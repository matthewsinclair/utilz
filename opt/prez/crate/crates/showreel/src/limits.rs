//! The photosensitivity envelope, applied HERE as well as in the player.

use artifact::Failure;

/// **NOT CONFIGURABLE, AND THAT IS THE POINT.** A reel that runs eight hours a
/// day two metres from someone working a till is a workplace, not a demo.
/// Values are the reference's, `showreel:65`, unchanged.
pub const MIN_DWELL_MS: u32 = 2_500;
pub const MIN_EASE_MS: u32 = 600;
/// **CAPPED AT 2400 BY hv, 2026-09-09, AND THE NUMBER IS LOAD-BEARING.** The
/// reference ships 3000, which EXCEEDS `MIN_DWELL_MS` -- so the longest ease the
/// runtime permits was longer than the shortest dwell it permits, and `?speed=`
/// could drive any reel into a crossfade that never finishes. 2400 closes that
/// space STRUCTURALLY rather than by refusal: runtime ease is at most 2400,
/// runtime dwell is at least 2500, so the crossing is unreachable instead of
/// forbidden. Swept over 1,927,206 authored-dwell x authored-ease x pace x speed
/// combinations: zero crossings at 2400, and crossings at 3000.
///
/// **A PARITY DIFFERENCE, NAMED:** a config with an authored ease above 2400
/// (or above ~1714 under `ambient`, which scales ease by 1.4 before the cap)
/// now renders a shorter crossfade than the Python build. The 45h reel is
/// unaffected -- its worst authored ease is 900 and both pace modes land
/// identically under either cap.
pub const MAX_EASE_MS: u32 = 2_400;

/// What a segment actually runs at, after the envelope.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Timing {
  pub dwell_ms: u32,
  pub ease_ms: u32,
}

/// Apply the envelope to one segment's authored timing, or refuse it by name.
///
/// **THE DEFECT THIS FIXES IS SPLIT ENFORCEMENT.** Verified from the reference
/// at `f593de8`: `showreel:799-800` applies `min_dwell` and `min_ease` and
/// **never applies `max_ease`**, while the cap lives only in the player's
/// `easeOf` -- and `showreel:988` ships the limits to the runtime under the
/// comment *"the runtime enforces the same floors"*, when it enforces one the
/// compiler does not have. One limit, two homes, disagreeing, plus a comment
/// asserting a parity that does not hold. The README's claim that compiler and
/// player both enforce the floors is false for exactly this one. `?speed=`
/// reaches the runtime, so a limit the compiler declines to apply is a limit
/// the URL can move.
///
/// **THIS PARAGRAPH READ "NOT AN UNLUCKY PAIR OF CONSTANTS" UNTIL THE
/// CONSTANTS WERE MEASURED, AND IT WAS ALSO AN UNLUCKY PAIR OF CONSTANTS.** The
/// reference's `MAX_EASE_MS` of 3000 exceeded `MIN_DWELL_MS`, a SECOND defect
/// independent of the split enforcement, which closing this module could not
/// fix. **hv capped the constant at 2400 and it is now unreachable rather than
/// refused.** The emphatic half of the original sentence was the wrong half,
/// and the fix was a constant rather than any of the enforcement I proposed.
///
/// **CITED BY TOKEN, NOT BY LINE, AND THIS MODULE EARNED THAT RULE THE HARD
/// WAY.** The first version of this doc cited `player.html` by line for the cap;
/// `3903937` had already moved it, and the line it named is now an unrelated
/// `getElementById`. **A stale citation and a live one are the same bytes to a
/// reader**, so a greppable name is the only form that survives somebody else
/// editing the file -- and I shipped the stale one in the module implementing
/// the row about that very line, an hour after writing the rule down.
///
/// **THE ease >= dwell REFUSAL READS THE AUTHORED VALUES, NOT THE CLAMPED
/// ONES**, and that choice is a superset rather than a preference. Effective
/// dwell is at least `MIN_DWELL_MS` and effective ease is at most `MAX_EASE_MS`,
/// so an authored pair that is sound can never clamp into an unsound one --
/// and **the argument does not depend on what those numbers ARE**: clamping only
/// ever raises dwell and only ever lowers an ease above the cap, so it holds for
/// any cap at or above `MIN_EASE_MS`. **This sentence cited 3000 until hv's cap
/// moved the constant to 2400, in the module whose own doc comment two
/// paragraphs above is about shipping a stale citation** -- reported by vc, and
/// the thing that sized it correctly was asking whether the proof leans on the
/// number. It does not. Proved by cases in
/// `clamping_can_never_manufacture_the_violation` below, and enforced there over
/// a grid rather than argued for here. Reading the authored pair therefore
/// catches everything the clamped pair would, plus the configs whose floors
/// happen to rescue them, and it names the numbers the author can actually find
/// in their file.
///
/// It REFUSES where `max_ease` CLAMPS, and the asymmetry is deliberate: a cap is
/// a safety limit the runtime already applies, so applying it here restores
/// parity without changing what ships. An ease that meets or exceeds its dwell
/// is incoherent rather than unsafe -- the transition never finishes before the
/// next one starts -- and no clamp rescues a config that asked for something
/// with no correct interpretation.
pub fn timing(segment: &str, dwell_ms: u32, ease_ms: u32) -> Result<Timing, Failure> {
  if ease_ms >= dwell_ms {
    return Err(Failure::new(
      format!(
        "segment '{segment}': ease {ease_ms}ms meets or exceeds dwell {dwell_ms}ms, \
         so the transition never finishes before the next slide begins"
      ),
      "give the segment a longer dwell or a shorter ease -- ease is the crossfade \
       INSIDE the dwell, not an addition to it",
    ));
  }
  Ok(Timing {
    dwell_ms: dwell_ms.max(MIN_DWELL_MS),
    ease_ms: ease_ms.clamp(MIN_EASE_MS, MAX_EASE_MS),
  })
}

