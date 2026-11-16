import '../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/setup_notice.dart';
import '../services/app_links.dart';

const _background = Color(0xFF090D18);
const _panel = Color(0xFF131A2B);
const _accent = Color(0xFF0070D1);
const _cyan = Color(0xFF4DE2D0);
const _muted = Color(0xFF929DB4);

class SetupGuideScreen extends StatefulWidget {
  static const totalSteps = 8;

  const SetupGuideScreen({
    required this.ps5Ready,
    required this.tvReady,
    required this.onSetupPs5,
    required this.onPairTv,
    super.key,
  });

  final bool ps5Ready;
  final bool tvReady;
  final Future<bool> Function() onSetupPs5;
  final Future<bool> Function() onPairTv;

  @override
  State<SetupGuideScreen> createState() => _SetupGuideScreenState();
}

class _SetupGuideScreenState extends State<SetupGuideScreen> {
  static const _channel = MethodChannel(
    'com.abrebostudio.consolegametranslator/ps5_registration',
  );

  // The card stays hidden until a video URL is added here.
  static const String? _setupVideoUrl = null;
  static const _steps = <_SetupStep>[
    _SetupStep(
      title: "Telefonu, PS5’i ve TV’yi aynı ağa bağla",
      icon: Icons.wifi_rounded,
      details: [
        "Telefon, PS5 ve Android TV aynı yönlendiricinin yerel ağına bağlı olmalı. PS5 veya TV Ethernet, telefon Wi-Fi kullanabilir; misafir ağı ya da cihazları birbirinden ayıran ağ ayarları bağlantıyı engelleyebilir.",
        "İlk kurulumda PS5 ve TV açık olsun. Google/PSN girişi, dil paketleri ve gerekiyorsa Oyun Kütüphanesi üzerinden çeviri indirme işlemleri için internet bağlantını hazır tut.",
      ],
    ),
    _SetupStep(
      title: "PS5’te Remote Play’i etkinleştir",
      icon: Icons.settings_remote_rounded,
      details: [
        "PS5’te Ayarlar → Sistem → Remote Play bölümünü aç ve Remote Play’i Etkinleştir seçeneğini aç.",
        "Dinlenme modundaki konsola bağlanmak istiyorsan Ayarlar → Sistem → Güç Tasarrufu → Dinlenme Modunda Kullanılabilen Özellikler bölümünde İnternete Bağlı Kal ve PS5’in Ağdan Açılmasını Etkinleştir seçeneklerini aç. İlk kayıt için konsolu açık tut.",
      ],
    ),
    _SetupStep(
      title: "PSN hesabını doğrula ve PS5’i kaydet",
      icon: Icons.sports_esports_rounded,
      details: [
        "Önemli: Remote Play için yeni veya kullanmadığın ayrı bir PSN hesabı kullan ve bu hesabı PS5’e kullanıcı olarak ekle. Oyunu kendi ana PSN hesabında oynayacaksın.",
        "Ana sayfadaki PlayStation 5 kartında PS5’i kur’a dokun, ardından PSN ile giriş yap’ı aç. Girişten sonra beyaz redirect sayfasındayken tarayıcının adres çubuğundaki bağlantının tamamını kopyala. Uygulamadaki Yönlendirme URL’si alanına yapıştır ve PSN hesabını doğrula’ya bas.",
        "Sonraki adım: PS5 konsolunu bağla’ya geç. Konsolda Ayarlar → Sistem → Remote Play → Cihazı Bağla’yı aç. Konsolu ağda bul veya IP adresini elle gir; PS5’in gösterdiği güncel 8 haneli PIN’i yazıp PS5 bağlantısını başlat’a dokun.",
        "IP adresini PS5’te Ayarlar → Ağ → Bağlantı Durumu bölümünde bulabilirsin. Kayıt tamamlandığında ana sayfadaki PS5 kartında Hazır görünür. PS5’in kayıt PIN’i, TV’nin 6 haneli eşleştirme kodundan farklıdır.",
      ],
      action: _SetupAction.ps5,
    ),
    _SetupStep(
      title: "Android TV uygulamasını hazırla",
      icon: Icons.tv_rounded,
      requiresTvApp: true,
      details: [
        "TV uygulamasında İzin ver’e bas, İzin ayarlarını aç ile Android’in izin ekranına geç ve diğer uygulamaların üzerinde gösterime izin ver. Uygulamaya dönünce altyazı katmanı hazırlanır. İzin zaten açıksa düğmenin adı Altyazıyı aç / yenile olur.",
        "Altyazı gösterimi duraklatılmışsa Altyazıları sürdür’e bas. Eşleştirmeden sonra TV uygulaması ekranda açık kalmak zorunda değildir; TV açık ve ağa bağlıyken alıcı arka planda çalışabilir. TV yeniden başladıktan veya uygulama zorla durdurulduktan sonra bağlantı kurulmazsa uygulamayı yeniden aç.",
      ],
    ),
    _SetupStep(
      title: "Telefonu TV ile eşleştir",
      icon: Icons.cast_connected_rounded,
      details: [
        "Ana sayfadaki Android TV kartında TV’yi eşleştir’e bas. TV uygulaması açıkken TV’yi ağda bul’u kullan veya TV ekranındaki adresi elle gir. Birden fazla sonuç varsa ekrandaki adresle aynı olanı seç.",
        "TV’deki güncel 6 haneli kodu girip Eşleştir ve bağlan’a dokun. TV kimliğini doğrula ekranı açılırsa telefondaki değerin TV’deki Güvenli bağlantı kimliği ile tamamının eşleştiğini kontrol ederek onayla.",
        "Telefonun Android TV kartında Bağlı durumunu gör. Eşleştirme kayıtlı • TV bağlı değil yazması çeviri için yeterli değildir. Sonraki kullanımda kayıtlı eşleştirme ile yeniden bağlantı denenir; bağlanmazsa TV uygulamasını açıp tekrar dene.",
      ],
      action: _SetupAction.tv,
    ),
    _SetupStep(
      title: "Çeviri modelini ve dil paketlerini hazırla",
      icon: Icons.translate_rounded,
      details: [
        "Ana sayfada Model A veya Model B’yi seç. Model A daha yavaş çalışır ancak daha doğru ve kaliteli çeviriler sunar. Model B daha hızlıdır; çevirileri zaman zaman daha az isabetli olabilir.",
        "Dilleri görüntüle ve indir’i aç. Model A için İngilizceden çevireceğin hedef dil paketini, Model B için kaynak ve hedef dil paketlerini indir. Ardından dil seçimlerini yap; örneğin English → Türkçe. Her modelin paketleri ayrıdır.",
        "Daha hızlı ve kaliteli bir çeviri deneyimi için Altyazı sekmesindeki Oyun Kütüphanesi bölümünden oyununu seç. Hazır oyun çevirileri, hikâyeyi daha doğal ve akıcı biçimde takip etmene yardımcı olur.",
      ],
    ),
    _SetupStep(
      title: "OCR ve altyazı alanlarını ayarla",
      icon: Icons.crop_free_rounded,
      details: [
        "Altyazı sekmesinde Altyazı görünümü’nü aç. Canlı oyun görüntüsünü görmek için PS5 kartından Remote Play’i açabilirsin. Sarı OCR alanını oyundaki metni tam kapsayacak şekilde yerleştir; yalnızca bu alanlardaki metin okunur.",
        "Çevrilmiş metnin yerini, boyutunu ve görünümünü altyazı ayarlarından düzenle. Sarı OCR alanı ile turkuaz altyazı alanı birbirinden bağımsızdır; birden fazla alan ekleyebilir, alanları sürükleyip boyutlandırabilirsin.",
        "Konuşma altyazıları için diyalog filtresini deneyebilirsin; görev ve menü metinlerinde kapalı tut. Ön işleme ve OCR ölçeği her alan için ayrı ayarlanır. Değişiklikler otomatik kaydedilir; Kaydet ile de saklayabilirsin.",
      ],
    ),
    _SetupStep(
      title: "Çeviriyi başlat ve PS5’te oyna",
      icon: Icons.play_circle_outline_rounded,
      details: [
        "Ana sayfada PS5 kaydı hazır, Android TV Bağlı ve dil paketleri indirilmişken Çeviriyi Başlat’a dokun. Google hesabınla giriş yapıp kullanılabilir deneme süresine veya Premium erişime sahip olmalısın.",
        "Remote Play ve çeviri hazır olunca uygulama ana sayfaya döner. İlk kullanımda Alanları ayarla önerisi çıkarsa oyundaki metne göre OCR ve altyazı alanlarını düzenle. Sonradan Altyazı → Altyazı görünümü’nden aynı ayarlara dönebilirsin.",
        "Oyunu ana PSN hesabında oyna ve TV’yi PS5’in HDMI girişine al. TV uygulamasını ekranda açık tutman gerekmez. Telefon arka plandayken veya ekranı kapalıyken çeviri sürebilir; kesinti olursa bağlantıları ve telefonun pil kısıtlamalarını kontrol et.",
        "Bitirirken telefonda Çeviriyi Durdur’a veya çeviri bildirimindeki Durdur’a bas. Remote Play ve çeviri durur; PS5 kaydı, TV eşleştirmesi ve ayarların korunur.",
      ],
    ),
  ];

