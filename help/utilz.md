# Utilz - Universal Utilities Framework

**Version**: run `utilz version`
<!-- NO VERSION LITERAL IN THIS FILE OR ANY HELP FILE, AND THIS ONE LEARNED IT
     FIRST: hardcoding the framework version here drifted it to 2.2.0 while
     2.4.0 shipped. The fix was applied to this file alone and left in fifteen
     others, where it drifted again -- cleanz's README said 1.1.0 against a
     yaml of 1.2.0, and todo's help AND README said 1.0.0 against 1.1.0. The
     version has ONE home: the utility's yaml, or the file its version_file
     points at. A test in common_lib.bats holds every help file and every
     utility README to it. -->

**Author**: Matthew Sinclair
**Location**: worked out from the dispatcher's own path -- a source checkout (typically `~/Devel/prj/Utilz`) or a published install (typically `~/Devel/opt/utilz`). `utilz version` names which one answered.

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
export PATH="$HOME/Devel/prj/Utilz/bin:$PATH"

# Reload shell config
source ~/.zshrc  # or ~/.bashrc

# Run diagnostics
utilz doctor
```

**Do NOT export `UTILZ_HOME`.** The dispatcher derives it from its own location
and ignores an inherited value. This page told you to export it until v2.5.1;
with two trees in play, an ambient `UTILZ_HOME` silently sent the _installed_
utilz back to the checkout. Delete those lines if you have them.

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

`-h` and `--help` are accepted as aliases, and take the same optional utility argument:

```bash
utilz --help
utilz -h
utilz --help mdagg
```

### `utilz doctor`

Run diagnostics to check that Utilz is properly configured.

Seven checks:

1. `UTILZ_HOME` resolves to a valid tree
2. Directory structure is correct
3. `bin/utilz` exists and is executable
4. `utilz` is reachable on `$PATH`
5. All installed utilities are properly configured
6. External dependencies are installed (eg `yq`)
7. Install integrity -- every owned file matches the manifest it was published
   with. In a source checkout there is no manifest, and doctor says so rather
   than passing silently.

Check results are written to **stderr** and the step headers to stdout, so
`utilz doctor | grep` sees the headers and not the answers. Redirect both
(`2>&1`) if you are capturing it.

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

Every answer carries **both** versions in play -- the framework's and the utility's -- because being handed one of them is how a bug report arrives missing the half that explains it. **There is no `v` prefix anywhere**: it is noise, and it was the only thing making the framework's line a different shape from a utility's.

```bash
$ utilz version          # --version is accepted as an alias
utilz:2.7.0
Universal utilities framework and dispatcher
installed at /Users/you/Devel/opt/utilz (a1b2c3d)

$ utilz mdagg --version  # either invocation form, byte-identical
utilz:2.7.0/mdagg:1.0.0
Markdown aggregator

$ mdagg --version
utilz:2.7.0/mdagg:1.0.0
Markdown aggregator
```

**Both invocation forms give the same bytes**, and that is a guarantee rather than a coincidence: `bin/utilz` answers `--version` from one place for both. Until ST0015 it intercepted the symlink form only, thirteen utilities hand-copied an arm to cover the other, and the two that never copied it -- `todo` and `prez` -- were the two that disagreed with themselves.

The framework's third line names **which tree replied** and the commit it was cut from, which is the fastest way to tell a source checkout from a published install when the two disagree.

`-v` is deliberately unbound: it reads as a verbose flag, and no utility binds it.

### `utilz install` / `utilz upgrade`

Publish a runnable install of this checkout, so the source can be worked on
without disturbing the copy you use.

```bash
utilz install                 # publish to install.prefix from opt/utilz/utilz.yaml
utilz install --prefix DIR    # publish somewhere else
utilz install --force         # publish over an existing install
utilz upgrade                 # replace an existing install with this checkout
utilz upgrade --force         # overwrite files that were edited in place
```

Where it publishes is configuration with no built-in default: set
`install.prefix` in `opt/utilz/utilz.yaml`. Unset is refused by name rather
than guessed, because a publish to the wrong place looks exactly like a publish
to the right one.

**The source tree must be clean, and no flag overrides that, `--force`
included.** The manifest records the commit the bytes came from, and that claim
only holds when nothing is uncommitted.

`install` and `upgrade` mirror each other: `install` refuses when an install
already exists and names `upgrade`; `upgrade` refuses when none exists and
names `install`. `upgrade` reports files edited in place and leaves them alone
without `--force`, keeping their install-time checksum so the next check still
reports them.

### `utilz use [dev|opt]`

Switch which tree your PATH symlinks serve. No path is typed either way -- each
tree carries the address of the other.

```bash
utilz use opt     # point them at install.prefix
utilz use dev     # point them at the source the install was published from
utilz use         # report which tree they serve now, and change nothing
```

### `utilz relink`

The mechanism `utilz use` is built on, when you want to name a tree yourself.

```bash
utilz relink                  # repoint at install.prefix
utilz relink --prefix DIR     # repoint at a tree you name
utilz relink --bin-dir DIR    # links live somewhere other than ~/.local/bin
```

Links resolving into a Utilz tree are repointed; anything else is left alone
and reported as skipped. **`install` and `upgrade` never do this implicitly** --
relinking your environment takes a verb you typed.

### `utilz integration <verb>`

Editor-neutral integration manifest surface. Consumed by the Utilz Emacs bridge and by any future VSCode / Zed / Vim integration.

Verbs:

- `commands` — emit a TSV manifest of every utility that declares an `integration:` block in its YAML. One row per utility; columns are `name`, `description`, `input`, `output`, `flags` (tab-separated).

```bash
# Render as an aligned table
utilz integration commands | column -t -s$'\t'

