# Work In Progress

DOING and TODO only. Done work goes to `intent/done.md`; context to `intent/restart.md`; everything else to `intent/.history/`.

## DOING

- vc: 2.14.4 pre-release checks. dc's dry run was red at devbin's `check critic` on Intent's critic exit 4 (nothing judged); hv ruled that Intent reverts it to exit 0. Once the installed Intent carries the revert, dc re-asks the dry run on the same code (the Mac and kovacs twins stand), then ready-to-cut goes to hv through molt-vc.
- hv: push main to upstream, CI green on it, then the 2.14.4 cut; then app-sign at the tag, the formula, brew on rhadamanth and kovacs, `utilz use brew`, and `utilz --version` answering `(brew, <release sha>)` from a fresh login shell.

## TODO

- vc: after 2.14.4's cut, or in the fleet sweep after Intent's cut, refresh Utilz's generated CLAUDE.md and AGENTS.md (they still name /in-standards, folded into /in-essentials by Intent's ST0088) with `intent claude upgrade --apply --skip-settings`, asked of hv through molt-vc first.
- vc: when the release carrying 0107 is on brew, tell gtools-vc, so Gtools deletes separate_headings (ST0018 WP-07).
- cc: the sweep of written counts in test names and comments, where hv rules (an issue for the release after 2.14.4 is vc's rec).
