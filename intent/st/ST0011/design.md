# ST0011 Design -- utilz stampz

As-designed decisions for the promotion. Provenance, the traps and the renderer measurements live in this thread's Context; this file states what gets built and why each choice beat its alternative. Owner: cc.

## 1. Layout

```
opt/stampz/
  stampz            # the implementation -- bash, the opt/<name>/<name> convention
  stampz.yaml       # utility metadata, including the dependency declarations
  README.md         # per-utility readme (repo convention)
  test/
    stampz.bats     # BATS suite
    fixtures/       # generated at test time, not committed -- see 6
bin/stampz -> utilz # standard dispatcher symlink
help/stampz.md      # help file (repo convention)
```

Scaffolded with `utilz generate stampz "..."`, which creates all of the above from `opt/utilz/tmpl/` and derives the `utilz_version` floor from the framework's own VERSION. Hand-creating the tree instead would reintroduce the hardcoded-floor defect the generator's comment records.

**The dispatcher is untouched.** `bin/utilz` requires only that `opt/stampz/stampz` be a regular file and executable before `exec`-ing it.

## 2. The CLI surface

```
stampz <pack-dir> "<recipient>" [options]

  --out <dir>          write stamped copies here (DEFAULT: <pack-dir>.stamped)
  --in-place           overwrite the pack in place (see 2.1)
  --date <YYYYMMDD>    default: today, UTC
  --colour <0..1>      grey level, default 0.5 (see 3.3)
  --opacity <0..1>     default 0.30
  -h, --help / --version
```

Command-less, unlike `cryptz encrypt|decrypt`: the utility does one thing, and minting a verb for a single operation would make `stampz stamp` the only legal form. `mdagg` and `lnrel` are the in-repo precedent for a verbless utility.

### 2.1 In-place is opt-in, not the default -- PENDING hv

The reference stamps **in place** by default and takes an out-dir as an optional fourth positional. That is safe in Lamplight and says so in its own header: the originals regenerate from `docs/pdf/investor/`, so an in-place run is reversible by re-copying. A general-purpose utility has no such guarantee and will be pointed at packs that exist in one copy only.

So the default inverts: stamped copies go to `<pack-dir>.stamped` and `--in-place` is an explicit request. **This changes the reference's behaviour and is hv's ruling to make, not this thread's.** Recorded here as the proposal; AC03 is written against it and moves with the ruling. The manifest's before/after sha256 columns make an in-place run auditable either way, which is why the reference could afford the other default.

## 3. The stamp renderer

One page, generated directly as PDF. No Chrome, no HTML, no network. The measurements behind this choice are in Context; what follows is the construction.

### 3.1 Assembly, and why byte offsets are measured rather than computed

A PDF's `xref` table is a list of byte offsets into its own file. Three ways to get them, and only one is honest:

| Approach                                       | Verdict                                                                              |
| ---------------------------------------------- | ------------------------------------------------------------------------------------ |
| Emit a bogus xref, let `qpdf` reconstruct it   | Rejected. qpdf repairs damaged files with a warning and exit 3 -- a silent-repair dependency in a thread whose whole subject is silent failure. |
| Compute offsets from string lengths in bash    | Rejected. `${#s}` counts characters, not bytes; correct only under `LC_ALL=C` and only for a recipient that is pure ASCII. |
| **Append each object, then measure the file**  | **Chosen.** `wc -c < "$f"` before each append is the offset of the object about to be written. Byte-exact by construction, locale-independent, no arithmetic to get wrong. |

The stamp is small enough (794 bytes measured in the spike) that the extra `wc` per object costs nothing.

### 3.2 Type and geometry

Base-14 **Courier-Bold**: present in every conforming PDF consumer, never embedded, no download. This is what deletes trap 4 -- and it does something the reference could not, because Courier is fixed-pitch with an advance of exactly **0.600 em for every glyph**. The reference's font-size formula uses `0.74 = 0.60 advance + 0.14 tracking`, and with a CDN font that constant is true only if the download succeeded. With Courier it is true by construction.

Size is derived, never configured (trap 3). For a line of `n` characters rotated by `d` degrees, spanning 85% of page width `w`:

```
  fs = 0.85 * w / (n * 0.74 * |cos d|)      floored at 8pt
```

Rotation and centring go in the text matrix, so the line's midpoint sits at the page centre:

```
  tw = n * 0.74 * fs                        unrotated width
  Tm = [cos d, sin d, -sin d, cos d, w/2 - (tw/2)cos d, h/2 - (tw/2)sin d]
```

`d = -30`. Tracking is the `Tc` operator at `0.14 * fs`. All of this is arithmetic over `pdfinfo`'s reported point size, so **the 96/72 px-to-pt conversion never arises** -- the trap that cost `lamplight-ac` a round is not mitigated here, it is absent.

