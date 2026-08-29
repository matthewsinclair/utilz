// Slide splitting: a line that is exactly `---` ends a slide.
//
// **THE WHOLE DIFFICULTY IS FENCES.** A deck about code very often contains a
// fenced block that itself contains `---` -- a YAML sample, a diff, a shell
// heredoc, another deck's front matter. Splitting on it would tear one slide
// into two mid-fence and produce an artifact with an unclosed <pre>. So this
// walks the source through `fence::Scanner` and only treats `---` as a
// separator at depth zero. The committed demo deck carries exactly this case so
// the behaviour is proven by the example, not only by the unit tests (spec 8).
//
// The fence rule itself lives in `fence.rs` because the renderer needs the same
// answer for directive comments; see that module for why.

use crate::fence;

/// Split a deck body into slide sources.
///
/// Leading and trailing whitespace is trimmed per slide, and empty slides are
/// dropped -- a trailing `---` at the end of a file is punctuation, not a
/// request for a blank slide.
pub fn slides(body: &str) -> Vec<String> {
  let mut out = Vec::new();
  let mut current = String::new();
  let mut fence = fence::Scanner::default();

  for line in body.lines() {
    if fence.feed(line) && line.trim() == "---" {
      push_slide(&mut out, &mut current);
    } else {
      current.push_str(line);
      current.push('\n');
    }
  }
  push_slide(&mut out, &mut current);
  out
}

fn push_slide(out: &mut Vec<String>, current: &mut String) {
  let slide = current.trim();
  if !slide.is_empty() {
    out.push(slide.to_string());
  }
  current.clear();
}

#[cfg(test)]
mod tests {
  use super::*;

  #[test]
  fn splits_on_a_bare_rule() {
    let s = slides("# One\n\n---\n\n# Two\n");
    assert_eq!(s.len(), 2);
    assert_eq!(s[0], "# One");
    assert_eq!(s[1], "# Two");
  }

  #[test]
  fn a_rule_inside_a_backtick_fence_is_content() {
    let src = "# One\n\n```yaml\n---\ntitle: x\n---\n```\n\n---\n\n# Two\n";
    let s = slides(src);
    assert_eq!(s.len(), 2, "the fenced ---s must not split: {:?}", s);
    assert!(s[0].contains("title: x"));
    assert!(s[0].contains("```"));
  }

  #[test]
  fn a_rule_inside_a_tilde_fence_is_content() {
    let s = slides("# One\n\n~~~\n---\n~~~\n\n---\n\n# Two\n");
    assert_eq!(s.len(), 2);
  }

  #[test]
  fn a_longer_fence_wraps_a_shorter_one() {
    let src = "# One\n\n````\n```\n---\n```\n````\n\n---\n\n# Two\n";
    let s = slides(src);
    assert_eq!(s.len(), 2, "the inner fence must not close the outer: {:?}", s);
  }

  #[test]
  fn a_shorter_closer_does_not_close_a_longer_fence() {
    // ``` cannot close ````, so the --- after it is still fenced.
    let s = slides("````\n```\n---\n````\n");
    assert_eq!(s.len(), 1);
  }

  #[test]
  fn trailing_and_repeated_rules_make_no_empty_slides() {
    let s = slides("# One\n---\n---\n\n---\n");
    assert_eq!(s, vec!["# One"]);
  }

  #[test]
  fn a_rule_with_surrounding_space_still_splits() {
    let s = slides("# One\n  ---  \n# Two\n");
    assert_eq!(s.len(), 2);
  }

  #[test]
  fn a_longer_horizontal_rule_is_not_a_separator() {
    // Only exactly `---` separates; ---- stays content (markdown renders it as
    // a horizontal rule, which is what the author asked for).
    let s = slides("# One\n----\n# Two\n");
    assert_eq!(s.len(), 1);
  }

  #[test]
  fn an_unclosed_fence_keeps_its_content_on_the_last_slide() {
    let s = slides("# One\n\n---\n\n```\n---\nstill code\n");
    assert_eq!(s.len(), 2);
    assert!(s[1].contains("still code"));
  }
}
