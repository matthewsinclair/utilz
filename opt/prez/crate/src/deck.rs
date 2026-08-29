// The build pipeline: source file in, artifact out.
//
// This is the only place that knows the ORDER of the compile -- read, front
// matter, includes, split, render, inline, theme, assemble -- and it does none
// of those jobs itself. Each step is a module that can be reasoned about alone;
// this file is the sentence they spell out.

use crate::args::{Command, Verb};
use crate::{drive, frontmatter, html, inline, notes, render, split, theme, Failure};
use std::path::{Path, PathBuf};

pub fn run(cmd: &Command) -> Result<(), Failure> {
  match cmd.verb {
    Verb::Build if cmd.watch => watch(cmd),
    Verb::Build => build(cmd).map(|_| ()),
    Verb::Pdf => pdf(cmd),
    Verb::Present => present(cmd),
  }
}

fn build(cmd: &Command) -> Result<PathBuf, Failure> {
  let out = output_path(cmd, "html");
  write(&out, &compile(cmd, None)?.artifact)?;
  println!("prez: wrote {}", out.display());
  Ok(out)
}

fn pdf(cmd: &Command) -> Result<(), Failure> {
  let browser = drive::find(cmd.browser.as_deref())?;
  let out = output_path(cmd, "pdf");
  // The intermediate HTML is a build product of THIS run and belongs in the
  // temp directory: writing it beside the deck would leave a file the user did
  // not ask for and did not know to delete.
  let staged = scratch("html");
  let compiled = compile(cmd, paper_rule(cmd.paper.as_deref())?)?;
  write(&staged, &compiled.artifact)?;

  // The slide count travels so the printer can check what came back against
  // what went in -- the base print rules are order-protected, not
  // !important-proof (drive::verify_pagination).
  report(&drive::print_to_pdf(&browser, &staged, &out, compiled.slides)?);
  let _ = std::fs::remove_file(&staged);
  println!("prez: wrote {}", out.display());
  Ok(())
}

fn present(cmd: &Command) -> Result<(), Failure> {
  // `-o` still means "keep the artifact here"; without it the deck is staged in
  // temp. Either way the file must OUTLIVE this process -- the browser is still
  // reading it after prez exits (spec 6).
  let compiled = compile(cmd, None)?;
  let out = match cmd.out.is_some() {
    true => output_path(cmd, "html"),
    false => scratch("html"),
  };
  write(&out, &compiled.artifact)?;
  drive::open_presenting(cmd.browser.as_deref(), &out)?;
  println!("prez: presenting {}", out.display());
  Ok(())
}

/// Rebuild on change (spec 1, `--watch`).
///
/// Polling rather than filesystem events: a watcher crate is a dependency AC02
/// does not allow, and a 400 ms poll of one file is imperceptible next to the
/// editor's own save latency. Ctrl-C ends it -- the default SIGINT disposition
/// is right here, and installing a handler to print something prettier would be
/// a handler that can itself go wrong.
fn watch(cmd: &Command) -> Result<(), Failure> {
  let input = PathBuf::from(&cmd.input);
  // The first build is not tolerated on failure: a deck that does not compile
  // at all is a mistake to report now, not to sit and poll over.
  build(cmd)?;
  println!("prez: watching {} -- ctrl-c to stop", input.display());

  let mut seen = modified(&input);
  loop {
    std::thread::sleep(std::time::Duration::from_millis(400));
    let now = modified(&input);
    if now == seen {
      continue;
    }
    seen = now;
    // A failure here is REPORTED AND SURVIVED. Half-saved decks are normal
    // while typing, and exiting on the first syntax error would make --watch
    // useless exactly when it is most wanted.
    match build(cmd) {
      Ok(_) => {}
      Err(e) => eprintln!("prez: {} ({})", e.message, e.remedy.unwrap_or_default()),
    }
  }
}

fn modified(path: &Path) -> Option<std::time::SystemTime> {
  std::fs::metadata(path).and_then(|m| m.modified()).ok()
}

