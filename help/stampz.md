# stampz

**Version**: run `stampz --version`
**Author**: Matthew Sinclair

---

## Name

`stampz` - Stamp a recipient watermark across every page of a PDF pack

---

## Synopsis

```bash
stampz <pack-dir> "<recipient>" [OPTIONS]
```

---

## Description

Stamps a recipient watermark diagonally across every page of every PDF in a directory, so a document pack handed to a named person carries their name. One line of mono type is rotated -30 degrees through the page centre reading `CONFIDENTIAL <date> <recipient>`, in mid-grey at 30% opacity.

A `STAMP-MANIFEST.txt` is written into the output directory recording the recipient, the date carried in the mark, when the run happened, and the page count plus the sha256 of every file before and after. That manifest is the audit trail: it makes a run attributable, and it makes an in-place run recoverable by re-copying rather than by trusting a backup nobody made.

### What this is, and what it is not

**This deters. It does not protect.**

An overlay is strippable in seconds by anyone with a PDF tool. The mark's glyphs do land in the text layer, but the rotation scatters them one per line in scrambled order, so no contiguous search finds the recipient. That cuts both ways: a naive `grep` will not leak the recipient out of the file, and it will not identify a leaked copy either.

It marks a copy. It does not secure one. If you need a document nobody can pass on, this is the wrong tool and there may not be a right one.

### How it works

Page geometry is read per PAGE with `pdfinfo`, a one-page stamp is built for each distinct size, and one `qpdf` run lays each stamp over the pages of its own size. Stamps are cached per geometry, so a pack of ten same-sized files builds one stamp, and a file of one size takes the same path with a single overlay rather than a special case of its own.

The stamp is assembled directly as a PDF using base-14 Courier-Bold. There is no browser, no HTML, no network request and no embedded font. That is deliberate: it means `stampz` runs anywhere `qpdf` and `poppler` do, and it means the type metrics used to size the mark are exact rather than dependent on which font happened to arrive.

### Two guards, each of which refuses rather than approximates

- **A PDF whose pages differ in size is stamped page by page.** One stamp is rendered for each distinct page size and laid over the pages of that size, so every page carries a mark made for it, and the run says `3 pages, 2 sizes`. This used to be refused, because one stamp drawn at another page's size is clipped or drawn small, and a page that looks stamped but is not properly marked is the failure a deterrent must not have. What is still refused is a file whose pages cannot all be measured: a probe that reads nothing is a refusal, never a pass.
- **A change in page count aborts the run.** Cheap, and it catches a class of corruption that still leaves a file which opens.

---

## Options

### General Options

| Option              | Description                                               |
| ------------------- | --------------------------------------------------------- |
| `--out <dir>`       | Write stamped copies here (default: `<pack-dir>.stamped`) |
| `--in-place`        | Overwrite the pack itself instead of copying              |
| `--date <YYYYMMDD>` | Date carried in the mark (default: today, UTC)            |
| `--colour <0..1>`   | Grey level of the mark (default: `0.5`)                   |
| `--opacity <0..1>`  | Opacity of the mark (default: `0.30`)                     |
| `--color <0..1>`    | Accepted spelling of `--colour`                           |
| `-h`, `--help`      | Show help                                                 |
| `--version`         | Show version                                              |

### Why the defaults are what they are

**Mid-grey at 30%, rather than a light grey screen.** A pack is not uniformly light or dark. A deck can put a near-black slide next to a light one inside a single file, and the failure is per page rather than per document: white vanishes on one, black vanishes on the other. Mid-grey at 30% is the value that stays legible on both, measured against a light and a near-black page rather than reasoned about. Move it if your pack is uniform; the defaults assume it is not.

**Copies by default, in place on request.** `--in-place` rewrites the pack you point it at. That is the right default only when the originals regenerate from somewhere else, which is a property of your pack and not of this tool, so it is opt-in here.

---

## Examples

### Basic Usage

```bash
# Stamp a pack; copies land in ~/packs/seriesA.stamped
stampz ~/packs/seriesA "Matthew Sinclair"

# Stamp into a named directory, with an explicit date in the mark
stampz ~/packs/seriesA "Matthew Sinclair" --out /tmp/ms --date 20260903

# Overwrite the pack itself
stampz ~/packs/seriesA "Matthew Sinclair" --in-place

# A fainter mark on a pack that is uniformly light
stampz ~/packs/seriesA "Matthew Sinclair" --colour 0.4 --opacity 0.20
```

### Reading the manifest

```bash
cat ~/packs/seriesA.stamped/STAMP-MANIFEST.txt
```

Every row carries the file, its page count, and its sha256 before and after. A row whose two hashes are equal would mean nothing was written to that file.

---

## Files

| Path                                 | Purpose                            |
| ------------------------------------ | ---------------------------------- |
| `<out-dir>/STAMP-MANIFEST.txt`       | Audit trail for the run            |
| `$UTILZ_HOME/opt/stampz/stampz`      | Implementation                     |
| `$UTILZ_HOME/opt/stampz/stampz.yaml` | Metadata and declared dependencies |

---

## Environment

`stampz` reads no environment variables of its own.

---

## Exit Status

| Code | Meaning                                                                                |
| ---- | -------------------------------------------------------------------------------------- |
| `0`  | Every PDF in the pack was stamped                                                      |
| `1`  | Refused: bad arguments, no PDFs found, geometry it cannot read, or a page-count change |

There is no partial success. A refusal names the file and the reason.

---

## Dependencies

| Tool      | Required | Install                | Purpose                                      |
| --------- | -------- | ---------------------- | -------------------------------------------- |
| `qpdf`    | yes      | `brew install qpdf`    | Applies the stamp over every page            |
| `poppler` | yes      | `brew install poppler` | Page geometry and count; rendering for tests |

`utilz doctor` checks both.

---

## See Also

- `utilz help pdf2md` - PDF to Markdown conversion
- `utilz help expz` - batch expense receipt extraction
- `qpdf(1)`, `pdfinfo(1)`

---

## Author

Matthew Sinclair

---

## Copyright

(C) hello@matthewsinclair.com
