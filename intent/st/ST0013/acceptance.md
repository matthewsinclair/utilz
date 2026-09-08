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

- AC02 `--theme-file` TAKES A PATH IN EITHER SHAPE THE OLD `--theme` TOOK: a `.css` FILE, or a DIRECTORY holding `theme.css`. Both verified accepted by the pinned binary 8 Sep. THE FLAG'S NAME IS NOT THE SPECIFICATION -- AC01 SAYS IT 'resolves a path ONLY', AND A PATH IS BOTH SHAPES. THIS ROW WAS MINTED 8 Sep SAYING THE OPPOSITE AND IT WAS WRONG. Its first form ruled that a directory passed to `--theme` must be refused naming `--theme-path=<parent>` plus `--theme=<name>`, on the premise that a refusal naming `--theme-file` 'would send a real user to a flag that cannot take what they have'. That premise is FALSE: `--theme-file` can take exactly what they have. vc read the flag's name where hv's text said path, then built a ruling on top of it; cc caught it by asking what the flag accepts rather than assuming, before writing any of it. So AC01's clause (f) stands EXACTLY AS hv WROTE IT -- a path given to `--theme` is refused naming `--theme-file` -- and this row no longer contradicts it. WHAT THIS ROW STILL DECIDES, and why it is not withdrawn: AC01 leaves the accepted SHAPES to be inferred from the word FILE in the flag's name, which is precisely the inference that produced the wrong ruling above, so it is pinned here instead. A prez theme IS a directory containing `theme.css` -- true of every built-in -- and directory addressing must not be lost, which is a bigger breaking change than the one AC01 deliberately takes. MIGRATION IS ONE WORD: the geodica node's live invocation, `--theme=\"$ESTATE/Clients/<domain>/_themes/<name>\"`, used twice in an hour and rendering both E0024 client decks since 3 Sep, becomes `--theme-file=\"...\"` and nothing else changes. `--theme-path=<parent>` plus `--theme=<name>` remains available and composes as AC01 specifies, but it is an option rather than the required remedy. -- satisfied: no (computed)

### Group AT01

_(no criteria in this group)_

### Group AT02

_(no criteria in this group)_

### Group AT03

_(no criteria in this group)_

### Group AT04

_(no criteria in this group)_

### Group AT05

_(no criteria in this group)_

### Group AT06

_(no criteria in this group)_

## Acceptance Tests

### Group AC01

_(no tests in this group)_

### Group AC02

_(no tests in this group)_

### Group AT01

- AT01 `opt/prez/crate/test/theme-addressing.sh` -- covers AC01 -- status: to-write -- Carried from ST0010/AT14 at hv's 7 Sep re-scope, still to-write and still GENUINELY red-first: --theme=NAME must resolve identically from two working directories, one of them containing a ./NAME/ directory. It is RED against the pinned binary today, because path.exists() is tried first and wins. It goes green only when the split lands.

### Group AT02

- AT02 `opt/prez/crate/test/theme-addressing.sh` -- covers AC02 -- status: to-write -- Three legs. (1) `--theme-file <dir>` where <dir> holds theme.css renders, and `--theme-file <file>.css` renders: BOTH shapes, because the flag's name implies one and AC02 requires both. (2) `--theme <path>` in either shape is REFUSED naming `--theme-file`, which is AC01 clause (f) unchanged. (3) the remedy the refusal prints actually WORKS: take the exact path from the refused invocation, pass it to `--theme-file`, assert it renders. A refusal whose advice is untested is a message rather than a remedy, and this leg exists because the row's first form printed advice that pointed at a flag which -- on that form's own premise -- could not have taken the input.

### Group AT03

- AT03 `opt/prez/crate/test/theme-addressing.sh` -- covers AC01 -- status: to-write -- MUTUAL EXCLUSION AND THE REFUSAL WORDING, AC01 clause (b). Two legs. (1) `--theme=simple --theme-file=x.css` in one invocation is REFUSED, either order, rather than one silently winning. (2) `--theme-file` naming a path that does not exist refuses saying NO SUCH FILE and does NOT print the built-in roster. Leg 2 is red-first for a reason worth recording: today `--theme=nope.css` falls through path-does-not-exist to the search path to the built-ins and lands in `unknown_theme()`, which by design names every directory it searched and every built-in it knows. That is the RIGHT answer for a NAME and the wrong one for a PATH -- a user who mistyped a filename is handed a theme roster, which reads as though the filename were a name they got wrong. Red-first by construction: neither `--theme-file` nor the exclusion check exists in `args.rs` at 6e02020.

### Group AT04

- AT04 `opt/prez/crate/test/theme-addressing.sh` -- covers AC01 -- status: to-write -- PREPEND, NOT REPLACE, AC01 clause (c) -- and the word prepend is the whole assertion. Three legs. (1) with `PREZ_THEME_PATH=<envdir>` set and `--theme-path=<flagdir>` given, a name present ONLY in envdir still resolves: the flag COMPOSES with the env rather than replacing it, and a replace implementation passes any test that only ever sets one of the two. (2) a name present in BOTH resolves from flagdir, which is what prepend means as against append. (3) repeated `--theme-path` is LAST-WINS, ruled 8 Sep on ccs Q2: every other value flag in `args.rs` is last-wins and a second rule for this one would be a special case nobody can predict. Red-first: no `--theme-path` exists at 6e02020, so all three legs fail at argument parsing. Leg 1 is the one that matters -- it is the only leg an accidental replace cannot pass.

### Group AT05

- AT05 `opt/prez/crate/test/theme-addressing.sh` -- covers AC01 -- status: to-write -- THE FRONT MATTER SPLITS IDENTICALLY, AC01 clause (d), or the ambiguity moves into the deck where it travels. Three legs. (1) `theme: simple` in front matter resolves as a NAME and never against the deck directory -- so a deck beside a `./simple/` directory builds the same artifact as the same deck built elsewhere, which is AT01 one layer down. (2) `theme: ./x.css` is REFUSED as a name carrying a separator, and the refusal NAMES `theme-file:`, the front-matter half of AC01 clause (f). (3) `theme-file: ./x.css` resolves DECK-RELATIVE, not cwd-relative: build the same deck from two different working directories and get the same artifact. Red-first: `frontmatter.rs` at 6e02020 has one `theme` key, and `theme::load` resolves a front-matter value as `base.join(spec)` -- a path -- so leg 2 today renders instead of refusing.

### Group AT06

- AT06 `opt/prez/crate/test/theme-addressing.sh` -- covers AC01 -- status: to-write -- SEARCH PATH BEFORE BUILT-INS, AC01 clause (a) second half. `--theme=simple` with a `simple` theme on `PREZ_THEME_PATH` resolves the search-path one, not the built-in of the same name. THIS ROW IS DELIBERATELY NOT RED-FIRST AND MUST NOT BE READ AS PROOF THE SPLIT LANDED. It is already correct at 6e02020 -- `theme.rs:126-129` tries `on_search_path` before `built_in` -- so it goes green on its first run and stays green. It is minted anyway because the fix is a TYPE change that rewrites that whole cascade (ccs finding, and the reason a branch reorder was rejected), and an ordering that is currently load-bearing by accident of line order is exactly what a rewrite drops silently. Every other row here fails loudly if the split is absent; this one fails only if the split is present and got the order wrong, which is the case no red-first test can reach.

---

_Generated by Intent v3.0.0 from `thread.json`. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
