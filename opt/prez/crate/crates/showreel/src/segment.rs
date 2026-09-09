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

/// The values `fit:` may take.
///
/// **A KEY CHECK AND A VALUE CHECK ARE DIFFERENT REFUSALS AND THIS MODULE OWES
/// BOTH.** `validate` already refuses `bg:` on a crawl; until now nothing
/// refused `fit: cvoer`, which passed every check this port had and would have
/// reached the player as a class name that styles nothing. **The typo is the
/// same defect as the mistyped `type:` one function up** -- a config that builds
/// something other than what it says, silently -- and it lived in the module
/// whose whole subject is that defect.
pub const FITS: &[&str] = &["cover", "contain", "matte", "blur", "logo"];

/// The values `transition:` may take.
pub const TRANSITIONS: &[&str] = &["cut", "fade", "dissolve", "push", "wipe"];

/// The values `motion:` may take.
pub const MOTIONS: &[&str] =
  &["none", "kenburns", "kenburns-out", "drift", "drift-l", "drift-r"];

/// A pace preset: every rendering default, not just the two durations.
///
/// **THE PORT CARRIED HALF OF THIS TABLE IN A `match` IN `main.rs`** -- `attract`
/// and `ambient` mapped to a dwell and an ease, with the transition, motion and
/// fit silently absent. Two homes for one table, one of them incomplete, which
/// is the Highlander shape rather than an oversight: the missing three had no
/// consumer yet, so nothing reported that they were gone.
#[derive(Debug, Clone, Copy)]
pub struct Pace {
  pub name: &'static str,
  pub dwell: &'static str,
  pub ease: &'static str,
  pub transition: &'static str,
  pub motion: &'static str,
  pub fit: &'static str,
}

/// The two presets, with the reason each exists.
///
/// `attract` is window-facing -- motion catches an eye moving past at walking
/// pace. `ambient` is indoors near staff: long dwell, slow drift, nothing that
/// pulses.
pub const PACES: &[Pace] = &[
  Pace {
    name: "attract",
    dwell: "6s",
    ease: "0.9s",
    transition: "dissolve",
    motion: "kenburns",
    fit: "cover",
  },
  Pace {
    name: "ambient",
    dwell: "11s",
    ease: "1.6s",
    transition: "dissolve",
    motion: "drift",
    fit: "cover",
  },
];

/// The reference's pace when a config names none.
pub const DEFAULT_PACE: &str = "attract";

/// Resolve a pace name, refusing an unknown one with the roster.
pub fn pace(name: Option<&str>) -> Result<&'static Pace, Failure> {
  let want = name.unwrap_or(DEFAULT_PACE);
  PACES.iter().find(|p| p.name == want).ok_or_else(|| {
    Failure::new(
      format!("unknown pace '{want}'"),
      format!("one of: {}", PACES.iter().map(|p| p.name).collect::<Vec<_>>().join(", ")),
    )
  })
}

