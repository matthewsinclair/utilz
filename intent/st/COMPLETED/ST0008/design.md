# Design - ST0008: Add todo to utilz

## Approach

`utilz todo` is a standalone, single-file todo manager: a plain-text `todo.md` with three buckets -- DOING / TODO / DONE -- that the utility both reads and writes. It is a **fork of Intent's `intent todo`**, factored out of Intent and made independent. The two must stay **file-format compatible** and keep **command names identical** wherever the standalone context allows.

The utility is scaffolded with `utilz generate todo` and follows the standard Utilz anatomy: `opt/todo/todo` (impl), `opt/todo/todo.yaml` (metadata), `opt/todo/test/todo.bats` (BATS), `opt/todo/README.md`, `help/todo.md`, `bin/todo -> utilz` (symlink). It sources `opt/utilz/lib/common.sh` for `info/success/warn/error` and the help/version plumbing.

## The fork: projection vs source-of-truth

This is the one architectural fact everything else follows from.

- **Intent's `todo` is a projection.** `intent/todo.md` is read-only output, regenerated live from each steel thread's `status:` frontmatter under `intent/st/**`. The file cannot drift because it is never hand-edited; mutations delegate to `intent st/wp done`. Items are addressed by steel-thread ID (`ST0001/02`).
- **`utilz todo` is the source of truth.** There are no steel threads. The `todo.md` file is the data. Items are freeform one-line strings the user adds and edits directly (via the CLI, or by hand + `sync`). This inverts the design: the file is read-modify-write, items are addressed by a **positional number**, and utilz gains verbs Intent never needed (`add`, `start`, `next`, `sync`, `edit`).

## File format

    ---
    title: "# TODO"
    history: _history/YYYYMMDD-done.md
    ---

    # TODO

    ## DOING

    01:[-] A WIP item

    ## TODO

    02:[ ] A todo item

    ## DONE:2026-07-02T00:00:00Z

    03:[x] A finished item

### Compatibility surface (identical to Intent)

| Element        | Form                                             |
| -------------- | ------------------------------------------------ |
| Bucket heads   | `## DOING`, `## TODO`                            |
| DONE watermark | `## DONE:<ISO-8601-UTC>`                         |
| Glyphs         | `[ ]` not-started, `[-]` in-progress, `[x]` done |
| Empty bucket   | `_(none)_`                                       |

Intent only ever greps `^## DONE:` and regenerates buckets, so the additions below (frontmatter, item numbers) are inert to Intent: a utilz `todo.md` remains readable by Intent's watermark/bucket reads. utilz never overwrites Intent's file and vice versa.

### Additions over Intent (deliberate divergences)

- **YAML frontmatter.** Intent's todo.md is frontmatter-less (a test asserts no provenance). utilz adds frontmatter carrying `title:` (the H1 written below the frontmatter; default `"# TODO"` on first creation, preserved thereafter, `--title` overrides on create) and `history:` (a path pattern for the purge archive, see Purge below).
- **No leading `- ` dash.** Intent emits GFM task-list items (`- [x] ...`) for its two-level ST/WP nesting. utilz todos are flat one-level items, so the line is bare: `<num>:[<glyph>] <text>`. (`sync` still tolerates a stray leading `- ` on load -- eg pasted from Intent -- and strips it.)

### Item numbering

- **Global, positional, re-derived on every write.** Numbers are display indices `1..N` in file order (DOING, then TODO, then DONE), recomputed and re-padded on each write. A number can refer to a different item after an `add`/`done`/`sync` -- the expected `list`-then-act rhythm of a flat todo tool.
- **Zero-pad to max width.** Width = digit-count of the largest number present: 1--9 -> `N`, 10--99 -> `NN`, 100+ -> `NNN`. All rows share one width so the `:` and `[` columns align.
- **Line shape:** `<zero-padded-num>:[<glyph>] <text>` (no space before `:`, one space after `]`).

### Ordering semantics

- **`todo.md` = priority order.** Top-to-bottom in DOING and TODO means most-important / do-next -> least. Position is the priority; `sync` and every verb preserve within-bucket order except for a deliberate move.
- **DONE = reverse-chronological.** Newest completion at the **top**, both in the `todo.md` DONE bucket and in the history file. `done <id>` therefore **prepends** to DONE; purge prepends the DONE block to history **as-is** (no per-batch reversal -- DONE is already newest-first).

## Commands

| Command                 | Behaviour                                                                 |
| ----------------------- | ------------------------------------------------------------------------- |
| `list` / (none)         | print the file (create from template if absent)                           |
| `add [--top] <text>`    | add item to TODO -- bottom by default, top with `--top`; normalize, write |
| `start [--top] <id>`    | move item to DOING (`[-]`) -- bottom by default, top with `--top`         |
| `done <id>`             | move item to DONE (`[x]`), prepend (newest-at-top); watermark unchanged   |
| `notdone <id>`          | move item back to TODO (`[ ]`)                                            |
| `toggle <id>`           | flip done <-> not-done from the current glyph                             |
| `next [n]`              | print the next `n` open items (DOING first, then TODO); default 1         |
| `doing`                 | print the DOING bucket                                                    |
| `todo`                  | print the TODO bucket                                                     |
| `done` (no arg)         | print the DONE bucket (query) -- see dispatch note                        |
| `count`                 | print counts per bucket                                                   |
| `sync` (alias `update`) | normalize the file: reconcile glyphs, relocate, renumber (see Sync)       |
| `edit`                  | open the resolved file in `$VISUAL`/`$EDITOR`/`vi`, then auto-`sync`      |
| `done --flush`          | clear DONE **without** archiving (destructive; confirm-guarded)           |
| `done --prune`          | purge: archive DONE to history, remove from file, stamp watermark         |
| `--json`                | emit `{title, doing[], todo[], done[], done_watermark}` to stdout         |
| `help`                  | usage                                                                     |

