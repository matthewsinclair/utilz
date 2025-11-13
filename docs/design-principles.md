# Design Principles

This document explains the philosophy behind Utilz, what problems it solves, and when to use it.

## Table of Contents

- [Core Philosophy](#core-philosophy)
- [Design Principles](#design-principles)
- [Problems Utilz Solves](#problems-utilz-solves)
- [Target Use Cases](#target-use-cases)
- [When to Use Utilz](#when-to-use-utilz)
- [When NOT to Use Utilz](#when-not-to-use-utilz)
- [Design Decisions](#design-decisions)

## Core Philosophy

**Utilz exists to make personal command-line utilities consistent, portable, and maintainable.**

The framework prioritizes:

1. **Simplicity**: Bash/zsh only, minimal dependencies
2. **Consistency**: All utilities follow the same patterns
3. **Portability**: Clone repo, set PATH, done
4. **Maintainability**: Shared code in common library
5. **Discoverability**: `utilz list` shows what's available

Utilz is NOT trying to be a package manager, distribution system, or general-purpose framework. It's a pattern for organizing personal utilities.

## Design Principles

### 1. Simple Over Feature-Rich

**Principle**: Use bash/zsh and simple patterns over complex abstractions.

**Why**: Bash is available on every Unix-like system. No installation, no version conflicts, no dependency hell.

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

**Principle**: Works the same on macOS, Linux, BSD without modification.

**Why**: Personal utilities should work on all your machines without tweaking.

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
  mdagg v1.0.0 - Markdown aggregator
  logtool v1.0.0 - Process log files
```

### 5. Testable Over Quick-and-Dirty

**Principle**: Built-in testing framework, test helpers, and test runner.

**Why**: Personal utilities grow over time. Tests prevent regressions.

**Example**:

```bash
$ utilz test
✓ All tests passed! (82 total)
```

### 6. Zero Overhead

**Principle**: Use `exec` to replace dispatcher process with utility.

**Why**: No performance penalty for using the framework.

**Example**:

```bash
exec "$UTIL_IMPL" "$@"  # Replace process, don't create subprocess
```

### 7. Self-Contained

**Principle**: Auto-detect installation directory, no environment setup required (except PATH).

**Why**: Works immediately after clone, no configuration needed.

**Example**:

```bash
# Framework finds itself
UTILZ_HOME="$(determine_utilz_home)"
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
├── convert-images
├── cleanup-old-files
└── ... (30+ scripts, different styles, no consistency)
```

**Pain Points**:

- Hard to find utilities
- Different help formats (some have --help, some don't)
- Different error messages
- Code duplication (every script parses args differently)

**With Utilz**:

```
$ utilz list
Available utilities:
  mdagg - Markdown aggregator
  backup - Backup notes to archive
  logtool - Process and analyze logs
  sync - Sync configuration files
  ...
```

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

- Argument parsing
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

- Clone repo: `git clone https://github.com/you/utilz`
- Add to PATH: `export PATH="$UTILZ_HOME/bin:$PATH"`
- Everything works

### Problem 5: No Testing

**Before**:

- No test framework
- Ad-hoc manual testing
- Fear of breaking existing utilities

**After**:

```bash
$ utilz test
Testing: utilz (55 tests)
Testing: mdagg (27 tests)
✓ All tests passed!
```

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

## Target Use Cases

### Use Case 1: Personal Productivity Tools

**Scenario**: You have 20+ small scripts for personal use across multiple machines.

**Solution**: Put them all in Utilz framework for consistency and portability.

**Example Utilities**:

- Backup notes to archive
- Convert image formats
- Process log files
- Sync configuration files
- Generate project scaffolds

### Use Case 2: Multi-Machine Synchronization

**Scenario**: You work on MacBook, Linux desktop, and remote servers. Want same tools everywhere.

**Solution**: Keep Utilz in git, clone to each machine.

**Workflow**:

```bash
# Machine 1: Add new utility
$ utilz generate cleanup "Clean old files"
$ git commit -am "Add cleanup utility"
$ git push

# Machine 2: Get new utility
$ git pull
$ cleanup --help  # Works immediately
```

### Use Case 3: Team-Shared Internal Tools

**Scenario**: Team needs shared utilities for internal workflows.

**Solution**: Team git repository with Utilz utilities.

**Example**:

```bash
# Team repo
git clone https://github.com/company/team-utils
cd team-utils
export UTILZ_HOME="$(pwd)"
export PATH="$UTILZ_HOME/bin:$PATH"

# Everyone has same tools
$ utilz list
deploy-staging
generate-report
check-services
backup-database
```

### Use Case 4: Rapid Prototyping

**Scenario**: Need to create a quick utility to process some files.

**Solution**: Use generator to scaffold, write implementation, test.

**Workflow**:

```bash
$ utilz generate process-csv "Process CSV files"
# 30 seconds later: complete utility scaffold
$ vim opt/process-csv/process-csv
# Write implementation
$ utilz test process-csv
$ process-csv data.csv  # Done!
```

### Use Case 5: Learning Best Practices

**Scenario**: Want to learn bash best practices.

**Solution**: Study Utilz framework and existing utilities.

**Benefits**:

- See proper error handling (`set -euo pipefail`)
- Learn argument parsing patterns
- Understand testing with BATS
- See consistent code organization

## When to Use Utilz

Use Utilz when:

1. **Personal utility collection**: You have multiple personal CLI utilities
2. **Multi-machine use**: You work on multiple machines and want same tools
3. **Team internal tools**: Team needs shared utilities (not public distribution)
4. **Consistency matters**: You want all utilities to work the same way
5. **Portability matters**: Need utilities to work on macOS, Linux, etc.
6. **Testing matters**: You want your utilities to be tested
7. **Quick prototyping**: Need to create new utility quickly

## When NOT to Use Utilz

**Don't use Utilz when**:

### 1. Public Distribution

**Wrong**: Public utilities for end users

```bash
# Don't do this:
brew install myutil  # Points to Utilz framework?
```

**Why Not**: Users shouldn't need entire framework for one utility.

**Instead**: Use proper packaging (Homebrew, npm, cargo, etc.)

### 2. Complex Dependencies

**Wrong**: Utility with 20 npm packages, Python venvs, etc.

**Why Not**: Utilz doesn't manage dependencies beyond checking if commands exist.

**Instead**: Use language-specific package managers (npm, pip, cargo, etc.)

### 3. GUI Applications

**Wrong**: Desktop applications with UI

**Why Not**: Utilz is for command-line utilities only.

**Instead**: Use appropriate GUI framework (Electron, Qt, etc.)

### 4. High Performance Requirements

**Wrong**: Process millions of records per second

**Why Not**: Bash is not optimized for heavy computation.

**Instead**: Use compiled language (Rust, Go, C++) or specialized tools.

### 5. Cross-Platform (Windows Native)

**Wrong**: Need native Windows support (without WSL)

**Why Not**: Requires symlinks, bash/zsh runtime.

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

- Zero overhead (no subprocess)
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
- Common library loaded once
- Consistent --help/--version handling
- Easy to add framework commands

**Trade-off**: Dispatcher must validate routing.

### Why Bash/Zsh?

**Decision**: Framework written in bash/zsh.

**Alternatives Considered**:

- Python
- Ruby
- Node.js

**Why Bash/Zsh**:

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

## Summary

Utilz is designed for **personal and team-internal CLI utilities** that prioritize:

- **Simplicity**: Bash/zsh, minimal dependencies
- **Consistency**: Same structure for all utilities
- **Portability**: Works on all Unix-like systems
- **Discoverability**: Easy to find and use utilities
- **Testability**: Built-in testing framework

It's NOT designed for:

- Public distribution
- Complex dependencies
- GUI applications
- High-performance computing
- Native Windows support

The framework makes trade-offs to optimize for the 80% use case: personal productivity utilities that you use across multiple machines.
