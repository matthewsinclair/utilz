# expz

**Version**: 1.0.0
**Part of**: [Utilz Framework](../../README.md)

---

## Overview

Batch expense receipt PDF extraction to CSV. Recursively finds PDF receipts in
category subdirectories, extracts structured data via `xtrct` (Claude API), and
outputs CSV to stdout or a file.

---

## Installation

As part of the Utilz framework, `expz` is automatically available once the symlink is created:

```bash
cd $UTILZ_HOME/bin
ln -s utilz expz
```

---

## Usage

```bash
expz <directory> [OPTIONS]
```

For detailed help: `utilz help expz`

---

## Examples

```bash
# Output CSV to stdout
expz receipts/

# Write to file with progress
expz receipts/ --out expenses.csv --verbose

# Custom extraction schema
expz receipts/ --schema custom_schema.json
```

---

## Implementation

### Architecture

```
expz <directory>
  │
  ├── find *.pdf recursively in <directory>
  │
  ├── for each PDF:
  │     ├── category = parent directory name
  │     ├── xtrct <pdf> --schema expense_schema.json --format json
  │     │   └── internally: pdf2md → markdown → Claude API → JSON
  │     ├── normalise JSON (handle array responses)
  │     └── jq: JSON → CSV row
  │
  └── output CSV (stdout or --out file)
```

### Key Files

```
opt/expz/
├── expz                       # Bash implementation
├── expz.yaml                  # Metadata (version, deps)
├── README.md                  # This file
├── lib/
│   └── expense_schema.json    # Default extraction schema
└── test/
    └── expz.bats              # BATS test suite
```

### Dependencies

**Required:**

- `xtrct` — Schema-driven semantic data extraction (utilz)
- `jq` — JSON parsing and CSV assembly (`brew install jq`)
- `ANTHROPIC_API_KEY` — Environment variable for Claude API

**Indirect:**

- `pdf2md` — Called internally by xtrct for PDF→Markdown conversion

---

## Testing

```bash
# Run tests
utilz test expz

# Run tests directly
cd opt/expz/test
bats expz.bats
```

---

## Development

### Making Changes

1. Edit `/Users/matts/Devel/prj/Utilz/opt/expz/expz`
2. Test changes: `expz --help`
3. Run tests: `utilz test expz`
4. Update help if needed: `/Users/matts/Devel/prj/Utilz/help/expz.md`

---

## License

Part of Utilz framework. Personal use.
Copyright (c) 2026 Matthew Sinclair

---

## See Also

- [Utilz Framework Documentation](../../README.md)
- [expz Help](../../help/expz.md) - Run: `utilz help expz`
