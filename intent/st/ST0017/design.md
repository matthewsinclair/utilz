# ST0017 Design: showreel under prez

Written by `vc` 2026-09-09, before any source edit. `cc` builds against this; `snorkeltoast`
authored the reference implementation and answers questions about it from the source.

**Provenance, because the findings were measured on two different trees.** Everything about the
prez crate is cc's, measured on this tree at `bf52bf9`, and re-measured by vc. Every `showreel:NNN`
line reference is snorkeltoast's, verified by them against their source; **vc has not read the
Python** and does not restate them as its own. Nothing here is ratified until its criteria are
minted -- see section 8.

---

## 1. The layout, and why it is not a compromise

**One Cargo workspace, three member crates, two binaries, one dispatching shim.**

```
opt/prez/crate/
  Cargo.toml              [workspace] -- members below, one shared lockfile
  crates/
    artifact/             THE SHARED CRATE. std only. No comrak, no image, no yaml.
                          theme resolution + base64 + data-URI inlining + the Failure vocabulary
    prez/                 the markdown pipeline. [dependencies] = comrak. UNCHANGED.
    showreel/             the reel pipeline. yaml + image + exif + qr. Its own budget.
```

`opt/prez/prez` (the shim) already resolves, builds-on-first-use and hands over. It gains one
branch: `prez showreel <...>` execs the showreel binary, everything else execs prez's.

| Constraint | How the layout meets it |
| ---------- | ----------------------- |
| AC02 -- prez depends on comrak and nothing else, hv signs off each addition by name | prez's `Cargo.toml` `[dependencies]` is not touched. showreel's budget is a NEW ruling on a NEW manifest, not an amendment to a standing one |
| The 8 MB binary ceiling, already spending 3.5 MB on mermaid | Two binaries, two budgets. `prez build` never links `image` |
| The Highlander violation spanning both tools | `artifact/` is the one implementation |
| hv's command surface: showreel lives under prez | The shim dispatches. The user types `prez showreel build <dir>` |

**Why this beats both options `HOIST.md` §1 weighed.** §1 chose sibling-with-no-sharing and
offered as its fallback *"a dispatching shim that execs this tool -- shared name, no shared code.
Do not merge the implementations."* That was the best trade available for a **Python** showreel.
Rust makes shared name AND shared code AND unmerged binaries simultaneously reachable. §1's
instruction is honoured exactly: the binaries stay separate; what merges is the duplicated
library half, which is what §6 was asking for.

**And AC02 is why the crates must not merge even though the commands do.** cc's finding, and it
is the sharpest thing said this morning: §1's third argument (different languages) was flagged by
its own author as having a shelf life a Rust port retires. **AC02 replaces it with a reason that
does not expire -- it gets worse as the port succeeds.** But it is a constraint on CRATES, not on
COMMANDS, and separating those two questions is what makes hv's ruling and §1's analysis both
satisfiable at once.

### What moves into `artifact/`, and the one seam nobody has read

| Item | Measured | Disposition |
| ---- | -------- | ----------- |
| `theme.rs` generic half -- `load`, `name_spec`, `provenance`, `split_path_flag`, `Origin`, `SearchSource`, `Theme`, `Spec` | 775 lines total; entire import surface is `crate::Failure` + `std::path`; no comrak, no slide-model coupling | MOVES |
| `theme.rs` -- `STANDARD_CLASSES` + `declares()` | encode prez's slide-class vocabulary (title/section/quote/full/center/small), which showreel has no equivalent of | STAYS in prez |
| `base64.rs` -- `encode` | 56 lines, hand-rolled **because of** AC02 | MOVES |
| `Failure` | 4-field struct in `main.rs`, one constructor | MOVES |
| `inline.rs` | 260 lines. **Neither cc nor snorkeltoast has read it, and neither is claiming it.** Both EXPECT it stays -- showreel builds a payload of data-URI strings rather than rewriting emitted HTML | **WP-01 assesses and reports before moving. Do not assume** |

**WP-01 carries one gate that is not about code moving.** `HOIST.md` §6 asserts prez and showreel
share "the same five behaviours". That is a claim from a design document that **nobody has
diffed**, and near-agreement suppresses the check that disagreement would force. So WP-01 diffs
prez's five against showreel's five and reports them as *identical* or *near*, by name. A shared
crate built on "near" silently picks one tool's semantics for both.

