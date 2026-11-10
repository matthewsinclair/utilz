---
verblock: "10 Nov 2026:v1.44: matts - ST0032 and ST0034 closed"
---

# Work In Progress

## DOING

## TODO

- dc: ST0031/01, Utilz's side of Devbin ST0011/10's sweep: re-plan it against the vendored core, retiring tools/post-cut and tools/formula into Devbin's core, and with them vc decision 91's six findings; ST0031/02's bank lands with it. At the build, descope ST0019's AC-01.3 to ST0031 and write it there, reworded, as AC-01.5. The build re-reads ST0031/03's build_kind against the vendored app-sign (ST0031/03's design, section 4, step 4).
- dc: arngz's latent yq class: the parsed captures at arngz:860, 1678, 1708, 1853 and 2034 take yq's stderr with the value, harmless while no `-p` makes yq warn; read each from stdout alone, as own_sizes_into now does.
- dc: arngz.bats's scheduled arms on ARNGZ_APPLY_TIMEOUT's 600 s default: a writer that fails costs 10 minutes per arm; cap them in one place, as arm 63 now is.
- Devbin (devbin-vc's to file): a cut's resume reads every CI run at the commit and takes the worst, so a cancelled run from a stopped attempt fails every resume; until fixed, delete each cancelled run on the release commit before resuming. A cut's macOS leg needs hv's keychain, so it runs in hv's own terminal.
- ic: issue 0114, once arca_swift tags its issue 0003's fixes.
- dc: ST0029, Retire Python, parked by hv ("not a priority today"); its records are on main, its WP01 started, and no code until hv's word (vc decisions 79 and 104).
