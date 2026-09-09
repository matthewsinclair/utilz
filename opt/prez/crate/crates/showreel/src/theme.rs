//! showreel's theme concerns: WHICH themes exist, WHERE one is looked for, and
//! the metadata sidecar that carries what CSS cannot say.
//!
//! **ONE HOME FOR "THEME" PER BINARY**, mirroring `prez::theme`. The roster, the
//! search-path variable and the `theme.yaml` model are three answers to one
//! question -- what does a theme mean to this tool -- and splitting them across
//! modules would put the roster in one file and the reason the roster is short
//! in another.
//!
//! **THIS MODULE EXISTS BECAUSE A THEME HAS A SECOND SURFACE AND ONLY ONE OF
//! THEM IS CSS.** `artifact::theme` resolves the directory and scans
//! `theme.css`, `theme.js` and `layout.html`; none of those can declare a font
//! file or a tab icon. `theme.yaml` can, which makes it a reference-bearing
//! surface that the offline guarantee has to cover -- R3, and the half of
//! AC-3.5 that waited on a YAML loader.
//!
//! **THE LOADER LIVES HERE RATHER THAN IN `artifact/` AND THAT IS LOAD-BEARING.**
//! `artifact` takes NO dependencies, which is the entire basis on which hv
//! signed it off as AC02's one permitted addition to prez: it adds zero packages
//! to prez's lockfile. Putting `serde_yaml` behind it would spend that
//! sign-off's whole reasoning to reach a file prez does not read. Measured: no
//! Rust code outside this crate reads `theme.yaml`.
//!
//! **THE SCAN IS OVER FIELDS, NOT OVER THE FILE.** Running the whole document
//! through `refuse_external` would refuse a provenance URL in a `#` comment --
//! `theme.yaml` is not CSS, so `Grammar::Verbatim` applies and there is no
//! comment form to exempt. The reference SITES are `favicon` and `fonts[].file`,
//! so those are what is scanned; a comment cannot become a fetch and is not
//! this rule's business. Same correction as issue 0017's, one surface along:
//! read the SITE, not the spelling.

use artifact::theme::{name_spec, refuse_external_target, Registry, Theme};
use artifact::Failure;
use serde::Deserialize;
use std::path::{Path, PathBuf};

/// Themes compiled into the binary. **EXACTLY ONE, AND THE COUNT IS A RULING.**
///
/// `themes/default/theme.css` is 951 bytes of grey ground and `system-ui`, and
/// it is the only theme in this tree. **The reference ships a second beside it
/// -- `popupart` -- and it does NOT move.** It carries one organisation's
/// palette, fonts and favicon; design.md 7 keeps it out and H3 holds the tree to
/// that. It reaches a build over `SHOWREEL_THEME_PATH` instead, which is the
/// mechanism prez already uses to let a house theme reach a brand-free binary.
///
/// **THE CONSEQUENCE, STATED HERE RATHER THAN DISCOVERED DURING A BUILD:
/// RESOLVING THE 45h REEL NEEDS THAT VARIABLE SET, WHERE THE PYTHON NEEDED
/// NOTHING.** Its config names `theme: popupart`, so the same command that
/// resolved silently there refuses here and names every directory it searched.
/// **That is the extractability guarantee working, not a port regression** --
/// and it is exactly what H3 asks to be able to see.
///
/// **THE FIRST ENTRY IS THE DEFAULT.** `Registry::load` takes
/// `built_ins.first()` when a reel names no theme, so the default has one home
/// rather than a name written down twice and free to disagree with the roster.
/// With one entry that is invisible; it is stated because the roster is the kind
/// of list that grows.
const BUILT_IN: &[(&str, &str)] = &[("default", include_str!("../themes/default/theme.css"))];

/// The environment variable naming extra theme directories, path-separated.
///
/// **SPELLED AS THE REFERENCE SPELLS IT** (`showreel:141`), because a reel
/// estate that already exports it must keep working across the port. Renaming it
/// would be a silent break: the variable would simply not be read, no theme
/// would be found, and the refusal would name a variable nobody had heard of.
const SEARCH_PATH: &str = "SHOWREEL_THEME_PATH";

