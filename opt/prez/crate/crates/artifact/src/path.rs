// Finding a command on PATH, for every tool that runs one.
//
// **TWO TOOLS ALREADY DID THIS, WHICH IS WHY IT IS HERE.** prez's browser
// finder walks PATH for a Chromium by name, and showreel's `video` walks it for
// ffmpeg and ffprobe. The same three steps -- split PATH, join the name, keep
// the first file -- were written twice until vc's review of ST0021's WP-03.

use std::ffi::OsStr;
use std::path::PathBuf;

/// The first file called `name` in a directory on PATH.
pub fn on_path(name: &str) -> Option<PathBuf> {
  find_in(&std::env::var_os("PATH")?, name)
}

/// The first file called `name` in a directory of `paths`, a PATH-shaped list.
/// Separate from `on_path` so it can be tested without the process's PATH,
/// which another test in this crate empties while it runs.
fn find_in(paths: &OsStr, name: &str) -> Option<PathBuf> {
  std::env::split_paths(paths)
    .map(|dir| dir.join(name))
    .find(|p| p.is_file())
}

#[cfg(test)]
mod tests {
  use super::*;

  #[test]
  fn the_first_directory_holding_the_name_wins_and_a_missing_name_is_none() {
    let root = std::env::temp_dir().join(format!("artifact-path-{}", std::process::id()));
    let (a, b) = (root.join("a"), root.join("b"));
    std::fs::create_dir_all(&a).unwrap();
    std::fs::create_dir_all(&b).unwrap();
    std::fs::write(b.join("tool"), b"x").unwrap();
    std::fs::create_dir_all(a.join("tool-dir-not-file")).unwrap();
    let paths = std::env::join_paths([&a, &b]).unwrap();

    assert_eq!(find_in(&paths, "tool"), Some(b.join("tool")));
    assert_eq!(find_in(&paths, "absent"), None);
    assert_eq!(
      find_in(&paths, "tool-dir-not-file"),
      None,
      "a directory is no command"
    );
    std::fs::remove_dir_all(&root).unwrap();
  }
}
