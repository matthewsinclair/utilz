// Local images become `data:` URIs, so the artifact opens offline (AC03).
//
// **THIS RUNS ON THE RENDERED HTML, NOT ON THE MARKDOWN**, and that is the whole
// reason it works. `![alt](logo.png)` and a hand-written `<img src="logo.png">`
// in an escape-hatch slide are the same thing by the time comrak is done, and a
// markdown-level pass would inline the first and leave the second pointing at a
// file that will not exist beside the artifact.
//
// What is deliberately NOT rewritten: anything with a scheme (`http:`, `https:`,
// `data:`, protocol-relative `//`). Spec 3 draws that line -- prez emits no
// external reference of its own, but a URL THE AUTHOR WRITES is their content
// and their business. Only `<img>` is touched for the same reason: a `<script
// src>` an author hand-wrote is theirs to own.

use crate::base64;
use std::path::Path;

/// Rewrite local `<img src=...>` references in `html` to `data:` URIs.
///
/// Paths resolve against `base`, the directory holding the deck. Returns the
/// rewritten HTML and one warning per image that could not be read.
pub fn images(html: &str, base: &Path) -> (String, Vec<String>) {
  let mut out = String::with_capacity(html.len());
  let mut warnings = Vec::new();
  let mut rest = html;

  while let Some(at) = rest.find("<img") {
    out.push_str(&rest[..at]);
    let tag_start = &rest[at..];
    // An unterminated tag is markup prez did not write and cannot repair;
    // copying it through verbatim leaves the author's own mistake visible.
    let Some(end) = tag_start.find('>') else {
      out.push_str(tag_start);
      return (out, warnings);
    };
    let (tag, after) = tag_start.split_at(end + 1);
    out.push_str(&rewrite_tag(tag, base, &mut warnings));
    rest = after;
  }
  out.push_str(rest);
  (out, warnings)
}

fn rewrite_tag(tag: &str, base: &Path, warnings: &mut Vec<String>) -> String {
  let Some((before, src, after)) = split_src(tag) else {
    return tag.to_string();
  };
  if has_scheme(src) {
    return tag.to_string();
  }
  let path = base.join(percent_decode(src));
  match data_uri(&path) {
    Ok(data) => format!("{before}{data}{after}"),
    Err(why) => {
      // Warn and leave the reference ALONE. Spec 3: never a silent drop -- the
      // browser then shows a broken image where the author put one, which is
      // the visible half of the report. The io error travels so the warning can
      // tell "no such file" from "permission denied".
      warnings.push(format!("image not read, left as a broken reference: {} ({why})", path.display()));
      tag.to_string()
    }
  }
}

/// Split a tag around the value of its `src` attribute.
///
/// Quoted values only. comrak always quotes, and an unquoted `src=a.png` in
/// hand-written HTML is rare enough that guessing where the value ends would
/// risk mangling a tag to save a rewrite.
fn split_src(tag: &str) -> Option<(&str, &str, &str)> {
  let at = find_src_attribute(tag)?;
  let after_eq = tag[at..].find('=')? + at + 1;
  let rest = &tag[after_eq..];
  let quote = rest.trim_start().chars().next()?;
  if quote != '"' && quote != '\'' {
    return None;
  }
  let open = after_eq + rest.find(quote)? + 1;
  let close = open + tag[open..].find(quote)?;
  Some((&tag[..open], &tag[open..close], &tag[close..]))
}

/// Offset of a `src` attribute name, not of the letters "src" inside a value.
///
/// This has to track quote state, because "preceded by a space and followed by
/// an equals" describes an attribute AND describes `<img alt="see src=x">`
/// exactly as well. Skipping quoted regions is the only thing that tells them
/// apart.
fn find_src_attribute(tag: &str) -> Option<usize> {
  let bytes = tag.as_bytes();
  let mut quote: Option<u8> = None;
  for i in 0..bytes.len() {
    match quote {
      Some(open) => {
        if bytes[i] == open {
          quote = None;
        }
      }
      None if bytes[i] == b'"' || bytes[i] == b'\'' => quote = Some(bytes[i]),
      // Outside a value, an attribute name begins after whitespace.
      None if bytes[i].is_ascii_whitespace() => {
        let name = &tag[i + 1..];
        let is_src = name.len() >= 3 && name.as_bytes()[..3].eq_ignore_ascii_case(b"src");
        if is_src && name[3..].trim_start().starts_with('=') {
          return Some(i + 1);
        }
      }
      None => {}
    }
  }
  None
}

fn has_scheme(src: &str) -> bool {
  let src = src.trim();
  if src.starts_with("//") {
    return true;
  }
  // A scheme is letters then a colon, before any slash -- which is what keeps
  // `images/a:b.png` (a colon in a path segment) from reading as one.
  match src.find(':') {
    Some(at) => {
      at > 0
        && !src[..at].contains('/')
        && src[..at].chars().all(|c| c.is_ascii_alphanumeric() || "+-.".contains(c))
    }
    None => false,
  }
}

fn data_uri(path: &Path) -> Result<String, std::io::Error> {
  Ok(format!("data:{};base64,{}", mime_for(path), base64::encode(&std::fs::read(path)?)))
}

