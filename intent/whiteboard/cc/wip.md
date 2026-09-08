---
node: cc
name: Control Claude
role: control
session_id: 221775b1-d498-41c0-b937-4d10094711a8
heartbeat_at: 2026-09-08 11:19Z
status: active
focus: "ST0013 built and verified. The split shipped -- --theme takes a NAME, --theme-file a PATH, --theme-path prepends -- and vc marked the contract 3/3 satisfied at 0daef97 with all eight ATs green, verified independently rather than read. WP-07 evidence is the last of mine; the AC03 widening is hv's to rule on."
claims: [ST0013]
---

# Control Claude (cc)

## DOING

**ST0013 -- prez theme addressing. Built, and verified by vc independently rather than read.** `--theme` takes a NAME (search path, then built-ins, never the cwd), `--theme-file` takes a PATH in either shape, `--theme-path` PREPENDS onto `PREZ_THEME_PATH`. Front matter splits the same way. vc marked the contract **3/3 satisfied at `0daef97`, all eight ATs green**.

**The fix is a TYPE change, not a branch reorder**, and that is the part worth carrying forward. `theme::load` took one ambiguous `&str` and asked `path.exists()` first; it now takes `Spec::Name` or `Spec::File`, so the cwd branch is **unreachable rather than unvisited**. Deleting the branch would have passed every test and left the cause in place.

**WP-07 evidence is all that remains of mine.** shellcheck CLEAN over CI's own 18-file set, `intent doctor` 0 findings; full `utilz test` running, `utilz doctor` after it because the suite mutates `$UTILZ_HOME/bin`.

## TODO

- **WP-07** -- finish the evidence: full `utilz test`, `utilz doctor`, and record the numbers.
- Nothing else. WP-01 through WP-06 and WP-08 are done and committed (`8326332`, `098f10c`, `09298e5`, `f57cd74`, `271d3c6`).

## Holds

**None. Both conditions were met and the holds are discharged rather than left standing.**

- `src/` was held on geodica's answer. **vc relayed it at 10:10Z** -- the pass-through shape is in real use, and AC02 was minted out of it. vc twice re-announced the hold afterwards from a pre-compact carry-forward; **a hold is governed by its CONDITION, not by whoever last mentions it**, and vc confirmed that reading at 10:34Z.
- WP-02 was held on the AT01 id collision. **Ruled at 10:18Z**: new file `theme-addressing.sh`, both rows re-cited.

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
