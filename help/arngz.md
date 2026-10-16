# arngz

**Version**: run `arngz --version`
**Author**: Matthew Sinclair

---

## Name

`arngz` - Named window arrangements (desks) across displays and spaces

---

## Synopsis

```bash
arngz <desk>
arngz apply <desk> [--dry-run] [--no-launch] [--no-create] [--map <name>=<uuid>]
arngz discover [--grid WxH] [--save <desk>] [--force]
arngz diff <desk>
arngz list
arngz show <desk>
arngz delete <desk>
arngz init [--yes]
arngz doctor
```

---

## Description

A **desk** is a named arrangement of windows: for each display, for each space on it, which apps live there and where on a grid their windows sit. `arngz <desk>` puts this machine's windows where the desk says; `arngz discover --save <desk>` records the arrangement on screen now as a desk.

`apply`, `discover`, `diff` and `doctor`'s IPC check reach Hammerspoon through its `hs` tool, so they need Hammerspoon running with `hs.ipc` loaded, which `arngz init --yes` sets up.

**`apply` takes the pointer.** macOS gives no working call to move a window to another space, so apply moves a window the way a person does: it holds the window by its title bar and presses Mission Control's Move left/right a space shortcut, once per step, or drags it over the edge two displays share. Keep your hands off the mouse and keyboard while it runs. Moving the pointer stops it, and every move left is reported as stopped. It puts the pointer back and gives focus back when it is done. The two shortcuts must be set in System Settings > Keyboard > Keyboard Shortcuts > Mission Control, or apply refuses. Every step is read back, and a move macOS did not make is reported as failed.

### The catalogue

One YAML file per desk, at `${XDG_CONFIG_HOME:-$HOME/.config}/arngz/desks/<desk>.yaml`. The directory is the catalogue: there is no index file. A desk's name is its file name: letters, digits, `.`, `_` and `-`, and never the name of a verb, because `arngz <desk>` is `apply <desk>`.

### A desk

```yaml
desk: zeop1
grid: 12x8
displays:
  - name: left
    match:
      {
        uuid: 37D8832A-2D66-02CA-B9F7-8F30A301B230,
        name: VY229HF,
        size: 1920x1080,
        position: left,
      }
    spaces:
      - name: comms # ordinal 1 on this display
        apps:
          - app: com.tinyspeck.slackmacgap
            layout: 0,0 6x8
          - app: com.apple.mail
            layout: 6,0 6x8
      - name: code # ordinal 2
        apps:
          - app: com.microsoft.VSCode
            window: "Utilz" # a Lua pattern on the window title; optional
            layout: 0,0 12x8
  - name: laptop
    match:
      {
        uuid: 37D8832A-2D66-02CA-B9F7-8F30A301B231,
        name: Color LCD,
        size: 3024x1964,
        position: main,
      }
    spaces:
      - apps:
          - app: com.apple.Safari
            layout: fullscreen
```

- **`grid`** is `WxH`, and every layout is in its cells.
- **A display** is matched to a screen by `uuid`, then by `name` and `size`, then by `position`. Its `match` names a `uuid`, a `name`, or both. A `position` is where the screen sits relative to the primary one: `main` for the primary, and otherwise up to two words joined by a hyphen, one from `above`/`below` and one from `left`/`right`, eg `above-left` or `right`.
- **A space** is its order on its display. Its `name` is a label for people; macOS names no desktop space.
- **An app** is its bundle id. `window` is a Lua pattern on the window title; without one, every window of the app takes the layout. The same app twice on one display needs a `window` on every entry.
- **`layout`** is `x,y wxh` in grid cells, inside the grid, or `fullscreen`.
- **`misfit`** is how far `discover` found the window from its cells, eg `3px`. It is information; `apply` ignores it.

### discover

