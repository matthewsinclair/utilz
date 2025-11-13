# macoz

**Version**: 1.0.0
**Part of**: [Utilz Framework](../../README.md)

---

## Overview

macOS system utilities

---

## Installation

As part of the Utilz framework, `macoz` is automatically available once the symlink is created:

```bash
cd $UTILZ_HOME/bin
ln -s utilz macoz
```

---

## Usage

```bash
macoz [OPTIONS] [ARGS]
```

For detailed help: `utilz help macoz`

---

## Examples

```bash
# Show help
macoz --help

# Show version
macoz --version
```

---

## Implementation

### Architecture

```
macoz
├── Invoked via: $UTILZ_HOME/bin/macoz (symlink)
├── Dispatched by: $UTILZ_HOME/bin/utilz
├── Has access to: $UTILZ_HOME/opt/utilz/lib/common.sh
└── Help from: $UTILZ_HOME/help/macoz.md
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
utilz test macoz

# Run tests directly
cd opt/macoz/test
bats macoz.bats
```

---

## Development

### Making Changes

1. Edit `/Users/matts/Devel/prj/Utilz/opt/macoz/macoz`
2. Test changes: `macoz --help`
3. Run tests: `utilz test macoz`
4. Update help if needed: `/Users/matts/Devel/prj/Utilz/help/macoz.md`

---

## License

Part of Utilz framework. Personal use.
Copyright (c) 2025 Matthew Sinclair

---

## See Also

- [Utilz Framework Documentation](../../README.md)
- [macoz Help](../../help/macoz.md) - Run: `utilz help macoz`
