# Work In Progress

DOING and TODO only. Done work goes to `intent/done.md`; context to `intent/restart.md`; everything else to `intent/.history/`.

## DOING

_(none)_

## TODO

**Next**

- Verify devbin 0.1.7's seam once `devbin-vc` commits it here: the manifest names 0.1.7 and its new source commit, `bin/devbin doctor`, `bin/devbin release check`, `bin/devbin check all`. Then hv pushes, which runs CI.
- hv to rule, no rush: a tracked home for `.git/hooks/pre-commit`. It is untracked, so issue 0060's Rust stanza protects this one checkout and ships to nobody. The choice is a source in this repository, or the formatter gate served by the Intent install the way its Claude Code hook bodies are.
- hv to decide, no rush: re-run the flaked `Rust (ubuntu-latest)` job on 2.12.0's tag run (35745443734) so its recorded CI verdict is green, or leave the red as the record of issue 0063.

**Threads**

- Follow-on to ST0017, if wanted: Rust `init` and `qr` for `prez showreel`.
- Crawl recedes as it rises (Star Wars pre-roll): a 3D transform in `player.html`.
- prez default look, "basic but cool enough out of the box". Needs a thread.

**Fixes**

- Sweep the tree for issue 0053's class: a probe whose pipeline failure kills the script under `set -e` before the guard on the next line can speak. `stampz` had three and exited 1 in silence on an unreadable PDF; every utility runs `set -euo pipefail` and most read something through a pipeline.

**Blocked**

- Migrate the 101 flat AC/AT ids once Intent has a rename verb. ST0013's two are the pilot.

**Opportunistic**

- Remove em dashes. Never touch `opt/macoz/images/backgrounds/autumn-*.png` or `opt/cleanz/data/trope-indicators.txt`.
- Point each `help/<name>.md` at the command instead of a hardcoded version, as `help/utilz.md` does.
- VSCode / Zed / Vim integration families.
- Emacs bridge v2: Transient grouped menu.