/// showreel's tool-specific facts, handed to the shared resolver together.
///
/// The noun is `reel`: it lands mid-sentence in the provenance announcement,
/// which is the one place the shared resolver has to describe the caller's
/// artifact rather than its own concern.
const REGISTRY: Registry =
  Registry::new(BUILT_IN, SEARCH_PATH, "--theme-path", "--theme-file", "reel");

/// Resolve the theme a reel's config names.
///
/// **A CONFIG'S `theme:` IS A NAME AND NEVER A PATH**, enforced by the shared
/// `name_spec` rather than re-checked here. The reference took whatever the key
/// held and joined it onto each search directory, so `theme: ../../elsewhere`
/// resolved wherever it landed. Refusing a separator is the narrowing prez
/// already applies to its own theme flag, and reaching for the shared helper is
/// what keeps the rule in one place instead of two that can drift.
///
/// `extra` is the `--theme-path` flag's directories, PREPENDED to the
/// environment variable for this invocation.
pub fn for_reel(name: Option<&str>, extra: &[PathBuf]) -> Result<Theme, Failure> {
  let spec = name
    .map(|n| {
      name_spec(
        n,
        "showreel.yaml's theme:",
        "give a theme NAME; a theme addressed by PATH needs --theme-file",
      )
    })
    .transpose()?;
  REGISTRY.load(spec, extra)
}

/// What to say on stderr when a theme did NOT come out of the binary.
///
/// `None` for a built-in: silence is the correct report for "the binary supplied
/// its own".
pub fn provenance(theme: &Theme) -> Option<String> {
  REGISTRY.provenance(theme)
}

/// A theme's `theme.yaml`, which is optional -- a theme may be CSS alone.
#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Meta {
  /// Display name. Read by nothing; kept because themes carry it.
  #[serde(default)]
  pub name: Option<String>,
  #[serde(default)]
  pub description: Option<String>,
  /// Where the theme's tokens came from. Provenance, not a reference.
  #[serde(default)]
  pub source: Option<String>,
  /// The tab icon, relative to the theme directory.
  #[serde(default)]
  pub favicon: Option<String>,
  #[serde(default)]
  pub fonts: Vec<Font>,
}

/// One `@font-face`.
///
/// `weight` is a NUMBER here where the reference accepted anything and called
/// `str()` on it. A theme writing `weight: "400"` is refused by serde with the
/// type named, which is a refusal rather than a coercion -- and the estate's
/// one real theme writes integers.
#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Font {
  pub family: String,
  /// The font file, relative to the theme directory. **A REFERENCE SITE.**
  pub file: String,
  #[serde(default = "weight_default")]
  pub weight: u32,
  #[serde(default)]
  pub style: Option<String>,
}

fn weight_default() -> u32 {
  400
}

impl Meta {
  /// Parse a `theme.yaml`, refusing an unknown key and any external reference.
  pub fn parse(source: &str, origin: &str) -> Result<Meta, Failure> {
    let meta: Meta = serde_yaml::from_str(source).map_err(|e| {
      Failure::new(
        format!("theme {origin}: {e}"),
        "theme.yaml takes name, description, source, favicon and fonts",
      )
    })?;
    meta.refuse_external_references(origin)?;
    Ok(meta)
  }

  /// **R3: no field of `theme.yaml` may point outside the artifact.**
  ///
  /// Each site is scanned on its own so the diagnostic can name WHICH field
  /// carried the reference -- a whole-file scan reports a line number into a
  /// document the author then has to search.
  fn refuse_external_references(&self, origin: &str) -> Result<(), Failure> {
    if let Some(icon) = &self.favicon {
      refuse_external_target(icon, &format!("{origin} (favicon)"))?;
    }
    for (index, font) in self.fonts.iter().enumerate() {
      refuse_external_target(
        &font.file,
        &format!("{origin} (fonts[{index}].file, {})", font.family),
      )?;
    }
    Ok(())
  }

