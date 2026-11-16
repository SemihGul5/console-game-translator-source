import 'dart:io';

import 'package:crypto/crypto.dart';

/// The TV's self-signed identity is trusted only after an on-screen comparison.
/// No credentials or HTTP data are sent by the certificate probe.
abstract final class TvSecureTransport {
  static String fingerprint(X509Certificate certificate) =>
      sha256.convert(certificate.der).toString();

  static bool isFingerprint(String? value) =>
      value != null && RegExp(r'^[a-f0-9]{64}$').hasMatch(value);

  static String verificationCode(String fingerprint) => List.generate(
    4,
    (index) => fingerprint.substring(index * 4, index * 4 + 4).toUpperCase(),
  ).join(' ');

  static Future<String> inspect(String host, int port) async {
    String? observed;
    try {
      final socket = await SecureSocket.connect(
        host,
        port,
        context: SecurityContext(withTrustedRoots: false),
        timeout: const Duration(seconds: 8),
        onBadCertificate: (certificate) {
          observed = fingerprint(certificate);
          return false;
        },
      );
      socket.destroy();
    } on HandshakeException {
      // Expected: the probe records the identity and rejects the connection.
    }
    if (observed == null) {
      throw const HandshakeException('TV sertifikası doğrulanamadı.');
    }
    return observed!;
  }

  static HttpClient pinnedClient(String fingerprint) {
    if (!isFingerprint(fingerprint)) {
      throw const FormatException('TV sertifika kaydı geçersiz.');
    }
    return HttpClient(context: SecurityContext(withTrustedRoots: false))
      ..connectionTimeout = const Duration(seconds: 8)
      ..badCertificateCallback = (certificate, host, port) =>
          TvSecureTransport.fingerprint(certificate) == fingerprint;
  }
}
