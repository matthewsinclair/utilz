---
st_id: ST0010
title: Add prez to utilz to support markdown presentation pipeline
status: WIP
created: 2026-08-29
completed:
---

# ST0010: Add prez to utilz to support markdown presentation pipeline

## Objective

Hoist `geopres` -- the markdown-to-HTML presentation compiler built as ST0002 in the Geodica `_tools` estate -- out of that estate and into Utilz as the `prez` utility, so that `utilz prez` becomes the tool's only home and `geodica present` becomes a CONSUMER of it rather than the owner of a bespoke copy.

The move must preserve the single property that makes it possible: the tool carries no knowledge of the estate it came from. `_tools` AC10 states it and grep-validates it, and `_tools` AT09 asserts it. A hoist that ends with a branded built-in theme, or with `--theme=geodica` resolving on a copy where the estate is absent, has destroyed the property it was trading on -- and nothing else in the suite would report it.

## Context

### What is being moved

`geopres` is one Rust crate at `~/Dropbox/Geodica/_tools/native/rust/geopres`: 3,378 lines across 13 modules, `comrak` as its only dependency, 111 unit tests plus a 9-test black-box acceptance suite. Markdown in, one self-contained HTML presentation out. It is `_tools` ST0002; WP01 (core) and WP03 (theme system) are done and validated, WP02 (estate binding) is in flight in `_tools-cc`'s hands.

The extraction line is already drawn and should not be redrawn. `_tools-vc` and `_tools-cc` both state it in the same terms:

| Moves to Utilz                                                        | Stays in `_tools`                                             |
| --------------------------------------------------------------------- | ------------------------------------------------------------- |
| the crate: `src/`, `Cargo.toml`, `Cargo.lock`, `assets/mermaid.min.js` | `bin/geodica_present` (the shim)                              |
| the seven brand-free built-in themes                                   | `themes/geopres/geodica/theme.css` (generated from tokens.yaml) |
| `examples/`, `test/acceptance.sh`, the three CDP probes                | `bin/help/geodica_present.md`, `test/geodica_geopres_test.exs` |
| AC02-AC10 and AC13                                                     | AC01, AC11 (estate binding), AC12 (generated brand theme)     |

### Why this is a move and not a rewrite

`_tools` AC10 required from the start that there be no estate paths in string literals and no estate imports in `src/`, grep-validated. The Geodica brand theme was deliberately placed OUTSIDE the crate at `themes/geopres/geodica/`, reached only because the shim puts `themes/geopres` on `GEOPRES_THEME_PATH`. hv's ruling of 28 Aug: no built-in is ever a brand.

That decision is what makes today cheap, and it is also the thing this move can quietly destroy. The guarantee is a REFUSAL: run the binary with the theme path unset and `--theme=geodica` must fail, naming every directory it searched. If that starts passing, the crate has stopped being liftable and no other check will say so.

### The shape hv has already settled

hv's scope instruction, verbatim: *"we build the presentation (rust) pipeline here inside the Gtools project and it's really good, and should be hoisted out into its own thing in the ../Utilz project. This will be a bit like the way 'utilz mdagg' works, and we should use that as an example. Once done, 'geodica present...' is a client of 'utilz prez'. 'geodica doctor' will need to check that 'utilz prez' is available. Note that utilz doesn't have any rust yet, so this will be the first rust code in that project."*

That closes what would otherwise have been the load-bearing open question. It is a HOIST of the crate, not a wrapper around a crate built elsewhere; `utilz mdagg` is the shape to follow; and hv knows this is the first Rust in the repo.

Utilz has never held compiled code. Measured: all 13 utilities are Bourne-Again shell scripts, `languages: ["shell"]`, and no `Cargo.toml` has ever existed here. The only non-bash precedent is `ensure_venv()` (pdf2md, xtrct), a bash wrapper over an INTERPRETED runtime with no build step and no compiled artifact.

One measured piece of good news: **the dispatcher needs no change.** `bin/utilz` requires only that `opt/<name>/<name>` be a regular file and executable before `exec`-ing it, so it is already agnostic to what sits there.

