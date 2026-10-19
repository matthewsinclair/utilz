---
node: cc
name: Control Claude
role: control
session_id: 9abbea6b-9526-4af1-9e02-92a33e698b9c
heartbeat_at: 2026-10-19 10:36Z
status: active
focus: "19 Oct: banked and localfolded for hv's compact, during the Gtools cut's step 5. 0081 (aeae4f63) and 0085 (2a49ec86) approved, in wt-0081 and wt-0085; slots 126 to 128 queued with gtools-vc; dc's kovacs leg after the compact; the landings follow 0082's. 0083's prez part designed and approved. Resume per the new hold."
claims: [ISSUE:0077, ISSUE:0079, ISSUE:0080, ISSUE:0081, ISSUE:0084, ISSUE:0085, ISSUE:0087]
---

# Control Claude (cc)

## DOING

- 0077 (vc, S) landed at 2023828 on 0150478 (19 Oct 07:06Z), by path through the gate, no push. It is 7 files from 5391226b plus its CHANGELOG line, verified by dc in slot 73. Left: the close, with its resolution, on vc's word after hv's push and CI's run. (edited)

- 0079 (vc, S) landed at 2d73b7f on 64acf18 (19 Oct 07:42Z), by path through the gate, no push: 7 paths, diff 682baa48, the patch install_e2e.bats saw green in the primary in slot 78 on bash 3.2.57 and bash 5.3.20. vc verified it by change; dc's slot 81 found 2023828 and 2d73b7f together make 5391226b and nothing else. Left: the close, with its resolution, on vc's word after hv's push and CI's run. (edited)

- 0080 (vc, M, medium) landed at fb5608f on 9d730f6 (19 Oct 09:31Z), by path through the gate, no push: 10 files, diff 08fe44c7, cleanz 1.2.1. It was red in slots 88 and 101 (with six mutation controls), green in 90, 104, 110 and 113 on this Mac, and green on kovacs in dc's slot 109. critic-shell's four warnings were fixed and vc read 494b26ca. The SHA went to vc and dc. Left: the close, with its resolution, on vc's word after hv's push and CI's run. (edited)


## TODO

- 2.14.1 cut role (vc, 19 Oct 05:29Z): after hv's tag, tools/formula-bump 2.14.1 and its commit, the formula copied into the tap clone, brew audit --strict there. The tap push is hv's.
- 0081 (low, cc's): get_util_metadata reads a yaml yq cannot read as an absent field. Design approved with vc's items 8 and 9, and critic-shell's review answered by amendments 10 to 17, approved by vc and in the body at f6d2040. Candidate aeae4f63 (7 files) in wt-0081, detached at d7166e4; wt-0081-ctl beside it at d7166e4 for the red and mutation phases. Queued with gtools-vc for after the Gtools cut's step 5: slot 126, light (light-0081b.sh: red on main's code and on 3ca98607's, three mutations, 19 green, shellcheck and the critic), and slot 127, heavy (green-0081b.sh, the utilz suite, 1..270, both bashes). Then the bytes to vc, dc's kovacs leg on them, and the landing by vc's steps: re-apply on the head (land-0080.sh adapted, CHANGELOG last in Fixed), compare by change, install_e2e booked heavy, one commit by path, no push, the SHA to vc and dc, who builds 0083 on it. (edited)

- 0083's prez part (items 7, 15, 16; utilz-cc's): present falls back to open on macOS and xdg-open elsewhere, through fallback_opener(os, lookup, no_browser), and refuses by name, exit 2, when neither a browser nor the opener is found. Design items 20 to 24 drafted (0083-prez-design.md) and sent to vc for its read; into 0083's body after the cut's step 5, carrying prettier's one blank line before item 19. Then red first on a build that keeps main's behaviour, green, check all, prez 2.5.2, dc's kovacs leg for the crate's tests. Lands third, after dc's and utilz-ic's parts. (edited)

- 0084 (low, cc's): seven tests of a missing tool's refusal skip wherever the tool is installed. Design approved (path_without, a farm of links, one ln per PATH directory, last to first; proof by mutation and a farm control; the farm made once per test under BATS_TEST_TMPDIR; the header says the per-directory glob stays inside ARG_MAX). Built on 0082's head once it lands, since 0082 changes test_helper.bash, cryptz.bats and macoz.bats; after 0085 (vc's order: 0081, 0085, 0084, 0087). (edited)

- 0085 (low, cc's, XS): a dependency entry written as a bare string is checked as a dependency with no name. Design approved, and amendment 7 (a list entry ended doctor at the bare name read, 0053's class) at a5a9153. Bytes 2a49ec86 (4 files) approved by vc, built on 0081's aeae4f63 in wt-0085 (aeae4f63 staged as the base; 0085-candidate.diff). Slot 128 with gtools-vc, light (light-0085.sh: 3 red on 0081's code, 22 green), after the cut's step 5. dc's kovacs leg may share 0081's bundle. Lands straight after 0081 (vc), re-applied on its head, install_e2e at the landing. (edited)

