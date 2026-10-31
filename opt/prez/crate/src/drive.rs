// Driving an installed browser, for `pdf` and `present`.
//
// **PREZ DOES NOT PRESENT AND DOES NOT RENDER** (hv's anti-requirement, spec
// 6). It has no server, no viewer and no layout engine of its own. What it has
// is a file and the ability to hand that file to something that already knows
// how to draw it. This module is that handoff and nothing more.
//
// **WHICH browser is found is not decided here.** `artifact::browser::find` is
// the one finder, shared with showreel's `video` (ST0021 AC-01.1), so the probe
// order and the refusal that lists every path tried live there. So does
// `file_url`, the address both tools hand a browser a file by.

use crate::html;
use crate::Failure;
use artifact::browser;
use artifact::partial::{partial_of, remove_partial};
use std::fs::File;
use std::path::{Path, PathBuf};
use std::process::{Child, Command, ExitStatus, Stdio};
use std::time::{Duration, Instant};

/// How long one print may take before Chrome is killed and the print refused
/// (issue 0131).
///
/// **A PRINT CAN HANG, AND NOTHING ELSE BOUNDS IT.** On CI's macOS leg at
/// 2.14.8's tag, AT21's first two prints took 1.9 s and 1.8 s, and its third
/// never returned: the leg sat for 17 minutes until it was cancelled by hand.
/// 120 s is sixty times that print, and far past the 5 s of page time
/// `--virtual-time-budget` gives it.
const PRINT_DEADLINE: Duration = Duration::from_secs(120);

/// How long a killed Chrome has to be reaped before the refusal says it is
/// still running. A killed process is gone in milliseconds unless it is stuck
/// in the kernel, and then the refusal says so rather than wait on it.
const REAP_GRACE: Duration = Duration::from_secs(5);

/// How often a wait looks at Chrome.
const POLL: Duration = Duration::from_millis(20);

/// What a person does about a print that stalled. The suites do it once on
/// their behalf, keyed on the words of the refusal that carries it
/// (lib/harness.sh, `stalled`), so a change to them is a change there too.
const STALLED: &str = "run it again; if it stalls twice, report it with Chrome's version";

/// Print an artifact to PDF through headless Chrome, keeping what Chrome says
/// in `log`.
///
/// `slides` is what the compiler produced, and it is checked against what came
/// back. See `verify_pagination` for why that check exists.
pub fn print_to_pdf(
  browser: &Path,
  artifact: &Path,
  out: &Path,
  log: &Path,
  slides: usize,
) -> Result<Vec<String>, Failure> {
  print_within(browser, artifact, out, log, slides, PRINT_DEADLINE)
}

/// `print_to_pdf` with its deadline given, so a test can give a short one.
///
/// **A REFUSED PRINT NEVER TOUCHES `out`** (issue 0131). Chrome prints to
/// `<out>.partial` beside it, which becomes `out` only when Chrome exits 0
/// having written it, so what a refused print leaves can never be read as its
/// PDF, by a person or by a suite's retry. showreel's videos work the same
/// way: no partial ever looks finished.
fn print_within(
  browser: &Path,
  artifact: &Path,
  out: &Path,
  log: &Path,
  slides: usize,
  deadline: Duration,
) -> Result<Vec<String>, Failure> {
  let partial = partial_of(out);
  // A partial an interrupted run left is not this run's, and Chrome is not
  // relied on to write over it.
  if let Some(message) = remove_partial(&partial) {
    return Err(Failure::new(
      format!("{message}, which an earlier print left"),
      "remove it by hand, and run it again",
    ));
  }
  let printed = print_into(browser, artifact, out, &partial, log, deadline)
    .and_then(|()| finish(&partial, out));
  match printed {
    Ok(()) => Ok(verify_pagination(out, slides)),
    Err(mut failure) => {
      if let Some(message) = remove_partial(&partial) {
        failure.message = format!("{}\n  and {message}", failure.message);
      }
      Err(failure)
    }
  }
}

/// Puts a finished print where it was asked for, in one rename beside it, so
/// `out` is the PDF it was or the whole new one, and never a part of one.
fn finish(partial: &Path, out: &Path) -> Result<(), Failure> {
  std::fs::rename(partial, out).map_err(|e| {
    Failure::new(
      format!(
        "could not move the print from '{}' to '{}': {e}",
        partial.display(),
        out.display()
      ),
      "check the -o path is writable",
    )
  })
}

