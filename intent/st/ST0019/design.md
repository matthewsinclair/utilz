# ST0019 design: Utilz's parts of the release pipeline

cc drafted this on 2026-09-21, for vc's review before any code (vc's todo 11). The scope is hv's decision 1 of 14 Sep: **Utilz's own parts only**, meaning its version files, the CI build of prez and the Homebrew formula. The shared release core is Devbin's, and switching it on at Utilz is **Devbin's ST0007 WP-08, not this thread**.

## What changed since the brief

The brief in `info.md` was written on 14 Sep against a release core that did not exist yet. Devbin 0.1.2 was vendored here at `633a1a1` on 2026-09-20, with the core present, opt-in and off (`bin/.devbin/lib/cmd/release`, `release.steps`, `release.notes`). So this design **declares against a contract read from source** instead of describing one. Every claim about the core below cites the line it was read from. No devbin command was run to learn any of it.

## Question by question

| Q   | Question                                   | Answer                                                                               | Owner            |
| --- | ------------------------------------------ | ------------------------------------------------------------------------------------ | ---------------- |
| 1   | What the formula installs, where it builds | A formula built from source off the git tag, on the user's machine (D3)              | ruled 2026-09-21 |
| 2   | brew versus `utilz install` / `upgrade`    | Beside them. A keg is an install tree whose upgrade is brew's (D4)                   | ruled 2026-09-21 |
| 3   | Bare tags                                  | Declared: `tag: "{version}"` (D1)                                                    | settled at 2.7.0 |
| 4   | Where the shared core lives                | Devbin, ruled 14 Sep, delivered in 0.1.2                                             | closed           |
| 5   | Notes and the CHANGELOG date               | `notes.kind: changelog`, with the heading convention changed (D2)                    | this design      |
| 6   | CI green before the tag                    | Dropped, on vc's ruling of 2026-09-21: the local gates are the gate, CI reports (D5) | closed           |

## D1. The release declaration

This is the block Utilz declares in `bin/.devbin/config.yaml`. **WP-01 declares it with the command still off**, and WP-08 only switches it on. It names only what differs from the defaults (`config.reference.yaml:482`: every uncommented value is the default).

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

