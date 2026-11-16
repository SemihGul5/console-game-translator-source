import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../services/app_links.dart';
import '../services/subtitle_settings_store.dart';

class GeminiSettingsPanel extends StatefulWidget {
  const GeminiSettingsPanel({
    super.key,
    required this.hasKey,
    required this.onChanged,
    this.store = const SubtitleSettingsStore(),
  });

  final bool hasKey;
  final ValueChanged<bool> onChanged;
  final SubtitleSettingsStore store;

  @override
  State<GeminiSettingsPanel> createState() => _GeminiSettingsPanelState();
}

class _GeminiSettingsPanelState extends State<GeminiSettingsPanel>
    with WidgetsBindingObserver {
  final _keyController = TextEditingController();
  bool _obscured = true;
  bool _busy = false;
  bool _failed = false;
  String? _status;
  Timer? _runtimeTimer;
  bool _readingRuntime = false;
  String _runtimeState = 'idle';
  String _runtimeMessage = '';
  String _fallback = 'idle';
  int _retrySeconds = 0;
  int _activeKeyIndex = 0;
  List<Map<String, dynamic>> _savedKeys = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _watchRuntime();
    unawaited(_readKeys());
  }

  void _watchRuntime() {
    _runtimeTimer?.cancel();
    unawaited(_readRuntime());
    _runtimeTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => unawaited(_readRuntime()),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _watchRuntime();
    } else {
      _runtimeTimer?.cancel();
    }
  }

  Future<void> _readRuntime() async {
    if (_readingRuntime) return;
    _readingRuntime = true;
    try {
      final value = await widget.store.loadGeminiRuntimeStatus();
      if (!mounted || value == null) return;
      final state = value['state'] as String? ?? 'idle';
      final milliseconds = value['remainingMs'] as num? ?? 0;
      final seconds = (milliseconds / 1000).ceil().clamp(0, 86400);
      final message = value['message'] as String? ?? '';
      final fallback = value['fallback'] as String? ?? 'idle';
      final activeKey = (value['activeKeyIndex'] as num?)?.toInt() ?? 0;
      if (_runtimeState != state ||
          _retrySeconds != seconds ||
          _runtimeMessage != message ||
          _fallback != fallback ||
          _activeKeyIndex != activeKey) {
        setState(() {
          _runtimeState = state;
          _retrySeconds = seconds;
          _runtimeMessage = message;
          _fallback = fallback;
          _activeKeyIndex = activeKey;
        });
      }
    } on PlatformException {
      // A local status display never grants access or retries a cloud request.
    } on MissingPluginException {
      // Older native builds have no runtime status channel.
    } finally {
      _readingRuntime = false;
    }
  }

  void _setKeys(Map<String, dynamic> value) {
    _savedKeys = (value['keys'] as List? ?? const [])
        .whereType<Map>()
        .map((key) => Map<String, dynamic>.from(key))
        .toList();
  }

  Future<void> _readKeys() async {
    try {
      final value = await widget.store.loadGeminiSettings();
      if (mounted && value != null) setState(() => _setKeys(value));
    } on PlatformException {
      // Key management errors are shown on the user's explicit action.
    } on MissingPluginException {
      // Supports older native previews.
    }
  }

  Future<void> _removeKey(String id) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = null;
      _failed = false;
    });
    try {
      final value = await widget.store.removeGeminiApiKey(id);
      if (!mounted || value == null) return;
      setState(() {
        _setKeys(value);
        _status = 'Gemini anahtarı silindi.';
      });
      widget.onChanged(value['hasKey'] == true);
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() {
          _failed = true;
          _status =
              error.message ?? 'Gemini işlemi tamamlanamadı. Tekrar dene.';
        });
      }
    } on MissingPluginException {
      if (mounted) {
        setState(() {
          _failed = true;
          _status = 'Gemini bu platformda kullanılamıyor.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _runtimeTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _run({bool clear = false}) async {
    if (_busy) return;
    final key = _keyController.text.trim();
    if (!clear && key.isEmpty && !widget.hasKey) {
      setState(() {
        _status = 'Geçerli bir Gemini API anahtarı gir.';
        _failed = true;
      });
      return;
    }
    setState(() {
      _busy = true;
      _failed = false;
      _status = null;
    });
    try {
      if (clear) {
        await widget.store.clearGeminiApiKey();
      } else if (key.isNotEmpty) {
        await widget.store.saveGeminiApiKey(key);
      } else {
        await widget.store.testGeminiConnection();
      }
      await _readKeys();
      if (!mounted) return;
      _keyController.clear();
      widget.onChanged(!clear);
      setState(
        () => _status = clear
            ? 'Gemini anahtarı silindi.'
            : 'Gemini bağlantısı başarılı. Çeviri için hazır.',
      );
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() {
          _failed = true;
          _status =
              error.message ?? 'Gemini işlemi tamamlanamadı. Tekrar dene.';
        });
      }
    } on MissingPluginException {
      if (mounted) {
        setState(() {
          _failed = true;
          _status = 'Gemini bu platformda kullanılamıyor.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        context.tr('Gemini 3.5 Flash-Lite'),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      Text(
        context.tr(
          'En fazla 5 anahtar ekleyebilirsin. Bir anahtar sınıra ulaşırsa hazır diğer anahtara geçilir; hepsi bekliyorsa önbellek ve yüklü Model A/B kullanılır.',
        ),
        style: const TextStyle(fontSize: 12, height: 1.4),
      ),
      const SizedBox(height: 6),
      Text(
        context.tr(
          'Aynı Google projesindeki anahtarlar ortak kotayı kullanır. Anahtar eklemek proje kotasını artırmaz; diğer anahtarın da kullanılabilir kotası olmalıdır.',
        ),
        style: const TextStyle(fontSize: 12, height: 1.4),
      ),
      for (final saved in _savedKeys)
        ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          leading: const Icon(Icons.key_rounded, size: 18),
          title: Text(context.tr('Anahtar {0}', [saved['index']])),
          subtitle: _runtimeState == 'idle' && _activeKeyIndex == saved['index']
              ? Text(context.tr('Kullanılıyor'))
              : null,
          trailing: IconButton(
            key: ValueKey('gemini-remove-${saved['id']}'),
            tooltip: context.tr('Bu anahtarı sil'),
            onPressed: _busy ? null : () => _removeKey(saved['id'] as String),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ),
      if (_runtimeState == 'waiting' || _runtimeState == 'paused') ...[
        Container(
          key: const ValueKey('gemini-runtime-notice'),
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF3B2C17),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _runtimeState == 'waiting'
                    ? context.tr(
                        'Gemini bekliyor. {0} sn sonra güncel altyazıyla yeniden denenecek.',
                        [_retrySeconds],
                      )
                    : context.trMessage(
                        _runtimeMessage.isNotEmpty
                            ? _runtimeMessage
                            : 'Geçerli bir Gemini API anahtarı gir.',
                      ),
                style: const TextStyle(
                  color: Color(0xFFFFC56D),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              if (_fallback != 'idle') ...[
                const SizedBox(height: 6),
                Text(
                  context.tr(switch (_fallback) {
                    'opus' => 'Model A ile yerel çeviri kullanılıyor.',
                    'mlkit' => 'Model B ile yerel çeviri kullanılıyor.',
                    'unavailable' =>
                      'Bu dil çifti için yerel paket yüklü değil. Model A veya B dil paketini indir. Önbellekteki çeviriler kullanılabilir.',
                    'failed' =>
                      'Yerel paket açılamadı. Model A veya B dil paketini yeniden indir. Önbellekteki çeviriler kullanılabilir.',
                    _ => 'Yerel paketler kontrol ediliyor.',
                  }),
                  style: const TextStyle(
                    color: Color(0xFFFFC56D),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
      Text(
        context.tr(
          'Gemini beklerken önce önbellek, ardından bu dil çifti için yüklü Model A veya Model B kullanılır. İkisi de hazırsa Model A seçilir. Yerel paketleri ilgili modelin dil paketleri bölümünden indirebilirsin.',
        ),
        style: const TextStyle(fontSize: 12, height: 1.4),
      ),
      const SizedBox(height: 8),
      Text(
        context.tr(
          'Gemini internet ve kendi API anahtarını gerektirir. Altyazı metinleri Google’a gönderilir. Ücretsiz katmanda bu içerikler Google ürünlerini geliştirmek için kullanılabilir.',
        ),
        style: const TextStyle(fontSize: 12, height: 1.4),
      ),
      TextButton.icon(
        key: const ValueKey('gemini-free-api-link'),
        onPressed: () =>
            AppLinks.openWeb(context, 'https://aistudio.google.com/apikey'),
        icon: const Icon(Icons.open_in_new_rounded, size: 16),
        label: Text(context.tr('Ücretsiz Gemini API anahtarı al')),
      ),
      Text(
        context.tr(
          'Google AI Studio’da Google hesabınla giriş yap, bir proje ve API anahtarı oluştur. Ücretsiz kullanım için projen Free Tier olmalı; faturalandırmayı etkinleştirme. Anahtarı aşağıya yapıştır.',
        ),
        style: const TextStyle(fontSize: 12, height: 1.4),
      ),
      const SizedBox(height: 8),
      Text(
        context.tr(
          'Ücretsiz kullanım sınırlıdır; istek ve token kotaları projene göre değişir. Ücretli bir proje anahtarı kullanırsan Google ücretlendirebilir. Bağlantı testi kısa bir çeviri isteği gönderir.',
        ),
        style: const TextStyle(fontSize: 12, height: 1.4),
      ),
      TextButton.icon(
        key: const ValueKey('gemini-usage-link'),
        onPressed: () => AppLinks.openWeb(
          context,
          'https://aistudio.google.com/rate-limit?timeRange=last-28-days',
        ),
        icon: const Icon(Icons.data_usage_rounded, size: 16),
        label: Text(context.tr('Google AI Studio kullanım ve limitleri')),
      ),
      const SizedBox(height: 8),
      TextField(
        key: const ValueKey('gemini-api-key'),
        controller: _keyController,
        enabled: !_busy,
        obscureText: _obscured,
        autocorrect: false,
        enableSuggestions: false,
        enableIMEPersonalizedLearning: false,
        decoration: InputDecoration(
          labelText: context.tr('Gemini API anahtarı'),
          hintText: widget.hasKey
              ? context.tr('Anahtar kayıtlı • değiştirmek için yaz')
              : null,
          helperText: context.tr('Anahtar yalnızca cihazda şifreli saklanır.'),
          helperMaxLines: 3,
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            tooltip: context.tr(
              _obscured ? 'Anahtarı göster' : 'Anahtarı gizle',
            ),
            onPressed: _busy
                ? null
                : () => setState(() => _obscured = !_obscured),
            icon: Icon(
              _obscured
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: [
          FilledButton.tonalIcon(
            key: const ValueKey('gemini-save-key'),
            onPressed: _busy ? null : () => _run(),
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_done_outlined, size: 18),
            label: Text(context.tr('Test et ve ekle')),
          ),
          if (widget.hasKey)
            TextButton(
              onPressed: _busy ? null : () => _run(clear: true),
              child: Text(
                context.tr(
                  _savedKeys.length > 1
                      ? 'Tüm anahtarları sil'
                      : 'Anahtarı sil',
                ),
              ),
            ),
        ],
      ),
      if (_status != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            context.trMessage(_status!),
            style: TextStyle(
              fontSize: 12,
              color: _failed
                  ? const Color(0xFFFFC56D)
                  : const Color(0xFF71E3BC),
            ),
          ),
        ),
    ],
  );
}
