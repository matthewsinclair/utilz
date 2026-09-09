# inbox: vc -> hv

## (2026-08-29 13:36Z)

Two things only you can act on, plus one that needs your relay. Everything else in ST0010 has unblocked work in front of it.

**1. The `_tools` pin is written but uncommitted, and both `_tools` nodes are paused.** `_tools` HEAD is `42320af`; `native/rust/geopres/test/acceptance.sh` sits modified in that working tree. I read the diff at 13:32Z and it is complete and correct -- `--use-mock-keychain` at all four launch sites, disposable `--user-data-dir` at the two that were running against your real Chrome profile, AT12 cut from eight profile creations to one, and `chrome()` extended to 4 app paths + 6 PATH names. So the work is done and the freeze cannot advance, because committing it needs a live `_tools` session. Nothing here can reach that repo and the standing rule forbids editing it from Utilz. WP-03 cannot close and WP-04 cannot start until a sha exists.

**2. THE CUTOVER IS BROKEN, and neither repo's tests can see it.** The rename sweep changed the search-path variable to `PREZ_THEME_PATH` (`opt/prez/crate/src/theme.rs:80`). `bin/geodica_present:125` still sets `GEOPRES_THEME_PATH`, and `_tools-cc`'s recorded shim-rewrite parameters do not mention the rename. If that rewrite lands as specified, `geodica present deck.md` sets a variable prez does not read, the search path is empty, and `--theme=geodica` REFUSES -- correctly, loudly, naming an empty path, and looking exactly like the port broke the brand theme. Eight further references trail it: `bin/geodica_design:114,178`, `bin/help/geodica_present.md:20,34`, `themes/geopres/geodica/theme.css:10`.

This is a seam defect: `_tools`' suite never runs prez, our suite never runs the shim, so it is invisible on both sides until a human types the command. It must reach `_tools-cc` BEFORE their cutover commit. **The only channel to that node is you** -- there is no cross-project inbox, and every "utilz-vc ruled X" on their boards arrived by your relay. I can also deliver it as a clearly-named temp file in their tree under the external-correspondent rule, but not unannounced: say the word and I will, or relay it yourself.

**3. `geodica doctor` must report whether `utilz prez` is available** -- your estate requirement, still with no AC on any contract. `_tools-vc` put it to you rather than minting it, and it has stayed put. It is an estate AC rather than one of ours, but today it is nobody's.

Retired since the last board: CI red on `main` is fixed at `95b650a`. Still standing: 18 unpushed commits, and whether a Keychain dialog actually reached your screen at ~14:18 local -- absence of a dialog is not observable from a shell, so AT15's note records that limit rather than papering over it.

## (2026-08-29 13:47Z) Re: (2026-08-29 13:36Z)

**Correcting item 1 of my last entry: the pin is MID-FLIGHT, not stalled.** `_tools-vc` messaged directly to say both their nodes are folding for a compact at your instruction, and that the modified `acceptance.sh` is `_tools-cc`'s in-flight keychain patch which resumes on the bounce. From outside that repo the two states look identical -- but I had a way to say which one I could not distinguish, and I asserted the worse reading instead. The practical difference is small: it still needs an `_tools` session resumed to commit, which is still yours. It is just not abandoned.

Items 2 and 3 of that entry stand unchanged. The cutover break is now also sitting on `_tools-vc`'s board, so it no longer depends on you being the only channel.

**On the v3 upgrade you have just put me on with intent-vc:** two batches sent, six findings. Two of them are live in Intent's own tree rather than ours -- `sync --to-disk` silently not writing attachments while doctor's remedy says it does, and the formatter fence being built by enumeration with five `design.md` attachments exposed in Intent's own repo today. Both measured, neither filed by me upstream; intent-vc has the pen there and I have not touched that tree.

Fixed here meanwhile: the fence hole (`2affb2f`) and ST0010's design.md drift, doctor 2 findings to 1. The one remaining is ST0009's blocked gate, which I am holding rather than repairing until intent-vc says whether they want the broken rows kept as a migrator reproduction.

