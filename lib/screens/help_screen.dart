import '../l10n/app_localizations.dart';
import 'package:flutter/material.dart';

const _background = Color(0xFF090D18);
const _panel = Color(0xFF131A2B);
const _cyan = Color(0xFF4DE2D0);
const _muted = Color(0xFF929DB4);

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _questions = <_HelpQuestion>[
    _HelpQuestion(
      'LG webOS veya Samsung Tizen TV kullanabilir miyim?',
      'TV eşleştirme ekranında LG webOS veya Samsung Tizen seç. LG, IP adresi ve TV’de izin onayıyla bildirim modunu kullanır; konum ve yazı biçimini TV belirler. Samsung, bilgisayardan kurulan ayrı Tizen alıcısını ve HDMI + örnek altyazı testini gerektirir. Sorun yaşarsan TV modelini ve ekran görüntüsünü destek ekibimize gönder. Philips ve Sony Android TV / Google TV cihazlarında mevcut Android TV seçeneğini kullan.',
    ),
    _HelpQuestion(
      "PS5’im bulunmuyor veya bağlanmıyor. Ne yapmalıyım?",
      "Telefon ve PS5 aynı yerel ağda olmalı; PS5 Ethernet, telefon Wi-Fi kullanabilir. Konsolu açıp Remote Play’i etkinleştir. Ağda bulunmazsa PS5’in Ayarlar → Ağ → Bağlantı Durumu bölümündeki IP adresini elle gir. Kayıtta kullandığın PSN hesabı konsolda kullanıcı olarak da ekli olmalı. Cihazı Bağla ekranındaki güncel 8 haneli PIN ile tekrar dene.",
    ),
    _HelpQuestion(
      "PS5 bağlı görünüyor ama telefondaki görüntü siyah. Ne yapmalıyım?",
      "Mobil görüntüyü gizlediysen Görüntüyü göster’e dokun. Ana sayfada olmak veya önizlemeyi gizlemek çeviriyi durdurmaz. Önizleme açıkken de görüntü yoksa PS5 kartından Remote Play’e dön; bağlantı veya görüntü yenileniyorsa bekle. Sorun sürerse çeviriyi durdurup yeniden başlat. PS5’te bağlantı bildirimi görünmesi tek başına video akışının hazır olduğunu göstermez.",
    ),
    _HelpQuestion(
      "Uygulamadaki PS5 görüntüsü nereden geliyor?",
      "Telefondaki görüntü PS5’ten Remote Play ile alınan canlı akıştır. OCR, bu görüntüde seçtiğin alanlardaki metni okur. TV’de PS5’in HDMI girişini izlersin; çevrilen altyazıyı Android TV uygulaması bu görüntünün üzerinde gösterir.",
    ),
    _HelpQuestion(
      "Altyazıları PS5’in HDMI görüntüsünde göstermek için ne gerekli?",
      "Telefon uygulaması, PS5 ve AnlaOyna TV uygulamasını çalıştırabilen bir Android TV gerekir. TV uygulamasına diğer uygulamaların üzerinde gösterim izni ver, telefonu TV ile eşleştir ve telefonda çeviriyi başlat. TV’de altyazı gösterimi açık olmalı. Sonra PS5’in bağlı olduğu HDMI girişine geç. HDMI üzerinde gösterim desteği TV’nin sistemine bağlıdır.",
    ),
    _HelpQuestion(
      "Telefon oyun görüntüsünü TV’ye gönderiyor mu?",
      "Hayır. Oyun görüntüsü PS5’in HDMI bağlantısından gelir. Telefon, Remote Play görüntüsünü metni okumak için kullanır; TV’ye çevrilmiş altyazı metnini ve görünüm ayarlarını gönderir. TV uygulaması bu metni ayrı bir katmanda gösterir.",
    ),
    _HelpQuestion(
      "Uygulama arka plandayken veya telefonun ekranı kapalıyken çeviri devam eder mi?",
      "Evet. Çeviriyi Başlat’tan sonra Remote Play ve OCR arka planda çalışır; uygulama ana sayfaya döner. Başka bir uygulamaya geçebilir veya ekranı kapatabilirsin. Bildirimlere izin vererek çeviri durumunu takip edebilirsin. Kesinti olursa uygulamaya dönüp PS5 ve TV bağlantısını kontrol et; telefonun pil ayarlarında uygulamanın arka plan çalışmasını kısıtlamadığından emin ol. Zorla durdurma işlemi oturumu sonlandırır.",
    ),
    _HelpQuestion(
      "Çeviriyi Başlat’a bastığımda neden başlamıyor?",
      "PS5 kaydı hazır, Android TV bağlı ve seçili modelin dil paketleri indirilmiş olmalı. Ayrıca Google hesabınla giriş yapıp kullanılabilir deneme süresine veya Premium erişime sahip olmalısın. Ekrandaki hata mesajına göre eksik adımı tamamla. PS5 yeniden bağlanıyorsa bekle; başarısız olursa bağlantıları kontrol edip tekrar dene.",
    ),
    _HelpQuestion(
      "Altyazılar TV’de görünmüyor. Neleri kontrol etmeliyim?",
      "Telefondaki Android TV kartında Bağlı yazdığını ve çevirinin çalıştığını kontrol et. TV uygulamasında İzin ver ile üstte gösterim iznini ver; izin zaten açıksa Altyazıyı aç / yenile’yi kullan. Altyazılar duraklatılmışsa Altyazıları sürdür’e bas. Oyundaki metin sarı OCR alanında olmalı. TV’yi PS5’in HDMI girişine al; sorun sürerse TV uygulamasını yeniden açıp bağlantı durumuna bak.",
    ),
    _HelpQuestion(
      "OCR metni yanlış okuyor veya geç algılıyor. Ne yapabilirim?",
      "Altyazı → Altyazı görünümü bölümünde sarı OCR alanını yalnızca okunacak metni tam kapsayacak şekilde ayarla. Konuşma altyazılarında diyalog filtresini deneyebilir, görev ve menü yazılarında kapalı tutabilirsin. Ön işleme ve ölçek ayarları her OCR alanı için ayrıdır; küçük yazıda 1,5× veya 2× ölçeği dene. Oyundaki altyazı arka planını açmak ve yazıyı büyütmek de okumayı iyileştirebilir.",
    ),
    _HelpQuestion(
      "İstediğim dil neden kaynak veya hedef listesinde görünmüyor?",
      "Dil menüleri seçili model için indirilen paketleri gösterir. Ana sayfada Dilleri görüntüle ve indir’i açıp desteklenen dillerden gerekenleri indir. Model A’da kaynak dil İngilizcedir; hedef dil paketini seçersin. Model B’de kaynak ve hedef paketleri ayrı gerekir. Bir modelin listesinde bulunmayan dil için diğer modelin desteklediği dilleri kontrol et.",
    ),
    _HelpQuestion(
      "Model A ve Model B arasındaki fark nedir?",
      "Model A daha yavaş çalışır ancak daha doğru ve kaliteli çeviriler sunar. Model B daha hızlıdır; çevirileri zaman zaman daha az isabetli olabilir. Kalite önceliğinse Model A’yı, hız önceliğinse Model B’yi tercih edebilirsin.",
    ),
    _HelpQuestion(
      "Altyazı sekmesindeki Oyun Kütüphanesi ne işe yarar?",
      "Oyun Kütüphanesi, oyununa özel hazır çevirilerle hikâyeyi daha rahat takip etmene yardımcı olur. En iyi deneyim için oyunun listede varsa Altyazı sekmesindeki Oyun Kütüphanesi bölümünden seç.",
    ),
    _HelpQuestion(
      "Uygulamaya döndüğümde PS5’i yeniden kaydetmem gerekir mi?",
      "Hayır. Oturum sürüyorsa mevcut Remote Play bağlantısı kullanılır. Beklenmedik kopmalarda uygulama yeniden bağlanmayı dener; PS5 kartında yeniden bağlanma veya görüntü yenileme durumunu görebilirsin. Denemeler sonuç vermezse konsolun ve ağın açık olduğunu kontrol edip çeviriyi tekrar başlat. PS5’i listeden kaldırmadığın sürece tekrar kayıt gerekmez.",
    ),
    _HelpQuestion(
      "Çeviriyi durdurunca PS5 kaydı veya TV eşleştirmesi silinir mi?",
      "Hayır. Çeviriyi Durdur, Remote Play ve çeviri akışını durdurup TV’deki mevcut altyazıyı temizler. Kayıtlı PS5, TV eşleştirmesi, dil paketleri ve altyazı ayarları korunur. PS5’i listeden kaldırmak ayrı bir işlemdir; TV eşleştirmesi de TV uygulamasındaki sıfırlama işlemiyle ayrıca yenilenir.",
    ),
    _HelpQuestion(
      "TV eşleştirme kodu veya bağlantısı çalışmıyor. Ne yapmalıyım?",
      "İlk eşleştirmede TV uygulamasını aç; TV ve telefonu aynı yerel ağa bağla. TV’yi ağda bul ile TV’yi seç veya ekrandaki adresi elle gir, ardından güncel 6 haneli kodu kullan. Kimlik doğrulama ekranı açılırsa değeri TV’deki Güvenli bağlantı kimliği ile karşılaştır. Daha önce eşleşmiş TV bağlanmıyorsa TV uygulamasını yeniden açıp tekrar dene; eşleştirme sıfırlandıysa yeniden eşleştir.",
    ),
    _HelpQuestion(
      "PSN bağlantısında hangi hesabı ve hangi yönlendirme adresini kullanmalıyım?",
      "Remote Play için yeni veya kullanmadığın ayrı bir PSN hesabı kullan ve bu hesabı PS5’e kullanıcı olarak ekle; oyunu ana hesabında oynarsın. PSN ile giriş yap’tan sonra açılan beyaz redirect sayfasında adres çubuğundaki bağlantının tamamını kopyala. Uygulamada Yönlendirme URL’si alanına yapıştırıp PSN hesabını doğrula’ya bas. Kod geçersiz veya kullanılmışsa giriş işlemini yeniden başlatıp yeni adresi kopyala.",
    ),
    _HelpQuestion(
      "Çeviri için internet gerekli mi?",
      "OCR ve indirilmiş modellerle metin çevirisi telefonda yapılır; metin çevirisi için buluta gönderilmez. Ancak ilk kurulum, Google/PSN girişi, dil veya Oyun Kütüphanesi üzerinden çeviri indirme, erişim ve satın alma doğrulamaları için internet gerekir. Kullanım sırasında telefon, PS5 ve TV’nin aynı yerel ağdaki bağlantısı sürmelidir; uygulamanın bütünü için tamamen çevrimdışı çalışma garantisi yoktur.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(title: Text(context.tr("Sık Sorulan Sorular"))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
        children: [
          Text(
            context.tr("Yanıtları görmek için bir soruya dokun."),
            style: TextStyle(color: _muted, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 10),
          for (final question in _questions)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: _panel,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFF293249)),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                  splashColor: _cyan.withValues(alpha: 0.08),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 15),
                  childrenPadding: const EdgeInsets.fromLTRB(15, 0, 15, 16),
                  iconColor: _cyan,
                  collapsedIconColor: _muted,
                  title: Text(
                    context.tr(question.title),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        context.tr(question.answer),
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HelpQuestion {
  const _HelpQuestion(this.title, this.answer);

  final String title;
  final String answer;
}
