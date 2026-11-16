const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const receiver = require('./receiver.js');
const path = require('node:path');
const crypto = require('node:crypto');

function node(tag) {
  return {tagName:tag.toUpperCase(), style:{}, children:[], disabled:false, value:'', textContent:'',
    appendChild(child) { this.children.push(child); },
    removeChild(child) { this.children.splice(this.children.indexOf(child),1); },
    get firstChild() { return this.children[0]; }, focus() {},
    querySelectorAll() { return []; }};
}
const doc = {createElement:node};

test('Arabic direction comes from the subtitle language independently of UI language', () => {
  const container = node('div');
  receiver.render(container, {type:'subtitle',text:'تعال إلى هنا!',presentation:{textDirection:'rtl',centered:false}},1080,doc);
  assert.equal(container.children[0].children[0].dir,'rtl');
  assert.equal(container.children[0].children[0].style.textAlign,'right');
  assert.equal(container.children[0].style.justifyContent,'flex-end');
});

test('each subtitle region renders its own font size, colors, alignment and weight', () => {
  const container = node('div');
  receiver.render(container, {type:'subtitle',texts:['First','Second'],presentation:{
    subtitleRegions:[{left:.1,top:.2,width:.8,height:.2},{left:.1,top:.6,width:.8,height:.2}],
    subtitleStyles:[
      {fontSize:36,textColor:0xffffff00,bold:true,centered:false,backgroundOpacity:.8},
      {fontSize:18,textColor:0xffffffff,bold:false,centered:true,backgroundOpacity:.3}
    ]}},1080,doc);
  const first=container.children[0].children[0], second=container.children[1].children[0];
  assert.equal(first.style.fontSize,'72px');
  assert.equal(second.style.fontSize,'36px');
  assert.equal(first.style.color,'rgba(255,255,0,1)');
  assert.equal(second.style.color,'rgba(255,255,255,1)');
  assert.equal(first.style.fontWeight,'bold');
  assert.equal(second.style.fontWeight,'normal');
  assert.equal(first.style.textAlign,'left');
  assert.equal(second.style.textAlign,'center');
});

test('downloaded Inter bytes are registered before the renderer selects the custom family', async () => {
  const descriptor = JSON.parse(fs.readFileSync(path.join(__dirname, '../server/game-catalog/profiles/font-assets.json')))['Inter-Regular'];
  const bytes = fs.readFileSync(path.join(__dirname, '../server/game-catalog/fonts/' + descriptor.sha256 + '.ttf'));
  assert.equal(crypto.createHash('sha256').update(bytes).digest('hex'), descriptor.sha256);
  let registered;
  const fontDoc = {createElement:node,fonts:{add(font){registered=font;}}};
  const environment = {atob:data=>Buffer.from(data,'base64').toString('binary'),FontFace:function(family,buffer){
    assert.deepEqual(Buffer.from(buffer),bytes);this.family=family;this.load=()=>Promise.resolve(this);
  }};
  await new Promise((resolve,reject)=>receiver.receiveFont({type:'font',sha256:descriptor.sha256,bytes:bytes.length,data:bytes.toString('base64')},fontDoc,resolve,reject,environment));
  assert.equal(registered.family,'GameFont_'+descriptor.sha256);
  const container=node('div');
  receiver.render(container,{type:'subtitle',text:'İğne ışığı: ÇÖŞÜ çğöşü',presentation:{fontSha256:descriptor.sha256}},1080,fontDoc);
  assert.equal(container.children[0].children[0].style.fontFamily,registered.family);
});

