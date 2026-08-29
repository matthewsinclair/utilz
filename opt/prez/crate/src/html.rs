// Artifact assembly: slides, theme and runtime become one self-contained file.
//
// **EVERYTHING THE ARTIFACT NEEDS IS IN THE ARTIFACT** (spec 3). Nothing here
// emits a `src=` or `href=` that leaves the file: the CSS is inlined, the
// runtime is inlined, images arrived as `data:` URIs from inline.rs, and the
// theme was refused at load time if it referenced anything external. That is the
// whole promise -- the deck opens on a plane, from a USB stick, in five years.
//
// The base CSS and the runtime below are THEME-INDEPENDENT and always present.
// A theme decides what a deck looks like; it does not decide whether the arrow
// keys work, and it does not decide whether printing produces one page per slide
// rather than one very tall page. Structure that a broken theme could take away
// is structure that belongs here.

use crate::render::Slide;
use crate::theme::Theme;

pub struct Document<'a> {
  pub title: Option<&'a str>,
  pub slides: &'a [Slide],
  pub theme: &'a Theme,
  pub mermaid: bool,
  /// A CSS `@page size` value, set by `prez pdf --paper`. `None` leaves the
  /// 16:9 default in the base print rules.
  pub paper: Option<String>,
}

/// Build the whole artifact.
pub fn assemble(doc: &Document) -> String {
  let title = doc.title.unwrap_or("presentation");
  let style = stylesheet(doc);
  let slides = sections(doc.slides);
  let script = script(doc);

  match &doc.theme.layout {
    Some(layout) => layout
      .replace("{{title}}", &escape_text(title))
      .replace("{{style}}", &style)
      .replace("{{slides}}", &slides)
      .replace("{{script}}", &script),
    None => format!(
      "<!doctype html>\n<html lang=\"en\">\n<head>\n<meta charset=\"utf-8\">\n\
       <meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">\n\
       <title>{}</title>\n<style>{style}</style>\n</head>\n<body>\n\
       <div class=\"gp-deck\">\n{slides}</div>\n\
       <div class=\"gp-counter\" aria-hidden=\"true\"></div>\n\
       <script>{script}</script>\n</body>\n</html>\n",
      escape_text(title)
    ),
  }
}

fn sections(slides: &[Slide]) -> String {
  let mut out = String::new();
  for (index, slide) in slides.iter().enumerate() {
    let mut classes = vec!["gp-slide".to_string()];
    if let Some(contrast) = slide.background.as_deref().and_then(contrast_class) {
      classes.push(contrast.to_string());
    }
    classes.extend(slide.classes.iter().cloned());
    out.push_str(&format!(
      "<section class=\"{}\" id=\"gp-{}\"{}>\n{}</section>\n",
      escape_attr(&classes.join(" ")),
      index + 1,
      slide
        .background
        .as_deref()
        .map(|b| format!(" style=\"background:{}\"", escape_attr(b)))
        .unwrap_or_default(),
      slide.html
    ));
  }
  out
}

/// Assemble the stylesheet, and the ORDER IS THE CONTRACT.
///
/// Two different things live in the print rules and they get different
/// treatment (vc's boundary, 28 Aug 2026):
///
/// - The page BREAK -- one slide, one page -- does not require the theme to opt
///   in, so `PRINT_BREAK_CSS` comes AFTER the theme. This is the rule spec 4's
///   wording would have left removable, which would let `pdf --theme mine.css`
///   silently produce one enormous page.
///
///   Order beats an ordinary declaration and **does not beat `!important`** at
///   equal specificity: a theme carrying `height: auto !important` inside
///   `@media print` still collapses pages (vc falsified my first, stronger
///   wording on 28 Aug 2026). That is a plausible accident, not just an attack,
///   so it is caught after the fact by `drive::verify_pagination` counting the
///   pages that came back -- a control that can go red -- rather than by an
///   `!important` arms race against themes prez does not control.
/// - The page SIZE is adjustable, so the default sits BEFORE the theme. `--paper`
///   owns page size and a theme may legitimately want a different aspect ratio.
///
/// An explicit `--paper` comes last of all and beats both, the same way `--theme`
/// beats the front-matter `theme:` key.
fn stylesheet(doc: &Document) -> String {
  let mut style = String::new();
  style.push_str(BASE_CSS);
  style.push_str(&page_rule(DEFAULT_PAPER));
  style.push('\n');
  style.push_str(&doc.theme.css);
  style.push('\n');
  style.push_str(PRINT_BREAK_CSS);
  if let Some(paper) = &doc.paper {
    style.push_str(&page_rule(paper));
  }
  style
}

