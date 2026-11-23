---
wp_id: WP-eae7
title: Progress toasts: Starting, Running and Finished, hung on the run log's progress points
scope: S
status: WIP
---

# WP-eae7: Progress toasts: Starting, Running and Finished, hung on the run log's progress points

## Objective

Show hv what an apply is doing while it runs. A Hammerspoon toast reads Starting with the desk's name, then Running..., rewritten in place as each wait and each step begins, then Finished, which says what happened, or why nothing moved, and stays up longer. It hangs on the run log's progress points (progress.md), and nothing it does can change what an apply does or reports.

# Toasts: Starting, Running and Finished (design)

Design by ic, for vc's read before any code. It hangs on the progress points in the thread's `progress.md`, dc's, as ic agreed to them with four changes, all taken, committed at 2c59d1d6. Read against arngz as it stands on main (opt/arngz last changed at c7a5df87, 10 Nov), dc's log read of 23 Nov, and the thread's design.

## What hv asked for

hv, 23 Nov, first-hand in vc's session: "It needs to have a toast when: Starting, Running..., and Finished. And perhaps the finished toast needs more info in it." And: "I guess you want this to be simple, quick, and out of the way when it is working, but when it's not working (like now) it's inscrutable and opaque." hv decision 10 took vc's recommendation: Hammerspoon on-screen alerts.

The thread's design gives the evidence. Since 17 Nov, 11 applies were refused before anything moved, and no reason reached the screen: from Menuz, a refusal shows only as Menuz's own "exited 2" notice. A run that works shows nothing at all, because Menuz posts a notice only for a non-zero exit (run 115). So the Finished toast is the only sign a good run worked, and the only place a refusal's reason is shown.

## The design

One toast per apply, drawn by Hammerspoon, which every way of running arngz already goes through: Menuz, the CLI and auto. It reads Starting while the engine reads the screens, then Running..., rewritten in place as each piece of work begins, then Finished, which says what happened and stays up longer. It hangs on the run log's progress points: the engine emits each point once, writes it to the log, and hands the same name and fields to opt/arngz/lib/toast.lua, which returns a table with `point(name, fields)`. The toast never takes focus, a click or a grab point, and nothing it does can change what an apply does or reports.

It is drawn with hs.canvas, which hs.alert itself draws with, so it looks like hs.alert while its text changes in place. hs.alert can only close one alert and show another, which flickers and moves.

Toasts are for apply. Every other verb runs inside one IPC call, and Hammerspoon draws nothing until that call has answered, so only a Finished toast could ever show for one. Whether discover (Save Desk...) gets one is the open question below.

## What each toast says

The first line is always `arngz: <desk>`. Then, by point:

- **start**: `Starting: reading the screens and windows`. It is on screen while the inventory phase reads the screens and plans.
- **observed** and **planned** leave Starting as it is. Both come at the end of the inventory phase, and what hv needs next is a wait, a step or Finished. A refusal in either comes as finished.
- **waiting**: `Running... waiting for new desktops (up to 3 s)`, `waiting for launched apps (up to 20 s)` or `waiting for windows to show (up to 1.5 s)`, from the point's `for` and `seconds`.
- **step**: `Running... 5 of 12: moving Slack to desktop 2 on left`, `placing Safari on left`, `launching Mail` or `adding desktop 3 on left`. From the first step to finished, a second line reads `Hands off the mouse and keyboard until it finishes`: a move is a gesture, and runs 106 and 113 lost moves to a hand on the mouse.
- **finished**, by `outcome`:
  - done: `Finished in 13.2 s: 9 placed, 2 already in place, 1 desktop added`; when nothing needed doing, `Finished in 2.1 s: all 12 already in place`.
  - partly: `Finished in 13.2 s with problems: 9 placed, 1 not found, 1 failed`, then the first problem's words, then `arngz log has the rest`.
  - refused: `Refused, nothing moved: <the refusal>`, then `Fix: <its fix>`.
  - failed: `Failed at step 5 of 12, after 7.1 s: <the first failure>`, then `arngz log has the rest`.
