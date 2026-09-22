---
st_id: ST0024
title: showreel: headlines fit a portrait frame, a platform safe zone, and a handle that fits at 16:9
---

# ST0024: showreel: headlines fit a portrait frame, a platform safe zone, and a handle that fits at 16:9 -- Acceptance

> **THIS FILE IS A GENERATED VIEW, AND A ROW AUTHORED HERE IS DISCARDED BY THE NEXT SYNC.** The acceptance contract is canon in the thread model; this file renders it. Acceptance Criteria (AC) are the ratified completeness boundary; Acceptance Tests (AT) are the small red-to-green tests that prove them.
>
> Done = every AC is covered by a GREEN AT, or (for a non-test AC) its named evidence is satisfied, AND the AC set is the ratified full boundary. Done is read from this map, never from a hand-ticked box.
>
> Test-backed satisfaction is COMPUTED from covering green ATs and never stored -- storing it would be double truth. An AC has four states, not two: beyond satisfied and unsatisfied, a requirement can be **descoped** to a named thread or **withdrawn** with its reason on the record. Both are non-blocking and both are reported separately, so a thread that descoped half its contract looks like one.

## Acceptance Criteria

### WP-01 -- The fit reads the longest word: headlines at portrait, handles by ink (status: WIP)

- AC-01.1 At portrait, a headline whose longest word is wider than its room is drawn on ONE line inside that room, never below the floor its own rule declares, and wraps at the floor rather than leaving the frame -- satisfied: yes (computed)
- AC-01.10 At 16:9 a headline whose INK would leave its room is fitted to it, and one that visibly fits is untouched: hv's ruling (b) of 2026-09-22, which superseded the answer AC-01.2 carried -- satisfied: yes (computed)
- AC-01.2 At 16:9 a headline is untouched: its size is the size it has with the fit off. This is hv's Q5 answer, and it is the row that fails first if Q5 is ever reversed -- WITHDRAWN: Q5 WAS REVERSED, which is what this row existed to catch. It asserted hv's first answer, that a headline is untouched at 16:9; hv ruled (b) on 2026-09-22 after the probe measured that answer's premise as false (a headline in a pane does not break mid-word at 16:9, it runs off both edges). Re-minted as AC-01.10 with the rule that replaced it, rather than edited in place, so the record carries the reversal (by cc)
- AC-01.3 A socials handle whose INK is wider than its room is fitted in any orientation, and one whose ink fits its room is untouched: a 40-capital handle at 16:9 has no glyph in the frame's outer 86 px and is still drawn, while ST0023 D3's handle, which visibly fits, does not move -- satisfied: yes (computed)
- AC-01.4 A fitted line in a grid track it shares with siblings is measured against its own SHARE of that track, not against the row's width nor against its own grown box, proven on a points slide and a crawl row with a long word at both orientations (design D2b) -- satisfied: yes (computed)
- AC-01.5 Every fitted rule declares its floor once: every fitted selector carries a --fit-floor its clamp reads, and no floor is written in both the stylesheet and the script -- satisfied: yes (computed)
- AC-01.6 The fit is idempotent and is re-run once the face has settled: a second fit gives the same size as the first, so frames cannot move between runs -- satisfied: yes (computed)
- AC-01.7 Fitted lines matching one rule under one parent share the smallest size any of them needs, so a row of points or a strapline's lines are never drawn at two sizes -- satisfied: yes (computed)
- AC-01.8 THE CONTROL: a 16:9 recording of a reel whose lines all fit is byte-identical, frame for frame, to the same recording made before this thread -- WITHDRAWN: Re-minted as AC-01.9, a non-test row: the control compares a recording against one made by a PRE-THREAD binary, which no suite can rebuild, so it is satisfied by evidence as ST0023's byte check was. The requirement is unchanged (by cc)
- AC-01.9 (non-test) THE CONTROL: this thread does not move a 16:9 recording of a reel whose lines all fit. Measured against the pre-thread binary, and against Chrome's OWN run-to-run variation, since a claim of byte-identity that no change could satisfy is not a criterion -- evidence: cc, 22 Sep: 25 of 75 widescreen frames differ by one channel sample of 1 at one pixel, and the same build recorded twice differs identically, so this thread moved nothing; AT01's nothing-written pass asserts the mechanism over every reel rather than this one -- satisfied: yes

### WP-02 -- The platform safe zone, and everything type inside it (status: WIP)

- AC-02.1 The flag --safe-zone and the key safe_zone: parse through one function, the flag wins, a bad value is refused by name at config parse so check and build refuse it too, and a frame wider than it is tall is refused naming both -- satisfied: yes (computed)
- AC-02.2 With --safe-zone social at portrait, no type or mark has ink in the zone's four bands, where the same recording without the zone does, and pictures still bleed to the frame's edge -- satisfied: yes (computed)
- AC-02.3 A cap measured against the frame's height reads the zone box instead, so the at-work card and the social QR sit inside the shortened zone rather than overflowing it -- satisfied: yes (computed)
- AC-02.4 THE CONTROL: with no zone, a portrait recording is byte-identical, frame for frame, to the same recording made before this thread -- WITHDRAWN: Re-minted as AC-02.6, a non-test row, for the same reason as AC-01.8 (by cc)
- AC-02.5 (non-test) vc reads a 9:16 recording of Snorkeltoast 001 with the zone and without it, one frame per segment type, and finds no type or mark cut by the zone's bands and nothing illegible at phone size -- satisfied: no
- AC-02.6 (non-test) THE CONTROL: with no zone, this thread does not move a portrait recording of a reel whose lines all fit, measured against the pre-thread binary -- evidence: cc, 22 Sep: 0 of 75 portrait frames differ between 504825a~1 and 504825a on a reel whose lines all fit -- satisfied: yes