  /// Read a theme directory's `theme.yaml`, or `None` where there is none.
  ///
  /// Absence is VALID -- a theme may be CSS alone -- and it is the only absence
  /// here that is. A file that exists and cannot be read is a failure, never an
  /// absence: those two are the same value to a caller that collapses them, and
  /// this is the collapse `IN-AG-NO-SILENT-001` names.
  pub fn read(dir: &Path) -> Result<Option<Meta>, Failure> {
    let path = dir.join("theme.yaml");
    if !path.exists() {
      return Ok(None);
    }
    let text = std::fs::read_to_string(&path).map_err(|e| {
      Failure::new(
        format!("cannot read {}: {e}", path.display()),
        "the theme declares a theme.yaml; make it readable or remove it",
      )
    })?;
    Meta::parse(&text, &path.display().to_string()).map(Some)
  }
}

#[cfg(test)]
mod tests {
  use super::*;

  /// **H3 AS A TEST RATHER THAN AS A PROMISE.** The roster is exactly one entry
  /// and it is not a brand. A second built-in arriving without a ruling fails
  /// here, which is the only place that can notice -- a brand reaching the
  /// roster is invisible in every other test in this crate, because everything
  /// else would keep passing.
  #[test]
  fn the_roster_is_one_brand_free_built_in() {
    let names: Vec<&str> = BUILT_IN.iter().map(|(id, _)| *id).collect();
    assert_eq!(names, vec!["default"], "the roster IS the claim");

    // **EVERY ENTRY, NOT `BUILT_IN[0]`.** This check was written against the
    // first entry, which is this thread's own dominant failure -- one member
    // taken to characterise a set -- inside the guard whose whole job is to
    // notice a brand ARRIVING. A brand joining as the second entry is exactly
    // the case it would have missed.
    for (id, css) in BUILT_IN {
      for brand in ["popupart", "POP^UP^ART", "Snorkeltoast", "--pop-"] {
        assert!(!id.contains(brand), "built-in '{id}' is named for a brand: {brand}");
        assert!(!css.contains(brand), "built-in '{id}' carries a brand token: {brand}");
      }
    }
  }

  /// A reel naming no theme takes the first built-in, and a built-in has nowhere
  /// to keep an asset. **BOTH HALVES, BECAUSE THE SECOND IS THE ONE THAT
  /// CONSTRAINS THE BUILD PATH** -- `default` can never declare a font.
  #[test]
  fn no_theme_named_takes_the_default_and_the_default_has_no_directory() {
    let t = for_reel(None, &[]).expect("the default must always resolve");
    assert!(t.name.contains("default"), "took the first built-in: {}", t.name);
    assert!(t.dir.is_none(), "a built-in has no directory, so it can hold no sidecar");
    assert!(provenance(&t).is_none(), "silence is the report for a built-in");
  }

