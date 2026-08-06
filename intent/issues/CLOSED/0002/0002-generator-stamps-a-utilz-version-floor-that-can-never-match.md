---
id: "0002"
title: utilz generate stamps a utilz_version floor of ^1.0.0 that no 2.x framework can satisfy
date: 2026-07-29
reporter: cdsync-cc (Cdsync project, via hv)
status: CLOSED
severity: low
resolved: 2026-07-29
---

# 0002: utilz generate stamps a utilz_version floor of ^1.0.0 that no 2.x framework can satisfy

## Tags

utilz, generate, template, version-compatibility, doctor, latent

## Summary

`opt/utilz/tmpl/metadata.tmpl` hardcodes `utilz_version: "^1.0.0"`. The framework `VERSION` has read `2.x` since v2.0.0. `run_doctor` compares only major versions, so **every utility produced by `utilz generate` is born incompatible with the framework that generated it**, and `utilz doctor` flags it until someone hand-edits the generated yaml.

Latent, not observed: no utility in this repo was ever shipped in the broken state. See Impact.

## Reproduction

    $ cat VERSION
    2.3.0
    $ grep utilz_version opt/utilz/tmpl/metadata.tmpl
    utilz_version: "^1.0.0"

    $ utilz generate zztest "throwaway" "matts"
    $ grep utilz_version opt/zztest/zztest.yaml
    utilz_version: "^1.0.0"

    $ utilz doctor
    ...
    [5/6] Checking installed utilities...
    ⚠ zztest (requires Utilz ^1.0.0, have 2.3.0)

## Root Cause

`opt/utilz/tmpl/metadata.tmpl` line 3 carries a literal floor rather than a placeholder. `generate_utility` in `opt/utilz/lib/common.sh` substitutes `{{NAME}}`, `{{DESCRIPTION}}`, and `{{AUTHOR}}` into the template but had no notion of a version floor, so the literal passed through untouched.

The compatibility check it fails is in `run_doctor` check 5:

    required_major=$(echo "$required_utilz_version" | sed 's/^\^//' | sed 's/[^0-9].*//')
    framework_major=$(echo "$framework_version" | cut -d. -f1)
    if [[ "$required_major" != "$framework_major" ]]; then
      incompatible_utils+=(...)
    fi

`1 != 2`, so every generated utility is reported incompatible.

## Impact

**Low, and lower than it first appears.** The defect is real but has never bitten this repo:

- All 13 utilities in `opt/` carry `utilz_version: "^2.0.0"`. There is no odd one out.
- `opt/todo/todo.yaml` -- the most recently generated utility, added by ST0008 in July 2026, while this defect was live -- was **born** `^2.0.0` in commit `03ccded`, its first and only version. It was never `^1.0.0` and was never hand-corrected.

The initial report cited `todo.yaml` as the fossil of a hand-fix; the git history does not support that, and the claim is withdrawn here. Either these utilities were not created via `utilz generate`, or the floor was corrected before the first commit each time.

So the cost to date is zero. The cost going forward is that the next person to run `utilz generate` gets a utility that fails `doctor` out of the box, with no indication that the template rather than their work is at fault -- a bad first-run experience for the framework's own scaffolding command.

## Proposed Fix

Derive the floor from the framework's own `VERSION` instead of hardcoding it. Add a `{{UTILZ_FLOOR}}` placeholder to `metadata.tmpl`:

    -utilz_version: "^1.0.0"
    +utilz_version: "{{UTILZ_FLOOR}}"

and compute it in `generate_utility` alongside the existing substitutions:

    local utilz_floor="^$(get_utilz_version | cut -d. -f1).0.0"

    sed -e "s/{{NAME}}/$util_name/g" \
        -e "s/{{DESCRIPTION}}/$util_desc/g" \
        -e "s/{{AUTHOR}}/$author/g" \
        -e "s/{{UTILZ_FLOOR}}/$utilz_floor/g" \
        "$tmpl_dir/metadata.tmpl" > "$util_dir/$util_name.yaml"

A hardcoded floor is a constant that has to be hand-maintained in lockstep with `VERSION`; deriving it means the next major bump needs no template edit and cannot drift again.

## Related

- ST0009 / WP-03 -- the work package that lands this fix, together with two Highlander collapses that share the same file.
- Issue 0001 -- precedent for tracking a shipped defect as an issue alongside (not instead of) the steel thread that fixes it.
- Found by the `cc` node of the Cdsync project while reading Utilz as a reference implementation, and fixed inline at hv's instruction before this issue was filed. The paperwork follows the code here; see ST0009 info.md Context for the full provenance.

## Resolutions

**2026-07-29 -- Fixed under ST0009/WP-03, shipped in v2.4.0 (cc node).**

Applied exactly as proposed above: `{{UTILZ_FLOOR}}` placeholder in
`opt/utilz/tmpl/metadata.tmpl`, with `generate_utility` deriving the value from
the framework's own `VERSION`:

    -utilz_version: "^1.0.0"
    +utilz_version: "{{UTILZ_FLOOR}}"

    +  local utilz_floor="^$(get_utilz_version | cut -d. -f1).0.0"

Regression coverage in `opt/utilz/test/common_lib.bats`:

- `metadata.tmpl carries a placeholder, not a literal version floor` -- asserts
  the template line is exactly `utilz_version: "{{UTILZ_FLOOR}}"`.
- `generate stamps a utilz_version floor matching VERSION's major` -- generates
  into a fabricated `UTILZ_HOME` whose `VERSION` reads **7.3.1** and asserts the
  stamped floor is `^7.0.0`. Deliberately not asserted against the real 2.x: a
  test expecting `^2.0.0` would pass even with the floor still hardcoded to a
  value that happened to match, and so would prove nothing.
- `a generated utility passes doctor's version compatibility check` -- the
  end-to-end bar from the Reproduction section, at framework 7.3.1.

All three fail against the pre-fix code. Full suite green (14 suites).

**Evidence correction (same session).** The Impact section above was revised
before closing: the original report cited `opt/todo/todo.yaml` as a fossil of a
hand-fix caused by this defect. `git log` does not support that -- `todo.yaml`
was born `^2.0.0` in `03ccded`, its first and only version, and all 13 utilities
carry `^2.0.0`. The defect is real but never bit this repo. Severity was set to
`low` on that basis rather than on the severity the fossil narrative implied.
