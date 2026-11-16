import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
