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
arngz apply <desk> [--dry-run] [--no-create] [--map <name>=<uuid>]
arngz discover [--grid WxH] [--save <desk>] [--force] [--with-gaps]
arngz diff <desk>
arngz list
arngz show <desk>
arngz delete <desk>
arngz current
arngz which
arngz auto [--default <desk>]
arngz init [--yes]
arngz doctor
arngz log
arngz --help | -h
arngz --version
```

---

## Description

A **desk** is a named arrangement of windows: for each display, for each space on it, which apps live there and where on a grid their windows sit. `arngz <desk>` puts this machine's windows where the desk says; `arngz discover --save <desk>` records the arrangement on screen now as a desk.

`apply`, `discover`, `diff`, `which`, `auto` and `doctor`'s IPC check reach Hammerspoon through its `hs` tool, so they need Hammerspoon running with `hs.ipc` loaded, which `arngz init --yes` sets up.

**Platform**: the engine (`apply`, a bare desk, `diff`, `discover`, `which`, `auto` and `init --yes`) needs macOS and Hammerspoon. Elsewhere each refuses, exit 2, before it reads or asks anything, saying it needs macOS and Hammerspoon and that list, show, delete, current and log work here. There, `init` makes the catalogue alone, and `doctor` says the engine is not available and checks the catalogue alone.

**`apply` takes the pointer.** macOS gives no working call to move a window to another space, so apply moves a window the way a person does: it holds the window by its title bar and presses Mission Control's Move left/right a space shortcut, once per step, or drags it over the edge two displays share. A move that would carry a window past a full-screen space goes round through another display instead, as the Full-screen windows note below says. Keep your hands off the mouse and keyboard while it runs. If you move the pointer, apply lets go and pauses until the pointer is still, then goes on with the move it was making, as the note on pauses below says. It puts the pointer back and gives focus back when it is done. The two shortcuts must be set in System Settings > Keyboard > Keyboard Shortcuts > Mission Control, or apply refuses. Some apps' windows do not follow a held pointer, Dictionary's and Stickies' among them, so apply checks that the window moved with the pointer before it presses a key; when it did not, apply lets go and reports that entry as failed. Every step is read back, and a move macOS did not make is reported as failed.

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

### apply

`apply <desk>`, or `arngz <desk>`, puts this machine's windows where the desk says, in this order:

1. The desk is read and validated. A desk that does not validate is refused, exit 2.
2. The three settings `doctor` checks are read: separate spaces on, auto-rearrange off and Stage Manager off. The first that does not hold is refused, exit 2, with its fix. `--dry-run` skips this step.
3. Hammerspoon observes the screens, spaces and windows, and plans. Before anything changes it refuses, exit 2, when it has no Accessibility grant, when the desk cannot be planned on this machine, eg a display that matches no screen, or, when a window has to move, when the Move left/right a space shortcuts are not set or a mouse button or modifier key is held down.
4. A display with more desktops than the desk names has its extra empty desktops removed. A display with fewer has the missing spaces created, unless `--no-create` is given, which does not stop the removals. Then apply plans again against what is on screen. apply never launches an app: one that is not running is left so, and the report says so.
5. Windows are moved to their spaces and placed on their cells, and every step is read back. Before apply takes a window by its title bar, it raises the window and checks, for up to 1 s, that a press there lands on that window's own bar. A window still covered by another app's window fails, naming that app. So does a window whose raise switched its display to another desktop, and a window whose frame does not follow the held pointer, which fails before any key is pressed.
6. The mouse button, the pointer and the focus are given back. Focus goes back only to a window on a desktop that is still shown.

The report names every app entry in the desk with its outcome: `placed`, `moved and placed`, `not running` (the app is not running, or not installed), `unseen` (running, with no window of it that matches and can be named), or `failed`, with why. `apply` exits 0 when every entry is placed, not running or unseen, 1 when any failed, and 2 when it refused before changing anything. An entry that is not running, and an unseen one, have nothing to arrange, so each is reported and counts against nothing, except an unseen entry while a window could not be read at that moment, since that window may have been the entry's: then the entry counts as not placed. An app that was running when apply began and quit during the run is `failed`.

- **Windows on desktops not shown.** Hammerspoon's window filter is the one way to name a window on a desktop that is not shown, and it can lose such a window, as it did after desktops were added or removed; it names the window again once that desktop is shown. A running app whose window is there then reads as unseen. Before it changes anything, and again after it adds or removes desktops, `apply` shows each such desktop once, through Mission Control: only a desktop that holds a window of a running app the desk names and the plan leaves unseen, display by display and in Mission Control's order. While a desktop shows, arngz names the app's windows on it. Then each display shows the desktop it showed before, and `apply` plans again. Running... says `finding windows: showing desktop 2 on main` meanwhile. A full-screen space is never shown for this. The step stops after 20 s; an app it did not reach stays unseen, and says its window is not named yet. The run log's finished line counts the desktops shown. At the end of every `apply`, each display shows again the desktop it showed when the run began, if that desktop still exists and is not a full-screen space, before focus goes back to the window that had it; a show that fails is said and counts against nothing. `diff` and `--dry-run` never switch desktops: they say of such an entry `its window is not named yet: it is on desktop 2 on display main, which apply shows`.
- **When Hammerspoon's window filter fails.** The filter is the one way to name a window on a desktop not shown, and once it fails it can go on failing until Hammerspoon's config is reloaded. When it fails at apply's read and leaves an entry unseen, apply refuses before anything changes. When it fails at the read after apply has created desktops, apply finishes its moves. Either way, the CLI then reloads Hammerspoon's config, waits up to `ARNGZ_RELOAD_TIMEOUT` seconds, 30 unless set, for Hammerspoon to answer from the fresh config, and runs apply once more. One line before the report says so: `Hammerspoon's window filter failed (<where>), so arngz reloaded Hammerspoon's config and ran apply again`. The second run's report and exit are the command's. A reload runs Hammerspoon's config from the start, so the second run waits the 5 s for the displays to settle. If the filter fails again, each entry it leaves unseen says so, with the fix to quit Hammerspoon, open it again, then run arngz again. A reload refused because another arngz run is live leaves the first answer, with the fix to run it again when that run has finished. If Hammerspoon does not answer in time, apply exits 1. A read in which the filter failed never replaces a plan made from one in which it ran. `--dry-run` and `diff` change nothing, so they never reload: an entry they find unseen says the filter failed, with the fix to run it again, then, if it fails again, to reload Hammerspoon's config (Reload Config in its menu).

- **An app that fixes its own window size** cannot fill the cells the desk gives it. A window that reached the origin the desk put it at, at a size the app enforces, is `placed`, and the report says so in brackets after the outcome: `placed (placed at the app's own size, 375x667)`. It is as well placed as it can be, so it counts against nothing. A window that reached the wrong origin is `failed` whatever its size.
- **Creating a space** asks the Dock through Mission Control. When the Dock does not open Mission Control for Hammerspoon ("unable to get Mission Control data from the Dock"), the create is not tried again, since each try asks the Dock to open it again while it may still be opening, and no other desktop is asked for in that run, on any display, since Mission Control is one for all of them. The failure says the Dock did not open Mission Control, and its fix is to add the desktop in Mission Control by hand, then run it again. Any other call that reports no space made none, and is tried up to four times, a fifth of a second apart. A call that reports a space is made **once**, and the attempts after it only re-read the desktop count, because the desktop list can lag behind a creation and a count read in the same breath as one cannot be the trigger for another. A cause that lasts is said once for the display, not once for every space the desk asks for, and the later ones say they were not tried again. A display the plan named and which is no longer there is not retried, since waiting cannot bring it back. If the desktops go up by more than the one asked for, apply says so by name rather than counting it a success.
- **Removing an extra desktop.** A display with more desktops than the desk names has its extra empty desktops removed before any window moves, so that its desktops line up with the desk's. A desktop is empty when every window on it is on another space too, or is not one a person places. A window a person places is at the window server's normal layer (layer 0), whether or not Accessibility can name it. An always-on-top or floating window, an overlay, or one of macOS's own windows for the desktop (its backdrop and the menu bar) is at another layer, so it holds no desktop: arngz can remove a desktop while such a window is on it. arngz reads the window server's list for this, through `osascript`, once before the plan and again before each removal. If it cannot read the list, it removes no desktop and says why. arngz never removes a full-screen space, a desktop of a display the desk does not match, or a display's only desktop. When more desktops are empty than the display has extra, arngz removes the ones whose removal leaves the most desk entries with a window of their app already on their own desktop. When a monitor is plugged in, macOS puts a new empty desktop first on it, before the desktops it brings back, and that is the one removed. Between equal choices, arngz keeps the desktop the display shows, then removes the later ones. Before each removal, arngz shows the desktop through Mission Control and reads back that the display shows it, then shows the desktop that takes its place. It removes the desktop only while the display's desktop list is still the one that check read, and then reads back that exactly that desktop went. A removal that cannot be done is said, and counts against nothing: the display keeps its extra desktop. If another desktop went, the removal fails, naming both, with the fix to check the desktops on that display in Mission Control, then run arngz apply again, and no later removal is tried. The Dock's Mission Control error stops removals and creates alike. `diff` and `--dry-run` show each removal first, and plan the moves for the desktops that stay. An extra desktop that arngz cannot remove is said after the rest and counts against nothing, so a desk whose only difference is one reads as no change.

- **Displays.** A desk display that matches no screen, or more than one, is refused, with every candidate screen named. `--map <name>=<uuid>` binds the desk display called `<name>` to the screen with that UUID, for this run only.
- **The order of a display's desktops** comes from `com.apple.spaces`, where macOS's record of that display is current. macOS rewrites that record only at the next display change, so after a change, and for a display just attached, arngz takes the order macOS lists the desktops in now. The run log says which it took for each display. Every step of a move reads its desktop back, so an order that proves wrong fails that move, by name. A window already on the desktop the order names, and `discover`, rest on the order alone.
- **The displays settle first.** A display that has just been plugged in or out changes several times in a few seconds. Before it reads the screens, apply waits until no display has changed for 5 s, for up to 20 s, and its toast says it is waiting. If the displays are still changing at 20 s, apply refuses, exit 2, before anything changes: run it again once they have stopped. An apply that finds no watcher of its own running, as after Hammerspoon's config is reloaded, waits the full 5 s, since nothing has watched the displays before it.
- **Full-screen windows** are left alone. A full-screen window is a space of its own, and takes no ordinal on its display. A held window cannot be carried into one, so a move that would pass one goes round through another display: one that shows a desktop and is joined to the window's display by shared edges, the fewest crossings first. The window is dragged there and read back, its own display steps past the full-screen space with nothing held, and the window is dragged back. With no such display the move fails, naming the full-screen apps in the way, and its fix says the way out: take them out of full screen, or attach a display, show a desktop on one, or arrange one to share an edge with the window's display, as the case is. A move that fails once its window is on the other display leaves it there, and says where it is.
- **`--dry-run`** prints the plan, one line per change with its reason, exactly as `diff` does, changes nothing, and exits 0; `diff` is the one whose exit says whether anything would change.
- **The CLI waits** up to `ARNGZ_APPLY_TIMEOUT` seconds, 600 unless set, for apply's report. If it gives up, apply may still be running, so it says so and exits 1, naming the request it kept.
- **The current desk.** An apply that ran makes its desk the current one, which `arngz current` prints. A `--dry-run` and a refusal do not.
- **The sizes apps hold their windows at.** When an apply reads a window back at its cells' origin at a size its app holds, it records the app, the cells' size and the size held in `$XDG_STATE_HOME/arngz/own-sizes`. `diff` then reads a window at its recorded size as in place, and `apply` rechecks it, setting its frame and reading it back rather than counting it a change, so an app that lets go is re-sized and its record cleared. Deleting the file is safe: until the next apply, `diff` reports those windows as differences again, and that apply places them and records them afresh.
- **A pause for the pointer.** When the pointer moves more than 40 points from where apply put it during a move, apply lets go of the window at once, and the window stays where it was let go. apply then waits until the pointer has stayed within 4 points of one place for 2 s, with no mouse button and no modifier key held. Then it reads each display's shown desktop again and runs that move again, from where its window is now. A move that paused and then took says so in brackets after its outcome, eg `moved and placed (paused 3 s for the pointer)`, and counts against nothing. A pause that waits 30 s without that gives up: the move fails, saying why, with the fix to keep your hands off the mouse and keyboard until arngz finishes, then run arngz apply again, and every move after it is reported as not tried. A run pauses at most three times, and the fourth time the pointer is taken, the moves end in the same way.
- **One apply at a time.** A second `apply` asked for while one is running is refused, exit 2, with the time the first was asked for. If arngz says an apply is running when none is, a crashed apply left that mark: reload Hammerspoon's config (`hs.reload()` in its console) to clear it.
- **Reads during an apply.** `doctor`, `diff`, `discover` and `apply --dry-run` are answered between apply's phases, so what they report is a machine whose windows are still being moved: a `diff` asked for during an apply names the moves it has still to make.

### discover

`discover` asks Hammerspoon what is on screen and prints it as a desk: every display with its `uuid`, `name`, `size` and `position` (the name without the " (2)" Hammerspoon adds to a second panel of the same name), every desktop space in order, and every standard window on it, snapped to the grid.

- **Snapping** puts each window edge on the nearest cell edge. When a window was not exactly on its cells, the desk says how far, beside the layout: `misfit: 3px`. A window that spanned part of a cell is snapped and named in the report.
- **A full-screen window** is recorded as `layout: fullscreen`, under the desktop before its space.
- **An app with more than one window** gets a `window` pattern on each, made from the window's title, because an entry with no pattern takes every window of its app. The pattern is the title without what leads it up to the first letter or digit (a glyph a terminal puts in front, a shell's `-`), escaped and anchored at neither end, so `◑ utilz-dc` gives `utilz%-dc` and still matches when the glyph changes. Where that would also match another window of the app, discover anchors it at its end, then uses the exact title. The report names every window it pinned and the pattern it wrote; tighten or loosen one in the desk if its title will move.
- **One line for each space** opens the report, eg `main space 1: 6 named, 3 recorded`. Where that space has gaps (below), the line ends with how many, eg `, 1 not recorded`. A space can name more windows than it records and have no gap: a minimised window, a window on every space, Hammerspoon's own windows and windows that are not standard are named and not recorded. `arngz log` shows those counts for each space, with the windows Accessibility could not name and the window list's totals.
- **Not recorded, and said**: the Dock's app bindings, which a desk does not hold.
- **A window lying mostly outside its display's usable area** is not recorded either, and the report says so with its centre and that area. A window belongs to the display its middle is on; one parked on a monitor the desk does not describe would otherwise be snapped into the edge cell, which the next `apply` then fails because that cell is narrower than the app will go. A window hanging over an edge with its middle still inside is recorded as it always was, with its misfit. The measure is the usable area, as snapping is, so it excludes the menu bar and the Dock rather than the whole panel.

