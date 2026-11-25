import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'app_language.dart';
import 'messages_ar.dart';
import 'messages_en.dart';
import 'messages_th.dart';
import 'messages_hu.dart';

/// Source messages remain Turkish; only interface text is passed through here.
/// Game text, user-entered names, protocol values and saved settings stay intact.
class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;
  bool get isTurkish => locale.languageCode == 'tr';
  Map<String, String> get _messages => switch (locale.languageCode) {
    'ar' => arabicMessages,
    'th' => thaiMessages,
    'hu' => hungarianMessages,
    _ => englishMessages,
  };
  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ??
      AppLocalizations(Localizations.localeOf(context));

  String text(String source, [List<Object?> arguments = const []]) {
    final message = isTurkish ? source : _messages[source] ?? source;
    return message.replaceAllMapped(RegExp(r'\{(\d+)\}'), (match) {
      final index = int.parse(match[1]!);
      return index < arguments.length ? '${arguments[index]}' : match[0]!;
    });
  }

  /// Native callbacks and retained status fields carry source messages rather
  /// than translated strings. Resolve them when displayed so a language change
  /// also updates an existing connection, error or setup screen.
  String message(String source) {
    if (isTurkish || source.isEmpty) return source;
    final exact = _messages[source];
    if (exact != null) return exact;
    for (final template in _statusTemplates) {
      final match = template.pattern.firstMatch(source);
      if (match == null) continue;
      final arguments = [for (var i = 1; i <= match.groupCount; i++) match[i]];
      if (const {
        'PS5 kaydı başarılı.\n{0}',
        '{0}\nHata kodu: {1}',
        'Beklenmeyen hata: {0}',
      }.contains(template.source)) {
        arguments[0] = message(arguments[0]!);
      }
      return text(template.source, arguments);
    }
    // Platform errors sometimes append a code or an exception prefix.
    for (final prefix in const ['Bad state: ', 'FormatException: ']) {
      if (source.startsWith(prefix)) {
        return message(source.substring(prefix.length));
      }
    }
    for (final entry in _statusMessages) {
      if (source.startsWith('${entry.key} (')) {
        return '${text(entry.key)}${source.substring(entry.key.length)}';
      }
    }
    return source;
  }

  static final _statusMessages = englishMessages.entries.toList()
    ..sort((a, b) => b.key.length.compareTo(a.key.length));
  static final _statusTemplates = [
    for (final entry in _statusMessages)
      if (RegExp(r'\{\d+\}').hasMatch(entry.key))
        _MessageTemplate(
          entry.key,
          RegExp(
            '^${entry.key.split(RegExp(r'\{\d+\}')).map(RegExp.escape).join('(.*?)')}\$',
            dotAll: true,
          ),
        ),
  ];
}

class _MessageTemplate {
  const _MessageTemplate(this.source, this.pattern);
  final String source;
  final RegExp pattern;
}

extension AppLocalizationContext on BuildContext {
  String tr(String source, [List<Object?> arguments = const []]) =>
      AppLocalizations.of(this).text(source, arguments);

  String trMessage(String source) => AppLocalizations.of(this).message(source);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLanguage.supportedLocales.any(
    (supported) => supported.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
