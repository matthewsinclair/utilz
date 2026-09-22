//! The platform safe zone a recording is made inside (ST0024 D5).
//!
//! **ONE PARSE FOR THE FLAG AND THE KEY.** `--safe-zone` and `safe_zone:` in
//! `showreel.yaml` both come through `Zone::parse`, exactly as `aspect` does,
//! so the two cannot accept different spellings.
//!
//! **THE NAME TRAVELS; THE GEOMETRY DOES NOT.** What a zone's four insets ARE
//! is a layout fact, and it lives in the player's CSS beside every other
//! length. This module carries the name, as `fit:`, `transition:` and
//! `motion:` are carried: Rust validates the word, the player draws it.
//!
//! **IT IS A RECORDING'S OPTION, NOT A REEL'S LOOK.** The built HTML is
//! unchanged by it; `video` asks the player for the zone on the URL it already
//! loads (`?noloop&kiosk`), which also means a person can preview one in a
//! browser by adding `?zone=social` by hand.

use artifact::Failure;
use serde::Deserialize;

/// The zones, with the word each is written as. `none` is the default and
/// means the frame's own overscan safe area, unchanged.
pub const NAMES: &[&str] = &["none", "social"];

/// Where a platform's own UI sits over a reel.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Deserialize)]
#[serde(try_from = "String")]
pub enum Zone {
  /// No platform zone: the shell's overscan safe area, as every recording
  /// before this one.
  #[default]
  None,
  /// TikTok's and Instagram Reels' UI together: their caption, sound and
  /// username rows across the bottom, their action column down the right, and
  /// their own chrome at the top. One zone covers both, because the same
  /// recording is posted to both.
  Social,
}

impl TryFrom<String> for Zone {
  type Error = String;

  /// serde's route in, for `safe_zone:`: the same parse, with the refusal's
  /// remedy folded into the message serde carries.
  fn try_from(value: String) -> Result<Self, Self::Error> {
    Self::parse(&value).map_err(|f| match f.remedy {
      Some(remedy) => format!("{}; {remedy}", f.message),
      None => f.message,
    })
  }
}

impl Zone {
  /// A name, in any case. Anything else is refused, naming it.
  pub fn parse(value: &str) -> Result<Self, Failure> {
    match value.trim() {
      v if v.eq_ignore_ascii_case("none") => Ok(Self::None),
      v if v.eq_ignore_ascii_case("social") => Ok(Self::Social),
      other => Err(Failure::new(
        format!("safe zone '{other}' is not a zone this knows"),
        format!(
          "expected one of {}, eg --safe-zone social",
          NAMES.join(", ")
        ),
      )),
    }
  }

  /// The word the player reads off the URL. `None` has none: a zone that
  /// changes nothing is not asked for.
  pub fn word(self) -> Option<&'static str> {
    match self {
      Self::None => None,
      Self::Social => Some("social"),
    }
  }
}

/// ST0024 AT05: the names in any case, every refusal, and the default that
/// puts nothing on the URL. The landscape refusal is video.rs's own row.
#[cfg(test)]
mod tests {
  use super::*;

  #[test]
  fn a_name_is_read_in_any_case() {
    assert_eq!(Zone::parse("social").unwrap(), Zone::Social);
    assert_eq!(Zone::parse("SOCIAL").unwrap(), Zone::Social);
    assert_eq!(Zone::parse(" Social ").unwrap(), Zone::Social);
    assert_eq!(Zone::parse("none").unwrap(), Zone::None);
  }

  #[test]
  fn anything_else_is_refused_by_name_with_the_names_it_knows() {
    let f = Zone::parse("tiktok").unwrap_err();
    assert!(f.message.contains("tiktok"), "{}", f.message);
    let remedy = f.remedy.unwrap();
    assert!(remedy.contains("social"), "{remedy}");
    assert!(remedy.contains("none"), "{remedy}");
    assert!(Zone::parse("").is_err());
  }

  #[test]
  fn the_default_is_no_zone_and_it_puts_nothing_on_the_url() {
    assert_eq!(Zone::default(), Zone::None);
    assert_eq!(Zone::None.word(), None);
    assert_eq!(Zone::Social.word(), Some("social"));
  }
}
