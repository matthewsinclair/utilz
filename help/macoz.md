# macoz

**Version**: 1.0.0
**Author**: Matthew Sinclair

---

## Name

`macoz` - macOS system utilities

---

## Synopsis

```bash
macoz <command> [args]
```

---

## Description

macOS system utilities - various macOS-specific operations.

**Platform**: Requires macOS (Darwin)

---

## Commands

- `background [season] [id]` - Set desktop background image
  - No args: auto-select current seasonal wallpaper
  - season: random wallpaper from specified season
  - season id: specific seasonal wallpaper
  - image path: use custom image
- `bg [season] [id]` - Alias for background

---

## Options

### General Options

- `-h, --help` - Show help message
- `--version` - Show version information

---

## Examples

### Seasonal Wallpapers

```bash
# Auto-select current seasonal wallpaper
macoz bg

# Random autumn wallpaper
macoz bg autumn

# Specific seasonal wallpaper
macoz bg autumn 02

# Using background command (same as bg)
macoz background winter 01
```

### Custom Images

```bash
# Set custom desktop background
macoz bg ~/Pictures/wallpaper.jpg
```

### Seasonal Selection

Current season is automatically selected based on month:
- **spring** (March, April, May)
- **summer** (June, July, August)
- **autumn** (September, October, November)
- **winter** (December, January, February)

Each season has 4 wallpaper variants numbered 01-04.

---

## Files

- `$UTILZ_HOME/opt/macoz/macoz` - Implementation
- `$UTILZ_HOME/opt/macoz/macoz.yaml` - Metadata
- `$UTILZ_HOME/bin/macoz` - Symlink to dispatcher

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
- [macoz README]($UTILZ_HOME/opt/macoz/README.md) - Detailed documentation

---

## Author

Matthew Sinclair

---

## Copyright

Copyright (c) 2025 Matthew Sinclair
Part of the Utilz framework.
