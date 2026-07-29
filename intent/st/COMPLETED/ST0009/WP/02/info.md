---
verblock: "29 Jul 2026:v0.2: matts - Objective and deliverables"
wp_id: WP-02
title: "yq as hard dependency: require_yq, fallback removal"
scope: Small
status: Done
---

# WP-02: yq as hard dependency: require_yq, fallback removal

## Objective

Make `yq` the single YAML parser and an honestly-declared hard dependency. The grep fallback it replaces answered four hardcoded queries and returned an empty string for every other query -- a value the caller cannot distinguish from an absent key.

## Deliverables

- `require_yq()` in `opt/utilz/lib/common.sh` as the one place that reports a missing `yq`; grep fallback removed from `get_util_metadata`. (Code already written; see ST info.md Context.)
- Loop-callers gate ONCE before the loop -- `get_util_metadata` runs in command substitution and cannot memoise, so a per-call guard reprints the hint once per utility.
- `run_doctor` resolves `have_yq` up front and branches rather than gating, so `doctor` still completes and reports the missing `yq` -- it is the command you run to discover exactly that.
- `opt/utilz/utilz.yaml` declares `yq` under `dependencies:`, and doctor check 6 walks `utilz` itself so the declaration is actually read.
- BATS coverage AT-02.1 through AT-02.5 in `opt/utilz/test/common_lib.bats`. AT-02.2 (hint printed once, not N times) is a regression test for a defect hit during this work.

## Acceptance

Acceptance Criteria for this work package live in the steel thread's `acceptance.md`, under the `WP-02` heading (single source of truth). Do not restate ACs here.

## Dependencies

- Shares `opt/utilz/lib/common.sh` with WP-01 and WP-03; the three land together.
- Drives the ST-level release decision (AC-00.4): this is the user-visible behaviour change that makes the bump minor rather than patch.
