import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/app_links.dart';
import '../services/lan_tv_address.dart';
import '../services/lg_webos_client.dart';
import '../services/tv_output_service.dart';
import 'setup_notice.dart';
import 'tv_platform_selector.dart';

class SmartTvSetupDialog extends StatefulWidget {
  const SmartTvSetupDialog({
    super.key,
    required this.kind,
    this.onKindSelected,
  });
  final TvOutputKind kind;
  final ValueChanged<TvOutputKind>? onKindSelected;

  @override
  State<SmartTvSetupDialog> createState() => _SmartTvSetupDialogState();
}

class _SmartTvSetupDialogState extends State<SmartTvSetupDialog> {
  final _ip = TextEditingController();
  final _lg = LgWebOsClient();
  final _output = TvOutputService.instance;
  StreamSubscription<void>? _samsungChanges;
  bool _encrypted = true;
  bool _busy = false;
  bool _tested = false;
  bool _accepted = false;
  bool _startedSamsung = false;
  String? _error;
  String? _errorCode;

  @override
  void initState() {
    super.initState();
    _samsungChanges = _output.samsung.changes.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ip.dispose();
    unawaited(_samsungChanges?.cancel());
    if (!_accepted) {
      unawaited(_lg.disconnect());
      if (_startedSamsung) unawaited(_output.samsung.stop());
    }
    super.dispose();
  }

