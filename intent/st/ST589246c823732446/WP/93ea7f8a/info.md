---
wp_id: WP-93ea
title: The desk-change fix: desktops that visit another display, from hv's diagnosis run on the dev tree
scope: S
status: WIP
---

# WP-93ea: The desk-change fix: desktops that visit another display, from hv's diagnosis run on the dev tree

## Objective

_(not yet written)_

# The desk-change fix: design

How arngz orders and creates desktops when a change of desk moves desktops between displays. Design only; no code before vc's read. cc is second reader. Inputs: hv's diagnosis run in `~/.local/state/arngz/arngz.log` (08:56Z to 09:01Z on 23 Nov 2026, vc's read and dc's), and cc's read-ahead (`~/Devel/scratch/utilz-cc/arngz-wp03-readahead.md`).

## What hv's run showed

1. **com.apple.spaces lags one display change behind.** The plugged layout stood for all 85 s that hv was unplugged, through the snapshots at 0, 5 and 30 s. The unplugged layout was written only at the replug, at 08:59:24.8Z, and still stood 120 s later. So D22's rule, which needs one recorded list equal to a display's live desktops, refuses after every display change, and waiting never helps. A reattached display has no recorded list at all.
2. **Where the record is current, the live order agrees with it.** This held on every screen in every run before the unplug. It also held for the unplugged built-in: the record macOS wrote at the replug, `1 3 1431 5 423 121 6 7 1271 1442`, is exactly the live list seen while unplugged. That is the built-in's own desktops, then the visitors in their own order.
3. **Visitors go home at once.** At the replug, above-left reads `1805 1271 1442` in the snapshot taken 0.17 s after the change. A replug flaps: there were eight change events in 4.1 s, from 08:59:23.761Z to 08:59:27.896Z.
4. **The ids churn, and the counts hold.** An unplug destroys each external's shown desktop (1716, 1586). A replug creates a new one, listed first (1805, then 1808 after a flap, and 1811).
5. **No desktop was created**, so AC-53ef07aa.3 is still unproven. F3 was seen once more: at 08:59:45Z the CLI killed hs as the response landed, and no ipc error followed.

## The rule, in place of D22

- **A display's order is its live list** (`hs.spaces.spacesForScreen`), in the order it comes. com.apple.spaces is still read and logged beside it as a cross-check. It is never waited on, and never a reason to refuse. The one order refusal left is a live list that cannot be read, which names the screen.
- **Every step of a move already reads back the desktop shown** (LEG.switch and LEG.carry wait for `activeSpaceOnScreen` to show the step). A live order that is wrong at some junction therefore fails that step by name, saying what was shown, and the op is reported failed. Nothing is reported done that the readback does not show, and the report names the order used.
- **cc's point 2** ("Main", the built-in or the primary?) falls away: no list is chosen by name.
- **cc's point 5**: an id on two screens' live lists is refused, naming both. The CGS data should never show one; it is checked all the same. Issue 0077's lone desktop no longer needs a record.

## The settle, for a replug's flaps

- **Before apply observes, it waits for quiet displays**: no display change for 5 s, the run's flap being 4.1 s. It reads the watcher's last change, and waits up to 20 s. It then goes on, and logs that the displays did not settle. With no watcher yet (the first call after a Hammerspoon reload), it goes on and logs "not watched".
- **The wait is a phase**, a timer, never a sleep inside a callback. Its point is `waiting`, with `for` set to "the displays to settle". That is a new value of an existing field, which ic's toast shows as text; dc confirms it with ic before code.

## Creates

- **The trigger is unchanged**: a display with fewer live desktops than the desk asks for gets the difference. It is safe now: visitors are home at once (3), and the settle covers the flap. cc's point 4's guard is then the settle itself.
- **The created wait changes.** It waits for the live list to show the new desktop, which it already does by the time exec_create_space returns. It no longer waits for com.apple.spaces, which records nothing until the next display change (1). So AC-53ef07aa.3 is reworded to the live list (agreed by vc), and proven on the first apply that creates.
- **Surplus desktops** (hv decision 10 names them). The settle prevents new surplus: apply no longer reads a display that is still flapping, which is the one moment a display could read short and so get a desktop it does not need. arngz removes no desktop, because desks share a display's desktops: rhad's 8 on the built-in hold zeopit's 6, so a desktop surplus to one desk is another desk's. The surplus already there stays. Removing it is hv's choice, by hand in Mission Control.
- **Where macOS puts a created desktop** (cc's point 5): the create record names its id and the live list after it. The plan's ordinal for it, have+1, is confirmed by that list or refused by the step readback.

## cc's junction walk: needed where no record backs the live order

- **Why it is needed at all** (cc): D22's 16 Oct counterexample came from `hs.spaces.allSpaces()`, which is `spacesForScreen` for each screen (Hammerspoon's spaces.lua:397). So the live order has disagreed with ctrl+right once before: live read `1, 3, 2588, 305`, the record `1, 3, 2588, 1733`, and ctrl+right from 2588 went to 1733. In hv's run every record macOS wrote equals the live order (2), but a state no record covers is unproven.
- **Needed, in the replugged state, which hv can walk without unplugging:**
  - Above-left: `1808 1271 1442`, with no list of its own at all.
  - The built-in: 8 live, while Main still holds 10 (cc).
