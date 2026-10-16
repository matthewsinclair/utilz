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
arngz apply <desk> [--dry-run] [--no-launch] [--no-create] [--bind] [--map <name>=<uuid>]
arngz discover [--save <desk>] [--force]
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

**Built so far: the desk catalogue and its validator.** `list`, `show`, `delete` and `init`'s catalogue half work. `apply`, `discover`, `diff`, `doctor` and `init`'s Hammerspoon half are part of the CLI already, and each says which work package of ST0026 builds it (`not yet: WP-0N`) and exits 2 rather than pretending.

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
- **A display** is matched to a screen by `uuid`, then by `name` and `size`, then by `position`. Its `match` names a `uuid`, a `name`, or both.
- **A space** is its order on its display. Its `name` is a label for people; macOS names no desktop space.
- **An app** is its bundle id. `window` is a Lua pattern on the window title; without one, every window of the app takes the layout. The same app twice on one display needs a `window` on every entry.
- **`layout`** is `x,y wxh` in grid cells, inside the grid, or `fullscreen`.

### The validator

Every verb that reads a desk validates it first, and refuses with exit 2 on any of: an unknown key; a `grid` that is not `WxH`; a `layout` that is neither `x,y wxh` inside the grid nor `fullscreen`; two displays with one `name`; a display whose `match` carries neither `uuid` nor `name`; the same `app` twice on one display without a `window` on each; a desk named like a verb. Each refusal names the desk, its file, the path in it, and the value, and every refusal in a desk is reported, not just the first.

---

## Verbs

| Verb            | Does                                                                                    | Exit                   |
| --------------- | --------------------------------------------------------------------------------------- | ---------------------- |
| `<desk>`        | the same as `apply <desk>`                                                              | as apply               |
| `apply <desk>`  | arrange this machine's windows as the desk says (not yet: WP-05)                        | 2                      |
| `discover`      | print the arrangement on screen now as a desk (not yet: WP-04)                          | 2                      |
| `diff <desk>`   | print what apply would do, and change nothing (not yet: WP-04)                          | 2                      |
| `list`          | each desk with its display and app counts; an invalid desk is named on its own line     | 0, or 1 if any invalid |
| `show <desk>`   | the desk, validated, exactly as stored                                                  | 0, or 2                |
| `delete <desk>` | remove the desk's file, naming it; a desk that no longer validates can still be deleted | 0, or 2                |
| `init`          | create the catalogue; the Hammerspoon half is not yet built (WP-06)                     | 0                      |
| `doctor`        | every precondition, each with its state (not yet: WP-06)                                | 2                      |

### Options

| Option                | Verb       | Effect                                                       |
| --------------------- | ---------- | ------------------------------------------------------------ |
| `--dry-run`           | `apply`    | print the plan and change nothing                            |
| `--no-launch`         | `apply`    | report apps that are not running instead of launching them   |
| `--no-create`         | `apply`    | do not create missing spaces                                 |
| `--bind`              | `apply`    | also write the Dock's app-to-space bindings                  |
| `--map <name>=<uuid>` | `apply`    | bind one desk display to one screen for this run             |
| `--save <desk>`       | `discover` | write the discovered desk into the catalogue                 |
| `--force`             | `discover` | with `--save`, overwrite an existing desk                    |
| `--yes`               | `init`     | do what init reports Hammerspoon needs, rather than print it |

---

## Examples

```bash
arngz init          # create the catalogue
arngz list          # what desks there are
arngz show zeop1    # one desk, validated
arngz delete old    # remove one
```

---

## Files

- `${XDG_CONFIG_HOME:-$HOME/.config}/arngz/desks/<desk>.yaml` -- one desk.

---

## Environment

- `XDG_CONFIG_HOME` -- where the catalogue lives; `$HOME/.config` when unset. It is the only override.

---

## Exit Status

- `0` -- done.
- `1` -- `list` found a desk that does not validate, and named it.
- `2` -- refused before anything changed: a desk that does not exist or does not validate, a bad name or option, or a verb not built yet.

---

## Dependencies

- `yq` (required) -- reads and validates desks.
- `hs` (optional) -- Hammerspoon's command-line tool; needed by `apply` and `discover`.
- Hammerspoon (optional, a macOS app) -- the engine; needed by `apply` and `discover`. `utilz doctor` looks it up by bundle id.

---

## See Also

- `utilz doctor` -- reports arngz's dependencies.
- `intent/st/ST0026/design.md` -- the design.

---

## Author

Matthew Sinclair

---

## Copyright

Copyright (c) 2026 Matthew Sinclair
Part of the Utilz framework.
