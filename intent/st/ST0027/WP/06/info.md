---
wp_id: WP-06
title: First-use fixes: notice, place, icon and glyph
scope: S
status: Done
---

# WP-06: First-use fixes: notice, place, icon and glyph

## Objective

First-use fixes, hv's D13 ("Fix everything that needs fixing", then, going AFK, "If a fix needs fixing, then fix it"): the four things hv met in menuz's first runs on 16 Oct (vc's todo 37, from dc's launch), fixed ahead of WP-05's remainder because hv is running the app now. design.md's Output section, the arms paragraph, the build layout and D13 are the contract; the measurements behind them are in D13 and at tmp/vc-st0026/st0027/notify-probe/RESULT.md (git-ignored, vc's).

**Who.** cc builds the app side and the mark: every file under native/macos/Menuz, the wrapper in MenuzKit's Run.swift, the tests. dc ports `bin/devbin macos` with `app-icons` first (Intent's `cmd_app_icons`, so cc's SVGs are rasterised by the one rasteriser) and writes help/menuz.md's lines. vc verifies each SHA in a worktree, runs the notice hand run from the dev build, mints the ATs and lands. Compiles only in a window vc books with intent-vc.

**1. The notice, one route (AC-06.1).**

- The wrapper (`Run.wrapper`) keeps its decision (`MENUZ_NOTIFY`: never, failure, always) and its text (`"<label>" exited <rc>`, plus `: <last line>` under always) and replaces the `osascript` line with `"$MENUZ_EXEC" --notify`, the text reaching the arm as the exported `MENUZ_NOTICE` and never as an argument (an argv is every local user's to read with `ps` for the arm's life); the arm's stdout and stderr go to the log under the run id as every other line does, so `notice posted` or the refusal lands in the log. `Run.noticeScript` goes.
- The Runner exports `MENUZ_EXEC`, `Bundle.main.executablePath`, into the wrapper's environment beside MENUZ_HOME, MENUZ_LABEL, MENUZ_RUN_ID and MENUZ_NOTIFY.
- `Arm.notify`: `--notify`, no argument; the arm is refused as usage, exit 2, naming `MENUZ_NOTICE`, when that variable is unset or empty. The arm runs before any menu bar work, as `--validate` does: `UNUserNotificationCenter.current()`, `requestAuthorization([.alert, .sound])` (granted at once on macOS 27 once the app's launch has asked; the request is cheap and makes the arm whole on its own), then `add` of a request titled `menuz` with `MENUZ_NOTICE` as the body, waiting on the run loop for the centre's answer with a deadline of 10 s. Success prints `notice posted`, exit 0. A refusal (`granted == false`, or settings reading `.denied`) prints `notice not posted: notifications are off for menuz under System Settings > Notifications`, exit 1; an `add` error prints `notice not posted: <error>`, exit 1; the deadline prints `notice not posted: no answer from the notification centre in 10 s`, exit 1.
- The app requests authorisation at its first launch, before the status item, and logs `notifications: granted|denied|<error>` through AppLog, never silent. `Notifier` posts the app's own notices through the same centre, with a `UNUserNotificationCenterDelegate` returning `.banner` and `.list` so a notice shows while menuz is frontmost. The OSLog path for a log the app cannot write stays.
- Tests, red first: `WrapperTests` with a fake `MENUZ_EXEC` on a fixture path recording its arguments: failure on a non-zero exit with the label and the code, always on every end with the last output line, never none, the fake's stdout in the log under the run id, and an exit 1 from the fake logged as its line; `ArmTests` for `--notify` and its usage refusal; in `MenuzTests`, the arm's poster behind a protocol, so the test sees the request's title and body and the exit for a granted, a denied and a failed `add`, with no real notification posted.
- AT-04.4's note is rewritten by vc to what the test measures now.

**2. The place (AC-06.2).** menuz seeds no `NSStatusItem Preferred Position`. When the app's defaults hold no `NSStatusItem Preferred Position Item-0` at launch, after the status item is made, the app logs one line and posts it through Notifier: `menuz is in the menu bar; on a full bar it may be hidden behind the overflow: hold Command and drag its icon where you want it`. Test: the line given and withheld by whether the key is set, under a UserDefaults suite the test owns.

**3. The icon (AC-06.3).** A drawn mark, `native/macos/Menuz/design/menuz.svg` (the app icon: the mark on macOS's rounded square, 1024 units) and `menuz-mark.svg` (its silhouette, black on transparent, for the template image), written in this WP by cc as SVG text, not the SF Symbol (the licence). dc's `bin/devbin macos app-icons` (Intent's `cmd_app_icons` ported; `rsvg-convert`, refusing by name without it) writes `native/macos/Menuz/Menuz/Assets.xcassets/AppIcon.appiconset` (the seven macOS sizes with its Contents.json) and `MenuBarIcon.imageset` (template, 1x 2x 3x, `template-rendering-intent: template`), tracked, so a build and CI need no rsvg-convert. project.yml adds `Menuz/Assets.xcassets` to the sources and `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon`. Test, hosted in MenuzTests: `Bundle.main` carries `CFBundleIconName` and the `AppIcon.icns` resource, and `NSImage(named: "MenuBarIcon")` loads as a template. `bin/devbin macos doctor` reports rsvg-convert and the asset, as Intent's app-doctor does.

**4. The default glyph (AC-06.3).** `MenuSpec.icon` optional (nil without `icon:`; `MenuSpec.defaultIcon` goes); the status item's button shows `MenuBarIcon` when nil, the SF Symbol when named, validated as now (D8 stands). The example's `icon:` line is a comment (landed at 1aa2346 in design.md's block; `opt/menuz/lib/example.yaml` follows it byte for byte, AC-01.2). Tests: SpecTests for nil without `icon:` and the example still ok; the hosted test above for the asset.

**5. The hand run (AC-06.4)**, vc's, hands off, from the dev build rebuilt at the landed SHA under `~/.local/state/menuz/build/macos` (not a worktree product: a bundle under /private/tmp is refused by the notification centre, D13), recorded with the machine, macOS and Xcode: the launch logs `notifications: granted`; a run that exits non-zero while the app runs lands `notice posted` in the log under its id, and so does a run that ends after the app quit; the first-launch line is logged and posted when the position key is absent; the status item shows the mark. The banners' appearance on screen is hv's confirmation when back (hv saw the probe's banner: "this is working"). Carrier: `opt/menuz/test/notice-handrun.sh`, beside the WP-03 and WP-04 hand runs.

**6. The help (AC-06.5)**, dc's: help/menuz.md says the default glyph is menuz's mark and `icon:` names an SF Symbol over it; that a full menu bar can hide a new item behind the overflow (hold Command and drag it); and that notices come through macOS's notification centre under menuz's name, a notice that could not post being a line in the log naming System Settings > Notifications > menuz. The README section and the CHANGELOG entry stay WP-05's close (dc's hold 7).

**Landing.** cc works on a branch from main's head, commits by explicit path, red tests first, shellcheck and critic-swift clean, and sends vc the SHA; vc verifies in a worktree with the compiles (`verify-wp03.sh <sha> --build`) in a booked window, then fast-forwards main and pushes. dc's `app-icons` lands first, on its own, so cc's assets come from the one rasteriser.

## Acceptance

Acceptance Criteria for this work package are RENDERED into `ST0027/acceptance.md`, under the `WP-06` heading. THAT FILE IS A GENERATED VIEW -- a row authored there is discarded by the next sync. The contract is canon in the thread's model, and the verbs write it: `intent ac new` and `intent at new` mint a row, `intent ac edit` and `intent at edit` reword or re-cite one, and `intent ac satisfy|unsatisfy|descope|rescope|withdraw|reinstate` and `intent at green|red|na` move its state. This cover never restates them.

---

_Generated by Intent v3 from the thread canon. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
