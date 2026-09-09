//! The shell, and the five things it does not carry.
//!
//! **THE PLAYER IS DATA, NOT CODE THIS CRATE WROTE.** `player.html` is pulled
//! from the reference and is **TWO LINES different, both deliberate and both
//! recorded** -- `diff` against the reference is the audit, and it should print
//! exactly these two.
//!
//! **ONE IS A REMOVAL.** `add("Producer", REEL.producer)` where the reference has
//! `|| "Snorkeltoast"` after it, measured by
//! `the_shell_carries_no_brand_of_anybody_s` below: `include_str!` puts this file
//! in the binary, so a verbatim pull would have put a brand literal in a Utilz
//! artifact and taken the H3 strings count off zero. Nothing in the CONTRACT
//! gates on it -- hv withdrew that row -- and the estate's own check does.
//!
//! **THE OTHER IS AN ADDITION, AND IT IS THE ONE A CARELESS PULL LOSES.**
//! `<meta name="showreel-producer" content="__PRODUCER__">` is the build's stamp
//! of its own identity, which `showreel-harness` reads to derive what produced an
//! artifact instead of inferring it from whatever compiler sat beside it. **The
//! reference writes no such tag, so ABSENCE derives Python** -- the same shape
//! design.md 4.1 gives the absent init stamp. A pull that drops the marker takes
//! `the_shell_declares_each_marker_exactly_once` to 0 and makes `render` refuse,
//! so the loss is loud. Ruled in design.md 4.5.
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
const PRODUCER: &str = "__PRODUCER__";

/// Every marker the shell is expected to carry.
///
/// **THIS IS THE AUTHORITY AND `subs` BELOW IS THE WORK, AND THEY ARE
/// DELIBERATELY TWO THINGS.** Control 1 checks the shell against THIS list;
/// the substitution walks the marker-to-value pairs. So a fifth marker added to
/// one and forgotten in the other does not pass quietly: added here and not to
/// `subs`, the marker is checked, never substituted, and
/// `every_marker_is_filled_and_none_survives_into_the_artifact` fails. One list
/// used for both would agree with itself by construction and report nothing.
const MARKERS: [&str; 5] = [THEME, TITLE, FAVICON, DATA, PRODUCER];

/// What the shell is missing, in the order the reference substitutes it --
/// **plus one the reference never substitutes at all.**
///
/// `producer` is the build's own stamp, read back by `showreel-harness`'s
/// `producer_stamp`. It is last because the reference has no such field: the
/// four above are a port of an order, this one is an addition, and collapsing
/// the two would lose which is which. design.md 4.5 rules it.
pub struct Filling<'a> {
  pub theme_css: &'a str,
  pub title: &'a str,
  pub favicon: &'a str,
  pub data: &'a str,
  pub producer: &'a str,
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
  let subs =
    [(THEME, f.theme_css), (TITLE, f.title), (FAVICON, f.favicon), (DATA, f.data), (PRODUCER, f.producer)];

  // **CONTROL 2: A STAMP THE INSTRUMENT CANNOT READ IS WORSE THAN NO STAMP.**
  // `showreel-harness:1236` is `"stamp" if stamp else "adjacency (UNVERIFIED)"`
  // -- Python truthiness -- so an EMPTY stamp matches the harness regex, yields
  // `""`, and grades identically to an artifact carrying no stamp at all. A
  // double quote closes `content="..."` early and defeats both the tag and the
  // regex's own `[^"]*`. **BOTH FAILURES ARE SILENT AT THE READING SIDE**, which
  // is exactly what makes them this side's to refuse. design.md 4.5.
  let fault = if f.producer.is_empty() {
    Some("empty, which grades as 'adjacency (UNVERIFIED)' -- what an UNSTAMPED artifact grades as")
  } else if f.producer.contains('"') {
    Some("carrying a double quote, which closes content=\"...\" early and breaks the harness regex")
  } else {
    None
  };
  if let Some(why) = fault {
    return Err(Failure::new(
      format!("the producer stamp is {why}"),
      "name the implementation, its version, and a policy identifier covering long edge, filter, quality and the alpha rule",
    ));
  }

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
    Filling {
      theme_css: "body{color:red}",
      title,
      favicon: "<link rel=icon>",
      data,
      producer: "test-producer",
    }
  }

  /// **AC-2.1 LEG 2, TEMPLATE HALF: THE ARTIFACT SAYS WHAT BUILT IT.**
  /// `showreel-harness`'s `STAMP_RE` is
  /// `<meta\s+name="showreel-producer"\s+content="([^"]*)"\s*/?>`, so the
  /// assertion below is the exact byte sequence that regex matches with one
  /// space at each `\s+`. **The reference writes no such tag**, which is what
  /// makes its ABSENCE derive Python rather than mean nothing -- design.md 4.5.
  #[test]
  fn the_artifact_stamps_its_own_producer_where_the_harness_looks_for_it() {
    let out = render(SHELL, &filling("T", "{}")).unwrap();
    assert!(
      out.contains(r#"<meta name="showreel-producer" content="test-producer">"#),
      "the stamp must land in the shape STAMP_RE reads"
    );
    assert_eq!(out.matches("showreel-producer").count(), 1, "and exactly once");
  }

  /// **THE SILENT ZERO THIS REFUSAL EXISTS FOR.** `showreel-harness:1236` is
  /// `"stamp" if stamp else "adjacency (UNVERIFIED)"` -- Python truthiness -- so
  /// an empty `content=""` MATCHES the regex, yields `""`, and grades exactly as
  /// an unstamped artifact does. **The reading side cannot tell the two apart by
  /// construction**, so an empty stamp would make leg 2 fail to move while every
  /// run still looked correct. Nothing but this refusal reports it.
  #[test]
  fn an_empty_producer_is_refused_because_the_harness_cannot_tell_it_from_no_stamp_at_all() {
    let mut f = filling("T", "{}");
    f.producer = "";
    let e = render(SHELL, &f).unwrap_err();
    assert!(e.message.contains("empty"), "{}", e.message);
    assert!(e.message.contains("adjacency (UNVERIFIED)"), "and says what it would grade as: {}", e.message);
  }

  /// A quote closes `content="..."` early: the tag breaks AND `[^"]*` stops
  /// short, so the harness reads a truncated stamp rather than failing. Silent
  /// in the same way and refused for the same reason.
  #[test]
  fn a_producer_carrying_a_quote_is_refused_before_it_breaks_the_tag() {
    let mut f = filling("T", "{}");
    f.producer = "showreel-rs \"0.1\"";
    let e = render(SHELL, &f).unwrap_err();
    assert!(e.message.contains("double quote"), "{}", e.message);
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
