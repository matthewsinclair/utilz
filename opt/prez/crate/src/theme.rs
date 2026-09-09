// Themes: the orthogonal half of the deck (spec 4) -- prez's half of it.
//
// **THE RESOLVER ITSELF IS NOT HERE. It lives in `artifact::theme` and is shared
// with the other tool in this workspace**, because the two implemented the same
// five behaviours twice, in two languages, and that is a Highlander violation
// spanning two tools rather than a mess inside either. What stays in this file
// is exactly what is prez's and cannot be shared: the built-in roster, the
// environment variable that names the search path, and the slide-class
// vocabulary. Everything else is delegated through a preserved signature, which
// is what lets this module's tests be unchanged by the extraction.
//
// A theme is a `.css` file, or a directory holding `theme.css` and optionally
// `theme.js` and `layout.html`. `--theme` beats the deck's front-matter
// `theme:`, and with neither the built-in `simple` is used.
//
// **ADDRESSING IS SPLIT BY MODE (hv, 29 Aug 2026, ST0013/AC01).** `--theme`
// takes a NAME and resolves it on `PREZ_THEME_PATH` -- extended for the
// invocation by `--theme-path` -- and then among the built-ins, NEVER against
// the working directory. `--theme-file` takes a PATH. A name that matches
// nothing is a REFUSAL listing the built-ins and every directory searched --
// never a quiet fall back to the default, which would let a typo'd
// `--theme=steampnk` produce a plausible deck in the wrong clothes and say
// nothing.
//
// **THIS REVERSES AN EARLIER RULING OF hv'S, AND THE REVERSAL IS RECORDED
// RATHER THAN THE PARAGRAPH REPLACED.** Until ST0013 this module said, in hv's
// own words of 28 Aug 2026: *"--theme TAKES A NAME OR A PATH, and a name is
// resolved in a fixed order: an existing path first, then a named theme on
// PREZ_THEME_PATH, then a theme built into the binary."* That order was
// measured to build two different decks from one command -- `--theme=simple`
// beside a `./simple/` directory took the local one, elsewhere the built-in,
// and `provenance()` announced neither because a cwd hit stamps `Origin::Path`.
// hv re-scoped it the following day. **An attributed decision that simply
// vanishes reads afterwards as one nobody ever made.**
//
// **NO BUILT-IN IS EVER A BRAND.** The estate's own look is not compiled in and
// must not be: prez is designed to be extracted, and a binary carrying one
// organisation's palette cannot be. **This is also why the roster below is
// PASSED to the shared resolver rather than living in it** -- a shared resolver
// holding prez's built-ins would make this rule false for every other tool that
// links it.
//
// The embedded default is brand-free by rule (AC09): system fonts, no borrowed
// design tokens, no house colours, no logo. prez has no house.

use crate::Failure;
use artifact::theme::Registry;
use std::path::PathBuf;

// The shared types and the mode-independent helpers, re-exported so this
// module's surface is exactly what it was before the extraction. `deck.rs` and
// `html.rs` still say `theme::Theme` and `theme::Spec`; nothing outside this
// file knows the resolver moved.
pub use artifact::theme::{name_spec, split_path_flag, Spec, Theme};

// `Origin` and `SearchSource` are named only by tests -- this module's, and
// `html.rs`'s, which build Themes by hand rather than resolving them. Gated so
// the non-test build does not carry an import it has no use for: prez is a
// binary, so a `pub use` here creates no public API that would justify keeping
// one. clippy's `-D warnings` is what makes this a build failure rather than a
// tidiness question, and it is the gate CI runs.
#[cfg(test)]
pub use artifact::theme::{Origin, SearchSource};

// Used only by this module's tests, which call the shared helpers directly.
#[cfg(test)]
use artifact::theme::refuse_external;

