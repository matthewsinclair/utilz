---
verblock: "12 Feb 2026:v0.1: matts - Initial version"
intent_version: 2.2.0
status: WIP
created: 20260212
completed:
---
# ST0005: pdf2md - PDF to Markdown Converter

## Objective

Create a standalone utilz utility that converts PDF files to clean markdown using local algorithmic extraction (no ML). Useful for feeding documents to LLMs, archiving, search indexing, and as a composable building block for document pipelines.

## Context

We need to extract structured data from supplier invoice PDFs in the Talga Road project. Rather than a monolithic tool, we're building two composable utilities: `pdf2md` (this steel thread) converts PDF to markdown, and `xtrct` (ST0004) semantically extracts structured data from documents using Claude API.

These compose: `pdf2md invoice.pdf | xtrct --schema invoice_schema.json`

The algorithm is a port of [pdf2md.morethan.io](https://pdf2md.morethan.io/) / [jzillmann/pdf-to-markdown](https://github.com/jzillmann/pdf-to-markdown), reimplemented in Python using `pdfplumber` instead of `pdfjs-dist`.

## CLI Interface

```
pdf2md <file> [options]

Arguments:
  file              Path to PDF file

Options:
  -o, --output <file>   Write to file instead of stdout
  --pages <range>        Page range (e.g., "1-5", "3,7,10-12")
  --verbose              Show progress to stderr
  --version              Show version
  --help                 Show help
```

### Examples

```bash
pdf2md invoice.pdf                           # Convert to stdout
pdf2md invoice.pdf -o invoice.md             # Save to file
pdf2md invoice.pdf | grep "Total"            # Pipe to other tools
pdf2md large-document.pdf --pages 1-5        # Specific pages
```

## Algorithm (ported from pdf2md.morethan.io)

The original JS project uses `pdfjs-dist` (Mozilla pdf.js) to extract text items with position/font data, then runs a transformation pipeline. We reimplement the same logic in Python using `pdfplumber` (which provides equivalent per-character position, font-name, font-size data).

**Pipeline stages:**

1. **Extract text items**: For each page, get every text span with `{x, y, width, height, text, font_name, font_size}` via `pdfplumber`'s character/word extraction.

2. **Calculate global stats**: Find `most_used_height` (body text font size -- the statistical mode), `most_used_font`, and `max_height` across the entire document.

3. **Group into lines**: Cluster text items into lines by Y-position (items within a Y-tolerance are on the same line). Sort items within each line by X-position. Concatenate with appropriate spacing.

4. **Detect headings**: Lines with font size > `most_used_height` -> headings. Assign H1-H6 by sorting unique above-body heights descending (largest = H1, etc.). Also detect ALL-CAPS lines in body font-size but different font-face as paragraph headings.

5. **Detect list items**: Lines starting with bullet chars, `-`, `*`, or `1.`/`(a)` patterns -> markdown list syntax.

6. **Remove repetitive elements**: If the same text appears at the same Y-position on most pages -> header/footer -> remove.

7. **Compact and emit**: Merge text fragments within lines. Join consecutive body-text lines into paragraphs. Emit with markdown heading prefixes (`#`, `##`, etc.) and list markers.

## Utility Structure

```
opt/pdf2md/
  pdf2md               # Bash entry point (sources common.sh, execs python)
  pdf2md.yaml          # Utilz metadata
  README.md
  lib/
    pdf2md.py          # Python CLI + conversion engine
    requirements.txt   # pdfplumber
  test/
    pdf2md.bats        # BATS tests
    fixtures/
      sample.pdf       # Test PDF
```

### Bash Wrapper Pattern

Standard utilz pattern:

- Sources `common.sh` if not already loaded
- Checks `python3` is available
- Manages a venv in `lib/.venv/` (auto-creates and installs requirements.txt on first run)
- Execs `python3 "$SCRIPT_DIR/lib/pdf2md.py" "$@"`

### Dependencies

- `pdfplumber` -- lightweight PDF text extraction with layout data (no PyTorch, no ML)

## Test PDF for Verification

Use the real invoice at:

```
/Users/matts/Library/CloudStorage/Dropbox/Sinclair-Shared/Property/AU/127 Talga Road Rothbury/Commercial/Suppliers/LAM - Eddie Lamb Electrical/Invoices/Paid/[PAID] 20241108 Lambs Electrical Invoice Nov-2153 1,536.13.pdf
```

## Related Steel Threads

- ST0004: `xtrct` -- depends on this utility for PDF-to-markdown conversion
