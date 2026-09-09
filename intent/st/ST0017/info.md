---
st_id: ST0017
title: Add 'showreel' to 'prez'
status: WIP
created: 2026-09-09
completed:
---

# ST0017: Add 'showreel' to 'prez'

## Objective

Hoist `showreel` -- the Snorkeltoast prototype that compiles a directory of pictures and a YAML config into one self-contained, self-advancing HTML file -- into Utilz as a subcommand of `prez`, reimplemented in Rust, and in the same move extract the logic prez and showreel already duplicate into one shared crate.

Done is four things, and the third is the one that makes this a thread rather than a copy:

1. `prez showreel build <dir>` produces an artifact from the 45h reel's real config.
2. The Rust pipeline's output is verified against the Python reference by a named instrument, per population, to a floor picked deliberately rather than assumed.
3. Theme resolution, asset inlining and base64 have ONE implementation serving both pipelines, where today they have two in two languages.
4. prez's own dependency contract (AC02: comrak and nothing else) and its binary budget are provably unchanged by any of it.

A green on 1 and 2 without 3 is a port. The thread is the consolidation.

## Context

### Where this came from

`showreel` was built in the Snorkeltoast repo on 2026-09-08 and documented the same evening in `bin/showreel/{README,HOIST}.md`. It exists because a 208-second, 70 MB, silent H.264 showreel was examined frame by frame and found to contain no motion footage at all: it was a slideshow rendered to video. Rebuilt as HTML it came to 4.6 MB, with sharper type, correct aspect handling, a typo fixable in one word, and -- because the session details live in the config and the query string -- one build that serves every venue.

The prototype is ~1,046 lines of Python plus a 44 KB player shell and a theme convention that deliberately mirrors prez's. It has no tests.

### The decision that governs the layout, and the case against it

**hv has ruled: showreel lands under `prez`, not beside it.** This is recorded here because the only written analysis argues the other way and a ruling that lives in a thread TITLE is a ruling a later reader will re-litigate.

`HOIST.md` §1 argues for a sibling `utilz showreel` on three grounds: that prez's help insists twice it is a pipeline and never a player while a showreel artifact IS a player; that the input shapes share no parser, no source format and no slide model; and that they are different languages -- a ground the document itself marks weakest and warns not to lean on, because a Rust port retires it.

Three things answer it, and none of them is "hv said so":

- **The player objection is thinner than it reads, and showreel's own README is the evidence.** It opens with prez's claim in prez's words: *"It is a pipeline, not a viewer. It writes a file and stops. The browser does the presenting."* Both tools make the identical claim about the TOOL. What differs is the ARTIFACT -- prez's is driven by a human pressing keys, showreel's drives itself -- and prez's sentence was never about the artifact.
- **A ground that does not expire replaces the one that does.** `opt/prez/crate/Cargo.toml` carries hv's AC02 ruling: comrak and nothing else, each addition signed off by hv and named in the commit. The Rust port needs serde, a YAML crate, `image`, an EXIF crate and a QR crate. Inside prez's crate that is not a trade-off, it is a contradiction of a standing ruling with an id on it, against a binary budget already carrying mermaid's 3.5 MB. So the code must not merge into prez's crate -- which is a statement about crates, not about commands.
- **Separating those two questions dissolves the argument.** `HOIST.md` §1's own fallback was *"`prez showreel` as a dispatching shim that execs this tool -- shared name, no shared code. Do not merge the implementations."* Written for a Python showreel, that was the best available trade. A Rust showreel makes shared name AND shared code AND unmerged binaries all reachable at once: a workspace, a shared crate both link, and two binaries the shim dispatches between. That is strictly better than either option §1 weighed, and it is only on the table because hv chose Rust.

**What the ruling does cost, and it is a deliverable rather than a worry.** `help/prez.md` says *"there is no player, and there never will be. Every feature request beginning 'and then prez could serve...' is answered by that sentence."* After this thread that sentence sits next to a subcommand emitting a self-advancing looping artifact. It stays literally true and no reader will parse it that finely. It is amended in the commit that adds the subcommand, or it becomes a lie by adjacency.

### The Highlander violation this thread exists to close

prez and showreel each resolve a theme on a `<NAME>_THEME_PATH`, each refuse an unknown name while listing every directory searched, each warn when a theme resolves off the search path, each reject a theme referencing anything off-artifact, and each inline assets as data URIs to guarantee the file opens with no network. **Five behaviours, implemented twice, in two languages.** It is the one defect in this system that cannot be fixed by tidying either tool on its own, and the port is what makes it fixable.