/// Undo the percent-encoding comrak applies to link destinations.
///
/// Without this a file called `my logo.png` is written into the HTML as
/// `my%20logo.png` and then looked for on disk under that literal name.
fn percent_decode(src: &str) -> String {
  let bytes = src.as_bytes();
  let mut out = Vec::with_capacity(bytes.len());
  let mut i = 0;
  while i < bytes.len() {
    if bytes[i] == b'%' && i + 2 < bytes.len() {
      if let Some(byte) = hex_pair(bytes[i + 1], bytes[i + 2]) {
        out.push(byte);
        i += 3;
        continue;
      }
    }
    out.push(bytes[i]);
    i += 1;
  }
  String::from_utf8_lossy(&out).into_owned()
}

fn hex_pair(hi: u8, lo: u8) -> Option<u8> {
  let digit = |c: u8| (c as char).to_digit(16).map(|d| d as u8);
  Some(digit(hi)? << 4 | digit(lo)?)
}

/// MIME type by extension, covering the formats spec 3 names plus the ones a
/// deck realistically carries. An unknown extension gets the generic octet
/// stream: the bytes still travel, and the browser sniffs what it can.
fn mime_for(path: &Path) -> &'static str {
  let ext = path.extension().and_then(|e| e.to_str()).unwrap_or_default().to_ascii_lowercase();
  match ext.as_str() {
    "png" => "image/png",
    "jpg" | "jpeg" => "image/jpeg",
    "gif" => "image/gif",
    "svg" => "image/svg+xml",
    "webp" => "image/webp",
    "avif" => "image/avif",
    "bmp" => "image/bmp",
    "ico" => "image/x-icon",
    _ => "application/octet-stream",
  }
}

#[cfg(test)]
mod tests {
  use super::*;

  /// A deck directory holding one 1x1 GIF, for tests that need a real read.
  ///
  /// Named per test, because tests run in parallel threads and a shared fixture
  /// path means one thread truncating a file another is reading. That is not
  /// hypothetical: it made `a_local_image_becomes_a_data_uri` fail with an empty
  /// base64 payload as soon as unrelated tests changed the scheduling.
  fn fixture(test: &str) -> std::path::PathBuf {
    let dir = std::env::temp_dir().join(format!("prez-inline-{}-{test}", std::process::id()));
    std::fs::create_dir_all(&dir).unwrap();
    std::fs::write(dir.join("dot.gif"), b"GIF89a\x01\x00").unwrap();
    std::fs::write(dir.join("a space.png"), b"\x89PNG").unwrap();
    dir
  }

  #[test]
  fn a_local_image_becomes_a_data_uri() {
    let (out, warnings) = images("<p><img src=\"dot.gif\" alt=\"d\" /></p>", &fixture("a_local_image_becomes_a_data_uri"));
    assert!(out.contains("src=\"data:image/gif;base64,R0lGODlhAQA=\""), "{out}");
    assert!(out.contains("alt=\"d\""), "the rest of the tag survives: {out}");
    assert!(warnings.is_empty());
  }

  #[test]
  fn a_percent_encoded_name_is_resolved_before_the_read() {
    let (out, warnings) = images("<img src=\"a%20space.png\">", &fixture("a_percent_encoded_name_is_resolved_before_the_read"));
    assert!(out.contains("data:image/png;base64,"), "{out}");
    assert!(warnings.is_empty(), "{warnings:?}");
  }

  #[test]
  fn a_missing_image_warns_and_is_left_visibly_broken() {
    let (out, warnings) = images("<img src=\"gone.png\">", &fixture("a_missing_image_warns_and_is_left_visibly_broken"));
    assert_eq!(out, "<img src=\"gone.png\">", "never a silent drop");
    assert_eq!(warnings.len(), 1);
    assert!(warnings[0].contains("gone.png"), "the warning names the path: {warnings:?}");
  }

  #[test]
  fn remote_and_data_sources_are_left_alone() {
    // The author's URL is the author's business (spec 3).
    for src in ["https://example.com/a.png", "http://x/a.png", "//cdn/a.png", "data:image/gif;base64,AA"] {
      let tag = format!("<img src=\"{src}\">");
      let (out, warnings) = images(&tag, &fixture("remote_and_data_sources_are_left_alone"));
      assert_eq!(out, tag, "{src} should not be touched");
      assert!(warnings.is_empty(), "{src}: {warnings:?}");
    }
  }

  #[test]
  fn a_colon_in_a_path_segment_is_not_a_scheme() {
    assert!(!has_scheme("images/a:b.png"));
    assert!(has_scheme("https://x/y.png"));
  }

  #[test]
  fn src_inside_another_attribute_value_is_not_the_src_attribute() {
    let tag = "<img alt=\"see src=x\" src=\"dot.gif\">";
    let (out, _) = images(tag, &fixture("src_inside_another_attribute_value_is_not_the_src_attribute"));
    assert!(out.contains("alt=\"see src=x\""), "{out}");
    assert!(out.contains("data:image/gif"), "{out}");
  }

  #[test]
  fn non_image_tags_are_untouched() {
    let html = "<script src=\"local.js\"></script><link href=\"x.css\">";
    let (out, warnings) = images(html, &fixture("non_image_tags_are_untouched"));
    assert_eq!(out, html);
    assert!(warnings.is_empty());
  }

  #[test]
  fn several_images_in_one_document_are_all_rewritten() {
    let (out, _) = images("<img src=\"dot.gif\"> text <img src=\"dot.gif\">", &fixture("several_images_in_one_document_are_all_rewritten"));
    assert_eq!(out.matches("data:image/gif").count(), 2, "{out}");
    assert!(out.contains(" text "), "{out}");
  }
}
