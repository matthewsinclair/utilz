---
node: cc
name: Control Claude
role: control
session_id: 5d94b174-72a1-4eca-9eb0-674adfd6414d
heartbeat_at: 2026-09-03 15:49Z
status: active
focus: "ST0011 green and checked in. ST/WP hygiene done, docs synced to as-built across all 15 utilities, issue 0008 raised and closed. AC11 (CI) is the only thing left and needs hv's push."
claims: [ST0010, ST0011]
---

# Control Claude (cc)

## DOING

**ST0011 (`stampz`) -- the Lamplight PDF pack watermarker, promoted. WP-01 through WP-04 DONE, WP-05 written and waiting on a push.** hv named it `stampz` (over `markz`: `mark` reads as _markdown_ next to `mdagg` and `pdf2md`) and ruled "Go" on the design, which ratified the out-dir default with an explicit `--in-place`. 22 BATS tests green, all 18 suites green, `shellcheck -x` clean across 17 files, `utilz doctor` clean. **AC11 (CI green on both legs) is the only unsatisfied criterion and it needs hv's push.**

**THE RENDERER IS NATIVE PDF AND THAT IS THE WHOLE PROMOTION.** The reference needed Chrome at a hardcoded `/Applications` path plus a CDN font; the stamp here is a hand-assembled 823-byte one-page PDF (base-14 Courier-Bold, rotation in the text matrix, alpha via ExtGState). `qpdf --check` finds no syntax errors, so the xref is byte-exact and nothing is being silently repaired. Offsets are MEASURED with `wc -c` per object, never summed from `${#s}`, which counts characters and would shift every entry on a non-ASCII recipient.

**FOUR DEFECTS FOUND, THREE OF THEM IN CHECKS RATHER THAN IN BEHAVIOUR. Full write-up is in ST0011's Context.**

- **The mixed-geometry guard was DEAD, here and in the reference.** `pdfinfo` prints `Page    1 size:`; the reference matches `/page *[0-9]+ size:/`, lowercase, and awk is case-sensitive. Zero matches, `wc -l` returns 0, and the caller's `${varied:-1}` reads that zero as "one geometry, carry on". Caught only because AT05 asserts its own fixture really carries two geometries first -- my first fixture built one by ROTATING a page, which does not change what `pdfinfo` reports, so the guard was handed a uniform file and the test passed on a refusal that never happened. Reported to `lamplight-ac`.
- **The size solve ignored page height, and the obvious case hides it.** On A4 a 3-char name goes to 263pt, whose bbox exceeds the page arithmetically and lands NO ink in the margins, because glyph ink is inset from the em box -- so an A4 fit check passes a wrong formula. On 1440x810 the same name goes to 636pt and puts 2761 ink pixels in the top/bottom margins. Both axes constrained now.
- **My source-guard made the shipped tool a silent no-op.** `STAMPZ_SOURCE_ONLY` is inherited by children: with it exported, `stampz <pack> <recipient>` did nothing and **exited 0**. Now `[[ "${BASH_SOURCE[0]}" == "${0}" ]]`, self-detecting and unsettable from outside. Caught because the tests assert on output files, not on the exit code -- and the exit code was the wrong thing.
- **`poppler` is a PACKAGE, not a command.** doctor resolves deps with `command -v`, so declaring `poppler` was a permanent false red on a machine that had it. Declared `pdfinfo` and `pdftoppm`; AT09 now asserts every declared dep is a real command name.

**A false claim reached a code comment before I caught it.** The first fit check hand-parsed the PGM header by skipping a guessed twelve fields and miscounted header bytes as pixels, reporting "6 ink pixels in the margins" for a mark that fits. That reading became the stated justification for a real fix. The fix was right and its reason was invented by a broken instrument. Every visibility check now renders the SAME crop of two files and compares byte for byte, so headers match by construction and nothing parses them.

**Three controls proven red-first, patch-landed-then-red, never reasoned about:** `--underlay` for `--overlay` reddens AT01; the reference's lowercase pattern reddens AT05; the width-only solve reddens AT03's wide-page case.

**I CHANGED A FILE IN vc's THREAD.** `opt/prez/test/prez.bats` asserted `"14 utilities"` and stampz is the fifteenth, so adding a utility reddened prez's suite. Bumping 14 to 15 moves the landmine to the next utility, so the count is now derived from `utilz list` -- the same idiom CI's macOS leg uses. prez is green again across all three suites (12 acceptance, 0 skipped). Told vc.

**DOC AND ROSTER SWEEP DONE, 3 Sep -- hv asked for as-built vs as-written and it was worse than one utility.** Raised and closed as issue **0008**.

