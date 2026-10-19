---
node: cc
name: Control Claude
role: control
session_id: 9abbea6b-9526-4af1-9e02-92a33e698b9c
heartbeat_at: 2026-10-19 09:54Z
status: active
focus: "19 Oct: banked and localfolded for hv's compact. 0080 landed at fb5608f. 0081 is at 3ca98607 in wt-0081, green in slots 120 to 122, approved by vc pending critic-shell; resume per the new hold. Then 0084, 0085, and 0083's prez part. Nothing on the host."
claims: [ISSUE:0077, ISSUE:0079, ISSUE:0080, ISSUE:0081, ISSUE:0084, ISSUE:0085]
---

# Control Claude (cc)

## DOING

- 0077 (vc, S) landed at 2023828 on 0150478 (19 Oct 07:06Z), by path through the gate, no push. It is 7 files from 5391226b plus its CHANGELOG line, verified by dc in slot 73. Left: the close, with its resolution, on vc's word after hv's push and CI's run. (edited)

- 0079 (vc, S) landed at 2d73b7f on 64acf18 (19 Oct 07:42Z), by path through the gate, no push: 7 paths, diff 682baa48, the patch install_e2e.bats saw green in the primary in slot 78 on bash 3.2.57 and bash 5.3.20. vc verified it by change; dc's slot 81 found 2023828 and 2d73b7f together make 5391226b and nothing else. Left: the close, with its resolution, on vc's word after hv's push and CI's run. (edited)

- 0080 (vc, M, medium) landed at fb5608f on 9d730f6 (19 Oct 09:31Z), by path through the gate, no push: 10 files, diff 08fe44c7, cleanz 1.2.1. It was red in slots 88 and 101 (with six mutation controls), green in 90, 104, 110 and 113 on this Mac, and green on kovacs in dc's slot 109. critic-shell's four warnings were fixed and vc read 494b26ca. The SHA went to vc and dc. Left: the close, with its resolution, on vc's word after hv's push and CI's run. (edited)


## TODO

