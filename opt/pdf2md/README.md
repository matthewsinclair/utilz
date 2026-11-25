# pdf2md

**Version**: run `pdf2md --version`
**Part of**: [Utilz Framework](../../README.md)

---

## Overview

PDF to Markdown converter using pdfplumber. Detects headings, list items, and paragraph structure from font size and position metadata. Python port of [pdf2md.morethan.io](https://pdf2md.morethan.io/).

---

## Installation

`pdf2md` ships with the Utilz framework. `bin/pdf2md` is a symlink to the `utilz` dispatcher.

On first run, pdf2md creates a Python venv at `lib/.venv/` and installs pdfplumber.

---

## Usage

```bash
pdf2md <file> [OPTIONS]
```

`utilz help pdf2md` holds the options, page ranges, examples and exit codes.

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

The dependencies are in `utilz help pdf2md`.

---

## Testing

```bash
# Run tests (tier 2 skips without python3)
utilz test pdf2md

# Run tests directly
cd opt/pdf2md/test
bats pdf2md.bats
```

---

## License

MIT. See [LICENSE](../../LICENSE).

---

## See Also

- [Utilz Framework Documentation](../../README.md)
- [pdf2md Help](../../help/pdf2md.md) - Run: `utilz help pdf2md`
- [xtrct](../xtrct/README.md) - Schema-driven semantic extraction (composes with pdf2md)