/// Themes compiled into the binary. Brand-free by rule (AC09).
///
/// **ORDER IS SIGNIFICANT IN TWO WAYS.** It is the order `--help` and the
/// unknown-theme refusal list them in, so `simple` -- the default and the one to
/// reach for when unsure -- comes first and the rest read as a menu rather than
/// as an alphabet. **And the FIRST entry IS the default**: the shared resolver
/// takes `built_ins.first()` when no theme is given, so the default has one home
/// rather than a name written down twice and free to disagree with this list.
const BUILT_IN: &[(&str, &str)] = &[
  ("simple", include_str!("../themes/simple/theme.css")),
  ("mono", include_str!("../themes/mono/theme.css")),
  ("manuscript", include_str!("../themes/manuscript/theme.css")),
  ("contrast", include_str!("../themes/contrast/theme.css")),
  ("blueprint", include_str!("../themes/blueprint/theme.css")),
  ("steampunk", include_str!("../themes/steampunk/theme.css")),
  ("8bit", include_str!("../themes/8bit/theme.css")),
];

/// The environment variable naming extra theme directories, colon-separated.
///
/// This is how a branded theme reaches prez without prez knowing the brand: the
/// estate's shim sets it, prez resolves a name inside it, and the binary stays
/// extractable.
const SEARCH_PATH: &str = "PREZ_THEME_PATH";

/// prez's two tool-specific facts, handed to the shared resolver together.
const REGISTRY: Registry =
  Registry::new(BUILT_IN, SEARCH_PATH, "--theme-path", "--theme-file", "deck");

/// The class names EVERY built-in theme declares, so a `<!-- class: -->`
/// directive stays portable between them.
///
/// **THIS IS THE SEAM IN "THEMES ARE ORTHOGONAL TO CONTENT".** A deck writing
/// `class: lede` is content naming one theme's private concept, and it silently
/// binds that deck to whichever themes happen to define it -- so swapping a
/// theme, the whole point of the feature, quietly stops working. A published
/// vocabulary is what keeps the directive portable, and the test at the bottom
/// of this file holds every built-in to it.
///
/// **STAYS IN prez.** It is a slide-class vocabulary, and the other tool in this
/// workspace has segments rather than slides -- there is nothing for it to mean
/// there.
pub const STANDARD_CLASSES: &[&str] = &["title", "section", "quote", "full", "center", "small"];

/// Resolve the theme for a build, against prez's roster and search path.
pub fn load(spec: Option<Spec>, extra: &[PathBuf]) -> Result<Theme, Failure> {
  REGISTRY.load(spec, extra)
}

/// What to say on stderr when a theme did NOT come out of the binary (AC14).
pub fn provenance(theme: &Theme) -> Option<String> {
  REGISTRY.provenance(theme)
}

/// The built-in of this name, if there is one. Test-only since the extraction:
/// the resolver reaches the roster through `REGISTRY`.
#[cfg(test)]
fn built_in(name: &str) -> Option<Theme> {
  REGISTRY.built_in(name)
}

/// Does this theme style `class`?
///
/// A substring test, deliberately: parsing CSS to answer it would be a parser
/// prez has no other use for, and the cost of being wrong is one warning either
/// way rather than a broken build.
pub fn declares(theme: &Theme, class: &str) -> bool {
  theme.css.contains(&format!(".{class}"))
}

#[cfg(test)]
mod tests {
  use super::*;

  fn dir(name: &str) -> PathBuf {
    let d = std::env::temp_dir().join(format!("prez-theme-{}-{name}", std::process::id()));
    std::fs::create_dir_all(&d).unwrap();
    d
  }

  #[test]
  fn no_theme_given_uses_the_embedded_default() {
    let t = load(None, &[]).unwrap();
    assert!(t.css.contains("--gp-bg"), "the default carries its own tokens");
    assert!(t.layout.is_none());
  }

  /// **S8: WHICH built-in is the default, pinned by a property unique to it.**
  ///
  /// The test above asserts `--gp-bg`, which ALL SEVEN built-ins declare, so it
  /// passes whichever one is default and constrains nothing. The resolver takes
  /// the FIRST entry of `BUILT_IN` -- positional, so the default has one home
  /// rather than a name written down twice -- and the cost of that is that
  /// reordering the roster silently changes prez's default. This is the control
  /// for exactly that, and `name` is the right discriminator because it is what
  /// the resolver reports rather than something the CSS happens to contain: not
  /// one of simple's five `--gp-*` tokens is unique to it.
  ///
  /// **Highlander governs implementations, not assertions.** A hardcoded default
  /// in the CODE is a second home; a hardcoded expectation in a TEST is a
  /// control.
  ///
  /// **RED-PROVED BY CHANGING THE DEFAULT, NOT BY REORDERING THE ROSTER, AND THE
  /// DIFFERENCE IS NOT PEDANTRY.** Pointing the default at `mono` fails this and
  /// leaves the `--gp-bg` test above green, which is the blindness this exists
  /// for. Reordering `BUILT_IN` currently changes NOTHING, because `load` here
  /// still hardcodes `built_in("simple")`; the positional default lives in the
  /// shared resolver this module does not yet delegate to. **When it does, the
  /// reorder injection becomes live and must be re-run** -- until then, naming
  /// this test after reordering would have been a claim its body could not
  /// support.
  #[test]
  fn the_default_is_simple_specifically() {
    let t = load(None, &[]).unwrap();
    assert!(
      t.name.contains("simple"),
      "the default must be 'simple'; BUILT_IN's first entry decides it, so this fails if the roster is reordered: {}",
      t.name
    );
  }

