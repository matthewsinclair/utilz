---
node: vc
name: Validation Claude
role: validation
session_id: 74b51d87-af54-4adf-9287-d19216567c43
heartbeat_at: 2026-10-23 20:06Z
status: active
focus: "23 Oct, 2.14.2 cut and published (tag on 54b6262d): reading the release commit's last CI job; then hv's Menuz.app, the formula and tap, brew upgrade here, ic's menuz install, dc's kovacs readback, and done.md. Resume: ~/Devel/scratch/utilz-vc/RESUME.md"
claims: []
---

# Validation Claude (vc)

## DOING

_(none)_

## TODO

- 2.14.2 (vc's decisions 49 to 56) is cut, by hv on 23 Oct: release commit 54b6262d (VERSION and CHANGELOG's date only), annotated tag 2.14.2 (561e0a9d), pushed to local and upstream, and release object 2.14.2 published at 19:44:11Z. The tag's CI run 40013739553 is green on all 8 jobs. The cut's step 11 timed out (ci.wait) on push run 40013730154, whose Rust (ubuntu-latest) job spent 19 minutes installing ffmpeg on GitHub's runner; vc reads its jobs to the end. Next, in order: Menuz.app signed, notarised and published (hv); the formula bump, the tap and its push (hv); brew upgrade and utilz doctor here; ic's todo 8 (menuz install); kovacs's brew at 2.14.2 (kovacs-sysadm on hv's approval), then dc's kovacs readback; cc's hold 44 released; done.md's 2.14.2 entry and the globalfold. (edited)

## Holds

_(none)_

## Watch-outs

- Reading prez's acceptance runs: AT01 asserts the in-crate target, so a run with CARGO_TARGET_DIR redirected reads AT01 red by construction; acceptance.sh:248 builds the tree it runs in, so a red on main runs the new suite in main's own tree; and AT20's window can read 0 wide under load, so re-run AT20 alone before calling it red. (edited)
- Host runs on this Mac and on kovacs, for Utilz and Gtools both, book with utilz-vc (gtools-vc's word, 20 Oct, and again on 22 Oct), on gtools-vc's decision 59 terms: a START (sender, repo, worktree and sha or diff hash, the exact command, what it binds or starts, the expected result, the kill timeout), the GO, which alone starts a run, and an END with the results. Heavy runs go one at a time: any build or compile, any whole suite, Chrome, a dry run or cut, a daemon. One light run (no build, GUI, daemon or port; its own temp dirs only) may share the window with one heavy run at a load under 60, and a timing-like failure in it is rerun alone. A kovacs leg runs beside a Mac run, counted in the load. Bytes that change after a GO send their new hash before the rerun. Before each GO: load under 60, nothing listening on 47600 to 47799, no suite running. Intent keeps its own queue (intent-vc): until hv rules on one queue, the two keepers send each other every heavy GO and END by name, neither GOes while the other's heavy run is in flight, and each alone GOes its own estate's runs, the other naming its gaps at an END with its census (agreed 22 Oct). The day's log is ~/Devel/scratch/utilz-vc/host-log-<date>.md. (edited)
- kovacs is brew-only for Utilz and Intent (hv, 19 Oct): Utilz 2.14.1 from the tap since 20 Oct (dc's readback, 81 ok), with no dev checkout and no link into one. A test leg lives in its own /var/tmp run dir, ships its own tree, and is removed once its logs are back. Its cargo legs put ~/.cargo/bin first (rustup stable 1.99.1, CI's toolchain, with clippy and rustfmt), since brew's rust comes first on PATH. Nothing for acceptance (xvfb, a browser, node) is installed. A fresh Homebrew 7 needs brew trust matthewsinclair/utilz between the tap and the install. kovacs-sysadm is reachable only while this session is on Remote Control, and it acts at hv's approval in its own session. (edited)
- hv's standing rules for Utilz work (19 and 20 Oct). Stack everything outstanding into the next release, with no small releases. Estimates in t-shirt sizes, never wall-clock. A landing is a local commit by path, one at a time into a primary holding no one else's hunks, on vc's word once vc has read the bytes and every booked run is green, the kovacs leg on the same bytes included; hv keeps every cut, tag and push. Ready to cut means the final head passes a local twin of every CI job (tests.yml's Ubuntu loop, shellcheck 0.9.0 and Rust fmt and clippy on kovacs; the macOS suites, cargo, acceptance and the menuz app build here), then dc's dry run, so no CI job fails on a slip. A finished issue closes as soon as it lands and is checked; a red on CI or the menuz-app dispatch reopens it.

## Decisions

- hv, 2026-09-14: every hv inbox and whiteboard item comes to vc for review and closeout, and after its compact cc takes its instructions from vc.
- hv, 22 Oct 2026, directly to vc, on the Rust toolchain for kovacs's lint twin: "Why do we need both versions? Answer: we don't. Just use 1.99.1". vc's reading. (1) kovacs keeps one toolchain, rustup's stable 1.99.1 (CI's newer line); the 1.99.0 kovacs-sysadm added on hv's earlier pick is uninstalled. (2) dc's rust-lint (fmt and clippy) on 1.99.1 counts as the twin of CI's Rust Lint job whichever line a CI run draws, so a clean lint there is green, with no rc 3 for a mismatch; this holds for 0101's K1 and for 2.14.2's final-head gate. (3) CI's own runs on main still read as they come; a red there reopens its issue.
- hv, 23 Oct 2026, to vc, answering vc's question on the checks before 2.14.2's cut: "Dry run, then cut (Recommended)". vc's reading. (1) dc's final-head gate phases do not run for 2.14.2. CI's own green on b3374e73, on every job in push 39859337814 and dispatch 39859347138, stands as the twin of every CI job: main's code is b3374e73's, and everything past it is under intent/, which no CI job or test reads. (2) dc runs the release dry run, bin/devbin release --patch --dry-run, in the primary, alone on a quiet host. Every node is frozen from vc's GO until vc says the cut's last row is read. (3) Then hv's cut from hv's terminal: bin/devbin release --patch. (4) Any change outside intent/ before the cut voids (1), and the gate's phases run. (5) ic's hold 14, the gate's menuz-app phase, does not run.

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
