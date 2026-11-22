import 'support/turkish_test_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gametranslate/models/subtitle_settings.dart';
import 'package:gametranslate/screens/ps5_stream_screen.dart';
import 'package:gametranslate/widgets/normalized_rect_editor.dart';
import 'package:gametranslate/widgets/game_subtitle_text.dart';
import 'package:gametranslate/services/game_fonts.dart';
import 'package:gametranslate/services/subtitle_settings_store.dart';

const _channel = MethodChannel(
  'com.abrebostudio.consolegametranslator/ps5_registration',
);
const _eventsChannel = MethodChannel(
  'com.abrebostudio.consolegametranslator/ps5_events',
);

Finder get _fontSlider => find.byWidgetPredicate(
  (widget) => widget is Slider && widget.min == 4 && widget.max == 64,
);

/// OCR settings are only shown in the OCR area mode.
Future<void> _showOcrSettings(WidgetTester tester) async {
  final target = find.text('OCR alanı').first;
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _openSettings(WidgetTester tester) async {
  await tester.pumpWidget(
    const TurkishTestApp(
      home: Ps5StreamScreen(openSubtitleSettingsOnStart: true),
    ),
  );
  await tester.pumpAndSettle();
}

/// These tests cover the fixed subtitle area, so the over-the-English mode
/// (on by default for OCR 1) is switched off for them.
Map<Object?, Object?> _fixedArea(SubtitleSettings settings) => settings
    .withOcrSettings(
      0,
      settings.effectiveOcrSettings.first.copyWith(coverEnglishSubtitle: false),
    )
    .toMap();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<Object?, Object?> savedSettings;
  late int saveCount;
  late bool failSaving;

  setUp(() {
    GameFonts.active.value = null;
    savedSettings = _fixedArea(const SubtitleSettings());
    saveCount = 0;
    failSaving = false;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_channel, (call) async {
      switch (call.method) {
        case 'getSubtitleSettings':
          return savedSettings;
        case 'saveSubtitleSettings':
          if (failSaving) {
            throw PlatformException(code: 'SUBTITLE_SETTINGS_SAVE_FAILED');
          }
          savedSettings = Map<Object?, Object?>.from(call.arguments as Map);
          saveCount++;
          return true;
        case 'getSessionState':
          return <String, Object>{'active': false};
        default:
          return null;
      }
    });
    messenger.setMockMethodCallHandler(_eventsChannel, (_) async => null);
    messenger.setMockMethodCallHandler(SystemChannels.platform_views, (
      call,
    ) async {
      if (call.method == 'create') return 1;
      if (call.method == 'resize') {
        final arguments = call.arguments as Map;
        return <String, Object?>{
          'width': arguments['width'],
          'height': arguments['height'],
        };
      }
      return null;
    });
  });

  tearDown(() {
    GameFonts.active.value = null;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_channel, null);
    messenger.setMockMethodCallHandler(_eventsChannel, null);
    messenger.setMockMethodCallHandler(SystemChannels.platform_views, null);
  });

  testWidgets(
    'subtitle areas keep independent defaults, appearance and saved edits',
    (tester) async {
      savedSettings = _fixedArea(const SubtitleSettings(
        fontSize: 38,
        useGameFont: false,
        textColor: 0xFFFFFF00,
        backgroundColor: 0xFF00315B,
        backgroundOpacity: 0.8,
        centered: false,
        bold: true,
        backgroundFitToText: false,
      ));
      await _openSettings(tester);
      Future<void> tap(String label) async {
        final target = find.text(label);
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      await tap('Altyazı alanı ekle');
      expect(tester.widget<Slider>(_fontSlider).value, 22);
      final previews = tester
          .widgetList<GameSubtitleText>(find.byType(GameSubtitleText))
          .toList();
      expect(previews.map((p) => p.settings.fontSize), [38, 22]);
      expect(previews.map((p) => p.settings.textColor), [
        0xFFFFFF00,
        0xFFFFFFFF,
      ]);
      expect(previews.map((p) => p.settings.useGameFont), [false, true]);
      expect(previews.map((p) => p.settings.backgroundFitToText), [
        false,
        true,
      ]);

      tester.widget<Slider>(_fontSlider).onChanged!(29);
      await tester.pump();
      await tap('Normal');
      await tap('Seçili alanı doldur');
      await tap('Altyazı 1');
      expect(tester.widget<Slider>(_fontSlider).value, 38);
      await tap('Altyazı 2');
      expect(tester.widget<Slider>(_fontSlider).value, 29);
      await tap('Kaydet');
      await tester.pumpWidget(const SizedBox.shrink());
      await _openSettings(tester);
      expect(tester.widget<Slider>(_fontSlider).value, 38);
      await tap('Altyazı 2');
      expect(tester.widget<Slider>(_fontSlider).value, 29);
      expect(
        tester
            .widget<ChoiceChip>(
              find.widgetWithText(ChoiceChip, 'Seçili alanı doldur'),
            )
            .selected,
        isTrue,
      );

      // Deleting the first area retains the second area's own settings.
      await tap('Altyazı 1');
      await tap('Seçili alanı sil');
      expect(tester.widget<Slider>(_fontSlider).value, 29);
      await tap('Altyazı alanı ekle');
      expect(tester.widget<Slider>(_fontSlider).value, 22);
      await tester.pumpWidget(const SizedBox.shrink());
      final restored = SubtitleSettings.fromMap(savedSettings);
      expect(restored.effectiveSubtitleStyles.map((s) => s.fontSize), [29, 22]);
    },
  );

  testWidgets(
    'OCR areas keep independent scan settings after adding, switching, saving and deleting',
    (tester) async {
      savedSettings = _fixedArea(const SubtitleSettings(
        sampleRateHz: 2,
        ocrCaptureScale: 2,
        ocrPreprocessingMode: 4,
        ocrDialogueFilter: true,
        holdSeconds: 6,
        autoHideAfterSeconds: 9,
      ));
      await _openSettings(tester);
      Future<void> tap(String label) async {
        final target = find.text(label);
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      Finder dropdown(Type type) =>
          find.byWidgetPredicate((w) => w.runtimeType == type);
      final rate = find.byWidgetPredicate(
        (w) =>
            w is DropdownButton<double> &&
            w.items!.any((item) => item.value == 20),
      );
      final scale = dropdown(DropdownButtonFormField<double>);
      final filter = dropdown(DropdownButtonFormField<int>);
      // OCR 1 also shows the over-the-English switch; pick the dialogue filter.
      final dialogueSwitch = find.ancestor(
        of: find.textContaining('diyalog filtresi'),
        matching: find.byType(SwitchListTile),
      );

      await tap('OCR alanı');
      await tap('OCR alanı ekle');
      expect(tester.widget<DropdownButton<double>>(rate).value, 10);
      expect(
        tester.widget<DropdownButtonFormField<double>>(scale).initialValue,
        1,
      );
      expect(
        tester.widget<DropdownButtonFormField<int>>(filter).initialValue,
        0,
      );
      expect(
        tester.widget<SwitchListTile>(dialogueSwitch).value,
        isFalse,
      );
      tester.widget<DropdownButton<double>>(rate).onChanged!(5);
      await tester.pump();
      tester.widget<DropdownButtonFormField<double>>(scale).onChanged!(1.5);
      await tester.pump();
      tester.widget<DropdownButtonFormField<int>>(filter).onChanged!(9);
      await tester.pump();
      final hold = find.byWidgetPredicate(
        (w) => w is Slider && w.min == 0 && w.max == 10,
      );
      final hide = find.byWidgetPredicate(
        (w) => w is Slider && w.min == 0.5 && w.max == 30,
      );
      tester.widget<Slider>(hold).onChanged!(4);
      await tester.pump();
      tester.widget<Slider>(hide).onChanged!(7);
      await tester.pump();
      await tap('OCR 1');
      expect(tester.widget<DropdownButton<double>>(rate).value, 2);
      expect(
        tester.widget<DropdownButtonFormField<double>>(scale).initialValue,
        2,
      );
      expect(
        tester.widget<DropdownButtonFormField<int>>(filter).initialValue,
        4,
      );
      expect(
        tester.widget<SwitchListTile>(dialogueSwitch).value,
        isTrue,
      );
      expect(tester.widget<Slider>(hold).value, 6);
      expect(tester.widget<Slider>(hide).value, 9);
      await tap('Kaydet');
      await tester.pumpWidget(const SizedBox.shrink());
      await _openSettings(tester);
      await tap('OCR alanı');
      await tap('OCR 2');
      expect(tester.widget<DropdownButton<double>>(rate).value, 5);
      expect(
        tester.widget<DropdownButtonFormField<double>>(scale).initialValue,
        1.5,
      );
      expect(
        tester.widget<DropdownButtonFormField<int>>(filter).initialValue,
        9,
      );
      expect(tester.widget<Slider>(hold).value, 4);
      expect(tester.widget<Slider>(hide).value, 7);
      await tap('OCR 1');
      await tap('Seçili OCR alanını sil');
      expect(tester.widget<DropdownButton<double>>(rate).value, 5);
      await tap('OCR alanı ekle');
      expect(tester.widget<DropdownButton<double>>(rate).value, 10);
      await tester.pumpWidget(const SizedBox.shrink());
      final restored = SubtitleSettings.fromMap(savedSettings);
      expect(restored.effectiveOcrSettings.map((s) => s.sampleRateHz), [5, 10]);
    },
  );

  test(
    'font preference survives ordinary edits and named profile serialization',
    () {
      const settings = SubtitleSettings(
        useGameFont: false,
        fontSize: 31,
        textColor: 0xFFFFEB3B,
      );
      final profile = SubtitleProfile.fromMap(
        SubtitleProfile(
          name: 'My game',
          settings: settings.copyWith(fontSize: 36),
        ).toMap(),
      );
      expect(profile.settings.useGameFont, isFalse);
      expect(profile.settings.fontSize, 36);
      expect(profile.settings.textColor, settings.textColor);
      expect(SubtitleSettings.fromMap(<String, Object>{}).useGameFont, isTrue);
    },
  );

  testWidgets(
    'selected game keeps editable appearance and position, including a saved system-font override',
    (tester) async {
      final gameFont = LoadedGameFont(sha256: 'f' * 64, bytes: Uint8List(12));
      GameFonts.active.value = gameFont;
      savedSettings = _fixedArea(const SubtitleSettings(
        fontSize: 31,
        textColor: 0xFFFFEB3B,
        backgroundColor: 0xFF00315B,
        backgroundOpacity: 0.6,
        centered: false,
        bold: true,
      ));
      await _openSettings(tester);
      final systemChip = find.byKey(const ValueKey('subtitle-font-system'));
      await tester.ensureVisible(systemChip);
      await tester.tap(systemChip);
      tester.widget<Slider>(_fontSlider).onChanged!(38);
      const bounds = NormalizedRect(
        left: 0.21,
        top: 0.35,
        width: 0.55,
        height: 0.2,
      );
      tester
          .widget<NormalizedRectEditor>(find.byType(NormalizedRectEditor))
          .onChanged(bounds);
      await tester.pump(const Duration(milliseconds: 301));
      await tester.pumpAndSettle();
      expect(savedSettings['useGameFont'], isFalse);
      expect(savedSettings['fontSize'], 38);
      expect((savedSettings['subtitleRegions'] as List).first, bounds.toMap());
      expect(savedSettings['textColor'], 0xFFFFEB3B);
      expect(savedSettings['backgroundOpacity'], 0.6);
      expect(savedSettings['centered'], isFalse);
      expect(savedSettings['bold'], isTrue);
      // A game-font reload is presentation data, not permission to reset user choices.
      GameFonts.active.value = LoadedGameFont(
        sha256: 'e' * 64,
        bytes: Uint8List(12),
      );
      await tester.pump();
      expect(tester.widget<ChoiceChip>(systemChip).selected, isTrue);
      expect(
        tester.widget<Text>(find.text('Altyazı önizlemesi')).style!.fontFamily,
        isNull,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await _openSettings(tester);
      expect(tester.widget<ChoiceChip>(systemChip).selected, isTrue);
      expect(tester.widget<Slider>(_fontSlider).value, 38);
      expect(savedSettings['textColor'], 0xFFFFEB3B);
      expect((savedSettings['subtitleRegions'] as List).first, bounds.toMap());
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('a previously disabled overlay is restored without a toggle', (
    tester,
  ) async {
    savedSettings = <Object?, Object?>{
      ..._fixedArea(const SubtitleSettings(fontSize: 31)),
      'enabled': false,
    };
    await _openSettings(tester);

    expect(find.text('Altyazı overlay’i'), findsNothing);
    expect(find.byKey(const ValueKey('subtitle-output-0')), findsOneWidget);
    expect(tester.widget<Slider>(_fontSlider).value, 31);

    tester.widget<Slider>(_fontSlider).onChanged!(32);
    await tester.pump(const Duration(milliseconds: 301));
    await tester.pumpAndSettle();
    expect(savedSettings['enabled'], isTrue);
    expect(savedSettings['fontSize'], 32);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('missing OCR settings use 10 scans per second and 1x capture', () {
    for (final settings in [
      const SubtitleSettings(),
      SubtitleSettings.fromMap(<String, Object>{}),
    ]) {
      expect(settings.sampleRateHz, 10);
      expect(settings.ocrCaptureScale, 1);
    }
    final saved = SubtitleSettings.fromMap(
      const SubtitleSettings(sampleRateHz: 5, ocrCaptureScale: 1.5).toMap(),
    );
    expect(saved.sampleRateHz, 5);
    expect(saved.ocrCaptureScale, 1.5);
  });

  for (final rate in [15.0, 20.0]) {
    testWidgets(
      'OCR $rate scans per second is selectable and survives reopening',
      (tester) async {
        savedSettings = <Object?, Object?>{};
        await _openSettings(tester);
        await _showOcrSettings(tester);
        final rateDropdown = find.byWidgetPredicate(
          (widget) =>
              widget is DropdownButton<double> &&
              widget.items!.any((item) => item.value == 20),
        );
        final scaleDropdown = find.byWidgetPredicate(
          (widget) =>
              widget is DropdownButtonFormField<double> &&
              widget.decoration.labelText == 'OCR alanı büyütme',
        );
        expect(tester.widget<DropdownButton<double>>(rateDropdown).value, 10);
        expect(
          tester
              .widget<DropdownButtonFormField<double>>(scaleDropdown)
              .initialValue,
          1,
        );
        await tester.ensureVisible(rateDropdown);
        await tester.tap(rateDropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('${rate.toInt()}/sn').last);
        await tester.pump(const Duration(milliseconds: 301));
        await tester.pumpAndSettle();

        expect(savedSettings['sampleRateHz'], rate);
        expect(savedSettings['ocrCaptureScale'], 1);
        await tester.pumpWidget(const SizedBox.shrink());
        await _openSettings(tester);
        await _showOcrSettings(tester);
        expect(tester.widget<DropdownButton<double>>(rateDropdown).value, rate);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  test(
    'missing background mode defaults to text fit and preserves a choice',
    () {
      expect(const SubtitleSettings().backgroundFitToText, isTrue);
      expect(
        SubtitleSettings.fromMap(<String, Object>{}).backgroundFitToText,
        isTrue,
      );
      expect(
        SubtitleSettings.fromMap(<String, Object>{
          'backgroundFitToText': false,
        }).backgroundFitToText,
        isFalse,
      );
    },
  );

  testWidgets(
    'background modes differ and filled bounds can be edited and saved',
    (tester) async {
      savedSettings = _fixedArea(const SubtitleSettings(fontSize: 10));
      await _openSettings(tester);
      final background = find.byKey(const ValueKey('subtitle-background-0'));
      final output = find.byKey(const ValueKey('subtitle-output-0'));
      final fitChip = find.widgetWithText(ChoiceChip, 'Yalnızca yazı kadar');
      final fillChip = find.widgetWithText(ChoiceChip, 'Seçili alanı doldur');

      expect(tester.widget<ChoiceChip>(fitChip).selected, isTrue);
      expect(find.text('Altyazı önizlemesi'), findsOneWidget);
      expect(
        tester.getSize(background).width,
        lessThan(tester.getSize(output).width),
      );
      expect(
        tester.getSize(background).height,
        lessThan(tester.getSize(output).height),
      );
      expect(
        tester
            .widget<NormalizedRectEditor>(find.byType(NormalizedRectEditor))
            .fillArea,
        isFalse,
      );

      await tester.ensureVisible(fillChip);
      await tester.tap(fillChip);
      await tester.pumpAndSettle();
      expect(tester.getRect(background), tester.getRect(output));
      await tester.tap(find.text('Arka plan alanını ayarla'));
      await tester.pumpAndSettle();
      expect(
        find.text('Arka plan konumu ve boyutu').hitTestable(),
        findsOneWidget,
      );

      const bounds = NormalizedRect(
        left: 0.2,
        top: 0.3,
        width: 0.5,
        height: 0.4,
      );
      tester
          .widget<NormalizedRectEditor>(find.byType(NormalizedRectEditor))
          .onChanged(bounds);
      await tester.pumpAndSettle();
      final preview = tester.getRect(find.byType(NormalizedRectEditor));
      final filled = tester.getRect(background);
      expect(
        filled.left,
        closeTo(preview.left + preview.width * bounds.left, 0.001),
      );
      expect(
        filled.top,
        closeTo(preview.top + preview.height * bounds.top, 0.001),
      );
      expect(filled.width, closeTo(preview.width * bounds.width, 0.001));
      expect(filled.height, closeTo(preview.height * bounds.height, 0.001));

      await tester.pumpWidget(const SizedBox.shrink());
      await _openSettings(tester);
      expect(tester.widget<ChoiceChip>(fillChip).selected, isTrue);
      expect(tester.getRect(background), filled);

      await tester.ensureVisible(fitChip);
      await tester.tap(fitChip);
      await tester.pumpAndSettle();
      expect(tester.getSize(background).height, lessThan(filled.height));
      expect(tester.getSize(background).width, lessThan(filled.width));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('appearance and bounds survive reopening without pressing save', (
    tester,
  ) async {
    await _openSettings(tester);
    tester.widget<Slider>(_fontSlider).onChanged!(37.5);
    await tester.pump();
    final opacitySlider = find.byWidgetPredicate(
      (widget) => widget is Slider && widget.min == 0 && widget.max == 1,
    );
    tester.widget<Slider>(opacitySlider).onChanged!(0.65);
    await tester.pump();
    const bounds = NormalizedRect(
      left: 0.2,
      top: 0.6,
      width: 0.6,
      height: 0.15,
    );
    tester
        .widget<NormalizedRectEditor>(find.byType(NormalizedRectEditor))
        .onChanged(bounds);
    await tester.pump(const Duration(milliseconds: 301));
    await tester.pump();

    expect(saveCount, 1);
    expect(savedSettings['fontSize'], 37.5);
    expect(savedSettings['backgroundOpacity'], closeTo(0.35, 0.0001));
    expect(savedSettings['subtitleBounds'], bounds.toMap());
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(hours: 4));
    await _openSettings(tester);

    expect(tester.widget<Slider>(_fontSlider).value, 37.5);
    expect(
      tester
          .widget<NormalizedRectEditor>(find.byType(NormalizedRectEditor))
          .value
          .toMap(),
      bounds.toMap(),
    );
    expect(saveCount, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('leaving immediately flushes the last change before reopening', (
    tester,
  ) async {
    await _openSettings(tester);
    tester.widget<Slider>(_fontSlider).onChanged!(31);
    await tester.pumpWidget(const SizedBox.shrink());
    await _openSettings(tester);

    expect(saveCount, 1);
    expect(tester.widget<Slider>(_fontSlider).value, 31);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('backgrounding flushes changes before the autosave delay', (
    tester,
  ) async {
    await _openSettings(tester);
    tester.widget<Slider>(_fontSlider).onChanged!(28);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(saveCount, 1);
    expect(savedSettings['fontSize'], 28);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('failed autosave reports the failure and can be retried', (
    tester,
  ) async {
    await _openSettings(tester);
    failSaving = true;
    tester.widget<Slider>(_fontSlider).onChanged!(42);
    await tester.pump(const Duration(milliseconds: 301));
    await tester.pumpAndSettle();

    expect(saveCount, 0);
    expect(
      find.textContaining('Altyazı ayarları kaydedilemedi:'),
      findsOneWidget,
    );
    expect(find.text('Altyazı ayarları kaydedildi.'), findsNothing);

    failSaving = false;
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(saveCount, 1);
    expect(savedSettings['fontSize'], 42);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
