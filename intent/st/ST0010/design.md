# ST0010 Design -- utilz prez

As-designed decisions for the hoist. Rationale and history live in this thread's Context; this file states what gets built and why each choice beat its alternative. Owner: vc. Builders: cc (WP-02, WP-03), vc (WP-01, WP-04).

## 1. Layout

```
opt/prez/
  prez              # bash shim -- the dispatcher target (opt/<name>/<name> convention)
  prez.yaml         # utility metadata
  README.md         # per-utility readme (repo convention)
  crate/            # the Rust crate, hoisted AS ONE UNIT from the pin
    Cargo.toml      #   name = "prez", version = "1.0.0"
    Cargo.lock
    src/            #   14 modules
    themes/         #   7 built-in themes -- include_str! siblings, do not separate
    assets/         #   mermaid.min.js (3.5MB) -- include_str! sibling, do not separate
    examples/       #   demo.md, test_pres.md
    test/           #   acceptance.sh, at04/at12 probes, theme-legibility-probe.html
  test/
    prez.bats       # shim-level BATS (see 5)
bin/prez -> utilz   # standard dispatcher symlink
help/prez.md        # help file (repo convention)
```

**The crate directory is indivisible.** `src/theme.rs:55-61` and `src/mermaid.rs:21` embed `../themes/*` and `../assets/*` at COMPILE time, so `src/`, `themes/`, `assets/` keep their exact sibling positions or the crate does not compile. Any tidier-looking layout that separates them is wrong by construction.

**The dispatcher is untouched.** `bin/utilz` requires `opt/prez/prez` to exist, be a regular file, and be executable. The shim satisfies that; zero framework dispatch changes.

## 2. The shim (`opt/prez/prez`)

Bash, inside the shellcheck gate, on the `ensure_venv()` precedent (an interpreted-runtime wrapper that provisions on first use, loudly):

1. `BINARY="$UTILZ_HOME/opt/prez/crate/target/release/prez"`.
2. **Freshness**: rebuild when the binary is missing OR any file under `crate/src crate/themes crate/assets crate/Cargo.*` is newer than it (`find -newer`, bash 3.2-safe). A stale binary after `git pull` is the silent failure this check exists for.
3. **Build**: `info` message, then `cargo build --release --manifest-path "$UTILZ_HOME/opt/prez/crate/Cargo.toml"`. No `CARGO_TARGET_DIR` redirect -- Utilz is not in Dropbox (verified: bare local remote; see Context) -- so the default in-crate `target/` is correct and `.gitignore` fences it.
4. **Refusal**: no `cargo` -> `error` + remedy `brew install rust`, exit non-zero, BEFORE any build attempt. A missing toolchain is a named finding, never a bare command-not-found.
5. `exec "$BINARY" "$@"` -- the shim decides nothing about presentations. Thin Coordinator: resolve, ensure, exec.

The build-verb collision is why there is no `prez build-self`: `prez build <deck>` already means "build the deck" in the tool's own grammar. Auto-provision-on-use avoids minting a colliding verb.

## 3. Rename sweep (geopres -> prez), at hoist time, in Utilz

| Site                          | Change                                                         |
| ----------------------------- | -------------------------------------------------------------- |
| `Cargo.toml`                  | `name = "prez"`, `version = "1.0.0"`, description reworded     |
| `src/main.rs`                 | error prefix `geopres:` -> `prez:`                             |
| `src/args.rs` USAGE           | tool name + examples                                           |
| `src/theme.rs:80`             | `SEARCH_PATH` const: `GEOPRES_THEME_PATH` -> `PREZ_THEME_PATH` |
| `test/acceptance.sh` + probes | binary name, env var                                           |
| refusal texts                 | re-verified against AT wording after the sweep                 |

**`PREZ_THEME_PATH` is named HERE and this file is its one owner.** `_tools`' rewritten shim consumes it. Clean break: no `GEOPRES_THEME_PATH` back-compat alias -- one consumer, coordinated cutover, and a wrong var name fails loudly (the resolver refuses, naming the search path it used).

Version: 1.0.0 on arrival, matching every other utility's arrival convention; `Cargo.toml` is the single source (`CARGO_PKG_VERSION` drives `--version`), `prez.yaml` mirrors it.

## 4. `prez.yaml`

