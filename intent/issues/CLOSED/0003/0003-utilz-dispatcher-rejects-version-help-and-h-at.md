---
id: "0003"
title: utilz dispatcher rejects --version, --help and -h at its own top level
date: 2026-07-29
reporter: matts
status: CLOSED
severity: medium
---

# 0003: utilz dispatcher rejects --version, --help and -h at its own top level

## Tags

dispatcher, cli-surface, consistency

## Summary

`utilz --version`, `utilz --help` and `utilz -h` all fail with `Unknown command`, exit 1, and dump the usage block. Only the bare subcommand forms `utilz version` and `utilz help` work. Every one of the 13 utilities accepts the flag forms, and the dispatcher's own `integration` and `emacs` subcommands accept `--help|-h` for their verbs, so the framework's front door is the single place in Utilz where the conventional flags do not work.

## Reproduction

```
$ utilz --version ; echo "rc=$?"
✗ Unknown command: --version
...usage...
rc=1

$ utilz --help ; echo "rc=$?"     # same
$ utilz -h ; echo "rc=$?"         # same
$ utilz version ; echo "rc=$?"    # utilz v2.4.0, rc=0
```

## Root Cause

`bin/utilz:76-105` dispatches on `COMMAND="${1:-help}"` through a `case` whose arms are bare words only -- `help)` and `version)`. Anything else falls to the `*)` arm, which treats the token as a utility name, fails the `-L`/`-x` test, and reports it as an unknown command. No flag aliases were ever added at this level, while `bin/utilz:120` and `bin/utilz:151` do carry `""|help|--help|-h)` for the nested verbs.

## Impact

User-facing and immediate: `--version` is the near-universal convention and the form every sub-utility honours, so it is what a first-time user (or a script probing the tool) types first. They get an error and a non-zero exit for a command that exists. No documentation ever promised the flag forms, so nothing was lying -- this is an inconsistency in the surface rather than a broken contract, which is why it is medium and not high.

## Proposed Fix

Alias the flags onto the existing arms in `bin/utilz`: `-h|--help)` onto `help)` and `--version)` onto `version)`. Keep `-h` out of the `version` arm (`-v` is left unbound -- it is ambiguous with a verbose flag and no utility binds it). Pin with tests asserting exit 0 and the expected first line for all five spellings.

## Related

- ST0009 -- the dispatcher/library refactor that this surface survived unchanged
- 0004 -- second dispatcher defect found in the same read

## Resolutions

Fixed 2026-07-29. `bin/utilz` `case` arms widened to `help|-h|--help)` and `version|--version)`. Aliases onto the existing arms, so there is no second code path and `utilz --help mdagg` keeps working off `$2` exactly as `utilz help mdagg` does.

`-v` left unbound as designed, and pinned by a test asserting it still fails -- so a later "while we're here" change has to argue with a test rather than quietly bind it.

Five tests in `opt/utilz/test/dispatcher.bats`, verified red before the fix (4 of the 5 failed; the `-v` test passed from the start, which is the point of including it). Documented in `help/utilz.md` under both `utilz help` and `utilz version`.
