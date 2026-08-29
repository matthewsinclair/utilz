---
id: "0006"
title: Adding any 14th utility reddens the suite whichever way it declares integration
date: 2026-08-29
reporter: matts
status: OPEN
severity: medium
---

# 0006: Adding any 14th utility reddens the suite whichever way it declares integration

## Tags

emacs-bridge, testing, latent, growth

## Summary

Two framework checks disagree about what a new utility owes the Emacs bridge, and **no value of the new utility's yaml satisfies both**:

- `opt/utilz/test/bridge.bats:35` asserts `emit_integration_tsv` emits **exactly 13** rows.
- `utilz emacs doctor` counts any utility **without** an `integration:` block as an issue and returns 1; `bridge.bats:137,145` assert it exits 0.

Declare a block and the row count becomes 14, failing the first. Omit it and `emacs doctor` returns 1, failing the other two. The defect is latent and has never fired, because `prez` is the first utility added since both checks were written.

Found by running the full suite after ST0010's hoist, not by reading either file.

## Reproduction

With `prez` installed (14 utilities, core included):

```
$ utilz test utilz
not ok 2 emit_integration_tsv emits one row per utility with an integration block
# FAILURE: Expected 13 rows, got 14                      # prez.yaml HAS a block

$ # remove the integration: block from opt/prez/prez.yaml, then:
$ utilz test utilz
not ok 15 utilz emacs doctor - runs and passes on clean checkout
not ok 16 utilz emacs doctor - reports canonical elisp as present
# ⚠ 1 utility/utilities without an integration: block:
#     - prez (opt/prez/prez.yaml)
```

`input: none` / `output: discard` do not help: both are valid values, so the row is still emitted and the count is still 14.

## Root Cause

Two independent copies of "the current roster is the final roster".

`bridge.bats:31-35` restates the roster as a constant, and its own comment says so: _"13 utilities currently declare integration blocks: the ST0007 design matrix of 12, plus todo (ST0008)."_ A count is the cheapest possible assertion and it is pinned to a moment rather than to a property.

`common.sh:908-914` (`run_emacs_doctor`, check 2) treats a missing `integration:` block as an issue and increments the failure counter. That is defensible as a prompt -- a utility with no block cannot be bound by the bridge -- but it conflates NOT YET BOUND with BROKEN, which is the opposite of the convention two functions away: `run_doctor` prints optional dependencies with `info` and does not fail on them.

## Impact

Medium. It does not affect any utility's behaviour, but it fires on **normal growth**: every future utility hits it, and the first symptom is two or three unrelated-looking framework tests going red in a thread that never touched them. That is expensive to diagnose from the failure text, which names the Emacs bridge rather than the addition.

It also currently blocks ST0010 from reading green, and ST0010's design explicitly rules out an integration block for prez v1 ("Non-decisions, named": _the Emacs bridge can bind later; nothing in this thread depends on it_), so the design-compliant tree is the red one.

## Proposed Fix

Two changes, neither of which needs the other, both small:

1. **`bridge.bats:35` should assert the property, not the count.** Compare the row count to the number of yaml files that actually declare a block, so the test measures "every declaring utility appears exactly once" -- which is what the test's title already claims. Named utilities keep their own assertions (`cleanz` at :38, `utilz` core excluded at :44), so coverage does not weaken.

2. **`run_emacs_doctor` should report an unbound utility without failing.** Keep the list -- it is the useful half -- but print it with `info`, do not increment `issues`, and reserve the failure for INVALID values, which are a real defect rather than an absence. That matches `run_doctor`'s posture on optional dependencies and keeps `emacs doctor` green on a correct checkout.

Whether (2) is right is a judgement about what the bridge intends, so it wants hv's or vc's ruling rather than a unilateral edit.

## Related

- ST0010 -- the thread that surfaced it; its design's "Non-decisions, named" section is the reason prez declares no block
- 0002 -- the other latent defect that only fires on a new utility (generator's `utilz_version` floor)
