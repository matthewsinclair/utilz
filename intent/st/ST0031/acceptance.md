---
st_id: ST0031
title: Release through devbin's reshaped core: Utilz's side of Devbin ST0011/10
---

# ST0031: Release through devbin's reshaped core: Utilz's side of Devbin ST0011/10 -- Acceptance

> **THIS FILE IS A GENERATED VIEW, AND A ROW AUTHORED HERE IS DISCARDED BY THE NEXT SYNC.** The acceptance contract is canon in the thread model; this file renders it. Acceptance Criteria (AC) are the ratified completeness boundary; Acceptance Tests (AT) are the small red-to-green tests that prove them.
>
> Done = every AC is covered by a GREEN AT, or (for a non-test AC) its named evidence is satisfied, AND the AC set is the ratified full boundary. Done is read from this map, never from a hand-ticked box.
>
> Test-backed satisfaction is COMPUTED from covering green ATs and never stored -- storing it would be double truth. An AC has four states, not two: beyond satisfied and unsatisfied, a requirement can be **descoped** to a named thread or **withdrawn** with its reason on the record. Both are non-blocking and both are reported separately, so a thread that descoped half its contract looks like one.

## Acceptance Criteria

### WP-01 -- Sweep: retire Utilz's release tools into devbin's core, and follow it in config, CI, docs and tests (status: Not Started)

- AC-01.1 (non-test) The sweep's push carries the whole change, on ST0031/02's bank: tools/ci-state, tools/post-cut, tools/formula, install.sh's install_ci_state and install_ci_jobs, and the tests of each are gone; bin/.devbin/config.yaml gates the cut with `check all` then `test estate`, and its one after: command is `bin/devbin formula publish`; docs/releasing.md describes the cut in the new shape; and no tracked file outside bin/.devbin, CHANGELOG.md and intent/ names any of them. -- satisfied: no
- AC-01.2 (non-test) tests.yml fires on a push to `main` or `candidate/**`, with no `tags:` trigger, and runs its macOS jobs and the rust job's macOS leg only on a `candidate/` push or a dispatch: after the sweep a read-only `bin/devbin release check` passes in Utilz, its checker finding that the test matrix fires on `candidate/`, and CI at the sweep's push is green on every job the run starts. -- WITHDRAWN: carried by ST0031/04's AC-04.1
- AC-01.3 (non-test) Before tools/formula and tools/ci-state go, the core gives Utilz the answers they give: `tools/formula render 2.14.8` and `bin/devbin formula render 2.14.8` are identical but for the header comment, and tools/ci-state and `bin/devbin ci-state`, each given the full sha, give the same verdict word on f2021ddc (green) and 1434e764 (failed), naming the same failed jobs on 1434e764. -- satisfied: no
- AC-01.4 (non-test) Utilz's first cut in the new shape goes through the core alone: its candidate's run fires every leg and its RELEASE seal names each one, Menuz.app.zip is attached before any after: command runs, and `bin/devbin formula publish` moves homebrew-utilz to the new tag over hv's ssh. -- satisfied: no

### WP-02 -- CI tuning, banked for the sweep's push: a cargo cache, test-linux's roster derived, and a timeout on the rust job (status: Not Started)

- AC-02.1 (non-test) The rust job caches cargo's dependencies, never the workspace's own crates: `Swatinem/rust-cache` pinned to 6323deb102c322ba6fcbdcafc7e3dddab59af2b6, the commit its v2.9.2 tag names, with the version in a comment, `workspaces: opt/prez/crate -> target` and `key: ${{ matrix.os }}`. Its ubuntu leg, the only one a push to main runs, restores nothing and saves at the sweep's push, then restores at the next push that runs CI, and its compile time falls. Its macOS leg runs only on a `candidate/` push or a dispatch, and its first run restores nothing and saves; since GitHub restores a cache only from the run's own branch or the default branch, a `candidate/` run's save is invisible to the next cut's branch, and the macOS leg restores only a cache that a dispatch on main saved. -- satisfied: no
- AC-02.2 (non-test) The rust job carries `timeout-minutes: 25` (issue 0131's point 5), with the measured leg durations in its comment. -- satisfied: no
- AC-02.3 (non-test) Both test jobs run one roster, `tools/ci-suites`: `utilz test` for the dispatcher and for every utility `utilz list` names except prez, through the tree's bin/utilz, stopping at the first failure and refusing an empty list. test-linux's log at the sweep's push, and test-macos's at its first run after it, a `candidate/` push or a dispatch, each have one `== <utility> ==` line per utility. -- satisfied: no

### WP-03 -- menuz reads the release stamp, not the tag, for MenuzKind=release (status: Done)

- AC-03.1 (non-test) menuz stamps MENUZ_KIND by the rule help/menuz.md states with the stamps, which reads the release commit as Devbin ST0011 WP06's app-sign does; menuz.bats pins each answer and each exit 1. -- evidence: landed at b8e527d8; desk run 01M697M3EPJDYFVJ40S2YAD0TW, menuz.bats 1..138, 138 ok, 0 skip, 0 not ok, log sha256 9a5b7b66, judged green by utilz-vc -- satisfied: yes

### WP-04 -- 2.14.9's cut in 0.1.20's shape: tests.yml on candidate/**, post-cut publishes and pulls only (status: WIP)

- AC-04.1 (non-test) tests.yml fires on a push to `main` or `candidate/**`, with no `tags:` trigger, and runs test-macos, menuz-app and the rust job's macOS leg only on a `candidate/` push or a dispatch. A read-only `bin/devbin release check` reads the trigger with no finding, and 2.14.9's candidate run is green on every job it starts. -- satisfied: no
- AC-04.2 (non-test) tools/post-cut, the one after: line, attaches the Menuz.app the cut's macos leg signed and notarised at the release commit, through `bin/devbin macos publish` at the project root, and builds and signs nothing. It then publishes the formula and pulls this machine's tap, stopping at the first failure. 2.14.9's after row is done, its release carries Menuz.app.zip and SHA256SUMS, and homebrew-utilz names 2.14.9. -- satisfied: no

## Acceptance Tests

### WP-01 -- Sweep: retire Utilz's release tools into devbin's core, and follow it in config, CI, docs and tests (status: Not Started)

_(no tests in this group)_

### WP-02 -- CI tuning, banked for the sweep's push: a cargo cache, test-linux's roster derived, and a timeout on the rust job (status: Not Started)

_(no tests in this group)_

### WP-03 -- menuz reads the release stamp, not the tag, for MenuzKind=release (status: Done)

_(no tests in this group)_

### WP-04 -- 2.14.9's cut in 0.1.20's shape: tests.yml on candidate/**, post-cut publishes and pulls only (status: WIP)

_(no tests in this group)_

---

_Generated by Intent v3 from the thread canon. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
