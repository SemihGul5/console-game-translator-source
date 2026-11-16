import 'package:flutter/material.dart';

import '../l10n/app_language.dart';
import '../l10n/app_localizations.dart';
import 'settings_section.dart';

class AppLanguageEntry extends StatelessWidget {
  const AppLanguageEntry({super.key});

  static String _label(BuildContext context, AppLanguage language) =>
      switch (language) {
        AppLanguage.system => context.tr('Sistem dili'),
        AppLanguage.turkish => 'Türkçe',
        AppLanguage.english => 'English',
      };

  @override
  Widget build(BuildContext context) {
    final controller = AppLanguageScope.of(context);
    return SettingsEntry(
      icon: Icons.language_rounded,
      title: context.tr('Uygulama dili'),
      subtitle: _label(context, controller.language),
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => _AppLanguageDialog(controller: controller),
      ),
    );
  }
}

class _AppLanguageDialog extends StatefulWidget {
  const _AppLanguageDialog({required this.controller});
  final AppLanguageController controller;

  @override
  State<_AppLanguageDialog> createState() => _AppLanguageDialogState();
}

class _AppLanguageDialogState extends State<_AppLanguageDialog> {
  bool _saving = false;

  Future<void> _select(AppLanguage language) async {
    setState(() => _saving = true);
    try {
      await widget.controller.select(language);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Dil tercihi kaydedilemedi. Tekrar dene.')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: Text(context.tr('Uygulama dili')),
    contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            context.tr(
              'Bu seçim arayüz dilini ve oyun kütüphanesindeki dil filtresini belirler.',
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final language in AppLanguage.values)
          ListTile(
            enabled: !_saving,
            title: Text(AppLanguageEntry._label(context, language)),
            selected: widget.controller.language == language,
            trailing: widget.controller.language == language
                ? const Icon(Icons.check_rounded)
                : null,
            onTap: () => _select(language),
          ),
        if (_saving) const LinearProgressIndicator(),
      ],
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: Text(context.tr('Kapat')),
      ),
    ],
  );
}
