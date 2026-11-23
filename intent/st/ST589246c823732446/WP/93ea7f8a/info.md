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

How arngz orders and creates desktops when a change of desk moves desktops between displays. cc is second reader. vc adopted cc's second read (`~/Devel/scratch/utilz-cc/93ea-second-read.md`) on 23 Nov 2026, and this version folds it in. Inputs: hv's diagnosis run in `~/.local/state/arngz/arngz.log` (08:56Z to 09:01Z on 23 Nov 2026), cc's read-ahead and second read, and ST0026's measurement of 16 Oct.

## What hv's run showed

1. **com.apple.spaces lags one display change behind.** The plugged layout stood for all 85 s that hv was unplugged, through the snapshots at 0, 5 and 30 s. The unplugged layout was written only at the replug, at 08:59:24.8Z, and still stood 120 s later. So D22's rule, which needs one recorded list equal to a display's live desktops, refuses after every display change, and waiting never helps. A reattached display has no recorded list at all.
2. **Where the record is current, the live order agrees with it.** This held on every screen in every run before the unplug. It also held for the unplugged built-in: the record macOS wrote at the replug, `1 3 1431 5 423 121 6 7 1271 1442`, is exactly the live list seen while unplugged. That is the built-in's own desktops, then the visitors in their own order. 423 and 121 are full-screen spaces, at the same places in both.
3. **Visitors go home at once.** At the replug, above-left reads `1805 1271 1442` in the snapshot taken 0.17 s after the change. A replug flaps: there were eight change events in 4.1 s, from 08:59:23.761Z to 08:59:27.896Z.
4. **The ids churn.** At the unplug, macOS removed one desktop from each external, the one each was showing: 1716, which was also above-left's first, and 1586, above-right's only one. It moved above-left's others to the built-in. At the replug it made a new one for each, listed first (1805, then 1808 after a flap; and 1811), and moved 1271 and 1442 home. Over the cycle the counts held: above-left 3, above-right 1. This is one cycle.
5. **No desktop was created**, so whether com.apple.spaces records a created desktop, and when, is still unmeasured (AC-53ef07aa.3). F3 was seen once more: at 08:59:45Z the CLI killed hs as the response landed, and no ipc error followed.

## The order rule, in place of D22

Per display, from its live list (`hs.spaces.spacesForScreen`) and com.apple.spaces' lists:

