//! What a build of this config READS -- slides and the files behind them, in one
//! walk.
//!
//! **THE ASSET LIST IS A PROJECTION OF THE PLAN, AND THE PLAN IS NOT THE SLIDE
//! LIST.** `Slide::assets` is correct about a slide and cannot be correct about
//! the reel: the persistent bug, each social's QR and the venue QR are read by
//! the ARTIFACT rather than by any one slide, and no arm of that match could
//! return them. Measured against the live 45h reel: the slide projection is 10
//! files, the reference's `used` is 14, and the four it does not reach are the
//! social QRs.
//!
//! **THAT GAP IS NOT A MISSING WARNING, IT IS A CONFIDENT WRONG INSTRUCTION.**
//! `report_unused` exists so an operator can delete exhaust; fed the slide
//! projection it names four files the build embeds and tells them to remove
//! them. So `used` is projected from `Plan` -- slides UNION reel-level -- and
//! there is exactly one of it.
//!
//! **AND 45h CANNOT TEST THE BUG HALF, WHICH IS WHY THE TESTS BUILD THEIR OWN
//! REELS.** That config's `bug.file` IS the logo segment's file, so the bug
//! enters `used` through the slide walk anyway and a build that dropped it
//! entirely still counts 14. The arithmetic agrees for the wrong reason.

use crate::{config, segment, slide};
use artifact::Failure;
use std::collections::BTreeSet;
use std::path::{Component, Path, PathBuf};

/// The reference's `slug`, for the social QR convention and nothing else.
///
/// **NOT `tight`, AND THE REFERENCE IS EXPLICIT ABOUT WHY.** This keeps the
/// hyphen because it names an asset; `tight` strips it because a hyphen is the
/// FIELD SEPARATOR in the output filename convention and one inside a field
/// makes the name unparseable. Two transforms, two jobs, deliberately not
/// merged.
pub fn slug(s: &str) -> String {
  let kept: String = s
    .chars()
    .filter(|c| c.is_alphanumeric() || c.is_whitespace() || *c == '-' || *c == '_')
    .collect();
  let mut out = String::with_capacity(kept.len());
  let mut pending = false;
  for c in kept.trim().to_lowercase().chars() {
    if c == '-' || c.is_whitespace() {
      pending = true;
    } else {
      if pending && !out.is_empty() {
        out.push('-');
      }
      pending = false;
      out.push(c);
    }
  }
  out
}

/// Where a social's QR lives: an explicit `qr:` wins, else the convention.
pub fn qr_path(reel: &Path, social: &config::Social) -> PathBuf {
  match &social.qr {
    Some(rel) => reel.join(rel),
    None => reel.join(format!("assets/qr/{}.svg", slug(&social.label))),
  }
}

/// The venue QR has no socials entry to name it, so its path is fixed.
pub fn venue_qr_path(reel: &Path) -> PathBuf {
  reel.join("assets/qr/venue.svg")
}

/// Lexically normalise, so the two sides of `have - used` are comparable.
///
/// **THE REFERENCE CALLS `.resolve()` ON BOTH SIDES AND THE PORT MUST NORMALISE
/// BOTH TOO, OR IT REPORTS FALSE POSITIVES.** `admit::named` returns
/// `reel.join(rel)` verbatim, so a config writing a path through its own parent
/// produces the same FILE as the walker's and a different `Path`. Subtracting
/// one from the other would then name a live input as exhaust -- and the harm is
/// not a missing warning, it is telling an operator to delete what the build
/// embeds.
///
/// **`..` IS THE CASE THIS IS FOR AND `.` IS NOT, WHICH THE RED-PROOF HAD TO
/// TELL ME.** Rust compares and orders `Path` by COMPONENTS, and `Components`
/// already drops a `CurDir`, so `./assets/x.png` needs no help from anything
/// here. It does NOT resolve `ParentDir`, so `assets/art/../brand/x.png` is
/// where this earns its place. The first test written for this function used the
/// `.` form, passed identically with the body reduced to the identity, and
/// proved nothing.
///
/// Lexical rather than `canonicalize` because a declared QR that does not exist
/// yet is a valid configuration and `canonicalize` refuses it.
fn tidy(path: &Path) -> PathBuf {
  let mut out = PathBuf::new();
  for part in path.components() {
    match part {
      Component::CurDir => {}
      Component::ParentDir => {
        if !out.pop() {
          out.push(Component::ParentDir);
        }
      }
      other => out.push(other),
    }
  }
  out
}

