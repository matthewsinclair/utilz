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

### WP-02 -- The keg as an install tree: the discriminator and the verbs that refuse (status: WIP)

- AC-02.1 A publish with --managed-by brew records managed-by brew in its manifest, and every other publish records utilz. When the tree they run from or the tree they target is a keg, utilz upgrade, relink, use and install --force refuse and name brew upgrade utilz. In a keg, utilz test's refusal names a clone of the repository, not the keg's source-tree, which is brew's deleted build directory. In a non-brew install tree, and with a manifest from before the row existed, all of them behave as before. -- satisfied: no (computed)

### WP-03 -- Spike: a git-URL formula built in a scratch tap, the keg run end to end (status: Not Started)

- AC-03.1 (non-test) A keg built from a git-URL formula in a scratch tap passes utilz doctor after brew's post-install, manifest included, and every utility runs from it. -- satisfied: no

### WP-04 -- The tap matthewsinclair/homebrew-utilz and its formula (status: Not Started)

- AC-04.1 (non-test) The formula in matthewsinclair/homebrew-utilz passes brew audit --strict and installs Utilz from its bare tag. -- satisfied: no

### WP-05 -- The formula bump after a release: after: or a documented step (status: Not Started)

- AC-05.1 (non-test) How the formula follows a release is decided by hv and either built or documented. -- satisfied: no

### Group AT01

_(no criteria in this group)_

## Acceptance Tests

### WP-01 -- Gates, tools/ci-state, the heading convention, and gates that leave no dirt (status: Done)

_(no tests in this group)_

### WP-02 -- The keg as an install tree: the discriminator and the verbs that refuse (status: WIP)

_(no tests in this group)_

### WP-03 -- Spike: a git-URL formula built in a scratch tap, the keg run end to end (status: Not Started)

_(no tests in this group)_

### WP-04 -- The tap matthewsinclair/homebrew-utilz and its formula (status: Not Started)

_(no tests in this group)_

### WP-05 -- The formula bump after a release: after: or a documented step (status: Not Started)

_(no tests in this group)_

### Group AT01

- AT01 `opt/utilz/test/install_lib.bats` -- covers AC-01.3 -- status: green -- Red first, 21 Sep: with tools/ci-state moved aside, bats --filter 'tools/ci-state' opt/utilz/test/install_lib.bats at 8b3f31b fails 5 of 5. Green, WP-01, 21 Sep: with it in place, 5 of 5 pass (bash 5.3.20, load 127.72): the five verdicts, gh's refusal as unknown, the query install_ci_state makes word for word, usage exit 2, and nothing under tools/ in install_owned_paths. Under /bin/bash 3.2.57 with no gh on PATH it answers 'unknown<TAB>gh is not installed'. CI's shellcheck collector, widened to bin opt tools, sees 19 files including tools/ci-state, and all are clean.

---

_Generated by Intent v3.1.0 from the thread canon. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