---

## 2. There are THREE consolidations, and they are named apart on purpose

Two of them are both "inside showreel" and collapse into each other the moment they are written
as one. cc's structuring, kept verbatim in shape because it is right.

| # | Consolidation | Where |
| - | ------------- | ----- |
| C1 | **One admission function** -- typed refusal with a remedy, preserving absent-is-valid for QR | inside showreel |
| C2 | **One normalisation policy across both image passes**, retiring the alpha asymmetry | inside showreel |
| C3 | **One theme resolver + one base64** | between showreel and prez |

C3 is the one `HOIST.md` §6 argues for and the one the thread title implies. **C1 and C2 are the
two nobody had named, and C2 is the one the fidelity harness has to know about** -- see 4.2.

---

## 3. Admission: six sites, three policies, two undeclared input classes

snorkeltoast's trace, corrected upward by them from their own first pass.

| Policy | Sites | Where |
| ------ | ----- | ----- |
| Filter-and-skip (`RASTER_EXT`) | 1 | `from:` (`:930`) |
| Exist-or-die (`p.exists()` only) | 5 | `bug.file` (`:784`), `logo`'s `file:` (`:919`), `files:` (`:932`), `strapline`'s `mark:` (`:850`), `venue`'s `image:` (`:874`) |
| **Absent-is-valid, deliberate** | 2 | QR assets (`qr_path` `:694`, `load_qr` `:727`), documented in README §5 |

**The two accidental policies are not arbitrary -- they track two input classes, and nothing in
the tool says so.** `init` writes exactly four buckets: `titles`, `art`, `photos`, `cards`
(`:314`). It creates no `brand/`, no `location/`, no `qr/`. So `from:` reads **normalised
masters** and the five exist-or-die sites read **raw hand-placed files**. One code path, two
input classes, undeclared.

Three consequences the port must carry:

- **The PDF crash is a symptom, not the defect.** The same `.pdf` through three paths gives
  silently-absent, traceback, traceback.
- **The silent skip is the more serious half even though the crash is louder.**
  `IN-AG-NO-SILENT-001`. It is partly surfaced already: `report_unused` (`:574`, README §11)
  names unread files under `assets/`. **That is a report, not a refusal, and it fires at the
  wrong altitude** -- it says an asset was unread, never that a segment silently dropped it. The
  port extends that surface rather than re-inventing it.
- **Absent-is-valid must survive the consolidation, as a TYPE.** It is the only silent absence in
  the tool that is a decision rather than a defect, and it sits directly beside ones that are
  defects. In Rust it is `Option<Qr>`, so flattening it is a compile error rather than a
  judgement someone tidies away. Where knowing a rule demonstrably does not prevent the error,
  the guard belongs in the code.

---

## 4. The fidelity contract

`HOIST.md` §6 proposes "RMSE 0 on every static slide of the 45h reel, Python as reference".
Traced against the source, that names neither one measurement nor a reachable floor, and after
the ruling in 4.2 it names the wrong instrument as well.

### 4.1 Three populations, and the convenient one is the trap

showreel resizes and re-encodes in two commands, and `build`'s input is `init`'s output:
`normalise_image` (`:271`, **init only**) writes 2560px masters; `data_uri` (`:417`, **build**)
re-encodes them to the 1920 delivery size. Both LANCZOS, both `exif_transpose`, both q86.

| # | Population | What it answers |
| - | ---------- | --------------- |
| 1 | Python init + Python build | the CONTROL. A non-zero here means the harness is broken, not the port |
| 2 | Python init + Rust build | useful **during** the port, a MIXED pipeline, and **the one that happens by accident** -- the masters are on disk and nobody re-runs `init` |
| 3 | Rust init + Rust build | the one that **ships** |

**A run of (2) reported as (3) is a green over half the pipeline that reads as a green over all
of it, and it fails in the quiet direction.** So the harness **derives its population label from
what actually ran, not from a flag someone passed, and refuses a verdict without one.** A number
without a population is not a result.

### 4.2 RULING: port the consistent policy, not the Python's asymmetry

This was put to vc as an AC-shaping decision. **Ruled: one normalisation policy across both
passes.**