### 3.3 Colour and opacity

Mid-grey `0.5 0.5 0.5 rg` under an `ExtGState` with `/ca` and `/CA` at `0.30`, which is the value Lamplight measured against a near-black slide and a light slide, and which this thread re-measured (0.67% of pixels changed on white, 0.94% on near-black). Both are flags because with a native renderer they are numbers in a content stream rather than a re-render, but the defaults are the measured ones and AC02 is written against the defaults.

`/CA` (stroke alpha) is set alongside `/ca` (fill alpha) even though the mark only fills. A future outline variant that strokes would otherwise draw at full opacity, and the failure would be visual-only.

## 4. Per-document probe and the two guards

Per PDF, before stamping:

1. `pdfinfo` reports `Pages:` and `Page size:`. A document whose size cannot be read is a refusal, not a default.
2. **Mixed-geometry guard.** `pdfinfo -f 1 -l <pages>` reports per-page sizes; more than one distinct size is a refusal. Stamping every page at the first size would clip the rest, and the clipped pages still look stamped. Native rendering makes per-geometry stamps cheap, but `qpdf --overlay --repeat=1` applies one stamp page to all pages, so per-page variation is genuine work and is deferred rather than smuggled in.
3. Stamps are cached per geometry in the work directory, so a pack of ten A4 files renders one stamp.
4. **Page-count guard.** After the overlay, `pdfinfo` on the output must report the same page count. Cheap, and it catches a class of silent corruption.

`qpdf ... --overlay <stamp> --repeat=1 --` is the verb. **Never `--underlay`** (trap 1); AT03 pins that as a control rather than a comment.

## 5. The manifest

`STAMP-MANIFEST.txt` in the output directory: recipient, date, stamp time (`date -u`), source directory, then a row per file with page count and the sha256 before and after. This is the audit trail that makes an in-place run recoverable and a leaked copy attributable to a run, and it is the reason the reference could default to in-place at all.

## 6. Testing

The suite is BATS, per repo convention, and generates its own fixtures at test time rather than committing binary PDFs. Two fixture pages, both painting an **opaque background rect**, because an opaque background is the precondition for trap 1 and a fixture without one cannot detect the wrong verb:

- `light.pdf` -- white ground, dark text
- `dark.pdf` -- near-black ground, light text

Fixtures are built by the same offset-measuring assembler the renderer uses, exercised through a `--emit-fixture` hidden flag rather than a second copy of the PDF-writing code in the test tree. **A second assembler in `test/` would be a Highlander violation and would also be the wrong instrument**: a bug in the shared assembler would cancel out, with the fixture and the stamp wrong in the same direction.

### 6.1 Visibility is measured in the centre region, never whole-page

Rendering is `pdftoppm -gray`; visibility is the count of pixels differing from the unstamped render of the same page.

**The threshold is not whole-page.** The spike's first attempt counted differences anywhere on the page and reported the underlay build -- the one that must be invisible -- as visible at 0.30%: 468 differing pixels spread one per row across 468 of 469 rows, every delta exactly 83, which is a single-pixel column down the page edge where the composited page meets the fixture's painted rect. A rasteriser seam, not a mark.

So the measurement crops to the central band the rotated line actually crosses before counting. The seam is excluded by construction rather than by choosing a threshold above it, because a threshold tuned to today's seam is a number that drifts with the renderer.

## 7. CI

Both legs need the tools: `qpdf poppler-utils` on Ubuntu, `qpdf poppler` on macOS.

**`stampz` must be added to `test-linux`'s hardcoded roster.** `test-macos` derives its roster from `utilz list` and picks the utility up for free; `test-linux` lists utilities by hand, and the comment in `tests.yml` already names this as the second-roster hazard it is. This thread pays the toll rather than fixing the roster, which is its own change and not this one.

The suite skips cleanly with a named reason when `qpdf` or `pdftoppm` is absent, so a developer without the tools gets a stated skip rather than a failure -- and, per the `prez` lesson, the CI legs install the tools so that the skip path is never the path CI takes.

## 8. Deferred, with the reason

| Deferred                          | Why                                                                                    |
| --------------------------------- | ---------------------------------------------------------------------------------------- |
| Mixed page geometry within a file | `--repeat=1` applies one stamp to all pages; per-page overlay ranges are real work (4). |
| A configurable text template      | The `CONFIDENTIAL <date> <recipient>` format is what the mark means; a template is a v2 question once there is a second caller. |
| Font choice beyond base-14        | Embedding a font reintroduces the download, and base-14 is what makes the advance constant exact (3.2). |
| Stripping or detecting a stamp    | Out of scope, and the honest answer is that an overlay is trivially strippable -- which the header says. |
