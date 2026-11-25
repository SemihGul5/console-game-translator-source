// Thai interface messages, keyed by Turkish source text.
const thaiMessages = <String, String>{
  "Kişiselleştir": "ปรับแต่ง",
  "Uygulama dili Model B’nin hedef dilini otomatik ayarlar.":
      "ภาษาของแอปจะกำหนดภาษาปลายทางของ Model B โดยอัตโนมัติ",
  "Temizle": "ล้าง",
  "Yenile": "รีเฟรช",
  "1,5× · dengeli": "1.5× · สมดุล",
  "Bu oyunun çeviri paketi telefonun belleğine sığmadı. Diğer uygulamaları kapatıp tekrar dene.":
      "หน่วยความจำของโทรศัพท์ไม่เพียงพอสำหรับแพ็กคำแปลของเกมนี้ ปิดแอปอื่นแล้วลองอีกครั้ง",
  "Ücretsiz denemen hazır. Remote Play bağlantısıyla başlar.":
      "การทดลองใช้ฟรีของคุณพร้อมแล้ว จะเริ่มเมื่อเชื่อมต่อ Remote Play",
  "Geliştirmeye katkıda bulun": "ช่วยพัฒนาแอป",
  "Geliştiriciye gönder": "ส่งให้นักพัฒนา",
  "İstersen son çevirilerinden bir dosyayı geliştiriciyle paylaşabilirsin. E-posta için en fazla 5.000 kayıt ve 5 MiB hazırlanır.":
      "คุณสามารถเลือกแชร์ไฟล์คำแปลล่าสุดกับนักพัฒนาได้ โดยจะเตรียมข้อมูลไม่เกิน 5,000 รายการและขนาดไม่เกิน 5 MiB สำหรับอีเมล",
  "Dosyada yalnızca çeviri kayıtları bulunur; API anahtarların ve uygulama hesabı bilgilerin eklenmez. Paylaştığın kayıtlar uygulamayı geliştirmek için kullanılır.":
      "ไฟล์มีเฉพาะบันทึกคำแปล ไม่มีคีย์ API หรือข้อมูลบัญชีแอป บันทึกที่แชร์จะนำไปใช้พัฒนาแอป",
  "{0} kayıt • {1} MiB\nAlıcı: {2}": "{0} รายการ • {1} MiB\nถึง: {2}",
  "Dosyayı açılan e-postanın ekinden inceleyebilirsin. Gönderimi e-posta uygulamasında sen tamamlarsın.":
      "คุณสามารถตรวจสอบไฟล์แนบในอีเมลฉบับร่าง แล้วส่งด้วยตนเองจากแอปอีเมล",
  "E-posta taslağını aç": "เปิดอีเมลฉบับร่าง",
  "E-posta uygulaması seç": "เลือกแอปอีเมล",
  "{0} - Çeviri kaydı katkısı": "{0} - ร่วมแชร์บันทึกคำแปล",
  "Çeviri kayıtlarını uygulamanın geliştirilmesi amacıyla isteğe bağlı olarak paylaşıyorum.\n\nÇeviri dosyası ektedir.":
      "ฉันสมัครใจแชร์บันทึกคำแปลเพื่อช่วยพัฒนาแอป\n\nแนบไฟล์คำแปลมาด้วยแล้ว",
  "Paylaşılacak çeviri kaydı yok.": "ไม่มีบันทึกคำแปลที่จะแชร์",
  "Gönderimi e-posta uygulamasından tamamlayabilirsin.":
      "คุณสามารถส่งอีเมลให้เสร็จสิ้นจากแอปอีเมลได้",
  "E-posta taslağı açılamadı. Önbelleği dışarı aktararak bize gönderebilirsin.":
      "เปิดอีเมลฉบับร่างไม่ได้ คุณสามารถส่งออกแคชแล้วส่งให้เราได้",
  "E-posta uygulaması bulunamadı. Önbelleği dışarı aktararak abrebostudio@gmail.com adresine gönderebilirsin.":
      "ไม่พบแอปอีเมล คุณสามารถส่งออกแคชแล้วส่งไปที่ abrebostudio@gmail.com",
  "Gelişmiş": "ขั้นสูง",
  "Çeviri önbelleği": "แคชคำแปล",
  "Saklama sınırları, yedekleme ve temizleme":
      "ขีดจำกัดการเก็บข้อมูล สำรองข้อมูล และล้างข้อมูล",
  "Gemini ve DeepL çevirilerini cihazında sakla; tekrar eden altyazılarda API isteğini azalt.":
      "เก็บคำแปลจาก Gemini และ DeepL ไว้บนอุปกรณ์ เพื่อลดคำขอ API เมื่อพบข้อความเดิมซ้ำ",
  "Kayıtlı çeviriler": "คำแปลที่บันทึกไว้",
  "{0} çeviri • {1} MiB": "{0} คำแปล • {1} MiB",
  "Her sağlayıcı için saklama sınırları":
      "ขีดจำกัดการเก็บข้อมูลต่อผู้ให้บริการ",
  "Saklama süresi": "ระยะเวลาเก็บข้อมูล",
  "En fazla çeviri": "จำนวนคำแปลสูงสุด",
  "En fazla alan": "พื้นที่สูงสุด",
  "{0} gün": "{0} วัน",
  "{0} çeviri": "{0} คำแปล",
  "{0} MiB": "{0} MiB",
  "Gün sınırı kayıt tarihinden hesaplanır. Sınırları azaltmak eski kayıtları kaldırabilir; okumak saklama süresini uzatmaz.":
      "นับอายุจากวันที่บันทึกคำแปล การลดขีดจำกัดอาจลบรายการเก่า การอ่านรายการจะไม่ต่ออายุการเก็บข้อมูล",
  "Sınırları kaydet": "บันทึกขีดจำกัด",
  "Varsayılana dön": "คืนค่าเริ่มต้น",
  "Yedekle ve geri yükle": "สำรองและกู้คืนข้อมูล",
  "Dosya altyazı metinlerini içerir; API anahtarlarını ve hesap bilgilerini içermez. İçeri aktarma mevcut kayıtları birleştirir; ayarlarını değiştirmez. Model A/B oturum önbelleği yedeğe dahil değildir.":
      "ไฟล์มีข้อความคำแปล แต่ไม่มีคีย์ API หรือข้อมูลบัญชี การนำเข้าจะรวมรายการที่บันทึกไว้โดยไม่เปลี่ยนการตั้งค่า ไม่รวมแคชชั่วคราวของเซสชัน Model A/B",
  "Dışarı aktar": "ส่งออก",
  "İçeri aktar": "นำเข้า",
  "Önbelleği içeri aktar": "นำเข้าแคชคำแปล",
  "Geçerli kayıt: {0}\nSüresi dolmuş veya ileri tarihli: {1}\nDosya içindeki tekrarlar: {2}\n\nMevcut kayıtlarla birleştirilir; aynı çevirinin en yenisi korunur. Seçtiğin saklama sınırları uygulanır.":
      "รายการที่ใช้ได้: {0}\nหมดอายุหรือลงวันที่ในอนาคต: {1}\nรายการซ้ำในไฟล์: {2}\n\nระบบจะรวมกับแคชเดิมและเก็บคำแปลฉบับล่าสุด โดยยังใช้ขีดจำกัดการเก็บข้อมูลที่คุณเลือก",
  "{0} önbelleği temizlensin mi?": "ล้างแคช {0} หรือไม่?",
  "Kaydedilmiş çeviriler kaldırılır. Aynı metinler için yeniden çeviri isteği gerekebilir.":
      "คำแปลที่บันทึกไว้จะถูกลบ การแปลข้อความเดิมอีกครั้งอาจต้องส่งคำขอ API ใหม่",
  "Önbelleği temizle": "ล้างแคช",
  "Önbellek sınırları kaydedildi.": "บันทึกขีดจำกัดแคชแล้ว",
  "Seçilen önbellek temizlendi.": "ล้างแคชที่เลือกแล้ว",
  "Önbellek dosyası kaydedildi.": "บันทึกไฟล์สำรองแคชแล้ว",
  "Önbellek içeri alındı.": "นำเข้าแคชแล้ว",
  "Önbellek yönetimi bu platformda kullanılamıyor.":
      "ไม่รองรับการจัดการแคชบนแพลตฟอร์มนี้",
  "Önbellek bilgileri alınamadı. Tekrar dene.":
      "โหลดข้อมูลแคชไม่ได้ ลองอีกครั้ง",
  "Önbelleği değiştirmeden önce çeviriyi durdur.": "หยุดการแปลก่อนแก้ไขแคช",
  "Önbellek işleminin tamamlanmasını bekle.":
      "รอให้การดำเนินการกับแคชเสร็จสิ้น",
  "Önbellek işlemi tamamlanamadı. Dosyayı ve kullanılabilir alanı kontrol et.":
      "ดำเนินการกับแคชไม่สำเร็จ ตรวจสอบไฟล์และพื้นที่ว่าง",
  "Önce açık dosya seçimini tamamla.": "เลือกไฟล์ที่เปิดอยู่ให้เสร็จก่อน",
  "Dosya seçimi için uygulamayı aç.": "เปิดแอปเพื่อเลือกไฟล์",
  "Bu cihazda dosya seçici açılamadı.": "เปิดตัวเลือกไฟล์บนอุปกรณ์นี้ไม่ได้",
  "En fazla 5 anahtar ekleyebilirsin. Bir anahtar sınıra ulaşırsa hazır diğer anahtara geçilir; hepsi bekliyorsa önbellek ve yüklü Model A/B kullanılır.":
      "เพิ่มคีย์ได้สูงสุด 5 คีย์ หากคีย์หนึ่งถึงขีดจำกัด ระบบจะใช้คีย์อื่นที่พร้อม เมื่อทุกคีย์อยู่ระหว่างรอ จะใช้คำแปลในแคชและ Model A/B ที่ติดตั้งไว้",
  "Aynı Google projesindeki anahtarlar ortak kotayı kullanır. Anahtar eklemek proje kotasını artırmaz; diğer anahtarın da kullanılabilir kotası olmalıdır.":
      "คีย์ในโปรเจ็กต์ Google เดียวกันใช้โควตาร่วมกัน การเพิ่มคีย์ไม่ได้เพิ่มโควตาของโปรเจ็กต์ คีย์อื่นต้องมีโควตาเหลือด้วย",
  "Anahtar {0}": "คีย์ {0}",
  "Kullanılıyor": "กำลังใช้งาน",
  "Bu anahtarı sil": "ลบคีย์นี้",
  "Tüm anahtarları sil": "ลบคีย์ทั้งหมด",
  "Test et ve ekle": "ทดสอบและเพิ่ม",
  "Bu Gemini anahtarı zaten kayıtlı.": "บันทึกคีย์ Gemini นี้ไว้แล้ว",
  "En fazla 5 Gemini anahtarı kaydedebilirsin.":
      "บันทึกคีย์ Gemini ได้สูงสุด 5 คีย์",
  "Gemini beklerken önce önbellek, ardından bu dil çifti için yüklü Model A veya Model B kullanılır. İkisi de hazırsa Model A seçilir. Yerel paketleri ilgili modelin dil paketleri bölümünden indirebilirsin.":
      "ระหว่างรอ Gemini ระบบจะใช้คำแปลในแคชก่อน จากนั้นใช้ Model A หรือ Model B ที่ติดตั้งไว้สำหรับคู่ภาษานี้ หากพร้อมทั้งคู่จะเลือก Model A ดาวน์โหลดแพ็กภายในเครื่องได้จากส่วนแพ็กภาษาของแต่ละโมเดล",
  "Model A ile yerel çeviri kullanılıyor.": "กำลังแปลในเครื่องด้วย Model A",
  "Model B ile yerel çeviri kullanılıyor.": "กำลังแปลในเครื่องด้วย Model B",
  "Bu dil çifti için yerel paket yüklü değil. Model A veya B dil paketini indir. Önbellekteki çeviriler kullanılabilir.":
      "ยังไม่ได้ติดตั้งแพ็กภายในเครื่องสำหรับคู่ภาษานี้ ดาวน์โหลดแพ็กภาษาของ Model A หรือ B ยังใช้คำแปลในแคชได้",
  "Yerel paket açılamadı. Model A veya B dil paketini yeniden indir. Önbellekteki çeviriler kullanılabilir.":
      "เปิดแพ็กภายในเครื่องไม่ได้ ดาวน์โหลดแพ็กภาษาของ Model A หรือ B ใหม่ ยังใช้คำแปลในแคชได้",
  "Yerel paketler kontrol ediliyor.": "กำลังตรวจสอบแพ็กภาษาภายในเครื่อง",
  "Gemini bekliyor. Model A ile yerel çeviri kullanılıyor.":
      "Gemini กำลังรอ กำลังแปลในเครื่องด้วย Model A",
  "Gemini bekliyor. Model B ile yerel çeviri kullanılıyor.":
      "Gemini กำลังรอ กำลังแปลในเครื่องด้วย Model B",
  "Gemini bekliyor. Bu dil çifti için yerel paket yüklü değil. Model A veya B dil paketini indir. Önbellekteki çeviriler kullanılabilir.":
      "Gemini กำลังรอ ยังไม่ได้ติดตั้งแพ็กสำหรับคู่ภาษานี้ ดาวน์โหลดแพ็กภาษาของ Model A หรือ B ยังใช้คำแปลในแคชได้",
  "Gemini bekliyor. Yerel paket açılamadı. Model A veya B dil paketini yeniden indir. Önbellekteki çeviriler kullanılabilir.":
      "Gemini กำลังรอ เปิดแพ็กภายในเครื่องไม่ได้ ดาวน์โหลดแพ็กภาษาของ Model A หรือ B ใหม่ ยังใช้คำแปลในแคชได้",
  "Gemini günlük kotası doldu. Yerel paketler kontrol ediliyor.":
      "โควตารายวันของ Gemini หมดแล้ว กำลังตรวจสอบแพ็กภาษาภายในเครื่อง",
  "Hemen abone olun": "สมัครสมาชิกเลย",
  "İsterseniz abone olmadan {0} dakika ücretsiz deneyebilirsiniz.":
      "คุณสามารถทดลองใช้ฟรี {0} นาทีโดยไม่ต้องสมัครสมาชิก",
  "Paketleri ve fiyatları görün": "ดูแพ็กเกจและราคา",
  "Premium paketlerini ve fiyatlarını inceleyebilirsiniz.":
      "ดูรายละเอียดแพ็กเกจและราคา Premium",
  "Ücretsiz denemeniz devam ediyor. Kalan süre: {0}.":
      "กำลังอยู่ในช่วงทดลองใช้ฟรี เวลาที่เหลือ: {0}",
  "Ücretsiz denemeniz sona erdi. Devam etmek için bir paket seçebilirsiniz.":
      "การทดลองใช้ฟรีสิ้นสุดแล้ว เลือกแพ็กเกจเพื่อใช้งานต่อ",
  "Abone olmadan deneyin": "ทดลองโดยไม่สมัครสมาชิก",
  "Google hesabınızla {0} dakika ücretsiz deneyebilirsiniz.":
      "ทดลองใช้ฟรี {0} นาทีด้วยบัญชี Google ของคุณ",
  "Ücretsiz deneme süresi kontrol ediliyor.": "กำลังตรวจสอบระยะเวลาทดลองใช้",
  "Gemini hazır. Güncel altyazı bekleniyor.":
      "Gemini พร้อมแล้ว กำลังรอข้อความปัจจุบัน",
  "Gemini bekliyor. {0} sn sonra güncel altyazıyla yeniden denenecek.":
      "Gemini กำลังรอ จะลองแปลข้อความปัจจุบันอีกครั้งใน {0} วินาที",
  "Gemini (ücretsiz katman)": "Gemini (ระดับฟรี)",
  "Gemini 3.5 Flash-Lite": "Gemini 3.5 Flash-Lite",
  "Ücretsiz Gemini API anahtarı al": "รับคีย์ Gemini API ฟรี",
  "Google AI Studio kullanım ve limitleri":
      "การใช้งานและขีดจำกัดของ Google AI Studio",
  "Gemini API anahtarı": "คีย์ Gemini API",
  "Gemini API anahtarı gerekli": "ต้องใช้คีย์ Gemini API",
  "Gemini bölümüne anahtarını girip test et ve kaydet.":
      "ป้อนคีย์ในส่วน Gemini แล้วทดสอบและบันทึก",
  "Gemini internet ve kendi API anahtarını gerektirir. Altyazı metinleri Google’a gönderilir. Ücretsiz katmanda bu içerikler Google ürünlerini geliştirmek için kullanılabilir.":
      "Gemini ต้องใช้อินเทอร์เน็ตและคีย์ API ของคุณเอง ข้อความคำแปลจะถูกส่งไปยัง Google ในระดับฟรี เนื้อหานี้อาจถูกนำไปใช้ปรับปรุงผลิตภัณฑ์ของ Google",
  "Google AI Studio’da Google hesabınla giriş yap, bir proje ve API anahtarı oluştur. Ücretsiz kullanım için projen Free Tier olmalı; faturalandırmayı etkinleştirme. Anahtarı aşağıya yapıştır.":
      "ลงชื่อเข้าใช้ Google AI Studio ด้วยบัญชี Google แล้วสร้างโปรเจ็กต์และคีย์ API หากต้องการใช้ฟรี โปรเจ็กต์ต้องอยู่ในระดับ Free Tier และไม่เปิดใช้การเรียกเก็บเงิน วางคีย์ด้านล่าง",
  "Ücretsiz kullanım sınırlıdır; istek ve token kotaları projene göre değişir. Ücretli bir proje anahtarı kullanırsan Google ücretlendirebilir. Bağlantı testi kısa bir çeviri isteği gönderir.":
      "การใช้งานฟรีมีขีดจำกัด โควตาคำขอและโทเคนขึ้นอยู่กับโปรเจ็กต์ Google อาจเรียกเก็บเงินหากใช้คีย์จากโปรเจ็กต์แบบชำระเงิน การทดสอบการเชื่อมต่อจะส่งคำขอแปลสั้น ๆ หนึ่งครั้ง",
  "Anahtar yalnızca cihazda şifreli saklanır.":
      "คีย์จะถูกเข้ารหัสและเก็บไว้บนอุปกรณ์นี้เท่านั้น",
  "Geçerli bir Gemini API anahtarı gir.": "ป้อนคีย์ Gemini API ที่ถูกต้อง",
  "Gemini anahtarı silindi.": "ลบคีย์ Gemini แล้ว",
  "Gemini bağlantısı başarılı. Çeviri için hazır.":
      "เชื่อมต่อ Gemini สำเร็จ พร้อมแปลแล้ว",
  "Gemini işlemi tamamlanamadı. Tekrar dene.":
      "ดำเนินการกับ Gemini ไม่สำเร็จ ลองอีกครั้ง",
  "Gemini bu platformda kullanılamıyor.": "ไม่รองรับ Gemini บนแพลตฟอร์มนี้",
  "Gemini için metin ve dil seçimini kontrol et.":
      "ตรวจสอบข้อความและภาษาที่เลือกสำหรับ Gemini",
  "Gemini bu altyazı için çeviri döndürmedi.":
      "Gemini ไม่ได้ส่งคำแปลสำหรับข้อความนี้",
  "Gemini bu altyazı için tam bir çeviri döndürmedi.":
      "Gemini ส่งคำแปลสำหรับข้อความนี้มาไม่ครบ",
  "Gemini çeviri yanıtı geçersiz.": "คำตอบการแปลจาก Gemini ไม่ถูกต้อง",
  "Gemini bağlantısı kurulamadı. İnternet bağlantını kontrol et.":
      "เชื่อมต่อ Gemini ไม่ได้ ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต",
  "Gemini günlük kotası doldu. Google AI Studio kullanım ekranını kontrol et.":
      "โควตารายวันของ Gemini หมดแล้ว ตรวจสอบการใช้งานใน Google AI Studio",
  "Gemini istek sınırına ulaşıldı. Biraz bekle veya Google AI Studio limitlerini kontrol et.":
      "ถึงขีดจำกัดคำขอ Gemini แล้ว รอสักครู่หรือตรวจสอบขีดจำกัดใน Google AI Studio",
  "Gemini API anahtarı kabul edilmedi. Anahtarı ve proje erişimini kontrol et.":
      "Gemini ไม่ยอมรับคีย์ API ตรวจสอบคีย์และสิทธิ์เข้าถึงโปรเจ็กต์",
  "Gemini isteği kabul edilmedi. API anahtarını, bölge uygunluğunu ve proje ayarlarını kontrol et.":
      "Gemini ไม่ยอมรับคำขอ ตรวจสอบคีย์ API การให้บริการในภูมิภาค และการตั้งค่าโปรเจ็กต์",
  "Gemini modeli bu projede kullanılamıyor. Google AI Studio erişimini kontrol et.":
      "ใช้โมเดล Gemini กับโปรเจ็กต์นี้ไม่ได้ ตรวจสอบสิทธิ์เข้าถึงใน Google AI Studio",
  "Gemini şu anda yanıt veremiyor. Biraz sonra tekrar dene.":
      "Gemini ยังไม่พร้อมให้บริการ ลองอีกครั้งในอีกสักครู่",
  "Gemini anahtarı okunamadı. Anahtarı yeniden gir.":
      "อ่านคีย์ Gemini ไม่ได้ ป้อนคีย์ใหม่",
  "Gemini anahtarı kaydedilemedi. Tekrar dene.":
      "บันทึกคีย์ Gemini ไม่ได้ ลองอีกครั้ง",
  "Ücretsiz dene": "ทดลองใช้ฟรี",
  "ÜCRETSİZ DENEME": "ทดลองใช้ฟรี",
  "{0} dakika ücretsiz çeviri": "แปลฟรี {0} นาที",
  "Google ile {0} dk ücretsiz dene": "ทดลองใช้ฟรี {0} นาทีด้วย Google",
  "Ödeme bilgisi gerekmez. Otomatik abonelik başlamaz.":
      "ไม่ต้องใช้ข้อมูลการชำระเงิน ไม่มีการสมัครสมาชิกอัตโนมัติ",
  "Premium paketleri": "แพ็กเกจ Premium",
  "Planını seç": "เลือกแพ็กเกจ",
  "Önce ücretsiz dene": "ทดลองใช้ฟรีก่อน",
  "{0} dakika ücretsiz dene": "ทดลองใช้ฟรี {0} นาที",
  "tek ödeme": "ชำระครั้งเดียว",
  "Google Play ile güvenli ödeme": "ชำระเงินอย่างปลอดภัยผ่าน Google Play",
  "İstediğin zaman iptal": "ยกเลิกได้ทุกเมื่อ",
  "Diyaloglar, görevler ve menüler oynarken çevrilir":
      "แปลบทสนทนา ภารกิจ และเมนูระหว่างเล่น",
  "Altyazılar TV’de oyunun üstünde görünür": "แสดงคำแปลทับบนเกมบนทีวี",
  "Desteklenen oyunlarda hazır, özenli çeviriler":
      "คำแปลสำเร็จรูปที่จัดทำอย่างพิถีพิถันสำหรับเกมที่รองรับ",
  "Görsel kurulum rehberi (PDF)": "คู่มือตั้งค่าพร้อมภาพ (PDF)",
  "Oklarla adım adım anlatım • Türkçe • PS5 + Android TV / Google TV":
      "อธิบายทีละขั้นตอนพร้อมลูกศร • ภาษาตุรกี • PS5 + Android TV / Google TV",
  "Oyun iste": "ขอเพิ่มเกม",
  "{0} - Oyun isteği": "{0} - ขอเพิ่มเกม",
  "Oyun adı: {0}\nİstenen dil:\nOyun sürümü (PS4 / PS5):\n\nEk not:":
      "ชื่อเกม: {0}\nภาษาที่ต้องการ:\nเวอร์ชันเกม (PS4 / PS5):\n\nหมายเหตุเพิ่มเติม:",
  "İsteği kopyala": "คัดลอกคำขอ",
  "İstek metni kopyalandı.": "คัดลอกข้อความคำขอแล้ว",
  "Altyazı dili": "ภาษาคำบรรยาย",
  "Bu dilde henüz oyun paketi yok.": "ยังไม่มีแพ็กเกมในภาษานี้",
  "Bu seçim arayüz dilini ve oyun kütüphanesindeki dil filtresini belirler.":
      "การเลือกนี้กำหนดภาษาแอปและตัวกรองภาษาในคลังเกม",
  "Dil değiştirilemez": "เปลี่ยนภาษาไม่ได้",
  "Dili veya oyunu değiştirmek için çeviriyi durdur.":
      "หยุดการแปลก่อนเปลี่ยนภาษาหรือเกม",
  "Seçili: {0} · {1}": "ที่เลือก: {0} · {1}",
  "Seçili model bu dili desteklemiyor. Yalnızca oyun paketindeki metinler gösterilir.":
      "โมเดลที่เลือกไม่รองรับภาษานี้ จะแสดงเฉพาะข้อความจากแพ็กเกม",
  "Kullanımı göster": "ดูการใช้งาน",
  "DeepL (önerilen)": "DeepL (แนะนำ)",
  "Kalan: {0} karakter (%{1})": "เหลือ: {0} อักขระ ({1}%)",
  "Kalan: Limitsiz": "เหลือ: ไม่จำกัด",
  "Ücretsiz DeepL API anahtarı al": "รับคีย์ DeepL API ฟรี",
  "DeepL’nin sitesinde ücretsiz bir API hesabı oluştur, API anahtarını buraya yapıştır.":
      "สร้างบัญชี API ฟรีบนเว็บไซต์ DeepL แล้ววางคีย์ API ที่นี่",
  "DeepL hesabı: {0} / {1} karakter": "บัญชี DeepL: {0} / {1} อักขระ",
  "Limitsiz": "ไม่จำกัด",
  "DeepL sayacı birkaç dakika gecikmeli güncellenebilir.":
      "ยอดการใช้งาน DeepL อาจอัปเดตช้าไปสองสามนาที",
  "DeepL kullanım bilgisi alınamadı. Tekrar dene.":
      "ดึงข้อมูลการใช้งาน DeepL ไม่ได้ ลองอีกครั้ง",
  "DeepL API anahtarı": "คีย์ DeepL API",
  "DeepL API anahtarı gerekli": "ต้องใช้คีย์ DeepL API",
  "DeepL bölümüne anahtarını girip test et ve kaydet.":
      "ป้อนคีย์ในส่วน DeepL แล้วทดสอบและบันทึก",
  "DeepL internet bağlantısı ve kendi API anahtarını gerektirir. Altyazı metinleri çeviri için DeepL’ye gönderilir; kullanım DeepL hesabının kotasından düşer.":
      "DeepL ต้องใช้อินเทอร์เน็ตและคีย์ API ของคุณเอง ข้อความจะถูกส่งไปแปลที่ DeepL และนับรวมในโควตาบัญชี DeepL ของคุณ",
  "Anahtar kayıtlı • değiştirmek için yaz":
      "บันทึกคีย์แล้ว • พิมพ์เพื่อเปลี่ยน",
  "Free / Pro otomatik seçilir. Anahtar cihazda şifreli saklanır.":
      "เลือก Free / Pro โดยอัตโนมัติ คีย์ถูกเข้ารหัสและเก็บไว้บนอุปกรณ์",
  "Anahtarı göster": "แสดงคีย์",
  "Anahtarı gizle": "ซ่อนคีย์",
  "Test et ve kaydet": "ทดสอบและบันทึก",
  "Anahtarı sil": "ลบคีย์",
  "DeepL anahtarı silindi.": "ลบคีย์ DeepL แล้ว",
  "DeepL bağlantısı başarılı. Çeviri için hazır.":
      "เชื่อมต่อ DeepL สำเร็จ พร้อมแปลแล้ว",
  "Geçerli bir DeepL API anahtarı gir.": "ป้อนคีย์ DeepL API ที่ถูกต้อง",
  "DeepL API anahtarı kabul edilmedi. Anahtarını kontrol et.":
      "DeepL ไม่ยอมรับคีย์ API ตรวจสอบคีย์ของคุณ",
  "DeepL karakter kotası doldu. DeepL hesabını kontrol et.":
      "โควตาอักขระ DeepL หมดแล้ว ตรวจสอบบัญชี DeepL",
  "DeepL istek sınırına ulaşıldı. Biraz sonra tekrar dene.":
      "ถึงขีดจำกัดคำขอ DeepL แล้ว ลองอีกครั้งในอีกสักครู่",
  "DeepL dil seçimini kontrol et.": "ตรวจสอบภาษาที่เลือกสำหรับ DeepL",
  "DeepL şu anda yanıt veremiyor. Biraz sonra tekrar dene.":
      "DeepL ยังไม่พร้อมให้บริการ ลองอีกครั้งในอีกสักครู่",
  "DeepL bağlantısı kurulamadı. İnternet bağlantını kontrol et.":
      "เชื่อมต่อ DeepL ไม่ได้ ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต",
  "DeepL çeviri yanıtı geçersiz.": "คำตอบการแปลจาก DeepL ไม่ถูกต้อง",
  "DeepL anahtarı okunamadı. Anahtarı yeniden gir.":
      "อ่านคีย์ DeepL ไม่ได้ ป้อนคีย์ใหม่",
  "DeepL anahtarı kaydedilemedi. Tekrar dene.":
      "บันทึกคีย์ DeepL ไม่ได้ ลองอีกครั้ง",
  "DeepL işlemi tamamlanamadı. Tekrar dene.":
      "ดำเนินการกับ DeepL ไม่สำเร็จ ลองอีกครั้ง",
  "DeepL bu platformda kullanılamıyor.": "ไม่รองรับ DeepL บนแพลตฟอร์มนี้",
  "Beta TV desteği": "การรองรับทีวีรุ่นเบต้า",
  "LG webOS ve Samsung Tizen desteği beta aşamasındadır. TV modeline göre bağlantı veya altyazı hataları yaşanabilir.":
      "การรองรับ LG webOS และ Samsung Tizen ยังอยู่ในช่วงเบต้า อาจพบปัญหาการเชื่อมต่อหรือคำบรรยายขึ้นอยู่กับรุ่นทีวี",
  "TV uygulamasını indir": "ดาวน์โหลดแอปทีวี",
  "TV kurulum rehberini aç": "เปิดคู่มือตั้งค่าทีวี",
  "TV bağlantısı için destek al": "ขอความช่วยเหลือเรื่องการเชื่อมต่อทีวี",
  "{0} TV bağlantı desteği": "ความช่วยเหลือการเชื่อมต่อทีวี {0}",
  "TV türü: {0}\nTV modeli:\nTV yazılım sürümü:\nUygulama sürümü: {1}\nSorun yaşadığın adım:\nSorunun açıklaması:\n\nSorunun ekran görüntüsünü bu e-postaya ekleyebilirsin.":
      "ประเภททีวี: {0}\nรุ่นทีวี:\nเวอร์ชันซอฟต์แวร์ทีวี:\nเวอร์ชันแอป: {1}\nขั้นตอนที่พบปัญหา:\nคำอธิบายปัญหา:\n\nคุณสามารถแนบภาพหน้าจอปัญหาในอีเมลนี้ได้",
  "Android TV / Google TV • Philips, Sony ve uyumlu cihazlar":
      "Android TV / Google TV • Philips, Sony และอุปกรณ์ที่รองรับ",
  "TV gerekli": "ต้องเชื่อมต่อทีวี",
  "Önce TV türünü seçip bağlantı testini tamamla.":
      "เลือกประเภททีวีและทดสอบการเชื่อมต่อให้เสร็จก่อน",
  "TV’ye bağlanılıyor": "กำลังเชื่อมต่อทีวี",
  "TV’ye bağlanılıyor…": "กำลังเชื่อมต่อทีวี…",
  "Başlamak için TV’yi eşleştir": "จับคู่ทีวีเพื่อเริ่มใช้งาน",
  "Oyun Çevirmeni • TV bağlantı testi":
      "ตัวแปลเกมคอนโซล • ทดสอบการเชื่อมต่อทีวี",
  "Önce TV bağlantısını kontrol edelim.": "ตรวจสอบการเชื่อมต่อทีวีก่อน",
  "Telefon ve TV aynı yerel ağda olsun. TV ayarlarındaki ağ bölümünden yerel IPv4 adresini bul. Bağlanırken TV’de çıkan izin isteğini kumandayla onayla. TV’ye uygulama yüklemek gerekmez.":
      "เชื่อมต่อโทรศัพท์และทีวีกับเครือข่ายท้องถิ่นเดียวกัน ดูที่อยู่ IPv4 ภายในจากการตั้งค่าเครือข่ายทีวี ใช้รีโมตอนุญาตคำขอที่ปรากฏบนทีวีเมื่อเชื่อมต่อ ไม่จำเป็นต้องติดตั้งแอปบนทีวี",
  "LG TV’nin yerel IPv4 adresi": "ที่อยู่ IPv4 ภายในของทีวี LG",
  "Şifreli bağlantı (3001)": "การเชื่อมต่อแบบเข้ารหัส (3001)",
  "İlk bağlantıda TV sertifikası kaydedilir; sonraki bağlantılarda aynı sertifika aranır. Kimlik ilk kullanımda TV’deki izin onayına dayanır.":
      "ระบบจะบันทึกใบรับรองทีวีในการเชื่อมต่อครั้งแรก และตรวจสอบให้ตรงกันทุกครั้งหลังจากนั้น การยืนยันตัวตนครั้งแรกอาศัยการอนุญาตบนทีวี",
  "Eski TV modu (3000): altyazı ve eşleştirme bilgileri yerel ağda şifresiz taşınır. Yalnızca güvendiğin ev ağında kullan.":
      "โหมดทีวีรุ่นเก่า (3000): ข้อความคำแปลและข้อมูลการจับคู่ถูกส่งผ่านเครือข่ายท้องถิ่นโดยไม่เข้ารหัส ใช้กับเครือข่ายบ้านที่เชื่อถือได้เท่านั้น",
  "LG bildirim modu: altyazılar TV bildirimi olarak görünür. Konum, yazı tipi ve süreyi TV belirler; çoklu alan metinleri birleştirilir. Durdurduğunda bekleyen metinler iptal edilir, görünen bildirim TV’nin süresi dolunca kapanır.":
      "โหมดแจ้งเตือน LG: แสดงคำแปลเป็นการแจ้งเตือนทีวี โดยทีวีกำหนดตำแหน่ง แบบอักษร และระยะเวลา ข้อความจากหลายพื้นที่จะถูกรวมกัน เมื่อหยุด ข้อความที่รอจะถูกยกเลิก ส่วนการแจ้งเตือนที่แสดงอยู่จะหายไปเมื่อหมดเวลาของทีวี",
  "TV’deki izin isteğini onayla…": "อนุญาตคำขอบนทีวี…",
  "Bağlan ve örnek yazı gönder": "เชื่อมต่อและส่งข้อความตัวอย่าง",
  "PS5’in HDMI görüntüsü açıkken örnek bildirimi gördüysen aşağıdan onayla. Göremediysen bu modu kullanma.":
      "ยืนยันด้านล่างเฉพาะเมื่อเห็นการแจ้งเตือนตัวอย่างพร้อมภาพ PS5 ผ่าน HDMI หากไม่เห็น อย่าใช้โหมดนี้",
  "Samsung TV’de “Console Game Translator TV” uygulamamızın açık olması gerekiyor. Telefonda oluşturduğun kodu bu TV uygulamasına girerek eşleştireceksin.":
      "เปิดแอป “Console Game Translator TV” บนทีวี Samsung แล้วป้อนรหัสที่สร้างจากโทรศัพท์ในแอปทีวีเพื่อจับคู่",
  "TV uygulaması henüz kurulu değil mi?": "ยังไม่ได้ติดตั้งแอปทีวีใช่ไหม?",
  "Samsung TV uygulamamız henüz Samsung mağazasında bulunmuyor. İlk kurulum için sitemizdeki Windows kurulum yardımcısını kullan. Samsung hesabınla TV’ye kurulum iznini bir kez hazırlaman gerekir. Adımlar için TV kurulum rehberini aç.":
      "แอปทีวี Samsung ของเรายังไม่มีในร้านค้า Samsung ใช้ตัวช่วยติดตั้งสำหรับ Windows จากเว็บไซต์ของเราในการติดตั้งครั้งแรก คุณต้องเตรียมสิทธิ์ติดตั้งบนทีวีด้วยบัญชี Samsung หนึ่งครั้ง เปิดคู่มือตั้งค่าทีวีเพื่อดูขั้นตอน",
  "Yeni eşleştirme kodu oluştur": "สร้างรหัสจับคู่ใหม่",
  "TV uygulamam kurulu • Eşleştir": "ติดตั้งแอปทีวีแล้ว • จับคู่",
  "Telefonun adresi": "ที่อยู่โทรศัพท์",
  "Eşleştirme kodu": "รหัสจับคู่",
  "TV’de uygulamamızı aç. Buradaki telefon adresini ve eşleştirme kodunu TV ekranına gir. Birden fazla adres varsa TV ile aynı ağdakini seç. Kod 2 dakika geçerlidir.":
      "เปิดแอปของเราบนทีวี แล้วป้อนที่อยู่โทรศัพท์และรหัสจับคู่ที่แสดงที่นี่ หากมีหลายที่อยู่ ให้เลือกที่อยู่ในเครือข่ายเดียวกับทีวี รหัสมีอายุ 2 นาที",
  "Kod kullanıldı": "ใช้รหัสแล้ว",
  "HDMI ve örnek altyazı TV’de onaylandı.":
      "ยืนยัน HDMI และคำบรรยายตัวอย่างบนทีวีแล้ว",
  "TV bağlandı. TV’de HDMI girişini seçip oyun + örnek altyazı testini onayla.":
      "จับคู่ทีวีแล้ว เลือกช่อง HDMI บนทีวีและยืนยันการทดสอบภาพเกมพร้อมคำบรรยายตัวอย่าง",
  "TV uygulamasının bağlanması bekleniyor…": "กำลังรอแอปทีวีเชื่อมต่อ…",
  "Altyazılar için TV uygulamamızı açık tut. Kumandadan Home’a basarsan veya başka bir girişe geçersen altyazılar durur. Bu bağlantıda metinler ev ağında şifresiz iletilir.":
      "เปิดแอปของเราค้างไว้บนทีวีเพื่อแสดงคำบรรยาย การกด Home หรือเปลี่ยนช่องสัญญาณเข้าจะหยุดคำบรรยาย การเชื่อมต่อนี้ส่งข้อความผ่านเครือข่ายบ้านโดยไม่เข้ารหัส",
  "Sorun mu yaşıyorsun? TV modelini, sorunun kısa açıklamasını ve ekran görüntüsünü bize gönder; birlikte çözelim.":
      "พบปัญหาใช่ไหม? ส่งรุ่นทีวี คำอธิบายปัญหาสั้น ๆ และภาพหน้าจอมาให้เราช่วยแก้ไข",
  "TV’de örnek yazıyı gördüm": "ฉันเห็นข้อความตัวอย่างบนทีวีแล้ว",
  "Bağlantıyı kullan": "ใช้การเชื่อมต่อนี้",
  "LG bağlantısı kurulamadı. IP adresini, TV iznini ve bağlantı türünü kontrol et.":
      "เชื่อมต่อ LG ไม่ได้ ตรวจสอบที่อยู่ IP สิทธิ์บนทีวี และประเภทการเชื่อมต่อ",
  "Geçerli bir yerel IP adresi gir (ör. 192.168.1.20). TV’de Ayarlar > Ağ bölümünde görünür.":
      "ป้อนที่อยู่ IP ภายในที่ถูกต้อง (เช่น 192.168.1.20) ดูได้ที่ การตั้งค่า > เครือข่าย บนทีวี",
  "LG bildirimi gösterilemedi. TV bağlantısını yeniden test et.":
      "แสดงการแจ้งเตือน LG ไม่ได้ ทดสอบการเชื่อมต่อทีวีใหม่",
  "TV bağlantı isteğini reddetti. Testi yeniden çalıştır ve TV’de izin ver.":
      "ทีวีปฏิเสธการเชื่อมต่อ ทดสอบอีกครั้งแล้วอนุญาตบนทีวี",
  "TV’deki izin isteği zamanında onaylanmadı. Testi yeniden çalıştır ve kumandayla izin ver.":
      "ไม่ได้อนุญาตคำขอบนทีวีทันเวลา ทดสอบอีกครั้งแล้วอนุญาตด้วยรีโมต",
  "TV eşleştirme isteğini kabul etmedi. TV ayarlarında mobil cihaz bağlantısı (LG Connect Apps / Mobile TV On) iznini açıp TV’yi yeniden başlat.":
      "ทีวีไม่ยอมรับการจับคู่ เปิดสิทธิ์เชื่อมต่ออุปกรณ์มือถือ (LG Connect Apps / Mobile TV On) ในการตั้งค่าทีวีแล้วรีสตาร์ตทีวี",
  "TV şifreli bağlantıya yanıt vermiyor. “Şifreli bağlantı” seçeneğini kapatıp yeniden dene.":
      "ทีวีไม่ตอบสนองต่อการเชื่อมต่อแบบเข้ารหัส ปิด “การเชื่อมต่อแบบเข้ารหัส” แล้วลองอีกครั้ง",
  "TV şifresiz bağlantıya yanıt vermiyor. “Şifreli bağlantı” seçeneğini açıp yeniden dene.":
      "ทีวีไม่ตอบสนองต่อการเชื่อมต่อแบบไม่เข้ารหัส เปิด “การเชื่อมต่อแบบเข้ารหัส” แล้วลองอีกครั้ง",
  "TV bu IP adresinde bulunamadı. TV’nin açık olduğunu, IP adresini ve telefonla aynı Wi-Fi ağında olduğunu kontrol et.":
      "ไม่พบทีวีที่ที่อยู่ IP นี้ ตรวจสอบว่าทีวีเปิดอยู่ ที่อยู่ IP ถูกต้อง และเชื่อมต่อ Wi-Fi เดียวกับโทรศัพท์",
  "TV ile şifreli bağlantı kurulamadı. “Şifreli bağlantı” seçeneğini kapatıp yeniden dene.":
      "สร้างการเชื่อมต่อแบบเข้ารหัสกับทีวีไม่ได้ ปิด “การเชื่อมต่อแบบเข้ารหัส” แล้วลองอีกครั้ง",
  "TV’nin güvenlik sertifikası değişmiş. TV bağlantısını kaldırıp yeniden eşleştir.":
      "ใบรับรองความปลอดภัยของทีวีเปลี่ยนไป ลบการเชื่อมต่อทีวีแล้วจับคู่ใหม่",
  "TV bağlantıyı kabul etmedi. TV’yi yeniden başlatıp diğer bağlantı türünü dene.":
      "ทีวีไม่ยอมรับการเชื่อมต่อ รีสตาร์ตทีวีแล้วลองการเชื่อมต่ออีกประเภท",
  "Yerel TV oturumu açılamadı. Telefonun Wi-Fi bağlantısını kontrol et.":
      "เปิดเซสชันทีวีภายในเครือข่ายไม่ได้ ตรวจสอบ Wi-Fi ของโทรศัพท์",
  "TV bağlantısı doğrulanamadı. Testi yeniden çalıştır.":
      "ยืนยันการเชื่อมต่อทีวีไม่ได้ ทดสอบอีกครั้ง",
  "LG webOS veya Samsung Tizen TV kullanabilir miyim?":
      "ใช้ทีวี LG webOS หรือ Samsung Tizen ได้ไหม?",
  "TV eşleştirme ekranında LG webOS veya Samsung Tizen seç. LG, IP adresi ve TV’de izin onayıyla bildirim modunu kullanır; konum ve yazı biçimini TV belirler. Samsung, bilgisayardan kurulan ayrı Tizen alıcısını ve HDMI + örnek altyazı testini gerektirir. Sorun yaşarsan TV modelini ve ekran görüntüsünü destek ekibimize gönder. Philips ve Sony Android TV / Google TV cihazlarında mevcut Android TV seçeneğini kullan.":
      "เลือก LG webOS หรือ Samsung Tizen ในหน้าจับคู่ทีวี LG ใช้โหมดแจ้งเตือนหลังจับคู่ด้วย IP และอนุญาตบนทีวี โดยทีวีกำหนดตำแหน่งและรูปแบบข้อความ Samsung ต้องใช้แอปรับสัญญาณ Tizen แยกต่างหากที่ติดตั้งจากคอมพิวเตอร์ และทดสอบ HDMI พร้อมคำบรรยายตัวอย่าง หากพบปัญหา ส่งรุ่นทีวีและภาพหน้าจอให้ทีมสนับสนุน สำหรับ Philips และ Sony ที่ใช้ Android TV / Google TV ให้เลือก Android TV",
  "Bu rehberdeki TV adımları Android TV içindir. LG webOS ve Samsung Tizen için TV eşleştirme ekranındaki ayrı seçeneği kullan ve kendi TV testini tamamla.":
      "ขั้นตอนทีวีในคู่มือนี้ใช้กับ Android TV สำหรับ LG webOS และ Samsung Tizen ให้ใช้ตัวเลือกเฉพาะในหน้าจับคู่ทีวีและทำการทดสอบของทีวีนั้นให้เสร็จ",
  "Her altyazı alanının konumunu ve görünümünü ayrı düzenleyebilirsin. Yeni alanlar varsayılan ayarlarla eklenir.":
      "ปรับตำแหน่งและรูปแบบของแต่ละพื้นที่คำบรรยายแยกกันได้ พื้นที่ใหม่จะใช้ค่าเริ่มต้น",
  "Her OCR alanının konumunu ve tarama ayarlarını ayrı düzenleyebilirsin. Yeni alanlar varsayılan ayarlarla eklenir.":
      "ปรับตำแหน่งและการสแกนของแต่ละพื้นที่ OCR แยกกันได้ พื้นที่ใหม่จะใช้ค่าเริ่มต้น",
  "OCR {0} tarama sıklığı: {1}": "อัตราสแกน OCR {0}: {1}",
  "Yazı tipi": "แบบอักษร",
  "Oyun fontu": "แบบอักษรเกม",
  "Sistem fontu": "แบบอักษรระบบ",
  "Oyun fontu yoksa sistem fontu kullanılır. Diğer görünüm ve konum ayarların korunur.":
      "ใช้แบบอักษรระบบเมื่อไม่มีแบบอักษรเกม การตั้งค่ารูปแบบและตำแหน่งอื่น ๆ จะคงเดิม",
  "İndirilen çevirileri sil?": "ลบคำแปลที่ดาวน์โหลดไว้หรือไม่?",
  "{0} oyununun telefondaki çevirileri silinir. Seçiliyse seçim kaldırılır. Oyunu tekrar seçerek çevirileri yeniden indirebilirsin.":
      "คำแปลของ {0} จะถูกลบออกจากโทรศัพท์ หากเลือกเกมนี้อยู่จะยกเลิกการเลือกด้วย เลือกเกมอีกครั้งเพื่อดาวน์โหลดคำแปลใหม่ได้",
  "Sil": "ลบ",
  "İndirilen çeviriler silindi.": "ลบคำแปลที่ดาวน์โหลดแล้ว",
  "İndirildi": "ดาวน์โหลดแล้ว",
  "Çeviriler silinemedi. Tekrar dene.": "ลบคำแปลไม่ได้ ลองอีกครั้ง",
  "En avantajlı": "คุ้มค่าที่สุด",
  "Uzun vadeli kullanım için tek ödeme.":
      "จ่ายครั้งเดียวสำหรับการใช้งานระยะยาว",
  "Haftalık plana göre %{0} tasarruf":
      "ประหยัด {0}% เมื่อเทียบกับแพ็กเกจรายสัปดาห์",
  "12 aylık ödemeye göre %{0} tasarruf":
      "ประหยัด {0}% เมื่อเทียบกับการจ่ายรายเดือน 12 ครั้ง",
  "Çeviri dosyası indiriliyor…": "กำลังดาวน์โหลดไฟล์คำแปล…",
  "Çeviri belleğe yükleniyor…": "กำลังโหลดคำแปลลงหน่วยความจำ…",
  "Oyun listesini yenile": "รีเฟรชคลังเกม",
  "Henüz oyun eklenmedi.": "ยังไม่มีเกม",
  "Oyun adıyla ara": "ค้นหาจากชื่อเกม",
  "Aramayı temizle": "ล้างการค้นหา",
  "Aramana uygun oyun bulunamadı.": "ไม่พบเกมที่ตรงกับการค้นหา",
  "Oyun seçilmedi": "ยังไม่ได้เลือกเกม",
  "Daha hızlı ve doğru çeviri için oyun kütüphanesinde oyunun varsa seç. Listede yoksa oyun seçmeden devam edebilirsin.":
      "เพื่อให้แปลได้เร็วและแม่นยำขึ้น ให้เลือกเกมของคุณหากมีในคลังเกม หากไม่มีในรายการ คุณสามารถใช้ต่อโดยไม่เลือกเกมได้",
  "Seçmeden devam et": "ใช้ต่อโดยไม่เลือกเกม",
  "Oyun kütüphanesini aç": "เปิดคลังเกม",
  "Oyun çevirileri hazırlanıyor…": "กำลังเตรียมคำแปลเกม…",
  "Oyun çevirileri yüklenemedi": "โหลดคำแปลเกมไม่ได้",
  "Oyun listesi yenilenemedi. Kayıtlı oyunlarını kullanabilirsin.":
      "รีเฟรชคลังเกมไม่ได้ คุณยังใช้เกมที่บันทึกไว้ได้",
  "Oyun erişimi doğrulanamadı.": "ยืนยันสิทธิ์เข้าถึงคลังเกมไม่ได้",
  "Oyun çeviri dosyası doğrulanamadı.": "ตรวจสอบไฟล์คำแปลเกมไม่ได้",
  "Oyun dosyası indirilemedi.": "ดาวน์โหลดไฟล์เกมไม่ได้",
  "Oyun dosyası çok büyük.": "ไฟล์เกมใหญ่เกินไป",
  "Konsol: {0}\n": "คอนโซล: {0}\n",
  "Çevrildi · {0} Yerel": "แปลแล้ว · {0} ในเครื่อง",
  "Console Game Translator": "ตัวแปลเกมคอนโซล",
  "Oyun Çevirmeni": "ตัวแปลเกมคอนโซล",
  "Oyununu kendi dilinde yaşa": "สัมผัสเกมในภาษาของคุณ",
  "Ayar kaydedilemedi": "บันทึกการตั้งค่าไม่ได้",
  "Uygulama dili": "ภาษาของแอป",
  "Uygulamanın arayüzü şu anda Türkçe. Çeviri kaynak ve hedef dilleri ana ekrandaki dil bölümünden seçebilirsin.":
      "เลือกภาษาที่ใช้แสดงในแอป ส่วนภาษาสำหรับแปลเกมเลือกแยกได้ที่หน้าหลัก",
  "Model C hazır": "Model C พร้อมแล้ว",
  "HPLT İngilizce → Türkçe paketi çevrimdışı kullanıma hazır.":
      "แพ็ก HPLT อังกฤษ → ตุรกีพร้อมใช้งานแบบออฟไลน์แล้ว",
  "Model C indirilemedi": "ดาวน์โหลด Model C ไม่ได้",
  "İnternet bağlantını kontrol edip tekrar dene.":
      "ตรวจสอบการเชื่อมต่ออินเทอร์เน็ตแล้วลองอีกครั้ง",
  "Dil paketi hazır": "แพ็กภาษาพร้อมแล้ว",
  "Seçilen hedef dil çevrimdışı kullanıma hazır.":
      "ภาษาปลายทางที่เลือกพร้อมใช้แบบออฟไลน์แล้ว",
  "Model indirilemedi": "ดาวน์โหลดโมเดลไม่ได้",
  "İnternet bağlantını kontrol et.": "ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต",
  "Dil seçilemedi": "เลือกภาษาไม่ได้",
  "Tekrar dene.": "ลองอีกครั้ง",
  "Model değiştirilemez": "เปลี่ยนโมเดลไม่ได้",
  "Çeviri devam ederken model değiştirilemez. Önce çeviriyi durdurup tekrar dene.":
      "เปลี่ยนโมเดลระหว่างแปลไม่ได้ หยุดการแปลแล้วลองอีกครั้ง",
  "Motor seçilemedi": "เลือกเอนจินแปลไม่ได้",
  "Dil çiftine uygun paketi seçip indir.":
      "เลือกและดาวน์โหลดแพ็กสำหรับคู่ภาษาของคุณ",
  "Kurulum henüz tamamlanmadı": "ยังตั้งค่าไม่เสร็จ",
  "{0} / {1} adım tamamlandı": "เสร็จแล้ว {0} / {1} ขั้นตอน",
  "PS5 ve TV bağlantıların hazır. En iyi deneyim için kurulum rehberindeki eksik adımları tamamlamanı öneririz. İstersen çeviriyi şimdi de başlatabilirsin.":
      "การเชื่อมต่อ PS5 และทีวีพร้อมแล้ว เพื่อประสบการณ์ที่ดีที่สุด แนะนำให้ทำขั้นตอนตั้งค่าที่เหลือให้ครบ หรือเริ่มแปลตอนนี้ได้เช่นกัน",
  "Bir daha gösterme": "ไม่ต้องแสดงอีก",
  "Yine de başlat": "เริ่มเลย",
  "Kurulumu tamamla": "ตั้งค่าให้เสร็จ",
  "Tercih kaydedilemedi. Kurulum uyarısı tekrar görünebilir.":
      "บันทึกการตั้งค่าไม่ได้ ข้อความเตือนการตั้งค่าอาจปรากฏอีก",
  "Android TV’yi eşleştir": "จับคู่ Android TV",
  "TV açık ve telefonla aynı Wi-Fi ağına bağlı olsun. İlk eşleştirme için TV uygulamasını açıp ekrandaki 6 haneli kodu gir. Eşleştirmeden sonra TV uygulamasını açmadan bağlanabilirsin.":
      "เปิดทีวีและเชื่อมต่อ Wi-Fi เดียวกับโทรศัพท์ สำหรับการจับคู่ครั้งแรก ให้เปิดแอปทีวีแล้วป้อนรหัส 6 หลักบนหน้าจอ หลังจับคู่แล้วจะเชื่อมต่อได้โดยไม่ต้องเปิดแอปทีวี",
  "TV bulunamadı. TV’nin açık ve iki cihazın aynı Wi-Fi ağında olduğundan emin ol.":
      "ไม่พบทีวี ตรวจสอบว่าทีวีเปิดอยู่และทั้งสองอุปกรณ์ใช้ Wi-Fi เดียวกัน",
  "Bir TV bulundu.": "พบทีวี 1 เครื่อง",
  "{0} TV bulundu. Kendi TV ekranındaki adresle eşleşeni seç.":
      "พบทีวี {0} เครื่อง เลือกที่อยู่ที่ตรงกับหน้าจอทีวีของคุณ",
  "Ağ taraması yapılamadı. Aynı Wi-Fi ağını kontrol et.":
      "สแกนเครือข่ายไม่ได้ ตรวจสอบว่าทั้งสองอุปกรณ์ใช้ Wi-Fi เดียวกัน",
  "TV aranıyor…": "กำลังค้นหาทีวี…",
  "TV’yi ağda bul": "ค้นหาทีวีในเครือข่าย",
  "TV ekranındaki adresle eşleşeni seç": "เลือกที่อยู่ที่แสดงบนทีวี",
  "TV ekranındaki adres": "ที่อยู่บนหน้าจอทีวี",
  "TV ekranındaki 6 haneli kod": "รหัส 6 หลักบนหน้าจอทีวี",
  "Bağlantıyı iptal et": "ยกเลิกการเชื่อมต่อ",
  "İptal": "ยกเลิก",
  "TV kimliğini doğrula": "ยืนยันตัวตนทีวี",
  "Bu değer TV ekranındaki “Güvenli bağlantı kimliği” ile aynı mı? Yalnızca tamamı eşleşiyorsa onayla.":
      "ค่านี้ตรงกับ “รหัสยืนยันการเชื่อมต่อที่ปลอดภัย” บนทีวีหรือไม่? ยืนยันเฉพาะเมื่อตรงกันทั้งหมด",
  "Eşleşmiyor / İptal": "ไม่ตรงกัน / ยกเลิก",
  "Tamamı eşleşiyor": "ตรงกันทั้งหมด",
  "Android TV eşleştirildi. Altyazılar bağlantı açılınca TV’ye gönderilir.":
      "จับคู่ Android TV แล้ว จะส่งคำบรรยายไปยังทีวีเมื่อเชื่อมต่อ",
  "TV’ye bağlanılamadı. Adres, kod ve aynı Wi-Fi ağını kontrol et.":
      "เชื่อมต่อทีวีไม่ได้ ตรวจสอบที่อยู่ รหัส และเครือข่าย Wi-Fi",
  "Bağlanıyor…": "กำลังเชื่อมต่อ…",
  "Eşleştir ve bağlan": "จับคู่และเชื่อมต่อ",
  "Türkçe": "ภาษาตุรกี",
  "Oyun seçilmedi · canlı çeviri kullanılıyor":
      "ยังไม่ได้เลือกเกม · ใช้การแปลสด",
  "Oyun çeviri dosyası yükleniyor…": "กำลังโหลดไฟล์คำแปลเกม…",
  "Seçili oyun katalogda bulunamadı.": "ไม่พบเกมที่เลือกในแค็ตตาล็อก",
  "Oyun kataloğu okunamadı.": "อ่านแค็ตตาล็อกเกมไม่ได้",
  "Oyun çeviri verisi belleğe alınamadı.":
      "โหลดข้อมูลคำแปลเกมลงหน่วยความจำไม่ได้",
  "{0} seçili": "เลือก {0} แล้ว",
  "Unable to load asset": "โหลดทรัพยากรไม่ได้",
  "Oyun çeviri dosyası bulunamadı.": "ไม่พบไฟล์คำแปลเกม",
  "Oyun çeviri verisi okunamadı.": "อ่านข้อมูลคำแปลเกมไม่ได้",
  "Seçili modelin dil paketleri okunamadı.":
      "อ่านแพ็กภาษาของโมเดลที่เลือกไม่ได้",
  "Dil paketi indirilemedi.": "ดาวน์โหลดแพ็กภาษาไม่ได้",
  "Dil paketi indirilemedi": "ดาวน์โหลดแพ็กภาษาไม่ได้",
  "Bağlantını kontrol edip tekrar dene.": "ตรวจสอบการเชื่อมต่อแล้วลองอีกครั้ง",
  "Model C • HPLT v2.0": "Model C • HPLT v2.0",
  "İngilizce → Türkçe • çevrimdışı • yaklaşık 80 MB • 64-bit ARM Android. HPLT v2.0 tabanlı INT8 CTranslate2 paketi.":
      "อังกฤษ → ตุรกี • ออฟไลน์ • ประมาณ 80 MB • Android แบบ ARM 64 บิต แพ็ก CTranslate2 แบบ INT8 ที่พัฒนาจาก HPLT v2.0",
  "HPLT İngilizce → Türkçe": "HPLT อังกฤษ → ตุรกี",
  "İndirildi • cihazda hazır": "ดาวน์โหลดแล้ว • พร้อมใช้บนอุปกรณ์",
  "İndirilmedi": "ยังไม่ได้ดาวน์โหลด",
  "Hazır": "พร้อม",
  "İndir": "ดาวน์โหลด",
  "Atıf: HPLT, translate-en-tr-v2.0-hplt_opus; WindyTranslate INT8 dönüşümü. CC BY 4.0.":
      "เครดิต: HPLT, translate-en-tr-v2.0-hplt_opus; การแปลง INT8 โดย WindyTranslate สัญญาอนุญาต CC BY 4.0",
  "Model A hedef dilleri": "ภาษาปลายทางของ Model A",
  "Model B dilleri": "ภาษาของ Model B",
  "İngilizceden seçtiğin dile çevrimdışı paket indir.":
      "ดาวน์โหลดแพ็กออฟไลน์เพื่อแปลจากภาษาอังกฤษเป็นภาษาที่เลือก",
  "İndirilen diller seçili çeviri motorunda kullanılabilir.":
      "ภาษาที่ดาวน์โหลดแล้วใช้กับเอนจินแปลที่เลือกได้",
  "Durumu yenile": "รีเฟรชสถานะ",
  "Dil seçenekleri yüklenemedi.": "โหลดตัวเลือกภาษาไม่ได้",
  "Yeniden dene": "ลองอีกครั้ง",
  "İndirildi • İngilizceden kullanılabilir": "ดาวน์โหลดแล้ว • แปลจากอังกฤษได้",
  "İndirilmedi • yaklaşık 20 MB": "ยังไม่ได้ดาวน์โหลด • ประมาณ 20 MB",
  "Seçili": "เลือกอยู่",
  "Seç": "เลือก",
  "İndirildi • çeviri seçiminde kullanılabilir": "ดาวน์โหลดแล้ว • พร้อมใช้แปล",
  "Android TV’ye bağlanılıyor": "กำลังเชื่อมต่อ Android TV",
  "Bağlantı tamamlanınca çeviriyi başlatabilirsin.":
      "เริ่มแปลได้เมื่อเชื่อมต่อแล้ว",
  "Hedef dil paketi gerekli": "ต้องใช้แพ็กภาษาปลายทาง",
  "Model A için seçili hedef dil paketini önce indir.":
      "ดาวน์โหลดแพ็กภาษาปลายทางที่เลือกสำหรับ Model A ก่อน",
  "Model C paketi gerekli": "ต้องใช้แพ็ก Model C",
  "HPLT İngilizce → Türkçe paketini önce indir.":
      "ดาวน์โหลดแพ็ก HPLT อังกฤษ → ตุรกีก่อน",
  "Çeviri durdu": "หยุดการแปลแล้ว",
  "Remote Play oturumu artık etkin değil.": "เซสชัน Remote Play สิ้นสุดแล้ว",
  "Çeviri durdurulamadı": "หยุดการแปลไม่ได้",
  "Önce PlayStation 5’i kurup kaydet.":
      "ตั้งค่าและลงทะเบียน PlayStation 5 ก่อน",
  "Android TV gerekli": "ต้องใช้ Android TV",
  "Önce Android TV’yi eşleştirip bağla.": "จับคู่และเชื่อมต่อ Android TV ก่อน",
  "Dil paketleri hazırlanamadı": "เตรียมแพ็กภาษาไม่ได้",
  "Çeviri başlatılamadı": "เริ่มแปลไม่ได้",
  "PS5 durumu okunamadı": "อ่านสถานะ PS5 ไม่ได้",
  "Lütfen birkaç saniye sonra tekrar dene.": "ลองอีกครั้งในอีกสองสามวินาที",
  "PS5’e bağlanılıyor": "กำลังเชื่อมต่อ PS5",
  "Bağlantı tamamlanana kadar PS5 kaydını kaldıramazsın. Biraz bekleyip tekrar dene.":
      "ลบการลงทะเบียน PS5 ระหว่างเชื่อมต่อไม่ได้ รอสักครู่แล้วลองอีกครั้ง",
  "PS5 görüntüsü yenileniyor": "กำลังรีเฟรชภาพ PS5",
  "Remote Play bağlantısı açık. Görüntü yüzeyi hazırlanıyor.":
      "เชื่อมต่อ Remote Play แล้ว กำลังเตรียมพื้นที่แสดงภาพ",
  "Remote Play bağlantısı kesilsin mi?": "ตัดการเชื่อมต่อ Remote Play หรือไม่?",
  "PS5’teki Remote Play oturumu ve devam eden çeviri durur. PS5 kaydın korunur; daha sonra yeniden bağlanabilirsin.":
      "เซสชัน Remote Play บน PS5 และการแปลปัจจุบันจะหยุดลง โดยจะเก็บการลงทะเบียน PS5 ไว้เพื่อเชื่อมต่อใหม่ภายหลัง",
  "Bağlantıyı kes": "ตัดการเชื่อมต่อ",
  "Remote Play kesildi. PS5 kaydı korundu.":
      "ตัดการเชื่อมต่อ Remote Play แล้ว เก็บการลงทะเบียน PS5 ไว้",
  "Bağlantı kesilemedi": "ตัดการเชื่อมต่อไม่ได้",
  "Kayıtlı PS5 kaldırılsın mı?": "ลบ PS5 ที่ลงทะเบียนไว้หรือไม่?",
  "Bu işlem telefondaki kayıtlı PS5 ve PSN eşleştirme bilgilerini siler. Tekrar eklemek için Sony hesabını doğrulayıp PS5’i yeniden kaydetmen gerekir. Kurulum genellikle yaklaşık 2–5 dakika sürer; Sony hesabı doğrulaması veya ağ bağlantısı yavaşsa daha uzun sürebilir.\n\nDevam etmek istiyor musun?":
      "ข้อมูล PS5 และการจับคู่ PSN ที่บันทึกไว้จะถูกลบออกจากโทรศัพท์ หากต้องการเพิ่มอีกครั้ง คุณต้องยืนยันบัญชี Sony และลงทะเบียน PS5 ใหม่ ปกติใช้เวลาประมาณ 2–5 นาที แต่อาจนานกว่านี้หากยืนยันบัญชี Sony หรือเครือข่ายช้า\n\nต้องการดำเนินการต่อหรือไม่?",
  "PS5’i kaldır": "ลบ PS5",
  "Remote Play açık": "Remote Play กำลังทำงาน",
  "Önce Remote Play bağlantısını kes. PS5 kaydı bağlantı kapandıktan sonra kaldırılabilir.":
      "ตัดการเชื่อมต่อ Remote Play ก่อน จึงจะลบการลงทะเบียน PS5 ได้",
  "PS5 kayıtlı cihazlardan kaldırıldı.": "ลบ PS5 ออกจากอุปกรณ์ที่บันทึกไว้แล้ว",
  "PS5 kaldırılamadı": "ลบ PS5 ไม่ได้",
  "Çeviri başladı": "เริ่มแปลแล้ว",
  "Daha doğru sonuç için oyundaki yazıların bulunduğu OCR alanlarını ve çevrilen altyazının ekranda gösterileceği alanı ayarla. Bu ayarlar her oyun görüntüsüne göre değişebilir.":
      "เพื่อผลลัพธ์ที่แม่นยำขึ้น ให้ปรับพื้นที่ OCR รอบข้อความในเกม และพื้นที่แสดงคำแปล การตั้งค่านี้อาจแตกต่างกันในแต่ละเกม",
  "Daha sonra": "ภายหลัง",
  "Alanları ayarla": "ปรับพื้นที่",
  "Altyazı": "คำบรรยาย",
  "Ana sayfa": "หน้าหลัก",
  "Profil": "โปรไฟล์",
  "Ayarlar": "การตั้งค่า",
  "Oyununu seç, altyazı görünümünü düzenle.": "เลือกเกมและปรับแต่งคำบรรยาย",
  "Görünüm ve alanlar": "รูปแบบและพื้นที่",
  "Altyazı görünümü": "รูปแบบคำบรรยาย",
  "Ekran önizlemesi, OCR alanları ve altyazı ayarları":
      "ตัวอย่างหน้าจอ พื้นที่ OCR และการตั้งค่าคำบรรยาย",
  "Yeni veya kullanılmamış PSN hesabı gerekli":
      "ต้องใช้บัญชี PSN ใหม่หรือบัญชีที่ไม่ได้ใช้งาน",
  "Remote Play bağlı": "เชื่อมต่อ Remote Play แล้ว",
  "Çeviri açık • görüntü yenileniyor": "กำลังแปล • กำลังรีเฟรชภาพ",
  "Çeviri açık • PS5 yeniden bağlanıyor, lütfen bekleyin":
      "กำลังแปล • กำลังเชื่อมต่อ PS5 ใหม่ โปรดรอ",
  "PS5 kaydı hazır": "การลงทะเบียน PS5 พร้อมแล้ว",
  "Kurulu değil": "ยังไม่ได้ตั้งค่า",
  "Bağlı": "เชื่อมต่อแล้ว",
  "Yeniden bağlanıyor": "กำลังเชื่อมต่อใหม่",
  "Bağlanıyor": "กำลังเชื่อมต่อ",
  "Görüntü yenileniyor": "กำลังรีเฟรชภาพ",
  "Lütfen bekleyin": "โปรดรอ",
  "PS5 kaydı kontrol ediliyor…": "กำลังตรวจสอบการลงทะเบียน PS5…",
  "PS5 açılıyor…": "กำลังเปิด PS5…",
  "Görüntü yenileniyor…": "กำลังรีเฟรชภาพ…",
  "PS5 yeniden bağlanıyor…": "กำลังเชื่อมต่อ PS5 ใหม่…",
  "PS5’e bağlanıyor…": "กำลังเชื่อมต่อ PS5…",
  "Remote Play’e dön": "กลับไปที่ Remote Play",
  "Remote Play’i aç": "เปิด Remote Play",
  "PS5’i listeden kaldır": "ลบ PS5 ออกจากรายการ",
  "Android TV": "Android TV",
  "TV’ye bağlantı kuruluyor": "กำลังเชื่อมต่อทีวี",
  "Bağlı • {0}": "เชื่อมต่อแล้ว • {0}",
  "Şifreli": "เข้ารหัส",
  "Şifresiz": "ไม่เข้ารหัส",
  "Altyazıları TV ekranında göster": "แสดงคำบรรยายบนหน้าจอทีวี",
  "Eşleştirme kayıtlı • TV bağlı değil":
      "บันทึกการจับคู่แล้ว • ทีวียังไม่เชื่อมต่อ",
  "Bağlı değil": "ไม่ได้เชื่อมต่อ",
  "Kontrol ediliyor": "กำลังตรวจสอบ",
  "TV’ye bağlanıyor…": "กำลังเชื่อมต่อทีวี…",
  "TV durumu kontrol ediliyor…": "กำลังตรวจสอบสถานะทีวี…",
  "TV’yi yeniden eşleştir": "จับคู่ทีวีใหม่",
  "TV’yi eşleştir": "จับคู่ทีวี",
  "Tekrar dene": "ลองอีกครั้ง",
  "{0}  •  OYUNUNA KENDİ DİLİNDE DEVAM ET": "{0}  •  เล่นต่อในภาษาของคุณ",
  "Kayıtlı": "บันทึกแล้ว",
  "ÇEVİRİ DİLLERİ": "ภาษาที่ใช้แปล",
  "Oyun Kütüphanesi": "คลังเกม",
  "Daha hızlı ve kaliteli bir çeviri deneyimi için oynadığın oyun listede varsa seç.":
      "หากมีเกมของคุณในรายการ ให้เลือกเพื่อการแปลที่เร็วและมีคุณภาพดีขึ้น",
  "Oyun listesi yükleniyor…": "กำลังโหลดเกม…",
  "Güncel oyun listesi alınamadı. İnternet bağlantını kontrol edip tekrar dene.":
      "อัปเดตรายการเกมไม่ได้ ตรวจสอบอินเทอร์เน็ตแล้วลองอีกครั้ง",
  "seçili": "เลือกอยู่",
  "Oyun seçimini kaldır": "ยกเลิกการเลือกเกม",
  "ÇEVİRİ MODELİ": "โมเดลแปลภาษา",
  "En iyi çeviri için Oyun Kütüphanesi’ni öneriyoruz. Oyunun listede yoksa DeepL veya Gemini’yi, bunlara erişimin yoksa yerel modelleri kullanabilirsin.":
      "เพื่อคำแปลที่ดีที่สุด แนะนำให้ใช้คลังเกม หากไม่มีเกมของคุณ ลองใช้ DeepL หรือ Gemini หากเข้าใช้ไม่ได้ ให้ใช้โมเดลภายในเครื่อง",
  "Model A - Yerel Kaliteli": "Model A - ในเครื่อง คุณภาพสูง",
  "Model B - Yerel Hızlı": "Model B - ในเครื่อง รวดเร็ว",
  "Önce yaklaşık 80 MB HPLT model paketini indir.":
      "ดาวน์โหลดแพ็กโมเดล HPLT ก่อน (ประมาณ 80 MB)",
  "İngilizceden seçtiğin hedef dile ait paketi indir.":
      "ดาวน์โหลดแพ็กสำหรับแปลจากอังกฤษเป็นภาษาปลายทางที่เลือก",
  "Seçtiğin kaynak ve hedef dillerin paketlerini indir.":
      "ดาวน์โหลดแพ็กภาษาต้นทางและปลายทางที่เลือก",
  "Dilleri görüntüle ve indir": "ดูและดาวน์โหลดภาษา",
  "Bu motor için kaynak dili İngilizce, hedef dili yukarıdaki seçim olmalı.":
      "สำหรับเอนจินนี้ ให้ใช้ภาษาอังกฤษเป็นภาษาต้นทางและภาษาปลายทางที่เลือกไว้ด้านบน",
  "Model C yalnızca İngilizce → Türkçe dil çiftiyle çalışır.":
      "Model C รองรับเฉพาะอังกฤษ → ตุรกี",
  "Diller yükleniyor…": "กำลังโหลดภาษา…",
  "durum kontrol ediliyor": "กำลังตรวจสอบสถานะ",
  "ÇEVİRİYİ DURDUR": "หยุดแปล",
  "ÇEVİRİYİ BAŞLAT": "เริ่มแปล",
  "Bağlantı hazırlanıyor…": "กำลังเตรียมการเชื่อมต่อ…",
  "Android TV’ye bağlanılıyor…": "กำลังเชื่อมต่อ Android TV…",
  "Remote Play ve altyazı akışı durdurulur":
      "หยุด Remote Play และการส่งคำบรรยาย",
  "Önce PS5 kurulumunu tamamla": "ตั้งค่า PS5 ให้เสร็จก่อน",
  "Başlamak için Android TV’yi eşleştir": "จับคู่ Android TV เพื่อเริ่มใช้งาน",
  "PS5’e bağlanır ve altyazılar TV’de başlar":
      "เชื่อมต่อ PS5 และเริ่มแสดงคำบรรยายบนทีวี",
  "Kurulum rehberi": "คู่มือตั้งค่า",
  "Oyun kataloğunda \"{0}\" alanı eksik.": "แค็ตตาล็อกเกมไม่มีช่องข้อมูล “{0}”",
  "Hesabını sil": "ลบบัญชีของคุณ",
  "Uygulamadaki hesabın kalıcı olarak silinir ve oturumun kapatılır. Tekrarlanan denemeleri önleyen bitiş kaydı saklanır. Bu işlem Google Play aboneliğini iptal etmez; aboneliğini Google Play’den yönetebilirsin.":
      "บัญชีแอปจะถูกลบอย่างถาวรและออกจากระบบ ระบบจะเก็บบันทึกวันสิ้นสุดการทดลองเพื่อป้องกันการทดลองซ้ำ การดำเนินการนี้ไม่ยกเลิกการสมัครสมาชิก Google Play คุณจัดการการสมัครได้ใน Google Play",
  "Vazgeç": "ยกเลิก",
  "Hesabımı sil": "ลบบัญชีของฉัน",
  "Hesabın silindi ve oturumun kapatıldı.": "ลบบัญชีและออกจากระบบแล้ว",
  "Sayfa açılamadı. Biraz sonra tekrar dene.":
      "เปิดหน้านี้ไม่ได้ ลองอีกครั้งภายหลัง",
  "Haftalık": "รายสัปดาห์",
  "Aylık": "รายเดือน",
  "Yıllık": "รายปี",
  "Süresiz": "ตลอดชีพ",
  "Premium": "Premium",
  "yıl": "ปี",
  "dönem": "รอบ",
  "Kalan deneme: {0}. Süre Remote Play bağlantısı başladığında kesintisiz işler. Uygulamayı kapatsan da süre devam eder. Otomatik ücret alınmaz.":
      "เวลาทดลองที่เหลือ: {0} เวลาจะนับต่อเนื่องตั้งแต่เชื่อมต่อ Remote Play แม้ปิดแอปก็ยังนับต่อ ไม่มีการเรียกเก็บเงินอัตโนมัติ",
  "Google girişin tamamlandı. Ücretsiz denemen, Çeviriyi başlat düğmesine basıp Remote Play bağlantısı kurulduğunda başlayacak.":
      "ลงชื่อเข้าใช้ด้วย Google แล้ว การทดลองใช้ฟรีจะเริ่มเมื่อกดเริ่มแปลและเชื่อมต่อ Remote Play",
  "Deneme henüz hazır değil. İnternet bağlantını kontrol edip tekrar dene.":
      "การทดลองยังไม่พร้อม ตรวจสอบอินเทอร์เน็ตแล้วลองอีกครั้ง",
  "Ücretsiz denemen sona erdi. Çeviriye devam etmek için bir paket seçebilirsin.":
      "การทดลองใช้ฟรีสิ้นสุดแล้ว เลือกแพ็กเกจเพื่อแปลต่อ",
  "Ücretsiz çeviriyi dene": "ทดลองแปลฟรี",
  "Google ile ücretsiz dene": "ทดลองใช้ฟรีด้วย Google",
  "Deneme süresi alınamadı. İnternet bağlantını kontrol edip aşağı çekerek yenile.":
      "โหลดระยะเวลาทดลองไม่ได้ ตรวจสอบการเชื่อมต่อแล้วดึงลงเพื่อรีเฟรช",
  "Google Play denemen {0} tarihine kadar aktif. Ücret alınmasını istemiyorsan deneme bitmeden Google Play’den iptal et.":
      "การทดลองผ่าน Google Play ใช้ได้ถึง {0} หากไม่ต้องการเสียค่าใช้จ่าย ให้ยกเลิกใน Google Play ก่อนหมดระยะทดลอง",
  "Deneme aboneliğinin yenilenmesi iptal edildi. {0} tarihine kadar çeviriyi kullanabilirsin.":
      "ยกเลิกการต่ออายุการสมัครทดลองแล้ว คุณยังแปลได้ถึง {0}",
  "Premium aktif. Aboneliğini Google Play’den yönetebilirsin.":
      "Premium ใช้งานได้แล้ว จัดการการสมัครได้ใน Google Play",
  "Yenileme iptal edildi. {0} tarihine kadar Premium erişimin sürer.":
      "ยกเลิกการต่ออายุแล้ว ใช้ Premium ต่อได้ถึง {0}",
  "Süresiz Premium erişimin aktif.":
      "สิทธิ์ Premium ตลอดชีพของคุณใช้งานได้แล้ว",
  "Satın alma durumu doğrulanamadı. İnternete bağlanıp durumu yenile.":
      "ยืนยันสถานะการซื้อไม่ได้ เชื่อมต่ออินเทอร์เน็ตแล้วรีเฟรช",
  "{0} · tek ödeme, otomatik yenilenmez.":
      "{0} · จ่ายครั้งเดียว ไม่มีการต่ออายุอัตโนมัติ",
  "{0} / {1}. Aboneliğin otomatik yenilenir; Google Play’den iptal edebilirsin.":
      "{0} / {1} การสมัครจะต่ออายุอัตโนมัติ ยกเลิกได้ใน Google Play",
  "Süresiz satın al": "ซื้อสิทธิ์ตลอดชีพ",
  "Abone ol": "สมัครสมาชิก",
  "Premium aktif": "Premium ใช้งานได้",
  "Erişim durumunu yenilemek için aşağı çek.": "ดึงลงเพื่อรีเฟรชสถานะสิทธิ์",
  "Çeviriye devam et": "แปลต่อ",
  "Deneme için Google ile giriş yap": "ลงชื่อเข้าใช้ด้วย Google เพื่อทดลอง",
  "Satın alınabilir paket bulunamadı. Biraz sonra tekrar dene.":
      "ไม่มีแพ็กเกจให้ซื้อ ลองอีกครั้งภายหลัง",
  "Deneme uygunluğu ve son ödeme koşulları Google Play ekranında gösterilir.":
      "คุณสมบัติการทดลองใช้ฟรีและเงื่อนไขการชำระเงินสุดท้ายจะแสดงใน Google Play",
  "Geri yükleme için biraz bekle": "รอก่อนกู้คืนอีกครั้ง",
  "Satın alımları geri yükle": "กู้คืนการซื้อ",
  "Google hesabı": "บัญชี Google",
  "Çıkış yap": "ออกจากระบบ",
  "Google Play aboneliğini yönet / iptal et":
      "จัดการ / ยกเลิกการสมัคร Google Play",
  "Gizlilik politikası": "นโยบายความเป็นส่วนตัว",
  "Kullanım şartları": "ข้อกำหนดการใช้งาน",
  "Sık Sorulan Sorular": "คำถามที่พบบ่อย",
  "Yanıtları görmek için bir soruya dokun.": "แตะคำถามเพื่อดูคำตอบ",
  "Süresiz erişim aktif": "สิทธิ์ตลอดชีพใช้งานได้",
  "Kalan deneme: {0}": "เวลาทดลองที่เหลือ: {0}",
  "Mağaza denemesi aktif": "การทดลองผ่านร้านค้าใช้งานได้",
  "Deneme süresi sona erdi": "สิ้นสุดการทดลองแล้ว",
  "Erişim doğrulaması gerekiyor": "ต้องยืนยันสิทธิ์ใช้งาน",
  "Paketleri ve erişim durumunu görüntüle": "ดูแพ็กเกจและสถานะสิทธิ์",
  "Hesabın, Premium erişimin ve uygulama ayarların. Yenilemek için aşağı çek.":
      "บัญชี สิทธิ์ Premium และการตั้งค่าแอปของคุณ ดึงลงเพื่อรีเฟรช",
  "Oyununa kaldığın yerden devam et": "เล่นต่อจากจุดเดิม",
  "Google hesabın": "บัญชี Google ของคุณ",
  "Deneme ve hesap işlemleri için Google hesabınla giriş yap.":
      "ลงชื่อเข้าใช้ด้วยบัญชี Google เพื่อทดลองและจัดการบัญชี",
  "Google ile giriş yap": "ลงชื่อเข้าใช้ด้วย Google",
  "Aboneliğim": "การสมัครของฉัน",
  "Hediye kodunu kullan": "ใช้รหัสของขวัญ",
  "Google Play hediye veya promosyon kodu":
      "รหัสของขวัญหรือโปรโมชัน Google Play",
  "Tekrar denemeden önce kısa bir süre bekle.": "รอสักครู่ก่อนลองอีกครั้ง",
  "Önceki satın alımlarını Google Play’den geri getir.":
      "กู้คืนการซื้อเดิมจาก Google Play",
  "PS5 bulundu. Eşleştirme için 8 haneli konsol PIN’ini gir.":
      "พบ PS5 แล้ว ป้อน PIN 8 หลักของคอนโซลเพื่อจับคู่",
  "PS5 kayıt işlemi başlatılıyor…": "กำลังเริ่มลงทะเบียน PS5…",
  "PS5 kaydı başarılı.\n{0}": "ลงทะเบียน PS5 สำเร็จ\n{0}",
  "Kayıt sonucu alınamadı.": "ไม่ได้รับผลการลงทะเบียน",
  "{0}\nHata kodu: {1}": "{0}\nรหัสข้อผิดพลาด: {1}",
  "PS5 kaydı başarısız.": "ลงทะเบียน PS5 ไม่สำเร็จ",
  "Beklenmeyen hata: {0}": "ข้อผิดพลาดที่ไม่คาดคิด: {0}",
  "PS5 bağlantısı hazır!": "การเชื่อมต่อ PS5 พร้อมแล้ว!",
  "{0} başarıyla eşleştirildi.\n\nArtık ana menüden çeviriyi başlatabilirsin.":
      "จับคู่ {0} สำเร็จ\n\nเริ่มแปลจากหน้าหลักได้แล้ว",
  "PS5 Bağlantısı": "การเชื่อมต่อ PS5",
  "Adım 2/2": "ขั้นตอน 2/2",
  "PS5 konsolunu kaydet": "ลงทะเบียน PS5",
  "Telefon ve PS5 aynı yerel ağda olmalı. PS5 IP adresini konsolun ağ ayarlarında bulabilirsin.":
      "โทรศัพท์และ PS5 ต้องอยู่ในเครือข่ายท้องถิ่นเดียวกัน ดูที่อยู่ IP ของ PS5 ได้ในการตั้งค่าเครือข่ายคอนโซล",
  "PS5’te bağladığın PSN hesabına geç. Ayarlar → Sistem → Uzaktan Oynatma → Uzaktan Oynatmayı Etkinleştir seçeneğini aç. Ardından Cihazı Eşleştir ile aldığın 8 haneli kodu aşağıya gir.":
      "สลับไปยังบัญชี PSN ที่ผูกไว้บน PS5 ไปที่ การตั้งค่า → ระบบ → Remote Play → เปิดใช้ Remote Play จากนั้นเลือกจับคู่อุปกรณ์แล้วป้อนรหัส 8 หลักด้านล่าง",
  "Kayıtlı PS5: {0}": "PS5 ที่ลงทะเบียน: {0}",
  "PS5 kayıtlı": "ลงทะเบียน PS5 แล้ว",
  "Remote Play ekranını aç": "เปิดหน้าจอ Remote Play",
  "Yerel ağ taranıyor…": "กำลังสแกนเครือข่ายท้องถิ่น…",
  "Ağda PS5 ara": "ค้นหา PS5 ในเครือข่าย",
  "PS5 bulunamazsa IP adresini elle yazabilirsin.":
      "หากไม่พบ PS5 คุณสามารถป้อนที่อยู่ IP เองได้",
  "PS5 IPv4 adresini gir.": "ป้อนที่อยู่ IPv4 ของ PS5",
  "Geçerli bir IPv4 adresi gir.": "ป้อนที่อยู่ IPv4 ที่ถูกต้อง",
  "Eşleştirmeden önce PSN hesabını doğrula. Account ID uygulamada güvenli olarak alınır.":
      "ยืนยันบัญชี PSN ก่อนจับคู่ แอปจะรับ Account ID อย่างปลอดภัย",
  "PSN hesabını doğrula": "ยืนยันบัญชี PSN",
  "PSN hesabı doğrulandı": "ยืนยันบัญชี PSN แล้ว",
  "Uzaktan erişim PIN kodu": "PIN สำหรับเข้าถึงระยะไกล",
  "PIN kodu 8 rakam olmalı.": "PIN ต้องมี 8 หลัก",
  "PS5 bağlantısını başlat": "เริ่มเชื่อมต่อ PS5",
  "OCR bekliyor": "กำลังรอ OCR",
  "Arka plan dönüşü için Remote Play yeniden kuruluyor.":
      "กำลังกู้คืน Remote Play หลังกลับจากการทำงานเบื้องหลัง",
  "Bağlandı": "เชื่อมต่อแล้ว",
  "PS5 kullanıcı giriş PIN’i gerekiyor": "ต้องใช้ PIN เข้าสู่ระบบผู้ใช้ PS5",
  "Konsol kullanıcı PIN ekranını bekliyor. Bu uygulamada PIN girişi henüz eklenmedi.":
      "คอนโซลกำลังรอ PIN ของผู้ใช้ แอปนี้ยังไม่รองรับการป้อน PIN",
  "Bağlantı kesildi": "ตัดการเชื่อมต่อแล้ว",
  "already in use": "กำลังถูกใช้งานอยู่",
  "yüzey": "พื้นที่แสดงภาพ",
  "arka plan": "เบื้องหลัง",
  "Bağlantı hatası": "ข้อผิดพลาดการเชื่อมต่อ",
  "kopya {0} ms, kırpma {1} ms, filtre {2} ms, OCR {3} ms (güven {4}) , {5}×{6}":
      "คัดลอก {0} มิลลิวินาที ตัดภาพ {1} มิลลิวินาที กรอง {2} มิลลิวินาที OCR {3} มิลลิวินาที (ความเชื่อมั่น {4}) {5}×{6}",
  "kıyas": "เปรียบเทียบ",
  "Çeviri erişimi sona erdi veya doğrulanamadı. Premium ekranını kontrol et.":
      "สิทธิ์แปลสิ้นสุดแล้วหรือยืนยันไม่ได้ ตรวจสอบหน้า Premium",
  "Altyazı ayarları kaydedilemedi: {0}": "บันทึกการตั้งค่าคำบรรยายไม่ได้: {0}",
  "Altyazı ayarları kaydedildi.": "บันทึกการตั้งค่าคำบรรยายแล้ว",
  "Remote Play açık değil": "Remote Play ไม่ได้ทำงานอยู่",
  "Seçili alan tek karede taranıyor…":
      "กำลังสแกนพื้นที่ที่เลือกจากภาพหนึ่งเฟรม…",
  "Seçili alan sıfırlandı ve kaydedildi.": "รีเซ็ตและบันทึกพื้นที่ที่เลือกแล้ว",
  "Tam ortaya hizala · %50": "จัดกึ่งกลาง · 50%",
  "Bu ölçü için konum sabit.": "ตำแหน่งถูกกำหนดตายตัวสำหรับขนาดนี้",
  "Arka plan konumu ve boyutu": "ตำแหน่งและขนาดพื้นหลัง",
  "Konum ve boyut": "ตำแหน่งและขนาด",
  "Tümünü ortala": "จัดทั้งหมดไว้กึ่งกลาง",
  "Alanı sürükleyebilir veya değerleri hassas biçimde ayarlayabilirsin.":
      "ลากพื้นที่หรือปรับค่าละเอียดได้",
  "Yatay merkez": "กึ่งกลางแนวนอน",
  "Dikey merkez": "กึ่งกลางแนวตั้ง",
  "Genişlik": "ความกว้าง",
  "Yükseklik": "ความสูง",
  "Remote Play bağlantısı korunuyor; görüntü yüzeyi yenileniyor.":
      "Remote Play ยังเชื่อมต่ออยู่ กำลังรีเฟรชพื้นที่แสดงภาพ",
  "Canlı oyun görüntüsü bağlantı kurulunca görünür.":
      "ภาพเกมสดจะแสดงเมื่อเชื่อมต่อแล้ว",
  "Altyazı alanı": "พื้นที่คำบรรยาย",
  "Arka plan alanı": "พื้นที่พื้นหลัง",
  "OCR alanı": "พื้นที่ OCR",
  "Altyazı önizlemesi": "ตัวอย่างคำบรรยาย",
  "Önizleme üzerinde hangi alanı ayarlayacaksın?":
      "ต้องการปรับพื้นที่ใดในตัวอย่าง?",
  "Altyazı yeri": "ตำแหน่งคำบรรยาย",
  "Turkuaz çerçeveler çevirinin gösterileceği yerlerdir. Her alanı seçip görüntüde taşıyabilir ve boyutlandırabilirsin.":
      "กรอบสีฟ้าอมเขียวระบุตำแหน่งแสดงคำแปล เลือกแต่ละพื้นที่เพื่อย้ายและปรับขนาดในตัวอย่าง",
  "Sarı çerçeve oyundaki yazının taranacağı OCR alanıdır.":
      "กรอบสีเหลืองคือพื้นที่ OCR สำหรับสแกนข้อความในเกม",
  "Altyazı {0}": "คำบรรยาย {0}",
  "Altyazı alanı ekle": "เพิ่มพื้นที่คำบรรยาย",
  "Seçili alanı sil": "ลบพื้นที่ที่เลือก",
  "SARI ALANLAR • OCR NEREDEN OKUSUN?": "พื้นที่สีเหลือง • ให้ OCR อ่านตรงไหน?",
  "Oyun görüntüsünde metnin bulunduğu yeri seç. OCR yalnızca seçtiğin alanları tarar. Her alanı ayrı taşıyıp boyutlandırabilirsin.":
      "เลือกพื้นที่ที่มีข้อความในเกม OCR จะสแกนเฉพาะพื้นที่ที่เลือก คุณย้ายและปรับขนาดแต่ละพื้นที่แยกกันได้",
  "OCR alanı ekle": "เพิ่มพื้นที่ OCR",
  "Seçili OCR alanını sil": "ลบพื้นที่ OCR ที่เลือก",
  "TURKUAZ KUTULAR • ALTYAZILAR NEREDE GÖRÜNSÜN?":
      "กรอบสีฟ้าอมเขียว • ให้แสดงคำบรรยายตรงไหน?",
  "Her turkuaz alan aynı çevrilmiş altyazıyı seçtiğin konumda gösterir. OCR alanlarından bağımsızdır; birden fazla yere ekleyebilirsin.":
      "แต่ละพื้นที่สีฟ้าอมเขียวจะแสดงคำแปลเดียวกันในตำแหน่งที่คุณเลือก พื้นที่คำบรรยายแยกจากพื้นที่ OCR และเพิ่มได้หลายพื้นที่",
  "OCR ipucu: Oyun ayarları izin veriyorsa İngilizce altyazının arka planını açıp opaklığını artır. Koyu zemin ve açık renk yazı, metnin daha net okunmasına ve çevirinin iyileşmesine yardımcı olabilir.":
      "เคล็ดลับ OCR: หากเกมรองรับ ให้เปิดพื้นหลังคำบรรยายอังกฤษและเพิ่มความทึบ ตัวอักษรสีอ่อนบนพื้นหลังเข้มช่วยให้อ่านข้อความได้ชัดและอาจแปลได้ดีขึ้น",
  "Altyazı kutusunu sıfırla": "รีเซ็ตกรอบคำบรรยาย",
  "Seçili OCR alanını sıfırla": "รีเซ็ตพื้นที่ OCR ที่เลือก",
  "Son OCR: {0}\n{1}": "OCR ล่าสุด: {0}\n{1}",
  "Ham/filtreli OCR kıyasla": "เปรียบเทียบ OCR ภาพต้นฉบับ / ภาพที่กรองแล้ว",
  "OCR tarama sıklığı: {0}": "ความถี่สแกน OCR: {0}",
  "Düşük değer daha az pil harcar; metni daha geç yakalayabilir.":
      "ค่าต่ำใช้แบตเตอรี่น้อยลง แต่อาจตรวจพบข้อความช้าลง",
  "OCR {0} diyalog filtresi": "ตัวกรองบทสนทนา OCR {0}",
  "Konuşmacı adı, cümle yapısı ve konuma göre diyalog benzeri satırları seçer.":
      "เลือกบรรทัดที่คล้ายบทสนทนาโดยดูจากชื่อผู้พูด โครงสร้างประโยค และตำแหน่ง",
  "Kapalı: seçili OCR alanındaki tüm metinler tanınır.":
      "ปิด: อ่านข้อความทั้งหมดในพื้นที่ OCR ที่เลือก",
  "Çeviriyi İngilizce altyazının üstünde göster": "แสดงคำแปลทับคำบรรยายอังกฤษ",
  "Açık: çeviri, okunan İngilizce metnin tam üstünde çıkar; art arda konuşan kişiler ayrı ayrı, düğme ipuçları (SEÇ, GERİ…) her biri kendi yazısının üstünde gösterilir ve oyundaki düğme simgeleri görünür kalır. Bu alanın sabit altyazı konumu kullanılmaz.":
      "เปิด: แสดงคำแปลตรงข้อความอังกฤษที่อ่านได้ ผู้พูดต่อเนื่องจะแยกกัน และคำแนะนำปุ่ม (เลือก ย้อนกลับ…) จะทับบนป้ายของตนโดยยังแสดงไอคอนปุ่มในเกม ไม่ใช้ตำแหน่งคำบรรยายคงที่ของพื้นที่นี้",
  "Kapalı: çeviri, Altyazı {0} için seçtiğin sabit yerde gösterilir.":
      "ปิด: แสดงคำแปลในตำแหน่งคงที่ที่เลือกไว้สำหรับคำบรรยาย {0}",
  "Altyazı {0} İngilizce metnin üstünde": "คำบรรยาย {0} แสดงทับข้อความอังกฤษ",
  "Çeviri, OCR {0} alanının okuduğu İngilizce metnin tam üstünde görünür ve onunla birlikte yer değiştirir; art arda konuşan kişiler ayrı kutularda, düğme ipuçları tek tek gösterilir. Bu yüzden sabit konum ayarı kapalı. Yazı boyutu, renk ve arka plan ayarları geçerli.":
      "คำแปลจะแสดงทับข้อความอังกฤษที่ OCR {0} อ่านได้และเคลื่อนตาม ผู้พูดต่อเนื่องจะแยกกล่อง ส่วนคำแนะนำปุ่มจะแสดงทับทีละรายการ จึงปิดการกำหนดตำแหน่งคงที่ แต่ยังใช้การตั้งค่าขนาด สี และพื้นหลัง",
  "Sabit konuma dön": "กลับไปใช้ตำแหน่งคงที่",
  "Altyazı {0}, OCR {1} alanıyla birlikte taşınsın":
      "ย้ายคำบรรยาย {0} ตามพื้นที่ OCR {1}",
  "Açıkken altyazı OCR alanının tam üstünde durur ve onu taşıdıkça o da taşınır. Altyazı kutusunu elle taşırsan kendi yerinde kalır.":
      "เมื่อเปิด คำบรรยายจะอยู่ตรงพื้นที่ OCR และเคลื่อนตาม หากย้ายกล่องคำบรรยายเอง กล่องจะอยู่ในตำแหน่งของตน",
  "OCR {0} görüntü ön işlemesi": "การประมวลผลภาพก่อนอ่าน OCR {0}",
  "Ham görüntü": "ภาพต้นฉบับ",
  "Gri tonlama + kontrast": "ระดับสีเทา + คอนทราสต์",
  "Adaptif eşikleme": "แยกขาวดำแบบปรับตามภาพ",
  "Kenar keskinleştirme": "เพิ่มความคมชัดขอบ",
  "Yerel kontrast (ışık/parlama)": "คอนทราสต์เฉพาะจุด (แสง / แสงสะท้อน)",
  "Hassas eşik · açık yazı": "แยกขาวดำละเอียด · ตัวอักษรสีอ่อน",
  "Hassas eşik · koyu yazı": "แยกขาวดำละเอียด · ตัวอักษรสีเข้ม",
  "Hassas eşik · otomatik yön": "แยกขาวดำละเอียด · เลือกแบบอัตโนมัติ",
  "Sarı yazı · mavi/soğuk zemin":
      "ตัวอักษรสีเหลือง · พื้นหลังสีน้ำเงิน / โทนเย็น",
  "Otomatik renk kanalı": "ช่องสีอัตโนมัติ",
  "OCR görüntü ön işlemesi": "การประมวลผลภาพก่อนอ่าน OCR",
  "Yalnızca seçili OCR kırpımına uygulanır. Otomatik renk kanalı her karede kırpımdaki RGB kanallarının kontrastını ölçüp o sahnede en çok ayrım sağlayanı seçer; farklı yazı ve arka plan renklerine uyum sağlamayı dener. Sarı yazı seçeneği yalnızca sarı yazı/mavi-soğuk zemin içindir.":
      "ใช้เฉพาะส่วนภาพ OCR ที่เลือก ช่องสีอัตโนมัติจะวัดคอนทราสต์ของช่อง RGB ในแต่ละเฟรมและเลือกช่องที่แยกข้อความได้ชัดที่สุด เพื่อปรับตามสีข้อความและพื้นหลัง ตัวเลือกตัวอักษรสีเหลืองใช้กับตัวอักษรเหลืองบนพื้นหลังน้ำเงินหรือโทนเย็นเท่านั้น",
  "OCR alanı büyütme": "ขยายภาพพื้นที่ OCR",
  "1× · hızlı": "1× · เร็ว",
  "2× · küçük yazı": "2× · ตัวอักษรเล็ก",
  "Ölçek uygulamadan seçilir ve yalnızca OCR kırpımına uygulanır; oyun görüntüsü değişmez. 1× en hızlısı, 1,5× genelde dengeli seçim, 2× küçük karakterler içindir. 1600 piksel genişlik sınırı korunur.":
      "เลือกอัตราขยายในแอปและใช้เฉพาะส่วนภาพ OCR โดยไม่เปลี่ยนภาพเกม 1× เร็วที่สุด 1.5× มักสมดุล และ 2× เหมาะกับตัวอักษรเล็ก ยังคงจำกัดความกว้างไว้ที่ 1600 พิกเซล",
  "OCR alanı boş kalırsa tut: {0} sn":
      "คงคำบรรยายเมื่อพื้นที่ OCR ว่าง: {0} วินาที",
  "Metin yenilenmezse gizle: {0} sn": "ซ่อนหากข้อความไม่อัปเดต: {0} วินาที",
  "OCR alanında yeni metin algılanmazsa altyazı seçtiğin süre sonunda gizlenir.":
      "หากไม่พบข้อความใหม่ในพื้นที่ OCR คำบรรยายจะซ่อนหลังเวลาที่เลือก",
  "Altyazı {0} genişliği: {1}%": "ความกว้างคำบรรยาย {0}: {1}%",
  "Altyazı {0} yüksekliği: {1}%": "ความสูงคำบรรยาย {0}: {1}%",
  "Yazı boyutu: {0}": "ขนาดตัวอักษร: {0}",
  "Arka plan saydamlığı: {0}%": "ความโปร่งใสพื้นหลัง: {0}%",
  "Saydamlık %0 iken arka plan tamamen opaktır. Saydamlık %100 iken arka plan tamamen görünmez olur.":
      "ที่ความโปร่งใส 0% พื้นหลังจะทึบทั้งหมด ที่ 100% พื้นหลังจะมองไม่เห็น",
  "Arka plan kutusu": "กล่องพื้นหลัง",
  "Yalnızca yazı kadar": "พอดีกับข้อความ",
  "Seçili alanı doldur": "เต็มพื้นที่ที่เลือก",
  "Arka plan yazıyla birlikte büyüyüp küçülür.":
      "พื้นหลังจะขยายและหดตามข้อความ",
  "Arka plan turkuaz alanın tamamını doldurur. Kutuyu sürükleyebilir, kenarlarından boyutlandırabilir veya alan ayarlarını kullanabilirsin.":
      "พื้นหลังเต็มพื้นที่สีฟ้าอมเขียว ลากกล่อง ปรับขนาดจากขอบ หรือใช้ตัวควบคุมพื้นที่ได้",
  "Arka plan alanını ayarla": "ปรับพื้นที่พื้นหลัง",
  "Arka plan rengi": "สีพื้นหลัง",
  "Özel arka plan rengi seç": "เลือกสีพื้นหลังเอง",
  "Yazı rengi": "สีตัวอักษร",
  "Özel yazı rengi seç · #{0}": "เลือกสีตัวอักษรเอง · #{0}",
  "Hizalama ve kalınlık": "การจัดแนวและความหนา",
  "Sola hizala": "ชิดซ้าย",
  "Kalın": "ตัวหนา",
  "Normal": "ปกติ",
  "Renk seç · #{0}": "เลือกสี · #{0}",
  "Parlaklık": "ความสว่าง",
  "Rengi uygula": "ใช้สีนี้",
  "Anladım": "เข้าใจแล้ว",
  "Görüntü alanı hazırlanıyor…": "กำลังเตรียมพื้นที่แสดงภาพ…",
  "Görüntü alanı hazır değil": "พื้นที่แสดงภาพยังไม่พร้อม",
  "Remote Play görüntüsü oluşturulamadı. Ekranı yenileyip tekrar dene.":
      "สร้างภาพ Remote Play ไม่ได้ รีเฟรชหน้าจอแล้วลองอีกครั้ง",
  "Bağlantı başlatılamadı": "เริ่มการเชื่อมต่อไม่ได้",
  "Remote Play yeniden bağlanıyor… {0} sn. Lütfen bekleyin ({1}/4)":
      "กำลังเชื่อมต่อ Remote Play ใหม่… {0} วินาที โปรดรอ ({1}/4)",
  "PS5 bağlantısı kapatılıyor…": "กำลังปิดการเชื่อมต่อ PS5…",
  "PS5 Remote Play": "PS5 Remote Play",
  "Görüntü gizli • Remote Play ve OCR çalışıyor":
      "ซ่อนภาพอยู่ • Remote Play และ OCR ยังทำงาน",
  "Görüntüyü göster": "แสดงภาพ",
  "Mobil görüntüyü gizle": "ซ่อนภาพบนมือถือ",
  "Çeviri hazırlanıyor…": "กำลังเตรียมการแปล…",
  "Deneme bitti": "สิ้นสุดการทดลองแล้ว",
  "Ana kullanıcıda oynamak için Remote Play oturumunu açık tut. PS5’e bağlı kumandada PS tuşuna basıp ana kullanıcıyı seç; Remote Play hesabından çıkma veya bağlantıyı kesme.":
      "เปิดเซสชัน Remote Play ค้างไว้เพื่อเล่นด้วยผู้ใช้หลัก กดปุ่ม PS บนคอนโทรลเลอร์ที่เชื่อมต่อ PS5 แล้วเลือกผู้ใช้หลัก อย่าออกจากบัญชี Remote Play หรือตัดการเชื่อมต่อ",
  "Altyazı alanlarını ve ayarlarını aç": "เปิดพื้นที่และการตั้งค่าคำบรรยาย",
  "Bağlantı kesiliyor…": "กำลังตัดการเชื่อมต่อ…",
  "PS5 yeniden denenecek…": "จะลองเชื่อมต่อ PS5 อีกครั้ง…",
  "Çeviriyi durdur": "หยุดแปล",
  "PS5’e bağlan": "เชื่อมต่อ PS5",
  "PS5 kaydı siliniyor…": "กำลังลบการลงทะเบียน PS5…",
  "Bağlantıyı kes, kayıtları sil ve çık": "ตัดการเชื่อมต่อ ลบข้อมูล และออก",
  "Doğrulama başarılı. PS5 konsolunu bağlamak için sonraki adıma devam et.":
      "ยืนยันสำเร็จ ไปยังขั้นตอนถัดไปเพื่อเชื่อมต่อ PS5",
  "Güvenli bağlantı doğrulanıyor…": "กำลังยืนยันการเชื่อมต่อที่ปลอดภัย…",
  "PSN Account ID alınıyor…": "กำลังรับ Account ID ของ PSN…",
  "Tarayıcı açılamadı. Lütfen tekrar dene.":
      "เปิดเบราว์เซอร์ไม่ได้ ลองอีกครั้ง",
  "PSN giriş sayfası açılamadı.": "เปิดหน้าลงชื่อเข้าใช้ PSN ไม่ได้",
  "Panoda yapıştırılacak bir bağlantı yok.": "ไม่มีลิงก์ในคลิปบอร์ดให้วาง",
  "Panodaki bağlantı okunamadı. Tekrar dene.":
      "อ่านลิงก์จากคลิปบอร์ดไม่ได้ ลองอีกครั้ง",
  "URL içinde geçerli bir authorization code bulunamadı. Yönlendirme URL’sini kontrol et.":
      "ไม่พบรหัสอนุญาตที่ถูกต้องใน URL ตรวจสอบ URL เปลี่ยนเส้นทาง",
  "Sony hesabı doğrulanıyor…": "กำลังยืนยันบัญชี Sony…",
  "PSN hesabı doğrulanamadı. Tekrar dene.":
      "ยืนยันบัญชี PSN ไม่ได้ ลองอีกครั้ง",
  "PSN doğrulaması başarısız.": "ยืนยัน PSN ไม่สำเร็จ",
  "PSN Hesap Bağlantısı": "การเชื่อมต่อบัญชี PSN",
  "Adım 1/2": "ขั้นตอน 1/2",
  "PSN hesabını bağla": "เชื่อมต่อบัญชี PSN",
  "PSN giriş sayfasını tarayıcıda aç. Giriş yaptıktan sonra \"redirect\" yazan beyaz bir sayfa açılır. Bu sayfa açıkken tarayıcının adres çubuğundaki bağlantının tamamını kopyalayıp buraya yapıştır. Sayfadaki yazıyı değil, adres çubuğundaki linki kopyala.":
      "เปิดหน้าลงชื่อเข้าใช้ PSN ในเบราว์เซอร์ หลังลงชื่อเข้าใช้จะมีหน้าสีขาวที่เขียนว่า “redirect” ขณะอยู่หน้านั้น ให้คัดลอกลิงก์ทั้งหมดจากแถบที่อยู่แล้ววางที่นี่ คัดลอกลิงก์ในแถบที่อยู่ ไม่ใช่ข้อความบนหน้าเว็บ",
  "Bu bağlantı için yeni bir PSN hesabı oluştur veya şu anda kullanmadığın bir hesabı bağla, ana hesabını bağlama. Bağlayacağın PSN hesabı PlayStation 5’te de kullanıcı olarak ekli olmalı. Ana hesaptan oyunu oynayacaksın.":
      "สร้างบัญชี PSN ใหม่หรือใช้บัญชีที่คุณไม่ได้ใช้อยู่ อย่าเชื่อมต่อบัญชีหลัก บัญชีที่เชื่อมต่อต้องถูกเพิ่มเป็นผู้ใช้บน PlayStation 5 ด้วย คุณจะเล่นเกมด้วยบัญชีหลัก",
  "Tarayıcı açılıyor...": "กำลังเปิดเบราว์เซอร์…",
  "PSN ile giriş yap": "ลงชื่อเข้าใช้ด้วย PSN",
  "Yönlendirme URL’si": "URL เปลี่ยนเส้นทาง",
  "Yapıştır": "วาง",
  "PSN doğrulanıyor…": "กำลังยืนยัน PSN…",
  "Sonraki adım: PS5 konsolunu bağla": "ขั้นตอนถัดไป: เชื่อมต่อ PS5",
  "Yardım": "ความช่วยเหลือ",
  "Bağlantı ve çeviri hakkında yanıtlar": "คำตอบเรื่องการเชื่อมต่อและการแปล",
  "Tamamladığın adımları yeniden incele": "ทบทวนขั้นตอนที่ทำเสร็จแล้ว",
  "Bize e-posta gönder": "ส่งอีเมลหาเรา",
  "Uygulama hakkında": "เกี่ยวกับแอป",
  "Sürüm": "เวอร์ชัน",
  "İlerleme bu telefonda saklanır. Konsol veya TV bağlantısını kaldırırsan ilgili adımı yeniden tamamlaman gerekir.":
      "บันทึกความคืบหน้าบนโทรศัพท์เครื่องนี้ หากลบการเชื่อมต่อคอนโซลหรือทีวี จะต้องทำขั้นตอนนั้นอีกครั้ง",
  "Kurulum adımları": "ขั้นตอนตั้งค่า",
  "Adımları sırayla uygula. Tamamladıklarını işaretle; uygulama bağlantı adımlarını kendisi de tanır.":
      "ทำตามขั้นตอนตามลำดับและทำเครื่องหมายขั้นตอนที่เสร็จ แอปจะตรวจจับขั้นตอนการเชื่อมต่อโดยอัตโนมัติด้วย",
  "Kurulum videosu": "วิดีโอตั้งค่า",
  "Video hazır olduğunda burada görünecek": "วิดีโอจะแสดงที่นี่เมื่อพร้อม",
  "Videoyu izle": "ดูวิดีโอ",
  "PS5 kurulumunu aç": "เปิดการตั้งค่า PS5",
  "TV eşleştirmeyi aç": "เปิดการจับคู่ทีวี",
  "{0} varsayılan profil seçildi.": "เลือก {0} เป็นโปรไฟล์เริ่มต้นแล้ว",
  "Bu isimde bir oyun profili zaten var.": "มีโปรไฟล์เกมชื่อนี้แล้ว",
  "Altyazı ayarları": "การตั้งค่าคำบรรยาย",
  "Oyun profili ekle": "เพิ่มโปรไฟล์เกม",
  "Henüz oyun profili yok. Her oyun için OCR alanlarını ve altyazı görünümünü ayrı kaydedebilirsin.":
      "ยังไม่มีโปรไฟล์เกม บันทึกพื้นที่ OCR และรูปแบบคำบรรยายแยกสำหรับแต่ละเกมได้",
  "İlk profili oluştur": "สร้างโปรไฟล์แรก",
  "Bir oyun profilini açıp OCR ve altyazı konumunu ayrı ayrı düzenle. Yıldızlı profil uygulama açılışında varsayılan olarak kullanılır.":
      "เปิดโปรไฟล์เกมเพื่อปรับตำแหน่ง OCR และคำบรรยายแยกกัน โปรไฟล์ที่ติดดาวจะใช้เป็นค่าเริ่มต้นเมื่อเปิดแอป",
  "{0} → {1} · {2} OCR alanı": "{0} → {1} · {2} พื้นที่ OCR",
  "Varsayılan profil": "โปรไฟล์เริ่มต้น",
  "Uygulama açılışında varsayılan yap": "ใช้เป็นค่าเริ่มต้นเมื่อเปิดแอป",
  "Oyun profili oluştur": "สร้างโปรไฟล์เกม",
  "Oyun adı": "ชื่อเกม",
  "Oluştur": "สร้าง",
  "Devam eden işlemin tamamlanmasını bekle.":
      "รอให้การดำเนินการปัจจุบันเสร็จสิ้น",
  "Tekrar denemek için {0} saniye bekle.": "รอ {0} วินาทีก่อนลองอีกครั้ง",
  "Satın alma sistemi şu anda Android için kullanılabilir.":
      "ขณะนี้รองรับการซื้อบน Android",
  "Satın alma hizmeti henüz kullanıma hazır değil.": "บริการซื้อยังไม่พร้อม",
  "Satın alma durumu alınamadı.": "ดึงสถานะการซื้อไม่ได้",
  "Google hesabı doğrulanamadı.": "ยืนยันบัญชี Google ไม่ได้",
  "Deneme başlatılamadı.": "เริ่มการทดลองไม่ได้",
  "Hesabını silmek için önce giriş yap.": "ลงชื่อเข้าใช้ก่อนลบบัญชี",
  "Uygulamadaki hesabın silindi. Oturum temizliği tamamlanamadı; uygulamayı kapatıp yeniden aç.":
      "ลบบัญชีแอปแล้ว แต่ล้างเซสชันออกจากระบบไม่เสร็จ ปิดแล้วเปิดแอปใหม่",
  "Oturumun değişti. Hesap silme işlemini yeniden başlat.":
      "เซสชันเปลี่ยนไป เริ่มลบบัญชีใหม่อีกครั้ง",
  "Google hesabı doğrulanamadı. Hesabın silinmedi.":
      "ยืนยันบัญชี Google ไม่ได้ บัญชียังไม่ถูกลบ",
  "Abonelik planı yüklenemedi. Paketleri yenileyip tekrar dene.":
      "โหลดแพ็กเกจสมาชิกไม่ได้ รีเฟรชแพ็กเกจแล้วลองอีกครั้ง",
  "Satın alma yanıtı doğrulanamadı. Satın alımları geri yüklemeyi dene.":
      "ยืนยันคำตอบการซื้อไม่ได้ ลองกู้คืนการซื้อ",
  "Google Play satın alımın bulundu ancak Premium erişimin doğrulanamadı. Yeniden ödeme yapma. Satın alımları geri yükle veya destekle iletişime geç.":
      "พบการซื้อ Google Play แล้ว แต่ยืนยันสิทธิ์ Premium ไม่ได้ อย่าจ่ายซ้ำ ให้กู้คืนการซื้อหรือติดต่อฝ่ายสนับสนุน",
  "Aktif satın alma bulunamadı. Ödeme bekliyorsa tamamlandıktan sonra tekrar dene.":
      "ไม่พบการซื้อที่ใช้งานอยู่ หากกำลังรอชำระเงิน ให้ลองอีกครั้งเมื่อเสร็จ",
  "Google girişi tamamlanmadı. İptal etmediysen tekrar dene; sorun sürerse destekle iletişime geç.":
      "ลงชื่อเข้าใช้ Google ไม่เสร็จ หากไม่ได้ยกเลิกให้ลองอีกครั้ง หากปัญหายังอยู่ให้ติดต่อฝ่ายสนับสนุน",
  "Google girişi bu sürümde kullanılamıyor. Destekle iletişime geç.":
      "เวอร์ชันนี้ลงชื่อเข้าใช้ Google ไม่ได้ ติดต่อฝ่ายสนับสนุน",
  "Google hesabına giriş yapılamadı. Tekrar dene.":
      "ลงชื่อเข้าใช้ Google ไม่ได้ ลองอีกครั้ง",
  "Google hesabı doğrulanamadı. İnternet bağlantını kontrol edip tekrar dene.":
      "ยืนยันบัญชี Google ไม่ได้ ตรวจสอบอินเทอร์เน็ตแล้วลองอีกครั้ง",
  "Uygulamada giriş yaptığın Google hesabını seçerek tekrar dene.":
      "ลองอีกครั้งโดยเลือกบัญชี Google ที่ลงชื่อเข้าใช้ในแอป",
  "Hesabını silmek için yeniden giriş yapıp tekrar dene.":
      "ลงชื่อเข้าใช้อีกครั้งแล้วลองลบบัญชี",
  "Google hesabı doğrulanamadı. Tekrar giriş yapmayı dene.":
      "ยืนยันบัญชี Google ไม่ได้ ลองลงชื่อเข้าใช้ใหม่",
  "Erişim durumu alınamadı. Tekrar dene.": "ดึงสถานะสิทธิ์ไม่ได้ ลองอีกครั้ง",
  "Bu satın alım Google Play hesabında zaten aktif. Satın alımları geri yükle.":
      "การซื้อนี้ใช้งานอยู่ในบัญชี Google Play แล้ว ให้กู้คืนการซื้อ",
  "Ödemen Google Play onayı bekliyor. Tamamlandığında erişim durumunu yenile.":
      "การชำระเงินกำลังรอ Google Play อนุมัติ รีเฟรชสถานะสิทธิ์เมื่อเสร็จ",
  "Satın alma hizmetine bağlanılamadı. İnternet bağlantını kontrol edip tekrar dene.":
      "เชื่อมต่อบริการซื้อไม่ได้ ตรวจสอบอินเทอร์เน็ตแล้วลองอีกครั้ง",
  "Satın alım başka bir hesaba bağlı görünüyor. Satın aldığın Google Play hesabını kontrol et veya destekle iletişime geç.":
      "การซื้อนี้ดูเหมือนผูกกับบัญชีอื่น ตรวจสอบบัญชี Google Play ที่ใช้ซื้อหรือติดต่อฝ่ายสนับสนุน",
  "Google Play bu hesapta satın almaya izin vermiyor. Mağaza hesabını kontrol et.":
      "Google Play ไม่อนุญาตให้บัญชีนี้ซื้อ ตรวจสอบบัญชีร้านค้า",
  "Satın alma hizmeti şu anda kullanılamıyor. Destekle iletişime geç.":
      "บริการซื้อยังไม่พร้อมให้ใช้งาน ติดต่อฝ่ายสนับสนุน",
  "İşlem tamamlanamadı. Biraz sonra tekrar dene.":
      "ดำเนินการไม่สำเร็จ ลองอีกครั้งภายหลัง",
  "Hizmete bağlanılamadı. İnternet bağlantını kontrol edip tekrar dene.":
      "เชื่อมต่อบริการไม่ได้ ตรวจสอบอินเทอร์เน็ตแล้วลองอีกครั้ง",
  "Sürüm bilgisi alınamadı": "ไม่มีข้อมูลเวอร์ชัน",
  "Bağlantı henüz hazır değil. Lütfen daha sonra tekrar dene.":
      "ลิงก์นี้ยังไม่พร้อม ลองอีกครั้งภายหลัง",
  "Bağlantı açılamadı. Lütfen tekrar dene.": "เปิดลิงก์ไม่ได้ ลองอีกครั้ง",
  "E-posta uygulaması açılamadı. Bu adresten bize ulaşabilirsin:":
      "เปิดแอปอีเมลไม่ได้ ติดต่อเราได้ที่:",
  "E-posta adresi kopyalandı.": "คัดลอกอีเมลแล้ว",
  "Adresi kopyala": "คัดลอกที่อยู่",
  "Oyun kataloğu bir liste değil.": "แค็ตตาล็อกเกมไม่ได้อยู่ในรูปแบบรายการ",
  "Oyun kataloğu kaydı geçersiz.": "รายการในแค็ตตาล็อกเกมไม่ถูกต้อง",
  "Oyun kataloğunda yinelenen ID var.": "แค็ตตาล็อกเกมมี ID ซ้ำ",
  "user_id pozitif bir tam sayı olmalıdır.": "user_id ต้องเป็นจำนวนเต็มบวก",
  "user_id geçerli bir sayısal değer değil.": "user_id ไม่ใช่ตัวเลขที่ถูกต้อง",
  "TV sertifikası doğrulanamadı.": "ยืนยันใบรับรองทีวีไม่ได้",
  "TV sertifika kaydı geçersiz.": "ข้อมูลใบรับรองทีวีไม่ถูกต้อง",
  "TV adresi veya 6 haneli kod geçersiz.":
      "ที่อยู่ทีวีหรือรหัส 6 หลักไม่ถูกต้อง",
  "TV kimliği ekrandan doğrulanmalı.": "ยืนยันตัวตนทีวีจากหน้าจอ",
  "TV bağlantı denemesi iptal edildi.": "ยกเลิกการพยายามเชื่อมต่อทีวีแล้ว",
  "TV kimliği doğrulanmadı.": "ยังไม่ได้ยืนยันตัวตนทีวี",
  "User disconnected": "ผู้ใช้ตัดการเชื่อมต่อ",
  "Connection cancelled": "ยกเลิกการเชื่อมต่อแล้ว",
  "TV bağlantı güvenliği değişti.": "ความปลอดภัยของการเชื่อมต่อทีวีเปลี่ยนไป",
  "Pairing failed": "จับคู่ไม่สำเร็จ",
  "TV eşleştirme kodunu kabul etmedi.": "ทีวีปฏิเสธรหัสจับคู่",
  "TV bağlantısı eşleştirme tamamlanmadan kapandı.":
      "การเชื่อมต่อทีวีปิดลงก่อนจับคู่เสร็จ",
  "Pairing stopped": "หยุดการจับคู่แล้ว",
  "Pairing rejected": "ปฏิเสธการจับคู่",
  "Invalid pairing data": "ข้อมูลจับคู่ไม่ถูกต้อง",
  "Pairing timed out": "การจับคู่หมดเวลา",
  "Süresiz Premium aktif": "Premium ตลอดชีพใช้งานได้",
  "Premium aboneliğin aktif": "การสมัคร Premium ของคุณใช้งานได้",
  "Premium durumun değişti": "สถานะ Premium เปลี่ยนไป",
  "Premium ayrıntıları": "รายละเอียด Premium",
  "Abonelik ayrıntıları": "รายละเอียดการสมัครสมาชิก",
  "Güncel erişim durumunu ve satın alımlarını ayrıntılar ekranından kontrol edebilirsin.":
      "ตรวจสอบสถานะสิทธิ์และการซื้อปัจจุบันในหน้ารายละเอียดได้",
  "Premium çeviri özelliklerine süresiz erişimin var. Tek seferlik satın alımın için otomatik yenileme veya tekrar ödeme yok.":
      "คุณมีสิทธิ์ใช้ฟีเจอร์แปล Premium ตลอดชีพ การซื้อแบบจ่ายครั้งเดียวไม่มีการต่ออายุอัตโนมัติหรือจ่ายเพิ่ม",
  "Google Play deneme aboneliğin aktif. {0}{1}":
      "การสมัครทดลอง Google Play ของคุณใช้งานได้ {0}{1}",
  "Deneme bitişi: {0}. ": "การทดลองสิ้นสุด: {0} ",
  "Deneme sonunda ücretli olarak yenilenir.":
      "หลังทดลองจะต่ออายุเป็นการสมัครแบบชำระเงิน",
  "Otomatik yenileme kapalı.": "ปิดการต่ออายุอัตโนมัติแล้ว",
  "Premium çeviri özelliklerini kullanabilirsin.\n\n{0}{1}":
      "คุณสามารถใช้ฟีเจอร์แปล Premium ได้\n\n{0}{1}",
  "Otomatik yenileme açık.": "เปิดการต่ออายุอัตโนมัติอยู่",
  "Otomatik yenileme kapalı; mevcut dönem sonuna kadar erişimin devam eder.":
      "ปิดการต่ออายุอัตโนมัติแล้ว ใช้งานต่อได้จนหมดรอบปัจจุบัน",
  "Sonraki yenileme": "ต่ออายุครั้งถัดไป",
  "Erişim bitişi": "สิทธิ์สิ้นสุด",
  "Önce TV uygulamasını indir": "ดาวน์โหลดแอปทีวีก่อน",
  "Sistem dili": "ภาษาของระบบ",
  "Dil tercihi kaydedilemedi. Tekrar dene.":
      "บันทึกภาษาที่เลือกไม่ได้ ลองอีกครั้ง",
  "Kapat": "ปิด",
  "Tamam": "ตกลง",
  "Kaydet": "บันทึก",
  "Geri": "ย้อนกลับ",
  "Devam": "ดำเนินการต่อ",
  "Hata": "ข้อผิดพลาด",
  "Kaynak": "ต้นทาง",
  "Hedef": "ปลายทาง",
  "hafta": "สัปดาห์",
  "ay": "เดือน",
  "PS5 gerekli": "ต้องใช้ PS5",
  "PS5’i kur": "ตั้งค่า PS5",
  "Abonelik": "การสมัครสมาชิก",
  "Hesap": "บัญชี",
  "PS5 IPv4 adresi": "ที่อยู่ IPv4 ของ PS5",
  "PS5 kaydediliyor…": "กำลังลงทะเบียน PS5…",
  "Ortala": "กึ่งกลาง",
  "Ton": "เฉดสี",
  "Doygunluk": "ความอิ่มตัวของสี",
  "Oyun": "เกม",
  "indirildi": "ดาวน์โหลดแล้ว",
  "indirilmedi": "ยังไม่ได้ดาวน์โหลด",
  "{0} • indirilmedi": "{0} • ยังไม่ได้ดาวน์โหลด",
  "Dil paketi gerekli": "ต้องใช้แพ็กภาษา",
  "Model B için seçili kaynak ve hedef dil paketlerini önce indir.":
      "ดาวน์โหลดแพ็กภาษาต้นทางและปลายทางที่เลือกสำหรับ Model B ก่อน",
  "{0} Destek": "ฝ่ายสนับสนุน {0}",
  "Deneme için Google hesabınla giriş yap.":
      "ลงชื่อเข้าใช้ด้วย Google เพื่อทดลอง",
  "Hesap zamanı doğrulanamadı.": "ยืนยันเวลาของบัญชีไม่ได้",
  "Deneme kaydı geçersiz.": "ข้อมูลการทดลองไม่ถูกต้อง",
  "JSONL satır {0} okunamadı.": "อ่านบรรทัด {0} ของ JSONL ไม่ได้",
  "JSONL satır {0}: ID eksik.": "JSONL บรรทัด {0}: ไม่มี ID",
  "JSONL satır {0}: yinelenen ID {1}.": "JSONL บรรทัด {0}: ID {1} ซ้ำ",
  "HPLT modeli kapalı.": "โมเดล HPLT ปิดอยู่",
  "HPLT model.bin bulunamadı.": "ไม่พบไฟล์ model.bin ของ HPLT",
  "HPLT İngilizce sözlüğü açılamadı.": "เปิดคลังคำศัพท์อังกฤษของ HPLT ไม่ได้",
  "HPLT Türkçe sözlüğü açılamadı.": "เปิดคลังคำศัพท์ตุรกีของ HPLT ไม่ได้",
  "HPLT modeli yüklenemedi.": "โหลดโมเดล HPLT ไม่ได้",
  "OPUS-MT SentencePiece sözlüğü açılamadı":
      "เปิดคลังคำศัพท์ SentencePiece ของ OPUS-MT ไม่ได้",
  "Almanca": "ภาษาเยอรมัน",
  "Katalanca": "ภาษาคาตาลัน",
  "Fransızca": "ภาษาฝรั่งเศส",
  "İspanyolca": "ภาษาสเปน",
  "İtalyanca": "ภาษาอิตาลี",
  "Felemenkçe": "ภาษาดัตช์",
  "Yunanca": "ภาษากรีก",
  "Rusça": "ภาษารัสเซีย",
  "PSN giriş kodu kabul edilmedi. PSN ile yeniden giriş yap.":
      "รหัสลงชื่อเข้าใช้ PSN ถูกปฏิเสธ ลงชื่อเข้าใช้ PSN ใหม่",
  "Güvenlik doğrulaması tamamlanamadı. Tekrar dene.":
      "ยืนยันความปลอดภัยไม่สำเร็จ ลองอีกครั้ง",
  "Çok fazla doğrulama denemesi yapıldı. Bir dakika sonra tekrar dene.":
      "พยายามยืนยันมากเกินไป ลองอีกครั้งในอีกหนึ่งนาที",
  "PSN hesap doğrulama hizmeti henüz hazır değil.":
      "บริการยืนยันบัญชี PSN ยังไม่พร้อม",
  "PSN hesap doğrulama hizmetine ulaşılamadı. Tekrar dene.":
      "ติดต่อบริการยืนยันบัญชี PSN ไม่ได้ ลองอีกครั้ง",
  "PSN hesap yanıtı geçersiz.": "คำตอบบัญชี PSN ไม่ถูกต้อง",
  "PSN hesap doğrulama sunucusu yapılandırılmamış.":
      "ยังไม่ได้กำหนดค่าเซิร์ฟเวอร์ยืนยันบัญชี PSN",
  "Güvenlik doğrulaması zaman aşımına uğradı. Tekrar dene.":
      "การยืนยันความปลอดภัยหมดเวลา ลองอีกครั้ง",
  "Güvenlik doğrulaması için güvenli bağlantı kurulamadı.":
      "สร้างการเชื่อมต่อที่ปลอดภัยเพื่อยืนยันไม่ได้",
  "Güvenlik doğrulama sayfası açılamadı. Tekrar dene.":
      "เปิดหน้ายืนยันความปลอดภัยไม่ได้ ลองอีกครั้ง",
  "Güvenlik doğrulaması kesildi. Tekrar deneyebilirsin.":
      "การยืนยันความปลอดภัยถูกขัดจังหวะ ลองใหม่ได้",
  "Güvenlik doğrulama adresi geçersiz.": "ที่อยู่ยืนยันความปลอดภัยไม่ถูกต้อง",
  "Güvenli bağlantı": "การเชื่อมต่อที่ปลอดภัย",
  "Güvenlik doğrulaması iptal edildi. Tekrar deneyebilirsin.":
      "ยกเลิกการยืนยันความปลอดภัยแล้ว ลองใหม่ได้",
  "Konsol bilgileri güvenli depoya yazılamadı.":
      "บันทึกข้อมูลคอนโซลในที่เก็บข้อมูลที่ปลอดภัยไม่ได้",
  "Güvenli kayıt silinemedi.": "ลบข้อมูลที่บันทึกไว้อย่างปลอดภัยไม่ได้",
  "PSN Account ID güvenli depodan silinemedi.":
      "ลบ Account ID ของ PSN จากที่เก็บข้อมูลที่ปลอดภัยไม่ได้",
  "PSN Account ID 8 bayt olmalı.": "Account ID ของ PSN ต้องมีขนาด 8 ไบต์",
  "PSN Account ID güvenli depoya yazılamadı.":
      "บันทึก Account ID ของ PSN ในที่เก็บข้อมูลที่ปลอดภัยไม่ได้",
  "Kayıtlı PSN Account ID geçersiz.":
      "Account ID ของ PSN ที่บันทึกไว้ไม่ถูกต้อง",
  "Uyarı tercihi geçersiz.": "การตั้งค่าข้อความเตือนไม่ถูกต้อง",
  "Uyarı tercihi kaydedilemedi.": "บันทึกการตั้งค่าข้อความเตือนไม่ได้",
  "Kurulum işaretleri geçersiz.": "รายการตรวจสอบการตั้งค่าไม่ถูกต้อง",
  "Çeviri motoru seçimi geçersiz.": "ตัวเลือกเอนจินแปลไม่ถูกต้อง",
  "TV eşleştirme bilgileri geçersiz.": "ข้อมูลจับคู่ทีวีไม่ถูกต้อง",
  "TV eşleştirmesi kaydedilemedi.": "บันทึกการจับคู่ทีวีไม่ได้",
  "Kayıtlı PSN ve PS5 bilgileri silinemedi.":
      "ลบข้อมูล PSN และ PS5 ที่บันทึกไว้ไม่ได้",
  "Bildirim izni isteği zaten açık.": "มีคำขอสิทธิ์แจ้งเตือนเปิดอยู่แล้ว",
  "Çeviri bildirimi başlatılamadı.": "เริ่มการแจ้งเตือนการแปลไม่ได้",
  "Ekran kapalıyken çeviri": "แปลขณะปิดหน้าจอ",
  "Şimdi değil": "ไว้ภายหลัง",
  "Ayarları aç": "เปิดการตั้งค่า",
  "Bir PS5 kayıt işlemi zaten çalışıyor.": "กำลังลงทะเบียน PS5 อยู่แล้ว",
  "Güvenli PSN kaydı açılamadı. PSN hesabını yeniden doğrula.":
      "เปิดข้อมูล PSN ที่เก็บไว้อย่างปลอดภัยไม่ได้ ยืนยันบัญชี PSN ใหม่",
  "Önce PSN hesabını doğrula.": "ยืนยันบัญชี PSN ก่อน",
  "Chiaki kayıt işlemi başlatılamadı.": "เริ่มลงทะเบียน Chiaki ไม่ได้",
  "Kayıt başlatılırken hata oluştu.": "เกิดข้อผิดพลาดขณะเริ่มลงทะเบียน",
  "PS5 kaydı alındı ancak güvenli depoya yazılamadı.":
      "รับการลงทะเบียน PS5 แล้ว แต่บันทึกอย่างปลอดภัยไม่ได้",
  "Chiaki-ng PS5 kaydını tamamlayamadı. Host ve PIN bilgilerini kontrol edip yeniden dene.":
      "Chiaki-ng ลงทะเบียน PS5 ไม่สำเร็จ ตรวจสอบที่อยู่เครื่องและ PIN แล้วลองอีกครั้ง",
  "PS5 kayıt işlemi iptal edildi.": "ยกเลิกการลงทะเบียน PS5 แล้ว",
  "Kayıtlı PS5 bilgileri çözülemedi. Yeniden eşleştirmen gerekebilir.":
      "ถอดรหัสข้อมูล PS5 ที่บันทึกไว้ไม่ได้ อาจต้องจับคู่ใหม่",
  "Oyun profilleri okunamadı.": "อ่านโปรไฟล์เกมไม่ได้",
  "PS5 görüntü alanı hazır değil.": "พื้นที่แสดงภาพ PS5 ยังไม่พร้อม",
  "PS5 karesini alamadım. Remote Play görüntüsü açıkken yeniden dene.":
      "จับภาพเฟรม PS5 ไม่ได้ ลองอีกครั้งขณะเปิดภาพ Remote Play",
  "PS5 ekran görüntüsü uygulama alanına kaydedilemedi.":
      "บันทึกภาพหน้าจอ PS5 ในพื้นที่แอปไม่ได้",
  "Kayıtlı ekran görüntüsü bulunamadı.": "ไม่พบภาพหน้าจอที่บันทึกไว้",
  "Altyazı ayarları okunamadı.": "อ่านการตั้งค่าคำบรรยายไม่ได้",
  "Altyazı ayarları kaydedilemedi.": "บันทึกการตั้งค่าคำบรรยายไม่ได้",
  "Oyun seçimi kaydedilemedi.": "บันทึกเกมที่เลือกไม่ได้",
  "Oyun çeviri dosyası okunamadı.": "อ่านไฟล์คำแปลเกมไม่ได้",
  "Model C için 64-bit ARM Android gerekiyor.":
      "Model C ต้องใช้ Android แบบ ARM 64 บิต",
  "Model klasörü oluşturulamadı.": "สร้างโฟลเดอร์โมเดลไม่ได้",
  "{0} dosyası eksik veya boyutu doğrulanamadı.":
      "ไม่พบไฟล์ {0} หรือยืนยันขนาดไม่ได้",
  "{0} dosyasının SHA-256 doğrulaması başarısız.":
      "ยืนยัน SHA-256 ของไฟล์ {0} ไม่สำเร็จ",
  "Eski {0} dosyası değiştirilemedi.": "แทนที่ไฟล์ {0} เดิมไม่ได้",
  "{0} dosyası kaydedilemedi.": "บันทึกไฟล์ {0} ไม่ได้",
  "HPLT model paketi doğrulanamadı.": "ตรวจสอบแพ็กโมเดล HPLT ไม่ได้",
  "Bu çevrimdışı dil modeli henüz desteklenmiyor.":
      "ยังไม่รองรับโมเดลภาษาออฟไลน์นี้",
  "Dil seçimi okunamadı.": "อ่านภาษาที่เลือกไม่ได้",
  "Bu çevrimdışı dil henüz sunulmuyor.": "ยังไม่มีภาษาออฟไลน์นี้",
  "İndirilen model doğrulanamadı.": "ตรวจสอบโมเดลที่ดาวน์โหลดไม่ได้",
  "Çevrimdışı model dosyaları beklenen dil modeliyle uyuşmuyor.":
      "ไฟล์โมเดลออฟไลน์ไม่ตรงกับโมเดลภาษาที่คาดไว้",
  "Çevrimdışı model dosyaları eksik veya sürümleri uyuşmuyor.":
      "ไฟล์โมเดลออฟไลน์ไม่ครบหรือเวอร์ชันไม่ตรงกัน",
  "Çevrimdışı dil modeli indirilemedi.": "ดาวน์โหลดโมเดลภาษาออฟไลน์ไม่ได้",
  "Kaynak ve hedef dil seçimini kontrol et.":
      "ตรวจสอบภาษาต้นทางและปลายทางที่เลือก",
  "Çeviri dil paketleri indirilemedi. İnternet bağlantını kontrol et.":
      "ดาวน์โหลดแพ็กภาษาแปลไม่ได้ ตรวจสอบอินเทอร์เน็ต",
  "Bu çeviri dili desteklenmiyor.": "ไม่รองรับภาษาสำหรับแปลนี้",
  "Dil paketi indirilemedi. İnternet bağlantını kontrol edip yeniden dene.":
      "ดาวน์โหลดแพ็กภาษาไม่ได้ ตรวจสอบอินเทอร์เน็ตแล้วลองอีกครั้ง",
  "PSN yönlendirme kodu geçersiz.": "รหัสเปลี่ยนเส้นทาง PSN ไม่ถูกต้อง",
  "PSN hesabı zaten doğrulanıyor.": "กำลังยืนยันบัญชี PSN อยู่แล้ว",
  "Doğrulama için uygulamayı yeniden aç.": "เปิดแอปใหม่เพื่อยืนยัน",
  "PSN hesabı doğrulanamadı.": "ยืนยันบัญชี PSN ไม่ได้",
  "Hesap doğrulama sunucusundan yanıt alınamadı. Tekrar dene.":
      "ไม่มีคำตอบจากเซิร์ฟเวอร์ยืนยันบัญชี ลองอีกครั้ง",
  "Hesap doğrulama sunucusunun TLS sertifikası doğrulanamadı.":
      "ยืนยันใบรับรอง TLS ของเซิร์ฟเวอร์บัญชีไม่ได้",
  "PSN hesabı doğrulanamadı. Giriş akışını yeniden başlatıp tekrar dene.":
      "ยืนยันบัญชี PSN ไม่ได้ เริ่มลงชื่อเข้าใช้ใหม่แล้วลองอีกครั้ง",
  "Güvenlik doğrulaması açılamadı. Android System WebView'i kontrol edip tekrar dene.":
      "เปิดการยืนยันความปลอดภัยไม่ได้ ตรวจสอบ Android System WebView แล้วลองอีกครั้ง",
  "Bir Remote Play oturumu zaten açık.": "มีเซสชัน Remote Play ทำงานอยู่แล้ว",
  "Kayıtlı PS5 bilgileri okunamadı. Yeniden PS5 eşleştirmen gerekebilir.":
      "อ่านข้อมูล PS5 ที่บันทึกไว้ไม่ได้ อาจต้องจับคู่ PS5 ใหม่",
  "Önce bir PS5'i kaydet.": "ลงทะเบียน PS5 ก่อน",
  "Arka plan çeviri servisi başlatılamadı.": "เริ่มบริการแปลเบื้องหลังไม่ได้",
  "PS5 bağlantısı iptal edildi.": "ยกเลิกการเชื่อมต่อ PS5 แล้ว",
  "Chiaki oturumu başlatılamadı: {0}": "เริ่มเซสชัน Chiaki ไม่ได้: {0}",
  "Remote Play oturumu başlatılamadı.": "เริ่มเซสชัน Remote Play ไม่ได้",
  "Chiaki oturumu kapatılamadı: {0}": "ปิดเซสชัน Chiaki ไม่ได้: {0}",
  "Remote Play oturumu kapatılırken hata oluştu.":
      "เกิดข้อผิดพลาดขณะปิด Remote Play",
  "Yerel ağ keşfi başlatılamadı: {0}":
      "เริ่มค้นหาอุปกรณ์ในเครือข่ายท้องถิ่นไม่ได้: {0}",
  "Bildirim izni isteği tamamlanamadı.": "ส่งคำขอสิทธิ์แจ้งเตือนไม่สำเร็จ",
  "Çeviri modeli hazır değil": "โมเดลแปลยังไม่พร้อม",
  "OCR kapalı": "OCR ปิดอยู่",
  "Önceki OCR karesi hâlâ işleniyor": "เฟรม OCR ก่อนหน้ายังประมวลผลอยู่",
  "Video karesi henüz hazır değil": "เฟรมวิดีโอยังไม่พร้อม",
  "OCR alanı boş": "พื้นที่ OCR ว่าง",
  "Video karesi işlenemedi": "ประมวลผลเฟรมวิดีโอไม่ได้",
  "Seçili alanda metin bulunamadı": "ไม่พบข้อความในพื้นที่ที่เลือก",
  "OCR işlenemedi: {0}": "ประมวลผล OCR ไม่สำเร็จ: {0}",
  "OCR hatası": "ข้อผิดพลาด OCR",
  "Çeviri hazırlanıyor": "กำลังเตรียมการแปล",
  "Çevrildi": "แปลแล้ว",
  "Çeviri başarısız": "แปลไม่สำเร็จ",
  "Yerel çeviri paketi açılamadı": "เปิดแพ็กแปลภายในเครื่องไม่ได้",
  "HPLT modeli açılamadı": "เปิดโมเดล HPLT ไม่ได้",
  "HPLT çevirisi hazırlanıyor": "กำลังเตรียมการแปล HPLT",
  "Çevrildi · HPLT": "แปลแล้ว · HPLT",
  "HPLT çevirisi başarısız": "แปลด้วย HPLT ไม่สำเร็จ",
  "Çeviri için aktif deneme veya Premium gerekiyor.":
      "ต้องมีสิทธิ์ทดลองที่ยังไม่หมดหรือ Premium เพื่อแปล",
  "Satın alma kontrolü devam ediyor.": "กำลังยืนยันการซื้อ",
  "Hesap değişti.": "เปลี่ยนบัญชีแล้ว",
  "Satın alma durumu alınamadı. İnternete bağlanıp tekrar dene.":
      "ดึงสถานะการซื้อไม่ได้ เชื่อมต่ออินเทอร์เน็ตแล้วลองอีกครั้ง",
  "Erişim kontrolü devam ediyor.": "กำลังตรวจสอบสิทธิ์",
  "Deneme durumu alınamadı. Google girişini ve internet bağlantını kontrol et.":
      "ดึงสถานะการทดลองไม่ได้ ตรวจสอบการลงชื่อเข้าใช้ Google และอินเทอร์เน็ต",
  "Çeviri beklemede": "การแปลกำลังรอ",
  "İlk video karesi henüz alınmadı. Bildirim açık kalıyor.":
      "ยังไม่ได้รับเฟรมวิดีโอแรก การแจ้งเตือนจะยังคงแสดงอยู่",
  "Yeni video karesi yok. Görüntü gelince çeviri sürdürülecek.":
      "ไม่มีเฟรมวิดีโอใหม่ จะแปลต่อเมื่อภาพกลับมา",
  "Çeviri çalışıyor": "กำลังแปล",
  "Menüye dönmek için dokun.": "แตะเพื่อกลับไปที่เมนู",
  "Çeviri durumu": "สถานะการแปล",
  "Remote Play altyazı çevirisi": "การแปลคำบรรยาย Remote Play",
  "PS5 bağlantısı arka planda sürüyor. Menüye dönmek için dokun.":
      "PS5 ยังเชื่อมต่อในเบื้องหลัง แตะเพื่อกลับไปที่เมนู",
  "Remote Play oturumu": "เซสชัน Remote Play",
  "Durdur": "หยุด",
  "PS5’im bulunmuyor veya bağlanmıyor. Ne yapmalıyım?":
      "ไม่พบ PS5 หรือเชื่อมต่อไม่ได้ ควรทำอย่างไร?",
  "Telefon ve PS5 aynı yerel ağda olmalı; PS5 Ethernet, telefon Wi-Fi kullanabilir. Konsolu açıp Remote Play’i etkinleştir. Ağda bulunmazsa PS5’in Ayarlar → Ağ → Bağlantı Durumu bölümündeki IP adresini elle gir. Kayıtta kullandığın PSN hesabı konsolda kullanıcı olarak da ekli olmalı. Cihazı Bağla ekranındaki güncel 8 haneli PIN ile tekrar dene.":
      "โทรศัพท์และ PS5 ต้องอยู่ในเครือข่ายท้องถิ่นเดียวกัน PS5 ใช้ Ethernet และโทรศัพท์ใช้ Wi-Fi ได้ เปิดคอนโซลและ Remote Play หากค้นหาไม่พบ ให้ป้อน IP จาก การตั้งค่า → เครือข่าย → สถานะการเชื่อมต่อ บน PS5 บัญชี PSN ที่ลงทะเบียนต้องเพิ่มเป็นผู้ใช้คอนโซลด้วย ลองใหม่ด้วย PIN 8 หลักปัจจุบันจากหน้าจับคู่อุปกรณ์",
  "PS5 bağlı görünüyor ama telefondaki görüntü siyah. Ne yapmalıyım?":
      "PS5 เชื่อมต่อแล้วแต่ภาพบนโทรศัพท์เป็นสีดำ ควรทำอย่างไร?",
  "Mobil görüntüyü gizlediysen Görüntüyü göster’e dokun. Ana sayfada olmak veya önizlemeyi gizlemek çeviriyi durdurmaz. Önizleme açıkken de görüntü yoksa PS5 kartından Remote Play’e dön; bağlantı veya görüntü yenileniyorsa bekle. Sorun sürerse çeviriyi durdurup yeniden başlat. PS5’te bağlantı bildirimi görünmesi tek başına video akışının hazır olduğunu göstermez.":
      "หากซ่อนภาพบนมือถือไว้ ให้แตะแสดงภาพ การกลับหน้าหลักหรือซ่อนตัวอย่างไม่หยุดการแปล หากยังไม่มีภาพ ให้กลับไปที่ Remote Play จากการ์ด PS5 และรอการเชื่อมต่อหรือภาพฟื้นตัว หากจำเป็นให้หยุดแปลแล้วเริ่มใหม่ การแจ้งเตือนเชื่อมต่อบน PS5 อย่างเดียวไม่ได้แปลว่าสตรีมภาพพร้อมแล้ว",
  "Uygulamadaki PS5 görüntüsü nereden geliyor?": "ภาพ PS5 ในแอปมาจากไหน?",
  "Telefondaki görüntü PS5’ten Remote Play ile alınan canlı akıştır. OCR, bu görüntüde seçtiğin alanlardaki metni okur. TV’de PS5’in HDMI girişini izlersin; çevrilen altyazıyı Android TV uygulaması bu görüntünün üzerinde gösterir.":
      "โทรศัพท์รับสตรีมสดจาก PS5 ผ่าน Remote Play โดย OCR อ่านข้อความในพื้นที่ที่เลือกจากภาพนั้น บนทีวีคุณดูช่อง HDMI ของ PS5 และแอป Android TV แสดงคำแปลทับบนภาพ",
  "Altyazıları PS5’in HDMI görüntüsünde göstermek için ne gerekli?":
      "ต้องใช้อะไรเพื่อแสดงคำบรรยายทับภาพ PS5 ผ่าน HDMI?",
  "Telefon uygulaması, PS5 ve OyunÇevirmeni TV uygulamasını çalıştırabilen bir Android TV gerekir. TV uygulamasına diğer uygulamaların üzerinde gösterim izni ver, telefonu TV ile eşleştir ve telefonda çeviriyi başlat. TV’de altyazı gösterimi açık olmalı. Sonra PS5’in bağlı olduğu HDMI girişine geç. HDMI üzerinde gösterim desteği TV’nin sistemine bağlıdır.":
      "ต้องมีแอปโทรศัพท์ PS5 และ Android TV ที่ใช้Console Game Translator TV ได้ อนุญาตให้แอปทีวีแสดงทับแอปอื่น จับคู่โทรศัพท์กับทีวี แล้วเริ่มแปลบนโทรศัพท์ ต้องเปิดแสดงคำบรรยายบนทีวีด้วย จากนั้นสลับไปยัง HDMI ของ PS5 การรองรับการแสดงทับ HDMI ขึ้นอยู่กับระบบทีวี",
  "Telefon oyun görüntüsünü TV’ye gönderiyor mu?":
      "โทรศัพท์ส่งภาพเกมไปยังทีวีหรือไม่?",
  "Hayır. Oyun görüntüsü PS5’in HDMI bağlantısından gelir. Telefon, Remote Play görüntüsünü metni okumak için kullanır; TV’ye çevrilmiş altyazı metnini ve görünüm ayarlarını gönderir. TV uygulaması bu metni ayrı bir katmanda gösterir.":
      "ไม่ ภาพเกมมาจาก HDMI ของ PS5 โทรศัพท์ใช้ภาพ Remote Play เพื่ออ่านข้อความ และส่งข้อความคำแปลพร้อมการตั้งค่ารูปแบบไปยังทีวี แอปทีวีแสดงข้อความในชั้นแสดงผลแยก",
  "Uygulama arka plandayken veya telefonun ekranı kapalıyken çeviri devam eder mi?":
      "ยังแปลต่อได้ไหมเมื่อแอปอยู่เบื้องหลังหรือปิดหน้าจอโทรศัพท์?",
  "Evet. Çeviriyi Başlat’tan sonra Remote Play ve OCR arka planda çalışır; uygulama ana sayfaya döner. Başka bir uygulamaya geçebilir veya ekranı kapatabilirsin. Bildirimlere izin vererek çeviri durumunu takip edebilirsin. Kesinti olursa uygulamaya dönüp PS5 ve TV bağlantısını kontrol et; telefonun pil ayarlarında uygulamanın arka plan çalışmasını kısıtlamadığından emin ol. Zorla durdurma işlemi oturumu sonlandırır.":
      "ได้ หลังเริ่มแปล Remote Play และ OCR จะทำงานเบื้องหลัง และแอปกลับหน้าหลัก คุณใช้แอปอื่นหรือปิดหน้าจอได้ อนุญาตการแจ้งเตือนเพื่อติดตามสถานะ หากคำแปลหยุดอัปเดต ให้กลับแอปและตรวจสอบการเชื่อมต่อ PS5 กับทีวี รวมถึงการตั้งค่าแบตเตอรี่ที่ต้องอนุญาตการทำงานเบื้องหลัง การบังคับหยุดแอปจะจบเซสชัน",
  "Çeviriyi Başlat’a bastığımda neden başlamıyor?":
      "ทำไมแตะเริ่มแปลแล้วไม่เริ่ม?",
  "PS5 kaydı hazır, Android TV bağlı ve seçili modelin dil paketleri indirilmiş olmalı. Ayrıca Google hesabınla giriş yapıp kullanılabilir deneme süresine veya Premium erişime sahip olmalısın. Ekrandaki hata mesajına göre eksik adımı tamamla. PS5 yeniden bağlanıyorsa bekle; başarısız olursa bağlantıları kontrol edip tekrar dene.":
      "การลงทะเบียน PS5 ต้องพร้อม Android TV ต้องเชื่อมต่อ และดาวน์โหลดแพ็กภาษาของโมเดลแล้ว คุณต้องลงชื่อเข้าใช้ Google และมีเวลาทดลองเหลือหรือสิทธิ์ Premium ทำขั้นตอนที่ขาดตามข้อความผิดพลาด หาก PS5 กำลังเชื่อมต่อใหม่ให้รอ หากไม่สำเร็จให้ตรวจสอบการเชื่อมต่อแล้วลองอีกครั้ง",
  "Altyazılar TV’de görünmüyor. Neleri kontrol etmeliyim?":
      "คำบรรยายไม่แสดงบนทีวี ควรตรวจสอบอะไร?",
  "Telefondaki Android TV kartında Bağlı yazdığını ve çevirinin çalıştığını kontrol et. TV uygulamasında İzin ver ile üstte gösterim iznini ver; izin zaten açıksa Altyazıyı aç / yenile’yi kullan. Altyazılar duraklatılmışsa Altyazıları sürdür’e bas. Oyundaki metin sarı OCR alanında olmalı. TV’yi PS5’in HDMI girişine al; sorun sürerse TV uygulamasını yeniden açıp bağlantı durumuna bak.":
      "ตรวจสอบว่าการ์ด Android TV บนโทรศัพท์แสดงว่าเชื่อมต่อแล้วและกำลังแปล ในแอปทีวีให้เลือกอนุญาตสิทธิ์เพื่อแสดงทับ หากอนุญาตแล้วให้เลือกเปิด / รีเฟรชคำบรรยาย หากพักอยู่ให้เลือกแสดงคำบรรยายต่อ ข้อความเกมต้องอยู่ในพื้นที่ OCR สีเหลือง สลับทีวีไปยัง HDMI ของ PS5 หากจำเป็นให้เปิดแอปทีวีใหม่และตรวจสอบสถานะ",
  "OCR metni yanlış okuyor veya geç algılıyor. Ne yapabilirim?":
      "OCR อ่านผิดหรือพบข้อความช้า ควรทำอย่างไร?",
  "Altyazı → Altyazı görünümü bölümünde sarı OCR alanını yalnızca okunacak metni tam kapsayacak şekilde ayarla. Konuşma altyazılarında diyalog filtresini deneyebilir, görev ve menü yazılarında kapalı tutabilirsin. Ön işleme ve ölçek ayarları her OCR alanı için ayrıdır; küçük yazıda 1,5× veya 2× ölçeği dene. Oyundaki altyazı arka planını açmak ve yazıyı büyütmek de okumayı iyileştirebilir.":
      "เปิด คำบรรยาย → รูปแบบคำบรรยาย แล้วปรับพื้นที่ OCR สีเหลืองให้ครอบเฉพาะข้อความที่ต้องการอ่านอย่างครบถ้วน ลองตัวกรองบทสนทนาสำหรับบทพูด และปิดสำหรับภารกิจหรือเมนู การประมวลผลภาพและอัตราขยายแยกแต่ละพื้นที่ ลอง 1.5× หรือ 2× กับตัวอักษรเล็ก การเปิดพื้นหลังคำบรรยายในเกมและเพิ่มขนาดอักษรอาจช่วยให้อ่านดีขึ้น",
  "İstediğim dil neden kaynak veya hedef listesinde görünmüyor?":
      "ทำไมไม่มีภาษาที่ต้องการในรายการต้นทางหรือปลายทาง?",
  "Dil menüleri seçili modelin desteklediği tüm dilleri gösterir; indirilmemiş olanlar “indirilmedi” olarak işaretlenir. Dili seçtikten sonra altındaki İndir’e dokun veya Dilleri görüntüle ve indir’den paketi indir. Model A’da kaynak dil İngilizcedir; hedef dil paketini seçersin. Model B’de kaynak ve hedef paketleri ayrı gerekir. Bir modelin listesinde bulunmayan dil için diğer modelin desteklediği dilleri kontrol et.":
      "เมนูภาษาจะแสดงทุกภาษาที่โมเดลรองรับ ภาษาที่ยังไม่ดาวน์โหลดจะมีเครื่องหมาย “ยังไม่ได้ดาวน์โหลด” หลังเลือกภาษาให้แตะดาวน์โหลดด้านล่าง หรือใช้ดูและดาวน์โหลดภาษา Model A ใช้ต้นทางอังกฤษและแพ็กปลายทางที่เลือก Model B ต้องมีแพ็กต้นทางและปลายทางแยกกัน หากโมเดลไม่มีภาษาที่ต้องการ ให้ตรวจสอบภาษาในอีกโมเดล",
  "Model A ve Model B arasındaki fark nedir?":
      "Model A กับ Model B ต่างกันอย่างไร?",
  "Model A daha yavaş çalışır ancak daha doğru ve kaliteli çeviriler sunar. Model B daha hızlıdır; çevirileri zaman zaman daha az isabetli olabilir. Kalite önceliğinse Model A’yı, hız önceliğinse Model B’yi tercih edebilirsin.":
      "Model A ช้ากว่า แต่แปลได้แม่นยำและมีคุณภาพสูงกว่า Model B เร็วกว่า แต่อาจแปลแม่นยำน้อยกว่าในบางครั้ง เลือก Model A เมื่อเน้นคุณภาพ หรือ Model B เมื่อเน้นความเร็ว",
  "Altyazı sekmesindeki Oyun Kütüphanesi ne işe yarar?":
      "คลังเกมในแท็บคำบรรยายมีไว้ทำอะไร?",
  "Oyun Kütüphanesi, oyununa özel hazır çevirilerle hikâyeyi daha rahat takip etmene yardımcı olur. En iyi deneyim için oyunun listede varsa Altyazı sekmesindeki Oyun Kütüphanesi bölümünden seç.":
      "คลังเกมช่วยให้ติดตามเนื้อเรื่องง่ายขึ้นด้วยคำแปลสำเร็จรูปของเกม เพื่อประสบการณ์ที่ดีที่สุด ให้เลือกเกมจากคลังเกมในแท็บคำบรรยายหากมีในรายการ",
  "Uygulamaya döndüğümde PS5’i yeniden kaydetmem gerekir mi?":
      "ต้องลงทะเบียน PS5 ใหม่เมื่อกลับมาใช้แอปไหม?",
  "Hayır. Oturum sürüyorsa mevcut Remote Play bağlantısı kullanılır. Beklenmedik kopmalarda uygulama yeniden bağlanmayı dener; PS5 kartında yeniden bağlanma veya görüntü yenileme durumunu görebilirsin. Denemeler sonuç vermezse konsolun ve ağın açık olduğunu kontrol edip çeviriyi tekrar başlat. PS5’i listeden kaldırmadığın sürece tekrar kayıt gerekmez.":
      "ไม่ หากเซสชันยังทำงานจะใช้การเชื่อมต่อ Remote Play เดิม เมื่อหลุดกะทันหัน แอปจะลองเชื่อมต่อใหม่ โดยดูสถานะได้จากการ์ด PS5 หากลองแล้วไม่สำเร็จ ให้ตรวจสอบคอนโซลและเครือข่ายแล้วเริ่มแปลใหม่ ไม่ต้องลงทะเบียนใหม่หากไม่ได้ลบ PS5 ออกจากรายการ",
  "Çeviriyi durdurunca PS5 kaydı veya TV eşleştirmesi silinir mi?":
      "การหยุดแปลจะลบการลงทะเบียน PS5 หรือการจับคู่ทีวีไหม?",
  "Hayır. Çeviriyi Durdur, Remote Play ve çeviri akışını durdurup TV’deki mevcut altyazıyı temizler. Kayıtlı PS5, TV eşleştirmesi, dil paketleri ve altyazı ayarları korunur. PS5’i listeden kaldırmak ayrı bir işlemdir; TV eşleştirmesi de TV uygulamasındaki sıfırlama işlemiyle ayrıca yenilenir.":
      "ไม่ การหยุดแปลจะหยุด Remote Play และการแปล พร้อมล้างคำบรรยายปัจจุบันบนทีวี การลงทะเบียน PS5 การจับคู่ทีวี แพ็กภาษา และการตั้งค่าคำบรรยายจะยังอยู่ การลบ PS5 ออกจากรายการเป็นอีกคำสั่งหนึ่ง และรีเซ็ตการจับคู่ทีวีแยกได้จากแอปทีวี",
  "TV eşleştirme kodu veya bağlantısı çalışmıyor. Ne yapmalıyım?":
      "รหัสจับคู่ทีวีหรือการเชื่อมต่อใช้ไม่ได้ ควรทำอย่างไร?",
  "İlk eşleştirmede TV uygulamasını aç; TV ve telefonu aynı yerel ağa bağla. TV’yi ağda bul ile TV’yi seç veya ekrandaki adresi elle gir, ardından güncel 6 haneli kodu kullan. Kimlik doğrulama ekranı açılırsa değeri TV’deki Güvenli bağlantı kimliği ile karşılaştır. Daha önce eşleşmiş TV bağlanmıyorsa TV uygulamasını yeniden açıp tekrar dene; eşleştirme sıfırlandıysa yeniden eşleştir.":
      "สำหรับการจับคู่ครั้งแรก ให้เปิดแอปทีวีและใช้เครือข่ายท้องถิ่นเดียวกันทั้งสองอุปกรณ์ เลือกค้นหาทีวีในเครือข่ายหรือป้อนที่อยู่เอง แล้วใช้รหัส 6 หลักปัจจุบัน หากมีการยืนยันตัวตน ให้เทียบกับรหัสยืนยันการเชื่อมต่อที่ปลอดภัยบนทีวี หากทีวีที่เคยจับคู่ไม่เชื่อมต่อ ให้เปิดแอปทีวีใหม่แล้วลองอีกครั้ง หากรีเซ็ตการจับคู่แล้วต้องจับคู่ใหม่",
  "PSN bağlantısında hangi hesabı ve hangi yönlendirme adresini kullanmalıyım?":
      "ควรใช้บัญชี PSN และ URL เปลี่ยนเส้นทางใด?",
  "Remote Play için yeni veya kullanmadığın ayrı bir PSN hesabı kullan ve bu hesabı PS5’e kullanıcı olarak ekle; oyunu ana hesabında oynarsın. PSN ile giriş yap’tan sonra açılan beyaz redirect sayfasında adres çubuğundaki bağlantının tamamını kopyala. Uygulamada Yönlendirme URL’si alanına yapıştırıp PSN hesabını doğrula’ya bas. Kod geçersiz veya kullanılmışsa giriş işlemini yeniden başlatıp yeni adresi kopyala.":
      "ใช้บัญชี PSN แยกที่ใหม่หรือไม่ได้ใช้งานสำหรับ Remote Play และเพิ่มเป็นผู้ใช้ PS5 ส่วนเกมให้เล่นด้วยบัญชีหลัก หลังลงชื่อเข้าใช้ PSN และเห็นหน้า redirect สีขาว ให้คัดลอก URL ทั้งหมดจากแถบที่อยู่ วางในช่อง URL เปลี่ยนเส้นทางในแอปแล้วเลือกยืนยันบัญชี PSN หากรหัสไม่ถูกต้องหรือใช้แล้ว ให้เริ่มลงชื่อเข้าใช้ใหม่และคัดลอก URL ใหม่",
  "Çeviri için internet gerekli mi?": "ต้องใช้อินเทอร์เน็ตเพื่อแปลหรือไม่?",
  "OCR ve indirilmiş modellerle metin çevirisi telefonda yapılır; metin çevirisi için buluta gönderilmez. Ancak ilk kurulum, Google/PSN girişi, dil veya Oyun Kütüphanesi üzerinden çeviri indirme, erişim ve satın alma doğrulamaları için internet gerekir. Kullanım sırasında telefon, PS5 ve TV’nin aynı yerel ağdaki bağlantısı sürmelidir; uygulamanın bütünü için tamamen çevrimdışı çalışma garantisi yoktur.":
      "OCR และการแปลด้วยโมเดลที่ดาวน์โหลดจะทำงานบนโทรศัพท์ ไม่ส่งข้อความไปแปลบนคลาวด์ แต่ต้องใช้อินเทอร์เน็ตเพื่อตั้งค่าครั้งแรก ลงชื่อเข้าใช้ Google/PSN ดาวน์โหลดภาษาหรือคำแปลจากคลังเกม และยืนยันสิทธิ์กับการซื้อ ระหว่างใช้งานโทรศัพท์ PS5 และทีวีต้องเชื่อมต่อเครือข่ายท้องถิ่นเดียวกัน ไม่รับประกันว่าทั้งแอปจะทำงานแบบออฟไลน์ได้ทั้งหมด",
  "Telefonu, PS5’i ve TV’yi aynı ağa bağla":
      "เชื่อมต่อโทรศัพท์ PS5 และทีวีกับเครือข่ายเดียวกัน",
  "Telefon, PS5 ve Android TV aynı yönlendiricinin yerel ağına bağlı olmalı. PS5 veya TV Ethernet, telefon Wi-Fi kullanabilir; misafir ağı ya da cihazları birbirinden ayıran ağ ayarları bağlantıyı engelleyebilir.":
      "โทรศัพท์ PS5 และ Android TV ต้องอยู่ในเครือข่ายท้องถิ่นของเราเตอร์เดียวกัน PS5 หรือทีวีใช้ Ethernet และโทรศัพท์ใช้ Wi-Fi ได้ เครือข่ายแขกหรือการตั้งค่าแยกอุปกรณ์อาจขัดขวางการเชื่อมต่อ",
  "İlk kurulumda PS5 ve TV açık olsun. Google/PSN girişi, dil paketleri ve gerekiyorsa Oyun Kütüphanesi üzerinden çeviri indirme işlemleri için internet bağlantını hazır tut.":
      "เปิด PS5 และทีวีไว้ขณะตั้งค่าครั้งแรก เตรียมอินเทอร์เน็ตสำหรับลงชื่อเข้าใช้ Google/PSN ดาวน์โหลดแพ็กภาษา และคำแปลจากคลังเกมหากต้องการ",
  "PS5’te Remote Play’i etkinleştir": "เปิดใช้ Remote Play บน PS5",
  "PS5’te Ayarlar → Sistem → Remote Play bölümünü aç ve Remote Play’i Etkinleştir seçeneğini aç.":
      "บน PS5 เปิด การตั้งค่า → ระบบ → Remote Play แล้วเปิดใช้ Remote Play",
  "Dinlenme modundaki konsola bağlanmak istiyorsan Ayarlar → Sistem → Güç Tasarrufu → Dinlenme Modunda Kullanılabilen Özellikler bölümünde İnternete Bağlı Kal ve PS5’in Ağdan Açılmasını Etkinleştir seçeneklerini aç. İlk kayıt için konsolu açık tut.":
      "หากต้องการเชื่อมต่อขณะคอนโซลอยู่ในโหมดพัก ให้เปิด การตั้งค่า → ระบบ → การประหยัดพลังงาน → คุณสมบัติที่ใช้งานได้ในโหมดพัก แล้วเปิดคงการเชื่อมต่ออินเทอร์เน็ตและเปิด PS5 ผ่านเครือข่ายได้ เปิดคอนโซลไว้สำหรับการลงทะเบียนครั้งแรก",
  "PSN hesabını doğrula ve PS5’i kaydet": "ยืนยันบัญชี PSN และลงทะเบียน PS5",
  "Önemli: Remote Play için yeni veya kullanmadığın ayrı bir PSN hesabı kullan ve bu hesabı PS5’e kullanıcı olarak ekle. Oyunu kendi ana PSN hesabında oynayacaksın.":
      "สำคัญ: ใช้บัญชี PSN แยกที่ใหม่หรือไม่ได้ใช้งานสำหรับ Remote Play และเพิ่มเป็นผู้ใช้ PS5 คุณจะเล่นเกมด้วยบัญชี PSN หลัก",
  "Ana sayfadaki PlayStation 5 kartında PS5’i kur’a dokun, ardından PSN ile giriş yap’ı aç. Girişten sonra beyaz redirect sayfasındayken tarayıcının adres çubuğundaki bağlantının tamamını kopyala. Uygulamadaki Yönlendirme URL’si alanına yapıştır ve PSN hesabını doğrula’ya bas.":
      "บนหน้าหลัก แตะตั้งค่า PS5 ในการ์ด PlayStation 5 แล้วลงชื่อเข้าใช้ด้วย PSN หลังลงชื่อเข้าใช้ ให้คัดลอก URL ทั้งหมดจากแถบที่อยู่ของหน้า redirect สีขาว วางในช่อง URL เปลี่ยนเส้นทางของแอปแล้วเลือกยืนยันบัญชี PSN",
  "Sonraki adım: PS5 konsolunu bağla’ya geç. Konsolda Ayarlar → Sistem → Remote Play → Cihazı Bağla’yı aç. Konsolu ağda bul veya IP adresini elle gir; PS5’in gösterdiği güncel 8 haneli PIN’i yazıp PS5 bağlantısını başlat’a dokun.":
      "ไปยังขั้นตอนถัดไป: เชื่อมต่อ PS5 บนคอนโซลเปิด การตั้งค่า → ระบบ → Remote Play → จับคู่อุปกรณ์ ค้นหาคอนโซลในเครือข่ายหรือป้อน IP เอง แล้วป้อน PIN 8 หลักปัจจุบันบน PS5 และแตะเริ่มเชื่อมต่อ PS5",
  "IP adresini PS5’te Ayarlar → Ağ → Bağlantı Durumu bölümünde bulabilirsin. Kayıt tamamlandığında ana sayfadaki PS5 kartında Hazır görünür. PS5’in kayıt PIN’i, TV’nin 6 haneli eşleştirme kodundan farklıdır.":
      "ดู IP ได้ที่ การตั้งค่า → เครือข่าย → สถานะการเชื่อมต่อ บน PS5 เมื่อลงทะเบียนเสร็จ การ์ด PS5 ที่หน้าหลักจะแสดงว่าพร้อม PIN ลงทะเบียน PS5 ต่างจากรหัสจับคู่ทีวี 6 หลัก",
  "Android TV uygulamasını hazırla": "เตรียมแอป Android TV",
  "TV uygulamasında İzin ver’e bas, İzin ayarlarını aç ile Android’in izin ekranına geç ve diğer uygulamaların üzerinde gösterime izin ver. Uygulamaya dönünce altyazı katmanı hazırlanır. İzin zaten açıksa düğmenin adı Altyazıyı aç / yenile olur.":
      "ในแอปทีวี เลือกอนุญาตสิทธิ์ จากนั้นเปิดการตั้งค่าสิทธิ์และอนุญาตให้แสดงทับแอปอื่นในการตั้งค่า Android เมื่อกลับมา ระบบจะเตรียมชั้นแสดงคำบรรยาย หากอนุญาตแล้ว ปุ่มจะชื่อเปิด / รีเฟรชคำบรรยาย",
  "Altyazı gösterimi duraklatılmışsa Altyazıları sürdür’e bas. Eşleştirmeden sonra TV uygulaması ekranda açık kalmak zorunda değildir; TV açık ve ağa bağlıyken alıcı arka planda çalışabilir. TV yeniden başladıktan veya uygulama zorla durdurulduktan sonra bağlantı kurulmazsa uygulamayı yeniden aç.":
      "หากพักคำบรรยายไว้ ให้เลือกแสดงคำบรรยายต่อ หลังจับคู่ ไม่ต้องเปิดแอปทีวีค้างบนหน้าจอ ตัวรับทำงานเบื้องหลังได้เมื่อทีวีเปิดและเชื่อมต่อเครือข่าย หากไม่เชื่อมต่อใหม่หลังรีสตาร์ตทีวีหรือบังคับหยุดแอป ให้เปิดแอปทีวีใหม่",
  "Telefonu TV ile eşleştir": "จับคู่โทรศัพท์กับทีวี",
  "Ana sayfadaki Android TV kartında TV’yi eşleştir’e bas. TV uygulaması açıkken TV’yi ağda bul’u kullan veya TV ekranındaki adresi elle gir. Birden fazla sonuç varsa ekrandaki adresle aynı olanı seç.":
      "ที่หน้าหลัก แตะจับคู่ทีวีในการ์ด Android TV ขณะเปิดแอปทีวี ให้ค้นหาทีวีในเครือข่ายหรือป้อนที่อยู่บนทีวีเอง หากมีหลายผลลัพธ์ ให้เลือกที่อยู่ที่ตรงกับทีวี",
  "TV’deki güncel 6 haneli kodu girip Eşleştir ve bağlan’a dokun. TV kimliğini doğrula ekranı açılırsa telefondaki değerin TV’deki Güvenli bağlantı kimliği ile tamamının eşleştiğini kontrol ederek onayla.":
      "ป้อนรหัส 6 หลักปัจจุบันบนทีวีแล้วแตะจับคู่และเชื่อมต่อ หากมีหน้ายืนยันตัวตนทีวี ให้ยืนยันหลังตรวจสอบว่าค่าทั้งหมดตรงกับรหัสยืนยันการเชื่อมต่อที่ปลอดภัยบนทีวี",
  "Telefonun Android TV kartında Bağlı durumunu gör. Eşleştirme kayıtlı • TV bağlı değil yazması çeviri için yeterli değildir. Sonraki kullanımda kayıtlı eşleştirme ile yeniden bağlantı denenir; bağlanmazsa TV uygulamasını açıp tekrar dene.":
      "ตรวจสอบว่าการ์ด Android TV บนโทรศัพท์แสดงว่าเชื่อมต่อแล้ว สถานะบันทึกการจับคู่แล้วแต่ทีวียังไม่เชื่อมต่อไม่เพียงพอให้เริ่มแปล ครั้งต่อไปจะพยายามใช้การจับคู่ที่บันทึกไว้ หากไม่เชื่อมต่อ ให้เปิดแอปทีวีแล้วลองอีกครั้ง",
  "Çeviri modelini ve dil paketlerini hazırla": "เตรียมโมเดลแปลและแพ็กภาษา",
  "Ana sayfada Model A veya Model B’yi seç. Model A daha yavaş çalışır ancak daha doğru ve kaliteli çeviriler sunar. Model B daha hızlıdır; çevirileri zaman zaman daha az isabetli olabilir.":
      "เลือก Model A หรือ Model B ที่หน้าหลัก Model A ช้ากว่า แต่ให้คำแปลแม่นยำและคุณภาพสูงกว่า Model B เร็วกว่า แต่อาจแปลแม่นยำน้อยกว่าในบางครั้ง",
  "Dilleri görüntüle ve indir’i aç. Model A için İngilizceden çevireceğin hedef dil paketini, Model B için kaynak ve hedef dil paketlerini indir. Ardından dil seçimlerini yap; örneğin English → Türkçe. Her modelin paketleri ayrıdır.":
      "เปิดดูและดาวน์โหลดภาษา สำหรับ Model A ดาวน์โหลดแพ็กจากอังกฤษเป็นภาษาปลายทาง ส่วน Model B ดาวน์โหลดแพ็กต้นทางและปลายทาง จากนั้นเลือกภาษา เช่น อังกฤษ → ไทย แต่ละโมเดลใช้แพ็กแยกกัน",
  "Daha hızlı ve kaliteli bir çeviri deneyimi için Altyazı sekmesindeki Oyun Kütüphanesi bölümünden oyununu seç. Hazır oyun çevirileri, hikâyeyi daha doğal ve akıcı biçimde takip etmene yardımcı olur.":
      "เพื่อการแปลที่เร็วและคุณภาพดีขึ้น ให้เลือกเกมจากคลังเกมในแท็บคำบรรยาย คำแปลสำเร็จรูปช่วยให้ติดตามเรื่องราวได้เป็นธรรมชาติและลื่นไหลยิ่งขึ้น",
  "OCR ve altyazı alanlarını ayarla": "ปรับพื้นที่ OCR และคำบรรยาย",
  "Altyazı sekmesinde Altyazı görünümü’nü aç. Canlı oyun görüntüsünü görmek için PS5 kartından Remote Play’i açabilirsin. Sarı OCR alanını oyundaki metni tam kapsayacak şekilde yerleştir; yalnızca bu alanlardaki metin okunur.":
      "เปิดรูปแบบคำบรรยายในแท็บคำบรรยาย เปิด Remote Play จากการ์ด PS5 เพื่อดูภาพเกมสดได้ วางพื้นที่ OCR สีเหลืองให้ครอบข้อความเกมทั้งหมด ระบบจะอ่านเฉพาะข้อความในพื้นที่เหล่านี้",
  "Çevrilmiş metnin yerini, boyutunu ve görünümünü altyazı ayarlarından düzenle. Sarı OCR alanı ile turkuaz altyazı alanı birbirinden bağımsızdır; birden fazla alan ekleyebilir, alanları sürükleyip boyutlandırabilirsin.":
      "ปรับตำแหน่ง ขนาด และรูปแบบข้อความแปลในการตั้งค่าคำบรรยาย พื้นที่ OCR สีเหลืองแยกจากพื้นที่คำบรรยายสีฟ้าอมเขียว เพิ่ม ย้าย และปรับขนาดได้หลายพื้นที่",
  "Konuşma altyazıları için diyalog filtresini deneyebilirsin; görev ve menü metinlerinde kapalı tut. Ön işleme ve OCR ölçeği her alan için ayrı ayarlanır. Değişiklikler otomatik kaydedilir; Kaydet ile de saklayabilirsin.":
      "ลองตัวกรองบทสนทนาสำหรับบทพูด และปิดสำหรับข้อความภารกิจหรือเมนู การประมวลผลภาพและอัตราขยาย OCR ตั้งแยกแต่ละพื้นที่ การเปลี่ยนแปลงบันทึกอัตโนมัติ หรือกดบันทึกได้",
  "Çeviriyi başlat ve PS5’te oyna": "เริ่มแปลและเล่นบน PS5",
  "Ana sayfada PS5 kaydı hazır, Android TV Bağlı ve dil paketleri indirilmişken Çeviriyi Başlat’a dokun. Google hesabınla giriş yapıp kullanılabilir deneme süresine veya Premium erişime sahip olmalısın.":
      "ที่หน้าหลัก เมื่อการลงทะเบียน PS5 พร้อม Android TV เชื่อมต่อแล้ว และดาวน์โหลดแพ็กภาษาแล้ว ให้แตะเริ่มแปล คุณต้องลงชื่อเข้าใช้ Google และมีเวลาทดลองเหลือหรือสิทธิ์ Premium",
  "Remote Play ve çeviri hazır olunca uygulama ana sayfaya döner. İlk kullanımda Alanları ayarla önerisi çıkarsa oyundaki metne göre OCR ve altyazı alanlarını düzenle. Sonradan Altyazı → Altyazı görünümü’nden aynı ayarlara dönebilirsin.":
      "เมื่อ Remote Play และการแปลพร้อม แอปจะกลับหน้าหลัก หากครั้งแรกมีคำแนะนำให้ปรับพื้นที่ ให้ตั้งพื้นที่ OCR และคำบรรยายตามข้อความเกม กลับมาปรับได้ที่ คำบรรยาย → รูปแบบคำบรรยาย",
  "Oyunu ana PSN hesabında oyna ve TV’yi PS5’in HDMI girişine al. TV uygulamasını ekranda açık tutman gerekmez. Telefon arka plandayken veya ekranı kapalıyken çeviri sürebilir; kesinti olursa bağlantıları ve telefonun pil kısıtlamalarını kontrol et.":
      "เล่นด้วยบัญชี PSN หลักและสลับทีวีไปยัง HDMI ของ PS5 ไม่ต้องเปิดแอปทีวีค้างบนหน้าจอ การแปลทำงานต่อได้เมื่อแอปโทรศัพท์อยู่เบื้องหลังหรือปิดหน้าจอ หากสะดุด ให้ตรวจสอบการเชื่อมต่อและข้อจำกัดแบตเตอรี่ของโทรศัพท์",
  "Bitirirken telefonda Çeviriyi Durdur’a veya çeviri bildirimindeki Durdur’a bas. Remote Play ve çeviri durur; PS5 kaydı, TV eşleştirmesi ve ayarların korunur.":
      "เมื่อเสร็จ ให้แตะหยุดแปลบนโทรศัพท์ หรือหยุดในการแจ้งเตือน การแปลและ Remote Play จะหยุด โดยเก็บการลงทะเบียน PS5 การจับคู่ทีวี และการตั้งค่าไว้",
  "TV’de Play Store’dan **Oyun Çevirmeni TV**’yi kur. TV İngilizceyse **Console Game Translator TV** ara. En güncel sürüm her zaman sitede.":
      "ติดตั้ง **Console Game Translator TV** จาก Play Store บนทีวี เวอร์ชันล่าสุดมีบนเว็บไซต์ของเราเสมอ",
  "TV ve telefon aynı Wi-Fi ağında olsun; TV uygulamasını aç.":
      "ใช้ Wi-Fi เดียวกันบนทีวีและโทรศัพท์ แล้วเปิดแอปทีวี",
  "TV’yi ağda bul’a dokun ya da TV ekranındaki adresi yaz.":
      "แตะค้นหาทีวีในเครือข่ายหรือป้อนที่อยู่ที่แสดงบนทีวี",
  "TV ekranındaki 6 haneli kodu girip eşleştir.":
      "ป้อนรหัส 6 หลักบนทีวีเพื่อจับคู่",
  "Google Play’de aç": "เปิดใน Google Play",
  "Siteden indir": "ดาวน์โหลดจากเว็บไซต์",
  "Seçili oyunun çeviri paketi {0}, çeviri dili ise {1}. Oyunun kendi çevirileri kullanılmayacak; oyunu {1} paketiyle yeniden seç ya da çeviri dilini değiştir.":
      "แพ็กคำแปลของเกมที่เลือกเป็นภาษา {0} แต่ภาษาที่ใช้แปลคือ {1} ระบบจะไม่ใช้คำแปลของเกม ให้เลือกเกมใหม่พร้อมแพ็กภาษา {1} หรือเปลี่ยนภาษาที่ใช้แปล",
  "Oyun paketinin dili farklı": "ภาษาแพ็กเกมไม่ตรงกัน",
};
