---
wp_id: WP-04
title: 2.14.9's cut in 0.1.19's shape: tests.yml on candidate/**, post-cut publishes and pulls only
scope: S
status: Not Started
---

# WP-04: 2.14.9's cut in 0.1.19's shape: tests.yml on candidate/**, post-cut publishes and pulls only

## Objective

Utilz 2.14.9 is cut through Devbin 0.1.19's core and works first time. tests.yml fires on the candidate branch the cut pushes, with its macOS jobs on it, so the pre-flight's trigger read passes. tools/post-cut stays the one after: line: it attaches the Menuz.app that the cut's macos leg signed and notarised at the release commit, then publishes the formula and pulls this machine's tap, stopping at the first failure. So the app is signed once, and no formula reaches the tap before its zip. The rest of ST0031/01 waits until after the cut.

Read on 2 Nov at Utilz c399465b and the vendored Devbin 0.1.19 (fc8cd495, its source re-recorded at 7f5167b7). Line numbers are at c399465b; vc's unstaged 0132 edits were not read. No source edit is made before hv's go, on vc's YOUR TURN.

## 1. Why two units, and not /01 whole

devbin-vc's three trip points, relayed by vc, and a fourth found here:

1. **tests.yml never fires on `candidate/**`.** 0.1.19's cut pushes the release commit R to `candidate/{tag}` and reads CI there before it tags, and pre-flight asks `bin/devbin ci-state --fires` and refuses a push that starts no run (lib/pages/release.md:75; `release check` asks the same in check_trigger, lib/cmd/release:455-462). Since the sweep dropped Utilz's `ci:` block (config.yaml:135-137), the defaults hold: the built-in query on tests.yml, ci.wait 60m (lib/config.reference.yaml:598-602). tests.yml pushes on `main` and tags only (tests.yml:4-10).
2. **post-cut signs Menuz.app a second time.** after: `tools/post-cut` (config.yaml:143-144) builds, signs and notarises it in a worktree at the tag (post-cut:89-101), after the cut's macos leg has signed and notarised it at R (lib/release.macos:94-98), at the project root (lib/cmd/release:1495).
3. **No build: block** (AC-5.4). The cut runs without one, and says the app is built uncached (lib/cmd/release:1298-1306). It waits until after this cut (vc).
4. **New: the cut never attaches Menuz.app.zip.**
   - The macos leg is app-sign then app-notarize, and nothing more (lib/release.macos:94-98).
   - The object step attaches only release.assets.workflow's run (lib/cmd/release:3086-3110), and Utilz declares none.
   - publish "runs once the tag is cut and the object made" (lib/pages/macos.md:35), and no step of a cut calls it.
   - after: runs every command even when one before it failed (lib/cmd/release:3114-3118).

   So /01's after: `bin/devbin formula publish` (its section 2; AC-01.1) ships 2.14.9 with no Menuz.app.zip. Two after: lines, macos publish then formula publish, could put the formula on the tap before the zip: the hazard post-cut is one line for (post-cut:12-14; ST0030 D2).

So 2.14.9 takes the trigger change, plus a post-cut that publishes what the leg signed. post-cut retires once the core attaches the app inside the cut, stops after: at a failure, and pulls the tap: three asks for Devbin ST0011 WP10, through vc.

## 2. U1: tests.yml on candidate/** (XS)

On main's tests.yml, not on ST0031/02's bank, so the first candidate run is the CI 2.14.8 passed, with only its triggers changed.

- :5, `branches: [ main ]`, becomes `branches: [ main, 'candidate/**' ]`.
- :6-10, the `tags:` line and its comment, go. The cut tags only once the candidate is green, so a tag's run would test a commit already proven.
- :11-13, the paths-ignore comment, is rewritten. A candidate is a branch push, where GitHub evaluates path filters. R changes VERSION and CHANGELOG.md, outside both ignored trees (:14-21), and pre-flight's `--fires` read asks exactly that, with the stamp's files (lib/cmd/release:455-462).
- The four conditions, :115, :285, :534 and :598: `github.ref_type == 'tag'` becomes `startsWith(github.ref, 'refs/heads/candidate/')`, beside `github.event_name == 'workflow_dispatch'`, which stays (/01's section 5, ruling 1). The four stay four (/01's section 2).
- Comments that say "release tag" say "candidate push" instead: :111-114 (test-macos), :519 (menuz-app), :623-627 (test-summary's macos_leg), and config.yaml:52-54 (test estate's).
- :241-242 calls tools/ci-state "the release core's ci.query", which the sweep ended. It names tools/post-cut, still in tools/, instead.

**Proof.**
- R2, `bin/devbin release check`, reads the trigger with no finding. Its one finding at the sweep, a push of `candidate/2.14.8` starting no run of tests.yml (fc8cd495's message), is gone.
- R3, the dry run, prints the legs row with no pre-flight refusal.
- **A gate before the cut:** hv's push of main after the landing runs CI as now, ubuntu legs only, which proves the main arm and the YAML. It must read green, by vc through the jobs API, before hv cuts, since a broken tests.yml would otherwise show only in the cut's candidate run.
- The cut's candidate run proves the candidate arm: test-macos, the rust job's macOS leg and menuz-app run, and Test Summary requires them.

## 3. U2: post-cut publishes and pulls only (S)

It stays the one after: line (config.yaml:143-144). The cut runs it at the project root, whose stage the leg signed (lib/cmd/release:1495); the stage is one per checkout (lib/pages/macos.md:75).

- **The app steps (post-cut:89-101).**
  - When the release carries Menuz.app.zip, they are skipped (:87-88, kept). Otherwise `bin/devbin macos publish` runs in `$root`. A failure dies naming it, and says the formula is not published.
  - The worktree, its temp dir, the trap, app-sign and app-notarize go (:90-100), with the header's worktree paragraph (:24-28).
  - publish ships only the leg's build of R. It refuses unless the stage was signed at the tag's commit (require_stage_signed_at_tag, lib/cmd/macos:926-938), and unless the copy passes the ship checks against that commit (app_ship_blockers, lib/cmd/macos:857-893).
  - It reads the tag from VERSION and the stage's record, not from HEAD (lib/cmd/macos:1290-1305). Once the tag exists, release_commit answers the tag's commit and never reads HEAD (lib/release.steps:258-290). It asks nobody: lib/cmd/macos calls no ask_person.
  - A stage that is gone, or another commit's, gets publish's own remedy, sign again in a tree at the tag (lib/cmd/macos:926-938). Then post-cut is run again.
- **The rest of the script.** formula publish (:103-105) and the tap pull (:107-123) stay as they are. tools/formula and packaging/homebrew/utilz.rb are unchanged since 2.14.8 (`git log 2.14.8..c399465b` over both is empty).
- **The header (:3-30) and usage (:48-56)** say what it does now: attach the app the cut signed at the release commit, then publish the formula, then pull the tap, stopping at the first failure. Why it is one line (:12-14) is kept. The re-run rule (:16-22) is kept, without "app-sign would build and sign a new copy".
- **config.yaml:131-137's comment** says the same, in one line, since the core runs every after: command.
- **docs/releasing.md.** :59, :70 and :72 say who signs (the cut's macos leg, at R) and that post-cut attaches what it signed; :99 follows. The numbered verb descriptions (:76-78) stay. The rest of the page describes 0.1.18's cut (:17, :20-56, the step table :26-38) and stays stale until /01's rewrite. hv's 2.14.9 commands come from vc's plan, so nobody follows that page at this cut.
- **CHANGELOG.md:** one Changed entry under 2.14.9, after vc's 0132 lands in the same file.

**Proof.**
- critic-shell, and the gate's shellcheck, read tools/post-cut.
- R1 runs `tools/post-cut 2.14.8` after the edit. It is light, and hv's to approve, since it reads gh and the tap.
  - **What it reads from gh:** only post-cut:83, `gh release view 2.14.8 -R matthewsinclair/utilz --json assets`, the release's asset names. Read on 2 Nov, they are Menuz.app.zip and SHA256SUMS, so the publish call is skipped (:87-88). tools/formula calls no gh.
  - **Why formula publish is a no-op on the tap:**
    - It publishes the newest release (tools/formula:144), which is 2.14.8 before the cut.
    - It clones the tap over https (:151-152, TAP_URL at :41), a read, into a temporary directory it removes on exit (:146-149).
    - It renders 2.14.8's formula into that clone (:154). The template and tools/formula are unchanged since 2.14.8.
    - The tap's Formula/utilz.rb already names tag 2.14.8 at f2021ddc, 2.14.8's commit (read on 2 Nov through the contents API), so the render changes nothing.
    - `git status --porcelain` on that file is then empty, so it prints "already carries utilz 2.14.8 ... so nothing was published" and returns (:156-161), before the add, commit and push (:163-167). There is no commit and no push.
  - **The pull** (post-cut:111-123) fast-forwards this machine's tap clone, which does nothing when it is current, and it writes nothing in the Utilz tree.
  - It ends `utilz 2.14.8: Menuz.app.zip attached and the tap published` (:124).
  - So every line is proven but the publish call.
- The cut proves the publish call: its after row is done, the release carries Menuz.app.zip and SHA256SUMS, and homebrew-utilz names 2.14.9.

## 4. Not in this package

- **/01 keeps its scope for after the cut:** tools/ci-state, install's CI reader, tools/formula and formula.bats moved to the core (probe (a) first), docs/releasing.md's rewrite, both probes, and ST0019's AC-01.3 as AC-01.5.
- **/02's bank** rebases onto U1 and lands after the cut, proven by hv's push and a dispatch.
- **The build: block** waits (vc). post-cut's retirement waits for the core (section 1).
- **For vc's ruling at /01's re-plan after the cut; nothing changes now.**
  - AC-01.1, whose one after: command is `bin/devbin formula publish` with post-cut gone, cannot hold on 0.1.19, by section 1's point 4.
  - Nor can AC-01.4, a cut "through the core alone" with Menuz.app.zip "attached before any after: command runs".
  - AC-01.2 is U1's criterion: AC-04.1 below takes it.