The desk goes to stdout and the report to stderr, so `arngz discover > desk.yaml` keeps the desk alone. `--save <desk>` writes it into the catalogue instead, refusing an existing desk unless `--force` is given, and makes it the current desk. Either way, the desk is checked by the validator first. A desk saved is written from one reading of the screens, so `--save` first waits for the displays to settle, as apply does, and if they are still changing at 20 s it refuses, exit 2, and writes nothing. A plain `discover` only prints what it sees, and does not wait. A read in which Hammerspoon's window filter failed is never a desk, since it leaves out the windows on desktops not shown, and `--save --force` writes the whole desk. So the CLI reloads Hammerspoon's config and runs discover once more, as apply does. If the filter fails again, discover refuses, exit 2, prints and saves nothing, and its fix is to quit Hammerspoon, open it again, then run arngz again.

Before it records, `discover` shows each desktop that is not shown and holds a window of a running app it could not name, once, through Mission Control, names that app's windows, shows each display the desktop it began on again, and reads the screens once more; a plain `discover` does so too, since it prints the desk a save would write. A window named by one read stays named in the reads after it while it is open. A window of a size no person uses (under 50 points a side) is left out of this. Many apps keep windows that no person sees, so a window counts only when macOS draws it while its desktop is shown: the window list is read at the start for the desktops shown, and at each desktop discover shows. A window of a person's size that it still could not name, and that macOS draws, is a gap, one line each on stderr: `not recorded: Console on desktop 3 on main: <why>`, where the why says what happened to that desktop. A window on a desktop discover could not show, or where it could not read the window list, stays a gap, since nothing judged it. A hidden app's windows are not drawn. When discover names none of a hidden app's windows, it leaves them out with no gap, and the report names that app on one line. An unnamed window that is not drawn, minimised or of a hidden app that has other windows named, cannot be told from a window no person sees, so it is left out and not said. A plain `discover` with gaps prints the desk and exits 1. `--save` with gaps refuses, exit 2, and leaves the desk file and the current desk as they were, `--force` or not, since `--force` only means overwrite. Its fix names the desktops to show where showing can help, says Save Desk again where a window came late, and always offers `--with-gaps`, which saves the desk without them and exits 1; `arngz log` names each gap by its window. A window list that could not be read at the start refuses `--save` unless `--with-gaps` is given, since no gap could be found. Save Desk from Menuz does not pass `--with-gaps`, so a gap there is a refusal and its notice.