- **Not needed:** the steady state, or the unplugged built-in (2), whose order macOS itself wrote at the flap. Nor a display of one desktop (above-right `1811`), which has no order.
- **Which walk decides** (cc's sharpening): taking a stale record's order for the ids it holds, with the rest in live order, agrees with the live order everywhere but the replugged above-left. There the live order puts the new 1808 first, and that composed order puts it last. So above-left's walk, 3 desktops and 2 presses, decides between the two. The built-in's walk, 7 presses, cannot decide between them. It tests the live order they both rest on, which 16 Oct's counterexample, also on the built-in, once broke.
- **How:** cc widens `junction-walk.md` to walk any display by its UUID, with no visitors needed. vc reads it before hv sees it, and hv runs it once.
  - If Mission Control's order agrees with the live list on both displays, the rule stands as written, and the step readbacks guard every later state.
  - If it differs, this design adds an order walk for a display that has just reattached: ctrl+right through its desktops, with a readback each time, before anything is moved there. arngz then measures the order itself, in the state that needs it.

## Refusal text and help

help/arngz.md's "A display just attached" bullet is replaced. arngz takes each display's desktops in the order macOS lists them now. com.apple.spaces, which macOS rewrites only at the next display change, is logged and never waited on. The old refusal's "wait, then run it again" goes.

## Not in this WP

- **F3**, the killed hs client: seen again at 08:59:45Z, and harmless. Put to hv, through vc, with its size: S. The fix gives hs a short grace to exit on its own once the response has landed, and kills it only at the deadline, with arngz.bats' existing hang-after-reply fake proving it. dc recommends leaving it out.
- **F4**, discover's deadline: no new data. Put to hv with two sizes. XS: discover's own deadline, eg 180 s, which still holds Hammerspoon's main thread for the whole discover. M: discover runs on a timer, as apply does, so Hammerspoon stays free; that touches the engine's and the CLI's scheduled lists, discover's path, and its arms. dc recommends leaving it out, or XS if hv wants it now.
- **The surplus desktops already on hv's displays**, which stay (see Creates).

## The log's padding (in this WP, on vc's word)

Every displays record printed com.apple.spaces' ~50 collapsed entries, mostly one id repeated. log.lua now writes them as one counted line: `record collapsed: <n> entries for <k> displays no longer attached`. Each list that holds desktops is still written whole.

## Files

- `opt/arngz/lib/plan.lua`: P.order_spaces becomes the live order; unread() keeps the refusal for a live list that cannot be read.
- `opt/arngz/lib/arngz.lua`: observe; the settle phase; the created wait; the report's words on the order.
- `opt/arngz/lib/log.lua`: the collapsed entries written as one counted line.
- `help/arngz.md`.
- Tests: plan_test.lua (the order rule, from the lists in hv's run); log_test.lua or engine_test.lua (the settle phase, with the watcher's state injected); arngz.bats where the refusal text is pinned.

## Acceptance (proposed)

1. After a display change, with com.apple.spaces still at the previous layout, observe orders each display by its live list, and plan does not refuse for order. Tested with the lists from hv's run.
2. A live list that cannot be read is still refused, naming the screen, and so is an id on two screens' lists.
3. A step whose readback shows a desktop other than the one the live order predicted fails its op by name, and nothing is reported done.
4. apply waits for 5 s of display quiet, up to 20 s, before it observes. It logs the wait, and goes on with a note when the displays do not settle or are not watched.
5. The created wait ends when the live list shows the new desktop.
6. help/arngz.md says the rule.
7. Live, on hv's dev tree: rhad applies unplugged, and zeopit applies replugged, with no order refusal. The junction walk's result is recorded.
8. The displays records write com.apple.spaces' collapsed entries as one counted line, and every list that holds desktops whole (log_test.lua).

## Acceptance

Acceptance Criteria for this work package are RENDERED into `ST589246c/acceptance.md`, under the `WP-93ea` heading. THAT FILE IS A GENERATED VIEW -- a row authored there is discarded by the next sync. The contract is canon in the thread's model, and the verbs write it: `intent ac new` and `intent at new` mint a row, `intent ac edit` and `intent at edit` reword or re-cite one, and `intent ac satisfy|unsatisfy|descope|rescope|withdraw|reinstate` and `intent at green|red|na` move its state. This cover never restates them.

---

_Generated by Intent v3 from the thread canon. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