### Group AT01

_(no criteria in this group)_

### Group AT02

_(no criteria in this group)_

### Group AT03

_(no criteria in this group)_

### Group AT04

_(no criteria in this group)_

### Group AT05

_(no criteria in this group)_

### Group AT06

_(no criteria in this group)_

### Group AT07

_(no criteria in this group)_

### Group AT08

_(no criteria in this group)_

## Acceptance Tests

### WP-01 -- The fit reads the longest word: headlines at portrait, handles by ink (status: WIP)

_(no tests in this group)_

### WP-02 -- The platform safe zone, and everything type inside it (status: WIP)

_(no tests in this group)_

### Group AT01

- AT01 `opt/prez/crate/test/video.sh` -- covers AC-01.1, AC-01.10, AC-01.3, AC-01.4, AC-01.5, AC-01.6, AC-01.7 -- status: green -- The player probe over CDP (test/fit-probe.mjs), driven by video.sh: measures the fit in the DOM at 540x960 and at 960x540. RED FIRST, genuinely: the first run reported that the player exposes no window.__showreelFit, so the fit could not be measured at either orientation. GREEN at hv's ruling (b): portrait 98/98, landscape 101/101, and over a reel whose lines all fit the probe asserts the fit wrote NOTHING -- 33/33 at each orientation. It caught two defects a pixel test passes: a word measured from a transformed rect (not idempotent under the crawl) and a room read inside out (a handle fitted to a row already grown past its pane)

### Group AT02

- AT02 `opt/prez/crate/test/video.sh` -- covers AC-01.3 -- status: green -- The 16:9 recording: a 40-capital handle has no glyph in the frame's outer 86 px and is still drawn. RED PROVEN RETROSPECTIVELY (restart.md's remedy for a block written after the code), by running it against HEAD's player in this tree and restoring it: 2743 and 2807 glyph pixels in the outer 86 px. GREEN at the fit: 0 and 0, the handle drawn at 41950 px inside the margin

### Group AT03

- AT03 `opt/prez/crate/test/video.sh` -- covers AC-01.1 -- status: green -- The portrait recording: the headline is drawn on one line with no glyph in the outer 20 px. RED PROVEN RETROSPECTIVELY, same run against HEAD's player: 880 and 642 glyph pixels in the outer 20 px. GREEN at the fit: 0 and 0, the headline drawn at 43415 px inside the margin

### Group AT04

- AT04 (non-test) By hand, as ST0023 did, and the exact run is in the note: the same reel recorded by the pre-thread binary and by the built one, compared frame by frame with cmp, and then the SAME build recorded twice to separate this thread's effect from Chrome's own -- covers AC-01.9 -- status: n/a -- Reel: three type-only slides (card, socials each, wordmark), every line short enough to fit. Built at 504825a and at 504825a~1 by checking out that player and rebuilding --workspace. Command each time: showreel video <reel> --browser <Chrome> --fps 10 --aspect widescreen --frames <dir>, 75 frames. Compared with cmp per frame. RESULT: 25 of 75 frames differ, every one by a SINGLE channel sample of 1 at x=877 y=540 (blue), inside the card headline's edge. The same build recorded TWICE differs in the same 25 frames, at the same pixel, by the same 1, so the difference is Chrome's own rasterisation of that glyph edge and not this thread's. Portrait: 0 of 75 frames differ. The mechanism behind the claim is asserted instead by AT01's nothing-written pass

### Group AT05

- AT05 `opt/prez/crate/crates/showreel/src/zone.rs` -- covers AC-02.1 -- status: green -- The names in any case, every refusal, the landscape refusal, and safe_zone: read and refused at config parse. RED by construction: zone.rs did not exist, and every test in it named a type the crate had no path to. GREEN: cargo test -p showreel 179 passed, 0 failed, up from 176

### Group AT06

- AT06 `opt/prez/crate/test/video.sh` -- covers AC-02.2, AC-02.3 -- status: green -- The portrait recording with --safe-zone social, against the same reel without it. RED before the zone existed: --safe-zone was refused as an unknown video option, so the recording this block reads could not be made at all. GREEN: 0 glyph pixels in each of the zone's four bands, 16080 inside the zone, and the control without the zone carries 410 left and 1646 right

### Group AT07

- AT07 (non-test) By hand: the portrait fixture with no zone, recorded by the pre-thread binary and by the built one, compared frame for frame -- covers AC-02.6 -- status: n/a -- The same two recordings at --aspect portrait, 75 frames each, compared with cmp: 0 frames differ between the pre-thread binary and the built one

### Group AT08

- AT08 (non-test) vc reads one frame per segment type from a 9:16 recording of Snorkeltoast 001, with the zone and without it -- covers AC-02.5 -- status: n/a

---

_Generated by Intent v3.2.0 from the thread canon. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
