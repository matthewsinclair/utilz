---
verblock: "07 Sep 2026:v0.1: matts - the two-tree arrangement: owned set, manifest, the four refusals, and the two places a runnable install differs from devbin's"
---

# ST0014: Design

**This document carries HOW the install is built, and deliberately not what it is for.** The scope is `acceptance.md` (AC01-AC13); the thread's Objective and Context are empty by hv's ruling of 2026-09-07. Rows are cited here, never restated, and where a decision was ruled rather than chosen the row carries the reasoning while this document carries the mechanism. A scope summary here would be the thread's scope in a third place, drifting against two copies neither node is reading.

## D1. The install machinery is a NEW library, not more of `common.sh`

`bin/utilz:58` sources `opt/utilz/lib/common.sh` unconditionally, before it looks at `INVOKED_AS`. Every one of the fifteen utilities therefore parses the whole of it on every invocation. It is 1218 lines today; devbin's equivalent install library is 942. Folding install machinery in would roughly double what `cleanz` parses in order to do something `cleanz` will never call.

So: **`opt/utilz/lib/install.sh`, sourced only from the `install` / `upgrade` / `link` branches of the dispatcher.** `bin/utilz` parses the verb and calls one entry point per verb and does nothing else (IN-AG-THIN-COORD-001). Inside the library, the owned set, the manifest and the install-versus-source diff are pure functions of a tree path; the copying, the building and the refusals are the coordination around them (IN-AG-PFIC-001).

The library depends on `common.sh` for `error` / `require_command` / `get_util_metadata` and on nothing else. It must never reach for state that describes the tree it is RUNNING in, because every function in it operates on a tree that is not that one.

## D2. The owned set is enumerated by EXCLUSION, and git is the authority

`git ls-files` over four roots plus `VERSION`, minus the excluded subtrees, plus the one built artefact:

| Root      | Excluded within it   | Why                                                                                                         |
| --------- | -------------------- | ----------------------------------------------------------------------------------------------------------- |
| `bin/`    | `devbin`, `.devbin/` | vendored devbin, not ours to publish                                                                        |
| `opt/`    | `*/test/`            | AC13 refuses `utilz test` from an install, so shipping the suites ships the input to a command that says no  |
| `opt/`    | `prez/crate/`        | `include_str!` compiles `themes/` and `assets/` INTO the binary, so the crate is build-time only. 170M       |
| `help/`   | --                   | `utilz help` reads these at runtime                                                                         |
| `static/` | --                   | `utilz emacs install` reads `utilz.el` from `$UTILZ_HOME`                                                    |
| `VERSION` | --                   | `utilz.yaml` points `version_file` at it                                                                    |

Plus `opt/prez/crate/target/release/prez`, which is built at publish and gitignored, so it is named rather than enumerated (D5).

**Measured 7 Sep: 109 tracked paths -- 15 symlinks and 94 files -- and one built binary. 43M, of which 42M is `opt/macoz/images/`.**

**THIS SECTION CARRIED AN INCLUSION LIST UNTIL 7 SEP AND THE LIST WAS WRONG.** It shipped `opt/<name>/<name>`, `<name>.yaml` and `README.md` per utility, which is the shape the tree APPEARS to have. A walk of all sixteen directories says otherwise: **five utilities keep runtime payload outside those three names** -- `opt/cleanz/data/trope-indicators.txt` (the detector list, read at `cleanz:343`), `opt/expz/lib/expense_schema.json` (the default schema), `opt/pdf2md/lib/pdf2md.py` and `opt/xtrct/lib/xtrct.py` (the actual implementations, each shell file being a venv wrapper around one), and `opt/macoz/images/backgrounds/` (read at `macoz:59`). An inclusion list publishes an install in which five of fifteen utilities are broken, **each failing only when someone reaches the one code path that needs the file that never arrived.**

**The inversion is the keeper, not the corrected list.** An inclusion list asserts that today's layout is the layout, so the next utility to add a data directory is dropped silently, and the drop surfaces as a bug report against that utility rather than against the installer. An exclusion list fails the other way -- a new subtree ships until someone says not to -- which costs bytes rather than correctness.

**Git is the authority here for the same reason it is in the manifest.** The manifest's claim is "these bytes are commit X"; `git ls-files` is exactly "the files commit X names". Any other enumeration makes the file list and the provenance claim two authorities that agree right up until they do not. After AC02's dirty gate the two are identical by construction -- a tracked file missing from the worktree IS a dirty tree, and that is already refused -- so the gate is what makes this correct rather than merely convenient. It also disposes of `.venv/` (101M across two utilities) and `crate/target/` at no cost: both are gitignored, so neither was ever a candidate.