- 0087 (low, cc's, XS): doctor's [5/7] calls every utility properly configured having read no yaml, for a utility with none and when yq is missing. Filed on vc's word at bfd86cd, from critic-shell's review of 0081. Design after 0084, whose path_without its no-yq test needs, built on 0081's [5/7]; then vc's read, red first, booked runs.


## Holds

- Banked for hv's compact (19 Oct, during the Gtools cut's step 5, begun 10:28:46Z). Condition: my compact is done, then /in-session and pickup. gtools-vc holds the host queue; the Mac is closed until step 5 ends, and each GO comes from gtools-vc by socket. Resume in this order, from the scratchpad /private/tmp/claude-501/-Users-matts-Devel-prj-Utilz/9abbea6b-9526-4af1-9e02-92a33e698b9c/scratchpad:
  (1) Slots 126, 127 and 128, STARTed to gtools-vc and queued after step 5. On each GO, under 3.2 then 5. 126: light-0081b.sh (0081's red on main's code and on 3ca98607's, three mutations, 19 green), then shellcheck-ci.sh on wt-0081 and intent critic shell on its two libs. 127: green-0081b.sh (the utilz suite, 1..270, 2 skips). 128: light-0085.sh (3 red on 0081's code, 22 green). Each END goes to gtools-vc, and the results to vc. If 126 or 127 goes red, tell dc before its kovacs GO.
  (2) dc's kovacs leg on 0081's aeae4f63 (recorded as c0081-aeae4f63), with 0085's 2a49ec86 if dc bundles it, booked with gtools-vc after hv's compact. Results to cc and vc.
  (3) 0081's landing, after dc lands 0082. land-0081.sh <head> apply in the primary applies hunks for a path main moved (the developer guide, which 0082 touches), copies the rest, and compares by change. Then e2e-0081.sh, STARTed heavy to gtools-vc. Write m-fix-0081.txt with the slots, then land-0081.sh <head> commit, no push, and send the SHA to vc and dc, who builds 0083 on it.
  (4) 0085's landing straight after 0081 (vc's order), re-applied on 0081's head: land-0085.sh, written from land-0081.sh for wt-0085 (2a49ec86 over aeae4f63), with install_e2e booked heavy.
  (5) 0083's prez part, its design in 0083's body (items 20 to 24, approved): build it in a new worktree at main's head, starting with the red stub. Then the tests, the function, help/prez.md:273, prez 2.5.2 and CHANGELOG; cargo tests and bin/devbin check all, STARTed heavy. It lands third, after dc's and utilz-ic's parts.
  (6) 0084 on 0082's head once 0082 lands (todo 36), then 0087's design (todo 38).


## Watch-outs

- hv's rule: a gap in devbin's vendored release core (bin/.devbin/lib/release*) is fixed in devbin, as a default with an override, through vc to devbin-dc or devbin-2b. Never patch the vendored copy or add a Utilz-only branch. Vendored line numbers move with each devbin sweep: re-read a citation before trusting it.
- A green suite says nothing about Rust formatting or clippy: run bin/devbin check all before handing a Rust change to vc, to CI or into a cut. cargo fmt --check fails CI ahead of clippy, so fmt drift hides the clippy verdict (0059, 0060). Fix with bin/devbin fmt rust; check all's critic arm reads staged files only. (edited)
- The pre-commit gate lives in .githooks/, read through core.hooksPath (0064). It refuses a staged .md or .rs that is not formatted and never rewrites it: prettier --write <file> or bin/devbin fmt rust, git add, commit again. A store body (an issue, a WP body) must be prettier-stable before intent set or intent issues add, or its view drifts and the doctor gate refuses every later commit. (edited)
- Two rules for 0077 and 0079 (vc, 19 Oct). The candidate lives only in cc's worktree, detached at main's head (scratchpad wt-cc, .githooks/*.intent copied in): never in the primary, which is live for hv's menu and shared with utilz-ic's path commits; the primary takes the patch at each landing. Every START says light or heavy (gtools-vc's light lane): light builds nothing, starts no GUI or daemon, binds no port and writes no state another run reads; any whole suite is heavy.


## Decisions

- hv, 18 Oct 2026, directly to cc, answering cc's finding that CHANGELOG.md's [2.14.1] - unreleased section holds three Added entries (0069, 0070, 0071) and so reads as a minor: "2.14.1". The next Utilz cut is 2.14.1. The CHANGELOG heading and intent/wip.md's TODO (bin/devbin release v2.14.1) already say so, so nothing is retitled.

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
