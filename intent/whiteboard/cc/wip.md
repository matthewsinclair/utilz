---
node: cc
name: Control Claude
role: control
session_id: 67bcef6b-d20d-4bb9-ac53-ff7fbaf2e422
heartbeat_at: 2026-10-16 09:56Z
status: active
focus: "16 Oct: WP-04 done and verified by vc at 00a93b3. WP-05 (apply on outcome D) briefed and held for after the compact (hold 11). Taking instructions from vc."
claims: []
---

# Control Claude (cc)

## DOING

_(none)_

## TODO

_(none)_

## Holds

- WP-05 apply on outcome D: brief from vc (sent 16 Oct as a session message, not a wb ask, so restated here), START AFTER THE COMPACT on hv's word. Then: read design.md at eeeab48 (apply in order, Display matching, Failures and the report, Measured 16 Oct 2026, D20 amended, D21, D22, D25) and intent ac show ST0026 AC-05.1..7; intent wp start ST0026/05 and claim it. Route D21: move within a display = hold the title bar (hs.eventtap) and press Move-space (symbolic hotkeys 79/81, read, refused if unset) once per step in Mission Control order, let go; across displays = drag over the shared edge onto the target's active space, let go, continue within. Read back each step at 0.5 s (window spaces, display active space, listed at dest not origin); disagreement = failed, exit 1. Port from dc's spike /private/tmp/claude-501/-Users-matts-Devel-prj-Utilz/b6f789ca-4627-4a74-b4cd-bb7c07de9f46/scratchpad/arngz-spike/arngz-spike2.lua (refusals: button or modifier down, pointer moved >40 px, no grab point, no route; cleanup) into arngz.lua, plan.lua pure, credit the spike. No moveWindowToSpace, gotoSpace, Mission Control or bindings; --bind refused as unknown (AC-05.6), so plan's bind step, bind_unread and restart_dock go. Ordinals (D22) from com.apple.spaces SpacesDisplayConfiguration, not allSpaces. Shape (D20): apply scheduled via hs.timer.doAfter held in a global, IPC returns at once, CLI waits on the response file under its own deadline. Launch, wait for a claimable window, place; --no-launch reports. Tests: planner for matching and report/exit (AC-05.2, 05.3); bats + fake hs for --dry-run, exit codes, verb-named desk (05.1, 05.3, 05.7); AT-05.N. AC-05.4/05.5 are acceptance.sh steps vc runs hands-off: NEVER run anything that takes the pointer. Bash 3.2+5, shellcheck, critic-lua 0/0, commit by pathspec in one script. Files: cc owns arngz.lua, plan.lua and their tests and the shim's apply arm; tell dc before touching opt/arngz/arngz and commit it alone. (edited)

## Watch-outs

- One suite at a time with vc, and commits by explicit path only: vc's files have sat staged in the shared index while cc committed.
- hv's rule: a gap in devbin's vendored release core (bin/.devbin/lib/release*) is fixed in devbin, as a default with an override, through vc to devbin-dc or devbin-2b. Never patch the vendored copy or add a Utilz-only branch. Vendored line numbers move with each devbin sweep: re-read a citation before trusting it.
- Two claims narrowed on 2026-09-22 by the same mechanism, and it is worth suspecting a third: the INSTRUMENT measured layout extent (or one fixture) and the CLAIM was written about painted extent (or every reel). They agree on every case anybody looks at, so nothing reports the gap until something else goes looking. 0054 and 0055 are both closed that way, and the caveat lives beside the check rather than in the issue alone.
- A green test suite says nothing about Rust formatting or clippy: run bin/devbin check all before handing a Rust change to vc, to CI or into a cut. Six cargo fmt diffs from cc 504825a rode five commits into main on 2026-09-22 under a green 13/13 thread and a green estate, reddened CI and would have refused the cut at step 5. cargo fmt --check fails the CI step AHEAD of clippy, so drift HIDES the clippy verdict rather than adding to it (0059, 0060). check all fixes with bin/devbin fmt rust; note its critic arm reads STAGED files only.
- To learn what a command will do, RUN it in its read-only mode (--dry-run, --check, status). Sourcing its library functions into a shell of your own measures YOUR shell, not the command: cc answered whether the vendored core resolves 2.12.0 by sourcing release_versions into a plain bash -c, got 2.12.0 and success, and was wrong -- the handler runs under set -euo pipefail (cmd/release:24) and release_versions ends its loop with is_semver && printf, which v2.6.1 (last in byte order) leaves at 1. release --minor --dry-run stops at step 1. AND: vc ran cc s probe verbatim and agreed, which is one measurement taken twice, not a confirmation. A repeat of a method cannot find a method error.
- The pre-commit gate is tracked in .githooks/ now, read through core.hooksPath (issue 0064, 39b0af4). It REFUSES a staged .md or .rs that is not formatted and never rewrites it, so fix with prettier --write <file> or bin/devbin fmt rust, git add, and commit again. Edits to .git/hooks/ are no longer read. What still holds from the old watch-out 5: a store body (an issue, a WP body) must be prettier-stable before intent set, or its view drifts and the doctor gate refuses every later commit.
- Before saying the tree is clean, run git status --porcelain --untracked-files=all with NO pathspec and quote the count. On 2026-09-22 cc checked -- docs/ only and twice told vc and hv nothing of its was in the tree, while its board, wip view and four canon events sat uncommitted, and those events alone would have refused the cut at step 2. The narrow answer was true; the claim was wider than what was measured.

## Decisions

_(none)_

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
