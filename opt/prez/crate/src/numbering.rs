// Page numbers in print (issue 0065, hv's model of 16 Oct 2026).
//
// A deck sets the default with `numbering: on|off` in front matter, off when
// absent; a slide overrides it with `<!-- numbering: on|off -->`. Every slide
// uses up a page number whether or not it shows one, so the number printed on a
// page is that page's index in the PDF. The `title` class has no say.
//
// **ONE READER FOR BOTH PLACES THE WORD IS WRITTEN.** The front-matter key and
// the slide directive accept the same vocabulary, so it lives here once rather
// than in frontmatter.rs and render.rs separately, where the two could drift.
//
// **AN UNREADABLE VALUE IS KEPT, NEVER DEFAULTED.** `numbering: ture` read as
// off would print a deck with no numbers and nothing to say why. Both readers
// keep the value they could not read, and `resolve` refuses it by name.

use crate::render::Slide;
use crate::Failure;

#[derive(Debug, Clone, PartialEq)]
pub enum Numbering {
  On,
  Off,
  /// A value that is none of on, off, true or false, kept verbatim so the
  /// refusal can quote it.
  Unreadable(String),
}

impl Numbering {
  /// Read one value. on/off and true/false, in any case; nothing else.
  pub fn read(value: &str) -> Self {
    match value.trim().to_ascii_lowercase().as_str() {
      "on" | "true" => Self::On,
      "off" | "false" => Self::Off,
      _ => Self::Unreadable(value.trim().to_string()),
    }
  }
}

/// Decide, once, which slides show their number.
///
/// The one answer feeds both the per-slide class and the gate on the print CSS
/// in html.rs, so the two cannot disagree. Refuses the first unreadable value,
/// the deck's before any slide's.
pub fn resolve(deck: Option<&Numbering>, slides: &[Slide]) -> Result<Vec<bool>, Failure> {
  let default = match deck {
    None | Some(Numbering::Off) => false,
    Some(Numbering::On) => true,
    Some(Numbering::Unreadable(value)) => {
      return Err(refusal(format!(
        "front-matter key 'numbering' has value '{value}', which prez cannot read"
      )))
    }
  };
  slides
    .iter()
    .enumerate()
    .map(|(index, slide)| match &slide.numbering {
      None => Ok(default),
      Some(Numbering::On) => Ok(true),
      Some(Numbering::Off) => Ok(false),
      Some(Numbering::Unreadable(value)) => Err(refusal(format!(
        "slide {}: directive 'numbering' has value '{value}', which prez cannot read",
        index + 1
      ))),
    })
    .collect()
}

fn refusal(message: String) -> Failure {
  Failure::new(message, "use on or off (true and false also work)")
}

#[cfg(test)]
mod tests {
  use super::*;

  fn slide(numbering: Option<Numbering>) -> Slide {
    Slide {
      numbering,
      ..Slide::default()
    }
  }

  #[test]
  fn on_off_and_true_false_are_read_in_any_case() {
    for on in ["on", "ON", "true", "True", " on "] {
      assert_eq!(Numbering::read(on), Numbering::On, "{on:?}");
    }
    for off in ["off", "Off", "false", "FALSE"] {
      assert_eq!(Numbering::read(off), Numbering::Off, "{off:?}");
    }
  }

  #[test]
  fn anything_else_is_kept_unread() {
    // `yes` and `1` too: the vocabulary is hv's, not `mermaid:`'s.
    for bad in ["ture", "yes", "1", ""] {
      assert_eq!(
        Numbering::read(bad),
        Numbering::Unreadable(bad.into()),
        "{bad:?}"
      );
    }
  }

  #[test]
  fn with_no_key_anywhere_nothing_is_numbered() {
    let slides = [slide(None), slide(None)];
    assert_eq!(resolve(None, &slides).unwrap(), vec![false, false]);
  }

  #[test]
  fn a_slide_override_beats_the_deck_default_either_way() {
    let slides = [slide(None), slide(Some(Numbering::Off)), slide(None)];
    assert_eq!(
      resolve(Some(&Numbering::On), &slides).unwrap(),
      vec![true, false, true]
    );
    let slides = [slide(None), slide(Some(Numbering::On)), slide(None)];
    assert_eq!(
      resolve(Some(&Numbering::Off), &slides).unwrap(),
      vec![false, true, false]
    );
  }

  #[test]
  fn an_unreadable_deck_value_is_refused_naming_the_key_and_value() {
    let e = resolve(Some(&Numbering::Unreadable("ture".into())), &[slide(None)]).unwrap_err();
    assert!(
      e.message.contains("'numbering'") && e.message.contains("'ture'"),
      "{}",
      e.message
    );
    assert_eq!(e.code, 2);
  }

  #[test]
  fn an_unreadable_slide_value_is_refused_naming_the_slide() {
    let slides = [
      slide(None),
      slide(Some(Numbering::Unreadable("maybe".into()))),
    ];
    let e = resolve(Some(&Numbering::On), &slides).unwrap_err();
    assert!(e.message.starts_with("slide 2:"), "{}", e.message);
    assert!(
      e.message.contains("'numbering'") && e.message.contains("'maybe'"),
      "{}",
      e.message
    );
  }
}
