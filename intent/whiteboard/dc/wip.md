---
node: dc
name: DevX Claude
role: devx
session_id: bc2f8276-99c2-4c44-b990-1124aa522585
heartbeat_at: 2026-10-26 12:28Z
status: active
focus: "26 Oct 12:11Z: folded at d6891e58 before hv's compact, not released. hv's ruling (a), vc's decision 64 (12:09Z): A4's conformance to T5 (use brew) goes into 2.14.4, so 9027555d is no longer the final head. Doing 20 holds at step (1) for vc's word with the new final head, once A4 has landed checked. Step (2), banked at 9027555d (twins.sh 4220174e, dryrun-2144.sh d298223c, request.md 3df71364), is not sent: it is the base for the re-hash. Then the kovacs twins through molt-vc to kovacs-sysadm, then the dry run. Resume: ~/Devel/scratch/utilz-dc/RESUME.md, its 26 Oct 12:11Z section. No push."
claims: []
---

# DevX Claude (dc)

## DOING

- 2.14.4's kovacs twins and release dry run on the final head, which now waits for A4: hv's ruling (a) through molt-vc (read 12:09:50Z, vc's decision 64) puts Utilz's conformance to A4 to T5 (use brew refuses, removing nothing, when no brew copy would answer) into 2.14.4, so main's 9027555d (0109, 0111 and 0110 landed) is no longer the final head. In vc's order: (1) hold until vc sends the new final head's sha, once A4 has landed checked; (2) then re-hash from the bytes banked at 9027555d and never sent (work/c2144/twins.sh 4220174e, work/dryrun-2144.sh d298223c, work/c2144/request.md 3df71364; the 21b0385d bytes in work/c2144/base-21b0385d/): set SHA and CODE to the new head, re-read request.md against the diff from 9027555d to it (its expected lines stay based on the 21b0385d readback, twins.out), and send vc the hashes; vc reads them and routes the request; (3) the twins go through molt-vc to kovacs-sysadm as a request, after cc's Mac twins END, booked as a heavy (vc's decision 60 (4)); bank the readback as work/c2144/twins-<head8>.out, re-tally it and send vc the END; (4) then the dry run, booked fresh with molt-vc: from its GO until vc reads its last row the tree is frozen, with no commit and no intent wb verb from any node. Each runs only on molt-vc's GO by name. Nothing run. No push. (edited)

## TODO

_(none)_

## Holds

_(none)_

## Watch-outs

- dc's own limits: no Hammerspoon, pointer, xcodebuild or hv's keychain; no menuz file (utilz-ic's); nothing pushed. Every host run books through Intent's slots on molt-vc's desk (hv's word, molt-vc in control from 13:19:49Z on 26 Oct; vc's watchout 17 has it whole): vc's word on the bytes first, then dc's intent estate slots ask heavy|light with --named tip=<sha> and each script's hash and --node dc, its id sent with the run's details to molt-vc and vc; a run only on molt-vc's GO by name; START and END as slots start and slots release with --node dc (--relayed for a kovacs run, whose START and END come through molt-vc), each also by message to molt-vc and vc; a slots verb's wrote: path committed exactly, as a wb verb's. (edited)
- kovacs legs (hv, 26 Oct, through molt-vc and vc, narrowing 25 Oct's no-ssh rule; vc's watchouts 17 and 21 hold the rule): while kovacs-sysadm is running, every read and change on kovacs goes through it, read-only included, and only when it is not running is ssh fine; never sudo in a probe. A leg is a heavy booked with molt-vc: a request to kovacs-sysadm (the bundle, the exact commands and their expected output) while it runs, vc re-tallying the answers, and over ssh only when it does not. The method, tools and kovacs's state are in ~/Devel/scratch/utilz-dc/RESUME.md, the baseline is tmp/dc-2141/kovacs/vbase-2d73b7f/BASELINE.md (slot 83), and a leg runs only its bundle's tree, with rustup's cargo first and each tool's version printed. dc's /var/tmp tool dirs on kovacs (shellcheck 0.9.0 and Lua 5.4.6) stay for the next leg. (edited)
- board@4.0 since 22 Oct (Intent issue 0612, intent 3.2.4; vc's re-render cb466d50): dc commits exactly the paths its own wb verbs print on wrote: lines, through ~/Devel/scratch/utilz-dc/wb-commit-wrote.sh, never a re-rendered: line, which is another node's; an ask's wrote: lines include the recipient's inbox view. Live messages are read from intent wb show dc --json (.messages[] with state live), since the inbox views no longer mark a message (handled). (edited at the localfold: the swap's one-off steps are done) (edited)
- PATH on rhadamanth: hv uses the brew release of every tool unless a project is being worked on, and runs `utilz use brew` himself (hv's ruling via molt-vc, through vc, 25 Oct). So a bare utilz may be brew's release, not the primary's dev links (Molt-matts a258ad0 put ~/.local/bin first). Every dc run on the Mac, the twins and the dry run among them, names its own tree's bin/ (eg <tree>/bin/utilz), never a plain utilz from PATH, and logs `command -v utilz` and `utilz --version`. kovacs runs put the run tree's bin/ first on PATH and check every name resolves into it. A release's checklist ends with brew upgraded on both hosts, `utilz use brew`, and `utilz --version` showing (brew, <release sha>) from a fresh login shell. (edited)

## Decisions

_(none)_

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
