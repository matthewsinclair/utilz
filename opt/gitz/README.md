# gitz

**Version**: 1.0.0
**Part of**: [Utilz Framework](../../README.md)

---

## Overview

Git multi-repository operations

---

## Installation

As part of the Utilz framework, `gitz` is automatically available once the symlink is created:

```bash
cd $UTILZ_HOME/bin
ln -s utilz gitz
```

---

## Usage

```bash
gitz [OPTIONS] [ARGS]
```

For detailed help: `utilz help gitz`

---

## Examples

```bash
# Show help
gitz --help

# Show version
gitz --version
```

---

## Implementation

### Architecture

```
gitz
├── Invoked via: $UTILZ_HOME/bin/gitz (symlink)
├── Dispatched by: $UTILZ_HOME/bin/utilz
├── Has access to: $UTILZ_HOME/opt/utilz/lib/common.sh
└── Help from: $UTILZ_HOME/help/gitz.md
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
utilz test gitz

# Run tests directly
cd opt/gitz/test
bats gitz.bats
```

---

## Development

### Making Changes

1. Edit `/Users/matts/Devel/prj/Utilz/opt/gitz/gitz`
2. Test changes: `gitz --help`
3. Run tests: `utilz test gitz`
4. Update help if needed: `/Users/matts/Devel/prj/Utilz/help/gitz.md`

---

## License

Part of Utilz framework. Personal use.
Copyright (c) 2025 Matthew Sinclair

---

## See Also

- [Utilz Framework Documentation](../../README.md)
- [gitz Help](../../help/gitz.md) - Run: `utilz help gitz`
