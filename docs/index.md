# Utilz Documentation

**Version**: 2.2.0

Utilz is a bash/zsh framework for building and managing command-line utilities with a single dispatcher pattern. All utilities are symlinks to `bin/utilz`, which routes execution to the appropriate implementation.

## Documentation by Role

### I want to use Utilz

Start here if you want to install and use Utilz utilities:

- **[README](../README.md)** - Installation, quick start, basic usage, and the Emacs bridge.
- **[Framework Help](../help/utilz.md)** - Complete command reference (`utilz help`, `test`, `doctor`, `integration`, `emacs`, etc.).
- **Per-utility help** - Run `utilz help <name>` or see `help/<name>.md` directly. All 12 shipped utilities have their own help files: `cleanz`, `clipz`, `cryptz`, `expz`, `gitz`, `lnrel`, `macoz`, `mdagg`, `pdf2md`, `retry`, `syncz`, `xtrct`.

### I want to integrate Utilz with my editor

- **[README - Using Utilz from Emacs](../README.md#using-utilz-from-emacs)** - Installer invocation, `(load ...)` line, usage table, prefix-arg semantics.
- **[ST0007 Design](../intent/st/ST0007/design.md)** - Editor-neutral `integration:` YAML block, `utilz integration commands` TSV surface, PFIC/Thin-Coordinator shape of the bridge.
- **[Bridge source](../static/emacs/utilz.el)** - The canonical elisp bridge (~270 lines).

Future integration targets (VSCode, Zed, Vim) slot in as parallel `utilz <editor>` subcommand families that consume the same `utilz integration commands` TSV - no per-editor YAML walker.

### I want to create utilities

Start here if you want to build your own utilities with Utilz:

- **[Developer Guide](developer-guide.md)** - Creating utilities, using the generator, testing, `integration:` metadata.
- **[Architecture](architecture.md)** - How the dispatcher pattern works.
- **[Design Principles](design-principles.md)** - Philosophy and when to use Utilz.

### I want to understand the codebase

- **[Architecture](architecture.md)** - Dispatcher pattern, common library, metadata system, integration manifest.
- **[Testing Guide](../opt/utilz/test/README.md)** - Test framework and best practices.
- **[CI/CD Workflows](../.github/workflows/README.md)** - GitHub Actions setup.

## Quick Reference

### Framework Commands

```bash
utilz help [utility]          # Show help documentation
utilz list                    # List available utilities
utilz version                 # Show framework version
utilz doctor                  # Run system diagnostics
utilz test [utility]          # Run test suite
utilz generate <name>         # Create new utility scaffold
utilz integration commands    # Emit the editor-neutral TSV manifest
utilz emacs install [args]    # Install the Emacs elisp bridge
utilz emacs doctor            # Health-check the Emacs bridge surface
```

### File Structure

```
Utilz/
├── bin/utilz           # Dispatcher (all utilities symlink here)
├── opt/                # Utility implementations
│   ├── utilz/         # Framework core
│   │   ├── lib/common.sh   # Shared functions
│   │   ├── test/           # Framework tests
│   │   └── tmpl/           # Generator templates
│   └── <utility>/     # Individual utility directories
├── help/               # Help documentation
└── docs/               # Architecture and guides
```

### Common Library Functions

The common library (`opt/utilz/lib/common.sh`) provides shared functions for all utilities:

- **Logging**: `info()`, `success()`, `warn()`, `error()`, `debug()`
- **Help**: `show_help()`, `show_version()`
- **Validation**: `check_command()`, `require_command()`
- **Metadata**: `get_util_metadata()`
- **Testing**: `run_tests()`, `run_doctor()`

See [Framework Help](../help/utilz.md) for complete function documentation.

## What Problems Does Utilz Solve?

- **Utility sprawl**: Multiple personal scripts scattered across systems
- **Inconsistent UX**: Different help formats, error handling
- **Code duplication**: Every script reimplements common functions
- **Portability**: Easy to clone to new machine (single `UTILZ_HOME`)
- **Discoverability**: `utilz list` shows all available utilities
- **Testing**: Built-in test framework vs ad-hoc testing

## Getting Started

1. Clone the repository
2. Set environment variables:

   ```bash
   export UTILZ_HOME="$HOME/Devel/prj/Utilz"
   export PATH="$UTILZ_HOME/bin:$PATH"
   ```

3. Run diagnostics: `utilz doctor`
4. List utilities: `utilz list`
5. Get help: `utilz help`

For detailed installation instructions, see the [README](../README.md).

## Creating Your First Utility

```bash
# Generate scaffold
utilz generate myutil "Does something useful" "Your Name"

# Edit implementation
vim opt/myutil/myutil

# Test it
utilz test myutil

# Use it
myutil --help
```

See [Developer Guide](developer-guide.md) for comprehensive utility creation documentation.

## Support

- **Repository**: <https://github.com/matthewsinclair/utilz>
- **Issues**: <https://github.com/matthewsinclair/utilz/issues>
- **Author**: Matthew Sinclair