/// A resolved reel: every slide, and every file the reel itself reads.
pub struct Plan {
  pub slides: Vec<slide::Slide>,
  /// Inputs a segment's scan declined, already at the segment's altitude.
  ///
  /// **CARRIED ON THE PLAN BECAUSE THE PLAN IS WHAT `report` READS.** AC-3.2
  /// says a dropped input is reported by EXTENDING `report_unused` rather than
  /// duplicating it, so there is one reporting function over both altitudes and
  /// no second path that could disagree with it.
  pub dropped: Vec<String>,
  /// Files the ARTIFACT reads that no single slide does -- the bug, the social
  /// QRs, the venue QR.
  pub reel_level: Vec<PathBuf>,
  pub pace: &'static segment::Pace,
}

impl Plan {
  /// Every file a build of this config reads, deduplicated and normalised.
  ///
  /// **ONE HOME.** The recycler that decides an asset is safe to delete reads
  /// exactly this, and so does the build.
  pub fn used(&self) -> BTreeSet<PathBuf> {
    self
      .slides
      .iter()
      .flat_map(slide::Slide::assets)
      .map(tidy)
      .chain(self.reel_level.iter().map(|p| tidy(p)))
      .collect()
  }
}

/// Resolve a config to its slides and its assets, in one walk.
pub fn plan(reel: &Path, cfg: &config::Reel) -> Result<Plan, Failure> {
  let pace = segment::pace(cfg.pace.as_deref())?;
  let defaults = slide::Defaults::resolve(pace, cfg.defaults.as_ref());

  let mut slides = Vec::new();
  let mut dropped = Vec::new();
  for (index, seg) in cfg.segments.iter().enumerate() {
    let got = slide::collect(reel, index, seg, &defaults, cfg.socials.len())?;
    slides.extend(got.slides);
    dropped.extend(got.dropped);
  }

  let mut reel_level = Vec::new();
  if let Some(bug) = &cfg.bug {
    if !bug.file.is_empty() {
      reel_level.push(reel.join(&bug.file));
    }
  }
  for social in &cfg.socials {
    reel_level.push(qr_path(reel, social));
  }
  // A venue QR is generated FROM `venue_url`, so its absence from the config is
  // what says the reel has none -- the file's absence says nothing.
  if !cfg.session.venue_url.is_empty() {
    reel_level.push(venue_qr_path(reel));
  }

  Ok(Plan { slides, reel_level, pace, dropped })
}

/// Files under `assets/` that a build of this config would not read.
pub fn spare(reel: &Path, used: &BTreeSet<PathBuf>) -> Vec<PathBuf> {
  let root = reel.join("assets");
  if !root.is_dir() {
    return Vec::new();
  }
  let mut spare: Vec<PathBuf> = walkdir::WalkDir::new(&root)
    .into_iter()
    .filter_map(Result::ok)
    .filter(|e| e.file_type().is_file())
    .filter(|e| !e.file_name().to_string_lossy().starts_with('.'))
    .map(|e| tidy(e.path()))
    .filter(|p| !used.contains(p))
    .collect();
  spare.sort();
  spare
}

