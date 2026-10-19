// Finding a command on PATH, for every tool that runs one.
//
// **TWO TOOLS ALREADY DID THIS, WHICH IS WHY IT IS HERE.** prez's browser
// finder walks PATH for a Chromium by name, and showreel's `video` walks it for
// ffmpeg and ffprobe. The same three steps -- split PATH, join the name, keep
// the first command that can run -- were written twice until vc's review of
// ST0021's WP-03.
//
// **A FILE THAT CANNOT RUN IS NO COMMAND (issue 0089).** The finders took the
// first file by `is_file()` alone, so a file without an execute bit ahead of a
// good command on PATH hid it, and the run failed at the launch with
// "Permission denied" and a remedy for another case. `is_executable` asks what
// PATH lookup asks, and every finder asks it.

use std::ffi::OsStr;
use std::os::unix::fs::PermissionsExt;
use std::path::{Path, PathBuf};

/// The first command called `name` in a directory on PATH.
pub fn on_path(name: &str) -> Option<PathBuf> {
  find_in(&std::env::var_os("PATH")?, name)
}

/// Whether `path` is a command that can run: a regular file, after links, with
/// an execute bit set. The crates build for macOS and Linux only, so the unix
/// permission bits are read with no cfg, as the rest of the workspace does.
pub fn is_executable(path: &Path) -> bool {
  path
    .metadata()
    .is_ok_and(|m| m.is_file() && m.permissions().mode() & 0o111 != 0)
}

/// The first command called `name` in a directory of `paths`, a PATH-shaped
/// list. Separate from `on_path` so it can be tested without the process's
/// PATH, which another test in this crate empties while it runs.
fn find_in(paths: &OsStr, name: &str) -> Option<PathBuf> {
  std::env::split_paths(paths)
    .map(|dir| dir.join(name))
    .find(|p| is_executable(p))
}

#[cfg(test)]
mod tests {
  use super::*;

  /// A file at `path` holding `x`, with `mode`.
  fn file_with_mode(path: &Path, mode: u32) {
    std::fs::write(path, b"x").unwrap();
    std::fs::set_permissions(path, std::fs::Permissions::from_mode(mode)).unwrap();
  }

  #[test]
  fn the_first_directory_holding_the_name_wins_and_a_missing_name_is_none() {
    let root = crate::testing::TempDir::new("artifact-path", "first-wins");
    let (a, b) = (root.join("a"), root.join("b"));
    std::fs::create_dir_all(&a).unwrap();
    std::fs::create_dir_all(&b).unwrap();
    file_with_mode(&b.join("tool"), 0o755);
    std::fs::create_dir_all(a.join("tool-dir-not-file")).unwrap();
    let paths = std::env::join_paths([&a, &b]).unwrap();

    assert_eq!(find_in(&paths, "tool"), Some(b.join("tool")));
    assert_eq!(find_in(&paths, "absent"), None);
    assert_eq!(
      find_in(&paths, "tool-dir-not-file"),
      None,
      "a directory is no command"
    );
  }

  #[test]
  fn a_file_that_cannot_run_is_passed_over_for_one_that_can_issue_0089() {
    let root = crate::testing::TempDir::new("artifact-path", "0089");
    let (a, b) = (root.join("a"), root.join("b"));
    std::fs::create_dir_all(&a).unwrap();
    std::fs::create_dir_all(&b).unwrap();
    file_with_mode(&a.join("tool"), 0o644);
    file_with_mode(&b.join("tool"), 0o755);
    file_with_mode(&a.join("plain"), 0o644);
    let paths = std::env::join_paths([&a, &b]).unwrap();

    assert_eq!(
      find_in(&paths, "tool"),
      Some(b.join("tool")),
      "the executable one in the second directory, as the shell finds it"
    );
    assert_eq!(
      find_in(&paths, "plain"),
      None,
      "a file that cannot run, alone, is none"
    );
  }

  #[test]
  fn is_executable_wants_a_regular_file_with_an_execute_bit_issue_0089() {
    let root = crate::testing::TempDir::new("artifact-path", "exec");
    file_with_mode(&root.join("runs"), 0o755);
    file_with_mode(&root.join("owner-only"), 0o700);
    file_with_mode(&root.join("plain"), 0o644);

    assert!(is_executable(&root.join("runs")));
    assert!(is_executable(&root.join("owner-only")));
    assert!(
      !is_executable(&root.join("plain")),
      "a 0644 file cannot run"
    );
    assert!(!is_executable(&root), "a directory is no command");
    assert!(
      !is_executable(&root.join("absent")),
      "nor is a missing path"
    );
  }
}
