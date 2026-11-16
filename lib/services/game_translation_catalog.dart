import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/game_catalog_entry.dart';
import 'game_catalog_access.dart';
import 'game_catalog_cache.dart';
import 'game_translation_pack.dart';

/// Loads the shipped/last-good catalog immediately, then refreshes it separately.
/// Packs are authenticated, verified and cached by content hash across launches.
class GameTranslationCatalog {
  factory GameTranslationCatalog() => _shared;

  GameTranslationCatalog._({
    required this.catalogUri,
    required AssetBundle bundle,
    required Future<String> Function() token,
    required GameCatalogCache cache,
    this.allowLoopbackHttp = false,
  }) : _bundle = bundle,
       _token = token,
       _cache = cache;

  @visibleForTesting
  factory GameTranslationCatalog.testing({
    required Uri catalogUri,
    required Future<Directory?> Function() cacheDirectory,
    AssetBundle? bundle,
    Future<String> Function()? token,
  }) => GameTranslationCatalog._(
    catalogUri: catalogUri,
    bundle: bundle ?? rootBundle,
    token: token ?? () async => 'test-app-check-token',
    cache: GameCatalogCache(catalogUri.toString(), directory: cacheDirectory),
    allowLoopbackHttp: true,
  );

  static const catalogUrl = String.fromEnvironment(
    'GAME_CATALOG_URL',
    defaultValue:
        'https://console-game-translator-games.abrebostudio.workers.dev/catalog.json',
  );
  static const maxManifestBytes = 512 * 1024;
  static const maxPackBytes = 25 * 1024 * 1024;
  static const maxCoverBytes = 5 * 1024 * 1024;
  static const maxFontBytes = 2 * 1024 * 1024;
  static const _catalogAsset = 'assets/games/catalog.json';
  static final _shared = GameTranslationCatalog._(
    catalogUri: Uri.parse(catalogUrl),
    bundle: rootBundle,
    token: GameCatalogAccess.token,
    cache: GameCatalogCache(catalogUrl),
  );
  static final _digest = RegExp(r'^[a-f0-9]{64}$');

  final Uri catalogUri;
  final bool allowLoopbackHttp;
  final AssetBundle _bundle;
  final Future<String> Function() _token;
  final GameCatalogCache _cache;
  final _dataLoads = <String, Future<String>>{};
  final _coverLoads = <String, Future<Uint8List?>>{};
  final _fontLoads = <String, Future<Uint8List>>{};
  final _downloadedPackKeys = <String>{};
  final _packDeletions = <String, Future<void>>{};
  final _downloadingPacks = ValueNotifier<Set<String>>(const {});
  final _downloadedPacks = ValueNotifier<Set<String>>(const {});
  final _packStatusEpochs = <String, int>{};

  /// Network transfers only; loading a local pack or native indexes isn't a download.
  ValueListenable<Set<String>> get downloadingPacks => _downloadingPacks;
  ValueListenable<Set<String>> get downloadedPacks => _downloadedPacks;

  void _markDownloaded(GameCatalogEntry game) {
    _downloadedPackKeys.add(game.contentKey);
    _packStatusEpochs.update(game.id, (value) => value + 1, ifAbsent: () => 1);
    if (!_downloadedPacks.value.contains(game.contentKey)) {
      _downloadedPacks.value = {..._downloadedPacks.value, game.contentKey};
    }
  }

  /// Restore badges from local file metadata, without loading any translations.
  Future<void> refreshDownloadedPacks(Iterable<GameCatalogEntry> values) async {
    final games = values.toList();
    final epochs = {
      for (final game in games) game.id: _packStatusEpochs[game.id] ?? 0,
    };
    final present = await Future.wait(
      games.map((game) async {
        if (_downloadedPackKeys.contains(game.contentKey)) return true;
        if (!_digest.hasMatch(game.sha256) || game.bytes <= 0) return false;
        return await _cache.contains('pack-${game.sha256}.json', game.bytes) ||
            await _cache.contains('pack-${game.sha256}.jsonl', game.bytes);
      }),
    );
    final next = {..._downloadedPacks.value};
    for (var i = 0; i < games.length; i++) {
      final game = games[i];
      // A download or deletion completed while file metadata was being read.
      if ((_packStatusEpochs[game.id] ?? 0) != epochs[game.id] ||
          _packDeletions.containsKey(game.id))
        continue;
      if (present[i]) {
        next.add(game.contentKey);
      } else {
        next.remove(game.contentKey);
      }
    }
    if (!setEquals(next, _downloadedPacks.value)) _downloadedPacks.value = next;
  }

