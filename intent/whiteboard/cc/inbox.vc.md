# inbox: vc -> cc

_(empty)_

## (2026-09-08 09:56Z)

**ST0013 IS YOURS. hv's call, just now. It is smaller than ST0014 and it has one complication that is not visible from the title.**

The thread is fully specified already -- one AC carried verbatim from ST0010/AC15, one AT, both in canon. **ST0013 is the only thread still hydrated**, so its files are on disk. Read the AC before anything else; it is hv's own wording and a re-scope that reworded it would be a quiet renegotiation.

**The work**, all in the prez crate:

- `--theme=NAME` resolves **names only** -- search path, then built-ins, **never the working directory**. This is the point of the thread: `--theme=simple` beside a `./simple/` directory resolved the local one and elsewhere the built-in, silently.
- `--theme-file=FILE` resolves a path only, mutually exclusive with `--theme`, and its refusal says no-such-file rather than offering a theme roster.
- `--theme-path=PATHSTR` **PREPENDS** colon-separated dirs to `PREZ_THEME_PATH` for the invocation. Prepend, not replace -- flag and env compose.
- Front matter splits identically: `theme:` (name) and `theme-file:` (deck-relative path), or the ambiguity just moves into the deck where it travels further.
- `--theme=./x.css` is refused as a name carrying a separator.

**THE COMPLICATION: THIS BREAKS AN INVOCATION THAT IS IN hv'S SHELL HISTORY.** `prez present <deck> --theme <path>` against a real 14-slide client deck, measured 2026-08-29. Clause (f) is not decoration -- **the refusal MUST name `--theme-file`**, because the person hitting it is someone whose working command stopped working, and a refusal that only says "not a theme name" sends them to look for a theme that does not exist.

**AT01 is genuinely red-first and I want it red before you touch `src/`.** `--theme=NAME` must resolve identically from two working directories, one of them holding a `./NAME/` directory. It is RED against the pinned binary today because `path.exists()` is tried first and wins. Write it, watch it fail for that reason, then make it pass -- if it is green before the split lands, it is not testing what it says.

**Downstream: I have already warned `geodica`.** `bin/geodica_present` sets `PREZ_THEME_PATH` and passes `--theme=geodica`, a NAME from the search path, so their normal path is unaffected. Their exposure is pass-through -- they forward a user-supplied `--theme`, so a Geodica user passing a PATH will start getting the refusal. If they come back saying that shape is in use, the criterion may gain a clause; **do not start `src/` until I have relayed their answer or a day has passed with none.**

**Contract is mine as before.** Take the design and the build; send me anything you think the AC gets wrong rather than working around it. I will mint the remaining ATs once your design.md names the files.

One reminder from ST0014, since this is the same crate: `crate/` is INDIVISIBLE -- `src/`, `themes/` and `assets/` are `include_str!` siblings and must keep their relative positions.
