//! `showreel video`: a reel recorded to a video file (ST0021).
//!
//! It builds the reel exactly as `build` does, by calling it, records the built
//! HTML's own player (`record`), and pipes every frame to ffmpeg. The video is
//! the reel, because the player that drew it is the one that ships.
//!
//! **EVERY REFUSAL THAT NEEDS NO RECORDING COMES BEFORE ONE STARTS**: a name
//! that is no container, a browser that cannot be found, an ffmpeg that is not
//! installed, a frames directory that is not empty. A missing tool found ten
//! minutes into a recording is ten minutes of somebody's time.
//!
//! **NO PARTIAL FILE EVER LOOKS FINISHED.** ffmpeg writes `<name>.partial`, and
//! the rename to `<name>` happens only once ffmpeg has exited 0 and ffprobe
//! counts the frames the plan made. Every failure this process sees removes
//! the partial; an interrupt can leave one, never the finished name, and the
//! next run removes it before it starts.

use crate::aspect::Aspect;
use crate::record::{self, Frame};
use crate::tail::{and_also, Tail};
use crate::zone::Zone;
use crate::{build, deliver};
use artifact::scratch::{Scratch, Tool};
use artifact::Failure;
use std::fmt::Write as _;
use std::io::Write;
use std::os::unix::process::CommandExt;
use std::path::{Path, PathBuf};
use std::process::{Child, ChildStdin, Command, Stdio};

/// Frames per second when `--fps` is not given (hv's answer 3).
pub const FPS_DEFAULT: u32 = 30;

/// The most frames per second `--fps` takes.
pub const FPS_MAX: u32 = 60;

const INSTALL: &str =
  "install ffmpeg, which brings ffprobe: brew install ffmpeg on macOS, sudo apt install ffmpeg on Debian and Ubuntu";

const RETRY: &str = "record again, and report it with ffmpeg's version if it recurs";

/// What `video` was asked for beyond the directory.
pub struct Options {
  /// `-o`: write the video here, outside the `_out/` rotation.
  pub out: Option<PathBuf>,
  pub fps: u32,
  /// `--keep`, as `build` takes it: whole slots, the HTML with its video.
  pub keep: usize,
  /// `--frames`: also write every frame as a PNG, and `frames.tsv`, here.
  pub frames: Option<PathBuf>,
  /// `--browser`: the browser to record with, rather than the one found.
  pub browser: Option<String>,
  /// `--aspect`, which wins over the reel's `aspect:`.
  pub aspect: Option<Aspect>,
  /// `--safe-zone`, which wins over the reel's `safe_zone:`.
  pub safe_zone: Option<Zone>,
}

/// What a recording made, for a caller that owns the output stream.
pub struct Video {
  pub path: PathBuf,
  pub frames: u64,
  pub fps: u32,
  pub duration_ms: f64,
  pub size: (u32, u32),
  /// The video's size, `None` when it could not be read, which `said` then
  /// names (issue 0096).
  pub bytes: Option<u64>,
  pub chrome: String,
  pub late_ms: f64,
  /// Everything the build and the recording want said. **The caller MUST drain
  /// this**, as it must `build::Built::said`.
  pub said: Vec<String>,
}

/// `--fps`, read: a whole number from 1 to `FPS_MAX`, or a refusal naming it.
pub fn fps(value: &str) -> Result<u32, Failure> {
  value
    .parse::<u32>()
    .ok()
    .filter(|n| (1..=FPS_MAX).contains(n))
    .ok_or_else(|| {
      Failure::new(
        format!("--fps takes a whole number from 1 to {FPS_MAX}, not '{value}'"),
        format!("eg --fps {FPS_DEFAULT}, the default"),
      )
    })
}

