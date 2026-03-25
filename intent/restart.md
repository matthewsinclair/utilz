---
verblock: "25 Mar 2026:v0.1: matts - Created after expz addition"
---

# Restart Context

## Key Context

- Framework version is **2.1.0** (VERSION file is the single source of truth)
- 12 utilities installed, all passing `utilz doctor`
- All utility YAMLs updated to `utilz_version: "^2.0.0"`
- Integration test updated to match v2.x major version
- Two remotes: `local` (Dropbox) and `upstream` (GitHub) — push to both

## Recent Decisions

- VERSION file was bumped from 1.3.2 directly to 2.1.0 (was missed for v2.0.0)
- All utility `utilz_version` constraints bumped from `^1.x.x` to `^2.0.0` in this session
- Each utility maintains its own independent version (e.g. expz v1.0.0) separate from the framework version
- `opt/utilz/utilz.yaml` uses `version_file: ../../VERSION` to track framework version; individual utilities use `version: X.Y.Z`

## Files Changed This Session

- `VERSION` — 1.3.2 -> 2.1.0
- `opt/expz/` — new utility (expz v1.0.0)
- `help/expz.md` — new help file
- `bin/expz -> utilz` — new symlink
- `README.md` — added expz section, utility count 11 -> 12
- `CHANGELOG.md` — added [2.1.0] entry
- `opt/*//*.yaml` — all utilz_version bumped to ^2.0.0
- `opt/utilz/test/integration.bats` — version compat test updated for v2.x

## For Next Session

1. Check CI passed: https://github.com/matthewsinclair/utilz/actions
2. Consider adding expz to CI test loop in `.github/workflows/tests.yml`
3. Run `utilz doctor` and `utilz test` to verify state
