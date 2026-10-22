//! Where a build lands, and what it is called.
//!
//! **THE FILE IS NAMED FOR THE GIG, NOT FOR THE BUILD.** The stamp comes from
//! the SESSION date, so rebuilding three days later does not invent a second
//! identity for the same reel. `iso:` is authoritative; `date:` is display copy
//! for the crawl ("19th September") and is parsed only as a fallback, because it
//! usually carries no year and a guess deserves a warning rather than a silent
//! wrong answer.
//!
//! **NO DATE CRATE IS IN THIS CRATE'S BUDGET**, so the calendar arithmetic is
//! written out here. That is a real cost and it is a small one: the tool needs
//! to validate a `yyyy-mm-dd`, name a month, and know today's year. Adding a
//! dependency for three things would need hv's sign-off under AC-3.9, and the
//! algorithm below is standard and pinned by tests against known dates.

use crate::config;
use artifact::Failure;
use std::io::Write as _;
use std::path::{Path, PathBuf};

pub const OUTPUT_DEFAULT: &str = "{date}-{artist}-{venue}-{city}-{nnn}.showreel.html";

const MONTHS: [&str; 12] = [
  "january",
  "february",
  "march",
  "april",
  "may",
  "june",
  "july",
  "august",
  "september",
  "october",
  "november",
  "december",
];

/// Alphanumerics only, for a FILENAME FIELD.
///
/// **"Forbidden Planet" BECOMES "forbiddenplanet", NOT "forbidden-planet".** The
/// hyphen is the field separator in the output convention, so a hyphen inside a
/// field makes the name unparseable by splitting on it. This is deliberately not
/// `plan::slug`, which keeps the hyphen because it names an asset.
pub fn tight(s: &str) -> String {
  s.to_lowercase()
    .chars()
    .filter(char::is_ascii_alphanumeric)
    .collect()
}

/// Days since the Unix epoch to (year, month, day).
///
/// Howard Hinnant's `civil_from_days`, which is the standard shift-the-era
/// algorithm: move the epoch to 1 March 0000 so leap days land at the end of the
/// year, then divide by the 400-year cycle. Pinned by tests against dates whose
/// answers are known independently, including two leap days.
fn civil_from_days(days: i64) -> (i64, u32, u32) {
  let z = days + 719_468;
  let era = if z >= 0 { z } else { z - 146_096 } / 146_097;
  let doe = z - era * 146_097;
  let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146_096) / 365;
  let y = yoe + era * 400;
  let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
  let mp = (5 * doy + 2) / 153;
  let d = (doy - (153 * mp + 2) / 5 + 1) as u32;
  let m = if mp < 10 { mp + 3 } else { mp - 9 } as u32;
  (if m <= 2 { y + 1 } else { y }, m, d)
}

fn today() -> (i64, u32, u32) {
  let secs = std::time::SystemTime::now()
    .duration_since(std::time::UNIX_EPOCH)
    .map_or(0, |d| d.as_secs() as i64);
  civil_from_days(secs.div_euclid(86_400))
}

fn leap(y: i64) -> bool {
  (y % 4 == 0 && y % 100 != 0) || y % 400 == 0
}

fn days_in(y: i64, m: u32) -> u32 {
  match m {
    1 | 3 | 5 | 7 | 8 | 10 | 12 => 31,
    4 | 6 | 9 | 11 => 30,
    2 if leap(y) => 29,
    2 => 28,
    _ => 0,
  }
}

fn valid(y: i64, m: u32, d: u32) -> bool {
  (1..=12).contains(&m) && d >= 1 && d <= days_in(y, m)
}

/// Parse a strict `yyyy-mm-dd`, or `None`.
fn iso(text: &str) -> Option<(i64, u32, u32)> {
  let b = text.as_bytes();
  if b.len() != 10 || b[4] != b'-' || b[7] != b'-' {
    return None;
  }
  let y: i64 = text[0..4].parse().ok()?;
  let m: u32 = text[5..7].parse().ok()?;
  let d: u32 = text[8..10].parse().ok()?;
  valid(y, m, d).then_some((y, m, d))
}

/// The stamp a build's filename carries, and anything the operator should know.
///
/// **THE WARNINGS ARE RETURNED, NOT PRINTED.** A pure function that hands back
/// what it wants said lets the tests read them and lets the caller own the
/// stream. The reference warns to stderr from inside the computation, which is
/// the same information in a place nothing can check.
pub fn stamp(session: &config::Session) -> Result<(String, Vec<String>), Failure> {
  let mut said = Vec::new();

  if !session.iso.is_empty() {
    return match iso(&session.iso) {
      Some((y, m, d)) => Ok((format!("{y:04}{m:02}{d:02}"), said)),
      None => Err(Failure::new(
        format!("session.iso is not a date: {}", session.iso),
        "use yyyy-mm-dd",
      )),
    };
  }

  let raw = session.date.trim().to_lowercase();
  if !raw.is_empty() {
    if let Some((y, m, d)) = iso(&raw) {
      return Ok((format!("{y:04}{m:02}{d:02}"), said));
    }
    // "19th September", "19 Sep 2026" -- a day, a month name, an optional year.
    let re = regex::Regex::new(r"\b(\d{1,2})(?:st|nd|rd|th)?\s+([a-z]+)\b(?:\s+(\d{4}))?")
      .expect("a literal pattern compiles");
    if let Some(c) = re.captures(&raw) {
      let day: u32 = c[1].parse().unwrap_or(0);
      let name = &c[2];
      let month = MONTHS
        .iter()
        .position(|mo| name.len() >= 3 && mo.starts_with(&name[..3]))
        .map(|i| i as u32 + 1);
      if let Some(m) = month {
        let year = match c.get(3).and_then(|g| g.as_str().parse::<i64>().ok()) {
          Some(y) => y,
          None => {
            let y = today().0;
            said.push(format!(
              "session.date '{}' carries no year; assuming {y}. Set session.iso to be sure.",
              session.date
            ));
            y
          }
        };
        if valid(year, m, day) {
          return Ok((format!("{year:04}{m:02}{day:02}"), said));
        }
      }
    }
  }

  let (y, m, d) = today();
  said.push(
    "no usable session date; naming the file with today's date. Set session.iso: yyyy-mm-dd"
      .to_string(),
  );
  Ok((format!("{y:04}{m:02}{d:02}"), said))
}

