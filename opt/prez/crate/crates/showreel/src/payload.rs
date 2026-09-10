//! The `REEL` object the artifact carries, and the runtime reads.
//!
//! **THE FIELD SET IS THE CONTRACT AND THE ORDER IS NOT**, measured rather than
//! assumed -- design.md 4.6. `showreel-harness`'s `compare_structure` iterates
//! `sorted(set(a) | set(b))` and compares by key, so a reordering is invisible
//! to it and a MISSING key reports as `slide {i}: {k}: reference <v>, new None`.
//! design.md 4.7 censuses every key `player.html` actually reads.
//!
//! **`limits` IS OWED BECAUSE OF THE PLAYER THIS CRATE SHIPS, NOT BECAUSE A RULE
//! SAYS SO.** The invariant is INTERNAL CONSISTENCY: an artifact whose own
//! embedded player reads `REEL.limits` unguarded must carry the keys that player
//! reads. Both halves are in the same file, so it is answerable from the
//! artifact alone -- and it lifts by itself the day a player guards its read.
//! **The blanket "every payload must carry `limits`" version was refuted while
//! the check for it was being written**: the published 45h build has no such key,
//! embeds the OLDER player, applies its floors inline, and is entirely sound. A
//! rule that refuses a correct artifact is worse than the blind spot it replaces.
//!
//! **FOR THIS CRATE IT BINDS TODAY AND NOTHING CHANGES.** `player.html` binds
//! `const LIM = REEL.limits` with **no fallback** and reads all three floors off
//! it, so a payload without the key makes `LIM` undefined and throws on the first
//! slide -- the reel does not run at all. And `signature()` walks
//! `payload["slides"]` and NOTHING else, so a port that emits every slide
//! correctly and omits `limits` **passes the structure comparison clean** and
//! fails in pixels, as a blank, with the instrument pointing at the slides.
//! Found by snorkeltoast; design.md 4.7.

use crate::{admit, config, limits, normalise, plan};
use artifact::Failure;
use serde::Serialize;
use std::path::Path;

/// The stamp `showreel qr` writes into the SVG it generates.
const QR_STAMP: &str = "showreel-qr:";

/// The safety floors, as the payload carries them to the runtime.
///
/// **EVERY FIELD DERIVES FROM `limits`, WHICH IS AC-3.6's RUNTIME LEG.** A
/// number restated here would be a second home for a safety limit -- the
/// shell's own comment names the cost: *"a safety limit that exists twice, in
/// two languages, is one limit and one liability"*. Red-control: move
/// `MAX_EASE_MS` and this must follow.
#[derive(Debug, Serialize)]
pub struct Limits {
  pub min_dwell: u32,
  pub min_ease: u32,
  pub max_ease: u32,
}

impl Limits {
  pub fn current() -> Self {
    Self { min_dwell: limits::MIN_DWELL_MS, min_ease: limits::MIN_EASE_MS, max_ease: limits::MAX_EASE_MS }
  }
}

impl Default for Limits {
  fn default() -> Self {
    Self::current()
  }
}

/// One social row. `qr` is absent rather than empty when the reel has none.
#[derive(Debug, Serialize)]
pub struct SocialRow {
  pub label: String,
  pub handle: String,
  pub url: String,
  /// **ABSENT-IS-VALID, CARRIED AS AN `Option` AND SKIPPED WHEN NONE.** AC-3.3's
  /// rule at the payload's altitude: no asset is a valid configuration, not a
  /// missing one. An empty string here would be a THIRD state the player has to
  /// distinguish from a QR that failed to load.
  #[serde(skip_serializing_if = "Option::is_none")]
  pub qr: Option<String>,
}

/// The persistent corner mark, embedded once and reused by every slide.
#[derive(Debug, Serialize)]
pub struct BugRow {
  pub src: String,
  pub caption: String,
  pub opacity: f64,
  pub height: f64,
  pub x: f64,
  pub y: f64,
}

