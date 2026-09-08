# ST0013: prez theme addressing -- Design

## D1 -- The defect, measured rather than described

AC01 says `--theme=simple` beside a `./simple/` directory "resolved the local one, elsewhere the built-in, silently". Measured 2026-09-08 against the pinned binary at `6e02020`, same deck, same binary, two working directories:

| cwd                | marker in artifact | bytes |
| ------------------ | ------------------ | ----- |
| holds `./simple/`  | present            | 18208 |
| holds nothing      | absent             | 22666 |

**Neither run printed anything, and that is sharper than the criterion's own wording.** `theme::provenance` announces only `Origin::SearchPath`; a cwd hit is stamped `Origin::Path`, and a typed path announces nothing by deliberate design (`a_typed_path_announces_nothing`, and its comment says the cwd case "is AC15's to remove, not this line's to narrate"). So the shadowing has no voice at all -- not a quiet warning, no warning. The unit test that documents the silence is correct and stays correct; what changes is that the case it defers becomes unreachable.

## D2 -- This is a type change, not a branch reorder

`theme::load(flag: Option<&str>, front: Option<&str>, base: &Path)` takes **one ambiguous string** and asks `path.exists()` first:

```
let path = match flag { Some(_) => PathBuf::from(spec), None => base.join(spec) };
let theme = if path.exists() { ... } else if let Some(f) = on_search_path(spec)? { ... } else if let Some(f) = built_in(spec) { ... }
```

Deleting the `path.exists()` arm would make today's tests pass and would leave the defect's cause in place: **the same `&str` would still be able to mean either a name or a path**, and the next feature that needs a path would put the branch back. The fix is to make the ambiguity unrepresentable.

```
pub enum Spec<'a> {
  Name(&'a str),
  File(&'a Path),
}
```

`load` takes `Option<Spec>`. A `Name` never touches the filesystem except through the search path; a `File` never consults the search path or the built-ins. **The cwd branch is not merely unvisited, it is unreachable**, which is the property a reorder cannot buy.

## D3 -- The precedence lattice, with four sources instead of two

Ruled by vc 2026-09-08 10:18Z, on cc's stated assumption. There are now two flags and two front-matter keys where there was one of each.

| rank | source                                | note                                    |
| ---- | ------------------------------------- | --------------------------------------- |
| 1    | `--theme` or `--theme-file`           | mutually exclusive with each other      |
| 2    | `theme:` or `theme-file:`             | mutually exclusive with each other      |
| 3    | built-in `simple`                     | the floor                               |

**A flag of either kind beats a front-matter key of either kind**, so `--theme=mono` beats `theme-file: ./x.css`. This is the natural reading of today's `flag.or(front)` and preserves the existing rule that the flag is the user's override of the deck's choice. It is stated here because the AC splits two sources into four without saying how the four rank, and an unstated lattice is one that gets inferred differently by the next reader.

## D4 -- Where each rule lives, and why that is the Highlander answer

| rule                              | home              | why not elsewhere                                                          |
| --------------------------------- | ----------------- | -------------------------------------------------------------------------- |
| separator-in-a-name refusal       | `theme.rs`        | front matter needs the identical rule; in `args.rs` it would need a copy   |
| `--theme` + `--theme-file` both   | `args.rs`         | flag-vs-flag, and the `--watch` refusal is the precedent                   |
| `theme:` + `theme-file:` both     | `frontmatter.rs`  | key-vs-key, beside the parser that read them                               |
| cwd base vs deck base             | `deck.rs`         | the caller decides and passes a resolved path; `theme.rs` never asks again |
| the four-source lattice           | pure fn, `theme.rs` | no I/O, exhaustively unit-testable                                        |

**The separator rule is the one worth arguing.** It looks like an argument-parsing concern and it is not: AT05 leg 2 requires `theme: ./x.css` in a deck to be refused with the same rule and a different remedy (`theme-file:` rather than `--theme-file`). Two callers, one rule. Putting it in `args.rs` would mean either a second copy in the front-matter path or a front-matter path that quietly does not enforce it, and the second is how the ambiguity "moves into the deck where it travels", which is exactly what AC01 clause (d) exists to stop.

