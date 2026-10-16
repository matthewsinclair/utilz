# ST0027: menuz design

**Status: a write-up for the rubber-duck session with hv. Every "recommended" below is vc's recommendation and not a ruling; the session turns each into a numbered decision (D-n) or a descoping, and WP-01 is done when none is left.**

## The ask

hv, 16 Oct 2026, verbatim essentials: a very simple macOS (Swift) menu bar app, entirely customisable from a yaml file that points to a `.menuz` config directory in the appropriate location for that kind of directory. The yaml defines what goes into the menu; each item does something, eg runs a script. If the script takes params, the menu bar pops up a window and acquires them before running the script and passing them in. If there is output, it is given back to the user after the script runs; hv's simplest option is a known `menuz.log` in an obvious location so it can be tailed. The app reads its entire menu from the config files and is aware of changes so the menu updates. The menu supports variable interpolation, realised each time the menu is displayed. The main use case: hv runs a list of common utilities by selecting them from the menu bar, and the first is `arngz`.

Two instructions from hv on the bounce govern the whole design:

1. Three working menu bar apps exist in `../Intent`, `../Conflab` and `../Gtools`. "We DO NOT need to reinvent the wheel here. We already know how to do this."
2. "Don't reinvent or rebuild something (eg interpolation of the menu bar commands, etc) if there's an accepted pre-existing way to do that. Always default to reusing existing infra on macOS or in the standard unix utils."

## What the three siblings share, and what menuz takes from each

Read on 16 Oct 2026: `Intent/native/macos/Intent`, `Conflab/native/macos/Conflab`, `Gtools/native/macos/Gtools`, their `project.yml`, `Info.plist`, `<Name>App.swift`, and the verbs that build and install them (`Gtools/bin/gtools_app`, `Intent/bin/.devbin/cmd/macos` app half).

| Concern                   | The siblings                                                                                                                                                                                                    | menuz                                                                                                    |
| ------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| Project                   | `project.yml` for xcodegen, the `.xcodeproj` tracked; Swift 6, macOS 14 deployment target, Xcode 16 defaults baked in; `<Name>/` sources, `<Name>Tests/` a unit-test bundle hosted by the app                   | The same, at `opt/menuz/app/` (Q6)                                                                       |
| Entry point               | `@main @MainActor final class AppDelegate: NSObject, NSApplicationDelegate`, `NSApplication.shared.run()`, `LSUIElement` true in Info.plist, an `NSStatusItem` with a template image, never a zero-width item   | The same; the glyph is an SF Symbol named in the yaml (Q8)                                               |
| Standard menus            | An Edit menu so Cmd-C/V/X/A work in text fields of an `LSUIElement` app                                                                                                                                         | The same                                                                                                 |
| Login shell               | Gtools `LoginShell.swift`: `/bin/zsh -ilc` once per launch captures `PATH` and where the CLI is; every child gets that `PATH`; stderr to nowhere                                                                 | The same code, cut to `PATH` and `menuz`'s own needs                                                     |
| Launch at login           | `SMAppService.mainApp.register()` on first run, logged and never silent when it fails; off in System Settings                                                                                                   | The same                                                                                                 |
| Test host                 | Gtools `isTestHost`: when XCTest hosts the app the delegate runs none of its launch path, so a test run leaves the menu bar as it found it                                                                       | The same                                                                                                 |
| Build                     | xcodegen only when `project.yml` or the set of source files changed; `xcodebuild` with derived data, products and intermediates under `~/.local/state/<tool>/build/macos/`; version, build, commit and tree hash passed as build settings and substituted into Info.plist; `--unsigned` for CI | The same, ported from Intent's bash helpers (`app_stamps`, `app_generate_if_stale`, `app_require_xcode`) |
| Signing                   | Gtools: Apple Development, automatic, team 76BQL8L47U, built where it runs, no notarisation. Intent: Developer ID and notarised, shipped as a release asset                                                      | Gtools' model (Q7)                                                                                       |
| Install and launch        | Gtools: build Release, quit every running copy, `ditto` into `~/Applications/<Name>.app`, `lsregister -u` the build products so they cannot claim anything, `lsregister -f` the installed bundle, then `open -a` with an EMPTY environment, because `open` lays its caller's environment over launchd's and the caller's wins (measured on macOS 27, 22 Sep 2026, gtools#0053) | The same                                                                                                 |
| YAML                      | Conflab: Yams 6.0.1 as an xcodegen package, Codable models                                                                                                                                                      | Yams (Q2)                                                                                                |
| File watching             | Conflab: `DispatchSource.makeFileSystemObjectSource` on an `O_EVTONLY` descriptor, `[.write, .delete, .rename]`, on the main queue                                                                               | The same, on the config directory and the file                                                           |
| Running a command         | Gtools `GtoolsCLI`: one shell-out path, `Process` with the login `PATH`, stdout and stderr captured or streamed line by line, a non-zero exit named with the command                                             | The same, as the runner                                                                                  |
| Dialogs and notifications | Conflab `ScriptExecutor`: `NSAppleScript` with a timeout, error -1743 mapped to "grant Automation"                                                                                                               | The standard dialogs and `display notification` through the same route (Q4, Q5)                          |
| Logging                   | OSLog with a subsystem per app; Gtools' `url.log` under `~/.local/state/gtools/`                                                                                                                                | OSLog for the app's own events; `menuz.log` for runs, under XDG state (Q5)                               |
| Icons                     | Intent: an SVG rasterised by `rsvg-convert` into a tracked asset catalogue; Gtools: the same from the product glyph                                                                                              | None in v1: an SF Symbol (Q8)                                                                            |