/// Name what the build did not use: inputs a segment DROPPED, then files under
/// `assets/` no segment read.
///
/// **REPORTED, NEVER DELETED.** A reel accumulates exhaust -- an asset stops
/// being referenced when a segment is rewritten and nothing about the output
/// says so -- but the tool does not get to decide that a picture is finished
/// with. Returned as lines rather than printed, so the caller owns the stream
/// and the tests can read it.
///
/// **TWO ALTITUDES, ONE FUNCTION, WHICH IS WHAT AC-3.2 ASKS FOR IN THOSE WORDS**
/// -- *"extending `report_unused` rather than duplicating it"*. The segment
/// lines come FIRST because they are the narrower fact: a named file the author
/// pointed a segment at and did not get. The reel-wide sweep follows.
///
/// **AND THE DROPS ARE NOT BEHIND THE `spare.is_empty()` EARLY RETURN.** They
/// were, in the first draft of this change, which would have made a segment's
/// drop invisible on exactly the tidy reels where it is the only thing worth
/// saying.
pub fn report(reel: &Path, used: &BTreeSet<PathBuf>, dropped: &[String]) -> Vec<String> {
  let mut out: Vec<String> = dropped.to_vec();
  let spare = spare(reel, used);
  if spare.is_empty() {
    return out;
  }
  let bytes: u64 = spare.iter().filter_map(|p| std::fs::metadata(p).ok()).map(|m| m.len()).sum();
  let mb = bytes as f64 / 1_048_576.0;
  out.push(format!("{} unused asset(s) under assets/, {mb:.1} MB:", spare.len()));
  for p in &spare {
    out.push(format!("    {}", p.strip_prefix(reel).unwrap_or(p).display()));
  }
  out
}

#[cfg(test)]
mod tests {
  use super::*;

  fn reel(tag: &str, files: &[&str]) -> PathBuf {
    let d = std::env::temp_dir().join(format!("showreel-plan-{}-{tag}", std::process::id()));
    let _ = std::fs::remove_dir_all(&d);
    std::fs::create_dir_all(&d).unwrap();
    for f in files {
      let p = d.join(f);
      std::fs::create_dir_all(p.parent().unwrap()).unwrap();
      std::fs::write(&p, b"x").unwrap();
    }
    d
  }

  fn parse(yaml: &str) -> config::Reel {
    config::parse(yaml, "test").unwrap()
  }

  /// **THE TEST 45h CANNOT PROVIDE, AND THAT IS WHY IT IS WRITTEN BY HAND.**
  /// On the live reel `bug.file` IS the logo segment's file, so the bug enters
  /// `used` through the slide walk and a build that dropped it entirely still
  /// counts 14. Here the bug is a file NO slide reads, so the slide projection
  /// and the plan give different answers and only the plan is right.
  #[test]
  fn the_bug_is_used_though_no_slide_reads_it() {
    let r = reel("bug", &["assets/art/a.jpg", "assets/brand/corner.png"]);
    let cfg = parse(
      "artist: {handle: x}\nbug: {file: assets/brand/corner.png}\nsegments: [{id: g, type: gallery, from: assets/art}]\n",
    );
    let p = plan(&r, &cfg).unwrap();

    let per_slide: BTreeSet<PathBuf> =
      p.slides.iter().flat_map(slide::Slide::assets).map(tidy).collect();
    assert!(!per_slide.contains(&r.join("assets/brand/corner.png")), "no slide reads the bug");
    assert!(p.used().contains(&r.join("assets/brand/corner.png")), "and the plan does");
    assert_eq!(per_slide.len(), 1, "one gallery file");
    assert_eq!(p.used().len(), 2, "plus the bug");
  }

