# Design - ST0004: xtrct - Semantic Data Extraction

## Approach

Build a thin Python CLI that:
1. Reads a document (markdown/text from file or stdin; PDF via pdf2md)
2. Reads a JSON schema template
3. Constructs a prompt with schema + document content
4. Calls Claude API and parses the JSON response
5. Outputs in the requested format (json, csv, table)

The heavy lifting is done by Claude -- the utility is mostly prompt engineering + I/O.

## Design Decisions

### Schema-driven (not hardcoded fields)

- The schema is a separate JSON file, not baked into the tool
- Makes `xtrct` generic -- works for any document type
- The `description` fields in the schema are the key -- they tell Claude what to look for semantically
- No need for regex, XPath, or positional extraction rules

### Stdin support for composability

- When no file arg is given, reads from stdin
- Enables: `pdf2md invoice.pdf | xtrct --schema schema.json`
- Also enables: `cat document.md | xtrct --schema schema.json`

### PDF handling via pdf2md (not built-in)

- When given a `.pdf` file, shells out to `pdf2md` to convert first
- Keeps xtrct focused on extraction, not PDF parsing
- If `pdf2md` isn't installed, gives a clear error message

### Default to Sonnet

- `claude-sonnet-4-5-20250929` is fast and capable enough for structured extraction
- `--model` flag allows upgrading to Opus for complex documents
- Keeps API costs low for routine use

## Architecture

```
Input (file or stdin)
    |
    v
Detect format:
  .pdf -> shell out to pdf2md -> get markdown
  .md/.txt/stdin -> read directly
    |
    v
Read schema template (JSON)
    |
    v
Construct prompt:
  System: "You are a document data extractor. Extract data according to the schema."
  User: schema + document content
  Response format: JSON
    |
    v
Call Claude API (anthropic SDK)
    |
    v
Parse JSON response, validate structure
    |
    v
Output in requested format:
  json -> pretty-print JSON
  csv -> flatten to CSV rows
  table -> formatted table
```

### Prompt Design

System prompt:
```
You are a precise document data extractor. Given a document and a schema,
extract the requested data and return it as JSON. Only include data that
is explicitly present in the document. Use null for fields that cannot
be determined. Do not invent or hallucinate data.
```

User message:
```
## Schema

{schema JSON}

## Document

{document content}

Extract the data according to the schema above. Return only valid JSON.
```

## Alternatives Considered

### Using OpenAI API instead
- Claude is better at structured extraction and following schemas
- We already have ANTHROPIC_API_KEY in the environment
- Consistent with the rest of the tooling

### Building extraction rules (regex/position-based)
- Brittle -- breaks when document format changes
- Requires per-document-type rule writing
- Claude handles format variation naturally

### Using function calling / tool_use for structured output
- Could use Claude's tool_use feature to enforce JSON schema
- Adds complexity, and simple prompting works well for this use case
- Worth revisiting if output quality is inconsistent
