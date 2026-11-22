import 'package:flutter/material.dart';

const subtitleOcrSamplingRatesHz = <double>[0.25, 0.5, 1, 2, 5, 10, 15, 20];
const subtitleOcrCaptureScales = <double>[1, 1.5, 2];

double normalizeSubtitleOcrCaptureScale(num? value) {
  if (value == null || !value.isFinite) return 1;
  // Older settings allowed 3x. PixelCopy was capped at 1600px, so keep those
  // profiles at the new 2x maximum instead of silently reducing their scale.
  if (value >= 2.5) return 2;
  return subtitleOcrCaptureScales.reduce(
    (a, b) => (a - value).abs() <= (b - value).abs() ? a : b,
  );
}

double normalizeSubtitleSamplingRate(num? value) {
  if (value == null || !value.isFinite) return 10;
  return subtitleOcrSamplingRatesHz.reduce(
    (a, b) => (a - value).abs() <= (b - value).abs() ? a : b,
  );
}

/// All coordinates are fractions of the native video surface, never screen pixels.
@immutable
class NormalizedRect {
  const NormalizedRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;

  Rect get rect => Rect.fromLTWH(left, top, width, height);

  factory NormalizedRect.fromRect(Rect rect) => NormalizedRect(
    left: rect.left.clamp(0.0, 1.0).toDouble(),
    top: rect.top.clamp(0.0, 1.0).toDouble(),
    width: rect.width.clamp(0.0, 1.0).toDouble(),
    height: rect.height.clamp(0.0, 1.0).toDouble(),
  );

  factory NormalizedRect.fromMap(Object? value, NormalizedRect fallback) {
    if (value is! Map) return fallback;
    double read(String key, double defaultValue) {
      final raw = value[key];
      if (raw is num && raw.isFinite) return raw.toDouble();
      return defaultValue;
    }

    final left = read('left', fallback.left).clamp(0.0, 0.98).toDouble();
    final top = read('top', fallback.top).clamp(0.0, 0.98).toDouble();
    final width = read(
      'width',
      fallback.width,
    ).clamp(0.02, 1.0 - left).toDouble();
    final height = read(
      'height',
      fallback.height,
    ).clamp(0.02, 1.0 - top).toDouble();
    return NormalizedRect(left: left, top: top, width: width, height: height);
  }

  Map<String, double> toMap() => {
    'left': left,
    'top': top,
    'width': width,
    'height': height,
  };
}

@immutable
class SubtitleSettings {
  const SubtitleSettings({
    this.ocrRegion = const NormalizedRect(
      left: 0.10,
      top: 0.78,
      width: 0.80,
      height: 0.22,
    ),
    this.ocrRegions = const [],
    this.subtitleBounds = const NormalizedRect(
      left: 0.10,
      top: 0.78,
      width: 0.80,
      height: 0.22,
    ),
    this.subtitleRegions = const [],
    this.subtitleStyles = const [],
    this.ocrRegionSettings = const [],
    this.sourceLanguageCode = 'en',
    this.targetLanguageCode = 'tr',
    this.sampleRateHz = 10,
    this.ocrPreprocessingMode = 0,
    this.ocrPreprocessingModes = const [],
    this.ocrDialogueFilter = false,
    this.ocrDialogueFilters = const [],
    this.ocrCaptureScale = 1,
    this.holdSeconds = 2.5,
    this.autoHideAfterSeconds = 2,
    this.backgroundColor = 0xFF000000,
    this.backgroundOpacity = 1,
    this.textColor = 0xFFFFFFFF,
    this.fontSize = 22,
    this.useGameFont = true,
    this.centered = true,
    this.bold = false,
    this.backgroundFitToText = true,
  });

  final NormalizedRect ocrRegion;
  final List<NormalizedRect> ocrRegions;

  List<NormalizedRect> get effectiveOcrRegions =>
      ocrRegions.isEmpty ? <NormalizedRect>[ocrRegion] : ocrRegions;
  final NormalizedRect subtitleBounds;
  final List<NormalizedRect> subtitleRegions;
  final List<SubtitleAppearance> subtitleStyles;
  final List<OcrRegionSettings> ocrRegionSettings;
  List<NormalizedRect> get effectiveSubtitleRegions => subtitleRegions.isEmpty
      ? <NormalizedRect>[subtitleBounds]
      : subtitleRegions;
  final String sourceLanguageCode;
  final String targetLanguageCode;
  final double sampleRateHz;

