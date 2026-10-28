# Releasing Utilz

A Utilz release is cut by **devbin's release core**, `bin/devbin release`, declared in the `release:` block of `bin/.devbin/config.yaml` and switched on since 2026-09-21 (hv's OK; ST0019 D1, Devbin ST0007 WP-08, commit cb45181). **2.12.0 is the first cut through it.** Every release up to 2.11.0 was cut by hand, the last of them on hv's ruling of 14 September that the core would be adopted after it rather than during it.

**hv runs the cut.** It tags and pushes, and tags and pushes are hv's. Every read-only step below is anyone's.

Everything here was read from the copy vendored at `bin/.devbin/`, which is the copy that runs, and the version rule below was checked by running it rather than by reading it. **A runtime before 0.1.6 cannot cut this project at all**: it stops at step 1 on this repository's own tag set, for the reason under "Which version it resolves" below. So 2.12.0 is cut after the vendored runtime is swept to 0.1.6.

## Before the cut

- **The CHANGELOG's open section names its version**: `## [X.Y.Z] - unreleased`, never `## [Unreleased]`. The core finds a section by its version and dates it at the cut (ST0019 D2).
- **prez keeps its own version number.** A release that bumps prez carries the bump (`opt/prez/crate/Cargo.toml` and the `Cargo.lock` cargo rewrites) in its own commit before the cut (ST0019 D2, ruled 2026-09-21). A hand-written version needs a build before the suite reads it (issue 0056).
- **Run `bin/devbin check all` before handing a Rust change on, and do not read a green test suite as covering it.** `check all` runs `cargo fmt --check` and clippy; no Utilz suite runs either, and the pre-commit formatter gate stops at markdown. Six formatting diffs rode five commits into `main` on 2026-09-22 under a green 13/13 thread and a green estate, reddened CI, and would have refused the cut at step 5 (issues 0059 and 0060). `cargo fmt --check` also fails the CI step **ahead** of clippy, so drift hides the clippy verdict entirely rather than adding to it.
- **The tree is clean, and stays clean.** Step 2 refuses anything dirty outside what the release owns, untracked files included, so a realised view of a closed thread or a stray scratch file stops the cut. Step 5 re-reads the tree and `HEAD` after the gates and fails the cut if a gate wrote to either.
- **Every node holds its writes for the whole cut** (ST0019 D6). That includes `intent wb` heartbeats and pickups, which write a board view and a canon event.
- **The gate is `bin/devbin check all`** (hv, 28 Oct 2026, ST0030). `bin/devbin test estate`, which is `tools/test-estate` and runs every suite under the bash 3.2.57 macOS ships (issue 0051), runs before the cut, in the dry run and the twins, and not again in it.
- **CI cancels a run that a newer push supersedes, and the macOS legs run on the TAG, not on the push** (issue 0046). A superseded commit's run concludes `cancelled`, which `tools/ci-state`, the core's CI query, reads as `failed`; the core reads CI after it pushes, so nothing may land on `main` between the release push and that read, which the hold above already guarantees. A release commit therefore carries two runs, the branch's without macOS and the tag's with it, and the query reads every run on the commit and answers with the worst of them (issue 0052), so its verdict does not depend on which of the two push events GitHub registered first.
- **The tag is bare and annotated**: `2.12.0`, never `v2.12.0`, with the CHANGELOG section's body as its message, passed with `--cleanup=whitespace` (ST0019 D7). The core writes it and reads it back.

## The cut

1. **`bin/devbin release check`** -- read-only. It validates the declaration and prints it.
2. **`bin/devbin release --minor --dry-run`** -- every read of the cut and none of its writes: no commit, no tag, no push, no release object. **The gates still run**, on `HEAD` in place; since a dry run makes no release commit, that predicts the gates rather than gating the release. `--patch` and `--major` choose the other bumps, and `X.Y.Z` or `vX.Y.Z` names a version outright.
3. **`bin/devbin release --minor --yes`**, run by hv. `--yes` answers the confirm step, which prints what it is about to push and carries on, so from here to the tap nobody is asked anything (ST0030). Without it, the cut stops at step 6 to ask. Eleven steps, each with a postcondition it reads first, so a re-run continues where it stopped rather than starting again:

| Step | Name       | What it does                                                    |
| ---- | ---------- | --------------------------------------------------------------- |
| 1    | resolve    | the version, the tag, and whether this is a new cut or a resume |
| 2    | pre-flight | the branch, the remotes, the tree, the notes                    |
| 3    | stamp      | the version files and the CHANGELOG's date                      |
| 4    | commit     | the release commit                                              |
| 5    | gates      | `check all`, then the tree and `HEAD` are re-read               |
| 6    | confirm    | what is about to be pushed, and where                           |
| 7    | tag        | bare, annotated, written and read back                          |
| 8    | push       | every remote (see below)                                        |
| 9    | object     | the release object                                              |
| 10   | after      | `tools/post-cut`: Menuz.app at the tag, then the tap            |
| 11   | ci         | the CI verdict, through `tools/ci-state`                        |

**Which version it resolves.** `--minor` bumps the newest tag matching the declared template, and the template here is `{version}`, so a tag counts only when it is a bare `X.Y.Z`. This repository's sixteen older `v`-prefixed tags (`v1.0.0` through `v2.6.1`) are therefore not candidates and cannot be bumped: the newest match is `2.11.0`, and `--minor` resolves `2.12.0`.

**On a runtime before 0.1.6 those same tags stop the cut dead** (devbin issue 0106, found here and fixed in 0.1.6). `release_versions` ends its loop body with `is_semver "$v" && printf ...` (release.steps:107). `git tag --list` emits byte order, so `v2.6.1` is the last tag it reads; `is_semver` is false on it; the `&&` leaves 1 as the loop's status; and because the handler runs under `set -euo pipefail` (cmd/release:24), `pipefail` makes that the status of the whole pipeline even though `sort` succeeded. `release_resolve` returns it on a bare `||` with no `warn`, so the cut stops at step 1 with an empty reason, having written nothing:

```
release: --minor (DRY RUN: nothing is written)
  1  resolve     FAILED

release: stopped at step 1 (resolve). This run tagged nothing and pushed nothing.
```

**Ask this question with `bin/devbin release --minor --dry-run`, never by sourcing `release_versions` into a shell of your own.** The refusal is created by the handler's shell options rather than by the function, so the same call under a plain `bash -c` returns `2.12.0` and reports success: a true answer about a shell the cut never runs in. Two nodes measured it that way on 2026-09-22 and agreed with each other, which is one measurement taken twice rather than a confirmation. The dry run is read-only, needs no argument beyond the bump, and answers it directly.

**Where it pushes.** `release.remotes` is undeclared here, and undeclared means every remote `git remote` lists, in that order: **`local` and `upstream`, both**, which is this project's rule anyway. `release.repo` names `matthewsinclair/utilz` because with no `origin` and two remotes the core cannot read the repository off a remote and refuses rather than guessing.

**If a step fails**, read what it printed and fix the cause; the same command resumes. `bin/devbin release status <version>` prints where a cut got to, writing nothing, and exits non-zero if any row could not be read -- a map with a hole in it is not an answer.

## After the cut: Menuz.app

menuz's app ships as a release asset, `Menuz.app.zip`, beside the tag's source. The release core attaches no files: step 9 makes the release object with a title and notes only. So once step 9 has made it, hv signs, notarises and attaches the app on this machine, through the project's own `bin/devbin macos` (ST0027 D12, as Intent signs `Intent.app`). CI builds the app unsigned and reads no secrets.

**Once per machine**, hv stores the notary credentials in the login keychain:

```bash
bin/devbin macos store-creds   # interactive: Apple ID, app-specific password, team id
bin/devbin macos doctor        # each credential PRESENT or MISSING, the identity counted, a test-sign
```

Nothing is written to this repository, and nothing prints a value. `store-creds` refuses to run without a terminal.

