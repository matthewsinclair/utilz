---
wp_id: WP-03
title: The app: the menu from the file, watched, realised at open
scope: S
status: Done
---

# WP-03: The app: the menu from the file, watched, realised at open

## Objective

The app, `Menuz.app`: its menu read from the file, validated, watched, and realised at each open, plus the command-line arms. Running items (the form, the runner, the run log, the notice) is WP-04; build, install, `use` and signing are WP-05. This note settles what design.md leaves open for WP-03. design.md's sections are the contract, with D1 to D11 as recorded in WP-01.

**Layout: a pure package and an app over it.** `swift test` must run the pure parts without an Xcode build, so they live in a local Swift package that the app links.

| Path                             | What                                                                                                                                                                                      |
| -------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `native/macos/Menuz/project.yml` | xcodegen, Gtools' cut: Swift 6, macOS 14, `LSUIElement`, Automatic signing with team 76BQL8L47U for Debug and Release, hardened runtime, the stamps as build settings                     |
| `native/macos/Menuz/MenuzKit/`   | A Swift package: the `MenuzKit` library (depends on Yams 6) and its `MenuzKitTests` test target. Everything pure lives here, with no AppKit                                               |
| `native/macos/Menuz/Menuz/`      | The app: `MenuzApp.swift` (the delegate and the arms), `Services/` (`LoginShell`, `Watcher`, `Realiser`, `MenuBuilder`, `AppLog`), `Info.plist`, entitlements                             |
| `native/macos/Menuz/MenuzTests/` | A unit-test bundle hosted by the app: the test-host guard, and anything that needs AppKit. The scheme runs it and `MenuzKitTests`, so `xcodebuild test` and `utilz menuz test` cover both |

Yams is the one package, a dependency of MenuzKit (D2). The bundle id is `com.matthewsinclair.utilz.menuz` (D11). Info.plist substitutes `MENUZ_VERSION`, `MENUZ_BUILD`, `MENUZ_COMMIT` and `MENUZ_SOURCE_TREE` into `CFBundleShortVersionString`, `CFBundleVersion`, `MenuzCommit` and `MenuzSourceTree`, the keys WP-02's `status` reads. A build from Xcode gets `dev`.

**MenuzKit, the pure parts.**

- **One parse.** `MenuLoader.load(text:file:context:)` composes the YAML into a Yams `Node` once. The validator walks that node and builds the models (`MenuFile`, `Entry`, `Param`) in the same walk, so a file it passes is never parsed twice. Amended 16 Oct at the build: a Codable decode was the first plan and is not used. It cannot name the entry path a refusal needs, and YAML's core schema would type `run: true` as a Bool and `cwd: ~` as null where the file means the text; the walk reads every value as the scalar's text as written.
- **Refusals beyond the seven rules**, each so that nothing in a file is silently dropped: a key given twice; a key that is not a single word; a value that must be one string and is a list or a mapping; `separator` other than `true`; a submenu's `items` empty; `choices` empty, or given with a type other than `choice`; `required` other than `true` or `false`; an entry or a param that is not a mapping. An `each` without a `label`, a `submenu` without `items` and `items` without a `submenu` are refused by the key that is wrong.
- **The validator** is a function of the node and two facts it is given: the names the login shell exports (rule 4) and a predicate for whether an SF Symbol exists (rule 6). It returns every refusal, not the first. A refusal carries the file, the entry path (`menu[4].items[1]`), the key, the value and why, and prints as one line: `<file>: <path>.<key> = '<value>': <why>`. A param with no `type` is `text`.
- **The menu spec** is the validated file as a tree of nodes (item, caption, header, separator, submenu, each), plus the fixed tail. The app builds an `NSMenu` from it. `--render` prints the same spec as indented text, one entry per line, with the realised labels.
- **The realiser's pure half.**
  - A string is dynamic when it holds `$` or a backtick. A literal is never sent to the shell.
  - Every dynamic label and every `each` line of a menu is realised in one script, run by one `zsh -ilc`.
  - Each label is expanded as the body of a double-quoted string (`eval` of `"<label>"`), each in its own subshell, so one that fails costs only itself.
  - Each `each` line is run, and for every line it prints, `MENUZ_ITEM` is set and that entry's label is expanded.
  - Each result comes back framed as `<id> US <status> US <value> RS`.
  - The script builder and the parser of its output are pure and tested. A test also runs the script through `/bin/zsh -c` (not `-il`, so it is hermetic).
