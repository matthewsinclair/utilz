# Tasks - ST0005: pdf2md - PDF to Markdown Converter

## Tasks

- [ ] Scaffold utility with `utilz generate pdf2md "PDF to Markdown converter"`
- [ ] Add `lib/` directory with `requirements.txt` (pdfplumber)
- [ ] Implement `lib/pdf2md.py` -- CLI arg parsing + full conversion pipeline
- [ ] Update bash wrapper to manage venv and exec Python
- [ ] Add test fixtures (sample.pdf or use the real invoice)
- [ ] Write BATS tests for basic conversion
- [ ] Test with real invoice PDF (Lambs Electrical)
- [ ] Verify stdout output and -o file output both work
- [ ] Verify --pages flag works
- [ ] Verify --verbose shows progress on stderr

## Dependencies

- No upstream dependencies. This is a standalone utility.
- ST0004 (xtrct) depends on this being available.