The asymmetry: `normalise_image` carries an alpha-collapse heuristic (`:283-285`) demoting a
fully-opaque RGBA to RGB/JPEG; `data_uri` has no equivalent, and its PNG branch
(`if im.mode in ("RGBA","LA")`, `:426`) **is the default path for hand-placed brand marks**. So a
fully-opaque RGBA PNG ships full-size where `init` would have made it a JPEG -- **the mascot and
the wordmark, on every build.**

Why consistent wins:

- **"Match Python exactly" now has a name: it means porting a known defect, on the path that
  carries the brand marks, on every build.** That is not a fidelity requirement, it is a
  fidelity requirement's costume.
- A reference implementation is a reference, not a specification. `HOIST.md` is careful about
  encoder bytes being *"not worse, different"*; this is different **in kind**, and the two must
  not be graded by one instrument.
- A port that reproduces a bug in order to satisfy an instrument has inverted what the instrument
  is for.

**The ruling costs the blanket RMSE, and that cost is paid explicitly rather than absorbed.**

### 4.3 What the harness therefore has to be

**RMSE with a named exemption list**: the slides whose assets take the un-normalised path are
exempted **by name**, with the expected difference stated as a **direction** (PNG to JPEG at q86
-- a known non-zero, not an unknown one). A blanket floor over a pipeline you deliberately
changed goes red for the right reason and then gets argued down, which is how an instrument dies.

**An exemption list is a population narrowing, so it needs its own controls.** cc's addition, and
it is required rather than nice -- too narrow fails **greenly** and ships:

- print the exemption count AND the covered count, and **refuse if they do not sum to the slide
  total** (the sum control);
- **refuse if a slide is exempted that is not in the named list** (the membership control).

Without both, the list silently grows to cover real regressions and every run stays green.

Three further properties, none optional:

- **Structure before pixels, and separately.** Slide count, order and ids are asserted exactly
  first; **a structural mismatch fails without reporting a pixel number at all.** Comparing
  slide 7 to slide 7 means nothing if one pipeline emitted 19 where the other emitted 20, and
  reporting a pixel number invites reading a structural defect as a tolerance question.
- **The same-file control run is mandatory** regardless of everything above. Without it every Ken
  Burns slide is a false positive; with it, the audit caught a real one-shade colour regression.
  It is also what establishes the noise floor the grading floor is derived from.
- **The floor is derived and stated with its reason, and may differ per population.** Against (2)
  the masters are byte-identical inputs, so a tight floor is meaningful. Against (3) the second
  pass consumes a Rust re-encode, so error compounds across two LANCZOS passes and two JPEG
  encodes; a floor carried over from (2) would be red for reasons that are not a defect. **A
  floor of 0 is red on a correct port**, which is the fastest way to train everyone to ignore an
  instrument.

### 4.4 The instrument is red-proved before it grades anything

An injected known change must show red, and the same-file control must report the floor, **before
the harness grades a single Rust build**. This is why the harness is WP-02 and the Rust is WP-03:
an instrument built after the thing it measures gets tuned, unconsciously, to agree with what
already exists.

---

## 5. Fixed in passage, or inherited -- decided now, not during

A behaviour difference found during fidelity testing and not written down in advance gets read as
a port bug.

| Prototype behaviour | Disposition |
| ------------------- | ----------- |
| `showreel.yaml` unknown keys silently ignored (`dwel: 8s` uses the default and says nothing) | **FIXED.** Refused by name, with the valid set |
| Six admission sites, three policies, two undeclared input classes (section 3) | **FIXED via C1.** One admission function, typed refusal with a remedy |
| The `from:` silent skip | **FIXED.** A dropped segment input is reported at the segment's altitude, extending `report_unused` rather than duplicating it |
| QR absent-is-valid | **PRESERVED, as `Option<Qr>`** -- a type, not a policy |
| The alpha asymmetry between the two image passes | **FIXED via C2** -- ruled in 4.2 |
| Theme contract is a comment, not a check -- a brand token entered the brand-free shell and survived until an audit | **FIXED.** A shell-purity check over `player.html` |
| Safety floors (600ms transition, 2.5s slide, 3s ceiling) enforced in compiler AND shipped to the runtime | **PRESERVED.** `?speed=` reaches the runtime, so both ends enforce. A limit written twice in two languages is one liability -- which is why it ships in the payload rather than being reimplemented |
| `plan()` derives the slide list and the asset list from ONE walk, so the recycler can never disagree with the build | **PRESERVED, and asserted.** It is a single-population property, and it is exactly the class this estate keeps losing |
| `socials layout: list` has no consumer | **INHERITED.** A legitimate option, recorded as untested by use |
| No tests (~2,000 lines verified by rendering and looking) | **FIXED** -- WP-02 and the ATs |

