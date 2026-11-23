import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../l10n/app_localizations.dart';

/// A selectable plan tile. The purchase button lives on the screen and buys
/// the selected package; this tile only shows price, period and savings.
class PremiumPlanCard extends StatelessWidget {
  const PremiumPlanCard({
    super.key,
    required this.package,
    required this.availablePackages,
    this.selected = false,
    this.onSelect,
  });

  final Package package;
  final List<Package> availablePackages;
  final bool selected;
  final VoidCallback? onSelect;

  /// The one-time plan with a valid price is recommended ("Best value").
  static bool isHighlighted(Package package) =>
      package.packageType == PackageType.lifetime && _comparable(package);

  /// Price, billing period and renewal terms of [package], shown next to the
  /// purchase button for the selected plan.
  static String termsFor(BuildContext context, Package package) {
    final price = package.storeProduct.priceString;
    if (package.packageType == PackageType.lifetime) {
      return context.tr('{0} · tek ödeme, otomatik yenilenmez.', [price]);
    }
    return context.tr(
      '{0} / {1}. Aboneliğin otomatik yenilenir; Google Play’den iptal edebilirsin.',
      [price, _periodWord(context, package)],
    );
  }

  static String actionLabel(BuildContext context, Package package) =>
      context.tr(
        package.packageType == PackageType.lifetime
            ? 'Süresiz satın al'
            : 'Abone ol',
      );

  static String _periodWord(BuildContext context, Package package) =>
      context.tr(switch (package.packageType) {
        PackageType.weekly => 'hafta',
        PackageType.monthly => 'ay',
        PackageType.annual => 'yıl',
        _ => 'dönem',
      });

  static bool _comparable(Package package) {
    final product = package.storeProduct;
    if (!product.price.isFinite ||
        product.price <= 0 ||
        product.currencyCode.trim().isEmpty) {
      return false;
    }
    final period = product.subscriptionPeriod;
    final periods = switch (package.packageType) {
      PackageType.weekly => const ['P1W', 'P7D'],
      PackageType.monthly => const ['P1M'],
      PackageType.annual => const ['P1Y', 'P12M'],
      _ => const <String>[],
    };
    if (period != null && periods.isNotEmpty && !periods.contains(period)) {
      return false;
    }
    // The purchase flow selects the first base plan, without introductory offers.
    // Don't compare prices if that plan disagrees with the displayed product.
    final base = product.subscriptionOptions
        ?.where((option) => option.isBasePlan)
        .firstOrNull;
    final fullPrice = base?.fullPricePhase?.price;
    if (fullPrice != null &&
        (fullPrice.currencyCode != product.currencyCode ||
            (fullPrice.amountMicros / 1000000 - product.price).abs() >
                0.000001)) {
      return false;
    }
    return true;
  }

  int? _savings() {
    if (!_comparable(package)) return null;
    final referenceType = switch (package.packageType) {
      PackageType.monthly => PackageType.weekly,
      PackageType.annual => PackageType.monthly,
      _ => null,
    };
    if (referenceType == null) return null;
    final references =
        availablePackages
            .where(
              (candidate) =>
                  candidate.packageType == referenceType &&
                  candidate.storeProduct.currencyCode ==
                      package.storeProduct.currencyCode &&
                  _comparable(candidate),
            )
            .toList()
          ..sort(
            (a, b) => a.storeProduct.price.compareTo(b.storeProduct.price),
          );
    if (references.isEmpty) return null;
    final reference = references.first.storeProduct;
    final price = package.packageType == PackageType.annual
        ? package.storeProduct.price
        : package.storeProduct.pricePerWeek;
    final regular = package.packageType == PackageType.annual
        ? reference.price * 12
        : reference.price;
    if (price == null ||
        !price.isFinite ||
        price <= 0 ||
        !regular.isFinite ||
        regular <= price) {
      return null;
    }
    // Round down so the advertised percentage never exceeds the actual saving.
    final percent = ((1 - price / regular) * 100).floor();
    return percent > 0 ? percent : null;
  }

  String _title(BuildContext context) =>
      context.tr(switch (package.packageType) {
        PackageType.weekly => 'Haftalık',
        PackageType.monthly => 'Aylık',
        PackageType.annual => 'Yıllık',
        PackageType.lifetime => 'Süresiz',
        _ => 'Premium',
      });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF4DE2D0);
    const muted = Color(0xFF929DB4);
    final lifetime = package.packageType == PackageType.lifetime;
    final savings = _savings();
    final highlight = isHighlighted(package);
    final subtitle = savings != null
        ? context.tr(
            package.packageType == PackageType.monthly
                ? 'Haftalık plana göre %{0} tasarruf'
                : '12 aylık ödemeye göre %{0} tasarruf',
            [savings],
          )
        : highlight
        ? context.tr('Uzun vadeli kullanım için tek ödeme.')
        : null;
    final period = lifetime
        ? context.tr('tek ödeme')
        : '/ ${_periodWord(context, package)}';
    final radius = BorderRadius.circular(18);
    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.08)
              : const Color(0xFF131A2B),
          borderRadius: radius,
          border: Border.all(
            color: selected ? accent : const Color(0xFF2A3447),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.16),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onSelect,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? accent : Colors.transparent,
                      border: Border.all(
                        color: selected ? accent : const Color(0xFF55627A),
                        width: 2,
                      ),
                    ),
                    child: selected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Color(0xFF062027),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              _title(context),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            if (highlight)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF0070D1),
                                      Color(0xFF00A6C8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  context.tr('En avantajlı'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 5),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: savings != null ? accent : muted,
                              fontSize: 12.5,
                              fontWeight: savings != null
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          package.storeProduct.priceString,
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          period,
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontSize: 12, color: muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