### Toasts

While `apply` runs, Hammerspoon shows a toast at the bottom of the main display, however the apply was started: from Menuz, in a terminal, or by `auto`.

- **Starting** names the desk while arngz reads the screens and windows and makes its plan.
- **Running...** is rewritten in place as each wait and each step begins, eg `5 of 12: moving Slack to desktop 2 on left`. A move that goes round through another display, past a full-screen app, ends by naming it, eg `5 of 12: moving Slack to desktop 2 on left, round through laptop`, and a long line is cut before that part, never in it. A display's extra empty desktops are removed before any window moves, eg `1 of 12: removing empty desktop 1 on left`, and the wait after the desktops are removed or added says `waiting for macOS to record the desktop changes`. From the first step it also says `Hands off the mouse and keyboard until it finishes`, because arngz moves the pointer itself.
- **Paused** comes when you take the pointer during a move: the apply waits, and the toast says `Paused: waiting for the pointer to be still for 2 s (up to 30 s)`. When the pointer is still, the apply goes on with that move, and the toast shows its step again.
- **Finished** says what happened: how many entries were placed, already in place, not found, not running or failed, each only when there were any, the desktops removed and added, the extra desktops it left because it could not remove them, how many times the apply paused for the pointer, and the time taken. A busy run's counts take another line, so no count is cut. A line under it names the apps that are not running, since apply never launches one. A refusal says that nothing moved, why, and its fix. A run with problems gives the words of the first entry that counts against it, labelled for what it was, `Not found:` or `Failed:`, and, where it names one, its fix. A run that failed says where it stopped and why, and `arngz log` has the rest. Finished stays up 5 s after a clean run and 15 s otherwise.
- **A reload.** When Hammerspoon's window filter fails, arngz reloads Hammerspoon's config and runs the command again, once. The first run's Finished says `Reloading Hammerspoon, then running again: its window filter failed`, and the reload takes that toast down. Each toast of the run again says `(after a reload)` after the desk's name, and its Starting says `Starting again`.
- **A second apply** asked for while one runs is refused, and says so in a small toast of its own above the running one, which carries on.
- **`discover`** (Menuz's Save Desk...) shows Finished alone: what it read, its displays, desktops and windows, and the time taken, or why it was refused. It answers inside one call to Hammerspoon, which draws nothing until that call returns, so it has no Starting or Running. The desk file is written after the read; a write that fails is said on stderr, and Menuz's notice shows it.

A toast takes no click and no focus: a click on it goes to the window under it. It stays in view while arngz switches desktops, and steps out of the way of a window arngz is about to take by its title bar. The other verbs show none. A refusal before Hammerspoon is asked, such as a desk that does not validate, shows none either: the CLI's message says it, and Menuz's notice for a non-zero exit. A toast that cannot be drawn changes nothing else: the apply runs and reports as it would without it, and the run log says why.

### The start, running and end marks

A run that can take the desktops, the pointer or the keyboard marks its start, its work and its end, so you know when to use the mouse and keyboard again. These runs are `apply` (not `--dry-run`), `discover` (plain and `--save`), and `auto` when it applies. `diff`, `apply --dry-run` and the other verbs make no mark.

- **The start.** A rising sound, and a small toast at the bottom right of the main display: `arngz: starting`. It stays until the next mark takes its place.
- **Running.** When the CLI first asks Hammerspoon for the run's work, the toast says `arngz: running`, with no sound, until the end mark takes its place. While `discover --save` or `apply` waits for the displays to settle, it says `arngz: running` too. A run refused before that ask, eg by a preference that does not hold, goes from `arngz: starting` to its end.
- **The end.** A falling sound, and the toast says how the run ended for 3 s: `arngz: done` (exit 0 or 1; Finished and the report say what happened), `arngz: stopped: refused` (exit 2), `arngz: stopped: interrupted` (Ctrl-C or TERM), or `arngz: stopped: exit <n>`. The sound is the same for each: arngz has let go.
- **When the CLI stops waiting** for an apply (`ARNGZ_APPLY_TIMEOUT`), the apply may still be at work. Then no sound plays, and the toast says `arngz: still running in Hammerspoon (arngz stopped waiting after <n> s)`. When the apply finishes, Hammerspoon plays the falling sound and shows its end: `arngz: done`, `arngz: stopped: refused`, or `arngz: stopped: error`.
- **When the apply finished and its answer never came**, Hammerspoon says so when the CLI stops waiting. Then the CLI plays the falling sound, and the toast says `arngz: ended with no answer: see arngz log`. `arngz log` shows what the run did.

The sounds are macOS's own screen-recording sounds, and the CLI plays them, so they come even when Hammerspoon does not answer. `ARNGZ_SOUNDS=off` turns them off. The mark toasts are apart from the toasts above, and step out of the way of a grab as they do. A CLI killed with SIGKILL makes no end mark and no falling sound: its mark goes when twice the run's longest wait has passed. So does the mark of an apply the CLI stopped waiting for when Hammerspoon does not answer then, since the CLI cannot tell whether the apply still works. The run log has a `mark` record for each mark, and for a mark that could not be drawn.

### current

`current` prints the name of the desk the screen was last arranged as. An `apply` that ran records it, whatever its report says, because windows may have moved. A `discover --save` records the desk it saved. A `--dry-run`, and a refusal before anything changed, leave the record as it was. `delete` of that desk clears the record.

`current` prints nothing and exits 1 when no desk is recorded, or when the recorded desk has since left the catalogue, so `$(arngz current)` is empty then. A record that exists and cannot be read is said by name, and exits 1 too. It reads one file and asks Hammerspoon nothing, so it is quick enough to run at every open of a menu.

When the record cannot be written, the `apply` or `discover` that tried says so on stderr and keeps its own exit. The record then still names the desk before, so `current` lags behind that apply until the next one that records.

### The run log

Every run of `apply`, `diff`, `discover`, `which`, `auto`, `doctor`, `init` and `delete` appends what it saw, planned, did and read back to `${XDG_STATE_HOME:-$HOME/.local/state}/arngz/arngz.log`, beside `current`. `list`, `show`, `current` and `log` only read, and log nothing. The log puts nothing on screen. `arngz log` prints the last run, from its start to its end.

- **One record per line**: `<time> <run> <source> <event> <text>`. `time` is UTC, to the second from the CLI and to the millisecond from the engine. `run` is the run's id, the same on every record of one run. `source` is `cli`, `engine`, or `displays` for the display watcher, whose records carry `-` as their run. `event` is one fixed word per kind of record, so `grep` picks out one kind.
- **The CLI's side**: `start` (arngz's version, the tree that ran, the verb and its arguments, and whether Menuz or a shell called it); `request`; `hs` (its pid and its deadlines); `kill`, when the CLI stopped hs and why, which once its response has come is only after hs has had 3 s to exit on its own; `answer` (how the asking ended); `refused`, with a refusal's words; and `end`, the exit code and the seconds the run took.
- **The engine's side**: `start`, then the displays at the run's start and, for `apply`, again at its end. For each display there is a `screen` line, its desktops as they are `live`, where com.apple.spaces has each one `filed` (a desktop filed under another display is a visitor), the `order` taken and where it came from, com.apple.spaces or the live list, with why, the `windows` arngz can name on each desktop, and every `record` com.apple.spaces keeps that holds desktops, then one line counting the entries that hold none. Then the `plan`, each `phase`, each `wait`, each `op` with what it read back, each `step` of a move, the desktops a creation added, the `report`, and each progress `point` the toasts are told.
- **The display watcher.** The first engine call in a Hammerspoon session starts a watcher. Each display change is a `change` record, followed by a `snapshot` of every display's desktops at once and 5, 30 and 120 seconds after it. A run's displays record says how long ago the displays last changed. A reload of Hammerspoon's config stops the watcher, and the next run starts it again. After `utilz use brew`, reload Hammerspoon's config so the dev tree's watcher stops.
- **Its size** stays under `ARNGZ_LOG_MAX` bytes, 4 MiB unless set. At a run's start, a log at or over that moves to `arngz.log.1`, replacing the older one, so there are never more than the two.
- **A log that cannot be written** is said once, on stderr, and the run goes on with its own exit.

