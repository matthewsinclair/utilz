---
verblock: "10 Nov 2026:v1.42: matts - after 2.14.10's cut"
---

# Work In Progress

## DOING

- dc: ST0034 (issue 0138), released in 2.14.10; WP01, the thread and 0138 stay open on AC-01.6, hv's live run on zeophq. dc removes wt-0133b and dc/0133b at its next fold.
- vc: ST0032, arngz's exit-code defects (issues 0133, 0134, 0135) and the desk picked from the monitors present. Still open: AC-01.4 and AC-01.5, the live path; AC-04.10, which rests on reading; and AC-05.4, the menu in Molt-matts. Check whether 0133, 0134 and 0135 can close on what 2.14.9 proved.

## TODO

- vc: the live path, and the one place arngz's own code is still unproven: `utilz use dev`, then `opt/arngz/test/acceptance.sh` in its apply and launch modes against a desk holding no app that enforces its own window size, since hv's zeophq holds Appgate (or after ST0034 lands). It is a desk booking and a run, so it is hv's or the holder's, never vc's.
- dc: ST0031/01, Utilz's side of Devbin ST0011/10's sweep: re-plan it against the vendored core, retiring tools/post-cut and tools/formula into Devbin's core, and with them vc decision 91's six findings; ST0031/02's bank lands with it. At the build, descope ST0019's AC-01.3 to ST0031 and write it there, reworded, as AC-01.5. The build re-reads ST0031/03's build_kind against the vendored app-sign (ST0031/03's design, section 4, step 4).
- dc: arngz's latent yq class: the parsed captures at arngz:860, 1678, 1708, 1853 and 2034 take yq's stderr with the value, harmless while no `-p` makes yq warn; read each from stdout alone, as own_sizes_into now does.
- dc: arngz.bats's scheduled arms on ARNGZ_APPLY_TIMEOUT's 600 s default: a writer that fails costs 10 minutes per arm; cap them in one place, as arm 63 now is.
- Devbin (devbin-vc's to file): a cut's resume reads every CI run at the commit and takes the worst, so a cancelled run from a stopped attempt fails every resume; until fixed, delete each cancelled run on the release commit before resuming. A cut's macOS leg needs hv's keychain, so it runs in hv's own terminal.
- ic: issue 0114, once arca_swift tags its issue 0003's fixes.
- dc: ST0029, Retire Python, parked by hv ("not a priority today"); its records are on main, its WP01 started, and no code until hv's word (vc decisions 79 and 104).