test('receiver accepts private IPv4 endpoints and blocks URLs, DNS, credentials and public IPs', () => {
  assert.equal(receiver.endpoint('192.168.1.20:43824'), 'ws://192.168.1.20:43824/subtitles');
  assert.equal(receiver.endpoint('172.16.0.1:1'), 'ws://172.16.0.1:1/subtitles');
  for (const bad of ['ws://192.168.1.2:1', '192.168.1.2:0', '192.168.1.2:65536', '127.0.0.1:1', '8.8.8.8:80', 'evil.local:1', '192.168.1.2:1/path', 'user@192.168.1.2:1', '192.168.01.2:1', '172.32.0.1:1']) {
    assert.throws(() => receiver.endpoint(bad), undefined, bad);
  }
});

test('large font packets register and oversized fonts are rejected before decoding', async () => {
  const descriptor = JSON.parse(fs.readFileSync(path.join(__dirname, '../server/game-catalog/profiles/font-assets.json')))['Inter-Regular'];
  const original = fs.readFileSync(path.join(__dirname, '../server/game-catalog/fonts/' + descriptor.sha256 + '.ttf'));
  const bytes = Buffer.alloc(2 * 1024 * 1024);
  original.copy(bytes);
  const hash = crypto.createHash('sha256').update(bytes).digest('hex');
  let registered, decoded = 0;
  const fontDoc = {fonts:{add(font){registered=font;}}};
  const environment = {atob:data=>{decoded++;return Buffer.from(data,'base64').toString('binary');},FontFace:function(family,buffer){
    assert.equal(buffer.byteLength,bytes.length);this.family=family;this.load=()=>Promise.resolve(this);
  }};
  const packet = {type:'font',sha256:hash,bytes:bytes.length,data:bytes.toString('base64')};
  await new Promise((resolve,reject)=>receiver.receiveFont(packet,fontDoc,resolve,reject,environment));
  assert.equal(registered.family,'GameFont_'+hash);
  await assert.rejects(new Promise((resolve,reject)=>receiver.receiveFont({...packet,bytes:bytes.length+1},fontDoc,resolve,reject,environment)),/Invalid font/);
  await assert.rejects(new Promise((resolve,reject)=>receiver.receiveFont({...packet,data:packet.data+'AAAA'},fontDoc,resolve,reject,environment)),/Invalid font/);
  assert.equal(decoded,1);
});

test('rendering preserves Unicode, treats markup as text, clamps bounds, and clears', () => {
  const container = node('div');
  receiver.render(container, {type:'subtitle',texts:['Çığ 日本語 🎮 <script>bad()</script>','İkinci'],presentation:{
    fontSize:30,bold:true,textColor:0xff00ff00,backgroundColor:0xff000000,backgroundOpacity:.5,
    subtitleRegions:[{left:0,top:0,width:1,height:.5},{left:.5,top:.8,width:2,height:2}]}},1080,doc);
  assert.equal(container.children.length,2);
  assert.equal(container.children[0].children[0].textContent,'Çığ 日本語 🎮 <script>bad()</script>');
  assert.equal(container.children[0].children[0].style.fontSize,'60px');
  assert.equal(container.children[0].children[0].style.color,'rgba(0,255,0,1)');
  assert.equal(container.children[1].style.width,'50%');
  receiver.render(container,{type:'clear'},1080,doc);
  assert.equal(container.children.length,0);
  receiver.render(container,{type:'subtitle',text:'hidden',presentation:{enabled:false}},1080,doc);
  assert.equal(container.children.length,0);
});

test('HDMI is selected before a full screen BEHIND window; unsupported inputs fail', () => {
  const calls=[]; let success=false,failed=false;
  const source={type:'HDMI',number:3};
  const tizen={tvwindow:{setSource(value,ok,error,type){calls.push(['source',value,type]);ok();},
    show(ok,error,rect,type,z){calls.push(['show',rect,type,z]);ok();}}};
  receiver.showHdmi(tizen,source,()=>success=true,()=>failed=true);
  assert.deepEqual(calls,[['source',source,'MAIN'],['show',['0%','0%','100%','100%'],'MAIN','BEHIND']]);
  assert.equal(success,true); assert.equal(failed,false);
  receiver.showHdmi(tizen,{type:'TV'},()=>assert.fail(),()=>failed=true); assert.equal(failed,true);
  receiver.showHdmi({tvwindow:{setSource(){throw Error('Permission');}}},source,()=>assert.fail(),()=>{});
});