/// Records the reel in `dir` to a video. `progress` hears each frame as it is
/// captured, with how many there are.
pub fn run(dir: &Path, o: &Options, progress: &mut dyn FnMut(u64, u64)) -> Result<Video, Failure> {
  let format = match &o.out {
    Some(out) => container(out)?,
    None => deliver::VIDEO_EXTENSIONS[0],
  };
  let browser = artifact::browser::find(o.browser.as_deref())?;
  let ffmpeg = on_path("ffmpeg")?;
  let ffprobe = on_path("ffprobe")?;
  if let Some(frames) = &o.frames {
    empty_directory(frames)?;
  }

  // With `-o` the HTML is built into the recording's own temporary directory,
  // because the caller named only a video, and it goes when the recording does.
  let scratch = Scratch::new(Tool::Showreel)?;
  let built = build::run(
    dir,
    &build::Options {
      out: o.out.as_ref().map(|_| scratch.path().join("reel.html")),
      keep: o.keep,
    },
  )?;
  let video = match &o.out {
    Some(out) => out.clone(),
    None => deliver::video_of(&built.path, format),
  };
  let partial = partial_of(&video);
  let mut said = built.said;
  said.extend(sweep_partials(&video, o.out.is_none())?);
  let aspect = chosen(o.aspect, built.aspect);
  let zone = zone_chosen(o.safe_zone, built.safe_zone);
  refuse_a_zone_on_a_wide_frame(zone, aspect)?;
  let size = aspect.size(built.target);

  let mut encoder = Encoder::start(&ffmpeg, &partial, format, o.fps)?;
  let mut table = String::new();
  // A frame is kept before ffmpeg takes it, so a recording that fails at the
  // encoder still leaves what was captured under `--frames`, and shows the
  // failure came mid-recording rather than before it.
  let recorded = record::record(
    &browser,
    &built.path,
    scratch,
    size,
    aspect.scale(),
    o.fps,
    zone.word(),
    |frame| {
      if let Some(frames) = &o.frames {
        keep_frame(frames, &frame)?;
        // Infallible: writing to a String cannot fail.
        let _ = writeln!(table, "{}\t{}\t{}", frame.index, frame.page_ms, frame.slide);
      }
      encoder.take(&frame)?;
      progress(frame.index + 1, frame.of);
      Ok(())
    },
  );
  let recording = match recorded {
    Ok(recording) => recording,
    Err(mut failure) => {
      and_also(&mut failure, encoder.abandon());
      return Err(failure);
    }
  };
  // What the recording's ending could not do, to Chrome's process group or its
  // scratch directory, is said whatever comes next: under the refusal when the
  // video is not made, beside the video when it is (issue 0096).
  let chrome_said = recording.warnings;
  let made = place(encoder, &ffprobe, &partial, &video, recording.frames).and_then(|()| {
    let Some(frames) = &o.frames else {
      return Ok(());
    };
    let head = format!(
      "# t0_ms={} fps={}\nframe\tpage_ms\tslide\n",
      recording.t0_ms, o.fps
    );
    deliver::write(
      &frames.join("frames.tsv"),
      (head + &table).as_bytes(),
      false,
    )
  });
  carry(made, chrome_said, &mut said)?;
  Ok(Video {
    bytes: deliver::size_of(&video, &mut said),
    path: video,
    frames: recording.frames,
    fps: o.fps,
    duration_ms: recording.duration_ms,
    size,
    chrome: recording.chrome,
    late_ms: recording.late_ms,
    said,
  })
}

/// Ends the encode and puts the video in place: the partial becomes the video
/// only once ffmpeg has exited 0 and ffprobe counts the frames the recording
/// made, and each refusal here removes the partial, saying when it cannot.
fn place(
  encoder: Encoder,
  ffprobe: &Path,
  partial: &Path,
  video: &Path,
  frames: u64,
) -> Result<(), Failure> {
  encoder.finish()?;
  let counted = frames_in(ffprobe, partial);
  if counted.as_ref().ok() != Some(&frames) {
    let found = counted.map_or_else(|e| e.message, |n| format!("{n} frames"));
    let mut failure = Failure::new(
      format!("the encode holds {found}, and the recording made {frames}"),
      RETRY,
    );
    and_also(&mut failure, remove_partial(partial));
    return Err(failure);
  }
  std::fs::rename(partial, video).map_err(|e| {
    let mut failure = Failure::new(
      format!(
        "could not move the finished video to {}: {e}",
        video.display()
      ),
      "check the directory is writable",
    );
    and_also(&mut failure, remove_partial(partial));
    failure
  })
}

