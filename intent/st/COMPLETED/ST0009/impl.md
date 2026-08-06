# Implementation - ST0009: Framework core: single bin walker, single YAML parser, correct generator floor

## Implementation

Source changes were made by the `cc` node of the Cdsync project on 2026-07-29, inline and hv-instructed, before this steel thread existed (see info.md Context). This thread supplied the paperwork, the test coverage, the documentation reconciliation, and the release.

Landed in `opt/utilz/lib/common.sh` (+344/-173), `opt/utilz/utilz.yaml`, `opt/utilz/tmpl/metadata.tmpl`:

- `each_utility()` added; five open-coded `bin/*` walks converted to consume it. One `"$UTILZ_HOME"/bin/*` glob remains in the file, at line 222, inside the walker itself.
- `require_yq()` added; the grep fallback removed from `get_util_metadata`, which now returns 1 rather than an empty string when the YAML or `yq` is absent.
- `run_doctor` resolves `have_yq` once up front; checks 5 and 6 branch on it rather than gating.
- `{{UTILZ_FLOOR}}` placeholder in `metadata.tmpl`, substituted by `generate_utility` from the framework's own `VERSION`.

Tests added in `opt/utilz/test/common_lib.bats` (12 new, file total 41).

## Technical Details

**Verification of the inherited change.** Two claims in the incoming report were checked rather than accepted:

- _bash 3.2 safety_ -- flagged by its author as believed-but-unverified. Now verified under `/bin/bash 3.2.57` with `set -euo pipefail`: `each_utility`, `require_yq`, `get_util_metadata` on both version paths, full `doctor` and `list`, and the yq-absent path. Clean.
- _The `opt/todo/todo.yaml` "fossil"_ -- cited as evidence that the generator floor defect had forced a hand-fix. It had not. `todo.yaml` was born `^2.0.0` in `03ccded`, its first and only version, and all 13 utilities carry `^2.0.0`. The defect is purely latent. Withdrawn on the record in issue 0002, and it lowered the defect's severity from the headline to `low`.

**Blast radius of the new error contract.** `get_util_metadata` has no callers outside `common.sh`, verified by grep across `bin/`, `opt/`, `help/`, `docs/`. No utility inherits a new `set -e` abort path.

**shellcheck.** Net improvement: 24 SC2155 at HEAD down to 8, SC2001 eliminated. Net -17 findings.

## Challenges & Solutions

**Proving red-first after the fact.** The code preceded the tests, so genuine red-first was impossible. Instead the full new set was run against `HEAD`'s `common.sh` / `metadata.tmpl` / `utilz.yaml` in a scratch copy of the repo: **11 of 12 fail**. AT-02.5 passes at HEAD because it guards behaviour the refactor had to preserve rather than behaviour it introduced. `acceptance.md` states the verification was retrospective rather than presenting it as red-first.

**Testing the walker without mutating the real `bin/`.** The obvious fixture -- adding a stray symlink to `$UTILZ_HOME/bin` -- pollutes the repo and leaves debris if a test fails mid-body, since a BATS assertion failure aborts before inline cleanup. Solved with `make_fake_home()`, which builds a self-contained `UTILZ_HOME` in the BATS temp dir carrying all three cases (dispatcher symlink, stray symlink, plain file). Zero repo mutation, no teardown hazard, and it avoids overriding the shared `teardown()` in `test_helper.bash`.

**Testing the yq-absent path portably.** The natural approach -- filter yq's directory out of `PATH` -- breaks on CI: `.github/workflows/tests.yml` installs yq to `/usr/bin` on Linux, so filtering that directory removes the core tools too. Solved with `yqless_path()`, which builds a sandbox directory of symlinks to the specific tools `common.sh` needs, deliberately excluding yq. Works identically on macOS (`/opt/homebrew/bin/yq`) and Linux CI.

**Making the generator test prove derivation rather than coincidence.** Asserting `^2.0.0` against the real `VERSION` would pass even if the floor were still hardcoded to a value that happened to match. `make_fake_home` takes the version as a parameter, so the test fabricates a `VERSION` of 7.3.1 and asserts `^7.0.0`.
