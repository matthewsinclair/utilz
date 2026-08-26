---
st_id: ST0008
title: Add todo to utilz
---

# ST0008: Add todo to utilz -- Acceptance

> **THIS FILE IS A GENERATED VIEW, AND A ROW AUTHORED HERE IS DISCARDED BY THE NEXT SYNC.** The acceptance contract is canon in the thread model; this file renders it. Acceptance Criteria (AC) are the ratified completeness boundary; Acceptance Tests (AT) are the small red-to-green tests that prove them.
>
> Done = every AC is covered by a GREEN AT, or (for a non-test AC) its named evidence is satisfied, AND the AC set is the ratified full boundary. Done is read from this map, never from a hand-ticked box.
>
> Test-backed satisfaction is COMPUTED from covering green ATs and never stored -- storing it would be double truth. An AC has four states, not two: beyond satisfied and unsatisfied, a requirement can be **descoped** to a named thread or **withdrawn** with its reason on the record. Both are non-blocking and both are reported separately, so a thread that descoped half its contract looks like one.

## Acceptance Criteria

### WP-01 -- Scaffold + core: parse, normalize, render, write, file-location, list/add (status: Done)

- AC-01.1 A fresh `list` (no file present) creates `todo.md` from the template: YAML frontmatter with `title: "# TODO"` and `history: _history/YYYYMMDD-done.md`, the `# TODO` H1, and the three buckets `## DOING`, `## TODO`, `## DONE:<ISO-8601-UTC>`, empty buckets shown as `_(none)_`. -- satisfied: yes (computed)
- AC-01.2 `add <text>` appends the item to the bottom of TODO with `[ ]`; `add --top <text>` prepends it to the top of TODO. -- satisfied: yes (computed)
- AC-01.3 Item numbers are global and positional in file order (DOING, TODO, DONE), zero-padded to the max width present (1--9 -> `N`, 10--99 -> `NN`), rendered as `<num>:[<glyph>] <text>`. -- satisfied: yes (computed)
- AC-01.4 File-location precedence: `--file <path>` wins; `-g`/`--global` resolves `${XDG_CONFIG_HOME:-$HOME/.config}/utilz/todo/todo.md`; default is `./todo.md`; `--file` with `-g` errors non-zero. -- satisfied: yes (computed)
- AC-01.5 Writes are atomic (temp + `mv`) and normalization is idempotent: running the write path twice yields a byte-identical file. -- satisfied: yes (computed)

### WP-02 -- Mutation verbs: start, done, notdone, toggle (status: Done)

- AC-02.1 `start <id>` moves the item to DOING as `[-]` (bottom by default, top with `--top`). -- satisfied: yes (computed)
- AC-02.2 `done <id>` moves the item to DONE as `[x]`, prepended so the newest completion is at the top of DONE. -- satisfied: yes (computed)
- AC-02.3 `notdone <id>` moves the item to TODO as `[ ]`. -- satisfied: yes (computed)
- AC-02.4 `toggle <id>` flips done <-> not-done from the item's current glyph. -- satisfied: yes (computed)
- AC-02.5 An unknown `<id>` errors with a clear message and non-zero exit (no silent no-op). -- satisfied: yes (computed)

### WP-03 -- Queries: next, doing, todo, done, count (status: Done)

- AC-03.1 `next` prints the next open item (DOING first, then TODO); `next <n>` prints the next `n`; default 1. -- satisfied: yes (computed)
- AC-03.2 `doing`, `todo`, and bare `done` print their respective buckets. -- satisfied: yes (computed)
- AC-03.3 `count` prints the item count per bucket. -- satisfied: yes (computed)

### WP-04 -- Lifecycle: done --prune (history), done --flush (status: Done)

- AC-04.1 `done --prune` prepends the DONE block to the history file (path from frontmatter `history:`, `YYYYMMDD` expanded to today UTC, resolved relative to the todo.md directory, dirs created), strips the positional number to `[x] <text>`, removes the items from `todo.md`, and stamps `## DONE:<now-UTC>`. -- satisfied: yes (computed)
- AC-04.2 `done --flush` clears the DONE bucket without archiving; it is confirm-guarded and proceeds non-interactively with `--force`/`--just-do-it`. -- satisfied: yes (computed)
- AC-04.3 A custom `history:` pattern in frontmatter is honoured (archive lands at the custom path). -- satisfied: yes (computed)

### WP-05 -- sync + edit (status: Done)

