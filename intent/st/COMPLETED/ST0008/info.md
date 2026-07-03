---
verblock: "03 Jul 2026:v0.1: matts - Initial version"
intent_version: 2.14.0
status: Completed
slug: add-todo-to-utilz
created: 20260703
completed: 2026-07-03T13:52:13Z
---

# ST0008: Add todo to utilz

## Objective

Add a `utilz todo` utility: a standalone, single-file manager for a plain-text `todo.md` with DOING / TODO / DONE buckets, positional item numbers, and history sweep/purge subcommands. It is a fork of Intent's `intent todo`, made independent of steel threads -- the `todo.md` is the source of truth rather than a projection.

## Context

Factored out of `intent todo` so a plain, project-agnostic todo file can be managed anywhere (cwd `./todo.md` or a global `-g` file). Two hard constraints carry over from Intent: the `todo.md` file format stays mutually compatible (same `## DOING/TODO/DONE:<watermark>` headings, same `[ ]/[-]/[x]` glyphs), and the command names stay identical to `intent todo` wherever the standalone context allows. The full design, including the projection-vs-source-of-truth fork and the divergences (frontmatter, item numbers, no GFM dash), is in `design.md`.

## Acceptance

Acceptance Criteria and Acceptance Tests for this steel thread live in `acceptance.md` (the single source of truth). Do not restate ACs here -- see that file for the ratified completeness boundary and live status.

## Related Steel Threads

- [List any related steel threads here]

## Context for LLM

This document represents a single steel thread - a self-contained unit of work focused on implementing a specific piece of functionality. When working with an LLM on this steel thread, start by sharing this document to provide context about what needs to be done.

### How to update this document

1. Update the status as work progresses
2. Update related documents (design.md, impl.md, etc.) as needed
3. Mark the completion date when finished

The LLM should assist with implementation details and help maintain this document as work progresses.
