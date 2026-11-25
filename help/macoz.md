# macoz

**Version**: run `macoz --version`
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

**Platform**: macOS only. Elsewhere every command refuses, exit 2, saying `macoz needs macOS, so it is not available on <platform>`; `--help`, `--version` and no arguments answer everywhere. `setpicfor` needs fileicon (`brew install fileicon`), which `utilz doctor` reports as optional.

---

## Commands

- `background [season] [id]` - Set desktop background image
  - No args: auto-select current seasonal wallpaper
  - season: random wallpaper from specified season
  - season id: specific seasonal wallpaper, the file `<season>-<id>.png` (id is `01` to `04`)
  - image path: use custom image
  - macoz sets the image on every desktop
- `bg [season] [id]` - Alias for background
- `setpicfor <image> [directory]` - Set folder icon from image file
  - image: path to image file (jpg, png)
  - directory: target directory (default: current directory)
  - setpicfor needs `fileicon`, but a `--dry-run` does not

---

## Options

### General Options

- `-h, --help` - Show help message
- `--version` - Show version information

### setpicfor Options

- `--all` - Batch mode: set icons for subdirectories
- `--data-dir <dir>` - Directory whose subdirectories `--all` scans (default: current directory)
- `--pattern <pattern>` - With `--all`: the images to look for, in place of the built-in names. See Folder Icon Pattern Matching
- `--dry-run` - Preview changes without applying them
- `-v, --verbose` - Show detailed operation steps

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

# Custom desktop background
macoz bg ~/Pictures/wallpaper.jpg
```

### Folder Icons

```bash
# Set icon for current directory
macoz setpicfor icon.png

# Set icon for specific directory
macoz setpicfor photo.jpg ~/Documents/Projects

# Set icons for all subdirectories with icon.* files
macoz setpicfor --all

# Preview what would be changed
macoz setpicfor --all --dry-run

# Process specific directory tree
macoz setpicfor --all --data-dir ~/Projects

# Look for cover.* first, then art.*, in place of the built-in names
macoz setpicfor --all --pattern 'cover.*|art.*'

# Verbose output
macoz setpicfor --all --verbose
```

### Seasonal Selection

Current season is automatically selected based on month:

- **spring** (March, April, May)
- **summer** (June, July, August)
- **autumn** (September, October, November)
- **winter** (December, January, February)

Each season has 4 wallpaper variants numbered 01-04.

### Folder Icon Pattern Matching

When using `--all` mode, the command looks for image files in each subdirectory:

- `icon.*` - An image file named "icon" (icon.png, icon.jpg, etc.)
- `folder.*` - An image file named "folder"
- `<dirname>.*` - Image file matching the directory name

The extensions are `png`, `jpg` and `jpeg`, in lower case or upper case. macoz scans only the subdirectories one level below the data directory. It skips a subdirectory with no matching image.

`--pattern` replaces the three names. Its value is a list of globs separated by `|`, eg `'cover.*|art.*'`, and macoz matches each glob against the file name of each image. It tries the globs in the order given. Where one glob matches more than one image, macoz takes the first in name order. Only files with the extensions above count. Without `--all`, macoz refuses a `--pattern`, exit 1.

---

## Files

- `$UTILZ_HOME/opt/macoz/macoz` - Implementation
- `$UTILZ_HOME/opt/macoz/macoz.yaml` - Metadata
- `$UTILZ_HOME/opt/macoz/images/backgrounds/` - Seasonal wallpapers, `<season>-<id>.png`
- `$UTILZ_HOME/bin/macoz` - Symlink to dispatcher

---

## Environment

- `UTILZ_HOME` - Root directory of Utilz framework

---

## Exit Status

- `0` - Success
- `1` - General error
- `2` - Not on macOS

In `--all` mode, a failure to set one icon is a warning. macoz goes on to the next directory and exits 0.

---

## See Also

- `utilz` - Utilz framework dispatcher
- `utilz help` - Show help for utilities
- [macoz README]($UTILZ_HOME/opt/macoz/README.md) - Detailed documentation

---

## Author

Matthew Sinclair

---

## Copyright

Copyright (c) 2025 Matthew Sinclair
Part of the Utilz framework.
