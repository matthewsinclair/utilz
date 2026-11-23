//! `showreel qr`: the QR codes a reel's config gives an address for.
//!
//! **THE STAMP IS WRITTEN AND READ HERE, SO THE TWO CANNOT DISAGREE.** The
//! build's check (`payload::socials`, ST0017 AC-4.2) reads the address a QR was
//! made for out of a leading comment. This module writes that comment and owns
//! its format, and payload.rs imports the reader rather than keeping a copy.
//! The check, its words and the rows it covers stay payload.rs's, unchanged.
//!
//! **IT DECIDES BEFORE IT WRITES.** `targets` says what goes where, `render`
//! makes each file's text, and every refusal either can make is made before
//! `run` writes anything, so a refused run leaves the reel as it found it.
//!
//! **IT READS THE CONFIG AND NOT THE PLAN.** The plan admits every named asset
//! and refuses a `qr:` naming a file that is not there, which is the file this
//! verb exists to write.

use crate::{build, config, plan};
use artifact::Failure;
use qrcode::render::svg;
use qrcode::QrCode;
use std::path::{Path, PathBuf};

/// The stamp `showreel qr` writes into the SVG it generates.
pub const QR_STAMP: &str = "showreel-qr:";

/// What the build and `qr` both say of a QR file that is there but cannot be
/// read as text: cc's words, issue I88af1f3, in one place.
pub const UNREADABLE: &str = "could not be read as text";

/// One QR the config gives an address for.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Target {
  /// The entry that asks for it, as the report and a refusal name it.
  pub whose: String,
  /// Where the build looks for it, lexically normalised.
  pub path: PathBuf,
  /// The address, from `plan::social_url` or `plan::venue_url`, the rules the
  /// build reads by. The QR encodes this value and the stamp carries it, so a
  /// fresh QR never reads as stale.
  pub url: String,
}

/// What a file already at a target says of itself.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Kept {
  /// Its stamp names the address the config gives.
  Matches,
  /// Its stamp names another address, which this carries.
  Was(String),
  /// It has no stamp, so nothing can say whether it matches.
  Unstamped,
  /// It is there but cannot be read as text, for the reason this carries.
  Unreadable(String),
}

/// What `run` did at one target.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Done {
  Wrote,
  Kept(Kept),
}

/// A finished run: the reel it ran in, and each target with what was done.
#[derive(Debug)]
pub struct Report {
  pub reel: PathBuf,
  pub done: Vec<(Target, Done)>,
}

/// The address a QR's stamp says it was generated for, if it carries one.
pub fn stamped_for(svg: &str) -> Option<String> {
  let open = svg.find("<!--")?;
  if !svg[..open].trim().is_empty() {
    return None;
  }
  let rest = &svg[open + 4..];
  let body = &rest[..rest.find("-->")?];
  body.strip_prefix(QR_STAMP).map(str::to_string)
}

/// Every QR the config gives an address for, in config order: each social with
/// a url, at `plan::qr_path`, then the session's `venue_url`, at
/// `plan::venue_qr_path`. Absent is valid: no url, no QR.
///
/// `reel` is absolute, as `run` makes it. Containment is decided lexically,
/// with plan.rs's `tidy`, because a QR not yet written is a valid
/// configuration and `canonicalize` refuses a path that does not exist.
///
/// **IT REFUSES A TARGET OUTSIDE THE REEL.** An explicit `qr:` is free text,
/// and a writer must not follow it out of the reel. It also refuses two
/// targets at one path that want different addresses, naming both; two that
/// want the same address are one file.
pub fn targets(reel: &Path, cfg: &config::Reel) -> Result<Vec<Target>, Failure> {
  let mut wanted = Vec::new();
  for s in &cfg.socials {
    if let Some(url) = plan::social_url(s) {
      wanted.push(Target {
        whose: format!("socials: {}", s.label),
        path: plan::qr_path(reel, s),
        url: url.to_string(),
      });
    }
  }
  if let Some(venue) = plan::venue_url(cfg) {
    wanted.push(Target {
      whose: "session: venue_url".to_string(),
      path: plan::venue_qr_path(reel),
      url: venue.to_string(),
    });
  }

  let root = plan::tidy(reel);
  let mut out: Vec<Target> = Vec::new();
  for t in wanted {
    let path = plan::tidy(&t.path);
    if !path.starts_with(&root) || path == root {
      return Err(Failure::new(
        format!(
          "{}: its QR would be written at {}, which is outside the reel",
          t.whose,
          t.path.display()
        ),
        format!(
          "give it a qr: path inside the reel directory: {}",
          reel.display()
        ),
      ));
    }
    match out.iter().find(|o| o.path == path) {
      Some(o) if o.url == t.url => {}
      Some(o) => {
        return Err(Failure::new(
          format!(
            "{} and {} both want {}, for different addresses",
            o.whose,
            t.whose,
            path.display()
          ),
          "give one of them a qr: path of its own",
        ))
      }
      None => out.push(Target { path, ..t }),
    }
  }
  Ok(out)
}

