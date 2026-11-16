import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'lan_tv_address.dart';
import 'tv_secure_transport.dart';

/// LG's paired second-screen notification API. No capture or remote keys.
/// Toast position, duration and typography belong to the TV's firmware.
class LgWebOsClient {
  LgWebOsClient();
  @visibleForTesting
  LgWebOsClient.forTesting({
    required this.openSocket,
    this.toastInterval = const Duration(milliseconds: 20),
    this.requestTimeout = const Duration(milliseconds: 300),
  });

  Future<WebSocket> Function(Uri uri, String? fingerprint)? openSocket;
  Duration toastInterval = const Duration(milliseconds: 1500);
  Duration requestTimeout = const Duration(seconds: 8);
  final _changes = StreamController<void>.broadcast();
  final _requests = <String, Completer<Map>>{};
  WebSocket? _socket;
  Completer<void>? _registration;
  Timer? _flushTimer;
  Timer? _retryTimer;
  int _generation = 0;
  int _contentGeneration = 0;
  int _sequence = 0;
  int _retries = 0;
  bool _paired = false;
  bool _connecting = false;
  bool _closed = true;
  bool _sending = false;
  String? _pending;
  String? _lastText;
  String? _sendingText;
  DateTime? _lastSent;
  String? host;
  String? clientKey;
  String? certificateFingerprint;
  bool secure = true;
  String? lastError;

  bool get isConnected => _paired && _socket != null;
  bool get isConnecting => _connecting || _retryTimer != null;
  Stream<void> get changes => _changes.stream;

  Future<void> connect(
    String ip, {
    bool encrypted = true,
    String? savedKey,
    String? fingerprint,
  }) async {
    if (!LanTvAddress.isPrivateIpv4(ip)) {
      throw const FormatException('Yerel IPv4 adresi gerekli.');
    }
    if (fingerprint != null &&
        (!encrypted || !TvSecureTransport.isFingerprint(fingerprint))) {
      throw const FormatException('TV sertifika kaydı geçersiz.');
    }
    await disconnect();
    host = ip;
    secure = encrypted;
    clientKey = savedKey;
    certificateFingerprint = fingerprint;
    _closed = false;
    await _connect(_generation);
  }

  Future<void> retry() async {
    if (host == null || isConnected || _connecting) return;
    _closed = false;
    _retryTimer?.cancel();
    _retryTimer = null;
    await _connect(_generation);
  }

  Future<void> _connect(int generation) async {
    _connecting = true;
    lastError = null;
    _changes.add(null);
    WebSocket? socket;
    try {
      final port = secure ? 3001 : 3000;
      // Trust on first use, followed by the TV's physical pairing prompt.
      // Subsequent connections pin the complete certificate; no TLS downgrade.
      if (secure && certificateFingerprint == null) {
        certificateFingerprint = await TvSecureTransport.inspect(host!, port);
      }
      if (_closed || generation != _generation) throw StateError('Cancelled');
      final uri = Uri(scheme: secure ? 'wss' : 'ws', host: host, port: port);
      if (openSocket != null) {
        socket = await openSocket!(uri, certificateFingerprint);
      } else {
        final http = secure
            ? TvSecureTransport.pinnedClient(certificateFingerprint!)
            : null;
        try {
          socket = await WebSocket.connect(
            uri.toString(),
            customClient: http,
          ).timeout(const Duration(seconds: 8));
        } finally {
          http?.close();
        }
      }
      if (_closed || generation != _generation) throw StateError('Cancelled');
      _socket = socket;
      socket.pingInterval = const Duration(seconds: 15);
      final registration = Completer<void>();
      _registration = registration;
      socket.listen(
        _receive,
        onDone: () => _ended(socket!),
        onError: (_) => _ended(socket!),
        cancelOnError: true,
      );
      socket.add(
        jsonEncode({
          'id': 'register',
          'type': 'register',
          'payload': {
            'pairingType': 'PROMPT', 'forcePairing': false,
            if (clientKey != null) 'client-key': clientKey,
            // No borrowed signed manifest or unrelated remote-control privileges.
            'manifest': {
              'manifestVersion': 1,
              'permissions': ['WRITE_NOTIFICATION_TOAST'],
            },
          },
        }),
      );
      await registration.future.timeout(const Duration(seconds: 45));
      if (_closed || generation != _generation) throw StateError('Cancelled');
      _retries = 0;
    } catch (error) {
      if (generation == _generation) {
        if (identical(_socket, socket)) _socket = null;
        _registration = null;
        _paired = false;
        lastError =
            'LG bağlantısı kurulamadı. IP adresini, TV iznini ve bağlantı türünü kontrol et.';
      }
      await socket?.close();
      rethrow;
    } finally {
      if (generation == _generation) {
        _connecting = false;
        if (!_closed && !isConnected) _scheduleReconnect();
        _changes.add(null);
      }
    }
  }