Measured 2026-09-09: the Utilz Rust estate is exactly one crate. So "consolidate the Rust estate" cannot mean tidying between existing crates -- it means standing up the workspace, and that lands with this work rather than before it.

### The fidelity problem, and why it is not one number

`HOIST.md` §6 proposes keeping the Python as the reference and requiring "RMSE 0 on every static slide of the 45h reel". Tracing the source against that sentence found it names neither one measurement nor a reachable floor.

**It is not one measurement.** showreel resizes and re-encodes in two different commands, and `build`'s input is `init`'s output: `normalise_image` (showreel:271) runs in `init` and writes 2560px masters; `data_uri` (showreel:417) runs in `build` and re-encodes those masters down to the 1920 delivery size. They are not even identical to each other -- `normalise_image` carries an alpha-collapse heuristic (:283-285) that `data_uri` lacks. So there are three populations: Python-init/Python-build (the control), Python-init/Rust-build (the convenient one, because the masters are already on disk and nobody re-runs `init`), and Rust-init/Rust-build (the one that ships). **The convenient one is a green over half the pipeline that reads as a green over all of it, and it is the one that happens by accident.**

**And the floor is unreachable as written.** `HOIST.md` says in its own risk paragraph that Pillow's LANCZOS and its q86 JPEG encoder produce specific bytes and the `image` crate will produce different ones -- not worse, different. A floor of 0 would therefore be red on a correct port, which is the fastest way to train everyone to ignore an instrument.

Both are settled in `design.md` rather than here: population is named by what ran, structure is asserted before pixels, and the floor comes from a same-file control run that establishes the noise floor instead of from a number someone liked.

### What the port fixes rather than inherits

The prototype's own README §13 names four gaps, and tracing the source found a fifth. Each one is recorded as fixed-in-passage or inherited BEFORE the port starts, because a behaviour difference discovered during fidelity testing and not written down in advance gets read as a port bug:

- **`showreel.yaml` is unvalidated.** Unknown keys are ignored, so `dwel: 8s` uses the default and says nothing -- a fallback where the rest of the tool refuses.
- **The theme contract is a comment, not a check.** A brand token entered the brand-free shell and survived until an audit.
- **One function refuses two ways.** A gallery's `from:` walk (:930) filters on `RASTER_EXT`, so a `.pdf` there is silently skipped; `files:` (:931) and `logo:`/`file:` (:918) check existence only, so a `.pdf` named there reaches Pillow and raises an uncaught traceback instead of the `die()` refusal every other bad input in that function gets.
- **No tests.** ~2,000 lines verified by rendering and looking.
- **`socials layout: list` has no consumer.** Kept as a legitimate option, untested by use.

### Sources

- `.../Snokeltoast/bin/showreel/README.md` -- the protocol and the reasoning, 433 lines.
- `.../Snokeltoast/bin/showreel/HOIST.md` -- the move and the Rust case, 251 lines.
- `.../Snokeltoast/bin/showreel/showreel` -- the reference implementation, 1,046 lines.
- The house theme `themes/popupart/` does NOT move: it carries one organisation's palette, fonts and favicon, and arrives over `SHOWREEL_THEME_PATH`. No built-in is ever a brand.

## Work Packages

| WP    | Title                                                                            | Size | Status      |
| ----- | -------------------------------------------------------------------------------- | ---- | ----------- |
| WP-01 | Workspace + artifact crate: the C3 consolidation, zero behaviour change to prez  | S    | WIP         |
| WP-02 | Fidelity harness, red-proved against population 1 (Python both sides)            | S    | WIP         |
| WP-03 | Rust build path: YAML, admission (C1), normalisation policy (C2), data-URI       | S    | WIP         |
| WP-04 | Rust init and qr paths, graded against population 3                              | S    | Not Started |
| WP-05 | Command surface: shim dispatch, manifest, help, doctor, prez help amendment      | S    | Not Started |
| WP-06 | Snorkeltoast side: point the prototype at the hoisted tool, move the house theme | S    | Not Started |

## Acceptance

Acceptance Criteria and Acceptance Tests are RENDERED into `acceptance.md`, which is a GENERATED VIEW -- a row authored there is discarded by the next sync. The contract is canon in this thread's model: change a state with the `intent ac` / `intent at` verbs, and mint or reword a row in `.canon/st/ST0017.json`, then `intent sync --to-store`. This cover never restates them.

---

_Generated by Intent v3.0.0 from `thread.json`. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
