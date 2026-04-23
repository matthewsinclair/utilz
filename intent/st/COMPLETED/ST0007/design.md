# Design - ST0007: Emacs bindings for Utilz utilities

## Approach

A metadata-first design. Two small additions on the Utilz side (an editor-neutral `integration:` block in each utility YAML + new dispatcher subcommand families split by scope: `utilz integration commands` for the neutral TSV manifest, `utilz emacs {install,doctor}` for Emacs-specific verbs) and one new elisp file in the repo (`static/emacs/utilz.el`) that the user symlinks into `~/.config/doom/custom/160-utilz.el`. The elisp is a thin coordinator: it reads a TSV capability manifest emitted by `utilz integration commands`, offers a Vertico `completing-read` menu, resolves input according to each utility's declared `input` kind (stdin | file | path | none), runs the utility, and dispatches output according to the declared `output` kind (replace | buffer | message | discard).

The design deliberately pushes all YAML parsing into the Utilz side. The elisp never opens a YAML file — the TSV is the only cross-boundary contract. This preserves the Highlander rule: there is one place that walks the utility corpus to build the Emacs-visible catalogue.

Phase 0 (this document plus its work-package siblings) lands _before_ any source edit. Phase 1 (WP01-WP04) touches code only after Phase 0 is committed.

## Design Decisions

### 1. Declarative capability metadata in each YAML

Each `opt/<n>/<n>.yaml` gains an optional `integration:` block. Absence means "not auto-exposed to the bridge". Shape:

```yaml
integration:
  input: stdin # stdin | file | path | none
  output: replace # replace | buffer | message | discard
  flags: [] # always-pass flags (rare)
  prompts: [] # flag suggestions for C-u prompt
```

Categories per utility:

| Utility | input | output  | Rationale                                     |
| ------- | ----- | ------- | --------------------------------------------- |
| cleanz  | stdin | replace | Motivating case. Region/buffer in, clean out. |
| xtrct   | stdin | buffer  | Structured extraction -> JSON in side buffer  |
| mdagg   | stdin | buffer  | Aggregates md -> dump result                  |
| clipz   | none  | message | Clipboard ops; Emacs has kill-ring anyway     |
| pdf2md  | file  | buffer  | Needs a real file path, shows md result       |
| expz    | path  | buffer  | Wants a directory; show CSV                   |
| cryptz  | file  | message | Mutates files on disk                         |
| syncz   | path  | buffer  | Shows rsync/unison output                     |
| gitz    | path  | buffer  | Status dump                                   |
| lnrel   | path  | message | Creates symlink, short result                 |
| macoz   | none  | message | System actions                                |
| retry   | none  | buffer  | Wraps any command; shows transcript           |

### 2. Two new dispatcher subcommand families: `utilz integration` + `utilz emacs`

Live in `opt/utilz/utilz`, dispatched alongside the existing `list`, `doctor`, `generate`, `test`. The split is by scope: a neutral manifest surface shared across all integration targets, and editor-specific installers layered on top.

**`utilz integration <verb>`** — editor-neutral manifest surface.

- `commands` emits TSV (one row per utility that has an `integration:` block): `name<TAB>description<TAB>input<TAB>output<TAB>flags`. TSV over JSON so consumers don't pull in a `jq` dependency. Any integration target (Emacs, future VSCode / Zed / Vim plugins) consumes this directly — there is no per-editor walker.

**`utilz emacs <verb>`** — Emacs-specific installer + health check.

- `install [--dest PATH] [--symlink]` copies (or symlinks) `static/emacs/utilz.el` to PATH, prints the `(load "...")` line the user adds to their loader. Does not edit the user's config for them. Idempotent.
- `doctor` verifies `utilz` is on the PATH Emacs will see, all YAMLs parse, every utility has an `integration:` block (or is explicitly absent), and — if an install destination exists — that the installed file matches the repo copy.

Future integration targets slot in as parallel families (e.g. `utilz vscode install`, `utilz vim install`) — they all consume the same `utilz integration commands` TSV, so the editor-neutral and editor-specific seams stay clean.

### 3. Elisp shape — Thin Coordinator + PFIC

`static/emacs/utilz.el` at ~150-200 lines max. Responsibilities:

- **Discover** — `utilz-refresh` shells out to `utilz integration commands`, parses TSV into `utilz--commands-alist`. Cached on load.
- **Dispatch** — one interactive `utilz` command. `completing-read` over the alist with an `:annotation-function` for descriptions. Looks up capability, resolves input, runs, renders output.
- **Input helpers** (one small function per kind): `utilz--input-stdin`, `utilz--input-file`, `utilz--input-path`, `utilz--input-none`.
- **Output helpers** (one per kind): `utilz--output-replace`, `utilz--output-buffer`, `utilz--output-message`, `utilz--output-discard`.
- **Flags** — no prefix = YAML-declared `flags` only. `C-u` = prompt for extras via `read-string`. `C-u C-u` = confirm full command line before running (for scarier utilities like cryptz, syncz).
- **Errors** — non-zero exit pops a stderr buffer and leaves region/buffer untouched. `No Silent Errors` guaranteed.
- **Keybinding** — one prefix: `C-c u` -> `utilz`. User layers more if wanted.

Transient menu is **explicitly out of scope** for v1 (Vertico `completing-read` only). Transient is available in the user's Doom config and is a clean future enhancement.

### 4. Distribution and install

The canonical elisp lives in the Utilz repo at `static/emacs/utilz.el` — Emacs-convention filename that matches its `(provide 'utilz)` form. The user installs it by symlinking (preferred: `ln -s .../static/emacs/utilz.el ~/.config/doom/custom/160-utilz.el`) or by running `utilz emacs install --dest ~/.config/doom/custom/160-utilz.el --symlink`. Symlinking means `git pull` in Utilz rolls the bridge forward automatically. `utilz emacs install` never edits `config.el`; it prints the `(load "160-utilz.el")` line for the user to paste.

## Architecture

Flow of a single invocation (e.g. `M-x utilz` -> `cleanz` on a region):

```
  Doom Emacs                     shell                        Utilz
  ----------                     -----                        -----
  M-x utilz
    completing-read
    (utilz--commands-alist)
    user picks "cleanz"
    input-kind = stdin
    output-kind = replace
      |
      v
    shell-command-on-region  ---- cleanz --detrope  ------>  runs cleanz
    (region, "cleanz --detrope",
     replace=t)                                               stdout <--
      |                                                        stderr <--
      v                                                        exit status <--
    if exit != 0:
      pop *utilz-stderr*
      region untouched
    else:
      region replaced
      (undo-boundary set)
```

The bridge never parses YAML. The manifest TSV is read once per Emacs session (or on `M-x utilz-refresh`).

### Agnostic rule enforcement

- **Highlander**: `emit_integration_tsv` in `opt/utilz/lib/common.sh` is the single walker of the YAML corpus. Both `utilz integration commands` and the Emacs bridge (and any future VSCode / Zed / Vim integration) consume it — no parallel walker.
- **Thin Coordinator**: `utilz-run` in elisp parses intent -> calls utility -> renders output. No inline transformation logic.
- **PFIC**: dispatch on `input`/`output` kind via small composable functions, not a monolithic `cond`.
- **No Silent Errors**: non-zero exits always surface; region/buffer is never replaced on failure.

## Alternatives Considered

1. **Parse `utilz list` prose in elisp + hardcode capability map in the bridge.** Rejected: drifts when utilities are added; violates Highlander (two places know about the utility set); makes the bridge Emacs-side-only.

2. **JSON over TSV.** Rejected: adds a `jq` dependency or forces bespoke JSON parsing in bash. TSV covers every field we need (name, description, input, output, flags) and is trivial to emit and parse.

3. **Hand-maintain the elisp in Doom config only, no Utilz-repo copy.** Rejected by the user: two sources of truth if the Doom config is backed up separately.

4. **Transient menu as v1 surface.** Deferred: the user already runs Vertico everywhere; `completing-read` is the lower-friction starting point. Transient grouping (text filters / file ops / clipboard / system) is a good v2.

5. **Auto-generate per-utility commands** (`utilz-cleanz`, `utilz-xtrct`, …) via a defmacro loop at load time. Deferred: the single `utilz` entry point with `completing-read` covers the motivating workflow; per-command aliases are easy to add later if the user wants to bind them to specific keys.
