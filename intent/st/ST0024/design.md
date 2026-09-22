# ST0024 design: headlines fit a portrait frame, a platform safe zone, and a handle that fits at 16:9

hv, 2026-09-22, through vc, all three yes and on today's critical path. **6.1**: headline fit-to-width at portrait in general, geodica's ask, scoped out of ST0023. **6.2**: a platform safe-zone option for TikTok and Instagram, whose own UI covers the bottom of the frame and the right edge, with the corner mark, the venue labels and the at-work QR inside it. **6.3**: a socials handle that overflows at 16:9 is fitted there too, which ST0023 D3 left as it was.

Reviewed by vc, 2026-09-22: GO on WP-01, one finding (D2b below) and five smaller points, each answered in place and marked **vc**.

## D1. What is there now, and the two things it cannot do

ST0023 gave the player `fitHandles` (`player.html:659-677`): in a portrait window a handle whose `scrollWidth` is wider than its pane's room inside the safe padding is scaled down to fit in one step, never below `HANDLE_FLOOR` (20 CSS px, its clamp's own minimum), and wraps anywhere at the floor. Each ask meets one of its two limits.

- **It reads OVERFLOW, and overflow is only one of the two symptoms.** A pane's centred child is sized fit-content, so a word too wide for the room widens the child and spills past the frame: that is issue 0045, and `scrollWidth` sees it. A headline in a container of definite width has the other symptom. `.tpl h2`, `.card h2`, `.atwork .name` and `.crawl dd` carry `overflow-wrap:break-word` (`player.html:436-437`), so a word too wide for the line is BROKEN MID-WORD instead, the box never grows, and `scrollWidth` never exceeds it. A fit that reads overflow alone cannot see the break.
- **It is gated on the orientation, and ST0023 D3 says why.** At 16:9 the fixture's handle had every glyph inside the 86 px safe margin and a box a few pixels wider than its room, so a box-based fit shrank it and the frame's bytes changed. The gate became the orientation rather than the measurement, and 6.3 is what that left behind.

## D2. One measure: the longest word against the room

Both symptoms have one cause, a word that cannot wrap and does not fit, so both are read from one pair of numbers.

- **The word** is the element's min-content inline size: its widest run that cannot be broken. It is read from the browser rather than computed, in one synchronous read, by laying the element out at `width:min-content` with `overflow-wrap:normal` and restoring both. `overflow-wrap:break-word` is deliberately not part of min-content in CSS, which is exactly why the browser breaks the word in the first place and why this reads the width that decides it.
- **The room** is the width the element's text may use: walking from the element to its slide, the tightest content box, less the padding and border between it and the element. The min over the chain is what makes it work in both container kinds. A grown fit-content box is wide, so it never wins the min and the real constraint above it does; an element in a definite container wins with its own box. It needs no per-template knowledge, and it picks up `.card .box`'s `max-width`, `.crawl .text`'s width and `.venue .lay`'s inset without naming any of them.

`word > room` is then the whole test: in a definite container it is exactly when the layout would break the word, and in a growing one exactly when the line leaves the room. The fit is the old one: scale the size by `room / word`, floored, so it fits in one step; never below the line's floor; at the floor, `overflow-wrap:anywhere`, so it wraps rather than leaves the frame.

### D2b. A shared grid track: the room is the item's SHARE (vc's finding)

The chain is wrong for a line that sits in a track it shares with siblings, and vc is right that the item's own box does not save it. `.points .row` is `display:grid;grid-auto-flow:column;grid-auto-columns:1fr` (`player.html:267`), and `1fr` is `minmax(auto,1fr)`, whose `auto` floor is the item's min-content: a long word GROWS its own track and squeezes its siblings, so the box read back is already the wrong width, while the chain above it returns the whole row, three times the share.

**So a line drawn BESIDE something else is measured against what is left for it, not against the whole container.** In a grid the tracks are divided equally: the container's content width, less the column gaps, divided by the number of row-mates. **Built, and the build added the other half of it**: a flex line does the same thing for a different reason, and a socials handle sized against its whole pane still crossed the frame because its label sat next to it on the line. There the room is what the row-mates did not take.

**AND THE WALK NARROWS FROM THE OUTSIDE IN, which is not the same as taking the smallest of the boxes.** Reading each ancestor on its own and taking the minimum looks equivalent and is not: a box that has already grown with its content is measured at its grown width, so a line inside it is given a share of a row that is itself too wide, and the constraint above is lost. Measured: the handle was fitted to 868 px inside a row of 968 where the pane allowed 873. One line reads both cases -- `min(room, node.offsetWidth)` -- because a box narrower than its room is a real constraint and a box wider than its room has grown, which never widens what its parent left it.

