# Releasing Utilz

A Utilz release is cut by **devbin's release core**, `bin/devbin release`, declared in the `release:` block of `bin/.devbin/config.yaml` (ST0019 D1).

**hv runs the cut.** It tags and pushes, and tags and pushes are hv's. Every read-only step below is anyone's.

Everything here was read from the copy vendored at `bin/.devbin/`, which is the copy that runs.

## Before the cut

- **The CHANGELOG's open section names its version**: `## [X.Y.Z] - unreleased`, never `## [Unreleased]`. The core finds a section by its version and dates it at the cut (ST0019 D2).
- **prez keeps its own version number.** A release that bumps prez carries the bump (`opt/prez/crate/Cargo.toml` and the `Cargo.lock` cargo rewrites) in its own commit before the cut (ST0019 D2, ruled 2026-09-21). A hand-written version needs a build before the suite reads it (issue 0056).
- **Run `bin/devbin check all` before handing a Rust change on, and do not read a green test suite as covering it.** `check all` runs `cargo fmt --check` and clippy; no Utilz suite runs either, and the pre-commit formatter gate stops at markdown (issues 0059 and 0060). `cargo fmt --check` also fails the CI step **ahead** of clippy, so drift hides the clippy verdict entirely rather than adding to it.
- **The tree is clean, and stays clean.** Step 2 refuses anything dirty outside what the release owns, untracked files included, so a realised view of a closed thread or a stray scratch file stops the cut. Step 5 re-reads the tree and `HEAD` after the gates and fails the cut if a gate wrote to either.
- **Every node holds its writes for the whole cut** (ST0019 D6). That includes `intent wb` heartbeats and pickups, which write a board view and a canon event.
- **The gate is `bin/devbin check all`** (hv, 28 Oct 2026, ST0030). `bin/devbin test estate`, which is `tools/test-estate` and runs every suite under the bash 3.2.57 macOS ships (issue 0051), runs before the cut and not in it. A dry run runs no gate, so the suites run in the twins before a cut, and in no step of the cut or its dry run.
- **CI is read on the candidate, before anything is tagged** (issue 0046, ST0031/04). The core reads CI itself, with its built-in `bin/devbin ci-state`: its legs step pushes the release commit to `candidate/<tag>`, whose push runs `tests.yml` with every leg, the macOS legs included, and it reads that ref's runs alone, the worst of them deciding. A red candidate, or no verdict within `ci.wait`, stops the cut with nothing tagged and the candidate deleted, and a run GitHub cancelled before a resumed cut's own push is passed over (devbin issue 0330).
- **The tag is bare and annotated**: `2.12.0`, never `v2.12.0`, with the CHANGELOG section's body as its message, passed with `--cleanup=whitespace` (ST0019 D7). The core writes it and reads it back.

## The cut

1. **`bin/devbin release check`** -- read-only. It validates the declaration and prints it.
2. **`bin/devbin release --minor --dry-run`** -- every read of the cut and none of its writes: no stamp, commit, tag, push or release object, **and no gate and no `after:`**. It runs `release.preflight`'s commands as the cut does, so it refuses wherever the cut would, and prints each step as what it would do. `--patch` and `--major` choose the other bumps, and `X.Y.Z` or `vX.Y.Z` names a version outright.
3. **`bin/devbin release --minor --yes`**, run by hv. `--yes` answers the confirm step, which names what the cut will push and run and carries on, so from here to the tap nobody is asked anything (ST0030). Without it, the cut stops at step 3 to ask. Eleven steps, each with a postcondition it reads first, so a re-run continues where it stopped rather than starting again (Devbin 0.1.28):

