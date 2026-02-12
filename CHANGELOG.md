# Changelog

All notable changes to the Utilz framework will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.0] - 2026-02-12

### Added

- **pdf2md** - New PDF to Markdown converter utility
  - Converts PDF files to clean markdown using pdfplumber
  - 7-stage pipeline: text extraction, stats, line grouping, heading detection, list detection, header/footer removal, markdown emission
  - Heading detection via font size analysis (H1-H6 by descending unique sizes)
  - List item detection (bullets, dashes, numbered, lettered, parenthesized)
  - Repetitive header/footer removal (same text+Y on >50% of pages)
  - Page range selection (`--pages 1-5,7,10-12`)
  - File output (`-o output.md`) or stdout
  - Verbose mode with progress to stderr
  - Python venv auto-management at `lib/.venv/`
  - 15 comprehensive tests
- **xtrct** - New schema-driven semantic data extraction utility
  - Uses Claude API to extract structured data from documents via JSON schema
  - Descriptive schema format: `description` fields guide semantic extraction
  - PDF input auto-converts via pdf2md
  - Stdin support for piping
  - Output formats: json (pretty-print), csv, table (aligned columns)
  - Model selection (`--model`) with default claude-haiku-4-5-20251001
  - Verbose mode with token usage stats
  - `ANTHROPIC_API_KEY` fail-fast check before venv creation
  - Python venv auto-management at `lib/.venv/`
  - 12 tests (8 tier-1 always run, 4 tier-2 require API key)
- Composable pipeline: `pdf2md invoice.pdf | xtrct --schema invoice_schema.json`
- Python venv pattern for utilities with Python dependencies
- python3-venv added to CI Ubuntu dependencies

### Changed

- Framework version bumped to 1.3.0

## [1.2.1] - 2026-02-10

### Added

- **syncz** - Bidirectional sync mode (`--bidi`)
  - Two-way sync with automatic orphan detection using `find` + `comm`
  - Orphan resolution: interactive prompts, `--delete` (silent), `--confirm yes/no/all` (scriptable)
  - Two-pass rsync (dir1→dir2, dir2→dir1) with newer-wins strategy
  - rsync `--delete` never passed in bidi mode (orphan resolution handles deletions)
  - `--source-wins` and `--dest-wins` blocked in bidi mode
- **syncz** - `--confirm` optional argument (`yes`, `no`, `all`)
  - Auto-answers all prompts for fully scriptable operation
  - Works in both unidirectional and bidirectional modes
  - Peek-ahead parsing preserves positional argument compatibility

### Fixed

- syncz: empty orphan arrays caused silent exit on bash 3.2 (`set -e` + `&&` short-circuit)
- syncz: `--confirm yes --delete` now correctly deletes (macOS rsync missing delete count in stats)

### Changed

- syncz version bumped to 1.3.0
- Framework version bumped to 1.2.1

## [1.2.0] - 2026-02-08

### Added

- **syncz** - New directory-to-directory syncer utility wrapping rsync
  - Three conflict resolution strategies: newer-wins (default), source-wins, dest-wins
  - Confirmation modes: `--confirm` (Y/N/A per-step), `--force` (no prompts), `--just-do-it` (single Y/N)
  - `--delete` with safety gate (requires `--confirm`, `--force`, or `--just-do-it`)
  - `--backup` creates `.syncz-bak` copies of overwritten files
  - `--exclude` pattern support (repeatable)
  - `--dry-run` with summary and itemized change listing
  - `--verbose` and `--progress` modes
  - Uses `-rlptD` instead of `-a` to avoid group/owner warnings for non-root syncs
  - Trailing slash normalization for predictable behavior
  - 45 comprehensive tests
- rsync dependency check in `utilz doctor`
- syncz added to Linux CI test loop

### Changed

- Framework version bumped to 1.2.0

## [1.1.0] - 2025-12-28

### Added

- **cleanz** - New LLM text cleaner utility that removes hidden characters and formatting artifacts from text copied from ChatGPT, Claude, Gemini, and other LLM interfaces
  - Removes zero-width characters (ZWSP, ZWNJ, ZWJ, word joiners)
  - Removes byte order marks (BOM) and soft hyphens
  - Removes directional formatting characters (LTR/RTL embedding, override)
  - Converts non-breaking spaces and hair spaces to regular spaces
  - Removes control characters (preserving newlines, tabs, carriage returns)
  - Strips HTML `data-*` attributes commonly injected by LLM UIs
  - Normalizes whitespace (multiple spaces, blank lines, trailing whitespace)
  - Optional smart quote to straight quote conversion (`--normalize-quotes`)
  - Detection mode (`--detect`) to show hidden characters without cleaning
  - Verbose mode (`--verbose`) to show cleaning summary
  - Full I/O support: files, stdin, stdout, clipboard (`--clipboard`), in-place editing (`--in-place`)
  - 46 comprehensive tests

### Changed

- Framework version bumped to 1.1.0

## [1.0.0] - 2025-11-12

### Added

- Initial release of Utilz framework
- Dispatcher-based architecture with single `bin/utilz` entry point
- Common functions library (`opt/utilz/lib/common.sh`)
- Built-in utility generator (`utilz generate`)
- Built-in test runner (`utilz test`)
- Built-in diagnostics (`utilz doctor`)
- **clipz** - Cross-platform clipboard utility (macOS, Linux X11, Wayland)
- **cryptz** - GPG encryption/decryption wrapper
- **gitz** - Git multi-repository status checker
- **macoz** - macOS utilities (desktop backgrounds, folder icons)
- **mdagg** - Markdown file aggregator
- **retry** - Retry command until success
- GitHub Actions CI/CD with tests on Ubuntu and macOS
- Comprehensive test suites using BATS
