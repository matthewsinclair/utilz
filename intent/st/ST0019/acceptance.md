---
st_id: ST0019
title: Release Utilz through dvb build release and a Homebrew tap, like Intent
---

# ST0019: Release Utilz through dvb build release and a Homebrew tap, like Intent -- Acceptance

> **THIS FILE IS A GENERATED VIEW, AND A ROW AUTHORED HERE IS DISCARDED BY THE NEXT SYNC.** The acceptance contract is canon in the thread model; this file renders it. Acceptance Criteria (AC) are the ratified completeness boundary; Acceptance Tests (AT) are the small red-to-green tests that prove them.
>
> Done = every AC is covered by a GREEN AT, or (for a non-test AC) its named evidence is satisfied, AND the AC set is the ratified full boundary. Done is read from this map, never from a hand-ticked box.
>
> Test-backed satisfaction is COMPUTED from covering green ATs and never stored -- storing it would be double truth. An AC has four states, not two: beyond satisfied and unsatisfied, a requirement can be **descoped** to a named thread or **withdrawn** with its reason on the record. Both are non-blocking and both are reported separately, so a thread that descoped half its contract looks like one.

## Acceptance Criteria

### WP-01 -- Gates, tools/ci-state, the heading convention, and gates that leave no dirt (status: Done)

- AC-01.1 (non-test) The release: block from design D1, its estate gate included, is declared in bin/.devbin/config.yaml with the command still off, and bin/devbin doctor, whose cfg_validate reads the block, reports the config clean. The core's read-only release check is run by hv or vc as the first act of the switch-on (Devbin ST0007 WP-08), before any cut. -- evidence: vc, 21 Sep, in vc's detached worktree at 45c3830: bin/.devbin/config.yaml carries design D1's release: block (tag "{version}", repo matthewsinclair/utilz, gates check all + test estate, ci.query tools/ci-state) with commands.release off; bin/devbin doctor reads '11 checks, 0 failed, 4 notes' and notes the block 'declared and inert'. Mutation: tag swapped to "release" makes doctor refuse, naming release.tag ('must contain {version}'), so the pass comes from reading the block. The read-only release check is the switch-on's first act. -- satisfied: yes
- AC-01.2 Every declared gate, bin/utilz test first, leaves git status --porcelain --untracked-files=all byte-identical, measured by hashing every dirty path before and after it. -- WITHDRAWN: Minted test-backed, but its proof is a one-off measurement in a release window, not a repeatable test, and the contract refuses a non-test AT on a test-backed AC. Replaced by AC-01.5, the same criterion as non-test, satisfied by the window's evidence.
- AC-01.3 tools/ci-state answers green, failed, pending, none and unknown for the corresponding install_ci_state answers under a stubbed gh, asks through install_ci_state alone, ships to no install or keg, and is linted by CI's shellcheck step. -- satisfied: yes (computed)
- AC-01.4 (non-test) CHANGELOG.md's open section is headed ## [2.11.0] - unreleased, the version hv ruled on 2026-09-21, and the core's heading reader (release.notes) reads its state as open. -- evidence: 0a63d4b: CHANGELOG.md line 10 reads '## [2.11.0] - unreleased'; release.notes _notes_changelog_state answers 2.11.0 open, 2.10.0 dated 2026-09-20, 2.12.0 absent -- satisfied: yes
- AC-01.5 (non-test) Every declared gate, bin/utilz test first, leaves git status --porcelain --untracked-files=all byte-identical, measured by hashing every dirty path before and after it, in a release window with every node holding its intent writes. -- evidence: Window 21 Sep, HEAD ba1b4bd, vc holding from 61adcc9, accepted by vc at close. bin/devbin check all 07:52:08-07:52:11Z rc 0; bin/devbin test estate 07:52:12-08:03:13Z rc 0, 20 of 20 suites, sealed ESTATE.errors 0 bytes; load 449.54 to 547.69. Porcelain 0 lines before and after each gate (hash da39a3ee5e6b), HEAD unmoved, no per-path hash changed; no writer found. -- satisfied: yes

### WP-02 -- The keg as an install tree: the discriminator and the verbs that refuse (status: Done)

- AC-02.1 A publish with --managed-by brew records managed-by brew in its manifest, and every other publish records utilz. When the tree they run from or the tree they target is a keg, utilz upgrade, relink, use and install --force refuse and name brew upgrade utilz. In a keg, utilz test's refusal names a clone of the repository, not the keg's source-tree, which is brew's deleted build directory. In a non-brew install tree, and with a manifest from before the row existed, all of them behave as before. -- satisfied: yes (computed)

### WP-03 -- Spike: a git-URL formula built in a scratch tap, the keg run end to end (status: Done)

- AC-03.1 (non-test) A keg built from a git-URL formula in a scratch tap, keg_only and from this repository at a named revision, passes utilz doctor after brew's post-install, manifest included and still recording managed-by brew. Every dispatcher link in it answers --version, and upgrade, relink and use refuse from it, naming brew upgrade utilz. The keg and the tap are removed afterwards. -- evidence: WP-03 body, spike of 2026-09-21 at 274e64f: keg /opt/homebrew/Cellar/utilz/2.11.0-spike built keg_only from a scratch tap; doctor inside it passed every check including 'Install matches its manifest', with managed-by brew in the header; all 16 links answered --version rc 0; upgrade, install --force, relink, use opt and use dev each refused rc 1 naming brew upgrade utilz; uninstall and untap left no Cellar, opt link, tap or bin link, and the spike's utilz--git cache was removed. -- satisfied: yes

### WP-04 -- The tap matthewsinclair/homebrew-utilz and its formula (status: Done)

