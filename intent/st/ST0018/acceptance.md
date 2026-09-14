---
st_id: ST0018
title: prez: a fallback theme for decks that name none (PREZ_DEFAULT_THEME)
---

# ST0018: prez: a fallback theme for decks that name none (PREZ_DEFAULT_THEME) -- Acceptance

> **THIS FILE IS A GENERATED VIEW, AND A ROW AUTHORED HERE IS DISCARDED BY THE NEXT SYNC.** The acceptance contract is canon in the thread model; this file renders it. Acceptance Criteria (AC) are the ratified completeness boundary; Acceptance Tests (AT) are the small red-to-green tests that prove them.
>
> Done = every AC is covered by a GREEN AT, or (for a non-test AC) its named evidence is satisfied, AND the AC set is the ratified full boundary. Done is read from this map, never from a hand-ticked box.
>
> Test-backed satisfaction is COMPUTED from covering green ATs and never stored -- storing it would be double truth. An AC has four states, not two: beyond satisfied and unsatisfied, a requirement can be **descoped** to a named thread or **withdrawn** with its reason on the record. Both are non-blocking and both are reported separately, so a thread that descoped half its contract looks like one.

## Acceptance Criteria

### WP-01 -- PREZ_DEFAULT_THEME: red-first tests, the precedence function, the docs (status: WIP)

- AC-01.1 A deck that names no theme, neither theme: nor theme-file:, built with PREZ_DEFAULT_THEME naming a theme, is dressed by that theme. Answers the request's clause: a deck without theme: plus fallback Y gives Y. -- satisfied: yes (computed)
- AC-01.2 A deck that names its own theme, by theme: or by theme-file:, is dressed by the deck's theme whatever PREZ_DEFAULT_THEME holds. Answers: a deck with theme: X plus fallback Y gives X. The theme-file: half is an EXTENSION beyond the request, stated and labelled as one in design.md. -- satisfied: yes (computed)
- AC-01.3 The flags --theme and --theme-file each beat both the deck's key and PREZ_DEFAULT_THEME. Answers: --theme Z beats both. -- satisfied: yes (computed)
- AC-01.4 PREZ_DEFAULT_THEME resolves exactly as --theme does: on PREZ_THEME_PATH extended by --theme-path, then among the built-ins, never against the working directory. An unknown name gets the unknown-theme refusal, exit 2, its no theme '<name>' prefix unchanged and listing the built-ins and every directory searched, plus one line naming PREZ_DEFAULT_THEME as where the name came from. A path-shaped value is refused naming the variable. Answers: the fallback name resolves on the same search path, with the same refusals, as --theme; and a fallback naming an unknown theme gets the usual refusal listing the search path. -- satisfied: yes (computed)
- AC-01.5 With PREZ_DEFAULT_THEME unset or empty, nothing changes. Two claims, labelled: (a) an empty value is treated as unset -- a regression guard, green at HEAD by construction, red only if the fix reads an empty value as a name; (b) rank 4, a claim about TODAY that must pass at HEAD: a deck that names no theme, with no fallback, builds byte-identical to --theme=simple. Answers: with the fallback unset, nothing changes. -- satisfied: yes (computed)
- AC-01.6 (non-test) prez --help and help/prez.md state the whole precedence -- the flags, then the deck, then PREZ_DEFAULT_THEME, then the built-in simple -- and how the variable resolves, what an empty value means and what it refuses. Nothing under opt/prez names the requester or any organisation. -- evidence: prez --help (src/args.rs USAGE: the order, highest first, and an Environment section) and help/prez.md (the Themes order sentence, a PREZ_DEFAULT_THEME subsection, the Options row) state the precedence, resolution, empty and refusals; a grep of the added lines under opt/prez and help/prez.md finds no requester or organisation name -- satisfied: yes
- AC-01.7 (non-test) When the thread lands, gtools-vc is told the commit and how the change reaches a wrapper: from a source checkout the prez shim rebuilds once on the first use after the commit and is quiet after; from an install, only once utilz upgrade publishes a release that carries it. Answers the request's last clause: tell gtools-vc when it lands, the commit, and whether the prez shim rebuilds on next use. -- satisfied: no

### Group AT10

_(no criteria in this group)_

### Group AT11

_(no criteria in this group)_

### Group AT12

_(no criteria in this group)_

### Group AT13

_(no criteria in this group)_

### Group AT14

_(no criteria in this group)_

## Acceptance Tests

### WP-01 -- PREZ_DEFAULT_THEME: red-first tests, the precedence function, the docs (status: WIP)

_(no tests in this group)_

### Group AT10

- AT10 `opt/prez/crate/test/theme-addressing.sh` -- covers AC-01.1 -- status: green -- red at 34eb61d: 2 checks failed (red-st0018.log); green in utilz test prez, 14:14-14:15Z, bash 3.2.57 end to end (gates-st0018.log)

### Group AT11

- AT11 `opt/prez/crate/test/theme-addressing.sh` -- covers AC-01.2 -- status: green -- a regression guard, green at 34eb61d by construction; the theme-file: leg is an extension; green in utilz test prez, 14:14-14:15Z, bash 3.2.57 end to end (gates-st0018.log)

### Group AT12

- AT12 `opt/prez/crate/test/theme-addressing.sh` -- covers AC-01.3 -- status: green -- a regression guard, green at 34eb61d by construction; green in utilz test prez, 14:14-14:15Z, bash 3.2.57 end to end (gates-st0018.log)

### Group AT13

- AT13 `opt/prez/crate/test/theme-addressing.sh` -- covers AC-01.4 -- status: green -- red at 34eb61d: 11 checks failed (red-st0018.log); green in utilz test prez, 14:14-14:15Z, bash 3.2.57 end to end (gates-st0018.log)

### Group AT14

- AT14 `opt/prez/crate/test/theme-addressing.sh` -- covers AC-01.5 -- status: green -- (a) a regression guard; (b) today's claim, green at 34eb61d; green in utilz test prez, 14:14-14:15Z, bash 3.2.57 end to end (gates-st0018.log)

---

_Generated by Intent v3.0.2 from `thread.json`. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
