---
wp_id: WP-01
title: Sweep: retire Utilz's release tools into devbin's core, and follow it in config, CI, docs and tests
scope: M
status: Done
---

# WP-01: Sweep: retire Utilz's release tools into devbin's core, and follow it in config, CI, docs and tests

## Objective

At Devbin 0.1.19's vendor sweep, Utilz hands its release tools to devbin's core and follows the core in config, CI, docs and tests: tools/ci-state, tools/post-cut, tools/formula and install.sh's own CI reader retire; `utilz install` reads CI once through the core's `ci-state`, inside its own deadline; the cut's one after: command, `bin/devbin formula publish`, publishes the formula after push and attach; and tests.yml runs its macOS jobs on a `candidate/` branch push or a dispatch, no longer on a tag. It is built on ST0031/02's bank and lands whole in the sweep's push.

# ST0031/01, re-planned at Utilz fa8d1eb4 and Devbin 0.1.28

Re-read on 23 Nov 2026 on vc's word, as design only: no run and no booking. It replaces the reading of 31 Oct at Utilz 97cab1bc and Devbin 0332d1a4, whose tags ([WP02] to [WP09]) have all landed. Utilz swept the core to 0.1.19 (fc8cd495) and 0.1.20 (7a6a06a7), then through 0.1.22 (a96b960a) to 0.1.28 (a521a573), and ST0031/03 (b8e527d8) and ST0031/04 (195b1c91) are done. The 31 Oct body is in git. Every cite below is at fa8d1eb4.

## 1. What has moved since 31 Oct, with nothing left to do

- **The ci: block is gone** (fc8cd495). The core reads CI through its own default `ci.query`, `bin/devbin ci-state` (core config:617). It refuses a declared ci.tag or ci.base as retired (config:1851-1852).
- **The candidate trigger is in** (195b1c91).
  - tests.yml fires on `candidate/**` (:5) and has no tags: line.
  - Its four macOS conditions read the candidate branch (:118, :288, :537, :601).
  - The core's `ci-state --fires` reads that trigger for the pre-flight refusal (release:3236-3264) and for `release check` (:479-536). AC-04.1 is satisfied.
- **The core attaches the app** (issue 0329, from 0.1.22).
  - Under object: local, with macos.app declared, the cut's object step zips Menuz.app.zip and attaches it through `macos publish` (release:4137-4165).
  - It runs before the formula step and the after: commands. A failed attach ends the cut through cut_fail before either runs (:4159, :4163).
  - post-cut's own attach (:98-114) skips when both assets are already there, so in a cut at 0.1.28 it does nothing.
- **Issue 0062's note is kept** (31 Oct ruling 2). A failed verdict's detail names the failed jobs, or says no job ran (ci-state:334-353, :391-403).
- **build_kind needs no change** (watch-out 3's re-read).
  - menuz's rule (menuz:628-660) is the core's release_commit, as require_release_head applies it (macos:1043-1080). Before the tag, a clean HEAD is the release commit. After it, HEAD must be the tag's commit, in a clean tree.
  - menuz judges clean by its source stamp and the core by the whole tree, as ST0031/03 chose.
  - So nothing here touches build_kind, and hv need give no fresh go.

## 2. What 0.1.28 changes in the plan: the formula cannot retire yet

- **The core's render refuses Utilz's template.**
  - In source mode, the template's `def install` must hold exactly one `@@INSTALL@@`, with nothing but blank and comment lines before it (install_refusal, formula:557-576, called at :372-373).
  - The core generates the install body: `system "bin/devbin", "install", "--prefix", libexec, "--managed-by", "brew"`, then the links (publish_ruby, formula:451-453).
  - packaging/homebrew/utilz.rb runs Utilz's own publish instead (:31): `system "bin/utilz", "install", "--prefix", libexec, "--managed-by", "brew"`. That publish builds prez and showreel, copies the runtime set and writes the manifest.
  - At 0.1.20, render had no such check. 31 Oct's "its Ruby is unchanged" and probe (a) rested on that. This finding is from the code; it was not run.
- **Taking the core's install is issue I59c806c** (devbin#0326's install and use). It is devbin-cc's, and hv decision 9 (4) sequences it after ST0031/01 lands.
- **A plain after: `bin/devbin formula publish` would not pull the tap clone.**
  - publish pulls only with `--pull` (formula:12-16, :837-861).
  - The cut's own formula step passes `--pull`, under the cut's one yes (release:3952-3983). It runs only when `release.formula` is true, and the default is false.