/// The text of the file `qr` writes for one target: the stamp, then the
/// renderer's `<svg>` element.
///
/// **NO XML DECLARATION.** XML allows one only at the very start of a file,
/// and the stamp must come first for the build to read it. The file is inlined
/// into the reel's HTML, where a declaration means nothing.
///
/// **THE CRATE'S DEFAULTS, ON PURPOSE.** Error correction M; the smallest
/// version that holds the address; a four-module quiet zone inside the symbol,
/// because the player's plate adds no padding of its own; and dark modules on
/// a white ground, so a QR keeps its contrast whatever a theme makes the plate
/// behind it.
pub fn render(t: &Target) -> Result<String, Failure> {
  // The stamp is a comment, and the reader ends it at the first `-->`. An
  // address holding one would read back as another address, and the build
  // would call a fresh QR stale.
  if t.url.contains("-->") {
    return Err(Failure::new(
      format!(
        "{}: the address holds '-->', which would end its stamp early: {}",
        t.whose, t.url
      ),
      "percent-encode the > as %3E, as a URL carries it anyway",
    ));
  }
  let code = QrCode::new(t.url.as_bytes()).map_err(|e| {
    Failure::new(
      format!(
        "{}: no QR code can hold this address ({e}, {} bytes): {}",
        t.whose,
        t.url.len(),
        t.url
      ),
      "shorten the address, eg with a short link its site serves",
    )
  })?;
  let drawn = code.render::<svg::Color>().build();
  let Some(at) = drawn.find("<svg") else {
    return Err(Failure::new(
      format!("{}: the QR renderer gave no <svg> element", t.whose),
      "this is a defect in showreel: report it with the address",
    ));
  };
  Ok(format!("<!--{QR_STAMP}{}-->\n{}\n", t.url, &drawn[at..]))
}

/// What a file already at a target says of itself, read as the build reads it.
pub fn kept(text: &str, url: &str) -> Kept {
  match stamped_for(text) {
    Some(was) if was == url => Kept::Matches,
    Some(was) => Kept::Was(was),
    None => Kept::Unstamped,
  }
}

/// One line of the report, without the `showreel: ` its printer adds.
pub fn describe(reel: &Path, t: &Target, done: &Done) -> String {
  let at = t
    .path
    .strip_prefix(reel)
    .unwrap_or(t.path.as_path())
    .display();
  match done {
    Done::Wrote => format!("wrote {at} for {}", t.url),
    Done::Kept(Kept::Matches) => format!("kept {at}: its stamp matches {}", t.url),
    Done::Kept(Kept::Was(was)) => format!(
      "kept {at}: it was generated for {was}, but the config now says {}; --force regenerates it",
      t.url
    ),
    Done::Kept(Kept::Unstamped) => format!(
      "kept {at}: it carries no '{QR_STAMP}' stamp, so nothing can say whether it matches {}; --force regenerates it",
      t.url
    ),
    Done::Kept(Kept::Unreadable(why)) => {
      format!("kept {at}: it {UNREADABLE} ({why}); --force regenerates it")
    }
  }
}

/// `showreel qr <dir>`: write each target's QR, or keep the file that is
/// there.
///
/// Everything that can refuse is done before the first write: the config, the
/// targets and every render. A file in the way that cannot be read is kept and
/// said, as the build says it, rather than refused.
pub fn run(path: &Path, force: bool) -> Result<Report, Failure> {
  let (dir, cfg) = build::read_config(path)?;
  let reel = std::path::absolute(&dir)
    .map(|d| plan::tidy(&d))
    .map_err(|e| {
      Failure::new(
        format!("cannot resolve {}: {e}", dir.display()),
        "point showreel at a reel directory, or at its parent",
      )
    })?;

  let mut decided = Vec::new();
  for t in targets(&reel, &cfg)? {
    let text = render(&t)?;
    let keep = if force { None } else { found(&t) };
    decided.push((t, text, keep));
  }

  let mut done = Vec::new();
  for (t, text, keep) in decided {
    let did = match keep {
      Some(k) => Done::Kept(k),
      None => {
        write(&t.path, &text)?;
        Done::Wrote
      }
    };
    done.push((t, did));
  }
  Ok(Report { reel, done })
}