  Future<List<GameCatalogEntry>>? _bootstrap;
  Future<List<GameCatalogEntry>>? _refreshing;
  List<GameCatalogEntry> _bundled = const [];
  List<GameCatalogEntry>? _catalog;
  bool _refreshAttempted = false;

  Future<List<GameCatalogEntry>> loadCatalog() =>
      _catalog != null ? Future.value(_catalog!) : _bootstrap ??= _loadLocal();

  Future<List<GameCatalogEntry>> _loadLocal() async {
    final decoded = jsonDecode(await _bundle.loadString(_catalogAsset));
    if (decoded is! List) {
      throw const FormatException('Oyun kataloğu bir liste değil.');
    }
    _bundled = _parseEntries(decoded, remote: false);
    try {
      final saved = await _cache.read('catalog.json', maxManifestBytes);
      if (saved != null) return _catalog = _parseRemote(utf8.decode(saved));
    } on FormatException {
      // A damaged cache must not hide the packaged game library.
    }
    return _catalog = _bundled;
  }

  Future<List<GameCatalogEntry>> refresh({bool force = false}) async {
    await loadCatalog();
    if (_refreshing != null) return _refreshing!;
    // One background catalog check per app process, on first library visit.
    // A failed attempt also stays quiet until the app is opened again.
    if (!force && _refreshAttempted) return _catalog!;
    _refreshAttempted = true;
    final operation = _fetchCatalog();
    _refreshing = operation;
    try {
      return await operation;
    } finally {
      _refreshing = null;
    }
  }

  Future<List<GameCatalogEntry>> _fetchCatalog() async {
    // Keep the same cache namespace and old endpoint available during rollout.
    Uint8List? multilingual;
    if (!allowLoopbackHttp && catalogUri.path.endsWith('/catalog.json')) {
      try {
        multilingual = await _download(
          catalogUri.resolve('catalog-v2.json'),
          maxManifestBytes,
          const Duration(seconds: 15),
        );
      } on FormatException {
        // An older deployment can still supply its verified Turkish catalog.
      }
    }
    final data =
        multilingual ??
        await _download(
          catalogUri,
          maxManifestBytes,
          const Duration(seconds: 15),
        );
    final entries = _parseRemote(utf8.decode(data));
    await _cache.write('catalog.json', data);
    return _catalog = entries;
  }

