// AT12 -- AC13. The artifact renders the same on every machine.
//
// Written by vc, 2026-08-29, to hand to cc: the subtlety in this check is not
// the measurement, it is WHICH DECK you point it at (see THE TRAP below), and a
// probe that already goes red for the right reason is more use than a
// description of one.
//
// It deliberately carries NO contrast maths. theme-legibility-probe.html owns
// legibility; this owns determinism. Two probes measuring one thing is how the
// numbers start disagreeing.
//
// Usage:  node at12-determinism-probe.mjs <cdp-port> <artifact-label>
//
// Exit 0 if the artifact is deterministic, 1 if not. Every check prints what it
// saw, so a red says which token moved rather than only that one did.
//
// ---------------------------------------------------------------------------
// THE TRAP, and it is the whole reason this file has a comment block.
//
// There are TWO independent sources of viewer-preference branching:
//
//   1. theme CSS   -- @media (prefers-color-scheme:) flipping the --gp- palette
//   2. mermaid.rs  -- window.matchMedia(...) choosing the diagram palette
//
// The second is ONLY in the artifact when the deck opts into mermaid. And
// examples/demo.md -- the deck every other AT uses -- does NOT opt in: its
// `mermaid: true` sits inside a fenced yaml block as documentation, which is
// the same fence-awareness case AC04 exists for.
//
// So AT12 run on demo.md alone reports blueprint CLEAN, because blueprint is
// the one theme with no @media block. Flatten the other six and that run goes
// fully GREEN while the mermaid defect -- the defect hv actually found, the
// reason AC13 exists -- is still there.
//
// A check that goes green on the very defect that caused it to be written is
// the sharpest version of the tell this thread has produced. RUN IT ON A
// MERMAID-OPTED DECK (examples/test_pres.md) AS WELL AS A PLAIN ONE.
// ---------------------------------------------------------------------------

const PORT = process.argv[2] || '9350';
const LABEL = process.argv[3] || 'artifact';

// Every host preference an artifact could branch on. Grepping the SOURCE is not
// enough and is not this probe's job -- an artifact is what ships, and a theme
// reaches it through inlining, so the artifact is the only honest target.
const PREFERENCE_QUERIES = [
  'prefers-color-scheme',
  'prefers-reduced-motion',
  'prefers-contrast',
  'forced-colors',
  'navigator.language',
];

const targets = await (await fetch(`http://127.0.0.1:${PORT}/json/list`)).json();
const page = targets.find((t) => t.type === 'page');
if (!page) {
  console.error('  FAIL setup: no page target on the debugging port');
  process.exit(1);
}

const ws = new WebSocket(page.webSocketDebuggerUrl);
await new Promise((res) => (ws.onopen = res));

let id = 0;
const pending = new Map();
ws.onmessage = (m) => {
  const msg = JSON.parse(m.data);
  if (msg.id && pending.has(msg.id)) {
    pending.get(msg.id)(msg);
    pending.delete(msg.id);
  }
};

function send(method, params = {}) {
  const n = ++id;
  return new Promise((res) => {
    pending.set(n, res);
    ws.send(JSON.stringify({ id: n, method, params }));
  });
}

async function evaluate(expr) {
  const r = await send('Runtime.evaluate', {
    expression: expr,
    returnByValue: true,
    awaitPromise: true,
  });
  return r.result?.result?.value;
}

let failed = 0;
const ok = (m) => console.log(`  ok   ${m}`);
const bad = (m) => {
  console.log(`  FAIL ${m}`);
  failed++;
};

// --- 1. The source half: does the artifact BRANCH on a preference ------------
//
// THIS USED TO GREP outerHTML AND IT WAS WRONG, in the exact way this file's
// other comment block lectures about. A correctly flattened theme documents its
// own flattening -- "NO prefers-color-scheme block, deliberately" -- that
// comment is inlined into the artifact verbatim, and a text search then goes RED
// on the fix. Caught by utilz-cc on 2026-08-29, on a grep vc had handed it as
// the instrument to verify with. The check was named "carries a colour-scheme
// block" and measured "mentions the string".
//
// So the CSS half is STRUCTURAL: walk the CSSOM, where a comment cannot appear
// by construction, and look for an actual CSSMediaRule. Not a smaller target --
// a different one, and the right one.
const cssHits = JSON.parse(await evaluate(`(() => {
  var out = [];
  function walk(rules) {
    for (var i = 0; i < rules.length; i++) {
      var r = rules[i];
      // 4 === CSSRule.MEDIA_RULE. conditionText is the live query text.
      if (r.type === 4) {
        out.push(r.conditionText || r.media.mediaText);
        if (r.cssRules) { walk(r.cssRules); }
      } else if (r.cssRules) { walk(r.cssRules); }
    }
  }
  for (var s = 0; s < document.styleSheets.length; s++) {
    try { walk(document.styleSheets[s].cssRules); } catch (e) { out.push('UNREADABLE-SHEET'); }
  }
  return JSON.stringify(out);
})()`));

const branching = cssHits.filter((c) =>
  PREFERENCE_QUERIES.some((q) => c.indexOf(q) !== -1)
);
if (cssHits.includes('UNREADABLE-SHEET')) {
  bad(`${LABEL}: a stylesheet could not be read -- not measured, not passed`);
} else if (branching.length === 0) {
  ok(`${LABEL}: no preference @media rule in ${cssHits.length} media rule(s)`);
} else {
  bad(`${LABEL}: ${branching.length} preference @media rule(s): ${branching.join(', ')}`);
}

