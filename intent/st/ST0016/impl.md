---
verblock: "08 Sep 2026:v0.1: cc - As-built notes for one-home --help dispatch"
---

# ST0016 -- Implementation

## What was built

**`version_intercept` became `predispatch_intercept`** and now answers `--version`, `--help` and `-h` for a dispatched utility, from both dispatch sites. The symlink site's inline `--help` block collapsed into it. **One function rather than two**: a second, `--help`-shaped intercept beside the `--version` one would have rebuilt the exact arrangement ST0015 removed.

**`show_help` closes stdin on both renderer arms** -- `glow ... </dev/null`, `bat ... </dev/null`. See D5.

## Evidence

Red-first: **14 of 15 utilities disagreed** between the two invocation forms before the change; **0 after**. `-h` agrees 15/15 too, and `--version` is unregressed 15/15.

Eight rows, each proved to go red by injecting the regression it catches:

| injection                             | red                          |
| ------------------------------------- | ---------------------------- |
| remove the dispatcher-site intercept  | AT01 AT02 AT03 AT04 AT05     |
| a second `--help`-shaped intercept    | AT05 alone                   |
| break `--version` inside the intercept| AT04 alone                   |
| remove the stdin redirect             | AT07 alone                   |
| delete cleanz's own `--help` arm      | AT06 alone                   |

Full suite **574 ok / 0 not ok**, denominator matched, the count predicted before the run rather than explained after it.

## AC06 has two exceptions, and neither is a defect

- **`expz`** -- its `-h|--help` arms call `show_help` directly, so it has no inline usage to keep. **This is why it was the 1 of 15 that agreed before the fix.**
- **`prez`** -- `opt/prez/prez` is a shim with no arm; clap answers `--help` inside the binary. Direct execution still works.

So the row asserts what is enforceable: all 15 answer `--help` when executed directly, 14 own an arm, and prez is named. **The count was wrong twice and the row was fixed both times rather than the constant.**

## Three errors found while writing that row, all the same family

1. **Curated-vs-inline classified by grepping for the help file's first line** -- which is the utility's NAME, and appears in `Usage: cleanz [OPTIONS]` too. Read 13 of 14 backwards.
2. **Asserted 14 shell implementations; there are 15.** prez's shim is a bash script, a fact this project's own board already carried.
3. **The arm-detection regex demanded `-h|--help)` exactly.** `todo` writes `-h | --help)` **with spaces**, so it reported as armless. A population narrowed by an assumption about SPELLING -- the same shape as matching one flag and missing the other, which is the defect this thread exists to fix, committed inside the test for it.

**Only the third was caught by a row going red.** The first two were caught by reading output that did not look right.

## D5 -- the stdin redirect, and what is NOT claimed

`show_help` called `glow "$file"` with a terminal on stdin. This project has a hang recorded twice from real incidents. **The pager was suspected by both nodes and was wrong**: `-p` is opt-in, injecting it changed nothing, and the bare call hangs anyway. Two incompatible wrong accounts -- "pager breaks scripts", "pager is inert because it keys on stdout" -- agreed on the conclusion while the real defect sat underneath the thing both were arguing about.

**The hang was not reproduced here.** Under a `script`-allocated pty, glow exits 1 emitting terminal-query escapes: a third behaviour, neither the hang nor a clean render. That is a fact about the harness, not about the defect.

**So the redirect is justified without claiming a fix.** A renderer handed a FILE has no business reading stdin; one token cannot make anything worse; and ST0016 routes 14 more invocations into `show_help`, so hardening it is part of not making things worse. **AT07 asserts the guard is PRESENT, by inspection, and says so.** A behavioural proof needs a faithful pty harness, which is a thread rather than a row.
