---
node: hv
name: Hypervisor
role: hypervisor
session_id: none
heartbeat_at: 2026-09-14 17:34Z
status: active
focus: "The next Utilz release, cut by hand once more (decision 1), with ST0020 in it."
claims: []
---

# Hypervisor (hv)

## DOING

_(none)_

## TODO

_(none)_

## Holds

_(none)_

## Standing directives

_(none)_

## Watch-outs

_(none)_

## Decisions

- hv, 23 Nov 2026, first-hand in vc's session. hv's words: "Go with your recommendations." This answers vc's triage of Utilz's open work, which hv asked for that morning: "Close out any outstanding STs, WPs, and Issues; but let's review what is there first and triage them into close, fix, or hold." The rest is vc's wording of what hv accepted. FIX: (1) ST0031, dc. WP01 retires tools/ci-state, tools/post-cut and tools/formula into devbin's core, taking vc decision 91's six critic findings with them. WP02 lands its banked CI tuning. Both land after the arngz fixes and go out in the same release. That release's cut proves AC-01.4 and is the first cut done the new way. (5) and (6), dc, with the arngz work: arngz's five parsed yq captures that take yq's stderr with the value, and one cap on the 600 s ARNGZ_APPLY_TIMEOUT default that each failing scheduled arm in arngz.bats waits out. HOLD: (2) ST0029, Retire Python, which hv has parked. dc puts it on hold in Intent and unstarts WP01. It resumes on hv's word. (3) Issue 0114, under hv's P3 ruling, until arca_swift tags its 0003 fixes. ic watches for the tag. (4) Issue I59c806c, devbin#0326's install and use. It is devbin-cc's, in devbin-vc's order after Pplr, Cldr and Gtools, and starts only after ST0031/01 lands, because ST0031's AC-01.3 compares against the current formula. CLOSE: (7) intent/wip.md's line on Devbin's cancelled-run resume defect, which Devbin filed and closed as 0330. (8) ic's 6 Nov item (b), the read-only check of 2.14.9's Menuz leg, which the 2.14.9 and 2.14.10 cuts overtook. Also recorded here: cc passed on to vc on 23 Nov hv's 6 Nov word to cc, given first-hand in cc's session: "Go with A, hold for the cut". It never reached vc, and 2.14.9's cut on 10 Nov spent it.
- hv, 23 Nov 2026, first-hand in vc's session. hv's word: "go". It approves vc's scope for arngz, which answers hv's account of arngz; that account is verbatim in vc's asks to dc and ic of 05:16Z. The rest is vc's wording of what hv accepted. One new arngz thread, going out in the same release as ST0031 (decision 9). WP01, the run log (dc): every run appends to ~/.local/state/arngz/arngz.log. It records each display with its desktops, both as com.apple.spaces records them and as they are live, in order; the plan; each step and what it read back; the outcome and the timings; and the CLI's side (the hs start, the deadline, any kill). It also records each desktop's display at the start and end of a run, every desktop arngz creates, and the time since the last display change, so that cc's likely cause of the surplus desktops can be proved or ruled out: a display that has just attached is short while its own desktops still visit the built-in, so apply creates new ones, and macOS then sends the visitors home. The log adds nothing on screen and is capped in size, and `arngz log` prints the last run. WP02, the toasts (ic): Hammerspoon on-screen alerts. Starting names the desk. Running... shows the current phase. Finished shows the windows placed, already in place and not found, the desktops added or removed, and the time taken, or else the refusal and its reason, and stays up longer. WP03, the desk-change fix (dc, with cc as second reader), starts once the log shows what goes wrong. It covers P.order_spaces' reading of desktop order when desktops move between displays, the refusal's wrong "wait, then run again" advice, the surplus desktops, F3's stale hs client, F4's discover deadline, and decision 9's (5) and (6). hv's diagnosis run: hv switches to the dev tree with utilz use dev, runs zeopit, unplugs, runs rhad, plugs back in and runs zeopit, then switches back with utilz use brew. Each design comes to vc before any code, and every run goes through the Desk.
- hv, 23 Nov 2026, first-hand in vc's session. hv's words: "And yes, include all fixes." This answers vc's question on the two one-off failures from the morning's log read. dc had recommended leaving them out of ST589246c/93ea, and vc decision 108 (3) brought that to hv in dc's words, with dc's sizes. F3: arngz stops its hs helper the moment the answer lands, which once broke the next run ("ipc port is no longer valid"). The fix is to let hs exit on its own first, size S. F4: Save Desk once ran past the CLI's 60 s wait. The fix is to raise that wait, size XS; the alternative, running it in the background as apply does, is M. vc recommended both, the S fix and the XS raise. So both go into 93ea, in this release.
- hv, 23 Nov 2026, first-hand in vc's session. hv's words: "Ok, context is high here on utilz-*, so lets find a sensible moment to bank the bankable, and then localfold+compact for all Claudes here. Then we continue on the bounce. I can run the next test run while everyone banks, folds, and holds." The rest is vc's wording of how it was carried out. vc named the moment at once (announce of 10:12Z). Every utilz-* seat banks what lives outside the tree, localfolds without a release, and holds: dc at 21bf2768, ic at 8e906dc1 and cc at fcc49ed8, each checked by vc by change, with vc folding last. hv runs 93ea's test by hand meanwhile: /bin/bash ~/Devel/scratch/utilz-dc/st5892/run-93ea-2.sh, pinned to a763184a. dc's own slot for it, granted before vc's STOP reached dc, was stopped at 61 of 180 with none failed, released, and its partial TAP set aside. Then hv compacts each session. On the bounce, each seat runs /in-session with its pickup and carries on from its RESUME.md on vc's word: dc reads hv's TAP and lands 93ea, then hv's live run follows. Open for hv on the bounce: whether ST0031 moves from dc to cc now, to run in parallel (decision 9 named dc).
- hv, 23 Nov 2026, first-hand in vc's session, received by vc's date -u of 11:27Z, answering vc's three questions after ST589246c/93ea's live re-runs. hv's words: "1: Yes 2: New thread, yes. Why not fix it now? I see no reason not to. 3: Remind me what A and B were before I pick one?" The rest is vc's wording. (1) Screen Sharing: vc gave it two entries titled by window in hv's desks rhad and zeopit, gyges full size on desktop 6 with Parallels and All Connections on desktop 7 with Appgate and Console. Both desks pass arngz show, and the copies from before are banked in ~/Devel/scratch/utilz-vc/desks-before-20261123/. (2) A new arngz thread, in this release: apps with more than one window across desktops (arngz cannot always see every window, a title is a fragile way to pick one, and an entry with no title takes every window of its app), and a route for a carried window past a full-screen desktop. cc designs it, as vc recommended and hv's yes took, design before code. Until it lands, hv keeps the two apps out of full screen, the workaround hv chose and acted on the same day. (3) ST0031's (A) or (B) stays open; vc restates both. Also hv's word on the toasts, in the same session: "The toasts work as expected." ic satisfied AC-eae7633d.1 on it at a47961d6.
- hv, 23 Nov 2026, first-hand in vc's session, received by vc's date -u of 11:33Z: "ok, go". It answers vc's restatement of ST0031's (A) and (B), which hv asked for in decision 13 (3). vc reads it as (A), the recommendation of dc and vc, and says so to hv. The rest is vc's wording. ST0031/01 retires tools/ci-state, install.sh's install_ci_state and install_ci_jobs, and tools/post-cut, as dc's re-plan of 23 Nov has it (~/Devel/scratch/utilz-dc/st0031-prep/wp01-replan.md, 1b222cf9). tools/formula stays until issue I59c806c, devbin-cc's, which takes AC-01.3's formula half, and the cut's one after: line becomes `tools/formula publish --pull`. This amends decision 9 (1), under which WP01 also retired tools/formula. The cut's gates stay `check all` alone, by hv's ruling of 28 Oct (ST0030), and AC-01.1 is reworded to match. Issue Ie8e55e8, menuz's hard-coded asset name, rides /01. /01 and /02 land together, in this release.

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