**The base decision is the one that keeps going wrong.** Today `load` itself chooses `PathBuf::from(spec)` for a flag and `base.join(spec)` for front matter, so the question "which directory is this relative to" lives inside the resolver. Under PFIC that is impure coordination sitting in the middle of a pure lookup. `deck.rs` resolves it once and hands `Spec::File` an already-correct path, so there is exactly one place that knows a flag is cwd-relative and a deck key is deck-relative.

## D5 -- The refusal catalogue

Every refusal, its trigger, and what its message must contain. This table is the specification the tests assert against.

| trigger                                     | must say                                              | must NOT say                |
| ------------------------------------------- | ----------------------------------------------------- | --------------------------- |
| `--theme=./x.css` (separator, path exists)  | not a name; name `--theme-file`                       | the built-in roster         |
| `--theme=nosuch/x.css` (separator, no path) | not a name; name `--theme-file`                       | the built-in roster         |
| `--theme=nosuchname` (no separator)         | dirs searched, built-in roster                        | "not a path"                |
| `--theme-file=nosuch`                       | no such file, with the path                           | the built-in roster         |
| `--theme` and `--theme-file` together       | mutually exclusive, either order                      | a silent winner             |
| `theme: ./x.css` in a deck                  | not a name; name `theme-file:`                        | the built-in roster         |
| `theme:` and `theme-file:` together         | mutually exclusive                                    | a silent winner             |

**Row 2 is a gap in the contract, raised with vc at 10:31Z and not yet ruled.** AC01 clause (e) makes a value a path by its **separator**, not by its existence, so `--theme=nosuch/x.css` must refuse naming `--theme-file`. The implementation that gets this wrong is the obvious one -- test `path.exists()`, name the flag if it does, otherwise fall through to the name resolver -- and a mistyped path then lands in `unknown_theme()` and is handed a theme roster. That is the defect AT03 leg 2 stops for `--theme-file`, unguarded for `--theme`, and it is the likelier keystroke of the two.

**Row 3 deletes an assertion that exists today.** `unknown_theme` prints `not a path: <tried>` and the unit test `an_unknown_theme_is_refused_saying_everything_it_tried` asserts it. Under the split a path is never tried for a name, so the line becomes false and both it and the assertion go. This is recorded because it is the shape where a misleading message gets kept alive to keep a test green.

## D6 -- `--theme-path` composes rather than replaces

`search_directories()` reads `PREZ_THEME_PATH` and nothing else. It gains the flag's directories **as a parameter**, threaded from the caller to both consumers (`on_search_path` and `unknown_theme`, which must report where it looked).

A module-level static would be the smaller diff and is rejected: `cargo` runs unit tests on parallel threads in one process, and the existing test module already documents that hazard (`provenance()` is tested on a hand-built `Theme` rather than by setting the env var, "so an env-driven test here would race every other test in this binary -- intermittently, which is the worst way to learn it"). A static would reintroduce exactly that.

Order is `<flag dirs> : <PREZ_THEME_PATH>`. Repeats of the flag are **last-wins**, ruled 10:18Z: every other value flag in `args.rs` is last-wins, and PREPEND describes the relationship between the flag's value and the environment variable, not between two occurrences of the flag.

**AT04 leg 1 is the only leg that can catch an accidental replace**, because it sets the env var *and* the flag and then resolves a name present only in the env. A test that exercises the flag alone passes against a replace implementation and proves nothing about the word "prepend".

## D7 -- The front-matter split, and why migration is not silent

`FrontMatter` gains `theme_file: Option<String>`, a `"theme-file"` match arm, and an entry in `declared()`. The key name needs no parser change: `parse` already accepts `-` in keys.

