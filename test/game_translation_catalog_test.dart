import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gametranslate/services/game_translation_catalog.dart';

String digest(List<int> data) => crypto.sha256.convert(data).toString();
const firstPack =
    '{"game":"test-game","source":"en","target":"tr","entries":[{"id":"1","english":"Hello","turkish":"Merhaba"}],"speakers":{}}';
const secondPack =
    '{"game":"test-game","source":"en","target":"tr","entries":[{"id":"1","english":"Hello","turkish":"Selam"}],"speakers":{}}';
final coverBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aRZkAAAAASUVORK5CYII=',
);
final bundledCoverBytes = Uint8List.fromList([...coverBytes, 0]);

class _Assets extends CachingAssetBundle {
  _Assets() {
    final bytes = utf8.encode(firstPack);
    values = {
      'assets/games/catalog.json': Uint8List.fromList(
        utf8.encode(
          jsonEncode([
            {
              'id': 'bundled',
              'name': 'Bundled Game',
              'sourceLanguage': 'en',
              'targetLanguage': 'tr',
              'file': 'assets/games/bundled.json',
              'sha256': digest(bytes),
              'bytes': bytes.length,
              'cover': 'assets/games/bundled.png',
              'coverSha256': digest(bundledCoverBytes),
            },
          ]),
        ),
      ),
      'assets/games/bundled.json': Uint8List.fromList(bytes),
      'assets/games/bundled.png': bundledCoverBytes,
    };
  }
  late Map<String, Uint8List> values;
  @override
  Future<ByteData> load(String key) async => ByteData.sublistView(values[key]!);
}

/// A catalog v3 pack published as .json.gz: hash and size are the compressed file's.
Map<String, Object> gzGame(List<int> compressed, {String id = 'large-game'}) => {
  'id': id,
  'name': 'Large Game',
  'sourceLanguage': 'en',
  'targetLanguage': 'tr',
  'file': 'translations/$id.${digest(compressed)}.json.gz',
  'sha256': digest(compressed),
  'bytes': compressed.length,
  'cover': 'covers/$id.${digest(coverBytes)}.png',
  'coverSha256': digest(coverBytes),
};

