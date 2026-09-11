---
node: vc
name: Validation Claude
role: validation
session_id: 11981560-5612-4fe7-a136-6eae64636b64
heartbeat_at: 2026-09-11 08:44Z
status: active
focus: "ST0017 culled to market by hv 2026-09-11: 49 satisfied, ONE open (AC-6.3, an 11-line edit), 8 withdrawn. WP-01/02/03/05 done, WP-04 deferred, WP-06 WIP. No new code, no new tests."
claims: [ST0017]
---

# Validation Claude (vc)

Validation node. cc builds, vc holds the contract, snorkeltoast owns the reference and harness, hv adjudicates. **Culled 2026-09-11 08:44Z on hv's instruction.** The pre-cull board is `.history/20260911/wip-before-cull.md`; the day narratives are in the earlier folds. This board carries only what is outstanding and the rulings that still bind.

## DOING

- **Close ST0017.** The ST's Done (info.md) is met: build from the real config, verified by a named instrument, one shared crate, prez's contract unchanged. Contract 49 satisfied, 1 open, 8 withdrawn, doctor 0.

## TODO

- **AC-6.3, the honest partial. cc's edit, 11 lines, no new code.** Nine fixture lines, one test literal swapped, one deleted. vc verifies with `git grep -P` over the name tokens, closes the row, marks WP-06 done, then `intent st done ST0017`.

## Holds

_(none)_

## Deferred out of this round by hv, 2026-09-11

- **WP-04, Rust `init` and `qr`.** The port dispatches `check` and `build` only. The 45h masters and QRs exist from the Python init and the Rust build consumes them. AC-3.4, AC-4.1, AC-4.2 and AC-5.3 carry the deferral reason; a follow-on thread reinstates them if hv wants init in Rust.
- **The harness's floors derivation (was AC-2.19) and the one-off control pass on the port artifact.** Instrument work; no shipped outcome depends on either. snorkeltoast's to pursue in their own repo if they choose.

## Rulings that still bind

- **`MAX_EASE_MS` is 2400 in both implementations. hv's safety cap.** Restoring the reference's 3000 reverses a ruling. Python capped at snorkeltoast `cf89cd9`: two bytes of artifact change, no pixel.
- **The JPEG encoder divergence is accepted** (AC-3.15). `image`'s baseline encoder stays. Parity would need a new crate, hv's named sign-off, and the AT03 manifest gate moved in the same commit.
- **The dependency budget is gated**, not disciplined: `tests/manifest.rs`. Any crate addition returns to hv.
- **The reference player's brand fallback stays** until after the 19th.
- **The honest partial** (AC-6.3): the stage handle, AC-6.1's evidence and the append-only boards keep the name by ruling.
- **`upstream` is frozen** (CI credits). `local` is pushed on hv's word only; it is 8 behind HEAD as of this cull.

## Watch-outs

- **`git grep -E` does not honour `\b`.** Use `-P`. Prove a composite pattern by deleting a clause and re-counting.
- **A count without its pattern and its unit cannot be compared with anyone else's.** 12 lines and 13 occurrences of one population are both correct.
- **A relayed ruling is not the ruling.** Both peers held on vc's relay of hv and were right to. hv's word lives in `hv/wip.md`.