**A deck written for the old shape is warned rather than broken quietly**, and the mechanism already exists. `FrontMatter::unknown` keeps every key it did not recognise so the caller can name it, precisely because "a typo'd `titel:` that vanished silently would present as 'the title stopped working' with nothing to go on". A deck that says `theme-file:` today is therefore already warned about, and one that says `theme: ./x.css` after the split is refused by the separator rule rather than dropped.

## D8 -- The blast radius, measured at 6e02020

| surface                | count | detail                                                                    |
| ---------------------- | ----- | ------------------------------------------------------------------------- |
| `theme.rs` unit tests  | 6     | call `load(Some(<path>), ...)`; migrate to `Spec::File`                   |
| `theme.rs` unit tests  | 1     | asserts the refusal contains `"not a path"`; deleted with the line        |
| `acceptance.sh`        | 5     | `--theme <path>` at lines 470, 478, 647, 680, 690 (AT05, AT08)            |
| docs                   | 5     | `help/prez.md`, `opt/prez/README.md`, `test_pres.md`, `demo.md`           |
| `opt/prez/prez` shim   | 0     | mentions no flags at all                                                  |

**The shim needs nothing, and that is a test rather than a hope.** `prez.bats:110` counts flag mentions in the shim and asserts `0`, as its Thin Coordinator check -- "a shim that grew its own argument parsing would give `prez --help` two answers". Two new flags therefore reach the shim not at all.

**The five `acceptance.sh` invocations are ST0010's green ATs.** This thread edits the artifact behind a closed thread's greens. In-place migration is the only honest option -- those tests drive a CLI whose contract changed, and a test asserting the old contract would be asserting the opposite of correct -- but the record must say ST0013 edited ST0010's suite and why, rather than leaving a later reader to find a closed thread's tests quietly rewritten.

**`examples/demo.md` is documentation, not a live deck.** Its `theme: themes/plain.css` sits inside a fenced code block, `crate/examples/themes/plain.css` does not exist, and neither example deck declares a theme in real front matter. It migrates as prose teaching the outlawed shape, not as a functional break.

## D9 -- AT06 is deliberately not red-first

`theme.rs:126-129` already tries `on_search_path` before `built_in`, so AT06 is green on its first run and stays green. **Its green is not evidence that the split landed** and it is written into the file carrying that statement, so no later reader can mistake it for a red-to-green.

It is minted because D2's fix rewrites that entire cascade, and an ordering that is load-bearing **by accident of line order** is what a rewrite drops without a sound. Every other row here fails loudly when the split is absent; this one fails only when the split is present and got the order wrong, which is the case red-first structurally cannot reach. It is a regression guard wearing an AT's clothes, and saying so is what keeps `IN-AG-RED-CONTROL-001` satisfied rather than gamed.

## D10 -- A superseded ruling is recorded, not overwritten

`theme.rs`'s module header states the current behaviour as an attributed decision:

> **`--theme` TAKES A NAME OR A PATH, and a name is resolved in a fixed order** (hv, 28 Aug 2026): an existing path first, then a named theme on `PREZ_THEME_PATH`, then a theme built into the binary.

That ruling is hv's and it is being reversed by hv's own 29 Aug re-scope. The rewrite says so explicitly rather than replacing the paragraph, because **an attributed decision that simply vanishes reads afterwards as one nobody ever made** -- and the next person to meet a cwd-first resolver has no way to know it was considered, ruled, and reversed.

## D11 -- Migration is one word

For the invocation actually in use -- geodica's `--theme="$ESTATE/Clients/<domain>/_themes/<name>"`, twice in an hour, rendering both E0024 client decks since 3 Sep -- `--theme=` becomes `--theme-file=` and nothing else changes. AC02 pins that `--theme-file` accepts a directory as well as a `.css` file, which is what makes the one-word migration true; the earlier ruling that would have required restructuring to `--theme-path` plus `--theme` was withdrawn on 8 Sep after the premise behind it was measured and found false.

For hv's `prez present <deck> --theme <path>`, the same one word, and the refusal names it. That is clause (f)'s whole purpose: **naming the replacement flag turns a breakage into a migration.**