/// Build every social row, and say which QRs look stale.
///
/// **THE WARNINGS ARE RETURNED, NOT PRINTED**, so the caller owns the stream and
/// the tests can read them -- the same shape as `plan::report`.
///
/// **AND THIS PORT WARNS ON ONE CASE THE REFERENCE IS BLIND TO, WHICH IS
/// AC-4.2's FIRST FINDING.** The reference's guard is
/// `if m and m.group(1) != row["url"]`, so it SHORT-CIRCUITS when the regex does
/// not match -- and `row["qr"] = svg` then runs regardless. A QR made by hand,
/// copied from another reel, or produced by any tool other than `showreel qr`
/// carries no stamp at all, **and that is precisely the population most likely
/// to be stale**. The detector is blind to its own worst case and ships it
/// silently.
///
/// **TAKING THE FIX IS FREE BECAUSE IT CHANGES NO PIXELS.** The unstamped QR is
/// still embedded, exactly as the reference embeds it; only a warning is added.
/// Contrast the other half of AC-4.2, which would change WHICH QR is embedded --
/// that one is not taken silently and is WP-04's.
pub fn socials(reel: &Path, cfg: &config::Reel) -> (Vec<SocialRow>, Vec<String>) {
  let mut rows = Vec::new();
  let mut warnings = Vec::new();
  for s in &cfg.socials {
    let url = s.url.trim().to_string();
    let mut row =
      SocialRow { label: s.label.clone(), handle: s.handle.clone(), url, qr: None };
    let path = plan::qr_path(reel, s);
    if !row.url.is_empty() {
      if let Ok(svg) = std::fs::read_to_string(&path) {
        match stamped_for(&svg) {
          Some(was) if was != row.url => warnings.push(format!(
            "QR for {} was generated for\n    {was}\n  but the config now says\n    {}\n  fix: showreel qr <dir> --force",
            row.label, row.url
          )),
          Some(_) => {}
          None => warnings.push(format!(
            "QR for {} carries no '{QR_STAMP}' stamp, so nothing can say whether it matches\n    {}\n  fix: showreel qr <dir> --force",
            row.label, row.url
          )),
        }
        row.qr = Some(svg);
      }
    }
    rows.push(row);
  }
  (rows, warnings)
}

/// The address a QR's stamp says it was generated for, if it carries one.
fn stamped_for(svg: &str) -> Option<String> {
  let open = svg.find("<!--")?;
  if !svg[..open].trim().is_empty() {
    return None;
  }
  let rest = &svg[open + 4..];
  let body = &rest[..rest.find("-->")?];
  body.strip_prefix(QR_STAMP).map(str::to_string)
}

/// The corner mark, or `None` when the reel declares no bug.
///
/// **THE ADMISSION IS THE POINT, AND IT IS A SEVENTH `admit` CALL SITE.**
/// `plan::plan` joins `bug.file` unclassified while every other image field
/// refuses through `admit::named`, so a bug naming a `.txt` reached `embed` and
/// failed there with a decoder's message instead of a remedy. The reference
/// refuses too -- by name on a declared bug with no file, and by name on a file
/// that is not there -- so this is the port catching up rather than diverging.
/// **AC-3.2's evidence states SIX sites and this makes it seven**; vc owns that
/// row and has been told.
pub fn bug(reel: &Path, cfg: &config::Reel) -> Result<Option<BugRow>, Failure> {
  let Some(spec) = &cfg.bug else { return Ok(None) };
  if spec.file.trim().is_empty() {
    return Err(Failure::new(
      "bug: needs a file:",
      "bug: {file: assets/brand/corner.png}, or remove the bug: block",
    ));
  }
  let site = admit::Site { owner: "bug", field: "file:" };
  let path = admit::named(reel, &spec.file, site, admit::Requires::Image)?;
  let art = normalise::embed(&path, cfg.embed_target(), normalise::Role::Bug)?;
  Ok(Some(BugRow {
    src: art.uri,
    caption: spec.caption.clone(),
    opacity: spec.opacity.unwrap_or(0.55),
    height: spec.height.unwrap_or(9.0),
    x: spec.x.unwrap_or(2.2),
    y: spec.y.unwrap_or(1.8),
  }))
}

#[cfg(test)]
mod tests {
  use super::*;
  use std::path::PathBuf;

