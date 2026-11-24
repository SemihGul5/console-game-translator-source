import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../app_branding.dart';
import '../services/translation_cache_service.dart';
import '../widgets/settings_section.dart';

class TranslationCacheScreen extends StatefulWidget {
  const TranslationCacheScreen({
    super.key,
    this.service = const TranslationCacheService(),
  });
  final TranslationCacheService service;

  @override
  State<TranslationCacheScreen> createState() => _TranslationCacheScreenState();
}

class _TranslationCacheScreenState extends State<TranslationCacheScreen>
    with WidgetsBindingObserver {
  Map<String, dynamic>? _status;
  TranslationCachePolicy _draft = const TranslationCachePolicy();
  bool _busy = false;
  bool _reviewingImport = false;
  bool _reviewingContribution = false;
  bool _failed = false;
  String? _message;
  bool get _running => _status?['translationRunning'] == true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy) _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _apply(Map<String, dynamic> status, {bool updateDraft = true}) {
    if (status['policy'] is! Map || status['providers'] is! List) {
      throw const FormatException('Cache status unavailable');
    }
    if (updateDraft || _status == null) {
      _draft = TranslationCachePolicy.fromMap(status['policy'] as Map);
    }
    _status = status;
  }

  Future<void> _load() async {
    await _perform(() async {
      final status = await widget.service.status();
      if (mounted) setState(() => _apply(status, updateDraft: false));
    });
  }

  Future<void> _perform(
    Future<void> Function() action, {
    String? success,
  }) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
      _message = null;
    });
    try {
      await action();
      if (mounted && success != null) setState(() => _message = success);
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() {
          _failed = true;
          _message =
              error.message ??
              'Önbellek işlemi tamamlanamadı. Dosyayı ve kullanılabilir alanı kontrol et.';
        });
      }
    } on MissingPluginException {
      if (mounted) {
        setState(() {
          _failed = true;
          _message = 'Önbellek yönetimi bu platformda kullanılamıyor.';
        });
      }
    } on FormatException {
      if (mounted) {
        setState(() {
          _failed = true;
          _message = 'Önbellek bilgileri alınamadı. Tekrar dene.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save({bool reset = false}) => _perform(() async {
    final status = reset
        ? await widget.service.reset()
        : await widget.service.save(_draft);
    if (mounted) setState(() => _apply(status));
  }, success: 'Önbellek sınırları kaydedildi.');

  Future<void> _clear(String provider, String label) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(context.tr('{0} önbelleği temizlensin mi?', [label])),
        content: Text(
          context.tr(
            'Kaydedilmiş çeviriler kaldırılır. Aynı metinler için yeniden çeviri isteği gerekebilir.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('Vazgeç')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('Temizle')),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    await _perform(() async {
      final status = await widget.service.clear(provider);
      if (mounted) setState(() => _apply(status));
    }, success: 'Seçilen önbellek temizlendi.');
  }

  Future<void> _export() => _perform(() async {
    final result = await widget.service.export();
    if (mounted && result['cancelled'] != true) {
      setState(() => _message = 'Önbellek dosyası kaydedildi.');
    }
  });

  Future<void> _import() => _perform(() async {
    try {
      final preview = await widget.service.previewImport();
      if (preview['cancelled'] == true || !mounted) return;
      final token = preview['token'] as String?;
      if (token == null) throw const FormatException('Missing import token');
      setState(() => _reviewingImport = true);
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          scrollable: true,
          title: Text(context.tr('Önbelleği içeri aktar')),
          content: Text(
            context.tr(
              'Geçerli kayıt: {0}\nSüresi dolmuş veya ileri tarihli: {1}\nDosya içindeki tekrarlar: {2}\n\nMevcut kayıtlarla birleştirilir; aynı çevirinin en yenisi korunur. Seçtiğin saklama sınırları uygulanır.',
              [preview['valid'], preview['expired'], preview['duplicates']],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.tr('Vazgeç')),
            ),
            FilledButton(
              key: const ValueKey('cache-confirm-import'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.tr('İçeri aktar')),
            ),
          ],
        ),
      );
      if (mounted) setState(() => _reviewingImport = false);
      if (accepted != true || !mounted) return;
      final status = await widget.service.commitImport(token);
      if (mounted) {
        setState(() {
          _apply(status);
          _message = 'Önbellek içeri alındı.';
        });
      }
    } finally {
      if (mounted && _reviewingImport) setState(() => _reviewingImport = false);
      await widget.service.cancelImport();
    }
  });

  Future<void> _contribute() => _perform(() async {
    String? token;
    try {
      final prepared = await widget.service.prepareContribution();
      token = prepared['token'] as String?;
      if (!mounted) return;
      if (token == null) throw const FormatException('Missing contribution');
      if ((prepared['count'] as num? ?? 0) <= 0) {
        setState(() => _message = 'Paylaşılacak çeviri kaydı yok.');
        return;
      }
      setState(() => _reviewingContribution = true);
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          scrollable: true,
          title: Text(context.tr('Geliştiriciye gönder')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(
                  'Dosyada yalnızca çeviri kayıtları bulunur; API anahtarların ve uygulama hesabı bilgilerin eklenmez. Paylaştığın kayıtlar uygulamayı geliştirmek için kullanılır.',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.tr('{0} kayıt • {1} MiB\nAlıcı: {2}', [
                  prepared['count'],
                  ((prepared['bytes'] as num).toDouble() / (1024 * 1024))
                      .toStringAsFixed(2),
                  prepared['recipient'],
                ]),
              ),
              const SizedBox(height: 12),
              Text(
                context.tr(
                  'Dosyayı açılan e-postanın ekinden inceleyebilirsin. Gönderimi e-posta uygulamasında sen tamamlarsın.',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.tr('Vazgeç')),
            ),
            FilledButton(
              key: const ValueKey('cache-confirm-contribution'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.tr('E-posta taslağını aç')),
            ),
          ],
        ),
      );
      if (mounted) setState(() => _reviewingContribution = false);
      if (accepted != true || !mounted) return;
      final subject = context.tr('{0} - Çeviri kaydı katkısı', [
        AppBranding.nameOf(context),
      ]);
      final body = context.tr(
        'Çeviri kayıtlarını uygulamanın geliştirilmesi amacıyla isteğe bağlı olarak paylaşıyorum.\n\nÇeviri dosyası ektedir.',
      );
      final result = await widget.service.openContributionDraft(
        token: token,
        subject: subject,
        body: body,
        chooserTitle: context.tr('E-posta uygulaması seç'),
      );
      if (mounted && result['opened'] == true) {
        setState(
          () =>
              _message = 'Gönderimi e-posta uygulamasından tamamlayabilirsin.',
        );
      }
    } finally {
      if (mounted && _reviewingContribution) {
        setState(() => _reviewingContribution = false);
      }
      if (token != null) await widget.service.discardContribution(token);
    }
  });

  Widget _choice({
    required String keyName,
    required String label,
    required int value,
    required List<int> options,
    required String template,
    required ValueChanged<int> select,
  }) {
    final values = {...options, value}.toList()..sort();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<int>(
        key: ValueKey('$keyName-$value'),
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: context.tr(label),
          border: const OutlineInputBorder(),
        ),
        items: values
            .map(
              (number) => DropdownMenuItem(
                value: number,
                child: Text(context.tr(template, [number])),
              ),
            )
            .toList(),
        onChanged: _busy || _running
            ? null
            : (next) {
                if (next != null) select(next);
              },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0B1020),
    appBar: AppBar(
      title: Text(context.tr('Çeviri önbelleği')),
      actions: [
        IconButton(
          key: const ValueKey('cache-refresh'),
          tooltip: context.tr('Yenile'),
          onPressed: _busy ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          context.tr(
            'Gemini ve DeepL çevirilerini cihazında sakla; tekrar eden altyazılarda API isteğini azalt.',
          ),
          style: const TextStyle(color: settingsMuted, height: 1.4),
        ),
        const SizedBox(height: 18),
        if (_busy && !_reviewingImport && !_reviewingContribution)
          const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: LinearProgressIndicator(),
          ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              context.trMessage(_message!),
              key: const ValueKey('cache-message'),
              style: TextStyle(
                color: _failed ? const Color(0xFFFFC56D) : settingsAccent,
              ),
            ),
          ),
        if (_status != null) ...[
          if (_running)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                context.tr('Önbelleği değiştirmeden önce çeviriyi durdur.'),
                style: const TextStyle(color: Color(0xFFFFC56D)),
              ),
            ),
          SettingsSection(
            title: context.tr('Kayıtlı çeviriler'),
            children: [
              for (final row
                  in (_status!['providers'] as List).whereType<Map>())
                ListTile(
                  title: Text(row['provider'] == 'gemini' ? 'Gemini' : 'DeepL'),
                  subtitle: Text(
                    context.tr('{0} çeviri • {1} MiB', [
                      row['count'],
                      ((row['bytes'] as num).toDouble() / (1024 * 1024))
                          .toStringAsFixed(2),
                    ]),
                  ),
                  trailing: IconButton(
                    key: ValueKey('cache-clear-${row['provider']}'),
                    tooltip: context.tr('Önbelleği temizle'),
                    onPressed: _busy || _running
                        ? null
                        : () => _clear(
                            row['provider'] as String,
                            row['provider'] == 'gemini' ? 'Gemini' : 'DeepL',
                          ),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ),
            ],
          ),
          Text(
            context.tr('Her sağlayıcı için saklama sınırları'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          _choice(
            keyName: 'cache-days',
            label: 'Saklama süresi',
            value: _draft.days,
            options: const [7, 30, 60, 90, 180],
            template: '{0} gün',
            select: (next) => setState(
              () => _draft = TranslationCachePolicy(
                days: next,
                maxEntries: _draft.maxEntries,
                maxMiB: _draft.maxMiB,
              ),
            ),
          ),
          _choice(
            keyName: 'cache-count',
            label: 'En fazla çeviri',
            value: _draft.maxEntries,
            options: const [1000, 5000, 10000, 20000, 50000],
            template: '{0} çeviri',
            select: (next) => setState(
              () => _draft = TranslationCachePolicy(
                days: _draft.days,
                maxEntries: next,
                maxMiB: _draft.maxMiB,
              ),
            ),
          ),
          _choice(
            keyName: 'cache-size',
            label: 'En fazla alan',
            value: _draft.maxMiB,
            options: const [4, 8, 16, 32],
            template: '{0} MiB',
            select: (next) => setState(
              () => _draft = TranslationCachePolicy(
                days: _draft.days,
                maxEntries: _draft.maxEntries,
                maxMiB: next,
              ),
            ),
          ),
          Text(
            context.tr(
              'Gün sınırı kayıt tarihinden hesaplanır. Sınırları azaltmak eski kayıtları kaldırabilir; okumak saklama süresini uzatmaz.',
            ),
            style: const TextStyle(
              fontSize: 12,
              color: settingsMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                key: const ValueKey('cache-save'),
                onPressed: _busy || _running ? null : () => _save(),
                child: Text(context.tr('Sınırları kaydet')),
              ),
              TextButton(
                key: const ValueKey('cache-reset'),
                onPressed: _busy || _running ? null : () => _save(reset: true),
                child: Text(context.tr('Varsayılana dön')),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            context.tr('Yedekle ve geri yükle'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(
              'Dosya altyazı metinlerini içerir; API anahtarlarını ve hesap bilgilerini içermez. İçeri aktarma mevcut kayıtları birleştirir; ayarlarını değiştirmez. Model A/B oturum önbelleği yedeğe dahil değildir.',
            ),
            style: const TextStyle(
              fontSize: 12,
              color: settingsMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: const ValueKey('cache-export'),
                onPressed: _busy ? null : _export,
                icon: const Icon(Icons.upload_file_rounded),
                label: Text(context.tr('Dışarı aktar')),
              ),
              OutlinedButton.icon(
                key: const ValueKey('cache-import'),
                onPressed: _busy || _running ? null : _import,
                icon: const Icon(Icons.file_download_outlined),
                label: Text(context.tr('İçeri aktar')),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            context.tr('Geliştirmeye katkıda bulun'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(
              'İstersen son çevirilerinden bir dosyayı geliştiriciyle paylaşabilirsin. E-posta için en fazla 5.000 kayıt ve 5 MiB hazırlanır.',
            ),
            style: const TextStyle(
              fontSize: 12,
              color: settingsMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              key: const ValueKey('cache-contribute'),
              onPressed: _busy ? null : _contribute,
              icon: const Icon(Icons.mail_outline_rounded),
              label: Text(context.tr('Geliştiriciye gönder')),
            ),
          ),
        ],
      ],
    ),
  );
}
