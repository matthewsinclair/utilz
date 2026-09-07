// AT20 -- AC19's BROWSER layer: the window that actually appears.
//
// AT18 asserts the argv `presenting_argv` builds, which is the only place a
// silently-DROPPED flag is catchable. It cannot tell a flag that was sent from
// one that was sent and IGNORED -- and that distinction is the whole reason
// AC19 exists: `--start-fullscreen` was passed on every launch for as long as
// the function existed, took no effect on macOS, and was found by a screenshot
// of a portrait window rather than by anything in the process, the exit status
// or the logs.
//
// So this measures the real window. It reports and asserts nothing on its own
// about WHICH size is right; the harness passes in what it expects, because the
// default lives in drive.rs and a copy of it here would be a second roster.
//
// Usage:  node at20-window-probe.mjs <port> <expected-w> <expected-h> <label>
//
// RESIDUAL, stated rather than glossed: this proves the window Chrome opened
// for the argv prez produced. It does not prove what a human sees on a physical
// monitor -- a window manager may still tile or resize it afterwards -- but
// that is the window manager's business, not prez's, whose contract is "ask for
// a window of the deck's shape".

const [, , portArg, wantWArg, wantHArg, label = 'window', excludeFile = ''] = process.argv;

// SELECTING THE RIGHT WINDOW WHEN TWO ARE OPEN.
// `prez present` builds into a TEMP file -- file:///.../T/prez-<pid>-<nanos> --
// so neither the deck's name nor any predictable string reaches the URL, and a
// filter written against "demo" matches nothing. (Measured 7 Sep; it is why the
// forwarding leg first reported no target on a browser that had one.) What IS
// reliable is the difference: record the page URLs before the second launch and
// take the one that was not there.
const excluded = new Set();
if (excludeFile) {
  const { readFileSync } = await import('node:fs');
  try {
    for (const line of readFileSync(excludeFile, 'utf8').split('\n')) {
      if (line.trim()) excluded.add(line.trim());
    }
  } catch { /* absent file means exclude nothing, which the caller controls */ }
}
const PORT = Number(portArg);
const wantW = Number(wantWArg);
const wantH = Number(wantHArg);

const sleep = ms => new Promise(r => setTimeout(r, ms));

const results = [];
const check = (name, got, want) => {
  const pass = String(got) === String(want);
  results.push({ name, got, want, pass });
  return pass;
};
// A tolerance is honest here and a lie in the other checks: Chrome's own window
// chrome (title bar, borders) is counted differently per platform, so an
// EXACT outer match would fail on a correct build for a reason that has nothing
// to do with prez. The ASPECT is what AC19 is about, so that is what is tested
// tightly; the absolute size is checked loosely enough to catch "it ignored the
// flag entirely" without pretending to pixel accuracy.
const near = (name, got, want, tol) => {
  const pass = Math.abs(got - want) <= tol;
  results.push({ name, got: `${got}(want ~${want}+-${tol})`, want, pass });
  return pass;
};

class CDP {
  constructor(ws) {
    this.ws = ws; this.id = 0; this.pending = new Map();
    ws.onmessage = e => {
      const m = JSON.parse(e.data);
      if (m.id && this.pending.has(m.id)) { this.pending.get(m.id)(m); this.pending.delete(m.id); }
    };
  }
  send(method, params = {}) {
    const id = ++this.id;
    return new Promise(res => { this.pending.set(id, res); this.ws.send(JSON.stringify({ id, method, params })); });
  }
  async eval(expression) {
    const r = await this.send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
    return r.result?.result?.value;
  }
}

// POLL FOR THE TARGET, NOT FOR THE PORT. The harness waits on the TCP socket,
// which Chrome opens BEFORE it has registered any target -- so a probe that
// fetched once raced it and reported "no page target" on a browser that was
// merely still starting. A fixed sleep would measure the sleep; this measures
// the condition. (Measured 7 Sep: the first AT20 run failed all three legs this
// way, on a launch that was working.)
let pages = [];
let sawTypes = new Set();
for (let tries = 0; tries < 100; tries++) {
  try {
    const targets = await (await fetch(`http://127.0.0.1:${PORT}/json/list`)).json();
    for (const t of targets) sawTypes.add(t.type);
    pages = targets.filter(t => t.type === 'page' && !excluded.has(t.url));
    if (pages.length) break;
  } catch { /* not up yet; the loop is the retry */ }
  await sleep(100);
}
if (!pages.length) {
  // Name what WAS there. "No page target" on its own sends the reader to the
  // wrong question when the real answer is that the window is a different type.
  console.log(`  FAIL ${label}: no NEW page target on port ${PORT} after 10s (excluding ${excluded.size}); saw types [${[...sawTypes].join(', ') || 'none'}]`);
  console.log('AT20: FAIL (1/1)');
  process.exit(1);
}

// THE ARTIFACT IS THE ONE prez BUILT, not one this probe made. If the window
// belongs to something else entirely, every size below would be measured off
// the wrong window and would still look plausible.
check('target_is_a_file_url', pages[0].url.startsWith('file://'), true);

const ws = new WebSocket(pages[0].webSocketDebuggerUrl);
await new Promise(r => (ws.onopen = r));
const cdp = new CDP(ws);

// Two independent readings of the same window. window.outerWidth is what the
// page sees; Browser.getWindowBounds is what the browser reports about its own
// window. They are measured separately ON PURPOSE -- if the two disagree, the
// number is not trustworthy and the check says so rather than picking one.
const outerW = await cdp.eval('window.outerWidth');
const outerH = await cdp.eval('window.outerHeight');

let boundsW = null, boundsH = null;
try {
  const { result: { windowId } } = await cdp.send('Browser.getWindowForTarget', { targetId: pages[0].id });
  const b = await cdp.send('Browser.getWindowBounds', { windowId });
  boundsW = b.result?.bounds?.width ?? null;
  boundsH = b.result?.bounds?.height ?? null;
} catch { /* reported as unavailable below, never silently skipped */ }

if (boundsW !== null) {
  near(`${label}_bounds_agree_with_page_w`, boundsW, outerW, 4);
  near(`${label}_bounds_agree_with_page_h`, boundsH, outerH, 4);
} else {
  results.push({ name: `${label}_browser_bounds`, got: 'UNAVAILABLE', want: 'a number', pass: false });
}

near(`${label}_width`, outerW, wantW, 40);
near(`${label}_height`, outerH, wantH, 90);

// THE CLAUSE THAT MATTERS. AC19(a) is about SHAPE -- hv's window came up
// portrait for a 16:9 deck -- so the aspect is asserted tightly even where the
// absolute pixels are allowed to drift.
const wantAspect = wantW / wantH;
const gotAspect = outerW / outerH;
check(`${label}_is_landscape`, outerW > outerH, true);
near(`${label}_aspect`, Number(gotAspect.toFixed(2)), Number(wantAspect.toFixed(2)), 0.25);

ws.close();

const failed = results.filter(r => !r.pass);
for (const r of results) {
  console.log(`  ${r.pass ? 'ok  ' : 'FAIL'} ${r.name}=${r.got}${r.pass ? '' : ` want=${r.want}`}`);
}
console.log(failed.length ? `AT20: FAIL (${failed.length}/${results.length})` : `AT20: PASS (${results.length} checks)`);
process.exit(failed.length ? 1 : 0);
