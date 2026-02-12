#!/usr/bin/env python3
"""
xtrct - Schema-driven semantic data extraction

Uses Claude API to semantically extract structured data from documents
according to a JSON schema template. Supports markdown, text, and PDF input
(PDF requires pdf2md utility).
"""

import argparse
import csv
import io
import json
import os
import re
import subprocess
import sys

import anthropic


DEFAULT_MODEL = "claude-sonnet-4-5-20250929"


# ============================================================================
# DOCUMENT READING
# ============================================================================

def read_document(file_path, verbose=False):
    """Read document content. For PDFs, shells out to pdf2md."""
    if file_path is None:
        # Read from stdin
        content = sys.stdin.read()
        if not content.strip():
            print("Error: No input received from stdin", file=sys.stderr)
            sys.exit(1)
        if verbose:
            print(f"Read {len(content)} chars from stdin", file=sys.stderr)
        return content

    if not os.path.isfile(file_path):
        print(f"Error: File not found: {file_path}", file=sys.stderr)
        sys.exit(1)

    if file_path.lower().endswith(".pdf"):
        return convert_pdf(file_path, verbose)

    with open(file_path, "r") as f:
        content = f.read()
    if verbose:
        print(f"Read {len(content)} chars from {file_path}", file=sys.stderr)
    return content


def convert_pdf(file_path, verbose=False):
    """Convert PDF to markdown using pdf2md."""
    utilz_home = os.environ.get("UTILZ_HOME", "")
    pdf2md_path = os.path.join(utilz_home, "bin", "pdf2md") if utilz_home else "pdf2md"

    try:
        result = subprocess.run(
            [pdf2md_path, file_path],
            capture_output=True, text=True, check=True,
        )
        if verbose:
            print(f"Converted PDF via pdf2md: {len(result.stdout)} chars", file=sys.stderr)
        return result.stdout
    except FileNotFoundError:
        print("Error: pdf2md not found. Install it to process PDF files.", file=sys.stderr)
        sys.exit(1)
    except subprocess.CalledProcessError as e:
        print(f"Error: pdf2md failed: {e.stderr}", file=sys.stderr)
        sys.exit(1)


# ============================================================================
# SCHEMA HANDLING
# ============================================================================

def load_schema(schema_path):
    """Load and validate a JSON schema file."""
    if not os.path.isfile(schema_path):
        print(f"Error: Schema file not found: {schema_path}", file=sys.stderr)
        sys.exit(1)

    try:
        with open(schema_path, "r") as f:
            schema = json.load(f)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in schema file: {e}", file=sys.stderr)
        sys.exit(1)

    if "fields" not in schema:
        print("Error: Schema must contain a 'fields' object", file=sys.stderr)
        sys.exit(1)

    return schema


# ============================================================================
# PROMPT CONSTRUCTION
# ============================================================================

def build_system_prompt():
    """Build the system prompt for Claude."""
    return """You are a precise document data extractor. Your task is to extract structured data from documents according to a provided schema.

Rules:
- Extract ONLY data that is explicitly present in the document
- Never hallucinate or infer data that isn't clearly stated
- Use null for fields where the data is not found or unclear
- For dates, convert to the format specified in the schema description
- For numbers, extract the numeric value without currency symbols or commas
- Return ONLY valid JSON matching the schema structure, no explanations
- Wrap your JSON response in ```json code fences"""


def build_user_prompt(schema, document):
    """Build the user prompt with schema and document content."""
    schema_desc = schema.get("description", "Document")
    fields_json = json.dumps(schema["fields"], indent=2)

    return f"""Extract data from the following {schema_desc}.

Schema (extract these fields):
```json
{fields_json}
```

Document:
---
{document}
---

Return the extracted data as JSON matching the schema field names."""


# ============================================================================
# API CALL
# ============================================================================

def call_claude(system_prompt, user_prompt, model, verbose=False):
    """Call Claude API and return the response text."""
    client = anthropic.Anthropic()

    if verbose:
        print(f"Calling {model}...", file=sys.stderr)

    try:
        response = client.messages.create(
            model=model,
            max_tokens=4096,
            system=system_prompt,
            messages=[{"role": "user", "content": user_prompt}],
        )
    except anthropic.AuthenticationError:
        print("Error: Invalid ANTHROPIC_API_KEY", file=sys.stderr)
        sys.exit(1)
    except anthropic.APIError as e:
        print(f"Error: API call failed: {e}", file=sys.stderr)
        sys.exit(1)

    if verbose:
        usage = response.usage
        print(
            f"Tokens: {usage.input_tokens} input, {usage.output_tokens} output",
            file=sys.stderr,
        )

    return response.content[0].text


