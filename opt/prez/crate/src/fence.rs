// Fenced-code state: the one home for "am I inside a FENCED code block?".
//
// **THAT QUESTION IS NARROWER THAN "AM I IN CODE?" AND THE NAME HAS TO SAY SO.**
// CommonMark's other code form -- a block indented by four spaces -- is not
// tracked here, so an indented `<!-- notes: ... -->` is lifted as a directive
// and an indented `---` splits a slide, where the fenced equivalents are left
// as content (vc, 28 Aug 2026). Both misreadings err on the safe side of AC04,
// which is why the gap is recorded rather than closed: teaching this scanner the
// indented form means tracking list context and preceding blank lines, which is
// a real slice of CommonMark for a case no deck has yet hit. The hazard was
// never the gap -- it was a docstring claiming the broader question, which the
// next consumer would have believed. Say fenced, mean fenced.
//
// **TWO PASSES OVER A DECK ASK THAT QUESTION AND MUST GET THE SAME ANSWER.**
// The slide splitter asks it of every `---`, because a deck about code routinely
// contains a fenced YAML sample or a diff. The renderer asks it of every
// `<!-- ... -->`, because a deck about prez contains fenced examples of
// prez's own directives. If the two disagreed, a deck could split correctly
// and still have its directive examples silently eaten -- so the rule lives here
// once and both call it (IN-AG-HIGHLANDER-001).
//
// Fence rules follow CommonMark closely enough for real decks: a fence opens
// with three or more backticks or tildes, indented no more than three spaces,
// and closes on a line of the SAME character that is at least as long as the
// opener. That length rule is what lets a four-backtick fence wrap a block
// containing a three-backtick one, which is how anyone writes about markdown
// inside markdown.

/// Walks a deck's lines carrying fence state.
#[derive(Default)]
pub struct Scanner {
  open: Option<Fence>,
}

struct Fence {
  ch: char,
  len: usize,
}

impl Scanner {
  /// Feed the next source line and report whether it is ORDINARY TEXT AT FENCE
  /// DEPTH ZERO -- the only place a `---` separator or a `<!-- directive -->`
  /// means what it says.
  ///
  /// The opening and closing fence lines are themselves content, so they report
  /// false along with everything between them. An unclosed fence simply leaves
  /// the scanner open: refusing to build a deck over a missing closing fence
  /// would be a worse trade than rendering it as the author left it.
  pub fn feed(&mut self, line: &str) -> bool {
    match &self.open {
      Some(fence) => {
        if closes(fence, line) {
          self.open = None;
        }
        false
      }
      None => match opens(line) {
        Some(fence) => {
          self.open = Some(fence);
          false
        }
        None => true,
      },
    }
  }
}

fn opens(line: &str) -> Option<Fence> {
  let trimmed = line.trim_start();
  // More than three leading spaces makes it an indented code block, not a
  // fence, and its content is literal anyway.
  if line.len() - trimmed.len() > 3 {
    return None;
  }
  let ch = trimmed.chars().next()?;
  if ch != '`' && ch != '~' {
    return None;
  }
  let len = trimmed.chars().take_while(|c| *c == ch).count();
  if len < 3 {
    return None;
  }
  // An info string may not contain a backtick on a backtick fence, which is how
  // CommonMark keeps inline code from opening a block.
  if ch == '`' && trimmed[len..].contains('`') {
    return None;
  }
  Some(Fence { ch, len })
}

fn closes(open: &Fence, line: &str) -> bool {
  let trimmed = line.trim();
  if trimmed.is_empty() {
    return false;
  }
  trimmed.chars().all(|c| c == open.ch) && trimmed.chars().count() >= open.len
}

#[cfg(test)]
mod tests {
  use super::*;

  /// Feed a whole source and collect the depth-zero verdict per line.
  fn verdicts(src: &str) -> Vec<bool> {
    let mut scanner = Scanner::default();
    src.lines().map(|l| scanner.feed(l)).collect()
  }

  #[test]
  fn ordinary_text_is_at_depth_zero() {
    assert_eq!(verdicts("# One\n\ntext\n"), vec![true, true, true]);
  }

  #[test]
  fn a_fence_and_everything_in_it_is_not_depth_zero() {
    assert_eq!(verdicts("a\n```\nb\n```\nc\n"), vec![true, false, false, false, true]);
  }

  #[test]
  fn a_shorter_closer_does_not_close_a_longer_fence() {
    assert_eq!(verdicts("````\n```\nstill in\n````\nout\n"), vec![false, false, false, false, true]);
  }

  #[test]
  fn a_tilde_fence_is_not_closed_by_backticks() {
    assert_eq!(verdicts("~~~\n```\nstill in\n~~~\nout\n"), vec![false, false, false, false, true]);
  }

  #[test]
  fn an_info_string_opens_a_fence_but_inline_code_does_not() {
    assert_eq!(verdicts("```yaml\nx\n```\n"), vec![false, false, false]);
    assert_eq!(verdicts("use `a` and `b`\n"), vec![true]);
  }

  #[test]
  fn four_spaces_of_indent_is_an_indented_block_not_a_fence() {
    // And note what this pins: the indented block's CONTENT still reports depth
    // zero, because this scanner tracks fences only. That is the known gap in
    // the module note, asserted here so it is a decision rather than a surprise.
    assert_eq!(verdicts("    ```\nafter\n"), vec![true, true]);
  }

  #[test]
  fn an_unclosed_fence_keeps_the_rest_of_the_input_inside_it() {
    assert_eq!(verdicts("```\na\nb\n"), vec![false, false, false]);
  }
}
