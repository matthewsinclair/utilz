---
node: cc
name: Control Claude
role: control
session_id: 5d94b174-72a1-4eca-9eb0-674adfd6414d
heartbeat_at: 2026-09-03 13:00Z
status: active
focus: "ST0011 (stampz) opened and WP-01 in flight -- the Lamplight PDF pack watermarker promoted into Utilz. Renderer decision made on measurement: native PDF, no Chrome, no network."
claims: [ST0010, ST0011]
---

# Control Claude (cc)

## DOING

**ST0011 (`stampz`) -- promoting Lamplight's PDF pack watermarker into Utilz. WP-01 in flight.** hv's call, routed by `lamplight-ac` on 2026-09-03 with the reference left in place (`Lamplight/design/system/docs/bin/stamp-pack.sh`, `fc31caf6a`). Name is hv's: `stampz`, chosen over `markz` because `mark` reads as _markdown_ in a roster that already has `mdagg` and `pdf2md`. Thread opened, objective + context + `design.md` written, 11 ACs and 10 ATs minted, six WPs created.

**THE RENDERER IS NATIVE PDF, NOT CHROME, AND THAT IS THE WHOLE PROMOTION.** The reference needs headless Chrome at a hardcoded `/Applications/...` path and pulls JetBrains Mono from a CDN, so it runs on one platform, online, and nowhere else -- and neither CI leg has Chrome. Spiked the alternative before planning: a 794-byte hand-built stamp page (base-14 Courier-Bold, rotation in the text matrix, alpha via ExtGState) overlays correctly and measures **0.67% of pixels changed on a white page, 0.94% on a near-black one**. It also deletes the 96/72 px-to-pt trap outright, because the stamp is authored in points.

**MY OWN SPIKE PRODUCED THE MEASUREMENT DEFECT THIS THREAD IS ABOUT.** The first visibility check counted pixels differing anywhere on the page and called the **underlay** build -- the one that must be invisible -- visible at 0.30%. Diagnostic: 468 differing pixels, one per row across 468 of 469 rows, every delta exactly 83. A single-pixel column down the page edge, a rasteriser seam, not the mark. **A whole-page pixel-diff greens the wrong verb.** AC02 and AT01 are written to crop to the centre band before counting, and AT02 keeps the underlay control as a test that can go red.

**Open and hv's, not mine to decide:** the reference stamps **in place** by default, which is safe in Lamplight only because the originals regenerate. `design.md` 2.1 proposes inverting it (out-dir default, explicit `--in-place`) and AC03 is written against the proposal; it moves with hv's ruling rather than being quietly dropped.

**ST0010 -- my build side is all landed; vc owns the remainder.** Gate at 16/20 (AC15, AC16, AC18, AC19 outstanding). Untouched today.

## TODO

- **ST0011/WP-02 next: the native stamp renderer.** Byte offsets for the xref are MEASURED (`wc -c` before each append), never computed from `${#s}`, which counts characters rather than bytes and is correct only under `LC_ALL=C` on a pure-ASCII recipient. Do not fall back on letting qpdf reconstruct a bogus xref: it repairs with a warning and exit 3, and a silent-repair dependency in this thread would be self-parody.
- **ST0011/WP-05 must add `stampz` to the hardcoded roster in `test-linux`.** `test-macos` derives its roster from `utilz list` and picks it up for free; Linux does not, and nothing reports the gap. Both legs need `qpdf` + poppler installed so the suite's skip path is never the path CI takes.
- **WP-04 is vc's**, on hoist-green. WP-05 (polish), WP-06 (AC15 theme addressing split), WP-07 (possibly un-deferred: two consumers now blocked by prez keeping its browser list and determinism probe private -- vc has it with hv).
- **`prez build examples/demo.md` warns `class 'escape' has no effect`** -- prez's own example ships a warning. vc's WP-05 note, deck content, not urgent.
- `ST0007/WP-04` is `wip` under a completed thread. Not the migrator: the v2 source itself says WIP. Ours to fix, small.
- **`hoist-rebase.sh` carries one dead postcondition.** `post "test/acceptance.sh" "AT13: PASS" 0 ...` sets the minimum to ZERO and `post()` tests `-ge`, so it prints `ok` unconditionally -- including at a count of zero, which is the case it exists to catch. Redundant rather than a hole: two other checks cover AT13 and both go red. But it is the measures-nothing shape sitting inside the script that guards against silent loss. Fix is `0` -> `1` and a re-attach; held because re-attaching writes canon while vc has the store open.
- **ST0002's six WPs read `not-started`** under a thread completed 2026-02-08 -- the v3 migrator defaulted them and `intent doctor` reports nothing. hv ruled not-today.

