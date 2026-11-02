---
wp_id: WP-01
title: Sweep: retire Utilz's release tools into devbin's core, and follow it in config, CI, docs and tests
scope: M
status: Not Started
---

# WP-01: Sweep: retire Utilz's release tools into devbin's core, and follow it in config, CI, docs and tests

## Objective

At Devbin 0.1.19's vendor sweep, Utilz hands its release tools to devbin's core and follows the core in config, CI, docs and tests: tools/ci-state, tools/post-cut, tools/formula and install.sh's own CI reader retire; `utilz install` reads CI once through the core's `ci-state`, inside its own deadline; the cut's one after: command, `bin/devbin formula publish`, publishes the formula after push and attach; and tests.yml runs its macOS jobs on a `candidate/` branch push or a dispatch, no longer on a tag. It is built on ST0031/02's bank and lands whole in the sweep's push.

Read at Utilz 97cab1bc and Devbin 0332d1a4: ST0011's design.md sections 7, 8, 11 and 12, the WP-09 and WP-10 objectives, and the core's `ci-state` and `formula`, both as Devbin holds them and as they are vendored here. utilz-vc checked it on 31 Oct, and its rulings and devbin-vc's answers are in section 5. Each point that hangs on Devbin work still in flight carries a tag. All of that work lands in 0.1.19 before WP09 is cut (devbin decision 93), so a tag names the unit a point is read against at the sweep:

- [WP02] is the cut's new order, the one loop, tag on green, publish folded in and the ci keys retired. It also carries WP03's two call lines (WP02b), and a failed step ending the cut with a red RELEASE seal naming it (WP02c).
- [WP03] is WP03's reopened remainder: the trigger reader and the pre-flight's refusal, and a failed detail that names the failed jobs or says that none ran.
- [run 3] is WP05 and WP06, the remote legs and the macOS stage at the release commit.
- [WP07] is attach reading the candidate run, and [WP08] is the formula under the yes, with the tap pull.
- [WP09] is Devbin 0.1.19, cut once WP01 to WP08, WP17 (D69) and WP03's remainder have landed, and its vendor sweep into Utilz: `bin/devbin upgrade`, committed by vc with the sweep pathspec, dropping `ci.tag`, `ci.base` and `ci.query`.