Map<String, Object> game({String id = 'remote-game', String pack = firstPack}) {
  final bytes = utf8.encode(pack);
  return {
    'id': id,
    'name': 'Remote Game',
    'sourceLanguage': 'en',
    'targetLanguage': 'tr',
    'file': 'translations/$id.${digest(bytes)}.json',
    'sha256': digest(bytes),
    'bytes': bytes.length,
    'cover': 'covers/$id.${digest(coverBytes)}.png',
    'coverSha256': digest(coverBytes),
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late HttpServer server;
  late Uri catalogUri;
  late List<String> requests;
  late Map<String, dynamic> manifest;
  late Map<String, String> packs;
  late Map<String, List<int>> gzPacks;
  late List<String?> gzAcceptEncodings;
  late int status;
  late bool corruptPack;
  late bool html;
  late bool redirect;
  late DateTime now;
  Completer<void>? packRequested;
  Completer<void>? releasePack;
  HttpOverrides? originalOverrides;

  GameTranslationCatalog catalog({Future<String> Function()? token}) =>
      GameTranslationCatalog.testing(
        catalogUri: catalogUri,
        cacheDirectory: () async => directory,
        bundle: _Assets(),
        token: token,
        now: () => now,
      );

  setUp(() async {
    originalOverrides = HttpOverrides.current;
    now = DateTime.utc(2026, 11, 17);
    HttpOverrides.global = null;
    directory = await Directory.systemTemp.createTemp('game-catalog-test-');
    requests = [];
    status = 200;
    html = false;
    corruptPack = false;
    redirect = false;
    packRequested = null;
    releasePack = null;
    manifest = {
      'schemaVersion': 1,
      'games': [game()],
    };
    packs = {
      digest(utf8.encode(firstPack)): firstPack,
      digest(utf8.encode(secondPack)): secondPack,
    };
    gzPacks = {};
    gzAcceptEncodings = [];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requests.add(request.uri.path);
      if (request.headers.value('X-Firebase-AppCheck') !=
          'test-app-check-token') {
        request.response.statusCode = 401;
      } else if (status != 200) {
        request.response.statusCode = status;
      } else if (redirect) {
        request.response.statusCode = 302;
        request.response.headers.set(
          HttpHeaders.locationHeader,
          'https://untrusted.example/catalog.json',
        );
      } else if (request.uri.path == '/catalog.json') {
        request.response.headers.contentType = ContentType(
          html ? 'text' : 'application',
          html ? 'html' : 'json',
          charset: 'utf-8',
        );
        request.response.write(
          html ? '<html>hosting fallback</html>' : jsonEncode(manifest),
        );
      } else if (request.uri.path.endsWith('.json.gz')) {
        gzAcceptEncodings.add(
          request.headers.value(HttpHeaders.acceptEncodingHeader),
        );
        request.response.headers.contentType = ContentType(
          'application',
          'gzip',
        );
        final key = request.uri.path.split('.').reversed.skip(2).first;
        request.response.add(corruptPack ? utf8.encode('corrupt') : gzPacks[key]!);
      } else if (request.uri.path.startsWith('/translations/')) {
        if (packRequested?.isCompleted == false) packRequested!.complete();
        if (releasePack != null) await releasePack!.future;
        request.response.headers.contentType = ContentType(
          'application',
          'x-ndjson',
          charset: 'utf-8',
        );
        final key = request.uri.path.split('.').reversed.skip(1).first;
        request.response.write(corruptPack ? 'corrupt' : packs[key]!);
      } else if (request.uri.path.startsWith('/covers/')) {
        request.response.headers.contentType = ContentType('image', 'png');
        request.response.add(coverBytes);
      } else {
        request.response.statusCode = 404;
      }
      await request.response.close();
    });
    catalogUri = Uri.parse('http://127.0.0.1:${server.port}/catalog.json');
  });

  tearDown(() async {
    await server.close(force: true);
    HttpOverrides.global = originalOverrides;
    final expectedParent = Directory.systemTemp.absolute.path;
    if (!directory.absolute.path.startsWith(
      '$expectedParent${Platform.pathSeparator}game-catalog-test-',
    )) {
      throw StateError('Unexpected test directory');
    }
    await directory.delete(recursive: true);
  });

  test(
    'v2 keeps same-game language packs separate, including download/delete state',
    () async {
      final arabic = jsonEncode({
        'schemaVersion': 2,
        'game': 'shared',
        'source': 'en',
        'target': 'ar',
        'entries': [
          {
            'id': '1',
            'sourceText': 'Come here!',
            'targetText': 'تعال إلى هنا!',
          },
        ],
      });
      packs[digest(utf8.encode(arabic))] = arabic;
      manifest = {
        'schemaVersion': 2,
        'games': [
          {...game(id: 'shared'), 'name': 'Shared Game'},
        ],
        'languages': [
          {
            'code': 'tr',
            'names': {'tr': 'Türkçe', 'en': 'Turkish'},
            'nativeName': 'Türkçe',
            'direction': 'ltr',
          },
          {
            'code': 'ar',
            'names': {'tr': 'Arapça', 'en': 'Arabic'},
            'nativeName': 'العربية',
            'direction': 'rtl',
          },
        ],
        'packs': [
          {
            ...game(id: 'shared'),
            'id': 'shared-en-tr',
            'gameId': 'shared',
            'formatVersion': 1,
          },
          {
            ...game(id: 'shared', pack: arabic),
            'id': 'shared-en-ar',
            'gameId': 'shared',
            'targetLanguage': 'ar',
            'formatVersion': 2,
          },
        ],
      };
      final service = catalog();
      final values = await service.refresh();
      expect(values.map((entry) => entry.gameId), ['shared', 'shared']);
      expect(values.map((entry) => entry.id).toSet(), hasLength(2));
      expect(values.last.languageLabel, 'العربية');
      await service.loadJson(values.first);
      expect(jsonDecode(await service.loadJson(values.last))['target'], 'ar');
      await service.deleteDownloadedPack(values.last);
      expect(await service.hasDownloadedPack(values.first), isTrue);
      expect(await service.hasDownloadedPack(values.last), isFalse);
      manifest['packs'] = [manifest['packs'][0], manifest['packs'][0]];
      await expectLater(service.refresh(force: true), throwsFormatException);
    },
  );

  test(
    'synthetic local test packs work without network and failed checks stay quiet',
    () async {
      var tokenAttempts = 0;
      final service = catalog(
        token: () async {
          tokenAttempts++;
          throw StateError('No attestation');
        },
      );
      final bundled = (await service.loadCatalog()).single;
      expect(bundled.id, 'bundled');
      expect(await service.loadJson(bundled), firstPack);
      expect(await service.loadCover(bundled), bundledCoverBytes);
      expect(requests, isEmpty);
      expect(tokenAttempts, 0);
      await expectLater(service.refresh(), throwsStateError);
      expect((await service.loadCatalog()).single.id, 'bundled');
      await Future.wait(List.generate(5, (_) => service.refresh()));
      expect(tokenAttempts, 1);
      expect(requests, isEmpty);
    },
  );

  test(
    'the real app has no packaged games and uses only the server and its cache',
    () async {
      var tokenAttempts = 0;
      final service = GameTranslationCatalog.testing(
        catalogUri: catalogUri,
        cacheDirectory: () async => null,
        token: () async {
          tokenAttempts++;
          throw StateError('Offline first selection');
        },
      );
      expect(await service.loadCatalog(), isEmpty);
      expect(tokenAttempts, 0);
      await expectLater(service.refresh(), throwsStateError);
      expect(tokenAttempts, 1);
      expect(await service.loadCatalog(), isEmpty);
      final online = GameTranslationCatalog.testing(
        catalogUri: catalogUri,
        cacheDirectory: () async => directory,
      );
      expect(await online.loadCatalog(), isEmpty);
      expect((await online.refresh()).single.id, 'remote-game');
      final cached = GameTranslationCatalog.testing(
        catalogUri: catalogUri,
        cacheDirectory: () async => directory,
        token: () async => throw StateError('Offline restart'),
      );
      expect((await cached.loadCatalog()).single.id, 'remote-game');
      expect((await cached.refresh()).single.id, 'remote-game');
      expect(requests, ['/catalog.json']);
      final assets = await AssetManifest.loadFromAssetBundle(rootBundle);
      expect(
        assets.listAssets().where(
          (path) =>
              path.startsWith('assets/games/') &&
              (path.endsWith('.jsonl') || path.endsWith('.jpg')),
        ),
        isEmpty,
      );
    },
  );

  test(
    'legacy server packs and old cache filenames still supply canonical JSON offline',
    () async {
      const legacy =
          '{"type":"entry","id":"old-1","source":"Come here!","target":"Buraya gel!","speaker":"Sweet"}\n';
      final descriptor = game(pack: legacy);
      descriptor['file'] = (descriptor['file'] as String).replaceAll(
        '.json',
        '.jsonl',
      );
      manifest['games'] = [descriptor];
      packs[digest(utf8.encode(legacy))] = legacy;
      final service = catalog();
      final remote = (await service.refresh()).single;
      final loaded = await service.loadJson(remote);
      final row =
          ((jsonDecode(loaded) as Map)['entries'] as List).single as Map;
      expect(row['english'], 'Come here!');
      expect(row['turkish'], 'Buraya gel!');
      expect(row['speaker'], 'Sweet');
      final saved = directory
          .listSync(recursive: true)
          .whereType<File>()
          .singleWhere(
            (file) => file.uri.pathSegments.last.startsWith('pack-'),
          );
      await saved.rename(saved.path.replaceAll('.json', '.jsonl'));
      final offline = catalog(token: () async => throw StateError('Offline'));
      final cached = (await offline.loadCatalog()).single;
      expect(await offline.hasDownloadedPack(cached), isTrue);
      await offline.refreshDownloadedPacks([cached]);
      expect(offline.downloadedPacks.value, contains(cached.contentKey));
      expect(await offline.loadJson(cached), loaded);
      await offline.deleteDownloadedPack(cached);
      expect(await offline.hasDownloadedPack(cached), isFalse);
      expect(
        requests.where((path) => path.startsWith('/translations/')),
        hasLength(1),
      );
    },
  );

  test(
    'profile headers survive download and offline cache without changing translations',
    () async {
      final profile = await File(
        'server/game-catalog/profiles/games/mafia-old-country.jsonl',
      ).readAsString();
      final pack = jsonEncode({
        ...jsonDecode(firstPack) as Map,
        'gameProfile': Map<String, dynamic>.from(jsonDecode(profile) as Map)
          ..remove('type'),
      });
      manifest['games'] = [game(id: 'mafia-old-country', pack: pack)];
      packs[digest(utf8.encode(pack))] = pack;
      final service = catalog();
      final remote = (await service.refresh()).single;
      expect(await service.loadJson(remote), pack);
      final offline = catalog(token: () async => throw StateError('Offline'));
      final cached = (await offline.loadCatalog()).single;
      expect(await offline.loadJson(cached), pack);
      expect(
        requests.where((path) => path.startsWith('/translations/')),
        hasLength(1),
      );
    },
  );

  test(
    'remote games appear; concurrent downloads are deduplicated and survive restart offline',
    () async {
      final service = catalog();
      final transfers = <Set<String>>[];
      void trackTransfers() =>
          transfers.add(Set.of(service.downloadingPacks.value));
      service.downloadingPacks.addListener(trackTransfers);
      addTearDown(
        () => service.downloadingPacks.removeListener(trackTransfers),
      );
      final remote = (await service.refresh()).single;
      expect(remote.id, 'remote-game');
      expect(service.downloadedPacks.value, isEmpty);
      expect(
        await Future.wait([service.loadJson(remote), service.loadJson(remote)]),
        [firstPack, firstPack],
      );
      expect(await service.loadCover(remote), coverBytes);
      expect(service.downloadedPacks.value, contains(remote.contentKey));
      expect(transfers, [
        {remote.contentKey},
        <String>{},
      ]);
      for (var selection = 0; selection < 5; selection++) {
        expect(await service.loadJson(remote), firstPack);
        expect(await service.loadCover(remote), coverBytes);
      }
      expect(transfers, hasLength(2));
      expect(
        requests.where((path) => path.startsWith('/translations/')),
        hasLength(1),
      );
      expect(
        requests.where((path) => path.startsWith('/covers/')),
        hasLength(1),
      );
      final count = requests.length;
      final offline = catalog(token: () async => throw StateError('Offline'));
      final diskTransfers = <Set<String>>[];
      void trackDiskTransfers() =>
          diskTransfers.add(Set.of(offline.downloadingPacks.value));
      offline.downloadingPacks.addListener(trackDiskTransfers);
      addTearDown(
        () => offline.downloadingPacks.removeListener(trackDiskTransfers),
      );
      final saved = (await offline.loadCatalog()).single;
      expect(saved.id, remote.id);
      final cachedPath = await offline.cachedJsonFile(saved);
      expect(cachedPath, isNotNull);
      expect(await File(cachedPath!).readAsString(), firstPack);
      await offline.refreshDownloadedPacks([saved]);
      expect(offline.downloadedPacks.value, contains(saved.contentKey));
      expect(await offline.loadJson(saved), firstPack);
      expect(await offline.loadCover(saved), coverBytes);
      expect(requests.length, count);
      expect(diskTransfers, isEmpty);
    },
  );

  test(
    'deleting a downloaded dictionary clears disk and memory while preserving other games and covers',
    () async {
      manifest['games'] = [
        game(id: 'first'),
        game(id: 'second', pack: secondPack),
      ];
      final service = catalog();
      final games = await service.refresh();
      final first = games.first;
      final second = games.last;
      expect(await service.hasDownloadedPack(first), isFalse);
      expect(await service.cachedJsonFile(first), isNull);
      await service.loadJson(first);
      await service.loadJson(second);
      await service.loadCover(first);
      expect(await service.hasDownloadedPack(first), isTrue);
      final count = requests.length;
      final statusRefresh = service.refreshDownloadedPacks(games);
      await service.deleteDownloadedPack(first);
      await statusRefresh;
      expect(await service.hasDownloadedPack(first), isFalse);
      expect(await service.hasDownloadedPack(second), isTrue);
      expect(service.downloadedPacks.value, isNot(contains(first.contentKey)));
      expect(service.downloadedPacks.value, contains(second.contentKey));
      expect(await service.loadJson(second), secondPack);
      expect(await service.loadCover(first), coverBytes);
      expect(await service.loadCatalog(), hasLength(2));
      expect(requests, hasLength(count));
      final nextLaunch = catalog(
        token: () async => throw StateError('Offline'),
      );
      final retained = await nextLaunch.loadCatalog();
      expect(await nextLaunch.hasDownloadedPack(retained.first), isFalse);
      expect(await nextLaunch.loadJson(retained.last), secondPack);
      expect(requests, hasLength(count));
      // Only an explicit new selection fetches the deleted package again.
      expect(await service.loadJson(first), firstPack);
      expect(requests, hasLength(count + 1));
      expect(await service.hasDownloadedPack(first), isTrue);
    },
  );

  test(
    'deletion waits for a pending cache write so the dictionary cannot reappear',
    () async {
      packRequested = Completer<void>();
      releasePack = Completer<void>();
      final service = catalog();
      final remote = (await service.refresh()).single;
      final loading = service.loadJson(remote);
      await packRequested!.future;
      final deleting = service.deleteDownloadedPack(remote);
      releasePack!.complete();
      expect(await loading, firstPack);
      await deleting;
      expect(await service.hasDownloadedPack(remote), isFalse);
      expect(service.downloadingPacks.value, isEmpty);
      expect(
        directory
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.uri.pathSegments.last.startsWith('pack-')),
        isEmpty,
      );
    },
  );

  test(
    'an updated hash under the same game ID loads new data without overwriting the old version',
    () async {
      final service = catalog();
      final first = (await service.refresh()).single;
      await service.loadJson(first);
      manifest['games'] = [game(pack: secondPack), game(id: 'another-game')];
      final games = await service.refresh(force: true);
      expect(games, hasLength(2));
      expect(games.first.id, first.id);
      expect(games.first.contentKey, isNot(first.contentKey));
      expect(await service.loadJson(games.first), secondPack);
      expect(await service.loadJson(first), firstPack);
    },
  );

  test(
    'failed HTTP and invalid HTML never overwrite a last-good catalog',
    () async {
      final service = catalog();
      await service.refresh();
      for (final failure in [401, 429, 500]) {
        status = failure;
        await expectLater(service.refresh(force: true), throwsFormatException);
        expect((await service.loadCatalog()).single.id, 'remote-game');
      }
      status = 200;
      html = true;
      await expectLater(service.refresh(force: true), throwsFormatException);
      expect((await catalog().loadCatalog()).single.id, 'remote-game');
    },
  );

  test(
    'wrong hashes are rejected and a failed download is retryable',
    () async {
      final service = catalog();
      final remote = (await service.refresh()).single;
      corruptPack = true;
      await expectLater(service.loadJson(remote), throwsFormatException);
      expect(service.downloadingPacks.value, isEmpty);
      corruptPack = false;
      expect(await service.loadJson(remote), firstPack);
      expect(
        requests.where((path) => path.startsWith('/translations/')),
        hasLength(2),
      );
    },
  );

  test('a corrupt disk file is detected and downloaded again', () async {
    final service = catalog();
    final remote = (await service.refresh()).single;
    await service.loadJson(remote);
    final saved = directory
        .listSync(recursive: true)
        .whereType<File>()
        .singleWhere((file) => file.uri.pathSegments.last.startsWith('pack-'));
    await saved.writeAsString('damaged');
    final nextLaunch = catalog();
    final nextGame = (await nextLaunch.loadCatalog()).single;
    expect(await nextLaunch.loadJson(nextGame), firstPack);
    expect(
      requests.where((path) => path.startsWith('/translations/')),
      hasLength(2),
    );
  });

  test(
    'unknown schema, duplicate IDs, off-origin URLs and excessive sizes fail closed',
    () async {
      final service = catalog();
      for (final invalid in [
        {
          'schemaVersion': 99,
          'games': [game()],
        },
        {
          'schemaVersion': 1,
          'games': [game(), game()],
        },
        {
          'schemaVersion': 1,
          'games': [
            {...game(), 'file': 'https://untrusted.example/game.jsonl'},
          ],
        },
        {
          'schemaVersion': 1,
          'games': [
            {...game(), 'bytes': GameTranslationCatalog.maxPackBytes + 1},
          ],
        },
      ]) {
        manifest = invalid;
        await expectLater(service.refresh(force: true), throwsFormatException);
        expect((await service.loadCatalog()).single.id, 'bundled');
      }
      expect(requests.every((path) => path == '/catalog.json'), isTrue);
      redirect = true;
      await expectLater(service.refresh(force: true), throwsFormatException);
    },
  );

  test(
    'catalog stays fresh across launches for six hours and concurrent checks share one request',
    () async {
      final service = catalog();
      await Future.wait(List.generate(5, (_) => service.refresh()));
      expect(requests, ['/catalog.json']);
      manifest['games'] = [game(), game(id: 'new-game')];
      final sameLaunch = await Future.wait(
        List.generate(20, (_) => service.refresh()),
      );
      expect(sameLaunch.every((games) => games.length == 1), isTrue);
      expect(requests, hasLength(1));
      final nextLaunch = catalog();
      expect(await nextLaunch.loadCatalog(), hasLength(1));
      expect(requests, hasLength(1));
      expect(await nextLaunch.refresh(), hasLength(1));
      expect(requests, hasLength(1));
      now = now.add(GameTranslationCatalog.catalogFreshness);
      expect(await nextLaunch.refresh(), hasLength(2));
      expect(requests, hasLength(2));
    },
  );

  test(
    'manual refresh bypasses freshness but throttles spam and app restarts',
    () async {
      final service = catalog();
      await service.refresh();
      manifest['games'] = [game(), game(id: 'new-game')];
      final refreshed = await Future.wait(
        List.generate(5, (_) => service.refreshManually()),
      );
      expect(refreshed.every((games) => games.length == 2), isTrue);
      expect(requests, hasLength(2));
      for (var i = 0; i < 20; i++) {
        await expectLater(
          service.refreshManually(),
          throwsA(isA<GameCatalogRefreshCooldown>()),
        );
      }
      final restarted = catalog();
      await expectLater(
        restarted.refreshManually(),
        throwsA(isA<GameCatalogRefreshCooldown>()),
      );
      now = now.add(
        GameTranslationCatalog.manualRefreshCooldown -
            const Duration(milliseconds: 1),
      );
      await expectLater(
        restarted.refreshManually(),
        throwsA(isA<GameCatalogRefreshCooldown>()),
      );
      expect(requests, hasLength(2));
      now = now.add(const Duration(milliseconds: 1));
      await restarted.refreshManually();
      expect(requests, hasLength(3));
      expect(requests.every((path) => path == '/catalog.json'), isTrue);
    },
  );

  test(
    'failed manual refreshes also persist the cooldown without a disk catalog',
    () async {
      status = 500;
      await expectLater(catalog().refreshManually(), throwsFormatException);
      expect(requests, hasLength(1));
      final restarted = catalog();
      await expectLater(
        restarted.refreshManually(),
        throwsA(isA<GameCatalogRefreshCooldown>()),
      );
      expect(requests, hasLength(1));
      await expectLater(
        restarted.refresh(),
        throwsA(isA<GameCatalogRefreshCooldown>()),
      );
      expect(requests, hasLength(1));
      now = now.add(GameTranslationCatalog.manualRefreshCooldown);
      status = 200;
      expect(await restarted.refreshManually(), hasLength(1));
      expect(requests, hasLength(2));
    },
  );

  test(
    'a clock moved backwards does not keep a cached catalog fresh',
    () async {
      await catalog().refresh();
      manifest['games'] = [game(), game(id: 'new-game')];
      now = now.subtract(const Duration(hours: 1));
      expect(await catalog().refresh(), hasLength(2));
      expect(requests, hasLength(2));
    },
  );

  test(
    'bundled copies satisfy a remote entry with the same hashes without downloading assets',
    () async {
      final service = catalog();
      manifest['games'] = [
        {...game(id: 'bundled'), 'coverSha256': digest(bundledCoverBytes)},
      ];
      final remote = (await service.refresh()).single;
      expect(await service.loadJson(remote), firstPack);
      expect(await service.loadCover(remote), bundledCoverBytes);
      expect(requests, ['/catalog.json']);
    },
  );

  test(
    'a .json.gz pack is stored as downloaded, verified by its compressed hash and deleted',
    () async {
      final compressed = gzip.encode(utf8.encode(secondPack));
      gzPacks[digest(compressed)] = compressed;
      manifest = {
        'schemaVersion': 3,
        'games': [
          {...game(), 'name': 'Remote Game'},
          {...gzGame(compressed), 'name': 'Large Game'},
        ],
        'languages': [
          {
            'code': 'tr',
            'names': {'tr': 'Türkçe', 'en': 'Turkish'},
            'nativeName': 'Türkçe',
            'direction': 'ltr',
          },
        ],
        'packs': [
          {...game(), 'id': 'remote-game-en-tr', 'gameId': 'remote-game', 'formatVersion': 1},
          {
            ...gzGame(compressed),
            'id': 'large-game-en-tr',
            'gameId': 'large-game',
            'formatVersion': 1,
          },
        ],
      };
      final service = catalog();
      final large = (await service.refresh()).last;
      expect(large.isCompressedPack, isTrue);
      expect(await service.cachedJsonFile(large), isNull);
      expect(await service.hasDownloadedPack(large), isFalse);
      final path = await service.downloadPackFile(large);
      expect(path, endsWith('pack-${digest(compressed)}.json.gz'));
      expect(await File(path!).readAsBytes(), compressed);
      expect(gzAcceptEncodings, ['identity']);
      expect(await service.cachedJsonFile(large), path);
      expect(await service.hasDownloadedPack(large), isTrue);
      expect(service.downloadedPacks.value, contains(large.contentKey));
      // Already on disk: no second download, also after an app restart.
      expect(await catalog().downloadPackFile(large), path);
      expect(gzAcceptEncodings, hasLength(1));
      // The Dart fallback can still expand it (fonts, tests, older hosts).
      expect(jsonDecode(await service.loadJson(large))['entries'][0]['turkish'], 'Selam');
      await service.deleteDownloadedPack(large);
      expect(File(path).existsSync(), isFalse);
      expect(await service.hasDownloadedPack(large), isFalse);
      // A plain pack still downloads exactly as before.
      final plain = (await service.loadCatalog()).first;
      expect(plain.isCompressedPack, isFalse);
      expect(await service.downloadPackFile(plain), isNull);
      expect(jsonDecode(await service.loadJson(plain))['entries'], hasLength(1));
    },
  );

  test('a .json.gz download with a wrong hash or a gzip bomb is rejected', () async {
    final compressed = gzip.encode(utf8.encode(secondPack));
    gzPacks[digest(compressed)] = compressed;
    manifest = {'schemaVersion': 1, 'games': [gzGame(compressed)]};
    final service = catalog();
    final large = (await service.refresh()).single;
    corruptPack = true;
    await expectLater(service.downloadPackFile(large), throwsFormatException);
    expect(await service.cachedJsonFile(large), isNull);
    expect(service.downloadedPacks.value, isEmpty);
    corruptPack = false;
    // 65 MiB of spaces compress to well under 1 MiB but must not be expanded.
    late List<int> bomb;
    final encoder = gzip.encoder.startChunkedConversion(
      ByteConversionSink.withCallback((data) => bomb = data),
    );
    encoder.add(utf8.encode('{"game":"large-game","pad":"'));
    final spaces = Uint8List(1024 * 1024)..fillRange(0, 1024 * 1024, 32);
    for (var i = 0; i < 65; i++) {
      encoder.add(spaces);
    }
    encoder.add(utf8.encode('"}'));
    encoder.close();
    expect(bomb.length, lessThan(1024 * 1024));
    gzPacks[digest(bomb)] = bomb;
    manifest = {'schemaVersion': 1, 'games': [gzGame(bomb, id: 'bomb')]};
    final bombGame = (await service.refresh(force: true)).single;
    await expectLater(service.loadJson(bombGame), throwsFormatException);
  });
}
