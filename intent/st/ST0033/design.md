---
verblock: "10 Nov 2026:v0.1: utilz-dc - ST0033: the engine's proof surface, WP01"
---

# ST0033 design

utilz-dc, 10 Nov 2026, every file:line read at main's head 8212f662. No source path has moved since 5d7bfe37, the head the arms ran green at, so every line cited here is a line the arms exercised.

## Why this thread exists, in one measurement

ST0032 applied one standard, "the engine's coordination is small enough to read in the bytes", to two engine functions on the same day, by the same author, in the same words. It held for one and failed three times for the other, and the two differ in a way that predicts it.

`exec_place` (issue 0133) had four readings by three readers and no defect was found in it. It is a stateless mapping: no loop, no mutable state, and no ordering between an effect and a read. It also has a genuine live proof, because `acceptance.sh`'s apply mode drives it on every run, which is why a break in its own acceptance check was findable at all.

`exec_create_space` (issue 0135) took four commits with a defect found after each one, every one by a reader rather than by the reading, twice while the author knew the function was under suspicion. It has a retry loop, two captured mutable locals, run-scoped state that outlives the call, and an ordering dependency between an effect that CREATES and a read that is known to lag. It has no suite coverage at all: `create_space` appears in `acceptance.sh` zero times, and issue 0135's design claimed it was "proved live by acceptance.sh" citing `acceptance.sh:75`, which is the `hs_call` inside the OBSERVE mode, the one line in that file that could not touch a space creation.

So the question is not whether arngz's engine needs a test surface. It is WHERE reading stops being sufficient, and this project's answer is: where there is state, an effect, and an order between them. That is one function, not an engine, which is what makes this thread small.

The sharpest form of it is utilz-vc's, and it decides what the arms must assert: **the arithmetic was never wrong. What was wrong every time was the function's own account of what it had done.** Three of the four defects were in what the function REPORTED, not in what it computed. An arm that checks only "a space was made" would have passed on every defective version.

hv ruled twice on 10 Nov, first-hand in dc's window: "Hold until C5B9WJ is green, don't ship it unrun", and then, on being told that the arms' green cannot reach this function at all, "write the driver for exec_create_space before the cut".

## The shape: inject the boundary, not Hammerspoon

The driver sets a fake `hs` and runs the engine's own code under plain `lua`. No Hammerspoon, no pointer, no Mac, no desk booking, and nothing that touches hv's desktops. It goes inside `utilz test` and CI alongside `plan_test.lua`.

This is proof rather than ceremony for one reason: it reaches the two reporting paths a live run cannot produce to order. A real machine will not lag its `com.apple.spaces` registration on request, and will not overshoot from n to n+2 on request. Those are exactly where two of the four defects lived. A live run would have caught none of the four, which is the measured fact behind this design rather than an argument for it.

It is also PFIC-shaped (`IN-AG-PFIC-001`) rather than against it. `plan.lua` is pure and already tested by `plan_test.lua`. `arngz.lua` is the impure coordinator. The surface does not make the coordinator pure, nor move logic out of it to suit a test: it substitutes the boundary the coordinator talks to, which is the only part that cannot run here.

## Why the module loads under plain lua, read rather than assumed

This is the one fact the whole design rests on, so it was read in full rather than tried:

- Nothing at file scope touches `hs`. Every file-scope statement in `arngz.lua` is a `local` declaration, a constant, an `end`, or `local P = dofile(here .. "/plan.lua")`, and `plan.lua` is pure by `AT-03.2`.
- There is no `local hs = hs` and no `hs` captured at load. All 76 `hs.` references sit inside function bodies, so they resolve against the global at CALL time, which is what makes injection possible at all.
- Load time does `dirname(debug.getinfo(1, "S").source)` and one `dofile` of `plan.lua`. Both work under plain `lua`.

If any of that stops being true, the driver stops loading, and the fix is to say so rather than to bend `arngz.lua` to suit the test. A source edit to the engine would move the tree out from under the green at 5d7bfe37 and needs a fresh arms run, so it is a finding and a decision, never a step.

## The door: `M.execute`, not `exec_create_space`

`exec_create_space` is a `local function` at `arngz.lua:351` and is not reachable from outside the module. The driver goes through `M.execute(ops, ctx)` at `arngz.lua:1047`, which dispatches on the `EXEC` table at `arngz.lua:1042`.

That is the better door anyway, and not a workaround:

- It is the surface `apply` itself uses, three times (`arngz.lua:1245`, `:1261`, `:1308`).
- It exercises the result decoration every report depends on: `M.execute` sets `r.op`, `r.index`, `r.path`, `r.bundle` and `r.uncounted` on whatever the exec returned, and `apply_report` reads all of them.
- It carries the `pcall` that turns a raised Lua error into `{ status = "failed", reason = "lua error: ..." }`, so an arm can tell a reported failure from a crash. That distinction is the whole of `IN-AG-NO-SILENT-001` here.
- `ctx` is passed through and mutated, which is how the run-scoped `ctx.space_failed` is observable at all.

## The fake's whole surface: four functions

