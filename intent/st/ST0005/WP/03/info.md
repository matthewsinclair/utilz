---
title: "WP/03: Python Conversion Engine"
status: completed
---

# WP/03: Python Conversion Engine

## Objective

Implement `opt/pdf2md/lib/pdf2md.py` — the core PDF-to-markdown conversion algorithm ported from pdf2md.morethan.io, using pdfplumber for text extraction.

## Pipeline Stages

| Stage | Description                                                                  |
|-------|------------------------------------------------------------------------------|
| 1     | Extract text items via `page.chars` → `{x, y, w, h, text, font_name, size}` |
| 2     | Calculate global stats: `most_used_height` (mode), `most_used_font`          |
| 3     | Group into lines by Y-position (tolerance ~2px), sort by X within lines      |
| 4     | Detect headings: `font_size > body` → H1-H6 by descending unique sizes      |
| 5     | Detect list items: bullets, `-`, `*`, `1.`, `(a)` patterns                   |
| 6     | Remove repetitive headers/footers (same text+Y on >50% of pages)            |
| 7     | Compact and emit: merge fragments, join paragraphs, emit markdown            |

## Tasks

- [x] Implement CLI via argparse: `pdf2md <file> [-o output] [--pages range] [--verbose]`
- [x] Use `page.chars` for font metadata per character
- [x] Cluster chars into spans by font, then into lines by Y-proximity
- [x] `Counter(font_sizes).most_common(1)` for body text detection
- [x] `--pages` parses ranges like `1-5,7,10-12`
- [x] `--verbose` prints progress to stderr
- [x] Handle empty/no-text PDFs gracefully

## Verification

```bash
pdf2md test/fixtures/sample.pdf   # Outputs markdown with headings and lists
```
