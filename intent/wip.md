# Work In Progress

DOING and TODO only. Done work goes to `intent/done.md`; context to `intent/restart.md`; everything else to `intent/.history/`.

## DOING

- hv is AFK and vc has the pen (16 Oct, decision 20 on vc's board): drive ST0027 `menuz` and ST0028 to the 2.14.0 cut; cc and dc take instructions from vc; compiles in windows booked with intent-vc; the Ubuntu leg on kovacs; vc pushes main.
- ST0027 WP-06, the first-use fixes (D13), cc's on `st0027-wp06`: the one-route `--notify` arm with the text in `MENUZ_NOTICE`, the first-launch placement line, the drawn mark rasterised by `bin/devbin macos app-icons` (dc, landed), the default glyph; vc verifies the SHA in a worktree, lands, pushes, rebuilds the dev build under `~/.local/state`, runs `opt/menuz/test/notice-handrun.sh` (AC-06.4), mints AT-06.1 to AT-06.4 (`tmp/vc-st0026/st0027/mint-at06.sh`), rewrites AT-04.4's note; dc's help lines (AC-06.5) land after the app.
- ST0027 WP-05, after WP-06: cc's shim verbs, the keg install and the CI job; dc's signing half of `bin/devbin macos` and `macos.bats`, then the README section, the CHANGELOG entry and `docs/releasing.md`; the install hand run; AC-05.2's logout is hv's (edit the AC to what is measurable if hv is still away); check all and the estate on the closing SHA.
- ST0028 (dc, ad2da79, verified and pushed): `wp done` and `st done` at the close, AC-01.4 folded into the estate run on the release SHA.
- The cut: `st done` both, dehydrate, `restart.md`, then `bin/devbin release --minor` on hv's word (or vc's under decision 20), nothing pushed while step 11 waits on CI; the tap bump for 2.14.0; `Menuz.app.zip` published after hv's `bin/devbin macos store-creds`.
- hv's keypresses: the 2.13.0 tap commit and push (the formula is copied into the tap clone and audited clean, 16 Oct 19:5xZ; the push was refused to vc by the permission layer); `.claude/settings.json`'s advisory (`intent claude upgrade --apply`); `store-creds`.

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
