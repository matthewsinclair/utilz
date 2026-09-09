//! The photosensitivity envelope, applied HERE as well as in the player.

use artifact::Failure;

/// **NOT CONFIGURABLE, AND THAT IS THE POINT.** A reel that runs eight hours a
/// day two metres from someone working a till is a workplace, not a demo.
/// Values are the reference's, `showreel:65`, unchanged.
pub const MIN_DWELL_MS: u32 = 2_500;
pub const MIN_EASE_MS: u32 = 600;
pub const MAX_EASE_MS: u32 = 3_000;

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
/// CONSTANTS WERE MEASURED, AND IT IS ALSO AN UNLUCKY PAIR OF CONSTANTS.**
/// `MAX_EASE_MS` 3000 exceeds `MIN_DWELL_MS` 2500, so the highest ease the
/// runtime permits is longer than the shortest dwell it permits. That is a
/// SECOND and independent defect, closing this module cannot fix it, and it has
/// its own pinned test below. The emphatic half of the original sentence was
/// the wrong half.
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
/// dwell is at least 2500 and effective ease is at most 3000, so an authored
/// pair that is sound can never clamp into an unsound one -- proved by cases in
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
  // refusal -- with the injection proved applied before the result was read:
  // exactly `max_ease_is_applied_by_the_compiler_and_not_only_by_the_player`
  // and `an_ease_that_meets_or_exceeds_its_dwell_is_refused_by_name` went red,
  // and the remaining five stayed green.
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

  /// **THIS PINS A HOLE THE COMPILER CANNOT CLOSE ALONE, AND ITS NAME SAYS SO.**
  ///
  /// AC-3.6 requires the floors to hold in compiler AND runtime with `?speed=`
  /// unable to cross them. **They do not and it can, and the cause is the
  /// CONSTANTS rather than their enforcement.** The player's `dwellOf` divides
  /// by `SPEED` and its `easeOf` does not, and `SPEED` is a `parseFloat`
  /// straight off the query string with no clamp -- so a large enough `?speed=`
  /// floors dwell at `MIN_DWELL_MS` while ease sits anywhere up to
  /// `MAX_EASE_MS`, which is larger.
  ///
  /// Measured against the player's own formulas: `dwell: 10s, ease: 2.8s`
  /// passes this module, and at `?speed=10` the runtime computes dwell 2500 and
  /// ease 2800. Three of six sampled cases cross.
  ///
  /// **NO AMOUNT OF COMPILE-TIME ENFORCEMENT FIXES IT.** Every available fix is
  /// a decision: refuse an authored ease at or above `MIN_DWELL_MS`, which
  /// refuses configs that build today; clamp `SPEED` in the player; or scale
  /// ease by `SPEED` as dwell is scaled, which changes what a reel looks like.
  /// **Filed rather than chosen** -- AC-3.6 is vc's row.
  ///
  /// **THIS TEST MUST GO RED WHEN IT IS RULED, AND THAT REDNESS IS THE POINT.**
  /// Invert it into a guarantee; do not delete it.
  #[test]
  #[expect(
    clippy::assertions_on_constants,
    reason = "the constants ARE the subject: MAX_EASE_MS exceeding MIN_DWELL_MS is the \
              defect being pinned, so the assertion is deliberately compile-time-decidable. \
              `expect` rather than `allow` so that restructuring which makes this no longer \
              constant is itself reported."
  )]
  fn speed_can_still_cross_the_envelope_at_runtime_which_is_a_known_hole() {
    assert!(
      MAX_EASE_MS > MIN_DWELL_MS,
      "EXPECTED RED IF THE ENVELOPE WAS JUST MADE CONSISTENT -- do not chase this \
       as a regression. It RECORDS that the highest permitted ease exceeds the \
       lowest permitted dwell. If that no longer holds, INVERT this test."
    );

    // The player's own arithmetic, transcribed from its `dwellOf` and `easeOf`.
    let runtime = |dwell: f64, ease: f64, speed: f64| {
      let d = (dwell / speed).max(f64::from(MIN_DWELL_MS));
      let e = ease.clamp(f64::from(MIN_EASE_MS), f64::from(MAX_EASE_MS));
      (d, e)
    };

    timing("legal", 10_000, 2_800).expect("the compiler accepts this config");
    let (d, e) = runtime(10_000.0, 2_800.0, 10.0);
    assert!(
      e >= d,
      "EXPECTED RED IF ?speed= WAS BOUNDED -- records that a compile-legal config \
       still crosses at runtime: dwell {d}, ease {e}"
    );

    // Control: the reel being ported is NOT exposed, its ease being 900ms.
    // Without this the test would read as "every reel is broken".
    let (d, e) = runtime(6_000.0, 900.0, 99.0);
    assert!(e < d, "the 45h reel survives any speed: dwell {d}, ease {e}");
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
