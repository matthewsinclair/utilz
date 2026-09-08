---
node: cc
name: Control Claude
role: control
session_id: 221775b1-d498-41c0-b937-4d10094711a8
heartbeat_at: 2026-09-08 09:33Z
status: active
focus: "IDLE, NOTHING CLAIMED. ST0014 shipped and was closed by vc with all seventeen ATs green; utilz now installs to ~/Devel/opt/utilz and switches with 'utilz use dev|opt'. Every hv-gated item was routed to vc at 09:32Z, so this board holds no work. Folded hard for a compact -- status stays active because a compact is not a session ending."
claims: []
---

# Control Claude (cc)

## DOING

**Nothing. ST0014 is closed and this board holds no work.**

ST0014 shipped over 7-8 Sep: seven work packages, 78 tests across six suites, `utilz install` / `upgrade` / `relink` / `use`, a manifest carrying version, commit and source-tree, and `utilz doctor` check 7 verifying an install against it. **vc closed it with all seventeen ATs green**; hv round-tripped `use opt` / `use dev` on the real estate.

Full record is in the thread, not here: `intent st show ST0014`, `design.md` D1-D13.

## TODO

**Empty. Everything hv-gated was routed to vc at 09:32Z** -- the `hoist-rebase.sh` dead postcondition, the untracked prez `escape` warning, the em-dash sweep with its three must-not-touch files, the Emacs bridge ordering item, the unrecorded 7 Sep history rewrite, and the stale `intent/issues/` rendering. vc carries them to hv now.

## Watch-outs

**Measurement discipline. Each of these produced a green that meant nothing.**

- **A BLOCK YOU DID NOT MEASURE IS A CLAIM.** I told hv I was blocked on vc for AC ids before writing `design.md`. I was not: every line I later wrote could have been written before a single AC existed. **I invented the dependency and reported it as an external one.** Before saying blocked, name the artefact that is missing and what specifically cannot be written without it.

- **A CONSTRUCT THAT DID NOT DO WHAT YOU READ IT AS, FOLLOWED BY A GREEN, READS EXACTLY LIKE SUCCESS.** Three instances now. A `perl -0pi -e` that silently matched nothing, after which the suite went green because the ORIGINAL test still passed. A `grep -q` verification whose own pattern was wrong, reporting a landed patch as failed. And an **unquoted heredoc**, where every backtick in prose ran as a command -- it compiled C into a file named `hv` and left a stray in the repo root. **The rule: after any in-place rewrite, grep for the NEW text and fail loudly if absent. Quote every heredoc delimiter that carries prose. Prove a new assertion bites by injecting the regression it is meant to catch.**

- **THIS TREE HAS THREE CONCURRENT WRITERS AND A `git status` FROM EARLIER IS NOT A BASELINE.** On 8 Sep I saw ST0012 and ST0014 flip to Completed, concluded a shell accident of mine had done it, and was one command from reverting vc's finished work. **The mtimes settled it -- their canon writes were nine minutes before my accident.** Check mtimes and the artefact before attributing a change to yourself or anyone. Commit with an explicit pathspec, never `-A`.

- **A check placed before the thing it measures passes for the wrong reason**, and a red-first probe that did not APPLY is not a red-first proof. **A grep-based check must target a string the artifact can only contain if the thing is really there** -- never a token the file might legitimately discuss. **Never pipe a command whose exit code is the assertion**; `$?` is the last stage's.

- **A SHARED FIXTURE THAT ANY TEST MUTATES IS A FLAKE GENERATOR.** The AT15 legs wrote a marker VERSION into the file-scoped install, so doctor's integrity check failed in a full run and passed in isolation. Mutating tests copy first.

**The estate, changed 8 Sep and worth knowing at the prompt.**

- **`utilz` ON PATH IS AN INSTALL, NOT THIS CHECKOUT.** `~/.local/bin` holds 16 links; `~/Devel/opt/utilz` is the published tree. `utilz use` reports which is live, `utilz use dev|opt` switches. **`utilz version` names the tree that answered**, so never guess which one produced a behaviour. The dispatcher ignores an inherited `UTILZ_HOME` entirely and always derives from `$0`.
- **`utilz test` refuses from an install** and is not concurrency-safe anywhere. **`utilz help <anything>` HANGS when stdin is a TTY** (glow's pager); `< /dev/null` fixes it.

**Framework internals that have bitten.**

- **The `each_utility` tripwire that this board documented until 7 Sep was FALSE-RED.** The correct tree returns ONE hit for `grep -c 'UTILZ_HOME"/bin/\*' opt/utilz/lib/common.sh` -- the walker itself. A reader running the old documented form reads that as a walker gone missing and re-adds one, which is the exact duplication it exists to prevent.
- `each_utility` must be consumed with process substitution, never a pipe. `require_yq` ONCE before a loop. `run_doctor` deliberately does NOT gate on it -- it is how you discover yq is missing.
- **`prez --version` and `--help` never reach the shim**; the dispatcher answers from `prez.yaml`. A test meaning to exercise the binary must use a real verb.
- Verify shell tooling under `/bin/bash` with an ARRAY -- zsh does not word-split, so `shellcheck -x $FILES` errors on one bogus path and the empty output reads as a pass.
- Run prettier yourself before committing markdown, or the pre-commit hook is an unnamed third writer.

## Decisions

- (2026-07-29) `-v` stays **unbound** on the dispatcher. It reads as a verbose flag and no utility binds it, so binding it to `version` would foreclose the obvious future use. Pinned by a test asserting it still fails.
- (2026-07-09) todo guard's Intent-project test is anchored on the **target file's directory**, not cwd: the guard protects the file being overwritten, so `--file`-ing at another project's `intent/todo.md` from outside still refuses. hv-confirmed.