- **A second apply** asked for while one runs is refused inside M.run, between the first run's callbacks. Its points carry their own `run`, so its toast is a small one of its own, just above the running one, which stays as it is: `Refused: zeopit is still being arranged`.

A count that is zero is left out. The counts are per desk entry: placed (by a step of this run), already in place, not found (unseen), skipped and failed, plus the desktops added. arngz removes no desktop today, so Finished names desktops added only; if 93ea7f8a adds removal, the point gets a count and the toast says it.

A line is at most 90 characters, cut with `...`, and a refusal or its fix may take two lines. An app is named as the step's `app` names it, by its display name where that is a bundle id (hs.application.nameForBundleID, falling back to the id), and never by a window title: a title can carry a mail subject or a file name, and a toast is on screen for anyone looking, a screen share included.

## How it shows

- On the primary display, the one with the menu bar, where Menuz is clicked, fixed for the run.
- At the bottom centre of that display's visible frame, a margin above the Dock.
- hs.alert's look, a rounded dark panel with light text, but smaller: the system font at 15 pt, at most 60% of the display's width.
- On every desktop (canJoinAllSpaces), and left alone by Mission Control (stationary). The engine switches a display's desktop while it carries a window, and the toast stays in view.
- At the `status` window level: above app windows and the Dock, below menus.
- Click-through: with no mouse callback, Hammerspoon's canvas ignores the mouse, so a click goes to the window under it. It never activates Hammerspoon or takes focus.
- One canvas per run. Each point rewrites its text and resizes it, with no fade between Running texts. Starting fades in and Finished fades out.
- Starting and Running stay until replaced. Finished stays 5 s after a clean run (done) and 15 s otherwise. A toast that has heard no point for 120 s removes itself, so a run that dies without a finished point cannot leave one on screen. Each of these is a named constant in toast.lua.
- A new run's Starting replaces whatever toast is up.

## Rules the toast keeps

1. **Never over a grab point.** A move presses on the window's title bar, and grab_point's hit test (opt/arngz/lib/arngz.lua:636 and :668) asks Accessibility what is under the point and refuses another app's window there. A Hammerspoon canvas may be what it finds, even though it ignores the mouse. So the toast hides for a move step when its frame would meet the title-bar strip of the window's frame now, which the step carries (change 2, below), and shows again at the next point. A pure function decides. A second grab in the same move, the carry after a drag, comes where P.drop_point lets go (opt/arngz/lib/plan.lua): the window's top left 80 points into the target display's visible frame, at the top of that display and never in the toast's band.
2. **Drawn between callbacks.** Hammerspoon draws only when its run loop turns, and the engine holds the loop inside each callback (pause, wait_for, and usleep in the hand). A toast shows what was set before a callback, and only once that callback returns. So each step goes out in the callback before the one that does it (change 1, below), and the toast reads "5 of 12" while window 5 moves, hidden first when rule 1 says so.
3. **State in a global.** dofile makes the engine and its modules anew at every IPC call (D20), so the canvas and its timers live in one global, `arngz_toast`, as `arngz_running` and `arngz_timer` do. That is how a later call replaces or closes the toast an earlier call drew.
4. **Never changes the outcome.** The engine catches the hook's errors, writes them to the log and returns them once in the response (progress.md, rule 5). toast.lua also keeps every hs.* call inside its own pcall, so it can say which call failed. It never prints. Hammerspoon sends each print to every registered hs client, and a client arngz has killed raises `ipc port is no longer valid (early)` until it is pruned. The first touch of hs.canvas prints its lazy load the same way, so that touch is inside the pcall too, and while a killed client is still registered it can cost a run its toasts, and nothing else.
5. **Not a window anyone arranges.** The canvas is a non-standard Hammerspoon window. plan claims only named, standard, unminimized windows of a desk's apps (P.claimable, opt/arngz/lib/plan.lua:338), so apply never takes it. discover counts it among its "not standard windows" if one is up while it reads, and nothing more.

## The points it hangs on

progress.md is dc's. ic agreed to it on 23 Nov with four changes, and dc took all four (2c59d1d6):

