---
node: vc
name: Validation Claude
role: validation
session_id: 06b406f0-9a29-4636-ad0d-abd6663e4f8f
heartbeat_at: 2026-09-08 10:02Z
status: active
focus: "ST0013 -- cc builds, I hold the contract; cc is held off src/ until geodica answers on --theme pass-through. v2.6.1 shipped, CI green on all seven jobs, ST0014 and ST0012 closed and dehydrated, six Intent defects relayed and hv's one-digit ruling delivered. Localfolded for a compact; status stays active."
claims: [ST0012, ST0013]
---

# Validation Claude (vc)

Validation node; for ST0010 hv also gave vc the coordination pen. cc builds, vc contracts and verifies, hv adjudicates. Two sessions archived in `.history/20260829/` -- read that before concluding anything is new.

Released at EOD on hv's instruction, 7 Sep. Folds archived in `.history/20260829/` and `.history/20260907/` -- read those before concluding anything here is new.

**EVERY SHA ON THIS BOARD IS POST-REWRITE.** `main` was rewritten and force-pushed at 16:45Z on hv's instruction, to strip a `Claude-Session` trailer the harness had injected into ten devbin commits. Only commit messages changed -- HEAD tree `da1a98f` before and after, 50 commits both sides, tags untouched. cc mapped the orphans and I have applied the mapping here rather than leaving dead hashes to be chased. **Reachability from `main` is the test for whether a SHA survived; `git cat-file -e` is not** -- the old objects are still in the object database via `backup/pre-scrub-20260907`, so an existence check returns a false green for every orphan. cc got that wrong first and said so.

## DOING

**ST0013 -- prez theme addressing. cc BUILDS, I hold the CONTRACT.** Handed over 8 Sep on hv's instruction. Same split that worked on ST0014, and it is the only hydrated thread.

**cc is on HOLD for `src/` until `geodica` answers or a day passes.** Their `bin/geodica_present` forwards a user-supplied `--theme`, so a Geodica user passing a PATH starts getting the refusal; if that shape is in use the criterion may gain a clause, and it is cheaper to change now than after it is built. Their normal path is unaffected -- `--theme=geodica` is a NAME off `PREZ_THEME_PATH`, which is exactly what the new `--theme` keeps doing. Verified in their tree, not taken on report.

**AT01 must be RED FIRST and red for the right reason.** `--theme=NAME` resolving identically from two working directories, one holding a `./NAME/` directory. It is red against the pinned binary today because `path.exists()` wins. **If it is green before the split lands it is not testing what it says.**

**Clause (f) is the part that is easy to drop.** The refusal of a path given to `--theme` MUST name `--theme-file`, because whoever hits it is someone whose working command stopped working -- `prez present <deck> --theme <path>` is in hv's shell history against a real 14-slide client deck.

**My next act is minting the remaining ATs once cc's `design.md` names the files.** One AC and one AT exist; the AC is hv's own wording carried verbatim from ST0010/AC15, and a re-scope that reworded it would be a quiet renegotiation.

## Claims

- **ST0013** -- prez theme addressing. 0/1, cc building, contract mine.

## Holds

- **The `intent ingest` damage probe stays unrun until `intent-vc` says the issue `0133` tiebreak has landed.** Utilz's exposure is **UNMEASURED, which is not zero**. The bound that holds: nothing here went through legacy ingest, everything went through `intent at new` on the API gate. Corrected 7 Sep -- an earlier version of this claimed no `sync --to-store` had run and two had; both were no-ops that overwrote nothing, so the argument survives but the sentence was false as written.

## Open with hv

- **AC16 on ST0010 -- hv's eye, and the only item nobody else can take.** A human renders every built-in prez theme and looks; the suite is not allowed to stand in for it.
- **`hoist-rebase.sh:205` and the `class 'escape'` warning**, both routed to me by cc 8 Sep and both genuinely hv's: the first needs a re-attach into a CLOSED, dehydrated thread's canon, and the second needs an issue or a deliberate acceptance rather than a record left inside a cancellation.

## Live with other nodes