- **The paths.** `MENUZ_HOME`, the config file and the log are found from an environment dictionary, the way the shim finds them. The app passes the login shell's capture, because launchd gives a GUI app none of the user's variables.
- **The log line**: an ISO 8601 UTC timestamp, then the text. WP-03 writes refusals and realise overruns. WP-04 adds the run lines.

**The app.**

- **The delegate** is Gtools' shape: `@main @MainActor final class AppDelegate`, `isTestHost` returning before any launch path, an Edit menu for an `LSUIElement` app, and the status item's glyph from the file's `icon` (an SF Symbol, `terminal` by default), never zero width. The app registers itself with `SMAppService.mainApp` on its first run, logs a failure, and never registers silently.
- **The login shell** is captured once per launch by `/bin/zsh -ilc`: `PATH` plus `MENUZ_HOME`, `XDG_CONFIG_HOME`, `XDG_STATE_HOME`, and the exported names rule 4 needs. Reload captures it again.
- **The watcher** is Conflab's: `DispatchSource` file-system sources on `O_EVTONLY` descriptors for the directory and the file (`.write`, `.delete`, `.rename`). It coalesces events over 250 ms, reopens the file's descriptor after a rename or a delete, and retries a missing directory every 5 s. GCD here is the API macOS gives for vnode events; the coalescing and the reload are a `Task` on the main actor.
- **A file that fails** keeps the last good menu and adds the refusal as a disabled first item in red. The refusal also goes to `menuz.log` and OSLog. A file that fails at launch shows the refusal and the tail alone.
- **The realiser's impure half** runs in `menuWillOpen`, off the main actor. The menu shows the last values at once (the file's text the first time), and titles change in place when the shell answers; `each` items are replaced in place. Past `realise` seconds the shell is stopped, every label not yet answered keeps its last value, and the overrun is logged.
- **The tail**: a separator, **Edit Menu…** (`open -t` on the file), **Open Log** (`open` on the log, or a disabled line saying none exists yet), **Reload**, **Quit menuz** (Cmd-Q). Items with `run` are listed in WP-03 and do nothing until WP-04's runner exists. Choosing one logs that running is not built yet. No item is ever silently dead.

**The arms**, read in `main()` before `NSApplication` starts. They touch no menu bar and exit:

| Arm                 | Prints                                                                                         | Exit                      |
| ------------------- | ---------------------------------------------------------------------------------------------- | ------------------------- |
| `--validate [file]` | `ok`, or every refusal, one per line                                                           | 0, or 2                   |
| `--render [file]`   | The menu as indented text, labels realised through the login shell, the tail included          | 0, or 2 with the refusals |
| `--version`         | `<version> (build <build>, <commit>)` from Info.plist                                          | 0                         |
| `--login-item`      | `SMAppService.mainApp.status`: `enabled`, `requires approval`, `not registered` or `not found` | 0                         |

`[file]` defaults to the config file found from the login shell's environment. An unknown arm is refused, exit 2.

**Tests.** MenuzKitTests use Swift Testing, written red first, and are run by `swift test` in `MenuzKit/`. They cover:

- decoding;
- every validation rule, each red on its own fixture and naming file, path, key and value;
- the example passing;
- a param with no type read as text;
- the spec and its render;
- the dynamic test;
- the script builder and output parser, and the script run through zsh;
- `each` expansion;
- path resolution;
- the log line.

MenuzTests holds the test-host guard. The watcher's latency is AC-03.3's hand run, vc's. critic-swift reviews.

## Acceptance

Acceptance Criteria for this work package are RENDERED into `ST0027/acceptance.md`, under the `WP-03` heading. THAT FILE IS A GENERATED VIEW -- a row authored there is discarded by the next sync. The contract is canon in the thread's model, and the verbs write it: `intent ac new` and `intent at new` mint a row, `intent ac edit` and `intent at edit` reword or re-cite one, and `intent ac satisfy|unsatisfy|descope|rescope|withdraw|reinstate` and `intent at green|red|na` move its state. This cover never restates them.

---

_Generated by Intent v3 from the thread canon. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
