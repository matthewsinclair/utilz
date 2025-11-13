# Utilz Architecture

This document explains how the Utilz framework works internally, focusing on the dispatcher pattern, common library integration, and metadata system.

## Table of Contents

- [Overview](#overview)
- [The Dispatcher Pattern](#the-dispatcher-pattern)
- [UTILZ_HOME Detection](#utilz_home-detection)
- [Common Library Integration](#common-library-integration)
- [Metadata System](#metadata-system)
- [Version Management](#version-management)
- [Test Runner Architecture](#test-runner-architecture)
- [Why This Design?](#why-this-design)
- [Trade-offs and Limitations](#trade-offs-and-limitations)

## Overview

Utilz uses a **single dispatcher** pattern where all utilities are symlinks to a master script (`bin/utilz`). When invoked, the dispatcher:

1. Detects which utility was called by examining `$0`
2. Sources the common library (`opt/utilz/lib/common.sh`)
3. Routes execution to the appropriate implementation in `opt/<utility>/<utility>`
4. Uses `exec` to replace itself with the utility (zero overhead)

This provides a consistent entry point while allowing utilities to be written in any language that can be executed as a script.

## The Dispatcher Pattern

### How It Works

```
User invokes      Symlink points to      Dispatcher examines    Utility runs
$ mdagg file.md → bin/mdagg → bin/utilz → $0 = "mdagg" → exec opt/mdagg/mdagg
```

### Step-by-Step Execution

1. **User invokes a utility**:

   ```bash
   mdagg file.md
   ```

2. **Shell resolves symlink**:

   ```bash
   bin/mdagg -> bin/utilz
   ```

3. **Dispatcher starts** (`bin/utilz`):
   - Detects `UTILZ_HOME` (if not set)
   - Examines `basename "$0"` → `"mdagg"`
   - Sources common library

4. **Dispatcher validates**:
   - Checks if `opt/mdagg/mdagg` exists
   - Checks if it's executable
   - Handles `--help` and `--version` flags

5. **Dispatcher executes**:

   ```bash
   exec "$UTILZ_HOME/opt/mdagg/mdagg" "$@"
   ```

   - Uses `exec` to replace the dispatcher process
   - Zero overhead - no subprocess created
   - Utility receives all original arguments

### Two Invocation Modes

**Mode 1: Direct utility invocation** (via symlink)

```bash
$ mdagg file.md
# Dispatcher detects: INVOKED_AS="mdagg"
# Routes to: opt/mdagg/mdagg
```

**Mode 2: Framework commands** (via "utilz" itself)

```bash
$ utilz help mdagg
# Dispatcher detects: INVOKED_AS="utilz", COMMAND="help"
# Calls: show_help "mdagg"
```

### Dispatcher Code Structure

The dispatcher (`bin/utilz`) has two main sections:

**Section 1: Framework Commands** (lines 60-136)

```bash
if [[ "$INVOKED_AS" == "utilz" ]]; then
    case "$COMMAND" in
        help|doctor|list|test|version|generate)
            # Handle framework commands
            ;;
        *)
            # Unknown command error
            ;;
    esac
fi
```

**Section 2: Utility Dispatch** (lines 138-179)

```bash
# At this point, invoked via symlink (e.g., 'mdagg')
UTIL_NAME="$INVOKED_AS"
UTIL_IMPL="$UTILZ_HOME/opt/$UTIL_NAME/$UTIL_NAME"

# Validate and execute
exec "$UTIL_IMPL" "$@"
```

## UTILZ_HOME Detection

The framework auto-detects its installation directory by following symlinks to find the real script location.

### Detection Algorithm

```bash
determine_utilz_home() {
    local script="$0"

    # Follow symlink chain to find real script
    while [[ -L "$script" ]]; do
        local link_target=$(readlink "$script")
        # Handle relative symlinks
        if [[ "$link_target" != /* ]]; then
            script="$(dirname "$script")/$link_target"
        else
            script="$link_target"
        fi
    done

    # Get directory containing real script
    local script_dir="$(cd "$(dirname "$script")" && pwd)"

    # UTILZ_HOME is parent of bin/
    echo "$(cd "$script_dir/.." && pwd)"
}
```

### Why This Matters

This allows flexible installation:

```bash
# Scenario 1: Direct PATH addition
export PATH="$HOME/Devel/prj/Utilz/bin:$PATH"
$ mdagg file.md  # Works - UTILZ_HOME detected

# Scenario 2: Symlink to ~/bin
ln -s ~/Devel/prj/Utilz/bin/utilz ~/bin/utilz
ln -s ~/Devel/prj/Utilz/bin/mdagg ~/bin/mdagg
$ mdagg file.md  # Works - symlink followed to find UTILZ_HOME

# Scenario 3: Explicit UTILZ_HOME
export UTILZ_HOME="$HOME/Devel/prj/Utilz"
$ mdagg file.md  # Works - uses explicit value
```

## Common Library Integration

The common library (`opt/utilz/lib/common.sh`) provides shared functions for all utilities.

### Loading Strategy

**In the dispatcher** (`bin/utilz` line 48):

```bash
# Source common functions
if [[ -f "$UTILZ_HOME/opt/utilz/lib/common.sh" ]]; then
    source "$UTILZ_HOME/opt/utilz/lib/common.sh"
else
    echo "ERROR: Cannot find common.sh library" >&2
    exit 1
fi
```

**In each utility** (e.g., `opt/mdagg/mdagg` lines 11-23):

```bash
# Source common functions if not already loaded
if [[ "$(type -t info 2>/dev/null)" != "function" ]]; then
    # Determine UTILZ_HOME from script location
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    UTILZ_HOME="${UTILZ_HOME:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

    if [[ -f "$UTILZ_HOME/opt/utilz/lib/common.sh" ]]; then
        source "$UTILZ_HOME/opt/utilz/lib/common.sh"
    else
        echo "ERROR: Cannot find common.sh library" >&2
        exit 1
    fi
fi
```

### Why Check If Already Loaded?

When invoked via the dispatcher, the common library is already sourced. The utility checks `type -t info` to avoid sourcing it twice. This allows utilities to also be:

- Invoked directly: `./opt/mdagg/mdagg file.md`
- Tested in isolation: `bats opt/mdagg/test/*.bats`
- Run without dispatcher

### Common Library Functions

The library provides these categories of functions:

1. **Logging**: `info()`, `success()`, `warn()`, `error()`, `debug()`
   - All write to stderr (>&2) to avoid polluting utility output
   - Color-aware (detects TTY)

2. **Help System**: `show_help()`, `show_version()`
   - Uses glow → bat → cat fallback for markdown rendering
   - Reads from `help/<utility>.md` files

3. **Validation**: `check_command()`, `require_command()`
   - Check for external dependencies
   - Provide helpful error messages

4. **Metadata**: `get_util_metadata()`
   - Parses YAML files using `yq`
   - Extracts version, description, dependencies

5. **Testing**: `run_tests()`, `run_doctor()`
   - Auto-discovers test suites
   - Validates framework installation

## Metadata System

Each utility has a YAML metadata file describing its configuration and dependencies.

### Metadata File Location

```
opt/<utility>/<utility>.yaml
```

Example: `opt/mdagg/mdagg.yaml`

### Metadata Schema

```yaml
name: mdagg
version: 1.0.0
utilz_version: "^1.0.0"  # Compatible framework version
description: Markdown aggregator for concatenating multiple markdown files
author: Matthew Sinclair
website: https://matthewsinclair.com
help_file: ../../help/mdagg.md

# Required external dependencies
dependencies:
  - name: yq
    required: true
    install: brew install yq
    purpose: YAML configuration file parsing

# Optional dependencies for enhanced functionality
optional_dependencies:
  - name: glow
    install: brew install glow
    purpose: Beautiful markdown rendering for help documentation
```

### Version File References

The framework itself uses a version file reference:

```yaml
# opt/utilz/utilz.yaml
name: utilz
version_file: ../../VERSION  # Points to /VERSION file
description: Universal utilities framework and dispatcher
```

This allows a single source of truth for the framework version (`/VERSION` file).

### Reading Metadata

Utilities use `get_util_metadata()` to read their metadata:

```bash
# Get utility version
version=$(get_util_metadata "mdagg" ".version")

# Get description
description=$(get_util_metadata "mdagg" ".description")

# Get required framework version
utilz_version=$(get_util_metadata "mdagg" ".utilz_version")
```

## Version Management

Utilz supports two versioning strategies:

### Framework Version

The framework version is stored in `/VERSION`:

```bash
$ cat VERSION
1.0.0
```

Referenced in `opt/utilz/utilz.yaml`:

```yaml
version_file: ../../VERSION
```

### Utility Versions

Utilities can specify their own version:

```yaml
# opt/mdagg/mdagg.yaml
version: 1.0.0
```

### Version Compatibility

Utilities declare framework version compatibility using caret notation:

```yaml
utilz_version: "^1.0.0"  # Compatible with 1.x.x
```

The `run_doctor()` function checks compatibility:

```bash
# Extract major version from requirement (e.g., "^1.0.0" -> "1")
local required_major=$(echo "$required_utilz_version" | sed 's/^\^//' | sed 's/[^0-9].*//')

# Extract framework major version
local framework_major=$(echo "$framework_version" | cut -d. -f1)

# Compare major versions
if [[ "$required_major" != "$framework_major" ]]; then
    # Report incompatibility
fi
```

## Test Runner Architecture

The test runner (`run_tests()` in common.sh) auto-discovers and runs tests for all utilities.

### Test Discovery

```bash
# Find all utilities with test directories
for symlink in "$UTILZ_HOME"/bin/*; do
    name=$(basename "$symlink")
    test_dir="$UTILZ_HOME/opt/$name/test"

    if [[ -d "$test_dir" ]]; then
        # Found tests for this utility
        cd "$test_dir"
        bats *.bats
    fi
done
```

### Test Organization

```
opt/<utility>/test/
├── <utility>.bats          # Test file
└── fixtures/               # Test data (optional)
```

Each test file loads the common test helper:

```bash
load "../../utilz/test/test_helper.bash"
```

### Running Tests

```bash
# All tests
$ utilz test

# Specific utility
$ utilz test mdagg

# Direct invocation
$ cd opt/mdagg/test && bats mdagg.bats
```

## Why This Design?

### Problem: Utility Sprawl

Before Utilz:

```
~/bin/
├── aggregate-markdown
├── process-logs
├── backup-notes
├── sync-configs
└── ... (each with different help, error handling, etc.)
```

### Solution: Unified Framework

With Utilz:

```
~/Devel/prj/Utilz/
├── bin/utilz (single dispatcher)
├── bin/mdagg -> utilz (symlink)
├── bin/logtool -> utilz (symlink)
└── opt/
    ├── mdagg/mdagg (implementation)
    └── logtool/logtool (implementation)
```

### Benefits

1. **Single Point of Entry**: All utilities go through dispatcher
2. **Consistent UX**: Unified help, error handling, output formatting
3. **Code Reuse**: Common library shared across all utilities
4. **Easy Discovery**: `utilz list` shows all available utilities
5. **Portable**: Clone repo, add bin/ to PATH, done
6. **Testable**: Built-in test framework with `utilz test`
7. **Maintainable**: Update common library once, all utilities benefit
8. **Zero Overhead**: Uses `exec`, not subprocesses

### Design Principles

1. **Simple**: Bash/zsh only, no complex dependencies
2. **Consistent**: All utilities follow same patterns
3. **Portable**: Works on any Unix-like system
4. **Extensible**: Easy to add new utilities
5. **Self-Contained**: Auto-detects installation directory

## Trade-offs and Limitations

### Trade-offs

**Symlinks Required**

- Pros: Zero overhead, simple routing
- Cons: Requires filesystem that supports symlinks (won't work on some Windows setups without WSL)

**Framework Dependency**

- Pros: Shared code, consistent UX
- Cons: Utilities depend on framework structure

**Bash/Zsh Only**

- Pros: Available everywhere, no installation needed
- Cons: Not as feature-rich as Python/Ruby for complex tasks
- Note: Utilities can be written in any language, just invoked via bash wrapper

### Limitations

1. **Not a Package Manager**: Doesn't handle external dependencies
2. **Not for Distribution**: Designed for personal/team use, not public distribution
3. **No Versioned Dependencies**: Utilities use whatever framework version is installed
4. **Filesystem Requirements**: Requires symlink support
5. **PATH Configuration**: Requires adding `$UTILZ_HOME/bin` to PATH

### When Not to Use Utilz

- Distributing utilities to end users (use Homebrew, npm, etc.)
- Utilities with complex dependencies (use proper package manager)
- Cross-platform GUI applications (use appropriate framework)
- High-performance requirements (use compiled language)
- Team needs versioned utility distribution (use proper package system)

### When to Use Utilz

- Personal collection of CLI utilities
- Team-shared internal tools
- Rapid prototyping of command-line utilities
- Learning bash best practices
- Multi-machine utility synchronization (via git)

## Summary

Utilz provides a simple, consistent framework for managing command-line utilities through:

- **Dispatcher pattern**: Single entry point routing to implementations
- **Common library**: Shared functions for consistent UX
- **Metadata system**: YAML files for configuration and dependencies
- **Auto-detection**: Finds installation directory automatically
- **Zero overhead**: Uses `exec` for direct execution
- **Built-in testing**: Test runner with BATS framework

The design prioritizes simplicity, consistency, and portability over features, making it ideal for personal productivity and team-shared internal tools.