- **Record current**: exactly one list holds the display's live desktops exactly. Its order is taken, as D22 does, and the log says when the live order differs. This keeps 16 Oct's state right. There the live list read `1, 3, 2588, 305`, the record `1, 3, 2588, 1733`, and ctrl+right from 2588 went to 1733: the record was right and the live list wrong (ST0026, "Measured 16 Oct 2026"; cc's second read, item 1).
- **Record stale**: no list holds them, as after any display change, on a reattached display, and after a create until macOS records the new desktop. The live order is taken, and the log says the record is stale.
- **Two lists** hold them exactly: the live order, with both lists logged. D22 refused this.
- **A lone desktop** is its own order, with or without a list, so issue 0077's refusal of a create beside it goes.
- **The one order refusal left** is an id on two displays' live lists, naming both. The CGS data should never show one; it is checked all the same. A live list that cannot be read is refused as now (unread()).
- **com.apple.spaces is never waited on**, and a stale record is never a reason to refuse. No list is chosen by its name, so the question of whether "Main" is the built-in or the primary falls away.

What guards the order, and what does not (cc's item 4):

- **Every step of a move reads back the desktop shown** (LEG.switch and LEG.carry wait for `activeSpaceOnScreen` to show the step). So a wrong order fails any move that crosses the wrong junction, by name, saying what was shown, and that op is reported failed.
- **Nothing else reads back.** A window already on the desktop the order names counts as in place, with no step (P.apply_report). discover --save writes ordinals from the order. The end-of-apply displays record reads the same order back. All three rest on the order alone, which is why the record's order is kept wherever it is current, and why the walk matters.

## Full-screen spaces (cc's item 3)

- **In the order**: a full-screen space is in the live list and in com.apple.spaces' lists like any desktop, and the rule orders it with the rest. Desk ordinals count user desktops only (P.user_spaces), so its place changes no ordinal. A move steps through it with one Move-space press, so a full-screen space the order misplaces fails a move that crosses it, at that step's readback.
- **In discover**: each full-screen window is filed under the user desktop before its space in the order (D11, plan.lua's discover), with no readback. plan leaves full-screen windows alone, so a misfiled one moves nothing, but the desk file records it under the wrong desktop.
- **Where the risk is**: 16 Oct's built-in had one full-screen space, and the live order parted from Mission Control's on that display. hv's replugged built-in has two, 423 and 121 at live positions 5 and 6, and its record is stale (8 live, while Main holds 10), so the live order places them. The built-in's walk steps through both.
- **If that walk finds the live order misplaces them**, discover files no full-screen window on a display whose order came from the live list, and names them in its notes instead, as it already does for one with no desktop before it.

## The settle, for a replug's flaps (cc's item 2)

- **Before apply observes, it waits for 5 s of quiet**, the run's flap being 4.1 s. Quiet is counted from the later of the watcher's last display change and the watcher's start. M.watch starts a watcher at the run's start whenever none is running from this tree. So after a Hammerspoon reload, or a call from another tree, the first apply waits the full 5 s and sees a flap in progress. If the watcher could not start, which its error record says, quiet is counted from the run's start.
- **It waits up to 20 s.** If the displays have not settled by then, apply refuses and changes nothing: "the displays did not settle: <n> changes in 20 s, the last at <time>", with the fix "run it again once the displays have stopped changing", which is true of a flap. Nothing is created on that path (cc's read-ahead, point 4). No window is moved or placed either, since a display still changing can move under them. cc left "go on without creates" or "refuse" to dc and vc. dc takes refuse, as the smaller and safer of the two.
- **The wait is a phase**, a timer, never a sleep inside a callback. Its point is `waiting`, with `for` set to "the displays to settle", sent once when the wait begins (ic agreed on 23 Nov 2026; progress.md at f977764f).
- **diff, which and discover do not wait.** Each run's log already records the time since the last display change (53ef07aa).

## Creates

- **The trigger is unchanged**: a display with fewer user desktops than the desk asks for gets the difference, after the settle.
- **The created wait follows the live list.** After create_space, apply observes again until every created id is on its display's live list, within the existing 3 s. It no longer waits for com.apple.spaces. That display's record is then stale until macOS records the new desktop, if it does before the next display change, so its order comes from the live list until then. The run's log shows com.apple.spaces after the creates and at the end, which answers AC-53ef07aa.3.
- **Where macOS puts a created desktop** (cc's read-ahead, point 5): the create record names its id and the live list after it. The plan's ordinal for it, have+1, is confirmed by that list or fails at the step readback.

## Surplus desktops (decision 10; cc's item 5)

- **Nothing is over against today's desks.** zeopit asks for 6, 3 and 1 desktops (main, above-left, above-right), and the displays hold 6, 3 and 1 user desktops. The built-in's 8 spaces include the two full-screen ones. hv's `discover --save zeopit --force` at 08:56:47Z, the run's first click, wrote above-left's 3 into zeopit; cc's read-ahead read zeopit at 2 before it.
- **How desks that disagree make a surplus.** At an unplug, the built-in keeps the plugged desk's main desktops and gains every external desktop but the one each was showing (4). With zeopit at 6, 3 and 1, the unplugged built-in holds 6 + 2 + 0 = 8, which is rhad's count, so rhad creates nothing. With zeopit's above-left at 2, it held 7: rhad's apply added an 8th, and after the replug that desktop was one over somewhere. This is read from one cycle, not proven.
- **The settle stops the other way to make one**: a display read mid-flap, short while its desktops are still elsewhere (cc's read-ahead, point 4). This run shows no sign that it happened (cc's second read, item 5).
- **arngz removes no desktop.** Desks share a display's desktops (rhad's 8 are zeopit's main 6 and 2 of above-left's 3), so a desktop over one desk's count is another desk's.

## cc's junction walk

- **What it decides.** The live order is taken only where the record is stale, so the walk tests it in the stale states hv can reach without unplugging, which is the replugged state:
  - **Above-left** (`1808 1271 1442`, no list of its own): 3 desktops, 2 presses. It decides whether a reattached display's new desktop comes first, as the live list says, or after the ones that came home, as a stale record's order would have it.
  - **The built-in** (8 live, while Main holds 10): 7 presses through 423 and 121. It tests where the live order puts full-screen spaces, the 16 Oct pattern.
- **Not needed**: the steady state, or any display whose record is current (the record's order is taken); the unplugged built-in, whose order macOS itself wrote at the flap; a lone desktop (above-right's `1811`).
- **How**: cc's widened `junction-walk.md` and `junction-walk.zsh`, with vc for its read before hv sees it. hv runs it once.
- **If either walk differs from the live list**, the stale branch changes before that state is relied on. It becomes either an order walk at runtime for that display (ctrl+right through its desktops, with a readback each time) or D22's refusal for that state, vc's and hv's choice. For the built-in, discover's full-screen rule above applies at once.

## Refusal text and help

help/arngz.md's "A display just attached" bullet is replaced with these points:

- arngz takes each display's desktop order from com.apple.spaces where its record is current. Where the record is not current, as after a display change (macOS rewrites the record only at the next one), arngz takes the order from the live list.
- A move fails by name where the order proves wrong. A window already in place, and discover, rest on the order alone.
- The old refusal's "wait, then run it again" goes. The settle's refusal is now the only one that says to run it again, and for a flap that is true.

## The log

- **Each display's order says where it came from**: the record, with any live disagreement, or the live list, with the record stale.
- **The padding** (on vc's word): every displays record printed com.apple.spaces' ~50 collapsed entries, mostly one id repeated. log.lua writes them as one counted line, `record collapsed: <n> entries for <k> displays no longer attached`. Each list that holds desktops is still written whole.

## Not in this WP

- **F3**, the killed hs client: seen again at 08:59:45Z, and harmless. It is with hv, through vc, at size S. The fix gives hs a short grace to exit on its own once the response has landed, and kills it only at the deadline. arngz.bats' existing hang-after-reply fake proves it. dc recommends leaving it out.
- **F4**, discover's deadline: no new data. It is with hv at two sizes. XS gives discover its own deadline, eg 180 s, which still holds Hammerspoon's main thread for the whole discover. M runs discover on a timer, as apply runs. dc recommends leaving it out, or XS if hv wants it now.
- **A check that two desks' counts agree across an unplug**, eg in `arngz doctor`: hv's call, if hv wants one.

## Files

- `opt/arngz/lib/plan.lua`: P.order_spaces takes the three cases and says which source it used; 0077's create refusal goes; unread() refuses an id on two displays' live lists.
- `opt/arngz/lib/arngz.lua`: observe keeps the order's source; the settle phase; the created wait on the live list, in place of spaces_agree; discover's full-screen rule, if the walk calls for it.
- `opt/arngz/lib/log.lua`: each display's order source; the collapsed entries as one counted line.
- `help/arngz.md`.
- Tests:
  - plan_test.lua: the order rule, from hv's lists with 423 and 121, and 16 Oct's shape.
  - engine_test.lua: the settle phase, with the watcher's state injected (a recent change, a new watcher, no watcher, and a flap that outlasts 20 s), and the created wait.
  - log_test.lua: the order's source and the counted line.
  - arngz.bats, where the refusal text is pinned.

## Acceptance (proposed)

1. Where exactly one recorded list holds a display's live desktops, observe takes that list's order, and logs it when the live order differs (16 Oct's shape). Where none does, it takes the live order and logs the record as stale (hv's unplugged and replugged lists). Where two do, it takes the live order and logs both. plan and discover refuse for none of these.
2. An id on two displays' live lists is refused, naming both. A live list that cannot be read is refused as before.
3. A move whose step reads back a desktop other than the one the order predicted fails by name, and is not reported done.
4. Full-screen spaces are ordered with the rest, and desk ordinals skip them (hv's built-in list, with 423 and 121 at positions 5 and 6).
5. apply waits for 5 s of display quiet, counted from the later of the watcher's last change and its start, before it observes. A display still changing at 20 s refuses the apply, with nothing created, moved or placed, and the changes named.
6. The created wait ends when the live list shows each new desktop, and a lone desktop can take a new one beside it.
7. help/arngz.md says the rule, what guards it, and what rests on it alone.
8. The displays records say each order's source, and write the collapsed entries as one counted line.
9. Live, on hv's dev tree: rhad applies unplugged, and zeopit applies replugged, with no order refusal. The junction walk's result is recorded, and any change it calls for is made.

## Acceptance

Acceptance Criteria for this work package are RENDERED into `ST589246c/acceptance.md`, under the `WP-93ea` heading. THAT FILE IS A GENERATED VIEW -- a row authored there is discarded by the next sync. The contract is canon in the thread's model, and the verbs write it: `intent ac new` and `intent at new` mint a row, `intent ac edit` and `intent at edit` reword or re-cite one, and `intent ac satisfy|unsatisfy|descope|rescope|withdraw|reinstate` and `intent at green|red|na` move its state. This cover never restates them.

---

_Generated by Intent v3 from the thread canon. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
