---
st_id: ST0034
title: arngz remembers a size the app enforces
---

# ST0034: arngz remembers a size the app enforces -- Acceptance

> **THIS FILE IS A GENERATED VIEW, AND A ROW AUTHORED HERE IS DISCARDED BY THE NEXT SYNC.** The acceptance contract is canon in the thread model; this file renders it. Acceptance Criteria (AC) are the ratified completeness boundary; Acceptance Tests (AT) are the small red-to-green tests that prove them.
>
> Done = every AC is covered by a GREEN AT, or (for a non-test AC) its named evidence is satisfied, AND the AC set is the ratified full boundary. Done is read from this map, never from a hand-ticked box.
>
> Test-backed satisfaction is COMPUTED from covering green ATs and never stored -- storing it would be double truth. An AC has four states, not two: beyond satisfied and unsatisfied, a requirement can be **descoped** to a named thread or **withdrawn** with its reason on the record. Both are non-blocking and both are reported separately, so a thread that descoped half its contract looks like one.

## Acceptance Criteria

### WP-01 -- plan, engine and shim: remember an enforced size, and recheck it (status: Done)

- AC-01.1 P.plan emits recheck, not place, for a window that is not moving, whose origin agrees with its cell and whose size matches a record for its bundle and wanted size; and emits place when the origin differs, the size matches neither record nor cell, or the record is for another bundle or wanted size, every comparison through P.origins_agree and P.sizes_agree. -- satisfied: yes (computed)
- AC-01.2 P.plan_exit and plan_report read a recheck as in place, saying "in place at the app's own size, WxH" from one helper that apply_report uses too, so diff reads no change for a desk whose only difference is a recorded own size. -- satisfied: yes (computed)
- AC-01.3 P.own_sizes_after merges a run's results into the records: an own_size readback of a place or recheck adds or replaces the record for its bundle and wanted size, a placed readback removes it, anything else leaves the records as they were, records for other keys are untouched, and merging the same results twice gives the same records. -- satisfied: yes (computed)
- AC-01.4 The engine executes a recheck as it does a place, by setFrame and readback, and its response carries the records P.own_sizes_after returns. -- satisfied: yes (computed)
- AC-01.5 The shim passes the own-sizes file's records to diff and apply, treats a missing file as no records and an unreadable or malformed one as no records said once on stderr, and apply writes the records the engine returns atomically and only when they changed. -- satisfied: yes (computed)
- AC-01.6 (non-test) Live, on hv's machine: arngz apply zeophq then arngz diff zeophq reads no change with Appgate SDP present, which makes acceptance.sh apply zeophq passable for ST0032's AC-01.4 and AC-01.5. -- evidence: vc decision 107 (28b8a381): hv's live run on 10 Nov 2026, desk homere standing in for zeophq (zeophq's saved 22E1W-above layout absent). arngz apply homere placed com.appgate.sdp in place at the app's own size, 375x667; arngz diff homere; echo rc=$? read the three unseen lines (Finder, Ivory, Console, not 0138's) and 'window 96 in place at the app's own size, 375x667 (displays[0].spaces[4].apps[1])', a recheck not a change, rc=0 -- satisfied: yes

## Acceptance Tests

### WP-01 -- plan, engine and shim: remember an enforced size, and recheck it (status: Done)

- AT-01.1 `opt/arngz/test/plan_test.lua` -- covers AC-01.1 -- status: green -- to write: the planner arms; red at 1401e7b3, where options.own_sizes and the recheck op do not exist. RED at the base 1401e7b3's code with the new tests laid over, in ~/Devel/scratch/utilz-dc/0133b/runs/st0034-wp01-20261110T175113Z.log (sha 09d003e3, driver ca20bf16, booked by devbin-vc in slot 01M739BNQ7EFKJHXHNFNEY4629): every new arm red there or named GREEN_AT_BASE in 0133b/guards.tsv (8b5c9b12). GREEN at the fix (code diff fa94557f) in the same run: plan_test 263/0, engine_test 51/0, bats 165 ok 0 not ok; ALL PASS
- AT-01.2 `opt/arngz/test/plan_test.lua` -- covers AC-01.2 -- status: green -- to write: plan_exit and plan_report arms; red at the base, where recheck is unknown. RED at the base 1401e7b3's code with the new tests laid over, in ~/Devel/scratch/utilz-dc/0133b/runs/st0034-wp01-20261110T175113Z.log (sha 09d003e3, driver ca20bf16, booked by devbin-vc in slot 01M739BNQ7EFKJHXHNFNEY4629): every new arm red there or named GREEN_AT_BASE in 0133b/guards.tsv (8b5c9b12). GREEN at the fix (code diff fa94557f) in the same run: plan_test 263/0, engine_test 51/0, bats 165 ok 0 not ok; ALL PASS
- AT-01.3 `opt/arngz/test/plan_test.lua` -- covers AC-01.3 -- status: green -- to write: the merge arms; red at the base, where P.own_sizes_after does not exist. RED at the base 1401e7b3's code with the new tests laid over, in ~/Devel/scratch/utilz-dc/0133b/runs/st0034-wp01-20261110T175113Z.log (sha 09d003e3, driver ca20bf16, booked by devbin-vc in slot 01M739BNQ7EFKJHXHNFNEY4629): every new arm red there or named GREEN_AT_BASE in 0133b/guards.tsv (8b5c9b12). GREEN at the fix (code diff fa94557f) in the same run: plan_test 263/0, engine_test 51/0, bats 165 ok 0 not ok; ALL PASS
- AT-01.4 `opt/arngz/test/engine_test.lua` -- covers AC-01.4 -- status: green -- to write: an injected-hs arm (ST0033's surface); red at the base, where the engine has no recheck. RED at the base 1401e7b3's code with the new tests laid over, in ~/Devel/scratch/utilz-dc/0133b/runs/st0034-wp01-20261110T175113Z.log (sha 09d003e3, driver ca20bf16, booked by devbin-vc in slot 01M739BNQ7EFKJHXHNFNEY4629): every new arm red there or named GREEN_AT_BASE in 0133b/guards.tsv (8b5c9b12). GREEN at the fix (code diff fa94557f) in the same run: plan_test 263/0, engine_test 51/0, bats 165 ok 0 not ok; ALL PASS
- AT-01.5 `opt/arngz/test/arngz.bats` -- covers AC-01.5 -- status: green -- to write: shim arms against a fake engine; red at the base, where the shim reads no own-sizes file. RED at the base 1401e7b3's code with the new tests laid over, in ~/Devel/scratch/utilz-dc/0133b/runs/st0034-wp01-20261110T175113Z.log (sha 09d003e3, driver ca20bf16, booked by devbin-vc in slot 01M739BNQ7EFKJHXHNFNEY4629): every new arm red there or named GREEN_AT_BASE in 0133b/guards.tsv (8b5c9b12). GREEN at the fix (code diff fa94557f) in the same run: plan_test 263/0, engine_test 51/0, bats 165 ok 0 not ok; ALL PASS
- AT-01.6 (non-test) hv runs arngz apply zeophq then arngz diff zeophq with Appgate SDP present, and diff reads no change -- covers AC-01.6 -- status: n/a -- hv's live run, after the code lands and 2.14.10 is in hv's hands

---

_Generated by Intent v3 from the thread canon. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