`exec_create_space`, its readback and its retry need exactly four `hs` entry points. The fake provides these and nothing else, so an engine change that reaches for a fifth fails loudly rather than silently reading `nil`:

| Function                          | Used by                             | What the fake does                                        |
| --------------------------------- | ----------------------------------- | --------------------------------------------------------- |
| `hs.spaces.addSpaceToScreen(u,b)` | `exec_create_space` (`:394`)        | returns a scripted id, or `nil, why`; counts its calls    |
| `hs.spaces.spacesForScreen(u)`    | `user_space_count` (`:340`)         | returns the next scripted space list, or `nil, err`       |
| `hs.spaces.spaceType(id)`         | `user_space_count` (`:344`)         | returns `"user"`, which is all `P.is_user_space` accepts  |
| `hs.timer.usleep(us)`             | `attempts` (`:100`)                 | counts the call and returns at once; never sleeps         |

Two notes that matter for the arms. `P.is_user_space` is `space_type == "user"` (`plan.lua:286`), so the fake's `spaceType` must answer with that exact string or every count reads zero. `P.space_error_kind` returns `"gone"` only for a reason containing "no display with specified id found" (`plan.lua:1219`), so the vanished-display arm must use that literal text, and it reads it from `plan.lua` rather than writing it down twice.

**Four is complete for THIS path, not for the engine**, and the distinction is the fake's own limit rather than a detail. `exec_create_space` reaches `addSpaceToScreen` directly, `spacesForScreen` and `spaceType` through `user_space_count`, and `usleep` through `attempts`. Nothing on that path calls `now()`, whose `hs.timer.absoluteTime` the fake does NOT provide: those calls are all in the launch and wait paths, at `arngz.lua:578`, `:619`, `:688`, `:1137`, `:1147` and `:1189`. So the fake is complete for an op list of `create_space` alone, and an arm that ever included a `place` or `launch` op would fail on a nil `absoluteTime` rather than report anything. That is the right failure, since it is loud, but it means the fake's completeness is a property of the op kinds the arms use and has to be re-established if they widen. Found by utilz-vc while checking this premise rather than taking it.

## The arms

Nine arms, driving `M.execute({{ op = "create_space", screen = <uuid> }}, ctx)`. Each scripts the count sequence the fake will answer with, which is the thing a real machine cannot be asked to do.

1. **A clean create.** `addSpaceToScreen` returns an id; the count goes 2 then 3. Expect `done`, `readback.user_spaces` of 3, `addSpaceToScreen` called once, and `ctx.space_failed` empty.
2. **A lag that catches up.** Returns an id; the count reads 2, 2, 2, then 3. Expect `done`, and **`addSpaceToScreen` called exactly ONCE**. This is the regression arm: the version at `fa0a7b58` would have called it four times and made up to four desktops where one was asked for.
3. **A lag that never catches up.** Returns an id; the count stays 2 throughout and after. Expect `failed`, the reason carrying "it reported making a space and the desktop list never caught up", `addSpaceToScreen` called once, and **`ctx.space_failed` NOT bound**, because a call that did make a space has not shown the display to be unusable.
4. **An overshoot.** Returns an id; the count goes 2 then 4. Expect `failed`, the reason naming both numbers, and no binding.
5. **Nothing made, transient.** Returns `nil, "the Dock is not answering"`; the count never moves. Expect `failed`, the reason carrying the Dock text, **`addSpaceToScreen` called four times** (`M.CREATE_SPACE_TRIES`, read from the module rather than written down), three `usleep` calls, and `ctx.space_failed` bound.
6. **A vanished display.** Returns `nil, "no display with specified id found"`. Expect `failed`, **`addSpaceToScreen` called exactly ONCE** because the stop predicate fires, and bound.
7. **The count cannot be read before.** `spacesForScreen` returns `nil, err` on the first call. Expect `failed`, the reason carrying "could not count the desktops before", **`addSpaceToScreen` never called**, and bound.
8. **A bound display is not tried again.** Two `create_space` ops on the same screen in one `M.execute`, the first failing as arm 5. Expect the second to report "already failed and was not tried again" and to add NO further `addSpaceToScreen` calls. This is run 35 of hv's log, which asked for seven spaces and reported the same Dock failure seven times.
9. **A bound display does not bind another.** Screen A fails as arm 5, then an op on screen B succeeds. Expect B `done`, proving the binding is per-display and not per-run.

No expected number in any arm is written by hand where it can be derived: the retry count comes from `M.CREATE_SPACE_TRIES`, the sleep count from that minus one, and the "gone" literal from `plan.lua`.

## Every arm proven by mutation, against a COPY of the engine

utilz-vc's condition, and it is the day's other lesson: a driver written against code that already works can pass while asserting nothing. Three of vc's own tests were found in exactly that state today, one of which could not go red at all. So each arm is proven by a one-line mutation that the arm must catch, applied one at a time and named here with the defect it recreates.

