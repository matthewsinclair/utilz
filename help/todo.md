# todo

**Version**: run `todo --version`
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

`todo` manages a plain-text `todo.md` file with three buckets -- DOING, TODO, and DONE -- and a handful of subcommands for adding, moving, querying, and archiving items. Each item is a one-line statement carrying an id and a checkbox glyph.

The file is the single source of truth: you can drive it entirely from the CLI, or open it in an editor and hand-edit it, then run `todo sync` to normalize. **An id is the item's name, not its position** (todo 2.0.0): an item keeps its id through every write, so an id cited in a note, a board or a handover still names the same item tomorrow, and a new item takes the next id the file has never used. Ids are zero-padded to three, so the column keeps its shape as they cross ten and a hundred (past 999 they widen rather than truncating).

`todo` is a standalone fork of Intent's `intent todo`. The two file formats are mutually compatible (same bucket headings, same `[ ]`/`[-]`/`[x]` glyphs, same `## DONE:<watermark>` line), so a `todo.md` written by one is readable by the other. Because the formats are that close, each tool stamps a `generator:` frontmatter marker and refuses to overwrite a file the other owns -- see [Interop with intent todo](#interop-with-intent-todo).

### File format

```markdown
---
generator: utilz todo
title: "# TODO"
history: _history/YYYYMMDD-done.md
next-id: 4
---

# TODO

## DOING

- [-] `001` An item currently being worked on

## TODO

- [ ] `002` Something to do next

## DONE:2026-07-02T00:00:00Z

- [x] `003` Something already finished
```

Item lines are GFM task-list items, so a `todo.md` renders as a real checklist
anywhere markdown is rendered rather than collapsing into one paragraph. The id
sits **after** the checkbox, in a code span, because a task-list marker only
counts when it directly follows the bullet. `[-]` for DOING is not a GFM marker
and renders as literal text: the glyph is what `sync` and `toggle` reconcile
against, and a DOING item under its own heading is clear enough without a box.

Reading is tolerant of the pre-2026-09 shape (`01:[ ] text`, no dash), of a
missing id, and of loose spacing, so an older file or a hand-pasted line parses.
Writing is always the current shape. Every id a line carries is kept; a line with no id, or with an id an earlier line already carries, takes the next id the file has never used, and a duplicate is warned about by both its ids. `utilz todo sync` migrates a file in place, every id unchanged.

The frontmatter carries the `generator` ownership marker (see [Interop with intent todo](#interop-with-intent-todo)), the H1 `title`, a `history` pattern (where `todo done --prune` archives completed items, each with its id; `YYYYMMDD` expands to the purge date, resolved relative to the `todo.md` directory), and `next-id`, the next id the file has never used. **`next-id` is load-bearing**: it is the only record of the ids above the highest one still present, so deleting it by hand lets a pruned id be handed out again.

### Ordering

- In DOING and TODO, top-to-bottom is priority: the next / most important item is at the top.
- In DONE (and in the history file), newest completion is at the top.

### Interop with intent todo

`todo` and Intent's `intent todo` share the file format closely enough that each could parse -- and accidentally rewrite -- the other's `todo.md`. To prevent that, both stamp an ownership marker in the frontmatter:

```
generator: utilz todo
```

`todo` refuses to overwrite a `todo.md` whose `generator:` names a different tool (eg `intent todo`). The refusal is **Intent-aware**: it fires only when Intent is actually installed _and_ the file sits inside an Intent project (a directory tree containing `intent/.config/config.json`, searched upward from the file). Anywhere else -- Intent not installed, or a plain `todo.md` outside any Intent project -- `todo` just works, silently, and takes ownership by stamping its own marker. A file with no frontmatter, or one already marked `generator: utilz todo`, is always safe to write.

For the same reason, `todo` will not **create** a fresh default `./todo.md` inside an Intent project: a bare `utilz todo` there refuses and points you to `intent todo` (or `--file`/`-g`), so it never plants a competing todo file in an Intent directory. Explicit `--file`/`-g`, an existing utilz `./todo.md`, and read-only queries are unaffected.

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
- `sync` (alias `update`) - Normalize the file: reconcile checkboxes, relocate, give an id to any line that has none
- `edit` - Open the file in `$VISUAL`/`$EDITOR`/`vi`, then `sync` on exit
- `done --prune` - Archive DONE to the history file, then clear it
- `done --flush` - Clear DONE WITHOUT archiving (add `--force`, or its alias `--just-do-it`, to skip the prompt)
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

`num` is the item's id, as `list` shows it, and it stays the same through every write. Requires `jq`.

---

## Examples

```bash
# Start a list and add a few items
todo add "Write the design doc"
todo add "Review the PR"
todo add --top "Fix the failing build"     # jumps to the top of TODO

# Move things around -- by id, which stays with the item
todo start 3        # begin "Fix the failing build", which add gave id 3
todo done 3         # complete it (-> DONE, newest at top)
todo toggle 1       # flip item 1

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
- `1` - Error (an id no item carries, a missing argument, `--file` with `-g`, etc.)

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
