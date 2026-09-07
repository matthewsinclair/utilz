---
verblock: "07 Sep 2026:v1.12: matts - EOD; CI fix landed and Xvfb verified, one red left needing hv's call"
---

# Work In Progress

This file carries **DOING and TODO only**. Completed work belongs in `intent/done.md`; durable context and conventions belong in `intent/restart.md`. Nothing done is recorded here, ever -- a "just landed" list here is the same narrative in two files with two values, and nothing reports the divergence.

## DOING

**Nothing in flight.** ST0010 closed 7 Sep; ST0011 closed 3 Sep. Both are dehydrated, so neither has files on disk and both are whole in canon.

Two open threads, neither started:

- **ST0013 -- prez theme addressing** (`--theme` names-only, `--theme-file`, `--theme-path`). 0/1. Carries ST0010's AC15 verbatim, and AT01 is genuinely red-first: `--theme=NAME` must resolve identically from two working directories, one holding a `./NAME/` directory, and it is red against the pinned binary today because `path.exists()` wins. **It is a BREAKING change to `prez present <deck> --theme <path>`, which is in hv's shell history**, so clause (f) requires the refusal to name `--theme-file`.
- **ST0012 -- estate file policy.** 4/4 PASS. Open because the policy is standing, not because work is outstanding. It declares the dehydration preconditions that let a closed thread's files leave the tree.

## TODO

**Immediate, hv's**

- **Push.** The CI fix and both board updates went up with the 16:45Z history rewrite; what is unpushed at EOD is cc's briefing commit and this fold.
- **ONE CI JOB IS STILL RED, AND IT NEEDS A CONTRACT CALL RATHER THAN A PATCH.** Run `34144634306` cleared three of the four failures -- including the Xvfb path, now VERIFIED: AT20 ran all four legs on Linux at 8 checks each. `Rust (ubuntu-latest)` still fails at **14 passed / 0 failed / 1 skipped**, because AT15's keychain half calls `unchecked()` when `security(1)` is absent and `--strict` reddens on any skip. **Nothing is broken.** `unchecked()` conflates a tool that is missing but installable (a real gap) with a check that cannot exist on this platform at all (`security(1)` is macOS-only, and the macOS job does run that half). A remedy means a third outcome that prints its reason without counting as did-not-run -- **which is a licence to wave away inconvenient skips unless the platform predicate, never the check's difficulty, is the condition.** It would be the first exception to "a SKIP is not a pass", so it is hv's to grant.
- **Relay the `intent ac gate` defect to `intent-vc`, now with a SECOND instance.** `Intent/bin/intent_acceptance:295` still greps the v2 dotted form while the v3 renderer emits `^- AC<nn> `, so a machine with no native build reports `0/0` against a full contract. **And the dehydration gate's `<<PRECONDITIONS ... PRECONDITIONS>>` block parses only the v2 dotted id too** -- `intent ac new` mints `AC91` happily and the gate then rejects it as "not an AC id". Same mismatch, two readers. Intent's tree; nothing here should be edited to accommodate either.
- **`geodica doctor` must report whether `utilz prez` is available.** hv's estate requirement, still on no contract in any repo. The move to `~/Devel/prj/Gtools` did not retire it.

**Deferred out of ST0011 (`stampz`), neither blocking**

- **Mixed page geometry within one PDF is refused, not handled.** `qpdf --overlay --repeat=1` applies one stamp to every page, so per-page variation needs overlay ranges. `lamplight-ac` has offered its real pack as a corpus (10 files, 55 pages, two geometries).
- **`todo` verbs are unreachable from Emacs** (issue 0009). The bridge inserts `C-u` extra flags BETWEEN the declared flags and the path. The default view works. Fixing it means the elisp appending the path before extra flags.

**Carried out of ST0010 when it closed**

- **Issue `0007` -- the prez slide counter drops below the 4.5:1 contrast floor on dark slides.** OPEN, and it now drives the fix directly: WP-05 was cancelled on the rule that a tracked issue may drive a focused bugfix without a full thread.
- **prez's default look, "basic but cool enough out of the box."** hv's words, no criterion behind it, no thread. It earns one when hv wants it.
- **`prez build examples/demo.md` warns `class 'escape' has no effect`** -- prez's own example ships a warning. Deck content.
- **The theme determinism probe is still deferred.** WP-07's browser half shipped as the `browser` verb; the probe half was never un-deferred and has no consumer. `design.md` section 12 in ST0010's canon is the record.

**Housekeeping**

- **cc's `hoist-rebase.sh` carries one dead postcondition.** `post "test/acceptance.sh" "AT13: PASS" 0` sets the minimum to zero against a `-ge` test, so it prints `ok` unconditionally, including at the count of zero it exists to catch. Re-verified 7 Sep at canon line 205. cc's, and it is a re-attach into ST0010's canon -- which is now a CLOSED, dehydrated thread, so it needs a hydrate first.
- **`intent/issues/CLOSED/` renders only 0001-0006** while canon holds 9. `intent doctor` reports 0 findings and does not treat it as skew, but a reader who lists that directory sees a stale set. cc's finding, 7 Sep.

**Opportunistic, no owner**

- **Em dashes across 18 tracked docs**, against the no-em-dash convention. **Re-measured 7 Sep: 18 files, 95 occurrences.** Worst offenders `usage-rules.md` (24) and `help/syncz.md` (21); the rest are single digits. Two of the 18 are arguably out of scope -- `intent/issues/CLOSED/0001/` is a closed historical record and `opt/prez/crate/examples/test_pres.md` is crate content that moves with the pin.

- VSCode / Zed / Vim integration families (same TSV manifest, new editor-specific installers).
- Emacs bridge v2: Transient grouped menu, deferred per ST0007 `design.md`.
- The 15 per-utility `help/<name>.md` files each hardcode a version alongside the same value in `<name>.yaml`. **Re-measured 7 Sep: all 15 agree with their yaml**, because per-utility versions rarely move. `help/utilz.md` is the one that did drift (2.2.0 while 2.4.0 shipped) and now points at `utilz version` instead of carrying a number. Apply the same treatment if another lags.
