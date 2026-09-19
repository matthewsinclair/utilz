---
st_id: ST0021
title: showreel exports a reel as a video file
---

# ST0021: showreel exports a reel as a video file -- Acceptance

> **THIS FILE IS A GENERATED VIEW, AND A ROW AUTHORED HERE IS DISCARDED BY THE NEXT SYNC.** The acceptance contract is canon in the thread model; this file renders it. Acceptance Criteria (AC) are the ratified completeness boundary; Acceptance Tests (AT) are the small red-to-green tests that prove them.
>
> Done = every AC is covered by a GREEN AT, or (for a non-test AC) its named evidence is satisfied, AND the AC set is the ratified full boundary. Done is read from this map, never from a hand-ticked box.
>
> Test-backed satisfaction is COMPUTED from covering green ATs and never stored -- storing it would be double truth. An AC has four states, not two: beyond satisfied and unsatisfied, a requirement can be **descoped** to a named thread or **withdrawn** with its reason on the record. Both are non-blocking and both are reported separately, so a thread that descoped half its contract looks like one.

## Acceptance Criteria

### WP-01 -- Browser discovery moves to the artifact crate (status: Done)

- AC-01.1 Browser discovery has one home, in the `artifact` crate, and prez's `pdf`, `present` and `browser` call it. It keeps prez's probe order (`--browser`, then the Chromium family by macOS app path, then by `PATH` name) and its refusal that lists every path tried, and prez's discovery tests pass from their new home. showreel's `video` calls the same finder, which AC-03.4 checks. -- satisfied: yes (computed)

### WP-02 -- The recording: Chrome over the pipe, on a clock the harness controls (status: WIP)

- AC-02.1 Two recordings of one reel, the second slowed in real time, write byte-identical PNG frames. The bytes compared are the captured PNGs, before the encode, because H.264 output need not match across encoder builds. -- satisfied: no (computed)
- AC-02.2 Frames are anchored on the reel's own start. Every frame i >= 1 is taken at page time `t0 + i x 1000/fps` within 0.5 ms, where `t0` is the page time at which the player showed its first slide, and its slide index is the one the dwell schedule puts there. Frame 0 is taken when the load finishes, and the report says how late. -- satisfied: no (computed)
- AC-02.3 Mid-transition frames sit on the player's own curve. On the known-colour fixture, each mid-fade frame's mean colour equals the incoming colour times the CSS `ease-in` progress at the frame's scheduled time, over the black ground, within 6/255 per channel. Expected values come from the player's CSS and the dwell schedule, never from a recording. -- satisfied: no (computed)
- AC-02.4 Every image is decoded before every screenshot. The first captured frame of a slide that arrives by `cut` has its photo's own mean colour within 6/255, never a partial draw or the ground. -- satisfied: no (computed)
- AC-02.5 Shutdown leaves nothing behind and matches nothing by name. Chrome runs in its own process group and is killed by group after a grace period, its temporary profile directory is removed on every exit path including an interrupt, and its stderr is shown only when a recording fails. -- satisfied: no (computed)
- AC-02.6 A stall is named. A CDP reply that does not arrive within the watchdog is refused with the step that stalled, eg `during frame 63: screenshot`, and nothing is left running. -- satisfied: no (computed)

### WP-03 -- The video verb and the encode (status: Not Started)

- AC-03.1 `showreel video <dir>` builds the reel into the next `_out/` slot exactly as `build` does, and writes the video beside it in the same slot, with `.html` swapped for `.mp4`. An explicit `-o` writes the video there, outside the rotation, and keeps no HTML. -- satisfied: no (computed)
- AC-03.2 The video holds floor(D x fps) frames by ffprobe, where D is the player's own schedule. Its codec is H.264, its size is the reel's target at 16:9, it has no audio stream, and `.mov` gives the same codec in QuickTime. `--fps` takes 1 to 60 and refuses anything else by name. -- satisfied: no (computed)
- AC-03.3 No partial file ever looks finished. The encode writes `<name>.partial` and renames it only after ffmpeg exits 0 and ffprobe's frame count equals the plan. A failing ffmpeg leaves neither the video nor the partial, and a stale partial is removed by the next run. -- satisfied: no (computed)
- AC-03.4 A missing ffmpeg or Chrome is refused by name before any frame is captured: ffmpeg with its install line, and Chrome with `artifact::browser::find`'s own refusal, the one list of every path tried. showreel defines no browser finder of its own: no `APP_PATHS`, no `PATH_NAMES` and no `fn find`. -- satisfied: no (computed)
- AC-03.5 `--keep N` prunes whole slots, in `build` and in `video`: a dropped revision's HTML and its video go together, and the warning past five revisions counts the videos' megabytes. -- satisfied: no (computed)
- AC-03.6 `prez showreel video` reaches the showreel binary through the shim's hand-over, as `check` and `build` do. -- satisfied: no (computed)
- AC-03.7 (non-test) Progress goes to stderr as `frame N/M` when stderr is a terminal, and nothing is printed before the report when it is not. -- satisfied: no