  /// **THE WHOLE CHAIN THE BUILD PATH RESTS ON, IN ONE TEST**: a NAME in a
  /// reel's config resolves off the search path, the resolved theme records the
  /// directory it was found in, and `theme.yaml` is read from THAT directory.
  ///
  /// It is one test rather than three because the links are what fail: each
  /// piece works in isolation today and the build still reads no fonts if the
  /// directory handed to `Meta::read` is the searched one instead of the
  /// theme's. The assertion on `dir` is what pins which of the two it is.
  #[test]
  fn a_named_theme_carries_the_directory_its_sidecar_is_read_from() {
    let root = std::env::temp_dir().join(format!("showreel-reg-{}", std::process::id()));
    let theme_dir = root.join("housestyle");
    std::fs::create_dir_all(&theme_dir).unwrap();
    std::fs::write(theme_dir.join("theme.css"), "body{color:#111}\n").unwrap();
    std::fs::write(
      theme_dir.join("theme.yaml"),
      "name: housestyle\nfavicon: icon.svg\nfonts:\n  - {family: X, file: x.woff2, weight: 700}\n",
    )
    .unwrap();

    let t = for_reel(Some("housestyle"), std::slice::from_ref(&root)).unwrap();
    assert_eq!(t.dir.as_deref(), Some(theme_dir.as_path()), "the theme's own directory");

    // Off the built-ins, so it announces. The reel estate depends on being told.
    //
    // **IT NAMES THE FLAG, NOT THE VARIABLE, AND THAT IS THE POINT.** The
    // directory arrived through `extra`, so `SearchSource::Flag` fired and the
    // announcement carries the mechanism that ACTUALLY resolved it -- what
    // reproduces the situation and what cures it are different facts for the
    // two sources. This assertion was written against the variable first and
    // the resolver was right; the env arm is deliberately not tested here,
    // because a process-wide variable races every other test in this binary.
    let said = provenance(&t).expect("a search-path theme is announced");
    assert!(said.contains("--theme-path"), "names the mechanism that fired: {said}");
    assert!(said.contains("reel"), "uses this tool's noun, not another's: {said}");

    // And the sidecar is read from the theme's directory, not the searched one.
    let meta = Meta::read(t.dir.as_deref().unwrap()).unwrap().expect("theme.yaml is there");
    assert_eq!(meta.fonts.len(), 1);
    assert_eq!(meta.fonts[0].weight, 700);
    assert_eq!(meta.favicon.as_deref(), Some("icon.svg"));
    assert!(Meta::read(&root).unwrap().is_none(), "the SEARCHED directory has no theme.yaml");
  }

  /// A config's `theme:` is a NAME. The reference joined whatever the key held
  /// onto each search directory, so a traversal resolved wherever it landed.
  #[test]
  fn a_config_theme_key_that_looks_like_a_path_is_refused_as_one() {
    let e = for_reel(Some("../../elsewhere"), &[]).unwrap_err();
    assert!(e.message.contains("theme NAME"), "names the rule: {}", e.message);
    assert!(e.message.contains("showreel.yaml"), "names where it was read: {}", e.message);
    assert!(e.remedy.unwrap().contains("--theme-file"), "offers the path route");
  }

  /// An unknown name refuses with THIS tool's roster and THIS tool's variable.
  /// A resolver that leaked prez's built-ins here would prove the shared crate
  /// is not parameterised at all.
  #[test]
  fn an_unknown_theme_names_this_tools_roster_and_not_another() {
    let e = for_reel(Some("popupart"), &[]).unwrap_err();
    assert!(e.message.contains("no theme 'popupart'"), "{}", e.message);
    assert!(e.message.contains("default"), "lists this roster: {}", e.message);
    assert!(e.message.contains("SHOWREEL_THEME_PATH"), "names this var: {}", e.message);
    assert!(!e.message.contains("simple"), "leaked prez's roster: {}", e.message);
  }

  /// The estate's one real `theme.yaml`, pinned. **TEST AGAINST SOMETHING YOU
  /// DID NOT WRITE**: the refusal cases below exercise keys I chose, this
  /// exercises the keys a theme author chose, and it is what caught a missing
  /// `#[serde(rename = "loop")]` one module over.
  const LIVE: &str = include_str!("../fixtures/popupart.theme.yaml");

  #[test]
  fn the_theme_this_port_is_graded_against_parses_whole() {
    let m = Meta::parse(LIVE, "popupart").expect("the live theme must parse");
    assert_eq!(m.favicon.as_deref(), Some("favicon.svg"));
    assert_eq!(m.fonts.len(), 5, "five faces");
    // Both the defaulted and the explicit form of every optional field.
    assert_eq!(m.fonts[0].weight, 400, "an explicit 400");
    assert_eq!(m.fonts[3].weight, 900, "an explicit 900");
    assert!(m.fonts[0].style.is_none(), "style is absent on four of five");
    assert_eq!(m.fonts[4].style.as_deref(), Some("italic"), "and present on one");
    assert!(m.name.is_some() && m.description.is_some() && m.source.is_some());
  }

