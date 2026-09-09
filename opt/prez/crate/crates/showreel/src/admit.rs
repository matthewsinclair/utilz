//! Admission: which files a config may read as a slide, and what becomes of the
//! ones it may not.
//!
//! **SIX SITES, ONE CLASSIFIER, AND TWO CALL SHAPES SEPARATED BY WHO ASSERTED
//! THE PATH.** That distinction is the whole design and it is not a stylistic
//! one -- it decides whether a wrong file is a refusal or a report:
//!
//! - **A path the config NAMED** (`bug.file`, `logo`'s `file:`, `strapline`'s
//!   `mark:`, `venue`'s `image:`, each entry of `files:`) is an ASSERTION by the
//!   author. Missing refuses; a type this tool cannot decode refuses. There is
//!   nothing to skip past, because somebody wrote that filename down.
//! - **A directory the config SCANNED** (`from:`) is a QUERY. It may reasonably
//!   hold a `README`, a stray export, an editor backup. Refusing the segment
//!   over one would make the feature unusable, so a non-image is DROPPED -- and
//!   **the drop is reported at the SEGMENT's altitude**, which is the half the
//!   reference does not have.
//!
//! **THE REPORT IS C1'S ACTUAL VALUE AND IT IS NOT A REFUSAL.** `report_unused`
//! already names files under `assets/` that no segment read; AC-3.2 says to
//! extend that rather than duplicate it. But it fires at the wrong altitude: it
//! says an asset went unread, never that segment `x` asked for a directory and
//! silently dropped three things out of it. **Those are different sentences and
//! only one of them tells the author where to look.**

use artifact::Failure;
use std::path::{Path, PathBuf};

/// The image spellings this tool admits.
///
/// **THIS IS THE SET THE MANIFEST ALREADY BUYS, AND SAYING SO IS WHAT STOPS THE
/// TWO DRIFTING.** `image` is compiled with exactly `jpeg, png, webp, gif,
/// tiff` (AC-3.9); these seven are those five formats plus the second spelling
/// of two of them. A decoder feature added without its spelling admits nothing
/// and looks like a broken config; a spelling added without its feature refuses
/// at DECODE instead of at admission, which is the wrong altitude again.
///
/// **`svg` IS DELIBERATELY ABSENT AND THAT IS MEASURED.** All five SVGs in the
/// live 45h reel are QR codes under `assets/qr/`, reached as TEXT and never by
/// an image site. An SVG arriving here is a mistake worth naming, not a gap to
/// helpfully fill.
pub const RASTER: &[&str] = &["png", "jpg", "jpeg", "webp", "gif", "tif", "tiff"];

/// Who named a path, and under which key.
///
/// **A REFUSAL THAT DOES NOT NAME ITS SITE SENDS THE AUTHOR THROUGH THE WHOLE
/// CONFIG.** `owner` reads as it will appear mid-sentence -- `segment 'hero'`,
/// or plain `bug`, which is the one site that belongs to no segment.
#[derive(Debug, Clone, Copy)]
pub struct Site<'a> {
  pub owner: &'a str,
  pub field: &'a str,
}

/// Why a path was NOT admitted.
///
/// **THERE IS NO `Image` VARIANT AND ITS ABSENCE IS THE POINT.** A first draft
/// had one enum covering all three outcomes, which put `Image` into the two
/// matches that render a refusal -- so both carried an arm that could only ever
/// print a falsehood about a file that was fine. A type that can represent
/// "declined because it was admissible" is a type with a lie available in it.
///
/// **`Document` IS SEPARATE FROM `Other` BECAUSE THE TWO DESERVE DIFFERENT
/// SENTENCES.** A `.pdf` is something this pipeline could plausibly carry and
/// does not yet; a `.txt` never was. Collapsing them offers a reader of the
/// first the remedy meant for the second.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Declined {
  Document,
  Other,
}

/// One file a scan declined to admit.
#[derive(Debug)]
pub struct Dropped {
  pub path: PathBuf,
  pub why: Declined,
}

/// What a `from:` directory yielded.
#[derive(Debug)]
pub struct Scan {
  pub admitted: Vec<PathBuf>,
  pub dropped: Vec<Dropped>,
}

impl Scan {
  /// One line per dropped file, for the caller to print at the segment.
  ///
  /// **EMPTY MEANS THE DIRECTORY HELD ONLY IMAGES**, which is the normal case
  /// and must stay silent -- a report that fires on every build is one nobody
  /// reads, and then the one that matters is invisible too.
  pub fn report(&self, site: Site) -> Vec<String> {
    self
      .dropped
      .iter()
      .map(|d| {
        let name = d.path.file_name().map_or_else(String::new, |n| n.to_string_lossy().into_owned());
        format!("{}: {} dropped '{name}' -- {}", site.owner, site.field, why(d.why))
      })
      .collect()
  }
}

