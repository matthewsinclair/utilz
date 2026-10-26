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
│   ├── cleanz -> utilz       # Utility symlinks...
│   ├── clipz -> utilz
│   ├── pdf2md -> utilz
│   ├── lnrel -> utilz
│   ├── ...                   # one symlink per utility (`utilz list`)
│   ├── syncz -> utilz
│   └── xtrct -> utilz
├── opt/
│   ├── utilz/
│   │   ├── lib/
│   │   │   └── common.sh    # Shared functions
│   │   ├── test/            # Framework tests
│   │   └── utilz.yaml       # Framework metadata
│   └── <utility>/            # Each utility has its own directory
│       ├── <utility>         # Implementation
│       ├── <utility>.yaml    # Utility metadata
│       ├── test/             # Utility tests
│       └── README.md         # Utility docs
└── help/
    ├── utilz.md              # Framework help
    └── <utility>.md          # Utility help files
```

## Installation

Install Utilz with Homebrew:

```bash
brew tap matthewsinclair/utilz

# Homebrew 7 loads a formula from a tap outside its own only once you trust it
brew trust --formula matthewsinclair/utilz/utilz

brew install matthewsinclair/utilz/utilz

# Check the install, and see which utilities' own dependencies are missing
utilz doctor
```

brew links the dispatcher and every utility into its own `bin` (`$(brew --prefix)/bin`), so nothing else goes on your PATH and no environment variable is needed. `brew upgrade utilz` updates it.

A clone of this repository is for working on Utilz itself: see [Maintaining Utilz](#maintaining-utilz-dev-opt-brew).

**Platforms.** Utilz runs on macOS and Linux. What needs macOS says so: macoz and menuz's app run on macOS alone, and arngz's apply, diff and discover need macOS and Hammerspoon, while its list, show, delete and current work anywhere. Elsewhere each refuses by name, `utilz list` marks a utility `(macOS only)`, and `utilz doctor` names what this machine lacks rather than count it as missing.

**Do NOT export `UTILZ_HOME`.** The dispatcher works out which tree it belongs
to from its own location, following the symlink chain from `$0` and taking the
parent of `bin/`. An exported `UTILZ_HOME` is ignored.

This README told you to export it until v2.5.1, and that instruction was worse
than redundant. Once Utilz gained a second tree (see Maintaining Utilz), an ambient
`UTILZ_HOME` pointing at the checkout silently redirected the _installed_
utilz back to the checkout: every command answered from the source tree while
appearing to run the install. Nothing reported it. If you have those lines in
your shell config, delete them.

## Usage

### Framework Commands

```bash
utilz help                    # Show framework help
utilz help <utility>          # Show utility-specific help
utilz list                    # List installed utilities
utilz version                 # Show framework version
utilz doctor                  # Run diagnostics
```

`utilz test`, `utilz generate` and the install verbs work in a clone of this repository: see [Maintaining Utilz](#maintaining-utilz-dev-opt-brew).

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

### arngz

Named window arrangements across displays and spaces, on macOS. A desk is a YAML file in arngz's catalogue that says, for each display and each space on it, which apps live there and where on a grid their windows sit. `arngz discover` records the arrangement on screen now as a desk, and `arngz <desk>` puts the windows back. Hammerspoon is the engine: `arngz init --yes` connects it, and `arngz doctor` checks every precondition.

**Platform**: apply, diff, discover and `init --yes` need macOS and Hammerspoon; list, show, delete and current work on Linux too.

**`apply` takes the pointer.** macOS has no working call to move a window to another space, so apply moves each window the way a person does, by its title bar. Keep your hands off the mouse and keyboard while it runs; moving the pointer stops it.

```bash
# Connect Hammerspoon, then check every precondition
arngz init --yes
arngz doctor

# Record the arrangement on screen now as a desk, on a 12x8 grid; replace it later
arngz discover --grid 12x8 --save work
arngz discover --save work --force

# The catalogue
arngz list
arngz show work
arngz delete old

# The desk applied or saved last
arngz current

# What apply would change, then do it
arngz diff work
arngz apply work --dry-run
arngz work

