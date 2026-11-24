# prez

**Version**: run `prez --version`
**Part of**: [Utilz Framework](../../README.md)

---

## Overview

Markdown to a self-contained HTML presentation. A pipeline, not a viewer: prez writes one `.html` file that opens offline, and the browser shows it.

Full reference: `utilz help prez` (or [`help/prez.md`](../../help/prez.md)).

---

## What is different about this utility

**prez is Rust.** Its layout differs from the usual `opt/<name>/<name>` script in three ways. Know them before you edit it.

```
opt/prez/
  prez              # bash SHIM: the dispatcher target. Resolves, builds if stale, execs.
  prez.yaml         # utility metadata
  README.md         # this file
  crate/            # the Rust crate: INDIVISIBLE, see below
    Cargo.toml      #   prez's package and the workspace root
    src/            #   the prez tool
    crates/         #   artifact (shared code) and showreel (the second binary)
    themes/         #   7 built-in themes    ) embedded at COMPILE time
    assets/         #   mermaid.min.js       ) with include_str!
    examples/       #   demo.md, test_pres.md
    test/           #   *.sh black-box suites, and the probes they run
    tests/          #   manifest.rs: the dependency budget gate
  test/
    prez.bats       # shim-level and framework-integration tests
```

**1. `opt/prez/prez` is a shim, not the tool.** One committed binary cannot serve both Ubuntu CI and macOS, and a repo that is cloned-and-symlinked has nowhere to ship per-platform artifacts. So the binary is built on the machine that runs it and the _shim_ is the portable thing. It also keeps `opt/prez/prez` inside the blocking shellcheck gate and inside doctor's existing model, both of which assume a script. The precedent is `ensure_venv()` in `common.sh`: an interpreted-runtime wrapper that provisions on first use, loudly.

The shim does resolve-ensure-exec and nothing else. Every flag, verb and refusal belongs to the tool, so `prez help` prints the tool's own usage rather than a second copy that can drift from it. (`prez --help` and `utilz help prez` show `help/prez.md`.) The shim builds the whole workspace, so it makes both binaries, `prez` and `showreel`. It runs `showreel` when the first argument is exactly `showreel`, and `prez` otherwise. In an install, the shim never builds: it runs the shipped binaries, or refuses if one is missing.

**2. `crate/` is indivisible.** `src/theme.rs` and `src/mermaid.rs` embed `../themes/*` and `../assets/*` with `include_str!` at compile time, so `src/`, `themes/` and `assets/` keep their exact sibling positions or the crate does not compile. Any tidier-looking layout that separates them is wrong by construction. It also means **editing a `.css` under `themes/` changes the binary**. So the shim's freshness check walks the whole crate, less `target/`, and not only `src/`.

**3. `crate/target/` is gitignored** by `opt/*/crate/target/` in the repo root `.gitignore`. The pattern is general, so a later Rust utility gets the same rule.

---

## Requirements

`cargo`, on the machine that builds:

```bash
brew install rust
```

The built binary has **no runtime dependencies**. Its crates, the themes and the mermaid library are compiled in. `prez.yaml` therefore declares `dependencies: []`: cargo is a build-time need, surfaced by the shim's refusal and by a conditional line in `utilz doctor` that appears only when a crate is present. Declaring it as a dependency would make doctor report it missing on every machine that has already built.

Only `pdf`, `present` and `prez showreel video` need a browser. The tool probes for one and refuses naming every path it tried, so doctor does not repeat that check. `prez showreel video` also needs ffmpeg, which `prez.yaml` declares as an optional dependency.

---

## Usage

`utilz help prez` (or `prez --help`) shows the synopsis, the flags and the examples.

---

## Testing

```bash
utilz test prez
```

does a release build, then runs three kinds of suite. It finds them by convention, with no prez special case:

| Source             | Suite                                                     |
| ------------------ | --------------------------------------------------------- |
| `crate/Cargo.toml` | `cargo test --workspace`: the modules of every crate      |
| `test/*.bats`      | the shim and framework integration                        |
| `crate/test/*.sh`  | black-box ATs against the built binary, always `--strict` |

**Every `.sh` in `crate/test/` is a suite.** A suite that is there but not executable fails the run. It is not skipped.

`--strict` is always on. Some checks need a browser, node or ffmpeg. Without `--strict`, a machine that lacks them would report a pass. With it, a skip is printed, counted, and fails the run.

`PREZ_TEST_BROWSER` overrides browser resolution inside the acceptance suite. Point it at a path that does not exist to test the no-browser refusal on a machine that _has_ Chrome:

```bash
PREZ_TEST_BROWSER=/nonexistent crate/test/acceptance.sh --strict   # expect exit 1
```

Without this variable, the control that proves `--strict` works cannot fail on a machine that has Chrome.

---

## Provenance

The crate came from an upstream project, where its name was `geopres`. Steel thread ST0010 records the import. Git history holds the rest.
