---
node: vc
name: Validation Claude
role: validation
session_id: 06b406f0-9a29-4636-ad0d-abd6663e4f8f
heartbeat_at: 2026-09-07 21:13Z
status: active
focus: "ST0014 -- contract and verification only; cc builds. AC01-AC13 minted with all three forks ruled, doctor 0 findings, contract 0/13 BLOCKED with every row decided, no source code from either node yet. Next act on this thread is verifying AC01 against the artefact -- the install running with the source tree moved aside -- not writing it. Localfolded 20:59Z; status stays active, a compact is not a session end."
claims: [ST0012, ST0013]
---

# Validation Claude (vc)

Validation node; for ST0010 hv also gave vc the coordination pen. cc builds, vc contracts and verifies, hv adjudicates. Two sessions archived in `.history/20260829/` -- read that before concluding anything is new.

Released at EOD on hv's instruction, 7 Sep. Folds archived in `.history/20260829/` and `.history/20260907/` -- read those before concluding anything here is new.

**EVERY SHA ON THIS BOARD IS POST-REWRITE.** `main` was rewritten and force-pushed at 16:45Z on hv's instruction, to strip a `Claude-Session` trailer the harness had injected into ten devbin commits. Only commit messages changed -- HEAD tree `da1a98f` before and after, 50 commits both sides, tags untouched. cc mapped the orphans and I have applied the mapping here rather than leaving dead hashes to be chased. **Reachability from `main` is the test for whether a SHA survived; `git cat-file -e` is not** -- the old objects are still in the object database via `backup/pre-scrub-20260907`, so an existence check returns a false green for every orphan. cc got that wrong first and said so.

## DOING

**ST0014 -- I hold the CONTRACT and VERIFICATION; cc holds `design.md` and the BUILD.** The original split, briefly reversed on bad evidence I supplied, restored by hv at 20:57Z.

State, verified rather than described: **AC01-AC13 minted with all three forks ruled; `intent doctor` 0 findings; contract 0/13 BLOCKED with every row decided; cc's `design.md` canonical in both canon and disk; `WP-01..05` the only live set (my `WP-06..11` Cancelled); no source code from either node.** cc is told to go.

**AT01-AT13 minted 21:07Z, BEFORE cc writes WP-01**, so the thread is red-first rather than tested-after. `intent ac list ST0014` shows twelve of thirteen ACs covered; AC12 is the non-test row and is deliberately uncovered, its evidence being the prompt output at close. Gate is still `0/13 BLOCKED`, correctly -- every row is `to-write`. Five of the notes exist because the obvious test passes for the wrong reason: AT06's literal-`null` leg, AT07's target-string retarget, AT10's `CARGO_TARGET_DIR` leg, AT11 measuring the mode announcement as ORDERING rather than presence, AT08's commit-describes-the-shipped-bytes leg.

**The five test-file paths follow cc's WP split and I told them so in writing: the paths are theirs to re-cite, the ASSERTIONS are not.** That is the whole boundary between my half and theirs on this thread.

**AC14 AND AC15 WERE FOUND BY VERIFYING BEFORE THERE WAS ANYTHING TO VERIFY, WHICH IS THE ARGUMENT FOR DOING THE CONTRACT FIRST.** Contract now `0/15 BLOCKED`, doctor 0 findings.

- **AC15 is the serious one, and it is measured rather than reasoned.** `bin/utilz:42` derives `UTILZ_HOME` from `$0` ONLY when the variable is unset; `~/.zshrc:76-78` exports it unconditionally, read back out of `zsh -lc`. A hand-built prefix with a marker VERSION answers `vPREFIX-MARKER-9.9.9` unset and `v2.5.0` -- the CHECKOUT -- exported. **AC01 cannot catch it**: AC01 moves the source aside, where a stale `UTILZ_HOME` fails loudly instead of deferring quietly, so AC01 goes green in a clean bats env while the defect is live in hv's shell. The remedy is a three-way fork, it is cc's to rule in `design.md`, and one branch of it is hv's `.zshrc`. Both told, 21:13Z. **I stated the property and did not rule the mechanism.**
- **AC14**: `pdf2md` and `xtrct` build a venv at `opt/<n>/lib/.venv` on first run (`ensure_venv`, `common.sh:223`) -- inside the install, outside `git ls-files`. A used install carries files the manifest never recorded. AC13's shape with AC13's remedy unavailable, because those two running IS the install working.

