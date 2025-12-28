# Implementation - ST0001: cleanz - LLM Text Cleaner Utility

**Status**: COMPLETE (28 Dec 2025)
**Version**: 1.1.0

## Implementation Summary

cleanz was implemented as a pure bash utility (~560 lines) following the Utilz dispatcher pattern. It removes hidden Unicode characters, HTML attributes, and formatting artifacts from LLM-generated text.

## Key Files

| File | Purpose |
|------|---------|
| `opt/cleanz/cleanz` | Main implementation (~560 lines) |
| `opt/cleanz/cleanz.yaml` | Metadata (version 1.1.0) |
| `opt/cleanz/README.md` | Utility documentation |
| `opt/cleanz/test/cleanz.bats` | Test suite (46 tests) |
| `help/cleanz.md` | Help documentation |
| `bin/cleanz` | Symlink to dispatcher |

## Technical Approach

### Unicode Character Handling

All Unicode characters are defined as bash variables using printf with UTF-8 byte sequences:

```bash
# Zero-width characters
ZWSP=$(printf '\xe2\x80\x8b')     # U+200B
ZWNJ=$(printf '\xe2\x80\x8c')     # U+200C
ZWJ=$(printf '\xe2\x80\x8d')      # U+200D
WJ=$(printf '\xe2\x81\xa0')       # U+2060

# Space variants
NBSP=$(printf '\xc2\xa0')         # U+00A0
HAIR=$(printf '\xe2\x80\x8a')     # U+200A

# Control characters
BOM=$(printf '\xef\xbb\xbf')      # U+FEFF
SHY=$(printf '\xc2\xad')          # U+00AD
DEL=$(printf '\x7f')              # U+007F

# Smart quotes
LSQUO=$(printf '\xe2\x80\x98')    # U+2018
RSQUO=$(printf '\xe2\x80\x99')    # U+2019
LDQUO=$(printf '\xe2\x80\x9c')    # U+201C
RDQUO=$(printf '\xe2\x80\x9d')    # U+201D
```

### String Replacement

Uses bash parameter expansion for all replacements:

```bash
# Remove character
text="${text//$ZWSP/}"

# Convert to space
text="${text//$NBSP/ }"

# Convert smart quotes (using variables to avoid escaping issues)
local SQ="'"
text="${text//$LSQUO/$SQ}"
```

### Function Structure

1. **clean_unicode()** - Removes/converts all Unicode control characters
2. **clean_html()** - Strips data-* attributes from HTML
3. **clean_whitespace()** - Normalizes spaces, blank lines, trailing whitespace
4. **clean_quotes()** - Converts smart quotes to straight (optional)
5. **detect_hidden()** - Counts occurrences without modifying text
6. **count_pattern()** - Helper for counting substring occurrences

## Challenges and Solutions

### Challenge 1: BATS Pipe Handling

**Problem**: BATS `run` command doesn't work well with piped input. Tests using `printf '...' | run_cleanz` failed silently.

**Solution**: Rewrote all tests to use file-based input:
```bash
@test "cleanz removes zero-width space" {
    local testfile="$BATS_TEST_TMPDIR/input.txt"
    printf 'Hello\xe2\x80\x8bWorld' > "$testfile"
    run_cleanz "$testfile"
    assert_output "HelloWorld"
}
```

### Challenge 2: Quote Escaping in Bash

**Problem**: Using `\'` in bash parameter expansion produced literal backslash on some systems (CI macOS runner).

**Solution**: Use variable assignment instead of escape sequences:
```bash
# Before (broken on some systems)
text="${text//$LSQUO/\'}"

# After (portable)
local SQ="'"
text="${text//$LSQUO/$SQ}"
```

### Challenge 3: Whitespace Normalization

**Problem**: Need to collapse multiple spaces and blank lines while preserving intentional formatting.

**Solution**: Multiple passes with bash parameter expansion:
```bash
# Collapse multiple spaces (iterative)
while [[ "$text" == *"  "* ]]; do
    text="${text//  / }"
done

# Reduce blank lines (max 2 consecutive)
while [[ "$text" == *$'\n\n\n'* ]]; do
    text="${text//$'\n\n\n'/$'\n\n'}"
done
```

## Testing

### Test Coverage (46 tests)

- Basic options (--help, --version, unknown options)
- Unicode character removal (8 character types)
- HTML attribute stripping
- Whitespace normalization
- Smart quote conversion
- Detection mode (--detect)
- Verbose mode (-v)
- I/O modes (file, stdin, output file, in-place)
- Error handling
- Edge cases (empty content, only hidden chars, mixed content)
- Feature flag combinations

### CI/CD

Tests run on both macOS and Linux via GitHub Actions. All 46 tests pass on both platforms.

## Performance Notes

- Pure bash implementation is fast for typical use (text documents)
- No external process spawning for cleaning operations
- File I/O uses temp files for safety (in-place editing)

## Future Considerations

- Could add `--dry-run` to preview changes without applying
- Could add pattern file support for custom cleaning rules
- Could add `--aggressive` mode for more extensive cleaning
