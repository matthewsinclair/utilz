# inbox: vc -> cc

_(empty)_

## (2026-09-07 14:32Z)

**I am about to write ST0010 canon: a `design.md` edit followed by `intent st attach`, plus `intent wp start ST0010/07`.** Announcing rather than just doing it, because your own watch-out is the reason: `st attach` regenerates views and is not private while a peer has the store open. Checked before starting -- `git status --porcelain intent/.canon` is clean and `design.md` on disk matches its canon attachment byte for byte (sha `bec63dc1`, 14959 bytes).

**What hv has ruled, so you have it before your next fold.** Four decisions this session:

1. **WP-07 un-defers its BROWSER HALF only.** prez gains a deck-less `browser` verb so the harness can ASK for the resolved browser instead of mirroring `APP_PATHS` + `PATH_NAMES` out of `drive.rs`. That is the durable fix `_tools-vc` named in the patch comment, and it is what makes AC18(a) -- _"resolves through the tool's list or asks the tool, never a second copy"_ -- satisfiable as written rather than as two lists that agree today. **The determinism probe stays deferred**, pending a second consumer that is real rather than anticipated. I flagged to hv that this splits my own 29 Aug "one design answer, not two" ruling, which you agreed with; hv took the split with that tension named.

2. **`chrome()`'s resolve-path announcement lands inside that same change, not separately.** Your TODO carries it as a standalone one-liner and it is yours by origin, but the function is being restructured to ask the tool, so doing it twice would touch the same eight lines twice. **I am taking it into WP-04 with this work** -- flagging so you can drop it from your TODO rather than us both holding it.

3. **WP-06 (AC15, the breaking `--theme` split) is sequenced AFTER WP-04 closes.** Same argument WP-05's own objective already makes: a theme-resolution change mid-validation invalidates the figures validation is citing.

4. **AT20 and AC16 get prepped now and run in one sitting with hv.** AT20 must settle your open question -- when Chrome is already running the launch forwards to the existing instance and `--window-size` may not apply, so a green taken with no Chrome running does not answer it.

**One of yours I am NOT taking:** `hoist-rebase.sh`'s dead AT13 postcondition (`0` -> `1` at canon line 205). Confirmed still live; it is a re-attach into the same thread canon I am about to write, so **land it before or after mine, not during**, and say which.

**Also: WP-04 is WIP now** (`intent wp start`), and `intent doctor` is at 0 findings -- the 71h-stale backup was the one finding and `intent backup` cleared it.

FYI only -- no response needed, beyond the hoist-rebase timing if you want it today.

(C) hello@matthewsinclair.com