/// What the recording's ending could not do goes under the refusal when the
/// video is not made, and among what is said beside it when it is: one join,
/// whichever step refuses (issue 0096).
fn carry(
  made: Result<(), Failure>,
  chrome_said: Vec<String>,
  said: &mut Vec<String>,
) -> Result<(), Failure> {
  if let Err(mut failure) = made {
    and_also(&mut failure, chrome_said);
    return Err(failure);
  }
  said.extend(chrome_said);
  Ok(())
}

/// The container a name asks for: its extension, when it is one `video`
/// writes. ffmpeg's format names are the extensions themselves.
fn container(out: &Path) -> Result<&'static str, Failure> {
  let ext = out
    .extension()
    .and_then(|e| e.to_str())
    .map(str::to_ascii_lowercase);
  deliver::VIDEO_EXTENSIONS
    .iter()
    .find(|known| ext.as_deref() == Some(**known))
    .copied()
    .ok_or_else(|| {
      Failure::new(
        format!("-o {} names no video container", out.display()),
        "end the name in .mp4 (H.264), or in .mov (H.264 in QuickTime)",
      )
    })
}

/// A tool on PATH, or a refusal naming it, with the line that installs it.
fn on_path(name: &str) -> Result<PathBuf, Failure> {
  artifact::path::on_path(name).ok_or_else(|| {
    Failure::new(
      format!("{name} is not on PATH, and showreel video needs it"),
      INSTALL,
    )
  })
}

/// `--frames` must name a new or empty directory: the frames of two
/// recordings must never sit together under one `frames.tsv`.
fn empty_directory(dir: &Path) -> Result<(), Failure> {
  let occupied = std::fs::read_dir(dir).map(|mut entries| entries.next().is_some());
  match occupied {
    Ok(false) => Ok(()),
    Ok(true) => Err(Failure::new(
      format!("--frames {} is not empty", dir.display()),
      "name a new or empty directory for the frames",
    )),
    Err(e) if e.kind() == std::io::ErrorKind::NotFound => {
      std::fs::create_dir_all(dir).map_err(|e| {
        Failure::new(
          format!("cannot create {}: {e}", dir.display()),
          "check the path",
        )
      })
    }
    Err(e) => Err(Failure::new(
      format!("cannot read --frames {}: {e}", dir.display()),
      "check the path",
    )),
  }
}

/// Where ffmpeg writes until the video is proven finished.
fn partial_of(video: &Path) -> PathBuf {
  let mut name = video.as_os_str().to_owned();
  name.push(".partial");
  PathBuf::from(name)
}

/// Removes what an interrupted run left: in `_out/`, every `.partial`, since
/// a slot run's partial carries its own slot's name; for `-o`, that name's. A
/// place it cannot read is refused, never taken as empty, and a partial gone
/// before its removal counts as removed (issue 0096).
fn sweep_partials(video: &Path, in_slot: bool) -> Result<Vec<String>, Failure> {
  let stale: Vec<PathBuf> = if in_slot {
    let dir = video.parent().unwrap_or(Path::new("."));
    // A read that fails is never an empty directory (`admit.rs`'s rule).
    let listed = deliver::entries(dir);
    listed
      .map_err(|e| {
        Failure::new(
          format!(
            "cannot read {} for what an interrupted recording left: {e}",
            dir.display()
          ),
          "make the directory readable",
        )
      })?
      .into_iter()
      .filter(|p| p.extension().is_some_and(|e| e == "partial"))
      .collect()
  } else {
    let own = partial_of(video);
    let there = own.try_exists().map_err(|e| {
      Failure::new(
        format!(
          "cannot check for {}, which an interrupted recording may have left: {e}",
          own.display()
        ),
        "check the path",
      )
    })?;
    if there {
      vec![own]
    } else {
      Vec::new()
    }
  };
  let mut said = Vec::new();
  for p in stale {
    if let Some(message) = remove_partial(&p) {
      return Err(Failure::new(
        message,
        "remove it by hand; an interrupted recording left it",
      ));
    }
    said.push(format!(
      "removed {}, which an interrupted recording left",
      p.display()
    ));
  }
  Ok(said)
}

/// The aspect a recording is made at: `--aspect`, else the reel's `aspect:`,
/// else widescreen.
fn chosen(flag: Option<Aspect>, reel: Option<Aspect>) -> Aspect {
  flag.or(reel).unwrap_or_default()
}

