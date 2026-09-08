---
node: cc
name: Control Claude
role: control
session_id: 221775b1-d498-41c0-b937-4d10094711a8
heartbeat_at: 2026-09-08 12:42Z
status: active
focus: "IDLE, FOLDED FOR A COMPACT -- status stays active because a compact is not a session ending. ST0013 closed and dehydrated; every version reduced to one home on hv's ruling; install published at 2f76209 and verified by behaviour, 126 paths, doctor 7/7. Nothing claimed, nothing held."
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

- **A BLOCKED PROCESS HOLDING AN UNFINISHED WRITE IS NOT INERT, AND TERMINATING IT COMPLETES THE WRITE.** 8 Sep, found during a tidiness sweep two hours after the fact: the zsh from that morning's unquoted-heredoc accident was STILL ALIVE, started 10:28:30, blocked. I killed it as cleanup -- and on termination it flushed its heredoc and appended **45 corrupted lines to a peer's inbox**, stamped with a stale 09:28Z, every backticked span command-substituted and the output of `intent issues list`, `ls` and `intent doctor` spliced into the prose. **The cleanup action caused the damage the cleanup was for.** Caught because `git status` was checked immediately after; the diff was additions-only so HEAD was intact and `git checkout --` discarded only the garbage. **Before killing a stray, know what it has open and check the tree immediately after.**

- **THIS TREE HAS THREE CONCURRENT WRITERS AND A `git status` FROM EARLIER IS NOT A BASELINE.** On 8 Sep I saw ST0012 and ST0014 flip to Completed, concluded a shell accident of mine had done it, and was one command from reverting vc's finished work. **The mtimes settled it -- their canon writes were nine minutes before my accident.** Check mtimes and the artefact before attributing a change to yourself or anyone. Commit with an explicit pathspec, never `-A`.

- **AN ASSERTION PHRASED AS "NAMES X" LICENSES A SUBSTRING CHECK, AND A SUBSTRING CHECK CANNOT SEE A MALFORMED STRING THAT CONTAINS X.** vc's generalisation, 8 Sep, from a defect of mine: I built two refusal remedies from one `{remedy}={value}` template, which printed `for a path, use 'theme-file:'=./x.css` -- not front matter and not anything else. **Every unit test and all six ATs stayed green**, because each greps `theme-file:` as a substring and the malformed string contains it. The contract's own wording permitted it, so the test was not weaker than the criterion; the criterion was. **Where the SHAPE of a message is the requirement, the row has to say the shape** -- and the way I found it was running the case and READING the output rather than matching on it.

- **"IT ANSWERS" AND "IT ANSWERS WITH THE RIGHT VALUE FROM THE RIGHT SOURCE" ARE DIFFERENT CLAIMS, AND THE FIRST IS THE EASY ONE.** 8 Sep, verifying the version publish: I checked every utility ANSWERS a version and carries the framework line -- liveness. vc checked the answer EQUALS THE BYTES of the file its yaml points at -- the Highlander claim. **Two numbers agreeing by luck pass mine and fail theirs.** When two people verify the same change, agreeing on the instrument wastes one of them; pick the claim the other did not make.

- **AND VERIFY THE ARTIFACT, NOT ONLY THE TREE THAT TESTS IT.** Both my guards run against the checkout. vc ran the equivalent against the published INSTALL -- 31 help files and READMEs, 0 literals, pointer present in all 31 -- which is the only way to know a fix REACHED the shipped tree. Pair it with a negative control proving the pattern bites before trusting a zero.

- **A CONTROL OVER A SUBSET READS EXACTLY LIKE A CONTROL OVER THE WHOLE.** vc's, 8 Sep, from a defect of mine. Pairing an assert-absence with an assert-presence is **necessary and not sufficient**: my absence check spanned 33 files and its presence control counted 16 of them, so deleting the version line from the other 17 passed BOTH. **The pair has to consume ONE population, computed once**, or the control is a subset wearing the costume of the fix.

