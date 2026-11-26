# Utilz - Universal Utilities Framework

**Version**: run `utilz version`
<!-- NO VERSION LITERAL IN THIS FILE OR ANY HELP FILE, AND THIS ONE LEARNED IT
     FIRST: hardcoding the framework version here drifted it to 2.2.0 while
     2.4.0 shipped. The fix was applied to this file alone and left in fifteen
     others, where it drifted again: cleanz's README said 1.1.0 against a
     yaml of 1.2.0, and todo's help AND README said 1.0.0 against 1.1.0. The
     version has ONE home: the utility's yaml, or the file its version_file
     points at. A test in common_lib.bats holds every help file and every
     utility README to it. -->

**Author**: Matthew Sinclair
**Location**: worked out from the dispatcher's own path: the Homebrew install (`$(brew --prefix)/opt/utilz/libexec`), or, for the maintainer, a dev checkout or an opt install published from one. `utilz version` names which one answered.

---

## Overview

**Utilz** (with a 'z') is a unified framework for managing personal command-line utilities across multiple machines. It provides:

- **Single dispatcher**: All utilities are symlinks to a master `utilz` script
- **Consistent UX**: Unified help, error handling, and output formatting
- **Easy management**: `utilz generate <name>` adds a utility, with its metadata, help page, tests and link
- **Installed with Homebrew**: one formula puts every utility on `$PATH`
- **Multi-language support**: each utility is a bash script, which can run a tool beside it in another language, as prez does in Rust and arngz in Lua

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

A clone of the repository is the maintainer's dev checkout; devbin's `bin/devbin use`, run there, switches the shell between it, an opt install and this one, and the commands that only work there are under "Commands for a dev checkout" below.

### First Utility

```bash
# All utilities should already be set up
# Try the markdown aggregator:
mdagg --help
```

---

## Commands

### `utilz help [utility|verb]`

Show help for Utilz, a specific utility, or a verb on this page: a verb shows its own section. A name that is neither says where to look.

```bash
# Show this help
utilz help

# Show help for mdagg utility
utilz help mdagg

# Show the section on utilz upgrade
utilz help upgrade
```

`-h` and `--help` are accepted as aliases, and take the same optional utility or verb argument:

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
  with, and each dispatcher link still targets `utilz`. In a source checkout there is no manifest, and doctor says so rather
  than passing silently. An opt install with a manifest in an old form fails, naming `bin/devbin install --force`; a Homebrew install with one is noted, naming `brew upgrade utilz`, and fails nothing.

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

Every answer carries **both** versions in play, the framework's and the utility's, because being handed one of them is how a bug report arrives missing the half that explains it. **There is no `v` prefix anywhere**: it is noise, and it was the only thing making the framework's line a different shape from a utility's.

```bash
$ utilz version          # --version is accepted as an alias
utilz 2.7.0 (brew, 0123456789ab)

$ utilz mdagg --version  # either invocation form, byte-identical
mdagg 2.7.0 (brew, 0123456789ab)
utilz:2.7.0/mdagg:1.0.0
Markdown aggregator

$ mdagg --version
mdagg 2.7.0 (brew, 0123456789ab)
utilz:2.7.0/mdagg:1.0.0
Markdown aggregator
```

**Both invocation forms give the same bytes**: `bin/utilz` answers `--version` from one place for both.

Utilz's own answer is **one line**, the version line every tool released through Homebrew prints (the dev, opt, brew contract): `utilz <version> (<tree>, <commit>)`. It names **which tree replied**, dev, opt or brew, and the commit it came from: in opt and brew the one its manifest records, in dev HEAD, followed by `+dirty` while a file of the runtime set is uncommitted. `(dev, unknown)` means git cannot read the checkout, and `(<tree>, old manifest)` an install from before the contract. The line names no path: where the running copy lives is the answer `command -v utilz` gives. A reader reads the line up to its closing parenthesis and ignores anything after it. A utility's answer opens with that line under the utility's own name, eg `mdagg 2.7.0 (brew, 0123456789ab)`, so a reader of the first line reads every tool's answer alike. The version, the tree and the commit are Utilz's, because a utility comes only with its tree. The pair and the description follow.

