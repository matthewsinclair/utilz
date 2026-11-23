---
verblock: "23 Nov 2026:v1.47: matts - the diagnosis run"
---

# Work In Progress

## DOING

- hv: the diagnosis run on the dev tree: `cd ~/Devel/prj/Utilz && bin/utilz use dev`; apply zeopit, unplug, apply rhad, plug back in, apply zeopit; then `utilz use brew` and a Hammerspoon reload.

## TODO

- dc: AC-53ef07aa.3, and ic: AC-eae7633d.1, from the diagnosis run's log.
- dc: ST589246c/93ea, the desk-change fix, from what the diagnosis run's log shows.

- dc: ST0031/01 and ST0031/02, after the arngz fixes and in the same release: re-plan the sweep against the vendored core, retiring tools/ci-state, tools/post-cut and tools/formula into Devbin's core, and with them vc decision 91's six findings; ST0031/02's bank lands with it. At the build, descope ST0019's AC-01.3 to ST0031 and write it there, reworded, as AC-01.5. The build re-reads ST0031/03's build_kind against the vendored app-sign (ST0031/03's design, section 4, step 4).
- devbin-cc: issue I59c806c, devbin#0326's install and use, in devbin-vc's order and after ST0031/01 lands.
- ic: issue 0114, once arca_swift tags its issue 0003's fixes.
- dc: ST0029, Retire Python, once hv lifts its hold.