// Scripts have no CSSOM equivalent, so this half stays textual -- but comments
// are stripped first, for the same reason. mermaid.rs's matchMedia branch is
// live code and survives the strip; a comment describing it does not.
//
// THE LINE-COMMENT STRIP ONLY FIRES AT LINE-START OR AFTER WHITESPACE, and that
// is not fussiness. The first version guarded with `[^:]` to protect `https://`,
// which it did -- but a `//` inside a STRING literal is preceded by a quote, so
// it matched, and everything to the end of that line vanished from the probe's
// view. The artifact has ONE <script> holding prez's runtime and the whole
// 3.5MB mermaid library, whose minified lines run to 325KB, so a single such
// match hides an enormous amount of live code. Measured on the real artifact:
// the old strip removed 320,543 chars (9.0% of live script), this one removes
// 22,184 (0.6%) -- and a preference query hidden behind a stripped `//` would
// make this probe report GREEN on a real defect.
//
// Found by utilz-cc verifying the repair against a real artifact rather than
// against its description, which is why it saw what three chosen-artifact cases
// could not. Its proposed fix -- treat "raw contains it, stripped does not" as
// UNMEASURED -- is rejected deliberately: mermaid.rs is about to carry a comment
// recording that it no longer branches on prefers-color-scheme, exactly as the
// themes now do, so that check would report unmeasured (and fail under --strict)
// on correctly fixed code that documents its own fix. That is the same defect
// one level down, introduced by the repair for it.
//
// RESIDUAL, and this class is REDUCED rather than CLOSED. Two shapes remain in
// the 0.6%. Genuine line comments, which is the case this half is meant to
// ignore and so is not a gap. And `var s = "a // b"` -- a `//` inside a string
// preceded by whitespace INSIDE that string, which `\s` cannot tell from
// whitespace in code, so it still eats to end of line. Rarer than the bare
// `a//b` form the fix closed, and not worth a tokeniser for one check; named by
// utilz-cc, who added the case my four did not cover.
//
// It is written down because a blind spot that shrank by 14x and got recorded as
// GONE is how the next instance gets in. This comment is the control for the
// part the regex cannot reach.
const scriptHits = JSON.parse(await evaluate(`(() => {
  var out = [];
  var qs = ${JSON.stringify(PREFERENCE_QUERIES)};
  var els = document.querySelectorAll('script');
  for (var i = 0; i < els.length; i++) {
    var src = els[i].textContent || '';
    var stripped = src.replace(/\\/\\*[\\s\\S]*?\\*\\//g, '').replace(/(^|\\s)\\/\\/[^\\n]*/g, '$1');
    for (var j = 0; j < qs.length; j++) {
      if (stripped.indexOf(qs[j]) !== -1) { out.push(qs[j]); }
    }
  }
  return JSON.stringify(out);
})()`));

if (scriptHits.length === 0) {
  ok(`${LABEL}: no preference query in live script code`);
} else {
  bad(`${LABEL}: script branches on ${[...new Set(scriptHits)].join(', ')}`);
}

// --- 2. The behaviour half: does the palette MOVE between schemes ------------
// The grep alone would pass a theme branching on a preference this list has
// never heard of. Measuring the rendered result is what closes that.
async function paletteUnder(scheme) {
  await send('Emulation.setEmulatedMedia', {
    features: [{ name: 'prefers-color-scheme', value: scheme }],
  });
  // A computed value read in the same tick is the pre-restyle one.
  await evaluate('new Promise(r => setTimeout(r, 250))');

  // ASSERT THE SETUP LANDED. If the emulation silently did not apply, both
  // palettes below are the same one and this probe reports PASS on a broken
  // artifact -- a green that means "I measured nothing", which is the failure
  // this whole thread is about.
  const applied = await evaluate(
    `window.matchMedia('(prefers-color-scheme: ${scheme})').matches`
  );
  if (applied !== true) {
    console.error(`  FAIL setup: page does not report prefers-color-scheme: ${scheme}`);
    process.exit(1);
  }

  // Every --gp- custom property the artifact declares, not a fixed list: a
  // theme's own tokens are as capable of moving as the five required ones.
  return await evaluate(`(() => {
    var cs = getComputedStyle(document.documentElement);
    var out = {};
    for (var i = 0; i < cs.length; i++) {
      var name = cs[i];
      if (name.indexOf('--gp-') === 0) { out[name] = cs.getPropertyValue(name).trim(); }
    }
    return JSON.stringify(out);
  })()`);
}

const light = JSON.parse(await paletteUnder('light'));
const dark = JSON.parse(await paletteUnder('dark'));

const names = [...new Set([...Object.keys(light), ...Object.keys(dark)])].sort();
if (names.length === 0) {
  bad(`${LABEL}: no --gp- custom properties found -- probe is measuring nothing`);
} else {
  const moved = names.filter((n) => light[n] !== dark[n]);
  if (moved.length === 0) {
    ok(`${LABEL}: all ${names.length} --gp- tokens identical in light and dark`);
  } else {
    bad(
      `${LABEL}: ${moved.length} of ${names.length} --gp- tokens move with the viewer's OS`
    );
    for (const n of moved) {
      console.log(`         ${n}: light=${light[n]}  dark=${dark[n]}`);
    }
  }
}

ws.close();
console.log(failed ? `AT12 (${LABEL}): FAIL (${failed})` : `AT12 (${LABEL}): PASS`);
process.exit(failed ? 1 : 0);