  void _receive(dynamic raw) {
    if (raw is! String || raw.length > 65536) return;
    try {
      final value = jsonDecode(raw);
      if (value is! Map) return;
      final payload = value['payload'];
      if (value['type'] == 'registered' && _registration != null) {
        final key = payload is Map ? payload['client-key'] : null;
        if (key is! String || key.isEmpty || key.length > 512) {
          _registration!.completeError(const FormatException('Invalid LG key'));
        } else {
          clientKey = key;
          _paired = true;
          _registration!.complete();
        }
        _registration = null;
        _changes.add(null);
      } else if (value['type'] == 'error') {
        final request = _requests.remove(value['id']);
        if (request != null) {
          request.completeError(StateError('LG request rejected'));
        }
        if (_registration != null) {
          _registration!.completeError(StateError('LG permission rejected'));
          _registration = null;
        }
      } else if (value['type'] == 'response') {
        final request = _requests.remove(value['id']);
        if (request != null) {
          if (payload is Map && payload['returnValue'] == true) {
            request.complete(payload);
          } else {
            request.completeError(StateError('LG notification rejected'));
          }
        }
      }
    } on FormatException {
      // Unrelated/malformed messages must not advance pairing.
    }
  }

  Future<void> testNotification(String text) => _toast(text);

  Future<void> _toast(String text) async {
    if (!isConnected) throw StateError('LG disconnected');
    final id = 'toast_${++_sequence}';
    final response = Completer<Map>();
    _requests[id] = response;
    _socket!.add(
      jsonEncode({
        'id': id,
        'type': 'request',
        'uri': 'ssap://system.notifications/createToast',
        'payload': {'message': text},
      }),
    );
    try {
      await response.future.timeout(requestTimeout);
    } finally {
      _requests.remove(id);
    }
  }

  void updateSubtitles(List<String> texts) {
    final text = texts.where((t) => t.isNotEmpty).join('\n');
    if (text.isEmpty) {
      _contentGeneration++;
      _sendingText = null;
      _pending = null;
      _lastText = null;
      _flushTimer?.cancel();
      _flushTimer = null;
      return; // The stock TV cannot reliably dismiss an existing toast.
    }
    if (text == _lastText || text == _pending || text == _sendingText) return;
    _pending = text;
    _scheduleFlush();
  }

  void _scheduleFlush() {
    if (_sending || _flushTimer != null || _pending == null || !isConnected) {
      return;
    }
    final elapsed = _lastSent == null
        ? toastInterval
        : DateTime.now().difference(_lastSent!);
    final delay = elapsed >= toastInterval
        ? Duration.zero
        : toastInterval - elapsed;
    _flushTimer = Timer(delay, () async {
      _flushTimer = null;
      final text = _pending;
      _pending = null;
      if (text == null || !isConnected) return;
      final generation = _generation;
      final contentGeneration = _contentGeneration;
      _sending = true;
      _sendingText = text;
      try {
        // Bound the notification size while preserving Unicode code points.
        await _toast(String.fromCharCodes(text.runes.take(1500)));
        if (generation == _generation &&
            contentGeneration == _contentGeneration) {
          _lastText = text;
          _lastSent = DateTime.now();
        }
      } catch (_) {
        if (generation != _generation) return;
        lastError =
            'LG bildirimi gösterilemedi. TV bağlantısını yeniden test et.';
        final socket = _socket;
        if (socket != null) {
          _ended(socket);
          unawaited(socket.close());
        }
      } finally {
        if (generation == _generation) {
          _sending = false;
          _sendingText = null;
          _scheduleFlush();
        }
      }
    });
  }

  void _ended(WebSocket socket) {
    if (!identical(socket, _socket)) return;
    _socket = null;
    _paired = false;
    _pending = null;
    _lastText = null;
    _flushTimer?.cancel();
    _flushTimer = null;
    final registration = _registration;
    _registration = null;
    if (registration != null && !registration.isCompleted) {
      registration.completeError(StateError('LG disconnected'));
    }
    for (final request in _requests.values) {
      if (!request.isCompleted) {
        request.completeError(StateError('LG disconnected'));
      }
    }
    _requests.clear();
    _scheduleReconnect();
    _changes.add(null);
  }

  void _scheduleReconnect() {
    if (!_closed && clientKey != null && !_connecting && _retryTimer == null) {
      final generation = _generation;
      _retryTimer = Timer(
        Duration(seconds: (++_retries * 2).clamp(2, 30)),
        () async {
          _retryTimer = null;
          try {
            await _connect(generation);
          } catch (_) {
            /* User can retry. */
          }
        },
      );
    }
  }

  Future<void> disconnect() async {
    _closed = true;
    _generation++;
    _contentGeneration++;
    _sending = false;
    _sendingText = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    _flushTimer?.cancel();
    _flushTimer = null;
    _pending = null;
    _lastText = null;
    _lastSent = null;
    final socket = _socket;
    if (socket != null) _ended(socket);
    _connecting = false;
    await socket?.close();
    _changes.add(null);
  }
}
