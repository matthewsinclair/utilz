---
node: cc
name: Control Claude
role: control
session_id: 737d3449-c07c-46aa-b88e-17a3524f8b46
heartbeat_at: 2026-10-19 14:01Z
status: active
focus: "19 Oct, localfolded for hv's compact: 0081 landed at bffd04a (slot 133, green); resume with 0085's landing START on it, then 0084 on 0082's head, 0083's prez part and 0087's design (order to confirm with vc); 0080 and 0081 close after hv's push."
claims: [ISSUE:0080, ISSUE:0081, ISSUE:0084, ISSUE:0085, ISSUE:0087]
---

# Control Claude (cc)

## DOING

- 0080 (vc, M, medium) landed at fb5608f on 9d730f6 (19 Oct 09:31Z), by path through the gate, no push: 10 files, diff 08fe44c7, cleanz 1.2.1. It was red in slots 88 and 101 (with six mutation controls), green in 90, 104, 110 and 113 on this Mac, and green on kovacs in dc's slot 109. critic-shell's four warnings were fixed and vc read 494b26ca. The SHA went to vc and dc. Left: the close, with its resolution, on vc's word after hv's push and CI's run. (edited)

- 0081 (low, cc's) landed at bffd04a on 4aa86d6 (19 Oct 13:59Z), by path through the gate, no push: 7 files, v3 85adb87a, each file's change, the CHANGELOG's included, equal to v3's own. Green: slot 126 (light: 8 red on main, 5 on 3ca98607, five mutations, 1..20), 127 (heavy: prez built, the utilz suite 1..271 on both bashes), dc's 130 on kovacs (1..285) and 133 (install_e2e 1..11 on both bashes, in the primary). The SHA went to vc and dc. Left: the close, with its resolution, on vc's word after hv's push and CI's run.


## TODO

- 2.14.1 cut role (vc, 19 Oct 05:29Z): after hv's tag, tools/formula-bump 2.14.1 and its commit, the formula copied into the tap clone, brew audit --strict there. The tap push is hv's.
- 0083's prez part (items 7, 15 and 16; utilz-cc's): present falls back to open on macOS and xdg-open elsewhere, through fallback_opener(os, lookup, no_browser), and refuses by name, exit 2, when neither a browser nor the opener is found. Design items 20 to 24 approved by vc and in 0083's body at a1e0209. Build in a new worktree at main's head under ~/Devel/scratch/utilz-cc/ (the crash took wt-0083p, which held nothing): red first on a stub that keeps main's open-everywhere, then the function; help/prez.md:273; prez 2.5.2 (Cargo.toml and Cargo.lock); one CHANGELOG line. The crate's tests red then green, and bin/devbin check all, each booked heavy with utilz-vc; dc's kovacs leg for the crate's tests. Lands third of 0083's three parts, after dc's and utilz-ic's, re-applied on the head; in vc's order after 0085 and before 0084. (edited)

- 0084 (low, cc's): seven tests of a missing tool's refusal skip wherever the tool is installed. Design approved (path_without, a farm of links, one ln per PATH directory, last to first; proof by mutation and a farm control; the farm made once per test under BATS_TEST_TMPDIR; the header says the per-directory glob stays inside ARG_MAX). Built on main's head, which carries 0082 since 853a947 (it changed test_helper.bash, cryptz.bats and macoz.bats), in a worktree under ~/Devel/scratch/utilz-cc/; after 0083's prez part (vc's order, 19 Oct 12:07Z: 0081, 0085, 0083's prez part, 0084, 0087's design). (edited)

- 0085 (low, cc's, XS): a dependency entry written as a bare string is checked as a dependency with no name. Design approved, amendment 7 at a5a9153. 20561470, re-based on 0081's v3 by 0081's amendment 21, live in ~/Devel/scratch/utilz-cc/wt-0085 over 85adb87a staged. Green: slot 128 (light, 13:49Z: 3 red on 0081's code, 1..23) and dc's 130 on kovacs. Next, its landing START on 0081's commit bffd04a (heavy): land-0085b.sh <head> apply in the primary, e2e-0085.sh under bash 3.2 then 5 (install_e2e 1..11), m-fix-0085.txt's two placeholders filled (130's result and the e2e slot's), land-0085b.sh <head> commit by path, no push, the SHA to vc and dc. Rehearsed at 13:53Z: 20561470 applies on 0081's applied tree, its CHANGELOG line aside, which land-0085b.sh places itself. (edited)

- 0087 (low, cc's, XS): doctor's [5/7] calls every utility properly configured having read no yaml, for a utility with none and when yq is missing. Filed on vc's word at bfd86cd, from critic-shell's review of 0081. Design after 0084, whose path_without its no-yq test needs, built on 0081's [5/7]; then vc's read, red first, booked runs.


## Holds

- Localfolded for hv's compact (vc's word of 13:58Z, on hv's). Condition: hv's compact of this session, then vc's word; nothing STARTs or GOes until after the compacts. Resume, as vc's 13:58Z word lists it: 0085's landing START on 0081's commit bffd04a (heavy: land-0085b.sh, e2e-0085.sh, m-fix-0085.txt with its two placeholders), then 0084 on 0082's head, 0083's prez part and 0087's design; 0080 (fb5608f) and 0081 (bffd04a) close after hv's push and its CI run, each on vc's word. vc's order of 12:07Z put 0083's prez part before 0084, so ask vc which comes first. Worktrees and scripts are under ~/Devel/scratch/utilz-cc/: wt-0081 (85adb87a, landed) and wt-0081-ctl, wt-0085 (85adb87a staged, 20561470 over it) and wt-0085-ctl; the crash's recovery tools and the patches in 20261019/.


## Watch-outs

- hv's rule: a gap in devbin's vendored release core (bin/.devbin/lib/release*) is fixed in devbin, as a default with an override, through vc to devbin-dc or devbin-2b. Never patch the vendored copy or add a Utilz-only branch. Vendored line numbers move with each devbin sweep: re-read a citation before trusting it.
- A green suite says nothing about Rust formatting or clippy: run bin/devbin check all before handing a Rust change to vc, to CI or into a cut. cargo fmt --check fails CI ahead of clippy, so fmt drift hides the clippy verdict (0059, 0060). Fix with bin/devbin fmt rust; check all's critic arm reads staged files only. (edited)
- The pre-commit gate lives in .githooks/, read through core.hooksPath (0064). It refuses a staged .md or .rs that is not formatted and never rewrites it: prettier --write <file> or bin/devbin fmt rust, git add, commit again. A store body (an issue, a WP body) must be prettier-stable before intent set or intent issues add, or its view drifts and the doctor gate refuses every later commit. (edited)
- Two rules for cc's candidates (vc, 19 Oct). Each candidate lives only in cc's own worktree under ~/Devel/scratch/utilz-cc/, detached at its base, .githooks/*.intent copied in: never in the primary, which is live for hv's menu and shared with peers' path commits, and never in the session scratchpad, which the reboot of 12:23:56Z emptied with cc's five worktrees in it. The primary takes the patch at each landing. Every START says light or heavy: light builds nothing, starts no GUI or daemon, binds no port and writes no state another run reads; any whole suite, and any build, is heavy. (edited)


## Decisions

- hv, 18 Oct 2026, directly to cc, answering cc's finding that CHANGELOG.md's [2.14.1] - unreleased section holds three Added entries (0069, 0070, 0071) and so reads as a minor: "2.14.1". The next Utilz cut is 2.14.1. The CHANGELOG heading and intent/wip.md's TODO (bin/devbin release v2.14.1) already say so, so nothing is retitled.

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
