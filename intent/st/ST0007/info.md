---
verblock: "23 Apr 2026:v0.1: matts - Initial version"
intent_version: 2.4.0
status: WIP
slug: emacs-bindings-for-utilz-utilities
created: 20260423
completed:
---

# ST0007: Emacs bindings for Utilz utilities

## Objective

Deliver a thin, metadata-driven bridge that exposes Utilz commands inside Emacs (Doom) so a user can pick a utility from a `completing-read` menu, have the current region (or whole buffer, or a file / directory) fed to it according to declared capability, and either replace the region in place, dump output into a side buffer, or surface a message — with non-zero exits preserved and surfaced. The bridge is delivered as a generic elisp file (`static/emacs/utilz.el`) that the user installs into their Doom config (as `160-utilz.el`) via symlink, plus a new core subcommand `utilz emacs {commands,install,doctor}` that publishes the capability manifest and wires installation.

## Context

Utilz is a dispatcher-based bash/zsh utility framework with 12 utilities (v2.1.0). The user works heavily in Doom Emacs and wants frictionless access to text-filter utilities (most immediately `cleanz --detrope` on a buffer) without leaving the editor. Existing Utilz output (`utilz list`, `utilz help`) is human prose only; per-utility YAML has no capability metadata. This ST adds the minimum declarative surface needed for a robust, auto-registering Emacs bridge — and carries the dispatcher pattern (`utilz generate`, `utilz doctor`) into a sibling `utilz emacs` subcommand so future utilities auto-scaffold the emacs block and are discoverable in the bridge without further elisp edits.

## Related Steel Threads

- None. First work in v2.2 series.

## Context for LLM

This document represents a single steel thread - a self-contained unit of work focused on implementing a specific piece of functionality. When working with an LLM on this steel thread, start by sharing this document to provide context about what needs to be done.

### How to update this document

1. Update the status as work progresses
2. Update related documents (design.md, impl.md, etc.) as needed
3. Mark the completion date when finished

The LLM should assist with implementation details and help maintain this document as work progresses.
