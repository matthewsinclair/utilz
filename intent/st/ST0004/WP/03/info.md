---
title: "WP/03: Python Extraction Engine"
status: completed
---

# WP/03: Python Extraction Engine

## Objective

Implement `opt/xtrct/lib/xtrct.py` — the semantic data extraction engine that uses Claude API to extract structured data from documents according to a JSON schema.

## Pipeline

```
Input (file/stdin) → detect format (.pdf → pdf2md, else read directly)
  → read schema JSON → construct prompt (system + user)
  → call Claude API (anthropic SDK) → strip code fences → parse JSON
  → output as json/csv/table
```

## Tasks

- [x] Document reading: stdin support, `.pdf` shells out to `$UTILZ_HOME/bin/pdf2md`
- [x] Prompt construction: system prompt enforces precision/no-hallucination
- [x] JSON extraction: strip markdown fences before `json.loads()`
- [x] Output formats: `json` (pretty-print), `csv` (key/value rows), `table` (aligned columns)
- [x] Model: default `claude-sonnet-4-5-20250929`, configurable via `--model`
- [x] `--verbose`: token usage stats to stderr

## Verification

```bash
xtrct fixtures/sample.md --schema fixtures/sample_schema.json  # Returns valid JSON
```
