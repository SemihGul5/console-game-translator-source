import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/access_service.dart';

class SubscriptionOfferCard extends StatelessWidget {
  const SubscriptionOfferCard({
    super.key,
    required this.status,
    required this.onViewPlans,
  });

  final AccessStatus status;
  final VoidCallback? onViewPlans;

  String _description(BuildContext context) {
    if (status.source == 'free_trial' && status.canStart) {
      return context.tr('Ücretsiz denemeniz devam ediyor. Kalan süre: {0}.', [
        status.remainingLabel,
      ]);
    }
    if (status.state == 'expired') {
      return context.tr(
        'Ücretsiz denemeniz sona erdi. Devam etmek için bir paket seçebilirsiniz.',
      );
    }
    if (const {'signed_out', 'available'}.contains(status.state) &&
        status.freeTrialMinutes != null) {
      return context.tr(
        'İsterseniz abone olmadan {0} dakika ücretsiz deneyebilirsiniz.',
        [status.freeTrialMinutes],
      );
    }
    return context.tr('Premium paketlerini ve fiyatlarını inceleyebilirsiniz.');
  }

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('home-subscription-offer'),
    padding: const EdgeInsets.fromLTRB(14, 13, 14, 10),
    decoration: BoxDecoration(
      color: const Color(0xFF151E2D),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFF303C51)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.workspace_premium_outlined,
              size: 19,
              color: Color(0xFFC1C9E4),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.tr('Hemen abone olun'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          _description(context),
          style: const TextStyle(
            color: Color(0xFFB6C0D0),
            fontSize: 13,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          key: const ValueKey('view-premium-plans'),
          onPressed: onViewPlans,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFD9E1F2),
            side: const BorderSide(color: Color(0xFF3A4860)),
            minimumSize: const Size.fromHeight(40),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  context.tr('Paketleri ve fiyatları görün'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, size: 18),
            ],
          ),
        ),
      ],
    ),
  );
}