- **`geodica`: two asks sent 8 Sep, both awaiting reply.** hv's standing requirement that `geodica doctor` report whether `utilz prez` is available -- theirs by the zero-knowledge ruling, since a check naming their estate cannot live in our tree -- and the ST0013 `--theme` pass-through question above.
- **`intent-vc`: six defects relayed and hv's one-digit ruling delivered.** `is_ac_id` relaxes rather than 182 rows migrating. **The flat 125 remain bad data and 101 of them are OURS** -- I offered to migrate Utilz's own once their mint-side check lands, and that offer is outstanding.

## Watch-outs

- **A PEER'S STALE BOARD IS EVIDENCE ABOUT THE BOARD AND NOTHING ELSE.** 7 Sep: I read cc's heartbeat at `18:28Z` and their focus naming forks already ruled, and reported them dormant to hv, who reversed a work assignment on it. cc had design attached, five WPs minted, and an announcement sitting in MY inbox that I had not read. **Check the inbox before diagnosing the peer, and check the artefact before diagnosing either** -- `intent wp list` and `ls intent/st/<ID>/` would each have shown it in one command. The write-versus-delivery rule I already carry has a second half: verifying that my writes land says nothing about whether theirs have arrived.
- **`sync --to-disk` does NOT re-derive an authored attachment, and `st attach` overwrites canon silently.** Two nodes attaching the same `design.md` leaves canon holding one and disk holding the other, with every command reporting ok. `intent doctor` catches it as `attachment-drift`; nothing else does. Its remedy is right and worth following exactly: copy BOTH sides outside the project first, because nothing can re-derive either.

- **THE BROWSER GATE IS AN ENV VAR AND THE SILENT PATH IS THE ONE THAT LAUNCHES CHROME.** `chrome()` says why it refuses and says nothing when it resolves, so `utilz test prez` gives 12/0/0 or 9-passed-11-skipped on the same tree depending only on whether `PREZ_TEST_BROWSER` survived into that shell -- and the output names neither. cc found it at EOD by getting a different answer to the morning's identical command. **Every acceptance figure I quote from here on cites the shell and whether the override landed**, the same way contrast figures cite selector + palette + commit. Reported by cc; the asymmetry is mine: the loud half is the harmless half.

- **`intent ac gate` AND `intent ac status` CANNOT READ A v3-RENDERED CONTRACT -- ON A SHELL-DISPATCHED `intent`. THIS MACHINE IS NO LONGER ONE.** Re-measured 7 Sep: `intent` resolves to `Intent/native/rust/target/release/intent`, and both verbs are correct here (`16/20, unsatisfied AC15 AC16 AC18 AC19`). The rest of this entry describes the bash path, which a fresh checkout with no native build still takes, and which `Intent/bin/intent_acceptance:295` still implements. `bin/intent_acceptance`'s `ac_lines()` greps `^- AC-<st>.<nn> ` (the v2 dotted form); the v3 renderer emits `^- AC<nn> `. Zero matches, so `ac gate ST0010` reports "acceptance.md has zero acceptance criteria (empty contract) -- BLOCKED" and `ac status` reports `0/0`, against a view carrying all 20 rows. No native binary is built on this machine, so `bin/intent` dispatches `ac` to that bash path unconditionally -- there is no second reader to disagree with it. **It fails SAFE (blocks, never a vacuous pass) but the remedy it prints is `acceptance: exempt`**, which would convert a false red into a permanent real silent pass on a thread that has a full contract. Do not take that remedy. **Read satisfaction off the view instead**: `grep -oE '^- AC[0-9]+ .*-- satisfied: [a-z]+' intent/st/ST0010/acceptance.md` -- 16 yes, 4 no (AC15, AC16, AC18, AC19) at `72ee931`. Intent's tree, not ours: `intent-vc`'s to file, via hv.

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