fn why(declined: Declined) -> &'static str {
  match declined {
    Declined::Document => "a document, and this build carries no rasteriser",
    Declined::Other => "not an image this tool decodes",
  }
}

/// The lowercased extension, or empty where there is none.
fn extension(path: &Path) -> String {
  path.extension().map(|e| e.to_string_lossy().to_ascii_lowercase()).unwrap_or_default()
}

/// **THE ONE CLASSIFIER.** All six sites reach their decision through here, so a
/// new spelling is admitted in one place or in none.
///
/// `None` is admission. Returning the REASON rather than a boolean is what lets
/// the two call shapes give different answers to the same file without either
/// re-deciding what the file is.
fn classify(path: &Path) -> Option<Declined> {
  let ext = extension(path);
  if RASTER.contains(&ext.as_str()) {
    None
  } else if ext == "pdf" {
    Some(Declined::Document)
  } else {
    Some(Declined::Other)
  }
}

fn refuse(rel: &str, site: Site, declined: Declined) -> Failure {
  let remedy = match declined {
    Declined::Document => {
      "rasterise it to PNG first. A rasteriser is not in this build's dependency \
       budget and adding one needs hv's sign-off (AC-3.9)"
        .to_string()
    }
    Declined::Other => format!("one of: {}", RASTER.join(", ")),
  };
  Failure::new(format!("{}: {} '{rel}' is {}", site.owner, site.field, why(declined)), remedy)
}

/// Admit a path the config NAMED. Anything wrong with it refuses.
pub fn named(reel: &Path, rel: &str, site: Site) -> Result<PathBuf, Failure> {
  let path = reel.join(rel);
  if !path.exists() {
    return Err(Failure::new(
      format!("{}: {} '{rel}' does not exist", site.owner, site.field),
      format!("paths are relative to the reel directory: {}", reel.display()),
    ));
  }
  if !path.is_file() {
    return Err(Failure::new(
      format!("{}: {} '{rel}' is not a file", site.owner, site.field),
      "name an image file; a directory of images goes at from:",
    ));
  }
  match classify(&path) {
    None => Ok(path),
    Some(declined) => Err(refuse(rel, site, declined)),
  }
}

/// Scan a directory the config named with `from:`.
///
/// **ORDER IS SORTED AND THAT IS LOAD-BEARING, NOT TIDINESS.** A reel's slide
/// order comes from this list, and `read_dir` returns whatever order the
/// filesystem holds -- so an unsorted walk builds a DIFFERENT reel on a
/// different machine from the same config, silently. The reference sorts for
/// the same reason.
pub fn scanned(reel: &Path, rel: &str, site: Site) -> Result<Scan, Failure> {
  let dir = reel.join(rel);
  if !dir.is_dir() {
    return Err(Failure::new(
      format!("{}: {} '{rel}' is not a directory", site.owner, site.field),
      "from: names a directory of images; a single file goes at files:",
    ));
  }
  // A read that fails is never an empty directory. Collapsing the two is the
  // silence IN-AG-NO-SILENT-001 names, and it would present an unreadable
  // directory as a segment that legitimately resolved to nothing.
  let entries = std::fs::read_dir(&dir).map_err(|e| {
    Failure::new(
      format!("{}: {} cannot read {}: {e}", site.owner, site.field, dir.display()),
      "make the directory readable, or point from: elsewhere",
    )
  })?;

  let mut paths: Vec<PathBuf> = Vec::new();
  for entry in entries {
    let entry = entry.map_err(|e| {
      Failure::new(
        format!("{}: {} cannot read an entry of {}: {e}", site.owner, site.field, dir.display()),
        "make the directory readable, or point from: elsewhere",
      )
    })?;
    let path = entry.path();
    // **A HIDDEN FILE IS NOT IN THE POPULATION AND SO IS NOT REPORTED.** It is
    // hidden from the author by the same convention that hides it here, so a
    // line about `.DS_Store` on every build is noise -- and a report people
    // learn to skip past has cost exactly what it was built to buy.
    if path.file_name().is_some_and(|n| n.to_string_lossy().starts_with('.')) {
      continue;
    }
    if path.is_file() {
      paths.push(path);
    }
  }
  paths.sort();

  let mut admitted = Vec::new();
  let mut dropped = Vec::new();
  for path in paths {
    match classify(&path) {
      None => admitted.push(path),
      Some(why) => dropped.push(Dropped { path, why }),
    }
  }
  Ok(Scan { admitted, dropped })
}

