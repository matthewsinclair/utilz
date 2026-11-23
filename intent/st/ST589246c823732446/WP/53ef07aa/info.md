---
wp_id: WP-53ef
title: The run log: every run appends to arngz.log what it saw, planned, did and read back, and arngz log prints the last run
scope: S
status: Done
---

# WP-53ef: The run log: every run appends to arngz.log what it saw, planned, did and read back, and arngz log prints the last run

## Objective

Record what each arngz run saw, planned, did and read back, so a run that goes wrong after a display change can be diagnosed from its log rather than guessed at. Every run appends to ~/.local/state/arngz/arngz.log each display with its desktops, as com.apple.spaces records them and as they are live, the plan, each step and its readback, the outcome and the timings, and the CLI's side; the log puts nothing extra on screen and is capped in size, and `arngz log` prints the last run. It is what hv's diagnosis run was read from, and what the desk-change fix (93ea7f8a) was built on.

# The run log

Every arngz run appends what it saw, planned, did and read back to `~/.local/state/arngz/arngz.log`, beside `current` and `own-sizes`. `arngz log` prints the last run. The log puts nothing extra on screen, and its size is capped. This is what hv's diagnosis run on the dev tree reads, and what 93ea7f8a's design is built on.

## What hv gets

- `arngz log` prints the last run, start to finish, readable as it stands.
- The file is plain text, one record per line, so `less` and `grep` read it too.
- Nothing changes on screen. arngz prints what it prints today. One exception: when the log itself cannot be written, the CLI prints one warning line (see Errors).

## Which runs log

| Verb                               | Logs                   | Why                                                                                           |
| ---------------------------------- | ---------------------- | --------------------------------------------------------------------------------------------- |
| apply, diff, discover, which, auto | the whole run          | each reaches the engine                                                                       |
| doctor                             | the whole run          | its IPC check asks the engine to observe                                                      |
| init, delete                       | one start and end pair | each changes something: Hammerspoon's config, or the catalogue                                |
| list, show, current, log, help     | nothing                | each only reads; Menuz runs `arngz current` at every menu open, and the log would drown in it |

## The record

One record per line, at most 1 KB:

```
<time> <run> <source> <event> <text>
```

- `time` is UTC. The engine writes milliseconds (`2026-11-23T05:11:28.412Z`). The CLI writes seconds (`2026-11-23T05:11:28Z`), from `date -u`, since bash 3.2 has no finer clock and its records need none.
- `run` is the CLI's run id, `<UTC yyyymmddThhmmssZ>-<CLI pid>`, eg `20261123T051128Z-48213`. The CLI passes it to the engine in the request, and every record of the run carries it. The display watcher's records carry `-`.
- `source` is `cli`, `engine` or `displays` (the watcher).
- `event` is one fixed word per kind of record, listed below, so `grep` can pick out one kind.
- A record too long for one line, such as a desktop with many windows, is split across several lines with the same event.

An illustration: an apply refused the way hv's run at 03:56Z today was. The desktop ids are that run's. The times, the pid, the watcher's change and the lists filed under the external displays are made up for the example, and the lines are cut to the ones that tell the story.

```
2026-11-23T03:56:44Z 20261123T035644Z-71022 cli start arngz 1.2.1, tree /opt/homebrew/Cellar/utilz/2.14.10/libexec, apply zeopit, from menuz
2026-11-23T03:56:44Z 20261123T035644Z-71022 cli hs started pid 71031, -t 60, waits up to 600 s for a scheduled apply
2026-11-23T03:56:45.103Z 20261123T035644Z-71022 engine start apply zeopit; Hammerspoon 1.1.1, macOS 27.2.1, Accessibility granted
2026-11-23T03:56:45.104Z 20261123T035644Z-71022 engine displays at start; last display change 41 s ago (03:56:04Z)
2026-11-23T03:56:45.161Z 20261123T035644Z-71022 engine screen 37D8832A "Built-in Retina Display" 1800x1169 main, primary, showing 3
2026-11-23T03:56:45.161Z 20261123T035644Z-71022 engine live 37D8832A: 1 3 1431 5 423 121 6 7 1586 1271 1442
2026-11-23T03:56:45.162Z 20261123T035644Z-71022 engine filed 37D8832A: 1586 under 2F1BFA83 (absent); 1271 1442 under 34791BF3 (absent)
2026-11-23T03:56:45.162Z 20261123T035644Z-71022 engine record Main: 1 3 1431 5 423 121 6 7 (current 3)
2026-11-23T03:56:45.162Z 20261123T035644Z-71022 engine record 34791BF3: 1271 1442 (current 1271)
2026-11-23T03:56:45.163Z 20261123T035644Z-71022 engine order 37D8832A: none; no recorded list is exactly its live desktops
2026-11-23T03:56:45.170Z 20261123T035644Z-71022 engine refused the order of screen 37D8832A's spaces could not be read: ...
2026-11-23T03:56:54Z 20261123T035644Z-71022 cli answer refused after 10 s; hs exited 0
2026-11-23T03:56:54Z 20261123T035644Z-71022 cli end exit 2 in 10 s
```

