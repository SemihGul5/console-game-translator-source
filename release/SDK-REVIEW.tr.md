# Birleşik APK için açık kalan SDK lisans incelemesi

Tarih: 6 Kasım 2026. Bu inceleme kullanılan bağımlılıkların gerçek derleme
bildirimlerine dayanır. `maven-dependencies.json`, public kopyanın
`releaseRuntimeClasspath` raporundan çıkarılan 165 koordinatı ve yerelde bulunan
POM lisans alanlarını kaydeder. 93 bileşenin mevcut source JAR'ı ayrıca pakettedir.

ML Kit `text-recognition:16.0.1` POM'u lisansı açıkça **ML Kit Terms of Service**
olarak belirtir. Google koşulları SDK/ilişkili yazılım için AGPL'den farklı şartlar
içerir. Derlemede ayrıca Google Play hizmetleri, Google kimlik/giriş, Billing ve
bazı Firebase geçişli bileşenleri için Google/Android SDK koşullarına atıflar
bulunur. JSON'daki `restrictedTermsReviewRequired` alanı bu bileşenleri işaretler;
otomatik hukuki hüküm değildir. Kaynak kodu bulunan bir üst katman veya Apache
lisanslı örnek, kapalı SDK'nın aynı lisansa sahip olduğunu göstermez.

Chiaki'nin ek izni OpenSSL içindir. Bu izinle ML Kit veya diğer kapalı SDK'lar
için yeni bir bağlantı/dağıtım istisnası oluşturulmadı. Uygulamaya özgü kaynakları
AGPL ile sunmak üçüncü taraf SDK koşullarını değiştirmez. Bu sebeple mevcut
birleşik APK için doğrulanmış bir dağıtım dayanağı açık kalmaktadır.

Yayın öncesi ilgili lisans/izin dayanağını doğrulamak veya uyumlu bileşenlerle
dağıtım yapmak gerekir. Bu paket çalışan uygulamada böyle bir değişiklik yapmaz.
Kaynak paketi hazırlanmış olması, lisans sorununun tamamen çözüldüğü veya
mağazanın bütün koşullarının karşılandığı beyanı değildir.

Bağımsız servis altyapısı, veritabanları, imzalama anahtarları ve üretim sırları
pakette değildir. Ayrı HTTP hizmeti kullanmak tek başına bütün sunucu deposunu
AGPL kapsamına sokmaz; sunucu tarafında kapsanan kod kullanımı varsa ayrıca
incelenir. Bu pakette uygulamanın istemci arayüzleri/istekleri korunmuştur.

Kaynaklar: [Chiaki lisansı, 1/5/6 ve OpenSSL ek izni](https://github.com/chiaki-ng/chiaki-ng/blob/v1.10.0/COPYING),
[ML Kit koşulları](https://developers.google.com/ml-kit/terms),
[Google API koşulları](https://developers.google.com/terms).
