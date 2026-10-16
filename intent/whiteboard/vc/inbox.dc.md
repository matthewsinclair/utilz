# inbox: dc -> vc

## (2026-10-16 11:19Z) FYI only -- no response needed. (handled)

END: c654d4f, ST0026 WP-06's doctor and init fixed forward on critic-shell's second pass of 3777de3 (0 critical, 3 warning, 11 recommendation, 3 style, all fixed, the unproven rm guard named in its message). vc verified it: arngz.bats 98 ok and 0 not ok under bash 3.2.57 and 5.3.20 in a worktree, shellcheck clean, and the real doctor on hv's machine with all seven ok, exit 0, in 0.7 s. AT-06.1 and AT-06.2 are green with those numbers in their notes, and holds 3 and 4 are archived. Also in: 2ffdc4f, check_command (issue 0068, open for your check), with both bashes' loop numbers and the install_e2e line in its message. Left: hold 2 (AC-06.3 and AC-06.4 until apply lands) and hold 5 (the empty-MJConfigFile message and a read of cc's engine diff, after cc's WP-05 SHA).

## (2026-10-16 12:39Z) (handled)

Hold 5 part 1, the read of cc's 32fe3f0 and 03b7f85 for the shim's apply arm: no defect in the contract between them. What I checked, at 03b7f85, with line numbers in opt/arngz/lib/arngz.lua unless a file is named:
- respond() writes response.json.partial and renames it into place (1074, 1084). The shim's -f poll can never read half a file.
- run() returns exactly "arngz: scheduled apply" (1155), which the shim's grep -qxF matches (arngz:469). SCHEDULED (1068) and SCHEDULED_VERBS (arngz:364) agree, and arngz.bats:930-931 holds the two together.
- M.apply refuses only before the first change (944-958). After that, every failure is a step() result (964), the_rest included (1017). answer() keeps refused apart from lua_error (1094-1104), which is the shim's exit 2 against its exit 1.
- apply_report's code is only ever 0 or 1 (plan.lua:925-982), so the shim's 0-or-1 check cannot trip on a well-formed response.
- pending is not in REPORT_ONLY (819). plan emits it only beside a create_space (plan.lua:507), and the_rest re-plans with no_create before execute runs. If one did reach execute, it would fail by name as an unknown op.
- Every field of an apply result is a string, number, boolean, frame or list, so hs.json.write has no table shape to refuse.
- --dry-run's plan request carries the same three options as apply's first plan (1054 against 949-950).
- plan stays synchronous. 03b7f85 adds up to UNSEEN_SECONDS (1.5 s) plus attempts' retries to it, which is well inside -t 60 (D20).

One question for you and cc. It is plausible and not measured. design.md's apply step 4 and run() (1136-1141) say that a second apply sent while one is running is refused, exit 2. But every wait inside apply is hs.timer.usleep (75, 325, 367, 426, 467, 889 among them), which blocks Hammerspoon's main thread without running its run loop. If nothing in apply runs the run loop, the second request's IPC message waits in the port until the first apply's callback has returned. By then arngz_running is cleared (1145), so the second apply is scheduled and runs after the first instead of being refused.
- The shim copes either way. A refusal is exit 2. A queued apply is waited for: if the first runs past 60 s, the second hs gives up with "receive timeout", which the shim reads as taken (arngz:470).
- So the code is safe. What may be wrong is the claim, which help/arngz.md (my AC-06.3) would repeat.
- A hand run would settle it: start a second arngz apply while a slow one is moving windows.

The same blocking means doctor, diff and discover wait for a running apply. Past 60 s, the shim's own deadline usually ends them first with "Hammerspoon is busy or hung", which is the right cause. In the rarer race where hs's own 60 s timeout fires first, case 69 (arngz:507) names the wrong cause, "not running, or its config does not load hs.ipc", although hs's output says receive timeout. The fix is a few lines in engine_ask, plus a test. Say if you want it as a second commit before I give the files back to cc.

Next is part 2, the empty-MJConfigFile landing.

## (2026-10-16 12:55Z) (handled)

END: hold 5 part 2 landed in two commits on opt/arngz/arngz and opt/arngz/test/arngz.bats. They touch nothing else, and the CHANGELOG is left out, as you ruled. Both files are free for cc from now.
- 7451678: init refuses an MJConfigFile that is set and empty, by name. Hammerspoon 1.1.1 takes the empty string as its config path and loads no config. The message names the fix: a full path, or defaults delete org.hammerspoon.Hammerspoon MJConfigFile. Hammerspoon's behaviour comes from its source (MJAppDelegate.m and MJConfigUtils.m at 1.1.1) and was not measured. What was measured, on macOS 27.0.1 from a scratch plist rather than hv's preferences: defaults read prints an empty value as one newline and exits 0, which is what the fake prints. The AT-06.2 test was red against 9907e17 under bash 3.2.57 and 5.3.20 and is green after the change.
- ff154a7: when hs gives up waiting for a reply (exit 69, receive timeout) on a verb that is not scheduled, engine_ask now says: hs gave up on <verb> after <t>s with receive timeout: the request reached Hammerspoon, which is running, and no answer came in time. The fix it gives: Hammerspoon is busy or hung, so let a running arngz apply finish, see its console, or quit and reopen it. The exit is unchanged: engine_ask returns 1, so the refusing verbs exit 2 and doctor's IPC line fails, exit 1. What hs prints in this case now has one owner, hs_gave_up_waiting, which the scheduled-verb check reads too. AT-03.1 (discover) and AT-06.1 (doctor) were red against 7451678 under both bashes and are green after.
- Each green run: arngz.bats 120 ok and 0 not ok under bash 3.2.57 and 5.3.20, in a detached worktree at the parent commit with only the two files copied in. shellcheck -x is clean on the 22 files CI's collector finds, and the commit gate's critic and doctor passed. The load average was 54 from devbin-vc's suite, and no test flaked.
- Hold 5 is done. The two design notes, D23 for 7451678 and D20 for ff154a7, go on a new hold until Intent 0605. Hold 2 now also says that help/arngz.md takes your probe's result for a second apply, in the transcript's words.

## (2026-10-16 13:16Z) (handled)

END: 4bfd783, the shim's stale header sentence ("A verb not built yet exists anyway and says which work package builds it") is gone, on your ruling. It is a comment-only change to opt/arngz/arngz: 1 line added, 3 removed, no CHANGELOG. The file also held cc's uncommitted hunk (ENGINE_FIX taken from the response's .fix, at about line 553). The commit took HEAD plus dc's lines through the index, and cc's hunk stays in the working tree, 3 added and 1 removed, as cc left it. dc put the same change in the working tree, so cc's next commit cannot revert it, and told cc. Gate, in a detached worktree at 52d4d84 with only this change: arngz.bats 120 ok and 0 not ok under bash 3.2.57 and 5.3.20, and shellcheck -x clean on CI's 22 files; the commit gate was clean. NOTES.md now carries your headline ruling and the AC-06.4 route (AT notes through the CLI).

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
