//! The showreel command.
//!
//! A pipeline, not a viewer: it writes a file and stops. The player that drives
//! the reel lives INSIDE the artifact, which is what makes it a single file that
//! opens from a USB stick with nothing beside it.
//!
//! **`check` EXISTS BEFORE `build` DOES, DELIBERATELY.** WP-03 has built the
//! refusals -- config keys, segment shapes, the timing envelope -- and none of
//! them were reachable from a command line, so the only way to exercise them was
//! to run the test suite. A verb that runs them against a real directory makes
//! the work observable to somebody who is not reading Rust.
//!
//! **AND IT DOES REACH THE `prez showreel` SHIM, WHICH THIS COMMENT DENIED FOR A
//! DAY.** It said the dispatch was WP-05 and unwired -- true when written and
//! false from `b8dc9f1` (2026-09-09, *"prez showreel dispatches, and the help
//! says so in the same commit"*), which is the commit that wired it. `opt/prez/
//! prez` routes an exact `showreel` first argument to this binary, so all four
//! of `prez showreel`, `utilz prez showreel` and both on `PATH` answer here.
//! **A comment describing a NEIGHBOUR's state goes stale silently**, and this
//! one was read back as evidence that AC-5.1's invocation forms did not exist.
//! Corrected 2026-09-10 after vc measured all four.

use artifact::Failure;
use showreel::{build, limits, plan};
use std::path::Path;

fn main() {
  let args: Vec<String> = std::env::args().skip(1).collect();
  let verb = args.first().map(String::as_str);
  let result = match verb {
    Some("check") => match args.get(1) {
      Some(path) => check(Path::new(path)),
      None => Err(Failure::new("check needs a directory", "showreel check <dir>")),
    },
    Some("build") => match args.get(1) {
      Some(path) => flags(&args[2..]).and_then(|f| build_reel(Path::new(path), &f)),
      None => Err(Failure::new("build needs a directory", "showreel build <dir>")),
    },
    Some("--help" | "-h") | None => {
      println!("{USAGE}");
      return;
    }
    Some(other) => Err(Failure::new(
      format!("unknown command '{other}'"),
      "expected one of: check, build. Try 'showreel --help'",
    )),
  };
  if let Err(e) = result {
    eprintln!("showreel: {}", e.message);
    if let Some(remedy) = e.remedy {
      eprintln!("  remedy: {remedy}");
    }
    std::process::exit(i32::from(e.code));
  }
}

const USAGE: &str = "\
showreel -- a directory of pictures to a self-contained looping HTML reel.

usage:
  showreel check <dir>    validate showreel.yaml and report what it declares
  showreel build <dir>    write the self-contained reel into <dir>/_out/

build options:
  --out <file>            write here instead of the next _out/ slot. Suppresses
                          pruning: an explicit destination is outside the rotation
  --keep <n>              keep the newest n revisions in _out/ and delete the rest
                          (default 0: delete nothing, and say so past five)

`prez showreel <verb>` and `utilz prez showreel <verb>` reach the same binary.
WP-05 still owns the manifest, the doctor line and a `bin/` entry of its own.";

fn check(path: &Path) -> Result<(), Failure> {
  let o = build::open(path)?;
  let (cfg, plan) = (&o.cfg, &o.plan);
  let file = o.dir.join("showreel.yaml");
  let pace = plan.pace;
  let clamped = plan.slides.iter().filter(|s| s.common.clamped).count();
  let used = plan.used();
  let (meta, inlined, theme) = (&o.meta, &o.inlined, &o.theme);

  println!("showreel: {} is valid", file.display());
  println!("  artist    {} ({})", cfg.artist.name, cfg.artist.handle);
  println!("  pace      {} (dwell {}, ease {}, {} / {} / {})", pace.name, pace.dwell, pace.ease, pace.transition, pace.motion, pace.fit);
  // **THE SHAPE-TABLE SIZE IS GONE FROM THIS LINE, AND ITS ABSENCE IS THE FIX.**
  // It read `{n} declared, {m} shapes known`, joining a fact about THIS config to
  // a build-time constant with a comma, and the reading a human takes from two
  // numbers side by side is subtraction. Both available readings were false:
  // nothing was unrecognised, and "12 of yours were recognised" is unavailable
  // too, because an unknown type refuses at exit 2 well before this line. The
  // constant printed 12 for every config ever checked, and 45h happens to use
  // exactly twelve distinct types, so on the one reel anybody runs it looked
  // derived. Issue 0022, found by snorkeltoast.
  println!("  segments  {n} declared, {n} validated", n = cfg.segments.len());
  println!("  slides    {} resolved, {} asset(s) read", plan.slides.len(), used.len());
  println!("  socials   {}", cfg.socials.len());
  println!("  theme     {}", theme.name);
  match &meta {
    Some(m) => println!(
      "  assets    {} font(s), favicon {}",
      m.fonts.len(),
      m.favicon.as_deref().unwrap_or("(none declared)")
    ),
    None => println!("  assets    no theme.yaml, so no fonts and no favicon"),
  }
  println!(
    "  inlined   {} bytes of css, {} bytes of favicon link",
    inlined.css.len(),
    inlined.favicon.len()
  );
  println!("  timing    {clamped} slide(s) clamped by the envelope");
  println!(
    "  envelope  dwell >= {}ms, ease {}..{}ms",
    limits::MIN_DWELL_MS,
    limits::MIN_EASE_MS,
    limits::MAX_EASE_MS
  );
  // The exhaust report, on the same `used` the build embeds from. Reported and
  // never deleted: the tool does not get to decide a picture is finished with.
  for line in plan::report(&o.dir, &used, &plan.dropped) {
    println!("  {line}");
  }
  Ok(())
}

/// What `build` was asked for beyond the directory.
fn flags(rest: &[String]) -> Result<build::Options, Failure> {
  let mut f = build::Options { out: None, keep: 0 };
  let mut i = 0;
  while i < rest.len() {
    let need = |what: &str| {
      rest.get(i + 1).cloned().ok_or_else(|| {
        Failure::new(format!("{what} needs a value"), format!("showreel build <dir> {what} <value>"))
      })
    };
    match rest[i].as_str() {
      "--out" => f.out = Some(std::path::PathBuf::from(need("--out")?)),
      "--keep" => {
        let v = need("--keep")?;
        f.keep = v.parse().map_err(|_| {
          Failure::new(format!("--keep is not a number: {v}"), "use a whole number, eg --keep 3")
        })?;
      }
      other => {
        return Err(Failure::new(
          format!("unknown build option '{other}'"),
          "expected --out <file> or --keep <n>",
        ))
      }
    }
    i += 2;
  }
  Ok(f)
}

/// **PARSE, CALL, RENDER.** The work is `build::run`'s; this owns the stream,
/// and draining `said` is the whole of its contract -- three of its six sources
/// have no other consumer in the crate.
fn build_reel(path: &Path, f: &build::Options) -> Result<(), Failure> {
  let b = build::run(path, f)?;
  println!("showreel: wrote {}", b.path.display());
  println!(
    "  {} slides, {:.1} MB self-contained, theme={}, pace={}",
    b.slides,
    b.bytes as f64 / 1_048_576.0,
    b.theme,
    b.pace
  );
  for line in b.said {
    eprintln!("showreel: {line}");
  }
  Ok(())
}
