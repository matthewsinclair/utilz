---
verblock: "27 Nov 2026:v1.54: matts - one index for both restart files"
---

# Restart Context

An index of where each thing is kept. Git holds the history.

| You want                             | Read                                                 |
| ------------------------------------ | ---------------------------------------------------- |
| What is being worked on now          | `intent/wip.md`, `intent outstanding`                |
| Live state, rulings and watch-outs   | `intent wb pickup --node <you>`, `intent wb show vc` |
| What shipped, and when               | `CHANGELOG.md`, `git tag`                            |
| Steel threads and work packages      | `intent st list --status all`, `intent st show <ID>` |
| Open defects                         | `intent issues list`                                 |
| How to cut and what follows a cut    | `docs/releasing.md`                                  |
| Architecture, conventions, extending | `docs/architecture.md`, `docs/developer-guide.md`    |
| Design principles                    | `docs/design-principles.md`                          |
| The tool-agnostic agent contract     | `AGENTS.md` (generated: never hand-edit)             |
| The DO / NEVER contract              | `usage-rules.md`                                     |
| Claude-specific overlay              | `CLAUDE.md`                                          |
| Framework version                    | `VERSION` (single source of truth)                   |
| Per-utility command reference        | `help/<name>.md`, or `utilz help <name>`             |
| The roster and the whiteboard rules  | `intent/whiteboard/README.md`                        |