fn page_rule(paper: &str) -> String {
  format!("@media print {{ @page {{ size: {paper}; margin: 0; }} }}\n")
}

/// Which contrast floor a `background:` directive needs, if we can tell.
///
/// **A BACKGROUND DIRECTIVE CAN MAKE A SLIDE UNREADABLE AND SAY NOTHING.**
/// `<!-- background: #101418 -->` under a light theme is dark text on a dark
/// slide -- hv's first real deck hit exactly that, and the heading was simply
/// gone. The directive sets one half of a pair and the theme is holding the
/// other half, so somebody has to notice.
///
/// A value we cannot parse -- a gradient, a `url()`, a named colour -- returns
/// `None` and gets no marker. A guess would be worse than nothing here: it would
/// occasionally invert a slide that was fine.
fn contrast_class(background: &str) -> Option<&'static str> {
  let (r, g, b) = parse_colour(background.trim())?;
  // Perceived luminance. Good enough to answer "is this dark?", which is the
  // only question being asked.
  let luminance = 0.299 * f64::from(r) + 0.587 * f64::from(g) + 0.114 * f64::from(b);
  Some(if luminance < 140.0 { "gp-on-dark" } else { "gp-on-light" })
}

fn parse_colour(value: &str) -> Option<(u8, u8, u8)> {
  if let Some(hex) = value.strip_prefix('#') {
    let digits: Vec<u32> = hex.chars().map(|c| c.to_digit(16)).collect::<Option<_>>()?;
    return match digits.len() {
      // #rgb is shorthand for #rrggbb.
      3 => Some((byte(digits[0] * 17), byte(digits[1] * 17), byte(digits[2] * 17))),
      6 => Some((
        byte(digits[0] * 16 + digits[1]),
        byte(digits[2] * 16 + digits[3]),
        byte(digits[4] * 16 + digits[5]),
      )),
      _ => None,
    };
  }
  let inner = value.strip_prefix("rgb(").or_else(|| value.strip_prefix("rgba("))?;
  let inner = inner.strip_suffix(')')?;
  let parts: Vec<&str> = inner.split([',', ' ', '/']).filter(|p| !p.is_empty()).collect();
  if parts.len() < 3 {
    return None;
  }
  Some((parts[0].trim().parse().ok()?, parts[1].trim().parse().ok()?, parts[2].trim().parse().ok()?))
}

fn byte(value: u32) -> u8 {
  value.min(255) as u8
}

/// 16:9 at a size browsers render crisply. Spec 5.
pub const DEFAULT_PAPER: &str = "254mm 142.9mm";

fn script(doc: &Document) -> String {
  match doc.mermaid {
    true => format!("{RUNTIME_JS}\n{}\n{}", crate::mermaid::LIBRARY, crate::mermaid::INIT_JS),
    false => RUNTIME_JS.to_string(),
  }
}

/// Escape text for an attribute value.
///
/// Directive values are the author's own words and are not a trust boundary --
/// prez compiles your file for you -- but a class name carrying a quote would
/// produce broken markup, and silently broken markup is the thing this codebase
/// keeps refusing to ship.
fn escape_attr(value: &str) -> String {
  value.replace('&', "&amp;").replace('"', "&quot;").replace('<', "&lt;").replace('>', "&gt;")
}