- 2.14.1 cut role (vc, 19 Oct 05:29Z): after hv's tag, tools/formula-bump 2.14.1 and its commit, the formula copied into the tap clone, brew audit --strict there. The tap push is hv's.
- 0081 (low, cc's): get_util_metadata reads a yaml yq cannot read as an absent field. Design approved with vc's items 8 and 9 (one fault, one count; the list row points at doctor). Built in wt-0081 at d7166e4: red in slot 120 (5 of 5 at their own assertions, both bashes), light green in slot 121 (9 of 9, with 0080's one-count tests). Candidate 3ca98607 (5 files) is read and approved by vc pending critic-shell, which is reading now. Then the heavy utilz suite (slot 122), dc's kovacs leg on the final bytes, and the landing: re-apply on the head, compare by change, install_e2e booked, one commit by path, no push, the SHA to vc and dc, who builds 0083 on it. (edited)

- 0083 (Utilz on Linux, size L, utilz-dc's, approved by vc), its item 7, prez's part, assigned to cc by vc on 19 Oct (09:04Z), after 0080 and 0081. When present finds no Chromium-family browser, it opens with open on macOS and xdg-open elsewhere (opt/prez/crate/src/drive.rs:269), through one small function a unit test pins for both. When neither a browser nor the platform's opener is found, present refuses by name, exit 2, saying what it needs. prez takes a patch bump, and bin/devbin check all runs before it is handed on. It lands third, after dc's and utilz-ic's parts, re-applied on the head. Design first (read intent issues show 0083), then vc's read, red first, booked runs. (edited)

- 0084 (low, cc's): seven tests of a missing tool's refusal skip wherever the tool is installed. vc approved cc's design as written (19 Oct 09:39Z), after 0081: path_without <tool>, a farm of links to everything on PATH but the tool, one ln per PATH directory, last to first; only the verb runs under the farm, and bats keeps its own PATH. Proof by mutation, plus a control that the farm hides gpg while bash, env and cat resolve. Two points for the bytes: the farm is made once per test under BATS_TEST_TMPDIR, so nothing outlives the test; and the helper's header says the per-directory glob stays one argument list, well inside ARG_MAX. It lands after 0082, which also edits test_helper.bash, re-applied on its head. (edited)

- 0085 (low, cc's): a dependency entry written as a bare string is checked as a dependency with no name. cc's design (XS) is approved by vc, refusing a bare string rather than reading it as a name, as the guide documents maps only. Two tests, red first. After 0081 and 0084. (edited)


## Holds

- Banked for hv's compact (19 Oct, after slot 122). Condition: my compact is done, then /in-session and pickup. vc holds the host queue, and every run books with vc until gtools-vc is back. Resume in this order, from the scratchpad /private/tmp/claude-501/-Users-matts-Devel-prj-Utilz/9abbea6b-9526-4af1-9e02-92a33e698b9c/scratchpad:
  (1) 0081: candidate 3ca98607 in wt-0081, detached at d7166e4, saved as 0081-candidate.diff. Red in slot 120, light green in 121, heavy green in 122 (268 on both bashes). vc approved the bytes pending critic-shell's read, which was launched before the compact and reports back to this session; if its report is lost, re-run critic-shell on wt-0081's diff. Fix any finding in wt-0081, re-run light-0081.sh (booked light) and send vc the changed bytes.
  (2) dc's kovacs leg on the final bytes: send dc the diff path and sha256; dc books it with vc.
  (3) The landing, by vc's steps: git status; re-apply on main's head, adapting land-0080.sh to 0081's 5 paths, with its CHANGELOG line last in Fixed, after 0080's; compare by change; START install_e2e.bats to vc, heavy, adapting e2e-0080.sh; one commit by path, writing m-fix-0081.txt, no push; the SHA to vc and dc, who builds 0083 on it.
  (4) 0084's build (todo 36), then (5) 0085's (todo 37), then (6) 0083's prez part (todo 35), which lands after dc's and utilz-ic's parts.


## Watch-outs

- hv's rule: a gap in devbin's vendored release core (bin/.devbin/lib/release*) is fixed in devbin, as a default with an override, through vc to devbin-dc or devbin-2b. Never patch the vendored copy or add a Utilz-only branch. Vendored line numbers move with each devbin sweep: re-read a citation before trusting it.
- A green suite says nothing about Rust formatting or clippy: run bin/devbin check all before handing a Rust change to vc, to CI or into a cut. cargo fmt --check fails CI ahead of clippy, so fmt drift hides the clippy verdict (0059, 0060). Fix with bin/devbin fmt rust; check all's critic arm reads staged files only. (edited)
- The pre-commit gate lives in .githooks/, read through core.hooksPath (0064). It refuses a staged .md or .rs that is not formatted and never rewrites it: prettier --write <file> or bin/devbin fmt rust, git add, commit again. A store body (an issue, a WP body) must be prettier-stable before intent set or intent issues add, or its view drifts and the doctor gate refuses every later commit. (edited)
- Two rules for 0077 and 0079 (vc, 19 Oct). The candidate lives only in cc's worktree, detached at main's head (scratchpad wt-cc, .githooks/*.intent copied in): never in the primary, which is live for hv's menu and shared with utilz-ic's path commits; the primary takes the patch at each landing. Every START says light or heavy (gtools-vc's light lane): light builds nothing, starts no GUI or daemon, binds no port and writes no state another run reads; any whole suite is heavy.


## Decisions

- hv, 18 Oct 2026, directly to cc, answering cc's finding that CHANGELOG.md's [2.14.1] - unreleased section holds three Added entries (0069, 0070, 0071) and so reads as a minor: "2.14.1". The next Utilz cut is 2.14.1. The CHANGELOG heading and intent/wip.md's TODO (bin/devbin release v2.14.1) already say so, so nothing is retitled.

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
