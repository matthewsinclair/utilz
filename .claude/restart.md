# Utilz -- Session Entry Point

**This file holds no state.** It says where to start. Current work, status, versions and history live in exactly one place each, and this file names them rather than summarising them -- a summary here becomes a third copy of the same narrative with a third value, and nothing reports the divergence.

## Start here, in this order

1. **Run `/in-session`.** Required on every session start and after every `/compact` or context reset. It loads the coding skills for the project's declared languages, releases the `UserPromptSubmit` gate, and chains `/in-whiteboard pickup`.
2. **`intent/wip.md`** -- what is being worked on now and what is queued. DOING and TODO only.
3. **`intent/restart.md`** -- what you need to know before touching anything: current state, conventions, the traps that produced real defects here, and the verification checklist for a fresh checkout.
4. **`intent/whiteboard/<your-node>/`** -- if you are a workstream node, your board and your inboxes. Roster and protocol in `intent/whiteboard/README.md`.

## Where everything else lives

| You want                         | Read                                                 |
| -------------------------------- | ---------------------------------------------------- |
| What shipped, and when           | `intent/done.md`, `CHANGELOG.md`                     |
| Steel threads and work packages  | `intent st list --status all`, `intent st show <ID>` |
| Open defects                     | `intent issues list` (see note below)                |
| The tool-agnostic agent contract | `AGENTS.md` (generated -- never hand-edit)           |
| Claude-specific overlay          | `CLAUDE.md`                                          |
| Architecture and how to extend   | `docs/architecture.md`, `docs/developer-guide.md`    |
| Framework version                | `VERSION` (single source of truth)                   |
| Per-utility command reference    | `help/<name>.md`, or `utilz help <name>`             |

## The three rules that are not negotiable

- **No Claude attribution in commits.** No `Co-Authored-By`, no generated-with footer. Commits end with `(C) hello@matthewsinclair.com`.
- **Doc before code.** ST + WP + `design.md` before any source edit.
- **Releases, tags and pushes are hv's.** Never push on your own initiative.
