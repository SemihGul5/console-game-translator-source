import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

enum AppLanguage {
  system,
  turkish,
  english;

  String get code => switch (this) {
    system => 'system',
    turkish => 'tr',
    english => 'en',
  };

  Locale? get locale => this == system ? null : Locale(code);

  static AppLanguage fromCode(String? code) => switch (code) {
    'tr' => turkish,
    'en' => english,
    _ => system,
  };

  static Locale resolve(Locale? deviceLocale) =>
      Locale(deviceLocale?.languageCode == 'tr' ? 'tr' : 'en');
}

class AppLanguageController extends ChangeNotifier {
  static const channel = MethodChannel(
    'com.abrebostudio.consolegametranslator/ps5_registration',
  );

  AppLanguage _language = AppLanguage.system;
  bool _disposed = false;
  AppLanguage get language => _language;

  Future<void> load() async {
    try {
      final saved = await channel.invokeMethod<String>('getAppLanguage');
      if (_disposed) return;
      _language = AppLanguage.fromCode(saved);
      notifyListeners();
    } on PlatformException {
      // Use the device language if preferences aren't available.
    } on MissingPluginException {
      // Desktop previews and older native builds use the device language.
    }
  }

  Future<void> select(AppLanguage language) async {
    if (_language == language) return;
    final saved = await channel.invokeMethod<bool>(
      'setAppLanguage',
      language.code,
    );
    if (saved != true) throw StateError('Language preference was not saved');
    if (_disposed) return;
    _language = language;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class AppLanguageScope extends InheritedNotifier<AppLanguageController> {
  const AppLanguageScope({
    super.key,
    required AppLanguageController controller,
    required this.systemLocale,
    required super.child,
  }) : super(notifier: controller);

  final Locale systemLocale;

  static AppLanguageScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppLanguageScope>();

  static AppLanguageController of(BuildContext context) =>
      maybeOf(context)!.notifier!;

  @override
  bool updateShouldNotify(AppLanguageScope oldWidget) =>
      systemLocale != oldWidget.systemLocale ||
      super.updateShouldNotify(oldWidget);
}
