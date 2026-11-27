# Utilz: Session Entry Point

**This file holds no state.** It says where to start.

## Start here, in this order

1. **Run `/in-session`.** Required on every session start and after every `/compact` or context reset. It loads the coding skills for the project's declared languages, releases the `UserPromptSubmit` gate, and chains `/in-whiteboard pickup`.
2. **`intent/wip.md`**: what is being worked on now and what is queued. DOING and TODO only.
3. **`intent/restart.md`**: an index of where everything is kept. Git holds the history.
4. **`intent/whiteboard/<your-node>/`**: if you are a workstream node, your board and your inboxes. Roster and protocol in `intent/whiteboard/README.md`.

## The three rules that are not negotiable

- **No Claude attribution in commits.** No `Co-Authored-By`, no generated-with footer. Commits end with `(C) hello@matthewsinclair.com`.
- **Doc before code.** ST + WP + `design.md` before any source edit.
- **Releases, tags and pushes are hv's.** Never push on your own initiative.
