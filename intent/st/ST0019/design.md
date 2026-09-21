# ST0019 design: Utilz's parts of the release pipeline

Scope, hv's decision 1 of 14 Sep: **Utilz's own parts only**, meaning its declaration to devbin's release core, its version files and its Homebrew formula. The core is Devbin's, vendored at 0.1.3. Every claim about it cites the vendored line it was read from (`bin/.devbin/lib/cmd/release`, `release.steps`, `release.notes`).

| Q   | Question                                   | Answer                                                                   |
| --- | ------------------------------------------ | ------------------------------------------------------------------------ |
| 1   | What the formula installs, where it builds | From source off the bare git tag, macOS both architectures (D3, hv)      |
| 2   | brew versus `utilz install` / `upgrade`    | Beside them; a keg is an install tree whose upgrade is brew's (D4, hv)   |
| 3   | Bare tags                                  | `tag: "{version}"` (D1), hv's ruling at 2.7.0                            |
| 4   | Where the shared core lives                | Devbin, ruled 14 Sep                                                     |
| 5   | Notes and the CHANGELOG date               | `notes.kind: changelog`, the open section named by version (D2)          |
| 6   | CI green before the tag                    | No: the local gates are the gate, and CI reports after (D5, vc's ruling) |

## D1. The release declaration

Declared in `bin/.devbin/config.yaml`, naming only what differs from the defaults (`config.reference.yaml:482`), and **switched on with `commands.release.enabled: true` on hv's OK of 2026-09-21 (vc's decision 12)**. The switch-on's first act, before any cut, is vc's read-only `bin/devbin release check`.

```yaml
release:
  tag: "{version}"
  repo: matthewsinclair/utilz
  gates:
    - check all
    - test estate
  ci:
    query: tools/ci-state
```

- **`repo:`** is declared because otherwise the core refuses: with no `origin` and two remotes (`local`, `upstream`), `release_repo` cannot choose (`release.steps:622-639`). `remotes:` stays undeclared, so both are pushed in `git remote` order.
- **`gates:`** is `check all` and `test estate`, a `test` option running `bin/utilz test`, the one driver that discovers every suite kind (bats, cargo, `crate/test/*.sh`), so the release gate is the hand gate by construction. It is `in_all: false`, so `test all` stays quick and never needs video.sh's Chrome and ffmpeg. Naming the black-box suites one by one was rejected, because it brings back ST0013/AC03's unrun suite; `test all` beside it would only repeat bats and cargo.
- **`ci.query: tools/ci-state`** makes step 11 a verdict rather than a skipped row (`cmd/release:985`). The script sources `install.sh`, asks through `install_ci_state` alone (issue 0016), and maps its answer: `success` to `green`, any other conclusion to `failed`, and `pending`, `none` and `unknown` passed through. It lives in `tools/` because `bin/` is published (`install.sh:99`, `INSTALL_EXCLUDE_RE` at `install.sh:50`), and CI's shellcheck collector reads `bin opt tools`.
- **`object: local`** stays the default, because no workflow triggers on a tag.
- **Proof before the switch-on:** `bin/devbin` refuses an inactive command before its handler runs (`bin/devbin:624`), so WP-01 proved the block through `bin/devbin doctor`, whose `cfg_validate` checks every `release:` key and value.

## D2. Version files and notes

- **prez keeps its own number** (hv, 2026-09-21). `Cargo.toml` is not a sidecar, since sidecars mirror `VERSION` (`config.reference.yaml:106`). A release that bumps prez carries the bump (`Cargo.toml` and `Cargo.lock`) in its own commit before the cut, because the core refuses any dirty path it does not own (`cmd/release:550`).
- **The open CHANGELOG section names its version**, `## [2.11.0] - unreleased`, because the core finds a section by version (`release.notes:805`) and dates it at the cut (`release.notes:839`). `## [Unreleased]` would read as absent.

## D3. The formula

Built from source in the tap `matthewsinclair/homebrew-utilz`, kept at `packaging/homebrew/utilz.rb` here and copied into the tap. macOS, both architectures, with no prebuilt or signed artefacts (hv, 2026-09-21; bottles may come later).

