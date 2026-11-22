> Son elle kaynak guncellemesi: 2026-11-23, surum 1.1.7+20.
> Onceki hazirlik notlari asagida tarihsel olarak korunur. Bu calistirmada ML Kit uyumlulugu
> yayincinin varsayimi olarak kabul edildi. Ikili/kaynak eslesmesi ve yayin baglantilari henuz dogrulanmadi.

# Kaynak paketi ve yayın adımları

Bu klasör ayrı bir public GitHub reposunun köküne konmak üzere hazırlanmıştır.
Ana uygulamanın özel reposu ve geçmişi kapalı kalabilir. Yeni repo oluşturulmadı,
hiçbir dosya internete yüklenmedi ve çalışan uygulama değiştirilmedi.

## Paylaşılacak kapsam

Chiaki'nin uygulamaya JNI ile bağlandığı mevcut yapıda yalnız `chiaki-native/`
veya yalnız JNI dosyalarını paylaşmayı yeterli kabul etmiyoruz. Pakette Flutter
`lib/`, Kotlin/Java, C/C++, arayüzler, gerekli varlıklar ve derleme betikleri
birlikte bulunur. Uygulamaya özgü kaynaklar bu kopyada AGPL v3 ve korunmuş
OpenSSL ek izniyle sunulur. Üçüncü taraf dosyalarının kendi lisansları korunur.

Özel reponun kendisini veya geçmişini açmak gerekmez. Ancak yayımlanacak birleşik
uygulamanın gerekli kaynaklarını bu paketten çıkarmak kaynak yükümlülüğünü
ortadan kaldırmaz. Ticari/ücretli dağıtım mümkündür; kaynaklara erişim ücretsiz olur.

## Gizlilik politikası konusu

AGPL, Chiaki açıklamasının özellikle **gizlilik politikası** başlığı altında
olmasını istemez. Ayrı bir açık kaynak/lisans sayfası kullanılabilir. Pylux'un
[public reposunda](https://github.com/ForWard-Technologies-LLC/Pylux) uygulama
kaynakları, Chiaki atfı ve lisans bulunmaktadır; yalnız gizlilik politikasına
bakarak kaynak yükümlülüğünün olmadığı sonucu çıkarılamaz.

Lisans/telif/garanti bildirimi, lisansa erişim ve açık kaynak bağlantısı ayrıca
sağlanmalıdır. AGPL 0 ve 5(d)'deki uygun arayüz bildirimi koşulları ve istisnası
da kontrol edilmelidir. Bu paket yeni uygulama ekranı eklemez; mevcut uygulamada
uygun bildirim erişiminin tamamlandığı doğrulanmış değildir. Hazır TR/EN metni
`publication/NOTICE.tr-en.txt`, ayrı sayfa taslağı `publication/legal.html` içindedir.
Gizlilik politikasındaki mevcut metin bu görevde kaldırılmadı veya değiştirilmedi.

## Yayın öncesi açık işler

- [ ] **ML Kit lisans dayanağı:** `text-recognition:16.0.1` ve `translate:17.0.3`
  birleşik APK'da kullanılıyor. Google koşulları ayrı kısıtlar içeriyor; Chiaki'nin
  OpenSSL iznini ML Kit izni olarak yorumlayamayız. Uygulanabilir bir izin/lisans
  dayanağını doğrula veya uyumlu alternatif kullan. Bu soru açıkken bu dosya bir
  "bütün lisanslar tamam" onayı değildir. Diğer SDK/model/varlık haklarını da kontrol et.
  `release/SDK-REVIEW.tr.md` ve `release/maven-dependencies.json`, Google Play,
  Billing, kimlik/giriş ve bazı Firebase geçişli bileşenlerindeki ayrı koşulları da listeler.
- [ ] **Son sürümle eşleştir:** Bu anlık kopya `1.0.3+4` çalışma ağacından alındı.
  Mağazaya gidecek gerçek sürümün kaynaklarını aynı şekilde sabitle; APK/AAB SHA-256,
  sürüm kodu/adı, public commit/tag ve kaynak arşiv adresini `release/publication.json`a yaz.
  Eski APK/AAB'yi bu yeni kaynaklarla eşleşmiş gibi gösterme.
- [ ] **Kaynak erişimini yayımla:** Yeni public repoya bu klasörün **içeriğini** koy;
  `source-vX.Y.Z-buildN` gibi bir tag ve indirilebilir kaynak arşivi yayımla. OpenSSL
  arşivini ve diğer dahil kaynakları bu yayının içinde koru. Mağaza/indirme sayfasında
  ikili dosyanın yanında açık bir kaynak bağlantısı ver. AGPL 6(d) için farklı
  sunucudaki kaynaklara açık yönlendirme ve erişilebilirliği sürdürmek gerekir.
- [ ] **Lisans bildirimini erişilebilir yap:** Uygun mevcut yasal bilgi akışına
  telif/garanti/lisans ve ilgili sürümün kaynak bağlantısını ekle. Gizlilik
  politikasını kullanmak zorunlu değildir. Taslaktaki URL yerlerini doldurmadan yayımlama.
- [ ] **Dağıtım koşullarını kontrol et:** Mağaza şartları ve kendi hizmet şartların
  kullanıcıların AGPL kapsamındaki kopyalama/değiştirme/yeniden dağıtma haklarına
  ek kısıt getirmesin. iOS/App Store dağıtımı bu Android paketiyle otomatik çözülmez.

## Anahtarlar ve kopyanın doğrulanması

İmzalama keystore'u/parolaları, `key.properties`, `access.properties`, Firebase
üretim dosyası, App Check debug tokenı, servis hesabı/sunucu sırları, yerel önbellek,
derlenmiş paketler, gerçek oyun sözlükleri ve özel Git geçmişi dışarıda bırakıldı.
Örnek dosyalar yalnız doldurulacak değerler içerir. Mevcut açık HTTPS adresleri ve
protokol/alan adları sır olarak gizlenmedi. İzole TLS test anahtarları ile upstream
test verileri üretim kimlik bilgisi değildir ve raporda ayrı ele alınır.

```powershell
node .\tool\verify_source_release.mjs
```

Dosya envanteri `release/SHA256SUMS`, doğrulama özeti `release/validation.json`.
Hazırlık sırasında orijinal dosyaların SHA-256 karşılaştırması ayrıca yapıldı;
rapordaki `originalFilesUnchanged` bu kontrolü belirtir. Otomatik sır taraması bir
hukuki uygunluk onayı veya bilinmeyen sırlar için mutlak güvence değildir.

## GitHub'a yükleme

GitHub'da boş bir **public** repo oluştur. Bu klasörü ana özel repodan bağımsız
bir dizine kopyala; orada `git init` yap ve sadece bu klasörün içeriğini yükle.
Özel reponun `.git` klasörünü, eski commitlerini veya gizli dosyalarını taşımayın.
`.gitignore` tek başına daha önce eklenmiş sırları geçmişten silmez; bu yüzden temiz
repo ve bu temiz anlık kopya kullanılır. Yükledikten sonra çıkış yapmış tarayıcıyla
kaynak tag'inin ve lisansların indirilebildiğini doğrula.

Dayanaklar: [Chiaki-ng v1.10.0 lisansı, 1/5/6/7/13](https://github.com/chiaki-ng/chiaki-ng/blob/v1.10.0/COPYING),
[ML Kit koşulları](https://developers.google.com/ml-kit/terms),
[GNU lisans SSS](https://www.gnu.org/licenses/gpl-faq.en.html).
