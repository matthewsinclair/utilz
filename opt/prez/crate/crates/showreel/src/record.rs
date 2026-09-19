//! The recording (ST0021): headless Chrome plays the reel on a clock this
//! module controls, and every frame is captured.
//!
//! **THE VIDEO IS THE REEL, BECAUSE THE PLAYER THAT DRAWS IT IS THE ONE THAT
//! SHIPS.** Nothing here lays out a slide or computes an ease. Chrome opens the
//! built HTML as `?noloop&kiosk` and this module decides only WHEN each frame
//! is: CDP's virtual time for the reel's JS, and `clock.js` for its CSS and
//! requestAnimationFrame, both stepped to the same schedule. The spike that
//! chose this route (design.md) measured 510 of 510 frames byte-identical
//! between two real-time paces.
//!
//! **FRAMES ARE ANCHORED ON THE PLAYER'S OWN START.** Frame i is taken at page
//! time `t0 + i x 1000/fps`, where `t0` is the moment the player showed its
//! first slide. Only frame 0 is off that grid: it is taken when the load has
//! settled, and `Recording::late_ms` says how late -- 11 ms on the spike's reel.
//! The spike anchored on the load instead, and every frame carried its 10 ms.
//!
//! **NOTHING IS MATCHED BY NAME, AND NOTHING IS LEFT BEHIND.** Chrome runs under
//! a `/bin/sh` wrapper in a process group of its own, and every exit path ends
//! with a kill of that group alone. The wrapper does not `exec`: it supervises,
//! and its `EXIT` trap removes the temporary directory holding the profile.
//! That covers the one path that runs no Rust at all, an interrupt: the wrapper
//! sees its parent go, ends Chrome itself, and the trap runs after it.

use crate::cdp::Session;
use crate::tail::Tail;
use artifact::{base64, browser, Failure};
use serde::Deserialize;
use serde_json::{json, Value};
use std::fs;
use std::io::ErrorKind;
use std::os::unix::fs::DirBuilderExt;
use std::os::unix::process::CommandExt;
use std::path::{Path, PathBuf};
use std::process::{Child, ChildStdin, Command, Stdio};
use std::time::{Duration, SystemTime, UNIX_EPOCH};

/// The injected clock, embedded as the player is (`template::SHELL`).
const CLOCK: &str = include_str!("../clock.js");

/// How long any one reply may take before the recording is refused.
const WATCHDOG: Duration = Duration::from_secs(30);

/// How long Chrome has to exit after `Browser.close` before its group is killed.
const GRACE: Duration = Duration::from_secs(3);

/// The most page time the load may take, in its 1 ms slices.
const LOAD_SLICES: u32 = 5000;

/// The flags without which a screenshot under paused virtual time stalls at a
/// random frame (the spike's finding 2: frame 63 on one run, 78 on the next).
const DETERMINISTIC: [&str; 5] = [
  "--run-all-compositor-stages-before-draw",
  "--disable-threaded-animation",
  "--disable-threaded-scrolling",
  "--disable-checker-imaging",
  "--disable-new-content-rendering-timeout",
];

