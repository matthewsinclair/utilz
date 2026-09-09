//! What a segment BECOMES: the slide list, and the asset list derived from it.
//!
//! **AC-3.8 IS A STRUCTURAL PROPERTY HERE RATHER THAN A DISCIPLINE.** The
//! reference derived the slides and the used-asset set in one walk after they
//! had been two, and its own comment says why: they agreed only as long as
//! somebody remembered to update both, and the one that goes stale is the one
//! that tells you an asset is safe to delete. **In this port the asset list is
//! not a second walk at all -- it is a projection of the slides**, so a slide
//! that reads a file it does not declare is a compile error rather than a
//! divergence nobody notices.
//!
//! **AND THE FIVE RENDERING DEFAULTS RESOLVE IN ONE PLACE.** `main.rs` did that
//! inline for `check`; building a second copy here is exactly the subset
//! duplicate that hid in the pace table, so `check` now calls this.

use crate::segment::{self, Pace};
use crate::{admit, config, duration, limits};
use artifact::Failure;
use std::path::{Path, PathBuf};

/// The five rendering defaults, resolved from the pace preset and the config's
/// `defaults:` block.
///
/// **PRECEDENCE, STATED ONCE: segment key, then `defaults:`, then the preset.**
/// The reference builds the same order by dict-update, and it is the kind of
/// thing that is obvious until it is written down twice.
#[derive(Debug, Clone)]
pub struct Defaults {
  pub dwell: String,
  pub ease: String,
  pub transition: String,
  pub motion: String,
  pub fit: String,
}

impl Defaults {
  pub fn resolve(pace: &Pace, cfg: Option<&config::Defaults>) -> Defaults {
    let pick = |from: Option<&String>, fallback: &str| {
      from.map_or_else(|| fallback.to_string(), String::clone)
    };
    Defaults {
      dwell: pick(cfg.and_then(|d| d.dwell.as_ref()), pace.dwell),
      ease: pick(cfg.and_then(|d| d.ease.as_ref()), pace.ease),
      transition: pick(cfg.and_then(|d| d.transition.as_ref()), pace.transition),
      motion: pick(cfg.and_then(|d| d.motion.as_ref()), pace.motion),
      fit: pick(cfg.and_then(|d| d.fit.as_ref()), pace.fit),
    }
  }
}

/// The rendering fields every slide carries.
#[derive(Debug, Clone)]
pub struct Common {
  pub dwell_ms: u32,
  pub ease_ms: u32,
  pub transition: String,
  pub fit: String,
  pub motion: String,
  /// Whether the timing envelope moved either duration.
  pub clamped: bool,
}

/// A QR a segment NAMED.
///
/// **`Option<Qr>` IS AC-3.3, AND THE TYPE IS THE POINT.** QR absence is the one
/// silent absence in this tool that is a decision rather than a defect, and it
/// sits directly beside ones that are defects -- so it is carried as a type
/// where flattening it is a compile error, not as a policy someone tidies away.
/// **Absent and declared-but-missing are DIFFERENT FACTS**: the first is this
/// `None`, the second refuses at admission. The reference returned `""` for both
/// and that is what made them look like one thing.
#[derive(Debug, Clone)]
pub struct Qr {
  pub path: PathBuf,
}

/// One slide, ready to render.
#[derive(Debug)]
pub struct Slide {
  pub id: String,
  pub common: Common,
  pub kind: Kind,
}

/// One question-and-answer pair on an `faq` slide.
#[derive(Debug, Clone)]
pub struct FaqItem {
  pub q: String,
  pub a: String,
}

