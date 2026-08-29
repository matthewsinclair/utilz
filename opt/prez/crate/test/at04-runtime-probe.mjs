// AT04 -- the base runtime (AC05), driven in a real browser over CDP.
//
// **WHY CDP AND NOT A SYNTHETIC KeyboardEvent.** This started as vc's fullscreen
// probe (28 Aug 2026) and the reason it had to exist is the reason the whole
// file is written this way. cc's first attempt dispatched KeyboardEvents from
// page script, which proves the handler runs but CANNOT prove `f` fullscreens:
// requestFullscreen requires transient user activation, script-made events do
// not carry it, so a CORRECT implementation fails that test and a broken one is
// indistinguishable from it. A check that cannot go red for the right reason is
// not a check. CDP-injected input is TRUSTED input and grants activation; that
// is the whole trick, and it is why every key here goes through Input.dispatch
// rather than through the DOM.
//
// Dependency-free: Node 22+ ships a global WebSocket, so this needs no install.
//
// Usage (the acceptance runner does this for you):
//   chrome --headless=new --remote-debugging-port=9333 --window-size=1280,800 \
//     --user-data-dir=<tmp> "file://<artifact>.html" &
//   node at04-runtime-probe.mjs [port]
//
// RESIDUAL, stated rather than glossed (vc's wording, still true): headless
// proves the API contract and the toggle. It does not prove physical pixels on a
// physical monitor -- but that is the browser's job, not prez's, whose
// contract is "press f, the browser goes fullscreen".

const PORT = Number(process.argv[2] || 9333);
const sleep = ms => new Promise(r => setTimeout(r, ms));

class CDP {
  constructor(ws) {
    this.ws = ws;
    this.id = 0;
    this.pending = new Map();
    ws.onmessage = e => {
      const m = JSON.parse(e.data);
      if (m.id && this.pending.has(m.id)) { this.pending.get(m.id)(m); this.pending.delete(m.id); }
    };
  }
  send(method, params = {}) {
    const id = ++this.id;
    return new Promise(res => {
      this.pending.set(id, res);
      this.ws.send(JSON.stringify({ id, method, params }));
    });
  }
  async eval(expression) {
    const r = await this.send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
    return r.result?.result?.value;
  }
}

const KEYS = {
  ArrowRight: [39, 'ArrowRight'], ArrowLeft: [37, 'ArrowLeft'],
  PageDown: [34, 'PageDown'], PageUp: [33, 'PageUp'],
  Home: [36, 'Home'], End: [35, 'End'],
  Escape: [27, 'Escape'], ' ': [32, 'Space'], f: [70, 'KeyF'],
  i: [73, 'KeyI'], g: [71, 'KeyG'], '?': [191, 'Slash'],
};

async function press(cdp, key) {
  const [vk, code] = KEYS[key];
  const printable = key === ' ' || key === 'f' || key === 'i' || key === 'g' || key === '?';
  for (const type of printable ? ['rawKeyDown', 'char', 'keyUp'] : ['rawKeyDown', 'keyUp']) {
    await cdp.send('Input.dispatchKeyEvent', {
      type, key, code,
      text: type === 'char' ? key : undefined,
      windowsVirtualKeyCode: vk, nativeVirtualKeyCode: vk,
    });
  }
  await sleep(120);
}

const results = [];
const check = (name, got, want) => {
  const pass = String(got) === String(want);
  results.push({ name, got, want, pass });
  return pass;
};

const current = '(function(){var s=document.querySelectorAll(".gp-slide");' +
  'for(var i=0;i<s.length;i++){if(s[i].classList.contains("gp-current"))return i+1}return 0})()';
const counter = 'document.querySelector(".gp-counter").textContent';
const overviewing = 'document.body.classList.contains("gp-overview")';

const targets = await (await fetch(`http://127.0.0.1:${PORT}/json/list`)).json();
const pages = targets.filter(t => t.type === 'page');
if (!pages.length) {
  console.error(`no page target on :${PORT} -- is chrome running with --remote-debugging-port?`);
  process.exit(2);
}
const ws = new WebSocket(pages[0].webSocketDebuggerUrl);
await new Promise(r => { ws.onopen = r; });
const cdp = new CDP(ws);
await cdp.send('Runtime.enable');
await sleep(400);

const total = await cdp.eval('document.querySelectorAll(".gp-slide").length');
check('slides_found', total, 6);
check('initial_slide', await cdp.eval(current), 1);
check('initial_counter', await cdp.eval(counter), `1 / ${total}`);

await press(cdp, 'ArrowRight'); check('arrow_right', await cdp.eval(current), 2);
await press(cdp, ' ');          check('space', await cdp.eval(current), 3);
await press(cdp, 'PageDown');   check('page_down', await cdp.eval(current), 4);
await press(cdp, 'ArrowLeft');  check('arrow_left', await cdp.eval(current), 3);
await press(cdp, 'PageUp');     check('page_up', await cdp.eval(current), 2);
await press(cdp, 'End');        check('end', await cdp.eval(current), total);
check('counter_tracks', await cdp.eval(counter), `${total} / ${total}`);

// The boundaries, which is where this class of runtime usually runs off the end.
await press(cdp, 'ArrowRight'); check('past_end_stays', await cdp.eval(current), total);
await press(cdp, 'Home');       check('home', await cdp.eval(current), 1);
await press(cdp, 'ArrowLeft');  check('before_start_stays', await cdp.eval(current), 1);

