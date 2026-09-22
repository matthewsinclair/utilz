---
node: cc
name: Control Claude
role: control
session_id: c6b24810-9d3c-45a5-ab7a-110a0611be6e
heartbeat_at: 2026-09-22 11:19Z
status: active
focus: "Holding for vc. releasing.md is in at f337e65, corrected: a runtime before 0.1.6 cannot cut this project (stops at step 1, devbin 0106), so the sweep IS a prerequisite. My earlier claim that it was not was measured in a shell without pipefail; watch-outs 11 and 12 carry it. Next cc work is after the tag: 0056 (todo 29) and the canon paths-ignore line (todo 30)."
claims: [ST0024]
---

# Control Claude (cc)

## DOING

_(none)_

## TODO

- AFTER THE CUT, not before: issue 0056's fix. utilz test prez reads the compiled binary in its BATS stage and builds it in a later stage, so a hand version bump (ST0019 D2 requires one) reddens a test that is right about the tree and wrong about the moment. The fix is the driver building once before the three sources; it touches the shared test driver, which is not a release-day edit.
- If devbin-vc does not take it with the sweep: add intent/.canon/** beside intent/whiteboard/** in tests.yml's paths-ignore, and correct my sentence 'a push that only moves the whiteboard runs nothing', which is false as written -- paths-ignore suppresses only when EVERY changed file matches, and intent wb writes a canon event outside the ignored path (vc measured 2 of 61 runs suppressed as committed, 18 of 61 with the canon line).

## Holds

_(none)_

## Watch-outs

- One suite at a time with vc, and commits by explicit path only: vc's files have sat staged in the shared index while cc committed.
- A .md the pre-commit prettier hook reformats can leave the index holding the pre-format text after an explicit-path commit: check git status after. Store bodies (issues, WP bodies) must be prettier-stable before intent set, or the view drifts and the doctor gate refuses every later commit.
- hv's rule: a gap in devbin's vendored release core (bin/.devbin/lib/release*) is fixed in devbin, as a default with an override, through vc to devbin-dc or devbin-2b. Never patch the vendored copy or add a Utilz-only branch. Vendored line numbers move with each devbin sweep: re-read a citation before trusting it.
- A version bumped by hand needs a BUILD before the suite: utilz test prez reads target/release/prez in its BATS stage and only acceptance.sh and video.sh build it, later in the same run. A second run of an untouched tree then goes green, which is the tell (issue 0056).
- Two claims narrowed on 2026-09-22 by the same mechanism, and it is worth suspecting a third: the INSTRUMENT measured layout extent (or one fixture) and the CLAIM was written about painted extent (or every reel). They agree on every case anybody looks at, so nothing reports the gap until something else goes looking. 0054 and 0055 are both closed that way, and the caveat lives beside the check rather than in the issue alone.
- A green test suite says nothing about Rust formatting or clippy: run bin/devbin check all before handing a Rust change to vc, to CI or into a cut. Six cargo fmt diffs from cc 504825a rode five commits into main on 2026-09-22 under a green 13/13 thread and a green estate, reddened CI and would have refused the cut at step 5. cargo fmt --check fails the CI step AHEAD of clippy, so drift HIDES the clippy verdict rather than adding to it (0059, 0060). check all fixes with bin/devbin fmt rust; note its critic arm reads STAGED files only.
- To learn what a command will do, RUN it in its read-only mode (--dry-run, --check, status). Sourcing its library functions into a shell of your own measures YOUR shell, not the command: cc answered whether the vendored core resolves 2.12.0 by sourcing release_versions into a plain bash -c, got 2.12.0 and success, and was wrong -- the handler runs under set -euo pipefail (cmd/release:24) and release_versions ends its loop with is_semver && printf, which v2.6.1 (last in byte order) leaves at 1. release --minor --dry-run stops at step 1. AND: vc ran cc s probe verbatim and agreed, which is one measurement taken twice, not a confirmation. A repeat of a method cannot find a method error.
- THE SWEEP IS A PREREQUISITE for the 2.12.0 cut: a devbin runtime before 0.1.6 stops at step 1 on this repository tag set (devbin issue 0106, found here). cc decision 3 below recorded the opposite for about twenty minutes on 2026-09-22 and is retracted in the record rather than deleted.

## Decisions

- hv, 2026-09-22, directly to cc, answering cc's day plan: (1) 'Yes': at Utilz, take only the cancel-superseded half of the fleet CI ruling, and macOS stays on every push (Utilz is public, and the macOS legs are its only bash 3.2 run). (2) 'Yes, vc has instructions from me now, follow their lead': go on vc's order, sequenced by vc. (3) 'I'm less worried about the release number and more worried about having all of this done and dusted today so that all of the outstanding work is shipped on a release.'
- hv, 2026-09-22, directly to cc and to vc on the same day, three rulings this node acted on: (1) the fleet CI ruling is UNIFORM whatever a repository's visibility, so Utilz took both halves and the earlier public-repo exception is superseded (0046); (2) on ST0024's Q5, '(b)': one rule at every orientation -- a line whose INK would leave its room is fitted wherever it is drawn, and at portrait a headline is held to its whole word against its room; (3) on 0055, 'Narrow', and on 0054, 'Ok': where an instrument measures one thing and the claim was written about another, the claim narrows to what is measured and the product does not move.

---

_Generated by Intent v3.2.0 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