`discover` asks Hammerspoon what is on screen and prints it as a desk: every display with its `uuid`, `name`, `size` and `position` (the name without the " (2)" Hammerspoon adds to a second panel of the same name), every desktop space in order, and every standard window on it, snapped to the grid.

- **Snapping** puts each window edge on the nearest cell edge. When a window was not exactly on its cells, the desk says how far, beside the layout: `misfit: 3px`. A window that spanned part of a cell is snapped and named in the report.
- **A full-screen window** is recorded as `layout: fullscreen`, under the desktop before its space.
- **An app with more than one window on a display** gets a `window` pattern on each, made from the window's title.
- **Not recorded, and said**: minimized windows, windows on every space, Hammerspoon's own windows, windows Accessibility could not name (counted per space), and the Dock's app bindings, which a desk does not hold.

The desk goes to stdout and the report to stderr, so `arngz discover > desk.yaml` keeps the desk alone. `--save <desk>` writes it into the catalogue instead, refusing an existing desk unless `--force` is given. Either way, the desk is checked by the validator first.

### diff

`diff <desk>` prints what `apply` would do, one line per change with its reason, and changes nothing: it asks Hammerspoon for a plan, never for an action. It exits 0 when this machine already matches the desk, and 1 when it does not. A window discover found on a hidden space may read as `unseen` when Accessibility cannot name it at that moment.

### doctor and init

`doctor` checks every precondition the engine's verbs need, and prints one line for each: `ok`; `FAIL`, with what fixes it; or `skip`, when an earlier failure means it cannot be checked, which counts as not holding. It exits 1 when any does not hold.

| Precondition    | Holds when                                   | Read from                                 |
| --------------- | -------------------------------------------- | ----------------------------------------- |
| Hammerspoon     | it is running                                | `pgrep`, and LaunchServices for where     |
| hs tool         | `hs` is on `PATH`                            | `PATH`                                    |
| IPC             | Hammerspoon answers through `hs`             | the engine, asked to observe              |
| Accessibility   | Hammerspoon holds the grant                  | the engine's observation                  |
| separate spaces | each display has its own spaces              | `com.apple.spaces spans-displays`         |
| auto-rearrange  | spaces are not rearranged by most recent use | `com.apple.dock mru-spaces`               |
| Stage Manager   | it is off                                    | `com.apple.WindowManager GloballyEnabled` |

A setting that was never changed takes macOS's default, and the line says so. `doctor` needs no Hammerspoon to run: without one it names it as missing and skips the two checks only Hammerspoon can answer.

`init` creates the catalogue and reports what Hammerspoon needs. `init --yes` provides it. It links the `hs` tool under `/opt/homebrew` as Hammerspoon's own `hs.ipc.cliInstall` would, from the copy inside Hammerspoon.app. It appends one marked line, `require("hs.ipc")`, to Hammerspoon's config, which is `~/.hammerspoon/init.lua` or the file Hammerspoon's `MJConfigFile` preference names, and then asks you to reload that config. A config that already requires `hs.ipc`, marked or not, is left alone, so a second run changes nothing. Whatever `--yes` cannot do, it refuses before changing anything.

### The validator

Every verb that reads a desk validates it first, and refuses with exit 2 on any of: an unknown key; a `grid` that is not `WxH`; a `layout` that is neither `x,y wxh` inside the grid nor `fullscreen`; two displays with one `name`; a display whose `match` carries neither `uuid` nor `name`; the same `app` twice on one display without a `window` on each; a desk named like a verb. Each refusal names the desk, its file, the path in it, and the value, and every refusal in a desk is reported, not just the first.

---

## Verbs

