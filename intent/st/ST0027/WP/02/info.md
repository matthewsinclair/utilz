---
wp_id: WP-02
title: The shim, the config directory and the catalogue verbs
scope: S
status: Done
---

# WP-02: The shim, the config directory and the catalogue verbs

## Objective

The `utilz menuz` shim: a bash script in the Utilz format, the menuz config directory, and the verbs that need no Xcode. It follows D1 to D11 as recorded in WP-01, D6 as hv corrected it on 16 Oct 2026. Where design.md's shim and build-layout sections disagree with those rulings, the rulings win, and design.md is rewritten at the 0605 sync.

**Files.**

- `opt/menuz/menuz` is the shim. It is bash 3.2-clean under `set -euo pipefail` and shellcheck-clean.
- `opt/menuz/menuz.yaml` declares the utility, with `version_file: VERSION` and `dependencies: []`. xcodegen and xcodebuild are build-time needs, so the shim refuses by name without them, as it does for cargo.
- `opt/menuz/VERSION` is the one home of the version.
- `opt/menuz/lib/example.yaml` is the design's example menu, which `init` writes. Its one param is typed (`type: string`), per D4.
- `bin/menuz` is a symlink to `utilz`, and CI's explicit Linux utility loop gains `menuz`.

**Paths, each in one function.**

| What               | Path                                                                                                                       |
| ------------------ | -------------------------------------------------------------------------------------------------------------------------- |
| Config directory   | `${MENUZ_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/menuz}`                                                                    |
| The menu           | `<config>/menuz.yaml`                                                                                                      |
| Log                | `${XDG_STATE_HOME:-$HOME/.local/state}/menuz/menuz.log`                                                                    |
| Dev build          | `${XDG_STATE_HOME:-$HOME/.local/state}/menuz/build/macos/Build/Products/Debug/Menuz.app`                                   |
| Installed copy     | `$HOME/Applications/Menuz.app`                                                                                             |
| The `use` record   | `${XDG_STATE_HOME:-$HOME/.local/state}/menuz/use`, holding `dev` or `installed`, written by WP-05's `use` verb             |

The build `use` selects is the one the record names. With no record, it is the installed copy when there is one, else the dev build. The app binary is `<bundle>/Contents/MacOS/Menuz` of that build.

**Verbs.** Exit codes follow arngz: 0 done, 1 failed, 2 refused before anything changed. `menuz` with no verb prints usage and exits 2.

| Verb                        | Does                                                                                                                                                                     | Exit                                                      |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------- |
| `init [--force]`            | Creates the config directory with the example `menuz.yaml` and an empty `bin/`. A second run changes nothing                                                             | 0; 2 when `menuz.yaml` exists without `--force`, naming it |
| `edit [--editor]`           | `open -t menuz.yaml`; with `--editor`, `$VISUAL`, else `$EDITOR`                                                                                                         | 0; 2 with no `menuz.yaml`, or `--editor` with neither set  |
| `log [-n N]`                | Prints the log's path, then `tail -f`; with `-n N`, the last N lines and no follow                                                                                       | 0; 2 with no log yet                                      |
| `validate [file]`           | The selected app binary's `--validate` on the file or `menuz.yaml`, its output and exit passed through                                                                  | the app's; 2 with no app, naming both build paths         |
| `render [file]`             | The same with `--render`                                                                                                                                                 | the same                                                  |
| `status`                    | One line each for installed (path, version, build, commit), use (dev or installed, and whether by the record or by default), running, login item and source           | 0; 1 when not installed                                   |

**Status details.**

- **Running** is `pgrep -x Menuz`, the pids or `no`.
- **Login item** is the selected app's answer to a new arm, `--login-item`, which prints the `SMAppService.mainApp` status. WP-03 adds the arm to the app's command-line arms. With no app, the line says so.
- **Source** compares the installed bundle's `MenuzSourceTree` (Info.plist) with the stamp of the tree, as Gtools does. The stamp is a SHA-1 of `git ls-tree -r HEAD native/macos/Menuz` without `MenuzTests/`. A dirty tree folds in each changed path and a digest of its content, and the stamp ends `-dirty`. With no `native/macos/Menuz`, the source is unknown and said so. WP-05's `stamps` and `build` use the same function.

`status` reads Info.plist with `/usr/libexec/PlistBuddy` and needs no Xcode.

**utilz doctor** checks xcodegen and xcodebuild only when `native/macos/Menuz` is present, beside the crate rule in common.sh, advisory as cargo is.

**Tests.** `opt/menuz/test/menuz.bats`, red first, with these fixtures:

- `HOME`, `XDG_CONFIG_HOME`, `XDG_STATE_HOME` and `MENUZ_HOME` all point under `BATS_TEST_TMPDIR`.
- A fake `Menuz.app` sits at the installed or dev path: an executable that records its arguments and prints a scripted answer, with an Info.plist.
- `open`, `pgrep` and `tail` are fakes on PATH where a verb would otherwise reach the machine.

## Acceptance

Acceptance Criteria for this work package are RENDERED into `ST0027/acceptance.md`, under the `WP-02` heading. THAT FILE IS A GENERATED VIEW -- a row authored there is discarded by the next sync. The contract is canon in the thread's model, and the verbs write it: `intent ac new` and `intent at new` mint a row, `intent ac edit` and `intent at edit` reword or re-cite one, and `intent ac satisfy|unsatisfy|descope|rescope|withdraw|reinstate` and `intent at green|red|na` move its state. This cover never restates them.

---

_Generated by Intent v3 from the thread canon. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