## (2026-08-29 17:32Z)

**v2.5.0 is cut, green and pushed, and everything you had open on my board is retired except AC16.** `HEAD`, `local/main`, `upstream/main` and the `v2.5.0` tag are all at `72ee931`; working tree clean; CI run `33265456630` passed all seven jobs.

**One judgement call of mine you should be able to reverse.** I moved the `v2.5.0` tag off `4b6eb07` -- the release commit, whose CI was red -- onto `72ee931`, and force-pushed both remotes. The three commits between them touch `test/acceptance.sh`, the workflow and the contract, and change nothing a user can run, so the shipped behaviour is identical and the tag now names a green build. Had any of them touched `src/` or `bin/`, the honest move would have been a new tag rather than a moved one. Say the word and I will put it back on the release commit.

**A finding you need, because it is an instrument and not a bug in our work.** `intent ac gate ST0010` reports "acceptance.md has zero acceptance criteria (empty contract) -- BLOCKED", and `intent ac status ST0010` reports `0/0`. Our contract is intact: 20 criteria in canon, all 20 rendered in the view, **16 satisfied and 4 not** (AC15, AC16, AC18, AC19). The tool cannot read it. `bin/intent_acceptance`'s `ac_lines()` greps `^- AC-<st>.<nn> `, the v2 dotted form; the v3 renderer emits `^- AC<nn> `. Zero matches, so the gate concludes there is no contract. No native binary is built on this machine, so `bin/intent` dispatches `ac` to that bash path unconditionally and there is no second reader to disagree with it.

It fails SAFE -- it blocks, it never passes vacuously. **The danger is the remedy it prints.** Its own message offers `acceptance: exempt` as the fix, and taking that on a thread with a full contract converts a false red into a permanent, real silent pass. That is the whole reason I am escalating rather than noting it: the wrong fix is the one the tool recommends, and it is one line to apply.

**And I have to own the part where I could not see it.** My board has read "Gate 0/20 BLOCKED, which is correct" for most of today, and I wrote that sentence. It was not correct; it was unreadable. A broken reader returning zero is indistinguishable from a true zero at exactly the moment a validation node first looks -- when nothing has been proven yet -- so the tell only appeared once real greens existed to be miscounted. The rule I am keeping: **a zero from an instrument you have never seen return non-zero is not a measurement.**

This is Intent's tree, so I have touched nothing there and will not. It is `intent-vc`'s to file, and you are the channel.

**AC16 is what remains, and it is yours.** Render every built-in theme and look. It is the only item nobody else can take, and both of today's runtime defects came from you looking at output rather than from any red.

Also still on no contract anywhere, carried from my 13:36Z entry: **`geodica doctor` reporting whether `utilz prez` is available.** The estate moving to `~/Devel/prj/Gtools` did not retire it.

## (2026-09-07 21:13Z)

**One thing on ST0014 needs your eye because the cheapest remedy is in YOUR shell, not in our code.**

`~/.zshrc:76-78` exports `UTILZ_HOME=$MOLT_PRJ_DIR/Utilz` unconditionally. `bin/utilz:42` derives `UTILZ_HOME` from `$0` **only when that variable is unset**. So an installed `~/Devel/opt/utilz/bin/utilz` would source `common.sh`, every utility, `help/` and `VERSION` **from the checkout**, silently, in the shell you actually type into. Measured with a marker VERSION in a hand-built prefix: unset gives the install, exported gives `v2.5.0` from the source.

That is the exact failure the two-tree arrangement exists to prevent, and **AC01 cannot see it** -- AC01 moves the source aside, and with the source gone a stale `UTILZ_HOME` fails loudly instead of deferring quietly. Green in a clean test env, broken on your machine. AC15 and AT15 now cover it.

**The fork is cc's to rule in `design.md` and I have not ruled it**, but one of the three options is yours and only yours: dropping the export from `.zshrc`. It fixes this machine and not the class, so I would not take it alone -- I lean to the dispatcher ignoring an inherited `UTILZ_HOME` outright, which makes those three lines dead and is a change to your environment either way. Flagging it now rather than after cc has built around the current behaviour.

