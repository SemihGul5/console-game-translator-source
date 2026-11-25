import 'package:flutter/widgets.dart';

import 'l10n/app_language.dart';

class AppBranding {
  static const englishName = 'Console Game Translator';
  static const turkishName = 'Oyun Çevirmeni';
  static const arabicName = 'مترجم ألعاب الكونسول';
  static const thaiName = 'ตัวแปลเกมคอนโซล';
  static const hungarianName = 'Konzoljáték-fordító';
  static const internationalIcon = 'assets/branding/app_icon_all.png';
  static const turkishIcon = 'assets/branding/app_icon_tr.png';

  static String iconOf(BuildContext context) =>
      _deviceLocale(context).languageCode == 'tr'
      ? turkishIcon
      : internationalIcon;

  static String nameOf(BuildContext context) =>
      switch (_deviceLocale(context).languageCode) {
        'tr' => turkishName,
        'ar' => arabicName,
        'th' => thaiName,
        'hu' => hungarianName,
        _ => englishName,
      };

  static Locale resolveLocale(
    Locale? locale,
    Iterable<Locale> supportedLocales,
  ) => AppLanguage.resolve(locale);

  static Locale _deviceLocale(BuildContext context) =>
      AppLanguageScope.maybeOf(context)?.systemLocale ??
      Localizations.localeOf(context);
}
