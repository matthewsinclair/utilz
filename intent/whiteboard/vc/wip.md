---
node: vc
name: Validation Claude
role: validation
session_id: 3d40d776-e1d0-40da-b5c5-7926017d5ce1
heartbeat_at: 2026-08-29 13:26Z
status: active
focus: "ST0010 coordination pen. WP-01/02 Done, WP-03 hoist WIP and BLOCKED on a new _tools pin. Contract 18 ACs / 15 ATs / 7 WPs, gate 0/18 BLOCKED. WP-04 validation is mine and starts on cc's hoist signal."
claims: [ST0010]
---

# Validation Claude (vc)

Validation node. For ST0010, hv additionally gave vc the coordination pen ("utilz-vc has the plan"). Coordination is not ownership of code: cc builds, vc contracts and verifies, hv adjudicates. Session history in `.history/20260829/`.

Status stays `active` through this compact deliberately -- `/compact` does not end a session (whiteboard invariant 6), and hv has said work continues on the bounce. A `release` here would put a false `paused` on the board.

## THE ONE BLOCKING FACT

**A new `_tools` pin is pending and nothing may be archived until it arrives.** `3e16597` is superseded. `_tools-cc` is cutting a commit carrying four things, then re-freezing and sending me the sha:

1. `--use-mock-keychain` on **all four** Chrome launch sites (`:244` AT04, `:371` AT07, `:482` AT08, `:545` AT12).
2. Disposable `--user-data-dir` at `:371` and `:482`, which today launch against hv's REAL Chrome profile.
3. AT12 launch count reduced from eight browser instances to one (`_tools-vc`'s fix; the flag treats the symptom, the count is the amplifier).
4. `chrome()` resolving through ONE browser list -- AC18(a), promoted into their patch so cc and they are not editing the same twelve lines.

**On receipt: relay the sha to utilz-cc immediately.** They have already archived once from `3e16597` and will re-archive rather than patch in place (AC17 provenance: the tree built must be the tree the sha names).

## DOING

- Holding the pen. Awaiting the pin sha from `_tools-cc`.
- WP-03 is cc's and in flight on its pin-independent half (shim, `prez.yaml`, `bin/prez`, `help/prez.md`, README) -- none of that comes from the archive.

## TODO

- **WP-04 (mine), on cc's hoist-green signal.** Re-produce every carried green with instruments run HERE: `cargo test` (111 at the pin), `acceptance.sh --strict` (10/0/0 there), AT12, the post-`ec3564a` legibility probe, the liftability refusal, the standalone greps. Walk ATs through red where the lifecycle requires. Satisfy AC16 (eyeball -- prepare the renders, hv supplies the eye) and AC17 (provenance) by named evidence. State what was NOT checked.
- Announce prez-green to `_tools-cc`: their signal to land the `geodica present` client rewrite + `geodica doctor` check in one commit. Until then their shim keeps working against the local binary; no breakage window.
- WP-06 spec is written (design section 10); WP-05 last; WP-07 deferred.

## Open with hv

- **CI is RED on `main`** and it is not ours. `05bca08 Installed devbin` vendored 33 files; the blocking shellcheck gate sees 34 SC1091 findings, **all inside devbin, none in Utilz-owned files**. Fix verified by me: exclude devbin from the collector -> 15 files, clean, exit 0. Annotating inside devbin is wrong -- `bin/.devbin/manifest.sha256` declares those files, so a directive there is manifest-detectable drift. hv's call under the issue-driven standing directive. It blocks WP-02/03 from ever _reading_ green.
- **Did a Keychain dialog pop at ~14:18 local?** I ran one bounded `--use-mock-keychain` verification. Flag accepted, Chrome renders, no keychain error -- but absence of a dialog on hv's screen is not observable from a shell, and AT15's note records that limit rather than papering it.
- 16 unpushed commits, both remotes at `367a75a`. Pushing is hv's.

## Watch-outs

- **Two known harness causes will redden the FIRST Linux CI run, neither a port defect.** (i) the browser-probe two-list drift (AC18a; `chrome()` had 2 macOS paths, `drive.rs` has 4 + 6 PATH names, so on Linux the tool finds a browser and the harness does not, five ATs skip, `--strict` reddens a correct build); (ii) `AT01` sizing the binary with BSD-only `stat -f %z`, which returns nothing on Ubuntu, reads 0, and fails the 8 MB ceiling. Check both before suspecting the port.
- **The rename sweep has three coordinated sets and must be atomic**: theme const + refusal string + the AT asserting it; the `SENTINEL=` literal and its twin payload in `examples/demo.md`; the binary name throughout. cc measured 110 occurrences across 19 files.
- **The liftability refusal is the guarantee.** An unknown theme must REFUSE naming built-ins + search path. If `--theme=geodica` ever resolves on bare prez, the crate has stopped being liftable and nothing else reports it.
- **`include_str!` pins the layout**: `src/`, `themes/`, `assets/` are compile-time siblings. The crate travels as one unit or it does not compile.
- **`examples/demo.md` does not opt into mermaid** (its `mermaid: true` is documentation inside a fence). Diagram and determinism checks must point at `examples/test_pres.md`; demo.md is the labelled negative control. Bit `_tools` three times.
- **`acceptance.sh` defaults to exit 0 with named SKIPs.** Always `--strict`, and in CI prove a browser was found.
- **Contrast figures go stale by selector** -- four corrections in two days. Current honest floor-nearest is mono 4.9:1 (flattened, every text element, `bfd0349`). Any quoted figure cites selector + palette + commit.
- **A green is a licence to look, not a substitute for looking** (AC16). `_tools-cc`'s diagram-font defect passed a green determinism probe.
- **Build provenance is a real seam** (AC17). At the pin a binary predated its own source commit by 3.5 minutes. If our numbers disagree with `_tools`' (10/0/0, 111), check provenance before suspecting the port.
- `utilz test` is not safe to run concurrently (the helper mutates `$UTILZ_HOME/bin`). Verify shell tooling under `/bin/bash` with an array, never zsh with an unquoted variable.
- Framework `VERSION` 2.4.0 and `intent` 3.0.0 are different numbers. ST0010 releases as **2.5.0**; tag and push are hv's.

## Decisions

- (2026-08-29) ST0010 claimed by vc as coordinator; cc executes the build WPs. Explicit exception to vc's no-claims default, at hv's direction.
- (2026-08-29) `_tools` AC01 NOT transcribed: Utilz is outside Dropbox and its `local` remote is bare, so it would gate a hazard that does not exist here. The hygiene lessons transfer as this thread's own criteria; the Dropbox justification does not.
- (2026-08-29) AC08's addressing clause is excised to AC15 rather than transcribed then edited -- validating a resolution order we are about to break yields a green that means nothing, and one AC is never edited twice.
- (2026-08-29) Two non-test ACs, satisfied by named evidence rather than a passing test: AC16 (a human looks at the render) and AC17 (the binary was built from a clean checkout of the pin). Both exist because the suite provably could not stand in for them.
- (2026-08-29) **The freeze protects utilz-cc from drift; it does not make the pin sacred.** Two findings, opposite rulings, and the difference is in the facts: the keychain modal is actively harming and testable where it lives, so it is patched in `_tools` and the pin moves; the Linux browser-probe drift is invisible and untestable there, so it is fixed in Utilz WP-02 where the CI that exposes it is written.
- (2026-08-29) Two checks measuring the same PROPERTY by different mechanisms are duplication; two measuring DIFFERENT properties are not (`_tools-cc`'s refinement). So the estate's static grep on its generated CSS and prez's runtime determinism verb both stand, and neither is a second home.
