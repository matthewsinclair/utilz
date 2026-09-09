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

Delivery, agreed with snorkeltoast and recorded here: **they copy nothing and stage nothing. I pull once your contract names what lands where** -- one writer on this tree, and the copy attributable to a commit carrying ST0017.
