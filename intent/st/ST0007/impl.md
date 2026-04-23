# Implementation - ST0007: Emacs bindings for Utilz utilities

## Implementation

Work is split across four work packages, each landing on a green test run before proceeding. See `intent/st/ST0007/WP/` for per-WP info documents once created.

- **WP01** — YAML metadata + generator template.
- **WP02** — `utilz emacs` dispatcher subcommand (`commands` / `install` / `doctor`).
- **WP03** — Elisp bridge (`static/emacs/utilz.el`).
- **WP04** — End-to-end verification + user-facing docs (README, CHANGELOG).

Implementation notes, snippets, and surprises land here as each WP closes out. Empty below until WP01 starts.

## Code Examples

Reserved for representative snippets as implementation progresses (YAML block shape, TSV emitter, elisp dispatch helper).

## Technical Details

- Files touched: `opt/utilz/utilz`, `opt/utilz/lib/common.sh`, `opt/*/*.yaml` (12 files), `opt/utilz/tmpl/metadata.tmpl`, `static/emacs/utilz.el` (new), `help/utilz.md`, `opt/utilz/test/utilz.bats`.
- No new runtime dependencies. `yq` already required; no new shell deps. No new elisp packages (Vertico + shell-command-on-region ship with Doom).
- Bash 3.2 compatibility required for macOS CI (per existing memory on array/unbound-variable pitfalls).

## Challenges & Solutions

Empty until challenges actually surface. Candidates to watch:

- YAML `emacs:` block parsing in bash — confirm `yq` handles nested keys predictably without JSON coercion.
- `shell-command-on-region` with `replace=t` plus non-zero exit — need to confirm region is preserved when the command fails (may require shelling out via `call-process-region` and handling replacement ourselves).
- Doom's numbered-custom load order — ensure `utilz.el` is idempotent-on-reload so users can `M-x eval-buffer` safely.
