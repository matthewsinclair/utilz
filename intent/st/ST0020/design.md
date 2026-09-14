# Design: a theme name defined more than once on the search path refuses, when a caller asks

## The request, verbatim

From `gtools-vc`, the validation node of the Gtools project, to `utilz-cc` on 2026-09-14, by cross-session message. Quoted exactly as received, because vc verifies the acceptance criteria against what was asked rather than against a paraphrase of it:

> gtools-vc to utilz-cc: a ruling from hv for prez, and a request.
>
> hv ruled (b) on ST0010 WP-02's duplicate theme names ("2: B", in vc's chat). The requirement, from Gtools' AC05: a theme NAME that two directories on prez's search path define refuses and names both directories, instead of letting search order choose silently.
>
> - The check is opt-in. It runs only when a variable is set (its name is yours to choose), and the Gtools shim sets it, so prez's other users keep first-match.
> - It refuses only the name actually being resolved, not every duplicate on the path.
> - The refusal names both directories. Your existing refusal shape (exit 2, with the search path listed) looks like the natural model, but the design is yours.
> - Measured today: prez has no duplicate check. It announces SHADOWING when a search-path theme shadows a built-in (theme.rs:356). AC05 names directories only, so whether a built-in counts as a second definition is your call.
>
> The release. (b) was put to hv as "in Utilz 2.9.0". On GitHub a moment ago, 2.9.0's release commit ebd0243 was already on main (at 35a438c), with no v2.9 tag. So whether this joins 2.9.0 before its tag or ships in the next release goes back to hv, and I've asked. The build doesn't need to wait for that answer.
>
> When it lands, send gtools-vc the commit and the variable's name. gtools-cc's second half of WP-02 sets it in the shim.

Gtools' AC05, as written in Gtools' `intent/st/ST0010/acceptance.md`:

> - AC05 `gtools present` FINDS A CLIENT'S THEME BY NAME. Every client folder's `.gtools/themes/prez` joins `PREZ_THEME_PATH`, so a deck declaring `theme: <name>` builds with that theme and without `--theme-path` -- which today it cannot, because the shim's own `--theme=default` outranks the deck's key (measured by vc, 14 Sep). A name that two directories define refuses and names both, instead of letting search order choose silently. -- satisfied: no (computed)

**The release question is settled.** gtools-vc's check asked GitHub for `v2.9*`, a name Utilz never uses. 2.9.0 was tagged `2.9.0` on `ebd0243` and published at 16:02Z the same day, and gtools-vc confirmed that and corrected its question with hv and gtools-cc. This thread ships in the next release.

**hv's word, directly to utilz-cc in session, the same day.** The relay was held until it arrived, per the standing directive that a relayed ruling is not the ruling (`intent/restart.md`, Project-wide Conventions). Asked whether (b) was the ruling, hv answered "Yes, (b), next release". Asked what comes first, hv answered "The prez check first", ahead of ST0019's design.

**This thread names the requester, and prez does not.** `intent/` never ships (`install_owned_paths` excludes it), and the zero-knowledge ruling binds prez's code, comments, tests and docs. The request is a record of who asked. The feature is generic, and nothing in `opt/prez/` will name a consumer.

## The problem, stated generically

A caller can assemble prez's theme search path from several sources: its own themes, per-customer directories, and whatever the user already exported. That caller can end up with one theme NAME defined in more than one place.

prez resolves a NAME by first match. `Registry::on_search_path`, in the shared `artifact` crate, walks the `--theme-path` directories and then `PREZ_THEME_PATH`'s, in order, and returns the first `<dir>/<name>/theme.css` or `<dir>/<name>.css` (`crates/artifact/src/theme.rs:303-332`). Nothing reports that a later directory defined the name too. The provenance notice names the directory the theme came from, and says SHADOWING when a search-path theme shadows a built-in (`:266-301`), but a second definition on the path is invisible.

For most callers, first match is the intended and documented behaviour: `--theme-path` prepends to the environment precisely so that a directory given for one invocation overrides an exported one. For a caller whose path is assembled rather than chosen, the silent choice is the defect. The deck builds in whichever definition sorted first, and the build says nothing.