  /// **THE REFERENCE POPULATION FOR THIS SURFACE, ENUMERATED, BOTH DIRECTIONS.**
  ///
  /// Three must refuse and three must BUILD. Without the building half the
  /// suite is satisfied by a scan that refuses everything -- and one of the
  /// three is the case that decides FIELDS-versus-FILE: a provenance URL in a
  /// `#` comment. `theme.yaml` has no comment form the scanner exempts, so a
  /// whole-file scan refuses it and this file's own header would not build.
  #[test]
  fn every_reference_site_in_theme_yaml_is_decided_and_comments_are_not_sites() {
    let population: &[(&str, &str, bool)] = &[
      ("clean", "favicon: favicon.svg\nfonts: []\n", false),
      ("no metadata at all", "{}\n", false),
      (
        "a provenance URL in a comment",
        "# tokens from https://snorkeltoast.com/brand\nfavicon: favicon.svg\n",
        false,
      ),
      ("absolute favicon", "favicon: https://cdn.example.com/icon.svg\n", true),
      (
        "absolute font file",
        "fonts:\n  - {family: X, file: 'http://cdn.example.com/x.woff2'}\n",
        true,
      ),
      (
        "protocol-relative font file",
        "fonts:\n  - {family: X, file: '//cdn.example.com/x.woff2'}\n",
        true,
      ),
    ];
    let refusing = population.iter().filter(|(_, _, r)| *r).count();
    assert_eq!(population.len(), 6, "the population IS the claim");
    assert_eq!(refusing, 3, "three refuse");
    assert_eq!(population.len() - refusing, 3, "and three BUILD, or refuse-all passes");

    let mut wrong = Vec::new();
    for (id, yaml, must_refuse) in population {
      let refused = Meta::parse(yaml, "t").is_err();
      if refused != *must_refuse {
        wrong.push(format!("{id}: expected refused={must_refuse}, got {refused}"));
      }
    }
    assert!(wrong.is_empty(), "{} decided wrongly:\n  {}", wrong.len(), wrong.join("\n  "));
  }

  #[test]
  fn a_refusal_names_the_field_that_carried_the_reference() {
    let e = Meta::parse("favicon: https://cdn/x.svg\n", "popupart").unwrap_err();
    assert!(e.message.contains("favicon"), "names the field: {}", e.message);

    // The family, not just the index: a theme with five faces should not send
    // its author counting from zero to find which one.
    let e = Meta::parse(
      "fonts:\n  - {family: Barlow, file: 'https://cdn/b.woff2'}\n",
      "popupart",
    )
    .unwrap_err();
    assert!(e.message.contains("Barlow"), "names the family: {}", e.message);
    assert!(e.message.contains("fonts[0].file"), "names the site: {}", e.message);
  }

  #[test]
  fn an_unknown_key_is_refused_rather_than_ignored() {
    let e = Meta::parse("favicon: x.svg\nfavicn: y.svg\n", "t").unwrap_err();
    assert!(e.message.contains("favicn"), "names the offending key: {}", e.message);
  }

  #[test]
  fn a_theme_with_no_theme_yaml_is_valid_and_a_missing_one_is_not_an_error() {
    let d = std::env::temp_dir().join(format!("showreel-theme-{}", std::process::id()));
    std::fs::create_dir_all(&d).unwrap();
    let _ = std::fs::remove_file(d.join("theme.yaml"));
    assert!(Meta::read(&d).expect("absence is valid").is_none());
  }

  #[test]
  fn weight_defaults_to_400_and_style_stays_absent() {
    let m = Meta::parse("fonts:\n  - {family: X, file: x.woff2}\n", "t").unwrap();
    assert_eq!(m.fonts[0].weight, 400);
    assert!(m.fonts[0].style.is_none());
  }
}