---

## 6. Work packages

| WP | Scope | Depends on |
| -- | ----- | ---------- |
| 01 | Workspace + `artifact/` (C3). Extract the generic theme half, base64, `Failure`; assess `inline.rs`; **diff prez's five theme behaviours against showreel's five and report identical-or-near**. Zero behaviour change to prez | -- |
| 02 | The fidelity harness, built and red-proved against **population (1) only** | -- |
| 03 | Rust `build`: YAML, config validation with refusals, C1's admission function, C2's normalisation policy, template, data-URI, delivery re-encode. Graded against (2) | 01, 02 |
| 04 | Rust `init` and `qr`. Graded against (3) | 03 |
| 05 | Command surface: shim dispatch, `showreel.yaml` manifest, help, doctor lines, and the `help/prez.md` amendment | 03 |
| 06 | Snorkeltoast side: point the prototype at the hoisted tool, move the house theme to `design/`, keep the 45h config as the worked example | 05 |

**WP-01 is separable from showreel entirely, and that is deliberate.** If showreel slipped a
month, WP-01 would still be worth having and still green on its own acceptance.

**WP-02 before WP-03 is the non-obvious one.** See 4.4.

**WP-06 writes into another project's tree.** Announce first. Learned here 2026-07-29, when
another project's session edited this tree mid-session while it was being measured.

**Delivery, agreed between cc and snorkeltoast and recorded:** snorkeltoast copies nothing and
stages nothing; cc pulls once this contract names what lands where. One writer on this tree, and
the copy attributable to a commit carrying ST0017.

---

## 7. Out of scope

- **Video segments.** A 70 MB clip cannot be a data URI, so it breaks the single-file guarantee.
  If ever wanted, an explicit opt-in stating plainly that the output is now a directory.
- **A markdown front end.** The config is a data structure; flattening it into front matter makes
  it worse.
- **`themes/popupart/` does not move.** It carries one organisation's palette, fonts and favicon
  and arrives over `SHOWREEL_THEME_PATH`. No built-in is ever a brand.

Deferred, not refused: `HOIST.md` §4's conveniences. `--watch` and `showreel present` are real
wins and prez-symmetric, but they are not the hoist and prove none of it. **hv's call** whether
they join ST0017 or take their own thread.

---

## 8. The contract, drafted

**Provisional ids, NOT minted** -- see section 9. Ratification is the mint, and the mint is the
gate.

### Group SHARE -- the consolidation between tools (C3)

| # | Criterion |
| - | --------- |
| S1 | Theme resolution, base64 and data-URI inlining have exactly ONE implementation in the tree, linked by both binaries |
| S2 | prez's `Cargo.toml` `[dependencies]` block is byte-identical before and after WP-01 |
| S3 | The existing prez suite passes after extraction with no edit to any test file |
| S4 | prez's release binary size after WP-01 is stated as a number against the budget, not as a distance |
| S5 | prez's five theme behaviours and showreel's five are diffed and reported identical-or-near, by name, before the shared crate takes either as its semantics |

### Group FID -- the instrument

| # | Criterion |
| - | --------- |
| F1 | The harness derives its population from what ran and refuses a verdict without one |
| F2 | Slide count, order and ids are asserted exactly before any pixel comparison; a structural mismatch reports no pixel number |
| F3 | A same-file control run reports the noise floor; the grading floor is derived from it and stated with its reason |
| F4 | An injected known change shows red before the harness grades any Rust build |
| F5 | The exemption list is named, its expected difference stated as a direction, and the harness refuses when exemptions + covered do not sum to the slide total, or when a slide outside the named list is exempted |

### Group PORT -- behaviour

| # | Criterion |
| - | --------- |
| P1 | An unknown key in `showreel.yaml` is refused, named, with the valid set |
| P2 | All six admission sites route through one function: a bad input refuses with a remedy, and a dropped segment input is reported at the segment's altitude |
| P3 | QR absence remains valid and is carried as `Option`, not as a policy |
| P4 | One normalisation policy governs both image passes; no opaque RGBA ships un-collapsed |
| P5 | A theme referencing `http://`, `https://` or `//` is a build error |
| P6 | The safety floors hold in compiler and runtime, and `?speed=` cannot cross them |
| P7 | `player.html` carries no brand token |
| P8 | The slide list and the asset list come from one walk |