1. Each `step` goes out in the callback before the one that does it: run_phase emits it before scheduling that callback (rule 2 above). prepare and launch run their creates and launches in one callback each, and dc chose to send all of a batch's steps before its callback, so the toast shows the batch's last step while the batch runs, and apply's phases stay as they are.
2. A move's `step` carries the window's frame now: `x`, `y`, `w`, `h` (rule 1 above).
3. `finished` carries `in_place` (the entries that needed nothing), `created` (the desktops added) and `fix` (a refusal's fix, beside `first`).
4. Every point carries `run`. A second apply refused while one runs emits its own `start` and `finished` under its own `run`, so its toast leaves the running one alone.

progress.md's rule 7 stands: the CLI's own moments are not points. A run refused before the engine is asked shows Menuz's "exited N" notice and no toast, and its reason is in the log. A failed engine run shows both the Finished toast and Menuz's notice; ic keeps both, so the notice stays the fallback for whatever the toast cannot show. Rule 8's "hands off" is the step's second line above, and rule 9 is "Toasts are for apply" above.

## Files, and who writes them

- ic, in this WP: opt/arngz/lib/toast.lua (new), with the pure `text(name, fields, run)`, `layout(lines, frame)` and `hides(toast_frame, fields)`, and `point(name, fields)`, a thin coordinator over hs.canvas; opt/arngz/test/toast_test.lua (new), plain lua as plan_test.lua is; and the "Toasts" section of help/arngz.md.
- dc, in 53ef07aa: the emitter, its call sites and the hook's loading in opt/arngz/lib/arngz.lua, the log in opt/arngz/lib/log.lua, and the CLI.

No file is edited by both seats. The points are the one thing both read.

## Proof

- toast_test.lua: each point's text, the caps, the zero counts left out, the run kept apart from a second apply's, the layout inside the visible frame, and the hide rule. Plain lua, run where plan_test.lua runs.
- With 53ef07aa, one hand run at the Desk: an apply from Menuz shows Starting, Running with "5 of 12" and "Hands off", and Finished with its counts; a refused apply shows why; a second click while one runs shows its own small toast. That run is the evidence for the criteria below. No bats arm is added for the toast.

## Acceptance criteria (proposed)

1. Every apply, from Menuz, the CLI or auto, shows a toast that reads Starting with the desk's name, then Running..., rewritten in place as each wait and each step begins (5 of 12, with its app, and "Hands off" from the first step), then Finished.
2. Finished says what happened: the windows placed, already in place, not found, skipped and failed, each only when not zero, the desktops added, and the time taken. A refusal says that nothing moved, why, and its fix. A failure says where it stopped and why. It stays up 5 s after a clean run and 15 s otherwise.
3. The toast never takes focus or a click, stays in view while the engine switches desktops, and is never over the title bar of a window the engine is about to grab.
4. A toast that cannot be drawn changes nothing else: the apply's moves, report and exit code are what they would be without it, and the log says why it was not drawn.

## Size and order

S. It needs 53ef07aa's emitter, so it lands with or after 53ef07aa, in the same release as the rest of the thread.

## Open, for vc

- discover (Save Desk...): it runs inside one IPC call, so a toast could only say "Saved" at the end. It is the other run that leaves hv waiting with nothing on screen (87 s once, 12 Nov). Not in this WP unless vc adds it.
- No setting turns the toasts off. If hv wants one, it goes in arngz.yaml.

## Acceptance

Acceptance Criteria for this work package are RENDERED into `ST589246c/acceptance.md`, under the `WP-eae7` heading. THAT FILE IS A GENERATED VIEW -- a row authored there is discarded by the next sync. The contract is canon in the thread's model, and the verbs write it: `intent ac new` and `intent at new` mint a row, `intent ac edit` and `intent at edit` reword or re-cite one, and `intent ac satisfy|unsatisfy|descope|rescope|withdraw|reinstate` and `intent at green|red|na` move its state. This cover never restates them.

---

_Generated by Intent v3 from the thread canon. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
