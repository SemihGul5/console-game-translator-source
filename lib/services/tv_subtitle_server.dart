import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../models/subtitle_settings.dart';
import 'game_fonts.dart';
import 'subtitle_presentation.dart';

/// A short-lived LAN-only channel. It sends translated text and visual settings,
/// never PSN credentials, video frames, or account identifiers.
class TvSubtitleServer {
  HttpServer? _server;
  StreamSubscription<WebSocket>? _connections;
  final Set<WebSocket> _pairedClients = <WebSocket>{};
  final _sentFonts = <WebSocket, String>{};
  String? _pairingCode;
  String _subtitle = '';
  Map<String, Object> _presentation = const {};

  bool get isRunning => _server != null;
  String? get pairingCode => _pairingCode;
  int get port => _server?.port ?? 0;

  Future<String?> start(SubtitleSettings settings) async {
    if (_server != null) return await localIpv4Address();
    _presentation = _presentationFrom(settings);
    _pairingCode = Random.secure().nextInt(1000000).toString().padLeft(6, '0');
    final server = await HttpServer.bind(
      InternetAddress.anyIPv4,
      0,
      shared: true,
    );
    _server = server;
    _connections = server
        .transform(WebSocketTransformer())
        .listen(_handleConnection);
    return await localIpv4Address();
  }

  Future<void> stop() async {
    _pairingCode = null;
    for (final client in _pairedClients.toList()) {
      await client.close(WebSocketStatus.goingAway, 'Pairing stopped');
    }
    _pairedClients.clear();
    _sentFonts.clear();
    await _connections?.cancel();
    _connections = null;
    await _server?.close(force: true);
    _server = null;
  }

  void updateSubtitle(String text, SubtitleSettings settings) {
    _subtitle = text;
    _presentation = _presentationFrom(settings);
    _send(<String, Object>{
      'type': text.isEmpty ? 'clear' : 'subtitle',
      'text': text,
      'presentation': _presentation,
    });
  }

  void updateSettings(SubtitleSettings settings) {
    _presentation = _presentationFrom(settings);
    _send(<String, Object>{
      'type': 'presentation',
      'presentation': _presentation,
    });
  }

  Future<String?> localIpv4Address() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        if (!address.isLoopback && address.address != '0.0.0.0') {
          return address.address;
        }
      }
    }
    return null;
  }

  Future<void> _handleConnection(WebSocket socket) async {
    var paired = false;
    late final StreamSubscription<dynamic> subscription;
    subscription = socket.listen(
      (message) {
        if (paired) return;
        try {
          final payload = jsonDecode(message.toString());
          if (payload is Map &&
              payload['type'] == 'pair' &&
              payload['code'] == _pairingCode &&
              _pairingCode != null) {
            paired = true;
            _pairedClients.add(socket);
            socket.add(
              jsonEncode(<String, Object>{
                'type': 'paired',
                'text': _subtitle,
                'presentation': _presentation,
              }),
            );
            _sendFont(socket);
          } else {
            socket.close(WebSocketStatus.policyViolation, 'Pairing rejected');
          }
        } on FormatException {
          socket.close(WebSocketStatus.policyViolation, 'Invalid pairing data');
        }
      },
      onDone: () {
        _pairedClients.remove(socket);
        _sentFonts.remove(socket);
        subscription.cancel();
      },
      onError: (_) {
        _pairedClients.remove(socket);
        socket.close(WebSocketStatus.internalServerError);
      },
    );
    Future<void>.delayed(const Duration(seconds: 15), () {
      if (!paired) {
        socket.close(WebSocketStatus.policyViolation, 'Pairing timed out');
      }
    });
  }

  void _send(Map<String, Object> message) {
    final encoded = jsonEncode(message);
    for (final client in _pairedClients.toList()) {
      try {
        _sendFont(client);
        client.add(encoded);
      } on WebSocketException {
        _pairedClients.remove(client);
      }
    }
  }

  void _sendFont(WebSocket socket) {
    final font = GameFonts.active.value;
    if (font != null &&
        subtitlePresentationUsesFont(_presentation, font.sha256) &&
        _sentFonts[socket] != font.sha256) {
      socket.add(jsonEncode(font.packet));
      _sentFonts[socket] = font.sha256;
    }
  }

  Map<String, Object> _presentationFrom(SubtitleSettings settings) =>
      subtitlePresentation(settings);
}