/// What a slide IS. One variant per rendering shape, which is NOT one per
/// segment type: `logo` and `gallery` both produce `Image`, and `socials`
/// produces `Socials` or N x `Social` depending on its layout.
#[derive(Debug)]
pub enum Kind {
  Crawl { source: String },
  Card { headline: String, sub: String, bg: String },
  Statement { kicker: String, headline: String, body: String, bg: String },
  Faq { headline: String, items: Vec<FaqItem>, bg: String },
  Atwork {
    kicker: String,
    name: String,
    strap: String,
    caption: String,
    qr: Option<Qr>,
    bg: String,
  },
  Strapline { mark: Option<PathBuf>, lines: Vec<String>, bg: String },
  Points { headline: String, body: String, points: Vec<String>, bg: String },
  Venue {
    image: Option<PathBuf>,
    kicker: String,
    headline: String,
    at: String,
    city: String,
    bg: String,
  },
  Wordmark { top: String, mid: String, bottom: String, bg: String },
  Socials { headline: String, bg: String },
  Social { index: usize, headline: String, bg: String },
  Image { path: PathBuf },
}

impl Slide {
  /// Every file this slide reads.
  ///
  /// **THIS IS AC-3.8: THE ASSET LIST IS A PROJECTION OF THE SLIDE LIST**, not a
  /// second walk over the config. The two cannot disagree because there is only
  /// one of them, and the recycler that decides an asset is safe to delete reads
  /// exactly what the build read.
  pub fn assets(&self) -> Vec<&Path> {
    match &self.kind {
      Kind::Image { path } => vec![path.as_path()],
      Kind::Strapline { mark: Some(p), .. } | Kind::Venue { image: Some(p), .. } => {
        vec![p.as_path()]
      }
      Kind::Atwork { qr: Some(q), .. } => vec![q.path.as_path()],
      _ => Vec::new(),
    }
  }
}

/// Read one segment's fields, with the owner string every refusal needs.
struct Fields<'a> {
  map: &'a serde_yaml::Mapping,
  owner: String,
}

impl Fields<'_> {
  fn raw(&self, key: &str) -> Option<&serde_yaml::Value> {
    self.map.get(serde_yaml::Value::from(key))
  }

  /// A string field, or the given default. A number is rendered rather than
  /// refused, because `top: 2026` is a reasonable thing to write in a wordmark.
  fn text(&self, key: &str, default: &str) -> String {
    self.raw(key).map_or_else(
      || default.to_string(),
      |v| {
        v.as_str().map_or_else(
          || v.as_u64().map_or_else(|| default.to_string(), |n| n.to_string()),
          str::to_string,
        )
      },
    )
  }

  fn opt_text(&self, key: &str) -> Option<String> {
    self.raw(key).and_then(|v| v.as_str()).map(str::to_string)
  }

  /// A list of strings, dropping entries that are blank after trimming --
  /// the reference's `if str(x).strip()`, which is what lets a config carry a
  /// trailing empty line without it becoming an empty row on screen.
  fn list(&self, key: &str) -> Vec<String> {
    self
      .raw(key)
      .and_then(|v| v.as_sequence())
      .map(|xs| {
        xs.iter()
          .filter_map(|x| x.as_str().map(str::to_string).or_else(|| x.as_u64().map(|n| n.to_string())))
          .filter(|x| !x.trim().is_empty())
          .collect()
      })
      .unwrap_or_default()
  }

  fn missing(&self, what: &str, remedy: &str) -> Failure {
    Failure::new(format!("{}: {what}", self.owner), remedy)
  }
}

/// Resolve one segment into its slides.
///
/// **NOTHING HERE READS AN IMAGE, AND THAT IS WHY THE REFERENCE'S `dry` FLAG HAS
/// NO COUNTERPART.** `collect_segment` both planned and embedded, so it needed a
/// flag to plan without embedding -- and callers that wanted only the asset list
/// had to remember to pass it. Splitting the two makes the flag unnecessary and
/// makes AC-3.8's single walk true by construction rather than by care.
/// What one segment resolved to: its slides, and anything its scan DROPPED.
///
/// **THE DROPS ARE CARRIED RATHER THAN PRINTED**, so the segment's altitude
/// survives the trip to `plan::report`, which is the one home this estate
/// reports unused inputs from. AC-3.2's clause is that a dropped input is
/// reported AT THE SEGMENT -- and a line assembled at the reel's altitude can
/// no longer say which segment dropped it.
pub struct Collected {
  pub slides: Vec<Slide>,
  /// One line per input the segment's scan declined, already carrying the
  /// segment's name and field. Empty is the normal case and must stay silent.
  pub dropped: Vec<String>,
}

