const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const html = fs.readFileSync(path.join(__dirname, '../web-shell.html'), 'utf8');
const source = [...html.matchAll(/<script>([\s\S]*?)<\/script>/g)].at(-1)[1]
  .replace('$GODOT_CONFIG', '{canvasResizePolicy:2}');
function harness(phone) {
  const handlers = {}, viewportHandlers = {}, timers = new Map(), classes = new Set();
  let nextTimer = 0, config;
  const root = {classList:{add:x=>classes.add(x),remove:x=>classes.delete(x)},
    style:{setProperty:(key,value)=>root[key]=value}};
  const elements = {};
  for (const id of ['canvas','keyboard-done','message','progress','loading']) {
    elements[id] = {style:{}, width:1920,height:1080, addEventListener:(key,fn)=>handlers[id+key]=fn,
      remove(){}, focus(){document.activeElement=this;}};
  }
  const document = {documentElement:root,body:{},activeElement:null,
    getElementById:id=>elements[id],addEventListener:(key,fn)=>handlers[key]=fn};
  const window = {innerWidth:844,innerHeight:390,devicePixelRatio:3,
    scrollTo(){},addEventListener:(key,fn)=>handlers[key]=fn,
    visualViewport:{offsetTop:0,addEventListener:(key,fn)=>viewportHandlers[key]=fn}};
  class Engine {
    static getMissingFeatures(){return [];}
    constructor(value){config=value;}
    startGame(){return Promise.resolve();}
  }
  vm.runInNewContext(source,{document,window,screen:{width:phone?390:1024,height:844},
    matchMedia:()=>({matches:phone}),Engine,
    setTimeout:fn=>{timers.set(++nextTimer,fn);return nextTimer;},clearTimeout:id=>timers.delete(id)});
  return {handlers,window,document,elements,classes,config,viewportHandlers,
    settle(){for(const fn of timers.values())fn();timers.clear();}};
}
const h=harness(true), canvas=h.elements.canvas;
assert.equal(h.config.canvasResizePolicy,0);
const original=[canvas.width,canvas.height,canvas.style.width,canvas.style.height];
const input={tagName:'INPUT',parentElement:h.document.body,setAttribute(){},
  blur(){h.document.activeElement=null;h.handlers.focusout({target:this});}};
h.document.activeElement=input;
h.handlers.focusin({target:input});
for(let i=0;i<15;i++) {
  h.window.innerHeight=160+i;
  h.handlers.resize();
  h.window.visualViewport.offsetTop=i;
  h.viewportHandlers.scroll();
  assert.deepEqual([canvas.width,canvas.height,canvas.style.width,canvas.style.height],original);
}
assert(h.classes.has('editing'));
assert.equal(h.document.documentElement['--keyboard-top'],'26px');
// A transient engine blur/focus must not unlock/reflow the canvas.
input.blur();h.document.activeElement=input;h.handlers.focusin({target:input});h.settle();
assert(h.classes.has('editing'));
h.handlers['keyboard-doneclick']();
h.window.innerHeight=390;h.settle();
assert(!h.classes.has('editing'));
assert.equal(canvas.height,1170);
h.window.innerWidth=390;h.window.innerHeight=844;h.handlers.resize();
assert.equal(canvas.width,1170);assert.equal(canvas.height,2532);
const desktop=harness(false);
assert.equal(desktop.config.canvasResizePolicy,2);
assert(!desktop.classes.has('phone-input'));
console.log('PASS: keyboard resize lock, transient focus, completion, orientation, desktop/tablet unchanged');
