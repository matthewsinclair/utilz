// Driving an installed browser, for `pdf` and `present`.
//
// **PREZ DOES NOT PRESENT AND DOES NOT RENDER** (hv's anti-requirement, spec
// 6). It has no server, no viewer and no layout engine of its own. What it has
// is a file and the ability to hand that file to something that already knows
// how to draw it. This module is that handoff and nothing more.
//
// The probe order is `--browser`, then the Chromium family by macOS app path,
// then the same family by PATH name. When none is found the refusal LISTS EVERY
// PATH TRIED, because "no browser found" on a machine with four browsers
// installed is a report the user cannot act on.

use crate::html;
use crate::Failure;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

/// Where a Chromium-family browser lives on macOS, in preference order.
const APP_PATHS: &[&str] = &[
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
  "/Applications/Chromium.app/Contents/MacOS/Chromium",
  "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
  "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser",
];

/// And what it is called on a PATH.
const PATH_NAMES: &[&str] =
  &["google-chrome", "google-chrome-stable", "chromium", "chromium-browser", "microsoft-edge", "brave-browser"];

/// Find a browser to drive, or refuse with everything that was tried.
pub fn find(explicit: Option<&str>) -> Result<PathBuf, Failure> {
  let mut probed: Vec<String> = Vec::new();

  if let Some(given) = explicit {
    let path = PathBuf::from(given);
    if is_runnable(&path) {
      return Ok(path);
    }
    // An explicit --browser that does not exist is a typo, not an invitation to
    // fall back and silently drive something the user did not name.
    return Err(Failure::new(
      format!("--browser '{given}' is not an executable file"),
      "give the full path to a Chrome, Chromium, Edge or Brave binary",
    ));
  }

  for candidate in APP_PATHS {
    probed.push((*candidate).to_string());
    let path = PathBuf::from(candidate);
    if is_runnable(&path) {
      return Ok(path);
    }
  }
  for name in PATH_NAMES {
    probed.push(format!("{name} (on PATH)"));
    if let Some(path) = on_path(name) {
      return Ok(path);
    }
  }

  Err(Failure::new(
    format!("no Chromium-family browser found. Probed:\n    {}", probed.join("\n    ")),
    "install Chrome, Chromium, Edge or Brave, or name one with --browser PATH",
  ))
}

fn is_runnable(path: &Path) -> bool {
  path.is_file()
}

fn on_path(name: &str) -> Option<PathBuf> {
  let paths = std::env::var_os("PATH")?;
  std::env::split_paths(&paths).map(|dir| dir.join(name)).find(|p| p.is_file())
}

/// Print an artifact to PDF through headless Chrome.
///
/// `slides` is what the compiler produced, and it is checked against what came
/// back. See `verify_pagination` for why that check exists.
pub fn print_to_pdf(
  browser: &Path,
  artifact: &Path,
  out: &Path,
  slides: usize,
) -> Result<Vec<String>, Failure> {
  // --virtual-time-budget gives the page a moment to lay out and, when the deck
  // opted into mermaid, to draw its diagrams. Without it a diagram-heavy deck
  // prints its fences as empty boxes.
  //
  // Chrome's output is CAPTURED rather than inherited. Headless Chrome narrates
  // ("86974 bytes written to file", allocator notices) and the user asked
  // prez for a PDF, not for a browser's log. It is replayed in full when the
  // print fails, which is the only moment it is worth reading -- quiet on
  // success is not the same as discarded.
  let result = Command::new(browser)
    .arg("--headless")
    .arg("--disable-gpu")
    .arg("--no-pdf-header-footer")
    .arg("--virtual-time-budget=5000")
    .arg(format!("--print-to-pdf={}", out.display()))
    .arg(file_url(artifact))
    .output()
    .map_err(|e| {
      Failure::new(
        format!("could not run '{}': {e}", browser.display()),
        "check the browser path, or name another with --browser",
      )
    })?;

  if !result.status.success() {
    return Err(Failure::new(
      format!(
        "'{}' failed while printing (exit {}):\n{}{}",
        browser.display(),
        code(&result.status),
        String::from_utf8_lossy(&result.stdout),
        String::from_utf8_lossy(&result.stderr)
      ),
      "try opening the built .html in that browser to see what it objects to",
    ));
  }
  if !out.is_file() {
    // Chrome exits 0 having written nothing often enough that trusting the exit
    // code alone would report a success with no PDF behind it.
    return Err(Failure::new(
      format!("the browser reported success but wrote no PDF at '{}'", out.display()),
      "check the -o path is writable, or try --browser with a different browser",
    ));
  }
  Ok(verify_pagination(out, slides))
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
    return vec![format!("could not re-read '{}' to check its page count", pdf.display())];
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
  (DEFAULT_WINDOW_WIDTH, (f64::from(DEFAULT_WINDOW_WIDTH) * ratio).round() as u32)
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
  let (w, h) = (w.trim().parse::<u32>().map_err(|_| refuse())?, h.trim().parse::<u32>().map_err(|_| refuse())?);
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
    format!("--app={}", file_url(artifact)),
    format!("--window-size={width},{height}"),
    "--new-window".to_string(),
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
  if let Ok(browser) = find(explicit) {
    let mut command = Command::new(&browser);
    command.args(presenting_argv(artifact, w, h));
    return spawn(&mut command, &browser.display().to_string());
  }
  if explicit.is_some() {
    // A named browser that could not be found is an error, never a fallback.
    find(explicit)?;
  }

  // No Chromium anywhere: hand it to the system opener. The deck still
  // presents, just with the browser's own chrome around it and `f` to fill
  // the screen.
  eprintln!("prez: warning: no Chromium-family browser found; opening with the system default, so the window will not be de-chromed");
  spawn(Command::new("open").arg(artifact), "open")
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
      Failure::new(format!("could not launch '{what}': {e}"), "name a browser with --browser PATH")
    })
}

