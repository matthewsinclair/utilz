// One on/off switch, read the same way wherever a deck writes one: the
// `mermaid:` and `numbering:` front-matter keys and the `numbering:` slide
// directive (issues 0065 and 0066).
//
// **ONE VOCABULARY, hv's ruling of 17 Oct 2026.** `on`, `true`, `yes` and `1`
// read as on; `off`, `false`, `no` and `0` as off; in any case. It is the union
// of what `mermaid:` and `numbering:` each read before, so no deck that built
// changes meaning, and only a value neither key read is refused. A second list
// in any one place is how `mermaid: yes` came to mean on while `numbering: yes`
// was refused.
//
// **AN UNREADABLE VALUE IS KEPT, NEVER DEFAULTED.** `mermaid: ture` read as off
// built a deck whose diagrams were plain code blocks with nothing to say why.
// The reader keeps the value it could not read, and the caller refuses it by
// name, through `refusal` below so every switch says the same thing.

use crate::Failure;

#[derive(Debug, Clone, PartialEq)]
pub enum Switch {
  On,
  Off,
  /// A value outside the vocabulary, kept verbatim so the refusal can quote it.
  Unreadable(String),
}

impl Switch {
  /// Read one value against the one vocabulary; nothing else.
  pub fn read(value: &str) -> Self {
    match value.trim().to_ascii_lowercase().as_str() {
      "on" | "true" | "yes" | "1" => Self::On,
      "off" | "false" | "no" | "0" => Self::Off,
      _ => Self::Unreadable(value.trim().to_string()),
    }
  }
}

/// A front-matter switch as on or off, absent being off; an unreadable value
/// is refused naming the key and the value.
pub fn deck_key(key: &str, value: Option<&Switch>) -> Result<bool, Failure> {
  match value {
    None | Some(Switch::Off) => Ok(false),
    Some(Switch::On) => Ok(true),
    Some(Switch::Unreadable(value)) => Err(refusal(format!(
      "front-matter key '{key}' has value '{value}', which prez cannot read"
    ))),
  }
}

/// The one refusal every switch gives, with the vocabulary as its hint.
pub fn refusal(message: String) -> Failure {
  Failure::new(
    message,
    "use on or off (true, false, yes, no, 1 and 0 also work)",
  )
}

#[cfg(test)]
mod tests {
  use super::*;

  #[test]
  fn the_on_words_are_read_in_any_case() {
    for on in ["on", "ON", "true", "True", "yes", "YES", "1", " on "] {
      assert_eq!(Switch::read(on), Switch::On, "{on:?}");
    }
  }

  #[test]
  fn the_off_words_are_read_in_any_case() {
    for off in ["off", "Off", "false", "FALSE", "no", "No", "0"] {
      assert_eq!(Switch::read(off), Switch::Off, "{off:?}");
    }
  }

  #[test]
  fn anything_else_is_kept_unread() {
    for bad in ["ture", "enabled", "y", "2", ""] {
      assert_eq!(Switch::read(bad), Switch::Unreadable(bad.into()), "{bad:?}");
    }
  }

  #[test]
  fn an_absent_key_is_off() {
    assert!(!deck_key("mermaid", None).unwrap());
    assert!(deck_key("mermaid", Some(&Switch::On)).unwrap());
    assert!(!deck_key("mermaid", Some(&Switch::Off)).unwrap());
  }

  #[test]
  fn an_unreadable_key_is_refused_naming_the_key_and_value() {
    let e = deck_key("mermaid", Some(&Switch::Unreadable("ture".into()))).unwrap_err();
    assert_eq!(
      e.message,
      "front-matter key 'mermaid' has value 'ture', which prez cannot read"
    );
    assert_eq!(e.code, 2);
  }
}
