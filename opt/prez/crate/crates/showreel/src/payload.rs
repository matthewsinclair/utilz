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

use crate::{admit, config, limits, normalise, plan, slide};
use artifact::Failure;
use serde::Serialize;
use serde_json::{Map, Value};
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

/// Every slide, as the artifact carries it.
///
/// **THE EMITTER IS EXPLICIT RATHER THAN DERIVED, AND design.md 4.8 IS WHY.**
/// A `Serialize` on `Slide` would emit FOUR keys the reference has none of.
/// Two are the ones the reference itself removes -- `s.pop("path")` and
/// `s.pop("asset")` at `showreel:993-994` -- and **two are this port's own**:
/// `Slide::id`, threaded through so every refusal can name its owner, and
/// `Common::clamped`, whether the timing envelope moved a duration. The
/// reference has no `id` on a slide at all (its `sid` is a local that reaches
/// only `die()`), so **porting exactly the two pops it names would still have
/// leaked two keys** -- a divergence introduced by faithfully copying the fix
/// for a different one. Listing what goes IN cannot fail that way.
///
/// **THE TARGET COMES FROM THE CONFIG, AND THE ARGUMENT TYPE IS WHAT ENFORCES
/// IT.** Taking `&config::Reel` rather than a `u32` is the same control as
/// `stamp::producer`: a caller holding a number can pass `normalise::TARGET` by
/// mistake, and **no reel in this tree would catch it** -- 45h and the pinned
/// fixture both set `target: 1920`, which IS the constant. This is where
/// `Reel::embed_target` acquires its caller.
pub fn slides(cfg: &config::Reel, slides: &[slide::Slide]) -> Result<Vec<Value>, Failure> {
  let target = cfg.embed_target();
  slides.iter().map(|s| row(s, target)).collect()
}

/// One slide row: the five rendering fields, `kind`, and the variant's own keys.
fn row(s: &slide::Slide, target: u32) -> Result<Value, Failure> {
  let mut m = Map::new();
  let c = &s.common;
  m.insert("dwell".into(), c.dwell_ms.into());
  m.insert("ease".into(), c.ease_ms.into());
  m.insert("transition".into(), c.transition.clone().into());
  m.insert("fit".into(), c.fit.clone().into());
  m.insert("motion".into(), c.motion.clone().into());
  variant(&mut m, &s.kind, target)?;
  Ok(Value::Object(m))
}

