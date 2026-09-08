---
st_id: ST0016
title: --help has one home, and both invocation forms agree
---

# ST0016: --help has one home, and both invocation forms agree -- Acceptance

> **THIS FILE IS A GENERATED VIEW, AND A ROW AUTHORED HERE IS DISCARDED BY THE NEXT SYNC.** The acceptance contract is canon in the thread model; this file renders it. Acceptance Criteria (AC) are the ratified completeness boundary; Acceptance Tests (AT) are the small red-to-green tests that prove them.
>
> Done = every AC is covered by a GREEN AT, or (for a non-test AC) its named evidence is satisfied, AND the AC set is the ratified full boundary. Done is read from this map, never from a hand-ticked box.
>
> Test-backed satisfaction is COMPUTED from covering green ATs and never stored -- storing it would be double truth. An AC has four states, not two: beyond satisfied and unsatisfied, a requirement can be **descoped** to a named thread or **withdrawn** with its reason on the record. Both are non-blocking and both are reported separately, so a thread that descoped half its contract looks like one.

## Acceptance Criteria

### Group AC01

- AC01 For every utility, '<util> --help' and 'utilz <util> --help' produce BYTE-IDENTICAL output. This is the defect: 14 of 15 disagreed before the change, the symlink form rendering the curated help/<name>.md and the dispatcher form falling through to the utility's terse inline usage. The covering test asserts the SIZE of the population it swept and refuses below the full set -- a discovery loop that silently narrows reports a clean pass over a partial population, and this thread's own precondition sweep (all 15 carry a curated help file) was verified with a count control rather than assumed. -- satisfied: no (computed)

### Group AC02

- AC02 The CURATED help/<name>.md is what both forms render, not the terse inline usage. Direction matters and is the decision: the inline block is a second home for the same concern -- cleanz carries 80 lines of it against 232 in help/cleanz.md, free to drift -- and it only ever surfaced because the dispatcher was not looking. Assert the rendered content comes from the curated file, not merely that the two forms agree: two forms agreeing on the WRONG one would satisfy AC01 completely. -- satisfied: no (computed)

### Group AC03

- AC03 '-h' agrees with '--help', on both invocation forms, for every utility. The intercept covers three flags and a test exercising only the long form cannot see a short form left behind -- which is exactly how this defect existed: one flag was intercepted at one site and the adjacent flag at neither. -- satisfied: no (computed)

### Group AC04

- AC04 '--version' is UNREGRESSED by this change: all 15 utilities, both forms, still answer the ST0015 pair form. The intercept that answers --help is the same function that answers --version, so an edit to one is an edit to both -- and a row proving --help now agrees says nothing about whether the older claim survived. ST0015 is closed and its evidence cannot be re-run from here, which is precisely why this thread must carry the check rather than assume the closed thread still holds. -- satisfied: no (computed)

### Group AC05

- AC05 There is ONE pre-dispatch intercept, not two. Adding a second --help-shaped intercept beside the --version one would rebuild the exact arrangement ST0015 removed -- two homes agreeing by convention, which is the arrangement that produced both defects. Proven by injection: a second intercept must turn this row red. -- satisfied: no (computed)

### Group AC06

- AC06 A DIRECTLY EXECUTED utility still prints its inline usage: 'opt/<name>/<name> --help' is not a dispatched invocation and this thread does not govern it. The row exists to pin the boundary cc drew in D4, where ST0016 deliberately DIFFERS from ST0015: ST0015 could delete its thirteen --version arms because show_version was the only producer either way, but here the inline block produces genuinely different text and is the only usage a directly-executed script can print. Without this row a later tidy-up reads the two threads as one pattern and deletes fifteen arms that nothing else replaces. -- satisfied: no (computed)

### Group AC07

- AC07 NO RENDERER IN show_help CAN BLOCK ON STDIN. Measured 8 Sep: 'glow help/cleanz.md' with an inherited interactive stdin did not return -- killed at 120s once and at a 5s timeout twice -- while the same command with '< /dev/null' returned exit 0 and 17450 bytes. The pager is NOT the variable: it hangs identically without '-p', which is opt-in and was never passed. THE ROW STATES A PROPERTY, NOT A MECHANISM, AND THIS WORDING IS A CORRECTION: it first said 'redirects stdin on every renderer arm', which is over-specified. show_help has three arms and only two need the guard -- 'cat "$help_file"' is always given a file argument and provably cannot block (measured: cat FILE exits 0 immediately; bare cat blocks at exit 124). Requiring a redirect there would add a token that protects nothing and teach the next reader that cat needs one. So: glow and bat carry '</dev/null'; cat is exempt BY MEASUREMENT rather than by omission. WHAT THIS ROW CLAIMS AND DOES NOT: it asserts the guard is present where it is needed, by inspection. It does NOT claim the hang is fixed -- cc could not reproduce it under 'script -q /dev/null' (exit 1, 59 bytes of terminal-query escapes, a third behaviour) and an unreproduced failure cannot be observed to stop. The behavioural form needs a faithful pty harness and is a thread, not a row. -- satisfied: no (computed)

### Group AT01

_(no criteria in this group)_

### Group AT02

_(no criteria in this group)_

### Group AT03

_(no criteria in this group)_

### Group AT04

_(no criteria in this group)_

### Group AT05

_(no criteria in this group)_

### Group AT06

_(no criteria in this group)_

### Group AT07

_(no criteria in this group)_

### Group AT08

_(no criteria in this group)_

## Acceptance Tests

### Group AC01

_(no tests in this group)_

### Group AC02

_(no tests in this group)_

### Group AC03

_(no tests in this group)_

### Group AC04

_(no tests in this group)_

### Group AC05

_(no tests in this group)_

### Group AC06

_(no tests in this group)_

### Group AC07

_(no tests in this group)_

### Group AT01

- AT01 `opt/utilz/test/help_dispatch.bats` -- covers AC01 -- status: to-write

### Group AT02

- AT02 `opt/utilz/test/help_dispatch.bats` -- covers AC02 -- status: to-write

### Group AT03

- AT03 `opt/utilz/test/help_dispatch.bats` -- covers AC03 -- status: to-write

### Group AT04

- AT04 `opt/utilz/test/help_dispatch.bats` -- covers AC04 -- status: to-write

### Group AT05

- AT05 `opt/utilz/test/help_dispatch.bats` -- covers AC05 -- status: to-write

### Group AT06

- AT06 `opt/utilz/test/help_dispatch.bats` -- covers AC06 -- status: to-write

### Group AT07

- AT07 `opt/utilz/test/help_dispatch.bats` -- covers AC07 -- status: to-write

### Group AT08

- AT08 `opt/utilz/test/help_dispatch.bats` -- covers AC07 -- status: to-write

---

_Generated by Intent v3.0.0 from `thread.json`. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
