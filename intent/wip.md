# Work In Progress

DOING and TODO only. Done work goes to `intent/done.md`; context to `intent/restart.md`; everything else to `intent/.history/`.

## DOING

- 2.14.0 is released (069e0f3, tag on both remotes, CI green on main and the tag). After hv's tap push: dc's install of 2.14.0 on this Mac (`brew upgrade utilz`, `utilz doctor`, `utilz menuz install`, version checks; the keg is 2.12.1). The kovacs runbook (`tmp/dc-st0027/kovacs-2.14.0.md`) runs at kovacs-sysadm through intent-vc; its Report comes back the same way.
- `Menuz.app.zip` on the 2.14.0 release after hv's `bin/devbin macos store-creds`: `utilz menuz build --release` in a window, `bin/devbin macos app-sign`, `app-notarize`, `app-verify`, `publish`; then done.md's @ASSET and @TAP values filled.
- The devbin fleet sweep vendoring 0.1.11 into `bin/devbin`, after the above, by path (its pathspec gains `.gitattributes`).

## TODO

- hv: `git -C "$(brew --repository matthewsinclair/utilz)" push origin main` (the formula 2.14.0 at 069e0f38 is audited clean, committed there as 14fef4c); `bin/devbin macos store-creds`; a logout and login to confirm the menu comes back (AT-05.2's note); `! intent claude upgrade --apply` for `.claude/settings.json`; Intent 3.2.4's cut at ef9889423 from hv's terminal.
- A second in-process notification request while the first launch's alert is up (cc's review of b7e07a3, point 7) is unmeasured; one failing run under the alert on a fresh bundle id settles it.
