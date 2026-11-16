import 'package:flutter_test/flutter_test.dart';
import 'package:gametranslate/services/app_links.dart';

void main() {
  test(
    'setup PDF uses the configured HTTPS site and preserves its directory',
    () {
      expect(
        AppLinks.setupGuidePdfUri(
          const AppInformation(
            privacyUrl: 'https://example.com/app/privacy.html?lang=en',
          ),
        ).toString(),
        'https://example.com/app/downloads/setup-guide-tr.pdf',
      );
      for (final url in [
        '',
        'http://example.com/privacy',
        'https://user:pass@example.com/privacy',
      ]) {
        expect(
          AppLinks.setupGuidePdfUri(AppInformation(privacyUrl: url)),
          isNull,
        );
      }
    },
  );
  test(
    'TV setup links reuse the configured site and preserve its base directory',
    () {
      final uri = AppLinks.tvSetupUri(
        const AppInformation(
          privacyUrl:
              'https://console-game-translator.pages.dev/privacy?lang=tr',
        ),
        'samsung',
        'tr',
      );
      expect(
        uri.toString(),
        'https://console-game-translator.pages.dev/tv-setup.html?brand=samsung&lang=tr',
      );
      expect(
        AppLinks.tvSetupUri(
          const AppInformation(
            privacyUrl: 'https://example.com/app/privacy.html',
          ),
          'lg',
          'de',
        ).toString(),
        'https://example.com/app/tv-setup.html?brand=lg&lang=en',
      );
    },
  );
  test(
    'missing, unsafe or unknown setup targets do not create broken download links',
    () {
      for (final address in [
        '',
        'http://example.com/privacy',
        'file:///privacy.html',
        'https://user:password@example.com/privacy',
      ]) {
        expect(
          AppLinks.tvSetupUri(AppInformation(privacyUrl: address), 'lg', 'tr'),
          isNull,
        );
      }
      expect(
        AppLinks.tvSetupUri(
          const AppInformation(privacyUrl: 'https://example.com/privacy'),
          'unknown',
          'tr',
        ),
        isNull,
      );
    },
  );
}