#[cfg(test)]
mod tests {
  use super::*;

  // **TWO OF THESE SEVEN CAN FAIL ON THE DEFECT; THE OTHER FIVE CANNOT, AND
  // SAYING SO IS THE POINT.** Measured by injecting the reference's own
  // implementation -- min_dwell and min_ease applied, max_ease never, no
  // refusal: exactly
  // `max_ease_is_applied_by_the_compiler_and_not_only_by_the_player` and
  // `an_ease_that_meets_or_exceeds_its_dwell_is_refused_by_name` went red, and
  // the remaining five stayed green.
  //
  // **THE APPLYING STEP PRINTED AND WAS READ; IT DID NOT REFUSE, AND THIS
  // COMMENT SAID OTHERWISE UNTIL vc AUDITED AC-1.15.** It read "with the
  // injection proved applied before the result was read", which is a claim
  // about an act with nothing left to run -- and neither this comment nor the
  // commit that added it records the mechanism, so the stronger reading cannot
  // be evidenced from the artefact. **It is recorded as non-compliant rather
  // than repaired into a refusal I cannot show.** A red-proof that lives in a
  // comment has no control available: PROSE DOES NOT FAIL, arriving at the one
  // place this thread assumed it could not.
  //
  // The five are still worth having and are NOT proofs of this fix:
  // `the_two_floors_...` and `the_forty_five_h_reel_...` pin PARITY -- they must
  // pass under both implementations, and a change that broke them would be a
  // divergence rather than a fix -- and `clamping_can_never_manufacture_...`
  // bounds this module's own clamp, which the reference does not have.
  //
  // Written down because seven green tests under one heading read as seven
  // proofs, and a later reader deciding this behaviour is well covered would be
  // reading five controls as evidence.

  /// The row AC-3.11 exists for: the cap the reference never applied.
  #[test]
  fn max_ease_is_applied_by_the_compiler_and_not_only_by_the_player() {
    let t = timing("slow", 20_000, 5_000).unwrap();
    assert_eq!(t.ease_ms, MAX_EASE_MS, "the reference ships 5000 and lets the runtime cap it");
  }

  #[test]
  fn the_two_floors_are_applied_as_the_reference_applies_them() {
    let t = timing("quick", 1_000, 100).unwrap();
    assert_eq!(t.dwell_ms, MIN_DWELL_MS);
    assert_eq!(t.ease_ms, MIN_EASE_MS);
  }

  #[test]
  fn an_ease_that_meets_or_exceeds_its_dwell_is_refused_by_name() {
    for (dwell, ease) in [(3_000, 3_000), (3_000, 5_000), (10_000, 10_001)] {
      let e = timing("outro", dwell, ease).unwrap_err();
      assert!(e.message.contains("segment 'outro'"), "{}", e.message);
      assert!(e.message.contains(&format!("{ease}ms")), "names the ease: {}", e.message);
      assert!(e.message.contains(&format!("{dwell}ms")), "and the dwell: {}", e.message);
      assert!(e.remedy.is_some());
    }
  }

  /// **THE PROOF THAT READING AUTHORED VALUES LOSES NOTHING**, driven over a
  /// grid rather than asserted in prose. If any authored-sound pair could clamp
  /// into an unsound one, checking before the clamp would let it through.
  ///
  /// The grid is deliberately dense around the constants, which is where a
  /// boundary error would live: dwell is floored at 2500 and ease capped at
  /// 3000, so the interesting region is entirely below 4000.
  #[test]
  fn clamping_can_never_manufacture_the_violation() {
    let mut checked = 0;
    let mut sound = 0;
    for dwell in (0..=4_000).step_by(50) {
      for ease in (0..=4_000).step_by(50) {
        checked += 1;
        if ease >= dwell {
          continue; // authored-unsound: refused before any clamp runs
        }
        sound += 1;
        let t = timing("grid", dwell, ease).expect("authored-sound must not refuse");
        assert!(
          t.ease_ms < t.dwell_ms,
          "authored {dwell}/{ease} clamped to {}/{} and became unsound",
          t.dwell_ms,
          t.ease_ms
        );
      }
    }
    assert_eq!(checked, 81 * 81, "the grid is the claim");
    assert!(sound > 3_000, "and it must contain real sound pairs, not just refusals: {sound}");
  }

