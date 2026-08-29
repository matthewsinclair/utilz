// Base64, hand-rolled (AC02: comrak is the only dependency).
//
// Encoding only. prez turns bytes into `data:` URIs and never reads one back,
// so a decoder would be dead code with tests that prove nothing about the
// artifact.

const ALPHABET: &[u8; 64] = b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

/// Standard base64 with `=` padding -- the alphabet `data:` URIs use.
pub fn encode(bytes: &[u8]) -> String {
  let mut out = String::with_capacity(bytes.len().div_ceil(3) * 4);
  for chunk in bytes.chunks(3) {
    let b1 = u32::from(chunk[0]);
    let b2 = chunk.get(1).map_or(0, |b| u32::from(*b));
    let b3 = chunk.get(2).map_or(0, |b| u32::from(*b));
    let triple = (b1 << 16) | (b2 << 8) | b3;

    out.push(ALPHABET[(triple >> 18 & 0x3f) as usize] as char);
    out.push(ALPHABET[(triple >> 12 & 0x3f) as usize] as char);
    // The padding is positional: two leftover bytes pad one `=`, one pads two.
    out.push(if chunk.len() > 1 { ALPHABET[(triple >> 6 & 0x3f) as usize] as char } else { '=' });
    out.push(if chunk.len() > 2 { ALPHABET[(triple & 0x3f) as usize] as char } else { '=' });
  }
  out
}

#[cfg(test)]
mod tests {
  use super::*;

  #[test]
  fn matches_the_rfc_4648_vectors() {
    // The canonical set, which pins all three padding cases at once.
    assert_eq!(encode(b""), "");
    assert_eq!(encode(b"f"), "Zg==");
    assert_eq!(encode(b"fo"), "Zm8=");
    assert_eq!(encode(b"foo"), "Zm9v");
    assert_eq!(encode(b"foob"), "Zm9vYg==");
    assert_eq!(encode(b"fooba"), "Zm9vYmE=");
    assert_eq!(encode(b"foobar"), "Zm9vYmFy");
  }

  #[test]
  fn handles_bytes_that_are_not_text() {
    // A PNG header: high bytes are where a sloppy shift-and-mask goes wrong.
    assert_eq!(encode(&[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]), "iVBORw0KGgo=");
  }

  #[test]
  fn every_output_length_is_a_multiple_of_four() {
    for len in 0..40usize {
      let bytes = vec![0xa5u8; len];
      assert_eq!(encode(&bytes).len() % 4, 0, "length {len} produced ragged output");
    }
  }
}