What sits there is the remaining design question, and it has one defensible answer. A committed binary cannot serve Ubuntu CI and macOS from one artifact, so `opt/prez/prez` is a **thin shell shim** that resolves a built binary and refuses with a remedy when it is absent. This is not a new invention: it is the `ensure_venv()` precedent already in this repo, and `_tools`' own `bin/geodica_present` is exactly that shim with three resolution branches (PATH, then a cache path, then a refusal naming the remedy), each already exercised with PATH scrubbed and the cache moved aside. Lift the shape rather than rediscover it.

What still has to be built around it, none of which exists today:

- CI runs Ubuntu + macOS with no Rust toolchain, no build matrix and no cargo cache.
- `utilz doctor` declares-and-checks dependencies from YAML; it has never built or installed anything.
- `utilz generate` scaffolds bash.
- Utilz is distributed by cloning and symlinking, and has never been built.

### Rust build hygiene: what actually happened, and what transfers

hv's instruction is that this thread be aware of the ballooning of Rust intermediate files in Lamplight, Intent and Conflab. The record, read rather than recited:

- **Conflab `f9875541` (27 Aug).** `native/cli` path-depended on `native/daemon` and neither was in a workspace, so each crate resolved and compiled its own copy of the graph into its own target dir. Measured: 433 packages in cli's lock, 401 in daemon's, **396 shared**; 94.4% of cli's release library bytes and 99.6% of daemon's were already built by the other crate. Fixed by making them one workspace, with `resolver = "3"` set EXPLICITLY -- a virtual workspace root defaults to resolver 1 regardless of member editions, which silently changes feature unification.
- **Lamplight `3b658d50f` (28 Aug).** Making `native/` a workspace moved the target dir, and three call sites still resolved through the dead path. One was loud and harmless (a successful build reporting "no .dmg produced"). One was quiet and worse: a `chmod` sitting behind `[ -d ]` on a path that could no longer exist, silently no-opping for a day. The third was the signed and notarised distributable chain, unexercised, with the same failure waiting.
- **`_tools` AC01** carries the third form: the repo lives inside Dropbox, so a `target/` directory there is tens of thousands of files churning as sync events. `bin/.devbin/cmd/build` exports `CARGO_TARGET_DIR` out of the tree and then ASSERTS ITS OWN POSTCONDITION, failing the build if a `target/` appeared anyway.

What transfers to Utilz, and what does not:

1. **The Dropbox rationale does NOT transfer.** Verified: Utilz lives at `/Users/matts/Devel/prj/Utilz`, outside Dropbox, and its `local` remote is a BARE repository, which receives objects only. Copying `_tools`' stated reason here would be carrying a justification that is false in this tree, which is worse than having no comment.
2. **The duplication lesson transfers as a TRIGGER, not as a workspace.** At one crate there is nothing to deduplicate and a workspace buys nothing. Conflab's 396 duplicate builds is precisely what "we will deal with it when there is a second crate" looks like when nobody wrote the trigger down. This thread writes it down: the second Rust crate in Utilz is the point at which a workspace with an explicit `resolver` becomes mandatory.
3. **Export `CARGO_TARGET_DIR`, never pass `--target-dir`**, so anything cargo shells out to inherits the redirect.
4. **The hygiene check belongs inside the build, not beside it.** A redirect that silently stops working looks exactly like a successful build.
5. **Sweep every consumer of the build path, and they are not all on PATH.** Conflab named five, including a CI cache `hashFiles` key that is invisible to a grep for "target". For Utilz the consumer set is `.gitignore`, the CI cache key, the `opt/prez/` shim, `utilz doctor` and `utilz test`.
6. **A guard behind `[ -d <dead path> ]` silently no-ops.** This is IN-AG-NO-SILENT-001 and it is the same shape as the defect class Utilz's own July audit was full of (`local x=$(cmd) || handler` never firing the handler).

### Three defects we would inherit, all open

