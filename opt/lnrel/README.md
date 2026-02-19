# lnrel

**Version**: 1.0.0
**Part of**: [Utilz Framework](../../README.md)

---

## Overview

Create symlinks with relative paths. Given a target and an optional link name, `lnrel` computes the relative path from the link's directory to the target, then creates a symlink using that relative path. This makes symlinks portable — they survive directory tree moves.

---

## Installation

As part of the Utilz framework, `lnrel` is automatically available once the symlink is created:

```bash
cd $UTILZ_HOME/bin
ln -s utilz lnrel
```

**macOS note:** Requires GNU coreutils for `realpath -m --relative-to`. Install with:

```bash
brew install coreutils
```

---

## Usage

```bash
lnrel <target> [<link_name>]
```

For detailed help: `utilz help lnrel`

---

## Examples

```bash
# Link to a file (creates ./file.txt in cwd)
lnrel /path/to/file.txt

# Explicit link name
lnrel ../shared/config.yaml config.yaml

# Cross-directory
lnrel /opt/data/db.sqlite ./data/db.sqlite

# Target doesn't need to exist yet (dangling symlink)
lnrel ../future/file.txt placeholder.txt
```

---

## Implementation

### Architecture

```
lnrel
├── Invoked via: $UTILZ_HOME/bin/lnrel (symlink)
├── Dispatched by: $UTILZ_HOME/bin/utilz
├── Has access to: $UTILZ_HOME/opt/utilz/lib/common.sh
├── Uses: GNU realpath (grealpath on macOS)
└── Help from: $UTILZ_HOME/help/lnrel.md
```

### Dependencies

**Required:**
- GNU coreutils `realpath` (with `-m` and `--relative-to` support)

**Platform:**
- Linux: built-in (`realpath` from coreutils)
- macOS: `brew install coreutils` (provides `grealpath`)

---

## Testing

```bash
# Run tests
utilz test lnrel

# Run tests directly
cd opt/lnrel/test
bats lnrel.bats
```

---

## License

Part of Utilz framework. Personal use.
Copyright (c) 2026 Matthew Sinclair

---

## See Also

- [Utilz Framework Documentation](../../README.md)
- [lnrel Help](../../help/lnrel.md) - Run: `utilz help lnrel`
