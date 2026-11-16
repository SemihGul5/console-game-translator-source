import '../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_branding.dart';

class AppInformation {
  const AppInformation({
    this.version = '',
    this.build = '',
    this.privacyUrl = '',
    this.termsUrl = '',
  });

  final String version;
  final String build;
  final String privacyUrl;
  final String termsUrl;

  String get versionLabel =>
      version.isEmpty ? 'Sürüm bilgisi alınamadı' : version;

  static Future<AppInformation> load() async {
    const channel = MethodChannel(
      'com.abrebostudio.consolegametranslator/ps5_registration',
    );
    try {
      final info = await channel.invokeMapMethod<String, dynamic>('getAppInfo');
      return AppInformation(
        version: info?['version']?.toString() ?? '',
        build: info?['build']?.toString() ?? '',
        privacyUrl: info?['privacyUrl']?.toString() ?? '',
        termsUrl: info?['termsUrl']?.toString() ?? '',
      );
    } on PlatformException {
      return const AppInformation();
    } on MissingPluginException {
      return const AppInformation();
    }
  }
}

class AppLinks {
  static const supportEmail = 'abrebostudio@gmail.com';
  static const xHandle = '@abreboStudio';
  static const xProfileUrl = 'https://x.com/abreboStudio';

  static Uri? tvSetupUri(AppInformation info, String brand, String language) {
    if (!const {'android', 'lg', 'samsung'}.contains(brand)) return null;
    final base = Uri.tryParse(info.privacyUrl);
    if (base == null ||
        base.scheme != 'https' ||
        base.host.isEmpty ||
        base.userInfo.isNotEmpty) {
      return null;
    }
    return base
        .resolve('tv-setup.html')
        .replace(
          queryParameters: {
            'brand': brand,
            'lang': language == 'tr' ? 'tr' : 'en',
          },
        );
  }

  static Future<void> openTvSetup(BuildContext context, String brand) async {
    final info = await AppInformation.load();
    if (!context.mounted) return;
    final uri = tvSetupUri(
      info,
      brand,
      AppLocalizations.of(context).locale.languageCode,
    );
    await openWeb(context, uri?.toString() ?? '');
  }

  static Uri? setupGuidePdfUri(AppInformation info) {
    final base = Uri.tryParse(info.privacyUrl);
    if (base == null ||
        base.scheme != 'https' ||
        base.host.isEmpty ||
        base.userInfo.isNotEmpty) {
      return null;
    }
    return base.resolve('downloads/setup-guide-tr.pdf');
  }

  static Future<void> openSetupGuidePdf(BuildContext context) async {
    final info = await AppInformation.load();
    if (!context.mounted) return;
    await openWeb(context, setupGuidePdfUri(info)?.toString() ?? '');
  }

  static Future<void> openWeb(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      if (context.mounted) {
        _message(
          context,
          context.tr(
            "Bağlantı henüz hazır değil. Lütfen daha sonra tekrar dene.",
          ),
        );
      }
      return;
    }
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // Keep the caller usable when no external application can open the link.
    }
    if (context.mounted) {
      _message(context, context.tr("Bağlantı açılamadı. Lütfen tekrar dene."));
    }
  }

  static Future<void> contactTvSupport(
    BuildContext context,
    String tvType,
  ) async {
    final info = await AppInformation.load();
    if (!context.mounted) return;
    final version = info.version.isEmpty
        ? context.tr('Sürüm bilgisi alınamadı')
        : '${info.version}${info.build.isEmpty ? '' : ' (${info.build})'}';
    await contactSupport(
      context,
      subject: context.tr('{0} TV bağlantı desteği', [tvType]),
      body: context.tr(
        'TV türü: {0}\nTV modeli:\nTV yazılım sürümü:\nUygulama sürümü: {1}\nSorun yaşadığın adım:\nSorunun açıklaması:\n\nSorunun ekran görüntüsünü bu e-postaya ekleyebilirsin.',
        [tvType, version],
      ),
    );
  }

  static Future<void> requestGame(
    BuildContext context, {
    String gameName = '',
  }) async {
    final subject = context.tr('{0} - Oyun isteği', [
      AppBranding.nameOf(context),
    ]);
    final body = context.tr(
      'Oyun adı: {0}\nİstenen dil:\nOyun sürümü (PS4 / PS5):\n\nEk not:',
      [gameName],
    );
    await contactSupport(
      context,
      subject: subject,
      body: body,
      copyText: '$subject\n\n$body',
    );
  }

  static Future<void> contactSupport(
    BuildContext context, {
    String? subject,
    String? body,
    String? copyText,
  }) async {
    final uri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      query:
          'subject=${Uri.encodeComponent(subject ?? context.tr("{0} Destek", [AppBranding.nameOf(context)]))}'
          '${body == null ? '' : '&body=${Uri.encodeComponent(body)}'}',
    );
    try {
      if (await launchUrl(uri)) return;
    } catch (_) {
      // Offer the address even on devices without an email application.
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: Text(context.tr("Bize e-posta gönder")),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(
                "E-posta uygulaması açılamadı. Bu adresten bize ulaşabilirsin:",
              ),
            ),
            SizedBox(height: 12),
            SelectableText(supportEmail),
            if (copyText != null) ...[
              const SizedBox(height: 12),
              SelectableText(copyText),
            ],
          ],
        ),
        actions: [
          if (copyText != null)
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: copyText));
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                if (context.mounted) {
                  _message(context, context.tr('İstek metni kopyalandı.'));
                }
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: Text(context.tr('İsteği kopyala')),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr("Kapat")),
          ),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(const ClipboardData(text: supportEmail));
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              if (context.mounted) {
                _message(context, context.tr("E-posta adresi kopyalandı."));
              }
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: Text(context.tr("Adresi kopyala")),
          ),
        ],
      ),
    );
  }

  static void _message(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
