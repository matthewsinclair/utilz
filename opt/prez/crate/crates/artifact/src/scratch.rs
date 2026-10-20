// A private temporary directory for one run of a tool, removed on every path
// out of the run (issue 0095).
//
// **IT MOVED HERE WHEN prez's `pdf` BECAME ITS SECOND IMPLEMENTATION.**
// showreel's recording made one for Chrome's profile and TMPDIR, and removed it
// on every path; prez's `pdf` staged its HTML in TMPDIR with a `remove_file`
// that a failed print's `?` stepped past, and left the file behind. By this
// crate's rule (lib.rs) it moved once two tools implemented it.
//
// **A REMOVAL THAT FAILS IS SAID, NEVER DROPPED.** The caller calls `remove`
// where it can report, through its own door for warnings; `Drop` is the
// backstop for a path that never reached it, and says so itself.

use crate::Failure;
use std::fs;
use std::io::{ErrorKind, Write};
use std::os::unix::fs::DirBuilderExt;
use std::path::{Path, PathBuf};

/// The tools that make a scratch directory. The name is the directory's prefix
/// and the name its backstop speaks in, and `SCRATCH_BASE_MAX`'s arithmetic
/// depends on how long it is, so every name a caller can pass is here.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Tool {
  Prez,
  Showreel,
}

impl Tool {
  /// Every tool, which the test of `SCRATCH_BASE_MAX` reads: a third caller
  /// adds its variant here, and a name too long for Chrome's socket fails that
  /// test rather than Chrome's bind.
  pub const ALL: [Tool; 2] = [Tool::Prez, Tool::Showreel];

  pub fn name(self) -> &'static str {
    match self {
      Tool::Prez => "prez",
      Tool::Showreel => "showreel",
    }
  }

  /// Whether the tool gives Chrome its scratch directory as TMPDIR, so that
  /// Chrome binds its singleton's socket inside it. showreel's recording does;
  /// prez's `pdf` hands Chrome only a file, so its scratch stays in TMPDIR
  /// whatever TMPDIR's length, where prez always staged.
  fn chrome_binds_here(self) -> bool {
    match self {
      Tool::Prez => false,
      Tool::Showreel => true,
    }
  }
}

// Beside `ALL` on purpose: a new variant makes this match non-exhaustive, so
// whoever adds one is sent here, where `ALL` has to list it too.
const _: fn(Tool) = |tool| match tool {
  Tool::Prez | Tool::Showreel => {}
};

/// A private (`0700`) `<tool>-<pid>-<n>` directory for one run, made in TMPDIR,
/// or, for a tool whose Chrome binds in it, in /tmp when TMPDIR is too long for
/// the socket (`SCRATCH_BASE_MAX`).
pub struct Scratch {
  tool: Tool,
  dir: PathBuf,
  removed: bool,
}

impl Scratch {
  pub fn new(tool: Tool) -> Result<Self, Failure> {
    make(tool).map(|dir| Self {
      tool,
      dir,
      removed: false,
    })
  }

  pub fn path(&self) -> &Path {
    &self.dir
  }

  /// Removes the directory, and says so when it cannot; gone already is
  /// removed. After it `Drop` does nothing, because the message is the
  /// caller's to report.
  pub fn remove(&mut self) -> Option<String> {
    self.removed = true;
    remove_dir(&self.dir).err().map(|e| {
      format!(
        "could not remove the temporary directory {}: {e}",
        self.dir.display()
      )
    })
  }
}

impl Drop for Scratch {
  /// The backstop for a path that never reached `remove`: a panic, or a launch
  /// that failed and dropped its scratch. No caller is left to report a
  /// directory that will not go, so it is said here, in the tool's name.
  ///
  /// **`writeln!`, AND NEVER `eprintln!`.** `eprintln!` panics when its write
  /// fails, as when stderr is a pipe whose reader has gone, and a panic inside
  /// a drop while unwinding aborts the process, which is exactly when this
  /// runs. A write to stderr that fails has nowhere left to report.
  fn drop(&mut self) {
    if self.removed {
      return;
    }
    if let Some(message) = self.remove() {
      let _ = writeln!(
        std::io::stderr(),
        "{}: warning: {message}",
        self.tool.name()
      );
    }
  }
}

/// Removes a directory and everything in it, one already gone counting as
/// removed. The crate's one removal: `Scratch` words its error as a warning,
/// and `testing::TempDir` as a failed test.
pub(crate) fn remove_dir(dir: &Path) -> std::io::Result<()> {
  match fs::remove_dir_all(dir) {
    Err(e) if e.kind() == ErrorKind::NotFound => Ok(()),
    done => done,
  }
}

