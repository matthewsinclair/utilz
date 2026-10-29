# menuz

**Version**: run `menuz --version`
**Author**: Matthew Sinclair

---

## Name

`menuz` - A macOS menu bar menu of your own commands, read from a YAML file

---

## Synopsis

```bash
menuz init [--force]
menuz edit [--editor]
menuz log [-n N]
menuz validate [<file>]
menuz render [<file>]
menuz status
menuz doctor
menuz build [--release] [--unsigned]
menuz test [--unsigned]
menuz stamps
menuz install
menuz use [dev|installed]
menuz uninstall
menuz start | stop | restart
menuz --help | -h
menuz --version
```

---

## Description

menuz puts a menu of your own commands in the macOS menu bar. The menu is one YAML file, `menuz.yaml`, in menuz's config directory. Each item runs a shell line: a script, a `utilz` verb, anything the login shell can run. An item that takes parameters asks for them in one form before it runs. Everything a run prints goes to one log, `menuz.log`, which `menuz log` tails.

There are two halves. `Menuz.app` shows the menu and runs the items. The `menuz` command creates and checks the config directory, reads the log, and builds, installs and drives the app. The YAML is parsed in one place, the app: `menuz validate` and `menuz render` ask the app's own command-line arms and parse nothing themselves.

**Platform**: the app, and so `validate`, `render`, `build`, `test`, `install`, `uninstall`, `start`, `stop`, `restart` and `edit` without `--editor`, needs macOS (`build` and `test` need Xcode too). Elsewhere each refuses, exit 2, before it asks anything, saying what it needs and that init, use, log, stamps, status, doctor and edit --editor work here. There, `status` prints that one line, and `doctor` says it and checks the menu file alone.

menuz adds no syntax of its own. A label or a shell line is expanded by the login shell, the way it expands a double-quoted string, so `$VAR`, `${VAR:-default}` and `$(command)` mean what they mean in zsh.

### The config directory

`${MENUZ_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/menuz}` holds:

- `menuz.yaml` -- the menu, the one file the app reads.
- `bin/` -- scripts of your own. It is first on `PATH` for every run and every realised label, so `run: backup-notes` finds `bin/backup-notes` with no path.

`menuz init` creates the directory with an example `menuz.yaml` and an empty `bin/`. It refuses to overwrite a `menuz.yaml` of your own unless `--force` is given, and run again over its own example it changes nothing. The log is not here, because it is state rather than configuration, and a config directory is the kind of thing kept in a dotfiles repository.

The app watches the directory and the file. A save, an editor's atomic rename, or a `git checkout` of the directory reaches the menu within a second, with no restart. **Reload** in the menu is for the one case the watcher misses.

### Finding menuz in the menu bar

menuz shows its own mark in the menu bar. `icon:` in the file names an SF Symbol to show instead, any name the SF Symbols app lists; pick one you can find at a glance, since a full menu bar is where you will be looking for it.

macOS puts a new menu bar item at the left of the others, and a full menu bar hides what does not fit behind its overflow. If you cannot see menuz, show the hidden items, then hold Command and drag menuz's icon to where you want it; macOS keeps that place from then on. Until it has one, menuz says so when it starts, in the log, and as a notification once macOS lets it post: `menuz is in the menu bar; on a full bar it may be hidden behind the overflow: hold Command and drag its icon where you want it`.

At its first launch menuz asks macOS whether it may post notifications, and macOS shows an alert: answer it with **Allow**. If menuz quits while the alert is up, macOS counts that as no, and System Settings > Notifications > menuz is then where to allow them.

### The menu file