The room is the min of that and the chain. For the crawl's `dl`, one column, the share is the container's content width and the two agree; for a row of three points it is a third of it. The limit is stated rather than hidden: the share is an EQUAL share, so it is right for tracks that are equal by declaration and wrong for a grid whose tracks differ by declaration (`.atwork .body`'s `1fr auto`). No fitted line sits in such a grid today, and D7's probe is what would catch one that did, at both orientations, on a points slide and a crawl row with a long word.

## D3. 6.1 Headlines fit, and only in a portrait window

The fitted lines are the display face carrying the reel's own words:

| Line                        | Segment                |
| --------------------------- | ---------------------- |
| `.tpl h2`                   | statement, faq, points |
| `.card h2`                  | card                   |
| `.socials h2`               | socials summary        |
| `.wordmark .top`, `.bottom` | wordmark               |
| `.atwork .name`             | atwork                 |
| `.strapline .panel div`     | strapline              |
| `.points .pt`               | points                 |
| `.crawl dd`                 | crawl                  |
| `.venue .banner .date`      | venue                  |
| `.venue .at`, `.city`       | venue                  |

Body copy and kickers are not fitted. They are running text at small sizes that wraps at its spaces, and shrinking a paragraph because one word in it is long is the wrong answer for a paragraph.

**Siblings share one size (vc's point 5).** Fitted lines that match the same rule under one parent take the smallest size any of them needs: three point boxes at three sizes read as a bug even though each line is correct on its own, and so do a strapline's lines and the handles down a socials summary. Lines under different rules stay independent, because `.wordmark .top` and `.bottom` are meant to differ.

**Q5 WAS PUT TO hv ON A PREMISE THE BUILD THEN DISPROVED, and this records that rather than quietly restating it.** The design said that at 16:9 a long word breaks mid-word, which is ugly and inside the frame, so it is a look rather than a defect. **That is true only for a headline in a container of definite width.** A headline in a PANE has nothing to break against, because the pane's centred child grows with its content: measured at 960 px wide, `.socials h2` occupied -357..1318 and `.wordmark .top` -506..1466. They run off both edges, exactly as issue 0045's handle did. Worse, the grown pane displaces everything beside them: the socials handle crossed the frame at 16:9 even though its own fit was correct.

**What is built, pending hv's answer, is ONE RULE at every orientation**: a line whose INK would leave its room is fitted wherever it is drawn, and in a portrait window a headline is held to the stronger test, its whole word against its room. Measured: every landscape frame violation and every unequal grid track goes away, portrait is unchanged at 98/98, and a line that visibly fits still never moves, so a recording whose lines all fit is byte-identical. If hv would rather hold widescreen completely still, the alternative ships a known overflow and the probe's landscape expectation records THAT decision instead.

## D4. 6.3 At 16:9 the gate is the ink, not the box

hv wants a handle that overflows at 16:9 fitted, and ST0023 D3's ruling stands: a handle that visibly fits must not move. The two are only compatible if the measurement answers the question the eye asks, which is where the GLYPHS are, not where the box ends. A box is wider than its glyphs by the side bearings of its first and last letter, and that difference is the whole of D3's few pixels.

So for a handle, in any orientation, the gate is `word - slack > room`, where `slack` is the box's width less its ink, measured for that word with the same font on a canvas: `slack = m.width - (m.actualBoundingBoxRight + m.actualBoundingBoxLeft)`. The scale stays `room / word`, so a fitted handle sits inside the room with the slack to spare.

**Determinism (vc's point 1), and the build found the real threat to it.** The word was first measured from a bounding RECT, which carries the transforms above the element: under the crawl's rising animation the same line measured twice gave two widths, so the fit was not idempotent and two recordings of one reel would have differed. It reads `offsetWidth`, the layout box, which no transform touches. The ink depends on the loaded face, so the fit runs when the slide mounts, again at `document.fonts.ready`, and again on a resize, which is what `fitHandles` already did. Every call CLEARS the previous fit before it measures, so a second call re-derives the same size from the same unfitted line rather than compounding: idempotence is by construction, and the probe asserts it rather than trusting the construction. The canvas font string is the element's own computed one, so a theme's face is what gets measured.

Two consequences worth stating. The orientation gate goes away for handles, so ST0023's portrait behaviour changes for one narrow case: a handle whose box is over the room but whose ink is not is no longer shrunk by a percent or two at portrait. Nothing has shipped that, since 0045's fix is unreleased. And a 16:9 handle whose ink sits in the overscan band but inside the frame is now fitted, which is what the shell has always claimed ("type and marks never" bleed past the safe area, `player.html:55`) and what it did not do.

## D5. 6.2 The platform safe zone

### D5a. The option

It mirrors `aspect` exactly, because a reel's recording options should not each have their own shape: `--safe-zone <name>` on `showreel video`, `safe_zone:` in `showreel.yaml`, one parse for both, and the flag wins. `none` is the default, and a bad value is refused at config parse, so `check` and `build` refuse it too.

**A zone with a frame wider than it is tall is refused, naming both.** The numbers below are measured on a 9:16 phone, and on a 16:9 frame they would move the type for no reason anyone could see.

### D5b. The geometry, and where it comes from (vc's point 3)

The zone is four insets, as a share of the frame. **Read 2026-09-22 from published safe-zone guides, which are third-party readings of the apps' own UI and not platform specifications**: for TikTok, checksafe.zone and kreatli.com; for Instagram Reels, outfy.com, firstpier.com and pod2reels.com. The ranges they give for a 1080x1920 frame:

| Edge   | TikTok, conservative | Instagram Reels  | This zone | At 1080x1920 |
| ------ | -------------------- | ---------------- | --------- | ------------ |
| top    | 130 px (6.8%)        | 108 to 270 px    | 10%       | 192 px       |
| right  | 140 px (13%)         | 120 px (11%)     | 15%       | 162 px       |
| bottom | 484 px (25.2%)       | 320 to 672 px    | 25%       | 480 px       |
| left   | 44 px (4.1%)         | 60 to 65 px (6%) | 6%        | 65 px        |

One zone covers both platforms rather than one per platform, because the same recording is posted to both and a zone per platform would mean a recording per platform. The numbers are the wider of the two at each edge, short of Instagram's 672 px bottom, which is its guidance for ADS with a call to action rather than for a posted reel. **They are a moving target**: the platforms change their UI several times a year, which is why the source and the date are written down here and why the geometry is one line to edit.

### D5c. How it reaches the player, and what moves

`record` already loads the built page as `?noloop&kiosk` (`record.rs:316`), so the zone travels the same way, as `&zone=social`. The built HTML is unchanged and gains a way to be previewed: opening a reel in a browser with `?zone=social` shows the same layout. Rust carries the NAME and the player's CSS holds the geometry, which is how `fit:`, `transition:` and `motion:` already work.

In the player, the four shell insets become per-edge, each the larger of today's safe area and the zone's edge:

```
:root{ --zone-t:0px; --zone-r:0px; --zone-b:0px; --zone-l:0px;
       --safe-t:max(var(--safe),var(--zone-t)); ... }
```

With no zone every one of them computes to exactly what it does today, which is what keeps every existing recording byte-identical. What then moves is everything that already sat inside the safe area: the pane's padding (wordmark, social, socials, strapline, card), `.tpl`'s padding (statement, faq, points, atwork), the venue's `.lay` inset and so its banner, "At <venue>" and city, the matte and logo plates, the crawl's mark, and the corner mark, whose own `x` and `y` are measured from the zone's corner instead of the frame's. **Pictures still bleed to the frame's edge**: the shell's rule is that pictures may and type may not.

**A cap measured against the frame's height has to be measured against the zone's**, or the at-work card and the social QR keep their full height inside a box a quarter shorter and overflow it. `--zone-h` and `--zone-w` carry the zone box's size, defaulting to `100vh` and `100vw`, and the QR caps use them.

**And a drawn picture's plate is MEASURED rather than computed.** `fitPlate` decided which axis a matte or logo picture fills from `--safe` and the window, which is a formula that a per-edge zone makes wrong; and the custom properties that describe the zone carry units only the layout can resolve. So the plate's own box is read, once the slide is in the page, which is where every other measurement in this thread is taken.

**The scale is not a trap here (vc's point 2).** A portrait frame is laid out at half size and drawn at `deviceScaleFactor: 2` (ST0022 D5a), but that scale is applied by Chrome at capture: `vh` and `vw` are the CSS viewport, `#stage` is `position:fixed;inset:0`, and every length in the player is already in CSS units. So the zone, the caps and the fit all measure the same box the layout uses, at either scale, and nothing in this thread reads a device pixel. The probe measures at 540x960 for exactly that reason.

## D6. The floors have one home

A fitted line's floor is its own clamp minimum, as ST0023 ruled for the handle, and there are now twelve of them. Writing them out in the script would be twelve numbers that agree with the CSS on the day they are written, so instead each fitted rule declares `--fit-floor` and its clamp reads it:

```
.tpl h2{--fit-floor:38px;font-size:clamp(var(--fit-floor),7.6vw,150px)}
@media (max-width:820px){ .tpl h2{--fit-floor:22px} }
```

The handset block already changes nothing but the floor for most of these, so most of it gets shorter. `HANDLE_FLOOR` goes: the handle's floor is read the same way as every other line's. Computed values do not move, which the byte check in D7 proves.

## D7. Tests

- **`zone.rs`**: the names in any case, every refusal, and the landscape refusal in `video.rs`. `config.rs`: `safe_zone:` read, a bad one refused at parse.
- **A player probe** over CDP, as AT12's determinism probe already drives Chrome from a plain `.mjs`. At 540x960: every fitted line's longest word is on one line inside its room; no line's ink crosses the safe box; a line too long at its floor wraps rather than leaving the frame; **a points slide and a crawl row with a long word, at both orientations, which is where D2b is measured rather than assumed**; siblings under one rule share one size; a second fit gives the same size as the first; and every fitted selector carries a `--fit-floor`, which is the contract D6 rests on. At 960x540: headlines are untouched and a handle whose ink fits is untouched.
- **`test/video.sh`: one fixture, three recordings**, each red first. The fixture is one reel carrying a socials page with a 40-capital handle and a statement page whose headline is one long word. Recorded at 16:9, no glyph falls in the frame's outer 86 px and the handle is still drawn (6.3). Recorded at portrait, no glyph falls in the outer 20 px and the headline is drawn on one line (6.1). Recorded at portrait with `--safe-zone social`, no ink falls in the zone's four bands, where the recording without the zone has ink in them (6.2). **Cost, since the estate gate runs this at every cut**: three recordings of a two-slide reel at the dwell floor and `--fps 10`, the same shape as ST0023's single handle recording, so the marginal cost is three Chrome launches and three encodes. The measured number goes in the WP before it closes.
- **The control, written down rather than claimed (vc's control)**: a 16:9 recording of a reel with no overflowing line, and a portrait recording with no zone, are byte-identical frame for frame to the same recordings made before this thread. That is what "by construction" means in D5c and D6, and it is the criterion that fails if either is wrong.
- **vc reads** a 9:16 recording of Snorkeltoast 001 with the zone and without it, one frame per segment type.

**WHY A DOM PROBE AND NOT ONLY PIXELS, recorded here because it is the kind of thing a later reader has to take on trust otherwise.** A recording can show that a line ended up inside the frame; it cannot show why, and a headline broken mid-word is inside the frame too. On this thread the probe caught two defects in the player that every pixel check passed: a fit that was not idempotent under the crawl's animation, which would have surfaced much later as frames moving between two recordings of one reel, and a room measured from the inside out, which fitted a handle to a row that had already grown past its pane. A line drawn in motion is exempt from the frame check, and says so in its own result rather than being dropped from the count.

## D8. Release

2.12.0, prez 2.4.0 (vc, on hv's "less worried about the release number"), the prez bump in its own commit before the cut (ST0019 D2). `--safe-zone` in `showreel`'s help.

**The CHANGELOG section is reconciled, not contradicted (vc's point 4).** 0045's entry in the open section ends "Widescreen is unchanged ... 16:9 recordings are byte-identical to before", and 6.3 makes that false for a handle that overflows at 16:9. The section is unreleased and ships as one release, so 0045's entry is reworded in the same commit that adds this thread's, and the two together say one thing: a handle is fitted wherever its glyphs would leave the safe area, at either aspect, and a recording whose lines all fit is unchanged. The open section's heading becomes `## [2.12.0] - unreleased` in that same commit, so the heading and the reason for it move together.

## The choices hv should see

| #   | Choice              | Recommendation                                                              |
| --- | ------------------- | --------------------------------------------------------------------------- |
| Q1  | The option's name   | `--safe-zone` and `safe_zone:`, values `none` and `social`                   |
| Q2  | Its default         | `none`: a zone changes every frame, so it is asked for                       |
| Q3  | The zone's geometry | top 10%, right 15%, bottom 25%, left 6% (D5b)                                |
| Q4  | One zone or two     | One `social` zone for both platforms, not `tiktok` and `instagram` apart     |
| Q5  | Headlines at 16:9   | Leave them: a long word breaks mid-word there, which is a look, not a defect |

## Work packages

| WP  | Title                                                                 | Status |
| --- | --------------------------------------------------------------------- | ------ |
| 01  | The fit reads the longest word: headlines at portrait, handles by ink | Open   |
| 02  | The platform safe zone, and everything type inside it                 | Open   |
