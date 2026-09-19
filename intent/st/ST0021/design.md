# ST0021 design: showreel exports a reel as a video file

## The answer, first

**Record the real player.** A new showreel verb builds the reel exactly as `build` does. It then opens the HTML in headless Chrome, on a clock the harness controls, captures every frame, and pipes the frames to ffmpeg.

A spike on 2026-09-19 proved the approach deterministic. The reel exercised all six keyframes and the timer-driven advance, and 510 frames came out byte-identical at two different real-time paces. It needs no change to `player.html` and no new crate. The one new run-time dependency is ffmpeg.

**hv approved it on 2026-09-19** (decision 7: "Ok, ST0021 looks good, you and CC should crack on and build it"), taking each question's recommendation as its answer. vc's review added ten notes, and they are folded in below.

**Size: four work packages, about two working sessions of build.** **Recording runs at 18-20 frames per second on a lightly loaded machine, and at 7 frames per second on this one at a load average of 400-500.** So a 3-minute reel takes 5 to 12 minutes to record. This sentence said 5 minutes until vc's review: it quoted the light-load rate as the only one.

## The three routes

| Route                         | How the frames are made                                                                               | Renderers | New dependencies                                    | Verdict                                                                                                                               |
| ----------------------------- | ----------------------------------------------------------------------------------------------------- | --------- | --------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| **A. Record the real player** | headless Chrome plays `player.html` on a controlled clock; each frame is captured and piped to ffmpeg | one       | ffmpeg (Chrome is already prez's, for PDF)          | **Chosen.** The video is the reel, so nothing can drift from it.                                                                      |
| B. Composite in Rust          | frames built with the `image` crate, then encoded                                                     | two       | a font rasteriser crate, ffmpeg or an encoder crate | Conflicts with prez's spec 6, "PREZ DOES NOT PRESENT AND DOES NOT RENDER" (`src/drive.rs:3-6`), and re-implements the theme's layout. |
| C. ffmpeg filter graph        | Rust writes one filter graph (zoompan, xfade, drawtext, overlay)                                      | two       | ffmpeg                                              | Quickest to write. It is a second renderer in another language, with rougher type, and the crawl is hard.                             |

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

1. **Under a paused clock the load event never fires.** The fix is to let virtual time run in 1 ms slices, pausing while a fetch is pending, until `Page.loadEventFired`. The load cost 10 ms of page time. The harness's slice count said 2, which is why the page's own clock, not the count, is what gets read (finding 9).
2. **Screenshots stall under paused virtual time** unless Chrome runs with `--run-all-compositor-stages-before-draw --disable-threaded-animation --disable-threaded-scrolling --disable-checker-imaging --disable-new-content-rendering-timeout`. Without the flags, one run stalled at frame 63 and the next at frame 78; with them, none stalled.
3. **JS timers follow CDP virtual time exactly, but CSS animations and transitions do not.** Slide changes landed on 7.000 s and 10.000 s to the frame. Yet only 225 of 510 frames matched across the two paces, the fade finished early, and the crawl froze at 1.8 s.
4. **An injected clock closes the CSS side without touching `player.html`.** The script is added with `Page.addScriptToEvaluateOnNewDocument` and does three things:
   - It pauses each Web Animation the moment it exists (a `MutationObserver` on class and style) and records its start on the virtual clock.
   - Before each captured frame, it sets every animation's `currentTime` from that clock.
   - It queues `requestAnimationFrame` callbacks and runs them at the frame boundary, because Chrome fires rAF on real-time frames. This was the wipe's one remaining divergence: 32 dB at its fastest frame.
   - It rounds the clock to whole virtual milliseconds, because Chrome jitters `performance.now()`.
5. **With the clock injected, 510 of 510 frames are byte-identical** between a run at full speed and a run that slept 0.1 s of real time per frame. A third recording, made later in a separate Chrome, matched on all of the first 180 frames. Every picture slide moves on every frame.
6. **Throughput depends on the machine's load, not on the shim.** With the flags and the shim:

   | Capture                                   | Rate     | 1-minute load average |
   | ----------------------------------------- | -------- | --------------------- |
   | Plain PNG                                 | 18.2 fps | about 60              |
   | PNG with `optimizeForSpeed`               | 20.1 fps | about 60              |
   | The recording whose frames were compared  | 7.3 fps  | 400-500               |

   `optimizeForSpeed` is not adopted, because the determinism check has not been run on it.

7. **The encode is one ffmpeg call**, frames to H.264, yuv420p, `+faststart`. ffprobe reads 510 frames at 30/1, 17.000 s, 2.3 MB.
8. **Chrome does not always exit on `Browser.close`**, so shutdown needs a kill after a grace period.
9. **THE CURVE IS EXACT, AND THE FRAMES WERE 10 MS LATE.** A per-frame probe read the page's own state:
   - **The curve.** The incoming slide's computed opacity equals the CSS `ease-in` curve at the transition's own `currentTime`, to four decimal places, on every frame of the fade.
   - **The start.** The reel started at page time 0.0. Frame 0 was taken at page time 10 ms, the load's cost, so every frame showed the reel 10 ms later than i/fps.
   - **What the mean colour showed.** vc's review read the reel as about 19 ms ahead. That was the 10 ms phase, plus about 3 of 197 levels of colour maths in ffmpeg's area mean.
   - **The consequence.** The phase sat in every transition, and the determinism check could not see it, because both runs shared it. It is why the design anchors frames on the reel's own start, and why the proof has a phase test.

## The design (route A)

### The verb

`showreel video <dir> [-o <file>] [--fps <n>] [--keep <n>] [--frames <dir>] [--browser <path>]`, and `prez showreel video ...` through the shim's existing hand-over (`opt/prez/prez:290`). As built (WP-03), `-o` is also spelled `--out`, as `build` spells it.

- **What it writes.** It builds the reel's HTML exactly as `build` does, into the next `_out/` slot (`build.rs:242`, `deliver.rs:218`). It then writes the video **beside it, in the same slot**: the HTML's name with `.html` swapped for `.mp4`. A slot is therefore one revision, holding the HTML and the video recorded from it.
- **An explicit `-o <file>`** writes the video there. Like `build --out`, it is outside the rotation and prunes nothing. The HTML is built into the recording's own temporary directory (`record::Scratch`), because the caller named only the video, so it goes on every path the profile does, an interrupt included.
- **`--keep N` prunes whole slots**, in `build` and in `video`: a dropped revision's HTML and its video go together. The warning past five revisions (`deliver.rs:349`) counts the videos' megabytes, because a 3-minute 1080p video is about 24 MB.
- **The container follows the extension.** `.mp4` is H.264 (hv's answer 1). `.mov` is H.264 in QuickTime.
- **The size is the reel's `target`** by its 16:9 height: 1920 gives 1920x1080 and 2560 gives 2560x1440 (hv's answer 2).
- **`--fps`** is 30 by default. It takes any whole number from 1 to 60 and refuses anything else by name (hv's answer 3).
- **The video is silent** (hv's answer 4).
- **The look is kiosk:** no progress bar and no HUD. The corner bug stays, as on a kiosk panel (hv's answer 5).
- **`--frames <dir>`** also writes every captured PNG, and a `frames.tsv` of frame index, page time and slide index. It is what the determinism and phase tests read, and it is a frame-sequence export for anyone who wants one. As built, the directory must be new or empty, and `frames.tsv` opens with a `# t0_ms=<t0> fps=<n>` line, then a header row, so the phase check has the player's own start. A frame is kept before ffmpeg takes it, so an encode that fails still leaves what was captured.
- **`--browser <path>`** names the browser, through `artifact::browser::find`, so a missing one is refused with the finder's own refusal, word for word what prez's is.
- **Progress goes to stderr when stderr is a terminal** (`std::io::IsTerminal`), as `frame N/M`. At 5 to 12 minutes for a 3-minute reel, silence would read as a hang. When stderr is not a terminal, nothing is printed until the end.
- **The report** at the end uses `build`'s shape: the file, frames, fps, duration, size, the Chrome version that recorded it, and how late frame 0 was taken. As built, on `video.sh`'s fixture at `--fps 5`:

  ```
  showreel: wrote <file>
    75 frames at 5 fps, 15.0 s, 1920x1080, 0.4 MB, recorded by Chrome/153.0.8010.52
    frame 0 taken 11 ms after the reel's start
  ```

### The recording (in `crates/showreel`)

- **Browser discovery moves to one home.** prez's `drive::find` (`src/drive.rs:37`) and its refusal, which lists every path tried, move into the shared `artifact` crate. prez's `pdf` and `present` and showreel's `video` then find Chrome the same way.
- **Chrome** runs headless with `--remote-debugging-pipe` and the deterministic-rendering flags (finding 2). A temporary `--user-data-dir` is used, and the window is the video's size.
  - A `/bin/sh` wrapper wires fds 3 and 4, as the spike did, so only the standard library is used. The workspace is Unix-only by hv's ruling on ST0020.
  - The wrapper does not `exec`. It waits for Chrome, and its `EXIT` trap removes the profile directory (see "Shutdown").
- **CDP** is NUL-terminated JSON, read and written with serde_json, which showreel already depends on. `tests/manifest.rs` does not move.
- **Where it lives, as built (WP-02).** `crates/showreel/src/cdp.rs` is the pipe: a reader thread, the watchdog and the refusals. `record.rs` is Chrome, the clock and the shutdown. `clock.js` sits beside `player.html` and is embedded the same way.
- **The clock:**
  - CDP virtual time drives the JS side.
  - The injected script drives CSS and rAF (finding 4). It is embedded with `include_str!`, as `player.html` is.
  - **As built, the harness hands each tick its frame's scheduled time**, and the script sets every animation from that number rather than from a clock read. Chrome jitters `performance.now()`, so a rounded read could round two runs differently at some frame rates. The script still rounds the one read it makes, when a timer starts an animation, because timers fire on whole virtual milliseconds.
  - The load runs in 1 ms slices until the load event (finding 1).
- **Frames are anchored on the reel's own start** (finding 9):
  - After the load, the harness reads the page time at which the player showed its first slide (the player's `t0`) and the page's current time.
  - It then steps so that frame i is taken at page time `t0 + i x 1000/fps`.
  - Only frame 0 is off that grid. It is taken when the load has settled, and the report states how late: 11 ms on the spike's reel.
  - **The load is settled by one 1 ms advance before the page's time is read** (measured in WP-02 on Chrome 153). Once loaded, the page read 2 ms, and a first advance of 1, 5, 20 or 98 ms landed at 11, 15, 30 or 108: 8 ms past the page's own clock. Every advance after the first landed exactly. 300 frames of 30 fps budgets ended on 10011 ms, 11 + 10000, and a 10 fps recording put every frame from 1 on within 0.1 ms of `t0 + 100i`.
  - **Budgets are whole microseconds plus a quarter.** Chrome converts a budget to whole microseconds. Adding a quarter of one lands the conversion on the intended microsecond whether Chrome truncates or rounds, so a long reel cannot drift off its grid.
- **The duration comes from the player.** The harness reads the player's own schedule from the page, `dwellOf` over every slide, so the reel's timing keeps one home. Frames = floor(duration x fps). The reel plays once (`?noloop`), so the last frame falls before the player's end-of-reel flash.
- **Every image is decoded before every screenshot.** The tick awaits `decode()` on every `<img>` in the document, so a large photo cannot be captured half-drawn (vc's note 4, closed by construction). A picture that fails to decode is refused, naming the frame. Before frame 0, the harness also waits for `document.fonts.ready`.
- **Screenshots** are PNG. `artifact`'s base64 gains the decode half of what it already encodes.
- **Every wait has a real-time watchdog** that names the step that stalled, eg `no reply from Chrome in 30 s, during frame 63: screenshot`.

### Shutdown

**The spike's `pkill -f spike-chrome-` is issue 0030's trap, and it does not carry over.** Nothing is ever matched by name.

- **Chrome's process group.** The wrapper and Chrome run in their own process group (`CommandExt::process_group(0)`, standard library). Shutdown is `Browser.close`, then, after a grace period, `kill -KILL -- -<pgid>` on that group alone.
- **The profile directory** is removed by the harness on every path it runs, normal or failed.
- **After an interrupt, which runs no Rust code, the wrapper ends Chrome itself.** It polls its own parent, which changes the moment showreel dies. It then gives Chrome 2 s, sends TERM to the group, which it alone ignores, and KILLs Chrome's main process. Its `EXIT` trap removes the directory and KILLs whatever is left of the group. As first built (b1e2864), the wrapper trusted Chrome to exit when its pipe closed. vc measured 10 of 10 interrupts leaving Chrome's main process idling in its own shutdown, with the profile behind. Killing only the main process then left a helper alive past 10 s at a load average of 580.
- **Chrome's stderr** is read into memory, its last 4 KB kept, and shown with a refusal, never on success and never spilled into the terminal. As built it is not a file in the temporary directory, as this line first said: an interrupt would have left that file behind, and the trap would have removed it before a failure could show it.
- **Chrome's temporary files, its process singleton among them, go in the scratch directory too.** Headless Chrome makes a singleton directory in its temporary directory, `com.google.Chrome.XXXXXX` on macOS, holding the `SingletonSocket` that a symlink in the profile points at. Both `TMPDIR` and `MAC_CHROMIUM_TMPDIR` name the scratch directory, because they fail differently:
  - **macOS Chrome ignores `TMPDIR`** and reads `MAC_CHROMIUM_TMPDIR`. Before both were set, every recording that ended in a kill left its singleton directory in the system's temporary directory. That directory held 664 Chrome entries, 523 of them made in one day of testing, singleton directories among them.
  - **Linux Chrome honours `TMPDIR`, and a socket's path must fit `sun_path`**: 108 bytes on Linux and 104 on macOS, the NUL included. Under `video.sh`'s nested `TMPDIR` the path reached about 117 bytes, and Chrome exited at its start. CI's first Linux run (35466064642) reported that as "Chrome closed the DevTools pipe during the start" on every recording.
  - So the scratch directory's base is at most 36 bytes, falling back to `/tmp`, and its name is `showreel-<pid>-<n>`. The socket's path is then at most 103 bytes for any of the four browsers the finder takes.
  - Measured on macOS after the fix: a full `video.sh` run, which kills Chrome on three paths, added nothing to the system's temporary directory (664 Chrome entries before and after, counting every name). AT27 finds the socket itself inside the recording's scratch directory, with `find -type s`: the profile's symlink, found by name alone, is there even when the socket is stranded (vc's review of 22a26b8).
- **Measured in WP-02 on Chrome 153.** Every Chrome process, the main one and its ten helpers, ran in the wrapper's process group. A recording refused mid-way left no process and no directory. With the wrapper ending Chrome, 4 of 4 interrupts settled within 5 s, with no process and an empty TMPDIR. The single clean interrupt measured before the fix was luck, not evidence. After a clean close, the group's only member is the exited, unreaped wrapper, and `kill` of it reports EPERM on macOS, which is not reported. Checked directly: a live group is killed, a zombie-only group gives EPERM, and a reaped one gives ESRCH.

### The encode

**ffmpeg** is found on `PATH` and is spawned in its own process group, with frames piped to it as an image sequence. `.mp4` is H.264, yuv420p, `+faststart`, and so is `.mov`, in QuickTime. As built, its stderr is kept as Chrome's is (`tail.rs`), and shown only with a refusal.

**NO PARTIAL FILE EVER LOOKS FINISHED.**

- **The temporary name.** ffmpeg writes `<name>.partial`, with the format named explicitly, because ffmpeg would otherwise infer it from the extension.
- **The rename** to the final name happens only after both of these hold:
  - ffmpeg exits 0.
  - ffprobe's frame count equals the plan's.
- **Cleanup.** Every failure path the harness sees deletes the partial file. An interrupt can leave only a `.partial`, never the finished name, and the next `video` run in that reel removes it before it starts.

**Missing tools are refused by name before any frame is captured.** A missing ffmpeg is refused with the install line. A missing Chrome is refused as `drive::find` refuses today (IN-AG-NO-SILENT-001).

## hv's answers (decision 7)

hv took each recommendation as its answer:

1. `.mp4` with H.264 by default, and `.mov` as H.264 in QuickTime.
2. The reel's `target` width at 16:9.
3. 30 fps by default, with `--fps`.
4. Silent.
5. The corner bug kept, as on a kiosk panel.
6. `showreel video <dir>`.
7. ffmpeg declared, as an optional dependency of prez (`prez.yaml` `optional_dependencies`), so doctor reports it.
8. Run on the maintainer's machine. In CI, the workflow installs ffmpeg on both legs, and the video tests run on both.

hv can change any one of these without changing the route.

## Work packages and size

| WP  | Scope                                                                                                                                                                                                       | Size   |
| --- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| 01  | Browser discovery moves to `artifact`; prez's `pdf` and `present` use it unchanged, and their tests move with it                                                                                            | small  |
| 02  | The recording: Chrome over the pipe, the CDP client, virtual time, the injected clock, the anchoring on `t0`, the image decode, fonts, screenshots, the watchdog and the shutdown                            | medium |
| 03  | The verb and the encode: arguments, the slot and `--keep`, `-o`, `--frames`, the duration from the player, the `.partial` and the rename, the refusals, progress, and the `prez showreel video` hand-over | medium |
| 04  | The proof, the gates and the docs: `crate/test/video.sh`, `prez.yaml`'s optional ffmpeg, the workflow's ffmpeg on both legs, `help/prez.md`, the README and the CHANGELOG entry                               | medium |

About two working sessions of build. Each WP goes red first and is verified by vc as it lands.

**Two unknowns remain.** Each would be a change inside WP-02, and `video.sh` on both CI legs is what finds it:

- **Web fonts under virtual time.** The fonts wait is in the design, but no fixture has exercised it yet.
- **Linux.** The spike ran on macOS only.

## Proof that a video is faithful to its reel

`crate/test/video.sh`, discovered by the test driver's `crate/test/*.sh` convention and run with `--strict`.

**The fixture** is generated at test time, so nothing binary is committed:

- A crawl, then four known-colour gridded pictures with fade, wipe, dissolve and push. That is every transition and all six keyframes.
- A sixth slide, a generated 6000x4000 photo, arrives by `cut`, so its first frame has nothing to blend with. `build` sizes it down to the target, as it does every picture, so what is decoded is a full-size target JPEG.
- Every slide sits at the 2500 ms dwell floor, with a 1200 ms ease.
- It is recorded at `--fps 10`, which keeps CI short: 150 frames per recording.

**Every expected value comes from the player's CSS and the dwell schedule, never from a recording** (vc's note 3). The tolerances are fixed here, before the first green:

1. **Frame count.** The video holds floor(duration x fps) frames by ffprobe, where the duration is the sum of the dwell floor over the slides. The codec, the size and the absence of an audio stream match the extension and the target.
2. **Determinism.** Two recordings, the second sleeping 0.02 s of real time per frame, write byte-identical PNGs to `--frames`. **The bytes compared are the captured PNGs, before the encode**, because H.264 output need not match across encoder builds.
3. **Phase.** In `frames.tsv`, every frame i >= 1 is at page time `t0 + i x 1000/fps` (100 ms apart at the fixture's 10 fps) within 0.5 ms, the shim's rounding. Its slide index is the one the dwell schedule puts there.
4. **Curve.** The mid-fade frames' mean colour equals the incoming colour times the CSS `ease-in` progress at the frame's scheduled time, over the black ground, within 6/255 per channel.
   - The spike's colour maths cost 3.3.
   - The phase error the review suspected cost 4 on its own. A one-frame slip costs more than 12, so it is caught.
   - The phase test is the exact check. This one catches a capture that lags its own clock.
5. **The photo.** The first captured frame of the photo's slide has the photo's own mean colour within 6/255, as `build`'s normalised JPEG measures it: the whole photo, not a partial draw or the black ground.
6. **The tools.** The test output names the Chrome and the ffmpeg it used, as the acceptance suite names its browser today. A leg with either missing is `unchecked`, which reddens `--strict`, and never `not_applicable` (restart.md: n/a is gated on the platform, never on a missing tool).

`player.html` does not change, so no regression check on the HTML reel is needed. vc's point 3 applies only if a later change makes the player seekable.

## Dependencies

Chrome, already needed by prez `pdf`, and ffmpeg, both at run time.

- ffmpeg is an optional dependency of prez, so doctor reports it.
- Both CI legs install it for `video.sh`.
- ST0019's Homebrew formula carries whatever this settles.
- No crate is added.
