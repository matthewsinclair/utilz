---
verblock: "10 Nov 2026:v1.41: matts - after 2.14.9's cut; ST0034 in flight"
---

# Work In Progress

## DOING

- dc: ST0034 (issue 0138), apply and diff agreeing about a window an app holds at its own size, on branch dc/0133b in dc's worktree. It is red on one arm, 159, and the cause is in the fix: own_sizes_into captured yq's stderr with its shape read, and yq 4.54.3's 'auto' output WARN stopped the list from matching, so no recorded size ever reached the engine. NEXT: design.md first, then the shim's yq reads given an explicit output format with stderr kept apart, a sweep of every other parsed `yq -p` capture, and an arm asserting no "is not a list" warning; then 159's driver again, then the whole ST0034 driver, with AT-03.2's base red derived and the full TAP kept. Every run is booked through devbin-vc. It lands on vc's check once the whole run reads green. hv accepted its cost, about 150 ms per apply per recorded window (vc decision 104).
- vc: ST0032, arngz's exit-code defects (issues 0133, 0134, 0135) and the desk picked from the monitors present. Still open: AC-01.4 and AC-01.5, the live path; AC-04.10, which rests on reading; and AC-05.4, the menu in Molt-matts. Check whether 0133, 0134 and 0135 can close on what 2.14.9 proved.

## TODO

- vc: the live path, and the one place arngz's own code is still unproven: `utilz use dev`, then `opt/arngz/test/acceptance.sh` in its apply and launch modes against a desk holding no app that enforces its own window size, since hv's zeophq holds Appgate (or after ST0034 lands). It is a desk booking and a run, so it is hv's or the holder's, never vc's.
- dc: ST0031/01, Utilz's side of Devbin ST0011/10's sweep: re-plan it against the vendored core, retiring tools/post-cut and tools/formula into Devbin's core, and with them vc decision 91's six findings; ST0031/02's bank lands with it. At the build, descope ST0019's AC-01.3 to ST0031 and write it there, reworded, as AC-01.5. The build re-reads ST0031/03's build_kind against the vendored app-sign (ST0031/03's design, section 4, step 4).
- ic: issue 0114, once arca_swift tags its issue 0003's fixes.
- dc: ST0029, Retire Python, parked by hv ("not a priority today"); its records are on main, its WP01 started, and no code until hv's word (vc decisions 79 and 104).
