# Utilz Project - Claude Code Restart Document

**Last Updated**: 25 March 2026
**Version**: 2.1.0
**Repository**: <https://github.com/matthewsinclair/utilz>
**Working Directory**: `/Users/matts/Devel/prj/Utilz`

---

## Project Overview

Utilz is a bash/zsh utility framework providing a dispatcher-based CLI system. All utilities are symlinks to `bin/utilz` which routes execution to implementations in `opt/*/`.

**Key Design Principles**:

- Single dispatcher pattern (`bin/utilz`)
- Shared common library for all utilities (`opt/utilz/lib/common.sh`)
- Self-contained utilities in `opt/<utility>/`
- Built-in testing with BATS (`utilz test [utility]`)
- Generator for scaffolding new utilities (`utilz generate <name>`)
- CI/CD with GitHub Actions (Ubuntu + macOS)

---

## Current State

No active work. All steel threads complete. Framework is stable at v2.1.0 with 12 utilities.

### Project Structure

```
Utilz/
+-- bin/utilz               # Main dispatcher (all utilities symlink here)
+-- opt/                    # Utility implementations
|   +-- utilz/              # Core framework
|   |   +-- utilz           # Core implementation
|   |   +-- lib/common.sh   # Shared functions library
|   |   +-- tmpl/           # Generator templates
|   |   +-- test/           # Framework tests + test_helper.bash
|   +-- cleanz/             # LLM text cleaner + C2PA image mode
|   +-- clipz/              # Clipboard utilities (cross-platform)
|   +-- cryptz/             # Encryption/decryption (GPG wrapper)
|   +-- expz/               # Batch expense receipt PDF extraction to CSV
|   +-- gitz/               # Git utilities (recursive status)
|   +-- lnrel/              # Portable relative symlinks
|   +-- macoz/              # macOS-specific utilities
|   +-- mdagg/              # Markdown aggregator
|   +-- pdf2md/             # PDF to Markdown converter
|   +-- retry/              # Retry command utility
|   +-- syncz/              # Directory syncer (rsync + unison)
|   +-- xtrct/              # Schema-driven semantic data extraction
+-- help/                   # Help documentation (*.md files)
+-- docs/                   # Architecture and developer guides
+-- .github/workflows/      # CI/CD (tests.yml)
+-- intent/                 # Steel thread documentation
+-- CHANGELOG.md            # Release history
+-- VERSION                 # Current version (2.1.0) - single source of truth
+-- README.md               # Main documentation
```

### Available Utilities

| Utility | Description                                        | Version |
| ------- | -------------------------------------------------- | ------- |
| utilz   | Core framework (help, version, list, doctor, test) | 2.1.0   |
| cleanz  | LLM text cleaner + C2PA image metadata stripping   | 1.1.0   |
| clipz   | Cross-platform clipboard (pbcopy/xclip/xsel)       | 1.0.0   |
| cryptz  | GPG encryption/decryption wrapper                  | 1.0.0   |
| expz    | Batch expense receipt PDF extraction to CSV        | 1.0.0   |
| gitz    | Git multi-repo recursive status                    | 1.0.0   |
| lnrel   | Portable relative symlinks                         | 1.0.0   |
| macoz   | macOS utilities (desktop bg, folder icons)         | 1.0.0   |
| mdagg   | Markdown file aggregator                           | 1.0.0   |
| pdf2md  | PDF to Markdown converter                          | 1.0.0   |
| retry   | Retry command with configurable intervals          | 1.0.0   |
| syncz   | Directory syncer with bidi/unison mode             | 2.0.0   |
| xtrct   | Schema-driven semantic data extraction             | 1.0.0   |

### Version Management

- **Framework version**: `VERSION` file (single source of truth), currently 2.1.0
- **Utility versions**: each `opt/<name>/<name>.yaml` has its own `version:` field (independent)
- **Compatibility**: each utility declares `utilz_version: "^2.0.0"` for framework compat
- **utilz.yaml** uses `version_file: ../../VERSION` to track framework version

### Git Configuration

**Remotes**:

- `local`: `~/Dropbox/Repositories/Devel/Utilz` (backup)
- `upstream`: `git@github.com-matthewsinclair:matthewsinclair/utilz.git` (primary)

**Push to both**: `git push local main && git push upstream main`

**Current branch**: `main`

**Latest tag**: `v2.1.0`

### GitHub Actions CI/CD

**File**: `.github/workflows/tests.yml`

