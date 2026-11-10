---
verblock: "10 Nov 2026:v1.27: matts - ST0032 lands unproven; 2.14.9 carries it"
---

# Work In Progress

## DOING

- vc: ST0032, arngz's three exit-code defects (issues 0133, 0134, 0135) and the desk picked from the monitors present: all five WPs are landed and none has been run. Its arms are booked at rhadamanth's desk as C5B9WJ, held behind agentic-engineering's P0; the desk's holder asks vc for the head when it is ready to grant, and records it on the grant, so the ask keeps its place with a stale pin.
- vc: do not run `utilz use dev` until C5B9WJ is green. The tree is not live on this machine, and arngz's apply reaches code no suite can.
- dc: ST0031/04, 2.14.9's cut in 0.1.20's shape: hv cuts it on hv's word, then AC-04.1 and AC-04.2 on vc's check, wp done and unclaim. On vc decision 95 that cut now carries ST0032 as well, and every run pinned on 195b1c91 is void.

## TODO

- hv: whether arngz's engine should get a test surface. `exec_create_space` cannot be reached by any suite, which `AT-03.2` asserts deliberately using `arngz.lua` as its own control, and three landed commits in that one function were corrected by readers rather than by a run. New scope, and hv's call.
- dc: re-pin its five run drivers before any of R1, R2, R3 or the tree-scan files is booked again, deriving the tree-scan's test count from the run rather than from a number written down. The head waits on the cut's.
- dc: ST0031/01, Utilz's side of Devbin ST0011/10's sweep, after 2.14.9: re-plan it against the vendored core, retiring tools/post-cut and tools/formula into Devbin's core, and with them vc decision 91's six findings; ST0031/02's bank lands with it. At the build, descope ST0019's AC-01.3 to ST0031 and write it there, reworded, as AC-01.5. The build re-reads ST0031/03's build_kind against the vendored app-sign (ST0031/03's design, section 4, step 4).
- ic: issue 0114, once arca_swift tags its issue 0003's fixes.
- dc: ST0029, Retire Python, on hv's word: resume it, widened to dc's census of the Python outside its scope, with xtrct's port byte-exact (vc decision 79).
