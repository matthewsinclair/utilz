---
node: vc
name: Validation Claude
role: validation
session_id: 06b406f0-9a29-4636-ad0d-abd6663e4f8f
heartbeat_at: 2026-09-07 16:22Z
status: active
focus: "CI fix at 035e9e2 AWAITING hv's PUSH -- run 34142119571 was red on three jobs. AT20 needs a display (Xvfb added to the Linux leg) and a window size is clamped to the screen (probe now reads it); shellcheck SC2016 in opt/todo/todo was a false positive, disabled by id. Local: acceptance 14/0/0, shellcheck 17 clean. The Xvfb path is UNVERIFIED until CI runs it."
claims: [ST0012, ST0013]
---

# Validation Claude (vc)

Validation node; for ST0010 hv also gave vc the coordination pen. cc builds, vc contracts and verifies, hv adjudicates. Two sessions archived in `.history/20260829/` -- read that before concluding anything is new.

Released at EOD on hv's instruction. Two folds archived in `.history/20260829/` -- read that before concluding anything here is new.

## DOING

**CI fix committed at `035e9e2`, awaiting hv's push.** Run `34142119571` went red on three jobs after the ST0010 work landed.

- **AT20 needs a real display; Ubuntu CI has none.** It is the only non-headless check in the suite, so Chrome opened nothing and a correct build reported "the presenting window never opened its debugging port". AT20 now detects and skips saying so, AND the Linux job gets **Xvfb** so it actually runs -- a skip alone reddens `--strict`, and excluding it would leave the one AT needing a window as the one AT CI never runs.
- **A THIRD QUALIFIER ON AC19, found by macOS CI: a requested size is CLAMPED TO THE DISPLAY.** It asked 1280x720 and got 1024x677, the runner's work area. The probe reads `screen.availWidth/availHeight` now and expects the request or the screen, whichever is smaller; the aspect assertion is skipped FOR CAUSE when clamped, because a clamped window carries the screen's proportions and asserting the deck's would test the monitor. **AC19's geometry is now: cold-start only, clamped to the display, honoured as a request.**
- **shellcheck SC2016 at `opt/todo/todo:249` was a false positive** -- literal backticks inside a printf FORMAT string, where single quotes are correct. Disabled by id with the reason. Not mine: `b650a77` landed at 16:52, after the run in which I measured that collector clean, so restart.md's "17 files and is clean" was true when written and stale when pushed.

**THE XVFB PATH IS UNVERIFIED** and cannot be exercised from macOS. It only proves itself on the next CI run.

## Claims

- **ST0012** -- the estate's dehydration preconditions. 4/4 PASS. Open because the policy is standing, not because work is outstanding.
- **ST0013** -- prez theme addressing (`--theme` / `--theme-file` / `--theme-path`). 0/1. AT01 is to-write and genuinely red-first. **Not started, and it is a BREAKING change to `prez present <deck> --theme <path>`, which is in hv's shell history.**

## Open with hv

- **AC16**, hv's eye. The only remaining item nobody else can take.
- **`geodica doctor` must report whether `utilz prez` is available** -- hv's estate requirement, still on no contract anywhere. Carried since 13:36Z; the estate has since moved to `~/Devel/prj/Gtools`, which does not retire it.
- **The `intent ac gate` false red** (Watch-outs) still needs relaying to `intent-vc`, with the qualifier that it is **bypassed here, not fixed**: this machine's `intent` is the native binary and reads the contract correctly. Re-verified 7 Sep that `Intent/bin/intent_acceptance:295` still greps the v2 dotted form, so a machine with no native build is unchanged. Intent's tree; nothing here should be edited to accommodate it.

Retired since the last board, each verified against the artefact rather than taken on report: the browser authorisation (given, run, green); the 41 unpushed commits (pushed); the 2.5.0 release; and **the `v2.5.0` tag move** -- the tag object `0ba1c2c` resolves to `4b6eb07`, the release commit, on both remotes, so the standing directive is satisfied and the item is off my board and off `intent/wip.md`. One commit is unpushed today (`0ab1ac2`, devbin re-vendor); pushing is yours.

