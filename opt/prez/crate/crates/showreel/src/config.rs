//! The reel config, and the refusal of anything it does not declare.
//!
//! **THE VALID KEY SET IS NOT A PROPERTY OF THIS TOOL ALONE, AND MODELLING IT
//! FROM THE COMPILER WOULD BREAK THE REEL IT IS PORTED FROM.** `session` is
//! copied wholesale into the payload (`showreel:977-978`) and the PLAYER reads
//! keys off it that the compiler never touches. Measured 2026-09-09 across both
//! files:
//!
//! | key         | read by                                    |
//! | ----------- | ------------------------------------------ |
//! | `venue`     | compiler and `player.html`                 |
//! | `city`      | compiler and `player.html`                 |
//! | `date`      | compiler and `player.html`                 |
//! | `iso`       | compiler only -- the output filename       |
//! | `venue_url` | compiler only -- the venue QR              |
//! | `action`    | **`player.html` only**                     |
//! | `artist`    | **`player.html` only**, an override        |
//!
//! A `deny_unknown_fields` written from `grep 'cfg.get'` would refuse `action:`,
//! which the 45h reel carries and shows on screen. The population spans two
//! files and neither says so.
//!
//! **AND THE PERMISSIVE DIRECTION IS THE ONE THAT SHIPS.** Today a typo in
//! `session.actoin` is copied into the payload, the player finds no `action`,
//! the row silently does not render, and nothing anywhere says a word. That is
//! the defect AC-3.1 names, and it is why every struct here denies what it does
//! not declare.

use artifact::Failure;
use serde::Deserialize;

/// The schema version block `init` writes.
///
/// **`init` WRITES THIS AND NOTHING READS IT** -- `showreel:370` scaffolds
/// `showreel: {version: 1}` and no code path consults it, so a version key that
/// cannot refuse an incompatible config is decoration. Accepted here because
/// every config `init` has ever written carries it, and CHECKED here because
/// accepted-and-ignored is the same no-op in a different costume.
#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Schema {
  pub version: u32,
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Artist {
  pub handle: String,
  #[serde(default)]
  pub name: String,
  #[serde(default)]
  pub discipline: String,
}

