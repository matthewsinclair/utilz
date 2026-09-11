---
node: hv
name: Hypervisor
role: hypervisor
session_id: none
heartbeat_at: 2026-07-29T10:21Z
status: active
focus: "Utilz stable at v2.4.0. No stream in flight."
claims: []
---

# Hypervisor (hv)

Workstream Zero -- the human in the loop. Adjudicates scope, sequences work, owns releases + tags + pushes. Peers read this board at pickup for the standing directives and route escalations to `hv/inbox.<you>.md`.

> Seeded by `cc` on 2026-07-29 while bringing the whiteboard up to the Lamplight / Baize standard. Every directive below is transcribed from an established project rule or a recorded hv decision -- nothing here is inferred or invented. It is hv's board: edit, cut, or add freely.

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
- **ST0017 is culled to market (2026-09-11). No new code, no new tests, no tests of tests.** The one open row is AC-6.3 (cc, an 11-line fixture and test edit). WP-04 (Rust `init`/`qr`) is DEFERRED to a follow-on thread; AC-3.4, AC-4.1, AC-4.2, AC-5.3 withdrawn with that reason. AC-2.19 and the one-off control pass are culled as instrument work. **This line is hv's word: cc and snorkeltoast are released on it. No relay needed.**
- **A relayed ruling is not the ruling.** Peers hold on a peer's relay of hv until hv's word reaches them here or directly. That is correct behaviour; keep it.

## DOING

- **ST0017 closing.** AC-6.3 then `intent st done`. Tag and push on hv's schedule; `upstream` frozen, `local` 8 behind HEAD.

## TODO

- Review the directives above; they were transcribed, not authored, so anything that reads as a rule you never actually set should be cut.

## Watch-outs

- A peer node in **another project** may edit this working tree. Cdsync's `cc` did on 2026-07-29, hv-instructed, while this project's session was live. A `git status` taken mid-session is therefore not a stable baseline -- re-verify before trusting earlier measurements. See the External correspondents section of `intent/whiteboard/README.md`.

## Decisions

- (2026-09-11) **ST0017 culled to market.** Done as the thread defined it is met; init/qr deferred; instrument rows withdrawn.
- (2026-09-10) **Honest partial** on the public-repo fixture: name and socials out, stage handle and contract evidence stay.
- (2026-09-10) **The JPEG encoder divergence is accepted.** No new crate.
- (2026-09-10) **`max_ease` caps to 2400 on both sides.** Safety ruling, outlives its row.

- (2026-07-29) Utilz declares `languages: ["shell"]` only. `elixir` was declared but never used -- no `mix.exs`, no `.ex`/`.exs` -- and was loading two Elixir skills into every session off a stale declaration. Removed via `intent lang remove elixir`.
- (2026-07-29) v2.4.0 is a **minor** bump, not a patch: removing the grep YAML fallback makes `yq` required, so `utilz list` now fails loudly where it previously degraded. Behaviour change that a user can observe drives the minor.
