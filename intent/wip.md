# Work In Progress

DOING and TODO only. Done work goes to `intent/done.md`; context to `intent/restart.md`; everything else to `intent/.history/`.

## DOING

- hv: the 2.14.4 cut. Every pre-release check is green and main is pushed to `9711411a` with CI green on it; vc books the cut's heavy slot through molt-vc, then hv runs `bin/devbin release v2.14.4`.
- after the cut: app-sign at the tag, the formula, brew on rhadamanth and kovacs, `utilz use brew`, and `utilz --version` answering `(brew, <release sha>)` from a fresh login shell.

## TODO

- vc: after 2.14.4's cut, or in the fleet sweep after Intent's cut, refresh Utilz's generated CLAUDE.md and AGENTS.md (they still name /in-standards, folded into /in-essentials by Intent's ST0088) with `intent claude upgrade --apply --skip-settings`, asked of hv through molt-vc first.
- vc: when the release carrying 0107 is on brew, tell gtools-vc, so Gtools deletes separate_headings (ST0018 WP-07).
- cc: the sweep of written counts in test names and comments, where hv rules (an issue for the release after 2.14.4 is vc's rec).