/// What a file already at a target says of itself, or `None` when nothing is
/// there and its QR is to be written.
fn found(t: &Target) -> Option<Kept> {
  match std::fs::read_to_string(&t.path) {
    Ok(text) => Some(kept(&text, &t.url)),
    Err(e) if e.kind() == std::io::ErrorKind::NotFound => None,
    Err(e) => Some(Kept::Unreadable(e.to_string())),
  }
}

/// Write one QR whole: to a temporary file beside it, then a rename, so a
/// build never reads half of one.
fn write(path: &Path, text: &str) -> Result<(), Failure> {
  let (Some(dir), Some(name)) = (path.parent(), path.file_name()) else {
    return Err(Failure::new(
      format!("cannot write a QR at {}: it names no file", path.display()),
      "give the entry a qr: path that names an .svg file",
    ));
  };
  std::fs::create_dir_all(dir).map_err(|e| {
    Failure::new(
      format!("cannot create {}: {e}", dir.display()),
      "make the reel directory writable",
    )
  })?;
  let tmp = dir.join(format!(".{}.showreel-qr", name.to_string_lossy()));
  std::fs::write(&tmp, text)
    .and_then(|()| std::fs::rename(&tmp, path))
    .map_err(|e| failed(path, &tmp, &e))
}

/// A write that failed. The temporary file is removed, and if that fails too,
/// the refusal says where it is left.
fn failed(path: &Path, tmp: &Path, e: &std::io::Error) -> Failure {
  let left = match std::fs::remove_file(tmp) {
    Ok(()) => String::new(),
    Err(r) if r.kind() == std::io::ErrorKind::NotFound => String::new(),
    Err(r) => format!(", and {} is left behind ({r})", tmp.display()),
  };
  Failure::new(
    format!("cannot write {}: {e}{left}", path.display()),
    "make the reel's QR directory writable, and run showreel qr again",
  )
}

#[cfg(test)]
mod tests {
  use super::*;
  use crate::payload;

  fn reel(tag: &str, yaml: &str, files: &[(&str, &str)]) -> artifact::testing::TempDir {
    let d = artifact::testing::TempDir::new("showreel-qr", tag);
    std::fs::write(d.join("showreel.yaml"), yaml).unwrap();
    for (name, body) in files {
      let p = d.join(name);
      std::fs::create_dir_all(p.parent().unwrap()).unwrap();
      std::fs::write(&p, body).unwrap();
    }
    d
  }

  /// The reel's QRs, relative to it, as the report names them.
  fn names(report: &Report) -> Vec<String> {
    report
      .done
      .iter()
      .map(|(t, _)| {
        t.path
          .strip_prefix(&report.reel)
          .unwrap()
          .display()
          .to_string()
      })
      .collect()
  }

  const THREE: &str = "\
artist: {handle: x}
session: {venue_url: 'https://v.example/shop'}
socials:
  - {label: Web, handle: a, url: 'https://a.example'}
  - {label: Shop Front, handle: b, url: ' https://b.example ', qr: assets/qr/front.svg}
  - {label: Mail, handle: c}
";

  /// **THE WRITER AND THE READER TOGETHER, WHICH IS THE CONTRACT.** Every file
  /// the verb writes reads back through the build's own reader as the address
  /// it encodes, and the build's check, unchanged, then has nothing to say.
  #[test]
  fn each_qr_is_written_where_the_build_looks_and_the_build_reads_its_address_back() {
    let r = reel("roundtrip", THREE, &[]);
    let report = run(&r, false).unwrap();
    assert_eq!(
      names(&report),
      [
        "assets/qr/web.svg",
        "assets/qr/front.svg",
        "assets/qr/venue.svg"
      ],
      "socials in config order, the explicit qr: kept, then the venue"
    );
    for (t, done) in &report.done {
      assert_eq!(done, &Done::Wrote, "{}", t.whose);
      let text = std::fs::read_to_string(&t.path).unwrap();
      assert_eq!(stamped_for(&text).as_deref(), Some(t.url.as_str()));
    }
    assert_eq!(
      report.done[1].0.url, "https://b.example",
      "trimmed, as the build trims it"
    );

    let cfg = config::parse(THREE, "qr-test").unwrap();
    let (rows, warns) = payload::socials(&r, &cfg);
    assert!(warns.is_empty(), "{warns:?}");
    assert!(rows[0].qr.is_some() && rows[1].qr.is_some());
    assert!(rows[2].qr.is_none(), "no url, no QR, and that is valid");
  }

