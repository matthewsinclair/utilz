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

Once per clone, turn on the tracked commit hooks:

```bash
git config core.hooksPath .githooks
```

`.githooks/pre-commit` checks staged markdown with prettier and staged Rust with rustfmt, and refuses a commit that isn't formatted without rewriting anything. It chains to Intent's gate when `intent claude upgrade` has written `.githooks/pre-commit.intent`. git doesn't carry `core.hooksPath` in a clone, so without this line nothing runs at commit time and CI is the first check (issue 0064).

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
version_file: VERSION
utilz_version: "^2.0.0"
description: Process and analyze log files
author: Your Name
dependencies: []
```

`utilz generate` writes these fields. The help page is always `help/<name>.md`, found by name.

### Required Fields

- `name`: Utility name (must match directory and file name)
- `version_file`: The file that holds the version, relative to the yaml. `utilz generate` writes `VERSION` beside it. A yaml's inline `version`, where it has one, is read first.
- `utilz_version`: Compatible framework version (caret notation)
- `description`: One-line description
- `author`: Author name

### Optional Fields

**Editor Integration Block**:

Utilities that should be auto-exposed to editor bridges (Emacs today; VSCode / Zed / Vim in future) declare an `integration:` block. The block is optional: without it, the utility is not in the integration manifest.

```yaml
integration:
  input: stdin # stdin | file | path | none
  output: buffer # replace | buffer | message | discard
  flags: [] # always-pass flags (rare)
  prompts: [] # optional flag suggestions for the C-u prompt
```

Pick `input` by what the utility reads:

- `stdin`: reads from stdin (Emacs pipes the active region or whole buffer via `shell-command-on-region`).
- `file`: needs a real file path (Emacs uses the current buffer's `buffer-file-name`, or prompts).
- `path`: needs a directory (Emacs prompts for a directory, defaulting to `default-directory`).
- `none`: takes no input (eg clipboard operators, system actions).

Pick `output` by what the user wants to see:

- `replace`: replaces the region/buffer with stdout (one `undo-boundary`, single `C-/` reverts).
- `buffer`: dumps stdout into a `*utilz-<name>*` side buffer.
- `message`: echoes stdout as a single-line minibuffer message.
- `discard`: runs and reports exit status only.

Once an `integration:` block is declared, `utilz integration commands` surfaces the utility in the TSV manifest, and `M-x utilz` in Emacs picks it up without any code changes. See [docs/architecture.md - Integration Manifest](architecture.md#integration-manifest) for the cross-boundary contract.

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

Each entry is a map with a `name`. `utilz doctor` refuses one that is not, such as `- jq` written as a bare string, by name, and counts it as an issue (issue 0085).

### Platforms

Utilz runs on macOS and Linux (issue 0083). A utility that runs on one alone says so at its top level, and a dependency needed on one alone says so in its entry:

```yaml
platforms: [macos]

dependencies:
  - name: xclip
    platforms: [linux]
    required: false
    install: sudo apt install xclip
    purpose: The X11 clipboard
```

`platforms` is a list of `macos` and `linux`; absent means everywhere, and an entry carrying `app:` is a macOS app, whatever its `platforms` say. Where a utility's platforms leave this one out, `utilz list` marks it `(macOS only)` and `utilz doctor` says it is not available here and skips its dependencies; a dependency left out is one line, with no install line. Neither counts as an issue. A `platforms` that is not such a list is one.

In the utility, ask common.sh rather than `uname`: `utilz_platform` answers `macos`, `linux` or `other`; `require_platform <util>` refuses, exit 2, where the yaml's platforms leave this one out; and `refuse_off_macos "<what>" "<needs>" ["<works here>"]` refuses one verb off macOS, as `<what> needs <needs>, so it is not available on Linux`. Call either after the help arms, so `--help` answers everywhere. In a test, `stub_platform Linux` (or `Darwin`) puts a `uname` first on PATH, so both platforms are tested on either.

### Complete Example

```yaml
name: logtool
version_file: VERSION
utilz_version: "^2.0.0"
description: Process and analyze log files
author: Jane Developer

dependencies:
  - name: jq
    required: true
    install: brew install jq
    purpose: JSON parsing

optional_dependencies:
  - name: bat
    install: brew install bat
    purpose: Colorized output

# Exposed to editor bridges via `utilz integration commands'. logtool
# accepts a log file path and writes its analysis to stdout; the Emacs
# bridge runs it and shows the result in a *utilz-logtool* side buffer.
integration:
  input: file
  output: buffer
  flags: []
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