`-v` is deliberately unbound: it reads as a verbose flag, and no utility binds it.

### `utilz use` (retired)

devbin switches the shell between Utilz's trees, as it does for every tool it drives (devbin#0326). Run it in a Utilz checkout:

```bash
bin/devbin use dev     # point every link at the dev checkout
bin/devbin use opt     # point every link at the opt install
bin/devbin use brew    # remove them, so Homebrew's own links answer
bin/devbin use         # report which tree they serve, and change nothing
```

`utilz use` refuses, naming it, and so does `utilz relink`. **No link means brew**: a Homebrew user who never runs `use` has brew's links, and `bin/devbin use brew` returns to them. For a dev or opt link to answer, `~/.local/bin` must come before Homebrew's bin on `$PATH`; `utilz doctor` fails, naming what shadows or splits the links, when a link is shadowed or the links serve more than one tree. After a switch, run `hash -r` in an open bash, or `rehash` in zsh.

### `utilz upgrade`

Upgrade the tree this utilz runs from, as that tree is upgraded.

```bash
utilz upgrade
```

In the Homebrew install it runs `brew update` first, as a step of its own, so that `brew outdated` reads the current tap, then `HOMEBREW_NO_AUTO_UPDATE=1 brew upgrade utilz` when brew names Utilz as outdated. A failed update fails the upgrade, by name. In a dev checkout it runs `git pull --ff-only`, refused while the runtime set is dirty, then runs `bin/devbin build`, which builds prez and showreel. In an opt install it changes nothing, names `bin/devbin install --force` in the dev checkout, and says when that checkout is ahead.

### `utilz integration <verb>`

Editor-neutral integration manifest surface. Consumed by the Utilz Emacs bridge and by any future VSCode / Zed / Vim integration.

Verbs:

- `commands`: emit a TSV manifest of every utility that declares an `integration:` block in its YAML. One row per utility; columns are `name`, `description`, `input`, `output`, `flags` (tab-separated).

```bash
# Render as an aligned table
utilz integration commands | column -t -s$'\t'

# Feed directly to an integration (Emacs, VSCode, ...)
utilz integration commands
```

The walker lives in `opt/utilz/lib/common.sh` as `emit_integration_tsv`. The block's rules live beside it in `integration_fields`, which `utilz emacs doctor` asks too, so the manifest and the doctor cannot disagree (Highlander). Utilities without an `integration:` block are left out without a word. A utility whose yaml yq cannot read, whose `integration:` is not a map, whose `input` or `output` is missing or outside the bridge's sets, or whose `flags` is not a list is named on stderr and left out of the TSV. `flags` may be absent, for none.

### `utilz emacs <verb>`

Emacs-specific installer and health check for the Utilz elisp bridge. Steel thread ST0007 holds the design.

Verbs:

- `install --dest PATH [--symlink] [--force]`: copy (or symlink with `--symlink`) the canonical `static/emacs/utilz.el` to `PATH`. From the Homebrew install the symlink goes through `$(brew --prefix)/opt/utilz/libexec`, the path brew keeps across upgrades, never the versioned keg, so it follows each `brew upgrade utilz`. Idempotent: re-running with the same destination is a no-op; use `--force` to overwrite a differing destination. Prints the `(load ...)` line to add to your Emacs config.
- `doctor`: verify `utilz` is on `PATH` (reachable by Emacs child processes), every installed utility has a valid `integration:` block, and the canonical elisp file is present (an info-level check).

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

These are the maintainer's, in a dev checkout (a clone of the repository).

### `utilz install` (retired)

