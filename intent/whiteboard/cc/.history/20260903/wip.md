# cc board, archived 2026-09-03

Folded out of the live board at the localfold before hv's compact. Everything here is DONE; nothing in this file is live state. The day's substance lives in ST0011's Context, `intent/done.md` and the commit log -- this is the board's own record of it.

## DOING, as it stood at close

**Nothing in flight.** ST0011 (`stampz`) closed 3 Sep at 11/11. hv pushed at `560ac49`; CI run `33785732770` is green on all seven jobs and **stampz ran 22/22 with ZERO skips on both legs** -- checked by grepping the logs for the suite's own `needs qpdf and poppler` skip reason (0 occurrences) rather than inferred from the green, because a suite that skipped everything exits 0 too. Every AT executed on machines that had never built a stamp.

The day's full narrative -- four defects, three of them in checks; the Emacs menu pruned 13 -> 6; the corrections traded with `lamplight-ac` -- is in ST0011's Context, `intent/done.md`, and this board's history. **ST0010 remains vc's and untouched apart from `prez.bats`.**

## TODO items completed today

- **ST0011/WP-02 next: the native stamp renderer.** Byte offsets for the xref are MEASURED (`wc -c` before each append), never computed from `${#s}`, which counts characters rather than bytes and is correct only under `LC_ALL=C` on a pure-ASCII recipient. Do not fall back on letting qpdf reconstruct a bogus xref: it repairs with a warning and exit 3, and a silent-repair dependency in this thread would be self-parody.
- **ST0011/WP-05 must add `stampz` to the hardcoded roster in `test-linux`.** `test-macos` derives its roster from `utilz list` and picks it up for free; Linux does not, and nothing reports the gap. Both legs need `qpdf` + poppler installed so the suite's skip path is never the path CI takes.
- `ST0007/WP-04` is `wip` under a completed thread. Not the migrator: the v2 source itself says WIP. Ours to fix, small.
- **ST0002's six WPs read `not-started`** under a thread completed 2026-02-08 -- the v3 migrator defaulted them and `intent doctor` reports nothing. hv ruled not-today.
