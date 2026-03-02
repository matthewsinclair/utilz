# Tasks - ST0006: Move syncz to use unison with rsync fallback

## Tasks

- [x] Add globals: OPT_BACKEND, OPT_FRESH, SYNCZ_BACKEND
- [x] Add --backend and --fresh arg parsing
- [x] Add select_backend() with auto-detect, validation, fallback warning
- [x] Add \_unison_build_common_args() shared arg builder
- [x] Add unison_bidi() with flag mapping and confirmation modes
- [x] Add unison_bidi_dryrun() via mutation-blocking approach
- [x] Add \_compute_path_labels() for D1/D2/Dir path display
- [x] Add SYNCZ_ROOTS_SHOWN env var support for wrapper scripts
- [x] Move rsync availability check from validate_inputs() to select_backend()
- [x] Add backend-aware validations (--fresh+rsync warning)
- [x] Update main flow bidi dispatch to route by backend
- [x] Update usage() text: --bidi section, --backend, --fresh flags, bidi examples
- [x] Update syncz header comment
- [x] Bump syncz.yaml to v2.0.0, add unison optional dep
- [x] Pin existing 66 tests to --backend rsync via run_syncz() helper
- [x] Pin 3 bidi interactive tests (run bash -c) to --backend rsync
- [x] Add 3 backend selection tests (invalid value, force rsync, --fresh+rsync)
- [x] Add 9 unison bidi tests (new files, state tracking, --fresh, --exclude, conflicts, --dry-run plan, --dry-run in-sync, --delete no-op, auto-detect)
- [x] Update help/syncz.md: backend selection, unison/rsync sections, path display, dry-run output, SYNCZ_ROOTS_SHOWN, .webloc known pattern
- [x] Add CHANGELOG.md [2.0.0] entry
- [x] Add unison to CI deps (Ubuntu apt-get, macOS brew)
- [x] Verify all 78 tests pass
- [x] Update version test assertion from 1.4.0 to 2.0.0
- [x] Fix set -e bug: convert `[[ ]] && ...` to `if/fi` in \_unison_build_common_args()
- [x] Add --prefer d1|d2|newer flag with mapping to unison `-prefer`
- [x] Add -rsrc=false to fix macOS resource fork false conflicts
- [x] Move -xattrs=false and -rsrc=false behind --no-metadata flag (caller policy, not hardcoded)
- [x] Add --ignore FILE flag to read exclude patterns from file (`#` comments, whitespace stripping)
- [x] Update \_unison_build_common_args() with --prefer and --no-metadata support
- [x] Update usage() with --prefer, --no-metadata, --ignore flags
- [x] Update help/syncz.md with --prefer, --no-metadata, --ignore documentation

## Descoped (from original spec)

- [ ] R2: Unison uni-mode (rsync works fine, no benefit)
- [ ] R7: Full parsed summary output format (dry-run parses `skipped:` lines; live sync is pass-through)
- [ ] Custom --version backend display (dispatcher intercepts --version)
- [ ] Test helpers: create_unison_scenario(), assert_unison_archive_exists()