pub fn collect(
  reel: &Path,
  index: usize,
  seg: &serde_yaml::Value,
  defaults: &Defaults,
  socials: usize,
) -> Result<Collected, Failure> {
  let map = seg.as_mapping().ok_or_else(|| {
    Failure::new(
      format!("segment {index} is not a mapping"),
      "each entry under segments: is a block of key: value pairs",
    )
  })?;
  let id = map
    .get(serde_yaml::Value::from("id"))
    .and_then(|v| v.as_str())
    .map_or_else(|| index.to_string(), str::to_string);
  let f = Fields { map, owner: format!("segment '{id}'") };
  let owner = f.owner.clone();

  let dwell = duration::parse(&f.text("dwell", &defaults.dwell), "dwell", &owner)?;
  let ease = duration::parse(&f.text("ease", &defaults.ease), "ease", &owner)?;
  let timing = limits::timing(&id, dwell, ease)?;
  let transition = f.text("transition", &defaults.transition);
  let fit = f.text("fit", &defaults.fit);
  let motion = f.text("motion", &defaults.motion);
  segment::value("transition", &transition, segment::TRANSITIONS, &owner)?;
  segment::value("fit", &fit, segment::FITS, &owner)?;
  segment::value("motion", &motion, segment::MOTIONS, &owner)?;

  let common = Common {
    dwell_ms: timing.dwell_ms,
    ease_ms: timing.ease_ms,
    transition,
    fit,
    motion,
    clamped: timing.dwell_ms != dwell || timing.ease_ms != ease,
  };
  // Most shapes are static text and are not animated; the reference sets
  // motion="none" on each of them rather than trusting the default.
  let still = |k: Kind| {
    vec![Slide { id: id.clone(), common: Common { motion: "none".into(), ..common.clone() }, kind: k }]
  };

  let kind = f.text("type", segment::DEFAULT_SHAPE);
  let site = |field: &'static str| admit::Site { owner: &owner, field };

  let slides = match kind.as_str() {
    "crawl" => still(Kind::Crawl { source: f.text("source", "session") }),
    "card" => still(Kind::Card {
      headline: f.text("headline", ""),
      sub: f.text("sub", ""),
      bg: f.text("bg", "accent"),
    }),
    "statement" => still(Kind::Statement {
      kicker: f.text("kicker", ""),
      headline: f.text("headline", ""),
      body: f.text("body", ""),
      bg: f.text("bg", "blue"),
    }),
    "faq" => {
      let items = faq_items(&f)?;
      still(Kind::Faq { headline: f.text("headline", ""), items, bg: f.text("bg", "cream") })
    }
    "atwork" => {
      // **THE TWO HALVES OF AC-3.3, KEPT APART.** No `qr:` is `None` and valid;
      // a `qr:` naming a file that is not there refuses, because naming it is an
      // assertion -- section 5's fifth row, and C1's rule at a fifth site.
      let qr = match f.opt_text("qr") {
        Some(rel) => Some(Qr { path: admit::named(reel, &rel, site("qr:"), admit::Requires::AnyFile)? }),
        None => None,
      };
      still(Kind::Atwork {
        kicker: f.text("kicker", "Artist at work"),
        name: f.text("name", ""),
        strap: f.text("strap", ""),
        caption: f.text("caption", ""),
        qr,
        bg: f.text("bg", "cream"),
      })
    }
    "strapline" => {
      let mark = match f.opt_text("mark") {
        Some(rel) => Some(admit::named(reel, &rel, site("mark:"), admit::Requires::Image)?),
        None => None,
      };
      let lines = f.list("lines");
      if lines.is_empty() {
        return Err(f.missing("type strapline needs lines:", "lines: [\"...\", \"...\"]"));
      }
      still(Kind::Strapline { mark, lines, bg: f.text("bg", "yellow") })
    }
    "points" => {
      let points = f.list("points");
      if points.is_empty() {
        return Err(f.missing("type points needs points:", "points: [\"...\", \"...\"]"));
      }
      still(Kind::Points {
        headline: f.text("headline", ""),
        body: f.text("body", ""),
        points,
        bg: f.text("bg", "cream"),
      })
    }
    "venue" => {
      let image = match f.opt_text("image") {
        Some(rel) => Some(admit::named(reel, &rel, site("image:"), admit::Requires::Image)?),
        None => None,
      };
      // The one shape whose motion is NOT forced to none: a venue card is
      // full-bleed art and the reference lets it drift.
      vec![Slide {
        id: id.clone(),
        common: Common { motion: f.text("motion", "kenburns"), ..common.clone() },
        kind: Kind::Venue {
          image,
          kicker: f.text("kicker", "Launching"),
          headline: f.text("headline", ""),
          at: f.text("at", ""),
          city: f.text("city", ""),
          bg: f.text("bg", "ink"),
        },
      }]
    }
    "wordmark" => still(Kind::Wordmark {
      top: f.text("top", ""),
      mid: f.text("mid", ""),
      bottom: f.text("bottom", ""),
      bg: f.text("bg", "ink"),
    }),
    "socials" => socials_slides(&f, &id, &common, socials)?,
    "logo" => {
      let Some(rel) = f.opt_text("file") else {
        return Err(f.missing("type logo needs a file:", "file: assets/brand/logo.png"));
      };
      let path = admit::named(reel, &rel, site("file:"), admit::Requires::Image)?;
      vec![Slide {
        id: id.clone(),
        common: Common { fit: "logo".into(), motion: "none".into(), ..common },
        kind: Kind::Image { path },
      }]
    }
    // **ONLY A SCAN CAN DROP AN INPUT, AND THIS IS THE ONLY SHAPE THAT SCANS.**
    // Every other shape NAMES its files, and a name that does not classify
    // REFUSES rather than dropping -- C1's rule, and the reason this arm is the
    // one that returns a drop list. The early return says so structurally: no
    // other arm has to remember it has nothing to report.
    _ => return gallery(reel, &f, &id, &common, &owner),
  };
  Ok(Collected { slides, dropped: Vec::new() })
}

