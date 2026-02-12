# xtrct

**Version**: 1.0.0
**Author**: Matthew Sinclair

---

## Name

`xtrct` - Schema-driven semantic data extraction using Claude API

---

## Synopsis

```bash
xtrct <file> --schema <schema-file> [OPTIONS]
xtrct --schema <schema-file> [OPTIONS] < input.md
```

---

## Description

xtrct takes a document and a JSON schema template, then uses Claude API to semantically extract structured data as JSON. Works with any document type — you just write a different schema.

For PDF input, xtrct automatically converts via `pdf2md` before extraction. For markdown/text input, the content is sent directly to Claude.

The schema is **descriptive, not rigid** — the `description` fields are what Claude uses to semantically locate data. This makes xtrct work for invoices, receipts, contracts, reports, etc.

On first run, xtrct automatically creates a Python virtual environment at `lib/.venv/` and installs dependencies.

---

## Options

| Flag              | Short | Description                                     |
|-------------------|-------|-------------------------------------------------|
| `--schema <file>` |       | JSON schema template (required)                 |
| `--format <fmt>`  |       | Output format: json (default), csv, table       |
| `--model <model>` |       | Claude model (default: claude-haiku-4-5-latest) |
| `--verbose`       |       | Show progress and token usage to stderr         |
| `--help`          | `-h`  | Show help message                               |
| `--version`       |       | Show version information                        |

---

## Schema Format

The schema is a JSON file describing what data to extract:

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

### Field Types

| Type      | Description                               |
|-----------|-------------------------------------------|
| `string`  | Text value                                |
| `number`  | Numeric value (integers or decimals)      |
| `boolean` | True/false value                          |
| `date`    | Date value (format in description)        |
| `array`   | List of items (define `items` sub-fields) |

### Schema Design Tips

- The `description` field is what Claude uses to semantically locate data
- Be specific: "Invoice date as YYYY-MM-DD" is better than "date"
- Use "or null" in descriptions for optional fields
- For arrays, define the structure of each item in `items`

---

## Output Formats

### json (default)

Pretty-printed JSON matching the schema field names.

### csv

Scalar fields as key/value rows. Array fields as sections with header rows followed by data rows.

### table

Aligned text table. Scalar fields in a key/value layout, array fields in tabular format with column headers.

---

## Examples

### Basic Usage

```bash
# Extract from markdown
xtrct invoice.md --schema invoice_schema.json

# Extract from PDF (auto-converts via pdf2md)
xtrct invoice.pdf --schema invoice_schema.json

# Pipe from pdf2md
pdf2md invoice.pdf | xtrct --schema invoice_schema.json
```

### Output Formats

```bash
# JSON (default)
xtrct invoice.md --schema schema.json

# CSV
xtrct invoice.md --schema schema.json --format csv

# Aligned table
xtrct invoice.md --schema schema.json --format table
```

### Model Selection

```bash
# Use a more capable model for complex documents
xtrct complex.pdf --schema schema.json --model claude-opus-4-6

# Default model (fast, good for most extractions)
xtrct invoice.md --schema schema.json
```

### Verbose Mode

```bash
# Show progress and token usage
xtrct invoice.md --schema schema.json --verbose
```

### Stdin Piping

```bash
# Pipe markdown content
cat document.md | xtrct --schema schema.json

# Chain with pdf2md
pdf2md invoice.pdf --pages 1-3 | xtrct --schema schema.json
```

---

## Example Schema: Invoice

```json
{
  "description": "Australian trade invoice",
  "fields": {
    "supplier_name": {"type": "string", "description": "Business name of the supplier"},
    "supplier_abn": {"type": "string", "description": "Australian Business Number (11 digits)"},
    "invoice_number": {"type": "string", "description": "Invoice or reference number"},
    "invoice_date": {"type": "string", "description": "Invoice date as YYYY-MM-DD"},
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

---

## Files

- `$UTILZ_HOME/opt/xtrct/xtrct` - Bash wrapper
- `$UTILZ_HOME/opt/xtrct/lib/xtrct.py` - Python extraction engine
- `$UTILZ_HOME/opt/xtrct/lib/requirements.txt` - Python dependencies
- `$UTILZ_HOME/opt/xtrct/xtrct.yaml` - Metadata
- `$UTILZ_HOME/bin/xtrct` - Symlink to dispatcher

---

## Environment

| Variable            | Description                       |
|---------------------|-----------------------------------|
| `ANTHROPIC_API_KEY` | Required. Your Anthropic API key  |
| `UTILZ_HOME`        | Root directory of Utilz framework |

---

## Exit Status

- `0` - Success
- `1` - Error (missing API key, file not found, API failure, invalid JSON)

---

## Dependencies

- `python3` (required) - Python 3 runtime; `brew install python3`
- `anthropic` (auto-installed) - Anthropic Python SDK
- `pdf2md` (optional) - Required for `.pdf` input; part of utilz framework

---

## See Also

- `pdf2md` - PDF to Markdown converter (composes with xtrct)
- `utilz` - Utilz framework dispatcher

---

## Author

Matthew Sinclair

---

## Copyright

Copyright (c) 2026 Matthew Sinclair
Part of the Utilz framework.
