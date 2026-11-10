---
st_id: ST0032
title: arngz: a desk picked from the monitors present, and the three defects that stop apply ever exiting 0
status: WIP
created: 2026-11-10
completed:
---

# ST0032: arngz: a desk picked from the monitors present, and the three defects that stop apply ever exiting 0

## Objective

Make `arngz apply` tell the truth about whether a desk went into place, and let one menu item pick the desk for the monitors in front of you.

Today `arngz apply` has never exited 0: of the 33 apply runs in hv's menuz log, 29 exited 1 and 4 exited 2. Three defects account for the exit-1 runs, and one of them, issue 0132, is already fixed on main and unreleased. The other two, issues 0133 and 0134, plus issue 0135, are this thread's first three work packages. The test that pins them is simple and is currently failing: **a desk `discover` has just saved applies cleanly straight afterwards, on the same screens.** Run 69 saved zeophq and exited 0; run 70, an apply of that same desk 20 s later on those same screens, exited 1.

The feature is hv's: one menu item that works out which desk the revealed monitor configuration is, selects it, and falls back to a named default when no desk fits. The matching it needs already exists and is already pure (`P.match_displays`, `plan.lua:130`), so this is an exact-cover rule over every desk plus two thin verbs, not new window-arranging machinery.

Done when `arngz which` names the desk the screens present fit, `arngz auto` applies it or the default, the menu's `Discover` runs that and `Save Desk…` saves as before, and a desk saved by `discover` applies with exit 0 on the same screens.

## Context

## How this arrived

hv typed the question and the feature request into gtools-vc's window by mistake on 10 Nov 2026. gtools-vc analysed it, changed nothing, and handed its analysis to utilz-vc over the socket; utilz-vc verified the handover's hash, re-derived every claim from the source and hv's `~/.local/state/menuz/menuz.log` first-hand, and banked a byte-identical copy at `~/Devel/scratch/utilz-vc/arngz-handover-20261110.md` (sha256 c0727ec6708e3f1dee92968a470a441b89e6c4570de555a7c46c4da9d99426b8, 130 lines), which carries hv's verbatim words and the three screenshots' paths.

One of gtools-vc's claims looked wrong on first check and was not: utilz-vc's initial exit-code census showed 7 exit-0 runs against gtools-vc's "no apply has ever exited 0", because utilz-vc had bucketed by menu label, which lumps `Empty the Trash` and six `utilz macoz bg` items in with the applies. Counted by command, gtools-vc's figures are exact to the run number.

## hv's rulings, 10 Nov

Given first-hand in utilz-vc's session, in answer to utilz-vc's four questions:

1. **One release, everything together.** 0133, 0134, 0135 and the feature go out as one release, not as separate small ones: "I DO NOT WANT MULTIPLE BITTY RELEASES. I want _all_ of this fixed and/or created now in this session." utilz-vc put the cost of that on the record before hv chose it, and hv chose it knowing: see the pin below.
2. **The number stays a patch, 2.14.9.** utilz-vc recommended 2.15.0, since a new verb and a new menu item are new functionality rather than a fix, and hv ruled for a patch. The release number is hv's. The CHANGELOG's existing `[2.14.9] - unreleased` section absorbs this work.
3. **The menu reads `Discover` and `Save Desk…`.** `Discover` picks the desk from the monitors present; `Save Desk…` is what `Discover…` does today, renamed to match its own dialog. The CLI verb `discover` keeps its meaning, so nothing breaks; the rename is in the menu only.
4. **No desk fits: fall back to a named default**, `arngz auto --default rhad`, with the notice naming the desk it chose so a fallback is visible. utilz-vc recorded the caveat hv accepted: rhad is laptop-only, so the fallback moves apps onto the laptop screen even with monitors plugged in.

## The pin, and what hv's first ruling costs

2.14.9's release runs are all pinned on 195b1c91, and the cut's own precondition is that nothing outside `intent/` has moved since that sha. Every work package here lands outside `intent/`. So on hv's ruling, **R1, R2, R3 and every tree-scan file must be run again at the new head**, on top of this thread's own red and green arms. That was stated to hv as the cost of one release and accepted. The alternative, cutting 2.14.9 as it stood and shipping this as 2.15.0, was declined.