- **`tag: "{version}"`** is hv's ruling at 2.7.0, which lives in 2.7.0's annotation. The reference already names Utilz as the case (`config.reference.yaml:498`).
- **`repo:` has to be declared, because otherwise the core refuses.** With `repo:` and `remotes:` both undeclared, `release_repo` (`release.steps:616-633`) reads the repository from `origin`, else from the only remote, else refuses: _"not exactly one remote -- declare release.repo"_. Utilz has `local` and `upstream` and no `origin`, so the cut stops there. The core never reads `local`, and if it did, its Dropbox url would be refused as naming no host. (This bullet first said the core read `local`; devbin's dc caught it against the source, and vc verified it in the vendored copy.)
- **`remotes:` stays undeclared**, so both remotes are pushed in `git remote` order, as hv pushes by hand today.
- **`gates:` is `check all` and one estate gate, `test estate`, which runs `bin/utilz test`.** That is the driver behind every hand release, 2.10.0's 20 of 20 suites included, so the release gate is the hand gate by construction rather than a list kept in step with it. Three alternatives were weighed and rejected:
  - **The default `test all`** runs the bats estate and the workspace's cargo tests through `bin/.devbin/config.yaml`'s `test` options, but not the black-box suites under `opt/*/crate/test/*.sh` (acceptance.sh, theme-addressing.sh, video.sh). On its own it is narrower than the hand gate.
  - **Three named gates, one per black-box suite** (the first revision of this design), bring back the failure ST0013/AC03 fixed. CI (`.github/workflows/tests.yml:328`) and `utilz test` (`common.sh:1116`) both DISCOVER `crate/test/*.sh` rather than naming each file, because naming one let a second suite go unrun while CI stayed green. A fourth suite added later would run under both and be run by nothing at release.
  - **`test all` plus `test estate`** runs bats and cargo twice inside the release window, and vc ruled it out. `test all` runs nothing `utilz test` does not: measured 2026-09-21, the 16 `opt/*/test` directories `bats opt/*/test` reads are exactly the 16 utilities `utilz test` walks, `utilz` included, and prez's crate, the only crate, is the one `utilz test` runs with `--workspace`.

  `estate` is declared as a `test` option with `in_all: false`, so `test all` stays the quick everyday verb, and video.sh's needs (Chrome, ffmpeg and a quiet machine, the load rule from 2.10.0) never land on it. The option is **reported as skipped, not dropped** (`config.reference.yaml:422-424`). A gate is a devbin verb run by its words (`cmd/release:698-702`), so the form is legal. **With the command off, `release check` cannot run**: `bin/devbin` refuses an inactive command with exit 2 before its handler runs (`bin/devbin:616-628`). So WP-01 proves the declaration through `bin/devbin doctor`, whose `cfg_validate` checks every `release:` key and value (`config:755`, `config:765`; `cmd/doctor:111`), and the core's read-only `release check` is **the first act of the switch-on, before any cut** (vc, 2026-09-21). `utilz test` notes that it "mutates `$UTILZ_HOME/bin`" (`common.sh:973`), so WP-01's dirt proof (D6) runs on this exact command first.

- **`ci.query: tools/ci-state`** is declared so that step 11 gives a verdict: an undeclared `ci.query` prints a skipped row, _"no ci.query declared"_ (`cmd/release:985`), and a skipped row is not a verdict. (This bullet and D5 first said step 11 was skipped silently; dc caught it, and vc verified it.) `tools/ci-state` is a thin wrapper that sources `install.sh` and calls **`install_ci_state`**, the one function that asks CI about a commit (issue 0016). Its only logic is mapping: `install_ci_state` prints the run's conclusion (`success`, `failure`, `cancelled` and so on), and `ci.query` expects `green`, `failed`, `pending`, `none` or `unknown`. `success` becomes `green`, any other conclusion becomes `failed`, and `pending`, `none` and `unknown` pass through. There is no second `gh` query. **It lives in `tools/`, outside the published set, on vc's review.** The publish ships every tracked file under `bin` except `bin/devbin` and `bin/.devbin/` (`install.sh:99`, `INSTALL_EXCLUDE_RE` at `install.sh:50`). So a release tool in `bin/` would ship to every install and every keg as if it were a utility, and `install_e2e`'s link census and `utilz list` would find a real file where only dispatcher links live. `INSTALL_EXCLUDE_RE` is not widened for it. The reference's `bin/ci-state` is only an example. A new top-level `tools/` also sits outside CI's shellcheck collector, which runs `find bin opt` (`.github/workflows/tests.yml:190`), so WP-01 adds `tools` to that collector, or the script ships unlinted.
- **`object: local`** is the default and stays. No workflow here triggers on a tag (`.github/workflows/tests.yml`, `pr-checks.yml`), so `check_release_writers` (`cmd/release:170`) finds no second writer. D3 needs no release assets, so `object: ci` would buy nothing.

## D2. Version files and notes

**The core has one version number, and Utilz has two.** `VERSION` (the framework, 2.10.0) and `opt/prez/crate/Cargo.toml` (prez, 2.2.0) move independently: 2.10.0 took prez from 2.1.0 to 2.2.0. The core's `project.version_sidecars` are files that **mirror** `VERSION` (`config.reference.yaml:87`), and it deliberately has no `Cargo.lock` recipe (`cmd/version:66`).

**Ruled (a), hv on 2026-09-21 (vc's decision 6), as cc recommended and vc concurred:** prez keeps its own number. `Cargo.toml` is **not** declared as a sidecar. A release that bumps prez carries that bump in its own commit before the cut (`Cargo.toml` plus the `Cargo.lock` cargo rewrites), because the core refuses any dirty path outside the files it owns (`cmd/release:550`). The release commit then owns `VERSION` and `CHANGELOG.md` alone, and `derived:` stays undeclared. hv has already treated prez's number as its own twice: decision 2, item 3 of 14 Sep, and `prez --version` printing `utilz:2.10.0/prez:2.2.0`. Alternative (b): prez takes the framework's number at every release, which means declaring the sidecar and a `derived:` command that rewrites the lock and prints its path.

**The CHANGELOG heading convention changes.** The core finds a section by its version: `## [X.Y.Z] - <YYYY-MM-DD | unreleased | in progress>` (`release.notes:805`). Utilz writes `## [Unreleased]`, which the core would read as `absent` and refuse at pre-flight. From the next release on, the open section is headed by its version. **hv ruled 2026-09-21 that the next is 2.11.0**, so it is `## [2.11.0] - unreleased`, and the core dates it at cut time (`_notes_changelog_write_date`, `release.notes:839`). Naming the version while the section is open is the price, and it is a small one: the Minor or Patch line already has to decide it.

## D3. The formula (Q1), ruled

**Ruled by hv on 2026-09-21 (vc's decision 6), as recommended: the formula builds from source off the git tag**, macOS on both architectures, with no prebuilt or signed artefacts (bottles may come later), in a tap `matthewsinclair/homebrew-utilz`:

```ruby
url "https://github.com/matthewsinclair/utilz.git", tag: "2.11.0", revision: "<sha>"
depends_on "rust" => :build
```

**Why source and not prebuilt binaries as Intent ships:**

- **No artefact pipeline.** Intent's formula installs signed, notarised binaries that `int macos prepare` builds and `int macos publish` attaches to the release. Utilz ships a bash framework whose only compiled parts are prez and showreel, and `install_build_prez` (`install.sh:549`) already builds both with `cargo build --release --workspace`. A source formula reuses that build and needs no signing, no notarisation, no upload and no `object: ci` workflow.
- **Platforms come by construction.** Building on the user's machine serves macOS arm64 and Intel alike, where Intent is arm64-only by ruling (hv, 2026-08-15). Ruled platform statement: **macOS, both architectures**, with `depends_on :macos`. Linuxbrew would work in principle, since CI exercises the source on Ubuntu, but nobody has installed a keg on Linux, so it is left out rather than claimed.
- **A git URL, not the tag tarball, and this is load-bearing.** `install_owned_paths` enumerates what an install contains with `git ls-files` (`install.sh:99`) and refuses a tree that is not a git top level (`install.sh:95`). A tarball has no `.git`. Homebrew's git strategy stages by copying the cached checkout recursively, `.git` included (`download_strategy/git_download_strategy.rb:265` describes exactly that copy), so the manifest keeps one authority for its file list. **The tree also stays clean inside brew, and that matters just as much**, because `install_tree_state` reads the WHOLE tree (`install.sh:198`) and `utilz install` refuses a dirty source. Homebrew sets the build's `HOME` to `buildpath/.brew_home` and writes a `*` `.gitignore` into it, under the comment _"Don't dirty the git tree for git clones."_ (`Library/Homebrew/formula.rb:3941-3952` in this machine's Homebrew; vc found it). **Both are read from Homebrew's source, not driven**, and WP-03's spike is where they are proved.

**What `def install` does: it calls Utilz's own publish instead of copying files.** `utilz install --prefix #{libexec}` already builds prez, copies the owned set and writes the manifest (`install.sh:752`). One publish path means the keg and `~/Devel/opt/utilz` are the same kind of tree, and the dispatcher, the prez shim's install branch (`opt/prez/prez`, which runs the shipped binary and never builds) and `utilz doctor` need no brew-specific path. The layout follows Intent's formula for the same reason Intent gives: the tree lives in `libexec`, because the dispatcher derives `UTILZ_HOME` from its own resolved path (`bin/utilz:43`), and `bin/` gets one symlink per dispatcher link (fifteen utilities plus `utilz`).

**The manifest has to survive brew's post-install.** Brew may normalise permissions or re-sign the prez and showreel Mach-O binaries after `def install` returns, and either one changes bytes the manifest checksummed. So WP-03's spike runs `utilz doctor` inside the finished keg and proves the manifest still verifies, instead of assuming it does because the publish verified at write time.

**Lessons carried over from Intent's formula, each measured there:** `url` at top level, never nested, because `brew tap` validates under every simulated OS. No `version` line if brew reads the version from the tag. The exec bit is irrelevant here, because nothing is a downloaded release asset.

**Runtime dependencies, read from each utility's yaml on 2026-09-21.** Required: `yq` (the framework itself), `jq`, `git`, `gpg`, `python3`, `qpdf` and poppler (`pdfinfo`, `pdftoppm`), `unison`, `rsync`. Optional: `ffmpeg` (prez's video export), `glow`, `bat`. Recommendation: `depends_on` only what the framework needs to start (`yq`), plus the rest as `=> :recommended` where brew has them, so installing one utility does not cost fifteen utilities' dependencies. `utilz doctor` already reports every missing dependency, optional ones included (2.10.0), and a caveat points at it.

## D4. brew beside `utilz install` and `upgrade` (Q2), ruled

**Ruled by hv on 2026-09-21 (vc's decision 6), as recommended: beside, not replacing.** `utilz install` and `upgrade` publish from a source checkout to `~/Devel/opt/utilz`, which is the maintainer's loop (ST0014), and brew is how everyone else installs. The two never share a tree.

- **A keg is an install tree.** It carries the manifest, so `install_tree_kind` answers `install` (`install.sh:172`), and every install-tree behaviour holds unchanged.
- **The verbs that write a tree refuse inside a keg.** `upgrade`, `relink` and `use` would rewrite files brew owns and checksums, so in a keg they refuse and name `brew upgrade utilz`. The discriminator must be a fact the keg carries, not a path pattern such as `Cellar`: WP-02 decides between a manifest header row written by the formula's publish (`INSTALL_MANIFEST_HEADER_KEYS`, `install.sh:271`) and a flag passed to `install`.
- **The manifest's header rows mean what they say.** `source-commit` is the tag's commit, `source-tree` is `clean` (a fresh checkout), and `ci-state` is whatever `install_ci_state` answers at build time, which may be `unknown` inside brew's sandbox. That is the row's defined answer for "could not ask", not a failure.

## D5. The risk that remains: Linux-only defects

**A release can ship with a defect that only Linux shows, and step 11 then reports it after the fact.** The local gates run on the maintainer's macOS machine. CI's Ubuntu legs are the only place Linux is exercised before users see a release, and bash 3.2 and Linux-only regressions have been caught only on CI before. vc ruled on 2026-09-21 not to ask devbin to reopen D40 (_"CI does not gate the release, it reports on it"_, `cmd/release:979`): 2.10.0 was tagged at 12:58:07Z, before CI run 35512150262 existed at 12:58:44Z, and that order was already accepted. A red step 11 means fixing forward and cutting the next patch, never moving the tag. Declaring `ci.query` (D1) is what turns that report from a skipped row into a verdict.

## D6. The release window

**The core refuses to cut while any path it does not own is dirty, untracked files included** (`release_dirt`, `release.steps:355`; the tree rule at `cmd/release:550`). On this estate that is the normal state: three nodes write board views and canon event files continuously, and at the time of writing vc's three views and five untracked event files would each refuse a cut. So a Utilz release has a **window**: every node commits its own views and events by explicit path, then holds board writes until the cut reports, the same way suites are held today. The node that runs the cut says when the window opens and closes, on the board and over the socket.

**The window is stricter than a clean start, because step 5 checks the tree after the gates.** The core reads the tree before the gates and again after them, and fails the cut if any gate changed it, untracked files included (`cmd/release:705-707`). Two consequences follow:

- **The window holds every `intent` write for the whole cut, gates included.** That means `intent wb pickup` and `intent wb touch` too, not just deliberate board edits: both write board views and canon events, so a heartbeat during the gates fails the cut at step 5.
- **Every gate must leave `git status --porcelain --untracked-files=all` byte-identical.** The bats estate, cargo, acceptance.sh, theme-addressing.sh and video.sh have never been held to that. WP-01 runs each one, diffs that status before and after, and any writer it finds is fixed or ignored before Devbin's WP-08 switches the core on. The alternatives were rejected: a cut from a separate clone loses the maintainer's gates-on-this-machine property, and ignoring `intent/whiteboard/` would stop the views being committed at all.

## D7. The inputs taken as given, and what the core already does with them

| Input from 2.10.0                                | Where the core honours it                                                                                |
| ------------------------------------------------ | -------------------------------------------------------------------------------------------------------- |
| Bare tag, hv's ruling at 2.7.0                   | `tag: "{version}"`, expanded as written (`release_tag_name`, `release.steps:86`)                         |
| `--cleanup=whitespace`, never strip or verbatim  | Step 7: `git tag -a "$tag" "$commit" -F "$body_file" --cleanup=whitespace` (`cmd/release:811`)           |
| Read the annotation back, trailing ws normalised | `release_tag_reuse_note` runs both sides through `git stripspace` and compares (`release.steps:444-452`) |

**One change to the tag message.** The core's message is the CHANGELOG section's body alone (`_notes_changelog_body`, `release.notes:852`). It drops both the `<version> -- <headline>` first line that 2.9.0 and 2.10.0 carried and the `## [X.Y.Z] - date` heading. The recommendation is to take the core's form, so the fleet has one. It also means the read-back compares against that body and not against the entry with its heading, which is what the core does. **Step 7 reads back a fresh tag as well as a reused one** (`cmd/release:814-818`), so watch-out 8's read-back is the core's by construction and Utilz owes nothing further for it.

## Work packages

vc reviewed on 2026-09-21: GO with four changes, all written in above (D1's gates, D3's evidence and post-install check, D6's step-5 consequences, D7's fresh-tag read-back).

| WP  | Title                                                                | Depends on          |
| --- | -------------------------------------------------------------------- | ------------------- |
| 01  | Gates, `tools/ci-state`, the heading convention, gates leave no dirt | D1, D2, D6          |
| 02  | The keg as an install tree: the discriminator and refusing verbs     | D4                  |
| 03  | Spike: a git-URL formula built in a scratch tap, keg run end to end  | D3                  |
| 04  | The tap `matthewsinclair/homebrew-utilz` and its formula             | WP-03               |
| 05  | The formula bump after a release: `after:` or a documented step      | WP-04, Devbin WP-08 |

WP-05 is open on purpose: a release's `after:` could rewrite the formula's `tag` and `revision` and push the tap, but `after:` runs outside the core's guarantees (`cmd/release:940`), and a push to a second repository is hv's call.

## Acceptance

The ACs are minted with `intent ac new` with the work packages. The shape: the declaration, gates included, is declared with the command off and `bin/devbin doctor` reads it clean, and the core's own `release check` (read-only, run by hv or vc) is the switch-on's first act; every gate leaves `git status --porcelain --untracked-files=all` byte-identical; `tools/ci-state` answers each of the five verdicts under a stubbed `gh`; the CHANGELOG's open section reads `open` to the core; a keg installed from the tap passes `utilz doctor` after brew's post-install, manifest included, and runs every utility; `upgrade`, `relink` and `use` refuse inside a keg and name `brew upgrade`.

## Open, and not this thread's

- Enabling the core (`commands.release.enabled: true`) is Devbin's ST0007 WP-08. Its first act, before any cut, is the core's read-only `release check` against the block WP-01 declared.