/// The zone a recording is made inside: `--safe-zone`, else the reel's
/// `safe_zone:`, else none.
fn zone_chosen(flag: Option<Zone>, reel: Option<Zone>) -> Zone {
  flag.or(reel).unwrap_or_default()
}

/// **A PLATFORM ZONE ON A WIDE FRAME IS REFUSED, NAMING BOTH.** Its insets are
/// measured on a 9:16 phone, where the app's own UI sits; on a frame wider
/// than it is tall they would move every mark and line of type for a reason
/// nobody could see on the result (ST0024 D5a).
fn refuse_a_zone_on_a_wide_frame(zone: Zone, aspect: Aspect) -> Result<(), Failure> {
  if zone == Zone::None || aspect.w <= aspect.h {
    return Ok(());
  }
  Err(Failure::new(
    format!(
      "--safe-zone {} needs a frame no wider than it is tall, and this one is {}:{}",
      zone.word().unwrap_or("none"),
      aspect.w,
      aspect.h
    ),
    "record it at --aspect portrait, square or feed, or drop --safe-zone",
  ))
}

/// One frame, kept as a PNG under `--frames`.
fn keep_frame(dir: &Path, frame: &Frame) -> Result<(), Failure> {
  deliver::write(
    &dir.join(format!("f{:05}.png", frame.index)),
    &frame.png,
    false,
  )
}

/// How many frames ffprobe reads in a video.
fn frames_in(ffprobe: &Path, video: &Path) -> Result<u64, Failure> {
  let out = Command::new(ffprobe)
    .args(["-v", "error", "-count_frames", "-select_streams", "v:0"])
    .args([
      "-show_entries",
      "stream=nb_read_frames",
      "-of",
      "default=nw=1:nk=1",
    ])
    .arg(video)
    .output()
    .map_err(|e| Failure::new(format!("could not run ffprobe: {e}"), INSTALL))?;
  String::from_utf8_lossy(&out.stdout)
    .trim()
    .parse()
    .map_err(|_| {
      Failure::new(
        format!(
          "ffprobe could not count the frames of {}: {}",
          video.display(),
          String::from_utf8_lossy(&out.stderr).trim()
        ),
        RETRY,
      )
    })
}

/// ffmpeg, taking PNG frames on its stdin and writing H.264 to the partial.
///
/// It runs in a process group of its own, so an interrupt at the terminal
/// reaches this process alone: ffmpeg then sees its input end and finishes the
/// partial, which is all an interrupt may leave.
struct Encoder {
  child: Child,
  stdin: Option<ChildStdin>,
  stderr: Tail,
  partial: PathBuf,
}

impl Encoder {
  fn start(ffmpeg: &Path, partial: &Path, format: &str, fps: u32) -> Result<Self, Failure> {
    let mut child = Command::new(ffmpeg)
      .args(["-hide_banner", "-loglevel", "error"])
      .args([
        "-f",
        "image2pipe",
        "-c:v",
        "png",
        "-framerate",
        &fps.to_string(),
        "-i",
        "-",
      ])
      .args([
        "-c:v",
        "libx264",
        "-pix_fmt",
        "yuv420p",
        "-movflags",
        "+faststart",
      ])
      // The format is named, because ffmpeg would otherwise read it from the
      // extension, and the partial's extension is `.partial`. The output is
      // the last argument.
      .args(["-f", format, "-y"])
      .arg(partial)
      .stdin(Stdio::piped())
      .stdout(Stdio::null())
      .stderr(Stdio::piped())
      .process_group(0)
      .spawn()
      .map_err(|e| {
        Failure::new(
          format!("could not start {}: {e}", ffmpeg.display()),
          INSTALL,
        )
      })?;
    let stderr = match child.stderr.take() {
      Some(stderr) => Tail::read(stderr),
      None => {
        let mut failure = Failure::new(
          "ffmpeg started without the pipes it was given",
          "report it with the platform",
        );
        and_also(&mut failure, stop_ffmpeg(&mut child));
        and_also(&mut failure, remove_partial(partial));
        return Err(failure);
      }
    };
    Ok(Self {
      stdin: child.stdin.take(),
      child,
      stderr,
      partial: partial.to_path_buf(),
    })
  }