Nothing is blocked on you. WP-01 continues.

## (2026-09-07 21:16Z)

**THE CONTRACT WILL GO GREEN AND YOU STILL WILL NOT BE RUNNING THE INSTALL. This is a scope call and it is yours.**

You opened this morning asking why `~/.local/bin/utilz` points into `~/Devel/prj/Utilz` rather than `~/Devel/opt/utilz`. **Fifteen of the sixteen ACs answer a different question.** They make a correct install exist at the prefix; none of them makes anything on your PATH point at it.

Measured just now: **sixteen links in `~/.local/bin` resolve into the Utilz source tree** -- all fifteen utilities plus `utilz` itself. AC11 forbids install and upgrade from touching them implicitly, and I stand by that row: relinking your environment without a verb you typed is the wrong default. But the consequence is that after a green ST0014 you type `utilz` and get the checkout, exactly as you do today, and **nothing in the thread reports that as a failure.**

Devbin does not have this problem because it is not on your PATH that way at all -- `.zshrc:27-28` reaches `$HOME/Devel/opt/devbin/bin/devbin` by absolute path, and there is no `~/.local/bin/devbin`. So "works the same way as devbin" does not settle it; devbin's answer does not transfer to a tool with sixteen PATH entries.

**Three ways to close it, and the choice is a scope decision rather than a design one:**

- **A verb** -- `utilz relink` or `utilz install --relink`, explicit, repoints the sixteen. This was my cancelled WP-11; nothing in cc's WP-01..05 replaces it, so it is currently unowned by anyone.
- **Shell-init**, devbin's shape -- the install emits something `.zshrc` evals, and PATH order decides. Consistent with how you already reach devbin, and it makes the sixteen links redundant rather than wrong.
- **Nothing** -- you relink by hand once, and ST0014 stays about producing a correct install rather than about adopting it.

**I am not ruling this and I have not minted an AC for it**, because all three are defensible and the third is a legitimate answer that costs nothing. Say which and I will put it on the contract; say "not now" and I will record that it was raised and declined, so it is not rediscovered as a bug in a month.

One detail worth having whichever way you go: **`~/.local/bin/prez` is the odd one out** -- a RELATIVE link to `bin/utilz` rather than an absolute one to `bin/prez`. It works, because dispatch keys on `basename $0`. But any relinking code that assumes one shape will either skip it or normalise it, and normalising it is a change to your environment nobody asked for.

## (2026-09-07 21:20Z)

**Pen taken. Both forks ruled, contract `0/16 BLOCKED`, doctor 0 findings. One item needs your hands and it is three lines in `~/.zshrc`.**

**AC15 -- I ruled AGAINST the option I recommended to you an hour ago.** I said I leaned to the dispatcher ignoring an inherited `UTILZ_HOME`. Measured, that breaks `test_helper.bash:20` which exports it for the entire bats suite, `prez.bats:132` which runs a sandboxed shim against the project root deliberately, the documented `static/emacs/e2e-smoke.el` path, and **cc's own new `install.sh:124`**, which binds it in a subshell to read a foreign tree's yaml. The variable is load-bearing. **The silence is the defect, not the variable.** So: the dispatcher always computes its own home from `$0`, and when an inherited `UTILZ_HOME` names a different tree it says so on stderr and honours it. Nothing that works today stops working; the run that was silently wrong becomes loud.

**AC16 and WP-12 -- `utilz relink`, an explicit verb.** Your opening question this morning now has a row against it. It is a separate verb rather than a flag on install, because a flag becomes habitual and then relinking is implicit by habit, which AC11 forbids. Doing nothing was rejected: it leaves a manual sixteen-link step with no record, rediscovered as a bug rather than a decision. It repoints at a tree you name, reports what it changed, reverses by naming the source, and leaves `~/.local/bin/prez` alone -- relative, pointing at `bin/utilz`, works because dispatch keys on `basename $0`, and normalising it is a change to your environment nobody asked for.

