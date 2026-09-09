//! The shell, and the four things it does not carry.
//!
//! **THE PLAYER IS DATA, NOT CODE THIS CRATE WROTE.** `player.html` is pulled
//! from the reference and is ONE LINE different -- `add("Producer",
//! REEL.producer)` where the reference has `|| "Snorkeltoast"` after it. That
//! single divergence is deliberate and is measured by
//! `the_shell_carries_no_brand_of_anybody_s` below: `include_str!` puts this file
//! in the binary, so a verbatim pull would have put a brand literal in a Utilz
//! artifact and taken the H3 strings count off zero. Nothing in the CONTRACT
//! gates on it -- hv withdrew that row -- and the estate's own check does.
//!
//! **AND ONE LINE IS DELIBERATELY NOT TOUCHED.** `const LIM = REEL.limits` is
//! half of AC-3.6's runtime leg: the photosensitivity cap the runtime applies is
//! READ OFF THE PAYLOAD rather than written out again in JavaScript. The shell's
//! own comment says why -- "a safety limit that exists twice, in two languages,
//! is one limit and one liability" -- and a port that hoisted those numbers into
//! JS constants while tidying would rebuild exactly the defect `limits.rs`
//! exists to prevent, in the commit that ports the fix. Asserted below rather
//! than left to whoever reads the diff.

use artifact::Failure;

/// The player shell, one line different from the reference.
pub const SHELL: &str = include_str!("../player.html");

const THEME: &str = "/*__THEME__*/";
const TITLE: &str = "__TITLE__";
const FAVICON: &str = "<!--__FAVICON__-->";
const DATA: &str = "/*__DATA__*/";

/// Every marker the shell is expected to carry.
///
/// **THIS IS THE AUTHORITY AND `subs` BELOW IS THE WORK, AND THEY ARE
/// DELIBERATELY TWO THINGS.** Control 1 checks the shell against THIS list;
/// the substitution walks the marker-to-value pairs. So a fifth marker added to
/// one and forgotten in the other does not pass quietly: added here and not to
/// `subs`, the marker is checked, never substituted, and
/// `every_marker_is_filled_and_none_survives_into_the_artifact` fails. One list
/// used for both would agree with itself by construction and report nothing.
const MARKERS: [&str; 4] = [THEME, TITLE, FAVICON, DATA];

/// What the shell is missing, in the order the reference substitutes it.
pub struct Filling<'a> {
  pub theme_css: &'a str,
  pub title: &'a str,
  pub favicon: &'a str,
  pub data: &'a str,
}

/// Fill the shell.
///
/// **ONE REFUSAL, AND A SECOND PROPERTY MADE STRUCTURAL RATHER THAN CHECKED.**
///
/// The reference does four sequential `str.replace` calls, which is safe on this
/// shell and is not safe in general: *"each marker occurs exactly once"* makes
/// one pass equal four passes **only if no substituted VALUE contains a
/// marker**. Replace #1 can emit text that #2 then rewrites. vc caught that this
/// module had proposed only the first half of that control.
///
/// **THEIR FIX WAS A SECOND REFUSAL AND THIS TAKES THE OTHER ROUTE, WHICH IS WHY
/// IT IS WRITTEN DOWN.** The substitution below is a genuine single pass whose
/// offsets are read from the UNMODIFIED shell, so a value containing a marker
/// cannot be rewritten by a later substitution -- the hazard is absent rather
/// than guarded. Refusing such a value on top of that would reject a config the
/// implementation renders correctly: the reference CORRUPTS a title carrying
/// `/*__DATA__*/`, a sequential port would corrupt it too, and this one emits it
/// verbatim. **A refusal there would be a deliberate divergence that costs a
/// valid input and buys nothing.**
///
/// What the refusal WOULD have bought is protection against a later edit
/// simplifying this back to `str::replace` -- and
/// `a_value_that_carries_a_marker_is_emitted_verbatim` buys that too, by failing
/// against exactly that edit. **A test that proves the immunity beats a guard
/// that makes it unnecessary to have.**
///
/// Control 1 stays a refusal, because a shell disagreeing with this module about
/// the markers is a genuine defect: they ship together in one binary.
pub fn render(shell: &str, f: &Filling) -> Result<String, Failure> {
  let subs = [(THEME, f.theme_css), (TITLE, f.title), (FAVICON, f.favicon), (DATA, f.data)];

  for marker in MARKERS {
    let found = shell.matches(marker).count();
    if found != 1 {
      return Err(Failure::new(
        format!("the player shell contains {found} occurrence(s) of {marker}, expected exactly 1"),
        "the shell and this module disagree about the template; they ship together and must be changed together",
      ));
    }
  }

  // ONE PASS OVER THE ORIGINAL. Each marker's offset is read from the unmodified
  // shell, so nothing any value contains can be mistaken for a marker.
  let mut at: Vec<(usize, &str, &str)> = subs
    .iter()
    .map(|(marker, value)| {
      let at = shell.find(marker).expect("the count above found exactly one");
      (at, *marker, *value)
    })
    .collect();
  at.sort_unstable_by_key(|(offset, _, _)| *offset);

  let grown: usize = subs.iter().map(|(_, value)| value.len()).sum();
  let mut out = String::with_capacity(shell.len() + grown);
  let mut cursor = 0;
  for (offset, marker, value) in at {
    out.push_str(&shell[cursor..offset]);
    out.push_str(value);
    cursor = offset + marker.len();
  }
  out.push_str(&shell[cursor..]);
  Ok(out)
}