  /// **THE CONSEQUENCE, STATED AS THE HARM RATHER THAN AS A COUNT.** Fed the
  /// slide projection, `report` names a file the build embeds and tells the
  /// operator to delete it.
  #[test]
  fn the_exhaust_report_never_names_a_file_the_build_reads() {
    let r = reel("exhaust", &["assets/art/a.jpg", "assets/brand/corner.png", "assets/old/gone.jpg"]);
    let cfg = parse(
      "artist: {handle: x}\nbug: {file: assets/brand/corner.png}\nsegments: [{id: g, type: gallery, from: assets/art}]\n",
    );
    let p = plan(&r, &cfg).unwrap();

    let lines = report(&r, &p.used(), &p.dropped);
    assert!(lines.iter().any(|l| l.contains("gone.jpg")), "names the real exhaust: {lines:?}");
    assert!(!lines.iter().any(|l| l.contains("corner.png")), "and NOT the bug: {lines:?}");

    // The control: the narrower projection DOES name it, which is the defect.
    let narrow: BTreeSet<PathBuf> =
      p.slides.iter().flat_map(slide::Slide::assets).map(tidy).collect();
    assert!(
      report(&r, &narrow, &p.dropped).iter().any(|l| l.contains("corner.png")),
      "the slide-only set would tell the operator to delete the bug"
    );
  }

  /// A declared QR that is not on disk yet is still READ BY THE CONFIG, so it
  /// must not be reported as exhaust. The reference adds socials' QRs to `used`
  /// unconditionally for exactly this reason.
  #[test]
  fn a_social_contributes_its_qr_whether_or_not_the_file_exists() {
    let r = reel("qr", &["assets/qr/instagram.svg"]);
    let cfg = parse(
      "artist: {handle: x}\nsocials: [{label: Instagram}, {label: TikTok}]\nsegments: []\n",
    );
    let used = plan(&r, &cfg).unwrap().used();
    assert!(used.contains(&r.join("assets/qr/instagram.svg")), "the one that exists");
    assert!(used.contains(&r.join("assets/qr/tiktok.svg")), "and the one that does not yet");
  }

  #[test]
  fn an_explicit_qr_wins_over_the_convention() {
    let r = reel("explicit", &[]);
    let cfg =
      parse("artist: {handle: x}\nsocials: [{label: Showreel, qr: assets/qr/named.svg}]\nsegments: []\n");
    let used = plan(&r, &cfg).unwrap().used();
    assert!(used.contains(&r.join("assets/qr/named.svg")), "{used:?}");
    assert!(!used.contains(&r.join("assets/qr/showreel.svg")), "the convention must not also fire");
  }

  /// The venue QR is generated FROM `venue_url`, so the config says whether the
  /// reel has one. The file's absence says nothing.
  #[test]
  fn the_venue_qr_is_read_only_when_the_config_carries_a_venue_url() {
    let r = reel("venue", &[]);
    let without = plan(&r, &parse("artist: {handle: x}\nsegments: []\n")).unwrap().used();
    assert!(!without.contains(&r.join("assets/qr/venue.svg")));

    let with = plan(
      &r,
      &parse("artist: {handle: x}\nsession: {venue_url: 'https://example.test/'}\nsegments: []\n"),
    )
    .unwrap()
    .used();
    assert!(with.contains(&r.join("assets/qr/venue.svg")));
  }

  /// **BOTH SIDES OF `have - used` MUST NORMALISE OR THE REPORT LIES**, and the
  /// two forms are NOT equally hard. Rust's `Path` compares by components and
  /// drops a `.` itself, so the first version of this test -- which used only the
  /// `./` form -- passed with `tidy` reduced to the identity and proved nothing.
  /// `..` is not resolved by `Components` and is the case that needs the
  /// function. Both are asserted, and the comment says which is which so nobody
  /// deletes the one doing the work.
  #[test]
  fn a_path_written_through_its_own_parent_is_not_reported_as_exhaust() {
    let r = reel("dotted", &["assets/brand/corner.png"]);

    // The form Rust handles unaided. Kept as a record, not as evidence.
    let free = parse("artist: {handle: x}\nbug: {file: ./assets/brand/corner.png}\nsegments: []\n");
    let p = plan(&r, &free).unwrap();
    assert!(report(&r, &p.used(), &p.dropped).is_empty(), "{:?}", report(&r, &p.used(), &p.dropped));

    // The form `tidy` exists for.
    let hard =
      parse("artist: {handle: x}\nbug: {file: assets/art/../brand/corner.png}\nsegments: []\n");
    let p = plan(&r, &hard).unwrap();
    assert!(
      report(&r, &p.used(), &p.dropped).is_empty(),
      "a path through its own parent is the same file: {:?}",
      report(&r, &p.used(), &p.dropped)
    );
  }