## 5. Criteria, proposed

- **AC-04.1** (non-test): tests.yml fires on a push to `main` or `candidate/**`, with no `tags:` trigger, and runs test-macos, menuz-app and the rust job's macOS leg only on a `candidate/` push or a dispatch. A read-only `bin/devbin release check` reads the trigger with no finding, and 2.14.9's candidate run is green on every job it starts.
- **AC-04.2** (non-test): tools/post-cut, the one after: line, attaches the Menuz.app the cut's macos leg signed and notarised at the release commit, through `bin/devbin macos publish` at the project root, and builds and signs nothing. It then publishes the formula and pulls this machine's tap, stopping at the first failure. 2.14.9's after row is done, its release carries Menuz.app.zip and SHA256SUMS, and homebrew-utilz names 2.14.9.
- **AC-01.2** is withdrawn, with the reason "carried by ST0031/04's AC-04.1", so the trigger has one criterion (vc). AC-01.1 and AC-01.4 wait for /01's re-plan after the cut (section 4).

## 6. Order, runs and freeze

- vc's 0132 lands first, since CHANGELOG.md is shared.
- On vc's YOUR TURN, once hv's go is in, the records land first, as one READY, before any source edit:
  1. `intent st resume ST0031`, first. Neither `wp new`'s help nor `intent llm guide` says whether it takes a held thread, and finding out would be a write, so the resume comes first, which holds either way. The resume hydrates the thread, so the new package's views land in it.
  2. `intent wp new ST0031 "<title>"`. It takes only the thread and the title, so the objective and body go in through `intent set intent:///threads/ST0031/wp/04 objective --from <file>` and `... body --from <file>`, and the scope through `intent wp rescope ST0031/04 S`.
  3. `intent ac new ST0031 AC-04.1 --kind non-test --text <text>`, the same for AC-04.2, and `intent ac withdraw ST0031 AC-01.2 --reason "carried by ST0031/04's AC-04.1"`.
  4. dc claims ST0031/04.
