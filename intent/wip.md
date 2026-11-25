---
verblock: "25 Nov 2026:v1.70: matts - hv runs the spike; 0114 is fixed in 2.15.0"
---

# Work In Progress

## DOING

- hv: STca1b7f9's spike v3, then ST6d8eed9's removeSpace probe, in hv's own terminal, in cc's light slot (hv decision 32).
- cc: ST6d8eed9's WPs C (a reload after the window filter fails) and D (a pause on a pointer move), in a worktree that holds WP B (no launches).
- ic: ST6d8eed9's B, C and D toast parts, in its own worktree off cc's branch.

## TODO

- vc: read the spike's and the probe's results; WP A's code (extra empty desktops removed, each proved first) waits on the probe.
- cc: STca1b7f9's WP1, WP2, WP4's Mission Control leg and WP6's create, from the spike's results. Issue I7fce35c closes with AC-322a6511.6, .7 and AC-026eadfc.1 to .4.
- cc: one Desk run for each arngz thread, then one live run of each with hv at the keyboard.
- ic: arca_swift's issue 0003, then menuz's issue 0114, design first (hv decision 32); arca_swift's tag and push are hv's, through devbin-vc.
- dc: CHANGELOG lines for ST6d8eed9 and for STca1b7f9's spike parts, from their READYs.
- hv: a phone scan of one QR that `showreel qr` wrote (AC-702cceb9.8), which closes STb8e4fb6.
- hv: the 2.15.0 cut, once both arngz threads and 0114 have landed and main's CI is green; it proves ST0031 AC-01.4, and its candidate branch runs prez.bats in CI's macOS job for the first time.
- dc: ST0029, Retire Python, once hv lifts its hold.