No source edit is made before the sweep has landed (devbin-vc's word).

## 1. What retires, what calls it now, and what calls the core instead

**tools/ci-state** (51 lines), Utilz's `ci.query`, which maps `install_ci_state`'s words to the core's five.

- **Called by** the config's `ci.query` (config.yaml:145, with its comment at :136). It is also named in docs/releasing.md:38, in the comments at tests.yml:241 and install.sh:550, and by its five tests at install_lib.bats:766-835. Those tests are ST0019's AT01 on AC-01.3.
- **Replaced by** the core's `bin/devbin ci-state`, as the default `ci.query` [WP02] once the sweep drops the key [WP09].
- **Hangs on [WP02]:** whether Utilz still needs a `ci:` block at all. An undeclared `ci:` today means "CI is not consulted", and [WP02] decides how the candidate leg reads an absent one. Devbin's own config declares `query: bin/devbin ci-state` and `summary: Test Summary`. Utilz adds `summary: Test Summary` only if [WP02] needs it, since its Test Summary job needs every job and so agrees with the run's own conclusion.

**install_ci_state and install_ci_jobs** (install.sh:476-478 for `INSTALL_GH`, `INSTALL_CI_WORKFLOW` and `INSTALL_CI_DEADLINE`; :567 and :621), a second CI reader.

- **Called by** `utilz install` at install.sh:916, which writes the manifest's `ci_state` and `ci_detail`. `utilz doctor` prints those words as recorded (common.sh:2030). tools/ci-state:42 also calls it.
- **Replaced by** `"$src/bin/devbin" ci-state "$commit"`, read once. bin/devbin is tracked in the source tree a publish runs from, and is kept out of the published runtime.
  - The call runs inside install's own `install_run_bounded` and `INSTALL_CI_DEADLINE`, because the core's `release_gh` sets no deadline.
  - The manifest then records the core's words and detail, eg `green` and `run 105`.
  - A call that fails, exits non-zero or prints no verdict line records `unknown` with its reason, and no answer refuses the publish (install.sh:911-913).
  - The formula's install runs `bin/utilz install` in brew's checkout of the tag (utilz.rb's `def install`), so the call runs inside brew's build. That build has no gh, so 2.14.8's keg records `ci_state: unknown` with `ci_detail: gh is not installed` (its manifest.sha256). Brew's manifest reads `unknown` before the change and after it.
  - With no tag set, the core reads back past coordination-only commits (cistate_walk). A publish from a board commit then records its code commit's verdict, where it records `none` today.
  - The core reads that walk off the workflow's push `paths-ignore` only when it is a block list of `<dir>/**` entries (lib/cmd/ci-state:276-281). Utilz's two entries already have that shape.
- **Kept:** issue 0062's note on a run that did not pass, which says which jobs failed, or that no job ran. At Devbin 0332d1a4 the core's failed detail names only the run and the summary's conclusion. In 0.1.19 it names the failed jobs, or says that none ran [WP03]. So the note survives in the manifest and mid-cut alike, and Utilz accepts no loss and keeps no reader of its own (section 5, 2).

**tools/post-cut** (124 lines), the release's one `after:` line.

- **Called by** config.yaml:143, with its comment at :134. It is also named in docs/releasing.md:37, :70, :99 and :103.
- **Replaced by** the core, duty by duty:
  1. The macOS app steps, which today run in a worktree at the tag. They become the core's macos leg at the release commit R [run 3], and its attach after the object [WP02, WP07].
  2. `tools/formula publish` becomes `after: - bin/devbin formula publish` [WP08].
  3. Its pull of this machine's tap clone (ST0030) moves into the built-in formula publish [WP08].
- **Kept:** the reason post-cut is one line. No formula may reach the tap before Menuz.app.zip is attached. The core keeps it. After the tag it pushes, attaches, then runs the after: commands, the formula publish among them. A failed attach ends the cut with a red RELEASE seal naming it before any after: command runs (D58, D61; issue 0297's close, in WP02c) [WP02, WP07]. devbin-vc has asked cc for WP02c's test that proves it.
- **Blocks the first cut:** menuz:632 gives MenuzKind=release only to a build of the tag, but the macos leg stages at R before any tag exists [run 3]. So ST0031/03 (ic's lane, owner hv's to name) lands before the first cut in the new shape, or the leg's kind check refuses.

**tools/formula** (187 lines) and **formula.bats** (178 lines; no AT cites it).

- **Called by** tools/post-cut:104, docs/index.md:38, docs/releasing.md:90-129 and the template's header at packaging/homebrew/utilz.rb:1-6.
- **Replaced by** `bin/devbin formula render|publish`, already vendored at bin/.devbin/lib/cmd/formula, in source mode. It keeps:
  - the template, packaging/homebrew/utilz.rb, whose one `@@TAG@@` and one `@@REVISION@@` the core fills;
  - the tap, homebrew-utilz under matthewsinclair;
  - the newest-release rule, under `release.tag: "{version}"`;
  - the refusals: a lightweight tag, and a template change no commit holds;
  - a tap that already carries the release left as it is.
- **Differs in two ways:**
  - It asks a person before it pushes, which [WP08] puts under the cut's one yes.
  - Its default tap URL is over ssh where tools/formula's is https. The push then goes over hv's ssh, as Devbin's own tap's does. This needs checking at the first publish.
- **Changes:** the template's header comment names `bin/devbin formula` in place of tools/formula. Its Ruby is unchanged.

## 2. What changes in place

**bin/.devbin/config.yaml:**

- `release.gates` becomes `check all`, then `test estate` (Q9, D57). They run in order under one GATES seal (WP01, landed). "In parallel" means the local leg runs beside the candidate and macos legs in the one loop [WP02]. Booking is outside the core (section 11), so whoever runs the cut books a heavy slot first.
- `after:` becomes `- bin/devbin formula publish` [WP08]. In 0.1.19 the formula publish stays an after: command, run after push and attach (D58), so the tap is published once.
- `macos:` stays as it is.
- The comment at :127-136 is rewritten. In the estate option's comment, :50-54 says the macOS legs run "on tags", and that is reworded.
- The `ci:` lines are as the sweep leaves them [WP09, WP02].

**.github/workflows/tests.yml:**

- `push` gains `'candidate/**'` beside `main`, and the `tags:` line (:10) and its comment (:5-9) go.
- The paths-ignore comment (:11-13) is rewritten. A candidate is a branch push, where path filters are evaluated, unlike a tag push. R's own change to VERSION and CHANGELOG.md [WP02's stamp] is outside both ignored trees, so the filter does not skip it. The first candidate's run is the proof [WP09].
- The macOS condition at :115, :285, :534 and :598 changes in each place from `github.ref_type == 'tag'` to `startsWith(github.ref, 'refs/heads/candidate/')`, beside `workflow_dispatch`. Its comments at :113 and :623 follow.
- :241's comment drops its tools/ci-state example.
- The four copies of the condition stay four. Collapsing them is not this change.
- WP03 is reopened for its checker, which refuses a test workflow whose matrix does not fire on `candidate/` and was absent at Devbin 0332d1a4. The trigger reader and the pre-flight's refusal are devbin-dc's, after run 3 [WP03]. The two call lines, in `release check` and the pre-flight, are cc's, in WP02b [WP02]. All of it lands in 0.1.19, so a read-only `release check` after the sweep proves this file before the first candidate's run [WP09].
- ST0031/02's bank edits the same file: the cache step, `timeout-minutes` and tools/ci-suites in both test jobs. /01 is built on top of /02's bank, and both land in the sweep's push.

**Docs:**

- docs/releasing.md is rewritten to the new shape: the cut's order as section 11 gives it, the two gates, the legs, and the formula under the yes. It records that a failed formula publish is the after step's FAILED row and the release stands, and that `bin/devbin formula publish` is then run again by hand.
- docs/index.md:38 names `bin/devbin formula`.

**Comments that name what retires:**

- install.sh:199-200, `install_manifest_write`'s header, says "the form install_ci_state gives". It names the core's `ci-state` line instead.
- install.sh:493, `install_run_bounded`'s watchdog comment, names `install_ci_state` as the caller read through `$(...)`. It names the bounded call to the core instead.
- install.sh:550's comment drops tools/ci-state.
- tools/test-estate:27-28 gives "the same reason ci-state does" for living in tools/. It gives the reason alone.

## 3. Tests

- **formula.bats** goes with tools/formula. The core's own suite covers its formula.
- **install_lib.bats:766-835**, the five tools/ci-state tests, go with it. They are the only "AT01" in the file, so ST0019's AT01 on AC-01.3 is left with no test to cite. Section 4's step 3 moves the criterion.
- **ST0014's AT08** on AC07 loses the eight tests of `install_ci_state` and `install_ci_jobs` at install_lib.bats:382-534, since what they test moves into the core.
  - The tests at :349-380 and one bound test cover Utilz's seam, not the core. They stub `$src/bin/devbin` in make_fake_src's tree, in four cases: a verdict line, a non-zero exit, no verdict line, and one that outlives `INSTALL_CI_DEADLINE`. Each asserts the sha the stub was asked about and what the manifest records, eg `green run 105` from `ci_state_row`.
  - A gh stub under the real core would encode the core's own gh queries (`run list` and `run view` with their JSON fields), which are the core's to change. It would also need the vendored core and its config in the fixture. The core's own suite covers its gh reading.
  - AT08's literal id stays in the file through its manifest tests (:247-366, :536).
- **install_guards.bats:355 and install_lib.bats:548** both seed `ci_state: success`, and both seed the core's word instead, alike. doctor prints what is recorded, and the verifier reads the line as header whatever its value, so both changes are cosmetic.
- **Two light probes** run after the sweep, before tools/formula, formula.bats and tools/ci-state go, booked with the run below. With Utilz's own tests deleted, they are the only proof that the core serves Utilz unchanged.
  - (a) `tools/formula render 2.14.8` against `bin/devbin formula render 2.14.8`, diffed: identical but for the header comment.
  - (b) tools/ci-state against `bin/devbin ci-state` on f2021ddc (green) and 1434e764 (failed), each given the full sha, as the core requires: the same verdict word from each, and on 1434e764 the same failed jobs named by each [WP03].
- **The run:** the smallest one that proves the change is install_lib.bats and install_guards.bats, booked at the desk once the sweep has landed. CI at the sweep's push proves the triggers, and the first cut in the new shape proves the rest: the candidate's run fires every leg, and the RELEASE seal names each one.

## 4. Order

1. The design is stored on vc's YOUR TURN, as ST0031/01's body, before any source edit.
2. After [WP09], the two probes run first, while tools/formula and tools/ci-state are still there to compare against.
3. Then `intent ac descope ST0019 AC-01.3 --to ST0031`, with the criterion reworded on ST0031. ST0019 is Completed, so first check that the verb accepts a closed thread, and take any refusal to vc. A test on ST0031 covers the reworded criterion: the seam tests for the call, and a check that no Utilz file outside bin/.devbin asks gh about runs.
4. It is built on /02's bank and lands whole in the sweep's push: everything section 1 retires goes at once.
5. ST0031/03 lands before the first cut in the new shape.

## 5. Rulings (utilz-vc, 31 Oct)

1. **The dispatch trigger:** `workflow_dispatch` stays, so a hand proof between releases can still run the macOS legs. The 0130 and 0131 proof waiting on hv is itself a dispatch.
2. **Issue 0062's job note:** (b), and devbin-vc has answered it. The core's `ci-state`, the one reader, names the failed jobs or says that none ran, in WP03's reopened remainder in 0.1.19. Utilz accepts no loss and keeps no reader of its own.
3. **ST0019's AC-01.3:** descoped to ST0031 at the build and reworded there. It becomes a criterion that Utilz's `ci.query` and `utilz install` read CI through the core's `ci-state`, and that no Utilz file asks gh about runs. The verb's acceptance of a closed thread is checked first (section 4).
4. **The deadline:** install keeps its own bound around the core's call.
5. **devbin-vc's answers (31 Oct, through vc):**
   - **No split.** 0.1.19 carries WP01 to WP08, WP17 (D69) and WP03's reopened remainder, and devbin decision 93 cuts WP09 only once those have landed. So tools/post-cut, tools/formula and the `after:` line retire at the sweep, and both probes run there.
   - **The note is kept.** The core's failed detail names the failed jobs, or says that none ran, in WP03's reopened remainder (ruling 2).
   - **A failed attach stops the cut.** A step that fails ends it with a red RELEASE seal naming the step (issue 0297's close, in WP02c), so no after: command runs, the formula publish included (D58, D61). devbin-vc has asked cc for WP02c's test that proves it.
   - **WP03 is reopened.** The trigger reader and the pre-flight's refusal are devbin-dc's, after run 3. The two call lines in `release check` and the pre-flight are cc's, in WP02b. All of it lands in 0.1.19.
   - **The formula publish stays an after: command** in 0.1.19, not a step of the cut. After the tag the order is push, attach, then the after: commands, the formula among them. A failed formula publish is the after step's FAILED row, and the release stands.
   - **ST0031/03's owner** stays FOR hv with devbin-vc.

## Acceptance

Acceptance Criteria for this work package are RENDERED into `ST0031/acceptance.md`, under the `WP-01` heading. THAT FILE IS A GENERATED VIEW -- a row authored there is discarded by the next sync. The contract is canon in the thread's model, and the verbs write it: `intent ac new` and `intent at new` mint a row, `intent ac edit` and `intent at edit` reword or re-cite one, and `intent ac satisfy|unsatisfy|descope|rescope|withdraw|reinstate` and `intent at green|red|na` move its state. This cover never restates them.

---

_Generated by Intent v3 from the thread canon. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