  fn reel(tag: &str, files: &[(&str, &str)]) -> PathBuf {
    let d = std::env::temp_dir().join(format!("showreel-payload-{}-{tag}", std::process::id()));
    let _ = std::fs::remove_dir_all(&d);
    std::fs::create_dir_all(&d).unwrap();
    for (name, body) in files {
      let p = d.join(name);
      std::fs::create_dir_all(p.parent().unwrap()).unwrap();
      std::fs::write(&p, body).unwrap();
    }
    d
  }

  fn cfg(yaml: &str) -> config::Reel {
    config::parse(yaml, "payload-test").unwrap()
  }

  /// **AC-3.6's RUNTIME LEG, PAYLOAD HALF.** Asserted as LITERALS so moving a
  /// constant breaks it -- the vacuous form would read the constant on both
  /// sides and agree with itself. And `max_ease` is **2400, not the reference's
  /// 3000**, because hv capped it: the payload is where that cap reaches the
  /// runtime.
  #[test]
  fn the_limits_block_carries_the_compilers_own_floors_and_not_the_references() {
    let l = Limits::current();
    assert_eq!(l.min_dwell, 2500);
    assert_eq!(l.min_ease, 600);
    assert_eq!(l.max_ease, 2400, "hv's cap, not the reference's 3000");
  }

  /// All three sub-keys, spelled the way `player.html` reads them. **A payload
  /// missing one throws on the first slide and the harness cannot see it.**
  #[test]
  fn the_limits_block_serialises_every_key_the_player_binds() {
    let j = serde_json::to_string(&Limits::current()).unwrap();
    for k in ["min_dwell", "min_ease", "max_ease"] {
      assert!(j.contains(&format!("\"{k}\"")), "missing {k} in {j}");
    }
  }

  #[test]
  fn a_social_without_a_qr_on_disk_omits_the_key_rather_than_emitting_an_empty_one() {
    let r = reel("noqr", &[]);
    let c = cfg("artist: {handle: x}\nsocials: [{label: Web, handle: a, url: 'https://a.example'}]\n");
    let (rows, warns) = socials(&r, &c);
    assert_eq!(rows.len(), 1);
    assert!(rows[0].qr.is_none(), "absent is valid and says nothing");
    assert!(warns.is_empty(), "{warns:?}");
    let j = serde_json::to_string(&rows[0]).unwrap();
    assert!(!j.contains("\"qr\""), "the key is omitted, not empty: {j}");
  }

  /// The reference's own case: a stamp that names a different address.
  #[test]
  fn a_qr_stamped_for_another_address_warns_and_is_still_embedded() {
    let r = reel("stale", &[("assets/qr/web.svg", "<!--showreel-qr:https://old.example--><svg/>")]);
    let c = cfg("artist: {handle: x}\nsocials: [{label: Web, handle: a, url: 'https://new.example'}]\n");
    let (rows, warns) = socials(&r, &c);
    assert_eq!(warns.len(), 1, "{warns:?}");
    assert!(warns[0].contains("https://old.example"), "{}", warns[0]);
    assert!(warns[0].contains("https://new.example"), "{}", warns[0]);
    assert!(rows[0].qr.is_some(), "the reference embeds it anyway and so does this");
  }

  /// **THE CASE THE REFERENCE IS BLIND TO, AND THE ONE MOST LIKELY TO BE
  /// STALE.** No stamp at all: the reference's `if m and ...` short-circuits and
  /// it ships without a word.
  #[test]
  fn a_qr_with_no_stamp_at_all_warns_where_the_reference_says_nothing() {
    let r = reel("unstamped", &[("assets/qr/web.svg", "<svg>hand drawn</svg>")]);
    let c = cfg("artist: {handle: x}\nsocials: [{label: Web, handle: a, url: 'https://a.example'}]\n");
    let (rows, warns) = socials(&r, &c);
    assert_eq!(warns.len(), 1, "{warns:?}");
    assert!(warns[0].contains("no 'showreel-qr:' stamp"), "{}", warns[0]);
    assert!(rows[0].qr.is_some(), "and it is STILL embedded -- the fix changes no pixels");
  }