| Verb            | Does                                                                                    | Exit                   |
| --------------- | --------------------------------------------------------------------------------------- | ---------------------- |
| `<desk>`        | the same as `apply <desk>`                                                              | as apply               |
| `apply <desk>`  | arrange this machine's windows as the desk says, and report each app's outcome          | 0, 1, or 2             |
| `discover`      | print the arrangement on screen now as a desk, or save it with `--save`                 | 0, or 2                |
| `diff <desk>`   | print what apply would do, one line per change with its reason, and change nothing      | 0 same, 1 differs, 2   |
| `list`          | each desk with its display and app counts; an invalid desk is named on its own line     | 0, or 1 if any invalid |
| `show <desk>`   | the desk, validated, exactly as stored                                                  | 0, or 2                |
| `delete <desk>` | remove the desk's file, naming it; a desk that no longer validates can still be deleted | 0, or 2                |
| `init`          | create the catalogue and report what Hammerspoon needs; with `--yes`, provide it        | 0, 1, or 2             |
| `doctor`        | every precondition, each with its state, and what fixes each one that does not hold     | 0, or 1 if any fails   |

### Options

| Option                | Verb       | Effect                                                       |
| --------------------- | ---------- | ------------------------------------------------------------ |
| `--dry-run`           | `apply`    | print the plan and change nothing                            |
| `--no-launch`         | `apply`    | report apps that are not running instead of launching them   |
| `--no-create`         | `apply`    | do not create missing spaces                                 |
| `--map <name>=<uuid>` | `apply`    | bind one desk display to one screen for this run             |
| `--grid WxH`          | `discover` | the grid windows are snapped to; 8x4 when absent             |
| `--save <desk>`       | `discover` | write the discovered desk into the catalogue                 |
| `--force`             | `discover` | with `--save`, overwrite an existing desk                    |
| `--yes`               | `init`     | do what init reports Hammerspoon needs, rather than print it |

---

## Examples

```bash
arngz init          # create the catalogue, and say what Hammerspoon needs
arngz init --yes    # and provide it
arngz doctor        # every precondition, each with its state
arngz list          # what desks there are
arngz show zeop1    # one desk, validated
arngz delete old    # remove one
```

---

## Files

- `${XDG_CONFIG_HOME:-$HOME/.config}/arngz/desks/<desk>.yaml` -- one desk.

---

## Environment

- `XDG_CONFIG_HOME` -- where the catalogue lives; `$HOME/.config` when unset.
- `ARNGZ_HS_PREFIX` -- where `init --yes` links the `hs` tool; `/opt/homebrew` when unset.
- `ARNGZ_HS_TIMEOUT` -- how many seconds one call to Hammerspoon may take; 60 when unset.
- `ARNGZ_APPLY_TIMEOUT` -- how many seconds the CLI waits for apply's answer; 600 when unset. Hammerspoon may still be working when it gives up, and it says so.

---

## Exit Status

- `0` -- done.
- `1` -- `apply` skipped an app (not installed, or not running under `--no-launch`), saw no window for an entry, or a move or place did not take, each named in its report; `list` found a desk that does not validate, `diff` found that apply would change something, `doctor` found a precondition that does not hold, or `init --yes` stopped at a step that failed after it had changed something; each is named, and for `init` so is every step it had made.
- `2` -- refused before anything changed: a desk that does not exist or does not validate, a bad name or option, a precondition `apply` checks first (a preference, Accessibility, the Move-space shortcuts, a mouse button or modifier held), or Hammerspoon not answering.

---

## Dependencies

- `yq` (required) -- reads and validates desks.
- `hs` (optional) -- Hammerspoon's command-line tool; needed by `apply`, `discover`, `diff` and `doctor`'s IPC check. `arngz init --yes` links it.
- Hammerspoon (optional, a macOS app) -- the engine; needed by the same verbs. `utilz doctor` and `arngz doctor` look it up by bundle id.

---

## See Also

- `utilz doctor` -- reports arngz's dependencies.
- `arngz doctor` -- every precondition arngz's engine verbs need.
- `intent/st/ST0026/design.md` -- the design.

---

## Author

Matthew Sinclair

---

## Copyright

Copyright (c) 2026 Matthew Sinclair
Part of the Utilz framework.
