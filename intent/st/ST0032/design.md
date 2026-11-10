---
verblock: "10 Nov 2026:v0.1: utilz-vc - ST0032: the feature and the menu"
---

# ST0032 design

utilz-vc, 10 Nov 2026, every file:line read at main's head 35025ba0.

**WP01, WP02 and WP03 are designed in their issues**, following 0132's precedent that a defect's design belongs with the defect: issue 0133 (`intent/issues/0133.md`), issue 0134, issue 0135. This file designs WP04, the feature, and WP05, the menu and the docs, and holds what is true across all five.

## What is true across all five

- **The pure/impure split is enforced by a test, not by convention.** `AT-03.2` (`opt/arngz/test/arngz.bats:544`) asserts `plan.lua` makes no `hs`, `io`, `os` or `require` call, and it uses `arngz.lua` as the control that the pattern _does_ match. So every decision added by this thread goes in `plan.lua` and is tested under plain Lua by `plan_test.lua`; the engine gets thin coordination only (`IN-AG-PFIC-001`, `IN-AG-THIN-COORD-001`). Any new `plan.lua` function that reached for `hs` would turn `AT-03.2` red, which is a free guard on the whole thread.
- **One version bump for the release, not one per work package.** arngz's own version moves once. vc's reading is 1.1.3 to **1.2.0**, since WP04 adds two verbs, and a new verb is not a patch. The number is hv's; hv has already ruled the _Utilz_ release number stays the patch 2.14.9.
- **No run starts in this session.** vc decision 74 stands and the desk is agentic-engineering-vc's with AE 0.3.x on total focus. Every arm named here needs hv's own run or a desk grant.
- **The thread's acceptance test is hv's own case**: a desk `discover` has just saved applies cleanly straight afterwards on the same screens. Run 69 saved zeophq and exited 0; run 70 applied it 20 s later and exited 1. WP01 and WP02 together are what make run 70 clean.

## WP04: a desk picked from the monitors present

### The matching already exists and is already pure

`P.match_displays(desk, world, options)` (`plan.lua:130`) binds each of a desk's displays to one screen: the same uuid; else the one screen with the same panel name and size; else, among several, the one in the same position. It returns the screens indexed like `desk.displays`, or nil and a refusal naming the display and every candidate.

**It already guarantees injectivity.** Its `taken[hit.uuid]` check (`plan.lua:184`) refuses a world where two desk displays would match the same screen. So the only half missing for "this desk is the one I am at" is surjectivity: that every screen _present_ is accounted for. And because the binding is injective, surjectivity is a **count**:

> a desk fits when `match_displays` returns a binding **and** `#matched == #world.screens`.

That is the whole rule. Without the count, `rhad`, which describes the laptop alone, binds successfully at every site, because its one display matches the laptop screen wherever it is, and it would be reported as the desk even with two monitors plugged in.

### The pure function

Add to `plan.lua`:

```
P.detect(desks, world, options) -> name, kind, report, candidates
```

**One shape, always.** This read as two shapes until 10 Nov, with `report` in position 2 on the success path where the code puts `kind`, so anyone implementing from it would have written `local name, report = P.detect(...)` and silently bound the kind string into the report variable. The code never had two shapes; the design did, and it was the one artefact nobody re-read after the shape was settled (utilz-dc). `name` is nil unless a desk was chosen.

- `desks` is a list of `{ name = <string>, desk = <table> }` in catalogue order, so the answer is stable and does not depend on table iteration order.
- `options.current` is the current desk's name, or nil.
- A desk fits by the rule above. `match_displays`'s own refusal text is kept for the report, so a reader is told _why_ each desk did not fit in the words arngz already uses, rather than a new vocabulary.
- `kind` is one of **four** values, not the two this said until 10 Nov: `"one"` (exactly one desk fits), `"current"` (several fit and the current one is among them, so it decides), `"several"` (several fit and none is current) and `"none"`. The paragraph above argued at length for the current-desk behaviour while the contract never named the value that carries it. On `"current"` the current desk is returned, because a site with two desks describing the same screens should keep doing what it is doing rather than refuse.
- The report names each desk and its verdict: fit; `match_displays`'s refusal; or `it describes N of the M screens present`, which is the new case.

