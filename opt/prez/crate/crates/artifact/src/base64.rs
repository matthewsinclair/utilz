// Base64, hand-rolled -- because the crate it lives in takes no dependencies.
//
// **THE HAND-ROLLING IS THE POINT, NOT AN ACCIDENT OF HISTORY.** AC02 holds prez
// to comrak and nothing else, so this was written against std rather than
// pulled in. That ruling is what made it cheap to share: a base64 crate here
// would have to be agreed by every consumer of this crate, and forty lines
// against std need no one's agreement at all.
//
// **BOTH HALVES, AND THE DECODER WAITED FOR A READER.** prez and showreel turn
// bytes into `data:` URIs with `encode`. showreel's `video` reads bytes back
// with `decode`, because the DevTools protocol sends every screenshot as base64
// (ST0021). Until `video` there was nothing to decode, and a decoder would have
// been dead code carrying tests that proved nothing about any artifact.

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
    out.push(if chunk.len() > 1 {
      ALPHABET[(triple >> 6 & 0x3f) as usize] as char
    } else {
      '='
    });
    out.push(if chunk.len() > 2 {
      ALPHABET[(triple & 0x3f) as usize] as char
    } else {
      '='
    });
  }
  out
}

/// Why a text is not base64, and where.
#[derive(Debug, PartialEq, Eq)]
pub enum DecodeError {
  /// The length, which is not a whole number of four-character groups.
  Length(usize),
  /// Padding before the last group, or more than two `=`, in the group that
  /// starts at this character.
  Padding(usize),
  /// A character outside the alphabet, and where it is.
  Character { byte: u8, at: usize },
}

impl std::fmt::Display for DecodeError {
  fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
    match self {
      Self::Length(n) => write!(
        f,
        "{n} characters is not a whole number of four-character groups"
      ),
      Self::Padding(at) => write!(f, "padding before the end, at character {at}"),
      Self::Character { byte, at } => {
        write!(
          f,
          "'{}' at character {at} is not base64",
          byte.escape_ascii()
        )
      }
    }
  }
}

impl std::error::Error for DecodeError {}

/// Standard base64 with `=` padding back to bytes.
///
/// **STRICT, BECAUSE EVERY INPUT IS MACHINE-WRITTEN.** Whitespace, a character
/// outside the alphabet, a length that is not a whole number of quads, and
/// padding anywhere but the end are each refused with where they are, never
/// skipped: skipping would turn a truncated screenshot into a shorter image
/// that decodes.
pub fn decode(text: &str) -> Result<Vec<u8>, DecodeError> {
  let bytes = text.as_bytes();
  if !bytes.len().is_multiple_of(4) {
    return Err(DecodeError::Length(bytes.len()));
  }
  let quads = bytes.len() / 4;
  let mut out = Vec::with_capacity(quads * 3);
  for (q, quad) in bytes.chunks(4).enumerate() {
    let pad = quad.iter().rev().take_while(|&&c| c == b'=').count();
    if pad > 2 || (pad > 0 && q + 1 < quads) {
      return Err(DecodeError::Padding(q * 4));
    }
    let mut triple = 0u32;
    for (k, &c) in quad[..4 - pad].iter().enumerate() {
      let value = sextet(c).ok_or(DecodeError::Character {
        byte: c,
        at: q * 4 + k,
      })?;
      triple |= u32::from(value) << (18 - 6 * k);
    }
    out.push((triple >> 16) as u8);
    if pad < 2 {
      out.push((triple >> 8 & 0xff) as u8);
    }
    if pad < 1 {
      out.push((triple & 0xff) as u8);
    }
  }
  Ok(out)
}

fn sextet(c: u8) -> Option<u8> {
  match c {
    b'A'..=b'Z' => Some(c - b'A'),
    b'a'..=b'z' => Some(c - b'a' + 26),
    b'0'..=b'9' => Some(c - b'0' + 52),
    b'+' => Some(62),
    b'/' => Some(63),
    _ => None,
  }
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
    assert_eq!(
      encode(&[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
      "iVBORw0KGgo="
    );
  }

  #[test]
  fn decode_reads_the_rfc_4648_vectors_back() {
    for (text, bytes) in [
      ("", &b""[..]),
      ("Zg==", b"f"),
      ("Zm8=", b"fo"),
      ("Zm9v", b"foo"),
      ("Zm9vYg==", b"foob"),
      ("Zm9vYmE=", b"fooba"),
      ("Zm9vYmFy", b"foobar"),
      (
        "iVBORw0KGgo=",
        &[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a],
      ),
    ] {
      assert_eq!(decode(text).unwrap(), bytes, "{text}");
    }
  }

  #[test]
  fn decode_undoes_encode_for_every_length_and_every_byte() {
    for len in 0..300usize {
      let bytes: Vec<u8> = (0..len).map(|i| (i * 7 + len) as u8).collect();
      assert_eq!(decode(&encode(&bytes)).unwrap(), bytes, "length {len}");
    }
  }

  #[test]
  fn decode_refuses_what_it_cannot_read_and_says_where() {
    assert_eq!(decode("Zm9"), Err(DecodeError::Length(3)));
    assert_eq!(decode("Zm9v\nYmFy"), Err(DecodeError::Length(9)));
    assert_eq!(
      decode("Zm9vYm F"),
      Err(DecodeError::Character { byte: b' ', at: 6 })
    );
    assert_eq!(decode("Zg==Zm9v"), Err(DecodeError::Padding(0)));
    assert_eq!(decode("Z==="), Err(DecodeError::Padding(0)));
    let said = decode("Zm9vYm F").unwrap_err().to_string();
    assert_eq!(said, "' ' at character 6 is not base64");
  }

  #[test]
  fn every_output_length_is_a_multiple_of_four() {
    for len in 0..40usize {
      let bytes = vec![0xa5u8; len];
      assert_eq!(
        encode(&bytes).len() % 4,
        0,
        "length {len} produced ragged output"
      );
    }
  }
}