## Live with other nodes

- **RETIRED 7 Sep: the Gtools cutover landed, and the completion check I set is met.** `git grep GEOPRES_THEME_PATH` returns zero live-code hits in both repos -- the only survivors either side are ST docs, canon and whiteboard history, which are the record of the change rather than the change. Verified in their tree, not taken on report: `bin/geodica_present` sets `PREZ_THEME_PATH` (lines 64, 110), the estate theme dir is `themes/prez/geodica/`, and `bin/geodica_design` and `bin/help/geodica_present.md` are consistent. The seam neither suite could see is closed.
- **Ruled and closed: no deprecated `GEOPRES_THEME_PATH` fallback.** It would silence the one tripwire of three that works, to protect an ordering a grep enforces for free. `_tools-vc` accepted and added the better argument: "for one release" requires someone to remove it and nobody ever does.
- **`intent-vc`: do NOT re-run the ingest damage probe until they say the tiebreak has landed.** Utilz's exposure to issue `0133` is **UNMEASURED, which is not zero**. The bound that still holds: nothing here went through legacy ingest -- `intent at new` through the API gate and `sync --to-disk` only, no `sync --to-store` -- so whatever exposure exists came from the original hop and has not grown.

## Watch-outs

- **THE BROWSER GATE IS AN ENV VAR AND THE SILENT PATH IS THE ONE THAT LAUNCHES CHROME.** `chrome()` says why it refuses and says nothing when it resolves, so `utilz test prez` gives 12/0/0 or 9-passed-11-skipped on the same tree depending only on whether `PREZ_TEST_BROWSER` survived into that shell -- and the output names neither. cc found it at EOD by getting a different answer to the morning's identical command. **Every acceptance figure I quote from here on cites the shell and whether the override landed**, the same way contrast figures cite selector + palette + commit. Reported by cc; the asymmetry is mine: the loud half is the harmless half.

- **cc's EOD numbers are NOT greens and I have not recorded them as such.** 17/17 and acceptance 12/0/0, off the warm dev tree. cc said so themselves before I could. My own 12/0/0 stands separately because it was taken against the cold build at `fdf161a` -- same figure, different provenance, and by AC17's own sequencing the provenance is what makes it mean anything. Do not let the two merge on a later read.

- **`intent ac gate` AND `intent ac status` CANNOT READ A v3-RENDERED CONTRACT -- ON A SHELL-DISPATCHED `intent`. THIS MACHINE IS NO LONGER ONE.** Re-measured 7 Sep: `intent` resolves to `Intent/native/rust/target/release/intent`, and both verbs are correct here (`16/20, unsatisfied AC15 AC16 AC18 AC19`). The rest of this entry describes the bash path, which a fresh checkout with no native build still takes, and which `Intent/bin/intent_acceptance:295` still implements. `bin/intent_acceptance`'s `ac_lines()` greps `^- AC-<st>.<nn> ` (the v2 dotted form); the v3 renderer emits `^- AC<nn> `. Zero matches, so `ac gate ST0010` reports "acceptance.md has zero acceptance criteria (empty contract) -- BLOCKED" and `ac status` reports `0/0`, against a view carrying all 20 rows. No native binary is built on this machine, so `bin/intent` dispatches `ac` to that bash path unconditionally -- there is no second reader to disagree with it. **It fails SAFE (blocks, never a vacuous pass) but the remedy it prints is `acceptance: exempt`**, which would convert a false red into a permanent real silent pass on a thread that has a full contract. Do not take that remedy. **Read satisfaction off the view instead**: `grep -oE '^- AC[0-9]+ .*-- satisfied: [a-z]+' intent/st/ST0010/acceptance.md` -- 16 yes, 4 no (AC15, AC16, AC18, AC19) at `72ee931`. Intent's tree, not ours: `intent-vc`'s to file, via hv.

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

---

# Snapshot: localfold 2026-09-07 20:59Z (evening, after the ST0014 handover)

---