Where 2.14.9 stood when this thread opened: ST0031/04's records and step 2 landed at 195b1c91; R2 red at the base and green at the fix, R3's dry run, R1 and the tree-scan files were all green on devbin-vc's desk; hv had pushed main to both remotes at 195b1c91 and CI there is green (run 42028263538, and the macOS dispatch 42227268608 read by vc on 10 Nov: macOS 1023 ok and 0 not ok, Ubuntu 1013 ok and 0 not ok, cargo 419 on both legs). All of that proof is now superseded by this thread's landings.

## Who is writing this, and what cannot be run

**utilz-dc was down when this thread was planned, and came up later the same day.** ST0031/04 is dc's claimed WIP and its close-out was waiting on the cut this thread now moves. hv directed that all of this be done "now in this session", and utilz-vc is the only Utilz node up, so **vc is writing the code here rather than checking dc's**, which is a departure from vc's advisory role and is recorded so the authorship is not misread later. The work still wants a second read: either dc when it comes up, or `critic-lua` and `critic-shell` on the diff.

**vc decision 74 stands: no Claude runs a test or a build, and hv runs the suites.** Every host run books through Intent's slots at the desk, which `agentic-engineering-vc` holds, with AE's 0.3.x on total focus by hv's own word this morning. So this thread can write and land its code and its designs, and its red and green arms, the tree-scan files and the re-run of R1, R2 and R3 need either hv's own run or a desk grant. That is the one thing "all fixed in this session" cannot include on its own.

## Shape

- **Issues**: 0133 (high), 0134 (medium), 0135 (medium), each carrying its own `## Measured` and `## Fix`. Each work package's design goes in its issue before any source edit, per 0132's precedent.
- **The feature is mostly pure**: `P.match_displays` (`plan.lua:130`) already binds a desk's displays to screens by uuid, then name and size, then position, and refuses a display matching none or several. Auto-selection runs it over every desk under an **exact-cover** rule: each of a desk's displays binds a distinct screen *and* every screen present is bound. The second half is what stops rhad, which is laptop-only, matching at every site.
- **Two desks fitting the same screens**: prefer the current desk, else refuse naming both.
- **`arngz which` costs a Hammerspoon call**, so it belongs in a run or a parameter default, never in a menu label realised at every menu open as `current` is.
- **WP05 touches another repository.** The menu is Molt-matts `config/menuz/menuz.yaml` and the desks are Molt-matts `config/arngz/desks/`, linked as `~/.config/menuz` and `~/.config/arngz`. Nothing in Menuz itself changes.

## Loose ends found on the way, not this thread's work

- Today's `Discover` wrote `zeophq.yaml` into Molt-matts' working tree, where it sits modified and uncommitted.
- `hockenbury` still carries two `SET-ON-SITE` placeholder monitors from Molt-matts 0f7b487, so it matches no screen and `apply hockenbury` exits 2 until a `discover` on site replaces them. That exit 2 is by design and is the other half of hv's "depending on where I am".
- Molt-matts 9adb5ae dropped Appgate from every desk on 2 Nov, and every later `discover` re-records it. WP01 is what makes that harmless.

## How the review actually went, which is the thread's own measurement

utilz-dc came up on hv's word partway through and read the whole thread: `plan.lua`, `arngz.lua`, `opt/arngz/arngz`, `arngz.bats`, `plan_test.lua`, the three fixtures, the help, the CHANGELOG, the README, this thread's `design.md` and the Design sections of all three issues, across every commit. `critic-lua` and `critic-shell` read the code before it.

What that produced, and it is why the thread was worth trusting at all while nothing had yet been executed, which was the case when this was written: **four real defects, one regression, and five drift items in documents rather than code.** critic-lua found the retry wrapping a creating call and a suppression bound on a succeeding path. critic-shell found the platform gate never learning the two new verbs, an unwrap-or-default on the desk name, a test of vc's that could not go red, and two more of vc's that would have run against the host's real `defaults`. utilz-dc found that vc's first fix to the retry was **worse** than what it replaced, then that the second still bound the run when a space had been made, then that the release-facing CHANGELOG and help described behaviour that had been removed as a defect, then that `acceptance.sh` could not match the line WP01 exists to print, then that `apply` and `diff` now disagree about that window.

