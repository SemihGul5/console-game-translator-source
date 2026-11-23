import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gametranslate/l10n/app_localizations.dart';
import 'package:gametranslate/widgets/premium_plan_card.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

Package plan(
  PackageType type,
  double price, {
  String currency = 'TRY',
  String? formatted,
  double? weeklyRate,
  String? period,
  List<SubscriptionOption>? options,
}) => Package(
  type.name,
  type,
  StoreProduct(
    type.name,
    '',
    'Premium',
    price,
    formatted ?? '$price TL',
    currency,
    pricePerWeek: weeklyRate,
    subscriptionPeriod:
        period ??
        switch (type) {
          PackageType.weekly => 'P1W',
          PackageType.monthly => 'P1M',
          PackageType.annual => 'P1Y',
          _ => null,
        },
    subscriptionOptions: options,
  ),
  const PresentedOfferingContext('default', null, null),
);

Future<void> showPlan(
  WidgetTester tester,
  Package package,
  List<Package> packages, {
  Locale locale = const Locale('tr'),
  VoidCallback? onSelect,
  bool selected = false,
}) => tester.pumpWidget(
  MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('tr'), Locale('en')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    theme: ThemeData.dark(useMaterial3: true),
    home: Scaffold(
      body: SingleChildScrollView(
        child: PremiumPlanCard(
          package: package,
          availablePackages: packages,
          selected: selected,
          onSelect: onSelect,
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('monthly savings use the SDK weekly equivalent and round down', (
    tester,
  ) async {
    final weekly = plan(PackageType.weekly, 20);
    final monthly = plan(
      PackageType.monthly,
      60,
      weeklyRate: 14.1,
      formatted: '₺60,00',
    );
    var selections = 0;
    await showPlan(tester, monthly, [
      weekly,
      monthly,
    ], onSelect: () => selections++);
    expect(find.text('Haftalık plana göre %29 tasarruf'), findsOneWidget);
    expect(find.text('₺60,00'), findsOneWidget);
    expect(find.text('/ ay'), findsOneWidget);
    await tester.tap(find.byType(PremiumPlanCard));
    expect(selections, 1);
    expect(find.text('En avantajlı'), findsNothing);
    final context = tester.element(find.byType(PremiumPlanCard));
    expect(
      PremiumPlanCard.termsFor(context, monthly),
      '₺60,00 / ay. Aboneliğin otomatik yenilenir; Google Play’den iptal edebilirsin.',
    );
    expect(PremiumPlanCard.actionLabel(context, monthly), 'Abone ol');
  });

  testWidgets(
    'annual savings compare with twelve monthly payments and update with prices',
    (tester) async {
      final annual = plan(PackageType.annual, 600, formatted: '₺600,00');
      await showPlan(tester, annual, [plan(PackageType.monthly, 100), annual]);
      expect(find.text('12 aylık ödemeye göre %50 tasarruf'), findsOneWidget);
      expect(find.text('₺600,00'), findsOneWidget);
      expect(find.text('/ yıl'), findsOneWidget);
      await showPlan(tester, annual, [plan(PackageType.monthly, 200), annual]);
      expect(find.text('12 aylık ödemeye göre %75 tasarruf'), findsOneWidget);
      // Use the least expensive comparable reference, even if offerings duplicate a tier.
      await showPlan(tester, annual, [
        plan(PackageType.monthly, 200),
        plan(PackageType.monthly, 100),
        annual,
      ]);
      expect(find.text('12 aylık ödemeye göre %50 tasarruf'), findsOneWidget);
    },
  );

  testWidgets(
    'missing, invalid, higher or incomparable prices never advertise a saving',
    (tester) async {
      final monthly = plan(PackageType.monthly, 100);
      for (final prices in [
        <Package>[],
        [plan(PackageType.monthly, 100, currency: 'USD')],
        [plan(PackageType.monthly, 0)],
        [plan(PackageType.monthly, double.nan)],
        [plan(PackageType.monthly, 100, period: 'P3M')],
        [plan(PackageType.monthly, 10)],
      ]) {
        await showPlan(tester, plan(PackageType.annual, 600), prices);
        expect(find.textContaining('tasarruf'), findsNothing);
      }
      await showPlan(tester, monthly, [plan(PackageType.weekly, 50), monthly]);
      expect(
        find.textContaining('tasarruf'),
        findsNothing,
        reason: 'No normalized weekly rate is available.',
      );
      await showPlan(tester, plan(PackageType.monthly, 100, weeklyRate: 60), [
        plan(PackageType.weekly, 50),
      ]);
      expect(find.textContaining('tasarruf'), findsNothing);
    },
  );

  testWidgets('a base plan price mismatch never creates an inflated saving', (
    tester,
  ) async {
    const fullPrice = PricingPhase(
      null,
      RecurrenceMode.infiniteRecurring,
      null,
      Price('80 TL', 80000000, 'TRY'),
      null,
    );
    const base = SubscriptionOption(
      'monthly',
      'premium:monthly',
      'premium',
      [fullPrice],
      [],
      true,
      null,
      false,
      fullPrice,
      null,
      null,
      null,
      null,
    );
    await showPlan(tester, plan(PackageType.annual, 600), [
      plan(PackageType.monthly, 100, options: [base]),
    ]);
    expect(find.textContaining('tasarruf'), findsNothing);
  });

  testWidgets(
    'lifetime highlights long-term value without a fictional saving percentage',
    (tester) async {
      final lifetime = plan(PackageType.lifetime, 1200, formatted: '₺1.200,00');
      await showPlan(tester, lifetime, [
        plan(PackageType.monthly, 100),
        lifetime,
      ]);
      expect(find.text('En avantajlı'), findsOneWidget);
      expect(find.text('Uzun vadeli kullanım için tek ödeme.'), findsOneWidget);
      expect(find.text('₺1.200,00'), findsOneWidget);
      expect(find.text('tek ödeme'), findsOneWidget);
      final context = tester.element(find.byType(PremiumPlanCard));
      expect(
        PremiumPlanCard.termsFor(context, lifetime),
        '₺1.200,00 · tek ödeme, otomatik yenilenmez.',
      );
      expect(PremiumPlanCard.actionLabel(context, lifetime), 'Süresiz satın al');
      expect(PremiumPlanCard.isHighlighted(lifetime), isTrue);
      expect(find.textContaining('%'), findsNothing);
      // Without onSelect the tile is inert.
      await tester.tap(find.byType(PremiumPlanCard));
      expect(tester.takeException(), isNull);
      await showPlan(tester, plan(PackageType.weekly, 20), [lifetime]);
      expect(find.textContaining('tasarruf'), findsNothing);
      expect(find.text('En avantajlı'), findsNothing);
    },
  );

  testWidgets(
    'English savings and the lifetime badge fit a small screen with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await showPlan(tester, plan(PackageType.annual, 600), [
        plan(PackageType.monthly, 100),
      ], locale: const Locale('en'));
      expect(
        find.text('Save 50% compared with 12 monthly payments'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await showPlan(
        tester,
        plan(PackageType.lifetime, 1200),
        [],
        locale: const Locale('en'),
      );
      expect(find.text('Best value'), findsOneWidget);
      expect(find.text('One payment for long-term use.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
