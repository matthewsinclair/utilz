# retry

**Version**: 1.0.0
**Part of**: [Utilz Framework](../../README.md)

---

## Overview

Retry command until success with configurable wait time

---

## Installation

As part of the Utilz framework, `retry` is automatically available once the symlink is created:

```bash
cd $UTILZ_HOME/bin
ln -s utilz retry
```

---

## Usage

```bash
retry [OPTIONS] [ARGS]
```

For detailed help: `utilz help retry`

---

## Examples

```bash
# Show help
retry --help

# Show version
retry --version
```

---

## Implementation

### Architecture

```
retry
├── Invoked via: $UTILZ_HOME/bin/retry (symlink)
├── Dispatched by: $UTILZ_HOME/bin/utilz
├── Has access to: $UTILZ_HOME/opt/utilz/lib/common.sh
└── Help from: $UTILZ_HOME/help/retry.md
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
utilz test retry

# Run tests directly
cd opt/retry/test
bats retry.bats
```

---

## Development

### Making Changes

1. Edit `/Users/matts/Devel/prj/Utilz/opt/retry/retry`
2. Test changes: `retry --help`
3. Run tests: `utilz test retry`
4. Update help if needed: `/Users/matts/Devel/prj/Utilz/help/retry.md`

---

## License

Part of Utilz framework. Personal use.
Copyright (c) 2025 Matthew Sinclair

---

## See Also

- [Utilz Framework Documentation](../../README.md)
- [retry Help](../../help/retry.md) - Run: `utilz help retry`
