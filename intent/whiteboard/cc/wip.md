---
node: cc
name: Control Claude
role: control
session_id: 67bcef6b-d20d-4bb9-ac53-ff7fbaf2e422
heartbeat_at: 2026-10-16 08:20Z
status: active
focus: "16 Oct: ST0026 WP-04 banked, not closed: two holds stand (estate after intent-vc's END; a clean critic-lua re-pass). Then green AT-04.1..4, wp done, SHA to vc. Taking instructions from vc."
claims: []
---

# Control Claude (cc)

## DOING

_(none)_

## TODO

- WP-05 (--bind): two desk entries for one app on different spaces plan two conflicting bind ops, since plan's bind step is not keyed on app_key (critic-lua fifth pass, plan.lua bind step). Key binds on app_key and refuse one app bound to two spaces, naming both paths. Harmless until bind has a measured route.

## Holds

- ST0026 WP-05 (apply): held until vc sends the WP-05 brief, which waits on two measurements: whether a Dock binding takes at all (the deciding test binds Calculator to a built-in desktop other than its last and needs hv's window), and the drag (hv's hands off). vc verified WP-04 at 00a93b3 (16 Oct). Not yet shown: that any binding, the Dock's own or a defaults write, does anything; vc's 08:54Z result was confounded by Calculator's last window position, and vc retracted it. Measured: the Dock writes nothing beyond app-bindings, so if bindings work, defaults write is enough. (edited)

## Watch-outs

- One suite at a time with vc, and commits by explicit path only: vc's files have sat staged in the shared index while cc committed.
- hv's rule: a gap in devbin's vendored release core (bin/.devbin/lib/release*) is fixed in devbin, as a default with an override, through vc to devbin-dc or devbin-2b. Never patch the vendored copy or add a Utilz-only branch. Vendored line numbers move with each devbin sweep: re-read a citation before trusting it.
- Two claims narrowed on 2026-09-22 by the same mechanism, and it is worth suspecting a third: the INSTRUMENT measured layout extent (or one fixture) and the CLAIM was written about painted extent (or every reel). They agree on every case anybody looks at, so nothing reports the gap until something else goes looking. 0054 and 0055 are both closed that way, and the caveat lives beside the check rather than in the issue alone.
- A green test suite says nothing about Rust formatting or clippy: run bin/devbin check all before handing a Rust change to vc, to CI or into a cut. Six cargo fmt diffs from cc 504825a rode five commits into main on 2026-09-22 under a green 13/13 thread and a green estate, reddened CI and would have refused the cut at step 5. cargo fmt --check fails the CI step AHEAD of clippy, so drift HIDES the clippy verdict rather than adding to it (0059, 0060). check all fixes with bin/devbin fmt rust; note its critic arm reads STAGED files only.
- To learn what a command will do, RUN it in its read-only mode (--dry-run, --check, status). Sourcing its library functions into a shell of your own measures YOUR shell, not the command: cc answered whether the vendored core resolves 2.12.0 by sourcing release_versions into a plain bash -c, got 2.12.0 and success, and was wrong -- the handler runs under set -euo pipefail (cmd/release:24) and release_versions ends its loop with is_semver && printf, which v2.6.1 (last in byte order) leaves at 1. release --minor --dry-run stops at step 1. AND: vc ran cc s probe verbatim and agreed, which is one measurement taken twice, not a confirmation. A repeat of a method cannot find a method error.
- The pre-commit gate is tracked in .githooks/ now, read through core.hooksPath (issue 0064, 39b0af4). It REFUSES a staged .md or .rs that is not formatted and never rewrites it, so fix with prettier --write <file> or bin/devbin fmt rust, git add, and commit again. Edits to .git/hooks/ are no longer read. What still holds from the old watch-out 5: a store body (an issue, a WP body) must be prettier-stable before intent set, or its view drifts and the doctor gate refuses every later commit.
- Before saying the tree is clean, run git status --porcelain --untracked-files=all with NO pathspec and quote the count. On 2026-09-22 cc checked -- docs/ only and twice told vc and hv nothing of its was in the tree, while its board, wip view and four canon events sat uncommitted, and those events alone would have refused the cut at step 2. The narrow answer was true; the claim was wider than what was measured.
- hs IPC limits, measured by vc 16 Oct: the hs client gives up after 4 s by default (receive timeout, exit 69); a long verb that pumps the run loop after that dies silently with hs.ipc 'already recursing' refusals; a 12 s sleep scheduled through hs.timer.doAfter, with the IPC call returning at once, completes cleanly. arngz's CLI already passes -t ARNGZ_HS_TIMEOUT (default 60) to hs, so discover and diff are inside it. WP-05's long operations (apply's launch waits, the re-observes) must not pump the run loop inside the IPC call: schedule them with hs.timer and let the response file be the answer. This becomes a D20 amendment once vc records the spike.

## Decisions

_(none)_

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
