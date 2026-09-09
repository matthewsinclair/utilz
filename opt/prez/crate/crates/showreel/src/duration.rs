//! Durations as a config writes them: `7s`, `700ms`, `7`, `7.5s`.

use artifact::Failure;

/// Parse a duration into milliseconds.
///
/// **A VALUE THAT DOES NOT PARSE IS REFUSED HERE, WHERE THE REFERENCE
/// SILENTLY SUBSTITUTED A DEFAULT.** `showreel:119-129` returns its `default`
/// argument for anything its regex misses, so `dwell: 7 seconds` and
/// `dwell: banana` both build at the default and say nothing at all. That is
/// `IN-AG-NO-SILENT-001` on a field whose whole purpose is to be read: a person
/// who mistypes a duration gets a reel that is subtly not the one they
/// described, and no line of output distinguishes it from the one they wanted.
///
/// **AND IT IS A PARITY DIFFERENCE, SO IT IS NAMED RATHER THAN DISCOVERED.**
/// A config carrying an unparseable duration builds under Python and refuses
/// here. The 45h reel carries none -- every `dwell:` and `ease:` in it is
/// `<n>s` -- so the fidelity harness sees no difference on the population it
/// grades. A config that DID carry one would differ, loudly, in the direction
/// that tells somebody something.
///
/// The reference's own regex is `^\s*([\d.]+)\s*(ms|s)?\s*$`, which admits
/// `7.5.3` into a `float()` that raises on it -- so the silent path has a
/// traceback hiding inside it for one class of input. Refusing covers both.
pub fn parse(value: &str, field: &str, whose: &str) -> Result<u32, Failure> {
  let text = value.trim();
  let (digits, scale) = match text.strip_suffix("ms") {
    Some(rest) => (rest.trim_end(), 1.0),
    None => match text.strip_suffix('s') {
      Some(rest) => (rest.trim_end(), 1000.0),
      // A bare number is SECONDS, matching the reference. It reads as the
      // surprising choice and it is the compatible one.
      None => (text, 1000.0),
    },
  };
  let number: f64 = digits.parse().map_err(|_| {
    Failure::new(
      format!("{whose}: {field} '{value}' is not a duration"),
      "write a duration as 7s, 7.5s, 700ms, or a bare number of seconds",
    )
  })?;
  if !number.is_finite() || number < 0.0 {
    return Err(Failure::new(
      format!("{whose}: {field} '{value}' is not a duration"),
      "a duration is zero or more, and finite",
    ));
  }
  let ms = number * scale;
  if ms > f64::from(u32::MAX) {
    return Err(Failure::new(
      format!("{whose}: {field} '{value}' is longer than this tool can represent"),
      "a segment lasts seconds, not weeks -- check the unit",
    ));
  }
  Ok(ms as u32)
}

#[cfg(test)]
mod tests {
  use super::*;

  /// **THE POPULATION IS IN THE TEST**, and it carries the shapes the reference
  /// accepts plus the ones it silently swallowed. Both directions: eleven that
  /// must parse to an exact value, six that must refuse. A table where every row
  /// parses is satisfied by a parser that never refuses.
  #[test]
  fn every_duration_shape_is_decided() {
    let good: &[(&str, u32)] = &[
      ("7s", 7000),
      ("7.5s", 7500),
      ("0.9s", 900),
      ("700ms", 700),
      ("7", 7000),
      ("0", 0),
      ("  6s  ", 6000),
      ("6 s", 6000),
      ("1600ms", 1600),
      ("21s", 21000),
      ("0.001s", 1),
    ];
    let bad: &[&str] = &["banana", "7 seconds", "7.5.3", "", "-1s", "1e400s"];
    assert_eq!(good.len(), 11, "the population is the claim");
    assert_eq!(bad.len(), 6, "and a table with no refusing rows passes on a parser that never refuses");

    for (text, want) in good {
      match parse(text, "dwell", "segment 'x'") {
        Ok(got) => assert_eq!(got, *want, "{text:?}"),
        Err(e) => panic!("{text:?} should parse: {}", e.message),
      }
    }
    for text in bad {
      let e = parse(text, "dwell", "segment 'x'")
        .expect_err(&format!("{text:?} should refuse"));
      assert!(e.message.contains("segment 'x'"), "names whose it is: {}", e.message);
      assert!(e.remedy.is_some(), "a refusal carries its remedy: {}", e.message);
    }
  }

  /// The reference reads a bare number as SECONDS, which is the surprising half
  /// of its grammar and the half a port is most likely to get backwards. Pinned
  /// on its own because it is a compatibility decision, not an implementation
  /// detail: `dwell: 7` meaning 7ms would silently make every such reel strobe.
  #[test]
  fn a_bare_number_is_seconds_not_milliseconds() {
    assert_eq!(parse("7", "dwell", "s").unwrap(), 7000);
    assert_ne!(parse("7", "dwell", "s").unwrap(), 7);
  }
}
