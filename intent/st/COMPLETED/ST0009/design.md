# Design - ST0009: Framework core: single bin walker, single YAML parser, correct generator floor

## Approach

Three defects in `opt/utilz/lib/common.sh` and `opt/utilz/tmpl/metadata.tmpl`, landed as one change because they share a file and must be tested together. Two are Highlander collapses (five walkers to one, two parsers to one); the third is a latent shipped bug in the generator (`intent/issues/OPEN/0002`).

The code was written before this steel thread existed -- see info.md Context for the full provenance. The substance of the thread is therefore the **test coverage for the new seams**, plus documentation reconciliation and the release call.

## Design Decisions

### `each_utility()` -- THE walker

Emits the name of every installed utility, one per line: a symlink in `bin/` that resolves to the dispatcher, excluding the dispatcher itself. Five consumers (`list_utilities`, `run_doctor` x2, `run_tests`, `emit_integration_tsv`, `emacs_doctor`) now read it and nothing else.

**Consume with process substitution, never a pipe:**

    while IFS= read -r name; do ...; done < <(each_utility)

A pipe puts the loop body in a subshell, so accumulator arrays (`broken_utils`, `utils_to_test`, `missing_deps`) are discarded when the loop ends. This is not style -- `run_doctor` and `run_tests` both accumulate, and both would silently report nothing.

The drift this closes: `list_utilities` and `run_tests` checked that `readlink` resolved to `utilz`; `run_doctor` (both loops), `emit_integration_tsv`, and `emacs_doctor` accepted any symlink in `bin/`. A stray symlink was therefore a utility to `doctor` and not to `list` -- the classic Highlander failure where two copies of one rule answer differently.

### `require_yq()` -- THE gate

`yq` is the single YAML parser; `require_yq` is the one place that reports its absence.

**A loop-caller must call it ONCE, before the loop.** `get_util_metadata` runs inside command substitution, so it cannot memoise anything -- a subshell's variables die with it. This is not theoretical: the first cut of `require_yq` carried a memoised state variable, and `utilz list` reprinted the install hint thirteen times, once per utility. The memo is gone; `list_utilities` gates up front, `run_doctor` resolves `have_yq` once at the top.

### Why `run_doctor` does not call `require_yq`

`doctor` is the command you run **to find out** that `yq` is missing. If it bailed on the gate it could not do its job. It resolves `have_yq` once up front and branches: check 5 skips version-compatibility (which needs the YAML), check 6 reports `yq` by hand.

Check 6 reports `yq` first and by hand for a reason easy to miss: **parsing YAML to discover that the YAML parser is missing does not work.** Every dependency declaration lives in a `.yaml` file, so the framework's own hard dependency must be checked before, and outside, the declaration-driven walk. Check 6 also walks `utilz` itself, unlike checks 3 and 5 -- `opt/utilz/utilz.yaml` now declares `yq`, and a declaration no check ever reads is a declaration in name only.

### Error contract

`get_util_metadata` returns 1 when the YAML file is absent or `yq` is missing, where it previously produced an empty string indistinguishable from an absent key. Callers that tolerate absence say so explicitly:

    desc=$(get_util_metadata "$name" ".description") || desc=""

Verified blast radius: `get_util_metadata` has **no callers outside `common.sh`**, so no utility inherits a new `set -e` abort path.

### Generator floor

Derived from the framework's own `VERSION`, never written into the template:

    local utilz_floor="^$(get_utilz_version | cut -d. -f1).0.0"

`metadata.tmpl` carries a `{{UTILZ_FLOOR}}` placeholder substituted at generation time alongside `{{NAME}}` / `{{DESCRIPTION}}` / `{{AUTHOR}}`. A hardcoded floor is a constant that must be hand-maintained in lockstep with `VERSION`; deriving it means the next major bump needs no template edit.

## Architecture

Compatibility constraints:

- **bash 3.2** (macOS system bash). Process substitution, `local`, `for ((;;))`, and guarded array expansion are all 3.2-safe; no namerefs, no `${var,,}`. Verified against `/bin/bash 3.2.57` under `set -euo pipefail`: `each_utility`, `require_yq`, `get_util_metadata` (both the inline-`version` and `version_file` paths), full `doctor` and `list` runs, and the yq-absent path on a stripped `PATH`.
- **Declared dependency.** `opt/utilz/utilz.yaml` moves from `dependencies: []` to declaring `yq` with `install: brew install yq`.
- **Version impact.** `utilz list` now fails loudly where it previously degraded. User-visible behaviour change -- minor bump (2.4.0), not a patch.

## Testing strategy

The suite was green throughout this change **without testing any of it** -- it exercises the old behaviours through unchanged public surfaces, and would stay green if `each_utility` regressed to accepting any symlink. Hand-verification is not coverage.

| Seam            | Test                                                                                            |
| --------------- | ----------------------------------------------------------------------------------------------- |
| `each_utility`  | A `bin/` symlink that does NOT resolve to `utilz` is invisible to every consumer, not just some |
| `require_yq`    | With `yq` off `PATH`, the install hint is printed **once**, not once per utility                |
| Generator floor | A generated utility's `utilz_version` major matches `VERSION`'s major                           |

The `require_yq` test is the highest-value one in the set: a regression test for a defect that actually occurred during this work, not a shape test.

Per the ST0008/WP-08 lesson, the BATS harness cwd sits outside the repo -- any fixture manipulating `bin/` or `PATH` must set up and tear down explicitly rather than assuming ambient state.

## Alternatives Considered

- **Keep the grep fallback for "graceful degradation".** Rejected: it degraded into an empty string that a caller reads as an absent key -- a silent wrong answer for any query outside the hardcoded four. A loud failure with an install hint is strictly better than a quiet wrong one.
- **Memoise `require_yq`.** Rejected: cannot work across command substitution. Call it once before the loop instead.
- **Have `run_doctor` call `require_yq`.** Rejected: would make `doctor` unable to diagnose the one dependency it most needs to diagnose.
- **Split into three steel threads.** Rejected: one working-tree change across shared files, which must land and be tested together. Split into three WPs instead, with defect 3 additionally cross-filed as issue 0002 because it shipped.
