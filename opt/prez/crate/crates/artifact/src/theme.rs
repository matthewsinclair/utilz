// Themes: the orthogonal half of an artifact.
//
// A theme is a `.css` file, or a directory holding `theme.css` and optionally
// `theme.js` and `layout.html`.
//
// **ADDRESSING IS SPLIT BY MODE, AND THE SPLIT LIVES IN THE TYPE.** A NAME
// resolves on a search path and then among the built-ins, NEVER against the
// working directory. A PATH is a path. `Spec` is what makes that structural:
// the previous resolver took one `&str` that might be either and asked
// `path.exists()` first, which let the working directory shadow a built-in --
// `--theme=simple` beside a `./simple/` directory took the local one,
// elsewhere the built-in, and nothing announced either. Deleting that branch
// would have made every test pass and left the cause in place, because the same
// string could still mean either thing. A `Name` cannot reach the filesystem
// except through the search path, and a `File` never consults the search path
// or the built-ins: the cwd branch is not merely unvisited, it is unreachable.
//
// **A NAME THAT MATCHES NOTHING IS A REFUSAL, NEVER A QUIET FALL BACK.** A
// typo'd `--theme=steampnk` would otherwise produce a plausible artifact in the
// wrong clothes and say nothing.
//
// **NO BUILT-IN IS EVER A BRAND**, which is why this module holds none of them.
// The built-in set arrives as a `Registry` parameter from the tool that owns it.
// A shared resolver carrying one tool's built-ins would make that rule false for
// every other tool linking it -- and it is the rule that lets a tool be lifted
// out of the estate it was written in. Branded themes live outside and arrive
// over the search path.
//
// **A THEME CARRYING AN EXTERNAL URL IS A BUILD ERROR.** That is the
// load-bearing rule of the whole feature, not a nicety. Orthogonality means the
// author picks a theme without auditing it; if a theme can quietly reference a
// webfont or a CDN, then swapping themes silently decides whether the artifact
// still opens on a plane, and the offline guarantee becomes a property of
// whichever theme happened to be chosen. Refusing at build time keeps the
// guarantee in one place and names the offending line so the theme author can
// fix it.

use crate::Failure;
use std::path::{Path, PathBuf};

/// WHICH BRANCH OF `load` PRODUCED THIS THEME.
///
/// Carried rather than inferred from `name`. `name` is a diagnostic string --
/// `"the built-in 'mono'"` for one, a bare path for the others -- and deciding
/// provenance by parsing it would make the announcement a property of that
/// prose, so rewording a diagnostic would silently change which builds warn.
/// The resolver already knows which branch it took; it records it, and the
/// caller decides what to say about it.
#[derive(Debug, PartialEq, Eq)]
pub enum Origin {
  /// Compiled into the binary.
  BuiltIn,
  /// A path that existed, given by the caller.
  Path,
  /// A NAME found in `dir`, one of the directories on the theme search path.
  ///
  /// `name` is kept because it is the only thing that can answer "did this
  /// shadow a built-in?", and by this point `name` on the Theme is the path it
  /// resolved to rather than the word the user typed.
  ///
  /// `source` is kept for the same reason `origin` is kept at all: TWO
  /// mechanisms supply search directories, and `provenance` has to name the one
  /// that actually did. Inferring it later is impossible -- by then the
  /// directory is just a path -- and guessing it would send a user who passed a
  /// flag to an environment variable that may not even be set.
  SearchPath { dir: PathBuf, name: String, source: SearchSource },
}

/// WHICH MECHANISM PUT A DIRECTORY ON THE SEARCH PATH.
///
/// A single announcement string cannot be true of both: the reproduction for
/// one is exporting a variable and for the other it is passing a flag again,
/// and the cure for an unwanted theme is to rename a directory in one case and
/// to stop passing the flag in the other. Rewording would pick a winner and lie
/// about the other.
#[derive(Debug, PartialEq, Eq, Clone, Copy)]
pub enum SearchSource {
  /// Named by the search-path environment variable.
  Env,
  /// Given by a flag, for this invocation only.
  Flag,
}

