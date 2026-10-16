---
st_id: ST0027
title: menuz: a macOS menu bar app whose menu is a YAML file of commands to run
---

# ST0027: menuz: a macOS menu bar app whose menu is a YAML file of commands to run -- Acceptance

> **THIS FILE IS A GENERATED VIEW, AND A ROW AUTHORED HERE IS DISCARDED BY THE NEXT SYNC.** The acceptance contract is canon in the thread model; this file renders it. Acceptance Criteria (AC) are the ratified completeness boundary; Acceptance Tests (AT) are the small red-to-green tests that prove them.
>
> Done = every AC is covered by a GREEN AT, or (for a non-test AC) its named evidence is satisfied, AND the AC set is the ratified full boundary. Done is read from this map, never from a hand-ticked box.
>
> Test-backed satisfaction is COMPUTED from covering green ATs and never stored -- storing it would be double truth. An AC has four states, not two: beyond satisfied and unsatisfied, a requirement can be **descoped** to a named thread or **withdrawn** with its reason on the record. Both are non-blocking and both are reported separately, so a thread that descoped half its contract looks like one.

## Acceptance Criteria

### WP-01 -- Design settled with hv (status: Done)

- AC-01.1 (non-test) design.md records hv's ruling on each of its questions Q1 to Q11 as a numbered decision or a descoping, in hv's words where hv gave them, and no recommendation is left standing in its place. -- evidence: hv's rulings of 16 Oct 2026 on Q1 to Q11, recorded as D1 to D11 in WP-01's body (and in design.md's Decisions section at the 0605 sync): Q4 one typed form, Q6 the source and dev build at native/macos/Menuz with the installed copy at ~/Applications/Menuz.app like the siblings and a use dev|installed switch (hv's correction in cc's session, confirmed to vc), Q7 Intent's signing, Q9 runs left running, Q10 and Q11 yes, the rest as recommended; no recommendation left standing in a ruling's place -- satisfied: yes
- AC-01.2 (non-test) The example menuz.yaml in design.md is final, its params typed as D4 rules, and is the one menuz init writes; swift is a declared language of the project (intent lang init swift) and critic-swift is the review for native/macos/Menuz. -- evidence: vc, 16 Oct 2026 at 04a331d: opt/menuz/lib/example.yaml is design.md's yaml block byte for byte (diff empty; cc's 4e34217 carried a 'type: string' line the five types do not allow, removed at 04a331d), menuz init writes it (AT-02.2 green), swift is a declared language (intent lang init swift, 16 Oct) and critic-swift reviews native/macos/Menuz -- satisfied: yes

### WP-02 -- The shim, the config directory and the catalogue verbs (status: Done)

- AC-02.1 utilz menuz is dispatched by bin/utilz; opt/menuz/menuz.yaml declares the utility with opt/menuz/VERSION as the one home of its version; utilz list shows menuz; utilz doctor reports xcodegen and xcodebuild only when native/macos/Menuz is present, as it reports cargo only when a crate is. -- satisfied: yes (computed)
- AC-02.2 init creates MENUZ_HOME (default ${XDG_CONFIG_HOME:-$HOME/.config}/menuz) with the example menuz.yaml and an empty bin/, refuses to overwrite an existing menuz.yaml without --force (exit 2, naming the file), and a second run changes nothing; edit opens the yaml with open -t, or $VISUAL/$EDITOR under --editor; log prints the log's path then tails it, -n N prints the last N lines; each refuses by name, exit 2, when its file is missing. -- satisfied: yes (computed)
- AC-02.3 validate and render run the app's --validate and --render arms on menuz.yaml or a given file and pass their output and exit code through, proven with a fake Menuz binary on PATH; with no app built or installed they refuse by name, exit 2; status reports installed (~/Applications/Menuz.app), running, login item, source-current and which build use selects (dev or installed), without Xcode present. -- satisfied: yes (computed)

### WP-03 -- The app: the menu from the file, watched, realised at open (status: WIP)

- AC-03.1 The app is an xcodegen project at native/macos/Menuz in the siblings' shape (Swift 6, macOS 14, LSUIElement, the test-host guard; signed and notarised with Developer ID on release as Intent's is, D7) with Yams as its one package; --validate and --render run without a menu bar and exit 0 or 2 with every finding named, and --version prints the stamped version. -- satisfied: no (computed)
- AC-03.2 The menu is exactly the file, in order: items, captions, headers, separators, submenus, then the fixed tail (Edit Menu, Open Log, Reload, Quit menuz); every validation rule in the design refuses its fixture naming file, entry path, key and value, and the example passes; a file that fails keeps the last good menu and shows the refusal as a disabled first item and in the log. -- satisfied: no (computed)
- AC-03.3 Hand run on hv's machine, recorded as such: a save of menuz.yaml, an atomic rename by an editor, and a deletion and recreation of MENUZ_HOME each reach the menu within one second with no restart. -- satisfied: no (computed)
- AC-03.4 Labels and each lines with a $ or a backtick are realised by the login shell at every menu open in one zsh -ilc invocation, asynchronously, the last values shown first and titles updated in place, under the realise cap with the previous value kept and the overrun logged; a label with neither is never sent to the shell; each expands to one item per stdout line with MENUZ_ITEM set. -- satisfied: no (computed)

### WP-04 -- Running items: params, the runner, the log and the notice (status: Not Started)

