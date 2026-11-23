---
verblock: "23 Nov 2026:v1.48: matts - the fold before the compact"
---

# Work In Progress

## DOING

- dc: ST589246c/93ea, the desk-change fix: read hv's test run of `~/Devel/scratch/utilz-dc/st5892/run-93ea-2.sh` at a763184a, then land it on vc's word.

## TODO

- hv: the live run on the dev tree once 93ea lands: reload Hammerspoon's config; apply rhad unplugged; plug back in, then Discover and zeopit.
- dc: AC-53ef07aa.3, and ic: AC-eae7633d.1, from that live run.

- dc: ST0031/01 and ST0031/02, after the arngz fixes and in the same release: re-plan the sweep against the vendored core, retiring tools/ci-state, tools/post-cut and tools/formula into Devbin's core, and with them vc decision 91's six findings; ST0031/02's bank lands with it. At the build, descope ST0019's AC-01.3 to ST0031 and write it there, reworded, as AC-01.5. The build re-reads ST0031/03's build_kind against the vendored app-sign (ST0031/03's design, section 4, step 4).
- devbin-cc: issue I59c806c, devbin#0326's install and use, in devbin-vc's order and after ST0031/01 lands.
- ic: issue 0114, once arca_swift tags its issue 0003's fixes.
- dc: ST0029, Retire Python, once hv lifts its hold.