**The owned set is enumerated in exactly one function**, and `install` and `upgrade` both read it from there (IN-AG-HIGHLANDER-001). The manifest CHECKER does not: it reads the manifest, which is the roll-call written from that one enumeration. That is the same single answer at one remove, and it is what lets the checker run in an install tree, which has no git and therefore nothing to enumerate from. A second enumeration would be a second answer about what the tool owns, and the one that drifts is whichever nobody is reading.

**The built prez binary is owned wherever the tree carries the crate to build it from, and nowhere else.** That predicate is the same one the publish uses to decide whether to run cargo at all (D5), so the binary cannot leave the owned set while there is still something to build. Built as-implemented on 7 Sep: naming it unconditionally made every tree without a prez crate fail its own manifest write, which is a correct refusal aimed at the wrong tree.

**One file ships that has no business in an install, and it is named here rather than special-cased: `static/emacs/e2e-smoke.el`.** It is a test -- its own header says to run it from the repo root -- and it escapes the `*/test/` exclusion by not living in a `test/` directory. Six kilobytes, inert, reached by no verb. Excluding it by filename would set a second KIND of rule, name-matching, beside one that is otherwise purely structural, to save 6KB. The honest fix is to move the file in the source tree, and that is not this thread's.

## D3. Symlinks are copied as target STRINGS, and they are load-bearing

`cp` dereferences a symlink. A naive copy therefore produces fifteen 8.5KB copies of the dispatcher in a tree that still works, so nothing fails and nothing says anything. Checksumming the resolved file is worse than useless: all fifteen hash identically, so a link retargeted at the wrong utility reads as intact (AC06).

Two consequences for the mechanism:

- **Read with `readlink`, recreate with `ln -s`.** Not `cp -R` and its per-platform argument about whether `-R` follows: making the target string the thing the code handles is what makes AC06 checkable rather than incidental.
- **The manifest row for a link records the target string**, not a content hash. See D4.

They are not cosmetic. `bin/utilz:183` dispatches only when `-L "$UTILZ_HOME/bin/$UTIL_NAME"` holds, so a utility whose symlink did not arrive is not a utility with a cosmetic defect -- it does not dispatch at all, and the dispatcher's error path suggests it as a typo.

## D4. The manifest

One file at the install root, `manifest.sha256`, three TAB-separated columns, one row per owned path, sorted with `LC_ALL=C` so the order is stable across filesystems:

```
utilz-version	2.5.0
source-commit	<sha>
file	<sha256>	bin/utilz
link	utilz	bin/cleanz
```

**The separator is one TAB, not aligned spaces.** No owned path contains a space today -- measured, 0 of 109 -- but a space separator makes the third column unparseable the day one does, and the day one does is not a day anybody announces.

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

The mode is announced before anything is written (AC10), and before the refusals as well, so a run that is about to be refused still says what it thought it was doing. A discriminator that is merely correct is not enough: a misdetection has to arrive in the output rather than be discovered later in the filesystem.

| Refusal                                  | Predicate                                               | `--force`? | Row  |
| ---------------------------------------- | ------------------------------------------------------- | ---------- | ---- |
| dirty source tree                        | `git status --porcelain` over the WHOLE tree, non-empty | never      | AC02 |
| source is not a git repository           | distinct from clean; provenance cannot be established   | never      | AC02 |
| target is a Utilz source tree            | a property of the TARGET, never `src == dst`            | never      | AC03 |
| `install` when an install already exists | manifest present at the prefix; names `upgrade`         | yes        | AC04 |
| `upgrade` when none exists               | manifest absent at the prefix; names `install`          | no         | AC04 |

**`--force` reaches exactly one row and the table says which.** It is the only refusal whose subject is a tree the publish is entitled to replace; every other row protects something the publish would destroy or misrepresent. AT02 pins this by repeating the dirty case with every flag the verb accepts.

**The dirty gate reads the whole tree, not the owned subset.** The manifest's claim is "these bytes are commit X", and that is only true when nothing in the tree is uncommitted -- a dirty `.md` beside a clean `opt/` still means the recorded commit does not describe the checkout the bytes came from. A tree that is not a git repository at all returns a distinct status: "no changes" and "cannot tell" must not render as the same answer.

