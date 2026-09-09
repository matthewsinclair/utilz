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
//! the work observable to somebody who is not reading Rust. It does NOT go
//! through the `prez showreel` shim yet: that dispatch is WP-05, and borrowing
//! it early to make WP-03 demonstrable would put one work package's surface
//! inside another's evidence.

use artifact::Failure;
use showreel::{config, limits, plan, theme};
use std::path::{Path, PathBuf};

fn main() {
  let args: Vec<String> = std::env::args().skip(1).collect();
  let verb = args.first().map(String::as_str);
  let result = match verb {
    Some("check") => match args.get(1) {
      Some(path) => check(Path::new(path)),
      None => Err(Failure::new("check needs a directory", "showreel check <dir>")),
    },
    Some("--help" | "-h") | None => {
      println!("{USAGE}");
      return;
    }
    Some(other) => Err(Failure::new(
      format!("unknown command '{other}'"),
      "expected one of: check. build lands in ST0017/WP-03; try 'showreel --help'",
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

`build` is not implemented yet: ST0017/WP-03 is porting it. The command surface
under `prez showreel` is WP-05 and is not wired.";

/// Resolve a reel directory the way the reference does: the directory itself, or
/// a `showreel/` beneath it.
fn resolve(path: &Path) -> PathBuf {
  if path.file_name().is_some_and(|n| n == "showreel") || !path.join("showreel").is_dir() {
    path.to_path_buf()
  } else {
    path.join("showreel")
  }
}

fn check(path: &Path) -> Result<(), Failure> {
  let reel = resolve(path);
  let file = reel.join("showreel.yaml");
  let text = std::fs::read_to_string(&file).map_err(|e| {
    Failure::new(
      format!("cannot read {}: {e}", file.display()),
      "point showreel at a reel directory, or at its parent",
    )
  })?;

  let cfg = config::parse(&text, &file.display().to_string())?;

  // The theme, resolved exactly as a build will resolve it. **`check` EXISTS TO
  // MAKE THE REFUSALS REACHABLE FROM A COMMAND LINE**, and this is the one that
  // fires first against the live 45h reel: its config names `theme: popupart`,
  // which is not a built-in here and never will be. Without
  // `SHOWREEL_THEME_PATH` the resolver refuses and names every directory it
  // searched; with it set, the theme resolves and announces that it came from
  // off the built-ins. Both are H3 working rather than a port regression.
  let theme = theme::for_reel(cfg.theme.as_deref(), &[])?;
  if let Some(said) = theme::provenance(&theme) {
    eprintln!("showreel: {said}");
  }
  // **THE ASSETS ARE INLINED HERE TOO, NOT JUST COUNTED.** Reading `theme.yaml`
  // exercises R3; inlining is what exercises the four refusals design.md 5
  // rules -- a missing font, a missing favicon, a font that is not WOFF2, an
  // icon type nothing serves. A verb that reported the counts without doing the
  // work would leave all four unreachable from a command line, which is the
  // state `check` exists to end.
  let meta = match &theme.dir {
    Some(dir) => theme::Meta::read(dir)?,
    // A built-in has no directory, so it can carry no sidecar. Not an absence
    // to report -- a shape the type already rules out.
    None => None,
  };
  let inlined = theme::inline(&theme)?;

  // **check RESOLVES EVERY SEGMENT THE WAY A BUILD WILL**, which is what makes
  // admission's refusals reachable from a command line. It reads no image:
  // `plan` decides and never embeds, so this is the whole of the build's
  // decision-making without any of its cost.
  //
  // **AND THE ASSET COUNT IS THE PLAN'S, NOT THE SLIDE LIST'S.** This line used
  // to project `Slide::assets` and reported 10 against the reference's 14 on the
  // live reel -- the bug and the social QRs are read by the ARTIFACT and by no
  // single slide. `check` reporting the narrower number would have been a
  // reasonable-looking figure that no build ever uses.
  let plan = plan::plan(&reel, &cfg)?;
  let pace = plan.pace;
  let clamped = plan.slides.iter().filter(|s| s.common.clamped).count();
  let used = plan.used();

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
  for line in plan::report(&reel, &used, &plan.dropped) {
    println!("  {line}");
  }
  Ok(())
}
