---
verblock: "10 Nov 2026:v1.28: matts - ST0032 landed unproven; the arms wait on a P2 slot"
---

# Work In Progress

## DOING

- vc: ST0032, arngz's three exit-code defects (issues 0133, 0134, 0135) and the desk picked from the monitors present: all five WPs are landed and none has been run. Its arms are booked at rhadamanth's desk as C5B9WJ, held behind agentic-engineering's P0. A grant records only the lane, so the head cannot live on it: the holder says "head?" when it is clear, vc re-asks with the head of that moment, and the holder grants the re-ask in the same exchange and holds the place by hand. C5B9WJ's own pin goes stale meanwhile and that is expected.
- vc: do not run `utilz use dev` until C5B9WJ is green. The tree is not live on this machine, and arngz's apply reaches code no suite can.
- dc: ST0031/04, 2.14.9's cut in 0.1.20's shape: hv cuts it on hv's word, then AC-04.1 and AC-04.2 on vc's check, wp done and unclaim. On vc decision 95 that cut now carries ST0032 as well, and every run pinned on 195b1c91 is void.

## TODO

- hv: **where** in arngz's engine reading stops being sufficient, which is the cheap form of the test-surface question and the one ST0032 measured. `exec_place` had four readings by three readers with no defect, and genuinely is driven live by `acceptance.sh`'s apply mode. `exec_create_space` took four commits with a defect found after each, has no suite, and has no live proof either, against what its design claimed. So the engine needs a surface where reading is the only proof there is, not everywhere. New scope, and hv's call. ST0032's `design.md` carries the measurement.
- after 2.14.9: `apply` and `diff` disagree about a window an app holds at its own size, new in this release and recorded in issue 0133 rather than fixed. Closing it needs arngz to remember an `own_size` outcome, or a desk to record an enforced size. While it stands, `acceptance.sh apply <desk>` wants a desk with no such app, and hv's zeophq holds Appgate.
- dc: re-pin its five run drivers before any of R1, R2, R3 or the tree-scan files is booked again, deriving the tree-scan's test count from the run rather than from a number written down. The head waits on the cut's.
- dc: ST0031/01, Utilz's side of Devbin ST0011/10's sweep, after 2.14.9: re-plan it against the vendored core, retiring tools/post-cut and tools/formula into Devbin's core, and with them vc decision 91's six findings; ST0031/02's bank lands with it. At the build, descope ST0019's AC-01.3 to ST0031 and write it there, reworded, as AC-01.5. The build re-reads ST0031/03's build_kind against the vendored app-sign (ST0031/03's design, section 4, step 4).
- ic: issue 0114, once arca_swift tags its issue 0003's fixes.
- dc: ST0029, Retire Python, on hv's word: resume it, widened to dc's census of the Python outside its scope, with xtrct's port byte-exact (vc decision 79).
