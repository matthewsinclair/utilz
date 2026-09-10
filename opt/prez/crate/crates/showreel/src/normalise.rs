//! ONE normalisation policy, applied by both image passes.
//!
//! **THE REFERENCE HAS TWO PASSES AND ONLY ONE OF THEM COLLAPSES OPAQUE ALPHA,
//! WHICH IS THE DEFECT design.md 4.2 RULED AGAINST PORTING.** `normalise_image`
//! demotes a fully-opaque RGBA to RGB and writes JPEG; `data_uri` has no
//! equivalent and its PNG branch is the DEFAULT PATH FOR HAND-PLACED BRAND
//! MARKS -- so a fully-opaque RGBA ships full-size PNG on every build, where the
//! same picture through `init` would have been a JPEG.
//!
//! **THIS DOC NAMED THE MASCOT AND THE WORDMARK AS THE INSTANCE, AND MEASUREMENT
//! REFUTED IT.** Both brand PNGs on the live 45h reel are GENUINELY transparent,
//! so the collapse fires on neither, and no asset of that reel takes the
//! diverging path at all. design.md 4.2 carries the table. The ruling is
//! untouched -- one policy across both passes is right whether or not it costs
//! anything here -- but the port does not pay for it on the only reel anybody
//! runs, and the exemption list the harness wants is EMPTY for 45h. The arm is
//! covered by the three synthetic tests below and by nothing on that reel, which
//! are different facts.
//!
//! **"MATCH PYTHON EXACTLY" HERE MEANS PORTING A KNOWN DEFECT, ON THE PATH THAT
//! CARRIES THE BRAND MARKS, ON EVERY BUILD.** That is a fidelity requirement's
//! costume rather than a fidelity requirement, and the ruling pays the cost of
//! the blanket RMSE explicitly instead of absorbing it.
//!
//! So there is one function, and the passes differ only in the edge they target:
//! `MASTER` for source art becoming a stored master, and a delivery size scaled
//! by the picture's ROLE for a slide being inlined.

use artifact::Failure;
use std::io::Cursor;
use std::path::Path;

/// The long edge of a stored master.
pub const MASTER: u32 = 2560;

/// The long edge of an embedded slide, before its role scales it.
pub const TARGET: u32 = 1920;

/// JPEG quality, matching the reference so the encoders are comparable even
/// though their bytes are not.
pub const JPEG_Q: u8 = 86;

/// The resampling kernel, named ONCE so the resize and the build's producer
/// stamp cannot disagree about which one ran.
///
/// **IT IS A CONSTANT BECAUSE THE STAMP HAS TO INTERPOLATE IT, NOT RESTATE
/// IT.** It sat inline at the `resize_exact` call until the stamp needed to
/// report it, and a stamp carrying a hand-typed `filter=lanczos3` would be **a
/// flag wearing a stamp's clothes** -- recording what somebody intended when
/// they typed it rather than what the code does. That is
/// `showreel-harness:218`'s flag-versus-stamp distinction one level deeper, and
/// it is the whole reason the stamp carries VALUES rather than a versioned
/// policy id: an id lets two halves agree on `pixpol-3` and disagree on pixels.
pub const FILTER: image::imageops::FilterType = image::imageops::FilterType::Lanczos3;

/// `FILTER`'s name for the producer stamp, **derived from the value rather than
/// written beside it**, so the two cannot drift apart. Pinned by a test, which
/// is what makes leaning on `Debug` here safe: a variant rename fails to
/// compile, and a formatting change fails the assertion.
pub fn filter_name() -> String {
  format!("{FILTER:?}").to_lowercase()
}

/// How much of the panel a picture's role actually needs.
///
/// **A CORNER MARK AT FULL SLIDE SIZE IS THE SAME PICTURE AND FIVE TIMES THE
/// BYTES.** The reference's numbers, ported: nothing about them is derivable, so
/// changing one is a decision rather than a tidy-up.
pub fn role_edge(role: Role, target: u32) -> u32 {
  let scaled = match role {
    Role::Slide => target,
    Role::Mark => (f64::from(target) * 0.72).round() as u32,
    Role::Bug => (f64::from(target) * 0.2).round() as u32,
  };
  scaled.max(256)
}

