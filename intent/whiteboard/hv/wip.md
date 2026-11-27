---
node: hv
name: Hypervisor
role: hypervisor
session_id: bbf0140c-70da-4570-8e04-c18e29c296ad
heartbeat_at: 2026-11-27 08:48Z
status: active
focus: "Utilz is parked by hv decision 72. spcz (ST6ae5a79), ST0029 and STb234935 wait for hv's word."
claims: []
---

# Hypervisor (hv)

## DOING

_(none)_

## TODO

_(none)_

## Holds

_(none)_

## Standing directives

_(none)_

## Watch-outs

_(none)_

## Decisions

- hv, 24 Nov 2026, first-hand in vc's session, read by vc's date -u of 14:47Z. hv's words: "I have pre-approved all checkins, commits, pushes, cuts, and brew updates, etc at devbin-vc. When it says go, go. Ok?" The rest is vc's wording. It confirms devbin-vc's relay of hv's 14:45Z words (vc decision 114). From now on, a go from devbin-vc is hv's approval in vc's session for Utilz's commits, pushes, cuts and brew updates, and vc acts on it. hv decisions 17, 18 and 19 are committed as written under it. A red before a tag stops and waits. Spike v3 and STca1b7f9's live run still need hv at the keyboard, and a cut's notarisation still needs hv's keychain.
- hv, 25 Nov 2026, first-hand in vc's session, answered before vc's date -u of 08:28Z. It answers vc's question on when issue Ibf2b53b (opt/prez/test/prez.bats runs in no CI job) goes in, where vc had recommended the next release. hv's words: "I don't understand this logic at all. Built it now for THIS release. Test it now LOCALLY and make sure it works. Then why would it fail on CI/CD? I don't want to keep going thru this bullshit charade of constantly making 1-off releases to go thru the entire release process for tiny bits of functionality. IT IS INSANE and literally sets fire to time I DO NOT HAVE." The rest is vc's wording. dc adds prez.bats to CI now, proves it with a local run booked at the Desk, and it ships in 2.15.0. From now on, no seat and no recommendation of vc's defers a fix to a later release. Every fix found goes into the release being built, proved locally, unless hv defers it by name. Then devbin-vc relayed that hv had picked "Next release (Recommended)" for Ibf2b53b in devbin-vc's window, read by devbin-vc's date -u of 08:31Z. vc put the two answers to hv in vc's session. hv picked "This release, as I told vc (Recommended)", so this decision stands. (edited)
- hv, 25 Nov 2026, by AskUserQuestion in devbin-vc's window, relayed by devbin-vc (its vc decision 308) and received before vc's date -u of 12:32Z. devbin-vc's wording: "Utilz ST0029 (Retire Python from Utilz) starts after 2.15.0 is cut: utilz-dc begins with xtrct's goldens and its zsh port, then the pdf2md spike. Nothing changes before the cut." It answers the OPEN line of vc's plan for the estate plan. The rest is vc's wording. ST0029 stays on hold until the 2.15.0 cut. At the cut, vc tells dc, and dc resumes ST0029 in Intent. dc starts with xtrct's goldens, then xtrct's zsh port, byte-exact, since xtrct feeds the Talga Rd accounting (vc decision 79 (2)), then the pdf2md spike. vc adds the step to Utilz's release chain, after the cut.
- hv, 26 Nov 2026, first-hand in vc's session, read by vc's date -u of 07:02Z. hv's words, on spcz against Hammerspoon: "Yeah, agree. If spcz can manipulate the things that need manipulating from a simple rust cli interface, then the rest doesn't matter." The rest is vc's wording. hv agreed with vc's view: spcz is a plain Rust CLI with commands and JSON output. Compatibility with Hammerspoon, its Lua API or its .lua config file is not a goal. spcz's design reads Hammerspoon's and yabai's source as a reference and cites it. Earlier in the sitting hv asked for one design agent to draft spcz's design for hv's review while the estate waits. The agent writes ~/Devel/scratch/utilz-vc/spcz/design-draft.md and nothing else. It amends hv decision 43's "no design work before the cut" for that one draft only. The spcz thread still opens after the 2.15.0 cut.
- hv, 26 Nov 2026, first-hand in vc's session, read by vc's date -u of 07:09Z. hv's words, on yabai in spcz's design draft: "I don't want _anything_ to do with this approach and I don't want to have to touch SIP." The rest is vc's wording. vc reads it so: spcz never needs a SIP change, injects no code into the Dock or WindowManager, and does not use yabai's methods. The draft's open question 6 is answered "No": spcz uses exported names only, and the bridged window move (method B, a symbol that SkyLight does not export) is not built and is not in the spike. yabai is not a model for spcz. vc keeps in the draft only the methods that Hammerspoon or arngz use today and that need no SIP change. If hv also wants yabai's source removed as a reference, hv says so.
- hv, 26 Nov 2026, first-hand in vc's session, read by vc's date -u of 07:12Z. Three rulings on spcz's design draft, each in hv's words. (1) To vc's "keep the yabai notes as reference only": "Yes". (2) On macOS versions: "Let's just target >27.x. I can't be arsed mucking around with older versions. I'm on 27.x and this is for me, so that's good enough." (3) On the title-bar hold against the private workspace call for a window move: "I'm inclined to look into Hammerspoon's code and just copy out what it is doing." The rest is vc's wording. The draft's open question 7 is answered: spcz supports macOS 27 and later only, with no Dock shape for macOS 26 and no fixtures for it. For the window move, the spike tries Hammerspoon's method first (its workspace call, ported from its MIT source with a citation), and the title-bar hold is the fallback. (3) is a lean and not a final choice: the spike's result on macOS 27 decides, and vc puts it to hv again if Hammerspoon's method does not move a window there. It does not change arngz in 2.15.0, whose finder keeps its Dock fallback. (edited)
- hv, 27 Nov 2026, first-hand in vc's session, by vc's picker, answered before vc's date -u of 08:27Z. hv picked "Check Desks (Recommended)" as the label of Menuz's Utilities item that runs `arngz doctor`, which said "Hammerspoon". It answers hv's own words earlier in the session: "Oh, so why does it say "Hammerspoon"? We should just update the text, right?" The rest is vc's wording. ic changes Utilz's copies, opt/menuz/lib/example.yaml line 31 and help/menuz.md lines 100 and 178, in one unit with its todo 16. hv's live file is Molt-matts' config/menuz/menuz.yaml line 43, since ~/.config/menuz links there, so molt-vc's seats change and commit it. The fixture in MenuBuilderTests.swift is test data, and it stays.
- hv, 27 Nov 2026, first-hand in vc's session, by vc's picker, answered before vc's date -u of 08:37Z. It answers ST0029's design rulings D1 and D3, which dc found unanswered in its plan of 08:29Z, as one question. hv picked "Text onward (Recommended)". The rest is vc's wording. xtrct's zsh port keeps exact its stdout, its exit status on every path, the API request (model, max_tokens, system text and user text) and xtrct's own stderr lines. It does not keep exact a PDF's markdown, since the new pdf2md writes different markdown from pdfminer's, or the SDK's error text after "Error: API call failed:", or retry timing, since the port drops the SDK. When the new pdf2md is ready (ST0029's WP04), hv checks it on hv's own Talga Rd PDFs, old xtrct against new, in a run hv makes. D2, the port in zsh with curl and jq, was already answered by hv decision 35 and ST0029's objective (vc decision 79). dc writes D1 and D3 into ST0029's design as answered.
- hv, 27 Nov 2026, first-hand in vc's session, received after vc's date -u of 08:37Z. hv's words: "Ok, I want to know if I can close out, and what. If we can, let me know. And before you close, I want you to sync as-written docs to as-built code, close out any STs, WPs, and Issues. In particular, if there are parts of a WP or an Issue that have been deferred to another ST, then we should move it out of the almost done ST/WP/Issue and either put it in a new unstarted ST or WP, or make a new ST and put it in that. Either way, I want anything that is partially done to be pruned and then closed and all unfinished work moved into a future, unstarted ST or WP. Make sense? Once that is done, I want you to do an aggressive lean out of all project docs. I'm espescially interested in ensuring that we are not writing tomes in the verblocks, WIPs, or restart files, and that they ONLY have WIP or TODO items, never DONE stuff. I want to draw a line under this weeks work so I can put all done work to bed and then concentrate on devvm, ae, and the zeop/* projects. Ok?" The rest is vc's wording. Every seat stops new work: no new run, unit or Desk ask. cc prunes STca1b7f9 into spcz (ST6ae5a79baaa93e17) and closes it, and spcz stays unstarted. dc puts ST0029 back to unstarted. ic puts STb234935 back to unstarted and closes issue I669673a into it. Each seat syncs its remit's docs to the as-built code and leans them, by hv decision 21's split, and leans its board and RESUME to WIP and TODO only. vc leans intent/wip.md, intent/restart.md and hv's board, checks each change by change and lands it. hv pushes once. Then vc tells hv which sessions can close.

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
