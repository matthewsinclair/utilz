---
verblock: "29 Aug 2026:v1.5: matts - globalfold after v2.5.0; prez shipped, ST0010 open at 16/20"
---

# Restart Context

Cross-session continuity. `intent/wip.md` holds DOING and TODO; `intent/done.md` holds the record of what shipped. This file holds what the next session needs to know before it touches anything.

## Key Context (as of 3 Sep 2026)

- **Framework at v2.5.0 with 15 utilities** (core `utilz` + 14 tools). `stampz` landed 3 Sep and **the version has NOT been bumped** -- releases and tags are hv's, and stampz is 2.6.0 material. `HEAD`, `local/main` and `upstream/main` are all at `560ac49`; the `v2.5.0` tag is still at `72ee931`, so the tag no longer names the tip.
- **ST0011 (`stampz`) is CLOSED**, 11/11, CI run `33785732770` green on all seven jobs with stampz at 22/22 and zero skips on both legs.
- **ST0010 (`utilz prez`) is shipped but NOT closed.** Gate 16/20; AC15, AC16, AC18, AC19 remain. AC16 is hv's by construction -- a human renders every built-in theme and looks -- and the suite is not allowed to stand in for it.
- **`opt/prez/crate` is a FORK of the `_tools` pin, not a mirror.** AC14, AT13, AC18(b), AT17/AT19, AC19 and AC20 exist only here. **Never `tar -x` a new pin over it**: that deletes them silently, leaving a green build and a passing suite because the proving tests go too. Use `hoist-rebase.sh`, attached to ST0010, `--dry-run` first.
- **`opt/prez/prez` is a shim, not the tool.** It resolves, rebuilds on staleness, and execs a Rust binary under `crate/`. `crate/` is INDIVISIBLE: `src/`, `themes/` and `assets/` are `include_str!` siblings and must keep their relative positions.
- **Utilz carries ZERO knowledge of `Geodica/` or its `_tools`** (which moved to `~/Devel/prj/Gtools`). hv's standing ruling. Gtools is a consumer of prez, never the reverse. AT09's tripwire greps all of `src/` including comments for estate paths or names; it is in `test/`, so it cannot match itself.
- **The `M-x utilz` menu is SIX utilities, not the whole roster** (issue 0009): `cleanz`, `expz`, `mdagg`, `pdf2md`, `prez`, `todo`. Absence is a decision -- nine blocks were removed after measuring what the bridge actually invokes, four of which could never have worked and one of which created a symlink on selection. A framework test now invokes the command form the bridge builds for every declaring utility.
- **`intent/issues/OPEN/` is empty BY POLICY and always will be, so do not read it as "no open defects".** `intent/.intentfiles` declares that only OPEN THREADS get a realised form on disk; no issue is ever written there, and the files under `intent/issues/CLOSED/` are v2 artefacts predating that policy. Use `intent issues list`. Open: `0007` (prez slide-counter contrast, WP-05). An empty directory confirms a false answer where a missing one would announce itself.
- **The `intent` CLI is at `~/Devel/prj/Intent/bin/intent` and may not be on `PATH` in a fresh tool shell.** `INTENT_HOME` is inert for v3. No native binary is built, so every `intent` subcommand runs the bash implementation.

## The one instrument you cannot trust -- UNLESS YOUR `intent` IS THE NATIVE BINARY

**RE-MEASURED 2026-09-03 AND THE ANSWER FLIPPED. Check which binary you have before following the rest of this section:**

```
readlink -f "$(command -v intent)"
```

On this machine it now resolves to `Intent/native/rust/target/release/intent`, and `intent ac gate` and `ac status` are **correct**: `ST0011 PASS -- 11/11`, and `ST0010 BLOCKED -- 16/20 satisfied; unsatisfied: AC15 AC16 AC18 AC19`, which matches the view exactly. The whole thread below was written when no native binary was built here and `intent` was the shell dispatcher.

