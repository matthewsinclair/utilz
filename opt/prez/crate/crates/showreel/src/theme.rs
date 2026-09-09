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

use artifact::base64;
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

/// The tab-icon types a browser takes from a data URI, and the only ones a
/// theme may declare.
const ICON_TYPES: &[(&str, &str)] =
  &[("svg", "image/svg+xml"), ("png", "image/png"), ("ico", "image/x-icon")];

/// The one format a theme may ship a font in. **THE PORT CARRIES NO CONVERTER**
/// -- the approved budget holds no woff2 or brotli crate, so adding one needs
/// fresh hv sign-off, and design.md 5 says so to stop one being added helpfully.
const FONT_EXT: &str = "woff2";

/// A theme's CSS and tab icon with every declared asset inlined.
///
/// **THE ARTIFACT OPENS FROM A USB STICK WITH NOTHING BESIDE IT**, so a font is
/// bytes inside the CSS and an icon is bytes inside a `<link>`. Neither has any
/// other form available here, which is why this is emission and not a choice.
#[derive(Debug)]
pub struct Inlined {
  /// `@font-face` rules in `fonts:` order, followed by the theme's own CSS.
  ///
  /// **THE ORDER IS THE REFERENCE'S, PORTED RATHER THAN CHOSEN.** It is not
  /// arbitrary: a face has to be declared before a later rule can override it,
  /// so putting the theme's own CSS second is what lets a theme restyle a
  /// family it also ships.
  pub css: String,
  /// The `<link rel="icon">` element, or empty where the theme declares none.
  ///
  /// **EMPTY IS "DECLARED NOTHING" AND IS THE ONLY WAY TO GET IT.** Every other
  /// path that used to produce an empty string -- a missing file, an
  /// unsupported type -- is now a refusal, so this value can no longer mean
  /// "something went wrong and we carried on".
  pub favicon: String,
}

/// A resolved theme's CSS and favicon, with every declared asset inlined.
///
/// A built-in has no directory and therefore no sidecar, so it contributes its
/// CSS and nothing else. That is a shape the type rules out rather than a case
/// checked here -- see `Theme::dir`.
pub fn inline(theme: &Theme) -> Result<Inlined, Failure> {
  let mut out = match &theme.dir {
    Some(dir) => match Meta::read(dir)? {
      Some(meta) => meta.inline(dir)?,
      None => Inlined { css: String::new(), favicon: String::new() },
    },
    None => Inlined { css: String::new(), favicon: String::new() },
  };
  out.css.push_str(&theme.css);
  Ok(out)
}

/// A declared asset's extension, lowercased. Empty where there is none.
fn extension(path: &Path) -> String {
  path.extension().map(|e| e.to_string_lossy().to_ascii_lowercase()).unwrap_or_default()
}

/// Read a declared theme asset, or refuse by name.
///
/// **A DECLARATION IS AN ASSERTION THAT THE FILE IS THERE.** The reference
/// warned and carried on for both the font and the icon, shipping an artifact
/// materially different from the one the theme declared while still reporting
/// success. Missing and unreadable are one refusal deliberately: they are the
/// same fact to a caller -- the bytes this theme named are not available -- and
/// the OS error carries which it was.
fn read_asset(path: &Path, what: &str, named: &str) -> Result<Vec<u8>, Failure> {
  std::fs::read(path).map_err(|e| {
    Failure::new(
      format!("theme {what} '{named}': cannot read {}: {e}", path.display()),
      format!("theme.yaml declares this {what}; add the file, or drop the entry"),
    )
  })
}