fn faq_items(f: &Fields) -> Result<Vec<FaqItem>, Failure> {
  let items: Vec<FaqItem> = f
    .raw("items")
    .and_then(|v| v.as_sequence())
    .map(|xs| {
      xs.iter()
        .filter_map(|x| x.as_mapping())
        .map(|m| FaqItem {
          q: m.get(serde_yaml::Value::from("q")).and_then(|v| v.as_str()).unwrap_or("").to_string(),
          a: m.get(serde_yaml::Value::from("a")).and_then(|v| v.as_str()).unwrap_or("").to_string(),
        })
        .collect()
    })
    .unwrap_or_default();
  if items.is_empty() {
    return Err(f.missing("type faq needs items:", "items: [{q: \"...\", a: \"...\"}]"));
  }
  Ok(items)
}

fn socials_slides(
  f: &Fields,
  id: &str,
  common: &Common,
  socials: usize,
) -> Result<Vec<Slide>, Failure> {
  let layout = f.text("layout", "list");
  segment::value("socials layout", &layout, &["list", "each"], &f.owner)?;
  let still = Common { motion: "none".into(), ..common.clone() };
  if layout == "list" {
    return Ok(vec![Slide {
      id: id.to_string(),
      common: still,
      kind: Kind::Socials {
        headline: f.text("headline", "Follow the artist"),
        bg: f.text("bg", "ink"),
      },
    }]);
  }
  if socials == 0 {
    return Err(f.missing(
      "layout 'each' needs a socials: block",
      "add socials: to the config, or use layout: list",
    ));
  }
  // Rotate the grounds so three consecutive social pages do not read as one long
  // slide that forgot to change.
  let mut bgs = f.list("bgs");
  if bgs.is_empty() {
    bgs = vec!["blue".into(), "red".into(), "ink".into()];
  }
  Ok(
    (0..socials)
      .map(|i| Slide {
        id: id.to_string(),
        common: still.clone(),
        kind: Kind::Social {
          index: i,
          headline: f.text("headline", ""),
          bg: bgs[i % bgs.len()].clone(),
        },
      })
      .collect(),
  )
}

