import '../l10n/app_localizations.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ps5_stream_screen.dart';
import 'psn_login_screen.dart';

class Ps5RegistrationScreen extends StatefulWidget {
  const Ps5RegistrationScreen({super.key});

  @override
  State<Ps5RegistrationScreen> createState() => _Ps5RegistrationScreenState();
}

class _Ps5RegistrationScreenState extends State<Ps5RegistrationScreen> {
  static const _channel = MethodChannel(
    'com.abrebostudio.consolegametranslator/ps5_registration',
  );

  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isRegistering = false;
  String? _message;
  bool _isSuccess = false;
  Map<String, dynamic>? _savedConsole;
  List<Map<String, dynamic>> _discoveredHosts = [];
  bool _isDiscovering = false;
  bool _hasPsnAccountId = false;
  StreamSubscription<dynamic>? _eventsSubscription;

  @override
  void initState() {
    super.initState();
    _loadSavedConsole();
    _loadPsnAccountState();
    _eventsSubscription = const EventChannel(
      'com.abrebostudio.consolegametranslator/ps5_events',
    ).receiveBroadcastStream().listen(_handleNativeEvent);
  }

  Future<void> _loadPsnAccountState() async {
    try {
      final hasId =
          await _channel.invokeMethod<bool>('getPsnAccountIdState') ?? false;
      if (mounted) setState(() => _hasPsnAccountId = hasId);
    } on PlatformException catch (error) {
      if (mounted) setState(() => _message = error.message ?? error.code);
    }
  }

