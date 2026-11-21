class PsnAuthService {
  static const String _expectedHost = 'remoteplay.dl.playstation.net';

  static const String _expectedPath = '/remoteplay/redirect';

  /// Checks the exact redirect origin/path and binds the code to this login's
  /// one-time OAuth state. Never log [input] or the returned code.
  static String? extractAuthorizationCode(
    String input, {
    required String expectedState,
  }) {
    final value = input.trim();

    if (value.isEmpty) {
      return null;
    }

    try {
      final uri = Uri.parse(value);

      if (uri.scheme != 'https' ||
          !uri.hasAuthority ||
          uri.userInfo.isNotEmpty ||
          uri.port != 443 ||
          uri.hasFragment) {
        return null;
      }

      if (uri.host.toLowerCase() != _expectedHost) {
        return null;
      }

      if (uri.path != _expectedPath) {
        return null;
      }

      final query = uri.queryParametersAll;
      final codes = query['code'];
      final states = query['state'];
      if (query.containsKey('error') ||
          codes == null ||
          codes.length != 1 ||
          states == null ||
          states.length != 1 ||
          states.single != expectedState) {
        return null;
      }

      final code = codes.single;
      if (code.isEmpty ||
          code.length > 4096 ||
          code.contains(RegExp(r'[\x00-\x1f\x7f]'))) {
        return null;
      }

      return code;
    } on FormatException {
      return null;
    }
  }
}
