---
verblock: "23 Nov 2026:v1.57: matts - showreel qr landed"
---

# Work In Progress

## DOING

- cc: STca1b7f9, arngz for apps with windows on several desktops and a route past a full-screen desktop, on branch cc/stca1b7f9 (worktree ~/Devel/scratch/utilz-cc/wt-stca1b): WP3, WP4's failure half, issue Ib12d894's fix and WP6 but its create (issue I7fce35c) at 3efc3397, read by ic, with no run (vc decision 112); spike v3 (M1, M2) on hv's ready; then WP1, WP2, WP4's Mission Control leg and WP6's create once the spike's results are read; then the thread's one Desk run, with ic's parts in it. WP5, Appgate's grab point, is out (hv decision 15).
- ic: STca1b7f9's toast parts (AC-dca427e7.3, AC-ad94d40b.2, AC-322a6511.9) and issue I4eacd29, stacked on cc's branch for the thread's one Desk run.
- dc: ST0031/01 with /02, on branch dc/st0031-01 at eec4b900 (worktree ~/Devel/scratch/utilz-dc/wt-st0031-01): one booked run with its driver, run-st0031-01.sh (7705761a), its ask FF5TB4 live at the Desk for a free cargo or bats lane; then /01 and /02 land together on vc's word, and hv's push proves /02 on CI.

## TODO

- hv: "ready" to vc for STca1b7f9's spike in hv's own terminal, `zsh ~/Devel/scratch/utilz-cc/stca1b/spike/spike.zsh` behind its sha check (2692ed78, v3), with vc giving the command at the grant.
- hv: the push of main, whose CI run proves STb8e4fb6's AC-702cceb9.7 (`showreel qr`'s use of `qrcode` clears Rust 1.100.0's unused_dependencies warning); ic satisfies it from that run's id.
- dc: prez.bats's missing CI job, filed as a low issue with ST0031/01's landing records.
- hv: STca1b7f9's live run on the dev tree: Save Desk each desk, Screen Sharing and Parallels back in full screen, zeopit plugged in, rhad unplugged; and a phone scan of one QR `showreel qr` wrote (AC-702cceb9.8).
- hv: the cut, once ST0031 and STca1b7f9 have landed and main's CI is green.
- devbin-cc: issue I59c806c, devbin#0326's install and use, after ST0031/01 lands.
- ic: issue 0114, once arca_swift tags its issue 0003's fixes.
- dc: ST0029, Retire Python, once hv lifts its hold.