  /// 0 = original, 1 = grayscale/contrast, 2 = adaptive threshold.
  final int ocrPreprocessingMode;

  /// Optional filter override for each OCR region, in region order.
  final List<int> ocrPreprocessingModes;
  List<int> get effectiveOcrPreprocessingModes => effectiveOcrSettings
      .map((settings) => settings.ocrPreprocessingMode.clamp(0, 9))
      .toList();
  int ocrPreprocessingModeFor(int index) =>
      index >= 0 && index < effectiveOcrRegions.length
      ? effectiveOcrPreprocessingModes[index]
      : ocrPreprocessingMode;

  /// Optional dialogue-only recognition per OCR region; disabled by default.
  final bool ocrDialogueFilter;
  final List<bool> ocrDialogueFilters;
  List<bool> get effectiveOcrDialogueFilters => effectiveOcrSettings
      .map((settings) => settings.ocrDialogueFilter)
      .toList();
  bool ocrDialogueFilterFor(int index) =>
      index >= 0 && index < effectiveOcrRegions.length
      ? effectiveOcrDialogueFilters[index]
      : ocrDialogueFilter;

  final double ocrCaptureScale;
  final double holdSeconds;
  bool get autoHideEnabled => true;
  final double autoHideAfterSeconds;
  final int backgroundColor;

  /// Background opacity, independent of the ARGB color's alpha byte.
  /// 0.0 is invisible; 1.0 is fully opaque.
  final double backgroundOpacity;
  int get effectiveBackgroundColor => Color(
    backgroundColor,
  ).withValues(alpha: backgroundOpacity.clamp(0.0, 1.0)).toARGB32();
  final int textColor;
  final double fontSize;

  /// A personal preference; selecting/reloading a game must not overwrite it.
  final bool useGameFont;
  final bool centered;
  final bool bold;
  final bool backgroundFitToText;

  SubtitleAppearance get appearance => SubtitleAppearance(
    backgroundColor: backgroundColor,
    backgroundOpacity: backgroundOpacity,
    textColor: textColor,
    fontSize: fontSize,
    useGameFont: useGameFont,
    centered: centered,
    bold: bold,
    backgroundFitToText: backgroundFitToText,
  );

  List<SubtitleAppearance> get effectiveSubtitleStyles => List.generate(
    effectiveSubtitleRegions.length,
    (index) =>
        index < subtitleStyles.length ? subtitleStyles[index] : appearance,
  );

  SubtitleSettings settingsForSubtitle(int index) =>
      effectiveSubtitleStyles[index].applyTo(this);

  List<OcrRegionSettings> get effectiveOcrSettings => List.generate(
    effectiveOcrRegions.length,
    (index) => index < ocrRegionSettings.length
        ? ocrRegionSettings[index]
        : OcrRegionSettings(
            sampleRateHz: sampleRateHz,
            ocrPreprocessingMode: index < ocrPreprocessingModes.length
                ? ocrPreprocessingModes[index]
                : ocrPreprocessingMode,
            ocrDialogueFilter: index < ocrDialogueFilters.length
                ? ocrDialogueFilters[index]
                : ocrDialogueFilter,
            ocrCaptureScale: ocrCaptureScale,
            holdSeconds: holdSeconds,
            autoHideAfterSeconds: autoHideAfterSeconds,
          ),
  );

  /// True when OCR 1 draws its translations over the English subtitle.
  bool get coversEnglishSubtitle {
    final settings = effectiveOcrSettings;
    return settings.isNotEmpty && settings.first.coverEnglishSubtitle;
  }

  /// Puts every subtitle area that follows its OCR area back onto it.
  SubtitleSettings withFollowingSubtitles() {
    final ocr = effectiveOcrRegions;
    final settings = effectiveOcrSettings;
    final subtitles = List<NormalizedRect>.of(effectiveSubtitleRegions);
    var changed = false;
    for (var index = 0; index < ocr.length && index < subtitles.length; index++) {
      if (index >= settings.length || !settings[index].subtitleFollowsOcr) {
        continue;
      }
      final from = ocr[index];
      final to = subtitles[index];
      if (from.left == to.left &&
          from.top == to.top &&
          from.width == to.width &&
          from.height == to.height) {
        continue;
      }
      subtitles[index] = from;
      changed = true;
    }
    return changed
        ? copyWith(subtitleBounds: subtitles.first, subtitleRegions: subtitles)
        : this;
  }