/// One compiled deck, and how many slides went into it.
///
/// The count is carried rather than recomputed because the PDF path checks it
/// against the pages that came back, and a second derivation could disagree with
/// the first (IN-AG-HIGHLANDER-001).
struct Compiled {
  artifact: String,
  slides: usize,
}

/// Read a deck and compile it to one self-contained artifact.
fn compile(cmd: &Command, paper: Option<String>) -> Result<Compiled, Failure> {
  let input = Path::new(&cmd.input);
  let source = std::fs::read_to_string(input).map_err(|e| {
    Failure::new(
      format!("cannot read deck '{}': {e}", input.display()),
      "check the path, or run 'prez --help'",
    )
  })?;
  let base = input.parent().filter(|p| !p.as_os_str().is_empty()).unwrap_or(Path::new("."));

  let (front, body) = frontmatter::parse(&source);
  let mut warnings: Vec<String> = front
    .unknown
    .keys()
    .map(|key| format!("unknown front-matter key '{key}' ignored"))
    .collect();

  // NOTES COME OUT BEFORE THE SPLIT, and the order is the fix rather than a
  // preference: a multi-line note containing a `---` would otherwise be torn in
  // half by the splitter and its tail promoted into the next slide as prose
  // (AC04, notes.rs). Includes are folded in first so an included fragment's
  // notes are stripped by the same pass.
  let body = with_includes(body, base, input, &front.include, &mut warnings)?;
  let (body, note_warnings) = notes::strip(&body);
  warnings.extend(note_warnings);

  let sources = split::slides(&body);
  if sources.is_empty() {
    return Err(Failure::new(
      format!("'{}' has no slides", input.display()),
      "a deck needs at least one slide; separate slides with a line of exactly ---",
    ));
  }

  let mut slides = Vec::with_capacity(sources.len());
  for (index, source) in sources.iter().enumerate() {
    let mut slide = render::slide(source);
    let (html, image_warnings) = inline::images(&slide.html, base);
    slide.html = html;
    warnings.extend(image_warnings.into_iter().map(|w| format!("slide {}: {w}", index + 1)));
    slides.push(slide);
  }

  let theme = theme::load(cmd.theme.as_deref(), front.theme.as_deref(), base)?;
  warn_undeclared_classes(&slides, &theme, &mut warnings);
  let artifact = html::assemble(&html::Document {
    title: front.title.as_deref(),
    slides: &slides,
    theme: &theme,
    mermaid: front.mermaid,
    paper,
  });

  report(&warnings);
  Ok(Compiled { artifact, slides: slides.len() })
}

/// Report every `class:` a slide uses that the chosen theme does not style.
///
/// **THIS IS THE ORTHOGONALITY SEAM MADE VISIBLE.** A `class:` directive is
/// content naming a theme's concept, so a deck written for one theme silently
/// loses its layout under another -- which defeats the entire point of being
/// able to swap themes. Nothing is broken enough to refuse the build, but the
/// author deserves to hear that the word they wrote did nothing, and the remedy
/// names the vocabulary every theme is expected to declare.
///
/// Warned per CLASS rather than per slide, so a deck using `title` on six slides
/// under a theme that lacks it produces one line, not six.
fn warn_undeclared_classes(slides: &[render::Slide], theme: &theme::Theme, warnings: &mut Vec<String>) {
  let mut reported: Vec<&str> = Vec::new();
  for class in slides.iter().flat_map(|slide| slide.classes.iter()) {
    if reported.contains(&class.as_str()) || theme::declares(theme, class) {
      continue;
    }
    reported.push(class);
    warnings.push(format!(
      "class '{class}' has no effect: {} does not style it. Every theme is expected to declare: {}",
      theme.name,
      theme::STANDARD_CLASSES.join(", ")
    ));
  }
}

