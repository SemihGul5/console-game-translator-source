import '../l10n/app_localizations.dart';
import 'package:flutter/material.dart';

const setupNoticeColor = Color(0xFFFFC56D);

class SetupNotice extends StatelessWidget {
  const SetupNotice({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.warning_amber_rounded,
  });

  final String title;
  final String message;
  final IconData icon;

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
              Text(
                message,
                style: const TextStyle(
                  color: Color(0xFFFFE6BF),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
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
      "Android TV’ne “AnlaOyna TV” uygulamamızı indirip aç. TV’nin dili Türkçe değilse adı “Console Game Translator TV” olarak görünür. Eşleştirme adresi ve 6 haneli kod bu uygulamada yer alır.",
    ),
  );
}
