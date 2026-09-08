---
node: vc
name: Validation Claude
role: validation
session_id: 06b406f0-9a29-4636-ad0d-abd6663e4f8f
heartbeat_at: 2026-09-08 12:03Z
status: active
focus: "Holding on hv. ST0013 closed, dehydrated and PUBLISHED; the install answers prez v2.0.0 on all three channels. Nothing claimed, nothing in flight, inboxes empty."
claims: []
---

# Validation Claude (vc)

Validation node; for ST0010 hv also gave vc the coordination pen. cc builds, vc contracts and verifies, hv adjudicates. Two sessions archived in `.history/20260829/` -- read that before concluding anything is new.

Released at EOD on hv's instruction, 7 Sep. Folds archived in `.history/20260829/` and `.history/20260907/` -- read those before concluding anything here is new.

**EVERY SHA ON THIS BOARD IS POST-REWRITE.** `main` was rewritten and force-pushed at 16:45Z on hv's instruction, to strip a `Claude-Session` trailer the harness had injected into ten devbin commits. Only commit messages changed -- HEAD tree `da1a98f` before and after, 50 commits both sides, tags untouched. cc mapped the orphans and I have applied the mapping here rather than leaving dead hashes to be chased. **Reachability from `main` is the test for whether a SHA survived; `git cat-file -e` is not** -- the old objects are still in the object database via `backup/pre-scrub-20260907`, so an existence check returns a false green for every orphan. cc got that wrong first and said so.

## DOING

**Nothing. Holding on hv's instruction, 2026-09-08 12:02Z.** Folded after ST0013 closed, dehydrated and published. Status stays `active` -- a fold is not a session end.

## TODO

- **Push.** 37 commits unpushed on both `local` and `upstream` at fold time. hv's.
- **Issue 0011** -- `install_guards.bats:267` reads a live `git rev-parse HEAD` against a fixture-time install, so a concurrent commit reddens it for the wrong reason. Open, one-line fix, unclaimed.
- **The closed-thread evidence gap**, in cc's framing which beat mine: **the mechanism that would catch a closed thread's evidence going stale is the same one that catches a green AT citing a file that no longer contains the test. There is a gate for the live case and none for the closed one.** Three instances now -- `hoist-rebase.sh:205`, ST0010/AT05+AT08, and issue 0011. **cc's cheap version is one grep at dehydration time**, which they ran by hand when dehydrating ST0013; nothing runs it automatically. Intent's, via `intent-vc`.
- **101 flat AC/AT ids** -- still blocked on a missing rename verb at CLI and facade level. Offer to migrate ours stands with `intent-vc`.
- **`version_file` exists twice in the estate, and devbin got there first.** `bin/.devbin/lib/config.reference.yaml:72-75` documents "names the FILE, never how to parse it -- devbin knows how to read a version out of VERSION, mix.exs, Cargo.toml, package.json and a plist". Utilz reinvented that this afternoon in `get_util_metadata`. Not a Highlander violation (different tools, different repos) and **not raised with hv yet** -- worth a look before a third tool grows a third copy.

## Claims

- **None.**

## Holds

- **The `intent ingest` damage probe stays unrun until `intent-vc` says the issue `0133` tiebreak has landed.** Utilz's exposure is **UNMEASURED, which is not zero**. The bound that holds: nothing here went through legacy ingest, everything went through `intent at new` on the API gate.

## Open with hv

- **AC16 on ST0010 -- hv's eye, and the only item nobody else can take.** A human renders every built-in prez theme and looks; the suite is not allowed to stand in for it.
- **`hoist-rebase.sh:205` and the `class 'escape'` warning**, both routed to me by cc 8 Sep and both genuinely hv's: the first needs a re-attach into a CLOSED, dehydrated thread's canon, and the second needs an issue or a deliberate acceptance rather than a record left inside a cancellation.

## Live with other nodes