fn escape_text(value: &str) -> String {
  value.replace('&', "&amp;").replace('<', "&lt;").replace('>', "&gt;")
}

/// Structure, not style. See the module note for why this is not in the theme.
const BASE_CSS: &str = r#"
*, *::before, *::after { box-sizing: border-box; }
html, body { margin: 0; padding: 0; height: 100%; overflow: hidden; }
.gp-deck { height: 100%; position: relative; }
.gp-slide { position: absolute; inset: 0; display: none; overflow: auto; padding: 6vmin 8vmin; }
.gp-slide.gp-current { display: flex; flex-direction: column; justify-content: center; }
.gp-slide > *:first-child { margin-top: 0; }
.gp-counter {
  position: fixed; right: 1.1rem; bottom: 0.8rem; z-index: 10;
  font: 12px/1 ui-monospace, SFMono-Regular, Menlo, monospace;
  opacity: 0.45; user-select: none; pointer-events: none;
}

/* Momentary, while mermaid measures: every slide needs a BOX or a diagram on
  a hidden slide renders 16px wide. visibility lays out where display does not.
  See mermaid.rs for the failure this exists to stop. */
body.gp-measuring .gp-slide { display: flex !important; visibility: hidden; }
body.gp-measuring .gp-slide.gp-current { visibility: visible; }

/* A slide whose author-set background we could read gets a legible floor for the
  text on it. It works by REDEFINING THE TOKENS rather than by setting colours,
  and that is the whole mechanism: a theme's own `h2 { color: var(--gp-fg) }`
  resolves the variable on the element at use time, so it picks the override up
  and stays legible. Setting `color` alone did not work -- the theme is emitted
  AFTER this block, so any theme that colours its headings explicitly won, and
  steampunk's heading measured 1.1:1 on a dark slide, which is invisible.
  A theme that deliberately wants to style a dark slide still can, by naming
  `.gp-on-dark` itself and beating this on specificity. */
.gp-slide.gp-on-dark {
  --gp-fg: #f2f4f7;
  --gp-muted: #b9c2cc;
  --gp-rule: rgba(255,255,255,.28);
  --gp-code-bg: rgba(255,255,255,.09);
  color: #f2f4f7;
}
.gp-slide.gp-on-light {
  --gp-fg: #16181d;
  --gp-muted: #5c6370;
  --gp-rule: rgba(0,0,0,.2);
  --gp-code-bg: rgba(0,0,0,.06);
  color: #16181d;
}
.gp-slide.gp-on-dark code, .gp-slide.gp-on-dark pre { background: rgba(255,255,255,.09); }
.gp-slide.gp-on-dark blockquote { border-left-color: rgba(255,255,255,.3); color: inherit; }
.gp-slide.gp-on-dark th, .gp-slide.gp-on-dark td { border-color: rgba(255,255,255,.25); }

/* Overview: every slide at once, click to jump. Esc toggles it. */
body.gp-overview { overflow: auto; }
body.gp-overview .gp-deck {
  display: grid; grid-template-columns: repeat(auto-fill, minmax(15rem, 1fr));
  gap: 1rem; padding: 1rem; height: auto; position: static;
}
body.gp-overview .gp-slide {
  position: relative; inset: auto; display: block; overflow: hidden;
  aspect-ratio: 16 / 9; padding: 1rem; font-size: 0.42em; cursor: pointer;
  border: 1px solid currentColor; border-radius: 5px; opacity: 0.62;
}
body.gp-overview .gp-slide.gp-current { opacity: 1; outline: 3px solid currentColor; }
body.gp-overview .gp-counter { display: none; }
"#;

