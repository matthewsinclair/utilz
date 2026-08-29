# prez

**Version**: 1.0.0
**Part of**: [Utilz Framework](../../README.md)

---

## Overview

Markdown to a self-contained HTML presentation. A pipeline, not a viewer -- prez writes one `.html` file that opens offline, and the browser does the presenting.

Full reference: `utilz help prez` (or [`help/prez.md`](../../help/prez.md)).

---

## What is different about this utility

**prez is Rust.** It is the first compiled utility in Utilz, so its layout departs from the usual `opt/<name>/<name>` script in three ways worth knowing before you edit it.

```
opt/prez/
  prez              # bash SHIM -- the dispatcher target. Resolves, builds if stale, execs.
  prez.yaml         # utility metadata
  README.md         # this file
  crate/            # the Rust crate -- INDIVISIBLE, see below
    Cargo.toml      #   name = "prez"; comrak is the only dependency
    src/            #   the tool
    themes/         #   7 built-in themes    ) embedded at COMPILE time
    assets/         #   mermaid.min.js       ) with include_str!
    examples/       #   demo.md, test_pres.md
    test/           #   acceptance.sh -- black-box ATs
  test/
    prez.bats       # shim-level and framework-integration tests
```

**1. `opt/prez/prez` is a shim, not the tool.** One committed binary cannot serve both Ubuntu CI and macOS, and a repo that is cloned-and-symlinked has nowhere to ship per-platform artifacts. So the binary is built on the machine that runs it and the _shim_ is the portable thing. It also keeps `opt/prez/prez` inside the blocking shellcheck gate and inside doctor's existing model, both of which assume a script. The precedent is `ensure_venv()` in `common.sh`: an interpreted-runtime wrapper that provisions on first use, loudly.

The shim does resolve-ensure-exec and nothing else. Every flag, verb and refusal belongs to the tool, so `prez --help` is the tool's own help rather than a second copy that can drift from it.

**2. `crate/` is indivisible.** `src/theme.rs` and `src/mermaid.rs` embed `../themes/*` and `../assets/*` with `include_str!` at compile time, so `src/`, `themes/` and `assets/` keep their exact sibling positions or the crate does not compile. Any tidier-looking layout that separates them is wrong by construction. It also means **editing a `.css` under `themes/` changes the binary** -- which is why the shim's freshness check watches those directories and not just `src/`.

**3. `crate/target/` is gitignored** by `opt/*/crate/target/` in the repo root `.gitignore` -- by convention rather than by name, so the next Rust utility inherits the fence. That rule landed _before_ the first in-tree build ever ran.

---

## Requirements

`cargo`, once, on the machine that builds:

```bash
brew install rust
```

The built binary has **no runtime dependencies** -- comrak is compiled in, and so are the themes and the mermaid library. `prez.yaml` therefore declares `dependencies: []`: cargo is a build-time need, surfaced by the shim's refusal and by a conditional line in `utilz doctor` that appears only when a crate is present. Declaring it as a dependency would make doctor report it missing on every machine that has already built.

A browser is needed only by the `pdf` and `present` verbs. The tool probes for one and refuses naming every path it tried, so doctor does not duplicate a refusal the tool already makes well.

---

## Usage

```bash
prez build   <deck.md> [-o out.html] [--theme=T] [--watch]
prez pdf     <deck.md> [-o out.pdf]  [--theme=T] [--paper=WxH] [--browser=PATH]
prez present <deck.md> [--theme=T] [--browser=PATH]
```

```bash
# Build one of the shipped decks
prez build examples/demo.md -o /tmp/demo.html

# A theme off the search path -- prez says which directory dressed the deck
PREZ_THEME_PATH=~/themes prez build deck.md --theme=house
```

---

## Testing

```bash
utilz test prez
```

runs three suites, discovered by convention rather than by a prez special case:

| Source                     | Suite                                                     |
| -------------------------- | --------------------------------------------------------- |
| `crate/Cargo.toml`         | `cargo test` -- the modules                               |
| `test/*.bats`              | the shim and framework integration                        |
| `crate/test/acceptance.sh` | black-box ATs against the built binary, always `--strict` |

`--strict` is not optional here. Six of the acceptance checks need a browser, and without `--strict` a browserless machine reports "everything that ran passed" -- which is the same ambiguity one level down. A skip is printed, counted, and fails the run.

`PREZ_TEST_BROWSER` overrides browser resolution inside the acceptance suite. Point it at a path that does not exist to exercise the browserless refusal path on a machine that _has_ Chrome:

```bash
PREZ_TEST_BROWSER=/nonexistent crate/test/acceptance.sh --strict   # expect exit 1
```

Without that hook the control proving `--strict` matters cannot be exercised anywhere Chrome is installed, which makes it a control that can never go red.

---

## Provenance

The crate was hoisted from the Geodica `_tools` estate, where it was `geopres`. It arrived by `git archive` at a recorded pin, was renamed wholesale, and carries its own acceptance suite with it. Steel thread: `intent/st/ST0010`. The hoist adaptations are a single idempotent script attached to that thread, so a moving pin costs a re-run rather than a re-remembering.

Net-new behaviour added here rather than upstream is marked in the source by its acceptance criterion -- currently AC14, announce-on-resolve.
