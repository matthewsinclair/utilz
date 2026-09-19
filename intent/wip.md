# Work In Progress

DOING and TODO only. Done work goes to `intent/done.md`; context to `intent/restart.md`; everything else to `intent/.history/`.

## DOING

- `opt/utilz/lib/install.sh`: the comment at :341-343 says the source-tree row is resolved physically, and :345 resolves it logically. File it and fix whichever side is wrong, so it ships in 2.10.0.

## TODO

**Next, in hv's order**

- showreel: generate a video file (.mov or .mp4) of a reel. A new thread, with design.md to vc before any code and its dependency choices put to hv.
- Cut 2.10.0 by hand (hv), with prez at 2.2.0: ST0020, the install.sh fix and showreel's video export in it. cc prepares the release commit, vc gives the GO, hv tags and pushes.
- ST0019: design the Utilz parts of the release pipeline (its version files, the CI build of prez, the Homebrew formula) for vc's review before any code. The shared release core is Devbin project work (Devbin issue 0064).

**Threads**

- Follow-on to ST0017, if wanted: Rust `init` and `qr` for `prez showreel`.
- Crawl recedes as it rises (Star Wars pre-roll): a 3D transform in `player.html`.
- prez default look, "basic but cool enough out of the box". Needs a thread.

**Fixes**

- `examples/demo.md` warns `class 'escape' has no effect`.
- `stampz`: handle mixed page geometry within one PDF (per-page overlay ranges).
- `hoist-rebase.sh`: the `AT13` postcondition uses minimum 0 against `-ge`, so it always passes. Needs ST0010 hydrated.
- Open an issue for `todo` verbs unreachable from Emacs: the bridge inserts `C-u` flags between the declared flags and the path.

**Blocked**

- Migrate the 101 flat AC/AT ids once Intent has a rename verb. ST0013's two are the pilot.

**Opportunistic**

- Remove em dashes. Never touch `opt/macoz/images/backgrounds/autumn-*.png` or `opt/cleanz/data/trope-indicators.txt`.
- Point each `help/<name>.md` at the command instead of a hardcoded version, as `help/utilz.md` does.
- VSCode / Zed / Vim integration families.
- Emacs bridge v2: Transient grouped menu.
