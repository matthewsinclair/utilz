---
node: vc
name: Validation Claude
role: validation
session_id: 3d40d776-e1d0-40da-b5c5-7926017d5ce1
heartbeat_at: 2026-08-29 12:54Z
status: active
focus: "Coordinating ST0010 (hoist geopres -> utilz prez), hv's pen. Plan documented in ST0010 Objective+Context; synthesis with utilz-cc + _tools-{vc,cc} done; awaiting hv ratification before dispatching WPs."
claims: [ST0010]
---

# Validation Claude (vc)

Advisory authority on validation; for ST0010 hv has additionally put vc in charge of coordination ("utilz-vc has the plan"). Coordination is not ownership of the code: cc builds, vc contracts + verifies, hv adjudicates.

## DOING

- ST0010 plan: Objective + Context written to canon, synced to store and views. WP breakdown + open decisions presented to hv for ratification.
- Standing duty (hv ruling 2026-08-29, recorded in README roster): vc reads `hv/inbox.*` and surfaces contents to hv in chat.

## TODO

- On hv ratification: mint ST0010 WPs via `intent wp new`, write design.md (WP-01), dispatch WP-02/03 to cc.
- Validation pass on the hoist once landed: re-run every carried green in the new home (cargo test 111, acceptance.sh --strict 9, AT12 determinism probe, legibility probe post-ec3564a, liftability grep + unknown-theme refusal).
- Pin the hoist-source commit in ST0010 once _tools lands the mermaid.rs fix.

## Watch-outs

- **The liftability refusal is the guarantee.** After the hoist, an unknown theme name (and, in _tools, `--theme=geodica` with the env unset) must REFUSE naming built-ins + search path. If it resolves, the crate has stopped being liftable and nothing else reports it.
- **`include_str!` pins the crate layout.** `src/`, `themes/`, `assets/` are compile-time siblings (`theme.rs:55-61`, `mermaid.rs:21`); the crate directory travels as one unit or it does not compile.
- **`examples/demo.md` does not opt into mermaid** (its `mermaid: true` is documentation inside a fenced yaml block). Diagram/determinism checks must also point at `examples/test_pres.md`. Bit _tools three times.
- **acceptance.sh defaults to exit 0 with named SKIPs** -- six of nine ATs skip without Node/Chrome. Always `--strict`; in CI, prove the browser was found.
- **Contrast figures go stale by selector.** Four corrections in two days, each from a strictly wider selector; current honest floor-nearest is mono 4.9:1 (flattened, every text element, `bfd0349`). Any quoted worst-case must cite selector + commit.
- `utilz test` is not safe to run concurrently (helper mutates `$UTILZ_HOME/bin`). One suite at a time.
- The framework `VERSION` (2.4.0) and the `intent` tooling version (3.0.0) are different numbers.

## Decisions

- (2026-08-29) ST0010 is claimed by vc as coordinator; cc executes the build WPs under it. Exception to vc's no-claims default, made explicitly at hv's direction.
- (2026-08-29) `_tools` AC01 (Dropbox target-dir hygiene) is NOT transcribed into ST0010: Utilz is outside Dropbox and its `local` remote is bare. The hygiene lessons transfer as ST0010's own criteria; the Dropbox justification does not.
- (2026-08-29) Mermaid palette fix (`mermaid.rs:37`) lands in `_tools` BEFORE the hoist; the commit landing it green is the hoist pin. Rationale in ST0010 Context.
