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

### WP-02 -- The recording: Chrome over the pipe, on a clock the harness controls (status: Done)

- AC-02.1 Two recordings of one reel, the second slowed in real time, write byte-identical PNG frames. The bytes compared are the captured PNGs, before the encode, because H.264 output need not match across encoder builds. -- satisfied: yes (computed)
- AC-02.2 Frames are anchored on the reel's own start. Every frame i >= 1 is taken at page time `t0 + i x 1000/fps` within 0.5 ms, where `t0` is the page time at which the player showed its first slide, and its slide index is the one the dwell schedule puts there. Frame 0 is taken when the load finishes, and the report says how late. -- satisfied: yes (computed)
- AC-02.3 Mid-transition frames sit on the player's own curve. On the known-colour fixture, each mid-fade frame's mean colour equals the incoming colour times the CSS `ease-in` progress at the frame's scheduled time, over the black ground, within 6/255 per channel. Expected values come from the player's CSS and the dwell schedule, never from a recording. -- satisfied: yes (computed)
- AC-02.4 Every image is decoded before every screenshot. The first captured frame of a slide that arrives by `cut` has its photo's own mean colour within 6/255, never a partial draw or the ground. -- satisfied: yes (computed)
- AC-02.5 Shutdown leaves nothing behind and matches nothing by name. Chrome runs in its own process group and is killed by group after a grace period, its temporary profile directory is removed on every exit path including an interrupt, and its stderr is shown only when a recording fails. -- satisfied: yes (computed)
- AC-02.6 A stall is named. A CDP reply that does not arrive within the watchdog is refused with the step that stalled, eg `during frame 63: screenshot`, and nothing is left running. -- satisfied: yes (computed)

### WP-03 -- The video verb and the encode (status: Done)

- AC-03.1 `showreel video <dir>` builds the reel into the next `_out/` slot exactly as `build` does, and writes the video beside it in the same slot, with `.html` swapped for `.mp4`. An explicit `-o` writes the video there, outside the rotation, and keeps no HTML. -- satisfied: yes (computed)
- AC-03.2 The video holds floor(D x fps) frames by ffprobe, where D is the player's own schedule. Its codec is H.264, its size is the reel's target at 16:9, it has no audio stream, and `.mov` gives the same codec in QuickTime. `--fps` takes 1 to 60 and refuses anything else by name. -- satisfied: yes (computed)
- AC-03.3 No partial file ever looks finished. The encode writes `<name>.partial` and renames it only after ffmpeg exits 0 and ffprobe's frame count equals the plan. A failing ffmpeg leaves neither the video nor the partial, and a stale partial is removed by the next run. -- satisfied: yes (computed)
- AC-03.4 A missing ffmpeg or Chrome is refused by name before any frame is captured: ffmpeg with its install line, and Chrome with `artifact::browser::find`'s own refusal, the one list of every path tried. showreel defines no browser finder of its own: no `APP_PATHS`, no `PATH_NAMES` and no `fn find`. -- satisfied: yes (computed)
- AC-03.5 `--keep N` prunes whole slots, in `build` and in `video`: a dropped revision's HTML and its video go together, and the warning past five revisions counts the videos' megabytes. -- satisfied: yes (computed)
- AC-03.6 `prez showreel video` reaches the showreel binary through the shim's hand-over, as `check` and `build` do. -- satisfied: yes (computed)
- AC-03.7 (non-test) Progress goes to stderr as `frame N/M` when stderr is a terminal, and nothing is printed before the report when it is not. -- evidence: opt/prez/crate/crates/showreel/src/main.rs video_reel: progress goes to stderr only when std::io::stderr().is_terminal(). Measured 19 Sep at --fps 5 on video.sh's fixture: under a pseudo-terminal (script -q) the verb printed 75 progress updates, frame 1/75 to frame 75/75, then the report; with stderr to a file, stderr held 0 bytes and the report went to stdout. -- satisfied: yes

### WP-04 -- The proof, the gates and the docs (status: WIP)