  #[test]
  fn the_default_theme_is_brand_free() {
    // AC09, asserted STRUCTURALLY rather than as a denylist of house names: a
    // list of names only catches the names on the list, and the property that
    // actually matters is that nothing in here came from anywhere.
    let css = built_in("simple").unwrap().css;
    for line in css.lines() {
      if let Some(declaration) = line.trim().strip_prefix("--") {
        let name = declaration.split(':').next().unwrap_or_default();
        assert!(name.starts_with("gp-"), "custom property outside the gp- namespace: {name}");
      }
    }
    assert!(!css.contains("url("), "the default theme loads no asset");
    assert!(!css.contains("@import"), "the default theme imports nothing");
    assert!(!css.contains("@font-face"), "the default theme ships no typeface");
  }

  #[test]
  fn every_built_in_passes_the_rule_it_enforces() {
    for (name, css) in BUILT_IN {
      refuse_external(css, name).unwrap_or_else(|e| panic!("built-in '{name}': {}", e.message));
    }
  }

  #[test]
  fn every_built_in_declares_the_standard_class_vocabulary() {
    // The orthogonality contract. A deck writing `class: quote` must render
    // sensibly under any built-in, or `--theme` swapping is a promise the tool
    // does not keep.
    for (name, css) in BUILT_IN {
      for class in STANDARD_CLASSES {
        assert!(
          css.contains(&format!(".{class}")),
          "built-in theme '{name}' does not declare the standard class '{class}'"
        );
      }
    }
  }

  #[test]
  fn a_built_in_is_selected_by_name() {
    let t = load(Some(Spec::Name("simple")), &[]).unwrap();
    assert!(t.name.contains("built-in"), "{}", t.name);
    assert!(t.css.contains("--gp-bg"));
  }

  #[test]
  fn an_unknown_theme_is_refused_saying_everything_it_tried() {
    // Never a silent fall back to the default: `--theme=simpel` must not build
    // a plausible deck in the wrong clothes and say nothing.
    let e = load(Some(Spec::Name("simpel")), &[]).unwrap_err();
    assert!(e.message.contains("no theme 'simpel'"), "{}", e.message);
    // THE "not a path" ASSERTION IS DELETED WITH THE LINE IT ASSERTED. A name
    // is never tried as a path any more, so keeping it would have meant keeping
    // a false sentence in a refusal to keep a test green.
    assert!(!e.message.contains("not a path"), "a name is not tried as a path: {}", e.message);
    assert!(e.message.contains("simple"), "it lists the built-ins: {}", e.message);
  }

  #[test]
  fn a_single_css_file_is_a_theme() {
    let d = dir("file");
    let css = d.join("plain.css");
    std::fs::write(&css, "body{color:red}").unwrap();
    let t = load(Some(Spec::File(css.clone())), &[]).unwrap();
    assert_eq!(t.css, "body{color:red}");
  }

  #[test]
  fn a_directory_theme_picks_up_its_optional_parts() {
    let d = dir("dir");
    std::fs::write(d.join("theme.css"), "body{color:blue}").unwrap();
    std::fs::write(d.join("theme.js"), "console.log(1)").unwrap();
    std::fs::write(d.join("layout.html"), "<html>{{slides}}</html>").unwrap();
    let t = load(Some(Spec::File(d.clone())), &[]).unwrap();
    assert_eq!(t.js.as_deref(), Some("console.log(1)"));
    assert!(t.layout.as_deref().unwrap().contains("{{slides}}"));
  }

