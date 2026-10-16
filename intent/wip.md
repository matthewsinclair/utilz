# Work In Progress

DOING and TODO only. Done work goes to `intent/done.md`; context to `intent/restart.md`; everything else to `intent/.history/`.

## DOING

- hv is AFK and vc has the pen (16 Oct, decisions 20 and 21 on vc's board): drive ST0027 `menuz` to the 2.14.0 cut; cc and dc take instructions from vc; compiles in windows booked with intent-vc; the Ubuntu leg on kovacs; vc pushes main.
- ST0027's close: AC-05.3, the `menuz-app` dispatch on main at 7ac829a (dc dispatches; the first dispatch found Swift 6.1 refusing five closures in `MenuLoader.swift`, fixed at 554fe03); AC-06.4, the notice hand run `opt/menuz/test/notice-handrun.sh` on the dev build once hv allows menuz under System Settings > Notifications (the first launch's alert was withdrawn when the hand run quit the app, which macOS counts as no); then `wp done ST0027/05` and `ST0027/06`, `st done ST0027`, dehydrate.
- The cut: `bin/devbin release --minor` under decision 21 once CI is green on the closing SHA, in a window booked with intent-vc (the pre-flight builds); nothing pushed while step 11 waits on CI; dc fills done.md's 2.14.0 @CLOSE values; the formula copied into the tap clone and audited (the tap push is hv's); `Menuz.app.zip` signed and published after hv's `bin/devbin macos store-creds`.

## TODO

- hv at return (hold 11 on vc's board): allow menuz's notifications, confirm the menu after a logout and login (AT-05.2's note), `bin/devbin macos store-creds`, the tap pushes for 2.13.0 and 2.14.0, `! intent claude upgrade --apply` for `.claude/settings.json`.
- A second in-process notification request while the first launch's alert is up (cc's review of b7e07a3, point 7) is unmeasured until the id is allowed; one failing run under the alert in a later hand run settles it.