### which and auto

`which` prints the name of the desk the screens in front of you are, and changes nothing. A desk fits when each of its displays matches a distinct screen **and** every screen present is matched. Both halves matter: a desk that describes the laptop alone matches the laptop screen whatever else is plugged in, so without the second half it would be the answer at every site. The report, on stderr, names every desk and why it did or did not fit, so the name alone comes back on stdout.

It exits 0 and prints the name when one desk fits; 1 when none does; and 2 when the question has no one answer, which is more than one desk fitting with none of them current, or the engine refusing. When several fit and one of them is the current desk, that one is the answer, because a site with two desks describing the same screens should go on doing what it is doing.

`which` asks Hammerspoon which screens are there, so unlike `current` it is not cheap enough to run at every open of a menu. Use it in what a menu item runs, or in a parameter's default, not in a label.

`auto` applies the desk `which` found, and is otherwise `apply`: its report, its readbacks and its exit are apply's.

- **`--default <desk>`** is applied when no desk fits, and the run says that it fell back and to what. Without it, nothing moves and `auto` exits 1, saying to save a desk for here. A `--default` that names no desk, or one named like a verb, is refused before Hammerspoon is asked anything, so a typo costs nothing.
- **A default moves windows for a site its desk was not recorded at.** A laptop-only default puts the apps on the laptop screen even with monitors plugged in, which is worth knowing before choosing one.
- **More than one desk fitting** stops `auto` too: nothing moves and it exits 2, naming them.
- **Just after a display change**, a passing layout could fit the wrong desk, so `auto` waits for the displays to settle before it asks which desk this is, as apply does, and refuses, exit 2, with nothing moved, if they are still changing at 20 s. `which` alone changes nothing, and does not wait.