#[cfg(test)]
mod tests {
  use super::*;

  fn filling<'a>(title: &'a str, data: &'a str) -> Filling<'a> {
    Filling { theme_css: "body{color:red}", title, favicon: "<link rel=icon>", data }
  }

  /// **H3, ASSERTED RATHER THAN MEASURED AFTER THE FACT.** `strings` on the built
  /// binary catches this too, and only if somebody runs it; this fails the build.
  #[test]
  fn the_shell_carries_no_brand_of_anybody_s() {
    for brand in ["Snorkeltoast", "popupart", "POP^UP^ART"] {
      assert!(!SHELL.contains(brand), "the shell must carry no brand, found {brand}");
    }
    // The control: a string that IS there, so an empty haystack cannot pass.
    assert!(SHELL.contains("REEL.producer"), "and the check can see the shell at all");
  }

  /// **AC-3.6's RUNTIME LEG, TEMPLATE HALF.** The cap the runtime enforces is
  /// read off the payload. If a later edit hoists it into a JS literal this
  /// fails, which is the whole point of writing it down as a test.
  #[test]
  fn the_runtime_reads_its_limits_from_the_payload_and_not_from_javascript() {
    assert!(SHELL.contains("const LIM = REEL.limits;"), "the limits must come from the payload");
    assert!(SHELL.contains("LIM.max_ease"), "and the cap must be the one it read");
    assert!(SHELL.contains("LIM.min_dwell"), "and so must the dwell floor");
  }

  #[test]
  fn every_marker_is_filled_and_none_survives_into_the_artifact() {
    let out = render(SHELL, &filling("A Title", "{\"ok\":1}")).unwrap();
    for marker in MARKERS {
      assert!(!out.contains(marker), "{marker} survived into the artifact");
    }
    assert!(out.contains("<title>A Title</title>"), "the title landed where the shell wants it");
    assert!(out.contains("const REEL = {\"ok\":1};"), "and the payload landed inside the statement");
    assert!(out.contains("body{color:red}"), "and the theme");
    assert!(out.contains("<link rel=icon>"), "and the favicon");
  }

  /// **vc's CONTROL, TAKEN AS A PROPERTY INSTEAD OF A REFUSAL.** A title carrying
  /// the data marker is rewritten by the NEXT substitution under sequential
  /// replaces -- the reference corrupts it, silently. Here the offsets come from
  /// the unmodified shell, so the title survives verbatim and the payload still
  /// lands in its own place.
  ///
  /// **THIS IS THE TEST THAT FAILS IF ANYBODY SIMPLIFIES `render` BACK TO FOUR
  /// `str::replace` CALLS**, which is the thing the refusal would have bought and
  /// the reason no refusal is needed to buy it.
  #[test]
  fn a_value_that_carries_a_marker_is_emitted_verbatim() {
    let out = render(SHELL, &filling("look /*__DATA__*/ here", "{\"d\":7}")).unwrap();
    assert!(
      out.contains("<title>look /*__DATA__*/ here</title>"),
      "the title must survive a marker inside it"
    );
    assert!(out.contains("const REEL = {\"d\":7};"), "and the payload must still land");
    assert_eq!(out.matches("/*__DATA__*/").count(), 1, "exactly the one the title carried");
  }

  #[test]
  fn a_shell_that_lost_a_marker_is_refused_with_the_count() {
    let broken = SHELL.replace("<!--__FAVICON__-->", "");
    let e = render(&broken, &filling("t", "{}")).unwrap_err();
    assert!(e.message.contains("0 occurrence"), "{}", e.message);
    assert!(e.message.contains("__FAVICON__"), "names which one: {}", e.message);
  }

  #[test]
  fn a_shell_carrying_a_marker_twice_is_refused_rather_than_filled_once() {
    let doubled = SHELL.replace("<title>__TITLE__</title>", "<title>__TITLE__</title><!--__TITLE__-->");
    let e = render(&doubled, &filling("t", "{}")).unwrap_err();
    assert!(e.message.contains("2 occurrence"), "{}", e.message);
  }

  /// **THE SUBSTITUTION IS POSITIONAL, NOT ORDERED BY THE ARRAY.** The shell puts
  /// title and favicon before the theme and the theme before the data; a pass
  /// that walked the subs array in its own order would interleave the output.
  #[test]
  fn the_pass_follows_the_shell_s_order_and_not_the_argument_order() {
    let out = render(SHELL, &filling("TT", "{\"d\":0}")).unwrap();
    let title = out.find("<title>TT</title>").expect("title present");
    let theme = out.find("body{color:red}").expect("theme present");
    let data = out.find("const REEL = {\"d\":0};").expect("data present");
    assert!(title < theme, "title precedes the theme in the shell");
    assert!(theme < data, "and the theme precedes the payload");
  }

  /// The pulled shell is the reference's, so its markers must still be there.
  #[test]
  fn the_shell_declares_each_marker_exactly_once() {
    for marker in MARKERS {
      assert_eq!(SHELL.matches(marker).count(), 1, "{marker}");
    }
  }
}