- Then U1 and U2 land as a second READY, checked by vc by their change, committed by literal path, then END.
- R1, R2 and R3, each booked at the desk:
  - R1 (light, hv's to approve): `tools/post-cut 2.14.8`, with U2 in the tree (section 3's Proof).
  - R2 (light): `bin/devbin release check`.
  - R3 (light): `bin/devbin release --patch --dry-run`. It makes no commit, tag, push or object, and runs no gate (lib/cmd/release:81). Watch-out 22's "no dry run" goes to hv in one line (vc).
  - R2's and R3's outputs go to devbin-vc.
- The gate: hv's push of main, and CI on that push read green by vc through the jobs API (U1's Proof). hv cuts only after that.
- hv's cut of 2.14.9.
- The freeze, from the cut's GO until its after row is read: no tree write by any node, `intent wb` verbs included, and every tree read with GIT_OPTIONAL_LOCKS=0, since the core commits in the primary and publish reads the leg's stage there.
- Sizes: U1 XS, U2 S, and S with its runs.

## Acceptance

Acceptance Criteria for this work package are RENDERED into `ST0031/acceptance.md`, under the `WP-04` heading. THAT FILE IS A GENERATED VIEW -- a row authored there is discarded by the next sync. The contract is canon in the thread's model, and the verbs write it: `intent ac new` and `intent at new` mint a row, `intent ac edit` and `intent at edit` reword or re-cite one, and `intent ac satisfy|unsatisfy|descope|rescope|withdraw|reinstate` and `intent at green|red|na` move its state. This cover never restates them.

---

_Generated by Intent v3 from the thread canon. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
