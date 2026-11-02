---
wp_id: WP-03
title: menuz reads the release stamp, not the tag, for MenuzKind=release
scope: S
status: Done
---

# WP-03: menuz reads the release stamp, not the tag, for MenuzKind=release

## Objective

menuz stamps a clean build at Utilz's release commit `release` before that commit's tag exists, reading the release commit as Devbin ST0011 WP06's app-sign does, so the macos leg of Devbin 0.1.19's cut can build, sign and ship Menuz.app there; a build between releases stays `dev`. The rule is stated once, in help/menuz.md.

Read at Utilz d0affbec and Devbin c8721135: WP06's objective, with its ruling of 31 Oct (last changed at 40abb91b), WP02's objective, and the core's `release_read_stamp` and `app_ship_blockers` as vendored here. [run 3] marks a point that hangs on WP06, the macOS stage at the release commit, which lands in 0.1.19 and reaches Utilz with the sweep. Sized S: `build_kind` and its tests, the kind rule stated once in `help/menuz.md` with the three other statements of it pointing there, and a CHANGELOG entry.

## 1. What build_kind decides today, and who reads it

- **The rule** (opt/menuz/menuz:620-645): `release` when the source stamp is clean and HEAD carries the tag the root VERSION names, bare, read with `git tag --points-at HEAD`; `dev` otherwise, an empty VERSION included; exit 1 with why when VERSION or the tags cannot be read.
- **Its callers:** `build_stamps` (:606-618) makes it the fifth stamp, which goes to two places.
  - `xcode_run` (:714-717): every `menuz build`, debug or `--release`, passes it to xcodebuild as `MENUZ_KIND`, and the app's Info.plist carries it as `MenuzKind`.
  - `cmd_stamps` (:798-801): `menuz stamps` in a source clone.
- **The release build:** the macos built-in's `build:` is `bin/utilz menuz build --release` (config.yaml:117), run by `bin/devbin macos app-sign`.
  - Today tools/post-cut runs app-sign in a worktree at the tag.
  - In the new shape the macos leg runs it at the release commit R, before the tag exists [run 3].
- **The reader:** the core's `app_ship_blockers` (bin/.devbin/lib/cmd/macos:772-813, vendored) refuses a copy whose `MenuzKind` (macos.kind_stamp) is not `release` (macos.kind_value), at app-sign and at publish. At R today's rule stamps `dev`, so the leg's app-sign would refuse every Utilz cut in the new shape.
- **Where the rule is written:** besides the code, four places state today's rule, each in its own words: help/menuz.md:249 (the stamps) and :264 (the top row's forms), docs/releasing.md:74, and the comment at bin/.devbin/config.yaml:109-110.

## 2. The new rule

The core defines the release commit for app-sign in WP06's ruling of 31 Oct: a clean tree, with HEAD at the tag's commit when the tag exists, else at the release commit, the untagged commit whose VERSION is the version being released [run 3]. `build_kind` reads the same rule, so the stamp and the gate that reads it agree:

- **release** when the source stamp is clean, and either:
  - the tag the root VERSION names points at HEAD, which is a build at the tag, as today; or
  - no tag of that name exists yet, which is a build at R before the tag is made on green.
- **dev** otherwise: a dirty tree, or the VERSION's tag on another commit. That second case is every commit from one release to the next stamp, since VERSION moves only at the stamp.

The rule in detail:

- **Reading the tag:** `git tag --list <VERSION>` answers empty for no tag, and fails only when git cannot answer. Then `git rev-parse refs/tags/<VERSION>^{commit}` is compared with HEAD, so a branch of the same name can never answer. A git that cannot answer stays exit 1 with why, as today.
- **What R carries:** WP02's stamp gives R its VERSION and a dated CHANGELOG.md note, which is what the core's `release_read_stamp` reads. The rule reads VERSION alone, as WP06's precondition does. Reading the note too would give menuz a second reader of the core's note convention, and make menuz stricter than the gate it feeds (ruling 1).
- **An empty VERSION:** a root VERSION that is empty, or only whitespace, names no release, so it is exit 1 saying so, as an unreadable one is. Today it reads `dev` with nothing on stderr. In a source clone it refuses `menuz stamps` and every `menuz build`, as a missing VERSION does today. A keg never reaches `build_kind`, and its install already refuses an empty VERSION (menuz:895).
- **The exit-1 cases, all with why on stderr:** the root VERSION cannot be read, or is empty; the tags cannot be listed; the tag is not a commit; HEAD cannot be read.
- **Unchanged:** the clean test (the source stamp's `-dirty` suffix), the bare tag (`release.tag: "{version}"`), and the root VERSION rather than opt/menuz/VERSION (the tag is Utilz's).
- **Stated once (W1):** the rule is written in prose once, at help/menuz.md:249, with the stamps, in the help that `utilz menuz --help` prints. It says the empty VERSION and the tagless clone too. The others point there, with no second copy:
  - help/menuz.md:264, under the top row's three forms: the kind is the build's `MENUZ_KIND`, by the rule above, and the signed release asset is built from a clean tree at its release commit;
  - docs/releasing.md:74: `MenuzKind` must be `release`, which menuz stamps by the rule `help/menuz.md` states with the stamps;
  - the comment at bin/.devbin/config.yaml:109-110: the kind stamp follows the rule help/menuz.md states. It stays within its two lines, so no line moves in that file, and the lines ST0031/01's stored design edits and cites there (:50-54, :127-136, :134, :136, :143 and :145) stand;
  - the comment above `build_kind` (:620-625) names the rule's home and WP06. It keeps only how the code reads the rule, the tag listed by name, read under refs/tags/ and peeled, and the exit-1 cases. It drops "as Intent's build.rs decides its own", which no longer holds.