**AC03's predicate is a property of the target alone**, derived rather than named: a tree that could be published FROM but carries no manifest is a source checkout. Comparing source to destination was devbin's guard and it did not hold -- the harm has nothing to do with the two being equal.

**ONE WRITE LANDS OUTSIDE THE PREFIX AND IT IS NAMED HERE RATHER THAN LEFT TO BE FOUND.** `cargo build --release` writes into the SOURCE tree's `opt/prez/crate/target/`, because AC09 requires the binary be built at publish time and that is where cargo puts it. AC11 says the publish writes "nothing a person authored and nothing outside the prefix", and the two halves of that sentence disagree here: the target directory is outside the prefix and is authored by nobody. **This is built on the reading that AC11 protects the operator's environment and their files, not the crate's own gitignored build output** -- the alternative reading makes AC09 and AC11 unsatisfiable together. Flagged to vc at 21:5xZ as a contract observation rather than settled unilaterally; if they read it the other way, the remedy is to build into a temporary directory and copy from there, which is a change to `install_build_prez` alone.

## D8. Telling the two trees apart at the prompt (AC12)

`utilz version` adds one line saying which tree answered and what it was cut from, discriminated by the manifest:

```
utilz v2.5.0
Universal utilities framework and dispatcher
installed at /Users/matts/Devel/opt/utilz (5a15b81)
```

against `source at /Users/matts/Devel/prj/Utilz` for a checkout. Without it the two-tree arrangement is invisible in precisely the situation it exists for -- someone debugging behaviour cannot tell which copy produced it, and the version string is identical either way.

**The manifest's filename lives in `common.sh` as `UTILZ_MANIFEST_NAME`, not in `install.sh`.** It is not install machinery: it is the discriminator between the two kinds of tree, and the RUNTIME needs it as much as the installer does -- `show_version` here, `run_tests`'s refusal for AC13, and the prez shim's install branch for AC09 all ask the same question. `install.sh` reads the constant from there rather than carrying a second copy, because a second answer to "which tree is this" is the one thing this thread cannot afford to have two of.

## D9. The PATH cutover is its own verb (AC11, AC16, WP-12)

`install` and `upgrade` write nothing outside the prefix. Relinking `~/.local/bin/*` is mutating the operator's environment mid-command and needs a verb they typed: **`utilz relink --prefix <dir>`**, separate and explicit, and it is WP-12, LAST, after WP-05. It is the only work package that writes outside the prefix, so it wants every guard finished first.

**AC11 and AC16 are one policy from two sides: never implicitly, always available explicitly.** A `--relink` flag on `install` was rejected because a flag becomes habitual and habitual relinking is implicit relinking with a longer spelling. Shell-init in devbin's shape was rejected too: devbin has one entry point reached by an absolute path, which does not transfer to sixteen, and PATH-order resolution would make which-tree-answers depend on shell state -- the defect AC15 exists to remove.

**THIS SECTION SAID THE VERB SHOULD NORMALISE THE ODD LINK AND THAT IS NOW REVERSED (vc, ruled 21:20Z).** `~/.local/bin/prez` is a RELATIVE link to `bin/utilz` while the other fifteen are ABSOLUTE links to `bin/<util>`. It works, because the dispatcher reads `basename "$0"` for `INVOKED_AS` and resolves `UTILZ_HOME` from the resolved path either way. The argument for normalising was that two conventions in one directory is a false red waiting for the first doctor check that asserts one of them. **The argument against it wins: it is a change to hv's environment that nobody asked for, made under cover of a command asked to do something else.** A verb that quietly tidies what it was not pointed at is the same shape as a manifest check that re-blesses a file it refused. AT16 pins it: leave a link you did not write alone.

Measured baseline for WP-12: **sixteen links in `~/.local/bin`** resolve into the source tree -- all fifteen utilities plus `utilz` -- and exactly one of them is the odd one.

**AS BUILT: WHICH FILE A LINK NAMES IS PRESERVED; ITS RELATIVE-NESS CANNOT BE.** `bin/utilz` and `bin/<name>` both dispatch, because the dispatcher reads `basename "$0"`, so choosing between them is normalising a convention rather than relinking -- `~/.local/bin/prez` names the dispatcher and stays that way. Relative-ness is a different case and the difference is not a preference: a relative target names the OLD tree by construction, so a repoint must rewrite it, and recomputing a relative path across a tree move is arithmetic that produces a silently broken link when it is wrong. The verb writes an absolute target and says so in its output.

