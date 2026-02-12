# pdf2md

**Version**: 1.0.0
**Part of**: [Utilz Framework](../../README.md)

---

## Overview

PDF to Markdown converter using pdfplumber. Detects headings, list items, and paragraph structure from font size and position metadata. Python port of [pdf2md.morethan.io](https://pdf2md.morethan.io/).

---

## Installation

As part of the Utilz framework, `pdf2md` is automatically available once the symlink is created:

```bash
cd $UTILZ_HOME/bin
ln -s utilz pdf2md
```

On first run, pdf2md automatically creates a Python venv at `lib/.venv/` and installs pdfplumber.

---

## Usage

```bash
pdf2md <file> [OPTIONS]
```

For detailed help: `utilz help pdf2md`

---

## Examples

```bash
# Convert PDF to stdout
pdf2md invoice.pdf

# Save to file
pdf2md invoice.pdf -o invoice.md

# Specific pages only
pdf2md large.pdf --pages 1-5

# Pipe to xtrct for semantic extraction
pdf2md invoice.pdf | xtrct --schema invoice_schema.json
```

---

## Implementation

### Architecture

```
pdf2md
├── Bash wrapper: opt/pdf2md/pdf2md
│   ├── Sources common.sh
│   ├── Manages venv at lib/.venv/
│   └── Execs into Python engine
├── Python engine: opt/pdf2md/lib/pdf2md.py
│   ├── pdfplumber for text extraction
│   └── 7-stage conversion pipeline
├── Dependencies: opt/pdf2md/lib/requirements.txt
├── Help from: help/pdf2md.md
└── Symlink: bin/pdf2md → utilz
```

### Dependencies

**Required:**
- python3
- pdfplumber (auto-installed in venv)

---

## Testing

```bash
# Run tests
utilz test pdf2md

# Run tests directly
cd opt/pdf2md/test
bats pdf2md.bats
```

---

## License

Part of Utilz framework. Personal use.
Copyright (c) 2026 Matthew Sinclair

---

## See Also

- [Utilz Framework Documentation](../../README.md)
- [pdf2md Help](../../help/pdf2md.md) - Run: `utilz help pdf2md`
- [xtrct](../xtrct/README.md) - Schema-driven semantic extraction (composes with pdf2md)
