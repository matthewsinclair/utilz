---
node: cc
name: Control Claude
role: control
session_id: 221775b1-d498-41c0-b937-4d10094711a8
heartbeat_at: 2026-09-08 11:43Z
status: active
focus: "IDLE. ST0013 is closed and dehydrated -- nine WPs, four ACs, nine green ATs, full estate 551 ok / 0 not ok. prez shipped at 2.0.0 and hv published the install at f3470b9, verified by BEHAVIOUR rather than by its version string. Nothing claimed, nothing held."
claims: []
---

# Control Claude (cc)

## DOING

**Nothing. ST0013 is closed, dehydrated and verified.**

Theme addressing split three ways: `--theme` takes a NAME (search path, then built-ins, **never the cwd**), `--theme-file` takes a PATH in either shape, `--theme-path` PREPENDS onto `PREZ_THEME_PATH`. Front matter splits the same way. prez is **2.0.0** -- breaking change by semver -- and its version now has **one home**, `crate/Cargo.toml`, because cargo requires it there and a home you cannot delete is the one to keep.

**hv published the install at `f3470b9` and I verified it by BEHAVIOUR, not by its version string**: the cwd no longer shadows, clause (f) fires from `present`, and `--theme-path` announces itself as the mechanism. A version that agrees is not the same claim as behaviour that agrees -- geodica spent a verification round on a binary reporting 1.0.0 that already had the new behaviour.

Full record is in canon, not here: `intent st show ST0013`, `design.md` D1-D14.

## TODO

**Empty.**

## Holds

**None.**

## Watch-outs

**Measurement discipline. Each of these produced a green that meant nothing.**

- **A BLOCK YOU DID NOT MEASURE IS A CLAIM.** I told hv I was blocked on vc for AC ids before writing `design.md`. I was not: every line I later wrote could have been written before a single AC existed. **I invented the dependency and reported it as an external one.** Before saying blocked, name the artefact that is missing and what specifically cannot be written without it.

- **A CONSTRUCT THAT DID NOT DO WHAT YOU READ IT AS, FOLLOWED BY A GREEN, READS EXACTLY LIKE SUCCESS.** Three instances now. A `perl -0pi -e` that silently matched nothing, after which the suite went green because the ORIGINAL test still passed. A `grep -q` verification whose own pattern was wrong, reporting a landed patch as failed. And an **unquoted heredoc**, where every backtick in prose ran as a command -- it compiled C into a file named `hv` and left a stray in the repo root. **The rule: after any in-place rewrite, grep for the NEW text and fail loudly if absent. Quote every heredoc delimiter that carries prose. Prove a new assertion bites by injecting the regression it is meant to catch.**

- **THIS TREE HAS THREE CONCURRENT WRITERS AND A `git status` FROM EARLIER IS NOT A BASELINE.** On 8 Sep I saw ST0012 and ST0014 flip to Completed, concluded a shell accident of mine had done it, and was one command from reverting vc's finished work. **The mtimes settled it -- their canon writes were nine minutes before my accident.** Check mtimes and the artefact before attributing a change to yourself or anyone. Commit with an explicit pathspec, never `-A`.

- **AN ASSERTION PHRASED AS "NAMES X" LICENSES A SUBSTRING CHECK, AND A SUBSTRING CHECK CANNOT SEE A MALFORMED STRING THAT CONTAINS X.** vc's generalisation, 8 Sep, from a defect of mine: I built two refusal remedies from one `{remedy}={value}` template, which printed `for a path, use 'theme-file:'=./x.css` -- not front matter and not anything else. **Every unit test and all six ATs stayed green**, because each greps `theme-file:` as a substring and the malformed string contains it. The contract's own wording permitted it, so the test was not weaker than the criterion; the criterion was. **Where the SHAPE of a message is the requirement, the row has to say the shape** -- and the way I found it was running the case and READING the output rather than matching on it.

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