# Only apps already running, on spaces that exist, one desk display bound to a screen
arngz apply work --no-launch --no-create --map left=<uuid>
```

See `utilz help arngz` for details.

### cleanz

LLM text cleaner that removes hidden characters and formatting artifacts from text copied from ChatGPT, Claude, Gemini, and other LLM interfaces. Also supports stripping C2PA metadata from AI-generated images.

```bash
# Clean a file
cleanz document.txt

# Clean file in place
cleanz -i document.txt

# Clean clipboard contents
cleanz --clipboard

# Detect hidden characters without cleaning
cleanz --detect document.txt

# Pipe mode
pbpaste | cleanz | pbcopy

# Image mode: strip C2PA/AI metadata
cleanz --image photo.png -o cleaned.png
cleanz --image --detect dalle-image.png
```

See `utilz help cleanz` for details.

### clipz

Cross-platform clipboard copy and paste utility. Supports macOS (pbcopy/pbpaste), Linux X11 (xclip/xsel), and Wayland (wl-clipboard).

```bash
# Copy from stdin
echo "hello" | clipz copy

# Copy from file
clipz copy file.txt

# Paste to stdout
clipz paste
```

See `utilz help clipz` for details.

### cryptz

GPG encryption and decryption wrapper with sensible defaults.

```bash
# Encrypt a file
cryptz encrypt secret.txt

# Decrypt a file
cryptz decrypt secret.txt.gpg

# Specify recipient
CRYPTZ_EMAIL=user@example.com cryptz encrypt file.txt
```

See `utilz help cryptz` for details.

### expz

Batch expense receipt PDF extraction to CSV. Recursively finds PDF receipts in category subdirectories, extracts structured data via `xtrct` (Claude API), and outputs CSV.

```bash
# Output CSV to stdout
expz receipts/

# Write to file with progress
expz receipts/ --out expenses.csv --verbose

# Custom extraction schema
expz receipts/ --schema custom_schema.json
```

Requires `ANTHROPIC_API_KEY` environment variable. See `utilz help expz` for details.

### gitz

Git multi-repository operations. Recursively find and check git repositories, excluding paths with leading underscores or `.work`.

```bash
# Check all repos in current directory
gitz status-all

# Check repos in specific path
gitz status-all ~/Projects
```

See `utilz help gitz` for details.

### lnrel

Create symlinks with relative paths. Computes the relative path from link directory to target using GNU `realpath`, then creates the symlink. Portable symlinks that survive directory tree moves.

```bash
# Link to a file (creates ./file.txt in cwd)
lnrel /path/to/file.txt

# Explicit link name
lnrel ../shared/config.yaml config.yaml

# Cross-directory
lnrel /opt/data/db.sqlite ./data/db.sqlite
```

Requires GNU coreutils on macOS (`brew install coreutils`). See `utilz help lnrel` for details.

### macoz

macOS system utilities - desktop backgrounds and folder icons.

**Platform**: macOS only. Elsewhere every command refuses, naming the platform; `--help` answers everywhere.

```bash
# Desktop backgrounds with seasonal auto-selection
macoz bg                              # Auto-select current season
macoz bg autumn                       # Random autumn wallpaper
macoz bg autumn 02                    # Specific seasonal wallpaper
macoz bg ~/Pictures/wallpaper.jpg     # Custom image

# Folder icons
macoz setpicfor icon.png              # Set icon for current directory
macoz setpicfor photo.jpg ~/Projects  # Set icon for specific directory
macoz setpicfor --all                 # Batch: set icons for subdirectories
macoz setpicfor --all --dry-run       # Preview changes
```

See `utilz help macoz` for details.

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

### menuz

A menu of your own commands in the macOS menu bar, read from one YAML file, on macOS 26 or later. Each item runs a shell line: a script, a `utilz` verb, anything the login shell can run. An item that takes parameters asks for them in one form first, and every run's output goes to one log that `menuz log` tails. Labels are expanded by the login shell each time the menu opens, and the menu follows the file as it changes, with no restart. On a full menu bar a new item can sit behind the overflow: hold Command and drag menuz's mark where you want it. At its first launch, answer macOS's alert with Allow, so its notices can post.

**Platform**: macOS 26 or later; the menu bar app needs macOS.

```bash
# Create the config directory and the example menu (--force replaces the yaml)
menuz init
menuz init --force

