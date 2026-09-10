//! The build: a reel directory to one self-contained artifact.
//!
//! **THIS LIVES IN THE LIBRARY AND NOT IN `main.rs`, AND THE REASON IS THE
//! REASON THE CRATE HAS A LIBRARY AT ALL.** Orchestration inside a binary is
//! unreachable from a test -- the only way to exercise it is to run the process
//! and read its stdout, which grades the printing rather than the work. So the
//! verb returns a `Built` saying what happened and `main.rs` prints it:
//! `IN-AG-THIN-COORD-001` with the coordinator on the outside where it belongs.
//!
//! **AND THE WARNINGS ARE THE REASON IT MATTERS HERE MORE THAN ELSEWHERE.** This
//! port turned every warning from a print at the site into a return value, which
//! is what lets a test read them -- and the cost is that **a returned warning
//! nobody drains is silent and nothing fails.** design.md 4.9 censuses the six
//! sources; three of them have no consumer anywhere but here. A build that
//! quietly stopped reporting stale QRs would pass every gate in this crate.

use crate::{config, deliver, payload, plan, stamp, template, theme};
use artifact::Failure;
use serde_json::{json, Map, Value};
use std::path::{Path, PathBuf};

/// Resolve a reel directory the way the reference does: the directory itself, or
/// a `showreel/` beneath it.
pub fn resolve(path: &Path) -> PathBuf {
  if path.file_name().is_some_and(|n| n == "showreel") || !path.join("showreel").is_dir() {
    path.to_path_buf()
  } else {
    path.join("showreel")
  }
}

/// Everything a verb resolves from a reel directory before it can do anything.
///
/// **ONE HOME, BECAUSE `check` EXISTS TO RESOLVE EXACTLY WHAT `build` RESOLVES.**
/// That is the whole of what makes `check` worth running: if the two walked the
/// config by different routes, a green `check` would be evidence about `check`.
/// A second copy here would be the subset duplicate that hid in the pace table --
/// present fields agreeing while an absent one goes unnoticed -- so there is one
/// opener and both verbs call it.
pub struct Opened {
  pub dir: PathBuf,
  pub cfg: config::Reel,
  pub theme: artifact::theme::Theme,
  pub meta: Option<theme::Meta>,
  pub inlined: theme::Inlined,
  pub plan: plan::Plan,
}

pub fn open(path: &Path) -> Result<Opened, Failure> {
  let dir = resolve(path);
  let file = dir.join("showreel.yaml");
  let text = std::fs::read_to_string(&file).map_err(|e| {
    Failure::new(
      format!("cannot read {}: {e}", file.display()),
      "point showreel at a reel directory, or at its parent",
    )
  })?;
  let cfg = config::parse(&text, &file.display().to_string())?;

  // The theme, resolved exactly as a build resolves it. **THIS IS THE REFUSAL
  // THAT FIRES FIRST AGAINST THE LIVE 45h REEL**: its config names
  // `theme: popupart`, which is not a built-in here and never will be. Without
  // `SHOWREEL_THEME_PATH` the resolver refuses and names every directory it
  // searched; with it set, the theme resolves and announces where it came from.
  // Both are H3 working rather than a port regression.
  let theme = theme::for_reel(cfg.theme.as_deref(), &[])?;
  if let Some(said) = theme::provenance(&theme) {
    eprintln!("showreel: {said}");
  }
  // **THE ASSETS ARE INLINED HERE, NOT JUST COUNTED.** Reading `theme.yaml`
  // exercises R3; inlining is what exercises the four refusals design.md 5
  // rules -- a missing font, a missing favicon, a font that is not WOFF2, an
  // icon type nothing serves.
  let meta = match &theme.dir {
    // A built-in has no directory, so it can carry no sidecar. Not an absence
    // to report -- a shape the type already rules out.
    Some(d) => theme::Meta::read(d)?,
    None => None,
  };
  let inlined = theme::inline(&theme)?;

  // **EVERY SEGMENT RESOLVED THE WAY A BUILD RESOLVES IT.** `plan` decides and
  // never embeds, so this is the whole of the build's decision-making without
  // any of its cost -- which is exactly why `check` can run it.
  let plan = plan::plan(&dir, &cfg)?;
  Ok(Opened { dir, cfg, theme, meta, inlined, plan })
}

/// What `build` was asked for beyond the directory.
pub struct Options {
  pub out: Option<PathBuf>,
  pub keep: usize,
}