/// One slide, one page -- emitted AFTER the theme so a theme need not opt in.
///
/// Page SIZE is not in here, and this is not `!important`-proof; see
/// `stylesheet` for the boundary, and `drive::verify_pagination` for what
/// catches a theme that defeats it anyway.
const PRINT_BREAK_CSS: &str = r#"
@media print {
  html, body { height: auto; overflow: visible; }
  .gp-deck { height: auto; position: static; }
  .gp-slide {
    position: static; display: flex !important; flex-direction: column;
    justify-content: center; overflow: hidden;
    width: 100%; height: 100vh; break-after: page; page-break-after: always;
  }
  .gp-slide:last-child { break-after: auto; page-break-after: auto; }
  .gp-counter { display: none; }
}
"#;

/// The base runtime: navigation, counter, deep-linking, overview.
///
/// Written to ES5 and with no build step, because it is read as source inside
/// every artifact prez ever emits and a reader should be able to audit it
/// there. `#n` is one-based so `deck.html#3` means the third slide, which is
/// what someone typing a URL from the counter expects.
const RUNTIME_JS: &str = r#"
(function () {
  var slides = Array.prototype.slice.call(document.querySelectorAll('.gp-slide'));
  var counter = document.querySelector('.gp-counter');
  var total = slides.length;
  var at = 0;
  if (!total) { return; }

  function clamp(n) { return Math.max(0, Math.min(total - 1, n)); }
  function fromHash() {
    var n = parseInt(String(location.hash).slice(1), 10);
    return isNaN(n) ? 0 : clamp(n - 1);
  }
  function paint() {
    for (var i = 0; i < total; i++) {
      slides[i].classList.toggle('gp-current', i === at);
    }
    if (counter) { counter.textContent = (at + 1) + ' / ' + total; }
  }
  function go(n) {
    at = clamp(n);
    var want = '#' + (at + 1);
    // Assigning the hash is what makes the position survive a reload; guarding
    // on equality keeps it out of the history on a no-op.
    if (location.hash !== want) { location.hash = want; } else { paint(); }
  }
  function overview(on) {
    document.body.classList.toggle('gp-overview', on);
    if (!on) { slides[at].scrollIntoView({ block: 'nearest' }); }
  }
  function fullscreen() {
    if (document.fullscreenElement) { document.exitFullscreen(); }
    else if (document.documentElement.requestFullscreen) {
      document.documentElement.requestFullscreen();
    }
  }

  window.addEventListener('hashchange', function () { at = fromHash(); paint(); });

  document.addEventListener('keydown', function (e) {
    if (e.metaKey || e.ctrlKey || e.altKey) { return; }
    var overviewing = document.body.classList.contains('gp-overview');
    switch (e.key) {
      case 'ArrowRight': case ' ': case 'PageDown': go(at + 1); break;
      case 'ArrowLeft': case 'PageUp': go(at - 1); break;
      case 'Home': go(0); break;
      case 'End': go(total - 1); break;
      case 'f': case 'F': fullscreen(); break;
      case 'Escape': overview(!overviewing); break;
      default: return;
    }
    e.preventDefault();
  });

  for (var i = 0; i < total; i++) {
    (function (n) {
      slides[n].addEventListener('click', function () {
        if (document.body.classList.contains('gp-overview')) { overview(false); go(n); }
      });
    })(i);
  }

  at = fromHash();
  paint();
})();
"#;

#[cfg(test)]
mod tests {
  use super::*;
  use crate::theme;
  use std::path::Path;

  fn slide(html: &str) -> Slide {
    Slide { classes: vec![], background: None, html: html.to_string() }
  }

  fn build(slides: &[Slide]) -> String {
    let theme = theme::load(None, None, Path::new(".")).unwrap();
    assemble(&Document { title: Some("A Deck"), slides, theme: &theme, mermaid: false, paper: None })
  }

  #[test]
  fn the_artifact_is_one_document_carrying_its_own_style_and_runtime() {
    let out = build(&[slide("<h1>One</h1>")]);
    assert!(out.starts_with("<!doctype html>"), "{}", &out[..40]);
    assert!(out.contains("<title>A Deck</title>"));
    assert!(out.contains("<style>"), "the CSS is inlined, never linked");
    assert!(out.contains("gp-slide"), "base structure is present");
    assert!(out.contains("addEventListener('keydown'"), "the runtime is inlined");
  }