**Test Strategy**:

- **Ubuntu (test-linux)**: Tests: utilz, cryptz, gitz, mdagg, retry, syncz, pdf2md, xtrct, lnrel
- **macOS (test-macos)**: Tests all utilities including macoz, clipz, cleanz, syncz
- **ShellCheck**: Static analysis on all shell scripts
- **Note**: expz not yet in CI test loop (needs ANTHROPIC_API_KEY in CI)

---

## Important Conventions

### Git Commits

**CRITICAL**: NEVER include Claude attribution in commits. No "Co-Authored-By" lines, no "Generated with Claude Code" footers. User will reject these.

### Code Style

- bash 3.2 compatible (macOS ships ancient bash - no namerefs, no `${var,,}`)
- Quote all variable expansions: `"$variable"`
- Use `[[ ]]` for conditionals
- All logging to stderr (>&2) via common.sh functions
- Markdown tables must be column-aligned

### Testing

- Tests use BATS framework loaded via `load "../../utilz/test/test_helper.bash"`
- Each utility has tests in `opt/<name>/test/<name>.bats`
- Run all: `utilz test` / Run one: `utilz test <name>`

### Adding New Utilities

1. `utilz generate <name> "description" "author"` to scaffold
2. Implement in `opt/<name>/<name>`
3. Add metadata to `opt/<name>/<name>.yaml` (especially dependencies)
4. Write tests in `opt/<name>/test/<name>.bats`
5. Write help in `help/<name>.md`
6. Add to CI test loop in `.github/workflows/tests.yml` if needed
7. Run `utilz doctor` and `utilz test <name>` to verify

---

## Dependencies

### Required

- bash or zsh (bash 3.2+ for macOS compat)
- yq (YAML parsing) - `brew install yq`
- bats-core (testing) - `brew install bats-core`

### Optional

- glow (enhanced help rendering) - `brew install glow`
- exiftool (cleanz image mode) - `brew install exiftool`
- rsync (syncz, pre-installed on most systems)
- unison (syncz bidi mode) - `brew install unison`
- jq (expz CSV assembly) - `brew install jq`

### Verification

Run `utilz doctor` to check all dependencies and configuration.

---

## Key Documentation

| Document                  | Purpose                          |
| ------------------------- | -------------------------------- |
| `README.md`               | Project overview and quick start |
| `CHANGELOG.md`            | Release history                  |
| `docs/index.md`           | Documentation hub                |
| `docs/developer-guide.md` | Creating new utilities           |
| `docs/architecture.md`    | Dispatcher pattern details       |
| `help/utilz.md`           | Framework command reference      |
| `intent/wip.md`           | Current work-in-progress status  |
| `intent/restart.md`       | Session restart context          |
| `intent/done.md`          | Completed work history           |

---

## Quick Reference Commands

```bash
# Framework
utilz list                          # List all utilities
utilz help [utility]                # Show help
utilz version                       # Show version
utilz doctor                        # Run diagnostics
utilz test [utility]                # Run tests
utilz generate <name>               # Generate new utility scaffold

# expz (NEW v1.0.0)
expz receipts/                      # Extract receipts to CSV
expz receipts/ --out expenses.csv   # Write to file
expz receipts/ --verbose            # Show progress

# syncz
syncz --dry-run ~/src ~/dst         # Preview sync
syncz --bidi ~/dir1 ~/dir2          # Two-way sync
syncz --just-do-it --delete ~/src ~/dst

# cleanz
cleanz document.txt                 # Clean text file
cleanz --clipboard                  # Clean clipboard
cleanz --image photo.png -o out.png # Strip image metadata

# Other utilities
clipz copy / clipz paste            # Clipboard operations
cryptz encrypt / decrypt            # Encryption
gitz status-all [dir]               # Recursive git status
macoz bg image.jpg                  # Set desktop background
mdagg "*.md"                        # Aggregate markdown
pdf2md doc.pdf                      # Convert PDF to markdown
retry -i 5 -m 10 command            # Retry command
xtrct doc.pdf --schema schema.json  # Extract structured data
```

---

## For Next Session

When starting a new session:

1. **Read this document** to understand current state
2. **Check WIP**: `cat intent/wip.md` for active work
3. **Run diagnostics**: `utilz doctor`
4. **Check git status**: `git status` and `git log --oneline -5`
5. **Ask user** what they want to work on

The framework is stable at v2.1.0. Future work involves adding utilities or enhancements based on user needs.