node: vc
name: Validation Claude
role: validation
session_id: 06b406f0-9a29-4636-ad0d-abd6663e4f8f
heartbeat_at: 2026-09-07 20:57Z
status: active
focus: "ST0014 -- contract and verification ONLY. hv ruled the build mine at ~20:45Z on my report that cc was dormant; that report was WRONG (cc had design.md attached and WP-01..05 minted, and had announced it in my inbox before I started), and hv has reversed at 20:57Z. cc builds. AC01-AC13 minted and ruled, doctor 0 findings, no source code from either node. My next act on this thread is verifying AC01 against the artefact, not writing it."
claims: [ST0012, ST0013]
---

# Validation Claude (vc)

Validation node; for ST0010 hv also gave vc the coordination pen. cc builds, vc contracts and verifies, hv adjudicates. Two sessions archived in `.history/20260829/` -- read that before concluding anything is new.

Released at EOD on hv's instruction, 7 Sep. Folds archived in `.history/20260829/` and `.history/20260907/` -- read those before concluding anything here is new.

**EVERY SHA ON THIS BOARD IS POST-REWRITE.** `main` was rewritten and force-pushed at 16:45Z on hv's instruction, to strip a `Claude-Session` trailer the harness had injected into ten devbin commits. Only commit messages changed -- HEAD tree `da1a98f` before and after, 50 commits both sides, tags untouched. cc mapped the orphans and I have applied the mapping here rather than leaving dead hashes to be chased. **Reachability from `main` is the test for whether a SHA survived; `git cat-file -e` is not** -- the old objects are still in the object database via `backup/pre-scrub-20260907`, so an existence check returns a false green for every orphan. cc got that wrong first and said so.

## DOING

**ST0014 -- I hold the CONTRACT and VERIFICATION. cc holds `design.md` and the BUILD.** That was the original split, it was briefly reversed on bad evidence I supplied, and hv restored it at 20:57Z. AC01-AC13 minted with all three forks ruled; `intent doctor` 0 findings; contract 0/13 BLOCKED with every row decided; **no source code exists from either node.**

**I REPORTED A PEER AS DORMANT AND HE WAS WORKING. THIS IS THE ENTRY THAT MATTERS.** At ~20:45Z hv asked why cc was blocked. I read cc's board (heartbeat `18:28Z`, focus still naming the forks) and concluded they had never read the 18:30/18:38Z rulings. **They had.** `design.md` was written and attached and `WP-01..05` minted, and they had announced the canon write in my inbox at **20:49Z** -- four entries above the one I was replying to. I wrote at 20:52Z without reading it. hv reversed the ruling on my report and then had to reverse it back.

**The failure is one thing, not two, and it points both ways: I verified that my writes had landed and never checked whether one had arrived for me.** I had described that exact asymmetry to cc minutes earlier and then committed the other half of it. A stale peer board is EVIDENCE OF NOTHING ABOUT WHETHER A PEER IS WORKING -- it is evidence only about the board.

**And cc's diagnosis of the original block beat mine, so cc's is the one recorded.** I said their board was stale and that I had reported them unblocked on a write rather than a delivery. The write-versus-delivery rule stands on its own and I keep it. But they were never blocked: the AC ids were not a prerequisite for a document that carries HOW and cites rows. **They manufactured the dependency and reported it as external, and a fresher heartbeat would not have prevented that.** "cc's board was stale" is a fix that changes nothing, and I would have shipped it as the finding.

**I also caused `attachment-drift` and did not notice until doctor said so.** My `st attach` put my 9425-byte `design.md` into canon while cc's 13947-byte file stayed on disk, because `--to-disk` does not re-derive an AUTHORED attachment. Repaired by copying BOTH outside the project first -- nothing can re-derive either side -- then re-attaching cc's. My six duplicate WPs are Cancelled.

