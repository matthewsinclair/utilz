# Changelog

All notable changes to the Utilz framework will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

The section still open names its version: `## [X.Y.Z] - unreleased`, never `## [Unreleased]`. Devbin's release core finds a section by its version and dates it at the cut; an unnamed section is one it cannot find (ST0019 D2).

## [2.14.3] - 2026-10-24

### Changed

- **Utilz follows the dev, opt, brew contract every tool released through Homebrew follows** (issue 0105; devbin's `docs/dev-opt-brew.md` at devbin commit aeed31e4, hv's ruling of 2026-10-24). A user installs from brew; dev and opt are the maintainer's, and the docs say so: the README's Installation is the brew way in (tap, `brew trust --formula`, install), and the dev, opt and brew trees are described in one closing section for the maintainer.
- **`utilz --version` is one line**: `utilz <version> (<tree>, <commit>) at <root>`, the tree being dev, opt or brew, a brew root named by brew's opt link, and `+dirty` after a dev commit while the runtime set is dirty. It replaces the framework's three lines (`utilz:<version>`, the description, the tree), the solo form of hv's ST0015 ruling. A utility keeps its pair and description, with the line last. CI's recorded verdict moves to `utilz doctor`, which prints the version line first and fails on a tree it cannot name.
- **`utilz use dev|opt|brew` is the one switch**. It points every link in `~/.local/bin` at dev or opt, creating the missing ones; `use brew` removes them, so Homebrew's links answer, as they do for a user who never runs `use`. `utilz use` with no word, and doctor, fail when a link is shadowed by an earlier `$PATH` entry or the links serve more than one tree. `utilz relink` is retired and names `use`.
- **`utilz upgrade` upgrades the tree it runs from**: in dev `git pull --ff-only` and the build, in brew `brew update` and then `HOMEBREW_NO_AUTO_UPDATE=1 brew upgrade utilz`, and in opt it names `utilz install --force` in the dev checkout. It no longer publishes, so ST0014's AC08 -- upgrade leaving a file edited in place inside an install, at its install-time checksum -- retires: doctor names that drift, and `install --force` overwrites it.
- **`utilz install` publishes only from a dev checkout, to `$UTILZ_INSTALL_PREFIX`**, which the sleeve sets; `install.prefix` leaves the committed `opt/utilz/utilz.yaml`, which every Homebrew install shipped. Only a dirty runtime set refuses a publish, not a doc or a board, and `--force` is the one republish, over a prefix whose manifest Utilz wrote.
- **The manifest takes the contract's form**: `# key: value` header lines (`tool`, `version`, `source_commit`, `managed_by`, then Utilz's `source_tree`, `ci_state` and `ci_detail`) over a body `shasum -a 256 -c` reads. An install with the old form is named as one: doctor fails an old opt install, naming `utilz install --force`, and notes an old Homebrew install, naming `brew upgrade utilz`, which replaces it.
- **The Homebrew formula is a template, rendered and published by `tools/formula`** (`render <tag> <out>`, `publish`), which replaces `tools/formula-bump`; nobody types a tag or a commit.
- **`utilz doctor` names its checks, with no step numbers**, and says `brew link utilz` or `utilz use <tree>` when `utilz` is not on `$PATH`, never to export `UTILZ_HOME`. **`utilz emacs install --symlink`** from the Homebrew install links through brew's opt link, so the bridge survives `brew upgrade` and `brew cleanup`. **`menuz build`** in an install names `menuz install` first.

### Fixed

- **`bin/devbin macos` takes only the release tag's own build of Menuz.app** (issue 0103). `app-sign` built whatever commit HEAD was, and `publish` checked only the bundle's id and version. So 2.14.2's first publish, run after the nodes' records had moved main five commits past the tag, attached a Menuz.app stamped with that later commit and the kind `dev`. It was deleted and rebuilt at the tag before the tap was pushed, so no install fetched it. `app-sign` now asks `utilz menuz stamps` what the build would carry, and refuses, building and signing nothing, unless its kind is `release`; the refusal names the stamps, the tag and the route through a worktree at the tag. Once it has staged the build, it refuses, signing nothing, a copy that `publish` would refuse, since another tree's build can replace the product in between. `publish` refuses, uploading nothing, a bundle whose `MenuzKind` is not `release`, a bundle whose `MenuzCommit` is not the commit the tag names, or is not a commit at all, and a tag that is not in the tree. `app-sign`, `app-notarize` and `app-verify` print the bundle's version, build, commit and kind, and `docs/releasing.md` runs the three steps in a worktree at the tag.
- **`bin/devbin macos publish` no longer leaves a Launch Services record for each Menuz.app it unpacks to prove its zip** (issue 0104). `stapler validate` on the unpacked copy registers it with Launch Services, and `publish` then removed the copy and left the record, pointing at a path that no longer existed, under menuz's bundle id; after 2.14.2's publish there were three. `publish` now drops the record with `lsregister -u` and removes the copy on every way out: an upload that worked, every refusal after the unpack, and an interrupt. It then reads Launch Services' records and requires none left under the copy's directory. A record it could not drop is said, naming it and the command that drops it, and makes a `publish` that otherwise worked exit 1, after saying what it published.
- **Menuz's bundle id opens the installed app, never a build** (issue 0106). Xcode registers each app it builds with Launch Services, and so can `codesign`, `stapler` and `spctl`, so the Debug and Release products and the staged copy `bin/devbin macos app-sign` signs kept records. Launch Services then resolved `com.matthewsinclair.utilz.menuz` to a build product, so `open -b`, a login item or a notification's click could start a build. `utilz menuz build`, `test` and `install` now drop the product's record after xcodebuild, a failed build's included, and a Homebrew install drops the fetched asset's. `app-sign`, `app-notarize` and `app-verify` (for `dist`) drop the staged copy's record on every way out, and the quarantined copy they check with `spctl` has its record dropped before it is removed. `menuz install` still registers `~/Applications/Menuz.app`. A record that will not drop is a warning naming the bundle and the `lsregister -u` line that drops it, and the verb's own exit stands. `utilz menuz doctor` has a `records` line, `WARN` for each record of the bundle id at any path but the installed app's. Launching the development build with `menuz use dev` registers it again, as that choice asks, and the next build drops it. lsregister's path, the bundle id, the reading of Launch Services' records and the checked drop now live in one lib, `opt/menuz/lib/launch-services.sh`, which menuz and `bin/devbin macos` both source, in place of the copy `bin/devbin macos` kept.

## [2.14.2] - 2026-10-23

### Changed

- **menuz builds with Xcode 27.1 or later, and CI builds and tests the app on Xcode 27.1** (issue 0097). The release's `Menuz.app` was already built with Xcode 27.1, while menuz's floor and the `menuz app` job named Xcode 26. `menuz doctor` in a source clone now fails an Xcode older than 27.1, and the job runs on GitHub's `xcode-27` image with Xcode 27.1 named. The app still runs on macOS 26.
- **menuz's Log opens menuz's own log window, not Console.app** (issue 0072). The window is arca_swift 0.2.0's console, made the first time Log is chosen. It follows menuz.log as it grows and across a truncation or a rotation; shows in red a failed run, a run not started, a refusal, and a form or an `open` that failed, in orange a run cancelled or a notice not posted, and in blue each run's start and exit 0; and finds with Command-F. menuz goes from 0.4.5 to 0.4.6.
- **menuz's log window colours the lines that say something did not happen outside a run** (issue 0102). Each showed plain, like the lines that say all is well. A label or `each` that did not realise shows red, and so does every line the top row logs: its refusals of `masthead.yaml` and `about.md`, and the About page or a link in it not opening. Those lines now open with `masthead: `, in the log and on `menuz render`'s standard error. Orange: a realise that passed its `realise` seconds, a login item menuz could not register, a login shell whose environment could not be read, a menu bar mark missing from the app, and notifications turned off or not set up. menuz goes from 0.4.6 to 0.4.7.

### Fixed

