---
verblock: "12 Nov 2025:v0.1: Matthew Sinclair - Initial version"
---

# Utilz

[![Utilz Tests](https://github.com/matthewsinclair/utilz/actions/workflows/tests.yml/badge.svg)](https://github.com/matthewsinclair/utilz/actions/workflows/tests.yml)

A bash/zsh framework for building and managing command-line utilities with a single dispatcher.

## What is this?

Utilz is a dispatcher-based framework where all utilities are symlinks to a single `bin/utilz` script. When you run a utility, the dispatcher figures out what was called and routes to the appropriate implementation.

This means:

- One codebase for common functionality (help, version, error handling)
- Each utility gets its own directory with implementation and tests
- Consistent CLI experience across all utilities
- Built-in testing with BATS

## Structure

```
Utilz/
├── VERSION                    # Framework version (single source of truth)
├── bin/
│   ├── utilz                 # Dispatcher script
│   └── mdagg -> utilz        # Utility symlinks
├── opt/
│   ├── utilz/
│   │   ├── lib/
│   │   │   └── common.sh    # Shared functions
│   │   ├── test/            # Framework tests
│   │   └── utilz.yaml       # Framework metadata
│   └── mdagg/
│       ├── mdagg            # Implementation
│       ├── mdagg.yaml       # Utility metadata
│       ├── test/            # Utility tests
│       └── README.md        # Utility docs
└── help/
    ├── utilz.md             # Framework help
    └── mdagg.md             # Utility help
```

## Installation

```bash
# Clone the repo
git clone https://github.com/matthewsinclair/utilz.git ~/Devel/prj/Utilz

# Set up environment
export UTILZ_HOME="$HOME/Devel/prj/Utilz"
export PATH="$UTILZ_HOME/bin:$PATH"

# Add to your shell config (~/.zshrc or ~/.bashrc)
echo 'export UTILZ_HOME="$HOME/Devel/prj/Utilz"' >> ~/.zshrc
echo 'export PATH="$UTILZ_HOME/bin:$PATH"' >> ~/.zshrc

# Check installation
utilz doctor
```

## Usage

### Framework Commands

```bash
utilz help                    # Show framework help
utilz help <utility>          # Show utility-specific help
utilz list                    # List installed utilities
utilz version                 # Show framework version
utilz doctor                  # Run diagnostics
utilz test                    # Run all tests
utilz test <utility>          # Run tests for specific utility
utilz generate <name> [desc]  # Generate new utility scaffold
```

### Calling Utilities

You can call utilities in two ways:

```bash
# Direct (via symlink)
mdagg --help
mdagg config.yaml -o output.md

# Via dispatcher
utilz mdagg --help
utilz mdagg config.yaml -o output.md
```

Both methods work identically.

## Included Utilities

### mdagg

Markdown aggregator for concatenating multiple markdown files into a single document. Useful for assembling multi-file documents into PDFs.

```bash
# Using YAML config
mdagg assembly.yaml -o output.md

# Using glob pattern
mdagg "chapter-*.md" -d -b -o book.md

# From stdin
find docs -name "*.md" | sort | mdagg --stdin -o docs.md
```

See `utilz help mdagg` for details.

## Creating a New Utility

Use the built-in generator to scaffold a new utility:

```bash
# Generate a new utility
utilz generate myutil "My new utility description"

# Or with author name
utilz generate myutil "Does something useful" "Your Name"
```

This creates:

- `opt/myutil/myutil` - Executable implementation with boilerplate
- `opt/myutil/myutil.yaml` - Metadata (version, description, dependencies)
- `opt/myutil/README.md` - Documentation
- `opt/myutil/test/myutil.bats` - Test suite with basic tests
- `help/myutil.md` - Help documentation
- `bin/myutil` - Symlink to dispatcher

Then customize the implementation:

```bash
# Edit the implementation
vim opt/myutil/myutil

# Test it
utilz myutil --help
utilz myutil

# Run tests
utilz test myutil

# Check everything is working
utilz doctor
utilz list
```

## Testing

Tests use [BATS](https://github.com/bats-core/bats-core) (Bash Automated Testing System).

```bash
# Install BATS
brew install bats-core

# Run all tests
utilz test

# Run specific utility tests
utilz test mdagg

# Run tests directly
cd opt/mdagg/test
bats mdagg.bats
```

Test files go in `opt/<utility>/test/*.bats`. See `opt/mdagg/test/mdagg.bats` for examples.

## Common Functions

All utilities have access to functions from `opt/utilz/lib/common.sh`:

- `info()` - Info message (blue)
- `success()` - Success message (green)
- `warn()` - Warning message (yellow)
- `error()` - Error message (red)
- `show_help()` - Display help file
- `show_version()` - Display version
- `check_command()` - Check if command exists
- `require_command()` - Require command or show error
- `get_util_metadata()` - Read utility YAML metadata

## Version Management

The framework version is stored in `/VERSION`. Utility metadata files (`*.yaml`) can either:

1. Reference the framework version:

```yaml
version_file: ../../VERSION
```

2. Specify their own version:

```yaml
version: 1.0.0
utilz_version: "^1.0.0"  # Compatible framework versions
```

## Requirements

- Bash 4.0+ or Zsh
- `yq` for YAML parsing (install: `brew install yq`)
- `bats-core` for testing (install: `brew install bats-core`)

## License

Personal use.
Copyright (c) 2025 Matthew Sinclair

## Author

Matthew Sinclair
[matthewsinclair.com](https://matthewsinclair.com)