# Edit the menu, in the default text editor or in $VISUAL/$EDITOR, then check it
menuz edit
menuz edit --editor
menuz validate
menuz render

# Build and test the app (--release, --unsigned where there is no signing identity)
menuz build
menuz build --release --unsigned
menuz test --unsigned

# Install it into ~/Applications and launch it (from a Homebrew install, the
# release's signed app); see where it stands, and check what it needs
menuz install
menuz status
menuz doctor
menuz stamps

# Drive it
menuz stop
menuz start
menuz restart
menuz uninstall

# Follow what the runs print, or read the last 50 lines
menuz log
menuz log -n 50

# Run the development build, then go back to the installed one
menuz use dev
menuz use installed

# The help (-h is the same) and the version
menuz --help
menuz -h
menuz --version
```

See `utilz help menuz` for details.

### pdf2md

PDF to Markdown converter using pdfplumber. Detects headings, list items, and paragraph structure from font metadata. Composes with `xtrct` for semantic data extraction.

```bash
# Convert PDF to stdout
pdf2md invoice.pdf

# Save to file
pdf2md invoice.pdf -o invoice.md

# Specific pages
pdf2md large.pdf --pages 1-5

# Pipeline with xtrct
pdf2md invoice.pdf | xtrct --schema invoice_schema.json
```

See `utilz help pdf2md` for details.

### prez

Markdown in, one self-contained HTML presentation out. A pipeline, not a viewer: it writes a file and stops, the browser presents, and there is no server. The single `.html` carries everything inside it, so a deck opens offline. The first Rust utility in the framework.

```bash
# Build a deck
prez build talk.md

# One slide per page, as PDF
prez pdf talk.md

# Present in a de-chromed window at the deck's own aspect
prez present talk.md

# Pick a built-in theme by NAME (simple, mono, manuscript, contrast,
# blueprint, steampunk, 8bit); --theme-file takes a path instead
prez build --theme mono talk.md

# A directory of pictures and a showreel.yaml to a looping HTML reel,
# then a video of that reel (needs Chrome and ffmpeg)
prez showreel build reel/
prez showreel video reel/
```

See `utilz help prez` for details.

### retry

Retry command until success with configurable wait time and max attempts.

```bash
# Retry with defaults (10s wait, unlimited retries)
retry "curl https://example.com"

# Retry with custom settings
retry --wait 5 --retries 3 "ping -c 1 google.com"
```

See `utilz help retry` for details.

### stampz

Stamp a recipient watermark diagonally across every page of every PDF in a directory, so a pack handed to a named person carries their name. Writes a manifest recording the sha256 of every file before and after. Builds its own stamp page, so it needs no browser and no network.

**This deters, it does not protect.** An overlay is strippable in seconds by anyone with a PDF tool. It marks a copy; it does not secure one.

```bash
# Stamp a pack; copies land in <pack-dir>.stamped
stampz ~/packs/seriesA "Matthew Sinclair"

# Stamp into a named directory, with an explicit date in the mark
stampz ~/packs/seriesA "Matthew Sinclair" --out /tmp/ms --date 20260903

# Overwrite the pack itself
stampz ~/packs/seriesA "Matthew Sinclair" --in-place
```

See `utilz help stampz` for details.

### syncz

Simple directory-to-directory syncer using rsync. Provides conflict resolution strategies (newer-wins, source-wins, dest-wins), confirmation prompts, dry-run, backup, delete support, and bidirectional sync with orphan detection.

```bash
# Preview what would be synced
syncz --dry-run ~/src /dst

# Sync with confirmation prompts
syncz --confirm ~/src /dst

# Force sync, delete extra files, create backups
syncz --force --delete --backup ~/src /dst

# Quick confirm-and-go
syncz --just-do-it --delete ~/src /dst

