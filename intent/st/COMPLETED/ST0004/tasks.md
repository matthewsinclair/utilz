# Tasks - ST0004: xtrct - Semantic Data Extraction

## Tasks

- [x] Scaffold utility with `utilz generate xtrct "Schema-driven semantic data extraction"`
- [x] Add `lib/` directory with `requirements.txt` (anthropic)
- [x] Implement `lib/xtrct.py` -- CLI arg parsing, prompt construction, API call, output formatting
- [x] Update bash wrapper to manage venv, check ANTHROPIC_API_KEY, exec Python
- [x] Add test fixtures (sample.md + sample_schema.json)
- [x] Write BATS tests (8 tier-1 + 4 tier-2 = 12 tests)
- [x] Verify --format json/csv/table outputs
- [x] Verify stdin piping works

## Dependencies

- Depends on ST0005 (pdf2md) for PDF input handling
- Requires `ANTHROPIC_API_KEY` environment variable