- **`README.md`'s utility list was missing `prez`, `todo` AND `stampz`.** Stale by two releases before mine. Nothing fails when docs go stale, which is why it lasted.
- **Issue 0006's sweep left a THIRD hardcoded roster copy** and I found it by breaking it: `prez.bats` asserted `"14 utilities"`. Derived from `utilz list` now, not bumped to 15. `docs/index.md` ("All 12 shipped utilities", naming twelve, tree held fifteen) and README's "(12 utilities total)" went the same way -- counts removed, not corrected. **A sweep bounded by the symptoms it saw is bounded by the wrong thing.**
- **`docs/index.md` restated the version as 2.2.0** against a `VERSION` of 2.5.0 -- stale across three releases. `help/utilz.md` already carried the fix for the identical defect, so mine matches its wording.
- **`cryptz` and `gitz` hard-require `gpg` and `git` and declared nothing**, so doctor never checked them and the failure arrived at use. Declared. prez still declares no `cargo` deliberately and there is a test pinning that.
- **`help/cryptz.md` was still the generated template.** Rewritten from the as-built surface; it was the last stub. A flag-drift audit now reports **0 of 15** in both directions -- and its first two versions were wrong in my favour (missed `--colour|--color` alternations, counted prose mentions of other tools' flags), so the audit was fixed twice before I trusted it.
- **`.claude/restart.md` documented two commands that do not work:** `intent st list --all` (it is `--status all`) and `intent/issues/OPEN/` for open defects. That directory is empty BY POLICY -- `.intentfiles` realises only open threads -- so it confirmed "no open defects" while 0007 was filed. **A pointer at an empty directory is worse than one at a missing path.**

**ST/WP HYGIENE.** ST0002's six WPs read `not-started` and ST0007/WP-04 read `wip`, both under completed threads. Closed via the CLI. **I declared `acceptance: exempt` on ST0002 and ST0007 and that is NOT the remedy this project ruled against** -- both hold **zero criteria in canon** (verified), so their contract is genuinely absent, where ST0010's is present and unreadable. The discriminator is the criteria count, not the error text, because the gate prints the same sentence either way. ST0010 and ST0011 keep their real contracts and are not exempt. Written into `restart.md` so the next reader does not think the ruling was broken. Issue 0006 also written into canon, where it had been a flat view only.

**NOT DONE, deliberately:** `intent organize --apply` wants to hydrate two ST0010 attachments (`hoist-adapt.sh`, `hoist-rebase.sh`). vc's thread, so I previewed and left it.

**FIRST NON-SYNTHETIC RUN, and it came from outside.** All 22 of my tests run on fixtures I generate, which this board already calls half a test. `lamplight-ac` deleted `stamp-pack.sh` (`34ad04d3f`) and ran `utilz stampz` over the real investor pack: **10 files, 55 pages, two geometries including the 1440x810 deck. All 55 marked, 0 unmarked.** It verified by comparing each stamped page against its unstamped source rather than looking for ink -- the same construction AT01 uses, reached independently, and for the same stated reason: a zero there means genuinely no mark, so the instrument can report a failure.

**THEIR GENERALISATION IS BETTER THAN MINE AND I HAVE TAKEN IT.** I called the dead guard a case-sensitivity bug with a bad default. They separated the two: the regex caused it, **the `${varied:-1}` is why it was SILENT**, and that generalises past the script -- _a default is a claim about what an unreadable answer means, and unreadable almost never means fine_. Acted on rather than banked: audited every utility for a `:-` default downstream of a parse. One instance remains, `${desc:-No description available}` in `list_utilities()`, and it is a visible label rather than a guard. Recorded in `intent/restart.md` as a project trap, not a stampz note.

**I FABRICATED A TIMESTAMP AND SO DID `lamplight-ac`, WITHIN MINUTES, AND WE INVENTED THE SAME VALUE.** I hardcoded `15:52Z` into this board's heartbeat while `date -u` printed `15:45Z` on the first line of the same command. They wrote `15:52Z` against a clock reading `15:43Z`, different repo, different task, no shared context. **One instance is carelessness; two independent instances converging on one number says the value is generated** -- and generated in the near future.

- **"I would notice a wrong stamp" is not available as a defence.** You would notice an implausible one. This class produces plausible ones, which is what a real read looks like.
- **Knowing the rule did nothing.** The discipline was loaded from the protocol at boot and we had both spent the afternoon on instruments reporting unmeasured values -- a dead awk guard, a misparsed PGM header, a whole-page diff greening the wrong verb. Then we both wrote an unmeasured value into a record while cataloguing exactly that.
- **Mine was REFUSED by the pre-commit clock guard; theirs was caught by read-back, ie luck.** That asymmetry is the whole argument for the mechanical control over attention.
- **Four known fabrications now, all POSITIVE drift** (Intent's two at +60s, ours at +7 and +9 min), none past-dated. The guard's own note names the past-dated fake as the residual it cannot catch; this says the observed generator does not produce them, so check A is load-bearing rather than one of three. Escalated to `hv/inbox.cc.md` for routing to `intent-cc` -- Intent's tree, nothing of theirs touched.

**ST0010 -- untouched today, apart from `prez.bats`.** Gate still 16/20; vc owns the remainder.

## TODO

- **ST0011/WP-02 next: the native stamp renderer.** Byte offsets for the xref are MEASURED (`wc -c` before each append), never computed from `${#s}`, which counts characters rather than bytes and is correct only under `LC_ALL=C` on a pure-ASCII recipient. Do not fall back on letting qpdf reconstruct a bogus xref: it repairs with a warning and exit 3, and a silent-repair dependency in this thread would be self-parody.
- **ST0011/WP-05 must add `stampz` to the hardcoded roster in `test-linux`.** `test-macos` derives its roster from `utilz list` and picks it up for free; Linux does not, and nothing reports the gap. Both legs need `qpdf` + poppler installed so the suite's skip path is never the path CI takes.
- **WP-04 is vc's**, on hoist-green. WP-05 (polish), WP-06 (AC15 theme addressing split), WP-07 (possibly un-deferred: two consumers now blocked by prez keeping its browser list and determinism probe private -- vc has it with hv).
- **`prez build examples/demo.md` warns `class 'escape' has no effect`** -- prez's own example ships a warning. vc's WP-05 note, deck content, not urgent.
- `ST0007/WP-04` is `wip` under a completed thread. Not the migrator: the v2 source itself says WIP. Ours to fix, small.
- **`hoist-rebase.sh` carries one dead postcondition.** `post "test/acceptance.sh" "AT13: PASS" 0 ...` sets the minimum to ZERO and `post()` tests `-ge`, so it prints `ok` unconditionally -- including at a count of zero, which is the case it exists to catch. Redundant rather than a hole: two other checks cover AT13 and both go red. But it is the measures-nothing shape sitting inside the script that guards against silent loss. Fix is `0` -> `1` and a re-attach; held because re-attaching writes canon while vc has the store open.
- **ST0002's six WPs read `not-started`** under a thread completed 2026-02-08 -- the v3 migrator defaulted them and `intent doctor` reports nothing. hv ruled not-today.

## Watch-outs

**Measurement discipline -- the class this project keeps hitting.** Every one of these produced a green that meant nothing.

- **A check placed before the thing it measures passes for the wrong reason.** Two "the terminal stays clean" assertions sat above the loop that waits for the stub to run. The red-first run is what exposed it: the other three checks failed and these two did not, which is the tell.
- **A red-first probe that did not APPLY is not a red-first proof.** Three of mine patched the wrong function, changed nothing, and the test passed for the wrong reason. Assert the patch landed before trusting the red.
- **A grep-based check must target a string the artifact can only contain if the thing is really there** -- a sentinel, a library-internal symbol, a size gap. Never a token the deck might legitimately discuss. This class has bitten five times.
- **A source-grep check can match itself.** A test grepped its own file via `include_str!` and failed forever, because it contains the word it looks for. Assert on the ARTIFACT instead.
- **A test that only runs on a synthetic fixture is half a test.** Both AT17 probe defects surfaced the moment it was pointed at the shipped decks.
- **Never pipe a command whose exit code is the assertion.** `$?` is the last stage's. Bit me twice today and vc twice.

**This tree has THREE concurrent writers: me, `vc`, and `hv`.**

- Commit with an explicit pathspec, never `-A` over the whole tree. A `git status` from earlier in a session is not a stable baseline; remotes and `bin/devbin` have both moved mid-session.
- **`intent st attach` writes canon and regenerates views**, so it is not private when a peer has the store open. Check `git status -- intent/.canon` BEFORE attaching.
- **Run prettier yourself before committing markdown.** Otherwise the pre-commit hook is an unnamed third writer, and `git commit --only` leaves a phantom staged diff (`git restore --staged` clears it). `git add` + plain `git commit` avoids it entirely.
- A peer node in ANOTHER project may edit this tree; Cdsync's `cc` did on 2026-07-29.

- **The browser gate in the prez acceptance suite is an ENVIRONMENT VARIABLE, so its absence is invisible.** `utilz test` drives `acceptance.sh --strict`, and with `PREZ_TEST_BROWSER` unset `chrome()` probes, finds Chrome, and AT04/AT07/AT08/AT12 each launch it. The override does not survive a new shell, so the same command is browserless in one terminal and browser-driving in the next with nothing said either way. Every launch does carry `--use-mock-keychain` via `$CHROME_SAFE`, which is what keeps the Safe-Storage modal off hv's screen. If a run must be browserless, set the variable in that shell and check it landed.

**Shell and tooling.**

- **A `grep` whose SUCCESS is "no matches" kills a `set -euo pipefail` script** -- grep exits 1, pipefail propagates, and the script dies at the moment it succeeded, silently, after earlier steps wrote to disk. Guard with `{ grep ... || true; }`.
- **`utilz help <anything>` HANGS when stdin is a TTY** (glow's pager -- `mdagg` does it too). It bites `bats --filter` from a terminal and looks like the test hung. `< /dev/null` fixes it; `utilz test` and CI never see it.
- **`utilz test` is not safe to run concurrently** -- the helper mutates `$UTILZ_HOME/bin`. One suite at a time. `pgrep -fl bats` matches peer Claude sessions, not just real suites.
- Verify shell tooling under `/bin/bash` with an ARRAY. zsh does not word-split, so `shellcheck -x $FILES` errors on one bogus path and the empty output reads as a pass -- a false "all 15 clean" against 57 real findings.
- Do not use `perl -0pi -e` where the text contains `$(` -- Perl interpolates it as GID and corrupts the file.

**Framework internals.**

- **`each_utility()` has six consumers, one in `bin/utilz`.** The no-seventh-copy check is `grep -rn 'UTILZ_HOME"/bin/\*' bin/utilz opt/utilz/lib/common.sh` -- exactly two hits.
- `each_utility()` must be consumed with process substitution, never a pipe: `run_doctor` and `run_tests` accumulate into arrays and a pipe subshells the loop body.
- `require_yq` ONCE before a loop, never per-iteration -- `get_util_metadata` runs in command substitution and cannot memoise.
- `run_doctor` deliberately does NOT gate on `require_yq` -- it is the command you run to discover yq is missing.
- **`prez --version` and `--help` never reach the shim** -- the dispatcher answers from `prez.yaml`. A test meaning to exercise the binary must use a real verb.
- **`examples/demo.md` does NOT opt into mermaid** (its `mermaid: true` is documentation inside a fence). Point diagram checks at `test_pres.md`; demo.md is the labelled negative control.
- mdagg strip + title-case are locale/BSD-sed sensitive -- `intent/issues/CLOSED/0001`. Match multibyte literals with `grep -F` or an ERE alternation, never a character class.
- todo guard: utilz `item_re` parses intent's `- [x] STID: title` lines as items, so `utilz todo sync` on an intent file would clobber it. The STAMP is unconditional; the REFUSAL fires only when intent is present.
- No Claude attribution in commits, ever. Commits end with `(C) hello@matthewsinclair.com`. 2-space indent, bash 3.2, no em dashes, column-aligned tables.

## Decisions

- (2026-07-29) `-v` stays **unbound** on the `utilz` dispatcher. It reads as a verbose flag and no utility binds it, so binding it to `version` would foreclose the obvious future use. Pinned by a test asserting it still fails, so the next "while we're here" change has to argue with a test rather than quietly take the name.
- (2026-07-29) A set of small, independent, already-diagnosed defects may be driven by one issue each rather than a steel thread, even when fixed in a single commit -- extending the 0001/0002 precedent from one issue to a batch. The commit body carries the narrative; each issue carries its own root cause, evidence and resolution. Doc-before-code still holds for feature work.
- (2026-07-29) Whiteboard brought to the Lamplight / Baize standard: `hv` provisioned via `intent claude ws new hv` (Workstream Zero is present in every Intent project), plus a hand-authored `README.md` roster. Roster deliberately stays at two nodes -- Utilz is single-stream, and nodes are made to order, not in anticipation. An external correspondent (`cdsync-cc`) gets an inbox but no node directory, because it has no workstream here.
- (2026-07-29) A shipped defect fixed inside a steel thread still gets its own `intent/issues/` entry (0002 alongside ST0009/WP-03), following the 0001 precedent. The ST carries the work; the issue carries the defect record.
- (2026-07-29) Retroactive paperwork is the remediation for a doc-before-code violation when the code is already correct and verified -- not reverting it. Red-first is then proven retrospectively by running the new tests against `HEAD` in a scratch copy, and the retrospective verification is stated as such in `acceptance.md` rather than presented as genuine red-first.
- (2026-07-10) A tracked issue in `intent/issues/` may drive a focused bugfix without a full ST (hv-approved for issue 0001). Doc-before-code still holds for feature work.
- (2026-07-09) todo guard's Intent-project test is anchored on the **target file's directory** (walk up from `dirname($TODO_FILE)`), NOT cwd. Deliberate divergence from Intent's cwd-based `find_project_root`: the guard protects the file being overwritten, so `--file`-ing at another project's `intent/todo.md` from outside still refuses. Own/unmarked files short-circuit before the project test. (hv-confirmed.)