/// A filename with the revision counter's place held open.
///
/// **THE REFERENCE USES A NUL BYTE AS A PLACEHOLDER AND THIS USES A TYPE, WHICH
/// IS THE SAME PROPERTY BY A DIFFERENT MEANS.** What made `NNN = "\x00"` good is
/// that the counter and the pruner both work off the CONFIGURED pattern rather
/// than assuming where the number sits or that the name ends in `.html`. A
/// prefix/suffix pair keeps exactly that and needs no sentinel inside a
/// formatted string.
///
/// **BOTH SHAPES ARE SUPPORTED BECAUSE THE REFERENCE SUPPORTS BOTH.**
/// `showreel:547` returns `out_dir / stem` for a pattern with no `{nnn}` -- a
/// fixed filename with no revisioning, commented as such -- so refusing it would
/// reject a working configuration.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Stem {
  /// No `{nnn}`: one fixed name, overwritten each build, never revisioned.
  Fixed(String),
  /// Exactly one `{nnn}`.
  Counted { prefix: String, suffix: String },
}

/// Every path a directory holds, or the error that stopped the read: a read
/// that fails is never an empty directory (`admit.rs`'s rule). The one listing
/// of `_out/`, for its revisions and for `video`'s sweep (issue 0098).
pub fn entries(dir: &Path) -> std::io::Result<Vec<PathBuf>> {
  std::fs::read_dir(dir)?
    .map(|entry| entry.map(|e| e.path()))
    .collect()
}

impl Stem {
  /// Whether this stem names counted revisions, the one home of that question
  /// (issue 0100): `write_next` asks it for both of its choices, the slot's
  /// check and creating fresh, and `build` asks it for what `Built` says.
  pub fn is_counted(&self) -> bool {
    matches!(self, Stem::Counted { .. })
  }

  /// Existing builds of this stem, lowest revision first.
  ///
  /// **AN `_out/` THAT CANNOT BE READ IS REFUSED, NEVER TAKEN AS EMPTY**: the
  /// next number comes from what it holds, so an empty answer would name a
  /// revision that may already be there (issue 0098).
  pub fn revisions(&self, out_dir: &Path) -> Result<Vec<(u32, PathBuf)>, Failure> {
    let Stem::Counted { prefix, suffix } = self else {
      return Ok(Vec::new());
    };
    let listed = entries(out_dir).map_err(|e| {
      Failure::new(
        format!(
          "cannot read {} for the next revision's number: {e}",
          out_dir.display()
        ),
        "make the directory readable, or name the output with --out",
      )
    })?;
    let mut found: Vec<(u32, PathBuf)> = listed
      .into_iter()
      .filter_map(|path| {
        let name = path.file_name()?.to_string_lossy().into_owned();
        let digits = name
          .strip_prefix(prefix.as_str())?
          .strip_suffix(suffix.as_str())?;
        // The reference's `(\d+)`: all digits, at least one, nothing else.
        (!digits.is_empty() && digits.bytes().all(|b| b.is_ascii_digit()))
          .then(|| digits.parse::<u32>().ok().map(|n| (n, path)))?
      })
      .collect();
    found.sort();
    Ok(found)
  }

  /// Where the next build goes.
  ///
  /// **BUILDS NEVER OVERWRITE EACH OTHER AND THE HIGHEST NUMBER IS THE CURRENT
  /// ONE**, which matters because the thing that goes on a shop television is a
  /// file somebody copied to a stick, and "which one did I copy" needs an answer
  /// that is not a timestamp.
  pub fn next(&self, out_dir: &Path) -> Result<PathBuf, Failure> {
    match self {
      Stem::Fixed(name) => Ok(out_dir.join(name)),
      Stem::Counted { prefix, suffix } => {
        let prev = self.revisions(out_dir)?.last().map_or(0, |(n, _)| *n);
        Ok(out_dir.join(format!("{prefix}{:03}{suffix}", prev + 1)))
      }
    }
  }

  /// Writes the next build where `next` names it, and says where.
  ///
  /// **A COUNTED REVISION IS CREATED, NEVER REPLACED**, so the rule above holds
  /// at the write itself: two builds of one reel at once cannot both take one
  /// number, since the second finds the first's file there and refuses (issue
  /// 0098). **AND ITS SLOT IS CHECKED WHOLE FIRST** (issue 0100): a file at
  /// either of the slot's video names refuses before anything is written,
  /// since an HTML beside another build's video would make one slot of two
  /// builds, which `prune` would then delete together. A fixed name is
  /// overwritten each build, its video too, as they always were.
  pub fn write_next(&self, out_dir: &Path, bytes: &[u8]) -> Result<PathBuf, Failure> {
    let path = self.next(out_dir)?;
    let counted = self.is_counted();
    if counted {
      for ext in VIDEO_EXTENSIONS {
        refuse_a_taken_name(&video_of(&path, ext))?;
      }
    }
    write(&path, bytes, counted)?;
    Ok(path)
  }
}