  /// A stamp that matches is the normal case and must stay silent.
  #[test]
  fn a_qr_stamped_for_the_configured_address_says_nothing() {
    let r = reel("fresh", &[("assets/qr/web.svg", "<!--showreel-qr:https://a.example--><svg/>")]);
    let c = cfg("artist: {handle: x}\nsocials: [{label: Web, handle: a, url: 'https://a.example'}]\n");
    let (_, warns) = socials(&r, &c);
    assert!(warns.is_empty(), "{warns:?}");
  }

  #[test]
  fn a_reel_with_no_bug_block_builds_none_rather_than_refusing() {
    let r = reel("nobug", &[]);
    assert!(bug(&r, &cfg("artist: {handle: x}\n")).unwrap().is_none());
  }

  /// **THE ABSENT KEY NEVER REACHES THIS MODULE, AND THAT IS THE PARSER BEING
  /// STRICTER THAN THE REFERENCE.** `config::Bug::file` carries no
  /// `#[serde(default)]`, so `bug: {caption: hi}` refuses at PARSE time naming
  /// the missing field -- where the reference gets as far as `build_bug` and
  /// dies there. Pinned here because it is the guard that actually fires, and a
  /// later `#[serde(default)]` added for tidiness would silently move the
  /// failure two stages downstream.
  #[test]
  fn a_bug_declared_without_a_file_key_is_refused_by_the_parser_not_by_this_module() {
    let e = config::parse("artist: {handle: x}\nbug: {caption: hi}\n", "r").unwrap_err();
    assert!(e.message.contains("missing field `file`"), "{}", e.message);
  }

  /// **AND THE VALUE THE PARSER LETS THROUGH IS THIS MODULE'S TO REFUSE.** An
  /// empty string satisfies `file: String`, so the two checks sit at different
  /// altitudes and neither is redundant: the parser catches an absent KEY, this
  /// catches a present-but-empty VALUE.
  #[test]
  fn a_bug_whose_file_is_empty_refuses_here_by_name() {
    let r = reel("bugempty", &[]);
    let e = bug(&r, &cfg("artist: {handle: x}\nbug: {file: ''}\n")).unwrap_err();
    assert!(e.message.contains("needs a file"), "{}", e.message);
  }

  /// **vc's RECORDED PREDICTION, DISCHARGED.** `plan::plan` joins `bug.file`
  /// unclassified; this is the site that classifies it, so a bug naming a file
  /// that is not there refuses with a remedy instead of failing inside a decoder.
  #[test]
  fn a_bug_naming_a_file_that_is_not_there_refuses_with_a_remedy() {
    let r = reel("bugmissing", &[]);
    let e = bug(&r, &cfg("artist: {handle: x}\nbug: {file: assets/brand/nope.png}\n")).unwrap_err();
    assert!(e.message.contains("nope.png"), "names the file: {}", e.message);
    assert!(e.remedy.is_some(), "and carries a remedy");
  }

  /// The classifier's own rule at the seventh site: a bug naming a `.txt` is
  /// refused for being the wrong TYPE, not for being absent.
  ///
  /// **THIS ASSERTED A NEGATIVE UNTIL THE RED-PROOF REFUSED TO FIRE.** It read
  /// `!e.message.contains("missing")` -- and with the admission removed and
  /// `bug.file` joined unclassified the way `plan.rs` still joins it, the `.txt`
  /// reached `normalise::embed` and failed in the DECODER, whose message does
  /// not contain "missing" either. The test passed against exactly the defect it
  /// was written to catch. **A negative assertion passes on almost any failure**,
  /// which is the same family as an assertion that sources the constant it is
  /// testing: it looks like rigour and cannot fail. Now it names the SITE, which
  /// only the classifier's refusal carries.
  #[test]
  fn a_bug_naming_something_that_is_not_an_image_is_refused_for_its_type() {
    let r = reel("bugtxt", &[("assets/brand/notes.txt", "not a picture")]);
    let e = bug(&r, &cfg("artist: {handle: x}\nbug: {file: assets/brand/notes.txt}\n")).unwrap_err();
    assert!(e.message.starts_with("bug: file:"), "the SITE is named: {}", e.message);
    assert!(e.message.contains("notes.txt"), "and the file: {}", e.message);
    assert!(e.remedy.is_some_and(|r| r.contains("jpg")), "and the remedy lists the types it takes");
  }
}
