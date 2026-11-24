import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

abstract final class AppLanguage {
  static const supportedLocales = [Locale('en'), Locale('tr'), Locale('ar')];

  static const preferences = ['system', 'tr', 'en', 'ar'];

  static String nativeName(String code) => switch (code) {
    'tr' => 'Türkçe',
    'ar' => 'العربية',
    'en' => 'English',
    _ => code,
  };

  static Locale localeFor(String preference, Locale systemLocale) =>
      preference == 'system'
      ? resolve(systemLocale)
      : resolve(Locale(preference));

  static Locale resolve(Locale? deviceLocale) =>
      Locale(switch (deviceLocale?.languageCode) {
        'tr' => 'tr',
        'ar' => 'ar',
        _ => 'en',
      });
}

class AppLanguagePreferences {
  const AppLanguagePreferences();

  static const _channel = MethodChannel(
    'com.abrebostudio.consolegametranslator/ps5_registration',
  );

  Future<String> load() async {
    try {
      final value = await _channel.invokeMethod<String>('getAppLanguage');
      return AppLanguage.preferences.contains(value) ? value! : 'system';
    } on PlatformException {
      return 'system';
    } on MissingPluginException {
      return 'system';
    }
  }

  Future<void> save(String preference) async {
    if (!AppLanguage.preferences.contains(preference)) {
      throw ArgumentError.value(preference, 'preference');
    }
    try {
      await _channel.invokeMethod<void>('setAppLanguage', preference);
    } on MissingPluginException {
      // Desktop previews can still change language for the current session.
    }
  }
}

/// Keeps system branding separate from the selected interface language.
class AppLanguageScope extends InheritedWidget {
  const AppLanguageScope({
    super.key,
    required this.systemLocale,
    this.preference = 'system',
    this.ready = true,
    this.changing = false,
    this.onChanged,
    required super.child,
  });

  final Locale systemLocale;
  final String preference;
  final bool ready;
  final bool changing;
  final Future<void> Function(String)? onChanged;

  Locale get interfaceLocale => AppLanguage.localeFor(preference, systemLocale);

  /// Keep unsupported system languages for the library's existing filtering.
  Locale get libraryLocale =>
      preference == 'system' ? systemLocale : interfaceLocale;

  static AppLanguageScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppLanguageScope>();

  @override
  bool updateShouldNotify(AppLanguageScope oldWidget) =>
      systemLocale != oldWidget.systemLocale ||
      preference != oldWidget.preference ||
      ready != oldWidget.ready ||
      changing != oldWidget.changing;
}
