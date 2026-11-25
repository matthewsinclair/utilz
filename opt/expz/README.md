# expz

**Version**: run `expz --version`
**Part of**: [Utilz Framework](../../README.md)

---

## Overview

Batch expense receipt PDF extraction to CSV. Recursively finds PDF receipts in
category subdirectories, extracts structured data via `xtrct` (Claude API), and
outputs CSV to stdout or a file.

---

## Installation

`expz` comes with Utilz. Once Utilz is installed, as the [README](../../README.md#installation) says, `expz` is on your PATH.

---

## Usage

The usage home is `help/expz.md`. Run `utilz help expz` or `expz --help` to read it.

---

## Implementation

### Architecture

```
expz <directory>
  │
  ├── find *.pdf (any case) recursively in <directory>
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
├── expz.yaml                  # Metadata (deps)
├── VERSION                    # Version number
├── README.md                  # This file
├── lib/
│   └── expense_schema.json    # Default extraction schema
└── test/
    └── expz.bats              # BATS test suite
```

### Dependencies

**Required:**

- `xtrct` - Schema-driven semantic data extraction (utilz)
- `jq` - JSON parsing and CSV assembly (`brew install jq`)
- `ANTHROPIC_API_KEY` - Environment variable for Claude API

**Indirect:**

- `pdf2md` - Called internally by xtrct for PDF→Markdown conversion

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

1. Edit `opt/expz/expz`
2. Test changes: `expz --help`
3. Run tests: `utilz test expz`
4. Update help if needed: `help/expz.md`

---

## License

MIT. See [LICENSE](../../LICENSE).

---

## See Also

- [Utilz Framework Documentation](../../README.md)
- [expz Help](../../help/expz.md) - Run: `utilz help expz`
