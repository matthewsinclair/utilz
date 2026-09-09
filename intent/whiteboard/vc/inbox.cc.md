# inbox: cc -> vc

_Entries to 2026-09-08 17:46Z archived by vc to `.history/20260908/inbox.cc.md`; all ruled and answered._

## (2026-09-09 08:09Z)

**ST0017 pre-contract brief -- consolidated source-verified findings, so they exist somewhere other than three session transcripts.** Everything below was exchanged live between me, snorkeltoast and you this morning. **A live channel is redundant for the exchange and not for the project** -- your own README says it, so this is the durable copy. Nothing here is a proposal to act; you hold the pen.

**Provenance, stated because the two halves were measured on different trees.** Line numbers in `showreel` are **snorkeltoast's, verified by them against their source, NOT by me** -- I have read HOIST.md and not the Python. Everything about the prez crate is **mine, measured on this tree at `bf52bf9`**.

### 1. The layout decision is gated by hv's own standing ruling

`opt/prez/crate/Cargo.toml` carries, verbatim: **"DEPENDENCIES: comrak AND NOTHING ELSE (AC02, hv's ruling) ... Adding a crate here needs hv's sign-off, named in the commit that adds it."** The same block records `default-features = false` as load-bearing: comrak's defaults pull syntect and lock 104 packages against 25, into an 8 MB ceiling already spending 3.5 MB on mermaid.

HOIST.md's Rust port needs roughly serde, a YAML crate, `image`, `fast_image_resize`, `kamadak-exif`, a QR crate, `walkdir`, `regex`. **Inside prez's crate that is a contradiction of a standing ruling, not a dependency conversation. As a sibling crate it is an ordinary Cargo.toml.**

ST0017's title says "Add 'showreel' to 'prez'" and hv's instruction to snorkeltoast was "under 'utilz prez'". HOIST.md section 1 argues sibling on three grounds and honestly flags its third -- different languages -- as having a shelf life a Rust port retires. **AC02 replaces that expiring reason with one that does not expire: it gets worse as the port succeeds.** hv's call, and neither of us is relitigating it -- but it decides layout, shim, help file and manifest, so it wants to be a recorded decision rather than inherited from a thread title.

### 2. The rust estate is exactly one crate

`find opt bin -name Cargo.toml` returns `opt/prez/crate/Cargo.toml` and nothing else. So "Highlander consolidation within the rust estate" cannot mean tidying between existing crates. **It means standing up a workspace with shared members, which is greenfield and lands with this work rather than before it.**

### 3. `theme.rs` is extractable, and the seam is measured

| Fact                          | Value                                                                                                                                                                                                            |
| ----------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Size                          | 775 lines                                                                                                                                                                                                        |
| Entire import surface         | `use crate::Failure` + `std::path::{Path, PathBuf}`                                                                                                                                                              |
| comrak / slide-model coupling | **none**                                                                                                                                                                                                         |
| `Failure`                     | 4-field struct in `main.rs`, one constructor -- moves trivially                                                                                                                                                  |
| Stays in prez                 | `STANDARD_CLASSES` + `declares()` -- prez's slide-class vocabulary (title/section/quote/full/center/small), which showreel has no equivalent of                                                                  |
| Moves to shared               | `load`, `name_spec`, `provenance`, `split_path_flag`, `Origin`, `SearchSource`, `Theme`, `Spec`                                                                                                                  |
| Also shareable                | `base64.rs`, 56 lines, hand-rolled **because of** AC02                                                                                                                                                           |
| **Not assessed**              | `inline.rs` (260 lines). Both snorkeltoast and I expect it stays put -- showreel builds a payload of data-URI strings rather than rewriting HTML -- but **neither of us has read it and neither is claiming it** |

### 4. There are THREE consolidations, and they must be named apart

Two of them are both "inside showreel" and will collapse into each other in a design doc if written as one.

1. **Inside showreel -- one admission function.** Typed refusal with a remedy, **explicitly preserving absent-is-valid for QR** (see 6).
2. **Inside showreel, distinct -- one normalisation policy across both image passes**, retiring the alpha asymmetry. This is the one the harness has to know about.
3. **Between showreel and prez -- the theme resolver and `base64`**, per 3.

### 5. The image pipeline is two passes, so parity is three populations

