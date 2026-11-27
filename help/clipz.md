# clipz

**Version**: run `clipz --version`
**Author**: Matthew Sinclair

---

## Name

`clipz` - Cross-platform clipboard copy and paste utility

---

## Synopsis

```bash
clipz <command> [file]
```

---

## Description

Supports macOS (pbcopy/pbpaste), Linux X11 (xclip/xsel), and Linux Wayland (wl-clipboard). On other platforms, clipz refuses with an error.

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

- `XDG_SESSION_TYPE` - On Linux, `wayland` selects wl-clipboard. Any other value selects xclip, or xsel when xclip is absent.

---

## Exit Status

- `0` - Success
- `1` - General error

---

## See Also

- `utilz help` - Utilz framework help

---

## Author

Matthew Sinclair

---

## Copyright

Copyright (c) 2025 Matthew Sinclair
Part of the Utilz framework.
