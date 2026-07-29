---
verblock: "29 Jul 2026:v0.2: matts - Objective and deliverables"
wp_id: WP-03
title: "Generator utilz_version floor derived from VERSION"
scope: Small
status: Done
---

# WP-03: Generator utilz_version floor derived from VERSION

## Objective

Fix a shipped bug: `opt/utilz/tmpl/metadata.tmpl` hardcoded `utilz_version: "^1.0.0"` while `VERSION` reads 2.3.0. `run_doctor` compares major versions, so every utility `utilz generate` produced was born incompatible and stayed that way until someone hand-edited the yaml.

Tracked separately as `intent/issues/OPEN/0002` because it shipped, following the precedent set by issue 0001.

## Deliverables

- `{{UTILZ_FLOOR}}` placeholder in `opt/utilz/tmpl/metadata.tmpl`, replacing the literal `"^1.0.0"`.
- `generate_utility` derives the floor from the framework's own `VERSION` (`^$(get_utilz_version | cut -d. -f1).0.0`) and substitutes it alongside `{{NAME}}` / `{{DESCRIPTION}}` / `{{AUTHOR}}`. (Code already written; see ST info.md Context.)
- BATS coverage AT-03.1 and AT-03.2 in `opt/utilz/test/utilz.bats` -- the stamped floor tracks `VERSION`'s major, and a generated utility passes doctor's compatibility check with no hand-editing.
- Issue 0002 moved to `intent/issues/CLOSED/` with a Resolutions entry when this lands.

## Acceptance

Acceptance Criteria for this work package live in the steel thread's `acceptance.md`, under the `WP-03` heading (single source of truth). Do not restate ACs here.

## Dependencies

- Shares `opt/utilz/lib/common.sh` with WP-01 and WP-02; the three land together.
- The defect is latent, not observed: all 13 existing utilities already carry `^2.0.0`, and `opt/todo/todo.yaml` was born `^2.0.0` in `03ccded` rather than hand-corrected. Nothing in this repo was ever broken by it. See issue 0002.
