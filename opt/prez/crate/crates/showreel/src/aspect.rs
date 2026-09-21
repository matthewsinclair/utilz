//! A video's aspect ratio, and the size and scale it records at (ST0022).
//!
//! **ONE PARSE FOR THE FLAG AND THE KEY.** `--aspect` and `aspect:` in
//! `showreel.yaml` both come through `Aspect::parse`, so the two cannot accept
//! different spellings. The names are hv's (2026-09-21, vc's decision 13), and
//! `W:H` is always accepted beside them.
//!
//! **THE TARGET IS THE LONG EDGE, AND THE SHORT EDGE FOLLOWS.** Both are made
//! even, as H.264's 4:2:0 chroma needs. That is the arithmetic `video` used for
//! 16:9 alone, so widescreen records exactly the size it always did.

use artifact::Failure;
use serde::Deserialize;

/// The names hv ruled, with the ratio each stands for.
pub const NAMES: &[(&str, Aspect)] = &[
  ("widescreen", Aspect::WIDESCREEN),
  ("portrait", Aspect { w: 9, h: 16 }),
  ("square", Aspect { w: 1, h: 1 }),
  ("feed", Aspect { w: 4, h: 5 }),
];

/// How far a ratio may lean either way: 1:4 to 4:1. The player was never laid
/// out for a strip narrower than that, and its short edge would be too small
/// to read.
pub const LEAN_MAX: u32 = 4;

/// A ratio of width to height, as given: 16:9 stays 16:9, not reduced.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Deserialize)]
#[serde(try_from = "String")]
pub struct Aspect {
  pub w: u32,
  pub h: u32,
}

impl Default for Aspect {
  fn default() -> Self {
    Self::WIDESCREEN
  }
}

impl TryFrom<String> for Aspect {
  type Error = String;

  /// serde's route in, for `aspect:`: the same parse, with the refusal's
  /// remedy folded into the message serde carries.
  fn try_from(value: String) -> Result<Self, Self::Error> {
    Self::parse(&value).map_err(|f| match f.remedy {
      Some(remedy) => format!("{}; {remedy}", f.message),
      None => f.message,
    })
  }
}

impl Aspect {
  pub const WIDESCREEN: Self = Self { w: 16, h: 9 };

  /// A name, in any case, or `W:H` of two positive whole numbers no more than
  /// 4:1 either way. Anything else is refused, naming it.
  pub fn parse(value: &str) -> Result<Self, Failure> {
    let v = value.trim();
    if let Some((_, a)) = NAMES.iter().find(|(n, _)| n.eq_ignore_ascii_case(v)) {
      return Ok(*a);
    }
    let side = |s: &str| s.trim().parse::<u32>().ok().filter(|n| *n > 0);
    let aspect = v
      .split_once(':')
      .and_then(|(w, h)| {
        Some(Self {
          w: side(w)?,
          h: side(h)?,
        })
      })
      .ok_or_else(|| {
        Failure::new(
          format!("aspect '{value}' is neither W:H nor a name"),
          format!(
            "give two positive whole numbers, eg --aspect 9:16, or one of {}",
            Self::named()
          ),
        )
      })?;
    let (long, short) = (aspect.w.max(aspect.h), aspect.w.min(aspect.h));
    if u64::from(long) > u64::from(short) * u64::from(LEAN_MAX) {
      return Err(Failure::new(
        format!("aspect '{value}' is narrower than 1:{LEAN_MAX} or wider than {LEAN_MAX}:1"),
        format!("eg --aspect 9:16, or one of {}", Self::named()),
      ));
    }
    Ok(aspect)
  }

  /// The frame, in pixels: `target` as the long edge, the short edge floored
  /// from the ratio, both even.
  pub fn size(self, target: u32) -> (u32, u32) {
    let long = target & !1;
    let short =
      |num: u32, den: u32| ((u64::from(long) * u64::from(num) / u64::from(den)) as u32) & !1;
    if self.w >= self.h {
      (long, short(self.h, self.w))
    } else {
      (short(self.w, self.h), long)
    }
  }

  /// The device scale the frame is recorded at. **A frame no wider than it is
  /// tall is recorded at 2, over a CSS viewport half its size**, so the
  /// player's handset rules (`max-width:820px`) apply to a video that will be
  /// watched on a phone. Widescreen stays at 1, so it records as it always did
  /// (design D5a).
  pub fn scale(self) -> u32 {
    if self.w <= self.h {
      2
    } else {
      1
    }
  }

  fn named() -> String {
    NAMES
      .iter()
      .map(|(n, a)| format!("{n} ({}:{})", a.w, a.h))
      .collect::<Vec<_>>()
      .join(", ")
  }
}