### WP-04 -- The proof, the gates and the docs (status: Not Started)

- AC-04.1 (non-test) CI records video on both legs. The workflow installs ffmpeg on ubuntu-latest and macos-latest, `video.sh` runs with `--strict`, and its output names the Chrome and the ffmpeg it used. A leg missing either is `unchecked`, never `not_applicable`. -- satisfied: no
- AC-04.2 (non-test) The verb is documented where prez's verbs are: `help/prez.md`, `showreel --help`, the README, and the CHANGELOG entry for 2.10.0, and `prez.yaml` declares ffmpeg as an optional dependency so doctor reports it. -- satisfied: no

### Group AT23

_(no criteria in this group)_

### Group AT24

_(no criteria in this group)_

### Group AT25

_(no criteria in this group)_

### Group AT26

_(no criteria in this group)_

### Group AT27

_(no criteria in this group)_

### Group AT28

_(no criteria in this group)_

### Group AT29

_(no criteria in this group)_

### Group AT30

_(no criteria in this group)_

### Group AT31

_(no criteria in this group)_

### Group AT32

_(no criteria in this group)_

### Group AT33

_(no criteria in this group)_

### Group AT34

_(no criteria in this group)_

### Group AT35

_(no criteria in this group)_

## Acceptance Tests

### WP-01 -- Browser discovery moves to the artifact crate (status: Done)

_(no tests in this group)_

### WP-02 -- The recording: Chrome over the pipe, on a clock the harness controls (status: WIP)

_(no tests in this group)_

### WP-03 -- The video verb and the encode (status: Not Started)

_(no tests in this group)_

### WP-04 -- The proof, the gates and the docs (status: Not Started)

_(no tests in this group)_

### Group AT23

- AT23 `opt/prez/crate/test/video.sh` -- covers AC-02.1 -- status: to-write

### Group AT24

- AT24 `opt/prez/crate/test/video.sh` -- covers AC-02.2 -- status: to-write

### Group AT25

- AT25 `opt/prez/crate/test/video.sh` -- covers AC-02.3 -- status: to-write

### Group AT26

- AT26 `opt/prez/crate/test/video.sh` -- covers AC-02.4 -- status: to-write

### Group AT27

- AT27 `opt/prez/crate/test/video.sh` -- covers AC-02.5 -- status: to-write

### Group AT28

- AT28 `opt/prez/crate/crates/showreel/src/cdp.rs` -- covers AC-02.6 -- status: to-write

### Group AT29

- AT29 `opt/prez/crate/test/video.sh` -- covers AC-03.1 -- status: to-write

### Group AT30

- AT30 `opt/prez/crate/test/video.sh` -- covers AC-03.2 -- status: to-write

### Group AT31

- AT31 `opt/prez/crate/test/video.sh` -- covers AC-03.3 -- status: to-write

### Group AT32

- AT32 `opt/prez/crate/test/video.sh` -- covers AC-03.4 -- status: to-write

### Group AT33

- AT33 `opt/prez/crate/crates/showreel/src/deliver.rs` -- covers AC-03.5 -- status: to-write

### Group AT34

- AT34 `opt/prez/crate/test/video.sh` -- covers AC-03.6 -- status: to-write

### Group AT35

- AT35 `opt/prez/crate/crates/artifact/src/browser.rs` -- covers AC-01.1 -- status: green -- Red first, 19 Sep: the two discovery tests, written in artifact::browser before the code moved, failed to compile with 4 errors (find, APP_PATHS and PATH_NAMES not found); cargo test exit 101. Green, WP-01, 19 Sep, under bash 3.2.57: the two tests pass in artifact::browser (artifact 30 tests, prez 137, 302 in the workspace, as at ST0020's verdict), clippy -D warnings and rustfmt are clean, and utilz test prez passes all 4 suites, with acceptance.sh 14 of 14 on a real browser found by the moved finder.

---

_Generated by Intent v3.1.0 from the thread canon. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
