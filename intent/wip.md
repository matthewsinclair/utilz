---
verblock: "23 Nov 2026:v1.55: matts - STca1b7f9 code under way"
---

# Work In Progress

## DOING

- cc: STca1b7f9, arngz for apps with windows on several desktops and a route past a full-screen desktop, on branch cc/stca1b7f9 (worktree ~/Devel/scratch/utilz-cc/wt-stca1b): WP3 and WP4's failure half at 8620c933, read by ic; issue Ib12d894's fix and WP6 (issue I7fce35c) next, with no run (vc decision 112); the spike (M1, M2) on hv's return, its ask TM15WA queued at the Desk; then WP1, WP2, WP4's Mission Control leg and WP6's create once the spike's results are read; then the thread's one Desk run, with ic's parts in it. WP5, Appgate's grab point, is out (hv decision 15).
- ic: STca1b7f9's toast parts (AC-dca427e7.3, AC-ad94d40b.2, AC-322a6511.9) and issue I4eacd29, stacked on cc's branch for the thread's one Desk run.
- dc: ST0031/01 with /02, on branch dc/st0031-01 at eec4b900 (worktree ~/Devel/scratch/utilz-dc/wt-st0031-01): one booked run with its driver, run-st0031-01.sh (7705761a), its heavy ask queued at the Desk to go after the spike's END; then /01 and /02 land together on vc's word, and hv's push proves /02 on CI.
- ic: STb8e4fb6, `showreel qr`, the qr half of ST0017's deferred WP-04, in this release (hv decision 15), with issue I88af1f3's warning riding it: code on ic/stb8e4fb6 at 1ae82d9d, read second by dc (r1 and r2); its booked run, run-qr.sh (8b3ce0d4), queued at the Desk behind dc's; then the landing on vc's word. Main's CI goes green with it after hv's push.

## TODO

- hv: on return, a word to devbin-vc to reopen the Desk, closed since 12:52Z; then STca1b7f9's spike in hv's own terminal, `zsh ~/Devel/scratch/utilz-cc/stca1b/spike/spike.zsh` behind its sha check (7ad7ec55), with vc giving the command at the grant.
- dc: prez.bats's missing CI job, filed as a low issue with ST0031/01's landing records.
- hv: STca1b7f9's live run on the dev tree: Save Desk each desk, Screen Sharing and Parallels back in full screen, zeopit plugged in, rhad unplugged; and a phone scan of one QR `showreel qr` wrote (AC-702cceb9.8).
- hv: the cut, once ST0031, STca1b7f9 and `showreel qr` have landed and main's CI is green.
- devbin-cc: issue I59c806c, devbin#0326's install and use, after ST0031/01 lands.
- ic: issue 0114, once arca_swift tags its issue 0003's fixes.
- dc: ST0029, Retire Python, once hv lifts its hold.
