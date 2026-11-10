# ST0034 design: arngz remembers a size the app enforces

utilz-vc's design (10 Nov, read at 1401e7b3), amended by utilz-dc's critical read and agreed by vc the same day. Issue 0138. It is for 2.14.10.

## The defect

See issue 0138. `P.plan` emits a `place` op whenever `not P.frames_agree(w.frame, frame)` (plan.lua:636). A window its app holds at its own size can never agree, so diff never reads "no change" after a clean apply, and every apply re-places the window.

## Options (vc)

1. **Remember the outcome. CHOSEN.** The state lives at `${XDG_STATE_HOME:-~/.local/state}/arngz/own-sizes`, beside `current` (arngz:190, the precedent: state, not configuration, so not the catalogue).
2. **The desk records the enforced size.** Rejected. apply would have to write hv's desk files, which are configuration under hv's version control in Molt-matts.
3. **diff says "may be the app's own size" whenever only the size differs.** Rejected. diff would still never read "no change", and a genuinely mis-sized window would read the same as Appgate.

## THE AMENDMENT: a record must not seal itself (dc)

vc's draft had P.plan emit no op for a recorded window and had a `placed` readback clear the record. But a readback only comes from executing a place. The record suppresses the only op that could clear it, so once written it would never clear. An app that stops enforcing (Appgate after an update) would stay at its old size, and diff would say "in place" forever. A false record written by the fixed 150 ms readback catching a resize mid-animation would last forever too.

So P.plan emits a distinct op, `recheck`, for a window whose origin agrees and whose size matches a record:

- **diff and `P.plan_exit`** read `recheck` as in place. plan_report says "in place at the app's own size, WxH", so diff reads "no change".
- **apply** executes it exactly as a place, through `exec_place`. An `own_size` readback keeps the record and reports quietly as in place, not as a change. A `placed` readback clears the record and reports "placed". A failed readback is a failure, as for any place.

A record therefore needs no expiry. The cost is one setFrame and 150 ms per recorded window per apply. vc's default is that this is acceptable, and it goes to hv as a note, not a blocker.

## The record

- **Key and value.** The key is the bundle id and the wanted size (the cell's w x h). The value is the enforced size read back.
- **Matching.** A window matches when its origin agrees with the cell, the wanted size agrees with the key, and its size agrees with the value. Every comparison goes through `P.origins_agree` and `P.sizes_agree`, so the slack keeps its one home (ST0032's AC-01.2).
- **Only when not moving.** A record is consulted only when the window is not moving. A window on the wrong space, or at the wrong origin, is moved and placed whatever is recorded.
- **The shared-key case, named.** Two entries of one bundle in cells of the same size share a record. A resizable second window sitting at exactly the enforced size would read as in place, which is acceptable.

## Where each part lives (PFIC)

- **plan.lua (pure).**
  - `P.own_size_match(own_sizes, bundle, want, got)` decides whether a window matches a record.
  - `P.plan` takes `options.own_sizes` and emits `recheck` where it applies.
  - `P.own_sizes_after(records, results)` is the merge. An `own_size` readback of a place or recheck adds or replaces the record for its bundle and wanted size. A `placed` readback removes it. Anything else leaves the records as they were. The merge is idempotent.
  - plan_report, apply_report and `P.plan_exit` learn `recheck`, with the "in place at the app's own size" wording coming from one helper.
- **arngz.lua (engine).** `exec_place` serves `recheck` too: same gesture, same readback. The response carries the merged records from `P.own_sizes_after`.
- **arngz (shim).**
  - diff and apply read the file and pass its records to the engine request. A missing file means no records. An unreadable or malformed file is said once on stderr and treated as no records (No Silent Errors).
  - apply writes the records the engine returns, atomically (tmp then mv), and only when they changed. It holds no merge logic of its own.
  - **A value the shim parses comes from yq's stdout alone (found by WP01's booked run, 10 Nov).** The first cut read the file's shape with `yq -r -p json '...' 2>&1`. yq 4.54 prints a WARN on stderr whenever `-p` is given without `-o` ("yq default output is now 'auto'"), so the captured shape read "time=... level=WARN ...\n!!seq 1", no shape matched, and every valid record file was said to be "not a list" and used as none. The fix would never have applied on a current yq. Arm 159 caught it only at its request-side read, because its output checks are `_contains` checks and the fake engine's canned plan does not depend on the request. So the shape read names its output format (`-o yaml`), which silences that warning. It also takes stderr apart from stdout, so a warning a later yq adds cannot poison a parsed value again: stderr is said only when yq fails. Arm 159 also refutes the "not a list" warning, so the fault cannot hide behind a `_contains` again. Found in this thread's own fix, so recorded here and not filed as an issue.

## Tests, red at the base (1401e7b3) and green at the fix

- **plan_test.lua.**
  - origin agrees and the size matches the record -> `recheck`;
  - size equals the cell -> no op (as today);
  - size differs from both -> `place`;
  - origin differs -> `place` whatever is recorded;
  - moving -> move and place whatever is recorded;
  - a record for another bundle or another wanted size -> `place`;
  - plan_exit and plan_report read `recheck` as in place;
  - `own_sizes_after`: own_size adds, placed removes, failed leaves, idempotent, other keys untouched.
- **engine_test.lua (ST0033's injected hs).** A `recheck` op is executed as a setFrame with a readback, and the response carries the merged records.
- **arngz.bats (fake engine).** diff reads "no change" for a desk whose only difference is a recorded own size. apply writes the returned records atomically. An unreadable file is said once and treated as none.

Each new arm is red at the base, reasoned where the function it calls does not exist there and proven by mutation where it does.

## Acceptance (live, hv's)

`arngz apply zeophq` then `arngz diff zeophq` reads "no change" with Appgate present. That makes `acceptance.sh apply zeophq` passable, which unblocks ST0032's AC-01.4 and AC-01.5.
