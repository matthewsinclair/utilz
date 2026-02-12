# pdf2md

**Version**: 1.0.0
**Part of**: [Utilz Framework](../../README.md)

---

## Overview

PDF to Markdown converter

---

## Installation

As part of the Utilz framework, `pdf2md` is automatically available once the symlink is created:

```bash
cd $UTILZ_HOME/bin
ln -s utilz pdf2md
```

---

## Usage

```bash
pdf2md [OPTIONS] [ARGS]
```

For detailed help: `utilz help pdf2md`

---

## Examples

```bash
# Show help
pdf2md --help

# Show version
pdf2md --version
```

---

## Implementation

### Architecture

```
pdf2md
├── Invoked via: $UTILZ_HOME/bin/pdf2md (symlink)
├── Dispatched by: $UTILZ_HOME/bin/utilz
├── Has access to: $UTILZ_HOME/opt/utilz/lib/common.sh
└── Help from: $UTILZ_HOME/help/pdf2md.md
```

### Dependencies

**Required:**
- Bash 4.0+ or Zsh

**Optional:**
- None

---

## Testing

```bash
# Run tests
utilz test pdf2md

# Run tests directly
cd opt/pdf2md/test
bats pdf2md.bats
```

---

## Development

### Making Changes

1. Edit `/Users/matts/Devel/prj/Utilz/opt/pdf2md/pdf2md`
2. Test changes: `pdf2md --help`
3. Run tests: `utilz test pdf2md`
4. Update help if needed: `/Users/matts/Devel/prj/Utilz/help/pdf2md.md`

---

## License

Part of Utilz framework. Personal use.
Copyright (c) 2026 Matthew Sinclair

---

## See Also

- [Utilz Framework Documentation](../../README.md)
- [pdf2md Help](../../help/pdf2md.md) - Run: `utilz help pdf2md`
