---
node: dc
name: DevX Claude
role: devx
session_id: d8335f71-a0c1-4581-9645-94d42188022e
heartbeat_at: 2026-10-19 07:33Z
status: active
focus: "19 Oct, localfolded for hv's compact: 0078 (0150478e) and 0077 (2023828b) checked exact against their approved bytes; cc's 0077 and 0079 candidate green on kovacs (slot 66). Resume from hold 11 (0079's landing check, on cc's SHA) and hold 12 (the kovacs baseline rerun, when python3-venv is in); then todo 5 (the Linux loop before hv's push), 0073's shim half (todo 2), the dry run (todo 3), the installs and done.md (todo 4; the draft is tmp/dc-2141/done-2.14.1.md), the kovacs runbook (todo 6). gtools-vc books the host."
claims: []
---

# DevX Claude (dc)

## DOING

_(none)_

## TODO

- 0074 shell check, if it changes a shell file, before it lands (vc, 19 Oct 05:29Z), and check-landing.sh after each of 0073 and 0074 landings, against its record (0073: tmp/dc-2141/sc090/c0073-9bb70e1b; its pre-landing checks are doing 7). At the candidate bytes: a commit SHA, or its paths in the lander worktree (PREP_REPO=<worktree> tmp/dc-2141/sc090/prep.sh <label> --paths ..., whose hash is now git diff HEAD, so a staged candidate reads right). shellcheck 0.9.0 by CI collector verbatim, with a control that fires, on kovacs (kv-prep.sh, then kv-window.sh <label> shellcheck). Each run booked with gtools-vc; the result to the lander and vc. Size XS each. (edited)
- The 2.14.1 dry run (vc, 19 Oct 05:29Z), once the last landing is in and hv has pushed: bin/devbin release --patch --dry-run at main's head, booked with gtools-vc. It stamps, commits, tags and pushes nothing, but runs its gates for real on HEAD: check all (clippy, fmt) and test estate (tools/test-estate: every bats suite, the cargo tests and the crate's black-box suites under bash 3.2, video.sh's Chrome and ffmpeg among them), so it wants a quiet host. The core's tree rule (bin/.devbin/lib/cmd/release, steps 2 and 5): pre-flight refuses any dirt outside what the release owns, untracked canon events included, so every node's views and events are committed first (dc's boot views at dc's fold); and step 5 hashes the tree and reads HEAD before and after the gates and fails on any change, whoever makes it, so from START to END no node runs a wb verb, commits, or edits the main tree; vc holds the board quiet. Gate logs go under tmp/, which is ignored. vc reads its rows. Size M. (edited)
- done.md's 2.14.1 entry (vc, 19 Oct 06:06Z): drafted now in tmp/dc-2141/done-2.14.1.md from the CHANGELOG's [2.14.1] section and today's issues, filled in as each one lands, and put into done.md with the post-cut records, so nothing new sits on disk while the cut is pending. After hv's tap push of 2.14.1 (vc, 05:29Z): brew upgrade utilz on this Mac, utilz doctor, menuz's app from the release's Menuz.app.zip asset (utilz menuz install), the versions read back (utilz menuz --version, utilz arngz --version); then the entry into done.md above 18 Oct's, by path, prettier-checked, the SHA to vc. An asset not yet attached is reported as pending. Size S. (edited)
- The push gate (vc, 19 Oct; hv said yes to an early push, so 0073 is proven on CI Xcode 26.6): tests.yml Linux loop and its shellcheck 0.9.0 step on kovacs at exactly ceba4252499421a0769fc99632ef99e8a24894f5 (ceba425), main head. Record push-ceba425 and its full bundle are ready; the START is with utilz-vc as slot 99, its GO once the Gtools cut step 5 ends (the freeze began at Gtools dispatch green, 08:39:07Z). Read against slot 83 baseline (watch-out 4), with menuz count moving for 0073 (130 in slot 87); the END carries the loop 14 counts. Then hv pushes exactly that sha, to upstream and local. Size M. (edited)
- Issue 0082, the test-isolation issue (vc, 19 Oct 08:03Z; design approved 08:23Z with amendments A to D, in the body as items 11 to 15). The candidate is in dc worktree /Users/matts/Devel/scratch/utilz-dc/wt-0082 on 4e6903f (record c0082-bad7c75a, uncommitted): the helper isolate_tool_homes, make_gpg_home and end_gpg_home; cryptz round trip real; macoz and clipz stubs; docs and CHANGELOG. Red on main: slot 93, both checks red at their leak under bash 3.2 and 5. Linux green: slot 97, the loop all rc 0 with syncz 79, cryptz 12, clipz 10, kovacs home unchanged and no gpg daemon left. Next: slot 98, the Mac green under both bashes with hv unison archives held at 26, once the Gtools cut step 5 ends; the critic-shell read; the estate; then vc landing word, by path in the primary. Size S. (edited)
- Issue 0083, Utilz on Linux (vc decision 32, on hv word, 19 Oct 08:00Z, in 2.14.1): design approved by vc at 09:04Z, size L, with amendments A to E and the landing order, in the body as items 13 to 18. Order: 0082 lands first; then 0080, then cc 0081; then dc part of 0083, re-applied on 0081 head and built knowing 0081 design (utilz_platform, refuse_off_macos naming uname -s, require_platform, sha256_of, doctor [5/7] and [6/7], macoz, arngz, stampz, the formula, README and help, the CI roster with cleanz, clipz and macoz); then utilz-ic menuz part; then utilz-cc prez part (present refuses by name when no browser and no opener). Each commit with vc read of its bytes and its booked runs. Proof before the cut: kovacs loop with the new roster and utilz doctor from the source tree there; after it, kovacs-sysadm brew install (vc todo 43). Size L. (edited)