/// Writes a file that a build or a recording makes, the one writer of either.
/// A `fresh` write creates it, so a file already at its name refuses and keeps
/// its bytes; any other write replaces what is there.
pub fn write(path: &Path, bytes: &[u8], fresh: bool) -> Result<(), Failure> {
  let mut options = std::fs::OpenOptions::new();
  options.write(true);
  if fresh {
    options.create_new(true);
  } else {
    options.create(true).truncate(true);
  }
  let written = options
    .open(path)
    .and_then(|mut file| file.write_all(bytes));
  written.map_err(|e| {
    // What is known is that the file is there: a build that ran beside this
    // one, or a pattern naming a place the listing does not read, can each
    // put it there, so the words name no cause (issue 0098).
    if fresh && e.kind() == std::io::ErrorKind::AlreadyExists {
      Failure::new(
        format!(
          "cannot create {}: a file is already there, and a build never replaces one",
          path.display()
        ),
        "if another build of this reel was running, build again; if not, move that file aside",
      )
    } else {
      Failure::new(
        format!("cannot write {}: {e}", path.display()),
        "check the path",
      )
    }
  })
}

/// Build the output stem from the configured pattern.
pub fn stem(cfg: &config::Reel, session: &config::Session, date: &str) -> Result<Stem, Failure> {
  let pattern = cfg.output.as_deref().unwrap_or(OUTPUT_DEFAULT);
  let artist = if cfg.artist.handle.is_empty() {
    &cfg.artist.name
  } else {
    &cfg.artist.handle
  };
  let fields: [(&str, String); 4] = [
    ("date", date.to_string()),
    ("artist", {
      let t = tight(artist);
      if t.is_empty() {
        "artist".to_string()
      } else {
        t
      }
    }),
    ("venue", {
      let t = tight(&session.venue);
      if t.is_empty() {
        "novenue".to_string()
      } else {
        t
      }
    }),
    ("city", {
      let t = tight(&session.city);
      if t.is_empty() {
        "nocity".to_string()
      } else {
        t
      }
    }),
  ];

  let mut prefix = String::new();
  let mut suffix: Option<String> = None;
  let mut rest = pattern;
  while let Some(open) = rest.find('{') {
    let close = rest[open..].find('}').map(|i| open + i).ok_or_else(|| {
      Failure::new(
        format!("output pattern has an unclosed field: {pattern}"),
        "fields look like {date}; a literal brace is not supported",
      )
    })?;
    let name = &rest[open + 1..close];
    // Everything before the counter accumulates into the prefix; everything
    // after it into the suffix. `suffix` being Some is what says we have passed
    // the counter, so there is one piece of state rather than two.
    let head = &rest[..open];
    suffix.as_mut().unwrap_or(&mut prefix).push_str(head);

    if name == "nnn" {
      if suffix.is_some() {
        return Err(Failure::new(
          format!("output pattern uses {{nnn}} more than once: {pattern}"),
          "the revision counter appears once, or not at all for a fixed filename",
        ));
      }
      suffix = Some(String::new());
    } else {
      let value = fields
        .iter()
        .find(|(k, _)| *k == name)
        .map(|(_, v)| v.as_str())
        .ok_or_else(|| {
          Failure::new(
            format!("output pattern uses unknown field {{{name}}}"),
            "fields: artist, city, date, venue, nnn",
          )
        })?;
      suffix.as_mut().unwrap_or(&mut prefix).push_str(value);
    }
    rest = &rest[close + 1..];
  }
  match suffix {
    Some(mut tail) => {
      tail.push_str(rest);
      Ok(Stem::Counted {
        prefix,
        suffix: tail,
      })
    }
    None => {
      prefix.push_str(rest);
      Ok(Stem::Fixed(prefix))
    }
  }
}

/// The containers `showreel video` writes, by extension: `.mp4` first, which a
/// slot's video always is, and `.mov`, which `-o` may name (ST0021).
pub const VIDEO_EXTENSIONS: [&str; 2] = ["mp4", "mov"];

/// The video a revision's HTML is recorded to: its name, with `.html` swapped
/// for the container's extension. The one home of that rule, for `video`,
/// which writes it, and `slot_files`, which prunes it.
pub fn video_of(html: &Path, ext: &str) -> PathBuf {
  html.with_extension(ext)
}

/// Whether anything is at a name: its own entry, not what the entry points
/// to, so a dangling link is there too. `NotFound` is the one answer read as
/// nothing there; any other error is returned, since a look that failed is
/// never an empty name (issue 0100). The one look at a slot's names, for
/// `refuse_a_taken_name` and `slot_files`, each saying in its own words what
/// it could not check.
fn entry_at(name: &Path) -> std::io::Result<bool> {
  match std::fs::symlink_metadata(name) {
    Ok(_) => Ok(true),
    Err(e) if e.kind() == std::io::ErrorKind::NotFound => Ok(false),
    Err(e) => Err(e),
  }
}

/// Refuses a name a slot would take when anything is already at it, a
/// dangling link included, since a slot never replaces a file; and refuses a
/// name it cannot check, since an answer it could not read is never "free"
/// (issue 0100). The one check of a slot's names, for `write_next` before a
/// build writes and for `video` before it places a recording.
pub fn refuse_a_taken_name(name: &Path) -> Result<(), Failure> {
  let taken = entry_at(name).map_err(|e| {
    Failure::new(
      format!(
        "cannot check for {}, so a new build cannot take its slot: {e}",
        name.display()
      ),
      "make the directory readable and searchable",
    )
  })?;
  if taken {
    return Err(Failure::new(
      format!(
        "{} is already there, so a new build cannot take its slot",
        name.display()
      ),
      "move it aside, or name the output yourself with --out (or video's -o)",
    ));
  }
  Ok(())
}

