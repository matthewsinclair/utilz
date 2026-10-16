# arngz: design

## The problem

macOS puts an app's windows on whichever space it decides, and after every reboot, display change or relaunch the arrangement is rebuilt by hand. Hammerspoon gives keyboard control of a window's geometry on a grid, but it has no notion of a saved arrangement across displays and spaces. arngz adds that: a named **desk** that says, for each display, for each space, which apps live there and where on the grid each app's windows sit. `utilz arngz zeop1` restores a known desk on this machine's displays; `utilz arngz discover --save zeop1` records the one on screen now.

## What macOS offers, and the shape it forces

| Fact                                                                                              | Consequence for arngz                                                                                                               |
| ------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| Spaces have no public API. Every tool reaches them through private SkyLight calls.               | Hammerspoon's `hs.spaces` carries that risk (D1). arngz makes only public `hs.*` calls and no private call of its own (D15).         |
| Desktop spaces have no names; Mission Control shows "Desktop 1..n" per display.                   | A space is its ordinal on its display. A name in the desk is a label arngz keeps, not something macOS knows (D4).                   |
| Space ids are integers macOS regenerates; a space's UUID lasts only while the space exists.       | The desk never stores a space id. Ordinals are resolved against a fresh observation at every apply.                                 |
| Each display has its own spaces when "Displays have separate Spaces" is on (the default).        | A precondition, checked by `doctor` and by `apply` before anything changes.                                                          |
| Moving a window to another space works on some macOS versions and not others.                    | WP-01's spike measures it on macOS 27 before apply is built. Its outcome selects between two apply strategies (see "The open input"). |
| A window's position and size are set through the Accessibility API, which is public.            | Placement is the safe half. It needs one Accessibility grant, which Hammerspoon already holds.                                        |
| A display's name is not unique (this machine has two VY229HF panels); its panel UUID is.          | Displays match by UUID first, name and size second, position third (D6).                                                             |
| An app is a bundle id; it has 0..n windows.                                                       | An app entry is a bundle id plus an optional window title pattern; no pattern means every window of that app (D5).                  |
| Some apps do not expose windows on non-visible spaces to Accessibility.                           | `observe` records, per space, how many window ids it saw and how many it could name; discovery visits a space only when it must.    |
| A full-screen window is its own space and cannot sit on a grid.                                   | Recorded as `layout: fullscreen` and left alone (D11).                                                                               |
| Accessibility cannot be granted on a CI runner, and the macOS legs run on tags only.             | The planner is pure and tested on Linux; the engine's execute half is hand-run on hv's machine and recorded as such (D12).          |
| The Dock's "Assign To" bindings are macOS's own app-to-space rule, kept in a private plist.      | Discovery reads them. Apply rewrites them only with `--bind`, and only once WP-01 shows a written binding takes (D10).               |

## The model

```
[desk] -1-n- [display] -1-n- [space] -1-n- [app] -1-1- [layout]
```

| Thing   | Identity                                       | Human label                    | Why that identity                                                     |
| ------- | ---------------------------------------------- | ------------------------------ | --------------------------------------------------------------------- |
| desk    | its file name                                  | the same                       | one file per desk makes list, show and delete file operations         |
| display | the panel's UUID (`hs.screen:getUUID()`)       | `name`, `size`, `position`     | two identical panels share a name and a size; only the UUID differs   |
| space   | its ordinal on its display                     | an optional `name`             | macOS names no desktop space, and regenerates ids                     |
| app     | its bundle id                                  | an optional `window` pattern   | app names localise and change; windows are the thing that gets placed |
| layout  | `x,y wxh` in the desk's grid, or `fullscreen`  |                                | a cell means nothing without the grid, so the desk declares it (D7)   |

## The config

A desk is one YAML file at `${XDG_CONFIG_HOME:-$HOME/.config}/arngz/desks/<desk>.yaml`. The directory is the catalogue: `list` reads it, `delete` removes a file from it, `discover --save` writes into it. There is no index file to drift. Tests point `XDG_CONFIG_HOME` at a fixture directory; no other override exists.

