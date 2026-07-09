# todo

**Version**: 1.0.0
**Part of**: [Utilz Framework](../../README.md)

Simple DOING/TODO/DONE manager for a plain-text `todo.md`.

`todo` manages a flat markdown todo file with three buckets and a small set of subcommands for adding, moving, querying, and archiving items. The file is the single source of truth -- drive it from the CLI, or hand-edit it and run `todo sync` to normalize. It is a standalone fork of Intent's `intent todo`, with a mutually compatible file format; each tool stamps a `generator:` marker and refuses to overwrite a file the other owns (see [Interop with intent todo](#interop-with-intent-todo)).

## Quick start

```bash
todo add "Write the design doc"     # -> TODO
todo add --top "Fix the build"       # -> top of TODO
todo start 1                         # -> DOING
todo done 1                          # -> DONE (newest at top)
todo next                            # what to work on next
todo done --prune                    # archive DONE to _history/YYYYMMDD-done.md
```

## File format

```markdown
---
generator: utilz todo
title: "# TODO"
history: _history/YYYYMMDD-done.md
---

# TODO

## DOING

01:[-] An item currently being worked on

## TODO

02:[ ] Something to do next

## DONE:2026-07-02T00:00:00Z

03:[x] Something already finished
```

- Each item is `<number>:[<glyph>] <text>`. Numbers are global, positional, and zero-padded to a shared width; they are re-derived on every write.
- Glyphs: `[ ]` todo, `[-]` doing, `[x]` done.
- In DOING/TODO top-to-bottom is priority; in DONE (and the history file) newest is on top.
- Frontmatter: `generator` marks the file as utilz-owned (see [Interop](#interop-with-intent-todo)); `title` is the H1; `history` is the archive path pattern for `done --prune` (`YYYYMMDD` expands to the purge date, relative to the file's directory).

## Commands

| Command                   | Does                                                      |
| ------------------------- | --------------------------------------------------------- |
| `list` / (none)           | Show the file (create from template if absent)            |
| `add [--top] <text>`      | Add to TODO (bottom, or top with `--top`)                 |
| `start [--top] <id>`      | Move item to DOING                                        |
| `done <id>`               | Move item to DONE (newest at top)                         |
| `notdone <id>`            | Move item back to TODO                                    |
| `toggle <id>`             | Flip done / not-done                                      |
| `next [n]`                | Next `n` open items (DOING first, then TODO); default 1   |
| `doing` / `todo` / `done` | Show one bucket                                           |
| `count`                   | Counts per bucket                                         |
| `sync` (alias `update`)   | Normalize: reconcile checkboxes, relocate, renumber       |
| `edit`                    | Open in `$VISUAL`/`$EDITOR`/`vi`, then sync               |
| `done --prune`            | Archive DONE to the history file, then clear it           |
| `done --flush`            | Clear DONE without archiving (`--force` skips the prompt) |

## Options

| Option           | Does                                             |
| ---------------- | ------------------------------------------------ |
| `--file <path>`  | Operate on `<path>` instead of `./todo.md`       |
| `-g, --global`   | Operate on `~/.config/utilz/todo/todo.md`        |
| `--title <text>` | Set the H1 title when creating a new file        |
| `--json`         | Emit the view as JSON (with `list` / no command) |

`--file` and `-g` are mutually exclusive.

## Checkbox reconciliation (glyph wins)

`sync` treats the checkbox as authoritative. Flip an item's box to `[x]` in your editor and `sync` files it under DONE -- even if the line is still sitting under `## TODO`. To reclassify an item by hand, change its checkbox, not the heading it sits under.

## Interop with intent todo

`todo` and Intent's `intent todo` share the file format closely enough that each could parse -- and accidentally rewrite -- the other's `todo.md`. Both stamp an ownership marker (`generator: utilz todo` / `generator: intent todo`) and refuse to overwrite a file the other owns.

utilz's refusal is **Intent-aware**: it fires only when Intent is installed _and_ the target file sits inside an Intent project (a tree containing `intent/.config/config.json`, searched upward from the file). Anywhere Intent is not in play -- not installed, or a `todo.md` outside any Intent project (eg the global `-g` file) -- `todo` runs silently and takes ownership by stamping its own marker. Files with no frontmatter, or already marked `generator: utilz todo`, are always safe to write.

The same awareness gates **creation** on the default path: a bare `utilz todo` inside an Intent project (with no `./todo.md` yet) refuses rather than plant a competing todo file -- use `intent todo`, or pass `--file`/`-g`. Explicit `--file`/`-g`, an existing utilz `./todo.md`, and read-only queries are unaffected.

## JSON

```bash
todo --json | jq '.todo[].text'
```

Emits `{title, doing[], todo[], done[], done_watermark}`, where each bucket is an array of `{num, text}`. Requires `jq`.

## Testing

```bash
utilz test todo
```

## See also

- `utilz help todo` - full help
- `intent/st/ST0008/design.md` - design and rationale
- Intent's `intent todo` - the projection-based ancestor this forks from
