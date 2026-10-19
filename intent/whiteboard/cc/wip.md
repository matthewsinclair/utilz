---
node: cc
name: Control Claude
role: control
session_id: 737d3449-c07c-46aa-b88e-17a3524f8b46
heartbeat_at: 2026-10-19 17:36Z
status: active
focus: "19 Oct, localfolded for hv's compact (freeze): 0084, 0087 and 0083's prez part landed today (faced93, 9ffc601, 80fb661); resume with 0089's landing START (re-applied on 80fb661, adff6ab7), then 0092's design for vc's read."
claims: [ISSUE:0080, ISSUE:0081, ISSUE:0084, ISSUE:0085, ISSUE:0087]
---

# Control Claude (cc)

## DOING

- 0080 (vc, M, medium) landed at fb5608f on 9d730f6 (19 Oct 09:31Z), by path through the gate, no push: 10 files, diff 08fe44c7, cleanz 1.2.1. It was red in slots 88 and 101 (with six mutation controls), green in 90, 104, 110 and 113 on this Mac, and green on kovacs in dc's slot 109. critic-shell's four warnings were fixed and vc read 494b26ca. The SHA went to vc and dc. Left: the close, with its resolution, on vc's word after hv's push and CI's run. (edited)

- 0081 (low, cc's) landed at bffd04a on 4aa86d6 (19 Oct 13:59Z), by path through the gate, no push: 7 files, v3 85adb87a, each file's change, the CHANGELOG's included, equal to v3's own. Green: slot 126 (light: 8 red on main, 5 on 3ca98607, five mutations, 1..20), 127 (heavy: prez built, the utilz suite 1..271 on both bashes), dc's 130 on kovacs (1..285) and 133 (install_e2e 1..11 on both bashes, in the primary). The SHA went to vc and dc. Left: the close, with its resolution, on vc's word after hv's push and CI's run.

- 0085 (low, cc's) landed at 9bb32fa on 3108471 (19 Oct 14:59Z), by path through the gate, no push: 4 files, 20561470, each file's change, the CHANGELOG's included, equal to its own. Green: slot 128 (light: 3 red on 0081's code, 1..23), dc's 130 on kovacs (1..285) and 135 (install_e2e 1..11 on both bashes, in the primary). The SHA went to vc and dc. Left: the close, with its resolution, on vc's word after hv's push and CI's run.
- 0084 (low, cc's) landed at faced93 on 809c3ff (19 Oct 16:29Z), by path through the gate, no push: 9 files, 620d60c7 (3164bffe re-based on 0083's 9ee7d59, path_without taking several tools so 0083's sha256_of test hides both), each file's net change equal to it. Green: 138 and 155 (light, mutations), 142 (heavy, every suite), dc's 159 on kovacs (utilz 311), 158 (the utilz suite whole in wt-0084c, install_e2e 11 on both bashes in the primary). SHA to vc and dc. Left: the close, on vc's word after hv's push and CI.
- 0087 (low, cc's) landed at 9ffc601 on 6c0f6ff (19 Oct 17:02Z), by path through the gate, no push: 3 files, 230012be (8c79a418 re-based over 0083's [5/7] and 0084, both locals kept), each file's net change equal to it. Green: 144 (red on 0084's code, then 17), 155 (72 on 0083's [5/7]), 161 (every suite in wt-0087c, prez's video.sh AT27 re-run alone for timing; install_e2e 11 on both bashes in the primary), dc's 163 on kovacs. SHA to vc and dc. Left: the close, on vc's word after hv's push and CI.
- 0083's prez part (cc's) landed at 80fb661 on 4821541 (19 Oct 17:22Z), by path through the gate, no push: 5 files, 1aa43fbf (e3c76fc9 re-applied), each file's net change equal to it; prez 2.5.2. Green: 147 (red on main's behaviour, then 385 passed, check all), dc's leg 3 and 171 on kovacs (385 passed), 170 (utilz test prez on both bashes, check all, install_e2e 11 on both bashes in the primary). All three of 0083's parts are in (dc's 9ee7d59, ic's c918dec, this). Left: 0083's close, on vc's word after hv's push and CI.


## TODO

