# Tasks - ST0004: xtrct - Semantic Data Extraction

## Tasks

- [ ] Scaffold utility with `utilz generate xtrct "Schema-driven semantic data extraction"`
- [ ] Add `lib/` directory with `requirements.txt` (anthropic)
- [ ] Implement `lib/xtrct.py` -- CLI arg parsing, prompt construction, API call, output formatting
- [ ] Update bash wrapper to manage venv, check ANTHROPIC_API_KEY, exec Python
- [ ] Add test fixtures (sample.md + sample_schema.json)
- [ ] Write BATS tests (at minimum: --help, missing schema error, missing API key error)
- [ ] Test with markdown input + invoice schema
- [ ] Test PDF input (requires pdf2md from ST0005 to be installed)
- [ ] Verify --format json/csv/table outputs
- [ ] Verify stdin piping works

## Dependencies

- Depends on ST0005 (pdf2md) for PDF input handling
- Requires `ANTHROPIC_API_KEY` environment variable
