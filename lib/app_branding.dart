import 'package:flutter/widgets.dart';

import 'l10n/app_language.dart';

class AppBranding {
  static const englishName = 'Console Game Translator';
  static const turkishName = 'OyunÇevirmeni';
  static const internationalIcon = 'assets/branding/app_icon_all.png';
  static const turkishIcon = 'assets/branding/app_icon_tr.png';

  static String iconOf(BuildContext context) =>
      _deviceLocale(context).languageCode == 'tr'
      ? turkishIcon
      : internationalIcon;

  static String nameOf(BuildContext context) =>
      _deviceLocale(context).languageCode == 'tr' ? turkishName : englishName;

  static Locale resolveLocale(
    Locale? locale,
    Iterable<Locale> supportedLocales,
  ) => AppLanguage.resolve(locale);

  static Locale _deviceLocale(BuildContext context) =>
      AppLanguageScope.maybeOf(context)?.systemLocale ??
      Localizations.localeOf(context);
}
