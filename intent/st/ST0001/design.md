# Design - ST0001: cleanz - LLM Text Cleaner Utility

## Command Interface

```
cleanz [options] [file]
```

### Input Options

- `file` - Read from file (optional, defaults to stdin)
- `-c, --clipboard` - Read from clipboard

### Output Options

- stdout - Default output
- `-o, --output FILE` - Write to file
- `-i, --in-place` - Edit input file in place
- `-c, --clipboard` - Also writes back to clipboard

### Modes

- (default) - Clean and output
- `-d, --detect` - Show hidden chars without cleaning
- `-v, --verbose` - Show cleaning summary

### Feature Flags

- `--no-html` - Skip HTML attribute cleaning
- `--no-whitespace` - Skip whitespace normalization
- `--normalize-quotes` - Convert smart quotes to straight
- `-h, --help` - Show help
- `--version` - Show version

## What Gets Cleaned

### Unicode Control Characters

| Code      | Name                   | Action                 |
|-----------|------------------------|------------------------|
| U+200B    | Zero-width space       | Remove                 |
| U+200C    | Zero-width non-joiner  | Remove                 |
| U+200D    | Zero-width joiner      | Remove                 |
| U+2060    | Word joiner            | Remove                 |
| U+00A0    | Non-breaking space     | Convert to space       |
| U+200A    | Hair space             | Convert to space       |
| U+FEFF    | BOM                    | Remove                 |
| U+00AD    | Soft hyphen            | Remove                 |
| U+202A-E  | Directional formatting | Remove                 |
| U+2061-64 | Invisible math ops     | Remove                 |
| U+0000-1F | Control chars          | Remove (keep \n \t \r) |
| U+007F    | DEL                    | Remove                 |

### HTML Attributes

- `data-start`, `data-end`, `data-sourcepos`
- LLM-specific `data-*` attributes

### Whitespace Normalization

- Multiple spaces -> single space
- Multiple blank lines -> max 2
- Trailing whitespace removed

### Smart Quotes (optional, --normalize-quotes)

- U+201C/D -> "
- U+2018/9 -> '

## Design Decisions

### Pure bash/sed Implementation

- No external dependencies beyond coreutils
- Use UTF-8 byte sequences for Unicode handling
- Compatible with both macOS sed and GNU sed

### Clipboard Integration

- Leverage existing clipz utility for cross-platform clipboard access
- `--clipboard` flag reads AND writes to clipboard

### In-place Editing

- Use temp file + mv pattern for safety
- Atomic replacement to prevent data loss

## Architecture

```
cleanz
  |
  +-- parse_args()        # Argument parsing
  |
  +-- read_input()        # File/stdin/clipboard input
  |
  +-- clean_text()        # Main cleaning pipeline
  |     |
  |     +-- clean_unicode()      # Remove/convert Unicode chars
  |     +-- clean_html()         # Strip HTML attributes
  |     +-- clean_whitespace()   # Normalize whitespace
  |     +-- clean_quotes()       # Optional quote conversion
  |
  +-- detect_hidden()     # Detection mode (--detect)
  |
  +-- write_output()      # File/stdout/clipboard output
```

## Alternatives Considered

### Perl-based implementation

- More robust Unicode regex support
- Rejected: adds dependency, bash/sed sufficient for this use case

### Python fallback

- Better cross-platform Unicode handling
- Rejected: over-engineering for text cleaning utility