**The mutation is applied to a COPY of `lib/`, never to the tree's `arngz.lua`.** The driver takes the engine's path as `arg[1]` and finds `plan.lua` beside it, so a copy in a scratch directory is driven exactly as the real one is. That is strictly stronger than mutating in place and reverting: the tree's engine is never written at all, so an interrupted run cannot leave it mutated, and the act of proving the arms cannot disturb the green at `5d7bfe37`. `arngz.lua`'s sha256 is recorded before and after the exercise, and is expected to be identical because nothing touched it.

| Mutation, applied to the copy                                | Line            | Arm that must go red | The defect it recreates                 |
| ------------------------------------------------------------ | --------------- | -------------------- | --------------------------------------- |
| `(after == before and not made)` becomes `(after == before)`  |  `arngz.lua:442` | 3                    | `bf6e5f08`, found by dc and critic-lua  |
| the `if not made then` guard becomes `if true then`            | `arngz.lua:393` | 2                    | `fa0a7b58`, the regression dc found     |
| the `now > before + 1` branch is removed                      |  `arngz.lua:399` | 4                    | the overshoot going unreported          |
| the stop predicate returns `false`                            |  `arngz.lua:419` | 6                    | the vanished display retried four times |

An arm that cannot be made to go red is not an arm, and gets reported as such rather than quietly kept.

## What this does NOT cover, said plainly

- **The rest of the engine.** `exec_place`, `exec_move` and `exec_launch` are untouched by this thread. `exec_place` is the one that measurably does not need it.
- **Hammerspoon's real behaviour.** The fake proves what the engine does with an answer, never that `hs.spaces` gives that answer. The lag, the overshoot and the "gone" text are taken from hv's own run logs (runs 32 and 35) and from `plan.lua`'s own predicate, not invented.
- **The live apply path.** `utilz use dev` plus `acceptance.sh` is still the only thing that drives the engine against a real Mac, is still a separate booking, and still wants a desk holding no app that enforces its own window size.
- **CI's Lua 5.4 leg.** `lua5.4` is absent on this machine, so anything run here is run under 5.5.1 alone.

## The runner, and where it hangs in the suite

The runner copies `plan_test.lua` exactly rather than inventing a second idiom (`IN-AG-HIGHLANDER-001`): `arg[1]` is the path to the library, `dofile` loads it, `check(name, ok, detail)` prints `  ok    <name>` or `  FAIL  <name>`, and the process exits 1 if anything failed.

**Its caller is a new file, `opt/arngz/test/engine.bats`, and `arngz.bats` gains no arm.** `run_tests()` in `opt/utilz/lib/common.sh` finds suites with `find "$test_dir" -name "*.bats"`, so a new file is discovered automatically. That matters for the audit trail rather than for convenience: `arngz.bats` is the file the arms ran green on, a new arm inside it would move its total off 158, and the next reader would have to re-establish what the green was of. It also keeps a proof surface for the engine out of the suite for the CLI. A `.lua` file is discovered by nothing, which is why `plan_test.lua` runs only because `AT-03.2` invokes it explicitly, and why this driver needs a caller at all.

**The arm parses the driver's summary rather than matching it, and that is the one place this design improves on `AT-03.2`.** A driver that ran no arms exits 0 and prints "0 passed, 0 failed", which both `assert_success` and a plain `"0 failed"` match would accept, so the suite would go green having proved nothing; and `"0 failed"` is a substring of `"10 failed"`. So the arm requires the summary line to be there, the failures to be none, and the count of what ran to be more than none. Neither number is written down: failures are checked against none, which is hv's "everything that ran passed", and passes only against having happened at all.

**One existing file does move, and it is a Highlander fix rather than a convenience.** `lua_bin()`, which decides which interpreter the project's Lua suites run under, was defined inside `arngz.bats`. With a second Lua suite it would have to exist in two places, so it moves to `opt/utilz/test/test_helper.bash`, which both suites already load and which already owns `command_exists` and `require_command`. The move is body-for-body identical, so it is provable by diff rather than by reading. The consequence is stated rather than left to be discovered: `arngz.bats` is now one deletion different from the file the arms ran, so its 158 arms want re-running, which a cut does anyway. The engine itself is untouched: `arngz.lua` and `plan.lua` are byte-identical to the green.

**The green's real path set.** The check dc added to vc's green this morning was "nothing outside `intent/` has moved", which was the right check for a tree that was only gaining records. The durable form names what the arms actually read: `opt/arngz/lib/plan.lua`, `opt/arngz/lib/arngz.lua`, `opt/arngz/test/plan_test.lua`, `opt/arngz/test/arngz.bats` and `opt/arngz/arngz`. Those are what must not move for a green to go on describing the code it was taken on, and it is the same lesson as pinning a run to its paths rather than to HEAD.

## Rules of the road

- `IN-AG-HIGHLANDER-001`: one runner idiom, copied from `plan_test.lua`; one fake `hs`, in one place; the "gone" literal read from `plan.lua` rather than restated.
- `IN-AG-PFIC-001`: the boundary is substituted, never the logic; no engine code moves to make it testable.
- `IN-AG-NO-SILENT-001`: the arms distinguish a reported failure from a Lua error, and arm 7 exists because a readback failure must not be blamed on the op it was reading back.
- hv's no-magic-numbers rule: no expected count is written by hand where the thing being counted can supply it.
