# todo

**Version**: 1.0.0
**Author**: Matthew Sinclair

---

## Name

`todo` - Simple DOING/TODO/DONE manager for a plain-text `todo.md`

---

## Synopsis

```bash
todo [OPTIONS] [COMMAND] [ARGS]
```

---

## Description

`todo` manages a plain-text `todo.md` file with three buckets -- DOING, TODO, and DONE -- and a handful of subcommands for adding, moving, querying, and archiving items. Each item is a one-line statement carrying a positional number and a checkbox glyph.

The file is the single source of truth: you can drive it entirely from the CLI, or open it in an editor and hand-edit it, then run `todo sync` to normalize. Numbers are re-derived on every write and zero-padded to a shared column width so the file always stays aligned.

`todo` is a standalone fork of Intent's `intent todo`. The two file formats are mutually compatible (same bucket headings, same `[ ]`/`[-]`/`[x]` glyphs, same `## DONE:<watermark>` line), so a `todo.md` written by one is readable by the other.

### File format

```markdown
---
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

The frontmatter carries the H1 `title` and a `history` pattern (where `todo done --prune` archives completed items; `YYYYMMDD` expands to the purge date, resolved relative to the `todo.md` directory).

### Ordering

- In DOING and TODO, top-to-bottom is priority: the next / most important item is at the top.
- In DONE (and in the history file), newest completion is at the top.

---

## Commands

- `list` (or no command) - Show the file; create it from a template if absent
- `add [--top] <text>` - Add an item to TODO (bottom by default, top with `--top`)
- `start [--top] <id>` - Move item `<id>` to DOING
- `done <id>` - Move item `<id>` to DONE (prepended: newest at the top)
- `notdone <id>` - Move item `<id>` back to TODO
- `toggle <id>` - Flip item `<id>` between done and not-done
- `next [n]` - Show the next `n` open items (DOING first, then TODO); default 1
- `doing` | `todo` | `done` - Show a single bucket
- `count` - Show item counts per bucket
- `sync` (alias `update`) - Normalize the file: reconcile checkboxes, relocate, renumber
- `edit` - Open the file in `$VISUAL`/`$EDITOR`/`vi`, then `sync` on exit
- `done --prune` - Archive DONE to the history file, then clear it
- `done --flush` - Clear DONE WITHOUT archiving (add `--force` to skip the prompt)
- `help` - Show help

### Checkbox reconciliation (glyph wins)

`sync` treats the checkbox as authoritative. If you hand-edit `todo.md` and change an item's box to `[x]` while it still sits under `## TODO`, `sync` relocates it to the top of DONE. The section a line lives in is derived from its glyph -- so to reclassify an item by hand, change its checkbox, not the heading it sits under.

---

## Options

- `--file <path>` - Operate on `<path>` instead of `./todo.md`
- `-g, --global` - Operate on `~/.config/utilz/todo/todo.md` (honours `XDG_CONFIG_HOME`)
- `--title <text>` - Set the H1 title when creating a new file
- `--json` - Emit the view as JSON (with `list` / no command)
- `-h, --help` - Show help
- `--version` - Show version

`--file` and `-g` are mutually exclusive.

### JSON output

`todo --json` emits the whole view as a single JSON object for scripting:

```json
{
  "title": "# TODO",
  "doing": [{ "num": 1, "text": "..." }],
  "todo": [{ "num": 2, "text": "..." }],
  "done": [{ "num": 3, "text": "..." }],
  "done_watermark": "2026-07-02T00:00:00Z"
}
```

Item numbers match the ids shown by `list`. Requires `jq`.

---

## Examples

```bash
# Start a list and add a few items
todo add "Write the design doc"
todo add "Review the PR"
todo add --top "Fix the failing build"     # jumps to the top of TODO

# Move things around
todo start 1        # begin the top item (-> DOING)
todo done 1         # complete it (-> DONE, newest at top)
todo toggle 3       # flip item 3

# Query
todo next           # the single next thing to work on
todo next 3         # the next three
todo count          # counts per bucket

# Hand-edit then normalize
todo edit           # opens $EDITOR, then syncs on exit
todo sync           # or normalize an already-edited file

# Archive completed work
todo done --prune                 # move DONE to _history/YYYYMMDD-done.md
todo done --flush --force         # discard DONE without archiving

# A global, machine-wide list
todo -g add "Renew the domain"

# JSON for scripting
todo --json | jq '.todo[].text'
```

---

## Files

- `./todo.md` - Default todo file (current directory)
- `~/.config/utilz/todo/todo.md` - Global todo file (`-g`)
- `<todo-dir>/_history/YYYYMMDD-done.md` - Default archive for `done --prune`
- `$UTILZ_HOME/opt/todo/todo` - Implementation
- `$UTILZ_HOME/opt/todo/todo.yaml` - Metadata

---

## Environment

- `UTILZ_HOME` - Root directory of Utilz framework
- `VISUAL`, `EDITOR` - Editor used by `todo edit` (VISUAL preferred, then EDITOR, then `vi`)
- `XDG_CONFIG_HOME` - Base for the global file (defaults to `~/.config`)

---

## Exit Status

- `0` - Success
- `1` - Error (bad item number, missing argument, `--file` with `-g`, etc.)

---

## See Also

- `utilz(1)` - Utilz framework dispatcher
- Intent's `intent todo` - the projection-based ancestor this forks from

---

## Author

Matthew Sinclair

---

## Copyright

Copyright (c) 2026 Matthew Sinclair
Part of the Utilz framework.