**Every defect in `exec_create_space` was found by a reader after the commit, never by the reading its design offered as the proof** — twice while vc knew the function was under suspicion. `exec_place`, designed and proved under the same words on the same day, had four readings and none. That contrast is this thread's most useful output and is written up in `design.md`; the sharper form of it is utilz-dc's, after dc corrected its own first account.

The code here is vc's and the second read is dc's. ST0031/04 remains dc's and untouched.

## What executing it showed, 10 Nov afternoon

The thread was first executed after the review above, and the execution found what the review could not.

- **The arms ran green** in slot NTVCDH at 5d7bfe37, run by the desk holder on hv's choice: `plan_test.lua` 240 passed, 0 failed, and `arngz.bats` 1..158, every count taken from the run. hv then made two rulings that gate the cut: don't ship it unrun (vc decision 96), and write a driver for `exec_create_space` before the cut (vc decision 97), because the arms cannot reach the engine at all.
- **The driver is ST0033's**, built by utilz-dc. It is mutation-proven on all ten of its arms and passes 6 of 6. It landed at `d7047f70`, together with issues 0136 and 0137, which dc found while writing it.
- **Fifteen of this thread's sixteen test rows are mutation-proven** (slot PDY9E2). Fourteen one-line mutations each landed on one line and turned the test they were aimed at red. One was rejected by its author: M14 broke the file's syntax, turned 145 of 158 tests red for the wrong reason, and proved nothing about its target. A version that parses replaced it.
- **AT-03.2 was not proven, and was first recorded as if it were.** The run checked that every mutation turned something red, not that every test was turned red by something, and vc filled the gap for AT-03.2 with a reason. Corrected at `79487479`. Its criterion, AC-03.2, is withdrawn on hv's word (vc decision 100): true by reading the engine, proven by no test anywhere.
- **The contract is blocked only on citations.** `intent at lint` reports 12 rows whose cited file lacks the literal id, and its four passes are false, because ST0026's and ST0028's tests share these files and use the same numbers. The fix is a comment beside each arm naming the thread, `AT-01.1 (ST0032)`, on the fifteen live rows. Under hv's order (vc decision 98) it comes next, then the one full suite run that is the cut's own.
- **What still stands between this thread and its close**, and the cut does not settle it: AC-01.4 and AC-01.5 want the live path, `utilz use dev` and then `acceptance.sh` on a desk holding no app that enforces its own window size; AC-04.10 rests on reading alone; and AC-05.4 is the menu, in Molt-matts. Lua 5.4 has not been run by anything today: every run used 5.5.1.

The contract, the AT notes and vc's decisions 95 to 101 carry the detail. This section is a pointer, not a second account.

## Work Packages

| WP    | Title                                                                                       | Size | Status |
| ----- | ------------------------------------------------------------------------------------------- | ---- | ------ |
| WP-01 | 0133: apply counts a window held at the app's own size as placed                            | S    | WIP    |
| WP-02 | 0134: discover leaves out a window lying mostly off its display                             | S    | Done   |
| WP-03 | 0135: create_space retries, reports a persisting cause once, and refuses a vanished display | S    | Done   |
| WP-04 | Desk auto-selection: a pure detect, arngz which and arngz auto                              | M    | WIP    |
| WP-05 | The menu, the help and the CHANGELOG                                                        | XS   | WIP    |

## Acceptance

Acceptance Criteria and Acceptance Tests are RENDERED into `acceptance.md`, which is a GENERATED VIEW -- a row authored there is discarded by the next sync. The contract is canon in this thread's model, and the verbs write it: `intent ac new` and `intent at new` mint a row, `intent ac edit` and `intent at edit` reword or re-cite one, and `intent ac satisfy|unsatisfy|descope|rescope|withdraw|reinstate` and `intent at green|red|na` move its state. This cover never restates them.

---

_Generated by Intent v3 from the thread canon. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