devbin publishes the checkout as an opt install, so the source can be worked on without disturbing the copy you use (devbin#0326). Run it in the checkout:

```bash
bin/devbin install                 # publish to install.prefix
bin/devbin install --prefix DIR    # publish somewhere else
bin/devbin install --force         # republish over an existing install
```

`utilz install` refuses, naming it. Where it publishes is `install.prefix` in `bin/.devbin/config.yaml`, and `--prefix DIR` serves a single publish. It runs `bin/devbin build` first, which builds prez and showreel, and **the checkout's runtime set must be clean**: what git names under `bin/`, `opt/`, `help/`, `static/` and `VERSION`, less each utility's tests, because the manifest records the commit the bytes came from. A file outside the runtime set, such as a doc or a board, does not block a publish. `--force` is the one republish.

**A Homebrew keg is brew's.** The formula publishes with `bin/devbin install --managed-by brew`, which records that in the manifest's header. devbin refuses to write into a keg, naming `brew upgrade utilz`, and `utilz test` in a keg names a clone of the repository to run the suites from.

### `utilz test [utility]`

Run the test suites: every suite with no name, a utility's own with its name, and the framework's own with `utilz test utilz`.

```bash
utilz test                    # every suite
utilz test mdagg              # mdagg's suite
utilz test utilz              # the framework's own suite
```

It needs `bats`, and it refuses in an install: the suites rewrite `bin/`, which is exactly what the install's manifest checksums, so an install would report drift nobody caused. The refusal says where to run the suites instead.

### `utilz generate <name> [description] [author]`

Scaffold a new utility: its directory under `opt/`, with its implementation, `VERSION`, metadata, README and tests; its page in `help/`; and its link in `bin/`. The author defaults to git's `user.name`.

```bash
utilz generate mytool "Does something useful"
```

It stamps `utilz_version` from the framework's own `VERSION` (major only), so a generated utility is always compatible with the framework that generated it.

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

Every utility can use the shared functions in `opt/utilz/lib/common.sh`. The [Developer Guide](../docs/developer-guide.md#using-the-common-library) lists them.

---

## Adding a New Utility

Run `utilz generate <name>`, as above. The [Developer Guide](../docs/developer-guide.md) covers the layout, the metadata and the tests.

---

## Multi-Language Support

The dispatcher runs `opt/<name>/<name>`, which is always a bash script. A tool in another language sits beside it, as prez's Rust crate and arngz's Lua engine do. The [Developer Guide](../docs/developer-guide.md#multi-language-utilities) says which languages new code may use.

---

## Environment Variables

None is required. `$UTILZ_HOME` is not one to set: the dispatcher works it out from its own path and ignores an inherited value.

- `$UTILZ_LINK_DIR` - for Utilz's own tests only: the link directory doctor reads in place of `~/.local/bin`

### Optional

- `$UTILZ_DEBUG` - Set to `1` to enable debug output

Colour is on when stdout is a terminal, and off when it is not.

---

## Dependencies

### Required

- Bash 3.2 or later (bash 3.2 is what macOS ships, and is the floor the framework targets)
- Standard Unix tools (`grep`, `sed`, `awk`, `cat`)
- `yq`: the single YAML parser for all utility metadata. Required by the framework itself, not by any one utility: `utilz list`, `utilz doctor`, and `utilz generate` all read `opt/<name>/<name>.yaml` through it.
  ```bash
  brew install yq
  ```

### Utility-Specific

- **syncz**: `unison` for `--bidi` state-tracked mode (rsync fallback otherwise)
- **cleanz**: `exiftool` for `--image` metadata stripping

### Optional (Recommended)

- `glow`, or else `bat` - Better markdown rendering for help
  ```bash
  brew install glow
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

If brew's `bin` is not on `$PATH`, add the line Homebrew's own installer gives, `eval "$(<brew's path>/brew shellenv)"`, to your shell config. In a dev checkout, `bin/devbin use dev` links it into `~/.local/bin`, which must come before Homebrew's bin on `$PATH`; `bin/utilz doctor` names the fix for whichever tree it runs in.

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

## License

MIT. See [LICENSE](../LICENSE).

---

**End of Utilz Help**
