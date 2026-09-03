# stampz

**Version**: 1.0.0
**Part of**: [Utilz Framework](../../README.md)

---

## Overview

Stamp a recipient watermark across every page of every PDF in a directory, so a document pack handed to a named person carries their name. One rotated line of mono type reading `CONFIDENTIAL <date> <recipient>`, plus a `STAMP-MANIFEST.txt` recording the sha256 of every file before and after.

**This deters, it does not protect.** An overlay is strippable in seconds by anyone with a PDF tool, and the rotation scatters the mark's glyphs so no contiguous search finds the recipient -- which means a naive grep will neither leak the name out of the file nor identify a leaked copy. It marks a copy; it does not secure one.

Promoted into Utilz from a Lamplight tool (ST0011). The port replaced headless Chrome and a CDN font with a hand-assembled base-14 PDF, so it needs no browser and no network and runs anywhere `qpdf` and `poppler` do.

---

## Installation

As part of the Utilz framework, `stampz` is automatically available once the symlink is created:

```bash
cd $UTILZ_HOME/bin
ln -s utilz stampz
```

---

## Usage

```bash
stampz <pack-dir> "<recipient>" [OPTIONS]
```

For detailed help: `utilz help stampz`

---

## Examples

```bash
# Stamp a pack; copies land in <pack-dir>.stamped
stampz ~/packs/seriesA "Matthew Sinclair"

# Overwrite the pack itself
stampz ~/packs/seriesA "Matthew Sinclair" --in-place

# Show help
stampz --help

# Show version
stampz --version
```

---

## Implementation

### Architecture

```
stampz
├── Invoked via: $UTILZ_HOME/bin/stampz (symlink)
├── Dispatched by: $UTILZ_HOME/bin/utilz
├── Has access to: $UTILZ_HOME/opt/utilz/lib/common.sh
└── Help from: $UTILZ_HOME/help/stampz.md
```

### Dependencies

**Required:**

- Bash 4.0+ or Zsh

**Optional:**

- None

---

## Testing

```bash
# Run tests
utilz test stampz

# Run tests directly
cd opt/stampz/test
bats stampz.bats
```

---

## Development

### Making Changes

1. Edit `/Users/matts/Devel/prj/Utilz/opt/stampz/stampz`
2. Test changes: `stampz --help`
3. Run tests: `utilz test stampz`
4. Update help if needed: `/Users/matts/Devel/prj/Utilz/help/stampz.md`

---

## License

Part of Utilz framework. Personal use.
Copyright (c) 2026 Matthew Sinclair

---

## See Also

- [Utilz Framework Documentation](../../README.md)
- [stampz Help](../../help/stampz.md) - Run: `utilz help stampz`
