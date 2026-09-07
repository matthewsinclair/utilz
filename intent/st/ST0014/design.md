---
verblock: "07 Sep 2026:v0.1: matts - the two-tree arrangement: owned set, manifest, the four refusals, and the two places a runnable install differs from devbin's"
---

# ST0014: Design

**This document carries HOW the install is built, and deliberately not what it is for.** The scope is `acceptance.md` (AC01-AC13); the thread's Objective and Context are empty by hv's ruling of 2026-09-07. Rows are cited here, never restated, and where a decision was ruled rather than chosen the row carries the reasoning while this document carries the mechanism. A scope summary here would be the thread's scope in a third place, drifting against two copies neither node is reading.

## D1. The install machinery is a NEW library, not more of `common.sh`

`bin/utilz:58` sources `opt/utilz/lib/common.sh` unconditionally, before it looks at `INVOKED_AS`. Every one of the fifteen utilities therefore parses the whole of it on every invocation. It is 1218 lines today; devbin's equivalent install library is 942. Folding install machinery in would roughly double what `cleanz` parses in order to do something `cleanz` will never call.

So: **`opt/utilz/lib/install.sh`, sourced only from the `install` / `upgrade` / `link` branches of the dispatcher.** `bin/utilz` parses the verb and calls one entry point per verb and does nothing else (IN-AG-THIN-COORD-001). Inside the library, the owned set, the manifest and the install-versus-source diff are pure functions of a tree path; the copying, the building and the refusals are the coordination around them (IN-AG-PFIC-001).

The library depends on `common.sh` for `error` / `require_command` / `get_util_metadata` and on nothing else. It must never reach for state that describes the tree it is RUNNING in, because every function in it operates on a tree that is not that one.

## D2. The owned set

| Ships                                             | Why                                                                       |
| ------------------------------------------------- | ------------------------------------------------------------------------- |
| `bin/utilz`                                       | the dispatcher                                                            |
| the 15 `bin/<name>` symlinks                      | AC06, and see D3 -- they are the dispatch predicate, not decoration       |
| `opt/<name>/<name>`, `<name>.yaml`, `README.md`   | the implementations and the metadata every read goes through              |
| `opt/utilz/lib/`, `opt/utilz/tmpl/`               | the framework library and the generator templates                         |
| `help/*.md`                                       | `utilz help` reads these at runtime                                       |
| `VERSION`                                         | `utilz.yaml` points `version_file` at it                                  |
| `static/emacs/utilz.el`                           | `utilz emacs install` reads it from `$UTILZ_HOME`                         |
| `opt/prez/crate/target/release/prez`              | built at publish, AC09                                                    |

| Excluded                     | Why                                                                                                     |
| ---------------------------- | -------------------------------------------------------------------------------------------------------- |
| `opt/*/test/`                | AC13 refuses `utilz test` from an install, so shipping the suites ships the input to a command that says no |
| `opt/prez/crate/` (source)   | `include_str!` compiles `themes/` and `assets/` INTO the binary, so the crate is build-time only. 170M     |
| `intent/`, `docs/`, `.git`   | project record, not runtime                                                                              |

**The owned set is enumerated in exactly one function** and both `install` and `upgrade` read it from there (IN-AG-HIGHLANDER-001). The manifest's roll-call IS the owned set, so a second enumeration is a second answer about what the tool owns, and the one that drifts is whichever nobody is reading.

## D3. Symlinks are copied as target STRINGS, and they are load-bearing

`cp` dereferences a symlink. A naive copy therefore produces fifteen 8.5KB copies of the dispatcher in a tree that still works, so nothing fails and nothing says anything. Checksumming the resolved file is worse than useless: all fifteen hash identically, so a link retargeted at the wrong utility reads as intact (AC06).

Two consequences for the mechanism:

- **Read with `readlink`, recreate with `ln -s`.** Not `cp -R` and its per-platform argument about whether `-R` follows: making the target string the thing the code handles is what makes AC06 checkable rather than incidental.
- **The manifest row for a link records the target string**, not a content hash. See D4.

