import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'lan_tv_address.dart';
import 'lg_connect_manifest.dart';
import 'tv_secure_transport.dart';

/// A registration the TV refused or never completed. [beforePrompt] means the
/// TV did not show its permission prompt (manifest refused, no reply or the
/// connection dropped), so another manifest may still work.
class LgPairingError extends StateError {
  LgPairingError(this.reason, {required this.beforePrompt, this.detail})
    : super('LG pairing failed: $reason');
  final String reason;
  final bool beforePrompt;
  final String? detail;
}

/// LG's paired second-screen notification API. No capture or remote keys.
/// Toast position, duration and typography belong to the TV's firmware.
class LgWebOsClient {
  LgWebOsClient();
  @visibleForTesting
  LgWebOsClient.forTesting({
    required this.openSocket,
    this.toastInterval = const Duration(milliseconds: 20),
    this.requestTimeout = const Duration(milliseconds: 300),
    this.replyTimeout = const Duration(milliseconds: 300),
    this.pairingTimeout = const Duration(milliseconds: 600),
    this.probePort,
  });

  Future<WebSocket> Function(Uri uri, String? fingerprint)? openSocket;
  Future<bool> Function(String host, int port)? probePort;
  /// First reply to a registration (prompt, key or error).
  Duration replyTimeout = const Duration(seconds: 10);
  /// Time the user has to answer the TV's permission prompt.
  Duration pairingTimeout = const Duration(seconds: 60);
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
  bool _promptShown = false;
  Completer<void>? _promptSeen;
  /// Set once the TV accepted the signed manifest; reconnects use it directly.
  bool _signedManifest = false;
  String? _pending;
  String? _lastText;
  String? _sendingText;
  DateTime? _lastSent;
  String? host;
  String? clientKey;
  String? certificateFingerprint;
  bool secure = true;
  String? lastError;
  /// Short technical tag of the failing step, e.g. `3001 tls`. Shown next to
  /// the message so support screenshots identify the cause.
  String? lastErrorCode;

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
    lastErrorCode = null;
    _changes.add(null);
    final port = secure ? 3001 : 3000;
    var step = 'tls';
    WebSocket? socket;
    try {
      // Trust on first use, followed by the TV's physical pairing prompt.
      // Subsequent connections pin the complete certificate; no TLS downgrade.
      if (secure && certificateFingerprint == null) {
        certificateFingerprint = await TvSecureTransport.inspect(host!, port);
      }
      if (_closed || generation != _generation) throw StateError('Cancelled');
      final uri = Uri(scheme: secure ? 'wss' : 'ws', host: host, port: port);
      // Unsigned first; firmware that refuses it before prompting gets the
      // signed manifest on a fresh socket.
      final variants = _signedManifest ? const [true] : const [false, true];
      for (var i = 0; i < variants.length; i++) {
        step = 'ws';
        socket = await _open(uri);
        if (_closed || generation != _generation) {
          throw StateError('Cancelled');
        }
        step = 'pair';
        try {
          await _register(socket, signed: variants[i]);
          _signedManifest = variants[i];
          break;
        } on LgPairingError catch (error) {
          if (!error.beforePrompt || i == variants.length - 1) rethrow;
          if (_closed || generation != _generation) rethrow;
          final rejected = socket;
          if (identical(_socket, rejected)) _socket = null;
          socket = null;
          await rejected.close();
        }
      }
      if (_closed || generation != _generation) throw StateError('Cancelled');
      _retries = 0;
    } catch (error) {
      if (generation == _generation) {
        if (identical(_socket, socket)) _socket = null;
        _registration = null;
        _promptSeen = null;
        _paired = false;
        await _describeFailure(error, step, port);
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

  Future<WebSocket> _open(Uri uri) async {
    if (openSocket != null) return openSocket!(uri, certificateFingerprint);
    final http = secure
        ? TvSecureTransport.pinnedClient(certificateFingerprint!)
        : null;
    try {
      return await WebSocket.connect(
        uri.toString(),
        customClient: http,
        // Some webOS builds drop connections that negotiate permessage-deflate.
        compression: CompressionOptions.compressionOff,
      ).timeout(const Duration(seconds: 8));
    } finally {
      http?.close();
    }
  }

  Future<void> _register(WebSocket socket, {required bool signed}) async {
    _socket = socket;
    socket.pingInterval = const Duration(seconds: 15);
    final registration = Completer<void>();
    final prompt = Completer<void>();
    _registration = registration;
    _promptSeen = prompt;
    _promptShown = false;
    socket.listen(
      _receive,
      onDone: () => _ended(socket),
      onError: (_) => _ended(socket),
      cancelOnError: true,
    );
    socket.add(
      jsonEncode({
        'id': 'register',
        'type': 'register',
        'payload': {
          'pairingType': 'PROMPT',
          'forcePairing': false,
          if (clientKey != null) 'client-key': clientKey,
          'manifest': signed
              ? LgConnectManifest.signed()
              : LgConnectManifest.unsigned(),
        },
      }),
    );
    try {
      await Future.any([registration.future, prompt.future]).timeout(
        replyTimeout,
      );
    } on TimeoutException {
      throw LgPairingError('no-reply', beforePrompt: true);
    }
    if (registration.isCompleted && !_promptShown) {
      return registration.future;
    }
    try {
      await registration.future.timeout(pairingTimeout);
    } on TimeoutException {
      throw LgPairingError('prompt-timeout', beforePrompt: false);
    }
  }

  Future<bool> _isOpen(String host, int port) async {
    if (probePort != null) return probePort!(host, port);
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 2),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _describeFailure(Object error, String step, int port) async {
    if (error is StateError && error.message == 'Cancelled') return;
    final other = port == 3001 ? 3000 : 3001;
    if (error is LgPairingError) {
      switch (error.reason) {
        case 'denied':
          lastError =
              'TV bağlantı isteğini reddetti. Testi yeniden çalıştır ve TV’de izin ver.';
        case 'prompt-timeout':
          lastError =
              'TV’deki izin isteği zamanında onaylanmadı. Testi yeniden çalıştır ve kumandayla izin ver.';
        default:
          lastError =
              'TV eşleştirme isteğini kabul etmedi. TV ayarlarında mobil cihaz bağlantısı (LG Connect Apps / Mobile TV On) iznini açıp TV’yi yeniden başlat.';
      }
      final detail = error.detail;
      lastErrorCode = '$port ${error.reason}'
          '${detail == null ? '' : ': ${detail.length > 40 ? detail.substring(0, 40) : detail}'}';
      return;
    }
    final network =
        error is SocketException ||
        error is TimeoutException ||
        (error is HandshakeException && step == 'tls');
    if (network && !(await _isOpen(host!, port))) {
      if (await _isOpen(host!, other)) {
        lastError = port == 3001
            ? 'TV şifreli bağlantıya yanıt vermiyor. “Şifreli bağlantı” seçeneğini kapatıp yeniden dene.'
            : 'TV şifresiz bağlantıya yanıt vermiyor. “Şifreli bağlantı” seçeneğini açıp yeniden dene.';
        lastErrorCode = '$port kapalı, $other açık';
      } else {
        lastError =
            'TV bu IP adresinde bulunamadı. TV’nin açık olduğunu, IP adresini ve telefonla aynı Wi-Fi ağında olduğunu kontrol et.';
        lastErrorCode = '3000/3001 yanıt yok';
      }
      return;
    }
    if (error is HandshakeException || error is TlsException) {
      lastError = step == 'tls'
          ? 'TV ile şifreli bağlantı kurulamadı. “Şifreli bağlantı” seçeneğini kapatıp yeniden dene.'
          : 'TV’nin güvenlik sertifikası değişmiş. TV bağlantısını kaldırıp yeniden eşleştir.';
      lastErrorCode = '$port tls';
      return;
    }
    if (error is SocketException || error is TimeoutException) {
      lastError =
          'TV bağlantıyı kabul etmedi. TV’yi yeniden başlatıp diğer bağlantı türünü dene.';
      lastErrorCode = '$port $step ${error is TimeoutException ? 'zaman aşımı' : 'kesildi'}';
      return;
    }
    if (error is WebSocketException || error is HttpException) {
      lastError =
          'TV bağlantıyı kabul etmedi. TV’yi yeniden başlatıp diğer bağlantı türünü dene.';
      lastErrorCode = '$port ws';
      return;
    }
    lastError =
        'LG bağlantısı kurulamadı. IP adresini, TV iznini ve bağlantı türünü kontrol et.';
    lastErrorCode = '$port $step ${error.runtimeType}';
  }

  void _receive(dynamic raw) {
    if (raw is! String || raw.length > 65536) return;
    try {
      final value = jsonDecode(raw);
      if (value is! Map) return;
      final payload = value['payload'];
      if (value['type'] == 'response' &&
          value['id'] == 'register' &&
          payload is Map &&
          payload['pairingType'] == 'PROMPT') {
        _promptShown = true;
        final prompt = _promptSeen;
        _promptSeen = null;
        if (prompt != null && !prompt.isCompleted) prompt.complete();
      } else if (value['type'] == 'registered' && _registration != null) {
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
          final message = value['error'];
          _registration!.completeError(
            LgPairingError(
              _promptShown ? 'denied' : 'rejected',
              beforePrompt: !_promptShown,
              detail: message is String ? message : null,
            ),
          );
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
      registration.completeError(
        LgPairingError('closed', beforePrompt: !_promptShown),
      );
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