/// The `kind` discriminator and the keys that come with it.
///
/// **`logo` IS NOT A TWELFTH SHAPE**: it is `kind: "image"` with `fit` forced to
/// `"logo"`, resolved before this sees it, so it needs no arm of its own.
fn variant(m: &mut Map<String, Value>, kind: &slide::Kind, target: u32) -> Result<(), Failure> {
  let mut put = |k: &str, v: Value| {
    m.insert(k.to_string(), v);
  };
  match kind {
    slide::Kind::Crawl { source } => {
      put("kind", "crawl".into());
      put("crawl", source.clone().into());
    }
    slide::Kind::Card { headline, sub, bg } => {
      put("kind", "card".into());
      put("headline", headline.clone().into());
      put("sub", sub.clone().into());
      put("bg", bg.clone().into());
    }
    slide::Kind::Statement { kicker, headline, body, bg } => {
      put("kind", "statement".into());
      put("kicker", kicker.clone().into());
      put("headline", headline.clone().into());
      put("body", body.clone().into());
      put("bg", bg.clone().into());
    }
    slide::Kind::Faq { headline, items, bg } => {
      put("kind", "faq".into());
      put("headline", headline.clone().into());
      let rows: Vec<Value> = items
        .iter()
        .map(|i| {
          let mut o = Map::new();
          o.insert("q".into(), i.q.clone().into());
          o.insert("a".into(), i.a.clone().into());
          Value::Object(o)
        })
        .collect();
      put("items", Value::Array(rows));
      put("bg", bg.clone().into());
    }
    slide::Kind::Atwork { kicker, name, strap, caption, qr, bg } => {
      put("kind", "atwork".into());
      put("kicker", kicker.clone().into());
      put("name", name.clone().into());
      put("strap", strap.clone().into());
      put("caption", caption.clone().into());
      put("qr", qr_text(qr.as_ref())?.into());
      put("bg", bg.clone().into());
    }
    slide::Kind::Strapline { mark, lines, bg } => {
      put("kind", "strapline".into());
      put("mark", inline(mark.as_deref(), target, normalise::Role::Mark)?.into());
      put("lines", Value::Array(lines.iter().map(|l| l.clone().into()).collect()));
      put("bg", bg.clone().into());
    }
    slide::Kind::Points { headline, body, points, bg } => {
      put("kind", "points".into());
      put("headline", headline.clone().into());
      put("body", body.clone().into());
      put("points", Value::Array(points.iter().map(|p| p.clone().into()).collect()));
      put("bg", bg.clone().into());
    }
    slide::Kind::Venue { image, kicker, headline, at, city, bg } => {
      put("kind", "venue".into());
      put("src", inline(image.as_deref(), target, normalise::Role::Slide)?.into());
      put("kicker", kicker.clone().into());
      put("headline", headline.clone().into());
      put("at", at.clone().into());
      put("city", city.clone().into());
      put("bg", bg.clone().into());
    }
    slide::Kind::Wordmark { top, mid, bottom, bg } => {
      put("kind", "wordmark".into());
      put("top", top.clone().into());
      put("mid", mid.clone().into());
      put("bottom", bottom.clone().into());
      put("bg", bg.clone().into());
    }
    slide::Kind::Socials { headline, bg } => {
      put("kind", "socials".into());
      put("headline", headline.clone().into());
      put("bg", bg.clone().into());
    }
    slide::Kind::Social { index, headline, bg } => {
      put("kind", "social".into());
      put("index", (*index).into());
      put("headline", headline.clone().into());
      put("bg", bg.clone().into());
    }
    slide::Kind::Image { path } => {
      let e = normalise::embed(path, target, normalise::Role::Slide)?;
      let name = path.file_name().and_then(std::ffi::OsStr::to_str).ok_or_else(|| {
        Failure::new(
          format!("slide image: {} has no usable filename", path.display()),
          "the payload carries the file's name; rename it to plain text",
        )
      })?;
      put("kind", "image".into());
      put("src", e.uri.into());
      put("w", e.width.into());
      put("h", e.height.into());
      put("name", name.to_string().into());
    }
  }
  Ok(())
}

/// A picture embedded in place, or `""` when the segment named none.
///
/// **THE EMPTY STRING IS THE REFERENCE'S OWN VALUE AND IT IS DELIBERATE HERE.**
/// `venue` and `strapline` initialise `src`/`mark` to `""` and only overwrite it
/// when the segment named a file, so **the key is present either way** and the
/// player's `if (s.src)` reads it as absent. Skipping the key instead would
/// report as a structural difference on every such slide.
///
/// **AND THIS IS THE ONE PLACE `w`/`h` ARE NOT ADDED ALONGSIDE `src`.** The
/// reference's dimensions come from `cmd_build`'s `if s.get("path")` block, and
/// a `venue` slide has no `path` -- it embedded its own image a function
/// earlier. So two kinds carry `src` by two different routes and only `image`
/// carries the size with it. design.md 4.8, trap (1).
fn inline(path: Option<&Path>, target: u32, role: normalise::Role) -> Result<String, Failure> {
  match path {
    None => Ok(String::new()),
    Some(p) => Ok(normalise::embed(p, target, role)?.uri),
  }
}