- **docs/releasing.md:72** says a Menuz.app built off the tag carries the kind `dev`. In post-cut's context the tag exists, so that stays true under the new rule. ST0031/01 rewrites that paragraph when it retires post-cut, and builds on :74.
- **Today's flow is unaffected:**
  - post-cut builds at the tag, where the tag is at HEAD;
  - between releases, VERSION's tag is on an earlier commit, so builds stay `dev`;
  - a version with no tag yet occurs today only inside a cut, between the stamp's commit and the tag, where no build runs.

  So /03 needs no new core, and it can land before the sweep.
- **A known limit:** a clone that holds no tags at all reads `release`, since no VERSION tag exists in it. The builders hold the tags: a desk clone, and CI's menuz-app job, which checks out with `fetch-depth: 0` (tests.yml:539-541) and uploads nothing. The macos leg reads `release` at R whatever its checkout holds, since at R no VERSION tag exists in any clone (ruling 3).
- **The CHANGELOG entry**, under 2.14.9's open section as `### Changed`, before `### Fixed`, says what a user sees change: a clean build at a release commit before its tag is stamped `release`, a build between releases is still `dev`, and an empty root VERSION is exit 1. It points to `utilz help menuz` for the rule. It was not in the stored design, and is for vc's read.

## 3. Tests (opt/menuz/test/menuz.bats)

- **One helper, `past_release`:** it tags the root VERSION on the fixture's commit, then commits once more, putting HEAD past a release. That is the state between releases. `source_home` stays as it is, since every other test uses it.
- **AT-07.3 at :1593** ("dev when HEAD carries no tag") inverts. With no tag for the root VERSION, HEAD is the release commit before its tag, and the kind is `release`, in `stamps` and in the build's xcodebuild call.
- **AT-07.3 at :1610:**
  - Its first half gains `past_release` first. The `v`-prefixed and `0.0.1` tags at HEAD then still read `dev`, since a tag that is not the bare VERSION never makes a release.
  - Its second half, the bare tag on an earlier commit, is the new `past_release` arm below, where it stays `dev`.
- **New AT-07.3 arms:**
  - dirty with no tag reads `dev`, the clean test applying before the tag test;
  - `past_release` reads `dev`.
- **AT-05.1 at :746 and :991** (the build passes the five stamps; stamps prints them) pin `MENUZ_KIND=dev` from `source_home`'s tagless fixture, which now reads `release`. Each calls `past_release` first, so each still pins `dev`. That adds a commit, so each also reads its `MENUZ_BUILD` from the fixture's commit count (`git rev-list --count HEAD`), in place of the count written by hand, 1.
- **New error arms in AT-07.3** (W2, and the empty VERSION). Each shows red by reading, against the bank before this revision and against today's `build_kind`:
  - **An empty root VERSION** is exit 1 with `menuz: <home>/VERSION is empty, so it names no release tag`. Red: both read it as `dev`, and stamps exits 0.
  - **A git that fails `tag --list` alone** is exit 1 with `menuz: git tag --list <VERSION> failed in <home>`. The fake goes on PATH and execs the real git, taken by `command -v git` before the fake goes on, for every other call. Red: with the `if !` arm deleted, or the call made `2>/dev/null || listed=""`, the failure reads as no tag. That is `release`, and stamps exits 0. If set -e held inside the substitution, it would exit 128 without the message instead.
  - **A root VERSION tag on HEAD's tree** (`git tag <VERSION> 'HEAD^{tree}'`) is exit 1 with `menuz: the commit of tag <VERSION> could not be read in <home>`. Red: with that `if !` arm deleted, the tag's commit reads empty and unequal to HEAD, so the kind is `dev`, and stamps exits 0.
  - **Only `v<VERSION>` and `0.0.1` at HEAD** read `release`, since no tag of the root VERSION exists yet. Red for a lookup that is not by the bare name exactly: `--points-at HEAD`, or a `*<VERSION>` pattern, lists the v-tag. The bare tag's commit then cannot be read, and stamps exits 1.
