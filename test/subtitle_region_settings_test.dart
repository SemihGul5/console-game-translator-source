import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gametranslate/models/subtitle_cover.dart';
import 'package:gametranslate/models/subtitle_settings.dart';
import 'package:gametranslate/services/game_fonts.dart';
import 'package:gametranslate/services/subtitle_presentation.dart';
import 'package:gametranslate/services/subtitle_settings_store.dart';

void main() {
  test('legacy areas keep their saved appearance and OCR overrides', () {
    const bounds = SubtitleSettings();
    final settings = SubtitleSettings.fromMap({
      'subtitleRegions': [
        bounds.subtitleBounds.toMap(),
        bounds.subtitleBounds.toMap(),
      ],
      'ocrRegions': [bounds.ocrRegion.toMap(), bounds.ocrRegion.toMap()],
      'fontSize': 35,
      'bold': true,
      'ocrPreprocessingModes': [2, 9],
      'ocrDialogueFilters': [true, false],
      'sampleRateHz': 5,
      'ocrCaptureScale': 2,
    });
    final restored = SubtitleSettings.fromMap(settings.toMap());
    expect(restored.effectiveSubtitleStyles.map((s) => s.fontSize), [35, 35]);
    expect(restored.effectiveSubtitleStyles.every((s) => s.bold), isTrue);
    expect(restored.effectiveOcrPreprocessingModes, [2, 9]);
    expect(restored.effectiveOcrDialogueFilters, [true, false]);
    expect(restored.effectiveOcrSettings.map((s) => s.sampleRateHz), [5, 5]);
    expect(restored.effectiveOcrSettings.map((s) => s.ocrCaptureScale), [2, 2]);
  });

  test(
    'named profiles and TV payloads preserve each area including mixed fonts',
    () {
      final font = LoadedGameFont(sha256: 'f' * 64, bytes: Uint8List(12));
      GameFonts.active.value = font;
      addTearDown(() => GameFonts.active.value = null);
      const defaults = SubtitleSettings();
      final settings = SubtitleSettings(
        subtitleRegions: [defaults.subtitleBounds, defaults.subtitleBounds],
        subtitleStyles: const [
          SubtitleAppearance(
            fontSize: 36,
            useGameFont: false,
            bold: true,
            centered: false,
          ),
          SubtitleAppearance(
            fontSize: 18,
            textColor: 0xFFFFFF00,
            backgroundOpacity: 0.3,
          ),
        ],
        ocrRegions: [defaults.ocrRegion, defaults.ocrRegion],
        ocrRegionSettings: const [
          OcrRegionSettings(
            sampleRateHz: 2,
            holdSeconds: 5,
            ocrDialogueFilter: true,
          ),
          OcrRegionSettings(
            sampleRateHz: 15,
            ocrCaptureScale: 2,
            ocrPreprocessingMode: 9,
          ),
        ],
      );
      final restored = SubtitleProfile.fromMap(
        SubtitleProfile(name: 'Game', settings: settings).toMap(),
      ).settings;
      expect(
        restored.effectiveOcrSettings.map((s) => s.toMap()),
        settings.effectiveOcrSettings.map((s) => s.toMap()),
      );
      expect(
        restored.effectiveSubtitleStyles.map((s) => s.toMap()),
        settings.effectiveSubtitleStyles.map((s) => s.toMap()),
      );
      final presentation = subtitlePresentation(restored);
      final styles = (presentation['subtitleStyles'] as List).cast<Map>();
      expect(styles.map((s) => s['fontSize']), [36, 18]);
      expect(styles.first.containsKey('fontSha256'), isFalse);
      expect(styles.last['fontSha256'], font.sha256);
      expect(subtitlePresentationUsesFont(presentation, font.sha256), isTrue);
    },
  );

  test('cover mode is on by default and can be turned off for OCR 1', () {
    const bounds = SubtitleSettings();
    final base = SubtitleSettings.fromMap({
      'subtitleRegions': [
        bounds.subtitleBounds.toMap(),
        bounds.subtitleBounds.toMap(),
      ],
      'ocrRegions': [bounds.ocrRegion.toMap(), bounds.ocrRegion.toMap()],
    });
    // New installs and saved settings without the key start in cover mode.
    expect(const SubtitleSettings().coversEnglishSubtitle, isTrue);
    expect(base.coversEnglishSubtitle, isTrue);
    final onStyles = subtitlePresentation(base)['subtitleStyles'] as List;
    expect((onStyles.first as Map)['coverEnglish'], isTrue);
    expect((onStyles.last as Map).containsKey('coverEnglish'), isFalse);

    final disabled = base.withOcrSettings(
      0,
      base.effectiveOcrSettings.first.copyWith(coverEnglishSubtitle: false),
    );
    final restored = SubtitleSettings.fromMap(disabled.toMap());
    expect(restored.coversEnglishSubtitle, isFalse);
    final offStyles = subtitlePresentation(restored)['subtitleStyles'] as List;
    expect(
      offStyles.every((style) => !(style as Map).containsKey('coverEnglish')),
      isTrue,
    );
  });

  test('new installs start with a fully opaque subtitle background', () {
    const settings = SubtitleSettings();
    expect(settings.backgroundOpacity, 1);
    expect(settings.effectiveBackgroundColor >>> 24, 0xFF);
    expect(SubtitleSettings.fromMap(<String, Object>{}).backgroundOpacity, 1);
  });

  test('cover items parse native events and reject broken ones', () {
    final cover = SubtitleCover.tryParse({
      'id': 3,
      'text': 'Merhaba',
      'left': 0.3,
      'top': 0.8,
      'width': 0.4,
      'height': 0.05,
      'lineHeight': 0.025,
    });
    expect(cover, isNotNull);
    expect(cover!.toMap(), {
      'id': 3,
      'text': 'Merhaba',
      'left': 0.3,
      'top': 0.8,
      'width': 0.4,
      'height': 0.05,
      'lineHeight': 0.025,
    });
    expect(SubtitleCover.tryParse({'id': 1, 'text': ' '}), isNull);
    expect(
      SubtitleCover.tryParse({
        'id': 1,
        'text': 'a',
        'left': 0.1,
        'top': 0.1,
        'width': 0,
        'height': 0.1,
      }),
      isNull,
    );
  });

  test('button icons travel with the translation and its covers', () {
    final rich = SubtitleRichText.fromEvent({
      'richText': 'Ayarlamak için $buttonIconPlaceholder tutun.',
      'icons': ['cG5n'],
    });
    expect(rich, isNotNull);
    expect(rich!.toMap(), {
      'text': 'Ayarlamak için $buttonIconPlaceholder tutun.',
      'icons': ['cG5n'],
    });
    expect(SubtitleRichText.fromEvent({'richText': 'Düz metin', 'icons': ['cG5n']}), isNull);
    expect(SubtitleRichText.fromEvent({'text': 'Düz metin'}), isNull);
    expect(buttonIconBytes('cG5n'), same(buttonIconBytes('cG5n')));

    final cover = SubtitleCover.tryParse({
      'id': 1,
      'text': 'Aç $buttonIconPlaceholder',
      'left': 0.2,
      'top': 0.7,
      'width': 0.3,
      'height': 0.04,
      'icons': ['cG5n'],
    })!;
    expect(cover.icons, ['cG5n']);
    expect(cover.toMap()['icons'], ['cG5n']);
  });

  test('a following subtitle area stays on its OCR area until detached', () {
    const second = NormalizedRect(left: 0.6, top: 0.1, width: 0.3, height: 0.1);
    const moved = NormalizedRect(left: 0.5, top: 0.4, width: 0.3, height: 0.1);
    const base = SubtitleSettings();
    final settings = base.copyWith(
      ocrRegions: [base.ocrRegion, second],
      ocrRegionSettings: [
        const OcrRegionSettings(),
        const OcrRegionSettings(subtitleFollowsOcr: true),
      ],
      subtitleRegions: [base.subtitleBounds, base.subtitleBounds],
    );
    // Lined up with its OCR area.
    final followed = settings.withFollowingSubtitles();
    expect(followed.effectiveSubtitleRegions[1].toMap(), second.toMap());
    expect(followed.effectiveSubtitleRegions[0].toMap(), base.subtitleBounds.toMap());
    // Moving the OCR area moves the subtitle area too.
    final movedOcr = followed.copyWith(ocrRegions: [base.ocrRegion, moved]).withFollowingSubtitles();
    expect(movedOcr.effectiveSubtitleRegions[1].toMap(), moved.toMap());
    // Once detached, the subtitle area keeps its own place.
    final detached = movedOcr.withSubtitleFollowing({1: false});
    final ownPlace = detached.copyWith(ocrRegions: [base.ocrRegion, second]).withFollowingSubtitles();
    expect(ownPlace.effectiveSubtitleRegions[1].toMap(), moved.toMap());
    // The setting is saved.
    final restored = SubtitleSettings.fromMap(followed.toMap());
    expect(restored.effectiveOcrSettings.map((s) => s.subtitleFollowsOcr), [false, true]);
  });
}
