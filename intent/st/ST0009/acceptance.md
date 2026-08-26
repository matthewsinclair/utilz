---
st_id: ST0009
title: Framework core: single bin walker, single YAML parser, correct generator floor
---

# ST0009: Framework core: single bin walker, single YAML parser, correct generator floor -- Acceptance

> **THIS FILE IS A GENERATED VIEW, AND A ROW AUTHORED HERE IS DISCARDED BY THE NEXT SYNC.** The acceptance contract is canon in the thread model; this file renders it. Acceptance Criteria (AC) are the ratified completeness boundary; Acceptance Tests (AT) are the small red-to-green tests that prove them.
>
> Done = every AC is covered by a GREEN AT, or (for a non-test AC) its named evidence is satisfied, AND the AC set is the ratified full boundary. Done is read from this map, never from a hand-ticked box.
>
> Test-backed satisfaction is COMPUTED from covering green ATs and never stored -- storing it would be double truth. An AC has four states, not two: beyond satisfied and unsatisfied, a requirement can be **descoped** to a named thread or **withdrawn** with its reason on the record. Both are non-blocking and both are reported separately, so a thread that descoped half its contract looks like one.

## Acceptance Criteria

### ST-level

- AC-00.1 The full BATS suite is green and `utilz doctor` reports no framework issue on a machine with `yq` installed. -- satisfied: no (computed)
- AC-00.2 (non-test) The change is bash 3.2 safe -- `each_utility`, `require_yq`, `get_util_metadata` (both version paths), `doctor`, `list`, and the yq-absent path all behave correctly under `/bin/bash 3.2.57` with `set -euo pipefail`. -- evidence: design.md Architecture, hand-run 2026-07-29 -- satisfied: yes
- AC-00.3 (non-test) `docs/architecture.md`, `help/utilz.md`, and `README.md` describe the as-built: one YAML parser, one `bin/` walker, `yq` required. No prose survives describing `get_util_metadata` as a utility-facing API, `yq` as mdagg-specific, or `^1.0.0` as the generated floor. -- evidence: doc diff in the landing commit -- satisfied: yes
- AC-00.4 (non-test) `VERSION` and `CHANGELOG.md` record 2.4.0, on the grounds that `yq` moving from optional to required is user-visible behaviour change. -- evidence: `VERSION` = 2.4.0, CHANGELOG `## [2.4.0]` -- satisfied: yes

### WP-01 -- each_utility(): one bin/ walker, five consumers (status: Done)

- AC-01.1 `each_utility` emits exactly the utilities installed as `bin/` symlinks resolving to the dispatcher, one name per line, excluding `utilz` itself. -- satisfied: no (computed)
- AC-01.2 A symlink in `bin/` that does NOT resolve to the dispatcher is invisible to every consumer -- this is the drift being closed, so the assertion must cover more than one consumer. -- satisfied: no (computed)
- AC-01.3 A non-symlink regular file in `bin/` is not treated as a utility. -- satisfied: no (computed)
- AC-01.4 (non-test) All five former walk sites (`list_utilities`, `run_doctor` x2, `run_tests`, `emit_integration_tsv`, `emacs_doctor`) read `each_utility` and no longer open-code a `bin/*` glob. -- evidence: `grep -c 'UTILZ_HOME"/bin/\*' opt/utilz/lib/common.sh` returns 1, at line 222, inside `each_utility` itself -- satisfied: yes
- AC-01.5 Consumers that accumulate into arrays (`run_doctor`, `run_tests`) still see their accumulated values after the loop -- ie the process-substitution contract holds, not a pipe. -- satisfied: no (computed)

### WP-02 -- yq as hard dependency: require_yq, fallback removal (status: Done)

- AC-02.1 With `yq` absent from `PATH`, `utilz list` fails loudly, names `yq`, gives the install hint, and exits non-zero. -- satisfied: no (computed)
- AC-02.2 With `yq` absent, the install hint appears exactly ONCE, not once per utility. (Regression test for the subshell-memo defect hit during this work.) -- satisfied: no (computed)
- AC-02.3 With `yq` absent, `utilz doctor` still completes and reports `yq` as a missing required dependency rather than bailing -- doctor is the command you run to discover this. -- satisfied: no (computed)
- AC-02.4 `get_util_metadata` returns non-zero (rather than an empty string) when the YAML file is absent or `yq` is missing. -- satisfied: no (computed)
- AC-02.5 `get_util_metadata` resolves both version forms: an inline `version:` and a `version_file:` reference (as `utilz` itself uses, pointing at the repo-root `VERSION`). -- satisfied: no (computed)
- AC-02.6 (non-test) `opt/utilz/utilz.yaml` declares `yq` under `dependencies:` with an install hint, and doctor check 6 walks `utilz` itself so that declaration is actually read. -- evidence: check 6 with yq off PATH emits "yq is not installed", then "Missing dependencies: yq" / "yq (required by utilz)" / "Install: brew install yq" -- satisfied: yes

### WP-03 -- Generator utilz_version floor derived from VERSION (status: Done)

- AC-03.1 A utility created by `utilz generate` is stamped with a `utilz_version` whose major matches the major in `VERSION` -- no hardcoded floor. -- satisfied: no (computed)
- AC-03.2 A freshly generated utility passes `utilz doctor`'s version-compatibility check with no hand-editing. -- satisfied: no (computed)
- AC-03.3 `opt/utilz/tmpl/metadata.tmpl` contains no literal version floor; the floor arrives via the `{{UTILZ_FLOOR}}` placeholder. -- satisfied: no (computed)

## Acceptance Tests

### ST-level

_(no tests in this group)_

### WP-01 -- each_utility(): one bin/ walker, five consumers (status: Done)

_(no tests in this group)_

### WP-02 -- yq as hard dependency: require_yq, fallback removal (status: Done)

_(no tests in this group)_

### WP-03 -- Generator utilz_version floor derived from VERSION (status: Done)

_(no tests in this group)_

---

_Generated by Intent v3.0.0 from `thread.json`. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
