// Themes: the orthogonal half of the deck (spec 4).
//
// A theme is a `.css` file, or a directory holding `theme.css` and optionally
// `theme.js` and `layout.html`. `--theme` beats the deck's front-matter
// `theme:`, and with neither the built-in `simple` is used.
//
// **ADDRESSING IS SPLIT BY MODE (hv, 29 Aug 2026, ST0013/AC01).** `--theme`
// takes a NAME and resolves it on `PREZ_THEME_PATH` -- extended for the
// invocation by `--theme-path` -- and then among the built-ins, NEVER against
// the working directory. `--theme-file` takes a PATH, in either shape the old
// flag took: a `.css` file or a directory holding `theme.css`. A name that
// matches nothing is a REFUSAL listing the built-ins and every directory
// searched -- never a quiet fall back to the default, which would let a typo'd
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
// vanishes reads afterwards as one nobody ever made**, and the next person to
// meet a cwd-first resolver would have no way to know it was considered, ruled,
// and reversed.
//
// **NO BUILT-IN IS EVER A BRAND.** The estate's own look is not compiled in and
// must not be: prez is designed to be extracted, and a binary carrying one
// organisation's palette cannot be. Branded themes live outside and arrive via
// the search path, which is why a consumer's own `--theme=<brand>` resolves
// where that consumer put it and correctly fails anywhere else.
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

/// WHICH BRANCH OF `load` PRODUCED THIS THEME.
///
/// Carried rather than inferred from `name`. `name` is a diagnostic string --
/// `"the built-in 'mono'"` for one, a bare path for the others -- and deciding
/// provenance by parsing it would make the announcement below a property of
/// that prose, so rewording a diagnostic would silently change which builds
/// warn. The resolver already knows which branch it took; it records it, and
/// `deck` decides what to say about it.
#[derive(Debug, PartialEq, Eq)]
pub enum Origin {
  /// Compiled into the binary.
  BuiltIn,
  /// A path that existed, given by `--theme` or by the deck's `theme:` key.
  Path,
  /// A NAME found in `dir`, one of the directories on `PREZ_THEME_PATH`.
  ///
  /// `name` is kept because it is the only thing that can answer "did this
  /// shadow a built-in?", and by this point `name` on the Theme is the path it
  /// resolved to rather than the word the user typed.
  SearchPath { dir: PathBuf, name: String },
}

#[derive(Debug)]
pub struct Theme {
  pub css: String,
  pub js: Option<String>,
  /// An optional whole-document skeleton. See `html::assemble` for the
  /// placeholders it may use.
  pub layout: Option<String>,
  /// What to call this theme in a diagnostic.
  pub name: String,
  /// Where it came from. See `provenance`.
  pub origin: Origin,
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

/// HOW A THEME WAS ADDRESSED: by NAME, or by PATH.
///
/// **THE SPLIT IS IN THE TYPE, AND THAT IS THE WHOLE FIX.** The previous
/// resolver took one `&str` that might be either and asked `path.exists()`
/// first, which is what let the working directory shadow a built-in. Deleting
/// that branch would have made every test pass and left the cause in place --
/// the same string would still be able to mean either thing, and the next
/// feature needing a path would put the branch back. A `Name` cannot reach the
/// filesystem except through the search path, and a `File` never consults the
/// search path or the built-ins: the cwd branch is not merely unvisited, it is
/// unreachable.
#[derive(Debug)]
pub enum Spec<'a> {
  /// A theme NAME. Resolved on the search path, then among the built-ins.
  Name(&'a str),
  /// A theme PATH, ALREADY RESOLVED against the right base by the caller.
  ///
  /// Owned rather than borrowed because the two bases differ and neither is
  /// this module's business: a flag's path is the user's, typed at a shell, so
  /// it resolves against the cwd; a deck's `theme-file:` belongs to the deck
  /// and resolves beside it. Deciding that here is what put an impure
  /// coordination question in the middle of a pure lookup, so the caller
  /// decides once and hands over a path that is already correct.
  File(PathBuf),
}

/// Build a NAME spec, refusing anything carrying a path separator.
///
/// **ONE HOME FOR THE SEPARATOR RULE, called by the flag and by the deck's
/// `theme:` key alike.** It looks like argument parsing and it is not: the deck
/// needs the identical rule with a different remedy, and a copy in `args.rs`
/// would mean either a second copy here or a front-matter path that quietly
/// does not enforce it -- which is how the ambiguity "moves into the deck where
/// it travels", the thing AC01 clause (d) exists to stop.
///
/// `source` names what the user typed and `remedy` is the COMPLETE remedy
/// sentence, because AC01 clause (f) requires the refusal to name the remedy for
/// the case that ACTUALLY FIRED -- and the two cases are not the same sentence
/// with a word swapped. A flag's remedy is `--theme-file=<value>`; a deck key's
/// is `theme-file: <value>`. Assembling either from a shared template produced
/// `'theme-file:'=./x.css`, which is not front matter and not anything else. This split breaks invocations that already exist in
/// shell histories and in consumers' build scripts, and naming the replacement
/// flag turns a breakage into a migration.
///
/// (The consumers are named in ST0013, not here. AC09 refuses estate paths and
/// names ANYWHERE in src, comments included, because this crate is meant to be
/// extractable -- and a comment leaks even though it creates no coupling. This
/// paragraph named one and AT09 caught it.)
///
/// **EXISTENCE IS NOT THE TEST, THE SEPARATOR IS.** A mistyped path must refuse
/// the same way a real one does: falling through to the name resolver would
/// hand someone who typo'd a filename the built-in roster, which reads as
/// though the filename were a name they got wrong.
pub fn name_spec<'a>(value: &'a str, source: &str, remedy: &str) -> Result<Spec<'a>, Failure> {
  if value.contains('/') || value.contains(std::path::MAIN_SEPARATOR) {
    return Err(Failure::new(
      format!("{source} takes a theme NAME, and '{value}' looks like a path"),
      // THE WHOLE REPLACEMENT, copyable, not just the flag name. Clause (f)
      // exists to turn a breakage into a migration, and the shortest migration
      // is one the reader can paste: they arrived here because a command that
      // worked stopped working.
      remedy.to_string(),
    ));
  }
  Ok(Spec::Name(value))
}

