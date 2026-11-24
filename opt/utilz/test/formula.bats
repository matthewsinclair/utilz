#!/usr/bin/env bats
# formula.bats - Utilz's Homebrew formula template renders through devbin's
# formula built-in (devbin#0326, issue I59c806c; dev, opt, brew contract T8)
#
# tools/formula, Utilz's own render and publish, is retired: the release
# core's formula step runs `bin/devbin formula publish --pull` under
# release.formula, and devbin's own arms prove the render and the publish. What
# is Utilz's to hold is that its template is one devbin renders: exactly one
# @@INSTALL@@, the one tag and the one revision placeholder, no install step
# of its own and no bash build line, which render writes. `bin/devbin formula
# check` makes every check render makes that needs no tag, so it holds that
# at every run of this suite, in both CI test jobs (tools/ci-suites runs
# `utilz test utilz`).
#
# devbin needs bash 5, where Utilz's estate gate runs its suites under macOS's
# /bin/bash 3.2, so the check runs under run_devbin's bash at devbin's floor
# (test_helper.bash). Where the machine has none, run_devbin fails the arm by
# name: it never skips.

load "test_helper.bash"

# AT04 (ST0019 AC-05.3, withdrawn for I59c806c): the template renders through
# devbin's formula check, with no placeholder left.
@test "AT04 (ST0019 AC-05.3, withdrawn for I59c806c): the formula template renders through devbin's formula check with no placeholder left" {
  run run_devbin "$UTILZ_HOME" formula check
  assert_success
  assert_output_contains "formula: packaging/homebrew/utilz.rb renders: every check that needs no tag passed"
}