#[cfg(test)]
mod tests {
  use super::*;

  fn reel(tag: &str, files: &[&str]) -> PathBuf {
    let d = std::env::temp_dir().join(format!("showreel-admit-{}-{tag}", std::process::id()));
    let _ = std::fs::remove_dir_all(&d);
    std::fs::create_dir_all(d.join("assets")).unwrap();
    for f in files {
      let p = d.join(f);
      std::fs::create_dir_all(p.parent().unwrap()).unwrap();
      std::fs::write(&p, b"x").unwrap();
    }
    d
  }

  const SEG: Site = Site { owner: "segment 'hero'", field: "files:" };
  const FROM: Site = Site { owner: "segment 'hero'", field: "from:" };

  /// **THE WHOLE DESIGN IN ONE ASSERTION: THE SAME FILE, TWO ANSWERS, AND THE
  /// DIFFERENCE IS WHO ASSERTED IT.** A `notes.txt` the author wrote down is a
  /// refusal; the identical file found by scanning a directory is a drop with a
  /// report. **Either half alone passes a test written against one call shape**,
  /// which is why they are asserted together rather than in two tests.
  #[test]
  fn a_named_path_refuses_where_a_scanned_one_is_dropped_and_reported() {
    let r = reel("both", &["assets/art/a.jpg", "assets/art/notes.txt"]);

    let e = named(&r, "assets/art/notes.txt", SEG).unwrap_err();
    assert!(e.message.contains("segment 'hero'"), "names the segment: {}", e.message);
    assert!(e.message.contains("notes.txt"), "names the file: {}", e.message);

    let scan = scanned(&r, "assets/art", FROM).unwrap();
    assert_eq!(scan.admitted.len(), 1, "the jpg is admitted");
    assert_eq!(scan.dropped.len(), 1, "and the txt is dropped, not refused");

    let lines = scan.report(FROM);
    assert_eq!(lines.len(), 1, "one line per drop");
    assert!(lines[0].contains("segment 'hero'"), "AT THE SEGMENT: {}", lines[0]);
    assert!(lines[0].contains("from:"), "and names the site: {}", lines[0]);
    assert!(lines[0].contains("notes.txt"), "and the file: {}", lines[0]);
  }

  /// **THE CLASSIFIER'S POPULATION, ENUMERATED, BOTH DIRECTIONS.** Seven
  /// spellings must admit and three must not, so a classifier that admits
  /// everything and one that admits nothing both fail.
  #[test]
  fn every_spelling_the_manifest_buys_is_admitted_and_the_rest_are_named() {
    let population: &[(&str, Option<Declined>)] = &[
      ("a.png", None),
      ("a.jpg", None),
      ("a.jpeg", None),
      ("a.webp", None),
      ("a.gif", None),
      ("a.tif", None),
      ("a.tiff", None),
      ("a.PNG", None),
      ("a.pdf", Some(Declined::Document)),
      ("a.svg", Some(Declined::Other)),
      ("a.txt", Some(Declined::Other)),
      ("noextension", Some(Declined::Other)),
    ];
    assert_eq!(population.len(), 12, "the population IS the claim");
    assert_eq!(
      population.iter().filter(|(_, d)| d.is_none()).count(),
      8,
      "seven spellings plus one proving the check is case-insensitive"
    );
    assert_eq!(RASTER.len(), 7, "and the roster itself is asserted");

    let mut wrong = Vec::new();
    for (name, want) in population {
      let got = classify(Path::new(name));
      if got != *want {
        wrong.push(format!("{name}: wanted {want:?}, got {got:?}"));
      }
    }
    assert!(wrong.is_empty(), "{} classified wrongly:\n  {}", wrong.len(), wrong.join("\n  "));
  }

  /// A `.pdf` and a `.txt` are different sentences with different remedies. The
  /// reference gave the same file three different answers depending on which
  /// path reached it; this is the one that says what to DO.
  #[test]
  fn a_document_and_a_stranger_are_not_offered_the_same_remedy() {
    let r = reel("remedies", &["a.pdf", "a.txt"]);

    let pdf = named(&r, "a.pdf", SEG).unwrap_err();
    assert!(pdf.message.contains("document"), "{}", pdf.message);
    let remedy = pdf.remedy.expect("a document says what to do");
    assert!(remedy.contains("rasterise"), "names the action: {remedy}");
    assert!(remedy.contains("AC-3.9"), "and why it is not automatic: {remedy}");

    let txt = named(&r, "a.txt", SEG).unwrap_err();
    let remedy = txt.remedy.expect("a stranger gets the roster");
    assert!(remedy.contains("png"), "lists what IS admitted: {remedy}");
    assert!(!remedy.contains("rasterise"), "and not the document remedy: {remedy}");
  }