```yaml
desk: zeop1
grid: 12x8
displays:
  - name: left
    match: { uuid: 37D8832A-2D66-02CA-B9F7-8F30A301B230, name: VY229HF, size: 1920x1080, position: left }
    spaces:
      - name: comms            # ordinal 1 on this display
        apps:
          - app: com.tinyspeck.slackmacgap
            layout: 0,0 6x8
          - app: com.apple.mail
            layout: 6,0 6x8
      - name: code             # ordinal 2
        apps:
          - app: com.microsoft.VSCode
            window: "Utilz"    # a Lua pattern on the window title; optional
            layout: 0,0 12x8
  - name: laptop
    match: { uuid: 37D8832A-2D66-02CA-B9F7-8F30A301B231, name: Color LCD, size: 3024x1964, position: main }
    spaces:
      - apps:
          - app: com.apple.Safari
            layout: fullscreen
```

The format is YAML and not TOML, measured rather than preferred: yq 4.54.1 reads and writes both, so the toolchain is indifferent, and the deciding point is that a four-level tree reads as indentation in YAML and as order-dependent `[[displays.spaces.apps]]` headers in TOML. This yq reads `on` and `off` as strings, so nothing in a desk turns into a boolean by surprise.

The validator refuses, naming the desk, the path and the value, on each of: an unknown key; a `grid` that is not `WxH`; a `layout` that is neither `x,y wxh` inside the grid nor `fullscreen`; two displays with one `name`; a display whose `match` carries neither `uuid` nor `name`; the same `app` twice on one display unless every one of them carries a `window` pattern; a desk name that is one of arngz's verbs. Two more, added in WP-02: a document whose shape is wrong (a list where the schema puts a mapping or the reverse, an app entry with no `app`, a missing `grid` or `layout`), and a desk name that is not a plain file name, so that `show ../x` cannot reach outside the catalogue. The validator is one function in the CLI, and every verb that reads a desk calls it before doing anything else; `delete` is the exception, deliberately, because a desk that no longer validates is exactly the one you want to be able to remove.

## The engine

Hammerspoon is the engine (D1). arngz is two halves with one contract between them.

- **The CLI**, `opt/arngz/arngz`, a bash utility in the Utilz pattern: `bin/arngz` dispatches to it, `opt/arngz/arngz.yaml` declares it and its dependencies (`yq`, Hammerspoon, the `hs` tool), `help/arngz.md` documents it, `opt/arngz/test/` holds its bats suite. It parses arguments, reads and validates desks, converts YAML to JSON with yq, hands Hammerspoon a request, and renders the response. No arrangement logic lives in it.
- **The module**, `opt/arngz/lib/arngz.lua`, loaded by Hammerspoon with `dofile` at every call, so a change to the file is live without reloading Hammerspoon's config. It has three parts: `observe() -> world` reads screens, spaces, windows, settings and bindings; `plan(desk, world) -> ops` is pure, with no `hs.*` call in it; `execute(ops) -> results` performs the ops and reads back after each one.

The contract: the CLI writes a request as JSON to a file under its own temp dir (`{verb, desk, options}`), runs `hs -c 'return dofile("<module>").run("<request path>")'`, and the module writes the response JSON beside the request and returns one status line. Files rather than arguments, because a desk does not fit safely in a shell-quoted `-c` string. The response carries the world as observed, the plan, the results of each op, and the report; the CLI renders those and never recomputes them.

The planner is pure so that it is testable where Hammerspoon is not (D12). Its inputs are two JSON documents, a desk and a world, and its output is a list of ops, each carrying the desk path that asked for it:

| Op             | Arguments                   | Produced when                                                              |
| -------------- | --------------------------- | -------------------------------------------------------------------------- |
| `create_space` | screen uuid                 | a display has fewer spaces than the desk needs, and `--no-create` is absent |
| `launch`       | bundle id                   | the desk names an app with no running process, and `--no-launch` is absent |
| `move`         | window id, space ordinal    | a matched window is on the wrong space                                     |
| `place`        | window id, frame            | a matched window's frame is not its layout's frame on its display          |
| `bind`         | bundle id, space uuid       | `--bind` is given and the binding differs                                  |
| `restart_dock` |                             | any `bind` op exists                                                       |

A layout's frame is computed by the planner from the display's frame and the desk's grid, not by `hs.grid`, whose grid is global state inside Hammerspoon (D7). Discovery does the reverse: it snaps a window's frame to the nearest cells and records, beside the layout, how far the window was from the cell edge, so a desk made from a loosely placed window says so.

