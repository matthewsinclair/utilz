---
title: "WP/05: Documentation & CI"
status: completed
---

# WP/05: Documentation & CI

## Objective

Write full help documentation, update project README, update CI workflow to include pdf2md in the Linux test loop and add python3-venv to Ubuntu dependencies.

## Tasks

- [x] Write `help/pdf2md.md` following existing help file pattern
- [x] Update `opt/pdf2md/README.md` with developer docs
- [x] Update `.github/workflows/tests.yml`: add `pdf2md` to Linux test loop
- [x] Update `.github/workflows/tests.yml`: add `python3-venv` to Ubuntu dependencies
- [x] Update `README.md`: add pdf2md to utility table

## Verification

```bash
utilz help pdf2md   # Renders help
utilz list          # Shows pdf2md with description
# CI passes on both Linux and macOS
```
