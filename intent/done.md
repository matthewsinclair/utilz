---
verblock: "29 Aug 2026:v0.3: matts - v2.5.0, prez and the Rust substrate (ST0010)"
---

# Done

## 29 Aug 2026 -- Utilz v2.5.0 (prez, the first Rust utility; ST0010)

The markdown-to-HTML presentation pipeline built in the Geodica `_tools` estate, hoisted into Utilz as `prez`, plus the framework support that makes a compiled utility a normal citizen rather than a special case. Framework goes to **14 utilities** (core + 13). Three nodes: `vc` held the contract pen, `cc` built, `hv` adjudicated.

Tagged `v2.5.0`. CI green on all seven jobs at `72ee931` (run `33265456630`).

- **`prez` v1.0.0.** Markdown in, one self-contained HTML presentation out. A pipeline, not a presentation tool: it writes a file and stops, the browser presents, and there is no server and no viewer. One `.html` carries everything, so a deck opens offline, from a USB stick, in five years. Seven brand-free built-in themes, mermaid opt-in and free when unused (9 KB instead of 3.5 MB), comrak its only dependency.
- **The framework learned Rust** (`0ebfa85`). `opt/*/crate/target/` gitignored by convention _before_ any in-tree build could run; `intent lang init rust`; two CI jobs (a rust matrix over both OSes that must PROVE a browser was found, plus clippy blocking from day one); a three-source test driver in `common.sh` that discovers `cargo test`, `*.bats` and `crate/test/acceptance.sh --strict` by convention, so the next Rust utility inherits it unedited; and a conditional cargo line in doctor that fires only when a crate exists.
- **The hoist** (`64d375b`, `673e4db`). `git archive` at pin `3e16597`, `geopres`->`prez` renamed atomically across 19 files, shimmed, then merged forward to pin `b600306`. The shim resolves the binary, rebuilds when a crate source, theme, asset or manifest is newer, and refuses by name when `cargo` is absent -- one committed binary cannot serve both Ubuntu CI and macOS, so the _shim_ is the portable thing.
- **The crate is a FORK, not a mirror, and that is the durable fact.** AC14 (announce-on-resolve) was deferred out of `_tools` by design, so it exists only here -- as do AT13, the AC18(b) browser override, AT17/AT19's browserless runtime probe, and AC19/AC20. A `tar -x` re-archive over the top deletes all of it **silently**: the build stays green and the suite still passes, because the tests proving the behaviour go in the same stroke. Every pin move goes through `hoist-rebase.sh` (attached to ST0010), which asserts 18 postconditions and is proven red against a pin-fresh tree.
- **hv's presentation runtime**, four commits (`4ed491e`, `c3307c5`, `f5253a9`, `5de4b0e`). A subtle key bar (`?`), `q`/`i`/`r`/`g` keys, `esc` closing rather than toggling the index, enter/space committing the highlighted slide, a presenting window sized to the deck's own 16:9, and a close message naming the platform shortcut **resolved when the deck is viewed rather than when it is built** -- the artifact is portable, so a deck built on a Mac and opened on Linux must say ctrl-W.
- **Estate zero-knowledge.** hv's ruling: Utilz carries no knowledge of `Geodica/` or its `_tools` (since moved to `~/Devel/prj/Gtools`). Swept from `deck.rs`, `theme.rs`, `.gitignore` and the README; `geodica` fixtures became `housestyle`. The interesting part is why nothing caught it: AT09's path check required a leading quote, so it saw string literals only, and **a real client path sat in a `deck.rs` comment, green, for as long as that check existed.** Widened to all of `src/` including comments, proven red by injection, and AC09 reworded to match -- a check stricter than its criterion is its own defect.

### Defects found underneath the work, none in scope when it started