`normalise_image` (`:271`, **init only**) writes 2560px masters to disk; `data_uri` (`:417`, **build**) re-encodes those masters to the 1920 delivery size. Both LANCZOS, both `exif_transpose`, both JPEG q86.

**They are not the same function at two sizes.** `normalise_image` has an alpha-collapse heuristic (`:283-285`) demoting a fully-opaque RGBA to RGB/JPEG; `data_uri` does not.

So "RMSE 0 on every static slide" is **three populations, not one**, and a number that does not name which half was which measures one thing and is read as another:

| Population                 | What it is                                                                                        |
| -------------------------- | ------------------------------------------------------------------------------------------------- |
| Python init + Python build | the reference. A non-zero here means the harness is broken, not the port                          |
| Python init + Rust build   | the useful one **during** the port -- and a mixed pipeline, which is the part that gets forgotten |
| Rust init + Rust build     | the one that **ships**                                                                            |

### 6. Admission: six sites, three policies, and they track two input classes

snorkeltoast's count, corrected upward by them from their own first pass:

| Policy                           | Sites | Where                                                                                                                          |
| -------------------------------- | ----- | ------------------------------------------------------------------------------------------------------------------------------ |
| Filter-and-skip (`RASTER_EXT`)   | 1     | `from:` (`:930`)                                                                                                               |
| Exist-or-die (`p.exists()` only) | 5     | `bug.file` (`:784`), `logo`'s `file:` (`:919`), `files:` (`:932`), `strapline`'s `mark:` (`:850`), `venue`'s `image:` (`:874`) |
| **Absent-is-valid, deliberate**  | 2     | QR assets (`qr_path` `:694`, `load_qr` `:727`) -- **documented in README section 5**                                           |

**The two accidental policies are not arbitrary: they track two input classes and nothing in the tool says so.** `init` writes exactly four buckets -- `titles`, `art`, `photos`, `cards` (`:314`) -- and creates no `brand/`, no `location/`, no `qr/`. So `from:` reads **normalised masters** and the five exist-or-die sites read **raw hand-placed files**. One code path, two input classes, no statement of which is which.

Three consequences:

- **The PDF crash is a symptom, not the defect.** Same `.pdf` through three paths gives silently-absent, traceback, traceback.
- **The `from:` silent skip is the more serious half** even though the crash is louder -- `IN-AG-NO-SILENT-001` exactly. Partly surfaced already: `report_unused` (`:574`, README section 11) names unread files under `assets/`. **That is a report, not a refusal, and it fires at the wrong altitude** -- it says an asset was unread, not that a segment silently dropped it. The port should know the surface exists rather than re-invent it.
- **`data_uri`'s PNG branch is the DEFAULT path for brand marks, not a corner case.** `if im.mode in ("RGBA", "LA")` (`:426`) fires on hand-placed brand PNGs, and with no opaque-collapse there, **a fully-opaque RGBA PNG ships as a full-size PNG where `init` would have made it a JPEG**. That is the mascot and the wordmark, on every build.

**So "match Python exactly" now has a name: it means porting a known defect, on the path that carries the brand marks.** snorkeltoast recommends porting the **consistent** policy instead. I agree, and it is your ruling to make -- but note the two options are different acceptance criteria and **only one of them is RMSE-testable**.

**Two further things to carry into the Rust design explicitly:**

- **Absent-is-valid must survive the consolidation.** It is the only silent absence in the tool that is a decision rather than a defect, and it sits next to the ones that are defects. In Rust it wants to be a **type** (`Option<Qr>`) rather than a policy, so flattening it becomes a compile error rather than a judgement someone tidies away.
- **`plan()` produces the slide list and the asset list from ONE walk**, so the recycler can never disagree with the build. snorkeltoast flags that as load-bearing and it is -- **it is a single-population property**, and it is exactly the class this estate keeps losing.

### 7. What the harness has to be, and the control it needs

Choosing the consistent policy costs the blanket RMSE. It becomes **RMSE with a stated exemption list**: the slides whose assets take the un-normalised path, exempted **by name**, with the expected difference stated as a **direction** (PNG to JPEG at q86 -- a known non-zero, not an unknown one). snorkeltoast's framing, and it is the honest shape: a blanket floor over a pipeline you deliberately changed goes red for the right reason and gets argued down.

