// The dependency budgets, held by a gate rather than by discipline.
// ST0017 AC-3.14, cited as AT03.
//
// Three manifests in this workspace each carry a written dependency budget --
// prez's `comrak` and nothing else (AC02), showreel's nine (AC-3.9), and
// artifact's deliberate emptiness, which that manifest calls "a contract rather
// than a current fact". Until this file existed all three were held by two
// people being careful. **A rule obeyed by the only party who could break it is
// not the same as a rule that cannot be broken**, and the difference is
// invisible until the careful party is replaced.
//
// **ONE RULE, THREE INSTANCES.** AC-3.9 names showreel's manifest alone because
// that is the manifest it is about. The hole it describes is identical in all
// three, and a gate covering a third of the population while reading as "the
// manifest budget is enforced" is the failure this thread has recorded seven
// times: an instrument reporting something adjacent to what was needed.
//
// **THIS TEST TAKES NO DEPENDENCY, AND THAT IS A CONSTRAINT RATHER THAN A
// FLOURISH.** A TOML crate would have to enter as a dev-dependency of prez,
// whose budget is comrak and nothing else -- so the instrument enforcing AC02
// would have had to breach AC02 in order to exist. The grammar it needs is
// closed and tiny, so it is hand-rolled against std in the style the root
// manifest already documents for args and front matter.
//
// **AND IT REFUSES WHAT IT CANNOT READ.** A hand-rolled parse that silently
// skips a line it does not recognise measures a smaller population than it
// reports and passes anyway -- the fourth kind of zero, and the one this
// contract has caught most often. Every line inside a dependency table must
// parse as `name = value` or this file fails naming it, and a table whose
// header is absent is refused rather than read as empty.

use std::path::PathBuf;

/// Every manifest in the workspace, against the budget approved for it. The
/// lines are whole and exact, not keys: `image`'s defaults pull every decoder
/// in the crate (+35 against the five listed) and `qrcode`'s pull an image
/// backend the tool has no use for (+8 against +1 for svg alone), so dropping
/// `default-features = false` blows the budget while leaving the name set
/// identical. Sorted, because a reorder is cosmetic and does not need hv again;
/// any other edit does, which is what AC-3.9 says in words.
const BUDGETS: &[(&str, &[&str])] = &[
  (
    "Cargo.toml",
    &[
      r#"artifact = { path = "crates/artifact" }"#,
      r#"comrak = { version = "0.54", default-features = false }"#,
    ],
  ),
  ("crates/artifact/Cargo.toml", &[]),
  (
    "crates/showreel/Cargo.toml",
    &[
      r#"artifact = { path = "../artifact" }"#,
      r#"image = { version = "0.25", default-features = false, features = ["jpeg", "png", "webp", "gif", "tiff"] }"#,
      r#"kamadak-exif = "0.6""#,
      r#"qrcode = { version = "0.14", default-features = false, features = ["svg"] }"#,
      r#"regex = "1""#,
      r#"serde = { version = "1", features = ["derive"] }"#,
      r#"serde_json = "1""#,
      r#"serde_yaml = "0.9""#,
      r#"walkdir = "2""#,
    ],
  ),
];

/// Tables that spend the budget without being it. Nothing in this workspace has
/// one today; the budget is denominated in lockfile packages, and a crate added
/// here would spend from it while escaping a `[dependencies]`-only gate.
const FORBIDDEN_TABLES: &[&str] = &["dev-dependencies", "build-dependencies"];

fn read(rel: &str) -> String {
  let path = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join(rel);
  std::fs::read_to_string(&path)
    .unwrap_or_else(|e| panic!("the manifest gate cannot read {}: {e}", path.display()))
}

/// Runs of whitespace collapse to one space. The only edit this gate forgives.
fn normalise(line: &str) -> String {
  line.split_whitespace().collect::<Vec<_>>().join(" ")
}

/// The normalised body lines of `[want]`, or `None` when the header is absent.
///
/// **`None` and `Some(vec![])` are different answers and the distinction is
/// load-bearing.** artifact's expected set is empty, so a parse that returned an
/// empty vector for a manifest it had failed to understand would satisfy that
/// assertion without reading anything -- a tautology wearing a test's clothes.
fn table(text: &str, want: &str) -> Option<Vec<String>> {
  let header = format!("[{want}]");
  let mut found = false;
  let mut inside = false;
  let mut out = Vec::new();
  for line in text.lines() {
    let trimmed = line.trim();
    if trimmed.starts_with('[') {
      inside = trimmed == header;
      found |= inside;
      continue;
    }
    if !inside || trimmed.is_empty() || trimmed.starts_with('#') {
      continue;
    }
    out.push(normalise(trimmed));
  }
  found.then_some(out)
}

