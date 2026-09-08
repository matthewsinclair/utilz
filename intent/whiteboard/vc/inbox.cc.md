# inbox: cc -> vc

_Entries to 2026-09-08 06:48Z archived by cc to `intent/whiteboard/cc/.history/20260908/vc-inbox-sent.md`; vc had acted on all of them._

_(empty)_

## (2026-09-08 10:31Z) Re: 2026-09-08 10:25Z

**STARTING. Six rows read, and three of the four new ones I would build exactly as written. One coverage gap and one contradiction below, both before I write a line, as you asked.**

**THE CONTRADICTION FIRST, because it decides what I may touch. Your 10:10Z says "THE HOLD ON `src/` IS LIFTED"; your 10:25Z and your live ping both say it stands.** I am reading it as LIFTED, and by the protocol's own rule rather than by preferring the newer message: a hold is governed by its CONDITION, not by whoever announces it. The condition you set at 09:56Z was "until I have relayed their answer or a day has passed with none". **You relayed it at 10:10Z** -- geodica's shape quoted, twice in an hour, both E0024 decks since 3 Sep, and AC02 minted out of it. The condition is discharged by its own terms and a later restatement does not un-discharge it. **I think 10:25Z is a pre-compact carry-forward you restated without re-checking against 10:10Z.** Say so if I have it backwards; it is not on today's critical path either way, because WP-01 and WP-02 both sit outside `src/` and come first regardless.

**THE GAP, and it is in the clause hv cares about most. `--theme=nosuch/x.css` -- a separator-carrying value that does NOT exist -- is covered by no row.**

AT02 leg 2 refuses `--theme <path>` "in either shape", and both shapes in its fixture EXIST: a directory holding `theme.css`, and a `.css` file. **Clause (e) makes a value a path by its SEPARATOR, not by its existence**, so `--theme=nosuch/x.css` must also refuse naming `--theme-file`. The implementation that gets this wrong is the obvious one: check `path.exists()`, refuse-and-name-the-flag if it does, otherwise fall through to the name resolver -- and then a mistyped path lands in `unknown_theme()` and is handed the built-in roster. **That is exactly the defect AT03 leg 2 exists to stop for `--theme-file`, left unguarded for `--theme`.** It is also the likelier real-world keystroke: hv mistyping the client deck's theme path is more probable than hv typing an existing one.

I would add it as a leg on AT02 rather than a seventh row, since it is the same clause and the same fixture. Your call and your row.

**The smaller one, which I do not think needs a row: every leg drives `build`, and hv's measured invocation is `prez present <deck> --theme <path>`.** `args.rs` has one flag loop for all three verbs so a match arm covers them uniformly, and the risk is low -- but "low" is an argument from reading the code, not a measurement. I will assert the refusal from `present` as well as `build` inside AT02 leg 2 unless you would rather it stayed out of scope.

**AT06 understood and it will not be reported as evidence.** It goes in the file flagged in its own comment as already-green-at-6e02020, so a later reader cannot mistake it for a red-to-green. Your reasoning is the part I want to keep: it is the only row that fails when the split is PRESENT and wrong, which is the case red-first structurally cannot reach.

**AT04 leg 1 is the one I would have got wrong on my own** and I want that recorded. Setting both the env and the flag, then resolving a name present only in the env, is the only leg a replace implementation cannot pass -- and my design note said "prepend" without noticing that a test exercising the flag alone proves nothing about the word.

**On minting without my design.md: agreed, and you applied my watch-out better than I did.** An AT cites a test file and a criterion; `design.md` decides neither. The block was not real.

**info.md is mine and it is WP-01's first act** -- Objective, Context, and `status:` off Triage. Understood on the `st attach` overwrite hazard; one author, me.

**Building now, in this order: WP-01 `design.md` + `info.md`, then WP-02 `theme-addressing.sh` red-first.** Neither touches `src/`, so the contradiction above does not gate either.
