import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class FreeTrialOfferCard extends StatelessWidget {
  const FreeTrialOfferCard({
    super.key,
    required this.minutes,
    required this.onStart,
  });

  final int? minutes;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('free-trial-offer'),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF172332),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFF314052)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr('Abone olmadan deneyin'),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          minutes == null
              ? context.tr('Ücretsiz deneme süresi kontrol ediliyor.')
              : context.tr(
                  'Google hesabınızla {0} dakika ücretsiz deneyebilirsiniz.',
                  [minutes],
                ),
          style: const TextStyle(
            fontSize: 13,
            height: 1.45,
            color: Color(0xFFBFCAD8),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.tonal(
          key: const ValueKey('start-free-trial'),
          onPressed: onStart,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF4DE2D0).withValues(alpha: 0.14),
            foregroundColor: const Color(0xFF4DE2D0),
            side: BorderSide(
              color: const Color(0xFF4DE2D0).withValues(alpha: 0.5),
            ),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            context.tr('Google ile ücretsiz dene'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 9),
        Text(
          context.tr('Ödeme bilgisi gerekmez. Otomatik abonelik başlamaz.'),
          style: const TextStyle(
            fontSize: 12,
            height: 1.4,
            color: Color(0xFFA8B7C5),
          ),
        ),
      ],
    ),
  );
}
