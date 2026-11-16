import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';

import '../models/subtitle_settings.dart';
import 'lan_tv_address.dart';
import 'game_fonts.dart';
import 'subtitle_presentation.dart';

/// A session-scoped, explicitly unencrypted LAN channel for the Tizen receiver.
/// The PIN expires, only one receiver pairs, and reconnect needs a random token.
class SamsungTvSession {
  SamsungTvSession({DateTime Function()? now}) : _now = now ?? DateTime.now;
  final DateTime Function() _now;
  final _changes = StreamController<void>.broadcast();
  final _sockets = <WebSocket>{};
  HttpServer? _server;
  WebSocket? _receiver;
  String? _sentFont;
  String? _token;
  String? _code;
  DateTime? _pairingDeadline;
  int _failures = 0;
  bool _ready = false;
  Map<String, Object> _current = const {
    'type': 'clear',
    'text': '',
    'texts': <String>[],
  };
  Uint8List? _receiverArchive;
  List<String> addresses = const [];

  Stream<void> get changes => _changes.stream;
  bool get isRunning => _server != null;
  bool get isConnected => _receiver != null && _ready;
  bool get hasReceiver => _receiver != null;
  String? get pairingCode => _code;
  int get port => _server?.port ?? 0;
  List<String> get endpoints =>
      isRunning ? addresses.map((ip) => '$ip:$port').toList() : const [];

  Future<void> start({
    InternetAddress? bindAddress,
    List<String>? localAddresses,
    Uint8List? archive,
  }) async {
    await stop();
    addresses = localAddresses ?? await LanTvAddress.localAddresses();
    if (addresses.isEmpty) {
      throw const SocketException('Yerel Wi-Fi adresi bulunamadı.');
    }
    _receiverArchive =
        archive ??
        (await rootBundle.load(
          'assets/tv/samsung-receiver.zip',
        )).buffer.asUint8List();
    _code = Random.secure().nextInt(1000000).toString().padLeft(6, '0');
    _pairingDeadline = _now().add(const Duration(minutes: 2));
    _failures = 0;
    final server = await HttpServer.bind(
      bindAddress ?? InternetAddress.anyIPv4,
      0,
    );
    _server = server;
    server.listen(
      (request) => unawaited(_handle(request, server)),
      onError: (_) {},
    );
    _changes.add(null);
  }