/// Runs Chrome's print of `artifact` into `partial`, and refuses unless Chrome
/// exited 0 having written it. `out` is named in a refusal and never written.
fn print_into(
  browser: &Path,
  artifact: &Path,
  out: &Path,
  partial: &Path,
  log: &Path,
  deadline: Duration,
) -> Result<(), Failure> {
  let mut chrome = launch(browser, artifact, partial, log)?;
  let status = match wait_within(&mut chrome, deadline) {
    Ok(Some(status)) => status,
    Ok(None) => return Err(abandon(&mut chrome, browser, out, log, deadline)),
    // The pid may no longer be Chrome's, so it is said and nothing is
    // signalled, as showreel's ffmpeg does (video.rs, stop_ffmpeg).
    Err(e) => {
      return Err(Failure::new(
        format!(
          "could not ask whether '{}' had finished printing: {e}; it may still be running as pid {}, unsignalled:\n{}",
          browser.display(),
          chrome.id(),
          said(log)
        ),
        "run it again",
      ))
    }
  };
  if !status.success() {
    return Err(Failure::new(
      format!(
        "'{}' failed while printing (exit {}):\n{}",
        browser.display(),
        code(&status),
        said(log)
      ),
      "try opening the built .html in that browser to see what it objects to",
    ));
  }
  if !partial.is_file() {
    // Chrome exits 0 having written nothing often enough that trusting the exit
    // code alone would report a success with no PDF behind it.
    return Err(Failure::new(
      format!(
        "the browser reported success but wrote no PDF at '{}'",
        out.display()
      ),
      "check the -o path is writable, or try --browser with a different browser",
    ));
  }
  Ok(())
}

/// Starts Chrome's print of `artifact` into `pdf`, with its stdout and stderr
/// both in `log`.
///
/// **CHROME'S OUTPUT GOES TO A FILE, NOT TO PIPES** (issue 0131). Headless
/// Chrome narrates ("86974 bytes written to file", allocator notices) and the
/// user asked prez for a PDF, not for a browser's log, so it is kept, and
/// replayed in full only when the print fails, which is the only moment it is
/// worth reading. It used to be captured on pipes, and a pipe is read to its
/// end only once every process holding it has gone: a helper Chrome left
/// behind held prez with it, and nothing bounded that wait. A file needs no
/// reader, so the wait is on Chrome's main process alone.
///
/// **CHROME STAYS IN prez's PROCESS GROUP**, so Ctrl-C at the terminal reaches
/// it as it reaches prez. In a group of its own, an interrupted print would
/// leave Chrome running with nothing to bound it (critic-rust, on 0131's v1).
fn launch(browser: &Path, artifact: &Path, pdf: &Path, log: &Path) -> Result<Child, Failure> {
  let unwritable = |e: std::io::Error| {
    Failure::new(
      format!(
        "could not open '{}' for the browser's output: {e}",
        log.display()
      ),
      "check that the temporary directory is writable",
    )
  };
  let stdout = File::create(log).map_err(unwritable)?;
  let stderr = stdout.try_clone().map_err(unwritable)?;
  // --virtual-time-budget gives the page a moment to lay out and, when the deck
  // opted into mermaid, to draw its diagrams. Without it a diagram-heavy deck
  // prints its fences as empty boxes.
  Command::new(browser)
    .arg("--headless")
    .arg("--disable-gpu")
    // Chrome's first-run experience is an interactive modal, and every launch
    // here meets a profile it has never seen, so it fires every time. Refuse it
    // rather than ask a human a question from inside a print pipeline.
    .arg("--no-first-run")
    .arg("--no-default-browser-check")
    .arg("--no-pdf-header-footer")
    .arg("--virtual-time-budget=5000")
    .arg(format!("--print-to-pdf={}", pdf.display()))
    .arg(browser::file_url(artifact))
    .stdin(Stdio::null())
    .stdout(stdout)
    .stderr(stderr)
    .spawn()
    .map_err(|e| {
      Failure::new(
        format!("could not run '{}': {e}", browser.display()),
        "check the browser path, or name another with --browser",
      )
    })
}

/// Waits up to `deadline` for `child` to exit, and returns how it exited, or
/// `None` when it is still running: found running, and so not yet reaped.
fn wait_within(child: &mut Child, deadline: Duration) -> std::io::Result<Option<ExitStatus>> {
  let until = Instant::now() + deadline;
  loop {
    if let Some(status) = child.try_wait()? {
      return Ok(Some(status));
    }
    if Instant::now() >= until {
      return Ok(None);
    }
    std::thread::sleep(POLL);
  }
}

