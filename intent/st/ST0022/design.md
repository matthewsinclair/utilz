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

- **What is there already**: `player.html` lays out tall windows under `@media (orientation:portrait)` (`:466`): points and the at-work body stack, and `fit: cover` becomes `contain` on a blurred copy of the same picture, a ground `buildImage` already paints (`:590`).
- **What does not fire**: the handset rules sit under `max-width:820px` (`:433`). A 1080-wide recording is wider than that, so it gets the television type floors and a 4.5% safe area, in a portrait layout.
- **The pictures assume no orientation.** `normalise` fits each picture's own long edge to the role's edge, and the payload carries each picture's `w` and `h`. So nothing in the build assumes a landscape frame. A landscape picture under `contain` in a 1080-wide frame is shown smaller than it was embedded, never enlarged.
- **The check**: record at 9:16, then read frames from every segment type: crawl, strapline, points, venue, card, gallery with kenburns, statement, faq, atwork, socials with their QRs, and the logo. For each: is it legible, and is it inside the safe area. The Snorkeltoast reel `20260919-45h-forbiddenplanet-nottingham-002` is the first real one, with `001` beside it as the working 16:9 reference.
- **If the check shows television type is wrong for a phone**, the fix is in `record`, not the player: record at `deviceScaleFactor: 2` over a viewport half the size, so the handset rules apply and the frame keeps its pixels. It is a decision taken from the frames, and it goes to vc with them.

## D6. Tests

- `aspect.rs` unit tests: the four names, `W:H` in both orders, case, every refusal in D3, and the size table in D2 at both targets.
- `config.rs`: `aspect:` accepted and a bad value refused at parse.
- `main.rs` or `video.rs`: the flag beats the yaml, the yaml beats the default, and no aspect at all is 16:9.
- `crate/test/video.sh`: a recording at 9:16, whose ffprobe size is 1080x1920.
- No suite runs without vc's go.

## D7. Release

A CHANGELOG entry under `## [2.11.0] - unreleased`, and `help` for `--aspect`.

## Work packages

| WP  | Title                                                              | Status |
| --- | ------------------------------------------------------------------ | ------ |
| 01  | The aspect flag and key, the size rule, and a 9:16 reel that reads | Open   |