/// Every file one revision holds: its HTML, and the video recorded from it.
///
/// **A SLOT IS ONE REVISION** (ST0021 AC-03.5). A video pruned apart from its
/// HTML, or left behind by it, is a file nothing names any more. So the video
/// is found by its own entry, not by what the entry points to: one that is a
/// dangling link goes with its HTML, and one that cannot be checked refuses
/// rather than being left behind (issue 0098).
pub fn slot_files(html: &Path) -> Result<Vec<PathBuf>, Failure> {
  let mut files = vec![html.to_path_buf()];
  for video in VIDEO_EXTENSIONS.iter().map(|ext| video_of(html, ext)) {
    let there = entry_at(&video).map_err(|e| {
      Failure::new(
        format!(
          "cannot check for {}, which goes with {}: {e}",
          video.display(),
          html.display()
        ),
        "a revision is pruned whole: make the directory readable and searchable",
      )
    })?;
    if there {
      files.push(video);
    }
  }
  Ok(files)
}

/// The size of a file. One that cannot be read is `None`, never
/// 0 bytes, and `said` gets why (issue 0096).
pub fn size_of(path: &Path, said: &mut Vec<String>) -> Option<u64> {
  match std::fs::metadata(path) {
    Ok(meta) => Some(meta.len()),
    Err(e) => {
      said.push(format!(
        "could not read the size of {}: {e}",
        path.display()
      ));
      None
    }
  }
}

/// A size as the summaries print it, in megabytes: `? MB` for one `size_of`
/// could not read.
pub fn megabytes(bytes: Option<u64>) -> String {
  bytes.map_or_else(
    || "? MB".to_string(),
    |n| format!("{:.1} MB", n as f64 / 1_048_576.0),
  )
}

/// The sizes of `paths` summed, `None` when any cannot be read, each of which
/// `said` gets from `size_of`. Every size is read before the sum, since
/// `Option`'s sum stops at the first `None` and would name only that one
/// (issues 0098 and 0099).
pub fn total_of(paths: &[PathBuf], said: &mut Vec<String>) -> Option<u64> {
  let sizes: Vec<Option<u64>> = paths.iter().map(|p| size_of(p, said)).collect();
  sizes.into_iter().sum()
}

/// Drop the oldest revisions, or say once that there are a lot of them.
///
/// **THE DEFAULT KEEPS EVERYTHING AND COMPLAINS**, because silently deleting a
/// build somebody may already have copied to a stick is a worse default than a
/// directory that needs tidying. Returns what it did and what it wants said.
/// Both count whole slots: a revision's video goes with its HTML, and its
/// megabytes are in the total. A size that cannot be read makes the total
/// unknown, never low, and is said; an `_out/` that cannot be read, or a
/// slot that cannot be checked, refuses before a path is returned, so
/// nothing is deleted (issue 0098).
pub fn prune(
  out_dir: &Path,
  stem: &Stem,
  keep: usize,
) -> Result<(Vec<PathBuf>, Vec<String>), Failure> {
  let sibs: Vec<PathBuf> = stem
    .revisions(out_dir)?
    .into_iter()
    .map(|(_, p)| p)
    .collect();
  if keep > 0 && sibs.len() > keep {
    let old = &sibs[..sibs.len() - keep];
    let said = vec![format!(
      "pruned {} older revision(s), kept {keep}",
      old.len()
    )];
    return Ok((slots(old)?, said));
  }
  if keep == 0 && sibs.len() > 5 {
    let mut unread = Vec::new();
    let total = total_of(&slots(&sibs)?, &mut unread);
    let mut said = vec![format!(
      "{} revisions of this reel in _out/ ({}). Use --keep N to drop the oldest.",
      sibs.len(),
      megabytes(total)
    )];
    said.extend(unread);
    return Ok((Vec::new(), said));
  }
  Ok((Vec::new(), Vec::new()))
}

/// Every file the given revisions hold, each slot whole, gathered before
/// anything is deleted, so a slot that cannot be checked deletes nothing.
fn slots(revisions: &[PathBuf]) -> Result<Vec<PathBuf>, Failure> {
  let mut files = Vec::new();
  for html in revisions {
    files.extend(slot_files(html)?);
  }
  Ok(files)
}

#[cfg(test)]
mod tests {
  use super::*;

  fn session(iso: &str, date: &str, venue: &str, city: &str) -> config::Session {
    config::Session {
      iso: iso.to_string(),
      date: date.to_string(),
      venue: venue.to_string(),
      city: city.to_string(),
      ..config::Session::default()
    }
  }

  fn out(tag: &str, names: &[&str]) -> artifact::testing::TempDir {
    let d = artifact::testing::TempDir::new("showreel-deliver", tag);
    for n in names {
      std::fs::write(d.join(n), b"x").unwrap();
    }
    d
  }

  /// **THE CALENDAR IS HAND-WRITTEN BECAUSE NO DATE CRATE IS IN THE BUDGET, SO
  /// IT IS PINNED AGAINST DATES WHOSE ANSWERS COME FROM OUTSIDE THIS FILE.**
  /// Both leap cases are here: 2000 is a leap year by the 400 rule and 1900 is
  /// not by the 100 rule, which is the pair a wrong implementation splits on.
  #[test]
  fn the_calendar_agrees_with_dates_whose_answers_are_known() {
    assert_eq!(civil_from_days(0), (1970, 1, 1), "the epoch");
    assert_eq!(civil_from_days(-1), (1969, 12, 31), "the day before it");
    assert_eq!(
      civil_from_days(11_016),
      (2000, 2, 29),
      "a leap day under the 400 rule"
    );
    assert_eq!(
      civil_from_days(20_715),
      (2026, 9, 19),
      "the 45h session date"
    );
    assert_eq!(
      civil_from_days(19_782),
      (2024, 2, 29),
      "and a leap day under the 4 rule"
    );
    assert!(leap(2000) && !leap(1900) && leap(2024) && !leap(2026));
    assert_eq!(days_in(2000, 2), 29);
    assert_eq!(days_in(1900, 2), 28);
  }

