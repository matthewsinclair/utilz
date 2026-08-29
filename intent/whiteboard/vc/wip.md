---
node: vc
name: Validation Claude
role: validation
session_id: 3d40d776-e1d0-40da-b5c5-7926017d5ce1
heartbeat_at: 2026-08-29 13:13Z
status: active
focus: "ST0010 contract RATIFIED by hv on all three nodes. WP-01 done (17 ACs / 14 ATs / 6 WPs, gate 0/17 BLOCKED). Pin 3e16597. cc in flight on WP-02, released on WP-03. WP-04 validation is mine and waits on the hoist."
claims: [ST0010]
---

# Validation Claude (vc)

Advisory authority on validation; for ST0010 hv has additionally put vc in charge of coordination ("utilz-vc has the plan"). Coordination is not ownership of the code: cc builds, vc contracts + verifies, hv adjudicates.

## DOING

- **WP-01 DONE.** design.md + the contract are in the store and ratified by hv: 17 ACs, 14 ATs, 6 WPs. Gate reads 0/17 BLOCKED, which is the truth -- nothing is proven in THIS repo yet.
- Coordinating the three build nodes. cc holds WP-02 (substrate; the `opt/*/crate/target/` fence and `lang init rust` are already in) and is released on WP-03 (the hoist).
- Standing duty (hv ruling 2026-08-29, in the README roster): vc reads `hv/inbox.*` and surfaces contents to hv in chat.

## TODO

- **WP-04 (mine), on cc's hoist signal**: re-produce every carried green with instruments run HERE -- cargo test (111 at the pin), `acceptance.sh --strict` (10/0/0 at the pin), AT12, the post-`ec3564a` legibility probe, the liftability refusal, the standalone greps. Walk ATs through red where the lifecycle requires. Satisfy AC16 (eyeball) and AC17 (provenance) by named evidence. State what was NOT checked.
- **WP-06 spec is written (design section 10); it follows WP-04.** AT14 is red-first against the pinned binary by construction.
- Announce prez green to `_tools-cc` -- that is their signal to land the client rewrite + `geodica doctor` check in one commit. Until then `geodica present` keeps working against its local binary; no breakage window.

## Watch-outs

- **The liftability refusal is the guarantee.** After the hoist, an unknown theme name (and, in _tools, `--theme=geodica` with the env unset) must REFUSE naming built-ins + search path. If it resolves, the crate has stopped being liftable and nothing else reports it.
- **`include_str!` pins the crate layout.** `src/`, `themes/`, `assets/` are compile-time siblings (`theme.rs:55-61`, `mermaid.rs:21`); the crate directory travels as one unit or it does not compile.
- **`examples/demo.md` does not opt into mermaid** (its `mermaid: true` is documentation inside a fenced yaml block). Diagram/determinism checks must also point at `examples/test_pres.md`. Bit _tools three times.
- **acceptance.sh defaults to exit 0 with named SKIPs** -- six of nine ATs skip without Node/Chrome. Always `--strict`; in CI, prove the browser was found.
- **Contrast figures go stale by selector.** Four corrections in two days, each from a strictly wider selector; current honest floor-nearest is mono 4.9:1 (flattened, every text element, `bfd0349`). Any quoted worst-case must cite selector + commit.
- `utilz test` is not safe to run concurrently (helper mutates `$UTILZ_HOME/bin`). One suite at a time.
- The framework `VERSION` (2.4.0) and the `intent` tooling version (3.0.0) are different numbers. ST0010 releases as **2.5.0** (new utility, minor -- the v2.3.0 precedent); tag + push are hv's.
- **Build provenance is a real seam, not a formality** (AC17). At the pin, the binary on disk predated its own source commit by 3.5 minutes -- a true green that could not name its instrument. If Utilz numbers disagree with `_tools`' (10/0/0, 111), check provenance BEFORE suspecting the port.
- **A green is a licence to look, not a substitute for looking** (AC16, `_tools-cc`). Their diagram-font defect passed a green determinism probe: deterministically wrong is still wrong.
- 9 unpushed commits at 13:13Z; both remotes at `367a75a`. Pushing is hv's.

## Decisions

- (2026-08-29) ST0010 is claimed by vc as coordinator; cc executes the build WPs under it. Exception to vc's no-claims default, made explicitly at hv's direction.
- (2026-08-29) `_tools` AC01 (Dropbox target-dir hygiene) is NOT transcribed into ST0010: Utilz is outside Dropbox and its `local` remote is bare. The hygiene lessons transfer as ST0010's own criteria; the Dropbox justification does not.
- (2026-08-29) Mermaid palette fix (`mermaid.rs:37`) lands in `_tools` BEFORE the hoist; the commit landing it green is the hoist pin. Rationale in ST0010 Context.
- (2026-08-29) The contract is ratified as the boundary: 17 ACs. Two are non-test and satisfied by named evidence rather than by a passing test -- AC16 (a human looks at the render) and AC17 (the binary was built from a clean checkout of the pin). Both exist because the automated suite provably could not stand in for them on `_tools`.
- (2026-08-29) `_tools` AC08's addressing clause is deliberately NOT transcribed with the rest of AC08; it is excised to AC15, the post-split semantics. Validating a resolution order we are about to break would produce a green that means nothing, and one AC is never edited twice.
