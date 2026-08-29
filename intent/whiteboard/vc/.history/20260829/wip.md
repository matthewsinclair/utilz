# vc archive -- 2026-08-29

Archived at the 13:26Z localfold. Live board keeps only what is still in flight.

## DONE this session

- **First pickup.** Both inboxes empty, no opening assignment; proposed the v2->v3 migration audit as a standing target, which hv superseded with ST0010.
- **Coordination pen for ST0010**, at hv's direction ("utilz-vc has the plan"). Three peer nodes: utilz-cc (builder here), _tools-cc (built geopres), _tools-vc (validated it).
- **WP-01 DONE.** Wrote ST0010's Objective + Context + design.md and the whole contract: 18 ACs, 15 ATs, 7 WPs. Ratified by hv on all three nodes.
- **Findings surfaced to hv**: CI red on main (devbin SC1091, cause and fix both verified by me under /bin/bash with an array); the stale restart doc; the whiteboard roster gap (closed by cc at 4c88248, naming vc as the reader of hv/inbox.*).
- **Rulings issued and carried**: fix-then-hoist; the pin and its two supersessions; _tools AC01 not transcribed (verified: Utilz outside Dropbox, bare local remote); AC08's addressing clause excised to AC15 rather than transcribed-then-edited; the estate's static grep vs prez's runtime probe being different checks rather than two homes; AC18 ownership split.
- **Errors made and corrected in-session**: told _tools-cc to patch "both launch sites" when there are four -- I had the evidence in my own grep output and read the conclusion off the narrower query. _tools-vc caught it; corrected before anyone acted.

## Superseded

- The migration-audit plan (Phases 0-4) proposed at pickup. Not cancelled on merit -- hv redirected to ST0010. Findings that survived it: doctor 3 -> 2 (the steel_threads.md view-skew cleared when my ST0010 sync regenerated the view); the ST0009 migrator gate and backup-stale remain open and are cc's/hv's, not ST0010's.

---

## Session 2 archive -- 2026-08-29, folded 15:42Z

The afternoon: ST0010's contract grew 18 -> 20 ACs and 15 -> 19 ATs, WP-03 closed, and a second workstream (Intent v3, with `intent-vc`) ran alongside it.

### Closed, needing nothing further

- **CI red on `main`** -- fixed at `95b650a` (the blocking shellcheck gate was linting vendored devbin).
- **ST0009's blocked gate** -- three AT rows carried v2 free text in `file`. Repaired at `2fd5187` after `intent-vc` ruled: preserve the specimen FIRST. It needed no manufactured commit; `3e3bbbe` is the commit that produced the state, which is better evidence than one made to hold it. `intent doctor` went 2 -> 0.
- **The formatter fence hole** -- `.prettierignore` enumerated four paths and `design.md` was not among them, so prettier reformatted an attachment and the hash stopped matching canon. Fixed at `2affb2f` by replacing the enumeration with the principle (`intent/st/**`). Proven by committing the repair and confirming the hash survived the hook.
- **Issue 0006** -- adding any 14th utility reddened the suite whichever way it declared. hv ruled both halves; I landed (2) at `d39422e`, cc landed (1). CLOSED at `406af49`; `intent/issues/OPEN/` empty.
- **The AT map** -- every acceptance.sh-backed row covered an AC one off from the block that tests it, because dropping `_tools`' AC01 renumbered the ACs while the ATs kept their sequence. Re-derived block by block at `aeeec3b`. The rule that prevents recurrence: an ST0010 AT id EQUALS the acceptance.sh block id the suite prints.
- **The deck key rosters** -- both example decks restated BINDINGS in prose, which is how hv saw "Esc overview grid" after that UX was removed. Deleted rather than checked (`e264bef`), AC04(e) forbids the return. A prose-vs-table check would have needed to pair keys with labels, and the failure was a label beside a key that still existed -- a token check goes green on the very screenshot hv sent.
- **AC04 rewritten twice.** First for hv's runtime change, then again because my own first rewrite ENUMERATED the key bindings -- a third home for the roster, in the thread whose subject is second homes. It now pins structural properties and names BINDINGS as the one roster.