  Future<void> _loadSavedConsole() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getSavedConsole',
      );
      if (mounted) setState(() => _savedConsole = result);
    } on PlatformException catch (error) {
      if (mounted) setState(() => _message = error.message ?? error.code);
    }
  }

  void _handleNativeEvent(dynamic event) {
    if (!mounted || event is! Map) return;
    if (event['type'] == 'discovery') {
      final hosts = (event['hosts'] as List? ?? const [])
          .whereType<Map>()
          .map((host) => Map<String, dynamic>.from(host))
          .where((host) => (host['host'] as String?)?.isNotEmpty == true)
          .toList();
      setState(() => _discoveredHosts = hosts);
    }
  }

  Future<void> _discoverPs5() async {
    setState(() {
      _isDiscovering = true;
      _discoveredHosts = [];
      _message = null;
    });
    try {
      await _channel.invokeMethod<bool>('startDiscovery');
      await Future<void>.delayed(const Duration(seconds: 8));
    } on PlatformException catch (error) {
      if (mounted) setState(() => _message = error.message ?? error.code);
    } finally {
      await _channel.invokeMethod<void>('stopDiscovery');
      if (mounted) setState(() => _isDiscovering = false);
    }
  }

  void _selectDiscoveredHost(Map<String, dynamic> host) {
    _hostController.text = host['host']?.toString() ?? '';
    setState(
      () => _message =
          "PS5 bulundu. Eşleştirme için 8 haneli konsol PIN’ini gir.",
    );
  }

  void _openStream() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const Ps5StreamScreen()));
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    _channel.invokeMethod<void>('stopDiscovery');
    _hostController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  bool _isIpv4(String value) {
    final parts = value.split('.');
    if (parts.length != 4) return false;
    return parts.every((part) {
      if (part.isEmpty || part.length > 3 || int.tryParse(part) == null) {
        return false;
      }
      final number = int.parse(part);
      return number >= 0 && number <= 255;
    });
  }

  Future<void> _registerPs5() async {
    if (_isRegistering) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isRegistering = true;
      _message = "PS5 kayıt işlemi başlatılıyor…";
      _isSuccess = false;
    });

    try {
      final response = await _channel.invokeMapMethod<String, dynamic>(
        'registerPs5',
        {
          'host': _hostController.text.trim(),
          'pin': _pinController.text.trim(),
        },
      );
      if (!mounted) return;
      final nickname = response?['nickname']?.toString();
      setState(() {
        _isSuccess = response?['status'] == 'success';
        if (_isSuccess) {
          _savedConsole = {'host': response?['host'], 'nickname': nickname};
        }
        _message = _isSuccess
            ? "PS5 kaydı başarılı.\n${nickname?.isNotEmpty == true ? 'Konsol: $nickname\n' : ''}"
            : "Kayıt sonucu alınamadı.";
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSuccess = false;
        _message =
            "${error.message ?? context.tr("PS5 kaydı başarısız.")}\nHata kodu: ${error.code}";
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSuccess = false;
        _message = "Beklenmeyen hata: $error";
      });
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
    if (mounted && _isSuccess) {
      await _showRegistrationSuccess(_savedConsole?['nickname']?.toString());
    }
  }

  Future<void> _showRegistrationSuccess(String? nickname) async {
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope<bool>(
        canPop: false,
        child: AlertDialog(
          scrollable: true,
          backgroundColor: const Color(0xFF1D1830),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFF295C55)),
          ),
          icon: Center(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF163E36), Color(0xFF213547)],
                ),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF69F0AE),
                size: 48,
              ),
            ),
          ),
          title: Text(
            context.tr("PS5 bağlantısı hazır!"),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          content: Text(
            context.tr(
              "{0} başarıyla eşleştirildi.\n\nArtık ana menüden çeviriyi başlatabilirsin.",
              [
                nickname?.trim().isNotEmpty == true
                    ? nickname!.trim()
                    : 'PlayStation 5',
              ],
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFCBC5DC), height: 1.5),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF69F0AE),
                  foregroundColor: const Color(0xFF100D1C),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(context.tr("Tamam")),
              ),
            ),
          ],
        ),
      ),
    );
    if (!mounted || confirmed != true) return;
    navigator.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF100D1C);
    const panel = Color(0xFF1D1830);
    const accent = Color(0xFF22D3EE);
    const muted = Color(0xFFAAA4BD);

    InputDecoration decoration(String label, String hint) => InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: muted),
      hintStyle: const TextStyle(color: muted),
      filled: true,
      fillColor: background,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF39314D)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accent),
      ),
    );

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: Colors.white,
        title: Text(context.tr("PS5 Bağlantısı")),
        actions: [
          Padding(
            padding: EdgeInsetsDirectional.only(end: 20),
            child: Center(
              child: Text(
                '2/2',
                semanticsLabel: context.tr("Adım 2/2"),
                style: TextStyle(
                  color: accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.sports_esports_rounded,
                  size: 62,
                  color: accent,
                ),
                const SizedBox(height: 18),
                Text(
                  context.tr("PS5 konsolunu kaydet"),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  context.tr(
                    "Telefon ve PS5 aynı yerel ağda olmalı. PS5 IP adresini konsolun ağ ayarlarında bulabilirsin.",
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, height: 1.5),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: panel,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accent.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.settings_remote_rounded,
                        color: accent,
                        size: 19,
                      ),
                      SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          context.tr(
                            "PS5’te bağladığın PSN hesabına geç. Ayarlar → Sistem → Uzaktan Oynatma → Uzaktan Oynatmayı Etkinleştir seçeneğini aç. Ardından Cihazı Eşleştir ile aldığın 8 haneli kodu aşağıya gir.",
                          ),
                          style: TextStyle(color: Colors.white, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (_savedConsole != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: panel,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          context.tr("Kayıtlı PS5: {0}", [
                            _savedConsole!['nickname'] ?? 'PlayStation 5',
                          ]),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr("PS5 kayıtlı"),
                          style: const TextStyle(color: muted),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _openStream,
                          icon: const Icon(Icons.play_arrow),
                          label: Text(context.tr("Remote Play ekranını aç")),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                OutlinedButton.icon(
                  onPressed: _isDiscovering ? null : _discoverPs5,
                  icon: _isDiscovering
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_find),
                  label: Text(
                    _isDiscovering
                        ? context.tr("Yerel ağ taranıyor…")
                        : context.tr("Ağda PS5 ara"),
                  ),
                ),
                if (_discoveredHosts.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ..._discoveredHosts.map(
                    (host) => ListTile(
                      leading: const Icon(Icons.sports_esports, color: accent),
                      title: Text(
                        host['nickname']?.toString().isNotEmpty == true
                            ? host['nickname'].toString()
                            : 'PlayStation 5',
                      ),
                      subtitle: Text('${host['host']} • ${host['state']}'),
                      onTap: () => _selectDiscoveredHost(host),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  context.tr("PS5 bulunamazsa IP adresini elle yazabilirsin."),
                  style: TextStyle(color: muted, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: panel,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        textDirection: TextDirection.ltr,
                        controller: _hostController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        style: const TextStyle(color: Colors.white),
                        decoration: decoration(
                          context.tr("PS5 IPv4 adresi"),
                          '192.168.1.100',
                        ),
                        validator: (value) {
                          final host = value?.trim() ?? '';
                          if (host.isEmpty) {
                            return context.tr("PS5 IPv4 adresini gir.");
                          }
                          if (!_isIpv4(host)) {
                            return context.tr("Geçerli bir IPv4 adresi gir.");
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      if (!_hasPsnAccountId) ...[
                        Text(
                          context.tr(
                            "Eşleştirmeden önce PSN hesabını doğrula. Account ID uygulamada güvenli olarak alınır.",
                          ),
                          style: TextStyle(
                            color: muted,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await Navigator.of(context).push<bool>(
                              MaterialPageRoute<bool>(
                                builder: (_) => const PsnLoginScreen(
                                  returnAfterSuccess: true,
                                ),
                              ),
                            );
                            _loadPsnAccountState();
                          },
                          icon: const Icon(Icons.verified_user),
                          label: Text(context.tr("PSN hesabını doğrula")),
                        ),
                        const SizedBox(height: 12),
                      ] else ...[
                        Row(
                          children: [
                            Icon(
                              Icons.verified,
                              color: Colors.greenAccent,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              context.tr("PSN hesabı doğrulandı"),
                              style: TextStyle(color: Colors.greenAccent),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        textDirection: TextDirection.ltr,
                        controller: _pinController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 8,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(8),
                        ],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          letterSpacing: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: decoration(
                          context.tr("Uzaktan erişim PIN kodu"),
                          '••••••••',
                        ).copyWith(counterText: ''),
                        validator: (value) =>
                            RegExp(r'^\d{8}$').hasMatch(value?.trim() ?? '')
                            ? null
                            : context.tr("PIN kodu 8 rakam olmalı."),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _isRegistering ? null : _registerPs5,
                        icon: _isRegistering
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.link_rounded),
                        label: Text(
                          _isRegistering
                              ? context.tr("PS5 kaydediliyor…")
                              : context.tr("PS5 bağlantısını başlat"),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: background,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      if (_message != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          context.trMessage(_message!),
                          style: TextStyle(
                            color: _isSuccess
                                ? Colors.greenAccent
                                : Colors.orangeAccent,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
