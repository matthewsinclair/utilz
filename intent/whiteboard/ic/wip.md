---
node: ic
name: Interface Claude
role: interface
session_id: 28cb7084-edb7-43ea-8d34-762c618e0583
heartbeat_at: 2026-10-19 17:39Z
status: active
focus: "19 Oct, localfolded for hv's compact (vc's decision 39, the freeze): 0086, 0083's menuz part with its fix forward, and 0091 LANDED, not pushed; 0073's diagnostic installed and its look waiting for hv; then START B and 0073's fix design; 0072 after hv's words at arca_swift. Resume from the compact hold, and ~/Devel/scratch/utilz-ic/RESUME.md."
claims: [ISSUE:0073, ISSUE:0072, ISSUE:0086, ISSUE:0091]
---

# Interface Claude (ic)

## DOING

- 0073, menuz's top row shows no icon: FIXED as 18e13a7f (19 Oct, by path, not pushed, menuz 0.4.4), on hv's word to do what Gtools does. macOS 27 draws a menu item's image only when the item asks, and GtoolsApp.drawsImage has asked since 15 Sep; menuz's row now does the same (preferredImageVisibility 1, by key). Slot 174: red 0 not 1, green 44 and 143. Slot 175: installed from main's head, build 1408; the diagnostic, wt-0073d and state-0073diag removed. hv's look at 0.4.4 shows the icon (CleanShot 2026-10-19 at 21.56.37, local time), written into the issue as d516d88. NEXT: close with 0086 and 0091 once hv's push and the dispatch's menuz-app job on Xcode 26.6 are green. (edited)

## TODO

- 0086 (medium), menuz's run-id store can be seen empty while it is being created, so a second run gets no id (found in slot 112, filed 19 Oct as 9d730f6, in 2.14.1; design approved by vc; 0.4.1 to 0.4.2 with a Fixed line). critic-swift's first review (runs/0086-critic-1.md) taken in full as the design amendment 53c7f83, approved by vc, all five points: storeMadeWhole lists the state folder inside the hold; errno saved before any string, mkostemp with O_CLOEXEC; RunId.Unreadable an enum (empty, holds, failed); the Swift 6.1 comment and the 0600 line. critic-swift's re-read (runs/0086-critic-2.md): 0 critical, 0 warning, all resolved; its one recommendation taken as point 10 (d23d7bc): the not-run line is Run.notRunLine in MenuzKit, pinned in RunTests.lines, the store's path RunId.store(in:); the script clears the xcodebuild log per run. Both worktrees on f826997. Banked: the green runs/0086-full-3.patch (938e0089, 8 files, +171 -43) in wt-0086; the red runs/0086-red-2.patch (9ad7c622) in wt-0086r; break 1 runs/0086-break1.patch. Slot 118 (13:19:25Z to 13:20:15Z): the red, rc 1 at RunnerTests.swift:123 alone. Slot 119 (13:22:49Z to 13:23:47Z): break 1, rc 1 at storeMadeWhole (:148) alone, then the green, rc 0, MenuzTests 43 and MenuzKitTests 143; the bank unchanged throughout. vc read the bytes against the design and its amendments 5 to 10, and they hold (13:27Z). Amendment 11 (the syncs, 18b9f84) read and approved by vc (13:39Z). Slot 132 (13:40:23Z to 13:41:05Z), the landing run in wt-0086L at 0e33766 (runs/0086-landing.patch, d03ad178): rc 0, MenuzTests 43 and MenuzKitTests 143. LANDED as d1fd58c (by path, not pushed, on 0e33766, 8 files, +181 -43, menuz 0.4.2), checked by change against slot 132's bytes, the SHA to vc. vc checked d1fd58c by change (13:44Z). Now: 0086's close, once hv's push is green on CI with the dispatch's menuz app job, its resolution saying in one clause that the state folder is not synced after the link, so a crash in the seconds after a first launch could lose the new store's name. Then the 0083 part. (edited)
- 0091 (low, XS, mine), menuz.bats and macos.bats skipped isolate_tool_homes. LANDED as 6316ff7 (19 Oct, by path, not pushed), on f8ba241 over 0087's 9ffc601: 4 files, +54 -9. That is both suites' isolate_tool_homes call; the red beside source_home; isolation.bats's one helper, _suites_missing_call, which 0088's teardown guard moved onto and 0091's setup() guard calls; and one CHANGELOG line under Fixed. Design and amendments: points 1 to 13 in the issue. Slot 166 (Mac, light): red 2 of 2 at their own assertions, green 1..141 on bash 3.2 and 5, the mutation (version_dispatch's utilz_teardown dropped) red and restored. dc's 167 (kovacs): utilz 313 ok with both guards, menuz 138 ok. Checked by change against c7c05cd9. NEXT: close 0091 once hv's push is green on CI. (edited)

## Holds

- 0072 (menuz adopts ArcaLogConsole, arca_swift WP-10) is mine and in 2.14.1 on hv's "Yes" (vc, 19 Oct 07:08Z). Released when gtools-ic's WP-09 (ArcaLogConsole, arca_swift 0.2.0) has fixed its shape; then its design goes into the issue for vc's read, after 0073 and 0074. (edited)
- Released: compacted and resumed (19 Oct). 0073 fixed and installed; what remains is 0072 (hold 3, after hv's words at arca_swift and gtools-ic's run id), the final gate's menuz-app phase as vc books it, and the closes of 0073, 0086 and 0091 after hv's push and the menuz-app dispatch are green. (edited)

## Watch-outs

- Landings (vc, 19 Oct 06:11Z): apply a patch only into a primary that holds no one else's uncommitted hunks. git status first, and if anything there is not mine, stop and tell vc. Every START says light or heavy (gtools-vc's terms from 06:06Z): any build, whole suite, Chrome, dry run or cut is heavy and runs alone; a light run (no build, no GUI or daemon, no port, only its own temp dirs) may share the window with one heavy run, and a failure that looks like timing beside a heavy run is rerun alone before it counts.

## Decisions

_(none)_

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
