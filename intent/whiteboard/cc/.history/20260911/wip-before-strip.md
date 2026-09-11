---
node: cc
name: Control Claude
role: control
session_id: a30f9092-03ed-44ba-a659-b37813af12c7
heartbeat_at: 2026-09-11 08:50Z
status: active
focus: "ST0017 at its Done. AC-6.3 landed 58a0bb0 and vc closed it; WP-06 done; doctor 0, 289 tests, contract 50 satisfied / 0 open / 8 withdrawn, verified here not carried. intent st done, the tag and both pushes are hv's. Nothing queued for me."
claims: [ST0017]
---

# Control Claude (cc)

**Culled by vc on hv's authority, 2026-09-11 08:44Z.** Prior board at `.history/20260911/wip-before-cull.md`; the build narrative in the earlier folds. hv's words: no new code, no new tests, only materially outstanding work. The header's `heartbeat_at` is cc's own stamp and was not rewritten.

## DOING

- **NOTHING. ST0017 IS AT ITS DONE AND THE LAST ROW WAS MINE.** AC-6.3 landed at `58a0bb0`, vc closed it at `bfafbf3`. Verified here rather than taken: doctor 0, contract 50 satisfied / 0 open / 8 withdrawn, five WPs Done, WP-04 `Not Started` as the deferred follow-on. **`intent st done`, the tag and both pushes are hv's** -- `local` is behind HEAD and `upstream` is frozen at `60153d8`.

## TODO

_(empty. WP-04 is deferred out of this round by hv; if it reopens it brings back its four rows, the write-set check on its diff, and the one-off control pass.)_

## Holds

_(none)_

## Rulings that bind this lane

- `limits::MAX_EASE_MS` is 2400, hv's cap; never 3000.
- The encoder stays (AC-3.15 accepted). Crate additions return to hv (AC-3.9; AT03 gate).
- `upstream` frozen; `local` on hv's word.

## Watch-outs

- Fixture symlink targets are WRITABLE. The protection is that `check` writes nothing and `_out` is never linked.
- `git grep -E` ignores `\b`; use `-P`. Quote the pattern and the unit with every count.
- **`intent sync --to-store` re-reads an authored attachment from disk; `--to-disk` does not.** vc's, earned on ST0017's `design.md`: a doctor hash divergence on an attachment cannot be re-derived from either side, so back the file up OUTSIDE the project first, then `--to-store` is the direction that ingests it.
- **A relayed ruling is not the ruling, and hv's board is the channel that closes it.** Held twice on WP-04 and on the de-identify; both times hv's own `Standing directives` released me, and hv added a directive telling peers to keep doing exactly that.
