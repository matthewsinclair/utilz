// Speaker notes, removed from the WHOLE DECK before it is ever split.
//
// **THE DECK-LEVEL PASS IS THE FIX, NOT AN OPTIMISATION** (vc, 28 Aug 2026).
// Stripping notes per slide is broken by construction, because the splitter runs
// first and is notes-unaware: a bare `---` inside a multi-line note ends a slide
// mid-comment, and the note's tail lands at the top of the NEXT slide with no
// opener in front of it. There it is not a comment any more, it is prose, and it
// renders as body text -- a speaker's private remark on a screen in front of an
// audience, which is the exact outcome AC04 exists to prevent:
//
//     # Slide One
//
//     <!-- notes: PRIVATE-HEAD
//     ---                         <- the splitter breaks here
//     PRIVATE-TAIL -->            <- and this renders as a paragraph
//
// The head was swallowed correctly, so the author sees the note mostly working
// and never looks. That is what makes it worth fixing at the root rather than
// patching the splitter.
//
// AC04 says notes appear nowhere in any ARTIFACT -- not nowhere within a slide
// -- so removal is properly a deck-level concern, while `class:` and
// `background:` are genuinely per-slide and stay in render.rs. Doing it here
// makes an orphaned tail impossible rather than merely unlikely, and it is why
// render.rs carries no notes state at all.
//
// Removal is by POSITION IN THE LINE, not by whole line: `<!-- notes: the number
// is wrong --> Revenue` must lose the note and keep the word. Raw HTML is
// enabled downstream, so anything left behind reaches the artifact verbatim.

use crate::fence;
use std::borrow::Cow;

/// Strip every `<!-- notes: ... -->` from a deck body.
///
/// Returns the body and any warnings for the caller to print. A note inside a
/// code fence is author content and is left alone -- a deck documenting prez
/// shows prez's own syntax, and eating that would be the defect.
pub fn strip(source: &str) -> (String, Vec<String>) {
  let mut out = String::with_capacity(source.len());
  let mut warnings = Vec::new();
  let mut fence = fence::Scanner::default();
  let mut swallowing = false;

  for raw in source.lines() {
    // A note opened on an earlier line swallows everything up to its
    // terminator, INCLUDING anything that looks like a fence -- so the fence
    // scanner is not fed while swallowing. Feeding it would let three backticks
    // inside a note capture the remainder of the deck.
    let line = if swallowing {
      match after_comment_close(raw) {
        Some(rest) => {
          swallowing = false;
          rest
        }
        None => continue,
      }
    } else {
      raw
    };

    if !fence.feed(line) {
      keep(&mut out, line);
      continue;
    }

    let stripped = strip_line(line);
    swallowing = stripped.opened;
    // A line that held nothing but a note leaves no blank behind. A line that
    // was ALREADY blank is kept: blank lines are structural in markdown and
    // eating them would weld two paragraphs together.
    if stripped.found && stripped.line.trim().is_empty() {
      continue;
    }
    keep(&mut out, &stripped.line);
  }

  if swallowing {
    warnings.push(
      "unterminated '<!-- notes:' comment: everything after it was treated as \
       speaker notes and dropped. Close it with '-->'."
        .to_string(),
    );
  }
  (out, warnings)
}

fn keep(out: &mut String, line: &str) {
  out.push_str(line);
  out.push('\n');
}

struct Stripped<'a> {
  line: Cow<'a, str>,
  /// A note opened here and did not close: swallow following lines.
  opened: bool,
  /// A note was found and removed from this line.
  found: bool,
}

fn strip_line(line: &str) -> Stripped<'_> {
  if find_open(line).is_none() {
    return Stripped { line: Cow::Borrowed(line), opened: false, found: false };
  }
  let mut kept = String::new();
  let mut rest = line;
  loop {
    let Some(start) = find_open(rest) else {
      kept.push_str(rest);
      return Stripped { line: Cow::Owned(kept), opened: false, found: true };
    };
    kept.push_str(&rest[..start]);
    match rest[start..].find("-->") {
      Some(end) => rest = &rest[start + end + "-->".len()..],
      None => return Stripped { line: Cow::Owned(kept), opened: true, found: true },
    }
  }
}