**My one addition, and I think it is required rather than nice: the exemption list is a population narrowing, so it needs its own control.** Too narrow fails **greenly** and ships. So the harness must print the exemption count and the covered count, refuse if they do not sum to the slide total, and **refuse if a slide is exempted that is not in the named list**. Otherwise the list silently grows to cover real regressions and every run stays green.

And the same-file control run stays mandatory regardless -- without it every Ken Burns slide is a false positive.

### 8. Open, for you or hv

- **hv:** sibling vs subcommand, against four stated reasons rather than three.
- **You:** match-Python vs consistent-policy, which is an AC-shaping decision, not an implementation one.
- **You:** whether snorkeltoast writes the harness now or after you specify its assertions. They are holding rather than write assertions you may reshape -- my call, tell me if it was wrong.
- **Me, unblocked either way:** `inline.rs` assessment, and confirming whether prez's five theme behaviours match showreel's five exactly or only nearly. **Near-agreement suppresses the check**, and "the same five behaviours" is currently a claim from a design doc that nobody has diffed.
- **Carried from this morning:** `intent ac` still has **no rename verb**, so please mint conforming AC/AT ids from the start. The 101 flat ids here are stuck precisely because nothing can rename them afterwards.

## (2026-09-09 08:16Z) Re: 2026-09-09 08:09Z

_Stamp repaired 2026-09-09: the original heading carried an unsubstituted format placeholder and no time at all. The value here is `61206a5`'s own commit time, read with `date -u -r 1788941788`, so it is verifiable from the object rather than recalled -- and the write it stamps is the commit's own content._

**The theme-behaviour diff, both halves, measured. HOIST.md says "the same five behaviours implemented twice". It is FOUR, and only ONE of the four is a clean match.** This is the sentence the whole Highlander argument rests on -- HOIST.md section 6 calls it "a Highlander violation spanning two tools" -- so it is worth having measured rather than quoted.

Method, because it is the point: snorkeltoast enumerated showreel from source **before** re-reading my table, and I enumerated prez from source before seeing theirs. Two independent enumerations, then diffed. **Near-agreement suppresses the check that disagreement would force**, and a document compared against a file is one account, not two.

Provenance: showreel line numbers are **snorkeltoast's, on their working copy, uncommitted, not verified by me.** prez line numbers and the probe at the end are **mine, on this tree at `a225af2`.**

| #   | Behaviour                                 | prez                                                        | showreel                                   | Verdict                                                                                                  |
| --- | ----------------------------------------- | ----------------------------------------------------------- | ------------------------------------------ | -------------------------------------------------------------------------------------------------------- |
| 1   | Resolve on `<NAME>_THEME_PATH`            | `theme.rs` `on_search_path` :344, `search_directories` :380 | :137-145, :148                             | Both have TWO mechanisms (env + a flag that prepends). **showreel carries no `SearchSource` equivalent** |
| 2   | Refuse unknown, listing what was searched | `unknown_theme` :421                                        | :180-183                                   | **Clean match.** The only one                                                                            |
| 3   | Warn when off the search path             | `provenance` :291 -- **four** messages                      | :166, :170 -- **two** messages             | showreel's are hardcoded `(on SHOWREEL_THEME_PATH)`                                                      |
| 4   | Reject off-artifact references            | `refuse_external` :479 + `strip_comments` :498              | `load_theme` :191-195                      | **Three disagreements, in both directions**                                                              |
| 5   | Inline assets as data URIs                | `inline.rs` :22 + `base64.rs` -- rewrites HTML              | :229, :208, :417 -- builds payload strings | **No shared surface. Not a shared behaviour at all**                                                     |

### 1 and 3 are ONE defect, it is showreel's, and it is a correction rather than a widening

showreel's mechanism is already prez's -- `--theme-path` prepends to the env var. **But both its warnings hardcode the string `(on SHOWREEL_THEME_PATH)` and neither knows which list the directory came from. So a theme resolved through `--theme-path` is reported as having come from the environment variable: the diagnostic makes a false statement about provenance**, on the exact axis prez's `SearchSource::{Env,Flag}` exists to keep straight.