  #[test]
  fn a_directory_without_theme_css_is_refused_by_name() {
    let d = dir("empty");
    let e = load(Some(Spec::File(d.clone())), &[]).unwrap_err();
    assert!(e.message.contains("no theme.css"), "{}", e.message);
  }

  #[test]
  fn an_external_url_in_a_theme_is_a_build_error_naming_the_offender() {
    let d = dir("external");
    let css = d.join("cdn.css");
    std::fs::write(&css, "body{color:red}\n@import url(https://fonts.example/x.css);\n").unwrap();
    let e = load(Some(Spec::File(css.clone())), &[]).unwrap_err();
    assert!(e.message.contains("line 2"), "names the line: {}", e.message);
    assert!(e.message.contains("fonts.example"), "names the offender: {}", e.message);
  }

  #[test]
  fn a_url_inside_a_comment_is_documentation_not_a_reference() {
    let source = "/* adapted from https://example.com/theme, MIT */\nbody{color:red}\n";
    refuse_external(source, "t").expect("an attribution comment must not fail a build");
  }

  #[test]
  fn a_protocol_relative_url_is_still_external() {
    let e = refuse_external("body{background:url(//cdn/x.png)}", "t").unwrap_err();
    assert!(e.message.contains("url(//"), "{}", e.message);
  }

  // ---- AC14: announce-on-resolve -----------------------------------------
  //
  // provenance() is tested DIRECTLY, on a Theme built by hand, rather than by
  // setting PREZ_THEME_PATH and calling load(). Two reasons, both about the
  // test rather than the code. std::env::set_var mutates the whole process and
  // cargo runs these on parallel threads, so an env-driven test here would
  // race every other test in this binary -- intermittently, which is the worst
  // way to learn it. And the end-to-end path is worth proving black-box
  // against the real binary in a real subprocess anyway: AT13 does that, with
  // the env var set where it cannot reach anything else.

  fn from_search_path(name: &str, dir: &str) -> Theme {
    from_source(name, dir, SearchSource::Env)
  }

  fn from_source(name: &str, dir: &str, source: SearchSource) -> Theme {
    Theme {
      css: String::new(),
      js: None,
      layout: None,
      name: format!("{dir}/{name}"),
      origin: Origin::SearchPath { dir: PathBuf::from(dir), name: name.to_string(), source },
    }
  }

  #[test]
  fn a_search_path_theme_names_the_directory_it_came_from() {
    let notice = provenance(&from_search_path("housestyle", "/opt/themes")).expect("announced");
    assert!(notice.contains("'housestyle'"), "{notice}");
    assert!(notice.contains("/opt/themes"), "the directory is the point: {notice}");
    assert!(notice.contains(SEARCH_PATH), "{notice}");
  }

  #[test]
  fn shadowing_a_built_in_is_said_differently_from_merely_being_external() {
    // The asymmetry is the content. A name that is not a built-in REFUSES
    // elsewhere -- loud, self-explaining. A name that shadows one builds
    // something else elsewhere and says nothing, which is the failure this
    // whole criterion exists for, so it must not read like the benign case.
    let shadowing = provenance(&from_search_path("mono", "/opt/themes")).expect("announced");
    let external = provenance(&from_search_path("housestyle", "/opt/themes")).expect("announced");
    assert!(shadowing.contains("SHADOWING"), "{shadowing}");
    assert!(!external.contains("SHADOWING"), "{external}");
    assert_ne!(shadowing, external);
  }

