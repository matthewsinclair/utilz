# Changelog

All notable changes to the Utilz framework will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.7.0] - 2026-09-08

Minor: **every version answer changes shape**, so a user can observe it. `utilz --version` now prints `utilz:2.7.0`; every utility prints `utilz:2.7.0/<name>:<version>`. **A new tag rather than a moved `v2.6.1`**, and the first tag in this project without a `v` -- the prefix is noise and it was the last thing making the framework's line a different shape from every utility's.

### Changed

- **`--version` HAS ONE HOME, AND BOTH VERSIONS ARE ON ONE GREPPABLE LINE** (ST0015). Every utility answers `utilz:<framework>/<utility>:<version>`, followed by its description; `utilz` itself answers `utilz:<version>`, keeping the description and the tree-provenance line that says which tree replied. **There is no `v` anywhere** -- hv's ruling, on the grounds that it is noise, and it was the only thing making the framework's line a different shape from a utility's. `common.sh` was the estate's single minter of one.

  **The defect was that `--version` had FIFTEEN homes and two of them disagreed.** `bin/utilz` intercepted the flag on the SYMLINK path only, so thirteen utilities hand-copied an identical `--version) show_version "<name>"; exit 0` arm to cover the `utilz <util>` form. **The two that never copied it were the two that broke**: `todo` had no arm and answered `Unknown command: --version` while its own `--help` advertised the flag, and `prez` could not have one because clap answers before any shell runs -- so `prez --version` and `utilz prez --version` differed by one character, the `v`, and the quiet one is the one that survives a reviewer.

  **The fix is one intercept called from both dispatch sites, and the fourteen arms are deleted.** Deletion is the proof rather than a tidy-up: "the dispatcher ALSO handles it" passes every test that "the dispatcher handles it" passes, so only their absence distinguishes the two. `expz` carried two arms, not one, which no per-file assumption and no single-line grep found -- only counting per file while removing them.

  **`script.tmpl` carried the arm too, and that was the leak that mattered.** The template scaffolds every new utility, so `utilz generate` would have re-seeded the duplication one utility at a time and the fix would have decayed silently from the next utility onward. An acceptance test now generates a utility and runs it on both forms, pinning REGENERATION rather than the template's current text.

  **An unreadable version is no longer a silent success.** The old arms exited 0 whatever `show_version` returned, so a utility whose `version_file` was missing from an install printed an error to stdout and reported success to the caller -- not hypothetical, it is the prez regression fixed earlier the same day.

