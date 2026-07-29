---
verblock: "29 Jul 2026:v0.2: matts - Acceptance contract for the framework-core triple"
st_id: ST0009
title: "Framework core: single bin walker, single YAML parser, correct generator floor -- acceptance contract"
---

# ST0009 Framework core: single bin walker, single YAML parser, correct generator floor -- Acceptance

> Canonical acceptance contract for ST0009. Acceptance Criteria (AC) are the ratified completeness boundary; Acceptance Tests (AT) are the small red-to-green tests that prove them. Real test code lives in the suite (paths cited below); this file is the contract plus the AC-to-AT coverage map plus live status. info.md / WP info.md reference this file and never restate ACs (one home).
>
> Done = every AC is covered by a GREEN AT, or (for a non-test AC) its named evidence is satisfied, AND the AC set is the ratified full boundary. Done is read from this map, never from a hand-ticked box.
>
> Change control: clarifying an AC or AT is verifier-and-builder; shrinking scope, or weakening an AT to make it pass, needs the owner.
>
> AT status vocabulary: to-write (red-first) | red | green | n/a (non-test: doc / eyeball / gate).
>
> Non-test ACs carry their state inline -- `-- evidence: <ref> -- satisfied: yes|no` on the AC line; test-backed ACs are satisfied by a green covering AT (computed, never written). Multi-AC coverage on an AT is comma-separated.

## Acceptance Criteria

### ST-level

- AC-00.1 The full BATS suite is green and `utilz doctor` reports no framework issue on a machine with `yq` installed.
- AC-00.2 (non-test) The change is bash 3.2 safe -- `each_utility`, `require_yq`, `get_util_metadata` (both version paths), `doctor`, `list`, and the yq-absent path all behave correctly under `/bin/bash 3.2.57` with `set -euo pipefail`. -- evidence: design.md Architecture, hand-run 2026-07-29 -- satisfied: yes
- AC-00.3 (non-test) `docs/architecture.md`, `help/utilz.md`, and `README.md` describe the as-built: one YAML parser, one `bin/` walker, `yq` required. No prose survives describing `get_util_metadata` as a utility-facing API, `yq` as mdagg-specific, or `^1.0.0` as the generated floor. -- evidence: doc diff in the landing commit -- satisfied: yes
- AC-00.4 (non-test) `VERSION` and `CHANGELOG.md` record 2.4.0, on the grounds that `yq` moving from optional to required is user-visible behaviour change. -- evidence: `VERSION` = 2.4.0, CHANGELOG `## [2.4.0]` -- satisfied: yes

### WP-01 -- each_utility(): one bin/ walker, five consumers (status: Done)

- AC-01.1 `each_utility` emits exactly the utilities installed as `bin/` symlinks resolving to the dispatcher, one name per line, excluding `utilz` itself.
- AC-01.2 A symlink in `bin/` that does NOT resolve to the dispatcher is invisible to every consumer -- this is the drift being closed, so the assertion must cover more than one consumer.
- AC-01.3 A non-symlink regular file in `bin/` is not treated as a utility.
- AC-01.4 (non-test) All five former walk sites (`list_utilities`, `run_doctor` x2, `run_tests`, `emit_integration_tsv`, `emacs_doctor`) read `each_utility` and no longer open-code a `bin/*` glob. -- evidence: `grep -c 'UTILZ_HOME"/bin/\*' opt/utilz/lib/common.sh` returns 1, at line 222, inside `each_utility` itself -- satisfied: yes
- AC-01.5 Consumers that accumulate into arrays (`run_doctor`, `run_tests`) still see their accumulated values after the loop -- ie the process-substitution contract holds, not a pipe.

### WP-02 -- yq as hard dependency: require_yq, fallback removal (status: Done)

- AC-02.1 With `yq` absent from `PATH`, `utilz list` fails loudly, names `yq`, gives the install hint, and exits non-zero.
- AC-02.2 With `yq` absent, the install hint appears exactly ONCE, not once per utility. (Regression test for the subshell-memo defect hit during this work.)
- AC-02.3 With `yq` absent, `utilz doctor` still completes and reports `yq` as a missing required dependency rather than bailing -- doctor is the command you run to discover this.
- AC-02.4 `get_util_metadata` returns non-zero (rather than an empty string) when the YAML file is absent or `yq` is missing.
- AC-02.5 `get_util_metadata` resolves both version forms: an inline `version:` and a `version_file:` reference (as `utilz` itself uses, pointing at the repo-root `VERSION`).
- AC-02.6 (non-test) `opt/utilz/utilz.yaml` declares `yq` under `dependencies:` with an install hint, and doctor check 6 walks `utilz` itself so that declaration is actually read. -- evidence: check 6 with yq off PATH emits "yq is not installed", then "Missing dependencies: yq" / "yq (required by utilz)" / "Install: brew install yq" -- satisfied: yes

