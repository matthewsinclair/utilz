# Design - ST0001: cleanz - LLM Text Cleaner Utility

**Status**: AS-BUILT (Implemented 28 Dec 2025)

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
- `--image` - Image mode: handle C2PA/AI metadata (requires exiftool)

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

### Image Mode (--image)

With `--image` flag, handles C2PA (Content Credentials) metadata from AI-generated images:
- C2PA content credentials manifest
- AI generation provenance data
- Creator/credit metadata from DALL-E, ChatGPT, Sora, Midjourney
- Uses exiftool for metadata stripping

## Design Decisions

### Pure bash Implementation

- No external dependencies beyond coreutils
- Use UTF-8 byte sequences via printf for Unicode handling
- Compatible with both macOS and Linux
- Uses bash parameter expansion for string replacement (no sed)

### Clipboard Integration

- Leverage existing clipz utility for cross-platform clipboard access
- `--clipboard` flag reads AND writes to clipboard

### In-place Editing

- Use temp file + mv pattern for safety
- Atomic replacement to prevent data loss

## Architecture (As-Built)

```
cleanz (~690 lines)
  |
  +-- Unicode byte sequences (defined via printf)
  |     ZWSP, ZWNJ, ZWJ, WJ, NBSP, HAIR, BOM, SHY
  |     LSQUO, RSQUO, LDQUO, RDQUO
  |     LRE, RLE, PDF, LRO, RLO
  |     Invisible math operators, control chars, DEL
  |
  +-- parse_args()        # Argument parsing with getopts
  |
  +-- Text Mode Functions:
  |     +-- read_input()        # File/stdin/clipboard input
  |     +-- clean_text()        # Main cleaning pipeline
  |     |     +-- clean_unicode()      # Bash parameter expansion
  |     |     +-- clean_html()         # Bash parameter expansion
  |     |     +-- clean_whitespace()   # Bash parameter expansion
  |     |     +-- clean_quotes()       # Bash parameter expansion
  |     +-- detect_hidden()     # Count occurrences of each char type
  |     |     +-- count_pattern()      # Helper function
  |     +-- write_output()      # File/stdout/clipboard output
  |
  +-- Image Mode Functions (--image):
  |     +-- check_exiftool()    # Verify exiftool is installed
  |     +-- detect_c2pa()       # Show C2PA/AI metadata
  |     +-- strip_c2pa()        # Remove all metadata via exiftool
  |
  +-- main()              # Entry point with dispatcher integration
```

## Implementation Notes

### Unicode Handling

All Unicode characters defined as bash variables using printf:
```bash
ZWSP=$(printf '\xe2\x80\x8b')     # U+200B Zero-width space
NBSP=$(printf '\xc2\xa0')         # U+00A0 Non-breaking space
```

### String Replacement

Uses bash parameter expansion instead of sed:
```bash
text="${text//$ZWSP/}"            # Remove
text="${text//$NBSP/ }"           # Convert to space
```

### Test Compatibility

BATS tests use file-based input rather than pipes due to `run` command limitations with stdin.

## Alternatives Considered

### sed-based implementation

- Initial approach considered
- Rejected: bash parameter expansion is more portable and easier to maintain

### Perl-based implementation

- More robust Unicode regex support
- Rejected: adds dependency, bash sufficient for this use case

### Python fallback

- Better cross-platform Unicode handling
- Rejected: over-engineering for text cleaning utility
