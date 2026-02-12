---
title: "WP/05: Documentation, CI & Release"
status: completed
---

# WP/05: Documentation, CI & Release

## Objective

Write full help documentation, update project README, CI workflow, CHANGELOG, and VERSION for the v1.3.0 release covering both pdf2md and xtrct utilities.

## Tasks

- [x] Write `help/xtrct.md` with schema format docs, examples, env vars
- [x] Update `opt/xtrct/README.md` with developer docs
- [x] Update `.github/workflows/tests.yml`: add `xtrct` to Linux test loop (tier 1 only)
- [x] Update `README.md`: add xtrct to utility table
- [x] Update `CHANGELOG.md`: add 1.3.0 release entry for both utilities
- [x] Update `VERSION` to 1.3.0

## Verification

```bash
utilz help xtrct   # Renders help
utilz list         # Shows xtrct with description
# CI passes
# CHANGELOG has both utilities documented
```
