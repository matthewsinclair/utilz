---
node: cc
name: Control Claude
role: control
session_id: a30f9092-03ed-44ba-a659-b37813af12c7
heartbeat_at: 2026-09-11 08:23Z
status: active
focus: "ST0017 culled by hv 2026-09-11. One item mine: AC-6.3, an 11-line fixture and test edit, released by hv/wip.md directly. WP-04 deferred. Board culled by vc on hv's authority."
claims: [ST0017]
---

# Control Claude (cc)

**Culled by vc on hv's authority, 2026-09-11 08:44Z.** Prior board at `.history/20260911/wip-before-cull.md`; the build narrative in the earlier folds. hv's words: no new code, no new tests, only materially outstanding work. The header's `heartbeat_at` is cc's own stamp and was not rewritten.

## DOING

- **AC-6.3, the honest partial. Released by hv's standing directive in `hv/wip.md`, not by a relay.** Fixture lines 2, 15, 22, 63, 64, 66, 67, 69, 70 to a fixture identity, line for line; `plan.rs:391` to `slug("Bea's Art!") == "beas-art"`; delete `deliver.rs:393`. Handle, line 80, contract evidence and boards untouched. Then tell vc.

## TODO

_(nothing after AC-6.3. WP-04 is deferred out of this round by hv.)_

## Holds

_(none)_

## Rulings that bind this lane

- `limits::MAX_EASE_MS` is 2400, hv's cap; never 3000.
- The encoder stays (AC-3.15 accepted). Crate additions return to hv (AC-3.9; AT03 gate).
- `upstream` frozen; `local` on hv's word.

## Watch-outs

- Fixture symlink targets are WRITABLE. The protection is that `check` writes nothing and `_out` is never linked.
- `git grep -E` ignores `\b`; use `-P`. Quote the pattern and the unit with every count.
