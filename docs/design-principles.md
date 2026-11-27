# Design Principles

This document explains the philosophy behind Utilz, what problems it solves, and when to use it. [Architecture](architecture.md) explains how it works.

## Table of Contents

- [Core Philosophy](#core-philosophy)
- [Design Principles](#design-principles)
- [Problems Utilz Solves](#problems-utilz-solves)
- [When to Use Utilz](#when-to-use-utilz)
- [When NOT to Use Utilz](#when-not-to-use-utilz)
- [Design Decisions](#design-decisions)

## Core Philosophy

**Utilz exists to make personal command-line utilities consistent, portable, and maintainable.**

The framework prioritizes:

1. **Simplicity**: A bash dispatcher and bash entry points, minimal dependencies
2. **Consistency**: All utilities follow the same patterns
3. **Portability**: One Homebrew install per machine
4. **Maintainability**: Shared code in common library
5. **Discoverability**: `utilz list` shows what's available

Utilz is NOT trying to be a package manager, distribution system, or general-purpose framework. It's a pattern for organizing personal utilities.

## Design Principles

### 1. Simple Over Feature-Rich

**Principle**: Use bash and simple patterns over complex abstractions.

**Why**: Bash is available on every Unix-like system. No installation, no version conflicts, no dependency hell.

A utility's entry point is always a bash script. The script can call code in another language when the task needs it, eg prez calls a Rust crate and arngz loads Lua into Hammerspoon.

**Example**:

```bash
# Simple: Direct execution with exec
exec "$UTIL_IMPL" "$@"

# Not: Complex plugin system, hooks, middleware
```

### 2. Consistent Over Flexible

**Principle**: All utilities follow the same structure and conventions.

**Why**: Reduces cognitive load. Once you understand one utility, you understand them all.

**Example**:

```
opt/<utility>/<utility>      # Always: Implementation
opt/<utility>/<utility>.yaml # Always: Metadata
help/<utility>.md            # Always: Help docs
```

### 3. Portable Over Optimized

**Principle**: Works the same on macOS and Linux without modification.

**Why**: Personal utilities should work on all your machines without tweaking.

A utility that needs macOS declares it, and refuses by name on another platform. The [README](../README.md) lists which utilities need macOS.

**Example**:

```bash
# Portable: Use standard tools
grep "pattern" file.txt

# Not portable: Use GNU-specific flags
grep --perl-regexp "pattern" file.txt
```

### 4. Discoverable Over Hidden

**Principle**: Make it easy to find utilities and understand what they do.

**Why**: Personal utilities are useless if you forget they exist.

**Example**:

```bash
$ utilz list
Available utilities:

  mdagg           Markdown aggregator for concatenating multiple markdown files into a single document
  ...
```

### 5. Testable Over Quick-and-Dirty

**Principle**: Built-in testing framework, test helpers, and test runner.

**Why**: Personal utilities grow over time. Tests prevent regressions.

**Example**:

```bash
utilz test          # every suite, in a dev checkout
utilz test mdagg    # one utility
```

### 6. One Process

**Principle**: Use `exec` to replace dispatcher process with utility.

**Why**: No dispatcher process waits while the utility runs.

**Example**:

```bash
exec "$UTIL_IMPL" "$@"  # Replace process, don't create subprocess
```

### 7. Self-Contained

**Principle**: Auto-detect installation directory, no environment setup required (except PATH).

**Why**: Works from any tree, with no configuration.

**Example**:

```bash
# Framework finds itself
UTILZ_HOME=$(determine_utilz_home)
```

## Problems Utilz Solves

### Problem 1: Utility Sprawl

**Before Utilz**:

```
~/bin/
├── aggregate-markdown.sh
├── backup-notes
├── process-logs.py
├── sync-config
└── ... (30+ scripts, different styles, no consistency)
```

**Pain Points**:

- Hard to find utilities
- Different help formats (some have --help, some don't)
- Different error messages
- Code duplication

**With Utilz**: one dispatcher, one layout, and `utilz list` names every utility.

### Problem 2: Inconsistent UX

**Before**:

```bash
script1 --help        # Shows help
script2 --help        # Error: unknown option
script3 -h            # Shows help
script4 help          # Shows help
script5               # No help available
```

**After**:

```bash
utilz help script1    # Always works
script1 --help        # Always works
script1 -h            # Always works
```

### Problem 3: Code Duplication

**Before**: Every script reimplements:

- Error handling
- Logging
- Color output
- Help formatting
- Dependency checking

**After**: Common library provides all of this:

```bash
info "Processing file"      # Consistent logging
error "File not found"      # Consistent errors
require_command "jq"        # Consistent dependency checks
show_help "myutil"          # Consistent help display
```

### Problem 4: Poor Portability

**Before**:

- Scripts hard-code paths: `~/bin/script.sh`
- Scripts depend on specific machine setup
- Moving to new machine requires editing scripts

**After**:

- Install once per machine with Homebrew, as the README's Installation says
- Every utility is on PATH, with no environment variable to set
- Everything works

### Problem 5: No Testing

**Before**: no test framework, ad-hoc manual testing, and fear of breaking existing utilities.

**After**: every utility has a suite under `opt/<utility>/test/`, and `utilz test` runs them all.

### Problem 6: Poor Discoverability

**Before**:

- What scripts do I have?
- What does this script do?
- How do I use it?

**After**:

```bash
utilz list                # What do I have?
utilz help mdagg          # How does it work?
utilz doctor              # Is everything working?
```

## When to Use Utilz

Use Utilz when:

1. **Personal utility collection**: You have multiple personal CLI utilities
2. **Multi-machine use**: You work on multiple machines and want same tools
3. **Team internal tools**: Team needs shared utilities (not public distribution)
4. **Consistency matters**: You want all utilities to work the same way
5. **Portability matters**: Need utilities to work on macOS and Linux
6. **Testing matters**: You want your utilities to be tested
7. **Quick prototyping**: Need to create new utility quickly (`utilz generate` makes the scaffold)

## When NOT to Use Utilz

**Don't use Utilz when**:

### 1. Public Distribution

**Wrong**: One utility published for end users on its own

```bash
# Don't do this:
brew install myutil  # one utility, carrying the whole framework with it
```

**Why Not**: Users shouldn't need the entire framework for one utility. Utilz itself ships as one Homebrew formula, the framework and every utility together.

**Instead**: Give a utility meant for the public on its own its own package (Homebrew, npm, cargo, etc.)

### 2. Complex Dependencies

**Wrong**: Utility with 20 npm packages, Python venvs, etc.

**Why Not**: Utilz checks that commands and macOS apps exist. Beyond that, it gives only `ensure_venv` for a utility that needs a Python venv.

**Instead**: Use language-specific package managers (npm, pip, cargo, etc.)

### 3. GUI Applications

**Wrong**: Desktop applications with UI

**Why Not**: Utilz is for command-line utilities. A utility can install and launch a small companion app, as menuz does, but the utility stays the command-line entry point.

**Instead**: Use appropriate GUI framework (Electron, Qt, etc.)

### 4. High Performance Requirements

**Wrong**: Process millions of records per second

**Why Not**: Bash is not optimized for heavy computation.

**Instead**: Use compiled language (Rust, Go, C++) or specialized tools. A utility's bash entry point can call compiled code, as prez does.

### 5. Cross-Platform (Windows Native)

**Wrong**: Need native Windows support (without WSL)

**Why Not**: Requires symlinks and a bash runtime.

**Instead**: Use PowerShell, or language with native Windows support.

### 6. Versioned Distribution

**Wrong**: Different teams need different versions of same utility

**Why Not**: Utilz doesn't support multiple versions of same utility.

**Instead**: Use proper package manager with version resolution.

### 7. Single One-Off Script

**Wrong**: One script you'll never touch again

**Why Not**: Overhead of framework structure not worth it.

**Instead**: Just write a standalone script.

## Design Decisions

### Why Symlinks?

**Decision**: All utilities are symlinks to dispatcher.

**Alternatives Considered**:

- Individual wrapper scripts
- Shell aliases
- Shell functions

**Why Symlinks**:

- Simple routing via `$0` inspection
- Standard Unix pattern
- Easy to add/remove utilities

**Trade-off**: Requires filesystem with symlink support.

### Why Single Dispatcher?

**Decision**: One dispatcher script for all utilities.

**Alternatives Considered**:

- Generate individual scripts per utility
- No dispatcher (standalone utilities)

**Why Single Dispatcher**:

- Single point of control
- Consistent --help/--version handling
- Easy to add framework commands

**Trade-off**: Dispatcher must validate routing.

### Why Bash?

**Decision**: Framework written in bash.

**Alternatives Considered**:

- Python
- Ruby
- Node.js

**Why Bash**:

- Available on every Unix-like system
- No installation required
- Perfect for CLI utilities
- Direct OS integration

**Trade-off**: Less powerful than Python/Ruby for complex logic.

### Why BATS for Testing?

**Decision**: Use BATS (Bash Automated Testing System).

**Alternatives Considered**:

- Shell script tests
- Python unittest
- Custom test framework

**Why BATS**:

- Native bash testing
- TAP output format
- Test isolation
- Good assertions

**Trade-off**: Requires BATS installation.

### Why YAML Metadata?

**Decision**: Use YAML files for utility metadata.

**Alternatives Considered**:

- JSON
- TOML
- Bash files with variables

**Why YAML**:

- Human-readable
- Standard format
- Comments supported
- Good tool support (`yq`)

**Trade-off**: Requires `yq` for parsing.

### Why Generator Command?

**Decision**: Provide `utilz generate` to scaffold utilities.

**Alternatives Considered**:

- Manual creation
- Copy existing utility as template
- External tool

**Why Generator**:

- Consistent structure
- Saves time
- Reduces errors
- Includes all boilerplate

**Trade-off**: Adds complexity to framework.

### Why No Plugin System?

**Decision**: No plugin/hook system for extending dispatcher.

**Alternatives Considered**:

- Pre/post hooks
- Plugin system
- Middleware pattern

**Why No Plugins**:

- Keeps framework simple
- Utilities don't need to extend dispatcher
- Common library provides extensibility

**Trade-off**: Can't customize dispatcher behavior per utility.
