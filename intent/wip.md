# Work In Progress

DOING and TODO only. Done work goes to `intent/done.md`; context to `intent/restart.md`; everything else to `intent/.history/`.

## DOING

- The 2.14.0 cut, hv's terminal: `cd ~/Devel/prj/Utilz && bin/devbin release v2.14.0` (the dry run at 5214f2e is green: check all, the estate, no step failed, the cut asks at step 6; the release core is refused in vc's session). ST0027 is closed (WP-07 the identity row) with CI green on main at the close in the push run and the menuz-app dispatch.
- After the tag, vc: `tools/formula-bump 2.14.0` committed by path, the formula copied into the tap clone and `brew audit --strict`ed (the tap commit and push are hv's); the done.md 2.14.0 values to dc, who lands the block by path; the kovacs runbook (`tmp/dc-st0027/kovacs-2.14.0.md`, staged with kovacs-sysadm through intent-vc, yq v4 already placed) on vc's trigger; `Menuz.app.zip` signed and published after hv's `bin/devbin macos store-creds` and before the tap push; then dc's install of 2.14.0 on this Mac (the keg is 2.12.1).

## TODO

- hv: the cut above; `bin/devbin macos store-creds`; the 2.14.0 tap push after vc's audit; a logout and login to confirm the menu comes back (AT-05.2's note); `! intent claude upgrade --apply` for `.claude/settings.json`; the `!` in the kovacs-sysadm session that its classifier asks for before a run.
- Intent 3.2.4 (ef9889423) and Devbin 0.1.11 (7dcb442e) are cut-ready for hv's terminal, their commands on their own boards; the devbin fleet sweep to 0.1.11 follows its tag.
- A second in-process notification request while the first launch's alert is up (cc's review of b7e07a3, point 7) is unmeasured; one failing run under the alert on a fresh bundle id settles it.
