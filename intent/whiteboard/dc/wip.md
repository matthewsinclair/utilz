---
node: dc
name: DevX Claude
role: devx
session_id: 45821818-5780-410a-a192-9845d3af133b
heartbeat_at: 2026-10-20 17:28Z
status: active
focus: "20 Oct: todo 15 done (slot 202, the kovacs readback of 2.14.1's brew install, 0 FAIL). Next: todo 19, the gate's kovacs fmt and clippy, once rustup there matches CI's 1.99.1; todo 16, cc's prez leak leg; todo 17, 0072's shim if it moves; todo 18, 2.14.2's gate. The README Homebrew paragraph waits for hv's word."
claims: []
---

# DevX Claude (dc)

## DOING

_(none)_

## TODO

- K1, the kovacs leg for cc's 0095 (prez's present decks and a failed pdf's HTML left in TMPDIR), vc's yes of 17:03Z and its word after slot 202. Once cc's R2 START names its bytes, on the same bytes: PREP_REPO=<cc's wt-0095> tmp/dc-2141/sc090/prep.sh c0095-<sha8> --paths <its paths> (the patch's sha256 checked against cc's), kv-prep.sh and ci-toolchain.sh, then one heavy kovacs run booked with utilz-vc: kv-window.sh c0095-<sha8> --cargo rust prez-build prez-at-stub shellcheck, with rust-lint if vc keeps it in K1. That is cargo build and test of the workspace with TMPDIR counted, acceptance.sh AT05 AT06 without --strict (0095's checks (a) and (b) on Linux, /tmp's prez-* listed before and after), and shellcheck 0.9.0 after its control, with the toolchain's four versions printed (rustup's 1.99.1 from ~/.cargo/bin). Size S. (edited)
- 0072's shim, item 3b, vc's yes of 17:03Z: only if opt/menuz/menuz moves, and after arca_swift's 0.2.0 tag: one light shellcheck 0.9.0 pass of the shim and one heavy kovacs leg of menuz.bats, booked with utilz-vc. Size S.
- The next release, 2.14.2 (hv, vc's decision 49): its final-head gate, report and dry run, then the post-release steps (item 4 of dc's 20 Oct plan). Later: the cut follows 0072's landing. Size L. (edited)
- The gate's kovacs phase gains fmt and clippy (hv, vc's decision 49 (a)): built 20 Oct, banked in ~/Devel/scratch/utilz-dc/gate/. kv-remote.sh's rust-lint runs cargo fmt --all --check, then cargo clippy --all-targets --workspace -D warnings, per crate; it is rc 3, never a pass, unless kovacs's rustc -V is CI's line, which ci-toolchain.sh reads from main's latest push run (rustc 1.99.1 (58cf8f9c3 2026-10-13) on 20 Oct, run 39463604956). Every cargo leg prints the four versions and where each resolved. final-head-gate.sh's kovacs phase calls both, and its report gains the line, with mac-lint kept as a cross-check. kovacs's rustup is 1.99.1 since kovacs-sysadm's update. Left: its first run, in K1 if vc keeps it there, else 2.14.2's gate. Size S. (edited)

## Holds

_(none)_

## Watch-outs

- Rules in force for dc: every host run, however small (one bats file, one prez AT, one shellcheck pass), "is booked by name with the booker vc names (utilz-vc, which books both estates from 20 Oct on gtools-vc's word, under gtools-vc's decisions 59 and 62: a START, its GO, an END, on the board and by SendMessage)", and nothing runs without a GO; reading needs no window. Each START says light or heavy. Heavy runs go one at a time across both estates: any build, any whole suite (utilz test included), the estate gate, Chrome, a dry run or a cut, any test that starts a daemon. A light run (builds nothing, starts no GUI or daemon, binds no port, writes only its own temp dirs) may share the window with one heavy run, its GO given at a load under 60, and a failure that looks like timing is rerun alone before it counts. kovacs is a Parallels VM on rhadamanth, this Mac (kovacs-sysadm, 19 Oct): a kovacs leg writes no file here but loads this Mac through kovacs's two vCPUs, so its START says so; gtools-vc runs it beside a Mac run under decision 62 as amended. CI's shellcheck is 0.9.0, which flags A && B || C as SC2015 where 0.11.0 passes: run it under 0.9.0 (on kovacs, or the darwin build here under Rosetta) before handing on, with a control whose B and C are not echo. A portable stat puts GNU stat -c first. Estimates in t-shirt sizes, never wall-clock (hv, 19 Oct, through vc). No Hammerspoon, pointer, xcodebuild or hv's real keychain from dc; nothing on menuz's files, which are utilz-ic's; nothing pushed by dc. (edited)
- kovacs's baseline for todo 5's loop: slot 83 at 2d73b7f (19 Oct, tmp/dc-2141/kovacs/vbase-2d73b7f/BASELINE.md), with python3-venv installed and kovacs's cargo on PATH. Every step rc 0 and no not ok anywhere: utilz 263, relink 19, plan_test 193, pdf2md 15, xtrct 12, arngz 136, menuz 128, and the rest of the roster as in slot 53. 11 skips by name: 6 error paths where the tool is installed, menuz AC-06.3 for want of rsvg-convert, xtrct 9 to 12 for want of ANTHROPIC_API_KEY. So any not ok, and any new skip, in a later leg is the candidate's until shown otherwise. The baselines at 11c0f95 (slot 53 without cargo, slot 57 with it) stay in tmp/dc-2141/kovacs/ for their environment failures by name. The leg carries a full bundle (the whole history and the tags) into an empty repository and reads nothing of kovacs's checkout. From the next leg, UNISON and GNUPGHOME are empty dirs in the run's dir and its gpg daemons are killed at its end, since slots 53 and 83 left 36 unison archives in kovacs's ~/.unison and a dirmngr running. "kovacs keeps two checked download dirs, refetched after the 19 Oct crash into /var/tmp because its /tmp is a tmpfs that a reboot empties: /var/tmp/dc-2141-sc090.qyz5IL (shellcheck 0.9.0) and /var/tmp/dc-2141-lua.dXTRHg (Lua 5.4.6's tarball), both read by kv-remote.sh. Each run's own dir goes under /var/tmp too and is removed once its logs are back." (edited)

## Decisions

_(none)_

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