/// What a picture is being embedded AS.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Role {
  /// Fills the panel.
  Slide,
  /// A wordmark inside a slide.
  Mark,
  /// The persistent corner mark.
  Bug,
}

/// A normalised picture, ready to store or to inline.
#[derive(Debug)]
pub struct Normalised {
  pub bytes: Vec<u8>,
  /// `image/jpeg` or `image/png`, decided by whether alpha SURVIVED the
  /// collapse -- never by the input's format.
  pub mime: &'static str,
  pub width: u32,
  pub height: u32,
  /// Whether the output kept an alpha channel. Carried rather than re-derived
  /// from `mime`, because a caller asking "is this transparent" should not have
  /// to know which encoder that implies.
  pub has_alpha: bool,
}

/// Read, orient, collapse opaque alpha, downsize, encode.
///
/// **THIS COMMENT CLAIMED THE ORDER WAS LOAD-BEARING AND THE RED-PROOF REFUTED
/// IT.** It argued that resampling an opaque alpha channel can leave values that
/// are no longer exactly 255, so a resize-first implementation would find a
/// picture that had quietly stopped being collapsible. **Measured by injecting
/// exactly that reordering: not one test moved.** A fully-opaque alpha channel
/// is CONSTANT, a Lanczos kernel sums to one, and a constant channel resamples
/// to itself -- so there is nothing for the resize to break. The same argument
/// disposes of the orientation half: a transpose commutes with a uniform scale,
/// so orienting after resizing lands on the same dimensions.
///
/// **THE ORDER IS KEPT FOR COST, WHICH IS A REAL REASON AND A SMALLER ONE.**
/// Collapsing first means the resize resamples three channels instead of four.
/// Stated as cost rather than correctness, because the correctness claim was
/// mine, was plausible, and was wrong -- and a comment asserting a property no
/// test can lose is the shape this thread keeps finding.
pub fn normalise(path: &Path, max_edge: u32) -> Result<Normalised, Failure> {
  let raw = std::fs::read(path).map_err(|e| {
    Failure::new(format!("cannot read {}: {e}", path.display()), "check the file is readable")
  })?;
  let decoded = image::load_from_memory(&raw).map_err(|e| {
    Failure::new(
      format!("cannot decode {}: {e}", path.display()),
      "the file's contents are not the image its extension claims",
    )
  })?;
  let oriented = orient(decoded, orientation(&raw));
  Ok(encode(collapse(oriented), max_edge))
}

/// A picture inlined at the size its role needs, with what the player needs to
/// lay it out.
#[derive(Debug)]
pub struct Embedded {
  /// `data:<mime>;base64,<payload>`, ready to be an `src` attribute.
  pub uri: String,
  pub width: u32,
  pub height: u32,
  /// The ENCODED byte count, BEFORE base64 -- what the picture costs rather than
  /// what the string costs, and the reference returns the same number. For
  /// reporting only: the size warning is computed from the finished file, so
  /// nothing budgets against this.
  pub encoded: usize,
}

/// Inline a picture at the size its role actually needs.
///
/// **THE ROLE IS THE WHOLE OF THIS FUNCTION.** `normalise` already decides
/// orientation, collapse, resampling and encoder; all that is left is which edge
/// to ask it for, and that is a property of what the picture is BEING -- a full
/// panel, a wordmark inside one, or the corner bug. A corner mark at slide size
/// is the same picture and five times the bytes.
///
/// **AND THE SPLIT IS WHY THE PORT COLLAPSES ON BOTH PASSES WITHOUT A SECOND
/// POLICY.** The reference's `data_uri` does its own resize and its own encoder
/// choice, which is how it came to disagree with `normalise_image`; here there is
/// one function that decides and one that says how big, so the two passes cannot
/// drift apart without somebody editing the shared one.
pub fn embed(path: &Path, target: u32, role: Role) -> Result<Embedded, Failure> {
  let n = normalise(path, role_edge(role, target))?;
  Ok(Embedded {
    uri: format!("data:{};base64,{}", n.mime, artifact::base64::encode(&n.bytes)),
    width: n.width,
    height: n.height,
    encoded: n.bytes.len(),
  })
}