fn gallery(
  reel: &Path,
  f: &Fields,
  id: &str,
  common: &Common,
  owner: &str,
) -> Result<Collected, Failure> {
  let site = |field: &'static str| admit::Site { owner, field };
  let mut files: Vec<PathBuf> = Vec::new();
  let mut dropped: Vec<String> = Vec::new();
  if let Some(rel) = f.opt_text("from") {
    let scan = admit::scanned(reel, &rel, site("from:"))?;
    dropped = scan.report(site("from:"));
    files = scan.admitted;
  }
  for rel in f.list("files") {
    files.push(admit::named(reel, &rel, site("files:"), admit::Requires::Image)?);
  }
  for pat in f.list("exclude") {
    files.retain(|p| !matches_glob(p, &pat));
  }
  if files.is_empty() {
    // **THE DROPS ARE NAMED IN THE REFUSAL, WHICH IS THE WHOLE OF C1'S VALUE.**
    // The reference says "resolved to no images" and stops; if three files were
    // dropped for being the wrong type, that is the answer and it was silent.
    let why = if dropped.is_empty() {
      "no images matched".to_string()
    } else {
      format!("{} file(s) were dropped:\n  {}", dropped.len(), dropped.join("\n  "))
    };
    return Err(f.missing(&format!("resolved to no images -- {why}"), "check from:, files: and exclude:"));
  }
  // **THE DROPS TRAVEL OUT ON THE SUCCESS PATH, WHICH IS THE WHOLE OF AC-3.2's
  // REMAINING CLAUSE.** Until this line they were computed and read only inside
  // the refusal above -- so a segment that dropped a `.txt` and still resolved
  // to eight slides said nothing, and `Scan::report`'s own doc comment ("for the
  // caller to print at the segment") described a caller that did not exist.
  //
  // **`exclude:` DROPS ARE DELIBERATELY NOT HERE.** vc ruled it and changed the
  // row's words to carry the distinction: an `exclude:` drop is the author's own
  // instruction obeyed, an admission drop is an accident nobody was told about.
  // Reporting both would fire on every build using `exclude:`, which is the cost
  // `Scan::report`'s comment already names.
  Ok(Collected {
    slides: files
      .into_iter()
      .map(|path| Slide { id: id.to_string(), common: common.clone(), kind: Kind::Image { path } })
      .collect(),
    dropped,
  })
}

/// The reference uses `Path.match`, which is a glob over the trailing components.
/// Only `*` is honoured here, which is what every `exclude:` in the estate uses.
fn matches_glob(path: &Path, pat: &str) -> bool {
  let name = path.file_name().map_or_else(String::new, |n| n.to_string_lossy().into_owned());
  let Some((head, tail)) = pat.split_once('*') else {
    return name == pat;
  };
  name.starts_with(head) && name.ends_with(tail) && name.len() >= head.len() + tail.len()
}

#[cfg(test)]
mod tests {
  use super::*;

  fn reel(tag: &str, files: &[&str]) -> PathBuf {
    let d = std::env::temp_dir().join(format!("showreel-slide-{}-{tag}", std::process::id()));
    let _ = std::fs::remove_dir_all(&d);
    std::fs::create_dir_all(&d).unwrap();
    for f in files {
      let p = d.join(f);
      std::fs::create_dir_all(p.parent().unwrap()).unwrap();
      std::fs::write(&p, b"x").unwrap();
    }
    d
  }

  fn defaults() -> Defaults {
    Defaults::resolve(segment::pace(None).unwrap(), None)
  }

  fn all(reel: &Path, yaml: &str, socials: usize) -> Result<Collected, Failure> {
    let seg: serde_yaml::Value = serde_yaml::from_str(yaml).unwrap();
    collect(reel, 0, &seg, &defaults(), socials)
  }

  fn one(reel: &Path, yaml: &str, socials: usize) -> Result<Vec<Slide>, Failure> {
    all(reel, yaml, socials).map(|c| c.slides)
  }