  Future<void> _handle(HttpRequest request, HttpServer server) async {
    if (!identical(_server, server)) {
      await request.response.close();
      return;
    }
    final remote = request.connectionInfo?.remoteAddress;
    if (remote == null ||
        (!remote.isLoopback && !LanTvAddress.isPrivateIpv4(remote.address))) {
      request.response.statusCode = HttpStatus.forbidden;
      await request.response.close();
      return;
    }
    if (request.method == 'GET' &&
        request.uri.path == '/receiver.zip' &&
        _receiverArchive != null) {
      request.response.headers.contentType = ContentType('application', 'zip');
      request.response.headers.set(
        'Content-Disposition',
        'attachment; filename="samsung-receiver.zip"',
      );
      request.response.headers.set('Cache-Control', 'no-store');
      request.response.add(_receiverArchive!);
      await request.response.close();
      return;
    }
    if (request.uri.path != '/subtitles' ||
        !WebSocketTransformer.isUpgradeRequest(request) ||
        _sockets.length >= 4) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    try {
      final socket = await WebSocketTransformer.upgrade(request);
      if (!identical(_server, server)) {
        await socket.close();
        return;
      }
      _sockets.add(socket);
      socket.pingInterval = const Duration(seconds: 10);
      var authenticated = false;
      final timeout = Timer(const Duration(seconds: 10), () {
        if (!authenticated) {
          unawaited(socket.close(WebSocketStatus.policyViolation));
        }
      });
      final heartbeat = Timer.periodic(const Duration(seconds: 5), (_) {
        if (authenticated && _sockets.contains(socket)) {
          socket.add('{"type":"ping"}');
        }
      });
      socket.listen(
        (raw) {
          if (!_sockets.contains(socket)) return;
          try {
            if (raw is! String || raw.length > 4096) {
              throw const FormatException();
            }
            final message = jsonDecode(raw);
            if (message is! Map) throw const FormatException();
            if (!authenticated) {
              final pairing =
                  message['type'] == 'pair' &&
                  _token == null &&
                  _code != null &&
                  _failures < 5 &&
                  _now().isBefore(_pairingDeadline!) &&
                  message['code'] == _code;
              final resume =
                  message['type'] == 'resume' &&
                  _token != null &&
                  message['sessionToken'] == _token;
              if ((!pairing && !resume) || _receiver != null) {
                _failures++;
                unawaited(
                  socket.close(
                    WebSocketStatus.policyViolation,
                    'Pairing rejected',
                  ),
                );
                return;
              }
              authenticated = true;
              timeout.cancel();
              _receiver = socket;
              _sentFont = null;
              _ready = false;
              _token ??= base64UrlEncode(
                List<int>.generate(32, (_) => Random.secure().nextInt(256)),
              );
              _code = null; // A PIN cannot enroll a second receiver.
              socket.add(
                jsonEncode({'type': 'paired', 'sessionToken': _token}),
              );
              _changes.add(null);
            } else if (message['type'] == 'ready' &&
                message['hdmiVisible'] == true) {
              _ready =
                  true; // Sent only after the user's physical HDMI + subtitle check.
              _sendCurrent();
              _changes.add(null);
            } else if (message['type'] == 'notReady') {
              _ready = false;
              _current = {
                ..._current,
                'type': 'clear',
                'text': '',
                'texts': <String>[],
              };
              _changes.add(null);
            }
          } catch (_) {
            unawaited(
              socket.close(WebSocketStatus.policyViolation, 'Invalid message'),
            );
          }
        },
        onDone: () {
          timeout.cancel();
          heartbeat.cancel();
          _sockets.remove(socket);
          if (identical(_receiver, socket)) {
            _receiver = null;
            _ready = false;
            _current = const {'type': 'clear', 'text': '', 'texts': <String>[]};
            _changes.add(null);
          }
        },
        onError: (_) {
          unawaited(socket.close());
        },
      );
    } catch (_) {
      // A peer can disconnect while upgrading.
    }
  }

  void updateSubtitles(List<String> texts, SubtitleSettings settings) {
    if (!isConnected) texts = const [];
    final text = texts.where((t) => t.isNotEmpty).join('\n');
    _current = {
      'type': text.isEmpty ? 'clear' : 'subtitle',
      'text': text,
      'texts': texts,
      'presentation': presentation(settings),
    };
    if (isConnected) _sendCurrent();
  }

  void updateSettings(SubtitleSettings settings) {
    _current = {..._current, 'presentation': presentation(settings)};
    if (isConnected) {
      _sendCurrent(type: 'presentation');
    }
  }

  void _sendCurrent({String? type}) {
    final socket = _receiver;
    if (socket == null) return;
    final font = GameFonts.active.value;
    final presentation = _current['presentation'];
    if (font != null &&
        presentation is Map &&
        subtitlePresentationUsesFont(presentation, font.sha256) &&
        _sentFont != font.sha256) {
      socket.add(jsonEncode(font.packet));
      _sentFont = font.sha256;
    }
    socket.add(jsonEncode({..._current, 'type': ?type}));
  }

  static Map<String, Object> presentation(SubtitleSettings settings) =>
      subtitlePresentation(settings);

  Future<void> stop() async {
    final server = _server;
    _server = null;
    _code = null;
    _token = null;
    _receiver = null;
    _ready = false;
    addresses = const [];
    _receiverArchive = null;
    _current = const {'type': 'clear', 'text': '', 'texts': <String>[]};
    for (final socket in _sockets.toList()) {
      await socket.close(WebSocketStatus.goingAway, 'Session ended');
    }
    _sockets.clear();
    await server?.close(force: true);
    _changes.add(null);
  }
}
