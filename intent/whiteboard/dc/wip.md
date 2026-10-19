---
node: dc
name: DevX Claude
role: devx
session_id: 6dcaa72a-ce22-40f6-9b26-864aa61830e6
heartbeat_at: 2026-10-19 14:00Z
status: active
focus: "19 Oct, localfolded for hv's compact: slot 130 green and 0082 landed (853a947); 0083's tests red in slot 134 and its code half written in wt-0083 on the corrected base (work/0083-RESUME.md). Resume from the compact hold."
claims: []
---

# DevX Claude (dc)

## DOING

_(none)_

## TODO

- The 2.14.1 dry run (vc, 19 Oct 05:29Z), once the last landing is in and hv has pushed: bin/devbin release --patch --dry-run at main's head, booked with gtools-vc. It stamps, commits, tags and pushes nothing, but runs its gates for real on HEAD: check all (clippy, fmt) and test estate (tools/test-estate: every bats suite, the cargo tests and the crate's black-box suites under bash 3.2, video.sh's Chrome and ffmpeg among them), so it wants a quiet host. The core's tree rule (bin/.devbin/lib/cmd/release, steps 2 and 5): pre-flight refuses any dirt outside what the release owns, untracked canon events included, so every node's views and events are committed first (dc's boot views at dc's fold); and step 5 hashes the tree and reads HEAD before and after the gates and fails on any change, whoever makes it, so from START to END no node runs a wb verb, commits, or edits the main tree; vc holds the board quiet. Gate logs go under tmp/, which is ignored. vc reads its rows. Size M. (edited)
- done.md's 2.14.1 entry (vc, 19 Oct 06:06Z): drafted now in tmp/dc-2141/done-2.14.1.md from the CHANGELOG's [2.14.1] section and today's issues, filled in as each one lands, and put into done.md with the post-cut records, so nothing new sits on disk while the cut is pending. After hv's tap push of 2.14.1 (vc, 05:29Z): brew upgrade utilz on this Mac, utilz doctor, menuz's app from the release's Menuz.app.zip asset (utilz menuz install), the versions read back (utilz menuz --version, utilz arngz --version); then the entry into done.md above 18 Oct's, by path, prettier-checked, the SHA to vc. An asset not yet attached is reported as pending. Size S. (edited)
- The Linux loop at main's head before the next push (vc, 19 Oct): tests.yml's Linux loop and its shellcheck 0.9.0 step on kovacs at exactly the sha hv will push, as a kovacs leg booked with vc (tmp/dc-2141/sc090/prep.sh <label> --sha <sha>, kv-prep.sh, kv-window.sh <label> --cargo lua-build shellcheck prez-build lua-plan relink loop). The last one, slot 99 at ceba425, was green: the 14 with no not ok, menuz at 130, 11 skips. Read against watch-out 4's baseline, with each landing's added tests named. Size M. (edited)
- Issue 0082, the test-isolation issue, landed at 853a947 (853a9477252c1ab606f768b8a2f0a26673d9985c) in slot 131 on vc's GO, 19 Oct: a local commit on main on 1fabda3, the nine paths; install_e2e 11 of 11 under bash 3.2; check-landing exit 0, the patch identical to record d5b139c5. Remaining: vc's check by change; then 0082's close after hv's push and CI green on it, as 0077 and 0079 closed (fixed in, carried upstream in, CI green). Size XS. (edited)
- Issue 0083, Utilz on Linux (vc's decision 32, on hv's word, 19 Oct; design approved by vc at 09:04Z with amendments A to E and the landing order, items 13 to 19 in the body; dc's part first, then utilz-ic's menuz part, then utilz-cc's prez part). In wt-0083 on 853a947 with 0081 v3 and 0085 v2 staged (record c0081-0085-8241f194), so git diff is 0083's alone. Tests written and red in slot 134 (32 tests, 29 red at their own assertions, 3 green controls, bash 3.2 and 5); code half written (common.sh's platform section, doctor, list, install.sh's sha256_of, the dispatcher's listing). The resume state, done and to do in order, is ~/Devel/scratch/utilz-dc/work/0083-RESUME.md; the work so far is banked in work/0083-wip/. Then: stampz, macoz, arngz, clipz, help_dispatch.bats, the docs, tests.yml's roster, versions and CHANGELOG; the green run, the controls by mutation, shellcheck 0.9.0, critic-shell and the kovacs leg, each booked; vc's read; the landing re-applied on the head after 0081 and 0085. Size L. (edited)

## Holds

- Holding for hv's compact (vc, 19 Oct 13:58Z, on hv's word: bank, localfold and compact across Utilz). Condition: hv's compact of this session has run. Then /in-session and pickup, and resume from ~/Devel/scratch/utilz-dc/work/0083-RESUME.md: 0083's dc part in wt-0083 on the corrected base (853a947 with 0081 v3 and 0085 v2 staged, common_lib.bats at b5114ffa; when cc's 0081 and 0085 land, re-base on that head), the rest of its code, then its green run and kovacs leg, then utilz-ic's and utilz-cc's parts. 0082 closes after hv's push and CI green on it. Nothing STARTs before vc's word after the compacts.

## Watch-outs

- Rules in force for dc: every host run, however small (one bats file, one prez AT, one shellcheck pass), "is booked by name with the booker vc names (utilz-vc since gtools-vc's handover of 19 Oct, on gtools-vc's decisions 59 and 62: a START, its GO, an END, on the board and by SendMessage)", and nothing runs without a GO; reading needs no window. Each START says light or heavy. Heavy runs go one at a time across both estates: any build, any whole suite (utilz test included), the estate gate, Chrome, a dry run or a cut, any test that starts a daemon. A light run (builds nothing, starts no GUI or daemon, binds no port, writes only its own temp dirs) may share the window with one heavy run, its GO given at a load under 60, and a failure that looks like timing is rerun alone before it counts. kovacs is a Parallels VM on rhadamanth, this Mac (kovacs-sysadm, 19 Oct): a kovacs leg writes no file here but loads this Mac through kovacs's two vCPUs, so its START says so; gtools-vc runs it beside a Mac run under decision 62 as amended. CI's shellcheck is 0.9.0, which flags A && B || C as SC2015 where 0.11.0 passes: run it under 0.9.0 (on kovacs, or the darwin build here under Rosetta) before handing on, with a control whose B and C are not echo. A portable stat puts GNU stat -c first. Estimates in t-shirt sizes, never wall-clock (hv, 19 Oct, through vc). No Hammerspoon, pointer, xcodebuild or hv's real keychain from dc; nothing on menuz's files, which are utilz-ic's; nothing pushed by dc. (edited)
- kovacs's baseline for todo 5's loop: slot 83 at 2d73b7f (19 Oct, tmp/dc-2141/kovacs/vbase-2d73b7f/BASELINE.md), with python3-venv installed and kovacs's cargo on PATH. Every step rc 0 and no not ok anywhere: utilz 263, relink 19, plan_test 193, pdf2md 15, xtrct 12, arngz 136, menuz 128, and the rest of the roster as in slot 53. 11 skips by name: 6 error paths where the tool is installed, menuz AC-06.3 for want of rsvg-convert, xtrct 9 to 12 for want of ANTHROPIC_API_KEY. So any not ok, and any new skip, in a later leg is the candidate's until shown otherwise. The baselines at 11c0f95 (slot 53 without cargo, slot 57 with it) stay in tmp/dc-2141/kovacs/ for their environment failures by name. The leg carries a full bundle (the whole history and the tags) into an empty repository and reads nothing of kovacs's checkout. From the next leg, UNISON and GNUPGHOME are empty dirs in the run's dir and its gpg daemons are killed at its end, since slots 53 and 83 left 36 unison archives in kovacs's ~/.unison and a dirmngr running. "kovacs keeps two checked download dirs, refetched after the 19 Oct crash into /var/tmp because its /tmp is a tmpfs that a reboot empties: /var/tmp/dc-2141-sc090.qyz5IL (shellcheck 0.9.0) and /var/tmp/dc-2141-lua.dXTRHg (Lua 5.4.6's tarball), both read by kv-remote.sh. Each run's own dir goes under /var/tmp too and is removed once its logs are back." (edited)

## Decisions

_(none)_

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
