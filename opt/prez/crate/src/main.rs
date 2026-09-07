// prez -- markdown in, one self-contained HTML presentation out.
//
// THE SHAPE OF THIS TOOL IS AN ANTI-REQUIREMENT (hv, 28 Aug 2026): there is no
// server and no viewer, and there never will be. prez is a pipeline that
// produces a file; the BROWSER presents it. Every feature request that begins
// "and then prez could serve..." is answered by that sentence.
//
// This file is a thin coordinator: parse argv, dispatch, render the outcome.
// Anything that decides something lives in a module beside it.

mod args;
mod base64;
mod deck;
mod drive;
mod fence;
mod frontmatter;
mod html;
mod inline;
mod mermaid;
mod notes;
mod render;
mod split;
mod theme;

use std::process::ExitCode;

fn main() -> ExitCode {
  // Errors are reported HERE and nowhere else, so every failure path leaves by
  // the same door and carries a remedy (IN-AG-NO-SILENT-001). A module that
  // printed its own error and exited would be a second door with its own
  // formatting, and the two would drift.
  match run() {
    Ok(()) => ExitCode::SUCCESS,
    Err(e) => {
      eprintln!("prez: {}", e.message);
      if let Some(remedy) = e.remedy {
        eprintln!("  remedy: {}", remedy);
      }
      ExitCode::from(e.code)
    }
  }
}

/// What went wrong, and what the reader should do about it.
///
/// A bare string would let a caller omit the remedy, and a failure a user
/// cannot act on is only half reported.
#[derive(Debug)]
pub struct Failure {
  pub message: String,
  pub remedy: Option<String>,
  pub code: u8,
}

impl Failure {
  pub fn new(message: impl Into<String>, remedy: impl Into<String>) -> Self {
    Self { message: message.into(), remedy: Some(remedy.into()), code: 2 }
  }
}

fn run() -> Result<(), Failure> {
  let argv: Vec<String> = std::env::args().skip(1).collect();
  match args::parse(&argv)? {
    args::Invocation::Help => {
      print!("{}", args::USAGE);
      Ok(())
    }
    args::Invocation::Version => {
      println!("prez {}", env!("CARGO_PKG_VERSION"));
      Ok(())
    }
    // The whole point is that a caller can ASK. Resolution goes through
    // drive::find, the same call pdf and present make, so there is one list
    // and no way for this answer to differ from the one they act on. The path
    // goes to STDOUT alone so `$(prez browser)` is the natural consumption;
    // finding none, drive::find's own refusal names every path it probed.
    args::Invocation::Browser => {
      println!("{}", drive::find(None)?.display());
      Ok(())
    }
    args::Invocation::Command(cmd) => deck::run(&cmd),
  }
}
