// Hand-rolled argument parsing (AC02 -- comrak is the only dependency).
//
// The surface is small and fixed, so a parser generator would be more code to
// read than the parser. What this file owes the user is the part a generator
// gives away free and a hand-rolled one usually forgets: an unknown flag is an
// ERROR NAMING ITSELF, never a silently ignored token.

use crate::Failure;

pub const USAGE: &str = "\
prez -- markdown in, one self-contained HTML presentation out.

Usage:
  prez build   <deck.md> [-o out.html] [--theme=T] [--watch]
  prez pdf     <deck.md> [-o out.pdf]  [--theme=T] [--paper=WxH] [--browser=PATH]
  prez present <deck.md> [--theme=T] [--browser=PATH]
  prez --help | --version

Every flag below takes its value either way: --theme=simple or --theme simple.

Options:
  -o, --out PATH    Output path. Default: beside the input, extension swapped.
      --theme T     Theme: a built-in name, a .css file, or a directory holding
                    theme.css. Names are also looked up in PREZ_THEME_PATH.
                    Beats the deck's front-matter 'theme:' key.
      --watch       Rebuild whenever the input changes (build only).
      --paper WxH   PDF page size in millimetres, eg 254x142.9 (16:9 default).
      --browser P   Browser to drive for pdf/present. Default: probe the
                    Chromium family, then fall back to the system opener.

The browser presents; prez only builds. There is no server and no viewer.
";

#[derive(Debug, PartialEq)]
pub enum Invocation {
  Help,
  Version,
  Command(Command),
}

#[derive(Debug, PartialEq)]
pub struct Command {
  pub verb: Verb,
  pub input: String,
  pub out: Option<String>,
  pub theme: Option<String>,
  pub watch: bool,
  pub paper: Option<String>,
  pub browser: Option<String>,
}

#[derive(Debug, PartialEq, Clone, Copy)]
pub enum Verb {
  Build,
  Pdf,
  Present,
}

impl std::fmt::Display for Verb {
  fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
    f.write_str(match self {
      Verb::Build => "build",
      Verb::Pdf => "pdf",
      Verb::Present => "present",
    })
  }
}

pub fn parse(argv: &[String]) -> Result<Invocation, Failure> {
  let Some(first) = argv.first() else {
    return Err(Failure::new("no command given", "try 'prez --help'"));
  };

  match first.as_str() {
    "--help" | "-h" | "help" => return Ok(Invocation::Help),
    "--version" | "-V" => return Ok(Invocation::Version),
    _ => {}
  }

  let verb = match first.as_str() {
    "build" => Verb::Build,
    "pdf" => Verb::Pdf,
    "present" => Verb::Present,
    other => {
      return Err(Failure::new(
        format!("unknown command '{}'", other),
        "expected one of: build, pdf, present. try 'prez --help'",
      ))
    }
  };

  let mut cmd = Command {
    verb,
    input: String::new(),
    out: None,
    theme: None,
    watch: false,
    paper: None,
    browser: None,
  };
  let mut input: Option<String> = None;

  // Index-based rather than an iterator because the value-taking flags need to
  // consume the NEXT element, and a for-loop over an iterator cannot without a
  // peekable dance that reads worse than the index.
  let mut i = 1;
  while i < argv.len() {
    // BOTH `--theme simple` AND `--theme=simple` must work. Matching the exact
    // string only meant the equals form fell through to the unknown-flag arm
    // below and was refused by name -- and that is the form hv writes and the
    // form a user reaches for first (vc, 28 Aug 2026). It failed loudly rather
    // than quietly, which is the only reason it was survivable; neither of us
    // noticed for a day because we both happened to type the space form.
    let (arg, attached) = match argv[i].split_once('=') {
      Some((flag, value)) if flag.starts_with('-') => (flag, Some(value.to_string())),
      _ => (argv[i].as_str(), None),
    };
    let mut value = |flag: &str| match attached.clone() {
      Some(v) => Ok(v),
      None => take_value(argv, &mut i, flag),
    };

    match arg {
      "-o" | "--out" => cmd.out = Some(value("-o")?),
      "--theme" => cmd.theme = Some(value("--theme")?),
      "--paper" => cmd.paper = Some(value("--paper")?),
      "--browser" => cmd.browser = Some(value("--browser")?),
      "--watch" => cmd.watch = true,
      // A bare "-" is a filename in some tools and a stdin convention in
      // others. It is neither here, and guessing which the user meant is how a
      // deck gets written to a file called "-".
      other if other.starts_with('-') => {
        return Err(Failure::new(
          format!("unknown flag '{}' for 'prez {}'", other, verb),
          "try 'prez --help' for the flags this command accepts",
        ))
      }
      other => {
        if input.replace(other.to_string()).is_some() {
          return Err(Failure::new(
            format!("more than one input given; '{}' is the second", other),
            "prez builds one deck at a time",
          ));
        }
      }
    }
    i += 1;
  }

  // Flags that belong to another verb are refused rather than ignored. Silently
  // accepting `present --watch` would leave the user believing something is
  // watching when nothing is (IN-AG-NO-SILENT-001).
  if cmd.watch && verb != Verb::Build {
    return Err(Failure::new(
      format!("--watch is not available for 'prez {}'", verb),
      "only 'prez build' watches; pdf and present are one-shot",
    ));
  }
  if cmd.paper.is_some() && verb != Verb::Pdf {
    return Err(Failure::new(
      format!("--paper is not available for 'prez {}'", verb),
      "only 'prez pdf' has a page size",
    ));
  }
  if cmd.browser.is_some() && verb == Verb::Build {
    return Err(Failure::new(
      "--browser is not available for 'prez build'",
      "build writes a file and drives no browser; use pdf or present",
    ));
  }

  cmd.input = input.ok_or_else(|| {
    Failure::new(
      format!("'prez {}' needs an input deck", verb),
      format!("usage: prez {} <deck.md>", verb),
    )
  })?;

  Ok(Invocation::Command(cmd))
}

