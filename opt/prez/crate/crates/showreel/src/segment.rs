//! Segment shapes, and the refusal of a key that does not belong to one.
//!
//! **A TYPO IN `type:` BUILDS A DIFFERENT REEL AND SAYS NOTHING. MEASURED, NOT
//! INFERRED.** The reference compares `stype` against eleven literals and has no
//! `else` -- an unrecognised type falls through to the gallery branch. Run
//! against the tool at `f593de8`, three arms:
//!
//! | config                             | rc | outcome                                    |
//! | ---------------------------------- | -- | ------------------------------------------ |
//! | `type: crwal` **with** `from:`      | 0  | **built a 2-slide gallery, silently**      |
//! | `type: crwal` without `from:`       | 2  | refused as `resolved to no images`         |
//! | `type: crawl` (control)             | 0  | built a crawl, so spelling is what differs |
//!
//! The middle row names the wrong problem -- an author who mistyped a type is
//! sent to look at their assets directory. The first row is the serious one:
//! they asked for a crawl and got two pictures.
//!
//! **THE VALID SETS LIVE IN ONE TABLE BECAUSE serde CANNOT EXPRESS THEM.**
//! `#[serde(flatten)]` and `deny_unknown_fields` are mutually exclusive, so an
//! internally-tagged enum would have to repeat the seven common fields in every
//! one of twelve variants -- the duplication Highlander exists to prevent, in
//! the file whose job is to be the one description of a segment. A flat struct
//! carrying the union of every field would accept `bg:` on a crawl, which is
//! the silent-ignore this module exists to end. So the shapes are data, checked
//! against the parsed keys, and the error names the type as well as the key.

use artifact::Failure;

/// Fields every segment may carry, whatever its type.
pub const COMMON: &[&str] = &["id", "type", "dwell", "ease", "transition", "fit", "motion"];

/// One segment type and the fields that belong to it alone.
pub struct Shape {
  pub name: &'static str,
  pub fields: &'static [&'static str],
}

/// **THE TWELVE SHAPES, TRANSCRIBED FROM `collect_segment` RATHER THAN FROM A
/// CONFIG.** Eleven are explicit branches; `gallery` is the fallthrough and is
/// the reference's default for a segment with no `type:` at all.
pub const SHAPES: &[Shape] = &[
  Shape { name: "crawl", fields: &["source"] },
  Shape { name: "card", fields: &["headline", "sub", "bg"] },
  Shape { name: "statement", fields: &["kicker", "headline", "body", "bg"] },
  Shape { name: "faq", fields: &["headline", "items", "bg"] },
  Shape { name: "atwork", fields: &["kicker", "name", "strap", "caption", "qr", "bg"] },
  Shape { name: "strapline", fields: &["mark", "lines", "bg"] },
  Shape { name: "points", fields: &["headline", "body", "points", "bg"] },
  Shape { name: "venue", fields: &["image", "kicker", "headline", "at", "city", "bg"] },
  Shape { name: "wordmark", fields: &["top", "mid", "bottom", "bg"] },
  Shape { name: "socials", fields: &["layout", "headline", "bg", "bgs"] },
  Shape { name: "logo", fields: &["file"] },
  Shape { name: "gallery", fields: &["from", "files", "exclude"] },
];

/// The reference's default when a segment declares no `type:`.
pub const DEFAULT_SHAPE: &str = "gallery";

fn shape(name: &str) -> Option<&'static Shape> {
  SHAPES.iter().find(|s| s.name == name)
}

fn names() -> String {
  let mut all: Vec<&str> = SHAPES.iter().map(|s| s.name).collect();
  all.sort_unstable();
  all.join(", ")
}

/// Check one segment's declared type and key set.
pub fn validate(index: usize, seg: &serde_yaml::Value) -> Result<(), Failure> {
  let map = seg.as_mapping().ok_or_else(|| {
    Failure::new(
      format!("segment {index} is not a mapping"),
      "each entry under segments: is a block of key: value pairs",
    )
  })?;

  let id = map
    .get(serde_yaml::Value::from("id"))
    .and_then(|v| v.as_str())
    .map_or_else(|| format!("{index}"), str::to_string);

  let declared = map.get(serde_yaml::Value::from("type")).and_then(|v| v.as_str());
  let kind = declared.unwrap_or(DEFAULT_SHAPE);
  let Some(shape) = shape(kind) else {
    return Err(Failure::new(
      format!("segment '{id}': unknown type '{kind}'"),
      format!(
        "one of: {} -- an unrecognised type is built as a {DEFAULT_SHAPE} by the tool this \
         ports, silently when the segment carries a from:",
        names()
      ),
    ));
  };

  for key in map.keys() {
    let Some(key) = key.as_str() else {
      return Err(Failure::new(
        format!("segment '{id}': a key is not a string"),
        "keys are plain names like dwell: or headline:",
      ));
    };
    if COMMON.contains(&key) || shape.fields.contains(&key) {
      continue;
    }
    let mut valid: Vec<&str> = COMMON.iter().chain(shape.fields.iter()).copied().collect();
    valid.sort_unstable();
    return Err(Failure::new(
      format!("segment '{id}': type '{kind}' has no key '{key}'"),
      format!("expected one of: {}", valid.join(", ")),
    ));
  }
  Ok(())
}

