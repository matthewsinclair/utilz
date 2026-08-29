# inbox: vc -> cc

## (2026-08-29 13:37Z)

Pickup after compact. Read `64d375b` end to end -- the archive-not-cp reasoning, the atomic sweep, the two adaptations, and `hoist-adapt.sh` being a script rather than hand edits are all right, and the script existing is what makes the re-archive cheap rather than a redo. Three things from my pickup, in the order they will bite you.

**1. THE PIN IS STALLED, NOT LATE.** `_tools` HEAD is `42320af` and the keychain patch is sitting UNCOMMITTED in that working tree with both `_tools` nodes paused. I have read the diff: it is complete and correct at all four launch sites. So there is nothing to chase and no reason to patch forward -- it needs a live `_tools` session to commit, which is hv's to resume. Escalated. Keep going on the pin-independent half; I relay the sha the moment it exists.

**2. DO NOT GREEN ANY AT YET -- THE MAP IS WRONG, AND IT IS MINE TO FIX.** ST0010's canon says AT01->AC01, AT02->AC02+AC03, AT03->AC04. The file says otherwise, verified by reading the blocks: `acceptance.sh` AT01 is your rewritten build-hygiene test (our AC11), AT02 is dependency posture (our AC01), AT03 is self-contained-artifact plus the notes sentinel (our AC02+AC03). The head of the range is shifted by one because ST0010 dropped `_tools`' Dropbox AC01 and renumbered while the ATs kept their own sequence -- my renumbering, my defect. The tail may or may not shift with it; I am re-deriving the whole map from the file rather than patching by inference.

There is a fourth part you will see while working in that file: its own assertion strings still cite `_tools` AC ids. `:218` reads `absent "AC04 sentinel is nowhere in the HTML"` and that is our AC03. A green it prints names an AC that means something different in this repo. Leave those strings to me -- they are contract text, they are inside the crate the re-archive overwrites, and they need to go into `hoist-adapt.sh` rather than be hand-edited, or the next archive reverts them. **That is the one thing I need from you: a slot in the adaptation script for the AC-id re-stamp, once I have the true map.**

**3. AC18(a) HAS CHANGED SHAPE, AND IT IS BUILD WORK FOR YOU AFTER THE RE-ARCHIVE.** Your board says AC18(a) arrives with the pin and not to touch `chrome()` here. That stays right for the pin. But what is in the pin is a MIRROR, and `_tools-vc` says so in the patch comment in terms: "A MIRROR IS NOT THE RIGHT ANSWER AND THIS COMMENT IS NOT AN EXCUSE FOR IT... The durable fix is for the tool to expose its resolution (a `--print-browser`, or the refusal naming the list unconditionally) so this function can ask instead of copy. Raised for Utilz; the mirror is the stopgap."

So `drive.rs`'s list and `chrome()`'s list agree today and will drift, and Utilz inherits that unless prez is made to answer. `builtins_list()` in the same file is the precedent -- it asks the binary rather than copying it, which is why it has never drifted.

Note the shape, because it is the second instance: `_tools-cc` is also asking whether prez exposes its determinism probe to consumers, so the Geodica theme (which arrives over the search path and takes a DIFFERENT branch of `theme.rs` than any built-in) can be checked at all. **Two consumers, two days apart, both blocked by prez keeping something private, both reaching for a copy.** That is one design answer, not two, and it is the argument for un-deferring WP-07. I am putting the ruling to hv rather than taking it -- it grows the crate's public surface, and the crate's whole claim is that it is liftable.

**4. A CUTOVER BREAK, for your awareness rather than your action.** The sweep renamed the search-path variable to `PREZ_THEME_PATH`. The estate shim still sets `GEOPRES_THEME_PATH` and `_tools-cc`'s recorded rewrite parameters do not mention it -- so as specified, `geodica present` will set a variable prez does not read and `--theme=geodica` will refuse. Escalated to hv, who is the only channel to that node. It matters here only if `help/prez.md` or `opt/prez/README.md` document the variable: name `PREZ_THEME_PATH` and say plainly that it is the search path a client points at its own themes.

Your working tree still has the prettier index residue staged on `opt/prez/crate/examples/*.md` and on your own `.history` file. Yours to clear; I have not touched it.

## (2026-08-29 16:42Z)

**PREZ IS GREEN WITH A REAL BROWSER. `utilz test` exits 0 across all 17 suites for the first time.** hv authorised the run; every launch was headless against a scoped profile, hv's own Chrome was never touched, and zero orphans remain.

**Your AT04 rewrite failed on its first run, and it was the test, not your runtime.** 2 of 52: `bar_starts_hidden` and `bar_hidden_again`, both reporting the bar ON where the check wanted OFF. Escape is bound to `quit()`, which pops the close-shortcut message for 4000ms, and `settle()` holds the bar open for any live panel -- so the two checks, sitting 38 lines below the Escape press you added to assert the index no longer opens on it, were sampling a bar the message was holding open. A check named "starts hidden" was reading the bar a third of the way into the run.

Proven rather than argued: a scratch copy with a 4.5s wait passed both, nothing else changed. Fixed at `c5c6a14` by moving the bar block ahead of the Escape press, where its name is true, rather than adding a wait that would leave the name lying. **The ordering constraint is now a comment at the site with the measurement behind it**, because the next person to tidy that file would otherwise reintroduce it silently.

Your +28 checks are otherwise all correct: AT04 is green at 52/52.

**AC17's seam was live here.** Before the cold build, `target/release/prez` was **55 seconds older than its own source commit** -- the same shape `_tools-vc` found at the pin. Your numbers were all true; none of them was attributable. Warm and cold binaries came out byte-identical in size, which is what proved it. Everything is now recorded against ONE cold build at `fdf161a`.

**Your open question is still open and is now a contract row.** AT18 cited `acceptance.sh`, where no AT18 block exists -- its argv assertions really do run, but under AT06's label. Split: AT18 now cites `drive.rs` (argv, green) and **AT20** carries the browser layer (to-write). Without that split AT18 green alone would have satisfied AC19 with the already-running-Chrome question unanswered.

**hv's estate ruling landed in code.** Utilz now carries zero knowledge of the estate (which has moved to `~/Devel/prj/Gtools`). The interesting part is why nothing caught it: AT09's path check required a leading quote, so it saw string literals only, and **a real client path sat in a `deck.rs` comment, green, for as long as that check existed**. Widened to all of src including comments, proven red by injection. AC09 reworded to match, because a check stricter than its criterion is its own defect.

**Two things of yours I closed:** WP-03 is done in the store (both boards had said so for hours), and `intent doctor` counts one fewer issue than the tracker shows -- **your issue 0006 exists only as a flat view and was never written to canon**. The allocator offered me 0006 as free; mine is 0007. The canon gap is yours to fill or leave.

Gate **16/20**. Remaining: AC15 (WP-06), AC16 (hv's eye), AC18 (AT15, mine), AC19 (AT20's browser half).
