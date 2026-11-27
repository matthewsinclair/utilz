# Releasing Utilz

A Utilz release is cut by devbin's release core, `bin/devbin release`. Its declaration is the `release:` block of `bin/.devbin/config.yaml`.

hv runs the cut, because it tags and pushes. Every read-only step below is anyone's.

## Before the cut

- **The CHANGELOG's open section names its version**: `## [X.Y.Z] - unreleased`, never `## [Unreleased]`. The core finds the section by its version and dates it at the cut.
- **prez keeps its own version.** A release that bumps prez carries the bump (`opt/prez/crate/Cargo.toml` and `Cargo.lock`) in its own commit before the cut.
- **The tree is clean.** The pre-flight step refuses anything dirty outside what the release owns, untracked files included. The legs step fails the cut if a gate writes to the tree.
- **Every node holds its writes for the whole cut**, `intent wb` pickups and heartbeats included.
- **The gate is `bin/devbin check all`.** `bin/devbin test estate` (`tools/test-estate`, every suite under the bash 3.2.57 macOS ships) runs before the cut, not in it. A dry run runs no gate.
- **CI is read on the candidate, before the tag.** The legs step pushes the release commit to `candidate/<tag>`, which runs `tests.yml` with every leg, the macOS legs included. The core's `bin/devbin ci-state` reads that ref's runs. A red candidate, or no verdict within `release.ci.wait` (60 minutes by default), stops the cut with nothing tagged, and the candidate is deleted.
- **The tag is bare and annotated**: `2.15.0`, never `v2.15.0`. Its message is the CHANGELOG section's body.

## The cut

1. `bin/devbin release check` validates the declaration and prints it. It writes nothing.
2. `bin/devbin release --minor --dry-run` makes every read of the cut and none of its writes, and runs no gate. It refuses wherever the cut would. `--patch` and `--major` choose the other bumps, and `X.Y.Z` names a version.
3. `bin/devbin release --minor --yes`, run by hv. `--yes` answers the confirm step, so nothing asks again before the tap. Each step reads its postcondition first, so a re-run continues where the cut stopped.

| Step | Name       | What it does                                                                        |
| ---- | ---------- | ----------------------------------------------------------------------------------- |
| 1    | resolve    | the version and the tag                                                             |
| 2    | pre-flight | the branch, the tree, the note, every remote, and that the candidate's push runs CI |
| 3    | confirm    | asks once, naming the tag, the candidate, the pushes, the object and the formula    |
| 4    | stamp      | the version files and the CHANGELOG's date                                          |
| 5    | commit     | the release commit                                                                  |
| 6    | legs       | `check all`, the macOS stage signing Menuz.app, and the candidate's CI              |
| 7    | tag        | bare, annotated, once every leg is green                                            |
| 8    | push       | every remote, then the candidate is deleted                                         |
| 9    | object     | the release object, then `Menuz.app.zip` attached                                   |
| 10   | formula    | `formula publish --pull`: the formula to the tap, then this machine's clone         |
| 11   | after      | skipped: Utilz declares no `after:`                                                 |

**The version.** `--minor` bumps the newest tag that matches the template `{version}`, so only a bare `X.Y.Z` tag counts. The old tags `v1.0.0` to `v2.6.1` are not candidates. The dry run shows which version a bump resolves.

**The remotes.** `release.remotes` is undeclared, so the core pushes to every remote that `git remote` lists: `local` and `upstream`. `release.repo` names `matthewsinclair/utilz`, because with no `origin` the core cannot read the repository off a remote.

**If a step fails**, read what it printed and fix the cause. The core prints the command that resumes the cut. `bin/devbin release status <version>` prints where a cut got to, and writes nothing.

## Menuz.app

menuz's app ships as a release asset, `Menuz.app.zip`. The cut's macOS leg builds, signs and notarises it at the release commit, through devbin's built-in `bin/devbin macos`, which the `macos:` block of `bin/.devbin/config.yaml` declares. The object step then attaches it with `bin/devbin macos publish`. A failed attach ends the cut before the formula step, so the tap never names a release without the app. CI builds the app unsigned and reads no secrets.

Once on each Mac that cuts, hv stores the notary profile in the login keychain:

```bash
bin/devbin macos store-creds   # interactive: notarytool store-credentials, under the profile devbin
bin/devbin macos doctor        # the profile, the Developer ID identities and a test-sign
```

The leg's steps are devbin's. `app-sign` builds Release through `utilz menuz build --release` at the tag's commit and signs a staged copy. `app-notarize` notarises and staples it. `publish` zips it and attaches it to the release at the tag. `app-verify` checks the staged copy's signature and ticket again. A copy whose `MenuzCommit` is not the tag's commit, or whose `MenuzKind` is not `release`, is refused. `help/menuz.md` states the stamps.

By hand, outside a cut: `bin/devbin macos publish` from a tree whose version is the tag, then `bin/devbin formula publish --pull`.

The icon is Utilz's own. `bin/devbin macos app-icons` rasterises `native/macos/Menuz/design/menuz.svg` and `menuz-mark.svg` into the asset catalogue, and `bin/devbin macos app-icons-check` checks that `rsvg-convert`, both SVGs and the catalogue are there. Both run `tools/app-icons`.

## The Homebrew formula

Utilz installs with Homebrew from the tap `matthewsinclair/homebrew-utilz`. The formula builds from source at the bare tag. The repository keeps it as a template, `packaging/homebrew/utilz.rb`, with one `@@TAG@@`, one `@@REVISION@@` and one `@@INSTALL@@`. devbin's formula built-in fills them: the tag and its commit from git, and `@@INSTALL@@` with `bin/devbin install --prefix libexec --managed-by brew`, then the link set. The `formula:` block in `bin/.devbin/config.yaml` declares source mode and the tap.

- `bin/devbin formula render <tag> <out>` writes the formula for an annotated tag to `<out>`, and nothing in this tree. `bin/devbin formula check` makes every check that needs no tag, and `formula.bats` runs it.
- `bin/devbin formula publish --pull` renders the release into a fresh clone of the tap, commits and pushes it, then pulls this machine's clone of the tap. The cut's formula step runs it.

**Never type the commit by hand.** The offline `brew audit --strict` accepts any 40 hex digits, so a wrong commit passes the audit and fails every install. The render takes the commit from `git rev-parse <tag>^{commit}`. At install, brew checks out the tag and stops if its commit is not the formula's revision.

## After every cut

hv:

1. Audits this machine's tap, which the formula step pulled:

   ```bash
   HOMEBREW_NO_AUTO_UPDATE=1 brew audit --strict matthewsinclair/utilz/utilz
   ```

2. Upgrades each machine's brew install and reads it back, on rhadamanth, and on kovacs through kovacs-sysadm:

   ```bash
   HOMEBREW_NO_AUTO_UPDATE=1 brew upgrade utilz
   utilz version   # utilz <version> (brew, <sha12>)
   utilz doctor
   ```

3. Runs `bin/devbin use brew` in the checkout, as the cut's closing note says, and reads `utilz version` again.

On a machine that has tapped it, brew keeps the tap's clone at `$(brew --repository)/Library/Taps/matthewsinclair/homebrew-utilz`.