### diff

`diff <desk>` prints what `apply` would do, one line per change with its reason, and changes nothing: it asks Hammerspoon for a plan, never for an action. Like `which` and a plain `discover`, it reads the displays as they are, and does not wait for them to settle. It exits 0 when this machine already matches the desk, and 1 when it does not. An `unseen` entry, an app running with no window to match, is printed and counts against nothing, as in `apply`'s report, unless a window could not be read just then. A window discover found on a hidden space may read as `unseen` when Accessibility cannot name it at that moment.

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

A setting that was never changed takes macOS's default, and the line says so. `doctor` needs no Hammerspoon to run: without one it names it as missing and skips the two checks only Hammerspoon can answer. When Hammerspoon is running and does not answer in time, the IPC line says it is busy or hung, not unreachable.

`init` creates the catalogue and reports what Hammerspoon needs. `init --yes` provides it. It links the `hs` tool under `/opt/homebrew` as Hammerspoon's own `hs.ipc.cliInstall` would, from the copy inside Hammerspoon.app. It appends one marked line, `require("hs.ipc")`, to Hammerspoon's config, which is `~/.hammerspoon/init.lua` or the file Hammerspoon's `MJConfigFile` preference names, and then asks you to reload that config. A config that already requires `hs.ipc`, marked or not, is left alone, so a second run changes nothing. An `MJConfigFile` that is not a full path or one under `~/` is refused by name, and so is one that is set and empty, which Hammerspoon takes as a config path that loads nothing. Whatever `--yes` cannot do, it refuses before changing anything.

