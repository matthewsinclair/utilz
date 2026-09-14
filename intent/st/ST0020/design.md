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

- **Unset, empty, or `first`: first match, exactly as today, and no new way to fail.** Empty means unset, as it does for `PREZ_DEFAULT_THEME`. `first` exists so that a shell which inherited `refuse` can state the default without unsetting it. Under `first` the resolver makes today's checks, in today's order, and stops at the first definition as it does now, so nothing this thread adds can refuse a build that builds today (N2, and "Where it lives").
- **`refuse`**: a name being resolved that has more than one definition on the search path is refused.
- **Any other value is refused by name**, listing the accepted values. A misspelt `refuse` must not quietly mean first match, which would be the exact silence this thread exists to remove. A value that is not UTF-8 is refused by name too, as `PREZ_DEFAULT_THEME`'s is.

**When a bad value is refused: at every compile, whatever the build resolves (N1).** prez reads the variable once per compile, in `deck::compile` beside `PREZ_DEFAULT_THEME` (`src/deck.rs:189`), before the theme is chosen. So `build`, `pdf` and `present`, which all compile there, refuse a bad value, and so does a build that resolves no theme NAME at all: a `--theme-file` path, a deck's `theme-file:`, or a deck that names no theme and takes the built-in `simple`. That is when `PREZ_DEFAULT_THEME`'s non-UTF-8 value is refused today, and for the same reason: a setting the user got wrong is reported on the next build they run, not only on the build shapes that happen to consult it. Under `--watch` the first build is a compile like any other, so a bad value refuses it and prez exits, as it does for every first-build failure (`src/deck.rs:93-95`). The environment cannot change inside a running process, so a bad value never reaches a rebuild.

**The value check is not the duplicate check.** The duplicate check is limited to the name being resolved ("Only the name being resolved", AC-01.3). The value is checked on every compile (AC-01.7).

**Why a variable, not a flag.** The caller is a shim that owns the environment it hands prez. The search path already arrives that way (`PREZ_THEME_PATH`), and so does the default name (`PREZ_DEFAULT_THEME`). A flag would have to be appended to every command form the shim forwards, and it would collide with flags its user types.

**Why a named policy, not a boolean.** `=1`, `=true` and `=yes` invite guessing at what the other spellings mean, while a word says what it does. The name also pairs with `PREZ_THEME_PATH`, the thing it governs.

### What counts as a definition

`on_search_path` already recognises two forms in a search directory: `<dir>/<name>/theme.css` and `<dir>/<name>.css`. A definition is one theme found in one of those forms.

- **Two directories that each define the name: two definitions.** This is AC05's case.
- **One directory that defines the name in both forms: two definitions. This is the one extension beyond the request, and it is stated as one.** Today the directory form wins silently (`:323-329`). A policy that refuses search order choosing between directories, but lets form order choose inside one, is half a policy. It is its own AC (AC-01.8), and vc's review kept it for that reason.
- **One file reached twice is one definition.** That covers a directory listed twice on the path, a directory given by both `--theme-path` and `PREZ_THEME_PATH`, a symlink to a directory already on the path, and a hard link to a `<name>.css` already on the path. Search order has nothing to choose between two routes to one file, so there is nothing to refuse, and refusing a repeat would punish exactly the assembled paths this policy is for, which repeat directories harmlessly.
- **Two copies are two definitions, even byte-identical ones.** The policy is about where a name is defined, not about what the definitions contain. Comparing content would make the answer depend on the files happening to agree today.
- **A built-in is not a second definition.** AC05 names directories, and a built-in is the tier beneath the search path, not a peer on it. Shadowing a built-in is already a documented, announced override (SHADOWING), and a caller that ships a theme under a built-in's name means it. With `refuse` set, one search-path definition that shadows a built-in builds exactly as today, notice included. prez's built-ins are simple, mono, manuscript, contrast, blueprint, steampunk and 8bit.

**A definition's identity is its device and inode (N3, cc's call).** Whether two definitions are one file is the question the rule asks, and (device, inode) is the answer POSIX gives to it: it is what `du`, `find -samefile` and `rsync -H` use. The alternative, the canonical path, answers a different question, whether two spellings name one path once symlinks are resolved, and it answers wrongly for a hard link or a bind mount, which are one file under two paths. It also costs a second resolution with a failure mode of its own, because `canonicalize` needs every component of the path resolvable, and this design's first draft needed a spelling fallback to survive that. Identity by (device, inode) is one `stat` of a path the walk has just found, so the fallback goes, and with it the false refusal that was its worst case. If that `stat` fails, which takes the file vanishing between two calls, the build is refused naming the path and the error, as an unreadable theme is.

