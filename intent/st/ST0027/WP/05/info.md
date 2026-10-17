---
wp_id: WP-05
title: Build, install, launch and the close
scope: S
status: Done
---

# WP-05: Build, install, launch and the close

## Objective

Build, install, launch and the close: the shim's remaining verbs (`build`, `test`, `install`, `use`, `uninstall`, `start`, `stop`, `restart`, `stamps`, `doctor`), the install a keg makes from the signed release asset, the signing and publishing of that asset, and CI. WP-02's verbs (`init`, `edit`, `log`, `validate`, `render`, `status`) stand. This note settles what design.md leaves open for WP-05. design.md's shim table, "Build layout", "CI" and the keg paragraph are the contract, with D6, D7 and D12.

**D12: D7's "same as Intent" is local signing, not CI.** Intent's workflows read no secrets and run no codesign or notarytool. Intent signs and notarises on the maintainer's machine, through its project-local `bin/devbin macos`, with the Apple credentials in the login keychain ("no key material in this repository, in CI config, or in any file this writes"). It publishes the stapled bundle as the release asset `Intent.app.zip`. hv confirmed this reading in cc's session on 16 Oct ("same as intent", "Correct."), and vc recorded it as D12, with design.md's CI paragraph and AC-05.3 reworded to match. So:

- CI builds unsigned and tests, on a tag or a dispatch, and reads no secrets.
- Signing, notarising and attaching the asset are a maintainer's step, on hv's machine.

**Layout.**

| Where                         | What                                                                                                                                                                                        |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `opt/menuz/menuz`             | The verbs below, bash 3.2 under `set -euo pipefail`, shellcheck-clean. Exit codes as arngz: 0 done, 1 failed after changing something (naming the step), 2 refused before anything changed  |
| `bin/.devbin/cmd/macos`       | Project-local, Utilz's own (not the vendored core): `doctor`, `store-creds`, `app-sign`, `app-notarize`, `app-verify`, `publish`, ported from Intent's app half, beside WP-06's `app-icons` |
| `.github/workflows/tests.yml` | The `menuz-app` job                                                                                                                                                                         |
| `opt/menuz/test/menuz.bats`   | The verbs' tests, with fakes on PATH                                                                                                                                                        |
| `opt/menuz/test/macos.bats`   | `bin/devbin macos`'s refusals and sequence, with fakes on PATH                                                                                                                              |

**Source clone or install.** As prez's shim does (ST0014 D5): a tree with `manifest.sha256` at the shim's own tree root is an install, a brew keg or a `utilz install` publish. Neither carries `native/macos/Menuz`, which the published set leaves out. In an install, `build` and `test` refuse by name, exit 2, naming the source clone (`git clone https://github.com/matthewsinclair/utilz`), and `install` takes the release asset (below). In a source clone, `install` builds.

**The first-use fixes are WP-06's (D13), landed ahead of this WP's remainder on hv's "Hold off"; the `--unregister` arm is this WP's.**

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

AC-05.4's `bin/devbin check all` and the estate suite on the closing SHA are vc's. The docs (`help/menuz.md`, the README section, the CHANGELOG entry, and `docs/releasing.md`'s new step for the app asset) are dc's, at the close.

## Acceptance

Acceptance Criteria for this work package are RENDERED into `ST0027/acceptance.md`, under the `WP-05` heading. THAT FILE IS A GENERATED VIEW -- a row authored there is discarded by the next sync. The contract is canon in the thread's model, and the verbs write it: `intent ac new` and `intent at new` mint a row, `intent ac edit` and `intent at edit` reword or re-cite one, and `intent ac satisfy|unsatisfy|descope|rescope|withdraw|reinstate` and `intent at green|red|na` move its state. This cover never restates them.

---

_Generated by Intent v3 from the thread canon. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
