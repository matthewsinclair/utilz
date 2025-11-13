# clipz

**Version**: 1.0.0
**Part of**: [Utilz Framework](../../README.md)

---

## Overview

Cross-platform clipboard copy and paste utility

---

## Installation

As part of the Utilz framework, `clipz` is automatically available once the symlink is created:

```bash
cd $UTILZ_HOME/bin
ln -s utilz clipz
```

---

## Usage

```bash
clipz [OPTIONS] [ARGS]
```

For detailed help: `utilz help clipz`

---

## Examples

```bash
# Show help
clipz --help

# Show version
clipz --version
```

---

## Implementation

### Architecture

```
clipz
├── Invoked via: $UTILZ_HOME/bin/clipz (symlink)
├── Dispatched by: $UTILZ_HOME/bin/utilz
├── Has access to: $UTILZ_HOME/opt/utilz/lib/common.sh
└── Help from: $UTILZ_HOME/help/clipz.md
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
utilz test clipz

# Run tests directly
cd opt/clipz/test
bats clipz.bats
```

---

## Development

### Making Changes

1. Edit `/Users/matts/Devel/prj/Utilz/opt/clipz/clipz`
2. Test changes: `clipz --help`
3. Run tests: `utilz test clipz`
4. Update help if needed: `/Users/matts/Devel/prj/Utilz/help/clipz.md`

---

## License

Part of Utilz framework. Personal use.
Copyright (c) 2025 Matthew Sinclair

---

## See Also

- [Utilz Framework Documentation](../../README.md)
- [clipz Help](../../help/clipz.md) - Run: `utilz help clipz`
