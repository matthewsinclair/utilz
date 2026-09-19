//! The last of what a child process wrote to a pipe (ST0021).
//!
//! Chrome and ffmpeg both narrate on stderr, and what they said is shown only
//! when a recording fails. Each is read on a thread of its own, so a child
//! never blocks on a full pipe, and only the last few kilobytes are kept,
//! because the part worth reading is the end.

use artifact::Failure;
use std::io::{ErrorKind, Read};
use std::sync::mpsc::{self, Receiver};
use std::sync::{Arc, Mutex, PoisonError};
use std::time::Duration;

/// How much of a child's output is kept.
const KEEP: usize = 4 * 1024;

/// The end of what one child wrote, as far as it has come.
pub struct Tail {
  kept: Arc<Mutex<Vec<u8>>>,
  done: Receiver<()>,
}

impl Tail {
  /// Starts reading `from` to its end, on a thread of its own.
  pub fn read(from: impl Read + Send + 'static) -> Self {
    let kept = Arc::new(Mutex::new(Vec::new()));
    let (finished, done) = mpsc::channel();
    let into = Arc::clone(&kept);
    std::thread::spawn(move || {
      keep_end(from, &into);
      // Nobody may be waiting any more, and that is not a failure.
      let _ = finished.send(());
    });
    Self { kept, done }
  }

  /// What was written, the last of it. It waits a moment for the reader to
  /// reach the end, because the lines worth reading are the last ones.
  pub fn said(&self) -> String {
    let _ = self.done.recv_timeout(Duration::from_secs(1));
    let kept = self.kept.lock().unwrap_or_else(PoisonError::into_inner);
    String::from_utf8_lossy(&kept).into_owned()
  }

  /// Adds what `who` said to a refusal, indented under it, when it said
  /// anything at all.
  pub fn append_to(&self, failure: &mut Failure, who: &str) {
    let said = self.said();
    if said.trim().is_empty() {
      return;
    }
    failure.message.push_str(&format!("\n  {who} said:"));
    for line in said.lines() {
      failure.message.push_str("\n    ");
      failure.message.push_str(line);
    }
  }
}

/// Reads to the end, keeping the last `KEEP` bytes.
fn keep_end(mut from: impl Read, into: &Mutex<Vec<u8>>) {
  let mut chunk = [0u8; 4096];
  loop {
    match from.read(&mut chunk) {
      Ok(0) => return,
      Ok(n) => {
        let mut kept = into.lock().unwrap_or_else(PoisonError::into_inner);
        kept.extend_from_slice(&chunk[..n]);
        let over = kept.len().saturating_sub(KEEP);
        kept.drain(..over);
      }
      Err(e) if e.kind() == ErrorKind::Interrupted => continue,
      // A pipe that cannot be read has nothing more to give, and what it gave
      // is kept: the refusal that shows it is already on its way.
      Err(_) => return,
    }
  }
}

#[cfg(test)]
mod tests {
  use super::*;
  use std::io::Write as _;

  #[test]
  fn the_end_is_kept_and_the_start_let_go() {
    let (reader, mut writer) = std::io::pipe().unwrap();
    let tail = Tail::read(reader);
    writer.write_all(&vec![b'a'; KEEP * 3]).unwrap();
    writer.write_all(b"\nthe last line\n").unwrap();
    drop(writer);
    let said = tail.said();
    assert!(said.len() <= KEEP, "{} bytes kept", said.len());
    assert!(said.ends_with("the last line\n"), "{said:?}");
  }

  #[test]
  fn a_refusal_carries_what_was_said_indented_and_nothing_when_nothing_was() {
    let (reader, mut writer) = std::io::pipe().unwrap();
    let tail = Tail::read(reader);
    writer.write_all(b"one\ntwo\n").unwrap();
    drop(writer);
    let mut failure = Failure::new("it stopped", "try again");
    tail.append_to(&mut failure, "ffmpeg");
    assert_eq!(
      failure.message,
      "it stopped\n  ffmpeg said:\n    one\n    two"
    );

    let (reader, writer) = std::io::pipe().unwrap();
    let quiet = Tail::read(reader);
    drop(writer);
    let mut failure = Failure::new("it stopped", "try again");
    quiet.append_to(&mut failure, "Chrome");
    assert_eq!(failure.message, "it stopped");
  }
}
