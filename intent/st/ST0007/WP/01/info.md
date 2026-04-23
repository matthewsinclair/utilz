---
verblock: "23 Apr 2026:v0.1: matts - Initial version"
wp_id: WP-01
title: "YAML emacs metadata and template update"
scope: Small
status: Not Started
---

# WP-01: YAML emacs metadata and template update

## Objective

Add declarative `emacs:` capability metadata to each of the 12 utility YAMLs per the ST0007 design matrix (input: stdin | file | path | none; output: replace | buffer | message | discard). Update `opt/utilz/tmpl/metadata.tmpl` so future `utilz generate` scaffolds include a commented `emacs:` stub. No dispatcher or elisp changes in this WP.

## Deliverables

- Updated `opt/<n>/<n>.yaml` for all 12 utilities with an `emacs:` block matching the design matrix.
- Updated `opt/utilz/tmpl/metadata.tmpl` with commented-out `emacs:` stub.
- All YAMLs continue to parse cleanly via `yq`.

## Acceptance Criteria

- [ ] All 12 YAMLs have an `emacs:` block with `input` and `output` fields populated per the design matrix.
- [ ] `utilz doctor` still passes (YAMLs parse, dependencies resolve).
- [ ] `utilz test utilz` still passes (no regressions).
- [ ] Generator template has the commented `emacs:` stub so `utilz generate <name>` scaffolds with it.
- [ ] `yq '.emacs' opt/<n>/<n>.yaml` returns the expected structure for every utility.

## Dependencies

- None. Pure data addition; no code paths consume the `emacs:` block yet (WP02 is the first reader).
