# Utilz - Universal Utilities Framework

**Version**: 1.0.0
**Author**: Matthew Sinclair
**Location**: `$UTILZ_HOME` (typically `~/Devel/prj/Utilz`)

---

## Overview

**Utilz** (with a 'z') is a unified framework for managing personal command-line utilities across multiple machines. It provides:

- **Single dispatcher**: All utilities are symlinks to a master `utilz` script
- **Consistent UX**: Unified help, error handling, and output formatting
- **Easy management**: Add utilities by dropping implementation in `opt/{name}/` and creating a symlink
- **Portable**: Clone repo, add `bin/` to `$PATH`, done
- **Multi-language support**: Utilities can be written in bash/zsh, Rust, Elixir, or any language

---

## Quick Start

### Installation

```bash
# Clone or create Utilz directory
mkdir -p ~/Devel/prj/Utilz
cd ~/Devel/prj/Utilz

# Add to your shell config (~/.zshrc or ~/.bashrc)
export UTILZ_HOME="$HOME/Devel/prj/Utilz"
export PATH="$UTILZ_HOME/bin:$PATH"

# Reload shell config
source ~/.zshrc  # or ~/.bashrc

# Run diagnostics
utilz doctor
```

### First Utility

```bash
# All utilities should already be set up
# Try the markdown aggregator:
mdagg --help
```

---

## Commands

### `utilz help [utility]`

Show help for Utilz or a specific utility.

```bash
# Show this help
utilz help

# Show help for mdagg utility
utilz help mdagg
```

### `utilz doctor`

Run diagnostics to check that Utilz is properly configured.

Checks:
- `$UTILZ_HOME` is set and valid
- Directory structure is correct
- `bin/utilz` exists and is executable
- `$UTILZ_HOME/bin` is in `$PATH`
- All installed utilities are properly configured
- External dependencies are installed (e.g., `yq`)

```bash
utilz doctor
```

### `utilz list`

List all available utilities with brief descriptions.

```bash
utilz list
```

### `utilz version`

Show version information for Utilz or a specific utility.

```bash
# Utilz version
utilz version

# Specific utility version (if invoked as utility)
mdagg --version
```

---

## Architecture

### Directory Structure

```
$UTILZ_HOME/
├── bin/
│   ├── utilz              # Master dispatcher (executable)
│   └── mdagg -> utilz     # Utility symlinks
│
├── opt/
│   ├── utilz/
│   │   └── lib/
│   │       └── common.sh  # Shared functions library
│   │
│   └── mdagg/
│       └── mdagg          # Utility implementation (executable)
│
└── help/
    ├── utilz.md           # This file
    └── mdagg.md           # Utility help files
```

### How It Works

1. **Invocation**: User runs `mdagg config.yaml -o output.md`
2. **Dispatch**: `$UTILZ_HOME/bin/mdagg` is a symlink to `utilz`
3. **Detection**: `utilz` detects it was invoked as `mdagg` (via `$0`)
4. **Setup**: Sources common functions from `opt/utilz/lib/common.sh`
5. **Execution**: Dispatches to `$UTILZ_HOME/opt/mdagg/mdagg "$@"`

### Common Functions

All utilities have access to shared functions in `opt/utilz/lib/common.sh`:

**Logging**:
- `info "message"` - Informational message (blue ℹ)
- `success "message"` - Success message (green ✓)
- `warn "message"` - Warning message (yellow ⚠)
- `error "message"` - Error message (red ✗)
- `debug "message"` - Debug message (only if `UTILZ_DEBUG=1`)

**Utilities**:
- `show_help "utility"` - Display help from `help/{utility}.md`
- `check_command "cmd"` - Check if command exists
- `require_command "cmd" "install hint"` - Require command or exit with hint
- `parse_yaml "file.yaml" "query"` - Parse YAML using `yq`

**Colors** (automatically disabled when not a TTY):
- `$BOLD`, `$RED`, `$GREEN`, `$YELLOW`, `$BLUE`, `$RESET`

---

## Adding a New Utility

### 1. Create the Implementation

