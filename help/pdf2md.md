# pdf2md

**Version**: 1.0.0
**Author**: Matthew Sinclair

---

## Name

`pdf2md` - PDF to Markdown converter

---

## Synopsis

```bash
pdf2md <file> [OPTIONS]
```

---

## Description

pdf2md converts PDF files to clean markdown using local algorithmic extraction with pdfplumber. It detects headings, list items, and paragraph structure based on font size and position metadata.

The algorithm is a Python port of [pdf2md.morethan.io](https://pdf2md.morethan.io/), using pdfplumber instead of pdfjs-dist for text extraction.

On first run, pdf2md automatically creates a Python virtual environment at `lib/.venv/` and installs dependencies.

---

## Options

| Flag                 | Short | Description                               |
|----------------------|-------|-------------------------------------------|
| `--output <file>`    | `-o`  | Write to file instead of stdout           |
| `--pages <range>`    |       | Page range (e.g., "1-5", "3,7,10-12")    |
| `--verbose`          |       | Show progress to stderr                   |
| `--help`             | `-h`  | Show help message                         |
| `--version`          |       | Show version information                  |

---

## Page Ranges

The `--pages` option accepts comma-separated page numbers and ranges:

- `--pages 1` — first page only
- `--pages 1-5` — pages 1 through 5
- `--pages 1,3,5` — specific pages
- `--pages 1-3,7,10-12` — mixed ranges and singles

Page numbers are 1-based.

---

## Conversion Pipeline

| Stage | Description                                                             |
|-------|-------------------------------------------------------------------------|
| 1     | Extract text items with position/font metadata via pdfplumber           |
| 2     | Calculate body text font size (statistical mode) and font name          |
| 3     | Group characters into lines by Y-position, sort by X within lines       |
| 4     | Detect headings: font size > body → H1-H6 by descending unique sizes   |
| 5     | Detect list items: bullets, dashes, numbered, lettered patterns         |
| 6     | Remove repetitive headers/footers (same text+Y on >50% of pages)       |
| 7     | Compact and emit: merge fragments, join paragraphs, emit markdown       |

---

## Examples

### Basic Usage

```bash
# Convert PDF to stdout
pdf2md invoice.pdf

# Save to file
pdf2md invoice.pdf -o invoice.md

# Pipe to other tools
pdf2md invoice.pdf | grep "Total"
```

### Page Selection

```bash
# First 5 pages only
pdf2md large-document.pdf --pages 1-5

# Specific pages
pdf2md report.pdf --pages 1,3,5-7
```

### Pipeline with xtrct

```bash
# Convert and extract structured data
pdf2md invoice.pdf | xtrct --schema invoice_schema.json

# Or let xtrct handle the conversion
xtrct invoice.pdf --schema invoice_schema.json
```

### Verbose Mode

```bash
# Show conversion progress
pdf2md document.pdf --verbose
```

---

## Files

- `$UTILZ_HOME/opt/pdf2md/pdf2md` - Bash wrapper
- `$UTILZ_HOME/opt/pdf2md/lib/pdf2md.py` - Python conversion engine
- `$UTILZ_HOME/opt/pdf2md/lib/requirements.txt` - Python dependencies
- `$UTILZ_HOME/opt/pdf2md/pdf2md.yaml` - Metadata
- `$UTILZ_HOME/bin/pdf2md` - Symlink to dispatcher

---

## Environment

- `UTILZ_HOME` - Root directory of Utilz framework

---

## Exit Status

- `0` - Success
- `1` - Error (file not found, not a PDF, conversion failure)

---

## Dependencies

- `python3` (required) - Python 3 runtime; `brew install python3`
- `pdfplumber` (auto-installed) - PDF text extraction library

---

## See Also

- `xtrct` - Schema-driven semantic data extraction (composes with pdf2md)
- `utilz` - Utilz framework dispatcher

---

## Author

Matthew Sinclair

---

## Copyright

Copyright (c) 2026 Matthew Sinclair
Part of the Utilz framework.