# Feed directly to an integration (Emacs, VSCode, ...)
utilz integration commands
```

The walker lives in `opt/utilz/lib/common.sh` as `emit_integration_tsv` and is the single source of truth (Highlander). Utilities without an `integration:` block are silently omitted.

### `utilz emacs <verb>`

Emacs-specific installer and health check for the Utilz elisp bridge. See `intent/st/ST0007/` for the design.

Verbs:

- `install --dest PATH [--symlink] [--force]` — copy (or symlink with `--symlink`) the canonical `static/emacs/utilz.el` to `PATH`. Idempotent: re-running with the same destination is a no-op; use `--force` to overwrite a differing destination. Prints the `(load ...)` line to add to your Emacs config.
- `doctor` — verify `utilz` is on `PATH` (reachable by Emacs child processes), every installed utility has a valid `integration:` block, and the canonical elisp file is present (info-level check; absence is expected pre-WP03).

```bash
# Install into Doom config as a symlink (rolls forward on 'git pull')
utilz emacs install \
  --dest ~/.config/doom/custom/160-utilz.el \
  --symlink

# Then add the printed load statement to ~/.config/doom/config.el

# Health-check
utilz emacs doctor
```

Future integration targets (VSCode, Zed, Vim) are expected to land as parallel `utilz <editor>` subcommand families that consume the same `utilz integration commands` TSV.

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
- `require_yq` - Gate on the `yq` hard dependency; call ONCE before a loop, never per-iteration
- `each_utility` - Emit every installed utility name, one per line; consume with `< <(each_utility)`, not a pipe

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

````bash
cat > $UTILZ_HOME/help/myutil.md <<'EOF'
# myutil - My Custom Utility

**Version**: run `myutil --version`

## Purpose
Brief description of what myutil does.

## Usage
```bash
myutil [options] <args>
````

## Examples

...
EOF

````

### 4. Test

```bash
# Run diagnostics
utilz doctor

# Test utility
myutil --help
myutil
````

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

- Bash 3.2+ or Zsh (bash 3.2 is what macOS ships, and is the floor the framework targets)
- Standard Unix tools (`grep`, `sed`, `awk`, `cat`)
- `yq` -- the single YAML parser for all utility metadata. Required by the framework itself, not by any one utility: `utilz list`, `utilz doctor`, and `utilz generate` all read `opt/<name>/<name>.yaml` through it.
  ```bash
  brew install yq
  ```

### Utility-Specific

- **syncz**: `unison` for `--bidi` state-tracked mode (rsync fallback otherwise)
- **cleanz**: `exiftool` for `--image` metadata stripping

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

### lnrel - Relative Symlink Creator

Creates symlinks with relative paths. Portable symlinks that survive directory tree moves.

See `utilz help lnrel` for details.

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
3. **Portable**: Works on any \*nix system
4. **Extensible**: Easy to add new utilities
5. **Self-contained**: Minimal external dependencies

---

## License

Personal use. Copyright © 2025 Matthew Sinclair.

---

**End of Utilz Help**