- **`cc`: idle, nothing claimed, inbox empty and archived.** ST0013 ran end to end today with the split holding: cc built, I held the contract and verified by running rather than reading.
- **`geodica`: migrated and verified.** Byte-identical sha1 on a real client deck. Their one bug was their own shim injecting `--theme=geodica` underneath a user's `--theme-file`; the new mutual-exclusion refusal caught it.
- **`intent-vc`: six defects relayed, one-digit ruling delivered and landed.** The flat-125 offer is outstanding.

## Watch-outs

- **A COST ASSERTED AS "ACCEPTED" IS STILL AN UNMEASURED CLAIM, AND WRITING "ACCEPTED" NEXT TO IT DOES NOT MEASURE IT.** 8 Sep, mine, in AC04. I wrote that `acceptance.sh`'s AT13 asserts the provenance wording, so ST0010's frozen suite would be edited a SECOND time -- as settled fact, in a criterion, without running it. **cc measured instead of editing on my prediction: `acceptance.sh` is byte-unchanged and AT13 PASSES.** Every AT13 leg is the ENV case, where the old wording stays exactly true. **The clause is corrected ON THE ROW rather than deleted, because as written it would have LICENSED AN EDIT TO A CLOSED THREAD'S EVIDENCE THAT NOTHING REQUIRED** -- hours after I took that exact hazard to hv as a pattern. **Second time today a prediction of mine about an artefact was wrong where reading the artefact would have settled it** (the `src/` hold was the first). Same shape both times: reasoning from what I expected a file to say.

- **A CONTROL THAT GOES RED DURING THE RED-FIRST REVERT WAS NEVER A CONTROL.** cc's result on AT09, 8 Sep, and it is the cleanest statement of what leg 4 is for. Reverting `provenance()` to its single-string form produced 6 failures and **the control legs stayed green through both directions** -- they describe behaviour that was already correct, so they catch a fix that OVER-corrects rather than one that under-corrects.

- **A HOLD IS GOVERNED BY ITS CONDITION, NOT BY WHOEVER LAST MENTIONED IT -- and a stale re-announcement cannot re-impose a condition already met.** cc's rule, 8 Sep, applied against me and correct. I set the `src/` hold to lift when geodica answered, relayed that answer at 10:10Z, minted AC02 out of it, then **re-imposed the hold twice across a compact** because I reconstructed it from CC'S board, which still said held because they had not folded yet. My own sent entry was the primary source and said the opposite. **This is the AC02 error in a different costume: a secondary reading trusted over the artefact.** After any compact, the state of anything I announced is read from what I SENT, never from a peer's rendering of it. cc resolved the contradiction correctly and unblocked themselves; had they deferred to my later word they would have sat idle on a condition that was met an hour earlier.

- **A DISCOVERY CONVENTION WITH ONE MEMBER IS CORRECT BY ACCIDENT, AND THE ACCIDENT ENDS THE DAY SOMETHING ADDS THE SECOND.** cc's finding, 8 Sep. Both drivers hardcoded `test/acceptance.sh` and were right for a year because prez had exactly one suite; the moment my id-collision ruling created a second, the guard at `common.sh:919-923` -- which exists precisely to refuse a suite that silently does not run -- became structurally blind, because **a guard can only guard the filename it names**. **The general form: before moving a test to a new path, name the thing that will RUN it.** I ruled the move and did not ask that question; cc asked it before writing a line.

- **A FIXTURE WHOSE CASES ALL EXIST CANNOT TEST A RULE THAT TRIGGERS ON SHAPE.** cc's finding, 8 Sep. AT02 leg 2 exercised `--theme <path>` in "either shape" and both shapes EXISTED, while AC01 clause (e) makes a value a path by its SEPARATOR rather than by its existence -- so the likelier keystroke, a mistyped path, was covered by nothing and would have been handed the built-in roster. **The general form: when a criterion says a property decides, check that no fixture quietly supplies that property to every case.** The one I keep re-learning next to it -- a test that only fails against the CURRENT binary does not constrain the implementation about to replace it.

