# xtrct

**Version**: run `xtrct --version`
**Part of**: [Utilz Framework](../../README.md)

---

## Overview

Schema-driven semantic data extraction using Claude API. Takes a document and a JSON schema template, then uses Claude to semantically extract structured data as JSON. It works with any document type: write a different schema for each type.

---

## Installation

`xtrct` ships with the Utilz framework. `bin/xtrct` is a symlink to the `utilz` dispatcher.

On first run, xtrct creates a Python venv at `lib/.venv/` and installs the anthropic SDK.

Requires `ANTHROPIC_API_KEY` environment variable.

---

## Usage

```bash
xtrct <file> --schema <schema-file> [OPTIONS]
```

`utilz help xtrct` holds the options, the schema format, the output formats, examples and exit codes.

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

The dependencies are in `utilz help xtrct`.

---

## Testing

```bash
# Run tests (tier 2 skips without ANTHROPIC_API_KEY)
utilz test xtrct

# Run tests directly
cd opt/xtrct/test
bats xtrct.bats
```

---

## License

MIT. See [LICENSE](../../LICENSE).

---

## See Also

- [Utilz Framework Documentation](../../README.md)
- [xtrct Help](../../help/xtrct.md) - Run: `utilz help xtrct`
- [pdf2md](../pdf2md/README.md) - PDF to Markdown converter (composes with xtrct)
