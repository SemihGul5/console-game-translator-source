import 'package:flutter/widgets.dart';

abstract final class AppLanguage {
  static Locale resolve(Locale? deviceLocale) =>
      Locale(deviceLocale?.languageCode == 'tr' ? 'tr' : 'en');
}

/// Keeps the device locale available when the interface falls back to English.
class AppLanguageScope extends InheritedWidget {
  const AppLanguageScope({
    super.key,
    required this.systemLocale,
    required super.child,
  });

  final Locale systemLocale;

  static AppLanguageScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppLanguageScope>();

  @override
  bool updateShouldNotify(AppLanguageScope oldWidget) =>
      systemLocale != oldWidget.systemLocale;
}
