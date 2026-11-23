---
verblock: "23 Nov 2026:v1.45: matts - hv's triage of the open work"
---

# Work In Progress

## DOING

- dc: arngz: read its logs for hv, then fix what hv reports, folding in the parsed captures at arngz:860, 1678, 1708, 1853 and 2034, which take yq's stderr with the value (read each from stdout alone, as own_sizes_into does), and one cap on the 600 s ARNGZ_APPLY_TIMEOUT default that each failing scheduled arm in arngz.bats waits out (as arm 63 is capped).

## TODO

- dc: ST0031/01 and ST0031/02, after the arngz fixes and in the same release: re-plan the sweep against the vendored core, retiring tools/ci-state, tools/post-cut and tools/formula into Devbin's core, and with them vc decision 91's six findings; ST0031/02's bank lands with it. At the build, descope ST0019's AC-01.3 to ST0031 and write it there, reworded, as AC-01.5. The build re-reads ST0031/03's build_kind against the vendored app-sign (ST0031/03's design, section 4, step 4).
- devbin-cc: issue I59c806c, devbin#0326's install and use, in devbin-vc's order and after ST0031/01 lands.
- ic: issue 0114, once arca_swift tags its issue 0003's fixes.
- dc: ST0029, Retire Python, once hv lifts its hold.
