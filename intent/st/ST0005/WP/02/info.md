---
title: "WP/02: Bash Wrapper with Venv Management"
status: completed
---

# WP/02: Bash Wrapper with Venv Management

## Objective

Replace generated bash boilerplate with a venv-aware wrapper that handles --help/--version on the fast path (before venv setup), auto-creates a Python venv with pip-installed requirements on first run, and execs into the Python engine.

## Tasks

- [x] Implement `ensure_venv()` that creates `lib/.venv/` and pip-installs requirements
- [x] Fast path for `--help` / `--version` (before venv setup)
- [x] Check `python3` availability via `check_command`
- [x] Exec into `$VENV_DIR/bin/python3 "$LIB_DIR/pdf2md.py" "$@"`
- [x] Verify: `pdf2md --help` is instant; `pdf2md nonexistent.pdf` triggers venv creation

## Design

```
pdf2md [args]
  ├─ --help / --version → handled immediately (no venv needed)
  └─ anything else
      ├─ check python3 available
      ├─ ensure_venv() → create lib/.venv/ if missing, pip install requirements.txt
      └─ exec $VENV_DIR/bin/python3 lib/pdf2md.py "$@"
```
