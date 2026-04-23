# Changelog

All notable changes to the Utilz framework will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.2.0] - 2026-04-23

### Added

- **Editor integration manifest** - new `integration:` YAML block declares each utility's input kind (`stdin`/`file`/`path`/`none`) and output kind (`replace`/`buffer`/`message`/`discard`). Optional; absence means the utility is not auto-exposed to editor bridges. All 12 current utilities now carry an `integration:` block.
- **`utilz integration commands`** - editor-neutral TSV manifest surface. Emits one row per utility with an `integration:` block: `name<TAB>description<TAB>input<TAB>output<TAB>flags`. The TSV is the single cross-boundary contract - any editor integration (Emacs, future VSCode / Zed / Vim) consumes it without parsing YAML directly. The walker (`emit_integration_tsv` in `opt/utilz/lib/common.sh`) is the only place that walks the YAML corpus to produce the integration catalogue (Highlander).
- **`utilz emacs install`** - installs the canonical elisp bridge (`static/emacs/utilz.el`) to a destination path. `--symlink` creates a symlink (preferred - `git pull` in Utilz rolls the bridge forward); omitting it copies. `--force` overwrites a differing destination. Prints the `(load ...)` line for the user to paste into `config.el`. Never edits the user's Emacs config.
- **`utilz emacs doctor`** - health check: verifies `utilz` is on the PATH Emacs will see, every installed utility has a valid `integration:` block (flags missing / invalid `input` / `output` values), and the canonical elisp is present.
- **Emacs bridge (`static/emacs/utilz.el`)** - thin coordinator (~270 lines). `M-x utilz` offers a `completing-read` menu (Vertico-compatible) of the TSV rows, annotated with descriptions. Picking a utility resolves input per its declared kind (region for stdin, buffer file or prompt for file, directory prompt for path, none), runs it, and dispatches the result per its declared output kind (replace region with single `undo-boundary`, pop a `*utilz-NAME*` buffer, echo a single-line message, or discard). `C-u` prompts for extra flags; `C-u C-u` confirms the full command line before running. Non-zero exit pops a stderr buffer and leaves the region/buffer untouched (No Silent Errors). `M-x utilz-refresh` re-reads the manifest. Default keybinding: `C-c u`.

### Changed

- Framework version bumped to 2.2.0 (additive minor bump - new subcommand families, no breaking changes).
- `opt/utilz/tmpl/metadata.tmpl` - includes a commented `integration:` stub so `utilz generate` scaffolds the block for new utilities.
- `help/utilz.md` - new sections documenting `utilz integration <verb>` and `utilz emacs <verb>`.
- Project-wide bash reindent from 4-space to 2-space (Intent project standard). 32 files touched, pure mechanical change.

### Tests

- `opt/utilz/test/bridge.bats` - 16 new tests covering TSV shape (column count, row count, cleanz spot-check, utilz-core exclusion), dispatcher verb routing (`integration`, `emacs`), `install` happy path + `--symlink` + idempotency + error paths (missing `--dest`, unknown option), and `doctor` exit-zero on clean checkout.

## [2.1.0] - 2026-03-25

### Added

- **expz** - New batch expense receipt PDF extraction utility
  - Recursively finds PDF receipts in category subdirectories
  - Extracts structured data via `xtrct` (Claude API) using a JSON schema
  - Outputs CSV with columns: Date, Category, Supplier, Description, Currency, Subtotal, VAT, Total, Reference, File
  - Category derived from parent directory name
  - Bundled default schema at `lib/expense_schema.json`, overridable with `--schema`
  - Output to stdout or `--out <file>`
  - Verbose mode with progress to stderr
  - Handles JSON array responses from xtrct (normalises to first element)
  - 9 comprehensive tests

### Changed

- Framework version bumped to 2.1.0

## [2.0.0] - 2026-03-02

### Changed

- **syncz** - Unison backend for bidirectional sync (syncz v2.0.0)
  - `--bidi` now uses unison when available for archive-based state tracking
  - Automatically distinguishes new files from deleted files (no more mass-deletion risk)
  - Falls back to rsync two-pass when unison is not installed
  - `--backend unison|rsync` flag to force a specific backend
  - `--fresh` flag to ignore saved unison archives (treat as first sync)
  - `--prefer d1|d2|newer` flag to force conflict resolution (unison only)
  - `--no-metadata` flag to ignore xattrs and resource forks (for cloud filesystems)
  - `--ignore FILE` flag to read exclude patterns from a file (one per line, `#` comments supported)
  - `--dry-run` works with unison via mutation blocking (`-nocreation/-nodeletion/-noupdate`)
  - `--delete` is a no-op in unison mode (deletions are state-tracked)
  - Path display uses `D1:/D2:` root labels with common suffix extraction (`Dir:`)
  - `SYNCZ_ROOTS_SHOWN` env var to suppress per-invocation headers in wrapper scripts
  - Dry-run output shows `[new]`, `[changed]`, `[CONFLICT]` tags with direction labels
  - unison added as optional dependency
  - 12 new tests (9 unison bidi + 3 backend selection); existing 66 tests pinned to rsync
  - unison added to CI dependencies (Ubuntu and macOS)

## [1.3.2] - 2026-03-02

### Fixed

- **syncz** - Safe orphan defaults in `--bidi` mode (syncz v1.4.0)
  - Bare `--bidi` now keeps all orphans and syncs them to both sides (was interactive delete-by-default)
  - `--bidi --delete` shows irreversibility warning before deleting
  - `--bidi --confirm` interactive prompt flipped to `[y/N/a]` where Enter = keep (was `[Y/n/a]` Enter = delete)
  - Prevents accidental mass-deletion when one side is mostly empty

### Changed

- Framework version bumped to 1.3.2

## [1.3.1] - 2026-02-19

### Added

- **lnrel** - New utility for creating symlinks with relative paths
  - Computes relative path from link directory to target using GNU `realpath`
  - Portable symlinks that survive directory tree moves
  - Automatic `grealpath`/`realpath` detection for macOS/Linux portability
  - Strips backslash escapes from paths (handles tab-completion-in-quotes pattern)
  - Supports dangling symlinks (target need not exist)
  - Single-arg form defaults to basename in current directory
  - 12 comprehensive tests
- coreutils added to macOS CI brew install (for `grealpath`)
- lnrel added to Linux CI test loop

### Changed

- Framework version bumped to 1.3.1

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
