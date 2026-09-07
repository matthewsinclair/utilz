---
node: vc
name: Validation Claude
role: validation
session_id: 06b406f0-9a29-4636-ad0d-abd6663e4f8f
heartbeat_at: 2026-09-07 18:30Z
status: active
focus: "ST0014 -- utilz installable into ~/Devel/opt/utilz with install + upgrade, like devbin. hv gave me the scoping half and cc the build half; cc had already picked the thread up, so the split is agreed in their inbox before either of us writes a plan. Reviewed devbin lib/cmd/{install,upgrade} + lib/install: the provenance machinery carries over, D33 INVERTS (utilz install must be runnable), and the Utilz-only problems devbin never had are symlinks, prez's Rust binary, and (cc's, which I missed) `utilz test` mutating an install it is run from. AC01-AC13 minted, 0/13 BLOCKED, doctor clean. Three forks up to hv."
claims: [ST0012, ST0013]
---

# Validation Claude (vc)

Validation node; for ST0010 hv also gave vc the coordination pen. cc builds, vc contracts and verifies, hv adjudicates. Two sessions archived in `.history/20260829/` -- read that before concluding anything is new.

Released at EOD on hv's instruction, 7 Sep. Folds archived in `.history/20260829/` and `.history/20260907/` -- read those before concluding anything here is new.

**EVERY SHA ON THIS BOARD IS POST-REWRITE.** `main` was rewritten and force-pushed at 16:45Z on hv's instruction, to strip a `Claude-Session` trailer the harness had injected into ten devbin commits. Only commit messages changed -- HEAD tree `da1a98f` before and after, 50 commits both sides, tags untouched. cc mapped the orphans and I have applied the mapping here rather than leaving dead hashes to be chased. **Reachability from `main` is the test for whether a SHA survived; `git cat-file -e` is not** -- the old objects are still in the object database via `backup/pre-scrub-20260907`, so an existence check returns a false green for every orphan. cc got that wrong first and said so.

## DOING

**ST0014 -- utilz installable into `~/Devel/opt/utilz`, with `install` and `upgrade`, modelled on devbin.** hv gave me the scoping half and cc the build half. cc had already picked the thread up at 18:21Z and was planning, so the split went into their inbox at 18:24Z BEFORE either of us wrote a plan: I take the contract, they take `design.md` and the build. Two plans for one thread is the cross-node form of the duplication we both police.

**Contract minted: AC01-AC13, rendered, `intent doctor` 0 findings.** `intent ac status ST0014` reads **0/13 BLOCKED** -- correct for an unstarted thread, and a non-zero denominator, so the reader is confirmed working before anyone believes a green off it.

**The devbin review, and the one line that matters most: D33 INVERTS.** Devbin's install tree is deliberately NOT RUNNABLE -- `bin/devbin` dies without a `config.yaml`, the install ships none, so it can only be vendored FROM. Ours must RUN; that is the whole ask. The provenance machinery carries over whole (dirty gate with no `--force`, refuse-into-a-source-tree, the install/upgrade mirror, prefix-is-configuration-with-no-default, the manifest that reports an edited file rather than replacing it). The not-runnable half must not be copied, and AC01 makes the inversion the actual test: the install must run with the SOURCE TREE MOVED ASIDE, because "files arrived" passes equally for a tree that silently reaches back into the checkout.

**Four problems are ours alone, because devbin's vendored set has never held a symlink or a build artefact and their install cannot run.** `bin/` is a dispatcher plus **fifteen** symlinks and two real files, and a manifest that checksums the RESOLVED file gives all fifteen the same hash, so a retargeted link reads as intact (AC06) -- **I said sixteen first; cc measured 15 and was right**, I had carried the count from `opt/`, which has sixteen entries because `utilz` sits there as the framework's own directory. prez's binary is git-ignored, so a git-derived owned set excludes 4.4MB the tool cannot run without, and prez is the ONLY utility with a build step -- measured across 16 dirs / 15 impl files, 1 hit (AC09). The PATH symlinks are hv's to move (AC11). **And cc's, which I missed and which belongs first: `utilz test` mutates `$UTILZ_HOME/bin`, so run from a runnable install it rewrites the very files the manifest checksums** and the install reports drift nobody caused (AC13). It is the only one of the forks where the wrong answer damages an install that was correct when written.

**THREE FORKS ARE hv'S AND ARE FLAGGED TO THEM, NOT PICKED BY ME**, in cc's order of damage:

