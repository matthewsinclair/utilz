# Work In Progress

DOING and TODO only. Done work goes to `intent/done.md`; context to `intent/restart.md`; everything else to `intent/.history/`.

## DOING

- ST0019: design the Utilz parts of the release pipeline (its version files, the CI build of prez, the Homebrew formula) for vc's review before any code. The shared release core is Devbin project work (Devbin issue 0064), and the next Utilz release is cut by hand.

## TODO

**Threads**

- Follow-on to ST0017, if wanted: Rust `init` and `qr` for `prez showreel`.
- Crawl recedes as it rises (Star Wars pre-roll): a 3D transform in `player.html`.
- prez default look, "basic but cool enough out of the box". Needs a thread.

**Fixes**

- Close 0038 once the first CI run carrying its format step shows rustfmt ran on ubuntu-latest.
- `examples/demo.md` warns `class 'escape' has no effect`.
- `stampz`: handle mixed page geometry within one PDF (per-page overlay ranges).
- `hoist-rebase.sh`: the `AT13` postcondition uses minimum 0 against `-ge`, so it always passes. Needs ST0010 hydrated.
- Open an issue for `todo` verbs unreachable from Emacs: the bridge inserts `C-u` flags between the declared flags and the path.
- Remove the v2 artefacts under `intent/issues/CLOSED/`; issues are read with `intent issues list`.

**Blocked**

- Migrate the 101 flat AC/AT ids once Intent has a rename verb. ST0013's two are the pilot.

**Opportunistic**

- Remove em dashes. Never touch `opt/macoz/images/backgrounds/autumn-*.png` or `opt/cleanz/data/trope-indicators.txt`.
- Point each `help/<name>.md` at the command instead of a hardcoded version, as `help/utilz.md` does.
- VSCode / Zed / Vim integration families.
- Emacs bridge v2: Transient grouped menu.