/// The supervisor Chrome runs under. `$1` is the recording's temporary
/// directory, and the rest is Chrome's command line. It wires Chrome's fds 3
/// and 4 to this process's pipe, ends Chrome if this process dies, and removes
/// the directory when Chrome is gone.
///
/// **CHROME IS ENDED BY THE WRAPPER, BECAUSE IT DOES NOT RELIABLY END ITSELF.**
/// This wrapper used to run Chrome in the foreground and trust it to exit when
/// its pipe closed. vc measured that trust on b1e2864: 10 of 10 interrupts left
/// Chrome's main process idling in its own shutdown, with the whole profile
/// behind, the first of them still there three minutes later. So:
///
/// - **fds 3 and 4 are taken before the launch**, because a background command
///   gets `/dev/null` as its stdin before its own redirections run.
/// - **The wrapper then gives up its copies** of the pipe, and sends its own
///   stderr to /dev/null. Chrome keeps its copy for this process to read.
///   Otherwise, once this process died, bash would report the kill on a
///   broken pipe and die of SIGPIPE before its trap ran, which vc also caught.
/// - **It watches its own parent**, which changes the moment this process dies,
///   even while it is an unreaped zombie that `kill -0` would still find.
/// - **Then it ends the group, as the shutdown does, from inside it.** Two
///   seconds' grace, then TERM to the whole group, which the wrapper alone
///   ignores, then KILL to Chrome's main process, which is the one that was
///   seen to linger. The trap removes the directory and then KILLs whatever is
///   left of the group, the wrapper with it. Killing only the main process left
///   a helper alive past ten seconds at a load average of 580.
///
/// Every command is named by its path, so a caller's PATH cannot quietly turn
/// the watch off, and an unreadable parent is never read as a departed one.
/// Outside a group of its own, as in this module's tests, `-$$` names no group
/// and the group kills are no-ops.
const WRAPPER: &str = r#"dir=$1; shift
trap 'rm -rf "$dir"; /bin/kill -KILL -- -$$ 2>/dev/null' EXIT
exec 3<&0 4>&1
"$@" 0</dev/null 1>/dev/null &
chrome=$!
exec 0</dev/null 1>/dev/null 2>/dev/null 3<&- 4>&-
trap '' PIPE TERM
parent=$PPID
while kill -0 "$chrome" 2>/dev/null; do
  set -- $(/bin/ps -o ppid= -p $$)
  if [ $# -eq 1 ] && [ "$1" != "$parent" ]; then
    /bin/sleep 2
    /bin/kill -TERM -- -$$ 2>/dev/null
    /bin/sleep 1
    kill -KILL "$chrome" 2>/dev/null
    break
  fi
  /bin/sleep 0.5
done
wait "$chrome"
"#;

/// One captured frame, in the order captured.
pub struct Frame {
  pub index: u64,
  /// How many frames the recording holds.
  pub of: u64,
  /// The page's own time when the frame was taken, in milliseconds.
  pub page_ms: f64,
  /// The slide the player was on.
  pub slide: i64,
  pub png: Vec<u8>,
}

/// What a recording was, for the report.
pub struct Recording {
  pub frames: u64,
  /// The reel's length by the player's own schedule, in milliseconds.
  pub duration_ms: f64,
  /// The player's start, in page milliseconds.
  pub t0_ms: f64,
  /// How long after `t0` frame 0 was taken, in page milliseconds.
  pub late_ms: f64,
  /// The Chrome that recorded it, as it names itself.
  pub chrome: String,
  /// What did not stop the recording but should be said.
  pub warnings: Vec<String>,
}

/// A private directory for one recording. It holds Chrome's profile and its
/// TMPDIR, and the reel's HTML when the caller named only a video (`-o`).
///
/// **IT GOES WHEN THE RECORDING ENDS, ON EVERY PATH.** `record` takes it, and
/// Chrome's shutdown removes it; after an interrupt the wrapper's trap does;
/// and a recording that never started drops it, which removes it too. Created
/// by the caller rather than inside `record`, so that whatever the caller puts
/// in it is covered by the same three.
pub struct Scratch {
  dir: PathBuf,
}

impl Scratch {
  pub fn new() -> Result<Self, Failure> {
    scratch_dir().map(|dir| Self { dir })
  }

  pub fn path(&self) -> &Path {
    &self.dir
  }

  /// Removes the directory, and says so when it cannot.
  fn remove(&self) -> Option<String> {
    match fs::remove_dir_all(&self.dir) {
      Ok(()) => None,
      Err(e) if e.kind() == ErrorKind::NotFound => None,
      Err(e) => Some(format!(
        "could not remove the recording's temporary directory {}: {e}",
        self.dir.display()
      )),
    }
  }
}

impl Drop for Scratch {
  /// The backstop for a recording that never reached Chrome's shutdown, which
  /// is where a directory that will not go is reported.
  fn drop(&mut self) {
    let _ = self.remove();
  }
}

/// Records the reel at `reel` at `width` x `height` and `fps`, in `scratch`,
/// handing each frame to `sink` as it is captured.
pub fn record(
  browser: &Path,
  reel: &Path,
  scratch: Scratch,
  (width, height): (u32, u32),
  fps: u32,
  mut sink: impl FnMut(Frame) -> Result<(), Failure>,
) -> Result<Recording, Failure> {
  let mut chrome = Chrome::launch(browser, width, height, scratch)?;
  let played = play(&mut chrome, reel, (width, height), fps, &mut sink);
  let warnings = chrome.stop(played.is_ok());
  match played {
    Ok(mut recording) => {
      recording.warnings.extend(warnings);
      Ok(recording)
    }
    // Chrome's own account goes with the refusal, and only with a refusal:
    // headless Chrome narrates, and a recording that worked has nothing to say.
    Err(mut failure) => {
      chrome.stderr.append_to(&mut failure, "Chrome");
      for warning in warnings {
        failure.message.push_str("\n  and ");
        failure.message.push_str(&warning);
      }
      Err(failure)
    }
  }
}

/// Everything between the launch and the shutdown.
fn play(
  chrome: &mut Chrome,
  reel: &Path,
  size: (u32, u32),
  fps: u32,
  sink: &mut impl FnMut(Frame) -> Result<(), Failure>,
) -> Result<Recording, Failure> {
  let cdp = &mut chrome.cdp;
  let (name, page) = attach(cdp, size)?;
  let s = Some(page.as_str());
  load(cdp, s, reel)?;

  cdp.step("the schedule");
  let schedule: Schedule = read(
    cdp.evaluate("window.__showreelClock.schedule()", s)?,
    "the schedule",
  )?;
  if schedule.idx != 0 {
    return Err(Failure::new(
      format!(
        "the player was on slide {} when the load finished, not on its first",
        schedule.idx
      ),
      "report it: the recording anchors every frame on the first slide's start",
    ));
  }
  let plan = Plan::new(&schedule, fps)?;
  capture(cdp, s, &plan, sink)?;

  Ok(Recording {
    frames: plan.frames,
    duration_ms: plan.duration_us as f64 / 1000.0,
    t0_ms: plan.t0_us as f64 / 1000.0,
    late_ms: (plan.now_us - plan.t0_us) as f64 / 1000.0,
    chrome: name,
    warnings: Vec::new(),
  })
}

/// A page of its own, at the video's size, with the clock injected before any
/// script of the reel's can run. Returns Chrome's name and the page's session.
fn attach(
  cdp: &mut Session<ChildStdin>,
  (width, height): (u32, u32),
) -> Result<(String, String), Failure> {
  cdp.step("the start");
  let version = cdp.call("Browser.getVersion", json!({}), None)?;
  let name = version["product"]
    .as_str()
    .unwrap_or("an unnamed Chrome")
    .to_string();
  let target = cdp.call("Target.createTarget", json!({ "url": "about:blank" }), None)?;
  let target = field(&target, "targetId", "Target.createTarget")?;
  let attached = cdp.call(
    "Target.attachToTarget",
    json!({ "targetId": target, "flatten": true }),
    None,
  )?;
  let page = field(&attached, "sessionId", "Target.attachToTarget")?;
  let s = Some(page.as_str());
  cdp.call("Page.enable", json!({}), s)?;
  let metrics =
    json!({ "width": width, "height": height, "deviceScaleFactor": 1, "mobile": false });
  cdp.call("Emulation.setDeviceMetricsOverride", metrics, s)?;
  cdp.call(
    "Page.addScriptToEvaluateOnNewDocument",
    json!({ "source": CLOCK }),
    s,
  )?;
  Ok((name, page))
}

/// Opens the reel on a paused clock and lets the load run to its end.
///
/// Paused BEFORE the navigation, so the reel's first moment is virtual. Under a
/// paused clock the load event never fires, so the load runs in 1 ms slices,
/// pausing while a fetch is pending, until it does (finding 1). Then the fonts.
fn load(cdp: &mut Session<ChildStdin>, s: Option<&str>, reel: &Path) -> Result<(), Failure> {
  cdp.step("the load");
  cdp.call(
    "Emulation.setVirtualTimePolicy",
    json!({ "policy": "pause" }),
    s,
  )?;
  let url = format!("{}?noloop&kiosk", browser::file_url(reel));
  let navigated = cdp.call("Page.navigate", json!({ "url": url }), s)?;
  if let Some(error) = navigated.get("errorText").and_then(Value::as_str) {
    return Err(Failure::new(
      format!("Chrome could not open {}: {error}", reel.display()),
      "check the reel's HTML exists and is readable",
    ));
  }
  let mut slices = 0;
  while !cdp.seen("Page.loadEventFired", s) {
    if slices == LOAD_SLICES {
      return Err(Failure::new(
        format!("the reel did not finish loading in {LOAD_SLICES} ms of page time"),
        "open the reel in a browser: a load that never ends there is the defect",
      ));
    }
    let slice = json!({ "policy": "pauseIfNetworkFetchesPending", "budget": 1 });
    cdp.call("Emulation.setVirtualTimePolicy", slice, s)?;
    cdp.event("Emulation.virtualTimeBudgetExpired", s)?;
    slices += 1;
  }
  cdp.step("the fonts");
  cdp.evaluate("document.fonts.ready.then(() => document.fonts.status)", s)?;

  // **THE FIRST ADVANCE AFTER THE LOAD OVERSHOOTS, SO ONE IS SPENT HERE.**
  // Measured on Chrome 153, 19 Sep: the page read 2 ms once loaded, and a first
  // advance of 1, 5, 20 or 98 ms landed at 11, 15, 30 or 108 -- 8 ms past the
  // page's own clock -- while every advance after it landed exactly: 300 frames
  // of 30 fps budgets ended on 10011 ms, 11 + 10000. Spending a 1 ms advance
  // before the page's time is read means nothing is scheduled across the jump.
  cdp.step("the settle");
  let settle = json!({ "policy": "advance", "budget": 1 });
  cdp.call("Emulation.setVirtualTimePolicy", settle, s)?;
  cdp.event("Emulation.virtualTimeBudgetExpired", s)?;
  Ok(())
}

/// Every frame of the plan, each stepped to, ticked, decoded and captured.
fn capture(
  cdp: &mut Session<ChildStdin>,
  s: Option<&str>,
  plan: &Plan,
  sink: &mut impl FnMut(Frame) -> Result<(), Failure>,
) -> Result<(), Failure> {
  let mut page_us = plan.now_us;
  for i in 0..plan.frames {
    let at_us = plan.at_us(i);
    if i > 0 {
      cdp.step(format!("frame {i}: advance"));
      let budget = json!({ "policy": "advance", "budget": budget_ms(at_us - page_us) });
      cdp.call("Emulation.setVirtualTimePolicy", budget, s)?;
      cdp.event("Emulation.virtualTimeBudgetExpired", s)?;
      page_us = at_us;
    }
    cdp.step(format!("frame {i}: tick"));
    let ms = at_us as f64 / 1000.0;
    let tick: Tick = read(
      cdp.evaluate(&format!("window.__showreelClock.tick({ms})"), s)?,
      "a tick",
    )?;
    if tick.broken > 0 {
      return Err(Failure::new(
        format!(
          "{} picture(s) on frame {i} could not be decoded",
          tick.broken
        ),
        "run showreel check on the reel's directory, and rebuild it",
      ));
    }
    cdp.step(format!("frame {i}: screenshot"));
    let shot = cdp.call("Page.captureScreenshot", json!({ "format": "png" }), s)?;
    let data = field(&shot, "data", "Page.captureScreenshot")?;
    let png = base64::decode(&data).map_err(|e| {
      Failure::new(
        format!("frame {i}'s screenshot is not base64: {e}"),
        "report it with Chrome's version",
      )
    })?;
    sink(Frame {
      index: i,
      of: plan.frames,
      page_ms: tick.page,
      slide: tick.slide,
      png,
    })?;
  }
  Ok(())
}

/// What `clock.js` reads off the player once the load is over.
#[derive(Deserialize)]
struct Schedule {
  t0: f64,
  idx: i64,
  now: f64,
  dwells: Vec<f64>,
}

/// What `clock.js` answers for each frame.
#[derive(Deserialize)]
struct Tick {
  page: f64,
  slide: i64,
  broken: u64,
}

/// The frame schedule, in whole microseconds of page time.
///
/// **THE PAGE'S TIMES ARE ROUNDED TO WHOLE MILLISECONDS HERE, AND THAT RECOVERS
/// THEM RATHER THAN APPROXIMATING THEM.** Virtual time moved only in the load's
/// 1 ms slices before this is read, so the player's `t0` and the page's `now`
/// are whole milliseconds, and what Chrome reports is that value plus the
/// jitter it adds to `performance.now()`.
#[derive(Debug)]
struct Plan {
  frames: u64,
  fps: u32,
  duration_us: i64,
  t0_us: i64,
  now_us: i64,
}

impl Plan {
  fn new(schedule: &Schedule, fps: u32) -> Result<Self, Failure> {
    let whole_ms = |ms: f64| (ms.round() as i64) * 1000;
    let duration_us = schedule
      .dwells
      .iter()
      .map(|ms| (ms * 1000.0).round() as i64)
      .sum::<i64>();
    let plan = Self {
      frames: frame_count(duration_us, fps),
      fps,
      duration_us,
      t0_us: whole_ms(schedule.t0),
      now_us: whole_ms(schedule.now),
    };
    if plan.frames == 0 {
      return Err(Failure::new(
        format!(
          "the reel lasts {} ms, which is less than one frame at {fps} fps",
          duration_us / 1000
        ),
        "add slides, or record at a higher --fps",
      ));
    }
    if plan.now_us - plan.t0_us >= plan.at_us(1) - plan.t0_us {
      return Err(Failure::new(
        format!(
          "the reel's load took {} ms of page time, longer than one frame at {fps} fps",
          (plan.now_us - plan.t0_us) / 1000
        ),
        "record at a lower --fps",
      ));
    }
    Ok(plan)
  }

  /// When frame `i` is taken: `t0 + i x 1000/fps`, except frame 0, which is
  /// taken where the load left the page.
  fn at_us(&self, i: u64) -> i64 {
    if i == 0 {
      return self.now_us;
    }
    let fps = i64::from(self.fps);
    let offset = (i as i64 * 1_000_000 * 2 + fps) / (2 * fps);
    self.t0_us + offset
  }
}

/// floor(duration x fps). The reel plays once, so the last frame falls before
/// the player's end-of-reel flash.
fn frame_count(duration_us: i64, fps: u32) -> u64 {
  u64::try_from(duration_us * i64::from(fps) / 1_000_000).unwrap_or(0)
}

/// A virtual-time budget, in the milliseconds CDP takes.
///
/// **A QUARTER OF A MICROSECOND IS ADDED, AND IT IS WHAT KEEPS A LONG REEL ON
/// ITS GRID.** Chrome turns the budget into whole microseconds, and a value such
/// as 33.333 ms can reach it as 33332.99999 of them. Truncated, that is a
/// microsecond lost on most frames at 30 fps: five milliseconds of drift over a
/// three-minute reel, ten times AC-02.2's tolerance. With the quarter added the
/// conversion lands on the intended microsecond whether Chrome truncates or
/// rounds.
fn budget_ms(us: i64) -> f64 {
  (us as f64 + 0.25) / 1000.0
}

/// A running Chrome, and what has to be undone when it stops.
struct Chrome {
  wrapper: Child,
  cdp: Session<ChildStdin>,
  scratch: Scratch,
  stderr: Tail,
  stopped: bool,
}

impl Chrome {
  /// Starts Chrome in `scratch`. When it cannot start, `scratch` is dropped
  /// here, and with it the directory, because nothing is running to need it.
  fn launch(browser: &Path, width: u32, height: u32, scratch: Scratch) -> Result<Self, Failure> {
    let dir = scratch.path();
    let tmp = dir.join("tmp");
    fs::create_dir(&tmp).map_err(|e| {
      Failure::new(
        format!("could not create {}: {e}", tmp.display()),
        "check TMPDIR names a writable directory",
      )
    })?;
    let mut wrapper = Command::new("/bin/sh")
      .arg("-c")
      .arg(WRAPPER)
      .arg("showreel-chrome")
      .arg(dir)
      .arg(browser)
      .args([
        "--headless",
        "--remote-debugging-pipe",
        "--use-mock-keychain",
        "--no-first-run",
        "--no-default-browser-check",
        "--hide-scrollbars",
        "--mute-audio",
      ])
      .arg(format!("--user-data-dir={}", dir.join("profile").display()))
      .arg(format!("--window-size={width},{height}"))
      .args(DETERMINISTIC)
      .arg("about:blank")
      // Chrome's own temporary files land inside the directory the trap and the
      // shutdown remove, rather than beside it where a kill would strand them.
      .env("TMPDIR", &tmp)
      .stdin(Stdio::piped())
      .stdout(Stdio::piped())
      .stderr(Stdio::piped())
      .process_group(0)
      .spawn()
      .map_err(|e| {
        Failure::new(
          format!("could not start {}: {e}", browser.display()),
          "check the browser runs, or name another with --browser",
        )
      })?;
    let (Some(stdin), Some(stdout), Some(stderr)) = (
      wrapper.stdin.take(),
      wrapper.stdout.take(),
      wrapper.stderr.take(),
    ) else {
      let _ = kill_group(wrapper.id());
      let _ = wrapper.wait();
      return Err(Failure::new(
        "Chrome started without the pipes it was given",
        "report it with the platform",
      ));
    };
    Ok(Self {
      wrapper,
      cdp: Session::new(stdin, stdout, WATCHDOG),
      scratch,
      stderr: Tail::read(stderr),
      stopped: false,
    })
  }

  /// Ends Chrome and removes its directory, and returns what could not be
  /// done. After a recording that worked, Chrome is asked to close and given a
  /// grace period; after one that failed, it is killed at once. Either way the
  /// kill of its group is what guarantees the end.
  fn stop(&mut self, gently: bool) -> Vec<String> {
    if self.stopped {
      return Vec::new();
    }
    self.stopped = true;
    let mut warnings = Vec::new();
    if gently {
      self.cdp.step("the shutdown");
      if self.cdp.send("Browser.close", json!({}), None).is_ok() {
        self.cdp.closes_within(GRACE);
      }
    }
    // Before the wrapper is reaped, because its pid is the group's id and
    // cannot be given to another process until then (issue 0030's trap).
    if let Err(e) = kill_group(self.wrapper.id()) {
      warnings.push(format!(
        "could not run /bin/kill for Chrome's process group {}: {e}",
        self.wrapper.id()
      ));
    }
    if let Err(e) = self.wrapper.wait() {
      warnings.push(format!("could not wait for Chrome's wrapper: {e}"));
    }
    warnings.extend(self.scratch.remove());
    warnings
  }
}

impl Drop for Chrome {
  /// The backstop for a path that never reached `stop`: a panic in a test.
  fn drop(&mut self) {
    self.stop(false);
  }
}

/// Kills a process group: Chrome and everything it started. kill(1) rather
/// than a call, because std has none that signals a group. Its exit status is
/// not read: it fails when the group has already gone, which is the end of a
/// clean close. Failing to RUN is the error.
fn kill_group(pgid: u32) -> std::io::Result<()> {
  Command::new("/bin/kill")
    .args(["-KILL", "--", &format!("-{pgid}")])
    .stdout(Stdio::null())
    .stderr(Stdio::null())
    .status()
    .map(|_| ())
}

/// Creates a directory no other process can read, under TMPDIR, for one
/// recording.
fn scratch_dir() -> Result<PathBuf, Failure> {
  let base = std::env::temp_dir();
  let stamp = SystemTime::now()
    .duration_since(UNIX_EPOCH)
    .map(|d| d.subsec_nanos())
    .unwrap_or(0);
  for n in 0..100 {
    let dir = base.join(format!("showreel-video-{}-{stamp}-{n}", std::process::id()));
    match fs::DirBuilder::new().mode(0o700).create(&dir) {
      Ok(()) => return Ok(dir),
      Err(e) if e.kind() == ErrorKind::AlreadyExists => continue,
      Err(e) => {
        return Err(Failure::new(
          format!(
            "could not create a temporary directory in {}: {e}",
            base.display()
          ),
          "check TMPDIR names a writable directory",
        ))
      }
    }
  }
  Err(Failure::new(
    format!(
      "could not find a free temporary directory name in {}",
      base.display()
    ),
    "clear old showreel-video-* directories out of it",
  ))
}

/// A string field of a reply that the recording cannot go on without.
fn field(reply: &Value, key: &str, method: &str) -> Result<String, Failure> {
  reply
    .get(key)
    .and_then(Value::as_str)
    .map(str::to_string)
    .ok_or_else(|| {
      Failure::new(
        format!("Chrome's reply to {method} carried no {key}"),
        "report it with Chrome's version",
      )
    })
}

/// A value from `clock.js`, in the shape the recording expects.
fn read<T: serde::de::DeserializeOwned>(value: Value, what: &str) -> Result<T, Failure> {
  serde_json::from_value(value).map_err(|e| {
    Failure::new(
      format!("the reel's page answered {what} in an unexpected shape: {e}"),
      "report it: clock.js and player.html have drifted apart",
    )
  })
}

#[cfg(test)]
mod tests {
  use super::*;

  fn schedule(t0: f64, now: f64, dwells: &[f64]) -> Schedule {
    Schedule {
      t0,
      idx: 0,
      now,
      dwells: dwells.to_vec(),
    }
  }

  #[test]
  fn the_frame_count_is_the_floor_of_duration_times_fps() {
    assert_eq!(frame_count(15_000_000, 10), 150);
    assert_eq!(frame_count(17_000_000, 30), 510);
    assert_eq!(frame_count(2_550_000, 30), 76, "76.5 frames is 76");
    assert_eq!(frame_count(0, 30), 0);
  }

  /// AC-02.2: frame i is at t0 + i x 1000/fps, and only frame 0 is off the
  /// grid, where the load left the page.
  #[test]
  fn frames_sit_on_the_player_s_own_grid_and_frame_0_where_the_load_left_it() {
    let plan = Plan::new(&schedule(0.03, 10.04, &[2500.0; 6]), 10).unwrap();
    assert_eq!(plan.t0_us, 0, "the jitter is rounded off");
    assert_eq!(plan.at_us(0), 10_000, "frame 0 is where the load ended");
    assert_eq!(plan.at_us(1), 100_000);
    assert_eq!(plan.at_us(25), 2_500_000);
    assert_eq!(plan.frames, 150);
  }

  #[test]
  fn a_grid_that_is_not_whole_microseconds_does_not_drift() {
    let plan = Plan::new(&schedule(0.0, 10.0, &[180_000.0]), 30).unwrap();
    assert_eq!(plan.frames, 5400);
    // Every target is the nearest microsecond to i x 1000/30, however far in.
    assert_eq!(plan.at_us(1), 33_333);
    assert_eq!(plan.at_us(2), 66_667);
    assert_eq!(plan.at_us(5399), 179_966_667);
  }

  #[test]
  fn a_budget_reaches_chrome_as_the_intended_microsecond() {
    for us in [1, 33_333, 33_334, 66_667, 100_000, 142_857] {
      let ms = budget_ms(us);
      assert_eq!((ms * 1000.0) as i64, us, "truncated: {ms}");
      assert_eq!((ms * 1000.0).round() as i64, us, "rounded: {ms}");
    }
  }

  #[test]
  fn a_reel_shorter_than_a_frame_is_refused() {
    let e = Plan::new(&schedule(0.0, 1.0, &[20.0]), 10).unwrap_err();
    assert!(e.message.contains("less than one frame"), "{}", e.message);
  }

  #[test]
  fn a_load_longer_than_a_frame_is_refused() {
    let e = Plan::new(&schedule(0.0, 20.0, &[2500.0]), 60).unwrap_err();
    assert!(
      e.message.contains("longer than one frame at 60 fps"),
      "{}",
      e.message
    );
  }

  /// clock.js reads four names off player.html's top level. A rename there
  /// fails here rather than in the middle of somebody's recording.
  #[test]
  fn the_player_still_declares_every_name_the_clock_reads() {
    for name in ["t0", "idx", "slides", "dwellOf"] {
      let declared = regex::Regex::new(&format!(r"(?m)^(?:const|let)\b[^;]*\b{name}\s*=")).unwrap();
      assert!(
        declared.is_match(crate::template::SHELL),
        "player.html no longer declares {name} at its top level"
      );
      assert!(CLOCK.contains(name), "clock.js no longer reads {name}");
    }
  }

  /// The trap is what removes the profile after an interrupt, when no Rust
  /// runs. Here the thing it waits for is `true`, which exits at once.
  #[test]
  fn the_wrapper_removes_its_directory_when_what_it_ran_exits() {
    let dir = scratch_dir().unwrap();
    fs::write(dir.join("profile-file"), b"x").unwrap();
    let status = Command::new("/bin/sh")
      .arg("-c")
      .arg(WRAPPER)
      .arg("showreel-chrome")
      .arg(&dir)
      .arg("/usr/bin/true")
      .stdin(Stdio::null())
      .stdout(Stdio::null())
      .status()
      .unwrap();
    assert!(status.success());
    assert!(!dir.exists(), "{} survived its wrapper", dir.display());
  }

  /// AC-02.5's interrupt, without Chrome: the wrapper's parent dies holding a
  /// child that will not exit by itself, and the wrapper ends the child and
  /// removes its directory. `sleep 60` stands in for Chrome that stays in its
  /// own shutdown, which is what vc measured Chrome doing.
  #[test]
  fn the_wrapper_ends_what_it_runs_when_its_parent_dies_and_removes_its_directory() {
    let dir = scratch_dir().unwrap();
    fs::write(dir.join("profile-file"), b"x").unwrap();
    let mut parent = Command::new("/bin/sh")
      .arg("-c")
      .arg(r#"/bin/sh -c "$0" showreel-chrome "$1" /bin/sleep 60 & wait"#)
      .arg(WRAPPER)
      .arg(&dir)
      .stdin(Stdio::null())
      .stdout(Stdio::null())
      .spawn()
      .unwrap();
    std::thread::sleep(Duration::from_millis(500));
    parent.kill().unwrap();
    parent.wait().unwrap();
    let began = std::time::Instant::now();
    while dir.exists() && began.elapsed() < Duration::from_secs(15) {
      std::thread::sleep(Duration::from_millis(100));
    }
    assert!(
      !dir.exists(),
      "{} outlived its wrapper's parent by 15 s",
      dir.display()
    );
  }
}
