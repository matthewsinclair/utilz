---
node: vc
name: Validation Claude
role: validation
session_id: 74b51d87-af54-4adf-9287-d19216567c43
heartbeat_at: 2026-10-24 14:59Z
status: active
focus: "fold for hv's compact (molt-vc, 14:58Z): 0105 landed 2e0f2940 and closed 82e8b021; final head 82e8b021; next the twins (kovacs books after the compact; Mac and the dry run wait for hv's molt resleeve)"
claims: []
---

# Validation Claude (vc)

## DOING

_(none)_

## TODO

- The next release, 2.14.3 (hv's number; hv's rule: stack everything outstanding). Resume: ~/Devel/scratch/utilz-vc/RESUME.md. (edited)
  - **0103, 0104, 0105, 0106:** landed and closed. 0105 landed as 2e0f2940 (net of f9e5e4b2..8a15eaf6, diff 06fde9c2, beside 0106's hunks; vc checked it staged and by change), green on kovacs slot 305 and Mac slot 322 on 8a15eaf6, install_e2e 11/0 in the primary at 2e0f2940; closed 82e8b021. vc dropped the 11 stale Launch Services records under cc's tmp-0105-run; the Menuz id resolves to ~/Applications/Menuz.app alone.
  - **Final head 82e8b021.** Next: ready to cut per watchout 22. kovacs twins (dc, hold 26: leg.sh d4ef6559 with --cargo lua-build shellcheck prez-build lua-plan loop, plus Rust fmt and clippy 1.99.1) book with molt-vc after the compact; Mac twins (cc: macOS suites, cargo, acceptance, menuz app build) and dc's dry run wait for hv's `molt resleeve` on rhadamanth (grep UTILZ_INSTALL_PREFIX ~/.config/molt/env.sh reads 0 at 14:59Z). Tell molt-vc before telling hv. Then hv's cut, the Menuz.app asset at the tag, tools/formula publish, brew upgrade on rhadamanth and kovacs.
  - **Host:** molt-vc keeps the slot desk; every Utilz run books through vc with molt-vc.

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
- hv, 2026-10-24, through molt-vc: dev, opt, brew is one identical approach across Molt, Utilz, devbin and Intent, on Molt's ST0008, with one shared spec in Devbin's docs drafted by devbin-vc. PATH is (B), 'your links first': formulas link into Homebrew's bin as usual, and Molt-matts puts ~/.local/bin ahead of it on hv's sleeves. 'No link means brew': `use brew` removes the tool's link set. Utilz's differences from the contract (C2, C3, C4, C5 brew and the link set, C7, C9's render) converge in 0105. 0105's dependent parts (install, use, version, doctor's PATH remedy, the formula, README's Installation) hold until the spec lands; its independent parts go on.
- hv, 2026-10-24, going AFK: molt-vc is in overall charge of resource-contention coordination for the host (this Mac and kovacs) across the estates. Each vc stays in control of its own Claudes, and they take their instructions from it. For Utilz: vc still books and GOes Utilz's runs, and books each one with molt-vc as the overall keeper (with intent-vc copied as before) until molt-vc names its own terms. Watchout 17's interleave with intent-vc gives way to molt-vc's coordination.

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
