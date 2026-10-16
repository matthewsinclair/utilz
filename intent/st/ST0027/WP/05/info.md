---
wp_id: WP-05
title: Build, install, launch and the close
scope: S
status: WIP
---

# WP-05: Build, install, launch and the close

## Objective

Build, install, launch and the close: the shim's remaining verbs (`build`, `test`, `install`, `use`, `uninstall`, `start`, `stop`, `restart`, `stamps`, `doctor`), the install a keg makes from the signed release asset, the signing and publishing of that asset, and CI. WP-02's verbs (`init`, `edit`, `log`, `validate`, `render`, `status`) stand. This note settles what design.md leaves open for WP-05. design.md's shim table, "Build layout", "CI" and the keg paragraph are the contract, with D6, D7 and D12.

**D12: D7's "same as Intent" is local signing, not CI.** Intent's workflows read no secrets and run no codesign or notarytool. Intent signs and notarises on the maintainer's machine, through its project-local `bin/devbin macos`, with the Apple credentials in the login keychain ("no key material in this repository, in CI config, or in any file this writes"). It publishes the stapled bundle as the release asset `Intent.app.zip`. hv confirmed this reading in cc's session on 16 Oct ("same as intent", "Correct."), and vc recorded it as D12, with design.md's CI paragraph and AC-05.3 reworded to match. So:

- CI builds unsigned and tests, on a tag or a dispatch, and reads no secrets.
- Signing, notarising and attaching the asset are a maintainer's step, on hv's machine.

**Layout.**

| Where                         | What                                                                                                                                                                                       |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `opt/menuz/menuz`             | The verbs below, bash 3.2 under `set -euo pipefail`, shellcheck-clean. Exit codes as arngz: 0 done, 1 failed after changing something (naming the step), 2 refused before anything changed |
| `bin/.devbin/cmd/macos`       | Project-local, Utilz's own (not the vendored core): `doctor`, `store-creds`, `app-icons`, `app-sign`, `app-notarize`, `app-verify`, `publish`, ported from Intent's app half               |
| `.github/workflows/tests.yml` | The `menuz-app` job                                                                                                                                                                        |
| `opt/menuz/test/menuz.bats`   | The verbs' tests, with fakes on PATH                                                                                                                                                       |
| `opt/menuz/test/macos.bats`   | `bin/devbin macos`'s refusals and sequence, with fakes on PATH                                                                                                                             |

**Source clone or install.** As prez's shim does (ST0014 D5): a tree with `manifest.sha256` at the shim's own tree root is an install, a brew keg or a `utilz install` publish. Neither carries `native/macos/Menuz`, which the published set leaves out. In an install, `build` and `test` refuse by name, exit 2, naming the source clone (`git clone https://github.com/matthewsinclair/utilz`), and `install` takes the release asset (below). In a source clone, `install` builds.

**hv's first runs: D13.** dc launched the Debug build for hv after the fold, and vc's todo 37 records what hv met. hv then ruled "Fix everything that needs fixing", recorded as D13 in design.md with the Output section amended. WP-05 carries all four fixes, and they land first, ahead of the shim, because hv is running the app now.

