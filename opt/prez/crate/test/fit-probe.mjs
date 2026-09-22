// ST0024 AT01 -- the fit, measured in the DOM rather than in the pixels.
//
// A recording can only show that a line ended up inside the frame. It cannot
// show WHY: a headline whose word was broken mid-word is inside the frame too,
// and so is one the fit shrank. The distinctions this thread turns on -- the
// word on one line, the floor honoured, the ink inside the room, siblings at
// one size, a second fit changing nothing -- are all DOM facts, so they are
// read from the DOM. The pixel checks in video.sh cover the other half: that
// what the DOM says survives being recorded.
//
// Usage:  node fit-probe.mjs <port> <portrait|landscape> <slides>
//
// THE ROSTER COMES FROM THE PLAYER, NEVER FROM HERE. `window.__showreelFit`
// carries the selectors the player fits and reports its own measurements; a
// list of selectors in this file would be a second roster, and the first line
// added to the player would be untested with nothing saying so. What this file
// does NOT take from the player is the verdict: every check below is a relation
// the probe asserts itself, and the geometric ones (nothing crosses the frame,
// nothing overflows its own box, siblings match) are measured here from the
// live DOM, so a player that reported flattering numbers would still fail them.
//
// EXIT CODES, ONE PER OUTCOME (issue 0029's rule):
//   0  measured, every check passed
//   2  measured, a check failed -- the only code that is evidence about the fit
//   3  nothing was measured: no page target, or the player exposes no fit
const MEASURED_FAIL = 2;
const NOT_MEASURED = 3;

const [, , portArg, modeArg = 'portrait', slidesArg = '6', expectArg = 'fits-after'] = process.argv;
const PORT = Number(portArg);
const MODE = modeArg;
const SLIDES = Number(slidesArg);
// `nothing-written` is the stronger criterion (vc): over a reel whose lines
// all fit, the fit must write NOTHING -- no inline size, no inline wrap, no
// inline custom property. It is a statement about every reel rather than about
// one recording of one fixture, and it is what makes "a line that visibly fits
// never moves" checkable without comparing pictures.
const NOTHING_WRITTEN = expectArg === 'nothing-written';
const TOL = 1; // px: a layout read is rounded, and a whole pixel is the grain

const sleep = ms => new Promise(r => setTimeout(r, ms));

const results = [];
const check = (name, pass, got) => {
  results.push({ name, pass, got });
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
    if (r.result?.exceptionDetails) {
      throw new Error(r.result.exceptionDetails.exception?.description || 'evaluate threw');
    }
    return r.result?.result?.value;
  }
}

// Poll for the target rather than for the port: Chrome opens the socket before
// it registers a page, and a probe that fetched once would race a browser that
// was merely still starting (AT20's lesson, 7 Sep).
let pages = [];
for (let tries = 0; tries < 100; tries++) {
  try {
    const targets = await (await fetch(`http://127.0.0.1:${PORT}/json/list`)).json();
    pages = targets.filter(t => t.type === 'page' && t.url.startsWith('file://'));
    if (pages.length) break;
  } catch { /* not up yet; the loop is the retry */ }
  await sleep(100);
}
if (!pages.length) {
  console.log(`  FAIL ${MODE}: no page target on port ${PORT} after 10s`);
  console.log('fit-probe: NOT MEASURED');
  process.exit(NOT_MEASURED);
}

const ws = new WebSocket(pages[0].webSocketDebuggerUrl);
await new Promise(r => (ws.onopen = r));
const cdp = new CDP(ws);

// The face decides every width here, so nothing is measured until it has
// settled and the player has fitted the slide that is up (design D4).
await cdp.eval('document.fonts.ready.then(() => true)');
await sleep(200);

const hasHook = await cdp.eval('!!(window.__showreelFit && window.__showreelFit.report)');
if (!hasHook) {
  console.log(`  FAIL ${MODE}: the player exposes no window.__showreelFit, so the fit cannot be measured`);
  console.log('fit-probe: NOT MEASURED');
  process.exit(NOT_MEASURED);
}

