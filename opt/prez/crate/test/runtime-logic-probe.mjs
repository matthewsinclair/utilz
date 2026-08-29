#!/usr/bin/env node
//
// Drive the emitted runtime's KEY HANDLING with no browser at all.
//
// WHY THIS EXISTS BESIDE at04-runtime-probe.mjs RATHER THAN INSTEAD OF IT.
// AT04 drives real Chrome over CDP and is the only thing that can prove
// fullscreen, focus, real key events and layout. It also cannot run on a
// machine without a browser, which means every runtime change is unverified
// until someone with Chrome runs it -- and a keyboard runtime is exactly the
// kind of change that gets shipped on "it compiles".
//
// So this stubs the four DOM surfaces the runtime actually touches, loads the
// script OUT OF A BUILT ARTIFACT (not out of the Rust source -- what ships is
// what gets tested), and dispatches keydown events at it. What it proves is
// dispatch and state: which slide is current, which mode is on, what the bar
// advertises. What it deliberately does NOT claim is anything visual.
//
// Usage: runtime-logic-probe.mjs <artifact.html>

import { readFileSync } from 'node:fs';

const file = process.argv[2];
if (!file) { console.error('usage: runtime-logic-probe.mjs <artifact.html>'); process.exit(2); }

const html = readFileSync(file, 'utf8');

// THE RUNTIME, NOT THE FIRST SCRIPT. A mermaid deck vendors the whole library
// into a <script> ahead of this one, so matching the first block loaded 3.5 MB
// of esbuild bundle into a four-function DOM stub and died on line 3859. The
// instrument was fine; the noun was wrong. Selected by a marker only the
// runtime carries, so adding another script block cannot silently change which
// one is under test.
const blocks = [...html.matchAll(/<script>([\s\S]*?)<\/script>/g)].map(m => m[1]);
const carrying = blocks.filter(b => b.includes("addEventListener('keydown'"));
if (carrying.length !== 1) {
  console.error(`expected exactly one script carrying the runtime, found ${carrying.length} of ${blocks.length}`);
  process.exit(2);
}

// A MERMAID DECK PUTS 3.5 MB OF VENDORED BUNDLE IN THE SAME TAG. html.rs emits
// RUNTIME_JS first and appends the library after it, so the runtime is the head
// of the block up to its own IIFE terminator. Cutting there rather than loading
// the lot is not an optimisation: evaluating the bundle in a four-function DOM
// stub died 3859 lines in, on esbuild's own bootstrap, which is a failure about
// the stub and not about prez.
const END = '\n})();\n';
const cut = carrying[0].indexOf(END);
const runtime = cut === -1 ? carrying[0] : carrying[0].slice(0, cut + END.length);

// THE EXTRACTION CHECKS ITSELF. A boundary read out of a text file is exactly
// the kind of thing that silently starts selecting the wrong span, and the
// symptom would be a probe that passes having tested something else.
if (!runtime.includes('var BINDINGS')) {
  console.error('extracted span is not the runtime: no binding table in it');
  process.exit(2);
}
if (runtime.includes('esbuild')) {
  console.error('extracted span ran past the runtime into the vendored bundle');
  process.exit(2);
}
const script = [runtime];

// ---------------------------------------------------------------- the stub
const classList = () => {
  const set = new Set();
  return {
    add: (c) => set.add(c),
    remove: (c) => set.delete(c),
    contains: (c) => set.has(c),
    toggle: (c, on) => (on === undefined ? (set.has(c) ? set.delete(c) : set.add(c)) : (on ? set.add(c) : set.delete(c))),
    _set: set,
  };
};
const el = (tag) => ({
  tagName: String(tag).toUpperCase(), className: '', textContent: '', type: '', value: '', min: '',
  classList: classList(), children: [], firstChild: null, form: null,
  appendChild(c) { this.children.push(c); this.firstChild = this.children[0] || null; c.parent = this;
                   if (c.tagName === 'INPUT' && this.tagName === 'FORM') { c.form = this; } return c; },
  removeChild(c) { this.children = this.children.filter(x => x !== c); this.firstChild = this.children[0] || null; return c; },
  setAttribute() {}, focus() { doc.activeElement = this; }, blur() { doc.activeElement = null; },
  addEventListener(type, fn) { (this._h ||= {})[type] = fn; },
  dispatchEvent(e) { const f = this._h && this._h[e.type]; if (f) { f(e); } return true; },
  scrollIntoView() {},
  querySelector(sel) { return find(this, sel); },
});

