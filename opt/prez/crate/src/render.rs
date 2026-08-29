// Slide rendering: one slide's markdown becomes the HTML that goes inside its
// <section>, plus the presentation attributes its directives asked for.
//
// **NOTES ARE ALREADY GONE BY THE TIME ANYTHING HERE RUNS.** They are stripped
// deck-wide by `notes.rs` BEFORE the splitter, and this module carries no notes
// state at all. That is deliberate and it is not a convenience: notes removal
// cannot be done per slide, because the splitter runs first and would break a
// multi-line note in half, orphaning its tail into the next slide as prose. See
// the note at the top of `notes.rs` for the case that proved it. `deck.rs` is
// the only caller and holds that order.
//
// What is left here is the per-slide half, which genuinely is per-slide:
// `class:` and `background:` are lifted out of the source, and only what remains
// is handed to comrak. Lifting before rendering matters for the same reason it
// matters for notes -- raw HTML passes through comrak untouched (that is the
// escape hatch, spec 2), so a directive still present at render time would land
// in the artifact as a visible comment.

use crate::fence;

/// One rendered slide. Wrapping these in `<section>` is html.rs's job.
#[derive(Debug, Default, PartialEq)]
pub struct Slide {
  pub classes: Vec<String>,
  pub background: Option<String>,
  pub html: String,
}

/// Render one slide's source to HTML.
pub fn slide(source: &str) -> Slide {
  let lifted = lift_directives(source);
  Slide {
    classes: lifted.classes,
    background: lifted.background,
    html: comrak::markdown_to_html(&lifted.body, &options()),
  }
}

/// The comrak configuration, stated once.
///
/// The five GFM extensions the spec names and no others (spec 2), matching the
/// estate CMS's MDEx semantics so a page and a slide render the same markdown
/// the same way.
///
/// `tagfilter` is deliberately OFF. It is part of GFM, and it neuters `<script>`,
/// `<style>` and `<iframe>` -- which is exactly the raw-HTML escape hatch the
/// spec guarantees. There is no trust boundary to defend here: prez compiles
/// the author's own file, for the author, into a file they open themselves.
///
/// `front_matter_delimiter` is also unset: front matter is the house's flat
/// `key: value` form, not YAML, and `frontmatter.rs` has already removed it.
fn options() -> comrak::Options<'static> {
  let mut o = comrak::Options::default();
  o.extension.table = true;
  o.extension.strikethrough = true;
  o.extension.tasklist = true;
  o.extension.footnotes = true;
  o.extension.autolink = true;
  o.render.r#unsafe = true;
  o
}

#[derive(Default)]
struct Lifted {
  body: String,
  classes: Vec<String>,
  background: Option<String>,
}

impl Lifted {
  fn keep(&mut self, line: &str) {
    self.body.push_str(line);
    self.body.push('\n');
  }

  /// Repeated `class:` directives ACCUMULATE rather than replace, so a slide
  /// tagged both by hand and by an included fragment keeps both tags. Duplicates
  /// are dropped so the emitted attribute never reads `class="wide wide"`.
  fn add_classes(&mut self, value: &str) {
    for class in value.split_whitespace() {
      if !self.classes.iter().any(|held| held == class) {
        self.classes.push(class.to_string());
      }
    }
  }
}

fn lift_directives(source: &str) -> Lifted {
  let mut lifted = Lifted::default();
  let mut fence = fence::Scanner::default();

  for line in source.lines() {
    if !fence.feed(line) {
      lifted.keep(line);
      continue;
    }
    match directive(line) {
      Some(Directive::Class(value)) => lifted.add_classes(value),
      // Last `background:` wins. An author editing top-down expects the later
      // line to be the correction, not the one that gets ignored.
      Some(Directive::Background(value)) => lifted.background = Some(value.to_string()),
      None => lifted.keep(line),
    }
  }
  lifted
}

