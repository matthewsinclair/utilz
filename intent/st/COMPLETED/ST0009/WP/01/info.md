---
verblock: "29 Jul 2026:v0.2: matts - Objective and deliverables"
wp_id: WP-01
title: "each_utility(): one bin/ walker, five consumers"
scope: Small
status: Done
---

# WP-01: each_utility(): one bin/ walker, five consumers

## Objective

Collapse five open-coded walks of `bin/*` onto a single `each_utility()` iterator, and pin the drift they had already developed with tests. Two of the five verified that the symlink resolved to `utilz`; three accepted any symlink, so a stray link in `bin/` was a utility to `doctor` and not to `list`.

## Deliverables

- `each_utility()` in `opt/utilz/lib/common.sh` -- emits one utility name per line, symlinks resolving to the dispatcher only, excluding `utilz`. (Code already written; see ST info.md Context.)
- All five call sites converted: `list_utilities`, `run_doctor` (utility check and dependency check), `run_tests`, `emit_integration_tsv`, `emacs_doctor`.
- Every consumer reads it via process substitution (`< <(each_utility)`), never a pipe, so accumulator arrays survive the loop.
- BATS coverage AT-01.1 through AT-01.4 in `opt/utilz/test/common_lib.bats`, including the cross-consumer drift assertion.

## Acceptance

Acceptance Criteria for this work package live in the steel thread's `acceptance.md`, under the `WP-01` heading (single source of truth). Do not restate ACs here.

## Dependencies

- None. Independent of WP-02 and WP-03 in behaviour, though it shares `opt/utilz/lib/common.sh` with both, so the three land together.
