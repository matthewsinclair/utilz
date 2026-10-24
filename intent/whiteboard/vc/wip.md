---
node: vc
name: Validation Claude
role: validation
session_id: 74b51d87-af54-4adf-9287-d19216567c43
heartbeat_at: 2026-10-24 09:53Z
status: active
focus: "2.14.3: slot 285 (0106 diagnostic) hidden arm clean, scratch arm running; then 0106 (B) route, 0105 fixes, landings, stale records, ready-to-cut; desk is molt-vc's"
claims: []
---

# Validation Claude (vc)

## DOING

_(none)_

## TODO

- The next release, 2.14.3 (hv's number; hv's rule: stack everything outstanding). Resume: ~/Devel/scratch/utilz-vc/RESUME.md. (edited)
  - **0103, 0104:** landed and closed (0104: ccb11bde, 7ce4cbda; closed 48a6dcea).
  - **0105** (cc, dev/opt/brew, hv: in 2.14.3; one approach across Molt, Utilz, devbin, Intent; contract devbin docs/dev-opt-brew.md at aeed31e4, plus the T3 amendment, devbin 0213): wt-0105, f9e5e4b2..d3dbb766 (net 6de27936), read by vc; critic-shell plus vc found 1 critical (tools/formula bash 3.2 quoted replacement, reproduced) and 8 warnings, sent to cc (board, 2026-10-24); cc fixing, plus the brew update step. Then one booked Mac run (fresh wt-0105-run, prez built with CARGO_TARGET_DIR unset, fixtures in system temp), dc's kovacs leg, the landing, install_e2e in the primary, the close.
  - **0106** (ic, Launch Services, hv: yes, fix): wt-0106 at 40b50e0d (net 7316c4a0), read by vc. Slot 276 (fakes) green. Slot 282 (real) red: the Release product re-registered after menuz's checked drop, with its original dates. Slot 285, a diagnostic (hidden ~/.local/state arm, then indexed scratch arm), running at the fold; its verdict decides (B): hidden clean, so (B) runs hidden and 0106 stands; hidden back too, so a wait-and-recheck in 0106.
  - **After the landings:** vc drops the stale Menuz records (hv's Debug, Release, dist; cc's fixture bundles under ~/Devel/scratch/utilz-cc/tmp-0105-run; the diagnostic's leftovers), reading the id before and after; ic's hidden arm dir goes.
  - **Then:** ready-to-cut per watchout 22 (kovacs has shellcheck 0.9.0 at vbubq3 and Lua 5.4.6 at UHvvGX; dc's kv-remote.sh 1bb5c1d3); tell molt-vc first (Molt's UTILZ_INSTALL_PREFIX, ST0008 WP05, live before the cut); dc's dry run; hv's cut, then tools/formula publish and brew upgrade on rhadamanth and kovacs.
  - **Host:** molt-vc keeps the slot desk while hv is AFK; every Utilz run books through vc with molt-vc.

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
