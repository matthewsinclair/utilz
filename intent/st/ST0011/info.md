---
st_id: ST0011
title: stampz -- recipient watermarking for PDF document packs
status: WIP
created: 2026-09-03
completed:
---

# ST0011: stampz -- recipient watermarking for PDF document packs

## Objective

Promote the pack watermarker built in Lamplight (`design/system/docs/bin/stamp-pack.sh`, 129 lines, committed `fc31caf6a`) into Utilz as the `stampz` utility, so that stamping a recipient watermark across every page of a PDF document pack is available to every project rather than living in one repo's `docs/bin/`. hv's call, in hv's framing: move it out of Lamplight so it is available everywhere.

**"Available everywhere" is the whole requirement, and it is the one thing the reference cannot do.** It resolves headless Chrome at a hardcoded `/Applications/Google Chrome.app/...` and pulls JetBrains Mono from `fonts.googleapis.com`, so it runs on a Mac, online, and nowhere else. Neither CI runner has Chrome. A port that carries both dependencies across would satisfy the letter of the promotion and leave the tool exactly as unportable as the day it was written -- and would land `stampz` in `prez`'s position, with a suite only a developer machine can green.

What must survive the move is the part the reference earned the hard way: guards against failures that are **silent**, each producing an output that passes every check short of rendering the page and looking at it. The promotion is judged on whether those guards come across as tests rather than as comments.

## Context

### Where it comes from

`stamp-pack.sh` was built in Lamplight to mark investor document packs: a pack handed to a named person carries their name diagonally across every page. It is in production use there. Routed here on 2026-09-03 by `lamplight-ac` on hv's instruction, with the reference left in place and that node standing down from it.

Its shape, which the promotion keeps: `stamp-pack.sh <pack-dir> "<recipient>" [YYYYMMDD] [out-dir]` stamps `CONFIDENTIAL <date> <recipient>` rotated -30 degrees through the page centre, mid-grey at 30% opacity, and writes `STAMP-MANIFEST.txt` recording the recipient, the date, and the sha256 of every file before and after. Geometry is read per document with `pdfinfo`, the stamp is rendered to match, and stamps are cached per geometry so a mixed pack renders each size once.

### What it is, and what it is not

**THIS DETERS, IT DOES NOT PROTECT.** An overlay is strippable in seconds by anyone with a PDF tool. The glyphs do land in the text layer, but the rotation scatters them one per line in scrambled order, so no contiguous search finds the recipient -- which cuts both ways: a naive grep will not leak the recipient out of the file, and will not identify a leaked copy either. This sentence is the one thing a user could reasonably misunderstand about what they are getting, it stays in the utility's header, and AC08 pins it with a test rather than trusting it to a comment.

### The traps, all of which fail silently

Three came from `lamplight-ac`, verbatim in substance. The fourth was found here while spiking the renderer.

1. **`--underlay` is the wrong verb even though "a watermark behind the page" is the natural description.** Underlay draws beneath page content, and any page painting an opaque background covers it completely. The output is byte-different from the input and pixel-identical to it, so every check short of rendering says it worked. Reproduced here: on a light page painting an opaque white rect, an underlay build differs from the original by **zero pixels**.
2. **One colour does not fit all pages, and the failure is per-page rather than per-document.** Lamplight's decks mix near-black and light slides inside one file, so white vanishes on some pages and black on others. Mid-grey (128,128,128) at 30% is the value that holds on both, picked there by rendering a dark slide and a light slide and looking at them. Confirmed here by measurement: 0.67% of pixels changed on a white page, 0.94% on a near-black one.
3. **Font size must be derived, not configured.** A fixed size overruns the page the moment the recipient's name is long. A rotated single line's horizontal extent is `len * advance * cos(30)`; solve for ~85% of page width. The reference's first attempt used a fixed 40px and the string ran off both margins.
4. **The font arrives over the network, and its absence is silent.** The reference `<link>`s JetBrains Mono from `fonts.googleapis.com`; offline, Chrome falls back to generic `monospace` and renders a stamp that looks approximately right at a different advance width -- which also invalidates the trap-3 formula, whose 0.74 constant is that font's advance plus tracking. Not a defect in Lamplight, where the machine is online and the output is eyeballed. It is a defect in a utility that claims to run anywhere.

### The renderer decision, measured rather than reasoned about

The reference renders its one-page stamp by generating HTML and driving headless Chrome with `--print-to-pdf`. The alternative is to write the stamp PDF directly: base-14 Courier-Bold (no embedding, present in every PDF consumer), rotation via the text matrix, opacity via an `ExtGState`. Spiked on 2026-09-03 against both a light and a near-black fixture, each painting an opaque background:

| Property                       | Chrome reference             | Native PDF (measured)         |
| ------------------------------ | ---------------------------- | ----------------------------- |
| Stamp artifact                 | Chrome, 10s time budget      | 794 bytes, no subprocess      |
| Network                        | Google Fonts CDN             | none                          |
| Visible on a white page        | yes                          | yes, 0.67% of pixels          |
| Visible on a near-black page   | yes                          | yes, 0.94% of pixels          |
| The 96/72 px-to-pt conversion  | live, and costs a round      | gone -- authored in points    |
| Runs on either CI runner       | no                           | yes, with qpdf + poppler      |
| Font                           | JetBrains Mono               | Courier-Bold                  |

**Decision: native.** The only loss is JetBrains Mono specifically. What it buys is the difference between "a Mac with Chrome, online" and "anywhere qpdf runs", which is what the objective requires; it deletes trap 4 outright and trap 3's dependence on a downloaded advance width; and it removes the 96/72 conversion that `lamplight-ac` flagged as costing a round (Chrome's `--print-to-pdf` takes CSS px and emits points at 72/96, so a 1440pt page needs a 1920px render and the obvious guess of 1440px yields 1080pt). Authoring the stamp in points removes the units mismatch rather than documenting it.

### The measurement trap this thread inherits, found in its own spike

The spike's first visibility check counted pixels differing anywhere on the page and called anything above 0.05% visible. It reported the **underlay** build -- the one that must be invisible -- as visible at 0.30% on the dark fixture. The diagnostic: 468 differing pixels across 468 of 469 rows, every delta exactly 83. One pixel per row is a single-pixel column down the page edge, a rasteriser seam where the overlay page composites against the fixture's painted rect, and not the mark at all.

**A whole-page pixel-diff check greens the wrong verb.** Visibility must be measured in the centre region where the mark actually lands, and AT01/AT02 are written that way. This is the same class as the existing board watch-out that a grep-based check must target a string the artifact can only contain if the thing is really there.

### What the framework requires of a new utility

- `opt/stampz/{stampz,stampz.yaml,README.md,test/stampz.bats}`, `help/stampz.md`, `bin/stampz -> utilz`. Scaffolded by `utilz generate`, which derives the `utilz_version` floor from the framework's own VERSION rather than hardcoding it.
- Dependencies declared in `stampz.yaml` so `utilz doctor` checks them without a second registration: `qpdf` and `poppler` (for `pdfinfo`), both required; `pdftoppm` (also poppler) is what the tests render with.
- **CI has two rosters and they do not agree.** `test-macos` derives its roster from `utilz list`, so `stampz` is covered there the day it lands; `test-linux` carries a hardcoded list and a new utility goes untested on that leg with nothing reporting it. `stampz` must be added there explicitly, and both legs need `qpdf` and `poppler-utils` / `poppler` installed. The existing comment in `tests.yml` names this second-roster hazard; this thread pays it rather than fixing it.
- `shellcheck -x` is blocking and collects every executable under `bin/` and `opt/` plus every `*.sh`, excluding `*/test/*`. bash 3.2 (macOS), 2-space indent, no em dashes, column-aligned tables.

### Open, and hv's to rule

- **In-place is the reference's default and is a footgun outside Lamplight.** It was safe there because the originals regenerate from `docs/pdf/investor/`, which the header says in terms. Pointed at someone's only copy of a pack, an in-place default rewrites it. The design proposes an out-dir default with an explicit `--in-place`, which changes the reference's behaviour and is therefore hv's call, not this thread's.
- **Mixed page geometry stays refused in v1.** The reference refuses rather than stamping every page at the first size and clipping the rest. Native rendering makes a per-geometry stamp nearly free, but `qpdf --overlay --repeat=1` applies one stamp page to all pages, so per-page variation is real work and is deferred rather than smuggled in.

### What the build found, 2026-09-03

Four defects, three of them in checks rather than in behaviour. Each is recorded because it passed something that looked like verification.

**1. TRAP 4 IS REAL BUT SMALLER THAN STATED, AND `lamplight-ac` MEASURED IT RATHER THAN ACCEPTING IT.** The claim above -- that the reference's font arrives over the network and vanishes silently offline -- is true in form and wrong about the dependency that was actually load-bearing. JetBrains Mono is installed locally on that machine (`~/Library/Fonts`), so Chrome resolved it from the font book and the CDN `<link>` was never on the resolution path: rendering with the link and with it deleted gave byte-comparable output and an identical 661x389 ink box, both embedding `JetBrainsMono-Medium`. Forcing the fallback with a nonexistent family gives Menlo, and the ink box moves 661x389 -> 661x390, because the plausible fallbacks on macOS all share the 0.600 em advance the formula assumes. So the geometric consequence is **one pixel on a Mac and unbounded off one**, where nothing constrains what a foreign `monospace` resolves to. The Courier-Bold decision stands unchanged and for a better-stated reason: it makes the advance exact by construction rather than contingent in two ways.

