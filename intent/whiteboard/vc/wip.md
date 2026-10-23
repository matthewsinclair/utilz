---
node: vc
name: Validation Claude
role: validation
session_id: 74b51d87-af54-4adf-9287-d19216567c43
heartbeat_at: 2026-10-23 21:46Z
status: active
focus: "After hv's compact, on the night of the close: nothing starts until hv's word. Then ic's 0103 bytes from wt-0103 to vc's read, slot 260, dc's kovacs leg, the landing and close; 0104's bytes on top, the same flow plus one run against the real Launch Services; the next release's number is hv's. Resume: ~/Devel/scratch/utilz-vc/RESUME.md"
claims: []
---

# Validation Claude (vc)

## DOING

_(none)_

## TODO

- The next release (hv's rule: stack everything outstanding): ic's 0103 and 0104, read by vc before any slot, in one worktree off main (~/Devel/scratch/utilz-ic/wt-0103). (edited)
  - **Order:** 0103's commit first, then 0104's on top. Each gets its own light slot, dc's kovacs leg (todo 28; leg-menuz.sh read by vc), and a landing by path on vc's word, then the close.
  - **0103:** the Design and amendment are agreed (issue 0103), with vc's add-on (build_kind's comment) and vc's answers to ic's fold notes. Its work in progress is banked by ic at runs/0103-bytes-wip-20261023T212746Z.patch (dae819dc, base 6339b817).
  - **0104:** the Design is at 6339b817 and its amendment at d76d9828, with vc's read of ic's two additions.
  - **The next release's number is hv's:** one question through vc, for the CHANGELOG section.
  - **Resume:** ~/Devel/scratch/utilz-vc/RESUME.md.

## Holds

_(none)_

## Watch-outs

- Reading prez's acceptance runs: AT01 asserts the in-crate target, so a run with CARGO_TARGET_DIR redirected reads AT01 red by construction; acceptance.sh:248 builds the tree it runs in, so a red on main runs the new suite in main's own tree; and AT20's window can read 0 wide under load, so re-run AT20 alone before calling it red. (edited)
- Host runs on this Mac and on kovacs, for Utilz and Gtools both, book with utilz-vc (gtools-vc's word, 20 Oct, and again on 22 Oct), on gtools-vc's decision 59 terms: a START (sender, repo, worktree and sha or diff hash, the exact command, what it binds or starts, the expected result, the kill timeout), the GO, which alone starts a run, and an END with the results. Heavy runs go one at a time: any build or compile, any whole suite, Chrome, a dry run or cut, a daemon. One light run (no build, GUI, daemon or port; its own temp dirs only) may share the window with one heavy run at a load under 60, and a timing-like failure in it is rerun alone. A kovacs leg runs beside a Mac run, counted in the load. Bytes that change after a GO send their new hash before the rerun. Before each GO: load under 60, nothing listening on 47600 to 47799, no suite running. Intent keeps its own queue (intent-vc): until hv rules on one queue, the two keepers send each other every heavy GO and END by name, neither GOes while the other's heavy run is in flight, and each alone GOes its own estate's runs, the other naming its gaps at an END with its census (agreed 22 Oct). The day's log is ~/Devel/scratch/utilz-vc/host-log-<date>.md. (edited)
- kovacs is brew-only for Utilz and Intent (hv, 19 Oct): Utilz 2.14.2 from the tap since 23 Oct (kovacs-sysadm's upgrade on hv's word, which also moved llvm to 23.1.4 and openldap to 2.7.2 through rust; dc's readbacks rb2142 and rb2142b, every keg row ok), with no dev checkout and no link into one. A brew upgrade there runs as a dry run first, since a formula's dependencies can move too. A test leg lives in its own /var/tmp run dir, ships its own tree, and is removed once its logs are back. Its cargo legs put ~/.cargo/bin first (rustup stable 1.99.1, CI's toolchain, with clippy and rustfmt), since brew's rust comes first on PATH. Nothing for acceptance (xvfb, a browser, node) is installed. A fresh Homebrew 7 needs brew trust matthewsinclair/utilz between the tap and the install. kovacs-sysadm is reachable only while this session is on Remote Control, and it acts at hv's approval in its own session. A readback's outside row reads every writer on the host (Ubuntu's once-a-day release check, a live Claude session), so name each writer from its own record. (edited)
- hv's standing rules for Utilz work (19 and 20 Oct). Stack everything outstanding into the next release, with no small releases. Estimates in t-shirt sizes, never wall-clock. A landing is a local commit by path, one at a time into a primary holding no one else's hunks, on vc's word once vc has read the bytes and every booked run is green, the kovacs leg on the same bytes included; hv keeps every cut, tag and push. Ready to cut means the final head passes a local twin of every CI job (tests.yml's Ubuntu loop, shellcheck 0.9.0 and Rust fmt and clippy on kovacs; the macOS suites, cargo, acceptance and the menuz app build here), then dc's dry run, so no CI job fails on a slip. A finished issue closes as soon as it lands and is checked; a red on CI or the menuz-app dispatch reopens it.

## Decisions

- hv, 2026-09-14: every hv inbox and whiteboard item comes to vc for review and closeout, and after its compact cc takes its instructions from vc.
- hv, 22 Oct 2026, directly to vc, on the Rust toolchain for kovacs's lint twin: "Why do we need both versions? Answer: we don't. Just use 1.99.1". vc's reading. (1) kovacs keeps one toolchain, rustup's stable 1.99.1 (CI's newer line); the 1.99.0 kovacs-sysadm added on hv's earlier pick is uninstalled. (2) dc's rust-lint (fmt and clippy) on 1.99.1 counts as the twin of CI's Rust Lint job whichever line a CI run draws, so a clean lint there is green, with no rc 3 for a mismatch; this holds for 0101's K1 and for 2.14.2's final-head gate. (3) CI's own runs on main still read as they come; a red there reopens its issue.

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
