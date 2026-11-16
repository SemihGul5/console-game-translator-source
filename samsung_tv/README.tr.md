# Samsung Tizen alıcısı

Bu paket Android APK değildir. HDMI üzerinde altyazı gösteren ayrı bir Tizen Web
uygulamasıdır. Kurulumdan sonra HDMI oyun görüntüsünü ve örnek altyazıyı birlikte
kontrol et. Sorun yaşarsan TV modelini, sorunun açıklamasını ve ekran görüntüsünü
abrebostudio@gmail.com adresine gönder; birlikte çözelim.

## Bilgisayardan ilk kurulum

1. Samsung'un Tizen Studio, TV Extensions ve Samsung Certificate Extension
   bileşenlerini kur:
   https://developer.samsung.com/smarttv/develop/getting-started/setting-up-sdk/installing-tv-sdk.html
2. Bilgisayar ve TV aynı yerel ağda olsun. TV'de Apps ekranındayken kumandada
   `12345` gir, Developer Mode'u aç, **bilgisayarın IPv4 adresini** Host PC IP
   alanına yaz ve TV'yi yeniden başlat. Buraya telefonun IP'si yazılmaz.
   https://developer.samsung.com/smarttv/develop/getting-started/using-sdk/tv-device.html
3. Tizen Studio Certificate Manager'da Samsung **TV** sertifika profili oluştur;
   TV'nin DUID bilgisini dağıtıcı sertifikasına ekle. Device Manager üzerinden
   TV'ye bağlanıp "Permit to install applications" seç. Sertifika anahtarlarını
   paylaşma, sonraki güncellemeler için kendi bilgisayarında sakla.
   https://developer.samsung.com/smarttv/develop/getting-started/setting-up-sdk/creating-certificates.html
4. Bu paketi klasöre çıkart. PowerShell'de aşağıdaki komutla kendi sertifika
   profilinle derle ve imzala (SDK yolu farklıysa parametreyle ver):

   ```powershell
   .\package.ps1 -CertificateProfile 'ProfilAdin' -TizenCli 'C:\tizen-studio\tools\ide\bin\tizen.bat'
   ```

5. Tizen Studio'da projeyi içe aktararak veya CLI ile kur ve çalıştır:

   ```powershell
   C:\tizen-studio\tools\sdb.exe devices
   C:\tizen-studio\tools\ide\bin\tizen.bat install -s TV_SERI_NO -n Receiver.wgt -- .\output
   C:\tizen-studio\tools\ide\bin\tizen.bat run -s TV_SERI_NO -p CGTransTV1.Receiver
   ```

   Paket dosyası adı CLI sürümüne göre değişebilir; `output` altındaki gerçek
   `.wgt` adını `-n` parametresine yaz. Developer Mode, sertifika veya kurulum
   hatasını APK yükleyerek çözmeye çalışma. Normal `.wgt` paketleri tüketici
   Samsung TV'lere USB'den kurulamaz.

CLI yönergesi:
https://developer.samsung.com/smarttv/develop/getting-started/using-sdk/command-line-interface.html

## Her kullanımda

Telefonda TV eşleştirme → Samsung Tizen → Yerel oturumu aç. TV alıcısına
**telefonun IPv4:port adresini** ve 6 haneli kodu gir. Kod 2 dakikada sona erer;
5 yanlış denemeden sonra telefonda yeni oturum oluştur. İlk başarılı eşleşme
kodu tüketir. Yeniden bağlantı yalnızca o oturumun bellekteki rastgele anahtarıyla
yapılır; uygulama veya telefon oturumu kapatılırsa yeni kod gerekir.

TV'de PS5'in bağlı HDMI girişini seç, "HDMI + örnek altyazı testi"ne bas.
**Oyunu ve örnek yazıyı aynı anda görüyorsan** onayla. Telefonda bağlantı
tamamlanmadan çeviri başlatılamaz. Alıcı TV'de açık kalmalı; Home veya başka
girişe geçilirse yazılar silinir ve yeniden test gerekir. Geri tuşu ayarları açar.

Bağlantı yalnızca güvenilir ev ağı için tasarlanmıştır ve şifresizdir. TV'ye
yalnızca çevrilmiş metin ve görünüm bilgisi gönderilir; PSN/Google bilgileri veya
oyun görüntüsü gönderilmez. Yerel ağa port yönlendirme yapma.

## Cihaz testi

- HDMI + Türkçe/Unicode altyazı birlikte görünmeli; yanlış HDMI onaylanmamalı.
- Çoklu bölgeler, boyut, renk, konum, arka plan ve durdur/temizle denenmeli.
- HDMI sesi, oyun modu, HDR, VRR, 4K/120Hz ve gecikme aynı oyunla karşılaştırılmalı.
  TVWindow'un kullanılabilmesi bu özelliklerin korunacağını garanti etmez.
- Wi-Fi kesilip gelmeli; TV Home/geri, telefon ekran kapama, en az 30 dakika
  çalışma, telefon/TV yeniden başlatma denenmeli. Kesintide eski yazı kalmamalı.
- Siyah görüntü veya TVWindow izni/desteği hatasında bu mod uyumlu kabul edilmez.

Telefon PS5 Remote Play görüntüsünü OCR için kullanır. TV'den ekran yakalanmaz.
TVWindow API:
https://developer.samsung.com/smarttv/develop/api-references/tizen-web-device-api-references/tvwindow-api.html
