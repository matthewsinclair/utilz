# Utilz - Universal Utilities Framework

**Version**: run `utilz version`
<!-- NO VERSION LITERAL IN THIS FILE OR ANY HELP FILE, AND THIS ONE LEARNED IT
     FIRST: hardcoding the framework version here drifted it to 2.2.0 while
     2.4.0 shipped. The fix was applied to this file alone and left in fifteen
     others, where it drifted again -- cleanz's README said 1.1.0 against a
     yaml of 1.2.0, and todo's help AND README said 1.0.0 against 1.1.0. The
     version has ONE home: the utility's yaml, or the file its version_file
     points at. A test in common_lib.bats holds every help file and every
     utility README to it. -->

**Author**: Matthew Sinclair
**Location**: worked out from the dispatcher's own path -- the Homebrew install (`$(brew --prefix)/opt/utilz/libexec`), or, for the maintainer, a dev checkout or an opt install published from one. `utilz version` names which one answered.

---

## Overview

**Utilz** (with a 'z') is a unified framework for managing personal command-line utilities across multiple machines. It provides:

- **Single dispatcher**: All utilities are symlinks to a master `utilz` script
- **Consistent UX**: Unified help, error handling, and output formatting
- **Easy management**: Add utilities by dropping implementation in `opt/{name}/` and creating a symlink
- **Installed with Homebrew**: one formula puts every utility on `$PATH`
- **Multi-language support**: Utilities can be written in bash/zsh, Rust, Elixir, or any language

---

## Quick Start

### Installation

Utilz is installed with Homebrew, and the README's Installation has the steps for a fresh machine (https://github.com/matthewsinclair/utilz#installation). brew links every utility into its own `bin`, so nothing else goes on `$PATH`.

```bash
# Check the install, and see which utilities' own dependencies are missing
utilz doctor

# Update it
brew upgrade utilz
```

A clone of the repository is the maintainer's dev checkout; `utilz use` switches the shell between it, an opt install and this one, and the commands that only work there are under "Commands for a dev checkout" below.

**Do NOT export `UTILZ_HOME`.** The dispatcher derives it from its own location
and ignores an inherited value. This page told you to export it until v2.5.1;
with two trees in play, an ambient `UTILZ_HOME` silently sent the _installed_
utilz back to the checkout. Delete those lines if you have them.

### First Utility

```bash
# All utilities should already be set up
# Try the markdown aggregator:
mdagg --help
```

---

## Commands

### `utilz help [utility]`

Show help for Utilz or a specific utility.

```bash
# Show this help
utilz help

# Show help for mdagg utility
utilz help mdagg
```

`-h` and `--help` are accepted as aliases, and take the same optional utility argument:

```bash
utilz --help
utilz -h
utilz --help mdagg
```

### `utilz doctor`

Run diagnostics to check that Utilz is properly configured.

It prints the version line first, as `utilz version` does, then its checks, each by name:

- **UTILZ_HOME**: the tree resolves to a valid one
- **which tree this is**: dev, opt or brew; a tree it cannot name fails, and so does a dev checkout git cannot read, saying why
- **directory structure**: it is correct
- **bin/utilz**: it exists and is executable
- **PATH configuration**: `utilz` is reachable on `$PATH`, with the remedy for this tree when it is not; and the links in `~/.local/bin` serve one tree and are not shadowed by an earlier `$PATH` entry
- **installed utilities**: each is properly configured
- **external dependencies**: they are installed (eg `yq`)
- **install integrity**: every file of the runtime set matches the manifest it was published
  with, each dispatcher link still targets `utilz`, and CI's verdict on the commit is shown as the publish recorded it. In a source checkout there is no manifest, and doctor says so rather
  than passing silently. An opt install with a manifest from before the dev, opt, brew contract fails, naming `utilz install --force`; a Homebrew install with one is noted, naming `brew upgrade utilz`.