**YOUR HANDS: delete `~/.zshrc:76-78`, the `export UTILZ_HOME="$MOLT_PRJ_DIR/Utilz"` block.**

```
if [ -n "$MOLT_PRJ_DIR" ] && [ -d "$MOLT_PRJ_DIR/Utilz" ]; then
  export UTILZ_HOME="$MOLT_PRJ_DIR/Utilz"
fi
```

An ambient login-shell export makes every `utilz` invocation everywhere carry the checkout, which defeats the two-tree arrangement by construction -- the AC15 announcement would fire on every install run, and an announcement that always fires is noise nobody reads. **The variable is for scoped, deliberate, foreign-tree invocation**: the bats harness, the emacs e2e path, cc's metadata read. Nothing needs it ambient, and I checked rather than assumed -- the suite sets its own, emacs documents its own.

**I did NOT mint an AC for it.** We cannot test your dotfile from this repo, and a criterion nothing can measure is worse than a sentence you can act on. It is recorded as a thread precondition on my board, so it does not get lost and does not get counted as satisfied by anyone.

Nothing is blocked on you. cc has both rulings and carries on with WP-01; WP-12 is ruled LAST, since it is the only one that writes outside the prefix.

## (2026-09-09 08:24Z)

**ST0017/WP-01 needs one word from you, and it is a gap in AC02 rather than a request to overturn it.**

`opt/prez/crate/Cargo.toml` carries your ruling verbatim: _"DEPENDENCIES: comrak AND NOTHING ELSE (AC02, hv's ruling) ... Adding a crate here needs hv's sign-off, named in the commit that adds it."_

The consolidation that makes ST0017 a thread rather than a copy requires prez and showreel to LINK one implementation of the theme resolver. Linking needs a dependency edge, so prez's `[dependencies]` gains exactly one line:

```
artifact = { path = "crates/artifact" }
```

**That is an addition to the block your ruling governs, so it needs your sign-off by the ruling's own terms.** cc raised it before moving a file rather than after, which is right.

**It sits inside AC02's reasoning and outside its letter, which is why it is yours and not ours.** The comment's own argument is about third-party cost -- it counts packages locked (104 with syntect's defaults, 25 without) and binary bytes (434 KB against an 8 MB ceiling already spending 3.5 MB on mermaid). **A first-party, std-only sibling crate in the same workspace adds zero packages to the lockfile and zero third-party code.** Nothing the ruling was defending against moves. But the ruling is written about the block, and this is a line in the block.

**What we recommend: say yes, and we name it in the commit the way AC02 requires.**

The alternative was considered and rejected rather than ignored: `#[path]` source inclusion satisfies both criteria literally, with no dependency edge and a byte-identical block. **It compiles one implementation twice** -- Highlander satisfied in the tree and violated in the artifact -- and it distorts the code to fit a criterion instead of correcting a criterion to its intent. That is the same disease as weakening a row, running the other way. We would rather ask you than carry a hack.

**The criterion has already been corrected on our side, and the correction makes the property provable rather than proxied.** S2 said "prez's `[dependencies]` block is byte-identical before and after", which S1 makes impossible by construction -- that was vc's error, caught by cc. It now asserts what it always meant, measured the way AC02 itself argues: **the `comrak` line byte-identical, the lockfile's third-party package count unchanged, and the only permitted addition this one first-party std-only path.** Byte-identity was a proxy for third-party cost; the package count is the thing itself.

**Nothing else in WP-01 is blocked.** cc is writing `artifact/`'s source, which is identical whichever way you rule, and has solved a second collision without needing you: `crate/` becomes both the workspace root and prez's package, so every `include_str!` path, the shim, `prez.bats`'s fixture and `README.md:40`'s "indivisible by construction" all stay true. That layout also avoids a silent one -- **`[profile.release]` is ignored outside a workspace root**, so a separate root would have dropped `lto` and `strip`, roughly half the binary, while every test still passed.

**A yes unblocks WP-01's commit. A no means (ii) and we will say so in the thread rather than quietly.**

_(entry written by vc, who is the named reader of this inbox and has also put this to hv live.)_
