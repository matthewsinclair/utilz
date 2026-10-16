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
| Project                   | `project.yml` for xcodegen, the `.xcodeproj` tracked; Swift 6, macOS 14 deployment target, Xcode 16 defaults baked in; `<Name>/` sources, `<Name>Tests/` a unit-test bundle hosted by the app                   | The same, at `native/macos/Menuz/` (D6)                                                                       |
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

Two halves, as arngz: a bash shim in the Utilz format (`opt/menuz/menuz`, dispatched by `bin/menuz -> utilz`) and the app (`native/macos/Menuz/`, the siblings' path; `~/Applications/Menuz.app` once installed, D6). The shim builds, installs and drives the app and manages the config directory; the app shows the menu and runs the items. Nothing is computed twice: the yaml is parsed in one place (the app), and the shim's `validate` and `render` ask the app's command-line arms rather than parsing anything themselves.

```
~/.config/menuz/menuz.yaml  --read, watched-->  Menuz.app  --zsh -ilc-->  the item's command
          ^                                        |                         |
          | utilz menuz init|edit|validate|render   | menuWillOpen: realise   | stdout+stderr
          |                                        v                         v
      utilz menuz  <--build|install|use|start|stop-- xcodebuild           ~/.local/state/menuz/menuz.log  <-- utilz menuz log (tail -f)
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

## Parameters: one typed form

Ruled (D4, hv: "One form with all params, typed (where possible)"): every parameter of an item is acquired through one form window (a SwiftUI form in an `NSPanel`, Gtools' settings hosting), its fields in the yaml's order, each field typed from the param's `type`; Run and Cancel at the foot:

| `type`   | Field                                                              | Value exported                       |
| -------- | ------------------------------------------------------------------ | ------------------------------------ |
| `text`   | A text field with `<prompt>` as its label and `<default>` filled in | The text                             |
| `secret` | A secure text field, empty                                         | The text; never written to the log   |
| `choice` | A popup of `choices`, the first selected                           | The chosen line                      |
| `file`   | A path field with a Choose button opening `NSOpenPanel` for a file | The POSIX path                       |
| `folder` | The same, for a folder                                             | The POSIX path                       |

`choices` is a list, or a shell line (`choices: $(ls ~/Desks)`) realised when the dialog opens. Cancel runs nothing and logs `cancelled`. A `required: true` param is refused empty in the form, by name, and Run stays disabled until every refusal is cleared; otherwise an empty answer is an empty variable. The values reach the run as exported variables under the declared names (`$desk`), which is why names are lower-case and refused when the login shell already exports them (validation rule 4).

hv ruled for the form over one dialog per parameter: the dialogs were the standard thing that exists, and the form is what "pops up a window" means once an item has more than one parameter. A `bool` is not a type in v1: a yes-or-no parameter is a `choice` of two lines. A param with no `type` is `text`, which is what the example's `name` param is.

## Running an item

The runner is Gtools' `GtoolsCLI` shape, one shell-out path:

1. `/bin/zsh -ilc "$run"`, so aliases and `PATH` additions from `.zshrc` count, as a terminal would have them (Gtools measured `-ilc` as the invocation that finds what a terminal finds).
2. Environment: launchd's, as the app has it, with `PATH` set to the login shell's capture plus `$MENUZ_HOME/bin` first; `MENUZ_HOME`, `MENUZ_LABEL`, `MENUZ_RUN_ID` and, under `each`, `MENUZ_ITEM`; the item's params by name.
3. Working directory: the item's `cwd`, else the file's, else `$HOME`.
4. stdin is `/dev/null`. A run never has a terminal and never waits for one.
5. Runs are concurrent and independent, each with a run id; nothing is queued and nothing is refused for being busy. A run is detached from the app (D9, hv: "Left running, surely?"): its own session, stdin `/dev/null`, and its stdout and stderr prefixed with the run id and appended to the log by the run's own wrapper shell, not by the app, which also writes the end line with the exit code and the duration. Quit therefore closes nothing a run writes to: runs still in flight are left running, and the log records the quit with the ids still going.

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
| `use`       | `dev` or `installed`: which build `start`, `restart`, `status`, `validate` and `render` act on, recorded in XDG state; no argument prints the current choice (D6, after devbin's own switch) | 0; 2 on any other word                    |
| `uninstall` | Quit every copy, remove the bundle                                                                                                       | 0                                         |
| `start` `stop` `restart` | `open -a` with an empty environment; quit by `osascript` (JXA) by bundle id                                                   | 0; 2 if not installed                     |
| `status`    | installed (version, build, commit), running (pid), login item (on/off), source-current (the tree hash against the installed bundle's), and which build `use` selects     | 0, 1 if not installed                     |
| `stamps`    | What the next build would stamp into Info.plist                                                                                          | 0                                         |
| `doctor`    | Every precondition with its state: Xcode selected, xcodegen, the identity, `MENUZ_HOME`, the yaml valid, the app installed and running   | 0; 1 when any fails                       |

Exit codes follow arngz: 0 done, 1 failed, 2 refused before anything changed. `menuz` with no verb prints usage. The shim is bash 3.2-clean under `set -euo pipefail` and shellcheck-clean, as every Utilz shim.

The brew keg (an install of Utilz that ships built binaries and no source) has no `native/macos/Menuz` to build: `build`, `test` and the source half of `install` refuse there by name, as prez's shim refuses to `cargo build` in an install (ST0014 D5), and name the source clone. The app a keg installs is the `Menuz.app` signed with Developer ID, notarised and attached to the release, Intent's pipeline (D7, hv: "Same as Intent. This is opensource just like Intent and it needs to be signed properly"): `install` from a keg fetches the asset of the keg's own version, verifies its signature and places it at `~/Applications/Menuz.app`.

## Build layout

| Path                                                   | What                                                                                                |
| ------------------------------------------------------ | --------------------------------------------------------------------------------------------------- |
| `opt/menuz/menuz`                                      | The shim                                                                                            |
| `opt/menuz/menuz.yaml`                                 | The utility's declaration: `version_file: VERSION`, `dependencies: []` (xcodegen and xcodebuild are build-time, refused by name as cargo is; doctor reports them only when `native/macos/Menuz` is present, the crate rule in common.sh extended by one path) |
| `opt/menuz/VERSION`                                    | The one home of the version; the shim passes it to xcodebuild as `MENUZ_VERSION`, Info.plist substitutes it |
| `native/macos/Menuz/project.yml`                       | The xcodegen spec: Gtools' cut, `bundleIdPrefix: com.matthewsinclair.utilz`, product `Menuz`, package Yams |
| `native/macos/Menuz/MenuzKit/`                         | A local Swift package the app links (WP-03): the `MenuzKit` library on Yams, everything pure and nothing of AppKit (the menu file, Codable; the validator; the menu spec and its render; the realiser's pure half; the paths; the log line), and `MenuzKitTests`, so `swift test` runs the pure parts without an Xcode build |
| `native/macos/Menuz/Menuz/`                            | `MenuzApp.swift` (the delegate and the arms), `Services/` (`LoginShell`, `Watcher`, `Realiser`, `MenuBuilder`, `AppLog`; WP-04 adds `Runner` and `ParamForm`), `Views/` (none in v1), `Info.plist`, entitlements |
| `native/macos/Menuz/MenuzTests/`                       | A unit-test bundle hosted by the app: the test-host guard and what needs AppKit; the scheme runs it with `MenuzKitTests`, so `xcodebuild test` and `utilz menuz test` cover both |
| `opt/menuz/test/menuz.bats`                            | The shim under bats with a fake `Menuz` binary and a fake `xcodebuild` on PATH                      |
| `opt/menuz/README.md`, `help/menuz.md`                 | The utility's docs                                                                                  |
| `${XDG_STATE_HOME:-$HOME/.local/state}/menuz/build/macos/` | Derived data, products (`Build/Products/<Config>/Menuz.app`), intermediates: off the tree, as Intent and Gtools keep theirs (D6) |
| `${XDG_STATE_HOME:-$HOME/.local/state}/menuz/use`     | The `use` choice, `dev` or `installed`; absent means `installed`                                  |
| `~/Applications/Menuz.app`                             | The installed app, Gtools' and Conflab's target (D6)                                                                                   |

The app's sources are reviewed by `critic-swift` (`intent lang init swift`, run 16 Oct 2026 in WP-01, the six Swift rules in the library: guard over nested if, optionals over sentinels, structured concurrency over GCD, Codable over manual JSON, narrowest access first, specific XCTAssertEqual values).

## Tests

- **Shim (Linux and macOS legs):** `opt/menuz/test/menuz.bats` with a fixture `HOME`, a fake `Menuz` binary on PATH that records its arguments and prints a scripted answer, and a fake `xcodebuild`/`xcodegen`; every verb's refusal by name; `init` idempotent; `log -n`; the install refusal with no source tree. This is where AC-02.x and the shim half of AC-05.1 live.
- **App (macOS leg, on a tag or on dispatch, as Gtools runs its):** `MenuzKitTests` (Swift Testing, `swift test` in `MenuzKit/`, no Xcode build) over the pure parts: the file decoded into the model, every validation rule red on its fixture and the example green, the realiser's split of literal from dynamic labels and its reassembly of the shell's answer, the `each` expansion, the runner's environment and argv assembly, the log line format; and `MenuzTests`, hosted by the app, holds the test-host guard. No test opens a menu or a dialog.
- **Hand runs on hv's machine, recorded in acceptance.md:** the watcher's latency, a change arriving with no restart; the arngz entries applying a desk; a parameter of each type acquired through the form; launch at login after a logout. vc runs these with hv's hands off, as ST0026's.

## CI

A `menuz-app` job on `macos-15`, `if: github.ref_type == 'tag' || github.event_name == 'workflow_dispatch'` (Gtools' gate, so every push is not an Xcode build), `brew install xcodegen`, `bin/utilz menuz build --unsigned`, `bin/utilz menuz test --unsigned`; on a tag it also signs `Menuz.app` with Developer ID, notarises it and attaches it to the release, Intent's pipeline (D7). The Linux legs run `menuz.bats` in the explicit utility loop.

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

hv ruled on 16 Oct 2026 in vc's session, the rubber-duck of WP-01. In hv's words where hv gave them.

| D   | Decision                                                                                                                                                                                                                                                                                                                                                                                                                         |
| --- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| D1  | As recommended: the config directory is `${XDG_CONFIG_HOME:-$HOME/.config}/menuz/`, `MENUZ_HOME` overriding.                                                                                                                                                                                                                                                                                                                      |
| D2  | As recommended: Yams parses the yaml in the app, Codable models, one parser.                                                                                                                                                                                                                                                                                                                                                       |
| D3  | As recommended: interpolation is the login shell's own expansion of labels and `each` lines, one `zsh -ilc` per menu open, asynchronous, the last values shown first, capped. No menuz syntax.                                                                                                                                                                                                                                    |
| D4  | hv: "One form with all params, typed (where possible)." One window per run holding every param, each field typed from the param's `type` (text, secret, choice, file, folder; `text` when none is given). Not the standard dialogs.                                                                                                                                                                   |
| D5  | As recommended: `menuz.log` under XDG state, `utilz menuz log` tails it, a notification on a non-zero exit, `notify:` per item.                                                                                                                                                                                                                                                                                                   |
| D6  | hv, first to vc: "It's built here locally for dev in native/macos like the other menbar apps, and the installed into opt. There should be a 'use dev\|opt' option like the way devbin has that feature." Then, in cc's session, hv asked where Intent.app, Conflab.app and Gtools.app live, "we should be consistent", and picked the siblings' target (confirmed to vc: "See the utilz-cc correction on install location"). So: the source and the xcodegen project at `native/macos/Menuz/`; the dev build under `${XDG_STATE_HOME:-~/.local/state}/menuz/build/macos/Build/Products/<Config>/`, as Intent's and Gtools' do; the installed copy at `~/Applications/Menuz.app`, Gtools' and Conflab's target (Intent's signed release goes to /Applications); a `use dev\|installed` switch, after devbin's own, says which the shim's launch and status use. |
| D7  | hv: "Same as Intent. This is opensource just like Intent and it needs to be signed properly." Developer ID, notarised, shipped as a release asset the keg installs; not the Apple Development model.                                                                                                                                                                                                                             |
| D8  | As recommended: the menu bar glyph is an SF Symbol named in the yaml, `terminal` by default; no asset pipeline. (hv's "8: Left running" is read as Q9, since "left running" is Q9's alternative; hv is told so.)                                                                                                                                                                                                                   |
| D9  | hv: "Left running, surely?" Runs in flight at Quit are left running, detached from the app (their own session, stdin from /dev/null, stdout and stderr on the log file directly rather than through the app), so the app's exit closes nothing they write to. The log records the quit and names the runs still going.                                                                                                             |
| D10 | hv: "Yep": `each` is in v1.                                                                                                                                                                                                                                                                                                                                                                                                       |
| D11 | hv: "Yep, agree": `Menuz.app`, `com.matthewsinclair.utilz.menuz`.                                                                                                                                                                                                                                                                                                                                                                 |


## Work packages

| WP    | Title                                                        | Builds                                                                                                                                       |
| ----- | ------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------- |
| WP-01 | Design settled with hv                                       | The rubber-duck; every Q above a decision; the example yaml final; swift declared                                                            |
| WP-02 | The shim, the config directory and the catalogue verbs       | `bin/menuz`, `opt/menuz/menuz` with `init`, `edit`, `log`, `validate`, `render`, `status`, `doctor`; bats with the fake app                  |
| WP-03 | The app: the menu from the file, watched, realised at open   | The xcodegen project, the model and validator, the menu, the watcher, the realiser, the command-line arms; `MenuzTests`                       |
| WP-04 | Running items: params, the runner, the log and the notice    | The dialogs, the runner, `menuz.log`, notifications; the arngz hand run                                                                      |
| WP-05 | Build, install, launch and the close                         | `build`, `test`, `install`, `uninstall`, `start`, `stop`, `restart`, `stamps`; login item; CI; help, README, CHANGELOG; the estate green      |

Each WP is sized S, as ST0026's, and WP-02 can start before WP-03 because the shim's verbs that need the app are tested against a fake.
