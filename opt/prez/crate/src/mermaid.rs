// Mermaid diagrams, opt-in via `mermaid: true` in the deck's front matter.
//
// **OPT-IN IS THE WHOLE DESIGN** (spec 7). The library is 3.5 MB -- corrected up
// from design.md's ~1 MB estimate on 28 Aug 2026 -- which is two orders of
// magnitude more than a text-only artifact. A deck that does not ask for
// diagrams carries ZERO mermaid bytes, and AC08 checks both halves.
//
// The conversion below exists because comrak and mermaid disagree about markup.
// comrak renders a ```mermaid fence as `<pre><code class="language-mermaid">`,
// which is correct for a code block; mermaid looks for `.mermaid` elements. The
// runtime rewrites the first into the second at open time rather than teaching
// comrak a custom code-fence renderer, because the rewrite is six lines of
// auditable JavaScript sitting in the artifact where a reader can see it.

/// Vendored from `cms/assets/mermaid.min.js` on 28 Aug 2026 -- the same build the
/// estate's CMS serves, so a diagram renders identically in a page and a slide.
///
/// This comment is the ONE permitted mention of the estate in prez source
/// (AC10): it is provenance for a vendored asset, and provenance that names no
/// origin is not provenance.
pub const LIBRARY: &str = include_str!("../assets/mermaid.min.js");

pub const INIT_JS: &str = r#"
(function () {
  var blocks = document.querySelectorAll('pre > code.language-mermaid');
  for (var i = 0; i < blocks.length; i++) {
    var host = document.createElement('div');
    host.className = 'mermaid';
    // textContent, not innerHTML: comrak escaped the fence contents on the way
    // in, and this is what turns `--&gt;` back into `-->` before mermaid parses
    // it. An arrow is the most common thing in a mermaid diagram.
    host.textContent = blocks[i].textContent;
    blocks[i].parentNode.replaceWith(host);
  }
  if (!blocks.length || !window.mermaid) { return; }

  // THE DIAGRAM TAKES ITS PALETTE FROM THE THEME, NOT FROM THE VIEWER.
  //
  // This line used to ask the viewer's machine which palette to draw, which
  // made one .html render two ways on two laptops -- the same defect that was
  // in six of the seven built-in themes, and the reason AC13 exists. hv found
  // the symptom in a screenshot: a stock lavender diagram dropped on a navy
  // deck, because the deck was dark by theme and the laptop was light by
  // preference.
  //
  // Fixing it alone would have been worse than leaving it. Making the diagram
  // track the theme means a dark theme on a light-mode machine renders light
  // AND draws a light diagram -- they agree, the visible mismatch that made
  // this findable disappears, and the artifact is still non-deterministic. So
  // this lands after the themes were flattened, never before.
  //
  // FIVE TOKENS, and only five. Every built-in declares --gp-bg, --gp-fg,
  // --gp-muted, --gp-rule and --gp-code-bg; --gp-accent exists in four of the
  // seven. An undeclared custom property resolves to the empty string and
  // mermaid handed "" falls back to its own palette -- which would re-enter
  // this very defect through a missing token instead of through the machine,
  // and silently, which is worse. (vc's finding; it would not have occurred
  // to me.)
  //
  // fg-on-code-bg is deliberate for the node fill and label: it is the pair
  // every theme already uses for fenced code, so it is a combination the theme
  // has been designed to make legible rather than one invented here.
  var css = getComputedStyle(document.documentElement);
  var token = function (name, fallback) {
    var value = css.getPropertyValue(name).trim();
    return value || fallback;
  };
  // The fallbacks are constants, not queries. A theme that fails to declare a
  // required token is a theme bug, and it degrades to a fixed neutral that
  // renders the same everywhere rather than to something the viewer chooses.
  var bg = token('--gp-bg', '#ffffff');
  var fg = token('--gp-fg', '#16181d');
  var muted = token('--gp-muted', '#5c6370');
  var rule = token('--gp-rule', '#d8dbe0');
  var sunk = token('--gp-code-bg', '#f4f5f7');

  window.mermaid.initialize({
    startOnLoad: false,
    theme: 'base',
    themeVariables: {
      background: bg,
      mainBkg: sunk,
      primaryColor: sunk,
      secondaryColor: sunk,
      tertiaryColor: sunk,
      primaryTextColor: fg,
      secondaryTextColor: fg,
      tertiaryTextColor: fg,
      textColor: fg,
      nodeTextColor: fg,
      primaryBorderColor: rule,
      secondaryBorderColor: rule,
      tertiaryBorderColor: rule,
      nodeBorder: rule,
      lineColor: muted,
      edgeLabelBackground: bg,
      labelBackground: bg,
      labelTextColor: fg,
      // From BODY, not documentElement. The custom properties above live on
      // :root, but every theme sets its face on `body` -- so reading the font
      // off documentElement returns the browser default and the diagram's
      // labels come back in Times while the deck is in its own sans. Caught in
      // a screenshot, not by AT12, which measures determinism and is perfectly
      // happy with a font that is deterministically wrong.
      fontFamily: getComputedStyle(document.body).fontFamily || 'sans-serif'
    }
  });

  // EVERY SLIDE MUST HAVE LAYOUT WHILE MERMAID MEASURES. A slide that is not
  // the current one is display:none, and an element with no box has no width --
  // so mermaid sizes its diagram to nothing and emits a 16px stub with
  // viewBox="-8 -8 16 16". The diagram is THERE and invisible, which is the
  // worst way for this to fail: a grep for <svg> finds it and a human does not.
  // (Found on hv's first real deck, 28 Aug 2026, from the screenshot.)
  //
  // gp-measuring gives every slide a box while keeping all but the current one
  // invisible; visibility, unlike display, still lays out.
  document.body.classList.add('gp-measuring');
  var done = function () { document.body.classList.remove('gp-measuring'); };
  try {
    var running = window.mermaid.run();
    if (running && running.then) { running.then(done, done); } else { done(); }
  } catch (e) {
    done();
  }
})();
"#;

#[cfg(test)]
mod tests {
  use super::*;

  #[test]
  fn the_vendored_library_is_present_and_exposes_a_global() {
    // The bundle is an esbuild ESM wrapper; its last line is what makes
    // `window.mermaid` exist, and INIT_JS depends on exactly that.
    assert!(LIBRARY.len() > 1_000_000, "the vendored asset looks truncated");
    assert!(LIBRARY.contains("globalThis[\"mermaid\"]"), "the global the runtime expects is gone");
  }
}