/// Ends a print that outran its deadline, and refuses it, naming the deadline
/// and the PDF, with what Chrome had said by then.
///
/// **CHROME IS KILLED WHILE IT IS UNREAPED**: found running at the deadline,
/// its pid is still Chrome's, so the kill cannot reach another process (issue
/// 0030's trap is a pid signalled after its reap). It is then reaped within
/// `REAP_GRACE`, and the refusal says it is still running if the grace runs
/// out: no wait here is unbounded. Only the main process is killed; a helper
/// it started holds only the log, which nothing waits on.
fn abandon(
  chrome: &mut Child,
  browser: &Path,
  out: &Path,
  log: &Path,
  deadline: Duration,
) -> Failure {
  let mut also = Vec::new();
  if let Err(e) = chrome.kill() {
    also.push(format!("could not kill it: {e}"));
  }
  match wait_within(chrome, REAP_GRACE) {
    Ok(Some(_)) => {}
    Ok(None) => also.push(format!("it is still running as pid {}", chrome.id())),
    Err(e) => also.push(format!(
      "could not ask whether it had ended, and it may still be running as pid {}: {e}",
      chrome.id()
    )),
  }
  let mut message = format!(
    "'{}' did not finish printing '{}' in {} s:\n{}",
    browser.display(),
    out.display(),
    deadline.as_secs_f64(),
    said(log)
  );
  for line in also {
    message.push_str("\n  and ");
    message.push_str(&line);
  }
  Failure::new(message, STALLED)
}

/// What Chrome wrote to its log, or why that cannot be read.
fn said(log: &Path) -> String {
  match std::fs::read(log) {
    Ok(bytes) => String::from_utf8_lossy(&bytes).into_owned(),
    Err(e) => format!(
      "(its output could not be read from '{}': {e})",
      log.display()
    ),
  }
}

/// Check that the PDF has one page per slide, and say so when it does not.
///
/// **THIS IS HERE BECAUSE THE BASE PRINT RULES CAN BE DEFEATED AND I CLAIMED
/// THEY COULD NOT** (vc falsified it, 28 Aug 2026). Emitting the page-break
/// rules after the theme beats an ordinary theme declaration, but it does not
/// beat `!important` at equal specificity: a theme carrying
/// `height: auto !important` inside `@media print` collapses six slides onto
/// four pages. That is a plausible ACCIDENT rather than an attack -- an author
/// writes it to fix on-screen layout and has no idea it merged the PDF -- and
/// the failure is silent, because a shorter PDF looks exactly like a shorter
/// deck.
///
/// The alternative was an `!important` arms race against themes prez does not
/// control, which would also have frozen print height for themes with a
/// legitimate reason to set it. Counting the pages instead is a control that CAN
/// go red, and it catches collapse causes neither of us has thought of, which an
/// arms race by construction cannot.
fn verify_pagination(pdf: &Path, slides: usize) -> Vec<String> {
  let Ok(bytes) = std::fs::read(pdf) else {
    return vec![format!(
      "could not re-read '{}' to check its page count",
      pdf.display()
    )];
  };
  match page_count(&bytes) {
    Some(pages) if pages == slides => Vec::new(),
    Some(pages) => vec![format!(
      "{slides} slides compiled but the PDF has {pages} pages: a theme rule is defeating \
       one-slide-per-page (commonly 'height: auto !important' inside @media print)"
    )],
    // A check that cannot run says so. Passing silently is the failure mode this
    // whole function exists to close.
    None => vec![format!(
      "could not read a page count from '{}', so one-slide-per-page went unverified",
      pdf.display()
    )],
  }
}

/// Count `/Type /Page` objects, which is what a PDF page is.
///
/// `None` means the count could not be read: a valid PDF has at least one page,
/// so zero means this failed rather than that the document is empty.
fn page_count(pdf: &[u8]) -> Option<usize> {
  const TYPE: &[u8] = b"/Type";
  const PAGE: &[u8] = b"/Page";
  let mut count = 0usize;
  let mut i = 0usize;

  while i + TYPE.len() <= pdf.len() {
    if &pdf[i..i + TYPE.len()] != TYPE {
      i += 1;
      continue;
    }
    let mut j = i + TYPE.len();
    while j < pdf.len() && pdf[j].is_ascii_whitespace() {
      j += 1;
    }
    if pdf[j..].starts_with(PAGE) {
      // `/Pages` is the tree node, not a page.
      let next = pdf.get(j + PAGE.len());
      if next.is_none_or(|byte| !byte.is_ascii_alphanumeric()) {
        count += 1;
      }
    }
    i = j.max(i + 1);
  }
  (count > 0).then_some(count)
}

