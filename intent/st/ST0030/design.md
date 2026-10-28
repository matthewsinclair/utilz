# ST0030 design: lights-out release

## D1. The config

`bin/.devbin/config.yaml`'s `release:` block:

- `gates:` is `check all` alone (hv, 28 Oct). `test estate` stays a declared option, run by hand and by the dry run's operator, out of the cut.
- `after:` is one line, `tools/post-cut`. One line, not four: the core runs every `after:` line even when an earlier one failed, and the formula must not be pushed unless Menuz.app.zip is attached.

The cut is `bin/devbin release --patch --yes`. `--yes` is the core's own: it prints what it will push and does not stop to ask.

## D2. `tools/post-cut [<tag>]`

Runs from the project root, as the core runs every `after:` line, with stdin on /dev/null. With no argument the tag is the top-level `VERSION` at HEAD, which at the after step is the release commit. Bash, `set -euo pipefail`, in `tools/` beside `tools/formula` since `bin/` is published.

1. Refuses off macOS (exit 2): app-sign needs Xcode and the keychain.
2. Refuses a tag that is not an annotated tag in this checkout, or whose release object GitHub does not have.
3. If the release already carries `Menuz.app.zip`, skips the app steps and says so. A re-run of a cut re-runs its after step (it has no postcondition), and `macos publish` refuses a release already holding the asset, which would stop the formula step for good.
4. Otherwise makes a detached worktree at the tag under `$(getconf DARWIN_USER_TEMP_DIR)` (never under ~/Devel, where Launch Services registers bundles), and runs in it, in order, stopping at the first failure: `bin/devbin macos app-sign`, `app-notarize`, `publish`. app-sign and publish refuse any tree whose HEAD is not the tag (issue 0103), which is why a worktree, not the primary, even though the primary is at the tag during a cut: a node's board commit during the after step would move it.
5. Removes the worktree on every way out with plain `git worktree remove`, never `--force`; a removal that fails says LEFT with the path.
6. Runs `tools/formula publish`, which renders the newest release into a fresh clone of the tap and pushes it, and leaves a tap that already carries it as it is.

7. Pulls this machine's clone of the tap, `$(brew --repository)/Library/Taps/matthewsinclair/homebrew-utilz`, with `git pull --ff-only` (WP 02, hv, 28 Oct): `brew upgrade` left it at 2.14.4 after 2.14.5's publish, so brew saw nothing to upgrade. No brew on PATH, or no such clone, is said and skipped; a pull that fails is a failure. The upgrade itself stays hv's.

Exit 0 only when every step it ran passed. A failure names the step, and `tools/post-cut <tag>` re-runs from the top, skipping what is done.

## D3. What stays by hand

`bin/devbin macos store-creds` (once per machine, interactive). Everything the dry run and the twins do before a cut is outside this thread.

## D4. Proof (decision 67: the smallest run that proves the change)

`tools/post-cut 2.14.5`, run by hv, does 2.14.5's outstanding app steps and tap publish: the real path, on the real release. `bin/devbin release --patch --dry-run` shows the gates as `check all` alone and the after row as `would run: tools/post-cut`. shellcheck on `tools/post-cut`. No bats suite: every step it runs is an existing verb with its own tests, and the script's own logic is the order and the skip.
