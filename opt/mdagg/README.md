# mdagg - Markdown Aggregator

**Version**: run `mdagg --version`
**Language**: Bash
**Part of**: [Utilz Framework](../../README.md)

---

## Overview

`mdagg` is a command-line utility for concatenating multiple markdown files into a single aggregate document, optimised for PDF generation and documentation assembly.

---

## Installation

`mdagg` comes with Utilz: once Utilz is installed, as the [README](../../README.md#installation) says, `mdagg` is on your PATH, and so is `yq`, which it needs.

```bash
# Verify installation
utilz doctor
mdagg --help
```

---

## Usage

The usage home is `help/mdagg.md`. Run `utilz help mdagg` to read it, or `mdagg --help` for a short summary.

---

## Implementation

### Architecture

```
opt/mdagg/mdagg
├── Invoked via: $UTILZ_HOME/bin/mdagg (symlink)
├── Dispatched by: $UTILZ_HOME/bin/utilz
├── Has access to: $UTILZ_HOME/opt/utilz/lib/common.sh
└── Help from: $UTILZ_HOME/help/mdagg.md
```

### Dependencies

**Required:**

- Bash 3.2+ or Zsh (bash 3.2 is what macOS ships, and is the floor the framework targets)
- `yq` - YAML parsing (install: `brew install yq`)

**Optional:**

- `glow` or `bat` - Better help display (`utilz help` uses the first one it finds, else `cat`)

### File Structure

```bash
opt/mdagg/
├── mdagg          # Main executable (this implementation)
├── mdagg.yaml     # Metadata and dependencies
├── VERSION        # Version number
├── README.md      # This file
└── test/          # BATS tests and fixtures
```

### Code Structure

The `mdagg` script is organised as follows:

1. **Settings & Defaults**
   - Default configuration values
   - Global variables

2. **Functions**
   - `usage()` - Help text
   - `derive_title()` - Section title from a file name (glob and stdin modes)
   - `process_file()` - Individual file processing
   - `process_yaml_config()` - YAML mode handler
   - `process_glob_pattern()` - Glob mode handler
   - `process_stdin()` - Stdin mode handler

3. **Argument Parsing**
   - Parse command-line options
   - Detect input mode

4. **Main Execution**
   - Validate inputs
   - Dispatch to appropriate handler
   - Generate output

---

## Testing

```bash
utilz test mdagg
```

### Run Utilz Doctor

```bash
utilz doctor
```

This checks:

- `$UTILZ_HOME` is set correctly
- `yq` is installed
- Symlinks are configured
- Scripts are executable

---

## Development

### Making Changes

1. Edit `opt/mdagg/mdagg`
2. Test changes: `mdagg --help` and basic functionality
3. Run `utilz doctor` to verify no issues
4. Update help if needed: `help/mdagg.md`

### Code Style

- Use `set -euo pipefail` for error handling
- Use Utilz common functions: `info()`, `error()`, `success()`, `warn()`
- Comment complex logic
- Keep functions focused and single-purpose
- Use descriptive variable names

### Adding Features

Example: Add a new option `--line-numbers`

```bash
# 1. Add to settings
LINE_NUMBERS=false

# 2. Add to argument parsing
-l|--line-numbers)
    LINE_NUMBERS=true
    shift
    ;;

# 3. Implement in process_file()
if [[ "$LINE_NUMBERS" == true ]]; then
    content=$(echo "$content" | nl)
fi

# 4. Update usage() help text
# 5. Update help/mdagg.md documentation
```

---

## Related Tools

- **pandoc**: Universal document converter (markdown → PDF/DOCX/HTML)
- **yq**: YAML processor (required dependency)
- **bat**: Better `cat` with syntax highlighting (optional, for help display)
- **glow**: Render markdown in terminal (optional, for help display)

---

## License

Part of Utilz framework. Personal use.
Copyright © 2025 Matthew Sinclair.

---

## See Also

- [Utilz Framework Documentation](../../help/utilz.md)
- [mdagg Detailed Help](../../help/mdagg.md) - Run: `utilz help mdagg`
- [Utilz Architecture](../../README.md)