#[derive(Debug)]
pub struct Theme {
  pub css: String,
  pub js: Option<String>,
  /// An optional whole-document skeleton, for callers that support one.
  pub layout: Option<String>,
  /// What to call this theme in a diagnostic.
  pub name: String,
  /// Where it came from. See `Registry::provenance`.
  pub origin: Origin,
}

/// HOW A THEME WAS ADDRESSED: by NAME, or by PATH.
#[derive(Debug)]
pub enum Spec<'a> {
  /// A theme NAME. Resolved on the search path, then among the built-ins.
  Name(&'a str),
  /// A theme PATH, ALREADY RESOLVED against the right base by the caller.
  ///
  /// Owned rather than borrowed because the bases differ and none of them is
  /// this module's business: a flag's path is the user's, typed at a shell, so
  /// it resolves against the cwd; a document's own key belongs to that document
  /// and resolves beside it. Deciding that here is what would put an impure
  /// coordination question in the middle of a pure lookup, so the caller
  /// decides once and hands over a path that is already correct.
  File(PathBuf),
}

/// The tool-specific half of theme resolution: which built-ins exist, and which
/// environment variable names the search path.
///
/// **THESE ARE PARAMETERS RATHER THAN CONSTANTS BECAUSE THEY ARE THE TWO THINGS
/// THAT DIFFER BETWEEN TOOLS AND NOTHING ELSE DOES.** Making them a struct
/// rather than two arguments on eight functions keeps the call sites honest: a
/// caller cannot pass one tool's built-ins with another tool's variable name,
/// because there is only ever one value to pass.
pub struct Registry {
  /// `(name, css)` pairs compiled into the consuming binary. The ORDER is the
  /// order diagnostics list them in, so the first entry should be the default
  /// and the rest should read as a menu rather than as an alphabet.
  pub built_ins: &'static [(&'static str, &'static str)],
  /// The environment variable naming extra theme directories, path-separated.
  pub search_path_var: &'static str,
  /// The flag that prepends directories to the search path, spelled as the user
  /// types it.
  ///
  /// **THE TOOL'S VOCABULARY IS A PARAMETER FOR THE SAME REASON THE BUILT-INS
  /// ARE.** A diagnostic naming a flag the reader's tool does not have is worse
  /// than no diagnostic: it sends them to look for something that is not there.
  /// Generalising the WORDING instead -- "the theme-path flag" -- reads fine and
  /// cannot be pasted into a shell, and a remedy you cannot paste is half a
  /// remedy.
  pub theme_path_flag: &'static str,
  /// The flag that takes a theme by PATH.
  pub theme_file_flag: &'static str,
  /// What this tool builds, as it says it in prose: "deck", "reel".
  ///
  /// It appears mid-sentence in the provenance announcement, which is the one
  /// place the resolver has to describe the caller's artifact rather than its
  /// own concern.
  pub noun: &'static str,
}

impl Registry {
  pub const fn new(
    built_ins: &'static [(&'static str, &'static str)],
    search_path_var: &'static str,
    theme_path_flag: &'static str,
    theme_file_flag: &'static str,
    noun: &'static str,
  ) -> Self {
    Self { built_ins, search_path_var, theme_path_flag, theme_file_flag, noun }
  }

  /// The remedy offered whenever a theme addressed by PATH cannot be read.
  fn read_remedy(&self) -> String {
    format!("{} takes a .css file or a directory holding theme.css", self.theme_file_flag)
  }

