---
id: "0005"
title: utilz doctor PATH check false-negatives a symlink-on-PATH install
date: 2026-07-29
reporter: matts
status: CLOSED
severity: low
---

# 0005: utilz doctor PATH check false-negatives a symlink-on-PATH install

## Tags

doctor, false-positive, portability

## Summary

`utilz doctor` check 4 passes only when the literal string `$UTILZ_HOME/bin` appears in `$PATH`. A `utilz` symlink on `PATH` that points back at the dispatcher is an equally working install, and doctor reports it as a problem -- then prints shell-config advice the user does not need. On this machine that is doctor's only complaint, so a fully working setup reports `Found 1 issue(s)`.

The same line has a second, quieter fault: the test is a `grep` on unanchored, unescaped `$UTILZ_HOME`, so it is a regex substring match rather than a PATH-element match.

## Reproduction

```
$ ln -s "$UTILZ_HOME/bin/utilz" ~/.local/bin/utilz   # ~/.local/bin is on PATH
$ command -v utilz                                    # /Users/matts/.local/bin/utilz -- works
$ utilz doctor
  [4/6] Checking PATH configuration...
  ⚠ $UTILZ_HOME/bin is not in $PATH
  ...
  ⚠ Found 1 issue(s)
```

Substring fault, independently:

```
$ PATH="/opt/Utilz/binaries:$PATH" UTILZ_HOME=/opt/Utilz utilz doctor   # check 4 wrongly passes
```

## Root Cause

`opt/utilz/lib/common.sh:353` -- `if echo "$PATH" | grep -q "$UTILZ_HOME/bin"`. Two problems in one expression. It only ever asks about `$UTILZ_HOME/bin` as a PATH entry, so it cannot recognise reachability via a symlink; and it asks with `grep`, so `$UTILZ_HOME` is interpreted as a regex (a `.` or `+` in the path is a metacharacter) and matches any substring, so `/opt/Utilz/binaries` satisfies a test for `/opt/Utilz/bin`.

## Impact

Low but corrosive: doctor is the trust surface. A warning on a working install teaches the user that doctor's output is noise, which devalues the six real checks around it. The substring half can also mask a genuinely broken PATH, which is the more dangerous direction.

## Proposed Fix

Replace the `grep` with an exact PATH-element match (`case ":$PATH:" in *":$bin_dir:"*)`) -- no regex, no substring. Then, when that fails, scan PATH for a `utilz` that is the same file as `$UTILZ_HOME/bin/utilz` using `[[ a -ef b ]]`, which compares device and inode through symlinks and so needs no path resolver of its own (the only existing resolver, `determine_utilz_home` in `bin/utilz`, cannot be reused -- it runs before `common.sh` is sourced, because it is what finds `common.sh`). Report which of the two routes was found so the output stays diagnostic. Warn only when neither holds.

## Related

- 0003, 0004 -- the other two defects from the same read

## Resolutions

Fixed 2026-07-29 in `opt/utilz/lib/common.sh` check 4, both faults:

- Exact PATH-element match via `case ":$PATH:" in *":$bin_dir:"*)`. No regex, so no metacharacter hazard and no substring pass.
- Fallback scan of PATH for a `utilz` that is `-ef` the dispatcher. `-ef` compares device and inode through symlinks, so no path resolver was added -- the codebase's only resolver, `determine_utilz_home` in `bin/utilz`, cannot be reused because it runs before `common.sh` is sourced (it is what finds `common.sh`). Empty PATH elements are skipped rather than treated as cwd.

Output stays diagnostic: `$UTILZ_HOME/bin is in $PATH` for the direct route, `utilz is on $PATH via <path>` for the symlink route, and the warning only when neither holds. The warning now also offers the symlink install as a second remedy, since it is a supported setup.

Verified on the reporting machine: `utilz doctor` went from `⚠ Found 1 issue(s)` to `✓ All checks passed!` with no change to the environment. Four tests in `opt/utilz/test/common_lib.bats` covering all three branches plus the substring case; the symlink and substring tests were red before the fix, the other two green (they describe behaviour that was already right). Needed a new fixture, `run_in_fake_home_with_path`, since the existing `run_in_fake_home` cannot vary PATH.