A discovered desk must plan clean against the world it came from, so discovery decides which windows need a pattern by the same test plan uses to decide which windows an entry can claim: a named, standard, unminimized window, counted once wherever it is listed, a window on every space included. A full-screen window is counted too, though plan leaves it alone, because its `fullscreen` entry sits on a display beside the app's others and the validator's rule on one app twice on a display reads it. An app with one such window in the whole world gets a bare entry. An app with more gets an anchored, escaped pattern of each window's title, and a title that app's windows share anywhere in the world, or an empty one, cannot tell its windows apart, so none of the windows carrying it is recorded and each is named in the report. What observe could not read refuses both discover and plan, through one check over every screen: a screen whose spaces could not be read, a space whose type could not be read, or a space whose windows could not be read. An empty list there would otherwise be planned as empty: plan would create spaces that exist and miss windows that are there. Dock bindings that could not be read are said rather than counted as none: discover, which records no binding in v1, reports that they could not be read and why, and plan refuses `--bind` while they cannot be read, since every binding would look unbound, or while the spaces' uuids cannot be read, since a binding names its space by uuid. A bindings entry that is there but is not a table of bindings counts as could not be read. An app is one app to both whatever the case of its bundle id, as it is to macOS.

## The verbs

| Verb                                                     | Does                                                                                  | Changes                       | Exit              |
| -------------------------------------------------------- | ------------------------------------------------------------------------------------- | ----------------------------- | ----------------- |
| `utilz arngz <desk>`                                     | the same as `apply <desk>`                                                            |                               |                   |
| `apply <desk> [--dry-run] [--no-launch] [--no-create] [--bind] [--map <name>=<uuid>]` | observe, match, plan, execute, observe, report                        | windows, spaces, bindings     | 0, 1 or 2 (below) |
| `discover [--save <desk>] [--force]`                     | observe, print the live state as a desk; `--save` writes it                           | one desk file, with `--save`  | 0, or 2 on refusal|
| `diff <desk>`                                            | observe, plan, print what apply would do                                              | nothing                       | 0 same, 1 differs |
| `list`                                                   | the desks in the catalogue, one per line, with display and app counts; a desk that does not validate is named as invalid | nothing | 0, or 1 when any desk is invalid |
| `show <desk>`                                            | the desk, validated, as YAML                                                          | nothing                       | 0, or 2           |
| `delete <desk>`                                          | removes the file, naming it                                                           | one desk file                 | 0, or 2           |
| `init [--yes]`                                           | creates the catalogue; reports what Hammerspoon needs; with `--yes`, provides it      | see D16                       | 0, or 2           |
| `doctor`                                                 | every precondition, each named with its state                                         | nothing                       | 0, or 1           |

`--dry-run` on apply is observe plus plan, printed as the ops with their reasons, and nothing executed. `diff` is the same computation under a name that says what it is for.

## apply, in order

1. Preconditions, the same checks `doctor` runs: Hammerspoon running and reachable over IPC, Accessibility granted, separate spaces on, Stage Manager off. Any failure refuses with the check named, exit 2.
2. Read and validate the desk. Exit 2 on refusal.
3. `observe`.
4. Match the desk's displays to the observed screens (below). A mismatch refuses, naming the desk display and every candidate, exit 2; `--map` overrides one display at a time.
5. `plan`. With `--dry-run`, print the ops and stop, exit 0.
6. Execute `create_space` ops, then `observe` again, because ordinals now resolve to new ids.
7. Execute `launch` ops, waiting for each app's first window with a timeout of 20 seconds, then `observe` again, because the windows to place now exist. An app that is not installed is reported and skipped.
8. `plan` again against the fresh world, for `move` and `place` only.
9. Execute `move` then `place` for each window, in that order, because a cross-display move changes what the frame means. After each op, read back: a `move` that returned success while the readback shows the window still at home is recorded as failed, never as done.
10. With `--bind`, execute `bind` ops, then one `restart_dock`, then `observe` again, so that any change the Dock restart made is in the report.
11. Report, per desk app: placed, launched and placed, moved and placed, skipped (not installed), unseen (no window matched the pattern), or failed (an op whose readback disagreed). Exit 0 when every app is placed; 1 when any app is skipped, unseen or failed; 2 when nothing was attempted.