  /// Turns following on or off for the given areas, then lines them up.
  SubtitleSettings withSubtitleFollowing(Map<int, bool> follows) {
    final values = effectiveOcrSettings;
    var changed = false;
    follows.forEach((index, follow) {
      if (index < 0 || index >= values.length) return;
      if (values[index].subtitleFollowsOcr == follow) return;
      values[index] = values[index].copyWith(subtitleFollowsOcr: follow);
      changed = true;
    });
    if (!changed) return withFollowingSubtitles();
    return copyWith(ocrRegionSettings: values).withFollowingSubtitles();
  }

  SubtitleSettings withSubtitleStyle(int index, SubtitleSettings settings) {
    final styles = effectiveSubtitleStyles;
    styles[index] = settings.appearance;
    return styles.first.applyTo(this).copyWith(subtitleStyles: styles);
  }

  SubtitleSettings withOcrSettings(int index, OcrRegionSettings settings) {
    final values = effectiveOcrSettings;
    values[index] = settings;
    final first = values.first;
    return copyWith(
      ocrRegionSettings: values,
      sampleRateHz: first.sampleRateHz,
      ocrCaptureScale: first.ocrCaptureScale,
      holdSeconds: first.holdSeconds,
      autoHideAfterSeconds: first.autoHideAfterSeconds,
      ocrPreprocessingMode: first.ocrPreprocessingMode,
      ocrDialogueFilter: first.ocrDialogueFilter,
      ocrPreprocessingModes: values.map((s) => s.ocrPreprocessingMode).toList(),
      ocrDialogueFilters: values.map((s) => s.ocrDialogueFilter).toList(),
    );
  }

  SubtitleSettings copyWith({
    NormalizedRect? ocrRegion,
    List<NormalizedRect>? ocrRegions,
    NormalizedRect? subtitleBounds,
    List<NormalizedRect>? subtitleRegions,
    List<SubtitleAppearance>? subtitleStyles,
    List<OcrRegionSettings>? ocrRegionSettings,
    String? sourceLanguageCode,
    String? targetLanguageCode,
    double? sampleRateHz,
    int? ocrPreprocessingMode,
    List<int>? ocrPreprocessingModes,
    bool? ocrDialogueFilter,
    List<bool>? ocrDialogueFilters,
    double? ocrCaptureScale,
    double? holdSeconds,
    double? autoHideAfterSeconds,
    int? backgroundColor,
    double? backgroundOpacity,
    int? textColor,
    double? fontSize,
    bool? useGameFont,
    bool? centered,
    bool? bold,
    bool? backgroundFitToText,
  }) => SubtitleSettings(
    ocrRegion: ocrRegion ?? this.ocrRegion,
    ocrRegions: ocrRegions ?? this.ocrRegions,
    subtitleBounds:
        subtitleBounds ??
        (subtitleRegions != null && subtitleRegions.isNotEmpty
            ? subtitleRegions.first
            : this.subtitleBounds),
    subtitleRegions: subtitleRegions ?? this.subtitleRegions,
    subtitleStyles: subtitleStyles ?? this.subtitleStyles,
    ocrRegionSettings: ocrRegionSettings ?? this.ocrRegionSettings,
    sourceLanguageCode: sourceLanguageCode ?? this.sourceLanguageCode,
    targetLanguageCode: targetLanguageCode ?? this.targetLanguageCode,
    sampleRateHz: sampleRateHz ?? this.sampleRateHz,
    ocrPreprocessingMode: ocrPreprocessingMode ?? this.ocrPreprocessingMode,
    ocrPreprocessingModes: ocrPreprocessingModes ?? this.ocrPreprocessingModes,
    ocrDialogueFilter: ocrDialogueFilter ?? this.ocrDialogueFilter,
    ocrDialogueFilters: ocrDialogueFilters ?? this.ocrDialogueFilters,
    ocrCaptureScale: ocrCaptureScale ?? this.ocrCaptureScale,
    holdSeconds: holdSeconds ?? this.holdSeconds,
    autoHideAfterSeconds: autoHideAfterSeconds ?? this.autoHideAfterSeconds,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
    textColor: textColor ?? this.textColor,
    fontSize: fontSize ?? this.fontSize,
    useGameFont: useGameFont ?? this.useGameFont,
    centered: centered ?? this.centered,
    bold: bold ?? this.bold,
    backgroundFitToText: backgroundFitToText ?? this.backgroundFitToText,
  );

