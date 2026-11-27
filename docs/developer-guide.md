# Developer Guide

This guide says how to write a Utilz utility.

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

## Quick Start

Once per clone, turn on the tracked commit hooks:

```bash
git config core.hooksPath .githooks
```

`.githooks/pre-commit` checks staged markdown with prettier and staged Rust with rustfmt, and refuses a commit that isn't formatted without rewriting anything. It chains to Intent's gate when `intent claude upgrade` has written `.githooks/pre-commit.intent`. git doesn't carry `core.hooksPath` in a clone, so without this line nothing runs at commit time and CI is the first check (issue 0064).

Create a utility:

```bash
utilz generate logtool "Process and analyze log files" "Your Name"   # names each file it writes
vim opt/logtool/logtool
utilz test logtool
logtool --help
```

## Using the Generator

### Command Syntax

```bash
utilz generate <name> [description] [author]
```

**Arguments:**

- `<name>` (required): a lowercase letter, then lowercase letters, digits and hyphens
- `[description]` (optional): one line on what the utility does, "A new utility" when left out
- `[author]` (optional): git's `user.name` when left out

### What Gets Created

1. `opt/<name>/<name>`: the implementation, a bash script that loads the common library and parses its arguments
2. `opt/<name>/VERSION`: the utility's version, `1.0.0`
3. `opt/<name>/<name>.yaml`: the metadata, which names `VERSION` and the framework version it needs
4. `help/<name>.md`: the page `utilz help <name>` renders
5. `opt/<name>/README.md`: the README
6. `opt/<name>/test/<name>.bats`: a BATS suite that loads the test helper
7. `bin/<name> -> utilz`: the link to the dispatcher

The generator refuses a name of any other form, and a name whose `opt/<name>/` or `bin/<name>` already exists.

## Project Structure

Each utility follows a consistent structure:

```
opt/<utility>/
├── <utility>           # Main implementation (executable)
├── <utility>.yaml      # Metadata file
├── VERSION             # The utility's version
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

The template includes a basic argument parsing loop. Write no `--version` arm: `bin/utilz` answers `--version` for every utility before the utility runs.

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

### Test Rules

1. **Keep the user's state out**: A test writes nothing outside its own temp dirs (issue 0082). The helper's `setup()` points `UNISON` into the test's dir and `GNUPGHOME` at a path that cannot be made. A test that runs gpg calls `make_gpg_home`, and a test that drives `osascript` or a clipboard tool puts a stub first on `PATH` in its own dir. `HOME` stays put.
2. **Test a missing tool's refusal everywhere**: Never skip it because the tool is installed, since every machine that runs the suite has it (issue 0084). `path_without <tool>` prints a dir of links to every command on `PATH` but that one; run only the verb under it, as `run env PATH="$(path_without jq)" ...`, so bats keeps its own `PATH`.

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