  /// A missing named path refuses and says where paths are resolved FROM --
  /// the mistake is almost always the base, not the name.
  #[test]
  fn a_missing_named_path_refuses_and_names_the_base_it_resolved_against() {
    let r = reel("missing", &[]);
    let e = named(&r, "assets/art/gone.jpg", SEG).unwrap_err();
    assert!(e.message.contains("does not exist"), "{}", e.message);
    assert!(e.message.contains("gone.jpg"), "{}", e.message);
    assert!(e.remedy.unwrap().contains(&r.display().to_string()), "names the reel dir");
  }

  /// **THE TWO SHAPES REFUSE EACH OTHER'S INPUT AND EACH POINTS AT THE OTHER.**
  /// A directory at `files:` and a file at `from:` are the two ways to hold it
  /// wrong, and neither is a mystery if the refusal names the key that wants it.
  #[test]
  fn each_call_shape_refuses_the_others_input_and_points_at_it() {
    let r = reel("shapes", &["assets/art/a.jpg"]);

    let e = named(&r, "assets/art", SEG).unwrap_err();
    assert!(e.message.contains("is not a file"), "{}", e.message);
    assert!(e.remedy.unwrap().contains("from:"), "sends a directory to from:");

    let e = scanned(&r, "assets/art/a.jpg", FROM).unwrap_err();
    assert!(e.message.contains("is not a directory"), "{}", e.message);
    assert!(e.remedy.unwrap().contains("files:"), "sends a file to files:");
  }

  /// **SORTED, AND THIS IS NOT TIDINESS.** A reel's slide order comes from this
  /// list and `read_dir` returns filesystem order, so an unsorted walk builds a
  /// DIFFERENT reel from the same config on a different machine, silently.
  ///
  /// **THE LIMIT, STATED WHERE IT IS PRODUCED: THIS TEST'S DISCRIMINATING POWER
  /// IS A PROPERTY OF THE FILESYSTEM, NOT OF THE TEST.** It was red-proved by
  /// commenting out the sort and it failed -- here, on APFS, where `read_dir`
  /// returns roughly creation order and the fixture writes `c`, `a`, `b`
  /// deliberately out of order to make that bite. **On a filesystem that hands
  /// back sorted entries it would pass with the defect live**, which is a test
  /// asserting nothing while looking fine. Nothing available in std fixes that;
  /// recording it is what stops a future green being read as proof.
  #[test]
  fn a_scan_returns_its_images_in_a_stable_order() {
    let r = reel("order", &["assets/art/c.jpg", "assets/art/a.jpg", "assets/art/b.png"]);
    let names: Vec<String> = scanned(&r, "assets/art", FROM)
      .unwrap()
      .admitted
      .iter()
      .map(|p| p.file_name().unwrap().to_string_lossy().into_owned())
      .collect();
    assert_eq!(names, vec!["a.jpg", "b.png", "c.jpg"]);
  }

  /// **A HIDDEN FILE IS NEITHER ADMITTED NOR REPORTED, AND THE SECOND HALF IS
  /// THE ONE THAT MATTERS.** A line about `.DS_Store` on every build is noise,
  /// and a report people learn to skip has cost exactly what it was built to
  /// buy. A directory of nothing but images reports NOTHING.
  #[test]
  fn hidden_files_leave_the_population_and_a_clean_directory_reports_nothing() {
    let r = reel("hidden", &["assets/art/a.jpg", "assets/art/.DS_Store", "assets/art/.keep"]);
    let scan = scanned(&r, "assets/art", FROM).unwrap();
    assert_eq!(scan.admitted.len(), 1, "one real image");
    assert_eq!(scan.dropped.len(), 0, "and the dotfiles are not drops");
    assert!(scan.report(FROM).is_empty(), "so a clean directory says nothing at all");
  }

  /// A directory that resolves to no images is not this module's refusal -- the
  /// caller owns that sentence, because "resolved to no images" is a fact about
  /// the SEGMENT after `files:` and `exclude:` have also had their say.
  #[test]
  fn a_directory_of_no_images_scans_clean_and_leaves_the_verdict_to_the_caller() {
    let r = reel("empty", &["assets/art/notes.txt"]);
    let scan = scanned(&r, "assets/art", FROM).unwrap();
    assert!(scan.admitted.is_empty());
    assert_eq!(scan.dropped.len(), 1, "and it says what it dropped");
  }
}