<!-- prettier-ignore -->
```yaml
# ~/.config/menuz/menuz.yaml
# icon: terminal      # an SF Symbol name for the menu bar glyph; menuz's own mark when absent
cwd: ~                # where runs start unless an item says otherwise; $HOME when absent
notify: failure       # never | failure | always; what a run's end posts as a notification
realise: 5            # seconds a menu open waits for its labels at most; 5 when absent

menu:
  - submenu: Desks…
    items:
      - each: ls "${XDG_CONFIG_HOME:-$HOME/.config}/arngz/desks" 2>/dev/null | sed 's/\.yaml$//'
        label: "$MENUZ_ITEM"
        run: arngz apply "$MENUZ_ITEM"
        checked: "$(arngz current || true)"
  - label: Discover…
    params:
      - name: desk
        prompt: Save the arrangement on screen now as
        default: "$(arngz current || echo today)"
        required: true
    run: arngz discover --save "$desk" --force
  - separator: true
  - submenu: Utilities
    items:
      - label: "Up $(uptime | sed 's/.*up //; s/,.*//')"
      - label: Sleep Display
        run: pmset displaysleepnow
      - label: Empty Trash
        run: osascript -e 'tell application "Finder" to empty trash'
        cwd: ~/.Trash
      - separator: true
      - label: Hammerspoon
        run: arngz doctor
        notify: always
      - separator: true
      - menuz: log
      - menuz: edit
      - menuz: reload
```

| Key         | Meaning                                                                                                                          |
| ----------- | -------------------------------------------------------------------------------------------------------------------------------- |
| `label`     | an item; with `run`, choosing it runs the line, and without `run` it is a caption, shown disabled                                |
| `run`       | the shell line the login shell runs; menuz never parses it                                                                       |
| `params`    | the parameters asked for before the run (below)                                                                                  |
| `cwd`       | the run's working directory; the item's wins over the file's                                                                     |
| `notify`    | `never`, `failure` or `always`; the item's wins over the file's                                                                  |
| `each`      | a shell line whose output lines become one item each, at every menu open; `$MENUZ_ITEM` is the line, in `label`, `run` and `cwd` |
| `checked`   | with `each`: a string realised like a label at every open; the item whose line it equals is ticked                               |
| `header`    | a section header                                                                                                                 |
| `separator` | a separator                                                                                                                      |
| `submenu`   | a submenu, with its entries under `items`, nested as deep as wanted                                                              |
| `menuz`     | one of the app's own items, placed here rather than below the file's entries: `log`, `edit` or `reload`, each at most once       |

A `separator` that starts the menu, or follows another at its top level, adds no line: the one under the top row, or the one before it, serves. Inside a submenu, separators are drawn as the file gives them.