| Step | Name       | What it does                                                                        |
| ---- | ---------- | ----------------------------------------------------------------------------------- |
| 1    | resolve    | the version and the tag                                                             |
| 2    | pre-flight | the branch, the tree, the note, every remote, and that the candidate's push runs CI |
| 3    | confirm    | asks once, naming the tag, the candidate, the pushes, the object and the formula    |
| 4    | stamp      | the version files and the CHANGELOG's date                                          |
| 5    | commit     | the release commit                                                                  |
| 6    | legs       | `check all`, the macOS stage signing Menuz.app, and the candidate's CI              |
| 7    | tag        | bare, annotated, once every leg is green                                            |
| 8    | push       | every remote (see below), then the candidate is deleted                             |
| 9    | object     | the release object, then `Menuz.app.zip` attached (issue 0329)                      |
| 10   | formula    | `formula publish --pull`: the formula to the tap, then this machine's clone         |
| 11   | after      | none: the formula step is the core's, under `release.formula` (issue I59c806c)      |

**Which version it resolves.** `--minor` bumps the newest tag matching the declared template, and the template here is `{version}`, so a tag counts only when it is a bare `X.Y.Z`. This repository's older `v`-prefixed tags (`v1.0.0` through `v2.6.1`) are therefore not candidates and cannot be bumped. Ask which version a bump resolves with `bin/devbin release --minor --dry-run`, never by sourcing the core's functions into a shell of your own: the cut's handler runs under `set -euo pipefail`, and a plain shell can answer differently (devbin issue 0106).

**Where it pushes.** `release.remotes` is undeclared here, and undeclared means every remote `git remote` lists, in that order: **`local` and `upstream`, both**, which is this project's rule anyway. `release.repo` names `matthewsinclair/utilz` because with no `origin` and two remotes the core cannot read the repository off a remote and refuses rather than guessing.

**If a step fails**, read what it printed and fix the cause; the same command resumes. `bin/devbin release status <version>` prints where a cut got to, writing nothing, and exits non-zero if any row could not be read -- a map with a hole in it is not an answer.

## After the cut: Menuz.app

menuz's app ships as a release asset, `Menuz.app.zip`, beside the tag's source. The cut's macOS leg signs and notarises it at the release commit, on this machine, through devbin's built-in `bin/devbin macos` (ST0027 D12, as Intent signs `Intent.app`), which `bin/.devbin/config.yaml`'s `macos:` block declares for Menuz (issue 0118). The release core's object step makes the release object and then attaches the copy the leg signed, with `macos publish` (issue 0329, below). CI builds the app unsigned and reads no secrets.

**Once on each Mac that cuts**, hv stores the notary profile in the login keychain:

```bash
bin/devbin macos store-creds   # interactive: notarytool store-credentials, under the profile devbin
bin/devbin macos doctor        # the profile PRESENT, the Developer ID identities counted with their team, a test-sign
```

`store-creds` runs `notarytool store-credentials` under the profile `macos.notary_profile` names, `devbin` by default, and every notarisation submits under it. It runs in a terminal only, refusing a stdin that is not one. notarytool asks for an App Store Connect API key path, left empty, then the Apple ID, the app-specific password and the team id, each typed at its own prompt, so none reaches a command line (issue 0126), checks them with Apple and saves the profile. Nothing is written to this repository, and nothing prints a value. `doctor` names each Developer ID identity's team, and `macos.team` is declared only where it counts more than one. The `utilz.apple` items an earlier devbin read stay in the keychain, unread.

**At every cut, the core's object step attaches the app the cut's macOS leg signed, with `macos publish` (step 3 below), and only then does the cut publish the formula** (issue 0329, ST0031/01). A failed attach ends the cut before the formula step, so the formula never reaches the tap ahead of the app. A re-run continues where it stopped: the object step is done once the release carries `Menuz.app.zip`, and a tap already carrying the release is left as it is. Nothing here builds or signs. By hand, outside a cut, it is `bin/devbin macos publish` from a tree whose version is the tag, then `bin/devbin formula publish --pull`.

The leg signs in the primary at the release commit, the commit the tag then names, and `publish` reads the tag's commit, never HEAD: it refuses a staged copy signed at any other commit, and one whose `MenuzCommit` is not the tag's (issue 0103). So a node's board commit that moves the primary past the tag cannot make it ship another build, and the attach needs no worktree. A Menuz.app built off the tag carries that commit and the kind `dev`, and every Homebrew install's menu would show them.

