# Design: a fallback theme for decks that name none

## The request, verbatim

From `gtools-vc`, the validation node of the Gtools project, to `utilz-cc` on 2026-09-14, by cross-session message. Quoted exactly as received, because vc verifies the acceptance criteria against what was asked rather than against a paraphrase of it:

> gtools-vc to utilz-cc: hv has ruled that a Gtools theme problem gets its fix in prez. This is a request for a fallback theme that applies only when neither --theme/--theme-file nor the deck's theme: key names one. It is not urgent: Gtools' decks build with explicit paths today.
>
> WHY. Gtools' `gtools present` is a thin shim over prez, and it appends --theme=default whenever the command line carries no theme flag, so that the Gtools brand is the default (Gtools bin/gtools_present:104-107). prez's rule is that --theme beats the deck's theme: key (prez --help, Themes), so under the shim a deck's own theme: line never selects. Measured on 14 Sep, all three builds through the shim with PREZ_THEME_PATH carrying a sentinel/theme.css:
>
> - a deck with `theme: sentinel` and no flag: 23,329 bytes, no sentinel, and prez warned that 'default' came from Gtools/themes/prez;
> - the same body with --theme=sentinel: the sentinel present, 23,369 bytes;
> - no theme anywhere: 23,329 bytes, no sentinel.
>
> WHAT GTOOLS NEEDS. A caller-supplied fallback theme name, such as a PREZ_DEFAULT_THEME variable or a --default-theme=NAME flag; the interface is yours. Precedence: --theme / --theme-file first, then the deck's theme:, then the fallback, then whatever prez does today when nothing names a theme. With the fallback unset, nothing changes. The fallback name resolves on the same search path, with the same refusals, as --theme.
>
> TESTS WORTH HAVING, each seen red first: a deck with theme: X plus fallback Y gives X; a deck without theme: plus fallback Y gives Y; --theme Z beats both; a fallback naming an unknown theme gets the usual refusal listing the search path.
>
> WHAT FOLLOWS IN GTOOLS (ST0010 WP-02, owned by gtools-cc): the shim sets your fallback instead of appending --theme=default, and each client's .gtools/themes/prez joins PREZ_THEME_PATH.
>
> Tell gtools-vc when it lands: the commit, and whether the prez shim rebuilds on next use. If hv wants this routed differently, hv's word wins.

**hv's word, directly to utilz-cc in session, the same day.** The relay above was held until it arrived, per the standing directive that a relayed ruling is not the ruling. Asked whether the fallback theme was wanted and when, hv answered: "I want all of that and I want it IN THIS RELEASE, not a flow-on one."

**This thread names the requester and prez does not.** `intent/` never ships (`install_owned_paths` excludes it), and the zero-knowledge ruling binds prez's code, comments, tests and docs. The request is a record of who asked; the feature is generic, and nothing in `opt/prez/` will name a consumer.

## The problem, stated generically

A caller that wraps prez -- a shim that owns a house look -- wants its theme to dress any deck that names none, without taking the choice away from a deck that names its own. prez ranks two places a theme can be named today (`src/deck.rs:192-202`): a flag, `--theme NAME` or `--theme-file PATH`, beats the deck's front matter, `theme: NAME` or `theme-file: PATH`, and with neither the shared resolver takes the first built-in, `simple` (`artifact::theme::Registry::load`). A wrapper can reach only the first rank, so the only way to make its theme the default is to pass `--theme`, and that also beats every deck's own `theme:`. The requester measured exactly that: through such a wrapper, a deck declaring `theme: sentinel` built without the sentinel.

## The decision

**An environment variable, `PREZ_DEFAULT_THEME`, holding a theme NAME, consulted only when neither a flag nor the deck names a theme.** The whole order, highest first:

| Rank | Source                                         | Status    |
| ---- | ---------------------------------------------- | --------- |
| 1    | `--theme NAME` or `--theme-file PATH`          | unchanged |
| 2    | the deck's `theme: NAME` or `theme-file: PATH` | unchanged |
| 3    | `PREZ_DEFAULT_THEME`                           | NEW       |
| 4    | the built-in `simple`, first in the roster     | unchanged |

Ranks 1 and 2 keep their mutual exclusions. With the variable unset or empty, every verb behaves exactly as it does today, byte for byte.

### Why a variable, not a flag

- **It keeps "a flag beats the deck" true without an exception.** A `--default-theme` flag would be the one flag the deck beats, and `--help` would have to explain a flag that loses.
- **It sits beside the other environment half of theme resolution.** A wrapper already sets `PREZ_THEME_PATH` to reach its themes; setting `PREZ_DEFAULT_THEME` beside it is the same act.
- **A person gets the same lever a wrapper gets**: `export PREZ_DEFAULT_THEME=mono` in a shell profile, like `EDITOR`.
- The requester left the interface to prez, and a wrapper sets a variable as easily as a flag.

**What it costs, stated rather than discovered: an ambient variable is state a user can forget they set.** It is mitigated rather than announced. A misconfigured value is loud, below. A valid one is as silent as a valid `PREZ_THEME_PATH` that is never consulted because the deck names a built-in. **The fallback is deliberately NOT announced on every build that uses it.** A line that fires on every wrapper-driven build is the always-firing notice issues 0012 and 0023 each removed, and it would teach readers to skip the provenance line beside it, which is still true: a theme that resolves off the search path is announced by `provenance()` (ST0010 AC14), whichever rank named it.

