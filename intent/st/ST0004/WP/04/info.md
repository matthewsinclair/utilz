---
title: "WP/04: Tests"
status: completed
---

# WP/04: Tests

## Objective

Write comprehensive BATS tests (~12 tests) in two tiers: tier 1 always runs (no API key needed), tier 2 requires ANTHROPIC_API_KEY and is skipped in CI.

## Test Tiers

### Tier 1 (always run)
- `--help` shows help
- `--version` shows version
- Unknown option shows error
- Missing `--schema` shows error
- Missing `ANTHROPIC_API_KEY` shows error
- Nonexistent input file shows error
- Nonexistent schema file shows error
- `.pdf` input without pdf2md available shows error

### Tier 2 (skip without API key)
- Extract from sample.md produces valid JSON
- `--format csv` produces CSV output
- `--format table` produces table output
- Stdin piping works

## Guard

```bash
[[ -z "${ANTHROPIC_API_KEY:-}" ]] && skip "ANTHROPIC_API_KEY not set"
```

## Verification

```bash
utilz test xtrct   # Tier 1 always passes; tier 2 passes locally with API key
```
