# cleanz

**Version**: 1.1.0
**Part of**: [Utilz Framework](../../README.md)

---

## Overview

cleanz is an LLM text cleaner that removes hidden characters and formatting artifacts from text copied from ChatGPT, Claude, Gemini, and other LLM interfaces. It also supports stripping C2PA metadata from AI-generated images.

### What Gets Cleaned

**Text mode (default):**
- **Zero-width characters**: ZWSP, ZWNJ, ZWJ, word joiners
- **Special spaces**: Non-breaking spaces, hair spaces (converted to regular spaces)
- **Control characters**: BOM, soft hyphens, directional formatting, DEL
- **HTML attributes**: `data-start`, `data-end`, `data-sourcepos`, and other LLM-injected attrs
- **Whitespace**: Multiple spaces, excessive blank lines, trailing whitespace

**Image mode (--image):**
- **C2PA metadata**: Content credentials manifest from AI image generators
- **AI provenance**: Creator/credit metadata from DALL-E, ChatGPT, Sora, Midjourney

---

## Installation

As part of the Utilz framework, `cleanz` is automatically available once the symlink is created:

```bash
cd $UTILZ_HOME/bin
ln -s utilz cleanz
```

---

## Usage

```bash
cleanz [OPTIONS] [FILE]
```

For detailed help: `utilz help cleanz`

---

## Examples

### Text Mode

```bash
# Clean file to stdout
cleanz document.txt

# Clean file in place
cleanz -i document.txt

# Clean clipboard
cleanz --clipboard

# Detect hidden chars
cleanz --detect document.txt

# Pipe mode
cat file.txt | cleanz > cleaned.txt
pbpaste | cleanz | pbcopy
```

### Image Mode

```bash
# Detect C2PA/AI metadata in image
cleanz --image --detect photo.png

# Strip metadata to new file
cleanz --image photo.png -o cleaned.png

# Strip metadata in place
cleanz --image -i photo.png
```

---

## Options

| Option | Description |
|--------|-------------|
| `-c, --clipboard` | Read from and write to clipboard |
| `-o, --output FILE` | Write to specified file |
| `-i, --in-place` | Edit file in place |
| `-d, --detect` | Show hidden chars without cleaning |
| `-v, --verbose` | Show cleaning summary |
| `--no-html` | Skip HTML attribute cleaning |
| `--no-whitespace` | Skip whitespace normalization |
| `--normalize-quotes` | Convert smart quotes to straight |
| `--image` | Image mode: handle C2PA/AI metadata |

---

## Implementation

### Architecture

```
cleanz
+-- Invoked via: $UTILZ_HOME/bin/cleanz (symlink)
+-- Dispatched by: $UTILZ_HOME/bin/utilz
+-- Has access to: $UTILZ_HOME/opt/utilz/lib/common.sh
+-- Help from: $UTILZ_HOME/help/cleanz.md
```

### Dependencies

**Required:**

- Bash 4.0+ or Zsh

**Optional:**

- `clipz` - For `--clipboard` functionality
- `exiftool` - For `--image` functionality (`brew install exiftool`)

---

## Testing

```bash
# Run tests
utilz test cleanz

# Run tests directly
cd opt/cleanz/test
bats cleanz.bats
```

---

## Development

### Making Changes

1. Edit `opt/cleanz/cleanz`
2. Test changes: `cleanz --help`
3. Run tests: `utilz test cleanz`
4. Update help if needed: `help/cleanz.md`

---

## License

Part of Utilz framework. Personal use.
Copyright (c) 2025 Matthew Sinclair

---

## See Also

- [Utilz Framework Documentation](../../README.md)
- [cleanz Help](../../help/cleanz.md) - Run: `utilz help cleanz`