1. **AC13 -- `utilz test` against a runnable install.** Refuse, or redirect the mutation. First because it is the only one where the wrong answer damages an install that was CORRECT when written, and a manifest reporting drift nobody caused discredits the manifest itself.
2. **AC09 -- ship crate source and build on first use, or build at publish and ship the binary.** cc and I both lean the latter and cc sharpened the reason: it is not arbitrary mtimes, it is COPY ORDER. `cp` stamps each destination as it writes, so under (a) whether a fresh install rebuilds itself is decided by whether the copier wrote `src/` before or after the binary -- deterministic per implementation, invisible in the output, and it flips on a reordering nobody would classify as behavioural. The install-tree shim must then REFUSE to build rather than fall back, or (a) returns through the back door on the first stale check.
3. **AC05 -- where `install.prefix` lives.** cc found `opt/utilz/utilz.yaml`, so utilz HAS a config of its own and the key need not borrow devbin's file. That improves the question rather than settling it: does framework INSTALL policy belong in the file that declares framework METADATA.

**ST0014's Objective and Context are EMPTY DELIBERATELY, and this is a finding rather than an omission.** `intent st edit ST0014` hands you `info.md`, which is a generated view whose footer says not to edit it; writing there produces `view-skew` and doctor offers to discard the text. There is no verb that sets objective or context on an EXISTING thread -- `sync --to-store` is add-only ("nothing the store already held was overwritten") -- and the one path that works is `intent ingest`, which is the surface `intent-vc` asked us not to exercise until their `0133` tiebreak lands. Text preserved in the session scratchpad; it goes in when hv says how.

**And I lost that prose once before saving it.** I wrote the canon extract and then ran `intent sync --to-disk`, which rewrote the extract FROM the store and silently discarded the edit; the next command then reported `nothing the store already held was overwritten`, which is true and reads like reassurance. **Two greens over a destroyed edit.** `--to-disk` after a canon edit is the wrong direction and says nothing about what it dropped.

## Claims

- **ST0012** -- the estate's dehydration preconditions. 4/4 PASS. Open because the policy is standing, not because work is outstanding.
- **ST0013** -- prez theme addressing (`--theme` / `--theme-file` / `--theme-path`). 0/1. AT01 is to-write and genuinely red-first. **Not started, and it is a BREAKING change to `prez present <deck> --theme <path>`, which is in hv's shell history.**

## Open with hv

- **AC16**, hv's eye. The only remaining item nobody else can take.
- **`geodica doctor` must report whether `utilz prez` is available** -- hv's estate requirement, still on no contract anywhere. Carried since 13:36Z; the estate has since moved to `~/Devel/prj/Gtools`, which does not retire it.
- **The `intent ac gate` false red** (Watch-outs) still needs relaying to `intent-vc`, with the qualifier that it is **bypassed here, not fixed**: this machine's `intent` is the native binary and reads the contract correctly. Re-verified 7 Sep that `Intent/bin/intent_acceptance:295` still greps the v2 dotted form, so a machine with no native build is unchanged. Intent's tree; nothing here should be edited to accommodate it.

Retired since the last board, each verified against the artefact rather than taken on report: the browser authorisation (given, run, green); the 41 unpushed commits (pushed); the 2.5.0 release; and **the `v2.5.0` tag move** -- the tag object `0ba1c2c` resolves to `4b6eb07`, the release commit, on both remotes, so the standing directive is satisfied and the item is off my board and off `intent/wip.md`. The devbin re-vendor went up with the rewritten range as `5d99764` (was `0ab1ac2`). **Unpushed at 18:30Z: cc's briefing, my EOD fold and release, and the ST0014 contract. Pushing is yours.**

## Live with other nodes

- **RETIRED 7 Sep: the Gtools cutover landed, and the completion check I set is met.** `git grep GEOPRES_THEME_PATH` returns zero live-code hits in both repos -- the only survivors either side are ST docs, canon and whiteboard history, which are the record of the change rather than the change. Verified in their tree, not taken on report: `bin/geodica_present` sets `PREZ_THEME_PATH` (lines 64, 110), the estate theme dir is `themes/prez/geodica/`, and `bin/geodica_design` and `bin/help/geodica_present.md` are consistent. The seam neither suite could see is closed.
- **Ruled and closed: no deprecated `GEOPRES_THEME_PATH` fallback.** It would silence the one tripwire of three that works, to protect an ordering a grep enforces for free. `_tools-vc` accepted and added the better argument: "for one release" requires someone to remove it and nobody ever does.
- **`intent-vc`: do NOT re-run the ingest damage probe until they say the tiebreak has landed.** Utilz's exposure to issue `0133` is **UNMEASURED, which is not zero**. The bound that still holds: nothing here went through legacy ingest -- `intent at new` through the API gate. **CORRECTED 7 Sep 18:28Z: this read `and sync --to-disk only, no sync --to-store`, and I ran `--to-store` twice at 18:26Z.** Both were no-ops that overwrote nothing, so the exposure argument is unchanged, but the sentence was false as written -- so whatever exposure exists came from the original hop and has not grown.

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
