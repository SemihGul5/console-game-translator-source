import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../services/app_links.dart';
import '../services/subtitle_settings_store.dart';

class DeepLSettingsPanel extends StatefulWidget {
  const DeepLSettingsPanel({
    super.key,
    required this.hasKey,
    required this.onChanged,
    this.store = const SubtitleSettingsStore(),
  });

  final bool hasKey;
  final ValueChanged<bool> onChanged;
  final SubtitleSettingsStore store;

  @override
  State<DeepLSettingsPanel> createState() => _DeepLSettingsPanelState();
}

class _DeepLSettingsPanelState extends State<DeepLSettingsPanel> {
  final _keyController = TextEditingController();
  bool _obscured = true;
  bool _busy = false;
  String? _status;
  bool _failed = false;
  int? _usedCharacters;
  int? _characterLimit;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _run({bool clear = false}) async {
    if (_busy) return;
    final key = _keyController.text.trim();
    if (!clear && key.isEmpty && !widget.hasKey) {
      setState(() {
        _status = 'Geçerli bir DeepL API anahtarı gir.';
        _failed = true;
      });
      return;
    }
    setState(() {
      _busy = true;
      _status = null;
      _failed = false;
    });
    try {
      if (clear) {
        await widget.store.clearDeepLApiKey();
      } else if (key.isNotEmpty) {
        await widget.store.saveDeepLApiKey(key);
      } else {
        await widget.store.testDeepLConnection();
      }
      if (!mounted) return;
      _keyController.clear();
      widget.onChanged(!clear);
      _usedCharacters = null;
      _characterLimit = null;
      setState(
        () => _status = clear
            ? 'DeepL anahtarı silindi.'
            : 'DeepL bağlantısı başarılı. Çeviri için hazır.',
      );
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() {
          _status = error.message ?? 'DeepL işlemi tamamlanamadı. Tekrar dene.';
          _failed = true;
        });
      }
    } on MissingPluginException {
      if (mounted) {
        setState(() {
          _status = 'DeepL bu platformda kullanılamıyor.';
          _failed = true;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refreshUsage() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = null;
      _failed = false;
    });
    try {
      final usage = await widget.store.loadDeepLUsage();
      if (!mounted) return;
      final used = usage?['characterCount'];
      final limit = usage?['characterLimit'];
      setState(() {
        if (used is num &&
            limit is num &&
            used.isFinite &&
            limit.isFinite &&
            used >= 0 &&
            limit >= 0) {
          _usedCharacters = used.toInt();
          _characterLimit = limit.toInt();
        } else {
          _failed = true;
          _status = 'DeepL kullanım bilgisi alınamadı. Tekrar dene.';
        }
      });
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() {
          _failed = true;
          _status =
              error.message ?? 'DeepL kullanım bilgisi alınamadı. Tekrar dene.';
        });
      }
    } on MissingPluginException {
      if (mounted) {
        setState(() {
          _failed = true;
          _status = 'DeepL kullanım bilgisi alınamadı. Tekrar dene.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _remainingUsageLabel(BuildContext context) {
    final limit = _characterLimit!;
    if (limit >= 1000000000000) return context.tr('Kalan: Limitsiz');
    final remaining = (limit - _usedCharacters!).clamp(0, limit);
    final percent = (limit == 0 ? 0.0 : remaining * 100 / limit)
        .toStringAsFixed(1);
    final localizedPercent =
        AppLocalizations.of(context).locale.languageCode == 'tr'
        ? percent.replaceAll('.', ',')
        : percent;
    return context.tr('Kalan: {0} karakter (%{1})', [
      remaining,
      localizedPercent,
    ]);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        context.tr(
          'DeepL internet bağlantısı ve kendi API anahtarını gerektirir. Altyazı metinleri çeviri için DeepL’ye gönderilir; kullanım DeepL hesabının kotasından düşer.',
        ),
        style: const TextStyle(fontSize: 12),
      ),
      TextButton.icon(
        key: const ValueKey('deepl-free-api-link'),
        onPressed: () =>
            AppLinks.openWeb(context, 'https://www.deepl.com/en/developers'),
        icon: const Icon(Icons.open_in_new_rounded, size: 16),
        label: Text(context.tr('Ücretsiz DeepL API anahtarı al')),
      ),
      Text(
        context.tr(
          'DeepL’nin sitesinde ücretsiz bir API hesabı oluştur, API anahtarını buraya yapıştır.',
        ),
        style: const TextStyle(fontSize: 12),
      ),
      const SizedBox(height: 12),
      TextField(
        key: const ValueKey('deepl-api-key'),
        controller: _keyController,
        enabled: !_busy,
        obscureText: _obscured,
        autocorrect: false,
        enableSuggestions: false,
        enableIMEPersonalizedLearning: false,
        decoration: InputDecoration(
          labelText: context.tr('DeepL API anahtarı'),
          hintText: widget.hasKey
              ? context.tr('Anahtar kayıtlı • değiştirmek için yaz')
              : null,
          helperText: context.tr(
            'Free / Pro otomatik seçilir. Anahtar cihazda şifreli saklanır.',
          ),
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
            onPressed: _busy ? null : () => _run(),
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_done_outlined, size: 18),
            label: Text(context.tr('Test et ve kaydet')),
          ),
          if (widget.hasKey)
            TextButton.icon(
              onPressed: _busy ? null : _refreshUsage,
              icon: const Icon(Icons.data_usage_rounded, size: 18),
              label: Text(context.tr('Kullanımı göster')),
            ),
          if (widget.hasKey)
            TextButton(
              onPressed: _busy ? null : () => _run(clear: true),
              child: Text(context.tr('Anahtarı sil')),
            ),
        ],
      ),
      if (_usedCharacters != null) ...[
        const SizedBox(height: 8),
        Text(
          context.tr('DeepL hesabı: {0} / {1} karakter', [
            _usedCharacters,
            _characterLimit! >= 1000000000000
                ? context.tr('Limitsiz')
                : _characterLimit,
          ]),
          style: const TextStyle(fontSize: 12),
        ),
        Text(
          _remainingUsageLabel(context),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        Text(
          context.tr('DeepL sayacı birkaç dakika gecikmeli güncellenebilir.'),
          style: const TextStyle(fontSize: 11),
        ),
      ],
      if (_status != null)
        Text(
          context.trMessage(_status!),
          style: TextStyle(
            fontSize: 12,
            color: _failed ? const Color(0xFFFFC56D) : const Color(0xFF4DE2D0),
          ),
        ),
    ],
  );
}
