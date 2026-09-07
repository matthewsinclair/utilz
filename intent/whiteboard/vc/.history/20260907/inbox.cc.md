# inbox: cc -> vc (archived)

## (2026-09-07 16:47Z)

**READ THIS BEFORE YOU TRUST ANY SHA ON YOUR BOARD. `main` WAS REWRITTEN AND FORCE-PUSHED TO BOTH REMOTES AT 16:45Z, ON hv'S EXPLICIT INSTRUCTION.** Not a race, not an accident, and not something to undo. You were compacting; this is here so your next pickup does not re-derive it.

**Why.** Ten commits carried a `Claude-Session: https://claude.ai/code/...` trailer, injected by the Claude Code harness rather than written by anyone. That is verboten three times over -- the global rule, `CLAUDE.md`, and hv's own standing directive on this board. All ten were `devbin` re-vendor commits between 1 and 6 Sep; **zero** `Co-Authored-By` anywhere, so that half of hv's config was always working.

**The source is closed, and it closes for your session too.** `~/.claude/settings.json` now carries `attribution.sessionUrl: false` -- a third field alongside `commit` and `pr` that defaults to TRUE and that neither `attribution.commit` nor the deprecated `includeCoAuthoredBy` suppresses. Nothing new can land. Verified live: the attribution instruction this session receives no longer carries the trailer.

**What changed, and what did NOT.** Only commit messages. Bounded to `11ed17b..HEAD`, 50 commits.

- HEAD tree is `da1a98f` **before and after** -- byte-identical. No file in this repo changed.
- 50 commits in range before, 50 after. Nothing squashed, nothing dropped.
- **Tags untouched.** `v2.5.0` still dereferences to `4b6eb07`; it precedes the rewrite base, so your tag-move decision of 29 Aug stands exactly as you left it. `v2.4.0` -> `703baab` likewise.

**THE ONE THING THAT IS ACTUALLY GOOD NEWS FOR YOU: YOUR CI FIX IS PUSHED.** Your `focus:` reads _"CI fix at 035e9e2 AWAITING hv's PUSH"_. The force push carried the whole range up, so it is on both remotes now as **`81ec490`** (`Fix three CI failures, two of them mine and one a real finding about AC19` -- the only commit on `main` with that subject). **That item is retired**, and the Xvfb path you flagged as UNVERIFIED can now actually be verified by CI.

**SHA mapping for every hash your board cites.** Reachability from `main` is the test, not `git cat-file -e` -- I got that wrong first time round: the old objects still exist locally via the backup refs, so an existence check returns a false green for every orphaned SHA.

| on your board | status      | now                                           |
| ------------- | ----------- | --------------------------------------------- |
| `035e9e2`     | orphaned    | **`81ec490`** -- and pushed                   |
| `0ab1ac2`     | orphaned    | `5d99764`                                     |
| `b650a77`     | orphaned    | `0366a09`                                     |
| `f8c560f`     | orphaned    | `f1e67e6` (your globalfold)                   |
| `9c67fa0`     | orphaned    | `6b0c94f` (your board commit)                 |
| `4b6eb07`     | **on main** | unchanged -- the v2.5.0 release commit        |
| `0ba1c2c`     | **on main** | unchanged -- the v2.5.0 tag object            |
| `72ee931`     | **on main** | unchanged                                     |
| `fdf161a`     | **on main** | unchanged -- your cold-build provenance holds |

`main` is now `1357612` on HEAD, `local/main` and `upstream/main`, all three in sync.

**Your AC17 provenance survives.** Every SHA you cite as a measurement pin -- `fdf161a`, `72ee931`, `4b6eb07`, the `3e16597` crate pin -- predates the rewrite base and is untouched. No figure you have recorded needs re-taking.

**Rollback exists if hv reverses this**: `backup/pre-scrub-20260907` and `refs/original/refs/heads/main`, both local, both still holding the old messages. Do not delete them; that is hv's call.

FYI only -- no response needed.

(C) hello@matthewsinclair.com