- AC-05.1 `sync` reconciles glyph vs section with glyph authoritative: an item marked `[x]` under `## TODO` relocates to the top of DONE; a `[ ]`/`[-]` under `## DONE` relocates out to TODO/DOING. -- satisfied: yes (computed)
- AC-05.2 `sync` tolerates hand-entered lines -- missing number, stray leading `- `, `[x]foo` with no space -- normalizing and renumbering them. -- satisfied: yes (computed)
- AC-05.3 `sync` warns on stderr for an unrecognizable non-blank line under a bucket and preserves it (never silently dropped). -- satisfied: yes (computed)
- AC-05.4 `update` is an alias that runs `sync`. -- satisfied: yes (computed)
- AC-05.5 `edit` opens the resolved file in `$VISUAL` (else `$EDITOR`, else `vi`) and runs `sync` on exit; with none resolvable it errors clearly. -- satisfied: yes (computed)

### WP-06 -- --json export + Emacs integration block (status: Done)

- AC-06.1 `--json` emits a valid object `{title, doing[], todo[], done[], done_watermark}` parseable by `jq`. -- satisfied: yes (computed)
- AC-06.2 (non-test) `opt/todo/todo.yaml` carries an `integration:` block so the Emacs bridge lists `todo`. -- evidence: `utilz emacs doctor` green (13 exposed) -- satisfied: yes

### WP-07 -- Docs: README + help + doctor deps (status: Done)

- AC-07.1 (non-test) `opt/todo/README.md` and `help/todo.md` document every verb and option. -- evidence: doc review (both written) -- satisfied: yes
- AC-07.2 (non-test) `utilz doctor` and `utilz list` pass with `todo` registered and its deps declared in YAML. -- evidence: `utilz doctor` (todo properly configured; only pre-existing PATH warning) + `utilz list` shows todo -- satisfied: yes

### WP-08 -- utilz todo <-> intent todo mutual guard (utilz side) (status: Done)