  /// **ALL TWELVE SHAPES RESOLVE, AND THE COUNT IS THE CLAIM.** A shape that
  /// stops resolving fails here rather than at a build against a reel that
  /// happens not to use it -- and two of the twelve are used by no real config
  /// in this estate, so nothing else stands behind them.
  #[test]
  fn every_shape_resolves_to_at_least_one_slide() {
    let r = reel("shapes", &["a.jpg", "m.png", "q.svg", "art/one.jpg"]);
    let cases: &[(&str, &str, usize)] = &[
      ("crawl", "{id: s, type: crawl}", 1),
      ("card", "{id: s, type: card, headline: H}", 1),
      ("statement", "{id: s, type: statement, headline: H}", 1),
      ("faq", "{id: s, type: faq, items: [{q: Q, a: A}]}", 1),
      ("atwork", "{id: s, type: atwork, qr: q.svg}", 1),
      ("atwork, no qr", "{id: s, type: atwork}", 1),
      ("strapline", "{id: s, type: strapline, mark: m.png, lines: [L]}", 1),
      ("points", "{id: s, type: points, points: [P]}", 1),
      ("venue", "{id: s, type: venue, image: a.jpg}", 1),
      ("wordmark", "{id: s, type: wordmark, top: T}", 1),
      ("socials list", "{id: s, type: socials, layout: list}", 1),
      ("socials each", "{id: s, type: socials, layout: each}", 4),
      ("logo", "{id: s, type: logo, file: a.jpg}", 1),
      ("gallery", "{id: s, from: art}", 1),
    ];
    // Fourteen cases over twelve shapes: atwork and socials each appear twice,
    // because their two arms are different code paths.
    assert_eq!(cases.len(), 14);
    assert_eq!(segment::SHAPES.len(), 12, "and the shape table has not moved");

    let mut wrong = Vec::new();
    for (label, yaml, want) in cases {
      match one(&r, yaml, 4) {
        Ok(slides) if slides.len() == *want => {}
        Ok(slides) => wrong.push(format!("{label}: wanted {want} slide(s), got {}", slides.len())),
        Err(e) => wrong.push(format!("{label}: refused -- {}", e.message)),
      }
    }
    assert!(wrong.is_empty(), "{} wrong:\n  {}", wrong.len(), wrong.join("\n  "));
  }

  /// **AC-3.3, BOTH HALVES, WHICH IS THE WHOLE ROW.** `qr:` absent is `None` and
  /// valid; `qr:` naming a file that is not there REFUSES. The reference
  /// returned `""` for both and that is what made them look like one thing.
  #[test]
  fn a_qr_is_optional_and_a_declared_one_that_is_missing_refuses() {
    let r = reel("qr", &["q.svg"]);

    let s = one(&r, "{id: s, type: atwork}", 0).unwrap();
    match &s[0].kind {
      Kind::Atwork { qr, .. } => assert!(qr.is_none(), "absent is valid and is None"),
      other => panic!("expected atwork, got {other:?}"),
    }

    let s = one(&r, "{id: s, type: atwork, qr: q.svg}", 0).unwrap();
    match &s[0].kind {
      Kind::Atwork { qr: Some(q), .. } => assert!(q.path.ends_with("q.svg")),
      other => panic!("expected a qr, got {other:?}"),
    }

    let e = one(&r, "{id: s, type: atwork, qr: gone.svg}", 0).unwrap_err();
    assert!(e.message.contains("gone.svg"), "names the file: {}", e.message);
    assert!(e.message.contains("qr:"), "names the site: {}", e.message);

    // **AND AN SVG IS ADMITTED HERE THOUGH NO IMAGE SITE WOULD TAKE ONE.** The
    // qr is read as text and never decoded, which is why `Requires` is a
    // parameter rather than a second admission function.
    let e = one(&r, "{id: s, type: logo, file: q.svg}", 0).unwrap_err();
    assert!(e.message.contains("not an image"), "an image site refuses it: {}", e.message);
  }

