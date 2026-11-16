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
  late int status;
  late bool corruptPack;
  late bool html;
  late bool redirect;
  Completer<void>? packRequested;
  Completer<void>? releasePack;
  HttpOverrides? originalOverrides;

  GameTranslationCatalog catalog({Future<String> Function()? token}) =>
      GameTranslationCatalog.testing(
        catalogUri: catalogUri,
        cacheDirectory: () async => directory,
        bundle: _Assets(),
        token: token,
      );

  setUp(() async {
    originalOverrides = HttpOverrides.current;
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
    'the real app ships only Mafia metadata and downloads its dictionary on selection',
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
      final mafia = (await service.loadCatalog()).single;
      expect(mafia.id, 'mafia-old-country');
      expect(mafia.isRemote, isTrue);
      expect(Uri.parse(mafia.file).origin, catalogUri.origin);
      expect(await service.hasDownloadedPack(mafia), isFalse);
      expect(tokenAttempts, 0);
      await expectLater(service.loadJson(mafia), throwsStateError);
      expect(tokenAttempts, 1);
      final assets = await AssetManifest.loadFromAssetBundle(rootBundle);
      expect(
        assets.listAssets().where(
          (path) => path.startsWith('assets/games/') && path.endsWith('.jsonl'),
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
    'catalog checks once per launch and concurrent refresh calls share one request',
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
      expect(await nextLaunch.refresh(), hasLength(2));
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
}