## Watch-outs

**Measurement discipline -- the class this project keeps hitting.** Every one of these produced a green that meant nothing.

- **A check placed before the thing it measures passes for the wrong reason.** Two "the terminal stays clean" assertions sat above the loop that waits for the stub to run. The red-first run is what exposed it: the other three checks failed and these two did not, which is the tell.
- **A red-first probe that did not APPLY is not a red-first proof.** Three of mine patched the wrong function, changed nothing, and the test passed for the wrong reason. Assert the patch landed before trusting the red.
- **A grep-based check must target a string the artifact can only contain if the thing is really there** -- a sentinel, a library-internal symbol, a size gap. Never a token the deck might legitimately discuss. This class has bitten five times.
- **A source-grep check can match itself.** A test grepped its own file via `include_str!` and failed forever, because it contains the word it looks for. Assert on the ARTIFACT instead.
- **A test that only runs on a synthetic fixture is half a test.** Both AT17 probe defects surfaced the moment it was pointed at the shipped decks.
- **Never pipe a command whose exit code is the assertion.** `$?` is the last stage's. Bit me twice today and vc twice.

**This tree has THREE concurrent writers: me, `vc`, and `hv`.**

- Commit with an explicit pathspec, never `-A` over the whole tree. A `git status` from earlier in a session is not a stable baseline; remotes and `bin/devbin` have both moved mid-session.
- **`intent st attach` writes canon and regenerates views**, so it is not private when a peer has the store open. Check `git status -- intent/.canon` BEFORE attaching.
- **Run prettier yourself before committing markdown.** Otherwise the pre-commit hook is an unnamed third writer, and `git commit --only` leaves a phantom staged diff (`git restore --staged` clears it). `git add` + plain `git commit` avoids it entirely.
- A peer node in ANOTHER project may edit this tree; Cdsync's `cc` did on 2026-07-29.

- **The browser gate in the prez acceptance suite is an ENVIRONMENT VARIABLE, so its absence is invisible.** `utilz test` drives `acceptance.sh --strict`, and with `PREZ_TEST_BROWSER` unset `chrome()` probes, finds Chrome, and AT04/AT07/AT08/AT12 each launch it. The override does not survive a new shell, so the same command is browserless in one terminal and browser-driving in the next with nothing said either way. Every launch does carry `--use-mock-keychain` via `$CHROME_SAFE`, which is what keeps the Safe-Storage modal off hv's screen. If a run must be browserless, set the variable in that shell and check it landed.

**Shell and tooling.**

