---
wp_id: WP-04
title: 2.14.9's cut in 0.1.20's shape: tests.yml on candidate/**, post-cut publishes and pulls only
scope: S
status: Not Started
---

# WP-04: 2.14.9's cut in 0.1.20's shape: tests.yml on candidate/**, post-cut publishes and pulls only

## Objective

Utilz 2.14.9 is cut through Devbin 0.1.20's core and works first time. tests.yml fires on the candidate branch the cut pushes, with its macOS jobs on it, so the pre-flight's trigger read passes. tools/post-cut stays the one after: line: it attaches the Menuz.app that the cut's macos leg signed and notarised at the release commit, then publishes the formula and pulls this machine's tap, stopping at the first failure. So the app is signed once, and no formula reaches the tap before its zip. release.formula stays undeclared, so the core's formula step is skipped. The rest of ST0031/01 waits until after the cut.

Read on 5 Nov at Utilz c54e89be and the vendored Devbin 0.1.20 (7a6a06a7, from Homebrew's install of v0.1.20, commit be40dea790f2), with vc decisions 89 and 90 and hv's calls on vc's revised plan folded in. Line numbers are at c54e89be. Of the paths this package edits, only CHANGELOG.md has moved since v2's read at c399465b (efdd047d, 0132's entry). No source edit is made before these records land, on vc's YOUR TURN.

## 1. Why two units, and not /01 whole

devbin-vc's three trip points and the fourth found at 0.1.19, each re-read at 0.1.20:

1. **tests.yml never fires on `candidate/**`.** The cut pushes the release commit R to `candidate/{tag}` and reads CI there before it tags, and pre-flight asks `bin/devbin ci-state --fires`, refusing a cut whose push would start no run (lib/pages/release.md:82; pre-flight's read, lib/cmd/release:2598-2608; `release check` asks the same in check_trigger, :467-516, its read at :502, through release_fires_read, :1878-1917). The read is of the workflow as committed at the sha, through git alone: it reads no repository (lib/cmd/ci-state:75-102, cistate_fires :686-731, :861). Since Utilz declares no `ci:` block (config.yaml:135-137), the defaults hold: the built-in query on tests.yml, ci.wait 60m (lib/config.reference.yaml:598-602). tests.yml pushes on `main` and tags only (tests.yml:4-10). Holds at 0.1.20.
2. **post-cut signs Menuz.app a second time.** after: `tools/post-cut` (config.yaml:143-144) builds, signs and notarises it in a worktree at the tag (post-cut:89-101), after the cut's macos leg has signed and notarised it at R. The leg is `macos leg` (lib/release.macos:93-111), app-sign then app-notarize where macos.app is declared (lib/cmd/macos:1753-1768), run at the root the cut hands it (lib/release.macos:96-97, started at lib/cmd/release:789). Holds.
3. **No build: block** (AC-5.4). The cut runs without one, and says the app is built uncached (lib/cmd/release:1335-1344). It waits until after this cut (vc). Holds.
4. **The cut never attaches Menuz.app.zip.**
   - The leg signs and notarises, and nothing more (lib/cmd/macos:1753-1768).
   - The object step, under object: local, attaches release.assets.workflow's run where one is declared, and Utilz declares none, and runs macos bin-publish only where macos.binaries is declared (lib/cmd/release:3306-3408), which 2.14.9 does not (hv's call (d)). No line of lib/cmd/release, lib/release.steps or lib/release.macos runs macos publish.
   - publish "attaches to the release object, so it runs once the tag is cut and the object made" (lib/pages/macos.md:56).
   - **New at 0.1.20, the formula step** (issue 0323): once the object step succeeds, where release.formula is true, the core runs `formula publish --pull` (cut_formula_step, lib/cmd/release:3218-3255, called at :3411-3415), and a failure there stops the cut with after: unrun. Undeclared, it prints `formula skipped: release.formula is not declared` (:3227), in the dry run and the cut alike.
   - after: still runs every command even when one before it failed (lib/cmd/release:3417-3470).

   So /01's after: `bin/devbin formula publish` (its section 2; AC-01.1) would ship 2.14.9 with no Menuz.app.zip, and so would a declared release.formula: the formula step runs before after:, so the formula would reach the tap ahead of the zip that the keg's `utilz menuz install` downloads by version (opt/menuz/menuz:904-917; ST0030 D2). A true release.formula with no formula command enabled is refused at pre-flight besides (lib/cmd/release:2346-2354), and enabling the built-in formula is /01's, after its render probe. Two after: lines, macos publish then formula publish, would put the formula on the tap after a failed publish: the hazard post-cut is one line for (post-cut:12-14).

So 2.14.9 takes the trigger change, plus a post-cut that publishes what the leg signed and keeps its formula publish and tap pull (hv's call (a)). Of v2's three asks for Devbin ST0011 WP10 (hv's call (i)), the tap pull is covered by 0.1.20's `formula publish --pull` (lib/pages/formula.md:16-24), and the stop at a failure follows once the app is attached in the object step, ahead of the formula step. The one still wanted is the cut attaching the app: an app publish in the object step, as bin-publish is. post-cut retires once that lands and /01 moves the formula to the built-in.

## 2. U1: tests.yml on candidate/** (XS)

On main's tests.yml, not on ST0031/02's bank, so the first candidate run is the CI 2.14.8 passed, with only its triggers changed. Every condition takes devbin's own form, which devbin-vc checks U1 against (Devbin's tests.yml :192, :355 and :546, at 1fad08a00f91): `github.event_name == 'workflow_dispatch' || startsWith(github.ref, 'refs/heads/candidate/')`.

- :5, `branches: [ main ]`, becomes `branches: [ main, 'candidate/**' ]`.
- :6-10, the `tags:` line and its comment, go. The cut tags only once the candidate is green, so a tag's run would test a commit already proven, as Devbin's own tests.yml says (its :12-18).
- :11-13, the paths-ignore comment, is rewritten. A candidate is a branch push, where GitHub evaluates path filters. R changes the files release_owned names, VERSION and the note in CHANGELOG.md (lib/release.steps:447-462; notes.kind changelog, lib/config.reference.yaml:588-589), outside both ignored trees (:14-21), and pre-flight's `--fires` read asks exactly that, with those files (lib/cmd/release:2598-2608).
- The four conditions, :115, :285, :534 and :598: `github.ref_type == 'tag' || github.event_name == 'workflow_dispatch'` becomes devbin's form above. The four stay four (/01's section 2), and :285 keeps its matrix form, the condition in parentheses inside `fromJSON(...)`.
- Comments that say "release tag" say "candidate push" instead: :111-114 (test-macos, whose sentence on `ref_type` goes), :519-520 (menuz-app), :623-624 (test-summary's macos_leg: a SKIP is expected on a push to main and a failure on a candidate), and config.yaml:52-54 (test estate's).
- :241-242 calls tools/ci-state "the release core's ci.query", which the 0.1.19 sweep ended. It names tools/post-cut, still in tools/, instead.
- **The whole-file sweep** (devbin-vc). At c54e89be the file's only tag tests are the `tags:` trigger (:10) and the four `ref_type == 'tag'` sites. `ref_type` is named otherwise only in the comments at :8 and :113, which go. After U1, `grep -n -E "ref_type|tags:|release tag" .github/workflows/tests.yml` finds nothing.

**Proof** (hv's call (f)).
- **The red arm, R2 at the base:** `bin/devbin release check` on main without U1 or U2. Its one finding is the trigger: a push of `candidate/2.14.8` at HEAD starts no run the cut could read, since `ci-state --fires` answers quiet: "its push branches (main) match no candidate/2.14.8" (lib/cmd/ci-state:567; lib/cmd/release:1914-1916), so it exits 1 (lib/cmd/release:506-508, 5126-5129). Any other finding is new at 0.1.20 and goes to vc and devbin-vc before step 2.
- **The green arm, R2 at the fix:** the same command once U1 has landed reads that a push of `candidate/2.14.8` starts release.ci.workflow, its push branches entry 'candidate/**' matching it (lib/cmd/ci-state:565; lib/cmd/release:504), and exits 0 with no finding.
- R3, the dry run, prints the legs row with no pre-flight refusal, and the formula row skipped (hv's call (a)).
- **A gate before the cut:** hv's push of main after the landing runs CI as now, ubuntu legs only, which proves the main arm and the YAML. It must read green, by vc through the jobs API, before hv cuts, since a broken tests.yml would otherwise show only in the cut's candidate run.
- The cut's candidate run proves the candidate arm: test-macos, the rust job's macOS leg and menuz-app run, and Test Summary requires them.
- The tree-scan files that read tests.yml, each run whole once before the cut (section 6): common_lib.bats counts four strings in it (:1193-1228), none of which U1 adds or removes, and arngz.bats greps it for the lua installs, through `$wf` (:571-575), lines U1 leaves alone.

## 3. U2: post-cut publishes and pulls only (S)

It stays the one after: line (config.yaml:143-144). The cut runs after: at the project root (lib/cmd/release:132), where the leg signed: the leg runs at the root it is given (lib/release.macos:96-97), and the stage is one per checkout (lib/pages/macos.md:127). Inside the release gate its stdin is /dev/null, and it is handed DEVBIN_RELEASE_CONFIRMED (lib/cmd/release:3455-3457).

- **The app steps (post-cut:89-101).**
  - When the release carries Menuz.app.zip, they are skipped (:87-88, kept). Otherwise `bin/devbin macos publish` runs in `$root`, where post-cut stands from :70. A failure dies naming it, and says the formula is not published.
  - The worktree, its temp dir, the trap, app-sign and app-notarize go (:90-100), with the header's worktree paragraph (:24-28).
  - publish ships only the leg's build of R (lib/cmd/macos:1506-1551). It refuses unless the tag exists (:1518-1519), unless the stage was signed at the tag's commit (require_stage_signed_at_tag, :1009-1016, called at :1520), and unless the stage, and then the zip's copy, pass the ship checks against that commit (app_ship_blockers, :933 on, at :1521 and :1535) and the zip's copy is notarised and stapled (:1536-1537).
  - It reads the version from VERSION (release_names, lib/cmd/macos:832-844) and the commit from the tag, never from HEAD: once the tag exists, release_commit answers the tag's commit (lib/release.steps:268-307, through read_release_commit, lib/cmd/macos:886-897). So a board commit that moves the primary past the tag cannot fail it. It asks nobody: lib/cmd/macos calls no ask_person.
  - A stage that is gone, or another commit's, gets publish's own remedy, sign again in a tree at the tag (lib/cmd/macos:1012-1015). Then post-cut is run again.
- **The rest of the script.** formula publish (:103-105) and the tap pull (:107-123) stay as they are (hv's call (a)). tools/formula and packaging/homebrew/utilz.rb are unchanged since 2.14.8 (`git log 2.14.8..c54e89be` over both is empty).
- **The header (:3-30) and usage (:48-56)** say what it does now: attach the app the cut signed at the release commit, then publish the formula, then pull the tap, stopping at the first failure. Why it is one line (:12-14) is kept. The re-run rule (:16-22) is kept, without "app-sign would build and sign a new copy".
- **config.yaml:131-137's comment** says the same, in one line, since the core runs every after: command. U2 touches no key of config.yaml's macos block: hv's `bin/devbin macos doctor` counts one Developer ID identity, team 76BQL8L47U, so no macos.team is needed (hv's call (c), settled by doctor; lib/cmd/macos:329-364).
- **docs/releasing.md.**
  - :59, :70 and :72 say who signs (the cut's macos leg, at R, in the primary) and that post-cut attaches what it signed; :99 follows.
  - **:61-68, the store-creds paragraph** (hv's call (b)), is rewritten for the notarytool profile. Once on each Mac that cuts, hv runs `bin/devbin macos store-creds`, which runs `notarytool store-credentials` under the profile macos.notary_profile names, `devbin` by default (lib/cmd/macos:1365-1374). It is interactive, and refuses a stdin that is not a terminal (:1366). notarytool asks for an App Store Connect API key path, left empty, then the Apple ID, the app-specific password and the team id, checks them with Apple, and saves the profile in the login keychain. `bin/devbin macos doctor` then reads the profile PRESENT, counts the Developer ID identities with their team, and test-signs (:1240-1360); macos.team is needed only where it counts more than one. Nothing is written to the repository, and nothing prints a value. The `utilz.apple` items an earlier devbin read stay in the keychain, unread (7a6a06a7's message).
  - The numbered verb descriptions (:76-78) stay. The rest of the page describes 0.1.18's cut (:17, :20-56, the step table :26-38) and stays stale until /01's rewrite, :76's HEAD-at-the-tag sentence among it. hv's 2.14.9 commands come from vc's plan, so nobody follows that page at this cut.
- **CHANGELOG.md:** one Changed entry under 2.14.9 (:12-14), after ST0031/03's; and vc's prez line, "prez goes from 2.5.9 to 2.5.10.", appended to :18, 0131's entry, which ends "a second stall fails.".

**Proof** (hv's call (e)).
- critic-shell, and the gate's shellcheck, read tools/post-cut.
- **No new bats arm, a named departure** (vc decision 90 (4)). No suite names tools/post-cut, and R1 on 2.14.8 skips the app path at the base and at the fix alike, since 2.14.8 carries the zip, so U2 has no arm red at the base. Its changed path, publish in place of a second signing, is proven by the cut's after row alone.
- R1 runs `tools/post-cut 2.14.8` after the landing, booked light (vc decision 87 (ii)). For devbin-vc's term, that no step can push to homebrew-utilz or upload to the 2.14.8 release on a re-run, its ask re-cites these at U2's landed lines:
  - **What it reads from gh:** only post-cut:83, `gh release view 2.14.8 -R matthewsinclair/utilz --json assets`, the release's asset names. Read on 2 Nov, they are Menuz.app.zip and SHA256SUMS, so the publish call is skipped (:87-88), and nothing is uploaded.
  - **Why formula publish is a no-op on the tap:**
    - It publishes the newest release (tools/formula:144), which is 2.14.8 before the cut.
    - It clones the tap over https (:151-152, TAP_URL at :41), a read, into a temporary directory it removes on exit (:146-149).
    - It renders 2.14.8's formula into that clone (:154). The template and tools/formula are unchanged since 2.14.8.
    - The tap's Formula/utilz.rb named tag 2.14.8 at f2021ddc, 2.14.8's commit, when read on 2 Nov through the contents API, so the render changes nothing.
    - `git status --porcelain` on that file is then empty, so it prints "already carries utilz 2.14.8 ... so nothing was published" and returns (:156-161), before the add, commit and push (:163-167). It asks nobody before a push, so the no-op rests on the render matching the tap.
  - **Two guards in R1's driver**, since a read of 2 Nov cannot speak for the tap on the day:
    - before post-cut runs, the driver reads 2.14.8's assets and refuses unless Menuz.app.zip is among them, and renders 2.14.8's formula with `tools/formula render` and refuses unless it is byte-identical to Formula/utilz.rb at the tap's HEAD;
    - it runs post-cut with git's pushes to github.com rewritten to an address that cannot answer (a pushInsteadOf, through GIT_CONFIG_COUNT), so a push that should not happen fails, and R1 reads red, rather than publishing.
  - **The pull** (post-cut:111-123) fast-forwards this machine's tap clone, outside the tree, which does nothing when it is current. The driver records the clone's HEAD before and after.
  - It ends `utilz 2.14.8: Menuz.app.zip attached and the tap published` (:124).
  - So every line is proven but the publish call.
- The cut proves the publish call: its after row is done, the release carries Menuz.app.zip and SHA256SUMS, and homebrew-utilz names 2.14.9.

## 4. Not in this package

- **/01 keeps its scope for after the cut:** tools/ci-state, install's CI reader, tools/formula and formula.bats moved to the core (probe (a) first), docs/releasing.md's rewrite, both probes, and ST0019's AC-01.3 as AC-01.5. At 0.1.20 its re-plan can lean on the formula step and `formula publish --pull`.
- **/02's bank** rebases onto U1 and lands after the cut, proven by hv's push and a dispatch.
- **The build: block** waits (vc). post-cut's retirement waits for the core's app attach (section 1).
- **macos.binaries** is not in 2.14.9 (hv's call (d)).
- **For vc's ruling at /01's re-plan after the cut; nothing changes now.**
  - AC-01.1, whose one after: command is `bin/devbin formula publish` with post-cut gone, cannot hold on 0.1.20 either, by section 1's point 4.
  - Nor can AC-01.4, a cut "through the core alone" with Menuz.app.zip "attached before any after: command runs".
  - AC-01.2 is withdrawn, carried by AC-04.1.

## 5. Criteria

AC-04.1 and AC-04.2 were minted at c475fae3, non-test, and AC-01.2 withdrawn there. Both hold as written at 0.1.20:

- **AC-04.1** (non-test): tests.yml fires on a push to `main` or `candidate/**`, with no `tags:` trigger, and runs test-macos, menuz-app and the rust job's macOS leg only on a `candidate/` push or a dispatch. A read-only `bin/devbin release check` reads the trigger with no finding, and 2.14.9's candidate run is green on every job it starts.
- **AC-04.2** (non-test): tools/post-cut, the one after: line, attaches the Menuz.app the cut's macos leg signed and notarised at the release commit, through `bin/devbin macos publish` at the project root, and builds and signs nothing. It then publishes the formula and pulls this machine's tap, stopping at the first failure. 2.14.9's after row is done, its release carries Menuz.app.zip and SHA256SUMS, and homebrew-utilz names 2.14.9.

## 6. Order, runs and freeze

In vc decision 90's order:

- **Done:** the records at c475fae3 (st resume, wp new, objective and body, scope, AC-04.1 and AC-04.2, AC-01.2 withdrawn, the claim); hv's `bin/devbin macos store-creds` and `macos doctor` on 5 Nov: one Developer ID identity, team 76BQL8L47U, test-sign good, the profile devbin PRESENT.
- **v3's records**, on vc's YOUR TURN after its check, before any source edit: `intent set intent:///threads/ST0031/wp/04 title|objective|body --from <file>`, the body with its ### headings raised to ##.
- **R2 at the base**, U1's red arm, booked light, its driver read by vc and then devbin-vc before the ask. It needs no notary profile: nothing in the release core names one, and the profile's first reader is the cut's macos leg (lib/release.macos:104-111).
- **Step 2 as one READY:** U1; U2 (post-cut, config.yaml's after: comment, docs/releasing.md with the store-creds paragraph); CHANGELOG.md (U2's Changed entry, and vc's prez line at :18); critic-shell's read of post-cut. vc checks it by change, devbin-vc checks U1's push trigger, its four sites against devbin's conditions and that no tag test is left, then YOUR TURN, a commit by literal path, and END.
- **Then the runs**, each booked on devbin's desk, each driver read by vc and then devbin-vc before the grant, each ask naming its command line and what it can write outside the tree:
  - R2 at the fix, U1's green arm (light).
  - R1, `tools/post-cut 2.14.8` (light), with the two guards in section 3.
  - R3, `bin/devbin release --patch --dry-run` (light). It makes no commit, tag, push or release object and runs no gate (lib/cmd/release:81), and a dry run never asks at the confirm step (:3175-3178), so it needs no terminal. Its formula row reads skipped.
  - The tree-scan files, each whole once, their lanes devbin-vc's to pick: common_lib.bats and arngz.bats (they read tests.yml), and macos.bats (it reads config.yaml's macos block, which the sweep edited, through cfg_macos at :73-80, and copies bin/.devbin whole into its fixture project at :52).
  - R2's and R3's outputs go to devbin-vc and vc.
- **The pin sweep**, read at c54e89be over every *.bats and *.bash file in the tree (38), variables followed: the suites that read a path U1 or U2 changes are common_lib.bats (:1193-1228), arngz.bats (:571-575, through `$wf`) and macos.bats (:73-80, nine keys of the macos block, none of which U2 changes, and no test of the key set). It adds none:
  - install_lib.bats names tests.yml only as a fake gh's `--workflow` argument (:363, :817), never as the file;
  - formula.bats copies tools/formula (:18), which U2 does not touch;
  - no suite reads tools/post-cut, docs/releasing.md or CHANGELOG.md;
  - the suites that walk a tree (arngz.bats:1165, install.bats:200-204 and :268-273, install_e2e.bats:234 and :272, prez.bats:455) walk their own temp dirs, an install prefix or prez's target.
- **The gate:** hv's push of main, and CI on that push read green by vc through the jobs API, the verdict to devbin-vc by sha. hv cuts only after that.
- **hv's cut of 2.14.9** (`bin/devbin release --patch`).
- **The freeze**, from the cut's GO until its after row is read: no tree write by any node, `intent wb` verbs included, and every tree read with GIT_OPTIONAL_LOCKS=0, since the core commits in the primary and publish reads the leg's stage there.
- **After the cut:** vc reads the candidate run's jobs, the after row, the assets and homebrew-utilz at 2.14.9; dc satisfies AC-04.1 and AC-04.2 on vc's check, then wp done and unclaim; devbin-vc files the core's ask.
- Sizes: U1 XS, U2 S, and S with its runs.

## Acceptance

Acceptance Criteria for this work package are RENDERED into `ST0031/acceptance.md`, under the `WP-04` heading. THAT FILE IS A GENERATED VIEW -- a row authored there is discarded by the next sync. The contract is canon in the thread's model, and the verbs write it: `intent ac new` and `intent at new` mint a row, `intent ac edit` and `intent at edit` reword or re-cite one, and `intent ac satisfy|unsatisfy|descope|rescope|withdraw|reinstate` and `intent at green|red|na` move its state. This cover never restates them.

---

_Generated by Intent v3 from the thread canon. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