# ============================================================================
# JSON EXTRACTION
# ============================================================================

def extract_json(response_text):
    """Extract JSON from response, stripping code fences if present."""
    # Try to find JSON in code fences
    match = re.search(r"```(?:json)?\s*\n?(.*?)```", response_text, re.DOTALL)
    if match:
        json_str = match.group(1).strip()
    else:
        json_str = response_text.strip()

    try:
        return json.loads(json_str)
    except json.JSONDecodeError as e:
        print(f"Error: Failed to parse extraction result as JSON: {e}", file=sys.stderr)
        print(f"Raw response:\n{response_text}", file=sys.stderr)
        sys.exit(1)


# ============================================================================
# OUTPUT FORMATTING
# ============================================================================

def format_json(data):
    """Pretty-print JSON output."""
    return json.dumps(data, indent=2, ensure_ascii=False)


def format_csv(data):
    """Format data as CSV. Scalars as key/value rows, arrays as sections."""
    output = io.StringIO()
    writer = csv.writer(output)

    for key, value in data.items():
        if isinstance(value, list):
            if not value:
                continue
            # Array section: header row + data rows
            writer.writerow([])
            headers = list(value[0].keys()) if isinstance(value[0], dict) else [key]
            writer.writerow(headers)
            for item in value:
                if isinstance(item, dict):
                    writer.writerow([item.get(h, "") for h in headers])
                else:
                    writer.writerow([item])
        else:
            writer.writerow([key, "" if value is None else value])

    return output.getvalue()


def format_table(data):
    """Format data as an aligned text table."""
    lines = []

    # Scalar fields
    scalar_items = [(k, v) for k, v in data.items() if not isinstance(v, list)]
    if scalar_items:
        max_key_len = max(len(k) for k, _ in scalar_items)
        for key, value in scalar_items:
            display_val = "" if value is None else str(value)
            lines.append(f"  {key:<{max_key_len}}  {display_val}")

    # Array fields
    for key, value in data.items():
        if not isinstance(value, list) or not value:
            continue

        lines.append("")
        lines.append(f"  {key}:")

        if isinstance(value[0], dict):
            headers = list(value[0].keys())
            col_widths = {h: len(h) for h in headers}
            for item in value:
                for h in headers:
                    val_str = str(item.get(h, ""))
                    if len(val_str) > col_widths[h]:
                        col_widths[h] = len(val_str)

            header_line = "  ".join(h.ljust(col_widths[h]) for h in headers)
            sep_line = "  ".join("-" * col_widths[h] for h in headers)
            lines.append(f"    {header_line}")
            lines.append(f"    {sep_line}")

            for item in value:
                row = "  ".join(
                    str(item.get(h, "")).ljust(col_widths[h]) for h in headers
                )
                lines.append(f"    {row}")
        else:
            for item in value:
                lines.append(f"    - {item}")

    return "\n".join(lines) + "\n"


# ============================================================================
# CLI
# ============================================================================

def main():
    parser = argparse.ArgumentParser(
        prog="xtrct",
        description="Schema-driven semantic data extraction using Claude API",
    )
    parser.add_argument(
        "file", nargs="?", default=None,
        help="Path to input document (.md, .txt, or .pdf). Reads stdin if omitted",
    )
    parser.add_argument(
        "--schema", required=True,
        help="JSON schema template describing what to extract",
    )
    parser.add_argument(
        "--format", dest="fmt", default="json",
        choices=["json", "csv", "table"],
        help="Output format (default: json)",
    )
    parser.add_argument(
        "--model", default=DEFAULT_MODEL,
        help=f"Claude model (default: {DEFAULT_MODEL})",
    )
    parser.add_argument(
        "--verbose", action="store_true",
        help="Show progress and token usage to stderr",
    )

    args = parser.parse_args()

    # Load schema
    schema = load_schema(args.schema)

    # Read document
    document = read_document(args.file, verbose=args.verbose)

    # Build prompts
    system_prompt = build_system_prompt()
    user_prompt = build_user_prompt(schema, document)

    # Call Claude
    response_text = call_claude(system_prompt, user_prompt, args.model, verbose=args.verbose)

    # Parse JSON
    data = extract_json(response_text)

    # Format and output
    if args.fmt == "json":
        print(format_json(data))
    elif args.fmt == "csv":
        sys.stdout.write(format_csv(data))
    elif args.fmt == "table":
        sys.stdout.write(format_table(data))


if __name__ == "__main__":
    main()