- **Source, not binaries:** `install_build_prez` already builds prez and showreel with cargo (`install.sh:570`), so there is no signing, notarising or upload pipeline, and both architectures come by construction.
- **A git URL, not a tarball:** `install_owned_paths` lists the install with `git ls-files` and refuses a tree that is not a git toplevel (`install.sh:95-99`). brew stages a git URL with `.git` and keeps the tree clean (`formula.rb:3941-3952` ignores its own `HOME`). WP-03 proved both.
- **`def install` calls Utilz's own publish**, `utilz install --prefix libexec --managed-by brew`, and links `bin/` to each dispatcher link. So the keg is the same kind of tree as `~/Devel/opt/utilz`, and the dispatcher finds `libexec` from its own resolved path (`bin/utilz:39-40`).
- **One runtime dependency, `yq`.** Each utility's own dependencies are reported by `utilz doctor`, and the caveat points at it. `:recommended` was rejected, because brew installs those by default; `:optional` was rejected, because no user passes `--with`.
- **`license "MIT"`** (hv, 2026-09-21), with a LICENSE file here.
- **The tag and its commit are written by `tools/formula-bump <tag>`, never typed** (D6). Until 2.11.0 is cut, the revision is a marked placeholder.

## D4. A keg is brew's

A keg carries the manifest, so it is an install tree (`install.sh:172`), and every install-tree behaviour holds. Beside that, brew owns it (hv, 2026-09-21):

- **The marker is a manifest header row, `managed-by`**, written by `utilz install --managed-by brew`, and `utilz` by every other publish; a manifest from before the row reads as `utilz`. A flag alone leaves nothing for a later verb to read, and a `Cellar` path pattern is not a fact the keg carries. `install_tree_manager` reads it, in `common.sh` so that `utilz test` can ask it without `install.sh`.
- **`install --force`, `upgrade`, `relink` and `use` refuse when the tree they run from or target is a keg**, naming `brew upgrade utilz`. `install_refuse_keg` is the one refusal, and `use` inherits it through `relink`. They would rewrite files brew checksums, or point PATH into a versioned keg that the next `brew upgrade` removes.
- **`source-tree` in a keg names brew's deleted build directory.** So `use dev` refuses before reading it, and `utilz test`'s refusal names a git clone instead (`common.sh:1035`). `ci-state` may be `unknown` inside brew's build, which is that row's defined answer.

## D5. The risk that remains: Linux-only defects

The gates run on the maintainer's macOS machine, and CI's Ubuntu legs report after the tag (D40, _"CI does not gate the release, it reports on it"_, `cmd/release:979`). A red step 11 means fixing forward in the next patch, never moving the tag.

## D6. The release window, the tag, and the formula after the cut

- **The window:** the core refuses a cut while any path it does not own is dirty, untracked included (`release.steps:361`, `cmd/release:550`), and fails it if a gate changes the tree (`cmd/release:707`). So every node commits its views and events, then holds every `intent` write, `pickup` and `touch` included, for the whole cut. Both gates leave the tree byte-identical (measured in WP-01).
- **The tag** is bare and annotated, made with `--cleanup=whitespace` (`cmd/release:811`), and read back after it is made (`cmd/release:814-818`). Its message is the CHANGELOG section's body alone (`release.notes:852`), without 2.10.0's headline line, so the fleet has one form.
- **The formula after each cut** (hv, 2026-09-21): no `after:` hook, because `after:` runs outside the core's guarantees (`cmd/release:1023`) and the tap is hv's to push. hv runs `tools/formula-bump <tag>`, which refuses a missing or lightweight tag, reads `git rev-parse <tag>^{commit}`, and rewrites only the `tag:` and `revision:` lines. It exists because the offline audit accepts any 40 hex digits. brew itself checks the tag against the revision at fetch (`vcs_download_strategy.rb:46-51`). `docs/releasing.md` is the procedure, including the tap's one-time setup at 2.11.0.

## Work packages

| WP  | Title                                                                       | Status          |
| --- | --------------------------------------------------------------------------- | --------------- |
| 01  | Gates, tools/ci-state, the heading convention, and gates that leave no dirt | Done            |
| 02  | The keg as an install tree: the discriminator and the verbs that refuse     | Done            |
| 03  | Spike: a git-URL formula built in a scratch tap, the keg run end to end     | Done            |
| 04  | The tap matthewsinclair/homebrew-utilz and its formula                      | Done            |
| 05  | The formula bump after a release: after: or a documented step               | Open on AC-05.2 |

AC-05.2, the install from the pushed tap at the bare tag, waits for the 2.11.0 cut.