What is not available on this platform is said, never counted as missing. A utility whose `platforms` leave this one out reads, in the installed utilities check, as `macoz: macOS only, not available on Linux`, and the external dependencies check skips its dependencies; a dependency whose `platforms` leave this one out, or a macOS app anywhere but macOS, is one line saying so, with no install line.

The whole report goes to stdout, so `utilz doctor | grep` sees every line.

```bash
utilz doctor
```

### `utilz list`

List all available utilities with brief descriptions.

```bash
utilz list
```

### `utilz version`

Show version information for Utilz or a specific utility.

Every answer carries **both** versions in play -- the framework's and the utility's -- because being handed one of them is how a bug report arrives missing the half that explains it. **There is no `v` prefix anywhere**: it is noise, and it was the only thing making the framework's line a different shape from a utility's.

```bash
$ utilz version          # --version is accepted as an alias
utilz 2.7.0 (brew, 0123456789ab)

$ utilz mdagg --version  # either invocation form, byte-identical
utilz:2.7.0/mdagg:1.0.0
Markdown aggregator
utilz 2.7.0 (brew, 0123456789ab)

$ mdagg --version
utilz:2.7.0/mdagg:1.0.0
Markdown aggregator
utilz 2.7.0 (brew, 0123456789ab)
```

**Both invocation forms give the same bytes**, and that is a guarantee rather than a coincidence: `bin/utilz` answers `--version` from one place for both. Until ST0015 it intercepted the symlink form only, thirteen utilities hand-copied an arm to cover the other, and the two that never copied it -- `todo` and `prez` -- were the two that disagreed with themselves.

Utilz's own answer is **one line**, the version line every tool released through Homebrew prints (the dev, opt, brew contract): `utilz <version> (<tree>, <commit>)`. It names **which tree replied** -- dev, opt or brew -- and the commit it came from: in opt and brew the one its manifest records, in dev HEAD, followed by `+dirty` while a file of the runtime set is uncommitted. `(dev, unknown)` means git cannot read the checkout, and `(<tree>, old manifest)` an install from before the contract. The line names no path: where the running copy lives is the answer `command -v utilz` gives. A reader reads the line up to its closing parenthesis and ignores anything after it. A utility's answer is the pair and its description, with that line last. CI's verdict on the commit is `utilz doctor`'s to show: a record, not a gate.

`-v` is deliberately unbound: it reads as a verbose flag, and no utility binds it.

### `utilz use [dev|opt|brew]`

Switch which tree the links in `~/.local/bin` -- `utilz` and every utility -- serve.

```bash
utilz use dev     # point every link at the dev checkout
utilz use opt     # point every link at the opt install
utilz use brew    # remove them, so Homebrew's own links answer
utilz use         # report which tree they serve, and change nothing
```

**No link means brew**: a Homebrew user who never runs `use` has brew's links, and `use brew` returns to them. `use dev` and `use opt` link every utility of the tree, making the links that are missing; each reaches the other tree with no path typed (opt is `$UTILZ_INSTALL_PREFIX`; dev is the checkout the opt install was published from), and from the Homebrew install `use dev` is run from the checkout instead. A link that is not Utilz's, and a file in a utility's place, are left alone and reported. Each switch ends with the version line of the tree it reaches.

`use brew` asks first: it removes the links only when Homebrew's own copy would then answer `utilz` and every name whose link it removes. Otherwise it refuses, removing nothing, and names each link and the tree it serves, why no Homebrew copy would answer (Homebrew is not installed or not on `$PATH`, the formula is not, the formula has no such utility, its keg is not linked, Homebrew's bin is not on `$PATH`, or another copy comes first on `$PATH`), and the remedy: install, link or upgrade the formula, remove a dead link, or stay on dev or opt. It also refuses, removing nothing, when the check for a name cannot finish, and names that name and its check's exit status.

For a dev or opt link to answer, `~/.local/bin` must come before Homebrew's bin on `$PATH`. `utilz use` with no word fails, as doctor does, when a link is shadowed or the links serve more than one tree, and names what shadows or splits them. `use` is the one verb that points links; `utilz relink` is retired, and names `use`.

