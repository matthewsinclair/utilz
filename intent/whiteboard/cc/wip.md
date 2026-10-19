---
node: cc
name: Control Claude
role: control
session_id: 737d3449-c07c-46aa-b88e-17a3524f8b46
heartbeat_at: 2026-10-19 13:05Z
status: active
focus: "19 Oct, back after the crash (this Mac booted 12:23:56Z; every session and /private/tmp lost): slot 126 had run in full; its END (not green: test 3 is vacuous on main) and what the crash took went to vc at 13:05Z with a three-step recovery. Holding for vc's word: nothing run, edited or committed."
claims: [ISSUE:0080, ISSUE:0081, ISSUE:0084, ISSUE:0085, ISSUE:0087]
---

# Control Claude (cc)

## DOING

- 0080 (vc, M, medium) landed at fb5608f on 9d730f6 (19 Oct 09:31Z), by path through the gate, no push: 10 files, diff 08fe44c7, cleanz 1.2.1. It was red in slots 88 and 101 (with six mutation controls), green in 90, 104, 110 and 113 on this Mac, and green on kovacs in dc's slot 109. critic-shell's four warnings were fixed and vc read 494b26ca. The SHA went to vc and dc. Left: the close, with its resolution, on vc's word after hv's push and CI's run. (edited)


## TODO

- 2.14.1 cut role (vc, 19 Oct 05:29Z): after hv's tag, tools/formula-bump 2.14.1 and its commit, the formula copied into the tap clone, brew audit --strict there. The tap push is hv's.
- 0081 (low, cc's): get_util_metadata reads a yaml yq cannot read as an absent field. Design approved with vc's items 8 and 9; critic-shell's review answered by amendments 10 to 17, approved and in the body at f6d2040. Candidate aeae4f63 (7 files), approved by vc, in wt-0081 detached at d7166e4, with wt-0081-ctl beside it. Slots 126 (light: light-0081b.sh, then shellcheck-ci.sh and intent critic shell) and 127 (heavy: green-0081b.sh, 1..270) are STARTed and booked with utilz-vc. dc's kovacs leg is slot 130, one bundle with 0085, c0081-0085-c04cb597 (7 files, 345 lines): it expects utilz 1..284 (273 plus install_e2e's 11), the 10 new tests ok by name and only slot 124's two skips, and the results come to cc and vc. The landing's START goes to vc once slot 130 is green and dc's 0082 has landed (slot 131): land-0081.sh <head> apply in the primary (git apply for a path main moved, a copy for the rest, every path compared by change), e2e-0081.sh booked heavy, m-fix-0081.txt naming the slots, land-0081.sh <head> commit by path, no push, the SHA to vc and dc. (edited)
- 0083's prez part (items 7, 15 and 16; utilz-cc's): present falls back to open on macOS and xdg-open elsewhere, through fallback_opener(os, lookup, no_browser), and refuses by name, exit 2, when neither a browser nor the opener is found. Design items 20 to 24 approved by vc and in 0083's body at a1e0209. Build in a new worktree at main's head: red first on a stub that keeps main's open-everywhere, then the function; help/prez.md:273; prez 2.5.2 (Cargo.toml and Cargo.lock); one CHANGELOG line. The crate's tests red then green, and bin/devbin check all, each booked heavy with utilz-vc; dc's kovacs leg for the crate's tests. Lands third of 0083's three parts, after dc's and utilz-ic's, re-applied on the head; in vc's order after 0085 and before 0084. (edited)
- 0084 (low, cc's): seven tests of a missing tool's refusal skip wherever the tool is installed. Design approved (path_without, a farm of links, one ln per PATH directory, last to first; proof by mutation and a farm control; the farm made once per test under BATS_TEST_TMPDIR; the header says the per-directory glob stays inside ARG_MAX). Built on 0082's head once it lands, since 0082 changes test_helper.bash, cryptz.bats and macoz.bats; after 0083's prez part (vc's order, 19 Oct 12:07Z: 0081, 0085, 0083's prez part, 0084, 0087's design). (edited)
- 0085 (low, cc's, XS): a dependency entry written as a bare string is checked as a dependency with no name. Design approved, and amendment 7 (a list entry ended doctor at the bare name read, 0053's class) at a5a9153. Bytes 2a49ec86 (4 files), approved by vc, built on 0081's aeae4f63 in wt-0085 (aeae4f63 staged as the base; 0085-candidate.diff), with wt-0085-ctl beside it. Slot 128 (light: light-0085.sh, 3 not ok on 0081's code, then 1..22 ok) is STARTed and booked with utilz-vc. dc's kovacs leg shares 0081's bundle (slot 130, c0081-0085-c04cb597). Lands straight after 0081 (vc), re-applied on its head by land-0085.sh, written from land-0081.sh, with install_e2e booked heavy at the landing. (edited)
- 0087 (low, cc's, XS): doctor's [5/7] calls every utility properly configured having read no yaml, for a utility with none and when yq is missing. Filed on vc's word at bfd86cd, from critic-shell's review of 0081. Design after 0084, whose path_without its no-yq test needs, built on 0081's [5/7]; then vc's read, red first, booked runs.


## Holds

- Slots 126 and 128 (light) and 127 (heavy), STARTed as gtools-vc's queue file records them (~/Devel/scratch/gtools-vc/20261019/todo-queue.md, lines 54, 55 and 59) and carried over to utilz-vc, which books every Utilz run since gtools-vc handed it the queue (vc's message of 19 Oct 12:07Z). Condition: vc's GO for each, which vc gives once hv's localfold-and-compact round across Utilz is done: 126 beside 123, 127 after 123's END, 128 in the light lane. Each runs from the scratchpad under bash 3.2.57 then 5.3.20, and each END, with its results, goes to vc. If 126 or 127 goes red, tell dc before slot 130's GO.

## Watch-outs

- hv's rule: a gap in devbin's vendored release core (bin/.devbin/lib/release*) is fixed in devbin, as a default with an override, through vc to devbin-dc or devbin-2b. Never patch the vendored copy or add a Utilz-only branch. Vendored line numbers move with each devbin sweep: re-read a citation before trusting it.
- A green suite says nothing about Rust formatting or clippy: run bin/devbin check all before handing a Rust change to vc, to CI or into a cut. cargo fmt --check fails CI ahead of clippy, so fmt drift hides the clippy verdict (0059, 0060). Fix with bin/devbin fmt rust; check all's critic arm reads staged files only. (edited)
- The pre-commit gate lives in .githooks/, read through core.hooksPath (0064). It refuses a staged .md or .rs that is not formatted and never rewrites it: prettier --write <file> or bin/devbin fmt rust, git add, commit again. A store body (an issue, a WP body) must be prettier-stable before intent set or intent issues add, or its view drifts and the doctor gate refuses every later commit. (edited)
- Two rules for 0077 and 0079 (vc, 19 Oct). The candidate lives only in cc's worktree, detached at main's head (scratchpad wt-cc, .githooks/*.intent copied in): never in the primary, which is live for hv's menu and shared with utilz-ic's path commits; the primary takes the patch at each landing. Every START says light or heavy (gtools-vc's light lane): light builds nothing, starts no GUI or daemon, binds no port and writes no state another run reads; any whole suite is heavy.


## Decisions

- hv, 18 Oct 2026, directly to cc, answering cc's finding that CHANGELOG.md's [2.14.1] - unreleased section holds three Added entries (0069, 0070, 0071) and so reads as a minor: "2.14.1". The next Utilz cut is 2.14.1. The CHANGELOG heading and intent/wip.md's TODO (bin/devbin release v2.14.1) already say so, so nothing is retitled.

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