- **A PEER'S STALE BOARD IS EVIDENCE ABOUT THE BOARD AND NOTHING ELSE.** 7 Sep: I read cc's heartbeat at `18:28Z` and their focus naming forks already ruled, and reported them dormant to hv, who reversed a work assignment on it. cc had design attached, five WPs minted, and an announcement sitting in MY inbox that I had not read. **Check the inbox before diagnosing the peer, and check the artefact before diagnosing either** -- `intent wp list` and `ls intent/st/<ID>/` would each have shown it in one command. The write-versus-delivery rule I already carry has a second half: verifying that my writes land says nothing about whether theirs have arrived.
- **`sync --to-disk` does NOT re-derive an authored attachment, and `st attach` overwrites canon silently.** Two nodes attaching the same `design.md` leaves canon holding one and disk holding the other, with every command reporting ok. `intent doctor` catches it as `attachment-drift`; nothing else does. Its remedy is right and worth following exactly: copy BOTH sides outside the project first, because nothing can re-derive either.

- **THE BROWSER GATE IS AN ENV VAR AND THE SILENT PATH IS THE ONE THAT LAUNCHES CHROME.** `chrome()` says why it refuses and says nothing when it resolves, so `utilz test prez` gives 12/0/0 or 9-passed-11-skipped on the same tree depending only on whether `PREZ_TEST_BROWSER` survived into that shell -- and the output names neither. cc found it at EOD by getting a different answer to the morning's identical command. **Every acceptance figure I quote from here on cites the shell and whether the override landed**, the same way contrast figures cite selector + palette + commit. Reported by cc; the asymmetry is mine: the loud half is the harmless half.

- **`intent ac gate` / `ac status` CANNOT READ A v3 CONTRACT ON A SHELL-DISPATCHED `intent`, AND THE REMEDY IT PRINTS IS A TRAP.** `bin/intent_acceptance:295` greps the v2 dotted form (`^- AC-<st>.<nn> `); the v3 renderer emits `^- AC<nn> `. Zero matches, so a full contract reports `0/0 -- BLOCKED`. It fails SAFE, but **its printed remedy is `acceptance: exempt`, which converts a false red into a permanent real silent pass** -- do not take it. **This machine resolves `intent` to the native binary and is CORRECT**; a fresh checkout with no native build still takes the bash path. Read satisfaction off the view instead. Intent's tree, not ours.

- **AN EXTERNAL SUITE ASSERTS ON OUR BUILT-IN THEMES, AND WE CANNOT SEE IT FIRE.** Gtools' AC12 renders a deck under every built-in prez declares and asserts the artifact carries no hex from their brand palette -- nine values we must not hold, because hv's zero-knowledge rule makes that check structurally impossible on our side. The coupling is forced, not chosen. **If a future Utilz built-in happens to use one of those nine hexes, THEIR suite goes red and we will have done nothing wrong.** Ruled 2026-08-29, keep it: from an artifact a coincidence is indistinguishable from a brand compiled in, and the remedy is a conversation rather than a code change. What they carry in exchange is the red's WORDING -- it must name the coincidence case, or it sends a reader to "fix" a legitimate upstream theme -- plus the cheaper refusal check beside it. Currently clean: seven built-ins, zero hexes each, measured by them. Disclosed by `_tools-cc` rather than discovered.

- **A ZERO FROM AN INSTRUMENT YOU HAVE NEVER SEEN RETURN NON-ZERO IS NOT A MEASUREMENT.** My board read "gate 0/20 BLOCKED, which is correct" for most of a day; it was not correct, it was unreadable, and a broken reader returning zero is indistinguishable from a true zero at exactly the moment a validation node first looks. Make one row green by hand-check first, then believe the counter.
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

- (2026-09-08) **AC03 STAYS IN ST0013 -- hv's ruling, and the reason generalises.** It widened a prez theming thread into estate-wide test-driver work: both drivers discovering every suite in `crate/test/` rather than one hardcoded filename. **The work has no independent motivation** -- it exists only because ST0013's own six ATs would otherwise have been run by nothing -- so a separate thread would have opened already satisfied and closed the same hour, documenting a decision rather than tracking work. **`intent ac descope` is for a requirement that moved to other WORK, not for retroactive filing.** The cost accepted, explicitly: an estate-wide driver change is findable only inside a prez thread, and **there is no title-amend verb** (`st edit` prints a path; the title is canon), so the badge cannot be cheaply relabelled. **The general form: a thread's cost of PROOF belongs to that thread, even when the proof is built somewhere the title does not name.**

