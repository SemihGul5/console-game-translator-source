import '../l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../services/app_links.dart';

const setupNoticeColor = Color(0xFFFFC56D);

/// Renders `**text**` segments in [message] as bold.
List<InlineSpan> _boldSpans(String message) {
  final parts = message.split('**');
  return [
    for (var i = 0; i < parts.length; i++)
      if (parts[i].isNotEmpty)
        TextSpan(
          text: parts[i],
          style: i.isOdd
              ? const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                )
              : null,
        ),
  ];
}

class SetupNotice extends StatelessWidget {
  const SetupNotice({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.warning_amber_rounded,
    this.action,
  });

  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: setupNoticeColor.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: setupNoticeColor.withValues(alpha: 0.55)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: setupNoticeColor, size: 23),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: setupNoticeColor,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(children: _boldSpans(message)),
                style: const TextStyle(
                  color: Color(0xFFFFE6BF),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              if (action != null) ...[const SizedBox(height: 10), action!],
            ],
          ),
        ),
      ],
    ),
  );
}

class SmartTvBetaNotice extends StatelessWidget {
  const SmartTvBetaNotice({super.key});

  @override
  Widget build(BuildContext context) => SetupNotice(
    title: context.tr('Beta TV desteği'),
    message: context.tr(
      'LG webOS ve Samsung Tizen desteği beta aşamasındadır. TV modeline göre bağlantı veya altyazı hataları yaşanabilir.',
    ),
  );
}

class TvAppInstallNotice extends StatelessWidget {
  const TvAppInstallNotice({super.key});

  @override
  Widget build(BuildContext context) => SetupNotice(
    icon: Icons.install_desktop_rounded,
    title: context.tr("Önce TV uygulamasını indir"),
    message: context.tr(
      'TV uygulaması artık Google Play’de. Android TV / Google TV cihazında Play Store’da **Oyun Çevirmeni TV** diye arayıp kur. TV’nin dili İngilizceyse **Console Game Translator TV** yaz. İstersen aşağıdaki düğmeyle mağaza sayfasını da açabilirsin.',
    ),
    action: OutlinedButton.icon(
      onPressed: () => AppLinks.openWeb(context, AppLinks.tvAppPlayStoreUrl),
      icon: const Icon(Icons.shop_rounded),
      label: Text(context.tr('Google Play’de aç')),
    ),
  );
}