What menuz has that none of them has: a menu that is a file, and parameters acquired before a run. What they have that menuz does not need: a daemon, a URL scheme, a settings window, a console window, a web face.

## The shape

Two halves, as arngz: a bash shim in the Utilz format (`opt/menuz/menuz`, dispatched by `bin/menuz -> utilz`) and the app (`opt/menuz/app/`, `Menuz.app` once installed). The shim builds, installs and drives the app and manages the config directory; the app shows the menu and runs the items. Nothing is computed twice: the yaml is parsed in one place (the app), and the shim's `validate` and `render` ask the app's command-line arms rather than parsing anything themselves.

```
~/.config/menuz/menuz.yaml  --read, watched-->  Menuz.app  --zsh -ilc-->  the item's command
          ^                                        |                         |
          | utilz menuz init|edit|validate|render   | menuWillOpen: realise   | stdout+stderr
          |                                        v                         v
      utilz menuz  <--build|install|start|stop-- xcodebuild           ~/.local/state/menuz/menuz.log  <-- utilz menuz log (tail -f)
```

## The config directory

Recommended: `${MENUZ_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/menuz}` (Q1). It holds:

| Path         | What                                                                                                                                       |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `menuz.yaml` | The menu. The one file the app reads                                                                                                       |
| `bin/`       | Scripts of hv's own. First on `PATH` for every run and every realised label, so `run: backup-notes` finds `bin/backup-notes` with no path  |

`utilz menuz init` creates the directory with the example `menuz.yaml` below and an empty `bin/`, and refuses to overwrite an existing `menuz.yaml` without `--force`. The log is not here: it is state, not configuration, and a config directory is the kind of thing hv keeps in a dotfiles repository.

## The menu file

One document, `menu:` a list of entries, read top to bottom into the menu in order. Four kinds of entry and four keys at the top:

```yaml
# ~/.config/menuz/menuz.yaml
icon: terminal        # an SF Symbol name for the menu bar glyph; "terminal" when absent
cwd: ~                # where runs start unless an item says otherwise; $HOME when absent
notify: failure       # never | failure | always; what a run's end posts as a notification
realise: 5            # seconds a menu open waits for its labels at most; 5 when absent

menu:
  - header: Desks
  - each: ls "${XDG_CONFIG_HOME:-$HOME/.config}/arngz/desks" 2>/dev/null | sed 's/\.yaml$//'
    label: "$MENUZ_ITEM"
    run: arngz apply "$MENUZ_ITEM"
  - label: Discover this arrangement
    params:
      - name: desk
        prompt: Save the arrangement on screen now as
        default: today
    run: arngz discover --save "$desk" --force
  - label: Hammerspoon doctor
    run: arngz doctor
    notify: always
  - separator: true
  - submenu: Machine
    items:
      - label: "Up $(uptime | sed 's/.*up //; s/,.*//')"
      - label: Sleep the display
        run: pmset displaysleepnow
      - label: Empty the Trash
        run: osascript -e 'tell application "Finder" to empty trash'
        cwd: ~/.Trash
```