/// The `<link rel="icon">` for a declared favicon, with the file inlined.
///
/// **EXISTENCE IS CHECKED BEFORE FORMAT, WHICH IS THE REFERENCE'S ORDER AND IS
/// KEPT FOR A REASON RATHER THAN FOR PARITY.** Format-first would report the
/// decidable error one round trip sooner when both are wrong, and it would also
/// hand back a remedy nobody can follow -- "convert this file" against a path
/// that is not there. **Report the error whose remedy is complete**, and the
/// existence one always is.
fn favicon_link(dir: &Path, spec: &str) -> Result<String, Failure> {
  let path = dir.join(spec);
  let bytes = read_asset(&path, "favicon", spec)?;
  let ext = extension(&path);
  let Some((_, mime)) = ICON_TYPES.iter().find(|(e, _)| *e == ext) else {
    let known: Vec<String> = ICON_TYPES.iter().map(|(e, _)| format!(".{e}")).collect();
    return Err(Failure::new(
      format!("theme favicon '{spec}': unsupported type '.{ext}'"),
      format!("one of: {}", known.join(", ")),
    ));
  };
  Ok(format!(
    r#"<link rel="icon" type="{mime}" href="data:{mime};base64,{}">"#,
    base64::encode(&bytes)
  ))
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

impl Font {
  /// This face as an `@font-face` rule with the file inlined.
  ///
  /// **THE DEFECT THIS REPLACES IS NOT THE BARE `except`; IT IS EMITTING
  /// SOMETHING DIFFERENT AND REPORTING SUCCESS.** The reference converted TTF to
  /// WOFF2 on every build inside `except Exception:` and, on any failure at all,
  /// embedded the RAW TTF -- a different format at roughly double the bytes,
  /// with no warning, so two machines building one reel produced measurably
  /// different artifacts and both said "wrote". There is no conversion left to
  /// fail here, which is a better answer than reporting the failure would have
  /// been.
  fn face(&self, dir: &Path) -> Result<String, Failure> {
    let path = dir.join(&self.file);
    let bytes = read_asset(&path, "font", &self.family)?;
    let ext = extension(&path);
    if ext != FONT_EXT {
      return Err(Failure::new(
        format!("theme font '{}' is not WOFF2: {}", self.family, path.display()),
        format!(
          "themes ship the format they want served, and this port carries no converter. \
           Convert it once:\n    python3 -c \"from fontTools.ttLib import TTFont; \
           f=TTFont('{}'); f.flavor='woff2'; f.save('{}')\"\n\
           then point the theme's fonts: entry at the .{FONT_EXT}",
          path.display(),
          path.with_extension(FONT_EXT).display()
        ),
      ));
    }
    let style = self.style.as_deref().unwrap_or("normal");
    let (family, weight) = (&self.family, self.weight);
    Ok(format!(
      "@font-face{{font-family:'{family}';font-weight:{weight};font-style:{style};\
       font-display:block;src:url(data:font/{FONT_EXT};base64,{}) format('{FONT_EXT}')}}\n",
      base64::encode(&bytes)
    ))
  }
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

  /// Inline every asset this manifest declares, against the directory it was
  /// read from.
  ///
  /// **THE DIRECTORY IS PASSED IN RATHER THAN REMEMBERED.** A `Meta` that
  /// carried its own directory could be constructed against one and inlined
  /// against another, and nothing would report it; taking it as an argument
  /// makes the pairing the caller's single decision.
  pub fn inline(&self, dir: &Path) -> Result<Inlined, Failure> {
    let mut css = String::new();
    for font in &self.fonts {
      css.push_str(&font.face(dir)?);
    }
    let favicon = match &self.favicon {
      Some(spec) => favicon_link(dir, spec)?,
      None => String::new(),
    };
    Ok(Inlined { css, favicon })
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

  /// One row of the refusal population: a label, the `theme.yaml`, the files
  /// sitting beside it, and whether it must refuse.
  type Case = (&'static str, &'static str, &'static [(&'static str, &'static [u8])], bool);

  /// Build a theme directory with the files named, and return it.
  fn theme_dir(tag: &str, files: &[(&str, &[u8])]) -> PathBuf {
    let d = std::env::temp_dir().join(format!("showreel-emit-{}-{tag}", std::process::id()));
    let _ = std::fs::remove_dir_all(&d);
    std::fs::create_dir_all(&d).unwrap();
    std::fs::write(d.join("theme.css"), "body{color:#111}\n").unwrap();
    for (name, bytes) in files {
      std::fs::write(d.join(name), bytes).unwrap();
    }
    d
  }

  /// **THE FOUR REFUSALS SECTION 5 RULES, ENUMERATED, BOTH DIRECTIONS.**
  ///
  /// Every one of them is a site where the reference WARNED and shipped an
  /// artifact without the asset it had declared. **The four building cases are
  /// not padding**: without them a scan that refuses everything passes this
  /// test, and two of them -- no `fonts:` at all, no `favicon:` at all -- are
  /// the cases that separate "declared nothing" from "declared and lost it",
  /// which is the distinction the whole family turns on.
  #[test]
  fn every_declared_asset_that_cannot_be_emitted_is_refused_and_the_rest_build() {
    // (label, theme.yaml, files beside it, must refuse)
    let population: &[Case] = &[
      ("nothing declared", "name: t\n", &[], false),
      ("a font that is there", "fonts:\n  - {family: X, file: x.woff2}\n", &[("x.woff2", b"wOF2fake")], false),
      ("an svg favicon", "favicon: i.svg\n", &[("i.svg", b"<svg/>")], false),
      ("a png favicon", "favicon: i.png\n", &[("i.png", b"\x89PNG")], false),
      ("a MISSING font", "fonts:\n  - {family: X, file: gone.woff2}\n", &[], true),
      ("a MISSING favicon", "favicon: gone.svg\n", &[], true),
      ("a font that is not WOFF2", "fonts:\n  - {family: X, file: x.ttf}\n", &[("x.ttf", b"\x00\x01\x00\x00")], true),
      ("an icon type nothing serves", "favicon: i.bmp\n", &[("i.bmp", b"BM")], true),
    ];
    let refusing = population.iter().filter(|(_, _, _, r)| *r).count();
    assert_eq!(population.len(), 8, "the population IS the claim");
    assert_eq!(refusing, 4, "four refuse -- one per section 5 row");
    assert_eq!(population.len() - refusing, 4, "and four BUILD, or refuse-all passes");

    let mut wrong = Vec::new();
    for (i, (label, yaml, files, must_refuse)) in population.iter().enumerate() {
      let d = theme_dir(&format!("pop{i}"), files);
      std::fs::write(d.join("theme.yaml"), yaml).unwrap();
      let meta = Meta::read(&d).unwrap().expect("theme.yaml is present");
      let refused = meta.inline(&d).is_err();
      if refused != *must_refuse {
        wrong.push(format!("{label}: expected refused={must_refuse}, got {refused}"));
      }
    }
    assert!(wrong.is_empty(), "{} decided wrongly:\n  {}", wrong.len(), wrong.join("\n  "));
  }

  /// A refusal has to name the thing the author has to go and fix. **THE FONT'S
  /// REMEDY CARRIES THE CONVERSION COMMAND** because this port has no converter
  /// and never will without fresh sign-off -- so the message is the whole of
  /// what the user gets.
  #[test]
  fn each_refusal_names_the_asset_and_offers_a_remedy_that_can_be_followed() {
    let d = theme_dir("names", &[("Barlow-Black.ttf", b"\x00\x01\x00\x00")]);
    std::fs::write(
      d.join("theme.yaml"),
      "fonts:\n  - {family: Barlow, file: Barlow-Black.ttf, weight: 900}\n",
    )
    .unwrap();
    let e = Meta::read(&d).unwrap().unwrap().inline(&d).unwrap_err();
    assert!(e.message.contains("Barlow"), "names the family: {}", e.message);
    assert!(e.message.contains("not WOFF2"), "names the defect: {}", e.message);
    let remedy = e.remedy.expect("a font refusal carries the conversion command");
    assert!(remedy.contains("fontTools"), "carries the command: {remedy}");
    assert!(remedy.contains("Barlow-Black.woff2"), "names the OUTPUT path: {remedy}");

    let d = theme_dir("icon", &[("mark.bmp", b"BM")]);
    std::fs::write(d.join("theme.yaml"), "favicon: mark.bmp\n").unwrap();
    let e = Meta::read(&d).unwrap().unwrap().inline(&d).unwrap_err();
    assert!(e.message.contains("mark.bmp"), "names the file: {}", e.message);
    let remedy = e.remedy.expect("an icon refusal lists what is served");
    for want in [".svg", ".png", ".ico"] {
      assert!(remedy.contains(want), "lists {want}: {remedy}");
    }
  }

  /// The emitted `@font-face` carries every field the manifest declared, and the
  /// **ORDER puts faces before the theme's own CSS** -- a face must be declared
  /// before a later rule can override it.
  #[test]
  fn the_emitted_css_declares_each_face_before_the_theme_that_restyles_it() {
    let d = theme_dir("shape", &[("i.woff2", b"wOF2"), ("r.woff2", b"wOF2")]);
    std::fs::write(
      d.join("theme.yaml"),
      "fonts:\n  - {family: Barlow, file: r.woff2, weight: 600}\n  - {family: Barlow, file: i.woff2, weight: 900, style: italic}\n",
    )
    .unwrap();
    let out = Meta::read(&d).unwrap().unwrap().inline(&d).unwrap();

    assert!(out.css.contains("font-family:'Barlow'"), "{}", out.css);
    assert!(out.css.contains("font-weight:600"), "the declared weight");
    assert!(out.css.contains("font-weight:900"), "and the second face's");
    assert!(out.css.contains("font-style:normal"), "style defaults rather than vanishing");
    assert!(out.css.contains("font-style:italic"), "and an explicit one is carried");
    assert!(out.css.contains("format('woff2')"), "the format the browser is told");
    assert!(!out.css.contains("truetype"), "no path emits truetype any more");
    // Two faces, in `fonts:` order.
    assert_eq!(out.css.matches("@font-face").count(), 2, "one rule per declared face");
    assert!(
      out.css.find("font-weight:600") < out.css.find("font-weight:900"),
      "faces keep the manifest's order"
    );
  }

  /// A built-in contributes its CSS and nothing else, because it has no
  /// directory to hold a sidecar. **The whole chain, from the roster to the
  /// emitted bytes**, so that a built-in silently gaining assets fails here.
  #[test]
  fn a_built_in_inlines_its_css_and_declares_no_asset() {
    let t = for_reel(None, &[]).unwrap();
    let out = inline(&t).unwrap();
    assert_eq!(out.favicon, "", "a built-in declares no icon");
    assert!(!out.css.contains("@font-face"), "and no face");
    assert_eq!(out.css, t.css, "so the emitted css IS the theme's css");
  }

  #[test]
  fn weight_defaults_to_400_and_style_stays_absent() {
    let m = Meta::parse("fonts:\n  - {family: X, file: x.woff2}\n", "t").unwrap();
    assert_eq!(m.fonts[0].weight, 400);
    assert!(m.fonts[0].style.is_none());
  }
}
