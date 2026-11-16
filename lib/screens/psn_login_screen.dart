import '../l10n/app_localizations.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'ps5_registration_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/psn_auth_service.dart';

class PsnLoginScreen extends StatefulWidget {
  const PsnLoginScreen({super.key, this.returnAfterSuccess = false});

  final bool returnAfterSuccess;

  @override
  State<PsnLoginScreen> createState() => _PsnLoginScreenState();
}

class _PsnLoginScreenState extends State<PsnLoginScreen> {
  static const _verificationSuccessMessage =
      'Doğrulama başarılı. PS5 konsolunu bağlamak için sonraki adıma devam et.';
  final TextEditingController _urlController = TextEditingController();

  String? _message;
  bool _isValid = false;
  bool _isOpeningBrowser = false;
  bool _isExchangingCode = false;
  bool _isPasting = false;
  late String _oauthState;
  StreamSubscription<dynamic>? _nativeEvents;

  static const String _psnLoginUrl =
      'https://auth.api.sonyentertainmentnetwork.com/2.0/oauth/authorize'
      '?service_entity=urn:service-entity:psn'
      '&response_type=code'
      '&client_id=ba495a24-818c-472b-b12d-ff231c1b5745'
      '&redirect_uri=https://remoteplay.dl.playstation.net/remoteplay/redirect'
      '&scope=psn:clientapp'
      '&request_locale=en_US'
      '&ui=pr'
      '&service_logo=ps'
      '&layout_type=popup'
      '&smcid=remoteplay'
      '&prompt=always'
      '&PlatformPrivacyWs1=minimal';

  Uri get _psnLoginUri => Uri.parse('$_psnLoginUrl&state=$_oauthState');

  String _newOAuthState() => base64UrlEncode(
    List<int>.generate(32, (_) => Random.secure().nextInt(256)),
  ).replaceAll('=', '');

  @override
  void initState() {
    super.initState();
    _oauthState = _newOAuthState();
    _nativeEvents = const EventChannel(
      'com.abrebostudio.consolegametranslator/ps5_events',
    ).receiveBroadcastStream().listen(_handleNativeEvent);
    unawaited(_loadPsnAccountState());
  }

  Future<void> _loadPsnAccountState() async {
    final initialState = _oauthState;
    try {
      final verified = await const MethodChannel(
        'com.abrebostudio.consolegametranslator/ps5_registration',
      ).invokeMethod<bool>('getPsnAccountIdState');
      if (!mounted ||
          verified != true ||
          _oauthState != initialState ||
          _urlController.text.isNotEmpty) {
        return;
      }
      setState(() {
        _isValid = true;
        _message = _verificationSuccessMessage;
      });
    } on PlatformException {
      // Keep manual verification available when saved state cannot be read.
    } on MissingPluginException {
      // Desktop previews can still show the sign-in form.
    }
  }

  void _handleNativeEvent(dynamic raw) {
    if (!mounted || !_isExchangingCode || raw is! Map) return;
    if (raw['type'] != 'psnProgress') return;
    final message = switch (raw['stage']) {
      'securityCheck' => 'Güvenli bağlantı doğrulanıyor…',
      'broker' => 'PSN Account ID alınıyor…',
      _ => null,
    };
    if (message != null) setState(() => _message = message);
  }

