---
verblock: "08 Sep 2026:v0.1: cc - Design for one-home --help dispatch"
---

# ST0016 -- Design

## Objective

`--help` diverges between the two invocation forms on **14 of 15 utilities**. Collapse it to the same one home `--version` now uses, so the two forms cannot disagree again.

## What was measured

This is ST0015 **one line up the same file**. `bin/utilz:325` intercepts `--help` and `-h` on the SYMLINK path; the `utilz <util>` arm falls straight through to the implementation. So:

| form                      | who answers                                   | what you get                     |
| ------------------------- | --------------------------------------------- | -------------------------------- |
| `<util> --help` (symlink) | `bin/utilz` intercepts, calls `show_help`     | the curated `help/<name>.md`     |
| `utilz <util> --help`     | the implementation's own arg loop             | the utility's terse inline usage |

**14 of 15 disagree.** `expz` is the lone agreement and only because its inline usage happens to be reached the same way.

**The precondition holds**: all 15 utilities have a curated `help/<name>.md`, so routing both forms through `show_help` cannot hit a missing file. Verified by sweep with a count control, not assumed.

## Decisions

**D1 -- ONE pre-dispatch intercept, not two.** `version_intercept` becomes `predispatch_intercept`, covering `--version`, `--help` and `-h`, called from both dispatch sites. The symlink site's inline `--help` block collapses into it. **Adding a second `--help`-shaped intercept beside the `--version` one would rebuild the exact arrangement ST0015 removed** -- two homes agreeing by convention -- so the generalisation is the point rather than a convenience.

**D2 -- The CURATED help wins, not the terse inline usage.** `help/<name>.md` is the maintained document; the inline usage is a fallback that only ever appeared because the dispatcher was not looking. This is what `<util> --help` already does today, so the change is that the OTHER form joins it.

**D3 -- THE PAGER COST DOES NOT EXIST. This decision previously said it did, and it was wrong.** `glow`'s pager is **opt-in** -- `-p, --pager` -- and `show_help` calls `glow "$help_file"` without it. Measured both ways: `glow --help` lists the flag as opt-in, and `./bin/cleanz --help` returns in **0 seconds, exit 0, 17450 bytes**. So routing the dispatcher form through `show_help` does **not** make it paged. The user-visible change is **terse to rendered**, not instant to paged, which is a materially easier change to defend and removes the only argument that stood against D2.

**D3a -- and this project's recorded `glow` hang is misattributed.** The board entry reads "`utilz help <anything>` HANGS when stdin is a TTY", which reads as a property of the help VERB. It cannot be: the verb and the flag both reach the same `show_help` and the same `glow` invocation, and both emitted **byte-identical output, 17450 bytes, exit 0** under a non-TTY stdin. Whatever the hang is, it belongs to `glow`-on-a-TTY and is shared by both entries or by neither. **Not disproved here** -- the reproduction requires a real TTY and this was run without one -- but the attribution to one path is unsupported by the code, which has only one path.

**D4 -- The utilities' own `-h|--help` arms are NOT deleted in this thread, unlike ST0015's `--version` arms.** They remain reachable when a utility is executed DIRECTLY (`opt/<name>/<name> --help`), which is not a dispatched invocation and not something this thread governs. ST0015 could delete its arms because `show_version` was the only producer either way; here the arm produces genuinely different text, so deleting it would remove the only inline usage a directly-executed script can print. **Whether that fallback should exist at all is a separate question and is not decided here.**

## Risks

- **A utility that consumes `--help` before the dispatcher.** Cannot happen: the dispatcher `exec`s the implementation, so an upstream intercept is strictly earlier.
- **`utilz --help` and `utilz help <x>` are separate paths** (`bin/utilz:97`, `:171`, `:202`) and are NOT touched here. Only the per-utility dispatch changes.
- **The pager**, per D3.

## Out of scope

Whether the inline usage blocks should exist at all (D4). Whether `glow` should be invoked with a pager flag -- that is a `show_help` question predating this thread and touching `utilz help` too.
