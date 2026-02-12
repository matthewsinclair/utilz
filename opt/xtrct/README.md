# xtrct

**Version**: 1.0.0
**Part of**: [Utilz Framework](../../README.md)

---

## Overview

Schema-driven semantic data extraction

---

## Installation

As part of the Utilz framework, `xtrct` is automatically available once the symlink is created:

```bash
cd $UTILZ_HOME/bin
ln -s utilz xtrct
```

---

## Usage

```bash
xtrct [OPTIONS] [ARGS]
```

For detailed help: `utilz help xtrct`

---

## Examples

```bash
# Show help
xtrct --help

# Show version
xtrct --version
```

---

## Implementation

### Architecture

```
xtrct
├── Invoked via: $UTILZ_HOME/bin/xtrct (symlink)
├── Dispatched by: $UTILZ_HOME/bin/utilz
├── Has access to: $UTILZ_HOME/opt/utilz/lib/common.sh
└── Help from: $UTILZ_HOME/help/xtrct.md
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
utilz test xtrct

# Run tests directly
cd opt/xtrct/test
bats xtrct.bats
```

---

## Development

### Making Changes

1. Edit `/Users/matts/Devel/prj/Utilz/opt/xtrct/xtrct`
2. Test changes: `xtrct --help`
3. Run tests: `utilz test xtrct`
4. Update help if needed: `/Users/matts/Devel/prj/Utilz/help/xtrct.md`

---

## License

Part of Utilz framework. Personal use.
Copyright (c) 2026 Matthew Sinclair

---

## See Also

- [Utilz Framework Documentation](../../README.md)
- [xtrct Help](../../help/xtrct.md) - Run: `utilz help xtrct`
