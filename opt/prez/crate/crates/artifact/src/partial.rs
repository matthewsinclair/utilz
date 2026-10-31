// A tool's output while it is not yet proven finished: `<name>.partial`,
// beside the name it takes once it is (issue 0131).
//
// **IT MOVED HERE WHEN prez's `pdf` BECAME ITS SECOND IMPLEMENTATION.**
// showreel's `video` has had ffmpeg write `<video>.partial`, renamed it only
// once the video was proven finished, and removed it on every refusal (issue
// 0096). prez's `pdf` now has Chrome print the same way, so that a refused
// print never leaves what reads as a PDF. By this crate's rule (lib.rs) the
// name, its extension and the removal moved together.

use std::path::{Path, PathBuf};

/// The extension of a tool's output not yet proven finished, a video or a
/// PDF. The one home of that name, for showreel's `video`, which names and
/// sweeps the partials, `stem`'s checks (issue 0101), and prez's `pdf` (issue
/// 0131).
pub const PARTIAL: &str = "partial";

/// Where a tool writes its output until it is proven finished: the output's
/// own name, and the partial's extension after it.
pub fn partial_of(output: &Path) -> PathBuf {
  let mut name = output.as_os_str().to_owned();
  name.push(".");
  name.push(PARTIAL);
  PathBuf::from(name)
}

/// Removes a partial, and says so when it cannot (issue 0096). A partial that
/// is not there is removed: a refusal can come before the tool has made it,
/// so a warning there would be false.
pub fn remove_partial(partial: &Path) -> Option<String> {
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
  fn a_partial_is_the_video_s_name_and_more() {
    assert_eq!(
      partial_of(Path::new("/x/r-001.showreel.mp4")),
      PathBuf::from("/x/r-001.showreel.mp4.partial")
    );
  }

  /// A partial that cannot be removed is named rather than dropped, and one
  /// that is not there counts as removed (issue 0096). A mode stops removal
  /// for a user and not for root, so where it does not bind the test fails
  /// saying so: it cannot pass without having measured.
  #[test]
  fn a_partial_that_cannot_be_removed_is_named_issue_0096() {
    use std::os::unix::fs::PermissionsExt;
    let guard = crate::testing::TempDir::new("artifact-partial", "partial");
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
}