/// The `REEL` object: eleven keys, top level.
///
/// **THE EMITTED ORDER IS ALPHABETICAL, NOT THE REFERENCE'S, AND THIS COMMENT
/// SAID OTHERWISE UNTIL A BUILT ARTIFACT WAS READ.** `serde_json::Map` is a
/// `BTreeMap` unless the `preserve_order` feature is on, so the insertion order
/// below is a reading aid and nothing more. Restoring it would mean a feature
/// flag, which is a manifest change, which is hv's sign-off under AC-3.9 -- for
/// a property that is not graded.
///
/// **AND IT IS NOT GRADED, MEASURED RATHER THAN HOPED (design.md 4.6):**
/// `signature()` reads only `payload["slides"]`, so these ten non-slide keys sit
/// outside the structural identity entirely; `compare_structure` sorts keys
/// before comparing them; and the player reads every one of them BY NAME. **Two
/// of the eleven could not be order-matched in any case** -- `artist` is the raw
/// YAML mapping and `session` a comprehension over it, so their key order is the
/// USER's and no Rust struct reproduces it.
fn reel_payload(o: &Opened, socials: Vec<payload::SocialRow>) -> Result<Value, Failure> {
  let c = &o.cfg;
  let mut m = Map::new();
  let mut obj = |k: &str, v: Value| {
    m.insert(k.to_string(), v);
  };
  obj("artist", json!({ "handle": c.artist.handle, "name": c.artist.name, "discipline": c.artist.discipline }));
  // **ALL SEVEN SESSION KEYS, INCLUDING THE TWO NO LINE OF THE PLAYER READS.**
  // `iso` names the `_out/` file and `venue_url` generates the venue QR, and the
  // reference ships them regardless because its `session` is a pass-through.
  // Dropping two would be a deliberate divergence needing a section 5 row and
  // would buy nothing. design.md 4.7.
  let s = &c.session;
  obj("session", json!({
    "venue": s.venue, "city": s.city, "date": s.date, "iso": s.iso,
    "venue_url": s.venue_url, "action": s.action, "artist": s.artist,
  }));
  obj("producer", c.producer.clone().into());
  obj("wordmark", c.wordmark.clone().into());
  obj("outro", Value::Array(
    c.outro.iter().map(|r| json!({ "label": r.label, "value": r.value })).collect(),
  ));
  obj("socials", serde_json::to_value(socials).map_err(json_failed)?);
  obj("bug", match payload::bug(&o.dir, c)? {
    Some(b) => serde_json::to_value(b).map_err(json_failed)?,
    None => Value::Null,
  });
  obj("limits", serde_json::to_value(payload::Limits::current()).map_err(json_failed)?);
  obj("loop", c.loop_.into());
  obj("pace", o.plan.pace.name.into());
  obj("slides", Value::Array(payload::slides(c, &o.plan.slides)?));
  Ok(Value::Object(m))
}

/// **SERIALISING A STRUCT WE DEFINED CANNOT FAIL FOR ANY REASON A USER CAN
/// CAUSE**, but it returns a `Result` and swallowing it would be the
/// rescue-and-swallow `IN-AG-NO-SILENT-001` forbids. Surfaced with a remedy that
/// says the truth: there is nothing the operator can do, and we want to hear it.
fn json_failed(e: serde_json::Error) -> Failure {
  Failure::new(format!("cannot serialise the payload: {e}"), "this is a bug in showreel; report it")
}

/// What a build did, for a caller that owns the output stream.
pub struct Built {
  pub path: PathBuf,
  pub slides: usize,
  pub bytes: u64,
  pub theme: String,
  pub pace: &'static str,
  /// Everything the build wants said, in the order it was produced. **The
  /// caller MUST drain this**: three of its six sources have no other consumer.
  pub said: Vec<String>,
}

