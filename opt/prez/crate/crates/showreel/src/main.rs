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
use showreel::{config, limits, theme};
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

  // The timing envelope, per segment, using the pace preset the config names.
  let (default_dwell, default_ease) = match cfg.pace.as_deref().unwrap_or("attract") {
    "attract" => ("6s", "0.9s"),
    "ambient" => ("11s", "1.6s"),
    other => {
      return Err(Failure::new(
        format!("{}: unknown pace '{other}'", file.display()),
        "one of: attract, ambient",
      ))
    }
  };
  let mut clamped = 0;
  for (index, seg) in cfg.segments.iter().enumerate() {
    let map = seg.as_mapping().expect("validated as a mapping above");
    let id = map
      .get(serde_yaml::Value::from("id"))
      .and_then(|v| v.as_str())
      .map_or_else(|| index.to_string(), str::to_string);
    let text_of = |key: &str, fallback: &str| {
      map
        .get(serde_yaml::Value::from(key))
        .map(|v| v.as_str().map_or_else(|| v.as_u64().map_or_else(String::new, |n| n.to_string()), str::to_string))
        .unwrap_or_else(|| fallback.to_string())
    };
    let dwell = duration(&text_of("dwell", default_dwell), "dwell", &id)?;
    let ease = duration(&text_of("ease", default_ease), "ease", &id)?;
    let timing = limits::timing(&id, dwell, ease)?;
    if timing.dwell_ms != dwell || timing.ease_ms != ease {
      clamped += 1;
    }
  }

  println!("showreel: {} is valid", file.display());
  println!("  artist    {} ({})", cfg.artist.name, cfg.artist.handle);
  println!("  pace      {}", cfg.pace.as_deref().unwrap_or("attract"));
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
  println!("  timing    {clamped} segment(s) clamped by the envelope");
  println!(
    "  envelope  dwell >= {}ms, ease {}..{}ms",
    limits::MIN_DWELL_MS,
    limits::MIN_EASE_MS,
    limits::MAX_EASE_MS
  );
  Ok(())
}

fn duration(value: &str, field: &str, id: &str) -> Result<u32, Failure> {
  showreel::duration::parse(value, field, &format!("segment '{id}'"))
}