/// The presenting window, in device-independent pixels.
///
/// **A DECK HAS A DESIGNED SHAPE AND PRESENTING IS THE ONE PATH THAT USED TO
/// IGNORE IT.** `pdf` has laid its pages out at `html::DEFAULT_PAPER` --
/// 254 x 142.9 mm, exactly 16:9 -- since it existed, while `present` set no
/// geometry at all and inherited whatever Chrome last remembered. hv got a
/// PORTRAIT window for a 16:9 deck, which is not a bad default; it is the
/// absence of one.
///
/// 1280 x 720 is that same 16:9 at a size that fits a laptop screen with room
/// for the OS chrome. It is derived rather than typed: DEFAULT_ASPECT comes off
/// the paper default, so the two cannot drift into disagreeing about what shape
/// a deck is.
pub const DEFAULT_WINDOW_WIDTH: u32 = 1280;

/// The deck's aspect, read off the same constant `pdf` lays pages out at.
fn default_window() -> (u32, u32) {
  let (w, h) = html::DEFAULT_PAPER
    .split_once(' ')
    .map(|(w, h)| (w.trim_end_matches("mm"), h.trim_end_matches("mm")))
    .unwrap_or(("16", "9"));
  let ratio = match (w.parse::<f64>(), h.parse::<f64>()) {
    (Ok(w), Ok(h)) if w > 0.0 && h > 0.0 => h / w,
    _ => 9.0 / 16.0,
  };
  (
    DEFAULT_WINDOW_WIDTH,
    (f64::from(DEFAULT_WINDOW_WIDTH) * ratio).round() as u32,
  )
}

/// Parse `--window WxH` into pixels.
///
/// Mirrors `--paper`'s grammar deliberately -- same `x`, same trimming, same
/// shape of refusal -- because someone who has learned one flag should not have
/// to learn the other. The UNIT differs and the refusal says so: a window is
/// pixels, a page is millimetres.
pub fn window_size(spec: Option<&str>) -> Result<(u32, u32), Failure> {
  let Some(spec) = spec else {
    return Ok(default_window());
  };
  let refuse = || {
    Failure::new(
      format!("--window '{spec}' is not a window size"),
      "give width x height in pixels, eg --window 1280x720",
    )
  };
  let (w, h) = spec.split_once(['x', 'X']).ok_or_else(refuse)?;
  let (w, h) = (
    w.trim().parse::<u32>().map_err(|_| refuse())?,
    h.trim().parse::<u32>().map_err(|_| refuse())?,
  );
  if w == 0 || h == 0 {
    return Err(refuse());
  }
  Ok((w, h))
}

/// The exact argv the presenting launch uses.
///
/// **SPLIT OUT SO IT CAN BE ASSERTED WITHOUT LAUNCHING ANYTHING**, which is the
/// only place a silently-dropped flag is catchable. `--start-fullscreen` was
/// passed on every launch for as long as this function existed and never took
/// effect; nothing in the process, the exit status or the logs said so, and it
/// took a screenshot of a portrait window to find. A browser test cannot see
/// the difference between a flag that was not sent and one that was ignored --
/// only the argv can.
pub fn presenting_argv(artifact: &Path, width: u32, height: u32) -> Vec<String> {
  vec![
    format!("--app={}", browser::file_url(artifact)),
    format!("--window-size={width},{height}"),
    "--new-window".to_string(),
    // See the headless path above: the first-run panel is a modal, and it
    // lands in front of the deck this is opening.
    "--no-first-run".to_string(),
    "--no-default-browser-check".to_string(),
  ]
}

