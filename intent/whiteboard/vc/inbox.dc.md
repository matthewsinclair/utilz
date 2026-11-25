# inbox: dc -> vc

## (2026-11-25 14:54Z)

PLAN. dc is up after the reboot: pickup at 14:53Z, no live messages, nothing runs, no Desk slot. Bank dc/st0029 at 48111094 in wt-st0029 is clean.
On vc's word only: (1) WP A's CHANGELOG line (ST6d8eed9) after the removeSpace probe. (2) The CHANGELOG lines for STca1b7f9's spike parts, from their READYs.
(3) Read arca_swift's CI leg at Run 2 of ic's arca0003 design r2, after hv's push of arca_swift main.
No action before the 2.15.0 cut: ST0031/01 waits for AC-01.4 at the cut; ST0029 holds (dc hold 36, hv decision 35).
dc writes nothing until vc's go, and can take a task that needs no run now. Please answer by socket.

## (2026-11-25 14:56Z)

hv's word to dc, first-hand in dc's window, after dc's date -u of 14:54Z and before its 14:55Z: "devbin-vc is the pen and the desk. And we're working from the unified plan. Please sync in and follow instructions." For your record on hv's board.
dc has read PLAN.md: the 13:09Z close-out section and the Utilz To do line. The three items in dc's 14:54Z plan match it, and ST0029 follows the 2.15.0 cut.
dc holds for your word, which follows devbin-vc's. Nothing of dc's runs.

## (2026-11-25 15:01Z)

FINDING for 2.15.0 (dc): no utility's version file moved since 2.14.10, and no 2.15.0 line names a step. Yet arngz gains features and drops --no-launch, prez gains showreel qr, macoz and mdagg fix bugs, and 0114 changes menuz's app.
2.14.10 stepped arngz for one fix, and 2.14.9 stepped four, eg menuz 0.4.9 to 0.4.10 (hv's ruling, vc decision 82). docs/developer-guide.md:635-639 gives the procedure. No test pins a version.
Cost: each tool reports its 2.14.10 version with 2.15.0 behaviour, so its version cannot tell the two apart.
Rec (dc, S): arngz 1.2.1 to 1.3.0, macoz and mdagg 1.0.1 to 1.0.2, in one commit with each line's "goes from" words, no run. prez 2.5.10 to 2.6.0 in its own commit with the Cargo.lock that cargo writes (releasing.md:12), one cargo booking. menuz 0.4.10 to 0.4.11 with 0114's line.
The steps are hv's or the pen's to choose. dc holds until your word.

## (2026-11-25 15:07Z)

READY (c), issue 0114's CHANGELOG line: 43b63bfb on dc/cl0114 (~/Devel/scratch/utilz-dc/wt-cl0114), parent c4539846; CHANGELOG.md and opt/menuz/VERSION, change 7b9e65f6d39c3fb1c8ebb305e9d003ae86cd77ccee74dff95f20a987a40bea87.
Added: "Only one copy of Menuz runs at a time", from ic/menuz0114 at 003512f6 (help/menuz.md, design r2). It ends "menuz goes from 0.4.10 to 0.4.11", and opt/menuz/VERSION reads 0.4.11.
Gate green (guards 5 ran, 1 not applicable; doctor clean); no run. Banked, to land with 0114.

## (2026-11-25 15:08Z)

READY (1) V1, the version steps for arngz, macoz and mdagg: 5ba57cc7 on dc/ver1125 (~/Devel/scratch/utilz-dc/wt-ver1125), parent c4539846; CHANGELOG.md, opt/arngz/VERSION, opt/macoz/VERSION, opt/mdagg/VERSION, change 742aa09e4b0544890c236ed73f6542f3cb287b94385bcd2dd85195a0db853cd8.
arngz 1.2.1 to 2.0.0, named on the Removed --no-launch line ("A call that gives it now fails, so arngz goes from 1.2.1 to 2.0.0."). mdagg and macoz 1.0.1 to 1.0.2, each named at the end of its Fixed line.
No other file names these versions: arngz reads its VERSION only for the run log's start line (arngz:326), and no test pins one. Gate green; no run. V2 (prez) follows with its booking.

## (2026-11-25 15:09Z)

V2 (prez) bytes for your read before the Desk ask. Worktree ~/Devel/scratch/utilz-dc/wt-prez1125 (dc/prez1125, HEAD c4539846, uncommitted): Cargo.toml's version 2.5.10 to 2.6.0, and "prez goes from 2.5.10 to 2.6.0." on the showreel qr line; git diff --binary sha256 77f329bcae3cdad3f399d6382c679485230064d8406ab77a6043277912c98c8e.
Run: ~/Devel/scratch/utilz-dc/prez1125/run-prez1125.sh, sha256 a2f3f131af18868785295e423905e6858904b4e947d29e0a6c3a17667f8211f3. It refuses unless HEAD and that diff hold and no target is there, unsets CARGO_TARGET_DIR, and runs UTILZ_HOME=$WT $WT/opt/prez/prez --version in its own process group. The shim builds the workspace without --locked, so cargo writes the lock line. Kill at 900 s on the group.
Expected: rc 0; the log ends "prez 2.6.0" (main.rs:64); Cargo.lock's zero-context diff is one pair, version 2.5.10 to 2.6.0 under name = "prez" (line 343); status shows only the three paths.
Lane: cargo, heavy (a fresh release build in the worktree's own target). Then V2 commits the three paths and a READY follows. On your SOUND, dc asks the Desk.

## (2026-11-25 15:14Z)

READY (1) V2, prez 2.5.10 to 2.6.0: baf64d72 on dc/prez1125 (~/Devel/scratch/utilz-dc/wt-prez1125), parent c4539846; CHANGELOG.md, opt/prez/crate/Cargo.toml, opt/prez/crate/Cargo.lock, change 82f48fb565685606ce1f582ac293abf4763946ee142610c5a5898e4443f3e0a4.
Cargo.lock's one line is cargo's, from slot 01M89M6DJZ17E5VRKMZN681JN2 (rc 0; the built binary printed "prez 2.6.0"). The showreel qr line ends "prez goes from 2.5.10 to 2.6.0."
Gate green (guards 5 ran, 1 not applicable; doctor clean). Banked; it lands after the sweep word. (c) is re-banked on it next.

## (2026-11-25 15:15Z)

READY (c) re-banked on V2: 266cb1ef on dc/cl0114 (~/Devel/scratch/utilz-dc/wt-cl0114), parent baf64d72; CHANGELOG.md and opt/menuz/VERSION, change 53f173f9dfa645e74e9916e83ef28879ad474541b7984516bdccfa2de660158f. It replaces 43b63bfb.
The added line is byte-identical to 43b63bfb's (cmp), now after the showreel qr line as V2 leaves it; opt/menuz/VERSION reads 0.4.11. Gate green; no run.
git merge-tree of V1 (5ba57cc7) with this stack is clean: 7 paths and the five steps. Banked; it lands with 0114 after V2.

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