  Future<void> _openPsnLogin() async {
    setState(() {
      _oauthState = _newOAuthState();
      _isOpeningBrowser = true;
      _isValid = false;
      _message = null;
    });

    try {
      final opened = await launchUrl(
        _psnLoginUri,
        mode: LaunchMode.externalApplication,
      );

      if (!mounted) return;

      if (!opened) {
        setState(() {
          _message = "Tarayıcı açılamadı. Lütfen tekrar dene.";
          _isValid = false;
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _message = "PSN giriş sayfası açılamadı.";
        _isValid = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningBrowser = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nativeEvents?.cancel();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pasteUrl() async {
    setState(() => _isPasting = true);
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (!mounted) return;
      final text = data?.text?.trim() ?? '';
      if (text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr("Panoda yapıştırılacak bir bağlantı yok."),
            ),
          ),
        );
        return;
      }
      setState(() {
        _urlController.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
        _isValid = false;
        _message = null;
      });
    } on PlatformException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr("Panodaki bağlantı okunamadı. Tekrar dene."),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPasting = false);
    }
  }

  Future<void> _validateUrl() async {
    var code = PsnAuthService.extractAuthorizationCode(
      _urlController.text,
      expectedState: _oauthState,
    );
    // Do not keep the pasted redirect URL (which includes the code) in the
    // editing controller while the network exchange is running.
    _urlController.clear();

    if (code == null) {
      setState(() {
        _isValid = false;
        _message =
            "URL içinde geçerli bir authorization code bulunamadı. Yönlendirme URL’sini kontrol et.";
      });
      return;
    }

    setState(() {
      _isExchangingCode = true;
      _isValid = false;
      _message = "Sony hesabı doğrulanıyor…";
    });
    try {
      final exchange = const MethodChannel(
        'com.abrebostudio.consolegametranslator/ps5_registration',
      ).invokeMethod<bool>('exchangePsnCode', {'code': code});
      code = null;
      if (await exchange != true) {
        throw PlatformException(
          code: 'PSN_AUTH_FAILED',
          message: "PSN hesabı doğrulanamadı. Tekrar dene.",
        );
      }
      if (!mounted) return;
      setState(() {
        _oauthState = _newOAuthState();
        _isValid = true;
        _message = _verificationSuccessMessage;
      });
      if (widget.returnAfterSuccess && mounted) Navigator.of(context).pop(true);
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _isValid = false;
        _message =
            '${error.message ?? "PSN doğrulaması başarısız."} (${error.code})';
      });
    } finally {
      if (mounted) setState(() => _isExchangingCode = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF100D1C);
    const panel = Color(0xFF1D1830);
    const accent = Color(0xFF8B5CF6);
    const muted = Color(0xFFAAA4BD);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: Colors.white,
        title: Text(context.tr("PSN Hesap Bağlantısı")),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: Center(
              child: Text(
                '1/2',
                semanticsLabel: context.tr("Adım 1/2"),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.link_rounded, size: 58, color: accent),
              const SizedBox(height: 20),
              Text(
                context.tr("PSN hesabını bağla"),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.tr(
                  "PSN giriş sayfasını tarayıcıda aç. Giriş yaptıktan sonra \"redirect\" yazan beyaz bir sayfa açılır. Bu sayfa açıkken tarayıcının adres çubuğundaki bağlantının tamamını kopyalayıp buraya yapıştır. Sayfadaki yazıyı değil, adres çubuğundaki linki kopyala.",
                ),
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, height: 1.5),
              ),
              const SizedBox(height: 12),
              Text(
                context.tr(
                  "Bu bağlantı için yeni bir PSN hesabı oluştur veya şu anda kullanmadığın bir hesabı bağla, ana hesabını bağlama. Bağlayacağın PSN hesabı PlayStation 5’te de kullanıcı olarak ekli olmalı. Ana hesaptan oyunu oynayacaksın.",
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.amberAccent,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // PSN girişini varsayılan harici tarayıcıda açar.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      _isOpeningBrowser || _isExchangingCode || _isPasting
                      ? null
                      : _openPsnLogin,
                  icon: _isOpeningBrowser
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.open_in_browser),
                  label: Text(
                    _isOpeningBrowser
                        ? context.tr("Tarayıcı açılıyor...")
                        : context.tr("PSN ile giriş yap"),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // URL yapıştırma bölümü.
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: panel,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.tr("Yönlendirme URL’si"),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed:
                              _isOpeningBrowser ||
                                  _isExchangingCode ||
                                  _isPasting
                              ? null
                              : _pasteUrl,
                          icon: const Icon(
                            Icons.content_paste_rounded,
                            size: 18,
                          ),
                          label: Text(context.tr("Yapıştır")),
                          style: TextButton.styleFrom(foregroundColor: accent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _urlController,
                      minLines: 1,
                      maxLines: 2,
                      enabled:
                          !_isOpeningBrowser &&
                          !_isExchangingCode &&
                          !_isPasting,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      onChanged: (_) {
                        if (_isValid || _message != null) {
                          setState(() {
                            _isValid = false;
                            _message = null;
                          });
                        }
                      },
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.all(12),
                        hintText: 'https://.../redirect?code=...',
                        hintStyle: const TextStyle(color: muted),
                        filled: true,
                        fillColor: background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF39314D),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: accent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed:
                            _isExchangingCode || _isOpeningBrowser || _isPasting
                            ? null
                            : _validateUrl,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: accent),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: Text(
                          _isExchangingCode
                              ? context.tr("PSN doğrulanıyor…")
                              : context.tr("PSN hesabını doğrula"),
                        ),
                      ),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        context.trMessage(_message!),
                        style: TextStyle(
                          color: _isValid
                              ? Colors.greenAccent
                              : Colors.orangeAccent,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: !_isValid
                      ? null
                      : () {
                          if (widget.returnAfterSuccess) {
                            Navigator.of(context).pop(true);
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const Ps5RegistrationScreen(),
                            ),
                          );
                        },
                  icon: const Icon(Icons.sports_esports_rounded),
                  label: Text(context.tr("Sonraki adım: PS5 konsolunu bağla")),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22D3EE),
                    foregroundColor: const Color(0xFF100D1C),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
