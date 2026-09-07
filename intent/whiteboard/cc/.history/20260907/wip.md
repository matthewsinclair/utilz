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
