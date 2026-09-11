---
verblock: "11 Sep 2026:v1.22: matts - ST0017 closed; tag and push are hv's"
---

# Work In Progress

This file carries **DOING and TODO only**. Completed work belongs in `intent/done.md`; durable context and conventions belong in `intent/restart.md`. Nothing done is recorded here, ever -- a "just landed" list here is the same narrative in two files with two values, and nothing reports the divergence.

## DOING

**Nothing in flight.**

## TODO

**Immediate, hv's**

- **Push `local`, then tag.** ST0017 closed 11 Sep; `local` 13+ behind HEAD, `upstream` frozen at `60153d8` (CI credits). `v2.6.0` at `4fdce3c` is still untagged too.
- **`geodica doctor` -- TAKEN BY `geodica` 8 Sep, off this board.** They accepted it and gave a better argument than the zero-knowledge one I led with: `geodica_present` already refuses with a remedy when prez is missing, so doctor reporting it is **the same fact surfaced EARLIER**, which makes it a diagnosis rather than a duplicate. Not scheduled -- they are mid-deliverable and there is no deadline.

**Threads open**

- **ST0013 -- prez theme addressing. ASSIGNED TO cc 8 Sep**, contract stays vc's. (`--theme` names-only, `--theme-file`, `--theme-path`). 0/1. Carries ST0010's AC15 verbatim, and AT01 is genuinely red-first: `--theme=NAME` must resolve identically from two working directories, one holding a `./NAME/` directory, and it is red against the pinned binary because `path.exists()` wins. **It is a BREAKING change to `prez present <deck> --theme <path>`, which is in hv's shell history**, so clause (f) requires the refusal to name `--theme-file`.

**Deferred out of ST0011 (`stampz`), neither blocking**

- **Mixed page geometry within one PDF is refused, not handled.** `qpdf --overlay --repeat=1` applies one stamp to every page, so per-page variation needs overlay ranges. `lamplight-ac` has offered its real pack as a corpus (10 files, 55 pages, two geometries).
- **`todo` verbs are unreachable from Emacs, and this has NO TRACKED HOME.** The bridge inserts `C-u` extra flags BETWEEN the declared flags and the path; the default view works. **Issue 0009 is CLOSED having deliberately ACCEPTED the limitation**, so citing it here was wrong -- this proposes a third option 0009 never weighed. Doc-before-code blocks the fix until it has an issue or a thread. cc's finding, 8 Sep.

**Carried out of ST0010 when it closed**

- **Issue `0007` -- the prez slide counter drops below the 4.5:1 contrast floor on dark slides.** OPEN, and a tracked issue may drive a focused bugfix without a full thread.
- **prez's default look, "basic but cool enough out of the box."** hv's words, no criterion behind it, no thread. It earns one when hv wants it.
- **`prez build examples/demo.md` warns `class 'escape' has no effect`** -- prez's own example ships a warning. Deck content.
- **The theme determinism probe is deferred and has no consumer.** WP-07's browser half shipped as the `browser` verb; the probe half was never un-deferred. `design.md` section 12 in ST0010's canon is the record.

**Housekeeping**

