(function (root, factory) {
  if (typeof module === 'object' && module.exports) module.exports = factory();
  else root.TvReceiver = factory();
}(this, function () {
  'use strict';
  function privateIp(ip) {
    var parts = ip.split('.');
    if (parts.length !== 4) return false;
    for (var i = 0; i < 4; i++) {
      if (!/^(0|[1-9][0-9]{0,2})$/.test(parts[i]) || Number(parts[i]) > 255) return false;
    }
    return Number(parts[0]) === 10 || (Number(parts[0]) === 172 && Number(parts[1]) >= 16 && Number(parts[1]) <= 31) || (parts[0] === '192' && parts[1] === '168');
  }
  function endpoint(value) {
    var match = /^([0-9.]+):([0-9]{1,5})$/.exec(value.trim());
    if (!match || !privateIp(match[1]) || Number(match[2]) < 1 || Number(match[2]) > 65535) throw new Error('Invalid local address');
    return 'ws://' + match[1] + ':' + Number(match[2]) + '/subtitles';
  }
  function number(value, fallback, min, max) {
    return typeof value === 'number' && isFinite(value) ? Math.max(min, Math.min(max, value)) : fallback;
  }
  function color(value, opacity) {
    var v = number(value, 0xffffffff, 0, 0xffffffff) >>> 0;
    return 'rgba(' + ((v >>> 16) & 255) + ',' + ((v >>> 8) & 255) + ',' + (v & 255) + ',' + number(opacity, 1, 0, 1) + ')';
  }
  var loadedFonts = {};
  var maxFontBytes = 2 * 1024 * 1024;
  var maxEncodedFontBytes = Math.ceil(maxFontBytes / 3) * 4;
  function receiveFont(packet, doc, success, failure, environment) {
    var env = environment || window;
    try {
      var hash = packet.sha256, size = packet.bytes;
      if (!/^[a-f0-9]{64}$/.test(hash) || typeof size !== 'number' || size % 1 !== 0 || size < 12 || size > maxFontBytes ||
          typeof packet.data !== 'string' || packet.data.length > maxEncodedFontBytes) throw new Error('Invalid font');
      if (loadedFonts[hash]) { success(); return; }
      if (!env.FontFace || !doc.fonts) throw new Error('Downloaded fonts unsupported');
      var raw = env.atob(packet.data);
      if (raw.length !== size) throw new Error('Font size mismatch');
      var bytes = new Uint8Array(raw.length);
      for (var i = 0; i < raw.length; i++) bytes[i] = raw.charCodeAt(i);
      if (bytes[0] !== 0 || bytes[1] !== 1 || bytes[2] !== 0 || bytes[3] !== 0) throw new Error('Invalid TrueType font');
      var face = new env.FontFace('GameFont_' + hash, bytes.buffer);
      face.load().then(function (font) {
        doc.fonts.add(font); loadedFonts[hash] = true; success();
      }, failure);
    } catch (error) { failure(error); }
  }
  function render(container, packet, height, doc) {
    while (container.firstChild) container.removeChild(container.firstChild);
    if (!packet || packet.type === 'clear') return;
    var p = packet.presentation || {};
    if (p.enabled === false) return;
    var texts = Array.isArray(packet.texts) ? packet.texts : [packet.text || ''];
    var regions = Array.isArray(p.subtitleRegions) ? p.subtitleRegions : [{left:.1,top:.78,width:.8,height:.22}];
    for (var i = 0; i < Math.min(regions.length, 12); i++) {
      if (typeof texts[i] !== 'string' || !texts[i]) continue;
      var r = regions[i] || {}, region = doc.createElement('div'), text = doc.createElement('div');
      var left = number(r.left, .1, 0, .98), top = number(r.top, .78, 0, .98);
      region.className = 'region'; text.className = 'text';
      region.style.left = (left * 100) + '%'; region.style.top = (top * 100) + '%';
      region.style.width = (number(r.width, .8, .02, 1 - left) * 100) + '%';
      region.style.height = (number(r.height, .22, .02, 1 - top) * 100) + '%';
      var style = {}, key, override = Array.isArray(p.subtitleStyles) ? p.subtitleStyles[i] : null;
      for (key in p) if (Object.prototype.hasOwnProperty.call(p, key)) style[key] = p[key];
      if (override && typeof override === 'object') {
        for (key in override) if (Object.prototype.hasOwnProperty.call(override, key)) style[key] = override[key];
      }
      var rtl = style.textDirection === 'rtl';
      region.style.justifyContent = style.centered === false ? (rtl ? 'flex-end' : 'flex-start') : 'center';
      text.dir = rtl ? 'rtl' : 'ltr';
      text.style.textAlign = style.centered === false ? (rtl ? 'right' : 'left') : 'center';
      text.style.color = color(style.textColor, 1);
      text.style.backgroundColor = color(style.backgroundColor || 0, style.backgroundOpacity);
      text.style.fontSize = (number(style.fontSize, 22, 4, 64) * height / 540) + 'px';
      text.style.fontWeight = style.bold ? 'bold' : 'normal';
      if (style.useGameFont !== false && /^[a-f0-9]{64}$/.test(style.fontSha256) && loadedFonts[style.fontSha256]) {
        text.style.fontFamily = 'GameFont_' + style.fontSha256;
      }
      if (style.backgroundFitToText === false) text.style.width = '100%';
      text.textContent = texts[i].slice(0, 12000); // Treat subtitles as text, never markup.
      region.appendChild(text); container.appendChild(region);
    }
  }
  function showHdmi(tizen, source, success, failure) {
    if (!tizen || !tizen.tvwindow || !source || source.type !== 'HDMI') { failure(new Error('HDMI unsupported')); return; }
    try {
      tizen.tvwindow.setSource(source, function () {
        try { tizen.tvwindow.show(success, failure, ['0%', '0%', '100%', '100%'], 'MAIN', 'BEHIND'); }
        catch (error) { failure(error); }
      }, failure, 'MAIN');
    } catch (error) { failure(error); }
  }
  return {privateIp:privateIp, endpoint:endpoint, render:render, showHdmi:showHdmi, receiveFont:receiveFont};
}));