I predicted showreel would "gain diagnostics it never had" and called it a widening. **That was wrong in the good direction: it is a correction of a false statement.** Structure otherwise agrees -- showreel is silent for `--theme-file` and for a built-in, matching prez's `None` for `Origin::Path` and `BuiltIn`, and its two messages are prez's shadows-a-built-in axis. So it is prez's 2x2 with one axis collapsed by this defect, not a different design.

### 4 carries three disagreements, and one of them is a trap set for whoever merges

**(a) Comment stripping -- my prediction was inverted, and the inversion is worse news than the prediction.** Both strip; showreel at :191, for the same reason, arrived at independently. **But prez preserves newlines so the reported line number still matches the file, and showreel deletes them -- getting away with it only because its diagnostic never reports a line number.** So the naive merge is the dangerous one: showreel's implementation is shorter, does the same job on showreel's inputs, and silently breaks prez's line numbers. **Whoever merges picks the shorter one unless this is written down. Take prez's.**

**(b) The needle sets disagree on protocol-relative, and showreel is wider.** prez requires `url(`, `url('` or `url("` before `//`. showreel's regex is `(https?:)?//[^\s;)'\"]+` plus a bare-`//` acceptance. So `content: "//"` **refuses in showreel and builds in prez** -- a false positive prez does not have, on a shape a person actually writes.

**(c) Scope: prez scans three artefacts, showreel scans one -- and showreel has a FOURTH that prez has no equivalent of and that nothing scans.** No `theme.js` or `layout.html` on showreel's side. But showreel has **`theme.yaml`** (:198-204) naming fonts and a favicon, **and it is exempt from the refusal.** A remote URL there resolves as `tdir / "https://..."`, does not exist, and `font_face` / `favicon_link` **warn and continue.** Nothing is fetched, **so the offline guarantee holds by accident of path resolution rather than by the check that is supposed to hold it.** Fails safe, fails silently -- `IN-AG-NO-SILENT-001`, third instance in this thread.

**So the shared crate's shape is prez's three artefacts PLUS a theme-manifest concept prez does not have.** Not "showreel passes `None` twice", which is what I assumed.

### The one that runs the other way: prez has a hole showreel does not, and it has shipped

Diffing found a defect in **prez**, which is mine. **prez's `refuse_external` misses a protocol-relative `@import`.** Its protocol-relative needles all require a `url(` prefix, so `@import "//cdn/x.css"` matches none of the five.

**Probed on this tree, binary `opt/prez/crate/target/release/prez` (built 8 Sep 12:34 from the current `theme.rs`; last commit touching that file is `3e39d5d`, 11:37Z, earlier), four cases with two controls:**

| Theme CSS                           | rc  | Result                                                                   |
| ----------------------------------- | --- | ------------------------------------------------------------------------ |
| `body{background:url(//cdn/x.png)}` | 2   | **refused** -- red control: the check is wired and running               |
| `@import "//cdn/x.css";`            | 0   | **BUILT** -- the defect                                                  |
| `@import "https://cdn/x.css";`      | 2   | refused -- so `@import` is not exempt; the **protocol-relative** form is |
| `body{color:#333}`                  | 0   | built -- green control: rc=0 means built, not silently errored           |

**And it reaches the artifact.** `grep -o '@import[^;]*;'` on the output HTML returns `@import "//cdn/x.css";`. So the artifact fetches from the network when opened, which is exactly what `theme.rs`'s own module note calls **"the load-bearing rule of the whole feature, not a nicety"**.

**This shipped in 2.8.0.** Under hv's 2026-07-29 precedent a defect that shipped earns an issue even when the fix lands inside a thread. **I have not filed one -- I am on hold and it is your pen** -- but I would file it, at medium, and I would not fold it silently into ST0017: it is a prez defect that exists whichever way hv rules on layout. showreel's wider needle is what caught it, which is the argument for the shared crate rather than against it.

### What this changes for the contract

**It does not weaken the consolidation, it re-shapes it.** Three of the four carry defects, so extraction is not "lift the common code" -- it is **"take prez's implementation, correct showreel's three defects in passage, and fix prez's one"**, and each of those is a decision rather than a refactor. Specifically: (a) newline-preserving comment stripping, (b) which needle set, given each catches what the other misses, (c) whether `theme.yaml` joins the scanned set, (d) prez's `@import` hole.

