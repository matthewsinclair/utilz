// Finding an installed Chromium-family browser to drive (ST0021 AC-01.1).
//
// **ONE FINDER FOR EVERY TOOL THAT HANDS A FILE TO A BROWSER.** prez's `pdf`
// and `present` drive one, and showreel's `video` records one. Each asking the
// question its own way is how the same machine would answer "which browser?"
// twice, differently, with nothing to report the disagreement.
//
// The probe order is `--browser`, then the Chromium family by macOS app path,
// then the same family by PATH name. When none is found the refusal LISTS EVERY
// PATH TRIED, because "no browser found" on a machine with four browsers
// installed is a report the user cannot act on.
//
// `file_url` is here for the same reason: it is the address every one of those
// tools hands the browser its file by, and it moved from prez's drive.rs,
// unchanged, when showreel's `video` became its second caller.

use crate::Failure;
use std::path::{Path, PathBuf};

/// Where a Chromium-family browser lives on macOS, in preference order.
const APP_PATHS: &[&str] = &[
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
  "/Applications/Chromium.app/Contents/MacOS/Chromium",
  "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
  "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser",
];

/// And what it is called on a PATH.
const PATH_NAMES: &[&str] = &[
  "google-chrome",
  "google-chrome-stable",
  "chromium",
  "chromium-browser",
  "microsoft-edge",
  "brave-browser",
];

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
    if let Some(path) = crate::path::on_path(name) {
      return Ok(path);
    }
  }

  Err(Failure::new(
    format!(
      "no Chromium-family browser found. Probed:\n    {}",
      probed.join("\n    ")
    ),
    "install Chrome, Chromium, Edge or Brave, or name one with --browser PATH",
  ))
}

fn is_runnable(path: &Path) -> bool {
  path.is_file()
}

/// A `file://` URL for an absolute path.
///
/// Percent-encoded conservatively: a deck living under a directory with a space
/// in it is the normal case on a Mac, and an unencoded space truncates the URL
/// at the space with no error from the browser.
pub fn file_url(path: &Path) -> String {
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

  // AT35 (ST0021 AC-01.1): the two discovery tests below moved here with the
  // finder, and pass from their new home.

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
      assert_eq!(
        message.matches("\n    ").count(),
        APP_PATHS.len() + PATH_NAMES.len()
      );
    }
  }

  #[test]
  fn a_file_url_survives_a_path_with_spaces() {
    let url = file_url(Path::new("/tmp/a deck/talk.html"));
    assert!(url.starts_with("file:///"), "{url}");
    assert!(url.contains("a%20deck"), "{url}");
    assert!(!url.contains(' '), "{url}");
  }
}