  /// **THE INVERSION THIS TEST ASKED FOR, KEEPING ITS FIXTURES.**
  ///
  /// It was `speed_can_still_cross_the_envelope_at_runtime_which_is_a_known_hole`
  /// and it recorded a hole with an instruction to invert rather than delete.
  /// hv capped `MAX_EASE_MS` at 2400 and the hole is shut.
  ///
  /// **CLOSED STRUCTURALLY, NOT BY REFUSAL, WHICH IS THE STRONGER FORM.** The
  /// compiler could never have closed it: at `?speed=16` a config with dwell
  /// 20000 and ease 2600 crosses while its authored ease sits eight times under
  /// its authored dwell, so nothing visible at compile time predicts it. With
  /// runtime ease bounded above by 2400 and runtime dwell bounded below by 2500,
  /// the crossing is unreachable for every config at every speed in both pace
  /// modes -- vc's finding, that both defects reduce to one condition.
  #[test]
  #[expect(
    clippy::assertions_on_constants,
    reason = "the constants ARE the subject: MAX_EASE_MS sitting below MIN_DWELL_MS is what \
              makes the crossing unreachable, so the assertion is deliberately \
              compile-time-decidable. `expect` rather than `allow` so that restructuring which \
              makes this no longer constant is itself reported."
  )]
  fn the_envelope_is_closed_structurally_so_speed_cannot_cross_it() {
    assert!(
      MAX_EASE_MS < MIN_DWELL_MS,
      "the whole guarantee: the longest permitted ease must be shorter than the \
       shortest permitted dwell, or ?speed= can drive any reel into a crossfade \
       that never finishes"
    );

    // The player's own arithmetic, transcribed from its `dwellOf` and `easeOf`.
    // dwellOf divides by SPEED; easeOf does not, which is why the bound must be
    // structural rather than proportional.
    let runtime = |dwell: f64, ease: f64, ambient: bool, speed: f64| {
      let d = (dwell * if ambient { 1.5 } else { 1.0 } / speed).max(f64::from(MIN_DWELL_MS));
      let e = (ease * if ambient { 1.4 } else { 1.0 })
        .clamp(f64::from(MIN_EASE_MS), f64::from(MAX_EASE_MS));
      (d, e)
    };

    // The two cases that crossed under the reference's 3000, now closed.
    for (dwell, ease, ambient, speed) in
      [(10_000.0, 2_800.0, false, 10.0), (0.0, 1_800.0, true, 0.25), (20_000.0, 2_600.0, false, 16.0)]
    {
      let (d, e) = runtime(dwell, ease, ambient, speed);
      assert!(e < d, "authored {dwell}/{ease} ambient={ambient} speed={speed} -> {d}/{e}");
    }

    // Control: the reel being ported is unmoved by the cap, at any speed.
    for speed in [1.0, 99.0] {
      let (d, e) = runtime(6_000.0, 900.0, false, speed);
      assert_eq!(e, 900.0, "45h's ease is untouched by the cap");
      assert!(e < d);
    }
  }

  /// The reel this port is graded against, so the parity question is answered
  /// by a test rather than by remembering an answer somebody sent.
  ///
  /// snorkeltoast measured the 45h config 2026-09-09: max ease 900ms against min
  /// dwell 5000ms, nothing above `max_ease`, nothing at ease >= dwell. Both PACE
  /// presets and the reel's own longest and shortest segments are here, so the
  /// claim "this config does not diverge" is checked rather than cited.
  #[test]
  fn the_forty_five_h_reel_passes_the_envelope_unchanged() {
    let cases: &[(&str, u32, u32)] = &[
      ("PACE attract", 6_000, 900),
      ("PACE ambient", 11_000, 1_600),
      ("logo", 5_000, 900),
      ("opening crawl", 21_000, 900),
      ("outro crawl", 16_000, 900),
      ("faq", 9_000, 900),
    ];
    assert_eq!(cases.len(), 6);
    for (name, dwell, ease) in cases {
      let t = timing(name, *dwell, *ease).expect("the 45h reel must not refuse");
      assert_eq!(t.dwell_ms, *dwell, "{name}: dwell must pass through untouched");
      assert_eq!(t.ease_ms, *ease, "{name}: ease must pass through untouched");
    }
  }
}