### The pin, resolved

`3e16597` -> `b600306`. I spent an hour telling people the pin was stalled and then that it must be re-archived; both were wrong, and `_tools-vc` retracted the moving-pin expectation independently. What actually happened: nothing that compiles ever moved between the two pins, and the crate had become a FORK (AC14, AT13, AC18(b) live only in Utilz), so the pin landed as a MERGE via cc's `hoist-rebase.sh`.

### Five errors, one shape

1. **"The pin is stalled"** -- it was mid-flight. I had a way to say which reading I could not distinguish and asserted the worse one.
2. **"The patch is complete and correct at all four sites"** -- validated by reading, not running. The `--user-data-dir` half hung the suite forever at the two `$(...)` sites; three orphaned Chromes on hv's machine.
3. **"Two symlinks, a Highlander violation"** -- `~/bin` IS `~/.local/bin`, a symlink since Dec 2024. One directory seen twice. I accused cc of creating my own file. `ls -l`, `stat` and `which` all report faithfully on two names for one directory; one `readlink ~/bin` would have settled it.
4. **"Invisible from both sides by construction"** -- `_tools`' suite has THREE tripwires on the rename. One fires correctly, one is a spelling check in behaviour's clothes, and one goes silently vacuous. I generalised from "my suite cannot see it" to "no suite can" without reading theirs.
5. **"Re-archive whole, not surgically"** -- would have silently deleted AC14, AT13 and AC18(b). I verified the upstream half exhaustively (both pins diffed, five paths byte-identical, four launch sites read one by one) and ran NOTHING against our own tree before ruling on how to merge them.

**All five are the same move: a thorough measurement of one half, stated as a claim about the whole.** `_tools-vc` matched it the same day with a count they read as a fact three separate ways. Naming the shape is the repair; the instances are not worth more.

Also caught and not shipped: I measured a refusal's exit code through `tail` and read `exit=0`, seconds from reporting that the liftability guarantee did not fail. `$?` after a pipeline is the last command's. Our own design doc says never to pipe a command whose exit code is the assertion, and I did it inside the check written to verify that guarantee.

### Intent v3 -- six findings, two live in Intent's own tree

Two were already tracked (`0100`, `0082`); one is a second instance of `0118`; one was new. Two issue bodies handed to `intent-vc` ready to file verbatim rather than filed by me, because Intent issue `0090` means a body has one writing verb and no rewriting verb.

- **The migrator has two behaviours for one input shape**, in one thread: nine rows preserved v2 text honestly under `legacy.raw` and lint clean; three asserted a path that was never a path. Only the destructive branch is detectable.
- **`sync --to-disk` does not write attachments** and doctor's `attachment-drift` remedy says it does. Measured three ways, all no-ops, both reporting `ok`.
- **Their damage probe fails its own self-test here**, 5 of 8. I refused to run it on Utilz and reported the failure instead. `intent-vc` reproduced it 4-pass/8-fail in twelve runs on the same Python: `newest_v2_blob` orders by commit time in WHOLE SECONDS and the fixture plants a burst. My Python 3.14 hypothesis was wrong; the clustering I reported was right. They had bisected four refs at one sample each and were about to file "no regression".
- **The synthesis routed to hv's documentation task**: the migrator cannot manufacture instrument names v2 never recorded, so every v2 project with free-text ATs inherits a blocked gate on upgrade with hand-repair the only exit.

### hv found three defects by looking, none of which had a red test

The stale deck advertising removed UX; a portrait window for a 16:9 deck; and `q` advertising a close it cannot perform. 128 cargo tests, a 37-check runtime probe, clippy and shellcheck had nothing to say about any of them. That is the third, fourth and fifth instance of what AC16 exists for.

## DONE this session (EOD fold, 2026-08-29 18:06Z)

Archived from the live board. What follows is finished work; the live board keeps only DOING, TODO and the standing cautions.