The move must not quietly close them. All three are the tool's own, not the estate's, so all three follow it here.

1. **AC13 determinism: theme half LANDED, mermaid half open.** Six of the seven built-in themes carried `@media (prefers-color-scheme:)` blocks flipping the whole `--gp-` palette, so one built `.html` rendered light on one laptop and dark on another, silently. hv ruled flatten; `_tools-cc` landed it at `bfd0349` (verified at `_tools` HEAD by utilz-cc against `git show`, comment-stripped -- the flattened files carry prose describing the removal, so a naive grep still "finds" the query).
2. **`src/mermaid.rs:37-38` keys the diagram palette off `prefers-color-scheme`.** The independent second violator, found by hv's eye at a demo and caught by no test. DELIBERATELY not fixed ahead of the flattening -- alone, it would have made diagram and theme agree while the artifact stayed non-deterministic, erasing the visible mismatch that made the defect findable. Now unblocked: it builds `themeVariables` from exactly the five universal tokens (`--gp-bg --gp-fg --gp-muted --gp-rule --gp-code-bg`; 7/7 coverage verified -- `--gp-accent` is 4/7 and using it would re-enter the defect through an empty string). **This fix is the last crate change `_tools` makes, and the commit landing it green under `--strict` is the hoist pin.** The probe commits `817aed5`/`bfb33cd` predate the freeze and are inside the pin; anything found after it lands in Utilz.
3. **`_tools` ST0002 WP02 is in flight.** The estate binding is being written now, against a shim that this thread proposes to change. Sequencing is a live question, below.

### What to distrust in the inherited tree

`_tools` keeps a table of instances of one failure shape -- a check that reads plausibly and measures something adjacent to what it names -- in spec.md section 10. THE TABLE IS THE COUNT: a prose copy of the number drifted (three sessions were quoted three different totals) and was removed at `abc0151`, so this document deliberately carries no number either. The operational form, in `_tools-vc`'s words, is to ask not "does this pass?" but what would have to be true for it to go RED, and whether that is the same thing the check is named after. If the answer needs an "and also", it is measuring something adjacent.

Three of the table's lessons travel beyond their rows: a FALSE RED is a distinct direction and the more expensive one (it came within a step of reporting a shipped theme as unreadable); after repairing a control, RE-RUN THE WHOLE CONTROL (two instances arrived one inside the other -- widening the selector to fix the contrast check is what reached into the SVG and broke the next one); and a bad check handed to a peer as their verification instrument is PUBLISHED, not private.

The specific traps, each of which has already bitten:

- **`test/acceptance.sh` defaults to exit 0 with named SKIPs.** Six of its nine tests degrade to a skip without Node or Chrome. Run it with `--strict` or a browserless runner reports a confident green having measured no theme's legibility at all. This matters most in CI, which is exactly where the browserless box lives.
- **A contrast figure is only meaningful with its selector, palette and commit named beside it.** The probe (`test/theme-legibility-probe.html:51`) originally used `querySelector`, singular -- first text element per slide, always the heading, always full-strength foreground, reported as worst-case -- so every figure predating `ec3564a` is void, and the "worst case" moved four times in two days as selectors widened, nobody careless at any step. Current set (themes flattened, every text element, `bfd0349`), against the 4.5 floor: mono 4.9 is nearest it; steampunk 5.5, manuscript 5.7, simple 6.0, 8bit 6.2, geodica 6.9, blueprint 7.6, contrast 14.2. The worked example for the rule: 8bit's `th` sat at 4.18:1 -- a genuine floor breach, present all along -- hidden by two blind spots at once (headless Chrome defaults to light, so only the light adaptation was ever measured; and the probe never reached a table cell). Removing either blind spot alone would not have shown it.
- **`examples/demo.md` does not opt into mermaid.** Its `mermaid: true` sits inside a fenced yaml block, as documentation. Any diagram or determinism check must point at `examples/test_pres.md`. Measured: blueprint + demo.md passes while blueprint + test_pres.md fails, same theme, same binary. This trap has bitten three times.
- **`intent critic rust` arms 1 of its 7 rules** and declines the clippy-backed ones. A clean critic alone is a control that cannot go red, which is why `_tools` AC10 pairs it with `cargo clippy --all-targets`.
- **A green must name the instrument that produced it.** `_tools` AT notes cited a run five commits older than the suite. Re-run every test in its new home before carrying any green across; a green produced by a different repo's build is not evidence about this one.

