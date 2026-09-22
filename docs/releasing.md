# Releasing Utilz

A Utilz release is cut by **devbin's release core**, `bin/devbin release`, declared in the `release:` block of `bin/.devbin/config.yaml` and switched on since 2026-09-21 (hv's OK; ST0019 D1, Devbin ST0007 WP-08, commit cb45181). **2.12.0 is the first cut through it.** Every release up to 2.11.0 was cut by hand, the last of them on hv's ruling of 14 September that the core would be adopted after it rather than during it.

**hv runs the cut.** It tags and pushes, and tags and pushes are hv's. Every read-only step below is anyone's.

Everything here was read from the copy vendored at `bin/.devbin/`, which is the copy that runs. A sweep of the vendored runtime is not a prerequisite for a cut; where a sweep would change what is written here, it is this page that is re-read against the swept copy, not the cut that waits.

## Before the cut

- **The CHANGELOG's open section names its version**: `## [X.Y.Z] - unreleased`, never `## [Unreleased]`. The core finds a section by its version and dates it at the cut (ST0019 D2).
- **prez keeps its own version number.** A release that bumps prez carries the bump (`opt/prez/crate/Cargo.toml` and the `Cargo.lock` cargo rewrites) in its own commit before the cut (ST0019 D2, ruled 2026-09-21). A hand-written version needs a build before the suite reads it (issue 0056).
- **Run `bin/devbin check all` before handing a Rust change on, and do not read a green test suite as covering it.** `check all` runs `cargo fmt --check` and clippy; no Utilz suite runs either, and the pre-commit formatter gate stops at markdown. Six formatting diffs rode five commits into `main` on 2026-09-22 under a green 13/13 thread and a green estate, reddened CI, and would have refused the cut at step 5 (issues 0059 and 0060). `cargo fmt --check` also fails the CI step **ahead** of clippy, so drift hides the clippy verdict entirely rather than adding to it.
- **The tree is clean, and stays clean.** Step 2 refuses anything dirty outside what the release owns, untracked files included, so a realised view of a closed thread or a stray scratch file stops the cut. Step 5 re-reads the tree and `HEAD` after the gates and fails the cut if a gate wrote to either.
- **Every node holds its writes for the whole cut** (ST0019 D6). That includes `intent wb` heartbeats and pickups, which write a board view and a canon event.
- **The gates are `bin/devbin check all` and `bin/devbin test estate`.** The second is `tools/test-estate`, which runs every suite under the bash 3.2.57 macOS ships (issue 0051) rather than under Homebrew's bash 5.
- **CI cancels a run that a newer push supersedes, and the macOS legs run on the TAG, not on the push** (issue 0046). A superseded commit's run concludes `cancelled`, which `tools/ci-state`, the core's CI query, reads as `failed`; the core reads CI after it pushes, so nothing may land on `main` between the release push and that read, which the hold above already guarantees. A release commit therefore carries two runs, the branch's without macOS and the tag's with it, and the query reads every run on the commit and answers with the worst of them (issue 0052), so its verdict does not depend on which of the two push events GitHub registered first.
- **The tag is bare and annotated**: `2.12.0`, never `v2.12.0`, with the CHANGELOG section's body as its message, passed with `--cleanup=whitespace` (ST0019 D7). The core writes it and reads it back.

## The cut

1. **`bin/devbin release check`** -- read-only. It validates the declaration and prints it.
2. **`bin/devbin release --minor --dry-run`** -- every read of the cut and none of its writes: no commit, no tag, no push, no release object. **The gates still run**, on `HEAD` in place; since a dry run makes no release commit, that predicts the gates rather than gating the release. `--patch` and `--major` choose the other bumps, and `X.Y.Z` or `vX.Y.Z` names a version outright.
3. **`bin/devbin release --minor`**, run by hv. Eleven steps, each with a postcondition it reads first, so a re-run continues where it stopped rather than starting again:

| Step | Name       | What it does                                                        |
| ---- | ---------- | ------------------------------------------------------------------- |
| 1    | resolve    | the version, the tag, and whether this is a new cut or a resume     |
| 2    | pre-flight | the branch, the remotes, the tree, the notes                        |
| 3    | stamp      | the version files and the CHANGELOG's date                          |
| 4    | commit     | the release commit                                                  |
| 5    | gates      | `check all` and `test estate`, then the tree and `HEAD` are re-read |
| 6    | confirm    | what is about to be pushed, and where                               |
| 7    | tag        | bare, annotated, written and read back                              |
| 8    | push       | every remote (see below)                                            |
| 9    | object     | the release object                                                  |
| 10   | after      | the declared follow-on commands                                     |
| 11   | ci         | the CI verdict, through `tools/ci-state`                            |

**Which version it resolves.** `--minor` bumps the newest tag matching the declared template, and the template here is `{version}`, so a tag counts only when it is a bare `X.Y.Z`. This repository's sixteen older `v`-prefixed tags (`v1.0.0` through `v2.6.1`) are therefore not candidates and cannot be bumped: the newest match is `2.11.0` and `--minor` resolves `2.12.0`.

**Where it pushes.** `release.remotes` is undeclared here, and undeclared means every remote `git remote` lists, in that order: **`local` and `upstream`, both**, which is this project's rule anyway. `release.repo` names `matthewsinclair/utilz` because with no `origin` and two remotes the core cannot read the repository off a remote and refuses rather than guessing.

**If a step fails**, read what it printed and fix the cause; the same command resumes. `bin/devbin release status <version>` prints where a cut got to, writing nothing, and exits non-zero if any row could not be read -- a map with a hole in it is not an answer.

## After the cut: the Homebrew formula

Utilz installs with Homebrew from the tap `matthewsinclair/homebrew-utilz`. Its formula builds from source at the bare tag, so it names the tag and the tag's commit. The formula is kept in this repository at `packaging/homebrew/utilz.rb` and copied into the tap.

### Where the tap lives, and how it was set up

The tap lives where brew keeps every tap, `$(brew --repository)/Library/Taps/matthewsinclair/homebrew-utilz`: a git clone whose `origin` is the GitHub repository, as hv's Intent tap is. hv edits, commits and pushes the formula there.

It was set up once, at the 2.11.0 cut on 2026-09-21, after this repository's tag was pushed:

1. `tools/formula-bump 2.11.0` here, and the bump committed (d5899ee).
2. A local repository staged with that formula as `Formula/utilz.rb`, then `gh repo create matthewsinclair/homebrew-utilz --source . --push`.
3. `brew tap matthewsinclair/utilz`, which cloned it into the path above.
4. `brew audit --strict matthewsinclair/utilz/utilz` (clean), `brew install matthewsinclair/utilz/utilz` (built in 44 s) and `utilz doctor` (7/7, manifest intact, `managed-by` brew). ST0019 AC-05.2.

### After every later cut, hv:

1. **Writes the new tag and its commit into the formula, from git:**

   ```bash
   tools/formula-bump 2.12.0
   ```

   It refuses a tag that does not exist or is not annotated, reads the commit with `git rev-parse 2.12.0^{commit}`, rewrites only the formula's `tag:` and `revision:` lines, and prints the diff. **Never type the commit by hand**: the offline `brew audit --strict` accepts any 40 hex digits, so a wrong commit passes the audit and fails at every user's install.

2. **Commits the bump here**, by path: `packaging/homebrew/utilz.rb`.

3. **Copies the formula into the tap** as `Formula/utilz.rb`, in the tap's clone above.

4. **Audits it from the tap:**

   ```bash
   brew audit --strict matthewsinclair/utilz/utilz
   ```

5. **Commits and pushes the tap.** Pushing the tap is hv's, as pushing this repository is. No release `after:` hook does it (ST0019 WP-05, hv's ruling of 2026-09-21).

A formula that names a commit brew cannot fetch fails every install, so the tap is pushed only after this repository's tag is.

**A wrong commit fails loudly at install, never silently.** When brew fetches a git URL with both `tag:` and `revision:`, it checks out the tag and compares the commit it got with the formula's revision. On a mismatch it stops: "`<tag>` tag should be `<revision>` but is actually `<commit>`" (`download_strategy/vcs_download_strategy.rb:46-51` in this machine's Homebrew). The offline audit makes no such check, which is why the commit comes from `tools/formula-bump` and the first install after a push is the real proof.
