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

use crate::record::{self, Frame, Scratch};
use crate::tail::Tail;
use crate::{build, deliver};
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
}

/// What a recording made, for a caller that owns the output stream.
pub struct Video {
  pub path: PathBuf,
  pub frames: u64,
  pub fps: u32,
  pub duration_ms: f64,
  pub size: (u32, u32),
  pub bytes: u64,
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
  let scratch = Scratch::new()?;
  let built = build::run(
    dir,
    &build::Options {
      out: o.out.as_ref().map(|_| scratch.path().join("reel.html")),
      keep: o.keep,
    },
  )?;
  let video = match &o.out {
    Some(out) => out.clone(),
    None => built.path.with_extension(format),
  };
  let partial = partial_of(&video);
  let mut said = built.said;
  said.extend(sweep_partials(&video, o.out.is_none())?);
  let size = sixteen_nine(built.target);

  let mut encoder = Encoder::start(&ffmpeg, &partial, format, o.fps)?;
  let mut table = String::new();
  // A frame is kept before ffmpeg takes it, so a recording that fails at the
  // encoder still leaves what was captured under `--frames`, and shows the
  // failure came mid-recording rather than before it.
  let recorded = record::record(&browser, &built.path, scratch, size, o.fps, |frame| {
    if let Some(frames) = &o.frames {
      keep_frame(frames, &frame)?;
      // Infallible: writing to a String cannot fail.
      let _ = writeln!(table, "{}\t{}\t{}", frame.index, frame.page_ms, frame.slide);
    }
    encoder.take(&frame)?;
    progress(frame.index + 1, frame.of);
    Ok(())
  });
  let recording = match recorded {
    Ok(recording) => recording,
    Err(failure) => {
      encoder.abandon();
      return Err(failure);
    }
  };
  encoder.finish()?;

  let counted = frames_in(&ffprobe, &partial);
  if counted.as_ref().ok() != Some(&recording.frames) {
    let _ = std::fs::remove_file(&partial);
    let found = counted.map_or_else(|e| e.message, |n| format!("{n} frames"));
    return Err(Failure::new(
      format!(
        "the encode holds {found}, and the recording made {}",
        recording.frames
      ),
      RETRY,
    ));
  }
  std::fs::rename(&partial, &video).map_err(|e| {
    let _ = std::fs::remove_file(&partial);
    Failure::new(
      format!(
        "could not move the finished video to {}: {e}",
        video.display()
      ),
      "check the directory is writable",
    )
  })?;
  if let Some(frames) = &o.frames {
    let head = format!(
      "# t0_ms={} fps={}\nframe\tpage_ms\tslide\n",
      recording.t0_ms, o.fps
    );
    write(&frames.join("frames.tsv"), (head + &table).as_bytes())?;
  }

  said.extend(recording.warnings);
  Ok(Video {
    bytes: std::fs::metadata(&video).map(|m| m.len()).unwrap_or(0),
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
  std::env::var_os("PATH")
    .and_then(|paths| {
      std::env::split_paths(&paths)
        .map(|dir| dir.join(name))
        .find(|p| p.is_file())
    })
    .ok_or_else(|| {
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
/// a slot run's partial carries its own slot's name; for `-o`, that name's.
fn sweep_partials(video: &Path, in_slot: bool) -> Result<Vec<String>, Failure> {
  let stale: Vec<PathBuf> = if in_slot {
    let dir = video.parent().unwrap_or(Path::new("."));
    std::fs::read_dir(dir)
      .map(|entries| {
        entries
          .filter_map(Result::ok)
          .map(|e| e.path())
          .filter(|p| p.extension().is_some_and(|e| e == "partial"))
          .collect()
      })
      .unwrap_or_default()
  } else {
    let own = partial_of(video);
    if own.exists() {
      vec![own]
    } else {
      Vec::new()
    }
  };
  let mut said = Vec::new();
  for p in stale {
    std::fs::remove_file(&p).map_err(|e| {
      Failure::new(
        format!("cannot remove the stale {}: {e}", p.display()),
        "remove it by hand; an interrupted recording left it",
      )
    })?;
    said.push(format!(
      "removed {}, which an interrupted recording left",
      p.display()
    ));
  }
  Ok(said)
}

/// The video's size: the reel's target at 16:9, both even, as H.264's 4:2:0
/// chroma needs. 1920 is 1920x1080 and 2560 is 2560x1440 (hv's answer 2).
fn sixteen_nine(target: u32) -> (u32, u32) {
  let width = target & !1;
  (width, (width * 9 / 16) & !1)
}

/// One frame, kept as a PNG under `--frames`.
fn keep_frame(dir: &Path, frame: &Frame) -> Result<(), Failure> {
  write(&dir.join(format!("f{:05}.png", frame.index)), &frame.png)
}

fn write(path: &Path, bytes: &[u8]) -> Result<(), Failure> {
  std::fs::write(path, bytes).map_err(|e| {
    Failure::new(
      format!("cannot write {}: {e}", path.display()),
      "check the directory is writable",
    )
  })
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
        let _ = child.kill();
        let _ = child.wait();
        return Err(Failure::new(
          "ffmpeg started without the pipes it was given",
          "report it with the platform",
        ));
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
    let _ = std::fs::remove_file(&self.partial);
    let mut failure = Failure::new(
      format!(
        "ffmpeg failed to finish the video: {}",
        status.map_or_else(|e| e.to_string(), |s| s.to_string())
      ),
      RETRY,
    );
    self.stderr.append_to(&mut failure, "ffmpeg");
    Err(failure)
  }

  /// A recording that failed: ffmpeg is stopped and its partial removed.
  fn abandon(mut self) {
    drop(self.stdin.take());
    let _ = self.child.kill();
    let _ = self.child.wait();
    let _ = std::fs::remove_file(&self.partial);
  }
}

#[cfg(test)]
mod tests {
  use super::*;

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
  fn the_size_is_the_target_at_sixteen_nine_and_even() {
    assert_eq!(sixteen_nine(1920), (1920, 1080));
    assert_eq!(sixteen_nine(2560), (2560, 1440));
    assert_eq!(sixteen_nine(1000), (1000, 562));
    assert_eq!(sixteen_nine(641), (640, 360));
  }

  #[test]
  fn a_partial_is_the_video_s_name_and_more() {
    assert_eq!(
      partial_of(Path::new("/x/r-001.showreel.mp4")),
      PathBuf::from("/x/r-001.showreel.mp4.partial")
    );
  }

  #[test]
  fn frames_go_only_where_nothing_is() {
    let dir = std::env::temp_dir().join(format!("showreel-frames-{}", std::process::id()));
    let _ = std::fs::remove_dir_all(&dir);
    empty_directory(&dir).unwrap();
    assert!(dir.is_dir(), "a new directory is made");
    empty_directory(&dir).unwrap();
    std::fs::write(dir.join("f00000.png"), b"x").unwrap();
    let e = empty_directory(&dir).unwrap_err();
    assert!(e.message.contains("not empty"), "{}", e.message);
    std::fs::remove_dir_all(&dir).unwrap();
  }
}
