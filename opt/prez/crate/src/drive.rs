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

use crate::Failure;
use std::path::{Path, PathBuf};
use std::process::Command;

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

/// Launch the artifact for presenting, then return so prez can exit.
pub fn open_presenting(explicit: Option<&str>, artifact: &Path) -> Result<(), Failure> {
  // `--app` drops the tab strip, the address bar and the bookmarks -- the
  // difference between a presentation and a browser window with slides in it.
  if let Ok(browser) = find(explicit) {
    return spawn(
      Command::new(&browser)
        .arg(format!("--app={}", file_url(artifact)))
        .arg("--start-fullscreen")
        .arg("--new-window"),
      &browser.display().to_string(),
    );
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
  command.spawn().map(|_| ()).map_err(|e| {
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