## Display matching

For each desk display, in order: a screen with the same UUID; else the one screen whose name and size both match; else, when name and size match more than one screen, the one whose position relative to the others matches `position` (`main`, `left`, `right`, `above`, `below`, read from the screens' frames); else no match. A desk display that matches no screen, or two desk displays that match one screen, refuse with every candidate listed. `--map left=37D8832A-...` binds one desk display to one screen UUID for this run and is reported in the output. Discovery records all four fields so that the next machine has the most to go on.

## Failures and the report

Nothing is silent. Every skipped app, every unmatched window, every op whose readback disagreed with its return value is a named line in the report and lifts the exit code to 1. A refusal before anything changed is exit 2 and names what refused. The one failure the design plans for specifically is the private API lying: `moveWindowToSpace` returning true with the window unmoved, which WP-01 measures; the readback after every op is there because of it.

## Testing: what runs where

| Layer                         | Where it runs                   | How                                                                                                              |
| ----------------------------- | ------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| CLI: verbs, catalogue, validator, rendering | bats, on every CI leg | a fake `hs` first on `PATH` that answers from fixture response files; `XDG_CONFIG_HOME` at a fixture catalogue      |
| Planner: `plan(desk, world)`  | `lua5.4` on the Linux leg, `lua` or `luajit` here | fixture desks and worlds, expected ops; the planner is written in the Lua 5.1 and 5.4 intersection               |
| Engine: `observe`, `execute`  | hv's machine, by hand           | the acceptance script in `opt/arngz/test/acceptance.sh`, run through Hammerspoon, its transcript recorded in `acceptance.md` as a hand run |

Lua becomes a declared language of the project (`intent lang init lua`), so `critic-lua` reads the module and `check all` covers it. CI's Linux legs install `lua5.4` beside the other apt packages.

## Decisions

- **D1** Hammerspoon is the engine. It holds the Accessibility grant, it is installed and running on hv's machine, and the private Spaces API becomes a Hammerspoon upgrade rather than our maintenance. A standalone Rust or Swift binary would reimplement `hs.spaces` and `hs.grid` and own their breakage, to save installing one cask.
- **D2** The CLI is bash in the Utilz shim format; the engine is a Lua module Hammerspoon loads. The CLI parses, calls and renders; the module observes, plans and executes.
- **D3** YAML, one file per desk, under the XDG config directory. Measured against TOML, above.
- **D4** A space is its ordinal on its display, with an optional name for people. Apply creates missing spaces unless `--no-create`, and never removes one.
- **D5** An app is a bundle id plus an optional window title pattern. No pattern means every window of that app takes the layout, which is Hammerspoon's own `hs.layout` convention. The same app on two spaces of one display needs a pattern on each entry.
- **D6** Displays match by UUID, then name and size, then position; a mismatch refuses by name; `--map` overrides one display per run. Position is compound, relative to the primary screen's centre: horizontal in left, centre, right and vertical in above, level, below, written `above-left`, `above-right`, `above`, `left`, `right`, `below-left` and so on, and `main` for the primary itself. A single word cannot separate hv's two identical panels, which both sit above the laptop (cc, 16 Oct, WP-03); the compound form can. Two screens that still tie are refused with both candidates listed.
- **D7** The desk declares its grid, and the planner computes frames from the screen frame and the grid. `hs.grid` is not used, because its grid is global state inside Hammerspoon and a pure planner cannot depend on it.
- **D8** Apps not running are launched and waited for, unless `--no-launch`. An app that is not installed is reported, skipped, and lifts the exit code.
- **D9** Missing spaces are created by default (hv's new-machine case), never removed.
- **D10** Dock bindings: discovery reads them; apply writes them only with `--bind`, and the flag exists only if WP-01 measures that a written binding takes. A flag that silently did nothing would be worse than no flag.
- **D11** Full-screen windows are recorded as `fullscreen` and left alone in v1.
- **D12** The planner is pure and tested on Linux; dry run and diff are the planner without execute; the execute half is hand-run on hv's machine and recorded as such, the showreel precedent.
- **D13** Exit codes: 0 every app placed; 1 something named was skipped, unseen or failed; 2 refused before anything changed.
- **D14** Move, then place, with a readback after each; WP-01 measures whether a frame survives a move.
- **D15** Only public `hs.*` calls. No private call of arngz's own.
- **D16** `init` installs the `hs` tool under `/opt/homebrew` (the default `/usr/local` is root-owned on hv's machine), and appends `require("hs.ipc")` to `~/.hammerspoon/init.lua` only with `--yes`, as one marked, idempotent line. Without `--yes` it prints what it would do.
- **D17** The request and response cross the IPC boundary as files, never as a shell-quoted string.
- **D18** Dependencies and `utilz doctor` (ruled by vc for cc, 16 Oct): `yq` is required and nothing softens it; the `hs` tool and Hammerspoon are `required: false`, reported as optional lines that say what they are for, because the catalogue verbs work without them and arngz's own `doctor` is where they become hard preconditions. A dependency entry may carry `app: <bundle id>`; on Darwin the framework checks it by asking LaunchServices through `NSWorkspace` (`URLForApplicationWithBundleIdentifier`, run as JXA), which does not launch the app. AppleScript's `path to application id` does launch it, measured by cc three times on Chess, and `mdfind` depends on Spotlight's index, so neither is used. On Linux an app dependency always reads as missing, and the line says so.
- **D19** `discover` takes `--grid WxH` and defaults to `8x4`, which is hv's own Hammerspoon grid (`hs.grid.setGrid("8x4")` in hv's `init.lua`), so a desk discovered on hv's machine snaps to the cells hv already thinks in.
- **D20** `hs -c` sometimes never returns after the module has finished, and `-t` does not end it (cc measured it three times in a row on `observe`, the response written within a second and `hs` still running at 20 s; the same happened to the spike at 70 s). The cause, guessed by dc from the `hs` manual and measured by vc: `hs` reads Lua from stdin whenever stdin is not a terminal, so under a tool shell's stdin `hs -c 'return 1'` hangs every time (3 of 3, killed at 15 s) and returns in under 0.1 s with `</dev/null` (3 of 3). So every `hs` call the CLI or a test makes takes its stdin from `/dev/null`, explicitly. The bash CLI as built was never exposed: it runs `hs` with `&`, and bash gives a background job `/dev/null` as stdin when job control is off, so removing the explicit redirect alone does not redden the test (cc measured that control); the hang was real for a caller in zsh, or any caller whose stdin stays open, which is every probe either of us ran from a tool shell. The contract keeps its defence anyway, because the next hang will have a different cause: the response file's appearance is the answer, the module writes it under a temporary name and renames it into place, the CLI watches for it under its own clock, and an `hs` still running after that is killed. The bats suite keeps a fake `hs` that replies and then hangs, and the CLI must return at once. Amended after the spike: the `hs` client also gives up 4 s after sending, whatever `-t` says when `-t` is absent, and a verb that pumps the run loop past that point dies silently; so every engine verb that can run longer than a few seconds (apply's moves, launches and re-observes) is scheduled through `hs.timer.doAfter` with the IPC call returning at once, the timer held in a global so it is not collected before it fires (dc), and its response file is the only answer the CLI waits for, on the CLI's own deadline. `-t 60` covers the short verbs.

- **D21** The move route (spike WP-01, 16 Oct): `move` within a display holds the window by its title bar through `hs.eventtap` and presses the Move-space shortcut (`ctrl+left`/`ctrl+right`, read from the symbolic hotkeys so a remapped key is used and an unset one refused) once per step along Mission Control's order, then lets go; across displays it drags the window over the edge the two displays share onto the target display, lets go, and continues within that display. Every step is read back at 0.5 s and a disagreement is reported as failed. The pointer is taken and put back; the refusals the spike names are the engine's (a mouse button or modifier down, the pointer moved more than 40 px, no grab point on the bar, no route between the displays). One window at a time; a mechanism the OS supports for its own users, and the only one that worked. `hs.spaces.moveWindowToSpace`, `hs.spaces.gotoSpace` and Dock bindings are not used for moves.
- **D22** A space's ordinal is its position in `com.apple.spaces`'s `SpacesDisplayConfiguration` list for its display, which observe already reads for bindings and uuids; `hs.spaces.allSpaces()` supplies ids and nothing about order, because on macOS 27 its order differs from Mission Control's.
- **D23** `init --yes` (dc, WP-06) makes the two links `hs.ipc.cliInstall` would make (`bin/hs` and `share/man/man1/hs.1` to the app's own copies) itself, because `cliInstall` runs inside Hammerspoon over the IPC that init is setting up; `ARNGZ_HS_PREFIX` overrides `/opt/homebrew`, so no test links into the machine; the config file is the one Hammerspoon's `MJConfigFile` preference names, `~/.hammerspoon/init.lua` when unset, refused when unreadable; and every change is checked before any is made, so a refusal leaves no link behind. Idempotency is by presence of `require("hs.ipc")` in the file, marked or not.
- **D24** `doctor` reads separate spaces, auto-rearrange and Stage Manager itself with `defaults read`, treating macOS 27's "Could not find key" and "Domain not found" and the older "does not exist" as unset, and asks the engine only about IPC and Accessibility, through `observe`.
- **D25** The CLI's `engine_ask` sends a request and returns 0 for an answer, 1 when nothing answered, 2 when nothing was asked and 3 when the engine answered with an error (a Lua error included), and never exits; `engine_call` refuses on its behalf for the verbs that stop on failure, naming the request file it kept.

## The open input: WP-01's spike

Everything above is written; one branch waits on a measurement. WP-01 runs dc's spike (`observe`, `move`, `bind`) on hv's machine and records the result here, under this heading. The observation files stay out of the repository, because they carry the titles of hv's windows; what is recorded is the measurement.

- **Outcome A, moves work**: apply is as written. `--bind` exists if the binding measurement also passed.
- **Outcome B, moves fail or lie, bindings take**: the `move` op is replaced by bind and relaunch: apply writes the app's binding, restarts the Dock once, and relaunches the app's windows on their bound space. Slower and visible, and macOS keeps doing it afterwards.
- **Outcome C, neither works**: apply places windows on the grid within each display's current space, the desk's space dimension is recorded by discovery but not enforced, and hv decides whether that is worth shipping.
- **Outcome D, the human's own move works**: a window is carried to another space the way a person does it, by a drag driven through public API (`hs.eventtap` holding the window at the screen's edge until macOS carries it into the adjacent space, or across displays), or through Mission Control, which `hs.spaces.gotoSpace` already drives through the Dock's accessibility tree. Slow and visible, one window at a time, but it is the mechanism the OS supports for its own users.

### Measured 16 Oct 2026

On hv's machine: macOS 27.0.1 (26A434), Hammerspoon 1.1.1, Accessibility granted, separate spaces on, auto-rearrange off, through the `hs` tool over IPC. The built-in display carried 13 spaces (one of them full-screen), each external panel one.

| Measurement                                                                                                     | Result                                                                                                                                                                                                                                                                                                                     |
| --------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `hs.spaces.moveWindowToSpace`: next space on the same display, then a space on another display, then home        | Returned `true` all three times and moved nothing. At 0.5 s and at 1.5 s after each call the window's spaces read `{1}`, its frame was unchanged and Accessibility still saw it. **Outcome A is closed**, and this is the lying case the readback after every op was designed for.                                      |
| `killall Dock` on its own, with an observation before and after                                                 | The Dock was back in 2 s. Every display kept its spaces, in order, and its active space; no window moved and none stopped being nameable.                                                                                                                                                                                 |
| A binding written as `defaults write com.apple.spaces app-bindings -dict-add com.apple.calculator <uuid>`, the uuid of VY229HF (2)'s space 1, then `killall Dock`, then `open -b com.apple.calculator` | The value read back from the preferences before the restart. Calculator opened on the built-in display's active space (#3), not on the bound one. The binding was removed through the preferences API (export, drop the key, import) and the Dock restarted again; the 14 bindings hv already had remain, untouched. |
| hv's 14 existing bindings                                                                                       | Every one is `AllSpaces` ("All Desktops"). So nothing on this machine shows a per-desktop binding working by any route, and whether the Dock's own menu still honours "This Desktop" on macOS 27 is the next measurement; it needs hv's hands, two clicks, and tells us both whether the mechanism lives and what the Dock writes. |
| The first desktop of the built-in display (space id 1)                                                          | Carries no UUID in the managed display data, so a binding cannot name it at all, whatever the Dock does with the others.                                                                                                                                                                                                  |
| hv's own two clicks: Calculator on VY229HF (2), Dock icon > Options > Assign To > This Desktop, then a launch from the shell with the mouse on the built-in display | The Dock wrote `com.apple.calculator = F775D982-...`, the key and value the spike had written by hand, and nothing else: the whole domain diffed against a later export differs only in timestamps and the current space. Calculator opened on VY229HF (2), the bound space, **and so did a control launched with no binding at all**: Calculator opens where its window last was, so that result says nothing about bindings. |
| The binding written again by `defaults write`, to the built-in's desktop 3 (`A6E2A621-...`), neither Calculator's last display nor the active desktop; `killall Dock`; `open -a Calculator` | **The binding took, for the display: the built-in switched from desktop 2588 to desktop 3 at launch.** The window did not follow: at 0.7 s, 1.2 s and 2.2 s it was on VY229HF (2)'s space, where it last was, and the frontmost app was the one living on desktop 3. A one-space binding moves the display to the space, not the window to the display. **Outcome B is closed**: bind-and-relaunch would switch desktops and leave the windows where they were. Removed again; the 14 bindings as found. |
| Outcome D by the edge: the window held against the built-in's right edge (dc's spike 2, `drag_to_next_space`)   | Nothing happened in 4 s at the edge, and the window was put back. One run.                                                                                                                                                                                                                                              |
| Outcome D by the keys: the window held, `ctrl+right`, then `ctrl+left` (`via = 'keys'`)                         | **Carried, 5 of 5 runs**, about 6 s each: at 0.5 s after each key the window's spaces read the destination alone, the display's active space was the destination, and the window was listed there and not at home. The frame ended at its home values every run; the spike's own `frame_restored` flag read false, from a readback taken before the frame settled. |
| Outcome D by desktop number (`via = 'desktop'`)                                                                 | Refused before the pointer was taken: Hammerspoon's reader of Mission Control's names answered "no display with specified id found". `hs.spaces.gotoSpace` reads the same tree, so neither is a route on this macOS.                                                                                                     |
| Across displays: the window dragged over the built-in's top edge onto VY229HF (2) and back (`drag_to_other_display`) | **Landed both ways**: screen and spaces read the destination at 0.5 s, the frame moved by the displays' offset and kept its size, and home, frame and pointer were restored.                                                                                                                                         |
| Across displays by `setFrame` alone, into VY229HF (2)'s coordinates and back                                    | The frame moved and the window drew on VY229HF (2), but its spaces still read the built-in's desktop at 0.5 s and 1.5 s, and the same on the way back. A frame set across displays moves the pixels and not the window's space; the drag moves both, so the drag is the route.                                           |
| The order of a display's spaces                                                                                 | `hs.spaces.allSpaces()` listed the built-in's spaces as 1, 3, 2588, 305, ...; `com.apple.spaces`'s `SpacesDisplayConfiguration` listed them 1, 3, 2588, 1733, ..., and `ctrl+right` from 2588 went to 1733. Mission Control's order is the plist's, and an ordinal counted along `allSpaces` is wrong.                 |
| `hs -c` running a verb longer than 4 s                                                                          | The client gave up at 4 s ("receive timeout", exit 69). A plain 12 s sleep still finished and wrote its file; the drag verb, which pumps the run loop while it holds the window, died silently after the timeout with 709 `hs.ipc ... already recursing` refusals in the console and no file. Both `-t 60` and a verb scheduled through `hs.timer.doAfter`, with the IPC call returning at once and the response file as the answer, completed. |

Standing after these, 16 Oct: **A and B are closed and D is open**, and the design takes D (D21): a window moves within a display by being held and carried with the Move-space shortcut, and across displays by being dragged over the shared edge, each step read back. `--bind` does not exist in v1 (AC-05.6: refused as unknown, since the one thing a binding does on this macOS is switch the display). C is not needed. The spike's result files and `hs` logs are in `/tmp/arngz-spike2/` and carry the test window's title, so they stay out of the repository.

## Out of scope for v1

Stage Manager and macOS's own window tiling (detected and refused); removing spaces; choosing among an app's windows by anything other than a title pattern; syncing desks between machines (they are plain files; copy them); a Hammerspoon hotkey that applies a desk (one line in `init.lua` once the module exists, and a later thread if wanted).
