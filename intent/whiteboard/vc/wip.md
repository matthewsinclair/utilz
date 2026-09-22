---
node: vc
name: Validation Claude
role: validation
session_id: 21164364-ee36-49ef-a53f-1cadfb9249d9
heartbeat_at: 2026-09-22 09:56Z
status: active
focus: "22 Sep: 2.12.0 today, carrying everything. Landed here: 0047 to 0053 and ST0025 (stampz, page-by-page). Waiting on cc ST0024 under hv decision (b), then hv cuts devbin 0.1.6, devbin-vc sweeps it here, then the cut. Nine commits held for one push per hv."
claims: []
---

# Validation Claude (vc)

## DOING

- Today's release, 2.12.0 (prez 2.4.0), through devbin's 0.1.5 core, carrying all outstanding work: the CI concurrency block (cc, 0046); the 0.1.5 sweep (devbin-vc sweeps; vc holds the tree and verifies); the portrait thread for 6.1-6.3 (cc; design to vc first); the three fixes, demo.md escape, hoist-rebase AT13 and the Emacs todo verbs (vc, red first; cc verifies); releasing.md from the swept core (cc); the bumps; hv's cut; tools/formula-bump and the tap.

## TODO

- AFTER 2.12.0: sweep the tree for issue 0053's class, a probe whose pipeline failure kills the script under set -e before the guard on the next line can speak. stampz had three such probes and exited 1 in silence on an unreadable PDF. Every utility runs set -euo pipefail and most read something through a pipeline, so the question is which callers assign from one and then test the result. Not before the release: it is a scan that can only add work to a day hv wants shipped.

## Holds

_(none)_

## Watch-outs

- Reading acceptance.sh from vc's worktree: AT01 asserts the in-crate target (acceptance.sh:300, :311), so a run with CARGO_TARGET_DIR redirected reads AT01 red by construction; judge AT01 from a default-target run. AT20's default window read 0 wide once under load (19 Sep, 0040's before run) and passed when re-run alone, so re-run AT20 alone before calling it red.
- The release tag form is BARE, no v, and hv ruled it at 2.7.0 -- it is not an open question and ST0019's release core takes it as a stated input rather than a choice. The 2.7.0 annotation is where the ruling lives: "the first tag here without a 'v'. The prefix is noise ... hv ruled it out of the version everywhere, tag included. Anything sorting tags on 'v*' will not see this one." That last line is the trap: git tag --sort=v:refname puts bare 2.7.0 BEFORE v1.0.0, so tail -1 answers v2.6.1 and reads as "the last three releases were never tagged". Use --sort=creatordate. All 19 tags are on upstream, the three bare ones included (2.7.0 bc1f525, 2.8.0 8c12a09, 2.9.0 c9b75b2); nothing is tagged on this machine alone. cc reached the opposite conclusion on 2026-09-20 and had escalated it to hv; vc corrected it and asked cc to withdraw the escalation.
- THE CUT THROUGH THE CORE, read from devbin 0.1.5 source (lib/cmd/release) before the sweep: step 6 asks at a TERMINAL and fails "nobody to ask: no terminal, and --yes was not given" (exit 2) without one, so a cut run from a session with the ! prefix carries --yes, and the dry run is what replaces the prompt. A dry run never reaches step 6. object: local is the default and Utilz declares none, so the core makes the GitHub release itself with gh against matthewsinclair/utilz; there is no release workflow here. release.remotes is undeclared, which means every remote git remote lists, in order, so local and upstream both get the push (confirm it in the dry run push plan). ci.query is tools/ci-state and step 11 runs AFTER the push, waiting on a pending verdict up to ci.wait default, so the cut is gates plus a CI wait, not instant.

## Decisions

- hv, 2026-09-14: every hv inbox and whiteboard item comes to vc for review and closeout, and after its compact cc takes its instructions from vc.
- hv, 2026-09-21, directly to vc: (1) 'Devbin: yes, do it.' Utilz adopts devbin's release core (devbin ST0007 WP-08), once ST0019 WP-01 has proved the declaration and the gates. (2) 'Rule: yes, agree.' Any gap in bin/.devbin/lib/release* goes to devbin-dc or devbin-2b through vc, fixed in devbin as a default with an override; never a patch to the vendored copy, never a Utilz-only branch.
- hv, 2026-09-22, directly to vc: (1) CI at Utilz: "Yes, please follow the devbin plan there" -- read with hv's "Yes" to cc's item 1 as the concurrency block only, macOS staying on every push; confirmation asked of hv. (2) The devbin 0.1.5 sweep, Utilz first: "Yes". (3) "Yes, but I want this all done and dusted today so that all of this outstanding work is shipped on a release": one release today carrying everything, a minor (utilz 2.12.0, prez 2.4.0). (4) vc tidies hv's board. (6.1-6.3) All three portrait calls: yes. The if-room fixes: "Yes to all of those, please".
- hv, 2026-09-22, directly to vc, read from date -u at 09:10Z and arriving after my 08:03Z read, so the minute itself is unmeasured and is NOT written down as one (decision 16 said 08:0xZ, which I guessed; it is archived for that reason). The fleet CI ruling is UNIFORM at Utilz whatever the repository's visibility: "Answered with CC. Keep things uniform, regardless of public/private repo state", and "The ruling is uniform". macOS runs on a tag or a manual run only here, built from devbin 0108's YAML, and 0c39c91's comment and CHANGELOG line are corrected in that commit. The bash 3.2 coverage the ruling removes is closed in the release gate instead. hv also ruled stampz IN for today's release: mixed page geometry within one PDF, vc to build it as its own thread.
- hv, 2026-09-22, directly to vc, read at the stamp on this line from date -u: "(b)". ST0024 takes ONE rule at every orientation -- a line whose ink would leave its room is fitted wherever it is drawn, and at portrait a headline is additionally fitted to its room. This SUPERSEDES Q5 as hv answered it earlier today ("leave headlines at 16:9"), which was answered on cc's framing that a long headline there breaks mid-word and is a look rather than a defect; cc's probe then measured the opposite for a headline in a pane -- .socials h2 at -357..1318 and .wordmark .top at -506..1466 in a 960 px frame -- and the same overflow was what carried the socials handle off the frame, so the three symptoms were one decision. The byte-identical control stands: a line that visibly fits never moves.

---

_Generated by Intent v3.2.0 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
