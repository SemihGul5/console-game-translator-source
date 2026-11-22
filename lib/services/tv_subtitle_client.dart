import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import '../models/subtitle_settings.dart';
import 'game_fonts.dart';
import 'subtitle_presentation.dart';
import 'tv_secure_transport.dart';

enum TvSubtitleConnectionState { disconnected, connecting, connected }

/// Mobile-side LAN client for the TV receiver. It only sends translated text
/// and presentation settings, never PSN credentials or video frames.
class TvSubtitleClient {
  static const int discoveryPort = 43821;
  static const int _maxReconnectDelaySeconds = 30;
  static const MethodChannel _pairingChannel = MethodChannel(
    'com.abrebostudio.consolegametranslator/ps5_registration',
  );
  TvSubtitleClient._();
  @visibleForTesting
  factory TvSubtitleClient.forTesting() => TvSubtitleClient._();

  static final TvSubtitleClient instance = TvSubtitleClient._();

  WebSocket? _socket;
  StreamSubscription<dynamic>? _subscription;
  Completer<void>? _pairCompleter;
  String? _address;
  String? _code;
  String? _sessionToken;
  String? _certificateFingerprint;
  String _subtitle = '';
  List<String> _subtitles = const [];
  Map<String, Object> _presentation = const {};
  List<Map<String, Object>> _covers = const [];
  List<Map<String, Object>> _rich = const [];
  bool _coverMode = false;
  double? _tvDisplayHeightDp;
  bool _manuallyDisconnected = false;
  bool _hasPaired = false;
  bool _socketPaired = false;
  bool _reconnectExhausted = false;
  bool _restoreCancelled = false;
  int _reconnectGeneration = 0;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _connecting = false;
  final StreamController<bool> _statusController =
      StreamController<bool>.broadcast();
  final StreamController<TvSubtitleConnectionState> _connectionStateController =
      StreamController<TvSubtitleConnectionState>.broadcast();
  TvSubtitleConnectionState? _lastReportedConnectionState;
  bool? _lastReportedConnected;

  bool get isConnected => _socketPaired && _socket != null;
  bool get isConnecting => _connecting || _reconnectTimer != null;
  TvSubtitleConnectionState get connectionState => isConnected
      ? TvSubtitleConnectionState.connected
      : isConnecting
      ? TvSubtitleConnectionState.connecting
      : TvSubtitleConnectionState.disconnected;
  String? get address => _address;
  String? get sessionToken => _sessionToken;
  String? get certificateFingerprint => _certificateFingerprint;
  bool get usesSecureTransport => _address?.startsWith('wss://') == true;
  double? get tvDisplayHeightDp => _tvDisplayHeightDp;
  Stream<bool> get statusChanges => _statusController.stream;
  Stream<TvSubtitleConnectionState> get connectionStateChanges =>
      _connectionStateController.stream;

  Future<void> restorePairing(
    String address,
    String sessionToken, {
    String? certificateFingerprint,
  }) async {
    if (_restoreCancelled) return;
    final endpoint = _parseAddress(address);
    if (endpoint == null ||
        !RegExp(r'^[A-Za-z0-9_-]{40,64}$').hasMatch(sessionToken) ||
        (endpoint.secure &&
            !TvSecureTransport.isFingerprint(certificateFingerprint)) ||
        (!endpoint.secure && certificateFingerprint != null)) {
      return;
    }
    final normalizedAddress = endpoint.address;
    if (_address == normalizedAddress &&
        _sessionToken == sessionToken &&
        _certificateFingerprint == certificateFingerprint &&
        !_manuallyDisconnected &&
        (isConnected || isConnecting || _reconnectExhausted)) {
      return;
    }
    _address = normalizedAddress;
    _sessionToken = sessionToken;
    _certificateFingerprint = endpoint.secure ? certificateFingerprint : null;
    _code = null;
    _hasPaired = true;
    _manuallyDisconnected = false;
    _reconnectAttempts = 0;
    _reconnectExhausted = false;
    _restoreCancelled = false;
    _reconnectGeneration++;
    await _attemptReconnect();
  }

  Future<void> retrySavedPairing() async {
    final address = _address;
    final sessionToken = _sessionToken;
    if (address == null || sessionToken == null || isConnected || _connecting) {
      return;
    }
    // A foregrounded app should retry now instead of waiting for the next
    // backoff timer scheduled while it was in the background.
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    _reconnectExhausted = false;
    _restoreCancelled = false;
    _manuallyDisconnected = false;
    _reconnectGeneration++;
    await _attemptReconnect();
  }