  #[test]
  fn the_file_is_the_stamp_then_one_svg_element_with_no_xml_declaration() {
    let t = Target {
      whose: "socials: Web".to_string(),
      path: PathBuf::from("/reel/assets/qr/web.svg"),
      url: "https://a.example".to_string(),
    };
    let text = render(&t).unwrap();
    assert!(
      text.starts_with("<!--showreel-qr:https://a.example-->\n<svg "),
      "{text}"
    );
    assert_eq!(text.matches("<svg").count(), 1, "{text}");
    assert!(!text.contains("<?xml"), "{text}");
    assert!(text.trim_end().ends_with("</svg>"), "{text}");
  }

  /// A `venue_url` of blanks is no address, here as in the plan: one
  /// predicate, `plan::venue_url`, answers for both.
  #[test]
  fn a_config_with_no_address_has_nothing_to_write_and_that_is_valid() {
    let r = reel(
      "none",
      "artist: {handle: x}\nsession: {venue_url: '   '}\nsocials: [{label: Mail, handle: c}]\n",
      &[],
    );
    assert!(run(&r, false).unwrap().done.is_empty());
    assert!(!r.join("assets").exists(), "nothing is made for nothing");
  }

  /// A refusal is made before the first write, so the venue's QR, which comes
  /// after the refused social, is not written either.
  #[test]
  fn a_qr_path_outside_the_reel_is_refused_and_nothing_is_written() {
    for (tag, qr) in [("climbs", "../x.svg"), ("absolute", "/x.svg")] {
      let yaml = format!(
        "artist: {{handle: x}}\nsession: {{venue_url: 'https://v.example'}}\n\
         socials: [{{label: Web, handle: a, url: 'https://a.example', qr: '{qr}'}}]\n"
      );
      let r = reel(tag, &yaml, &[]);
      let e = run(&r, false).unwrap_err();
      assert!(e.message.contains("outside the reel"), "{}", e.message);
      assert!(!r.join("assets").exists(), "{tag}: nothing was written");
    }
  }

  #[test]
  fn two_addresses_at_one_path_are_refused_naming_both() {
    let r = reel(
      "clash",
      "artist: {handle: x}\nsocials:\n\
       \x20 - {label: Web, handle: a, url: 'https://a.example'}\n\
       \x20 - {label: Shop, handle: b, url: 'https://b.example', qr: assets/qr/web.svg}\n",
      &[],
    );
    let e = run(&r, false).unwrap_err();
    assert!(
      e.message.contains("socials: Web") && e.message.contains("socials: Shop"),
      "{}",
      e.message
    );
    assert!(!r.join("assets").exists());
  }

  #[test]
  fn one_address_at_one_path_is_one_file() {
    let r = reel(
      "same",
      "artist: {handle: x}\nsession: {venue_url: 'https://v.example'}\n\
       socials: [{label: Here, handle: a, url: 'https://v.example', qr: assets/qr/venue.svg}]\n",
      &[],
    );
    assert_eq!(names(&run(&r, false).unwrap()), ["assets/qr/venue.svg"]);
  }

  #[test]
  fn an_address_holding_the_end_of_a_comment_is_refused() {
    let r = reel(
      "arrow",
      "artist: {handle: x}\nsocials: [{label: Web, handle: a, url: 'https://a.example/a-->b'}]\n",
      &[],
    );
    let e = run(&r, false).unwrap_err();
    assert!(e.message.contains("'-->'"), "{}", e.message);
    assert!(!r.join("assets").exists());
  }

  /// The length is the crate's own refusal, found by doubling, so no number of
  /// ours stands for its capacity.
  #[test]
  fn an_address_no_qr_code_can_hold_is_refused() {
    let url = std::iter::successors(Some("https://a.example/".to_string()), |u| {
      Some(u.repeat(2))
    })
    .find(|u| QrCode::new(u.as_bytes()).is_err())
    .unwrap();
    let yaml =
      format!("artist: {{handle: x}}\nsocials: [{{label: Web, handle: a, url: '{url}'}}]\n");
    let r = reel("long", &yaml, &[]);
    let e = run(&r, false).unwrap_err();
    assert!(e.message.contains("no QR code can hold"), "{}", e.message);
    assert!(!r.join("assets").exists());
  }

