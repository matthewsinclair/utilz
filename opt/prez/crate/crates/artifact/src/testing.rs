// TEST SUPPORT, NOT PART OF ANY TOOL: a test's own directory under TMPDIR, for
// every crate's tests (issue 0093).
//
// **IT IS KEPT OUT OF THE SHIPPED BINARIES BY NEVER BEING CALLED FROM THEM.**
// It is compiled always and hidden from the docs, because the tests of prez and
// showreel reach it through the dependency they already have: a test-only
// `[dev-dependencies]` table or feature would move a manifest, which
// tests/manifest.rs refuses without hv. No tool's code calls it, so the release
// build's LTO drops it; 0093's run checks the release binaries for its message.
//
// One guard, so no crate's tests grow a second copy of "make a directory and
// remember to remove it" -- which every one of them had, and most forgot the
// second half of.

use std::path::PathBuf;

/// `$TMPDIR/<prefix>-<pid>-<tag>`, made empty when the guard is made and
/// removed when it drops, whether the test passes or panics.
pub struct TempDir(PathBuf);

impl TempDir {
  /// The prefix names the crate and module that own the directory and the tag
  /// names the test, so tests running at once in one process never share one
  /// and a leftover still says whose it is. A leftover from a killed run with
  /// the same pid is removed first.
  pub fn new(prefix: &str, tag: &str) -> TempDir {
    let d = std::env::temp_dir().join(format!("{prefix}-{}-{tag}", std::process::id()));
    remove(&d);
    std::fs::create_dir_all(&d)
      .unwrap_or_else(|e| panic!("cannot make the test directory {}: {e}", d.display()));
    TempDir(d)
  }
}

impl std::ops::Deref for TempDir {
  type Target = PathBuf;

  fn deref(&self) -> &PathBuf {
    &self.0
  }
}

impl Drop for TempDir {
  fn drop(&mut self) {
    remove(&self.0);
  }
}

/// Gone already is fine; any other failure fails the test by name. A panic
/// inside an unwind aborts the test binary and hides the failure that started
/// it, so a test already failing only says so.
fn remove(d: &std::path::Path) {
  match std::fs::remove_dir_all(d) {
    Ok(()) => {}
    Err(e) if e.kind() == std::io::ErrorKind::NotFound => {}
    Err(e) if std::thread::panicking() => {
      eprintln!("cannot remove the test directory {}: {e}", d.display())
    }
    Err(e) => panic!("cannot remove the test directory {}: {e}", d.display()),
  }
}

#[cfg(test)]
mod tests {
  use super::*;

  #[test]
  fn a_test_directory_is_removed_when_its_guard_drops_issue_0092() {
    let d = TempDir::new("artifact-testing", "guard-probe");
    std::fs::write(d.join("theme.css"), "body{}\n").unwrap();
    let path = d.to_path_buf();
    drop(d);
    assert!(!path.exists(), "{} survived its test", path.display());
  }

  #[test]
  fn a_leftover_with_the_same_name_is_emptied_issue_0093() {
    let stale = std::env::temp_dir().join(format!("artifact-testing-{}-stale", std::process::id()));
    std::fs::create_dir_all(&stale).unwrap();
    std::fs::write(stale.join("old.css"), "body{}\n").unwrap();
    let d = TempDir::new("artifact-testing", "stale");
    assert_eq!(*d, stale);
    assert!(!d.join("old.css").exists(), "the leftover's file survived");
  }
}