1. **The notice (a WP-04 defect: AC-04.4 was green on a fake `osascript`, and the real one posts nothing on hv's machine).**
   - The wrapper still decides whether to post, and still builds the text. It then writes the text to `$MENUZ_NOTICES/<id>`, through `<id>.tmp` renamed into place, before its end line. `MENUZ_NOTICES` is `<state>/notices`, made by the app.
   - When `kill -0 "$MENUZ_APP_PID"` finds the app gone, the wrapper also runs `osascript` as before, and the file stays.
   - The app's process source, on the wrapper's exit, reads `<notices>/<id>`, posts it through `UNUserNotificationCenter` and removes it. No file means no notice was due.
   - At launch, the app posts one notice for any files left, "<n> run(s) ended while menuz was not running: see the log", and removes them. That also covers a run that saw the app alive just before it quit.
   - `Notifier` posts through `UNUserNotificationCenter` too, for the app's own notices. Authorisation is requested at launch, for `.alert` and `.sound`.
   - When the centre's settings say menuz may not post, the notice becomes a log line naming System Settings > Notifications > menuz, and so does a failed `add`. A notice about a log write that failed goes to OSLog instead, as now.
   - A delegate gives `.banner` and `.list` so a notice shows even while menuz is active.
   - `Run.noticeScript` stays as the wrapper's fallback only.
2. **Place.** A first launch on a full menu bar lands leftmost, behind macOS 27's overflow, where hv could not find it. menuz seeds no position. When the app's defaults hold no `NSStatusItem Preferred Position Item-0`, the launch logs, and posts as a notice, one line: "menuz is in the menu bar; if the bar is full it may be hidden: hold Command and drag its icon where you want it". The help's line on this is dc's.
3. **App icon.**
   - A drawn mark at `native/macos/Menuz/design/menuz.svg`, with its silhouette at `design/menuz-mark.svg`, made in this WP. Apple's SF Symbols licence does not allow a symbol as an app icon, so vc's "rendered from the SF Symbol" is not taken.
   - `bin/devbin macos app-icons` rasterises them with `rsvg-convert` into the tracked `Menuz/Assets.xcassets`: `AppIcon` at seven sizes, and `MenuBarIcon` as a template at 1x, 2x and 3x. This is Intent's `cmd_app_icons`, ported.
   - `project.yml` sets `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon`. A build needs no `rsvg-convert`, and `doctor` reports `rsvg-convert` only as `app-icons`' need.
4. **Default glyph.**
   - `MenuSpec.icon` becomes optional: nil when the file has no `icon:`. The app then shows `MenuBarIcon`, the mark as a template image, which hv can pick out in the overflow. `icon:` still names an SF Symbol and is validated as now (D8 otherwise stands).
   - The example's `icon:` line is commented out, saying the mark is the default.
   - hv's own `~/.config/menuz/menuz.yaml` (from `menuz init`) sets `icon: terminal` and keeps it until hv removes that line. cc tells hv rather than edit hv's file.

The arngz "command not found" in hv's first runs is not menuz's: hv's login shell has no `arngz` while the tap lacks 2.13.0, and dc linked it into `~/.config/menuz/bin`.

**The verbs.**

- **`build [--release] [--unsigned]`**
  - Refuses, exit 2, with no Xcode (`xcodebuild -version` fails), with no `xcodegen`, or with no source tree.
  - Runs `xcodegen generate` only when the project is stale: when `project.yml`, or the set of file paths under `Menuz/`, `MenuzTests/` and `MenuzKit/` (paths, not contents, since a changed source is Xcode's business and a new or removed one is xcodegen's), hashes differently from the hash kept at `${XDG_STATE_HOME:-~/.local/state}/menuz/build/xcodegen.hash`, or when `Menuz.xcodeproj` is absent.
  - Then runs `xcodebuild` Debug, or Release with `--release`. The products and every intermediate go under `${XDG_STATE_HOME:-~/.local/state}/menuz/build/macos`, through `-derivedDataPath`, `SYMROOT`, `OBJROOT` and `SHARED_PRECOMPS_DIR` (measured in WP-03: this machine's Xcode location preference otherwise writes into the tree).
  - `--unsigned` adds `CODE_SIGNING_ALLOWED=NO`, for a machine with no identity (CI).
  - The stamps are passed as build settings (see `stamps`). A failed `xcodebuild` is exit 1, with its last 40 lines.
- **`test [--unsigned]`**: `xcodebuild test` of the scheme, so MenuzKitTests and MenuzTests both, with the same paths and settings. Exit 1 on a red test, 2 without Xcode or the source.
- **`stamps`** prints what the next build would stamp, one `NAME=value` per line:
  - `MENUZ_VERSION` from `opt/menuz/VERSION`;
  - `MENUZ_BUILD`, the commit count (`git rev-list --count HEAD`);
  - `MENUZ_COMMIT`, the short commit;
  - `MENUZ_SOURCE_TREE`, the tree hash of `native/macos/Menuz`, with `-dirty` when it has uncommitted changes. This is WP-02's `source_stamp`, the one function `status` compares against.

  In an install it prints what the installed bundle carries, and says so.

- **`install`**
  - In a source clone, in order: build Release; quit every running copy by bundle id; replace `~/Applications/Menuz.app`; unclaim the build products; register the installed bundle; launch it.
    - Quitting is JXA's `Application('com.matthewsinclair.utilz.menuz').quit()`, then a wait of up to 5 s for every pid of the bundle id to go.
    - The replacement is a `ditto` to a sibling, then a rename over the old one, so a failure leaves the old copy whole.
    - Unclaiming is `lsregister -u` on the build product, so Launch Services never opens the dev copy for the bundle id.
    - Registering is `lsregister -f` on the installed bundle.
    - The launch is `env -i HOME="$HOME" open -a ~/Applications/Menuz.app`, so the app captures its own login shell rather than inheriting the shim's environment.
    - A step that fails after something changed is exit 1, naming the step. A refusal before any change (no Xcode, no source) is exit 2.
  - In an install: the release asset (below), then the same quit, replace, register and launch.
- **`use [dev|installed]`**: records the choice in `${XDG_STATE_HOME:-~/.local/state}/menuz/use`; with no argument it prints the choice, and why (`installed (default)` when there is no record, D6). `start`, `restart`, `status`, `validate` and `render` act on the chosen build, as WP-02's `selected_build` already does for the last three. Any other word is exit 2.
- **`uninstall`**: quits every copy; asks the installed copy to unregister its login item, through a new arm `--unregister` (`SMAppService.mainApp.unregister()`, printing the result); unregisters the bundle (`lsregister -u`); and removes `~/Applications/Menuz.app`. An unregistration that fails is reported and the removal goes on. Exit 0 when there was nothing installed, saying so.
- **`start`, `stop`, `restart`**:
  - `start` opens the chosen build with an empty environment; it is exit 2 when that build is not there, naming it.
  - `stop` quits every copy by bundle id.
  - `restart` is `stop`, then `start`.
- **`doctor`** prints one line per precondition with its state, exit 1 when any fails:
  - Xcode selected (`xcode-select -p`, `xcodebuild -version`);
  - xcodegen;
  - a Developer ID or Apple Development identity (`security find-identity -v -p codesigning`, counted, never printed whole);
  - `MENUZ_HOME` and its `menuz.yaml`;
  - the yaml valid through the chosen app's `--validate`;
  - the app installed;
  - the app running;
  - the login item.

  In an install it skips the build lines and says why.

- **`status`** gains nothing: WP-02's lines already cover the design's row.

**The release asset.**

- **The name.** `Menuz.app.zip`, as Intent names `Intent.app.zip`. It is a `ditto -c -k --keepParent` of the stapled bundle, with no version in the name: the release's tag carries it.
- **Signing and publishing**, on hv's machine, after `bin/devbin release` has made the release object:
  1. `bin/devbin macos app-sign`: `utilz menuz build --release`, the one build path; a copy staged out of the products; the bundle signed inside-out with the Developer ID identity and the hardened runtime; then the identifier, the team and the runtime flag read back off it.
  2. `bin/devbin macos app-notarize`: `notarytool submit --wait`, the ticket stapled, then a quarantined copy checked by `spctl -a -t exec` for `source=Notarized Developer ID`.
  3. `bin/devbin macos publish`: the zip made and proven again by unzipping it and checking the bundle inside. It is refused if the bundle's `CFBundleShortVersionString` is not `opt/menuz/VERSION`, if the release object for `VERSION`'s tag does not exist, or if it already holds a `Menuz.app.zip`. Then `gh release upload <tag> Menuz.app.zip`.
- **Credentials.** They live in the login keychain under `utilz.apple.APPLE_ID`, `utilz.apple.APPLE_APP_PASSWORD` and `utilz.apple.APPLE_TEAM_ID`, stored once by `bin/devbin macos store-creds`. That command is interactive and hv's to run. `doctor` reports each as PRESENT or MISSING, never a value. The identity is derived from the team id, as Intent's is.
- **How the asset reaches the release object.** Utilz's release core attaches no files: step 9 makes the object with `gh release create`, title and notes only, and nothing in the tree uploads an asset. `publish` attaches the zip to the object step 9 made, after it exists. The vendored core is not touched: `cmd/macos` is the project's own command, as it is in Intent (watch-out 6).
- **A keg's install.**
  - It fetches `https://github.com/matthewsinclair/utilz/releases/download/<VERSION>/Menuz.app.zip` with `curl -fsSL`, where `<VERSION>` is the tree's top-level `VERSION`, the tag the keg was built from. curl rather than gh, because gh is not a Utilz dependency and nothing else in a keg fetches.
  - It unzips with `ditto -x -k` into a temporary directory, then verifies:
    - `codesign --verify --deep --strict`;
    - `spctl -a -t exec -vv` reading `source=Notarized Developer ID`;
    - the bundle id `com.matthewsinclair.utilz.menuz`;
    - the bundle's version is the tree's `opt/menuz/VERSION`.
  - Any failure refuses the install with exit 1, naming the check, and nothing is replaced.
  - A 404, a release with no asset, is exit 1 naming the URL and saying the release carries no Menuz.app.

**CI.** A `menuz-app` job on `macos-15`, `if: github.ref_type == 'tag' || github.event_name == 'workflow_dispatch'` (Gtools' gate, so a push is not an Xcode build): `brew install xcodegen`, `bin/utilz menuz build --unsigned`, `bin/utilz menuz test --unsigned`. It reads no secrets and attaches nothing. The Linux legs already run `menuz.bats` in the explicit utility loop, and `macos.bats` joins the macOS leg's full run.

**The login item (AC-05.2)** is a hand run, vc's: the installed copy registers itself at its first launch (WP-03's `LoginItem`), status reports it, and the menu is back after a logout and login. The logout is hv's own keypress.

**Tests.** Written red first, both bashes, shellcheck-clean, every refusal asserted by its line and its exit code.

`menuz.bats` gains fakes on PATH: `xcodegen` and `xcodebuild` recording their arguments, `lsregister`, `open`, `osascript`, `codesign`, `spctl`, `ditto`, `curl` and `git`. It covers:

- every verb's refusals without Xcode, without xcodegen, and without the source tree;
- `build`'s staleness: a second build runs no xcodegen, while a changed `project.yml` or an added source does;
- the location settings and the stamps passed to `xcodebuild`;
- `--release` and `--unsigned`;
- `stamps`' values against a fixture git tree;
- `install`'s sequence, read from the fakes' records in order, and its exit 1 naming the step for a failed quit, replace or launch;
- `use`'s record and its effect on `start` and `status`;
- `uninstall` with and without a bundle;
- `doctor`'s lines and its exit;
- the keg install: a fixture install tree, a fake `curl` serving a zip, a fake `codesign` and `spctl` passing; a failed signature, a wrong version and a 404 each refused with nothing replaced.

`macos.bats` covers `bin/devbin macos`:

- with no credentials: `doctor` reports MISSING, and `app-notarize` refuses;
- `publish` refuses a version mismatch, a missing release object and an asset already uploaded, each with a fake `gh`;
- the sign sequence against fake `codesign`, `security` and `xcrun`.

MenuzKitTests and MenuzTests gain, red first:

- the wrapper with a live `MENUZ_APP_PID`, which writes the notice file, through the temporary name, with the text for each notify setting, and calls no `osascript`;
- the wrapper with a dead pid, which writes the file and calls the fake `osascript`;
- `never`, and a `failure` that exits 0, which write no file;
- the leftover summary's text for one run and for several;
- the first-run line, given and withheld by whether a position is recorded;
- `MenuSpec.icon` nil without `icon:`, and the example's validation still ok;
- in MenuzTests, a spawned run whose notice file the app's exit handler reads and removes, with the poster faked, so no real notification is posted.

AT-04.4's claim is rewritten to what it measures: the wrapper's decision and text, and the hand-off to the app. That AT edit is vc's.

AC-05.4's `bin/devbin check all` and the estate suite on the closing SHA are vc's. The docs (`help/menuz.md`, the README section, the CHANGELOG entry, and `docs/releasing.md`'s new step for the app asset) are dc's, at the close.

## Acceptance

Acceptance Criteria for this work package are RENDERED into `ST0027/acceptance.md`, under the `WP-05` heading. THAT FILE IS A GENERATED VIEW -- a row authored there is discarded by the next sync. The contract is canon in the thread's model, and the verbs write it: `intent ac new` and `intent at new` mint a row, `intent ac edit` and `intent at edit` reword or re-cite one, and `intent ac satisfy|unsatisfy|descope|rescope|withdraw|reinstate` and `intent at green|red|na` move its state. This cover never restates them.

---

_Generated by Intent v3 from the thread canon. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