They are not cosmetic. `bin/utilz:183` dispatches only when `-L "$UTILZ_HOME/bin/$UTIL_NAME"` holds, so a utility whose symlink did not arrive is not a utility with a cosmetic defect -- it does not dispatch at all, and the dispatcher's error path suggests it as a typo.

## D4. The manifest

One file at the install root, three columns, one row per owned path, sorted with `LC_ALL=C` so it is stable across filesystems:

```
utilz-version   2.5.0
source-commit   <sha>
file            <sha256>   bin/utilz
link            utilz      bin/cleanz
```

The type discriminator is what lets the checker pick the right comparison without inferring it from the path (AC06, AC07). **No generated-at timestamp**: a timestamp makes two manifests of identical bytes compare unequal, which turns the one instrument that reports drift into a thing that always reports drift.

`upgrade` reports a file whose on-disk hash differs from its manifest row and leaves it alone without `--force` (AC08). **A file it declined to overwrite keeps its install-time row, never a re-checksum of what is there now.** Re-checksumming a refused file records the edit as canonical and the next check pronounces it intact, which is the refuse-then-bless failure: the refusal still prints, and the evidence that made it necessary is destroyed by the same pass.

## D5. prez: built at publish, and the shim refuses (AC09)

`cargo build --release` runs against the SOURCE crate at publish time; the resulting binary is copied into the owned set. The install ships no crate source.

Two mechanisms the shim needs, and the second is a hazard I did not expect to find:

- **The shim must know it is in an install and refuse, rather than reach the refusal by accident.** Read `prez_is_stale()` at `opt/prez/prez`: it returns stale when the binary is missing, and otherwise runs `find "$CRATE_DIR/src" ... -newer "$BINARY" ... 2>/dev/null || true`. With no crate shipped, `find` errors on every path, the error is suppressed, `newer` is empty, and the answer is "not stale". **It works, and it works for the wrong reason** -- a suppressed error standing in for a decision. AC09's "refuses rather than falls back" is satisfied only when the install branch is explicit: manifest present means install, install means never build, and a missing binary is a named refusal rather than a build.
- **`CARGO_TARGET_DIR` must be ignored in install mode.** The shim honours it deliberately (`TARGET_DIR="${CARGO_TARGET_DIR:-$CRATE_DIR/target}"`, and the comment above it records the measured defect that forced it). But an install resolves its binary at a path fixed at publish time, so a user who happens to have that variable exported in their shell would send the install looking somewhere it never wrote. The variable is correct for a source tree and wrong for an install, and the discriminator is the same one: the manifest.

## D6. The prefix, and the trap in the reader (AC05)

`install.prefix` is read from `opt/utilz/utilz.yaml` in the SOURCE tree, through `get_util_metadata` like every other metadata read. No built-in default; unset is refused by name.

**`get_util_metadata` returns the literal four-character string `null` for an absent key.** It ends `echo "$result"`, and `yq eval '.install.prefix' opt/utilz/utilz.yaml` prints `null` today -- measured, not assumed. So the obvious guard is wrong in the silent direction:

```bash
# WRONG. "null" is four characters, so this passes, and the publish
# then writes a directory called ./null and reports success.
v="$(get_util_metadata utilz '.install.prefix')"
[[ -n "$v" ]] || die_no_prefix
```

The reader must treat `null` and empty alike as unset. This is `restart.md`'s standing trap in a new costume -- a default is a claim about what an unreadable answer means, and here the unreadable answer arrives wearing a valid-looking value rather than an empty one.

Two more properties, both inherited from devbin having paid for them:

- **Tilde expansion happens in the reader.** A YAML scalar is not a shell word, so an unexpanded `~/Devel/opt/utilz` creates a directory literally named `~` under the cwd, and every later command then finds the install exactly where it looked. Silent and self-consistent.
- **Unset returns rc 1, not an empty string.** A caller that forgets to check an empty return proceeds and writes to `/bin`; a caller that forgets to check rc 1 is killed by `set -e` at the assignment. Only one of those is silent.

