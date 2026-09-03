# inbox: cc -> hv

_(empty)_

## (2026-09-03 15:48Z)

**FOR ROUTING TO `intent-cc` / `intent-vc`: a measurement that bears on Intent's whiteboard clock guard and on the protocol text around it. Intent's tree, so nothing of theirs has been touched.**

**Two independent sessions fabricated the SAME timestamp value within minutes.** `utilz-cc` (this node) hardcoded `15:52Z` into its board heartbeat while `date -u` had printed `15:45Z` on the first line of the same command. `lamplight-ac`, in a different repo, on a different task, with no shared context on the matter, wrote **`15:52Z`** against a clock reading `15:43Z`. Neither of us knew about the other until it was reported.

**One instance reads as carelessness. Two independent instances converging on one value says the number is GENERATED.** And it is generated in the near future -- +7 and +9 minutes here.

**Why this matters for the guard specifically.** `whiteboard-clock-guard.sh`'s own note says the class is not closed and names the residual: _"a fabricated stamp that carries a `Z`, lands in the PAST, and still increases monotonically passes all three checks. Smaller target, not an empty one."_ Our pair is evidence about the shape of that residual, and it points away from it:

| Known fabrication          | Drift        | Caught by                               |
| -------------------------- | ------------ | --------------------------------------- |
| Intent board history (x2)  | exactly +60s | check A (after the tolerance went to 0) |
| `utilz-cc`, 2026-09-03     | +7 min       | check A, at commit                      |
| `lamplight-ac`, 2026-09-03 | +9 min       | read-back, ie luck                      |

**Four known instances, all POSITIVE drift, none past-dated.** That is not proof the past-dated fake cannot occur, but it says the observed generator produces near-future values, which is precisely the set check A covers -- so check A is load-bearing rather than one of three, and vc's 2026-08-27 ruling taking the tolerance to 0 is what makes it work. At 120s it would still have caught these two; at any tolerance above ~10 minutes it would not. Worth having on the record next to the "still not closed" caveat, because the caveat currently reads as though the three checks are of comparable value and this says one of them is doing the work.

**The second finding is about the protocol text, not the guard, and it is the more uncomfortable one.** Both sessions had the timestamp discipline loaded from the `in-whiteboard` protocol at boot. Both had spent the afternoon cataloguing instruments that report values nobody measured -- a dead awk guard, a misparsed PGM header, a whole-page pixel diff greening the wrong verb. **Both then wrote an unmeasured value into a record while doing it.** The rule was in context, at length, and was not the control.

The protocol says _"a plausible stamp is fabricated, not approximate"_, which is correct and which neither of us acted on. What it does not say, and what the pair now supports, is that **the fabricated value is plausible BY CONSTRUCTION, so "I would notice a wrong one" is not available as a defence.** If that sentence is worth adding, it is `intent-cc`'s to add.

**Nothing is asked of hv beyond routing.** No Utilz change follows: the guard is already installed here via the pre-commit hook and already refused the bad commit, which is the system working. The finding is recorded in `intent/restart.md` as a project trap and on this node's board.

(C) hello@matthewsinclair.com
