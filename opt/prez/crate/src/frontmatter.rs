// Front matter: the optional `---` block at the very top of a deck.
//
// **THIS IS NOT YAML AND MUST NOT BECOME YAML.** It is the house's flat
// `key: value` form, the same one `llm/design/tokens.yaml` and the whiteboard
// headers use: one line per key, the value is everything after the first `: `
// to end of line, no nesting, no block scalars, no continuation lines, and
// quotes are a display delimiter rather than syntax. Reaching for a YAML parser
// here would also breach AC02 (comrak is the only dependency).
//
// The delimiter collision with slide breaks is settled by POSITION AND THEN BY
// CONTENT, and it took both. Position alone -- "front matter is the block whose
// opening `---` is at byte 0" -- silently ate the first slide of any deck that
// OPENED with a slide break, which is a legal and not unusual way to write one
// (vc, 28 Aug 2026):
//
//     ---            <- read as a front-matter opener
//     # Just A Title <- read as a front-matter line, and lost
//     ---            <- read as the closing fence
//
// So the block at byte 0 is front matter only if EVERY non-blank line in it
// parses as `key: value` with a key that looks like a key. Anything else and
// the whole source is handed back for the splitter to break on, which is the
// same trade this module already makes for an unclosed block: better a deck
// with no title than a deck silently missing a slide.
//
// There are NO `#` comments here. An earlier version skipped them, which is
// what made the failure above invisible -- a `# Heading` was read as a comment
// and dropped without even landing in `unknown`. It was also drift: the house
// key:value form this file follows has no comment syntax.

use std::collections::BTreeMap;

#[derive(Debug, Default, PartialEq)]
pub struct FrontMatter {
  pub title: Option<String>,
  pub author: Option<String>,
  pub date: Option<String>,
  pub theme: Option<String>,
  pub include: Vec<String>,
  pub mermaid: bool,
  /// Keys we do not know. Kept rather than dropped so the caller can warn about
  /// each by name -- a typo'd `titel:` that vanished silently would present as
  /// "the title stopped working" with nothing to go on.
  pub unknown: BTreeMap<String, String>,
}

impl FrontMatter {
  /// Every key this block actually declared, in a stable order.
  ///
  /// For a caller that has to say which keys it IGNORED. An included fragment's
  /// `title:` is silently dropped otherwise, and "silently" is the whole
  /// problem -- the author sees a deck whose title did not change and has
  /// nothing to go on.
  pub fn declared(&self) -> Vec<String> {
    let named = [
      ("title", self.title.is_some()),
      ("author", self.author.is_some()),
      ("date", self.date.is_some()),
      ("theme", self.theme.is_some()),
      ("include", !self.include.is_empty()),
      ("mermaid", self.mermaid),
    ];
    named
      .into_iter()
      .filter(|(_, set)| *set)
      .map(|(key, _)| key.to_string())
      .chain(self.unknown.keys().cloned())
      .collect()
  }
}

/// Split a deck source into its front matter and the body that follows.
///
/// Returns the body unchanged when there is no front-matter block, so the
/// caller never has to ask whether one was present before splitting slides.
pub fn parse(source: &str) -> (FrontMatter, &str) {
  let Some(rest) = source.strip_prefix("---") else {
    return (FrontMatter::default(), source);
  };
  // The opening fence must be a line of its own: `---foo` at byte 0 is content
  // (a setext-ish oddity, but the author's), not an opening delimiter.
  let rest = match rest.strip_prefix('\n') {
    Some(r) => r,
    None => match rest.strip_prefix("\r\n") {
      Some(r) => r,
      None => return (FrontMatter::default(), source),
    },
  };

  // An UNCLOSED front-matter block is treated as no front matter, and the whole
  // file stays body. The alternative -- swallowing the entire deck as front
  // matter -- turns one missing line into a silently empty presentation.
  let Some((block, body)) = split_at_closing_fence(rest) else {
    return (FrontMatter::default(), source);
  };

  match parse_block(block) {
    Some(fm) => (fm, body),
    // Not front matter after all: it was a slide break with a slide behind it.
    None => (FrontMatter::default(), source),
  }
}

fn split_at_closing_fence(rest: &str) -> Option<(&str, &str)> {
  let mut offset = 0usize;
  for line in rest.split_inclusive('\n') {
    if line.trim_end_matches(['\r', '\n']).trim() == "---" {
      return Some((&rest[..offset], &rest[offset + line.len()..]));
    }
    offset += line.len();
  }
  None
}

/// Read the candidate block, or reject it as not being front matter at all.
///
/// `None` means "this was a slide, not a header". See the module note: the
/// rejection is what stops a deck that opens with a slide break losing its first
/// slide, and it has to be strict about the KEY rather than merely requiring a
/// colon -- `# Introduction: The Problem` has a colon and is plainly a heading.
fn parse_block(block: &str) -> Option<FrontMatter> {
  let mut fm = FrontMatter::default();
  for line in block.lines() {
    let line = line.trim();
    // Blank lines are ordinary in a hand-written header and mean nothing.
    if line.is_empty() {
      continue;
    }
    let (key, value) = line.split_once(':')?;
    let key = key.trim();
    if key.is_empty() || !key.chars().all(|c| c.is_ascii_alphanumeric() || c == '_' || c == '-') {
      return None;
    }
    let key = key.to_ascii_lowercase();
    let value = unquote(value.trim());

    match key.as_str() {
      "title" => fm.title = Some(value.to_string()),
      "author" => fm.author = Some(value.to_string()),
      "date" => fm.date = Some(value.to_string()),
      "theme" => fm.theme = Some(value.to_string()),
      "include" => {
        fm.include = value
          .split(',')
          .map(str::trim)
          .filter(|s| !s.is_empty())
          .map(str::to_string)
          .collect()
      }
      // Present-and-true rather than present-at-all: `mermaid: false` reads as
      // an author turning it off, and honouring the word costs one comparison.
      "mermaid" => fm.mermaid = matches!(value.to_ascii_lowercase().as_str(), "true" | "yes" | "1"),
      _ => {
        fm.unknown.insert(key, value.to_string());
      }
    }
  }
  Some(fm)
}

