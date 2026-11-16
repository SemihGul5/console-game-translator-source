import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'game_translation_catalog.dart';
import '../models/subtitle_settings.dart';

class LoadedGameFont {
  LoadedGameFont({required this.sha256, required this.bytes});
  final String sha256;
  final Uint8List bytes;
  String get family => 'GameFont_$sha256';
  Map<String, Object> get packet => {
    'type': 'font',
    'sha256': sha256,
    'bytes': bytes.length,
    'data': base64Encode(bytes),
  };
}

/// The chosen game's downloaded font; legacy packs and system profiles use null.
class GameFonts {
  static final active = ValueNotifier<LoadedGameFont?>(null);
  static final _loaded = <String, Future<LoadedGameFont>>{};
  static final _preparedGames = <String, LoadedGameFont?>{};
  static bool _licenseRegistered = false;
  static LoadedGameFont? forSettings(SubtitleSettings settings) =>
      settings.useGameFont ? active.value : null;

  static Future<LoadedGameFont?> prepare(
    String json,
    GameTranslationCatalog catalog, {
    String? contentKey,
  }) async {
    if (contentKey != null && _preparedGames.containsKey(contentKey)) {
      final font = _preparedGames.remove(contentKey);
      _preparedGames[contentKey] = font;
      return font;
    }
    final font = await _prepare(json, catalog);
    if (contentKey != null) {
      _preparedGames[contentKey] = font;
      while (_preparedGames.length > 8) {
        _preparedGames.remove(_preparedGames.keys.first);
      }
    }
    return font;
  }

  static bool restorePrepared(String contentKey) {
    if (!_preparedGames.containsKey(contentKey)) return false;
    final font = _preparedGames.remove(contentKey);
    _preparedGames[contentKey] = font;
    active.value = font;
    return true;
  }

  static void forgetGame(String gameId) =>
      _preparedGames.removeWhere((key, _) => key.startsWith('$gameId:'));

  static Future<LoadedGameFont?> _prepare(
    String json,
    GameTranslationCatalog catalog,
  ) async {
    final pack = jsonDecode(json);
    final profile = pack is Map ? pack['gameProfile'] : null;
    if (profile == null) return null;
    final regions = profile['regions'];
    if (regions is! List) return null;
    final first = regions
        .whereType<Map>()
        .where((region) => region['enabled'] == true)
        .firstOrNull;
    final style = first?['style'];
    final id = style is Map ? style['fontId'] : null;
    if (id == null || id == 'default') return null;
    final fonts = profile['fonts'];
    final font = fonts is List
        ? fonts.whereType<Map>().where((font) => font['id'] == id).firstOrNull
        : null;
    if (font == null) throw const FormatException('Oyun fontu bulunamadı.');
    final descriptor = Map<String, dynamic>.from(font);
    // Downloads are verified even when the same family is already registered.
    final bytes = await catalog.loadFont(descriptor);
    final hash = descriptor['sha256'] as String;
    final operation = _loaded.putIfAbsent(hash, () async {
      if (bytes.length < 12 ||
          ByteData.sublistView(bytes).getUint32(0) != 0x00010000) {
        throw const FormatException('Geçersiz TrueType fontu.');
      }
      final loaded = LoadedGameFont(sha256: hash, bytes: bytes);
      final loader = FontLoader(loaded.family)
        ..addFont(Future.value(ByteData.sublistView(bytes)));
      await loader.load();
      if (!_licenseRegistered) {
        _licenseRegistered = true;
        LicenseRegistry.addLicense(() async* {
          yield LicenseEntryWithLineBreaks([
            'Inter',
          ], await rootBundle.loadString('assets/licenses/Inter-OFL.txt'));
        });
      }
      return loaded;
    });
    try {
      return await operation;
    } catch (_) {
      _loaded.remove(hash);
      rethrow;
    }
  }
}
