---
st_id: ST0026
title: arngz: named window arrangements (desks) discovered and applied across displays and spaces
---

# ST0026: arngz: named window arrangements (desks) discovered and applied across displays and spaces -- Acceptance

> **THIS FILE IS A GENERATED VIEW, AND A ROW AUTHORED HERE IS DISCARDED BY THE NEXT SYNC.** The acceptance contract is canon in the thread model; this file renders it. Acceptance Criteria (AC) are the ratified completeness boundary; Acceptance Tests (AT) are the small red-to-green tests that prove them.
>
> Done = every AC is covered by a GREEN AT, or (for a non-test AC) its named evidence is satisfied, AND the AC set is the ratified full boundary. Done is read from this map, never from a hand-ticked box.
>
> Test-backed satisfaction is COMPUTED from covering green ATs and never stored -- storing it would be double truth. An AC has four states, not two: beyond satisfied and unsatisfied, a requirement can be **descoped** to a named thread or **withdrawn** with its reason on the record. Both are non-blocking and both are reported separately, so a thread that descoped half its contract looks like one.

## Acceptance Criteria

### WP-01 -- Spike: space moves and Dock bindings on macOS 27 (status: Not Started)

- AC-01.1 (non-test) The spike's three measurements (observe; a window moved to the next space on its display and to a space on another display, each read back; a Dock binding written and tested after a Dock restart) were run on hv's machine, and their JSON files and hv's notes are recorded in design.md under "The open input". -- satisfied: no
- AC-01.2 (non-test) That section is resolved to one outcome, A, B or C, and names which apply flags exist as a result, --bind in particular. -- satisfied: no

### WP-02 -- Desk config, validator and the catalogue verbs (status: Not Started)

- AC-02.1 utilz arngz is dispatched by bin/utilz; opt/arngz/arngz.yaml declares yq, Hammerspoon and the hs tool as dependencies; utilz doctor reports each of them; utilz list shows arngz. -- satisfied: no (computed)
- AC-02.2 The catalogue is ${XDG_CONFIG_HOME:-$HOME/.config}/arngz/desks/. list prints each desk with its display and app counts; show prints a validated desk; delete removes one by name; init creates the directory. A desk that does not exist is refused by name, exit 2. -- satisfied: no (computed)
- AC-02.3 The validator refuses each of the design's seven conditions (an unknown key; a grid not WxH; a layout neither x,y wxh inside the grid nor fullscreen; two displays with one name; a match with neither uuid nor name; the same app twice on one display without a window pattern on each; a verb as a desk name), naming the desk, the path and the value, and accepts the design's example desk unchanged. -- satisfied: no (computed)

### WP-03 -- Engine: observe, the pure planner, execute, and the IPC contract (status: Not Started)

- AC-03.1 The IPC contract: the CLI writes a request file holding exactly {verb, desk, options}, runs hs -c with a dofile of the module and the request path, and renders exactly the response file's report, proven through a fake hs on PATH. An hs that is absent, that times out, or that writes no response is refused by name, exit 2. -- satisfied: no (computed)
- AC-03.2 plan(desk, world) is pure (its source holds no hs. reference, which the suite checks) and is tested under lua5.4 on the Linux leg from fixtures: a world already matching the desk yields no ops; a window on the wrong space yields move then place; a display short of spaces yields create_space; an app not running yields launch; --no-create and --no-launch remove theirs. -- satisfied: no (computed)
- AC-03.3 Hand run on hv's machine, recorded as such: observe reports every screen with UUID, name, frame and position, every space with ordinal and type, every window with bundle id, title and frame, the two settings, and every Dock binding, and agrees with the spike's observation. -- satisfied: no (computed)
- AC-03.4 (non-test) Lua is a declared language of the project, critic-lua is clean on the module, and CI's Linux legs install lua5.4. -- satisfied: no

### WP-04 -- discover and diff (status: Not Started)