- **`assemble()` expanded placeholders inside the stylesheet it had just injected.** Four chained `.replace()` calls put `{{style}}` in first, so a theme author documenting `{{slides}}` in a CSS comment would have shipped every slide twice inside their own stylesheet.
- **The shim hardcoded its binary path while cargo honoured `CARGO_TARGET_DIR`.** Isolation was accepted and ignored: an empty target dir stayed empty while the build "succeeded" off the warm binary. This is the same class `_tools` paid for from the other end, where a "cold" build finished in 0.05s and exited 0.
- **`--start-fullscreen` was passed on every `present` launch since the function existed**, never took effect for an `--app` window on macOS, and said nothing. Found from a screenshot; removed rather than fixed, because there is no working form of it.
- **AT04's bar checks were sampling a bar a message was holding open.** `Escape` is bound to `quit()`, which pops the close-shortcut message for 4000ms, and `settle()` holds the bar open for any live panel -- so two checks named `bar_starts_hidden` / `bar_hidden_again`, sitting 38 lines below an `Escape` press, read the bar a third of the way into the run. Proven with a scratch copy and a 4.5s wait, then fixed by moving the block ahead of the press, where its name is true, rather than adding a wait that would leave the name lying.
- **Issue 0006 closed** (`406af49`, `d39422e`). Adding _any_ 14th utility reddened the suite whichever way it declared: `bridge.bats` asserted exactly 13 integration rows, while `utilz emacs doctor` counted a utility _without_ an `integration:` block as a failure, and no value of `prez.yaml` satisfied both. The count now derives from the corpus; an unbound utility is reported informationally, because the Emacs bridge is opt-in and "not yet bound" is not "broken".

### Three portability defects CI found on the suite's first run off a developer machine

All three were in `test/acceptance.sh`; the crate built and its 128 unit tests passed on both platforms every time.

- **`stat -f %z` is BSD-only, and on Linux it SUCCEEDS with the wrong answer.** GNU `-f` means filesystem status, so it exits 0 and prints something else -- which is why AT01's `|| stat -c %s` fallback never fired, and AT03 and AT07 had no fallback at all. **A command that succeeds wrongly defeats every `||` guard written against it.** One `file_size` helper now, GNU first.
- **Two CDP launches slept two seconds instead of waiting for the port**, giving `ECONNREFUSED` on both matrix legs. A fixed sleep measures two seconds, not readiness. `wait_for_cdp` polls the port via bash's `/dev/tcp`, the same shape the suite's argv checks already used for files. Faster as well as correct: 52s to 48s.
- **The critic gate had two homes and CI could reach neither.** `intent critic rust` already runs at pre-commit; asserting it in the suite too was a second home, and the one no runner can satisfy. Deleted rather than worked around -- installing Intent in CI would redden Utilz whenever Intent's main is red, and a "not applicable" outcome is a control that cannot go red. clippy, the load-bearing half, stays.