/// Byte offset of a `<!--` whose comment body begins with `notes:`.
fn find_open(line: &str) -> Option<usize> {
  let mut from = 0usize;
  while let Some(offset) = line[from..].find("<!--") {
    let at = from + offset;
    let body = line[at + "<!--".len()..].trim_start();
    // `get` rather than a slice: the body may open with a multi-byte character
    // and `..6` would not be a char boundary.
    if body.get(.."notes:".len()).is_some_and(|key| key.eq_ignore_ascii_case("notes:")) {
      return Some(at);
    }
    from = at + "<!--".len();
  }
  None
}

fn after_comment_close(line: &str) -> Option<&str> {
  line.find("-->").map(|at| &line[at + "-->".len()..])
}

#[cfg(test)]
mod tests {
  use super::*;

  fn stripped(source: &str) -> String {
    strip(source).0
  }

  #[test]
  fn a_whole_line_note_is_removed_leaving_no_blank() {
    let out = stripped("# Revenue\n\n<!-- notes: the Q3 number is wrong -->\n\ntext\n");
    assert!(!out.contains("Q3"), "AC04: {out}");
    assert!(!out.contains("<!--"), "{out}");
    assert!(out.contains("# Revenue") && out.contains("text"), "{out}");
  }

  #[test]
  fn a_note_sharing_a_line_with_prose_loses_only_the_note() {
    let out = stripped("Revenue <!-- notes: do not read this out --> grew.\n");
    assert_eq!(out, "Revenue  grew.\n");
  }

  #[test]
  fn a_note_spanning_a_slide_break_takes_the_break_with_it() {
    // vc, 28 Aug 2026. The tail used to be promoted into slide two as prose.
    let src = "# Slide One\n\n<!-- notes: PRIVATE-HEAD\n---\nPRIVATE-TAIL -->\n\nVisible text\n";
    let out = stripped(src);
    assert!(!out.contains("PRIVATE-HEAD"), "AC04: {out}");
    assert!(!out.contains("PRIVATE-TAIL"), "AC04: the tail must not survive: {out}");
    assert!(!out.contains("---"), "the note's --- must not reach the splitter: {out}");
    assert!(out.contains("# Slide One") && out.contains("Visible text"), "{out}");
    assert_eq!(crate::split::slides(&out).len(), 1, "one slide, not two: {out}");
  }

  #[test]
  fn a_multi_line_note_is_stripped_whole_and_is_not_a_warning() {
    let (out, warnings) = strip("# T\n\n<!-- notes:\nprivate one\nprivate two\n-->\n\ntext\n");
    assert!(!out.contains("private"), "AC04: {out}");
    assert!(out.contains("text"), "{out}");
    assert!(warnings.is_empty(), "a closed note is not a warning: {warnings:?}");
  }

  #[test]
  fn an_unterminated_note_is_swallowed_to_the_end_and_warned_about() {
    let (out, warnings) = strip("# T\n\n<!-- notes: never closed\nstill private\n");
    assert!(!out.contains("private"), "AC04 beats content: {out}");
    assert_eq!(warnings.len(), 1);
    assert!(warnings[0].contains("unterminated"), "{warnings:?}");
  }

  #[test]
  fn a_fence_inside_a_note_does_not_capture_the_rest_of_the_deck() {
    let out = stripped("<!-- notes:\n```\nnot code\n-->\n\n# Still A Heading\n");
    assert!(out.contains("# Still A Heading"), "{out}");
    assert!(!out.contains("not code"), "AC04: {out}");
  }

  #[test]
  fn a_note_inside_a_code_fence_is_author_content() {
    // The case fence.rs exists for: a deck documenting prez's own syntax.
    let src = "```html\n<!-- notes: shown on purpose -->\n```\n";
    assert_eq!(stripped(src), src);
  }

  #[test]
  fn the_key_is_case_insensitive_and_the_spacing_is_not_load_bearing() {
    assert!(!stripped("<!--NOTES:hidden-->\n").contains("hidden"));
    assert!(!stripped("<!--   Notes:   hidden -->\n").contains("hidden"));
  }

  #[test]
  fn two_notes_on_one_line_both_go() {
    let out = stripped("a <!-- notes: one --> b <!-- notes: two --> c\n");
    assert_eq!(out, "a  b  c\n");
  }

  #[test]
  fn an_ordinary_comment_is_not_a_note() {
    let src = "<!-- TODO: rewrite this slide -->\n";
    assert_eq!(stripped(src), src);
  }
}
