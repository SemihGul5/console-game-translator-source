import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../l10n/app_localizations.dart';

class PremiumPlanCard extends StatelessWidget {
  const PremiumPlanCard({
    super.key,
    required this.package,
    required this.availablePackages,
    required this.onPurchase,
  });

  final Package package;
  final List<Package> availablePackages;
  final VoidCallback? onPurchase;

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
    final lifetime = package.packageType == PackageType.lifetime;
    final price = package.storeProduct.priceString;
    final period = context.tr(switch (package.packageType) {
      PackageType.weekly => 'hafta',
      PackageType.monthly => 'ay',
      PackageType.annual => 'yıl',
      _ => 'dönem',
    });
    final savings = _savings();
    final highlight = lifetime && _comparable(package);
    final terms = lifetime
        ? context.tr('{0} · tek ödeme, otomatik yenilenmez.', [price])
        : context.tr(
            '{0} / {1}. Aboneliğin otomatik yenilenir; Google Play’den iptal edebilirsin.',
            [price, period],
          );
    return Card(
      shape: highlight
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: accent.withValues(alpha: 0.5)),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  _title(context),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (highlight)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      context.tr('En avantajlı'),
                      style: const TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(terms),
            if (highlight) ...[
              const SizedBox(height: 8),
              Text(
                context.tr('Uzun vadeli kullanım için tek ödeme.'),
                style: const TextStyle(fontSize: 12, height: 1.4),
              ),
            ],
            if (savings != null) ...[
              const SizedBox(height: 10),
              Text(
                context.tr(
                  package.packageType == PackageType.monthly
                      ? 'Haftalık plana göre %{0} tasarruf'
                      : '12 aylık ödemeye göre %{0} tasarruf',
                  [savings],
                ),
                style: const TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onPurchase,
              child: Text(
                context.tr(lifetime ? 'Süresiz satın al' : 'Abone ol'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