| Entry key   | Meaning                                                                                                                                                            |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `label`     | An item. With `run`, choosing it runs the command; without, it is a caption (disabled)                                                                             |
| `run`       | The shell line the login shell executes. Never parsed by menuz                                                                                                     |
| `params`    | A list of parameters acquired before the run (below)                                                                                                               |
| `cwd`       | The run's working directory, this item's over the file's                                                                                                           |
| `notify`    | This item's over the file's                                                                                                                                        |
| `each`      | A shell line whose stdout lines become one item each, realised at every menu open; `$MENUZ_ITEM` is the line, in `label`, `run` and `cwd`                          |
| `header`    | A section header (`NSMenuItem.sectionHeader`, macOS 14)                                                                                                            |
| `separator` | A separator                                                                                                                                                        |
| `submenu`   | A submenu with `items`, the same entries, nested as deep as wanted                                                                                                  |

Below the file's entries the app always adds its own tail: a separator, **Edit Menu…** (opens `menuz.yaml` with `open -t`, so the user's default text editor), **Open Log** (`open` on `menuz.log`), **Reload**, and **Quit menuz** (Cmd-Q). Reload exists for the one case the watcher misses; it is not how changes normally arrive.

### Validation

The validator refuses, naming the file, the entry (by its path, eg `menu[4].items[1]`), the key and the value:

1. An unknown key anywhere.
2. An entry that is none of the four kinds, or more than one (`label` with `header`, `each` with `submenu`).
3. `run` without `label` or `each`; `params` without `run`.
4. A param whose `name` is not `[a-z][a-z0-9_]*`, or a name the login shell already exports (measured at validation, so `path` is refused on a machine whose shell exports `path`), or two params with one name.
5. A param `type` outside `text`, `secret`, `choice`, `file`, `folder`; `choice` without `choices`.
6. `notify` outside `never`, `failure`, `always`; `realise` not a positive number; `icon` not an SF Symbol this macOS has (`NSImage(systemSymbolName:)` returns nil).
7. An empty `menu`.

A file that fails keeps the last good menu on screen and puts the refusal, named, as a disabled first item in red (and in the log and OSLog). A file that fails at launch, with no last good menu, shows the refusal and the tail alone. Nothing is ever silently dropped.

## Interpolation: the login shell's own