### The validator

Every verb that reads a desk validates it first, and refuses with exit 2 on any of: an unknown key; a `grid` that is not `WxH`; a `layout` that is neither `x,y wxh` inside the grid nor `fullscreen`; two displays with one `name`; a display whose `match` carries neither `uuid` nor `name`; the same `app` twice on one display without a `window` on each; a desk named like a verb. Each refusal names the desk, its file, the path in it, and the value, and every refusal in a desk is reported, not just the first.

---

## Verbs

| Verb            | Does                                                                                    | Exit                   |
| --------------- | --------------------------------------------------------------------------------------- | ---------------------- |
| `<desk>`        | the same as `apply <desk>`                                                              | as apply               |
| `apply <desk>`  | arrange this machine's windows as the desk says, and report each app's outcome          | 0, 1, or 2             |
| `discover`      | print the arrangement on screen now as a desk, or save it with `--save`                 | 0, 1 with gaps, or 2   |
| `diff <desk>`   | print what apply would do, one line per change with its reason, and change nothing      | 0 same, 1 differs, 2   |
| `list`          | each desk with its display and app counts; an invalid desk is named on its own line     | 0, or 1 if any invalid |
| `show <desk>`   | the desk, validated, exactly as stored                                                  | 0, or 2                |
| `delete <desk>` | remove the desk's file, naming it; a desk that no longer validates can still be deleted | 0, or 2                |
| `current`       | the desk applied or saved last; nothing and exit 1 when none is recorded or it is gone  | 0, or 1 if none        |
| `which`         | the desk the screens present are, and change nothing                                    | 0 one, 1 none, 2       |
| `auto`          | apply the desk the screens present are, or `--default` when none fits                   | as apply, 1, or 2      |
| `init`          | create the catalogue and report what Hammerspoon needs; with `--yes`, provide it        | 0, 1, or 2             |
| `doctor`        | every precondition, each with its state, and what fixes each one that does not hold     | 0, or 1 if any fails   |
| `log`           | the last run, from the run log; it changes nothing and asks Hammerspoon nothing         | 0, or 1 if none logged |