- **cc's `hoist-rebase.sh` carries one dead postcondition.** `post "test/acceptance.sh" "AT13: PASS" 0` sets the minimum to zero against a `-ge` test, so it prints `ok` unconditionally, including at the count of zero it exists to catch. cc's, and it is a re-attach into ST0010's canon -- a CLOSED, dehydrated thread, so it needs a hydrate first.
- **`intent/issues/OPEN/` and `CLOSED/` on disk are a STALE RENDERING of canon.** Canon holds ten; the OPEN directory is empty while **0007** (prez contrast) and **0010** (eight utility READMEs ship hv's absolute home path into an install) are both open. `intent doctor` counts canon and reports no skew, so nothing flags it. **Read issues with `intent issues list`, never with `ls`.** Corrected against cc's measurement 8 Sep; my earlier "canon holds 9, only 0007 open" was stale.
- **`utilz doctor` writes its results to stderr and its step headers to stdout**, so `utilz doctor | grep` sees the headers and not the answers. Pre-existing and unruled: changing it could break a caller, and the help now documents it rather than assuming nobody pipes it.

**Blocked on a missing Intent verb**

- **101 flat AC/AT ids in this repo are non-conforming and there is NO WAY TO RENAME THEM.** Measured from canon 8 Sep: ST0010 40, ST0011 21, ST0013 2, ST0014 38, plus 38 distinct ids cited across 11 files in the live tree. `intent-vc` landed hv's `is_ac_id` relaxation (`93c5a53d9`), taking the fleet from 307 non-conforming to 125 with zero files touched -- **and the surviving 125 are exactly Gtools 24 and OUR 101.** The flat form is broken today regardless of Intent: it breaks `group_of`, the renderer's grouping and the ship gate.
  **The blocker is the mechanism.** `intent ac` has `new`, `edit`, `descope`, `withdraw` and `reinstate`; there is no rename, and `edit` rewords text only. So migration is withdraw-and-re-mint, which on ST0014 cost 4 withdrawn rows and 19 reference migrations for FOUR ids -- **scaled, ~101 tombstones across four contracts, which is worse than the disease.** Three of the four threads are also CLOSED and DEHYDRATED, so each is hydrate, rewrite canon, re-dehydrate.
  **Do not start this without a rename verb.** ST0013's 2 ids are the cheap pilot if one lands -- **but only after cc has stopped citing them, or with cc's agreement first.** `intent-vc`'s condition, and it is the right one: the whole reason the 101 are expensive is that ids get cited, so taking the pilot while a peer is building against those ids reproduces the defect at small scale. Confirmed at the layer below the CLI too -- `grep 'fn ac_rename|fn ac_rekey|fn rename'` over `facade.rs` returns nothing, so it is not a missing surface over a present capability. Requested from `intent-vc` as the same root they already have filed: the mint accepts what it should refuse and nothing can correct it afterwards -- the AC-kind hole in a second field.

**Wanted, hv's, no thread yet**

- **The crawl should recede as it rises, Star Wars pre-roll style** -- larger at the bottom as it arrives, shrinking as it flows up so it reads as fading into the distance. hv's request 2026-09-09, explicitly "when we get to it". **It is a change to `player.html`, which ST0017 carries across UNCHANGED by design**, so it belongs AFTER the hoist and in Utilz, not in the Snorkeltoast prototype -- otherwise the thing being ported moves while the port is being graded against it. Today `.crawl .text` is `transform-origin:50% 0` with a linear translate; the recede effect wants a 3D transform (a `perspective` on the stage plus `rotateX` on the text), which is a different mechanism rather than a tweak to the current one.

**Opportunistic, no owner**

- **Em dashes: 27 files, 110 occurrences**, measured by cc 7 Sep excluding canon, history, closed issues and the crate. My earlier 18/95 was the stale figure. Worst are `usage-rules.md` (24) and `help/syncz.md` (21). **THREE FILES MUST NOT BE TOUCHED AND A BLIND SED IS A DEFECT RATHER THAN A TIDY**: two `opt/macoz/images/backgrounds/autumn-*.png` are binaries where the byte sequence is coincidental, and **`opt/cleanz/data/trope-indicators.txt` is a DETECTOR LIST -- the em dash there is what the utility hunts, so rewriting it breaks cleanz.**
- **The 15 per-utility `help/<name>.md` files each hardcode a version alongside the same value in `<name>.yaml`.** All 15 currently agree, because per-utility versions rarely move. Apply `help/utilz.md`'s treatment -- point at the command instead of carrying a number -- if another lags.
- VSCode / Zed / Vim integration families (same TSV manifest, new editor-specific installers).
- Emacs bridge v2: Transient grouped menu, deferred per ST0007 `design.md`.