fn take_value(argv: &[String], i: &mut usize, flag: &str) -> Result<String, Failure> {
  *i += 1;
  argv.get(*i).cloned().ok_or_else(|| {
    Failure::new(format!("{} needs a value", flag), format!("eg: {} <value>", flag))
  })
}

#[cfg(test)]
mod tests {
  use super::*;

  fn argv(s: &[&str]) -> Vec<String> {
    s.iter().map(|x| x.to_string()).collect()
  }

  #[test]
  fn build_takes_input_and_out() {
    let Invocation::Command(c) = parse(&argv(&["build", "d.md", "-o", "x.html"])).unwrap() else {
      panic!("expected a command");
    };
    assert_eq!(c.verb, Verb::Build);
    assert_eq!(c.input, "d.md");
    assert_eq!(c.out.as_deref(), Some("x.html"));
  }

  #[test]
  fn every_value_flag_takes_both_the_equals_and_the_space_form() {
    // The whole defect was that nobody exercised one of the two forms, so the
    // test asserts they produce the IDENTICAL command rather than that each
    // parses. hv writes --theme=simple; we both happened to type the space form.
    let spaced =
      parse(&argv(&["pdf", "d.md", "-o", "x.pdf", "--theme", "simple", "--paper", "210x297", "--browser", "/b"])).unwrap();
    let equals =
      parse(&argv(&["pdf", "d.md", "-o=x.pdf", "--theme=simple", "--paper=210x297", "--browser=/b"])).unwrap();
    assert_eq!(spaced, equals);

    let Invocation::Command(c) = equals else { panic!("expected a command") };
    assert_eq!(c.theme.as_deref(), Some("simple"));
    assert_eq!(c.out.as_deref(), Some("x.pdf"));
    assert_eq!(c.paper.as_deref(), Some("210x297"));
    assert_eq!(c.browser.as_deref(), Some("/b"));
  }

  #[test]
  fn an_equals_in_a_value_or_a_filename_is_not_a_flag_separator() {
    let Invocation::Command(c) = parse(&argv(&["build", "a=b.md", "--theme=x=y.css"])).unwrap() else {
      panic!("expected a command")
    };
    assert_eq!(c.input, "a=b.md", "an input is not split on =");
    assert_eq!(c.theme.as_deref(), Some("x=y.css"), "only the FIRST = separates");
  }

  #[test]
  fn unknown_flag_is_refused_by_name() {
    let e = parse(&argv(&["build", "d.md", "--colour"])).unwrap_err();
    assert!(e.message.contains("--colour"), "message should name the flag: {}", e.message);
  }

  #[test]
  fn watch_is_refused_for_present() {
    let e = parse(&argv(&["present", "d.md", "--watch"])).unwrap_err();
    assert!(e.message.contains("--watch"));
  }

  #[test]
  fn missing_input_is_refused() {
    let e = parse(&argv(&["build"])).unwrap_err();
    assert!(e.message.contains("needs an input deck"));
  }

  #[test]
  fn a_flag_missing_its_value_is_refused() {
    let e = parse(&argv(&["build", "d.md", "--theme"])).unwrap_err();
    assert!(e.message.contains("--theme needs a value"));
  }

  #[test]
  fn two_inputs_are_refused() {
    let e = parse(&argv(&["build", "a.md", "b.md"])).unwrap_err();
    assert!(e.message.contains("more than one input"));
  }
}