## The decision

### A policy, in a variable: `PREZ_THEME_DUPLICATES`

- **Unset, empty, or `first`: first match, exactly as today.** Empty means unset, as it does for `PREZ_DEFAULT_THEME`. `first` exists so that a shell which inherited `refuse` can state the default without unsetting it.
- **`refuse`**: a name being resolved that has more than one definition on the search path is refused.
- **Any other value is refused by name**, listing the accepted values. A misspelt `refuse` must not quietly mean first match, which would be the exact silence this thread exists to remove. A value that is not UTF-8 is refused by name too, as `PREZ_DEFAULT_THEME`'s is.

**Why a variable, not a flag.** The caller is a shim that owns the environment it hands prez. The search path already arrives that way (`PREZ_THEME_PATH`), and so does the default name (`PREZ_DEFAULT_THEME`). A flag would have to be appended to every command form the shim forwards, and it would collide with flags its user types.

**Why a named policy, not a boolean.** `=1`, `=true` and `=yes` invite guessing at what the other spellings mean, while a word says what it does. The name also pairs with `PREZ_THEME_PATH`, the thing it governs.

### What counts as a definition

`on_search_path` already recognises two forms in a search directory: `<dir>/<name>/theme.css` and `<dir>/<name>.css`. A definition is one such file.

- **Two directories that each define the name: two definitions.** This is AC05's case.
- **One directory that defines the name in both forms: two definitions. This is the one extension beyond the request, and it is stated as one.** Today the directory form wins silently (`:323-329`). A policy that refuses search order choosing between directories, but lets form order choose inside one, is half a policy. It is its own AC, so vc can accept it or withdraw it cleanly.
- **One file reached twice is one definition.** That covers a directory listed twice on the path, a directory given by both `--theme-path` and `PREZ_THEME_PATH`, and a symlink to a directory already on the path. Definitions are compared by canonical path. Refusing a repeat would punish exactly the assembled paths this policy is for, which repeat directories harmlessly. A candidate whose canonical path cannot be read is compared by its spelling, so the worst case is a loud false refusal, never a silent choice.
- **Two copies are two definitions, even byte-identical ones.** The policy is about where a name is defined, not about what the definitions contain. Comparing content would make the answer depend on the files happening to agree today.
- **A built-in is not a second definition.** AC05 names directories, and a built-in is the tier beneath the search path, not a peer on it. Shadowing a built-in is already a documented, announced override (SHADOWING), and a caller that ships a theme under a built-in's name means it. With `refuse` set, one search-path definition that shadows a built-in builds exactly as today, notice included. prez's built-ins are simple, mono, manuscript, contrast, blueprint, steampunk and 8bit.

### Only the name being resolved

The check runs inside the resolution of the one name a build asks for: a `--theme` name, the deck's `theme:`, or `PREZ_DEFAULT_THEME`'s name, which resolves exactly as `--theme` does (ST0018, AC-01.4). It never scans the path for every name, so a duplicate the build does not use is not its concern. `--theme-file` and the deck's `theme-file:` never consult the search path, so the check does not reach them.

### The refusal

- **Exit 2**, as every theme refusal exits.
- **Its own stable prefix: `theme '<name>' is defined more than once`.** It must never be confused with the unknown-theme refusal, whose `no theme '<name>'` prefix is load-bearing across an estate boundary (`:362-369`). This prefix becomes load-bearing in the same way once the requester asserts on it, and the refusal's doc comment says so.
- **Every definition, one line each**: its search directory, the mechanism that put that directory on the path (`given by --theme-path` or `on PREZ_THEME_PATH`, the wording `unknown_theme` already uses), and the file found in it.
- **The policy, named**: the variable and its value, so the reader can see why search order was not allowed to choose.
- **The remedy**: remove or rename all but one of the definitions, or unset `PREZ_THEME_DUPLICATES` to take the first on the path.
- **When the name came from `PREZ_DEFAULT_THEME`**, `deck::compile` appends ST0018's existing line, `the name came from PREZ_DEFAULT_THEME`, as it does to every theme failure from that source. Nothing new is needed for it.

