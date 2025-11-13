# Developer Guide

This guide covers everything you need to know to create utilities with the Utilz framework.

## Table of Contents

- [Quick Start](#quick-start)
- [Using the Generator](#using-the-generator)
- [Project Structure](#project-structure)
- [Writing Your Implementation](#writing-your-implementation)
- [Metadata Files](#metadata-files)
- [Using the Common Library](#using-the-common-library)
- [Writing Tests](#writing-tests)
- [Multi-Language Utilities](#multi-language-utilities)
- [Version Management](#version-management)
- [Best Practices](#best-practices)

## Quick Start

Create a new utility in 30 seconds:

```bash
# Generate scaffold
$ utilz generate logtool "Process and analyze log files" "Your Name"

✓ Created utility scaffold for 'logtool'
  Implementation: opt/logtool/logtool
  Metadata: opt/logtool/logtool.yaml
  Help: help/logtool.md
  README: opt/logtool/README.md
  Tests: opt/logtool/test/logtool.bats
  Symlink: bin/logtool -> utilz

# Edit implementation
$ vim opt/logtool/logtool

# Test it
$ utilz test logtool

# Use it
$ logtool --help
```

## Using the Generator

The generator creates a complete utility scaffold with all necessary files.

### Command Syntax

```bash
utilz generate <name> [description] [author]
```

**Arguments:**

- `<name>` (required): Utility name (lowercase, alphanumeric + hyphens only)
- `[description]` (optional): Short description of what the utility does
- `[author]` (optional): Author name (defaults to git config user.name)

### Examples

```bash
# Minimal (prompts for description and uses git config for author)
$ utilz generate logtool

# With description
$ utilz generate logtool "Process log files"

# Complete
$ utilz generate logtool "Process log files" "Jane Developer"
```

### What Gets Created

The generator creates:

1. **Implementation** (`opt/<name>/<name>`)
   - Executable bash script with template code
   - Common library integration boilerplate
   - Argument parsing skeleton

2. **Metadata** (`opt/<name>/<name>.yaml`)
   - Version, description, author
   - Framework version requirement
   - Dependency declarations

3. **Help Documentation** (`help/<name>.md`)
   - Formatted help file for `utilz help <name>`
   - Includes usage, options, examples sections

4. **README** (`opt/<name>/README.md`)
   - Developer-focused documentation
   - Implementation notes template

5. **Test File** (`opt/<name>/test/<name>.bats`)
   - BATS test file with example tests
   - Test helper integration

6. **Symlink** (`bin/<name> -> utilz`)
   - Links utility name to dispatcher

### Generator Validation

The generator validates:

- Name format (lowercase, alphanumeric + hyphens)
- No conflicts with existing utilities
- No conflicts with framework commands
- Valid author name (if provided)

## Project Structure

Each utility follows a consistent structure:

```
opt/<utility>/
├── <utility>           # Main implementation (executable)
├── <utility>.yaml      # Metadata file
├── README.md           # Developer documentation
└── test/               # Test directory
    └── <utility>.bats  # Test file

bin/
└── <utility> -> utilz  # Symlink to dispatcher

help/
└── <utility>.md        # User help documentation
```

### Directory Organization

**`opt/<utility>/`** - Utility home directory

- Contains all utility-specific code and configuration
- Implementation file has same name as utility
- Must be executable (`chmod +x`)

**`bin/`** - Symlink directory

- All utilities symlink to `utilz` dispatcher
- Symlink name determines utility name

**`help/`** - Help documentation

- Markdown files rendered by `utilz help`
- Displayed with glow/bat/cat fallback

## Writing Your Implementation

### Template Structure

The generated implementation has this structure:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Source common library (if not already loaded)
if [[ "$(type -t info 2>/dev/null)" != "function" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    UTILZ_HOME="${UTILZ_HOME:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

    if [[ -f "$UTILZ_HOME/opt/utilz/lib/common.sh" ]]; then
        source "$UTILZ_HOME/opt/utilz/lib/common.sh"
    else
        echo "ERROR: Cannot find common.sh library" >&2
        exit 1
    fi
fi

# Your implementation here
```

### Required Elements

1. **Shebang**: `#!/usr/bin/env bash` (or other interpreter)
2. **Error Handling**: `set -euo pipefail` for bash scripts
3. **Common Library Loading**: Check if loaded, source if not
4. **Exit Codes**: Use consistent exit codes (0 = success, non-zero = error)

### Argument Parsing

The template includes a basic argument parsing loop:

```bash
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help "$(basename "$0")"
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -*)
            error "Unknown option: $1"
            exit 1
            ;;
        *)
            # Positional argument
            FILES+=("$1")
            shift
            ;;
    esac
done
```

### Error Handling

Use the common library error functions:

```bash
# Fatal error (exits)
error "Configuration file not found: $config_file"
exit 1

# Warning (continues)
warn "Cache directory not found, creating it"

# Informational
info "Processing 42 files"

# Success
success "Operation completed"
```

### Output Guidelines

1. **User-facing output**: Write to stdout

   ```bash
   echo "Result: $value"
   ```

2. **Logging/Status**: Use common library functions (write to stderr)

   ```bash
   info "Processing file: $file"
   ```

3. **Errors**: Use `error()` function (writes to stderr)

   ```bash
   error "Failed to process file: $file"
   ```

This allows users to pipe utility output while still seeing status messages.

## Metadata Files

Each utility has a YAML metadata file describing its configuration.

### Basic Metadata

```yaml
name: logtool
version: 1.0.0
utilz_version: "^1.0.0"
description: Process and analyze log files
author: Your Name
website: https://yoursite.com
help_file: ../../help/logtool.md
```

### Required Fields

- `name`: Utility name (must match directory and file name)
- `version`: Semantic version (MAJOR.MINOR.PATCH)
- `utilz_version`: Compatible framework version (caret notation)
- `description`: One-line description
- `author`: Author name
- `help_file`: Relative path to help file

### Optional Fields

**Website**:

```yaml
website: https://github.com/you/logtool
```

**Version File Reference** (instead of inline version):

```yaml
version_file: ../../VERSION
```

### Dependencies

**Required Dependencies**:

```yaml
dependencies:
  - name: jq
    required: true
    install: brew install jq
    purpose: JSON parsing and processing
```

**Optional Dependencies**:

```yaml
optional_dependencies:
  - name: bat
    install: brew install bat
    purpose: Syntax highlighting for output
```

### Complete Example

```yaml
name: logtool
version: 1.0.0
utilz_version: "^1.0.0"
description: Process and analyze log files
author: Jane Developer
website: https://github.com/janedev/logtool
help_file: ../../help/logtool.md

dependencies:
  - name: jq
    required: true
    install: brew install jq
    purpose: JSON parsing

optional_dependencies:
  - name: bat
    install: brew install bat
    purpose: Colorized output

features:
  - Parse JSON logs
  - Filter by severity level
  - Aggregate statistics
  - Export to CSV
```

## Using the Common Library

The common library (`opt/utilz/lib/common.sh`) provides shared functions.

### Logging Functions

All logging functions write to stderr (>&2) and are color-aware.

```bash
info "Processing started"      # Blue
success "Operation complete"   # Green
warn "Cache not found"         # Yellow
error "File not found"         # Red
debug "Variable value: $foo"   # Gray (only if UTILZ_DEBUG=1)
```

### Help and Version

```bash
# Show help (reads from help/<utility>.md)
show_help "logtool"

# Show version (reads from YAML metadata)
show_version "logtool"
```

### Command Validation

```bash
# Check if command exists (returns 0 or 1)
if check_command "jq"; then
    echo "jq is installed"
fi

# Require command (exits if not found)
require_command "jq" "jq is required for JSON parsing"
```

### Metadata Access

```bash
# Get utility version
version=$(get_util_metadata "logtool" ".version")

# Get description
description=$(get_util_metadata "logtool" ".description")

# Get framework requirement
utilz_version=$(get_util_metadata "logtool" ".utilz_version")
```

### Framework Functions

```bash
# List all utilities
list_utilities

# Run doctor checks
run_doctor

# Run tests
run_tests "logtool"  # Specific utility
run_tests            # All utilities
```

## Writing Tests

Utilz uses BATS (Bash Automated Testing System) for testing.

### Test File Structure

```bash
#!/usr/bin/env bats

load "../../utilz/test/test_helper.bash"

@test "logtool --help shows usage" {
    run_utility logtool --help
    assert_success
    assert_output_contains "Usage"
}

@test "logtool processes log file" {
    echo "INFO: Test message" > test.log
    run_utility logtool test.log
    assert_success
    assert_output_contains "processed"
}
```

### Test Helper Functions

**Execution**:

```bash
run_utility logtool --help     # Run your utility
run_utilz help logtool          # Run framework command
```

**Assertions**:

```bash
assert_success                  # Exit code was 0
assert_failure                  # Exit code was non-zero
assert_exit_code 1              # Specific exit code
assert_output_contains "text"   # Output contains string
refute_output_contains "text"   # Output does NOT contain
assert_output "exact match"     # Exact output match
```

**File Assertions**:

```bash
assert_file_exists "test.log"
assert_file_not_exists "temp.log"
assert_file_contains "test.log" "expected text"
```

**Test Data Creation**:

```bash
# Create markdown files (for testing)
create_markdown_files 3    # Creates test1.md, test2.md, test3.md
```

### Running Tests

```bash
# All tests
$ utilz test

# Specific utility
$ utilz test logtool

# Direct invocation (from test directory)
$ cd opt/logtool/test
$ bats logtool.bats

# Single test
$ bats logtool.bats -f "help shows usage"
```

### Test Best Practices

1. **Use test helpers**: Don't reinvent assertion functions
2. **Isolate tests**: Each test runs in a temp directory
3. **Test error cases**: Not just happy path
4. **Use descriptive names**: Test names should explain what they test
5. **Clean up**: Tests auto-clean temp directories
6. **Skip when needed**: Use `skip "reason"` for conditional tests

### Example Test Suite

```bash
#!/usr/bin/env bats

load "../../utilz/test/test_helper.bash"

@test "help flag shows usage" {
    run_utility logtool --help
    assert_success
    assert_output_contains "Usage"
}

@test "version flag shows version" {
    run_utility logtool --version
    assert_success
    assert_output_matches "^logtool v[0-9]"
}

@test "processes single log file" {
    echo "INFO: test" > test.log
    run_utility logtool test.log
    assert_success
}

@test "fails gracefully on missing file" {
    run_utility logtool nonexistent.log
    assert_failure
    assert_output_contains "not found"
}

@test "requires jq dependency" {
    if ! command_exists jq; then
        run_utility logtool --json test.log
        assert_failure
        assert_output_contains "jq"
    fi
}
```

## Multi-Language Utilities

Utilities can be written in any language, invoked via a bash wrapper.

### Bash Wrapper Pattern

```bash
#!/usr/bin/env bash
set -euo pipefail

# Source common library
if [[ "$(type -t info 2>/dev/null)" != "function" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    UTILZ_HOME="${UTILZ_HOME:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
    source "$UTILZ_HOME/opt/utilz/lib/common.sh"
fi

# Check for Python
require_command "python3" "Python 3 is required"

# Execute Python implementation
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$SCRIPT_DIR/logtool.py" "$@"
```

### Project Structure

```
opt/logtool/
├── logtool         # Bash wrapper (dispatcher invokes this)
├── logtool.py      # Python implementation
├── logtool.yaml    # Metadata
└── test/
    └── logtool.bats
```

### Supported Languages

Any language that can be invoked as a script:

- **Python**: `exec python3 "$SCRIPT_DIR/logtool.py" "$@"`
- **Ruby**: `exec ruby "$SCRIPT_DIR/logtool.rb" "$@"`
- **Node.js**: `exec node "$SCRIPT_DIR/logtool.js" "$@"`
- **Compiled** (Rust, Go): Build binary, `exec "$SCRIPT_DIR/logtool" "$@"`

### Dependency Declaration

Declare language dependency in metadata:

```yaml
dependencies:
  - name: python3
    required: true
    install: brew install python3
    purpose: Runtime for logtool implementation
```

## Version Management

### Utility Versioning

Each utility declares its own version:

```yaml
version: 1.0.0
```

### Framework Compatibility

Declare compatible framework version with caret notation:

```yaml
utilz_version: "^1.0.0"  # Compatible with 1.x.x
```

**Version Compatibility Rules**:

- `^1.0.0`: Compatible with 1.x.x (major version must match)
- `^2.0.0`: Compatible with 2.x.x (incompatible with 1.x.x)

### Checking Compatibility

The `utilz doctor` command checks version compatibility:

```bash
$ utilz doctor
[5/6] Checking installed utilities...
⚠ Version incompatibilities detected:
    - logtool (requires Utilz ^2.0.0, have 1.0.0)
```

### Updating Versions

When releasing a new version of your utility:

1. Update version in YAML:

   ```yaml
   version: 1.1.0
   ```

2. Update CHANGELOG (if you have one)

3. Commit and tag:

   ```bash
   git commit -am "logtool v1.1.0: Add JSON support"
   git tag logtool-v1.1.0
   ```

## Best Practices

### Naming

- **Use lowercase**: `logtool`, not `LogTool`
- **Use hyphens**: `log-analyzer`, not `log_analyzer`
- **Be specific**: `git-backup`, not `backup`
- **Avoid conflicts**: Don't use common command names (`test`, `time`, etc.)

### Error Handling

- **Use set -euo pipefail**: Catch errors early
- **Check prerequisites**: Validate dependencies before starting work
- **Provide helpful errors**: Tell users how to fix the problem
- **Use exit codes**: 0 = success, 1 = user error, 2 = system error

### Logging

- **Use common library functions**: `info()`, `warn()`, `error()`
- **Write to stderr**: Keep stdout clean for piping
- **Provide context**: Include filenames, line numbers in errors
- **Support verbose mode**: Add `-v/--verbose` flag

### Documentation

- **Write clear help**: Include examples, not just syntax
- **Document dependencies**: List all required and optional dependencies
- **Include README**: Developer-focused implementation notes
- **Add comments**: Explain why, not what (code shows what)

### Testing

- **Test error cases**: Not just happy path
- **Test with real data**: Create realistic test fixtures
- **Test edge cases**: Empty input, missing files, etc.
- **Keep tests fast**: Tests should run in seconds, not minutes

### Performance

- **Avoid unnecessary work**: Check if output exists before regenerating
- **Stream when possible**: Don't load entire files into memory
- **Use efficient tools**: `grep`, `awk`, `sed` faster than loops
- **Profile if slow**: Use `time` to find bottlenecks

### Compatibility

- **Use portable bash**: Avoid bashisms if targeting zsh too
- **Check tool availability**: Use `check_command()` for dependencies
- **Handle missing dependencies gracefully**: Provide install instructions
- **Test on target systems**: macOS and Linux have differences

### Code Organization

- **Keep utilities focused**: One utility, one purpose
- **Extract functions**: Don't write 500-line monoliths
- **Use constants**: Define paths, defaults at top
- **Consistent style**: Follow existing utility patterns

### Example: Complete Utility

Here's a minimal but complete utility following best practices:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Source common library
if [[ "$(type -t info 2>/dev/null)" != "function" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    UTILZ_HOME="${UTILZ_HOME:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
    source "$UTILZ_HOME/opt/utilz/lib/common.sh"
fi

# Constants
readonly VERSION="1.0.0"
readonly PROG_NAME="$(basename "$0")"

# Defaults
VERBOSE=false
OUTPUT_DIR="."

# Functions
usage() {
    cat <<EOF
Usage: $PROG_NAME [options] <file>

Process log files and extract errors.

Options:
  -o, --output DIR   Output directory (default: current)
  -v, --verbose      Verbose output
  -h, --help         Show this help
  --version          Show version

Examples:
  $PROG_NAME app.log
  $PROG_NAME -o /tmp app.log
EOF
}

process_file() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        error "File not found: $file"
        return 1
    fi

    $VERBOSE && info "Processing $file"

    # Do the work
    grep "ERROR" "$file" > "$OUTPUT_DIR/errors.log"

    success "Processed $file"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --version)
            echo "$PROG_NAME v$VERSION"
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -*)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
        *)
            # Positional argument
            INPUT_FILE="$1"
            shift
            ;;
    esac
done

# Validate
if [[ -z "${INPUT_FILE:-}" ]]; then
    error "No input file specified"
    usage
    exit 1
fi

# Main execution
process_file "$INPUT_FILE"
```

## Next Steps

Now that you understand utility development:

1. Generate your first utility: `utilz generate myutil`
2. Read the [Architecture](architecture.md) to understand how it works
3. Review existing utilities in `opt/` for examples
4. Write tests for your utility
5. Run `utilz doctor` to validate your setup

For questions or issues, see the [main documentation](index.md).
