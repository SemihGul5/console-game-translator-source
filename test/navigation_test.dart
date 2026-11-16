import 'dart:io';
import 'dart:async';
import 'support/offline_game_catalog.dart';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gametranslate/main.dart';
import 'package:gametranslate/screens/access_screen.dart';
import 'package:gametranslate/screens/help_screen.dart';
import 'package:gametranslate/screens/ps5_stream_screen.dart';
import 'package:gametranslate/screens/setup_guide_screen.dart';
import 'package:gametranslate/services/app_links.dart';
import 'package:gametranslate/services/game_translation_catalog.dart';
import 'package:gametranslate/services/tv_subtitle_client.dart';
import 'package:gametranslate/widgets/setup_notice.dart';
import 'package:gametranslate/widgets/game_cover_card.dart';

const _native = MethodChannel(
  'com.abrebostudio.consolegametranslator/ps5_registration',
);
const _access = MethodChannel('com.abrebostudio.consolegametranslator/access');
const _launcher = MethodChannel('plugins.flutter.io/url_launcher');
const _events = MethodChannel(
  'com.abrebostudio.consolegametranslator/ps5_events',
);
const _previewDirectory = String.fromEnvironment('NAV_PREVIEW_DIR');
final _previewKey = GlobalKey();

Future<void> _openApp(
  WidgetTester tester, {
  GameTranslationCatalog? gameCatalog,
}) async {
  final catalog = gameCatalog ?? offlineGameCatalog;
  tester.platformDispatcher.localesTestValue = const [Locale('tr')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  // The catalog intentionally caches its Future across app instances. Load it
  // outside a test's fake clock so later tests can await that same Future.
  await tester.runAsync(() async {
    final games = await catalog.loadCatalog();
    for (final game in games) {
      await catalog.loadCover(game);
    }
  });
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _previewKey,
      child: GameTranslateApp(gameCatalog: catalog),
    ),
  );
  await tester.pump(const Duration(milliseconds: 1100));
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump();
  await tester.pumpAndSettle();
}

Future<void> _selectTab(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(NavigationDestination, label));
  await tester.pumpAndSettle();
  if (label == 'Altyazı' && find.byType(GameCoverCard).evaluate().isNotEmpty) {
    await tester.ensureVisible(find.byType(GameCoverCard).first);
    await tester.pumpAndSettle();
  }
}

Future<void> _continueWithoutGame(WidgetTester tester) async {
  expect(find.text('Oyun seçilmedi'), findsOneWidget);
  await tester.tap(find.text('Seçmeden devam et'));
  await tester.pumpAndSettle();
}

Future<GameTranslationCatalog> _downloadedTestCatalog(
  WidgetTester tester, {
  bool reverseOrder = false,
  Map<String, String> displayNames = const {},
  List<String> gameNames = const ['Alpha', 'Beta'],
  Directory? packDirectory,
}) async {
  late GameTranslationCatalog catalog;
  await tester.runAsync(() async {
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    try {
      String hash(List<int> bytes) => crypto.sha256.convert(bytes).toString();
      final image = await rootBundle.load(
        'assets/games/mafia-old-country.cover.jpg',
      );
      final cover = image.buffer.asUint8List(
        image.offsetInBytes,
        image.lengthInBytes,
      );
      final entries = <Map<String, Object>>[];
      final files = <String, List<int>>{};
      for (final name in reverseOrder ? gameNames.reversed : gameNames) {
        final id = 'downloaded-${name.toLowerCase()}';
        final data = utf8.encode(
          jsonEncode({
            'game': id,
            'source': 'en',
            'target': 'tr',
            'entries': [
              {'id': '1', 'english': 'Hello $name', 'turkish': 'Merhaba $name'},
            ],
          }),
        );
        final pack = 'translations/$id.${hash(data)}.json';
        final art = 'covers/${hash(cover)}.jpg';
        entries.add({
          'id': id,
          'name': displayNames[name] ?? 'Downloaded $name',
          'sourceLanguage': 'en',
          'targetLanguage': 'tr',
          'file': pack,
          'bytes': data.length,
          'sha256': hash(data),
          'cover': art,
          'coverSha256': hash(cover),
          'coverAspectRatio': name == 'Alpha' ? 285 / 350 : 1.8,
        });
        files['/$pack'] = data;
        files['/$art'] = cover;
      }
      files['/catalog.json'] = utf8.encode(
        jsonEncode({'schemaVersion': 1, 'games': entries}),
      );
      server.listen((request) async {
        request.response.headers.contentType = request.uri.path.endsWith('.jpg')
            ? ContentType('image', 'jpeg')
            : ContentType.json;
        request.response.add(files[request.uri.path]!);
        await request.response.close();
      });
      catalog = GameTranslationCatalog.testing(
        catalogUri: Uri.parse('http://127.0.0.1:${server.port}/catalog.json'),
        cacheDirectory: () async => packDirectory,
      );
      for (final game in await catalog.refresh()) {
        await catalog.loadJson(game);
        await catalog.loadCover(game);
      }
    } finally {
      await server.close(force: true);
      HttpOverrides.global = previousOverrides;
    }
  });
  return catalog;
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (_previewDirectory.isEmpty) return;
  await tester.runAsync(() async {
    for (final image in tester.widgetList<Image>(find.byType(Image))) {
      await precacheImage(image.image, tester.element(find.byWidget(image)));
    }
  });
  await tester.pumpAndSettle();
  final boundary =
      _previewKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(_previewDirectory).create(recursive: true);
    await File(
      '$_previewDirectory/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> _connectTestTv(WidgetTester tester) async {
  late HttpServer server;
  final sockets = <WebSocket>[];
  final client = TvSubtitleClient.instance;
  await tester.runAsync(() async {
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    try {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.transform(WebSocketTransformer()).listen((socket) {
        sockets.add(socket);
        socket.listen((data) {
          final message = jsonDecode(data as String) as Map;
          if (message['type'] == 'pair') {
            socket.add(
              jsonEncode({
                'type': 'paired',
                'sessionToken': List.filled(48, 'a').join(),
              }),
            );
          }
        });
      });
      await client.connect('127.0.0.1:${server.port}', '123456');
    } finally {
      HttpOverrides.global = previousOverrides;
    }
  });
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      await client.disconnect();
      for (final socket in sockets) {
        await socket.close();
      }
      await server.close(force: true);
    });
  });
}