/// Whether every alpha byte is fully opaque, and the demotion if so.
///
/// **THIS IS THE HALF `data_uri` DOES NOT HAVE**, and giving it to both passes is
/// the whole of AC-3.4.
fn collapse(img: image::DynamicImage) -> (image::DynamicImage, bool) {
  if !img.color().has_alpha() {
    return (img, false);
  }
  let rgba = img.to_rgba8();
  let opaque = rgba.pixels().all(|p| p.0[3] == 255);
  if opaque {
    (image::DynamicImage::ImageRgb8(image::DynamicImage::ImageRgba8(rgba).to_rgb8()), false)
  } else {
    (image::DynamicImage::ImageRgba8(rgba), true)
  }
}

/// Round the way PYTHON rounds, not the way Rust does.
///
/// **`f64::round()` IS THE WRONG FUNCTION HERE AND THE DIFFERENCE IS ONE PIXEL
/// ON AN EXACT HALF.** Python's `round()` is round-half-to-EVEN (banker's);
/// Rust's `f64::round()` is round-half-AWAY-from-zero. They agree on every input
/// except a value landing exactly on `.5`, which is why this survived every
/// synthetic fixture and every unit test in this crate.
///
/// **FOUND BY THE FIRST STRUCTURAL COMPARE AGAINST THE REFERENCE, ON ONE SLIDE
/// OF TWENTY-THREE.** `02-burning-city-45h.jpg` is 2560x1862; at target 1920 the
/// scale is exactly 0.75 and `1862 * 0.75 = 1396.5` with no floating-point slop
/// at all. The reference emitted 1396 and this port emitted 1397. **A test
/// written from a fixture we chose could not have found it** -- it needs an
/// image whose short edge times the scale lands dead on a half, and 2560x1862 at
/// 0.75 is the only one of fourteen assets on the live reel that does.
fn round_like_python(v: f64) -> u32 {
  v.round_ties_even().max(1.0) as u32
}

fn encode((img, has_alpha): (image::DynamicImage, bool), max_edge: u32) -> Normalised {
  let (w, h) = (img.width(), img.height());
  let img = if w.max(h) > max_edge {
    let s = f64::from(max_edge) / f64::from(w.max(h));
    let nw = round_like_python(f64::from(w) * s);
    let nh = round_like_python(f64::from(h) * s);
    img.resize_exact(nw, nh, FILTER)
  } else {
    img
  };

  let mut bytes = Vec::new();
  let mime = if has_alpha {
    img
      .write_to(&mut Cursor::new(&mut bytes), image::ImageFormat::Png)
      .expect("a PNG encode into memory cannot fail");
    "image/png"
  } else {
    let rgb = img.to_rgb8();
    image::codecs::jpeg::JpegEncoder::new_with_quality(&mut bytes, JPEG_Q)
      .encode_image(&rgb)
      .expect("a JPEG encode into memory cannot fail");
    "image/jpeg"
  };
  Normalised { bytes, mime, width: img.width(), height: img.height(), has_alpha }
}

/// The EXIF orientation tag, or 1 where there is none.
///
/// **ABSENT IS 1 AND UNREADABLE IS ALSO 1, DELIBERATELY.** A picture with no
/// EXIF is the common case and is not an error; a corrupt EXIF block is not a
/// reason to refuse a picture that decodes perfectly well. This is the one place
/// in the port where a swallowed failure is correct, and it is correct because
/// the fallback is the IDENTITY -- nothing is silently changed, only silently
/// not changed.
fn orientation(raw: &[u8]) -> u32 {
  let mut cursor = Cursor::new(raw);
  exif::Reader::new()
    .read_from_container(&mut cursor)
    .ok()
    .and_then(|e| {
      e.get_field(exif::Tag::Orientation, exif::In::PRIMARY)
        .and_then(|f| f.value.get_uint(0))
    })
    .unwrap_or(1)
}