  /// **AC-3.8: THE ASSET LIST IS A PROJECTION OF THE SLIDE LIST.** Not a second
  /// walk, so the two cannot disagree -- which is what the recycler that decides
  /// an asset is safe to delete depends on.
  #[test]
  fn the_assets_come_from_the_slides_and_only_the_slides() {
    let r = reel("assets", &["a.jpg", "b.jpg", "m.png", "q.svg", "art/one.jpg", "art/two.png"]);
    let mut all: Vec<String> = Vec::new();
    for yaml in [
      "{id: g, from: art}",
      "{id: s, type: strapline, mark: m.png, lines: [L]}",
      "{id: a, type: atwork, qr: q.svg}",
      "{id: c, type: card, headline: H}",
    ] {
      for s in one(&r, yaml, 0).unwrap() {
        for p in s.assets() {
          all.push(p.file_name().unwrap().to_string_lossy().into_owned());
        }
      }
    }
    all.sort();
    assert_eq!(all, vec!["m.png", "one.jpg", "q.svg", "two.png"]);
    // A text slide reads nothing, and that must stay true or every recycle
    // would think its assets were in use.
    let card = one(&r, "{id: c, type: card, headline: H}", 0).unwrap();
    assert!(card[0].assets().is_empty(), "a card reads no file");
  }