- AC-04.1 An item's params are acquired through one form window holding every param in order (D4), each field typed from the param's type (text, secret, choice, file, folder; text when none is given; secret hidden) with its prompt and default; Cancel runs nothing and logs cancelled; required refuses an empty answer and a typed field refuses a value of the wrong kind, each named in the form; the values reach the run as exported variables under the declared names. -- satisfied: no (computed)
- AC-04.2 Each run is /bin/zsh -ilc of the run line, with the login shell's PATH and MENUZ_HOME/bin first on it, cwd the item's, else the file's, else HOME, stdin /dev/null, and MENUZ_HOME, MENUZ_LABEL, MENUZ_RUN_ID and (under each) MENUZ_ITEM exported; runs are concurrent, each with its own id, detached from the app (their own session, stdout and stderr on the log file directly, not through the app); Quit leaves runs in flight running and logs each as left running with its id (D9). -- satisfied: no (computed)
- AC-04.3 Every run appends to ${XDG_STATE_HOME:-$HOME/.local/state}/menuz/menuz.log, created on first use: a start line (timestamp, run id, item, cwd, the run line as written), stdout and stderr lines as they come prefixed with the run id, and an end line with exit code and duration; a secret's value never appears; a line the app cannot write is an error in OSLog and a notification. -- satisfied: no (computed)
- AC-04.4 A run that exits non-zero posts a notification naming the item and the exit code; notify: always posts one on every finish carrying the last output line; notify: never posts none; the item's notify overrides the file's. -- satisfied: no (computed)
- AC-04.5 Hand run on hv's machine, recorded as such: the example menu applies an arngz desk chosen from the each-generated items, and discover saves one through a text dialog, with both runs in the log. -- satisfied: no (computed)

### WP-05 -- Build, install, launch and the close (status: Not Started)

- AC-05.1 build runs xcodegen only when project.yml or the set of sources changed and xcodebuild Debug or --release with products under ${XDG_STATE_HOME:-$HOME/.local/state}/menuz/build/macos as Intent's and Gtools' do; test runs the MenuzTests target; install builds Release, quits every running copy, replaces ~/Applications/Menuz.app (the siblings' target, D6), unclaims the build products, registers the bundle and launches it with an empty environment; use dev|installed records which build the shim's launch and status use, after devbin's own switch; uninstall, start, stop, restart and stamps as designed; each refuses by name, exit 2, without xcodegen or xcodebuild, and install refuses when native/macos/Menuz is absent. -- satisfied: no (computed)
- AC-05.2 Hand run on hv's machine, recorded as such: the app registers itself as a login item on its first run, status reports it, and the menu is back after a logout and login. -- satisfied: no (computed)
- AC-05.3 (non-test) CI: a macOS job on a tag builds the app, signs it with Developer ID, notarises it and attaches it as the release asset, as Intent's does (D7); on dispatch it builds unsigned and runs MenuzTests; the Linux legs run menuz.bats with the fake app in the explicit utility loop; both green on the closing SHA. -- satisfied: no
- AC-05.4 (non-test) help/menuz.md, the README's menuz section and the CHANGELOG entry exist and name every verb and flag the CLI accepts, checked against menuz --help; bin/devbin check all and the estate suite are green; the hand-run transcript in acceptance.md names the machine, the macOS build and the Xcode version. -- satisfied: no

## Acceptance Tests

### WP-01 -- Design settled with hv (status: Done)

_(no tests in this group)_

### WP-02 -- The shim, the config directory and the catalogue verbs (status: Done)

- AT-02.1 `opt/menuz/test/menuz.bats` -- covers AC-02.1 -- status: green -- opt/menuz/test/menuz.bats, 7 tests marked AT-02.1: verified by vc on 4e34217 in a detached worktree, 16 Oct 2026: menuz.bats 38/38 under bash 5.3.20 and 3.2.57, the dispatch suites (help_dispatch 8/8 on the primary checkout where prez is built, version_dispatch 11/11, dispatcher 28/28), utilz list shows menuz, menuz --help renders 84 lines, VERSION 0.1.0 is the one home (utilz menuz --version prints utilz:2.13.0/menuz:0.1.0), shellcheck clean.
- AT-02.2 `opt/menuz/test/menuz.bats` -- covers AC-02.2 -- status: green -- opt/menuz/test/menuz.bats, 14 tests marked AT-02.2: verified by vc on 4e34217 in a detached worktree, 16 Oct 2026, under a fixture HOME: init wrote menuz.yaml and bin/ (exit 0), a second init changed nothing (exit 0), init over a menu of the user's own refused naming the file and --force (exit 2), log with no log refused by name (exit 2); 38/38 under both bashes.
- AT-02.3 `opt/menuz/test/menuz.bats` -- covers AC-02.3 -- status: green -- opt/menuz/test/menuz.bats, 17 tests marked AT-02.3: verified by vc on 4e34217 in a detached worktree, 16 Oct 2026: validate with no app built or installed refused by name, exit 2, naming both paths looked at (~/Applications/Menuz.app and the XDG dev build); status without Xcode printed use installed (default), running no, login item unknown with the reason, source unknown with the reason, exit 1; 38/38 under both bashes.

### WP-03 -- The app: the menu from the file, watched, realised at open (status: WIP)

_(no tests in this group)_

### WP-04 -- Running items: params, the runner, the log and the notice (status: Not Started)

_(no tests in this group)_

### WP-05 -- Build, install, launch and the close (status: Not Started)

_(no tests in this group)_

---

_Generated by Intent v3 from the thread canon. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
