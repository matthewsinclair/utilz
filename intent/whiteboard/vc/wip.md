---
node: vc
name: Validation Claude
role: validation
session_id: 3341dbaf-a82f-4073-bae3-2f8c30306f25
heartbeat_at: 2026-10-16 11:14Z
status: active
focus: "16 Oct: 0065 and 0067 verified and landed; ST0026 arngz designed and started, WP-02 and WP-03 verified, WP-04 with cc; the spike closed outcome A and doubts B; D (the drag) and the Dock clicks wait on hv. Folding for a compact on hv's word after cc and dc fold."
claims: [ST0026, ST0027]
---

# Validation Claude (vc)

## DOING

- ST0026 arngz: vc holds the thread for the design. WP-01 spike DONE 16 Oct: A and B closed (moveWindowToSpace lies; a binding switches the display, not the window), D taken (D21: hold the window and press the Move-space shortcut, 5 of 5; drag over a shared edge across displays), ordinals from the plist (D22), hs client 4 s timeout (D20 amended). WP-02 (3e11cb4), WP-03 (88c57ad), WP-04 (00a93b3) verified. WP-06 doctor/init at 3777de3 (dc): suite and shellcheck verified, diff read and real doctor run pending. WP-05 apply briefed to cc, starts after the compact. Design on disk at intent/st/ST0026/design.md and in the store; edit the file, then intent sync --to-store. (edited)
- ST0027 menuz: written up on hv's ask and the three sibling apps (Intent, Conflab, Gtools), nothing reinvented: design.md at 59efdaf carries the shape, the menu file, the login shell's own interpolation, the standard dialogs for params, the log, 18 criteria and 11 questions with a recommendation each. WP-01 (the rubber-duck with hv) is started; WP-02..05 and the criteria are in the store. HELD until Intent's fixed pair (0605, 3.2.4): the sync --to-store that carries design.md into the store, and any edit under intent/st/. Code starts after hv's rulings.

## TODO

- Fold notes still open: the README utility table needs an arngz row, with help/arngz.md and the CHANGELOG entry (WP-06 AC-06.3, after apply); vc's scratchpad holds git worktrees wt-c21f319, wt-13552bc, wt-3e11cb4, wt-88c57ad, so run git worktree prune when the scratchpad goes. Done 16 Oct: restart.md says 16 utilities and devbin 0.1.10, and carries the arngz state, the Lua review fact (headless critic arms 0 of 7 lua rules) and hv's init.lua lines. (edited)

## Holds

- After the compact, what is left: (1) cc's WP-05 hand runs AC-05.4 and AC-05.5 need hv's hands off when cc hands over; (2) git worktree prune when the scratchpad goes (wt-c21f319, wt-13552bc, wt-3e11cb4, wt-88c57ad); (3) the spike's files in /tmp/arngz-spike2/ and dc's scratchpad go at reboot; (4) intent sync --to-disk once, if the file index still misses the two AC writes of 09:5xZ after hv's index rebuild; (5) install_e2e.bats has not run since the store blew up (it copies the primary checkout, intent/.cache included): run it from the primary checkout once the store is back to size and before 2.13.0. Done 16 Oct: dc's c654d4f read and verified (98/98 both bashes, shellcheck 22 clean, real doctor 7 of 7 on hv's machine); dc marks AT-06.1/06.2 green on those numbers. (edited)

## Watch-outs

- Reading acceptance.sh from vc's worktree: AT01 asserts the in-crate target (acceptance.sh:300, :311), so a run with CARGO_TARGET_DIR redirected reads AT01 red by construction; judge AT01 from a default-target run. AT20's default window read 0 wide once under load (19 Sep, 0040's before run) and passed when re-run alone, so re-run AT20 alone before calling it red.
- The release tag form is BARE, no v, and hv ruled it at 2.7.0 -- it is not an open question and ST0019's release core takes it as a stated input rather than a choice. The 2.7.0 annotation is where the ruling lives: "the first tag here without a 'v'. The prefix is noise ... hv ruled it out of the version everywhere, tag included. Anything sorting tags on 'v*' will not see this one." That last line is the trap: git tag --sort=v:refname puts bare 2.7.0 BEFORE v1.0.0, so tail -1 answers v2.6.1 and reads as "the last three releases were never tagged". Use --sort=creatordate. All 19 tags are on upstream, the three bare ones included (2.7.0 bc1f525, 2.8.0 8c12a09, 2.9.0 c9b75b2); nothing is tagged on this machine alone. cc reached the opposite conclusion on 2026-09-20 and had escalated it to hv; vc corrected it and asked cc to withdraw the escalation.

## Decisions

- hv, 2026-09-14: every hv inbox and whiteboard item comes to vc for review and closeout, and after its compact cc takes its instructions from vc.
- hv, 2026-10-16, directly to vc, on arngz (ST0026): (1) Hammerspoon is the engine. (2) The CLI is bash in the Utilz shim format, for now. (3) Config is YAML: hv asked whether TOML would be better, and vc measured that yq 4.54.1 reads and writes both, so the deciding point is shape, and a four-level desk tree reads as indentation in YAML and as order-dependent [[displays.spaces.apps]] headers in TOML. (4) For the rest hv takes vc's recommendations from the review: a space is its ordinal on its display with an optional name, and apply creates missing spaces unless --no-create; an app is a bundle id plus an optional window title pattern, no pattern meaning every window of that app, and the same app on two spaces of one display without patterns is refused; displays match by UUID, then name and size, then position, mismatches refused by name with --map to override; apps not running are launched and waited for unless --no-launch, apps not installed are reported and apply exits non-zero; discovery reads the Dock app-bindings and apply rewrites them only with --bind, once the spike shows it works; full-screen windows are recorded as fullscreen and left alone in v1; v1 is apply, discover, diff, list, show, delete, init, doctor and dry run. (edited)

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