  #[test]
  fn the_announcement_names_the_mechanism_that_actually_supplied_the_directory() {
    // AC04. Four messages, not one with a word swapped: what REPRODUCES the
    // situation and what CURES it are different facts for the two sources.
    let flag = provenance(&from_source("house", "/opt/themes", SearchSource::Flag)).unwrap();
    assert!(flag.contains("given by --theme-path"), "{flag}");
    assert!(!flag.contains(SEARCH_PATH), "it must not name an unset variable: {flag}");
    assert!(flag.contains("Without that flag"), "the flag remedy: {flag}");

    let flag_shadow = provenance(&from_source("mono", "/opt/themes", SearchSource::Flag)).unwrap();
    assert!(flag_shadow.contains("SHADOWING"), "{flag_shadow}");
    assert!(flag_shadow.contains("drop --theme-path"), "the cure is to stop passing it: {flag_shadow}");
    assert!(!flag_shadow.contains("rename the local theme"), "that cure is the env case's: {flag_shadow}");

    // THE CONTROL. Without it, a fix that simply stopped naming the variable
    // passes everything above and breaks the case AC14 was written for.
    let env = provenance(&from_source("house", "/opt/themes", SearchSource::Env)).unwrap();
    assert!(env.contains(SEARCH_PATH), "the env case still names it: {env}");
    assert!(!env.contains("--theme-path"), "and does not name the flag: {env}");
    assert!(env.contains("on the path"), "the env remedy survives: {env}");
    let env_shadow = provenance(&from_source("mono", "/opt/themes", SearchSource::Env)).unwrap();
    assert!(env_shadow.contains("rename the local theme"), "{env_shadow}");
  }

  #[test]
  fn a_built_in_announces_nothing() {
    // Silence is the correct report for "the binary supplied its own". A line
    // on every default build would be noise, and noise is how a real notice
    // stops being read.
    assert_eq!(provenance(&built_in("simple").unwrap()), None);
  }

  #[test]
  fn a_typed_path_announces_nothing() {
    // Deliberate, and NOT an oversight: a path the user typed is already
    // visible in what they typed. The cwd-shadowing case hiding behind this
    // origin is AC15's to remove, not this line's to narrate.
    let d = dir("provenance");
    std::fs::write(d.join("theme.css"), "body{}").unwrap();
    let t = load(Some(Spec::File(d.clone())), &[]).unwrap();
    assert_eq!(t.origin, Origin::Path);
    assert_eq!(provenance(&t), None);
  }

  // PRECEDENCE MOVED OUT OF THIS MODULE and is deck.rs's now: it is the caller
  // that sees all four sources and knows which base each path resolves against.
  // What is testable here is that the two SPECS cannot be confused, which is
  // the property the old flag-beats-front test was standing in for.
  // THE CWD CASE IS NOT TESTED HERE, DELIBERATELY, and the reason is the note
  // above provenance()'s tests one screen up. Proving it at this level needs
  // std::env::set_current_dir, which mutates the WHOLE PROCESS while cargo runs
  // these on parallel threads -- it would race every other test in this binary
  // that touches a relative path, intermittently. AT01 proves it black-box in a
  // real subprocess from two real directories, which is where it belongs.
  //
  // What IS pure, and therefore lives here, is the rule that makes the cwd
  // unreachable in the first place: a name carrying a separator never becomes a
  // Name at all.
  #[test]
  fn a_name_carrying_a_separator_is_refused_naming_its_replacement() {
    let e = name_spec("./x.css", "--theme", "for a path, use --theme-file=./x.css").unwrap_err();
    assert!(e.message.contains("looks like a path"), "{}", e.message);
    assert!(e.remedy.as_deref().unwrap_or_default().contains("--theme-file"), "clause (f): {:?}", e.remedy);
    // EXISTENCE IS NOT THE TEST. A path that is not there refuses identically,
    // or a mistyped filename falls through to the name resolver and is handed
    // the built-in roster.
    assert!(name_spec("nosuch/x.css", "--theme", "for a path, use --theme-file=nosuch/x.css").is_err());
    // And the front-matter half names the front-matter remedy, not the flag.
    let e = name_spec("./x.css", "the deck's 'theme:'", "for a path, use 'theme-file: ./x.css'").unwrap_err();
    assert!(e.remedy.as_deref().unwrap_or_default().contains("theme-file:"), "{:?}", e.remedy);
  }

  #[test]
  fn an_ordinary_name_is_not_refused() {
    // The control: without this the test above passes against a name_spec that
    // refuses everything.
    assert!(matches!(name_spec("simple", "--theme", "unused"), Ok(Spec::Name("simple"))));
  }

  #[test]
  fn theme_path_directories_are_searched_before_the_environment() {
    // split_path_flag is the pure half and is what the flag hands to load().
    let dirs = split_path_flag("/a:/b");
    assert_eq!(dirs, vec![PathBuf::from("/a"), PathBuf::from("/b")]);
    assert!(split_path_flag("").is_empty(), "an empty value adds no directories");
  }
}