- **EVERY VERSION HAS ONE HOME, AND NOTHING RESTATES IT** (hv's ruling). The framework's is `./VERSION`; each utility now carries its own `opt/<name>/VERSION`, and its yaml points at it with `version_file` instead of repeating the number. **Thirty-two copies were removed** -- fifteen help files, fifteen utility READMEs and two templates each stated a literal `**Version**:` that nothing held equal to anything.

  **This estate had already been bitten twice and only noticed once.** `help/utilz.md` carries the record of the first: hardcoding the framework version there drifted it to 2.2.0 while 2.4.0 shipped. That fix was applied to one file and left in fifteen others, where it drifted again -- measured before this change, `cleanz`'s README said 1.1.0 against a yaml of 1.2.0, and `todo`'s help AND README both said 1.0.0 against 1.1.0. **Nothing reported either, because prose is the copy nobody re-reads.** The templates were minting fresh instances: every utility `utilz generate` scaffolded was born with a literal that was correct exactly until its first release.

  **`prez` is the documented exception and it is not an exception to the rule.** Cargo REQUIRES a version in `[package]`, so `crate/Cargo.toml` is a home that cannot be deleted -- which makes it the one to keep, and prez has no `VERSION` file because a second one would be the duplication being removed. The rule is **point at the one home you cannot delete**, not "use this filename".

  **A utility now reports the framework it belongs to as well as itself.** Two versions are in play whenever a utility misbehaves, and being handed one of them is how a bug report arrives missing the half that explains it. The line's final shape is below, under ST0015.

  Two tests hold all of it, both proved to go red by re-introducing a literal: no help file, README or template may state a version, and no utility yaml may either -- each paired with a check that the pointer is still present, because deleting every version line satisfies an assert-absence just as well as fixing it does.

- **BREAKING (prez v2.0.0) -- `--theme` takes a NAME and nothing else** (ST0013). It resolves on `PREZ_THEME_PATH`, extended for one invocation by the new `--theme-path`, then among the built-ins, and **never against the working directory**. Paths move to the new `--theme-file`, which accepts both shapes the old flag took: a `.css` file, or a directory holding `theme.css`. Front matter splits the same way into `theme:` (a name) and `theme-file:` (a path resolved beside the deck), or the ambiguity simply moves into the deck where it travels with the file.

  **The defect was measured rather than reported.** The same deck, the same binary, `--theme=simple`: from a directory holding a `./simple/` the local theme won at 18208 bytes; from anywhere else the built-in won at 22662. **Neither run printed a word** -- `provenance()` announces only a search-path hit and a cwd hit was stamped as a typed path -- so one command built two different decks silently.

  **The fix is a type change, not a branch reorder.** The resolver took one ambiguous string and asked `path.exists()` first; it now takes a name or a path as distinct variants, so the working-directory branch is unreachable rather than merely unvisited. Deleting the branch instead would have passed every test and left the cause in place for the next feature that needed a path.

  **A breaking change taken deliberately, at the cheapest moment it will ever have**, and the refusal names the remedy for the case that fired: a path given to `--theme` is refused naming `--theme-file` with the value, so the message can be pasted. Both known live invocations migrated by one word. The downstream estate verified its client decks re-render **byte-identical** under the new spelling.

- **`version_file:` reads the version OUT of a file that carries one, rather than requiring a file that IS one.** A plain `VERSION` file still works by `cat`; a `Cargo.toml` is read from `[package]`. **Cargo requires a version in `[package]`, so for a Rust utility that file is a home which cannot be eliminated** -- which made prez's inline `version:` the removable copy. The two were not two readings of one value but two channels: the dispatcher answered from the yaml and the binary from a compiled-in `CARGO_PKG_VERSION`, so they could disagree and each would look right alone.

### Added

- **`utilz test` and CI discover every black-box suite in `crate/test/` rather than one hardcoded filename, and REFUSE one that is present but not executable** (ST0013/AC03). Naming a single file meant a second suite was run by nothing: CI green, the local driver green, and its tests marked green on a manual run nothing repeats. The refusal half is not optional -- "glob and run each executable one" silently skips the non-executable and hands back a green, which is the defect the single-file guard already existed to prevent, generalised from one name to a set.

## [2.6.1] - 2026-09-08

Patch: two CI gates repaired, no user-visible behaviour change. **A NEW TAG RATHER THAN A MOVED `v2.6.0`**, because the fixes touch `opt/utilz/lib/`, which is shipped code and not harness -- and because the install manifest records `source-commit`, so moving a tag would leave `v2.6.0` naming two different sets of bytes over time while an already-published install still claimed the commit the tag no longer named. That is the provenance property AC07 exists to protect.

### Fixed

- **ShellCheck went red on the 2.6.0 release, and the cause was one deliberate subshell reaching eighteen files.** `common.sh` began sourcing `install.sh` for doctor's install-integrity check, and `install.sh` bound the tree ambiently -- `raw=$( export UTILZ_HOME="$tree"; get_util_metadata ... )`. Under `shellcheck -x` that produced SC2031 on every later read of `UTILZ_HOME` in every file reaching `common.sh`: 39 findings, including `opt/cleanz/cleanz`, which the release never touched. **Fixed by removing the idiom rather than muting the check** -- a `# shellcheck disable` at the write site does not suppress read-site warnings, and disabling SC2031 project-wide would hide a real bug class. `get_util_metadata` now takes the tree as an optional third argument defaulting to `$UTILZ_HOME`, and `install.sh` passes it. Behaviour is unchanged and the caller's `UTILZ_HOME` is now provably untouched rather than merely subshell-scoped.
- **The prez acceptance suite has a third outcome, `n/a`, and it is the first exception to "a SKIP is not a pass"** (ruled by hv). AT15's keychain half asks about Chrome Safe Storage, a macOS keychain concept, so on Linux there is nothing for it to be about; counting it as did-not-run demanded a run that could never happen and reddened `--strict` on every Linux leg. **The condition is the platform predicate, never the missing tool**: gating on `command -v security` would make any machine lacking it silently exempt, including a Mac that should have it, while `uname -s != Darwin` cannot. A Darwin host without `security(1)` still reports `unchecked` -- that is a broken machine, not an inapplicable one. It is only honest while some leg runs the check, and the macOS legs do; the comment says a `not_applicable` check that no leg runs is dead and should be deleted rather than excused. Verified on macOS at 14 passed / 0 failed / 0 skipped / **0 n/a**, the zero being the evidence the check genuinely ran.

## [2.6.0] - 2026-09-08

Minor rather than patch: four new user-observable commands and a new utility, no breaking change to anything that existed at 2.5.0. Semver by the same reading 2.5.0 used.

### Added

- **Utilz can publish a runnable install of itself, so the source can be worked on without disturbing the copy you use** (ST0014). `utilz install` publishes this checkout to `install.prefix`; `utilz upgrade` replaces an existing one. **Devbin's install tree is deliberately not runnable and ours inverts that**, so the criterion is that the install works when the source is moved aside rather than that files arrived -- an install reaching back into the checkout passes every check that does not move the source.
- **`utilz use dev|opt` switches which tree your PATH symlinks serve, in one word, from either tree.** No path is typed either way: the install records `source-tree` in its manifest and the checkout reads `install.prefix` from its yaml, so each tree carries the address of the other. `utilz use` with no argument reports which tree is live and changes nothing. `utilz relink` is the mechanism underneath when you want to name a tree yourself.
- **`utilz version` names the tree that answered** -- `installed at <prefix> (<commit>)` or `source at <path>`. Without it the two-tree arrangement is invisible in exactly the situation it exists for: someone debugging behaviour cannot tell which copy produced it.
- **`utilz doctor` gained a seventh check, install integrity**, verifying every owned file against the manifest it was published with. In a source checkout there is no manifest and doctor says so rather than passing silently.
- **The install carries a manifest recording the version, the source commit, the source tree and a checksum per owned file.** Symlinks are checksummed by their target STRING against their path, never by the file they resolve to -- all fifteen resolve to the dispatcher, so a dereferenced check gives them one hash and reads a corrupted link as intact.

### Changed

- **The owned set is enumerated by EXCLUSION over `git ls-files`, not by an inclusion list.** The first cut shipped `opt/<n>/<n>`, `<n>.yaml` and `README.md` per utility, which is the shape the tree appears to have. A walk of all sixteen directories says otherwise: **five utilities keep runtime payload outside those three names** -- `cleanz`'s trope list, `expz`'s default schema, `pdf2md` and `xtrct`'s Python implementations, and `macoz`'s backgrounds -- 22 paths in total. An inclusion list publishes an install in which five of fifteen utilities are broken, each failing only when someone reaches the one code path that needs the file that never arrived. **The inversion is the keeper, not the corrected list**: an exclusion list ships a new subtree until someone says not to, which costs bytes rather than correctness.
- **`install` and `upgrade` never touch your PATH symlinks.** Relinking your environment takes a verb you typed. Publishing from a dirty tree is refused and **no flag overrides it**, `--force` included: the manifest's commit claim only holds when nothing is uncommitted.

### Fixed

- **An exported `UTILZ_HOME` silently redirected an install back at the checkout, and this project's own README told you to export it.** The dispatcher derived its tree from `$0` only when the variable was unset, so a published install invoked by its own path answered from whatever tree `UTILZ_HOME` named -- measured with a marker VERSION: unset gave the install, exported gave the source, and nothing said so. An ambient login-shell export made that the normal case rather than the edge. **The dispatcher now always derives from `$0` and ignores an inherited value**; the variable survives only as an internal channel to child processes. `README.md` and `help/utilz.md` no longer tell you to set it and say plainly that the old instruction was wrong.
- **`utilz test` from an install tree refuses and now NAMES the source tree**, printing a `cd <path> && utilz test` you can paste. It previously said "the checkout this install was published from", a description the reader has to resolve, which made a correct refusal read as a failure with no next step. The suite rewrites `bin/`, which is exactly what the manifest checksums, so running it in an install would report drift nobody caused.
- **`cryptz`'s round-trip test blocked the whole suite on a passphrase prompt.** `run_cryptz` did not close stdin, so `cryptz decrypt` inherited the terminal and gpg asked for a passphrase; the test's own comment said "decrypt may prompt for passphrase, so we don't assert success", which handled the assertion and not the prompt. Green in CI, dead on a terminal. Stdin is now closed at the one door every cryptz call goes through, and the decrypt half is opt-in behind `CRYPTZ_TEST_DECRYPT` and asserts success when it runs -- **a call that asserts nothing and can block the suite is pure cost.**

### Changed

- **`utilz todo` writes GFM task-list items, so a `todo.md` renders as a checklist instead of a wall of prose** (todo 1.1.0). The line was `01:[ ] text`, which is not a markdown construct: a run of them collapses into a single paragraph anywhere markdown is actually rendered, which is how the estate's CMS, Obsidian and a GitHub blob all showed it. It is now ``- [ ] `01` text`` -- a real list item, with `[ ]` and `[x]` rendering as checkboxes for free. **`intent todo` had already reached the same conclusion for the same reason** (its emit comment: "plain `[-] ...` lines get reflowed into one paragraph"); the fork had not carried it across.
- **The id moved to after the checkbox, into a code span.** A task-list marker only counts when it directly follows the bullet, so `- 01:[ ] text` is a plain list item with literal text while ``- [ ] `01` text`` is a checkbox. The id has to stay visible because it is the handle every verb takes.
- **`[-]` for DOING is left as literal text and not forced into a checkbox.** The glyph is what `sync` and `toggle` reconcile against and what the legend documents; a DOING item under its own heading reads clearly enough without a box. Round-trip correctness over a cosmetic third state.
- **Reading is unchanged in tolerance and now strips the id from either position**, so pre-2026-09 files, a missing id, a hand-pasted `- [ ]` line and an `intent todo` item all still parse. Writing is always the current shape and ids renumber positionally on every write, so `utilz todo sync` migrates a file in place with no separate migration. Two tests cover it: a legacy file through `sync`, and a double round trip not accreting a second id.

### Added

- **`stampz` -- stamp a recipient watermark across every page of a PDF pack** (ST0011). Promoted out of a Lamplight tool so it is available everywhere rather than living in one repo's `docs/bin/`. One rotated line of mono type reading `CONFIDENTIAL <date> <recipient>`, mid-grey at 30%, plus a `STAMP-MANIFEST.txt` recording the page count and the sha256 of every file before and after. Two guards that refuse rather than approximate: mixed page geometry, and any change in page count. **It deters and does not protect** -- an overlay is strippable in seconds, and the header, the README and the help all say so, with a test asserting the sentence is there.
- **The stamp is built as a PDF, not rendered.** The reference drove headless Chrome at a hardcoded `/Applications` path over a generated HTML file and pulled its font from a CDN, which made it a one-platform, online-only tool. `stampz` assembles an 823-byte one-page PDF directly in base-14 Courier-Bold: no browser, no network, no embedded font, and it runs anywhere `qpdf` and `poppler` do. Courier is fixed-pitch at 0.600 em, so the size formula's constant is exact by construction rather than contingent on which font arrived. Object offsets are measured with `wc -c` per append rather than summed from `${#s}`, which counts characters and would shift every xref entry on a non-ASCII recipient.
- **Out-dir is the default and `--in-place` is explicit**, inverting the reference. In-place is only safe when the originals regenerate from somewhere else, which is a property of the pack and not of the tool.

### Fixed

- **`M-x utilz` offered thirteen utilities; four could never have worked and one mutated the filesystem on selection** (issue 0009). The `integration:` blocks were authored in one pass from each utility's I/O shape and nothing checked that the resulting command line was one the utility would accept: `cryptz`, `gitz` and `retry` each needed a verb the block did not supply, and `mdagg` was declared `stdin` when it does not read stdin. `lnrel` created a symlink in the prompted directory and reported success. On hv's ruling the menu is pruned to six -- `cleanz`, `expz`, `mdagg` (input corrected to `path`), `pdf2md`, `todo` (input corrected `none` -> `file`, `flags: [--file]`), and `prez` (added, `flags: [build]`, the strongest editor fit in the roster). Eight blocks removed. **`todo` was dropped in the first pass on a wrong reason and hv caught it**: its declaration was broken in the same way `mdagg`'s was -- `input: none` meant the bridge ran it in whatever directory Emacs was in and ignored the buffer -- and `mdagg` was corrected rather than dropped. Same defect, two conclusions. **`integration.flags` was the mechanism that would have made the verb-taking utilities work; it reaches the TSV and the elisp inserts it, and every utility declared it empty.** A framework test now invokes what the bridge would build per declaring utility and fails if the utility rejects the form, with a self-discrimination control so it cannot pass vacuously.
- **Issue 0006's sweep left a third hardcoded roster copy** (issue 0008). `prez.bats` asserted `"14 utilities"`, so adding the fifteenth reddened a suite in a thread that never touched it -- the same count-pinned-to-a-moment defect 0006 fixed in two other places on the same day. The count is now derived from `utilz list`, the idiom CI's macOS leg already uses. Two prose copies went with it: `docs/index.md` claimed "All 12 shipped utilities" and named twelve while the tree held fifteen, and `README.md`'s tree comment said "(12 utilities total)".
- **A dead mixed-geometry guard, inherited from the reference.** `pdfinfo` prints `Page    1 size:`; the guard matched `/page *[0-9]+ size:/` against a case-sensitive awk, so it matched nothing, `wc -l` returned 0, and the caller's `${varied:-1}` read that zero as "one geometry, carry on". The check could not fire on any input. A probe that reads nothing is now a refusal rather than a pass.
- **`cryptz` and `gitz` declared no dependencies while hard-requiring `gpg` and `git`.** Both call `require_command`, so the failure arrived at use rather than from `utilz doctor`. Declared, and now checked up front. (`prez` still declares none deliberately: `cargo` is a build-time need and a test pins that distinction.)
- **`help/cryptz.md` was still the generated template** -- "Add more detailed description here", a generic `[OPTIONS] [ARGS]` synopsis, no commands, and no `--email`. Rewritten from the as-built surface. It was the only help file left in that state.
- **`docs/index.md` restated the framework version as 2.2.0** while `VERSION` read 2.5.0 -- a second copy of the single source of truth, stale across three releases. Replaced with a pointer, matching the fix `help/utilz.md` already carried.
- **`.claude/restart.md` documented `intent st list --all`**, which has never worked (the flag is `--status all`), and pointed at `intent/issues/OPEN/` for open defects. That directory is permanently empty by policy, so it confirmed "no open defects" while one was filed.

### Changed

- `README.md`'s `## Included Utilities` gained `prez`, `stampz` and `todo`. `prez` and `todo` had shipped in earlier releases and were never added.
- ST0002 and ST0007 carry `acceptance: exempt`. Both completed before the v3 contract model and hold zero criteria, so the close gate blocked their work packages with a remedy the project otherwise rules against; exempt is correct for a genuinely contract-free unit and is not the ST0010 case, where a full contract exists and the gate cannot read it.
- Issue 0006 was written into canon. It had existed only as a flat view, so `intent doctor` counted one fewer issue than the tracker showed.

## [2.5.0] - 2026-08-29

### Added

- **`prez` -- markdown in, one self-contained HTML presentation out** (ST0010). The first Rust utility in the framework. It is a pipeline, not a presentation tool: it writes a file and stops, the browser presents, and there is no server and no viewer. One `.html` carries everything inside it, so a deck opens offline, from a USB stick, in five years. `prez build`, `prez pdf` (one slide per 254x142.9mm page), `prez present` (a de-chromed window at the deck's own aspect). Seven brand-free built-in themes, `--theme NAME` resolving through `PREZ_THEME_PATH`, mermaid diagrams opt-in via front matter (and costing zero bytes when not opted into). Hoisted from an upstream estate at a recorded pin rather than rewritten, with the adaptation captured as an idempotent script so a moving pin costs a re-run rather than a re-remembering. `comrak` is its only dependency.
- **Rust support in the framework itself** (ST0010/WP-02). Utilz had never held compiled code. `utilz test` now discovers up to three suites per utility BY CONVENTION, so the next utility of a given shape inherits the driver for free: `crate/Cargo.toml` drives `cargo test`, `test/*.bats` drives BATS, and `crate/test/acceptance.sh` drives a black-box suite with `--strict` always passed -- hard-coded, because a suite that degrades to skips exits 0 having driven nothing. `utilz doctor` treats `cargo` as optional rather than as a declared dependency. `.gitignore` fences `opt/*/crate/target/` in a commit that landed before any in-tree build existed. CI gains `rust` and `clippy` jobs (the latter with `-D warnings`), both feeding the `all-green` gate.
- **A shell shim per compiled utility.** `opt/prez/prez` resolves a built binary and refuses with a remedy when it is absent, following the existing `ensure_venv()` precedent rather than committing a binary that could not serve both Ubuntu CI and macOS from one artifact. It honours `CARGO_TARGET_DIR`, which is what lets a cold build be forced and then verified.

### Fixed

- **Adding any 14th utility reddened the suite whichever way it declared integration** (issue 0006). `bridge.bats` asserted `emit_integration_tsv` emits exactly 13 rows while `utilz emacs doctor` counted a utility without an `integration:` block as an issue and returned 1, which two other tests asserted did not happen -- so no value of a new utility's yaml satisfied both. The row count is now a property rather than a number pinned to a moment, and a utility not bound to the Emacs bridge is not treated as broken. Latent since both checks were written; `prez` is the first utility added since.
- **The CI shellcheck gate was aimed at code with a different owner.** The vendored `devbin` tool sources files resolved at runtime, which shellcheck cannot resolve statically, so every one was an SC1091 and the gate exited non-zero at default severity. Excluded by pattern rather than annotated, because devbin ships a manifest that would make an in-file directive detectable drift.

### Changed

- `test-macos` derives its utility roster from the dispatcher instead of carrying a hardcoded list, so a new utility is covered there the day it lands. `prez` is deliberately excluded from that leg: its acceptance suite needs Chrome, node and a toolchain, and `--strict` correctly counts a skip as a failure, which makes it the wrong instrument for a runner that legitimately lacks the tools. The crate is covered by the `rust` and `clippy` jobs instead.

### Known

- **The `prez` slide counter drops below the 4.5:1 contrast floor on dark slides** (issue 0007). It is `position: fixed` and a sibling of the deck, so no theme can reach it per-slide; the fix belongs in the compiler. `aria-hidden` decorative chrome, so low severity.

## [2.4.0] - 2026-07-29

### Changed

- **BREAKING (soft): `yq` is now a hard dependency of the framework** (ST0009/WP-02). `get_util_metadata` previously carried two parsers -- a `yq` path and a grep fallback that answered four hardcoded queries and returned an empty string for everything else, which a caller cannot distinguish from an absent key. The fallback is gone; `yq` is the single YAML parser, declared in `opt/utilz/utilz.yaml` and gated by a single `require_yq`. Without `yq`, `utilz list` now fails loudly with an install hint where it previously degraded silently and gave wrong answers. `utilz doctor` deliberately still completes without `yq` and names it as the missing dependency -- it is the command you run to discover exactly that. This is the change that makes the bump minor rather than patch.
- **One walker of `bin/`** (ST0009/WP-01). `list_utilities`, `run_doctor` (twice), `run_tests`, `emit_integration_tsv`, and `emacs_doctor` each open-coded the same glob-and-filter over `bin/*`, and had already drifted: two verified the symlink resolved to the dispatcher, three accepted any symlink, so a stray link in `bin/` was a utility to `doctor` and not to `list`. All five now read a single `each_utility()` (Highlander), consumed via process substitution so accumulator arrays survive the loop.

### Fixed

- **`utilz generate` stamped a compatibility floor no 2.x framework could satisfy** (issue 0002, ST0009/WP-03). `opt/utilz/tmpl/metadata.tmpl` hardcoded `utilz_version: "^1.0.0"` while `VERSION` read 2.3.0, and `run_doctor` compares major versions -- so every generated utility was born incompatible and stayed that way until someone hand-edited the yaml. The floor is now derived from the framework's own `VERSION` via a `{{UTILZ_FLOOR}}` placeholder substituted at generation time. Latent rather than observed: all 13 shipped utilities already carried `^2.0.0`, so nothing in the repo was ever broken by it.

### Docs

- `docs/architecture.md`, `help/utilz.md`, `README.md` reconciled with the as-built: `yq` documented as a framework-level hard requirement rather than an mdagg-specific one, `each_utility` / `require_yq` added to the common-library reference, and the claim that utilities call `get_util_metadata()` corrected (it has no callers outside `common.sh` -- it is framework-internal). The stated bash floor is corrected from "4.0+" to 3.2, which is what macOS ships and what the code has always targeted.

### Tests

- `opt/utilz/test/common_lib.bats` -- 12 new tests covering the three seams, 11 of which fail against the pre-change code. `each_utility` distinguishing a dispatcher symlink from a stray symlink and a plain file; the drift regression asserting a stray link is invisible to `list_utilities` **and** `run_doctor` (the old code counted it in one and not the other); `list_utilities` failing loudly without `yq`; the install hint printed **once** rather than once per utility (a regression test for a defect hit during this work -- `require_yq` originally memoised into a variable, which does nothing across the command substitution `get_util_metadata` runs in); `run_doctor` completing without `yq`; `get_util_metadata` returning non-zero rather than an empty string; and the generator stamping a floor that tracks a fabricated `VERSION` of 7.3.1, proving derivation rather than coincidence.

## [2.3.0] - 2026-07-10

### Added

- **todo** - New standalone DOING / TODO / DONE task manager (ST0008). A single-file manager for a plain-text `todo.md` with positional item numbers and history sweep / purge subcommands. Forked from Intent's `intent todo` but made independent of steel threads: the `todo.md` is the source of truth, not a projection. File-location precedence: `--file <path>` wins, then `-g`/`--global` (`${XDG_CONFIG_HOME:-$HOME/.config}/utilz/todo/todo.md`), else default `./todo.md`. Verbs: `add`/`start`/`done`/`notdone`/`toggle`, `next`/`doing`/`todo`/`done`/`count`, `done --prune`/`--flush`, `sync`/`update`/`edit`, `--json`. The `todo.md` format stays mutually compatible with `intent todo` (same bucket headings and glyphs).
- **`utilz todo` <-> `intent todo` mutual guard** (ST0008/WP-08). `utilz todo` stamps `generator: utilz todo` on every write and refuses to clobber a `todo.md` owned by a different generator (eg `intent todo`) - but only when Intent is actually present (a silent `command -v intent` plus a `intent/.config/config.json` check rooted at the target file's directory), so utilz stays a zero-dependency standalone tool that runs silently and never fails where Intent is absent. It also refuses to create a fresh default `./todo.md` inside an Intent project. Mirrors Intent's `guard_foreign_todo` without taking a runtime dependency on Intent.
- **File-based issue tracker** at `intent/issues/` (`OPEN/` / `CLOSED/` / `_templ/`) - lightweight, git-tracked, steel-thread-independent, for defects a single issue can drive without a full ST.

### Fixed

- **mdagg: silent Unicode data loss under a C locale** (issue 0001). With `--strip-back-links`, mdagg used a `[←↑]` grep bracket class that, under `LC_ALL=C`, degraded to a byte set (`0xE2` is the UTF-8 lead byte for the whole U+2000-U+2FFF block) and silently deleted any content line containing a `→ ∥ ∈ — ...` character - invisible in a UTF-8 terminal, data-destroying in CI / agent sandboxes that export `LC_ALL=C`. Fixed with an anchored, byte-safe ERE (`grep -vE '^[[:space:]]*\[(←|↑)'`) that also tightens the strip to genuine navigation-link lines (inline arrows in prose now survive). The sibling title-case (`sed 's/\b\(.\)/\u\1/g'`, whose `\b`/`\u` are GNU-sed no-ops on BSD sed - so section titles came out un-cased on macOS) was replaced with a portable POSIX-awk title-case, and the duplicated title derivation extracted into a single `derive_title()` (Highlander).

### Changed

- Framework version bumped to 2.3.0 (additive minor bump - new `todo` utility; no breaking changes).
- CI: **expz** added to the Ubuntu (test-linux) test loop. Its BATS suite is entirely offline (every test returns before expz's `ANTHROPIC_API_KEY` check), so no CI secret is required; macOS already exercised it via `utilz test`.

### Tests

- `opt/todo/test/todo.bats` - full BATS coverage for the todo utility, including the WP-08 mutual-guard acceptance tests (stamp present; foreign-refusal inside an Intent project with a stubbed `intent` on PATH; foreign-proceed outside a project; own / legacy / fresh pass-through; default-path creation refused in an Intent project).
- `opt/mdagg/test/mdagg.bats` - regression tests for issue 0001 under `LC_ALL=C` (Unicode content survives while navigation links are stripped; a link-only file strips without a `set -e` abort; inline arrows preserved; portable title-casing).

## [2.2.0] - 2026-04-23

### Added

- **Editor integration manifest** - new `integration:` YAML block declares each utility's input kind (`stdin`/`file`/`path`/`none`) and output kind (`replace`/`buffer`/`message`/`discard`). Optional; absence means the utility is not auto-exposed to editor bridges. All 12 current utilities now carry an `integration:` block.
- **`utilz integration commands`** - editor-neutral TSV manifest surface. Emits one row per utility with an `integration:` block: `name<TAB>description<TAB>input<TAB>output<TAB>flags`. The TSV is the single cross-boundary contract - any editor integration (Emacs, future VSCode / Zed / Vim) consumes it without parsing YAML directly. The walker (`emit_integration_tsv` in `opt/utilz/lib/common.sh`) is the only place that walks the YAML corpus to produce the integration catalogue (Highlander).
- **`utilz emacs install`** - installs the canonical elisp bridge (`static/emacs/utilz.el`) to a destination path. `--symlink` creates a symlink (preferred - `git pull` in Utilz rolls the bridge forward); omitting it copies. `--force` overwrites a differing destination. Prints the `(load ...)` line for the user to paste into `config.el`. Never edits the user's Emacs config.
- **`utilz emacs doctor`** - health check: verifies `utilz` is on the PATH Emacs will see, every installed utility has a valid `integration:` block (flags missing / invalid `input` / `output` values), and the canonical elisp is present.
- **Emacs bridge (`static/emacs/utilz.el`)** - thin coordinator (~270 lines). `M-x utilz` offers a `completing-read` menu (Vertico-compatible) of the TSV rows, annotated with descriptions. Picking a utility resolves input per its declared kind (region for stdin, buffer file or prompt for file, directory prompt for path, none), runs it, and dispatches the result per its declared output kind (replace region with single `undo-boundary`, pop a `*utilz-NAME*` buffer, echo a single-line message, or discard). `C-u` prompts for extra flags; `C-u C-u` confirms the full command line before running. Non-zero exit pops a stderr buffer and leaves the region/buffer untouched (No Silent Errors). `M-x utilz-refresh` re-reads the manifest. Default keybinding: `C-c u`.

### Changed

- Framework version bumped to 2.2.0 (additive minor bump - new subcommand families, no breaking changes).
- `opt/utilz/tmpl/metadata.tmpl` - includes a commented `integration:` stub so `utilz generate` scaffolds the block for new utilities.
- `help/utilz.md` - new sections documenting `utilz integration <verb>` and `utilz emacs <verb>`.
- Project-wide bash reindent from 4-space to 2-space (Intent project standard). 32 files touched, pure mechanical change.

### Tests

- `opt/utilz/test/bridge.bats` - 16 new tests covering TSV shape (column count, row count, cleanz spot-check, utilz-core exclusion), dispatcher verb routing (`integration`, `emacs`), `install` happy path + `--symlink` + idempotency + error paths (missing `--dest`, unknown option), and `doctor` exit-zero on clean checkout.

## [2.1.0] - 2026-03-25

### Added

- **expz** - New batch expense receipt PDF extraction utility
  - Recursively finds PDF receipts in category subdirectories
  - Extracts structured data via `xtrct` (Claude API) using a JSON schema
  - Outputs CSV with columns: Date, Category, Supplier, Description, Currency, Subtotal, VAT, Total, Reference, File
  - Category derived from parent directory name
  - Bundled default schema at `lib/expense_schema.json`, overridable with `--schema`
  - Output to stdout or `--out <file>`
  - Verbose mode with progress to stderr
  - Handles JSON array responses from xtrct (normalises to first element)
  - 9 comprehensive tests

### Changed

- Framework version bumped to 2.1.0

## [2.0.0] - 2026-03-02

### Changed

- **syncz** - Unison backend for bidirectional sync (syncz v2.0.0)
  - `--bidi` now uses unison when available for archive-based state tracking
  - Automatically distinguishes new files from deleted files (no more mass-deletion risk)
  - Falls back to rsync two-pass when unison is not installed
  - `--backend unison|rsync` flag to force a specific backend
  - `--fresh` flag to ignore saved unison archives (treat as first sync)
  - `--prefer d1|d2|newer` flag to force conflict resolution (unison only)
  - `--no-metadata` flag to ignore xattrs and resource forks (for cloud filesystems)
  - `--ignore FILE` flag to read exclude patterns from a file (one per line, `#` comments supported)
  - `--dry-run` works with unison via mutation blocking (`-nocreation/-nodeletion/-noupdate`)
  - `--delete` is a no-op in unison mode (deletions are state-tracked)
  - Path display uses `D1:/D2:` root labels with common suffix extraction (`Dir:`)
  - `SYNCZ_ROOTS_SHOWN` env var to suppress per-invocation headers in wrapper scripts
  - Dry-run output shows `[new]`, `[changed]`, `[CONFLICT]` tags with direction labels
  - unison added as optional dependency
  - 12 new tests (9 unison bidi + 3 backend selection); existing 66 tests pinned to rsync
  - unison added to CI dependencies (Ubuntu and macOS)

## [1.3.2] - 2026-03-02

### Fixed

- **syncz** - Safe orphan defaults in `--bidi` mode (syncz v1.4.0)
  - Bare `--bidi` now keeps all orphans and syncs them to both sides (was interactive delete-by-default)
  - `--bidi --delete` shows irreversibility warning before deleting
  - `--bidi --confirm` interactive prompt flipped to `[y/N/a]` where Enter = keep (was `[Y/n/a]` Enter = delete)
  - Prevents accidental mass-deletion when one side is mostly empty

### Changed

- Framework version bumped to 1.3.2

## [1.3.1] - 2026-02-19

### Added

- **lnrel** - New utility for creating symlinks with relative paths
  - Computes relative path from link directory to target using GNU `realpath`
  - Portable symlinks that survive directory tree moves
  - Automatic `grealpath`/`realpath` detection for macOS/Linux portability
  - Strips backslash escapes from paths (handles tab-completion-in-quotes pattern)
  - Supports dangling symlinks (target need not exist)
  - Single-arg form defaults to basename in current directory
  - 12 comprehensive tests
- coreutils added to macOS CI brew install (for `grealpath`)
- lnrel added to Linux CI test loop

### Changed

- Framework version bumped to 1.3.1

## [1.3.0] - 2026-02-12

### Added

- **pdf2md** - New PDF to Markdown converter utility
  - Converts PDF files to clean markdown using pdfplumber
  - 7-stage pipeline: text extraction, stats, line grouping, heading detection, list detection, header/footer removal, markdown emission
  - Heading detection via font size analysis (H1-H6 by descending unique sizes)
  - List item detection (bullets, dashes, numbered, lettered, parenthesized)
  - Repetitive header/footer removal (same text+Y on >50% of pages)
  - Page range selection (`--pages 1-5,7,10-12`)
  - File output (`-o output.md`) or stdout
  - Verbose mode with progress to stderr
  - Python venv auto-management at `lib/.venv/`
  - 15 comprehensive tests
- **xtrct** - New schema-driven semantic data extraction utility
  - Uses Claude API to extract structured data from documents via JSON schema
  - Descriptive schema format: `description` fields guide semantic extraction
  - PDF input auto-converts via pdf2md
  - Stdin support for piping
  - Output formats: json (pretty-print), csv, table (aligned columns)
  - Model selection (`--model`) with default claude-haiku-4-5-20251001
  - Verbose mode with token usage stats
  - `ANTHROPIC_API_KEY` fail-fast check before venv creation
  - Python venv auto-management at `lib/.venv/`
  - 12 tests (8 tier-1 always run, 4 tier-2 require API key)
- Composable pipeline: `pdf2md invoice.pdf | xtrct --schema invoice_schema.json`
- Python venv pattern for utilities with Python dependencies
- python3-venv added to CI Ubuntu dependencies

### Changed

- Framework version bumped to 1.3.0

## [1.2.1] - 2026-02-10

### Added

- **syncz** - Bidirectional sync mode (`--bidi`)
  - Two-way sync with automatic orphan detection using `find` + `comm`
  - Orphan resolution: interactive prompts, `--delete` (silent), `--confirm yes/no/all` (scriptable)
  - Two-pass rsync (dir1→dir2, dir2→dir1) with newer-wins strategy
  - rsync `--delete` never passed in bidi mode (orphan resolution handles deletions)
  - `--source-wins` and `--dest-wins` blocked in bidi mode
- **syncz** - `--confirm` optional argument (`yes`, `no`, `all`)
  - Auto-answers all prompts for fully scriptable operation
  - Works in both unidirectional and bidirectional modes
  - Peek-ahead parsing preserves positional argument compatibility

### Fixed

- syncz: empty orphan arrays caused silent exit on bash 3.2 (`set -e` + `&&` short-circuit)
- syncz: `--confirm yes --delete` now correctly deletes (macOS rsync missing delete count in stats)

### Changed

- syncz version bumped to 1.3.0
- Framework version bumped to 1.2.1

## [1.2.0] - 2026-02-08

### Added

- **syncz** - New directory-to-directory syncer utility wrapping rsync
  - Three conflict resolution strategies: newer-wins (default), source-wins, dest-wins
  - Confirmation modes: `--confirm` (Y/N/A per-step), `--force` (no prompts), `--just-do-it` (single Y/N)
  - `--delete` with safety gate (requires `--confirm`, `--force`, or `--just-do-it`)
  - `--backup` creates `.syncz-bak` copies of overwritten files
  - `--exclude` pattern support (repeatable)
  - `--dry-run` with summary and itemized change listing
  - `--verbose` and `--progress` modes
  - Uses `-rlptD` instead of `-a` to avoid group/owner warnings for non-root syncs
  - Trailing slash normalization for predictable behavior
  - 45 comprehensive tests
- rsync dependency check in `utilz doctor`
- syncz added to Linux CI test loop

### Changed

- Framework version bumped to 1.2.0

## [1.1.0] - 2025-12-28

### Added

- **cleanz** - New LLM text cleaner utility that removes hidden characters and formatting artifacts from text copied from ChatGPT, Claude, Gemini, and other LLM interfaces
  - Removes zero-width characters (ZWSP, ZWNJ, ZWJ, word joiners)
  - Removes byte order marks (BOM) and soft hyphens
  - Removes directional formatting characters (LTR/RTL embedding, override)
  - Converts non-breaking spaces and hair spaces to regular spaces
  - Removes control characters (preserving newlines, tabs, carriage returns)
  - Strips HTML `data-*` attributes commonly injected by LLM UIs
  - Normalizes whitespace (multiple spaces, blank lines, trailing whitespace)
  - Optional smart quote to straight quote conversion (`--normalize-quotes`)
  - Detection mode (`--detect`) to show hidden characters without cleaning
  - Verbose mode (`--verbose`) to show cleaning summary
  - Full I/O support: files, stdin, stdout, clipboard (`--clipboard`), in-place editing (`--in-place`)
  - 46 comprehensive tests

### Changed

- Framework version bumped to 1.1.0

## [1.0.0] - 2025-11-12

### Added

- Initial release of Utilz framework
- Dispatcher-based architecture with single `bin/utilz` entry point
- Common functions library (`opt/utilz/lib/common.sh`)
- Built-in utility generator (`utilz generate`)
- Built-in test runner (`utilz test`)
- Built-in diagnostics (`utilz doctor`)
- **clipz** - Cross-platform clipboard utility (macOS, Linux X11, Wayland)
- **cryptz** - GPG encryption/decryption wrapper
- **gitz** - Git multi-repository status checker
- **macoz** - macOS utilities (desktop backgrounds, folder icons)
- **mdagg** - Markdown file aggregator
- **retry** - Retry command until success
- GitHub Actions CI/CD with tests on Ubuntu and macOS
- Comprehensive test suites using BATS