**After every cut, `tools/post-cut` runs the three steps below and then the formula's publish, in order, stopping at the first failure** (ST0030). It is the release core's one `after:` line, so the cut runs it; by hand it is `tools/post-cut [<tag>]`, the tag defaulting to the top-level `VERSION` at HEAD, and refusing any tag but the newest release. It runs the three steps in a detached worktree at the tag under the system's temp dir, never under `~/Devel`, where Launch Services registers bundles, and removes it on every way out. A re-run starts from the top and skips what is done: a release already carrying `Menuz.app.zip` skips the app steps, and a tap already carrying the release is left as it is. It is one `after:` line, not four, because the core runs every `after:` line even when one before it failed.

`app-sign` and `publish` refuse a tree whose HEAD is not the tag (issue 0103), which is why `post-cut` uses a worktree even during a cut, when the primary is at the tag: a node's board commit would move it. A Menuz.app built off the tag carries that commit and the kind `dev`, and every Homebrew install's menu would show them.

1. **`bin/devbin macos app-sign`**: asks `utilz menuz stamps` what the build would carry, and refuses, building and signing nothing, unless its kind is `release`, which menuz gives only to a build of the tag from a clean tree. The refusal names the stamps, the tag and the worktree route. Then it builds Release through `utilz menuz build --release`, stages a copy under `${XDG_STATE_HOME:-~/.local/state}/menuz/build/macos/dist`, and refuses, signing nothing, a staged copy that `publish` would refuse: the build products are shared by every tree, so another build can replace the one just made. Then it signs the copy inside-out with the Developer ID identity and the hardened runtime, and reads the identifier, the team and the runtime back off the signature, and the version, build, commit and kind off the bundle.
2. **`bin/devbin macos app-notarize`**: submits the signed copy to Apple and waits. Anything but `Accepted` prints Apple's log and staples nothing. Then it staples the ticket and checks a quarantined copy with `spctl` for `source=Notarized Developer ID`.
3. **`bin/devbin macos publish`**: zips the stapled bundle as `Menuz.app.zip`, unpacks the zip and checks the bundle inside, then attaches it with `gh release upload` to the release for the top-level `VERSION`. It refuses, uploading nothing, when the bundle's version is not `opt/menuz/VERSION`, when its `MenuzKind` is not `release`, when its `MenuzCommit` is not the commit the tag names or the tag is not in the tree, when that release object does not exist yet, and when the release already holds `Menuz.app.zip`. The bundle it unpacks to prove the zip gets a Launch Services record from `stapler validate`, so on every way out, a refusal or an interrupt included, `publish` drops that record with `lsregister -u` before it removes the copy, then checks that no record is left under the copy's directory (issue 0104). If one is, it says which, with the command that drops it, and exits 1, after saying what it published. After the upload, it drops and checks every record still standing under menuz's build root, a Release build product's included, so the bundle id opens the installed app alone; a record it cannot drop, or a list it cannot read, is a warning, and the publish stands (issue 0115).

`bin/devbin macos app-verify` checks the signed bundle again at any time, changing no bundle.

Only the installed `~/Applications/Menuz.app` keeps a Launch Services record, so the bundle id opens it and never a build (issue 0106). Xcode registers each app it builds, so `utilz menuz build`, `test` and `install` drop the product's record after xcodebuild. A record can come back from outside Utilz after that drop, so `menuz install` ends, on both its paths, by dropping and checking every record under menuz's build root, as `publish` does after its upload (issue 0115). `codesign`, `stapler` and `spctl` can register the staged copy, so `app-sign`, `app-notarize` and `app-verify` (for `dist`) drop its record on every way out, and the quarantined copy each checks with `spctl` has its record dropped before it is removed. The drop touches no file, so the next step still reads the copy. A record that will not drop is a warning naming the bundle and the `lsregister -u` line that drops it, and the step's own exit stands. `utilz menuz doctor` says `WARN` for each record of the bundle id at any other path.

**Publish before pushing the tap.** In a Homebrew install, `menuz install` fetches `Menuz.app.zip` from the release named by the install's own `VERSION`, and checks its signature, its notarisation, its bundle id and its version before replacing anything. Until the asset is attached, it exits 1, naming the URL it tried and saying that the release carries no Menuz.app. So a formula pushed before `publish` gives every new install a `menuz install` that fails until the asset arrives.

## After the cut: the Homebrew formula

