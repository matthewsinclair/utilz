# ST0022 design: showreel video at a chosen aspect ratio

hv, 2026-09-21, through vc, needed today and ahead of the 2.11.0 cut: `showreel video` must record portrait and square reels for TikTok and Instagram. Today it cannot, because `video.rs:112` sizes every recording with `sixteen_nine(built.target)` (`video.rs:283`).

## D1. The ask

- The ratio is given as `W:H` or by name, with `--aspect` on the command line and `aspect:` in `showreel.yaml`. **The flag wins.**
- **The default stays 16:9**, so every existing reel records byte for byte as it does now.
- The names are `widescreen` 16:9 (the default), `portrait` 9:16, `square` 1:1 and `feed` 4:5, and `W:H` is always accepted too (hv, 2026-09-21, vc's decision 13).

## D2. The size rule

**`target` stays the long edge, and the short edge follows from the ratio.** Both are even, as H.264's 4:2:0 chroma needs.

| Aspect | At target 1920 | At target 2560 |
| ------ | -------------- | -------------- |
| 16:9   | 1920x1080      | 2560x1440      |
| 9:16   | 1080x1920      | 1440x2560      |
| 1:1    | 1920x1920      | 2560x2560      |
| 4:5    | 1536x1920      | 2048x2560      |

The long edge is `target & !1`, and the short edge is `long * short / long_ratio`, floored and then made even. That is `sixteen_nine`'s arithmetic, so 16:9 cannot move. `sixteen_nine` goes, and one function sizes every ratio.

## D3. Parsing and refusals

- A ratio is two positive whole numbers joined by `:`, or one of the four names. Case is ignored.
- **A value that is neither is refused, naming it**: a zero side, a missing side, a non-number, a fraction. The refusal lists the four names and gives `eg --aspect 9:16`.
- **A ratio outside 1:4 to 4:1 is refused**, because the player was never laid out for a strip that shape and the short edge would be too small to read.
- The yaml value is checked when the config is parsed, so `showreel check` and `build` refuse a bad `aspect:` too, not only `video`. A recording never starts on a value that was always going to fail.

## D4. Where it lives

- **`aspect.rs`, one pure module**: the type, its parse and the size rule. Nothing in it reads a file or runs a process.
- `config.rs`: `Reel.aspect: Option<Aspect>`, parsed through the same function as the flag, so the two cannot accept different spellings.
- `build.rs`: `Built` carries the reel's `aspect` beside `target`. The HTML does not change, because the player already lays itself out from the window it is given.
- `main.rs`: `--aspect <ratio>` in `video_flags`, and in the help text.
- `video.rs`: the size is `aspect.size(built.target)`, where the aspect is the flag's, else the yaml's, else 16:9. The summary line already prints the size.

## D5. The player, which is the real risk

The size math is small. What decides whether a 9:16 reel is usable is whether every segment reads, inside the safe area, in a tall frame.

- **What is there already**: `player.html` lays out tall windows under `@media (orientation:portrait)` (`:466`). Points and the at-work body stack, `fit: cover` becomes `contain` on a blurred copy of the same picture (a ground `buildImage` already paints, `:590`), and Ken Burns is switched off (`:483`), because its 1.2% upward drift pulls the picture off its ground.
- **The pictures assume no orientation.** `normalise` fits each picture's own long edge to the role's edge and never enlarges, and the payload carries each picture's `w` and `h`. Nothing in the build assumes a landscape frame.

### D5a. Portrait and square record at the handset layout

**A frame no wider than it is tall (9:16, 1:1, 4:5, or any such W:H) is recorded at `deviceScaleFactor: 2` over a CSS viewport half its size. Widescreen stays at 1, so 16:9 does not move.** The frame keeps its pixels, because Chrome's screenshot is in device pixels. The change is in `record`'s metrics and needs nothing in the player.

The reason is arithmetic. The handset rules sit under `max-width:820px` (`:433`). A 1080-wide recording at scale 1 misses them and gets the television type: the socials kicker is `1.5vw`, 16 px of 1080, which on a phone about 390 points wide is about 6 points and cannot be read. At scale 2 the page is 540 wide, the handset rules apply, the safe area drops to 2.4%, and every clamp's floor doubles in the frame.

### D5b. A landscape gallery picture in a portrait frame: contain, on its ground

A 1080x1920 frame, with vc's two cases:

| Picture                      | `cover`                                                               | `contain`                                             |
| ---------------------------- | --------------------------------------------------------------------- | ----------------------------------------------------- |
| 5608x3536 hero (1920x1211)   | the centre 35% of the width; about two thirds of the painting cut off | whole, 1080x681, a third of the frame's height        |
| 1024x768 in-store photo      | enlarged 2.5 times, the centre 42% of the width, visibly soft         | whole, 1080x810, enlarged 1.05 times                  |

**`contain` on the blurred ground, which is what the player already does.** The painting is the point, and `cover` shows a third of it. It also enlarges a small photo until it is soft. The ground fills the bars with the picture's own colour, not a flat band.

**Ken Burns comes back in portrait as a zoom only**, 1.00 to 1.06 about the centre, with no drift. A zoom about the centre keeps the picture on its ground, where the drift did not, and a gallery that does not move at all is dead on a phone. This is the one player change. It applies to any tall window, a phone's browser included, where the same reasoning holds.

**The venue slide follows the same rule** (vc's ruling after the 9:16 pass of 001). Its shop photograph was `cover`, and in portrait the crop cut the shop's own sign to "ernation". So in portrait it is contained on a blurred copy of itself too, with the same zoom-only Ken Burns. Landscape is unchanged: the venue's ground exists there, but it is not displayed.

**And the at-work card sits inside the safe area in portrait.** The portrait rule `.tpl{padding:0 6%}` overrode the card's safe padding, so its head touched the top edge, and the card filled the whole height, leaving an empty band above the QR. In portrait the card gets its safe padding back, takes its content's height, and is centred. Two declarations in the portrait block.

### D5c. Socials at phone size

At the handset layout (D5a) on a 1080-wide frame: the handle (`.at`, `7.4vw`) is 80 px, about 7% of the width. The network name is about 48 px. The QR is `min(62vw,52vh)`, 670 px, 62% of the width. The QR's job in a video is to be screenshotted, or scanned off a second screen. The handle's job is to be read and typed, so the handle is what the check measures.

### D5d. A video clip in a segment: no, only frames

A segment takes only stills: `admit` admits only raster extensions (`admit.rs:41`), and the player has no `<video>`. **The recorder could not carry a clip even if the player could**: it drives the page on Chrome's virtual clock and screenshots each frame (`record.rs:293-367`). Media playback does not step with that clock, so a clip would be sampled at wrong or repeated frames. So 002's hand-drawing progression goes in as a gallery of stills with a short dwell. A real clip would be its own thread.

### D5e. The check

Record Snorkeltoast's reel `20260919-45h-forbiddenplanet-nottingham-001` at 9:16 (002 is not stable yet; geodica will say when it is). Read frames from every segment type: crawl, strapline, points, venue, card, gallery with Ken Burns, statement, faq, atwork, socials with their QRs, and the logo. For each, check that it is legible at phone size and inside the safe area. Its 16:9 recording is the reference. The frames go to vc, and a finding that D5a to D5c are wrong reopens the design and does not get patched over.

## D6. Tests

- `aspect.rs` unit tests: the four names, `W:H` in both orders, case, every refusal in D3, and the size table in D2 at both targets.
- `config.rs`: `aspect:` accepted and a bad value refused at parse.
- `main.rs` or `video.rs`: the flag beats the yaml, the yaml beats the default, and no aspect at all is 16:9.
- `crate/test/video.sh`: a recording at 9:16, whose ffprobe size is 1080x1920, and 16:9 unchanged.
- `record`: the scale is 2 for a frame no wider than it is tall and 1 otherwise, as a unit test of the pure rule.
- No suite runs without vc's go.

## D7. Release

A CHANGELOG entry under `## [2.11.0] - unreleased`, and `help` for `--aspect`.

## Work packages

| WP  | Title                                                              | Status |
| --- | ------------------------------------------------------------------ | ------ |
| 01  | The aspect flag and key, the size rule, and a 9:16 reel that reads | Open   |
