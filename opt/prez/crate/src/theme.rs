// Themes: the orthogonal half of the deck (spec 4).
//
// A theme is a `.css` file, or a directory holding `theme.css` and optionally
// `theme.js` and `layout.html`. `--theme` beats the deck's front-matter
// `theme:`, and with neither the built-in `simple` is used.
//
// **`--theme` TAKES A NAME OR A PATH, and a name is resolved in a fixed order**
// (hv, 28 Aug 2026): an existing path first, then a named theme on
// `PREZ_THEME_PATH`, then a theme built into the binary. A name that matches
// nothing is a REFUSAL listing both the built-ins and every directory searched
// -- never a quiet fall back to the default, which would let a typo'd
// `--theme=steampnk` produce a plausible deck in the wrong clothes and say
// nothing.
//
// **NO BUILT-IN IS EVER A BRAND.** The estate's own look is not compiled in and
// must not be: prez is designed to be extracted, and a binary carrying one
// organisation's palette cannot be. Branded themes live outside and arrive via
// the search path, which is why `--theme=geodica` works inside the estate and
// correctly fails anywhere else.
//
// **A THEME CARRYING AN EXTERNAL URL IS A BUILD ERROR.** That is the load-
// bearing rule of the whole feature, not a nicety. Orthogonality means the deck
// author picks a theme without auditing it; if a theme can quietly reference a
// webfont or a CDN, then swapping themes silently decides whether the artifact
// still opens on a plane, and the offline guarantee in spec 3 becomes a property
// of whichever theme happened to be chosen. Refusing at build time keeps the
// guarantee where it belongs -- in prez, once -- and names the offending line
// so the theme author can fix it.
//
// The embedded default is brand-free by rule (AC09): system fonts, no borrowed
// design tokens, no house colours, no logo. A branded look arrives as a theme
// from the outside, like every other theme -- which is the point of the whole
// module. prez has no house.

use crate::Failure;
use std::path::{Path, PathBuf};

#[derive(Debug)]
pub struct Theme {
  pub css: String,
  pub js: Option<String>,
  /// An optional whole-document skeleton. See `html::assemble` for the
  /// placeholders it may use.
  pub layout: Option<String>,
  /// What to call this theme in a diagnostic.
  pub name: String,
}

/// Themes compiled into the binary. Brand-free by rule (AC09) -- see the module
/// note for why that is structural rather than a preference.
/// Order is the order `--help` and the unknown-theme refusal list them in, so
/// `simple` -- the default and the one to reach for when unsure -- comes first
/// and the rest read as a menu rather than as an alphabet.
const BUILT_IN: &[(&str, &str)] = &[
  ("simple", include_str!("../themes/simple/theme.css")),
  ("mono", include_str!("../themes/mono/theme.css")),
  ("manuscript", include_str!("../themes/manuscript/theme.css")),
  ("contrast", include_str!("../themes/contrast/theme.css")),
  ("blueprint", include_str!("../themes/blueprint/theme.css")),
  ("steampunk", include_str!("../themes/steampunk/theme.css")),
  ("8bit", include_str!("../themes/8bit/theme.css")),
];

/// The class names EVERY built-in theme declares, so a `<!-- class: -->`
/// directive stays portable between them.
///
/// **THIS IS THE SEAM IN "THEMES ARE ORTHOGONAL TO CONTENT".** A deck writing
/// `class: lede` is content naming one theme's private concept, and it silently
/// binds that deck to whichever themes happen to define it -- so swapping a
/// theme, the whole point of the feature, quietly stops working. A published
/// vocabulary is what keeps the directive portable, and the test at the bottom
/// of this file holds every built-in to it.
pub const STANDARD_CLASSES: &[&str] = &["title", "section", "quote", "full", "center", "small"];

/// The environment variable naming extra theme directories, colon-separated.
///
/// This is how a branded theme reaches prez without prez knowing the
/// brand: the estate's shim sets it, prez resolves a name inside it, and the
/// binary stays extractable.
const SEARCH_PATH: &str = "PREZ_THEME_PATH";