## Holds

_(none)_

## Watch-outs

- Rules in force for dc: every host run, however small (one bats file, one prez AT, one shellcheck pass), is booked by name with the booker vc names for the day (gtools-vc on 18 and 19 Oct, its decisions 59 and 62: a START, its GO, an END, by SendMessage), and nothing runs without a GO; reading needs no window. Each START says light or heavy. Heavy runs go one at a time across both estates: any build, any whole suite (utilz test included), the estate gate, Chrome, a dry run or a cut, any test that starts a daemon. A light run (builds nothing, starts no GUI or daemon, binds no port, writes only its own temp dirs) may share the window with one heavy run, its GO given at a load under 60, and a failure that looks like timing is rerun alone before it counts. kovacs is a Parallels VM on rhadamanth, this Mac (kovacs-sysadm, 19 Oct): a kovacs leg writes no file here but loads this Mac through kovacs's two vCPUs, so its START says so; gtools-vc runs it beside a Mac run under decision 62 as amended. CI's shellcheck is 0.9.0, which flags A && B || C as SC2015 where 0.11.0 passes: run it under 0.9.0 (on kovacs, or the darwin build here under Rosetta) before handing on, with a control whose B and C are not echo. A portable stat puts GNU stat -c first. Estimates in t-shirt sizes, never wall-clock (hv, 19 Oct, through vc). No Hammerspoon, pointer, xcodebuild or hv's real keychain from dc; nothing on menuz's files, which are utilz-ic's; nothing pushed by dc. (edited)
- kovacs's baseline for todo 5's loop: slot 83 at 2d73b7f (19 Oct, tmp/dc-2141/kovacs/vbase-2d73b7f/BASELINE.md), with python3-venv installed and kovacs's cargo on PATH. Every step rc 0 and no not ok anywhere: utilz 263, relink 19, plan_test 193, pdf2md 15, xtrct 12, arngz 136, menuz 128, and the rest of the roster as in slot 53. 11 skips by name: 6 error paths where the tool is installed, menuz AC-06.3 for want of rsvg-convert, xtrct 9 to 12 for want of ANTHROPIC_API_KEY. So any not ok, and any new skip, in a later leg is the candidate's until shown otherwise. The baselines at 11c0f95 (slot 53 without cargo, slot 57 with it) stay in tmp/dc-2141/kovacs/ for their environment failures by name. The leg carries a full bundle (the whole history and the tags) into an empty repository and reads nothing of kovacs's checkout. From the next leg, UNISON and GNUPGHOME are empty dirs in the run's dir and its gpg daemons are killed at its end, since slots 53 and 83 left 36 unison archives in kovacs's ~/.unison and a dirmngr running. kovacs keeps two checked download dirs for the day: /tmp/dc-2141-sc090.i5YjL5 (shellcheck 0.9.0) and /tmp/dc-2141-lua.61GdRV (Lua 5.4.6's tarball); each run's own dir goes under /var/tmp and is removed once its logs are back. (edited)

## Decisions

_(none)_

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