- AC-04.1 (non-test) CI records video on both legs. The workflow installs ffmpeg on ubuntu-latest and macos-latest, `video.sh` runs with `--strict`, and its output names the Chrome and the ffmpeg it used. A leg missing either is `unchecked`, never `not_applicable`. -- satisfied: no
- AC-04.2 (non-test) The verb is documented where prez's verbs are: `help/prez.md`, `showreel --help`, the README, and the CHANGELOG entry for 2.10.0, and `prez.yaml` declares ffmpeg as an optional dependency so doctor reports it. -- evidence: Documented where prez's verbs are, 19 Sep: help/prez.md (the showreel section gains the video paragraph, and the runtime line names its Chrome and ffmpeg), showreel --help (video and its flags, main.rs USAGE), README.md (prez's examples gain prez showreel build and video), and CHANGELOG.md's Unreleased entry, which the 2.10.0 release commit dates. prez.yaml declares ffmpeg under optional_dependencies, and with issue 0041's fix doctor reads it: with ffmpeg off PATH, utilz doctor prints Optional: 'ffmpeg' is not installed: prez showreel video encodes the recorded reel with it (declared by prez), with its install line, as information that never changes the verdict. -- satisfied: yes

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

### WP-02 -- The recording: Chrome over the pipe, on a clock the harness controls (status: Done)

_(no tests in this group)_

### WP-03 -- The video verb and the encode (status: Done)

_(no tests in this group)_

### WP-04 -- The proof, the gates and the docs (status: WIP)

_(no tests in this group)_

### Group AT23

- AT23 `opt/prez/crate/test/video.sh` -- covers AC-02.1 -- status: green -- Red first, 19 Sep: opt/prez/crate/test/video.sh, written before the verb and run at ef32951 under bash 3.2.57 with --strict, exits 1 (passed 0, failed 10) because showreel refuses unknown command 'video'. AT23 fails its two recordings, so no frames are compared. Green, WP-03, 19 Sep: video.sh --strict under bash 3.2.57 passes 10 of 10 (failed 0, skipped 0) against Chrome 153 and ffmpeg 9.0.2, at a load average of 16, in 77 s. The paced run was paused 235 times, and all 150 PNGs are byte-identical to the unhindered run's.

### Group AT24

- AT24 `opt/prez/crate/test/video.sh` -- covers AC-02.2 -- status: green -- Red first, 19 Sep: opt/prez/crate/test/video.sh, written before the verb and run at ef32951 under bash 3.2.57 with --strict, exits 1 (passed 0, failed 10) because showreel refuses unknown command 'video'. AT24 has no frames.tsv to hold to the grid. Green, WP-03, 19 Sep: video.sh --strict under bash 3.2.57 passes 10 of 10 (failed 0, skipped 0) against Chrome 153 and ffmpeg 9.0.2, at a load average of 16, in 77 s. t0 is 0 ms by frames.tsv, 150 rows, every frame from 1 on within 0.10 ms of t0 + 100i, none on a slide other than the dwell schedule's, and the report says frame 0 was taken 11 ms after the reel's start.

### Group AT25

- AT25 `opt/prez/crate/test/video.sh` -- covers AC-02.3 -- status: green -- Red first, 19 Sep: opt/prez/crate/test/video.sh, written before the verb and run at ef32951 under bash 3.2.57 with --strict, exits 1 (passed 0, failed 10) because showreel refuses unknown command 'video'. AT25 has no fade frames to hold to the ease-in curve. Green, WP-03, 19 Sep: video.sh --strict under bash 3.2.57 passes 10 of 10 (failed 0, skipped 0) against Chrome 153 and ffmpeg 9.0.2, at a load average of 16, in 77 s. Frames 51 to 55, 100 to 500 ms into the 600 ms ease-in fade over the ground #0e0e10, sit within 0.5 of a level of the curve on every channel (tolerance 6).

### Group AT26

- AT26 `opt/prez/crate/test/video.sh` -- covers AC-02.4 -- status: green -- Red first, 19 Sep: opt/prez/crate/test/video.sh, written before the verb and run at ef32951 under bash 3.2.57 with --strict, exits 1 (passed 0, failed 10) because showreel refuses unknown command 'video'. AT26 has no first frame of the photo's slide to measure. Green, WP-03, 19 Sep: video.sh --strict under bash 3.2.57 passes 10 of 10 (failed 0, skipped 0) against Chrome 153 and ffmpeg 9.0.2, at a load average of 16, in 77 s. The photo's first frame, frame 25, has mean 127 97 63, exactly the mean of the 1920x1280 JPEG the build embedded.

### Group AT27

- AT27 `opt/prez/crate/test/video.sh` -- covers AC-02.5 -- status: green -- Red first, 19 Sep: opt/prez/crate/test/video.sh, written before the verb and run at ef32951 under bash 3.2.57 with --strict, exits 1 (passed 0, failed 10) because showreel refuses unknown command 'video'. AT27 has no recording that worked, failed or was interrupted to inspect. Green, WP-03, 19 Sep: video.sh --strict under bash 3.2.57 passes 10 of 10 (failed 0, skipped 0) against Chrome 153 and ffmpeg 9.0.2, at a load average of 16, in 77 s. A clean run leaves no process, an empty TMPDIR and no Chrome output; a run failing at ffmpeg kept 2 frames first and left nothing; SIGINT exits 130 and settles within 1 s; a stall is refused "no reply from Chrome in 30 s, during frame 8: screenshot" and settles; nothing carries the run's name.

### Group AT28

- AT28 `opt/prez/crate/crates/showreel/src/cdp.rs` -- covers AC-02.6 -- status: green -- Red first, 19 Sep: cdp.rs's six tests, including a_stalled_reply_is_refused_naming_the_step, were written before the client and wired into showreel's lib, and failed to compile with 8 errors (split_messages and Session not found); cargo test exit 101. Green, WP-02, 19 Sep, rustc 1.98.1: cdp.rs's 10 tests pass, the six red ones unchanged but for one import the finished module made redundant; with record.rs's 8, base64::decode's 3 and file_url's moved test, the workspace passes 323 (artifact 34, prez 136, manifest 5, showreel 148), and clippy -D warnings and rustfmt are clean. Against Chrome 153, a 16 s reel at 10 fps gave 160 frames byte-identical at full speed and at a 0.02 s nap per frame, every frame from 1 on within 0.1 ms of t0 + 100i; a refused frame and a SIGINT each left no process and no directory behind.

### Group AT29

- AT29 `opt/prez/crate/test/video.sh` -- covers AC-03.1 -- status: green -- Red first, 19 Sep: opt/prez/crate/test/video.sh, written before the verb and run at ef32951 under bash 3.2.57 with --strict, exits 1 (passed 0, failed 10) because showreel refuses unknown command 'video'. AT29 finds no video in the _out/ slot and none at -o. Green, WP-03, 19 Sep: video.sh --strict under bash 3.2.57 passes 10 of 10 (failed 0, skipped 0) against Chrome 153 and ffmpeg 9.0.2, at a load average of 16, in 77 s. The slot holds one HTML and its .mp4 beside it with .html swapped; -o writes only the video, and _out/ still holds 2 entries.

### Group AT30

- AT30 `opt/prez/crate/test/video.sh` -- covers AC-03.2 -- status: green -- Red first, 19 Sep: opt/prez/crate/test/video.sh, written before the verb and run at ef32951 under bash 3.2.57 with --strict, exits 1 (passed 0, failed 10) because showreel refuses unknown command 'video'. AT30 probes no file, and --fps 0, 61 and x are refused as an unknown command rather than by name. Green, WP-03, 19 Sep: video.sh --strict under bash 3.2.57 passes 10 of 10 (failed 0, skipped 0) against Chrome 153 and ffmpeg 9.0.2, at a load average of 16, in 77 s. ffprobe reads h264, 1920x1080, 150 frames, no audio, brand isom; the .mov is h264 with brand qt; --fps 0, 61 and x are refused naming --fps.

### Group AT31

- AT31 `opt/prez/crate/test/video.sh` -- covers AC-03.3 -- status: green -- Red first, 19 Sep: opt/prez/crate/test/video.sh, written before the verb and run at ef32951 under bash 3.2.57 with --strict, exits 1 (passed 0, failed 10) because showreel refuses unknown command 'video'. AT31's failing ffmpeg is never reached, so the refusal does not name ffmpeg, and no run follows a stale partial. Green, WP-03, 19 Sep: video.sh --strict under bash 3.2.57 passes 10 of 10 (failed 0, skipped 0) against Chrome 153 and ffmpeg 9.0.2, at a load average of 16, in 77 s. A failing ffmpeg fails the verb with exit 2 naming ffmpeg, after 2 frames were captured, and leaves no video and no partial; the next run to the same name removes the stale partial and finishes.

### Group AT32

- AT32 `opt/prez/crate/test/video.sh` -- covers AC-03.4 -- status: green -- Red first, 19 Sep: opt/prez/crate/test/video.sh, written before the verb and run at ef32951 under bash 3.2.57 with --strict, exits 1 (passed 0, failed 10) because showreel refuses unknown command 'video'. AT32: no ffmpeg on PATH and a missing --browser are both refused as an unknown command, not by name or by artifact::browser::find's refusal, and showreel's source never calls artifact::browser::find. Green, WP-03, 19 Sep: video.sh --strict under bash 3.2.57 passes 10 of 10 (failed 0, skipped 0) against Chrome 153 and ffmpeg 9.0.2, at a load average of 16, in 77 s. No ffmpeg on PATH is refused naming ffmpeg with its install line, and a missing --browser with artifact::browser::find's own refusal and remedy, each before any frame; showreel's source has no APP_PATHS, PATH_NAMES or fn find( and calls artifact::browser::find.

### Group AT33

- AT33 `opt/prez/crate/crates/showreel/src/deliver.rs` -- covers AC-03.5 -- status: green -- Red first, 19 Sep: a_pruned_slot_takes_its_video_with_it_and_the_warning_counts_video_megabytes, written in deliver.rs before prune knew of videos, fails: --keep 1 over three slots dropped only r-001.showreel.html and r-002.showreel.html, leaving both videos; cargo test exit 101. Green, WP-03, 19 Sep: prune takes each slot's files (deliver::slot_files, the HTML with any .mp4 or .mov beside it), so --keep 1 over three slots drops two whole slots, and six slots with 1 MB videos warn of 6 MB; the workspace passes 333 tests, and clippy -D warnings and rustfmt are clean.

### Group AT34

- AT34 `opt/prez/crate/test/video.sh` -- covers AC-03.6 -- status: green -- Red first, 19 Sep: opt/prez/crate/test/video.sh, written before the verb and run at ef32951 under bash 3.2.57 with --strict, exits 1 (passed 0, failed 10) because showreel refuses unknown command 'video'. AT34: prez showreel video reaches showreel, whose refusal is the unknown command, not 'video needs a directory', and --fps is not named. Green, WP-03, 19 Sep: video.sh --strict under bash 3.2.57 passes 10 of 10 (failed 0, skipped 0) against Chrome 153 and ffmpeg 9.0.2, at a load average of 16, in 77 s. prez showreel video with no directory exits 2 with showreel's own "video needs a directory", and --fps reaches it.

### Group AT35

- AT35 `opt/prez/crate/crates/artifact/src/browser.rs` -- covers AC-01.1 -- status: green -- Red first, 19 Sep: the two discovery tests, written in artifact::browser before the code moved, failed to compile with 4 errors (find, APP_PATHS and PATH_NAMES not found); cargo test exit 101. Green, WP-01, 19 Sep, under bash 3.2.57: the two tests pass in artifact::browser (artifact 30 tests, prez 137, 302 in the workspace, as at ST0020's verdict), clippy -D warnings and rustfmt are clean, and utilz test prez passes all 4 suites, with acceptance.sh 14 of 14 on a real browser found by the moved finder.

---

_Generated by Intent v3.1.0 from the thread canon. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