`version: 1.0.0`; `utilz_version: "^2.5.0"` (prez needs this release's test driver, not just dispatch); `dependencies: []` -- the built binary is self-contained. `cargo` is a BUILD-time need surfaced by the shim's refusal and by doctor's manual optional checks (one line added beside glow/exiftool: cargo, noted as "prez: builds on first use"). A browser is a runtime need only for `pdf`/`present` verbs, and the binary already probes and refuses with the paths it tried -- doctor does not duplicate a refusal the tool itself makes well.

## 5. Test driver (`utilz test prez`)

Convention-driven extension to `run_tests()` in `common.sh`, not a prez special case -- the next Rust utility inherits it:

- `opt/<name>/crate/Cargo.toml` exists -> run `cargo test --manifest-path ...` first.
- `opt/<name>/test/*.bats` -> BATS as today (prez ships shim-level tests: version/help via dispatcher, refusal-without-cargo shape, freshness rebuild trigger).
- `opt/<name>/crate/test/acceptance.sh` exists -> run it `--strict` ALWAYS. A machine without Chrome/Node fails with the skip named, deliberately: six of nine ATs degrade to skips otherwise, and a browserless green is the exact adjacent-measure failure this thread inherits the vocabulary for.

Suite counters must aggregate all three sources or fail loudly; `each_utility()` consumption stays process-substitution (existing contract).

## 6. CI (`.github/workflows/tests.yml`)

Two NEW jobs; the four existing jobs untouched:

- **`rust`** (matrix: ubuntu-latest, macos-latest): checkout, rustc via the runner's toolchain, `actions/setup-node@v4` with Node 26 (AT12 needs global WebSocket), `cargo build --release`, `cargo test`, then `test/acceptance.sh --strict`. The job must PROVE the browser was found (assert the probe output names one) -- a skip surviving into CI green is the measured failure mode.
- **`clippy`** (ubuntu-latest): `cargo clippy --all-targets -- -D warnings`. **Blocking from day one** -- verified clean at the source today (6.34s build, zero warnings), and the shellcheck gate's non-blocking era is the recorded argument against phasing.
- `test-summary` gains both in `needs` and its result checks.

No cargo caching at the start: a 6.34s clean build does not earn cache complexity or a `hashFiles` key that can drift (Conflab's invisible-consumer lesson). Add caching only when measurement says the build got slow.

## 7. Hoist mechanics (WP-03 order)

1. `.gitignore` gains `opt/prez/crate/target/` -- BEFORE any in-tree build ever runs (first build otherwise drops a multi-hundred-MB untracked tree).
2. `intent lang init rust` (config declares rust; critic-rust + rule pack arrive). Note: critic-rust arms 1 of 7 rules -- clippy in CI is the real gate; the critic is advisory here.
3. Hoist FROM GIT at the pin: `git -C ~/Dropbox/Geodica/_tools archive <PIN> native/rust/geopres | tar -x` into `opt/prez/crate/` (tracked content only -- the 11 untracked `pres_*.html` litter files never travel; `cp -R` is forbidden for exactly that reason). Record the pin sha in impl.md.
4. Rename sweep (3), then shim + yaml + symlink + help + README.
5. Announce-on-resolve (the one net-new crate behaviour, deferred out of `_tools` to keep the pin narrow): when a theme name resolves from `PREZ_THEME_PATH` rather than built-ins, say so on stderr -- local-wins shadowing must be visible, or same-command-different-output returns through the side door AC13 just closed. Contract states local-wins explicitly.

## 8. Contract map (WP-01 completes this in canon)

`_tools` AC02-AC10 + AC13 transcribe, renumbered prez-AC01..prez-AC10, reworded for home and name. AC01/AC11/AC12 stay behind (Dropbox hygiene; estate binding; brand theme) -- recorded with verification, not just assertion. New criteria minted here: gitignore-before-build; announce-on-resolve + local-wins; the `--strict` CI browser proof; the liftability refusal (unknown theme refuses naming built-ins + search path; verified shape already green on an estate-absent copy). Every transcribed green arrives UNVERIFIED and is re-proven by instruments run in this repo -- 111 unit tests, 9 ATs, AT12 (`bfb33cd` + the script-half hardening), legibility probe (post-`ec3564a`).

AT discipline notes carried from `_tools` (each one paid for): never pipe a command whose exit code is the assertion; a grep targets a sentinel the artifact can only contain if the thing is real; point diagram checks at `test_pres.md` (demo.md's `mermaid: true` is documentation inside a fence); a contrast figure cites selector + palette + commit; after repairing a control, re-run the whole control.

## 9. Standing rule minted by this thread

**The second Rust crate in Utilz makes a workspace mandatory** -- root manifest with EXPLICIT `resolver = "3"` -- before it lands. At one crate a workspace buys nothing; at two, the absence is Conflab's 396 duplicate builds with a day's cleanup attached (`f9875541`). This sentence exists so "we will deal with it later" has a written trigger.

## Non-decisions, named

- No `utilz generate` Rust scaffolding -- one crate does not justify template machinery; revisit at the second crate alongside the workspace rule.
- No `integration:` YAML block for prez v1 -- the Emacs bridge can bind later; nothing in this thread depends on it.
- No cargo caching, no toolchain pinning beyond CI's runner default -- measured 6.34s says not yet.