- **A `grep` whose SUCCESS is "no matches" kills a `set -euo pipefail` script** -- grep exits 1, pipefail propagates, and the script dies at the moment it succeeded, silently, after earlier steps wrote to disk. Guard with `{ grep ... || true; }`.
- **`utilz help <anything>` HANGS when stdin is a TTY** (glow's pager -- `mdagg` does it too). It bites `bats --filter` from a terminal and looks like the test hung. `< /dev/null` fixes it; `utilz test` and CI never see it.
- **`utilz test` is not safe to run concurrently** -- the helper mutates `$UTILZ_HOME/bin`. One suite at a time. `pgrep -fl bats` matches peer Claude sessions, not just real suites.
- Verify shell tooling under `/bin/bash` with an ARRAY. zsh does not word-split, so `shellcheck -x $FILES` errors on one bogus path and the empty output reads as a pass -- a false "all 15 clean" against 57 real findings.
- Do not use `perl -0pi -e` where the text contains `$(` -- Perl interpolates it as GID and corrupts the file.

**Framework internals.**

- **`each_utility()` has six consumers, one in `bin/utilz`.** The no-seventh-copy check is `grep -rn 'UTILZ_HOME"/bin/\*' bin/utilz opt/utilz/lib/common.sh` -- exactly two hits.
- `each_utility()` must be consumed with process substitution, never a pipe: `run_doctor` and `run_tests` accumulate into arrays and a pipe subshells the loop body.
- `require_yq` ONCE before a loop, never per-iteration -- `get_util_metadata` runs in command substitution and cannot memoise.
- `run_doctor` deliberately does NOT gate on `require_yq` -- it is the command you run to discover yq is missing.
- **`prez --version` and `--help` never reach the shim** -- the dispatcher answers from `prez.yaml`. A test meaning to exercise the binary must use a real verb.
- **`examples/demo.md` does NOT opt into mermaid** (its `mermaid: true` is documentation inside a fence). Point diagram checks at `test_pres.md`; demo.md is the labelled negative control.
- mdagg strip + title-case are locale/BSD-sed sensitive -- `intent/issues/CLOSED/0001`. Match multibyte literals with `grep -F` or an ERE alternation, never a character class.
- todo guard: utilz `item_re` parses intent's `- [x] STID: title` lines as items, so `utilz todo sync` on an intent file would clobber it. The STAMP is unconditional; the REFUSAL fires only when intent is present.
- No Claude attribution in commits, ever. Commits end with `(C) hello@matthewsinclair.com`. 2-space indent, bash 3.2, no em dashes, column-aligned tables.

## Decisions

- (2026-07-29) `-v` stays **unbound** on the `utilz` dispatcher. It reads as a verbose flag and no utility binds it, so binding it to `version` would foreclose the obvious future use. Pinned by a test asserting it still fails, so the next "while we're here" change has to argue with a test rather than quietly take the name.
- (2026-07-29) A set of small, independent, already-diagnosed defects may be driven by one issue each rather than a steel thread, even when fixed in a single commit -- extending the 0001/0002 precedent from one issue to a batch. The commit body carries the narrative; each issue carries its own root cause, evidence and resolution. Doc-before-code still holds for feature work.
- (2026-07-29) Whiteboard brought to the Lamplight / Baize standard: `hv` provisioned via `intent claude ws new hv` (Workstream Zero is present in every Intent project), plus a hand-authored `README.md` roster. Roster deliberately stays at two nodes -- Utilz is single-stream, and nodes are made to order, not in anticipation. An external correspondent (`cdsync-cc`) gets an inbox but no node directory, because it has no workstream here.
- (2026-07-29) A shipped defect fixed inside a steel thread still gets its own `intent/issues/` entry (0002 alongside ST0009/WP-03), following the 0001 precedent. The ST carries the work; the issue carries the defect record.
- (2026-07-29) Retroactive paperwork is the remediation for a doc-before-code violation when the code is already correct and verified -- not reverting it. Red-first is then proven retrospectively by running the new tests against `HEAD` in a scratch copy, and the retrospective verification is stated as such in `acceptance.md` rather than presented as genuine red-first.
- (2026-07-10) A tracked issue in `intent/issues/` may drive a focused bugfix without a full ST (hv-approved for issue 0001). Doc-before-code still holds for feature work.
- (2026-07-09) todo guard's Intent-project test is anchored on the **target file's directory** (walk up from `dirname($TODO_FILE)`), NOT cwd. Deliberate divergence from Intent's cwd-based `find_project_root`: the guard protects the file being overwritten, so `--file`-ing at another project's `intent/todo.md` from outside still refuses. Own/unmarked files short-circuit before the project test. (hv-confirmed.)
