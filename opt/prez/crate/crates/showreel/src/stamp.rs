//! What the build says about itself, in the shape `showreel-harness` reads.
//!
//! **THE HARNESS ASKED FOR THIS AND NEITHER IMPLEMENTATION WAS WRITING IT.**
//! `STAMP_RE` searches an artifact for
//! `<meta name="showreel-producer" content="...">`, and `population_source`
//! becomes `"stamp"` when it is found and `"adjacency (UNVERIFIED)"` when it is
//! not -- so without a stamp the harness infers the producer from whichever
//! compiler happened to sit beside it at capture time. AC-2.1 leg 2 refuses that
//! inference, and this module is what replaces it. design.md 4.5 rules it.
//!
//! **`config::Reel::producer` IS A DIFFERENT THING WEARING THE SAME WORD, AND
//! THAT COLLISION IS WHY THIS FIELD LOOKED HANDLED.** That field is the REEL'S
//! CREDIT LINE -- who made the show -- rendered by the player as
//! `add("Producer", REEL.producer)`. This is the BUILD's identity: which
//! compiler, at which version, under which pixel policy. The reference carries
//! the identical collision at `showreel:1006`, so a grep for `producer` finds
//! the credit line and reads as covered.
//!
//! **EVERY MEASURABLE FIELD INTERPOLATES FROM A LIVE CONSTANT AND NONE IS TYPED
//! OUT.** A hard-coded `q=86` is **a flag wearing a stamp's clothes**: it
//! records what somebody intended when they typed it, not what the code does --
//! `showreel-harness:218`'s own flag-versus-stamp distinction one level deeper.
//! It is also why the stamp carries VALUES rather than a versioned policy id: an
//! id lets two halves agree on `pixpol-3` and disagree on pixels.
//!
//! **`stage` AND `alpha` ARE LITERAL AND CORRECTLY SO.** They measure nothing
//! this build reads; they name which half wrote the stamp and which policy that
//! half applies, and that is a constant fact about the writer. snorkeltoast's
//! side stamps `alpha=mode-only`, so the divergence ruled in design.md 4.2
//! surfaces as two distinct strings rather than as something to remember.
//!
//! **NOTHING CALLS THIS YET, DELIBERATELY AND ON THE RECORD.** There is no build
//! verb, so `producer` has no production caller -- machinery nothing calls, of
//! exactly the kind this contract has mis-graded before. It is cited by AC-2.1
//! leg 2, which is OPEN, and it must stay that way: leg 2 discharges when an
//! artifact carries a filled stamp, not when this function exists.

use crate::{config, normalise};

/// The producer stamp for a build of `cfg`.
///
/// The shape is snorkeltoast's, because the instrument that reads it is theirs:
/// `impl=<name>/<version>;stage=build;embed=<edge>;filter=<kernel>;q=<quality>;alpha=<policy>`.
///
/// **`embed` IS THE REEL'S TARGET AND NOT THE DEFAULT**, which is why this takes
/// the whole config rather than a `u32`: a caller holding a number can pass the
/// constant by mistake, and a caller holding the config cannot.
pub fn producer(cfg: &config::Reel) -> String {
  format!(
    "impl={}/{};stage=build;embed={};filter={};q={};alpha=collapse",
    env!("CARGO_PKG_NAME"),
    env!("CARGO_PKG_VERSION"),
    cfg.embed_target(),
    normalise::filter_name(),
    normalise::JPEG_Q,
  )
}

#[cfg(test)]
mod tests {
  use super::*;

  fn cfg(yaml: &str) -> config::Reel {
    config::parse(yaml, "stamp-test").unwrap()
  }

  fn plain() -> config::Reel {
    cfg("artist: {handle: x}\n")
  }

  #[test]
  fn the_stamp_carries_every_field_the_harness_asks_for() {
    let s = producer(&plain());
    for key in ["impl=", "stage=build", "embed=", "filter=", "q=", "alpha="] {
      assert!(s.contains(key), "missing {key} in {s}");
    }
  }

  /// **THE RED-PROOF'S TARGET, AND THE WHOLE POINT OF THE RULE.** This asserts
  /// the LITERAL, so changing `JPEG_Q` must break it. A stamp that typed its own
  /// `86` would keep this test green while the encoder moved -- which is the
  /// flag-wearing-a-stamp's-clothes failure, passing.
  #[test]
  fn the_quality_is_the_encoders_own_and_not_a_number_typed_beside_it() {
    assert!(producer(&plain()).contains("q=86"), "{}", producer(&plain()));
  }

  /// The same property one field along: the kernel the resize actually runs.
  #[test]
  fn the_filter_is_the_one_the_resize_actually_runs() {
    assert!(producer(&plain()).contains("filter=lanczos3"), "{}", producer(&plain()));
  }

  /// **THE DISCRIMINATION NO REEL IN THIS ESTATE CAN MAKE.** 45h and the pinned
  /// fixture BOTH set `target: 1920`, which is exactly `normalise::TARGET`, so a
  /// build reading the constant instead of the config is byte-identical on both
  /// members of the config population. This is the unit test that separates
  /// them -- and it is a claim about the RESOLVER, not about a build, which has
  /// no embed site yet.
  #[test]
  fn the_stamp_reports_the_reels_own_target_and_not_the_default() {
    assert!(producer(&cfg("artist: {handle: x}\ntarget: 1440\n")).contains("embed=1440"));
    assert!(producer(&cfg("artist: {handle: x}\ntarget: 2560\n")).contains("embed=2560"));
    // **AND THE SILENT REEL FALLS BACK TO THE CONSTANT -- ASSERTED AS A LITERAL,
    // BECAUSE THE OBVIOUS FORM IS VACUOUS.** This line read
    // `contains(&format!("embed={}", normalise::TARGET))` until the red-proof
    // moved `TARGET` to 1600 and the test stayed GREEN: both sides read the same
    // constant, so it agreed with itself by construction and proved nothing. It
    // was the one assertion in this module that could not fail, inside the test
    // written to stop exactly that.
    assert!(producer(&plain()).contains("embed=1920"), "{}", producer(&plain()));
  }

  /// **THE COLLISION, ASSERTED RATHER THAN LEFT TO THE DOC COMMENT.** A reel's
  /// `producer:` is its credit line and must never reach the build's stamp --
  /// the same word one file apart, which is what made this field look handled.
  #[test]
  fn the_builds_identity_is_not_the_reels_credit_line() {
    let c = cfg("artist: {handle: x}\nproducer: Snorkeltoast\n");
    assert_eq!(c.producer, "Snorkeltoast", "the credit line parsed, so this is not a vacuous check");
    assert!(!producer(&c).contains("Snorkeltoast"), "{}", producer(&c));
  }

  /// The stamp has to survive `template::render`'s two refusals or it could
  /// never ship. Both are cheap to assert here and neither is implied.
  #[test]
  fn the_stamp_is_something_render_will_accept() {
    let s = producer(&plain());
    assert!(!s.is_empty(), "an empty stamp grades as an absent one");
    assert!(!s.contains('"'), "a quote would close content=\"...\" early: {s}");
  }
}
