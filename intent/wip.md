---
verblock: "07 Sep 2026:v1.10: matts - as-written tidy; tag move and Intent 0008 retired, AT15 corrected to unwritten"
---

# Work In Progress

This file carries **DOING and TODO only**. Completed work belongs in `intent/done.md`; durable context and conventions belong in `intent/restart.md`. Nothing done is recorded here, ever -- a "just landed" list here is the same narrative in two files with two values, and nothing reports the divergence.

## DOING

**ST0010 -- `utilz prez`, the first Rust utility.** Shipped as **v2.5.0**, CI green on all seven jobs. The thread is not closed: four acceptance criteria remain. Release state as of 7 Sep: the `v2.5.0` tag names `4b6eb07`, the release commit, on both remotes -- the standing directive satisfied. `main` has since moved on: both remotes are at `5dcc317` and `HEAD` is one commit further at `0ab1ac2` (devbin re-vendor), so the tag deliberately no longer names the tip.

Gate **16/20**. Unsatisfied: AC15, AC16, AC18, AC19.

| AC   | What it needs                                                | Whose |
| ---- | ------------------------------------------------------------ | ----- |
| AC16 | a human renders every built-in theme and looks               | hv    |
| AC18 | AT15 -- UNWRITTEN; the code it would prove is in the tree    | vc    |
| AC19 | AT20's browser half: the presenting window's actual geometry | vc    |
| AC15 | theme addressing split + `--theme-path` (WP-06)              | vc    |

Two things blocking their own progress rather than each other:

- **AC19's open question needs a browser to answer.** When Chrome is already running, the launch forwards to the existing instance, and `--window-size` may not apply on that path -- so AC19's geometry could be cold-only. AT20 exists to find out; nothing else can.
- **WP-04 still reads `Not Started`** while its work is substantially done. **Its hold condition is now released**: it was held because `intent wp done` consults an acceptance gate that could not be read, and on a native `intent` the gate reads correctly (16/20, matching the view). Whether `wp done` nonetheless refuses on a gate that is legitimately BLOCKED is a different question and is **untested** -- do not assume either answer. Advancing it is a state verb and hv's to sequence.

## TODO

**Immediate, hv's**

- **Relay the `intent ac gate` defect to `intent-vc`.** Bypassed here, not fixed. On this machine `intent` resolves to `Intent/native/rust/target/release/intent` and the gate is correct: `ST0010 BLOCKED -- 16/20, unsatisfied AC15 AC16 AC18 AC19`, matching the view. **Re-verified 7 Sep: `Intent/bin/intent_acceptance:295` still reads `ac_lines() { grep -E '^- AC-[0-9]+\.[0-9]+ ' ... }`**, the v2 dotted form, while the v3 renderer emits `^- AC<nn> ` -- so a machine with no native build still gets `0/0` against a full 20-row contract. It fails safe, but **the remedy it prints is `acceptance: exempt`**, which on a thread with a real contract converts a false red into a permanent silent pass. The report stands; the urgency does not. Intent's tree; nothing here should be edited to accommodate it.
- **`geodica doctor` must report whether `utilz prez` is available.** hv's estate requirement, raised 13:36Z, still on no contract in any repo. The estate's move to `~/Devel/prj/Gtools` did not retire it.

**Deferred out of ST0011 (`stampz`), neither blocking**

- **Mixed page geometry within one PDF is refused, not handled.** `qpdf --overlay --repeat=1` applies one stamp to every page, so per-page variation needs overlay ranges. `lamplight-ac` has offered its real pack as a corpus (10 files, 55 pages, two geometries, one of them a 1440x810 deck).
- **`todo` verbs are unreachable from Emacs** (issue 0009). The bridge inserts `C-u` extra flags BETWEEN the declared flags and the path, so `utilz todo --file "done 2" <path>` exits 1. The default view works. Fixing it means the elisp appending the path before extra flags -- a bridge change, not a declaration.

**ST0010, remaining work packages**

- **WP-05 -- default theme polish.** Carries issue `0007` (slide-counter contrast) and the `prez build examples/demo.md` warning that `class 'escape' has no effect` -- prez's own example ships a warning.
- **WP-06 -- AC15, the theme addressing split** plus `--theme-path`.
- **WP-07 -- expose the theme determinism probe** (deferred, possibly to be un-deferred). Two consumers, two days apart, were both blocked by prez keeping something private and both reached for a copy: the browser list and the determinism probe. That is one design answer, not two. The ruling is hv's, because it grows the crate's public surface and the crate's whole claim is that it is liftable.

**Housekeeping, small and each independently true**

- **`chrome()` should name the browser it resolved.** One `printf ... >&2` on the resolve path in `crate/test/acceptance.sh`, matching the note it already prints when it refuses. Today it is silent exactly where it is about to launch Chrome on someone's machine, so an acceptance number carries no evidence of which mode produced it. Found by cc at EOD from a 12/0/0 where the morning's identical command gave 9 passed / 11 skipped.
- **cc's `hoist-rebase.sh` carries one dead postcondition.** `post "test/acceptance.sh" "AT13: PASS" 0` sets the minimum to zero against a `-ge` test, so it prints `ok` unconditionally -- including at the count of zero it exists to catch. Redundant rather than a hole (two other checks cover AT13), but it is the measures-nothing shape sitting inside the script that guards against silent loss. cc's; the canon-writing conflict that was holding it is cleared.

**Opportunistic, no owner**

- **Em dashes across 18 tracked docs**, against the no-em-dash convention. **Re-measured 7 Sep: 18 files, 95 occurrences.** Worst offenders `usage-rules.md` (24) and `help/syncz.md` (21); the rest are single digits. Two of the 18 are arguably out of scope -- `intent/issues/CLOSED/0001/` is a closed historical record and `opt/prez/crate/examples/test_pres.md` is crate content that moves with the pin.

- VSCode / Zed / Vim integration families (same TSV manifest, new editor-specific installers).
- Emacs bridge v2: Transient grouped menu, deferred per ST0007 `design.md`.
- The 15 per-utility `help/<name>.md` files each hardcode a version alongside the same value in `<name>.yaml`. **Re-measured 7 Sep: all 15 agree with their yaml**, because per-utility versions rarely move. `help/utilz.md` is the one that did drift (2.2.0 while 2.4.0 shipped) and now points at `utilz version` instead of carrying a number. Apply the same treatment if another lags.