- AC-04.1 (non-test) packaging/homebrew/utilz.rb and an MIT LICENSE are in this repository, the README's license section says MIT, and the formula passes brew audit --strict in a scratch tap, removed afterwards. -- evidence: 1ecdd3a: packaging/homebrew/utilz.rb, MIT LICENSE, README license section MIT. WP-04 body: brew audit --strict in a throwaway tap exits 0 with no findings on the committed formula and on a real-commit copy; a bad-desc control exits 1 naming both faults, so the pass is a reading; tap untapped, live install manifest and ~/.local/bin listing hash identical before and after. -- satisfied: yes
- AC-04.2 (non-test) Once hv has created and pushed matthewsinclair/homebrew-utilz and 2.11.0 is tagged, brew install matthewsinclair/utilz/utilz installs Utilz from the bare tag, and utilz doctor passes in the keg, manifest included. -- WITHDRAWN: It can only be satisfied after the 2.11.0 cut, when hv creates and pushes the tap with the tag's real commit (vc decision 9), and vc ruled that WP-04 closes on AC-04.1. Moved to WP-05, which is how the formula follows a release, as AC-05.2.

### WP-05 -- The formula bump after a release: after: or a documented step (status: WIP)

- AC-05.1 (non-test) docs/releasing.md documents the step hv runs after each cut: tools/formula-bump <tag>, the formula copied into matthewsinclair/homebrew-utilz, brew audit --strict, and the tap committed and pushed by hv, with no after: hook (hv, 2026-09-21, vc decision 10). -- evidence: docs/releasing.md: after each cut hv runs tools/formula-bump <tag>, commits the bump by path, copies the formula into matthewsinclair/homebrew-utilz, runs brew audit --strict from the tap, and commits and pushes the tap; no after: hook. Linked from docs/index.md. -- satisfied: yes
- AC-05.2 (non-test) Once hv has created and pushed matthewsinclair/homebrew-utilz at the 2.11.0 cut, with the tag's real commit in the formula, brew install matthewsinclair/utilz/utilz installs Utilz from the bare tag, and utilz doctor passes in the keg, manifest included. -- satisfied: no
- AC-05.3 tools/formula-bump <tag> refuses a missing tag, a lightweight tag, a wrong argument count, and a formula without exactly one tag: and one revision: line, changing nothing in each case. For an annotated tag it rewrites exactly those two lines, to the tag and git rev-parse <tag>^{commit}, and prints the diff. -- satisfied: yes (computed)

### Group AT01

_(no criteria in this group)_

### Group AT03

_(no criteria in this group)_

### Group AT04

_(no criteria in this group)_

## Acceptance Tests

### WP-01 -- Gates, tools/ci-state, the heading convention, and gates that leave no dirt (status: Done)

_(no tests in this group)_

### WP-02 -- The keg as an install tree: the discriminator and the verbs that refuse (status: Done)

_(no tests in this group)_

### WP-03 -- Spike: a git-URL formula built in a scratch tap, the keg run end to end (status: Done)

_(no tests in this group)_

### WP-04 -- The tap matthewsinclair/homebrew-utilz and its formula (status: Done)

_(no tests in this group)_

### WP-05 -- The formula bump after a release: after: or a documented step (status: WIP)

_(no tests in this group)_

### Group AT01

- AT01 `opt/utilz/test/install_lib.bats` -- covers AC-01.3 -- status: green -- Red first, 21 Sep: with tools/ci-state moved aside, bats --filter 'tools/ci-state' opt/utilz/test/install_lib.bats at 8b3f31b fails 5 of 5. Green, WP-01, 21 Sep: with it in place, 5 of 5 pass (bash 5.3.20, load 127.72): the five verdicts, gh's refusal as unknown, the query install_ci_state makes word for word, usage exit 2, and nothing under tools/ in install_owned_paths. Under /bin/bash 3.2.57 with no gh on PATH it answers 'unknown<TAB>gh is not installed'. CI's shellcheck collector, widened to bin opt tools, sees 19 files including tools/ci-state, and all are clean.

### Group AT03

- AT03 `opt/utilz/test/keg.bats` -- covers AC-02.1 -- status: green -- Red first, 21 Sep: with opt/utilz/lib/install.sh and common.sh at 499ccc9, bats opt/utilz/test/keg.bats fails 8 of 8, because install refuses --managed-by and nothing reads the row. Green, WP-02, 21 Sep: 8 of 8 pass at load 24.95: brew and utilz rows as published, a manifest without the row reads utilz and upgrade then writes it, an unknown manager word refused with exit 2, upgrade and install --force refused onto a keg with its manifest byte-identical, upgrade from a keg naming brew rather than the missing git, relink refused into and from a keg with no link moved, use opt and use dev refused when install.prefix is a keg, and utilz test in a keg naming a git clone and not the source-tree. bats opt/utilz/test: 248 tests, 0 failed, 2 skipped (yq and bats installed, as before).

### Group AT04

- AT04 `opt/utilz/test/formula_bump.bats` -- covers AC-05.3 -- status: green -- Red first, 21 Sep: at c36a773, with no tools/formula-bump, bats opt/utilz/test/formula_bump.bats fails 5 of 5. Green, WP-05, 21 Sep: 5 of 5 pass. An annotated tag rewrites exactly the tag: and revision: lines to 9.9.9 and git rev-parse 9.9.9^{commit}, keeps the formula's mode, and prints the diff. A missing tag, a lightweight tag, a formula with two revision: lines, and one with no tag: line are each refused with the formula byte-identical. Zero or two arguments exit 2. CI's shellcheck collector sees 20 files, tools/formula-bump among them, and all are clean.

---

_Generated by Intent v3.2.0 from the thread canon. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
