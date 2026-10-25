---
node: vc
name: Validation Claude
role: validation
session_id: 74b51d87-af54-4adf-9287-d19216567c43
heartbeat_at: 2026-10-25 16:35Z
status: active
focus: "Localfold for hv (molt-vc 16:24Z), not released: 2.14.4 carries 0107, 0108 and 0109 (A3's version line, hv's ruling); cc's 0109 one-slot run booked with molt-vc, unrun, no GOs until hv says continue; then the twins and dry run rebook on the new code. doing 68. Resume: ~/Devel/scratch/utilz-vc/RESUME.md"
claims: []
---

# Validation Claude (vc)

## DOING

- 2.14.4 (0107, 0108, and A3's version line on hv's ruling) pre-release checks. On code 21b0385d the Mac twins, critic leg and kovacs twins were green, but they are superseded by A3. Next: cc's A3 issue and landing (after A3 is in devbin's docs and vc reads the bytes), then the Mac twins, kovacs twins via kovacs-sysadm, and dc's dry run on the new code, each booked fresh with molt-vc; then hv's cut, app-sign at the tag, brew on both hosts, utilz use brew, and the version line reading brew. (edited)

## TODO

- When the release carrying 0107 (mdagg's blank line between joined files) is on brew, tell gtools-vc, so Gtools' cc deletes separate_headings in its ST0018 WP-07 (gtools-vc's ACK, 25 Oct).

## Holds

_(none)_

## Watch-outs

- Reading prez's acceptance runs: AT01 asserts the in-crate target, so a run with CARGO_TARGET_DIR redirected reads AT01 red by construction; acceptance.sh:248 builds the tree it runs in, so a red on main runs the new suite in main's own tree; and AT20's window can read 0 wide under load, so re-run AT20 alone before calling it red. (edited)
- Host runs on this Mac and on kovacs, for every estate, book on molt-vc's desk, the one host queue (hv, 25 Oct; decision 58 put molt-vc in charge on 24 Oct). Utilz's runs book through vc with molt-vc: vc asks for the GO with sender, repo, worktree and sha or diff hash, the exact command, what it binds or starts, the expected result and the kill timeout; the START follows molt-vc's GO by name, which alone starts a run; an END follows with the results. Heavy runs go one at a time: any build or compile, any whole suite, Chrome, a dry run or cut, a daemon. A light run (no build, GUI, daemon or port; its own temp dirs only) shares the window with a heavy only when molt-vc says so, and a timing-like failure in it is rerun alone. A kovacs leg goes to kovacs-sysadm as a request, never over ssh, and counts as a heavy. Bytes that change after a GO send their new hash before the rerun. The older interleave with intent-vc is retired. The day's log is ~/Devel/scratch/utilz-vc/host-log-<date>.md. (edited)
- kovacs is brew-only for Utilz and Intent (hv, 19 Oct): Utilz 2.14.3 from the tap since 25 Oct (hv's own upgrade, which also moved openssl@4 to 4.1.0; rb2143's checks run by kovacs-sysadm, all green), with no dev checkout and no link into one. NO SSH TO KOVACS from any Utilz node, read-only included (hv's rule on molt-vc's desk, 25 Oct): send kovacs-sysadm the exact commands with the expected output, molt-vc books it as a light, and vc re-tallies; a dc leg that ships a bundle over ssh needs hv's word through molt-vc first. A brew upgrade there runs as a dry run first, since a formula's dependencies can move too. A test leg lives in its own /var/tmp run dir, ships its own tree, and is removed once its logs are back. Its cargo legs put ~/.cargo/bin first (rustup stable 1.99.1, CI's toolchain, with clippy and rustfmt), since brew's rust comes first on PATH. Nothing for acceptance (xvfb, a browser, node) is installed. A fresh Homebrew 7 needs brew trust matthewsinclair/utilz between the tap and the install. kovacs-sysadm is reachable only over Remote Control, and it acts at hv's approval in its own session. kovacs-sysadm's shell is zsh: `command -v -a` fails there; use `whence -a`. (edited)
- hv's standing rules for Utilz work (19 and 20 Oct). Stack everything outstanding into the next release, with no small releases. Estimates in t-shirt sizes, never wall-clock. A landing is a local commit by path, one at a time into a primary holding no one else's hunks, on vc's word once vc has read the bytes and every booked run is green, the kovacs leg on the same bytes included; hv keeps every cut, tag and push. Ready to cut means the final head passes a local twin of every CI job (tests.yml's Ubuntu loop, shellcheck 0.9.0 and Rust fmt and clippy on kovacs; the macOS suites, cargo, acceptance and the menuz app build here), then dc's dry run, so no CI job fails on a slip. A finished issue closes as soon as it lands and is checked; a red on CI or the menuz-app dispatch reopens it.

## Decisions

- hv, 2026-09-14: every hv inbox and whiteboard item comes to vc for review and closeout, and after its compact cc takes its instructions from vc.
- hv, 22 Oct 2026, directly to vc, on the Rust toolchain for kovacs's lint twin: "Why do we need both versions? Answer: we don't. Just use 1.99.1". vc's reading. (1) kovacs keeps one toolchain, rustup's stable 1.99.1 (CI's newer line); the 1.99.0 kovacs-sysadm added on hv's earlier pick is uninstalled. (2) dc's rust-lint (fmt and clippy) on 1.99.1 counts as the twin of CI's Rust Lint job whichever line a CI run draws, so a clean lint there is green, with no rc 3 for a mismatch; this holds for 0101's K1 and for 2.14.2's final-head gate. (3) CI's own runs on main still read as they come; a red there reopens its issue.
- hv, 2026-10-24, through molt-vc: dev, opt, brew is one identical approach across Molt, Utilz, devbin and Intent, on Molt's ST0008, with one shared spec in Devbin's docs drafted by devbin-vc. PATH is (B), 'your links first': formulas link into Homebrew's bin as usual, and Molt-matts puts ~/.local/bin ahead of it on hv's sleeves. 'No link means brew': `use brew` removes the tool's link set. Utilz's differences from the contract (C2, C3, C4, C5 brew and the link set, C7, C9's render) converge in 0105. 0105's dependent parts (install, use, version, doctor's PATH remedy, the formula, README's Installation) hold until the spec lands; its independent parts go on.
- hv, 2026-10-24, going AFK: molt-vc is in overall charge of resource-contention coordination for the host (this Mac and kovacs) across the estates. Each vc stays in control of its own Claudes, and they take their instructions from it. For Utilz: vc still books and GOes Utilz's runs, and books each one with molt-vc as the overall keeper (with intent-vc copied as before) until molt-vc names its own terms. Watchout 17's interleave with intent-vc gives way to molt-vc's coordination.
- hv, 2026-10-25 (molt-vc 06:48Z, all VCs): one next release per project, carrying everything outstanding that is not deferred; no patch, interim or point releases before it. No user base but hv, so nothing is held back for compatibility or staging. The order is fixed: everything done, then everything tested at the desk, then the Linux artefacts checked on kovacs through kovacs-sysadm (a heavy, booked with molt-vc), then hv's cut. Anything left out is deferred on the record with hv's say; nothing drops out quietly. For Utilz now: no thread or issue is open, so the next release has nothing in it yet.
- hv, 2026-10-25, directly to vc: (1) the next Utilz release is 2.14.4 and carries 0107 and 0108; its pre-release checks start now, in the ruled order: Mac twins, then the Linux twins on kovacs through kovacs-sysadm, then dc's dry run, then hv's cut. (2) vc pushes main before the checks so CI reads it first. (3) molt-vc's desk is the one host queue for every estate on this Mac and kovacs; watchout 17's interleave with intent-vc is retired. (4) dc's kovacs legs no longer ship over ssh: each goes to kovacs-sysadm as a request, with the bundle, the commands and the expected output, and is booked with molt-vc as a heavy.
- hv, 2026-10-25, directly to vc: A3's version-line change (devbin's contract T4: ' at <root>' comes off; Utilz said SAME to devbin-vc's draft b19ffcb9) goes into 2.14.4, not a later release. cc files the issue and lands it once A3 is in devbin's docs; the Mac twins, kovacs twins and dry run then rerun on the new code. The dry run's READY (dryrun-2144.sh e4de6bc0) is withdrawn from molt-vc's queue and the freeze is lifted.

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
