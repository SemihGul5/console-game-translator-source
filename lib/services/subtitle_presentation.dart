import '../models/subtitle_settings.dart';
import 'game_fonts.dart';

/// Keeps mobile, Android TV and Samsung TV on the same per-area appearance.
Map<String, Object> subtitlePresentation(SubtitleSettings settings) => {
  'enabled': true,
  'targetLanguage': settings.targetLanguageCode,
  'textDirection':
      const {
        'ar',
        'fa',
        'he',
        'ur',
      }.contains(settings.targetLanguageCode.split('-').first)
      ? 'rtl'
      : 'ltr',
  ..._appearance(settings.settingsForSubtitle(0)),
  'subtitleBounds': settings.effectiveSubtitleRegions.first.toMap(),
  'subtitleRegions': settings.effectiveSubtitleRegions
      .map((r) => r.toMap())
      .toList(),
  'subtitleStyles': [
    for (
      var index = 0;
      index < settings.effectiveSubtitleRegions.length;
      index++
    )
      {
        ..._appearance(settings.settingsForSubtitle(index)),
        // Area 1 is drawn over the English subtitle lines instead of in its
        // fixed box. Older receivers ignore the flag and keep the fixed box.
        if (index == 0 && settings.coversEnglishSubtitle) 'coverEnglish': true,
      },
  ],
};

Map<String, Object> _appearance(SubtitleSettings settings) => {
  ...settings.appearance.toMap(),
  'backgroundColor': settings.effectiveBackgroundColor,
  'backgroundOpacity': settings.backgroundOpacity.clamp(0.0, 1.0),
  'backgroundAlpha': (settings.backgroundOpacity * 255).round(),
  if (GameFonts.forSettings(settings) case final font?)
    'fontSha256': font.sha256,
};

bool subtitlePresentationUsesFont(Map presentation, String hash) =>
    presentation['fontSha256'] == hash ||
    (presentation['subtitleStyles'] is List &&
        (presentation['subtitleStyles'] as List).whereType<Map>().any(
          (style) => style['fontSha256'] == hash,
        ));
