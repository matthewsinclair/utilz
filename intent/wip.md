# Work In Progress

DOING and TODO only. Done work goes to `intent/done.md`; context to `intent/restart.md`; everything else to `intent/.history/`.

## DOING

- WP-07 of ST0027, the menu's version line (hv's decision 22, 17 Oct), BEFORE the 2.14.0 cut: ST0027 reopened at d1de113 with design.md "The identity row", D14 and AC-07.1 to AC-07.5; cc builds the app half (`Identity.line` in MenuzKit, the first menu item from the bundle's stamps, `--render`'s first line, `MenuzKind` in Info.plist), dc the shim half (`MENUZ_COMMIT` at eight characters, `MENUZ_KIND` release only for a clean source stamp at the commit carrying the root `VERSION`'s bare tag, five stamps, `menuz.bats`, `help/menuz.md`, the CHANGELOG line); vc verifies in a worktree, installs on hv's Mac for AT-07.5, dispatches `tests.yml` for the menuz-app job, closes ST0027 again; compiles only in windows booked with intent-vc (cc's build and test, vc's verify, then the cut).
- Then vc drives the 2.14.0 cut under decisions 20 and 21: the cut window from intent-vc, `bin/devbin release --minor --yes` on main, nothing pushed while step 11 waits on CI; then `tools/formula-bump 2.14.0` committed by path, the formula copied into the tap clone and audited (the tap push is hv's), dc fills done.md's 2.14.0 @CLOSE values; `Menuz.app.zip` signed and published after hv's `bin/devbin macos store-creds` and before the tap push; then dc's install of 2.14.0 on this Mac (hv's ask).

## TODO

- hv: a logout and login to confirm the menu comes back (AT-05.2's note), `bin/devbin macos store-creds`, the 2.14.0 tap push after the cut, `! intent claude upgrade --apply` for `.claude/settings.json`.
- A second in-process notification request while the first launch's alert is up (cc's review of b7e07a3, point 7) is unmeasured; one failing run under the alert on a fresh bundle id settles it.