  #[test]
  fn iso_is_authoritative_and_a_bad_one_refuses_by_name() {
    let (d, said) = stamp(&session("2026-09-19", "19th September", "", "")).unwrap();
    assert_eq!(d, "20260919", "iso wins over the display copy");
    assert!(said.is_empty(), "and says nothing: {said:?}");

    let e = stamp(&session("19-09-2026", "", "", "")).unwrap_err();
    assert!(
      e.message.contains("session.iso is not a date"),
      "{}",
      e.message
    );
    assert!(
      e.message.contains("19-09-2026"),
      "names the value: {}",
      e.message
    );

    // A date-shaped string that is not a date. 2026 is not a leap year.
    assert!(
      stamp(&session("2026-02-29", "", "", "")).is_err(),
      "29 Feb 2026 does not exist"
    );
    assert!(
      stamp(&session("2024-02-29", "", "", "")).is_ok(),
      "but 2024 does"
    );
  }

  /// **A GUESSED YEAR WARNS RATHER THAN PASSING SILENTLY**, which is the whole
  /// reason `date:` is a fallback: it is crawl copy and usually carries no year.
  #[test]
  fn a_display_date_without_a_year_is_parsed_and_says_so() {
    let (d, said) = stamp(&session("", "19th September", "", "")).unwrap();
    assert!(d.ends_with("0919"), "day and month came from the copy: {d}");
    assert_eq!(said.len(), 1, "exactly one warning: {said:?}");
    assert!(said[0].contains("carries no year"), "{}", said[0]);

    let (d, said) = stamp(&session("", "19 Sep 2026", "", "")).unwrap();
    assert_eq!(d, "20260919", "an explicit year is taken");
    assert!(said.is_empty(), "and needs no warning: {said:?}");
  }

  #[test]
  fn no_usable_date_falls_back_to_today_and_says_so() {
    let (d, said) = stamp(&session("", "", "", "")).unwrap();
    assert_eq!(d.len(), 8, "still a stamp: {d}");
    assert_eq!(said.len(), 1);
    assert!(said[0].contains("no usable session date"), "{}", said[0]);
  }

  /// "Forbidden Planet" is one FIELD in a hyphen-separated name, so it must not
  /// contain a hyphen. This is the difference from `plan::slug`.
  #[test]
  fn tight_strips_everything_that_would_break_the_field_separator() {
    assert_eq!(tight("Forbidden Planet"), "forbiddenplanet");
    assert_eq!(tight("POP^UP^ART"), "popupart");
    assert_eq!(tight("45h"), "45h");
    assert_eq!(tight("  --  "), "");
  }

  #[test]
  fn the_default_pattern_builds_the_convention_s_name() {
    let cfg = config::parse("artist: {handle: 45h}\nsegments: []\n", "t").unwrap();
    let s = session("2026-09-19", "", "Forbidden Planet", "Nottingham");
    let stem = stem(&cfg, &s, "20260919").unwrap();
    assert_eq!(
      stem,
      Stem::Counted {
        prefix: "20260919-45h-forbiddenplanet-nottingham-".to_string(),
        suffix: ".showreel.html".to_string(),
      }
    );
    let dir = out("default", &[]);
    assert_eq!(
      stem.next(&dir).unwrap().file_name().unwrap(),
      "20260919-45h-forbiddenplanet-nottingham-001.showreel.html"
    );
  }

  #[test]
  fn an_empty_field_gets_the_reference_s_placeholder() {
    let cfg = config::parse("artist: {handle: ''}\nsegments: []\n", "t").unwrap();
    let stem = stem(&cfg, &session("", "", "", ""), "20260919").unwrap();
    let Stem::Counted { prefix, .. } = &stem else {
      panic!("counted")
    };
    assert_eq!(prefix, "20260919-artist-novenue-nocity-");
  }

  /// **A PATTERN WITH NO `{nnn}` IS A SUPPORTED CONFIGURATION, NOT AN ERROR.**
  /// `showreel:547` returns `out_dir / stem` for exactly this and says so in a
  /// comment -- a fixed filename with no revisioning. Refusing it would reject a
  /// working reel, so the rule is AT MOST one rather than exactly one.
  #[test]
  fn a_pattern_without_the_counter_is_a_fixed_name_that_never_revisions() {
    let cfg = config::parse(
      "artist: {handle: x}\noutput: reel.html\nsegments: []\n",
      "t",
    )
    .unwrap();
    let stem = stem(&cfg, &session("", "", "", ""), "20260919").unwrap();
    assert_eq!(stem, Stem::Fixed("reel.html".to_string()));

    let dir = out("fixed", &["reel.html"]);
    assert_eq!(
      stem.next(&dir).unwrap().file_name().unwrap(),
      "reel.html",
      "the same name every build"
    );
    assert!(
      stem.revisions(&dir).unwrap().is_empty(),
      "and nothing to revision or prune"
    );
    assert_eq!(prune(&dir, &stem, 1).unwrap(), (Vec::new(), Vec::new()));
  }

