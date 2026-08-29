---
node: vc
name: Validation Claude
role: validation
session_id: 3d40d776-e1d0-40da-b5c5-7926017d5ce1
heartbeat_at: 2026-08-29 16:43Z
status: active
focus: "ST0010 WP-04 substantially done. hv authorised the browser: acceptance 12/0/0 exit 0 with real Chrome, utilz test exit 0 across 17 suites, 17 ATs green, gate 16/20. Remaining: AC16 (hv looks), AC18/AT15 mine, AC19/AT20 browser layer, AC15 is WP-06."
claims: [ST0010]
---

# Validation Claude (vc)

Validation node; for ST0010 hv also gave vc the coordination pen. cc builds, vc contracts and verifies, hv adjudicates. Two sessions archived in `.history/20260829/` -- read that before concluding anything is new.

`status` stays `active` through the compact deliberately: `/compact` does not end a session (whiteboard invariant 6) and hv is holding on the bounce. A `release` here would put a false `paused` on the board.

## THE ONE THING BLOCKING EVERYTHING

**hv has not authorised a browser run, and nothing else is in the way.** Queued behind that single decision: AT04, AT18's browser half, the eleven browser-dependent acceptance checks, and the AC17 cold build. That is the whole remaining distance to WP-04 closing. The keychain fix is in the pin, so the dialog risk is far lower than this morning -- but it is hv's screen and hv's call. **Do not launch a browser without it.**

**AC16 is hv's by construction** -- a human renders every theme and looks. vc prepares the renders; vc cannot be the eye.

## State, verified not relayed

- **Pin `b600306`.** Landed as a MERGE via cc's `hoist-rebase.sh`, not a re-archive -- the crate is a FORK (AC14, AT13, AC18(b) exist only here). Its postcondition check is 16 items and asserts our work survived; a `tar -x` over the top goes red rather than reporting a clean merge.
- **Contract 20 ACs / 19 ATs / 7 WPs.** WP-01/02/03 Done. WP-04 (validation) mine and next. WP-05 default theme polish, WP-06 theme addressing split, WP-07 expose the determinism probe -- all after.
- **`intent doctor` 0 findings. `intent at lint ST0010` ok, 19 rows.** Gate 0/20 BLOCKED, which is correct: nothing goes green until instruments run here.
- cc reports 128 cargo tests, clippy clean, shellcheck clean across 16, acceptance 9 passed / 11 skipped under the browser override.
- **AC19 and AC20 spot-verified by me** at `f5253a9`: `--start-fullscreen` gone from the launch path, `--window` guarded to `present` and refusing in pixels, the Rust naming no platform, and ONE artifact carrying both `cmd-W` and `ctrl-W` chosen at view time. Ran the browserless probe myself: **37 passed, 0 failed, exit 0**. These are spot checks, NOT AT greens -- my artifact came from the warm dev tree and so fails AC17's provenance. Statuses left alone deliberately.

## WP-04, when the browser is authorised

Re-produce every carried green with instruments run HERE, and state what was not checked.

- **AC17 first**, because it gates the meaning of everything after it: `rm -rf opt/prez/crate/target`, cold build at `b600306`, provenance recorded beside the numbers. `_tools-vc` has sent the literal procedure -- **use their line, not a parallel one**, so the two measurements are the same measurement taken twice.
- **The trap in it**, theirs, paid for: `_tools`' devbin `export`s `CARGO_TARGET_DIR` and overwrote their isolation, so a "cold" build ran warm, finished in 0.05s and reported exit 0. Whatever lever forces cold, **assert afterwards that it went cold** -- the artifact is where isolation put it, and the wall time is a release build's. cc found the same class here from the other end: the shim hardcoded `$CRATE_DIR/target` while cargo honoured the variable. Fixed; 8.50s now.
- Then `cargo test`, `acceptance.sh --strict`, the runtime probe, the legibility probe, the liftability refusal, the standalone greps. Walk ATs through red where the lifecycle requires.
- **`_tools-vc` is standing by to re-run our greens on their machine** against the cold-built binary; their numbers go beside ours. Send the exact command with the corrected map. Their figures: 10 ATs `--strict`, 0/0, exit 0, 69s. Contrast, flattened, floor 4.5: simple 6.0, **mono 4.9 nearest**, manuscript 5.7, contrast 14.2, blueprint 7.6, steampunk 5.5, 8bit 6.2, geodica 6.9.
- Then announce prez-green to `_tools-cc`: their trigger to land the `geodica present` client rewrite plus a `geodica doctor` check in ONE commit.

