---
st_id: ST0033
title: A test surface for arngz's engine, starting with exec_create_space
---

# ST0033: A test surface for arngz's engine, starting with exec_create_space -- Acceptance

> **THIS FILE IS A GENERATED VIEW, AND A ROW AUTHORED HERE IS DISCARDED BY THE NEXT SYNC.** The acceptance contract is canon in the thread model; this file renders it. Acceptance Criteria (AC) are the ratified completeness boundary; Acceptance Tests (AT) are the small red-to-green tests that prove them.
>
> Done = every AC is covered by a GREEN AT, or (for a non-test AC) its named evidence is satisfied, AND the AC set is the ratified full boundary. Done is read from this map, never from a hand-ticked box.
>
> Test-backed satisfaction is COMPUTED from covering green ATs and never stored -- storing it would be double truth. An AC has four states, not two: beyond satisfied and unsatisfied, a requirement can be **descoped** to a named thread or **withdrawn** with its reason on the record. Both are non-blocking and both are reported separately, so a thread that descoped half its contract looks like one.

## Acceptance Criteria

### WP-01 -- The create_space driver: an injected hs, every reporting path, each arm proven by mutation (status: WIP)

- AC-01.1 The four reporting behaviours of create_space that issues 0133, 0134 and 0135 never named, each asserted on the function's own ACCOUNT of what it did rather than on its arithmetic: a creation that reported a space and whose readback never caught up does NOT bind the display for the rest of the run, because a call that made a space has not shown the display unusable; a readback that cannot be read at all is reported as the count failing BEFORE the create and nothing is created; a display already bound is refused with the cause quoted rather than tried again; and a bound display does not bind its neighbour, the binding being per-display and not per-run. ST0032's AC-03.3, AC-03.4 and AC-03.5 carry the three the issues did name and are descoped here by utilz-vc, so each behaviour is asserted once. -- satisfied: no (computed)
- AC-01.2 The creating call's COUNT is asserted, not just its outcome: addSpaceToScreen is called exactly once when it reported a space however long the readback lags, exactly once when the display is gone, M.CREATE_SPACE_TRIES times when nothing was made, and never when the count could not be read before. The budget and the sleep count are read from the module rather than written down. -- WITHDRAWN: Subsumed by ST0032's AC-03.3, which utilz-vc is descoping to ST0033 in the same exchange and which came first, is written per-defect, and is what issue 0135 actually requires: a creation reporting no space is retried up to CREATE_SPACE_TRIES while one reporting a space is attempted once. Keeping both would assert the same requirement twice on one thread. The call-count assertions beyond AC-03.3's scope, that nothing is created when the count cannot be read first and that a bound display adds no further calls, moved into AC-01.1 rather than being lost. (by utilz-dc)
- AC-01.3 (non-test) Every arm is proven by a one-line mutation that makes that arm go red, applied one at a time and each named in the work package with the defect it recreates. The mutation is applied to a COPY of opt/arngz/lib, never to the tree's arngz.lua: the driver takes the engine's path as its argument and finds plan.lua beside it, so a copy is driven exactly as the real one is, an interrupted run cannot leave the engine mutated, and proving the arms cannot disturb the green at 5d7bfe37. arngz.lua's sha256 is recorded before and after and is identical. An arm that cannot be made to go red is reported as not an arm rather than kept. -- satisfied: no
- AC-01.4 The driver runs inside the suite the way plan_test.lua does, under whichever of lua5.4, lua or luajit is present, with its test count taken from the run rather than asserted as a number written by hand. -- satisfied: no (computed)

## Acceptance Tests

### WP-01 -- The create_space driver: an injected hs, every reporting path, each arm proven by mutation (status: WIP)

- AT-01.1 `opt/arngz/test/engine_test.lua` -- covers AC-01.1 -- status: to-write -- The driver: an injected hs under plain lua, ten arms over create_space's reporting paths and call counts. Covers AC-01.1 now and will be re-cited to cover ST0032's AC-03.3, AC-03.4 and AC-03.5 once utilz-vc has descoped them here. Starts to-write; proven by mutation under AC-01.3 before it is marked anything else.
- AT-01.2 `opt/arngz/test/engine.bats` -- covers AC-01.4 -- status: to-write -- The suite arm that runs the driver, in its own bats file so arngz.bats is not disturbed: run_tests() finds suites by glob, so a new file is discovered without touching the one the arms ran green on. Starts to-write.
- AT-01.3 (non-test) The mutation proof: four one-line mutations to arngz.lua, each applied alone and reverted, each named with the arm that must catch it and the defect it recreates, with arngz.lua's sha256 identical before and after. Recorded in WP01's body rather than in a file, because the artefact is the record of the runs and not a test that ships. -- covers AC-01.3 -- status: n/a

---

_Generated by Intent v3 from the thread canon. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