enum Directive<'a> {
  Class(&'a str),
  Background(&'a str),
}

/// Read a full-line HTML comment as a presentation directive.
///
/// The whole line must be the comment: one sharing a line with prose is the
/// author's own markup and passes through. A malformed `class:` is inert, which
/// is why these two can afford the strict reading that `notes:` cannot.
///
/// An unknown key is deliberately neither a directive nor a warning. A plain
/// `<!-- TODO: rewrite this slide -->` is ordinary markdown, and complaining
/// about it would teach authors to stop writing comments.
fn directive(line: &str) -> Option<Directive<'_>> {
  let inner = line.trim().strip_prefix("<!--")?.strip_suffix("-->")?;
  if inner.contains("-->") {
    return None; // two comments on one line, so neither is the whole line
  }
  let (key, value) = inner.trim().split_once(':')?;
  match key.trim().to_ascii_lowercase().as_str() {
    "class" => Some(Directive::Class(value.trim())),
    "background" => Some(Directive::Background(value.trim())),
    _ => None,
  }
}

#[cfg(test)]
mod tests {
  use super::*;

  fn html(source: &str) -> String {
    slide(source).html
  }

  #[test]
  fn gfm_tables_render() {
    let out = html("| a | b |\n| - | - |\n| 1 | 2 |\n");
    assert!(out.contains("<table>"), "{out}");
    assert!(out.contains("<td>1</td>"), "{out}");
  }

  #[test]
  fn strikethrough_tasklists_and_autolinks_render() {
    assert!(html("~~gone~~\n").contains("<del>gone</del>"));
    assert!(html("- [x] done\n").contains("type=\"checkbox\""));
    assert!(html("see https://example.com now\n").contains("<a href=\"https://example.com\">"));
  }

  #[test]
  fn footnotes_render() {
    let out = html("A claim[^1]\n\n[^1]: the source\n");
    assert!(out.contains("footnote"), "{out}");
  }

  #[test]
  fn raw_html_passes_through_untouched() {
    // The escape hatch: a slide may drop to HTML, style and script and all.
    let out = html("<div class=\"custom\"><script>go()</script></div>\n");
    assert!(out.contains("<div class=\"custom\">"), "{out}");
    assert!(out.contains("<script>go()</script>"), "{out}");
  }

  #[test]
  fn a_class_directive_is_lifted_and_leaves_no_trace() {
    let s = slide("<!-- class: wide dark -->\n\n# Title\n");
    assert_eq!(s.classes, vec!["wide", "dark"]);
    assert!(s.html.contains("<h1>Title</h1>"), "{}", s.html);
    assert!(!s.html.contains("class:"), "{}", s.html);
  }

  #[test]
  fn repeated_class_directives_accumulate_without_duplicates() {
    let s = slide("<!-- class: wide -->\n# T\n<!-- class: dark wide -->\n");
    assert_eq!(s.classes, vec!["wide", "dark"]);
  }

  #[test]
  fn the_last_background_directive_wins() {
    let s = slide("<!-- background: red -->\n# T\n<!-- background: #012 -->\n");
    assert_eq!(s.background.as_deref(), Some("#012"));
  }

  #[test]
  fn directives_inside_a_code_fence_are_content() {
    // A deck documenting prez shows its own syntax. Eating that would be the
    // same defect the splitter avoids with `---`.
    let s = slide("```html\n<!-- class: wide -->\n```\n");
    assert!(s.classes.is_empty(), "a fenced directive is not a directive");
    assert!(s.html.contains("class: wide"), "{}", s.html);
  }

  #[test]
  fn an_unknown_comment_passes_through_silently() {
    let s = slide("<!-- TODO: rewrite this slide -->\n\n# T\n");
    assert!(s.html.contains("<!-- TODO: rewrite this slide -->"), "{}", s.html);
  }

  #[test]
  fn blank_lines_survive_directive_lifting() {
    let s = slide("one\n\n<!-- class: x -->\n\ntwo\n");
    assert!(s.html.contains("<p>one</p>"), "{}", s.html);
    assert!(s.html.contains("<p>two</p>"), "{}", s.html);
  }

  #[test]
  fn a_directive_key_is_case_insensitive() {
    assert_eq!(slide("<!-- Class: wide -->\n# T\n").classes, vec!["wide"]);
  }

  #[test]
  fn a_directive_sharing_a_line_with_prose_is_the_authors_markup() {
    let s = slide("text <!-- class: wide --> more\n");
    assert!(s.classes.is_empty(), "not a full-line directive");
    assert!(s.html.contains("<!-- class: wide -->"), "{}", s.html);
  }
}