/// Resolve the theme for a build.
///
/// `extra` is `--theme-path`: directories PREPENDED to `PREZ_THEME_PATH` for
/// this invocation, so the flag and the environment compose rather than the
/// flag replacing it.
pub fn load(spec: Option<Spec>, extra: &[PathBuf]) -> Result<Theme, Failure> {
  let Some(spec) = spec else {
    return built_in("simple").ok_or_else(|| {
      Failure::new("the built-in default theme is missing", "this is a prez build fault")
    });
  };

  let theme = match spec {
    Spec::File(path) => {
      if !path.exists() {
        // NO ROSTER HERE. A path that is not there is a missing FILE, and
        // offering the built-in names would read as though the filename were a
        // name the user got wrong.
        return Err(Failure::new(
          format!("no such file: {}", path.display()),
          "--theme-file takes a .css file or a directory holding theme.css",
        ));
      }
      if path.is_dir() { from_directory(&path)? } else { from_file(&path)? }
    }
    Spec::Name(name) => {
      if let Some(found) = on_search_path(name, extra)? {
        found
      } else if let Some(found) = built_in(name) {
        found
      } else {
        return Err(unknown_theme(name, extra));
      }
    }
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

/// What to say on stderr when a theme did NOT come out of the binary (AC14).
///
/// **THE ARTIFACT'S LOOK BECOMES A PROPERTY OF THE ENVIRONMENT the moment a
/// name resolves off `PREZ_THEME_PATH`, and nothing in the deck records that.**
/// Two people building the same file from the same commit get different decks,
/// or one of them gets none, and until this line existed neither could tell
/// which had happened. Naming the directory is the whole point: a user with two
/// directories on the path can always answer which one won.
///
/// The two cases read differently because they FAIL differently, and the
/// asymmetry is the reason one of them is dangerous:
///
/// - A name that is not a built-in refuses elsewhere. Loud, immediate,
///   self-explaining -- the unknown-theme refusal already names every directory
///   it searched.
/// - A name that shadows a built-in SILENTLY builds something else elsewhere.
///   Same command, same deck, same commit, different output, no diagnostic.
///   That is the local-wins failure this exists for.
///
/// Returns `None` for a built-in -- silence is the correct report for "the
/// binary supplied its own" -- and `None` for `Origin::Path`, deliberately. A
/// path the user typed is already visible in what they typed. The cwd-shadowing
/// case that hides behind `Origin::Path` (`--theme=mono` beside a `./mono/`
/// directory) is real, is measured, and is NOT fixed by announcing it: AC15
/// splits the flag so a name can never resolve against the working directory at
/// all. Left here, an announcement would be a warning that the tool is doing
/// the wrong thing, which is not a fix and would take the pressure off one.
pub fn provenance(theme: &Theme) -> Option<String> {
  let Origin::SearchPath { dir, name } = &theme.origin else {
    return None;
  };
  let shadowed = BUILT_IN.iter().any(|(id, _)| id == name);
  Some(match shadowed {
    true => format!(
      "theme '{name}' came from {} (on {SEARCH_PATH}), SHADOWING the built-in of the same name. \
       Elsewhere the same command builds a different deck and says nothing -- rename the local theme if that is not what you want.",
      dir.display()
    ),
    false => format!(
      "theme '{name}' came from {} (on {SEARCH_PATH}), not from the built-ins. \
       Elsewhere this deck refuses to build until that directory is on the path.",
      dir.display()
    ),
  })
}

fn from_file(path: &Path) -> Result<Theme, Failure> {
  let css = read(path)?;
  Ok(Theme { css, js: None, layout: None, name: path.display().to_string(), origin: Origin::Path })
}

fn built_in(name: &str) -> Option<Theme> {
  BUILT_IN.iter().find(|(id, _)| *id == name).map(|(id, css)| Theme {
    css: (*css).to_string(),
    js: None,
    layout: None,
    name: format!("the built-in '{id}'"),
    origin: Origin::BuiltIn,
  })
}

/// Look for a named theme in each directory on `PREZ_THEME_PATH`.
///
/// A name matches either `<dir>/<name>/theme.css` (a directory theme, which may
/// also carry theme.js and layout.html) or `<dir>/<name>.css` (a file theme).
fn on_search_path(name: &str, extra: &[PathBuf]) -> Result<Option<Theme>, Failure> {
  // A separator can no longer reach here -- `name_spec` refuses it at the door
  // -- so this is an invariant rather than a guard, and it is cheap to keep.
  if name.contains('/') || name.contains(std::path::MAIN_SEPARATOR) {
    return Ok(None);
  }
  for dir in search_directories(extra) {
    // from_directory and from_file both stamp Origin::Path, because on their
    // own they cannot tell a path the user typed from a path this loop built.
    // Only here is that known, so only here is it overwritten.
    let found = |theme: Theme| Theme { origin: Origin::SearchPath { dir: dir.clone(), name: name.to_string() }, ..theme };
    let as_dir = dir.join(name);
    if as_dir.join("theme.css").is_file() {
      return from_directory(&as_dir).map(found).map(Some);
    }
    let as_file = dir.join(format!("{name}.css"));
    if as_file.is_file() {
      return from_file(&as_file).map(found).map(Some);
    }
  }
  Ok(None)
}

/// The directories a NAME is looked for in: `--theme-path` first, then
/// `PREZ_THEME_PATH`.
///
/// **PREPEND, NOT REPLACE.** The flag composes with the environment, so a shim
/// that exports a house theme path keeps working when a user adds one of their
/// own. `extra` is threaded as a PARAMETER rather than held in a module static
/// deliberately: cargo runs unit tests on parallel threads in one process, and
/// the note above `provenance`'s tests records what process-wide state does to
/// this file -- it races every other test in the binary, intermittently, which
/// is the worst way to learn it.
fn search_directories(extra: &[PathBuf]) -> Vec<PathBuf> {
  let mut dirs: Vec<PathBuf> = extra.to_vec();
  if let Some(paths) = std::env::var_os(SEARCH_PATH) {
    dirs.extend(std::env::split_paths(&paths).filter(|p| !p.as_os_str().is_empty()));
  }
  dirs
}

/// Split a `--theme-path` value into directories.
///
/// Repeats of the flag are LAST-WINS, decided where the flag is parsed: every
/// other value flag in `args.rs` is last-wins, and PREPEND describes the
/// relationship between this value and the environment variable, not between
/// two occurrences of the flag.
pub fn split_path_flag(value: &str) -> Vec<PathBuf> {
  std::env::split_paths(value).filter(|p| !p.as_os_str().is_empty()).collect()
}

/// Refuse an unrecognised theme, saying everything that was tried.
///
/// Falling back to the default here would be the quiet failure this codebase
/// keeps refusing to ship: `--theme=steampnk` would build a perfectly plausible
/// deck in the wrong clothes and say nothing.
fn unknown_theme(name: &str, extra: &[PathBuf]) -> Failure {
  let names: Vec<&str> = BUILT_IN.iter().map(|(id, _)| *id).collect();
  let searched = search_directories(extra);
  let where_looked = match searched.is_empty() {
    true => format!("  {SEARCH_PATH} is unset and no --theme-path was given, so no theme directories were searched"),
    false => searched
      .iter()
      .map(|d| format!("  searched {}", d.display()))
      .collect::<Vec<_>>()
      .join("\n"),
  };
  // THE "not a path" LINE IS GONE, and its unit test with it. A name is never
  // tried as a path any more, so the line was about to become a false
  // statement kept alive by a passing assertion.
  Failure::new(
    format!("no theme '{name}'.\n{where_looked}\n  built in: {}", names.join(", ")),
    format!("give a built-in name, or add directories to {SEARCH_PATH} or --theme-path; for a theme by PATH use --theme-file"),
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
    origin: Origin::Path,
  })
}

fn read(path: &Path) -> Result<String, Failure> {
  std::fs::read_to_string(path).map_err(|e| {
    Failure::new(
      format!("cannot read theme '{}': {e}", path.display()),
      "--theme-file takes a .css file or a directory holding theme.css",
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
    let t = load(None, &[]).unwrap();
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
    Theme {
      css: String::new(),
      js: None,
      layout: None,
      name: format!("{dir}/{name}"),
      origin: Origin::SearchPath { dir: PathBuf::from(dir), name: name.to_string() },
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
