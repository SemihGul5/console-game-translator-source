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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
    decoration: BoxDecoration(
      color: setupNoticeColor.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: setupNoticeColor.withValues(alpha: 0.35)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.install_desktop_rounded,
              color: setupNoticeColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.tr("Önce TV uygulamasını indir"),
                style: const TextStyle(
                  color: setupNoticeColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text.rich(
          TextSpan(
            children: _boldSpans(
              context.tr(
                'TV’de Play Store’dan **Oyun Çevirmeni TV**’yi kur. TV İngilizceyse **Console Game Translator TV** ara. En güncel sürüm her zaman sitede.',
              ),
            ),
          ),
          style: const TextStyle(
            color: Color(0xFFE9DCC6),
            fontSize: 12,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: _NoticeButton(
                icon: Icons.shop_rounded,
                label: context.tr('Google Play’de aç'),
                onPressed: () =>
                    AppLinks.openWeb(context, AppLinks.tvAppPlayStoreUrl),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              // Google Play rolls out TV updates slowly; the website always has the latest APK.
              child: _NoticeButton(
                key: const ValueKey('tv-app-latest-website'),
                icon: Icons.download_rounded,
                label: context.tr('Siteden indir'),
                onPressed: () => AppLinks.openTvSetup(context, 'android'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _NoticeButton extends StatelessWidget {
  const _NoticeButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 16),
    label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    style: OutlinedButton.styleFrom(
      foregroundColor: setupNoticeColor,
      side: BorderSide(color: setupNoticeColor.withValues(alpha: 0.45)),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      minimumSize: const Size(0, 36),
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}
