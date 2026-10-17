# Work In Progress

DOING and TODO only. Done work goes to `intent/done.md`; context to `intent/restart.md`; everything else to `intent/.history/`.

## DOING

- hv has the pen back from the fold of 17 Oct 04:5xZ; vc drives the 2.14.0 cut under decisions 20 and 21: ask intent-vc for the window, `bin/devbin release --minor --yes` on main (ST0027 and ST0028 closed, CI green, the dry run clean), nothing pushed while step 11 waits on CI; then `tools/formula-bump 2.14.0` committed by path, the formula copied into the tap clone and audited (the tap push is hv's), dc fills done.md's 2.14.0 @CLOSE values; `Menuz.app.zip` signed and published after hv's `bin/devbin macos store-creds` and before the tap push.

## TODO

- hv: a logout and login to confirm the menu comes back (AT-05.2's note), `bin/devbin macos store-creds`, the 2.14.0 tap push after the cut, `! intent claude upgrade --apply` for `.claude/settings.json`.
- A second in-process notification request while the first launch's alert is up (cc's review of b7e07a3, point 7) is unmeasured; one failing run under the alert on a fresh bundle id settles it.
