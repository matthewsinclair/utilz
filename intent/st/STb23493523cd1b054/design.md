# Design: one search for a bash 5 in macos.bats, and the Check Desks label

Two parts, in one unit, on vc's BOUNCE of cycle 8:

1. Issue I669673a: menuz's `macos.bats` takes its bash 5 from `devbin_bash`.
2. hv decision 70: the example menu's item that runs `arngz doctor` is labelled "Check Desks".

## Part 1: one search for a bash 5

### Now

`setup_file` in `opt/menuz/test/macos.bats` (lines 26 to 32) has its own search: `UTILZ_TEST_BASH5`, then each bash on the PATH (`type -ap bash`), each asked `(( BASH_VERSINFO[0] >= 5 ))`. `devbin_bash` in `opt/utilz/test/test_helper.bash` (line 802) is the search that `run_devbin` uses. `macos.bats` loads `test_helper.bash` at line 24, so `devbin_bash` is defined when `setup_file` runs.

### The change

- `setup_file` opens with `BASH5="$(devbin_bash)" || BASH5=""`, then `export BASH5`. The loop and its `local b` go. The rest of `setup_file` stays.
- When `devbin_bash` finds none, `BASH5` is empty, and `setup()` skips each test, as now. The two skip messages (lines 49 and 278) say "devbin needs bash 5, and devbin_bash finds none", since the search now reads more than the PATH.
- The header comment (lines 17 to 22) says that the tests run under the bash `devbin_bash` finds, as `run_devbin` does, and that `devbin_bash` reads `UTILZ_TEST_BASH5` first.
- `devbin_bash`'s comment (lines 793 to 801) stops saying that `macos.bats` reads `UTILZ_TEST_BASH5` itself. It says that `devbin_bash` is the one search for that bash in Utilz's tests, and that `run_devbin` and `macos.bats` both ask it.

### What stays

`setup()` still links `BASH5` into the fakes as `bash`, and the last test still runs `"$BASH5"` for its read of the config. CI's macOS job still sets `UTILZ_TEST_BASH5`, which `devbin_bash` reads first (issue I7854aef).

### What the search reads after the change

`devbin_bash` reads Homebrew's places, which `macos.bats` did not, and only the first bash on the PATH, where `macos.bats` read each one. On a Mac with Homebrew's bash, on CI's macOS job, and on a Linux with bash 5 first on the PATH, both searches find the same bash. So the change moves no test from a run to a skip there.

### Out of scope

`devbin_bash` restates devbin's floor (5) and its candidate places, which the vendored `bin/.devbin/lib/helpers` spells once (`_DEVBIN_BASH_FLOOR`, `bash_floor_candidates`). Those are devbin's private names, and Devbin has no public verb for them. vc passes it to devbin-vc for Devbin's tracker, and nothing is filed in Utilz for it.

## Part 2: the Check Desks label

hv decision 70 names the label "Check Desks". hv had asked why the item says "Hammerspoon" when it runs `arngz doctor`. The places in Utilz:

| Place                                                                 | What it is                                                                            |
| --------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| `opt/menuz/lib/example.yaml:31`                                       | the example menu that `menuz init` writes                                             |
| `help/menuz.md:100`                                                   | the help's copy of the example                                                        |
| `help/menuz.md:178`                                                   | the quoted label in the log example; the line under it is `arngz doctor`'s own output |
| `help/menuz.md:226`                                                   | the help's render of the example menu                                                 |
| `native/macos/Menuz/MenuzKit/Tests/MenuzKitTests/SpecTests.swift:210` | `example()` reads `example.yaml` and checks its render, so it changes with the label  |

Each "Hammerspoon" there becomes "Check Desks", and nothing else changes.

Not changed: `MenuBuilderTests.swift` and `RunTests.swift` hold their own labels as test data (vc). Molt-matts' `config/menuz/menuz.yaml`, hv's live menu, is changed by molt-vc's seats.

## Proof

- Static: `bash -n opt/utilz/test/test_helper.bash` under bash 3.2 and 5. The commit gate runs the critics on the staged files.
- Runs, on vc's word and a Desk booking, from the worktree at the unit's commit:
  - `bats --tap opt/menuz/test/macos.bats` under bash 3.2, then under bash 5, each picked by a shim dir that holds only that bash. Each is green: bats exits 0, and every planned test is an ok line, with none skipped (`rsvg-convert` is installed on rhadamanth).
  - `bin/utilz menuz test --unsigned`, with its state in a scratch folder under `DARWIN_USER_TEMP_DIR`. It is green: exit 0, `** TEST SUCCEEDED **`, and "the example menu renders, unrealised, entry by entry" and "the example menu passes" are seen passing by name.
- No run is red at the base. Part 1 finds the same bash at the base and the tip. Part 2's test passes at the base with the old label and at the tip with the new one, and its red is the case where only one of `example.yaml` and `SpecTests.swift` changes (no test of a test).