**THE STRONGEST EVIDENCE THAT THE REVERSAL IS CORRECT IS AGAINST ME.** My draft's AC05 guard was `[[ -n "$v" ]] || refuse`. cc measured that `get_util_metadata` ends in `echo "$result"` and `yq` prints the literal string `null` for an absent key -- **so that guard passes on unset and publishes to a directory called `./null`.** I wrote the criterion about unreadable answers arriving as valid-looking values, and then wrote precisely that defect into its implementation. Mine argued from devbin's design; cc's measured ours. The method is the difference, not the effort.

**AC06 gained cc's dispatch-predicate finding** -- `bin/utilz:183` gates on `-L`, so a symlink that did not arrive means the utility does not dispatch AND the error path offers it as a typo. Contract work, so I took it; their other three findings are design and stayed in their document.

**Next act on this thread is verifying AC01 against the artefact** -- the install running with the source tree moved aside -- not writing it.

## Claims

- **ST0012** -- the estate's dehydration preconditions. 4/4 PASS. Open because the policy is standing, not because work is outstanding.
- **ST0013** -- prez theme addressing (`--theme` / `--theme-file` / `--theme-path`). 0/1. AT01 is to-write and genuinely red-first. **Not started, and it is a BREAKING change to `prez present <deck> --theme <path>`, which is in hv's shell history.**

## Open with hv

- **AC16**, hv's eye. The only remaining item nobody else can take.
- **`geodica doctor` must report whether `utilz prez` is available** -- hv's estate requirement, still on no contract anywhere. Carried since 13:36Z; the estate has since moved to `~/Devel/prj/Gtools`, which does not retire it.
- **NEW, and the third for the same relay: there is NO VERB that sets `objective` or `context` on an EXISTING thread.** `intent st edit <id>` prints the path to `info.md`, a GENERATED VIEW whose own footer forbids editing it, and doctor then reports `view-skew` and offers to discard the text. `sync --to-store` is add-only, and `sync --to-disk` after a canon edit silently destroys it. The only working path is `intent ingest`. **So the documented way in hands you a file you are told not to edit, and the working way in is the surface we have been asked not to touch.** Filed 7 Sep on hv's ruling; goes to `intent-vc` with the two AC-id defects.
- **The `intent ac gate` false red** (Watch-outs) still needs relaying to `intent-vc`, with the qualifier that it is **bypassed here, not fixed**: this machine's `intent` is the native binary and reads the contract correctly. Re-verified 7 Sep that `Intent/bin/intent_acceptance:295` still greps the v2 dotted form, so a machine with no native build is unchanged. Intent's tree; nothing here should be edited to accommodate it.

Retired since the last board, each verified against the artefact rather than taken on report: the browser authorisation (given, run, green); the 41 unpushed commits (pushed); the 2.5.0 release; and **the `v2.5.0` tag move** -- the tag object `0ba1c2c` resolves to `4b6eb07`, the release commit, on both remotes, so the standing directive is satisfied and the item is off my board and off `intent/wip.md`. The devbin re-vendor went up with the rewritten range as `5d99764` (was `0ab1ac2`). **Unpushed at 18:30Z: cc's briefing, my EOD fold and release, and the ST0014 contract. Pushing is yours.**

## Live with other nodes

- **RETIRED 7 Sep: the Gtools cutover landed, and the completion check I set is met.** `git grep GEOPRES_THEME_PATH` returns zero live-code hits in both repos -- the only survivors either side are ST docs, canon and whiteboard history, which are the record of the change rather than the change. Verified in their tree, not taken on report: `bin/geodica_present` sets `PREZ_THEME_PATH` (lines 64, 110), the estate theme dir is `themes/prez/geodica/`, and `bin/geodica_design` and `bin/help/geodica_present.md` are consistent. The seam neither suite could see is closed.
- **Ruled and closed: no deprecated `GEOPRES_THEME_PATH` fallback.** It would silence the one tripwire of three that works, to protect an ordering a grep enforces for free. `_tools-vc` accepted and added the better argument: "for one release" requires someone to remove it and nobody ever does.
- **`intent-vc`: do NOT re-run the ingest damage probe until they say the tiebreak has landed.** Utilz's exposure to issue `0133` is **UNMEASURED, which is not zero**. The bound that still holds: nothing here went through legacy ingest -- `intent at new` through the API gate. **CORRECTED 7 Sep 18:28Z: this read `and sync --to-disk only, no sync --to-store`, and I ran `--to-store` twice at 18:26Z.** Both were no-ops that overwrote nothing, so the exposure argument is unchanged, but the sentence was false as written -- so whatever exposure exists came from the original hop and has not grown.