- **A SUITE RUN AT ONE INDEX STATE SAYS NOTHING ABOUT ANOTHER, BECAUSE `git ls-files` READS THE INDEX AND NOT THE WORKTREE.** 8 Sep: 14 new `VERSION` files were STAGED when a full suite ran, so `install_owned_paths` found them and the install gate passed **honestly**. They were untracked twenty minutes later, and a publish would have shipped sixteen yamls pointing at files that were not there. **Nothing was wrong with that green -- it simply stopped describing the tree.** One level below "a `git status` from earlier is not a baseline", and sharper, because there the reading was already stale and here it was correct when taken.

- **ANY CONTROL THAT READS THE WORKTREE CANNOT SEE A PACKAGING DEFECT.** The check built to prove every utility resolves a version sourced `common.sh` against the CHECKOUT, where the files exist on disk whether or not git knows about them. Green in the checkout, broken in the install: **the two-tree trap firing on the control built to prevent the thing.** Only `install_guards.bats`, which builds an install through `install_owned_paths` and runs every link, could see it -- and it did.

- **A check placed before the thing it measures passes for the wrong reason**, and a red-first probe that did not APPLY is not a red-first proof. **A grep-based check must target a string the artifact can only contain if the thing is really there** -- never a token the file might legitimately discuss. **Never pipe a command whose exit code is the assertion**; `$?` is the last stage's.

- **A SHARED FIXTURE THAT ANY TEST MUTATES IS A FLAKE GENERATOR.** The AT15 legs wrote a marker VERSION into the file-scoped install, so doctor's integrity check failed in a full run and passed in isolation. Mutating tests copy first.

**The estate, changed 8 Sep and worth knowing at the prompt.**

- **`utilz` ON PATH IS AN INSTALL, NOT THIS CHECKOUT.** `~/.local/bin` holds 16 links; `~/Devel/opt/utilz` is the published tree. `utilz use` reports which is live, `utilz use dev|opt` switches. **`utilz version` names the tree that answered**, so never guess which one produced a behaviour. The dispatcher ignores an inherited `UTILZ_HOME` entirely and always derives from `$0`.
- **EVERY VERSION HAS ONE HOME AND NOTHING RESTATES IT** (hv, 8 Sep). Framework: `./VERSION`. Each utility: `opt/<name>/VERSION`, pointed at by `version_file`. **prez is the exception and is not an exception to the rule** -- cargo requires the version in `[package]`, so that home cannot be deleted, which makes it the one to keep. **Point at the one home you cannot delete**, never "use this filename". Two guards in `common_lib.bats` hold it; do not "fix" prez into compliance.
- **`utilz test` refuses from an install** and is not concurrency-safe anywhere. **`utilz help <anything>` HANGS when stdin is a TTY** (glow's pager); `< /dev/null` fixes it.

**Framework internals that have bitten.**

- **The `each_utility` tripwire that this board documented until 7 Sep was FALSE-RED.** The correct tree returns ONE hit for `grep -c 'UTILZ_HOME"/bin/\*' opt/utilz/lib/common.sh` -- the walker itself. A reader running the old documented form reads that as a walker gone missing and re-adds one, which is the exact duplication it exists to prevent.
- `each_utility` must be consumed with process substitution, never a pipe. `require_yq` ONCE before a loop. `run_doctor` deliberately does NOT gate on it -- it is how you discover yq is missing.
- **`prez --version` and `--help` never reach the shim**; the dispatcher answers from `prez.yaml` -- which as of 8 Sep carries NO version and points at `crate/Cargo.toml` with `version_file`. A test meaning to exercise the binary must use a real verb.
- Verify shell tooling under `/bin/bash` with an ARRAY -- zsh does not word-split, so `shellcheck -x $FILES` errors on one bogus path and the empty output reads as a pass.
- Run prettier yourself before committing markdown, or the pre-commit hook is an unnamed third writer.

## Decisions

- (2026-07-29) `-v` stays **unbound** on the dispatcher. It reads as a verbose flag and no utility binds it, so binding it to `version` would foreclose the obvious future use. Pinned by a test asserting it still fails.
- (2026-07-09) todo guard's Intent-project test is anchored on the **target file's directory**, not cwd: the guard protects the file being overwritten, so `--file`-ing at another project's `intent/todo.md` from outside still refuses. hv-confirmed.