// Counted off the <section> openers specifically: `gp-slide` also appears in
// the stylesheet and in the runtime's own source, both of which are in this
// file, so a bare substring count over the whole artifact is not the number of
// slides -- it is the number of times the word occurs.
const slideCount = (html.match(/<section class="gp-slide/g) || []).length;
const slides = Array.from({ length: slideCount }, () => { const s = el('section'); s.classList.add('gp-slide'); return s; });
const counter = el('div'); counter.classList.add('gp-counter');
const body = el('body');

function find(root, sel) {
  const want = sel.replace(/^\./, '');
  const walk = (n) => {
    for (const c of n.children) {
      if (c.className && c.className.split(/\s+/).includes(want)) { return c; }
      const deep = walk(c); if (deep) { return deep; }
    }
    return null;
  };
  return walk(root);
}

const listeners = {};
const doc = {
  body, activeElement: null, fullscreenElement: null,
  documentElement: { requestFullscreen() { doc.fullscreenElement = doc.documentElement; } },
  exitFullscreen() { doc.fullscreenElement = null; },
  createElement: el,
  createTextNode: (t) => ({ tagName: '#text', textContent: t, classList: classList(), children: [] }),
  addEventListener(type, fn) { listeners[type] = fn; },
  querySelectorAll(sel) { return sel.includes('gp-slide') ? slides : []; },
  querySelector(sel) { return sel.includes('gp-counter') ? counter : find(body, sel); },
};
const winListeners = {};
let hash = '';
const loc = {
  get hash() { return hash; },
  set hash(v) { const changed = hash !== v; hash = v; if (changed && winListeners.hashchange) { winListeners.hashchange(); } },
  reload() { loc._reloaded = (loc._reloaded || 0) + 1; },
};
const win = { addEventListener(t, f) { winListeners[t] = f; }, close() { win._closed = (win._closed || 0) + 1; } };

const ctx = {
  document: doc, window: win, location: loc, Array,
  setTimeout: () => 0, clearTimeout: () => {}, Math, String, parseInt, isNaN, Event: class { constructor(t) { this.type = t; } },
};
// Function rather than eval, so the runtime sees exactly these globals and
// nothing leaks in from node's own scope.
new Function(...Object.keys(ctx), script[0])(...Object.values(ctx));

// ---------------------------------------------------------------- the checks
let pass = 0, fail = 0;
const check = (name, got, want) => {
  if (String(got) === String(want)) { console.log(`  ok    ${name} = ${got}`); pass++; }
  else { console.log(`  FAIL  ${name} = ${got}, wanted ${want}`); fail++; }
};
const press = (key, target) => listeners.keydown({ key, target: target || body, metaKey: false, ctrlKey: false, altKey: false, preventDefault() {} });
const current = () => slides.findIndex(s => s.classList.contains('gp-current')) + 1;
const indexing = () => body.classList.contains('gp-overview');
const bar = () => doc.querySelector('.gp-bar');
const keysOn = () => find(bar(), '.gp-bar-keys').classList.contains('gp-on');
const items = () => find(bar(), '.gp-bar-keys').children.length;

console.log(`\nruntime logic probe -- ${slideCount} slides, no browser`);
check('initial slide', current(), 1);
check('counter painted', counter.textContent, `1 / ${slideCount}`);

press('ArrowRight'); check('arrow right', current(), 2);
press(' ');          check('space advances outside the index', current(), 3);
press('ArrowLeft');  check('arrow left', current(), 2);
press('Home');       check('home', current(), 1);
press('End');        check('end', current(), slideCount);
press('ArrowRight'); check('past the end stays', current(), slideCount);

// hv, 29 Aug: enter and space COMMIT the highlighted slide in index mode.
press('i');          check('i opens the index', indexing(), true);
press('Home');       check('arrows still move the highlight in the index', current(), 1);
press('ArrowRight'); check('and keep moving it', current(), 2);
press(' ');          check('SPACE commits rather than advancing', current(), 2);
check('space closed the index', indexing(), false);

press('i');          check('index again', indexing(), true);
press('ArrowRight'); check('highlight moves', current(), 3);
press('Enter');      check('ENTER commits too', current(), 3);
check('enter closed the index', indexing(), false);

// Enter outside the index must do nothing at all -- it is bound only by `when`.
press('Enter');      check('enter outside the index is inert', current(), 3);
check('and did not open anything', indexing(), false);

press('Escape');     check('escape does not touch the index', indexing(), false);
check('escape asked the window to close', win._closed, 1);

// The bar tells the truth about the CURRENT mode.
press('?');          check('bar opens', keysOn(), true);
const outside = items();
press('i');          check('index on with the bar open', indexing(), true);
const inside = items();
check('the bar re-renders per mode', inside === outside ? 'same' : 'different', 'different');
const labels = find(bar(), '.gp-bar-keys').children.map(i => i.children[i.children.length - 1].textContent);
check('index mode advertises the commit', labels.includes('open this slide'), true);
check('and drops it outside', (press('i'), find(bar(), '.gp-bar-keys').children.map(i => i.children[i.children.length - 1].textContent).includes('open this slide')), false);

press('r'); check('r reloads', loc._reloaded, 1);
press('f'); check('f enters fullscreen', String(doc.fullscreenElement !== null), 'true');
press('f'); check('f leaves it', String(doc.fullscreenElement === null), 'true');

console.log(`\npassed ${pass}   failed ${fail}`);
process.exit(fail > 0 ? 1 : 0);