  /// **THE EARLY RETURN NEARLY SWALLOWED THIS.** `report` returned `Vec::new()`
  /// the moment `spare` was empty, which would have hidden a segment's drop on
  /// exactly the tidy reels where it is the only thing worth saying. The fixture
  /// carries no `assets/` at all, so the reel-wide sweep is empty BY
  /// CONSTRUCTION and only the segment line can carry the report.
  #[test]
  fn a_segment_drop_is_reported_even_when_the_reel_has_no_exhaust_at_all() {
    let r = reel("tidy", &["art/a.jpg", "art/notes.txt"]);
    let cfg = parse("artist: {handle: x}\nsegments: [{id: g, type: gallery, from: art}]\n");
    let p = plan(&r, &cfg).unwrap();
    assert!(spare(&r, &p.used()).is_empty(), "no assets/ dir, so nothing is exhaust");
    let lines = report(&r, &p.used(), &p.dropped);
    assert_eq!(lines.len(), 1, "the drop is the whole report: {lines:?}");
    assert!(lines[0].contains("notes.txt"), "{}", lines[0]);
  }

  /// **TWO ALTITUDES, ONE FUNCTION, NARROWER FIRST** -- AC-3.2's "extending
  /// `report_unused` rather than duplicating it", asserted as an ORDER so a
  /// later edit cannot quietly append the segment's named file after the
  /// reel-wide list it is easy to stop reading.
  #[test]
  fn the_segment_altitude_is_reported_before_the_reel_wide_sweep() {
    let r = reel("both", &["assets/art/a.jpg", "assets/art/notes.txt", "assets/old/gone.jpg"]);
    let cfg = parse("artist: {handle: x}\nsegments: [{id: g, type: gallery, from: assets/art}]\n");
    let p = plan(&r, &cfg).unwrap();
    let lines = report(&r, &p.used(), &p.dropped);
    let seg = lines.iter().position(|l| l.contains("segment 'g'")).expect("a segment line");
    let sweep = lines.iter().position(|l| l.contains("unused asset(s)")).expect("a sweep line");
    assert!(seg < sweep, "the segment's altitude comes first: {lines:?}");
  }

  /// `slug` names an ASSET and keeps the hyphen; `tight` names a filename FIELD
  /// and strips it. These are the cases that actually reach a file on 45h.
  #[test]
  fn slug_lowercases_and_joins_on_hyphens_without_dropping_them() {
    assert_eq!(slug("LinkedIn"), "linkedin");
    assert_eq!(slug("TikTok"), "tiktok");
    assert_eq!(slug("Watch this again"), "watch-this-again");
    assert_eq!(slug("  Spaced  Out  "), "spaced-out");
    assert_eq!(slug("Bea's Art!"), "beas-art");
    assert_eq!(slug("already-hyphenated"), "already-hyphenated");
  }

  /// A hidden file is not exhaust; it was never part of the population. The
  /// reference excludes them from `have` for the same reason.
  #[test]
  fn a_hidden_file_is_not_reported_as_exhaust() {
    let r = reel("hidden", &["assets/.DS_Store", "assets/art/a.jpg"]);
    let cfg = parse("artist: {handle: x}\nsegments: [{id: g, type: gallery, from: assets/art}]\n");
    let p = plan(&r, &cfg).unwrap();
    assert!(report(&r, &p.used(), &p.dropped).is_empty(), "{:?}", report(&r, &p.used(), &p.dropped));
  }
}
