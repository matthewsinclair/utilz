# expz

**Version**: 1.0.0
**Author**: Matthew Sinclair

---

## Name

`expz` - Batch expense receipt PDF extraction to CSV

---

## Synopsis

```bash
expz <directory> [OPTIONS]
```

---

## Description

expz recursively finds PDF receipt files in category subdirectories, extracts
structured expense data from each using `xtrct` (Claude API), and outputs the
results as CSV.

The parent directory name of each PDF becomes the `Category` column in the
output. For example, a PDF at `receipts/Travel/train.pdf` gets Category "Travel".

Each PDF is converted to Markdown via `pdf2md`, then semantically parsed by
`xtrct` using a JSON schema that describes the fields to extract: date, supplier,
description, currency, subtotal, VAT, total, and reference number.

---

## Options

| Flag              | Short | Description                                                             |
| ----------------- | ----- | ----------------------------------------------------------------------- |
| `<directory>`     |       | Directory containing receipt PDFs in category subdirectories (required) |
| `--out <file>`    |       | Write CSV to file instead of stdout                                     |
| `--schema <file>` |       | Use custom xtrct schema (default: bundled expense_schema.json)          |
| `--verbose`       |       | Show progress to stderr                                                 |
| `--help`          | `-h`  | Show help message                                                       |
| `--version`       |       | Show version information                                                |

---

## CSV Output

```
Date,Category,Supplier,Description,Currency,Subtotal,VAT,Total,Reference,File
```

| Column      | Source         | Description                                  |
| ----------- | -------------- | -------------------------------------------- |
| Date        | xtrct (PDF)    | Receipt/invoice date as YYYY-MM-DD           |
| Category    | Directory name | Parent directory of the PDF (e.g. Travel)    |
| Supplier    | xtrct (PDF)    | Vendor or service provider name              |
| Description | xtrct (PDF)    | Short one-line summary of the expense        |
| Currency    | xtrct (PDF)    | ISO 4217 currency code (GBP, USD, EUR, etc.) |
| Subtotal    | xtrct (PDF)    | Amount before tax/VAT                        |
| VAT         | xtrct (PDF)    | VAT/tax amount (0 if none)                   |
| Total       | xtrct (PDF)    | Total amount paid                            |
| Reference   | xtrct (PDF)    | Invoice/receipt number                       |
| File        | Filesystem     | Relative path to source PDF                  |

---

## Directory Structure

expz expects receipt PDFs organized in category subdirectories:

```
receipts/
├── Hardware/
│   └── 20260218 Amazon monitor.pdf
├── Infrastructure/
│   └── 20251103 Fly.io Invoice.pdf
├── Travel/
│   └── 20260105 Hotel booking.pdf
└── ...
```

---

## Examples

### Basic Usage

```bash
# Output CSV to stdout
expz receipts/

# Write CSV to a file
expz receipts/ --out expenses.csv

# Show progress while processing
expz receipts/ --out expenses.csv --verbose
```

### Custom Schema

```bash
# Use a different extraction schema
expz receipts/ --schema my_schema.json
```

### Pipeline with xtrct

```bash
# expz composes xtrct internally:
#   PDF → pdf2md → markdown → xtrct + schema → JSON → jq → CSV
```

---

## Schema

The default extraction schema is bundled at `$UTILZ_HOME/opt/expz/lib/expense_schema.json`.
It defines 8 fields for `xtrct` to extract from each receipt:

- `date` — Receipt date as YYYY-MM-DD
- `supplier` — Vendor/merchant name
- `description` — Short one-line summary (max 80 chars)
- `currency` — ISO 4217 code (GBP, USD, EUR)
- `subtotal` — Pre-tax amount, or null
- `vat` — VAT/tax amount, or 0/null
- `total` — Total paid
- `reference` — Invoice/receipt number, or null

Override with `--schema <file>` to extract different fields.

---

## Files

- `$UTILZ_HOME/opt/expz/expz` - Bash implementation
- `$UTILZ_HOME/opt/expz/expz.yaml` - Metadata
- `$UTILZ_HOME/opt/expz/lib/expense_schema.json` - Default extraction schema
- `$UTILZ_HOME/bin/expz` - Symlink to dispatcher

---

## Environment

| Variable          | Description                                      |
| ----------------- | ------------------------------------------------ |
| ANTHROPIC_API_KEY | Required. Your Anthropic API key (used by xtrct) |
| UTILZ_HOME        | Root directory of Utilz framework                |

---

## Exit Status

- `0` - Success
- `1` - Error (missing args, missing tools, API failure, no PDFs found)

---

## Dependencies

- `xtrct` (required) - Schema-driven semantic data extraction; part of utilz framework
- `jq` (required) - JSON parsing and CSV assembly; `brew install jq`
- `pdf2md` (optional) - Called internally by xtrct for PDF input; part of utilz framework

---

## See Also

- `xtrct` - Schema-driven semantic data extraction (composes with expz)
- `pdf2md` - PDF to Markdown converter (called by xtrct)
- `utilz` - Utilz framework dispatcher

---

## Author

Matthew Sinclair

---

## Copyright

Copyright (c) 2026 Matthew Sinclair
Part of the Utilz framework.
