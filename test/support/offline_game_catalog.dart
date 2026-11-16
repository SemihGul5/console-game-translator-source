import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/services.dart';
import 'package:gametranslate/services/game_translation_catalog.dart';

/// Tiny synthetic data for UI tests only. Production ships no game dictionary.
class _UiGameAssets extends CachingAssetBundle {
  static const _fixturePath = 'assets/games/ui-test.json';
  static final _fixture = Uint8List.fromList(
    utf8.encode(
      '{"game":"ui-test","source":"en","target":"tr","entries":[{"id":"test-1","english":"Hello","turkish":"Merhaba"}]}',
    ),
  );

  @override
  Future<ByteData> load(String key) async {
    if (key == _fixturePath) return ByteData.sublistView(_fixture);
    if (key == 'assets/games/catalog.json') {
      final entries = jsonDecode(await rootBundle.loadString(key)) as List;
      for (final entry in entries.cast<Map>()) {
        entry['file'] = _fixturePath;
        entry['sha256'] = crypto.sha256.convert(_fixture).toString();
        entry['bytes'] = _fixture.length;
      }
      return ByteData.sublistView(
        Uint8List.fromList(utf8.encode(jsonEncode(entries))),
      );
    }
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