  /// **TWO COUNTERS ARE REFUSED, AND THIS IS WHERE THE PORT DIVERGES ON PURPOSE.**
  /// The reference's `str.replace` has no count so it fills BOTH, and its scanner
  /// regex simply grows a second capture group -- it handles the case. A
  /// prefix/suffix pair structurally cannot: the second `{nnn}` would ship
  /// literally into the filename. So the shape that buys the type its clarity is
  /// exactly the shape that cannot express this, and refusing with the pattern
  /// named is the honest price. vc's ruling, and the hazard is the port's own.
  #[test]
  fn a_pattern_with_two_counters_is_refused_with_the_pattern_named() {
    let cfg = config::parse(
      "artist: {handle: x}\noutput: '{nnn}-r-{nnn}.html'\nsegments: []\n",
      "t",
    )
    .unwrap();
    let e = stem(&cfg, &session("", "", "", ""), "20260919").unwrap_err();
    assert!(e.message.contains("more than once"), "{}", e.message);
    assert!(
      e.message.contains("{nnn}-r-{nnn}.html"),
      "names the pattern: {}",
      e.message
    );
  }

  #[test]
  fn an_unknown_field_refuses_and_lists_the_ones_that_exist() {
    let cfg = config::parse(
      "artist: {handle: x}\noutput: '{date}-{gig}.html'\nsegments: []\n",
      "t",
    )
    .unwrap();
    let e = stem(&cfg, &session("", "", "", ""), "20260919").unwrap_err();
    assert!(e.message.contains("unknown field {gig}"), "{}", e.message);
    assert!(e.remedy.unwrap().contains("venue"), "lists the valid set");
  }

  /// The counter is scoped to the exact stem, so a different reel's builds in the
  /// same directory do not advance it.
  #[test]
  fn the_counter_reads_only_its_own_stem_and_takes_the_highest() {
    let stem = Stem::Counted {
      prefix: "r-".to_string(),
      suffix: ".html".to_string(),
    };
    let dir = out(
      "counter",
      &[
        "r-001.html",
        "r-002.html",
        "r-9.html",
        "r-010.html",
        "other-003.html",
        "r-x.html",
        "r-.html",
      ],
    );
    let seen: Vec<u32> = stem
      .revisions(&dir)
      .unwrap()
      .iter()
      .map(|(n, _)| *n)
      .collect();
    // **`r-9.html` IS WHAT MAKES THIS TEST ABLE TO FAIL.** Every name here was
    // zero-padded at first, so lexical and numeric order COINCIDED and the
    // assertion passed with the sort keyed on the filename -- the injection moved
    // nothing. Unpadded, "r-9" sorts after "r-010" as text and before it as a
    // number, so the two orders disagree and only the numeric one is right.
    // `revisions` accepts any run of digits, as the reference's `(\d+)` does, so
    // such a file is a real thing to meet rather than a contrivance.
    assert_eq!(
      seen,
      vec![1, 2, 9, 10],
      "only its own, sorted numerically not lexically"
    );
    assert_eq!(
      stem.next(&dir).unwrap().file_name().unwrap(),
      "r-011.html",
      "one past the highest"
    );
  }

  /// **DELETING A BUILD SOMEBODY MAY HAVE COPIED TO A STICK IS A WORSE DEFAULT
  /// THAN A DIRECTORY THAT NEEDS TIDYING**, so the default keeps everything and
  /// complains once it gets silly.
  #[test]
  fn pruning_drops_the_oldest_only_when_asked_and_otherwise_just_says_so() {
    let stem = Stem::Counted {
      prefix: "r-".to_string(),
      suffix: ".html".to_string(),
    };
    let names: Vec<String> = (1..=7).map(|n| format!("r-{n:03}.html")).collect();
    let refs: Vec<&str> = names.iter().map(String::as_str).collect();

    let dir = out("prune-keep", &refs);
    let (dropped, said) = prune(&dir, &stem, 2).unwrap();
    assert_eq!(dropped.len(), 5, "seven minus the two kept");
    assert!(dropped
      .iter()
      .all(|p| !p.ends_with("r-006.html") && !p.ends_with("r-007.html")));
    assert!(said[0].contains("kept 2"), "{}", said[0]);

    let dir = out("prune-none", &refs);
    let (dropped, said) = prune(&dir, &stem, 0).unwrap();
    assert!(dropped.is_empty(), "the default deletes nothing");
    assert_eq!(said.len(), 1);
    assert!(said[0].contains("7 revisions"), "{}", said[0]);
  }

  /// AT33 (AC-03.5): **A SLOT IS ONE REVISION, AND ITS VIDEO GOES WITH IT.**
  /// `--keep` prunes whole slots, in `build` and in `video` alike, and the
  /// warning past five revisions counts the videos' megabytes, which dwarf the
  /// HTML's: a three-minute 1080p video is about 24 MB.
  #[test]
  fn a_pruned_slot_takes_its_video_with_it_and_the_warning_counts_video_megabytes() {
    let stem = Stem::Counted {
      prefix: "r-".to_string(),
      suffix: ".showreel.html".to_string(),
    };
    let dir = out(
      "prune-slots",
      &[
        "r-001.showreel.html",
        "r-001.showreel.mp4",
        "r-002.showreel.html",
        "r-002.showreel.mov",
        "r-003.showreel.html",
        "r-003.showreel.mp4",
      ],
    );
    let (dropped, said) = prune(&dir, &stem, 1).unwrap();
    let mut gone: Vec<String> = dropped
      .iter()
      .filter_map(|p| p.file_name())
      .map(|n| n.to_string_lossy().into_owned())
      .collect();
    gone.sort();
    assert_eq!(
      gone,
      vec![
        "r-001.showreel.html",
        "r-001.showreel.mp4",
        "r-002.showreel.html",
        "r-002.showreel.mov"
      ],
      "two whole slots, and not the one kept"
    );
    assert!(
      said[0].contains("pruned 2 older revision(s)"),
      "{}",
      said[0]
    );

    let names: Vec<String> = (1..=6).map(|n| format!("r-{n:03}.showreel.html")).collect();
    let refs: Vec<&str> = names.iter().map(String::as_str).collect();
    let dir = out("prune-slot-megabytes", &refs);
    for n in 1..=6 {
      std::fs::write(
        dir.join(format!("r-{n:03}.showreel.mp4")),
        vec![0u8; 1_048_576],
      )
      .unwrap();
    }
    let (dropped, said) = prune(&dir, &stem, 0).unwrap();
    assert!(dropped.is_empty(), "the default still deletes nothing");
    assert!(said[0].contains("6 revisions"), "{}", said[0]);
    assert!(
      said[0].contains("(6.0 MB)"),
      "the videos are counted: {}",
      said[0]
    );
  }