function app() {
  const elements = {}, events = {}, timers = [], sockets=[];
  for (const id of ['controls','instructions','address','code','addressLabel','codeLabel','connect','test','confirm','disconnect','hdmi','subtitles','status','limits','support']) elements[id]=node(id === 'hdmi' ? 'select':'div');
  elements.address.value='192.168.1.20:43824'; elements.code.value='123456';
  const document={hidden:false, getElementById:id=>elements[id],createElement:node,addEventListener:(name,fn)=>events[name]=fn};
  class FakeSocket {
    constructor(url){this.url=url;this.readyState=1;this.sent=[];sockets.push(this);}
    send(data){this.sent.push(JSON.parse(data));} close(){this.readyState=3;this.onclose?.({code:1000});}
  }
  const tizen={systeminfo:{getPropertyValue(name,ok){ok({connected:[{type:'HDMI',number:1}]});}},tvwindow:{setSource(source,ok){ok();},show(ok){ok();}}};
  const context={navigator:{language:'tr'},document,TvReceiver:receiver,WebSocket:FakeSocket,tizen,Date,JSON,
    setTimeout(fn){timers.push(fn);return timers.length;},clearTimeout(){},setInterval(){return 1;},clearInterval(){}};
  context.window={tizen,innerHeight:1080,addEventListener:(name,fn)=>events[name]=fn};
  vm.runInNewContext(fs.readFileSync(__dirname+'/app.js','utf8'),context);
  return {elements,events,sockets,document,timers};
}

test('TV does not announce ready until paired, HDMI shown and user confirms; hiding clears subtitles', () => {
  const a=app(), e=a.elements;
  e.test.onclick(); assert.equal(a.sockets.length,0);
  e.connect.onclick(); const socket=a.sockets[0]; socket.onopen();
  assert.deepEqual(socket.sent[0],{type:'pair',code:'123456'});
  socket.onmessage({data:JSON.stringify({type:'paired',sessionToken:'a'.repeat(44)})});
  e.confirm.onclick(); assert.equal(socket.sent.some(m=>m.type==='ready'),false);
  e.test.onclick(); assert.equal(e.confirm.disabled,false); assert.equal(e.subtitles.children.length,1);
  e.confirm.onclick(); assert.equal(socket.sent.at(-1).type,'ready'); assert.equal(e.controls.style.display,'none');
  socket.onmessage({data:JSON.stringify({type:'subtitle',text:'Merhaba',presentation:{}})});
  assert.equal(e.subtitles.children.length,1);
  a.document.hidden=true; a.events.visibilitychange();
  assert.equal(e.subtitles.children.length,0); assert.equal(socket.readyState,3);
});

test('policy rejection stops automatic retries and stale messages do not render', () => {
  const a=app(),e=a.elements;
  e.connect.onclick();const old=a.sockets[0];old.onopen();old.onclose({code:1008});
  assert.equal(a.timers.length,0);
  old.onmessage({data:JSON.stringify({type:'subtitle',text:'stale'})});
  assert.equal(e.subtitles.children.length,0);
});

test('manifest requests only public capabilities and source remains ES5 compatible', () => {
  const config=fs.readFileSync(__dirname+'/config.xml','utf8');
  assert.match(config,/required_version="2.4"/);
  assert.match(config,/privilege\/tv.window/);
  assert.doesNotMatch(config,/partner|platform|screencapture|certificate/);
  for(const file of ['receiver.js','app.js']) assert.doesNotMatch(fs.readFileSync(__dirname+'/'+file,'utf8'),/\b(?:const|let|class)\s|=>|\.innerHTML\s*=/);
});
