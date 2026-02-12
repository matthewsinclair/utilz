---
title: "WP/01: Scaffold & Metadata"
status: completed
---

# WP/01: Scaffold & Metadata

## Objective

Bootstrap the xtrct utility using `utilz generate`, set up the Python project structure with lib/ directory, requirements.txt, update metadata with python3 and optional pdf2md dependencies, and create test fixtures.

## Tasks

- [x] Run `utilz generate xtrct "Schema-driven semantic data extraction" "Matthew Sinclair"`
- [x] Create `opt/xtrct/lib/` directory
- [x] Create `opt/xtrct/lib/requirements.txt` with anthropic>=0.39.0
- [x] Update `opt/xtrct/xtrct.yaml` with python3 dep and pdf2md optional dep
- [x] Create `opt/xtrct/test/fixtures/sample.md` (mock invoice markdown)
- [x] Create `opt/xtrct/test/fixtures/sample_schema.json` (invoice extraction schema)
- [x] Verify: `xtrct --help`, `xtrct --version`, `utilz list` shows xtrct

## Verification

```bash
xtrct --help      # Shows help
xtrct --version   # Shows version
utilz list        # Lists xtrct
```