  /// A size that cannot be read is unknown and said, never 0 (issue 0096).
  #[test]
  fn a_size_that_cannot_be_read_is_unknown_and_said_never_0_issue_0096() {
    let dir = out("size", &["r-001.showreel.mp4"]);
    let mut said = Vec::new();
    assert_eq!(size_of(&dir.join("r-001.showreel.mp4"), &mut said), Some(1));
    assert!(
      said.is_empty(),
      "a size that was read says nothing: {said:?}"
    );

    let gone = dir.join("r-002.showreel.mp4");
    assert_eq!(size_of(&gone, &mut said), None);
    assert_eq!(said.len(), 1, "{said:?}");
    assert!(
      said[0].contains(&gone.display().to_string()),
      "the line does not name {}: {}",
      gone.display(),
      said[0]
    );
    assert_eq!(megabytes(None), "? MB");
    assert_eq!(megabytes(Some(1_572_864)), "1.5 MB");
  }

  fn counted() -> Stem {
    Stem::Counted {
      prefix: "r-".to_string(),
      suffix: ".html".to_string(),
    }
  }

  /// **AN `_out/` THAT CANNOT BE READ IS REFUSED, NEVER TAKEN AS EMPTY**
  /// (issue 0098): taken as empty, it named 001 again, over a delivered
  /// revision. A mode binds a user and not root, so where it does not bind the
  /// test fails saying so.
  #[test]
  fn an_out_dir_that_cannot_be_read_is_refused_never_empty_issue_0098() {
    use std::os::unix::fs::PermissionsExt;
    let dir = out("unread", &["r-001.html"]);
    let mode = |bits: u32| {
      std::fs::set_permissions(&*dir, std::fs::Permissions::from_mode(bits)).unwrap();
    };
    mode(0o300);
    let binds = std::fs::read_dir(&*dir).is_err();
    let listed = counted().revisions(&dir);
    let named = counted().next(&dir);
    mode(0o700);
    assert!(
      binds,
      "a mode does not stop a read here (root?), so this test cannot run"
    );
    for e in [listed.unwrap_err(), named.unwrap_err()] {
      assert!(
        e.message.contains(&dir.display().to_string()),
        "the refusal does not name {}: {}",
        dir.display(),
        e.message
      );
    }
  }

  /// **A SLOT IS PRUNED WHOLE OR NOT AT ALL** (issue 0098): a video that is a
  /// dangling link goes with its HTML, and one that cannot be checked refuses,
  /// naming it, before anything is deleted. A mode binds a user and not root,
  /// so where it does not bind the test fails saying so.
  #[test]
  fn a_slot_is_pruned_whole_or_refused_by_name_issue_0098() {
    use std::os::unix::fs::PermissionsExt;
    let dir = out("whole", &["r-001.html", "r-002.html"]);
    let video = video_of(&dir.join("r-001.html"), "mp4");
    std::os::unix::fs::symlink(dir.join("nowhere.mp4"), &video).unwrap();
    let (dropped, _) = prune(&dir, &counted(), 1).unwrap();
    assert!(
      dropped.contains(&video),
      "the dangling video was left behind: {dropped:?}"
    );

    let mode = |bits: u32| {
      std::fs::set_permissions(&*dir, std::fs::Permissions::from_mode(bits)).unwrap();
    };
    mode(0o600);
    let binds = std::fs::symlink_metadata(&video).is_err();
    let pruned = prune(&dir, &counted(), 1);
    mode(0o700);
    assert!(
      binds,
      "a mode does not stop a look here (root?), so this test cannot run"
    );
    let e = pruned.unwrap_err();
    assert!(
      e.message.contains(&video.display().to_string()),
      "the refusal does not name {}: {}",
      video.display(),
      e.message
    );
  }

  /// **A SIZE THAT CANNOT BE READ MAKES THE TOTAL UNKNOWN, NEVER LOW** (issue
  /// 0098): the warning past five revisions prints `? MB` and names every size
  /// it could not read, not only the first.
  #[test]
  fn many_revisions_with_a_size_not_read_print_an_unknown_total_issue_0098() {
    let names: Vec<String> = (1..=6).map(|n| format!("r-{n:03}.html")).collect();
    let refs: Vec<&str> = names.iter().map(String::as_str).collect();
    let dir = out("unsized", &refs);
    let videos = [
      video_of(&dir.join("r-001.html"), "mp4"),
      video_of(&dir.join("r-002.html"), "mov"),
    ];
    for video in &videos {
      std::os::unix::fs::symlink(dir.join("nowhere.mp4"), video).unwrap();
    }
    let (dropped, said) = prune(&dir, &counted(), 0).unwrap();
    assert!(dropped.is_empty(), "the default deletes nothing");
    assert!(
      said[0].contains("6 revisions") && said[0].contains("(? MB)"),
      "{said:?}"
    );
    for video in &videos {
      let named = video.display().to_string();
      assert!(
        said[1..]
          .iter()
          .any(|s| s.contains("could not read the size of") && s.contains(&named)),
        "{named} is not named: {said:?}"
      );
    }
  }

