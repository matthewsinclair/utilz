---
st_id: ST0013
title: prez theme addressing: split --theme, --theme-file and --theme-path
---

# ST0013: prez theme addressing: split --theme, --theme-file and --theme-path -- Acceptance

> **THIS FILE IS A GENERATED VIEW, AND A ROW AUTHORED HERE IS DISCARDED BY THE NEXT SYNC.** The acceptance contract is canon in the thread model; this file renders it. Acceptance Criteria (AC) are the ratified completeness boundary; Acceptance Tests (AT) are the small red-to-green tests that prove them.
>
> Done = every AC is covered by a GREEN AT, or (for a non-test AC) its named evidence is satisfied, AND the AC set is the ratified full boundary. Done is read from this map, never from a hand-ticked box.
>
> Test-backed satisfaction is COMPUTED from covering green ATs and never stored -- storing it would be double truth. An AC has four states, not two: beyond satisfied and unsatisfied, a requirement can be **descoped** to a named thread or **withdrawn** with its reason on the record. Both are non-blocking and both are reported separately, so a thread that descoped half its contract looks like one.

## Acceptance Criteria

### Group AC01

- AC01 CARRIED VERBATIM FROM ST0010/AC15 on 2026-09-07, hv's re-scope. ST0010 was 'add prez to utilz' and prez is added, shipped, green and eyeballed; this is a redesign of theme addressing that arrived mid-thread from hv's CLI asks, and it wears its own badge now. The text below is unchanged -- a re-scope that reworded the requirement would be a quiet renegotiation of it. || Theme addressing, split by mode (hv 2026-08-29): --theme=NAME resolves names ONLY -- search path then built-ins, never the working directory (killing the measured cwd-shadowing: --theme=simple beside a ./simple/ directory resolved the local one, elsewhere the built-in, silently); --theme-file=FILE resolves a path ONLY, mutually exclusive with --theme, its refusal saying no-such-file rather than offering a theme roster; --theme-path=PATHSTR PREPENDS colon-separated directories to PREZ_THEME_PATH for the invocation (prepend, not replace: flag and env compose); front matter splits identically into theme: (name) and theme-file: (deck-relative path), or the ambiguity moves into the deck where it travels; --theme=./x.css is thereby refused as a name carrying a separator -- a breaking change taken deliberately at the rename, the cheapest moment it will ever have. (f) THE REFUSAL OF A PATH GIVEN TO --theme MUST NAME --theme-file, because this split breaks an invocation that is already in use. Measured 2026-08-29: hv presented a real 14-slide client deck with `prez present <deck> --theme <path>`, which is in hv's shell history and in that deck's build instructions. On the day WP-06 lands, that exact command starts failing, and a refusal that only says a name cannot contain a separator reads as the port having broken the deck. Naming the replacement flag turns a breakage into a migration. This is the general rule of AC20(b) pointing the other way: a refusal must name the remedy for the case that actually fired. -- satisfied: no (computed)

### Group AC02

- AC02 A PATH GIVEN TO `--theme` IS REFUSED WITH THE FLAG THAT FITS THE SHAPE OF WHAT WAS PASSED, AND A DIRECTORY-SHAPED THEME'S LANDING PLACE IS `--theme-path` PLUS A NAME, NOT `--theme-file`. Added 8 Sep from MEASURED DOWNSTREAM USE rather than reasoning: the geodica node reported `--theme=\"$ESTATE/Clients/<domain>/_themes/<name>\"` twice in one hour, and it is how both client decks in engagement E0024 have rendered since 3 Sep. AC01 does not cover it. AC01's worked example is `--theme=./x.css` and its clause (f) requires the refusal to name `--theme-file` -- but A PREZ THEME IS A DIRECTORY CONTAINING theme.css, verified 8 Sep against the built-ins and by building a deck with `--theme <dir>`, which succeeds today. So the shape actually in use is a DIRECTORY, `--theme-file` names a FILE, and a refusal naming it would send a real user to a flag that cannot take what they have. THE RULING: a directory is refused naming `--theme-path=<parent>` plus `--theme=<name>`, which composes with PREZ_THEME_PATH exactly as AC01 already specifies and keeps `--theme` name-only, which is the thread's entire point; a path to a .css FILE is refused naming `--theme-file`. Extending `--theme-file` to accept directories was rejected: the name would then lie about what it takes, and a bare stylesheet with no directory is a genuinely different input that deserves its own flag. AC01'S WORDING IS UNTOUCHED -- it is hv's verbatim from ST0010/AC15 and a re-scope that reworded it would be a quiet renegotiation. This is the case it did not anticipate, added beside it. Per-client themes live outside PREZ_THEME_PATH deliberately: geodica_present sets that to the house theme only, so the estate is not a search-path consumer for this case. -- satisfied: no (computed)

### Group AT01

_(no criteria in this group)_

### Group AT02

_(no criteria in this group)_

## Acceptance Tests

### Group AC01

_(no tests in this group)_

### Group AC02

_(no tests in this group)_

### Group AT01

- AT01 `opt/prez/crate/test/acceptance.sh` -- covers AC01 -- status: to-write -- Carried from ST0010/AT14 at hv's 7 Sep re-scope, still to-write and still GENUINELY red-first: --theme=NAME must resolve identically from two working directories, one of them containing a ./NAME/ directory. It is RED against the pinned binary today, because path.exists() is tried first and wins. It goes green only when the split lands.

### Group AT02

- AT02 `opt/prez/crate/test/acceptance.sh` -- covers AC02 -- status: to-write -- Three legs, and the first is the one measured in the field. (1) `--theme <dir>` where <dir> holds theme.css: REFUSED, and the message names BOTH `--theme-path` and `--theme=<name>`, because either half alone does not get the user there. (2) `--theme <file>.css`: REFUSED naming `--theme-file`. Assert the two refusals differ -- one message for both shapes is the defect this row exists to stop. (3) the remedy the refusal prints actually WORKS: run `--theme-path <parent> --theme <name>` on the same fixture and assert it renders, so the message is verified rather than merely present.

---

_Generated by Intent v3.0.0 from `thread.json`. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