The colour variables `$BOLD`, `$RED`, `$GREEN`, `$YELLOW`, `$BLUE` and `$RESET` are set when stdout is a terminal, and are empty when it is not.

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

`get_util_metadata`'s status is an answer (issue 0081): 1 means no yaml or no yq, and 2 means the yaml cannot be read, which `yaml_read_error` names. Take the status rather than masking it:

```bash
# Get utility version
status=0
version=$(get_util_metadata "logtool" ".version") || status=$?
if [[ $status -eq 2 ]]; then
  error "logtool.yaml cannot be read: $(yaml_read_error "$(util_yaml_path logtool)")"
fi

# Get description
description=$(get_util_metadata "logtool" ".description") || status=$?

# Get framework requirement
utilz_version=$(get_util_metadata "logtool" ".utilz_version") || status=$?
```

`require_yq` is the gate for yq, the one YAML parser. A caller that loops over utilities calls it once, before the loop. `parse_yaml "<file>" "<query>"` runs one yq query on any yaml file, after the same gate.

### Framework Functions

```bash
# List all utilities
list_utilities

# Run doctor checks
run_doctor

# Run tests
run_tests "logtool"  # Specific utility
run_tests            # All utilities

# Every utility of a tree, the running one unless named, one name per line
while IFS= read -r name; do echo "$name"; done < <(each_utility)
```

Read `each_utility` through process substitution, as above, and not through a pipe, so the loop's variables live after it.

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
7. **Keep the user's state out**: A test writes nothing outside its own temp dirs (issue 0082). The helper's `setup()` points `UNISON` into the test's dir and `GNUPGHOME` at a path that cannot be made. A test that runs gpg calls `make_gpg_home`, and a test that drives `osascript` or a clipboard tool puts a stub first on `PATH` in its own dir. `HOME` stays put.
8. **Test a missing tool's refusal everywhere**: Never skip it because the tool is installed, since every machine that runs the suite has it (issue 0084). `path_without <tool>` prints a dir of links to every command on `PATH` but that one; run only the verb under it, as `run env PATH="$(path_without jq)" ...`, so bats keeps its own `PATH`.

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
  local farm
  farm=$(path_without jq)
  echo "INFO: test" > test.log
  run env PATH="$farm" "$UTILZ_BIN_DIR/logtool" --json test.log
  assert_failure
  assert_output_contains "jq is required"
}
```

## Multi-Language Utilities

The dispatcher runs `opt/<name>/<name>`, which is always a bash script. A utility in another language keeps that script as a shim and puts the tool beside it. Write new code in bash or zsh, or in Rust. Ship no Python.

- **Rust**: prez is the model. `opt/prez/prez` is a shim that builds the crate under `opt/prez/crate/` when it is missing or stale, then runs it. Its header says why the binary is built on each machine and not committed. Build it through `bin/devbin build`.
- **Lua**: arngz is the model. `opt/arngz/arngz` is the shim, and its engine is in `opt/arngz/lib/`.

Declare each runtime the utility needs under `dependencies:` in its metadata, as [Dependencies](#dependencies) says.

## Version Management

### Utility Versioning

Each utility keeps its version in one file, which its yaml names. `utilz generate` writes `VERSION` beside the yaml:

```yaml
version_file: VERSION
```

### Framework Compatibility

Declare compatible framework version with caret notation:

```yaml
utilz_version: "^2.0.0" # Compatible with 2.x.x
```

The major version must match: `^2.0.0` accepts 2.x.x and refuses 1.x.x.

### Checking Compatibility

The `utilz doctor` command checks version compatibility:

```bash
$ utilz doctor
Checking installed utilities...
⚠ Version incompatibilities detected:
    - logtool (requires Utilz ^3.0.0, have 2.15.0)
```

### Updating Versions

A utility ships in a Utilz release. It has no tag of its own.

1. Bump `version:` in its YAML, or the file its `version_file:` names (eg `opt/arngz/VERSION`, prez's `crate/Cargo.toml`).
2. Add a line to the CHANGELOG's open section, `## [X.Y.Z] - unreleased`, that names the change and the version step, eg "arngz goes from 1.2.0 to 1.2.1".
3. Commit it. hv's cut tags the release, bare, with no `v` ([releasing.md](releasing.md)).

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
        # No --version arm: bin/utilz answers --version for every utility
        # before the utility runs, from the version's one home.
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