# Source always wins, exclude .git
syncz --source-wins --exclude ".git" ~/src /dst

# Two-way sync between directories
syncz --bidi ~/dir1 ~/dir2

# Bidi sync, auto-delete orphans
syncz --bidi --delete ~/dir1 ~/dir2
```

See `utilz help syncz` for details.

### todo

A DOING / TODO / DONE manager for a plain-text `todo.md`. Refuses to clobber an Intent project's own `intent/todo.md`.

```bash
# Show the view
todo

# Add an item, or add it at the top
todo add "write the thing"
todo add --top "write the thing first"

# Move things along
todo start 3
todo done 3

# Archive completed items
todo done --flush
```

See `utilz help todo` for details.

### xtrct

Schema-driven semantic data extraction using Claude API. Takes a document and a JSON schema template, then extracts structured data as JSON. Works with any document type.

```bash
# Extract from markdown
xtrct invoice.md --schema invoice_schema.json

# Extract from PDF (auto-converts via pdf2md)
xtrct invoice.pdf --schema invoice_schema.json

# Different output formats
xtrct doc.md --schema schema.json --format csv
xtrct doc.md --schema schema.json --format table
```

Requires `ANTHROPIC_API_KEY` environment variable. See `utilz help xtrct` for details.

## Using Utilz from Emacs

Utilz ships with a Doom-ready elisp bridge that exposes every utility with an `integration:` block in its YAML to Emacs. `M-x utilz` opens a `completing-read` menu of the available utilities, annotated with their description and I/O shape; picking one runs the utility on the current region, buffer, file, or directory, and dispatches the result per the utility's declared output kind (replace region, pop a result buffer, echo a message, or discard).

### Install

The canonical elisp ships with Utilz at `static/emacs/utilz.el`. Install it into your Doom custom directory with the bundled installer. A symlink is preferred, because it follows each `brew upgrade utilz`: from the Homebrew install it links through `$(brew --prefix)/opt/utilz/libexec`, the path brew keeps across upgrades, never the versioned keg.

```bash
utilz emacs install --dest ~/.config/doom/custom/160-utilz.el --symlink
```

Then add the printed `(load ...)` line to `~/.config/doom/config.el` (near your other `(load "NNN-<name>.el")` statements — anywhere before `999-finalise.el`):

```elisp
(load "160-utilz.el")
```

Run `doom sync && doom doctor` and restart Emacs. Sanity-check with:

```bash
utilz emacs doctor
```

Every check should be green: `utilz` on PATH, all utilities carry an `integration:` block, canonical elisp present.

### Everyday usage

The motivating case is cleaning LLM-pasted text in place:

```
M-x utilz RET cleanz RET
```

With an active region, the region is piped through `cleanz` and replaced with the cleaned output (one `undo-boundary` — a single `C-/` reverts cleanly). With no active region, the whole buffer is the input.

Other common flows:

**The menu is deliberately short.** Every entry is one that works and that makes sense from inside a buffer; the roster is not "every utility". See below.

| Invocation              | Input                          | Output                                        |
| ----------------------- | ------------------------------ | --------------------------------------------- |
| `M-x utilz` -> `cleanz` | active region or whole buffer  | region/buffer replaced in place               |
| `M-x utilz` -> `mdagg`  | directory (prompted)           | concatenated markdown in `*utilz-mdagg*`      |
| `M-x utilz` -> `pdf2md` | current buffer's file (or ask) | converted markdown in `*utilz-pdf2md*`        |
| `M-x utilz` -> `expz`   | directory (prompted)           | CSV of receipts in `*utilz-expz*`             |
| `M-x utilz` -> `prez`   | current buffer's file (or ask) | builds the deck; echoes the written path      |
| `M-x utilz` -> `todo`   | current buffer's file (or ask) | that file's DOING/TODO/DONE in `*utilz-todo*` |

### Why most utilities are NOT in the menu

A utility appears only if it declares an `integration:` block, and most deliberately do not. Absence is a decision, not an oversight -- `utilz emacs doctor` reports an unbound utility without failing.

Nine blocks were removed on 2026-09-03 (issue 0009) after the menu was measured against what the bridge actually invokes:

- **Four could never have worked.** The bridge builds `utilz <name> <flags> <path>`, and `cryptz`, `gitz` and `retry` each need a verb the block did not supply, while `mdagg` was declared `stdin` and does not read stdin. All four exited non-zero on selection.
- **Two mutated the filesystem on selection.** `lnrel` created a symlink in the prompted directory and reported success; `syncz` would fire a directory sync. Neither belongs one keystroke from a fuzzy-match menu.
- **Two were coherent but pointless here.** `clipz` duplicates Emacs' own clipboard and kill ring, and `macoz` is not buffer work. `xtrct` went too: it needs both an API key and a `--schema` the menu cannot supply.

`todo` was removed in that same pass and **restored**, because the reason was wrong. Its block declared `input: none`, so the bridge ran `utilz todo` in whatever directory Emacs happened to be in and ignored the buffer -- a broken declaration, exactly like `mdagg`'s, and `mdagg` was corrected rather than dropped. It is now `file -> buffer` with `flags: [--file]`, so visiting a `todo.md` and picking it shows that file's view. The default invocation is read-only, verified by hashing an ordinary markdown file before and after.

**`C-u` does not work with `todo`, and fails loudly rather than quietly.** The bridge inserts extra flags between the declared flags and the path, so `C-u ... done 2` builds `utilz todo --file "done 2" <path>` and exits 1. Declaring `flags: []` instead would put the path last and build `utilz todo done 2 <path>`, which exits 0 having modified `./todo.md` rather than the file you were looking at. Use the shell for `todo` verbs.

`stampz` declares no block either: `path -> message` is the right shape, but it needs a recipient, which only reaches it through the `C-u` extra-flags prompt.

A framework test now invokes the command line the bridge would build for every declaring utility and fails if the utility rejects the form, which is the check whose absence let four impossible entries sit in the menu since v2.2.0.

### Prefix arguments

- `M-x utilz` — default flags only (whatever the YAML declares).
- `C-u M-x utilz` — prompts for extra flags via `read-string`; passed through to the utility (eg `--detrope` for cleanz).
- `C-u C-u M-x utilz` — shows the full command line in a yes/no confirm before running. Useful before you let `cryptz` or `syncz` fire.

### Refreshing the manifest

After adding a new utility (or editing an `integration:` block), re-read the manifest without restarting Emacs:

```
M-x utilz-refresh
```

### Keybinding

The bridge binds `C-c u` to `utilz`. Override in your Doom config if you want a different prefix.

### How it works

The bridge is a thin coordinator. It reads a TSV manifest from `utilz integration commands` at load time (cached in `utilz--commands-alist`) and never parses YAML directly — the TSV is the single cross-boundary contract, so future editor integrations (VSCode, Zed, Vim) can consume the same surface without duplicating the walker. On failure (non-zero exit from the underlying utility), the bridge pops a stderr buffer and leaves your region/buffer untouched.

See `intent/st/ST0007/design.md` for the full design and `static/emacs/utilz.el` for the bridge source (~270 lines).

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
utilz_version: "^2.0.0" # Compatible framework versions
```

