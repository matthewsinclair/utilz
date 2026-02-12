---
verblock: "12 Feb 2026:v0.1: matts - Initial version"
intent_version: 2.2.0
status: WIP
created: 20260212
completed:
---
# ST0004: xtrct - Semantic Data Extraction

## Objective

Create a utilz utility that takes a document and a JSON schema template, then uses Claude API to semantically extract structured data as JSON. Works with any document type -- you just write a different schema.

## Context

Part of a composable document-processing pipeline with `pdf2md` (ST0005). While `pdf2md` handles PDF-to-markdown conversion locally, `xtrct` handles the semantic understanding step via Claude API. Together they enable: `pdf2md invoice.pdf | xtrct --schema invoice_schema.json`

The schema is **descriptive, not rigid** -- the `description` fields are what Claude uses to semantically locate data. This makes `xtrct` work for invoices, receipts, contracts, reports, etc.

## CLI Interface

```
xtrct <file> --schema <schema-file> [options]

Arguments:
  file                    Path to input document (.md, .txt, or .pdf)

Required:
  --schema <file>         JSON schema template describing what to extract

Options:
  --format <fmt>          Output format: json (default), csv, table
  --model <model>         Claude model (default: claude-sonnet-4-5-20250929)
  --verbose               Show progress to stderr
  --version               Show version
  --help                  Show help

Stdin:
  When no file argument is given, reads from stdin (for piping)
```

### Examples

```bash
# Extract from markdown (schema-driven)
xtrct invoice.md --schema invoice_schema.json

# Extract directly from PDF (auto-converts via pdf2md)
xtrct invoice.pdf --schema invoice_schema.json

# Pipe from pdf2md explicitly
pdf2md invoice.pdf | xtrct --schema invoice_schema.json

# Different output formats
xtrct invoice.pdf --schema schema.json --format csv
xtrct invoice.pdf --schema schema.json --format table

# Use a more capable model for complex docs
xtrct invoice.pdf --schema schema.json --model claude-opus-4-6
```

## Schema Template Format

```json
{
  "description": "Human-readable description of the document type",
  "fields": {
    "field_name": {
      "type": "string|number|boolean|date|array",
      "description": "What this field means -- Claude uses this to find it"
    },
    "nested_array": {
      "type": "array",
      "description": "What these items represent",
      "items": {
        "sub_field": {"type": "string", "description": "..."}
      }
    }
  }
}
```

The schema is descriptive -- the `description` fields tell Claude what to look for semantically. No rigid path expressions or regex patterns.

## Claude API Integration

- Uses `anthropic` Python SDK
- Requires `ANTHROPIC_API_KEY` environment variable
- Prompt construction: system prompt explains the extraction task, user message contains the schema + document content
- Requests JSON output, validates it parses correctly
- Default model: `claude-sonnet-4-5-20250929` (fast, capable enough for extraction)

## Utility Structure

```
opt/xtrct/
  xtrct                # Bash entry point
  xtrct.yaml           # Utilz metadata
  README.md
  lib/
    xtrct.py           # Python CLI + extraction logic
    requirements.txt   # anthropic
  test/
    xtrct.bats         # BATS tests
    fixtures/
      sample.md              # Test markdown document
      sample_schema.json     # Test schema
```

### Bash Wrapper Pattern

Standard utilz pattern:
- Sources `common.sh` if not already loaded
- Checks `python3` is available
- Checks `ANTHROPIC_API_KEY` is set
- For `.pdf` input: checks `pdf2md` is available (`command -v pdf2md`)
- Manages a venv in `lib/.venv/` (auto-creates and installs requirements.txt on first run)
- Execs `python3 "$SCRIPT_DIR/lib/xtrct.py" "$@"`

### Dependencies

- `anthropic` -- Claude API SDK

## Test Data for Verification

Use `pdf2md` output from the real invoice at:
```
/Users/matts/Library/CloudStorage/Dropbox/Sinclair-Shared/Property/AU/127 Talga Road Rothbury/Commercial/Suppliers/LAM - Eddie Lamb Electrical/Invoices/Paid/[PAID] 20241108 Lambs Electrical Invoice Nov-2153 1,536.13.pdf
```

With this invoice schema:
```json
{
  "description": "Australian trade invoice",
  "fields": {
    "supplier_name": {"type": "string", "description": "Business name of the supplier"},
    "supplier_abn": {"type": "string", "description": "Australian Business Number (11 digits)"},
    "invoice_number": {"type": "string", "description": "Invoice or reference number"},
    "invoice_date": {"type": "string", "description": "Invoice date as YYYY-MM-DD"},
    "due_date": {"type": "string", "description": "Payment due date as YYYY-MM-DD, or null"},
    "subtotal": {"type": "number", "description": "Subtotal excluding GST"},
    "gst": {"type": "number", "description": "GST amount"},
    "total": {"type": "number", "description": "Total including GST"},
    "line_items": {
      "type": "array",
      "description": "Individual line items on the invoice",
      "items": {
        "description": {"type": "string", "description": "Description of work or item"},
        "quantity": {"type": "number", "description": "Quantity, or null"},
        "unit_price": {"type": "number", "description": "Per-unit price, or null"},
        "amount": {"type": "number", "description": "Line total"}
      }
    }
  }
}
```

## Related Steel Threads

- ST0005: `pdf2md` -- this utility depends on pdf2md for handling PDF input
