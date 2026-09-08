---
verblock: "08 Sep 2026:v0.1: cc - Design for one-home version dispatch"
---

# ST0015 -- Design

## Objective

`--version` is answered in fifteen places and reports the framework version in only some of them. Collapse the dispatch to one home, and make every utility report **both** its own version and the framework's, on a single greppable line.

## What was measured, before any edit

Two invocation forms exist and they answer `--version` by **different mechanisms**:

| form                         | who answers                                      |
| ---------------------------- | ------------------------------------------------ |
| `<util> --version` (symlink) | `bin/utilz:326` intercepts, calls `show_version` |
| `utilz <util> --version`     | args pass through to the implementation          |

Thirteen shell utilities cover the second path by hand-copying an identical three-line arm: `--version) show_version "<name>"; exit 0 ;;`.

**The two utilities that never copied that arm are the two that are broken:**

- **`todo`** has no arm, so `utilz todo --version` prints `✗ Unknown command: --version` -- while `todo --help` documents the flag.
- **`prez`** cannot have one: it is a Rust binary and clap answers `--version` before any shell sees it, giving `prez 2.0.0` against the framework's `prez v2.0.0` plus description plus framework line.

**What is NOT duplicated, recorded because it was suspected and checked:** the version VALUE has one home (each yaml's `version_file`), `show_version()` has one definition (`common.sh:167`), and the framework line has one implementation (`common.sh:191`). Zero of the thirteen arms restate a version or a format; every one delegates. **The Highlander violation here is the ROUTING ARM, not the version.**

An earlier sweep reported 267 affected files. That sweep globbed `*.md` across `.backup/`, which holds eight full historical snapshots; the real count of implementations is one. **The alarming number was an artefact of the instrument** -- the failure mode this project spent 8 Sep cataloguing, arriving one more time in the measurement taken to open this thread.

## Decisions

**D1 -- One intercept, both paths.** `bin/utilz` answers `--version` for a utility regardless of invocation form, before dispatching to the implementation. The thirteen arms are then unreachable and are deleted.

**D2 -- The format is a pair on line one, detail beneath** (hv, 8 Sep):

```
utilz:2.6.1/prez:2.0.0
Markdown to a self-contained HTML presentation -- a pipeline, not a viewer
```

Line one is machine-greppable and carries both numbers, which is the point: **two versions are in play whenever a utility misbehaves, and a bug report carrying only one of them is missing the half that explains it.** Line two preserves what the utility is.

**D3 -- `utilz --version` itself is NOT changed, deliberately.** The framework is not "part of" anything, so the pair form has no second term, and its third line (`installed at <tree> (<sha>)`) is held by an existing acceptance criterion -- it answers "which tree replied", which the two-tree estate makes load-bearing. **Flagged for hv rather than assumed: if the answer is `utilz:2.6.1` for symmetry, it is a one-line change.**

**D4 -- prez is fixed by interception, not by touching the crate.** Once `bin/utilz` answers first, clap never sees `--version`, so the Rust side needs no edit and `crate/Cargo.toml` stays the single home of prez's version. The binary's own `--version` remains reachable by invoking the binary directly, which is correct -- that is a different program being asked.

**D5 -- The 13 deletions are the proof, not a tidy-up.** If the intercept is right, all thirteen arms are unreachable. Leaving them in leaves two homes agreeing by convention, which is the arrangement that produced this defect. **Deleting them is what converts "the dispatcher also handles it" into "the dispatcher handles it."**

## Risks

- **A utility parsing its own args first.** Measured: all thirteen arms sit in the implementation, which the dispatcher `exec`s, so an upstream intercept is strictly earlier. No utility can pre-empt it.
- **`-v` is deliberately not bound** (issue 0003): it reads as verbose. Unchanged.
- **Documentation drift.** Fifteen `help/*.md` and fifteen READMEs mention `--version`. They are documentation, not implementations, but any quoting the old output becomes a stale second description.

## Out of scope

The suite-label wart (`common.sh:810` labels a script with a utility name), found the same day. Separate concern; hv ruled no issue.
