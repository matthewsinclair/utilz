---
verblock: "29 Jul 2026:v0.2: matts - Objective and context filled in"
intent_version: 2.17.3
status: Completed
slug: framework-core-single-bin-walker-single-yaml
created: 20260729
completed: 2026-07-29T09:56:19Z
---

# ST0009: Framework core: single bin walker, single YAML parser, correct generator floor

## Objective

Land three defects found in the framework core -- two Highlander violations in `opt/utilz/lib/common.sh` and one shipped bug in the generator template -- as a documented, tested change, and make `yq` an honestly-declared hard dependency rather than a silently-degrading optional one.

## Context

This steel thread is **retroactive**, and the record should say so plainly.

On 2026-07-29 the `cc` node of the **Vboot** project was reading `../Utilz/bin/utilz*` as the reference implementation for a new CLI API shim. It found three defects, reported them to hv, and was told "let's nip over to Utilz and fix those, please. Just do it inline." It edited this repo's working tree directly, from outside the project, between roughly 09:05 and 09:25 UTC -- while this project's own `cc` session was live and unaware. Utilz's `cc` node found the changes uncommitted and uncovered during pickup triage, flagged them as an orphaned refactor, and blocked on hv for a framing ruling. Vboot's `cc` then wrote to `cc/inbox.vboot-cc.md` claiming provenance and owning the unannounced edit as its error. hv ruled: proceed and fix.

So the code preceded the paperwork, in violation of this project's doc-before-code rule. It is documented here rather than reverted because it is correct, verified, and fixes a real defect. What was genuinely missing -- and is the substance of this thread -- is **test coverage for the new seams**, plus the documentation reconciliation and the release call that a behaviour change requires.

The three defects:

1. **Two open-coded YAML parsers** in `get_util_metadata` -- a `yq` path and a grep fallback answering four hardcoded queries, returning an empty string for every other query. A caller cannot distinguish that empty string from an absent key. (Highlander + No-Silent-Errors.) WP-02.
2. **Five open-coded walks of `bin/*`** -- in `list_utilities`, `run_doctor` (twice), `run_tests`, `emit_integration_tsv`, and `emacs_doctor`. They had already drifted: two verified the symlink resolved to `utilz`, three accepted any symlink, so a stray link in `bin/` was a utility to `doctor` and not to `list`. (Highlander.) WP-01.
3. **`opt/utilz/tmpl/metadata.tmpl` hardcoded `utilz_version: "^1.0.0"`** while `VERSION` reads 2.3.0. `run_doctor` compares major versions, so every utility `utilz generate` produced was born incompatible. Latent -- see `intent/issues/OPEN/0002`. WP-03.

Defect 3 makes `yq` a hard dependency, which is user-visible behaviour change: `utilz list` now fails loudly where it previously degraded silently. That drives a minor version bump, not a patch.

## Acceptance

Acceptance Criteria and Acceptance Tests for this steel thread live in `acceptance.md` (the single source of truth). Do not restate ACs here -- see that file for the ratified completeness boundary and live status.

## Related Steel Threads

- ST0007 -- introduced `emit_integration_tsv` and `emacs_doctor`, two of the five drifted `bin/` walkers this thread collapses.
- ST0008 -- added the `todo` utility, the most recent utility generated while defect 3 was live.

## Context for LLM

This document represents a single steel thread - a self-contained unit of work focused on implementing a specific piece of functionality. When working with an LLM on this steel thread, start by sharing this document to provide context about what needs to be done.

### How to update this document

1. Update the status as work progresses
2. Update related documents (design.md, impl.md, etc.) as needed
3. Mark the completion date when finished

The LLM should assist with implementation details and help maintain this document as work progresses.
