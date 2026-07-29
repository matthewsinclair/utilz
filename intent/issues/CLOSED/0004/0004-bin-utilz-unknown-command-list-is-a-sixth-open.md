---
id: "0004"
title: bin/utilz unknown-command list is a sixth open-coded bin/ walk ST0009 missed
date: 2026-07-29
reporter: matts
status: CLOSED
severity: low
---

# 0004: bin/utilz unknown-command list is a sixth open-coded bin/ walk ST0009 missed

## Tags

highlander, dispatcher, st0009-completeness

## Summary

ST0009/WP-01 replaced five open-coded walks of `bin/*` with a single `each_utility()` iterator in `opt/utilz/lib/common.sh`. There was a sixth, in `bin/utilz` itself, and it was missed: the "Installed utilities:" list printed on the unknown-command path. It carries exactly the drift ST0009 was raised to eliminate -- it accepts any symlink in `bin/`, with no check that the link resolves to `utilz`.

## Reproduction

```
$ ln -s /bin/ls "$UTILZ_HOME/bin/notautility"
$ utilz list          # correctly omits notautility (uses each_utility)
$ utilz bogus         # WRONG: suggests "utilz notautility [args]"
```

Column alignment is wrong in the same block: the separator is a hardcoded run of spaces, so line length tracks the utility name and the `-` descriptions do not line up (`utilz expz [args]      - ...` against `utilz pdf2md [args]      - ...`).

## Root Cause

`bin/utilz:200-205` iterates `"$UTILZ_HOME"/bin/*` and filters on `[[ "$name" != "utilz" && -L "$symlink" ]]` -- membership by "is a symlink", not by "is a Utilz utility". `each_utility()` (`common.sh:262`) additionally requires `readlink` to yield `utilz` or `./utilz`. The two therefore disagree about what a utility is, which is the precise divergence recorded in the `each_utility` header comment. It was missed because the ST0009 sweep grepped `common.sh` for the walk pattern; the dispatcher has its own copy.

## Impact

Cosmetic and low. It only affects the suggestion list on an already-failing command, and only when a stray non-Utilz symlink is present in `bin/` -- which `utilz doctor` reports separately. No behaviour depends on the list. It matters as unfinished Highlander work, not as a user-visible fault: the next person to add a filter to `each_utility` will fix five call sites and leave this one wrong again.

## Proposed Fix

Consume `each_utility()` via process substitution (never a pipe -- see the header comment), and emit with `printf` using a computed column width so the descriptions align. Pin with a test that plants a stray symlink and asserts it is absent from the unknown-command output.

## Related

- ST0009 -- WP-01, the walker consolidation this completes
- 0003 -- first dispatcher defect found in the same read

## Resolutions

Fixed 2026-07-29. `bin/utilz:200-205` now consumes `each_utility()` via process substitution, so there are six call sites and one walker -- ST0009/WP-01 is complete. Emission switched to `printf '  %-*s - Run %s utility\n'` with the width computed from the longest label, so the column aligns whatever the names are. `%-*s` star-width verified under bash 3.2.57. The accumulator array is guarded with `${#UTIL_NAMES[@]} -gt 0` before expansion, per the project's `set -u` rule.

Three tests in `opt/utilz/test/dispatcher.bats` (stray-symlink rejection, a real utility still listed, column alignment); the first and third were red before the fix. Verified by hand too: with `/bin/echo` symlinked in as `bin/zzstray`, the suggestion list omits it and the descriptions line up.

Worth recording for the next sweep: this copy survived ST0009 because that sweep grepped `common.sh` for the walk pattern and never looked in `bin/utilz`. `grep -rn 'UTILZ_HOME"/bin/\*'` across both files is the check that would have caught it, and now returns only `each_utility` itself plus this consumer.