  /// Finds TV receivers on the local Wi-Fi without sending the pairing code.
  Future<List<String>> discoverReceivers({
    Duration timeout = const Duration(seconds: 4),
    bool preferSecure = true,
  }) async {
    final socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      0,
      reuseAddress: true,
    );
    socket.broadcastEnabled = true;
    final found = <String>{};
    final subscription = socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      Datagram? datagram;
      while ((datagram = socket.receive()) != null) {
        try {
          final response = jsonDecode(utf8.decode(datagram!.data));
          if (response is! Map || response['type'] != 'gametranslate_tv') {
            continue;
          }
          final securePort = response['securePort'];
          final secure =
              preferSecure &&
              securePort is int &&
              securePort > 0 &&
              securePort <= 65535;
          final port = secure ? securePort : response['port'];
          final host = datagram.address.address;
          if (port is int && port > 0 && port <= 65535) {
            found.add('${secure ? 'wss://' : ''}$host:$port');
          }
        } on FormatException {
          // Ignore unrelated packets on the local network.
        }
      }
    });
    final probe = utf8.encode(jsonEncode({'type': 'gametranslate_discover'}));
    final broadcast = InternetAddress('255.255.255.255');
    final started = DateTime.now();
    try {
      while (DateTime.now().difference(started) < timeout) {
        socket.send(probe, broadcast, discoveryPort);
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      return found.toList()..sort();
    } finally {
      await subscription.cancel();
      socket.close();
    }
  }

  Future<void> connect(
    String address,
    String code, {
    Future<bool> Function(String verificationCode)? verifyCertificate,
  }) async {
    final endpoint = _parseAddress(address);
    final cleanCode = code.trim();
    if (endpoint == null || !RegExp(r'^\d{6}$').hasMatch(cleanCode)) {
      throw const FormatException('TV adresi veya 6 haneli kod geçersiz.');
    }
    final generation = ++_reconnectGeneration;
    final oldSocket = _socket;
    _socket = null;
    _hasPaired = false;
    _socketPaired = false;
    _emitConnectionState();
    await _subscription?.cancel();
    _subscription = null;
    await oldSocket?.close(WebSocketStatus.goingAway, 'Re-pairing');
    _manuallyDisconnected = false;
    _hasPaired = false;
    _socketPaired = false;
    _sessionToken = null;
    _certificateFingerprint = null;
    _reconnectExhausted = false;
    _restoreCancelled = false;
    _tvDisplayHeightDp = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _address = endpoint.address;
    _code = cleanCode;
    _reconnectAttempts = 0;
    _connecting = true;
    _emitConnectionState();
    try {
      if (endpoint.secure) {
        if (verifyCertificate == null) {
          throw const HandshakeException('TV kimliği ekrandan doğrulanmalı.');
        }
        final fingerprint = await TvSecureTransport.inspect(
          endpoint.host,
          endpoint.port,
        );
        if (generation != _reconnectGeneration ||
            _restoreCancelled ||
            _manuallyDisconnected) {
          throw const HandshakeException('TV bağlantı denemesi iptal edildi.');
        }
        final verified = await verifyCertificate(
          TvSecureTransport.verificationCode(fingerprint),
        );
        if (!verified ||
            generation != _reconnectGeneration ||
            _restoreCancelled ||
            _manuallyDisconnected) {
          throw const HandshakeException('TV kimliği doğrulanmadı.');
        }
        _certificateFingerprint = fingerprint;
      }
      await _openSocket(endpoint, generation: generation);
      if (generation != _reconnectGeneration || _restoreCancelled) {
        throw const WebSocketException('TV bağlantı denemesi iptal edildi.');
      }
      final token = _sessionToken;
      if (token != null) {
        try {
          await _pairingChannel.invokeMethod<void>('saveTvPairing', {
            'address': _address,
            'sessionToken': token,
            'certificateFingerprint': _certificateFingerprint,
          });
        } on PlatformException {
          // The pairing caller also persists credentials after connect succeeds.
        }
      }
    } finally {
      _connecting = false;
      _emitConnectionState();
    }
  }

  Future<void> disconnect() async {
    _reconnectGeneration++;
    _manuallyDisconnected = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _code = null;
    _sessionToken = null;
    _certificateFingerprint = null;
    _hasPaired = false;
    _tvDisplayHeightDp = null;
    _address = null;
    _reconnectAttempts = 0;
    final socket = _socket;
    _socket = null;
    _socketPaired = false;
    _connecting = false;
    _emitConnectionState();
    await _subscription?.cancel();
    _subscription = null;
    await socket?.close(WebSocketStatus.goingAway, 'User disconnected');
  }

  Future<void> cancelConnectionAttempt() async {
    _reconnectGeneration++;
    _reconnectExhausted = true;
    _restoreCancelled = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _connecting = false;
    final pairCompleter = _pairCompleter;
    if (pairCompleter != null && !pairCompleter.isCompleted) {
      pairCompleter.complete();
    }
    _pairCompleter = null;
    final socket = _socket;
    _socket = null;
    _socketPaired = false;
    await _subscription?.cancel();
    _subscription = null;
    await socket?.close(WebSocketStatus.goingAway, 'Connection cancelled');
    _emitConnectionState();
  }

  void updateSubtitle(String text, SubtitleSettings settings) {
    updateSubtitles(<String>[text], settings, covers: const [], rich: const []);
  }

  void updateSubtitles(
    List<String> texts,
    SubtitleSettings settings, {
    List<Map<String, Object>>? covers,
    List<Map<String, Object>>? rich,
  }) {
    _subtitles = List<String>.of(texts);
    _subtitle = _subtitles.where((text) => text.isNotEmpty).join('\n');
    if (covers != null) _covers = List.unmodifiable(covers);
    if (rich != null) _rich = List.unmodifiable(rich);
    _presentation = _presentationFrom(settings);
    _send(_subtitleMessage());
  }

  /// Sends the translations that sit over the English subtitle lines.
  void updateCovers(
    List<Map<String, Object>> covers,
    SubtitleSettings settings,
  ) {
    _covers = List.unmodifiable(covers);
    _presentation = _presentationFrom(settings);
    _send(_subtitleMessage());
  }

  void updateSettings(SubtitleSettings settings) {
    _presentation = _presentationFrom(settings);
    _send(<String, Object>{
      'type': 'presentation',
      'text': _subtitle,
      'texts': _subtitles,
      'presentation': _presentation,
      if (_coverMode) 'covers': _covers,
      if (_hasRich) 'rich': _rich,
    });
  }

  // `covers` is only added while the cover mode is on, so the message stays
  // byte-for-byte the same as before for everyone using the fixed area.
  Map<String, Object> _subtitleMessage() => <String, Object>{
    'type': _subtitle.isEmpty && _covers.isEmpty ? 'clear' : 'subtitle',
    'text': _subtitle,
    'texts': _subtitles,
    'presentation': _presentation,
    if (_coverMode) 'covers': _covers,
    // Translations with button icons, per area; only sent when there are any,
    // so other messages stay exactly as before. Older receivers ignore it.
    if (_hasRich) 'rich': _rich,
  };

  bool get _hasRich => _rich.any((entry) => entry.isNotEmpty);

  Future<void> _openSocket(_Endpoint endpoint, {int? generation}) async {
    // A saved TLS identity must never be sent to a plaintext discovery result.
    if (endpoint.secure != (_certificateFingerprint != null)) {
      throw const HandshakeException('TV bağlantı güvenliği değişti.');
    }
    final completer = Completer<void>();
    _pairCompleter = completer;
    WebSocket? openedSocket;
    final httpClient = endpoint.secure
        ? TvSecureTransport.pinnedClient(_certificateFingerprint!)
        : null;
    try {
      final socket = await WebSocket.connect(
        Uri(
          scheme: endpoint.secure ? 'wss' : 'ws',
          host: endpoint.host,
          port: endpoint.port,
          path: '/subtitles',
        ).toString(),
        customClient: httpClient,
      ).timeout(const Duration(seconds: 8));
      openedSocket = socket;
      if (generation != null && generation != _reconnectGeneration) {
        throw const WebSocketException('TV bağlantı denemesi iptal edildi.');
      }
      _socket = socket;
      socket.pingInterval = const Duration(seconds: 15);
      final sessionToken = _sessionToken;
      socket.add(
        jsonEncode(
          sessionToken == null
              ? {'type': 'pair', 'code': _code}
              : {'type': 'resume', 'sessionToken': sessionToken},
        ),
      );
      _subscription = socket.listen(
        _handleMessage,
        onDone: () => _onSocketEnded(socket),
        onError: (_) => _onSocketEnded(socket),
        cancelOnError: true,
      );
      await completer.future.timeout(const Duration(seconds: 12));
    } catch (_) {
      if (openedSocket != null && identical(_socket, openedSocket)) {
        _socket = null;
        await _subscription?.cancel();
        _subscription = null;
      }
      await openedSocket?.close(WebSocketStatus.goingAway, 'Pairing failed');
      if (identical(_pairCompleter, completer)) {
        _pairCompleter = null;
      }
      rethrow;
    } finally {
      // Upgraded WebSockets own their socket independently of this client.
      httpClient?.close(force: openedSocket == null);
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final value = jsonDecode(message.toString());
      if (value is Map && value['type'] == 'paired') {
        final sessionToken = value['sessionToken'];
        if (sessionToken is String && sessionToken.length >= 40) {
          _sessionToken = sessionToken;
          _code = null;
        }
        _hasPaired = true;
        _socketPaired = true;
        _reconnectAttempts = 0;
        _reconnectExhausted = false;
        _restoreCancelled = false;
        _reconnectTimer?.cancel();
        _reconnectTimer = null;
        final displayHeight = value['displayHeightDp'];
        if (displayHeight is num &&
            displayHeight.isFinite &&
            displayHeight > 0) {
          _tvDisplayHeightDp = displayHeight.toDouble();
        }
        _emitConnectionState();
        _pairCompleter?.complete();
        _pairCompleter = null;
        _send(_subtitleMessage());
      } else if (value is Map && value['type'] == 'pairRejected') {
        _pairCompleter?.completeError(
          const WebSocketException('TV eşleştirme kodunu kabul etmedi.'),
        );
        _pairCompleter = null;
      }
    } catch (_) {
      // Ignore malformed receiver messages.
    }
  }

  void _onSocketEnded(WebSocket socket) {
    if (!identical(_socket, socket)) return;
    final wasPaired = _socketPaired;
    _socket = null;
    _socketPaired = false;
    final pairCompleter = _pairCompleter;
    if (pairCompleter != null && !pairCompleter.isCompleted) {
      pairCompleter.completeError(
        const WebSocketException(
          'TV bağlantısı eşleştirme tamamlanmadan kapandı.',
        ),
      );
      _pairCompleter = null;
    }
    _emitConnectionState();
    if (!_manuallyDisconnected && _hasPaired && _sessionToken != null) {
      if (wasPaired) {
        _reconnectAttempts = 0;
        _reconnectExhausted = false;
        _restoreCancelled = false;
      }
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_reconnectTimer != null ||
        _manuallyDisconnected ||
        !_hasPaired ||
        _sessionToken == null ||
        _reconnectExhausted ||
        _restoreCancelled) {
      return;
    }
    _reconnectAttempts++;
    final retryDelay = Duration(
      seconds: (_reconnectAttempts * 2)
          .clamp(2, _maxReconnectDelaySeconds)
          .toInt(),
    );
    _reconnectTimer = Timer(retryDelay, () async {
      _reconnectTimer = null;
      await _attemptReconnect();
    });
    _emitConnectionState();
  }

  Future<void> _attemptReconnect() async {
    if (_manuallyDisconnected ||
        !_hasPaired ||
        _sessionToken == null ||
        _reconnectExhausted ||
        _restoreCancelled ||
        isConnected ||
        _connecting) {
      return;
    }
    final generation = _reconnectGeneration;
    _connecting = true;
    _emitConnectionState();
    try {
      final savedAddress = _address;
      if (savedAddress != null &&
          await _tryReconnectAddress(savedAddress, generation)) {
        return;
      }
      if (generation != _reconnectGeneration ||
          _reconnectExhausted ||
          _restoreCancelled ||
          _manuallyDisconnected) {
        return;
      }

      final candidates = <String>{};
      try {
        candidates.addAll(
          await discoverReceivers(
            timeout: const Duration(seconds: 2),
            preferSecure: _certificateFingerprint != null,
          ),
        );
      } catch (_) {
        // The saved endpoint can still work when UDP discovery is unavailable.
      }
      if (generation != _reconnectGeneration ||
          _reconnectExhausted ||
          _restoreCancelled ||
          _manuallyDisconnected) {
        return;
      }
      for (final address in candidates) {
        if (address == savedAddress) continue;
        if (generation != _reconnectGeneration ||
            _manuallyDisconnected ||
            _reconnectExhausted ||
            _restoreCancelled ||
            !_hasPaired ||
            _sessionToken == null) {
          return;
        }
        if (await _tryReconnectAddress(address, generation)) return;
      }

      if (generation == _reconnectGeneration &&
          !_manuallyDisconnected &&
          !_restoreCancelled &&
          _hasPaired &&
          _sessionToken != null) {
        _scheduleReconnect();
      }
    } finally {
      _connecting = false;
      _emitConnectionState();
    }
  }

  Future<bool> _tryReconnectAddress(String address, int generation) async {
    if (_manuallyDisconnected ||
        _reconnectExhausted ||
        _restoreCancelled ||
        generation != _reconnectGeneration ||
        !_hasPaired ||
        _sessionToken == null) {
      return false;
    }
    final endpoint = _parseAddress(address);
    if (endpoint == null) return false;
    try {
      await _openSocket(endpoint, generation: generation);
      if (generation != _reconnectGeneration ||
          _reconnectExhausted ||
          _restoreCancelled ||
          _manuallyDisconnected) {
        final socket = _socket;
        _socket = null;
        _socketPaired = false;
        await _subscription?.cancel();
        _subscription = null;
        await socket?.close(WebSocketStatus.goingAway, 'Connection cancelled');
        return false;
      }
      if (!isConnected) return false;
      _address = endpoint.address;
      _reconnectAttempts = 0;
      try {
        await _pairingChannel.invokeMethod<void>('saveTvPairing', {
          'address': _address,
          'sessionToken': _sessionToken,
          'certificateFingerprint': _certificateFingerprint,
        });
      } on PlatformException {
        // Keep the live connection even if its refreshed endpoint cannot be saved.
      }
      return true;
    } catch (_) {
      // The address can belong to another TV, or the receiver may still be starting.
      return false;
    }
  }

  void _emitConnectionState() {
    final state = connectionState;
    if (state != _lastReportedConnectionState) {
      _lastReportedConnectionState = state;
      _connectionStateController.add(state);
    }
    final connected = state == TvSubtitleConnectionState.connected;
    if (connected != _lastReportedConnected) {
      _lastReportedConnected = connected;
      _statusController.add(connected);
    }
  }

  WebSocket? _fontSocket;
  String? _sentFont;
  void _send(Map<String, Object> message) {
    if (!isConnected) return;
    final socket = _socket;
    if (socket == null) return;
    try {
      final font = GameFonts.active.value;
      final presentation = message['presentation'];
      if (font != null &&
          presentation is Map &&
          subtitlePresentationUsesFont(presentation, font.sha256) &&
          (!identical(_fontSocket, socket) || _sentFont != font.sha256)) {
        socket.add(jsonEncode(font.packet));
        _fontSocket = socket;
        _sentFont = font.sha256;
      }
      socket.add(jsonEncode(message));
    } on WebSocketException {
      _onSocketEnded(socket);
    }
  }

  _Endpoint? _parseAddress(String value) {
    try {
      final text = value.trim();
      final uri = Uri.parse(text.contains('://') ? text : 'ws://$text');
      if ((uri.scheme != 'ws' && uri.scheme != 'wss') ||
          uri.host.isEmpty ||
          !uri.hasPort ||
          uri.port < 1 ||
          uri.port > 65535 ||
          uri.userInfo.isNotEmpty ||
          uri.hasQuery ||
          uri.hasFragment ||
          (uri.path.isNotEmpty && uri.path != '/subtitles')) {
        return null;
      }
      return _Endpoint(uri.host, uri.port, secure: uri.scheme == 'wss');
    } on FormatException {
      return null;
    }
  }

  Map<String, Object> _presentationFrom(SubtitleSettings settings) {
    _coverMode = settings.coversAnyEnglish;
    if (!_coverMode) _covers = const [];
    return subtitlePresentation(settings);
  }
}

class _Endpoint {
  const _Endpoint(this.host, this.port, {required this.secure});

  final String host;
  final int port;
  final bool secure;
  String get address =>
      '${secure ? 'wss://' : ''}'
      '${host.contains(':') ? '[$host]' : host}:$port';
}
