---
verblock: "08 Sep 2026:v0.1: cc - As-built notes for one-home version dispatch"
---

# ST0015 -- Implementation

## What was built

**`version_intercept()` in `common.sh` -- the one home.** Takes the utility name, inspects the first remaining argument, and answers `--version` before any implementation runs. Called from **both** dispatch sites in `bin/utilz`: the `utilz <util> …` arm, which previously had no intercept at all, and the symlink arm, whose inline copy it replaces.

**The format (D2).** `show_version` now prints `utilz:<framework>/<util>:<version>` for a utility, then the description. Both halves are read -- the framework's from `./VERSION` via `get_utilz_version`, the utility's from whatever file its yaml's `version_file` names. Nothing is restated. `utilz --version` keeps its old shape (D3, open with hv).

**Fourteen arms deleted from thirteen files.** `expz` carried **two** -- one in an early option pass and one in the main parse loop -- which the first count missed by assuming one per file.

**The template arm deleted too, and this was the leak that mattered.** `opt/utilz/tmpl/script.tmpl` scaffolds every new utility, and it carried the arm. Left alone, `utilz generate` would have reintroduced the duplication one utility at a time, so the fix would have decayed silently from the moment the next utility was created. Its place now carries the reason rather than the code.

## Evidence

Red-first, captured before any edit: **0 of 30 invocations** (15 utilities x 2 forms) carried the pair line.

After, over a population asserted at 15 and refusing below it:

- **15/15 carry the anchored form** `^utilz:X.Y.Z/<util>:X.Y.Z$` -- matched as a form, not a substring, so a malformed pair cannot pass.
- **15/15 byte-identical across both invocation forms.** The disagreement was the defect; a test running one form cannot see it.
- **The framework half equals the bytes of `./VERSION`**, checked separately from "looks like a version".
- **`todo` and `prez` specifically**, the two that could not inherit the old convention, both fixed by the intercept rather than by two more special cases.
- **A freshly generated utility answers on both forms with no arm of its own**, which is the template fix proved rather than asserted.
- **`prez/crate` untouched**; `Cargo.toml` remains the single home of prez's version, with no `VERSION` file beside it.

## Notes

**The arms were proved dead by deletion, not by inspection (AC05).** Reading the code and concluding they were unreachable would have passed exactly as well if they were not; removing all fourteen and watching both forms still answer is the claim that "the dispatcher **also** handles it" cannot make.

**One record deliberately preserved here rather than lost with its code.** `mdagg`'s arm carried a comment about a hand-rolled version fallback it once held: unreachable, duplicating `show_version` with a hardcoded string that would have gone stale, and declaring `local` outside a function so it would have died had it ever run. The arm is gone; the lesson belongs somewhere, so it is here.

**`--version` for an unreadable version is no longer a silent success.** The old inline intercept exited 0 whatever `show_version` returned; `version_intercept` exits with its status (`IN-AG-NO-SILENT-001`).

## Adjacent defect, NOT fixed here

**`--help` diverges between the two forms on 14 of 15 utilities** -- the symlink form renders the curated `help/*.md`, the dispatcher form falls through to the utility's own inline usage. Identical structure to the `--version` defect, one line above it in the same file, and a materially larger behaviour change. Reported to hv; not folded in without a ruling.

## What the change flushed out of the existing tests

**Ten bats tests asserted `assert_output_contains "v"` -- the bare letter -- and only five went red** on a change that rewrote every one of those lines. `stampz` and `lnrel` stayed green because their DESCRIPTIONS contain a `v`, in "e**v**ery" and "relati**v**e"; the two framework tests stayed green off `utilz v2.6.1`. **An assertion weak enough to be satisfied by prose splits a uniform change into red and green for reasons unrelated to the change.** All ten now assert the anchored form.

**And one test had written the DEFECT down as its contract.** `prez.bats` asserted `utilz prez --version` equals `prez <version>` -- clap's output, which is exactly what hv reported as wrong. The test existed to prove both channels read one source, and froze the bug standing next to it by matching the whole line instead of the claim. The claim is kept; the accidental pinning of the framework's shape to the binary's is gone, and the symlink form is now asserted to agree with it exactly.

**Two more asserted `"utilz v"` literally**, one of them on the line directly above `assert_output_contains "installed at $E2E_PREFIX"` -- ST0014/AC12 being load-bearing in a test rather than in an argument.

## Not done here

**The install is stale.** Everything above is verified against the CHECKOUT. The published install still answers the old way, and a publish is hv's. Verification from the install, by behaviour, is a separate step and is not claimed.