## D7. Mode and the four refusals

The mode is announced before anything is written (AC10). A discriminator that is merely correct is not enough: a misdetection has to arrive in the output rather than be discovered later in the filesystem.

| Refusal                                    | Predicate                                                         | Row  |
| ------------------------------------------ | ----------------------------------------------------------------- | ---- |
| dirty source tree                          | `git status --porcelain` over the WHOLE tree, non-empty           | AC02 |
| target is a Utilz source tree              | a property of the TARGET, never `src == dst`                      | AC03 |
| `install` when an install already exists   | manifest present at the prefix; names `upgrade`                   | AC04 |
| `upgrade` when none exists                 | manifest absent at the prefix; names `install`                    | AC04 |

**The dirty gate reads the whole tree, not the owned subset.** The manifest's claim is "these bytes are commit X", and that is only true when nothing in the tree is uncommitted -- a dirty `.md` beside a clean `opt/` still means the recorded commit does not describe the checkout the bytes came from. A tree that is not a git repository at all must return a distinct status: "no changes" and "cannot tell" must not render as the same answer. **No `--force` on this one** (AC02).

**AC03's predicate is a property of the target alone**, derived rather than named: a tree that could be published FROM but carries no manifest is a source checkout. Comparing source to destination was devbin's guard and it did not hold -- the harm has nothing to do with the two being equal.

## D8. Telling the two trees apart at the prompt (AC12)

`utilz version` reports which tree answered and what it was cut from: `installed 2.5.0 (<commit>) at <prefix>` against `source 2.5.0 at <root>`, discriminated by the manifest. Without it the two-tree arrangement is invisible in precisely the situation it exists for -- someone debugging behaviour cannot tell which copy produced it, and the version string is identical either way.

## D9. The PATH cutover is its own verb (AC11)

`install` and `upgrade` write nothing outside the prefix. Relinking `~/.local/bin/*` is mutating the operator's environment mid-session and needs a verb they typed: **`utilz link --prefix <dir>`**, separate and explicit.

It normalises while it is there. Today `~/.local/bin/prez` is a RELATIVE link to `bin/utilz` while the other fourteen are ABSOLUTE links to `bin/<util>`. Both work, because the dispatcher reads `basename "$0"` for `INVOKED_AS` and resolves `UTILZ_HOME` from the resolved path either way. Two conventions in one directory is a false red waiting for the first doctor check that asserts one of them: one absolute link per utility, to `<prefix>/bin/<name>`.

## D10. What is shared with `emacs_install`, and what is not

`emacs_install` (`opt/utilz/lib/common.sh:967`) already implements `--dest`, `--symlink`, `--force` and tilde expansion. The tilde expansion and the flag parsing are extracted and shared (IN-AG-HIGHLANDER-001).

**The refusal policy is NOT shared, and that boundary is deliberate.** `emacs_install` writes into a directory the user nominates; publish refuses a dirty tree, refuses an existing install and refuses a source tree. Common mechanism, different contract. Folding the refusals into the shared half would give `emacs_install` three gates nobody asked it for, which is a worse defect than the small duplication it would remove.

## D11. Build order, and the one test that has to come first

WP-01 (owned set + manifest) -> WP-02 (`install`) -> WP-04 (the runnable-install guards) -> WP-03 (`upgrade`) -> WP-05 (AC01 end to end).

`upgrade` sits after the guards because it is the mirror of `install` (AC04) and mirroring something still moving costs more than waiting.

**AC01 is the row the whole thread turns on and it is the one most easily faked.** `determine_utilz_home` at `bin/utilz:17-53` walks the symlink chain, takes `dirname`, and returns the parent of `bin/`, so `<prefix>/bin/utilz` should yield `UTILZ_HOME=<prefix>` with no dispatcher change at all. **That is a code read and not a measurement, and it is recorded here as one.** An install that silently reaches back into `~/Devel/prj/Utilz` passes every check that does not move the source aside, and it passes them looking exactly like success -- which is why AC01 is written to move the source tree aside rather than to assert that files arrived.