- **The choice, put to hv through vc. hv chose (A) on 23 Nov 2026 ("ok, go", hv decision 14, which amends decision 9 (1)):**
  - **(A), taken:** ST0031/01 retires what the core takes while Utilz still installs as it does today: the CI readers and post-cut.
    - The formula stays Utilz's until I59c806c. This release's cut runs it through one after: line, `tools/formula publish --pull`.
    - I59c806c then moves the template to `@@INSTALL@@`, sets `release.formula: true`, enables the formula command, drops the after: line, and retires tools/formula and formula.bats. It carries AC-01.3's formula half.
  - **(B), not taken:** fold I59c806c into this release, so the formula retires now. It is larger, it is devbin-cc's, and it changes how brew installs Utilz.

## 3. The change, under (A)

**tools/ci-state** (51 lines) retires.

- Nothing in the release path has called it since fc8cd495.
- Its five AT01 tests go (install_lib.bats:766-834; ST0019's AT01 on AC-01.3).

**install.sh's install_ci_state (:621-729) and install_ci_jobs (:567-619)** retire, with INSTALL_GH and INSTALL_CI_WORKFLOW (:476-477).

- **The call:** the publish (:916) reads CI through the core once, `"$src/bin/devbin" ci-state "$commit"`.
  - It runs inside install's own install_run_bounded and INSTALL_CI_DEADLINE (:478), since the core's ci-state sets no deadline of its own (ci-state:78-80).
  - ci-state is a core command on every project (builtins: `any`), so nothing has to be enabled for it.
- **What the manifest records:** the core's word and detail, eg `green` and `run 105`.
  - A call that fails, exits non-zero, outlives the deadline or prints no verdict line records `unknown` with its reason.
  - No answer refuses the publish (:912-914).
  - brew's build has no gh, so brew's manifest reads `unknown` with "gh is not installed" before and after (ci-state:1100-1102).
- **Tests:**
  - AT08's eight tests of the two functions go (install_lib.bats:382-534).
  - The seam tests at :349-380 stub `$src/bin/devbin` where they now stub gh (:312-339). They cover four cases: a verdict line, a non-zero exit, no verdict line, and one past INSTALL_CI_DEADLINE. Each asserts the sha asked about and what the manifest records.
  - The seeds at install_guards.bats:355 (asserted at :357) and install_lib.bats:548 take the core's word.

**tools/post-cut** (138 lines) retires, and the after: line becomes `- tools/formula publish --pull`.

- **Its duties:**
  - Its attach is the core's now (section 1).
  - Its formula publish is tools/formula's already.
  - Its fast-forward pull of this machine's tap clone (:125-137) moves into tools/formula, behind `--pull`, the core's own flag. I59c806c's swap is then a line of config.
- **vc decision 91's six findings:**
  - Four go with post-cut: the copy of the newest-tag check (:83-88), tag_commit's copy (:80-82), cat-file's discarded stderr (:80), and the ASSET literal (:42).
  - git log's status lost inside say (:135) sits in the pull, and is fixed as the pull moves.
  - The third copy of die() (post-cut:45-48) goes with post-cut. The other two copies remain: tools/formula's (:43-46), which retires at I59c806c, and tools/app-icons' (:32-35), which stays. This change does not touch them.
- **Issue Ie8e55e8 rides this change (XS, vc's word).** opt/menuz/menuz:915 and :917 also hard-code Menuz.app.zip, where the core derives the name from config (cfg_macos_app_asset). The fix gives the name one home, `MENUZ_ASSET` in opt/menuz/lib/launch-services.sh, and a macos.bats arm holds it equal to the core's derivation, as issue 0106's arm does for the bundle id.

**bin/.devbin/config.yaml:**

- **after:** becomes `- tools/formula publish --pull`. The comment at :128-142 is rewritten to the shape at 0.1.28: the object step attaches the app, and no formula: key is set until I59c806c, with the reason.
- **gates:** unchanged, `check all` alone, by hv's ruling of 28 Oct (ST0030), with the dry run and the twins running test estate before a cut (config.yaml:131-133). AC-01.1's "then test estate" came from 31 Oct's design, with no ruling behind it, so it is reworded (vc, 23 Nov).

**Docs and comments:**

- docs/releasing.md is rewritten to the cut at 0.1.28. It is stale at :16, :17 and :24, in the step table at :26-38 (post-cut at :37, and a ci step through tools/ci-state at :38), at :90-95 and at :103.
- tests.yml's comment at :243-247 names post-cut, and is reworded.
- install.sh's comments at :199-200, :493 and :550 name the core's call instead.
- tools/test-estate:27-28 gives its own reason alone.
- docs/index.md:38 and the template's header keep naming tools/formula until I59c806c.

## 4. Tests and the run

- **formula.bats** gains arms for `--pull`: the clone pulled after a publish, nothing pulled when the publish fails, and a failed pull named.
- **Probe (b) for AC-01.3**, before tools/ci-state goes. tools/ci-state and `bin/devbin ci-state` are each given the full sha, on f2021ddc (green) and 1434e764 (failed). Each must give the same verdict word, and on 1434e764 name the same failed jobs. It asks GitHub through gh, so it is booked.
- **opt/menuz/test/macos.bats** gains Ie8e55e8's arm: MENUZ_ASSET equals cfg_macos_app_asset.
- **The run:** install_lib.bats, install_guards.bats, formula.bats and macos.bats, booked at the Desk with probe (b).
- **The rest:** CI at the push proves /02 and the triggers, and the release's cut proves AC-01.4.

## 5. The criteria, changed on vc's check

- **AC-01.1, reworded.** It requires all of the following:
  - tools/ci-state, tools/post-cut, install.sh's install_ci_state and install_ci_jobs, and their tests are gone;
  - the after: line is `tools/formula publish --pull`;
  - the gates are `check all` alone, as hv ruled on 28 Oct;
  - issue Ie8e55e8 is fixed: menuz names the release asset from one home, held equal to the core's derivation;
  - docs/releasing.md describes the cut at 0.1.28;
  - no tracked file outside bin/.devbin, CHANGELOG.md and intent/ names tools/ci-state, tools/post-cut, install_ci_state or install_ci_jobs.
- **AC-01.3** keeps its ci-state half. Its formula half, the render compared against the core's, moves to I59c806c's acceptance, where the template changes.
- **AC-01.4, reworded.** It requires the first cut in this shape to do all of the following:
  - fire every leg on its candidate's run;
  - name each leg in its RELEASE seal;
  - attach Menuz.app.zip in the object step before any after: command runs;
  - move homebrew-utilz to the new tag through `tools/formula publish --pull`, and pull this machine's clone.
  - "Through the core alone" moves to I59c806c.
- **ST0019's AC-01.3** is still descoped to ST0031 at the build, for the reading of CI (31 Oct section 4, step 3).

## 6. Order

1. hv chose (A) (decision 14).
2. This body and the criteria are recorded on vc's YOUR TURN, before any source edit, and dc claims ST0031/01 and Ie8e55e8.
3. The code is built in a worktree off main, on /02's bank, which applies there at an offset of 3 lines.
4. One booked run: the four suites and probe (b).
5. /01 and /02 land together on vc's word, and hv's push proves /02 on CI.
6. The release's cut, hv's, proves AC-01.4.
7. I59c806c then takes the formula to the core.

## Acceptance

Acceptance Criteria for this work package are RENDERED into `ST0031/acceptance.md`, under the `WP-01` heading. THAT FILE IS A GENERATED VIEW -- a row authored there is discarded by the next sync. The contract is canon in the thread's model, and the verbs write it: `intent ac new` and `intent at new` mint a row, `intent ac edit` and `intent at edit` reword or re-cite one, and `intent ac satisfy|unsatisfy|descope|rescope|withdraw|reinstate` and `intent at green|red|na` move its state. This cover never restates them.

---

_Generated by Intent v3 from the thread canon. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