  /// The three states a kept file can be in, each said as the build would say
  /// it, and each file left byte for byte.
  #[test]
  fn without_force_a_file_there_is_kept_byte_for_byte_and_its_state_is_said() {
    let fresh = "<!--showreel-qr:https://a.example--><svg/>";
    let stale = "<!--showreel-qr:https://old.example--><svg/>";
    let bare = "<svg>hand drawn</svg>";
    let r = reel(
      "keep",
      "artist: {handle: x}\nsocials:\n\
       \x20 - {label: Fresh, handle: a, url: 'https://a.example'}\n\
       \x20 - {label: Stale, handle: b, url: 'https://b.example'}\n\
       \x20 - {label: Bare, handle: c, url: 'https://c.example'}\n",
      &[
        ("assets/qr/fresh.svg", fresh),
        ("assets/qr/stale.svg", stale),
        ("assets/qr/bare.svg", bare),
      ],
    );
    let report = run(&r, false).unwrap();
    let states: Vec<Done> = report.done.iter().map(|(_, d)| d.clone()).collect();
    assert_eq!(
      states,
      [
        Done::Kept(Kept::Matches),
        Done::Kept(Kept::Was("https://old.example".to_string())),
        Done::Kept(Kept::Unstamped),
      ]
    );
    for (name, body) in [("fresh", fresh), ("stale", stale), ("bare", bare)] {
      let now = std::fs::read_to_string(r.join(format!("assets/qr/{name}.svg"))).unwrap();
      assert_eq!(now, body, "{name} is kept byte for byte");
    }
    let lines: Vec<String> = report
      .done
      .iter()
      .map(|(t, d)| describe(&report.reel, t, d))
      .collect();
    assert!(!lines[0].contains("--force"), "{}", lines[0]);
    assert!(
      lines[1].contains("https://old.example") && lines[1].contains("--force"),
      "{}",
      lines[1]
    );
    assert!(
      lines[2].contains("no 'showreel-qr:' stamp") && lines[2].contains("--force"),
      "{}",
      lines[2]
    );
  }

  /// The fourth state, issue I88af1f3's: a file there that is not UTF-8 is
  /// kept as it is and said, in the words the build uses, not refused.
  #[test]
  fn a_file_there_that_cannot_be_read_as_text_is_kept_and_said() {
    let r = reel(
      "unreadable",
      "artist: {handle: x}\nsocials: [{label: Web, handle: a, url: 'https://a.example'}]\n",
      &[],
    );
    let p = r.join("assets/qr/web.svg");
    std::fs::create_dir_all(p.parent().unwrap()).unwrap();
    std::fs::write(&p, b"\xff\xfe\xfd").unwrap();
    let report = run(&r, false).unwrap();
    let (t, done) = &report.done[0];
    assert!(matches!(done, Done::Kept(Kept::Unreadable(_))), "{done:?}");
    assert_eq!(std::fs::read(&p).unwrap(), b"\xff\xfe\xfd", "kept as it is");
    let line = describe(&report.reel, t, done);
    assert!(
      line.contains("could not be read as text") && line.contains("--force"),
      "{line}"
    );
  }

  #[test]
  fn force_writes_every_target_anew() {
    let r = reel(
      "force",
      "artist: {handle: x}\nsocials: [{label: Stale, handle: b, url: 'https://b.example'}]\n",
      &[(
        "assets/qr/stale.svg",
        "<!--showreel-qr:https://old.example--><svg/>",
      )],
    );
    let report = run(&r, true).unwrap();
    assert_eq!(report.done[0].1, Done::Wrote);
    let text = std::fs::read_to_string(r.join("assets/qr/stale.svg")).unwrap();
    assert_eq!(stamped_for(&text).as_deref(), Some("https://b.example"));
    assert_eq!(
      describe(&report.reel, &report.done[0].0, &report.done[0].1),
      "wrote assets/qr/stale.svg for https://b.example"
    );
  }

  /// AT-702cceb9.4 (STb8e4fb6 acceptance.md) cites this test.
  #[test]
  fn a_written_qr_leaves_no_temporary_file_beside_it() {
    let r = reel(
      "whole",
      "artist: {handle: x}\nsocials: [{label: Web, handle: a, url: 'https://a.example'}]\n",
      &[],
    );
    run(&r, false).unwrap();
    let there: Vec<String> = std::fs::read_dir(r.join("assets/qr"))
      .unwrap()
      .map(|e| e.unwrap().file_name().to_string_lossy().into_owned())
      .collect();
    assert_eq!(there, ["web.svg"]);
  }
}