  late List<bool> _checked;
  bool _loading = true;
  bool _busy = false;
  bool _ps5Ready = false;
  bool _tvReady = false;

  @override
  void initState() {
    super.initState();
    _ps5Ready = widget.ps5Ready;
    _tvReady = widget.tvReady;
    _checked = List<bool>.filled(_steps.length, false);
    _loadChecklist();
  }

  Future<void> _loadChecklist() async {
    try {
      final saved = await _channel.invokeListMethod<bool>('getSetupChecklist');
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < _checked.length; i++) {
          _checked[i] = i < (saved?.length ?? 0) && saved![i];
        }
        _checked[2] = _ps5Ready;
        _checked[4] = _tvReady;
        _loading = false;
      });
      await _persistChecklist();
    } on PlatformException {
      if (mounted) {
        setState(() {
          _checked[2] = _ps5Ready;
          _checked[4] = _tvReady;
          _loading = false;
        });
      }
    }
  }

  Future<void> _persistChecklist() async {
    try {
      await _channel.invokeMethod<void>('saveSetupChecklist', _checked);
    } on PlatformException {
      // Checkboxes remain usable if native persistence is unavailable.
    }
  }

  Future<void> _toggleStep(int index, bool? value) async {
    if (value == null) return;
    setState(() => _checked[index] = value);
    await _persistChecklist();
  }

  Future<void> _runAction(_SetupAction action, int index) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final ready = action == _SetupAction.ps5
          ? await widget.onSetupPs5()
          : await widget.onPairTv();
      if (!mounted) return;
      setState(() {
        if (action == _SetupAction.ps5) {
          _ps5Ready = ready;
        } else {
          _tvReady = ready;
        }
        _checked[index] = ready;
      });
      await _persistChecklist();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  int get _completedCount => _checked.where((checked) => checked).length;

  @override
  Widget build(BuildContext context) {
    final progress = _completedCount / _steps.length;
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        title: Text(context.tr("Kurulum rehberi")),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
                children: [
                  _buildProgress(progress),
                  const SizedBox(height: 14),
                  Material(
                    color: _panel,
                    borderRadius: BorderRadius.circular(18),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      key: const ValueKey('setup-guide-pdf'),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: const Icon(
                        Icons.picture_as_pdf_outlined,
                        color: _cyan,
                      ),
                      title: Text(context.tr('Görsel kurulum rehberi (PDF)')),
                      subtitle: Text(
                        context.tr(
                          'Oklarla adım adım anlatım • Türkçe • PS5 + Android TV / Google TV',
                        ),
                      ),
                      trailing: const Icon(Icons.open_in_new_rounded, size: 20),
                      onTap: () => AppLinks.openSetupGuidePdf(context),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if ((_setupVideoUrl ?? '').trim().isNotEmpty) ...[
                    _buildVideoPlaceholder(),
                    const SizedBox(height: 18),
                  ],
                  Text(
                    context.tr(
                      'Bu rehberdeki TV adımları Android TV içindir. LG webOS ve Samsung Tizen için TV eşleştirme ekranındaki ayrı seçeneği kullan ve kendi TV testini tamamla.',
                    ),
                    style: const TextStyle(color: _muted, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < _steps.length; i++) ...[
                    _buildStep(i),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    context.tr(
                      "İlerleme bu telefonda saklanır. Konsol veya TV bağlantısını kaldırırsan ilgili adımı yeniden tamamlaman gerekir.",
                    ),
                    style: TextStyle(color: _muted, fontSize: 12, height: 1.45),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildProgress(double progress) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF242044), Color(0xFF151C30)],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _accent.withValues(alpha: 0.35)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.checklist_rounded, color: _cyan),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.tr("Kurulum adımları"),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              '$_completedCount / ${_steps.length}',
              style: const TextStyle(color: _cyan, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: Colors.white12,
            color: _cyan,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          context.tr(
            "Adımları sırayla uygula. Tamamladıklarını işaretle; uygulama bağlantı adımlarını kendisi de tanır.",
          ),
          style: TextStyle(color: _muted, fontSize: 12, height: 1.4),
        ),
      ],
    ),
  );

  Widget _buildVideoPlaceholder() => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: _panel,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFF293249)),
    ),
    child: AspectRatio(
      aspectRatio: 16 / 6,
      child: InkWell(
        onTap: _setupVideoUrl == null
            ? null
            : () => launchUrl(Uri.parse(_setupVideoUrl!)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF23203D), Color(0xFF111827)],
                ),
              ),
            ),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _setupVideoUrl == null
                        ? Icons.movie_outlined
                        : Icons.play_circle_fill_rounded,
                    color: _cyan,
                    size: 34,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr("Kurulum videosu"),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _setupVideoUrl == null
                            ? context.tr(
                                "Video hazır olduğunda burada görünecek",
                              )
                            : context.tr("Videoyu izle"),
                        style: const TextStyle(color: _muted, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildStep(int index) {
    final step = _steps[index];
    final actualCompletion =
        (index == 2 && _ps5Ready) || (index == 4 && _tvReady);
    final checked = _checked[index] || actualCompletion;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 14),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: checked
              ? _cyan.withValues(alpha: 0.34)
              : const Color(0xFF293249),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox.adaptive(
                value: checked,
                onChanged: actualCompletion
                    ? null
                    : (value) => _toggleStep(index, value),
                activeColor: _cyan,
                checkColor: _background,
                visualDensity: VisualDensity.compact,
              ),
              Container(
                width: 38,
                height: 38,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: (checked ? _cyan : _accent).withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  step.icon,
                  color: checked ? _cyan : _accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${index + 1}. ${context.tr(step.title)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (step.requiresTvApp)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: TvAppInstallNotice(),
            ),
          for (var i = 0; i < step.details.length; i++)
            Padding(
              padding: const EdgeInsets.only(left: 47, top: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${i + 1}. ',
                    style: const TextStyle(
                      color: _cyan,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      context.tr(step.details[i]),
                      style: TextStyle(
                        color: step.action == _SetupAction.ps5 && i == 0
                            ? Colors.amberAccent
                            : _muted,
                        fontSize: 12,
                        height: 1.5,
                        fontWeight: step.action == _SetupAction.ps5 && i == 0
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (step.action != null) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _runAction(step.action!, index),
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        step.action == _SetupAction.ps5
                            ? Icons.sports_esports_rounded
                            : Icons.cast_connected_rounded,
                      ),
                label: Text(
                  step.action == _SetupAction.ps5
                      ? context.tr("PS5 kurulumunu aç")
                      : context.tr("TV eşleştirmeyi aç"),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _SetupAction { ps5, tv }

class _SetupStep {
  const _SetupStep({
    required this.title,
    required this.icon,
    required this.details,
    this.action,
    this.requiresTvApp = false,
  });

  final String title;
  final IconData icon;
  final List<String> details;
  final _SetupAction? action;
  final bool requiresTvApp;
}