### Group HOIST -- the move

| # | Criterion |
| - | --------- |
| H1 | `prez showreel build <dir>` builds the 45h reel from its real config, from BOTH invocation forms (`utilz prez ...` and a direct `prez ...`) |
| H2 | `help/prez.md`'s "there is no player, and there never will be" is amended in the same commit that adds the subcommand |
| H3 | No Utilz-tree file contains the `popupart` theme; a build resolving it warns that it came from off the built-ins |
| H4 | `utilz doctor` reports showreel's external dependencies as optional lines, present because the tool is present |

---

## 9. Not ruled by vc

1. **The showreel dependency budget.** AC02's precedent: hv signs off each crate by name in the
   commit that adds it. The port needs roughly serde, a YAML crate, `image` (possibly with
   `fast_image_resize`), an EXIF crate and a QR crate. Largest single decision in the thread.
   `HOIST.md` §6 calls its own crate list *"the shape of the answer, not a verified list"* and
   asks for current state to be confirmed first.
2. **The exact command spelling** -- `prez showreel build` vs `prez reel build`. Cheap now,
   expensive after the shim, manifest and help are written against it.
3. **The grading floor's number.** vc specifies the shape; the number comes from the control run
   and accepting it is hv's.
4. **Whether `--watch` and `present` are in ST0017.**
5. **The AC/AT id format** -- see 10.
6. **Whether the published install is refreshed before this starts.** `utilz` on PATH is the
   install, 6 commits behind, 9 owned files differ. Any hoist step shelling out via PATH
   exercises a stale tree.

Two `HOIST.md` §6 decisions vc endorses, needing no ruling because both are improvements
independent of language:

- **Pre-convert theme fonts to `.woff2`.** The prototype converts TTF to WOFF2 at every build,
  which is the only reason `fontTools` and `brotli` are dependencies at all. Two dependencies
  gone, faster builds, and the theme ships the format it wants served.
- **PDF rasterisation stays an external CLI.** Every Rust PDF renderer is bindings to PDFium or
  MuPDF, which breaks the self-contained claim motivating the port, and MuPDF drags AGPL in.
  `pdftoppm` runs only in `init`, never in `build`, so the hot path is already pure.

---

## 10. The id-format blocker, measured

`intent ac` has no rename verb, so an id minted wrong is stuck. Measured on ST0017 today, the
tooling cannot say what conforming means:

- `intent ac new` **accepted all three** of `AC-HOIST-01`, `HOIST-AC-01` and `AC01`. The mint
  refuses nothing.
- The renderer then made **every one of them its own group** -- "Group AC-HOIST-01", "Group
  AC01", "Group HOIST-AC-01". `group_of` extracted no group from any form tried.

Unenforced in both directions, and not inferable from behaviour. **So the rows in section 8 are
drafted and minted only once hv or `intent-vc` names the form.**

One thing that partially defuses the blocker, also measured today: **removing rows from
`intent/.canon/st/<ID>.json` and running `intent sync --to-store` retracts them cleanly** -- no
tombstone, no `withdraw`, `intent doctor` 0 findings afterwards. That is a working retraction
path for an un-ratified row. It is **not** established as safe for a row carrying satisfaction
state or a covering AT: the sync warns that it OVERWRITES, and that case was not tested.

---

## 11. Sources

| Document | What it is |
| -------- | ---------- |
| `.../Snokeltoast/bin/showreel/README.md` | the protocol and the reasoning, 433 lines |
| `.../Snokeltoast/bin/showreel/HOIST.md` | the move and the Rust case, 251 lines |
| `.../Snokeltoast/bin/showreel/showreel` | the reference implementation, 1,046 lines |
| `.../Snokeltoast/bin/showreel/player.html` | the shell, 44 KB, unchanged by the port -- data the tool inlines |
| `opt/prez/crate/Cargo.toml` | AC02, hv's dependency ruling, and the size reasoning |
| `intent/whiteboard/vc/inbox.cc.md` (2026-09-09 08:09Z, `a225af2`) | the consolidated pre-contract brief |
