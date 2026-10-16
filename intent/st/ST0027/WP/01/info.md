---
wp_id: WP-01
title: Design settled with hv
scope: S
status: WIP
---

# WP-01: Design settled with hv

## Objective

_(not yet written)_

## Decisions

hv ruled on 16 Oct 2026 in vc's session, the rubber-duck of WP-01. In hv's words where hv gave them.

| D   | Decision                                                                                                                                                                                                                                                                                                                                                                                                                         |
| --- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| D1  | As recommended: the config directory is `${XDG_CONFIG_HOME:-$HOME/.config}/menuz/`, `MENUZ_HOME` overriding.                                                                                                                                                                                                                                                                                                                      |
| D2  | As recommended: Yams parses the yaml in the app, Codable models, one parser.                                                                                                                                                                                                                                                                                                                                                       |
| D3  | As recommended: interpolation is the login shell's own expansion of labels and `each` lines, one `zsh -ilc` per menu open, asynchronous, the last values shown first, capped. No menuz syntax.                                                                                                                                                                                                                                    |
| D4  | hv: "One form with all params, typed (where possible)." One window per run holding every param, each field typed from the param's declaration where the yaml gives a type (string, number, path, choice, bool), free text otherwise. Not the standard dialogs.                                                                                                                                                                   |
| D5  | As recommended: `menuz.log` under XDG state, `utilz menuz log` tails it, a notification on a non-zero exit, `notify:` per item.                                                                                                                                                                                                                                                                                                   |
| D6  | hv: "It's built here locally for dev in native/macos like the other menbar apps, and the installed into opt. There should be a 'use dev\|opt' option like the way devbin has that feature." The source and the dev build live at `native/macos/Menuz/`, the siblings' path; `install` puts the built app under `opt/menuz/`; a `use dev\|opt` switch, after devbin's, says which build the shim and the menu bar run. |
| D7  | hv: "Same as Intent. This is opensource just like Intent and it needs to be signed properly." Developer ID, notarised, shipped as a release asset the keg installs; not the Apple Development model.                                                                                                                                                                                                                             |
| D8  | As recommended: the menu bar glyph is an SF Symbol named in the yaml, `terminal` by default; no asset pipeline. (hv's "8: Left running" is read as Q9, since "left running" is Q9's alternative; hv is told so.)                                                                                                                                                                                                                   |
| D9  | hv: "Left running, surely?" Runs in flight at Quit are left running, detached from the app (their own session, stdin from /dev/null, stdout and stderr on the log file directly rather than through the app), so the app's exit closes nothing they write to. The log records the quit and names the runs still going.                                                                                                             |
| D10 | hv: "Yep": `each` is in v1.                                                                                                                                                                                                                                                                                                                                                                                                       |
| D11 | hv: "Yep, agree": `Menuz.app`, `com.matthewsinclair.utilz.menuz`.                                                                                                                                                                                                                                                                                                                                                                 |

## Acceptance

Acceptance Criteria for this work package are RENDERED into `ST0027/acceptance.md`, under the `WP-01` heading. THAT FILE IS A GENERATED VIEW -- a row authored there is discarded by the next sync. The contract is canon in the thread's model, and the verbs write it: `intent ac new` and `intent at new` mint a row, `intent ac edit` and `intent at edit` reword or re-cite one, and `intent ac satisfy|unsatisfy|descope|rescope|withdraw|reinstate` and `intent at green|red|na` move its state. This cover never restates them.

---

_Generated by Intent v3 from the thread canon. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