  List<GameCatalogEntry> _parseRemote(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! Map ||
        !const [1, 2].contains(decoded['schemaVersion']) ||
        decoded['games'] is! List) {
      throw const FormatException('Oyun kataloğu kaydı geçersiz.');
    }
    if (decoded['schemaVersion'] == 1)
      return _parseEntries(decoded['games'] as List, remote: true);
    if (decoded['packs'] is! List ||
        decoded['languages'] is! List ||
        (decoded['games'] as List).length > 1000 ||
        (decoded['languages'] as List).length > 200) {
      throw const FormatException('Oyun kataloğu kaydı geçersiz.');
    }
    final games = <String, Map>{};
    final languages = <String, Map>{};
    for (final game in decoded['games'] as List) {
      if (game is! Map ||
          game['id'] is! String ||
          games.containsKey(game['id']))
        throw const FormatException('Oyun kataloğu kaydı geçersiz.');
      games[game['id'] as String] = game;
    }
    for (final language in decoded['languages'] as List) {
      if (language is! Map ||
          language['code'] is! String ||
          language['names'] is! Map ||
          language['nativeName'] is! String ||
          !const ['ltr', 'rtl'].contains(language['direction']) ||
          languages.containsKey(language['code']))
        throw const FormatException('Oyun kataloğu dil bilgileri geçersiz.');
      languages[language['code'] as String] = language;
    }
    final tuples = <String>{};
    return _parseEntries(
      (decoded['packs'] as List).map((pack) {
        if (pack is! Map ||
            games[pack['gameId']] == null ||
            languages[pack['targetLanguage']] == null ||
            !const [1, 2].contains(pack['formatVersion']) ||
            !tuples.add(
              '${pack['gameId']}:${pack['sourceLanguage']}:${pack['targetLanguage']}',
            ))
          throw const FormatException(
            'Oyun kataloğu paket bilgileri geçersiz.',
          );
        final language = languages[pack['targetLanguage']]!;
        return <String, dynamic>{
          ...Map<String, dynamic>.from(games[pack['gameId']]!),
          ...Map<String, dynamic>.from(pack),
          'targetLanguageName': language['names']['tr'] ?? '',
          'targetLanguageEnglishName': language['names']['en'] ?? '',
          'targetLanguageNativeName': language['nativeName'],
        };
      }).toList(),
      remote: true,
    );
  }

  List<GameCatalogEntry> _parseEntries(List values, {required bool remote}) {
    if (values.length > 1000) {
      throw const FormatException('Oyun kataloğu kaydı geçersiz.');
    }
    final ids = <String>{};
    final entries = <GameCatalogEntry>[];
    for (final item in values) {
      if (item is! Map) {
        throw const FormatException('Oyun kataloğu kaydı geçersiz.');
      }
      final value = Map<String, dynamic>.from(item);
      // Shipped metadata can point to a server pack without including its data.
      if (!remote &&
          value['file'] is String &&
          !(value['file'] as String).startsWith('assets/games/')) {
        value['file'] = _resolveUrl(value['file']).toString();
      }
      if (remote) {
        value['file'] = _resolveUrl(value['file']).toString();
        value['cover'] = _resolveUrl(value['cover']).toString();
        if (value['sha256'] is! String ||
            !_digest.hasMatch(value['sha256'] as String) ||
            value['coverSha256'] is! String ||
            !_digest.hasMatch(value['coverSha256'] as String) ||
            value['bytes'] is! int ||
            (value['bytes'] as int) <= 0 ||
            (value['bytes'] as int) > maxPackBytes) {
          throw const FormatException('Oyun kataloğu kaydı geçersiz.');
        }
      }
      final game = GameCatalogEntry.fromJson(value);
      if (!RegExp(r'^[a-z0-9][a-z0-9_-]{0,111}$').hasMatch(game.id) ||
          !RegExp(r'^[a-z0-9][a-z0-9_-]{0,95}$').hasMatch(game.gameId) ||
          !game.coverAspectRatio.isFinite ||
          game.coverAspectRatio < 0.25 ||
          game.coverAspectRatio > 4 ||
          game.name.length > 180 ||
          !RegExp(
            r'^[a-z]{2,3}(?:-[A-Za-z0-9]{2,8})?$',
          ).hasMatch(game.sourceLanguage) ||
          !RegExp(
            r'^[a-z]{2,3}(?:-[A-Za-z0-9]{2,8})?$',
          ).hasMatch(game.targetLanguage)) {
        throw const FormatException('Oyun kataloğu kaydı geçersiz.');
      }
      if (!ids.add(game.id)) {
        throw const FormatException('Oyun kataloğunda yinelenen ID var.');
      }
      entries.add(game);
    }
    return List.unmodifiable(entries);
  }

  Uri _resolveUrl(Object? path) {
    if (path is! String || path.trim().isEmpty) {
      throw const FormatException('Oyun kataloğu kaydı geçersiz.');
    }
    final uri = catalogUri.resolve(path);
    final secure =
        uri.scheme == 'https' ||
        allowLoopbackHttp &&
            uri.scheme == 'http' &&
            const ['127.0.0.1', 'localhost', '::1'].contains(uri.host);
    if (!secure ||
        uri.host != catalogUri.host ||
        uri.port != catalogUri.port ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment ||
        uri.hasQuery ||
        !uri.path.startsWith(catalogUri.resolve('.').path) ||
        uri.pathSegments.any((p) => p == '..' || p == '.')) {
      throw const FormatException('Oyun kataloğu kaydı geçersiz.');
    }
    return uri;
  }

  Future<String> loadJson(GameCatalogEntry game) async {
    final deleting = _packDeletions[game.id];
    if (deleting != null) await deleting;
    final pending = _dataLoads.putIfAbsent(
      game.contentKey,
      () => _loadJson(game),
    );
    try {
      return await pending;
    } catch (_) {
      if (identical(_dataLoads[game.contentKey], pending)) {
        _dataLoads.remove(game.contentKey);
      }
      rethrow;
    }
  }

  /// Native verifies and parses an already downloaded JSON directly.
  Future<String?> cachedJsonFile(GameCatalogEntry game) async {
    final deleting = _packDeletions[game.id];
    if (deleting != null) await deleting;
    if (!game.isRemote ||
        !Uri.parse(game.file).path.endsWith('.json') ||
        !_digest.hasMatch(game.sha256) ||
        game.bytes <= 0)
      return null;
    return _cache.pathIfPresent('pack-${game.sha256}.json', game.bytes);
  }

  Future<Uint8List> loadFont(Map<String, dynamic> font) async {
    final hash = font['sha256'];
    final file = font['file'];
    final size = font['bytes'];
    if (hash is! String ||
        !_digest.hasMatch(hash) ||
        file is! String ||
        !RegExp(r'^fonts/[a-z0-9._-]+\.ttf$').hasMatch(file) ||
        size is! int ||
        size <= 0 ||
        size > maxFontBytes) {
      throw const FormatException('Oyun fontu kaydı geçersiz.');
    }
    final uri = _resolveUrl(file);
    final operation = _fontLoads.putIfAbsent(hash, () async {
      final cached = await _cache.read(
        'font-$hash.ttf',
        maxFontBytes,
        sha256: hash,
      );
      if (cached != null && cached.length == size) return cached;
      final bytes = await _download(
        uri,
        maxFontBytes,
        const Duration(seconds: 30),
      );
      _verify(bytes, hash);
      if (bytes.length != size) {
        throw const FormatException('Oyun fontu doğrulanamadı.');
      }
      await _cache.write('font-$hash.ttf', bytes);
      return bytes;
    });
    try {
      return await operation;
    } catch (_) {
      _fontLoads.remove(hash);
      rethrow;
    }
  }

  Future<String> _loadJson(GameCatalogEntry game) async {
    if (!game.isRemote) return _decodePack(await _asset(game.file), game);
    final cached = await _readCachedPack(game);
    if (cached != null) {
      final json = _decodePack(cached, game);
      _markDownloaded(game);
      return json;
    }
    for (final bundled in _bundled) {
      if (!bundled.isRemote &&
          bundled.id == game.id &&
          bundled.sha256 == game.sha256) {
        final bytes = await _asset(bundled.file);
        _verify(bytes, game.sha256);
        return _decodePack(bytes, game);
      }
    }
    late Uint8List bytes;
    _downloadingPacks.value = {..._downloadingPacks.value, game.contentKey};
    try {
      bytes = await _download(
        Uri.parse(game.file),
        maxPackBytes,
        const Duration(seconds: 90),
      );
    } finally {
      _downloadingPacks.value = {..._downloadingPacks.value}
        ..remove(game.contentKey);
    }
    _verify(bytes, game.sha256);
    if (bytes.length != game.bytes) {
      throw const FormatException('Oyun çeviri dosyası doğrulanamadı.');
    }
    final json = _decodePack(bytes, game);
    await _cache.write('pack-${game.sha256}.json', bytes);
    _markDownloaded(game);
    return json;
  }

  Future<Uint8List?> _readCachedPack(GameCatalogEntry game) async =>
      await _cache.read(
        'pack-${game.sha256}.json',
        maxPackBytes,
        sha256: game.sha256,
      ) ??
      // Keep existing verified downloads usable during the server migration.
      await _cache.read(
        'pack-${game.sha256}.jsonl',
        maxPackBytes,
        sha256: game.sha256,
      );

  Future<bool> hasDownloadedPack(GameCatalogEntry game) async {
    if (_downloadedPackKeys.contains(game.contentKey)) return true;
    if (!_digest.hasMatch(game.sha256)) return false;
    final cached = await _readCachedPack(game);
    if (cached == null) return false;
    _markDownloaded(game);
    return true;
  }

  Future<void> deleteDownloadedPack(GameCatalogEntry game) async {
    final existing = _packDeletions[game.id];
    if (existing != null) return existing;
    final operation = _deletePackCopies(game);
    _packDeletions[game.id] = operation;
    try {
      await operation;
    } finally {
      if (identical(_packDeletions[game.id], operation)) {
        _packDeletions.remove(game.id);
      }
    }
  }

  Future<void> _deletePackCopies(GameCatalogEntry game) async {
    final prefix = '${game.id}:';
    final keys = {
      game.contentKey,
      ..._dataLoads.keys.where((key) => key.startsWith(prefix)),
      ..._downloadedPackKeys.where((key) => key.startsWith(prefix)),
      ..._downloadedPacks.value.where((key) => key.startsWith(prefix)),
    };
    // Finish any existing write before removing its file, so it cannot reappear.
    for (final key in keys) {
      try {
        await _dataLoads[key];
      } catch (_) {
        // A failed load has nothing to retain.
      }
    }
    for (final key in keys) {
      final hash = key.substring(prefix.length);
      if (_digest.hasMatch(hash)) {
        await _cache.remove('pack-$hash.json');
        await _cache.remove('pack-$hash.jsonl');
      }
    }
    for (final key in keys) {
      _dataLoads.remove(key);
      _downloadedPackKeys.remove(key);
    }
    _packStatusEpochs.update(game.id, (value) => value + 1, ifAbsent: () => 1);
    _downloadedPacks.value = {..._downloadedPacks.value}
      ..removeWhere((key) => key.startsWith(prefix));
  }

  String _decodePack(Uint8List bytes, GameCatalogEntry game) => jsonEncode(
    GameTranslationPack.decode(
      utf8.decode(bytes),
      gameId: game.gameId,
      sourceLanguage: game.sourceLanguage,
      targetLanguage: game.targetLanguage,
    ),
  );

  Future<Uint8List?> loadCover(GameCatalogEntry game) async {
    if (game.cover.isEmpty) return null;
    final pending = _coverLoads.putIfAbsent(
      game.coverKey,
      () => _loadCover(game),
    );
    try {
      final bytes = await pending;
      if (bytes == null) _coverLoads.remove(game.coverKey);
      return bytes;
    } catch (_) {
      if (identical(_coverLoads[game.coverKey], pending)) {
        _coverLoads.remove(game.coverKey);
      }
      return null;
    }
  }

  Future<Uint8List> _loadCover(GameCatalogEntry game) async {
    if (!Uri.parse(game.cover).hasScheme) return _asset(game.cover);
    final cached = await _cache.read(
      'cover-${game.coverSha256}.image',
      maxCoverBytes,
      sha256: game.coverSha256,
    );
    if (cached != null) return cached;
    for (final bundled in _bundled) {
      if (bundled.cover.isNotEmpty && bundled.coverSha256 == game.coverSha256) {
        return _asset(bundled.cover);
      }
    }
    final bytes = await _download(
      Uri.parse(game.cover),
      maxCoverBytes,
      const Duration(seconds: 30),
    );
    _verify(bytes, game.coverSha256);
    await _cache.write('cover-${game.coverSha256}.image', bytes);
    return bytes;
  }

  String _gamePath(String path) {
    if (!path.startsWith('assets/games/') || path.split('/').contains('..')) {
      throw const FormatException('Oyun kataloğu kaydı geçersiz.');
    }
    return path;
  }

  Future<Uint8List> _asset(String path) async {
    final data = await _bundle.load(_gamePath(path));
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  Future<Uint8List> _download(Uri uri, int limit, Duration timeout) async {
    _resolveUrl(uri.toString());
    final token = await _token().timeout(const Duration(seconds: 15));
    if (token.isEmpty) throw StateError('Oyun erişimi doğrulanamadı.');
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(uri).timeout(timeout);
      // Never forward attestation tokens through a redirect or query string.
      request.followRedirects = false;
      request.headers.set('X-Firebase-AppCheck', token);
      final response = await request.close().timeout(timeout);
      if (response.statusCode != HttpStatus.ok ||
          response.contentLength > limit ||
          response.headers.contentType?.mimeType == 'text/html') {
        throw const FormatException('Oyun dosyası indirilemedi.');
      }
      final builder = BytesBuilder(copy: false);
      await response
          .forEach((chunk) {
            if (builder.length + chunk.length > limit) {
              throw const FormatException('Oyun dosyası çok büyük.');
            }
            builder.add(chunk);
          })
          .timeout(timeout);
      return builder.takeBytes();
    } finally {
      client.close(force: true);
    }
  }

  void _verify(Uint8List bytes, String expected) {
    if (!_digest.hasMatch(expected) ||
        crypto.sha256.convert(bytes).toString() != expected) {
      throw const FormatException('Oyun çeviri dosyası doğrulanamadı.');
    }
  }
}
