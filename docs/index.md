# Utilz Documentation

**Version**: see `VERSION` at the repo root, or run `utilz version`.

Utilz is a bash framework for building and managing command-line utilities with a single dispatcher pattern. All utilities are symlinks to `bin/utilz`, which routes execution to the appropriate implementation.

## Documentation by Role

### I want to use Utilz

Start here if you want to install and use Utilz utilities:

- **[README](../README.md)** - Installation, quick start, basic usage, and the Emacs bridge.
- **[Framework Help](../help/utilz.md)** - Complete command reference (`utilz help`, `test`, `doctor`, `integration`, `emacs`, etc.).
- **Per-utility help** - Run `utilz help <name>` or see `help/<name>.md` directly. Every shipped utility has its own help file; `utilz list` is the roster.

### I want to integrate Utilz with my editor

- **[README - Using Utilz from Emacs](../README.md#using-utilz-from-emacs)** - Installer invocation, `(load ...)` line, usage table, prefix-arg semantics.
- **[Developer Guide](developer-guide.md)** - The `integration:` YAML block.
- **[Bridge source](../static/emacs/utilz.el)** - The canonical elisp bridge. It reads the `utilz integration commands` TSV.

### I want to create utilities

Start here if you want to build your own utilities with Utilz:

- **[Developer Guide](developer-guide.md)** - Creating utilities, using the generator, testing, `integration:` metadata.
- **[Architecture](architecture.md)** - How the dispatcher pattern works.
- **[Design Principles](design-principles.md)** - Philosophy and when to use Utilz.

### I want to understand the codebase

- **[Architecture](architecture.md)** - Dispatcher pattern, common library, metadata system, integration manifest.
- **[Testing Guide](../opt/utilz/test/README.md)** - Test framework and best practices.
- **[CI/CD Workflows](../.github/workflows/README.md)** - GitHub Actions setup.
- **[Releasing](releasing.md)** - Before a cut, and the Homebrew formula the cut publishes (devbin's formula built-in).

## Quick Reference

### Common Library Functions

The common library (`opt/utilz/lib/common.sh`) provides shared functions for all utilities. The [Developer Guide](developer-guide.md#using-the-common-library) lists them.

## Getting Started

1. Install with Homebrew, as the README's [Installation](../README.md#installation) says (`brew install matthewsinclair/utilz/utilz`, after trusting the formula)
2. Run diagnostics: `utilz doctor`
3. List utilities: `utilz list`
4. Get help: `utilz help`

To create your first utility, see the [Developer Guide](developer-guide.md#quick-start).

## Support

- **Repository**: <https://github.com/matthewsinclair/utilz>
- **Issues**: <https://github.com/matthewsinclair/utilz/issues>
- **Author**: Matthew Sinclair