`prez` is excluded from the `test-macos` roster (hv's call), covered instead by the two Rust jobs and clippy. The loop derives its roster from `utilz list` and `continue`s past prez with a comment saying why, so the exclusion is visible rather than an absence.

### Rulings worth keeping

- **A green is a licence to look, not a substitute for looking.** hv found three runtime defects by looking at output; none had a red test. This is why AC16 (a human renders every theme and looks) is a criterion the suite is not allowed to stand in for.
- **Delete the second home rather than check it.** Applied to the deck rosters and to the critic gate. A comparison brittle enough to false-red is worse than no check, because a false red sends a peer to disprove it and spends the credibility the next finding needs.
- **A criterion pins properties, not enumerations.** AC04 lists no keys; it names `BINDINGS` as the one roster and pins four structural facts about it.
- **A platform-dependent string in a portable artifact resolves when the deck is VIEWED, never when it is built.** Whoever sees the wrong text is never whoever built the deck.
- **No fallback message names as its remedy the case in which it fired.**
- **An external suite asserts on our built-in themes and we cannot see it fire.** Gtools renders a deck under every built-in prez declares and asserts the artifact carries no hex from their brand palette -- nine values we must not hold, because hv's zero-knowledge rule makes that check structurally impossible on our side. The coupling is forced, not chosen: if a future Utilz built-in happens to use one of those nine hexes, their suite goes red and we will have done nothing wrong. Currently clean, seven built-ins, zero hexes each.

## 29 Jul 2026 -- repo-wide shell audit + issues 0003-0005 (no release)

Landed after the v2.4.0 tag, so it ships with the next release. Two phases, both prompted by hv: an audit ("are there other dumb things in there I have missed?") and then a health check ("is Utilz good?") that turned up three more defects while reading.

- **57 shellcheck findings including 3 hard errors -> 0.** Commits `cf45371`, `1cb66b2`, `ad6402d`.
- **Four real defects that no tool found** -- these came out of reading, and shellcheck was clean on all four afterwards as well as before:
  - **`clipz` copied nothing and reported success.** `local copy_cmd=$(get_copy_command) || exit 1` never fires: `local` returns its own status, so the `||` tests the declaration. With `copy_cmd` empty, `$copy_cmd < "$input_file"` is a bare redirect -- it runs nothing and exits 0. clipz printed an error, copied nothing, and exited 0.
  - **`syncz execute_delete` reported success on failure.** `rsync "${delete_args[@]}" || true` followed by an unconditional `success "Delete complete"`, twelve lines from an `execute_sync` that already had the correct 0/23/else convention. Now mirrors it.
  - **`mdagg` carried a dead, broken, duplicate `--version`.** Unreachable (the header sources `common.sh` and exits 1 if absent), would have died on a top-level `local` if it were reachable, and hardcoded a stale `v1.0.0`.
  - **`cleanz`'s trope detector stopped detecting silently.** It collapsed grep exit 2 (invalid regex on this platform) into "no match", so a broken pattern reported clean. Note the adjacent `data_attrs=$(...) || data_attrs=0` is load-bearing, not a bug: grep exits 1 on no match and pipefail propagates it, so a naive split there would abort cleanz on text _without_ data attributes.
- **CI's shellcheck step could never fail the build.** It collected only executables, so `opt/utilz/lib/common.sh` (0644, sourced by every utility) had **no static analysis at all** -- 15 of the 57 findings had accumulated there unseen -- and the step ended with `|| echo "(non-blocking)"`. Now collects `*.sh` too, uses `-perm -u+x` for BSD portability, builds an array rather than a word-split string, fails loudly if the collection is empty, and **blocks**. Sequenced last (`0566bcc`) so turning it on never reddened CI.
- **`ensure_venv()`** extracted from pdf2md + xtrct (Highlander).
- **Issues 0003-0005** (`fe8eecf`), three dispatcher/doctor defects found by reading `bin/utilz`:
  - **0003**: `utilz --version`, `--help` and `-h` each exited 1 with "Unknown command". Only the bare words worked -- while all 13 utilities accept the flag forms and the nested `integration`/`emacs` verbs accept them too, making the framework's own front door the one place the conventional spelling failed. Fixed by widening the existing case arms (aliases, not a second code path). `-v` stays unbound by design and is now pinned by a test.
  - **0004**: the "Installed utilities" list on the unknown-command path was a **sixth** open-coded walk of `bin/*`, missed by ST0009/WP-01 because that sweep grepped `common.sh` and this copy lives in `bin/utilz`. It carried the exact `-L`-only drift ST0009 existed to remove: a stray symlink was suggested as a utility while `utilz list` correctly omitted it. Now consumes `each_utility()`; column width computed rather than a hardcoded run of spaces, so descriptions align.
  - **0005**: doctor check 4 was `echo "$PATH" | grep -q "$UTILZ_HOME/bin"` -- one expression, two faults. It recognised only a literal `$UTILZ_HOME/bin` PATH entry, so a working symlink install reported "Found 1 issue(s)"; and it matched by unanchored regex, so `/opt/Utilz/binaries` satisfied a test for `/opt/Utilz/bin`. Now an exact PATH-element match with a fallback scan for a `utilz` that is `-ef` the dispatcher. `-ef` compares device and inode _through_ symlinks, so no resolver was added -- the only one, `determine_utilz_home`, cannot be reused because it runs before `common.sh` is sourced (it is what finds `common.sh`).
- **Tests 395 -> 407.** 12 new across `dispatcher.bats` and `common_lib.bats`, **6 genuinely red before the fix**; the 6 that passed from the start are deliberate (they pin `-v` staying unbound, a real utility still listed, and doctor's two already-correct PATH branches).
- **Method note worth keeping.** A false "all 15 clean" was reported early in the audit because `shellcheck -x $FILES` ran under zsh, which does not word-split unquoted variables: shellcheck got one bogus path, errored, and the empty output read as a pass. Real count under bash was 57. Verify shell tooling under `/bin/bash` with an array.

## 29 Jul 2026 -- Utilz v2.4.0 (framework core: one walker, one parser, derived generator floor)

- **ST0009** (3 WPs): three defects in the framework core, landed together because they share `opt/utilz/lib/common.sh`. Found and fixed **inline by the `cc` node of the Cdsync project**, hv-instructed, while reading Utilz as a reference implementation for its own dispatcher -- so the code preceded the paperwork. ST0009 supplied the documentation, the test coverage, the doc reconciliation, and the release.
  - **WP-01 `each_utility()`**: `list_utilities`, `run_doctor` (x2), `run_tests`, `emit_integration_tsv`, `emacs_doctor` each open-coded the same walk of `bin/*` and had **already drifted** -- two verified the symlink resolved to the dispatcher, three accepted any symlink, so a stray link was a utility to `doctor` and not to `list`. Collapsed to one walker (Highlander), consumed via process substitution so accumulator arrays survive the loop.
  - **WP-02 `require_yq()`**: `get_util_metadata` carried two parsers -- `yq` and a grep fallback answering four hardcoded queries with an empty string for everything else, indistinguishable from an absent key. Fallback removed; **`yq` is now a hard dependency**, declared in `opt/utilz/utilz.yaml`. `utilz doctor` deliberately still completes without it, because that is the command you run to discover it is missing.
  - **WP-03 generator floor** (issue 0002): `metadata.tmpl` hardcoded `utilz_version: "^1.0.0"` while `VERSION` read 2.3.0, so every generated utility was born incompatible. Now derived from `VERSION` via a `{{UTILZ_FLOOR}}` placeholder. Latent -- all 13 utilities already carried `^2.0.0`, so nothing in the repo was ever broken by it.
- **Tests**: 12 new in `opt/utilz/test/common_lib.bats` (41 total). Red-first proven **retrospectively** -- run against `HEAD` in a scratch copy, where **11 of 12 fail**. Highest-value: the drift regression (a stray `bin/` symlink must be invisible to `list` **and** `doctor` -- old code disagreed between them), and "the yq hint prints once, not once per utility", a regression test for a defect hit mid-work where `require_yq` memoised into a variable that cannot survive command substitution.
- **Docs**: `docs/architecture.md`, `help/utilz.md`, `README.md` reconciled -- `yq` as a framework-level hard requirement rather than mdagg-specific, `each_utility`/`require_yq` in the library reference, and the correction that utilities do **not** call `get_util_metadata()` (no callers outside `common.sh`).
- **Bash floor corrected 4.0+ -> 3.2** across 10 files (README, help, 8 utility READMEs, workflows README). One instance remains in `AGENTS.md:13` and is not fixable here -- it is an unconditional `echo` in Intent's own generator, raised as **Intent issue 0008**.
- **Whiteboard to Lamplight/Baize standard**: `hv` node provisioned (Workstream Zero, present in every Intent project), hand-authored roster `README.md`, cross-project correspondence rules recorded.
- **`elixir` dropped** from `languages` -- declared but never used in a pure-bash project, and loading two Elixir skills into every session.
- Bumped VERSION 2.3.0 -> 2.4.0 (minor, not patch: `yq` optional -> required is user-visible); tagged `v2.4.0` on both remotes.

## 10 Jul 2026 -- Utilz v2.3.0 (todo utility release + mdagg fix)

- **todo v1.0.0** (ST0008): standalone DOING/TODO/DONE `todo.md` manager, forked from `intent todo` and made steel-thread-independent (the file is the source of truth). Positional item numbers, history sweep/purge, `--json`, `-g`/global + `--file` precedence. `utilz todo <-> intent todo` **mutual guard** (WP-08): stamps `generator: utilz todo`, refuses to clobber an Intent-owned `todo.md`, but only when Intent is actually present (stays a zero-dependency standalone tool).
- **mdagg issue 0001 fix**: silent Unicode line-drop under a C locale (`[←↑]` byte-class degradation) fixed with an anchored, byte-safe grep + a tightening to genuine link lines; portable POSIX-awk title-case replaced the GNU-sed `\b`/`\u` (a no-op on BSD sed → un-cased titles on macOS); duplicated title derivation extracted into `derive_title()` (Highlander). Regression tests under `LC_ALL=C`.
- **File-based issue tracker** at `intent/issues/` (`OPEN/` / `CLOSED/` / `_templ/`); issue 0001 recorded + CLOSED.
- **CI**: `expz` added to the Ubuntu test loop (its BATS suite is offline; no `ANTHROPIC_API_KEY` needed).
- Bumped VERSION 2.2.0 → 2.3.0; tagged `v2.3.0` (both remotes).

## 23 Apr 2026 -- Utilz v2.2.0 (Emacs bridge, ST0007)

- **Editor-integration surface**: `integration:` YAML block on all 12 utilities; `utilz integration commands` (editor-neutral TSV manifest, single Highlander walker `emit_integration_tsv`); `utilz emacs {install,doctor}`.
- **Emacs bridge** (`static/emacs/utilz.el`): `M-x utilz` completing-read menu (Vertico); resolves input/output per each utility's declared kinds; non-zero exit pops stderr and leaves text untouched (No Silent Errors). Live Doom E2E + 34-test batch E2E green.
- Project-wide 4-space → 2-space bash reindent (32 files, mechanical).
- Bumped VERSION 2.1.1 → 2.2.0; tagged `v2.2.0`.

## 25 Mar 2026 -- expz v1.0.0 (Utilz v2.1.0)

- Added expz utility: batch expense receipt PDF extraction to CSV
  - Recursively finds PDFs in category subdirectories
  - Extracts structured data via xtrct (Claude API) using JSON schema
  - Outputs CSV: Date, Category, Supplier, Description, Currency, Subtotal, VAT, Total, Reference, File
  - Category derived from parent directory name
  - Bundled default schema at `lib/expense_schema.json`, overridable with `--schema`
  - JSON array normalisation fix (handles array responses from xtrct)
  - 9 BATS tests, all passing
- Bumped VERSION from 1.3.2 to 2.1.0
- Updated all 12 utility YAMLs: `utilz_version` from `^1.x.x` to `^2.0.0`
- Fixed integration test for v2.x version compatibility
- Updated README.md, CHANGELOG.md, help/expz.md
- GitHub release: https://github.com/matthewsinclair/utilz/releases/tag/v2.1.0

## 02 Mar 2026 -- syncz v2.0.0 (Utilz v2.0.0)

- Unison backend for bidirectional sync
- Falls back to rsync when unison not installed
- 12 new tests (78 total)

## 02 Mar 2026 -- syncz v1.4.0 (Utilz v1.3.2)

- Safe orphan defaults in --bidi mode
- Bare --bidi keeps orphans, syncs to both sides
- --bidi --delete shows irreversibility warning

## 19 Feb 2026 -- lnrel v1.0.0 (Utilz v1.3.1)

- Portable relative symlinks via GNU realpath
- 12 tests

## 12 Feb 2026 -- pdf2md v1.0.0 + xtrct v1.0.0 (Utilz v1.3.0)

- pdf2md: PDF to Markdown converter using pdfplumber
- xtrct: Schema-driven semantic data extraction via Claude API
- Composable pipeline: pdf2md | xtrct

## 10 Feb 2026 -- syncz v1.3.0 (Utilz v1.2.1)

- Bidirectional sync mode (--bidi) with orphan detection
- --confirm optional argument for scriptable operation

## 08 Feb 2026 -- syncz v1.2.0 (Utilz v1.2.0)

- Directory-to-directory syncer wrapping rsync
- Conflict resolution, confirmation modes, dry-run, backup
- 45 tests

## 28 Dec 2025 -- cleanz v1.1.0 (Utilz v1.1.0)

- LLM text cleaner + C2PA image metadata stripping
- 46 tests

## 12 Nov 2025 -- Utilz v1.0.0

- Initial release: dispatcher, common library, generator, test runner
- clipz, cryptz, gitz, macoz, mdagg, retry
