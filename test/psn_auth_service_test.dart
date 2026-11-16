import 'package:flutter_test/flutter_test.dart';
import 'package:gametranslate/services/psn_auth_service.dart';

void main() {
  const redirect = 'https://remoteplay.dl.playstation.net/remoteplay/redirect';
  const state = 'this-login-only';

  test('preserves the exact code for the current OAuth login', () {
    expect(
      PsnAuthService.extractAuthorizationCode(
        '$redirect?code=one%2Buse%2Fcode&state=$state',
        expectedState: state,
      ),
      'one+use/code',
    );
  });

  for (final url in [
    '$redirect?code=valid&state=another-login',
    '$redirect?code=valid',
    '$redirect?code=valid&state=$state&state=$state',
    '$redirect?code=first&code=second&state=$state',
    '$redirect?code=valid&state=$state&error=access_denied',
    '$redirect?code=&state=$state',
    '$redirect?code=bad%0Acode&state=$state',
    '$redirect?code=valid&state=$state#fragment',
    'http://remoteplay.dl.playstation.net/remoteplay/redirect?code=valid&state=$state',
    'https://attacker.example/remoteplay/redirect?code=valid&state=$state',
    'https://user@remoteplay.dl.playstation.net/remoteplay/redirect?code=valid&state=$state',
    'https://remoteplay.dl.playstation.net:444/remoteplay/redirect?code=valid&state=$state',
    '$redirect/extra?code=valid&state=$state',
  ]) {
    test('rejects an untrusted or mismatched OAuth redirect: $url', () {
      expect(
        PsnAuthService.extractAuthorizationCode(url, expectedState: state),
        isNull,
      );
    });
  }
}