`P.detect` touches nothing impure, so `AT-03.2` stays green.

### The engine verb

`VERBS.which` in `arngz.lua`, in `discover`'s shape (`arngz.lua:1327`), which is the precedent for a verb that observes and then calls a pure function:

```lua
which = function(_, options)
  local world = M.observe()
  local name, kind, report, candidates = P.detect(options.desks or {}, world, { current = options.current })
  return { desk = name, kind = kind, candidates = candidates, report = report }
end
```

**`kind = name and "one" or kind` is what this sketch said until 10 Nov, and it was wrong.** `name` is non-nil whenever the kind is `"current"`, so that expression rewrote `"current"` to `"one"`: the response would have asserted that one desk fits when several fitted and the current one decided, which is false, and stripped the one field a later caller or menu would read to tell those apart. The code passes `kind` through untouched and always did, so nothing shipped wrong — but the sketch is what reads as the specification (utilz-dc).

Two deliberate choices:

- **It returns a normal ok response even when no desk fits**, rather than raising a refusal. Exit codes are the CLI's policy and arngz keeps them there; an engine refusal would collapse "none fits" and "several fit" into one kind. The engine reports, the CLI decides.
- **It reuses `M.observe()` whole** rather than adding a screens-only read. `which` needs only screens, and a cheaper path is possible, but `world.screens` has one builder today and a second one could drift from what `match_displays` expects (`IN-AG-HIGHLANDER-001`). One observe per click is the no-yak-shaving answer (vc decision 67); the cheaper read is noted here as a later option and is not in this release.

The desks reach the engine in `options.desks`, through the existing `engine_ask <verb> "" "<options file>"` path that `discover` already uses (`arngz:1622`). The engine is given data, never the desk directory's layout, which stays the CLI's.

### The two verbs

**`arngz which`** prints the desk the screens present fit, and changes nothing.

| exit | meaning                                                                |
| ---- | ---------------------------------------------------------------------- |
| 0    | one desk fits; its name is printed on stdout, alone                    |
| 1    | no desk fits; the report says why each did not                         |
| 2    | the question could not be answered: several fit, or the engine refused |

Exit 2 keeps arngz's established meaning, refused and nothing said, rather than becoming a second "none" code.

**`arngz auto [--default <desk>]`** resolves the desk and applies it. It is a coordinator and holds no logic of its own: it asks `which`, then **calls `cmd_apply` with the name**, so apply's report, its readbacks and its exit code are apply's, unchanged, and nothing about applying a desk is written twice.

- one fits: apply it; the notice names the desk it chose.
- none fits, `--default` given: apply the default, and **say it is a fallback**, naming both that nothing matched and what it chose. hv's ruling asked for the default; the notice is what makes the fallback visible rather than silent.
- none fits, no `--default`: exit 1, saying no desk fits and suggesting `Save Desk…`.
- several fit: exit 2, naming them.
- `--default` naming a desk that is not in the catalogue is refused **before** the engine call, by the same `desk_name_refusal` and `desk_file` checks apply uses, so a typo costs no observe.

### Dispatch

`which)` and `auto)` go into `main`'s `case` (`arngz:1766`) **before** the `*) cmd_apply "$verb" "$@"` fallthrough, or `arngz which` would try to apply a desk called "which". Neither is added to the `load_hammerspoon` skip list, which holds `current` and the help flags only: `current` reads one file and needs no engine, while `which` must observe. That is also why `which` must never be used in a menu _label_, which is realised at every menu open; it belongs in a `run:` line or a parameter default, which run on a click.

### Tests

