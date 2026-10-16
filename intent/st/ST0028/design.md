# ST0028 design: the title patterns discover writes

## Measured

hv's run 8 on 16 Oct 2026 (menuz run log, `~/.local/state/menuz/menuz.log`) applied `today.yaml`, saved by `arngz discover --save today` through menuz minutes before. 15 entries were placed; one failed (appgate fixes its own window size, reported as such and not a defect); two iTerm windows were `unseen`:

| Entry                           | Pattern discover wrote | What it was made from                                                                   |
| ------------------------------- | ---------------------- | --------------------------------------------------------------------------------------- |
| `displays[0].spaces[0].apps[5]` | `^%-zsh$`              | iTerm's title for a shell at its prompt                                                 |
| `displays[0].spaces[2].apps[0]` | `^◑ utilz%-dc$`        | Claude Code's session title, with `◑`, its working glyph, put in front while a turn ran |

Claude Code changes that leading glyph through a turn and replaces it when the turn ends, and a terminal's title follows the job in it. A pattern anchored at both ends holds the title as it was for one moment, so it misses the same window soon after. The second title would match with its glyph gone; the first is recorded as found, with what it had become at apply not measured (apply's report gives the pattern, not the titles it saw).

## The rule today

Discover gives an entry a `window` pattern when its app has more than one claimable window in the world (named, standard, not minimized, each counted once, a window on every space included), because plan gives a bare entry every claimable window of its app on every display: a bare entry where the app has two windows would claim one the desk never put there. The pattern is the title escaped and anchored at both ends (`exact_pattern`). A title the app's windows share, or an empty one, cannot tell them apart, so that window is not recorded and the report says so.

vc ruled that discover pins only where the design's rule needs a pattern. That rule is the one above and it stays: narrowing it to "two windows of one app on one display" would let a bare entry on one display claim the app's window on another, and the tests that hold a discovered desk to its own world ("the discovered desk plans against its own world with nothing but snapping places", the two-display and every-space cases in `plan_test.lua`) would go red. So what changes is the pattern discover writes, and the report.

## The change

**The pattern.** Where discover pins a window, it takes the title's core: the title with its leading run of characters other than ASCII letters and digits removed. Spaces, punctuation and every non-ASCII character count as decoration, so `◑ utilz-dc` gives `utilz-dc` and `-zsh` gives `zsh`. The class is spelled `[^A-Za-z0-9]`, not `%w`, because `%w` follows the C library's locale and a byte of a UTF-8 glyph may read as a letter under one. The core is escaped for Lua and the pattern is anchored at neither end (vc's ruling: a pattern tells one window of an app from the app's others; the user tightens it in the yaml).

**The pattern must still claim only its own window.** Plan matches a pattern against every claimable window of the app with `string.find`, so an unanchored `Inbox` would also take `Inbox - 2 messages`. Discover therefore takes the first of these that matches exactly one of the app's claimable windows, counted as the rule above counts them:

1. the core, unanchored: `utilz%-dc`;
2. the core anchored at the end: `Inbox$`;
3. the whole title, exact: `^Inbox$`, today's pattern.

The first two are skipped when the core is empty (a title that is all decoration). Where none tells the window apart, it is not recorded and the report says so, as today. So a desk discover writes still plans against its own world with nothing but snapping places.

**The report.** Discover's report (stderr) names every window it pinned, one line each: `<display> desktop <n>: <bundle> "<title>" pinned as "<pattern>"`. A user who sees a title that will move (a terminal's) knows which entry to loosen or tighten.

**Unchanged.** Plan, apply, diff and the desk format. A desk saved before this change applies as it did. `help/arngz.md`'s discover section says what a pinned pattern is made from and that the report names each one. arngz goes from 1.0.0 to 1.0.1, a fix; the CHANGELOG line goes under 2.14.0's Fixed.

## Tests

In `opt/arngz/test/plan_test.lua`, red first, over fixture worlds:

- run 8's two titles: a world with two iTerm windows titled `◑ utilz-dc` and `-zsh` gives `utilz%-dc` and `zsh`, and each matches its window's title with another leading glyph (`✳ utilz-dc`) and with none;
- a title inside another: `Inbox` and `Inbox - 2 messages` give `Inbox$` and `Inbox %- 2 messages`;
- two windows whose cores collide but whose titles differ (`◑ notes`, `✳ notes`) fall to the exact pattern; two with one title stay unrecorded and said;
- a title that is all decoration takes the exact pattern;
- every pinned window is named in the report with its pattern;
- every discovered desk still plans against its own world with nothing but snapping places.

`arngz.bats`'s discover test expects the new pattern in the saved yaml.
