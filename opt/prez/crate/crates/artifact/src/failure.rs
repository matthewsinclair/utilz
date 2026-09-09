// The failure vocabulary: what went wrong, and what to do about it.

/// A refusal, carrying its own remedy.
///
/// **THE REMEDY IS A FIELD RATHER THAN A CONVENTION**, because a refusal
/// without one is a report that the user is now stuck. Every construction site
/// has to answer "and then what", and a struct field is the only version of
/// that requirement a compiler enforces.
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
