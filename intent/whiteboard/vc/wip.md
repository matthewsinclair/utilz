---
node: vc
name: Validation Claude
role: validation
session_id: 10d02503-c5ac-4034-b498-1aec461f1878
heartbeat_at: 2026-10-22 16:48Z
status: active
focus: "20 Oct: 2.14.2 under way (0095 cc's, designed and measured; 0072 ic's, behind arca_swift 0.2.0); kovacs brew-only on 2.14.1 and read back green (202); main pushed at 1ceade68, CI green; utilz-vc books the host for both estates"
claims: []
---

# Validation Claude (vc)

## DOING

_(none)_

## TODO

- 2.14.2 (vc's decision 49). 0095 landed (d633f4cb). 0096 is cc's: v2 in wt-0096 with record.rs:552-553 folded in, then its runs, dc's K1 and the landing. 0072 is ic's (menuz 0.4.6), after arca_swift 0.2.0, which needs hv's four steps in gtools-ic's session: the console look (AC-09.6), the landing, the push with its Xcode 26.6 CI run, and the tag. Then dc's final-head gate and dry run, and hv's cut.

## Holds

_(none)_

## Watch-outs

- Reading prez's acceptance runs: AT01 asserts the in-crate target, so a run with CARGO_TARGET_DIR redirected reads AT01 red by construction; acceptance.sh:248 builds the tree it runs in, so a red on main runs the new suite in main's own tree; and AT20's window can read 0 wide under load, so re-run AT20 alone before calling it red. (edited)
- Host runs on this Mac and on kovacs, for Utilz and Gtools both, book with utilz-vc (gtools-vc's word, 20 Oct), on gtools-vc's decision 59 terms: a START (sender, repo, worktree and sha or diff hash, the exact command, what it binds or starts, the expected result, the kill timeout), the GO, which alone starts a run, and an END with the results. Heavy runs go one at a time: any build or compile, any whole suite, Chrome, a dry run or cut, a daemon. One light run (no build, GUI, daemon or port; its own temp dirs only) may share the window with one heavy run at a load under 60, and a timing-like failure in it is rerun alone. A kovacs leg runs beside a Mac run, counted in the load. Bytes that change after a GO send their new hash before the rerun. Before each GO: load under 60, nothing listening on 47600 to 47799, no suite running. The day's log is ~/Devel/scratch/utilz-vc/host-log-<date>.md. (edited)
- An arca_swift pin is proven only by the menuz-app dispatch on macos-26 (Xcode 26.6). This Mac's Swift 6.4 drops a dependency's warnings-as-errors, so a local green cannot see that red (Gtools run 39208058955, fixed by arca_swift 0.1.1). It applies to 0072's 0.2.0. (edited)
- kovacs is brew-only for Utilz and Intent (hv, 19 Oct): Utilz 2.14.1 from the tap since 20 Oct (dc's readback, 81 ok), with no dev checkout and no link into one. A test leg lives in its own /var/tmp run dir, ships its own tree, and is removed once its logs are back. Its cargo legs put ~/.cargo/bin first (rustup stable 1.99.1, CI's toolchain, with clippy and rustfmt), since brew's rust comes first on PATH. Nothing for acceptance (xvfb, a browser, node) is installed. A fresh Homebrew 7 needs brew trust matthewsinclair/utilz between the tap and the install. kovacs-sysadm is reachable only while this session is on Remote Control, and it acts at hv's approval in its own session. (edited)
- hv's standing rules for Utilz work (19 and 20 Oct). Stack everything outstanding into the next release, with no small releases. Estimates in t-shirt sizes, never wall-clock. A landing is a local commit by path, one at a time into a primary holding no one else's hunks, on vc's word once vc has read the bytes and every booked run is green, the kovacs leg on the same bytes included; hv keeps every cut, tag and push. Ready to cut means the final head passes a local twin of every CI job (tests.yml's Ubuntu loop, shellcheck 0.9.0 and Rust fmt and clippy on kovacs; the macOS suites, cargo, acceptance and the menuz app build here), then dc's dry run, so no CI job fails on a slip. A finished issue closes as soon as it lands and is checked; a red on CI or the menuz-app dispatch reopens it.

## Decisions

- hv, 2026-09-14: every hv inbox and whiteboard item comes to vc for review and closeout, and after its compact cc takes its instructions from vc.
- hv, 22 Oct 2026, directly to vc, on vc's boot plan: "Yep, go for it and go with your recs (4: def pin it to the right Xcode)." Then, before anything had gone out: "Hang on: the latest Xcode is 27.x. Why not pin to that?" And on vc's answer (26.6, the toolchain this Mac is not): "Can you do me a favour and poll all *-vc that have Swift and macOS code and ask why we can't ping to 27.x now? I see no reason not to. Isn't it just a matter of rebuilding with Xcode 27.x?" vc's reading. (1) The plan goes ahead in its order, and cc, dc and ic take their words from vc, as hv told each of them at boot. (2) vc pushes main's commits past 1ceade68 to both remotes and reads the push's CI. (3) 0072 is unblocked on vc's own read of the tag, not a relay: 0.2.0 is tag 9f3b863 on f7742b1, and run 39803565309 is green there, its adopter job on macos-26 with DEVELOPER_DIR at Xcode 26.6. (4) Which Xcode tests.yml's menuz-app job pins is open. vc polled gtools-vc (for Gtools.app and arca_swift) and intent-vc (for Intent.app); molt-vc's project has no Swift. vc takes their answers to hv, and nothing about the pin is filed or changed until hv rules. (5) 2.14.2 is 0095 (landed), 0096 (prez 2.5.5), deliver.rs's revision overwrite (cc's new issue, prez 2.5.6), the Xcode pin once hv has ruled, and 0072 (menuz 0.4.6). (6) Still hv's, asked at 0072's step 7: when hv looks at the dev install, and what stays installed after it.

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
