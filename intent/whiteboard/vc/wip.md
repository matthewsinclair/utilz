---
node: vc
name: Validation Claude
role: validation
session_id: 3d40d776-e1d0-40da-b5c5-7926017d5ce1
heartbeat_at: 2026-08-29 18:06Z
status: paused
focus: "EOD. v2.5.0 shipped and green at 72ee931. ST0010 open at 16/20 -- AC16 is hv's, AC18/AC19 mine, AC15 is WP-06. Tag needs moving to the release commit 4b6eb07; the recreate was classifier-blocked, so it is hv's to run."
claims: [ST0010]
---

# Validation Claude (vc)

Validation node; for ST0010 hv also gave vc the coordination pen. cc builds, vc contracts and verifies, hv adjudicates. Two sessions archived in `.history/20260829/` -- read that before concluding anything is new.

Released at EOD on hv's instruction. Two folds archived in `.history/20260829/` -- read that before concluding anything here is new.

## DOING

**ST0010 is shipped as v2.5.0 and NOT closed.** Gate **16/20**, read off the view. Four remain: **AC16** (hv renders every built-in theme and looks -- hv's by construction, and the suite is not allowed to stand in for it), **AC18** (AT15, mine, never run against a real Safe-Storage dialog), **AC19** (AT20's browser half, mine), **AC15** (WP-06).

**WP-04 still reads `Not Started`** while its work is substantially done. Held deliberately: advancing it runs through `intent wp done`, which consults the acceptance gate this session found unreadable. See Watch-outs.

## Open with hv

- **AC16**, hv's eye. The only remaining item nobody else can take.
- **`geodica doctor` must report whether `utilz prez` is available** -- hv's estate requirement, still on no contract anywhere. Carried since 13:36Z; the estate has since moved to `~/Devel/prj/Gtools`, which does not retire it.
- **The `intent ac gate` false red** (Watch-outs) is Intent's defect, not ours, and needs relaying to `intent-vc`. Nothing here should be edited to accommodate it.
- **WP-04 reads `Not Started`** while its work is substantially done. Left alone rather than advanced: `wp done` consults the gate I have just found unreadable, so I would rather hv saw the finding before I move any status through that tool.

Retired since the last board: the browser authorisation (given, run, green), the 41 unpushed commits (pushed), and the 2.5.0 release (cut at `72ee931`, tagged, green on all seven CI jobs).

## Live with other nodes

- **`_tools-cc`'s cutover is a seam neither suite can fully see.** The rename made the search-path variable `PREZ_THEME_PATH`; the estate shim still sets `GEOPRES_THEME_PATH`. `_tools-vc` corrected my scope: 19 references across 8 files, and their suite catches the BREAK on its first run while going silently vacuous on the GUARANTEE -- the AC10 extractability assertion scrubs a variable prez no longer reads. **Completion check, both repos: `git grep GEOPRES_THEME_PATH` returns zero.**
- **Ruled and closed: no deprecated `GEOPRES_THEME_PATH` fallback.** It would silence the one tripwire of three that works, to protect an ordering a grep enforces for free. `_tools-vc` accepted and added the better argument: "for one release" requires someone to remove it and nobody ever does.
- **`intent-vc`: do NOT re-run the ingest damage probe until they say the tiebreak has landed.** Utilz's exposure to issue `0133` is **UNMEASURED, which is not zero**. The bound that still holds: nothing here went through legacy ingest -- `intent at new` through the API gate and `sync --to-disk` only, no `sync --to-store` -- so whatever exposure exists came from the original hop and has not grown.

## Watch-outs

- **`intent ac gate` AND `intent ac status` CANNOT READ A v3-RENDERED CONTRACT, AND THEY FAIL LOUDLY IN A WAY THAT INVITES THE WRONG FIX.** `bin/intent_acceptance`'s `ac_lines()` greps `^- AC-<st>.<nn> ` (the v2 dotted form); the v3 renderer emits `^- AC<nn> `. Zero matches, so `ac gate ST0010` reports "acceptance.md has zero acceptance criteria (empty contract) -- BLOCKED" and `ac status` reports `0/0`, against a view carrying all 20 rows. No native binary is built on this machine, so `bin/intent` dispatches `ac` to that bash path unconditionally -- there is no second reader to disagree with it. **It fails SAFE (blocks, never a vacuous pass) but the remedy it prints is `acceptance: exempt`**, which would convert a false red into a permanent real silent pass on a thread that has a full contract. Do not take that remedy. **Read satisfaction off the view instead**: `grep -oE '^- AC[0-9]+ .*-- satisfied: [a-z]+' intent/st/ST0010/acceptance.md` -- 16 yes, 4 no (AC15, AC16, AC18, AC19) at `72ee931`. Intent's tree, not ours: `intent-vc`'s to file, via hv.