- AC-08.1 Every `todo.md` utilz writes carries `generator: utilz todo` in its YAML frontmatter (alongside `title:`/`history:`); the stamp is unconditional -- independent of whether Intent is installed or the file is in an Intent project. -- satisfied: yes (computed)
- AC-08.2 On a mutating command whose target file's frontmatter `generator:` names a different tool (eg `intent todo`), utilz refuses with a clear error and non-zero exit -- but only when BOTH `command -v intent` succeeds AND the file's own directory tree contains a valid Intent project (`intent/.config/config.json`, walking upward from the file's directory). On refusal the file is left byte-unchanged and no history file is created. -- satisfied: yes (computed)
- AC-08.3 A file safe to write is written without error and gains the marker: no frontmatter (legacy Intent / fresh), frontmatter without a `generator:` (utilz's pre-marker `title:`/`history:` file), or `generator: utilz todo` (utilz's own). A foreign-marked file that is NOT inside an Intent project is taken over and re-stamped `generator: utilz todo`. -- satisfied: yes (computed)
- AC-08.4 With Intent absent, utilz never fails or emits an Intent-related message on account of the guard, even for a foreign-marked file inside an Intent project tree (the `command -v intent` gate short-circuits to proceed). -- satisfied: yes (computed)
- AC-08.5 With its DEFAULT path (no `--file`/`-g`) and no `./todo.md` present yet, utilz refuses to CREATE a new file inside an Intent project (Intent installed AND cwd's tree contains `intent/.config/config.json`), directing the user to `intent todo` or `--file`/`-g`; the file is not created and exit is non-zero. Unaffected (all proceed): explicit `--file`/`-g`, an already-existing utilz `./todo.md`, read-only queries that never write, non-Intent directories, and Intent-absent. -- satisfied: yes (computed)

## Acceptance Tests

### WP-01 -- Scaffold + core: parse, normalize, render, write, file-location, list/add (status: Done)

- AT-01.1 (legacy) [opt/todo/test/todo.bats::list creates a template file with frontmatter and buckets] -- covers AC-01.1 -- status: green
- AT-01.2 (legacy) [opt/todo/test/todo.bats::add appends to bottom; add --top prepends] -- covers AC-01.2 -- status: green
- AT-01.3 (legacy) [opt/todo/test/todo.bats::numbers are global, positional, zero-padded to max width] -- covers AC-01.3 -- status: green
- AT-01.4 (legacy) [opt/todo/test/todo.bats::file-location precedence file over global over default; file+g errors] -- covers AC-01.4 -- status: green
- AT-01.5 (legacy) [opt/todo/test/todo.bats::normalization is idempotent] -- covers AC-01.5 -- status: green

### WP-02 -- Mutation verbs: start, done, notdone, toggle (status: Done)

- AT-02.1 (legacy) [opt/todo/test/todo.bats::start moves to DOING as in-progress] -- covers AC-02.1 -- status: green
- AT-02.2 (legacy) [opt/todo/test/todo.bats::done prepends to DONE newest-first] -- covers AC-02.2 -- status: green
- AT-02.3 (legacy) [opt/todo/test/todo.bats::notdone moves back to TODO] -- covers AC-02.3 -- status: green
- AT-02.4 (legacy) [opt/todo/test/todo.bats::toggle flips from current glyph] -- covers AC-02.4 -- status: green
- AT-02.5 (legacy) [opt/todo/test/todo.bats::unknown id errors non-zero] -- covers AC-02.5 -- status: green

### WP-03 -- Queries: next, doing, todo, done, count (status: Done)

- AT-03.1 (legacy) [opt/todo/test/todo.bats::next prints next n open items DOING-first] -- covers AC-03.1 -- status: green
- AT-03.2 (legacy) [opt/todo/test/todo.bats::doing todo done print their buckets] -- covers AC-03.2 -- status: green
- AT-03.3 (legacy) [opt/todo/test/todo.bats::count prints per-bucket counts] -- covers AC-03.3 -- status: green

### WP-04 -- Lifecycle: done --prune (history), done --flush (status: Done)

- AT-04.1 (legacy) [opt/todo/test/todo.bats::prune archives DONE to history newest-first and clears bucket] -- covers AC-04.1 -- status: green
- AT-04.2 (legacy) [opt/todo/test/todo.bats::flush clears DONE with --force and does not archive] -- covers AC-04.2 -- status: green
- AT-04.3 (legacy) [opt/todo/test/todo.bats::custom history pattern is honoured] -- covers AC-04.3 -- status: green

### WP-05 -- sync + edit (status: Done)

- AT-05.1 (legacy) [opt/todo/test/todo.bats::sync relocates by glyph (glyph wins)] -- covers AC-05.1 -- status: green
- AT-05.2 (legacy) [opt/todo/test/todo.bats::sync tolerates hand-entered lines] -- covers AC-05.2 -- status: green
- AT-05.3 (legacy) [opt/todo/test/todo.bats::sync warns and preserves an unrecognizable line] -- covers AC-05.3 -- status: green
- AT-05.4 (legacy) [opt/todo/test/todo.bats::update aliases sync] -- covers AC-05.4 -- status: green
- AT-05.5 (legacy) [opt/todo/test/todo.bats::edit uses EDITOR then syncs] -- covers AC-05.5 -- status: green

### WP-06 -- --json export + Emacs integration block (status: Done)

- AT-06.1 (legacy) [opt/todo/test/todo.bats::--json emits keyed buckets] -- covers AC-06.1 -- status: green

### WP-07 -- Docs: README + help + doctor deps (status: Done)

_(no tests in this group)_

### WP-08 -- utilz todo <-> intent todo mutual guard (utilz side) (status: Done)

- AT-08.1 (legacy) [opt/todo/test/todo.bats::write stamps generator: utilz todo] -- covers AC-08.1 -- status: green
- AT-08.2 (legacy) [opt/todo/test/todo.bats::foreign file in an Intent project with intent present is refused unchanged] -- covers AC-08.2 -- status: green
- AT-08.3 (legacy) [opt/todo/test/todo.bats::safe files own no-frontmatter and no-generator are written] -- covers AC-08.3 -- status: green
- AT-08.4 (legacy) [opt/todo/test/todo.bats::foreign file outside an Intent project is taken over and re-stamped] -- covers AC-08.3 -- status: green
- AT-08.5 (legacy) [opt/todo/test/todo.bats::foreign file with intent absent proceeds without error] -- covers AC-08.4 -- status: green
- AT-08.6 (legacy) [opt/todo/test/todo.bats::refuses to create a fresh default todo.md inside an Intent project] -- covers AC-08.5 -- status: green
- AT-08.7 (legacy) [opt/todo/test/todo.bats::an existing utilz todo.md inside an Intent project still works] -- covers AC-08.5 -- status: green

---

_Generated by Intent v3.0.0 from `thread.json`. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