- (2026-09-07) **THE VARIABLE IS NOT THE DEFECT; THE SILENCE IS.** Ruled with the pen on AC15, against my own prior recommendation. `UTILZ_HOME` is load-bearing as a SETTABLE variable in five places -- `test_helper.bash:20` for the whole bats suite, `prez.bats:132` as a deliberate foreign-tree run, `common_lib.bats:71`, the documented `e2e-smoke.el` path, and cc's own `install.sh:124` reading a foreign tree's yaml in a subshell. So the dispatcher derives its own home from `$0` always, ANNOUNCES a divergence with an inherited value, and HONOURS the inherited value. **The general form: when a capability is silent in the failing case and load-bearing in the working ones, remove the silence rather than the capability.** Two dispatchers was rejected as a Highlander violation on the one file that must have exactly one answer -- cc flagged that risk and the flag is what killed the option.
- (2026-09-07) **A FIXTURE HAS THE SHAPE ITS AUTHOR IMAGINED, SO AN ENUMERATION IS TESTED AGAINST THE REAL TREE.** cc's, `install_lib.bats:4-7`, and it beat the ruling I was about to make on cost grounds. The defect the owned-set tests exist to catch is an enumeration matching the imagined shape rather than the real one -- which is the inclusion-list bug cc found this evening -- so a synthetic fixture would have reproduced the bug inside the test. Cheap `git init` trees for the refusal paths, the real tree for the enumeration. **The general form: a test fixture cannot catch a defect whose mechanism is the author's own model of the thing.**
- (2026-09-07) **NEVER IMPLICITLY, ALWAYS AVAILABLE EXPLICITLY.** AC11 and AC16 are one policy from two sides, and AC16 is a SEPARATE VERB rather than a flag on install: **a `--relink` flag becomes habitual, and a habitual flag is implicit by habit**, which is the thing AC11 forbids. Shell-init in devbin's shape was rejected because devbin has one entry point reached by absolute path and that does not transfer to sixteen, and because PATH-order resolution makes which-tree-answers depend on shell state -- the defect AC15 exists to remove. Doing nothing was rejected: a manual sixteen-link step with no record is rediscovered as a bug rather than a decision.

- (2026-08-29) **A tag may be moved off a red release commit onto the green commit that fixes only the harness.** `v2.5.0` was cut at `4b6eb07`, whose CI was red; the three fixes after it touch `acceptance.sh`, the workflow and the contract, and change nothing a user can run. Moved to `72ee931` and force-pushed both remotes, so the tag names a build that is green. The limit is the reason: had any commit in between touched `src/` or `bin/`, the honest move is a new tag, not a moved one. hv can reverse it.

- (2026-08-29) **Two checks measuring the same PROPERTY by different mechanisms are duplication; two measuring DIFFERENT properties are not.** So AT01+AT10 both cover AC11 (build-produces-nothing-tracked vs the-ignore-rule-is-committed) and AT04+AT17 both cover AC04 (a real browser vs the dispatch table). Both pairs say so on the row, so neither is tidied away.
- (2026-08-29) **Delete the second home rather than check it.** The deck rosters went, rather than gaining a prose-vs-table comparison that would have been brittle enough to false-red -- and a false red is the more expensive direction, because it sends a peer to disprove it and spends the credibility the next finding needs.
- (2026-08-29) **A criterion pins properties, not enumerations.** AC04 lists no keys; it names BINDINGS as the one roster and pins four structural facts about it.
- (2026-08-29) **No fallback message names as its remedy the case in which it fired** (AC20b). The general form of hv's `q` finding, and the checkable one.
- (2026-08-29) **A platform-dependent string in a portable artifact resolves when the deck is VIEWED, never when it is built** (AC20d). Whoever sees the wrong text is never whoever built the deck.
- (2026-08-29) **The freeze protects utilz-cc from drift; it does not make the pin sacred.** Same rule, opposite answers, and the axis is in the facts: harming and testable where it lives -> patch there; invisible and untestable there -> fix here.