/// Strip ONE matching pair of surrounding double quotes, the house rule.
///
/// Quotes inside the value are literal and are never unescaped -- writing
/// `title: "the counted body" is the sent body` keeps its inner quotes. Single
/// quotes are not delimiters and are left visible, deliberately: two delimiter
/// forms would silently eat two characters from a value that legitimately opens
/// and closes with an apostrophe.
fn unquote(value: &str) -> &str {
  if value.len() >= 2 && value.starts_with('"') && value.ends_with('"') {
    &value[1..value.len() - 1]
  } else {
    value
  }
}

#[cfg(test)]
mod tests {
  use super::*;

  #[test]
  fn reads_known_keys_and_leaves_the_body() {
    let src = "---\ntitle: A Deck\nauthor: Someone\nmermaid: true\n---\n# One\n";
    let (fm, body) = parse(src);
    assert_eq!(fm.title.as_deref(), Some("A Deck"));
    assert_eq!(fm.author.as_deref(), Some("Someone"));
    assert!(fm.mermaid);
    assert_eq!(body, "# One\n");
  }

  #[test]
  fn a_file_not_starting_with_a_fence_has_no_front_matter() {
    let src = "# One\n\n---\n\n# Two\n";
    let (fm, body) = parse(src);
    assert_eq!(fm, FrontMatter::default());
    assert_eq!(body, src, "the whole file stays body so the splitter sees the break");
  }

  #[test]
  fn an_unclosed_block_is_not_swallowed_as_front_matter() {
    let src = "---\ntitle: A Deck\n\n# One\n";
    let (fm, body) = parse(src);
    assert_eq!(fm.title, None);
    assert_eq!(body, src, "better a deck with no title than a silently empty one");
  }

  #[test]
  fn include_is_a_comma_separated_list() {
    let (fm, _) = parse("---\ninclude: a.md, b.md ,c.md\n---\n");
    assert_eq!(fm.include, vec!["a.md", "b.md", "c.md"]);
  }

  #[test]
  fn unknown_keys_are_kept_for_the_caller_to_warn_about() {
    let (fm, _) = parse("---\ntitel: typo\n---\n");
    assert_eq!(fm.unknown.get("titel").map(String::as_str), Some("typo"));
  }

  #[test]
  fn one_pair_of_double_quotes_is_stripped_and_inner_quotes_survive() {
    let (fm, _) = parse("---\ntitle: \"the \"counted\" body\"\n---\n");
    assert_eq!(fm.title.as_deref(), Some("the \"counted\" body"));
  }

  #[test]
  fn single_quotes_are_not_delimiters() {
    let (fm, _) = parse("---\ntitle: 'plain'\n---\n");
    assert_eq!(fm.title.as_deref(), Some("'plain'"));
  }

  #[test]
  fn a_value_may_contain_colons() {
    let (fm, _) = parse("---\ntitle: Ratio: 16:9\n---\n");
    assert_eq!(fm.title.as_deref(), Some("Ratio: 16:9"));
  }

  #[test]
  fn a_deck_opening_with_a_slide_break_keeps_its_first_slide() {
    // Reported by vc, 28 Aug 2026: position alone claimed this as front matter
    // and the first slide vanished into it.
    let src = "---\n# Slide One\n\nBody of one.\n\n---\n\n# Slide Two\n";
    let (fm, body) = parse(src);
    assert_eq!(fm, FrontMatter::default());
    assert_eq!(body, src, "the whole deck stays body so the splitter sees both slides");
  }

  #[test]
  fn a_lone_heading_between_rules_is_a_slide_not_front_matter() {
    // The fully silent case: nothing even landed in `unknown` to warn about.
    let src = "---\n# Just A Title\n---\n# Two\n";
    let (fm, body) = parse(src);
    assert_eq!(fm, FrontMatter::default());
    assert_eq!(body, src);
  }

  #[test]
  fn a_heading_with_a_colon_is_still_not_front_matter() {
    // `# Introduction: The Problem` splits on a colon, so requiring a colon is
    // not enough -- the KEY has to look like a key.
    let src = "---\n# Introduction: The Problem\n---\n# Two\n";
    let (_, body) = parse(src);
    assert_eq!(body, src);
  }

  #[test]
  fn one_unparseable_line_rejects_the_whole_block() {
    let src = "---\ntitle: Real Deck\nthis line is prose\n---\n# One\n";
    let (fm, body) = parse(src);
    assert_eq!(fm.title, None, "a partly-valid header is not a header");
    assert_eq!(body, src);
  }

  #[test]
  fn mermaid_false_means_off() {
    let (fm, _) = parse("---\nmermaid: false\n---\n");
    assert!(!fm.mermaid);
  }
}