### `utilz upgrade`

Upgrade the tree this utilz runs from, as that tree is upgraded.

```bash
utilz upgrade
```

In the Homebrew install it runs `brew update` first, as a step of its own, so that `brew outdated` reads the current tap, then `HOMEBREW_NO_AUTO_UPDATE=1 brew upgrade utilz` when brew names Utilz as outdated. A failed update fails the upgrade, by name. In a dev checkout it runs `git pull --ff-only`, refused while the runtime set is dirty, then builds prez and showreel. In an opt install it changes nothing, names `utilz install --force` in the dev checkout, and says when that checkout is ahead.

### `utilz integration <verb>`

Editor-neutral integration manifest surface. Consumed by the Utilz Emacs bridge and by any future VSCode / Zed / Vim integration.

Verbs:

- `commands` — emit a TSV manifest of every utility that declares an `integration:` block in its YAML. One row per utility; columns are `name`, `description`, `input`, `output`, `flags` (tab-separated).

```bash
# Render as an aligned table
utilz integration commands | column -t -s$'\t'

# Feed directly to an integration (Emacs, VSCode, ...)
utilz integration commands
```

The walker lives in `opt/utilz/lib/common.sh` as `emit_integration_tsv`. The block's rules live beside it in `integration_fields`, which `utilz emacs doctor` asks too, so the manifest and the doctor cannot disagree (Highlander). Utilities without an `integration:` block are left out without a word. A utility whose yaml yq cannot read, whose `integration:` is not a map, whose `input` or `output` is missing or outside the bridge's sets, or whose `flags` is not a list is named on stderr and left out of the TSV. `flags` may be absent, for none.

### `utilz emacs <verb>`

Emacs-specific installer and health check for the Utilz elisp bridge. See `intent/st/ST0007/` for the design.

Verbs:

- `install --dest PATH [--symlink] [--force]` — copy (or symlink with `--symlink`) the canonical `static/emacs/utilz.el` to `PATH`. From the Homebrew install the symlink goes through `$(brew --prefix)/opt/utilz/libexec`, the path brew keeps across upgrades, never the versioned keg, so it follows each `brew upgrade utilz`. Idempotent: re-running with the same destination is a no-op; use `--force` to overwrite a differing destination. Prints the `(load ...)` line to add to your Emacs config.
- `doctor` — verify `utilz` is on `PATH` (reachable by Emacs child processes), every installed utility has a valid `integration:` block, and the canonical elisp file is present (info-level check; absence is expected pre-WP03).

```bash
# Install into Doom config as a symlink (follows each brew upgrade utilz)
utilz emacs install \
  --dest ~/.config/doom/custom/160-utilz.el \
  --symlink

# Then add the printed load statement to ~/.config/doom/config.el

# Health-check
utilz emacs doctor
```

Future integration targets (VSCode, Zed, Vim) are expected to land as parallel `utilz <editor>` subcommand families that consume the same `utilz integration commands` TSV.

## Commands for a dev checkout

These are the maintainer's, in a dev checkout (a clone of the repository). `utilz test` and `utilz generate` work there too.

### `utilz install`

Publish the checkout as an opt install, so the source can be worked on without disturbing the copy you use.

```bash
utilz install                 # publish to $UTILZ_INSTALL_PREFIX
utilz install --prefix DIR    # publish somewhere else
utilz install --force         # republish over an existing install
```