/// Resolve the theme for a build.
///
/// `flag` is `--theme` and beats `front` (the deck's `theme:` key), which beats
/// the built-in default. `base` is the deck's directory, so a front-matter theme
/// path is written relative to the deck rather than to the shell's cwd.
pub fn load(flag: Option<&str>, front: Option<&str>, base: &Path) -> Result<Theme, Failure> {
  let Some(spec) = flag.or(front) else {
    return built_in("simple").ok_or_else(|| {
      Failure::new("the built-in default theme is missing", "this is a prez build fault")
    });
  };
  // A --theme path is the user's, typed at a shell, so it resolves against the
  // cwd. A front-matter one belongs to the deck and resolves beside it.
  let path = match flag {
    Some(_) => PathBuf::from(spec),
    None => base.join(spec),
  };

  let theme = if path.exists() {
    if path.is_dir() { from_directory(&path)? } else { from_file(&path)? }
  } else if let Some(found) = on_search_path(spec)? {
    found
  } else if let Some(found) = built_in(spec) {
    found
  } else {
    return Err(unknown_theme(spec, &path));
  };

  refuse_external(&theme.css, &format!("{} (css)", theme.name))?;
  if let Some(js) = &theme.js {
    refuse_external(js, &format!("{} (js)", theme.name))?;
  }
  if let Some(layout) = &theme.layout {
    refuse_external(layout, &format!("{} (layout.html)", theme.name))?;
  }
  Ok(theme)
}

/// Does this theme style `class`?
///
/// A substring test, deliberately: parsing CSS to answer it would be a parser
/// prez has no other use for, and the cost of being wrong is one warning
/// either way rather than a broken build.
pub fn declares(theme: &Theme, class: &str) -> bool {
  theme.css.contains(&format!(".{class}"))
}

fn from_file(path: &Path) -> Result<Theme, Failure> {
  let css = read(path)?;
  Ok(Theme { css, js: None, layout: None, name: path.display().to_string() })
}

fn built_in(name: &str) -> Option<Theme> {
  BUILT_IN.iter().find(|(id, _)| *id == name).map(|(id, css)| Theme {
    css: (*css).to_string(),
    js: None,
    layout: None,
    name: format!("the built-in '{id}'"),
  })
}

/// Look for a named theme in each directory on `PREZ_THEME_PATH`.
///
/// A name matches either `<dir>/<name>/theme.css` (a directory theme, which may
/// also carry theme.js and layout.html) or `<dir>/<name>.css` (a file theme).
fn on_search_path(name: &str) -> Result<Option<Theme>, Failure> {
  // A name with a separator in it was a path that did not exist. Searching for
  // it would turn a wrong path into a confusing "unknown theme".
  if name.contains('/') || name.contains(std::path::MAIN_SEPARATOR) {
    return Ok(None);
  }
  for dir in search_directories() {
    let as_dir = dir.join(name);
    if as_dir.join("theme.css").is_file() {
      return from_directory(&as_dir).map(Some);
    }
    let as_file = dir.join(format!("{name}.css"));
    if as_file.is_file() {
      return from_file(&as_file).map(Some);
    }
  }
  Ok(None)
}

fn search_directories() -> Vec<PathBuf> {
  std::env::var_os(SEARCH_PATH)
    .map(|paths| std::env::split_paths(&paths).filter(|p| !p.as_os_str().is_empty()).collect())
    .unwrap_or_default()
}

/// Refuse an unrecognised theme, saying everything that was tried.
///
/// Falling back to the default here would be the quiet failure this codebase
/// keeps refusing to ship: `--theme=steampnk` would build a perfectly plausible
/// deck in the wrong clothes and say nothing.
fn unknown_theme(spec: &str, tried: &Path) -> Failure {
  let names: Vec<&str> = BUILT_IN.iter().map(|(id, _)| *id).collect();
  let searched = search_directories();
  let where_looked = match searched.is_empty() {
    true => format!("  {SEARCH_PATH} is unset, so no theme directories were searched"),
    false => searched
      .iter()
      .map(|d| format!("  searched {}", d.display()))
      .collect::<Vec<_>>()
      .join("\n"),
  };
  Failure::new(
    format!(
      "no theme '{spec}'.\n  not a path: {}\n{where_looked}\n  built in: {}",
      tried.display(),
      names.join(", ")
    ),
    format!("give a path to a .css file or a theme directory, or a built-in name; add directories to {SEARCH_PATH} for more"),
  )
}

fn from_directory(dir: &Path) -> Result<Theme, Failure> {
  let css_path = dir.join("theme.css");
  if !css_path.is_file() {
    return Err(Failure::new(
      format!("theme directory '{}' has no theme.css", dir.display()),
      "a theme directory needs theme.css; theme.js and layout.html are optional",
    ));
  }
  Ok(Theme {
    css: read(&css_path)?,
    js: optional(&dir.join("theme.js"))?,
    layout: optional(&dir.join("layout.html"))?,
    name: dir.display().to_string(),
  })
}

fn read(path: &Path) -> Result<String, Failure> {
  std::fs::read_to_string(path).map_err(|e| {
    Failure::new(
      format!("cannot read theme '{}': {e}", path.display()),
      "--theme takes a .css file or a directory holding theme.css",
    )
  })
}

