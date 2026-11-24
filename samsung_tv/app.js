(function () {
  'use strict';
  var language = (navigator.language || '').toLowerCase().split(/[-_]/)[0];
  var tr = language === 'tr', ar = language === 'ar';
  document.documentElement.lang = tr ? 'tr' : ar ? 'ar' : 'en';
  document.documentElement.dir = ar ? 'rtl' : 'ltr';
  function t(turkish, english, arabic) { return tr ? turkish : ar ? arabic : english; }
  function el(id) { return document.getElementById(id); }
  var socket = null, token = null, url = null, reconnect = null, watchdog = null;
  var paired = false, tested = false, ready = false, stopped = true, lastMessage = 0;
  var sources = [], lastPacket = {type:'clear'}, testGeneration = 0;
  function status(value) { el('status').textContent = value; }
  function clear() { lastPacket = {type:'clear'}; TvReceiver.render(el('subtitles'), lastPacket, window.innerHeight, document); }
  function controls(show) { el('controls').style.display = show ? 'block' : 'none'; if (show) el('connect').focus(); }
  function screensaver(enabled) {
    try { webapis.appcommon.setScreenSaver(enabled ? webapis.appcommon.AppCommonScreenSaverState.SCREEN_SAVER_ON : webapis.appcommon.AppCommonScreenSaverState.SCREEN_SAVER_OFF); } catch (_) {}
  }
  function invalidate() {
    testGeneration++;
    ready = false; tested = false; el('confirm').disabled = true; clear(); screensaver(true);
    if (paired && socket && socket.readyState === 1) socket.send(JSON.stringify({type:'notReady'}));
  }
  function stop() {
    stopped = true; token = null; paired = false;
    clearTimeout(reconnect); clearInterval(watchdog); reconnect = null; watchdog = null;
    var previous = socket; socket = null; if (previous) previous.close();
    invalidate(); controls(true); status(t('Bağlantı kapatıldı.', 'Disconnected.', 'تم قطع الاتصال.'));
  }
  function open() {
    var current = new WebSocket(url); socket = current; lastMessage = Date.now();
    current.onopen = function () {
      current.send(JSON.stringify(token ? {type:'resume',sessionToken:token} : {type:'pair',code:el('code').value.trim()}));
    };
    current.onmessage = function (event) {
      if (current !== socket || typeof event.data !== 'string' || event.data.length > 262144) return;
      lastMessage = Date.now();
      try {
        var packet = JSON.parse(event.data);
        if (packet.type === 'paired' && typeof packet.sessionToken === 'string') {
          token = packet.sessionToken; paired = true;
          status(t('HDMI girişini seç ve örnek altyazıyı test et.', 'Select HDMI and test the sample subtitle.', 'اختر مدخل HDMI واختبر الترجمة التجريبية.'));
        } else if (packet.type === 'ping') {
          current.send(JSON.stringify({type:'pong'}));
        } else if (paired && packet.type === 'font') {
          TvReceiver.receiveFont(packet, document, function () {
            if (current === socket && ready) TvReceiver.render(el('subtitles'), lastPacket, window.innerHeight, document);
          }, function () { status(t('Altyazı fontu yüklenemedi.', 'Subtitle font could not be loaded.', 'تعذّر تحميل خط الترجمة.')); });
        } else if (ready && (packet.type === 'subtitle' || packet.type === 'presentation' || packet.type === 'clear')) {
          lastPacket = packet; TvReceiver.render(el('subtitles'), packet, window.innerHeight, document);
        }
      } catch (_) { clear(); }
    };
    current.onerror = function () { current.close(); };
    current.onclose = function (event) {
      if (current !== socket) return;
      socket = null; paired = false; invalidate(); controls(true);
      if (event.code === 1008) { token = null; stopped = true; }
      status(t('Bağlantı kesildi. Telefonda oturumu ve kodu kontrol et.', 'Connection lost. Check the phone session and code.', 'انقطع الاتصال. تحقّق من الجلسة والرمز على الهاتف.'));
      if (!stopped && token && !document.hidden) reconnect = setTimeout(open, 2000);
    };
    clearInterval(watchdog);
    watchdog = setInterval(function () { if (socket && Date.now() - lastMessage > 16000) socket.close(); }, 3000);
  }
  el('instructions').textContent = t('Telefonda Samsung Tizen seçeneğinden yerel oturum aç. Telefonun adresini ve kodunu gir. Aynı ev ağını kullan.', 'Open a local session under Samsung Tizen on your phone. Enter the phone address and code. Use the same home network.', 'ابدأ جلسة محلية من خيار Samsung Tizen على هاتفك. أدخل عنوان الهاتف والرمز. استخدم الشبكة المنزلية نفسها.');
  el('addressLabel').textContent = t('Telefonun IPv4:port adresi', 'Phone IPv4:port', 'عنوان IPv4 والمنفذ للهاتف');
  el('codeLabel').textContent = t('Kod', 'Code', 'الرمز');
  el('connect').textContent = t('Bağlan', 'Connect', 'اتصال');
  el('test').textContent = t('HDMI + örnek altyazı testi', 'Test HDMI + sample subtitle', 'اختبار HDMI والترجمة التجريبية');
  el('confirm').textContent = t('Oyunu ve örnek yazıyı birlikte görüyorum', 'I can see gameplay and the sample together', 'أرى اللعبة والنص التجريبي معًا');
  el('disconnect').textContent = t('Bağlantıyı kes', 'Disconnect', 'قطع الاتصال');
  el('limits').textContent = t('Bu alıcı TV’de açık kalmalı. Home veya kaynak değiştirmek altyazıyı keser. Yerel bağlantı şifresizdir. HDR/VRR/oyun modu ve gecikmeyi cihazında kontrol et. Geri tuşu ayarları açar.', 'Keep this receiver open. Home or changing input stops subtitles. The LAN connection is unencrypted. Check HDR/VRR/game mode and latency on your TV. Back opens settings.', 'أبقِ تطبيق الاستقبال مفتوحًا على التلفزيون. تتوقف الترجمة عند الضغط على Home أو تغيير المدخل. الاتصال المحلي غير مشفّر. تحقّق من HDR وVRR ووضع الألعاب وزمن التأخير على تلفزيونك. يفتح زر الرجوع الإعدادات.');
  el('support').textContent = t('Sorun mu yaşıyorsun? TV modelini, sorunun açıklamasını ve ekran görüntüsünü abrebostudio@gmail.com adresine gönder; birlikte çözelim.', 'Having trouble? Send your TV model, a description and a screenshot to abrebostudio@gmail.com so we can help.', 'هل تواجه مشكلة؟ أرسل طراز التلفزيون ووصف المشكلة ولقطة شاشة إلى abrebostudio@gmail.com لنساعدك في حلها.');
  el('connect').onclick = function () {
    stop();
    try {
      url = TvReceiver.endpoint(el('address').value);
      if (!/^[0-9]{6}$/.test(el('code').value.trim())) throw new Error('PIN');
      stopped = false; status(t('Bağlanıyor…', 'Connecting…', 'جارٍ الاتصال…')); open();
    } catch (_) { status(t('Yerel IPv4:port adresini ve 6 haneli kodu kontrol et.', 'Check the private IPv4:port address and six-digit code.', 'تحقّق من عنوان IPv4 المحلي والمنفذ والرمز المكوّن من 6 أرقام.')); }
  };
  el('test').onclick = function () {
    invalidate();
    if (!paired) { status(t('Önce telefona bağlan.', 'Connect to the phone first.', 'اتصل بالهاتف أولًا.')); return; }
    var source = sources[Number(el('hdmi').value)];
    var generation = testGeneration;
    TvReceiver.showHdmi(window.tizen, source, function () {
      if (!paired || document.hidden || generation !== testGeneration) return;
      tested = true; el('confirm').disabled = false;
      TvReceiver.render(el('subtitles'), {type:'subtitle',text:t('Örnek altyazı • Oyun görüntüsüyle birlikte görüyor musun?', 'Sample subtitle • Is gameplay visible behind this text?', 'ترجمة تجريبية • هل ترى صورة اللعبة خلف هذا النص؟'),
        presentation:{fontSize:28,backgroundOpacity:.8,textDirection:ar ? 'rtl' : 'ltr'}}, window.innerHeight, document);
      status(t('Örnek yazıyı ve oyunu birlikte görüyorsan onayla.', 'Confirm only if both gameplay and the sample are visible.', 'أكّد فقط إذا كنت ترى اللعبة والنص التجريبي معًا.'));
    }, function () { if (generation !== testGeneration) return; invalidate(); status(t('HDMI üzerinde gösterim desteklenmiyor veya izin verilmedi.', 'HDMI display is unsupported or permission was denied.', 'العرض فوق HDMI غير مدعوم أو لم يُمنح الإذن.')); });
  };
  el('confirm').onclick = function () {
    if (!paired || !tested || !socket || socket.readyState !== 1) return;
    clear(); ready = true; socket.send(JSON.stringify({type:'ready',hdmiVisible:true})); screensaver(false); controls(false);
  };
  el('hdmi').onchange = invalidate;
  el('disconnect').onclick = stop;
  try {
    if (!window.tizen || !tizen.tvwindow) throw new Error('Not a Tizen TV');
    tizen.systeminfo.getPropertyValue('VIDEOSOURCE', function (info) {
      sources = info.connected.filter(function (source) { return source.type === 'HDMI'; });
      sources.forEach(function (source, index) {
        var option = document.createElement('option'); option.value = String(index); option.textContent = 'HDMI ' + source.number; el('hdmi').appendChild(option);
      });
      if (!sources.length) status(t('Bağlı HDMI kaynağı bulunamadı.', 'No connected HDMI source found.', 'لم يُعثر على مصدر HDMI متصل.'));
    }, function () { status(t('HDMI kaynakları okunamadı.', 'Cannot read HDMI sources.', 'تعذّرت قراءة مصادر HDMI.')); });
  } catch (_) { status(t('HDMI gösterimi için Samsung Tizen TV gerekir. Tarayıcı önizlemesi cihaz doğrulaması değildir.', 'Samsung Tizen TV is required for HDMI display. A browser preview does not verify hardware.', 'يلزم تلفزيون Samsung Tizen للعرض فوق HDMI. معاينة المتصفح لا تتحقّق من دعم الجهاز.')); }
  document.addEventListener('visibilitychange', function () {
    if (document.hidden) {
      clearTimeout(reconnect); invalidate(); if (socket) socket.close();
    } else { controls(true); if (!stopped && token && !socket) open(); }
  });
  document.addEventListener('keydown', function (event) {
    if (event.keyCode === 10009 || event.keyCode === 27) {
      event.preventDefault();
      if (el('controls').style.display === 'none') controls(true);
      else { stop(); try { tizen.application.getCurrentApplication().exit(); } catch (_) {} }
      return;
    }
    if (event.keyCode >= 37 && event.keyCode <= 40) {
      // Leave native SELECT navigation to the TV's input system.
      if (document.activeElement.tagName === 'SELECT' && (event.keyCode === 38 || event.keyCode === 40)) return;
      if (document.activeElement.tagName === 'INPUT' && (event.keyCode === 37 || event.keyCode === 39)) return;
      var elements = el('controls').querySelectorAll('input,button,select'), enabled = [], i;
      for (i = 0; i < elements.length; i++) if (!elements[i].disabled) enabled.push(elements[i]);
      var at = enabled.indexOf(document.activeElement), next = (at + (event.keyCode === 40 || event.keyCode === 39 ? 1 : -1) + enabled.length) % enabled.length;
      if (enabled[next]) { event.preventDefault(); enabled[next].focus(); }
    }
  });
  window.addEventListener('unload', function () { stop(); try { tizen.tvwindow.hide(function () {}, function () {}); } catch (_) {} });
  window.addEventListener('resize', function () { if (ready) TvReceiver.render(el('subtitles'), lastPacket, window.innerHeight, document); });
  el('address').focus();
}());