### WP-03 -- Generator utilz_version floor derived from VERSION (status: Done)

- AC-03.1 A utility created by `utilz generate` is stamped with a `utilz_version` whose major matches the major in `VERSION` -- no hardcoded floor.
- AC-03.2 A freshly generated utility passes `utilz doctor`'s version-compatibility check with no hand-editing.
- AC-03.3 `opt/utilz/tmpl/metadata.tmpl` contains no literal version floor; the floor arrives via the `{{UTILZ_FLOOR}}` placeholder.

## Acceptance Tests

All AT code lives in `opt/utilz/test/common_lib.bats`. There is no `utilz.bats` -- `generate_utility` is a `common.sh` function, so its tests belong with the rest of that file's coverage (one test file per source file).

Red-first was verified retrospectively rather than by writing the tests first, because the code preceded this thread (see info.md Context). The whole new set was run against `HEAD`'s `common.sh` / `metadata.tmpl` / `utilz.yaml` in a scratch copy of the repo: **11 of the 12 fail against the pre-change code.** The exception is noted below.

### WP-01

- AT-01.1 `each_utility() lists installed utilities one per line` -- covers AC-01.1 -- status: green (red at HEAD: `each_utility: command not found`)
- AT-01.2 `each_utility() ignores a bin/ symlink that does not resolve to utilz` -- covers AC-01.2 -- status: green (red at HEAD)
- AT-01.3 `each_utility() ignores a plain file in bin/` -- covers AC-01.3 -- status: green (red at HEAD)
- AT-01.4 `a stray bin/ symlink is invisible to both list_utilities and run_doctor` -- covers AC-01.2, AC-01.5 -- status: green (red at HEAD: doctor reported `Found 3 utilities, but 1 have issues: - zzstray (no implementation)` while list showed 2 -- the drift itself)
- Coverage: AC-01.4 is non-test (evidence on the AC line). All other WP-01 ACs covered.

### WP-02

- AT-02.1 `list_utilities() without yq fails loudly with an install hint` -- covers AC-02.1 -- status: green (red at HEAD)
- AT-02.2 `the yq install hint is printed once, not once per utility` -- covers AC-02.2 -- status: green (red at HEAD)
- AT-02.3 `run_doctor() completes without yq and names it as missing` -- covers AC-02.3 -- status: green (red at HEAD)
- AT-02.4 `get_util_metadata() returns non-zero for a missing yaml file` -- covers AC-02.4 -- status: green (red at HEAD -- the old code returned 0 with empty output)
- AT-02.5 `get_util_metadata() resolves both an inline version and a version_file` -- covers AC-02.5 -- status: green (**passes at HEAD too** -- this is a regression guard for behaviour the refactor had to preserve, not new behaviour; it is the 1 of 12 that was not red)
- Coverage: AC-02.6 is non-test (evidence on the AC line). All other WP-02 ACs covered.

### WP-03

- AT-03.1 `metadata.tmpl carries a placeholder, not a literal version floor` -- covers AC-03.3 -- status: green (red at HEAD)
- AT-03.2 `generate stamps a utilz_version floor matching VERSION's major` -- covers AC-03.1 -- status: green (red at HEAD). Asserts against a fake home reporting `VERSION` 7.3.1 and expects `^7.0.0`, so it proves derivation; asserting `^2.0.0` against the real VERSION would pass even with the floor still hardcoded.
- AT-03.3 `a generated utility passes doctor's version compatibility check` -- covers AC-03.2 -- status: green (red at HEAD)
- Coverage: all WP-03 ACs covered.

### ST-level

- AT-00.1 Full suite via `utilz test` -- covers AC-00.1 -- status: green (14/14 suites, 41 tests in `common_lib.bats`, 2026-07-29)
- Coverage: AC-00.2, AC-00.3, AC-00.4 are non-test (evidence on the AC lines).
