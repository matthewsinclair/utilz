# ST0021 design: showreel exports a reel as a video file

## The answer, first

**Record the real player.** A new showreel verb builds the reel exactly as `build` does. It then opens the HTML in headless Chrome, on a clock the harness controls, captures every frame, and pipes the frames to ffmpeg.

A spike on 2026-09-19 proved the approach deterministic. The reel exercised all six keyframes and the timer-driven advance, and 510 frames came out **byte-identical** at two different real-time paces. It needs no change to `player.html` and no new crate. The one new run-time dependency is ffmpeg.

**Size: four work packages, about two working sessions after this design is reviewed.** The unknown that moved the size was the clock. It is measured and closed (see "What the spike measured").

## The three routes

| Route                         | How the frames are made                                                                          | Renderers | New dependencies                           | Verdict                                                                                                             |
| ----------------------------- | ------------------------------------------------------------------------------------------------ | --------- | ------------------------------------------ | ------------------------------------------------------------------------------------------------------------------- |
| **A. Record the real player** | headless Chrome plays `player.html` on a controlled clock; each frame is captured and piped to ffmpeg | one       | ffmpeg (Chrome is already prez's, for PDF) | **Recommended.** The video is the reel, so nothing can drift from it.                                               |
| B. Composite in Rust          | frames built with the `image` crate, then encoded                                                | two       | a font rasteriser crate, ffmpeg or an encoder crate | Conflicts with prez's spec 6, "PREZ DOES NOT PRESENT AND DOES NOT RENDER" (`src/drive.rs:3-6`), and re-implements the theme's layout. |
| C. ffmpeg filter graph        | Rust writes one filter graph (zoompan, xfade, drawtext, overlay)                                 | two       | ffmpeg                                     | Quickest to write. It is a second renderer in another language, with rougher type, and the crawl is hard.           |

B and C each put the reel's eases, transitions and crawl in a second implementation that drifts from `player.html` unless something holds the two equal (IN-AG-HIGHLANDER-001). A has one renderer by construction.

## What the spike measured

Scratch research only, with no product code. Chrome 153.0.8010.52 (new headless) and ffmpeg from Homebrew, on macOS.

- **The reel:** built by the Rust showreel as `?noloop&kiosk`. A 4 s crawl, then four gridded pictures of 3 s each at a 1200 ms ease:
  - kenburns with fade
  - kenburns-out with wipe
  - drift-l with dissolve
  - drift-r with push

  That covers all six keyframes (crawl, kb-in, kb-out, dr-l, dr-r, wipe) and the `setTimeout` advance.
- **The harness:** CDP over `--remote-debugging-pipe`: NUL-terminated JSON on fds 3 and 4, wired by `/bin/sh -c 'exec "$0" "$@" 3<&0 4>&1 0</dev/null 1>/dev/null'`. It needs no library.

What it found, in the order it was found:

1. **Under a paused clock the load event never fires.** The fix is to let virtual time run in 1 ms slices, pausing while a fetch is pending, until `Page.loadEventFired`. That cost 2 ms of virtual time.
2. **Screenshots stall under paused virtual time** unless Chrome runs with `--run-all-compositor-stages-before-draw --disable-threaded-animation --disable-threaded-scrolling --disable-checker-imaging --disable-new-content-rendering-timeout`. Without the flags, one run stalled at frame 63 and the next at frame 78; with them, none stalled.
3. **JS timers follow CDP virtual time exactly, but CSS animations and transitions do not.** Slide changes landed on 7.000 s and 10.000 s to the frame. Yet only 225 of 510 frames matched across the two paces, the fade finished early, and the crawl froze at 1.8 s.
4. **An injected clock closes the CSS side without touching `player.html`.** The script is added with `Page.addScriptToEvaluateOnNewDocument` and does three things:
   - It pauses each Web Animation the moment it exists (a `MutationObserver` on class and style) and records its start on the virtual clock.
   - Before each captured frame, it sets every animation's `currentTime` from that clock.
   - It queues `requestAnimationFrame` callbacks and runs them at the frame boundary, because Chrome fires rAF on real-time frames. This was the wipe's one remaining divergence: 32 dB at its fastest frame.
   - It rounds the clock to whole virtual milliseconds, because Chrome jitters `performance.now()`.
5. **With the clock injected, 510 of 510 frames are byte-identical** between a run at full speed and a run that slept 0.1 s of real time per frame. Every picture slide moves on every frame. Each transition takes the time and curve the player's CSS gives it:
   - The fade is `ease*.5 ease-in`: 69 of 197 red at 0.3 s, and full at 0.6 s.
   - The dissolve and the push blend across 1.2 s.
   - The wipe's bar crosses in mid-ease.
   - The crawl rises linearly and passes under the top mask at 77% of its dwell.
6. **Throughput is 18-20 frames per second** at 1920x1080 PNG. So 17 s of reel at 30 fps took 26-28 s, and a 3-minute reel takes about 5 minutes.
7. **The encode is one ffmpeg call**, frames to H.264, yuv420p, `+faststart`. ffprobe reads 510 frames at 30/1, 17.000 s, 2.3 MB.
8. **Chrome does not always exit on `Browser.close`**, so shutdown needs a kill after a grace period.

## The design (route A)

### The verb

`showreel video <dir> [-o <file>] [--fps <n>]` builds the reel's HTML as `build` does, records it, and writes the video beside it in `_out/`, as `<stem>.mp4` unless `-o` names a file. The container follows the extension (`.mp4` or `.mov`). `prez showreel video ...` reaches it through the existing hand-over to the showreel binary, as `check` and `build` do.

It prints what it made in the shape `build` already uses: the file, frames, fps, duration, size and the Chrome version that recorded it. The version is there because headless virtual-time behaviour has moved between Chrome releases (vc).

### The recording (in `crates/showreel`)

- **Browser discovery moves to one home.** prez's `drive::find` (`src/drive.rs:37`) and its refusal, which lists every path tried, move into the shared `artifact` crate. prez's `pdf` and `present` and showreel's `video` then find Chrome the same way.
- **Chrome** runs headless with `--remote-debugging-pipe` and the deterministic-rendering flags (finding 2). Its fds are wired by `/bin/sh` as the spike did, so only the standard library is used. The workspace is Unix-only by hv's ruling on ST0020.
- **CDP** is NUL-terminated JSON, read and written with serde_json, which showreel already depends on. `tests/manifest.rs` does not move.
- **The clock:**
  - CDP virtual time drives the JS side.
  - The injected script drives CSS and rAF (finding 4). It is embedded with `include_str!`, as `player.html` is.
  - The load runs in 1 ms slices until the load event (finding 1).
  - Before frame 0, the harness waits for `document.fonts.ready`.
- **The duration comes from the player.** The harness reads the player's own schedule from the page, `dwellOf` over every slide, so the reel's timing keeps one home. Frames = floor(duration x fps). The reel plays once (`?noloop`), and the last frame falls before the player's end-of-reel flash.
- **The look is kiosk**: no progress bar and no HUD, as `?kiosk` already gives. The corner bug stays, as it does on a kiosk panel (hv's question 5).
- **Screenshots** are PNG. `artifact`'s base64 gains the decode half of what it already encodes.
- **Every wait has a real-time watchdog** that names the step that stalled, as the spike's did. Shutdown is `Browser.close`, then a kill after a grace period (finding 8).

### The encode

ffmpeg is found on `PATH`, and frames are piped to it as an image sequence. `.mp4` is H.264, yuv420p, `+faststart`. `.mov` carries the same codec unless hv chooses ProRes (question 1).

**A missing ffmpeg is refused by name, with the install line, before any frame is captured.** A missing Chrome is refused as `drive::find` refuses today. Neither ever produces a partial file that looks finished (IN-AG-NO-SILENT-001).

## Questions for hv

Each has a recommendation, and every one can change without changing the route.

1. **Container and codec.** `.mp4` with H.264 is recommended as the default, because it plays everywhere. `.mov` could be H.264 in QuickTime (small) or ProRes 422 for editing (about ten times the size).
2. **Resolution.** Recommended: the reel's own `target`, 1920 wide, which gives 1080p. Should a reel with a 2560 target record at 2560x1440, or always at 1080p?
3. **Frame rate.** Recommended: 30 fps by default, with `--fps 60` as an option. 60 is smoother under Ken Burns, and doubles the recording time.
4. **Audio.** Recommended: silent, because the reel is silent. An optional soundtrack muxed by ffmpeg is a small addition later.
5. **The corner bug.** Kept as on a kiosk panel (recommended), or removed with `?nobug`?
6. **The verb's shape.** `showreel video <dir>` (recommended) or `showreel build <dir> --video`?
7. **ffmpeg as a declared run-time dependency** of the video verb, reported by doctor (recommended)? The alternative is writing a frame sequence and leaving the encode to the user.
8. **Where it runs.** On the maintainer's machine, where Chrome and ffmpeg are present. In CI, the video acceptance tests run on whichever legs carry both.

## Work packages and size

| WP  | Scope                                                                                                                                                             | Size   |
| --- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| 01  | Browser discovery moves to `artifact`; prez's `pdf` and `present` use it unchanged, and their tests move with it                                                     | small  |
| 02  | The recording: Chrome over the pipe, the CDP client, virtual time, the injected clock, the load, fonts, screenshots, the watchdog and the shutdown, with unit tests of the framing and the frame schedule | medium |
| 03  | The verb and the encode: arguments, the duration from the player, the ffmpeg pipe, the refusals, the output name, the `prez showreel video` hand-over, and help | medium |
| 04  | The proof, the gates and the docs: the acceptance tests below, doctor's report of ffmpeg, both CI legs, `help/prez.md`, README and the CHANGELOG entry            | medium |

**About two working sessions after review**, so 2.10.0 is days away rather than weeks. **The one unknown that moved the size was the clock, and the spike closed it.** Three smaller unknowns remain, and none of them is expected to move the size:
- Web fonts under virtual time.
- A large photo's asynchronous decode at the first frame of its slide.
- Linux. The spike ran on macOS only.

Each would be a change inside WP-02, and the acceptance tests on both CI legs are what find them.

## Proof that a video is faithful to its reel

Three acceptance tests, on a fixture reel whose slides are known colours:

1. **Frame count.** The video holds floor(duration x fps) frames by ffprobe, where the duration is the player's own schedule.
2. **Determinism.** Two recordings of one reel, one of them slowed in real time, are byte-identical frame by frame. The spike measured 510 of 510. This is the test that catches a Chrome release changing virtual-time behaviour.
3. **Timeline.** Each slide change lands on the frame its dwell puts it on, and mid-transition frames sit on the player's own curves.

Chrome or ffmpeg missing on a leg is `unchecked`, which reddens `--strict`, never `not_applicable`: the acceptance suite gates n/a on the platform, never on a missing tool (restart.md).

`player.html` does not change, so no regression check on the HTML reel is needed. vc's point 3 applies only if a later change makes the player seekable.

## Dependencies, per route (vc's point 4)

- **A:** Chrome (already needed by prez `pdf`) and ffmpeg at run time. Doctor reports ffmpeg for the video verb. Both CI legs need it for WP-04's tests. And ST0019's Homebrew formula carries whatever this settles.
- **B:** an encoder crate or ffmpeg, plus a font rasteriser crate. Any crate goes to hv, with `tests/manifest.rs` moved in the same commit.
- **C:** ffmpeg.
