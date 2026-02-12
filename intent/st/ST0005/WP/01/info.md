---
title: "WP/01: Scaffold & Metadata"
status: completed
---

# WP/01: Scaffold & Metadata

## Objective

Bootstrap the pdf2md utility using `utilz generate`, set up the Python project structure with lib/ directory, requirements.txt, and update metadata with python3 dependency.

## Tasks

- [x] Run `utilz generate pdf2md "PDF to Markdown converter" "Matthew Sinclair"`
- [x] Create `opt/pdf2md/lib/` directory
- [x] Create `opt/pdf2md/lib/requirements.txt` with pdfplumber>=0.10.0
- [x] Update `opt/pdf2md/pdf2md.yaml` with python3 dependency
- [x] Create `opt/pdf2md/test/fixtures/` directory
- [x] Add `opt/*/lib/.venv/` to `.gitignore`
- [x] Verify: `pdf2md --help`, `pdf2md --version`, `utilz list` shows pdf2md

## Verification

```bash
pdf2md --help      # Shows help
pdf2md --version   # Shows version
utilz list         # Lists pdf2md
```