Menuz versions apart from Utilz, from `opt/menuz/VERSION`, so a copy's version cannot show it is the tag's build. Its `MenuzCommit` stamp does: it must be 8 to 40 lowercase hex characters and begin the commit the tag names, with the tag in the tree. Its `MenuzKind` must be `release`, which menuz stamps by the rule `help/menuz.md` states with the stamps.

1. **`bin/devbin macos app-sign`**: refuses, building and signing nothing, unless HEAD is the commit of the tag the top-level `VERSION` names, in a clean tree, and names the worktree route. Then it builds Release through `utilz menuz build --release`, which checks its own product: its executable is there, `LSUIElement` is true, and it carries the stamps the build was given. It stages a copy under `${XDG_STATE_HOME:-~/.local/state}/devbin/macos/`, one stage per checkout, and refuses, signing nothing, a staged copy whose bundle id, version, `MenuzKind` or `MenuzCommit` is not the release's: the build products are shared by every tree, so another build can replace the one just made. Then it signs the copy inside-out with the Developer ID identity and the hardened runtime, and reads the identifier, the team and the runtime back off the signature.
2. **`bin/devbin macos app-notarize`**: submits the signed copy to Apple and waits. Anything but `Accepted` prints Apple's log and staples nothing. Then it staples the ticket and checks a quarantined copy with `spctl` for `source=Notarized Developer ID`.
3. **`bin/devbin macos publish`**: zips the stapled bundle as `Menuz.app.zip`, unpacks the zip and checks the bundle inside, and refuses, uploading nothing, when the stapled copy or the zip's copy fails the checks `app-sign` makes. Then it attaches the zip to the release at the tag through `bin/devbin release attach --from`, the core's one way an asset reaches a release, which writes `SHA256SUMS` over every asset and reads it back. An asset of the same name with the same bytes counts as attached; one with other bytes is refused, never replaced. After the upload, it drops every Launch Services record still standing at or under menuz's build root, `macos.build_root`, a Release build product's included, so the bundle id opens the installed app alone; a record left there is a warning, and the publish stands (issue 0115).

`bin/devbin macos app-verify` checks the staged copy's signature and ticket again at any time, changing no bundle.

Only the installed `~/Applications/Menuz.app` keeps a Launch Services record, so the bundle id opens it and never a build (issue 0106). Xcode registers each app it builds, so `utilz menuz build`, `test` and `install` drop the product's record after xcodebuild. A record can come back from outside Utilz after that drop, so `menuz install` ends, on both its paths, by dropping and checking every record under menuz's build root, as `publish` does after its upload (issue 0115). `codesign`, `stapler` and `spctl` can register the copies the built-in makes, so every step drops each copy's record on every way out, a refusal or an interrupt included, with the interrupt held off until the drop is done, and reads the record list back (issues 0104 and 0106). A record left on the staged copy is a warning naming the `lsregister -u` line that drops it, and the step's own exit stands, since the next step drops it again. One left on the Gatekeeper check's copy or on the copy `publish` unpacks to prove its zip, or a proof directory not removed, fails the step, and after an upload the message says first what was published. `utilz menuz doctor` says `WARN` for each record of the bundle id at any other path.

The icon is Utilz's own, not the built-in's: `bin/devbin macos app-icons` rasterises `native/macos/Menuz/design/menuz.svg` and `menuz-mark.svg` into the asset catalogue, and `bin/devbin macos app-icons-check` says whether `rsvg-convert`, both SVGs and the catalogue are there. Both are declared options that run `tools/app-icons`, and neither is in `macos all`.

**Publish before pushing the tap.** In a Homebrew install, `menuz install` fetches `Menuz.app.zip` from the release named by the install's own `VERSION`, and checks its signature, its notarisation, its bundle id and its version before replacing anything. Until the asset is attached, it exits 1, naming the URL it tried and saying that the release carries no Menuz.app. So a formula pushed before `publish` gives every new install a `menuz install` that fails until the asset arrives.

## After the cut: the Homebrew formula