- **The identity is taken of the theme's own root**: `<dir>/<name>` for the directory form, and `<dir>/<name>.css` for the file form. A directory theme is its `theme.css`, `theme.js`, `layout.html` and asset files together, so a directory whose `theme.css` alone links to another theme's is a different theme, and counts as a second definition. The two forms never share an identity, because a directory and a file cannot share an inode.
- **Only `refuse` reads identity** ("Where it lives"). `first` never compares definitions, so it never needs one.
- **The limit, stated.** `std` exposes (device, inode) only on Unix, through `std::os::unix::fs::MetadataExt`. The workspace is built and tested on macOS and Linux only (the Rust job's matrix in `.github/workflows/tests.yml`), and this is its first Unix-only `std` call. A build for another platform fails to compile at that one call, which is loud, and a port would choose its own identity then. A filesystem that reported two different files under one (device, inode) would break `du` and `rsync -H` too, and this check does not try to outguess one.

### Only the name being resolved

The check runs inside the resolution of the one name a build asks for: a `--theme` name, the deck's `theme:`, or `PREZ_DEFAULT_THEME`'s name, which resolves exactly as `--theme` does (ST0018, AC-01.4). It never scans the path for every name, so a duplicate the build does not use is not its concern. `--theme-file` and the deck's `theme-file:` never consult the search path, so the check does not reach them.

**This limits the duplicate check and nothing else.** The variable's value is checked on every compile, whether or not the build resolves a name (N1, "A policy, in a variable").

### The refusal

- **Exit 2**, as every theme refusal exits.
- **Its own stable prefix: `theme '<name>' is defined more than once`.** It must never be confused with the unknown-theme refusal, whose `no theme '<name>'` prefix is load-bearing across an estate boundary (`:362-369`). This prefix becomes load-bearing in the same way once the requester asserts on it, and the refusal's doc comment says so.
- **Every definition, one line each, in search order (N4)**: its search directory, the mechanism that put that directory on the path (`given by --theme-path` or `on PREZ_THEME_PATH`, the wording `unknown_theme` already uses), and the file found in it. The message says the list is in search order, and so does the refusal's doc comment, because the order carries information: the first line is the definition that unsetting the variable would give.
- **The policy, named**: the variable and its value, so the reader can see why search order was not allowed to choose. The resolver is shared and reads no environment, so the name comes with the policy ("Where it lives").
- **The remedy**: remove or rename all but one of the definitions, or unset `PREZ_THEME_DUPLICATES` to take the first in search order.
- **When the name came from `PREZ_DEFAULT_THEME`**, `deck::compile` appends ST0018's existing line, `the name came from PREZ_DEFAULT_THEME`, as it does to every theme failure from that source. Nothing new is needed for it.

As prez prints it, with generic paths:

    prez: theme 'house' is defined more than once on the search path, and PREZ_THEME_DUPLICATES=refuse does not let search order choose. In search order:
      /srv/themes (given by --theme-path): house/theme.css
      /home/me/themes (on PREZ_THEME_PATH): house.css
      remedy: remove or rename all but one of them, or unset PREZ_THEME_DUPLICATES to take the first in search order

**A bad value's refusal** names the variable and the value, and lists the policies:

    prez: PREZ_THEME_DUPLICATES='refuze' is not a policy; the policies are first and refuse
      remedy: set PREZ_THEME_DUPLICATES=refuse to refuse a duplicated theme name, or unset it to take the first in search order

A value that is not UTF-8 is refused as `PREZ_THEME_DUPLICATES is not valid UTF-8, so it cannot name a policy; the policies are first and refuse`, with the same remedy. It does not echo the value, which cannot be printed faithfully.

### Where it lives

- **The shared resolver takes the policy as a parameter**: `Registry::load(spec, extra, duplicates)`, with `Duplicates` beside `Spec` in the `artifact` crate. **One walk, two policies**: a second walker for the strict case would be the Highlander breach.
  - The walk yields every definition of the name in search order, lazily. In each directory it makes today's two `is_file` checks in today's order, and it reads nothing but the chosen definition.
  - **`First` takes the first definition and stops.** It makes exactly the checks today's early return makes, reads what today reads, and computes no identity, so nothing it adds can fail (N2). That holds by construction, where this design's first draft relied on a fallback.
  - **`Refuse` walks to the end**, drops a definition whose identity matches an earlier one's (keeping the earlier, which is the one `First` would take, with its directory and mechanism), and then takes the only definition, or refuses with all of them. Only this arm reads identity.
- **`Duplicates::Refuse` carries the name of the variable that set it**, as `Refuse { var }`. The resolver is shared and reads no environment, so a refusal can name its cause only if the policy brings the name with it. A refusal that cannot say what asked for it cannot be constructed.
- **The policy's words live beside the type they select.** `duplicates_policy(var, value)`, in the `artifact` crate beside `name_spec`, turns a value into a `Duplicates` or refuses it by name. `first` and `refuse` are written once, for the parse and for every refusal that names them. It is pure, since it takes the value and never reads the environment, so its unit tests pass values rather than setting process environment, which races other tests in the same binary (`crates/artifact/src/theme.rs:337-342`).
- **prez reads the variable once per compile, at its edge.** `duplicates_from_env()` in `src/theme.rs`, one line beside `default_from_env`, hands `std::env::var_os`'s answer to `duplicates_policy`. `deck::compile`, which holds the only production call of `theme::load` (`src/deck.rs:199`), calls it beside `default_from_env` (`:189`) and passes the policy down.
- **showreel passes `Duplicates::First`, and never reads the variable.** The variable is prez's, as `PREZ_DEFAULT_THEME` is. A showreel equivalent would be its own request.
- **Every call of `load` gains the argument (N6).** There are 24, counted by searching the workspace for `load(`:

| Where                                     | Calls | What each passes                |
| ----------------------------------------- | ----- | ------------------------------- |
| `crates/artifact/src/theme.rs`, its tests | 10    | `Duplicates::First`             |
| `crates/showreel/src/theme.rs:98`         | 1     | `Duplicates::First`             |
| `src/theme.rs:138`, prez's wrapper        | 1     | the policy it was given         |
| `src/theme.rs`, its tests                 | 9     | `Duplicates::First`             |
| `src/html.rs:628` and `:726`, tests       | 2     | `Duplicates::First`             |
| `src/deck.rs:199`, the production call    | 1     | what `duplicates_from_env` read |

vc's note counted nine in the `artifact` crate's tests. The tenth, at `:1057-1058`, is split across two lines, so a one-line search for `FAKE.load(` does not see it. The new unit tests pass the policy they test.

### Scope, stated

- **Every verb.** `build`, `pdf` and `present` all compile through `deck::compile` (`src/deck.rs:23`, `:35`, `:51`), which reads the policy and resolves the theme, so a refusal there refuses all three.
- **`--watch` (N5).** A duplicate refusal there is a failed build like any other (`src/deck.rs:91-113`). The first build does not tolerate failure, so prez refuses and exits 2, as it does for every first-build failure. A rebuild reports the refusal and keeps watching, and each rebuild resolves the theme afresh, so removing the duplicate cures it at the next save without a restart. Nothing in `watch` changes.
- **Not in this thread**: showreel; a command that lists every duplicated name on the path; built-ins as definitions; and any change to the unknown-theme refusal's text or to the SHADOWING notice.

## Tests

- **Unit, in `crates/artifact/src/theme.rs`**, over temporary directories passed as `extra`, never through the environment. The cases: two directories; one directory in both forms; the same directory twice; a symlink to a directory already on the path; a hard link to a `<name>.css`; two byte-identical copies; `First` takes the first; `Refuse` lists every definition, in search order, with its mechanism; and a single definition under `Refuse` resolves as it does under `First`. And `duplicates_policy` over unset, empty, `first`, `refuse`, an unrecognised value, and a value that is not UTF-8.
- **Black-box, in `crate/test/theme-addressing.sh`, as new blocks AT15 to AT22, one per test AC.** They join that file for the reason ST0018's blocks did: it is prez's theme-resolution suite.

**RED-FIRST IS CLAIMED ONLY WHERE HEAD CAN FAIL, AND THE REST IS LABELLED**, as vc required of ST0018. HEAD takes first match and never reads the variable, so any check that first match is unchanged passes at HEAD by construction.

| AT   | Covers  | Red-first                                                            |
| ---- | ------- | -------------------------------------------------------------------- |
| AT15 | AC-01.1 | yes: HEAD builds it                                                  |
| AT16 | AC-01.2 | NO, a regression guard                                               |
| AT17 | AC-01.3 | NO, a regression guard; AT15 is its control                          |
| AT18 | AC-01.4 | yes: HEAD builds it                                                  |
| AT19 | AC-01.5 | NO, a regression guard; AT15's byte-identical copies are its control |
| AT20 | AC-01.6 | NO, a regression guard                                               |
| AT21 | AC-01.7 | yes: HEAD ignores the variable                                       |
| AT22 | AC-01.8 | yes: HEAD takes the directory form silently                          |

- **A guard goes red only if the fix over-reaches, and each block says so in its own header.** A guard alone also passes against a check that refuses nothing, so the table names the red-first block that fails such a check. AT17's control is AT15: a build whose name has two definitions refuses. AT19's control is AT15's copies leg: a check that compared contents rather than identity would pass AT19 and fail there.
- **The black-box blocks drive `build`.** All three verbs compile through `deck::compile`, so a refusal there reaches `pdf` and `present` by construction. `pdf` needs a browser and `present` opens one, so a red-first run of either against HEAD, which builds, would drive a browser on the machine running the suite.

## Closing the loop with the requester

The request's last clause, "send gtools-vc the commit and the variable's name", is AC-01.10 and WP-01's closing step. The message also says how the change reaches a wrapper. From a source checkout, the prez shim rebuilds once on the first use after the commit (issues 0023 and 0025). From an install, it arrives with the next published release.

## Docs

`prez --help` (`args.rs` USAGE, its Environment section) and `help/prez.md` gain a `PREZ_THEME_DUPLICATES` subsection beside `PREZ_THEME_PATH` and `PREZ_DEFAULT_THEME`: its values, what counts as a definition, the refusal, and that a value it does not know is refused at every compile. Neither names any organisation.

## Version

prez goes from 2.1.0 to 2.2.0 in the next Utilz release: a new opt-in behaviour, with nothing changed for a caller that does not set the variable. The number is hv's to confirm at release time.

## vc's review, and where each note landed

vc reviewed this design on 2026-09-14 and approved it with six notes, to be folded into this file and the ACs before any code. This table says where each landed, so the fold can be checked against the notes rather than against a summary of them.

| Note | What vc asked                                                  | Where it landed                                                                              |
| ---- | -------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| N1   | Say when a bad value is refused: at every compile              | "A policy, in a variable"; AC-01.7 reworded, and AC-01.3 now says it covers duplicates only |
| N2   | `first` must add no new way to fail                            | "Where it lives": `First` stops at the first and reads no identity; AC-01.2                 |
| N3   | Consider (device, inode) for one file reached twice; say which | "What counts as a definition": (device, inode), with the reasons and the limit              |
| N4   | Say the list is in search order                                | "The refusal": in the message and in its doc comment; AC-01.1                                |
| N5   | Scope also needs `--watch`                                     | "Scope, stated"                                                                              |
| N6   | The `artifact` crate's own tests call `load` too               | "Where it lives": every call counted, ten there rather than nine                             |

**Beyond the notes, four refinements made while folding them.** Each is stated so vc can keep or refuse it at verification.

1. **The parse moved into the `artifact` crate.** The approved design put a pure `duplicates_policy(value)` in prez's `src/theme.rs`. It now sits beside `Duplicates` and takes the variable's name, so `first` and `refuse` are written once, for the parse and for the refusals that name them. prez keeps the environment read, a one-line `duplicates_from_env()` at its edge. That keeps what the approved design required: a pure parse, and the impure read at the edge.
2. **`Refuse` carries the variable's name**, so a duplicate refusal can always say what asked for it. It follows from 1.
3. **Identity is taken of the theme's own root**, not of `theme.css`, because a directory theme is more than its stylesheet.
4. **Two AC legs for decisions the design already made.** AC-01.1 now includes byte-identical copies, since "two copies are two definitions" had no AC. AC-01.5 now includes a hard link, which is N3's reason and would otherwise be a claim no test makes.
