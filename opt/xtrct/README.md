# xtrct

**Version**: 1.0.0
**Part of**: [Utilz Framework](../../README.md)

---

## Overview

Schema-driven semantic data extraction using Claude API. Takes a document and a JSON schema template, then uses Claude to semantically extract structured data as JSON. Works with any document type — you just write a different schema.

---

## Installation

As part of the Utilz framework, `xtrct` is automatically available once the symlink is created:

```bash
cd $UTILZ_HOME/bin
ln -s utilz xtrct
```

On first run, xtrct automatically creates a Python venv at `lib/.venv/` and installs the anthropic SDK.

Requires `ANTHROPIC_API_KEY` environment variable.

---

## Usage

```bash
xtrct <file> --schema <schema-file> [OPTIONS]
```

For detailed help: `utilz help xtrct`

---

## Examples

```bash
# Extract from markdown
xtrct invoice.md --schema invoice_schema.json

# Extract from PDF (auto-converts via pdf2md)
xtrct invoice.pdf --schema invoice_schema.json

# Pipe from pdf2md
pdf2md invoice.pdf | xtrct --schema invoice_schema.json

# Different output formats
xtrct invoice.md --schema schema.json --format csv
xtrct invoice.md --schema schema.json --format table
```

---

## Implementation

### Architecture

```
xtrct
├── Bash wrapper: opt/xtrct/xtrct
│   ├── Sources common.sh
│   ├── Checks ANTHROPIC_API_KEY
│   ├── Checks pdf2md for .pdf input
│   ├── Manages venv at lib/.venv/
│   └── Execs into Python engine
├── Python engine: opt/xtrct/lib/xtrct.py
│   ├── anthropic SDK for Claude API
│   ├── JSON schema-driven prompt construction
│   └── json/csv/table output formatting
├── Dependencies: opt/xtrct/lib/requirements.txt
├── Help from: help/xtrct.md
└── Symlink: bin/xtrct → utilz
```

### Dependencies

**Required:**
- python3
- anthropic SDK (auto-installed in venv)
- `ANTHROPIC_API_KEY` environment variable

**Optional:**
- pdf2md (for .pdf input)

---

## Testing

```bash
# Run tests (tier 1 always passes, tier 2 requires API key)
utilz test xtrct

# Run tests directly
cd opt/xtrct/test
bats xtrct.bats
```

---

## License

Part of Utilz framework. Personal use.
Copyright (c) 2026 Matthew Sinclair

---

## See Also

- [Utilz Framework Documentation](../../README.md)
- [xtrct Help](../../help/xtrct.md) - Run: `utilz help xtrct`
- [pdf2md](../pdf2md/README.md) - PDF to Markdown converter (composes with xtrct)