- 2.14.1 cut role (vc, 19 Oct 05:29Z): after hv's tag, tools/formula-bump 2.14.1 and its commit, the formula copied into the tap clone, brew audit --strict there. The tap push is hv's.
- 0089 (low, cc's, XS): artifact::path's finders took a file with no execute bit. Design approved. Candidate 9b384e14 in ~/Devel/scratch/utilz-cc/wt-0089 over the prez part staged; green in 168 (red on is_file at its own lines, then 388 passed, check all). Re-applied on 80fb661 by land-0089.sh in wt-0089c: every file the same net change, applied adff6ab7, banked as ~/Devel/scratch/utilz-cc/0089-landing.diff. Next, after the compacts: its landing START (run-land-0089.sh, to write from run-land-0083p.sh: utilz test prez on both bashes and check all in wt-0089c, then the apply and install_e2e on both bashes in the primary), dc's kovacs leg on adff6ab7 before the commit, m-fix-0089.txt to write. (edited)

- 0092 (low, cc's, XS): artifact's theme.rs test helper dir() (:1094) leaves 9 temp dirs in TMPDIR on every cargo test run. Filed at 4821541. Design drafted for vc's read, banked at ~/Devel/scratch/utilz-cc/20261019/0092-design.md: a test-only TempDir guard whose Drop removes the dir, no new dependency, red by a guard probe and the TMPDIR count (9 on main, 0 after). After 0089's landing; built on 0089's commit. (edited)


## Holds

- Localfolded for hv's compact (vc's decision 39), with a freeze: nothing STARTs or GOes until after the compacts. Released by hv's compact of this session, then vc's word. Resume: (1) 0089's landing START on main's head: wt-0089c holds it re-applied on 80fb661 (adff6ab7, banked as 0089-landing.diff); if main has moved, re-run land-0089.sh through LAND_P on the new head first. Write run-land-0089.sh from run-land-0083p.sh (W=wt-0089c, paths path.rs, browser.rs, Cargo.toml, Cargo.lock, CHANGELOG), e2e-0089.sh from e2e-0083p.sh, and m-fix-0089.txt; ask dc for its kovacs leg on the landing bytes; commit after both are green. (2) 0092: send vc the banked design for its read, then write it into the issue, then build on 0089's commit. Landed today, waiting for the close after hv's push and CI: 0080 fb5608f, 0081 bffd04a, 0085 9bb32fa, 0084 faced93, 0087 9ffc601, 0083's prez part 80fb661. Worktrees under ~/Devel/scratch/utilz-cc/: wt-0089 and wt-0089c are live; the rest are landed or superseded. TMPDIR: each utilz-suite run is clean now 0090 has landed; each cargo test run of the prez workspace leaves 9 artifact-theme-<pid>-* dirs until 0092, so remove those of your own runs by literal path.


## Watch-outs

- hv's rule: a gap in devbin's vendored release core (bin/.devbin/lib/release*) is fixed in devbin, as a default with an override, through vc to devbin-dc or devbin-2b. Never patch the vendored copy or add a Utilz-only branch. Vendored line numbers move with each devbin sweep: re-read a citation before trusting it.
- A green suite says nothing about Rust formatting or clippy: run bin/devbin check all before handing a Rust change to vc, to CI or into a cut. cargo fmt --check fails CI ahead of clippy, so fmt drift hides the clippy verdict (0059, 0060). Fix with bin/devbin fmt rust; check all's critic arm reads staged files only. (edited)
- The pre-commit gate lives in .githooks/, read through core.hooksPath (0064). It refuses a staged .md or .rs that is not formatted and never rewrites it: prettier --write <file> or bin/devbin fmt rust, git add, commit again. A store body (an issue, a WP body) must be prettier-stable before intent set or intent issues add, or its view drifts and the doctor gate refuses every later commit. (edited)
- Two rules for cc's candidates (vc, 19 Oct). Each candidate lives only in cc's own worktree under ~/Devel/scratch/utilz-cc/, detached at its base, .githooks/*.intent copied in: never in the primary, which is live for hv's menu and shared with peers' path commits, and never in the session scratchpad, which the reboot of 12:23:56Z emptied with cc's five worktrees in it. The primary takes the patch at each landing. Every START says light or heavy: light builds nothing, starts no GUI or daemon, binds no port and writes no state another run reads; any whole suite, and any build, is heavy. (edited)


## Decisions

- hv, 18 Oct 2026, directly to cc, answering cc's finding that CHANGELOG.md's [2.14.1] - unreleased section holds three Added entries (0069, 0070, 0071) and so reads as a minor: "2.14.1". The next Utilz cut is 2.14.1. The CHANGELOG heading and intent/wip.md's TODO (bin/devbin release v2.14.1) already say so, so nothing is retitled.

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
