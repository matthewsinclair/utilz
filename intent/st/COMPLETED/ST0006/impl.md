# Implementation - ST0006: Move syncz to use unison with rsync fallback

## Implementation

### Scope reduction from original spec

The original info.md spec (R1-R10) described a full unison wrapper with output parsing, summary format translation, uni-mode unison support, and extensive flag mapping. Implementation was scoped down to a **thin bidi-only wrapper** based on design review, then iteratively refined with real-world testing.

What was built (vs. spec):

| Spec requirement          | Built?  | Notes                                                                            |
| ------------------------- | ------- | -------------------------------------------------------------------------------- |
| R1: Backend detection     | Yes     | `select_backend()` with auto-detect + `--backend`                                |
| R2: Unison uni-mode       | No      | Descoped — rsync works fine for uni-mode                                         |
| R3: Unison bidi           | Yes     | `unison_bidi()` with `_unison_build_common_args()` extraction                    |
| R4: Archive management    | Yes     | `--fresh` maps to `-ignorearchives`                                              |
| R5: Rsync fallback        | Yes     | Existing code unchanged, pinned via `--backend rsync`                            |
| R6: CLI changes           | Yes     | `--backend`, `--fresh`, `--prefer`, `--no-metadata`, `--ignore FILE` flags added |
| R7: Summary output format | Partial | Dry-run parses `skipped:` lines into `[new]/[changed]/[CONFLICT]` tags           |
| R8: Testing               | Yes     | 12 new tests, 66 existing pinned to rsync                                        |
| R9: Documentation         | Yes     | help/syncz.md fully updated with backend sections                                |
| R10: Version/metadata     | Yes     | v2.0.0, yaml updated, CI updated                                                 |

### Files modified

| File                          | Change summary                                                                                                                                                                                                           |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `opt/syncz/syncz`             | `select_backend()`, `_compute_path_labels()`, `_unison_build_common_args()`, `unison_bidi_dryrun()`, `unison_bidi()`, arg parsing (`--backend`, `--fresh`, `--prefer`, `--no-metadata`, `--ignore FILE`), header comment |
| `opt/syncz/syncz.yaml`        | v2.0.0, unison optional dep                                                                                                                                                                                              |
| `opt/syncz/test/syncz.bats`   | `run_syncz()` pinned to rsync, 12 new tests                                                                                                                                                                              |
| `help/syncz.md`               | Full rewrite of bidi section, path display, dry-run output, env vars                                                                                                                                                     |
| `CHANGELOG.md`                | `[2.0.0]` entry                                                                                                                                                                                                          |
| `.github/workflows/tests.yml` | unison added to Ubuntu and macOS CI deps                                                                                                                                                                                 |

### Key implementation details

**`_compute_path_labels()`** (line ~447): Splits two paths into arrays by `/`, walks backwards to find the longest common suffix, then constructs `_PATH_ROOT1`, `_PATH_ROOT2` (unique prefixes) and `_PATH_SUFFIX` (common tail). Used by both `unison_bidi()` and `unison_bidi_dryrun()` for the `D1:/D2:/Dir:` display.

**`_unison_build_common_args()`** (line ~523): Extracted common unison arg construction shared between dry-run and real sync. Sets `_UNISON_ARGS` array with: roots, `-times`, `-ui text`, optional `-xattrs=false -rsrc=false` (--no-metadata), `-prefer` mapping (d1→dir1 path, d2→dir2 path, newer, or raw passthrough), `-ignorearchives` (--fresh), `-ignore "Name PAT"` for excludes, `-backup` args, and `-terse` when not verbose.

**`unison_bidi_dryrun()`** (line ~548): Runs unison with all mutations blocked (`-nocreation`, `-nodeletion`, `-noupdate` on both roots) in `-batch -auto` mode. Captures output, parses `skipped:` lines using regex to extract filenames and reasons. Classifies each entry by checking filesystem state:

- File exists in dir1 only → `[new] D1 → D2`
- File exists in dir2 only → `[new] D2 → D1`
- Both exist + reason contains "contents changed on both sides" → `[CONFLICT]`
- Both exist otherwise → `[changed]`
- Directory-only entries are filtered out.

**`unison_bidi()`** (line ~638): Delegates to `unison_bidi_dryrun()` when `OPT_DRY_RUN` is true. Otherwise builds args via `_unison_build_common_args()` and handles confirmation mode branching. Respects `SYNCZ_ROOTS_SHOWN` env var to suppress header.

**`select_backend()`** (line ~492): Auto-detects unison for bidi mode via `command -v unison`. Validates chosen backend is available. Only warns about rsync fallback when the user didn't explicitly choose rsync.

### Confirmation mode mapping (unison bidi)

| syncz flags         | unison behavior                                     |
| ------------------- | --------------------------------------------------- |
| (default)           | `-batch -auto` (no prompts)                         |
| `--force`           | `-batch -auto` (no prompts)                         |
| `--confirm` (bare)  | No `-batch`, unison prompts per-file                |
| `--confirm yes/all` | `-batch -auto` (auto-accept all)                    |
| `--confirm no`      | Abort immediately, don't run unison                 |
| `--just-do-it`      | Show header, single Y/N prompt, then `-batch -auto` |

## Challenges & Solutions

### Dry-run: unison has no -dryrun flag

The original spec assumed unison had `-dryrun`. It does not. Solution: block all mutations using `-nocreation/-nodeletion/-noupdate` on both roots. Unison still detects changes and reports them as `skipped:` lines, which are parsed into the `[new]/[changed]/[CONFLICT]` display format.

### set -e bug with `[[ ]] && ...`

`_unison_build_common_args()` originally had `[[ "$OPT_VERBOSE" != "true" ]] && _UNISON_ARGS+=(-terse)` as its last line. When verbose was true, the `&&` short-circuit set the function's exit code to 1, killing the script under `set -e`. Fixed by converting to `if/fi`. This is a known bash 3.2 pitfall documented in MEMORY.md.

### Dispatcher intercepts --version

The utilz dispatcher (`bin/utilz`) handles `--version` before dispatching to the utility script (line 180). The plan to show backend info in `--version` output was not possible without modifying the dispatcher. Solution: dropped the custom `--version` handler from syncz.

### Existing bidi interactive tests auto-selected unison

Tests 57-59 used `run bash -c` directly (not `run_syncz()`) to pipe interactive input. After implementation, these auto-selected unison (installed locally), causing failures because unison's interactive prompts don't match the piped Y/N/A input. Solution: added `--backend rsync` to these three test commands.

### .webloc conflicts in real-world testing

Real-world testing with Dropbox ↔ Google Drive revealed ~86 `.webloc` files showing as `[CONFLICT]` (modified on both sides). Both cloud providers rewrite bookmark metadata. Not a bug — unison correctly identifies these. Documented as a known pattern in help/syncz.md with a suggested `--exclude "*.webloc"` workaround.