Dispatch note: `done` is overloaded (Intent precedent). `done <id>` mutates; `done --flush` / `done --prune` are lifecycle; a bare `done` with no arg prints the DONE bucket. The parser branches on the first argument.

`next [n]` prints the next `n` open items in file order: DOING items first (already in-flight), then TODO. Default `n=1`. The "what do I work on next" query.

## Sync and the shared normalizer (Highlander)

`normalize()` is the single core operation; **every mutating verb is `load -> apply verb -> normalize -> write`**, and `sync` is the no-mutation path straight through it. There is one parser, one normalizer, one writer.

`normalize()` steps:

1. **Parse tolerantly.** Accept hand-entered lines: missing number, wrong padding, a stray leading `- ` (Intent paste), `[x]foo` with no space. An unrecognizable non-blank line under a bucket is **warned** on stderr (No Silent Errors), never silently dropped.
2. **Reconcile glyph vs section -- glyph wins.** The checkbox is the semantic signal; the section is derived. An item marked `[x]` while sitting under `## TODO` is relocated to DONE; a `[ ]`/`[-]` under `## DONE` is relocated out. To reclassify by hand, change the checkbox -- not the section. (Moving a line between headings without changing its glyph is a no-op: glyph wins, it moves back.)
3. **Place.** DOING and TODO preserve within-bucket priority order; relocations into DONE go to the **top** (newest-first).
4. **Renumber + re-pad** globally in file order; **write atomically** (temp + `mv`).

The motivating flow: open `todo.md` in an editor, flip a DOING item's `[-]` to `[x]`, save, run `utilz todo sync` (or just `utilz todo edit`, which syncs on exit) -- the item lands at the top of DONE, everything renumbers. `update` is a back-compat alias for `sync` (Intent had `update`; utilz has nothing to regenerate from but the file itself, so the two collapse to one operation).

## Purge (history sweep) and flush

The `## DONE:<T>` watermark is **reinterpreted as "last purge/flush time"** -- informational + format-compat. Unlike Intent, DONE items are real lines that live in the file until purged; the watermark does not gate visibility.

`done --prune` (purge):

1. Resolve `history:` from frontmatter. `YYYYMMDD` is a strftime placeholder expanded to today's UTC date; the path resolves **relative to the todo.md's own directory**. Default `_history/YYYYMMDD-done.md`.
2. **Prepend** the DONE block to that file (creating dirs as needed), newest batch on top so top-to-bottom reads reverse-chronological. DONE is already newest-first in `todo.md`, so the block is written as-is. Archived lines drop the volatile positional number: `[x] <text>`.
3. Remove the DONE items from `todo.md`; stamp `## DONE:<now-UTC>`; renumber.

`done --flush` clears the DONE bucket **without** archiving. Destructive, so it confirms (or `--force`/`--just-do-it` per the Utilz confirm idiom). Stamp `## DONE:<now-UTC>`.

## File location

- Default `./todo.md` (cwd-relative).
- `--file <path>` -- explicit path (wins over all).
- `-g` / `--global` -- `${XDG_CONFIG_HOME:-$HOME/.config}/utilz/todo/todo.md`.
- Precedence: `--file` > `-g` > `./todo.md`. `--file` and `-g` together is an error. `edit` opens whichever the same resolution picks.

## Design Decisions

- **Highlander.** One parser, one `normalize()`, one writer (temp + `mv`, atomic), one bucket->section map, shared by the markdown and `--json` views. Every verb funnels through `normalize()`.
- **Thin coordinator.** The dispatch `case` parses args, calls a verb, renders. All item logic (parse, reconcile, place, renumber, pad) lives in named helpers.
- **No silent errors.** Unknown id -> error + non-zero exit. `--file` + `-g` -> error. Unrecognizable line on `sync` -> warned, not dropped. `$EDITOR` unresolved -> clear error.
- **PFIC.** Verbs are small transformations over the parsed item list; pattern on glyph/section rather than nested conditionals.
- **Bash 3.2 (macOS CI).** Guard empty-array expansion under `set -u`; never end a function/loop on a bare `[[ ... ]] && cmd`; use `if/fi`. Atomic writes.

## Alternatives Considered

- **Stable ids** (assigned at `add`, never renumbered): rejected for gaps after purge, unbounded growth, and width decoupling from count. Positional matches the "1..9 then 01..99" spec and the flat-file `list`-then-act model.
- **Section-authoritative sync** (dragging a line between headings reclassifies it): rejected -- the user's gesture is checkbox-driven, so glyph wins and the rule stays "change the checkbox to reclassify."
- **Per-bucket numbering:** rejected -- three item-1s collide; global is unambiguous.
- **Separate `update` (regenerate) and `sync`:** collapsed -- utilz has nothing to regenerate from but the file; `update` is a back-compat alias for `sync`.
- **Text-substring addressing** (`done "fix parser"`): rejected as primary for ambiguity; positional number is the handle. Possible convenience later.