Recommended (Q3): menuz has no interpolation syntax. A string goes to the login shell, which expands it the way the shell expands a double-quoted string: `$VAR`, `${VAR:-default}`, `$(command)`, backticks, `\` escapes, `~` is not expanded inside quotes so `$HOME` is the spelling. Two consequences hv should know:

- A label with no `$` and no backtick is literal and never sent to the shell. A label with one is realised at every menu open (`NSMenuDelegate.menuWillOpen`), all of the menu's such labels and `each` lines in ONE `zsh -ilc` invocation, so a menu with ten dynamic labels costs one shell start, not ten.
- The realisation is asynchronous: the menu opens at once showing the last realised values (the file's text on the first open), and titles update in place when the shell answers; `each` items are inserted and removed in place. Hv sees "fresh a moment later" rather than a menu that hangs on a slow command. The wait is capped at `realise` seconds; a label past the cap keeps its last value and the cap is logged. (The alternative, synchronous realisation in `menuWillOpen`, blocks the menu for the slowest command and is the thing hv would notice.)

`run` lines are never realised by menuz at all: the shell executes them, with the item's parameters exported as variables (below), so `run: arngz apply "$desk"` is ordinary shell and quoting is the shell's. This is what keeps a parameter with a space, a quote or a `;` in it safe: menuz never splices a value into a command line.

## Parameters: the standard dialogs

Recommended (Q4): each parameter is acquired, in order, through macOS's own dialogs, from the app via `NSAppleScript` (Conflab's `ScriptExecutor` route, with its timeout and its Automation error mapping), which gives menuz the dialogs without building a form engine:

| `type`   | Dialog                                                       | Value exported                       |
| -------- | ------------------------------------------------------------ | ------------------------------------ |
| `text`   | `display dialog <prompt> default answer <default>`           | The text                             |
| `secret` | `display dialog ... default answer "" with hidden answer`    | The text; never written to the log   |
| `choice` | `choose from list <choices> with prompt <prompt>`            | The chosen line                      |
| `file`   | `choose file with prompt <prompt>`                           | The POSIX path                       |
| `folder` | `choose folder with prompt <prompt>`                         | The POSIX path                       |

`choices` is a list, or a shell line (`choices: $(ls ~/Desks)`) realised when the dialog opens. Cancel on any dialog runs nothing and logs `cancelled`. A `required: true` param refuses an empty answer and asks again; otherwise an empty answer is an empty variable. The values reach the run as exported variables under the declared names (`$desk`), which is why names are lower-case and refused when the login shell already exports them (validation rule 4).

The alternative, one `NSAlert` with an accessory form holding every parameter at once (a SwiftUI form in an `NSPanel`, Gtools' settings hosting), is more to build and more to test, and it is what hv's words "pops up a window" could also mean. One dialog per parameter is the standard thing that exists; most items will have one parameter.

## Running an item

The runner is Gtools' `GtoolsCLI` shape, one shell-out path:

1. `/bin/zsh -ilc "$run"`, so aliases and `PATH` additions from `.zshrc` count, as a terminal would have them (Gtools measured `-ilc` as the invocation that finds what a terminal finds).
2. Environment: launchd's, as the app has it, with `PATH` set to the login shell's capture plus `$MENUZ_HOME/bin` first; `MENUZ_HOME`, `MENUZ_LABEL`, `MENUZ_RUN_ID` and, under `each`, `MENUZ_ITEM`; the item's params by name.
3. Working directory: the item's `cwd`, else the file's, else `$HOME`.
4. stdin is `/dev/null`. A run never has a terminal and never waits for one.
5. Runs are concurrent and independent, each with a run id; nothing is queued and nothing is refused for being busy. Quit terminates runs still in flight and logs each as `terminated` (Q9).

## Output: the log and the notice

Recommended (Q5): hv's simplest option, taken whole. Every run appends to `${XDG_STATE_HOME:-$HOME/.local/state}/menuz/menuz.log`, created on first use:

```
2026-10-16T10:42:03Z run 17 start "Hammerspoon doctor" cwd=/Users/matts: arngz doctor
[17] hammerspoon  running (pid 4123)
[17] hs tool      /opt/homebrew/bin/hs
[17] ...
2026-10-16T10:42:04Z run 17 exit 0 in 1.3s
```

stdout and stderr lines carry the run id so concurrent runs interleave legibly; the start line prints `run` as written, which is what keeps a `secret` out of the log (the shell expands `$token`, the log never sees the value). `utilz menuz log` is `tail -f` on that file and prints its path first; **Open Log** in the menu opens it in the default app for `.log`. A log line the app cannot write (the directory unwritable, the disk full) is an error in the app's OSLog and a notification, never a swallowed write.

The notice: a run that exits non-zero posts a macOS notification naming the item and the exit code, through `display notification` by the same `NSAppleScript` route, so the failure is not silent for a user who is not tailing; `notify: always` posts one on every finish with the last line of output; `notify: never` posts none. (`UNUserNotificationCenter` is the other standard route; it needs the bundle to request permission on first run and gives nothing `display notification` does not for one line of text.)

Not in v1, for the rubber-duck to confirm: a console window tailing the log (Gtools' `ConsoleWindowController`, which exists and could be lifted), and output shown in a window per run. hv: "I have a few questions to resolve about what we do with the output." The log is the base either way.

## Watching the file

Conflab's watcher, on two descriptors: the config directory (so an editor's atomic save, which renames a new file into place, and a `git checkout` of the dotfiles both register) and `menuz.yaml` itself. Events are coalesced over 250 ms and then the file is re-read and re-validated; the descriptor on the file is reopened after a rename. A change lands in the menu within a second, measured by hand (AC-03.3). The directory's absence at launch is reported in the menu and the watcher retries every 5 s until `init` creates it.

## The app's command-line arms

`Menuz.app/Contents/MacOS/Menuz --validate [file]`, `--render [file]` and `--version` run without touching the menu bar and exit: `--validate` prints `ok` or every refusal (exit 0 or 2); `--render` prints the menu as the app would show it, labels realised through the shell, indented text, one entry per line (so a test and a human can see what a file becomes). The shim's `validate` and `render` verbs call the installed app's binary, else the Debug build product, else refuse by name. One parser, in the app; the shim parses nothing.

## The shim: `utilz menuz`

| Verb        | Does                                                                                                                                     | Exit                                      |
| ----------- | ---------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------- |
| `init`      | Create `MENUZ_HOME` with the example `menuz.yaml` and `bin/`; `--force` overwrites the yaml                                              | 0; 2 if the yaml exists and no `--force`  |
| `edit`      | `open -t menuz.yaml`, or `$VISUAL`/`$EDITOR` when `--editor` is given                                                                    | 0; 2 if no yaml                           |
| `log`       | Print the log's path, then `tail -f` it; `-n N` for the last N lines and no follow                                                       | 0; 2 if no log yet                        |
| `validate`  | The app's `--validate` on `menuz.yaml` or a given file                                                                                   | 0 or 2, the app's; 2 if no app            |
| `render`    | The app's `--render`                                                                                                                     | the same                                  |
| `build`     | xcodegen when stale, then `xcodebuild` Debug, `--release` for Release, `--unsigned` for a machine with no identity                       | 0; 1 on a failed build; 2 without Xcode   |
| `test`      | `xcodebuild test`, the `MenuzTests` target                                                                                               | 0; 1 on a red test; 2 without Xcode       |
| `install`   | Build Release, quit every running copy, replace `~/Applications/Menuz.app`, unclaim the build products, `lsregister`, launch              | 0; 1 if it stopped after changing something, which it names; 2 without Xcode or without the source tree |
| `uninstall` | Quit every copy, remove the bundle                                                                                                       | 0                                         |
| `start` `stop` `restart` | `open -a` with an empty environment; quit by `osascript` (JXA) by bundle id                                                   | 0; 2 if not installed                     |
| `status`    | installed (version, build, commit), running (pid), login item (on/off), source-current (the tree hash against the installed bundle's)     | 0, 1 if not installed                     |
| `stamps`    | What the next build would stamp into Info.plist                                                                                          | 0                                         |
| `doctor`    | Every precondition with its state: Xcode selected, xcodegen, the identity, `MENUZ_HOME`, the yaml valid, the app installed and running   | 0; 1 when any fails                       |

Exit codes follow arngz: 0 done, 1 failed, 2 refused before anything changed. `menuz` with no verb prints usage. The shim is bash 3.2-clean under `set -euo pipefail` and shellcheck-clean, as every Utilz shim.

The brew keg (an install of Utilz that ships built binaries and no source) has no `opt/menuz/app` to build: `build`, `test` and `install` refuse there by name, as prez's shim refuses to `cargo build` in an install (ST0014 D5), and name the source clone. Shipping a built `Menuz.app` with the keg needs Intent's Developer ID and notarisation pipeline and is not v1 (Q7).

## Build layout

| Path                                                   | What                                                                                                |
| ------------------------------------------------------ | --------------------------------------------------------------------------------------------------- |
| `opt/menuz/menuz`                                      | The shim                                                                                            |
| `opt/menuz/menuz.yaml`                                 | The utility's declaration: `version_file: VERSION`, `dependencies: []` (xcodegen and xcodebuild are build-time, refused by name as cargo is; doctor reports them only when `opt/menuz/app` is present, the crate rule in common.sh extended by one path) |
| `opt/menuz/VERSION`                                    | The one home of the version; the shim passes it to xcodebuild as `MENUZ_VERSION`, Info.plist substitutes it |
| `opt/menuz/app/project.yml`                            | The xcodegen spec: Gtools' cut, `bundleIdPrefix: com.matthewsinclair.utilz`, product `Menuz`, package Yams |
| `opt/menuz/app/Menuz/`                                 | `MenuzApp.swift` (the delegate), `Models/` (the menu file, Codable; the validator; the log line), `Services/` (`LoginShell`, `Runner`, `Realiser`, `Dialogs`, `Watcher`, `Log`), `Views/` (none in v1) |
| `opt/menuz/app/MenuzTests/`                            | Swift Testing over the pure parts                                                                   |
| `opt/menuz/test/menuz.bats`                            | The shim under bats with a fake `Menuz` binary and a fake `xcodebuild` on PATH                      |
| `opt/menuz/README.md`, `help/menuz.md`                 | The utility's docs                                                                                  |
| `${XDG_STATE_HOME:-$HOME/.local/state}/utilz/menuz/build/` | Derived data, products, intermediates: off the tree, as the siblings keep theirs                 |
| `~/Applications/Menuz.app`                             | The installed app                                                                                   |

The app's sources are reviewed by `critic-swift` (`intent lang init swift` in WP-03, the six Swift rules in the library: guard over nested if, optionals over sentinels, structured concurrency over GCD, Codable over manual JSON, narrowest access first, specific XCTAssertEqual values).

## Tests

- **Shim (Linux and macOS legs):** `opt/menuz/test/menuz.bats` with a fixture `HOME`, a fake `Menuz` binary on PATH that records its arguments and prints a scripted answer, and a fake `xcodebuild`/`xcodegen`; every verb's refusal by name; `init` idempotent; `log -n`; the install refusal with no source tree. This is where AC-02.x and the shim half of AC-05.1 live.
- **App (macOS leg, on a tag or on dispatch, as Gtools runs its):** `MenuzTests`, Swift Testing, over the pure parts: the file decoded into the model, every validation rule red on its fixture and the example green, the realiser's split of literal from dynamic labels and its reassembly of the shell's answer, the `each` expansion, the runner's environment and argv assembly, the log line format, the test-host guard. No test opens a menu or a dialog.
- **Hand runs on hv's machine, recorded in acceptance.md:** the watcher's latency, a change arriving with no restart; the arngz entries applying a desk; a parameter acquired through each dialog type; launch at login after a logout. vc runs these with hv's hands off, as ST0026's.

## CI

A `menuz-app` job on `macos-15`, `if: github.ref_type == 'tag' || github.event_name == 'workflow_dispatch'` (Gtools' gate, so every push is not an Xcode build), `brew install xcodegen`, `bin/utilz menuz build --unsigned`, `bin/utilz menuz test --unsigned`. The Linux legs run `menuz.bats` in the explicit utility loop.

## Questions for the rubber-duck, each with vc's recommendation

| Q   | Question                                                                 | Recommended                                                                                                                                      | Alternative                                                                                   |
| --- | ------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------- |
| Q1  | Where is the config directory?                                           | `${XDG_CONFIG_HOME:-$HOME/.config}/menuz/`, `MENUZ_HOME` overriding; arngz's and todo's convention                                               | `~/.menuz/` with `~/.menuz.yaml` pointing at it, hv's literal words                           |
| Q2  | Who parses the yaml?                                                     | Yams in the app (Conflab's package), Codable models, one parser                                                                                  | `yq -o json` into `JSONDecoder`: no package, but the app then needs `yq` on PATH to show anything |
| Q3  | What does "variable interpolation" mean?                                 | The login shell's own expansion of labels and `each` lines, one `zsh -ilc` per menu open, asynchronous with the last values shown first, capped  | A menuz syntax (`{{var}}`) resolved by the app: a second expander beside the shell's, which hv ruled out |
| Q4  | How are params acquired?                                                 | macOS's standard dialogs, one per param, via `NSAppleScript`                                                                                     | One `NSAlert`/SwiftUI form with every param: a form engine to build and test                  |
| Q5  | What happens to output?                                                  | `menuz.log` under XDG state, `utilz menuz log` tails it, a notification on a non-zero exit, `notify:` per item                                   | Plus a console window (Gtools' exists); or a result window per run                            |
| Q6  | Where does the app live in the tree?                                     | `opt/menuz/app/`, where prez keeps its crate                                                                                                     | `native/macos/Menuz/`, the siblings' path                                                     |
| Q7  | Signing and distribution                                                 | Gtools' model: Apple Development automatic, team 76BQL8L47U, built where it runs by `install`; the keg refuses `install` by name                  | Intent's: Developer ID, notarised, shipped as a release asset the keg installs                 |
| Q8  | The menu bar glyph                                                       | An SF Symbol named in the yaml, `terminal` by default; no asset pipeline, no App icon beyond the generic one                                     | An SVG rasterised by `rsvg-convert` into a tracked catalogue, Intent's `app-icons`            |
| Q9  | Runs in flight at Quit                                                   | Terminated and logged as such; runs are children of the app                                                                                      | Left running (`nohup`); a run that must outlive the app says so in its own line               |
| Q10 | `each` in v1?                                                            | Yes: one item per desk is the arngz use case, and it is one shell line and one loop                                                              | Later; v1 lists desks by hand in the yaml                                                     |
| Q11 | The app's name and bundle id                                             | `Menuz.app`, `com.matthewsinclair.utilz.menuz`                                                                                                   | hv's choice                                                                                   |

## Decisions

None yet. The rubber-duck session writes D1 onwards here, one per question above, in hv's words where hv gave them.

## Work packages

| WP    | Title                                                        | Builds                                                                                                                                       |
| ----- | ------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------- |
| WP-01 | Design settled with hv                                       | The rubber-duck; every Q above a decision; the example yaml final; swift declared                                                            |
| WP-02 | The shim, the config directory and the catalogue verbs       | `bin/menuz`, `opt/menuz/menuz` with `init`, `edit`, `log`, `validate`, `render`, `status`, `doctor`; bats with the fake app                  |
| WP-03 | The app: the menu from the file, watched, realised at open   | The xcodegen project, the model and validator, the menu, the watcher, the realiser, the command-line arms; `MenuzTests`                       |
| WP-04 | Running items: params, the runner, the log and the notice    | The dialogs, the runner, `menuz.log`, notifications; the arngz hand run                                                                      |
| WP-05 | Build, install, launch and the close                         | `build`, `test`, `install`, `uninstall`, `start`, `stop`, `restart`, `stamps`; login item; CI; help, README, CHANGELOG; the estate green      |

Each WP is sized S, as ST0026's, and WP-02 can start before WP-03 because the shim's verbs that need the app are tested against a fake.

## Acceptance criteria, to be minted

**Held here only until the store takes them.** On 16 Oct 2026 Utilz's runtime store was doubling its full-text index on every write (intent-vc has the measurements), so `intent ac new` could not run; the criteria below are the contract as drafted, one row per `intent ac new` call in vc's scratch script, and this section is removed once `acceptance.md` renders them.

### WP-01

- AC-01.1 (non-test) design.md records hv's ruling on each of its questions Q1 to Q11 as a numbered decision or a descoping, in hv's words where hv gave them, and no recommendation is left standing in its place.
- AC-01.2 (non-test) The example menuz.yaml in design.md is final and is the one menuz init writes; swift is a declared language of the project (intent lang init swift) and critic-swift is the review for opt/menuz/app.
### WP-02

- AC-02.1 utilz menuz is dispatched by bin/utilz; opt/menuz/menuz.yaml declares the utility with opt/menuz/VERSION as the one home of its version; utilz list shows menuz; utilz doctor reports xcodegen and xcodebuild only when opt/menuz/app is present, as it reports cargo only when a crate is.
- AC-02.2 init creates MENUZ_HOME (default \${XDG_CONFIG_HOME:-\$HOME/.config}/menuz) with the example menuz.yaml and an empty bin/, refuses to overwrite an existing menuz.yaml without --force (exit 2, naming the file), and a second run changes nothing; edit opens the yaml with open -t, or \$VISUAL/\$EDITOR under --editor; log prints the log's path then tails it, -n N prints the last N lines; each refuses by name, exit 2, when its file is missing.
- AC-02.3 validate and render run the app's --validate and --render arms on menuz.yaml or a given file and pass their output and exit code through, proven with a fake Menuz binary on PATH; with no app built or installed they refuse by name, exit 2; status reports installed, running, login item and source-current without Xcode present.
### WP-03

- AC-03.1 The app is an xcodegen project at opt/menuz/app in the siblings' shape (Swift 6, macOS 14, LSUIElement, Apple Development automatic signing, the test-host guard) with Yams as its one package; --validate and --render run without a menu bar and exit 0 or 2 with every finding named, and --version prints the stamped version.
- AC-03.2 The menu is exactly the file, in order: items, captions, headers, separators, submenus, then the fixed tail (Edit Menu, Open Log, Reload, Quit menuz); every validation rule in the design refuses its fixture naming file, entry path, key and value, and the example passes; a file that fails keeps the last good menu and shows the refusal as a disabled first item and in the log.
- AC-03.3 Hand run on hv's machine, recorded as such: a save of menuz.yaml, an atomic rename by an editor, and a deletion and recreation of MENUZ_HOME each reach the menu within one second with no restart.
- AC-03.4 Labels and each lines with a \$ or a backtick are realised by the login shell at every menu open in one zsh -ilc invocation, asynchronously, the last values shown first and titles updated in place, under the realise cap with the previous value kept and the overrun logged; a label with neither is never sent to the shell; each expands to one item per stdout line with MENUZ_ITEM set.
### WP-04

- AC-04.1 An item's params are acquired in order through the standard dialogs (display dialog with default answer, hidden answer for secret, choose from list, choose file, choose folder), each with its prompt and default; Cancel on any dialog runs nothing and logs cancelled; required refuses an empty answer; the values reach the run as exported variables under the declared names.
- AC-04.2 Each run is /bin/zsh -ilc of the run line, with the login shell's PATH and MENUZ_HOME/bin first on it, cwd the item's, else the file's, else HOME, stdin /dev/null, and MENUZ_HOME, MENUZ_LABEL, MENUZ_RUN_ID and (under each) MENUZ_ITEM exported; runs are concurrent, each with its own id, and Quit terminates those in flight and logs each as terminated.
- AC-04.3 Every run appends to \${XDG_STATE_HOME:-\$HOME/.local/state}/menuz/menuz.log, created on first use: a start line (timestamp, run id, item, cwd, the run line as written), stdout and stderr lines as they come prefixed with the run id, and an end line with exit code and duration; a secret's value never appears; a line the app cannot write is an error in OSLog and a notification.
- AC-04.4 A run that exits non-zero posts a notification naming the item and the exit code; notify: always posts one on every finish carrying the last output line; notify: never posts none; the item's notify overrides the file's.
- AC-04.5 Hand run on hv's machine, recorded as such: the example menu applies an arngz desk chosen from the each-generated items, and discover saves one through a text dialog, with both runs in the log.
### WP-05

- AC-05.1 build runs xcodegen only when project.yml or the set of sources changed and xcodebuild Debug or --release with products under \${XDG_STATE_HOME:-\$HOME/.local/state}/utilz/menuz/build; test runs the MenuzTests target; install builds Release, quits every running copy, replaces ~/Applications/Menuz.app, unclaims the build products, registers the bundle and launches it with an empty environment; uninstall, start, stop, restart and stamps as designed; each refuses by name, exit 2, without xcodegen or xcodebuild, and install refuses when opt/menuz/app is absent.
- AC-05.2 Hand run on hv's machine, recorded as such: the app registers itself as a login item on its first run, status reports it, and the menu is back after a logout and login.
- AC-05.3 (non-test) CI: a macOS job on a tag or on dispatch builds the app unsigned and runs MenuzTests; the Linux legs run menuz.bats with the fake app in the explicit utility loop; both green on the closing SHA.
- AC-05.4 (non-test) help/menuz.md, the README's menuz section and the CHANGELOG entry exist and name every verb and flag the CLI accepts, checked against menuz --help; bin/devbin check all and the estate suite are green; the hand-run transcript in acceptance.md names the machine, the macOS build and the Xcode version.