pub fn run(path: &Path, f: &Options) -> Result<Built, Failure> {
  let o = open(path)?;

  // **THE WARNING SOURCES ARE DRAINED, NOT MERELY CALLED.** This port turned
  // every warning from a print at the site into a return value, which is what
  // lets the tests read them -- and the cost is that a returned warning nobody
  // prints is silent and NOTHING FAILS. design.md 4.9 censuses the six sources;
  // this is where the three with no other consumer acquire one.
  let mut said: Vec<String> = Vec::new();
  let (socials, warn) = payload::socials(&o.dir, &o.cfg);
  said.extend(warn);
  let (date, warn) = deliver::stamp(&o.cfg.session)?;
  said.extend(warn);

  let payload = reel_payload(&o, socials)?;
  let data = serde_json::to_string(&payload).map_err(json_failed)?;

  // `cfg.title`, then the artist's name, then the handle -- the reference's
  // three levels, and `Artist` already resolves the last two.
  let fallback = if o.cfg.artist.name.is_empty() { &o.cfg.artist.handle } else { &o.cfg.artist.name };
  let title =
    if o.cfg.title.is_empty() { format!("{fallback} - showreel") } else { o.cfg.title.clone() };

  // **THE PRODUCER STAMP IS FILLED HERE AND NOWHERE ELSE.** This is the only
  // site holding both a `config::Reel` and a `Filling`, and an unstamped
  // artifact grades as `adjacency (UNVERIFIED)` -- which is what `render`'s
  // second refusal exists to make impossible. That refusal is reachable from
  // here alone.
  let html = template::render(template::SHELL, &template::Filling {
    theme_css: &o.inlined.css,
    title: &title,
    favicon: &o.inlined.favicon,
    data: &data,
    producer: &stamp::producer(&o.cfg),
  })?;

  let out_dir = o.dir.join("_out");
  let stem = deliver::stem(&o.cfg, &o.cfg.session, &date)?;
  let out = match &f.out {
    Some(p) => p.clone(),
    None => {
      std::fs::create_dir_all(&out_dir).map_err(|e| {
        Failure::new(
          format!("cannot create {}: {e}", out_dir.display()),
          "check the reel directory is writable",
        )
      })?;
      stem.next(&out_dir)
    }
  };
  std::fs::write(&out, &html)
    .map_err(|e| Failure::new(format!("cannot write {}: {e}", out.display()), "check the path"))?;

  // **THE SIZE IS THE FINISHED FILE's, NOT THE SUM OF WHAT WAS EMBEDDED.**
  // `Embedded::encoded` is pre-base64 and per-picture, and the artifact also
  // carries the shell, the theme and the JSON. Its own doc says nothing budgets
  // against it; this is what does.
  let bytes = std::fs::metadata(&out).map(|m| m.len()).unwrap_or(0);
  let mb = bytes as f64 / 1_048_576.0;
  if mb > 12.0 {
    said.push("over 12 MB. Lower `target:` in showreel.yaml for a television stick.".to_string());
  }

  // **PRUNING IS A PROPERTY OF THE `_out/` SLOT SEQUENCE, NOT OF WRITING A
  // FILE.** An explicit `--out` is outside the rotation, so the retention policy
  // must not delete alongside it. The reference's `if not args.out`.
  if f.out.is_none() {
    let (drop, warn) = deliver::prune(&out_dir, &stem, f.keep);
    said.extend(warn);
    for p in drop {
      std::fs::remove_file(&p).map_err(|e| {
        Failure::new(
          format!("cannot remove {}: {e}", p.display()),
          "check the directory is writable",
        )
      })?;
    }
  }

  // A theme sidecar is read to exercise its refusals; nothing downstream of the
  // artifact reads it, so its presence is worth saying and its content is not.
  if o.meta.is_none() && o.theme.dir.is_some() {
    said.push("the theme declares no theme.yaml, so no fonts and no favicon".to_string());
  }
  said.extend(plan::report(&o.dir, &o.plan.used(), &o.plan.dropped));

  Ok(Built {
    path: out,
    slides: o.plan.slides.len(),
    bytes,
    theme: o.theme.name.clone(),
    pace: o.plan.pace.name,
    said,
  })
}

#[cfg(test)]
mod tests {
  use super::*;

  /// A reel on disk: real PNGs, because the build DECODES where `check` only
  /// admits.
  fn reel(tag: &str, yaml: &str, files: &[(&str, &str)]) -> PathBuf {
    let d = std::env::temp_dir().join(format!("showreel-build-{}-{tag}", std::process::id()));
    let _ = std::fs::remove_dir_all(&d);
    std::fs::create_dir_all(d.join("art")).unwrap();
    std::fs::write(d.join("showreel.yaml"), yaml).unwrap();
    for (name, body) in files {
      let p = d.join(name);
      std::fs::create_dir_all(p.parent().unwrap()).unwrap();
      std::fs::write(&p, body).unwrap();
    }
    for n in ["one", "two"] {
      let img = image::RgbImage::from_fn(800, 450, |x, _| image::Rgb([(x % 256) as u8, 9, 9]));
      image::DynamicImage::ImageRgb8(img).save(d.join("art").join(format!("{n}.png"))).unwrap();
    }
    d
  }

  const BASE: &str = "\
artist: {handle: t, name: Tester}
session: {venue: The Hall, city: Derby, iso: 2026-09-19}
theme: default
target: 640
segments:
  - {id: g, from: art}
";

  fn built(dir: &Path, o: &Options) -> Built {
    run(dir, o).unwrap()
  }

  fn plain() -> Options {
    Options { out: None, keep: 0 }
  }