/// Apply an EXIF orientation, all eight of them.
///
/// **ALL EIGHT, NOT THE THREE ANYONE MEETS.** The four transposed values are
/// rare and are produced by real cameras; handling six and silently ignoring two
/// would rotate most pictures correctly and mirror the rest, which is the shape
/// of bug nobody finds until it is in front of an audience.
fn orient(img: image::DynamicImage, orientation: u32) -> image::DynamicImage {
  use image::DynamicImage as D;
  match orientation {
    2 => img.fliph(),
    3 => img.rotate180(),
    4 => img.flipv(),
    5 => D::rotate90(&img.fliph()),
    6 => img.rotate90(),
    7 => D::rotate270(&img.fliph()),
    8 => img.rotate270(),
    _ => img,
  }
}

#[cfg(test)]
mod tests {
  use super::*;

  /// A PNG of one flat colour at a chosen alpha.
  fn png(w: u32, h: u32, alpha: u8) -> Vec<u8> {
    let mut img = image::RgbaImage::new(w, h);
    for (i, p) in img.pixels_mut().enumerate() {
      // Varied content so the encoders have something real to do; only the
      // alpha channel is held constant, which is what these tests are about.
      let v = u8::try_from(i % 251).unwrap_or(0);
      *p = image::Rgba([v, 20, 30, alpha]);
    }
    let mut out = Vec::new();
    image::DynamicImage::ImageRgba8(img)
      .write_to(&mut Cursor::new(&mut out), image::ImageFormat::Png)
      .unwrap();
    out
  }

  fn write(tag: &str, bytes: &[u8]) -> std::path::PathBuf {
    let d = std::env::temp_dir().join(format!("showreel-norm-{}", std::process::id()));
    std::fs::create_dir_all(&d).unwrap();
    let p = d.join(format!("{tag}.png"));
    std::fs::write(&p, bytes).unwrap();
    p
  }

  /// **THE RULING, AS ONE ASSERTION: A FULLY-OPAQUE RGBA BECOMES A JPEG.**
  ///
  /// This is the case the reference decides two different ways depending which
  /// pass reaches it -- JPEG through `normalise_image`, full-size PNG through
  /// `data_uri`, which is the path every hand-placed brand mark takes. **Both
  /// arms are asserted here because one policy means the EDGE is the only thing
  /// that differs between the passes.**
  #[test]
  fn a_fully_opaque_rgba_is_demoted_to_jpeg_at_both_edges() {
    let p = write("opaque", &png(64, 64, 255));
    for edge in [MASTER, TARGET] {
      let out = normalise(&p, edge).unwrap();
      assert_eq!(out.mime, "image/jpeg", "opaque alpha must not ship as PNG at edge {edge}");
      assert!(!out.has_alpha, "and the flag agrees with the encoder");
    }
  }

  /// The other direction, or the rule above is satisfied by "always JPEG".
  #[test]
  fn a_genuinely_transparent_image_keeps_its_alpha_and_its_encoder() {
    let p = write("transparent", &png(64, 64, 128));
    let out = normalise(&p, MASTER).unwrap();
    assert_eq!(out.mime, "image/png", "real transparency survives");
    assert!(out.has_alpha);
  }

