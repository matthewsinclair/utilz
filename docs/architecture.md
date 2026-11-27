# Utilz Architecture

This document explains how the Utilz framework works internally, focusing on the dispatcher pattern, common library integration, and metadata system.

For the reasons behind this design, and its trade-offs, see [Design Principles](design-principles.md).

## Table of Contents

- [Overview](#overview)
- [The Dispatcher Pattern](#the-dispatcher-pattern)
- [UTILZ_HOME Detection](#utilz_home-detection)
- [Common Library Integration](#common-library-integration)
- [Metadata System](#metadata-system)
- [Test Runner Architecture](#test-runner-architecture)

## Overview

Utilz uses a **single dispatcher** pattern where all utilities are symlinks to a master script (`bin/utilz`). When invoked, the dispatcher:

1. Detects which utility was called by examining `$0`
2. Sources the common library (`opt/utilz/lib/common.sh`)
3. Routes execution to the appropriate implementation in `opt/<utility>/<utility>`
4. Uses `exec` to replace itself with the utility, so no dispatcher process waits while it runs

Each implementation is a bash script. A script can call code in another language, eg prez calls its Rust crate in `opt/prez/crate/`.

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
   - Derives `UTILZ_HOME` from `$0`
   - Examines `basename "$0"` → `"mdagg"`
   - Sources common library

4. **Dispatcher validates**:
   - Checks if `opt/mdagg/mdagg` exists
   - Checks if it's executable
   - Calls `predispatch_intercept`, which answers `--help`, `-h` and `--version`

5. **Dispatcher executes**:

   ```bash
   exec "$UTIL_IMPL" "$@"
   ```

   - Uses `exec` to replace the dispatcher process
   - No dispatcher process waits while the utility runs
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

`utilz <utility> [args]` also dispatches to a utility. It calls the same `predispatch_intercept` as Mode 1, so the two forms give the same `--help` and `--version` answers.

### Dispatcher Code Structure

The dispatcher (`bin/utilz`) has two main sections:

**Section 1: Framework Commands**

```bash
if [[ "$INVOKED_AS" == "utilz" ]]; then
    case "$COMMAND" in
        help|doctor|list|test|version|generate|upgrade|integration|emacs)
            # Handle framework commands
            ;;
        install|use|relink)
            # Retired: refer the user to bin/devbin, exit 2
            ;;
        *)
            # Dispatch to a utility, or report an unknown command
            ;;
    esac
fi
```

`utilz help` gives the full list of verbs. Only `upgrade` and `doctor` source the tree library, `opt/utilz/lib/trees.sh`.

**Section 2: Utility Dispatch**

```bash
# At this point, invoked via symlink (eg 'mdagg')
UTIL_NAME="$INVOKED_AS"
UTIL_IMPL="$UTILZ_HOME/opt/$UTIL_NAME/$UTIL_NAME"

# Validate, answer --help/--version, and execute
predispatch_intercept "$UTIL_NAME" "$@"
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
        local link_target
        link_target=$(readlink "$script")
        # Handle relative symlinks
        if [[ "$link_target" != /* ]]; then
            script="$(dirname "$script")/$link_target"
        else
            script="$link_target"
        fi
    done

    # Get directory containing real script
    local script_dir
    script_dir=$(cd "$(dirname "$script")" && pwd) || return 1

    # UTILZ_HOME is parent of bin/
    cd "$script_dir/.." && pwd
}
```

### Why This Matters

This allows flexible installation:

```bash
# Scenario 1: the Homebrew install (the user's)
# brew links $(brew --prefix)/bin/mdagg into the keg's libexec/bin
$ mdagg file.md  # Works - symlink chain followed to find UTILZ_HOME

# Scenario 2: the maintainer's links, made by `bin/devbin use dev` or `use opt`
# ~/.local/bin/mdagg -> ~/Devel/prj/Utilz/bin/mdagg
$ mdagg file.md  # Works - symlink followed to find UTILZ_HOME

# Scenario 3: a dev checkout's bin on PATH
export PATH="$HOME/Devel/prj/Utilz/bin:$PATH"
$ mdagg file.md  # Works - UTILZ_HOME detected
```

An exported `UTILZ_HOME` is ignored: the dispatcher always works its tree out from its own path. The dispatcher then exports `UTILZ_HOME` for the utilities and `common.sh`.

## Common Library Integration

The common library (`opt/utilz/lib/common.sh`) provides shared functions for all utilities.

### Loading Strategy

**In the dispatcher** (`bin/utilz`):

```bash
# Source common functions
if [[ -f "$UTILZ_HOME/opt/utilz/lib/common.sh" ]]; then
    source "$UTILZ_HOME/opt/utilz/lib/common.sh"
else
    echo "ERROR: Cannot find common.sh library" >&2
    exit 1
fi
```

**In each utility** (eg the head of `opt/mdagg/mdagg`):

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

The dispatcher's `exec` runs the utility in a new bash, which has none of the dispatcher's shell functions. So each utility loads the library again on every run. The `type -t info` check skips that load only when a shell that already has the library sources the script, eg stampz's tests. The loader also lets a utility run without the dispatcher, eg `./opt/mdagg/mdagg file.md`.

### Common Library Functions

The library provides these categories of functions:

1. **Logging**: `info()`, `success()`, `warn()`, `error()`, `debug()`
   - All write to stderr (>&2) to avoid polluting utility output
   - `debug()` prints only when `UTILZ_DEBUG=1`

2. **Help System**: `show_help()`, `show_version()`, `predispatch_intercept()`
   - `render_help()` uses glow → bat → cat fallback for markdown rendering
   - Reads from `help/<utility>.md` files, or from a verb's section of `help/utilz.md`

3. **Validation**: `check_command()`, `require_command()`, `require_platform()`
   - Check for external dependencies and for the platform a utility needs
   - Provide helpful error messages

4. **Metadata**: `get_util_metadata()`, `require_yq()`
   - `yq` is the single YAML parser and a hard dependency; `require_yq()` is the gate that stops a caller when `yq` is missing
   - Reads one key, eg `.version` or `.utilz_version`, and resolves a `version_file:` reference where present
   - Returns non-zero when the YAML file or `yq` is missing, rather than an empty string a caller would read as an absent key

5. **Discovery**: `each_utility()`
   - The single walker of `bin/`: emits the name of every symlink in `bin/` whose target is `utilz` or `./utilz`, one per line, from the running tree's `bin/` or from the tree it is given
   - Consume with process substitution (`< <(each_utility)`), never a pipe, so accumulator variables survive the loop

6. **Framework commands**: `list_utilities()`, `run_tests()`, `run_doctor()`, `generate_utility()`
   - `run_doctor()` deliberately does not gate on `require_yq()`: it is the command you run to discover that `yq` is missing

## Metadata System

Each utility has a YAML metadata file at `opt/<utility>/<utility>.yaml`, eg `opt/mdagg/mdagg.yaml`. The [Developer Guide](developer-guide.md#metadata-files) gives its fields.

### Version Resolution

The framework version is in `/VERSION`. `opt/utilz/utilz.yaml` points to it with `version_file: ../../VERSION`.

Each utility also uses `version_file:`, with a path relative to its YAML. Most point to `opt/<utility>/VERSION`. prez points to `crate/Cargo.toml`, which carries the version in `[package]`. An inline `version:` key also works.

A utility declares the framework major version it needs with `utilz_version` (eg `"^2.0.0"`). `utilz doctor` compares that major version with the major version in `/VERSION`.

### Reading Metadata

The framework reads utility metadata through `get_util_metadata()`. It backs `--version`, `utilz list` and doctor's installed utilities check. It is a framework-internal helper, not a utility-facing API; utilities do not call it. Its status is an answer: 0 prints the value, and yq's `null` for a key the yaml lacks; 1 means no yaml, no yq, or a `version_file` the tree does not carry or cannot open; 2 means the yaml cannot be read, and `yaml_read_error` says why:

```bash
# Get utility version
status=0
version=$(get_util_metadata "mdagg" ".version") || status=$?
if [[ $status -eq 2 ]]; then
  error "mdagg.yaml cannot be read: $(yaml_read_error "$(util_yaml_path mdagg)")"
fi

# Get description, and the required framework version, each the same way
description=$(get_util_metadata "mdagg" ".description") || status=$?
utilz_version=$(get_util_metadata "mdagg" ".utilz_version") || status=$?
```

### Integration Manifest

Utilities that want to be auto-exposed to editor bridges (Emacs, and future VSCode / Zed / Vim) declare an `integration:` block in their YAML. The block has three fields:

- `input`: one of `stdin` (pipe region/buffer to the utility), `file` (pass the current buffer's file path), `path` (prompt for a directory), or `none` (run with no input).
- `output`: one of `replace` (replace the region/buffer with stdout), `buffer` (dump stdout into a `*utilz-<name>*` side buffer), `message` (single-line echo), or `discard` (run and report exit status only).
- `flags`: a list of always-pass flags.

The manifest is exposed as TSV via `utilz integration commands`: one row per utility that has an `integration:` block. Format: `name<TAB>description<TAB>input<TAB>output<TAB>flags`. The walker is `emit_integration_tsv` in `opt/utilz/lib/common.sh`, and the integration block's rules live in one function beside it, `integration_fields`, which `emacs_doctor` asks too (Highlander: no editor parses YAML itself; the TSV is the only cross-boundary contract).

Editor-specific installers live alongside the neutral manifest: `utilz emacs install` and `utilz emacs doctor` ship today. Other editor families can add verbs that use the same walker.

The canonical Emacs bridge lives in the repo at `static/emacs/utilz.el`. See the [README Emacs section](../README.md#using-utilz-from-emacs) for installer invocation and usage.

## Test Runner Architecture

The test runner (`run_tests()` in common.sh) runs the framework's tests and the tests of every utility that `each_utility()` names. `utilz test <utility>` runs one utility.

`run_tests()` refuses to run in an install tree, because the suites change `$UTILZ_HOME/bin`.

### Test Sources

For each utility, the runner uses these sources in this order:

1. The release build, when `opt/<utility>/crate/Cargo.toml` exists. A failed build stops the other sources for that utility.
2. The crate's Rust unit tests.
3. Every `*.bats` file under `opt/<utility>/test/`.
4. The crate's black-box suites, found by the glob `opt/<utility>/crate/test/*.sh`. A suite that is not executable fails.

The [Developer Guide](developer-guide.md#writing-tests) says how to write a suite.