Utilz installs with Homebrew from the tap `matthewsinclair/homebrew-utilz`. Its formula builds from source at the bare tag, so it names the tag and the tag's commit. The repository keeps the formula as a template, `packaging/homebrew/utilz.rb`, with one `@@TAG@@` and one `@@REVISION@@`, and is never installed from. `tools/formula` fills them from git, as the dev, opt, brew contract has every tool's formula rendered (T8, devbin's `docs/dev-opt-brew.md` at devbin commit aeed31e4; issue 0105).

- `tools/formula render <tag> <out>` writes the formula for an annotated tag to `<out>`. It refuses a tag that does not exist, a lightweight one, and a template without exactly one of each placeholder, and writes nothing in this tree.
- `tools/formula publish [--tap <url>]` renders the newest release, the highest annotated tag of Utilz's bare-semver form, into a fresh clone of the tap, commits it and pushes it. It refuses a template with changes no commit holds, and leaves a tap that already carries the formula as it is. It pushes, so it runs in hv's cut, through `tools/post-cut`, the release's `after:` line, once `Menuz.app.zip` is attached (ST0030, hv's ruling of 28 Oct 2026, replacing that of 2026-09-21 in ST0019 WP-05 that no release hook runs it).

**Never type the commit by hand.** The offline `brew audit --strict` accepts any 40 hex digits, so a wrong commit passes the audit and fails at every user's install. The commit comes from `git rev-parse <tag>^{commit}`, inside `tools/formula`.

### After every cut

`tools/post-cut` publishes Menuz.app's asset first (above), since a formula pushed before it gives every new install a `menuz install` that fails until the asset arrives, and then publishes the formula to the tap with `tools/formula publish`. Nothing is committed in this repository: the template does not change from one release to the next.

Then hv:

1. **Brings this machine's tap up to date and audits it**, with Homebrew's auto-update off, as every scripted brew call runs:

   ```bash
   git -C "$(brew --repository)/Library/Taps/matthewsinclair/homebrew-utilz" pull --ff-only
   HOMEBREW_NO_AUTO_UPDATE=1 brew audit --strict matthewsinclair/utilz/utilz
   ```

2. **Upgrades each machine's brew install and reads it back.** On rhadamanth, and on kovacs through kovacs-sysadm:

   ```bash
   HOMEBREW_NO_AUTO_UPDATE=1 brew upgrade utilz
   utilz version   # utilz <version> (brew, <sha12>)
   utilz doctor
   ```

   An install from before the contract's manifest reads as `brew (old manifest)`, which doctor notes, and this upgrade replaces it.

3. **Proves the switch on rhadamanth** (contract T10): `utilz use dev`, `utilz use opt`, `utilz use brew` in turn, each followed by `utilz version` and `utilz doctor`, whose PATH check fails if a link is shadowed. It needs `~/.local/bin` before Homebrew's bin on PATH, which Molt-matts' sleeve config sets.

A formula that names a commit brew cannot fetch fails every install, so the tap is published only after this repository's tag is pushed.

**A wrong commit fails loudly at install, never silently.** When brew fetches a git URL with both `tag:` and `revision:`, it checks out the tag and compares the commit it got with the formula's revision. On a mismatch it stops: "`<tag>` tag should be `<revision>` but is actually `<commit>`" (`download_strategy/vcs_download_strategy.rb:46-51` in this machine's Homebrew). The offline audit makes no such check, which is why the commit comes from `tools/formula` and the first install after a publish is the real proof.

### Where the tap lives, and how it was set up

The tap's repository is `matthewsinclair/homebrew-utilz` on GitHub. On a machine that has tapped it, brew keeps its clone at `$(brew --repository)/Library/Taps/matthewsinclair/homebrew-utilz`, as hv's Intent tap is kept.

It was set up once, at the 2.11.0 cut on 2026-09-21, after this repository's tag was pushed: the formula then committed here, written by the tool `tools/formula` replaced, was staged as `Formula/utilz.rb` in a new repository, created with `gh repo create matthewsinclair/homebrew-utilz --source . --push`, then tapped with `brew tap matthewsinclair/utilz`, audited clean, installed and checked with `utilz doctor` (ST0019 AC-05.2).