  factory SubtitleSettings.fromMap(Object? value) {
    final defaults = const SubtitleSettings();
    if (value is! Map) return defaults;
    final region = NormalizedRect.fromMap(
      value['ocrRegion'],
      defaults.ocrRegion,
    );
    final regionsValue = value['ocrRegions'];
    final regions = regionsValue is List
        ? regionsValue
              .map((entry) => NormalizedRect.fromMap(entry, region))
              .toList()
        : <NormalizedRect>[];
    final subtitle = NormalizedRect.fromMap(
      value['subtitleBounds'],
      defaults.subtitleBounds,
    );
    final subtitleRegionsValue = value['subtitleRegions'];
    final subtitleRegions = subtitleRegionsValue is List
        ? subtitleRegionsValue
              .map((entry) => NormalizedRect.fromMap(entry, subtitle))
              .toList()
        : <NormalizedRect>[];
    final rate = value['sampleRateHz'];
    final hold = value['holdSeconds'];
    final autoHideAfter = value['autoHideAfterSeconds'];
    final font = value['fontSize'];
    final bg = value['backgroundColor'];
    final fg = value['textColor'];
    final preprocessingModesValue = value['ocrPreprocessingModes'];
    final preprocessingModes = preprocessingModesValue is List
        ? preprocessingModesValue
              .whereType<num>()
              .map((mode) => mode.round().clamp(0, 9))
              .take(12)
              .toList()
        : <int>[];
    final dialogueFilterFallback = value['ocrDialogueFilter'] is bool
        ? value['ocrDialogueFilter'] as bool
        : false;
    final dialogueFiltersValue = value['ocrDialogueFilters'];
    final dialogueFilters = dialogueFiltersValue is List
        ? dialogueFiltersValue
              .map((filter) => filter is bool ? filter : dialogueFilterFallback)
              .take(12)
              .toList()
        : <bool>[];
    return SubtitleSettings(
      ocrRegion: region,
      ocrRegions: regions,
      subtitleBounds: subtitle,
      subtitleRegions: subtitleRegions,
      subtitleStyles: value['subtitleStyles'] is List
          ? (value['subtitleStyles'] as List)
                .take(12)
                .map(SubtitleAppearance.fromMap)
                .toList()
          : const [],
      ocrRegionSettings: value['ocrRegionSettings'] is List
          ? (value['ocrRegionSettings'] as List)
                .take(12)
                .map(OcrRegionSettings.fromMap)
                .toList()
          : const [],
      sourceLanguageCode: value['sourceLanguageCode'] is String
          ? value['sourceLanguageCode'] as String
          : 'en',
      targetLanguageCode: value['targetLanguageCode'] is String
          ? value['targetLanguageCode'] as String
          : 'tr',
      sampleRateHz: normalizeSubtitleSamplingRate(rate is num ? rate : null),
      ocrPreprocessingMode: value['ocrPreprocessingMode'] is num
          ? (value['ocrPreprocessingMode'] as num).round().clamp(0, 9)
          : 0,
      ocrPreprocessingModes: preprocessingModes,
      ocrDialogueFilter: dialogueFilterFallback,
      ocrDialogueFilters: dialogueFilters,
      ocrCaptureScale: normalizeSubtitleOcrCaptureScale(
        value['ocrCaptureScale'] is num
            ? value['ocrCaptureScale'] as num
            : null,
      ),
      holdSeconds: hold is num ? hold.toDouble().clamp(0, 10).toDouble() : 2.5,
      autoHideAfterSeconds: autoHideAfter is num
          ? autoHideAfter.toDouble().clamp(0.5, 30).toDouble()
          : 2,
      backgroundColor: bg is num ? bg.toInt() : defaults.backgroundColor,
      backgroundOpacity: value['backgroundOpacity'] is num
          ? (value['backgroundOpacity'] as num)
                .toDouble()
                .clamp(0.0, 1.0)
                .toDouble()
          : bg is num
          ? Color(bg.toInt()).a
          : defaults.backgroundOpacity,
      textColor: fg is num ? fg.toInt() : defaults.textColor,
      fontSize: font is num ? font.toDouble().clamp(4, 64).toDouble() : 22,
      useGameFont: value['useGameFont'] is bool
          ? value['useGameFont'] as bool
          : true,
      centered: value['centered'] is bool ? value['centered'] as bool : true,
      bold: value['bold'] is bool ? value['bold'] as bool : false,
      backgroundFitToText: value['backgroundFitToText'] is bool
          ? value['backgroundFitToText'] as bool
          : defaults.backgroundFitToText,
    );
  }