  /// **A SINGLE NON-OPAQUE PIXEL IS ENOUGH, AND THAT IS THE POINT OF SCANNING
  /// RATHER THAN SAMPLING.** A wordmark is opaque everywhere except its
  /// antialiased edge, so a check that looked at a corner would demote it and
  /// throw the edge away.
  #[test]
  fn one_transparent_pixel_in_a_million_stops_the_demotion() {
    let mut img = image::RgbaImage::new(200, 200);
    for p in img.pixels_mut() {
      *p = image::Rgba([10, 20, 30, 255]);
    }
    img.put_pixel(199, 199, image::Rgba([10, 20, 30, 254]));
    let mut bytes = Vec::new();
    image::DynamicImage::ImageRgba8(img)
      .write_to(&mut Cursor::new(&mut bytes), image::ImageFormat::Png)
      .unwrap();
    let out = normalise(&write("onepixel", &bytes), MASTER).unwrap();
    assert_eq!(out.mime, "image/png", "254 is not 255");
    assert!(out.has_alpha);
  }

  /// A large fully-opaque RGBA must be downsized AND demoted, and the two must
  /// both happen rather than the resize costing the demotion.
  ///
  /// **WHAT THIS TEST DOES NOT PROVE, STATED BECAUSE I FIRST CLAIMED IT DID:**
  /// it does not discriminate the ORDER of the collapse and the resize.
  /// Injecting the reordering moved no test at all -- a fully-opaque alpha
  /// channel is constant, a Lanczos kernel sums to one, and a constant channel
  /// resamples to itself. The order is a cost choice, not a correctness one, and
  /// nothing here is a control over it.
  #[test]
  fn a_large_opaque_rgba_is_still_demoted_after_being_downsized() {
    let p = write("bigopaque", &png(3000, 1200, 255));
    let out = normalise(&p, MASTER).unwrap();
    assert_eq!(out.mime, "image/jpeg", "the collapse must precede the resize");
    assert_eq!(out.width, MASTER, "long edge hits the cap");
    assert_eq!(out.height, 1024, "and the short edge scales with it");
  }

  /// Under the cap, nothing is resampled -- resizing a small picture up would
  /// invent detail and cost bytes for it.
  /// **THE STAMP'S TEXT IS DERIVED, NOT RESTATED.** This pins the derivation so
  /// a change to the kernel cannot leave the stamp's name behind -- which is the
  /// exact failure the constant was hoisted to prevent.
  #[test]
  fn the_filter_names_itself_from_the_value_the_resize_actually_uses() {
    assert_eq!(filter_name(), "lanczos3");
  }

  #[test]
  fn an_image_under_the_edge_is_not_resized() {
    let p = write("small", &png(300, 200, 128));
    let out = normalise(&p, MASTER).unwrap();
    assert_eq!((out.width, out.height), (300, 200));
  }

  /// **ALL EIGHT ORIENTATIONS, NOT THE THREE ANYONE MEETS.** The four transposed
  /// values are rare and real; handling six would rotate most pictures correctly
  /// and mirror the rest, which is the shape of bug nobody finds until it is in
  /// front of an audience. The four that TRANSPOSE swap the dimensions, and that
  /// is what makes them observable without comparing pixels.
  #[test]
  fn every_exif_orientation_is_handled_and_the_transposing_four_swap_the_edges() {
    let img = image::DynamicImage::ImageRgba8(image::RgbaImage::new(40, 10));
    let swaps = [5u32, 6, 7, 8];
    let keeps = [1u32, 2, 3, 4];
    assert_eq!(swaps.len() + keeps.len(), 8, "the population IS the claim");

    for o in swaps {
      let out = orient(img.clone(), o);
      assert_eq!((out.width(), out.height()), (10, 40), "orientation {o} must transpose");
    }
    for o in keeps {
      let out = orient(img.clone(), o);
      assert_eq!((out.width(), out.height()), (40, 10), "orientation {o} must not transpose");
    }
    // An out-of-range value is the identity rather than a refusal: a corrupt tag
    // is not a reason to reject a picture that decoded perfectly well.
    assert_eq!((orient(img.clone(), 99).width(), orient(img, 99).height()), (40, 10));
  }

  /// A file with no EXIF at all is orientation 1, which is the common case and
  /// not an error.
  #[test]
  fn an_image_with_no_exif_is_upright() {
    assert_eq!(orientation(&png(8, 8, 255)), 1);
    assert_eq!(orientation(b"not an image at all"), 1, "and so is unreadable EXIF");
  }

