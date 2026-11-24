import '../l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../services/access_service.dart';

class PremiumStatusButton extends StatelessWidget {
  const PremiumStatusButton({super.key, required this.onOpenDetails});

  final VoidCallback onOpenDetails;
  static const _gold = Color(0xFFFFD580);

  Future<void> _showStatus(BuildContext context) async {
    final openDetails = await showDialog<bool>(
      context: context,
      builder: (context) => ListenableBuilder(
        listenable: AccessService.instance,
        builder: (context, _) {
          final status = AccessService.instance.status;
          final lifetime = status.state == 'lifetime';
          return AlertDialog(
            icon: Icon(
              status.premium
                  ? Icons.workspace_premium_rounded
                  : Icons.info_outline_rounded,
              color: _gold,
              size: 42,
            ),
            title: Text(
              status.premium
                  ? lifetime
                        ? context.tr("Süresiz Premium aktif")
                        : context.tr("Premium aboneliğin aktif")
                  : context.tr("Premium durumun değişti"),
            ),
            scrollable: true,
            content: Text(_description(context, status)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.tr("Kapat")),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  lifetime
                      ? context.tr("Premium ayrıntıları")
                      : context.tr("Abonelik ayrıntıları"),
                ),
              ),
            ],
          );
        },
      ),
    );
    if (openDetails == true && context.mounted) onOpenDetails();
  }

  String _description(BuildContext context, AccessStatus status) {
    if (!status.premium) {
      return context.tr(
        "Güncel erişim durumunu ve satın alımlarını ayrıntılar ekranından kontrol edebilirsin.",
      );
    }
    if (status.state == 'lifetime') {
      return context.tr(
        "Premium çeviri özelliklerine süresiz erişimin var. Tek seferlik satın alımın için otomatik yenileme veya tekrar ödeme yok.",
      );
    }
    final end = status.expiresAt?.toLocal();
    final localizations = MaterialLocalizations.of(context);
    final date = end == null
        ? null
        : '${localizations.formatMediumDate(end)} · '
              '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(end), alwaysUse24HourFormat: true)}';
    if (status.state == 'trial') {
      return context.tr("Google Play deneme aboneliğin aktif. {0}{1}", [
        date == null ? '' : context.tr("Deneme bitişi: {0}. ", [date]),
        status.willRenew
            ? context.tr("Deneme sonunda ücretli olarak yenilenir.")
            : context.tr("Otomatik yenileme kapalı."),
      ]);
    }
    return context.tr("Premium çeviri özelliklerini kullanabilirsin.\n\n{0}{1}", [
      status.willRenew
          ? context.tr("Otomatik yenileme açık.")
          : context.tr(
              "Otomatik yenileme kapalı; mevcut dönem sonuna kadar erişimin devam eder.",
            ),
      date == null
          ? ''
          : '\n${status.willRenew ? context.tr("Sonraki yenileme") : context.tr("Erişim bitişi")}: $date.',
    ]);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AccessService.instance,
    builder: (context, _) {
      if (!AccessService.instance.status.premium) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsetsDirectional.only(start: 8),
        child: IconButton.filledTonal(
          tooltip: context.tr("Premium aktif"),
          style: IconButton.styleFrom(
            foregroundColor: _gold,
            backgroundColor: _gold.withValues(alpha: 0.12),
            minimumSize: const Size(48, 48),
            side: BorderSide(color: _gold.withValues(alpha: 0.3)),
          ),
          onPressed: () => _showStatus(context),
          icon: const Icon(Icons.workspace_premium_rounded),
        ),
      );
    },
  );
}