The app has four items of its own: **Edit…**, which opens `menuz.yaml` in the default text editor, **Log**, which opens menuz's log window, **Reload**, and **Quit menuz**. The log window follows the log as it grows, and across a truncation or a rotation. It shows in red a run that exited other than 0, could not start or was not run, a refusal, a form or an `open` that failed, a label or `each` that did not realise, and what the top row logs; in orange a run cancelled, a notice not posted, a realise that passed its `realise` seconds, a login item menuz could not register, a login shell whose environment could not be read, a menu bar mark missing from the app, and notifications turned off or not set up; and in blue each run's start and its exit 0. Command-F finds. A `menuz` entry puts one of the first three where it stands, so the example keeps them in its **Utilities** submenu. Those the file does not place go below its entries, after a line (the menu's own, when its last entry is a separator), and **Quit menuz** is always there, last. Before there is a log, **Log** reads **Log (no log yet)**, disabled, wherever it sits.

### Labels at every open

A label or an `each` line with a `$` or a backtick is realised by the login shell each time the menu opens. All of a menu's such strings go to one `zsh -ilc`, so ten dynamic labels cost one shell start. The menu opens at once with the last values, the file's text on the first open, and the titles update in place when the shell answers. A string still unanswered after `realise` seconds keeps its last value, and the log says so. A label with neither a `$` nor a backtick is never sent to the shell. An `each`'s `checked` goes to the same shell, with the labels, and the item whose line equals what it gives is ticked.

A `$(...)` that exits other than 0 fails the string it is in, which then keeps its last value. So a command that may print nothing and fail, such as `arngz current` before any desk is recorded, is written with what the string should be then: `$(arngz current || true)` for no tick, `$(arngz current || echo today)` for a default.

### Parameters

An item's `params` is a list of the parameters it asks for, in order. A parameter has:

| Key        | Meaning                                                                                                                       |
| ---------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `name`     | the variable its value is exported as: lower case, `[a-z][a-z0-9_]*`, not one the login shell already exports, and not shared |
| `prompt`   | the question asked                                                                                                            |
| `default`  | the answer filled in; with `$` or a backtick, realised by the login shell as the form opens; not on a `secret` or a `choice`  |
| `required` | `true` refuses an empty answer; otherwise an empty answer is an empty variable                                                |
| `type`     | the kind of answer, one of the five below; `text` when absent                                                                 |

| `type`   | Answer                                                                                    | Exported as     |
| -------- | ----------------------------------------------------------------------------------------- | --------------- |
| `text`   | a line of text                                                                            | the text        |
| `secret` | a line of text, hidden as it is typed and never written to the log                        | the text        |
| `choice` | one of `choices`, a list or a shell line realised when it is asked; the first is selected | the chosen line |
| `file`   | a file                                                                                    | its POSIX path  |
| `folder` | a folder                                                                                  | its POSIX path  |

A yes-or-no is a `choice` of two lines.

The parameters are asked for in one form, which holds every parameter as a field in the file's order, with **Run** and **Cancel** at its foot. The form is titled with the item's label less a trailing `…` or `...`, so **Discover…** asks in a form titled **Discover**. Return is **Run**; Escape, or closing the form, is **Cancel**. An item with no parameters runs at once, with no form.

- A `text` field shows its `prompt`, or the parameter's name when there is none, with its `default` filled in.
- A `secret` field starts empty and hides what is typed.
- A `choice` is a pop-up of its `choices`, the first selected. A `choices` shell line runs when the form opens, through the login shell, one choice per line it prints; a line that fails or prints nothing shows its failure in the field, and a failure is logged too.
- A `file` or `folder` field takes a path, with its `default` filled in, and a **Choose** button for the usual Open panel.
- A `default` with a `$` or a backtick is realised by the login shell when the form opens. The field waits for it, and so does **Run** while nothing is typed there; what is typed first is never overwritten. A default that cannot be read is said under the field, which is left to be typed, and in the log.

The form checks the answers as they are typed, and each refusal names its parameter: a `required` parameter left empty, a `file` that does not exist or is a folder, a `folder` that does not exist or is not a folder, a `choice` that is not one of the choices. **Run** stays disabled while any refusal stands. A parameter that is not `required` and is left empty is exported empty. **Cancel** runs nothing, and the log records the run as cancelled.

The values reach the run as exported variables under the parameters' names, so `run: arngz discover --save "$desk"` is ordinary shell, and quoting is the shell's. menuz never splices a value into a command line, which is what keeps a value with a space, a quote or a `;` in it safe.

### Running an item

A run is `/bin/zsh -ilc` of the item's `run` line, so aliases and `PATH` additions from `.zshrc` count, as in a terminal. Its `PATH` is the login shell's with `$MENUZ_HOME/bin` first. It starts in the item's `cwd`, else the file's, else `$HOME`, expanded by zsh as written, so `~`, `$HOME` and, under `each`, `$MENUZ_ITEM` work; a directory it cannot enter ends the run with exit 126 and a line in the log saying so. Its stdin is `/dev/null`: a run never has a terminal. It has `MENUZ_HOME`, `MENUZ_LABEL`, `MENUZ_RUN_ID`, under `each` `MENUZ_ITEM`, and its parameters.

Runs are concurrent and independent, each with its own id. Nothing is queued and nothing is refused for being busy. A run is detached from the app, in its own session and writing to the log itself, so **Quit menuz** leaves runs in flight running, and the log records the quit and names each run still going.

### The log and the notice

Every run appends to `${XDG_STATE_HOME:-$HOME/.local/state}/menuz/menuz.log`, which is created on first use:

```
2026-10-16T10:42:03Z run 17 start "Hammerspoon" cwd=~: arngz doctor
[17] hammerspoon  running (pid 4123)
2026-10-16T10:42:04Z run 17 exit 0 in 1.3s
```

The start line prints the `cwd` and the `run` line as written, before the shell expands them, so `cwd=~` stays `~`; with no `cwd` in the item or the file it prints `$HOME`'s value. A parameter's value reaches the run only through its environment, which is what keeps a secret's value out of the log. Each output line carries its run's id, so concurrent runs interleave legibly. Two more lines are the app's: `<time> run <id> cancelled "<label>"` when a form is cancelled, and `<time> quit; runs still going: <ids>`, the ids separated by commas, or `none`, when the app quits.

A run that exits non-zero posts a macOS notification, `"<label>" exited <code>`. `notify: always` posts one at every finish, with the run's last line of output after a colon, and `notify: never` posts none. Notices come through macOS's notification centre under menuz's name, posted by the app's own executable at the run's end, so a run that outlives the app still sends one. The log says which: `[<id>] notice posted`; `[<id>] notice not posted: notifications are off for menuz under System Settings > Notifications > menuz` when they are turned off there; `[<id>] notice not posted: menuz is not yet allowed to post notifications: answer macOS's alert, or allow them under System Settings > Notifications > menuz` while macOS's alert is still up; `[<id>] notice not posted: no answer from the notification centre in 10 s` when the centre does not answer within the 10 seconds a run waits; or the centre's own reason. System Settings > Notifications > menuz is also where you choose how they show.

Each launch logs what macOS answered: `notifications: granted`, `notifications: denied under System Settings > Notifications > menuz`, `notifications: not yet allowed: answer macOS's alert, or allow them under System Settings > Notifications > menuz`, or the centre's own error. `not yet allowed` is logged only while the alert is up; once it was answered no, or withdrawn by menuz quitting under it, the launch logs `denied` and each run the `notifications are off` line. When the alert is still up after 10 seconds the launch logs `notifications: macOS is asking whether menuz may post; the answer is logged when it comes`, and the answer follows when it comes. A line the app cannot write to the log is reported in the app's own log and as a notification, never dropped.

### The validator

`menuz validate` refuses, naming the file, the entry by its path (eg `menu[4].items[1]`), the key and the value:

1. an unknown key anywhere;
2. an entry that is none of the kinds, or more than one (`label` with `header`, `each` with `submenu`);
3. `run` without `label` or `each`, `params` without `run`, `checked` anywhere but an `each`, or `cwd` or `notify` beside a `menuz`;
4. a parameter name that is not `[a-z][a-z0-9_]*`, that the login shell already exports, or that two parameters share;
5. a parameter `type` that is not `text`, `secret`, `choice`, `file` or `folder`, a `choice` without `choices`, or a `default` on a `secret` or a `choice`;
6. a `notify` that is not `never`, `failure` or `always`, a `realise` that is not a positive number, or an `icon` this macOS has no SF Symbol for;
7. an empty `menu`;
8. a `menuz` that is not `log`, `edit` or `reload`, or one of them placed a second time.

It reports every refusal, not only the first, one to a line, as `<file>: <path>.<key> = '<value>': <why>`: a key at the top of the file has no path, and a file that is not YAML at all is `<file>: <why>`. A file that passes prints `ok`.

```
menuz.yaml: notify = 'sometimes': notify is never, failure or always
menuz.yaml: menu[0].colour = 'red': unknown key
menuz.yaml: menu[3].items[8].menuz = 'log': menu[3].items[6] places it already
```

`menuz render` prints the menu as an outline, one entry per line, its labels realised: `# ` before a header, an item by its label, `✓ ` before the one an `each`'s `checked` names, a caption in parentheses, `---` for a separator, and a submenu as `Name >` with its entries indented two spaces under it. Its first two lines are the menu's top row, its heading and its second line as below, with the `---` the menu draws under them, so what `render` prints is what the menu shows. The app's own items come where the file places them, and the rest last.

```
Menuz 0.4.0
3e731d3a · release
---
Desks… >
  ✓ home
  work
Discover…
---
Utilities >
  (Up 16 days)
  Sleep Display
  Empty Trash
  ---
  Hammerspoon
  ---
  Log
  Edit…
  Reload
---
Quit menuz
```

A file that fails in the running app keeps the last good menu on screen and shows the refusal as a disabled first item, and in the log. Nothing is dropped silently.

### Which build

`validate`, `render`, `start`, `restart`, `doctor` and `status`'s login item act on the selected build: the one named, `dev` or `installed`, in `${XDG_STATE_HOME:-$HOME/.local/state}/menuz/use`, and the installed `~/Applications/Menuz.app` when that file names none. When none is named and none is installed, they take the development build, `${XDG_STATE_HOME:-$HOME/.local/state}/menuz/build/macos/Build/Products/Debug/Menuz.app`, instead. With neither app there they refuse, exit 2, naming both places; with a named build that is not there, they refuse naming it.

`menuz use dev` names the development build, and `menuz use installed` the one in `~/Applications`. `menuz use` alone prints the choice and why: `installed (default)` when nothing is named, or `dev (by <the use file>)`.

`status` prints one line each: whether the app is installed, with its path, version, build and commit; which build is selected, and why; whether it is running, with its pid; its login item; and whether the installed app is current with `native/macos/Menuz`.

### Building and installing

The app's source and its xcodegen project live at `native/macos/Menuz/`. The app runs on macOS 26 or later, and builds with Xcode 27.1 or later, the floor `project.yml`'s `xcodeVersion` names and `menuz doctor` checks. `menuz build` runs xcodegen only when there is no `Menuz.xcodeproj`, `project.yml` changed, or a source file was added or removed, then builds Debug, or Release with `--release`, with every product and intermediate under `${XDG_STATE_HOME:-$HOME/.local/state}/menuz/build/macos/`, off the tree. It prints where xcodebuild's log is. A failed build prints the log's `error:` and `fatal error:` lines first, the first 20 with a count of the rest, then the log's last 40 lines. `--unsigned` builds with no signing identity, as CI does. `menuz test` runs the app's tests, `MenuzTests` and `MenuzKitTests`, the same way, in Debug. Xcode registers each app it builds with Launch Services, so `build`, `test` and `install` drop the product's record after xcodebuild, a failed build's included, and the bundle id opens only the installed app. A record that will not drop is a warning naming the bundle and the `lsregister -u` line that drops it; the build's own exit stands.

Each build stamps the app with five values, which `menuz stamps` prints one `NAME=value` a line before a build: `MENUZ_VERSION`, from `opt/menuz/VERSION`; `MENUZ_BUILD`, the commit count; `MENUZ_COMMIT`, the commit's first eight characters; `MENUZ_SOURCE_TREE`, the stamp of the app's sources, ending `-dirty` when the working tree differs from the commit there; and `MENUZ_KIND`, `release` when the source stamp is clean and the commit carries the release tag that Utilz's root `VERSION` file names (a bare tag, `2.14.0`, never `v2.14.0`), and `dev` otherwise. `status` compares the installed app's `MENUZ_SOURCE_TREE` with the tree's to say whether it is current.

The menu's top row names the build from those stamps, `Menuz <version>` in bold over a smaller `<commit> · <kind>`, with menuz's icon, in one of three forms:

```
Menuz 0.4.0
3e731d3a · release

Menuz 0.4.0
3e731d3a · dev

Menuz 0.4.0
dirty-3e731d3a · dev
```

`dirty-` comes before the commit of a build from a dirty source tree, and the kind is `release` for a clean build of the release tag and `dev` for every other. The signed release asset is built at the tag from a clean tree, so a Homebrew install's app shows the first form; a build from a working tree, the development build included, shows `dev`.

Choosing the row opens menuz's About window. The row and the window are arca_swift's masthead, read from a `masthead.yaml` and an `about.md` in the app's bundle each time the menu opens. A copy of either in `${XDG_CONFIG_HOME:-~/.config}/menuz/`, which `MENUZ_HOME` does not move, replaces the bundle's with no rebuild; one that fails its checks leaves the bundle's in use, the row's second line says what is wrong, and the log says it after `masthead: `. In them, `{name}` and `{version}` are the bundle's name and version, and menuz gives `{app}`, the version with its build and commit, `{tree}`, the source tree stamp at the commit's length with any `-dirty` kept, `{commit}`, `{kind}` and `{menu}`, the path of the menu file it reads. The bundle's About window shows menuz's logo, its name, a line on what it is, the version with its build and commit, the source tree, the menu file, what built it, the repository and the author, as Gtools' does.

`menuz install` builds Release, quits every running copy, puts the new one at `~/Applications/Menuz.app`, where the other menu bar apps install, registers it with Launch Services, so it, and never a build product, is the one opened for menuz, and launches it with an empty environment but `HOME`, so the app reads your login shell's environment for itself rather than the caller's. The old copy is replaced only once the new one is whole beside it, and put back if the move fails. The installed copy, and only that copy, registers itself as a login item when it launches; `menuz status` reports it.

`menuz start` launches the selected build the same way; `menuz stop` quits every copy and waits up to 5 seconds for each to go; `menuz restart` finds the selected build first, so a missing one is refused with nothing quit, then stops and starts. `menuz uninstall` quits every copy, has the installed app unregister its login item, unregisters it with Launch Services and removes it; with nothing installed it changes nothing. Launching the development build, with `menuz use dev`, registers it with Launch Services again, as that choice asks; the next build drops it.

### In a Homebrew install

A Homebrew install of Utilz carries no app source. There, `build` and `test` refuse, naming `menuz install` for the release's signed app and the source clone to build from (`git clone https://github.com/matthewsinclair/utilz`), `stamps` prints what the installed app carries, `status` says its source is `homebrew`, with nothing to compare, and `install` takes the app from the release instead: it fetches `Menuz.app.zip` from the GitHub release for the installed Utilz version, then checks its signature, that macOS accepts it as notarised Developer ID, its bundle id and its version against `opt/menuz/VERSION`, before it replaces anything. A check that fails stops the install, naming the check; a release that carries no `Menuz.app.zip` stops it naming the URL it tried. Each release's `Menuz.app` is signed with a Developer ID and notarised, as Intent's app is.

---

## Verbs

| Verb        | Does                                                                                                                                                                                                                                                                                                                                                                   | Exit                     |
| ----------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------ |
| `init`      | create the config directory with the example `menuz.yaml` and an empty `bin/`                                                                                                                                                                                                                                                                                          | 0, or 2                  |
| `edit`      | open `menuz.yaml` in the default text editor, or in `$VISUAL` or `$EDITOR` with `--editor`                                                                                                                                                                                                                                                                             | 0, or 2                  |
| `log`       | print the log's path, then follow it                                                                                                                                                                                                                                                                                                                                   | 0, or 2                  |
| `validate`  | check `menuz.yaml`, or `<file>`, with the app's validator: `ok`, or every refusal                                                                                                                                                                                                                                                                                      | 0, or 2                  |
| `render`    | print the menu as the app would show it, labels realised, one entry per line                                                                                                                                                                                                                                                                                           | 0, or 2                  |
| `status`    | installed (version, build, commit), running (pid), login item, source-current, and which build is selected                                                                                                                                                                                                                                                             | 0, or 1 if not installed |
| `doctor`    | one line per precondition, each `ok` or `FAIL`: `xcode`, `xcodegen` and `identity` (one `build skip` line in a Homebrew install), `config`, `menu` (it validates), `installed`, `records`, `running` and `login item`; `records` is `WARN`, which fails nothing, for each Launch Services record of the bundle id but the installed app's, with the line that drops it | 0, or 1 if any fails     |
| `build`     | build the app, Debug unless `--release`                                                                                                                                                                                                                                                                                                                                | 0, 1, or 2               |
| `test`      | run the app's `MenuzTests` and `MenuzKitTests`                                                                                                                                                                                                                                                                                                                         | 0, 1, or 2               |
| `stamps`    | print what the next build stamps into the app; in a Homebrew install, what the installed app carries                                                                                                                                                                                                                                                                   | 0, 1, or 2               |
| `install`   | build Release (in a Homebrew install, fetch the release's app), replace `~/Applications/Menuz.app`, register and launch it                                                                                                                                                                                                                                             | 0, 1, or 2               |
| `use`       | name the development build (`dev`) or the installed one (`installed`), or print which is selected and why                                                                                                                                                                                                                                                              | 0, or 2                  |
| `uninstall` | quit every copy, unregister its login item and the bundle, and remove the installed app                                                                                                                                                                                                                                                                                | 0, 1, or 2               |
| `start`     | launch the selected build with an empty environment                                                                                                                                                                                                                                                                                                                    | 0, 1, or 2               |
| `stop`      | quit every copy                                                                                                                                                                                                                                                                                                                                                        | 0, 1, or 2               |
| `restart`   | stop, then start the selected build                                                                                                                                                                                                                                                                                                                                    | 0, 1, or 2               |

### Options

| Option         | Verb            | Effect                                     |
| -------------- | --------------- | ------------------------------------------ |
| `--force`      | `init`          | overwrite an existing `menuz.yaml`         |
| `--editor`     | `edit`          | open the file in `$VISUAL`, else `$EDITOR` |
| `-n N`         | `log`           | print the last N lines and do not follow   |
| `--release`    | `build`         | build Release rather than Debug            |
| `--unsigned`   | `build`, `test` | build with no signing identity, as CI does |
| `--help`, `-h` |                 | print this help                            |
| `--version`    |                 | print menuz's version                      |

---

## Examples

```bash
menuz init                    # create the config directory and the example menu
menuz edit                    # open menuz.yaml
menuz validate                # check it
menuz render                  # see the menu it makes, labels realised
menuz install                 # build the app, install it in ~/Applications and launch it
menuz doctor                  # every precondition, ok or FAIL
menuz status                  # installed, running, login item, which build
menuz log                     # follow every run's output
menuz log -n 50               # the last 50 lines
menuz use dev                 # act on the development build
menuz use installed           # back to the installed one
```

---

## Files

- `${MENUZ_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/menuz}/menuz.yaml` -- the menu.
- `${MENUZ_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/menuz}/bin/` -- your scripts, first on every run's `PATH`.
- `${XDG_STATE_HOME:-$HOME/.local/state}/menuz/menuz.log` -- every run's output.
- `native/macos/Menuz/` -- the app's source and its xcodegen project.
- `${XDG_STATE_HOME:-$HOME/.local/state}/menuz/build/macos/` -- the development build.
- `~/Applications/Menuz.app` -- the installed app.

---

## Environment

- `MENUZ_HOME` -- the config directory; `${XDG_CONFIG_HOME:-$HOME/.config}/menuz` when unset.
- `XDG_CONFIG_HOME` -- where the config directory lives when `MENUZ_HOME` is unset; `$HOME/.config` when unset.
- `XDG_STATE_HOME` -- where the log and the development build live; `$HOME/.local/state` when unset.
- `VISUAL`, `EDITOR` -- the editor `edit --editor` opens.

Every run also has `MENUZ_HOME`, `MENUZ_LABEL`, `MENUZ_RUN_ID` and, under `each`, `MENUZ_ITEM`.

---

## Exit Status

- `0` -- done.
- `1` -- failed after something changed, naming the step: xcodegen or xcodebuild (a build failed or a test was red), or `install`'s quit, replace, unclaim, register, launch, fetch, unzip, codesign, spctl, bundle id or version; `stop` or `restart` found a copy still running 5 seconds after asking it to quit; `start` could not launch the app; `uninstall` removed the app but could not unregister it; `stamps` could not read the stamps; `status` found no app installed; or `doctor` found a precondition that does not hold.
- `2` -- refused before anything changed: `init` over a `menuz.yaml` that is not the example, without `--force`; `edit`, `validate` or `render` with no `menuz.yaml`, or `validate` or `render` given a file that does not exist; `edit --editor` with neither `VISUAL` nor `EDITOR` set; `log` with no log yet, or `-n` without a count; `validate` or `render` with no app built or installed, or a file the validator refuses; `build`, `test` or `install` without Xcode or xcodegen or the app's source, and `build` or `test` in a Homebrew install; `start` or `restart` with no build to launch; `use` with a word that is neither `dev` nor `installed`; `stamps` in a Homebrew install with no app installed; a bad verb or option.

---

## Dependencies

- macOS 26 or later -- for `Menuz.app`, whose top row and About window need it.
- Xcode 27.1 or later and `xcodegen` (optional) -- needed by `build`, `test` and `install` in a source clone; `utilz doctor` reports them only where the app's source, `native/macos/Menuz/`, is present.

---

## See Also

- `utilz doctor` -- reports menuz's dependencies.
- `menuz doctor` -- every precondition menuz needs.
- `arngz` -- the first thing on the example menu.
- `intent/st/ST0027/design.md` -- the design.

---

## Author

Matthew Sinclair

---

## Copyright

Copyright (c) 2026 Matthew Sinclair
Part of the Utilz framework.
