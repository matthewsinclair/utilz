---
title: "WP/04: Tests & Test Fixture"
status: completed
---

# WP/04: Tests & Test Fixture

## Objective

Generate a deterministic test PDF fixture and write comprehensive BATS tests (~15 tests) covering both bash wrapper behavior and Python conversion accuracy.

## Tasks

- [x] Generate test PDF fixture at `opt/pdf2md/test/fixtures/sample.pdf` using fpdf2
- [x] Fixture contains: 2 pages, heading, body text, list items, page footer
- [x] Commit output PDF only (not generator script)
- [x] Write `opt/pdf2md/test/pdf2md.bats` with ~15 tests

## Test Tiers

### Always run (no python3 required)
- `--help` shows help
- `--version` shows version
- Unknown option shows error
- No args shows usage
- Nonexistent file shows error
- Non-PDF file shows error

### Require python3
- Converts sample PDF to markdown
- `-o` writes output file
- Detects headings in output
- Detects list items in output
- `--pages` limits output to specified pages
- `--verbose` shows progress on stderr

## Verification

```bash
utilz test pdf2md   # All tests pass
```