/// Launch the artifact for presenting, then return so prez can exit.
pub fn open_presenting(
  explicit: Option<&str>,
  artifact: &Path,
  window: Option<&str>,
) -> Result<(), Failure> {
  let (w, h) = window_size(window)?;
  // `--app` drops the tab strip, the address bar and the bookmarks -- the
  // difference between a presentation and a browser window with slides in it.
  //
  // **`--start-fullscreen` USED TO BE HERE AND IS GONE ON PURPOSE.** It was
  // passed on every launch and demonstrably did not take: hv's window came up
  // with traffic lights on it, in portrait. Chrome does not honour it for an
  // `--app` window on macOS, and it fails SILENTLY -- no warning, no error,
  // nothing in the exit status -- which is precisely the class this thread has
  // been removing from the harness, pointed at the tool instead.
  //
  // Deleted rather than fixed, because there is nothing to fix: the flag has no
  // working form here. What replaces it is a window that is the right SHAPE,
  // plus `f` in the runtime for a fullscreen the browser actually performs and
  // the key bar actually advertises. A flag nobody can observe working is worse
  // than an honest key.
  let no_browser = match browser::find(explicit) {
    Ok(found) => {
      let mut command = Command::new(&found);
      command.args(presenting_argv(artifact, w, h));
      return spawn(&mut command, &found.display().to_string());
    }
    Err(refusal) => refusal,
  };
  if explicit.is_some() {
    // A named browser that could not be found is an error, never a fallback.
    return Err(no_browser);
  }

  // No Chromium anywhere: hand it to the platform's opener. The deck still
  // presents, just with the browser's own chrome around it and `f` to fill
  // the screen. The platform is read here, once, so the choice below is a
  // plain function of it and is tested for both on either (issue 0083).
  let (opener, path) = fallback_opener(std::env::consts::OS, artifact::path::on_path, no_browser)?;
  eprintln!("prez: warning: no Chromium-family browser found; opening with {opener}, so the window will not be de-chromed");
  spawn(Command::new(&path).arg(artifact), opener)
}

/// The opener `present` falls back to when no browser is found, or the
/// refusal when there is none (issue 0083).
///
/// **`open` IS macOS's, NOT EVERYONE'S.** `present` spawned `open` on every
/// platform, so on Linux it reached no opener -- or Debian's `open`, a link to
/// `openvt` -- and failed at the exec with "could not launch 'open'", if at
/// all. Elsewhere the opener is `xdg-open`. Each is looked up with `lookup`,
/// which `present` passes as `on_path`; a test passes its own, since the
/// artifact crate's tests empty PATH while they run.
///
/// With no opener either, the refusal is the finder's, extended: its list of
/// every path it probed and its remedy, each with the opener added, and its
/// exit code. So the browsers it names have one home, the finder.
fn fallback_opener(
  os: &str,
  lookup: impl Fn(&str) -> Option<PathBuf>,
  no_browser: Failure,
) -> Result<(&'static str, PathBuf), Failure> {
  let opener = if os == "macos" { "open" } else { "xdg-open" };
  match lookup(opener) {
    Some(path) => Ok((opener, path)),
    None => Err(Failure {
      message: format!(
        "{}\n  and no '{opener}' on PATH to open the deck with",
        no_browser.message
      ),
      remedy: Some(match no_browser.remedy {
        Some(remedy) => format!("{remedy}, or put {opener} on PATH"),
        None => format!("put {opener} on PATH"),
      }),
      code: no_browser.code,
    }),
  }
}

fn spawn(command: &mut Command, what: &str) -> Result<(), Failure> {
  // THE BROWSER'S OUTPUT IS DISCARDED, and it is noise rather than diagnostics.
  //
  // prez hands over and exits, so the launched process outlives it and writes
  // to the terminal WHENEVER IT LIKES -- which in practice is after the shell
  // has already drawn the next prompt. Chrome greets a running instance with
  // "Opening in existing browser session." and it lands under the prompt,
  // looking like output from whatever the user types next. It is unreadable as
  // a diagnostic and it belongs to a process nobody is waiting on.
  //
  // Nothing is lost by dropping it: prez never reads these streams, cannot
  // wait for them without breaking the anti-requirement that it gets out of the
  // way, and would have exited long before anything interesting arrived. A
  // failure to LAUNCH is still a named Failure below -- that is the part with a
  // remedy attached, and it is the part that happens while prez is still here.
  command
    .stdin(Stdio::null())
    .stdout(Stdio::null())
    .stderr(Stdio::null())
    .spawn()
    .map(|_| ())
    .map_err(|e| {
      Failure::new(
        format!("could not launch '{what}': {e}"),
        "name a browser with --browser PATH",
      )
    })
}

fn code(status: &std::process::ExitStatus) -> String {
  status
    .code()
    .map_or_else(|| "signal".to_string(), |c| c.to_string())
}

#[cfg(test)]
mod tests {
  use super::*;

  // ---- issue 0083: the opener is the platform's, or a refusal by name ------

  fn finder_refusal() -> Failure {
    Failure::new(
      "no Chromium-family browser found. Probed:\n    /Applications/Google Chrome.app\n    chromium (on PATH)",
      "install Chrome, Chromium, Edge or Brave, or name one with --browser PATH",
    )
  }

