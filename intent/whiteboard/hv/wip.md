---
node: hv
name: Hypervisor
role: hypervisor
session_id: none
heartbeat_at: 2026-07-29T10:21Z
status: active
focus: "Cut the release after 2.8.0."
claims: []
---

# Hypervisor (hv)

## Standing directives

- **No Claude attribution in commits. Ever.** No `Co-Authored-By`, no generated-with footers. Commits end with `(C) hello@matthewsinclair.com`. (Project + global rule.)
- Commit straight to `main`; no feature branches (solo project). Confirmed 2026-07-29: "we don't need to branch anything".
- **Doc before code**: ST + WP + `design.md` before any source edit. The hard-line rule for this project.
- A tracked issue in `intent/issues/` may drive a focused bugfix without a full ST (2026-07-10 ruling, issue 0001). Doc-before-code still holds for feature work. A defect that _shipped_ earns an issue even when the fix lands inside a steel thread (2026-07-29, issue 0002 alongside ST0009/WP-03).
- **bash 3.2 compatible** -- macOS ships 3.2.57 and CI runs it. No namerefs, no `${var,,}`. Guard `"${arr[@]}"` under `set -u`; never end a function or loop body with a bare `[[ ... ]] && cmd`.
- 2-space indent, every language. Markdown tables column-aligned. No em dashes, no non-printing characters.
- Use the Intent CLI for lifecycle -- `intent st`, `intent wp`, `intent claude ws`, `intent lang`. Never hand-create the directories or hand-edit `status:` frontmatter.
- **Releases are hv's.** Annotated tag on the `release:` commit itself (not on the session's final HEAD -- see `v2.3.0` and `v2.4.0`), then `git push local main <tag> && git push upstream main <tag>`. Both remotes, always.
- `yq` is a hard dependency of the framework as of v2.4.0. `utilz doctor` must still complete without it.
- **No new code, no new tests, no tests of tests, beyond what a thread's Done requires.** Set 2026-09-11 when ST0017 was culled to market. WP-04 (Rust `init`/`qr`) is a follow-on thread if wanted.
- **A relayed ruling is not the ruling.** Peers hold on a peer's relay of hv until hv's word reaches them here or directly. That is correct behaviour; keep it.

## DOING

_(none)_

## TODO

- Cut the release after `2.8.0`; it carries ST0017 (`prez showreel`).
- Review the standing directives; they were transcribed, not authored. Cut any you never set.
