# cleanz

**Version**: 1.1.0
**Author**: Matthew Sinclair

---

## Name

`cleanz` - LLM text cleaner that removes hidden characters and formatting artifacts

---

## Synopsis

```bash
cleanz [OPTIONS] [FILE]
```

---

## Description

cleanz removes invisible Unicode characters, HTML attributes, and formatting artifacts that LLM interfaces (ChatGPT, Claude, Gemini, etc.) inject into copied text. These hidden elements can cause issues with text formatting, parsing, publishing, and accessibility.

---

## Options

### Input Options

- `FILE` - Read from file (optional, defaults to stdin)
- `-c, --clipboard` - Read from and write to clipboard

### Output Options

- `-o, --output FILE` - Write to specified file
- `-i, --in-place` - Edit input file in place

### Modes

- `-d, --detect` - Show hidden characters without cleaning
- `-v, --verbose` - Show cleaning summary

### Feature Flags

- `--no-html` - Skip HTML attribute cleaning
- `--no-whitespace` - Skip whitespace normalization
- `--normalize-quotes` - Convert smart quotes to straight quotes

### General Options

- `-h, --help` - Show help message
- `--version` - Show version information

---

## What Gets Cleaned

### Unicode Control Characters

| Character | Code | Action |
|-----------|------|--------|
| Zero-width space | U+200B | Remove |
| Zero-width non-joiner | U+200C | Remove |
| Zero-width joiner | U+200D | Remove |
| Word joiner | U+2060 | Remove |
| Non-breaking space | U+00A0 | Convert to space |
| Hair space | U+200A | Convert to space |
| Byte order mark | U+FEFF | Remove |
| Soft hyphen | U+00AD | Remove |
| Directional formatting | U+202A-E | Remove |
| Invisible math operators | U+2061-64 | Remove |
| Control characters | U+0000-1F | Remove (keep \\n \\t \\r) |
| DEL character | U+007F | Remove |

### HTML Attributes

- `data-start`, `data-end`, `data-sourcepos`
- All `data-*` attributes from LLM UIs

### Whitespace

- Multiple spaces collapsed to single space
- Multiple blank lines reduced to max 2
- Trailing whitespace removed

### Smart Quotes (optional)

With `--normalize-quotes`:
- Curly double quotes -> straight `"`
- Curly single quotes -> straight `'`

---

## Examples

### Basic Usage

```bash
# Clean file and output to stdout
cleanz document.txt

# Clean file in place
cleanz -i document.txt

# Clean with verbose output
cleanz -v document.txt
```

### Pipe Mode

```bash
# Clean text from stdin
cat document.txt | cleanz > cleaned.txt

# Clean clipboard (macOS)
pbpaste | cleanz | pbcopy
```

### Clipboard Integration

```bash
# Clean clipboard contents directly
cleanz --clipboard
```

### Detection Mode

```bash
# Show hidden characters without removing them
cleanz --detect document.txt
```

### Feature Flags

```bash
# Only clean Unicode, preserve HTML and whitespace
cleanz --no-html --no-whitespace document.txt

# Full cleaning with quote normalization
cleanz --normalize-quotes document.txt
```

---

## Files

- `$UTILZ_HOME/opt/cleanz/cleanz` - Implementation
- `$UTILZ_HOME/opt/cleanz/cleanz.yaml` - Metadata
- `$UTILZ_HOME/bin/cleanz` - Symlink to dispatcher

---

## Environment

- `UTILZ_HOME` - Root directory of Utilz framework

---

## Exit Status

- `0` - Success
- `1` - Error (invalid option, file not found, etc.)

---

## Dependencies

- `clipz` (optional) - Required for `--clipboard` operations

---

## See Also

- `clipz` - Cross-platform clipboard utility
- `utilz` - Utilz framework dispatcher

---

## Author

Matthew Sinclair

---

## Copyright

Copyright (c) 2025 Matthew Sinclair
Part of the Utilz framework.
