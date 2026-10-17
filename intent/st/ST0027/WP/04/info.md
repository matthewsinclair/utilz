---
wp_id: WP-04
title: Running items: params, the runner, the log and the notice
scope: S
status: Done
---

# WP-04: Running items: params, the runner, the log and the notice

## Objective

Running an item: the one typed form for its params (D4), the run, detached and logged by its own wrapper (D9), and the notice at its end (D5). WP-03's menu, validator, realiser and log stay as they are; WP-05 is build, install and `use`. This note settles what design.md leaves open for WP-04. design.md's "Parameters: one typed form", "Running an item" and "Output: the log and the notice" are the contract, with D4, D5, D9 and D10.

**Layout: the pure parts in MenuzKit, the impure in the app.** As in WP-03, whatever can be decided without AppKit, a process or the file system is a function in MenuzKit, tested by `swift test`.

| Where                      | What                                                                                                                                                       |
| -------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `MenuzKit/Form.swift`      | The form's model: a field per param in the file's order, its kind, label and starting value; the check of the answers; the values a submitted form exports |
| `MenuzKit/Run.swift`       | A run decided before it starts: its environment, the wrapper script, the notify setting, and the app's log lines (start, cancelled, quit)                  |
| `MenuzKit/RunId.swift`     | The next-id store's arithmetic: the id read, the next written                                                                                              |
| `Menuz/Services/ParamForm` | The SwiftUI form in an `NSPanel` (Gtools' settings hosting)                                                                                                |
| `Menuz/Services/Runner`    | The id taken under a lock, the start line, the spawn, the process source per run, the quit line                                                            |

**The form (AC-04.1).**

- One SwiftUI `Form` in an `NSPanel` per run, titled with the item's label as shown. The app activates so the panel takes key. Every param is a field in the file's order, with Run and Cancel at the foot (D4). Return is Run, Escape is Cancel, and closing the panel is Cancel. An item with no params runs at once, with no form.
- Fields by `type`:
  - `text`: a text field, labelled with `prompt` (the param's `name` when there is none), `default` filled in;
  - `secret`: a `SecureField`, empty;
  - `choice`: a `Picker` of the choices, the first selected;
  - `file` and `folder`: a path field, `default` filled in, and a Choose button opening `NSOpenPanel` for a file or a folder.
- `choices` given as a shell line is realised when the form opens, through the same `Realise` script and login shell as an `each`: one choice per line printed. A line that fails or prints nothing shows its failure in the field, and Run stays disabled.
- The check runs as the user types and again at Run, and each refusal names its param in the form:
  - `required` and empty;
  - a `file` that does not exist or is a directory;
  - a `folder` that does not exist or is not a directory;
  - a `choice` not among the choices.

  Run is disabled while any refusal stands. Whether a path exists, and is a directory, is a predicate the form's model is given, so the check is pure and is tested in MenuzKit with no window.

- A param that is not `required` and left empty is exported empty.
- The validator gains two refusals, so nothing in a file is silently ignored: `default` on a `secret` ("a secret has no default", the field starts empty) and `default` on a `choice` ("a choice starts on its first choice").
- Accessibility identifiers, for vc's AC-04.5 hand run, which drives the form through the accessibility tree: each field's is the param's `name`, and the buttons' are `Run` and `Cancel`.
- Cancel runs nothing and logs `<ts> run <id> cancelled "<label>"`.

**The run (AC-04.2, D9).**

- **The id** never repeats across launches. The next id is kept in `${XDG_STATE_HOME:-$HOME/.local/state}/menuz/next-run`, read, incremented and written under an exclusive lock (`O_EXLOCK`), so a dev and an installed copy running at once never share one. A missing file starts at 1. A store that cannot be read or written refuses the run, logged in OSLog and as a notification, never a silent id.
- **The spawn.** One wrapper per run: `posix_spawn` with `POSIX_SPAWN_SETSID` (its own session, D9) and `POSIX_SPAWN_CLOEXEC_DEFAULT` (nothing of the app's held open), argv `/bin/zsh -f -c <wrapper>`. Its stdin is `/dev/null`; its stdout and stderr are the log file, opened for append by the file actions. The app writes the start line, then spawns.
- **The wrapper** is one fixed script, carrying no run line, label, cwd or value. They all reach it through the environment, as WP-03's realise script takes its strings. It:
  1. changes to the working directory: the item's `cwd`, else the file's, else `$HOME`, expanded by zsh as written (`${~${(e)MENUZ_CWD}}`, so `~`, `$HOME` and, under `each`, `$MENUZ_ITEM` work). A directory it cannot enter ends the run with exit 126 and an output line saying so;
  2. runs `/bin/zsh -ilc 'export PATH="$MENUZ_HOME/bin:$PATH"; eval "$MENUZ_RUN"'`, stdin `/dev/null`, stdout and stderr merged. `.zshrc` counts, and `bin/` is first even after `.zshrc` rewrites PATH;
  3. prefixes every output line `[<id>] ` onto its own stdout (the log), keeps the last line, and takes the run's code from `pipestatus`;
  4. writes the end line and posts the notice (below), then exits with the run's code.
- **The environment** is the login shell's capture (WP-03's `LoginShell`), with `PATH` set by `Paths.runPath`, plus `MENUZ_HOME`, `MENUZ_LABEL` (the label as shown), `MENUZ_RUN_ID`, `MENUZ_ITEM` under an `each`, `MENUZ_RUN`, `MENUZ_CWD`, `MENUZ_NOTIFY` and every param by its name. A param's value is in the environment only. The wrapper echoes no environment, so no value ever reaches the log.
- **Concurrent.** Nothing is queued and nothing is refused for being busy. The app keeps each run in flight by id, with a `DispatchSource` process source on its pid that removes it when the wrapper ends and reaps it with `waitpid`.
- **Quit** writes `<ts> quit; runs still going: <ids>` (or `none`) and kills nothing; the runs write their own end lines. Measured in vc's AC-04.5 hand run, driven through the accessibility tree with a fixture menu whose item runs `sleep 20; echo done`: the app quit during it, and the run's `[<id>] done` and end line arriving in the log after the quit line.

**The log (AC-04.3).** Exactly the design's block:

```
<ts> run <id> start "<label>" cwd=<cwd as written>: <run as written>
[<id>] <line>
<ts> run <id> exit <code> in <seconds>s
```

Each `<ts>` is ISO 8601 UTC to the second, with a `Z`, and the duration has one decimal (`1.3s`). Two more lines: `<ts> run <id> cancelled "<label>"` and the quit line. The app's lines go through WP-03's `LogLine`; the wrapper's end line is written by zsh's `strftime` under `TZ=UTC`. A test runs the wrapper and checks its end line against the format `LogLine` writes, so the two writers cannot drift. A line the app cannot write is an OSLog error, as now, and also a notification. The app's writes share the file with wrappers appending in their own sessions, so `AppLog` opens it `O_WRONLY|O_APPEND|O_CREAT` and writes each line in one `write` on that descriptor. WP-03's open, seek to the end and write could land a wrapper's bytes between the seek and the write and overwrite them.

**The notice (AC-04.4, D5).**

- The setting is the item's `notify`, else the file's, else `failure`. The app resolves it and passes it as `MENUZ_NOTIFY`.
- `failure` posts when the code is not 0, `always` posts on every end, and `never` posts nothing.
- The wrapper posts it at the end line, with `osascript -e 'display notification (system attribute "MENUZ_NOTICE") with title "menuz"'`, the text read from the environment and never spliced into the script. The text is `"<label>" exited <code>`, and under `always` also the run's last output line.
- **This is `osascript` in the wrapper, not `NSAppleScript` in the app as design.md's Output section has it.** The reason is D9: a run may outlive the app, and its notice must still come. design.md's Output section takes that one line at the close.

**Choosing an item** in the menu now runs it: the form when it has params, else the run at once. WP-03's "running items is not built yet" line goes.

**Tests.** MenuzKitTests, Swift Testing, written red first:

- the form's fields from params, every check and its wording, Run enabled only when every refusal is clear, and the exported values;
- the two new validator refusals;
- the run's environment: `MENUZ_HOME`, `MENUZ_LABEL`, `MENUZ_RUN_ID`, `MENUZ_ITEM` under an `each`, the params by name, `PATH` with `bin/` first, the notify setting;
- the wrapper text, which carries no run line, label or value;
- the app's log lines (start, cancelled, quit);
- the next-id arithmetic;
- the wrapper run through `/bin/zsh -c` with a fixture log, a fixture `MENUZ_HOME` and a fake `osascript` on PATH. It checks:
  - the prefixes on stdout and stderr lines;
  - the end line's code, duration and format against `LogLine`'s;
  - the cwd as written, with `~` and a variable, and an unenterable one;
  - the notice's text for each notify setting;
  - a secret's value present in the run and absent from the log.

MenuzTests (hosted) covers the spawn against a scratch log and state directory:

- a run whose `getsid` is not the test host's;
- its lines in the log with nothing passing through the app;
- the app's writer and a spawned appender interleaving a few hundred lines each, with none lost;
- two runs at once with distinct ids;
- the exit seen through the process source.

No test opens a form or posts a real notification. The form's window, and the arngz entries end to end, are AC-04.5's hand run, vc's.

## Acceptance

Acceptance Criteria for this work package are RENDERED into `ST0027/acceptance.md`, under the `WP-04` heading. THAT FILE IS A GENERATED VIEW -- a row authored there is discarded by the next sync. The contract is canon in the thread's model, and the verbs write it: `intent ac new` and `intent at new` mint a row, `intent ac edit` and `intent at edit` reword or re-cite one, and `intent ac satisfy|unsatisfy|descope|rescope|withdraw|reinstate` and `intent at green|red|na` move its state. This cover never restates them.

---

_Generated by Intent v3 from the thread canon. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