  Future<void> _testLg() async {
    setState(() {
      _busy = true;
      _error = null;
      _errorCode = null;
      _tested = false;
    });
    final ip = _ip.text.trim();
    if (!LanTvAddress.isPrivateIpv4(ip)) {
      setState(() {
        _busy = false;
        _error =
            'Geçerli bir yerel IP adresi gir (ör. 192.168.1.20). TV’de Ayarlar > Ağ bölümünde görünür.';
      });
      return;
    }
    var connected = false;
    try {
      await _lg.connect(ip, encrypted: _encrypted);
      connected = true;
      if (!mounted) return;
      await _lg.testNotification(
        context.tr('Oyun Çevirmeni • TV bağlantı testi'),
      );
      if (mounted) setState(() => _tested = true);
    } catch (error) {
      if (mounted) {
        setState(() {
          if (connected) {
            _error =
                'LG bildirimi gösterilemedi. TV bağlantısını yeniden test et.';
            _errorCode = 'toast ${error.runtimeType}';
          } else {
            _error =
                _lg.lastError ??
                'LG bağlantısı kurulamadı. IP adresini, TV iznini ve bağlantı türünü kontrol et.';
            _errorCode = _lg.lastErrorCode;
          }
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startSamsung() async {
    setState(() {
      _busy = true;
      _error = null;
      _errorCode = null;
    });
    try {
      await _output.startSamsung();
      _startedSamsung = true;
      if (!mounted) {
        await _output.samsung.stop();
        return;
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Yerel TV oturumu açılamadı. Telefonun Wi-Fi bağlantısını kontrol et.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _accept() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (widget.kind == TvOutputKind.lg) {
        if (!_lg.isConnected) throw StateError('Disconnected');
        await _output.activateLg(_lg);
      } else if (!_output.samsung.isConnected) {
        throw StateError('Not ready');
      }
      _accepted = true;
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'TV bağlantısı doğrulanamadı. Testi yeniden çalıştır.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lg = widget.kind == TvOutputKind.lg;
    final session = _output.samsung;
    final canAccept = lg
        ? _tested && _lg.isConnected
        : _startedSamsung && session.isConnected;
    return AlertDialog(
      backgroundColor: const Color(0xFF131A2B),
      title: Text(lg ? 'LG webOS • Beta' : 'Samsung Tizen • Beta'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TvPlatformSelector(
                selected: widget.kind,
                onSelected: _busy ? null : widget.onKindSelected,
              ),
              const SizedBox(height: 12),
              const SmartTvBetaNotice(),
              const SizedBox(height: 12),
              Text(
                context.tr('Önce TV bağlantısını kontrol edelim.'),
                style: const TextStyle(color: Color(0xFF4DE2D0)),
              ),
              const SizedBox(height: 12),
              if (lg) ...[
                Text(
                  context.tr(
                    'Telefon ve TV aynı yerel ağda olsun. TV ayarlarındaki ağ bölümünden yerel IPv4 adresini bul. Bağlanırken TV’de çıkan izin isteğini kumandayla onayla. TV’ye uygulama yüklemek gerekmez.',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _ip,
                  enabled: !_busy,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: context.tr('LG TV’nin yerel IPv4 adresi'),
                    hintText: '192.168.1.25',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() => _tested = false),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _encrypted,
                  title: Text(context.tr('Şifreli bağlantı (3001)')),
                  onChanged: _busy
                      ? null
                      : (value) => setState(() {
                          _encrypted = value;
                          _tested = false;
                        }),
                ),
                Text(
                  context.tr(
                    _encrypted
                        ? 'İlk bağlantıda TV sertifikası kaydedilir; sonraki bağlantılarda aynı sertifika aranır. Kimlik ilk kullanımda TV’deki izin onayına dayanır.'
                        : 'Eski TV modu (3000): altyazı ve eşleştirme bilgileri yerel ağda şifresiz taşınır. Yalnızca güvendiğin ev ağında kullan.',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr(
                    'LG bildirim modu: altyazılar TV bildirimi olarak görünür. Konum, yazı tipi ve süreyi TV belirler; çoklu alan metinleri birleştirilir. Durdurduğunda bekleyen metinler iptal edilir, görünen bildirim TV’nin süresi dolunca kapanır.',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _busy ? null : _testLg,
                  child: Text(
                    context.tr(
                      _busy
                          ? 'TV’deki izin isteğini onayla…'
                          : 'Bağlan ve örnek yazı gönder',
                    ),
                  ),
                ),
                if (_tested)
                  Text(
                    context.tr(
                      'PS5’in HDMI görüntüsü açıkken örnek bildirimi gördüysen aşağıdan onayla. Göremediysen bu modu kullanma.',
                    ),
                  ),
              ] else ...[
                Text(
                  context.tr(
                    'Samsung TV’de “Console Game Translator TV” uygulamamızın açık olması gerekiyor. Telefonda oluşturduğun kodu bu TV uygulamasına girerek eşleştireceksin.',
                  ),
                ),
                // TODO: Remove the website download action after store release.
                OutlinedButton.icon(
                  onPressed: () => AppLinks.openTvSetup(context, 'samsung'),
                  icon: const Icon(Icons.download_rounded),
                  label: Text(context.tr('TV uygulamasını indir')),
                ),
                const SizedBox(height: 12),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 12),
                  title: Text(
                    context.tr('TV uygulaması henüz kurulu değil mi?'),
                  ),
                  children: [
                    Text(
                      context.tr(
                        'Samsung TV uygulamamız henüz Samsung mağazasında bulunmuyor. İlk kurulum için sitemizdeki Windows kurulum yardımcısını kullan. Samsung hesabınla TV’ye kurulum iznini bir kez hazırlaman gerekir. Adımlar için TV kurulum rehberini aç.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _busy ? null : _startSamsung,
                  child: Text(
                    context.tr(
                      _startedSamsung
                          ? 'Yeni eşleştirme kodu oluştur'
                          : 'TV uygulamam kurulu • Eşleştir',
                    ),
                  ),
                ),
                if (_startedSamsung) ...[
                  Text(context.tr('Telefonun adresi')),
                  for (final endpoint in session.endpoints)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: SelectableText(endpoint),
                    ),
                  Text(
                    context.tr(
                      'TV’de uygulamamızı aç. Buradaki telefon adresini ve eşleştirme kodunu TV ekranına gir. Birden fazla adres varsa TV ile aynı ağdakini seç. Kod 2 dakika geçerlidir.',
                    ),
                  ),
                  Text(context.tr('Eşleştirme kodu')),
                  SelectableText(
                    session.pairingCode ?? context.tr('Kod kullanıldı'),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr(
                      session.isConnected
                          ? 'HDMI ve örnek altyazı TV’de onaylandı.'
                          : session.hasReceiver
                          ? 'TV bağlandı. TV’de HDMI girişini seçip oyun + örnek altyazı testini onayla.'
                          : 'TV uygulamasının bağlanması bekleniyor…',
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  context.tr(
                    'Altyazılar için TV uygulamamızı açık tut. Kumandadan Home’a basarsan veya başka bir girişe geçersen altyazılar durur. Bu bağlantıda metinler ev ağında şifresiz iletilir.',
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                context.tr(
                  'Sorun mu yaşıyorsun? TV modelini, sorunun kısa açıklamasını ve ekran görüntüsünü bize gönder; birlikte çözelim.',
                ),
              ),
              TextButton.icon(
                onPressed: () =>
                    AppLinks.openTvSetup(context, lg ? 'lg' : 'samsung'),
                icon: const Icon(Icons.open_in_browser),
                label: Text(context.tr('TV kurulum rehberini aç')),
              ),
              TextButton.icon(
                onPressed: () => AppLinks.contactTvSupport(
                  context,
                  lg ? 'LG webOS' : 'Samsung Tizen',
                ),
                icon: const Icon(Icons.support_agent),
                label: Text(context.tr('TV bağlantısı için destek al')),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _errorCode == null
                        ? context.tr(_error!)
                        : '${context.tr(_error!)} [$_errorCode]',
                    style: const TextStyle(color: Colors.orangeAccent),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.tr('İptal')),
        ),
        FilledButton(
          onPressed: _busy || !canAccept ? null : _accept,
          child: Text(
            context.tr(lg ? 'TV’de örnek yazıyı gördüm' : 'Bağlantıyı kullan'),
          ),
        ),
      ],
    );
  }
}