// The orientation the window really has, rather than the one the caller meant.
// A window manager can clamp a requested size (AT20 measured exactly that on
// macOS CI), and every check below reads differently at the other orientation.
const isPortrait = await cdp.eval('matchMedia("(orientation:portrait)").matches');
check(`${MODE}_window_orientation`, isPortrait === (MODE === 'portrait'),
  `portrait=${isPortrait}`);

// One slide at a time, stepped with the player's own key, so the reel is driven
// the way a viewer drives it rather than by reaching into its internals.
const seen = { headline: 0, handle: 0, fitted: 0 };
for (let i = 0; i < SLIDES; i++) {
  const report = await cdp.eval(`(() => {
    const rows = window.__showreelFit.report();
    const stage = document.getElementById('stage').getBoundingClientRect();
    // The geometry is read HERE, from the live DOM, so it is the probe's own
    // reading and not the player's account of itself.
    for (const r of rows) {
      const el = r.node;
      const box = el.getBoundingClientRect();
      r.left = box.left; r.right = box.right;
      r.scrollW = el.scrollWidth; r.clientW = el.clientWidth;
      // What the fit WROTE, read off the element's own inline style.
      r.wroteSize = el.style.fontSize !== '';
      r.wroteWrap = el.style.overflowWrap !== '';
      r.wroteVars = false;
      for (let k = 0; k < el.style.length; k++) {
        if (el.style[k].indexOf('--fit-') === 0) r.wroteVars = true;
      }
      r.siblings = [...el.parentElement.children]
        .filter(s => s !== el && s.matches(r.sel))
        .map(s => parseFloat(getComputedStyle(s).fontSize));
      // A LINE DRAWN IN MOTION IS NOT HELD TO THE FRAME. The crawl rises
      // through it under a perspective transform and is clipped on purpose, so
      // its rect crosses the frame on a correct build; every static line is
      // held to it. The reason is reported rather than the check quietly
      // dropped.
      // The ancestors with their widths: when a line crosses the frame, the
      // question is always which box above it was measured wrongly, and a
      // failure that does not carry the chain sends the reader back to Chrome
      // to get it.
      // NO TEMPLATE LITERALS IN HERE: this whole block is itself inside one,
      // so a $-brace would be interpolated by node before the page ever sees
      // it, and the probe would die on a ReferenceError (measured).
      r.chain = [];
      for (let a = el; a && a.id !== 'stage'; a = a.parentElement) {
        r.chain.push((a.className || a.tagName.toLowerCase()) + ':' + a.offsetWidth + '/' + a.clientWidth);
      }
      r.transformed = false;
      for (let a = el; a && a.id !== 'stage'; a = a.parentElement) {
        if (getComputedStyle(a).transform !== 'none') { r.transformed = true; break; }
      }
      // A row of boxes sharing one grid track set must keep equal widths: a
      // word that grew its own track is the defect D2b names. Only row-mates
      // in a GRID, because siblings under any other parent (a socials row's
      // label and handle, a template's kicker and body) differ by design.
      const parent = el.parentElement;
      const pcs = getComputedStyle(parent);
      r.rowWidths = [];
      if (pcs.display.endsWith('grid')) {
        const top = box.top;
        r.rowWidths = [...parent.children]
          .filter(s => Math.abs(s.getBoundingClientRect().top - top) < 1)
          .map(s => s.getBoundingClientRect().width);
      }
      delete r.node;
    }
    return { rows, stage: { left: stage.left, right: stage.right } };
  })()`);

  for (const r of report.rows) {
    const where = `${MODE}_slide${i}_${r.sel.replace(/[^a-z]+/gi, '_')}`;
    seen[r.kind] = (seen[r.kind] || 0) + 1;
    if (r.fitted) seen.fitted++;

    // The floor is the contract D6 rests on: a fitted rule that declares none
    // cannot be fitted safely, and the player refuses to fit it.
    check(`${where}_declares_a_floor`, Number.isFinite(r.floor) && r.floor > 0, `floor=${r.floor}`);

    // Nothing crosses the frame. True at every orientation, for every static
    // line, fitted or not: it is the invariant issue 0045 broke. A line drawn
    // in motion is exempt, and says so rather than passing silently.
    if (r.transformed) {
      check(`${where}_frame_check_not_applicable`, true, 'drawn in motion and clipped by design');
    } else {
      check(`${where}_inside_the_frame`,
        r.left >= report.stage.left - TOL && r.right <= report.stage.right + TOL,
        `${Math.round(r.left)}..${Math.round(r.right)} in ${Math.round(report.stage.left)}..${Math.round(report.stage.right)}` +
        ` (word=${Math.round(r.word)} room=${Math.round(r.room)} ink=${Math.round(r.ink)} size=${r.size} fitted=${r.fitted}) chain ${r.chain.join(' < ')}`);
    }

    // Nothing overflows its own box, which is what a grown grid track looks
    // like from the outside (design D2b).
    check(`${where}_fits_its_own_box`, r.scrollW <= r.clientW + TOL,
      `scroll=${r.scrollW} client=${r.clientW}`);

    // Siblings under one rule are drawn at one size.
    check(`${where}_siblings_share_a_size`,
      r.siblings.every(s => Math.abs(s - r.size) < 0.5),
      `me=${r.size} siblings=[${r.siblings.join(',')}]`);

    // A row of boxes keeps equal widths: a word that grew its own track would
    // show up here as one box wider than the others.
    if (r.rowWidths.length > 1) {
      const spread = Math.max(...r.rowWidths) - Math.min(...r.rowWidths);
      check(`${where}_row_widths_equal`, spread <= TOL + 1, `spread=${spread.toFixed(1)}`);
    }

    // ONE RULE, TWO STRENGTHS (hv, 2026-09-22, ruling (b), which SUPERSEDES the
    // earlier "leave headlines at 16:9"): a line whose INK would leave its room
    // is fitted wherever it is drawn, and in a portrait window a headline is
    // held to the stronger test, its whole word against its room, because there
    // a word too wide is broken mid-word instead.
    const strong = r.kind === 'headline' && isPortrait;
    const measure = strong ? r.word : r.ink;
    check(`${where}_${strong ? 'word' : 'ink'}_fits_or_wraps_at_the_floor`,
      measure <= r.room + TOL || (Math.abs(r.size - r.floor) < 0.5 && r.wrapped),
      `${strong ? 'word' : 'ink'}=${Math.round(measure)} room=${Math.round(r.room)} size=${r.size} floor=${r.floor} wrapped=${r.wrapped}`);
    check(`${where}_never_below_the_floor`, r.size >= r.floor - 0.5, `size=${r.size} floor=${r.floor}`);

    // THE CRITERION BEHIND "a line that visibly fits never moves", asserted as
    // a MECHANISM rather than by comparing two recordings: a line that fits has
    // nothing written to it, so there is nothing that could render differently.
    if (NOTHING_WRITTEN) {
      check(`${where}_nothing_was_written`,
        !r.wroteSize && !r.wroteWrap && !r.wroteVars,
        `size=${r.wroteSize} wrap=${r.wroteWrap} vars=${r.wroteVars} (word=${Math.round(r.word)} ink=${Math.round(r.ink)} room=${Math.round(r.room)})`);
    }
  }

  // Fitting again must change nothing. A fit that is not idempotent moves
  // frames between two recordings of one reel, which AT12's determinism check
  // would find much later and much less clearly (vc, design D4).
  const stable = await cdp.eval(`(() => {
    const before = window.__showreelFit.report().map(r => r.size);
    window.__showreelFit.fit();
    const after = window.__showreelFit.report().map(r => r.size);
    return before.length === after.length && before.every((v, i) => Math.abs(v - after[i]) < 0.5);
  })()`);
  check(`${MODE}_slide${i}_fit_is_idempotent`, stable === true, `stable=${stable}`);

  await cdp.eval(`window.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowRight' })), true`);
  await sleep(150);
}

// A run that measured no line proved nothing, however many checks passed.
check(`${MODE}_measured_some_lines`, seen.headline + seen.handle > 0,
  `headlines=${seen.headline} handles=${seen.handle} fitted=${seen.fitted}`);

const failed = results.filter(r => !r.pass);
for (const r of results) {
  if (!r.pass) console.log(`  FAIL ${r.name}: ${r.got}`);
}
console.log(`fit-probe ${MODE}: ${results.length - failed.length}/${results.length} checks passed`);
ws.close();
process.exit(failed.length ? MEASURED_FAIL : 0);