  Map<String, Object> toMap() => {
    'ocrRegion': ocrRegion.toMap(),
    'ocrRegions': effectiveOcrRegions.map((rect) => rect.toMap()).toList(),
    'subtitleBounds': effectiveSubtitleRegions.first.toMap(),
    'subtitleRegions': effectiveSubtitleRegions
        .map((rect) => rect.toMap())
        .toList(),
    'subtitleStyles': effectiveSubtitleStyles.map((s) => s.toMap()).toList(),
    'ocrRegionSettings': effectiveOcrSettings.map((s) => s.toMap()).toList(),
    // Older Android and TV builds still read this field.
    'enabled': true,
    'sourceLanguageCode': sourceLanguageCode,
    'targetLanguageCode': targetLanguageCode,
    'sampleRateHz': sampleRateHz,
    'ocrPreprocessingMode': ocrPreprocessingMode,
    'ocrPreprocessingModes': effectiveOcrPreprocessingModes,
    'ocrDialogueFilter': ocrDialogueFilter,
    'ocrDialogueFilters': effectiveOcrDialogueFilters,
    'ocrCaptureScale': ocrCaptureScale,
    'holdSeconds': holdSeconds,
    'autoHideEnabled': true,
    'autoHideAfterSeconds': autoHideAfterSeconds,
    'backgroundColor': effectiveBackgroundColor,
    'backgroundOpacity': backgroundOpacity.clamp(0.0, 1.0),
    'textColor': textColor,
    'fontSize': fontSize,
    'useGameFont': useGameFont,
    'centered': centered,
    'bold': bold,
    'backgroundFitToText': backgroundFitToText,
  };
}

@immutable
class SubtitleAppearance {
  const SubtitleAppearance({
    this.backgroundColor = 0xFF000000,
    this.backgroundOpacity = 1,
    this.textColor = 0xFFFFFFFF,
    this.fontSize = 22,
    this.useGameFont = true,
    this.centered = true,
    this.bold = false,
    this.backgroundFitToText = true,
  });

  final int backgroundColor;
  final double backgroundOpacity;
  final int textColor;
  final double fontSize;
  final bool useGameFont;
  final bool centered;
  final bool bold;
  final bool backgroundFitToText;

  SubtitleAppearance copyWith({
    int? backgroundColor,
    double? backgroundOpacity,
    int? textColor,
    double? fontSize,
    bool? useGameFont,
    bool? centered,
    bool? bold,
    bool? backgroundFitToText,
  }) => SubtitleAppearance(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
    textColor: textColor ?? this.textColor,
    fontSize: fontSize ?? this.fontSize,
    useGameFont: useGameFont ?? this.useGameFont,
    centered: centered ?? this.centered,
    bold: bold ?? this.bold,
    backgroundFitToText: backgroundFitToText ?? this.backgroundFitToText,
  );

  SubtitleSettings applyTo(SubtitleSettings settings) => settings.copyWith(
    backgroundColor: backgroundColor,
    backgroundOpacity: backgroundOpacity,
    textColor: textColor,
    fontSize: fontSize,
    useGameFont: useGameFont,
    centered: centered,
    bold: bold,
    backgroundFitToText: backgroundFitToText,
  );

  factory SubtitleAppearance.fromMap(Object? value) {
    final map = value is Map ? value : const <String, Object>{};
    return SubtitleAppearance(
      backgroundColor: _regionNumber(
        map['backgroundColor'],
        0xFF000000,
      ).toInt(),
      backgroundOpacity: _regionNumber(
        map['backgroundOpacity'],
        ((_regionNumber(map['backgroundColor'], 0xFF000000).toInt() >> 24) &
                255) /
            255,
      ).clamp(0.0, 1.0).toDouble(),
      textColor: _regionNumber(map['textColor'], 0xFFFFFFFF).toInt(),
      fontSize: _regionNumber(map['fontSize'], 22).clamp(4, 64).toDouble(),
      useGameFont: map['useGameFont'] is bool
          ? map['useGameFont'] as bool
          : true,
      centered: map['centered'] is bool ? map['centered'] as bool : true,
      bold: map['bold'] is bool ? map['bold'] as bool : false,
      backgroundFitToText: map['backgroundFitToText'] is bool
          ? map['backgroundFitToText'] as bool
          : true,
    );
  }