  #[test]
  fn nothing_prez_emits_reaches_the_network() {
    // AC03, asserted on the assembler rather than only on the built demo.
    let out = build(&[slide("<h1>One</h1>")]);
    assert!(!out.contains("http://"), "{out}");
    assert!(!out.contains("https://"), "{out}");
    assert!(!out.contains("<script src"), "{out}");
    assert!(!out.contains("<link "), "{out}");
  }

  #[test]
  fn each_slide_is_a_numbered_section_for_hash_addressing() {
    let out = build(&[slide("<p>a</p>"), slide("<p>b</p>")]);
    assert!(out.contains("id=\"gp-1\""), "{out}");
    assert!(out.contains("id=\"gp-2\""), "{out}");
  }

  #[test]
  fn directive_classes_and_backgrounds_reach_the_section() {
    let s = Slide {
      classes: vec!["wide".into(), "dark".into()],
      background: Some("#012".into()),
      html: "<p>x</p>".into(),
    };
    let out = build(&[s]);
    // The contrast marker is derived, so it sits ahead of the author's own
    // classes and a theme rule on either still wins by ordinary specificity.
    assert!(out.contains("class=\"gp-slide gp-on-dark wide dark\""), "{out}");
    assert!(out.contains("style=\"background:#012\""), "{out}");
  }

  #[test]
  fn a_dark_background_directive_gets_a_legible_text_colour() {
    // hv's first real deck: `background: #101418` under a light theme rendered
    // dark text on a dark slide and the heading simply vanished.
    let dark = Slide {
      classes: vec![],
      background: Some("#101418".into()),
      html: "<h2>The escape hatch</h2>".into(),
    };
    let out = build(&[dark]);
    assert!(out.contains("gp-slide gp-on-dark"), "{out}");
    // The floor works by REDEFINING THE TOKEN, not by setting a colour: the
    // theme is emitted after this block, so a theme colouring its own headings
    // beat a plain `color:` and steampunk measured 1.1:1 on a dark slide.
    // Asserting the mechanism rather than its presence is what would catch a
    // revert to the version that looked right and did nothing.
    let floor = out.find(".gp-slide.gp-on-dark").expect("the floor is defined");
    assert!(out[floor..floor + 200].contains("--gp-fg:"), "{}", &out[floor..floor + 200]);
  }

  #[test]
  fn contrast_reads_the_colour_forms_an_author_actually_writes() {
    assert_eq!(contrast_class("#101418"), Some("gp-on-dark"));
    assert_eq!(contrast_class("#000"), Some("gp-on-dark"));
    assert_eq!(contrast_class("#ffffff"), Some("gp-on-light"));
    assert_eq!(contrast_class("#fff"), Some("gp-on-light"));
    assert_eq!(contrast_class("rgb(16, 20, 24)"), Some("gp-on-dark"));
    assert_eq!(contrast_class("rgba(250, 250, 250, 0.9)"), Some("gp-on-light"));
  }

  #[test]
  fn a_background_we_cannot_read_gets_no_marker_rather_than_a_guess() {
    // Inverting a slide that was fine is worse than leaving it alone.
    assert_eq!(contrast_class("linear-gradient(#fff, #000)"), None);
    assert_eq!(contrast_class("url(bg.png)"), None);
    assert_eq!(contrast_class("rebeccapurple"), None);
    assert_eq!(contrast_class("#12345"), None);
  }

  #[test]
  fn an_attribute_value_carrying_a_quote_cannot_break_the_markup() {
    let s = Slide {
      classes: vec!["a\"onload=\"x".into()],
      background: None,
      html: String::new(),
    };
    let out = build(&[s]);
    assert!(!out.contains("a\"onload"), "the quote must not close the attribute: {out}");
    assert!(out.contains("&quot;"), "{out}");
  }

