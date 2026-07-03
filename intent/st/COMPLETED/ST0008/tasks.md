# Tasks - ST0008: Add todo to utilz

## Tasks

- [x] WP-01 Scaffold + core: parse, normalize, render, write, file-location, list/add
- [x] WP-02 Mutation verbs: start, done, notdone, toggle
- [x] WP-03 Queries: next, doing, todo, done, count
- [x] WP-04 Lifecycle: done --prune (history), done --flush
- [x] WP-05 sync + edit
- [x] WP-06 --json export + Emacs integration block
- [x] WP-07 Docs: README + help + doctor deps

## Task Notes

All acceptance ATs are covered by the 24-test BATS suite (`opt/todo/test/todo.bats`); the non-test ACs (integration block, docs, doctor/list) are satisfied with evidence recorded in `acceptance.md`.

## Dependencies

- `jq` -- optional, required only for `todo --json` (declared in `todo.yaml`).