/// Append the decks named by the front matter's `include:` key.
///
/// The included file's text is concatenated onto the body with a slide break
/// between, so a fragment may itself hold several slides. Paths resolve beside
/// the deck that NAMED them, not the shell's cwd, so a deck built from another
/// directory still finds its own fragments.
///
/// Includes are NOT recursive -- one level covers a shared cover or closing
/// section without opening a cycle that would need detecting -- but every way an
/// include can quietly do less than the author asked is reported (vc's
/// conditions, 28 Aug 2026): a missing fragment is an ERROR naming both files, a
/// nested `include:` warns that it was not followed, and any other front-matter
/// key in a fragment warns that only the top-level deck can set it. Silently
/// non-recursive is a trap; loudly non-recursive is a design.
fn with_includes(
  body: &str,
  base: &Path,
  deck: &Path,
  include: &[String],
  warnings: &mut Vec<String>,
) -> Result<String, Failure> {
  if include.is_empty() {
    return Ok(body.to_string());
  }
  let mut out = body.to_string();
  for name in include {
    let path = base.join(name);
    let text = std::fs::read_to_string(&path).map_err(|e| {
      Failure::new(
        format!("cannot read '{}', included by '{}': {e}", path.display(), deck.display()),
        "'include:' paths are resolved beside the deck that names them",
      )
    })?;

    let (front, fragment) = frontmatter::parse(&text);
    if !front.include.is_empty() {
      warnings.push(format!(
        "'{}' has its own 'include:' and includes are not recursive, so {} was not read",
        path.display(),
        front.include.join(", ")
      ));
    }
    let ignored: Vec<String> =
      front.declared().into_iter().filter(|key| key != "include").collect();
    if !ignored.is_empty() {
      warnings.push(format!(
        "'{}' is an included fragment, so only the top-level deck's front matter applies; ignored: {}",
        path.display(),
        ignored.join(", ")
      ));
    }

    out.push_str("\n\n---\n\n");
    out.push_str(fragment);
  }
  Ok(out)
}

/// Turn `--paper 254x142.9` into the CSS `@page size` value.
///
/// `None` means the flag was not given, which is NOT the same as "use the
/// default": the default is emitted ahead of the theme so a theme may change it,
/// while an explicit flag is emitted last and beats everything (html::stylesheet).
fn paper_rule(paper: Option<&str>) -> Result<Option<String>, Failure> {
  let Some(spec) = paper else {
    return Ok(None);
  };
  let refuse = || {
    Failure::new(
      format!("--paper '{spec}' is not a page size"),
      "give width x height in millimetres, eg --paper 254x142.9",
    )
  };
  let (w, h) = spec.split_once(['x', 'X']).ok_or_else(refuse)?;
  let (w, h) = (w.trim(), h.trim());
  if w.parse::<f64>().is_err() || h.parse::<f64>().is_err() {
    return Err(refuse());
  }
  Ok(Some(format!("{w}mm {h}mm")))
}

fn output_path(cmd: &Command, extension: &str) -> PathBuf {
  match &cmd.out {
    Some(out) => PathBuf::from(out),
    None => PathBuf::from(&cmd.input).with_extension(extension),
  }
}

fn scratch(extension: &str) -> PathBuf {
  let stamp = std::time::SystemTime::now()
    .duration_since(std::time::UNIX_EPOCH)
    .map(|d| d.as_nanos())
    .unwrap_or_default();
  std::env::temp_dir().join(format!("prez-{}-{stamp}.{extension}", std::process::id()))
}

fn write(path: &Path, contents: &str) -> Result<(), Failure> {
  if let Some(parent) = path.parent().filter(|p| !p.as_os_str().is_empty()) {
    std::fs::create_dir_all(parent).map_err(|e| {
      Failure::new(
        format!("cannot create '{}': {e}", parent.display()),
        "check the -o path and its permissions",
      )
    })?;
  }
  std::fs::write(path, contents).map_err(|e| {
    Failure::new(format!("cannot write '{}': {e}", path.display()), "check the -o path and its permissions")
  })
}

/// Warnings go to stderr from here and nowhere else, the same way failures leave
/// by the single door in main.rs. Two printers would drift in wording.
fn report(warnings: &[String]) {
  for warning in warnings {
    eprintln!("prez: warning: {warning}");
  }
}

#[cfg(test)]
mod tests {
  use super::*;

  #[test]
  fn an_absent_paper_flag_is_not_an_override_and_a_present_one_is() {
    assert_eq!(paper_rule(None).unwrap(), None, "no flag means the theme may still decide");
    assert_eq!(paper_rule(Some("210x297")).unwrap().as_deref(), Some("210mm 297mm"));
    assert_eq!(paper_rule(Some("254 x 142.9")).unwrap().as_deref(), Some("254mm 142.9mm"));
  }