/// AT02 (ST0022 AC-01.2): the parse, its refusals and the size rule.
#[cfg(test)]
mod tests {
  use super::*;

  fn a(w: u32, h: u32) -> Aspect {
    Aspect { w, h }
  }

  #[test]
  fn the_four_names_are_hvs_ratios_in_any_case() {
    assert_eq!(Aspect::parse("widescreen").unwrap(), a(16, 9));
    assert_eq!(Aspect::parse("Portrait").unwrap(), a(9, 16));
    assert_eq!(Aspect::parse("SQUARE").unwrap(), a(1, 1));
    assert_eq!(Aspect::parse("feed").unwrap(), a(4, 5));
  }

  #[test]
  fn w_h_is_taken_either_way_round_and_as_given() {
    assert_eq!(Aspect::parse("16:9").unwrap(), a(16, 9));
    assert_eq!(Aspect::parse("9:16").unwrap(), a(9, 16));
    assert_eq!(Aspect::parse(" 32:18 ").unwrap(), a(32, 18));
    assert_eq!(Aspect::parse("4:1").unwrap(), a(4, 1));
    assert_eq!(Aspect::parse("1:4").unwrap(), a(1, 4));
  }

  #[test]
  fn the_default_is_widescreen() {
    assert_eq!(Aspect::default(), a(16, 9));
  }

  #[test]
  fn a_malformed_or_zero_ratio_is_refused_by_name() {
    for bad in [
      "", "16", "16:", ":9", "0:9", "16:0", "16x9", "1.5:1", "-16:9", "16:9:1", "cinema", "a:b",
    ] {
      let e = Aspect::parse(bad).unwrap_err();
      assert!(
        e.message.contains(&format!("'{bad}'")),
        "names '{bad}': {}",
        e.message
      );
      let remedy = e.remedy.unwrap();
      assert!(
        remedy.contains("9:16") && remedy.contains("portrait"),
        "{remedy}"
      );
    }
  }

  #[test]
  fn a_ratio_past_four_to_one_either_way_is_refused() {
    for bad in ["5:1", "1:5", "17:4"] {
      let e = Aspect::parse(bad).unwrap_err();
      assert!(e.message.contains("1:4"), "{}", e.message);
    }
  }

  #[test]
  fn the_size_table_holds_at_both_targets() {
    let table = [
      (a(16, 9), (1920, 1080), (2560, 1440)),
      (a(9, 16), (1080, 1920), (1440, 2560)),
      (a(1, 1), (1920, 1920), (2560, 2560)),
      (a(4, 5), (1536, 1920), (2048, 2560)),
    ];
    for (aspect, at1920, at2560) in table {
      assert_eq!(aspect.size(1920), at1920, "{aspect:?} at 1920");
      assert_eq!(aspect.size(2560), at2560, "{aspect:?} at 2560");
    }
  }

  #[test]
  fn both_edges_are_even_whatever_the_target_or_ratio() {
    for target in [640, 641, 1001, 1920] {
      for aspect in [a(16, 9), a(9, 16), a(4, 3), a(7, 5), a(1, 4)] {
        let (w, h) = aspect.size(target);
        assert!(w % 2 == 0 && h % 2 == 0, "{aspect:?} at {target}: {w}x{h}");
      }
    }
  }

  #[test]
  fn widescreen_sizes_as_the_sixteen_nine_rule_did() {
    // The rule `video` used before ST0022, restated here as the fixed point.
    let sixteen_nine = |t: u32| {
      let w = t & !1;
      (w, (w * 9 / 16) & !1)
    };
    for target in [256, 640, 641, 1280, 1919, 1920, 2560, 3841] {
      assert_eq!(
        Aspect::WIDESCREEN.size(target),
        sixteen_nine(target),
        "{target}"
      );
    }
  }

  #[test]
  fn a_frame_no_wider_than_tall_records_at_scale_two_and_widescreen_at_one() {
    assert_eq!(Aspect::WIDESCREEN.scale(), 1);
    assert_eq!(a(4, 3).scale(), 1);
    assert_eq!(a(9, 16).scale(), 2);
    assert_eq!(a(1, 1).scale(), 2);
    assert_eq!(a(4, 5).scale(), 2);
  }

  #[test]
  fn a_yaml_value_is_parsed_by_the_same_rule() {
    assert_eq!(Aspect::try_from("portrait".to_string()).unwrap(), a(9, 16));
    let e = Aspect::try_from("0:1".to_string()).unwrap_err();
    assert!(e.contains("'0:1'") && e.contains("portrait"), "{e}");
  }
}