### Options

| Option                | Verb       | Effect                                                                                     |
| --------------------- | ---------- | ------------------------------------------------------------------------------------------ |
| `--dry-run`           | `apply`    | print the plan and change nothing                                                          |
| `--no-create`         | `apply`    | do not create missing spaces; still remove extra empty ones                                |
| `--map <name>=<uuid>` | `apply`    | bind one desk display to one screen for this run                                           |
| `--grid WxH`          | `discover` | the grid windows are snapped to; 8x4 when absent                                           |
| `--save <desk>`       | `discover` | write the discovered desk into the catalogue                                               |
| `--force`             | `discover` | with `--save`, overwrite an existing desk                                                  |
| `--with-gaps`         | `discover` | with `--save`, save a desk that leaves out the windows arngz could not name, and name them |
| `--yes`               | `init`     | do what init reports Hammerspoon needs, rather than print it                               |
| `--help`, `-h`        |            | print this help                                                                            |
| `--version`           |            | print arngz's version                                                                      |

An option that takes a value also takes it after `=`: `--map=left=<uuid>`, `--grid=12x8`, `--save=zeop1`. `--map` may be given once per desk display.

---

## Examples

```bash
arngz init                    # create the catalogue, and say what Hammerspoon needs
arngz init --yes              # and provide it
arngz doctor                  # every precondition, each with its state
arngz discover > desk.yaml    # the arrangement on screen now, as a desk
arngz discover --grid 12x8 --save zeop1   # record it in the catalogue
arngz discover --save zeop1 --force       # and replace it later
arngz list                    # what desks there are
arngz show zeop1              # one desk, validated
arngz diff zeop1              # what apply would change, changing nothing
arngz apply zeop1 --dry-run   # the same plan, from apply
arngz zeop1                   # arrange the windows; hands off the mouse
arngz apply zeop1 --no-create # only on spaces that exist; extra empty ones still go
arngz apply zeop1 --map left=37D8832A-2D66-02CA-B9F7-8F30A301B230   # bind a display
arngz delete old              # remove a desk
arngz current                 # the desk applied or saved last
```

---

## Files