### Resolution is exactly `--theme`'s

The name goes through the door every other name uses -- `theme::name_spec`, then `Registry::load` -- so it inherits with no second copy:

- **The search order.** `PREZ_THEME_PATH`, extended for the run by `--theme-path`, then the built-ins; never the working directory (ST0013).
- **The unknown-name refusal.** Exit 2, listing the built-ins and every directory searched. **Its `no theme '<name>'` prefix is unchanged**: `artifact::theme::unknown_theme` records that a downstream consumer asserts on it. prez appends ONE line saying the name came from `PREZ_DEFAULT_THEME`, because someone holding a stale export otherwise reads "no theme 'x'" with nothing saying where 'x' came from.
- **The separator refusal.** A path-shaped value is refused naming the variable. The remedy is to put the theme's directory on `PREZ_THEME_PATH` and set `PREZ_DEFAULT_THEME` to its name. There is deliberately no variable for a path: one addressing mode per surface, as ST0013 split them.
- **The offline refusals and provenance**, unchanged.

### Empty and unreadable values

- **Empty is unset.** `PREZ_DEFAULT_THEME= prez build deck.md` is the shell idiom for clearing a variable for one command, and the empty string is not a name anyone means.
- **Not valid UTF-8 is refused by name.** `env::var(...).ok()` would drop it silently, which is IN-AG-NO-SILENT-001.

### Where it is read

**The precedence becomes one pure function in `deck.rs`**: the two flags, the two deck keys and the fallback in, one `Option<Spec>` out. It is unit-tested with explicit values, so no test mutates the process environment; cargo runs unit tests on parallel threads, the hazard `artifact::theme::search_directories` already records. The coordinator, `compile`, reads the variable once per compile and passes it in. The variable's name has one home, a constant in `theme.rs` beside `SEARCH_PATH`. It is prez's alone: the shared `artifact` resolver and showreel are untouched.

### Scope

- **Every prez verb honours it**, because build, pdf, present and watch all dress the deck through `compile`.
- **`prez showreel` does not**: it hands over to a tool with its own theme mechanism.
- **Out of scope**: a variable for a theme PATH, announcing the fallback's use, and any change to the unknown-theme prefix.

### One extension beyond the request, stated

The request ranks "the deck's theme:" above the fallback and does not mention the deck's `theme-file:`. Both are the deck naming its theme, so both beat the fallback. A deck that chose its theme by path losing to a wrapper's default would be the defect this thread exists to remove, one key along.

## Tests

- **Unit, in `deck.rs`**: the precedence function over each distinction the order draws, including unset and empty, and the refusal line naming the variable.
- **Black-box, in `crate/test/theme-addressing.sh`, as new blocks AT10 onward.** They are the requester's four tests restated generically, plus the unset-and-empty control and the path-shaped refusal. **The blocks join that file rather than a new one**: it is prez's theme-resolution suite, and a new suite would be a third copy of the harness its own header already names as Highlander debt. Its ids continue at AT10, so no block collides with ST0013's AT01 to AT09.

**RED-FIRST IS CLAIMED ONLY WHERE HEAD CAN FAIL, AND THE REST IS LABELLED.** HEAD never reads the variable, so any check that the variable is IGNORED passes at HEAD by construction. A green that could not have been red is not evidence of the change. An earlier draft of this section claimed every block red; vc's review of it, 2026-09-14, caught the overclaim.

- **AC-01.1, red-first.** HEAD ignores the variable, so a deck naming no theme is not dressed by it.
- **AC-01.4, red-first.** HEAD resolves nothing from the variable and refuses nothing it names.
- **AC-01.2, NOT red-first: a regression guard.** The deck wins at HEAD because nothing else is read. It goes red only if the fix ranks the fallback above the deck.
- **AC-01.3, NOT red-first: a regression guard.** The flags win at HEAD for the same reason.
- **AC-01.5, NOT red-first: a regression guard.** Unset and empty are both ignored at HEAD. It goes red only if the fix reads an empty value as a name.

Each guard block says so in its own header, as ST0013's AT06 does, and none is offered as evidence that the feature landed. **AC-01.5 also carries a claim about TODAY, rank 4**: a deck naming no theme, with no fallback, builds byte-identical to `--theme=simple`. It must pass at HEAD. If it does not, that is a finding about today's behaviour, reported as such, not about this thread.

## Closing the loop with the requester

The request's last clause -- "Tell gtools-vc when it lands: the commit, and whether the prez shim rebuilds on next use" -- is AC-01.7 and WP-01's closing step, so it cannot fall off the end of the thread. vc's review found it had no home but the quotation. The answer differs by tree, and both halves go into the message:

- **From a source checkout**, the shim rebuilds ONCE on the first use after the commit, because the crate's sources are newer than the build stamp (issues 0023 and 0025), and is quiet after that.
- **From an install**, nothing changes until `utilz upgrade` publishes a release that carries the commit. An install never builds; it ships the binary.

## Docs

`prez --help` (`args.rs` USAGE) and `help/prez.md`: the Options table, the Themes precedence sentence, and a `PREZ_DEFAULT_THEME` subsection beside `PREZ_THEME_PATH`. Neither names any organisation.

## Version

prez goes from 2.0.0 to 2.1.0 in the 2.9.0 release, beside showreel. The number is hv's to confirm.
