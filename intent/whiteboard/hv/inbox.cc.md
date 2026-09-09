# inbox: cc -> hv

_(empty)_

## (2026-09-09 18:24Z)

**Three items for your review, none of them blocking today's work.** Sent because you asked on the way out; vc has the same list live.

### 1. `prez showreel build` will need `SHOWREEL_THEME_PATH` set, where the Python needed nothing

45h's config names `theme: popupart`. **popupart is a built-in of snorkeltoast's script and can never be one here** -- design.md section 7 keeps it out of this tree and H3 holds it there, because no built-in is ever a brand. So it arrives over the search-path variable instead, and a bare `prez showreel build <45h dir>` refuses with a message naming every directory it searched.

**That is the extractability guarantee working, not a port regression**, and it is measured: zero brand strings in either shipped binary, with a control proving the check finds what IS there. **But it is a workflow change for whoever runs the build**, and it needs to be in front of you before the first one rather than discovered during it. vc has taken it into H1's acceptance test as part of the FIXTURE rather than as a defect.

**No decision needed unless you want the variable set somewhere permanent** -- a shim export, or the reel directory carrying its own theme. Say if you do.

### 2. snorkeltoast must be told before any build points at 45h

**The live config plans 23 slides; FLOORS.md's artifact 008 has 22.** Their `compare` refuses on a structural mismatch and they re-derive.

**The gap is between the live config and 008, NOT between the port and the Python** -- my `collect` reaches 23 independently, which is the number the estate already records for what this config plans. So it is a coordination item and not a defect. **Sequencing is yours**: it is their tree and their instrument, and I have not touched either.

### 3. vc's public-repo question, which is theirs and already with you

Flagging only so it is not read as handled by me. `matthewsinclair/utilz` is public and the two pinned fixtures carry a named individual and a customer brand. **`upstream` is frozen at `60153d8`, 156 behind, so nothing is published and it is decidable before it is.** I have not touched the fixtures either way and will not without your ruling.

### Standing, not new

**A woff2/brotli converter and a PDF rasteriser both need fresh sign-off** under AC-3.9's budget rule. Neither is wanted -- the theme ships WOFF2 and 45h contains no PDF -- and both are refused BY NAME with the remedy, so nobody adds one helpfully. Recorded rather than asked.

**Issue 0016** remains the only open issue, scheduled by you as a WP-05 rider.

## (2026-09-09 18:51Z) Re: 2026-09-09 18:24Z FYI only -- no response needed.

**Correcting my own item 2, and one premise of your AC-3.7 ruling. Neither is a request; both are things I would want to know if I were you.**

### Item 2's evidence was weaker than I wrote it, and it is now settled

I told you the 23-vs-22 gap is config-vs-008 rather than port-vs-Python, **and the reason I gave was "my `collect` reaches 23 independently"**. That is one implementation agreeing with itself about a number it derived. It is the exact failure this thread has been naming all day and I wrote it into your inbox.

**Measured properly at 18:44Z: I ran snorkeltoast's own Python against the live config in dry mode -- it embeds nothing and writes nothing -- and the REFERENCE plans 23 slides and 14 used assets.** So the conclusion holds and now rests on the reference rather than on me. **The gap is between the live config and artifact 008, and no part of it is the port.**

**vc's `hv/inbox.vc.md` names the 1 and I am not restating their finding here** -- their four-artifact sweep is the better half of this and it is already in front of you. The coordination item is unchanged: **snorkeltoast should be told before any build points at 45h**, sequencing yours, their tree.

### AC-3.7: you ruled "nothing gates on the producer literal", and that is still true of the CONTRACT but no longer true of the tree

Your withdrawal said dropping `|| "Snorkeltoast"` remains fine and is **not required**, on the grounds that nothing gates on it and no row carries it. **No row does carry it, and I am not asking you to reinstate anything.**

What is new is measured: **`player.html:628` is `add("Producer", REEL.producer || "Snorkeltoast")`, the template is pulled with `include_str!`, and that puts the literal in the shipped binary.** Baseline this turn, with a control proving the check finds what is there: `popupart` 0, `POP^UP^ART` 0, `Snorkeltoast` 0 in both binaries; `showreel.yaml` 3. **Pulling the template verbatim takes that zero to one.**

So the drop stays optional under the contract and has become load-bearing for the H3 measurement I run every slice. **I am taking the permission you already gave** -- the drop lands in the same commit as the pull, with the strings check as its red-proof. Recorded because your ruling's premise had an exception in it that neither of us could have seen at the time.

**Worth knowing and not worth acting on: 45h sets `producer: Snorkeltoast` itself, so the fallback never fires there.** The drop changes no pixel on this reel and changes the binary. That is the whole of it.

(C) hello@matthewsinclair.com

## (2026-09-09 19:15Z) ONE DECISION NEEDED: serde_json, or a hand-rolled JSON emitter

**This is a request, unlike my last two. The template pull is in at `cb8f2bf`; the payload cannot be written until this is answered, and vc cannot answer it.**

`crates/showreel/Cargo.toml` says, in its own words: **"ADDING A CRATE HERE NEEDS hv's SIGN-OFF, NAMED IN THE COMMIT THAT ADDS IT."** So I stopped rather than adding one.

### What needs it

`cmd_build` renders the payload with `json.dumps`. The port needs the same: one JSON object carrying the artist, session, socials, outro, bug, limits and every slide, substituted into `const REEL = /*__DATA__*/;`. **There is no JSON emitter in the tree.**

### The cost, measured rather than estimated

`serde_json 1.0.151` pulls `itoa`, `memchr`, `serde_core` and `zmij`. **Three of those four are ALREADY in the Utilz lock.** The net addition is **2 packages: `serde_json` and `zmij`**, taking the workspace lock from **79 to 81**.

I nearly reported this as +4 from reading the crate's own tree. **The number that matters is what this tree does not already have**, and it is half.

### The alternative, stated fairly

**Hand-roll it**, as `artifact/base64.rs` was hand-rolled -- and that precedent is real, so it deserves a straight answer rather than a dismissal.

**I recommend AGAINST it, on where the risk actually sits.** base64 was safe to hand-roll because its input is bytes and its specification is forty lines. **A JSON emitter's risk is string escaping over arbitrary text**, and this payload carries artist names, session copy, social handles and outro rows straight out of somebody's YAML -- quotes, backslashes, newlines, and the `POP^UP^ART` and `@45h836782` kind of thing. An escaping bug produces an artifact that fails to parse in the browser, or worse, one that parses differently.

**And a second reason that is about this codebase rather than about JSON.** `serde_json` derives the field order from the struct, so the payload's order matches the reference's dict order by declaration. A hand-rolled emitter means maintaining that order in a second place, by hand -- **a subset duplicate of exactly the kind that hid in the pace table**, where two of five fields were present and correct and nothing reported the missing three.

### What I recommend

**Take `serde_json`.** Same author and same ecosystem as the `serde` and `serde_yaml` already in the budget, 2 net packages against 79, and it removes the one part of this work where a quiet correctness bug is genuinely likely.

**If you would rather not, say so and I will hand-roll it** -- it is a day's care rather than a blocker, and I would put the emitter in `artifact/` beside `base64.rs` where the no-dependency argument already lives.

**Nothing is blocked while this waits** except the payload itself: delivery re-encode has naming, revisions, pruning and `report_unused` in it, none of which need JSON. Say the word either way and I will name your ruling in the commit.

(C) hello@matthewsinclair.com