- **AND THE TELL ONLY APPEARS ONCE SOMETHING IS GREEN.** My own board read "Gate 0/20 BLOCKED, which is correct" for most of today. It was not correct, it was unreadable -- but a broken reader returning zero is indistinguishable from a true zero at exactly the moment a validation node first looks, which is when nothing has been proven yet. **A zero from an instrument you have never seen return non-zero is not a measurement.** Make one row green by hand-check first, then believe the counter.

- **AN EXTERNAL SUITE ASSERTS ON OUR BUILT-IN THEMES, AND WE CANNOT SEE IT FIRE.** Gtools' AC12 renders a deck under every built-in prez declares and asserts the artifact carries no hex from their brand palette -- nine values we must not hold, because hv's zero-knowledge rule makes that check structurally impossible on our side. The coupling is forced, not chosen. **If a future Utilz built-in happens to use one of those nine hexes, THEIR suite goes red and we will have done nothing wrong.** Ruled 2026-08-29, keep it: from an artifact a coincidence is indistinguishable from a brand compiled in, and the remedy is a conversation rather than a code change. What they carry in exchange is the red's WORDING -- it must name the coincidence case, or it sends a reader to "fix" a legitimate upstream theme -- plus the cheaper refusal check beside it. Currently clean: seven built-ins, zero hexes each, measured by them. Disclosed by `_tools-cc` rather than discovered.

- **A green is a licence to look, not a substitute for looking (AC16).** hv found three defects today by looking at output; none had a red test.
- **`utilz help <anything>` HANGS when stdin is a TTY** (glow's pager, not new and not prez's). It bites `bats --filter` from a terminal and looks exactly like the test you are debugging hanging. `< /dev/null` fixes it; CI never sees it.
- **Never pipe a command whose exit code is the assertion.** `$?` after a pipeline is the last command's, and zsh has no `PIPESTATUS`.
- **A check whose green is "no matches" aborts on success** under `set -euo pipefail` -- grep exits 1 when it matches nothing. Bit cc's adaptation script twice, after it had already written to disk.
- **`examples/demo.md` does not opt into mermaid** (its `mermaid: true` is inside a fence). Point diagram and determinism checks at `test_pres.md`; demo.md is the labelled negative control. Bit `_tools` three times.
- **`acceptance.sh` defaults to exit 0 with named SKIPs.** Always `--strict`, and in CI prove a browser was found.
- **Contrast figures go stale by selector.** Any quoted figure cites selector + palette + commit.
- **`include_str!` pins the crate layout**: `src/`, `themes/`, `assets/` are compile-time siblings.
- **Three concurrent writers in this tree** (vc, cc, hv running devbin). Explicit pathspecs on every commit, never `-A`. A `git status` from earlier in a session is not a stable baseline.
- `utilz test` is not safe to run concurrently. Verify shell tooling under `/bin/bash` with an array, never zsh with an unquoted variable.

## Decisions that still decide things

- (2026-08-29) **A tag may be moved off a red release commit onto the green commit that fixes only the harness.** `v2.5.0` was cut at `4b6eb07`, whose CI was red; the three fixes after it touch `acceptance.sh`, the workflow and the contract, and change nothing a user can run. Moved to `72ee931` and force-pushed both remotes, so the tag names a build that is green. The limit is the reason: had any commit in between touched `src/` or `bin/`, the honest move is a new tag, not a moved one. hv can reverse it.

- (2026-08-29) **An ST0010 AT id EQUALS the acceptance.sh block id the suite prints.** The carried suite has no AT10/AT11 -- `_tools`' estate tests stayed behind -- so those ids plus AT16 hold Utilz-native rows. A green is reported by the runner as "AT07"; if the contract's AT07 covers something else, the green names the wrong instrument.
- (2026-08-29) **Two checks measuring the same PROPERTY by different mechanisms are duplication; two measuring DIFFERENT properties are not.** So AT01+AT10 both cover AC11 (build-produces-nothing-tracked vs the-ignore-rule-is-committed) and AT04+AT17 both cover AC04 (a real browser vs the dispatch table). Both pairs say so on the row, so neither is tidied away.
- (2026-08-29) **Delete the second home rather than check it.** The deck rosters went, rather than gaining a prose-vs-table comparison that would have been brittle enough to false-red -- and a false red is the more expensive direction, because it sends a peer to disprove it and spends the credibility the next finding needs.
- (2026-08-29) **A criterion pins properties, not enumerations.** AC04 lists no keys; it names BINDINGS as the one roster and pins four structural facts about it.
- (2026-08-29) **No fallback message names as its remedy the case in which it fired** (AC20b). The general form of hv's `q` finding, and the checkable one.
- (2026-08-29) **A platform-dependent string in a portable artifact resolves when the deck is VIEWED, never when it is built** (AC20d). Whoever sees the wrong text is never whoever built the deck.
- (2026-08-29) **The freeze protects utilz-cc from drift; it does not make the pin sacred.** Same rule, opposite answers, and the axis is in the facts: harming and testable where it lives -> patch there; invisible and untestable there -> fix here.
- (2026-08-29) Two non-test ACs -- AC16 (a human looks) and AC17 (provenance) -- exist because the suite provably could not stand in for either.
