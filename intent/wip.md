# Work In Progress

DOING and TODO only. Done work goes to `intent/done.md`; context to `intent/restart.md`; everything else to `intent/.history/`.

## DOING

- ST0027 `menuz`: WP-02 (the shim) on cc's branch `st0027-wp02`, verified by vc in a worktree and fast-forwarded to main; dc lands `help/menuz.md`'s WP-02 cut at that SHA; AC-02.1 to AC-02.3 on the read, AC-01.2 then WP-01 done; cc's `--login-item` arm and the plutil note into WP-03's design; then WP-03, the app at `native/macos/Menuz`.
- 2.13.0's recorded CI verdict: the main-branch run on 01cf76d was cancelled by a later push during the core's CI wait and re-run; read `tools/ci-state 01cf76d` once both runs finish, and cut 2.13.1 only if the bytes are red.
- hv's part of 2.13.0: copy `packaging/homebrew/utilz.rb` into the tap as `Formula/utilz.rb`, `brew audit --strict matthewsinclair/utilz/utilz`, commit and push the tap.

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