**A link that resolves into no Utilz tree is left alone and reported as skipped**, which is the row's whole point. The predicate is derived, not listed: resolve the link the way the kernel does, require its directory to be a `bin/`, and ask `install_tree_kind` about the parent. A name list would have to be maintained against the fifteen and would answer wrongly the day a sixteenth arrived.

## D10. What is shared with `emacs_install`, and what is not

`emacs_install` already implements `--dest`, `--symlink`, `--force` and tilde expansion. **The tilde expansion is extracted and shared as of WP-01** -- `expand_tilde` in `common.sh`, called by `emacs_install --dest` and by `install_prefix_configured` (IN-AG-HIGHLANDER-001). The flag parsing follows when `install` needs it (WP-02).

**The extraction carried the behaviour across unchanged, including the part that is wrong.** `~user` becomes `"$HOMEuser"`, because that is what the one implementation did. It is recorded in the helper rather than quietly fixed: neither caller supports `~user`, and improving a mechanism under cover of extracting it is how an extraction stops being a refactor.

**The refusal policy is NOT shared, and that boundary is deliberate.** `emacs_install` writes into a directory the user nominates; publish refuses a dirty tree, refuses an existing install and refuses a source tree. Common mechanism, different contract. Folding the refusals into the shared half would give `emacs_install` three gates nobody asked it for, which is a worse defect than the small duplication it would remove.

## D11. Build order, and the one test that has to come first

WP-01 (owned set + manifest) -> WP-02 (`install`) -> WP-04 (the runnable-install guards, and AC15) -> WP-03 (`upgrade`) -> WP-05 (AC01 end to end) -> WP-12 (`relink`). WP-12 is last because it is the only package that writes outside the prefix.

`upgrade` sits after the guards because it is the mirror of `install` (AC04) and mirroring something still moving costs more than waiting.

**AC01 is the row the whole thread turns on and it is the one most easily faked.** `determine_utilz_home` at `bin/utilz:17-53` walks the symlink chain, takes `dirname`, and returns the parent of `bin/`, so `<prefix>/bin/utilz` should yield `UTILZ_HOME=<prefix>` with no dispatcher change at all. **That is a code read and not a measurement, and it is recorded here as one.** An install that silently reaches back into `~/Devel/prj/Utilz` passes every check that does not move the source aside, and it passes them looking exactly like success -- which is why AC01 is written to move the source tree aside rather than to assert that files arrived.
## D12. An inherited UTILZ_HOME is ANNOUNCED, not ignored (AC15, WP-04)

**The dispatcher always computes its own home from `$0`, and when an inherited `UTILZ_HOME` names a DIFFERENT tree it says so on stderr and then HONOURS THE INHERITED VALUE.** Behaviour preserved, silence removed. Ruled by vc at 21:20Z with hv's pen; the remedy touches `bin/utilz` and belongs to WP-04, not WP-02.

**The defect this closes is invisible to AC01, structurally.** `bin/utilz:42` derives `UTILZ_HOME` from `$0` only when the variable is unset, and `~/.zshrc:76-78` exports it unconditionally at the source checkout. So a published install invoked from hv's shell runs the SOURCE tree, silently. AC01 moves the source aside, and with the source gone a stale `UTILZ_HOME` makes the install fail loudly rather than defer quietly -- **so AC01 goes green in a clean test environment while the defect is live in the shell hv actually types into.** The dangerous case is source-PRESENT, which is the normal case.

**IGNORING THE VARIABLE WAS THE OBVIOUS FIX AND IT IS WRONG, MEASURED RATHER THAN ARGUED.** `UTILZ_HOME` is load-bearing as a settable variable in five places: `test_helper.bash:20` exports it for the entire bats suite, `prez.bats:132` sandboxes a shim, `common_lib.bats:71` binds a temp home per test, `e2e-smoke.el:11` documents `UTILZ_HOME=$PWD emacs -Q --batch`, and `install.sh:124` -- this thread's own code -- binds it in a subshell to read a foreign tree's yaml. Ignoring it breaks WP-01. **The variable is not the defect; the silence is.** Two dispatchers, one per tree, was rejected as a Highlander violation on the one file that must have exactly one answer.

**AT15's fourth leg is the one that bites: the announcement goes to STDERR, and stdout must be byte-identical to the unset run.** A caller parsing `utilz` output must not gain a line. `install.sh:124` is unaffected either way -- it binds the variable in a subshell for a metadata read, never for a dispatcher invocation, so the rule never fires there.