**The defect is NOT fixed -- it is bypassed.** `Intent/bin/intent_acceptance:295` still reads `ac_lines() { grep -E '^- AC-[0-9]+\.[0-9]+ ' ... }`, the v2 dotted form, and `bin/intent` still `exec`s those shell scripts. A machine without a built native binary gets the old behaviour, unchanged. So the escalation stands as a bug report and the operational advice below does not apply to a native build.

**Do not delete this section on the strength of one green.** It is conditional on a build artefact that a fresh checkout does not have.

## The instrument you cannot trust on a SHELL-DISPATCHED `intent`

**`intent ac gate` and `intent ac status` cannot read a v3-rendered acceptance contract.** `bin/intent_acceptance`'s `ac_lines()` greps `^- AC-[0-9]+\.[0-9]+ ` (the v2 dotted form); the v3 renderer emits `^- AC[0-9]+ `. Zero matches, so the gate reports "acceptance.md has zero acceptance criteria (empty contract) -- BLOCKED" and `ac status` reports `0/0` against a contract with all 20 rows present.

It fails **safe** -- it blocks, it never passes vacuously. The danger is the remedy it prints: `acceptance: exempt`, which on a thread with a real contract converts a false red into a permanent, real silent pass. **Do not take it.** Read satisfaction off the view instead:

```
grep -oE '^- AC[0-9]+ .*-- satisfied: [a-z]+' intent/st/ST0010/acceptance.md
```

It also means `st done` / `wp done` will refuse on any thread here for a reason that has nothing to do with the thread.

**`acceptance: exempt` WAS taken on two threads on 3 Sep, and that is not this case.** ST0002 and ST0007 completed before the v3 contract model and hold **zero criteria in canon** -- verified, not assumed -- so their contract is genuinely absent rather than present-and-unreadable. The gate blocked their work packages, `wp done` is declared only from `wip`, and Intent's own test suite calls exempt "the estate's own mechanism for a deliberately contract-free unit". Nothing further will ever be closed under those two threads, so there is no future pass to hide.

**The distinction that matters is the count of criteria, not the wording of the error.** The gate prints the same sentence either way. Before declaring exempt on anything, read `criteria` out of `intent/.canon/st/<ID>.json`: zero means the contract was never written, and any other number means the reader is broken and exempt would bury a real contract. ST0010 and ST0011 both carry real contracts and are deliberately NOT exempt.

**And the reason this survived a full day of use is worth more than the defect.** This project's boards read "Gate 0/20 BLOCKED, which is correct" for hours, and that reading was reasonable: a broken reader returning zero is indistinguishable from a true zero at exactly the moment a validation node first looks, when nothing has been proven yet. The tell only appears once real greens exist to be miscounted. **A zero from an instrument you have never seen return non-zero is not a measurement.**

## Project-wide Conventions

- **2-space indentation everywhere**, every language, every Intent project. Reindent any 4-space drift before adding new code.
- **Doc before code**: every non-trivial change starts with `intent st new` + `intent wp new` + `design.md` before any source edit. (Exception the hypervisor may grant: a tracked issue in `intent/issues/` can drive a focused bugfix without a full ST.)
- **Agnostic rule pack (Highlander / Thin Coordinator / PFIC / No Silent Errors) applies to elisp, shell, YAML, Rust** -- every language, not just those with dedicated rule skills.
- **Never manually wrap markdown prose**; paragraphs flow as single lines. Tables stay column-aligned. No em dashes.
- **No Claude attribution in git commits.** Commits end with the `(C) hello@matthewsinclair.com` footer.
- **Releases, tags and pushes are hv's.** Annotated tag on the `release:` commit itself, then both remotes.
- **bash 3.2 compatibility** (macOS ships 3.2.57 and CI runs it): no namerefs, no `${var,,}`; guard `"${arr[@]}"` under `set -u`; avoid GNU-only sed/grep idioms (`\b`, `\u`, byte-fragile bracket classes).

## Traps that each produced a real defect here