// THE INDEX IS ON `i` NOW, NOT ON Escape (hv, 29 Aug). Escape toggling a mode
// was the complaint -- one key that meant "open this" and "close this"
// depending on invisible state. These three lines used to press Escape.
await press(cdp, 'i');          check('index_on', await cdp.eval(overviewing), true);
await press(cdp, 'i');          check('index_toggles_off', await cdp.eval(overviewing), false);
await press(cdp, 'i');          check('index_on_again', await cdp.eval(overviewing), true);
await cdp.eval('document.querySelectorAll(".gp-slide")[2].click()');
await sleep(150);
check('index_click_jumps', await cdp.eval(current), 3);
check('index_closed_by_click', await cdp.eval(overviewing), false);
check('click_wrote_the_hash', await cdp.eval('location.hash'), '#3');

// AND ESCAPE MUST NOT TOUCH THE INDEX ANY MORE. Asserted as its own check
// rather than left implied by the three above: "i works" and "Escape no longer
// does" are two claims, and a runtime that bound BOTH would satisfy the first
// while the change hv asked for had not happened.
await press(cdp, 'Escape');
check('escape_does_not_open_the_index', await cdp.eval(overviewing), false);

// ---- the bar, and the keys that drive it ----
const barOn = 'document.querySelector(".gp-bar").classList.contains("gp-on")';
const keysOn = 'document.querySelector(".gp-bar-keys").classList.contains("gp-on")';
const gotoOn = 'document.querySelector(".gp-bar-goto").classList.contains("gp-on")';

check('bar_exists', await cdp.eval('!!document.querySelector(".gp-bar")'), true);
check('bar_starts_hidden', await cdp.eval(barOn), false);
// The keycaps are BUILT FROM THE BINDING TABLE, so this count is the number of
// bindings. It is asserted because an empty bar would render, be styled, be
// toggleable, and advertise nothing.
check('bar_lists_every_binding', await cdp.eval('document.querySelectorAll(".gp-bar-item").length'), 10);
check('keycaps_are_kbd_elements', await cdp.eval('document.querySelectorAll(".gp-bar .gp-key").length > 0'), true);

await press(cdp, '?');          check('help_opens', await cdp.eval(keysOn), true);
check('bar_visible_with_help', await cdp.eval(barOn), true);
await press(cdp, '?');          check('help_toggles_off', await cdp.eval(keysOn), false);
check('bar_hidden_again', await cdp.eval(barOn), false);

// go-to-page: open, type, submit, and the clamp hv asked for by name.
await press(cdp, 'g');          check('goto_opens', await cdp.eval(gotoOn), true);
check('goto_focuses_its_input', await cdp.eval('document.activeElement === document.querySelector(".gp-bar-goto input")'), true);
await cdp.eval('(function(){var i=document.querySelector(".gp-bar-goto input");i.value="2";' +
  'i.form.dispatchEvent(new Event("submit",{cancelable:true,bubbles:true}));return 1})()');
await sleep(150);
check('goto_jumps', await cdp.eval(current), 2);
check('goto_closes_after_submit', await cdp.eval(gotoOn), false);

// "99 on a 10 page doc goes to page 10" -- hv's own example, as its own check.
await press(cdp, 'g');
await cdp.eval('(function(){var i=document.querySelector(".gp-bar-goto input");i.value="99";' +
  'i.form.dispatchEvent(new Event("submit",{cancelable:true,bubbles:true}));return 1})()');
await sleep(150);
check('goto_clamps_past_the_end', await cdp.eval(current), total);

// Escape INSIDE the input cancels the input. It must not reach the quit path,
// or changing your mind about a page number closes the deck.
await press(cdp, 'g');          check('goto_reopens', await cdp.eval(gotoOn), true);
await press(cdp, 'Escape');     check('escape_cancels_the_input', await cdp.eval(gotoOn), false);
check('escape_in_input_did_not_navigate', await cdp.eval(current), total);

await cdp.eval('location.hash = "#3"');
await sleep(150);

// Fullscreen: three separate claims, and the toggle is the one a synthetic
// event could never reach.
check('fullscreen_before', await cdp.eval('String(document.fullscreenElement)'), 'null');
await press(cdp, 'f'); await sleep(500);
check('fullscreen_entered', await cdp.eval('String(document.fullscreenElement && document.fullscreenElement.tagName)'), 'HTML');
check('fullscreen_fills', await cdp.eval('window.innerHeight === screen.height'), true);
await press(cdp, 'f'); await sleep(500);
check('fullscreen_toggles_out', await cdp.eval('String(document.fullscreenElement)'), 'null');

// Deep-link survival, proven by a real reload rather than by an in-page claim.
await cdp.eval('location.hash = "#4"');
await sleep(150);
await cdp.send('Page.enable');
await cdp.send('Page.reload', { ignoreCache: true });
await sleep(900);
check('hash_survives_reload', await cdp.eval(current), 4);
check('counter_survives_reload', await cdp.eval(counter), `4 / ${total}`);

ws.close();

const failed = results.filter(r => !r.pass);
for (const r of results) {
  console.log(`  ${r.pass ? 'ok  ' : 'FAIL'} ${r.name}=${r.got}${r.pass ? '' : ` want=${r.want}`}`);
}
console.log(failed.length ? `AT04: FAIL (${failed.length}/${results.length})` : `AT04: PASS (${results.length} checks)`);
process.exit(failed.length ? 1 : 0);
