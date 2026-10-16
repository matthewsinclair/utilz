# menuz

**Version**: run `menuz --version`
**Author**: Matthew Sinclair

---

## Name

`menuz` - A menu bar app whose menu is a YAML file of commands to run

---

## Synopsis

```bash
menuz init [--force]
menuz edit [--editor]
menuz log [-n N]
menuz validate [file]
menuz render [file]
menuz status
```

---

## Description

menuz puts a menu of your own commands in the macOS menu bar. The menu is a YAML file in the menuz config directory, `${MENUZ_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/menuz}`. Choosing an item runs its command in your login shell, and what it prints goes to `${XDG_STATE_HOME:-$HOME/.local/state}/menuz/menuz.log`.

This command is the shim. The app itself is `Menuz.app`, built from `native/macos/Menuz` and installed at `~/Applications/Menuz.app`. The yaml is read in one place, the app: `validate` and `render` ask it.

---

## Verbs

| Verb              | Does                                                                                                                                                                    | Exit                                                          |
| ----------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------- |
| `init [--force]`  | Creates the config directory with the example `menuz.yaml` and an empty `bin/`. Run again, it changes nothing. `--force` overwrites the menu                            | 0; 2 when `menuz.yaml` is your own and `--force` is not given |
| `edit [--editor]` | Opens `menuz.yaml` with `open -t`, your default text editor. `--editor` uses `$VISUAL`, else `$EDITOR`                                                                  | 0; 2 with no `menuz.yaml`, or `--editor` with neither set     |
| `log [-n N]`      | Prints the log's path, then follows it with `tail -f`. `-n N` prints the last N lines and does not follow                                                               | 0; 2 with no log yet                                          |
| `validate [file]` | The app's validation of `menuz.yaml`, or of a file: `ok`, or every refusal                                                                                              | the app's, 0 or 2; 2 with no app built or installed           |
| `render [file]`   | The menu as the app would show it, labels realised through the shell                                                                                                    | the same                                                      |
| `status`          | Where the app is installed and its version, which build `use` selects, whether it is running, its login item, and whether the installed copy is current with the source | 0; 1 when not installed                                       |

`validate`, `render` and `status` use the build `use` selects: the one recorded in `${XDG_STATE_HOME:-$HOME/.local/state}/menuz/use`, else the installed copy, else the dev build under `${XDG_STATE_HOME:-$HOME/.local/state}/menuz/build/macos/Build/Products/Debug/`.

---

## Exit codes

- `0` -- done.
- `1` -- `status` found no installed app.
- `2` -- refused before anything changed, with the reason named.
