//! The theme's metadata sidecar: `theme.yaml`.
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

use artifact::theme::refuse_external_target;
use artifact::Failure;
use serde::Deserialize;
use std::path::Path;

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
