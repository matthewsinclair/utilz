# Work In Progress

DOING and TODO only. Done work goes to `intent/done.md`; context to `intent/restart.md`; everything else to `intent/.history/`.

## DOING

- ST0020: prez refuses a theme name defined twice on the search path when a caller sets `PREZ_THEME_DUPLICATES=refuse` (hv's ruling (b), for the next release, as prez 2.2.0). cc builds it; vc verifies red first and then the landing.

## TODO

**hv**

- Push main to local and upstream once ST0020 lands, and not before (hv, 14 Sep).

**Threads**

- ST0019, after ST0020 (hv: the prez check first): release Utilz through `dvb build release` and a Homebrew tap, like Intent. hv ruled on 14 Sep that the shared release core (pre-flight, version stamping, the CHANGELOG date, commit, tag, push and the release object) is Devbin project work, with Utilz as its first user (Devbin issue 0064), and that Utilz's own parts (its version files, the CI build of prez, the Homebrew formula) start in Utilz. The next Utilz release is cut by hand once more. cc drafts the design; vc reviews it before any code.
- Adopt rustfmt for the prez crate once ST0020 lands (hv, 14 Sep): `rustfmt.toml` with `tab_spaces = 2`, one reformat commit, then re-enable `fmt rust` in `bin/.devbin/config.yaml` and `check format`.
- Follow-on to ST0017, if wanted: Rust `init` and `qr` for `prez showreel`.
- Crawl recedes as it rises (Star Wars pre-roll): a 3D transform in `player.html`.
- prez default look, "basic but cool enough out of the box". Needs a thread.

**Fixes**

- `utilz doctor` prints its report to stdout (hv, 14 Sep): one redirect where the doctor verb runs, while the shared message helpers stay on stderr. File it, then fix it.
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