  /// Hands one frame to ffmpeg. A refusal here is ffmpeg having stopped.
  fn take(&mut self, frame: &Frame) -> Result<(), Failure> {
    let written = match self.stdin.as_mut() {
      Some(stdin) => stdin.write_all(&frame.png),
      None => Err(std::io::Error::other("its input is closed")),
    };
    written.map_err(|e| {
      let mut failure = Failure::new(
        format!("ffmpeg stopped taking frames at frame {}: {e}", frame.index),
        RETRY,
      );
      self.stderr.append_to(&mut failure, "ffmpeg");
      failure
    })
  }

  /// Ends the input and waits for ffmpeg, which must exit 0. Otherwise the
  /// partial is removed and ffmpeg's own account goes with the refusal.
  fn finish(mut self) -> Result<(), Failure> {
    drop(self.stdin.take());
    let status = self.child.wait();
    if matches!(status, Ok(s) if s.success()) {
      return Ok(());
    }
    let mut failure = Failure::new(
      format!(
        "ffmpeg failed to finish the video: {}",
        status.map_or_else(|e| e.to_string(), |s| s.to_string())
      ),
      RETRY,
    );
    self.stderr.append_to(&mut failure, "ffmpeg");
    and_also(&mut failure, remove_partial(&self.partial));
    Err(failure)
  }

  /// A recording that failed: ffmpeg is stopped and its partial removed, and
  /// what could not be done is returned for the recording's failure to carry
  /// (issue 0096).
  fn abandon(mut self) -> Vec<String> {
    drop(self.stdin.take());
    let mut said = stop_ffmpeg(&mut self.child);
    said.extend(remove_partial(&self.partial));
    said
  }
}

/// Stops ffmpeg and reaps it, and says what it could not do (issue 0096).
/// `try_wait` comes first: a child that has already exited is reaped there and
/// not killed, so a recording whose ffmpeg died first says nothing false. A
/// child found running takes the kill even if it exits in between, since it is
/// not reaped until the wait, so a kill or wait error after that is real. Only
/// a child found running is killed: when `try_wait` itself fails, the pid may
/// no longer be ffmpeg's, so it is said and nothing is signalled.
fn stop_ffmpeg(child: &mut Child) -> Vec<String> {
  let mut said = Vec::new();
  match child.try_wait() {
    Ok(Some(_)) => return said,
    Ok(None) => {}
    Err(e) => return vec![format!("could not ask whether ffmpeg had exited: {e}")],
  }
  if let Err(e) = child.kill() {
    said.push(format!("could not stop ffmpeg: {e}"));
  }
  if let Err(e) = child.wait() {
    said.push(format!("could not wait for ffmpeg: {e}"));
  }
  said
}

/// Removes the partial, and says so when it cannot (issue 0096). A partial
/// that is not there is removed: `abandon` and the no-pipes path can run
/// before ffmpeg has made it, so a warning there would be false.
fn remove_partial(partial: &Path) -> Option<String> {
  match std::fs::remove_file(partial) {
    Ok(()) => None,
    Err(e) if e.kind() == std::io::ErrorKind::NotFound => None,
    Err(e) => Some(format!(
      "could not remove the partial {}: {e}",
      partial.display()
    )),
  }
}

#[cfg(test)]
mod tests {
  use super::*;

  #[test]
  fn the_flag_beats_the_reel_and_the_reel_beats_widescreen() {
    let portrait = Aspect { w: 9, h: 16 };
    let square = Aspect { w: 1, h: 1 };
    assert_eq!(chosen(Some(portrait), Some(square)), portrait);
    assert_eq!(chosen(None, Some(square)), square);
    assert_eq!(chosen(Some(portrait), None), portrait);
    assert_eq!(chosen(None, None), Aspect::WIDESCREEN);
  }

  #[test]
  fn the_zone_flag_beats_the_reel_and_the_reel_beats_no_zone() {
    assert_eq!(
      zone_chosen(Some(Zone::Social), Some(Zone::None)),
      Zone::Social
    );
    assert_eq!(zone_chosen(None, Some(Zone::Social)), Zone::Social);
    assert_eq!(
      zone_chosen(Some(Zone::None), Some(Zone::Social)),
      Zone::None
    );
    assert_eq!(zone_chosen(None, None), Zone::None);
  }