  /// The role factors, ported rather than derived, with the floor that stops a
  /// bug becoming unreadable on a small target.
  #[test]
  fn each_role_gets_the_edge_the_reference_gives_it() {
    assert_eq!(role_edge(Role::Slide, 1920), 1920);
    assert_eq!(role_edge(Role::Mark, 1920), 1382);
    assert_eq!(role_edge(Role::Bug, 1920), 384);
    // The 256 floor bites only at small targets, and it is the reference's.
    assert_eq!(role_edge(Role::Bug, 640), 256, "128 would be unreadable");
  }

  /// A file that is not an image refuses by name rather than panicking. The
  /// admission layer should have caught it first; this is the second line.
  #[test]
  fn a_file_that_is_not_an_image_refuses_with_its_name() {
    let p = write("bogus", b"this is not a png");
    let e = normalise(&p, MASTER).unwrap_err();
    assert!(e.message.contains("cannot decode"), "{}", e.message);
    assert!(e.message.contains("bogus"), "names the file: {}", e.message);
  }

  /// Base64 back to bytes, WRITTEN HERE RATHER THAN BORROWED.
  ///
  /// **AN ENCODER CANNOT BE ITS OWN WITNESS.** Asserting the uri equals
  /// `format!("...{}", encode(bytes))` is the implementation restated, and it
  /// passes for a truncating encoder as happily as for a correct one. This runs
  /// the other direction over the standard alphabet, so a byte lost between
  /// `normalise` and the uri has somewhere to show up. It handles only what
  /// `encode` emits and panics on anything else, which is what a test wants.
  fn unbase64(s: &str) -> Vec<u8> {
    const A: &[u8; 64] = b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    let raw: Vec<u8> = s.bytes().filter(|b| *b != b'=').collect();
    let mut out = Vec::new();
    for chunk in raw.chunks(4) {
      let mut acc: u32 = 0;
      for (i, b) in chunk.iter().enumerate() {
        let v = A.iter().position(|a| a == b).expect("inside the base64 alphabet") as u32;
        acc |= v << (18 - 6 * i);
      }
      // 4 sextets carry 3 bytes, 3 carry 2, 2 carry 1 -- the padding is what
      // `encode` dropped and the filter above removed again.
      for i in 0..chunk.len() - 1 {
        out.push(((acc >> (16 - 8 * i)) & 0xff) as u8);
      }
    }
    out
  }

  /// The uri carries EXACTLY the bytes the policy produced, and says what they
  /// are. Decoded independently rather than compared against the encoder.
  #[test]
  fn an_embedded_picture_round_trips_to_the_bytes_normalise_produced() {
    let p = write("embed-opaque", &png(64, 64, 255));
    let e = embed(&p, TARGET, Role::Slide).unwrap();
    let head = "data:image/jpeg;base64,";
    assert!(e.uri.starts_with(head), "opaque alpha embeds as jpeg: {}", &e.uri[..40]);

    let direct = normalise(&p, role_edge(Role::Slide, TARGET)).unwrap();
    assert_eq!(unbase64(&e.uri[head.len()..]), direct.bytes, "the uri lost or changed bytes");
    assert_eq!(e.encoded, direct.bytes.len(), "and reports the encoded count, not the string's");
    assert_eq!((e.width, e.height), (direct.width, direct.height));
  }

  /// The mime in the uri follows the ENCODER, which follows the collapse -- so a
  /// genuinely transparent picture keeps both. This is the path both of 45h's
  /// brand marks actually take.
  #[test]
  fn a_genuinely_transparent_picture_embeds_as_png() {
    let p = write("embed-clear", &png(64, 64, 128));
    let e = embed(&p, TARGET, Role::Slide).unwrap();
    assert!(e.uri.starts_with("data:image/png;base64,"), "{}", &e.uri[..40]);
  }