**2. THE MIXED-GEOMETRY GUARD WAS DEAD, HERE AND IN THE REFERENCE.** `pdfinfo` prints `Page    1 size:  595 x 842 pts`. The reference matches `/page *[0-9]+ size:/` -- lowercase, and awk regexes are case-sensitive -- so it matches nothing, `wc -l` returns 0, and the caller's `${varied:-1}` default reads that zero as "one geometry, carry on". The check could not fire under any input. Inherited here verbatim and caught only because AT05 asserts its own fixture really carries two geometries before trusting the refusal; the first version of that test built its fixture by rotating a page, which does not change what `pdfinfo` reports, so the guard was being handed a uniform file and the test was passing on a refusal that never happened. **A test whose fixture does not exercise the guard is indistinguishable from a working guard.** Not a live defect in Lamplight, whose packs are one geometry per file; a check that cannot go red nonetheless, and it has been reported back.

**3. THE SIZE SOLVE IGNORED THE PAGE HEIGHT, AND THE OBVIOUS CASE HIDES IT.** The reference solves `len * em * cos(angle)` for a fraction of page WIDTH, which says nothing about height, and the error grows as the string shortens because a short line takes a large derived size and the glyph height then dominates the rotated bounding box. On A4 a three-character name takes the solve to 263pt, whose bbox exceeds the page arithmetically and yet lands **no** ink in the margins, because glyph ink is inset from the em box -- so an A4 fit check passes a formula that is wrong. On a 1440x810 deck page the same name goes to 636pt and puts **2761 ink pixels** into the top and bottom margins. Both axes are now constrained; the same case gives 382pt and 141. AT03 carries the wide-page case and goes red without the fix.

**4. THE SOURCE GUARD MADE THE SHIPPED TOOL A SILENT NO-OP.** So the test suite could reach the one PDF assembler, the implementation first detected "am I being sourced" with an environment variable. A child process inherits it: with `STAMPZ_SOURCE_ONLY` exported, `stampz <pack> <recipient>` defined its functions, did nothing, and **exited 0**. A success-reporting no-op, in the tool whose whole subject is silent failure. Replaced with `[[ "${BASH_SOURCE[0]}" == "${0}" ]]`, which is self-detecting and cannot be set from outside. Caught only because the tests assert on the output files rather than on the exit code -- and the exit code was the thing that was wrong.

### The instrument that produced two of these

The first fit check hand-parsed the PGM header by skipping a guessed twelve fields (`NR > 12`) and counting bytes below a brightness threshold. It miscounted header bytes as pixels, reported "6 ink pixels in the margins" for a mark that fits, and that false reading went into an implementation comment as the justification for a real fix. **The fix was right and its stated reason was invented by a broken instrument** -- which is the same failure as the whole-page pixel diff greening the wrong verb, one level up: not a wrong measurement of the artifact, but a wrong measurement used as evidence in prose that outlives it.

Every visibility check now renders the SAME crop of two files and compares them byte for byte, so the headers are identical by construction and nothing parses them. The corrected comment records both the fix and the fact that its first justification was false.

### Verification standing at the end of WP-04

22 BATS tests green, `utilz doctor` clean, `shellcheck -x` clean. Three controls proven red-first by injecting the defect into the implementation and confirming the patch landed before trusting the red:

| Injected defect                              | Goes red         |
| -------------------------------------------- | ----------------- |
| `--overlay` swapped for `--underlay`         | AT01 (both pages) |
| the reference's lowercase geometry pattern   | AT05              |
| the width-only size solve                    | AT03 (wide page)  |

Not yet green: AC11, which is CI on both legs and is WP-05.

## Work Packages

| WP    | Title                                    | Size | Status      |
| ----- | ---------------------------------------- | ---- | ----------- |
| WP-01 | Design and acceptance contract           | S    | Done        |
| WP-02 | Native stamp renderer and geometry probe | S    | Done        |
| WP-03 | Utility surface, manifest and guards     | S    | Done        |
| WP-04 | Test suite and fixtures                  | S    | Done        |
| WP-05 | CI wiring on both legs                   | S    | WIP         |
| WP-06 | Docs and acceptance run                  | S    | Not Started |

## Acceptance

Acceptance Criteria and Acceptance Tests are RENDERED into `acceptance.md`, which is a GENERATED VIEW -- a row authored there is discarded by the next sync. The contract is canon in this thread's model: change a state with the `intent ac` / `intent at` verbs, and mint or reword a row in `.canon/st/ST0011.json`, then `intent sync --to-store`. This cover never restates them.

---

_Generated by Intent v3.0.0 from `thread.json`. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
