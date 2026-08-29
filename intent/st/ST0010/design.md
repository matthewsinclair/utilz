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

**The default theme belongs to the CALLER, not to a name** (hv, 2026-08-29). prez's own no-flag default stays `simple`; there is no theme named `default` in either tree, and the estate's default arrives as `geodica present` passing `--theme=geodica`. hv's framing is the pattern every later consumer follows: geodica is a USER of prez, not a co-owner -- a user passes an argument, it does not override its library's defaults. The alternative (a `default` name the estate shadows) was killed by measurement: `theme.rs:87-91` short-circuits to `built_in("simple")` when no theme is given and never consults the search path, so the override would have been silently ignored for exactly the users who typed nothing (`_tools-vc`, magenta-marker test, both directions).

## 3. Rename sweep (geopres -> prez), at hoist time, in Utilz

| Site                          | Change                                                        |
| ----------------------------- | ------------------------------------------------------------- |
| `Cargo.toml`                  | `name = "prez"`, `version = "1.0.0"`, description reworded    |
| `src/main.rs`                 | error prefix `geopres:` -> `prez:`                            |
| `src/args.rs` USAGE           | tool name + examples                                          |
| `src/theme.rs:80`             | `SEARCH_PATH` const: `GEOPRES_THEME_PATH` -> `PREZ_THEME_PATH` |
| `test/acceptance.sh` + probes | binary name, env var                                          |
| refusal texts                 | the refusal NAMES the variable, and an AT asserts the refusal names every directory searched -- `theme.rs`, the refusal string and that AT change together or the suite goes red on the rename itself (`_tools-cc`'s flag) |
| **the sentinel pair**         | `acceptance.sh`'s `SENTINEL=` literal and the identical notes payload in `examples/demo.md` (twice) -- rename one without the other and AC03's leak test greps the artifact for a string that is supposed to be absent (`utilz-cc`'s find) |

**Do the sweep ATOMICALLY across every file at once, not file by file.** Three coordinated sets now exist (the theme const + refusal + its AT; the sentinel pair; the binary name throughout), and coordination by construction beats coordination by remembering. `utilz-cc`'s first pass measured 110 occurrences across 19 files with 0 residual.

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
3. Hoist FROM GIT at the pin -- **`3e16597`** (the mermaid fix `8fba69b` plus the probe hardening on top; identical `src/`, 14x smaller instrument blind spot): `git -C ~/Dropbox/Geodica/_tools archive 3e16597 native/rust/geopres | tar -x` into `opt/prez/crate/` (tracked content only -- the 11 untracked `pres_*.html` litter files never travel; `cp -R` is forbidden for exactly that reason). At the pin: 10 ATs `--strict` 0 skipped, 111 unit tests. Record the sha in impl.md.
4. Rename sweep (3), then shim + yaml + symlink + help + README.
5. Announce-on-resolve moved to WP-06 (section 11) -- it lands where `theme.rs` is already open, and `--theme-path` makes it load-bearing again rather than hygiene.

## 8. Contract map (WP-01 completes this in canon)

`_tools` AC02-AC10 + AC13 transcribe, renumbered prez-AC01..prez-AC10, reworded for home and name. AC01/AC11/AC12 stay behind (Dropbox hygiene; estate binding; brand theme) -- recorded with verification, not just assertion. New criteria minted here: gitignore-before-build; announce-on-resolve + local-wins; the `--strict` CI browser proof; the liftability refusal (unknown theme refuses naming built-ins + search path; verified shape already green on an estate-absent copy). Every transcribed green arrives UNVERIFIED and is re-proven by instruments run in this repo -- 111 unit tests, 9 ATs, AT12 (`bfb33cd` + the script-half hardening), legibility probe (post-`ec3564a`).

Two NON-TEST gates are minted here and satisfied by named evidence at WP-04, because the automated suite provably cannot stand in for either. **AC16, the eyeball gate**: a human renders every theme and LOOKS at it. On `_tools`, hv's screenshots found four defects a full day of tests had missed, and the diagram-font defect passed a GREEN determinism probe -- deterministically wrong is still wrong. The rule, in `_tools-cc`'s words: *a green determinism probe is a licence to look at the output, not a substitute for looking at it.* **AC17, build provenance**: the binary under test is built from a clean checkout of the pin, recorded beside the numbers. At the pin `_tools-vc` found a binary predating its own source commit by three and a half minutes -- the green was true but unattributable. The first Utilz build at `3e16597` is the first moment the sha and the binary are provably one artifact; if our numbers disagree with theirs, that seam is checked BEFORE the port is suspected.

**Two known harness causes will redden the first Linux run, both inherited and neither a port defect** (AC18 covers the first): the browser-probe two-list drift, and `AT01` sizing the binary with `stat -f %z`, which is BSD-only -- on Ubuntu it returns nothing, the size reads 0, and an 8 MB ceiling check fails on a correct build. The second is the day's cleanest specimen of the class: it measures *stat succeeded* while being named *the binary is small enough*, it fails soft rather than erroring, and it can only fire on the platform nobody develops on. Check both before suspecting the port.

AT discipline notes carried from `_tools` (each one paid for): never pipe a command whose exit code is the assertion; a grep targets a sentinel the artifact can only contain if the thing is real; point diagram checks at `test_pres.md` (demo.md's `mermaid: true` is documentation inside a fence); a contrast figure cites selector + palette + commit; after repairing a control, re-run the whole control.

## 9. Standing rule minted by this thread

**The second Rust crate in Utilz makes a workspace mandatory** -- root manifest with EXPLICIT `resolver = "3"` -- before it lands. At one crate a workspace buys nothing; at two, the absence is Conflab's 396 duplicate builds with a day's cleanup attached (`f9875541`). This sentence exists so "we will deal with it later" has a written trigger.

## 10. Theme addressing split + `--theme-path` (WP-06, after WP-04, before WP-05)

hv's two CLI asks, designed on `_tools-vc`'s measurements. The resolver already speaks colon-separated lists (`std::env::split_paths`) and already tries `<dir>/<name>/theme.css` then `<dir>/<name>.css`; what is missing is the CLI door and the mode split:

- **`--theme-path=PATHSTR`** prepends to `PREZ_THEME_PATH` for the invocation. Prepend, not replace: the flag and the shim's env compose instead of excluding each other.
- **`--theme=NAME` resolves names ONLY** -- search path, then built-ins, never the working directory. The defect this kills was measured: `--theme=simple` run beside a `./simple/` directory resolved the local one, run anywhere else the built-in -- same command, same binary, different theme, silently, because `path.exists()` was tried first.
- **`--theme-file=FILE` resolves a path ONLY**, mutually exclusive with `--theme`, refusing with no-such-file -- a theme-roster refusal on a mistyped filename sends the reader hunting a roster for a typo.
- **Front matter splits identically** (`theme:` name, `theme-file:` deck-relative path) or the ambiguity moves into the deck and travels with it.
- **`--theme=./x.css` breaks, deliberately, now** -- pre-release, in the same move as the rename, the cheapest moment this break will ever have.
- **Announce-on-resolve (AC14) lands here**: a name resolving off the search path says which directory won, on stderr. Under `--theme-path` a user with two directories makes shadowing ordinary rather than exotic.

AT14 is written red-first against the PINNED binary (cwd-identical resolution fails today) before any of this is coded. Sequenced after WP-04 so the carried contract is proven before the surface moves.

## 11. Default theme polish (WP-05, post-hoist, LAST -- after WP-06)

hv: prez's out-of-box look should be "basic but cool enough". `simple` is the plainest of the seven at 96 lines and is the no-flag default, so this is a real gap -- and it is cleanly prez's business now that geodica is just a caller. Deliberately sequenced after validation: it touches nothing the pin or WP-04 depend on, and a theme edit mid-validation would invalidate contrast figures the validation is busy citing.

## Non-decisions, named

- No `utilz generate` Rust scaffolding -- one crate does not justify template machinery; revisit at the second crate alongside the workspace rule.
- No `integration:` YAML block for prez v1 -- the Emacs bridge can bind later; nothing in this thread depends on it.
- No cargo caching, no toolchain pinning beyond CI's runner default -- measured 6.34s says not yet.