  /// **THE ARTIFACT IS SELF-CONTAINED AND STAMPED, AND THE STAMP NAMES THE
  /// REEL's TARGET.** `640` is not a constant in this crate: `normalise::TARGET`
  /// is 1920, and 45h and the pinned fixture both set 1920, so a build reading
  /// the constant is invisible on every real reel. Asserted on a PRODUCED FILE
  /// rather than on the emitter, because filling the stamp is this verb's job
  /// and nothing else reaches it.
  #[test]
  fn a_build_writes_a_filled_artifact_whose_stamp_names_the_reels_own_target() {
    let d = reel("stamped", BASE, &[]);
    let b = built(&d, &plain());
    let html = std::fs::read_to_string(&b.path).unwrap();
    assert!(html.contains("content=\"impl=showreel/"), "no producer stamp");
    assert!(html.contains(";embed=640;"), "the stamp took the constant, not the config");
    for marker in ["/*__THEME__*/", "__TITLE__", "<!--__FAVICON__-->", "/*__DATA__*/", "__PRODUCER__"]
    {
      assert!(!html.contains(marker), "{marker} was never filled");
    }
    assert_eq!(b.slides, 2);
    assert!(b.path.starts_with(d.join("_out")), "wrote outside _out: {:?}", b.path);
  }

  /// **THE ELEVEN TOP-LEVEL KEYS, ON THE ARTIFACT.** The player reads every one
  /// by name and `signature()` reads none of them, so this is the only thing
  /// standing over the payload's non-slide half end to end.
  #[test]
  fn the_artifact_carries_every_top_level_key_the_player_reads() {
    let d = reel("toplevel", BASE, &[]);
    let html = std::fs::read_to_string(built(&d, &plain()).path).unwrap();
    for k in [
      "artist", "session", "producer", "wordmark", "outro", "socials", "bug", "limits", "loop",
      "pace", "slides",
    ] {
      assert!(html.contains(&format!("\"{k}\":")), "missing top-level {k}");
    }
    assert!(html.contains("\"max_ease\":2400"), "hv's cap did not reach the artifact");
  }

  /// **EVERY WARNING SOURCE IS DRAINED, AND THIS IS THE ONE TEST THAT WOULD
  /// CATCH A BUILD GOING QUIET.** design.md 4.9: this port turned warnings from
  /// prints into return values, so a source nobody reads is silent and NOTHING
  /// ELSE FAILS -- no gate, no test, and the build still succeeds. Three
  /// sources at once, each asserted by its own text.
  #[test]
  fn a_build_drains_every_warning_source_rather_than_merely_calling_them() {
    let d = reel(
      "warnings",
      "\
artist: {handle: t, name: Tester}
session: {venue: The Hall, city: Derby, iso: 2026-09-19}
theme: default
target: 640
socials: [{label: Web, handle: t, url: 'https://new.example'}]
segments:
  - {id: g, from: art}
",
      &[
        // A QR generated for a DIFFERENT address: payload::socials warns.
        ("assets/qr/web.svg", "<!--showreel-qr:https://old.example--><svg/>"),
        // An input the gallery scan declined: slide::Collected.dropped warns.
        ("art/notes.txt", "not an image"),
        // A picture no segment reads: plan::report warns.
        ("assets/spare.png", "x"),
      ],
    );
    let said = built(&d, &plain()).said.join("\n");
    assert!(said.contains("https://old.example"), "stale-QR warning was not drained:\n{said}");
    assert!(said.contains("notes.txt"), "the dropped input was not drained:\n{said}");
    assert!(said.contains("spare.png"), "the unused asset was not drained:\n{said}");
  }

  /// **`--out` PUTS THE FILE OUTSIDE THE ROTATION, SO PRUNING MUST NOT RUN.**
  /// The reference's `if not args.out`. Asserted by count, on a directory that
  /// would otherwise be pruned to one.
  #[test]
  fn an_explicit_destination_is_outside_the_rotation_and_prunes_nothing() {
    let d = reel("explicit", BASE, &[]);
    built(&d, &plain());
    built(&d, &plain());
    built(&d, &plain());
    let out = d.join("elsewhere.html");
    let b = built(&d, &Options { out: Some(out.clone()), keep: 1 });
    assert_eq!(b.path, out);
    let left = std::fs::read_dir(d.join("_out")).unwrap().count();
    assert_eq!(left, 3, "--keep 1 pruned alongside an explicit --out");
  }

  /// **`--keep n` DELETES THE OLDEST AND SAYS SO.** The deletion is the caller's
  /// -- `prune` decides and returns paths -- so this grades the coordination and
  /// not the policy.
  #[test]
  fn keep_deletes_the_oldest_revisions_and_reports_what_it_did() {
    let d = reel("keep", BASE, &[]);
    for _ in 0..4 {
      built(&d, &plain());
    }
    assert_eq!(std::fs::read_dir(d.join("_out")).unwrap().count(), 4);
    let b = built(&d, &Options { out: None, keep: 2 });
    assert_eq!(std::fs::read_dir(d.join("_out")).unwrap().count(), 2, "the oldest were not removed");
    assert!(b.said.iter().any(|s| s.contains("pruned")), "the prune said nothing: {:?}", b.said);
  }
}