/// Check every segment, reporting the first that fails.
pub fn validate_all(segments: &[serde_yaml::Value]) -> Result<(), Failure> {
  segments.iter().enumerate().try_for_each(|(i, s)| validate(i, s))
}

#[cfg(test)]
mod tests {
  use super::*;

  // **THREE OF THESE FIVE CAN FAIL ON THE DEFECT.** Injecting the reference's
  // behaviour -- validate returning Ok unconditionally -- fails exactly the
  // mistyped-type, cross-type-key and default-shape tests. The injection was
  // checked by two counts, `unknown type '` and `shape.fields.contains`, both
  // reading 0.
  //
  // **THOSE TWO COUNTS WERE PRINTED AND READ; THEY DID NOT GATE THE RUN**, and
  // this comment claimed "proved applied first" until vc's AC-1.15 audit asked
  // which form the step took. Reporting two values is what a reading looks
  // like; a refusal would have needed neither. Recorded as non-compliant rather
  // than restated as a refusal the artefact cannot show -- see limits.rs for
  // the same note and the same reason.
  //
  // The other two are not proofs of this checker and must stay green under both:
  // `every_shape_...` tests the TABLE, and `every_segment_of_the_live_reel_...`
  // must pass under a no-op validator because a no-op accepts everything. The
  // live-reel test's job is the other direction -- catching a table so strict it
  // refuses a real reel.
  //
  // **AND THE LIVE REEL BOUNDS WHAT IT CAN PROVE.** It exercises all twelve
  // shapes but not every FIELD of them, so a field I transcribed wrongly for a
  // type the reel does not use that way is invisible here.

  fn seg(yaml: &str) -> serde_yaml::Value {
    serde_yaml::from_str(yaml).unwrap()
  }

  /// **THE SHAPE TABLE IS A POPULATION AND ITS SIZE IS ASSERTED.** Eleven
  /// explicit branches in `collect_segment` plus the gallery fallthrough. A
  /// table that silently loses a row would let that type's segments through
  /// unchecked, which is the defect this module exists to end, one type at a
  /// time.
  #[test]
  fn every_shape_the_reference_has_is_declared_here() {
    assert_eq!(SHAPES.len(), 12, "eleven branches plus the gallery fallthrough");
    for want in [
      "crawl", "card", "statement", "faq", "atwork", "strapline", "points", "venue", "wordmark",
      "socials", "logo", "gallery",
    ] {
      assert!(shape(want).is_some(), "missing shape: {want}");
    }
    let mut seen: Vec<&str> = SHAPES.iter().map(|s| s.name).collect();
    seen.sort_unstable();
    seen.dedup();
    assert_eq!(seen.len(), SHAPES.len(), "a duplicated shape name would shadow silently");
  }

  /// The measured defect, refused: `crwal` built a gallery and said nothing.
  #[test]
  fn a_mistyped_segment_type_is_refused_and_the_valid_set_is_given() {
    let e = validate(0, &seg("{id: mistyped, type: crwal, from: assets/art}")).unwrap_err();
    assert!(e.message.contains("segment 'mistyped'"), "{}", e.message);
    assert!(e.message.contains("crwal"), "names what was written: {}", e.message);
    let remedy = e.remedy.unwrap();
    assert!(remedy.contains("crawl"), "offers the intended type: {remedy}");
    assert!(remedy.contains("gallery"), "and names what it would silently become: {remedy}");
  }

  /// A key belonging to ANOTHER type is not "unknown" to the config as a whole,
  /// and is exactly what a flat union struct would wave through. It is silently
  /// ignored by the reference.
  #[test]
  fn a_key_valid_for_a_different_type_is_still_refused() {
    let e = validate(0, &seg("{id: opening, type: crawl, bg: yellow}")).unwrap_err();
    assert!(e.message.contains("type 'crawl' has no key 'bg'"), "{}", e.message);
    assert!(e.remedy.unwrap().contains("source"), "gives crawl's own fields");
    validate(0, &seg("{id: meet, type: card, bg: yellow}")).expect("bg IS a card's key");
  }

  #[test]
  fn a_segment_with_no_type_is_a_gallery_as_the_reference_defaults_it() {
    validate(0, &seg("{id: art, from: assets/art}")).expect("no type: means gallery");
    let e = validate(0, &seg("{id: art, source: session}")).unwrap_err();
    assert!(e.message.contains("has no key 'source'"), "{}", e.message);
  }

  /// **BOTH DIRECTIONS OVER THE REEL BEING PORTED.** Every segment of the live
  /// 45h config must validate; a suite that only refuses is satisfied by a
  /// validator that refuses everything.
  #[test]
  fn every_segment_of_the_live_reel_validates() {
    #[derive(serde::Deserialize)]
    struct Just {
      segments: Vec<serde_yaml::Value>,
    }
    let reel: Just =
      serde_yaml::from_str(include_str!("../fixtures/45h.showreel.yaml")).unwrap();
    assert_eq!(reel.segments.len(), 15, "the population is the reel");
    validate_all(&reel.segments).expect("the live reel must validate whole");
  }
}