```bash
# Create directory
mkdir -p $UTILZ_HOME/opt/myutil

# Create executable script
cat > $UTILZ_HOME/opt/myutil/myutil <<'EOF'
#!/usr/bin/env bash
# Implementation of myutil
set -euo pipefail

# $UTILZ_HOME and common functions are already available
info "Running myutil..."

# Your utility logic here
echo "Hello from myutil!"
success "Done!"
EOF

chmod +x $UTILZ_HOME/opt/myutil/myutil
```

### 2. Create a Symlink

```bash
cd $UTILZ_HOME/bin
ln -s utilz myutil
```

### 3. Create Help File

```bash
cat > $UTILZ_HOME/help/myutil.md <<'EOF'
# myutil - My Custom Utility

**Version**: 1.0.0

## Purpose
Brief description of what myutil does.

## Usage
```bash
myutil [options] <args>
```

## Examples
...
EOF
```

### 4. Test

```bash
# Run diagnostics
utilz doctor

# Test utility
myutil --help
myutil
```

---

## Multi-Language Support

Utilities can be written in any language:

### Bash/Zsh (Default)
```bash
#!/usr/bin/env bash
# opt/myutil/myutil
```

### Rust
```bash
#!/usr/bin/env bash
# opt/myutil/myutil (wrapper script)
exec "$UTILZ_HOME/opt/myutil/target/release/myutil" "$@"
```

Then build Rust binary in `opt/myutil/`:
```bash
cd $UTILZ_HOME/opt/myutil
cargo build --release
```

### Elixir
```bash
#!/usr/bin/env elixir
# opt/myutil/myutil
```

### Python (if you must)
```bash
#!/usr/bin/env python3
# opt/myutil/myutil
```

The dispatcher doesn't care about the implementation language - it just needs an executable file.

---

## Environment Variables

### Required

- `$UTILZ_HOME` - Path to Utilz installation (auto-detected if not set)

### Optional

- `$UTILZ_DEBUG` - Set to `1` to enable debug output
- `$NO_COLOR` - Set to disable colored output

---

## Dependencies

### Required

- Bash 4.0+ or Zsh
- Standard Unix tools (`grep`, `sed`, `awk`, `cat`)

### Utility-Specific

- **mdagg**: Requires `yq` for YAML parsing
  ```bash
  brew install yq
  ```

### Optional (Recommended)

- `bat` or `mdcat` - Better markdown rendering for help
  ```bash
  brew install bat
  ```

---

## Troubleshooting

### "Command not found: utilz"

**Problem**: `$UTILZ_HOME/bin` is not in your `$PATH`.

**Fix**:
```bash
echo 'export UTILZ_HOME="$HOME/Devel/prj/Utilz"' >> ~/.zshrc
echo 'export PATH="$UTILZ_HOME/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### "Utility implementation not found"

**Problem**: Symlink exists but implementation is missing.

**Fix**: Run `utilz doctor` to diagnose. Ensure:
1. `opt/{utility}/{utility}` exists
2. File is executable: `chmod +x opt/{utility}/{utility}`

### "yq: command not found"

**Problem**: YAML utilities require `yq`.

**Fix**:
```bash
brew install yq
```

### General Issues

Always start with:
```bash
utilz doctor
```

This will identify and suggest fixes for common configuration issues.

---

## Installed Utilities

Run `utilz list` to see all installed utilities, or check the list below:

### mdagg - Markdown Aggregator
Concatenates multiple markdown files into a single document for PDF generation.

See `utilz help mdagg` for details.

---

## Version History

### 1.0.0 (2025-01-12)
- Initial release
- Core dispatcher framework
- `utilz help`, `utilz doctor`, `utilz list` commands
- Multi-language utility support
- First utility: `mdagg` (Markdown Aggregator)

---

## Contributing

This is a personal utilities framework, but the architecture can be adapted for team use.

### Design Principles

1. **Simple**: Each utility does one thing well
2. **Consistent**: Unified UX across all utilities
3. **Portable**: Works on any *nix system
4. **Extensible**: Easy to add new utilities
5. **Self-contained**: Minimal external dependencies

---

## License

Personal use. Copyright © 2025 Matthew Sinclair.

---

**End of Utilz Help**