  #[test]
  fn a_zone_is_refused_on_a_frame_wider_than_it_is_tall_naming_both() {
    let tall = Aspect { w: 9, h: 16 };
    let square = Aspect { w: 1, h: 1 };
    assert!(refuse_a_zone_on_a_wide_frame(Zone::Social, tall).is_ok());
    assert!(refuse_a_zone_on_a_wide_frame(Zone::Social, square).is_ok());
    // No zone is never refused, whatever the frame.
    assert!(refuse_a_zone_on_a_wide_frame(Zone::None, Aspect::WIDESCREEN).is_ok());
    let e = refuse_a_zone_on_a_wide_frame(Zone::Social, Aspect::WIDESCREEN).unwrap_err();
    assert!(
      e.message.contains("social"),
      "names the zone: {}",
      e.message
    );
    assert!(e.message.contains("16:9"), "names the frame: {}", e.message);
  }

  #[test]
  fn fps_takes_1_to_60_and_refuses_the_rest_by_name() {
    assert_eq!(fps("1").unwrap(), 1);
    assert_eq!(fps("60").unwrap(), 60);
    for bad in ["0", "61", "x", "-1", "2.5", ""] {
      let e = fps(bad).unwrap_err();
      assert!(e.message.contains("--fps"), "{bad}: {}", e.message);
    }
  }

  #[test]
  fn the_container_is_the_extension_and_nothing_else_is_one() {
    assert_eq!(container(Path::new("a/b.mp4")).unwrap(), "mp4");
    assert_eq!(container(Path::new("b.MOV")).unwrap(), "mov");
    for bad in ["b.mkv", "b", "b.mp4.partial"] {
      assert!(container(Path::new(bad)).is_err(), "{bad}");
    }
  }

  #[test]
  fn with_no_aspect_the_size_is_the_target_at_sixteen_nine_as_before() {
    // The values pinned before ST0022, through the path a recording takes.
    let size = |t| chosen(None, None).size(t);
    assert_eq!(size(1920), (1920, 1080));
    assert_eq!(size(2560), (2560, 1440));
    assert_eq!(size(1000), (1000, 562));
    assert_eq!(size(641), (640, 360));
  }

  #[test]
  fn a_partial_is_the_video_s_name_and_more() {
    assert_eq!(
      partial_of(Path::new("/x/r-001.showreel.mp4")),
      PathBuf::from("/x/r-001.showreel.mp4.partial")
    );
  }

  /// The directory under test is a fresh path inside a guard, so it is made
  /// by `empty_directory` and goes with the guard, pass or fail (issue 0096).
  #[test]
  fn frames_go_only_where_nothing_is() {
    let guard = artifact::testing::TempDir::new("showreel-video", "frames");
    let dir = guard.join("frames");
    empty_directory(&dir).unwrap();
    assert!(dir.is_dir(), "a new directory is made");
    empty_directory(&dir).unwrap();
    std::fs::write(dir.join("f00000.png"), b"x").unwrap();
    let e = empty_directory(&dir).unwrap_err();
    assert!(e.message.contains("not empty"), "{}", e.message);
  }

  /// A partial that cannot be removed is named rather than dropped, and one
  /// that is not there counts as removed (issue 0096). A mode stops removal
  /// for a user and not for root, so where it does not bind the test fails
  /// saying so: it cannot pass without having measured.
  #[test]
  fn a_partial_that_cannot_be_removed_is_named_issue_0096() {
    use std::os::unix::fs::PermissionsExt;
    let guard = artifact::testing::TempDir::new("showreel-video", "partial");
    let held = guard.join("held");
    std::fs::create_dir(&held).unwrap();
    let partial = held.join("r.mp4.partial");
    std::fs::write(&partial, b"x").unwrap();
    assert_eq!(remove_partial(&held.join("never-made.partial")), None);
    std::fs::set_permissions(&held, std::fs::Permissions::from_mode(0o500)).unwrap();
    let binds = std::fs::write(held.join("probe"), b"x").is_err();
    let said = remove_partial(&partial);
    std::fs::set_permissions(&held, std::fs::Permissions::from_mode(0o700)).unwrap();
    assert!(
      binds,
      "a mode does not stop removal here (root?), so this test cannot run"
    );
    let said = said.expect("remove_partial said nothing of a partial it could not remove");
    assert!(
      said.contains(&partial.display().to_string()),
      "the message does not name {}: {said}",
      partial.display()
    );
  }