/// The longest directory a scratch directory Chrome binds in is made in.
///
/// **CHROME BINDS A UNIX SOCKET INSIDE IT, AND A SOCKET'S PATH IS SHORT.**
/// showreel gives Chrome its scratch directory as TMPDIR, and the process
/// singleton makes `<dir>/.<prefix>.XXXXXX/SingletonSocket`: up to 46 bytes
/// past `<dir>`, for Chromium's `.org.chromium.Chromium` prefix, the longest of
/// the four browsers the finder takes. The path must fit `sun_path`, 104 bytes
/// on macOS and 108 on Linux with the terminating NUL, or Chrome aborts at its
/// start. CI's Linux leg measured that as "Chrome closed the DevTools pipe
/// during the start", under video.sh's nested TMPDIR. So a base longer than
/// this is swapped for /tmp: 36, a slash, and `dir_name` at most 19 for the
/// longest name in `Tool::ALL`, leave 57, and 57 + 46 is 103.
const SCRATCH_BASE_MAX: usize = 36;

/// Where a scratch directory Chrome binds in is made: TMPDIR, unless it is
/// too long for the socket Chrome puts inside it.
fn base(temp: PathBuf) -> PathBuf {
  if temp.as_os_str().len() <= SCRATCH_BASE_MAX {
    temp
  } else {
    PathBuf::from("/tmp")
  }
}

/// A scratch directory's name, `<tool>-<pid>-<n>` for the `n`th name tried:
/// one spelling, which `make` uses and the test of `SCRATCH_BASE_MAX`
/// measures.
fn dir_name(tool: Tool, pid: u32, n: u32) -> String {
  format!("{}-{pid}-{n}", tool.name())
}

/// Creates a directory no other process can read, for one run.
fn make(tool: Tool) -> Result<PathBuf, Failure> {
  let temp = std::env::temp_dir();
  let base = match tool.chrome_binds_here() {
    true => base(temp),
    false => temp,
  };
  for n in 0..100 {
    let dir = base.join(dir_name(tool, std::process::id(), n));
    match fs::DirBuilder::new().mode(0o700).create(&dir) {
      Ok(()) => return Ok(dir),
      Err(e) if e.kind() == ErrorKind::AlreadyExists => continue,
      Err(e) => {
        return Err(Failure::new(
          format!(
            "could not create a temporary directory in {}: {e}",
            base.display()
          ),
          format!("check that {} is a writable directory", base.display()),
        ))
      }
    }
  }
  Err(Failure::new(
    format!(
      "could not find a free temporary directory name in {}",
      base.display()
    ),
    format!("clear old {}-* directories out of it", tool.name()),
  ))
}

#[cfg(test)]
mod tests {
  use super::*;
  use std::os::unix::fs::PermissionsExt;

  /// The scratch directory leaves room for the socket Chrome binds in it, on
  /// the longest TMPDIR as on the shortest, for every name a caller can pass.
  #[test]
  fn a_scratch_directory_leaves_room_for_chrome_s_socket_for_every_tool() {
    let long = PathBuf::from("/var/folders/nn/p40vzghs67v8yq0p5y416yf80000gn/T/");
    assert_eq!(base(long), PathBuf::from("/tmp"), "too long, so /tmp");
    assert_eq!(base(PathBuf::from("/tmp/")), PathBuf::from("/tmp/"));
    for tool in Tool::ALL {
      let widest = format!(
        "{}/{}",
        "x".repeat(SCRATCH_BASE_MAX),
        dir_name(tool, u32::MAX / 1000, 99)
      );
      assert!(widest.len() <= 57, "{} bytes: {widest}", widest.len());
      let socket = format!("{widest}/.org.chromium.Chromium.XXXXXX/SingletonSocket");
      assert!(
        socket.len() < 104,
        "{} bytes, over macOS's sun_path: {socket}",
        socket.len()
      );
    }
  }

  /// A directory that cannot be removed is named rather than dropped. A mode
  /// stops removal for a user and not for root, so where it does not bind the
  /// test fails saying so: it cannot pass without having measured.
  #[test]
  fn a_directory_that_cannot_be_removed_is_named_issue_0095() {
    let mut scratch = Scratch::new(Tool::Prez).unwrap();
    let dir = scratch.path().to_path_buf();
    let held = dir.join("held");
    fs::create_dir(&held).unwrap();
    fs::write(held.join("deck.html"), b"x").unwrap();
    fs::set_permissions(&held, fs::Permissions::from_mode(0o500)).unwrap();
    if fs::write(held.join("probe"), b"x").is_ok() {
      fs::set_permissions(&held, fs::Permissions::from_mode(0o700)).unwrap();
      remove_dir(&dir).unwrap();
      panic!("a mode does not stop removal here (root?), so this test cannot run");
    }
    let said = scratch.remove();
    fs::set_permissions(&held, fs::Permissions::from_mode(0o700)).unwrap();
    remove_dir(&dir).unwrap();
    let said = said.expect("remove said nothing of a directory it could not remove");
    assert!(
      said.contains(&dir.display().to_string()),
      "the message does not name {}: {said}",
      dir.display()
    );
  }
}