  /// A PATH holding only `names`, each at /usr/bin/<name>.
  fn path_with(names: &'static [&'static str]) -> impl Fn(&str) -> Option<PathBuf> {
    move |name| {
      names
        .contains(&name)
        .then(|| PathBuf::from(format!("/usr/bin/{name}")))
    }
  }

  #[test]
  fn on_macos_the_opener_is_open() {
    let (opener, path) =
      fallback_opener("macos", path_with(&["open", "xdg-open"]), finder_refusal())
        .expect("open is on PATH");
    assert_eq!(opener, "open");
    assert_eq!(path, PathBuf::from("/usr/bin/open"));
  }

  #[test]
  fn off_macos_the_opener_is_xdg_open_even_where_an_open_exists() {
    // Debian's /usr/bin/open is openvt, which is no way to open a deck.
    let (opener, path) =
      fallback_opener("linux", path_with(&["open", "xdg-open"]), finder_refusal())
        .expect("xdg-open is on PATH");
    assert_eq!(opener, "xdg-open");
    assert_eq!(path, PathBuf::from("/usr/bin/xdg-open"));
  }

  #[test]
  fn off_macos_with_no_xdg_open_it_refuses_by_name_keeping_the_probe_list() {
    let refusal = fallback_opener("linux", path_with(&["open"]), finder_refusal())
      .expect_err("with no xdg-open on PATH, present refuses");
    assert_eq!(refusal.code, 2);
    assert!(
      refusal.message.contains("chromium (on PATH)"),
      "the finder's probe list is kept: {}",
      refusal.message
    );
    assert!(
      refusal
        .message
        .ends_with("and no 'xdg-open' on PATH to open the deck with"),
      "{}",
      refusal.message
    );
    assert_eq!(
      refusal.remedy.as_deref(),
      Some("install Chrome, Chromium, Edge or Brave, or name one with --browser PATH, or put xdg-open on PATH")
    );
  }

  #[test]
  fn on_macos_with_no_open_it_refuses_naming_open() {
    let refusal = fallback_opener("macos", path_with(&[]), finder_refusal())
      .expect_err("with no open on PATH, present refuses");
    assert_eq!(refusal.code, 2);
    assert!(
      refusal
        .message
        .ends_with("and no 'open' on PATH to open the deck with"),
      "{}",
      refusal.message
    );
    assert_eq!(
      refusal.remedy.as_deref(),
      Some("install Chrome, Chromium, Edge or Brave, or name one with --browser PATH, or put open on PATH")
    );
  }

  // ---- AC19: the presenting window has a shape -----------------------------

  #[test]
  fn the_default_window_is_the_deck_s_own_aspect() {
    // Derived from html::DEFAULT_PAPER rather than typed here, so `pdf` and
    // `present` cannot drift into disagreeing about what shape a deck is.
    let (w, h) = default_window();
    let ratio = f64::from(w) / f64::from(h);
    assert!(
      (ratio - 254.0 / 142.9).abs() < 0.01,
      "{w}x{h} is {ratio}, not the deck's aspect"
    );
  }

  #[test]
  fn window_mirrors_paper_s_grammar_and_says_pixels_when_refusing() {
    assert_eq!(window_size(Some("1920x1080")).unwrap(), (1920, 1080));
    assert_eq!(window_size(Some("1920X1080")).unwrap(), (1920, 1080));
    assert_eq!(window_size(Some(" 800 x 600 ")).unwrap(), (800, 600));
    let e = window_size(Some("wide")).unwrap_err();
    assert!(e.message.contains("not a window size"), "{}", e.message);
    // The UNIT is the one thing that differs from --paper, so the remedy has to
    // say it: copying --paper's "millimetres" here would be a plausible,
    // wrong sentence.
    assert!(
      e.remedy.as_deref().unwrap().contains("pixels"),
      "{:?}",
      e.remedy
    );
    assert!(
      window_size(Some("0x600")).is_err(),
      "a zero dimension is not a window"
    );
  }

  #[test]
  fn no_window_flag_means_the_deck_s_shape_not_whatever_chrome_remembered() {
    assert_eq!(window_size(None).unwrap(), default_window());
  }

  // ---- AT18's argv half ----------------------------------------------------

  #[test]
  fn the_presenting_argv_carries_the_geometry_and_no_inert_flag() {
    let argv = presenting_argv(Path::new("/tmp/deck.html"), 1280, 720);

    // PRESENCE, which is the easy half.
    assert!(
      argv.iter().any(|a| a == "--window-size=1280,720"),
      "{argv:?}"
    );
    assert!(argv.iter().any(|a| a.starts_with("--app=")), "{argv:?}");

    // AND ABSENCE, which is the half that matters. A build that kept
    // --start-fullscreen beside a working --window-size would pass a check
    // that only looked for the new flag, and the inert flag would live on
    // forever behind a green. It never worked here and nothing ever said so.
    assert!(
      !argv.iter().any(|a| a == "--start-fullscreen"),
      "--start-fullscreen is inert for an --app window and must not be sent: {argv:?}"
    );
  }

  // The browser-discovery tests (AC06's negative half, and the refusal that
  // lists every path tried) moved with the finder to artifact::browser, and the
  // file-URL test moved there with file_url (ST0021 WP-02).

  #[test]
  fn page_count_reads_pages_and_ignores_the_pages_tree_node() {
    let pdf = b"<</Type /Pages /Count 2>> <</Type /Page>> <</Type/Page>>";
    assert_eq!(page_count(pdf), Some(2));
  }

  #[test]
  fn page_count_reports_failure_rather_than_zero() {
    // A valid PDF has at least one page, so a zero count means the scan failed
    // and the caller must be told rather than shown a confident 0.
    assert_eq!(page_count(b"not a pdf at all"), None);
    assert_eq!(page_count(b"<</Type /Pages /Count 6>>"), None);
  }

  #[test]
  fn a_pdf_shorter_than_the_deck_is_reported_with_the_usual_cause() {
    let dir = artifact::testing::TempDir::new("prez-drive", "short");
    let pdf = dir.join("short.pdf");
    std::fs::write(&pdf, b"<</Type /Pages>> <</Type /Page>> <</Type /Page>>").unwrap();

    assert!(
      verify_pagination(&pdf, 2).is_empty(),
      "a matching count is silent"
    );

    let warnings = verify_pagination(&pdf, 6);
    assert_eq!(warnings.len(), 1);
    assert!(warnings[0].contains("6 slides"), "{warnings:?}");
    assert!(warnings[0].contains("2 pages"), "{warnings:?}");
    assert!(
      warnings[0].contains("height: auto !important"),
      "names the usual cause: {warnings:?}"
    );
  }

  #[test]
  fn an_unreadable_page_count_is_reported_rather_than_passed() {
    let dir = artifact::testing::TempDir::new("prez-drive", "opaque");
    let pdf = dir.join("opaque.pdf");
    std::fs::write(&pdf, b"nothing recognisable here").unwrap();
    let warnings = verify_pagination(&pdf, 6);
    assert_eq!(warnings.len(), 1);
    assert!(warnings[0].contains("unverified"), "{warnings:?}");
  }

  // ---- issue 0131: a print is bounded, and nothing of Chrome's holds it ----

  /// A stand-in for Chrome: a shell script named `chrome` in `dir`.
  fn fake_browser(dir: &Path, body: &str) -> PathBuf {
    use std::os::unix::fs::PermissionsExt;
    let path = dir.join("chrome");
    std::fs::write(&path, format!("#!/bin/sh\n{body}\n")).unwrap();
    std::fs::set_permissions(&path, std::fs::Permissions::from_mode(0o755)).unwrap();
    path
  }

  /// Writes a one-page PDF where the fake was told to print.
  const WRITES_THE_PDF: &str = r#"for a; do case "$a" in --print-to-pdf=*) out="${a#--print-to-pdf=}" ;; esac; done
