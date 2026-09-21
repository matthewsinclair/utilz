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
use showreel::aspect::Aspect;
use showreel::{build, limits, plan, video};
use std::io::IsTerminal;
use std::path::{Path, PathBuf};

fn main() {
  let args: Vec<String> = std::env::args().skip(1).collect();
  let verb = args.first().map(String::as_str);
  let result = match verb {
    Some("check") => match args.get(1) {
      Some(path) => check(Path::new(path)),
      None => Err(Failure::new(
        "check needs a directory",
        "showreel check <dir>",
      )),
    },
    Some("build") => match args.get(1) {
      Some(path) => flags(&args[2..]).and_then(|f| build_reel(Path::new(path), &f)),
      None => Err(Failure::new(
        "build needs a directory",
        "showreel build <dir>",
      )),
    },
    Some("video") => match args.get(1) {
      Some(path) => video_flags(&args[2..]).and_then(|f| video_reel(Path::new(path), &f)),
      None => Err(Failure::new(
        "video needs a directory",
        "showreel video <dir>",
      )),
    },
    Some("--help" | "-h") | None => {
      println!("{USAGE}");
      return;
    }
    Some(other) => Err(Failure::new(
      format!("unknown command '{other}'"),
      "expected one of: check, build, video. Try 'showreel --help'",
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
  showreel video <dir>    build the reel, then record it to a video beside it in
                          <dir>/_out/: the HTML's name with .html swapped for .mp4

build options:
  --out <file>            write here instead of the next _out/ slot. Suppresses
                          pruning: an explicit destination is outside the rotation
  --keep <n>              keep the newest n revisions in _out/ and delete the rest
                          (default 0: delete nothing, and say so past five). A
                          revision is its whole slot: the HTML and any video

video options:
  -o, --out <file>        write the video here, .mp4 or .mov, instead of the next
                          _out/ slot. Keeps no HTML and prunes nothing
  --fps <n>               frames per second, 1 to 60 (default 30)
  --aspect <ratio>        W:H, or widescreen (16:9, the default), portrait
                          (9:16), square (1:1) or feed (4:5). The reel's target
                          is the long edge. Wins over aspect: in showreel.yaml
  --keep <n>              as for build
  --frames <dir>          also write every frame as a PNG, with frames.tsv, into
                          a new or empty <dir>
  --browser <path>        the Chrome, Chromium, Edge or Brave to record with

video needs Chrome and ffmpeg: brew install ffmpeg, or sudo apt install ffmpeg.
It records in real time or slower, so a three-minute reel takes minutes.

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
  println!(
    "  pace      {} (dwell {}, ease {}, {} / {} / {})",
    pace.name, pace.dwell, pace.ease, pace.transition, pace.motion, pace.fit
  );
  // **THE SHAPE-TABLE SIZE IS GONE FROM THIS LINE, AND ITS ABSENCE IS THE FIX.**
  // It read `{n} declared, {m} shapes known`, joining a fact about THIS config to
  // a build-time constant with a comma, and the reading a human takes from two
  // numbers side by side is subtraction. Both available readings were false:
  // nothing was unrecognised, and "12 of yours were recognised" is unavailable
  // too, because an unknown type refuses at exit 2 well before this line. The
  // constant printed 12 for every config ever checked, and 45h happens to use
  // exactly twelve distinct types, so on the one reel anybody runs it looked
  // derived. Issue 0022, found by snorkeltoast.
  println!(
    "  segments  {n} declared, {n} validated",
    n = cfg.segments.len()
  );
  println!(
    "  slides    {} resolved, {} asset(s) read",
    plan.slides.len(),
    used.len()
  );
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

/// The value after flag `i`, or a refusal naming the flag.
fn value<'a>(rest: &'a [String], i: usize, verb: &str) -> Result<&'a str, Failure> {
  rest.get(i + 1).map(String::as_str).ok_or_else(|| {
    Failure::new(
      format!("{} needs a value", rest[i]),
      format!("showreel {verb} <dir> {} <value>", rest[i]),
    )
  })
}

/// `--keep`, read the same way for every verb that takes it.
fn keep(v: &str) -> Result<usize, Failure> {
  v.parse().map_err(|_| {
    Failure::new(
      format!("--keep is not a number: {v}"),
      "use a whole number, eg --keep 3",
    )
  })
}

/// What `build` was asked for beyond the directory.
fn flags(rest: &[String]) -> Result<build::Options, Failure> {
  let mut f = build::Options { out: None, keep: 0 };
  let mut i = 0;
  while i < rest.len() {
    // The flag is matched before its value is read, so an unknown flag is
    // refused as unknown rather than as missing a value.
    match rest[i].as_str() {
      "--out" => f.out = Some(PathBuf::from(value(rest, i, "build")?)),
      "--keep" => f.keep = keep(value(rest, i, "build")?)?,
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

/// What `video` was asked for beyond the directory. Read in full before
/// anything is built, so a bad flag costs nothing.
fn video_flags(rest: &[String]) -> Result<video::Options, Failure> {
  let mut f = video::Options {
    out: None,
    fps: video::FPS_DEFAULT,
    keep: 0,
    frames: None,
    browser: None,
    aspect: None,
  };
  let mut i = 0;
  while i < rest.len() {
    // The flag first, as for build.
    let v = || value(rest, i, "video");
    match rest[i].as_str() {
      "-o" | "--out" => f.out = Some(PathBuf::from(v()?)),
      "--fps" => f.fps = video::fps(v()?)?,
      "--keep" => f.keep = keep(v()?)?,
      "--frames" => f.frames = Some(PathBuf::from(v()?)),
      "--browser" => f.browser = Some(v()?.to_string()),
      "--aspect" => f.aspect = Some(Aspect::parse(v()?)?),
      other => {
        return Err(Failure::new(
          format!("unknown video option '{other}'"),
          "expected -o <file>, --fps <n>, --aspect <ratio>, --keep <n>, --frames <dir> or --browser <path>",
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

/// **PARSE, CALL, RENDER**, as `build_reel`. Progress goes to stderr only when
/// stderr is a terminal: a recording takes minutes, and silence there reads as
/// a hang, where anywhere else it would be noise in a log (AC-03.7).
fn video_reel(path: &Path, f: &video::Options) -> Result<(), Failure> {
  let live = std::io::stderr().is_terminal();
  let mut progress = |n: u64, of: u64| {
    if live {
      eprint!("\r  frame {n}/{of}");
      if n == of {
        eprintln!();
      }
    }
  };
  let v = video::run(path, f, &mut progress)?;
  println!("showreel: wrote {}", v.path.display());
  println!(
    "  {} frames at {} fps, {:.1} s, {}x{}, {:.1} MB, recorded by {}",
    v.frames,
    v.fps,
    v.duration_ms / 1000.0,
    v.size.0,
    v.size.1,
    v.bytes as f64 / 1_048_576.0,
    v.chrome
  );
  println!("  frame 0 taken {} ms after the reel's start", v.late_ms);
  for line in v.said {
    eprintln!("showreel: {line}");
  }
  Ok(())
}