  /// Resolve the theme for a build.
  ///
  /// `extra` is the flag's directories: PREPENDED to the environment variable
  /// for this invocation, so the flag and the environment compose rather than
  /// the flag replacing it.
  pub fn load(&self, spec: Option<Spec>, extra: &[PathBuf]) -> Result<Theme, Failure> {
    let Some(spec) = spec else {
      let default = self.built_ins.first().map(|(id, _)| *id).unwrap_or("");
      return self.built_in(default).ok_or_else(|| {
        Failure::new("the built-in default theme is missing", "this is a build fault")
      });
    };

    let theme = match spec {
      Spec::File(path) => {
        if !path.exists() {
          // NO ROSTER HERE. A path that is not there is a missing FILE, and
          // offering the built-in names would read as though the filename were
          // a name the user got wrong.
          return Err(Failure::new(
            format!("no such file: {}", path.display()),
            self.read_remedy(),
          ));
        }
        let remedy = self.read_remedy();
        if path.is_dir() { from_directory(&path, &remedy)? } else { from_file(&path, &remedy)? }
      }
      Spec::Name(name) => {
        if let Some(found) = self.on_search_path(name, extra)? {
          found
        } else if let Some(found) = self.built_in(name) {
          found
        } else {
          return Err(self.unknown_theme(name, extra));
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

  /// The built-in of this name, if there is one.
  pub fn built_in(&self, name: &str) -> Option<Theme> {
    self.built_ins.iter().find(|(id, _)| *id == name).map(|(id, css)| Theme {
      css: (*css).to_string(),
      js: None,
      layout: None,
      name: format!("the built-in '{id}'"),
      origin: Origin::BuiltIn,
    })
  }

  /// What to say on stderr when a theme did NOT come out of the binary.
  ///
  /// **THE ARTIFACT'S LOOK BECOMES A PROPERTY OF THE ENVIRONMENT the moment a
  /// name resolves off the search path, and nothing in the source records
  /// that.** Two people building the same file from the same commit get
  /// different output, or one of them gets none, and until this line existed
  /// neither could tell which had happened. Naming the directory is the whole
  /// point: a user with two directories on the path can always answer which one
  /// won.
  ///
  /// The two cases read differently because they FAIL differently, and the
  /// asymmetry is the reason one of them is dangerous:
  ///
  /// - A name that is not a built-in refuses elsewhere. Loud, immediate,
  ///   self-explaining -- the unknown-theme refusal already names every
  ///   directory it searched.
  /// - A name that shadows a built-in SILENTLY builds something else elsewhere.
  ///   Same command, same source, same commit, different output, no diagnostic.
  ///
  /// Returns `None` for a built-in -- silence is the correct report for "the
  /// binary supplied its own" -- and `None` for `Origin::Path`, deliberately: a
  /// path the user typed is already visible in what they typed.
  pub fn provenance(&self, theme: &Theme) -> Option<String> {
    let Origin::SearchPath { dir, name, source } = &theme.origin else {
      return None;
    };
    let var = self.search_path_var;
    let flag = self.theme_path_flag;
    let noun = self.noun;
    let shadowed = self.built_ins.iter().any(|(id, _)| id == name);
    // The mechanism, and the two remedies that follow FROM it. Four messages
    // rather than one with a word swapped: what reproduces the situation and
    // what cures it are different facts for the two sources, not different
    // labels for one fact.
    let (mechanism, elsewhere, cure) = match source {
      SearchSource::Env => (
        format!("on {var}"),
        format!("Elsewhere this {noun} refuses to build until that directory is on the path."),
        "rename the local theme if that is not what you want".to_string(),
      ),
      SearchSource::Flag => (
        format!("given by {flag}"),
        format!("Without that flag this {noun} refuses to build."),
        format!("drop {flag} if that is not what you want"),
      ),
    };
    Some(match shadowed {
      true => format!(
        "theme '{name}' came from {} ({mechanism}), SHADOWING the built-in of the same name. \
         Elsewhere the same command builds a different {noun} and says nothing -- {cure}.",
        dir.display()
      ),
      false => format!(
        "theme '{name}' came from {} ({mechanism}), not from the built-ins. {elsewhere}",
        dir.display()
      ),
    })
  }

  /// Look for a named theme in each directory on the search path.
  ///
  /// A name matches either `<dir>/<name>/theme.css` (a directory theme, which
  /// may also carry theme.js and layout.html) or `<dir>/<name>.css`.
  fn on_search_path(&self, name: &str, extra: &[PathBuf]) -> Result<Option<Theme>, Failure> {
    // A separator can no longer reach here -- `name_spec` refuses it at the
    // door -- so this is an invariant rather than a guard, and it is cheap.
    if name.contains('/') || name.contains(std::path::MAIN_SEPARATOR) {
      return Ok(None);
    }
    for (dir, source) in self.search_directories(extra) {
      // from_directory and from_file both stamp Origin::Path, because on their
      // own they cannot tell a path the user typed from a path this loop built.
      // Only here is that known, so only here is it overwritten.
      let found = |theme: Theme| Theme {
        origin: Origin::SearchPath { dir: dir.clone(), name: name.to_string(), source },
        ..theme
      };
      let remedy = self.read_remedy();
      let as_dir = dir.join(name);
      if as_dir.join("theme.css").is_file() {
        return from_directory(&as_dir, &remedy).map(found).map(Some);
      }
      let as_file = dir.join(format!("{name}.css"));
      if as_file.is_file() {
        return from_file(&as_file, &remedy).map(found).map(Some);
      }
    }
    Ok(None)
  }

  /// The directories a NAME is looked for in: the flag first, then the
  /// environment variable.
  ///
  /// **PREPEND, NOT REPLACE.** The flag composes with the environment, so a
  /// shim that exports a house theme path keeps working when a user adds one of
  /// their own. `extra` is threaded as a PARAMETER rather than held in a module
  /// static deliberately: cargo runs unit tests on parallel threads in one
  /// process, so process-wide state here races every other test in the binary,
  /// intermittently, which is the worst way to learn it.
  fn search_directories(&self, extra: &[PathBuf]) -> Vec<(PathBuf, SearchSource)> {
    let mut dirs: Vec<(PathBuf, SearchSource)> =
      extra.iter().map(|d| (d.clone(), SearchSource::Flag)).collect();
    if let Some(paths) = std::env::var_os(self.search_path_var) {
      dirs.extend(
        std::env::split_paths(&paths)
          .filter(|p| !p.as_os_str().is_empty())
          .map(|d| (d, SearchSource::Env)),
      );
    }
    dirs
  }

  /// Refuse an unrecognised theme, saying everything that was tried.
  ///
  /// Falling back to the default here would be the quiet failure this codebase
  /// keeps refusing to ship: a one-letter typo would build perfectly plausible
  /// output in the wrong clothes and say nothing.
  ///
  /// **THE `no theme '<name>'` PREFIX IS LOAD-BEARING ACROSS AN ESTATE BOUNDARY
  /// AND MUST NOT BE REWORDED WITHOUT NOTICE.** A downstream consumer asserts
  /// on it, with the search path scrubbed, as their EXTRACTABILITY guarantee: a
  /// zero exit there would mean their brand had become a built-in and the tool
  /// could no longer be lifted out of their estate.
  ///
  /// That prefix once survived a rewrite by luck rather than by design, because
  /// nothing recorded that anyone depended on it. It is recorded now.
  fn unknown_theme(&self, name: &str, extra: &[PathBuf]) -> Failure {
    let var = self.search_path_var;
    let flag = self.theme_path_flag;
    let names: Vec<&str> = self.built_ins.iter().map(|(id, _)| *id).collect();
    let searched = self.search_directories(extra);
    let where_looked = match searched.is_empty() {
      true => format!(
        "  {var} is unset and no {flag} was given, so no theme directories were searched"
      ),
      false => searched
        .iter()
        .map(|(d, src)| match src {
          SearchSource::Flag => format!("  searched {} (given by {flag})", d.display()),
          SearchSource::Env => format!("  searched {} (on {var})", d.display()),
        })
        .collect::<Vec<_>>()
        .join("\n"),
    };
    Failure::new(
      format!("no theme '{name}'.\n{where_looked}\n  built in: {}", names.join(", ")),
      format!(
        "give a built-in name, or add directories to {var} or {flag}; for a theme by PATH use {}",
        self.theme_file_flag
      ),
    )
  }
}

/// Build a NAME spec, refusing anything carrying a path separator.
///
/// **ONE HOME FOR THE SEPARATOR RULE**, called by every surface that accepts a
/// theme name. It looks like argument parsing and it is not: a second copy
/// elsewhere would mean either a duplicate here or a surface that quietly does
/// not enforce it, which is how an ambiguity moves somewhere it can travel.
///
/// `source` names what the user typed and `remedy` is the COMPLETE remedy
/// sentence, because the refusal has to name the remedy for the case that
/// ACTUALLY FIRED -- and two cases are not the same sentence with a word
/// swapped. Assembling either from a shared template produced remedies that
/// were not valid syntax in any of the surfaces they were offered for.
///
/// **EXISTENCE IS NOT THE TEST, THE SEPARATOR IS.** A mistyped path must refuse
/// the same way a real one does: falling through to the name resolver would
/// hand someone who typo'd a filename the built-in roster, which reads as
/// though the filename were a name they got wrong.
pub fn name_spec<'a>(value: &'a str, source: &str, remedy: &str) -> Result<Spec<'a>, Failure> {
  if value.contains('/') || value.contains(std::path::MAIN_SEPARATOR) {
    return Err(Failure::new(
      format!("{source} takes a theme NAME, and '{value}' looks like a path"),
      // THE WHOLE REPLACEMENT, copyable, not just the flag name. The shortest
      // migration is one the reader can paste: they arrived here because a
      // command that worked stopped working.
      remedy.to_string(),
    ));
  }
  Ok(Spec::Name(value))
}

/// Split a theme-path flag value into directories.
///
/// Repeats of the flag are LAST-WINS, decided where the flag is parsed: PREPEND
/// describes the relationship between this value and the environment variable,
/// not between two occurrences of the flag.
pub fn split_path_flag(value: &str) -> Vec<PathBuf> {
  std::env::split_paths(value).filter(|p| !p.as_os_str().is_empty()).collect()
}

/// Read a theme source file, or refuse by name.
pub fn read(path: &Path, remedy: &str) -> Result<String, Failure> {
  std::fs::read_to_string(path).map_err(|e| {
    Failure::new(format!("cannot read theme '{}': {e}", path.display()), remedy)
  })
}

fn optional(path: &Path, remedy: &str) -> Result<Option<String>, Failure> {
  if path.is_file() { read(path, remedy).map(Some) } else { Ok(None) }
}

fn from_file(path: &Path, remedy: &str) -> Result<Theme, Failure> {
  let css = read(path, remedy)?;
  Ok(Theme { css, js: None, layout: None, name: path.display().to_string(), origin: Origin::Path })
}

fn from_directory(dir: &Path, remedy: &str) -> Result<Theme, Failure> {
  let css_path = dir.join("theme.css");
  if !css_path.is_file() {
    return Err(Failure::new(
      format!("theme directory '{}' has no theme.css", dir.display()),
      "a theme directory needs theme.css; theme.js and layout.html are optional",
    ));
  }
  Ok(Theme {
    css: read(&css_path, remedy)?,
    js: optional(&dir.join("theme.js"), remedy)?,
    layout: optional(&dir.join("layout.html"), remedy)?,
    name: dir.display().to_string(),
    origin: Origin::Path,
  })
}

/// Refuse a theme that reaches outside the artifact.
///
/// Comments are stripped before the scan: a provenance or licence URL in a
/// `/* ... */` block is documentation, not a reference, and failing a build over
/// one would teach theme authors to delete their attributions.
pub fn refuse_external(source: &str, origin: &str) -> Result<(), Failure> {
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

/// Strip `/* ... */` comments, PRESERVING newlines.
///
/// **THE NEWLINES ARE THE POINT AND DELETING THEM IS THE CHEAPER MISTAKE.** The
/// scan above reports the line a reference was found on, and that number is only
/// true if stripping a comment does not move the lines after it. An
/// implementation that deletes comments outright passes every test that does not
/// assert a line number, and then misreports every one that follows a comment.
fn strip_comments(source: &str) -> String {
  let mut out = String::with_capacity(source.len());
  let mut rest = source;
  while let Some(at) = rest.find("/*") {
    out.push_str(&rest[..at]);
    match rest[at..].find("*/") {
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

  // A registry that is deliberately NOT any real tool's. If these tests passed
  // against prez's built-ins they would prove the resolver works for prez and
  // nothing about whether it is parameterised at all.
  const FAKE: Registry = Registry::new(
    &[("plain", "body{color:#111}\n"), ("loud", "body{color:#f00}\n")],
    "ARTIFACT_TEST_THEME_PATH",
    "--fake-theme-path",
    "--fake-theme-file",
    "artifact",
  );

  fn dir(name: &str) -> PathBuf {
    let d = std::env::temp_dir().join(format!("artifact-theme-{}-{name}", std::process::id()));
    std::fs::create_dir_all(&d).unwrap();
    d
  }

  #[test]
  fn no_theme_given_uses_the_first_built_in() {
    // The default is POSITIONAL, not a hardcoded name. A name would be a second
    // place the default is written down, free to disagree with the roster the
    // diagnostics list.
    let t = FAKE.load(None, &[]).unwrap();
    assert_eq!(t.origin, Origin::BuiltIn);
    assert!(t.name.contains("plain"), "took the first built-in: {}", t.name);
  }

  #[test]
  fn a_registry_resolves_only_its_own_built_ins() {
    assert!(FAKE.built_in("loud").is_some());
    // A name from a DIFFERENT tool's roster must not resolve here. This is the
    // rule "no built-in is ever a brand" made testable.
    assert!(FAKE.built_in("simple").is_none(), "resolved another tool's built-in");
  }

  #[test]
  fn an_unknown_theme_names_this_registrys_roster_and_variable() {
    let e = FAKE.load(Some(Spec::Name("nope")), &[]).unwrap_err();
    assert!(e.message.contains("no theme 'nope'"), "{}", e.message);
    assert!(e.message.contains("plain, loud"), "lists this roster: {}", e.message);
    assert!(e.message.contains("ARTIFACT_TEST_THEME_PATH"), "names this var: {}", e.message);
    assert!(!e.message.contains("simple"), "leaked another tool's roster: {}", e.message);
  }

  #[test]
  fn a_named_theme_on_the_search_path_records_the_directory_and_the_flag() {
    let d = dir("searchpath");
    let t_dir = d.join("housestyle");
    std::fs::create_dir_all(&t_dir).unwrap();
    std::fs::write(t_dir.join("theme.css"), "body{color:#222}\n").unwrap();

    let t = FAKE.load(Some(Spec::Name("housestyle")), &[d.clone()]).unwrap();
    match &t.origin {
      Origin::SearchPath { dir, name, source } => {
        assert_eq!(name, "housestyle");
        assert_eq!(*source, SearchSource::Flag);
        assert_eq!(dir, &d);
      }
      other => panic!("expected a search-path origin, got {other:?}"),
    }
    let said = FAKE.provenance(&t).expect("a search-path theme is announced");
    assert!(said.contains("--fake-theme-path"), "names the mechanism that fired: {said}");
    assert!(said.contains("artifact"), "uses this tool's noun, not another's: {said}");
  }

  #[test]
  fn a_built_in_announces_nothing() {
    let t = FAKE.load(Some(Spec::Name("plain")), &[]).unwrap();
    assert!(FAKE.provenance(&t).is_none(), "silence is the report for a built-in");
  }

  // ---- The offline guarantee, and the property that makes its report true ---

  #[test]
  fn an_external_url_is_refused_naming_the_line_and_the_offender() {
    let e = refuse_external("body{color:red}\nbody{background:url(https://cdn/x.png)}\n", "t")
      .unwrap_err();
    assert!(e.message.contains("line 2"), "{}", e.message);
    assert!(e.message.contains("cdn/x.png"), "{}", e.message);
  }

  #[test]
  fn a_url_inside_a_comment_is_documentation_not_a_reference() {
    refuse_external("/* adapted from https://example.com/t, MIT */\nbody{color:red}\n", "t")
      .expect("an attribution comment must not fail a build");
  }

  /// **THE CONTROL FOR R1, AND IT PROTECTS A PROPERTY NOTHING ELSE DOES.**
  ///
  /// Stripping comments is easy; stripping them WITHOUT MOVING THE LINES AFTER
  /// THEM is the part that makes the reported line number true. Every other
  /// test here passes against an implementation that deletes comments outright
  /// -- the shorter, more obvious implementation -- and that one misreports the
  /// line of every reference following a comment.
  ///
  /// This is the difference measured between two independent implementations of
  /// the same rule, where the shorter one was the worse one and a merge would
  /// have taken it silently.
  #[test]
  fn stripping_a_comment_does_not_move_the_lines_after_it() {
    let css = "/* a\n   licence\n   note */\nbody{background:url(https://cdn/x.png)}\n";
    let e = refuse_external(css, "t").unwrap_err();
    assert!(
      e.message.contains("line 4"),
      "the offender is on line 4 of the FILE; a comment-deleting strip reports line 2: {}",
      e.message
    );
  }

  /// **THIS PINS A KNOWN HOLE, NOT A GUARANTEE, AND ITS NAME SAYS SO.**
  ///
  /// An unterminated `/*` truncates the scanned source, so every reference after
  /// it goes unchecked. The plain case is close to self-neutralising -- a browser
  /// also treats the rest as commented -- but the scanner has no notion of string
  /// literals, so `content: "/*"` opens a comment that never closes while the
  /// browser parses it correctly. The artifact then really does reach the
  /// network. Filed separately from the needle-set defect because the root causes
  /// differ: one is *the needle set misses a shape*, this is *the scanner never
  /// receives the text*, and widening the needles does nothing for it.
  ///
  /// **THIS TEST MUST GO RED WHEN THAT IS FIXED. That redness is the point** --
  /// it is what carries the decision to whoever fixes it, rather than leaving a
  /// green test whose name suggests the hole is already shut.
  #[test]
  fn an_unterminated_comment_truncates_the_scan_which_is_a_known_hole() {
    let css = "body{color:red}\n/* unterminated\nbody{background:url(https://cdn/x.png)}\n";
    let scanned = strip_comments(css);
    assert!(scanned.contains("color:red"), "keeps what preceded the comment: {scanned:?}");
    assert!(
      !scanned.contains("cdn/x.png"),
      "EXPECTED RED IF THE SCANNER WAS JUST FIXED -- do not chase this as a regression. \
       This test RECORDS a known hole: an unterminated comment truncates the scan, so the rest \
       of the file goes unchecked. If the scanner now reaches this text, that is the fix landing. \
       INVERT this test into a guarantee; do not delete it."
    );
    assert!(
      refuse_external(css, "t").is_ok(),
      "EXPECTED RED IF THE SCANNER WAS JUST FIXED -- do not chase this as a regression. \
       Today the external reference is NOT caught, and this asserts that on the record. \
       A refusal here means the hole is shut: INVERT this test into a guarantee, keep the \
       fixture, and do not delete it."
    );
  }
}