- `${XDG_CONFIG_HOME:-$HOME/.config}/arngz/desks/<desk>.yaml`: one desk.
- `${XDG_STATE_HOME:-$HOME/.local/state}/arngz/current`: the current desk's name, which `apply` and `discover --save` write and `delete` clears.
- `${XDG_STATE_HOME:-$HOME/.local/state}/arngz/own-sizes`: the sizes apps hold their windows at, which `apply` writes and `apply` and `diff` read.
- `${XDG_STATE_HOME:-$HOME/.local/state}/arngz/arngz.log`, and `arngz.log.1` before it: the run log, which `arngz log` reads.
- `${TMPDIR:-/tmp}/arngz.XXXXXX/`: one call to Hammerspoon, with its `request.json` and `response.json`. It is removed after a call that went well, and kept and named after one that did not.

---

## Environment

- `XDG_CONFIG_HOME`: where the catalogue lives; `$HOME/.config` when unset.
- `XDG_STATE_HOME`: where the current desk and the own sizes are recorded and the run log kept; `$HOME/.local/state` when unset.
- `ARNGZ_LOG_MAX`: how many bytes the run log may reach before a run moves it to `arngz.log.1`; 4194304 (4 MiB) when unset.
- `ARNGZ_HS_PREFIX`: where `init --yes` links the `hs` tool; `/opt/homebrew` when unset.
- `ARNGZ_HS_TIMEOUT`: how many seconds one call to Hammerspoon may take; 60 when unset, 180 for `discover`, which reads every window on every desktop in one call, and 5 for a reload and for each check after it that Hammerspoon is back.
- `ARNGZ_APPLY_TIMEOUT`: how many seconds the CLI waits for apply's answer; 600 when unset. Hammerspoon may still be working when it gives up, and it says so.
- `ARNGZ_RELOAD_TIMEOUT`: how many seconds the CLI waits, after it reloads Hammerspoon's config because the window filter failed, for Hammerspoon to answer from the fresh config; 30 when unset.
- `ARNGZ_SOUNDS`: `on` or `off`, whether the start and end marks play their sounds; `on` when unset. Any other value is refused, exit 2.
- `ARNGZ_SOUND_START`, `ARNGZ_SOUND_END`: the sound files the start and end marks play; macOS's `begin_record.caf` and `end_record.caf` when unset.
- `TMPDIR`: where each call's request and response are written; `/tmp` when unset.

---

## Exit Status

- `0`: done.
- `1`: `apply` saw no window for an entry while a window could not be read, found an app gone that was running when it began, or a move or place did not take, each named in its report; `apply` was sent and did not answer within `ARNGZ_APPLY_TIMEOUT`, so it may still be running; `apply`'s engine failed rather than refused, which can come after windows moved, so its response is kept and named; `apply` or `discover` reloaded Hammerspoon's config after its window filter failed, and Hammerspoon did not answer within `ARNGZ_RELOAD_TIMEOUT`, or an `apply` that had run before the reload got no ok answer from its second run; `list` found a desk that does not validate, `current` found no desk recorded or the recorded one gone from the catalogue, `log` found no run logged, `diff` found that apply would change something, `doctor` found a precondition that does not hold, or `init --yes` stopped at a step that failed after it had changed something; each is named, and for `init` so is every step it had made. A plain `discover` printed a desk with gaps, or `discover --save --with-gaps` saved one; each gap is named on stderr. `which` found no desk fitting the screens present, and `auto` found none with no `--default` to fall back on, so nothing moved.
- `2`: refused before anything changed: a desk that does not exist or does not validate, a bad name or option, a precondition `apply` checks first (a preference, Accessibility, the Move-space shortcuts, a mouse button or modifier held), another apply still running, Hammerspoon not answering, or a `discover --save` whose read has gaps and no `--with-gaps` (`--force` or not), which leaves the desk file and the current desk as they were. For `which` and `auto` it is also the question having no one answer: more than one desk fits the screens present and none of them is the current desk, so `auto` moves nothing.

---

## Dependencies

- `yq` (required): reads and validates desks.
- `hs` (optional): Hammerspoon's command-line tool; needed by `apply`, `discover`, `diff`, `which`, `auto` and `doctor`'s IPC check. `arngz init --yes` links it.
- Hammerspoon (optional, a macOS app): the engine; needed by the same verbs. `utilz doctor` and `arngz doctor` look it up by bundle id.

---

## See Also

- `utilz doctor`: reports arngz's dependencies.
- `arngz doctor`: every precondition arngz's engine verbs need.
- `intent/st/ST0026/design.md`: the design, in a Utilz checkout; `intent st hydrate ST0026` puts it on disk.

---

## Author

Matthew Sinclair

---

## Copyright

Copyright (c) 2026 Matthew Sinclair
Part of the Utilz framework.
