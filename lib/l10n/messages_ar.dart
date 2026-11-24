// Modern Standard Arabic interface messages, keyed by Turkish source text.
// Keep application names, product names and protocol identifiers unchanged.
const arabicMessages = <String, String>{
  'Kişiselleştir': 'التخصيص',
  'Uygulama dili Model B’nin hedef dilini otomatik ayarlar.':
      'تحدّد لغة التطبيق تلقائيًا اللغة المستهدفة في Model B.',
  'Temizle': 'مسح',
  'Yenile': 'تحديث',
  '1,5× · dengeli': '1.5× • متوازن',
  "Bu oyunun çeviri paketi telefonun belleğine sığmadı. Diğer uygulamaları kapatıp tekrar dene.":
      "لم تتسع ذاكرة الهاتف لحزمة ترجمة هذه اللعبة. أغلق التطبيقات الأخرى وحاول مجددًا.",
  "Ücretsiz denemen hazır. Remote Play bağlantısıyla başlar.":
      "تجربتك المجانية جاهزة. تبدأ عند اتصال Remote Play.",
  "Geliştirmeye katkıda bulun": "ساهم في تحسين التطبيق",
  "Geliştiriciye gönder": "إرسال إلى المطوّر",
  "İstersen son çevirilerinden bir dosyayı geliştiriciyle paylaşabilirsin. E-posta için en fazla 5.000 kayıt ve 5 MiB hazırlanır.":
      "يمكنك مشاركة ملف من ترجماتك الأخيرة مع المطوّر إن رغبت. يُجهَّز للبريد الإلكتروني ما يصل إلى 5,000 سجل بحجم أقصاه 5 MiB.",
  "Dosyada yalnızca çeviri kayıtları bulunur; API anahtarların ve uygulama hesabı bilgilerin eklenmez. Paylaştığın kayıtlar uygulamayı geliştirmek için kullanılır.":
      "يحتوي الملف على سجلات الترجمة فقط، دون مفاتيح API أو بيانات حسابك في التطبيق. تُستخدم السجلات التي تشاركها لتحسين التطبيق.",
  "{0} kayıt • {1} MiB\nAlıcı: {2}": "{0} سجل • {1} MiB\nإلى: {2}",
  "Dosyayı açılan e-postanın ekinden inceleyebilirsin. Gönderimi e-posta uygulamasında sen tamamlarsın.":
      "يمكنك مراجعة الملف المرفق في مسودة البريد الإلكتروني. تتولى أنت إتمام الإرسال من تطبيق البريد.",
  "E-posta taslağını aç": "فتح مسودة البريد",
  "E-posta uygulaması seç": "اختيار تطبيق بريد",
  "{0} - Çeviri kaydı katkısı": "{0} - مساهمة بسجلات الترجمة",
  "Çeviri kayıtlarını uygulamanın geliştirilmesi amacıyla isteğe bağlı olarak paylaşıyorum.\n\nÇeviri dosyası ektedir.":
      "أشارك سجلات الترجمة طوعًا للمساهمة في تحسين التطبيق.\n\nملف الترجمة مرفق.",
  "Paylaşılacak çeviri kaydı yok.": "لا توجد سجلات ترجمة لمشاركتها.",
  "Gönderimi e-posta uygulamasından tamamlayabilirsin.":
      "يمكنك إتمام الإرسال من تطبيق البريد الإلكتروني.",
  "E-posta taslağı açılamadı. Önbelleği dışarı aktararak bize gönderebilirsin.":
      "تعذّر فتح مسودة البريد. يمكنك تصدير ذاكرة التخزين المؤقت وإرسالها إلينا.",
  "E-posta uygulaması bulunamadı. Önbelleği dışarı aktararak abrebostudio@gmail.com adresine gönderebilirsin.":
      "لم يُعثر على تطبيق بريد. يمكنك تصدير ذاكرة التخزين المؤقت وإرسالها إلى abrebostudio@gmail.com.",
  "Gelişmiş": "إعدادات متقدمة",
  "Çeviri önbelleği": "ذاكرة التخزين المؤقت للترجمة",
  "Saklama sınırları, yedekleme ve temizleme":
      "حدود الاحتفاظ والنسخ الاحتياطي والتنظيف",
  "Gemini ve DeepL çevirilerini cihazında sakla; tekrar eden altyazılarda API isteğini azalt.":
      "احتفظ بترجمات Gemini وDeepL على جهازك لتقليل طلبات API عند تكرار النصوص.",
  "Kayıtlı çeviriler": "الترجمات المحفوظة",
  "{0} çeviri • {1} MiB": "{0} ترجمة • {1} MiB",
  "Her sağlayıcı için saklama sınırları": "حدود الاحتفاظ لكل مزوّد",
  "Saklama süresi": "مدة الاحتفاظ",
  "En fazla çeviri": "الحد الأقصى للترجمات",
  "En fazla alan": "الحد الأقصى للمساحة",
  "{0} gün": "{0} يوم",
  "{0} çeviri": "{0} ترجمة",
  "{0} MiB": "{0} MiB",
  "Gün sınırı kayıt tarihinden hesaplanır. Sınırları azaltmak eski kayıtları kaldırabilir; okumak saklama süresini uzatmaz.":
      "تُحسب المدة من تاريخ حفظ السجل. قد يؤدي خفض الحدود إلى حذف السجلات القديمة؛ ولا تؤدي قراءة السجل إلى تمديد مدة الاحتفاظ به.",
  "Sınırları kaydet": "حفظ الحدود",
  "Varsayılana dön": "استعادة الإعدادات الافتراضية",
  "Yedekle ve geri yükle": "النسخ الاحتياطي والاستعادة",
  "Dosya altyazı metinlerini içerir; API anahtarlarını ve hesap bilgilerini içermez. İçeri aktarma mevcut kayıtları birleştirir; ayarlarını değiştirmez. Model A/B oturum önbelleği yedeğe dahil değildir.":
      "يحتوي الملف على نصوص الترجمة، دون مفاتيح API أو بيانات الحساب. يدمج الاستيراد السجلات الحالية دون تغيير إعداداتك. لا يشمل النسخ الاحتياطي ذاكرة جلسة Model A/B المؤقتة.",
  "Dışarı aktar": "تصدير",
  "İçeri aktar": "استيراد",
  "Önbelleği içeri aktar": "استيراد ذاكرة الترجمة",
  "Geçerli kayıt: {0}\nSüresi dolmuş veya ileri tarihli: {1}\nDosya içindeki tekrarlar: {2}\n\nMevcut kayıtlarla birleştirilir; aynı çevirinin en yenisi korunur. Seçtiğin saklama sınırları uygulanır.":
      "السجلات الصالحة: {0}\nالمنتهية أو المؤرخة في المستقبل: {1}\nالسجلات المكررة في الملف: {2}\n\nتُدمج مع السجلات الحالية، وتُحفظ أحدث نسخة من كل ترجمة. تُطبَّق حدود الاحتفاظ التي اخترتها.",
  "{0} önbelleği temizlensin mi?": "هل تريد مسح ذاكرة {0} المؤقتة؟",
  "Kaydedilmiş çeviriler kaldırılır. Aynı metinler için yeniden çeviri isteği gerekebilir.":
      "ستُحذف الترجمات المحفوظة. قد تتطلب ترجمة النصوص نفسها إرسال طلبات ترجمة جديدة.",
  "Önbelleği temizle": "مسح ذاكرة التخزين المؤقت",
  "Önbellek sınırları kaydedildi.": "تم حفظ حدود ذاكرة التخزين المؤقت.",
  "Seçilen önbellek temizlendi.": "تم مسح ذاكرة التخزين المؤقت المحددة.",
  "Önbellek dosyası kaydedildi.":
      "تم حفظ النسخة الاحتياطية لذاكرة التخزين المؤقت.",
  "Önbellek içeri alındı.": "تم استيراد ذاكرة التخزين المؤقت.",
  "Önbellek yönetimi bu platformda kullanılamıyor.":
      "إدارة ذاكرة التخزين المؤقت غير متاحة على هذه المنصة.",
  "Önbellek bilgileri alınamadı. Tekrar dene.":
      "تعذّر تحميل معلومات ذاكرة التخزين المؤقت. حاول مجددًا.",
  "Önbelleği değiştirmeden önce çeviriyi durdur.":
      "أوقف الترجمة قبل تعديل ذاكرة التخزين المؤقت.",
  "Önbellek işleminin tamamlanmasını bekle.":
      "انتظر حتى تكتمل عملية ذاكرة التخزين المؤقت.",
  "Önbellek işlemi tamamlanamadı. Dosyayı ve kullanılabilir alanı kontrol et.":
      "تعذّر إكمال العملية. تحقّق من الملف والمساحة المتاحة.",
  "Önce açık dosya seçimini tamamla.": "أكمل اختيار الملف الحالي أولًا.",
  "Dosya seçimi için uygulamayı aç.": "افتح التطبيق لاختيار ملف.",
  "Bu cihazda dosya seçici açılamadı.":
      "تعذّر فتح منتقي الملفات على هذا الجهاز.",
  "En fazla 5 anahtar ekleyebilirsin. Bir anahtar sınıra ulaşırsa hazır diğer anahtara geçilir; hepsi bekliyorsa önbellek ve yüklü Model A/B kullanılır.":
      "يمكنك إضافة 5 مفاتيح كحد أقصى. إذا بلغ أحدها الحد المسموح، يُستخدم مفتاح آخر متاح. وعندما تكون جميع المفاتيح قيد الانتظار، تُستخدم الترجمات المخزّنة وحزم Model A/B المثبتة.",
  "Aynı Google projesindeki anahtarlar ortak kotayı kullanır. Anahtar eklemek proje kotasını artırmaz; diğer anahtarın da kullanılabilir kotası olmalıdır.":
      "تتشارك مفاتيح مشروع Google نفسه الحصة ذاتها. إضافة مفتاح لا تزيد حصة المشروع؛ ويجب أن تتوفر حصة متبقية للمفتاح الآخر أيضًا.",
  "Anahtar {0}": "المفتاح {0}",
  "Kullanılıyor": "قيد الاستخدام",
  "Bu anahtarı sil": "حذف هذا المفتاح",
  "Tüm anahtarları sil": "حذف جميع المفاتيح",
  "Test et ve ekle": "اختبار وإضافة",
  "Bu Gemini anahtarı zaten kayıtlı.": "مفتاح Gemini هذا محفوظ بالفعل.",
  "En fazla 5 Gemini anahtarı kaydedebilirsin.":
      "يمكنك حفظ 5 مفاتيح Gemini كحد أقصى.",
  "Gemini beklerken önce önbellek, ardından bu dil çifti için yüklü Model A veya Model B kullanılır. İkisi de hazırsa Model A seçilir. Yerel paketleri ilgili modelin dil paketleri bölümünden indirebilirsin.":
      "أثناء انتظار Gemini، تُستخدم الترجمات المخزّنة أولًا، ثم Model A أو Model B المثبّت لزوج اللغات هذا. إذا كان كلاهما جاهزًا، تكون الأولوية لـModel A. يمكنك تنزيل الحزم المحلية من قسم حزم اللغات للنموذج المعني.",
  "Model A ile yerel çeviri kullanılıyor.":
      "تُستخدم الترجمة المحلية عبر Model A.",
  "Model B ile yerel çeviri kullanılıyor.":
      "تُستخدم الترجمة المحلية عبر Model B.",
  "Bu dil çifti için yerel paket yüklü değil. Model A veya B dil paketini indir. Önbellekteki çeviriler kullanılabilir.":
      "لا توجد حزمة محلية مثبتة لزوج اللغات هذا. نزّل حزمة Model A أو Model B. تظل الترجمات المخزّنة متاحة.",
  "Yerel paket açılamadı. Model A veya B dil paketini yeniden indir. Önbellekteki çeviriler kullanılabilir.":
      "تعذّر فتح الحزمة المحلية. أعد تنزيل حزمة Model A أو Model B. تظل الترجمات المخزّنة متاحة.",
  "Yerel paketler kontrol ediliyor.": "جارٍ التحقّق من حزم اللغات المحلية.",
  "Gemini bekliyor. Model A ile yerel çeviri kullanılıyor.":
      "Gemini قيد الانتظار. تُستخدم الترجمة المحلية عبر Model A.",
  "Gemini bekliyor. Model B ile yerel çeviri kullanılıyor.":
      "Gemini قيد الانتظار. تُستخدم الترجمة المحلية عبر Model B.",
  "Gemini bekliyor. Bu dil çifti için yerel paket yüklü değil. Model A veya B dil paketini indir. Önbellekteki çeviriler kullanılabilir.":
      "Gemini قيد الانتظار. لا توجد حزمة محلية مثبتة لزوج اللغات هذا. نزّل حزمة Model A أو Model B. تظل الترجمات المخزّنة متاحة.",
  "Gemini bekliyor. Yerel paket açılamadı. Model A veya B dil paketini yeniden indir. Önbellekteki çeviriler kullanılabilir.":
      "Gemini قيد الانتظار. تعذّر فتح الحزمة المحلية. أعد تنزيل حزمة Model A أو Model B. تظل الترجمات المخزّنة متاحة.",
  "Gemini günlük kotası doldu. Yerel paketler kontrol ediliyor.":
      "نفدت حصة Gemini اليومية. جارٍ التحقّق من حزم اللغات المحلية.",
  "Hemen abone olun": "اشترك الآن",
  "İsterseniz abone olmadan {0} dakika ücretsiz deneyebilirsiniz.":
      "يمكنك التجربة مجانًا لمدة {0} دقيقة دون اشتراك.",
  "Paketleri ve fiyatları görün": "عرض الباقات والأسعار",
  "Premium paketlerini ve fiyatlarını inceleyebilirsiniz.":
      "اطّلع على باقات Premium وأسعارها.",
  "Ücretsiz denemeniz devam ediyor. Kalan süre: {0}.":
      "تجربتك المجانية مستمرة. الوقت المتبقي: {0}.",
  "Ücretsiz denemeniz sona erdi. Devam etmek için bir paket seçebilirsiniz.":
      "انتهت تجربتك المجانية. اختر باقة للمتابعة.",
  "Abone olmadan deneyin": "جرّب دون اشتراك",
  "Google hesabınızla {0} dakika ücretsiz deneyebilirsiniz.":
      "يمكنك التجربة مجانًا لمدة {0} دقيقة باستخدام حسابك في Google.",
  "Ücretsiz deneme süresi kontrol ediliyor.":
      "جارٍ التحقّق من مدة التجربة المجانية.",
  "Gemini hazır. Güncel altyazı bekleniyor.":
      "Gemini جاهز. بانتظار النص الحالي للترجمة.",
  "Gemini bekliyor. {0} sn sonra güncel altyazıyla yeniden denenecek.":
      "Gemini قيد الانتظار. ستُعاد المحاولة بالنص الحالي بعد {0} ثانية.",
  "Gemini (ücretsiz katman)": "Gemini (الفئة المجانية)",
  "Gemini 3.5 Flash-Lite": "Gemini 3.5 Flash-Lite",
  "Ücretsiz Gemini API anahtarı al": "الحصول على مفتاح Gemini API مجاني",
  "Google AI Studio kullanım ve limitleri":
      "الاستخدام والحدود في Google AI Studio",
  "Gemini API anahtarı": "مفتاح Gemini API",
  "Gemini API anahtarı gerekli": "يلزم مفتاح Gemini API",
  "Gemini bölümüne anahtarını girip test et ve kaydet.":
      "أدخل مفتاحك في قسم Gemini، ثم اختبره واحفظه.",
  "Gemini internet ve kendi API anahtarını gerektirir. Altyazı metinleri Google’a gönderilir. Ücretsiz katmanda bu içerikler Google ürünlerini geliştirmek için kullanılabilir.":
      "يتطلب Gemini اتصالًا بالإنترنت ومفتاح API خاصًا بك. تُرسل نصوص الترجمة إلى Google. في الفئة المجانية، قد تُستخدم هذه النصوص لتحسين منتجات Google.",
  "Google AI Studio’da Google hesabınla giriş yap, bir proje ve API anahtarı oluştur. Ücretsiz kullanım için projen Free Tier olmalı; faturalandırmayı etkinleştirme. Anahtarı aşağıya yapıştır.":
      "سجّل الدخول إلى Google AI Studio بحسابك في Google، وأنشئ مشروعًا ومفتاح API. للاستخدام المجاني، يجب أن يكون مشروعك ضمن الفئة المجانية (Free Tier)؛ لا تفعّل الفوترة. ألصق مفتاحك أدناه.",
  "Ücretsiz kullanım sınırlıdır; istek ve token kotaları projene göre değişir. Ücretli bir proje anahtarı kullanırsan Google ücretlendirebilir. Bağlantı testi kısa bir çeviri isteği gönderir.":
      "الاستخدام المجاني محدود؛ وتختلف حصص الطلبات والرموز بحسب مشروعك. قد تفرض Google رسومًا إذا استخدمت مفتاح مشروع مدفوع. يرسل اختبار الاتصال طلب ترجمة قصيرًا.",
  "Anahtar yalnızca cihazda şifreli saklanır.":
      "يُحفظ مفتاحك مشفّرًا على هذا الجهاز فقط.",
  "Geçerli bir Gemini API anahtarı gir.": "أدخل مفتاح Gemini API صالحًا.",
  "Gemini anahtarı silindi.": "تم حذف مفتاح Gemini.",
  "Gemini bağlantısı başarılı. Çeviri için hazır.":
      "تم الاتصال بـGemini بنجاح. جاهز للترجمة.",
  "Gemini işlemi tamamlanamadı. Tekrar dene.":
      "تعذّر إكمال عملية Gemini. حاول مجددًا.",
  "Gemini bu platformda kullanılamıyor.": "Gemini غير متاح على هذه المنصة.",
  "Gemini için metin ve dil seçimini kontrol et.":
      "تحقّق من النص واللغات المختارة لـGemini.",
  "Gemini bu altyazı için çeviri döndürmedi.":
      "لم يُرجع Gemini ترجمة لهذا النص.",
  "Gemini bu altyazı için tam bir çeviri döndürmedi.":
      "لم يُرجع Gemini ترجمة كاملة لهذا النص.",
  "Gemini çeviri yanıtı geçersiz.": "استجابة الترجمة من Gemini غير صالحة.",
  "Gemini bağlantısı kurulamadı. İnternet bağlantını kontrol et.":
      "تعذّر الاتصال بـGemini. تحقّق من اتصالك بالإنترنت.",
  "Gemini günlük kotası doldu. Google AI Studio kullanım ekranını kontrol et.":
      "نفدت حصة Gemini اليومية. تحقّق من صفحة الاستخدام في Google AI Studio.",
  "Gemini istek sınırına ulaşıldı. Biraz bekle veya Google AI Studio limitlerini kontrol et.":
      "تم بلوغ حد طلبات Gemini. انتظر قليلًا أو راجع حدودك في Google AI Studio.",
  "Gemini API anahtarı kabul edilmedi. Anahtarı ve proje erişimini kontrol et.":
      "لم يُقبل مفتاح Gemini API. تحقّق من المفتاح وصلاحيات الوصول إلى المشروع.",
  "Gemini isteği kabul edilmedi. API anahtarını, bölge uygunluğunu ve proje ayarlarını kontrol et.":
      "لم يُقبل طلب Gemini. تحقّق من مفتاح API وتوفر الخدمة في منطقتك وإعدادات المشروع.",
  "Gemini modeli bu projede kullanılamıyor. Google AI Studio erişimini kontrol et.":
      "نموذج Gemini غير متاح لهذا المشروع. تحقّق من صلاحيات الوصول في Google AI Studio.",
  "Gemini şu anda yanıt veremiyor. Biraz sonra tekrar dene.":
      "Gemini غير متاح حاليًا. حاول مجددًا بعد قليل.",
  "Gemini anahtarı okunamadı. Anahtarı yeniden gir.":
      "تعذّرت قراءة مفتاح Gemini. أدخله مجددًا.",
  "Gemini anahtarı kaydedilemedi. Tekrar dene.":
      "تعذّر حفظ مفتاح Gemini. حاول مجددًا.",
  "Ücretsiz dene": "جرّب مجانًا",
  "ÜCRETSİZ DENEME": "تجربة مجانية",
  "{0} dakika ücretsiz çeviri": "{0} دقيقة من الترجمة المجانية",
  "Google ile {0} dk ücretsiz dene":
      "جرّب مجانًا لمدة {0} دقيقة باستخدام Google",
  "Ödeme bilgisi gerekmez. Otomatik abonelik başlamaz.":
      "لا حاجة إلى بيانات الدفع. لن يبدأ اشتراك تلقائي.",
  "Premium paketleri": "باقات Premium",
  "Planını seç": "اختر باقتك",
  "Önce ücretsiz dene": "جرّب مجانًا أولًا",
  "{0} dakika ücretsiz dene": "جرّب مجانًا لمدة {0} دقيقة",
  "tek ödeme": "دفعة واحدة",
  "Google Play ile güvenli ödeme": "دفع آمن عبر Google Play",
  "İstediğin zaman iptal": "ألغِ في أي وقت",
  "Diyaloglar, görevler ve menüler oynarken çevrilir":
      "ترجمة الحوارات والمهام والقوائم أثناء اللعب",
  "Altyazılar TV’de oyunun üstünde görünür":
      "تظهر الترجمة فوق اللعبة على التلفزيون",
  "Desteklenen oyunlarda hazır, özenli çeviriler":
      "ترجمات جاهزة ومتقنة للألعاب المدعومة",
  "Görsel kurulum rehberi (PDF)": "دليل الإعداد المصوّر (PDF)",
  "Oklarla adım adım anlatım • Türkçe • PS5 + Android TV / Google TV":
      "شرح خطوة بخطوة بالأسهم • باللغة التركية • PS5 + Android TV / Google TV",
  "Oyun iste": "طلب إضافة لعبة",
  "{0} - Oyun isteği": "{0} - طلب إضافة لعبة",
  "Oyun adı: {0}\nİstenen dil:\nOyun sürümü (PS4 / PS5):\n\nEk not:":
      "اسم اللعبة: {0}\nاللغة المطلوبة:\nإصدار اللعبة (PS4 / PS5):\n\nملاحظات إضافية:",
  "İsteği kopyala": "نسخ الطلب",
  "İstek metni kopyalandı.": "تم نسخ نص الطلب.",
  "Altyazı dili": "لغة الترجمة",
  "Bu dilde henüz oyun paketi yok.": "لا توجد حزم ألعاب بهذه اللغة بعد.",
  "Bu seçim arayüz dilini ve oyun kütüphanesindeki dil filtresini belirler.":
      "يحدّد هذا الاختيار لغة الواجهة ومرشّح اللغة في مكتبة الألعاب.",
  "Dil değiştirilemez": "تعذّر تغيير اللغة",
  "Dili veya oyunu değiştirmek için çeviriyi durdur.":
      "أوقف الترجمة لتغيير اللغة أو اللعبة.",
  "Seçili: {0} · {1}": "المحدّد: {0} · {1}",
  "Seçili model bu dili desteklemiyor. Yalnızca oyun paketindeki metinler gösterilir.":
      "النموذج المحدّد لا يدعم هذه اللغة. ستُعرض النصوص الموجودة في حزمة اللعبة فقط.",
  "Kullanımı göster": "عرض الاستخدام",
  "DeepL (önerilen)": "DeepL (موصى به)",
  "Kalan: {0} karakter (%{1})": "المتبقي: {0} حرف ({1}%)",
  "Kalan: Limitsiz": "المتبقي: غير محدود",
  "Ücretsiz DeepL API anahtarı al": "الحصول على مفتاح DeepL API مجاني",
  "DeepL’nin sitesinde ücretsiz bir API hesabı oluştur, API anahtarını buraya yapıştır.":
      "أنشئ حساب API مجانيًا على موقع DeepL، ثم ألصق مفتاح API هنا.",
  "DeepL hesabı: {0} / {1} karakter": "حساب DeepL: ‏{0} / {1} حرف",
  "Limitsiz": "غير محدود",
  "DeepL sayacı birkaç dakika gecikmeli güncellenebilir.":
      "قد يتأخر تحديث عدّاد DeepL بضع دقائق.",
  "DeepL kullanım bilgisi alınamadı. Tekrar dene.":
      "تعذّر تحميل معلومات استخدام DeepL. حاول مجددًا.",
  "DeepL API anahtarı": "مفتاح DeepL API",
  "DeepL API anahtarı gerekli": "يلزم مفتاح DeepL API",
  "DeepL bölümüne anahtarını girip test et ve kaydet.":
      "أدخل مفتاحك في قسم DeepL، ثم اختبره واحفظه.",
  "DeepL internet bağlantısı ve kendi API anahtarını gerektirir. Altyazı metinleri çeviri için DeepL’ye gönderilir; kullanım DeepL hesabının kotasından düşer.":
      "يتطلب DeepL اتصالًا بالإنترنت ومفتاح API خاصًا بك. تُرسل النصوص إلى DeepL لترجمتها، ويُحتسب الاستخدام من حصة حسابك في DeepL.",
  "Anahtar kayıtlı • değiştirmek için yaz": "المفتاح محفوظ • اكتب لاستبداله",
  "Free / Pro otomatik seçilir. Anahtar cihazda şifreli saklanır.":
      "يُحدَّد Free أو Pro تلقائيًا. يُحفظ المفتاح مشفّرًا على جهازك.",
  "Anahtarı göster": "إظهار المفتاح",
  "Anahtarı gizle": "إخفاء المفتاح",
  "Test et ve kaydet": "اختبار وحفظ",
  "Anahtarı sil": "حذف المفتاح",
  "DeepL anahtarı silindi.": "تم حذف مفتاح DeepL.",
  "DeepL bağlantısı başarılı. Çeviri için hazır.":
      "تم الاتصال بـDeepL بنجاح. جاهز للترجمة.",
  "Geçerli bir DeepL API anahtarı gir.": "أدخل مفتاح DeepL API صالحًا.",
  "DeepL API anahtarı kabul edilmedi. Anahtarını kontrol et.":
      "لم يُقبل مفتاح DeepL API. تحقّق من مفتاحك.",
  "DeepL karakter kotası doldu. DeepL hesabını kontrol et.":
      "نفدت حصة الأحرف في DeepL. تحقّق من حسابك في DeepL.",
  "DeepL istek sınırına ulaşıldı. Biraz sonra tekrar dene.":
      "تم بلوغ حد طلبات DeepL. حاول مجددًا بعد قليل.",
  "DeepL dil seçimini kontrol et.": "تحقّق من اللغات المختارة لـDeepL.",
  "DeepL şu anda yanıt veremiyor. Biraz sonra tekrar dene.":
      "DeepL غير متاح حاليًا. حاول مجددًا بعد قليل.",
  "DeepL bağlantısı kurulamadı. İnternet bağlantını kontrol et.":
      "تعذّر الاتصال بـDeepL. تحقّق من اتصالك بالإنترنت.",
  "DeepL çeviri yanıtı geçersiz.": "استجابة الترجمة من DeepL غير صالحة.",
  "DeepL anahtarı okunamadı. Anahtarı yeniden gir.":
      "تعذّرت قراءة مفتاح DeepL. أدخله مجددًا.",
  "DeepL anahtarı kaydedilemedi. Tekrar dene.":
      "تعذّر حفظ مفتاح DeepL. حاول مجددًا.",
  "DeepL işlemi tamamlanamadı. Tekrar dene.":
      "تعذّر إكمال عملية DeepL. حاول مجددًا.",
  "DeepL bu platformda kullanılamıyor.": "DeepL غير متاح على هذه المنصة.",
  "Beta TV desteği": "دعم تجريبي للتلفزيونات",
  "LG webOS ve Samsung Tizen desteği beta aşamasındadır. TV modeline göre bağlantı veya altyazı hataları yaşanabilir.":
      "دعم LG webOS وSamsung Tizen في المرحلة التجريبية. قد تحدث مشاكل في الاتصال أو الترجمة بحسب طراز التلفزيون.",
  "TV uygulamasını indir": "تنزيل تطبيق التلفزيون",
  "TV kurulum rehberini aç": "فتح دليل إعداد التلفزيون",
  "TV bağlantısı için destek al": "الحصول على مساعدة لاتصال التلفزيون",
  "{0} TV bağlantı desteği": "مساعدة في اتصال تلفزيون {0}",
  "TV türü: {0}\nTV modeli:\nTV yazılım sürümü:\nUygulama sürümü: {1}\nSorun yaşadığın adım:\nSorunun açıklaması:\n\nSorunun ekran görüntüsünü bu e-postaya ekleyebilirsin.":
      "نوع التلفزيون: {0}\nطراز التلفزيون:\nإصدار نظام التلفزيون:\nإصدار التطبيق: {1}\nالخطوة التي واجهت فيها المشكلة:\nوصف المشكلة:\n\nيمكنك إرفاق لقطة شاشة للمشكلة بهذا البريد.",
  "Android TV / Google TV • Philips, Sony ve uyumlu cihazlar":
      "Android TV / Google TV • Philips وSony والأجهزة المتوافقة",
  "TV gerekli": "يلزم تلفزيون",
  "Önce TV türünü seçip bağlantı testini tamamla.":
      "اختر نوع التلفزيون وأكمل اختبار الاتصال أولًا.",
  "TV’ye bağlanılıyor": "جارٍ الاتصال بالتلفزيون",
  "TV’ye bağlanılıyor…": "جارٍ الاتصال بالتلفزيون…",
  "Başlamak için TV’yi eşleştir": "أقرن التلفزيون للبدء",
  "Oyun Çevirmeni • TV bağlantı testi":
      "Console Game Translator • اختبار اتصال التلفزيون",
  "Önce TV bağlantısını kontrol edelim.": "لنتحقّق من اتصال التلفزيون أولًا.",
  "Telefon ve TV aynı yerel ağda olsun. TV ayarlarındaki ağ bölümünden yerel IPv4 adresini bul. Bağlanırken TV’de çıkan izin isteğini kumandayla onayla. TV’ye uygulama yüklemek gerekmez.":
      "يجب أن يكون الهاتف والتلفزيون على الشبكة المحلية نفسها. ابحث عن عنوان IPv4 المحلي في قسم الشبكة بإعدادات التلفزيون. وافق بالريموت على طلب الإذن الذي يظهر على التلفزيون عند الاتصال. لا يلزم تثبيت تطبيق على التلفزيون.",
  "LG TV’nin yerel IPv4 adresi": "عنوان IPv4 المحلي لتلفزيون LG",
  "Şifreli bağlantı (3001)": "اتصال مشفّر (3001)",
  "İlk bağlantıda TV sertifikası kaydedilir; sonraki bağlantılarda aynı sertifika aranır. Kimlik ilk kullanımda TV’deki izin onayına dayanır.":
      "تُحفظ شهادة التلفزيون عند الاتصال الأول، ويُشترط تطابقها في الاتصالات اللاحقة. يعتمد التحقّق من الهوية في المرة الأولى على موافقتك على طلب الإذن على التلفزيون.",
  "Eski TV modu (3000): altyazı ve eşleştirme bilgileri yerel ağda şifresiz taşınır. Yalnızca güvendiğin ev ağında kullan.":
      "وضع التلفزيونات القديمة (3000): تُنقل نصوص الترجمة وبيانات الاقتران دون تشفير عبر الشبكة المحلية. استخدمه على شبكة منزلك الموثوقة فقط.",
  "LG bildirim modu: altyazılar TV bildirimi olarak görünür. Konum, yazı tipi ve süreyi TV belirler; çoklu alan metinleri birleştirilir. Durdurduğunda bekleyen metinler iptal edilir, görünen bildirim TV’nin süresi dolunca kapanır.":
      "وضع إشعارات LG: تظهر الترجمة كإشعارات على التلفزيون. يحدّد التلفزيون موضعها وخطها ومدتها، وتُدمج نصوص المناطق المتعددة. عند الإيقاف تُلغى النصوص المعلّقة، ويختفي الإشعار الظاهر عند انتهاء المدة التي يحدّدها التلفزيون.",
  "TV’deki izin isteğini onayla…": "وافق على طلب الإذن على التلفزيون…",
  "Bağlan ve örnek yazı gönder": "الاتصال وإرسال نص تجريبي",
  "PS5’in HDMI görüntüsü açıkken örnek bildirimi gördüysen aşağıdan onayla. Göremediysen bu modu kullanma.":
      "إذا ظهر الإشعار التجريبي أثناء عرض صورة PS5 عبر HDMI، فأكّد ذلك أدناه. إن لم يظهر، فلا تستخدم هذا الوضع.",
  "Samsung TV’de “Console Game Translator TV” uygulamamızın açık olması gerekiyor. Telefonda oluşturduğun kodu bu TV uygulamasına girerek eşleştireceksin.":
      "يجب فتح تطبيقنا «Console Game Translator TV» على تلفزيون Samsung. ستُقرن الجهازين بإدخال الرمز الذي تنشئه على الهاتف في تطبيق التلفزيون.",
  "TV uygulaması henüz kurulu değil mi?": "لم تثبّت تطبيق التلفزيون بعد؟",
  "Samsung TV uygulamamız henüz Samsung mağazasında bulunmuyor. İlk kurulum için sitemizdeki Windows kurulum yardımcısını kullan. Samsung hesabınla TV’ye kurulum iznini bir kez hazırlaman gerekir. Adımlar için TV kurulum rehberini aç.":
      "تطبيقنا لتلفزيون Samsung غير متاح بعد في متجر Samsung. استخدم مساعد التثبيت على Windows من موقعنا للإعداد الأول. يلزم إعداد إذن التثبيت على التلفزيون بحسابك في Samsung مرة واحدة. افتح دليل إعداد التلفزيون لمعرفة الخطوات.",
  "Yeni eşleştirme kodu oluştur": "إنشاء رمز اقتران جديد",
  "TV uygulamam kurulu • Eşleştir": "تطبيق التلفزيون مثبّت • اقتران",
  "Telefonun adresi": "عنوان الهاتف",
  "Eşleştirme kodu": "رمز الاقتران",
  "TV’de uygulamamızı aç. Buradaki telefon adresini ve eşleştirme kodunu TV ekranına gir. Birden fazla adres varsa TV ile aynı ağdakini seç. Kod 2 dakika geçerlidir.":
      "افتح تطبيقنا على التلفزيون. أدخل عنوان الهاتف ورمز الاقتران الظاهرين هنا في شاشة التلفزيون. إذا ظهرت عدة عناوين، فاختر العنوان الموجود على شبكة التلفزيون نفسها. تنتهي صلاحية الرمز بعد دقيقتين.",
  "Kod kullanıldı": "تم استخدام الرمز",
  "HDMI ve örnek altyazı TV’de onaylandı.":
      "تم تأكيد HDMI والنص التجريبي على التلفزيون.",
  "TV bağlandı. TV’de HDMI girişini seçip oyun + örnek altyazı testini onayla.":
      "تم اقتران التلفزيون. اختر مدخل HDMI على التلفزيون وأكّد اختبار صورة اللعبة مع الترجمة التجريبية.",
  "TV uygulamasının bağlanması bekleniyor…": "بانتظار اتصال تطبيق التلفزيون…",
  "Altyazılar için TV uygulamamızı açık tut. Kumandadan Home’a basarsan veya başka bir girişe geçersen altyazılar durur. Bu bağlantıda metinler ev ağında şifresiz iletilir.":
      "أبقِ تطبيقنا مفتوحًا على التلفزيون لعرض الترجمة. تتوقف الترجمة عند الضغط على Home في الريموت أو التبديل إلى مدخل آخر. تُنقل النصوص في هذا الاتصال دون تشفير عبر الشبكة المنزلية.",
  "Sorun mu yaşıyorsun? TV modelini, sorunun kısa açıklamasını ve ekran görüntüsünü bize gönder; birlikte çözelim.":
      "هل تواجه مشكلة؟ أرسل إلينا طراز التلفزيون ووصفًا مختصرًا للمشكلة ولقطة شاشة لنساعدك في حلها.",
  "TV’de örnek yazıyı gördüm": "ظهر النص التجريبي على التلفزيون",
  "Bağlantıyı kullan": "استخدام الاتصال",
  "LG bağlantısı kurulamadı. IP adresini, TV iznini ve bağlantı türünü kontrol et.":
      "تعذّر الاتصال بتلفزيون LG. تحقّق من عنوان IP وإذن التلفزيون ونوع الاتصال.",
  "Geçerli bir yerel IP adresi gir (ör. 192.168.1.20). TV’de Ayarlar > Ağ bölümünde görünür.":
      "أدخل عنوان IP محليًا صالحًا (مثل 192.168.1.20). ستجده على التلفزيون ضمن الإعدادات > الشبكة.",
  "LG bildirimi gösterilemedi. TV bağlantısını yeniden test et.":
      "تعذّر عرض إشعار LG. اختبر اتصال التلفزيون مجددًا.",
  "TV bağlantı isteğini reddetti. Testi yeniden çalıştır ve TV’de izin ver.":
      "رفض التلفزيون طلب الاتصال. أعد الاختبار وامنح الإذن على التلفزيون.",
  "TV’deki izin isteği zamanında onaylanmadı. Testi yeniden çalıştır ve kumandayla izin ver.":
      "لم تتم الموافقة على طلب الإذن على التلفزيون في الوقت المحدّد. أعد الاختبار ووافق باستخدام الريموت.",
  "TV eşleştirme isteğini kabul etmedi. TV ayarlarında mobil cihaz bağlantısı (LG Connect Apps / Mobile TV On) iznini açıp TV’yi yeniden başlat.":
      "لم يقبل التلفزيون طلب الاقتران. فعّل إذن اتصال الأجهزة المحمولة (LG Connect Apps / Mobile TV On) في إعدادات التلفزيون ثم أعد تشغيله.",
  "TV şifreli bağlantıya yanıt vermiyor. “Şifreli bağlantı” seçeneğini kapatıp yeniden dene.":
      "لا يستجيب التلفزيون للاتصال المشفّر. عطّل خيار «اتصال مشفّر» وحاول مجددًا.",
  "TV şifresiz bağlantıya yanıt vermiyor. “Şifreli bağlantı” seçeneğini açıp yeniden dene.":
      "لا يستجيب التلفزيون للاتصال غير المشفّر. فعّل خيار «اتصال مشفّر» وحاول مجددًا.",
  "TV bu IP adresinde bulunamadı. TV’nin açık olduğunu, IP adresini ve telefonla aynı Wi-Fi ağında olduğunu kontrol et.":
      "لم يُعثر على تلفزيون بهذا العنوان. تحقّق من تشغيل التلفزيون وصحة عنوان IP واتصاله بشبكة Wi-Fi نفسها التي يتصل بها الهاتف.",
  "TV ile şifreli bağlantı kurulamadı. “Şifreli bağlantı” seçeneğini kapatıp yeniden dene.":
      "تعذّر إنشاء اتصال مشفّر بالتلفزيون. عطّل خيار «اتصال مشفّر» وحاول مجددًا.",
  "TV’nin güvenlik sertifikası değişmiş. TV bağlantısını kaldırıp yeniden eşleştir.":
      "تغيّرت شهادة أمان التلفزيون. احذف اتصال التلفزيون وأعد الاقتران.",
  "TV bağlantıyı kabul etmedi. TV’yi yeniden başlatıp diğer bağlantı türünü dene.":
      "لم يقبل التلفزيون الاتصال. أعد تشغيله وجرّب نوع الاتصال الآخر.",
  "Yerel TV oturumu açılamadı. Telefonun Wi-Fi bağlantısını kontrol et.":
      "تعذّر بدء جلسة التلفزيون المحلية. تحقّق من اتصال الهاتف بشبكة Wi-Fi.",
  "TV bağlantısı doğrulanamadı. Testi yeniden çalıştır.":
      "تعذّر التحقّق من اتصال التلفزيون. أعد الاختبار.",
  "LG webOS veya Samsung Tizen TV kullanabilir miyim?":
      "هل يمكنني استخدام تلفزيون LG webOS أو Samsung Tizen؟",
  "TV eşleştirme ekranında LG webOS veya Samsung Tizen seç. LG, IP adresi ve TV’de izin onayıyla bildirim modunu kullanır; konum ve yazı biçimini TV belirler. Samsung, bilgisayardan kurulan ayrı Tizen alıcısını ve HDMI + örnek altyazı testini gerektirir. Sorun yaşarsan TV modelini ve ekran görüntüsünü destek ekibimize gönder. Philips ve Sony Android TV / Google TV cihazlarında mevcut Android TV seçeneğini kullan.":
      "اختر LG webOS أو Samsung Tizen في شاشة اقتران التلفزيون. يستخدم LG وضع الإشعارات بعد الاقتران عبر عنوان IP والموافقة على الإذن على التلفزيون؛ ويحدّد التلفزيون الموضع وتنسيق النص. يتطلب Samsung تطبيق استقبال Tizen منفصلًا يُثبَّت من الكمبيوتر، واختبار HDMI مع ترجمة تجريبية. إذا واجهت مشكلة، فأرسل طراز التلفزيون ولقطة شاشة إلى فريق الدعم. استخدم خيار Android TV الحالي لأجهزة Philips وSony التي تعمل بنظام Android TV / Google TV.",
  "Bu rehberdeki TV adımları Android TV içindir. LG webOS ve Samsung Tizen için TV eşleştirme ekranındaki ayrı seçeneği kullan ve kendi TV testini tamamla.":
      "خطوات التلفزيون في هذا الدليل تخص Android TV. بالنسبة إلى LG webOS وSamsung Tizen، استخدم الخيار المخصّص في شاشة الاقتران وأكمل اختبار التلفزيون.",
  "Her altyazı alanının konumunu ve görünümünü ayrı düzenleyebilirsin. Yeni alanlar varsayılan ayarlarla eklenir.":
      "يمكنك تعديل موضع كل منطقة ترجمة ومظهرها بشكل مستقل. تُضاف المناطق الجديدة بالإعدادات الافتراضية.",
  "Her OCR alanının konumunu ve tarama ayarlarını ayrı düzenleyebilirsin. Yeni alanlar varsayılan ayarlarla eklenir.":
      "يمكنك تعديل موضع كل منطقة OCR وإعدادات مسحها بشكل مستقل. تُضاف المناطق الجديدة بالإعدادات الافتراضية.",
  "OCR {0} tarama sıklığı: {1}": "وتيرة مسح OCR ‏{0}: ‏{1}",
  "Yazı tipi": "الخط",
  "Oyun fontu": "خط اللعبة",
  "Sistem fontu": "خط النظام",
  "Oyun fontu yoksa sistem fontu kullanılır. Diğer görünüm ve konum ayarların korunur.":
      "يُستخدم خط النظام إذا لم يتوفر خط للعبة. تُحفظ إعدادات المظهر والموضع الأخرى.",
  "İndirilen çevirileri sil?": "هل تريد حذف الترجمات المنزّلة؟",
  "{0} oyununun telefondaki çevirileri silinir. Seçiliyse seçim kaldırılır. Oyunu tekrar seçerek çevirileri yeniden indirebilirsin.":
      "ستُحذف ترجمات لعبة {0} المحفوظة على الهاتف. وسيُلغى تحديدها إن كانت محدّدة. يمكنك تنزيل الترجمات مجددًا باختيار اللعبة مرة أخرى.",
  "Sil": "حذف",
  "İndirilen çeviriler silindi.": "تم حذف الترجمات المنزّلة.",
  "İndirildi": "تم التنزيل",
  "Çeviriler silinemedi. Tekrar dene.": "تعذّر حذف الترجمات. حاول مجددًا.",
  "En avantajlı": "أفضل قيمة",
  "Uzun vadeli kullanım için tek ödeme.": "دفعة واحدة للاستخدام طويل الأمد.",
  "Haftalık plana göre %{0} tasarruf": "وفّر {0}% مقارنة بالباقة الأسبوعية",
  "12 aylık ödemeye göre %{0} tasarruf":
      "وفّر {0}% مقارنة بالدفع الشهري لمدة 12 شهرًا",
  "Çeviri dosyası indiriliyor…": "جارٍ تنزيل ملف الترجمة…",
  "Çeviri belleğe yükleniyor…": "جارٍ تحميل الترجمة في الذاكرة…",
  "Oyun listesini yenile": "تحديث قائمة الألعاب",
  "Henüz oyun eklenmedi.": "لم تُضف أي ألعاب بعد.",
  "Oyun adıyla ara": "البحث باسم اللعبة",
  "Aramayı temizle": "مسح البحث",
  "Aramana uygun oyun bulunamadı.": "لم يُعثر على ألعاب تطابق بحثك.",
  "Oyun seçilmedi": "لم تُحدَّد لعبة",
  "Daha hızlı ve doğru çeviri için oyun kütüphanesinde oyunun varsa seç. Listede yoksa oyun seçmeden devam edebilirsin.":
      "للحصول على ترجمة أسرع وأدق، اختر لعبتك إن كانت في مكتبة الألعاب. يمكنك المتابعة دون تحديد لعبة إذا لم تجدها في القائمة.",
  "Seçmeden devam et": "المتابعة دون اختيار",
  "Oyun kütüphanesini aç": "فتح مكتبة الألعاب",
  "Oyun çevirileri hazırlanıyor…": "جارٍ تجهيز ترجمات اللعبة…",
  "Oyun çevirileri yüklenemedi": "تعذّر تحميل ترجمات اللعبة",
  "Oyun listesi yenilenemedi. Kayıtlı oyunlarını kullanabilirsin.":
      "تعذّر تحديث قائمة الألعاب. يمكنك استخدام ألعابك المحفوظة.",
  "Oyun erişimi doğrulanamadı.": "تعذّر التحقّق من صلاحية الوصول إلى اللعبة.",
  "Oyun çeviri dosyası doğrulanamadı.": "تعذّر التحقّق من ملف ترجمة اللعبة.",
  "Oyun dosyası indirilemedi.": "تعذّر تنزيل ملف اللعبة.",
  "Oyun dosyası çok büyük.": "ملف اللعبة كبير جدًا.",
  "Konsol: {0}\n": "جهاز الألعاب: {0}\n",
  "Çevrildi · {0} Yerel": "تمت الترجمة · {0} محلي",
  "Console Game Translator": "Console Game Translator",
  "Oyun Çevirmeni": "Console Game Translator",
  "Oyununu kendi dilinde yaşa": "عش تجربة لعبتك بلغتك",
  "Ayar kaydedilemedi": "تعذّر حفظ الإعداد",
  "Uygulama dili": "لغة التطبيق",
  "Uygulamanın arayüzü şu anda Türkçe. Çeviri kaynak ve hedef dilleri ana ekrandaki dil bölümünden seçebilirsin.":
      "واجهة التطبيق باللغة العربية حاليًا. يمكنك اختيار لغتَي المصدر والهدف للترجمة من قسم اللغات في الشاشة الرئيسية.",
  "Model C hazır": "Model C جاهز",
  "HPLT İngilizce → Türkçe paketi çevrimdışı kullanıma hazır.":
      "حزمة HPLT من الإنجليزية إلى التركية جاهزة للاستخدام دون إنترنت.",
  "Model C indirilemedi": "تعذّر تنزيل Model C",
  "İnternet bağlantını kontrol edip tekrar dene.":
      "تحقّق من اتصالك بالإنترنت وحاول مجددًا.",
  "Dil paketi hazır": "حزمة اللغة جاهزة",
  "Seçilen hedef dil çevrimdışı kullanıma hazır.":
      "اللغة المستهدفة المحدّدة جاهزة للاستخدام دون إنترنت.",
  "Model indirilemedi": "تعذّر تنزيل النموذج",
  "İnternet bağlantını kontrol et.": "تحقّق من اتصالك بالإنترنت.",
  "Dil seçilemedi": "تعذّر اختيار اللغة",
  "Tekrar dene.": "حاول مجددًا.",
  "Model değiştirilemez": "تعذّر تغيير النموذج",
  "Çeviri devam ederken model değiştirilemez. Önce çeviriyi durdurup tekrar dene.":
      "لا يمكن تغيير النموذج أثناء الترجمة. أوقف الترجمة أولًا وحاول مجددًا.",
  "Motor seçilemedi": "تعذّر اختيار محرّك الترجمة",
  "Dil çiftine uygun paketi seçip indir.":
      "اختر الحزمة المناسبة لزوج اللغات ونزّلها.",
  "Kurulum henüz tamamlanmadı": "لم يكتمل الإعداد بعد",
  "{0} / {1} adım tamamlandı": "اكتملت {0} من {1} خطوة",
  "PS5 ve TV bağlantıların hazır. En iyi deneyim için kurulum rehberindeki eksik adımları tamamlamanı öneririz. İstersen çeviriyi şimdi de başlatabilirsin.":
      "اتصالات PS5 والتلفزيون جاهزة. ننصحك بإكمال الخطوات المتبقية في دليل الإعداد للحصول على أفضل تجربة. يمكنك أيضًا بدء الترجمة الآن إن رغبت.",
  "Bir daha gösterme": "عدم الإظهار مجددًا",
  "Yine de başlat": "البدء على أي حال",
  "Kurulumu tamamla": "إكمال الإعداد",
  "Tercih kaydedilemedi. Kurulum uyarısı tekrar görünebilir.":
      "تعذّر حفظ التفضيل. قد يظهر تنبيه الإعداد مجددًا.",
  "Android TV’yi eşleştir": "إقران Android TV",
  "TV açık ve telefonla aynı Wi-Fi ağına bağlı olsun. İlk eşleştirme için TV uygulamasını açıp ekrandaki 6 haneli kodu gir. Eşleştirmeden sonra TV uygulamasını açmadan bağlanabilirsin.":
      "تأكّد من تشغيل التلفزيون واتصاله بشبكة Wi-Fi نفسها التي يتصل بها الهاتف. للاقتران الأول، افتح تطبيق التلفزيون وأدخل الرمز المكوّن من 6 أرقام الظاهر على الشاشة. بعد الاقتران، يمكنك الاتصال دون فتح تطبيق التلفزيون.",
  "TV bulunamadı. TV’nin açık ve iki cihazın aynı Wi-Fi ağında olduğundan emin ol.":
      "لم يُعثر على التلفزيون. تأكّد من تشغيله واتصال الجهازين بشبكة Wi-Fi نفسها.",
  "Bir TV bulundu.": "تم العثور على تلفزيون واحد.",
  "{0} TV bulundu. Kendi TV ekranındaki adresle eşleşeni seç.":
      "تم العثور على {0} تلفزيون. اختر ما يطابق العنوان الظاهر على شاشة تلفزيونك.",
  "Ağ taraması yapılamadı. Aynı Wi-Fi ağını kontrol et.":
      "تعذّر فحص الشبكة. تحقّق من اتصال الجهازين بشبكة Wi-Fi نفسها.",
  "TV aranıyor…": "جارٍ البحث عن التلفزيون…",
  "TV’yi ağda bul": "البحث عن التلفزيون على الشبكة",
  "TV ekranındaki adresle eşleşeni seç":
      "اختر ما يطابق العنوان الظاهر على شاشة التلفزيون",
  "TV ekranındaki adres": "العنوان الظاهر على شاشة التلفزيون",
  "TV ekranındaki 6 haneli kod": "الرمز المكوّن من 6 أرقام على شاشة التلفزيون",
  "Bağlantıyı iptal et": "إلغاء الاتصال",
  "İptal": "إلغاء",
  "TV kimliğini doğrula": "التحقّق من هوية التلفزيون",
  "Bu değer TV ekranındaki “Güvenli bağlantı kimliği” ile aynı mı? Yalnızca tamamı eşleşiyorsa onayla.":
      "هل تطابق هذه القيمة «هوية الاتصال الآمن» على شاشة التلفزيون؟ أكّد فقط إذا تطابقت القيمة بالكامل.",
  "Eşleşmiyor / İptal": "غير متطابقة / إلغاء",
  "Tamamı eşleşiyor": "متطابقة بالكامل",
  "Android TV eşleştirildi. Altyazılar bağlantı açılınca TV’ye gönderilir.":
      "تم إقران Android TV. ستُرسل الترجمة إلى التلفزيون عند الاتصال.",
  "TV’ye bağlanılamadı. Adres, kod ve aynı Wi-Fi ağını kontrol et.":
      "تعذّر الاتصال بالتلفزيون. تحقّق من العنوان والرمز واتصال الجهازين بشبكة Wi-Fi نفسها.",
  "Bağlanıyor…": "جارٍ الاتصال…",
  "Eşleştir ve bağlan": "اقتران واتصال",
  "Türkçe": "التركية",
  "Oyun seçilmedi · canlı çeviri kullanılıyor":
      "لم تُحدَّد لعبة · تُستخدم الترجمة المباشرة",
  "Oyun çeviri dosyası yükleniyor…": "جارٍ تحميل ملف ترجمة اللعبة…",
  "Seçili oyun katalogda bulunamadı.":
      "لم يُعثر على اللعبة المحدّدة في الكتالوج.",
  "Oyun kataloğu okunamadı.": "تعذّرت قراءة كتالوج الألعاب.",
  "Oyun çeviri verisi belleğe alınamadı.":
      "تعذّر تحميل بيانات ترجمة اللعبة في الذاكرة.",
  "{0} seçili": "تم تحديد {0}",
  "Unable to load asset": "تعذّر تحميل المورد",
  "Oyun çeviri dosyası bulunamadı.": "لم يُعثر على ملف ترجمة اللعبة.",
  "Oyun çeviri verisi okunamadı.": "تعذّرت قراءة بيانات ترجمة اللعبة.",
  "Seçili modelin dil paketleri okunamadı.":
      "تعذّرت قراءة حزم اللغات للنموذج المحدّد.",
  "Dil paketi indirilemedi.": "تعذّر تنزيل حزمة اللغة.",
  "Dil paketi indirilemedi": "تعذّر تنزيل حزمة اللغة",
  "Bağlantını kontrol edip tekrar dene.": "تحقّق من اتصالك وحاول مجددًا.",
  "Model C • HPLT v2.0": "Model C • HPLT v2.0",
  "İngilizce → Türkçe • çevrimdışı • yaklaşık 80 MB • 64-bit ARM Android. HPLT v2.0 tabanlı INT8 CTranslate2 paketi.":
      "من الإنجليزية إلى التركية • دون إنترنت • نحو 80 MB • Android بمعمارية ARM ‏64 بت. حزمة CTranslate2 بدقة INT8 مبنية على HPLT v2.0.",
  "HPLT İngilizce → Türkçe": "HPLT من الإنجليزية إلى التركية",
  "İndirildi • cihazda hazır": "تم التنزيل • جاهز على الجهاز",
  "İndirilmedi": "لم يُنزَّل",
  "Hazır": "جاهز",
  "İndir": "تنزيل",
  "Atıf: HPLT, translate-en-tr-v2.0-hplt_opus; WindyTranslate INT8 dönüşümü. CC BY 4.0.":
      "الإسناد: HPLT، ‏translate-en-tr-v2.0-hplt_opus؛ تحويل INT8 بواسطة WindyTranslate. الترخيص CC BY 4.0.",
  "Model A hedef dilleri": "اللغات المستهدفة في Model A",
  "Model B dilleri": "لغات Model B",
  "İngilizceden seçtiğin dile çevrimdışı paket indir.":
      "نزّل حزمة للترجمة من الإنجليزية إلى اللغة التي تختارها دون إنترنت.",
  "İndirilen diller seçili çeviri motorunda kullanılabilir.":
      "يمكن استخدام اللغات المنزّلة في محرّك الترجمة المحدّد.",
  "Durumu yenile": "تحديث الحالة",
  "Dil seçenekleri yüklenemedi.": "تعذّر تحميل خيارات اللغة.",
  "Yeniden dene": "إعادة المحاولة",
  "İndirildi • İngilizceden kullanılabilir":
      "تم التنزيل • متاح للترجمة من الإنجليزية",
  "İndirilmedi • yaklaşık 20 MB": "لم يُنزَّل • نحو 20 MB",
  "Seçili": "محدّد",
  "Seç": "اختيار",
  "İndirildi • çeviri seçiminde kullanılabilir":
      "تم التنزيل • متاح ضمن خيارات الترجمة",
  "Android TV’ye bağlanılıyor": "جارٍ الاتصال بـAndroid TV",
  "Bağlantı tamamlanınca çeviriyi başlatabilirsin.":
      "يمكنك بدء الترجمة عند اكتمال الاتصال.",
  "Hedef dil paketi gerekli": "يلزم تنزيل حزمة اللغة المستهدفة",
  "Model A için seçili hedef dil paketini önce indir.":
      "نزّل حزمة اللغة المستهدفة المحدّدة لـModel A أولًا.",
  "Model C paketi gerekli": "تلزم حزمة Model C",
  "HPLT İngilizce → Türkçe paketini önce indir.":
      "نزّل حزمة HPLT من الإنجليزية إلى التركية أولًا.",
  "Çeviri durdu": "توقفت الترجمة",
  "Remote Play oturumu artık etkin değil.": "جلسة Remote Play لم تعد نشطة.",
  "Çeviri durdurulamadı": "تعذّر إيقاف الترجمة",
  "Önce PlayStation 5’i kurup kaydet.": "أعدّ جهاز PlayStation 5 وسجّله أولًا.",
  "Android TV gerekli": "يلزم Android TV",
  "Önce Android TV’yi eşleştirip bağla.": "أقرن Android TV واتصل به أولًا.",
  "Dil paketleri hazırlanamadı": "تعذّر تجهيز حزم اللغات",
  "Çeviri başlatılamadı": "تعذّر بدء الترجمة",
  "PS5 durumu okunamadı": "تعذّرت قراءة حالة PS5",
  "Lütfen birkaç saniye sonra tekrar dene.": "حاول مجددًا بعد بضع ثوانٍ.",
  "PS5’e bağlanılıyor": "جارٍ الاتصال بـPS5",
  "Bağlantı tamamlanana kadar PS5 kaydını kaldıramazsın. Biraz bekleyip tekrar dene.":
      "لا يمكنك إلغاء تسجيل PS5 حتى يكتمل الاتصال. انتظر قليلًا وحاول مجددًا.",
  "PS5 görüntüsü yenileniyor": "جارٍ تحديث صورة PS5",
  "Remote Play bağlantısı açık. Görüntü yüzeyi hazırlanıyor.":
      "اتصال Remote Play نشط. جارٍ تجهيز مساحة عرض الصورة.",
  "Remote Play bağlantısı kesilsin mi?": "هل تريد قطع اتصال Remote Play؟",
  "PS5’teki Remote Play oturumu ve devam eden çeviri durur. PS5 kaydın korunur; daha sonra yeniden bağlanabilirsin.":
      "ستتوقف جلسة Remote Play على PS5 والترجمة الجارية. سيُحفظ تسجيل PS5 ويمكنك الاتصال مجددًا لاحقًا.",
  "Bağlantıyı kes": "قطع الاتصال",
  "Remote Play kesildi. PS5 kaydı korundu.":
      "تم قطع اتصال Remote Play. حُفظ تسجيل PS5.",
  "Bağlantı kesilemedi": "تعذّر قطع الاتصال",
  "Kayıtlı PS5 kaldırılsın mı?": "هل تريد إزالة جهاز PS5 المحفوظ؟",
  "Bu işlem telefondaki kayıtlı PS5 ve PSN eşleştirme bilgilerini siler. Tekrar eklemek için Sony hesabını doğrulayıp PS5’i yeniden kaydetmen gerekir. Kurulum genellikle yaklaşık 2–5 dakika sürer; Sony hesabı doğrulaması veya ağ bağlantısı yavaşsa daha uzun sürebilir.\n\nDevam etmek istiyor musun?":
      "سيحذف هذا الإجراء بيانات PS5 المحفوظة وبيانات اقتران PSN من الهاتف. لإضافته مجددًا، ستحتاج إلى التحقّق من حسابك في Sony وإعادة تسجيل PS5. يستغرق الإعداد عادة نحو 2–5 دقائق، وقد يطول إذا كان التحقّق من حساب Sony أو الاتصال بالشبكة بطيئًا.\n\nهل تريد المتابعة؟",
  "PS5’i kaldır": "إزالة PS5",
  "Remote Play açık": "Remote Play نشط",
  "Önce Remote Play bağlantısını kes. PS5 kaydı bağlantı kapandıktan sonra kaldırılabilir.":
      "اقطع اتصال Remote Play أولًا. يمكن إزالة تسجيل PS5 بعد إغلاق الاتصال.",
  "PS5 kayıtlı cihazlardan kaldırıldı.": "تمت إزالة PS5 من الأجهزة المحفوظة.",
  "PS5 kaldırılamadı": "تعذّرت إزالة PS5",
  "Çeviri başladı": "بدأت الترجمة",
  "Daha doğru sonuç için oyundaki yazıların bulunduğu OCR alanlarını ve çevrilen altyazının ekranda gösterileceği alanı ayarla. Bu ayarlar her oyun görüntüsüne göre değişebilir.":
      "للحصول على نتائج أدق، اضبط مناطق OCR التي تحتوي على نصوص اللعبة والمنطقة التي ستظهر فيها الترجمة على الشاشة. قد تختلف هذه الإعدادات بحسب صورة كل لعبة.",
  "Daha sonra": "لاحقًا",
  "Alanları ayarla": "ضبط المناطق",
  "Altyazı": "الترجمة",
  "Ana sayfa": "الرئيسية",
  "Profil": "الملف الشخصي",
  "Ayarlar": "الإعدادات",
  "Oyununu seç, altyazı görünümünü düzenle.": "اختر لعبتك واضبط مظهر الترجمة.",
  "Görünüm ve alanlar": "المظهر والمناطق",
  "Altyazı görünümü": "مظهر الترجمة",
  "Ekran önizlemesi, OCR alanları ve altyazı ayarları":
      "معاينة الشاشة ومناطق OCR وإعدادات الترجمة",
  "Yeni veya kullanılmamış PSN hesabı gerekli":
      "يلزم حساب PSN جديد أو غير مستخدم",
  "Remote Play bağlı": "Remote Play متصل",
  "Çeviri açık • görüntü yenileniyor": "الترجمة نشطة • جارٍ تحديث الصورة",
  "Çeviri açık • PS5 yeniden bağlanıyor, lütfen bekleyin":
      "الترجمة نشطة • جارٍ إعادة الاتصال بـPS5، يُرجى الانتظار",
  "PS5 kaydı hazır": "تسجيل PS5 جاهز",
  "Kurulu değil": "لم يُعَدّ بعد",
  "Bağlı": "متصل",
  "Yeniden bağlanıyor": "جارٍ إعادة الاتصال",
  "Bağlanıyor": "جارٍ الاتصال",
  "Görüntü yenileniyor": "جارٍ تحديث الصورة",
  "Lütfen bekleyin": "يُرجى الانتظار",
  "PS5 kaydı kontrol ediliyor…": "جارٍ التحقّق من تسجيل PS5…",
  "PS5 açılıyor…": "جارٍ تشغيل PS5…",
  "Görüntü yenileniyor…": "جارٍ تحديث الصورة…",
  "PS5 yeniden bağlanıyor…": "جارٍ إعادة الاتصال بـPS5…",
  "PS5’e bağlanıyor…": "جارٍ الاتصال بـPS5…",
  "Remote Play’e dön": "العودة إلى Remote Play",
  "Remote Play’i aç": "فتح Remote Play",
  "PS5’i listeden kaldır": "إزالة PS5 من القائمة",
  "Android TV": "Android TV",
  "TV’ye bağlantı kuruluyor": "جارٍ إنشاء اتصال بالتلفزيون",
  "Bağlı • {0}": "متصل • {0}",
  "Şifreli": "مشفّر",
  "Şifresiz": "غير مشفّر",
  "Altyazıları TV ekranında göster": "عرض الترجمة على شاشة التلفزيون",
  "Eşleştirme kayıtlı • TV bağlı değil": "الاقتران محفوظ • التلفزيون غير متصل",
  "Bağlı değil": "غير متصل",
  "Kontrol ediliyor": "جارٍ التحقّق",
  "TV’ye bağlanıyor…": "جارٍ الاتصال بالتلفزيون…",
  "TV durumu kontrol ediliyor…": "جارٍ التحقّق من حالة التلفزيون…",
  "TV’yi yeniden eşleştir": "إعادة إقران التلفزيون",
  "TV’yi eşleştir": "إقران التلفزيون",
  "Tekrar dene": "حاول مجددًا",
  "{0}  •  OYUNUNA KENDİ DİLİNDE DEVAM ET": "{0}  •  واصل لعبتك بلغتك",
  "Kayıtlı": "محفوظ",
  "ÇEVİRİ DİLLERİ": "لغات الترجمة",
  "Oyun Kütüphanesi": "مكتبة الألعاب",
  "Daha hızlı ve kaliteli bir çeviri deneyimi için oynadığın oyun listede varsa seç.":
      "للحصول على ترجمة أسرع وأفضل، اختر اللعبة التي تلعبها إن كانت في القائمة.",
  "Oyun listesi yükleniyor…": "جارٍ تحميل قائمة الألعاب…",
  "Güncel oyun listesi alınamadı. İnternet bağlantını kontrol edip tekrar dene.":
      "تعذّر جلب قائمة الألعاب المحدّثة. تحقّق من اتصالك بالإنترنت وحاول مجددًا.",
  "seçili": "محدّد",
  "Oyun seçimini kaldır": "إلغاء تحديد اللعبة",
  "ÇEVİRİ MODELİ": "نموذج الترجمة",
  "En iyi çeviri için Oyun Kütüphanesi’ni öneriyoruz. Oyunun listede yoksa DeepL veya Gemini’yi, bunlara erişimin yoksa yerel modelleri kullanabilirsin.":
      "ننصح بمكتبة الألعاب للحصول على أفضل ترجمة. إذا لم تكن لعبتك في القائمة، يمكنك استخدام DeepL أو Gemini، أو النماذج المحلية إذا لم يتوفر لك الوصول إليهما.",
  "Model A - Yerel Kaliteli": "Model A - محلي عالي الجودة",
  "Model B - Yerel Hızlı": "Model B - محلي سريع",
  "Önce yaklaşık 80 MB HPLT model paketini indir.":
      "نزّل حزمة نموذج HPLT بحجم نحو 80 MB أولًا.",
  "İngilizceden seçtiğin hedef dile ait paketi indir.":
      "نزّل حزمة الترجمة من الإنجليزية إلى اللغة المستهدفة التي اخترتها.",
  "Seçtiğin kaynak ve hedef dillerin paketlerini indir.":
      "نزّل حزم لغتَي المصدر والهدف اللتين اخترتهما.",
  "Dilleri görüntüle ve indir": "عرض اللغات وتنزيلها",
  "Bu motor için kaynak dili İngilizce, hedef dili yukarıdaki seçim olmalı.":
      "يتطلب هذا المحرّك أن تكون لغة المصدر هي الإنجليزية، واللغة المستهدفة هي المحدّدة أعلاه.",
  "Model C yalnızca İngilizce → Türkçe dil çiftiyle çalışır.":
      "يعمل Model C مع زوج اللغات من الإنجليزية إلى التركية فقط.",
  "Diller yükleniyor…": "جارٍ تحميل اللغات…",
  "durum kontrol ediliyor": "جارٍ التحقّق من الحالة",
  "ÇEVİRİYİ DURDUR": "إيقاف الترجمة",
  "ÇEVİRİYİ BAŞLAT": "بدء الترجمة",
  "Bağlantı hazırlanıyor…": "جارٍ تجهيز الاتصال…",
  "Android TV’ye bağlanılıyor…": "جارٍ الاتصال بـAndroid TV…",
  "Remote Play ve altyazı akışı durdurulur":
      "سيتم إيقاف Remote Play وتدفّق الترجمة",
  "Önce PS5 kurulumunu tamamla": "أكمل إعداد PS5 أولًا",
  "Başlamak için Android TV’yi eşleştir": "أقرن Android TV للبدء",
  "PS5’e bağlanır ve altyazılar TV’de başlar":
      "يتصل بـPS5 وتبدأ الترجمة على التلفزيون",
  "Kurulum rehberi": "دليل الإعداد",
  "Oyun kataloğunda \"{0}\" alanı eksik.":
      "الحقل «{0}» مفقود من كتالوج الألعاب.",
  "Hesabını sil": "حذف حسابك",
  "Uygulamadaki hesabın kalıcı olarak silinir ve oturumun kapatılır. Tekrarlanan denemeleri önleyen bitiş kaydı saklanır. Bu işlem Google Play aboneliğini iptal etmez; aboneliğini Google Play’den yönetebilirsin.":
      "سيُحذف حسابك في التطبيق نهائيًا وسيتم تسجيل خروجك. يُحتفَظ بسجل انتهاء التجربة لمنع تكرارها. لا يلغي هذا الإجراء اشتراكك في Google Play؛ يمكنك إدارته من Google Play.",
  "Vazgeç": "تراجع",
  "Hesabımı sil": "حذف حسابي",
  "Hesabın silindi ve oturumun kapatıldı.": "تم حذف حسابك وتسجيل خروجك.",
  "Sayfa açılamadı. Biraz sonra tekrar dene.":
      "تعذّر فتح الصفحة. حاول مجددًا بعد قليل.",
  "Haftalık": "أسبوعي",
  "Aylık": "شهري",
  "Yıllık": "سنوي",
  "Süresiz": "مدى الحياة",
  "Premium": "Premium",
  "yıl": "سنة",
  "dönem": "فترة",
  "Kalan deneme: {0}. Süre Remote Play bağlantısı başladığında kesintisiz işler. Uygulamayı kapatsan da süre devam eder. Otomatik ücret alınmaz.":
      "الوقت المتبقي للتجربة: {0}. يُحتسب الوقت بشكل متواصل منذ بدء اتصال Remote Play، حتى عند إغلاق التطبيق. لن تُفرض رسوم تلقائية.",
  "Google girişin tamamlandı. Ücretsiz denemen, Çeviriyi başlat düğmesine basıp Remote Play bağlantısı kurulduğunda başlayacak.":
      "تم تسجيل دخولك باستخدام Google. ستبدأ تجربتك المجانية عند الضغط على «بدء الترجمة» وإنشاء اتصال Remote Play.",
  "Deneme henüz hazır değil. İnternet bağlantını kontrol edip tekrar dene.":
      "التجربة غير جاهزة بعد. تحقّق من اتصالك بالإنترنت وحاول مجددًا.",
  "Ücretsiz denemen sona erdi. Çeviriye devam etmek için bir paket seçebilirsin.":
      "انتهت تجربتك المجانية. يمكنك اختيار باقة لمتابعة الترجمة.",
  "Ücretsiz çeviriyi dene": "جرّب الترجمة مجانًا",
  "Google ile ücretsiz dene": "جرّب مجانًا باستخدام Google",
  "Deneme süresi alınamadı. İnternet bağlantını kontrol edip aşağı çekerek yenile.":
      "تعذّر تحميل مدة التجربة. تحقّق من اتصالك بالإنترنت واسحب للأسفل للتحديث.",
  "Google Play denemen {0} tarihine kadar aktif. Ücret alınmasını istemiyorsan deneme bitmeden Google Play’den iptal et.":
      "تجربتك عبر Google Play فعّالة حتى {0}. إذا كنت لا ترغب في دفع رسوم، فألغِها من Google Play قبل انتهائها.",
  "Deneme aboneliğinin yenilenmesi iptal edildi. {0} tarihine kadar çeviriyi kullanabilirsin.":
      "تم إلغاء تجديد الاشتراك التجريبي. يمكنك استخدام الترجمة حتى {0}.",
  "Premium aktif. Aboneliğini Google Play’den yönetebilirsin.":
      "Premium فعّال. يمكنك إدارة اشتراكك من Google Play.",
  "Yenileme iptal edildi. {0} tarihine kadar Premium erişimin sürer.":
      "تم إلغاء التجديد. يستمر وصولك إلى Premium حتى {0}.",
  "Süresiz Premium erişimin aktif.": "وصولك إلى Premium مدى الحياة فعّال.",
  "Satın alma durumu doğrulanamadı. İnternete bağlanıp durumu yenile.":
      "تعذّر التحقّق من حالة الشراء. اتصل بالإنترنت وحدّث الحالة.",
  "{0} · tek ödeme, otomatik yenilenmez.":
      "{0} · دفعة واحدة، دون تجديد تلقائي.",
  "{0} / {1}. Aboneliğin otomatik yenilenir; Google Play’den iptal edebilirsin.":
      "{0} / {1}. يتجدّد اشتراكك تلقائيًا؛ ويمكنك إلغاؤه من Google Play.",
  "Süresiz satın al": "شراء وصول مدى الحياة",
  "Abone ol": "اشتراك",
  "Premium aktif": "Premium فعّال",
  "Erişim durumunu yenilemek için aşağı çek.":
      "اسحب للأسفل لتحديث حالة الوصول.",
  "Çeviriye devam et": "متابعة الترجمة",
  "Deneme için Google ile giriş yap": "سجّل الدخول باستخدام Google للتجربة",
  "Satın alınabilir paket bulunamadı. Biraz sonra tekrar dene.":
      "لا توجد باقات متاحة للشراء. حاول مجددًا بعد قليل.",
  "Deneme uygunluğu ve son ödeme koşulları Google Play ekranında gösterilir.":
      "تظهر أهلية التجربة وشروط الدفع النهائية في شاشة Google Play.",
  "Geri yükleme için biraz bekle": "انتظر قليلًا قبل الاستعادة",
  "Satın alımları geri yükle": "استعادة المشتريات",
  "Google hesabı": "حساب Google",
  "Çıkış yap": "تسجيل الخروج",
  "Google Play aboneliğini yönet / iptal et":
      "إدارة اشتراك Google Play أو إلغاؤه",
  "Gizlilik politikası": "سياسة الخصوصية",
  "Kullanım şartları": "شروط الاستخدام",
  "Sık Sorulan Sorular": "الأسئلة الشائعة",
  "Yanıtları görmek için bir soruya dokun.": "اضغط على سؤال لعرض الإجابة.",
  "Süresiz erişim aktif": "الوصول مدى الحياة فعّال",
  "Kalan deneme: {0}": "الوقت المتبقي للتجربة: {0}",
  "Mağaza denemesi aktif": "تجربة المتجر فعّالة",
  "Deneme süresi sona erdi": "انتهت مدة التجربة",
  "Erişim doğrulaması gerekiyor": "يلزم التحقّق من صلاحية الوصول",
  "Paketleri ve erişim durumunu görüntüle": "عرض الباقات وحالة الوصول",
  "Hesabın, Premium erişimin ve uygulama ayarların. Yenilemek için aşağı çek.":
      "حسابك ووصولك إلى Premium وإعدادات التطبيق. اسحب للأسفل للتحديث.",
  "Oyununa kaldığın yerden devam et": "واصل لعبتك من حيث توقفت",
  "Google hesabın": "حسابك في Google",
  "Deneme ve hesap işlemleri için Google hesabınla giriş yap.":
      "سجّل الدخول بحسابك في Google للتجربة وإدارة الحساب.",
  "Google ile giriş yap": "تسجيل الدخول باستخدام Google",
  "Aboneliğim": "اشتراكي",
  "Hediye kodunu kullan": "استخدام رمز هدية",
  "Google Play hediye veya promosyon kodu":
      "رمز هدية أو رمز ترويجي من Google Play",
  "Tekrar denemeden önce kısa bir süre bekle.":
      "انتظر قليلًا قبل المحاولة مجددًا.",
  "Önceki satın alımlarını Google Play’den geri getir.":
      "استعد مشترياتك السابقة من Google Play.",
  "PS5 bulundu. Eşleştirme için 8 haneli konsol PIN’ini gir.":
      "تم العثور على PS5. أدخل رمز PIN للجهاز المكوّن من 8 أرقام للاقتران.",
  "PS5 kayıt işlemi başlatılıyor…": "جارٍ بدء تسجيل PS5…",
  "PS5 kaydı başarılı.\n{0}": "تم تسجيل PS5 بنجاح.\n{0}",
  "Kayıt sonucu alınamadı.": "تعذّر الحصول على نتيجة التسجيل.",
  "{0}\nHata kodu: {1}": "{0}\nرمز الخطأ: {1}",
  "PS5 kaydı başarısız.": "فشل تسجيل PS5.",
  "Beklenmeyen hata: {0}": "خطأ غير متوقع: {0}",
  "PS5 bağlantısı hazır!": "اتصال PS5 جاهز!",
  "{0} başarıyla eşleştirildi.\n\nArtık ana menüden çeviriyi başlatabilirsin.":
      "تم إقران {0} بنجاح.\n\nيمكنك الآن بدء الترجمة من القائمة الرئيسية.",
  "PS5 Bağlantısı": "اتصال PS5",
  "Adım 2/2": "الخطوة 2/2",
  "PS5 konsolunu kaydet": "تسجيل جهاز PS5",
  "Telefon ve PS5 aynı yerel ağda olmalı. PS5 IP adresini konsolun ağ ayarlarında bulabilirsin.":
      "يجب أن يكون الهاتف وPS5 على الشبكة المحلية نفسها. ستجد عنوان IP الخاص بـPS5 في إعدادات الشبكة على الجهاز.",
  "PS5’te bağladığın PSN hesabına geç. Ayarlar → Sistem → Uzaktan Oynatma → Uzaktan Oynatmayı Etkinleştir seçeneğini aç. Ardından Cihazı Eşleştir ile aldığın 8 haneli kodu aşağıya gir.":
      "بدّل إلى حساب PSN الذي ربطته على PS5. افتح الإعدادات ← النظام ← اللعب عن بُعد، وفعّل «تمكين اللعب عن بُعد». ثم اختر «إقران الجهاز» وأدخل أدناه الرمز المكوّن من 8 أرقام.",
  "Kayıtlı PS5: {0}": "جهاز PS5 المحفوظ: {0}",
  "PS5 kayıtlı": "PS5 مسجّل",
  "Remote Play ekranını aç": "فتح شاشة Remote Play",
  "Yerel ağ taranıyor…": "جارٍ فحص الشبكة المحلية…",
  "Ağda PS5 ara": "البحث عن PS5 على الشبكة",
  "PS5 bulunamazsa IP adresini elle yazabilirsin.":
      "يمكنك إدخال عنوان IP يدويًا إذا لم يُعثر على PS5.",
  "PS5 IPv4 adresini gir.": "أدخل عنوان IPv4 الخاص بـPS5.",
  "Geçerli bir IPv4 adresi gir.": "أدخل عنوان IPv4 صالحًا.",
  "Eşleştirmeden önce PSN hesabını doğrula. Account ID uygulamada güvenli olarak alınır.":
      "تحقّق من حساب PSN قبل الاقتران. يحصل التطبيق على معرّف الحساب بأمان.",
  "PSN hesabını doğrula": "التحقّق من حساب PSN",
  "PSN hesabı doğrulandı": "تم التحقّق من حساب PSN",
  "Uzaktan erişim PIN kodu": "رمز PIN للوصول عن بُعد",
  "PIN kodu 8 rakam olmalı.": "يجب أن يتكوّن رمز PIN من 8 أرقام.",
  "PS5 bağlantısını başlat": "بدء اتصال PS5",
  "OCR bekliyor": "OCR قيد الانتظار",
  "Arka plan dönüşü için Remote Play yeniden kuruluyor.":
      "جارٍ إعادة إنشاء اتصال Remote Play بعد العودة من الخلفية.",
  "Bağlandı": "تم الاتصال",
  "PS5 kullanıcı giriş PIN’i gerekiyor": "يلزم رمز PIN لتسجيل دخول مستخدم PS5",
  "Konsol kullanıcı PIN ekranını bekliyor. Bu uygulamada PIN girişi henüz eklenmedi.":
      "ينتظر الجهاز إدخال رمز PIN للمستخدم. إدخال الرمز غير متاح في هذا التطبيق بعد.",
  "Bağlantı kesildi": "تم قطع الاتصال",
  "already in use": "قيد الاستخدام بالفعل",
  "yüzey": "سطح العرض",
  "arka plan": "الخلفية",
  "Bağlantı hatası": "خطأ في الاتصال",
  "kopya {0} ms, kırpma {1} ms, filtre {2} ms, OCR {3} ms (güven {4}) , {5}×{6}":
      "النسخ {0} مللي ثانية، الاقتصاص {1} مللي ثانية، التصفية {2} مللي ثانية، OCR ‏{3} مللي ثانية (الثقة {4})، ‏{5}×{6}",
  "kıyas": "مقارنة",
  "Çeviri erişimi sona erdi veya doğrulanamadı. Premium ekranını kontrol et.":
      "انتهت صلاحية الوصول إلى الترجمة أو تعذّر التحقّق منها. راجع شاشة Premium.",
  "Altyazı ayarları kaydedilemedi: {0}": "تعذّر حفظ إعدادات الترجمة: {0}",
  "Altyazı ayarları kaydedildi.": "تم حفظ إعدادات الترجمة.",
  "Remote Play açık değil": "Remote Play غير نشط",
  "Seçili alan tek karede taranıyor…":
      "جارٍ مسح المنطقة المحدّدة من إطار واحد…",
  "Seçili alan sıfırlandı ve kaydedildi.":
      "تمت إعادة ضبط المنطقة المحدّدة وحفظها.",
  "Tam ortaya hizala · %50": "محاذاة إلى المنتصف تمامًا · 50%",
  "Bu ölçü için konum sabit.": "الموضع ثابت لهذا الحجم.",
  "Arka plan konumu ve boyutu": "موضع الخلفية وحجمها",
  "Konum ve boyut": "الموضع والحجم",
  "Tümünü ortala": "توسيط الكل",
  "Alanı sürükleyebilir veya değerleri hassas biçimde ayarlayabilirsin.":
      "يمكنك سحب المنطقة أو ضبط القيم بدقة.",
  "Yatay merkez": "المركز الأفقي",
  "Dikey merkez": "المركز العمودي",
  "Genişlik": "العرض",
  "Yükseklik": "الارتفاع",
  "Remote Play bağlantısı korunuyor; görüntü yüzeyi yenileniyor.":
      "اتصال Remote Play مستمر؛ جارٍ تحديث مساحة عرض الصورة.",
  "Canlı oyun görüntüsü bağlantı kurulunca görünür.":
      "ستظهر صورة اللعبة المباشرة عند الاتصال.",
  "Altyazı alanı": "منطقة الترجمة",
  "Arka plan alanı": "منطقة الخلفية",
  "OCR alanı": "منطقة OCR",
  "Altyazı önizlemesi": "معاينة الترجمة",
  "Önizleme üzerinde hangi alanı ayarlayacaksın?":
      "أي منطقة تريد ضبطها في المعاينة؟",
  "Altyazı yeri": "موضع الترجمة",
  "Turkuaz çerçeveler çevirinin gösterileceği yerlerdir. Her alanı seçip görüntüde taşıyabilir ve boyutlandırabilirsin.":
      "تحدّد الإطارات الفيروزية مواضع عرض الترجمة. يمكنك اختيار كل منطقة وتحريكها وتغيير حجمها على الصورة.",
  "Sarı çerçeve oyundaki yazının taranacağı OCR alanıdır.":
      "يحدّد الإطار الأصفر منطقة OCR التي ستُمسح فيها نصوص اللعبة.",
  "Altyazı {0}": "الترجمة {0}",
  "Altyazı alanı ekle": "إضافة منطقة ترجمة",
  "Seçili alanı sil": "حذف المنطقة المحدّدة",
  "SARI ALANLAR • OCR NEREDEN OKUSUN?": "المناطق الصفراء • من أين يقرأ OCR؟",
  "Oyun görüntüsünde metnin bulunduğu yeri seç. OCR yalnızca seçtiğin alanları tarar. Her alanı ayrı taşıyıp boyutlandırabilirsin.":
      "حدّد موضع النص في صورة اللعبة. يمسح OCR المناطق التي تختارها فقط. يمكنك تحريك كل منطقة وتغيير حجمها بشكل مستقل.",
  "OCR alanı ekle": "إضافة منطقة OCR",
  "Seçili OCR alanını sil": "حذف منطقة OCR المحدّدة",
  "TURKUAZ KUTULAR • ALTYAZILAR NEREDE GÖRÜNSÜN?":
      "المربعات الفيروزية • أين تظهر الترجمة؟",
  "Her turkuaz alan aynı çevrilmiş altyazıyı seçtiğin konumda gösterir. OCR alanlarından bağımsızdır; birden fazla yere ekleyebilirsin.":
      "تعرض كل منطقة فيروزية النص المترجم نفسه في الموضع الذي تختاره. وهي مستقلة عن مناطق OCR؛ ويمكنك إضافتها في عدة مواضع.",
  "OCR ipucu: Oyun ayarları izin veriyorsa İngilizce altyazının arka planını açıp opaklığını artır. Koyu zemin ve açık renk yazı, metnin daha net okunmasına ve çevirinin iyileşmesine yardımcı olabilir.":
      "نصيحة لـOCR: إذا سمحت إعدادات اللعبة، فعّل خلفية الترجمة الإنجليزية واجعلها أكثر عتامة. قد تساعد الخلفية الداكنة مع النص الفاتح على قراءة أوضح وترجمة أفضل.",
  "Altyazı kutusunu sıfırla": "إعادة ضبط مربع الترجمة",
  "Seçili OCR alanını sıfırla": "إعادة ضبط منطقة OCR المحدّدة",
  "Son OCR: {0}\n{1}": "آخر قراءة OCR: ‏{0}\n{1}",
  "Ham/filtreli OCR kıyasla": "مقارنة OCR للصورة الأصلية والمعالَجة",
  "OCR tarama sıklığı: {0}": "وتيرة مسح OCR: ‏{0}",
  "Düşük değer daha az pil harcar; metni daha geç yakalayabilir.":
      "تستهلك القيمة المنخفضة بطارية أقل، لكنها قد تؤخّر التقاط النص.",
  "OCR {0} diyalog filtresi": "مرشّح الحوار لـOCR ‏{0}",
  "Konuşmacı adı, cümle yapısı ve konuma göre diyalog benzeri satırları seçer.":
      "يختار السطور التي تبدو كحوار استنادًا إلى اسم المتحدث وبنية الجملة والموضع.",
  "Kapalı: seçili OCR alanındaki tüm metinler tanınır.":
      "معطّل: يُتعرَّف على جميع النصوص داخل منطقة OCR المحدّدة.",
  "Çeviriyi İngilizce altyazının üstünde göster":
      "عرض الترجمة فوق النص الإنجليزي",
  "Açık: çeviri, okunan İngilizce metnin tam üstünde çıkar; art arda konuşan kişiler ayrı ayrı, düğme ipuçları (SEÇ, GERİ…) her biri kendi yazısının üstünde gösterilir ve oyundaki düğme simgeleri görünür kalır. Bu alanın sabit altyazı konumu kullanılmaz.":
      "مفعّل: تظهر الترجمة مباشرة فوق النص الإنجليزي المقروء؛ ويظهر كلام المتحدثين المتعاقبين بشكل منفصل، وتظهر تسميات الأزرار (اختيار، رجوع…) فوق نصوصها مع إبقاء رموز الأزرار في اللعبة ظاهرة. لا يُستخدم موضع الترجمة الثابت لهذه المنطقة.",
  "Kapalı: çeviri, Altyazı {0} için seçtiğin sabit yerde gösterilir.":
      "معطّل: تظهر الترجمة في الموضع الثابت الذي اخترته للترجمة {0}.",
  "Altyazı {0} İngilizce metnin üstünde": "الترجمة {0} فوق النص الإنجليزي",
  "Çeviri, OCR {0} alanının okuduğu İngilizce metnin tam üstünde görünür ve onunla birlikte yer değiştirir; art arda konuşan kişiler ayrı kutularda, düğme ipuçları tek tek gösterilir. Bu yüzden sabit konum ayarı kapalı. Yazı boyutu, renk ve arka plan ayarları geçerli.":
      "تظهر الترجمة مباشرة فوق النص الإنجليزي الذي تقرؤه منطقة OCR ‏{0} وتتحرك معه. يظهر كلام المتحدثين المتعاقبين في مربعات منفصلة، وتسميات الأزرار كلٌّ على حدة. لذلك يُعطَّل ضبط الموضع الثابت. تبقى إعدادات حجم الخط واللون والخلفية مطبّقة.",
  "Sabit konuma dön": "العودة إلى موضع ثابت",
  "Altyazı {0}, OCR {1} alanıyla birlikte taşınsın":
      "تحريك الترجمة {0} مع منطقة OCR ‏{1}",
  "Açıkken altyazı OCR alanının tam üstünde durur ve onu taşıdıkça o da taşınır. Altyazı kutusunu elle taşırsan kendi yerinde kalır.":
      "عند التفعيل، تظهر الترجمة فوق منطقة OCR مباشرة وتتحرك معها. إذا حرّكت مربع الترجمة يدويًا، يبقى في موضعه الخاص.",
  "OCR {0} görüntü ön işlemesi": "المعالجة المسبقة لصورة OCR ‏{0}",
  "Ham görüntü": "الصورة الأصلية",
  "Gri tonlama + kontrast": "تدرّج رمادي + تباين",
  "Adaptif eşikleme": "تحويل تكيفي إلى الأبيض والأسود",
  "Kenar keskinleştirme": "زيادة حدة الحواف",
  "Yerel kontrast (ışık/parlama)": "تباين محلي (الإضاءة والوهج)",
  "Hassas eşik · açık yazı": "تحويل دقيق • نص فاتح",
  "Hassas eşik · koyu yazı": "تحويل دقيق • نص داكن",
  "Hassas eşik · otomatik yön": "تحويل دقيق • تحديد تلقائي للنمط",
  "Sarı yazı · mavi/soğuk zemin": "نص أصفر • خلفية زرقاء أو باردة",
  "Otomatik renk kanalı": "قناة ألوان تلقائية",
  "OCR görüntü ön işlemesi": "المعالجة المسبقة لصورة OCR",
  "Yalnızca seçili OCR kırpımına uygulanır. Otomatik renk kanalı her karede kırpımdaki RGB kanallarının kontrastını ölçüp o sahnede en çok ayrım sağlayanı seçer; farklı yazı ve arka plan renklerine uyum sağlamayı dener. Sarı yazı seçeneği yalnızca sarı yazı/mavi-soğuk zemin içindir.":
      "تُطبَّق على الجزء المحدّد لـOCR فقط. يقيس خيار قناة الألوان التلقائية تباين قنوات RGB في كل إطار، ويختار القناة التي تُظهر أوضح فرق في المشهد لمحاولة التكيّف مع ألوان النص والخلفية. خيار النص الأصفر مخصّص للنص الأصفر على خلفية زرقاء أو باردة فقط.",
  "OCR alanı büyütme": "تكبير منطقة OCR",
  "1× · hızlı": "1× • سريع",
  "2× · küçük yazı": "2× • للنص الصغير",
  "Ölçek uygulamadan seçilir ve yalnızca OCR kırpımına uygulanır; oyun görüntüsü değişmez. 1× en hızlısı, 1,5× genelde dengeli seçim, 2× küçük karakterler içindir. 1600 piksel genişlik sınırı korunur.":
      "يُختار مقياس التكبير من التطبيق ويُطبَّق على الجزء المحدّد لـOCR فقط؛ ولا تتغير صورة اللعبة. ‏1× هو الأسرع، و1.5× خيار متوازن عادة، و2× للحروف الصغيرة. يبقى الحد الأقصى للعرض 1600 بكسل.",
  "OCR alanı boş kalırsa tut: {0} sn": "الاحتفاظ عند خلو منطقة OCR: ‏{0} ثانية",
  "Metin yenilenmezse gizle: {0} sn": "الإخفاء إذا لم يتجدّد النص: {0} ثانية",
  "OCR alanında yeni metin algılanmazsa altyazı seçtiğin süre sonunda gizlenir.":
      "إذا لم يُكتشف نص جديد في منطقة OCR، تختفي الترجمة بعد المدة التي تختارها.",
  "Altyazı {0} genişliği: {1}%": "عرض الترجمة {0}: ‏{1}%",
  "Altyazı {0} yüksekliği: {1}%": "ارتفاع الترجمة {0}: ‏{1}%",
  "Yazı boyutu: {0}": "حجم الخط: {0}",
  "Arka plan saydamlığı: {0}%": "شفافية الخلفية: {0}%",
  "Saydamlık %0 iken arka plan tamamen opaktır. Saydamlık %100 iken arka plan tamamen görünmez olur.":
      "عند شفافية 0% تكون الخلفية معتمة تمامًا. وعند 100% تختفي الخلفية تمامًا.",
  "Arka plan kutusu": "مربع الخلفية",
  "Yalnızca yazı kadar": "بحجم النص فقط",
  "Seçili alanı doldur": "ملء المنطقة المحدّدة",
  "Arka plan yazıyla birlikte büyüyüp küçülür.": "تكبر الخلفية وتصغر مع النص.",
  "Arka plan turkuaz alanın tamamını doldurur. Kutuyu sürükleyebilir, kenarlarından boyutlandırabilir veya alan ayarlarını kullanabilirsin.":
      "تملأ الخلفية المنطقة الفيروزية بالكامل. يمكنك سحب المربع وتغيير حجمه من الحواف أو استخدام إعدادات المنطقة.",
  "Arka plan alanını ayarla": "ضبط منطقة الخلفية",
  "Arka plan rengi": "لون الخلفية",
  "Özel arka plan rengi seç": "اختيار لون خلفية مخصّص",
  "Yazı rengi": "لون النص",
  "Özel yazı rengi seç · #{0}": "اختيار لون نص مخصّص · #{0}",
  "Hizalama ve kalınlık": "المحاذاة وسُمك الخط",
  "Sola hizala": "محاذاة إلى اليسار",
  "Kalın": "عريض",
  "Normal": "عادي",
  "Renk seç · #{0}": "اختيار لون · #{0}",
  "Parlaklık": "السطوع",
  "Rengi uygula": "تطبيق اللون",
  "Anladım": "فهمت",
  "Görüntü alanı hazırlanıyor…": "جارٍ تجهيز مساحة العرض…",
  "Görüntü alanı hazır değil": "مساحة العرض غير جاهزة",
  "Remote Play görüntüsü oluşturulamadı. Ekranı yenileyip tekrar dene.":
      "تعذّر إنشاء صورة Remote Play. حدّث الشاشة وحاول مجددًا.",
  "Bağlantı başlatılamadı": "تعذّر بدء الاتصال",
  "Remote Play yeniden bağlanıyor… {0} sn. Lütfen bekleyin ({1}/4)":
      "جارٍ إعادة اتصال Remote Play… ‏{0} ثانية. يُرجى الانتظار ({1}/4)",
  "PS5 bağlantısı kapatılıyor…": "جارٍ إغلاق اتصال PS5…",
  "PS5 Remote Play": "PS5 Remote Play",
  "Görüntü gizli • Remote Play ve OCR çalışıyor":
      "الصورة مخفية • Remote Play وOCR يعملان",
  "Görüntüyü göster": "إظهار الصورة",
  "Mobil görüntüyü gizle": "إخفاء الصورة على الهاتف",
  "Çeviri hazırlanıyor…": "جارٍ تجهيز الترجمة…",
  "Deneme bitti": "انتهت التجربة",
  "Ana kullanıcıda oynamak için Remote Play oturumunu açık tut. PS5’e bağlı kumandada PS tuşuna basıp ana kullanıcıyı seç; Remote Play hesabından çıkma veya bağlantıyı kesme.":
      "أبقِ جلسة Remote Play مفتوحة للعب بحسابك الرئيسي. اضغط زر PS في وحدة التحكم المتصلة بـPS5 واختر المستخدم الرئيسي؛ ولا تسجّل الخروج من حساب Remote Play أو تقطع الاتصال.",
  "Altyazı alanlarını ve ayarlarını aç": "فتح مناطق الترجمة وإعداداتها",
  "Bağlantı kesiliyor…": "جارٍ قطع الاتصال…",
  "PS5 yeniden denenecek…": "ستُعاد محاولة الاتصال بـPS5…",
  "Çeviriyi durdur": "إيقاف الترجمة",
  "PS5’e bağlan": "الاتصال بـPS5",
  "PS5 kaydı siliniyor…": "جارٍ حذف تسجيل PS5…",
  "Bağlantıyı kes, kayıtları sil ve çık": "قطع الاتصال وحذف البيانات والخروج",
  "Doğrulama başarılı. PS5 konsolunu bağlamak için sonraki adıma devam et.":
      "تم التحقّق بنجاح. تابع إلى الخطوة التالية لربط جهاز PS5.",
  "Güvenli bağlantı doğrulanıyor…": "جارٍ التحقّق من الاتصال الآمن…",
  "PSN Account ID alınıyor…": "جارٍ الحصول على معرّف حساب PSN…",
  "Tarayıcı açılamadı. Lütfen tekrar dene.": "تعذّر فتح المتصفح. حاول مجددًا.",
  "PSN giriş sayfası açılamadı.": "تعذّر فتح صفحة تسجيل الدخول إلى PSN.",
  "Panoda yapıştırılacak bir bağlantı yok.": "لا يوجد رابط في الحافظة للصقه.",
  "Panodaki bağlantı okunamadı. Tekrar dene.":
      "تعذّرت قراءة الرابط من الحافظة. حاول مجددًا.",
  "URL içinde geçerli bir authorization code bulunamadı. Yönlendirme URL’sini kontrol et.":
      "لم يُعثر على رمز تفويض صالح في الرابط. تحقّق من رابط إعادة التوجيه.",
  "Sony hesabı doğrulanıyor…": "جارٍ التحقّق من حساب Sony…",
  "PSN hesabı doğrulanamadı. Tekrar dene.":
      "تعذّر التحقّق من حساب PSN. حاول مجددًا.",
  "PSN doğrulaması başarısız.": "فشل التحقّق من PSN.",
  "PSN Hesap Bağlantısı": "ربط حساب PSN",
  "Adım 1/2": "الخطوة 1/2",
  "PSN hesabını bağla": "ربط حسابك في PSN",
  "PSN giriş sayfasını tarayıcıda aç. Giriş yaptıktan sonra \"redirect\" yazan beyaz bir sayfa açılır. Bu sayfa açıkken tarayıcının adres çubuğundaki bağlantının tamamını kopyalayıp buraya yapıştır. Sayfadaki yazıyı değil, adres çubuğundaki linki kopyala.":
      "افتح صفحة تسجيل الدخول إلى PSN في المتصفح. بعد تسجيل الدخول، ستظهر صفحة بيضاء مكتوب عليها «redirect». انسخ الرابط بالكامل من شريط عنوان المتصفح وألصقه هنا بينما الصفحة مفتوحة. انسخ رابط شريط العنوان، وليس النص الظاهر في الصفحة.",
  "Bu bağlantı için yeni bir PSN hesabı oluştur veya şu anda kullanmadığın bir hesabı bağla, ana hesabını bağlama. Bağlayacağın PSN hesabı PlayStation 5’te de kullanıcı olarak ekli olmalı. Ana hesaptan oyunu oynayacaksın.":
      "أنشئ حساب PSN جديدًا لهذا الاتصال أو اربط حسابًا لا تستخدمه حاليًا، ولا تربط حسابك الرئيسي. يجب أيضًا إضافة حساب PSN الذي ستربطه كمستخدم على PlayStation 5. ستلعب بحسابك الرئيسي.",
  "Tarayıcı açılıyor...": "جارٍ فتح المتصفح…",
  "PSN ile giriş yap": "تسجيل الدخول باستخدام PSN",
  "Yönlendirme URL’si": "رابط إعادة التوجيه",
  "Yapıştır": "لصق",
  "PSN doğrulanıyor…": "جارٍ التحقّق من PSN…",
  "Sonraki adım: PS5 konsolunu bağla": "الخطوة التالية: ربط جهاز PS5",
  "Yardım": "المساعدة",
  "Bağlantı ve çeviri hakkında yanıtlar": "إجابات عن الاتصال والترجمة",
  "Tamamladığın adımları yeniden incele": "مراجعة الخطوات التي أكملتها",
  "Bize e-posta gönder": "مراسلتنا عبر البريد",
  "Uygulama hakkında": "حول التطبيق",
  "Sürüm": "الإصدار",
  "İlerleme bu telefonda saklanır. Konsol veya TV bağlantısını kaldırırsan ilgili adımı yeniden tamamlaman gerekir.":
      "يُحفظ التقدّم على هذا الهاتف. إذا أزلت اتصال جهاز الألعاب أو التلفزيون، فستحتاج إلى إكمال الخطوة المعنية مجددًا.",
  "Kurulum adımları": "خطوات الإعداد",
  "Adımları sırayla uygula. Tamamladıklarını işaretle; uygulama bağlantı adımlarını kendisi de tanır.":
      "اتبع الخطوات بالترتيب وعلّم على ما أكملته. يتعرّف التطبيق تلقائيًا على خطوات الاتصال أيضًا.",
  "Kurulum videosu": "فيديو الإعداد",
  "Video hazır olduğunda burada görünecek":
      "سيظهر الفيديو هنا عندما يصبح جاهزًا",
  "Videoyu izle": "مشاهدة الفيديو",
  "PS5 kurulumunu aç": "فتح إعداد PS5",
  "TV eşleştirmeyi aç": "فتح اقتران التلفزيون",
  "{0} varsayılan profil seçildi.": "تم تعيين {0} ملفًا افتراضيًا.",
  "Bu isimde bir oyun profili zaten var.":
      "يوجد ملف إعدادات لعبة بهذا الاسم بالفعل.",
  "Altyazı ayarları": "إعدادات الترجمة",
  "Oyun profili ekle": "إضافة ملف إعدادات لعبة",
  "Henüz oyun profili yok. Her oyun için OCR alanlarını ve altyazı görünümünü ayrı kaydedebilirsin.":
      "لا توجد ملفات إعدادات ألعاب بعد. يمكنك حفظ مناطق OCR ومظهر الترجمة لكل لعبة بشكل مستقل.",
  "İlk profili oluştur": "إنشاء أول ملف إعدادات",
  "Bir oyun profilini açıp OCR ve altyazı konumunu ayrı ayrı düzenle. Yıldızlı profil uygulama açılışında varsayılan olarak kullanılır.":
      "افتح ملف إعدادات لعبة وعدّل مواضع OCR والترجمة بشكل مستقل. يُستخدم الملف المميّز بنجمة افتراضيًا عند فتح التطبيق.",
  "{0} → {1} · {2} OCR alanı": "{0} ← {1} · {2} منطقة OCR",
  "Varsayılan profil": "ملف الإعدادات الافتراضي",
  "Uygulama açılışında varsayılan yap": "تعيين كافتراضي عند فتح التطبيق",
  "Oyun profili oluştur": "إنشاء ملف إعدادات لعبة",
  "Oyun adı": "اسم اللعبة",
  "Oluştur": "إنشاء",
  "Devam eden işlemin tamamlanmasını bekle.":
      "انتظر حتى تكتمل العملية الجارية.",
  "Tekrar denemek için {0} saniye bekle.":
      "انتظر {0} ثانية قبل المحاولة مجددًا.",
  "Satın alma sistemi şu anda Android için kullanılabilir.":
      "نظام الشراء متاح حاليًا على Android.",
  "Satın alma hizmeti henüz kullanıma hazır değil.":
      "خدمة الشراء غير جاهزة للاستخدام بعد.",
  "Satın alma durumu alınamadı.": "تعذّر تحميل حالة الشراء.",
  "Google hesabı doğrulanamadı.": "تعذّر التحقّق من حساب Google.",
  "Deneme başlatılamadı.": "تعذّر بدء التجربة.",
  "Hesabını silmek için önce giriş yap.": "سجّل الدخول أولًا لحذف حسابك.",
  "Uygulamadaki hesabın silindi. Oturum temizliği tamamlanamadı; uygulamayı kapatıp yeniden aç.":
      "تم حذف حسابك في التطبيق. تعذّر إكمال تنظيف الجلسة؛ أغلق التطبيق وافتحه مجددًا.",
  "Oturumun değişti. Hesap silme işlemini yeniden başlat.":
      "تغيّرت جلسة تسجيل دخولك. ابدأ عملية حذف الحساب مجددًا.",
  "Google hesabı doğrulanamadı. Hesabın silinmedi.":
      "تعذّر التحقّق من حساب Google. لم يُحذف حسابك.",
  "Abonelik planı yüklenemedi. Paketleri yenileyip tekrar dene.":
      "تعذّر تحميل باقة الاشتراك. حدّث الباقات وحاول مجددًا.",
  "Satın alma yanıtı doğrulanamadı. Satın alımları geri yüklemeyi dene.":
      "تعذّر التحقّق من استجابة الشراء. جرّب استعادة المشتريات.",
  "Google Play satın alımın bulundu ancak Premium erişimin doğrulanamadı. Yeniden ödeme yapma. Satın alımları geri yükle veya destekle iletişime geç.":
      "تم العثور على عملية شرائك في Google Play، لكن تعذّر التحقّق من وصولك إلى Premium. لا تدفع مجددًا. استعد المشتريات أو تواصل مع الدعم.",
  "Aktif satın alma bulunamadı. Ödeme bekliyorsa tamamlandıktan sonra tekrar dene.":
      "لم يُعثر على عملية شراء فعّالة. إذا كانت الدفعة معلّقة، فحاول مجددًا بعد اكتمالها.",
  "Google girişi tamamlanmadı. İptal etmediysen tekrar dene; sorun sürerse destekle iletişime geç.":
      "لم يكتمل تسجيل الدخول باستخدام Google. إن لم تكن قد ألغيته، فحاول مجددًا؛ وإذا استمرت المشكلة، فتواصل مع الدعم.",
  "Google girişi bu sürümde kullanılamıyor. Destekle iletişime geç.":
      "تسجيل الدخول باستخدام Google غير متاح في هذا الإصدار. تواصل مع الدعم.",
  "Google hesabına giriş yapılamadı. Tekrar dene.":
      "تعذّر تسجيل الدخول إلى حساب Google. حاول مجددًا.",
  "Google hesabı doğrulanamadı. İnternet bağlantını kontrol edip tekrar dene.":
      "تعذّر التحقّق من حساب Google. تحقّق من اتصالك بالإنترنت وحاول مجددًا.",
  "Uygulamada giriş yaptığın Google hesabını seçerek tekrar dene.":
      "حاول مجددًا باختيار حساب Google الذي سجّلت به الدخول إلى التطبيق.",
  "Hesabını silmek için yeniden giriş yapıp tekrar dene.":
      "سجّل الدخول مجددًا ثم حاول حذف حسابك.",
  "Google hesabı doğrulanamadı. Tekrar giriş yapmayı dene.":
      "تعذّر التحقّق من حساب Google. جرّب تسجيل الدخول مجددًا.",
  "Erişim durumu alınamadı. Tekrar dene.":
      "تعذّر تحميل حالة الوصول. حاول مجددًا.",
  "Bu satın alım Google Play hesabında zaten aktif. Satın alımları geri yükle.":
      "عملية الشراء هذه فعّالة بالفعل في حسابك على Google Play. استعد المشتريات.",
  "Ödemen Google Play onayı bekliyor. Tamamlandığında erişim durumunu yenile.":
      "دفعتك بانتظار موافقة Google Play. حدّث حالة الوصول عند اكتمالها.",
  "Satın alma hizmetine bağlanılamadı. İnternet bağlantını kontrol edip tekrar dene.":
      "تعذّر الاتصال بخدمة الشراء. تحقّق من اتصالك بالإنترنت وحاول مجددًا.",
  "Satın alım başka bir hesaba bağlı görünüyor. Satın aldığın Google Play hesabını kontrol et veya destekle iletişime geç.":
      "يبدو أن عملية الشراء مرتبطة بحساب آخر. تحقّق من حساب Google Play الذي اشتريت به أو تواصل مع الدعم.",
  "Google Play bu hesapta satın almaya izin vermiyor. Mağaza hesabını kontrol et.":
      "لا يسمح Google Play بالشراء من هذا الحساب. تحقّق من حساب المتجر.",
  "Satın alma hizmeti şu anda kullanılamıyor. Destekle iletişime geç.":
      "خدمة الشراء غير متاحة حاليًا. تواصل مع الدعم.",
  "İşlem tamamlanamadı. Biraz sonra tekrar dene.":
      "تعذّر إكمال العملية. حاول مجددًا بعد قليل.",
  "Hizmete bağlanılamadı. İnternet bağlantını kontrol edip tekrar dene.":
      "تعذّر الاتصال بالخدمة. تحقّق من اتصالك بالإنترنت وحاول مجددًا.",
  "Sürüm bilgisi alınamadı": "تعذّر تحميل معلومات الإصدار",
  "Bağlantı henüz hazır değil. Lütfen daha sonra tekrar dene.":
      "الرابط غير جاهز بعد. حاول مجددًا لاحقًا.",
  "Bağlantı açılamadı. Lütfen tekrar dene.": "تعذّر فتح الرابط. حاول مجددًا.",
  "E-posta uygulaması açılamadı. Bu adresten bize ulaşabilirsin:":
      "تعذّر فتح تطبيق البريد. يمكنك التواصل معنا على هذا العنوان:",
  "E-posta adresi kopyalandı.": "تم نسخ عنوان البريد الإلكتروني.",
  "Adresi kopyala": "نسخ العنوان",
  "Oyun kataloğu bir liste değil.": "كتالوج الألعاب ليس قائمة.",
  "Oyun kataloğu kaydı geçersiz.": "سجل كتالوج الألعاب غير صالح.",
  "Oyun kataloğunda yinelenen ID var.": "يحتوي كتالوج الألعاب على معرّف مكرّر.",
  "user_id pozitif bir tam sayı olmalıdır.":
      "يجب أن يكون user_id عددًا صحيحًا موجبًا.",
  "user_id geçerli bir sayısal değer değil.":
      "قيمة user_id ليست قيمة رقمية صالحة.",
  "TV sertifikası doğrulanamadı.": "تعذّر التحقّق من شهادة التلفزيون.",
  "TV sertifika kaydı geçersiz.": "سجل شهادة التلفزيون غير صالح.",
  "TV adresi veya 6 haneli kod geçersiz.":
      "عنوان التلفزيون أو الرمز المكوّن من 6 أرقام غير صالح.",
  "TV kimliği ekrandan doğrulanmalı.":
      "يجب التحقّق من هوية التلفزيون من شاشته.",
  "TV bağlantı denemesi iptal edildi.": "تم إلغاء محاولة الاتصال بالتلفزيون.",
  "TV kimliği doğrulanmadı.": "لم يتم التحقّق من هوية التلفزيون.",
  "User disconnected": "قطع المستخدم الاتصال",
  "Connection cancelled": "تم إلغاء الاتصال",
  "TV bağlantı güvenliği değişti.": "تغيّرت بيانات أمان اتصال التلفزيون.",
  "Pairing failed": "فشل الاقتران",
  "TV eşleştirme kodunu kabul etmedi.": "لم يقبل التلفزيون رمز الاقتران.",
  "TV bağlantısı eşleştirme tamamlanmadan kapandı.":
      "أُغلق اتصال التلفزيون قبل اكتمال الاقتران.",
  "Pairing stopped": "توقف الاقتران",
  "Pairing rejected": "تم رفض الاقتران",
  "Invalid pairing data": "بيانات الاقتران غير صالحة",
  "Pairing timed out": "انتهت مهلة الاقتران",
  "Süresiz Premium aktif": "Premium مدى الحياة فعّال",
  "Premium aboneliğin aktif": "اشتراكك في Premium فعّال",
  "Premium durumun değişti": "تغيّرت حالة Premium لديك",
  "Premium ayrıntıları": "تفاصيل Premium",
  "Abonelik ayrıntıları": "تفاصيل الاشتراك",
  "Güncel erişim durumunu ve satın alımlarını ayrıntılar ekranından kontrol edebilirsin.":
      "يمكنك مراجعة حالة الوصول الحالية ومشترياتك من شاشة التفاصيل.",
  "Premium çeviri özelliklerine süresiz erişimin var. Tek seferlik satın alımın için otomatik yenileme veya tekrar ödeme yok.":
      "لديك وصول مدى الحياة إلى ميزات الترجمة في Premium. لا يوجد تجديد تلقائي أو دفعات إضافية لعملية الشراء هذه.",
  "Google Play deneme aboneliğin aktif. {0}{1}":
      "اشتراكك التجريبي عبر Google Play فعّال. {0}{1}",
  "Deneme bitişi: {0}. ": "تنتهي التجربة في: {0}. ",
  "Deneme sonunda ücretli olarak yenilenir.":
      "يتجدّد كاشتراك مدفوع عند انتهاء التجربة.",
  "Otomatik yenileme kapalı.": "التجديد التلقائي معطّل.",
  "Premium çeviri özelliklerini kullanabilirsin.\n\n{0}{1}":
      "يمكنك استخدام ميزات الترجمة في Premium.\n\n{0}{1}",
  "Otomatik yenileme açık.": "التجديد التلقائي مفعّل.",
  "Otomatik yenileme kapalı; mevcut dönem sonuna kadar erişimin devam eder.":
      "التجديد التلقائي معطّل؛ ويستمر وصولك حتى نهاية الفترة الحالية.",
  "Sonraki yenileme": "التجديد التالي",
  "Erişim bitişi": "انتهاء الوصول",
  "Önce TV uygulamasını indir": "نزّل تطبيق التلفزيون أولًا",
  "Sistem dili": "لغة النظام",
  "Dil tercihi kaydedilemedi. Tekrar dene.":
      "تعذّر حفظ تفضيل اللغة. حاول مجددًا.",
  "Kapat": "إغلاق",
  "Tamam": "موافق",
  "Kaydet": "حفظ",
  "Geri": "رجوع",
  "Devam": "متابعة",
  "Hata": "خطأ",
  "Kaynak": "المصدر",
  "Hedef": "الهدف",
  "hafta": "أسبوع",
  "ay": "شهر",
  "PS5 gerekli": "يلزم PS5",
  "PS5’i kur": "إعداد PS5",
  "Abonelik": "الاشتراك",
  "Hesap": "الحساب",
  "PS5 IPv4 adresi": "عنوان IPv4 الخاص بـPS5",
  "PS5 kaydediliyor…": "جارٍ تسجيل PS5…",
  "Ortala": "توسيط",
  "Ton": "درجة اللون",
  "Doygunluk": "التشبّع",
  "Oyun": "اللعبة",
  "indirildi": "تم التنزيل",
  "indirilmedi": "لم يُنزَّل",
  "{0} • indirilmedi": "{0} • لم يُنزَّل",
  "Dil paketi gerekli": "تلزم حزمة اللغة",
  "Model B için seçili kaynak ve hedef dil paketlerini önce indir.":
      "نزّل حزم لغتَي المصدر والهدف المحدّدتين لـModel B أولًا.",
  "{0} Destek": "دعم {0}",
  "Deneme için Google hesabınla giriş yap.":
      "سجّل الدخول بحسابك في Google لبدء التجربة.",
  "Hesap zamanı doğrulanamadı.": "تعذّر التحقّق من وقت الحساب.",
  "Deneme kaydı geçersiz.": "سجل التجربة غير صالح.",
  "JSONL satır {0} okunamadı.": "تعذّرت قراءة السطر {0} من JSONL.",
  "JSONL satır {0}: ID eksik.": "السطر {0} من JSONL: المعرّف مفقود.",
  "JSONL satır {0}: yinelenen ID {1}.":
      "السطر {0} من JSONL: المعرّف {1} مكرّر.",
  "HPLT modeli kapalı.": "نموذج HPLT غير نشط.",
  "HPLT model.bin bulunamadı.": "لم يُعثر على ملف model.bin الخاص بـHPLT.",
  "HPLT İngilizce sözlüğü açılamadı.": "تعذّر فتح قاموس HPLT الإنجليزي.",
  "HPLT Türkçe sözlüğü açılamadı.": "تعذّر فتح قاموس HPLT التركي.",
  "HPLT modeli yüklenemedi.": "تعذّر تحميل نموذج HPLT.",
  "OPUS-MT SentencePiece sözlüğü açılamadı":
      "تعذّر فتح قاموس SentencePiece الخاص بـOPUS-MT",
  "Almanca": "الألمانية",
  "Katalanca": "الكتالونية",
  "Fransızca": "الفرنسية",
  "İspanyolca": "الإسبانية",
  "İtalyanca": "الإيطالية",
  "Felemenkçe": "الهولندية",
  "Yunanca": "اليونانية",
  "Rusça": "الروسية",
  "PSN giriş kodu kabul edilmedi. PSN ile yeniden giriş yap.":
      "لم يُقبل رمز تسجيل الدخول إلى PSN. سجّل الدخول إلى PSN مجددًا.",
  "Güvenlik doğrulaması tamamlanamadı. Tekrar dene.":
      "تعذّر إكمال التحقّق الأمني. حاول مجددًا.",
  "Çok fazla doğrulama denemesi yapıldı. Bir dakika sonra tekrar dene.":
      "أُجريت محاولات تحقّق كثيرة جدًا. حاول مجددًا بعد دقيقة.",
  "PSN hesap doğrulama hizmeti henüz hazır değil.":
      "خدمة التحقّق من حساب PSN غير جاهزة بعد.",
  "PSN hesap doğrulama hizmetine ulaşılamadı. Tekrar dene.":
      "تعذّر الوصول إلى خدمة التحقّق من حساب PSN. حاول مجددًا.",
  "PSN hesap yanıtı geçersiz.": "استجابة حساب PSN غير صالحة.",
  "PSN hesap doğrulama sunucusu yapılandırılmamış.":
      "لم يُضبط خادم التحقّق من حساب PSN.",
  "Güvenlik doğrulaması zaman aşımına uğradı. Tekrar dene.":
      "انتهت مهلة التحقّق الأمني. حاول مجددًا.",
  "Güvenlik doğrulaması için güvenli bağlantı kurulamadı.":
      "تعذّر إنشاء اتصال آمن لإجراء التحقّق الأمني.",
  "Güvenlik doğrulama sayfası açılamadı. Tekrar dene.":
      "تعذّر فتح صفحة التحقّق الأمني. حاول مجددًا.",
  "Güvenlik doğrulaması kesildi. Tekrar deneyebilirsin.":
      "انقطع التحقّق الأمني. يمكنك المحاولة مجددًا.",
  "Güvenlik doğrulama adresi geçersiz.": "عنوان التحقّق الأمني غير صالح.",
  "Güvenli bağlantı": "اتصال آمن",
  "Güvenlik doğrulaması iptal edildi. Tekrar deneyebilirsin.":
      "تم إلغاء التحقّق الأمني. يمكنك المحاولة مجددًا.",
  "Konsol bilgileri güvenli depoya yazılamadı.":
      "تعذّر حفظ بيانات جهاز الألعاب في التخزين الآمن.",
  "Güvenli kayıt silinemedi.": "تعذّر حذف البيانات المحفوظة بأمان.",
  "PSN Account ID güvenli depodan silinemedi.":
      "تعذّر حذف معرّف حساب PSN من التخزين الآمن.",
  "PSN Account ID 8 bayt olmalı.": "يجب أن يكون معرّف حساب PSN بطول 8 بايت.",
  "PSN Account ID güvenli depoya yazılamadı.":
      "تعذّر حفظ معرّف حساب PSN في التخزين الآمن.",
  "Kayıtlı PSN Account ID geçersiz.": "معرّف حساب PSN المحفوظ غير صالح.",
  "Uyarı tercihi geçersiz.": "تفضيل التنبيه غير صالح.",
  "Uyarı tercihi kaydedilemedi.": "تعذّر حفظ تفضيل التنبيه.",
  "Kurulum işaretleri geçersiz.": "علامات إكمال الإعداد غير صالحة.",
  "Çeviri motoru seçimi geçersiz.": "اختيار محرّك الترجمة غير صالح.",
  "TV eşleştirme bilgileri geçersiz.": "بيانات اقتران التلفزيون غير صالحة.",
  "TV eşleştirmesi kaydedilemedi.": "تعذّر حفظ اقتران التلفزيون.",
  "Kayıtlı PSN ve PS5 bilgileri silinemedi.":
      "تعذّر حذف بيانات PSN وPS5 المحفوظة.",
  "Bildirim izni isteği zaten açık.": "طلب إذن الإشعارات مفتوح بالفعل.",
  "Çeviri bildirimi başlatılamadı.": "تعذّر بدء إشعار الترجمة.",
  "Ekran kapalıyken çeviri": "الترجمة والشاشة مغلقة",
  "Şimdi değil": "ليس الآن",
  "Ayarları aç": "فتح الإعدادات",
  "Bir PS5 kayıt işlemi zaten çalışıyor.": "توجد عملية تسجيل PS5 جارية بالفعل.",
  "Güvenli PSN kaydı açılamadı. PSN hesabını yeniden doğrula.":
      "تعذّر فتح بيانات PSN المحفوظة بأمان. أعد التحقّق من حساب PSN.",
  "Önce PSN hesabını doğrula.": "تحقّق من حساب PSN أولًا.",
  "Chiaki kayıt işlemi başlatılamadı.": "تعذّر بدء عملية التسجيل عبر Chiaki.",
  "Kayıt başlatılırken hata oluştu.": "حدث خطأ أثناء بدء التسجيل.",
  "PS5 kaydı alındı ancak güvenli depoya yazılamadı.":
      "تم الحصول على تسجيل PS5، لكن تعذّر حفظه في التخزين الآمن.",
  "Chiaki-ng PS5 kaydını tamamlayamadı. Host ve PIN bilgilerini kontrol edip yeniden dene.":
      "تعذّر على Chiaki-ng إكمال تسجيل PS5. تحقّق من عنوان الجهاز ورمز PIN وحاول مجددًا.",
  "PS5 kayıt işlemi iptal edildi.": "تم إلغاء عملية تسجيل PS5.",
  "Kayıtlı PS5 bilgileri çözülemedi. Yeniden eşleştirmen gerekebilir.":
      "تعذّر فك تشفير بيانات PS5 المحفوظة. قد تحتاج إلى إعادة الاقتران.",
  "Oyun profilleri okunamadı.": "تعذّرت قراءة ملفات إعدادات الألعاب.",
  "PS5 görüntü alanı hazır değil.": "مساحة عرض صورة PS5 غير جاهزة.",
  "PS5 karesini alamadım. Remote Play görüntüsü açıkken yeniden dene.":
      "تعذّر الحصول على إطار من PS5. حاول مجددًا أثناء عرض صورة Remote Play.",
  "PS5 ekran görüntüsü uygulama alanına kaydedilemedi.":
      "تعذّر حفظ لقطة شاشة PS5 في مساحة التطبيق.",
  "Kayıtlı ekran görüntüsü bulunamadı.": "لم يُعثر على لقطة شاشة محفوظة.",
  "Altyazı ayarları okunamadı.": "تعذّرت قراءة إعدادات الترجمة.",
  "Altyazı ayarları kaydedilemedi.": "تعذّر حفظ إعدادات الترجمة.",
  "Oyun seçimi kaydedilemedi.": "تعذّر حفظ اختيار اللعبة.",
  "Oyun çeviri dosyası okunamadı.": "تعذّرت قراءة ملف ترجمة اللعبة.",
  "Model C için 64-bit ARM Android gerekiyor.":
      "يتطلب Model C جهاز Android بمعمارية ARM ‏64 بت.",
  "Model klasörü oluşturulamadı.": "تعذّر إنشاء مجلد النموذج.",
  "{0} dosyası eksik veya boyutu doğrulanamadı.":
      "الملف {0} مفقود أو تعذّر التحقّق من حجمه.",
  "{0} dosyasının SHA-256 doğrulaması başarısız.":
      "فشل التحقّق من بصمة SHA-256 للملف {0}.",
  "Eski {0} dosyası değiştirilemedi.": "تعذّر استبدال الملف القديم {0}.",
  "{0} dosyası kaydedilemedi.": "تعذّر حفظ الملف {0}.",
  "HPLT model paketi doğrulanamadı.": "تعذّر التحقّق من حزمة نموذج HPLT.",
  "Bu çevrimdışı dil modeli henüz desteklenmiyor.":
      "نموذج اللغة هذا للاستخدام دون إنترنت غير مدعوم بعد.",
  "Dil seçimi okunamadı.": "تعذّرت قراءة اختيار اللغة.",
  "Bu çevrimdışı dil henüz sunulmuyor.":
      "هذه اللغة غير متاحة للاستخدام دون إنترنت بعد.",
  "İndirilen model doğrulanamadı.": "تعذّر التحقّق من النموذج المنزّل.",
  "Çevrimdışı model dosyaları beklenen dil modeliyle uyuşmuyor.":
      "ملفات النموذج المحلي لا تطابق نموذج اللغة المتوقع.",
  "Çevrimdışı model dosyaları eksik veya sürümleri uyuşmuyor.":
      "ملفات النموذج المحلي ناقصة أو إصداراتها غير متوافقة.",
  "Çevrimdışı dil modeli indirilemedi.":
      "تعذّر تنزيل نموذج اللغة للاستخدام دون إنترنت.",
  "Kaynak ve hedef dil seçimini kontrol et.":
      "تحقّق من لغتَي المصدر والهدف المحدّدتين.",
  "Çeviri dil paketleri indirilemedi. İnternet bağlantını kontrol et.":
      "تعذّر تنزيل حزم لغات الترجمة. تحقّق من اتصالك بالإنترنت.",
  "Bu çeviri dili desteklenmiyor.": "لغة الترجمة هذه غير مدعومة.",
  "Dil paketi indirilemedi. İnternet bağlantını kontrol edip yeniden dene.":
      "تعذّر تنزيل حزمة اللغة. تحقّق من اتصالك بالإنترنت وحاول مجددًا.",
  "PSN yönlendirme kodu geçersiz.": "رمز إعادة التوجيه من PSN غير صالح.",
  "PSN hesabı zaten doğrulanıyor.": "جارٍ التحقّق من حساب PSN بالفعل.",
  "Doğrulama için uygulamayı yeniden aç.": "أعد فتح التطبيق لإجراء التحقّق.",
  "PSN hesabı doğrulanamadı.": "تعذّر التحقّق من حساب PSN.",
  "Hesap doğrulama sunucusundan yanıt alınamadı. Tekrar dene.":
      "لم تصل استجابة من خادم التحقّق من الحساب. حاول مجددًا.",
  "Hesap doğrulama sunucusunun TLS sertifikası doğrulanamadı.":
      "تعذّر التحقّق من شهادة TLS لخادم التحقّق من الحساب.",
  "PSN hesabı doğrulanamadı. Giriş akışını yeniden başlatıp tekrar dene.":
      "تعذّر التحقّق من حساب PSN. ابدأ خطوات تسجيل الدخول من جديد وحاول مجددًا.",
  "Güvenlik doğrulaması açılamadı. Android System WebView'i kontrol edip tekrar dene.":
      "تعذّر فتح التحقّق الأمني. تحقّق من Android System WebView وحاول مجددًا.",
  "Bir Remote Play oturumu zaten açık.": "توجد جلسة Remote Play مفتوحة بالفعل.",
  "Kayıtlı PS5 bilgileri okunamadı. Yeniden PS5 eşleştirmen gerekebilir.":
      "تعذّرت قراءة بيانات PS5 المحفوظة. قد تحتاج إلى إعادة إقران PS5.",
  "Önce bir PS5'i kaydet.": "سجّل جهاز PS5 أولًا.",
  "Arka plan çeviri servisi başlatılamadı.":
      "تعذّر بدء خدمة الترجمة في الخلفية.",
  "PS5 bağlantısı iptal edildi.": "تم إلغاء اتصال PS5.",
  "Chiaki oturumu başlatılamadı: {0}": "تعذّر بدء جلسة Chiaki: ‏{0}",
  "Remote Play oturumu başlatılamadı.": "تعذّر بدء جلسة Remote Play.",
  "Chiaki oturumu kapatılamadı: {0}": "تعذّر إغلاق جلسة Chiaki: ‏{0}",
  "Remote Play oturumu kapatılırken hata oluştu.":
      "حدث خطأ أثناء إغلاق جلسة Remote Play.",
  "Yerel ağ keşfi başlatılamadı: {0}":
      "تعذّر بدء اكتشاف الأجهزة على الشبكة المحلية: {0}",
  "Bildirim izni isteği tamamlanamadı.": "تعذّر إكمال طلب إذن الإشعارات.",
  "Çeviri modeli hazır değil": "نموذج الترجمة غير جاهز",
  "OCR kapalı": "OCR معطّل",
  "Önceki OCR karesi hâlâ işleniyor": "لا يزال إطار OCR السابق قيد المعالجة",
  "Video karesi henüz hazır değil": "إطار الفيديو غير جاهز بعد",
  "OCR alanı boş": "منطقة OCR فارغة",
  "Video karesi işlenemedi": "تعذّرت معالجة إطار الفيديو",
  "Seçili alanda metin bulunamadı": "لم يُعثر على نص في المنطقة المحدّدة",
  "OCR işlenemedi: {0}": "تعذّرت معالجة OCR: ‏{0}",
  "OCR hatası": "خطأ في OCR",
  "Çeviri hazırlanıyor": "جارٍ تجهيز الترجمة",
  "Çevrildi": "تمت الترجمة",
  "Çeviri başarısız": "فشلت الترجمة",
  "Yerel çeviri paketi açılamadı": "تعذّر فتح حزمة الترجمة المحلية",
  "HPLT modeli açılamadı": "تعذّر فتح نموذج HPLT",
  "HPLT çevirisi hazırlanıyor": "جارٍ تجهيز ترجمة HPLT",
  "Çevrildi · HPLT": "تمت الترجمة · HPLT",
  "HPLT çevirisi başarısız": "فشلت ترجمة HPLT",
  "Çeviri için aktif deneme veya Premium gerekiyor.":
      "تتطلب الترجمة تجربة فعّالة أو وصولًا إلى Premium.",
  "Satın alma kontrolü devam ediyor.": "جارٍ التحقّق من المشتريات.",
  "Hesap değişti.": "تغيّر الحساب.",
  "Satın alma durumu alınamadı. İnternete bağlanıp tekrar dene.":
      "تعذّر تحميل حالة الشراء. اتصل بالإنترنت وحاول مجددًا.",
  "Erişim kontrolü devam ediyor.": "جارٍ التحقّق من صلاحية الوصول.",
  "Deneme durumu alınamadı. Google girişini ve internet bağlantını kontrol et.":
      "تعذّر تحميل حالة التجربة. تحقّق من تسجيل الدخول باستخدام Google والاتصال بالإنترنت.",
  "Çeviri beklemede": "الترجمة قيد الانتظار",
  "İlk video karesi henüz alınmadı. Bildirim açık kalıyor.":
      "لم يصل إطار الفيديو الأول بعد. سيبقى الإشعار نشطًا.",
  "Yeni video karesi yok. Görüntü gelince çeviri sürdürülecek.":
      "لا توجد إطارات فيديو جديدة. ستُستأنف الترجمة عند عودة الصورة.",
  "Çeviri çalışıyor": "الترجمة قيد التشغيل",
  "Menüye dönmek için dokun.": "اضغط للعودة إلى القائمة.",
  "Çeviri durumu": "حالة الترجمة",
  "Remote Play altyazı çevirisi": "ترجمة نصوص Remote Play",
  "PS5 bağlantısı arka planda sürüyor. Menüye dönmek için dokun.":
      "اتصال PS5 مستمر في الخلفية. اضغط للعودة إلى القائمة.",
  "Remote Play oturumu": "جلسة Remote Play",
  "Durdur": "إيقاف",
  "PS5’im bulunmuyor veya bağlanmıyor. Ne yapmalıyım?":
      "لم يُعثر على PS5 أو تعذّر الاتصال به. ماذا أفعل؟",
  "Telefon ve PS5 aynı yerel ağda olmalı; PS5 Ethernet, telefon Wi-Fi kullanabilir. Konsolu açıp Remote Play’i etkinleştir. Ağda bulunmazsa PS5’in Ayarlar → Ağ → Bağlantı Durumu bölümündeki IP adresini elle gir. Kayıtta kullandığın PSN hesabı konsolda kullanıcı olarak da ekli olmalı. Cihazı Bağla ekranındaki güncel 8 haneli PIN ile tekrar dene.":
      "يجب أن يكون الهاتف وPS5 على الشبكة المحلية نفسها؛ ويمكن توصيل PS5 عبر Ethernet والهاتف عبر Wi-Fi. شغّل الجهاز وفعّل Remote Play. إذا لم يُعثر عليه على الشبكة، فأدخل عنوان IP يدويًا من إعدادات PS5 ← الشبكة ← حالة الاتصال. يجب أيضًا إضافة حساب PSN المستخدم للتسجيل كمستخدم على الجهاز. حاول مجددًا باستخدام رمز PIN الحالي المكوّن من 8 أرقام من شاشة «إقران الجهاز».",
  "PS5 bağlı görünüyor ama telefondaki görüntü siyah. Ne yapmalıyım?":
      "يظهر PS5 متصلًا لكن الصورة على الهاتف سوداء. ماذا أفعل؟",
  "Mobil görüntüyü gizlediysen Görüntüyü göster’e dokun. Ana sayfada olmak veya önizlemeyi gizlemek çeviriyi durdurmaz. Önizleme açıkken de görüntü yoksa PS5 kartından Remote Play’e dön; bağlantı veya görüntü yenileniyorsa bekle. Sorun sürerse çeviriyi durdurup yeniden başlat. PS5’te bağlantı bildirimi görünmesi tek başına video akışının hazır olduğunu göstermez.":
      "إذا أخفيت الصورة على الهاتف، فاضغط «إظهار الصورة». لا تؤدي العودة إلى الرئيسية أو إخفاء المعاينة إلى إيقاف الترجمة. إذا لم تظهر الصورة حتى مع فتح المعاينة، فاختر «العودة إلى Remote Play» من بطاقة PS5، وانتظر إذا كان الاتصال أو الصورة قيد التحديث. إذا استمرت المشكلة، فأوقف الترجمة وأعد تشغيلها. ظهور إشعار الاتصال على PS5 وحده لا يعني أن بث الفيديو جاهز.",
  "Uygulamadaki PS5 görüntüsü nereden geliyor?":
      "من أين تأتي صورة PS5 داخل التطبيق؟",
  "Telefondaki görüntü PS5’ten Remote Play ile alınan canlı akıştır. OCR, bu görüntüde seçtiğin alanlardaki metni okur. TV’de PS5’in HDMI girişini izlersin; çevrilen altyazıyı Android TV uygulaması bu görüntünün üzerinde gösterir.":
      "الصورة على الهاتف بث مباشر من PS5 عبر Remote Play. يقرأ OCR النصوص في المناطق التي تختارها من هذه الصورة. على التلفزيون، تشاهد مدخل HDMI الخاص بـPS5، ويعرض تطبيق Android TV الترجمة فوق الصورة.",
  "Altyazıları PS5’in HDMI görüntüsünde göstermek için ne gerekli?":
      "ما المطلوب لعرض الترجمة فوق صورة PS5 عبر HDMI؟",
  "Telefon uygulaması, PS5 ve OyunÇevirmeni TV uygulamasını çalıştırabilen bir Android TV gerekir. TV uygulamasına diğer uygulamaların üzerinde gösterim izni ver, telefonu TV ile eşleştir ve telefonda çeviriyi başlat. TV’de altyazı gösterimi açık olmalı. Sonra PS5’in bağlı olduğu HDMI girişine geç. HDMI üzerinde gösterim desteği TV’nin sistemine bağlıdır.":
      "تحتاج إلى تطبيق الهاتف وجهاز PS5 وتلفزيون Android TV يمكنه تشغيل Console Game Translator TV. امنح تطبيق التلفزيون إذن الظهور فوق التطبيقات الأخرى، وأقرن الهاتف بالتلفزيون، ثم ابدأ الترجمة على الهاتف. يجب تفعيل عرض الترجمة على التلفزيون. بعد ذلك، انتقل إلى مدخل HDMI المتصل بـPS5. يعتمد دعم العرض فوق HDMI على نظام التلفزيون.",
  "Telefon oyun görüntüsünü TV’ye gönderiyor mu?":
      "هل يرسل الهاتف صورة اللعبة إلى التلفزيون؟",
  "Hayır. Oyun görüntüsü PS5’in HDMI bağlantısından gelir. Telefon, Remote Play görüntüsünü metni okumak için kullanır; TV’ye çevrilmiş altyazı metnini ve görünüm ayarlarını gönderir. TV uygulaması bu metni ayrı bir katmanda gösterir.":
      "لا. تأتي صورة اللعبة من اتصال HDMI الخاص بـPS5. يستخدم الهاتف صورة Remote Play لقراءة النص، ويرسل النص المترجم وإعدادات المظهر إلى التلفزيون. يعرض تطبيق التلفزيون هذا النص في طبقة منفصلة.",
  "Uygulama arka plandayken veya telefonun ekranı kapalıyken çeviri devam eder mi?":
      "هل تستمر الترجمة عندما يعمل التطبيق في الخلفية أو تكون شاشة الهاتف مغلقة؟",
  "Evet. Çeviriyi Başlat’tan sonra Remote Play ve OCR arka planda çalışır; uygulama ana sayfaya döner. Başka bir uygulamaya geçebilir veya ekranı kapatabilirsin. Bildirimlere izin vererek çeviri durumunu takip edebilirsin. Kesinti olursa uygulamaya dönüp PS5 ve TV bağlantısını kontrol et; telefonun pil ayarlarında uygulamanın arka plan çalışmasını kısıtlamadığından emin ol. Zorla durdurma işlemi oturumu sonlandırır.":
      "نعم. بعد الضغط على «بدء الترجمة»، يعمل Remote Play وOCR في الخلفية ويعود التطبيق إلى الرئيسية. يمكنك الانتقال إلى تطبيق آخر أو إغلاق الشاشة. اسمح بالإشعارات لمتابعة حالة الترجمة. إذا حدث انقطاع، فعد إلى التطبيق وتحقّق من اتصال PS5 والتلفزيون، وتأكّد من أن إعدادات بطارية الهاتف لا تقيّد عمل التطبيق في الخلفية. يؤدي الإيقاف الإجباري إلى إنهاء الجلسة.",
  "Çeviriyi Başlat’a bastığımda neden başlamıyor?":
      "لماذا لا تبدأ الترجمة عند الضغط على «بدء الترجمة»؟",
  "PS5 kaydı hazır, Android TV bağlı ve seçili modelin dil paketleri indirilmiş olmalı. Ayrıca Google hesabınla giriş yapıp kullanılabilir deneme süresine veya Premium erişime sahip olmalısın. Ekrandaki hata mesajına göre eksik adımı tamamla. PS5 yeniden bağlanıyorsa bekle; başarısız olursa bağlantıları kontrol edip tekrar dene.":
      "يجب أن يكون تسجيل PS5 جاهزًا، وAndroid TV متصلًا، وحزم لغات النموذج المحدّد منزّلة. يجب أيضًا تسجيل الدخول بحساب Google وامتلاك وقت متبقٍ للتجربة أو وصول إلى Premium. أكمل الخطوة الناقصة بحسب رسالة الخطأ. إذا كان PS5 يعيد الاتصال، فانتظر؛ وإذا فشل، فتحقّق من الاتصالات وحاول مجددًا.",
  "Altyazılar TV’de görünmüyor. Neleri kontrol etmeliyim?":
      "لا تظهر الترجمة على التلفزيون. ممّ أتحقّق؟",
  "Telefondaki Android TV kartında Bağlı yazdığını ve çevirinin çalıştığını kontrol et. TV uygulamasında İzin ver ile üstte gösterim iznini ver; izin zaten açıksa Altyazıyı aç / yenile’yi kullan. Altyazılar duraklatılmışsa Altyazıları sürdür’e bas. Oyundaki metin sarı OCR alanında olmalı. TV’yi PS5’in HDMI girişine al; sorun sürerse TV uygulamasını yeniden açıp bağlantı durumuna bak.":
      "تحقّق من ظهور «متصل» في بطاقة Android TV على الهاتف ومن تشغيل الترجمة. في تطبيق التلفزيون، اضغط «منح الإذن» للسماح بالظهور فوق التطبيقات؛ وإذا كان الإذن ممنوحًا بالفعل، فاستخدم «تشغيل الترجمة / تحديثها». إذا كانت الترجمة متوقفة مؤقتًا، فاضغط «استئناف الترجمة». يجب أن يكون نص اللعبة داخل منطقة OCR الصفراء. بدّل التلفزيون إلى مدخل HDMI الخاص بـPS5؛ وإذا استمرت المشكلة، فأعد فتح تطبيق التلفزيون وراجع حالة الاتصال.",
  "OCR metni yanlış okuyor veya geç algılıyor. Ne yapabilirim?":
      "يقرأ OCR النص بشكل خاطئ أو يتأخر في اكتشافه. ماذا أفعل؟",
  "Altyazı → Altyazı görünümü bölümünde sarı OCR alanını yalnızca okunacak metni tam kapsayacak şekilde ayarla. Konuşma altyazılarında diyalog filtresini deneyebilir, görev ve menü yazılarında kapalı tutabilirsin. Ön işleme ve ölçek ayarları her OCR alanı için ayrıdır; küçük yazıda 1,5× veya 2× ölçeği dene. Oyundaki altyazı arka planını açmak ve yazıyı büyütmek de okumayı iyileştirebilir.":
      "افتح «الترجمة ← مظهر الترجمة» واضبط منطقة OCR الصفراء لتحتوي النص المطلوب قراءته بالكامل دون غيره. يمكنك تجربة مرشّح الحوار للحوارات، وإبقاؤه معطّلًا للمهام والقوائم. إعدادات المعالجة المسبقة والتكبير مستقلة لكل منطقة OCR؛ جرّب 1.5× أو 2× للنص الصغير. قد يساعد أيضًا تفعيل خلفية الترجمة في اللعبة وتكبير الخط على تحسين القراءة.",
  "İstediğim dil neden kaynak veya hedef listesinde görünmüyor?":
      "لماذا لا تظهر اللغة المطلوبة في قائمة المصدر أو الهدف؟",
  "Dil menüleri seçili modelin desteklediği tüm dilleri gösterir; indirilmemiş olanlar “indirilmedi” olarak işaretlenir. Dili seçtikten sonra altındaki İndir’e dokun veya Dilleri görüntüle ve indir’den paketi indir. Model A’da kaynak dil İngilizcedir; hedef dil paketini seçersin. Model B’de kaynak ve hedef paketleri ayrı gerekir. Bir modelin listesinde bulunmayan dil için diğer modelin desteklediği dilleri kontrol et.":
      "تعرض قوائم اللغات جميع اللغات التي يدعمها النموذج المحدّد، وتضع علامة «لم يُنزَّل» على غير المنزّلة. بعد اختيار اللغة، اضغط «تنزيل» أسفلها، أو نزّل الحزمة من «عرض اللغات وتنزيلها». لغة المصدر في Model A هي الإنجليزية، وتختار حزمة اللغة المستهدفة. يحتاج Model B إلى حزمتَي المصدر والهدف بشكل منفصل. إذا لم تجد اللغة في قائمة أحد النماذج، فراجع اللغات التي يدعمها النموذج الآخر.",
  "Model A ve Model B arasındaki fark nedir?": "ما الفرق بين Model A وModel B؟",
  "Model A daha yavaş çalışır ancak daha doğru ve kaliteli çeviriler sunar. Model B daha hızlıdır; çevirileri zaman zaman daha az isabetli olabilir. Kalite önceliğinse Model A’yı, hız önceliğinse Model B’yi tercih edebilirsin.":
      "يعمل Model A ببطء أكبر، لكنه يقدّم ترجمات أدق وأفضل جودة. أما Model B فأسرع، وقد تكون ترجماته أقل دقة أحيانًا. اختر Model A إذا كانت الجودة أولويتك، أو Model B إذا كانت السرعة أولويتك.",
  "Altyazı sekmesindeki Oyun Kütüphanesi ne işe yarar?":
      "ما فائدة مكتبة الألعاب في تبويب الترجمة؟",
  "Oyun Kütüphanesi, oyununa özel hazır çevirilerle hikâyeyi daha rahat takip etmene yardımcı olur. En iyi deneyim için oyunun listede varsa Altyazı sekmesindeki Oyun Kütüphanesi bölümünden seç.":
      "تساعدك مكتبة الألعاب على متابعة القصة بسهولة أكبر بترجمات جاهزة خاصة بلعبتك. للحصول على أفضل تجربة، اختر لعبتك من «مكتبة الألعاب» في تبويب «الترجمة» إن كانت في القائمة.",
  "Uygulamaya döndüğümde PS5’i yeniden kaydetmem gerekir mi?":
      "هل أحتاج إلى إعادة تسجيل PS5 عند العودة إلى التطبيق؟",
  "Hayır. Oturum sürüyorsa mevcut Remote Play bağlantısı kullanılır. Beklenmedik kopmalarda uygulama yeniden bağlanmayı dener; PS5 kartında yeniden bağlanma veya görüntü yenileme durumunu görebilirsin. Denemeler sonuç vermezse konsolun ve ağın açık olduğunu kontrol edip çeviriyi tekrar başlat. PS5’i listeden kaldırmadığın sürece tekrar kayıt gerekmez.":
      "لا. إذا كانت الجلسة مستمرة، يُستخدم اتصال Remote Play الحالي. عند حدوث انقطاع غير متوقع، يحاول التطبيق إعادة الاتصال؛ ويمكنك رؤية حالة إعادة الاتصال أو تحديث الصورة في بطاقة PS5. إذا فشلت المحاولات، فتحقّق من تشغيل الجهاز والشبكة وأعد بدء الترجمة. لا يلزم التسجيل مجددًا ما لم تُزل PS5 من القائمة.",
  "Çeviriyi durdurunca PS5 kaydı veya TV eşleştirmesi silinir mi?":
      "هل يؤدي إيقاف الترجمة إلى حذف تسجيل PS5 أو اقتران التلفزيون؟",
  "Hayır. Çeviriyi Durdur, Remote Play ve çeviri akışını durdurup TV’deki mevcut altyazıyı temizler. Kayıtlı PS5, TV eşleştirmesi, dil paketleri ve altyazı ayarları korunur. PS5’i listeden kaldırmak ayrı bir işlemdir; TV eşleştirmesi de TV uygulamasındaki sıfırlama işlemiyle ayrıca yenilenir.":
      "لا. يوقف زر «إيقاف الترجمة» اتصال Remote Play وتدفّق الترجمة، ويمسح النص الظاهر على التلفزيون. يُحتفَظ بتسجيل PS5 واقتران التلفزيون وحزم اللغات وإعدادات الترجمة. إزالة PS5 من القائمة إجراء منفصل؛ ويمكن إعادة إعداد اقتران التلفزيون بشكل مستقل عبر إعادة الضبط في تطبيق التلفزيون.",
  "TV eşleştirme kodu veya bağlantısı çalışmıyor. Ne yapmalıyım?":
      "رمز اقتران التلفزيون أو الاتصال لا يعمل. ماذا أفعل؟",
  "İlk eşleştirmede TV uygulamasını aç; TV ve telefonu aynı yerel ağa bağla. TV’yi ağda bul ile TV’yi seç veya ekrandaki adresi elle gir, ardından güncel 6 haneli kodu kullan. Kimlik doğrulama ekranı açılırsa değeri TV’deki Güvenli bağlantı kimliği ile karşılaştır. Daha önce eşleşmiş TV bağlanmıyorsa TV uygulamasını yeniden açıp tekrar dene; eşleştirme sıfırlandıysa yeniden eşleştir.":
      "في الاقتران الأول، افتح تطبيق التلفزيون ووصل التلفزيون والهاتف بالشبكة المحلية نفسها. اختر التلفزيون عبر «البحث عن التلفزيون على الشبكة» أو أدخل العنوان الظاهر على شاشته يدويًا، ثم استخدم الرمز الحالي المكوّن من 6 أرقام. إذا ظهرت شاشة التحقّق من الهوية، فقارن القيمة مع «هوية الاتصال الآمن» على التلفزيون. إذا تعذّر اتصال تلفزيون سبق إقرانه، فأعد فتح تطبيقه وحاول مجددًا؛ وإذا أُعيد ضبط الاقتران، فأقرنه من جديد.",
  "PSN bağlantısında hangi hesabı ve hangi yönlendirme adresini kullanmalıyım?":
      "أي حساب وأي رابط إعادة توجيه أستخدم عند ربط PSN؟",
  "Remote Play için yeni veya kullanmadığın ayrı bir PSN hesabı kullan ve bu hesabı PS5’e kullanıcı olarak ekle; oyunu ana hesabında oynarsın. PSN ile giriş yap’tan sonra açılan beyaz redirect sayfasında adres çubuğundaki bağlantının tamamını kopyala. Uygulamada Yönlendirme URL’si alanına yapıştırıp PSN hesabını doğrula’ya bas. Kod geçersiz veya kullanılmışsa giriş işlemini yeniden başlatıp yeni adresi kopyala.":
      "استخدم حساب PSN منفصلًا جديدًا أو غير مستخدم لـRemote Play وأضفه كمستخدم على PS5؛ وستلعب بحسابك الرئيسي. بعد «تسجيل الدخول باستخدام PSN»، انسخ الرابط بالكامل من شريط العنوان في صفحة redirect البيضاء. ألصقه في حقل «رابط إعادة التوجيه» داخل التطبيق، ثم اضغط «التحقّق من حساب PSN». إذا كان الرمز غير صالح أو مستخدمًا، فابدأ تسجيل الدخول مجددًا وانسخ الرابط الجديد.",
  "Çeviri için internet gerekli mi?": "هل تتطلب الترجمة اتصالًا بالإنترنت؟",
  "OCR ve indirilmiş modellerle metin çevirisi telefonda yapılır; metin çevirisi için buluta gönderilmez. Ancak ilk kurulum, Google/PSN girişi, dil veya Oyun Kütüphanesi üzerinden çeviri indirme, erişim ve satın alma doğrulamaları için internet gerekir. Kullanım sırasında telefon, PS5 ve TV’nin aynı yerel ağdaki bağlantısı sürmelidir; uygulamanın bütünü için tamamen çevrimdışı çalışma garantisi yoktur.":
      "تُجرى قراءة OCR والترجمة بالنماذج المنزّلة على الهاتف، ولا يُرسل النص إلى السحابة للترجمة بهذه النماذج. لكن يلزم الإنترنت للإعداد الأول، وتسجيل الدخول إلى Google وPSN، وتنزيل اللغات أو ترجمات مكتبة الألعاب، والتحقّق من صلاحية الوصول والمشتريات. يجب أن يبقى الهاتف وPS5 والتلفزيون متصلين بالشبكة المحلية نفسها أثناء الاستخدام؛ ولا يوجد ضمان لعمل التطبيق بالكامل دون إنترنت.",
  "Telefonu, PS5’i ve TV’yi aynı ağa bağla":
      "توصيل الهاتف وPS5 والتلفزيون بالشبكة نفسها",
  "Telefon, PS5 ve Android TV aynı yönlendiricinin yerel ağına bağlı olmalı. PS5 veya TV Ethernet, telefon Wi-Fi kullanabilir; misafir ağı ya da cihazları birbirinden ayıran ağ ayarları bağlantıyı engelleyebilir.":
      "يجب توصيل الهاتف وPS5 وAndroid TV بالشبكة المحلية للموجّه نفسه. يمكن توصيل PS5 أو التلفزيون عبر Ethernet والهاتف عبر Wi-Fi؛ وقد تمنع شبكة الضيوف أو إعدادات عزل الأجهزة الاتصال.",
  "İlk kurulumda PS5 ve TV açık olsun. Google/PSN girişi, dil paketleri ve gerekiyorsa Oyun Kütüphanesi üzerinden çeviri indirme işlemleri için internet bağlantını hazır tut.":
      "أبقِ PS5 والتلفزيون قيد التشغيل أثناء الإعداد الأول. جهّز اتصال الإنترنت لتسجيل الدخول إلى Google وPSN وتنزيل حزم اللغات وترجمات مكتبة الألعاب عند الحاجة.",
  "PS5’te Remote Play’i etkinleştir": "تفعيل Remote Play على PS5",
  "PS5’te Ayarlar → Sistem → Remote Play bölümünü aç ve Remote Play’i Etkinleştir seçeneğini aç.":
      "افتح الإعدادات ← النظام ← اللعب عن بُعد على PS5، وفعّل «تمكين اللعب عن بُعد».",
  "Dinlenme modundaki konsola bağlanmak istiyorsan Ayarlar → Sistem → Güç Tasarrufu → Dinlenme Modunda Kullanılabilen Özellikler bölümünde İnternete Bağlı Kal ve PS5’in Ağdan Açılmasını Etkinleştir seçeneklerini aç. İlk kayıt için konsolu açık tut.":
      "إذا أردت الاتصال بالجهاز أثناء وضع السكون، فافتح الإعدادات ← النظام ← حفظ الطاقة ← الميزات المتاحة في وضع السكون، وفعّل «البقاء على اتصال بالإنترنت» و«تمكين تشغيل جهاز PS5 من الشبكة». أبقِ الجهاز قيد التشغيل أثناء التسجيل الأول.",
  "PSN hesabını doğrula ve PS5’i kaydet": "التحقّق من حساب PSN وتسجيل PS5",
  "Önemli: Remote Play için yeni veya kullanmadığın ayrı bir PSN hesabı kullan ve bu hesabı PS5’e kullanıcı olarak ekle. Oyunu kendi ana PSN hesabında oynayacaksın.":
      "مهم: استخدم حساب PSN منفصلًا جديدًا أو غير مستخدم لـRemote Play وأضفه كمستخدم على PS5. ستلعب بحساب PSN الرئيسي الخاص بك.",
  "Ana sayfadaki PlayStation 5 kartında PS5’i kur’a dokun, ardından PSN ile giriş yap’ı aç. Girişten sonra beyaz redirect sayfasındayken tarayıcının adres çubuğundaki bağlantının tamamını kopyala. Uygulamadaki Yönlendirme URL’si alanına yapıştır ve PSN hesabını doğrula’ya bas.":
      "اضغط «إعداد PS5» في بطاقة PlayStation 5 على الرئيسية، ثم افتح «تسجيل الدخول باستخدام PSN». بعد تسجيل الدخول، انسخ الرابط بالكامل من شريط عنوان المتصفح وأنت في صفحة redirect البيضاء. ألصقه في حقل «رابط إعادة التوجيه» داخل التطبيق، ثم اضغط «التحقّق من حساب PSN».",
  "Sonraki adım: PS5 konsolunu bağla’ya geç. Konsolda Ayarlar → Sistem → Remote Play → Cihazı Bağla’yı aç. Konsolu ağda bul veya IP adresini elle gir; PS5’in gösterdiği güncel 8 haneli PIN’i yazıp PS5 bağlantısını başlat’a dokun.":
      "تابع إلى «الخطوة التالية: ربط جهاز PS5». على الجهاز، افتح الإعدادات ← النظام ← اللعب عن بُعد ← إقران الجهاز. ابحث عن الجهاز على الشبكة أو أدخل عنوان IP يدويًا؛ ثم أدخل رمز PIN الحالي المكوّن من 8 أرقام الظاهر على PS5 واضغط «بدء اتصال PS5».",
  "IP adresini PS5’te Ayarlar → Ağ → Bağlantı Durumu bölümünde bulabilirsin. Kayıt tamamlandığında ana sayfadaki PS5 kartında Hazır görünür. PS5’in kayıt PIN’i, TV’nin 6 haneli eşleştirme kodundan farklıdır.":
      "ستجد عنوان IP على PS5 ضمن الإعدادات ← الشبكة ← حالة الاتصال. عند اكتمال التسجيل، تظهر حالة «جاهز» في بطاقة PS5 على الرئيسية. يختلف رمز PIN لتسجيل PS5 عن رمز اقتران التلفزيون المكوّن من 6 أرقام.",
  "Android TV uygulamasını hazırla": "تجهيز تطبيق Android TV",
  "TV uygulamasında İzin ver’e bas, İzin ayarlarını aç ile Android’in izin ekranına geç ve diğer uygulamaların üzerinde gösterime izin ver. Uygulamaya dönünce altyazı katmanı hazırlanır. İzin zaten açıksa düğmenin adı Altyazıyı aç / yenile olur.":
      "اضغط «منح الإذن» في تطبيق التلفزيون، ثم «فتح إعدادات الإذن» للانتقال إلى شاشة أذونات Android والسماح بالظهور فوق التطبيقات الأخرى. تُجهَّز طبقة الترجمة عند العودة إلى التطبيق. إذا كان الإذن ممنوحًا بالفعل، يظهر الزر باسم «تشغيل الترجمة / تحديثها».",
  "Altyazı gösterimi duraklatılmışsa Altyazıları sürdür’e bas. Eşleştirmeden sonra TV uygulaması ekranda açık kalmak zorunda değildir; TV açık ve ağa bağlıyken alıcı arka planda çalışabilir. TV yeniden başladıktan veya uygulama zorla durdurulduktan sonra bağlantı kurulmazsa uygulamayı yeniden aç.":
      "إذا كان عرض الترجمة متوقفًا مؤقتًا، فاضغط «استئناف الترجمة». بعد الاقتران، لا يلزم إبقاء تطبيق التلفزيون ظاهرًا؛ إذ يمكن للمستقبِل العمل في الخلفية ما دام التلفزيون قيد التشغيل ومتصلًا بالشبكة. إذا تعذّر الاتصال بعد إعادة تشغيل التلفزيون أو إيقاف التطبيق إجباريًا، فأعد فتح التطبيق.",
  "Telefonu TV ile eşleştir": "إقران الهاتف بالتلفزيون",
  "Ana sayfadaki Android TV kartında TV’yi eşleştir’e bas. TV uygulaması açıkken TV’yi ağda bul’u kullan veya TV ekranındaki adresi elle gir. Birden fazla sonuç varsa ekrandaki adresle aynı olanı seç.":
      "اضغط «إقران التلفزيون» في بطاقة Android TV على الرئيسية. أثناء فتح تطبيق التلفزيون، استخدم «البحث عن التلفزيون على الشبكة» أو أدخل العنوان الظاهر على شاشته يدويًا. إذا ظهرت عدة نتائج، فاختر ما يطابق العنوان على الشاشة.",
  "TV’deki güncel 6 haneli kodu girip Eşleştir ve bağlan’a dokun. TV kimliğini doğrula ekranı açılırsa telefondaki değerin TV’deki Güvenli bağlantı kimliği ile tamamının eşleştiğini kontrol ederek onayla.":
      "أدخل الرمز الحالي المكوّن من 6 أرقام على التلفزيون واضغط «اقتران واتصال». إذا ظهرت شاشة «التحقّق من هوية التلفزيون»، فأكّد بعد التأكّد من تطابق القيمة على الهاتف بالكامل مع «هوية الاتصال الآمن» على التلفزيون.",
  "Telefonun Android TV kartında Bağlı durumunu gör. Eşleştirme kayıtlı • TV bağlı değil yazması çeviri için yeterli değildir. Sonraki kullanımda kayıtlı eşleştirme ile yeniden bağlantı denenir; bağlanmazsa TV uygulamasını açıp tekrar dene.":
      "تأكّد من ظهور حالة «متصل» في بطاقة Android TV على الهاتف. ظهور «الاقتران محفوظ • التلفزيون غير متصل» لا يكفي لبدء الترجمة. في الاستخدام التالي، يحاول التطبيق الاتصال بالاقتران المحفوظ؛ وإذا لم يتصل، فافتح تطبيق التلفزيون وحاول مجددًا.",
  "Çeviri modelini ve dil paketlerini hazırla":
      "تجهيز نموذج الترجمة وحزم اللغات",
  "Ana sayfada Model A veya Model B’yi seç. Model A daha yavaş çalışır ancak daha doğru ve kaliteli çeviriler sunar. Model B daha hızlıdır; çevirileri zaman zaman daha az isabetli olabilir.":
      "اختر Model A أو Model B من الرئيسية. يعمل Model A ببطء أكبر، لكنه يقدّم ترجمات أدق وأفضل جودة. أما Model B فأسرع، وقد تكون ترجماته أقل دقة أحيانًا.",
  "Dilleri görüntüle ve indir’i aç. Model A için İngilizceden çevireceğin hedef dil paketini, Model B için kaynak ve hedef dil paketlerini indir. Ardından dil seçimlerini yap; örneğin English → Türkçe. Her modelin paketleri ayrıdır.":
      "افتح «عرض اللغات وتنزيلها». نزّل حزمة اللغة المستهدفة للترجمة من الإنجليزية في Model A، وحزمتَي المصدر والهدف في Model B. ثم حدّد اللغات، مثل الترجمة من الإنجليزية إلى العربية. لكل نموذج حزمه المنفصلة.",
  "Daha hızlı ve kaliteli bir çeviri deneyimi için Altyazı sekmesindeki Oyun Kütüphanesi bölümünden oyununu seç. Hazır oyun çevirileri, hikâyeyi daha doğal ve akıcı biçimde takip etmene yardımcı olur.":
      "للحصول على ترجمة أسرع وأفضل، اختر لعبتك من «مكتبة الألعاب» في تبويب «الترجمة». تساعدك الترجمات الجاهزة للألعاب على متابعة القصة بأسلوب أكثر سلاسة وطبيعية.",
  "OCR ve altyazı alanlarını ayarla": "ضبط مناطق OCR والترجمة",
  "Altyazı sekmesinde Altyazı görünümü’nü aç. Canlı oyun görüntüsünü görmek için PS5 kartından Remote Play’i açabilirsin. Sarı OCR alanını oyundaki metni tam kapsayacak şekilde yerleştir; yalnızca bu alanlardaki metin okunur.":
      "افتح «مظهر الترجمة» في تبويب «الترجمة». يمكنك فتح Remote Play من بطاقة PS5 لعرض صورة اللعبة المباشرة. ضع منطقة OCR الصفراء بحيث تحتوي نص اللعبة بالكامل؛ إذ تُقرأ النصوص داخل هذه المناطق فقط.",
  "Çevrilmiş metnin yerini, boyutunu ve görünümünü altyazı ayarlarından düzenle. Sarı OCR alanı ile turkuaz altyazı alanı birbirinden bağımsızdır; birden fazla alan ekleyebilir, alanları sürükleyip boyutlandırabilirsin.":
      "عدّل موضع النص المترجم وحجمه ومظهره من إعدادات الترجمة. منطقة OCR الصفراء ومنطقة الترجمة الفيروزية مستقلتان؛ ويمكنك إضافة عدة مناطق وسحبها وتغيير أحجامها.",
  "Konuşma altyazıları için diyalog filtresini deneyebilirsin; görev ve menü metinlerinde kapalı tut. Ön işleme ve OCR ölçeği her alan için ayrı ayarlanır. Değişiklikler otomatik kaydedilir; Kaydet ile de saklayabilirsin.":
      "يمكنك تجربة مرشّح الحوار لترجمة الحوارات، وإبقاؤه معطّلًا للمهام والقوائم. تُضبط المعالجة المسبقة وتكبير OCR لكل منطقة بشكل مستقل. تُحفظ التغييرات تلقائيًا؛ ويمكنك أيضًا استخدام «حفظ».",
  "Çeviriyi başlat ve PS5’te oyna": "بدء الترجمة واللعب على PS5",
  "Ana sayfada PS5 kaydı hazır, Android TV Bağlı ve dil paketleri indirilmişken Çeviriyi Başlat’a dokun. Google hesabınla giriş yapıp kullanılabilir deneme süresine veya Premium erişime sahip olmalısın.":
      "اضغط «بدء الترجمة» على الرئيسية عندما يكون تسجيل PS5 جاهزًا وAndroid TV متصلًا وحزم اللغات منزّلة. يجب تسجيل الدخول بحساب Google وامتلاك وقت متبقٍ للتجربة أو وصول إلى Premium.",
  "Remote Play ve çeviri hazır olunca uygulama ana sayfaya döner. İlk kullanımda Alanları ayarla önerisi çıkarsa oyundaki metne göre OCR ve altyazı alanlarını düzenle. Sonradan Altyazı → Altyazı görünümü’nden aynı ayarlara dönebilirsin.":
      "عندما يصبح Remote Play والترجمة جاهزين، يعود التطبيق إلى الرئيسية. إذا ظهر اقتراح «ضبط المناطق» في الاستخدام الأول، فاضبط مناطق OCR والترجمة بحسب نصوص اللعبة. يمكنك العودة إلى الإعدادات نفسها لاحقًا من «الترجمة ← مظهر الترجمة».",
  "Oyunu ana PSN hesabında oyna ve TV’yi PS5’in HDMI girişine al. TV uygulamasını ekranda açık tutman gerekmez. Telefon arka plandayken veya ekranı kapalıyken çeviri sürebilir; kesinti olursa bağlantıları ve telefonun pil kısıtlamalarını kontrol et.":
      "العب بحساب PSN الرئيسي وبدّل التلفزيون إلى مدخل HDMI الخاص بـPS5. لا يلزم إبقاء تطبيق التلفزيون ظاهرًا. يمكن أن تستمر الترجمة والهاتف في الخلفية أو شاشته مغلقة؛ وإذا حدث انقطاع، فتحقّق من الاتصالات وقيود البطارية على الهاتف.",
  "Bitirirken telefonda Çeviriyi Durdur’a veya çeviri bildirimindeki Durdur’a bas. Remote Play ve çeviri durur; PS5 kaydı, TV eşleştirmesi ve ayarların korunur.":
      "عند الانتهاء، اضغط «إيقاف الترجمة» على الهاتف أو «إيقاف» في إشعار الترجمة. سيتوقف Remote Play والترجمة؛ وسيُحتفَظ بتسجيل PS5 واقتران التلفزيون وإعداداتك.",
  "TV’de Play Store’dan **Oyun Çevirmeni TV**’yi kur. TV İngilizceyse **Console Game Translator TV** ara. En güncel sürüm her zaman sitede.":
      "ثبّت **Console Game Translator TV** من Play Store على التلفزيون. يتوفر أحدث إصدار دائمًا على موقعنا.",
  "TV ve telefon aynı Wi-Fi ağında olsun; TV uygulamasını aç.":
      "وصّل التلفزيون والهاتف بشبكة Wi-Fi نفسها، وافتح تطبيق التلفزيون.",
  "TV’yi ağda bul’a dokun ya da TV ekranındaki adresi yaz.":
      "اضغط «البحث عن التلفزيون على الشبكة» أو أدخل العنوان الظاهر على شاشة التلفزيون.",
  "TV ekranındaki 6 haneli kodu girip eşleştir.":
      "أدخل الرمز المكوّن من 6 أرقام على شاشة التلفزيون وأكمل الاقتران.",
  "Google Play’de aç": "فتح في Google Play",
  "Siteden indir": "تنزيل من الموقع",
  "Seçili oyunun çeviri paketi {0}, çeviri dili ise {1}. Oyunun kendi çevirileri kullanılmayacak; oyunu {1} paketiyle yeniden seç ya da çeviri dilini değiştir.":
      "حزمة ترجمة اللعبة المحددة هي {0}، بينما لغة الترجمة هي {1}. لن تُستخدم ترجمات اللعبة نفسها؛ اختر اللعبة مجددًا بحزمة {1} أو غيّر لغة الترجمة.",
  "Oyun paketinin dili farklı":
      "لغة حزمة اللعبة مختلفة",
};