Pure, under plain Lua, in `plan_test.lua`, red at the base and green at the fix. The worlds are built from the existing base world so each check changes one thing.

- exactly one desk fits a world: `P.detect` names it;
- **the laptop-only desk does not win at a two-screen site**: with `rhad` (one display) and `homere` (two) in the catalogue and two screens present, `detect` names `homere`, and `rhad` is reported as describing 1 of the 2 screens present. This is the check that pins the surjectivity half, and it fails without the count;
- no desk fits: `kind` is `"none"` and every desk has a verdict line;
- two desks fit the same screens: `kind` is `"several"` and both are named;
- the same, with `options.current` naming one of them: that one is returned;
- a desk whose display matches no screen keeps `match_displays`'s own refusal text in the report, so the wording is not reinvented;
- `#matched == #world.screens` is compared against the world's own screen count, never a number written down (the project's no-magic-numbers rule).

`arngz.bats` gains shim-level tests for the two verbs against the fixture machine: `which` printing one name and exiting 0; `which` exiting 1 with its report when nothing fits; `auto --default` applying the default and saying so; `auto` refusing an unknown `--default` before any engine call; and `arngz which` not being read as a desk name by the fallthrough.

The engine's `which` verb is three lines of coordination over a pure function, read in the bytes as 0132's design did, and driven live by `acceptance.sh`, which is hv's run.

## WP05: the menu, the help and the CHANGELOG

### The menu is Molt-matts, not Utilz

The menu is Molt-matts `config/menuz/menuz.yaml`, linked as `~/.config/menuz`; the desks are Molt-matts `config/arngz/desks/`, linked as `~/.config/arngz`. **Menuz itself does not change** and neither does any Utilz file for this part. On hv's ruling the two items read:

```yaml
- label: Discover
  run: arngz auto --default rhad
  notify: always
- label: Save Desk…
  params:
    - name: desk
      prompt: Save the arrangement on screen now as
      default: "$(arngz current || echo today)"
      required: true
  run: arngz discover --save "$desk" --force
```

`notify: always` on `Discover` is what makes the chosen desk, or the fallback, visible: the run is detached, so the notification is the only place its answer is seen. **`Save Desk…`'s default stays `arngz current`, not `arngz which`**: a parameter default is realised when the form opens, and `which` costs an observe, while `current` reads one file. That is the distinction `which`'s own cost forces and it is the reason the verb exists separately from `current`.

`Discover` runs `auto`, which is new, so the menu change must land **after** the arngz change is on the machine hv is using. Since hv has said `use dev` rather than a brew release, the order is: land the Utilz change, `utilz use dev` so `~/.local/bin/arngz` serves this checkout, then change the menu.

### Docs

- `help/arngz.md`: `which` and `auto` get entries beside the other verbs, with the exit-code table above; apply's report paragraph gains WP01's `own_size` note; discover's report paragraph gains WP02's refusal; apply's account of creating a space gains WP03's retry and once-per-display rule. The Exit Status section gains `which`'s reading of 1 and 2.
- `CHANGELOG.md`, under the existing `[2.14.9] - unreleased`: one Added entry for WP04 and WP05 together, and one Fixed entry each for 0133, 0134 and 0135, in the house's one-bold-sentence-then-prose form. arngz's version line moves once, to the number hv sets.
- `README.md` mentions `arngz` verbs; the two new ones go in the same list.

## Order of work, and what each step may not do

1. WP01, WP02, WP03: `plan.lua`'s pure additions and their `plan_test.lua` arms, then the two engine mappings. No new test surface is built (see issue 0135's design).
2. WP04: `P.detect` and its arms, then `VERBS.which`, then `cmd_which` and `cmd_auto` and the dispatch, then the bats tests.
3. WP05: help, CHANGELOG, README, and the version bump once hv gives the number.
4. The menu, in Molt-matts, after `utilz use dev`.

