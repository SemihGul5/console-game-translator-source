import 'messages_tv_en.dart';

// English interface messages, keyed by their Turkish source text.
const englishMessages = <String, String>{
  'Bu oyunun çeviri paketi telefonun belleğine sığmadı. Diğer uygulamaları kapatıp tekrar dene.':
      "This game's translation pack did not fit in the phone's memory. Close other apps and try again.",
  'Ücretsiz denemen hazır. Remote Play bağlantısıyla başlar.':
      'Your free trial is ready. It starts when Remote Play connects.',
  'Geliştirmeye katkıda bulun': 'Help improve the app',
  'Geliştiriciye gönder': 'Send to developer',
  'İstersen son çevirilerinden bir dosyayı geliştiriciyle paylaşabilirsin. E-posta için en fazla 5.000 kayıt ve 5 MiB hazırlanır.':
      'You can choose to share a file of recent translations with the developer. Up to 5,000 entries and 5 MiB are prepared for email.',
  'Dosyada yalnızca çeviri kayıtları bulunur; API anahtarların ve uygulama hesabı bilgilerin eklenmez. Paylaştığın kayıtlar uygulamayı geliştirmek için kullanılır.':
      'The file contains only translation records, with no API keys or app account details. Shared records are used to improve the app.',
  '{0} kayıt • {1} MiB\nAlıcı: {2}': '{0} entries • {1} MiB\nTo: {2}',
  'Dosyayı açılan e-postanın ekinden inceleyebilirsin. Gönderimi e-posta uygulamasında sen tamamlarsın.':
      'You can review the attachment in the email draft. You complete sending in your email app.',
  'E-posta taslağını aç': 'Open email draft',
  'E-posta uygulaması seç': 'Choose an email app',
  '{0} - Çeviri kaydı katkısı': '{0} - Translation contribution',
  'Çeviri kayıtlarını uygulamanın geliştirilmesi amacıyla isteğe bağlı olarak paylaşıyorum.\n\nÇeviri dosyası ektedir.':
      'I am voluntarily sharing translation records to help improve the app.\n\nThe translation file is attached.',
  'Paylaşılacak çeviri kaydı yok.':
      'There are no translation records to share.',
  'Gönderimi e-posta uygulamasından tamamlayabilirsin.':
      'You can complete sending in your email app.',
  'E-posta taslağı açılamadı. Önbelleği dışarı aktararak bize gönderebilirsin.':
      'The email draft could not be opened. You can export the cache and send it to us.',
  'E-posta uygulaması bulunamadı. Önbelleği dışarı aktararak abrebostudio@gmail.com adresine gönderebilirsin.':
      'No email app was found. You can export the cache and send it to abrebostudio@gmail.com.',
  'Gelişmiş': 'Advanced',
  'Çeviri önbelleği': 'Translation cache',
  'Saklama sınırları, yedekleme ve temizleme':
      'Retention limits, backup and cleanup',
  'Gemini ve DeepL çevirilerini cihazında sakla; tekrar eden altyazılarda API isteğini azalt.':
      'Keep Gemini and DeepL translations on your device to reduce API requests for repeated subtitles.',
  'Kayıtlı çeviriler': 'Saved translations',
  '{0} çeviri • {1} MiB': '{0} translations • {1} MiB',
  'Her sağlayıcı için saklama sınırları': 'Retention limits per provider',
  'Saklama süresi': 'Retention period',
  'En fazla çeviri': 'Maximum translations',
  'En fazla alan': 'Maximum space',
  '{0} gün': '{0} days',
  '{0} çeviri': '{0} translations',
  '{0} MiB': '{0} MiB',
  'Gün sınırı kayıt tarihinden hesaplanır. Sınırları azaltmak eski kayıtları kaldırabilir; okumak saklama süresini uzatmaz.':
      'Age is measured from the date a translation was saved. Lowering limits can remove older entries; reading an entry does not extend its retention.',
  'Sınırları kaydet': 'Save limits',
  'Varsayılana dön': 'Restore defaults',
  'Yedekle ve geri yükle': 'Backup and restore',
  'Dosya altyazı metinlerini içerir; API anahtarlarını ve hesap bilgilerini içermez. İçeri aktarma mevcut kayıtları birleştirir; ayarlarını değiştirmez. Model A/B oturum önbelleği yedeğe dahil değildir.':
      'The file contains subtitle text, but no API keys or account details. Import merges saved entries without changing your settings. Model A/B session caches are not included.',
  'Dışarı aktar': 'Export',
  'İçeri aktar': 'Import',
  'Önbelleği içeri aktar': 'Import translation cache',
  'Geçerli kayıt: {0}\nSüresi dolmuş veya ileri tarihli: {1}\nDosya içindeki tekrarlar: {2}\n\nMevcut kayıtlarla birleştirilir; aynı çevirinin en yenisi korunur. Seçtiğin saklama sınırları uygulanır.':
      'Valid entries: {0}\nExpired or future-dated: {1}\nDuplicates in the file: {2}\n\nEntries are merged with your cache, keeping the newest version of a translation. Your retention limits still apply.',
  '{0} önbelleği temizlensin mi?': 'Clear the {0} cache?',
  'Kaydedilmiş çeviriler kaldırılır. Aynı metinler için yeniden çeviri isteği gerekebilir.':
      'Saved translations will be removed. Translating the same text again may require another API request.',
  'Önbelleği temizle': 'Clear cache',
  'Önbellek sınırları kaydedildi.': 'Cache limits saved.',
  'Seçilen önbellek temizlendi.': 'Selected cache cleared.',
  'Önbellek dosyası kaydedildi.': 'Cache backup saved.',
  'Önbellek içeri alındı.': 'Cache imported.',
  'Önbellek yönetimi bu platformda kullanılamıyor.':
      'Cache management is unavailable on this platform.',
  'Önbellek bilgileri alınamadı. Tekrar dene.':
      'Cache information could not be loaded. Try again.',
  'Önbelleği değiştirmeden önce çeviriyi durdur.':
      'Stop translation before changing the cache.',
  'Önbellek işleminin tamamlanmasını bekle.':
      'Wait for the cache operation to finish.',
  'Önbellek işlemi tamamlanamadı. Dosyayı ve kullanılabilir alanı kontrol et.':
      'The cache operation could not be completed. Check the file and available storage.',
  'Önce açık dosya seçimini tamamla.':
      'Finish the current file selection first.',
  'Dosya seçimi için uygulamayı aç.': 'Open the app to select a file.',
  'Bu cihazda dosya seçici açılamadı.':
      'The file picker could not be opened on this device.',
  'En fazla 5 anahtar ekleyebilirsin. Bir anahtar sınıra ulaşırsa hazır diğer anahtara geçilir; hepsi bekliyorsa önbellek ve yüklü Model A/B kullanılır.':
      'You can add up to 5 keys. If one reaches its limit, another available key is used. When all keys are waiting, cached translations and installed Model A/B take over.',
  'Aynı Google projesindeki anahtarlar ortak kotayı kullanır. Anahtar eklemek proje kotasını artırmaz; diğer anahtarın da kullanılabilir kotası olmalıdır.':
      'Keys in the same Google project share a quota. Adding a key does not increase the project quota; the other key must also have quota available.',
  'Anahtar {0}': 'Key {0}',
  'Kullanılıyor': 'In use',
  'Bu anahtarı sil': 'Remove this key',
  'Tüm anahtarları sil': 'Remove all keys',
  'Test et ve ekle': 'Test and add',
  'Bu Gemini anahtarı zaten kayıtlı.': 'This Gemini key is already saved.',
  'En fazla 5 Gemini anahtarı kaydedebilirsin.':
      'You can save up to 5 Gemini keys.',
  'Gemini beklerken önce önbellek, ardından bu dil çifti için yüklü Model A veya Model B kullanılır. İkisi de hazırsa Model A seçilir. Yerel paketleri ilgili modelin dil paketleri bölümünden indirebilirsin.':
      'While Gemini waits, cached translations are used first, then an installed Model A or Model B for this language pair. Model A takes priority when both are ready. Download local packs from the corresponding model’s language packs section.',
  'Model A ile yerel çeviri kullanılıyor.':
      'Using Model A for local translation.',
  'Model B ile yerel çeviri kullanılıyor.':
      'Using Model B for local translation.',
  'Bu dil çifti için yerel paket yüklü değil. Model A veya B dil paketini indir. Önbellekteki çeviriler kullanılabilir.':
      'No local pack is installed for this language pair. Download a Model A or B language pack. Cached translations remain available.',
  'Yerel paket açılamadı. Model A veya B dil paketini yeniden indir. Önbellekteki çeviriler kullanılabilir.':
      'The local pack could not be opened. Download the Model A or B language pack again. Cached translations remain available.',
  'Yerel paketler kontrol ediliyor.': 'Checking local language packs.',
  'Gemini bekliyor. Model A ile yerel çeviri kullanılıyor.':
      'Gemini is waiting. Using Model A for local translation.',
  'Gemini bekliyor. Model B ile yerel çeviri kullanılıyor.':
      'Gemini is waiting. Using Model B for local translation.',
  'Gemini bekliyor. Bu dil çifti için yerel paket yüklü değil. Model A veya B dil paketini indir. Önbellekteki çeviriler kullanılabilir.':
      'Gemini is waiting. No local pack is installed for this language pair. Download a Model A or B language pack. Cached translations remain available.',
  'Gemini bekliyor. Yerel paket açılamadı. Model A veya B dil paketini yeniden indir. Önbellekteki çeviriler kullanılabilir.':
      'Gemini is waiting. The local pack could not be opened. Download the Model A or B language pack again. Cached translations remain available.',
  'Gemini günlük kotası doldu. Yerel paketler kontrol ediliyor.':
      'Gemini’s daily quota is exhausted. Checking local language packs.',
  'Hemen abone olun': 'Subscribe now',
  'İsterseniz abone olmadan {0} dakika ücretsiz deneyebilirsiniz.':
      'You can also try it free for {0} minutes without subscribing.',
  'Paketleri ve fiyatları görün': 'View plans and prices',
  'Premium paketlerini ve fiyatlarını inceleyebilirsiniz.':
      'Explore Premium plans and prices.',
  'Ücretsiz denemeniz devam ediyor. Kalan süre: {0}.':
      'Your free trial is active. Time remaining: {0}.',
  'Ücretsiz denemeniz sona erdi. Devam etmek için bir paket seçebilirsiniz.':
      'Your free trial has ended. Choose a plan to continue.',
  'Abone olmadan deneyin': 'Try without subscribing',
  'Google hesabınızla {0} dakika ücretsiz deneyebilirsiniz.':
      'Try it free for {0} minutes with your Google account.',
  'Ücretsiz deneme süresi kontrol ediliyor.':
      'Checking the free trial duration.',
  'Gemini hazır. Güncel altyazı bekleniyor.':
      'Gemini is ready. Waiting for the current subtitle.',
  'Gemini bekliyor. {0} sn sonra güncel altyazıyla yeniden denenecek.':
      'Gemini is waiting. It will retry with the current subtitle in {0} seconds.',
  'Gemini (ücretsiz katman)': 'Gemini (free tier)',
  'Gemini 3.5 Flash-Lite': 'Gemini 3.5 Flash-Lite',
  'Ücretsiz Gemini API anahtarı al': 'Get a free Gemini API key',
  'Google AI Studio kullanım ve limitleri': 'Google AI Studio usage and limits',
  'Gemini API anahtarı': 'Gemini API key',
  'Gemini API anahtarı gerekli': 'Gemini API key required',
  'Gemini bölümüne anahtarını girip test et ve kaydet.':
      'Enter your key in the Gemini section, then test and save it.',
  'Gemini internet ve kendi API anahtarını gerektirir. Altyazı metinleri Google’a gönderilir. Ücretsiz katmanda bu içerikler Google ürünlerini geliştirmek için kullanılabilir.':
      'Gemini requires internet access and your own API key. Subtitle text is sent to Google. On the free tier, this content may be used to improve Google products.',
  'Google AI Studio’da Google hesabınla giriş yap, bir proje ve API anahtarı oluştur. Ücretsiz kullanım için projen Free Tier olmalı; faturalandırmayı etkinleştirme. Anahtarı aşağıya yapıştır.':
      'Sign in to Google AI Studio with your Google account, create a project and an API key. For free usage, your project must be on the Free Tier; do not enable billing. Paste your key below.',
  'Ücretsiz kullanım sınırlıdır; istek ve token kotaları projene göre değişir. Ücretli bir proje anahtarı kullanırsan Google ücretlendirebilir. Bağlantı testi kısa bir çeviri isteği gönderir.':
      'Free usage is limited; request and token quotas vary by project. Google may charge if you use a paid project key. The connection test sends one short translation request.',
  'Anahtar yalnızca cihazda şifreli saklanır.':
      'Your key is stored encrypted only on this device.',
  'Geçerli bir Gemini API anahtarı gir.': 'Enter a valid Gemini API key.',
  'Gemini anahtarı silindi.': 'Gemini key deleted.',
  'Gemini bağlantısı başarılı. Çeviri için hazır.':
      'Gemini connection successful. Ready to translate.',
  'Gemini işlemi tamamlanamadı. Tekrar dene.':
      'Could not complete the Gemini operation. Try again.',
  'Gemini bu platformda kullanılamıyor.':
      'Gemini is not available on this platform.',
  'Gemini için metin ve dil seçimini kontrol et.':
      'Check the text and language selection for Gemini.',
  'Gemini bu altyazı için çeviri döndürmedi.':
      'Gemini did not return a translation for this subtitle.',
  'Gemini bu altyazı için tam bir çeviri döndürmedi.':
      'Gemini did not return a complete translation for this subtitle.',
  'Gemini çeviri yanıtı geçersiz.': 'Invalid Gemini translation response.',
  'Gemini bağlantısı kurulamadı. İnternet bağlantını kontrol et.':
      'Could not connect to Gemini. Check your internet connection.',
  'Gemini günlük kotası doldu. Google AI Studio kullanım ekranını kontrol et.':
      'Your Gemini daily quota is exhausted. Check usage in Google AI Studio.',
  'Gemini istek sınırına ulaşıldı. Biraz bekle veya Google AI Studio limitlerini kontrol et.':
      'Gemini rate limit reached. Wait a while or check your Google AI Studio limits.',
  'Gemini API anahtarı kabul edilmedi. Anahtarı ve proje erişimini kontrol et.':
      'Gemini rejected the API key. Check the key and project access.',
  'Gemini isteği kabul edilmedi. API anahtarını, bölge uygunluğunu ve proje ayarlarını kontrol et.':
      'Gemini rejected the request. Check your API key, regional availability and project settings.',
  'Gemini modeli bu projede kullanılamıyor. Google AI Studio erişimini kontrol et.':
      'The Gemini model is unavailable in this project. Check access in Google AI Studio.',
  'Gemini şu anda yanıt veremiyor. Biraz sonra tekrar dene.':
      'Gemini is currently unavailable. Try again shortly.',
  'Gemini anahtarı okunamadı. Anahtarı yeniden gir.':
      'Could not read your Gemini key. Enter it again.',
  'Gemini anahtarı kaydedilemedi. Tekrar dene.':
      'Could not save your Gemini key. Try again.',
  'Ücretsiz dene': 'Try for free',
  'ÜCRETSİZ DENEME': 'FREE TRIAL',
  '{0} dakika ücretsiz çeviri': '{0} minutes of free translation',
  'Google ile {0} dk ücretsiz dene': 'Try {0} minutes free with Google',
  'Ödeme bilgisi gerekmez. Otomatik abonelik başlamaz.':
      'No payment details needed. No automatic subscription.',
  'Premium paketleri': 'Premium plans',
  'Lansmana özel fiyatlar': 'Launch special pricing',
  'İlk çıkışa özel, sınırlı süreli fiyatlar.':
      'Special introductory prices for a limited time.',
  'Görsel kurulum rehberi (PDF)': 'Visual setup guide (PDF)',
  'Oklarla adım adım anlatım • Türkçe • PS5 + Android TV / Google TV':
      'Step-by-step instructions with arrows • Turkish • PS5 + Android TV / Google TV',
  'Oyun iste': 'Request a game',
  '{0} - Oyun isteği': '{0} - Game request',
  'Oyun adı: {0}\nİstenen dil:\nOyun sürümü (PS4 / PS5):\n\nEk not:':
      'Game title: {0}\nRequested language:\nGame edition (PS4 / PS5):\n\nAdditional notes:',
  'İsteği kopyala': 'Copy request',
  'İstek metni kopyalandı.': 'Request text copied.',
  'Altyazı dili': 'Subtitle language',
  'Bu dilde henüz oyun paketi yok.':
      'No game packs are available in this language yet.',
  'Bu seçim arayüz dilini ve oyun kütüphanesindeki dil filtresini belirler.':
      'This sets the interface language and the game library language filter.',
  'Dil değiştirilemez': 'Cannot change language',
  'Dili veya oyunu değiştirmek için çeviriyi durdur.':
      'Stop translation to change the language or game.',
  'Seçili: {0} · {1}': 'Selected: {0} · {1}',
  'Seçili model bu dili desteklemiyor. Yalnızca oyun paketindeki metinler gösterilir.':
      'The selected model does not support this language. Only text from the game pack is shown.',
  'Kullanımı göster': 'Show usage',
  'DeepL (önerilen)': 'DeepL (recommended)',
  'Kalan: {0} karakter (%{1})': 'Remaining: {0} characters ({1}%)',
  'Kalan: Limitsiz': 'Remaining: Unlimited',
  'Ücretsiz DeepL API anahtarı al': 'Get a free DeepL API key',
  'DeepL’nin sitesinde ücretsiz bir API hesabı oluştur, API anahtarını buraya yapıştır.':
      'Create a free API account on DeepL’s website, then paste your API key here.',
  'DeepL hesabı: {0} / {1} karakter': 'DeepL account: {0} / {1} characters',
  'Limitsiz': 'Unlimited',
  'DeepL sayacı birkaç dakika gecikmeli güncellenebilir.':
      'DeepL usage may take a few minutes to update.',
  'DeepL kullanım bilgisi alınamadı. Tekrar dene.':
      'Could not retrieve DeepL usage. Try again.',
  'DeepL API anahtarı': 'DeepL API key',
  'DeepL API anahtarı gerekli': 'DeepL API key required',
  'DeepL bölümüne anahtarını girip test et ve kaydet.':
      'Enter your key in the DeepL section, then test and save it.',
  'DeepL internet bağlantısı ve kendi API anahtarını gerektirir. Altyazı metinleri çeviri için DeepL’ye gönderilir; kullanım DeepL hesabının kotasından düşer.':
      'DeepL requires an internet connection and your own API key. Subtitle text is sent to DeepL for translation and counts toward your DeepL account quota.',
  'Anahtar kayıtlı • değiştirmek için yaz': 'Key saved • type to replace it',
  'Free / Pro otomatik seçilir. Anahtar cihazda şifreli saklanır.':
      'Free / Pro is selected automatically. Your key is stored encrypted on this device.',
  'Anahtarı göster': 'Show key',
  'Anahtarı gizle': 'Hide key',
  'Test et ve kaydet': 'Test and save',
  'Anahtarı sil': 'Delete key',
  'DeepL anahtarı silindi.': 'DeepL key deleted.',
  'DeepL bağlantısı başarılı. Çeviri için hazır.':
      'DeepL connection successful. Ready to translate.',
  'Geçerli bir DeepL API anahtarı gir.': 'Enter a valid DeepL API key.',
  'DeepL API anahtarı kabul edilmedi. Anahtarını kontrol et.':
      'DeepL rejected the API key. Check your key.',
  'DeepL karakter kotası doldu. DeepL hesabını kontrol et.':
      'Your DeepL character quota is exhausted. Check your DeepL account.',
  'DeepL istek sınırına ulaşıldı. Biraz sonra tekrar dene.':
      'DeepL rate limit reached. Try again shortly.',
  'DeepL dil seçimini kontrol et.': 'Check your DeepL language selection.',
  'DeepL şu anda yanıt veremiyor. Biraz sonra tekrar dene.':
      'DeepL is currently unavailable. Try again shortly.',
  'DeepL bağlantısı kurulamadı. İnternet bağlantını kontrol et.':
      'Could not connect to DeepL. Check your internet connection.',
  'DeepL çeviri yanıtı geçersiz.': 'Invalid DeepL translation response.',
  'DeepL anahtarı okunamadı. Anahtarı yeniden gir.':
      'Could not read your DeepL key. Enter it again.',
  'DeepL anahtarı kaydedilemedi. Tekrar dene.':
      'Could not save your DeepL key. Try again.',
  'DeepL işlemi tamamlanamadı. Tekrar dene.':
      'Could not complete the DeepL operation. Try again.',
  'DeepL bu platformda kullanılamıyor.':
      'DeepL is not available on this platform.',
  ...tvEnglishMessages,
  'Her altyazı alanının konumunu ve görünümünü ayrı düzenleyebilirsin. Yeni alanlar varsayılan ayarlarla eklenir.':
      'Edit each subtitle area’s position and appearance independently. New areas start with default settings.',
  'Her OCR alanının konumunu ve tarama ayarlarını ayrı düzenleyebilirsin. Yeni alanlar varsayılan ayarlarla eklenir.':
      'Edit each OCR area’s position and scan settings independently. New areas start with default settings.',
  'OCR {0} tarama sıklığı: {1}': 'OCR {0} scan rate: {1}',
  'Yazı tipi': 'Font',
  'Oyun fontu': 'Game font',
  'Sistem fontu': 'System font',
  'Oyun fontu yoksa sistem fontu kullanılır. Diğer görünüm ve konum ayarların korunur.':
      'Uses the system font when no game font is available. Your other appearance and position settings are preserved.',
  'İndirilen çevirileri sil?': 'Delete the downloaded translations?',
  '{0} oyununun telefondaki çevirileri silinir. Seçiliyse seçim kaldırılır. Oyunu tekrar seçerek çevirileri yeniden indirebilirsin.':
      'The translations for {0} will be removed from this phone. Its selection will also be cleared if selected. Select the game again to download the translations again.',
  'Sil': 'Delete',
  'İndirilen çeviriler silindi.': 'Downloaded translations deleted.',
  'İndirildi': 'Downloaded',
  'Çeviriler silinemedi. Tekrar dene.':
      "Couldn't delete the translations. Try again.",
  "En avantajlı": "Best value",
  "Uzun vadeli kullanım için tek ödeme.": "One payment for long-term use.",
  "Haftalık plana göre %{0} tasarruf":
      "Save {0}% compared with the weekly plan",
  "12 aylık ödemeye göre %{0} tasarruf":
      "Save {0}% compared with 12 monthly payments",
  "Çeviri dosyası indiriliyor…": "Downloading the translation file…",
  "Çeviri belleğe yükleniyor…": "Loading translations into memory…",
  'Oyun listesini yenile': 'Refresh game library',
  'Henüz oyun eklenmedi.': 'No games added yet.',
  'Oyun adıyla ara': 'Search by game name',
  'Aramayı temizle': 'Clear search',
  'Aramana uygun oyun bulunamadı.': 'No games match your search.',
  'Oyun seçilmedi': 'No game selected',
  'Daha hızlı ve doğru çeviri için oyun kütüphanesinde oyunun varsa seç. Listede yoksa oyun seçmeden devam edebilirsin.':
      'For faster, more accurate translations, select your game if it is in the game library. If it is not listed, you can continue without selecting a game.',
  'Seçmeden devam et': 'Continue without a game',
  'Oyun kütüphanesini aç': 'Open game library',
  'Oyun çevirileri hazırlanıyor…': 'Preparing game translations…',
  'Oyun çevirileri yüklenemedi': "Couldn't load game translations",
  'Oyun listesi yenilenemedi. Kayıtlı oyunlarını kullanabilirsin.':
      "Couldn't refresh the game library. Your saved games are still available.",
  'Oyun erişimi doğrulanamadı.': "Couldn't verify access to the game library.",
  'Oyun çeviri dosyası doğrulanamadı.':
      "Couldn't verify the game translation file.",
  'Oyun dosyası indirilemedi.': "Couldn't download the game file.",
  'Oyun dosyası çok büyük.': 'The game file is too large.',
  'Konsol: {0}\n': 'Console: {0}\n',
  'Çevrildi · {0} Yerel': 'Translated · {0} Local',
  "Console Game Translator": "Console Game Translator",
  "Oyun Çevirmeni": "Console Game Translator",
  "Oyununu kendi dilinde yaşa": "Experience your game in your language",
  "Ayar kaydedilemedi": "Couldn't save setting",
  "Uygulama dili": "App language",
  "Uygulamanın arayüzü şu anda Türkçe. Çeviri kaynak ve hedef dilleri ana ekrandaki dil bölümünden seçebilirsin.":
      "Choose the app's interface language. Game translation languages are selected separately on the home screen.",
  "Model C hazır": "Model C is ready",
  "HPLT İngilizce → Türkçe paketi çevrimdışı kullanıma hazır.":
      "The HPLT English → Turkish pack is ready for offline use.",
  "Model C indirilemedi": "Couldn't download Model C",
  "İnternet bağlantını kontrol edip tekrar dene.":
      "Check your internet connection and try again.",
  "Dil paketi hazır": "Language pack is ready",
  "Seçilen hedef dil çevrimdışı kullanıma hazır.":
      "The selected target language is ready for offline use.",
  "Model indirilemedi": "Couldn't download model",
  "İnternet bağlantını kontrol et.": "Check your internet connection.",
  "Dil seçilemedi": "Couldn't select language",
  "Tekrar dene.": "Try again.",
  "Model değiştirilemez": "Can't change model",
  "Çeviri devam ederken model değiştirilemez. Önce çeviriyi durdurup tekrar dene.":
      "You can't change the model while translation is running. Stop translation and try again.",
  "Motor seçilemedi": "Couldn't select engine",
  "Dil çiftine uygun paketi seçip indir.":
      "Select and download the pack for your language pair.",
  "Kurulum henüz tamamlanmadı": "Setup isn't complete yet",
  "{0} / {1} adım tamamlandı": "{0} / {1} steps completed",
  "PS5 ve TV bağlantıların hazır. En iyi deneyim için kurulum rehberindeki eksik adımları tamamlamanı öneririz. İstersen çeviriyi şimdi de başlatabilirsin.":
      "Your PS5 and TV connections are ready. For the best experience, we recommend completing the remaining setup steps. You can also start translating now.",
  "Bir daha gösterme": "Don't show again",
  "Yine de başlat": "Start anyway",
  "Kurulumu tamamla": "Complete setup",
  "Tercih kaydedilemedi. Kurulum uyarısı tekrar görünebilir.":
      "Couldn't save your preference. The setup reminder may appear again.",
  "Android TV’yi eşleştir": "Pair your Android TV",
  "TV açık ve telefonla aynı Wi-Fi ağına bağlı olsun. İlk eşleştirme için TV uygulamasını açıp ekrandaki 6 haneli kodu gir. Eşleştirmeden sonra TV uygulamasını açmadan bağlanabilirsin.":
      "Keep the TV on and connected to the same Wi-Fi network as your phone. For the first pairing, open the TV app and enter the 6-digit code shown on screen. Once paired, you can connect without opening the TV app.",
  "TV bulunamadı. TV’nin açık ve iki cihazın aynı Wi-Fi ağında olduğundan emin ol.":
      "No TV found. Make sure your TV is on and both devices are on the same Wi-Fi network.",
  "Bir TV bulundu.": "One TV found.",
  "{0} TV bulundu. Kendi TV ekranındaki adresle eşleşeni seç.":
      "{0} TVs found. Select the address shown on your TV screen.",
  "Ağ taraması yapılamadı. Aynı Wi-Fi ağını kontrol et.":
      "Couldn't scan the network. Check that both devices are on the same Wi-Fi network.",
  "TV aranıyor…": "Searching for TVs…",
  "TV’yi ağda bul": "Find TV on network",
  "TV ekranındaki adresle eşleşeni seç": "Select the address shown on your TV",
  "TV ekranındaki adres": "Address shown on TV",
  "TV ekranındaki 6 haneli kod": "6-digit code shown on TV",
  "Bağlantıyı iptal et": "Cancel connection",
  "İptal": "Cancel",
  "TV kimliğini doğrula": "Verify TV identity",
  "Bu değer TV ekranındaki “Güvenli bağlantı kimliği” ile aynı mı? Yalnızca tamamı eşleşiyorsa onayla.":
      "Does this match the “Secure connection identity” on your TV screen? Confirm only if the entire value matches.",
  "Eşleşmiyor / İptal": "Doesn't match / Cancel",
  "Tamamı eşleşiyor": "Everything matches",
  "Android TV eşleştirildi. Altyazılar bağlantı açılınca TV’ye gönderilir.":
      "Android TV paired. Subtitles will be sent to the TV once connected.",
  "TV’ye bağlanılamadı. Adres, kod ve aynı Wi-Fi ağını kontrol et.":
      "Couldn't connect to the TV. Check the address, code and Wi-Fi network.",
  "Bağlanıyor…": "Connecting…",
  "Eşleştir ve bağlan": "Pair and connect",
  "Türkçe": "Turkish",
  "Oyun seçilmedi · canlı çeviri kullanılıyor":
      "No game selected · using live translation",
  "Oyun çeviri dosyası yükleniyor…": "Loading game translation file…",
  "Seçili oyun katalogda bulunamadı.":
      "The selected game wasn't found in the catalog.",
  "Oyun kataloğu okunamadı.": "Couldn't read the game catalog.",
  "Oyun çeviri verisi belleğe alınamadı.":
      "Couldn't load game translation data into memory.",
  "{0} seçili": "{0} selected",
  "Unable to load asset": "Unable to load asset",
  "Oyun çeviri dosyası bulunamadı.": "Game translation file not found.",
  "Oyun çeviri verisi okunamadı.": "Couldn't read game translation data.",
  "Seçili modelin dil paketleri okunamadı.":
      "Couldn't read the selected model's language packs.",
  "Dil paketi indirilemedi.": "Couldn't download language pack.",
  "Dil paketi indirilemedi": "Couldn't download language pack",
  "Bağlantını kontrol edip tekrar dene.":
      "Check your connection and try again.",
  "Model C • HPLT v2.0": "Model C • HPLT v2.0",
  "İngilizce → Türkçe • çevrimdışı • yaklaşık 80 MB • 64-bit ARM Android. HPLT v2.0 tabanlı INT8 CTranslate2 paketi.":
      "English → Turkish • offline • about 80 MB • 64-bit ARM Android. INT8 CTranslate2 pack based on HPLT v2.0.",
  "HPLT İngilizce → Türkçe": "HPLT English → Turkish",
  "İndirildi • cihazda hazır": "Downloaded • ready on device",
  "İndirilmedi": "Not downloaded",
  "Hazır": "Ready",
  "İndir": "Download",
  "Atıf: HPLT, translate-en-tr-v2.0-hplt_opus; WindyTranslate INT8 dönüşümü. CC BY 4.0.":
      "Attribution: HPLT, translate-en-tr-v2.0-hplt_opus; WindyTranslate INT8 conversion. CC BY 4.0.",
  "Model A hedef dilleri": "Model A target languages",
  "Model B dilleri": "Model B languages",
  "İngilizceden seçtiğin dile çevrimdışı paket indir.":
      "Download an offline pack to translate from English to your chosen language.",
  "İndirilen diller seçili çeviri motorunda kullanılabilir.":
      "Downloaded languages can be used with the selected translation engine.",
  "Durumu yenile": "Refresh status",
  "Dil seçenekleri yüklenemedi.": "Couldn't load language options.",
  "Yeniden dene": "Try again",
  "İndirildi • İngilizceden kullanılabilir":
      "Downloaded • available from English",
  "İndirilmedi • yaklaşık 20 MB": "Not downloaded • about 20 MB",
  "Seçili": "Selected",
  "Seç": "Select",
  "İndirildi • çeviri seçiminde kullanılabilir":
      "Downloaded • available for translation",
  "Android TV’ye bağlanılıyor": "Connecting to Android TV",
  "Bağlantı tamamlanınca çeviriyi başlatabilirsin.":
      "You can start translating once connected.",
  "Hedef dil paketi gerekli": "Target language pack required",
  "Model A için seçili hedef dil paketini önce indir.":
      "Download the selected target language pack for Model A first.",
  "Model C paketi gerekli": "Model C pack required",
  "HPLT İngilizce → Türkçe paketini önce indir.":
      "Download the HPLT English → Turkish pack first.",
  "Çeviri durdu": "Translation stopped",
  "Remote Play oturumu artık etkin değil.":
      "The Remote Play session is no longer active.",
  "Çeviri durdurulamadı": "Couldn't stop translation",
  "Önce PlayStation 5’i kurup kaydet.":
      "Set up and register your PlayStation 5 first.",
  "Android TV gerekli": "Android TV required",
  "Önce Android TV’yi eşleştirip bağla.":
      "Pair and connect your Android TV first.",
  "Dil paketleri hazırlanamadı": "Couldn't prepare language packs",
  "Çeviri başlatılamadı": "Couldn't start translation",
  "PS5 durumu okunamadı": "Couldn't read PS5 status",
  "Lütfen birkaç saniye sonra tekrar dene.":
      "Please try again in a few seconds.",
  "PS5’e bağlanılıyor": "Connecting to PS5",
  "Bağlantı tamamlanana kadar PS5 kaydını kaldıramazsın. Biraz bekleyip tekrar dene.":
      "You can't remove the PS5 registration while connecting. Wait a moment and try again.",
  "PS5 görüntüsü yenileniyor": "Refreshing PS5 video",
  "Remote Play bağlantısı açık. Görüntü yüzeyi hazırlanıyor.":
      "Remote Play is connected. Preparing the video surface.",
  "Remote Play bağlantısı kesilsin mi?": "Disconnect Remote Play?",
  "PS5’teki Remote Play oturumu ve devam eden çeviri durur. PS5 kaydın korunur; daha sonra yeniden bağlanabilirsin.":
      "The PS5 Remote Play session and current translation will stop. Your PS5 registration will be kept so you can reconnect later.",
  "Bağlantıyı kes": "Disconnect",
  "Remote Play kesildi. PS5 kaydı korundu.":
      "Remote Play disconnected. PS5 registration kept.",
  "Bağlantı kesilemedi": "Couldn't disconnect",
  "Kayıtlı PS5 kaldırılsın mı?": "Remove registered PS5?",
  "Bu işlem telefondaki kayıtlı PS5 ve PSN eşleştirme bilgilerini siler. Tekrar eklemek için Sony hesabını doğrulayıp PS5’i yeniden kaydetmen gerekir. Kurulum genellikle yaklaşık 2–5 dakika sürer; Sony hesabı doğrulaması veya ağ bağlantısı yavaşsa daha uzun sürebilir.\n\nDevam etmek istiyor musun?":
      "This removes the saved PS5 and PSN pairing information from your phone. To add it again, you'll need to verify your Sony account and register your PS5 again. Setup usually takes about 2–5 minutes; Sony account verification or a slow network may take longer.\n\nDo you want to continue?",
  "PS5’i kaldır": "Remove PS5",
  "Remote Play açık": "Remote Play is active",
  "Önce Remote Play bağlantısını kes. PS5 kaydı bağlantı kapandıktan sonra kaldırılabilir.":
      "Disconnect Remote Play first. You can remove the PS5 registration once disconnected.",
  "PS5 kayıtlı cihazlardan kaldırıldı.": "PS5 removed from saved devices.",
  "PS5 kaldırılamadı": "Couldn't remove PS5",
  "Çeviri başladı": "Translation started",
  "Daha doğru sonuç için oyundaki yazıların bulunduğu OCR alanlarını ve çevrilen altyazının ekranda gösterileceği alanı ayarla. Bu ayarlar her oyun görüntüsüne göre değişebilir.":
      "For more accurate results, adjust the OCR areas around the game's text and the area where translated subtitles appear. These settings may vary between games.",
  "Daha sonra": "Later",
  "Alanları ayarla": "Adjust areas",
  "Altyazı": "Subtitles",
  "Ana sayfa": "Home",
  "Profil": "Profile",
  "Ayarlar": "Settings",
  "Oyununu seç, altyazı görünümünü düzenle.":
      "Choose your game and customize your subtitles.",
  "Görünüm ve alanlar": "Appearance and areas",
  "Altyazı görünümü": "Subtitle appearance",
  "Ekran önizlemesi, OCR alanları ve altyazı ayarları":
      "Screen preview, OCR areas and subtitle settings",
  "Yeni veya kullanılmamış PSN hesabı gerekli":
      "A new or unused PSN account is required",
  "Remote Play bağlı": "Remote Play connected",
  "Çeviri açık • görüntü yenileniyor": "Translation on • refreshing video",
  "Çeviri açık • PS5 yeniden bağlanıyor, lütfen bekleyin":
      "Translation on • reconnecting to PS5, please wait",
  "PS5 kaydı hazır": "PS5 registration ready",
  "Kurulu değil": "Not set up",
  "Bağlı": "Connected",
  "Yeniden bağlanıyor": "Reconnecting",
  "Bağlanıyor": "Connecting",
  "Görüntü yenileniyor": "Refreshing video",
  "Lütfen bekleyin": "Please wait",
  "PS5 kaydı kontrol ediliyor…": "Checking PS5 registration…",
  "PS5 açılıyor…": "Opening PS5…",
  "Görüntü yenileniyor…": "Refreshing video…",
  "PS5 yeniden bağlanıyor…": "Reconnecting to PS5…",
  "PS5’e bağlanıyor…": "Connecting to PS5…",
  "Remote Play’e dön": "Return to Remote Play",
  "Remote Play’i aç": "Open Remote Play",
  "PS5’i listeden kaldır": "Remove PS5 from list",
  "Android TV": "Android TV",
  "TV’ye bağlantı kuruluyor": "Connecting to TV",
  "Bağlı • {0}": "Connected • {0}",
  "Şifreli": "Encrypted",
  "Şifresiz": "Unencrypted",
  "Altyazıları TV ekranında göster": "Show subtitles on your TV screen",
  "Eşleştirme kayıtlı • TV bağlı değil": "Pairing saved • TV disconnected",
  "Bağlı değil": "Disconnected",
  "Kontrol ediliyor": "Checking",
  "TV’ye bağlanıyor…": "Connecting to TV…",
  "TV durumu kontrol ediliyor…": "Checking TV status…",
  "TV’yi yeniden eşleştir": "Pair TV again",
  "TV’yi eşleştir": "Pair TV",
  "Tekrar dene": "Try again",
  "{0}  •  OYUNUNA KENDİ DİLİNDE DEVAM ET":
      "{0}  •  KEEP PLAYING IN YOUR LANGUAGE",
  "Kayıtlı": "Saved",
  "ÇEVİRİ DİLLERİ": "TRANSLATION LANGUAGES",
  "Oyun Kütüphanesi": "Game Library",
  "Daha hızlı ve kaliteli bir çeviri deneyimi için oynadığın oyun listede varsa seç.":
      "If your game is listed, select it for a faster, higher-quality translation experience.",
  "Oyun listesi yükleniyor…": "Loading games…",
  'Güncel oyun listesi alınamadı. İnternet bağlantını kontrol edip tekrar dene.':
      'Could not update the game list. Check your internet connection and try again.',
  "seçili": "selected",
  "Oyun seçimini kaldır": "Clear game selection",
  "ÇEVİRİ MODELİ": "TRANSLATION MODEL",
  'En iyi çeviri için Oyun Kütüphanesi’ni öneriyoruz. Oyunun listede yoksa DeepL veya Gemini’yi, bunlara erişimin yoksa yerel modelleri kullanabilirsin.':
      'For the best translation, we recommend the Game Library. If your game is not listed, try DeepL or Gemini. If you cannot access them, use a local model.',
  'Model A - Yerel Kaliteli': 'Model A - Local, High Quality',
  'Model B - Yerel Hızlı': 'Model B - Local, Fast',
  "Önce yaklaşık 80 MB HPLT model paketini indir.":
      "Download the HPLT model pack first (about 80 MB).",
  "İngilizceden seçtiğin hedef dile ait paketi indir.":
      "Download the pack from English to your selected target language.",
  "Seçtiğin kaynak ve hedef dillerin paketlerini indir.":
      "Download packs for your selected source and target languages.",
  "Dilleri görüntüle ve indir": "View and download languages",
  "Bu motor için kaynak dili İngilizce, hedef dili yukarıdaki seçim olmalı.":
      "For this engine, use English as the source and the target language selected above.",
  "Model C yalnızca İngilizce → Türkçe dil çiftiyle çalışır.":
      "Model C only supports English → Turkish.",
  "Diller yükleniyor…": "Loading languages…",
  "durum kontrol ediliyor": "checking status",
  "ÇEVİRİYİ DURDUR": "STOP TRANSLATION",
  "ÇEVİRİYİ BAŞLAT": "START TRANSLATION",
  "Bağlantı hazırlanıyor…": "Preparing connection…",
  "Android TV’ye bağlanılıyor…": "Connecting to Android TV…",
  "Remote Play ve altyazı akışı durdurulur":
      "Stops Remote Play and subtitle streaming",
  "Önce PS5 kurulumunu tamamla": "Complete PS5 setup first",
  "Başlamak için Android TV’yi eşleştir": "Pair your Android TV to get started",
  "PS5’e bağlanır ve altyazılar TV’de başlar":
      "Connects to PS5 and starts subtitles on your TV",
  "Kurulum rehberi": "Setup guide",
  "Oyun kataloğunda \"{0}\" alanı eksik.":
      "The game catalog is missing the “{0}” field.",
  "Hesabını sil": "Delete your account",
  "Uygulamadaki hesabın kalıcı olarak silinir ve oturumun kapatılır. Tekrarlanan denemeleri önleyen bitiş kaydı saklanır. Bu işlem Google Play aboneliğini iptal etmez; aboneliğini Google Play’den yönetebilirsin.":
      "Your app account will be permanently deleted and you'll be signed out. A trial end record is kept to prevent repeated trials. This doesn't cancel your Google Play subscription; you can manage it in Google Play.",
  "Vazgeç": "Cancel",
  "Hesabımı sil": "Delete my account",
  "Hesabın silindi ve oturumun kapatıldı.":
      "Your account has been deleted and you've been signed out.",
  "Sayfa açılamadı. Biraz sonra tekrar dene.":
      "Couldn't open the page. Try again later.",
  "Haftalık": "Weekly",
  "Aylık": "Monthly",
  "Yıllık": "Yearly",
  "Süresiz": "Lifetime",
  "Premium": "Premium",
  "yıl": "year",
  "dönem": "period",
  "Kalan deneme: {0}. Süre Remote Play bağlantısı başladığında kesintisiz işler. Uygulamayı kapatsan da süre devam eder. Otomatik ücret alınmaz.":
      "Trial remaining: {0}. Time runs continuously from the Remote Play connection, even if you close the app. You won't be charged automatically.",
  "Google girişin tamamlandı. Ücretsiz denemen, Çeviriyi başlat düğmesine basıp Remote Play bağlantısı kurulduğunda başlayacak.":
      "You're signed in with Google. Your free trial starts when you press Start translation and Remote Play connects.",
  'Deneme henüz hazır değil. İnternet bağlantını kontrol edip tekrar dene.':
      'Your trial is not ready yet. Check your internet connection and try again.',
  "Ücretsiz denemen sona erdi. Çeviriye devam etmek için bir paket seçebilirsin.":
      "Your free trial has ended. Choose a plan to keep translating.",
  "Ücretsiz çeviriyi dene": "Try translation for free",
  "Google ile ücretsiz dene": "Try free with Google",
  "Deneme süresi alınamadı. İnternet bağlantını kontrol edip aşağı çekerek yenile.":
      "Couldn't load the trial duration. Check your connection and pull down to refresh.",
  "Google Play denemen {0} tarihine kadar aktif. Ücret alınmasını istemiyorsan deneme bitmeden Google Play’den iptal et.":
      "Your Google Play trial is active until {0}. To avoid a charge, cancel in Google Play before the trial ends.",
  "Deneme aboneliğinin yenilenmesi iptal edildi. {0} tarihine kadar çeviriyi kullanabilirsin.":
      "Trial subscription renewal is canceled. You can keep translating until {0}.",
  "Premium aktif. Aboneliğini Google Play’den yönetebilirsin.":
      "Premium is active. You can manage your subscription in Google Play.",
  "Yenileme iptal edildi. {0} tarihine kadar Premium erişimin sürer.":
      "Renewal is canceled. Your Premium access continues until {0}.",
  "Süresiz Premium erişimin aktif.": "Your Lifetime Premium access is active.",
  "Satın alma durumu doğrulanamadı. İnternete bağlanıp durumu yenile.":
      "Couldn't verify purchase status. Connect to the internet and refresh.",
  "{0} · tek ödeme, otomatik yenilenmez.":
      "{0} · one-time payment, no automatic renewal.",
  "{0} / {1}. Aboneliğin otomatik yenilenir; Google Play’den iptal edebilirsin.":
      "{0} / {1}. Your subscription renews automatically; you can cancel in Google Play.",
  "Süresiz satın al": "Buy lifetime access",
  "Abone ol": "Subscribe",
  "Premium aktif": "Premium active",
  "Erişim durumunu yenilemek için aşağı çek.":
      "Pull down to refresh your access status.",
  "Çeviriye devam et": "Continue translating",
  "Deneme için Google ile giriş yap": "Sign in with Google for a trial",
  "Satın alınabilir paket bulunamadı. Biraz sonra tekrar dene.":
      "No plans available to purchase. Try again later.",
  "Deneme uygunluğu ve son ödeme koşulları Google Play ekranında gösterilir.":
      "Trial eligibility and final payment terms are shown in Google Play.",
  "Geri yükleme için biraz bekle": "Please wait before restoring again",
  "Satın alımları geri yükle": "Restore purchases",
  "Google hesabı": "Google account",
  "Çıkış yap": "Sign out",
  "Google Play aboneliğini yönet / iptal et":
      "Manage / cancel Google Play subscription",
  "Gizlilik politikası": "Privacy policy",
  "Kullanım şartları": "Terms of use",
  "Sık Sorulan Sorular": "Frequently asked questions",
  "Yanıtları görmek için bir soruya dokun.":
      "Tap a question to see the answer.",
  "Süresiz erişim aktif": "Lifetime access active",
  "Kalan deneme: {0}": "Trial remaining: {0}",
  "Mağaza denemesi aktif": "Store trial active",
  "Deneme süresi sona erdi": "Trial ended",
  "Erişim doğrulaması gerekiyor": "Access verification required",
  "Paketleri ve erişim durumunu görüntüle": "View plans and access status",
  "Hesabın, Premium erişimin ve uygulama ayarların. Yenilemek için aşağı çek.":
      "Your account, Premium access and app settings. Pull down to refresh.",
  "Oyununa kaldığın yerden devam et": "Pick up where you left off",
  "Google hesabın": "Your Google account",
  "Deneme ve hesap işlemleri için Google hesabınla giriş yap.":
      "Sign in with your Google account for trial and account options.",
  "Google ile giriş yap": "Sign in with Google",
  "Aboneliğim": "My subscription",
  "Hediye kodunu kullan": "Redeem a gift code",
  "Google Play hediye veya promosyon kodu": "Google Play gift or promo code",
  "Tekrar denemeden önce kısa bir süre bekle.":
      "Wait a moment before trying again.",
  "Önceki satın alımlarını Google Play’den geri getir.":
      "Restore your previous Google Play purchases.",
  "PS5 bulundu. Eşleştirme için 8 haneli konsol PIN’ini gir.":
      "PS5 found. Enter the console's 8-digit PIN to pair.",
  "PS5 kayıt işlemi başlatılıyor…": "Starting PS5 registration…",
  "PS5 kaydı başarılı.\n{0}": "PS5 registered successfully.\n{0}",
  "Kayıt sonucu alınamadı.": "No registration result received.",
  "{0}\nHata kodu: {1}": "{0}\nError code: {1}",
  "PS5 kaydı başarısız.": "PS5 registration failed.",
  "Beklenmeyen hata: {0}": "Unexpected error: {0}",
  "PS5 bağlantısı hazır!": "PS5 connection ready!",
  "{0} başarıyla eşleştirildi.\n\nArtık ana menüden çeviriyi başlatabilirsin.":
      "{0} paired successfully.\n\nYou can now start translating from the home screen.",
  "PS5 Bağlantısı": "PS5 connection",
  "Adım 2/2": "Step 2/2",
  "PS5 konsolunu kaydet": "Register your PS5",
  "Telefon ve PS5 aynı yerel ağda olmalı. PS5 IP adresini konsolun ağ ayarlarında bulabilirsin.":
      "Your phone and PS5 must be on the same local network. You can find your PS5's IP address in the console's network settings.",
  "PS5’te bağladığın PSN hesabına geç. Ayarlar → Sistem → Uzaktan Oynatma → Uzaktan Oynatmayı Etkinleştir seçeneğini aç. Ardından Cihazı Eşleştir ile aldığın 8 haneli kodu aşağıya gir.":
      "Switch to the PSN account you linked on your PS5. Go to Settings → System → Remote Play → Enable Remote Play. Then select Link Device and enter the 8-digit code below.",
  "Kayıtlı PS5: {0}": "Registered PS5: {0}",
  "PS5 kayıtlı": "PS5 registered",
  "Remote Play ekranını aç": "Open Remote Play screen",
  "Yerel ağ taranıyor…": "Scanning local network…",
  "Ağda PS5 ara": "Find PS5 on network",
  "PS5 bulunamazsa IP adresini elle yazabilirsin.":
      "If your PS5 isn't found, you can enter its IP address manually.",
  "PS5 IPv4 adresini gir.": "Enter your PS5's IPv4 address.",
  "Geçerli bir IPv4 adresi gir.": "Enter a valid IPv4 address.",
  "Eşleştirmeden önce PSN hesabını doğrula. Account ID uygulamada güvenli olarak alınır.":
      "Verify your PSN account before pairing. Your Account ID is retrieved securely in the app.",
  "PSN hesabını doğrula": "Verify PSN account",
  "PSN hesabı doğrulandı": "PSN account verified",
  "Uzaktan erişim PIN kodu": "Remote access PIN",
  "PIN kodu 8 rakam olmalı.": "The PIN must be 8 digits.",
  "PS5 bağlantısını başlat": "Start PS5 connection",
  "OCR bekliyor": "Waiting for OCR",
  "Arka plan dönüşü için Remote Play yeniden kuruluyor.":
      "Restoring Remote Play after returning from the background.",
  "Bağlandı": "Connected",
  "PS5 kullanıcı giriş PIN’i gerekiyor": "PS5 user login PIN required",
  "Konsol kullanıcı PIN ekranını bekliyor. Bu uygulamada PIN girişi henüz eklenmedi.":
      "The console is waiting for the user PIN. PIN entry isn't available in this app yet.",
  "Bağlantı kesildi": "Disconnected",
  "already in use": "already in use",
  "yüzey": "surface",
  "arka plan": "background",
  "Bağlantı hatası": "Connection error",
  "kopya {0} ms, kırpma {1} ms, filtre {2} ms, OCR {3} ms (güven {4}) , {5}×{6}":
      "copy {0} ms, crop {1} ms, filter {2} ms, OCR {3} ms (confidence {4}), {5}×{6}",
  "kıyas": "compare",
  "Çeviri erişimi sona erdi veya doğrulanamadı. Premium ekranını kontrol et.":
      "Translation access ended or couldn't be verified. Check the Premium screen.",
  "Altyazı ayarları kaydedilemedi: {0}": "Couldn't save subtitle settings: {0}",
  "Altyazı ayarları kaydedildi.": "Subtitle settings saved.",
  "Remote Play açık değil": "Remote Play isn't active",
  "Seçili alan tek karede taranıyor…":
      "Scanning the selected area in a single frame…",
  "Seçili alan sıfırlandı ve kaydedildi.": "Selected area reset and saved.",
  "Tam ortaya hizala · %50": "Align to center · 50%",
  "Bu ölçü için konum sabit.": "Position is fixed for this size.",
  "Arka plan konumu ve boyutu": "Background position and size",
  "Konum ve boyut": "Position and size",
  "Tümünü ortala": "Center all",
  "Alanı sürükleyebilir veya değerleri hassas biçimde ayarlayabilirsin.":
      "Drag the area or fine-tune the values.",
  "Yatay merkez": "Horizontal center",
  "Dikey merkez": "Vertical center",
  "Genişlik": "Width",
  "Yükseklik": "Height",
  "Remote Play bağlantısı korunuyor; görüntü yüzeyi yenileniyor.":
      "Remote Play remains connected; refreshing the video surface.",
  "Canlı oyun görüntüsü bağlantı kurulunca görünür.":
      "Live game video will appear once connected.",
  "Altyazı alanı": "Subtitle area",
  "Arka plan alanı": "Background area",
  "OCR alanı": "OCR area",
  "Altyazı önizlemesi": "Subtitle preview",
  "Önizleme üzerinde hangi alanı ayarlayacaksın?":
      "Which area would you like to adjust in the preview?",
  "Altyazı yeri": "Subtitle position",
  "Turkuaz çerçeveler çevirinin gösterileceği yerlerdir. Her alanı seçip görüntüde taşıyabilir ve boyutlandırabilirsin.":
      "Turquoise frames show where translations appear. Select each area to move and resize it in the preview.",
  "Sarı çerçeve oyundaki yazının taranacağı OCR alanıdır.":
      "The yellow frame is the OCR area where game text is scanned.",
  "Altyazı {0}": "Subtitle {0}",
  "Altyazı alanı ekle": "Add subtitle area",
  "Seçili alanı sil": "Delete selected area",
  "SARI ALANLAR • OCR NEREDEN OKUSUN?": "YELLOW AREAS • WHERE SHOULD OCR READ?",
  "Oyun görüntüsünde metnin bulunduğu yeri seç. OCR yalnızca seçtiğin alanları tarar. Her alanı ayrı taşıyıp boyutlandırabilirsin.":
      "Select the areas containing game text. OCR scans only the selected areas. You can move and resize each one separately.",
  "OCR alanı ekle": "Add OCR area",
  "Seçili OCR alanını sil": "Delete selected OCR area",
  "TURKUAZ KUTULAR • ALTYAZILAR NEREDE GÖRÜNSÜN?":
      "TURQUOISE BOXES • WHERE SHOULD SUBTITLES APPEAR?",
  "Her turkuaz alan aynı çevrilmiş altyazıyı seçtiğin konumda gösterir. OCR alanlarından bağımsızdır; birden fazla yere ekleyebilirsin.":
      "Each turquoise area displays the same translated subtitle in your chosen position. Subtitle areas are independent of OCR areas; you can add more than one.",
  'OCR ipucu: Oyun ayarları izin veriyorsa İngilizce altyazının arka planını açıp opaklığını artır. Koyu zemin ve açık renk yazı, metnin daha net okunmasına ve çevirinin iyileşmesine yardımcı olabilir.':
      'OCR tip: If the game settings allow it, enable the English subtitle background and increase its opacity. Light text on a dark background can make the text easier to read and help improve translation.',
  "Altyazı kutusunu sıfırla": "Reset subtitle box",
  "Seçili OCR alanını sıfırla": "Reset selected OCR area",
  "Son OCR: {0}\n{1}": "Last OCR: {0}\n{1}",
  "Ham/filtreli OCR kıyasla": "Compare raw / filtered OCR",
  "OCR tarama sıklığı: {0}": "OCR scan frequency: {0}",
  "Düşük değer daha az pil harcar; metni daha geç yakalayabilir.":
      "Lower values use less battery but may detect text later.",
  "OCR {0} diyalog filtresi": "OCR {0} dialogue filter",
  "Konuşmacı adı, cümle yapısı ve konuma göre diyalog benzeri satırları seçer.":
      "Selects dialogue-like lines using speaker names, sentence structure and position.",
  "Kapalı: seçili OCR alanındaki tüm metinler tanınır.":
      "Off: recognizes all text in the selected OCR area.",
  "Çeviriyi İngilizce altyazının üstünde göster":
      "Show translation over the English subtitle",
  "Açık: çeviri, okunan İngilizce metnin tam üstünde çıkar; art arda konuşan kişiler ayrı ayrı, düğme ipuçları (SEÇ, GERİ…) her biri kendi yazısının üstünde gösterilir ve oyundaki düğme simgeleri görünür kalır. Bu alanın sabit altyazı konumu kullanılmaz.":
      "On: the translation appears right over the English text that was read; back-to-back speakers are shown separately, and button prompts (SELECT, BACK…) each go over their own label while the game's button icons stay visible. This area's fixed subtitle position is not used.",
  "Kapalı: çeviri, Altyazı {0} için seçtiğin sabit yerde gösterilir.":
      "Off: the translation is shown at the fixed position you chose for Subtitle {0}.",
  "Altyazı {0} İngilizce metnin üstünde":
      "Subtitle {0} is over the English text",
  "Çeviri, OCR {0} alanının okuduğu İngilizce metnin tam üstünde görünür ve onunla birlikte yer değiştirir; art arda konuşan kişiler ayrı kutularda, düğme ipuçları tek tek gösterilir. Bu yüzden sabit konum ayarı kapalı. Yazı boyutu, renk ve arka plan ayarları geçerli.":
      "The translation appears right over the English text read by OCR {0} and moves with it; back-to-back speakers get separate boxes and button prompts are covered one by one. That is why the fixed position setting is off. Text size, color and background settings still apply.",
  "Sabit konuma dön": "Back to fixed position",
  "Altyazı {0}, OCR {1} alanıyla birlikte taşınsın":
      "Move Subtitle {0} with OCR {1} area",
  "Açıkken altyazı OCR alanının tam üstünde durur ve onu taşıdıkça o da taşınır. Altyazı kutusunu elle taşırsan kendi yerinde kalır.":
      "When on, the subtitle sits right on the OCR area and moves with it. If you move the subtitle box yourself, it keeps its own place.",
  "OCR {0} görüntü ön işlemesi": "OCR {0} image preprocessing",
  "Ham görüntü": "Raw image",
  "Gri tonlama + kontrast": "Grayscale + contrast",
  "Adaptif eşikleme": "Adaptive threshold",
  "Kenar keskinleştirme": "Edge sharpening",
  "Yerel kontrast (ışık/parlama)": "Local contrast (lighting / glare)",
  "Hassas eşik · açık yazı": "Fine threshold · light text",
  "Hassas eşik · koyu yazı": "Fine threshold · dark text",
  "Hassas eşik · otomatik yön": "Fine threshold · automatic polarity",
  "Sarı yazı · mavi/soğuk zemin": "Yellow text · blue / cool background",
  "Otomatik renk kanalı": "Automatic color channel",
  "OCR görüntü ön işlemesi": "OCR image preprocessing",
  "Yalnızca seçili OCR kırpımına uygulanır. Otomatik renk kanalı her karede kırpımdaki RGB kanallarının kontrastını ölçüp o sahnede en çok ayrım sağlayanı seçer; farklı yazı ve arka plan renklerine uyum sağlamayı dener. Sarı yazı seçeneği yalnızca sarı yazı/mavi-soğuk zemin içindir.":
      "Applies only to the selected OCR crop. Automatic color channel measures the contrast of the RGB channels in each frame and picks the one with the clearest separation, adapting to different text and background colors. The yellow text option is only for yellow text on blue or cool backgrounds.",
  "OCR alanı büyütme": "OCR area scaling",
  "1× · hızlı": "1× · fast",
  "2× · küçük yazı": "2× · small text",
  "Ölçek uygulamadan seçilir ve yalnızca OCR kırpımına uygulanır; oyun görüntüsü değişmez. 1× en hızlısı, 1,5× genelde dengeli seçim, 2× küçük karakterler içindir. 1600 piksel genişlik sınırı korunur.":
      "Scaling is selected in the app and applies only to the OCR crop; game video is unchanged. 1× is fastest, 1.5× is generally balanced, and 2× is for small characters. The 1600-pixel width limit still applies.",
  "OCR alanı boş kalırsa tut: {0} sn":
      "Keep subtitles when OCR area is empty: {0} s",
  "Metin yenilenmezse gizle: {0} sn": "Hide if text isn't updated: {0} s",
  "OCR alanında yeni metin algılanmazsa altyazı seçtiğin süre sonunda gizlenir.":
      "If no new text is detected in the OCR area, subtitles hide after the selected time.",
  "Altyazı {0} genişliği: {1}%": "Subtitle {0} width: {1}%",
  "Altyazı {0} yüksekliği: {1}%": "Subtitle {0} height: {1}%",
  "Yazı boyutu: {0}": "Font size: {0}",
  "Arka plan saydamlığı: {0}%": "Background transparency: {0}%",
  "Saydamlık %0 iken arka plan tamamen opaktır. Saydamlık %100 iken arka plan tamamen görünmez olur.":
      "At 0% transparency, the background is fully opaque. At 100%, it's completely invisible.",
  "Arka plan kutusu": "Background box",
  "Yalnızca yazı kadar": "Fit to text",
  "Seçili alanı doldur": "Fill selected area",
  "Arka plan yazıyla birlikte büyüyüp küçülür.":
      "The background grows and shrinks with the text.",
  "Arka plan turkuaz alanın tamamını doldurur. Kutuyu sürükleyebilir, kenarlarından boyutlandırabilir veya alan ayarlarını kullanabilirsin.":
      "The background fills the entire turquoise area. Drag the box, resize its edges or use the area controls.",
  "Arka plan alanını ayarla": "Adjust background area",
  "Arka plan rengi": "Background color",
  "Özel arka plan rengi seç": "Choose custom background color",
  "Yazı rengi": "Text color",
  "Özel yazı rengi seç · #{0}": "Choose custom text color · #{0}",
  "Hizalama ve kalınlık": "Alignment and weight",
  "Sola hizala": "Align left",
  "Kalın": "Bold",
  "Normal": "Normal",
  "Renk seç · #{0}": "Choose color · #{0}",
  "Parlaklık": "Brightness",
  "Rengi uygula": "Apply color",
  "Anladım": "Got it",
  "Görüntü alanı hazırlanıyor…": "Preparing video area…",
  "Görüntü alanı hazır değil": "Video area isn't ready",
  "Remote Play görüntüsü oluşturulamadı. Ekranı yenileyip tekrar dene.":
      "Couldn't create the Remote Play view. Refresh the screen and try again.",
  "Bağlantı başlatılamadı": "Couldn't start connection",
  "Remote Play yeniden bağlanıyor… {0} sn. Lütfen bekleyin ({1}/4)":
      "Reconnecting Remote Play… {0} s. Please wait ({1}/4)",
  "PS5 bağlantısı kapatılıyor…": "Closing PS5 connection…",
  "PS5 Remote Play": "PS5 Remote Play",
  "Görüntü gizli • Remote Play ve OCR çalışıyor":
      "Video hidden • Remote Play and OCR are running",
  "Görüntüyü göster": "Show video",
  "Mobil görüntüyü gizle": "Hide mobile video",
  "Çeviri hazırlanıyor…": "Preparing translation…",
  "Deneme bitti": "Trial ended",
  "Ana kullanıcıda oynamak için Remote Play oturumunu açık tut. PS5’e bağlı kumandada PS tuşuna basıp ana kullanıcıyı seç; Remote Play hesabından çıkma veya bağlantıyı kesme.":
      "Keep the Remote Play session open to play on your main user. Press the PS button on the controller connected to your PS5 and select your main user; don't sign out of the Remote Play account or disconnect.",
  "Altyazı alanlarını ve ayarlarını aç": "Open subtitle areas and settings",
  "Bağlantı kesiliyor…": "Disconnecting…",
  "PS5 yeniden denenecek…": "PS5 will retry…",
  "Çeviriyi durdur": "Stop translation",
  "PS5’e bağlan": "Connect to PS5",
  "PS5 kaydı siliniyor…": "Removing PS5 registration…",
  "Bağlantıyı kes, kayıtları sil ve çık": "Disconnect, delete records and exit",
  "Doğrulama başarılı. PS5 konsolunu bağlamak için sonraki adıma devam et.":
      "Verification successful. Continue to the next step to connect your PS5.",
  "Güvenli bağlantı doğrulanıyor…": "Verifying secure connection…",
  "PSN Account ID alınıyor…": "Retrieving PSN Account ID…",
  "Tarayıcı açılamadı. Lütfen tekrar dene.":
      "Couldn't open browser. Please try again.",
  "PSN giriş sayfası açılamadı.": "Couldn't open the PSN sign-in page.",
  "Panoda yapıştırılacak bir bağlantı yok.":
      "There's no link to paste in the clipboard.",
  "Panodaki bağlantı okunamadı. Tekrar dene.":
      "Couldn't read the clipboard link. Try again.",
  "URL içinde geçerli bir authorization code bulunamadı. Yönlendirme URL’sini kontrol et.":
      "No valid authorization code found in the URL. Check the redirect URL.",
  "Sony hesabı doğrulanıyor…": "Verifying Sony account…",
  "PSN hesabı doğrulanamadı. Tekrar dene.":
      "Couldn't verify PSN account. Try again.",
  "PSN doğrulaması başarısız.": "PSN verification failed.",
  "PSN Hesap Bağlantısı": "PSN account connection",
  "Adım 1/2": "Step 1/2",
  "PSN hesabını bağla": "Connect your PSN account",
  "PSN giriş sayfasını tarayıcıda aç. Giriş yaptıktan sonra \"redirect\" yazan beyaz bir sayfa açılır. Bu sayfa açıkken tarayıcının adres çubuğundaki bağlantının tamamını kopyalayıp buraya yapıştır. Sayfadaki yazıyı değil, adres çubuğundaki linki kopyala.":
      "Open the PSN sign-in page in your browser. After signing in, a white page saying “redirect” will appear. While on that page, copy the entire link from the browser's address bar and paste it here. Copy the address bar link, not the text on the page.",
  "Bu bağlantı için yeni bir PSN hesabı oluştur veya şu anda kullanmadığın bir hesabı bağla, ana hesabını bağlama. Bağlayacağın PSN hesabı PlayStation 5’te de kullanıcı olarak ekli olmalı. Ana hesaptan oyunu oynayacaksın.":
      "Create a new PSN account or connect an account you don't currently use; don't connect your main account. The PSN account you connect must also be added as a user on your PlayStation 5. You'll play the game on your main account.",
  "Tarayıcı açılıyor...": "Opening browser...",
  "PSN ile giriş yap": "Sign in with PSN",
  "Yönlendirme URL’si": "Redirect URL",
  "Yapıştır": "Paste",
  "PSN doğrulanıyor…": "Verifying PSN…",
  "Sonraki adım: PS5 konsolunu bağla": "Next step: connect your PS5",
  "Yardım": "Help",
  "Bağlantı ve çeviri hakkında yanıtlar":
      "Answers about connections and translation",
  "Tamamladığın adımları yeniden incele": "Review your completed steps",
  "Bize e-posta gönder": "Email us",
  "Uygulama hakkında": "About the app",
  "Sürüm": "Version",
  "İlerleme bu telefonda saklanır. Konsol veya TV bağlantısını kaldırırsan ilgili adımı yeniden tamamlaman gerekir.":
      "Progress is saved on this phone. If you remove a console or TV connection, you'll need to complete the relevant step again.",
  "Kurulum adımları": "Setup steps",
  "Adımları sırayla uygula. Tamamladıklarını işaretle; uygulama bağlantı adımlarını kendisi de tanır.":
      "Follow the steps in order. Check off completed steps; the app also detects connection steps automatically.",
  "Kurulum videosu": "Setup video",
  "Video hazır olduğunda burada görünecek":
      "The video will appear here when it's ready",
  "Videoyu izle": "Watch video",
  "PS5 kurulumunu aç": "Open PS5 setup",
  "TV eşleştirmeyi aç": "Open TV pairing",
  "{0} varsayılan profil seçildi.": "{0} selected as the default profile.",
  "Bu isimde bir oyun profili zaten var.":
      "A game profile with this name already exists.",
  "Altyazı ayarları": "Subtitle settings",
  "Oyun profili ekle": "Add game profile",
  "Henüz oyun profili yok. Her oyun için OCR alanlarını ve altyazı görünümünü ayrı kaydedebilirsin.":
      "No game profiles yet. Save separate OCR areas and subtitle appearances for each game.",
  "İlk profili oluştur": "Create your first profile",
  "Bir oyun profilini açıp OCR ve altyazı konumunu ayrı ayrı düzenle. Yıldızlı profil uygulama açılışında varsayılan olarak kullanılır.":
      "Open a game profile to adjust OCR and subtitle positions separately. The starred profile is used by default when the app starts.",
  "{0} → {1} · {2} OCR alanı": "{0} → {1} · {2} OCR areas",
  "Varsayılan profil": "Default profile",
  "Uygulama açılışında varsayılan yap": "Make default on app startup",
  "Oyun profili oluştur": "Create game profile",
  "Oyun adı": "Game name",
  "Oluştur": "Create",
  "Devam eden işlemin tamamlanmasını bekle.":
      "Wait for the current action to finish.",
  "Tekrar denemek için {0} saniye bekle.":
      "Wait {0} seconds before trying again.",
  "Satın alma sistemi şu anda Android için kullanılabilir.":
      "Purchases are currently available on Android.",
  "Satın alma hizmeti henüz kullanıma hazır değil.":
      "The purchase service isn't ready yet.",
  "Satın alma durumu alınamadı.": "Couldn't retrieve purchase status.",
  "Google hesabı doğrulanamadı.": "Couldn't verify Google account.",
  "Deneme başlatılamadı.": "Couldn't start trial.",
  "Hesabını silmek için önce giriş yap.":
      "Sign in before deleting your account.",
  "Uygulamadaki hesabın silindi. Oturum temizliği tamamlanamadı; uygulamayı kapatıp yeniden aç.":
      "Your app account was deleted. Sign-out cleanup couldn't finish; close and reopen the app.",
  "Oturumun değişti. Hesap silme işlemini yeniden başlat.":
      "Your session changed. Start account deletion again.",
  "Google hesabı doğrulanamadı. Hesabın silinmedi.":
      "Couldn't verify Google account. Your account hasn't been deleted.",
  "Abonelik planı yüklenemedi. Paketleri yenileyip tekrar dene.":
      "Couldn't load the subscription plan. Refresh the plans and try again.",
  "Satın alma yanıtı doğrulanamadı. Satın alımları geri yüklemeyi dene.":
      "Couldn't verify the purchase response. Try restoring purchases.",
  "Google Play satın alımın bulundu ancak Premium erişimin doğrulanamadı. Yeniden ödeme yapma. Satın alımları geri yükle veya destekle iletişime geç.":
      "Your Google Play purchase was found, but Premium access couldn't be verified. Don't pay again. Restore purchases or contact support.",
  "Aktif satın alma bulunamadı. Ödeme bekliyorsa tamamlandıktan sonra tekrar dene.":
      "No active purchase found. If payment is pending, try again once it's complete.",
  "Google girişi tamamlanmadı. İptal etmediysen tekrar dene; sorun sürerse destekle iletişime geç.":
      "Google sign-in wasn't completed. If you didn't cancel, try again; contact support if the problem continues.",
  "Google girişi bu sürümde kullanılamıyor. Destekle iletişime geç.":
      "Google sign-in isn't available in this version. Contact support.",
  "Google hesabına giriş yapılamadı. Tekrar dene.":
      "Couldn't sign in to Google. Try again.",
  "Google hesabı doğrulanamadı. İnternet bağlantını kontrol edip tekrar dene.":
      "Couldn't verify Google account. Check your internet connection and try again.",
  "Uygulamada giriş yaptığın Google hesabını seçerek tekrar dene.":
      "Try again and select the Google account you're signed into in the app.",
  "Hesabını silmek için yeniden giriş yapıp tekrar dene.":
      "Sign in again and retry deleting your account.",
  "Google hesabı doğrulanamadı. Tekrar giriş yapmayı dene.":
      "Couldn't verify Google account. Try signing in again.",
  "Erişim durumu alınamadı. Tekrar dene.":
      "Couldn't retrieve access status. Try again.",
  "Bu satın alım Google Play hesabında zaten aktif. Satın alımları geri yükle.":
      "This purchase is already active on your Google Play account. Restore purchases.",
  "Ödemen Google Play onayı bekliyor. Tamamlandığında erişim durumunu yenile.":
      "Your payment is awaiting Google Play approval. Refresh access status once it's complete.",
  "Satın alma hizmetine bağlanılamadı. İnternet bağlantını kontrol edip tekrar dene.":
      "Couldn't connect to the purchase service. Check your internet connection and try again.",
  "Satın alım başka bir hesaba bağlı görünüyor. Satın aldığın Google Play hesabını kontrol et veya destekle iletişime geç.":
      "This purchase appears to belong to another account. Check the Google Play account you used to purchase or contact support.",
  "Google Play bu hesapta satın almaya izin vermiyor. Mağaza hesabını kontrol et.":
      "Google Play doesn't allow purchases on this account. Check your store account.",
  "Satın alma hizmeti şu anda kullanılamıyor. Destekle iletişime geç.":
      "The purchase service is currently unavailable. Contact support.",
  "İşlem tamamlanamadı. Biraz sonra tekrar dene.":
      "Couldn't complete the action. Try again later.",
  "Hizmete bağlanılamadı. İnternet bağlantını kontrol edip tekrar dene.":
      "Couldn't connect to the service. Check your internet connection and try again.",
  "Sürüm bilgisi alınamadı": "Version information unavailable",
  "Bağlantı henüz hazır değil. Lütfen daha sonra tekrar dene.":
      "This link isn't ready yet. Please try again later.",
  "Bağlantı açılamadı. Lütfen tekrar dene.":
      "Couldn't open the link. Please try again.",
  "E-posta uygulaması açılamadı. Bu adresten bize ulaşabilirsin:":
      "Couldn't open an email app. You can reach us at this address:",
  "E-posta adresi kopyalandı.": "Email address copied.",
  "Adresi kopyala": "Copy address",
  "Oyun kataloğu bir liste değil.": "The game catalog isn't a list.",
  "Oyun kataloğu kaydı geçersiz.": "Invalid game catalog entry.",
  "Oyun kataloğunda yinelenen ID var.":
      "The game catalog contains duplicate IDs.",
  "user_id pozitif bir tam sayı olmalıdır.":
      "user_id must be a positive integer.",
  "user_id geçerli bir sayısal değer değil.": "user_id isn't a valid number.",
  "TV sertifikası doğrulanamadı.": "Couldn't verify the TV certificate.",
  "TV sertifika kaydı geçersiz.": "Invalid TV certificate record.",
  "TV adresi veya 6 haneli kod geçersiz.":
      "Invalid TV address or 6-digit code.",
  "TV kimliği ekrandan doğrulanmalı.": "Verify the TV identity on screen.",
  "TV bağlantı denemesi iptal edildi.": "TV connection attempt canceled.",
  "TV kimliği doğrulanmadı.": "TV identity wasn't verified.",
  "User disconnected": "User disconnected",
  "Connection cancelled": "Connection canceled",
  "TV bağlantı güvenliği değişti.": "TV connection security has changed.",
  "Pairing failed": "Pairing failed",
  "TV eşleştirme kodunu kabul etmedi.": "The TV rejected the pairing code.",
  "TV bağlantısı eşleştirme tamamlanmadan kapandı.":
      "The TV connection closed before pairing was complete.",
  "Pairing stopped": "Pairing stopped",
  "Pairing rejected": "Pairing rejected",
  "Invalid pairing data": "Invalid pairing data",
  "Pairing timed out": "Pairing timed out",
  "Süresiz Premium aktif": "Lifetime Premium active",
  "Premium aboneliğin aktif": "Your Premium subscription is active",
  "Premium durumun değişti": "Your Premium status changed",
  "Premium ayrıntıları": "Premium details",
  "Abonelik ayrıntıları": "Subscription details",
  "Güncel erişim durumunu ve satın alımlarını ayrıntılar ekranından kontrol edebilirsin.":
      "Check your current access status and purchases on the details screen.",
  "Premium çeviri özelliklerine süresiz erişimin var. Tek seferlik satın alımın için otomatik yenileme veya tekrar ödeme yok.":
      "You have lifetime access to Premium translation features. Your one-time purchase has no automatic renewal or additional payments.",
  "Google Play deneme aboneliğin aktif. {0}{1}":
      "Your Google Play trial subscription is active. {0}{1}",
  "Deneme bitişi: {0}. ": "Trial ends: {0}. ",
  "Deneme sonunda ücretli olarak yenilenir.":
      "Renews as a paid subscription after the trial.",
  "Otomatik yenileme kapalı.": "Automatic renewal is off.",
  "Premium çeviri özelliklerini kullanabilirsin.\n\n{0}{1}":
      "You can use Premium translation features.\n\n{0}{1}",
  "Otomatik yenileme açık.": "Automatic renewal is on.",
  "Otomatik yenileme kapalı; mevcut dönem sonuna kadar erişimin devam eder.":
      "Automatic renewal is off; your access continues until the current period ends.",
  "Sonraki yenileme": "Next renewal",
  "Erişim bitişi": "Access ends",
  "Önce TV uygulamasını indir": "Download the TV app first",
  "Sistem dili": "System language",
  "Dil tercihi kaydedilemedi. Tekrar dene.":
      "Couldn't save language preference. Try again.",
  "Kapat": "Close",
  "Tamam": "OK",
  "Kaydet": "Save",
  "Geri": "Back",
  "Devam": "Continue",
  "Hata": "Error",
  "Kaynak": "Source",
  "Hedef": "Target",
  "hafta": "week",
  "ay": "month",
  "PS5 gerekli": "PS5 required",
  "PS5’i kur": "Set up PS5",
  "Abonelik": "Subscription",
  "Hesap": "Account",
  "PS5 IPv4 adresi": "PS5 IPv4 address",
  "PS5 kaydediliyor…": "Registering PS5…",
  "Ortala": "Center",
  "Ton": "Hue",
  "Doygunluk": "Saturation",
  "Oyun": "Game",
  "indirildi": "downloaded",
  "indirilmedi": "not downloaded",
  "{0} • indirilmedi": "{0} • not downloaded",
  "Dil paketi gerekli": "Language pack required",
  "Model B için seçili kaynak ve hedef dil paketlerini önce indir.":
      "Download the selected source and target packs for Model B first.",
  "{0} Destek": "{0} Support",
  "Deneme için Google hesabınla giriş yap.": "Sign in with Google for a trial.",
  "Hesap zamanı doğrulanamadı.": "Couldn't verify account time.",
  "Deneme kaydı geçersiz.": "Invalid trial record.",
  "JSONL satır {0} okunamadı.": "Couldn't read JSONL line {0}.",
  "JSONL satır {0}: ID eksik.": "JSONL line {0}: missing ID.",
  "JSONL satır {0}: yinelenen ID {1}.": "JSONL line {0}: duplicate ID {1}.",
  "HPLT modeli kapalı.": "HPLT model is disabled.",
  "HPLT model.bin bulunamadı.": "HPLT model.bin not found.",
  "HPLT İngilizce sözlüğü açılamadı.":
      "Couldn't open the HPLT English vocabulary.",
  "HPLT Türkçe sözlüğü açılamadı.":
      "Couldn't open the HPLT Turkish vocabulary.",
  "HPLT modeli yüklenemedi.": "Couldn't load the HPLT model.",
  "OPUS-MT SentencePiece sözlüğü açılamadı":
      "Couldn't open the OPUS-MT SentencePiece vocabulary",
  "Almanca": "German",
  "Katalanca": "Catalan",
  "Fransızca": "French",
  "İspanyolca": "Spanish",
  "İtalyanca": "Italian",
  "Felemenkçe": "Dutch",
  "Yunanca": "Greek",
  "Rusça": "Russian",
  "PSN giriş kodu kabul edilmedi. PSN ile yeniden giriş yap.":
      "The PSN sign-in code was rejected. Sign in with PSN again.",
  "Güvenlik doğrulaması tamamlanamadı. Tekrar dene.":
      "Couldn't complete security verification. Try again.",
  "Çok fazla doğrulama denemesi yapıldı. Bir dakika sonra tekrar dene.":
      "Too many verification attempts. Try again in a minute.",
  "PSN hesap doğrulama hizmeti henüz hazır değil.":
      "The PSN account verification service isn't ready yet.",
  "PSN hesap doğrulama hizmetine ulaşılamadı. Tekrar dene.":
      "Couldn't reach the PSN account verification service. Try again.",
  "PSN hesap yanıtı geçersiz.": "Invalid PSN account response.",
  "PSN hesap doğrulama sunucusu yapılandırılmamış.":
      "The PSN account verification server isn't configured.",
  "Güvenlik doğrulaması zaman aşımına uğradı. Tekrar dene.":
      "Security verification timed out. Try again.",
  "Güvenlik doğrulaması için güvenli bağlantı kurulamadı.":
      "Couldn't establish a secure connection for verification.",
  "Güvenlik doğrulama sayfası açılamadı. Tekrar dene.":
      "Couldn't open the security verification page. Try again.",
  "Güvenlik doğrulaması kesildi. Tekrar deneyebilirsin.":
      "Security verification was interrupted. You can try again.",
  "Güvenlik doğrulama adresi geçersiz.":
      "Invalid security verification address.",
  "Güvenli bağlantı": "Secure connection",
  "Güvenlik doğrulaması iptal edildi. Tekrar deneyebilirsin.":
      "Security verification was canceled. You can try again.",
  "Konsol bilgileri güvenli depoya yazılamadı.":
      "Couldn't save console details to secure storage.",
  "Güvenli kayıt silinemedi.": "Couldn't delete the secure record.",
  "PSN Account ID güvenli depodan silinemedi.":
      "Couldn't delete PSN Account ID from secure storage.",
  "PSN Account ID 8 bayt olmalı.": "PSN Account ID must be 8 bytes.",
  "PSN Account ID güvenli depoya yazılamadı.":
      "Couldn't save PSN Account ID to secure storage.",
  "Kayıtlı PSN Account ID geçersiz.": "Invalid saved PSN Account ID.",
  "Uyarı tercihi geçersiz.": "Invalid reminder preference.",
  "Uyarı tercihi kaydedilemedi.": "Couldn't save reminder preference.",
  "Kurulum işaretleri geçersiz.": "Invalid setup checklist.",
  "Çeviri motoru seçimi geçersiz.": "Invalid translation engine selection.",
  "TV eşleştirme bilgileri geçersiz.": "Invalid TV pairing details.",
  "TV eşleştirmesi kaydedilemedi.": "Couldn't save TV pairing.",
  "Kayıtlı PSN ve PS5 bilgileri silinemedi.":
      "Couldn't delete saved PSN and PS5 details.",
  "Bildirim izni isteği zaten açık.":
      "A notification permission request is already open.",
  "Çeviri bildirimi başlatılamadı.":
      "Couldn't start the translation notification.",
  "Ekran kapalıyken çeviri": "Translate with screen off",
  "Şimdi değil": "Not now",
  "Ayarları aç": "Open settings",
  "Bir PS5 kayıt işlemi zaten çalışıyor.":
      "PS5 registration is already in progress.",
  "Güvenli PSN kaydı açılamadı. PSN hesabını yeniden doğrula.":
      "Couldn't open the secure PSN record. Verify your PSN account again.",
  "Önce PSN hesabını doğrula.": "Verify your PSN account first.",
  "Chiaki kayıt işlemi başlatılamadı.": "Couldn't start Chiaki registration.",
  "Kayıt başlatılırken hata oluştu.":
      "An error occurred while starting registration.",
  "PS5 kaydı alındı ancak güvenli depoya yazılamadı.":
      "PS5 registration was received but couldn't be saved securely.",
  "Chiaki-ng PS5 kaydını tamamlayamadı. Host ve PIN bilgilerini kontrol edip yeniden dene.":
      "Chiaki-ng couldn't complete PS5 registration. Check the host and PIN, then try again.",
  "PS5 kayıt işlemi iptal edildi.": "PS5 registration was canceled.",
  "Kayıtlı PS5 bilgileri çözülemedi. Yeniden eşleştirmen gerekebilir.":
      "Couldn't decode saved PS5 details. You may need to pair again.",
  "Oyun profilleri okunamadı.": "Couldn't read game profiles.",
  "PS5 görüntü alanı hazır değil.": "The PS5 video area isn't ready.",
  "PS5 karesini alamadım. Remote Play görüntüsü açıkken yeniden dene.":
      "Couldn't capture a PS5 frame. Try again with Remote Play video visible.",
  "PS5 ekran görüntüsü uygulama alanına kaydedilemedi.":
      "Couldn't save the PS5 screenshot to app storage.",
  "Kayıtlı ekran görüntüsü bulunamadı.": "Saved screenshot not found.",
  "Altyazı ayarları okunamadı.": "Couldn't read subtitle settings.",
  "Altyazı ayarları kaydedilemedi.": "Couldn't save subtitle settings.",
  "Oyun seçimi kaydedilemedi.": "Couldn't save game selection.",
  "Oyun çeviri dosyası okunamadı.": "Couldn't read the game translation file.",
  "Model C için 64-bit ARM Android gerekiyor.":
      "Model C requires 64-bit ARM Android.",
  "Model klasörü oluşturulamadı.": "Couldn't create the model folder.",
  "{0} dosyası eksik veya boyutu doğrulanamadı.":
      "File {0} is missing or its size couldn't be verified.",
  "{0} dosyasının SHA-256 doğrulaması başarısız.":
      "SHA-256 verification failed for {0}.",
  "Eski {0} dosyası değiştirilemedi.": "Couldn't replace the old {0} file.",
  "{0} dosyası kaydedilemedi.": "Couldn't save file {0}.",
  "HPLT model paketi doğrulanamadı.": "Couldn't verify the HPLT model pack.",
  "Bu çevrimdışı dil modeli henüz desteklenmiyor.":
      "This offline language model isn't supported yet.",
  "Dil seçimi okunamadı.": "Couldn't read the language selection.",
  "Bu çevrimdışı dil henüz sunulmuyor.":
      "This offline language isn't available yet.",
  "İndirilen model doğrulanamadı.": "Couldn't verify the downloaded model.",
  "Çevrimdışı model dosyaları beklenen dil modeliyle uyuşmuyor.":
      "Offline model files don't match the expected language model.",
  "Çevrimdışı model dosyaları eksik veya sürümleri uyuşmuyor.":
      "Offline model files are missing or their versions don't match.",
  "Çevrimdışı dil modeli indirilemedi.":
      "Couldn't download the offline language model.",
  "Kaynak ve hedef dil seçimini kontrol et.":
      "Check the source and target language selections.",
  "Çeviri dil paketleri indirilemedi. İnternet bağlantını kontrol et.":
      "Couldn't download translation language packs. Check your internet connection.",
  "Bu çeviri dili desteklenmiyor.":
      "This translation language isn't supported.",
  "Dil paketi indirilemedi. İnternet bağlantını kontrol edip yeniden dene.":
      "Couldn't download the language pack. Check your internet connection and try again.",
  "PSN yönlendirme kodu geçersiz.": "Invalid PSN redirect code.",
  "PSN hesabı zaten doğrulanıyor.":
      "PSN account verification is already in progress.",
  "Doğrulama için uygulamayı yeniden aç.": "Reopen the app to verify.",
  "PSN hesabı doğrulanamadı.": "Couldn't verify the PSN account.",
  "Hesap doğrulama sunucusundan yanıt alınamadı. Tekrar dene.":
      "No response from the account verification server. Try again.",
  "Hesap doğrulama sunucusunun TLS sertifikası doğrulanamadı.":
      "Couldn't verify the account server's TLS certificate.",
  "PSN hesabı doğrulanamadı. Giriş akışını yeniden başlatıp tekrar dene.":
      "Couldn't verify the PSN account. Restart sign-in and try again.",
  "Güvenlik doğrulaması açılamadı. Android System WebView'i kontrol edip tekrar dene.":
      "Couldn't open security verification. Check Android System WebView and try again.",
  "Bir Remote Play oturumu zaten açık.":
      "A Remote Play session is already active.",
  "Kayıtlı PS5 bilgileri okunamadı. Yeniden PS5 eşleştirmen gerekebilir.":
      "Couldn't read saved PS5 details. You may need to pair your PS5 again.",
  "Önce bir PS5'i kaydet.": "Register a PS5 first.",
  "Arka plan çeviri servisi başlatılamadı.":
      "Couldn't start the background translation service.",
  "PS5 bağlantısı iptal edildi.": "PS5 connection was canceled.",
  "Chiaki oturumu başlatılamadı: {0}": "Couldn't start Chiaki session: {0}",
  "Remote Play oturumu başlatılamadı.":
      "Couldn't start the Remote Play session.",
  "Chiaki oturumu kapatılamadı: {0}": "Couldn't close Chiaki session: {0}",
  "Remote Play oturumu kapatılırken hata oluştu.":
      "An error occurred while closing Remote Play.",
  "Yerel ağ keşfi başlatılamadı: {0}":
      "Couldn't start local network discovery: {0}",
  "Bildirim izni isteği tamamlanamadı.":
      "Couldn't complete the notification permission request.",
  "Çeviri modeli hazır değil": "Translation model isn't ready",
  "OCR kapalı": "OCR is off",
  "Önceki OCR karesi hâlâ işleniyor":
      "The previous OCR frame is still processing",
  "Video karesi henüz hazır değil": "Video frame isn't ready yet",
  "OCR alanı boş": "OCR area is empty",
  "Video karesi işlenemedi": "Couldn't process video frame",
  "Seçili alanda metin bulunamadı": "No text found in the selected area",
  "OCR işlenemedi: {0}": "OCR processing failed: {0}",
  "OCR hatası": "OCR error",
  "Çeviri hazırlanıyor": "Preparing translation",
  "Çevrildi": "Translated",
  "Çeviri başarısız": "Translation failed",
  "Yerel çeviri paketi açılamadı": "Couldn't open the local translation pack",
  "HPLT modeli açılamadı": "Couldn't open the HPLT model",
  "HPLT çevirisi hazırlanıyor": "Preparing HPLT translation",
  "Çevrildi · HPLT": "Translated · HPLT",
  "HPLT çevirisi başarısız": "HPLT translation failed",
  "Çeviri için aktif deneme veya Premium gerekiyor.":
      "An active trial or Premium is required to translate.",
  "Satın alma kontrolü devam ediyor.": "Purchase verification is in progress.",
  "Hesap değişti.": "Account changed.",
  "Satın alma durumu alınamadı. İnternete bağlanıp tekrar dene.":
      "Couldn't retrieve purchase status. Connect to the internet and try again.",
  "Erişim kontrolü devam ediyor.": "Access verification is in progress.",
  "Deneme durumu alınamadı. Google girişini ve internet bağlantını kontrol et.":
      "Couldn't retrieve trial status. Check Google sign-in and your internet connection.",
  "Çeviri beklemede": "Translation waiting",
  "İlk video karesi henüz alınmadı. Bildirim açık kalıyor.":
      "Waiting for the first video frame. The notification stays active.",
  "Yeni video karesi yok. Görüntü gelince çeviri sürdürülecek.":
      "No new video frames. Translation will resume when video returns.",
  "Çeviri çalışıyor": "Translation running",
  "Menüye dönmek için dokun.": "Tap to return to the menu.",
  "Çeviri durumu": "Translation status",
  "Remote Play altyazı çevirisi": "Remote Play subtitle translation",
  "PS5 bağlantısı arka planda sürüyor. Menüye dönmek için dokun.":
      "PS5 stays connected in the background. Tap to return to the menu.",
  "Remote Play oturumu": "Remote Play session",
  "Durdur": "Stop",
  // Reviewed FAQ and setup guide messages.
  "PS5’im bulunmuyor veya bağlanmıyor. Ne yapmalıyım?":
      "My PS5 cannot be found or will not connect. What should I do?",
  "Telefon ve PS5 aynı yerel ağda olmalı; PS5 Ethernet, telefon Wi-Fi kullanabilir. Konsolu açıp Remote Play’i etkinleştir. Ağda bulunmazsa PS5’in Ayarlar → Ağ → Bağlantı Durumu bölümündeki IP adresini elle gir. Kayıtta kullandığın PSN hesabı konsolda kullanıcı olarak da ekli olmalı. Cihazı Bağla ekranındaki güncel 8 haneli PIN ile tekrar dene.":
      "Your phone and PS5 must be on the same local network; the PS5 can use Ethernet while your phone uses Wi-Fi. Turn on the console and enable Remote Play. If discovery fails, enter the IP address from Settings → Network → Connection Status on the PS5. The PSN account used for registration must also be added as a console user. Retry with the current 8-digit PIN from Link Device.",
  "PS5 bağlı görünüyor ama telefondaki görüntü siyah. Ne yapmalıyım?":
      "My PS5 appears connected, but the phone preview is black. What should I do?",
  "Mobil görüntüyü gizlediysen Görüntüyü göster’e dokun. Ana sayfada olmak veya önizlemeyi gizlemek çeviriyi durdurmaz. Önizleme açıkken de görüntü yoksa PS5 kartından Remote Play’e dön; bağlantı veya görüntü yenileniyorsa bekle. Sorun sürerse çeviriyi durdurup yeniden başlat. PS5’te bağlantı bildirimi görünmesi tek başına video akışının hazır olduğunu göstermez.":
      "If you hid the mobile preview, tap Show picture. Returning to the home screen or hiding the preview does not stop translation. If the visible preview is still blank, return to Remote Play from the PS5 card and wait while the connection or picture recovers. If needed, stop translation and start again. A connection notification on the PS5 alone does not mean the video stream is ready.",
  "Uygulamadaki PS5 görüntüsü nereden geliyor?":
      "Where does the PS5 picture in the app come from?",
  "Telefondaki görüntü PS5’ten Remote Play ile alınan canlı akıştır. OCR, bu görüntüde seçtiğin alanlardaki metni okur. TV’de PS5’in HDMI girişini izlersin; çevrilen altyazıyı Android TV uygulaması bu görüntünün üzerinde gösterir.":
      "The phone receives a live Remote Play stream from your PS5. OCR reads the text inside the areas you select in that picture. On the TV, you watch the PS5 HDMI input; the Android TV app displays translated subtitles over that picture.",
  "Altyazıları PS5’in HDMI görüntüsünde göstermek için ne gerekli?":
      "What do I need to show subtitles over the PS5 HDMI picture?",
  "Telefon uygulaması, PS5 ve OyunÇevirmeni TV uygulamasını çalıştırabilen bir Android TV gerekir. TV uygulamasına diğer uygulamaların üzerinde gösterim izni ver, telefonu TV ile eşleştir ve telefonda çeviriyi başlat. TV’de altyazı gösterimi açık olmalı. Sonra PS5’in bağlı olduğu HDMI girişine geç. HDMI üzerinde gösterim desteği TV’nin sistemine bağlıdır.":
      "You need the phone app, a PS5, and an Android TV that can run Console Game Translator TV. Grant the TV app permission to display over other apps, pair your phone with the TV, and start translation on the phone. Subtitle display must be enabled on the TV. Then switch to the PS5 HDMI input. Overlay support over HDMI depends on the TV system.",
  "Telefon oyun görüntüsünü TV’ye gönderiyor mu?":
      "Does my phone send gameplay video to the TV?",
  "Hayır. Oyun görüntüsü PS5’in HDMI bağlantısından gelir. Telefon, Remote Play görüntüsünü metni okumak için kullanır; TV’ye çevrilmiş altyazı metnini ve görünüm ayarlarını gönderir. TV uygulaması bu metni ayrı bir katmanda gösterir.":
      "No. Gameplay comes from the PS5 HDMI connection. Your phone uses the Remote Play picture to read text and sends translated subtitle text and appearance settings to the TV. The TV app displays that text in a separate overlay.",
  "Uygulama arka plandayken veya telefonun ekranı kapalıyken çeviri devam eder mi?":
      "Does translation continue in the background or with the phone screen off?",
  "Evet. Çeviriyi Başlat’tan sonra Remote Play ve OCR arka planda çalışır; uygulama ana sayfaya döner. Başka bir uygulamaya geçebilir veya ekranı kapatabilirsin. Bildirimlere izin vererek çeviri durumunu takip edebilirsin. Kesinti olursa uygulamaya dönüp PS5 ve TV bağlantısını kontrol et; telefonun pil ayarlarında uygulamanın arka plan çalışmasını kısıtlamadığından emin ol. Zorla durdurma işlemi oturumu sonlandırır.":
      "Yes. After Start Translation, Remote Play and OCR run in the background and the app returns to its home screen. You can use another app or turn off the screen. Allow notifications to follow translation status. If translation stops updating, return to the app and check the PS5 and TV connections, and make sure the phone battery settings allow background activity. Force-stopping the app ends the session.",
  "Çeviriyi Başlat’a bastığımda neden başlamıyor?":
      "Why does translation not start when I tap Start Translation?",
  "PS5 kaydı hazır, Android TV bağlı ve seçili modelin dil paketleri indirilmiş olmalı. Ayrıca Google hesabınla giriş yapıp kullanılabilir deneme süresine veya Premium erişime sahip olmalısın. Ekrandaki hata mesajına göre eksik adımı tamamla. PS5 yeniden bağlanıyorsa bekle; başarısız olursa bağlantıları kontrol edip tekrar dene.":
      "Your PS5 registration must be ready, Android TV connected, and the selected model language packs downloaded. You also need to sign in with Google and have remaining trial time or Premium access. Complete any missing step described in the error message. If the PS5 is reconnecting, wait; if it fails, check the connections and try again.",
  "Altyazılar TV’de görünmüyor. Neleri kontrol etmeliyim?":
      "Subtitles are not appearing on the TV. What should I check?",
  "Telefondaki Android TV kartında Bağlı yazdığını ve çevirinin çalıştığını kontrol et. TV uygulamasında İzin ver ile üstte gösterim iznini ver; izin zaten açıksa Altyazıyı aç / yenile’yi kullan. Altyazılar duraklatılmışsa Altyazıları sürdür’e bas. Oyundaki metin sarı OCR alanında olmalı. TV’yi PS5’in HDMI girişine al; sorun sürerse TV uygulamasını yeniden açıp bağlantı durumuna bak.":
      "Check that the phone Android TV card says Connected and translation is running. In the TV app, use Grant permission to allow overlays; if already allowed, use Open / refresh subtitles. If paused, select Resume subtitles. The game text must be inside the yellow OCR area. Switch the TV to the PS5 HDMI input. If needed, reopen the TV app and check its connection status.",
  "OCR metni yanlış okuyor veya geç algılıyor. Ne yapabilirim?":
      "OCR reads text incorrectly or detects it slowly. What can I do?",
  "Altyazı → Altyazı görünümü bölümünde sarı OCR alanını yalnızca okunacak metni tam kapsayacak şekilde ayarla. Konuşma altyazılarında diyalog filtresini deneyebilir, görev ve menü yazılarında kapalı tutabilirsin. Ön işleme ve ölçek ayarları her OCR alanı için ayrıdır; küçük yazıda 1,5× veya 2× ölçeği dene. Oyundaki altyazı arka planını açmak ve yazıyı büyütmek de okumayı iyileştirebilir.":
      "Open Subtitles → Subtitle appearance and adjust the yellow OCR area to contain only the complete text you want to read. Try the dialogue filter for spoken subtitles; leave it off for quest and menu text. Preprocessing and scale settings are separate for each OCR area. Try 1.5× or 2× for small text. Enabling the game subtitle background and increasing its text size may also improve recognition.",
  "İstediğim dil neden kaynak veya hedef listesinde görünmüyor?":
      "Why is my language missing from the source or target list?",
  "Dil menüleri seçili modelin desteklediği tüm dilleri gösterir; indirilmemiş olanlar “indirilmedi” olarak işaretlenir. Dili seçtikten sonra altındaki İndir’e dokun veya Dilleri görüntüle ve indir’den paketi indir. Model A’da kaynak dil İngilizcedir; hedef dil paketini seçersin. Model B’de kaynak ve hedef paketleri ayrı gerekir. Bir modelin listesinde bulunmayan dil için diğer modelin desteklediği dilleri kontrol et.":
      "Language menus show every language the selected model supports; languages not downloaded yet are marked “not downloaded”. After selecting one, tap Download below it or download the pack from View and download languages. Model A uses English as its source and a selected target pack. Model B needs separate source and target packs. If a model does not list a language, check the languages supported by the other model.",
  "Model A ve Model B arasındaki fark nedir?":
      "What is the difference between Model A and Model B?",
  "Model A daha yavaş çalışır ancak daha doğru ve kaliteli çeviriler sunar. Model B daha hızlıdır; çevirileri zaman zaman daha az isabetli olabilir. Kalite önceliğinse Model A’yı, hız önceliğinse Model B’yi tercih edebilirsin.":
      "Model A is slower but provides more accurate, higher-quality translations. Model B is faster, but its translations can be less accurate. Choose Model A when quality matters most, or Model B when speed is your priority.",
  "Altyazı sekmesindeki Oyun Kütüphanesi ne işe yarar?":
      "What is the Game Library in the Subtitles tab for?",
  "Oyun Kütüphanesi, oyununa özel hazır çevirilerle hikâyeyi daha rahat takip etmene yardımcı olur. En iyi deneyim için oyunun listede varsa Altyazı sekmesindeki Oyun Kütüphanesi bölümünden seç.":
      "The Game Library helps you follow the story more easily with prepared translations for your game. For the best experience, select your game from the Game Library in the Subtitles tab if it is listed.",
  "Uygulamaya döndüğümde PS5’i yeniden kaydetmem gerekir mi?":
      "Do I need to register my PS5 again when I return to the app?",
  "Hayır. Oturum sürüyorsa mevcut Remote Play bağlantısı kullanılır. Beklenmedik kopmalarda uygulama yeniden bağlanmayı dener; PS5 kartında yeniden bağlanma veya görüntü yenileme durumunu görebilirsin. Denemeler sonuç vermezse konsolun ve ağın açık olduğunu kontrol edip çeviriyi tekrar başlat. PS5’i listeden kaldırmadığın sürece tekrar kayıt gerekmez.":
      "No. An active session reuses the existing Remote Play connection. After an unexpected disconnect, the app attempts to reconnect; the PS5 card can show reconnection or picture recovery status. If retries fail, check the console and network and start translation again. You do not need to register again unless you removed the PS5 from the list.",
  "Çeviriyi durdurunca PS5 kaydı veya TV eşleştirmesi silinir mi?":
      "Does stopping translation delete my PS5 registration or TV pairing?",
  "Hayır. Çeviriyi Durdur, Remote Play ve çeviri akışını durdurup TV’deki mevcut altyazıyı temizler. Kayıtlı PS5, TV eşleştirmesi, dil paketleri ve altyazı ayarları korunur. PS5’i listeden kaldırmak ayrı bir işlemdir; TV eşleştirmesi de TV uygulamasındaki sıfırlama işlemiyle ayrıca yenilenir.":
      "No. Stop Translation stops Remote Play and translation and clears the current TV subtitle. Your registered PS5, TV pairing, language packs, and subtitle settings are kept. Removing the PS5 from the list is a separate action. TV pairing can be reset separately in the TV app.",
  "TV eşleştirme kodu veya bağlantısı çalışmıyor. Ne yapmalıyım?":
      "The TV pairing code or connection is not working. What should I do?",
  "İlk eşleştirmede TV uygulamasını aç; TV ve telefonu aynı yerel ağa bağla. TV’yi ağda bul ile TV’yi seç veya ekrandaki adresi elle gir, ardından güncel 6 haneli kodu kullan. Kimlik doğrulama ekranı açılırsa değeri TV’deki Güvenli bağlantı kimliği ile karşılaştır. Daha önce eşleşmiş TV bağlanmıyorsa TV uygulamasını yeniden açıp tekrar dene; eşleştirme sıfırlandıysa yeniden eşleştir.":
      "For initial pairing, open the TV app and connect both devices to the same local network. Use Find TV on network or enter the displayed address manually, then use the current 6-digit code. If identity verification appears, compare it with the Secure connection identity shown on the TV. If a previously paired TV will not connect, reopen the TV app and retry. Pair again if pairing was reset.",
  "PSN bağlantısında hangi hesabı ve hangi yönlendirme adresini kullanmalıyım?":
      "Which PSN account and redirect URL should I use?",
  "Remote Play için yeni veya kullanmadığın ayrı bir PSN hesabı kullan ve bu hesabı PS5’e kullanıcı olarak ekle; oyunu ana hesabında oynarsın. PSN ile giriş yap’tan sonra açılan beyaz redirect sayfasında adres çubuğundaki bağlantının tamamını kopyala. Uygulamada Yönlendirme URL’si alanına yapıştırıp PSN hesabını doğrula’ya bas. Kod geçersiz veya kullanılmışsa giriş işlemini yeniden başlatıp yeni adresi kopyala.":
      "Use a new or unused separate PSN account for Remote Play and add it as a PS5 user; play the game with your main account. After Sign in with PSN opens the white redirect page, copy the entire URL from the browser address bar. Paste it into Redirect URL in the app and select Verify PSN account. If the code is invalid or already used, restart sign-in and copy the new URL.",
  "Çeviri için internet gerekli mi?":
      "Does translation require an internet connection?",
  "OCR ve indirilmiş modellerle metin çevirisi telefonda yapılır; metin çevirisi için buluta gönderilmez. Ancak ilk kurulum, Google/PSN girişi, dil veya Oyun Kütüphanesi üzerinden çeviri indirme, erişim ve satın alma doğrulamaları için internet gerekir. Kullanım sırasında telefon, PS5 ve TV’nin aynı yerel ağdaki bağlantısı sürmelidir; uygulamanın bütünü için tamamen çevrimdışı çalışma garantisi yoktur.":
      "OCR and translation with downloaded models run on your phone; text is not sent to the cloud for translation. Internet is needed for initial setup, Google/PSN sign-in, language downloads or translation downloads from the Game Library, and access and purchase verification. During use, your phone, PS5, and TV must stay connected on the same local network. Fully offline operation of the entire app is not guaranteed.",
  "Telefonu, PS5’i ve TV’yi aynı ağa bağla":
      "Connect your phone, PS5, and TV to the same network",
  "Telefon, PS5 ve Android TV aynı yönlendiricinin yerel ağına bağlı olmalı. PS5 veya TV Ethernet, telefon Wi-Fi kullanabilir; misafir ağı ya da cihazları birbirinden ayıran ağ ayarları bağlantıyı engelleyebilir.":
      "Your phone, PS5, and Android TV must be on the same router local network. The PS5 or TV can use Ethernet while the phone uses Wi-Fi. A guest network or settings that isolate devices can prevent connections.",
  "İlk kurulumda PS5 ve TV açık olsun. Google/PSN girişi, dil paketleri ve gerekiyorsa Oyun Kütüphanesi üzerinden çeviri indirme işlemleri için internet bağlantını hazır tut.":
      "Keep the PS5 and TV turned on during initial setup. Have an internet connection ready for Google/PSN sign-in, language packs, and any translation downloads from the Game Library.",
  "PS5’te Remote Play’i etkinleştir": "Enable Remote Play on your PS5",
  "PS5’te Ayarlar → Sistem → Remote Play bölümünü aç ve Remote Play’i Etkinleştir seçeneğini aç.":
      "On your PS5, open Settings → System → Remote Play and turn on Enable Remote Play.",
  "Dinlenme modundaki konsola bağlanmak istiyorsan Ayarlar → Sistem → Güç Tasarrufu → Dinlenme Modunda Kullanılabilen Özellikler bölümünde İnternete Bağlı Kal ve PS5’in Ağdan Açılmasını Etkinleştir seçeneklerini aç. İlk kayıt için konsolu açık tut.":
      "To connect while the console is in rest mode, open Settings → System → Power Saving → Features Available in Rest Mode and enable Stay Connected to the Internet and Enable Turning On PS5 from Network. Keep the console on for initial registration.",
  "PSN hesabını doğrula ve PS5’i kaydet":
      "Verify your PSN account and register your PS5",
  "Önemli: Remote Play için yeni veya kullanmadığın ayrı bir PSN hesabı kullan ve bu hesabı PS5’e kullanıcı olarak ekle. Oyunu kendi ana PSN hesabında oynayacaksın.":
      "Important: Use a new or unused separate PSN account for Remote Play and add it as a user on your PS5. You will play using your main PSN account.",
  "Ana sayfadaki PlayStation 5 kartında PS5’i kur’a dokun, ardından PSN ile giriş yap’ı aç. Girişten sonra beyaz redirect sayfasındayken tarayıcının adres çubuğundaki bağlantının tamamını kopyala. Uygulamadaki Yönlendirme URL’si alanına yapıştır ve PSN hesabını doğrula’ya bas.":
      "On the home screen PlayStation 5 card, tap Set up PS5, then Sign in with PSN. After signing in, copy the entire browser address bar URL from the white redirect page. Paste it into Redirect URL in the app and select Verify PSN account.",
  "Sonraki adım: PS5 konsolunu bağla’ya geç. Konsolda Ayarlar → Sistem → Remote Play → Cihazı Bağla’yı aç. Konsolu ağda bul veya IP adresini elle gir; PS5’in gösterdiği güncel 8 haneli PIN’i yazıp PS5 bağlantısını başlat’a dokun.":
      "Continue with Next step: Connect PS5 console. On the console, open Settings → System → Remote Play → Link Device. Find the console on the network or enter its IP address manually, then enter the current 8-digit PIN shown by the PS5 and tap Start PS5 connection.",
  "IP adresini PS5’te Ayarlar → Ağ → Bağlantı Durumu bölümünde bulabilirsin. Kayıt tamamlandığında ana sayfadaki PS5 kartında Hazır görünür. PS5’in kayıt PIN’i, TV’nin 6 haneli eşleştirme kodundan farklıdır.":
      "Find the IP address under Settings → Network → Connection Status on the PS5. When registration completes, the PS5 card on the home screen shows Ready. The PS5 registration PIN is different from the TV 6-digit pairing code.",
  "Android TV uygulamasını hazırla": "Prepare the Android TV app",
  "TV uygulamasında İzin ver’e bas, İzin ayarlarını aç ile Android’in izin ekranına geç ve diğer uygulamaların üzerinde gösterime izin ver. Uygulamaya dönünce altyazı katmanı hazırlanır. İzin zaten açıksa düğmenin adı Altyazıyı aç / yenile olur.":
      "In the TV app, select Grant permission, then Open permission settings, and allow display over other apps in Android settings. The subtitle overlay is prepared when you return. If permission is already granted, the button is called Open / refresh subtitles.",
  "Altyazı gösterimi duraklatılmışsa Altyazıları sürdür’e bas. Eşleştirmeden sonra TV uygulaması ekranda açık kalmak zorunda değildir; TV açık ve ağa bağlıyken alıcı arka planda çalışabilir. TV yeniden başladıktan veya uygulama zorla durdurulduktan sonra bağlantı kurulmazsa uygulamayı yeniden aç.":
      "If subtitle display is paused, select Resume subtitles. After pairing, the TV app does not need to remain on screen; the receiver can run in the background while the TV is on and connected. If it does not reconnect after a TV restart or force stop, reopen the TV app.",
  "Telefonu TV ile eşleştir": "Pair your phone with the TV",
  "Ana sayfadaki Android TV kartında TV’yi eşleştir’e bas. TV uygulaması açıkken TV’yi ağda bul’u kullan veya TV ekranındaki adresi elle gir. Birden fazla sonuç varsa ekrandaki adresle aynı olanı seç.":
      "On the home screen Android TV card, tap Pair TV. With the TV app open, use Find TV on network or enter the address shown on the TV manually. If there are multiple results, choose the one matching the TV address.",
  "TV’deki güncel 6 haneli kodu girip Eşleştir ve bağlan’a dokun. TV kimliğini doğrula ekranı açılırsa telefondaki değerin TV’deki Güvenli bağlantı kimliği ile tamamının eşleştiğini kontrol ederek onayla.":
      "Enter the current 6-digit code from the TV and tap Pair and connect. If Verify TV identity appears, confirm only after checking that the complete value matches the Secure connection identity on your TV.",
  "Telefonun Android TV kartında Bağlı durumunu gör. Eşleştirme kayıtlı • TV bağlı değil yazması çeviri için yeterli değildir. Sonraki kullanımda kayıtlı eşleştirme ile yeniden bağlantı denenir; bağlanmazsa TV uygulamasını açıp tekrar dene.":
      "Check that the phone Android TV card shows Connected. Pairing saved • TV not connected is not enough to start translation. Later sessions attempt to reconnect using the saved pairing. If this fails, open the TV app and retry.",
  "Çeviri modelini ve dil paketlerini hazırla":
      "Prepare your translation model and language packs",
  "Ana sayfada Model A veya Model B’yi seç. Model A daha yavaş çalışır ancak daha doğru ve kaliteli çeviriler sunar. Model B daha hızlıdır; çevirileri zaman zaman daha az isabetli olabilir.":
      "On the home screen, choose Model A or Model B. Model A is slower but provides more accurate, higher-quality translations. Model B is faster, but its translations can be less accurate.",
  "Dilleri görüntüle ve indir’i aç. Model A için İngilizceden çevireceğin hedef dil paketini, Model B için kaynak ve hedef dil paketlerini indir. Ardından dil seçimlerini yap; örneğin English → Türkçe. Her modelin paketleri ayrıdır.":
      "Open View and download languages. For Model A, download the pack for translating from English into your target language. For Model B, download the source and target language packs. Then select your languages, for example English → Turkish. Each model uses separate packs.",
  "Daha hızlı ve kaliteli bir çeviri deneyimi için Altyazı sekmesindeki Oyun Kütüphanesi bölümünden oyununu seç. Hazır oyun çevirileri, hikâyeyi daha doğal ve akıcı biçimde takip etmene yardımcı olur.":
      "For faster, higher-quality translations, select your game from the Game Library in the Subtitles tab. Prepared game translations help you follow the story more naturally and fluently.",
  "OCR ve altyazı alanlarını ayarla": "Adjust the OCR and subtitle areas",
  "Altyazı sekmesinde Altyazı görünümü’nü aç. Canlı oyun görüntüsünü görmek için PS5 kartından Remote Play’i açabilirsin. Sarı OCR alanını oyundaki metni tam kapsayacak şekilde yerleştir; yalnızca bu alanlardaki metin okunur.":
      "Open Subtitles → Subtitle appearance. You can open Remote Play from the PS5 card to see the live game picture. Position the yellow OCR area to fully contain the game text; only text inside these areas is read.",
  "Çevrilmiş metnin yerini, boyutunu ve görünümünü altyazı ayarlarından düzenle. Sarı OCR alanı ile turkuaz altyazı alanı birbirinden bağımsızdır; birden fazla alan ekleyebilir, alanları sürükleyip boyutlandırabilirsin.":
      "Adjust translated text position, size, and appearance in subtitle settings. Yellow OCR areas and turquoise subtitle areas are independent. You can add multiple areas, move them, and resize them.",
  "Konuşma altyazıları için diyalog filtresini deneyebilirsin; görev ve menü metinlerinde kapalı tut. Ön işleme ve OCR ölçeği her alan için ayrı ayarlanır. Değişiklikler otomatik kaydedilir; Kaydet ile de saklayabilirsin.":
      "Try the dialogue filter for spoken subtitles and leave it off for quest and menu text. Preprocessing and OCR scale are configured separately for each area. Changes save automatically; you can also use Save.",
  "Çeviriyi başlat ve PS5’te oyna": "Start translation and play on your PS5",
  "Ana sayfada PS5 kaydı hazır, Android TV Bağlı ve dil paketleri indirilmişken Çeviriyi Başlat’a dokun. Google hesabınla giriş yapıp kullanılabilir deneme süresine veya Premium erişime sahip olmalısın.":
      "On the home screen, with PS5 registration ready, Android TV Connected, and language packs downloaded, tap Start Translation. You must be signed in with Google and have remaining trial time or Premium access.",
  "Remote Play ve çeviri hazır olunca uygulama ana sayfaya döner. İlk kullanımda Alanları ayarla önerisi çıkarsa oyundaki metne göre OCR ve altyazı alanlarını düzenle. Sonradan Altyazı → Altyazı görünümü’nden aynı ayarlara dönebilirsin.":
      "When Remote Play and translation are ready, the app returns to its home screen. If the Adjust areas prompt appears on first use, configure OCR and subtitle areas for your game. You can return to these settings through Subtitles → Subtitle appearance.",
  "Oyunu ana PSN hesabında oyna ve TV’yi PS5’in HDMI girişine al. TV uygulamasını ekranda açık tutman gerekmez. Telefon arka plandayken veya ekranı kapalıyken çeviri sürebilir; kesinti olursa bağlantıları ve telefonun pil kısıtlamalarını kontrol et.":
      "Play using your main PSN account and switch the TV to the PS5 HDMI input. The TV app does not need to stay on screen. Translation can continue with the phone app in the background or its screen off; if interrupted, check connections and phone battery restrictions.",
  "Bitirirken telefonda Çeviriyi Durdur’a veya çeviri bildirimindeki Durdur’a bas. Remote Play ve çeviri durur; PS5 kaydı, TV eşleştirmesi ve ayarların korunur.":
      "To finish, tap Stop Translation on the phone or Stop in the translation notification. Remote Play and translation stop; your PS5 registration, TV pairing, and settings are kept.",
  'TV uygulaması artık Google Play’de. Android TV / Google TV cihazında Play Store’da **Oyun Çevirmeni TV** diye arayıp kur. TV’nin dili İngilizceyse **Console Game Translator TV** yaz. İstersen aşağıdaki düğmeyle mağaza sayfasını da açabilirsin.':
      'The TV app is now on Google Play. On your Android TV / Google TV, search the Play Store for **Console Game Translator TV** and install it. You can also open the store page with the button below.',
  'Google Play’de aç': 'Open in Google Play',
};