  #[test]
  fn the_default_paper_is_sixteen_by_nine_and_paper_overrides_it() {
    let theme = theme::load(None, None, Path::new(".")).unwrap();
    let slides = [slide("<p>x</p>")];
    let doc = Document { title: None, slides: &slides, theme: &theme, mermaid: false, paper: None };
    assert!(assemble(&doc).contains("size: 254mm 142.9mm"));

    let doc = Document { paper: Some("210mm 297mm".into()), ..doc };
    assert!(assemble(&doc).contains("size: 210mm 297mm"));
  }

  #[test]
  fn a_theme_may_change_page_size_and_need_not_opt_into_the_page_break() {
    // vc's boundary, 28 Aug 2026. Both halves are questions of ORDER, so both
    // are asserted as order rather than as presence. Note what this does NOT
    // claim: order loses to !important, which is why drive::verify_pagination
    // exists.
    let theme = Theme {
      css: "@media print { @page { size: 100mm 100mm } .gp-slide { break-after: auto } }".into(),
      js: None,
      layout: None,
      name: "t".into(),
      // A hand-made fixture is not something the resolver produced. BuiltIn is
      // the origin that announces nothing, which is what these tests want.
      origin: crate::theme::Origin::BuiltIn,
    };
    let slides = [slide("<p>x</p>")];
    let out = stylesheet(&Document {
      title: None,
      slides: &slides,
      theme: &theme,
      mermaid: false,
      paper: None,
    });
    let theme_at = out.find("100mm 100mm").expect("the theme is in the stylesheet");
    let default_size_at = out.find("254mm 142.9mm").expect("the default size is present");
    let break_at = out.rfind("break-after: page").expect("the page break is present");
    assert!(default_size_at < theme_at, "a theme must be able to change page size");
    assert!(break_at > theme_at, "a theme must NOT be able to remove the page break");
  }

  #[test]
  fn an_explicit_paper_flag_beats_a_theme_that_sets_its_own_size() {
    let theme = Theme {
      css: "@media print { @page { size: 100mm 100mm } }".into(),
      js: None,
      layout: None,
      name: "t".into(),
      // A hand-made fixture is not something the resolver produced. BuiltIn is
      // the origin that announces nothing, which is what these tests want.
      origin: crate::theme::Origin::BuiltIn,
    };
    let slides = [slide("<p>x</p>")];
    let out = stylesheet(&Document {
      title: None,
      slides: &slides,
      theme: &theme,
      mermaid: false,
      paper: Some("210mm 297mm".into()),
    });
    assert!(
      out.rfind("210mm 297mm") > out.find("100mm 100mm"),
      "--paper is the user's word and comes last: {out}"
    );
  }

  #[test]
  fn without_the_opt_in_the_artifact_carries_no_mermaid_bytes() {
    // AC08's negative half, cheap to assert here and again on the built demo.
    let out = build(&[slide("<pre><code class=\"language-mermaid\">graph TD;</code></pre>")]);
    assert!(!out.contains("mermaid.min"), "{}", out.len());
    assert!(!out.to_lowercase().contains("mermaid.initialize"));
  }

  #[test]
  fn a_theme_layout_replaces_the_default_skeleton() {
    let theme = Theme {
      css: "body{}".into(),
      js: None,
      layout: Some("<html><head>{{style}}</head><body>{{slides}}{{script}}</body></html>".into()),
      name: "t".into(),
      // A hand-made fixture is not something the resolver produced. BuiltIn is
      // the origin that announces nothing, which is what these tests want.
      origin: crate::theme::Origin::BuiltIn,
    };
    let slides = [slide("<p>x</p>")];
    let out = assemble(&Document {
      title: Some("T"),
      slides: &slides,
      theme: &theme,
      mermaid: false,
      paper: None,
    });
    assert!(out.starts_with("<html><head>"), "{out}");
    assert!(out.contains("<p>x</p>"), "{out}");
    assert!(!out.contains("{{"), "every placeholder is filled: {out}");
  }
}