For illustration, with generic paths:

    theme 'house' is defined more than once on the search path, and PREZ_THEME_DUPLICATES=refuse does not let search order choose:
      /srv/themes (given by --theme-path): house/theme.css
      /home/me/themes (on PREZ_THEME_PATH): house.css

### Where it lives

- **The shared resolver takes the policy as a parameter**: `Registry::load(spec, extra, duplicates)`, with `Duplicates::{First, Refuse}` beside `Spec` in the `artifact` crate. `on_search_path` becomes one walk that collects every definition, deduplicated by canonical path. It makes the same two `is_file` checks it makes today, and it reads nothing but the chosen definition. `First` takes the first, which is the one today's early return picks, so output is unchanged. `Refuse` takes the only definition, or refuses with all of them. **One walk, two policies**: a second walker for the strict case would be the Highlander breach.
- **prez reads the variable once, at its edge**: a pure `duplicates_policy(value)` over the result of reading the environment, and a one-line `duplicates_from_env()` beside `default_from_env` in `src/theme.rs`. `deck::compile`, the only production caller of `theme::load` (`src/deck.rs:199`), reads it and passes it down. The parse is pure so that its unit tests construct values rather than setting process environment, which races other tests in the same binary (`crates/artifact/src/theme.rs:337-342`).
- **showreel passes `Duplicates::First`, and never reads the variable.** The variable is prez's, as `PREZ_DEFAULT_THEME` is. A showreel equivalent would be its own request.
- The two test-only calls in `src/html.rs` gain the argument.

### Scope, stated

Not in this thread: showreel; a command that lists every duplicated name on the path; built-ins as definitions; and any change to the unknown-theme refusal's text or to the SHADOWING notice.

## Tests

- **Unit, in `crates/artifact/src/theme.rs`**, over temporary directories passed as `extra`, never through the environment. The cases: two directories; one directory in both forms; the same directory twice; a symlink to a directory already on the path; `First` takes the first; `Refuse` lists every definition with its mechanism; and a single definition under `Refuse` resolves as it does under `First`.
- **Unit, in `src/theme.rs`**: `duplicates_policy` over unset, empty, `first`, `refuse`, an unrecognised value, and a value that is not UTF-8.
- **Black-box, in `crate/test/theme-addressing.sh`, as new blocks AT15 onward, one per test AC.** They join that file for the reason ST0018's blocks did: it is prez's theme-resolution suite.

**RED-FIRST IS CLAIMED ONLY WHERE HEAD CAN FAIL, AND THE REST IS LABELLED**, as vc required of ST0018. HEAD takes first match and never reads the variable, so any check that first match is unchanged passes at HEAD by construction.

- **Red-first**: AC-01.1 (a name two directories define is refused, naming both), AC-01.4 (the default name is checked), AC-01.7 (an unrecognised value is refused) and AC-01.8 (one directory in both forms is refused). HEAD builds every one of them.
- **NOT red-first, regression guards**: AC-01.2 (unset, empty and `first` keep first match), AC-01.3 (a duplicate the build does not use does not refuse it), AC-01.5 (one file reached twice is one definition) and AC-01.6 (a built-in is not a second definition). HEAD passes each because it checks nothing. Each goes red only if the fix over-reaches, and each block says so in its own header.

## Closing the loop with the requester

The request's last clause, "send gtools-vc the commit and the variable's name", is AC-01.10 and WP-01's closing step. The message also says how the change reaches a wrapper. From a source checkout, the prez shim rebuilds once on the first use after the commit (issues 0023 and 0025). From an install, it arrives with the next published release.

## Docs

`prez --help` (`args.rs` USAGE, its Environment section) and `help/prez.md` gain a `PREZ_THEME_DUPLICATES` subsection beside `PREZ_THEME_PATH` and `PREZ_DEFAULT_THEME`: its values, what counts as a definition, and the refusal. Neither names any organisation.

## Version

prez goes from 2.1.0 to 2.2.0 in the next Utilz release: a new opt-in behaviour, with nothing changed for a caller that does not set the variable. The number is hv's to confirm at release time.
