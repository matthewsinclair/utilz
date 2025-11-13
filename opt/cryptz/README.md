# cryptz

**Version**: 1.0.0
**Part of**: [Utilz Framework](../../README.md)

---

## Overview

GPG encryption and decryption utility

---

## Installation

As part of the Utilz framework, `cryptz` is automatically available once the symlink is created:

```bash
cd $UTILZ_HOME/bin
ln -s utilz cryptz
```

---

## Usage

```bash
cryptz [OPTIONS] [ARGS]
```

For detailed help: `utilz help cryptz`

---

## Examples

```bash
# Show help
cryptz --help

# Show version
cryptz --version
```

---

## Implementation

### Architecture

```
cryptz
├── Invoked via: $UTILZ_HOME/bin/cryptz (symlink)
├── Dispatched by: $UTILZ_HOME/bin/utilz
├── Has access to: $UTILZ_HOME/opt/utilz/lib/common.sh
└── Help from: $UTILZ_HOME/help/cryptz.md
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
utilz test cryptz

# Run tests directly
cd opt/cryptz/test
bats cryptz.bats
```

---

## Development

### Making Changes

1. Edit `/Users/matts/Devel/prj/Utilz/opt/cryptz/cryptz`
2. Test changes: `cryptz --help`
3. Run tests: `utilz test cryptz`
4. Update help if needed: `/Users/matts/Devel/prj/Utilz/help/cryptz.md`

---

## License

Part of Utilz framework. Personal use.
Copyright (c) 2025 Matthew Sinclair

---

## See Also

- [Utilz Framework Documentation](../../README.md)
- [cryptz Help](../../help/cryptz.md) - Run: `utilz help cryptz`