**cc's D2 rewrite reproduces exactly on my side**: 109 tracked paths, 15 symlinks, 94 files, 43M, 42M of it `opt/macoz/images/`, same five utilities. Sharper figure I gave them: 22 paths an inclusion list would have dropped. `bin/devbin` excluded safely -- one reference in all 109, a comment at `opt/prez/prez:54`.

**I CORRECTED TWO OF MY OWN ROWS AGAINST cc'S WORK RATHER THAN DEFENDING THEM.** AT07 said "15 symlinks and 2 real files" as the ARRIVAL count; the exclusion makes the install's `bin/` 15 and one, and AC06 now says in the row that its count is of the SOURCE `bin/`. And AT06 gained a fourth leg after I nearly filed cc's literal-`null` finding as unreproducible -- **my probe passed `install.prefix` without the leading dot, which is not a yq path, so it returned empty.** With `.install.prefix` the finding is exact: the four-character string `null`, `[[ -n ]]` passes, a bare guard publishes to `./null`. Both the null and the empty case have to be refused; a guard written for one lets the other through. **The near-miss is the lesson: I was one malformed argument away from telling a peer their measured finding did not reproduce.**

**My next act on this thread is VERIFYING AC01 against the artefact** -- the install running with the source tree moved aside -- not writing it. An install that reaches back into the checkout passes everything that does not move the source.

Narrative of the 20:45-20:57Z collision is archived to `.history/20260907/`. What survives it are the two Watch-outs below, which are the only parts that change what anyone does next.

## Claims

- **ST0012** -- the estate's dehydration preconditions. 4/4 PASS. Open because the policy is standing, not because work is outstanding.
- **ST0013** -- prez theme addressing (`--theme` / `--theme-file` / `--theme-path`). 0/1. AT01 is to-write and genuinely red-first. **Not started, and it is a BREAKING change to `prez present <deck> --theme <path>`, which is in hv's shell history.**

## Open with hv

- **AC16**, hv's eye. The only remaining item nobody else can take.
- **`geodica doctor` must report whether `utilz prez` is available** -- hv's estate requirement, still on no contract anywhere. Carried since 13:36Z; the estate has since moved to `~/Devel/prj/Gtools`, which does not retire it.
- **NEW, and the third for the same relay: there is NO VERB that sets `objective` or `context` on an EXISTING thread.** `intent st edit <id>` prints the path to `info.md`, a GENERATED VIEW whose own footer forbids editing it, and doctor then reports `view-skew` and offers to discard the text. `sync --to-store` is add-only, and `sync --to-disk` after a canon edit silently destroys it. The only working path is `intent ingest`. **So the documented way in hands you a file you are told not to edit, and the working way in is the surface we have been asked not to touch.** Filed 7 Sep on hv's ruling; goes to `intent-vc` with the two AC-id defects.
- **NEW, and the FOURTH for the same relay: the rendered `acceptance.md` groups every AT under its OWN id, so a full contract reads as zero coverage.** Measured here at 21:07Z with thirteen ATs minted: all thirteen `### Group AC<nn>` sections under Acceptance Tests read `_(no tests in this group)_` while the rows sit in self-named `### Group AT<nn>` groups, and the phantom groups appear under Acceptance CRITERIA too, each reading `_(no criteria in this group)_`. **The MODEL is correct** -- `intent ac list ST0014` prints `AC01 covered-by: AT01` and so on -- and `intent doctor` is 0 findings, so nothing reports it. It fails in the direction that matters: a reader of the file concludes the contract is uncovered when it is fully covered.
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
