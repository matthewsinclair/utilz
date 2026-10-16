# Work In Progress

DOING and TODO only. Done work goes to `intent/done.md`; context to `intent/restart.md`; everything else to `intent/.history/`.

## DOING

- ST0026 `arngz`: land the engine's post-launch settle and observe's nil-element guard (cc), re-run the AC-05.4 and AC-05.5 hand checks with hv's hands off, then WP-06's docs (help, README, CHANGELOG) and the close estate run.
- ST0027 `menuz`: the rubber-duck with hv on design.md's eleven questions, record D1 to D11, close WP-01; then WP-02, the shim.
- After Intent 0605 ships: `intent sync --to-store ST0027` (design.md into the store, its drafted-criteria section out) and cc's ST0026 design notes.
- Run `opt/utilz/test/install_e2e.bats` from the primary checkout before 2.13.0 is cut.

## TODO

**Threads**

- Follow-on to ST0017, if wanted: Rust `init` and `qr` for `prez showreel`.
- Crawl recedes as it rises (Star Wars pre-roll): a 3D transform in `player.html`.
- prez default look, "basic but cool enough out of the box". Needs a thread.

**Fixes**

- Issue 0066: `mermaid: ture` in a prez deck reads as off with no warning; hv says whether `mermaid:` takes the words `numbering:` takes.
- Sweep the tree for issue 0053's class: a probe whose pipeline failure kills the script under `set -e` before the guard on the next line can speak. `stampz` had three and exited 1 in silence on an unreadable PDF; every utility runs `set -euo pipefail` and most read something through a pipeline.

**Blocked**

- Migrate the 101 flat AC/AT ids once Intent has a rename verb. ST0013's two are the pilot.

**Opportunistic**

- Remove em dashes. Never touch `opt/macoz/images/backgrounds/autumn-*.png` or `opt/cleanz/data/trope-indicators.txt`.
- Point each `help/<name>.md` at the command instead of a hardcoded version, as `help/utilz.md` does.
- VSCode / Zed / Vim integration families.
- Emacs bridge v2: Transient grouped menu.
