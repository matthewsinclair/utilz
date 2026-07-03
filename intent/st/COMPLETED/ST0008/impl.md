# Implementation - ST0008: Add todo to utilz

## Implementation

Delivered as a standard Utilz utility scaffolded with `utilz generate todo`:

- `opt/todo/todo` -- implementation (~500 lines bash).
- `opt/todo/todo.yaml` -- metadata; `utilz_version: "^2.0.0"`, `jq` dependency (optional, for `--json`), and an `integration:` block (`input: none`, `output: buffer`).
- `opt/todo/test/todo.bats` -- 24 BATS tests, named to match the acceptance ATs.
- `help/todo.md`, `opt/todo/README.md` -- docs.
- `bin/todo -> utilz` -- dispatcher symlink.

The architecture is the shared-normalizer core from `design.md`: one tolerant `parse_file`, one atomic `write_file` (temp + `mv`), and every mutating verb is `parse_file -> mutate arrays -> write_file`. `sync` is the no-mutation path through the same core. Item state lives in three indexed arrays (`DOING_ITEMS`/`TODO_ITEMS`/`DONE_ITEMS`) holding text only; the glyph is derived from the bucket. Numbering is computed at render time (global, positional, zero-padded to `${#TOTAL}` width).

## Technical Details

- **Glyph-authoritative parse.** Each line is routed to a bucket by its checkbox glyph, not the section heading it sits under (the reconciliation rule). Because the DOING/TODO sections are physically above DONE, a hand-marked `[x]` under TODO naturally lands at the top of DONE on the next write -- no special "move to top" code needed.
- **Tolerant item regex:** `^[[:space:]]*(- )?([0-9]+:)?\[([ xX-])\] ?(.*)$` -- absorbs a stray GFM `- ` (Intent paste), a missing number, and `[x]foo` with no space.
- **History (`done --prune`):** `history:` frontmatter pattern; `YYYYMMDD` -> `date -u +%Y%m%d`, resolved relative to the todo.md dir; DONE block prepended `[x] <text>` (numbers stripped), newest-first preserved because DONE is already newest-first.
- **File resolution:** `--file` > `-g` (`${XDG_CONFIG_HOME:-$HOME/.config}/utilz/todo/todo.md`) > `./todo.md`; `--file` + `-g` is a hard error.
- **JSON:** `--json` builds `{title, doing[], todo[], done[], done_watermark}` via `jq`, each bucket an array of `{num, text}` with ids matching `list`.

## Challenges & Solutions

- **Generator `sed` choked on the description.** `utilz generate todo "…DOING/TODO/DONE…"` failed because the `/` broke the `sed` substitution. Resolved by scaffolding with a slash-free description, then setting the real description in `todo.yaml`.
- **Bash 3.2 (macOS CI).** No associative arrays / namerefs: array element removal uses an eval-based `_splice_out`; empty-array expansions are guarded with `${arr[@]+"${arr[@]}"}`; loop/function tails use `if/fi` (never a bare `[[ ... ]] && cmd`).
- **`edit` + `$VISUAL` precedence.** `edit` honours `$VISUAL` then `$EDITOR` then `vi`. The bats test clears `VISUAL` and points `EDITOR` at a stub, because an inherited interactive `$VISUAL` would block.
- **Core bridge test count.** Adding `todo`'s `integration:` block took the manifest from 12 to 13 utilities; updated `opt/utilz/test/bridge.bats` accordingly (`utilz emacs doctor` confirms 13 exposed).

## Verification

`utilz test todo` -> 24/24 green. Full suite `utilz test` -> 14/14 suites green. `utilz doctor` reports todo properly configured (only the pre-existing PATH warning). `utilz emacs doctor` -> all green.
