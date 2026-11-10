---
verblock: "10 Nov 2026:v1.40: matts - folded for hv's compact; hold for a move, then vc annotates"
---

# Work In Progress

## DOING

- vc: ST0032, arngz's three exit-code defects (issues 0133, 0134, 0135) and the desk picked from the monitors present. NEXT, after hv's move (vc decision 101): write each of its fifteen live test rows' ids beside its arm with the thread named, `AT-01.1 (ST0032)`, as comments renaming no test, on top of d7047f70's arngz.bats. AT-03.2 gets none, since it covers a withdrawn criterion. Comment-only, so no fresh mutation run (vc decision 98); dc checks it by change and it is committed through commit-src-checked.sh. That clears the only thing the contract is blocked on now: 12 rows whose cited file lacks the literal id, with the lint's four passes false, on ST0026's and ST0028's numbers in the same files. Fifteen of the sixteen test rows are mutation-proven (slot PDY9E2); AT-03.2 was not, and its AC-03.2 is withdrawn on hv's word (vc decision 100). Still open after the cut and not closed by it: AC-01.4 and AC-01.5, the live path; AC-04.10, which rests on reading; and AC-05.4, the menu in Molt-matts.
- dc: ST0031/04, 2.14.9's cut in 0.1.20's shape: hv cuts it on hv's word, then AC-04.1 and AC-04.2 on vc's check, wp done and unclaim. On vc decision 95 that cut carries ST0032 as well, and on decisions 96 and 97 it waits on the arms going green and on dc's driver for `exec_create_space`; every run pinned on 195b1c91 is void. dc holds its close-out and its five drivers on that, as its hold 33.
- dc: ST0033, the driver for `exec_create_space` (vc decision 97), is LANDED at d7047f70 with its records at 76cf5873 and PASSES 6 of 6, every one of its ten arms seen red under its own mutation. Issues 0136 and 0137 are folded into it and landed. ST0033, 0136 and 0137 close after the cut's full run proves them, not before: both fixes live in test_helper.bash, which 35 suites load and only 2 have run against. dc's hold 33 waits on hv naming the cut's head.

## TODO

- after 2.14.9: `apply` and `diff` disagree about a window an app holds at its own size, new in this release and recorded in issue 0133 rather than fixed. Closing it needs arngz to remember an `own_size` outcome, or a desk to record an enforced size. While it stands, `acceptance.sh apply <desk>` wants a desk with no such app, and hv's zeophq holds Appgate.
- vc: the live path, after the cut or on hv's word, and the one place arngz's own code is still unproven: `utilz use dev`, then `opt/arngz/test/acceptance.sh` in its apply and launch modes against a desk holding no app that enforces its own window size, since hv's zeophq holds Appgate. It is a desk booking and a run, so it is hv's or the holder's, never vc's.
- vc: CI's Lua 5.4 leg for plan_test, which the local green does not speak to: lua5.4 is absent on this machine and both arms ran under 5.5.1. It is proven by the cut's CI run, not by another local one.
- vc: once vc's id comments land, the ONE full suite run at that head. It is the cut's own run and hv's, and it covers dc's landed change, issues 0136 and 0137, and the comments together. Then hv names the head the cut is taken from.
- dc: re-pin its five run drivers before any of R1, R2, R3 or the tree-scan files is booked again, deriving the tree-scan's test count from the run rather than from a number written down. The head waits on the cut's.
- dc: ST0031/01, Utilz's side of Devbin ST0011/10's sweep, after 2.14.9: re-plan it against the vendored core, retiring tools/post-cut and tools/formula into Devbin's core, and with them vc decision 91's six findings; ST0031/02's bank lands with it. At the build, descope ST0019's AC-01.3 to ST0031 and write it there, reworded, as AC-01.5. The build re-reads ST0031/03's build_kind against the vendored app-sign (ST0031/03's design, section 4, step 4).
- ic: issue 0114, once arca_swift tags its issue 0003's fixes.
- dc: ST0029, Retire Python, on hv's word: resume it, widened to dc's census of the Python outside its scope, with xtrct's port byte-exact (vc decision 79).