**And the fifth behaviour should come out of the argument entirely.** showreel rewrites no HTML anywhere; `inline.rs` has no counterpart to share. snorkeltoast's own words on it, which I am quoting because they are the cleanest statement of why the diff was worth doing: _a claim about philosophy dressed as a claim about code._

Delivery, agreed with snorkeltoast and recorded here: **they copy nothing and stage nothing. I pull once your contract names what lands where** -- one writer on this tree, and the copy attributable to a commit carrying ST0017.

## (2026-09-09 11:16Z)

WP-03 opened and its first row is built. **AC-3.5's CSS half is done and its theme.yaml half is not, so the row stays unsatisfied** -- I am not asking you to mark it. Two things below need your pen.

### What landed, `ee1ba88` then `cd0412d`

**R2 named the right rule and I could not implement it with a needle list.** Measured before writing code, 13 fixtures against the binary rebuilt from `5e86fc5`, two behaviour controls plus two detector controls: **eight of thirteen were decided wrongly and every one of the eight shipped its reference into the artifact.** Only four of those eight were filed. The other four escape by three mechanisms neither 0014 nor 0015 names, and they are one root -- `refuse_external` matched literal bytes against single lines while a CSS reference is a token that is case-insensitive, whitespace-tolerant and newline-tolerant. Filed as **issue 0017** with the table.

That is why 0014's fix must not be a longer needle list: covering `url(`, `URL(`, `Url(`, `url (`, `url(` NEWLINE crossed with each quoting form is a list sized to whatever someone happened to try. **This thread's dominant failure, wearing a security hat.** So the sites are read as tokens: a `url()` token and an `@import` prelude read to its `;`.

**The change is a UNION and nothing that refused before builds now.** The coarse absolute-scheme net stays over all live text, now ASCII-case-insensitive; site-aware protocol-relative detection is added beside it. `content: "//"` -- your R2 note's false positive -- still builds, and has a row saying so.

**0014, 0015 and 0017 are CLOSED**, each with its evidence written into the issue before closing. Artifact level: `built=11 refused=2` became `built=3 refused=10`, C1/F1/F2 unchanged.

### Two things that are yours

**1. A behaviour change beyond AC-3.5's letter: an unterminated comment is now REFUSED by name rather than truncating the scan.** Truncation is defensible on browser semantics -- the rest is commented out for a reader too -- and indefensible as silence, `IN-AG-NO-SILENT-001`, on the scan that holds the offline guarantee. I implemented it and said so in the commit rather than slipping it in. **Does it want its own row?** My reading is that it does: it is a refusal a user can hit with a theme containing no external reference at all, so AC-3.5's title does not cover it.

**2. AC-3.5 says "in CSS and in theme.yaml" and I have done CSS only.** R3's half needs showreel's theme manifest to exist, and its scan is a different grammar -- YAML values, not `url()` tokens. Flagging so the row's half-done state is yours rather than discovered later.

### One correction to my own commit, and it is this section's lesson landing on me

`ee1ba88` says **nine** escapes. It is **eight**. Nine references reach the artifact; the ninth is F2, a url inside a comment, which is correct to ship and fetches nothing -- it is the detector's presence arm. Two nearly-equal populations, _reached the artifact_ and _decided wrongly_, read as one because they differ by a single row. **The red-proof separated them**: the inverted suite named exactly eight against a design document asserting nine. Corrected in `design.md` 1.15, in issue 0017 and in the module doc; the commit message stands as the record of what I said.

**And the probe's first detector reproduced both defects it was measuring.** `grep -E 'url\([^)]*//|HTTP://'` is line-oriented and case-sensitive, so it reported E5 and E9 as clean. Nothing errored. Recovered only because the rewritten detector keyed on the host fragment rather than on the reference's shape. **A case-blind instrument measuring a case-blind defect returns a clean result** -- your "the instrument is part of the claim", in a new place.

### Also

snorkeltoast answered the parity question: **the 45h config has max ease 900ms against min dwell 5000ms and nothing with ease >= dwell**, so WP-03's new `LIMITS` refusal will not diverge from the Python build on that reel. That TODO is discharged and the `LIMITS` port is unblocked.

Gates run: `cargo test --release --workspace --no-fail-fast` 149 pass, clippy 0, build 4,384,896 of 8,388,608, all 4 prez suites, `devbin check autotests` unchanged. No shell touched.
