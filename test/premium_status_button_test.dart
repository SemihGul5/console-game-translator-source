import 'support/turkish_test_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gametranslate/services/access_service.dart';
import 'package:gametranslate/widgets/premium_status_button.dart';

void main() {
  const channel = MethodChannel(
    'com.abrebostudio.consolegametranslator/access',
  );
  final service = AccessService.instance;
  late Map<String, dynamic> nativeStatus;

  setUp(() {
    nativeStatus = {'state': 'inactive'};
    service.status = const AccessStatus('inactive');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'status');
          return nativeStatus;
        });
  });

  tearDown(() {
    service.status = const AccessStatus('inactive');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('badge follows purchase and expiry, not the free account trial', (
    tester,
  ) async {
    await tester.pumpWidget(
      TurkishTestApp(
        home: Scaffold(
          appBar: AppBar(actions: [PremiumStatusButton(onOpenDetails: () {})]),
        ),
      ),
    );
    expect(find.byTooltip('Premium aktif'), findsNothing);
    nativeStatus = {
      'state': 'trial',
      'source': 'free_trial',
      'trialRemainingMs': 10000,
    };
    await service.readNativeStatus();
    await tester.pump();
    expect(find.byTooltip('Premium aktif'), findsNothing);

    nativeStatus = {
      'state': 'premium',
      'willRenew': false,
      'expiresAtMs': DateTime(2027, 2, 20, 14, 30).millisecondsSinceEpoch,
    };
    await service.readNativeStatus();
    await tester.pump();
    await tester.tap(find.byTooltip('Premium aktif'));
    await tester.pumpAndSettle();
    expect(find.text('Premium aboneliğin aktif'), findsOneWidget);
    expect(find.textContaining('Otomatik yenileme kapalı'), findsOneWidget);
    expect(find.textContaining('Erişim bitişi:'), findsOneWidget);

    nativeStatus = {'state': 'expired'};
    await service.readNativeStatus();
    await tester.pumpAndSettle();
    expect(find.byTooltip('Premium aktif'), findsNothing);
    expect(find.text('Premium durumun değişti'), findsOneWidget);
    await tester.tap(find.text('Kapat'));
    await tester.pumpAndSettle();
  });

  testWidgets('lifetime explains one-time access and opens premium details', (
    tester,
  ) async {
    service.status = const AccessStatus('lifetime');
    var openedDetails = false;
    await tester.pumpWidget(
      TurkishTestApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [
              PremiumStatusButton(onOpenDetails: () => openedDetails = true),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Premium aktif'));
    await tester.pumpAndSettle();
    expect(find.text('Süresiz Premium aktif'), findsOneWidget);
    expect(find.textContaining('tekrar ödeme yok'), findsOneWidget);
    expect(find.textContaining('Sonraki yenileme:'), findsNothing);
    await tester.tap(find.text('Premium ayrıntıları'));
    await tester.pumpAndSettle();
    expect(openedDetails, isTrue);
  });
}