- **A FABRICATED TIMESTAMP IS NOT A RANDOM ONE, MEASURED n=2 ON THE SAME VALUE.** On 2026-09-03 this node hardcoded `15:52Z` into its board heartbeat while `date -u` had printed `15:45Z` on the first line of the same command. Within minutes, in a different repo, on a different task, with no shared context on the matter, `lamplight-ac` wrote **the same value, `15:52Z`**, against a clock reading `15:43Z`. Two independent sessions converging on one wrong number says the value is being generated rather than mistyped, and it is generated in the NEAR FUTURE.
  - **This kills the defence "I would notice a wrong stamp."** You would notice an implausible one. This class does not produce those -- it produces a plausible near-future stamp, which is exactly what a real read looks like.
  - **Knowing the rule does nothing.** Both sessions had the timestamp discipline loaded from the protocol at boot, and both had spent the afternoon cataloguing instruments that report unmeasured values. The rule was in context and was not the control.
  - **The asymmetry is the argument for the guard over attention.** This node's was REFUSED by the pre-commit clock guard. `lamplight-ac`'s was caught by read-back, which is to say by happening to look again.
  - **Never repair one by inventing a better-looking value** -- re-run `date -u '+%Y-%m-%d %H:%MZ'` and paste what it prints. A corrected-looking fake is worse than an admitted one.