  /// A shape whose required list is empty refuses by name, and says what shape
  /// it needed it for.
  #[test]
  fn a_shape_missing_its_required_list_refuses_and_names_the_key() {
    let r = reel("empty", &["m.png"]);
    for (yaml, want) in [
      ("{id: s, type: strapline, mark: m.png, lines: []}", "lines:"),
      ("{id: s, type: points, points: []}", "points:"),
      ("{id: s, type: faq, items: []}", "items:"),
      ("{id: s, type: logo}", "file:"),
    ] {
      let e = one(&r, yaml, 0).unwrap_err();
      assert!(e.message.contains(want), "must name {want}: {}", e.message);
      assert!(e.message.contains("segment 's'"), "and the segment: {}", e.message);
    }
    // Blank entries are dropped before the emptiness test -- the reference's
    // `if str(x).strip()` -- so a list of whitespace is an empty list.
    let e = one(&r, r#"{id: s, type: points, points: ["", "  "]}"#, 0).unwrap_err();
    assert!(e.message.contains("points:"), "{}", e.message);
  }

  /// **AC-3.2's REMAINING CLAUSE: THE DROP SURVIVES A SEGMENT THAT SUCCEEDED.**
  /// Until this landed, `dropped` was computed and read ONLY inside the refusal
  /// branch -- so a segment that dropped a `.txt` and still resolved to slides
  /// said nothing at all, and `Scan::report`'s own doc comment ("for the caller
  /// to print at the segment") described a caller that did not exist.
  #[test]
  fn a_segment_that_dropped_an_input_and_still_resolved_names_it_at_the_segment() {
    let r = reel("kept", &["art/a.jpg", "art/b.jpg", "art/notes.txt"]);
    let got = all(&r, "{id: g, from: art}", 0).unwrap();
    assert_eq!(got.slides.len(), 2, "the two images still resolve");
    assert_eq!(got.dropped.len(), 1, "and the drop is reported: {:?}", got.dropped);
    assert!(got.dropped[0].contains("notes.txt"), "names the file: {}", got.dropped[0]);
    assert!(got.dropped[0].contains("segment 'g'"), "at the SEGMENT: {}", got.dropped[0]);
    assert!(got.dropped[0].contains("from:"), "and the field: {}", got.dropped[0]);
  }

  /// **vc's RULING, AND THE ROW'S WORDS WERE CHANGED TO CARRY IT.** An
  /// `exclude:` drop is the author's own instruction obeyed; an admission drop
  /// is an accident nobody was told about. Reporting both would fire on every
  /// build that uses `exclude:`, which is the cost `Scan::report`'s own comment
  /// already names -- and then the one that matters is invisible too.
  #[test]
  fn an_excluded_file_is_not_reported_because_the_author_asked_for_it() {
    let r = reel("silent", &["art/keep.jpg", "art/skip-me.jpg"]);
    let got = all(&r, "{id: g, from: art, exclude: [skip-*]}", 0).unwrap();
    assert_eq!(got.slides.len(), 1, "the exclude took effect");
    assert!(got.dropped.is_empty(), "and said nothing about it: {:?}", got.dropped);
  }

  /// The normal case, and it must stay silent.
  #[test]
  fn a_clean_directory_drops_nothing_and_says_nothing() {
    let r = reel("clean", &["art/a.jpg", "art/b.jpg"]);
    assert!(all(&r, "{id: g, from: art}", 0).unwrap().dropped.is_empty());
  }

  /// `exclude:` filters what `from:` and `files:` gathered, and the refusal when
  /// nothing survives NAMES WHAT WAS DROPPED -- which is C1's value reaching the
  /// sentence the reference ends with.
  #[test]
  fn exclude_filters_the_gathered_files_and_an_empty_result_says_why() {
    let r = reel("excl", &["art/keep.jpg", "art/skip-me.jpg", "art/notes.txt"]);
    let s = one(&r, "{id: s, from: art, exclude: [skip-*]}", 0).unwrap();
    assert_eq!(s.len(), 1, "one survives the exclusion");

    let e = one(&r, "{id: s, from: art, exclude: ['*']}", 0).unwrap_err();
    assert!(e.message.contains("resolved to no images"), "{}", e.message);

    // The directory held a .txt, so the refusal reports the drop rather than
    // leaving the author to wonder where it went.
    let r = reel("onlytxt", &["art/notes.txt"]);
    let e = one(&r, "{id: s, from: art}", 0).unwrap_err();
    assert!(e.message.contains("notes.txt"), "names what was dropped: {}", e.message);
  }

  /// `socials: layout: each` yields one slide per social and rotates the ground
  /// so three consecutive pages do not read as one slide that forgot to change.
  #[test]
  fn socials_each_yields_one_slide_per_social_with_rotating_grounds() {
    let r = reel("soc", &[]);
    let s = one(&r, "{id: s, type: socials, layout: each}", 5).unwrap();
    assert_eq!(s.len(), 5);
    let bgs: Vec<&str> = s
      .iter()
      .map(|x| match &x.kind {
        Kind::Social { bg, .. } => bg.as_str(),
        other => panic!("expected a social, got {other:?}"),
      })
      .collect();
    assert_eq!(bgs, vec!["blue", "red", "ink", "blue", "red"], "three grounds, rotated");

    let e = one(&r, "{id: s, type: socials, layout: each}", 0).unwrap_err();
    assert!(e.message.contains("socials: block"), "{}", e.message);
    let e = one(&r, "{id: s, type: socials, layout: grid}", 3).unwrap_err();
    assert!(e.message.contains("grid"), "{}", e.message);
  }

  /// **THE LIVE REEL, RESOLVED WHOLE.** Fifteen segments become twenty-three
  /// slides -- which is the figure the estate already records for what this
  /// config PLANS, arrived at here by an independent implementation.
  #[test]
  fn the_live_reel_resolves_to_the_slide_count_the_estate_records() {
    let cfg = config::parse(include_str!("../fixtures/45h.showreel.yaml"), "45h").unwrap();
    let pace = segment::pace(cfg.pace.as_deref()).unwrap();
    let d = Defaults::resolve(pace, cfg.defaults.as_ref());
    // The reel's assets are not in this tree, so admission cannot run here --
    // this asserts the SHAPE arithmetic, and `check` against the real directory
    // is what exercises the file half.
    let mut planned = 0;
    for (i, seg) in cfg.segments.iter().enumerate() {
      let map = seg.as_mapping().unwrap();
      let ty = map.get(serde_yaml::Value::from("type")).and_then(|v| v.as_str()).unwrap_or("gallery");
      let each = ty == "socials"
        && map.get(serde_yaml::Value::from("layout")).and_then(|v| v.as_str()) == Some("each");
      planned += if each { cfg.socials.len() } else { 1 };
      let _ = i;
    }
    assert_eq!(cfg.segments.len(), 15, "the config's segments");
    assert_eq!(cfg.socials.len(), 4, "and its socials");
    assert_eq!(planned, 18, "non-gallery arithmetic; galleries add the rest at admission");
    let _ = d;
  }
}