printf '<</Type /Page>>' >"$out""#;

  /// Kills the process whose pid a fake wrote to `file`: what it left running.
  fn kill_left(file: &Path) {
    if let Ok(pid) = std::fs::read_to_string(file) {
      let _ = Command::new("/bin/kill")
        .args(["-KILL", pid.trim()])
        .status();
    }
  }

  /// Neither the PDF nor its partial is at `out`: what a refused print leaves.
  fn assert_nothing_at(out: &Path) {
    assert!(
      !out.exists(),
      "a refused print left a PDF at {}",
      out.display()
    );
    assert!(
      !partial_of(out).exists(),
      "a refused print left its partial beside {}",
      out.display()
    );
  }

  #[test]
  fn a_print_that_never_finishes_is_refused_at_its_deadline_and_chrome_killed() {
    let dir = artifact::testing::TempDir::new("prez-drive", "stall");
    let left = dir.join("left");
    let out = dir.join("deck.pdf");
    let chrome = fake_browser(
      &dir,
      &format!(
        "echo 'still printing'\nsleep 30 &\necho $! >'{}'\nwait",
        left.display()
      ),
    );
    let deadline = Duration::from_secs(3);
    let began = Instant::now();
    let e = print_within(
      &chrome,
      &dir.join("deck.html"),
      &out,
      &dir.join("chrome.log"),
      1,
      deadline,
    )
    .unwrap_err();
    let took = began.elapsed();
    // Only Chrome's main process is killed, so the sleep it started is left,
    // as a helper of Chrome's would be, and the test ends it.
    kill_left(&left);
    assert!(took < deadline + REAP_GRACE, "{took:?}");
    assert!(
      e.message.contains("did not finish printing"),
      "{}",
      e.message
    );
    assert!(
      e.message.contains("still printing"),
      "what Chrome said goes with the refusal: {}",
      e.message
    );
    assert!(
      !e.message.contains("still running"),
      "the killed fake was not reaped within the grace: {}",
      e.message
    );
    assert_eq!(e.remedy.as_deref(), Some(STALLED));
    assert_nothing_at(&out);
  }

  #[test]
  fn a_print_returns_when_chrome_exits_whatever_it_leaves_holding_its_output() {
    let dir = artifact::testing::TempDir::new("prez-drive", "linger");
    let left = dir.join("left");
    let out = dir.join("deck.pdf");
    // A partial an interrupted print left, which this print must not keep.
    std::fs::write(partial_of(&out), b"an interrupted print").unwrap();
    // The sleep inherits the fake's stdout and stderr and outlives it, as a
    // helper of Chrome's can. On pipes, reading them to their end waited for it.
    let chrome = fake_browser(
      &dir,
      &format!(
        "{WRITES_THE_PDF}\nsleep 30 &\necho $! >'{}'",
        left.display()
      ),
    );
    let began = Instant::now();
    let printed = print_within(
      &chrome,
      &dir.join("deck.html"),
      &out,
      &dir.join("chrome.log"),
      1,
      Duration::from_secs(20),
    );
    let took = began.elapsed();
    kill_left(&left);
    assert_eq!(printed.unwrap(), Vec::<String>::new());
    assert!(
      took < Duration::from_secs(10),
      "the print waited {took:?} for what Chrome left behind"
    );
    assert_eq!(std::fs::read(&out).unwrap(), b"<</Type /Page>>");
    assert!(!partial_of(&out).exists(), "the partial outlived the print");
  }

  #[test]
  fn a_print_that_fails_is_refused_with_what_chrome_said() {
    let dir = artifact::testing::TempDir::new("prez-drive", "fails");
    let out = dir.join("deck.pdf");
    let chrome = fake_browser(&dir, "echo 'cannot print this' >&2\nexit 1");
    let e = print_within(
      &chrome,
      &dir.join("deck.html"),
      &out,
      &dir.join("chrome.log"),
      1,
      Duration::from_secs(20),
    )
    .unwrap_err();
    assert!(
      e.message.contains("failed while printing (exit 1)"),
      "{}",
      e.message
    );
    assert!(e.message.contains("cannot print this"), "{}", e.message);
    assert_nothing_at(&out);
  }

  #[test]
  fn a_print_refused_after_writing_its_pdf_leaves_no_pdf_and_no_partial() {
    let dir = artifact::testing::TempDir::new("prez-drive", "refused");
    let out = dir.join("deck.pdf");
    let chrome = fake_browser(&dir, &format!("{WRITES_THE_PDF}\nexit 1"));
    let e = print_within(
      &chrome,
      &dir.join("deck.html"),
      &out,
      &dir.join("chrome.log"),
      1,
      Duration::from_secs(20),
    )
    .unwrap_err();
    assert!(
      e.message.contains("failed while printing (exit 1)"),
      "{}",
      e.message
    );
    assert_nothing_at(&out);
  }

  #[test]
  fn a_stale_partial_is_never_taken_for_a_print_that_wrote_nothing() {
    let dir = artifact::testing::TempDir::new("prez-drive", "stale");
    let out = dir.join("deck.pdf");
    // A whole one-page PDF an interrupted print left: without its removal
    // first, a Chrome that exits 0 having written nothing would see it
    // renamed over `out` and counted as its own print.
    std::fs::write(partial_of(&out), b"<</Type /Page>>").unwrap();
    let chrome = fake_browser(&dir, "exit 0");
    let e = print_within(
      &chrome,
      &dir.join("deck.html"),
      &out,
      &dir.join("chrome.log"),
      1,
      Duration::from_secs(20),
    )
    .unwrap_err();
    assert!(e.message.contains("wrote no PDF"), "{}", e.message);
    assert_nothing_at(&out);
  }
}