  #[test]
  fn a_paper_size_that_is_not_a_size_is_refused_with_the_form_it_wanted() {
    let e = paper_rule(Some("a4")).unwrap_err();
    assert!(e.message.contains("not a page size"), "{}", e.message);
    assert!(e.remedy.unwrap().contains("254x142.9"));
    assert!(paper_rule(Some("wide x tall")).is_err());
  }

  #[test]
  fn the_output_path_swaps_the_extension_unless_told_otherwise() {
    let cmd = |out: Option<&str>| Command {
      verb: Verb::Build,
      input: "decks/talk.md".into(),
      out: out.map(str::to_string),
      theme: None,
      watch: false,
      paper: None,
      browser: None,
    };
    assert_eq!(output_path(&cmd(None), "html"), PathBuf::from("decks/talk.html"));
    assert_eq!(output_path(&cmd(None), "pdf"), PathBuf::from("decks/talk.pdf"));
    assert_eq!(output_path(&cmd(Some("x.html")), "html"), PathBuf::from("x.html"));
  }

  fn sandbox(name: &str) -> PathBuf {
    let dir = std::env::temp_dir().join(format!("prez-deck-{}-{name}", std::process::id()));
    std::fs::create_dir_all(&dir).unwrap();
    dir
  }

  #[test]
  fn includes_are_appended_behind_a_slide_break() {
    let dir = sandbox("plain");
    std::fs::write(dir.join("closing.md"), "# Thanks\n").unwrap();
    let mut warnings = Vec::new();
    let deck = dir.join("talk.md");
    let out =
      with_includes("# One\n", &dir, &deck, &["closing.md".to_string()], &mut warnings).unwrap();
    assert_eq!(split::slides(&out).len(), 2, "{out}");
    assert!(warnings.is_empty(), "{warnings:?}");
  }

  #[test]
  fn a_missing_include_names_both_the_fragment_and_the_deck_that_asked_for_it() {
    let deck = Path::new("/nowhere/talk.md");
    let mut warnings = Vec::new();
    let e = with_includes("# One\n", Path::new("/nowhere"), deck, &["gone.md".into()], &mut warnings)
      .unwrap_err();
    assert!(e.message.contains("gone.md"), "{}", e.message);
    assert!(e.message.contains("talk.md"), "the deck that named it: {}", e.message);
  }

  #[test]
  fn a_fragments_own_front_matter_is_stripped_and_reported_rather_than_dropped() {
    let dir = sandbox("frontmatter");
    std::fs::write(dir.join("part.md"), "---\ntitle: Ignored\nmermaid: true\n---\n# Part\n")
      .unwrap();
    let mut warnings = Vec::new();
    let deck = dir.join("talk.md");
    let out =
      with_includes("# One\n", &dir, &deck, &["part.md".to_string()], &mut warnings).unwrap();
    assert!(!out.contains("title: Ignored"), "the block must not become a slide: {out}");
    assert!(out.contains("# Part"), "{out}");
    assert_eq!(warnings.len(), 1, "{warnings:?}");
    assert!(warnings[0].contains("title"), "{warnings:?}");
    assert!(warnings[0].contains("mermaid"), "{warnings:?}");
  }

  #[test]
  fn a_nested_include_warns_that_it_was_not_followed() {
    // Non-recursive is fine; SILENTLY non-recursive is the trap.
    let dir = sandbox("nested");
    std::fs::write(dir.join("part.md"), "---\ninclude: deeper.md\n---\n# Part\n").unwrap();
    let mut warnings = Vec::new();
    let deck = dir.join("talk.md");
    with_includes("# One\n", &dir, &deck, &["part.md".to_string()], &mut warnings).unwrap();
    assert_eq!(warnings.len(), 1, "{warnings:?}");
    assert!(warnings[0].contains("not recursive"), "{warnings:?}");
    assert!(warnings[0].contains("deeper.md"), "it names what went unread: {warnings:?}");
  }
}
