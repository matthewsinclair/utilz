---
verblock: "29 Aug 2026:v1.6: matts - globalfold; wip carries DOING and TODO only, done work folded to done.md"
---

# Work In Progress

This file carries **DOING and TODO only**. Completed work belongs in `intent/done.md`; durable context and conventions belong in `intent/restart.md`. Nothing done is recorded here, ever -- a "just landed" list here is the same narrative in two files with two values, and nothing reports the divergence.

## DOING

**ST0010 -- `utilz prez`, the first Rust utility.** Shipped as **v2.5.0**, tagged, both remotes at `72ee931`, CI green on all seven jobs. The thread is not closed: four acceptance criteria remain.

Gate **16/20**. Unsatisfied: AC15, AC16, AC18, AC19.

| AC   | What it needs                                                 | Whose |
| ---- | ------------------------------------------------------------- | ----- |
| AC16 | a human renders every built-in theme and looks                | hv    |
| AC18 | AT15 -- written, never run against a real Safe-Storage dialog | vc    |
| AC19 | AT20's browser half: the presenting window's actual geometry  | vc    |
| AC15 | theme addressing split + `--theme-path` (WP-06)               | vc    |

Two things blocking their own progress rather than each other:

- **AC19's open question needs a browser to answer.** When Chrome is already running, the launch forwards to the existing instance, and `--window-size` may not apply on that path -- so AC19's geometry could be cold-only. AT20 exists to find out; nothing else can.
- **WP-04 still reads `Not Started`** while its work is substantially done. Advancing it runs through `intent wp done`, which consults the acceptance gate this session found unreadable (see TODO). Held deliberately until that is resolved.

## TODO

**Immediate, hv's**

- **Move the `v2.5.0` tag onto the release commit `4b6eb07`** per the standing directive ("annotated tag on the `release:` commit itself"). It currently sits at `72ee931`. The rewritten tag message is composed and ready; the recreate + force-push was blocked by the permission classifier, so the three commands are hv's to run. The reason the tag was moved in the first place stands on the record: `4b6eb07`'s CI was red, and the three commits after it are harness-only.
- **Relay the `intent ac gate` defect to `intent-vc`.** `bin/intent_acceptance`'s `ac_lines()` greps the v2 dotted form `^- AC-<st>.<nn> `; the v3 renderer emits `^- AC<nn> `. Zero matches, so `ac gate` reports "empty contract -- BLOCKED" and `ac status` reports `0/0` against a full 20-row contract. It fails safe, but **the remedy it prints is `acceptance: exempt`**, which on a thread with a real contract converts a false red into a permanent silent pass. Intent's tree; nothing here should be edited to accommodate it.
- **`geodica doctor` must report whether `utilz prez` is available.** hv's estate requirement, raised 13:36Z, still on no contract in any repo. The estate's move to `~/Devel/prj/Gtools` did not retire it.

**ST0010, remaining work packages**

- **WP-05 -- default theme polish.** Carries issue `0007` (slide-counter contrast) and the `prez build examples/demo.md` warning that `class 'escape' has no effect` -- prez's own example ships a warning.
- **WP-06 -- AC15, the theme addressing split** plus `--theme-path`.
- **WP-07 -- expose the theme determinism probe** (deferred, possibly to be un-deferred). Two consumers, two days apart, were both blocked by prez keeping something private and both reached for a copy: the browser list and the determinism probe. That is one design answer, not two. The ruling is hv's, because it grows the crate's public surface and the crate's whole claim is that it is liftable.

**Housekeeping, small and each independently true**

- **`chrome()` should name the browser it resolved.** One `printf ... >&2` on the resolve path in `crate/test/acceptance.sh`, matching the note it already prints when it refuses. Today it is silent exactly where it is about to launch Chrome on someone's machine, so an acceptance number carries no evidence of which mode produced it. Found by cc at EOD from a 12/0/0 where the morning's identical command gave 9 passed / 11 skipped.
- **cc's `hoist-rebase.sh` carries one dead postcondition.** `post "test/acceptance.sh" "AT13: PASS" 0` sets the minimum to zero against a `-ge` test, so it prints `ok` unconditionally -- including at the count of zero it exists to catch. Redundant rather than a hole (two other checks cover AT13), but it is the measures-nothing shape sitting inside the script that guards against silent loss. cc's; the canon-writing conflict that was holding it is cleared.
- **cc's issue `0006` exists only as a flat view and was never written to canon**, so `intent doctor` counts one fewer issue than the tracker shows. cc's to fill or leave.
- **`ST0007/WP-04` reads `wip` under a completed thread.** Not the migrator -- the v2 source itself says WIP. Small.
- **ST0002's six WPs read `not-started`** under a thread completed 2026-02-08; the v3 migrator defaulted them and `intent doctor` reports nothing. hv ruled not-today.
- **Intent issue 0008** is filed but uncommitted in `../Intent`. It covers the unconditional `Bash 4.0+` line `intent agents sync` writes into every project's `AGENTS.md`. `AGENTS.md:13` is wrong here today and **must not be hand-edited** -- re-run `intent agents sync` once the Intent fix lands.

**Opportunistic, no owner**

- **Em dashes across 18 tracked docs**, against the no-em-dash convention: `CHANGELOG.md`, `README.md`, both `docs/*.md`, six `help/*.md`, five `opt/*/README.md`, `usage-rules.md`, `intent/llm/RULES.md` and one closed issue. Cleared from the tracking docs at the 29 Aug globalfold; the rest is a mechanical sweep nobody has run. Find them with `git grep -l $'\u2014' -- '*.md'`.
- **`intent doctor` reports all checks passed as of the 29 Aug globalfold.** It had carried one finding all day (ST0009's status/gate disagreement). Nothing in this session's doc fold could have cleared it, so either it was resolved elsewhere or the check changed. Not chased at EOD; worth one minute of confirmation next session, because a finding that disappears without anyone fixing it is the same shape as a check that stopped looking.

- VSCode / Zed / Vim integration families (same TSV manifest, new editor-specific installers).
- Emacs bridge v2: Transient grouped menu, deferred per ST0007 `design.md`.
- The 12 per-utility `help/<name>.md` files each hardcode a version alongside the same value in `<name>.yaml`. None has drifted, because per-utility versions rarely move. `help/utilz.md` is the one that did (2.2.0 while 2.4.0 shipped) and now points at `utilz version` instead of carrying a number. Apply the same treatment if another lags.
