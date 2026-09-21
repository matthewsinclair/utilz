# ST0023 design: a long socials handle fits a portrait frame

Issue 0045, from geodica through vc on 2026-09-21, for the release after 2.11.0. At 9:16 the handle `forbiddenplanetnottingham` (25 characters) runs off both edges of a 1080x1920 frame, and at 16:9 it fits. Reproduced on a scratch copy of Snorkeltoast's 001.

## D1. Why it overflows

A portrait frame is laid out 540 CSS px wide (ST0022 D5a), where the handset rules set `.social .at` to `clamp(20px,7.4vw,124px)`, 40 px. A 25-character handle in the display face at 40 px is wider than 540 px. It is one word, so it cannot wrap, and its size is fixed, so it cannot shrink. The pane centres it, so it spills past both edges.

## D2. The fix: fit the handle to its pane

- **In a portrait window, the player measures the handle once its slide is in the page, and shrinks it only when it is wider than the room it has**: the pane's width inside its safe padding. The new size is the old one scaled by room over width, rounded down, so it fits in one step. One function does it (`fitHandles`), called from `show()` straight after the slide goes in, and again for the slide on screen when `document.fonts.ready` settles, because the width depends on the face.
- **The floor is the handle's own clamp minimum, 20 CSS px**, which is 40 px in a portrait frame. That is the size the handset rules already accept as legible. A handle still too wide at the floor stays at the floor and wraps anywhere, so it never leaves the frame.
- **It covers both socials layouts.** The `each` page's handle and the summary page's rows both carry `.at`, and both have the same defect, so one rule serves both.
- **Headlines in general are out of scope.** geodica asked for that too, and it is with hv.

## D3. Portrait only, so widescreen cannot change

**The fit runs only in a portrait window** (`orientation:portrait`, the same test the player's portrait block uses). A landscape window clears any fit and measures nothing, so widescreen is unchanged by construction.

It was first built to act on any overflowing handle, and measurement ruled that out. The 16:9 fixture's handle has no glyph inside the 86 px safe margin, yet its box was a few pixels wider than its room, so the fit shrank it, and the frame's bytes changed. A handle that visibly fits must not move, so the gate is the orientation, not the measurement. A handle too long even for 16:9 still overflows there, as before, and would be a separate defect.

Checked on the fix, pre-fix binary against post-fix, frame by frame: 001's four socials pages are byte-identical at both aspects, and the fixture is byte-identical at 16:9.

## D4. Tests

- **Red first**: a `video.sh` block, AT01 of ST0023. It records a fixture reel with one socials page whose handle is 25 characters, at `--aspect portrait`, and checks that no glyph falls in the frame's outer 20 px on either side. It fails before the fix.
- After the fix: it passes, `cargo test -p showreel` passes, and `video.sh` AT01 and AT30 of ST0022 still pass. vc reads the portrait frame.

## Work packages

| WP  | Title                                                        | Status |
| --- | ------------------------------------------------------------ | ------ |
| 01  | Fit the socials handle to its pane, red test first           | Open   |
