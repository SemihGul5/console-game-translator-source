import 'dart:convert';

/// The shared game JSON format: game/source/target/entries and optional speakers
/// and gameProfile. Legacy downloads are adapted only at the catalog boundary.
class GameTranslationPack {
  static Map<String, dynamic> decode(
    String text, {
    required String gameId,
    required String sourceLanguage,
    required String targetLanguage,
  }) {
    final clean = text.startsWith('\uFEFF') ? text.substring(1) : text;
    Map<String, dynamic> pack;
    try {
      final value = jsonDecode(clean);
      if (value is! Map<String, dynamic>) _invalid();
      // An existing single-record JSONL pack is also valid JSON.
      pack = value.containsKey('entries')
          ? value
          : _fromLegacy(clean, gameId, sourceLanguage, targetLanguage);
    } on FormatException {
      pack = _fromLegacy(clean, gameId, sourceLanguage, targetLanguage);
    }
    if (pack['game'] is! String ||
        (pack['game'] as String).trim().isEmpty ||
        pack['source'] != sourceLanguage ||
        pack['target'] != targetLanguage ||
        pack['entries'] is! List ||
        (pack['entries'] as List).isEmpty) {
      _invalid();
    }
    final version = pack['schemaVersion'] ?? 1;
    if (version != 1 && version != 2 ||
        version == 1 && (sourceLanguage != 'en' || targetLanguage != 'tr'))
      _invalid();
    final sourceField = version == 2 ? 'sourceText' : 'english';
    final targetField = version == 2 ? 'targetText' : 'turkish';
    final ids = <String>{};
    final entries = <Map<String, dynamic>>[];
    for (final entry in pack['entries'] as List) {
      if (entry is! Map) _invalid();
      if (version == 2 &&
          (entry.containsKey('english') || entry.containsKey('turkish')))
        _invalid();
      for (final field in ['id', sourceField, targetField]) {
        if (entry[field] is! String ||
            (entry[field] as String).trim().isEmpty) {
          _invalid();
        }
      }
      if (!ids.add(entry['id'] as String)) _invalid();
      if (entry['speaker'] != null && entry['speaker'] is! String) _invalid();
      entries.add({
        'id': entry['id'],
        sourceField: entry[sourceField],
        targetField: entry[targetField],
        if (entry['speaker'] is String &&
            (entry['speaker'] as String).isNotEmpty)
          'speaker': entry['speaker'],
      });
    }
    final speakers = pack['speakers'];
    if (speakers != null &&
        (speakers is! Map ||
            speakers.entries.any(
              (e) => e.key is! String || e.value is! String,
            ))) {
      _invalid();
    }
    if (pack['gameProfile'] != null && pack['gameProfile'] is! Map) _invalid();
    final names = <String, String>{
      if (speakers is Map) ...Map<String, String>.from(speakers),
    };
    for (final entry in entries) {
      final speaker = entry['speaker'] as String?;
      if (speaker != null) names.putIfAbsent(speaker, () => speaker);
    }
    return {
      if (version == 2) 'schemaVersion': 2,
      'game': pack['game'],
      'source': pack['source'],
      'target': pack['target'],
      'entries': entries,
      'speakers': names,
      if (pack['gameProfile'] is Map)
        'gameProfile': Map<String, dynamic>.from(pack['gameProfile'] as Map)
          ..remove('type'),
    };
  }

  static Map<String, dynamic> _fromLegacy(
    String text,
    String gameId,
    String source,
    String target,
  ) {
    final entries = <Map<String, dynamic>>[];
    final pack = <String, dynamic>{};
    for (final line in LineSplitter.split(text)) {
      if (line.trim().isEmpty) continue;
      final row = jsonDecode(line);
      if (row is! Map<String, dynamic>) _invalid();
      switch (row['type']) {
        case 'entry':
          if (row.containsKey('english') && row['english'] != row['source'] ||
              row.containsKey('turkish') && row['turkish'] != row['target']) {
            _invalid();
          }
          final entry = Map<String, dynamic>.from(row)..remove('type');
          entry['english'] = entry.remove('source');
          entry['turkish'] = entry.remove('target');
          entries.add(entry);
        case 'manifest':
          if (pack.containsKey('manifest')) _invalid();
          pack['manifest'] = row;
          final metadata = row['metadata'];
          if (metadata != null) {
            if (metadata is! Map<String, dynamic> ||
                [
                  'entries',
                  'manifest',
                  'gameProfile',
                ].any(metadata.containsKey)) {
              _invalid();
            }
            pack.addAll(metadata);
          }
        case 'game_profile':
          if (pack.containsKey('gameProfile')) _invalid();
          pack['gameProfile'] = row;
        default:
          _invalid();
      }
    }
    pack['game'] ??= gameId;
    pack['source'] ??= source;
    pack['target'] ??= target;
    pack['entries'] = entries;
    return pack;
  }

  static Never _invalid() =>
      throw const FormatException('Oyun çeviri verisi okunamadı.');
}