- **Tightened** (critic-shell's recommendations):
  - AT-05.1's stamps test reads the commit count first, then matches the whole line with `grep -qx "MENUZ_BUILD=$count"`, in place of :999. So `MENUZ_BUILD=2` cannot pass for 20, and a git that fails stops the test instead of leaving `MENUZ_BUILD=`, which every stamps output contains. Its `MENUZ_VERSION` and `MENUZ_COMMIT` lines (:998, :1000) predate this WP and stay as they are.
  - AT-07.3's two `past_release` arms, new in this WP, assert a clean source stamp (`^MENUZ_SOURCE_TREE=[0-9a-f]{40}$`) before the kind, as the dirty arms assert `-dirty`. So a fixture turned dirty cannot pass for the tag on an earlier commit.
- **The AT-07.3 header comment** names the error tests.
- **Stand as they are:**
  - AT-07.3 at :1572 and :1584 (the tag at HEAD, plain and annotated) and :1600 (dirty with the tag).
  - :1644 (an installed bundle with no MenuzKind), which reads a bundle, not `build_kind`.
  - The bundle fixtures at :108 (make_app's plist) and :607 (the fake xcodebuild's product, whose MenuzKind is the build's MENUZ_KIND). They describe bundles, not the decision.
  - The keg install test at :1552, whose empty VERSION a keg refuses before any stamp is read.
- **The run:** menuz.bats alone, booked at rhadamanth's desk after vc reads the bytes. Every red above shows by reading, so no red run is booked (decision 67).

Line numbers in this section are main's at d0affbec, before the change. A test the WP adds is named by its title.

## 4. Order

1. vc reads this revision, the re-bank and the run wrapper by sha256. Then, on vc's YOUR TURN, the revision is stored as ST0031/03's body, and the WP is rescoped to S.
2. It is built in a worktree off main. The tests use the fake xcodebuild and a fake git, and nothing touches Hammerspoon, the pointer or hv's keychain (watch-out 3, widened for W1).
3. menuz.bats is booked and run. The change lands on vc's check before Utilz's first cut in the new shape, and may land before the sweep.
4. **At the sweep**, once Devbin 0.1.19 is vendored, `build_kind` is read against the vendored `app-sign`. The vendored 0.1.18's `app-sign` still wants the tag at HEAD (bin/.devbin/lib/cmd/macos:827-840, its refusal at :831), so the two readings agree only from 0.1.19 on. The read belongs to ST0031/01's build, which vendors 0.1.19.

## 5. Rulings (utilz-vc, 31 Oct)

1. **What the rule reads:** VERSION alone, as WP06's app-sign precondition reads the release commit, and not the dated CHANGELOG note as well.
2. **Where the fixture moves:** a `past_release` helper, called by the tests that pin `dev`. `source_home` stays as it is.
3. **The tagless clone:** the limit is accepted and named. An any-tag guard would refuse the cut if the leg's checkout at R held no tags, and the stamp's one reader, `app_ship_blockers`, runs only at app-sign and publish. Since W1, the limit is named where the rule is written, help/menuz.md:249, and the comment points there.
4. **critic-shell's read of the bank a2e9756e** (vc decision 80 resumed the WP under these rulings):
   - W1 is in this WP: the rule is written once, at help/menuz.md:249, and :264, docs/releasing.md:74 and the comment at config.yaml:109-110 point there. Watch-out 3 was widened to those lines first.
   - W2: three AT-07.3 tests (the `tag --list` failure, a tag that is not a commit, a v-tag alone), each red by reading. A mutation run is booked only where reading cannot show it.
   - An empty VERSION is exit 1 with why, pinned by one test.
   - :1012 assigns the count first, then matches with `grep -qx`.
   - :1638 and :1646 assert a clean tree first.
   - These three lines are the critic's, in the bank a2e9756e.
   - The re-check against WP06 is a step at the sweep (section 4, step 4).
   - The WP is rescoped to S if the help and the tests take it past XS. They do.

## Acceptance

Acceptance Criteria for this work package are RENDERED into `ST0031/acceptance.md`, under the `WP-03` heading. THAT FILE IS A GENERATED VIEW -- a row authored there is discarded by the next sync. The contract is canon in the thread's model, and the verbs write it: `intent ac new` and `intent at new` mint a row, `intent ac edit` and `intent at edit` reword or re-cite one, and `intent ac satisfy|unsatisfy|descope|rescope|withdraw|reinstate` and `intent at green|red|na` move its state. This cover never restates them.

---

_Generated by Intent v3 from the thread canon. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
