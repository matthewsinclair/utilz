---
verblock: "24 Nov 2026:v1.66: matts - end-of-day docs sync"
---

# Work In Progress

## DOING

- Utilz holds for hv's word on 25 Nov 2026 (hv decision 21).

## TODO

- hv: "ready" to vc for STca1b7f9's spike v3 in hv's own terminal (vc hold 31); cc asks the Desk, and vc gives hv the command at the grant.
- cc: STca1b7f9's WP1, WP2, WP4's Mission Control leg and WP6's create, once the spike's results are read; then the thread's one Desk run. Issue I7fce35c closes with AC-322a6511.6, .7 and AC-026eadfc.1 to .4.
- hv: STca1b7f9's live run on the dev tree, and a phone scan of one QR `showreel qr` wrote (AC-702cceb9.8), which closes STb8e4fb6.
- hv: the cut, once STca1b7f9 has landed and main's CI is green; it proves ST0031 AC-01.4.
- hv: 0114, whether ic fixes arca_swift issue 0003 first.
- dc: issue Ibf2b53b, opt/prez/test/prez.bats runs in no CI job.
- dc: docs/developer-guide.md still has 1.0.0 and ^1.0.0 examples (lines 266, 267, 371) and 9 em-dashes; the test_helper.bash comment at lines 34-36 says a fake source holds no bin/devbin.
- dc: help/utilz.md's 1.0.0 version history and its own list of common functions; opt/utilz/tmpl/README.tmpl still mints the long "Personal use" README.
- cc: opt/lnrel/lnrel.yaml and opt/cleanz/cleanz.yaml declare no dependencies (lnrel needs GNU realpath; cleanz needs exiftool and clipz); bin/utilz's comments say "fifteen utilities".
- ic: mdagg --strip-front-matter cuts any --- block, not only one at line 1; macoz setpicfor parses --pattern and never uses it, and its --dry-run still needs fileicon; prez.yaml says stdin input and "comrak is the only crate"; prez's USAGE omits present -o.
- dc: ST0029, Retire Python, once hv lifts its hold.