## Watch-outs

- **A PEER'S STALE BOARD IS EVIDENCE ABOUT THE BOARD AND NOTHING ELSE.** 7 Sep: I read cc's heartbeat at `18:28Z` and their focus naming forks already ruled, and reported them dormant to hv, who reversed a work assignment on it. cc had design attached, five WPs minted, and an announcement sitting in MY inbox that I had not read. **Check the inbox before diagnosing the peer, and check the artefact before diagnosing either** -- `intent wp list` and `ls intent/st/<ID>/` would each have shown it in one command. The write-versus-delivery rule I already carry has a second half: verifying that my writes land says nothing about whether theirs have arrived.
- **`sync --to-disk` does NOT re-derive an authored attachment, and `st attach` overwrites canon silently.** Two nodes attaching the same `design.md` leaves canon holding one and disk holding the other, with every command reporting ok. `intent doctor` catches it as `attachment-drift`; nothing else does. Its remedy is right and worth following exactly: copy BOTH sides outside the project first, because nothing can re-derive either.

- **THE BROWSER GATE IS AN ENV VAR AND THE SILENT PATH IS THE ONE THAT LAUNCHES CHROME.** `chrome()` says why it refuses and says nothing when it resolves, so `utilz test prez` gives 12/0/0 or 9-passed-11-skipped on the same tree depending only on whether `PREZ_TEST_BROWSER` survived into that shell -- and the output names neither. cc found it at EOD by getting a different answer to the morning's identical command. **Every acceptance figure I quote from here on cites the shell and whether the override landed**, the same way contrast figures cite selector + palette + commit. Reported by cc; the asymmetry is mine: the loud half is the harmless half.

- **cc's EOD numbers are NOT greens and I have not recorded them as such.** 17/17 and acceptance 12/0/0, off the warm dev tree. cc said so themselves before I could. My own 12/0/0 stands separately because it was taken against the cold build at `fdf161a` -- same figure, different provenance, and by AC17's own sequencing the provenance is what makes it mean anything. Do not let the two merge on a later read.

- **`intent ac gate` AND `intent ac status` CANNOT READ A v3-RENDERED CONTRACT -- ON A SHELL-DISPATCHED `intent`. THIS MACHINE IS NO LONGER ONE.** Re-measured 7 Sep: `intent` resolves to `Intent/native/rust/target/release/intent`, and both verbs are correct here (`16/20, unsatisfied AC15 AC16 AC18 AC19`). The rest of this entry describes the bash path, which a fresh checkout with no native build still takes, and which `Intent/bin/intent_acceptance:295` still implements. `bin/intent_acceptance`'s `ac_lines()` greps `^- AC-<st>.<nn> ` (the v2 dotted form); the v3 renderer emits `^- AC<nn> `. Zero matches, so `ac gate ST0010` reports "acceptance.md has zero acceptance criteria (empty contract) -- BLOCKED" and `ac status` reports `0/0`, against a view carrying all 20 rows. No native binary is built on this machine, so `bin/intent` dispatches `ac` to that bash path unconditionally -- there is no second reader to disagree with it. **It fails SAFE (blocks, never a vacuous pass) but the remedy it prints is `acceptance: exempt`**, which would convert a false red into a permanent real silent pass on a thread that has a full contract. Do not take that remedy. **Read satisfaction off the view instead**: `grep -oE '^- AC[0-9]+ .*-- satisfied: [a-z]+' intent/st/ST0010/acceptance.md` -- 16 yes, 4 no (AC15, AC16, AC18, AC19) at `72ee931`. Intent's tree, not ours: `intent-vc`'s to file, via hv.

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
