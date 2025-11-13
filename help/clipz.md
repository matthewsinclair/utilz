# clipz

**Version**: 1.0.0
**Author**: Matthew Sinclair

---

## Name

`clipz` - Cross-platform clipboard copy and paste utility

---

## Synopsis

```bash
clipz <command> [options] [args]
```

---

## Description

Cross-platform clipboard copy and paste utility.

Supports macOS (pbcopy/pbpaste), Linux X11 (xclip/xsel), and Linux Wayland (wl-clipboard).

---

## Commands

- `copy [file]` - Copy to clipboard from file or stdin
- `paste` - Paste from clipboard to stdout

---

## Options

### General Options

- `-h, --help` - Show help message
- `--version` - Show version information

---

## Examples

### Copy Operations

```bash
# Copy from stdin
echo "hello" | clipz copy

# Copy from file
clipz copy file.txt

# Copy multi-line text
cat document.txt | clipz copy
```

### Paste Operations

```bash
# Paste to stdout
clipz paste

# Paste to file
clipz paste > output.txt

# Pipe to another command
clipz paste | grep "pattern"
```

---

## Files

- `$UTILZ_HOME/opt/clipz/clipz` - Implementation
- `$UTILZ_HOME/opt/clipz/clipz.yaml` - Metadata
- `$UTILZ_HOME/bin/clipz` - Symlink to dispatcher

---

## Environment

- `UTILZ_HOME` - Root directory of Utilz framework

---

## Exit Status

- `0` - Success
- `1` - General error

---

## See Also

- `utilz(1)` - Utilz framework dispatcher
- `utilz-help(1)` - Show help for utilities
- [clipz README]($UTILZ_HOME/opt/clipz/README.md) - Detailed documentation

---

## Author

Matthew Sinclair

---

## Copyright

Copyright (c) 2025 Matthew Sinclair
Part of the Utilz framework.
