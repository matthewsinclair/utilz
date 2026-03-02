# Tasks - ST0005: pdf2md - PDF to Markdown Converter

## Tasks

- [x] Scaffold utility with `utilz generate pdf2md "PDF to Markdown converter"`
- [x] Add `lib/` directory with `requirements.txt` (pdfplumber)
- [x] Implement `lib/pdf2md.py` -- CLI arg parsing + full conversion pipeline
- [x] Update bash wrapper to manage venv and exec Python
- [x] Add test fixtures (sample.pdf generated with fpdf2)
- [x] Write BATS tests for basic conversion (15 tests, all passing)
- [x] Verify stdout output and -o file output both work
- [x] Verify --pages flag works
- [x] Verify --verbose shows progress on stderr

## Dependencies

- No upstream dependencies. This is a standalone utility.
- ST0004 (xtrct) depends on this being available.
