# Work In Progress

DOING and TODO only. Done work goes to `intent/done.md`; context to `intent/restart.md`; everything else to `intent/.history/`.

## DOING

- ST0019: release Utilz through `dvb build release` and a Homebrew tap, like Intent. cc drafts the design; vc reviews it before any code.

## TODO

**hv**

- Rule ST0019's question 4: whether the shared release steps (pre-flight, version stamping, tag, push, release object) move into devbin itself, which is Devbin project work, or stay a Utilz-owned command.
- Decide whether `utilz doctor` should write its results to stdout rather than stderr.
- Decide whether to adopt rustfmt for the prez crate: add `rustfmt.toml` (`tab_spaces = 2`), one reformat commit, then re-enable `fmt rust` in `bin/.devbin/config.yaml`.

**Threads**

- Follow-on to ST0017, if wanted: Rust `init` and `qr` for `prez showreel`.
- Crawl recedes as it rises (Star Wars pre-roll): a 3D transform in `player.html`.
- prez default look, "basic but cool enough out of the box". Needs a thread.

**Fixes**

- `examples/demo.md` warns `class 'escape' has no effect`.
- `stampz`: handle mixed page geometry within one PDF (per-page overlay ranges).
- `hoist-rebase.sh`: the `AT13` postcondition uses minimum 0 against `-ge`, so it always passes. Needs ST0010 hydrated.
- Open an issue for `todo` verbs unreachable from Emacs: the bridge inserts `C-u` flags between the declared flags and the path.
- Remove the v2 artefacts under `intent/issues/CLOSED/`; issues are read with `intent issues list`.
- Verify that CI's macOS leg runs bats under bash 3.2. The workflow installs no other bash, but the runner image's own bash has not been read.

**Blocked**

- Migrate the 101 flat AC/AT ids once Intent has a rename verb. ST0013's two are the pilot.

**Opportunistic**

- Remove em dashes. Never touch `opt/macoz/images/backgrounds/autumn-*.png` or `opt/cleanz/data/trope-indicators.txt`.
- Point each `help/<name>.md` at the command instead of a hardcoded version, as `help/utilz.md` does.
- VSCode / Zed / Vim integration families.
- Emacs bridge v2: Transient grouped menu.