  Map<String, Object> toMap() => {
    'backgroundColor': backgroundColor,
    'backgroundOpacity': backgroundOpacity,
    'textColor': textColor,
    'fontSize': fontSize,
    'useGameFont': useGameFont,
    'centered': centered,
    'bold': bold,
    'backgroundFitToText': backgroundFitToText,
  };
}

@immutable
class OcrRegionSettings {
  const OcrRegionSettings({
    this.sampleRateHz = 10,
    this.ocrPreprocessingMode = 0,
    this.ocrDialogueFilter = false,
    this.ocrCaptureScale = 1,
    this.holdSeconds = 2.5,
    this.autoHideAfterSeconds = 2,
    this.coverEnglishSubtitle = true,
    this.subtitleFollowsOcr = false,
  });

  final double sampleRateHz;
  final int ocrPreprocessingMode;
  final bool ocrDialogueFilter;
  final double ocrCaptureScale;
  final double holdSeconds;
  final double autoHideAfterSeconds;

  /// Draws each translation directly over the English subtitle it came from
  /// instead of in the fixed subtitle box. Only offered for OCR 1.
  final bool coverEnglishSubtitle;

  /// The subtitle area with the same number sits exactly on this OCR area and
  /// moves with it. Set for areas added later; moving the subtitle area by hand
  /// turns it off.
  final bool subtitleFollowsOcr;

  OcrRegionSettings copyWith({
    double? sampleRateHz,
    int? ocrPreprocessingMode,
    bool? ocrDialogueFilter,
    double? ocrCaptureScale,
    double? holdSeconds,
    double? autoHideAfterSeconds,
    bool? coverEnglishSubtitle,
    bool? subtitleFollowsOcr,
  }) => OcrRegionSettings(
    sampleRateHz: sampleRateHz ?? this.sampleRateHz,
    ocrPreprocessingMode: ocrPreprocessingMode ?? this.ocrPreprocessingMode,
    ocrDialogueFilter: ocrDialogueFilter ?? this.ocrDialogueFilter,
    ocrCaptureScale: ocrCaptureScale ?? this.ocrCaptureScale,
    holdSeconds: holdSeconds ?? this.holdSeconds,
    autoHideAfterSeconds: autoHideAfterSeconds ?? this.autoHideAfterSeconds,
    coverEnglishSubtitle: coverEnglishSubtitle ?? this.coverEnglishSubtitle,
    subtitleFollowsOcr: subtitleFollowsOcr ?? this.subtitleFollowsOcr,
  );

  factory OcrRegionSettings.fromMap(Object? value) {
    final map = value is Map ? value : const <String, Object>{};
    return OcrRegionSettings(
      sampleRateHz: normalizeSubtitleSamplingRate(
        map['sampleRateHz'] is num ? map['sampleRateHz'] as num : null,
      ),
      ocrPreprocessingMode: _regionNumber(
        map['ocrPreprocessingMode'],
        0,
      ).round().clamp(0, 9),
      ocrDialogueFilter: map['ocrDialogueFilter'] is bool
          ? map['ocrDialogueFilter'] as bool
          : false,
      ocrCaptureScale: normalizeSubtitleOcrCaptureScale(
        map['ocrCaptureScale'] is num ? map['ocrCaptureScale'] as num : null,
      ),
      holdSeconds: _regionNumber(
        map['holdSeconds'],
        2.5,
      ).clamp(0, 10).toDouble(),
      autoHideAfterSeconds: _regionNumber(
        map['autoHideAfterSeconds'],
        2,
      ).clamp(0.5, 30).toDouble(),
      coverEnglishSubtitle: map['ocrCoverEnglish'] is bool
          ? map['ocrCoverEnglish'] as bool
          : true,
      subtitleFollowsOcr: map['ocrSubtitleFollows'] == true,
    );
  }

  Map<String, Object> toMap() => {
    'sampleRateHz': sampleRateHz,
    'ocrPreprocessingMode': ocrPreprocessingMode,
    'ocrDialogueFilter': ocrDialogueFilter,
    'ocrCaptureScale': ocrCaptureScale,
    'holdSeconds': holdSeconds,
    'autoHideAfterSeconds': autoHideAfterSeconds,
    'ocrCoverEnglish': coverEnglishSubtitle,
    'ocrSubtitleFollows': subtitleFollowsOcr,
  };
}

num _regionNumber(Object? value, num fallback) =>
    value is num && value.isFinite ? value : fallback;