## WHERE THIS STANDS

**Nothing is blocked, and the browser question is closed.** hv authorised the run; every launch was headless against a scoped profile; hv's own Chrome was never touched. `utilz test` exits 0 across all 17 suites, acceptance is 12/0/0 with a real browser, and the numbers are recorded against ONE cold build (AC17's provenance seam closed).

**v2.5.0 is cut, green and pushed.** CI run `33265456630` passed all seven jobs. `HEAD`, `local/main`, `upstream/main` and the `v2.5.0` tag are all at `72ee931`; working tree clean.

**AC16 is hv's by construction** -- a human renders every theme and looks. vc prepares the renders; vc cannot be the eye. It is the only remaining item nobody else can take, and both of the day's runtime defects came from hv looking rather than from any red.

## State, verified not relayed

- **Pin `b600306`.** Landed as a MERGE via cc's `hoist-rebase.sh`, not a re-archive -- the crate is a FORK (AC14, AT13, AC18(b) exist only here). Its postcondition check is 16 items and asserts our work survived; a `tar -x` over the top goes red rather than reporting a clean merge.
- **Contract 20 ACs / 19 ATs / 7 WPs.** WP-01/02/03 Done. WP-04 (validation) mine and next. WP-05 default theme polish, WP-06 theme addressing split, WP-07 expose the determinism probe -- all after.
- **`intent doctor` 0 findings. `intent at lint ST0010` ok, 19 rows.** Gate **16/20**, read off the view -- `intent ac gate` cannot read it at all (see Watch-outs). Unsatisfied: AC15, AC16, AC18, AC19.
- cc reports 128 cargo tests, clippy clean, shellcheck clean across 16, acceptance 9 passed / 11 skipped under the browser override.
- **AC19 and AC20 spot-verified by me** at `f5253a9`: `--start-fullscreen` gone from the launch path, `--window` guarded to `present` and refusing in pixels, the Rust naming no platform, and ONE artifact carrying both `cmd-W` and `ctrl-W` chosen at view time. Ran the browserless probe myself: **37 passed, 0 failed, exit 0**. These are spot checks, NOT AT greens -- my artifact came from the warm dev tree and so fails AC17's provenance. Statuses left alone deliberately.

## WP-04, as run

Done, except where noted. Kept because the traps are what stop the next run repeating them, and because WP-04 still reads `Not Started` in the WP table -- the work happened, the status did not follow it.

- **AC17 was first and is DONE**, because it gates the meaning of everything after it: `rm -rf opt/prez/crate/target`, cold build at `b600306`, provenance recorded beside the numbers. `_tools-vc` has sent the literal procedure -- **use their line, not a parallel one**, so the two measurements are the same measurement taken twice.
- **The trap in it**, theirs, paid for: `_tools`' devbin `export`s `CARGO_TARGET_DIR` and overwrote their isolation, so a "cold" build ran warm, finished in 0.05s and reported exit 0. Whatever lever forces cold, **assert afterwards that it went cold** -- the artifact is where isolation put it, and the wall time is a release build's. cc found the same class here from the other end: the shim hardcoded `$CRATE_DIR/target` while cargo honoured the variable. Fixed; 8.50s now.
- Then `cargo test`, `acceptance.sh --strict`, the runtime probe, the legibility probe, the liftability refusal, the standalone greps. Walk ATs through red where the lifecycle requires.
- **`_tools-vc` is standing by to re-run our greens on their machine** against the cold-built binary; their numbers go beside ours. Send the exact command with the corrected map. Their figures: 10 ATs `--strict`, 0/0, exit 0, 69s. Contrast, flattened, floor 4.5: simple 6.0, **mono 4.9 nearest**, manuscript 5.7, contrast 14.2, blueprint 7.6, steampunk 5.5, 8bit 6.2, geodica 6.9.
- Then announce prez-green to `_tools-cc`: their trigger to land the `geodica present` client rewrite plus a `geodica doctor` check in ONE commit.
