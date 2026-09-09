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
