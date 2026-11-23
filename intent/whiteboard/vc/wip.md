---
node: vc
name: Validation Claude
role: validation
session_id: 7386a9d5-ebce-4a62-bbeb-a887311d02fd
heartbeat_at: 2026-11-23 13:50Z
status: active
focus: "hv has left for now (hv decision 16); the spike waits for hv's return, its ask TM15WA queued at the Desk, which devbin-vc keeps closed until hv's word. dc queues its heavy ask for ST0031's run, to go after the spike. cc codes STca1b7f9's WP3 and WP4's failure half with no run (vc decision 112), and ic reads it second. ic designs showreel qr (hv decision 15). Then the landings, hv's push, the spike and WP1, WP2 and WP4's Mission Control leg, hv's live run, and the cut."
claims: []
---

# Validation Claude (vc)

## DOING

_(none)_

## TODO

_(none)_

## Holds

_(none)_

## Watch-outs

- prez acceptance: AT01 reads red with CARGO_TARGET_DIR redirected; a red on main reruns in main's tree; rerun AT20 alone before calling it red. (edited)
- Every host run books through Intent's slots on the desk after vc reads its bytes; the desk's holder is estate status's control line, READ IT RATHER THAN ASSUMING (agentic-engineering-vc since 10 Nov, devbin-vc before it, and it has changed under vc twice without notice); GO by name; START and END to the holder and vc; new bytes are a new booking, and a grant records only the lane, so a head that has moved since the ask is confirmed to the holder in the exchange that grants it. (edited)
- kovacs is brew-only for Utilz; reads and changes go through kovacs-sysadm while it runs, batched by the desk's holder (estate status's control line); rustup stable 1.99.1 alone is CI's lint twin. (edited)
- hv's release rules: one release carries everything not deferred; land one change at a time on vc's word; hv runs the suites and the cut, no dry run; hv keeps cuts, tags and pushes. (edited)
- A cut's macOS leg needs hv's keychain for notarisation, so it runs in hv's own terminal and never through a Claude's shell. 2.14.10's cut on 10 Nov stopped there from vc's shell (vc decision 105).

## Decisions

- hv, 14 Sep: every hv inbox and whiteboard item comes to vc for review and closeout; cc takes its instructions from vc. (edited)
- vc, 27 Oct, on hv's no-yak-shaving rule: every booking is the smallest run that proves its change; a mutation only where reading cannot show the check fails. (edited)
- hv, 30 Oct, verbatim in intent-vc's session, relayed in its WINDOW START of 18:13Z by its date -u: "Ok, you've gone down a yak shaving rabbit hole again. I'm take control of the build and release process. I want every Cladue to mark-to-market and check in everthing to head on main and then I will run the full test suite in each case manually." intent-vc's terms: hv controls build and release, and no Claude runs a test or a build, so no booking under watch-out 17 or decision 67 opens; each node marks its true state on its board, and vc in intent/wip.md; everything is checked in to HEAD on main by literal path through the gate, in chain order; a bank outside the tree stays banked, named, for hv's ruling; nothing is pushed.
- hv, 31 Oct, first-hand in vc's session, received by vc's date -u of 14:12Z: 'Go with your recommendations on hold 24'. (2) ST0029, Retire Python, resumes after Devbin 0.1.19's sweep, owned by dc, widened to dc's census of the Python outside its scope (hold 24's text, archived with this decision, and ~/Devel/scratch/utilz-dc/python-census-20261030.txt), with xtrct's port byte-exact, since it feeds the Talga Rd accounting. (3) ST0017/04 is cancelled, with that reason on it. (4) git rm of the whiteboard's .history/ trees, 48 files, was refused by the pre-commit gate's append-only guard, since Intent's whiteboard protocol keeps .history/ append-only; vc restored all 48 from HEAD with nothing committed, withdraws the recommendation, and puts it back to hv: keep them (vc's rec), or remove them by hand past the gate, which is hv's alone. (5) vc's 15 spent messages in hv's inbox are cleared by hv's own '! intent wb clear vc --node hv', which vc then commits. 0114, hold 24's (1), stays parked on arca_swift's tag (ic's todo 13; intent/wip.md). Peers read this decision at pickup; dc records no copy.
- hv, 31 Oct, first-hand in vc's session, received by vc's date -u of 15:14Z: 'Keep them', on the whiteboard's .history/ trees (decision 79's (4)). They stay, append-only, as Intent's whiteboard protocol and the pre-commit gate's guard keep them, and nothing is removed; the TODO leaves intent/wip.md. Peers read this decision at pickup; dc records no copy.
- hv, 5 Nov, in vc's session: critic-shell's six findings in tools/post-cut that predate ST0031/04's diff are deferred past 2.14.9, into ST0031/01's re-plan, where post-cut and tools/formula retire into Devbin's core and the copies go with them. hv asked what they were, vc listed them with its rec to defer, and hv pushed main with the push lines vc had given for "defer"; vc then said it read the push as that deferral and would record it, and hv answered "Ah, ok. I read the above. Carry on." The six: IN-AG-HIGHLANDER-001, post-cut's newest-tag check a copy of tools/formula's newest_release_tag (critical, the only one with risk, which cannot fire while the copies agree); IN-SH-CODE-006, a third die() across tools/ and tag_commit copied inline; IN-SH-CODE-005, git cat-file's stderr discarded and git log's status lost inside say; IN-AG-HIGHLANDER-001, the ASSET literal beside devbin's macos.asset default. critic-shell's report: ~/Devel/scratch/utilz-dc/st0031-prep/critic-shell-post-cut-r1.md (5b3ce942). Peers read this decision at pickup; dc records no copy.
- vc, 23 Nov 2026: cc's design for STca1b7f9 (35510494: objective, context, design.md and four WPs), read against hv decision 13, is approved for its spike, M1 to M3, once vc has read the probes' bytes. Code waits on three things: the spike's results, each WP's body and acceptance criteria recorded, and hv's word on WP5, Appgate's grab point, which cc recommends and vc backs. vc's five notes to cc, sent with this read: (1) The two ways past a full-screen desktop on the laptop alone, leaving full screen or Mission Control, were vc's words in the question decision 13 answered, not hv's, so design.md says so. Turning down leaving full screen is cc's design choice, and vc tells hv it as that. (2) A void bindings record, after a reboot or a logout, falls back to today's rules until the next Save Desk. The design and help/arngz.md say so, and AC 13's steps save each desk in the same session first. (3) The design says what keeps two runs from losing each other's write of the record. The engine refuses a second apply (arngz:999-1000), and the design says whether a discover --save can run beside one. (4) WP5 is one rule: a press only where the deepest element is the web area itself, and only in the title strip. Appgate is a VPN client, so M3's point is chosen by that rule. (5) A window that newest's rule misses is left unarranged, never mis-taken, and the design says so. The spike moves hv's windows, so hv runs it in hv's own terminal, booked at the Desk. ic is second reader, on the design now and on the code before it lands, in place of dc, whom ST0031/01 holds (vc, the same day, at ic's return from hv's compact). (edited)
- vc, 23 Nov 2026: decision 111's code gate is amended. hv's word on WP5 is in: hv decision 15 left it out, and M3 with it. cc codes WP3, the round through B, and WP4's failure half, its words and their fix, now, in a worktree off main, with no run, for ic to read second. cc read that neither depends on M1, M2 or WP5, and vc takes that read. WP1, WP2 and WP4's Mission Control leg wait on the spike's results, and the spike waits on hv's return (hv decision 16). Nothing lands before ic's read and vc's check by change.

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