- (2026-09-07) **THE VARIABLE IS NOT THE DEFECT; THE SILENCE IS.** Ruled with the pen on AC15, against my own prior recommendation. `UTILZ_HOME` is load-bearing as a SETTABLE variable in five places -- `test_helper.bash:20` for the whole bats suite, `prez.bats:132` as a deliberate foreign-tree run, `common_lib.bats:71`, the documented `e2e-smoke.el` path, and cc's own `install.sh:124` reading a foreign tree's yaml in a subshell. So the dispatcher derives its own home from `$0` always, ANNOUNCES a divergence with an inherited value, and HONOURS the inherited value. **The general form: when a capability is silent in the failing case and load-bearing in the working ones, remove the silence rather than the capability.** Two dispatchers was rejected as a Highlander violation on the one file that must have exactly one answer -- cc flagged that risk and the flag is what killed the option.
- (2026-09-07) **A FIXTURE HAS THE SHAPE ITS AUTHOR IMAGINED, SO AN ENUMERATION IS TESTED AGAINST THE REAL TREE.** cc's, `install_lib.bats:4-7`, and it beat the ruling I was about to make on cost grounds. The defect the owned-set tests exist to catch is an enumeration matching the imagined shape rather than the real one -- which is the inclusion-list bug cc found this evening -- so a synthetic fixture would have reproduced the bug inside the test. Cheap `git init` trees for the refusal paths, the real tree for the enumeration. **The general form: a test fixture cannot catch a defect whose mechanism is the author's own model of the thing.**
- (2026-09-07) **NEVER IMPLICITLY, ALWAYS AVAILABLE EXPLICITLY.** AC11 and AC16 are one policy from two sides, and AC16 is a SEPARATE VERB rather than a flag on install: **a `--relink` flag becomes habitual, and a habitual flag is implicit by habit**, which is the thing AC11 forbids. Shell-init in devbin's shape was rejected because devbin has one entry point reached by absolute path and that does not transfer to sixteen, and because PATH-order resolution makes which-tree-answers depend on shell state -- the defect AC15 exists to remove. Doing nothing was rejected: a manual sixteen-link step with no record is rediscovered as a bug rather than a decision.

- (2026-08-29) **A tag may be moved off a red release commit onto the green commit that fixes only the harness.** `v2.5.0` was cut at `4b6eb07`, whose CI was red; the three fixes after it touch `acceptance.sh`, the workflow and the contract, and change nothing a user can run. Moved to `72ee931` and force-pushed both remotes, so the tag names a build that is green. The limit is the reason: had any commit in between touched `src/` or `bin/`, the honest move is a new tag, not a moved one. hv can reverse it.

- (2026-08-29) **An ST0010 AT id EQUALS the acceptance.sh block id the suite prints.** The carried suite has no AT10/AT11 -- `_tools`' estate tests stayed behind -- so those ids plus AT16 hold Utilz-native rows. A green is reported by the runner as "AT07"; if the contract's AT07 covers something else, the green names the wrong instrument.
- (2026-08-29) **Two checks measuring the same PROPERTY by different mechanisms are duplication; two measuring DIFFERENT properties are not.** So AT01+AT10 both cover AC11 (build-produces-nothing-tracked vs the-ignore-rule-is-committed) and AT04+AT17 both cover AC04 (a real browser vs the dispatch table). Both pairs say so on the row, so neither is tidied away.
- (2026-08-29) **Delete the second home rather than check it.** The deck rosters went, rather than gaining a prose-vs-table comparison that would have been brittle enough to false-red -- and a false red is the more expensive direction, because it sends a peer to disprove it and spends the credibility the next finding needs.
- (2026-08-29) **A criterion pins properties, not enumerations.** AC04 lists no keys; it names BINDINGS as the one roster and pins four structural facts about it.
- (2026-08-29) **No fallback message names as its remedy the case in which it fired** (AC20b). The general form of hv's `q` finding, and the checkable one.
- (2026-08-29) **A platform-dependent string in a portable artifact resolves when the deck is VIEWED, never when it is built** (AC20d). Whoever sees the wrong text is never whoever built the deck.
- (2026-08-29) **The freeze protects utilz-cc from drift; it does not make the pin sacred.** Same rule, opposite answers, and the axis is in the facts: harming and testable where it lives -> patch there; invisible and untestable there -> fix here.
- (2026-08-29) Two non-test ACs -- AC16 (a human looks) and AC17 (provenance) -- exist because the suite provably could not stand in for either.
