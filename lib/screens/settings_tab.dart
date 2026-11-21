import '../l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../services/app_links.dart';
import '../widgets/settings_section.dart';
import 'translation_cache_screen.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({
    super.key,
    required this.personalization,
    required this.setupCompleted,
    required this.onOpenSetup,
    required this.onOpenFaq,
  });

  final Widget personalization;
  final bool setupCompleted;
  final VoidCallback onOpenSetup;
  final VoidCallback onOpenFaq;

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  AppInformation _information = const AppInformation();

  @override
  void initState() {
    super.initState();
    _loadInformation();
  }

  Future<void> _loadInformation() async {
    final information = await AppInformation.load();
    if (mounted) setState(() => _information = information);
  }

  @override
  Widget build(BuildContext context) => ListView(
    key: const PageStorageKey('settings-scroll'),
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
    children: [
      SettingsPageHeader(
        title: context.tr("Ayarlar"),
        description: context.tr("Uygulamayı kendine göre düzenle."),
      ),
      widget.personalization,
      SettingsSection(
        title: context.tr('Gelişmiş'),
        children: [
          SettingsEntry(
            icon: Icons.storage_rounded,
            title: context.tr('Çeviri önbelleği'),
            subtitle: context.tr('Saklama sınırları, yedekleme ve temizleme'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const TranslationCacheScreen(),
              ),
            ),
          ),
        ],
      ),
      SettingsSection(
        title: context.tr("Yardım"),
        children: [
          SettingsEntry(
            icon: Icons.quiz_outlined,
            title: context.tr("Sık Sorulan Sorular"),
            subtitle: context.tr("Bağlantı ve çeviri hakkında yanıtlar"),
            onTap: widget.onOpenFaq,
          ),
          if (widget.setupCompleted)
            SettingsEntry(
              icon: Icons.checklist_rounded,
              title: context.tr("Kurulum rehberi"),
              subtitle: context.tr("Tamamladığın adımları yeniden incele"),
              onTap: widget.onOpenSetup,
            ),
          SettingsEntry(
            icon: Icons.mail_outline_rounded,
            title: context.tr("Bize e-posta gönder"),
            subtitle: AppLinks.supportEmail,
            onTap: () => AppLinks.contactSupport(context),
          ),
          SettingsEntry(
            icon: Icons.alternate_email_rounded,
            title: 'X (Twitter)',
            subtitle: AppLinks.xHandle,
            onTap: () => AppLinks.openWeb(context, AppLinks.xProfileUrl),
          ),
        ],
      ),
      SettingsSection(
        title: context.tr("Uygulama hakkında"),
        children: [
          SettingsEntry(
            icon: Icons.privacy_tip_outlined,
            title: context.tr("Gizlilik politikası"),
            onTap: () => AppLinks.openWeb(context, _information.privacyUrl),
          ),
          SettingsEntry(
            icon: Icons.description_outlined,
            title: context.tr("Kullanım şartları"),
            onTap: () => AppLinks.openWeb(context, _information.termsUrl),
          ),
          SettingsEntry(
            icon: Icons.info_outline_rounded,
            title: context.tr("Sürüm"),
            subtitle: context.tr(_information.versionLabel),
          ),
        ],
      ),
    ],
  );
}