Where it publishes is `UTILZ_INSTALL_PREFIX`, which the sleeve sets (Molt's sleeve config). There is no default: unset is refused by name rather than guessed, because a publish to the wrong place looks exactly like a publish to the right one.

**It runs only in a dev checkout, and the checkout's runtime set must be clean**: what git names under `bin/`, `opt/`, `help/`, `static/` and `VERSION`, less each utility's tests. No flag overrides that, `--force` included, because the manifest records the commit the bytes came from. A file outside the runtime set, such as a doc or a board, does not block a publish.

`--force` is the one republish, and it replaces only a prefix whose manifest Utilz wrote, an old one included. install never touches the links in `~/.local/bin`: switching the shell is `utilz use`.

**A Homebrew keg is brew's.** The formula publishes with `utilz install --managed-by brew`, which records that in the manifest's header. From a keg or onto one, `install` refuses and names `brew upgrade utilz`, and `utilz test` names a clone of the repository to run the suites from.

---

## Architecture

### Directory Structure

```
$UTILZ_HOME/
├── bin/
│   ├── utilz              # Master dispatcher (executable)
│   └── mdagg -> utilz     # Utility symlinks
│
├── opt/
│   ├── utilz/
│   │   └── lib/
│   │       └── common.sh  # Shared functions library
│   │
│   └── mdagg/
│       └── mdagg          # Utility implementation (executable)
│
└── help/
    ├── utilz.md           # This file
    └── mdagg.md           # Utility help files
```

### How It Works

1. **Invocation**: User runs `mdagg config.yaml -o output.md`
2. **Dispatch**: `$UTILZ_HOME/bin/mdagg` is a symlink to `utilz`
3. **Detection**: `utilz` detects it was invoked as `mdagg` (via `$0`)
4. **Setup**: Sources common functions from `opt/utilz/lib/common.sh`
5. **Execution**: Dispatches to `$UTILZ_HOME/opt/mdagg/mdagg "$@"`

### Common Functions

All utilities have access to shared functions in `opt/utilz/lib/common.sh`:

**Logging**:

- `info "message"` - Informational message (blue ℹ)
- `success "message"` - Success message (green ✓)
- `warn "message"` - Warning message (yellow ⚠)
- `error "message"` - Error message (red ✗)
- `debug "message"` - Debug message (only if `UTILZ_DEBUG=1`)

**Utilities**:

- `show_help "utility"` - Display help from `help/{utility}.md`
- `check_command "cmd"` - Check if command exists
- `require_command "cmd" "install hint"` - Require command or exit with hint
- `parse_yaml "file.yaml" "query"` - Parse YAML using `yq`
- `require_yq` - Gate on the `yq` hard dependency; call ONCE before a loop, never per-iteration
- `each_utility [tree]` - Emit every installed utility name of a tree, the running one unless given, one per line; consume with `< <(each_utility)`, not a pipe

**Colors** (automatically disabled when not a TTY):

- `$BOLD`, `$RED`, `$GREEN`, `$YELLOW`, `$BLUE`, `$RESET`

---

## Adding a New Utility

### 1. Create the Implementation

```bash
# Create directory
mkdir -p $UTILZ_HOME/opt/myutil

# Create executable script
cat > $UTILZ_HOME/opt/myutil/myutil <<'EOF'
#!/usr/bin/env bash
# Implementation of myutil
set -euo pipefail

# $UTILZ_HOME and common functions are already available
info "Running myutil..."

# Your utility logic here
echo "Hello from myutil!"
success "Done!"
EOF

chmod +x $UTILZ_HOME/opt/myutil/myutil
```

### 2. Create a Symlink

```bash
cd $UTILZ_HOME/bin
ln -s utilz myutil
```

### 3. Create Help File

````bash
cat > $UTILZ_HOME/help/myutil.md <<'EOF'
# myutil - My Custom Utility

**Version**: run `myutil --version`

## Purpose
Brief description of what myutil does.

## Usage
```bash
myutil [options] <args>
````

## Examples

...
EOF

````

### 4. Test

```bash
# Run diagnostics
utilz doctor

# Test utility
myutil --help
myutil
````

---

## Multi-Language Support

Utilities can be written in any language:

### Bash/Zsh (Default)

```bash
#!/usr/bin/env bash
# opt/myutil/myutil
```

### Rust

```bash
#!/usr/bin/env bash
# opt/myutil/myutil (wrapper script)
exec "$UTILZ_HOME/opt/myutil/target/release/myutil" "$@"
```

Then build Rust binary in `opt/myutil/`:

```bash
cd $UTILZ_HOME/opt/myutil
cargo build --release
```

### Elixir

```bash
#!/usr/bin/env elixir
# opt/myutil/myutil
```

### Python (if you must)

```bash
#!/usr/bin/env python3
# opt/myutil/myutil
```

The dispatcher doesn't care about the implementation language - it just needs an executable file.

---

## Environment Variables

None is required. `$UTILZ_HOME` is not one to set: the dispatcher works it out from its own path and ignores an inherited value.

- `$UTILZ_INSTALL_PREFIX` - where `utilz install` publishes a dev checkout, set by the maintainer's sleeve; unset, a publish is refused by name
- `$UTILZ_LINK_DIR` - for Utilz's own tests only: the link directory `use` and doctor read in place of `~/.local/bin`

### Optional

- `$UTILZ_DEBUG` - Set to `1` to enable debug output
- `$NO_COLOR` - Set to disable colored output

---

## Dependencies

### Required

- Bash 3.2+ or Zsh (bash 3.2 is what macOS ships, and is the floor the framework targets)
- Standard Unix tools (`grep`, `sed`, `awk`, `cat`)
- `yq` -- the single YAML parser for all utility metadata. Required by the framework itself, not by any one utility: `utilz list`, `utilz doctor`, and `utilz generate` all read `opt/<name>/<name>.yaml` through it.
  ```bash
  brew install yq
  ```

### Utility-Specific

- **syncz**: `unison` for `--bidi` state-tracked mode (rsync fallback otherwise)
- **cleanz**: `exiftool` for `--image` metadata stripping

### Optional (Recommended)

- `bat` or `mdcat` - Better markdown rendering for help
  ```bash
  brew install bat
  ```

---

## Troubleshooting

### "Command not found: utilz"

**Problem**: brew's `bin` is not on your `$PATH`, or brew has not linked Utilz into it.

**Fix**:

```bash
brew link utilz
echo "$PATH" | tr ':' '\n' | grep -Fx "$(brew --prefix)/bin"   # prints the line when it is on PATH
```

If brew's `bin` is not on `$PATH`, add the line Homebrew's own installer gives, `eval "$(<brew's path>/brew shellenv)"`, to your shell config. In a dev checkout, `bin/utilz use dev` links it into `~/.local/bin`, which must come before Homebrew's bin on `$PATH`; `bin/utilz doctor` names the fix for whichever tree it runs in.

### "Utility implementation not found"

**Problem**: Symlink exists but implementation is missing.

**Fix**: Run `utilz doctor` to diagnose. Ensure:

1. `opt/{utility}/{utility}` exists
2. File is executable: `chmod +x opt/{utility}/{utility}`

### "yq: command not found"

**Problem**: YAML utilities require `yq`.

**Fix**:

```bash
brew install yq
```

### General Issues

Always start with:

```bash
utilz doctor
```

This will identify and suggest fixes for common configuration issues.

---

## Installed Utilities

Run `utilz list` to see all installed utilities, or check the list below:

### lnrel - Relative Symlink Creator

Creates symlinks with relative paths. Portable symlinks that survive directory tree moves.

See `utilz help lnrel` for details.

### mdagg - Markdown Aggregator

Concatenates multiple markdown files into a single document for PDF generation.

See `utilz help mdagg` for details.

---

## Version History

### 1.0.0 (2025-01-12)

- Initial release
- Core dispatcher framework
- `utilz help`, `utilz doctor`, `utilz list` commands
- Multi-language utility support
- First utility: `mdagg` (Markdown Aggregator)

---

## Contributing

This is a personal utilities framework, but the architecture can be adapted for team use.

### Design Principles

1. **Simple**: Each utility does one thing well
2. **Consistent**: Unified UX across all utilities
3. **Portable**: Works on any \*nix system
4. **Extensible**: Easy to add new utilities
5. **Self-contained**: Minimal external dependencies

---

## License

Personal use. Copyright © 2025 Matthew Sinclair.

---

**End of Utilz Help**
