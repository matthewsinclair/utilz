// Page numbers in print (issue 0065, hv's model of 16 Oct 2026).
//
// A deck sets the default with `numbering: on|off` in front matter, off when
// absent; a slide overrides it with `<!-- numbering: on|off -->`. Every slide
// uses up a page number whether or not it shows one, so the number printed on a
// page is that page's index in the PDF. The `title` class has no say.
//
// **ONE READER FOR EVERY PLACE A SWITCH IS WRITTEN.** The front-matter key and
// the slide directive are read by switch.rs, which `mermaid:` shares (issue
// 0066), so the vocabulary cannot drift between them. An unreadable value is
// kept by the reader and refused here by name.

use crate::render::Slide;
use crate::switch::{self, Switch};
use crate::Failure;

/// Decide, once, which slides show their number.
///
/// The one answer feeds both the per-slide class and the gate on the print CSS
/// in html.rs, so the two cannot disagree. Refuses the first unreadable value,
/// the deck's before any slide's.
pub fn resolve(deck: Option<&Switch>, slides: &[Slide]) -> Result<Vec<bool>, Failure> {
  let default = switch::deck_key("numbering", deck)?;
  slides
    .iter()
    .enumerate()
    .map(|(index, slide)| match &slide.numbering {
      None => Ok(default),
      Some(Switch::On) => Ok(true),
      Some(Switch::Off) => Ok(false),
      Some(Switch::Unreadable(value)) => Err(switch::refusal(format!(
        "slide {}: directive 'numbering' has value '{value}', which prez cannot read",
        index + 1
      ))),
    })
    .collect()
}

#[cfg(test)]
mod tests {
  use super::*;

  fn slide(numbering: Option<Switch>) -> Slide {
    Slide {
      numbering,
      ..Slide::default()
    }
  }

  // The vocabulary itself is tested once, in switch.rs.

  #[test]
  fn with_no_key_anywhere_nothing_is_numbered() {
    let slides = [slide(None), slide(None)];
    assert_eq!(resolve(None, &slides).unwrap(), vec![false, false]);
  }

  #[test]
  fn a_slide_override_beats_the_deck_default_either_way() {
    let slides = [slide(None), slide(Some(Switch::Off)), slide(None)];
    assert_eq!(
      resolve(Some(&Switch::On), &slides).unwrap(),
      vec![true, false, true]
    );
    let slides = [slide(None), slide(Some(Switch::On)), slide(None)];
    assert_eq!(
      resolve(Some(&Switch::Off), &slides).unwrap(),
      vec![false, true, false]
    );
  }

  #[test]
  fn an_unreadable_deck_value_is_refused_naming_the_key_and_value() {
    let e = resolve(Some(&Switch::Unreadable("ture".into())), &[slide(None)]).unwrap_err();
    assert!(
      e.message.contains("'numbering'") && e.message.contains("'ture'"),
      "{}",
      e.message
    );
    assert_eq!(e.code, 2);
  }

  #[test]
  fn an_unreadable_slide_value_is_refused_naming_the_slide() {
    let slides = [slide(None), slide(Some(Switch::Unreadable("maybe".into())))];
    let e = resolve(Some(&Switch::On), &slides).unwrap_err();
    assert!(e.message.starts_with("slide 2:"), "{}", e.message);
    assert!(
      e.message.contains("'numbering'") && e.message.contains("'maybe'"),
      "{}",
      e.message
    );
  }
}