## What the records hold

### The CLI's side (`source` cli)

| Event     | Holds                                                                                                                                     |
| --------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `start`   | arngz's VERSION, the tree that ran (UTILZ_HOME), the verb and its arguments, and the caller (`menuz` when MENUZ_LOG is set, else `shell`) |
| `request` | the request file, the verb asked, the desk file                                                                                           |
| `hs`      | hs's path and pid, its `-t`, the CLI's deadline, and for a scheduled verb how long the CLI waits after hs says it took it                 |
| `answer`  | how long until the response came, hs's exit code, and the response's status and kind                                                      |
| `kill`    | that the CLI stopped hs, and why: the response landed while hs ran, or the deadline passed                                                |
| `refused` | a refusal's words and its fix, whether before the engine was asked or after it answered                                                   |
| `end`     | the exit code and the seconds the run took                                                                                                |

`start` comes first and `end` last, from an EXIT trap held on a global (the bash 5 trap loses locals), so a refusal's `exit 2` is logged too.

### The engine's side (`source` engine)

- **`start`**: the verb, the desk's name, the options (no_create, no_launch, the map, how many own sizes), Hammerspoon's and macOS's versions, and the Accessibility grant.
- **Displays, at the run's start and again at its end:**
  - `screen` per display: UUID, name, size, position, primary or not, and the desktop it shows.
  - `live`: its desktops as they are live, in live order, each as `id` with its type when it is not a user desktop.
  - `filed`: which of those desktops com.apple.spaces files under another display, naming that display and whether it is attached. These are the visitors.
  - `record`: com.apple.spaces' list for every Monitors entry, in its order, with its current desktop, and `collapsed` for an entry that has only a Collapsed Space.
  - `order`: the order taken for the display, or none and why.
  - `windows`: per desktop, the windows arngz can name (app, window id, frame, title cut to 40 characters), and how many it cannot name and why.
  - The time since the last display change, from the watcher below, or "none seen since the watcher started at <time>".
- **`plan`**: each op with its reason, in diff's own words (`P.plan_report`), and the counts by kind.
- **`phase`**: each phase of apply as it starts, with how long the last one took. A `wait` record says what a wait is for and how long it may take, and when it ended, why: done or timed out.
- **Each op** (`op`): its start and end, its result (status and reason, as the report has them) and its time.
  - A move: each `step` of the gesture (D21): the key pressed, the hold, the release, and what it read back: the desktop the window is on, its frame, and whether it is still shown.
  - A place: the frame asked for and the frame read back.
  - A launch: how long until the app had a window that plan could claim.
- **`created`**, for every desktop arngz creates: the display, its user desktops before and after, the new desktop's id (the live lists before and after, compared), and how long until com.apple.spaces recorded it, or that it never did.
- **`report`**: the report lines the CLI prints, the exit code, the totals (placed, failed, unseen, skipped), and the run's duration.
- **`error`**: a refusal's words and fix, a Lua error and its message, an observe that failed, a log or toast-hook failure.
- **`point`**: each progress point as it is emitted (see `progress.md`), so the log shows what the toasts were told.

### The display watcher (`source` displays)

The time since the last display change needs something that sees the change when it happens. arngz runs only when it is asked, so it is not there for the change itself.

- The engine's first call in a Hammerspoon session starts an `hs.screen.watcher`, held in a global (`arngz_screens`), as the engine already holds `arngz_running`. The global is keyed on the engine module's path, so a call from another tree, eg after `utilz use dev`, replaces it.
- Each display change appends a `change` record: the screens now, attached and detached.
- It then appends a `snapshot` of every display's desktops, live and recorded, as above: at once, then 5, 30 and 120 s later. That shows whether, and when, the visiting desktops go home (cc's points 3 and 4).
- A Hammerspoon reload drops the watcher, and the next arngz call starts it again. The log records when the watcher started, so a change it missed reads as unseen and is never guessed.
- Cost: four snapshots per display change, each one `defaults export` and the spaces reads, about a tenth of a second. It writes to the log and nowhere else.
- Guarded: the watcher's callback and each snapshot timer run inside a pcall, and a failure goes to the log as an `error` record, never into Hammerspoon's console alone. The snapshot timers are held in the watcher's global, beside the watcher, so none is collected before it fires, and a replaced watcher stops its timers with it.
- hv's way back: after `utilz use brew`, a reload of Hammerspoon's config drops the dev engine's watcher, which 2.14.10's engine does not know about. That step is in hv's steps in design.md.

**This is the one part of this design that runs outside an arngz run. It is put to vc and hv as such.**

## Size

The CLI caps the log at `ARNGZ_LOG_MAX` bytes. That is the one setting, and its default is 4 MiB.

- At a run's start, a log at or over the cap is moved to `arngz.log.1`, replacing the older one. So there are never more than two files, about 8 MiB in all.
- An apply writes roughly 15 to 30 KB, so the two files hold some hundreds of runs.
- Only the CLI rotates, and only before its run writes. The engine and the watcher append to the path, so a run still in flight carries on in the new file.