/// An `atwork` QR as the payload carries it: the SVG's own text, or `""`.
///
/// **`Option<Qr>` STOPS AT THIS BOUNDARY, ON PURPOSE.** AC-3.3 carries QR
/// absence as a type because absent and declared-but-missing are different facts
/// and the reference returned `""` for both. That distinction has already done
/// its work by the time a payload is built -- the missing one refused at
/// admission -- and **`skip_serializing_if` here would be the natural Rust
/// spelling and a structural divergence**: `compare_structure` would report `qr`
/// against every atwork slide without one. So `None` emits `""`, which is where
/// this port and the reference agree again.
///
/// **AND IT IS THE SVG's TEXT, NOT A DATA URI** -- `load_qr` is a bare
/// `p.read_text()` (`showreel:746-755`). The markup goes into the page inline.
fn qr_text(qr: Option<&slide::Qr>) -> Result<String, Failure> {
  match qr {
    None => Ok(String::new()),
    Some(q) => std::fs::read_to_string(&q.path).map_err(|e| {
      Failure::new(
        format!("atwork qr: cannot read {}: {e}", q.path.display()),
        "the segment declares a qr:; make it readable or drop the key",
      )
    }),
  }
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

  /// A real picture, because the emitter DECODES where `slide::collect` only
  /// admits. 2000x1000 so the two targets below land on different sizes.
  fn png(dir: &Path, name: &str) {
    let img = image::RgbImage::from_fn(2000, 1000, |x, _| image::Rgb([(x % 256) as u8, 1, 2]));
    image::DynamicImage::ImageRgb8(img).save(dir.join(name)).unwrap();
  }

  fn rows(dir: &Path, yaml: &str, socials: usize, target: &str) -> Vec<Value> {
    let seg: serde_yaml::Value = serde_yaml::from_str(yaml).unwrap();
    let d = slide::Defaults::resolve(crate::segment::pace(None).unwrap(), None);
    let c = slide::collect(dir, 0, &seg, &d, socials).unwrap();
    slides(&cfg(&format!("artist: {{handle: x}}\n{target}")), &c.slides).unwrap()
  }

  fn keys(v: &Value) -> Vec<String> {
    let mut k: Vec<String> = v.as_object().unwrap().keys().cloned().collect();
    k.sort();
    k
  }

  fn sorted(extra: &[&str]) -> Vec<String> {
    let mut k: Vec<String> = ["dwell", "ease", "transition", "fit", "motion", "kind"]
      .iter()
      .chain(extra.iter())
      .map(|s| (*s).to_string())
      .collect();
    k.sort();
    k
  }

  /// **THE KEY SET PER KIND, ASSERTED AS EQUALITY SO AN EXTRA KEY FAILS TOO.**
  /// The table is transcribed from design.md 4.8, which took it from
  /// `collect_segment` and from the JSON of an artifact the REFERENCE built --
  /// two readings that agree. Equality rather than containment is the whole
  /// point: **`id`, `clamped`, `path` and `asset` are what a derived emitter
  /// would add**, and only an exact set can see a key that should not be there.
  #[test]
  fn every_slide_kind_emits_exactly_the_reference_key_set() {
    let r = reel("kinds", &[("q.svg", "<svg/>"), ("art/.keep", "")]);
    png(&r, "a.png");
    png(&r, "art/one.png");
    let cases: &[(&str, &str, usize, &[&str])] = &[
      ("{id: s, type: crawl}", "crawl", 1, &["crawl"]),
      ("{id: s, type: card, headline: H}", "card", 1, &["headline", "sub", "bg"]),
      ("{id: s, type: statement}", "statement", 1, &["kicker", "headline", "body", "bg"]),
      ("{id: s, type: faq, items: [{q: Q, a: A}]}", "faq", 1, &["headline", "items", "bg"]),
      (
        "{id: s, type: atwork, qr: q.svg}",
        "atwork",
        1,
        &["kicker", "name", "strap", "caption", "qr", "bg"],
      ),
      ("{id: s, type: atwork}", "atwork", 1, &["kicker", "name", "strap", "caption", "qr", "bg"]),
      ("{id: s, type: strapline, mark: a.png, lines: [L]}", "strapline", 1, &["mark", "lines", "bg"]),
      ("{id: s, type: strapline, lines: [L]}", "strapline", 1, &["mark", "lines", "bg"]),
      ("{id: s, type: points, points: [P]}", "points", 1, &["headline", "body", "points", "bg"]),
      (
        "{id: s, type: venue, image: a.png}",
        "venue",
        1,
        &["src", "kicker", "headline", "at", "city", "bg"],
      ),
      ("{id: s, type: venue}", "venue", 1, &["src", "kicker", "headline", "at", "city", "bg"]),
      ("{id: s, type: wordmark, top: T}", "wordmark", 1, &["top", "mid", "bottom", "bg"]),
      ("{id: s, type: socials, layout: list}", "socials", 1, &["headline", "bg"]),
      ("{id: s, type: socials, layout: each}", "social", 2, &["index", "headline", "bg"]),
      ("{id: s, type: logo, file: a.png}", "image", 1, &["src", "w", "h", "name"]),
      ("{id: s, from: art}", "image", 1, &["src", "w", "h", "name"]),
    ];
    for (yaml, kind, socials, extra) in cases {
      for row in rows(&r, yaml, *socials, "") {
        assert_eq!(row["kind"], Value::from(*kind), "{yaml}");
        assert_eq!(keys(&row), sorted(extra), "{yaml} -- id/clamped/path/asset leak here");
      }
    }
    assert_eq!(cases.len(), 16, "sixteen cases over twelve shapes");
  }

  /// **`venue` CARRIES `src` AND NOT THE DIMENSIONS, AND `image` CARRIES BOTH.**
  /// design.md 4.8 trap (1): the two kinds reach `src` by different routes and
  /// the reference adds `w`/`h`/`name` only where a `path` survived into
  /// `cmd_build`. Asserted as a pair so the natural "every picture gets
  /// src/w/h/name" rule cannot pass.
  ///
  /// **AND THE HARNESS IS BLIND TO HALF OF WHAT THIS TEST HOLDS, SO THIS TEST IS
  /// THE ONLY THING OVER IT.** `signature()` builds each row as
  /// `{k: v for k, v in s.items() if k != "src"}` -- **the `src` key is stripped
  /// entirely** before `compare_structure` sees anything. So a venue slide
  /// GAINING `w`/`h`/`name` is caught downstream, and a venue slide LOSING `src`
  /// is invisible to the instrument and reaches a shop as a blank panel.
  ///
  /// **THE EXCLUSION IS DELIBERATE AND IT IS DOING AN UNDECLARED SECOND JOB.**
  /// `signature`'s own docstring calls itself *"everything about every slide
  /// EXCEPT the pixels"*, and `src` is dropped because it IS pixels -- a sound
  /// reason that also, silently, removes the only evidence that the key was
  /// there at all. Named by vc, 2026-09-10. It is the same narrowing this thread
  /// keeps finding, this time in the reference harness rather than in either
  /// port.
  #[test]
  fn a_venue_picture_is_a_src_alone_where_a_slide_picture_carries_its_size() {
    let r = reel("venue-vs-image", &[("art/.keep", "")]);
    png(&r, "a.png");
    png(&r, "art/one.png");
    let v = &rows(&r, "{id: s, type: venue, image: a.png}", 1, "")[0];
    assert!(v["src"].as_str().unwrap().starts_with("data:"), "the venue image IS embedded");
    assert!(v.get("w").is_none() && v.get("h").is_none() && v.get("name").is_none());
    let i = &rows(&r, "{id: s, from: art}", 1, "")[0];
    assert_eq!(i["w"], Value::from(1920));
    assert_eq!(i["name"], Value::from("one.png"));
  }

  /// **AN ABSENT PICTURE IS AN EMPTY STRING, NOT AN ABSENT KEY.** The reference
  /// initialises `src`/`mark` to `""` and overwrites only when the segment named
  /// a file, so the key is there either way. `skip_serializing_if` is the
  /// natural Rust spelling and would report against every such slide.
  #[test]
  fn a_segment_that_names_no_picture_still_carries_the_key_as_an_empty_string() {
    let r = reel("empty-src", &[]);
    assert_eq!(rows(&r, "{id: s, type: venue}", 1, "")[0]["src"], Value::from(""));
    assert_eq!(rows(&r, "{id: s, type: strapline, lines: [L]}", 1, "")[0]["mark"], Value::from(""));
    assert_eq!(rows(&r, "{id: s, type: atwork}", 1, "")[0]["qr"], Value::from(""));
  }

  /// **`qr` IS THE SVG's OWN TEXT, NOT A DATA URI** -- `load_qr` is a bare
  /// `read_text` and the markup goes inline.
  #[test]
  fn an_atwork_qr_carries_the_svg_source_rather_than_a_data_uri() {
    let r = reel("qr-text", &[("q.svg", "<svg id='mine'/>")]);
    let q = rows(&r, "{id: s, type: atwork, qr: q.svg}", 1, "")[0]["qr"].clone();
    assert_eq!(q, Value::from("<svg id='mine'/>"));
  }

  /// **THE EMBED SIZE COMES FROM THE CONFIG, NOT FROM `normalise::TARGET`.**
  /// Asserted at **640**, a value no constant in this crate holds: 45h and the
  /// pinned fixture both set `target: 1920`, which IS the constant, so a build
  /// reading the constant instead of the config passes on every reel in this
  /// tree. This is the only place that difference is observable.
  #[test]
  fn the_embed_size_follows_the_reels_target_and_not_the_compiled_default() {
    let r = reel("target", &[("art/.keep", "")]);
    png(&r, "art/one.png");
    assert_eq!(rows(&r, "{id: s, from: art}", 1, "target: 640\n")[0]["w"], Value::from(640));
    assert_eq!(rows(&r, "{id: s, from: art}", 1, "")[0]["w"], Value::from(1920));
    assert_eq!(normalise::TARGET, 1920, "and the default is what the bare case fell back to");
  }

}
