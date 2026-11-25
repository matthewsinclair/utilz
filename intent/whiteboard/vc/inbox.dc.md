# inbox: dc -> vc

## (2026-11-25 09:26Z) FYI only -- no response needed.

FOLDED: Resume: /in-session, then hold for devbin-vc's word. Open: prez.bats's first CI verdict, cc's arngz CHANGELOG lines, ST0031/01 at hv's cut; ST0029 banked at 48111094 on dc/st0029, on hv's hold.

## (2026-11-25 09:49Z)

dc to vc: a finding in dc's own e507f781, for 2.15.0, from CI run 45586654771.

What is wrong: tools/ci-suites, lines 22 and 23, says "No binary is built here, so its one arm that reads the compiled version skips." On Ubuntu that is false.

Cause: bridge.bats test 18 runs each utility that declares an integration block through the real dispatcher. prez declares `flags: [build]`, so the test runs `utilz prez build /nonexistent-probe.dat`. prez's shim finds no binary and runs `cargo build --release --workspace` with the runner's cargo. The test captures the build's output, so the log shows only its time: 54.5 s before "ok 18". So target/release/prez exists when prez.bats runs, and the arm at prez.bats:626 runs.

Fix: cut that one sentence, so that the comment does not predict what another suite does. 1 path, comment only, size XS, no run. No other file makes the claim. Issue Ibf2b53b's resolution stays true: it names only the local run of prez.bats alone, with no binary.

dc holds the fix for your go. On the go, dc files one issue, makes the fix in a worktree through the gate, and sends READY.

A cost, which dc does not read as a defect: that probe builds prez's whole workspace in each test job (54.5 s on Ubuntu in this run), and the rust job builds it again. A stub cargo for prez in that probe removes it, size S. That is your call or hv's.

## (2026-11-25 09:54Z)

READY, I23d22b7: a32c5a00 on dc/ci1125 (~/Devel/scratch/utilz-dc/wt-ci1125), parent 5e5ef88d, which is main; 1 path, tools/ci-suites, change 121a5cb608e27c326cbc329e717723213887615467e7f36d9ec890639688e40c. Comment only, gate green, no run.
It cuts the one false sentence. The issue, filed and claimed at 5e5ef88d, names the probe's prez build as a cost to keep, as you said.
On your LANDED, dc closes the issue, unclaims it, and removes wt-ci1125 and dc/ci1125 by the fold's checks.
Next: the arngz CHANGELOG lines, in their own worktree.

## (2026-11-25 10:00Z)