## Open with hv

- **The browser authorisation** (above). Everything waits on it.
- **AC16**, hv's eye.
- **41 commits unpushed**, both remotes behind, CI fix among them -- so `main` reads red on the remote until hv pushes.
- **The 2.5.0 release.** `prez.yaml` declares `utilz_version "^2.5.0"`; `VERSION` still reads 2.4.0. `run_doctor` compares majors only so nothing false-alarms meanwhile. Bump, tag and push are hv's.
- **`geodica doctor` must report whether `utilz prez` is available** -- hv's estate requirement, still on no contract anywhere.

## Live with other nodes

- **`_tools-cc`'s cutover is a seam neither suite can fully see.** The rename made the search-path variable `PREZ_THEME_PATH`; the estate shim still sets `GEOPRES_THEME_PATH`. `_tools-vc` corrected my scope: 19 references across 8 files, and their suite catches the BREAK on its first run while going silently vacuous on the GUARANTEE -- the AC10 extractability assertion scrubs a variable prez no longer reads. **Completion check, both repos: `git grep GEOPRES_THEME_PATH` returns zero.**
- **Ruled and closed: no deprecated `GEOPRES_THEME_PATH` fallback.** It would silence the one tripwire of three that works, to protect an ordering a grep enforces for free. `_tools-vc` accepted and added the better argument: "for one release" requires someone to remove it and nobody ever does.
- **`intent-vc`: do NOT re-run the ingest damage probe until they say the tiebreak has landed.** Utilz's exposure to issue `0133` is **UNMEASURED, which is not zero**. The bound that still holds: nothing here went through legacy ingest -- `intent at new` through the API gate and `sync --to-disk` only, no `sync --to-store` -- so whatever exposure exists came from the original hop and has not grown.

## Watch-outs

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

- (2026-08-29) **An ST0010 AT id EQUALS the acceptance.sh block id the suite prints.** The carried suite has no AT10/AT11 -- `_tools`' estate tests stayed behind -- so those ids plus AT16 hold Utilz-native rows. A green is reported by the runner as "AT07"; if the contract's AT07 covers something else, the green names the wrong instrument.
- (2026-08-29) **Two checks measuring the same PROPERTY by different mechanisms are duplication; two measuring DIFFERENT properties are not.** So AT01+AT10 both cover AC11 (build-produces-nothing-tracked vs the-ignore-rule-is-committed) and AT04+AT17 both cover AC04 (a real browser vs the dispatch table). Both pairs say so on the row, so neither is tidied away.
- (2026-08-29) **Delete the second home rather than check it.** The deck rosters went, rather than gaining a prose-vs-table comparison that would have been brittle enough to false-red -- and a false red is the more expensive direction, because it sends a peer to disprove it and spends the credibility the next finding needs.
- (2026-08-29) **A criterion pins properties, not enumerations.** AC04 lists no keys; it names BINDINGS as the one roster and pins four structural facts about it.
- (2026-08-29) **No fallback message names as its remedy the case in which it fired** (AC20b). The general form of hv's `q` finding, and the checkable one.
- (2026-08-29) **A platform-dependent string in a portable artifact resolves when the deck is VIEWED, never when it is built** (AC20d). Whoever sees the wrong text is never whoever built the deck.
- (2026-08-29) **The freeze protects utilz-cc from drift; it does not make the pin sacred.** Same rule, opposite answers, and the axis is in the facts: harming and testable where it lives -> patch there; invisible and untestable there -> fix here.
- (2026-08-29) Two non-test ACs -- AC16 (a human looks) and AC17 (provenance) -- exist because the suite provably could not stand in for either.
