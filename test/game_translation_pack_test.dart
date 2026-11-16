import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gametranslate/services/game_translation_pack.dart';

Map<String, dynamic> decode(String text) => GameTranslationPack.decode(
  text,
  gameId: 'test-game',
  sourceLanguage: 'en',
  targetLanguage: 'tr',
);

void main() {
  test(
    'v2 supports Thai, Indonesian and Arabic without language-named fields',
    () {
      for (final pair in {
        'th': 'มานี่!',
        'id': 'Kemarilah!',
        'ar': 'تعال إلى هنا!',
      }.entries) {
        final pack = GameTranslationPack.decode(
          jsonEncode({
            'schemaVersion': 2,
            'game': 'test-game',
            'source': 'en',
            'target': pair.key,
            'entries': [
              {'id': '1', 'sourceText': 'Come here!', 'targetText': pair.value},
            ],
          }),
          gameId: 'test-game',
          sourceLanguage: 'en',
          targetLanguage: pair.key,
        );
        expect((pack['entries'] as List).single['targetText'], pair.value);
        expect(pack['schemaVersion'], 2);
      }
      expect(
        () => GameTranslationPack.decode(
          '{"game":"test-game","source":"en","target":"ar","entries":[{"id":"1","english":"Hi","turkish":"مرحبا"}]}',
          gameId: 'test-game',
          sourceLanguage: 'en',
          targetLanguage: 'ar',
        ),
        throwsFormatException,
      );
    },
  );
  final entry = {
    'id': '0001',
    'english': '  Reach {place}!\nNow.',
    'turkish': '  {place} konumuna ulaş!\nŞimdi.',
  };
  Map<String, dynamic> pack() => {
    'game': 'test-game',
    'source': 'en',
    'target': 'tr',
    'entries': [entry],
    'speakers': {'Sweet': 'Sweet', 'Isabella': 'Isabella'},
  };

  test(
    'pretty JSON preserves texts and speakers while dropping old editorial fields',
    () {
      final value = pack();
      value['entries'] = [
        entry,
        {
          ...entry,
          'id': '0002',
          'speaker': 'Sweet',
          'chapter': 'I',
          'kind': 'objective',
          'notes': 'İncele',
          'qualityStatus': 'ai_draft',
        },
      ];
      value['gameProfile'] = {'regions': [], 'fonts': []};
      final result = decode(
        '\uFEFF${const JsonEncoder.withIndent('  ').convert(value)}',
      );
      expect(result['entries'], [
        entry,
        {...entry, 'id': '0002', 'speaker': 'Sweet'},
      ]);
      expect(result['speakers'], value['speakers']);
      expect(result['gameProfile'], value['gameProfile']);
    },
  );

  test('invalid records, duplicate IDs and wrong language directions fail', () {
    for (final field in ['id', 'english', 'turkish']) {
      for (final invalid in [null, '', '  ', 1]) {
        expect(
          () => decode(
            jsonEncode({
              ...pack(),
              'entries': [
                {...entry, field: invalid},
              ],
            }),
          ),
          throwsFormatException,
        );
      }
    }
    for (final value in [
      {
        ...pack(),
        'entries': [entry, entry],
      },
      {...pack(), 'entries': []},
      {...pack(), 'source': 'tr'},
      {
        ...pack(),
        'speakers': {'Sweet': 1},
      },
      {
        ...pack(),
        'entries': [
          {...entry, 'speaker': 1},
        ],
      },
      {...pack(), 'gameProfile': []},
    ]) {
      expect(() => decode(jsonEncode(value)), throwsFormatException);
    }
  });

  test(
    'existing JSONL downloads become JSON before reaching the native matcher',
    () {
      final manifest = {
        'type': 'manifest',
        'entryCount': 1,
        'metadata': {
          'game': 'test-game',
          'speakers': {'Sweet': 'Sweet'},
        },
      };
      final profile = {'type': 'game_profile', 'regions': [], 'fonts': []};
      final result = decode(
        [
          manifest,
          profile,
          {
            'type': 'entry',
            'id': '0001',
            'source': entry['english'],
            'target': entry['turkish'],
            'speaker': 'Sweet',
            'kind': 'dialogue',
            'chapter': 'I',
            'qualityStatus': 'ai_draft',
            'notes': null,
          },
        ].map(jsonEncode).join('\n'),
      );
      expect(result['game'], 'test-game');
      expect(result['source'], 'en');
      expect(result['target'], 'tr');
      expect(result['speakers'], {'Sweet': 'Sweet'});
      expect(result.containsKey('manifest'), isFalse);
      expect(result['gameProfile'], {'regions': [], 'fonts': []});
      final row = (result['entries'] as List).single as Map;
      expect(row['english'], entry['english']);
      expect(row['turkish'], entry['turkish']);
      expect(row['speaker'], 'Sweet');
      for (final field in ['chapter', 'kind', 'notes', 'qualityStatus']) {
        expect(row.containsKey(field), isFalse);
      }
      expect(row.containsKey('source'), isFalse);
      expect(row.containsKey('type'), isFalse);
    },
  );

  test(
    'single entry legacy JSONL and malformed legacy inputs are handled explicitly',
    () {
      expect(
        (decode(
                  '{"type":"entry","id":"1","source":"Hello","target":"Merhaba"}',
                )['entries']
                as List)
            .length,
        1,
      );
      for (final text in [
        'broken',
        '{}',
        '[]',
        '{"type":"manifest"}',
        '{"type":"unknown"}',
        '{"type":"entry","id":"1","source":"Hi","target":"Selam","english":"different"}',
      ]) {
        expect(() => decode(text), throwsFormatException);
      }
    },
  );
}