Utilz installs with Homebrew from the tap `matthewsinclair/homebrew-utilz`. Its formula builds from source at the bare tag, so it names the tag and the tag's commit. The repository keeps the formula as a template, `packaging/homebrew/utilz.rb`, with one `@@TAG@@`, one `@@REVISION@@` and one `@@INSTALL@@`, and is never installed from. devbin's formula built-in fills them, as the dev, opt, brew contract has every tool's formula rendered (T8, devbin's `docs/dev-opt-brew.md`; issues 0105 and I59c806c): the tag and its commit from git, and `@@INSTALL@@` with the core's one install form, `bin/devbin install --prefix libexec --managed-by brew` from the tag's checkout, then the link set. Render also writes the bash the build needs and the step that hashes the manifest again after brew changes the keg. The template's declaration is the `formula:` block in `bin/.devbin/config.yaml`: source mode, and the tap.

- `bin/devbin formula render <tag> <out>` writes the formula for an annotated tag to `<out>`, and writes nothing in this tree. `bin/devbin formula check` makes every check render makes that needs no tag, and Utilz's formula.bats runs it.
- `bin/devbin formula publish --pull` renders the release into a fresh clone of the tap, commits it and pushes it, then brings this machine's clone of the tap forward, where Homebrew keeps one. It pushes, so it runs in hv's cut, as the core's formula step under `release.formula`, once the object step has attached `Menuz.app.zip`.

**Never type the commit by hand.** The offline `brew audit --strict` accepts any 40 hex digits, so a wrong commit passes the audit and fails at every user's install. The commit comes from `git rev-parse <tag>^{commit}`, inside devbin's render.

### After every cut

The core's object step attaches Menuz.app's asset first, the copy the cut's macOS leg signed (above). Then the core's formula step publishes the formula to the tap and pulls this machine's clone, with `bin/devbin formula publish --pull`. Nothing is committed in this repository: the template does not change from one release to the next.

Then hv:

1. **Audits this machine's tap**, which the formula step's `--pull` has pulled (brew's own auto-update can leave a third-party tap behind, as it left 2.14.4 after 2.14.5's publish), with Homebrew's auto-update off, as every scripted brew call runs:

   ```bash
   HOMEBREW_NO_AUTO_UPDATE=1 brew audit --strict matthewsinclair/utilz/utilz
   ```

2. **Upgrades each machine's brew install and reads it back.** On rhadamanth, and on kovacs through kovacs-sysadm:

   ```bash
   HOMEBREW_NO_AUTO_UPDATE=1 brew upgrade utilz
   utilz version   # utilz <version> (brew, <sha12>)
   utilz doctor
   ```

   An install from before the contract's manifest reads as `brew (old manifest)`, which doctor notes, and this upgrade replaces it.

3. **Proves the switch on rhadamanth** (contract T10): `bin/devbin use dev`, `bin/devbin use opt`, `bin/devbin use brew` in turn, run in the checkout, each followed by `utilz version` and `utilz doctor`, whose PATH check fails if a link is shadowed. It needs `~/.local/bin` before Homebrew's bin on PATH, which Molt-matts' sleeve config sets.

A formula that names a commit brew cannot fetch fails every install, so the tap is published only after this repository's tag is pushed.

**A wrong commit fails loudly at install, never silently.** When brew fetches a git URL with both `tag:` and `revision:`, it checks out the tag and compares the commit it got with the formula's revision. On a mismatch it stops: "`<tag>` tag should be `<revision>` but is actually `<commit>`" (`download_strategy/vcs_download_strategy.rb:46-51` in this machine's Homebrew). The offline audit makes no such check, which is why the commit comes from devbin's formula built-in (`bin/devbin formula`) and the first install after a publish is the real proof.

### Where the tap lives, and how it was set up

The tap's repository is `matthewsinclair/homebrew-utilz` on GitHub. On a machine that has tapped it, brew keeps its clone at `$(brew --repository)/Library/Taps/matthewsinclair/homebrew-utilz`, as hv's Intent tap is kept.

It was set up once, at the 2.11.0 cut on 2026-09-21, with `gh repo create matthewsinclair/homebrew-utilz --source . --push` and `brew tap matthewsinclair/utilz` (ST0019 AC-05.2).