void main() {
  setUpAll(() async {
    final packageConfig =
        jsonDecode(await File('.dart_tool/package_config.json').readAsString())
            as Map;
    final flutterPackage = (packageConfig['packages'] as List)
        .cast<Map>()
        .firstWhere((package) => package['name'] == 'flutter');
    final flutterRoot = Directory.fromUri(
      Uri.parse(flutterPackage['rootUri'] as String),
    ).parent.parent;
    final fonts = '${flutterRoot.path}/bin/cache/artifacts/material_fonts';
    final roboto = FontLoader('Roboto');
    for (final weight in ['regular', 'medium', 'bold', 'black']) {
      roboto.addFont(
        File(
          '$fonts/roboto-$weight.ttf',
        ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
      );
    }
    await roboto.load();
    await (FontLoader('MaterialIcons')..addFont(
          File(
            '$fonts/materialicons-regular.otf',
          ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        ))
        .load();
  });
  late List<String> nativeCalls;
  late List<bool> checklist;
  late bool consoleSaved;
  late bool tvSaved;
  late bool translationRunning;
  late bool keepAwake;
  late bool setupWarningDismissed;
  String? smartTvPairing;
  late List<Uri> launched;
  late bool launchSucceeds;
  late String? copiedText;
  late String? savedGameId;
  late List<Map<Object?, Object?>> gameMemoryCalls;
  Completer<Map<String, Object>>? gameMemoryPreparation;
  var gameMemoryCacheHit = false;
  var rejectCachedFile = false;
  late List<Map<Object?, Object?>> gameMemoryActivations;

  setUp(() {
    nativeCalls = [];
    checklist = List.filled(SetupGuideScreen.totalSteps, false);
    consoleSaved = false;
    tvSaved = false;
    translationRunning = false;
    keepAwake = false;
    setupWarningDismissed = false;
    smartTvPairing = null;
    launched = [];
    launchSucceeds = true;
    copiedText = null;
    savedGameId = null;
    gameMemoryCalls = [];
    gameMemoryPreparation = null;
    gameMemoryCacheHit = false;
    rejectCachedFile = false;
    gameMemoryActivations = [];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_native, (call) async {
      nativeCalls.add(call.method);
      switch (call.method) {
        case 'getSavedConsole':
          return consoleSaved
              ? {'host': '192.168.1.50', 'nickname': 'PS5'}
              : null;
        case 'getSessionState':
          return {
            'active': translationRunning,
            'connected': translationRunning,
            'videoReady': translationRunning,
          };
        case 'isTranslationForegroundRunning':
          return translationRunning;
        case 'stopSession':
        case 'stopTranslationForeground':
          translationRunning = false;
          return true;
        case 'getSelectedGameId':
          return savedGameId;
        case 'saveSelectedGameId':
          final id = call.arguments as String;
          savedGameId = id.isEmpty ? null : id;
          return true;
        case 'activateCachedGameTranslationMemory':
          gameMemoryActivations.add(
            Map<Object?, Object?>.from(call.arguments as Map),
          );
          return {'loaded': gameMemoryCacheHit};
        case 'setGameTranslationMemory':
          gameMemoryCalls.add(
            Map<Object?, Object?>.from(call.arguments as Map),
          );
          if ((call.arguments as Map).containsKey('filePath')) {
            return {'loaded': !rejectCachedFile, 'gameProfile': null};
          }
          if ((call.arguments as Map)['gameId'] != null &&
              gameMemoryPreparation != null) {
            return gameMemoryPreparation!.future;
          }
          return {'loaded': true};
        case 'getSetupChecklist':
          return checklist;
        case 'saveSetupChecklist':
          checklist = List<bool>.from(call.arguments as List);
          return true;
        case 'getIncompleteSetupWarningDismissed':
          return setupWarningDismissed;
        case 'setIncompleteSetupWarningDismissed':
          setupWarningDismissed = call.arguments as bool;
          return true;
        case 'getSmartTvPairing':
          return smartTvPairing;
        case 'saveSmartTvPairing':
          smartTvPairing = call.arguments as String?;
          return true;
        case 'getTvPairing':
          // A persisted pairing without a reachable endpoint; no network is
          // needed to decide where the completed guide belongs.
          return tvSaved
              ? {'address': 'saved-tv', 'sessionToken': 'saved-token'}
              : null;
        case 'getPersonalizationSettings':
          return {'keepScreenAwake': keepAwake};
        case 'savePersonalizationSettings':
          keepAwake = (call.arguments as Map)['keepScreenAwake'] as bool;
          return true;
        case 'getAppInfo':
          return {
            'version': '1.2.3',
            'build': 7,
            'privacyUrl': 'https://example.com/privacy',
            'termsUrl': 'https://example.com/terms',
          };
        case 'commitGameTranslationSelection':
          savedGameId = (call.arguments as Map)['packId'] as String;
          return null;
        default:
          return null;
      }
    });
    messenger.setMockMethodCallHandler(_access, (call) async {
      if (call.method == 'configuration') return {'configured': false};
      if (call.method == 'status') return {'state': 'inactive'};
      fail('Navigation must not start a trial or purchase: ${call.method}');
    });
    messenger.setMockMethodCallHandler(_events, (_) async => null);
    messenger.setMockMethodCallHandler(SystemChannels.platform_views, (
      call,
    ) async {
      if (call.method == 'create') return 1;
      if (call.method == 'resize') {
        final arguments = call.arguments as Map;
        return {'width': arguments['width'], 'height': arguments['height']};
      }
      return null;
    });
    messenger.setMockMethodCallHandler(_launcher, (call) async {
      if (call.method == 'launch') {
        launched.add(Uri.parse((call.arguments as Map)['url'] as String));
        return launchSucceeds;
      }
      return null;
    });
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copiedText = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final channel in [
      _native,
      _access,
      _launcher,
      _events,
      SystemChannels.platform_views,
      SystemChannels.platform,
    ]) {
      messenger.setMockMethodCallHandler(channel, null);
    }
  });

  testWidgets(
    'tabs retain the home, live translation and personalization state',
    (tester) async {
      consoleSaved = true;
      translationRunning = true;
      await _openApp(tester);
      final homeState = tester.state(find.byType(HomeScreen));
      expect(find.text('ÇEVİRİYİ DURDUR'), findsOneWidget);
      expect(find.text('Kişiselleştir'), findsNothing);
      expect(find.text('Sık Sorulan Sorular'), findsNothing);
      expect(find.text('Premium'), findsNothing);
      expect(find.text('Oyun Kütüphanesi'), findsNothing);
      expect(find.text('Altyazı görünümü'), findsNothing);
      final homeScroll = find
          .descendant(
            of: find.byKey(const PageStorageKey('home-scroll')),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.drag(homeScroll, const Offset(0, -500));
      await tester.pumpAndSettle();
      final position = tester
          .state<ScrollableState>(homeScroll)
          .position
          .pixels;
      final reads = nativeCalls
          .where((call) => call == 'getSavedConsole')
          .length;

      await _selectTab(tester, 'Profil');
      expect(find.text('Aboneliğim'), findsOneWidget);
      expect(find.text('Hediye kodunu kullan'), findsOneWidget);
      await _selectTab(tester, 'Ayarlar');
      expect(find.text('Kişiselleştir'), findsOneWidget);
      expect(find.text('Altyazı görünümü'), findsNothing);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(keepAwake, isTrue);
      await _selectTab(tester, 'Ana sayfa');
      expect(tester.state(find.byType(HomeScreen)), same(homeState));
      expect(
        tester.state<ScrollableState>(homeScroll).position.pixels,
        position,
      );
      expect(
        nativeCalls.where((call) => call == 'getSavedConsole').length,
        reads,
      );
      expect(
        nativeCalls.where(
          (call) => {
            'startSession',
            'stopSession',
            'startTranslationForeground',
            'stopTranslationForeground',
          }.contains(call),
        ),
        isEmpty,
      );
      await _selectTab(tester, 'Ayarlar');
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isTrue,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1,
      );
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'an old Samsung setup choice is not shown as an active or saved TV',
    (tester) async {
      smartTvPairing = jsonEncode({'kind': 'samsung'});
      await _openApp(tester);
      await tester.ensureVisible(find.text('TV’yi eşleştir'));
      expect(find.text('TV'), findsOneWidget);
      expect(find.text('Samsung Tizen'), findsNothing);
      expect(find.text('Altyazıları TV ekranında göster'), findsOneWidget);
      expect(find.text('Eşleştirme kayıtlı • TV bağlı değil'), findsNothing);
      expect(smartTvPairing, isNull);
      expect(nativeCalls, contains('getTvPairing'));
      expect(nativeCalls, isNot(contains('clearTvPairing')));
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'TV card names a connected receiver and reopens generically after disconnecting',
    (tester) async {
      await _connectTestTv(tester);
      await _openApp(tester);
      await tester.ensureVisible(find.text('TV’yi yeniden eşleştir'));
      expect(find.text('Android TV'), findsOneWidget);
      await tester.runAsync(() => TvSubtitleClient.instance.disconnect());
      await tester.pumpWidget(const SizedBox.shrink());
      await _openApp(tester);
      await tester.ensureVisible(find.text('TV’yi eşleştir'));
      expect(find.text('TV'), findsOneWidget);
      expect(find.text('Android TV'), findsNothing);
      expect(find.text('TV’yi eşleştir'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'missing PS5 still blocks translation before any setup warning',
    (tester) async {
      setupWarningDismissed = true;
      await _openApp(tester);
      await tester.tap(find.text('ÇEVİRİYİ BAŞLAT'));
      await tester.pumpAndSettle();
      expect(find.text('PS5 gerekli'), findsOneWidget);
      expect(find.text('Kurulum henüz tamamlanmadı'), findsNothing);
      expect(nativeCalls, isNot(contains('prepareTranslationModels')));
      expect(nativeCalls, isNot(contains('startTranslationForeground')));
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'missing TV still blocks translation and pairing explains the TV app download',
    (tester) async {
      consoleSaved = true;
      setupWarningDismissed = true;
      await _openApp(tester);
      await tester.tap(find.text('ÇEVİRİYİ BAŞLAT'));
      await tester.pumpAndSettle();
      expect(find.text('TV gerekli'), findsOneWidget);
      expect(find.text('Kurulum henüz tamamlanmadı'), findsNothing);
      expect(nativeCalls, isNot(contains('prepareTranslationModels')));
      await tester.tap(find.text('Tamam'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('TV’yi eşleştir'));
      await tester.tap(find.text('TV’yi eşleştir'));
      await tester.pumpAndSettle();
      expect(find.byType(TvAppInstallNotice), findsOneWidget);
      expect(find.text('Önce TV uygulamasını indir'), findsOneWidget);
      expect(find.textContaining('AnlaOyna TV'), findsOneWidget);
      await _capture(tester, 'tv-install-notice');
      tester.view.physicalSize = const Size(320, 640);
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('İptal'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(AlertDialog), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'TV pairing keeps Android as default and opens separate LG and Samsung setup',
    (tester) async {
      await _openApp(tester);
      await tester.ensureVisible(find.text('TV’yi eşleştir'));
      await tester.tap(find.text('TV’yi eşleştir'));
      await tester.pumpAndSettle();
      expect(find.byType(TvAppInstallNotice), findsOneWidget);
      expect(find.text('LG webOS'), findsOneWidget);
      expect(find.text('Samsung Tizen'), findsOneWidget);
      await _capture(tester, 'tv-brand-options');
      await tester.tap(find.text('LG webOS'));
      await tester.pumpAndSettle();
      expect(find.text('LG TV’nin yerel IPv4 adresi'), findsOneWidget);
      expect(find.byType(TvAppInstallNotice), findsNothing);
      expect(find.textContaining('Deneysel'), findsNothing);
      await _capture(tester, 'tv-lg-setup');
      await tester.ensureVisible(find.text('TV bağlantısı için destek al'));
      await tester.tap(find.text('TV bağlantısı için destek al'));
      await tester.pumpAndSettle();
      expect(launched.last.path, AppLinks.supportEmail);
      expect(
        launched.last.queryParameters['subject'],
        'LG webOS TV bağlantı desteği',
      );
      expect(launched.last.queryParameters['body'], contains('TV modeli:'));
      expect(launched.last.queryParameters['body'], contains('1.2.3 (7)'));
      expect(
        launched.last.queryParameters['body'],
        contains('ekran görüntüsünü'),
      );
      await tester.tap(find.text('İptal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('TV’yi eşleştir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Samsung Tizen'));
      await tester.pumpAndSettle();
      expect(find.text('TV uygulamam kurulu • Eşleştir'), findsOneWidget);
      expect(find.textContaining('README'), findsNothing);
      expect(find.textContaining('receiver.zip'), findsNothing);
      await tester.ensureVisible(find.text('TV kurulum rehberini aç'));
      await tester.tap(find.text('TV kurulum rehberini aç'));
      await tester.pumpAndSettle();
      expect(launched.last.path, '/tv-setup.html');
      expect(launched.last.queryParameters['brand'], 'samsung');
      expect(launched.last.queryParameters['lang'], 'tr');
      await _capture(tester, 'tv-samsung-setup');
      await tester.ensureVisible(find.text('TV bağlantısı için destek al'));
      await tester.tap(find.text('TV bağlantısı için destek al'));
      await tester.pumpAndSettle();
      expect(
        launched.last.queryParameters['subject'],
        'Samsung Tizen TV bağlantı desteği',
      );
      await tester.tap(find.text('İptal'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'incomplete setup is advisory and can open the guide or continue translation',
    (tester) async {
      consoleSaved = true;
      checklist = List.filled(SetupGuideScreen.totalSteps, true)..last = false;
      await _connectTestTv(tester);
      await _openApp(tester);
      expect(TvSubtitleClient.instance.isConnected, isTrue);
      await tester.tap(find.text('ÇEVİRİYİ BAŞLAT'));
      await tester.pumpAndSettle();
      expect(find.text('Kurulum henüz tamamlanmadı'), findsOneWidget);
      expect(find.text('7 / 8 adım tamamlandı'), findsWidgets);
      expect(find.text('Kurulumu tamamla'), findsOneWidget);
      expect(find.text('Yine de başlat'), findsOneWidget);
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, 'Bir daha gösterme'),
            )
            .value,
        isFalse,
      );
      expect(nativeCalls, isNot(contains('prepareTranslationModels')));
      expect(nativeCalls, isNot(contains('startTranslationForeground')));
      await _capture(tester, 'setup-advisory');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(nativeCalls, isNot(contains('prepareTranslationModels')));
      await tester.tap(find.text('ÇEVİRİYİ BAŞLAT'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kurulumu tamamla'));
      await tester.pumpAndSettle();
      expect(find.byType(SetupGuideScreen), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byType(TvAppInstallNotice),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Önce TV uygulamasını indir'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(nativeCalls, isNot(contains('prepareTranslationModels')));
      await tester.tap(find.text('ÇEVİRİYİ BAŞLAT'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yine de başlat'));
      await tester.pumpAndSettle();
      await _continueWithoutGame(tester);
      expect(find.byType(AccessScreen), findsOneWidget);
      expect(nativeCalls, contains('prepareTranslationModels'));
      expect(find.text('Kurulum henüz tamamlanmadı'), findsNothing);
      expect(setupWarningDismissed, isFalse);
      expect(
        nativeCalls,
        isNot(contains('setIncompleteSetupWarningDismissed')),
      );
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'do not show again persists across app recreation without completing setup',
    (tester) async {
      consoleSaved = true;
      checklist = List.filled(SetupGuideScreen.totalSteps, true)..last = false;
      await _connectTestTv(tester);
      await _openApp(tester);
      await tester.tap(find.text('ÇEVİRİYİ BAŞLAT'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bir daha gösterme'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, 'Bir daha gösterme'),
            )
            .value,
        isTrue,
      );
      await _capture(tester, 'setup-advisory-opt-out');
      await tester.tap(find.text('Yine de başlat'));
      await tester.pumpAndSettle();
      await _continueWithoutGame(tester);
      expect(find.byType(AccessScreen), findsOneWidget);
      expect(setupWarningDismissed, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
      await _openApp(tester);
      expect(find.text('7 / 8 adım tamamlandı'), findsOneWidget);
      await tester.tap(find.text('ÇEVİRİYİ BAŞLAT'));
      await tester.pumpAndSettle();
      expect(find.text('Kurulum henüz tamamlanmadı'), findsNothing);
      await _continueWithoutGame(tester);
      expect(find.byType(AccessScreen), findsOneWidget);
      expect(
        nativeCalls.where(
          (call) => call == 'setIncompleteSetupWarningDismissed',
        ),
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'completed setup confirms continuing without a game before translation access',
    (tester) async {
      consoleSaved = true;
      checklist = List.filled(SetupGuideScreen.totalSteps, true);
      await _connectTestTv(tester);
      await _openApp(tester);
      await tester.tap(find.text('ÇEVİRİYİ BAŞLAT'));
      await tester.pumpAndSettle();
      expect(find.text('Kurulum henüz tamamlanmadı'), findsNothing);
      expect(nativeCalls, isNot(contains('prepareTranslationModels')));
      await _continueWithoutGame(tester);
      expect(find.byType(AccessScreen), findsOneWidget);
      expect(nativeCalls, contains('prepareTranslationModels'));
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'no selected game offers the library without preparing or starting translation',
    (tester) async {
      consoleSaved = true;
      checklist = List.filled(SetupGuideScreen.totalSteps, true);
      await _connectTestTv(tester);
      await _openApp(tester);
      await tester.tap(find.text('ÇEVİRİYİ BAŞLAT'));
      await tester.pumpAndSettle();
      expect(find.text('Oyun seçilmedi'), findsOneWidget);
      expect(nativeCalls, isNot(contains('prepareTranslationModels')));
      expect(nativeCalls, isNot(contains('startTranslationForeground')));
      await _capture(tester, 'game-required-advisory');
      tester.view.physicalSize = const Size(320, 640);
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Oyun kütüphanesini aç'));
      await tester.tap(find.text('Oyun kütüphanesini aç'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
      expect(find.byKey(const ValueKey('game-library-search')), findsOneWidget);
      expect(find.byType(AccessScreen), findsNothing);
      expect(nativeCalls, isNot(contains('prepareTranslationModels')));
      expect(nativeCalls, isNot(contains('startTranslationForeground')));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  for (final loaded in [true, false]) {
    testWidgets(
      'translation waits for selected dictionary preparation and handles loaded=$loaded',
      (tester) async {
        consoleSaved = true;
        checklist = List.filled(SetupGuideScreen.totalSteps, true);
        await _connectTestTv(tester);
        final catalog = await _downloadedTestCatalog(tester);
        savedGameId = 'downloaded-alpha';
        gameMemoryPreparation = Completer<Map<String, Object>>();
        await _openApp(tester, gameCatalog: catalog);
        await tester.tap(find.text('ÇEVİRİYİ BAŞLAT'));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Oyun çevirileri hazırlanıyor…'), findsOneWidget);
        expect(find.text('Oyun seçilmedi'), findsNothing);
        expect(nativeCalls, isNot(contains('prepareTranslationModels')));
        expect(nativeCalls, isNot(contains('startTranslationForeground')));
        expect(find.byType(AccessScreen), findsNothing);
        gameMemoryPreparation!.complete({'loaded': loaded});
        await tester.pump();
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pumpAndSettle();
        expect(find.text('Oyun çevirileri hazırlanıyor…'), findsNothing);
        if (loaded) {
          expect(find.byType(AccessScreen), findsOneWidget);
          expect(nativeCalls, contains('prepareTranslationModels'));
        } else {
          expect(find.text('Oyun çevirileri yüklenemedi'), findsOneWidget);
          expect(find.byType(AccessScreen), findsNothing);
          expect(nativeCalls, isNot(contains('prepareTranslationModels')));
          expect(nativeCalls, isNot(contains('startTranslationForeground')));
        }
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );
  }

  testWidgets(
    'incomplete setup never interrupts stopping a running translation',
    (tester) async {
      consoleSaved = true;
      translationRunning = true;
      await _openApp(tester);
      await tester.tap(find.text('ÇEVİRİYİ DURDUR'));
      await tester.pumpAndSettle();
      expect(
        nativeCalls,
        containsAll(['stopSession', 'stopTranslationForeground']),
      );
      expect(find.text('Kurulum henüz tamamlanmadı'), findsNothing);
      expect(find.text('Oyun seçilmedi'), findsNothing);
      expect(find.text('ÇEVİRİYİ BAŞLAT'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'unfinished setup stays home and subtitle appearance opens its original flow',
    (tester) async {
      await _openApp(tester);
      expect(find.text('Kurulum rehberi'), findsOneWidget);
      await _capture(tester, 'home');
      await _selectTab(tester, 'Ayarlar');
      expect(find.text('Kurulum rehberi'), findsNothing);
      await tester.tap(find.text('Sık Sorulan Sorular'));
      await tester.pumpAndSettle();
      expect(find.byType(HelpScreen), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await _capture(tester, 'settings');
      await _selectTab(tester, 'Profil');
      await _capture(tester, 'profile');
      await tester.tap(find.text('Aboneliğim'));
      await tester.pumpAndSettle();
      expect(find.byType(AccessScreen), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        2,
      );
      await _selectTab(tester, 'Altyazı');
      await _capture(tester, 'subtitles');
      await tester.ensureVisible(find.text('Altyazı görünümü'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Altyazı görünümü'));
      await tester.pumpAndSettle();
      expect(find.byType(Ps5StreamScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'games with different cover shapes have equal cards across screen sizes',
    (tester) async {
      final catalog = await _downloadedTestCatalog(tester);
      await _openApp(tester, gameCatalog: catalog);
      await _selectTab(tester, 'Altyazı');
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final width in [320.0, 390.0, 600.0]) {
        for (final scale in [1.0, 1.6]) {
          tester.view.physicalSize = Size(width, 844);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          await tester.pumpAndSettle();
          if (find.byType(GameCoverCard).evaluate().isEmpty) {
            final scrollable = find
                .descendant(
                  of: find.byKey(const PageStorageKey('subtitles-scroll')),
                  matching: find.byType(Scrollable),
                )
                .first;
            tester.state<ScrollableState>(scrollable).position.jumpTo(0);
            await tester.pumpAndSettle();
            await tester.scrollUntilVisible(
              find.byWidgetPredicate(
                (widget) =>
                    widget is GameCoverCard &&
                    widget.game.id == 'downloaded-alpha',
              ),
              150,
              scrollable: scrollable,
            );
          }
          await tester.ensureVisible(find.byType(GameCoverCard).first);
          await tester.pumpAndSettle();
          final cards = find.byType(GameCoverCard);
          expect(cards, findsNWidgets(2));
          final first = tester.getSize(cards.first);
          expect(tester.getSize(cards.last), first);
          expect(first.width, greaterThanOrEqualTo(104));
          expect(tester.getRect(cards.last).right, lessThanOrEqualTo(width));
          expect(tester.takeException(), isNull);
          if (width == 390 && scale == 1) {
            await _capture(tester, 'games-uniform-cards');
          }
        }
      }
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'leftmost subtitle tab keeps game selection and native translation memory',
    (tester) async {
      await _openApp(tester);
      final navigation = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(
        navigation.destinations.cast<NavigationDestination>().map(
          (destination) => destination.label,
        ),
        ['Altyazı', 'Ana sayfa', 'Profil', 'Ayarlar'],
      );
      expect(navigation.selectedIndex, 1);
      expect(find.text('Oyun Kütüphanesi'), findsNothing);
      expect(find.text('Altyazı görünümü'), findsNothing);
      await _selectTab(tester, 'Altyazı');
      expect(find.text('Oyun Kütüphanesi'), findsOneWidget);
      expect(find.text('Altyazı görünümü'), findsOneWidget);
      expect(
        find.textContaining(
          'Daha hızlı ve kaliteli bir çeviri deneyimi için oynadığın oyun listede varsa seç.',
        ),
        findsOneWidget,
      );
      await tester.runAsync(() async {
        final catalog = offlineGameCatalog;
        await catalog.loadJson((await catalog.loadCatalog()).first);
      });
      await tester.tap(find.text('Mafia: The Old Country'));
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(savedGameId, 'mafia-old-country');
      final selectedCard = find.byType(GameCoverCard);
      expect(find.byType(Radio<String>), findsNothing);
      expect(
        find.descendant(
          of: selectedCard,
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsOneWidget,
      );
      await Scrollable.ensureVisible(
        tester.element(selectedCard),
        alignment: 1,
      );
      await tester.pumpAndSettle();
      await _capture(tester, 'subtitles-game-selected');
      expect(find.text('Mafia: The Old Country seçili'), findsNothing);
      expect(find.text('Oyun seçimini kaldır'), findsNothing);
      expect(find.byTooltip('Oyun listesini yenile'), findsNothing);
      expect(tester.widget<GameCoverCard>(selectedCard).selected, isTrue);
      expect(
        tester.getSize(selectedCard).height,
        lessThan(tester.getSize(selectedCard).width * 2),
      );
      expect(gameMemoryCalls.last['gameId'], savedGameId);
      expect(gameMemoryCalls.last['sourceLanguage'], 'en');
      expect(gameMemoryCalls.last['targetLanguage'], 'tr');
      expect(gameMemoryCalls.last['json'], isNotEmpty);
      final memoryCallCount = gameMemoryCalls.length;
      await _selectTab(tester, 'Ana sayfa');
      expect(find.text('Oyun Kütüphanesi'), findsNothing);
      await _selectTab(tester, 'Ayarlar');
      await _selectTab(tester, 'Altyazı');
      expect(tester.widget<GameCoverCard>(selectedCard).selected, isTrue);
      expect(gameMemoryCalls.length, memoryCallCount);
      await tester.tap(find.text('Mafia: The Old Country'));
      await tester.pumpAndSettle();
      expect(savedGameId, isNull);
      expect(gameMemoryCalls.last['gameId'], isNull);
      expect(gameMemoryCalls.last['json'], isNull);
      expect(tester.widget<GameCoverCard>(selectedCard).selected, isFalse);
      expect(
        find.descendant(
          of: selectedCard,
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsNothing,
      );
      expect(
        find.text('Oyun seçilmedi · canlı çeviri kullanılıyor'),
        findsNothing,
      );
      // Cached selection can still rebuild native indexes; that must not look
      // like another network download, even while the native work is pending.
      gameMemoryPreparation = Completer<Map<String, Object>>();
      await tester.tap(find.text('Mafia: The Old Country'));
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      // Persist only after parsing succeeds, so a broken replacement cannot
      // overwrite the user's previous valid selection.
      expect(savedGameId, isNull);
      expect(gameMemoryCalls.last['gameId'], 'mafia-old-country');
      expect(tester.widget<GameCoverCard>(selectedCard).downloading, isFalse);
      expect(tester.widget<GameCoverCard>(selectedCard).preparing, isTrue);
      expect(find.byType(AlertDialog), findsNothing);
      expect(
        find.descendant(
          of: selectedCard,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: selectedCard,
          matching: find.byType(LinearProgressIndicator),
        ),
        findsNothing,
      );
      expect(gameMemoryPreparation!.isCompleted, isFalse);
      final preparingCallCount = gameMemoryCalls.length;
      await tester.tap(find.text('Altyazı görünümü'));
      await tester.pump();
      expect(find.byType(Ps5StreamScreen), findsNothing);
      await tester.tap(find.text('Mafia: The Old Country'));
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(savedGameId, isNull);
      expect(gameMemoryCalls.length, preparingCallCount);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
      gameMemoryPreparation!.complete({'loaded': true});
      await tester.pumpAndSettle();
      expect(savedGameId, 'mafia-old-country');
      expect(tester.widget<GameCoverCard>(selectedCard).preparing, isFalse);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1,
      );
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'prepared game reselects without transferring JSON or waiting for native parsing',
    (tester) async {
      await _openApp(tester);
      await _selectTab(tester, 'Altyazı');
      await tester.runAsync(() async {
        final catalog = offlineGameCatalog;
        await catalog.loadJson((await catalog.loadCatalog()).first);
      });
      await tester.tap(find.text('Mafia: The Old Country'));
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      final loadedCall = gameMemoryCalls.last;
      expect(loadedCall['json'], isNotEmpty);
      expect(loadedCall['contentKey'], isNotEmpty);
      await tester.tap(find.text('Mafia: The Old Country'));
      await tester.pumpAndSettle();
      expect(savedGameId, isNull);
      final callCount = gameMemoryCalls.length;
      gameMemoryCacheHit = true;
      // A pending cold parser cannot hold up a native cache hit.
      gameMemoryPreparation = Completer<Map<String, Object>>();
      await tester.tap(find.text('Mafia: The Old Country'));
      await tester.pumpAndSettle();
      expect(savedGameId, 'mafia-old-country');
      expect(gameMemoryCalls, hasLength(callCount));
      expect(
        gameMemoryActivations.last['contentKey'],
        loadedCall['contentKey'],
      );
      expect(gameMemoryActivations.last.containsKey('json'), isFalse);
      final card = tester.widget<GameCoverCard>(find.byType(GameCoverCard));
      expect(card.selected, isTrue);
      expect(card.preparing, isFalse);
      expect(card.downloading, isFalse);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  for (final fallback in [false, true]) {
    testWidgets(
      'cached JSON uses the native file path with legacy fallback=$fallback',
      (tester) async {
        final directory = await tester.runAsync(
          () => Directory.systemTemp.createTemp('game-selection-file-'),
        );
        addTearDown(() async => directory!.delete(recursive: true));
        final catalog = await _downloadedTestCatalog(
          tester,
          packDirectory: directory,
        );
        rejectCachedFile = fallback;
        await _openApp(tester, gameCatalog: catalog);
        await _selectTab(tester, 'Altyazı');
        await tester.tap(find.text('Downloaded Alpha'));
        await tester.pump();
        for (var i = 0; i < 4; i++) {
          await tester.runAsync(() async {
            final game = (await catalog.loadCatalog()).first;
            await catalog.cachedJsonFile(game);
            if (fallback) await catalog.loadJson(game);
          });
          await tester.pump();
        }
        await tester.pumpAndSettle();
        expect(savedGameId, 'downloaded-alpha');
        final calls = gameMemoryCalls
            .where((call) => call['gameId'] == 'downloaded-alpha')
            .toList();
        expect(calls.first['filePath'], isA<String>());
        expect(calls.first.containsKey('json'), isFalse);
        expect(calls.first['sha256'], isA<String>());
        expect(calls, hasLength(fallback ? 2 : 1));
        if (fallback) expect(calls.last['json'], isA<String>());
        expect(
          tester
              .widgetList<GameCoverCard>(find.byType(GameCoverCard))
              .first
              .preparing,
          isFalse,
        );
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );
  }

  testWidgets(
    'library sorts server games and searches names without changing the selected dictionary',
    (tester) async {
      final catalog = await _downloadedTestCatalog(
        tester,
        reverseOrder: true,
        displayNames: {'Alpha': 'İstanbul Şehir', 'Beta': 'Zeta Beta'},
      );
      await _openApp(tester, gameCatalog: catalog);
      await _selectTab(tester, 'Altyazı');
      List<String> names() => tester
          .widgetList<GameCoverCard>(find.byType(GameCoverCard))
          .map((card) => card.game.name)
          .toList();
      expect(names(), ['İstanbul Şehir', 'Zeta Beta']);
      await tester.ensureVisible(find.text('İstanbul Şehir'));
      await tester.tap(find.text('İstanbul Şehir'));
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(savedGameId, 'downloaded-alpha');
      final memoryLoads = gameMemoryCalls.length;
      final betaState = tester.state(find.byType(GameCoverCard).last);
      final search = find.byKey(const ValueKey('game-library-search'));
      await tester.ensureVisible(search);
      await tester.enterText(search, 'zEtA');
      await tester.pumpAndSettle();
      expect(names(), ['Zeta Beta']);
      expect(
        identical(tester.state(find.byType(GameCoverCard)), betaState),
        isTrue,
      );
      expect(savedGameId, 'downloaded-alpha');
      expect(gameMemoryCalls, hasLength(memoryLoads));
      await _capture(tester, 'game-library-search-results');
      await tester.enterText(search, 'ISTANBUL SEHIR');
      await tester.pumpAndSettle();
      expect(names(), ['İstanbul Şehir']);
      await tester.enterText(search, 'no such game');
      await tester.pumpAndSettle();
      expect(find.text('Aramana uygun oyun bulunamadı.'), findsOneWidget);
      expect(find.text('Henüz oyun eklenmedi.'), findsNothing);
      expect(find.byType(GameCoverCard), findsNothing);
      await tester.tap(find.byTooltip('Aramayı temizle'));
      await tester.pumpAndSettle();
      expect(names(), ['İstanbul Şehir', 'Zeta Beta']);
      expect(
        tester
            .widgetList<GameCoverCard>(find.byType(GameCoverCard))
            .first
            .selected,
        isTrue,
      );
      expect(savedGameId, 'downloaded-alpha');
      expect(gameMemoryCalls, hasLength(memoryLoads));
      expect(tester.takeException(), isNull);
      await _capture(tester, 'game-library-search');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'a game selected at the end is pinned and brought into view while other games stay alphabetical',
    (tester) async {
      final names = List.generate(
        18,
        (i) => 'Game${i.toString().padLeft(2, '0')}',
      );
      final catalog = await _downloadedTestCatalog(tester, gameNames: names);
      await _openApp(tester, gameCatalog: catalog);
      await _selectTab(tester, 'Altyazı');
      final scrollable = find
          .descendant(
            of: find.byKey(const PageStorageKey('subtitles-scroll')),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Downloaded Game17'),
        450,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();
      expect(
        tester.state<ScrollableState>(scrollable).position.pixels,
        greaterThan(800),
      );
      await tester.tap(find.text('Downloaded Game17'));
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(savedGameId, 'downloaded-game17');
      void expectPinned() {
        final cards = tester
            .widgetList<GameCoverCard>(find.byType(GameCoverCard))
            .toList();
        expect(cards.first.game.id, 'downloaded-game17');
        expect(cards.first.selected, isTrue);
        expect(
          cards.skip(1).map((card) => card.game.name),
          names.take(cards.length - 1).map((name) => 'Downloaded $name'),
        );
        final card = tester.getRect(find.byType(GameCoverCard).first);
        final viewport = tester.getRect(scrollable);
        expect(card.top, greaterThanOrEqualTo(viewport.top));
        expect(card.bottom, lessThanOrEqualTo(viewport.bottom));
      }

      expectPinned();
      final loads = gameMemoryCalls.length;
      await _capture(tester, 'game-library-selected-first');
      await _selectTab(tester, 'Ana sayfa');
      await _selectTab(tester, 'Altyazı');
      expectPinned();
      expect(gameMemoryCalls, hasLength(loads));
      await tester.tap(find.text('Downloaded Game17'));
      await tester.pumpAndSettle();
      expect(savedGameId, isNull);
      expect(
        tester
            .widgetList<GameCoverCard>(find.byType(GameCoverCard))
            .first
            .game
            .name,
        'Downloaded Game00',
      );
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'long press deletes only the confirmed dictionary and clears an active selection',
    (tester) async {
      Future<void> settleGameWork() async {
        await tester.pump();
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pumpAndSettle();
      }

      final catalog = await _downloadedTestCatalog(tester);
      final games = await catalog.loadCatalog();
      await _openApp(tester, gameCatalog: catalog);
      await _selectTab(tester, 'Altyazı');
      await tester.tap(find.text('Downloaded Alpha'));
      await settleGameWork();
      expect(savedGameId, 'downloaded-alpha');
      final activeMemoryCount = gameMemoryCalls.length;
      final cards = tester
          .widgetList<GameCoverCard>(find.byType(GameCoverCard))
          .toList();
      expect(cards.first.downloaded, isTrue);
      expect(cards.last.downloaded, isTrue);
      expect(cards.last.selected, isFalse);
      expect(find.byTooltip('İndirildi'), findsNWidgets(2));
      await _capture(tester, 'game-library-downloaded');

      await tester.longPress(find.text('Downloaded Beta'));
      await settleGameWork();
      expect(find.text('İndirilen çevirileri sil?'), findsOneWidget);
      await tester.tap(find.text('Vazgeç'));
      await settleGameWork();
      expect(
        await tester.runAsync(() => catalog.hasDownloadedPack(games.last)),
        isTrue,
      );
      expect(gameMemoryCalls, hasLength(activeMemoryCount));

      await tester.longPress(find.text('Downloaded Beta'));
      await settleGameWork();
      await tester.tap(find.text('Sil'));
      await settleGameWork();
      expect(
        await tester.runAsync(() => catalog.hasDownloadedPack(games.last)),
        isFalse,
      );
      expect(savedGameId, 'downloaded-alpha');
      expect(gameMemoryCalls, hasLength(activeMemoryCount));
      expect(
        find.byKey(const ValueKey('game-downloaded-downloaded-beta')),
        findsNothing,
      );
      expect(find.byTooltip('İndirildi'), findsOneWidget);

      await tester.longPress(find.text('Downloaded Alpha'));
      await settleGameWork();
      await tester.tap(find.text('Sil'));
      await settleGameWork();
      expect(
        await tester.runAsync(() => catalog.hasDownloadedPack(games.first)),
        isFalse,
      );
      expect(savedGameId, isNull);
      expect(gameMemoryCalls.last, {'gameId': null, 'json': null});
      expect(find.byTooltip('İndirildi'), findsNothing);
      expect(find.text('Downloaded Alpha'), findsOneWidget);
      expect(find.text('Downloaded Beta'), findsOneWidget);
      expect(
        tester
            .widgetList<GameCoverCard>(find.byType(GameCoverCard))
            .every((card) => !card.selected),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'catalog checks on first subtitles visit without startup or resume requests',
    (tester) async {
      var checks = 0;
      final catalog = GameTranslationCatalog.testing(
        catalogUri: Uri.parse(GameTranslationCatalog.catalogUrl),
        cacheDirectory: () async => null,
        token: () async {
          checks++;
          throw StateError('Offline catalog check');
        },
      );
      await _openApp(tester, gameCatalog: catalog);
      expect(checks, 0);
      await _selectTab(tester, 'Altyazı');
      expect(checks, 1);
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pumpAndSettle();
      expect(checks, 1);
      await _selectTab(tester, 'Ana sayfa');
      await _selectTab(tester, 'Altyazı');
      expect(checks, 1);
      expect(find.text('Mafia: The Old Country'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'subtitle tab returns to the existing stream when translation is running',
    (tester) async {
      consoleSaved = true;
      translationRunning = true;
      await _openApp(tester);
      final originalHome = tester.state(find.byType(HomeScreen));
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      final result = navigator.push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => HomeScreen(
            translationRunningOnOpen: true,
            gameCatalog: offlineGameCatalog,
          ),
        ),
      );
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      await _selectTab(tester, 'Altyazı');
      await tester.tap(find.text('Altyazı görünümü'));
      await tester.pumpAndSettle();
      expect(await result, isTrue);
      expect(tester.state(find.byType(HomeScreen)), same(originalHome));
      expect(find.byType(Ps5StreamScreen), findsNothing);
      expect(
        nativeCalls.where(
          (call) => call == 'startSession' || call == 'stopSession',
        ),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'completed setup moves to help even when the paired TV is offline',
    (tester) async {
      checklist = List.filled(SetupGuideScreen.totalSteps, true);
      consoleSaved = true;
      tvSaved = true;
      await _openApp(tester);
      expect(find.text('Kurulum rehberi'), findsNothing);
      await _selectTab(tester, 'Ayarlar');
      expect(find.text('Kurulum rehberi'), findsOneWidget);
      await tester.tap(find.text('Kurulum rehberi'));
      await tester.pumpAndSettle();
      expect(find.byType(SetupGuideScreen), findsOneWidget);
      expect(checklist.every((step) => step), isTrue);
      await tester.tap(find.byKey(const ValueKey('setup-guide-pdf')));
      await tester.pumpAndSettle();
      expect(
        launched.last.toString(),
        'https://example.com/downloads/setup-guide-tr.pdf',
      );
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await _selectTab(tester, 'Ana sayfa');
      expect(find.text('Kurulum rehberi'), findsNothing);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  for (final emailAvailable in [true, false]) {
    testWidgets(
      'game request opens a ready email template with email app available=$emailAvailable',
      (tester) async {
        launchSucceeds = emailAvailable;
        await _openApp(tester);
        await _selectTab(tester, 'Altyazı');
        final search = find.byKey(const ValueKey('game-library-search'));
        await tester.ensureVisible(search);
        await tester.enterText(search, 'Yeni Oyun & لعبة');
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();
        final request = find.byKey(const ValueKey('request-game-button'));
        await tester.ensureVisible(request);
        await tester.tap(request);
        await tester.pumpAndSettle();
        expect(launched.single.scheme, 'mailto');
        expect(launched.single.path, AppLinks.supportEmail);
        expect(
          launched.single.queryParameters['subject'],
          'AnlaOyna - Oyun isteği',
        );
        final body = launched.single.queryParameters['body']!;
        expect(body, contains('Oyun adı: Yeni Oyun & لعبة'));
        expect(body, contains('İstenen dil:'));
        expect(body, contains('Oyun sürümü (PS4 / PS5):'));
        expect(find.byType(TextFormField), findsNothing);
        if (emailAvailable) {
          expect(find.byType(AlertDialog), findsNothing);
        } else {
          expect(find.text(AppLinks.supportEmail), findsOneWidget);
          await tester.tap(find.text('İsteği kopyala'));
          await tester.pumpAndSettle();
          expect(copiedText, contains(body));
        }
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );
  }

  testWidgets(
    'support email, policy links, version and gift redemption are wired',
    (tester) async {
      await _openApp(tester);
      await _selectTab(tester, 'Ayarlar');
      await tester.scrollUntilVisible(
        find.text('1.2.3'),
        250,
        scrollable: find.descendant(
          of: find.byKey(const PageStorageKey('settings-scroll')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.text('1.2.3'), findsOneWidget);
      await tester.ensureVisible(find.text('Bize e-posta gönder'));
      await tester.tap(find.text('Bize e-posta gönder'));
      await tester.pumpAndSettle();
      expect(launched.single.scheme, 'mailto');
      expect(launched.single.path, AppLinks.supportEmail);
      expect(launched.single.queryParameters['subject'], 'AnlaOyna Destek');
      await tester.ensureVisible(find.text('X (Twitter)'));
      expect(find.text('@abreboStudio'), findsOneWidget);
      await tester.tap(find.text('X (Twitter)'));
      await tester.pumpAndSettle();
      expect(launched.last.toString(), 'https://x.com/abreboStudio');
      await tester.ensureVisible(find.text('Gizlilik politikası'));
      await tester.tap(find.text('Gizlilik politikası'));
      await tester.pumpAndSettle();
      expect(launched.last.toString(), 'https://example.com/privacy');
      await tester.ensureVisible(find.text('Kullanım şartları'));
      await tester.tap(find.text('Kullanım şartları'));
      await tester.pumpAndSettle();
      expect(launched.last.toString(), 'https://example.com/terms');
      await _selectTab(tester, 'Profil');
      await tester.ensureVisible(find.text('Hediye kodunu kullan'));
      await tester.tap(find.text('Hediye kodunu kullan'));
      await tester.pumpAndSettle();
      expect(launched.last.toString(), 'https://play.google.com/redeem');
      await _selectTab(tester, 'Ayarlar');
      launchSucceeds = false;
      await tester.ensureVisible(find.text('Bize e-posta gönder'));
      await tester.tap(find.text('Bize e-posta gönder'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Adresi kopyala'));
      await tester.pumpAndSettle();
      expect(copiedText, AppLinks.supportEmail);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'navigation and settings fit a narrow screen with large text',
    (tester) async {
      await _openApp(tester);
      tester.view.physicalSize = const Size(320, 640);
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      await _selectTab(tester, 'Altyazı');
      await _capture(tester, 'subtitles-large-text');
      await _selectTab(tester, 'Profil');
      await _selectTab(tester, 'Ayarlar');
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
