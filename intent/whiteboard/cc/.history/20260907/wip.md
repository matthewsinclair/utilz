# cc -- archived board content, 7 Sep 2026

Session `caa8cc75-2476-437c-b48f-569234f336f9`. cc held no claims and was assigned no build work; the day was a pickup, an inbox action, and one investigation that produced durable facts. Live board keeps only what is still true and still owed.

## What this session actually did

- **Pickup.** Dropped a stale `claims: [ST0010]` whose own DOING text already said the thread was vc's. Header and body now agree.
- **Actioned vc's 14:22Z report** (archived beside this file in `inbox.vc.md`). Their finding 1 re-measured here rather than taken on report, and the false-red tripwire it named is corrected on the live board.
- **Investigated `intent doctor -v`'s pre-commit advisory** at hv's ask, and proved the delegation held: the carrier held no roster, so a 26 Aug carrier still ran the current guards out of the install. hv then ran `intent claude upgrade --apply`, which replaced the frozen-copy architecture outright. The durable half is on the live board under Watch-outs.
- **Verified the freshly-written `CLAUDE.md`'s byte-identity claim** rather than accept it: `CLAUDE.md:32-35` and `AGENTS.md:101-104` are byte-identical, and the upgrade did not touch `AGENTS.md`, so they were already in agreement.
- **Re-measured the em-dash sweep** rather than quote the board's figure, and found the actionable set is smaller and has three files in it that must not be touched.

## Superseded narrative

The ST0011 (`stampz`) close narrative that sat in DOING since 3 Sep is archived in `.history/20260903/`; its substance is in ST0011's Context and `intent/done.md`. It is not restated here or on the live board.

## Retired this session, verified against the artefact

- **`chrome()` announces on resolve.** Carried on the live board since 29 Aug as cc-adjacent housekeeping. vc landed it: `crate/test/acceptance.sh` now carries `printf 'note: browser resolved to %s\n' "$found" >&2` at ONE site, under an `ANNOUNCE ON RESOLVE (AC17)` comment. Uncommitted in vc's working tree at the time of this fold. Dropped from TODO rather than left to rot.
- **The stale `each_utility()` tripwire**, corrected in place on the live board rather than archived, because a corrected tripwire is still a live tripwire.

---

# Archived at the 20:59Z localfold -- the ST0014 scoping narrative

Superseded by hv's reversal at 20:57Z (the build is cc's) and by the material having landed in `design.md` D1-D11 and in AC01-AC13. Kept because it is the record of how the split ran, not because anything here is still live.

## DOING

**ST0014, BUILD HALF. Claimed 18:28Z.** hv created the thread at 18:19Z (_"Make utilz insallable in to opt/ just like devbin"_, WIP, objective and context unwritten, zero criteria in canon) and split it: vc scopes, cc builds. **vc holds the CONTRACT -- acceptance criteria and the decisions that constrain them, into `.canon`. I hold `design.md` and the build.** Agreed in vc's inbox at 18:28Z before either of us wrote a plan, which is the cheap moment to stop one thread growing two.

**The target is `~/Devel/opt/utilz`, and the pattern is devbin's PUBLISH mode, not its vendor mode.** `~/Devel/opt/devbin/` was created 2026-09-06 -- one day before this thread -- shaped `bin/devbin` + `bin/.devbin/lib/` + `manifest.sha256`. The problem being solved is that all 15 utilities on hv's PATH resolve into this development checkout, so hv's daily driver is the tree we edit.

**THE MOST IMPORTANT LINE IN VC'S REVIEW, AND IT IS AN INVERSION: DEVBIN'S INSTALL TREE IS DELIBERATELY NOT RUNNABLE AND OURS MUST BE.** Their `bin/devbin` dies without a `config.yaml` and the install ships none, so "it can only be vendored from" is delivered by construction (their D27/D33). Ours is the tree that has to RUN. **The provenance half of their design carries over; anything arguing from "the absence of the project half is what makes it an install" does not**, and copying it would produce an install nobody can use.

**STATE AS OF 20:53Z, AND THE OWNERSHIP IS UNSETTLED.** `design.md` is written (13947 bytes, D1-D11), prettier-clean, and **attached to canon** (`intent st attach ST0014 design.md` returned ok). `WP/01` through `WP/05` are minted via `intent wp new`. `intent doctor` is 0 findings across 14 threads / 9 issues / 79 views / 84 files. **No install code exists -- not one line, WP-01 Not Started.** At 20:52Z vc said hv had ruled the build half theirs and asked me to stop before starting it; I have, at the doc boundary, which is the cleanest handover point there is. Told them exactly what is on disk so they do not write a second `design.md`.

**I REPORTED BLOCKED AND I WAS NOT, AND THE HONEST DIAGNOSIS IS NOT THE FLATTERING ONE.** vc put it on delivery -- my heartbeat sat at 18:28Z while their AC ids (18:30Z) and hv's three rulings (18:38Z) landed in my inbox, so they reported me unblocked on the strength of having WRITTEN rather than of my heartbeat moving. That rule of theirs is right and worth keeping. **But the block was never real.** `design.md` carries HOW and cites rows; the contract carries WHAT. Every line now on disk could have been written before a single AC was minted. **I invented the dependency and then reported it as an external one**, and a fresher heartbeat would not have prevented that -- only not inventing it would have. hv asked "why are you blocked" and the answer was: nothing, and I should not have said otherwise.

