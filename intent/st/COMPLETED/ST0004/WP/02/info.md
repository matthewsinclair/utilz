---
title: "WP/02: Bash Wrapper with Venv & API Key Check"
status: completed
---

# WP/02: Bash Wrapper with Venv & API Key Check

## Objective

Replace generated bash boilerplate with a venv-aware wrapper that checks for ANTHROPIC_API_KEY, detects PDF input requiring pdf2md, manages venv, and execs into the Python engine.

## Tasks

- [x] Fast path for `--help` / `--version` (before venv setup)
- [x] Check `ANTHROPIC_API_KEY` is set (fail-fast before venv creation)
- [x] Check `pdf2md` availability when `.pdf` input detected
- [x] Implement `ensure_venv()` same pattern as pdf2md
- [x] Export `UTILZ_HOME` so Python can locate `pdf2md` binary
- [x] Exec into `$VENV_DIR/bin/python3 "$LIB_DIR/xtrct.py" "$@"`

## Design

```
xtrct [args]
  ├─ --help / --version → handled immediately (no venv needed)
  └─ anything else
      ├─ check ANTHROPIC_API_KEY is set
      ├─ if .pdf input detected, check pdf2md is available
      ├─ check python3 available
      ├─ ensure_venv() → create lib/.venv/ if missing
      ├─ export UTILZ_HOME
      └─ exec $VENV_DIR/bin/python3 lib/xtrct.py "$@"
```

## Verification

```bash
# Clear errors for missing API key
unset ANTHROPIC_API_KEY && xtrct sample.md --schema schema.json

# Clear errors for missing pdf2md on .pdf input
xtrct input.pdf --schema schema.json  # when pdf2md not in PATH
```
