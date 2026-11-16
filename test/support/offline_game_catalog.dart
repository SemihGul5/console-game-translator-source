import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/services.dart';
import 'package:gametranslate/services/game_translation_catalog.dart';

const testGameCoverPath = 'test/support/fixtures/game-cover.jpg';

/// Tiny synthetic data for UI tests only. No game is bundled in production.
class _UiGameAssets extends CachingAssetBundle {
  static const _fixturePath = 'assets/games/ui-test.json';
  static const _coverPath = 'assets/games/ui-test.cover.jpg';
  Uint8List? _cover;
  static final _fixture = Uint8List.fromList(
    utf8.encode(
      '{"game":"ui-test","source":"en","target":"tr","entries":[{"id":"test-1","english":"Hello","turkish":"Merhaba"}]}',
    ),
  );

  @override
  Future<ByteData> load(String key) async {
    if (key == _fixturePath) return ByteData.sublistView(_fixture);
    if (key == 'assets/games/catalog.json') {
      _cover ??= await File(testGameCoverPath).readAsBytes();
      final entries = [
        {
          'id': 'mafia-old-country',
          'name': 'Mafia: The Old Country',
          'sourceLanguage': 'en',
          'targetLanguage': 'tr',
          'file': _fixturePath,
          'sha256': crypto.sha256.convert(_fixture).toString(),
          'bytes': _fixture.length,
          'cover': _coverPath,
          'coverSha256': crypto.sha256.convert(_cover!).toString(),
          'coverAspectRatio': 285 / 350,
        },
      ];
      return ByteData.sublistView(
        Uint8List.fromList(utf8.encode(jsonEncode(entries))),
      );
    }
    if (key == _coverPath) return ByteData.sublistView(_cover!);
    return rootBundle.load(key);
  }
}

/// HTTP/auth and real app metadata are tested separately against the catalog.
final offlineGameCatalog = GameTranslationCatalog.testing(
  catalogUri: Uri.parse(GameTranslationCatalog.catalogUrl),
  cacheDirectory: () async => null,
  bundle: _UiGameAssets(),
  token: () async => throw StateError('Offline widget test'),
);