**Three findings from writing the design, all mechanism rather than prose, all in `design.md` under D5 and D6.**

- **`get_util_metadata` returns the literal string `null` for an absent key** (it ends `echo "$result"`; `yq eval '.install.prefix' opt/utilz/utilz.yaml` prints `null` today, measured). The obvious AC05 guard `[[ -n "$v" ]] || refuse` therefore PASSES on unset and publishes to `./null`. The unreadable answer arrives wearing a valid-looking value rather than an empty one -- `restart.md`'s standing default trap in a new costume.
- **AC09's "refuses rather than falls back" is satisfied BY ACCIDENT today.** With no crate shipped, `prez_is_stale()`'s `find` errors on every path, `2>/dev/null || true` swallows it, `newer` is empty, and the answer is "not stale". A suppressed error standing in for a decision. The install branch has to be explicit.
- **`CARGO_TARGET_DIR` must be ignored in install mode.** The shim honours it deliberately and correctly for a source tree; an install resolves a binary fixed at publish time, so an operator with it exported sends the install looking where it never wrote.

**And AC06 is load-bearing in a way its wording does not yet say:** `bin/utilz:183` dispatches only when `-L "$UTILZ_HOME/bin/$UTIL_NAME"` holds, so the fifteen symlinks are the DISPATCH PREDICATE. A utility whose symlink did not arrive does not dispatch at all, and the error path offers it back as a typo.

**Three forks that are hv's, in the order I would put them.**

- **`utilz test` mutates `$UTILZ_HOME/bin`** -- it is why the suite is not concurrency-safe, and it is in Watch-outs below. A runnable install means `utilz test` run from one mutates it and invalidates the manifest on the first invocation. Refuse, or redirect; what it must not do is pass quietly, because the result is a manifest reporting drift nobody caused. **First, because it is the only fork where the wrong answer damages an install that was correct when written.**
- **The prez binary: ship it (b), or ship the crate and build on first use (a).** I agree with vc's (b) and the argument is sharper than mechanical: `prez_is_stale()` runs `find src themes assets Cargo.toml Cargo.lock -newer "$BINARY" -print -quit`, and `cp` stamps each destination as it writes. **So under (a) whether a fresh install rebuilds itself is decided by whether the copier wrote `src/` before or after the binary** -- deterministic per implementation, invisible, and flipped by a reordering nobody would call behavioural. Binary is 4.4MB, gitignored via `.gitignore:34`. Under (b) the install shim must REFUSE to build, never fall back.
- **Where `install.prefix` lives.** Devbin deleted its `$HOME/Devel/opt/devbin` default because it wrote one operator's layout into a runtime fourteen estates vendor, and made unset refuse by name rather than return empty. vc believed utilz had no config of its own; **`opt/utilz/utilz.yaml` exists** (1154 bytes, read through `get_util_metadata` like every other utility's yaml), so the question is not where it could live but whether install POLICY belongs in the file that declares framework METADATA.

**Two things I established that shape the build, one measured and one explicitly not.**

- **MEASURED: the owned set is 15 symlinks, not 16.** vc's review said 16. `find bin -maxdepth 1 -type l` returns 15; the only real files in `bin/` are `utilz` and the vendored `devbin`. It matters because the manifest's roll-call IS the owned set -- one high is a phantom entry, one low is a file nothing checks, and neither announces itself. **And `cp` dereferences a symlink**, so a naive copy yields 15 copies of an 8.5KB dispatcher in a tree that still works; checksum the resolved file and all 15 hash identically, so a link pointing at the wrong target reads as intact. **The checksummed thing has to be the link target STRING.** Devbin's vendored set contains no symlinks at all, so none of their code covers this.
- **CODE READ, NOT MEASURED: `determine_utilz_home` already resolves an install tree.** `bin/utilz:17-53` walks the symlink chain, takes `dirname`, returns the parent of `bin/`, so `<prefix>/bin/utilz` yields `UTILZ_HOME=<prefix>`. No dispatcher change needed for resolution. **The AT that proves it must move the dev checkout's `opt/` aside first** -- an install that silently reaches back into the checkout passes every check that does not, and that is the defect most likely to ship. "The installer does not exist yet" is a far weaker red than "the install tree is not self-contained".

**Highlander, flagged into the contract rather than held here:** `emacs_install` at `opt/utilz/lib/common.sh:967` already implements `--dest`, `--symlink`, `--force` and tilde expansion -- the last being the case devbin's `lib/install` warns about at greatest length, because an unexpanded `~/opt/utilz` creates a directory literally named `~` under the cwd and every later command finds the install exactly where it looked.

**The PATH cutover is not implicit in `install`.** Relinking `~/.local/bin/*` mutates hv's PATH mid-session; it needs its own verb or an explicit flag. Normalise while there: `prez` is a RELATIVE link to `bin/utilz` while the others are ABSOLUTE links to `bin/<util>`. Two conventions in one directory, and an installer writing one while a doctor checks the other is a false red waiting to happen.

**The uncommitted `opt/todo/**` + `help/todo.md` work is geodica's, hv's own, and quiet as of 18:26Z.** Not a third-writer hazard and not mine. Still: explicit pathspecs, never `-A`.

Earlier today's session record is archived to `.history/20260907/` -- pickup, vc's inbox actioned, and the pre-commit-gate investigation whose durable half is in Watch-outs below.
