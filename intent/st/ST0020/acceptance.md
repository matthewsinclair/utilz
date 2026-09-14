---
st_id: ST0020
title: prez: a theme name defined twice on the search path refuses, when a caller asks
---

# ST0020: prez: a theme name defined twice on the search path refuses, when a caller asks -- Acceptance

> **THIS FILE IS A GENERATED VIEW, AND A ROW AUTHORED HERE IS DISCARDED BY THE NEXT SYNC.** The acceptance contract is canon in the thread model; this file renders it. Acceptance Criteria (AC) are the ratified completeness boundary; Acceptance Tests (AT) are the small red-to-green tests that prove them.
>
> Done = every AC is covered by a GREEN AT, or (for a non-test AC) its named evidence is satisfied, AND the AC set is the ratified full boundary. Done is read from this map, never from a hand-ticked box.
>
> Test-backed satisfaction is COMPUTED from covering green ATs and never stored -- storing it would be double truth. An AC has four states, not two: beyond satisfied and unsatisfied, a requirement can be **descoped** to a named thread or **withdrawn** with its reason on the record. Both are non-blocking and both are reported separately, so a thread that descoped half its contract looks like one.

## Acceptance Criteria

### WP-01 -- prez refuses a duplicated theme name when PREZ_THEME_DUPLICATES=refuse (status: WIP)

- AC-01.1 With PREZ_THEME_DUPLICATES=refuse, a theme name that two directories on the search path define is refused, byte-identical copies included: exit 2, a message beginning theme '<name>' is defined more than once, each definition named with its directory and the mechanism that put that directory on the path, listed in search order, and no output written. Answers AC05: a name that two directories define refuses and names both. Red-first: HEAD builds it. -- satisfied: no (computed)
- AC-01.10 (non-test) When the thread lands, gtools-vc is told the commit, the variable's name and value, and how the change reaches a wrapper: from a source checkout the prez shim rebuilds once on first use, and from an install it arrives with the next published release. -- satisfied: no
- AC-01.2 With PREZ_THEME_DUPLICATES unset, empty or first, a name that two directories define resolves by first match exactly as today, with today's provenance notice and no new refusal of any kind: the artifact and stderr are byte-identical across the three. Answers: prez's other users keep first-match. A regression guard, green at HEAD by construction. -- satisfied: no (computed)
- AC-01.3 Only the name being resolved is checked for a second definition: with refuse set, a build whose theme name has one definition succeeds even when another name on the path is defined twice. This limits the duplicate check only; the variable's value is checked at every compile (AC-01.7). Answers: it refuses only the name actually being resolved. A regression guard, green at HEAD by construction; AT15 is its control. -- satisfied: no (computed)
- AC-01.4 The default name is checked as a flag's or the deck's name is: with refuse set, PREZ_DEFAULT_THEME naming a theme that two directories define is refused, and the refusal says the name came from PREZ_DEFAULT_THEME. Red-first: HEAD builds it. -- satisfied: no (computed)
- AC-01.5 One file reached twice is one definition, identified by device and inode: with refuse set, a directory listed twice on the path, a directory given by both --theme-path and PREZ_THEME_PATH, a symlink to a directory already on the path, and a hard link to a <name>.css already on the path each build. A regression guard, green at HEAD by construction; AT15's byte-identical copies are its control. -- satisfied: no (computed)
- AC-01.6 A built-in is not a second definition: with refuse set, one search-path theme that shadows a built-in builds, announced SHADOWING as today. The built-in answer the request left to prez. A regression guard, green at HEAD by construction. -- satisfied: no (computed)
- AC-01.7 A PREZ_THEME_DUPLICATES value other than unset, empty, first or refuse is refused by name at every compile, whether or not the build resolves a theme name: exit 2, naming the variable and its value, listing the accepted values, and no output written, for a --theme name, a --theme-file path and a deck that names no theme alike. A value that is not UTF-8 is refused by name the same way. This is not the duplicate check, which AC-01.3 limits to the name being resolved. Red-first: HEAD ignores the variable. -- satisfied: no (computed)
- AC-01.8 The one extension beyond the request, stated: with refuse set, one directory that defines a name both as <name>/theme.css and as <name>.css is refused, naming both files. Red-first: HEAD takes the directory form silently. vc's review of the design kept it, because without it the policy is half a policy. -- satisfied: no (computed)
- AC-01.9 (non-test) prez --help and help/prez.md describe PREZ_THEME_DUPLICATES: its values, what counts as a definition, the refusal, that a value it does not know is refused at every compile, and that unset keeps first match. Neither names any organisation. -- satisfied: no

### Group AT15

_(no criteria in this group)_

### Group AT16

_(no criteria in this group)_

### Group AT17

_(no criteria in this group)_

### Group AT18

_(no criteria in this group)_

### Group AT19

_(no criteria in this group)_

### Group AT20

_(no criteria in this group)_

### Group AT21

_(no criteria in this group)_

### Group AT22

_(no criteria in this group)_

## Acceptance Tests

### WP-01 -- prez refuses a duplicated theme name when PREZ_THEME_DUPLICATES=refuse (status: WIP)

_(no tests in this group)_

### Group AT15

- AT15 `opt/prez/crate/test/theme-addressing.sh` -- covers AC-01.1 -- status: to-write -- red-first: HEAD builds a name two directories define

### Group AT16

- AT16 `opt/prez/crate/test/theme-addressing.sh` -- covers AC-01.2 -- status: to-write -- NOT red-first: a regression guard, green at HEAD by construction

### Group AT17

- AT17 `opt/prez/crate/test/theme-addressing.sh` -- covers AC-01.3 -- status: to-write -- NOT red-first: a regression guard, green at HEAD by construction; AT15 is its control

### Group AT18

- AT18 `opt/prez/crate/test/theme-addressing.sh` -- covers AC-01.4 -- status: to-write -- red-first: HEAD builds the default's duplicated name

### Group AT19

- AT19 `opt/prez/crate/test/theme-addressing.sh` -- covers AC-01.5 -- status: to-write -- NOT red-first: a regression guard, green at HEAD by construction; AT15's byte-identical copies are its control

### Group AT20

- AT20 `opt/prez/crate/test/theme-addressing.sh` -- covers AC-01.6 -- status: to-write -- NOT red-first: a regression guard, green at HEAD by construction

### Group AT21

- AT21 `opt/prez/crate/test/theme-addressing.sh` -- covers AC-01.7 -- status: to-write -- red-first: HEAD ignores the variable

### Group AT22

- AT22 `opt/prez/crate/test/theme-addressing.sh` -- covers AC-01.8 -- status: to-write -- red-first: HEAD takes the directory form silently

---

_Generated by Intent v3.0.3 from `thread.json`. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