### Open decisions for hv

hv's scope instruction has already closed the two largest. Recorded here as settled so they are not silently reopened:

- **Hoist, not wrap.** The crate moves into Utilz. Settled by hv.
- **`geodica present` becomes a client, and `geodica doctor` checks that `utilz prez` is available.** So Geodica acquires a real dependency on a Utilz install, deliberately, and the doctor check is the place that failure is meant to surface.

Three remain genuinely open:

1. **Fix-then-hoist, or hoist-then-fix?** `_tools-vc` argues fix-then-hoist, on the grounds that the same fix landing in two repos is the expensive version. The complication is that `_tools` WP02 (estate binding) is in flight right now against a shim this thread proposes to change. This is the one decision blocking a start.
2. **Does the name travel?** `geopres` carries the estate's prefix into a general-purpose framework, which is the coupling AC10 exists to prevent, pointing the other way. Renaming crate and binary to `prez` also renames `GEOPRES_THEME_PATH`, a breaking change for the `_tools` shim that must land in lockstep with it.
3. **What does `utilz doctor` do about `cargo`?** Utilz's doctor declares and checks; it has never built. Whether a missing toolchain is a doctor finding, a `prez`-only finding, or silent until first use is a framework-shaped decision, not a `prez` one.

### What must not be transcribed

`_tools` AC01 does NOT travel, and this is the clearest case on the thread of a criterion that is about a repository rather than about a tool. It reads: after `bin/devbin build`, the binary lands in the redirected `CARGO_TARGET_DIR` and no `target/` directory exists anywhere under the repo tree. It exists solely because `_tools` lives inside Dropbox, where a `target/` directory is tens of thousands of files churning as sync events on three machines and a NAS.

Verified independently here: Utilz is at `/Users/matts/Devel/prj/Utilz`, outside Dropbox, and its `local` remote is a BARE repository, which receives objects only and never a working tree. Carried across unchanged, AC01 would gate against a hazard that does not exist in this repo and would fail an ordinary `cargo build`. Both validators reached this conclusion independently.

The hygiene LESSONS above still apply and are restated as this thread's own criteria. The Dropbox JUSTIFICATION does not come with them, because a comment asserting a reason that is false in this tree is worse than no comment.

## Work Packages

| WP    | Title                                                              | Size | Status      |
| ----- | ------------------------------------------------------------------ | ---- | ----------- |
| WP-01 | Contract: design.md + AC/AT transcription from _tools ST0002       | S    | Done        |
| WP-02 | Framework Rust substrate: lang, gitignore, CI, test driver, doctor | S    | Done        |
| WP-03 | The hoist: crate at the pin, rename to prez, shim, yaml, help      | S    | Not Started |
| WP-04 | Validation: every carried green re-produced in the new home        | S    | Not Started |
| WP-05 | Default theme polish: basic but cool enough out of the box         | S    | Not Started |
| WP-06 | Theme addressing split + --theme-path (hv's CLI asks)              | S    | Not Started |
| WP-07 | Expose theme determinism checking as a prez capability (deferred)  | S    | Not Started |

## Acceptance

Acceptance Criteria and Acceptance Tests are RENDERED into `acceptance.md`, which is a GENERATED VIEW -- a row authored there is discarded by the next sync. The contract is canon in this thread's model: change a state with the `intent ac` / `intent at` verbs, and mint or reword a row in `.canon/st/ST0010.json`, then `intent sync --to-store`. This cover never restates them.

---

_Generated by Intent v3.0.0 from `thread.json`. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