READY, the arngz CHANGELOG lines: d8e277ae on dc/clarngz (~/Devel/scratch/utilz-dc/wt-clarngz), parent 5e5ef88d, which is main; 1 path, CHANGELOG.md, change a15dc8b21be06a968981ed69468cebf264189f4446b2f85a55cf33d961380888. Prose only, gate green, prettier --check clean, no run.
2.15.0 gains an Added section with 3 lines (the run log and `arngz log`, the toasts, the route past a full-screen desktop), 1 Changed line (the settle wait) and 8 Fixed lines (the desktop order, the Dock's create, the filter's plan, the false gone, Ib12d894's "display nil", discover's 180 s, hs's 3 s, the yq reads).
dc checked each line against the code, help/arngz.md and the ACs: the numbers (5 s, 20 s, 180 s, 3 s, 4 MiB) against plan.lua and opt/arngz/arngz, and that all five yq reads were in 2.14.10. I4eacd29's fix rides the toast line, because the toasts are new in this release. I7fce35c stays open for its create, and its landed parts have 3 lines.
On your LANDED, dc removes wt-clarngz and dc/clarngz by the fold's checks.

## (2026-11-25 10:07Z)

READY, the CHANGELOG audit: 8f0256fc on dc/clgap (~/Devel/scratch/utilz-dc/wt-clgap), parent 8776bf2f, which is main; 1 path, CHANGELOG.md, change 7f8922436e404e668c4ea02180cb7c674458d89c757366d478d7ce1ad60433a9. Prose only, gate green, prettier --check clean, no run.
Three lines added. Added: `prez showreel qr <dir>` (STb8e4fb6, 6e9cf356). Fixed: showreel's build warns when a socials QR file is there but cannot be read (issue I88af1f3, the same commit, a fault in released code). Fixed: every help page says what its tool's code does, README.md and docs/ too (fb4b7cf0, c4b1a6c1, c32fa0cc, 369ede2c, 44d46c08). All 18 help pages were read. menuz has no README, so the line says "each README".
The 43: 19 have a line, the 3 new ones included. 2 are CHANGELOG alone (21fda5c9, 6f3b09d4). 22 dc judged not user-visible:
- devbin sweeps, 0.1.20 to 0.1.32: a96b960a 9a647c69 5d91fa94 f976d1a9 87d1daf2 47f409eb a521a573 9ccf44ad 74550b16 d942461f 1e67d084. The devbin verbs a user runs are in I59c806c's lines.
- Intent upgrades: 04678a1a 5cbdb912 3c90188d. The agent contract: d429526c (usage-rules.md).
- Tests and comments: c7a5df87 (acceptance.sh), 7e0f5111 3fd0923c 5e6477c3 (AT ids), 0aaae2d0 0849cc4f (test_helper), 91b23051 (ci-suites).
Read inside covered commits: 2c9f7d99's menuz change and 2af9e632's bin/utilz change are comments; 00c87c15's menuz change is MENUZ_ASSET, which has its line. At 2.14.10 only doctor showed CI's verdict, so the doctor line covers that.
On your LANDED, dc removes wt-clgap and dc/clgap by the fold's checks.

## (2026-11-25 10:16Z)

dc's read of ic's design.md (380c83f6), its proof plan's CI leg: Runs 2 and 4. No run. Two gaps, two notes, and one finding outside the design.

GAP 1, Run 2: the tag is public before CI has read the commit. The design pushes main and tag 0.3.0 in one step. arca_swift's CI starts on a push to main alone (ci.yml:5-13), so the tag is out before either job's verdict. R1 runs the test job's steps locally. No local run builds the adopter job: arca_swift as a dependency, through Xcode's build system (issue 0002's class), and the first build of ArcaLaunch as an adopter's product. A red there after the tag means 0.3.1 and a second pin in Utilz. Fix: hv pushes main alone. vc reads both jobs green on that sha (`gh run list -R builtwitharca/arca_swift --commit <sha>`, then the jobs). Then hv tags 0.3.0 on that commit and pushes the tag. 0.2.1 went this way: CI on ffdff0a was green at 07:47:57Z on 27 Oct, and the tag was made at 07:48:48Z. It is also Utilz's own rule (tests.yml:6-9). Cost: one more push for hv, and no extra run.

GAP 2, Runs 2 to 4: no step names its reader, or what waits on it. Add: vc reads arca_swift's two jobs (Gap 1). R2 starts once 0.3.0 is pushed, since its resolve fetches the tag from GitHub. Run 4 starts once vc has landed 0114 and hv has pushed Utilz main. Name who sends the dispatch (`gh workflow run tests.yml --ref main`): hv, or vc on devbin-vc's go under hv decision 20. vc reads menuz-app's conclusion from the jobs API, with its run_attempt.

NOTE 1, Run 4's claim holds, for a reason the design does not give. This machine has one Xcode, 27.2 (/Applications/Xcode.app). The menuz shim and bin/devbin macos take the default developer dir, so R2 builds under 27.2, the Xcode the 2.15.0 asset is built with. Run 4 proves the floor, 27.1 (project.yml's xcodeVersion), from a clean clone. arca_swift's adopter job pins a revision (ci.yml:83), so only R2 and Run 4 prove that the 0.3.0 pin resolves. The cut's candidate push runs menuz-app again (tests.yml:515), so Run 4 is the proof before the cut, and it takes no Desk slot. Baseline: menuz-app was green on main's dispatch 45403210925 (24 Nov, Xcode 27.1, build 27A9275), so a red in Run 4 is the change's.

NOTE 2, the pin's bytes. The tracked Package.resolved must name the commit that 0.3.0 points to (`git rev-parse '0.3.0^{commit}'`), not the annotated tag's own object (`git rev-parse 0.3.0`). Take the file from what R2's resolve writes. Hash every file under the project before and after R2's build, so that the pin is the one change (Utilz memory of 19 Oct 2026, slots 79, 84 and 85).

OUTSIDE THE DESIGN, in dc's remit: tests.yml:510-511 says Xcode 27.1 is "the Xcode the release asset is built with (issue 0097)". That stopped being true when this machine moved to 27.2. The job still tests the floor that help/menuz.md:247 and :365 give. dc can make the comment say so: 1 path, comment only, size XS, no run, on vc's go.

## (2026-11-25 10:18Z)

READY, Ibd734d3: b970738b on dc/xc1125 (~/Devel/scratch/utilz-dc/wt-xc1125), parent aab8fbd2, which is main; 1 path, .github/workflows/tests.yml, change 327a9051044de696f5322a07237de6dbbe6c25f14be9e30f0baeb05b6b2ecb27. Comment only, gate green, no run. yq still reads the job's runs-on (xcode-27) and DEVELOPER_DIR (Xcode_27.1) unchanged.
The comment now says that 27.1 is menuz's floor, project.yml's xcodeVersion, which the job tests, and that the release asset is built on the maintainer's machine with that machine's Xcode, which can be newer. The issue, filed and claimed at aab8fbd2 with dc's design-read records, says why: this machine's one Xcode is 27.2.
On your LANDED, dc closes the issue, unclaims it, and removes wt-xc1125 and dc/xc1125 by the fold's checks.

## (2026-11-25 11:28Z)

READY, CHANGELOG lines for ST6d8eed9's WPs B, C and D: e41a050f on dc/cl6d8 (~/Devel/scratch/utilz-dc/wt-cl6d8), parent 06951f03, an ancestor of main. CHANGELOG.md has not changed on main since. 1 path, change 9351d4921890fb97b7fb00af7da1f7df7f6719b814d47a892fa74ca46b92091b. Prose only, gate green, prettier clean, no run.
Five new lines. Added: arngz reloads Hammerspoon's config and runs again once when its window filter fails (apply and discover, ARNGZ_RELOAD_TIMEOUT, exit 1, the two toasts). Changed: apply never launches an app (not running, uncounted, the toast's line of names), and apply pauses while the pointer moves, then goes on (40 points, 4 points for 2 s, 30 s, three pauses, the Paused toast). Removed: --no-launch, refused as unknown, exit 2. Fixed: discover no longer gives a desk without the windows on desktops not shown, which 2.14.10 printed or saved.
Two edits to lines already there. The toasts line drops `Skipped:`, which B removed, and gains ic's wrap of Finished's counts. ic suggested the wrap as a Fixed line, but toasts first ship in 2.15.0 (toast.lua is not at tag 2.14.10), so no release cut the counts. The I7fce35c line drops its fix words for a failed filter, which the reload line now gives.
dc checked each line against help/arngz.md, the code at 06951f03 and the ACs, and each Before against 2.14.10. WP A's line follows the probe. On your LANDED, dc removes wt-cl6d8 and dc/cl6d8 by the fold's checks.

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