- **A DEFAULT IS A CLAIM ABOUT WHAT AN UNREADABLE ANSWER MEANS, and "unreadable" almost never means "fine".** `varied=$(pdfinfo ... | awk ... | wc -l)` returned `0` because the awk pattern matched nothing, and the caller's `${varied:-1}` turned that zero into "one geometry, carry on" -- so the guard could not fire on any input. The regex was the bug; **the default is why the bug was silent**, and the two are separable. Generalised by `lamplight-ac` from the same defect in the tool this was promoted from, and taken over the narrower reading: any `${x:-safe}` sitting downstream of a parse converts a failed read into a pass. Audited across every utility on 3 Sep -- the only remaining instance is `${desc:-No description available}` in `list_utilities()`, which is a visible label rather than a guard. A parse that read nothing must refuse.
- **`local x=$(cmd) || handler` never fires the handler.** `local` returns its own status, so the `||` tests the declaration. It is what made `clipz` copy nothing and report success. shellcheck SC2155 catches it and the CI gate is blocking.
- **A command that succeeds WRONGLY defeats every `||` guard written against it.** `stat -f %z` is BSD syntax; on GNU `-f` means filesystem status and exits 0 with the wrong answer, so the `|| stat -c %s` fallback never ran. The general form is the keeper.
- **Verify shell tooling under `/bin/bash` with an ARRAY.** zsh does not word-split unquoted variables, so `shellcheck -x $FILES` passes one bogus path, errors, and the empty output reads as a clean run -- a false "all 15 clean" against a real 57 findings. Empty output is not a pass; report how many files the tool saw.
- **Never pipe a command whose exit code is the assertion.** `$?` after a pipeline is the last stage's, and zsh has no `PIPESTATUS`.
- **A check whose success is "no matches" aborts the script under `set -euo pipefail`** -- grep exits 1 when it matches nothing, and the script dies at the moment it succeeded, after earlier steps have written to disk. Guard with `{ grep ... || true; }`.
- **A fixed `sleep` measures the sleep, not readiness.** Poll for the condition.
- **`utilz test` is not concurrency-safe.** The helper mutates `$UTILZ_HOME/bin`, so two suites corrupt each other; one observed hang ran 2h18m and looked like a code defect. One suite at a time.
- **`utilz help <anything>` HANGS when stdin is a TTY** (glow's pager; `mdagg` does it too). It bites `bats --filter` from a terminal and looks exactly like the test hanging. `< /dev/null` fixes it; `utilz test` and CI never see it.

## Framework internals that are silent when broken

- **THE ACCEPTANCE SUITE'S BROWSER GATE IS AN ENVIRONMENT VARIABLE, SO ITS ABSENCE IS INVISIBLE, AND THE SILENT PATH IS THE ONE THAT LAUNCHES CHROME.** `chrome()` in `crate/test/acceptance.sh` announces the refusal path loudly -- an override pointing at something non-executable prints `note: PREZ_TEST_BROWSER=... is not executable` -- and prints **nothing** when it probes, finds a real browser, and hands it to four ATs to launch headless. The louder half is the harmless half. `PREZ_TEST_BROWSER` does not survive a new shell, so the same `utilz test prez` on the same tree gives 12 passed / 0 skipped in one shell and 9 passed / 11 skipped in another, with nothing in the output naming the difference. **Before quoting any acceptance number, say which shell it ran in and whether the override landed.** If a run must be browserless, `export` it in that shell and check it took.
- **`each_utility()` has six consumers, one in `bin/utilz`.** ST0009 consolidated five and missed the sixth because its sweep grepped `common.sh` only. The no-seventh-copy check is `grep -rn 'UTILZ_HOME"/bin/\*' bin/utilz opt/utilz/lib/common.sh` -- exactly two hits. Run it after adding any listing surface.
- **Consume `each_utility` with process substitution, never a pipe.** A pipe subshells the loop body and the accumulator arrays are discarded, so `run_doctor` / `run_tests` report nothing, successfully.
- **Call `require_yq` once before a loop**, never per-iteration and never memoised: `get_util_metadata` runs inside command substitution, so a memo dies with the subshell.
- **`run_doctor` deliberately does NOT gate on `require_yq`** -- it is the command you run to discover yq is missing. Do not "tidy" it.
- **`prez --version` and `--help` never reach the shim** -- the dispatcher answers from `prez.yaml`. A test meaning to exercise the binary must use a real verb.
- **`examples/demo.md` does NOT opt into mermaid** (its `mermaid: true` is documentation inside a fence). Point diagram and determinism checks at `test_pres.md`; `demo.md` is the labelled negative control.
- **`acceptance.sh` defaults to exit 0 with named SKIPs.** Always `--strict`, and in CI prove a browser was found.
- Editor-integration shape: every user-facing utility declares an `integration:` block in its YAML; the single walker `emit_integration_tsv` emits the only cross-boundary contract (TSV). An unbound utility is reported informationally, not as a failure.

## Version disambiguation

The Utilz **framework** version is `VERSION` = **2.5.0** (single source of truth). Per-utility versions in `opt/<name>/<name>.yaml` move independently. The **`intent` tooling** version (3.0.0) is a third thing; do not conflate them.

## Verification checklist on fresh checkout

- `utilz version` and `utilz --version` -- both expect `utilz v2.5.0`. `utilz --help` / `-h` work too; `utilz -v` must still fail (deliberately unbound).
- `utilz doctor` + `utilz emacs doctor` -- both green.
- `utilz test` -- full suite green. Takes several minutes; do not assume a timeout means a failure, and never run two at once.
- `utilz test prez` -- drives three sources: 128 cargo tests, 23 shim BATS, and `crate/test/acceptance.sh --strict`. The acceptance suite needs a real browser; under `PREZ_TEST_BROWSER=/nonexistent` it takes the browserless path and says why it refused.
- shellcheck exactly as CI runs it: collect `find bin opt -type f \( -perm -u+x -o -name '*.sh' \) -not -path '*/test/*' -not -path '*/.venv/*'` into a bash **array** and `shellcheck -x` it. Under `/bin/bash`, not zsh.
- Highlander check: `grep -rn 'UTILZ_HOME"/bin/\*' bin/utilz opt/utilz/lib/common.sh` -- exactly two hits, or a seventh open-coded walk has appeared.
- Estate zero-knowledge: `grep -rlE '(/Users/|Dropbox|[Gg]eodica)' opt/prez/crate/src` -- no hits.
- With `yq` off `PATH`: `utilz list` must fail loudly with a single install hint, and `utilz doctor` must still complete and name `yq` as missing.