## Writing

- Every record is appended in one write: open for append, write the line, close. The CLI and the engine do the same, so two writers never split a line, and no handle outlives a rotation.
- The engine's formatters are pure functions in `log.lua`: they take a world, an op or a result, and return lines. They are tested without Hammerspoon. One impure function appends.

## Errors

A log that cannot be written never changes a run's outcome, and the failure is never dropped (IN-AG-NO-SILENT-001).

- The engine counts its failed writes and returns the first in the response, as `log_error`.
- The CLI prints `arngz: warning: the run log could not be written: <why>` on stderr, once per run, and only then.
- The toast hook's failures take the same path, as `toast_error`.

## `arngz log`

- It prints the last run: from the last CLI `start` record to the end of the file, that run's records and the watcher's records between them. When that `start` is in `arngz.log.1`, it reads that file first.
- It exits 0, or 1 when no run is logged, saying where it looked.
- It needs no engine and skips the read of Hammerspoon's entry, as `current` does. It runs on any platform, so it joins `ARNGZ_CATALOGUE_VERBS`, the list main()'s platform gate tests.
- It writes nothing to the log.
- Adding it to `ARNGZ_VERBS` makes `log` a name no desk may take (`desk_name_refusal`). No desk in hv's catalogue has that name.

## Folded in (vc's order)

- **The five yq captures** at `opt/arngz/arngz:862`, `1680`, `1710`, `1855` and `2036` take yq's stderr into the parsed value (`2>&1`). Each reads stdout alone, with stderr to a file whose words a failure names, as `own_sizes_into` does. The captures at 286, 310, 1581 and 1819 keep `2>&1`, because what they capture is an error message.
- **The 600 s cap.** arngz.bats's scheduled arms that set no `ARNGZ_APPLY_TIMEOUT` wait out the 600 s default when a writer fails. The file sets one cap for every arm, in one place. The arms that set their own value keep it.

## Files

- `opt/arngz/arngz`: the CLI's records and the EXIT trap, the run id, the cap and the rotation, the `log` verb, the request's `run` and `log` fields, and the five captures.
- `opt/arngz/lib/log.lua` (new): the formatters and the one append.
- `opt/arngz/lib/arngz.lua`: the engine's records at each site, the progress points' emitter and the toast hook, and the watcher.
- `opt/arngz/test/arngz.bats`: the CLI's arms, and the cap.
- `opt/arngz/test/engine_test.lua` and `engine.bats`: the formatters' and the points' arms, on ST0033's injected-hs driver.
- `help/arngz.md`: the `log` verb and "The run log".
- `CHANGELOG.md`.

## Acceptance (proposed; recorded with `intent ac` after vc's read)

1. An engine run appends its CLI and engine records, every one carrying the run's id, from `start` to `end`. A refusal before the engine appends `start`, `refused` and `end`.
2. The displays records name, for each display, its live desktops in order, com.apple.spaces' lists, and each visiting desktop with the display it is filed under. They are written at the run's start and end.
3. Every desktop arngz creates is recorded with its id, and with how long until com.apple.spaces recorded it.
4. A run prints the same stdout and stderr as before this change, except the warning when the log cannot be written.
5. At the cap the log moves to `arngz.log.1`, and never more than the two files exist.
6. `arngz log` prints the last run and no other run's records.
7. A log that cannot be written leaves the run's exit unchanged and prints the one warning.
8. The watcher records a display change and its four snapshots, and a run's start record gives the time since that change. A failure in the watcher's callback or one of its timers is written as an `error` record.
9. The progress points are emitted in `progress.md`'s order, and `finished` comes even after a phase's Lua error.
10. The five captures read stdout alone, and arngz.bats' scheduled arms are capped in one place.

## Proof

- One booked run at the Desk, through devbin-vc, after vc reads its bytes: arngz.bats and engine.bats, once.
- dc runs nothing live. hv's diagnosis run on the dev tree is the live proof, and its log is 93ea7f8a's input.

## Not in this WP

- The toasts are eae7633d.
- The order rule and the creates are 93ea7f8a.
- F3 (arngz kills hs, which can leave a stale ipc port) and F4 (discover running past the 60 s deadline) are in 93ea7f8a's scope, as hv decision 10 has them. This WP's log records both, from the CLI's side.

## Acceptance

Acceptance Criteria for this work package are RENDERED into `ST589246c/acceptance.md`, under the `WP-53ef` heading. THAT FILE IS A GENERATED VIEW -- a row authored there is discarded by the next sync. The contract is canon in the thread's model, and the verbs write it: `intent ac new` and `intent at new` mint a row, `intent ac edit` and `intent at edit` reword or re-cite one, and `intent ac satisfy|unsatisfy|descope|rescope|withdraw|reinstate` and `intent at green|red|na` move its state. This cover never restates them.

---

_Generated by Intent v3 from the thread canon. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
