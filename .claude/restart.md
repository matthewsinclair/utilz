# Utilz Project - Claude Code Restart Document

**Last Updated**: 29 July 2026
**Version**: 2.4.0
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

No active work. All nine steel threads (ST0001-ST0009) complete and filed under `intent/st/COMPLETED/`. Framework stable at **v2.4.0** with 13 utilities (core `utilz` + 12 tools). The issue tracker at `intent/issues/` has nothing open -- 0001 (mdagg Unicode drop under C locale), 0002 (generator compatibility floor), 0003 (dispatcher flag aliases), 0004 (ST0009's sixth `bin/` walk) and 0005 (doctor PATH check) are all CLOSED.

Suite is **407 tests / 0 failures** across 14 suites; shellcheck clean across 15 files (the CI gate is blocking as of `0566bcc`); every script parses under bash 3.2.57; `utilz doctor` and `intent doctor` both fully green.

**Working tree is clean, but `fe8eecf` and `c5694d6` are unpushed** -- both remotes sit at `ad6402d`. Neither is a release, so no tag: `git push local main && git push upstream main` when hv wants it. Pushing is hv's per standing directive.

**v2.4.0 changed behaviour**: `yq` is now a hard dependency. The two-parser grep fallback in `get_util_metadata` is gone, so `utilz list` fails loudly with an install hint where it previously degraded silently and returned empty strings a caller could not tell from absent keys. `utilz doctor` deliberately still completes without `yq` -- it is the command you run to discover it is missing, so do not "tidy" it into gating on `require_yq`.

The whiteboard now has two nodes: `hv` (Workstream Zero, the human) and `cc`. Roster in `intent/whiteboard/README.md`.

Note: the framework `VERSION` (2.4.0) is distinct from the `intent` tooling version (2.17.3) -- don't conflate them.

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
|   +-- todo/               # Standalone DOING/TODO/DONE todo.md manager
|   +-- xtrct/              # Schema-driven semantic data extraction
+-- help/                   # Help documentation (*.md files)
+-- docs/                   # Architecture and developer guides
+-- .github/workflows/      # CI/CD (tests.yml)
+-- intent/                 # Steel threads (st/COMPLETED/) + issues/ tracker
+-- CHANGELOG.md            # Release history
+-- VERSION                 # Current version (2.4.0) - single source of truth
+-- README.md               # Main documentation
```

### Available Utilities

| Utility | Description                                        | Version |
| ------- | -------------------------------------------------- | ------- |
| utilz   | Core framework (help, version, list, doctor, test) | 2.4.0   |
| cleanz  | LLM text cleaner + C2PA image metadata stripping   | 1.2.0   |
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
| todo    | Standalone DOING/TODO/DONE todo.md manager         | 1.0.0   |
| xtrct   | Schema-driven semantic data extraction             | 1.0.0   |

### Version Management

- **Framework version**: `VERSION` file (single source of truth), currently 2.4.0
- **Utility versions**: each `opt/<name>/<name>.yaml` has its own `version:` field (independent)
- **Compatibility**: each utility declares `utilz_version: "^2.0.0"` for framework compat
- **utilz.yaml** uses `version_file: ../../VERSION` to track framework version

### Git Configuration

**Remotes**:

- `local`: `~/Dropbox/Repositories/Devel/Utilz` (backup)
- `upstream`: `git@github.com-matthewsinclair:matthewsinclair/utilz.git` (primary)

**Push to both**: `git push local main && git push upstream main`

**Current branch**: `main`

**Latest tag**: `v2.4.0` (2026-07-29), annotated on the `release:` commit itself, not the session HEAD

### GitHub Actions CI/CD

**File**: `.github/workflows/tests.yml`

**Test Strategy**:

- **Ubuntu (test-linux)**: Tests: utilz, cryptz, gitz, mdagg, retry, syncz, pdf2md, xtrct, lnrel, todo, expz
- **macOS (test-macos)**: Tests all utilities including macoz, clipz, cleanz, syncz
- **ShellCheck**: Static analysis on all shell scripts
- **Note**: expz IS in the CI loop (added 2026-07-10). Its BATS suite is entirely offline -- every test hits arg/schema validation paths that return before the `ANTHROPIC_API_KEY` check -- so no key or secret is needed in CI.

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

- bash or zsh (bash 3.2 is the floor -- macOS ships 3.2.57 and CI runs it)
- yq (YAML parsing) - `brew install yq`. HARD dependency as of v2.4.0; there is no fallback parser
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
utilz help [utility]                # Show help (-h / --help also accepted)
utilz version                       # Show version (--version also accepted; -v is unbound)
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

The framework is stable at v2.4.0. Future work involves adding utilities or enhancements based on user needs. Open defects (if any) live under `intent/issues/OPEN/` -- currently empty.

**First decision next session**: `fe8eecf` and `c5694d6` are unpushed (remotes at `ad6402d`). Not a release, so no tag involved.

Three traps that produced real defects here, worth holding before touching shell code:

- `local x=$(cmd) || handler` never runs the handler -- `local` returns its own status. Split declaration from assignment when the exit code matters. This is what made `clipz` copy nothing and report success.
- Verify shell tooling under `/bin/bash` with an array. zsh does not word-split unquoted variables, so `shellcheck -x $FILES` there errors on one bogus path and the empty output reads as a pass -- it produced a false "all 15 clean" against a real 57 findings.
- Never run two `utilz test` suites at once. The helper mutates `$UTILZ_HOME/bin`, so they corrupt each other; one such hang ran 2h18m and looked like a code defect.

Two items carried out of the 29 Jul 2026 session, both **outside this repo** and neither blocking:

- **Intent issue 0008** filed but uncommitted in `../Intent`. It covers the unconditional `Bash 4.0+` line `intent agents sync` writes into every project's `AGENTS.md`. `AGENTS.md:13` here is wrong today and **must not be hand-edited** -- it is generated, so the next sync would revert it. Re-run `intent agents sync` once the Intent fix lands.
- A reply to the Cdsync project's node, delivered as `../Cdsync/intent/whiteboard/cc/TEMP-from-utilz-cc-20260729.md` (uncommitted there, theirs to file or bin).
