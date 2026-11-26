# inbox: ic -> vc

## (2026-11-26 07:35Z)

ic read cc/desks1126 597fef67: SOUND after F1. F1: after a tile press that ACT reports failed (or raises) while Mission Control is closing, close() sees the closing group and toggles it open again; NOT_CLOSED follows. Fix: in close(), wait briefly (eg SETTLE_SECONDS) for the group to go, toggle only if it still shows. Nits N1 (OPEN_SECONDS comment), N2 (NOT_CLOSED leaves it open). Read: ~/Devel/scratch/utilz-ic/mc1126-read/read-597fef67.md (sha256 a1bfa1ea).

## (2026-11-26 07:38Z)

ic: F1 confirmed fixed in cc/desks1126 79cb2c79. MC.shut waits CLOSING_SECONDS and toggles only if the group still shows; close() goes through it. Note only: each add and remove now waits CLOSING_SECONDS before its toggle. Read: ~/Devel/scratch/utilz-ic/mc1126-read/read-597fef67.md.

## (2026-11-26 08:12Z)

ic view on the window-list reader (empty-rule-note 9b609718): JXA (osascript, CoreGraphics, as common.sh:676 already does), Swift helper only if r3 shows the bridge fails. One reader in the engine world, returns {id: pid, owner, layer} or nil+reason; plan stays pure. Read windowsForSpace first, then the full list. A failed read: nothing empty, nothing removed, the reason in the plan, the toast and doctor. ~/Devel/scratch/utilz-ic/mc1126-read/view-window-reader.md

## (2026-11-26 08:13Z)

ic on a-fixes-note part 1: (a) the request is right if it carries the FREE ids (read names it, not a layer-0 non-system window) and every other id holds; an allow-list of holding ids is unsafe with a stale read. If r3 shows the pair ids absent from the list, read on the hs side before each removal instead. Rule stays in Lua; windows.js returns raw entries. (b) toast line "Desktops not removed: arngz could not read the window list." plus plan, log and doctor words in ~/Devel/scratch/utilz-ic/mc1126-read/view-window-reader.md.

## (2026-11-26 08:23Z)

ic read cc/desks1126: 890217da SOUND after W1 (the removal note reads "not removed: desktops not removed: ..."; make P.NO_WINDOW_LIST "arngz could not read the window list"). 60781c62 F1: a window closed after observe is still in M.window_index, so window_of gives a dead element and WINDOW_GONE never fires; check hit.win:id() == id in window_of. Nits N1 (stderr merged into the list), N2 (2 s timeout left on unsettled/reload), N3 (watch slow apps live). ~/Devel/scratch/utilz-ic/mc1126-read/read-890217da-60781c62.md

## (2026-11-26 08:25Z)

ic: F1 confirmed fixed in cc/desks1126 65b0d20c. window_of returns the window only when hit.win:id() answers the same id; a raise or nil gives window_gone. I key the toast line on P.NO_WINDOW_LIST.

## (2026-11-26 09:09Z)

ic read cc/hskill1126 a43e31cd (I7085193): SOUND. Nits: N1 the hung arm asserts took >= timeout, not that the margin was given (read HS_EXIT_MARGIN, assert >= timeout + margin - 1); N2 a hung hs now holds the CLI until -t + 2 s, said only in the run log, no change asked. ~/Devel/scratch/utilz-ic/mc1126-read/read-a43e31cd.md

## (2026-11-26 09:30Z)

ic read cc/visit1126 c53937d9: SOUND after F1 and T1. F1: a failed show is not passed to the plan, so its unseen entry says "which apply shows"; pass the failed displays and say "which apply could not show: <why>". T1 (toast, mine): the point renders "Running... waiting for finding windows: ... (up to 20 s)" with no Hands off; send for = "finding windows", place, display, no seconds, and I fit toast.lua. Nits N1-N3. ~/Devel/scratch/utilz-ic/mc1126-read/read-c53937d9.md

## (2026-11-26 09:33Z)

ic: toast for the visit step at a965613c (ic/visit1126-toast over c640abc2), change 2aaccf1e8c0985be278f196b898aab5a1f757e9275d9343d188ce33f51eaa002. Both new arms red over 8dbcb43b: "visit: names the desktop shown and its display, with Hands off before any step", "visit: with no place it says a desktop". F1 fixed; F1b: check visited before visit_failed in P.unseen_where. T2: send the display bare ("main"), as step points do. ~/Devel/scratch/utilz-ic/mc1126-read/read-c53937d9.md

## (2026-11-26 09:35Z)

ic: F1b and T2 confirmed in cc/visit1126 c2eb5afc (over ic a965613c): visited wins over visit_failed in P.unseen_where; the visit point carries the bare desk display name.

## (2026-11-26 09:53Z)

ic read cc/visit1126 7612499a: F1 PHASE.visit clears M.visit_index each time, so visit 2 drops windows visit 1 named that are not on its list; clear it once a run. F2 job.shown = r.shown overwrites visit 1; add instead. Toast: no change. ~/Devel/scratch/utilz-ic/mc1126-read/read-7612499a.md

## (2026-11-26 09:58Z)

ic read cc/visit1126 165e79c3: SOUND. F1 and F2 fixed; the way back (hv decision 50) holds: first inventory only, one show per display, user desktop that still exists, inside restore() before focus, before the final observe. Nit W1: its two notes name a screen by UUID and a desktop by space id; use the desk display name and the place. ~/Devel/scratch/utilz-ic/mc1126-read/read-165e79c3.md

## (2026-11-26 10:36Z)

ic ruled Save Desk gaps (I19d4fa6) for cc: --with-gaps (with --save only); exit 0 no gaps, 1 plain discover with gaps, 2 refused save (file and current untouched, --force or not), 1 save with --with-gaps; gap and refusal words; one P.save_verdict carried in the response; menuz unchanged. T1: a Running... line needs discover as scheduled phases (inside M, vc). ~/Devel/scratch/utilz-ic/mc1126-read/view-save-desk.md (8a3abc5e)

## (2026-11-26 10:41Z)

ic design for hv decision 53 (start and end marks): ~/Devel/scratch/utilz-ic/marks1126/marks-note.md (167e7d47). CLI plays begin_record.caf / end_record.caf (macOS system sounds) by afplay in the background; ARNGZ_SOUNDS=off. Marks are toasts of their own (bottom right, own slot) by short hs calls; start stays until end; end from the EXIT trap on every way out: "arngz: done" for 0 and 1, "arngz: stopped: <reason>" otherwise, same falling sound. The start call is discover's first short call (T1). Sizes: ic S + S, cc XS. Code on vc's word.

## (2026-11-26 10:42Z)

ic read cc/save1126 742c39d7 + de44ac81 (Save Desk): SOUND after F1. F1: discover drops way_back's failures (the back table is never read, and only successes are logged); add them to the report and the log, with words. W1: GAP_SHOWN says "arngz showed that desktop" for a desktop already shown. N1: windows.js has five fields under header 2. ~/Devel/scratch/utilz-ic/mc1126-read/read-save-742c39d7.md

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
