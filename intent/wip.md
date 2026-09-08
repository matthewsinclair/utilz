---
verblock: "08 Sep 2026:v1.17: matts - AC-id ruling discharged; ST0013 to cc; geodica doctor routed"
---

# Work In Progress

This file carries **DOING and TODO only**. Completed work belongs in `intent/done.md`; durable context and conventions belong in `intent/restart.md`. Nothing done is recorded here, ever -- a "just landed" list here is the same narrative in two files with two values, and nothing reports the divergence.

## DOING

**Nothing in flight.**

## TODO

**Immediate, hv's**

- **Tag `v2.6.0` at `4fdce3c` and push.** 48 commits unpushed.
- **`geodica doctor` must report whether `utilz prez` is available.** hv's estate requirement. **Put to the `geodica` node directly on 8 Sep** rather than left unowned: Utilz cannot host it under hv's zero-knowledge ruling, so it looks like theirs, and they were asked to take it or argue it back. Waiting on their answer.

**Threads open**

- **ST0013 -- prez theme addressing. ASSIGNED TO cc 8 Sep**, contract stays vc's. (`--theme` names-only, `--theme-file`, `--theme-path`). 0/1. Carries ST0010's AC15 verbatim, and AT01 is genuinely red-first: `--theme=NAME` must resolve identically from two working directories, one holding a `./NAME/` directory, and it is red against the pinned binary because `path.exists()` wins. **It is a BREAKING change to `prez present <deck> --theme <path>`, which is in hv's shell history**, so clause (f) requires the refusal to name `--theme-file`.

**Deferred out of ST0011 (`stampz`), neither blocking**

- **Mixed page geometry within one PDF is refused, not handled.** `qpdf --overlay --repeat=1` applies one stamp to every page, so per-page variation needs overlay ranges. `lamplight-ac` has offered its real pack as a corpus (10 files, 55 pages, two geometries).
- **`todo` verbs are unreachable from Emacs** (issue 0009). The bridge inserts `C-u` extra flags BETWEEN the declared flags and the path. The default view works. Fixing it means the elisp appending the path before extra flags.

**Carried out of ST0010 when it closed**

- **Issue `0007` -- the prez slide counter drops below the 4.5:1 contrast floor on dark slides.** OPEN, and a tracked issue may drive a focused bugfix without a full thread.
- **prez's default look, "basic but cool enough out of the box."** hv's words, no criterion behind it, no thread. It earns one when hv wants it.
- **`prez build examples/demo.md` warns `class 'escape' has no effect`** -- prez's own example ships a warning. Deck content.
- **The theme determinism probe is deferred and has no consumer.** WP-07's browser half shipped as the `browser` verb; the probe half was never un-deferred. `design.md` section 12 in ST0010's canon is the record.

**Housekeeping**

- **cc's `hoist-rebase.sh` carries one dead postcondition.** `post "test/acceptance.sh" "AT13: PASS" 0` sets the minimum to zero against a `-ge` test, so it prints `ok` unconditionally, including at the count of zero it exists to catch. cc's, and it is a re-attach into ST0010's canon -- a CLOSED, dehydrated thread, so it needs a hydrate first.
- **`intent/issues/CLOSED/` renders only 0001-0006** while canon holds 9. `intent doctor` reports 0 findings and does not treat it as skew, but a reader who lists that directory sees a stale set.
- **`utilz doctor` writes its results to stderr and its step headers to stdout**, so `utilz doctor | grep` sees the headers and not the answers. Pre-existing and unruled: changing it could break a caller, and the help now documents it rather than assuming nobody pipes it.

**Opportunistic, no owner**

- **Em dashes across 18 tracked docs**, against the no-em-dash convention. 95 occurrences; worst are `usage-rules.md` (24) and `help/syncz.md` (21). Two of the 18 are arguably out of scope -- `intent/issues/CLOSED/0001/` is a closed historical record and `opt/prez/crate/examples/test_pres.md` is crate content that moves with the pin.
- **The 15 per-utility `help/<name>.md` files each hardcode a version alongside the same value in `<name>.yaml`.** All 15 currently agree, because per-utility versions rarely move. Apply `help/utilz.md`'s treatment -- point at the command instead of carrying a number -- if another lags.
- VSCode / Zed / Vim integration families (same TSV manifest, new editor-specific installers).
- Emacs bridge v2: Transient grouped menu, deferred per ST0007 `design.md`.