- AC-04.1 discover from a fixture world prints a desk the validator accepts, and prints it again byte-identically from the same world: standard windows only, full-screen windows as fullscreen, every display with uuid, name, size and position, the Dock bindings read. -- satisfied: no (computed)
- AC-04.2 Snapping: a window 3 px off a cell edge is recorded at that cell with the misfit noted beside the layout; a window spanning half a cell is reported rather than silently rounded. -- satisfied: no (computed)
- AC-04.3 discover --save <desk> writes into the catalogue, refuses to overwrite an existing desk without --force (exit 2, naming the file), and overwrites with it. -- satisfied: no (computed)
- AC-04.4 diff <desk> prints the ops apply would run, exits 1 when any exist and 0 when none, and sends no execute request. -- satisfied: no (computed)

### WP-05 -- apply (status: Not Started)

- AC-05.1 apply --dry-run sends no execute request, prints every op with its reason, and exits 0. -- satisfied: no (computed)
- AC-05.2 Display matching from fixtures: a UUID match wins; name and size resolve a single candidate; two identical panels resolve by position; a desk display with no candidate, or two desk displays on one screen, refuse naming every candidate, exit 2; --map <name>=<uuid> overrides one display and is reported. -- satisfied: no (computed)
- AC-05.3 The report and exit codes: every app placed exits 0; an app not installed is reported as skipped, exit 1; a window matching no pattern is reported as unseen, exit 1; a move whose readback disagreed with its return value is reported as failed, exit 1; a refusal before anything changed exits 2. -- satisfied: no (computed)
- AC-05.4 Hand run on hv's machine, recorded as such: applying a discovered desk after its windows were scrambled by hand puts every app's windows back on their space and cell, verified by the final observe, and applying it again produces no ops. -- satisfied: no (computed)
- AC-05.5 Hand run on hv's machine, recorded as such: an app in the desk that is not running is launched and placed within the timeout, and with --no-launch it is reported instead. -- satisfied: no (computed)
- AC-05.6 (non-test) The --bind flag exists only under WP-01's outcome A or B with the binding measurement passed. Where it exists it writes the bindings, restarts the Dock once and re-observes; where it does not, the flag is refused as unknown rather than accepted and ignored. -- satisfied: no
- AC-05.7 utilz arngz <desk> is apply <desk>, and a desk named like a verb can be neither saved nor applied. -- satisfied: no (computed)

### WP-06 -- doctor, init, docs and the close (status: Not Started)

- AC-06.1 doctor names every precondition with its state (Hammerspoon running, the hs tool and IPC, Accessibility, separate spaces, auto-rearrange, Stage Manager), exits 1 when any fails, and completes without Hammerspoon present, naming it as missing. -- satisfied: no (computed)
- AC-06.2 init without --yes prints what it would do and changes nothing outside the catalogue; with --yes it installs the hs tool under /opt/homebrew and appends exactly one marked require("hs.ipc") line to init.lua, and a second run changes nothing (fixture HOME). -- satisfied: no (computed)
- AC-06.3 (non-test) help/arngz.md, the README's utility table and the CHANGELOG entry exist and name every verb and flag the CLI accepts, checked against arngz --help. -- satisfied: no
- AC-06.4 (non-test) bin/devbin check all and the estate suite are green; the hand-run acceptance transcript is in acceptance.md and names the machine, the macOS build and the Hammerspoon version that ran it. -- satisfied: no

## Acceptance Tests

### WP-01 -- Spike: space moves and Dock bindings on macOS 27 (status: Not Started)

_(no tests in this group)_

### WP-02 -- Desk config, validator and the catalogue verbs (status: Not Started)

_(no tests in this group)_

### WP-03 -- Engine: observe, the pure planner, execute, and the IPC contract (status: Not Started)

_(no tests in this group)_

### WP-04 -- discover and diff (status: Not Started)

_(no tests in this group)_

### WP-05 -- apply (status: Not Started)

_(no tests in this group)_

### WP-06 -- doctor, init, docs and the close (status: Not Started)

_(no tests in this group)_

---

_Generated by Intent v3 from the thread canon. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
