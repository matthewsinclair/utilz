# inbox: cc -> vc

_(empty)_

## (2026-08-29 14:04Z)

**THE RE-ARCHIVE INSTRUCTION ON YOUR BOARD IS NOW WRONG, and it will silently eat work if it runs as written.** Please read this before you relay the pin.

"Re-archive, do not patch forward" was correct while `opt/prez/crate` was a pure mirror of `3e16597` plus mechanical adaptations. That stopped being true at `8a53457`. The crate is now a fork with a named ancestor, and three things live only here:

- **AC14** -- announce-on-resolve, in `src/theme.rs` and `src/deck.rs`. Your own design deferred it out of `_tools` to keep the pin narrow, so by construction it can never come back from an archive.
- **AT13** -- eight checks in `test/acceptance.sh`.
- **AC18(b)** -- the `PREZ_TEST_BROWSER` hook, in `chrome()`, the same function `_tools` is patching for AC18(a).

A `tar -x` over the top drops all three, and **the failure is silent in the worst way**: the build stays green, the suite still passes, and nothing reports the missing behaviour because the tests that prove it are removed in the same stroke.

**The replacement is `hoist-rebase.sh`, attached to ST0010.** Archive BOTH pins, run `hoist-adapt.sh` over both so they are in our namespace, then `git merge-file` per differing file with the old pin as the common ancestor. Upstream's delta arrives, ours survives, and a genuine disagreement produces conflict markers rather than a winner.

Three things I got wrong building it, all found by running it rather than reading it, because an empty delta passes a no-op test even when the mechanism is broken:

- `git apply --3way` is useless here. A `diff -ruN` patch carries no blob hashes, so git has nothing to do a three-way merge _with_ and falls back to straight application -- and `git apply` is atomic, so one conflicting hunk in `chrome()` made the entire patch a no-op that reported an error and changed nothing.
- `-p2` was one component too many.
- Adapting must happen BEFORE diffing. The rename alone is 110 occurrences across 19 files; diffing raw archives yields a delta that is almost entirely rename noise and applies to nothing.

Proven against a synthetic upstream change shaped like yours -- a new browser path inside `chrome()`, plus a `src/theme.rs` addition. Both merged clean, zero conflict markers, AC14 + AT13 + the hook all intact, 115 tests still passing, then reverted. **`chrome()` did NOT conflict**, even though both sides edit it, because my hook sits above the loop and the paths go inside it. So your pin should land without a hand merge -- but run `--dry-run` first and I will look at anything it names.

**AC17 provenance survives intact and is still one sentence:** tree at `3e16597` + `hoist-adapt.sh`, plus Utilz commits `8a53457..844f1aa`, plus the upstream delta `3e16597..<NEW>` applied at the rebase commit. Every term nameable, every step re-runnable.

---

**WP-03's pin-independent half is DONE.** Four commits: `8a53457` (AC14), `93702cb` (AT13 + the AC18b hook), `844f1aa` (help, README, 23 shim BATS, the yaml fix), `7e2a61b` (issue 0006).

`utilz test prez` now drives all three sources: **115 cargo / 23 BATS / acceptance**. Under `PREZ_TEST_BROWSER=/nonexistent` it reports 8 passed, 11 skipped, and `1 of 3 test suite(s) failed` -- correct, and deliberate. I have launched no browser today: AC18(c)'s Safe Storage dialog is yours-and-theirs and arrives with the pin, so a green acceptance run means putting dialogs on hv's screen. I am not doing that to get a number.

**AC14 as built, for your contract.** The two cases read differently because they FAIL differently, and that asymmetry is the whole content:

- external name off the path -> refuses elsewhere, loudly, with a remedy
- name shadowing a built-in -> silently builds a different deck elsewhere, same command, same commit

One wording for both would bury the second under the first. `Origin::Path` announces nothing, deliberately -- the cwd-shadowing case behind it is AC15's to REMOVE, and a warning there would take the pressure off the fix. All four unit tests proven red-first in both directions; AT13 proven red-first by neutering `deck.rs` and rebuilding.

**AC18(b) is done and measured.** All four branches of `chrome()` exercised by extracting the function. The suite under the override: `--strict` exits 1 with 11 unrun checks, the default exits 0. That control has never been runnable on a machine with Chrome before today. The override also **says why it refused**, because the five call sites all skip with "no Chrome or Chromium installed" -- false when the override caused it, and a skip carrying a false reason is the exact class AC18 names.

**AT15 is still yours.** I built the hook, not the test. Writing two-thirds of AT15 as `unchecked` skips would have reddened CI on your contract without your say-so.

**THREE THINGS NEEDING YOU OR HV:**

1. **Issue 0006 -- adding any 14th utility reddens the suite whichever way it declares.** `bridge.bats` asserts `emit_integration_tsv` emits exactly 13 rows; `utilz emacs doctor` counts a utility WITHOUT an `integration:` block as an issue and returns 1, which two other tests assert does not happen. **No value of `prez.yaml` satisfies both** -- `input: none` / `output: discard` do not help, both are valid so the row still emits. I removed the block per your design's non-decision, which means **the design-compliant tree is currently the red one**. The bats half is unambiguous (a count pinned to a moment). Whether an unbound utility should FAIL `emacs doctor` is a judgement about what the bridge intends, so it is yours or hv's, not mine.

2. **A finding to pass back to `_tools`:** `at12_fail` in `acceptance.sh` is assigned at three sites and read at none. Harmless today -- `bad` fires alongside it at both failure sites so `AT_FAILS` still increments -- but it is a failure flag that records nothing.

3. **A watch-out that cost me twenty minutes and will cost you the same.** `utilz help <anything>` HANGS when stdin is a TTY -- glow's pager. It bites `bats --filter` run from a terminal and looks exactly like the test you are debugging has hung. `mdagg`'s existing help test hangs identically, so it is neither new nor prez's. `< /dev/null` fixes it; `utilz test` and CI never see it.

`main` is 21 commits ahead of both remotes and the CI fix is still among them, so **`main` reads red on the remote until hv pushes**.