/// Refuse a value that is not in its vocabulary.
///
/// **THE REMEDY LISTS THE WHOLE SET, SORTED.** A refusal naming only the bad
/// value sends the author to the README; naming the alternatives ends it at the
/// terminal.
pub fn value(field: &str, got: &str, allowed: &[&str], owner: &str) -> Result<(), Failure> {
  if allowed.contains(&got) {
    return Ok(());
  }
  let mut names: Vec<&str> = allowed.to_vec();
  names.sort_unstable();
  Err(Failure::new(
    format!("{owner}: unknown {field} '{got}'"),
    format!("one of: {}", names.join(", ")),
  ))
}

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

  /// **THE THREE VOCABULARIES, WITH THEIR SIZES ASSERTED.** A set that silently
  /// loses a member starts refusing configs that built yesterday; one that gains
  /// a member admits a value the player styles nothing for. Both are silent, and
  /// the count is what makes either visible.
  #[test]
  fn each_vocabulary_is_the_reference_set_and_its_size_is_stated() {
    assert_eq!(FITS.len(), 5);
    assert_eq!(TRANSITIONS.len(), 5);
    assert_eq!(MOTIONS.len(), 6);
    for want in ["cover", "contain", "matte", "blur", "logo"] {
      assert!(FITS.contains(&want), "missing fit: {want}");
    }
    for want in ["cut", "fade", "dissolve", "push", "wipe"] {
      assert!(TRANSITIONS.contains(&want), "missing transition: {want}");
    }
    for want in ["none", "kenburns", "kenburns-out", "drift", "drift-l", "drift-r"] {
      assert!(MOTIONS.contains(&want), "missing motion: {want}");
    }
  }

  /// A value refusal names the field, the bad value AND the whole set. **The
  /// roster is the half that ends it at the terminal** rather than sending the
  /// author to the README.
  #[test]
  fn a_value_outside_its_vocabulary_is_refused_with_the_whole_set() {
    assert!(value("fit", "cover", FITS, "segment 'x'").is_ok());
    let e = value("fit", "cvoer", FITS, "segment 'x'").unwrap_err();
    assert!(e.message.contains("segment 'x'"), "names the owner: {}", e.message);
    assert!(e.message.contains("cvoer"), "names the value: {}", e.message);
    let remedy = e.remedy.expect("a vocabulary refusal lists the vocabulary");
    for want in FITS {
      assert!(remedy.contains(want), "lists {want}: {remedy}");
    }
    // Sorted, so two runs give one message and a reader can scan it.
    assert_eq!(remedy, "one of: blur, contain, cover, logo, matte");
  }

  /// **THE PACE TABLE CARRIES FIVE FIELDS, NOT TWO.** The port held `attract`
  /// and `ambient` as a dwell and an ease in a `match` in `main.rs`, with the
  /// transition, motion and fit silently absent -- two homes for one table, one
  /// of them incomplete, and nothing reported it because nothing consumed the
  /// missing three yet.
  #[test]
  fn a_pace_preset_carries_every_rendering_default() {
    let p = pace(Some("attract")).unwrap();
    assert_eq!((p.dwell, p.ease), ("6s", "0.9s"));
    assert_eq!((p.transition, p.motion, p.fit), ("dissolve", "kenburns", "cover"));

    let p = pace(Some("ambient")).unwrap();
    assert_eq!((p.dwell, p.ease), ("11s", "1.6s"));
    assert_eq!((p.transition, p.motion, p.fit), ("dissolve", "drift", "cover"));

    assert_eq!(pace(None).unwrap().name, DEFAULT_PACE, "no pace named takes the default");

    // **AND EVERY PRESET'S OWN DEFAULTS MUST BE IN THE VOCABULARIES.** A preset
    // naming a transition the player does not have would refuse every config
    // that omits the key -- the failure would look like the config's.
    for p in PACES {
      assert!(TRANSITIONS.contains(&p.transition), "{}: {}", p.name, p.transition);
      assert!(MOTIONS.contains(&p.motion), "{}: {}", p.name, p.motion);
      assert!(FITS.contains(&p.fit), "{}: {}", p.name, p.fit);
    }
  }

  #[test]
  fn an_unknown_pace_is_refused_with_the_roster() {
    let e = pace(Some("frantic")).unwrap_err();
    assert!(e.message.contains("frantic"), "{}", e.message);
    assert_eq!(e.remedy.unwrap(), "one of: attract, ambient");
  }

  /// **TEST AGAINST SOMETHING YOU DID NOT WRITE.** Every `fit:`, `transition:`
  /// and `motion:` the live 45h config states must pass the vocabularies -- the
  /// refusal cases above exercise values I chose, this exercises values a reel
  /// author chose, which is what caught a missing serde rename one module over.
  #[test]
  fn every_rendering_value_the_live_reel_states_is_in_its_vocabulary() {
    let reel: serde_yaml::Value =
      serde_yaml::from_str(include_str!("../fixtures/45h.showreel.yaml")).unwrap();
    let segments = reel.get("segments").and_then(|v| v.as_sequence()).expect("segments");
    let mut checked = 0;
    for seg in segments {
      let map = seg.as_mapping().expect("a mapping");
      for (field, allowed) in
        [("fit", FITS), ("transition", TRANSITIONS), ("motion", MOTIONS)]
      {
        if let Some(v) = map.get(serde_yaml::Value::from(field)).and_then(|v| v.as_str()) {
          value(field, v, allowed, "live reel").unwrap_or_else(|e| {
            panic!("the live reel states a value this port refuses: {}", e.message)
          });
          checked += 1;
        }
      }
    }
    // **THE COUNT IS THE CONTROL.** A reel stating none of these keys would pass
    // this test having checked nothing, which is a green over an empty
    // population -- the shape this thread keeps finding.
    assert!(checked > 0, "the live reel stated no rendering values at all; test proved nothing");
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