  /// **THE ROLE HAS TO REACH THE EDGE, AND ONLY AN EMBED CAN SHOW THAT.**
  /// `each_role_gets_the_edge_the_reference_gives_it` proves `role_edge` computes
  /// the three numbers; it cannot notice `embed` ignoring the role it was passed.
  #[test]
  fn each_role_embeds_at_the_edge_its_role_asks_for() {
    let p = write("embed-roles", &png(3000, 3000, 255));
    let seen: Vec<u32> = [Role::Slide, Role::Mark, Role::Bug]
      .iter()
      .map(|r| embed(&p, TARGET, *r).unwrap().width)
      .collect();
    // A square resizes to exactly the edge, so the widths ARE role_edge's answers.
    assert_eq!(seen, vec![1920, 1382, 384], "the role must reach the resize");
  }

  /// A refusal propagates through `embed` with the file still named -- the
  /// wrapper must not turn a diagnosable failure into an anonymous one.
  #[test]
  fn a_missing_file_refuses_through_embed_and_still_names_itself() {
    let e = embed(Path::new("/nonesuch/absent-mark.png"), TARGET, Role::Bug).unwrap_err();
    assert!(e.message.contains("cannot read"), "{}", e.message);
    assert!(e.message.contains("absent-mark.png"), "names the file: {}", e.message);
  }
  /// **PYTHON ROUNDS HALF TO EVEN AND RUST ROUNDS HALF AWAY FROM ZERO, AND THE
  /// PORT HAS TO ROUND PYTHON's WAY.** 8x5 at a 4px edge scales by exactly 0.5,
  /// so the height is exactly 2.5 -- no floating-point slop, the one input class
  /// where the two rounding modes disagree.
  ///
  /// **THIS IS THE ONLY DEFECT THE FIRST STRUCTURAL COMPARE AGAINST THE
  /// REFERENCE FOUND, AND NO FIXTURE WE CHOSE COULD HAVE FOUND IT.** On the live
  /// reel it was `02-burning-city-45h.jpg`, 2560x1862 at target 1920: scale
  /// exactly 0.75, height exactly 1396.5, reference 1396 and this port 1397 --
  /// **one asset of fourteen, one slide of twenty-three.** Every synthetic
  /// fixture in this crate passed under both modes, because landing dead on a
  /// half is a property of the input and we had never written one.
  #[test]
  fn a_dimension_landing_exactly_on_a_half_rounds_the_way_python_rounds() {
    let d = std::env::temp_dir().join(format!("showreel-round-{}", std::process::id()));
    std::fs::create_dir_all(&d).unwrap();
    let p = d.join("half.png");
    let img = image::RgbImage::from_fn(8, 5, |x, _| image::Rgb([(x * 30) as u8, 1, 2]));
    image::DynamicImage::ImageRgb8(img).save(&p).unwrap();

    let n = normalise(&p, 4).unwrap();
    assert_eq!(n.width, 4, "the long edge is exact and cannot disagree");
    assert_eq!(
      n.height, 2,
      "5 * 0.5 = 2.5 exactly: Python's round() gives 2 (half-to-even), \
       Rust's f64::round() gives 3 (half-away-from-zero)"
    );

    // **AND A SECOND CASE, BECAUSE THE FIRST ONE ALONE CANNOT SEE TRUNCATION.**
    // The red-proof caught this: injecting a bare `as u32` left the test GREEN,
    // since 2.5 truncates to 2 and that is also the banker's answer. **A single
    // exact half separates the two ROUNDING MODES and says nothing about
    // whether rounding happens at all.** 9 * 0.3 = 2.7 separates the other axis:
    // every rounding mode gives 3, truncation gives 2.
    let q = d.join("point-seven.png");
    let img = image::RgbImage::from_fn(10, 9, |x, _| image::Rgb([(x * 20) as u8, 1, 2]));
    image::DynamicImage::ImageRgb8(img).save(&q).unwrap();
    let n = normalise(&q, 3).unwrap();
    assert_eq!(n.height, 3, "9 * 0.3 = 2.7 rounds to 3; truncation would give 2");
  }

}