fn optional(path: &Path) -> Result<Option<String>, Failure> {
  if path.is_file() { read(path).map(Some) } else { Ok(None) }
}

/// Refuse a theme that reaches outside the artifact.
///
/// Comments are stripped before the scan: a provenance or licence URL in a
/// `/* ... */` block is documentation, not a reference, and failing a build over
/// one would teach theme authors to delete their attributions.
fn refuse_external(source: &str, origin: &str) -> Result<(), Failure> {
  for (number, line) in strip_comments(source).lines().enumerate() {
    let found = ["http://", "https://", "url(//", "url('//", "url(\"//"]
      .into_iter()
      .find(|needle| line.contains(needle));
    if let Some(needle) = found {
      return Err(Failure::new(
        format!(
          "theme {origin} line {} references something outside the artifact ({needle}): {}",
          number + 1,
          line.trim()
        ),
        "themes must work offline -- inline the font or asset, or drop the reference",
      ));
    }
  }
  Ok(())
}

fn strip_comments(source: &str) -> String {
  let mut out = String::with_capacity(source.len());
  let mut rest = source;
  while let Some(at) = rest.find("/*") {
    out.push_str(&rest[..at]);
    match rest[at..].find("*/") {
      // Newlines are kept so the reported line number still matches the file.
      Some(end) => {
        let comment = &rest[at..at + end + 2];
        out.extend(comment.chars().filter(|c| *c == '\n'));
        rest = &rest[at + end + 2..];
      }
      None => return out,
    }
  }
  out.push_str(rest);
  out
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
    let t = load(None, None, Path::new(".")).unwrap();
    assert!(t.css.contains("--gp-bg"), "the default carries its own tokens");
    assert!(t.layout.is_none());
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
    let t = load(Some("simple"), None, Path::new(".")).unwrap();
    assert!(t.name.contains("built-in"), "{}", t.name);
    assert!(t.css.contains("--gp-bg"));
  }

  #[test]
  fn an_unknown_theme_is_refused_saying_everything_it_tried() {
    // Never a silent fall back to the default: `--theme=simpel` must not build
    // a plausible deck in the wrong clothes and say nothing.
    let e = load(Some("simpel"), None, Path::new(".")).unwrap_err();
    assert!(e.message.contains("no theme 'simpel'"), "{}", e.message);
    assert!(e.message.contains("not a path"), "{}", e.message);
    assert!(e.message.contains("simple"), "it lists the built-ins: {}", e.message);
  }

  #[test]
  fn a_single_css_file_is_a_theme() {
    let d = dir("file");
    let css = d.join("plain.css");
    std::fs::write(&css, "body{color:red}").unwrap();
    let t = load(Some(css.to_str().unwrap()), None, Path::new(".")).unwrap();
    assert_eq!(t.css, "body{color:red}");
  }

  #[test]
  fn a_directory_theme_picks_up_its_optional_parts() {
    let d = dir("dir");
    std::fs::write(d.join("theme.css"), "body{color:blue}").unwrap();
    std::fs::write(d.join("theme.js"), "console.log(1)").unwrap();
    std::fs::write(d.join("layout.html"), "<html>{{slides}}</html>").unwrap();
    let t = load(Some(d.to_str().unwrap()), None, Path::new(".")).unwrap();
    assert_eq!(t.js.as_deref(), Some("console.log(1)"));
    assert!(t.layout.as_deref().unwrap().contains("{{slides}}"));
  }

  #[test]
  fn a_directory_without_theme_css_is_refused_by_name() {
    let d = dir("empty");
    let e = load(Some(d.to_str().unwrap()), None, Path::new(".")).unwrap_err();
    assert!(e.message.contains("no theme.css"), "{}", e.message);
  }

  #[test]
  fn an_external_url_in_a_theme_is_a_build_error_naming_the_offender() {
    let d = dir("external");
    let css = d.join("cdn.css");
    std::fs::write(&css, "body{color:red}\n@import url(https://fonts.example/x.css);\n").unwrap();
    let e = load(Some(css.to_str().unwrap()), None, Path::new(".")).unwrap_err();
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

  #[test]
  fn the_flag_beats_the_front_matter_key() {
    let d = dir("beats");
    let flagged = d.join("flag.css");
    std::fs::write(&flagged, "body{color:green}").unwrap();
    let t = load(Some(flagged.to_str().unwrap()), Some("never-read.css"), &d).unwrap();
    assert_eq!(t.css, "body{color:green}");
  }
}