- **prez's acceptance suite no longer leaves its decks in TMPDIR, and a `pdf` whose print fails leaves nothing behind** (issue 0095). `prez present` stages its deck in TMPDIR and leaves it there for the browser on purpose, so the suite's six `present` runs left six decks in the caller's TMPDIR on every run; the suite now gives everything it runs a TMPDIR inside its own work directory, removed when it ends. `prez pdf` staged its HTML in TMPDIR and removed it only after a print that worked, so a print that failed left it behind; it now stages in a scratch directory of its own, removed on every path out, and a removal that fails is said. The scratch directory is showreel's, moved into `artifact` so the two tools share one. prez 2.5.4.
- **showreel says what its clean-up and its reads could not do, rather than dropping it** (issue 0096). `showreel video` said nothing when it could not remove its `.partial` after a failed encode, stop an ffmpeg it had abandoned, or stop a Chrome that started without its pipes. A failure after a recording that worked (ffmpeg not finishing, a wrong frame count, a rename or `frames.tsv`'s write) dropped what Chrome's ending could not do. Its sweep for interrupted runs took an `_out/` it could not read as empty, and both `video` and `build` printed a size they could not read as 0.0 MB. Each failure now names those leftovers under its own message, the sweep refuses a directory it cannot read, a partial already gone counts as removed, and a size not read prints as `? MB`, with the reason said. One of video's own tests no longer leaves a directory in TMPDIR when it fails. prez 2.5.5.
- **showreel never writes over a revision it has delivered, and says what it cannot read in `_out/`** (issue 0098). `showreel build` names each revision one past the highest it lists in `_out/`, and it took an `_out/` it could not read as empty, so the next build named 001 again and wrote over a delivered 001 with nothing said, and `--keep` pruned nothing and said nothing. A build now refuses an `_out/` it cannot read, naming it, and creates each revision rather than writing over a file, so two builds of one reel at once cannot take one number. Pruning finds a revision's video by its own entry, so a slot is pruned whole and one it cannot check is refused by name, and a size it cannot read makes the total `? MB`, with the reason said. `--out` and a fixed name are overwritten, as they always were. prez 2.5.6.
- **showreel's report of unused assets says what it could not read, rather than reporting less** (issue 0099). `showreel build` and `showreel check` end by listing the files under `assets/` that the reel does not use, with their total size. A directory under `assets/` that the report could not read was skipped, so its files were never listed, and an `assets/` it could not read at all reported nothing spare; a size it could not read counted as nothing, so the total printed low. Each directory it cannot read is now said, naming it and why, and a size it cannot read makes the total `? MB`, with the reason said. prez 2.5.7.
- **showreel never puts a recording over a file at a slot's video name** (issue 0100). `showreel video` names a slot's video from its HTML's number alone, and the finished recording replaced whatever was at that name, so a video kept after its HTML was deleted by hand was replaced with nothing said. A build now checks the slot whole before it writes anything: a file at either of the slot's video names refuses, naming it, so no HTML is left beside another build's video, and a recording checks its name again before it is put in place. `-o` and a fixed name overwrite, as they always did. prez 2.5.8.
- **showreel refuses an output pattern whose names it cannot keep apart, and `check` refuses it too** (issue 0101). `showreel build` took an `output:` pattern that named a directory (`sub/{nnn}.html`, `../{nnn}.html`, an absolute path, or a name such as `..` or `..html`), so a revision went where its listing never counts it; one with the counter in the name's last extension (`{date}.{nnn}`), so every revision's video took the same name; and one ending in a video's or an unfinished recording's extension (`.mp4`, `.mov`, `.partial`), so the HTML took one of its own videos' names, or `showreel video` removed it as an interrupted recording's leftover. Each is now refused where the stem is built, naming the pattern, with its remedy, and `showreel check`, which called such a reel valid, refuses what `build` refuses, an `iso:` that is not a date included. prez 2.5.9.

## [2.14.1] - 2026-10-19

### Added

- **menuz's own items can sit anywhere in its menu** (issue 0069). A `menuz:` entry in `menuz.yaml` places **Log** (`menuz: log`), **Edit…** (`menuz: edit`) or **Reload** (`menuz: reload`) where it stands, in a submenu as readily as at the top, so a menu that keeps its tools in a **Utilities** submenu can keep menuz's there too. Each can be placed once. Those a file does not place stay below its entries, where all four sat before, and **Quit menuz** is always last there. `menuz validate` refuses any other word, `quit` included; a second placing, naming the entry that placed it first; and a `cwd` or `notify` beside one, which would do nothing. A file with no `menuz:` entry keeps all four below its entries, as before. menuz goes from 0.1.0 to 0.2.0.
- **`arngz current` names the desk the screen was last arranged as** (issue 0070). An `apply` that ran records its desk, whatever its report says, and so does a `discover --save`. A `--dry-run`, or a refusal before anything changed, leaves the record as it was, and `delete` of that desk clears it. The record is one file, `${XDG_STATE_HOME:-~/.local/state}/arngz/current`. `current` prints the name; it prints nothing and exits 1 when none is recorded or the desk has left the catalogue, so `$(arngz current)` is empty then. It asks Hammerspoon nothing, so a menu can run it at every open. `current` joins the verbs, so a desk can no longer be named `current`. arngz goes from 1.0.1 to 1.1.0.
- **A param's `default:` can come from the shell, and an `each` can tick one of its items** (issue 0071). A `default:` holding a `$` or a backtick is realised by the login shell when its form opens, as a label is at a menu open, waiting at most `realise` seconds. Its field starts empty, and **Run** waits for it while nothing is typed there; what has been typed is never overwritten. A default the shell cannot give is said under its field, which is left to be typed, and in the log under the item's label, as a failed `choices:` line now is too. An `each`'s new `checked:` goes to the shell with the labels at every menu open and ticks the item whose line equals what it gives, so `checked: "$(arngz current || true)"` ticks the desk the screen was last arranged as, and `menuz render` prints `✓ ` before that item. `menuz validate` refuses `checked:` anywhere but an `each`. A `$(...)` that fails fails its string, so a command that may print nothing and fail is written with its fallback: `|| true` for no tick, `|| echo today` for a default. The example `menuz.yaml` that `menuz init` writes now ticks the current desk under **Desks…**, and **Discover…** offers that desk's name, or `today` when none is recorded, and refuses an empty answer. menuz goes from 0.2.0 to 0.3.0.
- **menuz's top row opens an About window, and both can be your own** (issue 0073). The top row is now arca_swift's masthead: `menuz <version>` in bold over a smaller `<commit> · <kind>`, with menuz's icon, where it was one greyed line. Choosing it opens menuz's first About window, which says what menuz is, which menu file it reads, and where to get help. Both are read from a `masthead.yaml` and an `about.md` in the app, and a copy of either in `${XDG_CONFIG_HOME:-~/.config}/menuz/` replaces the app's with no rebuild. `menuz render` prints the row's two lines first. menuz goes from 0.3.1 to 0.4.0.
- **Utilz runs on Linux, and says what needs macOS** (issue 0083). Nothing in the install needed macOS but the formula's `depends_on :macos`, which is gone, and its caveats now say what does. A utility's yaml, and a dependency entry, may declare `platforms: [macos]` or `[linux]`. macoz refuses each command off macOS, exit 2, as `macoz needs macOS, so it is not available on Linux`, where it exited 1 before parsing its arguments, so its usage now answers everywhere; arngz's apply, a bare desk, diff, discover and `init --yes` refuse the same way before they read or ask anything, while list, show, delete and current work anywhere, `init` makes the catalogue, and `doctor` checks the catalogue alone. `utilz list` marks a utility `(macOS only)` where it is not available, and `utilz doctor` says what is not here, in one line each, rather than count it as missing or offer a cask brew has only on macOS. clipz names xclip and wl-copy as optional on Linux, macoz names fileicon for `setpicfor`, stampz takes its checksums as install does, with `shasum` or `sha256sum`, and CI's Linux leg now runs cleanz's, clipz's and macoz's suites too. macoz goes from 1.0.0 to 1.0.1, arngz from 1.1.1 to 1.1.2, clipz from 1.0.0 to 1.0.1, and stampz from 1.0.0 to 1.0.1.
- **menuz says what needs macOS** (issue 0083). Off macOS, `validate`, `render`, `build`, `test`, `install`, `uninstall`, `start`, `stop`, `restart` and `edit` without `--editor` refuse, exit 2, before they ask anything, as `menuz build needs macOS and Xcode, so it is not available on Linux`, naming what works there: init, use, log, stamps, status, doctor and `edit --editor`. `uninstall` and `stop` refuse there, where they did nothing and exited 0. `status` prints that one line, and `doctor` says it and checks the menu file alone. menuz goes from 0.4.2 to 0.4.3.

### Changed

- **menuz's menu draws a line under its version row, and its own items are one word each** (issue 0069). A separator now divides the identity row from the menu, and `menuz render` prints a `---` under its first line to match. A file that ends in a separator shares it with the line above menuz's own items, rather than showing two. **Edit Menu…** is now **Edit…**, and **Open Log** is **Log**, which reads **Log (no log yet)** before there is a log. A form is titled with its item's label less a trailing ellipsis, so **Discover…** asks in a form titled **Discover**. The example `menuz.yaml` that `menuz init` writes is regrouped to match: a **Desks…** submenu of the known desks, **Discover…**, and a **Utilities** submenu holding the machine's items, **Hammerspoon**, and menuz's own **Log**, **Edit…** and **Reload**. A menu file of your own is not touched.
- **A separator that starts menuz's menu, or follows another at its top level, draws no line of its own** (issue 0071). The line under the identity row, or the one before it, serves, and `menuz render` prints one `---` to match. Inside a submenu, separators are drawn as the file gives them.
- **menuz needs macOS 26 or later, and Xcode 26 or later to build** (issue 0073), the floor of arca_swift, whose masthead its top row is. `menuz doctor` now fails an Xcode older than `project.yml`'s `xcodeVersion`, naming both, where it read any Xcode as ok, and CI builds and tests the app on macOS 26.

### Fixed

- **prez refuses a `mermaid:` value it cannot read, as it does for `numbering:`** (issue 0066). `mermaid:` turned diagrams on for `true`, `yes` or `1` and read every other value as off, so `mermaid: ture` built a deck whose diagrams were plain code blocks and nothing said why. `mermaid:`, `numbering:` and the `<!-- numbering: -->` slide directive now read one vocabulary, in any case: `on`, `true`, `yes` and `1` turn a switch on, and `off`, `false`, `no` and `0` turn it off. Anything else is refused by name, exit 2, naming the key and the value. No deck that built before changes meaning; `numbering:` gains `yes`, `no`, `1` and `0`. An included fragment's `mermaid:` is now named in the "ignored" warning when it is off too. prez goes from 2.5.0 to 2.5.1.
- **A flaky Ubuntu test of `utilz use`** (relink.bats AT17). It compared each link's `stat -f` before and after, which on Linux reports the filesystem, so a write anywhere on the runner failed it (CI run 39036616338); it now compares each link's own inode and mtime.
- **menuz's labels, ticks, `each` lines, choices and defaults run the menu's own `bin/` first, as its runs do** (issue 0078). The login shell that realises them had `bin/` first on `PATH` only until its login files ran, and a login file that puts its own directories first, as Homebrew's `shellenv` does, put them ahead of it. So `checked: "$(arngz current || true)"` ran the Homebrew keg's arngz 1.0.1, which has no `current`, and ticked nothing, and **Discover…** offered `today`, while a run of the same line used the menu's own arngz. A realise now puts `$MENUZ_HOME/bin` first after the login files, as a run does, and the two take that line from one place. menuz goes from 0.3.0 to 0.3.1.
- **arngz no longer refuses a display with one desktop just after it attaches** (issue 0077). arngz reads each display's desktops in Mission Control's order from the list macOS keeps in `com.apple.spaces`, and just after a display attaches macOS has not written that list. `discover` and `apply` refused then, even for a display with one desktop, whose order is never in doubt, and the refusal's fix said only to fix what the engine named. A display with one desktop now needs no list, though apply adds no desktop to it until macOS records it, since it could not then follow the new one. One with two or more is still refused, exit 2, until macOS records them, and so is an apply that would add a desktop to a display of one. Each refusal comes before anything changes and says so, with its fix: wait for macOS to record them, then run arngz again. arngz goes from 1.1.0 to 1.1.1.
- **`utilz use` and `utilz relink` link a utility added since the links were made** (issue 0079). Both repointed the links already in the bin dir and made none, so a utility that arrived later never reached PATH through them, and the report did not say so: on a machine whose links predate arngz and menuz, `use dev` could not give either. Where the bin dir holds a link into a Utilz tree, each utility of the tree with no link there now gets one, reported as `linked:`, and a file of something else's under that name is left alone and reported. A link for a utility the tree does not have, as for an install published before that utility, is now left pointing where it does and reported, where relink used to point it at a file that did not exist. A relative `--prefix` is now made absolute first: relink wrote it into each link as typed, and a link's relative target is read from the link's own directory, so every link it touched named nothing. The summary counts what was linked.
- **menuz's refusal of a file that is not YAML names what is wrong** (issue 0074). It kept only the first line of the YAML library's error, and an error that carries a context, such as `while scanning a simple key`, has its problem on the second line, so the refusal said where the reader was and dropped what it found: `not YAML: 3:1: error: scanner: while scanning a simple key in line 2, column 1`. The refusal is now one line with both, `... in line 2, column 1: could not find expected ':'`, and a scanner, parser or composer error with no context no longer ends in a stray colon. menuz goes from 0.4.0 to 0.4.1.
- **`cleanz --detrope` reports on a long text, and `utilz doctor`, `utilz integration commands` and `utilz emacs doctor` name a yaml they cannot use** (issue 0080). Each ended in silence under `set -euo pipefail`. cleanz exited 141 with no trope report once its matches, or one matching line, passed the 64 KiB pipe, and the three utilz verbs stopped at their first read of a yaml yq could not read, before a word. Each now names what it cannot use and goes on. doctor counts a yaml it cannot read, or a `dependencies` or `optional_dependencies` that is not a list, as an issue, and reaches its verdict. The manifest warns and leaves the utility out, and emacs doctor lists it as invalid. One function now holds the integration block's rules for the manifest and emacs doctor alike, so `flags` may be absent, for none, and an integration block that is not a map, a `flags` that is not a list, or an `input` or `output` outside the bridge's sets, is refused by name in both.
- **Tests no longer write the user's own state** (issue 0082). syncz's unison tests left their archives in the user's own unison dir, 18 a run, and ran under the user's own `default.prf`. cryptz's round trip ran gpg on the user's keyring and, where the key was missing, looked it up over the network, leaving a dirmngr running. macoz's background tests set the desktop picture, and clipz's tests overwrote the clipboard. The test helper now points `UNISON` into each test's own dir and fails gpg closed outside a home of the test's own. cryptz's round trip runs for real with a throwaway key, and macoz's and clipz's tests assert against stubs.
- **Two runs started at once while menuz's run-id store is new each get an id** (issue 0086). menuz takes each run's id from `next-run` in its state folder under a lock, and a run that made that file showed it before it held the lock, so a second run started in that moment could find it empty and was refused, logged with nothing after `holds no id:`. The store is now made whole, already holding the first id, and synced to disk before any run can see it, and a new store is its owner's alone (mode 0600, where it was 0644). A run refused an id is logged with why, after the store's path: it `is empty`, it `holds no id:` and what it holds, or the step that failed, such as `could not be opened:`, where a failure was logged as the store holding no id. menuz goes from 0.4.1 to 0.4.2.
- **`--version`, `utilz list`, `utilz doctor`, `install`, `upgrade`, `relink` and `use` say when a utility's yaml cannot be read** (issue 0081). The metadata reader took a yaml yq could not read, or one that is not a single map, such as one holding two documents, for a yaml without the field asked for. So `--version` said the yaml carried no version, `utilz list` showed no description, doctor's `[5/7]` called every utility properly configured, or for two documents reported a version incompatibility, and the last four said `install.prefix` was not set. `--version`, doctor and the last four now say the yaml or its `install.prefix` cannot be read, and why, `utilz list` points at doctor, and doctor counts the fault once, under `[6/7]`.
- **`utilz doctor` refuses a dependency entry that names no dependency** (issue 0085). An entry written as a bare string, `dependencies: [jq]`, or as a map with no `name`, was checked as a dependency with no name and reported missing as an empty name or `null`, and one written as a list ended doctor before its verdict. Doctor now names each such entry and why, counts it as an issue, and no longer says every dependency is installed.
- **The utilz suite no longer leaves a temp dir in TMPDIR for each of `version_dispatch.bats`' tests** (issue 0088). Its own `teardown()` replaced the test helper's, so for each of its 11 tests the per-test dir, any gpg home and the cd back were skipped, and every run left 11 dirs in `$TMPDIR`. The helper's cleanup is now one function, `utilz_teardown`, which its `teardown()` and `version_dispatch.bats`' both call, and `isolation.bats` checks that every suite defining its own `teardown()` calls it.
- **Seven tests of a missing tool's refusal no longer skip where the tool is installed** (issue 0084). Each skipped wherever its tool was installed, and each tool was installed wherever its test ran, so the refusals of `parse_yaml`, `utilz test`, cryptz's `encrypt` and `decrypt`, gitz, mdagg's yaml mode and macoz's `setpicfor` were never tested. The test helper's `path_without <tool>` now gives each verb a `PATH` that lacks its tool and keeps every other command, and each test runs its verb under it. macoz's still runs on macOS only. The tests that run doctor and `utilz list` without yq use it too, in place of a list of 17 tools of their own.
- **`utilz doctor` names a utility with no yaml, and says what it did not check without yq** (issue 0087). Its `[5/7]` took a utility with no `<name>.yaml` for one with no version requirement, and `[6/7]` skips it, so doctor named it nowhere and called every utility properly configured, while `<name> --version` called its version unknown. Without yq, `[5/7]` read no yaml and still called every utility properly configured. It now lists `<name> (no <name>.yaml)` among the utilities with issues and counts it, and without yq it says `utilz_version` was not checked and calls none configured.
- **menuz's suites keep the user's unison, gpg and git signing out of their tests, as every other suite does** (issue 0091). `menuz.bats` and `macos.bats` define their own `setup()`, which replaced the test helper's and with it `isolate_tool_homes`, so `menuz.bats`' fixture commit took a signing git config from the environment and asked the user's gpg to sign. Both now call it. `isolation.bats` checks that every suite defining its own `setup()` calls `isolate_tool_homes`, through the same helper as its `teardown()` check.
- **todo leaves no temp file behind when a write fails** (issue 0090). todo wrote each file to a temp in the system temp dir, then moved it over the target, so a move that failed left the temp there: every run of the utilz suite left one, from the bridge's probe of `todo --file /nonexistent-probe.dat`. The temp now sits beside the target, and a write that cannot finish, a move that fails, or an INT, TERM or HUP while the temp exists removes it, names the target, and leaves the target as it was. todo goes from 2.0.0 to 2.0.1.
- **`prez present` opens a deck with the platform's opener when it finds no browser** (issue 0083). It fell back to `open` on every platform, so on Linux it reached no opener, or Debian's `open`, which is `openvt`, and failed at the launch, if at all. It now uses `open` on macOS and `xdg-open` elsewhere, names it in its warning, and with neither a browser nor the opener refuses by name, exit 2, listing every path it probed. `help/prez.md` no longer says `present` refuses when it finds no browser. prez goes from 2.5.1 to 2.5.2.
- **prez and showreel pass over a file on `PATH` with no execute bit** (issue 0089). The finders of a browser, of ffmpeg and ffprobe, and of `present`'s opener took the first file by its name alone, so a file without an execute bit ahead of a good command hid it, and the run failed at the launch with `Permission denied` and a remedy for another case. They now take the first one that can run, and a `--browser` at a file that cannot run is refused by name. prez goes from 2.5.2 to 2.5.3.
- **menuz's top row shows menuz's icon** (issue 0073). On macOS 27 a menu item draws its image only when it asks to, and the row never asked, so it showed no icon. It now asks, as Gtools' menu does. menuz goes from 0.4.3 to 0.4.4.
- **`menuz status` says a Homebrew install's source is `homebrew`** (issue 0094). It said `source      unknown: no …/native/macos/Menuz under git here`, since a Homebrew install is no git checkout and has no source to compare the app with. It now says `source      homebrew`. menuz goes from 0.4.4 to 0.4.5.
- **prez's crate tests no longer leave a temp dir in TMPDIR for each theme test** (issue 0092). The theme tests' helper made `$TMPDIR/artifact-theme-<pid>-<name>` and nothing removed it, so every run of the crate's tests left 9 dirs behind, on a Mac, on Linux and on CI. The helper now returns a guard that removes its dir when the test ends, whether it passes or panics, and a removal that fails for any reason but a dir already gone fails the test by name.
- **prez's crate tests no longer leave temp dirs in TMPDIR** (issue 0093). The test helpers of prez, showreel and artifact made their scratch dirs under TMPDIR and removed them before a test or not at all, so every run of the crates' tests left 82 behind, on a Mac and on Linux. Each helper now takes one guard from `artifact`, built into the tests alone, that removes its dir when the test ends, whether it passes or panics. 0092's fix for the theme tests moves into the same guard.

## [2.14.0] - 2026-10-17

### Added

- **`menuz`, a new utility: a macOS menu bar app whose menu is a YAML file of commands to run** (ST0027). The menu is `menuz.yaml` in `${MENUZ_HOME:-${XDG_CONFIG_HOME:-~/.config}/menuz}`: items that run a shell line, captions, headers, separators, submenus, and `each`, one item per line a shell line prints. Labels are expanded by the login shell at every menu open, with no syntax of menuz's own, and the app follows the file as it is saved, renamed or recreated, with no restart. A file that fails keeps the last good menu and shows the refusal as its first item. An item's parameters are asked for in one form (`text`, `secret`, `choice`, `file` or `folder`) and reach the run as exported variables, never spliced into the command. Runs are detached and concurrent, write to `${XDG_STATE_HOME:-~/.local/state}/menuz/menuz.log` with their ids, and keep going when menuz quits. A failed run posts a notification through macOS's notification centre under menuz's name, even when it ends after menuz has quit, and the log says whether each notice was posted, naming System Settings > Notifications > menuz when menuz's notifications are off or not yet allowed. At its first launch menuz asks macOS whether it may post, and each launch logs the answer. The app has its own icon, and shows its mark in the menu bar unless `icon:` names an SF Symbol; until it has a place in the menu bar it says, in the log and, once macOS allows it, as a notice, that a full bar may hide it behind the overflow and that Command-drag moves it. `init` creates the menu's folder with an example `menuz.yaml` and an empty `bin/`, first on every run's `PATH`, and refuses to overwrite a menu of your own without `--force`. `edit` opens the menu with `open -t`, or `$VISUAL`/`$EDITOR` under `--editor`. `log` follows the run log, or prints its last lines with `-n N`. `validate` prints `ok` or every refusal, naming the file, the entry, the key and the value, and `render` prints the menu as an outline. `build` (with `--release` and `--unsigned`), `test`, `install`, `uninstall`, `start`, `stop`, `restart` and `stamps` build and drive `Menuz.app` from `native/macos/Menuz`, and `use dev|installed` chooses between the development build and the copy installed in `~/Applications`, which registers itself as a login item. The menu's first row names the build, `menuz <version> (<commit>)`, with `dirty-` before the commit of a dirty source and ` dev` after it for any build that is not a clean build of the release tag, read from the five stamps `stamps` prints. `status` reports where the app is installed, which build is in use, whether it is running and a login item, and whether the installed copy is current with its source; `doctor` checks every precondition, one `ok` or `FAIL` line each. Each release carries `Menuz.app.zip`, signed with a Developer ID and notarised on the maintainer's machine through `bin/devbin macos`, and in a Homebrew install `menuz install` fetches it and checks its signature, notarisation, bundle id and version before installing it. CI builds and tests the app, unsigned, on a release tag or a manual run. menuz starts at 0.1.0.

### Fixed

- **A desk `arngz discover` saved from terminal windows now finds them again when it is applied** (ST0028). discover gave each window it had to tell from its app's others a pattern of its exact title, anchored at both ends, and a terminal's title moves: Claude Code puts a working glyph in front of its session's name, and a shell's title follows the job in it. So a desk saved from live terminals applied minutes later with those windows `unseen`. A pinned pattern is now the title from its first letter or digit on, escaped and anchored at neither end (`◑ utilz-dc` gives `utilz%-dc`), tightened to the end anchor and then the exact title only where the looser one would also take another window of the app. discover's report names every window it pinned, with the pattern. Desks saved before apply as they did. arngz goes from 1.0.0 to 1.0.1.

## [2.13.0] - 2026-10-16

Minor: **a new utility, `arngz`, arranges windows across displays and spaces from named desks**, and **prez prints page numbers in a PDF when a deck asks for them**, with a per-slide override. prez goes from 2.4.0 to 2.5.0.

### Added

- **`arngz`, a new utility: named window arrangements (desks) across displays and spaces, on macOS** (ST0026). A desk is a YAML file in `${XDG_CONFIG_HOME:-~/.config}/arngz/desks/` that says, for each display and each space on it, which apps live there and where on a grid their windows sit. `discover` prints the arrangement on screen now as a desk, on an 8x4 grid unless `--grid WxH` says otherwise; `--save <desk>` puts it in the catalogue, and `--force` replaces one already there. `apply <desk>`, or `arngz <desk>`, puts this machine's windows where the desk says. It launches apps that are not running unless `--no-launch` is given, creates missing spaces unless `--no-create` is given, and takes `--map <name>=<uuid>` to bind a desk display to a screen; `--dry-run` prints its plan, as `diff <desk>` does. `list`, `show <desk>` and `delete <desk>` manage the catalogue, and every desk is validated before a verb uses it. Hammerspoon is the engine: `init` reports what it needs and `init --yes` provides it, linking its `hs` tool and loading `hs.ipc` in its config, and `doctor` checks all seven preconditions, each with its fix. **`apply` takes the pointer**: macOS has no working call to move a window to another space, so each move is a person's gesture, the window held by its title bar, and moving the pointer stops it. Every step is read back, and the report names each desk entry as placed, launched and placed, moved and placed, skipped, unseen or failed. `apply` exits 0 when every entry is placed, 1 when any is not, and 2 when it refused before changing anything. arngz starts at 1.0.0.
- **`numbering: on|off` in a deck's front matter, and `<!-- numbering: on|off -->` on any slide** (issue 0065). The front-matter key sets the deck's default, off when absent, and a slide's directive overrides it for that slide alone. Every slide uses up a page number whether or not it shows one, so the number printed on a page is that page's number in the PDF, and a cover that should carry none says `<!-- numbering: off -->`; the `title` class has no say. Numbers appear in print only, bottom right, in the theme's `--gp-muted` colour and its `--gp-display` face where it defines one, so no theme changes and the on-screen `4 / 12` counter is untouched. `on`, `off`, `true` and `false` are accepted in any case; anything else is refused with exit 2, naming the key and the value and, for a directive, the slide. A deck with no `numbering` anywhere compiles to exactly the bytes it did before.

### Changed

- **`help/prez.md`** lists `theme-file` and `numbering` among the front-matter keys, and no longer calls the front matter YAML: it is flat `key: value` lines, which is what prez reads.
- **CI installs poppler on both Rust legs**, so the new acceptance check that reads every page of a printed deck with `pdftotext` runs rather than being skipped.
- **Harness only, no behaviour change: prez's `AT04` splits its fullscreen claim** (issue 0067). Headless Chrome on macOS (measured on 155) refuses fullscreen requested from a key, though the same Chrome in a window honours prez's `f`. AT04 now checks prez's half on every platform: `f` requests fullscreen on the page's root with the keypress's activation live. The browser's half (entered, fills, toggles out) is `n/a` on macOS by `uname` and still runs on the Linux leg. AT04 prints the browser's version.

### Fixed

- **`utilz doctor` no longer calls a command present when the only file of that name on PATH cannot run** (issue 0068). `check_command`, which `utilz doctor` and every utility's dependency check go through, asked `command -v` alone, and bash's `command -v` names a file on PATH that is not executable when nothing executable matches (measured under bash 3.2.57 and 5.3.20). A dependency shadowed that way read as installed, and the utility then failed when it ran it. `check_command` now requires the path it is given to be executable; a builtin or a function, which `command -v` names without a path, still counts.

## [2.12.1] - 2026-09-22

Patch: **`utilz test` builds a utility's binaries before any suite reads them**, and **a red CI verdict names the jobs that failed** rather than the run alone.

### Fixed

- **`utilz test <name>` builds a crate's release binaries first** (issue 0056). For a utility with a crate, two of the three test sources read `crate/target/release/<bin>` and only the last one built it, so after a version bump the shell tests read the binary from before the bump and failed: `Expected: prez 2.4.0   Actual: prez 2.3.0`. The build now runs before anything reads its output, with `--workspace` so `showreel` is rebuilt alongside `prez`. A crate that does not build stops that utility's run rather than testing a stale binary. A full run does no extra work: the later suites already built release, and they now find it built.

- **When CI is red, `utilz install` and `upgrade` record which jobs failed** (issue 0062). A run concludes `failure` both when a job went red and when no job ran at all, a billing refusal or a runner that never started, and those need opposite responses: fix the code, or re-run. The manifest's `ci-state` row, and the release core's CI verdict through `tools/ci-state`, now read the failing run's jobs and say `failed: <names>`, or that the run was refused rather than tested. Only a red verdict asks the second question, so a green one costs what it always did; a job list that cannot be read adds nothing and leaves the verdict as it was.

- **Harness and development only, no behaviour change**:
  - Every Chrome the black-box suites launch for the DevTools protocol takes a free port asked for at the moment it is needed, rather than one of nine fixed ports (0063). A port already held made Chrome fail to bind, and the only symptom was the wait timing out and blaming Chrome's startup: that is how `AT04` failed on the Linux leg of the 2.12.0 tag run while the same commit passed on its other run. The wait's ceiling is now a named 30 seconds, and a refusal says how long it waited.
  - `stampz`'s `ST0025-AT01` now fails when every page is stamped with one geometry, which is the regression it names (0057). It proved a mark existed on each page and not which page it was made for; it now requires the wide page to carry materially more ink than the A4 pages, since only a stamp sized for its own page does. `AT02`'s comment no longer claims to prove that, because it cannot.
  - `tools/test-estate` reads `/bin/bash`'s version and refuses by name when it is not 3.2 (0058). It forced a `PATH` and never checked what that path led to, so on a machine whose `/bin/bash` is not the one macOS ships the release gate reported green having proved nothing.
  - CI's setup steps lose two `chmod +x` lines (0061). One read `[!test]` as a character class, "not t, e or s", and so silently skipped `expz`, `stampz`, `syncz` and `todo`; both were dead anyway, because git already records every file they touched as executable.

## [2.12.0] - 2026-09-22

Minor: **`prez showreel video --safe-zone` records inside TikTok's and Instagram's own UI**, and **a line of type too wide for its frame is fitted to it** rather than running off the edge or breaking mid-word. prez goes from 2.3.0 to 2.4.0.

### Added

- **`prez showreel video --safe-zone social`: a reel recorded inside the platform's own UI** (ST0024). TikTok and Instagram Reels draw their caption and sound rows across the bottom of a video, their action column down the right, and their own chrome at the top; anything a reel puts there is covered. With the zone every mark and every line of type moves inside it, the corner mark's position is measured from the zone's corner rather than the frame's, and the QR codes are sized against the zone's box rather than the frame's height. Pictures still bleed to the frame's edge, as they always have. It comes from `--safe-zone`, or from `safe_zone:` in `showreel.yaml`, and the flag wins; `none` is the default, so an existing reel records exactly as it did. A frame wider than it is tall is refused, naming both, because the zone's insets are measured on a phone. The built HTML is unchanged either way: the recording asks for the zone on the URL, so the same reel can be seen with it or without it in a browser by adding `?zone=social`.

### Fixed

- **A line of type too wide for the room it has is fitted to that room** (ST0024, and issue 0045 before it). A word that cannot wrap and does not fit shows up two ways: in a centred pane it widens its box and runs off both edges of the frame, and in a column of fixed width it is broken mid-word instead. Both are now read from one pair of numbers, the longest run the line cannot break against the room its text may use, and the size is scaled down until it fits, never below the smallest size that line's own rule accepts; at that floor the line wraps rather than leave the frame. It covers headlines, the wordmark, a strapline's lines, the points, the crawl's values, the venue's labels and the socials handles. **A line that visibly fits never moves**, so a recording whose lines all fit is unchanged, frame for frame.

- **The Emacs bridge reaches `todo`'s verbs** (issue 0047). With a prefix argument (`C-u`) the bridge asks for extra flags, and it put them between a declared flag and the file, so `done 2` on a `todo.md` built `utilz todo --file done 2 <file>`, which todo refuses. The file now follows the declared flags and the extra flags come last, so it builds `utilz todo --file <file> done 2`. Without extra flags every command is exactly as before.

- **`stampz` stamps a PDF whose pages differ in size, page by page** (ST0025). One stamp is rendered for each distinct page size and laid over the pages of that size in a single `qpdf` run, so every page carries a mark made for it, every page keeps its own size, and the run reports `3 pages, 2 sizes`. Such a file used to be refused with "split the file": one stamp drawn at another page's size is clipped or drawn small, and a page that looks stamped but is not properly marked is the failure a deterrent must not have. Measured on a three-page A4, wide, A4 fixture, the wide page took a quarter of the ink from an A4-sized stamp. **A file whose pages cannot all be measured is still refused**, and it now says so: under `set -e` with `pipefail` an unreadable file killed the run at the probe, before the refusal on the next line could print, so `stampz` exited 1 in silence and left a manifest naming a recipient and no files (issue 0053).

- **`utilz install` and `upgrade` read every CI run on the commit they publish** (issue 0052). Since the macOS legs moved to release tags, a commit can carry two runs of the workflow, the branch's and the tag's, and GitHub promises no order between them; the manifest recorded whichever was newest. It now records the worst of them, so a `success` row means every run on that commit passed. The release core's CI verdict comes through the same reader.

- **Harness and development only, no behaviour change**:
  - CI cancels a run that a newer push has superseded, and the macOS legs run on a release tag or a manual run rather than on every push (0046, hv's fleet ruling of 2026-09-22, uniform whatever a repository's visibility). The Test Summary requires macOS only where macOS runs, so a push that skips it stays green. A push that only moves the whiteboard runs nothing.
  - The Emacs smoke test (`static/emacs/e2e-smoke.el`) expects one menu entry per row of the manifest rather than twelve; it had failed its first check on every run since the menu became six (0048).
  - `hoist-rebase.sh`, ST0010's rebase script, loses a postcondition that could not fail and re-points two that could not pass, because the code they name moved into the shared crate and the test harness (0049, 0050).
  - The release core's `test estate` gate runs every suite under the bash 3.2.57 that macOS ships, through `tools/test-estate` (0051). With the macOS legs now on tags and manual runs, that gate is what stands between a green tree and a tag.
  - **A recording is not bit-identical between runs in every case** (0054), and 2.10.0's entry here says it is. Measured: two recordings of one reel by ONE build, on one machine, differed on 25 of 75 frames, each by a single channel sample of 1 at one pixel inside a headline's edge; the same reel at 9:16 was identical. The suite's determinism check compares its own fixture, a crawl and five pictures, and that green is sound; the sentence a reader takes from it is wider than what it measures, and `video.sh` now says so where the check is. Nothing in the product changes: one sample of 1 is invisible and the encoded video is the same either way.
  - The two Chrome helpers both black-box suites need, `wait_for_cdp` and `CHROME_SAFE`, are defined once in `test/lib/harness.sh` rather than in `acceptance.sh` alone, which is the direction issue 0040 set for that harness. A consolidation, not a deletion: every call site is unchanged.

## [2.11.0] - 2026-09-21

Minor: **`prez showreel video --aspect` records portrait, square and 4:5 reels**, **Utilz installs with Homebrew**, and **Utilz is MIT-licensed**. prez goes from 2.2.0 to 2.3.0.

### Added

- **`prez showreel video --aspect`: a reel recorded portrait, square or 4:5, as well as widescreen** (ST0022), for TikTok and Instagram. The ratio is `W:H` or a name: `widescreen` (16:9, the default), `portrait` (9:16), `square` (1:1) or `feed` (4:5). It comes from `--aspect`, or from `aspect:` in `showreel.yaml`, and the flag wins. The reel's `target` is the long edge and the short edge follows, so at 1920 portrait is 1080x1920. A malformed ratio, a zero side, or one past 4:1 either way is refused by name, and `check` and `build` refuse a bad `aspect:` too. A frame no wider than it is tall is laid out at half size and drawn at twice the scale, so the player's phone layout applies while the frame keeps its pixels. In a portrait frame a gallery picture and the venue's shopfront are shown whole on a blurred copy of themselves, Ken Burns becomes a slow zoom with no drift, and the at-work card sits inside the safe area. **Widescreen records exactly as before.**

- **Utilz installs with Homebrew** (ST0019): `brew install matthewsinclair/utilz/utilz`, from the tap `matthewsinclair/homebrew-utilz`. The formula builds from source at the release tag, on macOS on Apple Silicon and Intel, and publishes through Utilz's own `utilz install`, so a brew install carries the same manifest and passes the same `utilz doctor`. It depends on `yq` alone; `utilz doctor` names what each utility needs beyond that.

- **`utilz install --managed-by brew|utilz`** records who owns an install in its manifest (ST0019). Only the formula passes `brew`; every other publish records `utilz`, and an install from before the row reads as `utilz`.

- **A LICENSE file: Utilz is MIT-licensed.**

### Changed

- **Inside a Homebrew install, `utilz upgrade`, `relink`, `use` and `install --force` refuse** and name `brew upgrade utilz`, whether run from the brew install or pointed at one with `--prefix` (ST0019). `utilz test` there names a clone of the repository rather than brew's deleted build directory.

### Fixed

- **`utilz install` and `upgrade` announce the source tree's own commit, or `none`** (issue 0044). From a tree that is not a git repository, such as a brew build, they announced the commit of whatever repository enclosed it.

- **Harness and development only, no behaviour change**:
  - `install_e2e`'s fixture no longer fails when a commit lands while it copies the checkout (0042), and it refuses by name to run from a linked worktree, where its fixture commit would have landed in the real repository (0043).
  - devbin's release core (`bin/devbin release`) is declared and switched on, with `tools/ci-state` as its CI query; this release was still cut by hand, because the core cannot yet resolve a version beside the older `v`-prefixed tags (reported to devbin). `tools/formula-bump` writes a release's tag and commit into the Homebrew formula, and `docs/releasing.md` is the procedure. The vendored devbin is at 0.1.3.

## [2.10.0] - 2026-09-20

Minor: **`prez showreel video` is new**, **`PREZ_THEME_DUPLICATES=refuse` can refuse a theme name defined twice**, and **`utilz doctor` reports every optional dependency a utility declares**. prez goes from 2.1.0 to 2.2.0.

### Added

- **`prez showreel video`: a showreel recorded to a video file** (ST0021). It builds the reel as `build` does, plays the built HTML's own player in headless Chrome on a clock it controls, and encodes every frame with ffmpeg. The result is an H.264 `.mp4` beside the HTML in the next `_out/` slot, or a `.mov` with `-o`. **The video is the reel**: the player that drew it is the one that ships, so nothing can drift from it, and two recordings at two real-time paces give byte-identical frames. `--fps` (1 to 60, default 30), `--keep`, `--frames` (every frame as a PNG, with a `frames.tsv`) and `--browser` complete it. It needs Chrome, which `pdf` and `present` already use, and ffmpeg, and it refuses a missing one by name before it records anything. A partial file never looks finished, and an interrupt leaves no Chrome and no profile behind. It records no faster than the machine renders, so a three-minute reel takes minutes.

- **`PREZ_THEME_DUPLICATES=refuse`: a theme name defined more than once on prez's search path can be refused** (ST0020). A caller that assembles the search path can ask for it, instead of search order choosing in silence. `refuse` refuses the name with exit 2, listing every definition in search order: its directory, the mechanism that put it on the path, and the stylesheet found there. Unset, empty or `first` keep first match exactly as before, and any other value is refused. `prez showreel` does not read it.

### Changed

- **`utilz doctor` reports every optional dependency a utility declares** (issue 0041). It read each utility's `dependencies` and never its `optional_dependencies`, and it reported an entry marked `required: false` as missing. Each missing optional dependency is now an information line with its own purpose and install line, never a failure. A user may see new lines for bat, bats and ffmpeg, and unison is reported as optional rather than missing. The hand-written glow and rsync lines went, because the utilities declare both.

- **`showreel build --keep` prunes whole slots** (ST0021): a dropped revision's HTML and its video go together, and the warning past five revisions counts the videos' megabytes.

### Fixed

- **`utilz doctor` and `utilz emacs doctor` print their whole report on stdout** (issue 0037). Their verdict lines went to stderr and the rest to stdout, so a redirect or a pipe split the report. The exit status is unchanged.

- **Harness and development only, no behaviour change**:
  - `utilz install` refuses by name a source tree it cannot enter, where it would have recorded the tree's unresolved spelling. Earlier checks refuse such a tree first today, so no run behaves differently. Its comment now says, correctly, that the tree is resolved logically (0039).
  - prez's source check, which refuses the estate's names, matches its second name too (0035).
  - devbin's format commands cover the prez crate again (0036), and CI checks its formatting ahead of clippy (0038).
  - prez's black-box suites share one test harness, which stops a suite when it is missing or does not load (0040).

## [2.9.0] - 2026-09-14

Minor: **`prez showreel` is new**, **a published install records CI's verdict on the commit it was cut from**, and **`PREZ_DEFAULT_THEME` gives a deck that names no theme a default**. prez goes from 2.0.0 to 2.1.0. todo goes from 1.1.0 to 2.0.0: **a breaking change to that one utility**, carried by its own major (see Changed).

### Added

- **`prez showreel`: a directory of pictures and a `showreel.yaml` become one self-contained, looping HTML reel that plays from a USB stick with nothing installed** (ST0017). `prez showreel <...>` hands over to a separate binary built from the same Rust workspace, so `prez build` never links showreel's image decoders and neither budget pays for the other. **The thread is the consolidation, not the port**: theme resolution, the offline guarantee, asset inlining and base64 now have one implementation, the shared `artifact` crate, serving both tools, where they had two in two languages. prez's dependency contract -- comrak and nothing else -- and its binary budget are provably unchanged.

- **A published install records CI's verdict on the commit it was cut from** (issue 0016). `utilz install` and `utilz upgrade` ask CI's own record of the commit with `gh`, under a 10-second watchdog, and write the answer into the manifest: the run's conclusion, `pending`, `none` when CI has no run for the commit, or `unknown` with the reason when `gh` is absent, refuses, or does not answer in time. `utilz version` shows it from an install -- `installed at <prefix> (<commit>, CI <state>)`, and `CI not recorded` for an install published before the record existed. **Record only**: no answer refuses a publish, and nothing defaults to success. Before this, a publish from a commit whose gates were red and one from a green commit produced the same install, and nothing could tell them apart.

- **`PREZ_DEFAULT_THEME`: a default theme for any deck that names none** (ST0018). The order, highest first: a flag (`--theme` or `--theme-file`), then the deck's `theme:` or `theme-file:`, then `PREZ_DEFAULT_THEME`, then the built-in `simple`. It holds a theme NAME, and it resolves and is refused exactly as `--theme` is: an unknown name keeps the unknown-theme refusal's `no theme '<name>'` prefix and gains one line saying where the name came from. Empty means unset, and a value that is not UTF-8 is refused by name. A wrapper that owns a house look can now give it to every deck without taking the choice from a deck that names its own.

### Changed

- **BREAKING (todo 2.0.0) -- an item's id is its name, not its position** (issue 0033). `utilz todo` renumbered every item on every write, so an id cited anywhere went stale at the next `add`, `done` or `sync`, with nothing to report it. An item now keeps its id through every write. A new item takes the next id the file has never used, recorded in a `next-id` frontmatter key, which is load-bearing: it is the only record of ids above the highest one still present. `start`, `done`, `notdone` and `toggle` address the id wherever the item sits, `--json`'s `num` carries it, and `done --prune` archives each item with its id. **A script that ran `todo done 1` to complete the top item now completes the item named 1.** A 1.x file migrates on its first write, every id unchanged.

### Fixed

- **An installed `prez showreel` exec'd a file the publish never produced** (issue 0024). `utilz install` built prez alone; it now builds the whole workspace and ships both binaries, and the installed shim refuses a missing one by name rather than failing at exec.

- **The prez shim announced "sources changed: rebuilding..." on every run** (issues 0023, 0025). It measured freshness against a binary that a no-op build does not touch, so the rebuild it triggered could never clear the staleness it detected. It now measures against a build stamp it writes itself, one pending stamp per invocation, so a build clears it and two overlapping builds both land.

- **A stray `/* ... */` in a theme's `layout.html` hid a live external reference from the offline check** (issue 0018). CSS's comment grammar was being applied to HTML; the comment exemption is now CSS-only.

- **prez's offline check let external references through in shapes it had not spelled out** (issues 0014, 0015, 0017): a protocol-relative `@import` (0014); anything after a `/*` inside a string, which it took for a comment that never closed and so stopped scanning (0015); and a reference in upper case, with whitespace in it, or wrapped across lines (0017). It no longer hunts for spellings: it reads the target at the two sites a stylesheet loads from, a `url()` token and an `@import` prelude, and a refusal names the line the URL is on. The case-insensitive net for absolute schemes stays over all live text as well, so nothing that refused before builds now, and `theme.yaml` joined the scanned set (ST0017). **One refusal is new**: a theme with a genuinely unterminated comment is refused by name, where the scan used to stop at it in silence.

- **`prez showreel check` printed a build-time constant beside a config fact, and the subtraction between them was false** (issue 0022). The constant is gone.

- **`utilz doctor` printed step 6's dependency verdict under step 7's heading** (issue 0026).

- **A publish could wait up to 10 seconds for nothing** (issue 0032). A TERM landing in a microsecond window left the CI query's watchdog sleep holding its caller's output pipe until the deadline. The watchdog's output now goes nowhere, so nothing it starts can hold the pipe.

- **Eight utilities' READMEs carried an absolute path into the maintainer's home directory, and an install shipped it** (issue 0010). `utilz generate` wrote the same path into every new utility's README, so correcting the eight alone would have fixed nothing. The generator no longer writes it, the eight are corrected, and the install suite holds every owned file to the rule, where it had exempted every `.md`.

- **`todo done --prune` reported "pruned 0 item(s)" whatever it archived** (issue 0034). It counted the bucket again after clearing it; the archive itself was always right.

- **Harness and development only, no behaviour change**: install_guards' AT12 asserts the manifest's own record of the commit rather than a live HEAD, so a concurrent commit no longer reddens it for the wrong reason (0011); prez's AT09 walks every `src/` in the workspace rather than the root package's alone (0027); the install suites' shared fixtures have one home, and a fixture commit a hook refuses fails by name instead of surfacing later as a dirty tree (0028); AT20 reports a forwarded window that never opened as itself, rather than as a wrong criterion (0029); the acceptance suite's process matchers reach only their own run (0030); `.prettierignore` covers every generated view, so the formatter can no longer rewrite one after the doctor gate (0031); help dispatch's tests accept a platform's stated refusal and survive `set -e`, both of which had turned CI red, and install_guards gains an install-coverage test (ST0016); install_guards declares the bats version its `run --separate-stderr` needs; and the vendored devbin gates point at this project's crate and test suites, with `tmp/`, which they write into, ignored.

## [2.8.0] - 2026-09-08

Minor: **`--help` changes for 14 of 15 utilities** when invoked as `utilz <util> --help`, so a user can observe it. It now renders the curated `help/<name>.md`, which is what `<util> --help` already gave.

### Fixed

- **`--help` HAD THE SAME DEFECT AS `--version`, ONE LINE UP THE SAME FILE** (ST0016). `bin/utilz` intercepted `--help` and `-h` on the **symlink** path only, so `<util> --help` rendered the curated help while `utilz <util> --help` fell through to the utility's own terse inline usage. **14 of 15 disagreed with themselves depending on how they were invoked.**

  `version_intercept` became `predispatch_intercept` and answers `--version`, `--help` and `-h` from **one** home, called from both dispatch sites. A second, `--help`-shaped intercept beside the `--version` one would have rebuilt exactly the arrangement ST0015 removed.

  **The utilities' own `--help` arms are deliberately NOT deleted**, unlike ST0015's `--version` arms. Those could go because `show_version` was the only producer either way; these produce genuinely different text and are the only usage a **directly executed** script can print -- `opt/<name>/<name> --help` is not a dispatched invocation and nothing intercepts it. An acceptance criterion holds that boundary, because the judgement otherwise lives in prose and prose does not fail: the next reader sees two adjacent threads, reads them as one pattern, and deletes fifteen arms that nothing replaces.

  Two documented exceptions, neither a defect: **`expz`** calls `show_help` from its own arms and so has no inline usage to keep -- which is why it was the one utility that agreed before the fix -- and **`prez`** is a shim whose compiled binary answers `--help` itself.

- **`show_help` closes stdin on every renderer arm.** A bare `glow "$file"` with a terminal on stdin hangs; this estate has it recorded twice from real incidents. **The pager was suspected and was wrong**: `-p` is opt-in, injecting it changed nothing, and the bare call hangs regardless. Two incompatible wrong explanations agreed on the conclusion while the real cause sat underneath the thing both were arguing about. **The hang was not reproduced under a `script`-allocated pty** -- glow exits 1 emitting terminal-query escapes there, a third behaviour -- so the guard is asserted **present** by inspection rather than the hang claimed fixed. A renderer handed a FILE has no business reading stdin either way.

## [2.7.0] - 2026-09-08

Minor: **every version answer changes shape**, so a user can observe it. `utilz --version` now prints `utilz:2.7.0`; every utility prints `utilz:2.7.0/<name>:<version>`. **A new tag rather than a moved `v2.6.1`**, and the first tag in this project without a `v` -- the prefix is noise and it was the last thing making the framework's line a different shape from every utility's.

### Changed

- **`--version` HAS ONE HOME, AND BOTH VERSIONS ARE ON ONE GREPPABLE LINE** (ST0015). Every utility answers `utilz:<framework>/<utility>:<version>`, followed by its description; `utilz` itself answers `utilz:<version>`, keeping the description and the tree-provenance line that says which tree replied. **There is no `v` anywhere** -- hv's ruling, on the grounds that it is noise, and it was the only thing making the framework's line a different shape from a utility's. `common.sh` was the estate's single minter of one.

  **The defect was that `--version` had FIFTEEN homes and two of them disagreed.** `bin/utilz` intercepted the flag on the SYMLINK path only, so thirteen utilities hand-copied an identical `--version) show_version "<name>"; exit 0` arm to cover the `utilz <util>` form. **The two that never copied it were the two that broke**: `todo` had no arm and answered `Unknown command: --version` while its own `--help` advertised the flag, and `prez` could not have one because clap answers before any shell runs -- so `prez --version` and `utilz prez --version` differed by one character, the `v`, and the quiet one is the one that survives a reviewer.

  **The fix is one intercept called from both dispatch sites, and the fourteen arms are deleted.** Deletion is the proof rather than a tidy-up: "the dispatcher ALSO handles it" passes every test that "the dispatcher handles it" passes, so only their absence distinguishes the two. `expz` carried two arms, not one, which no per-file assumption and no single-line grep found -- only counting per file while removing them.

  **`script.tmpl` carried the arm too, and that was the leak that mattered.** The template scaffolds every new utility, so `utilz generate` would have re-seeded the duplication one utility at a time and the fix would have decayed silently from the next utility onward. An acceptance test now generates a utility and runs it on both forms, pinning REGENERATION rather than the template's current text.

  **An unreadable version is no longer a silent success.** The old arms exited 0 whatever `show_version` returned, so a utility whose `version_file` was missing from an install printed an error to stdout and reported success to the caller -- not hypothetical, it is the prez regression fixed earlier the same day.

- **EVERY VERSION HAS ONE HOME, AND NOTHING RESTATES IT** (hv's ruling). The framework's is `./VERSION`; each utility now carries its own `opt/<name>/VERSION`, and its yaml points at it with `version_file` instead of repeating the number. **Thirty-two copies were removed** -- fifteen help files, fifteen utility READMEs and two templates each stated a literal `**Version**:` that nothing held equal to anything.

  **This estate had already been bitten twice and only noticed once.** `help/utilz.md` carries the record of the first: hardcoding the framework version there drifted it to 2.2.0 while 2.4.0 shipped. That fix was applied to one file and left in fifteen others, where it drifted again -- measured before this change, `cleanz`'s README said 1.1.0 against a yaml of 1.2.0, and `todo`'s help AND README both said 1.0.0 against 1.1.0. **Nothing reported either, because prose is the copy nobody re-reads.** The templates were minting fresh instances: every utility `utilz generate` scaffolded was born with a literal that was correct exactly until its first release.

  **`prez` is the documented exception and it is not an exception to the rule.** Cargo REQUIRES a version in `[package]`, so `crate/Cargo.toml` is a home that cannot be deleted -- which makes it the one to keep, and prez has no `VERSION` file because a second one would be the duplication being removed. The rule is **point at the one home you cannot delete**, not "use this filename".

  **A utility now reports the framework it belongs to as well as itself.** Two versions are in play whenever a utility misbehaves, and being handed one of them is how a bug report arrives missing the half that explains it. The line's final shape is below, under ST0015.

  Two tests hold all of it, both proved to go red by re-introducing a literal: no help file, README or template may state a version, and no utility yaml may either -- each paired with a check that the pointer is still present, because deleting every version line satisfies an assert-absence just as well as fixing it does.

- **BREAKING (prez v2.0.0) -- `--theme` takes a NAME and nothing else** (ST0013). It resolves on `PREZ_THEME_PATH`, extended for one invocation by the new `--theme-path`, then among the built-ins, and **never against the working directory**. Paths move to the new `--theme-file`, which accepts both shapes the old flag took: a `.css` file, or a directory holding `theme.css`. Front matter splits the same way into `theme:` (a name) and `theme-file:` (a path resolved beside the deck), or the ambiguity simply moves into the deck where it travels with the file.

  **The defect was measured rather than reported.** The same deck, the same binary, `--theme=simple`: from a directory holding a `./simple/` the local theme won at 18208 bytes; from anywhere else the built-in won at 22662. **Neither run printed a word** -- `provenance()` announces only a search-path hit and a cwd hit was stamped as a typed path -- so one command built two different decks silently.

  **The fix is a type change, not a branch reorder.** The resolver took one ambiguous string and asked `path.exists()` first; it now takes a name or a path as distinct variants, so the working-directory branch is unreachable rather than merely unvisited. Deleting the branch instead would have passed every test and left the cause in place for the next feature that needed a path.

  **A breaking change taken deliberately, at the cheapest moment it will ever have**, and the refusal names the remedy for the case that fired: a path given to `--theme` is refused naming `--theme-file` with the value, so the message can be pasted. Both known live invocations migrated by one word. The downstream estate verified its client decks re-render **byte-identical** under the new spelling.

- **`version_file:` reads the version OUT of a file that carries one, rather than requiring a file that IS one.** A plain `VERSION` file still works by `cat`; a `Cargo.toml` is read from `[package]`. **Cargo requires a version in `[package]`, so for a Rust utility that file is a home which cannot be eliminated** -- which made prez's inline `version:` the removable copy. The two were not two readings of one value but two channels: the dispatcher answered from the yaml and the binary from a compiled-in `CARGO_PKG_VERSION`, so they could disagree and each would look right alone.

### Added

- **`utilz test` and CI discover every black-box suite in `crate/test/` rather than one hardcoded filename, and REFUSE one that is present but not executable** (ST0013/AC03). Naming a single file meant a second suite was run by nothing: CI green, the local driver green, and its tests marked green on a manual run nothing repeats. The refusal half is not optional -- "glob and run each executable one" silently skips the non-executable and hands back a green, which is the defect the single-file guard already existed to prevent, generalised from one name to a set.

## [2.6.1] - 2026-09-08

Patch: two CI gates repaired, no user-visible behaviour change. **A NEW TAG RATHER THAN A MOVED `v2.6.0`**, because the fixes touch `opt/utilz/lib/`, which is shipped code and not harness -- and because the install manifest records `source-commit`, so moving a tag would leave `v2.6.0` naming two different sets of bytes over time while an already-published install still claimed the commit the tag no longer named. That is the provenance property AC07 exists to protect.

### Fixed

- **ShellCheck went red on the 2.6.0 release, and the cause was one deliberate subshell reaching eighteen files.** `common.sh` began sourcing `install.sh` for doctor's install-integrity check, and `install.sh` bound the tree ambiently -- `raw=$( export UTILZ_HOME="$tree"; get_util_metadata ... )`. Under `shellcheck -x` that produced SC2031 on every later read of `UTILZ_HOME` in every file reaching `common.sh`: 39 findings, including `opt/cleanz/cleanz`, which the release never touched. **Fixed by removing the idiom rather than muting the check** -- a `# shellcheck disable` at the write site does not suppress read-site warnings, and disabling SC2031 project-wide would hide a real bug class. `get_util_metadata` now takes the tree as an optional third argument defaulting to `$UTILZ_HOME`, and `install.sh` passes it. Behaviour is unchanged and the caller's `UTILZ_HOME` is now provably untouched rather than merely subshell-scoped.
- **The prez acceptance suite has a third outcome, `n/a`, and it is the first exception to "a SKIP is not a pass"** (ruled by hv). AT15's keychain half asks about Chrome Safe Storage, a macOS keychain concept, so on Linux there is nothing for it to be about; counting it as did-not-run demanded a run that could never happen and reddened `--strict` on every Linux leg. **The condition is the platform predicate, never the missing tool**: gating on `command -v security` would make any machine lacking it silently exempt, including a Mac that should have it, while `uname -s != Darwin` cannot. A Darwin host without `security(1)` still reports `unchecked` -- that is a broken machine, not an inapplicable one. It is only honest while some leg runs the check, and the macOS legs do; the comment says a `not_applicable` check that no leg runs is dead and should be deleted rather than excused. Verified on macOS at 14 passed / 0 failed / 0 skipped / **0 n/a**, the zero being the evidence the check genuinely ran.

## [2.6.0] - 2026-09-08

Minor rather than patch: four new user-observable commands and a new utility, no breaking change to anything that existed at 2.5.0. Semver by the same reading 2.5.0 used.

### Added

- **Utilz can publish a runnable install of itself, so the source can be worked on without disturbing the copy you use** (ST0014). `utilz install` publishes this checkout to `install.prefix`; `utilz upgrade` replaces an existing one. **Devbin's install tree is deliberately not runnable and ours inverts that**, so the criterion is that the install works when the source is moved aside rather than that files arrived -- an install reaching back into the checkout passes every check that does not move the source.
- **`utilz use dev|opt` switches which tree your PATH symlinks serve, in one word, from either tree.** No path is typed either way: the install records `source-tree` in its manifest and the checkout reads `install.prefix` from its yaml, so each tree carries the address of the other. `utilz use` with no argument reports which tree is live and changes nothing. `utilz relink` is the mechanism underneath when you want to name a tree yourself.
- **`utilz version` names the tree that answered** -- `installed at <prefix> (<commit>)` or `source at <path>`. Without it the two-tree arrangement is invisible in exactly the situation it exists for: someone debugging behaviour cannot tell which copy produced it.
- **`utilz doctor` gained a seventh check, install integrity**, verifying every owned file against the manifest it was published with. In a source checkout there is no manifest and doctor says so rather than passing silently.
- **The install carries a manifest recording the version, the source commit, the source tree and a checksum per owned file.** Symlinks are checksummed by their target STRING against their path, never by the file they resolve to -- all fifteen resolve to the dispatcher, so a dereferenced check gives them one hash and reads a corrupted link as intact.

### Changed

- **The owned set is enumerated by EXCLUSION over `git ls-files`, not by an inclusion list.** The first cut shipped `opt/<n>/<n>`, `<n>.yaml` and `README.md` per utility, which is the shape the tree appears to have. A walk of all sixteen directories says otherwise: **five utilities keep runtime payload outside those three names** -- `cleanz`'s trope list, `expz`'s default schema, `pdf2md` and `xtrct`'s Python implementations, and `macoz`'s backgrounds -- 22 paths in total. An inclusion list publishes an install in which five of fifteen utilities are broken, each failing only when someone reaches the one code path that needs the file that never arrived. **The inversion is the keeper, not the corrected list**: an exclusion list ships a new subtree until someone says not to, which costs bytes rather than correctness.
- **`install` and `upgrade` never touch your PATH symlinks.** Relinking your environment takes a verb you typed. Publishing from a dirty tree is refused and **no flag overrides it**, `--force` included: the manifest's commit claim only holds when nothing is uncommitted.

### Fixed

- **An exported `UTILZ_HOME` silently redirected an install back at the checkout, and this project's own README told you to export it.** The dispatcher derived its tree from `$0` only when the variable was unset, so a published install invoked by its own path answered from whatever tree `UTILZ_HOME` named -- measured with a marker VERSION: unset gave the install, exported gave the source, and nothing said so. An ambient login-shell export made that the normal case rather than the edge. **The dispatcher now always derives from `$0` and ignores an inherited value**; the variable survives only as an internal channel to child processes. `README.md` and `help/utilz.md` no longer tell you to set it and say plainly that the old instruction was wrong.
- **`utilz test` from an install tree refuses and now NAMES the source tree**, printing a `cd <path> && utilz test` you can paste. It previously said "the checkout this install was published from", a description the reader has to resolve, which made a correct refusal read as a failure with no next step. The suite rewrites `bin/`, which is exactly what the manifest checksums, so running it in an install would report drift nobody caused.
- **`cryptz`'s round-trip test blocked the whole suite on a passphrase prompt.** `run_cryptz` did not close stdin, so `cryptz decrypt` inherited the terminal and gpg asked for a passphrase; the test's own comment said "decrypt may prompt for passphrase, so we don't assert success", which handled the assertion and not the prompt. Green in CI, dead on a terminal. Stdin is now closed at the one door every cryptz call goes through, and the decrypt half is opt-in behind `CRYPTZ_TEST_DECRYPT` and asserts success when it runs -- **a call that asserts nothing and can block the suite is pure cost.**

### Changed

- **`utilz todo` writes GFM task-list items, so a `todo.md` renders as a checklist instead of a wall of prose** (todo 1.1.0). The line was `01:[ ] text`, which is not a markdown construct: a run of them collapses into a single paragraph anywhere markdown is actually rendered, which is how the estate's CMS, Obsidian and a GitHub blob all showed it. It is now ``- [ ] `01` text`` -- a real list item, with `[ ]` and `[x]` rendering as checkboxes for free. **`intent todo` had already reached the same conclusion for the same reason** (its emit comment: "plain `[-] ...` lines get reflowed into one paragraph"); the fork had not carried it across.
- **The id moved to after the checkbox, into a code span.** A task-list marker only counts when it directly follows the bullet, so `- 01:[ ] text` is a plain list item with literal text while ``- [ ] `01` text`` is a checkbox. The id has to stay visible because it is the handle every verb takes.
- **`[-]` for DOING is left as literal text and not forced into a checkbox.** The glyph is what `sync` and `toggle` reconcile against and what the legend documents; a DOING item under its own heading reads clearly enough without a box. Round-trip correctness over a cosmetic third state.
- **Reading is unchanged in tolerance and now strips the id from either position**, so pre-2026-09 files, a missing id, a hand-pasted `- [ ]` line and an `intent todo` item all still parse. Writing is always the current shape and ids renumber positionally on every write, so `utilz todo sync` migrates a file in place with no separate migration. Two tests cover it: a legacy file through `sync`, and a double round trip not accreting a second id.

### Added

- **`stampz` -- stamp a recipient watermark across every page of a PDF pack** (ST0011). Promoted out of a Lamplight tool so it is available everywhere rather than living in one repo's `docs/bin/`. One rotated line of mono type reading `CONFIDENTIAL <date> <recipient>`, mid-grey at 30%, plus a `STAMP-MANIFEST.txt` recording the page count and the sha256 of every file before and after. Two guards that refuse rather than approximate: mixed page geometry, and any change in page count. **It deters and does not protect** -- an overlay is strippable in seconds, and the header, the README and the help all say so, with a test asserting the sentence is there.
- **The stamp is built as a PDF, not rendered.** The reference drove headless Chrome at a hardcoded `/Applications` path over a generated HTML file and pulled its font from a CDN, which made it a one-platform, online-only tool. `stampz` assembles an 823-byte one-page PDF directly in base-14 Courier-Bold: no browser, no network, no embedded font, and it runs anywhere `qpdf` and `poppler` do. Courier is fixed-pitch at 0.600 em, so the size formula's constant is exact by construction rather than contingent on which font arrived. Object offsets are measured with `wc -c` per append rather than summed from `${#s}`, which counts characters and would shift every xref entry on a non-ASCII recipient.
- **Out-dir is the default and `--in-place` is explicit**, inverting the reference. In-place is only safe when the originals regenerate from somewhere else, which is a property of the pack and not of the tool.

### Fixed

- **`M-x utilz` offered thirteen utilities; four could never have worked and one mutated the filesystem on selection** (issue 0009). The `integration:` blocks were authored in one pass from each utility's I/O shape and nothing checked that the resulting command line was one the utility would accept: `cryptz`, `gitz` and `retry` each needed a verb the block did not supply, and `mdagg` was declared `stdin` when it does not read stdin. `lnrel` created a symlink in the prompted directory and reported success. On hv's ruling the menu is pruned to six -- `cleanz`, `expz`, `mdagg` (input corrected to `path`), `pdf2md`, `todo` (input corrected `none` -> `file`, `flags: [--file]`), and `prez` (added, `flags: [build]`, the strongest editor fit in the roster). Eight blocks removed. **`todo` was dropped in the first pass on a wrong reason and hv caught it**: its declaration was broken in the same way `mdagg`'s was -- `input: none` meant the bridge ran it in whatever directory Emacs was in and ignored the buffer -- and `mdagg` was corrected rather than dropped. Same defect, two conclusions. **`integration.flags` was the mechanism that would have made the verb-taking utilities work; it reaches the TSV and the elisp inserts it, and every utility declared it empty.** A framework test now invokes what the bridge would build per declaring utility and fails if the utility rejects the form, with a self-discrimination control so it cannot pass vacuously.
- **Issue 0006's sweep left a third hardcoded roster copy** (issue 0008). `prez.bats` asserted `"14 utilities"`, so adding the fifteenth reddened a suite in a thread that never touched it -- the same count-pinned-to-a-moment defect 0006 fixed in two other places on the same day. The count is now derived from `utilz list`, the idiom CI's macOS leg already uses. Two prose copies went with it: `docs/index.md` claimed "All 12 shipped utilities" and named twelve while the tree held fifteen, and `README.md`'s tree comment said "(12 utilities total)".
- **A dead mixed-geometry guard, inherited from the reference.** `pdfinfo` prints `Page    1 size:`; the guard matched `/page *[0-9]+ size:/` against a case-sensitive awk, so it matched nothing, `wc -l` returned 0, and the caller's `${varied:-1}` read that zero as "one geometry, carry on". The check could not fire on any input. A probe that reads nothing is now a refusal rather than a pass.
- **`cryptz` and `gitz` declared no dependencies while hard-requiring `gpg` and `git`.** Both call `require_command`, so the failure arrived at use rather than from `utilz doctor`. Declared, and now checked up front. (`prez` still declares none deliberately: `cargo` is a build-time need and a test pins that distinction.)
- **`help/cryptz.md` was still the generated template** -- "Add more detailed description here", a generic `[OPTIONS] [ARGS]` synopsis, no commands, and no `--email`. Rewritten from the as-built surface. It was the only help file left in that state.
- **`docs/index.md` restated the framework version as 2.2.0** while `VERSION` read 2.5.0 -- a second copy of the single source of truth, stale across three releases. Replaced with a pointer, matching the fix `help/utilz.md` already carried.
- **`.claude/restart.md` documented `intent st list --all`**, which has never worked (the flag is `--status all`), and pointed at `intent/issues/OPEN/` for open defects. That directory is permanently empty by policy, so it confirmed "no open defects" while one was filed.

### Changed

- `README.md`'s `## Included Utilities` gained `prez`, `stampz` and `todo`. `prez` and `todo` had shipped in earlier releases and were never added.
- ST0002 and ST0007 carry `acceptance: exempt`. Both completed before the v3 contract model and hold zero criteria, so the close gate blocked their work packages with a remedy the project otherwise rules against; exempt is correct for a genuinely contract-free unit and is not the ST0010 case, where a full contract exists and the gate cannot read it.
- Issue 0006 was written into canon. It had existed only as a flat view, so `intent doctor` counted one fewer issue than the tracker showed.

## [2.5.0] - 2026-08-29

### Added

- **`prez` -- markdown in, one self-contained HTML presentation out** (ST0010). The first Rust utility in the framework. It is a pipeline, not a presentation tool: it writes a file and stops, the browser presents, and there is no server and no viewer. One `.html` carries everything inside it, so a deck opens offline, from a USB stick, in five years. `prez build`, `prez pdf` (one slide per 254x142.9mm page), `prez present` (a de-chromed window at the deck's own aspect). Seven brand-free built-in themes, `--theme NAME` resolving through `PREZ_THEME_PATH`, mermaid diagrams opt-in via front matter (and costing zero bytes when not opted into). Hoisted from an upstream estate at a recorded pin rather than rewritten, with the adaptation captured as an idempotent script so a moving pin costs a re-run rather than a re-remembering. `comrak` is its only dependency.
- **Rust support in the framework itself** (ST0010/WP-02). Utilz had never held compiled code. `utilz test` now discovers up to three suites per utility BY CONVENTION, so the next utility of a given shape inherits the driver for free: `crate/Cargo.toml` drives `cargo test`, `test/*.bats` drives BATS, and `crate/test/acceptance.sh` drives a black-box suite with `--strict` always passed -- hard-coded, because a suite that degrades to skips exits 0 having driven nothing. `utilz doctor` treats `cargo` as optional rather than as a declared dependency. `.gitignore` fences `opt/*/crate/target/` in a commit that landed before any in-tree build existed. CI gains `rust` and `clippy` jobs (the latter with `-D warnings`), both feeding the `all-green` gate.
- **A shell shim per compiled utility.** `opt/prez/prez` resolves a built binary and refuses with a remedy when it is absent, following the existing `ensure_venv()` precedent rather than committing a binary that could not serve both Ubuntu CI and macOS from one artifact. It honours `CARGO_TARGET_DIR`, which is what lets a cold build be forced and then verified.

### Fixed

- **Adding any 14th utility reddened the suite whichever way it declared integration** (issue 0006). `bridge.bats` asserted `emit_integration_tsv` emits exactly 13 rows while `utilz emacs doctor` counted a utility without an `integration:` block as an issue and returned 1, which two other tests asserted did not happen -- so no value of a new utility's yaml satisfied both. The row count is now a property rather than a number pinned to a moment, and a utility not bound to the Emacs bridge is not treated as broken. Latent since both checks were written; `prez` is the first utility added since.
- **The CI shellcheck gate was aimed at code with a different owner.** The vendored `devbin` tool sources files resolved at runtime, which shellcheck cannot resolve statically, so every one was an SC1091 and the gate exited non-zero at default severity. Excluded by pattern rather than annotated, because devbin ships a manifest that would make an in-file directive detectable drift.

### Changed

- `test-macos` derives its utility roster from the dispatcher instead of carrying a hardcoded list, so a new utility is covered there the day it lands. `prez` is deliberately excluded from that leg: its acceptance suite needs Chrome, node and a toolchain, and `--strict` correctly counts a skip as a failure, which makes it the wrong instrument for a runner that legitimately lacks the tools. The crate is covered by the `rust` and `clippy` jobs instead.

### Known

- **The `prez` slide counter drops below the 4.5:1 contrast floor on dark slides** (issue 0007). It is `position: fixed` and a sibling of the deck, so no theme can reach it per-slide; the fix belongs in the compiler. `aria-hidden` decorative chrome, so low severity.

## [2.4.0] - 2026-07-29

### Changed

- **BREAKING (soft): `yq` is now a hard dependency of the framework** (ST0009/WP-02). `get_util_metadata` previously carried two parsers -- a `yq` path and a grep fallback that answered four hardcoded queries and returned an empty string for everything else, which a caller cannot distinguish from an absent key. The fallback is gone; `yq` is the single YAML parser, declared in `opt/utilz/utilz.yaml` and gated by a single `require_yq`. Without `yq`, `utilz list` now fails loudly with an install hint where it previously degraded silently and gave wrong answers. `utilz doctor` deliberately still completes without `yq` and names it as the missing dependency -- it is the command you run to discover exactly that. This is the change that makes the bump minor rather than patch.
- **One walker of `bin/`** (ST0009/WP-01). `list_utilities`, `run_doctor` (twice), `run_tests`, `emit_integration_tsv`, and `emacs_doctor` each open-coded the same glob-and-filter over `bin/*`, and had already drifted: two verified the symlink resolved to the dispatcher, three accepted any symlink, so a stray link in `bin/` was a utility to `doctor` and not to `list`. All five now read a single `each_utility()` (Highlander), consumed via process substitution so accumulator arrays survive the loop.

### Fixed

- **`utilz generate` stamped a compatibility floor no 2.x framework could satisfy** (issue 0002, ST0009/WP-03). `opt/utilz/tmpl/metadata.tmpl` hardcoded `utilz_version: "^1.0.0"` while `VERSION` read 2.3.0, and `run_doctor` compares major versions -- so every generated utility was born incompatible and stayed that way until someone hand-edited the yaml. The floor is now derived from the framework's own `VERSION` via a `{{UTILZ_FLOOR}}` placeholder substituted at generation time. Latent rather than observed: all 13 shipped utilities already carried `^2.0.0`, so nothing in the repo was ever broken by it.

### Docs

- `docs/architecture.md`, `help/utilz.md`, `README.md` reconciled with the as-built: `yq` documented as a framework-level hard requirement rather than an mdagg-specific one, `each_utility` / `require_yq` added to the common-library reference, and the claim that utilities call `get_util_metadata()` corrected (it has no callers outside `common.sh` -- it is framework-internal). The stated bash floor is corrected from "4.0+" to 3.2, which is what macOS ships and what the code has always targeted.

### Tests

- `opt/utilz/test/common_lib.bats` -- 12 new tests covering the three seams, 11 of which fail against the pre-change code. `each_utility` distinguishing a dispatcher symlink from a stray symlink and a plain file; the drift regression asserting a stray link is invisible to `list_utilities` **and** `run_doctor` (the old code counted it in one and not the other); `list_utilities` failing loudly without `yq`; the install hint printed **once** rather than once per utility (a regression test for a defect hit during this work -- `require_yq` originally memoised into a variable, which does nothing across the command substitution `get_util_metadata` runs in); `run_doctor` completing without `yq`; `get_util_metadata` returning non-zero rather than an empty string; and the generator stamping a floor that tracks a fabricated `VERSION` of 7.3.1, proving derivation rather than coincidence.

## [2.3.0] - 2026-07-10

### Added

- **todo** - New standalone DOING / TODO / DONE task manager (ST0008). A single-file manager for a plain-text `todo.md` with positional item numbers and history sweep / purge subcommands. Forked from Intent's `intent todo` but made independent of steel threads: the `todo.md` is the source of truth, not a projection. File-location precedence: `--file <path>` wins, then `-g`/`--global` (`${XDG_CONFIG_HOME:-$HOME/.config}/utilz/todo/todo.md`), else default `./todo.md`. Verbs: `add`/`start`/`done`/`notdone`/`toggle`, `next`/`doing`/`todo`/`done`/`count`, `done --prune`/`--flush`, `sync`/`update`/`edit`, `--json`. The `todo.md` format stays mutually compatible with `intent todo` (same bucket headings and glyphs).
- **`utilz todo` <-> `intent todo` mutual guard** (ST0008/WP-08). `utilz todo` stamps `generator: utilz todo` on every write and refuses to clobber a `todo.md` owned by a different generator (eg `intent todo`) - but only when Intent is actually present (a silent `command -v intent` plus a `intent/.config/config.json` check rooted at the target file's directory), so utilz stays a zero-dependency standalone tool that runs silently and never fails where Intent is absent. It also refuses to create a fresh default `./todo.md` inside an Intent project. Mirrors Intent's `guard_foreign_todo` without taking a runtime dependency on Intent.
- **File-based issue tracker** at `intent/issues/` (`OPEN/` / `CLOSED/` / `_templ/`) - lightweight, git-tracked, steel-thread-independent, for defects a single issue can drive without a full ST.

### Fixed

- **mdagg: silent Unicode data loss under a C locale** (issue 0001). With `--strip-back-links`, mdagg used a `[←↑]` grep bracket class that, under `LC_ALL=C`, degraded to a byte set (`0xE2` is the UTF-8 lead byte for the whole U+2000-U+2FFF block) and silently deleted any content line containing a `→ ∥ ∈ — ...` character - invisible in a UTF-8 terminal, data-destroying in CI / agent sandboxes that export `LC_ALL=C`. Fixed with an anchored, byte-safe ERE (`grep -vE '^[[:space:]]*\[(←|↑)'`) that also tightens the strip to genuine navigation-link lines (inline arrows in prose now survive). The sibling title-case (`sed 's/\b\(.\)/\u\1/g'`, whose `\b`/`\u` are GNU-sed no-ops on BSD sed - so section titles came out un-cased on macOS) was replaced with a portable POSIX-awk title-case, and the duplicated title derivation extracted into a single `derive_title()` (Highlander).

### Changed

- Framework version bumped to 2.3.0 (additive minor bump - new `todo` utility; no breaking changes).
- CI: **expz** added to the Ubuntu (test-linux) test loop. Its BATS suite is entirely offline (every test returns before expz's `ANTHROPIC_API_KEY` check), so no CI secret is required; macOS already exercised it via `utilz test`.

### Tests

- `opt/todo/test/todo.bats` - full BATS coverage for the todo utility, including the WP-08 mutual-guard acceptance tests (stamp present; foreign-refusal inside an Intent project with a stubbed `intent` on PATH; foreign-proceed outside a project; own / legacy / fresh pass-through; default-path creation refused in an Intent project).
- `opt/mdagg/test/mdagg.bats` - regression tests for issue 0001 under `LC_ALL=C` (Unicode content survives while navigation links are stripped; a link-only file strips without a `set -e` abort; inline arrows preserved; portable title-casing).

## [2.2.0] - 2026-04-23

### Added

- **Editor integration manifest** - new `integration:` YAML block declares each utility's input kind (`stdin`/`file`/`path`/`none`) and output kind (`replace`/`buffer`/`message`/`discard`). Optional; absence means the utility is not auto-exposed to editor bridges. All 12 current utilities now carry an `integration:` block.
- **`utilz integration commands`** - editor-neutral TSV manifest surface. Emits one row per utility with an `integration:` block: `name<TAB>description<TAB>input<TAB>output<TAB>flags`. The TSV is the single cross-boundary contract - any editor integration (Emacs, future VSCode / Zed / Vim) consumes it without parsing YAML directly. The walker (`emit_integration_tsv` in `opt/utilz/lib/common.sh`) is the only place that walks the YAML corpus to produce the integration catalogue (Highlander).
- **`utilz emacs install`** - installs the canonical elisp bridge (`static/emacs/utilz.el`) to a destination path. `--symlink` creates a symlink (preferred - `git pull` in Utilz rolls the bridge forward); omitting it copies. `--force` overwrites a differing destination. Prints the `(load ...)` line for the user to paste into `config.el`. Never edits the user's Emacs config.
- **`utilz emacs doctor`** - health check: verifies `utilz` is on the PATH Emacs will see, every installed utility has a valid `integration:` block (flags missing / invalid `input` / `output` values), and the canonical elisp is present.
- **Emacs bridge (`static/emacs/utilz.el`)** - thin coordinator (~270 lines). `M-x utilz` offers a `completing-read` menu (Vertico-compatible) of the TSV rows, annotated with descriptions. Picking a utility resolves input per its declared kind (region for stdin, buffer file or prompt for file, directory prompt for path, none), runs it, and dispatches the result per its declared output kind (replace region with single `undo-boundary`, pop a `*utilz-NAME*` buffer, echo a single-line message, or discard). `C-u` prompts for extra flags; `C-u C-u` confirms the full command line before running. Non-zero exit pops a stderr buffer and leaves the region/buffer untouched (No Silent Errors). `M-x utilz-refresh` re-reads the manifest. Default keybinding: `C-c u`.

### Changed

- Framework version bumped to 2.2.0 (additive minor bump - new subcommand families, no breaking changes).
- `opt/utilz/tmpl/metadata.tmpl` - includes a commented `integration:` stub so `utilz generate` scaffolds the block for new utilities.
- `help/utilz.md` - new sections documenting `utilz integration <verb>` and `utilz emacs <verb>`.
- Project-wide bash reindent from 4-space to 2-space (Intent project standard). 32 files touched, pure mechanical change.

### Tests

- `opt/utilz/test/bridge.bats` - 16 new tests covering TSV shape (column count, row count, cleanz spot-check, utilz-core exclusion), dispatcher verb routing (`integration`, `emacs`), `install` happy path + `--symlink` + idempotency + error paths (missing `--dest`, unknown option), and `doctor` exit-zero on clean checkout.

## [2.1.0] - 2026-03-25

### Added

- **expz** - New batch expense receipt PDF extraction utility
  - Recursively finds PDF receipts in category subdirectories
  - Extracts structured data via `xtrct` (Claude API) using a JSON schema
  - Outputs CSV with columns: Date, Category, Supplier, Description, Currency, Subtotal, VAT, Total, Reference, File
  - Category derived from parent directory name
  - Bundled default schema at `lib/expense_schema.json`, overridable with `--schema`
  - Output to stdout or `--out <file>`
  - Verbose mode with progress to stderr
  - Handles JSON array responses from xtrct (normalises to first element)
  - 9 comprehensive tests

### Changed

- Framework version bumped to 2.1.0

## [2.0.0] - 2026-03-02

### Changed

- **syncz** - Unison backend for bidirectional sync (syncz v2.0.0)
  - `--bidi` now uses unison when available for archive-based state tracking
  - Automatically distinguishes new files from deleted files (no more mass-deletion risk)
  - Falls back to rsync two-pass when unison is not installed
  - `--backend unison|rsync` flag to force a specific backend
  - `--fresh` flag to ignore saved unison archives (treat as first sync)
  - `--prefer d1|d2|newer` flag to force conflict resolution (unison only)
  - `--no-metadata` flag to ignore xattrs and resource forks (for cloud filesystems)
  - `--ignore FILE` flag to read exclude patterns from a file (one per line, `#` comments supported)
  - `--dry-run` works with unison via mutation blocking (`-nocreation/-nodeletion/-noupdate`)
  - `--delete` is a no-op in unison mode (deletions are state-tracked)
  - Path display uses `D1:/D2:` root labels with common suffix extraction (`Dir:`)
  - `SYNCZ_ROOTS_SHOWN` env var to suppress per-invocation headers in wrapper scripts
  - Dry-run output shows `[new]`, `[changed]`, `[CONFLICT]` tags with direction labels
  - unison added as optional dependency
  - 12 new tests (9 unison bidi + 3 backend selection); existing 66 tests pinned to rsync
  - unison added to CI dependencies (Ubuntu and macOS)

## [1.3.2] - 2026-03-02

### Fixed

- **syncz** - Safe orphan defaults in `--bidi` mode (syncz v1.4.0)
  - Bare `--bidi` now keeps all orphans and syncs them to both sides (was interactive delete-by-default)
  - `--bidi --delete` shows irreversibility warning before deleting
  - `--bidi --confirm` interactive prompt flipped to `[y/N/a]` where Enter = keep (was `[Y/n/a]` Enter = delete)
  - Prevents accidental mass-deletion when one side is mostly empty

### Changed

- Framework version bumped to 1.3.2

## [1.3.1] - 2026-02-19

### Added

- **lnrel** - New utility for creating symlinks with relative paths
  - Computes relative path from link directory to target using GNU `realpath`
  - Portable symlinks that survive directory tree moves
  - Automatic `grealpath`/`realpath` detection for macOS/Linux portability
  - Strips backslash escapes from paths (handles tab-completion-in-quotes pattern)
  - Supports dangling symlinks (target need not exist)
  - Single-arg form defaults to basename in current directory
  - 12 comprehensive tests
- coreutils added to macOS CI brew install (for `grealpath`)
- lnrel added to Linux CI test loop

### Changed

- Framework version bumped to 1.3.1

## [1.3.0] - 2026-02-12

### Added

- **pdf2md** - New PDF to Markdown converter utility
  - Converts PDF files to clean markdown using pdfplumber
  - 7-stage pipeline: text extraction, stats, line grouping, heading detection, list detection, header/footer removal, markdown emission
  - Heading detection via font size analysis (H1-H6 by descending unique sizes)
  - List item detection (bullets, dashes, numbered, lettered, parenthesized)
  - Repetitive header/footer removal (same text+Y on >50% of pages)
  - Page range selection (`--pages 1-5,7,10-12`)
  - File output (`-o output.md`) or stdout
  - Verbose mode with progress to stderr
  - Python venv auto-management at `lib/.venv/`
  - 15 comprehensive tests
- **xtrct** - New schema-driven semantic data extraction utility
  - Uses Claude API to extract structured data from documents via JSON schema
  - Descriptive schema format: `description` fields guide semantic extraction
  - PDF input auto-converts via pdf2md
  - Stdin support for piping
  - Output formats: json (pretty-print), csv, table (aligned columns)
  - Model selection (`--model`) with default claude-haiku-4-5-20251001
  - Verbose mode with token usage stats
  - `ANTHROPIC_API_KEY` fail-fast check before venv creation
  - Python venv auto-management at `lib/.venv/`
  - 12 tests (8 tier-1 always run, 4 tier-2 require API key)
- Composable pipeline: `pdf2md invoice.pdf | xtrct --schema invoice_schema.json`
- Python venv pattern for utilities with Python dependencies
- python3-venv added to CI Ubuntu dependencies

### Changed

- Framework version bumped to 1.3.0

## [1.2.1] - 2026-02-10

### Added

- **syncz** - Bidirectional sync mode (`--bidi`)
  - Two-way sync with automatic orphan detection using `find` + `comm`
  - Orphan resolution: interactive prompts, `--delete` (silent), `--confirm yes/no/all` (scriptable)
  - Two-pass rsync (dir1→dir2, dir2→dir1) with newer-wins strategy
  - rsync `--delete` never passed in bidi mode (orphan resolution handles deletions)
  - `--source-wins` and `--dest-wins` blocked in bidi mode
- **syncz** - `--confirm` optional argument (`yes`, `no`, `all`)
  - Auto-answers all prompts for fully scriptable operation
  - Works in both unidirectional and bidirectional modes
  - Peek-ahead parsing preserves positional argument compatibility

### Fixed

- syncz: empty orphan arrays caused silent exit on bash 3.2 (`set -e` + `&&` short-circuit)
- syncz: `--confirm yes --delete` now correctly deletes (macOS rsync missing delete count in stats)

### Changed

- syncz version bumped to 1.3.0
- Framework version bumped to 1.2.1

## [1.2.0] - 2026-02-08

### Added

- **syncz** - New directory-to-directory syncer utility wrapping rsync
  - Three conflict resolution strategies: newer-wins (default), source-wins, dest-wins
  - Confirmation modes: `--confirm` (Y/N/A per-step), `--force` (no prompts), `--just-do-it` (single Y/N)
  - `--delete` with safety gate (requires `--confirm`, `--force`, or `--just-do-it`)
  - `--backup` creates `.syncz-bak` copies of overwritten files
  - `--exclude` pattern support (repeatable)
  - `--dry-run` with summary and itemized change listing
  - `--verbose` and `--progress` modes
  - Uses `-rlptD` instead of `-a` to avoid group/owner warnings for non-root syncs
  - Trailing slash normalization for predictable behavior
  - 45 comprehensive tests
- rsync dependency check in `utilz doctor`
- syncz added to Linux CI test loop

### Changed

- Framework version bumped to 1.2.0

## [1.1.0] - 2025-12-28

### Added

- **cleanz** - New LLM text cleaner utility that removes hidden characters and formatting artifacts from text copied from ChatGPT, Claude, Gemini, and other LLM interfaces
  - Removes zero-width characters (ZWSP, ZWNJ, ZWJ, word joiners)
  - Removes byte order marks (BOM) and soft hyphens
  - Removes directional formatting characters (LTR/RTL embedding, override)
  - Converts non-breaking spaces and hair spaces to regular spaces
  - Removes control characters (preserving newlines, tabs, carriage returns)
  - Strips HTML `data-*` attributes commonly injected by LLM UIs
  - Normalizes whitespace (multiple spaces, blank lines, trailing whitespace)
  - Optional smart quote to straight quote conversion (`--normalize-quotes`)
  - Detection mode (`--detect`) to show hidden characters without cleaning
  - Verbose mode (`--verbose`) to show cleaning summary
  - Full I/O support: files, stdin, stdout, clipboard (`--clipboard`), in-place editing (`--in-place`)
  - 46 comprehensive tests

### Changed

- Framework version bumped to 1.1.0

## [1.0.0] - 2025-11-12

### Added

- Initial release of Utilz framework
- Dispatcher-based architecture with single `bin/utilz` entry point
- Common functions library (`opt/utilz/lib/common.sh`)
- Built-in utility generator (`utilz generate`)
- Built-in test runner (`utilz test`)
- Built-in diagnostics (`utilz doctor`)
- **clipz** - Cross-platform clipboard utility (macOS, Linux X11, Wayland)
- **cryptz** - GPG encryption/decryption wrapper
- **gitz** - Git multi-repository status checker
- **macoz** - macOS utilities (desktop backgrounds, folder icons)
- **mdagg** - Markdown file aggregator
- **retry** - Retry command until success
- GitHub Actions CI/CD with tests on Ubuntu and macOS
- Comprehensive test suites using BATS
