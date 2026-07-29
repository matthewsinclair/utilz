# Changelog

All notable changes to the Utilz framework will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.4.0] - 2026-07-29

### Changed

- **BREAKING (soft): `yq` is now a hard dependency of the framework** (ST0009/WP-02). `get_util_metadata` previously carried two parsers -- a `yq` path and a grep fallback that answered four hardcoded queries and returned an empty string for everything else, which a caller cannot distinguish from an absent key. The fallback is gone; `yq` is the single YAML parser, declared in `opt/utilz/utilz.yaml` and gated by a single `require_yq`. Without `yq`, `utilz list` now fails loudly with an install hint where it previously degraded silently and gave wrong answers. `utilz doctor` deliberately still completes without `yq` and names it as the missing dependency -- it is the command you run to discover exactly that. This is the change that makes the bump minor rather than patch.
- **One walker of `bin/`** (ST0009/WP-01). `list_utilities`, `run_doctor` (twice), `run_tests`, `emit_integration_tsv`, and `emacs_doctor` each open-coded the same glob-and-filter over `bin/*`, and had already drifted: two verified the symlink resolved to the dispatcher, three accepted any symlink, so a stray link in `bin/` was a utility to `doctor` and not to `list`. All five now read a single `each_utility()` (Highlander), consumed via process substitution so accumulator arrays survive the loop.

### Fixed

- **`utilz generate` stamped a compatibility floor no 2.x framework could satisfy** (issue 0002, ST0009/WP-03). `opt/utilz/tmpl/metadata.tmpl` hardcoded `utilz_version: "^1.0.0"` while `VERSION` read 2.3.0, and `run_doctor` compares major versions -- so every generated utility was born incompatible and stayed that way until someone hand-edited the yaml. The floor is now derived from the framework's own `VERSION` via a `{{UTILZ_FLOOR}}` placeholder substituted at generation time. Latent rather than observed: all 13 shipped utilities already carried `^2.0.0`, so nothing in the repo was ever broken by it.

### Docs

- `docs/architecture.md`, `help/utilz.md`, `README.md` reconciled with the as-built: `yq` documented as a framework-level hard requirement rather than an mdagg-specific one, `each_utility` / `require_yq` added to the common-library reference, and the claim that utilities call `get_util_metadata()` corrected (it has no callers outside `common.sh` -- it is framework-internal). The stated bash floor is corrected from "4.0+" to 3.2, which is what macOS ships and what the code has always targeted.

### Tests

- `opt/utilz/test/common_lib.bats` -- 12 new tests covering the three seams, 11 of which fail against the pre-change code. `each_utility` distinguishing a dispatcher symlink from a stray symlink and a plain file; the drift regression asserting a stray link is invisible to `list_utilities` **and** `run_doctor` (the old code counted it in one and not the other); `list_utilities` failing loudly without `yq`; the install hint printed **once** rather than once per utility (a regression test for a defect hit during this work -- `require_yq` originally memoised into a variable, which does nothing across the command substitution `get_util_metadata` runs in); `run_doctor` completing without `yq`; `get_util_metadata` returning non-zero rather than an empty string; and the generator stamping a floor that tracks a fabricated `VERSION` of 7.3.1, proving derivation rather than coincidence.

## [2.3.0] - 2026-07-10

### Added

- **todo** - New standalone DOING / TODO / DONE task manager (ST0008). A single-file manager for a plain-text `todo.md` with positional item numbers and history sweep / purge subcommands. Forked from Intent's `intent todo` but made independent of steel threads: the `todo.md` is the source of truth, not a projection. File-location precedence: `--file <path>` wins, then `-g`/`--global` (`${XDG_CONFIG_HOME:-$HOME/.config}/utilz/todo/todo.md`), else default `./todo.md`. Verbs: `add`/`start`/`done`/`notdone`/`toggle`, `next`/`doing`/`todo`/`done`/`count`, `done --prune`/`--flush`, `sync`/`update`/`edit`, `--json`. The `todo.md` format stays mutually compatible with `intent todo` (same bucket headings and glyphs).
- **`utilz todo` <-> `intent todo` mutual guard** (ST0008/WP-08). `utilz todo` stamps `generator: utilz todo` on every write and refuses to clobber a `todo.md` owned by a different generator (eg `intent todo`) - but only when Intent is actually present (a silent `command -v intent` plus a `intent/.config/config.json` check rooted at the target file's directory), so utilz stays a zero-dependency standalone tool that runs silently and never fails where Intent is absent. It also refuses to create a fresh default `./todo.md` inside an Intent project. Mirrors Intent's `guard_foreign_todo` without taking a runtime dependency on Intent.
- **File-based issue tracker** at `intent/issues/` (`OPEN/` / `CLOSED/` / `_templ/`) - lightweight, git-tracked, steel-thread-independent, for defects a single issue can drive without a full ST.

### Fixed

- **mdagg: silent Unicode data loss under a C locale** (issue 0001). With `--strip-back-links`, mdagg used a `[←↑]` grep bracket class that, under `LC_ALL=C`, degraded to a byte set (`0xE2` is the UTF-8 lead byte for the whole U+2000-U+2FFF block) and silently deleted any content line containing a `→ ∥ ∈ — ...` character - invisible in a UTF-8 terminal, data-destroying in CI / agent sandboxes that export `LC_ALL=C`. Fixed with an anchored, byte-safe ERE (`grep -vE '^[[:space:]]*\[(←|↑)'`) that also tightens the strip to genuine navigation-link lines (inline arrows in prose now survive). The sibling title-case (`sed 's/\b\(.\)/\u\1/g'`, whose `\b`/`\u` are GNU-sed no-ops on BSD sed - so section titles came out un-cased on macOS) was replaced with a portable POSIX-awk title-case, and the duplicated title derivation extracted into a single `derive_title()` (Highlander).

### Changed

- Framework version bumped to 2.3.0 (additive minor bump - new `todo` utility; no breaking changes).
- CI: **expz** added to the Ubuntu (test-linux) test loop. Its BATS suite is entirely offline (every test returns before expz's `ANTHROPIC_API_KEY` check), so no CI secret is required; macOS already exercised it via `utilz test`.

### Tests

- `opt/todo/test/todo.bats` - full BATS coverage for the todo utility, including the WP-08 mutual-guard acceptance tests (stamp present; foreign-refusal inside an Intent project with a stubbed `intent` on PATH; foreign-proceed outside a project; own / legacy / fresh pass-through; default-path creation refused in an Intent project).
- `opt/mdagg/test/mdagg.bats` - regression tests for issue 0001 under `LC_ALL=C` (Unicode content survives while navigation links are stripped; a link-only file strips without a `set -e` abort; inline arrows preserved; portable title-casing).

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