`utilz generate` stamps `utilz_version` from the framework's own `VERSION` (major only), so a generated utility is always compatible with the framework that generated it. Do not hardcode a floor in the template.

## Maintaining Utilz: dev, opt, brew

This section is for the maintainer of a dev checkout, a clone of this repository. A user installs from Homebrew ([Installation](#installation)); nothing here is needed to use Utilz.

Utilz follows the dev, opt, brew contract that every tool released through Homebrew follows (devbin's `docs/dev-opt-brew.md`, at devbin commit aeed31e4), as dev, stage and prod:

- **dev** is the checkout, where the work happens: the bleeding edge.
- **opt** is a working copy the checkout publishes with `utilz install`, kept apart from dev so what works is not disturbed by what is in progress. It lives at `$UTILZ_INSTALL_PREFIX`, which the sleeve sets (Molt's sleeve config); there is no default, and unset is refused by name.
- **brew** is the one prod publish: the Homebrew formula, rendered from a release tag ([docs/releasing.md](docs/releasing.md)). Inside it, `utilz install` refuses and names `brew upgrade utilz`.

`utilz version` names the tree that answered, on one line:

```
utilz <version> (dev, 0123456789ab)
utilz <version> (opt, 0123456789ab)
utilz <version> (brew, 0123456789ab)
```

The commit is HEAD in dev, with `+dirty` while a file of the runtime set is uncommitted, and in opt and brew it is the commit the install was published from, read from its manifest, `<root>/manifest.sha256`. The line names no path: where the running copy lives is the answer `command -v utilz` gives. `utilz doctor` prints the same line first, and checks the manifest: every file it names, each dispatcher link's target, and CI's verdict on the commit as the publish recorded it.

### Switching the shell between trees

`utilz use` points the links in `~/.local/bin` -- `utilz` and every utility -- at one tree:

```bash
utilz use dev     # point every link at the dev checkout
utilz use opt     # point every link at the opt install
utilz use brew    # remove them, so Homebrew's own links answer
utilz use         # report which tree they serve, and change nothing
```

**No link means brew**: a user who never runs `use` has Homebrew's links, and `use brew` returns a maintainer to them. For a dev or opt link to answer, `~/.local/bin` must come before Homebrew's bin on PATH, which the sleeve sets. `utilz use` with no word, and `utilz doctor`, fail when a link is shadowed by an earlier entry on PATH, or when the links serve more than one tree, and name what shadows or splits them. `use` is the one verb that points links: `relink` is retired, and install and upgrade never touch them.

`use brew` asks first: it removes the links only when Homebrew's own copy would then answer `utilz` and every name whose link it removes. Otherwise it refuses, removing nothing, and names each link and the tree it serves, why no Homebrew copy would answer (Homebrew is not installed or not on PATH, the formula is not, the formula has no such utility, its keg is not linked, Homebrew's bin is not on PATH, or another copy comes first on PATH), and the remedy: install, link or upgrade the formula, remove a dead link, or stay on dev or opt.

### Publishing and upgrading

```bash
utilz install                 # publish the checkout to $UTILZ_INSTALL_PREFIX
utilz install --prefix DIR    # publish somewhere else
utilz install --force         # republish over an existing install
utilz upgrade                 # upgrade the tree this utilz runs from
```

`install` runs only in a dev checkout, and refuses a dirty runtime set -- what git names under `bin/`, `opt/`, `help/`, `static/` and `VERSION`, less each utility's tests -- with no flag to override it, because the manifest records the commit the bytes came from. A doc or a board being edited beside it is not in the runtime set. `--force` is the one republish, and it replaces only a prefix whose manifest Utilz wrote.

`upgrade` does the running tree's own upgrade. In dev it runs `git pull --ff-only` and builds prez and showreel. In opt it changes nothing and names `utilz install --force` in the dev checkout, saying when dev is ahead. In brew it runs `brew update`, then `HOMEBREW_NO_AUTO_UPDATE=1 brew upgrade utilz` when brew names Utilz as outdated.

`utilz test` refuses in an install: the suite rewrites `bin/`, which is exactly what the manifest checksums, so an install would report drift nobody caused. The refusal names the dev tree to run it in.

### Commands for a dev checkout

```bash
utilz test                    # Run all tests
utilz test <utility>          # Run tests for specific utility
utilz generate <name> [desc]  # Generate new utility scaffold
```

### Creating a New Utility

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

### Testing

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

## Requirements

- Bash 3.2+ or Zsh (bash 3.2 is what macOS ships, and is the floor the framework targets)
- `yq` for YAML parsing -- required, not optional: it is the single parser for all utility metadata. The formula installs it; a dev checkout needs `brew install yq`
- `bats-core` for the suites, in a dev checkout (install: `brew install bats-core`)

## License

MIT. See [LICENSE](LICENSE).
Copyright (c) 2025-2026 Matthew Sinclair

## Author

Matthew Sinclair
[matthewsinclair.com](https://matthewsinclair.com)
