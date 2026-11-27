# Utilz Usage Rules

This file is the terse DO / NEVER contract for work in Utilz. `AGENTS.md`, which `intent agents sync` generates, says how Utilz builds, tests and tracks its work, and `intent llm guide` lists every command.

## NEVER DO

- Never edit `AGENTS.md` directly: `intent agents sync` generates it.
- Never edit the hook stanzas in `.claude/settings.json`: re-apply them with `intent claude upgrade --apply`.
- Never bypass the pre-commit gate with `--no-verify` on a shared branch without a reason in the commit message.
- Never create steel thread or work package directories by hand: use `intent st new` and `intent wp new`.
- Never edit a `status:` field in a thread's frontmatter: use the `intent st` and `intent wp` verbs.