fn code(status: &std::process::ExitStatus) -> String {
  status.code().map_or_else(|| "signal".to_string(), |c| c.to_string())
}

/// A `file://` URL for an absolute path.
///
/// Percent-encoded conservatively: a deck living under a directory with a space
/// in it is the normal case on a Mac, and an unencoded space truncates the URL
/// at the space with no error from the browser.
fn file_url(path: &Path) -> String {
  let absolute = path.canonicalize().unwrap_or_else(|_| path.to_path_buf());
  let mut url = String::from("file://");
  for byte in absolute.to_string_lossy().bytes() {
    match byte {
      b'A'..=b'Z' | b'a'..=b'z' | b'0'..=b'9' | b'/' | b'-' | b'.' | b'_' | b'~' => {
        url.push(byte as char)
      }
      _ => url.push_str(&format!("%{byte:02X}")),
    }
  }
  url
}

#[cfg(test)]
mod tests {
  use super::*;

  // ---- AC19: the presenting window has a shape -----------------------------

  #[test]
  fn the_default_window_is_the_deck_s_own_aspect() {
    // Derived from html::DEFAULT_PAPER rather than typed here, so `pdf` and
    // `present` cannot drift into disagreeing about what shape a deck is.
    let (w, h) = default_window();
    let ratio = f64::from(w) / f64::from(h);
    assert!((ratio - 254.0 / 142.9).abs() < 0.01, "{w}x{h} is {ratio}, not the deck's aspect");
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
    assert!(e.remedy.as_deref().unwrap().contains("pixels"), "{:?}", e.remedy);
    assert!(window_size(Some("0x600")).is_err(), "a zero dimension is not a window");
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
    assert!(argv.iter().any(|a| a == "--window-size=1280,720"), "{argv:?}");
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

  #[test]
  fn an_explicit_browser_that_does_not_exist_is_refused_rather_than_replaced() {
    // AC06's negative half. Falling back here would drive a browser the user
    // did not choose while reporting success.
    let e = find(Some("/nonexistent/browser")).unwrap_err();
    assert!(e.message.contains("/nonexistent/browser"), "{}", e.message);
    assert!(e.message.contains("not an executable"), "{}", e.message);
  }

  #[test]
  fn a_failed_probe_lists_every_path_it_tried() {
    // Driven with an empty PATH so the probe cannot succeed on this machine.
    let original = std::env::var_os("PATH");
    // SAFETY: single-threaded test process; restored immediately below.
    unsafe { std::env::set_var("PATH", "") };
    let refusal = find(None).err().map(|e| e.message);
    match original {
      Some(p) => unsafe { std::env::set_var("PATH", p) },
      None => unsafe { std::env::remove_var("PATH") },
    }

    // On a machine that HAS Chrome installed the probe legitimately succeeds,
    // so this asserts the refusal's shape only when there is a refusal.
    if let Some(message) = refusal {
      assert!(message.contains("Google Chrome"), "{message}");
      assert!(message.contains("chromium (on PATH)"), "{message}");
      assert_eq!(message.matches("\n    ").count(), APP_PATHS.len() + PATH_NAMES.len());
    }
  }

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
    let dir = std::env::temp_dir().join(format!("prez-drive-{}", std::process::id()));
    std::fs::create_dir_all(&dir).unwrap();
    let pdf = dir.join("short.pdf");
    std::fs::write(&pdf, b"<</Type /Pages>> <</Type /Page>> <</Type /Page>>").unwrap();

    assert!(verify_pagination(&pdf, 2).is_empty(), "a matching count is silent");

    let warnings = verify_pagination(&pdf, 6);
    assert_eq!(warnings.len(), 1);
    assert!(warnings[0].contains("6 slides"), "{warnings:?}");
    assert!(warnings[0].contains("2 pages"), "{warnings:?}");
    assert!(warnings[0].contains("height: auto !important"), "names the usual cause: {warnings:?}");
  }

  #[test]
  fn an_unreadable_page_count_is_reported_rather_than_passed() {
    let dir = std::env::temp_dir().join(format!("prez-drive-{}", std::process::id()));
    std::fs::create_dir_all(&dir).unwrap();
    let pdf = dir.join("opaque.pdf");
    std::fs::write(&pdf, b"nothing recognisable here").unwrap();
    let warnings = verify_pagination(&pdf, 6);
    assert_eq!(warnings.len(), 1);
    assert!(warnings[0].contains("unverified"), "{warnings:?}");
  }

  #[test]
  fn a_file_url_survives_a_path_with_spaces() {
    let url = file_url(Path::new("/tmp/a deck/talk.html"));
    assert!(url.starts_with("file:///"), "{url}");
    assert!(url.contains("a%20deck"), "{url}");
    assert!(!url.contains(' '), "{url}");
  }
}
