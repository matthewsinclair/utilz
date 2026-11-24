# macoz

**Version**: run `macoz --version`
**Part of**: [Utilz Framework](../../README.md)

---

## Overview

macOS system utilities - desktop backgrounds and folder icons.

---

## Installation

`macoz` comes with Utilz. Once Utilz is installed, as the [README](../../README.md#installation) says, `macoz` is on your PATH.

---

## Usage

The usage home is `help/macoz.md`. Run `utilz help macoz` to read it, or `macoz --help` for a short summary.

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

- Bash 3.2+ or Zsh (bash 3.2 is what macOS ships, and is the floor the framework targets)
- macOS (every command refuses elsewhere)
- `yq` - Reads `macoz.yaml` to check the platform

**Optional:**

- `fileicon` - Needed by `setpicfor` (install: `brew install fileicon`)

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

1. Edit `opt/macoz/macoz`
2. Test changes: `macoz --help`
3. Run tests: `utilz test macoz`
4. Update help if needed: `help/macoz.md`

---

## License

Part of Utilz framework. Personal use.
Copyright (c) 2025 Matthew Sinclair

---

## See Also

- [Utilz Framework Documentation](../../README.md)
- [macoz Help](../../help/macoz.md) - Run: `utilz help macoz`