/// Display copy for one showing. See the module note: this struct's valid set is
/// the UNION of what the compiler reads and what the player reads.
#[derive(Debug, Deserialize, Default)]
#[serde(deny_unknown_fields)]
pub struct Session {
  #[serde(default)]
  pub venue: String,
  #[serde(default)]
  pub city: String,
  #[serde(default)]
  pub date: String,
  /// The machine date, used for the `_out/` filename. Compiler only.
  #[serde(default)]
  pub iso: String,
  /// Compiler only -- the venue QR is generated from it.
  #[serde(default)]
  pub venue_url: String,
  /// **`player.html` only.** Absent from every `cfg.get` in the compiler.
  #[serde(default)]
  pub action: String,
  /// **`player.html` only**, overriding the artist's name for one showing.
  #[serde(default)]
  pub artist: String,
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Bug {
  pub file: String,
  #[serde(default)]
  pub caption: String,
  #[serde(default)]
  pub opacity: Option<f64>,
  #[serde(default)]
  pub height: Option<f64>,
  #[serde(default)]
  pub x: Option<f64>,
  #[serde(default)]
  pub y: Option<f64>,
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Social {
  #[serde(default)]
  pub label: String,
  #[serde(default)]
  pub handle: String,
  #[serde(default)]
  pub url: String,
  /// Explicit asset path. Absent means the convention `assets/qr/<label>.svg`.
  #[serde(default)]
  pub qr: Option<String>,
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct OutroRow {
  #[serde(default)]
  pub label: String,
  #[serde(default)]
  pub value: String,
}

/// Per-reel overrides of the pace preset (`showreel:553`).
#[derive(Debug, Deserialize, Default)]
#[serde(deny_unknown_fields)]
pub struct Defaults {
  #[serde(default)]
  pub dwell: Option<String>,
  #[serde(default)]
  pub ease: Option<String>,
  #[serde(default)]
  pub transition: Option<String>,
  #[serde(default)]
  pub motion: Option<String>,
  #[serde(default)]
  pub fit: Option<String>,
}

/// One reel.
///
/// **`segments` IS VALIDATED BY `crate::segment`, WHICH LANDED AFTER THIS
/// STRUCT.** Its twelve shapes are discriminated by `type:` and serde cannot
/// express them -- `flatten` and `deny_unknown_fields` are mutually exclusive --
/// so the shapes are a table there and `parse` calls into it. The note here
/// previously said segments were unvalidated and that the row stayed open; it is
/// kept in this shape rather than deleted because **the honest reading of
/// AC-3.1 is still that it is not fully closed**: the shape table is
/// transcribed from `collect_segment`, and a field of a type the live reel does
/// not exercise could be wrong without any test noticing.
#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Reel {
  #[serde(default)]
  pub showreel: Option<Schema>,
  #[serde(default)]
  pub title: String,
  #[serde(default)]
  pub theme: Option<String>,
  #[serde(default)]
  pub producer: String,
  #[serde(default)]
  pub wordmark: String,
  pub artist: Artist,
  #[serde(default)]
  pub session: Session,
  #[serde(default)]
  pub pace: Option<String>,
  #[serde(default)]
  pub defaults: Option<Defaults>,
  /// `loop` is a Rust keyword, so the field is renamed rather than spelled
  /// differently in YAML. **The live-config test caught the missing rename and
  /// all five refusal tests missed it**, because those exercise keys I chose and
  /// the live config exercises keys the REEL chose.
  #[serde(rename = "loop", default = "yes")]
  pub loop_: bool,
  #[serde(default)]
  pub target: Option<u32>,
  #[serde(default)]
  pub output: Option<String>,
  #[serde(default)]
  pub bug: Option<Bug>,
  #[serde(default)]
  pub socials: Vec<Social>,
  #[serde(default)]
  pub outro: Vec<OutroRow>,
  #[serde(default)]
  pub segments: Vec<serde_yaml::Value>,
}

fn yes() -> bool {
  true
}

/// The schema version this build understands.
pub const SCHEMA_VERSION: u32 = 1;

/// Parse a reel config, refusing any key it does not declare.
///
/// serde's own message already names the offending key AND lists the valid set,
/// which is exactly what AC-3.1 asks for, so it is carried through rather than
/// rewritten -- a hand-written list would be a second place the field names
/// live, and it would drift from the struct the first time anyone added one.
impl Reel {
  /// The long edge an embed targets for THIS reel.
  ///
  /// **ONE HOME, READ BY BOTH THE EMBED AND THE PRODUCER STAMP.** The reference
  /// is `target = int(cfg.get("target", TARGET_DEFAULT))` -- locate it with
  /// `grep 'target = int(cfg.get("target"'`, which matches once, NOT with
  /// `grep 'cfg.get("target"'`, which matches twice. **A line number was here
  /// until 2026-09-10 and it was correct**; the previous line citation into that
  /// file decayed twice without anyone noticing, so the locator is a token now
  /// and the quoted text above is the durable half. Raised by snorkeltoast,
  /// and vc measured the remedy rather than passing it on. So
  /// the value is per-reel overridable, and a build reaching for the constant
  /// instead would be wrong on any reel that sets one.
  ///
  /// **AND NOTHING IN THIS ESTATE CAN CATCH THAT MISTAKE FROM A REEL.** The live
  /// 45h config and the pinned fixture BOTH set `target: 1920`, which is exactly
  /// `normalise::TARGET` -- so a build reading the constant produces
  /// byte-identical output on both members of the config population. The
  /// discrimination is carried by a unit test in `stamp`, not by any reel, and
  /// the estate is blind to it by construction rather than by accident.
  pub fn embed_target(&self) -> u32 {
    self.target.unwrap_or(crate::normalise::TARGET)
  }
}

pub fn parse(yaml: &str, whose: &str) -> Result<Reel, Failure> {
  let reel: Reel = serde_yaml::from_str(yaml).map_err(|e| {
    Failure::new(
      format!("{whose}: {e}"),
      "every key is checked against the ones this tool reads -- check the spelling, \
       or drop the key if it was never doing anything",
    )
  })?;
  crate::segment::validate_all(&reel.segments).map_err(|e| Failure {
    message: format!("{whose}: {}", e.message),
    ..e
  })?;
  if let Some(schema) = &reel.showreel {
    if schema.version != SCHEMA_VERSION {
      return Err(Failure::new(
        format!(
          "{whose}: showreel.version is {} and this build understands {SCHEMA_VERSION}",
          schema.version
        ),
        "use a build that declares this version, or drop the showreel: block",
      ));
    }
  }
  Ok(reel)
}

#[cfg(test)]
mod tests {
  use super::*;

  /// **THE REAL 45h CONFIG, PARSED.** A schema tested only against fixtures its
  /// own author wrote is a schema tested against its own assumptions -- and this
  /// one proved it within the minute: the missing `#[serde(rename = "loop")]`
  /// was caught here and missed by all five refusal cases, because those
  /// exercise keys I chose and this exercises keys the REEL chose.
  ///
  /// **IT IS A PINNED COPY AND WILL GO STALE.** Taken 2026-09-09 from
  /// `marketplace/artists/10-active/45h/showreel/showreel.yaml` in the
  /// Snorkeltoast tree, which is another project and another writer. Refresh it
  /// deliberately, in a commit that says the config moved -- never silently, or
  /// this test stops being an independent check and becomes a copy of whatever
  /// made it pass.
  ///
  /// **RED-PROVED:** stripping every `deny_unknown_fields` (8 to 0, counted
  /// before the result was read) fails exactly the two refusal tests and leaves
  /// this one green, which is correct -- a permissive parser still accepts a
  /// valid config. Two of eleven discriminate the guard.
  const LIVE: &str = include_str!("../fixtures/45h.showreel.yaml");

  #[test]
  fn the_reel_this_port_is_graded_against_parses_whole() {
    let reel = parse(LIVE, "45h").expect("the live config must parse");
    assert_eq!(reel.artist.handle, "45h");
    assert_eq!(reel.session.action, "Come and say hello!", "player-only key survives");
    assert_eq!(reel.session.iso, "2026-09-19", "compiler-only key survives");
    assert_eq!(reel.socials.len(), 4);
    // 15 SEGMENTS, NOT 15 SLIDES. `socials` with `layout: each` expands to one
    // page per entry and `gallery` expands to one per image, which is why the
    // fourth socials entry hv asked for took the reel from 22 planned slides to
    // 23 and made snorkeltoast's partition refuse. Counted, not eyeballed: my
    // first assertion here said 14.
    assert_eq!(reel.segments.len(), 15);
    assert!(reel.loop_, "loop: true");
    assert_eq!(reel.target, Some(1920));
  }

  /// **BOTH DIRECTIONS.** Five keys that must refuse, and the two silent-failure
  /// shapes that motivated the row are among them. A table where every row
  /// refuses is satisfied by a parser that refuses everything, so the live
  /// config above is the other arm.
  #[test]
  fn an_unknown_key_is_refused_named_and_with_the_valid_set() {
    let cases: &[(&str, &str, &str)] = &[
      ("top level", "artist: {handle: x}\nlop: true\n", "lop"),
      ("session", "artist: {handle: x}\nsession: {actoin: hi}\n", "actoin"),
      ("artist", "artist: {handle: x, nmae: y}\n", "nmae"),
      ("social", "artist: {handle: x}\nsocials: [{label: a, ur: b}]\n", "ur"),
      ("bug", "artist: {handle: x}\nbug: {file: a, opactiy: 1}\n", "opactiy"),
    ];
    assert_eq!(cases.len(), 5, "the population is the claim");
    for (where_, yaml, typo) in cases {
      let e = parse(yaml, "reel").expect_err(&format!("{where_}: {typo} must refuse"));
      assert!(e.message.contains(typo), "{where_}: names the key: {}", e.message);
      assert!(e.message.contains("expected"), "{where_}: gives the valid set: {}", e.message);
      assert!(e.remedy.is_some(), "{where_}: carries a remedy");
    }
  }

  /// `session.actoin` is the shape that motivated the row: today it is copied
  /// into the payload, the player finds no `action`, the row does not render,
  /// and nothing says anything. Pinned on its own because it is the instance,
  /// not just a member of the table above.
  #[test]
  fn the_typo_that_silently_drops_a_row_on_screen_is_refused() {
    let good = parse("artist: {handle: x}\nsession: {action: hi}\n", "r").unwrap();
    assert_eq!(good.session.action, "hi");
    let e = parse("artist: {handle: x}\nsession: {actoin: hi}\n", "r").unwrap_err();
    assert!(e.message.contains("actoin"), "{}", e.message);
  }

  #[test]
  fn a_schema_version_this_build_does_not_understand_is_refused_by_number() {
    parse("showreel: {version: 1}\nartist: {handle: x}\n", "r").expect("version 1 is ours");
    let e = parse("showreel: {version: 2}\nartist: {handle: x}\n", "r").unwrap_err();
    assert!(e.message.contains("version is 2"), "{}", e.message);
    assert!(e.message.contains("understands 1"), "{}", e.message);
  }
}