Every step lands outside `intent/`, so **on hv's one-release ruling the whole of 2.14.9's pinned proof is void from the first of them**: R1, R2, R3 and every tree-scan file must run again at the new head, with this thread's arms. That cost was put to hv and accepted (vc decision 95) and is recorded on ST0032's context.

## What this thread measured about its own proof standard

utilz-vc, 10 Nov 2026, from utilz-dc's reading and its own correction of it. This is evidence for the question on `intent/wip.md` of whether arngz's engine should have a test surface. It is not a defect to fix, and both halves are below because either alone misleads.

**The standard**, asserted in four places in this thread: issue 0133's design, issue 0135's design twice, and this file's WP04 section. The engine's coordination is "small enough to read in the bytes", proved live by `acceptance.sh`.

**It was applied to two engine functions, on the same day, by the same author, under the same words — and it held for one and failed three times for the other.**

- `exec_place` (issue 0133, WP01): **four readings by three readers, no defect found.** critic-lua read it, utilz-dc read it going at it specifically, and neither found anything; the only hazard chased there was whether `P.round` existed for the own-size note, and it does.
- `exec_create_space` (issue 0135, WP03): **three commits, a defect found after each one, every one by a reader rather than by the reading offered as the proof** — twice while the author knew the function was under suspicion and was looking straight at it.

**The two differ in a way that predicts which way it went.** `exec_place`'s change is a stateless mapping: call a pure function, branch three ways on its answer, return. No loop, no mutable state, no ordering between an effect and a read — nothing to hold in your head while reading it. `exec_create_space` has a retry loop, two captured mutable locals, run-scoped state in `ctx.space_failed` that outlives the call, and an ordering dependency between a side effect that **creates** something and a read known to lag behind it. All three defects lived in exactly that combination: the retry wrapping the effect, the suppression keyed off the wrong variable, and the final-failure path not consulting the state the loop had set.

**So the question this thread answers is a smaller and better one than it first appeared.** Not "should arngz's engine have a test surface", which invites a yes or no about the whole engine and a large piece of work, but **where does reading stop being sufficient** — and the evidence from these two functions says: where there is state, an effect, and an order between them. `exec_place` would gain little from a harness. `exec_create_space` is where four commits went and where a fifth may yet.

That distinction is utilz-dc's, which sent the failure half first and then corrected its own evidence after reading issue 0133's design, on the ground that half of it would lead to over-correcting. The correction is the more useful finding.

**Two smaller measurements, for the same reader.** First, this design asserted that no expected count in its arms was written by hand; `#matched == #world.screens` is indeed derived, but three other counts in WP04's arms were written down and had to be derived out afterwards. A design asserting compliance with the no-magic-numbers rule is the wrong kind of claim — the arms either demonstrate it or they do not. Second, five of this thread's findings were in documents rather than code: two literals and a done-rule the code had moved past, the `P.detect` contract above, the `kind` rewrite in the engine sketch, and a release-facing CHANGELOG entry describing behaviour that had been removed as a defect. Doc-before-code put the design first; nothing put it under review again when the code moved four times.

**The criterion is sharper than that, and cheaper.** utilz-dc then found that issue 0135's design claimed a live proof it did not have: `acceptance.sh` never mentions `create_space`, and its apply mode is an apply after windows are scrambled **by hand**, which deletes no desktops and so plans no creation. The `acceptance.sh:75` the design cited is the `hs_call` in its observe mode, the one line in that file that could not touch a space creation. Meanwhile `exec_place` genuinely is driven live, by that same apply mode on every run — which is exactly why a defect in the harness's own counting of `exec_place`'s new note was findable, and was found.

So the dividing line is not only state, effect and order. It is **whether reading is the only proof there is**. `exec_place` has a live proof and a harness that exercises it. `exec_create_space` has neither: no suite reaches it, and `acceptance.sh` cannot. The engine needs a surface where reading is the only proof, and this thread touched exactly one such function and spent four commits on it.