/// The dependency name a line declares, or `None` when the line is not one this
/// gate understands -- a continuation of a multi-line inline table, say. The
/// caller must treat `None` as a failure and never as a line to skip.
fn dep_name(line: &str) -> Option<&str> {
  let key = line.split_once('=')?.0.trim();
  let readable = !key.is_empty()
    && key
      .chars()
      .all(|c| c.is_ascii_alphanumeric() || c == '_' || c == '-');
  readable.then_some(key)
}

#[test]
fn every_dependency_table_matches_its_approved_budget() {
  for (rel, approved) in BUDGETS {
    let text = read(rel);
    let mut found = table(&text, "dependencies").unwrap_or_else(|| {
      panic!("{rel} has no [dependencies] table -- the gate refuses to read that as an empty budget")
    });
    for line in &found {
      assert!(
        dep_name(line).is_some(),
        "{rel}: the manifest gate cannot read this line inside [dependencies], so it \
         cannot say whether the budget holds: {line}"
      );
    }
    found.sort();
    let mut want: Vec<String> = approved.iter().map(|l| normalise(l)).collect();
    want.sort();
    assert_eq!(
      found, want,
      "{rel}: the dependency table has moved off the budget hv approved. Any change \
       here -- an addition, a removal, or an edit to a feature list -- needs hv's \
       sign-off named in the commit, and then this list."
    );
  }
}

#[test]
fn no_manifest_carries_a_dev_or_build_dependency_table() {
  for (rel, _) in BUDGETS {
    let text = read(rel);
    for forbidden in FORBIDDEN_TABLES {
      assert!(
        table(&text, forbidden).is_none(),
        "{rel} has a [{forbidden}] table. The budget is denominated in lockfile \
         packages and those spend it too, so this needs hv before it needs a gate."
      );
    }
  }
}

#[test]
fn fast_image_resize_is_refused_in_both_places_it_could_appear() {
  for (rel, _) in BUDGETS {
    let text = read(rel);
    let lines = table(&text, "dependencies").unwrap_or_default();
    let named = lines.iter().filter_map(|l| dep_name(l)).any(|n| n == "fast_image_resize");
    assert!(
      !named,
      "{rel} depends on fast_image_resize, which AC-3.9 refuses: image carries \
       FilterType::Lanczos3 and nothing has measured a need."
    );
  }
  let lock = read("Cargo.lock");
  assert!(
    !lock.contains(r#"name = "fast_image_resize""#),
    "Cargo.lock carries fast_image_resize. It is named in showreel's manifest as \
     prose recording the refusal; a lock entry means something linked it."
  );
}

// ---- The gate's own soundness, proved here rather than by hand ----
//
// The three tests above are green today because the manifests are correct today,
// which is exactly the green that proves nothing. These two prove the parse
// REFUSES, so the greens above are detector greens and not census greens.

#[test]
fn a_missing_table_is_not_an_empty_one() {
  let no_header = "[package]\nname = \"x\"\n";
  let empty_table = "[package]\nname = \"x\"\n\n[dependencies]\n";
  assert_eq!(table(no_header, "dependencies"), None);
  assert_eq!(table(empty_table, "dependencies"), Some(vec![]));
}

#[test]
fn a_line_the_gate_cannot_read_is_refused_rather_than_skipped() {
  let multi_line = "[dependencies]\nimage = {\n  version = \"0.25\",\n}\n";
  let lines = table(multi_line, "dependencies").expect("header is present");
  let unreadable: Vec<&String> = lines.iter().filter(|l| dep_name(l).is_none()).collect();
  assert_eq!(
    unreadable,
    vec![&"}".to_string()],
    "a multi-line inline table must leave a line the parser refuses, or a crate \
     written in that form would be invisible to this gate"
  );
  assert_eq!(dep_name("= \"1\""), None, "a line with no key is not a dependency");
  assert_eq!(dep_name("serde_json = \"1\""), Some("serde_json"));
}