  /// **A FRESH WRITE CREATES, NEVER REPLACES** (issue 0098): one that finds a
  /// file at its name refuses, naming it, and leaves its bytes, which is what
  /// keeps two builds of one reel off one number. Any other write replaces the
  /// file whole, a longer one included.
  #[test]
  fn a_fresh_write_refuses_a_file_already_there_and_leaves_it_issue_0098() {
    let dir = out("fresh", &["r-001.html"]);
    let path = dir.join("r-001.html");
    let fresh = write(&path, b"another", true);
    assert_eq!(
      std::fs::read(&path).unwrap(),
      b"x",
      "a fresh write replaced the file"
    );
    let e = fresh.unwrap_err();
    assert!(
      e.message.contains(&path.display().to_string()),
      "the refusal does not name {}: {}",
      path.display(),
      e.message
    );
    std::fs::write(&path, b"a longer file").unwrap();
    write(&path, b"y", false).unwrap();
    assert_eq!(
      std::fs::read(&path).unwrap(),
      b"y",
      "the overwrite kept the old file's tail"
    );
  }

  /// **`write_next` ASKS FOR THE RIGHT WRITE** (issue 0098): a fixed name is
  /// overwritten each build, whole; a counted revision is created and never
  /// replaces a file, even one the listing did not count, which a prefix naming
  /// a directory below `_out/` makes here.
  #[test]
  fn write_next_overwrites_a_fixed_name_and_never_replaces_a_revision_issue_0098() {
    let dir = out("next", &[]);
    let fixed = Stem::Fixed("reel.html".to_string());
    fixed.write_next(&dir, b"a first build").unwrap();
    let path = fixed.write_next(&dir, b"second").unwrap();
    assert_eq!(
      std::fs::read(&path).unwrap(),
      b"second",
      "a fixed name was not overwritten whole"
    );

    std::fs::create_dir(dir.join("sub")).unwrap();
    let taken = dir.join("sub").join("r-001.html");
    std::fs::write(&taken, b"delivered").unwrap();
    let below = Stem::Counted {
      prefix: "sub/r-".to_string(),
      suffix: ".html".to_string(),
    };
    let refused = below.write_next(&dir, b"another");
    assert_eq!(
      std::fs::read(&taken).unwrap(),
      b"delivered",
      "a counted revision replaced a file"
    );
    let e = refused.unwrap_err();
    assert!(
      e.message.contains(&taken.display().to_string()),
      "the refusal does not name {}: {}",
      taken.display(),
      e.message
    );
  }

  /// **A TAKEN NAME IS REFUSED, AND ONE THAT CANNOT BE CHECKED IS NOT FREE**
  /// (issue 0100): a file at the name, or a dangling link, refuses, naming it,
  /// and the file keeps its bytes; a free name passes. A mode binds a user and
  /// not root, so where it does not bind the test fails saying so.
  #[test]
  fn a_taken_name_is_refused_and_one_that_cannot_be_checked_too_issue_0100() {
    use std::os::unix::fs::PermissionsExt;
    let dir = out("taken-name", &["r-001.mp4"]);
    let file = dir.join("r-001.mp4");
    let link = dir.join("r-002.mp4");
    std::os::unix::fs::symlink(dir.join("nowhere.mp4"), &link).unwrap();
    refuse_a_taken_name(&dir.join("r-003.mp4")).unwrap();
    for name in [&file, &link] {
      let e = refuse_a_taken_name(name).unwrap_err();
      assert!(
        e.message.contains(&name.display().to_string()),
        "the refusal does not name {}: {}",
        name.display(),
        e.message
      );
    }
    assert_eq!(
      std::fs::read(&file).unwrap(),
      b"x",
      "the file at the taken name was touched"
    );

    let mode = |bits: u32| {
      std::fs::set_permissions(&*dir, std::fs::Permissions::from_mode(bits)).unwrap();
    };
    mode(0o600);
    let binds = std::fs::symlink_metadata(&file).is_err();
    let checked = refuse_a_taken_name(&dir.join("r-004.mp4"));
    mode(0o700);
    assert!(
      binds,
      "a mode does not stop a look here (root?), so this test cannot run"
    );
    let unchecked = dir.join("r-004.mp4");
    let e = checked.unwrap_err();
    assert!(
      e.message.starts_with("cannot check for")
        && e.message.contains(&unchecked.display().to_string()),
      "the refusal does not name {}: {}",
      unchecked.display(),
      e.message
    );
  }

  /// **A SLOT IS CHECKED WHOLE BEFORE ANYTHING IS WRITTEN** (issue 0100): a
  /// video at the next revision's video name, whose HTML was deleted, refuses
  /// the build, naming it; no HTML is created beside it, and it keeps its
  /// bytes. Each container a slot's video may be, in a directory of its own.
  /// A fixed name beside the same video builds, overwriting as a fixed name
  /// always did: the slot's check is a counted revision's alone.
  #[test]
  fn write_next_refuses_a_slot_whose_video_name_is_taken_issue_0100() {
    for (tag, name) in [("orphan-mp4", "r-002.mp4"), ("orphan-mov", "r-002.mov")] {
      let dir = out(tag, &["r-001.html", name]);
      let orphan = dir.join(name);
      let refused = counted().write_next(&dir, b"a build");
      assert!(
        !dir.join("r-002.html").exists(),
        "an HTML was written beside {name}"
      );
      assert_eq!(std::fs::read(&orphan).unwrap(), b"x", "{name} was touched");
      let e = refused.unwrap_err();
      assert!(
        e.message.contains(&orphan.display().to_string()),
        "the refusal does not name {}: {}",
        orphan.display(),
        e.message
      );
      if let Err(e) = Stem::Fixed("r-002.html".to_string()).write_next(&dir, b"a build") {
        panic!("a fixed name beside {name} was refused: {}", e.message);
      }
    }
  }
}