  /// What the recording's ending could not do goes under a refusal after it,
  /// leaving what is said as it was, and among what is said beside a video
  /// that is made (issue 0096).
  #[test]
  fn what_the_recording_could_not_do_is_said_whether_or_not_the_video_is_made_issue_0096() {
    let lines = || vec!["could not remove the scratch".to_string()];
    let mut said = vec!["built".to_string()];
    let refused = carry(
      Err(Failure::new("it stopped", "try again")),
      lines(),
      &mut said,
    );
    assert_eq!(
      refused.unwrap_err().message,
      "it stopped\n  and could not remove the scratch"
    );
    assert_eq!(said, ["built"]);
    carry(Ok(()), lines(), &mut said).unwrap();
    assert_eq!(said, ["built", "could not remove the scratch"]);
  }

  /// A place the sweep cannot read is refused by name, never taken as empty:
  /// `_out/`, and `-o`'s own partial (issue 0096). Once it can read, the sweep
  /// removes what an interrupted run left and says so. A mode binds a user and
  /// not root, so where it does not bind the test fails saying so.
  #[test]
  fn a_place_the_sweep_cannot_read_is_refused_by_name_issue_0096() {
    use std::os::unix::fs::PermissionsExt;
    let mode = |dir: &Path, bits: u32| {
      std::fs::set_permissions(dir, std::fs::Permissions::from_mode(bits)).unwrap();
    };
    let guard = artifact::testing::TempDir::new("showreel-video", "sweep");

    let out = guard.join("_out");
    std::fs::create_dir(&out).unwrap();
    let stale = out.join("r-001.showreel.mp4.partial");
    std::fs::write(&stale, b"x").unwrap();
    mode(&out, 0o300);
    let binds = std::fs::read_dir(&out).is_err();
    let swept = sweep_partials(&out.join("r-002.showreel.mp4"), true);
    mode(&out, 0o700);
    assert!(
      binds,
      "a mode does not stop a read here (root?), so this test cannot run"
    );
    let e = swept.expect_err("an _out/ that cannot be read was taken as empty");
    assert!(
      e.message.contains(&out.display().to_string()),
      "the refusal does not name {}: {}",
      out.display(),
      e.message
    );
    mode(&out, 0o500);
    let binds = std::fs::write(out.join("probe"), b"x").is_err();
    let swept = sweep_partials(&out.join("r-002.showreel.mp4"), true);
    mode(&out, 0o700);
    assert!(
      binds,
      "a mode does not stop a write here (root?), so this test cannot run"
    );
    let e = swept.expect_err("a stale partial that could not be removed was said to be removed");
    assert!(
      e.message.contains(&stale.display().to_string()),
      "the refusal does not name {}: {}",
      stale.display(),
      e.message
    );
    let said = sweep_partials(&out.join("r-002.showreel.mp4"), true).unwrap();
    assert_eq!(
      said,
      [format!(
        "removed {}, which an interrupted recording left",
        stale.display()
      )]
    );
    assert!(!stale.exists(), "the stale partial is still there");

    let held = guard.join("held");
    std::fs::create_dir(&held).unwrap();
    mode(&held, 0o600);
    let binds = held.join("probe").try_exists().is_err();
    let swept = sweep_partials(&held.join("r.mp4"), false);
    mode(&held, 0o700);
    assert!(
      binds,
      "a mode does not stop a look here (root?), so this test cannot run"
    );
    let e = swept.expect_err("-o's partial, which could not be looked for, was taken as absent");
    let own = held.join("r.mp4.partial");
    assert!(
      e.message.contains(&own.display().to_string()),
      "the refusal does not name {}: {}",
      own.display(),
      e.message
    );
  }
}
