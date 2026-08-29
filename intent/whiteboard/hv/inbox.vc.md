# inbox: vc -> hv

## (2026-08-29 13:36Z)

Two things only you can act on, plus one that needs your relay. Everything else in ST0010 has unblocked work in front of it.

**1. The `_tools` pin is written but uncommitted, and both `_tools` nodes are paused.** `_tools` HEAD is `42320af`; `native/rust/geopres/test/acceptance.sh` sits modified in that working tree. I read the diff at 13:32Z and it is complete and correct -- `--use-mock-keychain` at all four launch sites, disposable `--user-data-dir` at the two that were running against your real Chrome profile, AT12 cut from eight profile creations to one, and `chrome()` extended to 4 app paths + 6 PATH names. So the work is done and the freeze cannot advance, because committing it needs a live `_tools` session. Nothing here can reach that repo and the standing rule forbids editing it from Utilz. WP-03 cannot close and WP-04 cannot start until a sha exists.

**2. THE CUTOVER IS BROKEN, and neither repo's tests can see it.** The rename sweep changed the search-path variable to `PREZ_THEME_PATH` (`opt/prez/crate/src/theme.rs:80`). `bin/geodica_present:125` still sets `GEOPRES_THEME_PATH`, and `_tools-cc`'s recorded shim-rewrite parameters do not mention the rename. If that rewrite lands as specified, `geodica present deck.md` sets a variable prez does not read, the search path is empty, and `--theme=geodica` REFUSES -- correctly, loudly, naming an empty path, and looking exactly like the port broke the brand theme. Eight further references trail it: `bin/geodica_design:114,178`, `bin/help/geodica_present.md:20,34`, `themes/geopres/geodica/theme.css:10`.

This is a seam defect: `_tools`' suite never runs prez, our suite never runs the shim, so it is invisible on both sides until a human types the command. It must reach `_tools-cc` BEFORE their cutover commit. **The only channel to that node is you** -- there is no cross-project inbox, and every "utilz-vc ruled X" on their boards arrived by your relay. I can also deliver it as a clearly-named temp file in their tree under the external-correspondent rule, but not unannounced: say the word and I will, or relay it yourself.

**3. `geodica doctor` must report whether `utilz prez` is available** -- your estate requirement, still with no AC on any contract. `_tools-vc` put it to you rather than minting it, and it has stayed put. It is an estate AC rather than one of ours, but today it is nobody's.

Retired since the last board: CI red on `main` is fixed at `95b650a`. Still standing: 18 unpushed commits, and whether a Keychain dialog actually reached your screen at ~14:18 local -- absence of a dialog is not observable from a shell, so AT15's note records that limit rather than papering over it.
