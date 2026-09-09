# ST0017 Design: showreel under prez

Written by `vc` 2026-09-09, before any source edit. `cc` builds against this; `snorkeltoast`
authored the reference implementation and answers questions about it from the source.

**Provenance, because the findings were measured on two different trees.** Everything about the
prez crate is cc's, measured on this tree at `bf52bf9`, and re-measured by vc. Every `showreel:NNN`
line reference is snorkeltoast's, verified by them against their source; **vc has not read the
Python** and does not restate them as its own. Nothing here is ratified until its criteria are
minted -- see section 8.

---

## 1. The layout, and why it is not a compromise

**One Cargo workspace, three crates -- the root package plus two members -- two binaries, one dispatching shim.**

```
opt/prez/crate/
  Cargo.toml              [workspace] AND prez's [package] -- see 1.4, collision 2
  src/ themes/ assets/    prez's own, at their exact existing sibling positions
  crates/
    artifact/             THE SHARED CRATE. std only. No comrak, no image, no yaml.
                          theme resolution + base64 + data-URI inlining + the Failure vocabulary
    showreel/             the reel pipeline. yaml + image + exif + qr. Its own budget.
```

**THIS DIAGRAM READ `crates/prez/` UNTIL 2026-09-09 AND THAT LAYOUT IS REFUSED BY 1.4.** prez's
`src/`, `themes/` and `assets/` cannot move -- seven `include_str!` and the shim's freshness walk
resolve them as exact siblings -- so `crate/` is both the workspace root and prez's package, which
is what WP-01 built and vc verified. Corrected here rather than left for a later reader to
flatten the two sections into one: **a stale diagram in the section titled "the layout" is the
first thing read and the last thing checked.**

`opt/prez/prez` (the shim) already resolves, builds-on-first-use and hands over. It gains one
branch: `prez showreel <...>` execs the showreel binary, everything else execs prez's.

| Constraint | How the layout meets it |
| ---------- | ----------------------- |
| AC02 -- prez depends on comrak and nothing else, hv signs off each addition by name | prez gains **no third-party dependency**; showreel's budget is a NEW ruling on a NEW manifest, not an amendment to a standing one. The one first-party path dependency S1 requires is escalated to hv -- see 1.4 |
| The 8 MB binary ceiling, already spending 3.5 MB on mermaid | Two binaries, two budgets. `prez build` never links `image` |
| The Highlander violation spanning both tools | `artifact/` is the one implementation |
| hv's command surface: showreel lives under prez | The shim dispatches. The user types `prez showreel build <dir>` |

**Why this beats both options `HOIST.md` §1 weighed.** §1 chose sibling-with-no-sharing and
offered as its fallback *"a dispatching shim that execs this tool -- shared name, no shared code.
Do not merge the implementations."* That was the best trade available for a **Python** showreel.
Rust makes shared name AND shared code AND unmerged binaries simultaneously reachable. §1's
instruction is honoured exactly: the binaries stay separate; what merges is the duplicated
library half, which is what §6 was asking for.

**And AC02 is why the crates must not merge even though the commands do.** cc's finding, and it
is the sharpest thing said this morning: §1's third argument (different languages) was flagged by
its own author as having a shelf life a Rust port retires. **AC02 replaces it with a reason that
does not expire -- it gets worse as the port succeeds.** But it is a constraint on CRATES, not on
COMMANDS, and separating those two questions is what makes hv's ruling and §1's analysis both
satisfiable at once.

### What moves into `artifact/`, and the one seam nobody has read

| Item | Measured | Disposition |
| ---- | -------- | ----------- |
| `theme.rs` generic half -- `load`, `name_spec`, `provenance`, `split_path_flag`, `Origin`, `SearchSource`, `Theme`, `Spec` | 775 lines total; entire import surface is `crate::Failure` + `std::path`; no comrak, no slide-model coupling | MOVES |
| `theme.rs` -- `STANDARD_CLASSES` + `declares()` | encode prez's slide-class vocabulary (title/section/quote/full/center/small), which showreel has no equivalent of | STAYS in prez |
| `base64.rs` -- `encode` | 56 lines, hand-rolled **because of** AC02 | MOVES |
| `Failure` | 4-field struct in `main.rs`, one constructor | MOVES |
| `inline.rs` | 260 lines. **STAYS IN PREZ** -- the WP-01 diff established that behaviour 5 has no shared surface at all: showreel rewrites no HTML anywhere, it builds payload strings the player consumes | STAYS. cc still does the formal read and reports, but the seam is settled |

### 1.1 S5, run 2026-09-09: the claim was wrong, and it is FOUR

`HOIST.md` §6 asserts prez and showreel share "the same five behaviours", and the whole Highlander
argument rests on that sentence. Nobody had diffed it. cc and snorkeltoast enumerated
independently -- each from source, before seeing the other's table, because a document compared
against a file is one account and not two -- and diffed.

**It is four behaviours, and exactly one of them is a clean match.**

| # | Behaviour | Verdict |
| - | --------- | ------- |
| 1 | Resolve on `<NAME>_THEME_PATH` | both have env + a prepending flag; **showreel carries no `SearchSource` equivalent** |
| 2 | Refuse unknown, listing what was searched | **clean match. The only one** |
| 3 | Warn when off the search path | prez has four messages, showreel two, and showreel's **hardcode `(on SHOWREEL_THEME_PATH)`** |
| 4 | Reject off-artifact references | **three disagreements, in both directions** |
| 5 | Inline assets as data URIs | **not a shared behaviour at all.** showreel rewrites no HTML; it builds payload strings |

**This does not weaken the consolidation, it re-shapes it.** Extraction is not "lift the common
code": it is *take prez's implementation, correct showreel's defects in passage, and fix prez's
one*. Each of those is a decision, and they are ruled in 1.2.


### 1.2 The four rulings the diff forced

Each is a decision rather than a refactor, and each is ruled here so the merge does not decide it
by accident.

**R1 -- Comment stripping: take PREZ's, and this is the merge trap.** Both strip CSS comments,
arrived at independently. **prez preserves newlines so a reported line number still matches the
file; showreel deletes them, and gets away with it only because its diagnostic never reports a
line.** So the shorter implementation is the worse one, and a naive merge takes the shorter one.
Written down because "pick the tidier of two functions that pass the same tests" is exactly what
an extraction does when nobody says otherwise.

**R2 -- Needle set: neither as it stands, and the union is not the wider one.** prez requires a
`url(` prefix on every protocol-relative needle, so it misses `@import "//cdn/x.css"` -- a
shipped defect, now **issue 0014**. showreel's regex `(https?:)?//[^\s;)'\"]+` catches that and
**false-positives on `content: "//"`**, a shape a person writes. The rule is the union of what
each CATCHES minus showreel's false positive: **protocol-relative in `url(...)` and in
`@import`, not in arbitrary string content.**

**R3 -- `theme.yaml` joins the scanned set.** showreel has a fourth artefact prez has no
equivalent of, naming fonts and a favicon, and **nothing scans it.** A remote URL there resolves
as `tdir / "https://..."`, does not exist, and the loader warns and continues. Nothing is
fetched, **so the offline guarantee holds by accident of path resolution rather than by the check
that is supposed to hold it.** `IN-AG-NO-SILENT-001`. The shared crate's shape is therefore
prez's three artefacts PLUS a theme-manifest concept prez does not have -- not "showreel passes
`None` twice".

**R4 -- Provenance messages: take PREZ's four.** showreel's two hardcode `(on
SHOWREEL_THEME_PATH)` and neither knows which list a directory came from, **so a theme resolved
through `--theme-path` is reported as having come from the environment variable.** Adopting
prez's `SearchSource::{Env,Flag}` axis is a correction of a false statement, not a widening.

### 1.3 WP-01 is a pure move, and the shared crate starts with a known hole

cc raised the collision and the resolution is theirs: **WP-01 changes no behaviour, and issue
0014's fix does not ride along.** WP-01's green means *the move changed nothing*, which is
exactly what it should mean and is provable by the existing suite.

**The consequence has to be stated or WP-01's green gets over-read.** A pure move takes prez's
implementation verbatim, hole included -- so between WP-01 and R2 landing, **the shared crate
carries issue 0014 and showreel now inherits it too.** The consolidation propagates the defect
from one tool to two before it fixes it in one place. That is the right order, because R2 is a
design decision that wants its own commit and its own red-proof, but **nobody may read WP-01's
green as "the resolver is correct".** It means "the resolver is unchanged."

Issue 0014 closes when R2 lands, in WP-03.


### 1.4 Two collisions in the contract, and the layout they force

cc raised both before moving a file. The first is an error in the contract and it is vc's; the
second is an error the contract would have caused.

**Collision 1 -- S1 and S2 cannot both hold, and S2 was measuring a proxy.** S1 requires one
implementation **linked by both binaries**; linking needs a dependency edge, so prez gains
`artifact = { path = "crates/artifact" }` and the `[dependencies]` block cannot be byte-identical.
S2 as drafted fails by construction, and section 1's "prez's `Cargo.toml` is not touched" carried
the same mistake.

**S2 is corrected to its intent, which is not a weakening.** The test is whether the intent held
before the edit: S2 meant *WP-01 adds no third-party cost to prez*, and byte-identity of the block
was a proxy for that. The proxy breaks; the property does not. So S2 now asserts the property
**and a stronger measurement than the one it replaces** -- AC02's own reasoning argues in packages
locked (104 versus 25) and binary bytes, so the lockfile's third-party package count is the direct
measurement that byte-identity was standing in for.

**And it reads on AC02, which is hv's.** *"Adding a crate here needs hv's sign-off, named in the
commit that adds it."* A path dependency is an addition to that block. **AC02's reasoning is about
third-party cost, not the block's shape** -- a first-party, std-only sibling in the same workspace
adds zero packages to the lockfile and zero third-party code -- so this sits inside AC02's intent
and outside its letter. **That gap is hv's to close, not a typing decision**, and it is escalated
rather than assumed. The alternative considered and rejected: `#[path]` source inclusion, which
satisfies both rows literally with no dependency edge, **but compiles one implementation twice**
-- Highlander in the tree and violated in the artifact -- and distorts the code to fit a row
rather than correcting a row to its intent. Same disease as weakening a row, running the other
way.

**Collision 2 -- S3 versus any layout that moves `src/`, and the fix needs no ruling.**
`opt/prez/README.md:40` states it outright: *"`crate/` is indivisible ... `src/`, `themes/` and
`assets/` keep their exact sibling positions or the crate does not compile. Any tidier-looking
layout that separates them is wrong by construction."* Verified: 7 `include_str!` built-ins
resolve `../themes/*`, and `prez_is_stale` (`opt/prez/prez:109`) walks `$CRATE_DIR/{src,themes,assets}`.

**So `crate/` becomes BOTH the workspace root AND prez's package.** Cargo permits it. Every
`include_str!` path, the shim, `prez.bats`'s crate-shaped fixture and README:40 are all unchanged;
the only additions are a `[workspace]` stanza and `crates/artifact/`.

**The trap this avoids is silent, and it is why the layout is a criterion rather than a
preference: `[profile.release]` is IGNORED outside a workspace root.** A separate root leaving the
profile in prez's package manifest loses `lto` and `strip` -- roughly half the binary -- **while
every test still passes.** S4 would then measure a blown budget with no test able to say why.

One thing deliberately NOT filed: `prez_is_stale` suppresses `find`'s errors, and the shim's own
comment (`opt/prez/prez:50-54`) records that as a considered trade for install mode rather than an
oversight. The no-move layout does not disturb it.


### 1.5 WP-01 verification: two things the report claimed that do not hold

cc built WP-01 and reported it green. Verified rather than accepted; the build stands and two
claims in the report do not.

**Confirmed as reported:** the workspace stanza is appended with no reordering, `[dependencies]`
is still `comrak` alone, `crates/artifact/` carries `Cargo.toml`/`lib.rs`/`failure.rs`/`base64.rs`/`theme.rs`,
and artifact's `strip_comments` is **byte-identical to prez's** -- so WP-01 is a pure move on the
point that matters most for S3.

**Confirmed and important: R1's behaviour is unguarded in the tool R1 says to take it FROM.**
`an_external_url_..._naming_the_offender` asserts "line 2" against a fixture with **no comment in
it**, and `a_url_inside_a_comment_...` only asserts that a comment does not fail a build. Neither
constrains newline preservation, so a tidier could swap `strip_comments` for a comment-deleting
regex today and all 135 tests would pass. cc wrote that control into artifact and red-proved it:
the naive strip fails exactly one test, the new one, and the other eleven pass. **R1 is now
enforced rather than written down.**

**FAILS -- the positional default has no control, and the test named as proving it does not.**
cc made artifact's `load(None, ..)` take the FIRST built-in rather than a hardcoded `"simple"`,
on the sound Highlander ground that a name would be a second place the default is written down.
The reasoning is right and the change is kept. **The stated proof is not: prez's
`no_theme_given_uses_the_embedded_default` asserts `t.css.contains("--gp-bg")`, and measured
across the roster, ALL SEVEN built-ins declare `--gp-bg`.** The test passes with any of them as
default.

So after the swap, reordering `BUILT_IN` silently changes prez's default theme and every test
stays green. Behaviour is preserved TODAY only because `simple` happens to be first. **The
distinction cc's reasoning missed: a hardcoded default in the CODE is a second home; a hardcoded
expectation in a TEST is a control.** Highlander governs implementations, not assertions. **New
row S8** requires prez to pin which theme `load(None, ..)` resolves to, by a property unique to
`simple` rather than one the whole roster shares.

**FAILS -- a test name that overstates its assertion.**
`an_unterminated_comment_does_not_swallow_a_reference_silently` asserts only that text BEFORE the
comment survives. The implementation **does** swallow the reference, and the test passes anyway.
A later reader sees a green test with that name and concludes the hole is closed. Rename it to
what it checks, or assert the truncation explicitly so the behaviour is documented as known.

**And probing that flag found issue 0015.** `strip_comments` has no notion of string literals, so
`content: "/*"` reads as an unterminated comment and the scanner discards the rest of the file.
Measured on the shipped binary with both controls: plain external refuses (rc=2), clean CSS builds
(rc=0), and `body{content:"/*"}` followed by `@import "https://cdn/x.css";` **builds and ships the
reference into the artifact**. Unlike the plain unterminated case, a browser parses that string
correctly, so the artifact fetches from the network. **Second bypass of the offline guarantee,
distinct from 0014 in root cause and in fix**, filed separately so R2's landing cannot be read as
closing it.


### 1.6 A control over code nothing links cannot fire, and it looks exactly like a control that passed

cc's first red-proof of S8 **did not fire, and cc caught it by running it.** Reordering `BUILT_IN`
to put `mono` first failed nothing: both tests passed. The reason is that `theme.rs:216` still
returns `built_in("simple")` -- **the positional default lives in artifact's `load`, which prez
does not yet link.** The injection could not reach the behaviour it was written against.

**This is the estate's recurring shape in a new place.** A hung watcher and a working watcher emit
byte-identical output; a control over unreachable code and a control over correct code emit
byte-identical output too. The discriminator is never the result. **Had it not been run, a control
asserted to be live would have shipped dead** -- and it would have been protecting the exact
property that this thread minted it to protect.

So the row was red-proved against what its body can actually reach: pointing prez's default at
`mono` fails the new test and leaves `no_theme_given_uses_the_embedded_default` green. 135 pass, 1
fails, and the one that fails is the new one. **That demonstrates the blindness finding rather
than restating it.**

**S8 therefore has a second, deferred half, and it is written down rather than remembered: the
reorder injection becomes live at wiring and must be re-run then.** A control that cannot fire yet
is not satisfied; it is scheduled.

### 1.7 Two rows of vc's measured a proxy instead of the property, and that is now a pattern

S2 said *the `[dependencies]` block is byte-identical*. S3 said *no edit to any test file*. Both
were mechanical checks standing in for properties -- *prez picks up no third-party cost*, and *no
existing assertion is weakened*. **Mechanical proxies are attractive because they are exactly
checkable, and they break the moment the implementation legitimately has to touch the mechanism.**
S1 forced a dependency edge, and S8 forced a new test; each broke its proxy while leaving the
property untouched.

**S3 is corrected the same way S2 was.** prez is now at 136 tests, so *no edit to any test file* is
literally false while its intent holds exactly -- as written the row forbids the addition this
thread asked for. It now reads as the property, with the mechanical check named as evidence rather
than as the requirement.

**The rule this thread is adopting: a criterion asserts the PROPERTY and names the mechanical check
as its evidence. It never substitutes the check for the property.** Both corrections are
strengthenings, and both were caught by cc before a file moved rather than after.


### 1.8 hv's four rulings, 2026-09-09

All four put with options and a recommendation; all four taken as recommended.

| # | Ruling | Consequence |
| - | ------ | ----------- |
| H-A | **AC02 sign-off GRANTED for `artifact = { path = "crates/artifact" }`**, as a one-off, named in the commit exactly as AC02 requires | WP-01 unblocked. AC02's wording is UNCHANGED -- hv declined to broaden it to a first-party/third-party distinction, so **if prez ever gains a second first-party crate the question returns, and that is deliberate** |
| H-B | **showreel gets a STANDING dependency budget in its own manifest**, mirroring AC02's shape but sized for a tool that must decode JPEGs. cc confirms current crate state and versions FIRST; hv approves the named list once at WP-03; additions thereafter need sign-off | WP-03's design point gains a gate. `HOIST.md` §6's list is a sketch and is **not** what was approved |
| H-C | **The command is `prez showreel build <dir>`** | Every document written so far is already correct. The shim, `showreel.yaml` and `help/prez.md` are written against this |
| H-D | **Republish the install NOW, before WP-03** | Sequenced -- see below |

**H-D has an ordering constraint that is not optional and was not visible when the question was
put.** `install.sh:582` and `:733` refuse a dirty source tree, and `:736` says plainly *"There is
no flag for this."* WP-01's work is uncommitted, so the tree is dirty and the republish cannot
run. The sequence is therefore:

1. H-A unblocks cc to wire and commit WP-01, naming the sign-off in the commit.
2. The tree goes clean.
3. Republish, and **verify by behaviour rather than by reading the install's `VERSION`** -- both
   invocation forms answer, and the provenance line names the tree and commit.
4. WP-03 may then shell out via PATH without exercising a stale tree.

Nothing before step 3 may reach `utilz` or `prez` through PATH.


### 1.9 TN001: the Rust build trap, and what Utilz owes it

hv raised this at the moment of granting H-A, citing the week lost to it in Intent and Lamplight:
`/Users/matts/Devel/prj/Intent/intent/docs/notes/tn001-one-test-target-per-crate.md`.

**The defect it names.** Cargo's `autotests` defaults to `true`, so every `.rs` file directly
under a crate's `tests/` becomes its own target -- a separate compile and a **full link** of the
crate and its whole dependency graph. Cost is linear in FILE COUNT, not test count. Nothing warns;
it grows one file at a time. Intent reached 166 links.

**Utilz's exposure, measured 2026-09-09: ZERO, and there is nothing to consolidate.**

| Check | Result |
| ----- | ------ |
| Rust `tests/` directories in the estate | **none** (the one `find` hit was a vendored Python venv -- my search was too wide and is corrected here rather than quietly) |
| `opt/prez/crate/test/` | singular, and holds `.sh`/`.mjs`/`.html` probes. **Cargo reads `tests/` only, so it is invisible to cargo entirely** |
| All 148 tests (prez 136, artifact 12) | `#[cfg(test)] mod tests` inside `src/`, compiled into the existing target. **No extra links** |
| `autotests` / `[[test]]` / `[profile.dev]` declared | none |

**So `autotests = false` is REFUSED for now, and the refusal is the note's own reasoning rather
than an oversight.** TN001 is explicit that consolidation without an orphan guard *"trades a LOUD
WASTE for a QUIET HOLE"*, and devbin's gate refuses exactly the case of discovery off with nothing
declared and `.rs` files in `tests/`. **With no waste to remove, adopting it today would create
the hole and buy nothing.**

### 1.10 But the workspace ALREADY opened a quiet hole, and it is measured

The estate's two `cargo test` call sites -- `opt/utilz/lib/common.sh:838` and
`.github/workflows/tests.yml:284` -- both pass `--manifest-path "$manifest"` and neither passes
`--workspace`. `crate/Cargo.toml` now carries a `[package]` as well as `[workspace]`, so cargo
operates on that package alone.

Driven, both arms, from a scratch `CARGO_TARGET_DIR` so as not to disturb cc's build:

| Command | Executables built |
| ------- | ----------------- |
| `cargo test --manifest-path Cargo.toml --no-run` (**what the estate actually runs**) | **1** -- `unittests src/main.rs` (prez) |
| `cargo test --workspace --no-run` | **2** -- artifact's lib AND prez |

**So `utilz test prez` and CI would run prez's 136 and silently skip artifact's 12.** Nothing
errors, the suite reports green, and a whole crate's tests never ran -- TN001's quiet hole
arriving by a different route: not `autotests`, but a call site whose scope no longer matches the
workspace's shape. **It passes by not existing.**

### 1.11 Four rulings, and the one that must not be a note

**W1 -- both call sites gain `--workspace`.** Without it every crate added after prez is invisible
to `utilz test` and to CI. Measured above: 1 executable against 2.

**W2 -- and `--no-fail-fast` in the same edit, not after.** Two targets means the first failing
crate hides the second's results. Lamplight's instance is the mirror of ours -- 17 failing targets
became 1 and the first failure hid the other sixteen -- and TN001 is explicit that you do not lose
a flag's benefit by omitting it, you **lose CI information you previously had**.

**W3 -- `[profile.dev] debug = "line-tables-only"` at the workspace root**, which is
`crate/Cargo.toml`. `cargo test` inherits `dev`, so one key reaches every test target. Keeps file
and line in a backtrace, drops what only a debugger reads. Costs nothing today and compounds.
`[profile.release]` is already there and already correct; S7 covers it.

**W4 -- the standing policy, and it is a CRITERION rather than a note, deliberately.** TN001's own
transferable lesson is that Intent ruled this estate-wide on 2026-08-27 and did not apply it until
2026-09-01, in the estate that authored the ruling -- *"a decision and its application were
separately tracked, and only one of them was."* **Prose does not fail.** So: **the first crate in
this workspace to gain a `tests/` directory adopts `autotests = false`, one declared `[[test]]`
target, and the orphan guard, in the same commit that adds the first file.** showreel is almost
certainly that crate, because the fidelity harness needs integration tests.

**The guard's subtleties, carried from TN001 so they are not rediscovered:** key on
`#[path = "..."]` and never the `mod` name, since the two are free to diverge and only the path
decides what compiles; plant a REAL orphan file rather than a synthetic control, because a walker
that returns empty on a `read_dir` error finds no orphans and goes GREEN when aimed at a moved
directory; both instruments assert their own corpus is non-empty; only the UNDECLARED direction
needs guarding, since a declared path with no file behind it is a loud compile error; and **the
guard cannot catch its own omission -- its declaration line in `suite.rs` is load-bearing and must
not be tidied away.**

**And the trap in proving any of it, which generalises far past this job: `cargo test <filter>`
EXITS 0 WHEN THE FILTER MATCHES NOTHING.** Exit 0 over zero filtered-out tests is byte-identical
to exit 0 over one pass. **Every arm asserts the COUNT, never the exit code** -- any harness that
selects by name and checks only `$?` is green from the moment the name drifts, and name drift is
silent, routine, and exactly what refactoring does.


### 1.12 The contract is minted, and the group digit is the WORK PACKAGE

**Form, from `intent-vc` with source (`preconditions.rs:428`, `fn is_ac_id`): `AC-<group>.<seq>`, both
parts digits, ANY group width.** hv ruled the width out on 2026-09-08 against a 13-estate census
that found 182 rows in the one-digit shape parsing correctly everywhere except in that one
function. `AC-HOIST-01`, `HOIST-AC-01` and `AC01` do not conform.

**And the group digit binds the row to a WORK PACKAGE.** `AC-1.x` renders under WP-01, `AC-5.x`
under WP-05, and a WP with no rows does not appear at all.

**vc minted 30 rows grouped by CONCERN, which misfiled three groups of five, and then retracted
and re-minted them.** The contract briefly asserted that the harness criteria belonged to the
Rust-build package and the build-topology criteria to the harness package. **The error is the
day's own class applied to the contract itself: the FORM came from a source and the SEMANTICS
were inferred.** Caught by reading the rendered view instead of trusting the mint's `ok`.

**Retraction used the path measured this morning** -- drop `criteria` from
`intent/.canon/st/ST0017.json`, `intent sync --to-store` -- verified PAST the daemon ingest rather
than at the write, on `intent-vc`'s warning that Intent's issue `0216` has a canon write reporting
`ok`, landing, and being reverted about a second later. 30 out, 33 back, `doctor` 0 both sides.

**33 rows: WP-01 twelve, WP-02 seven, WP-03 eight, WP-04 two, WP-05 three, WP-06 one.** The parts
sum to the total, which is the check a partition owes.

### 1.13 The day's dominant failure, with its instances

**ONE GREEN, GENERALISED ACROSS A POPULATION NOBODY MEASURED.** Eight instances, three nodes, one
day. Recorded together because the list is the evidence that it is a class rather than a run of
bad luck, and because each instance looked like diligence at the time.

| # | Instance | Whose |
| - | -------- | ----- |
| 1 | A control injected against code the crate does not yet link. Reordering `BUILT_IN` failed nothing and read as a pass | cc |
| 2 | A test named for a property its body does not check, twice in one file | cc |
| 3 | A comment claiming a prez failure "hides every other crate's results", corrected after driving it -- both arms ran artifact, because artifact's target happens to run first | cc |
| 4 | RMSE 0.0 measured on slide 3 and asserted of all 22 | snorkeltoast |
| 5 | Three peer nodes reported offline from a 90-minute-old listing, in which each name ALSO had a live row | vc |
| 6 | TN001's fail-fast example relayed as fact without driving it; lamplight-vc's mechanism reading says it runs backwards | vc |
| 7 | A `sed` range stopping at the first blank line, read as a missing dependency | vc |
| 8 | `0 unused-import hits` from a clippy run that exited 101 before reaching the check, read as "the gate is blind to it". Re-running to completion showed it reports both | vc |
| 9 | `check autotests` absent from `devbin check all` -- never instantiated, so nothing announced it, and the summary spoke for the survivors | cc, measuring |

**The sharpest statement of it is cc's, from #9: a gate that runs and finds nothing SAYS SO; a gate
that never activates has no voice. To a reader the two are indistinguishable.** That is why
`AC-1.12` requires every gate to be enumerated before a change is called green, and every gate to
report its own population including on passes.

**And cc's generalisation of their own case is the one to keep: "did it pass" is a question about
an INSTRUMENT, and it was answered without enumerating the instruments.** `cargo test` green felt
like done; the estate also runs `cargo clippy --all-targets -- -D warnings`, and that list was one
grep away.


### 1.14 The day's rule, in snorkeltoast's words, with the three instances under it

**A WRONG MODEL THAT AGREES WITH A RIGHT ONE AT THE SAMPLED POINT IS MORE DANGEROUS THAN A WRONG
MODEL THAT DISAGREES**, because the agreement reads as validation and nothing prompts anyone to
check the structure underneath.

Three instances on 2026-09-09, all of which agreed exactly where they were looked at and were
wrong about the mechanism:

| model | where it agreed | what it got wrong |
| ----- | --------------- | ----------------- |
| vc's two-mode fit of q | landed on n=13, which is also where the three-mode count lands | there are three renders, not two. The next reel with different proportions separates them |
| snorkeltoast's `(2/3)^C(n,2)` | exact at n=2, where one pair makes independence trivial | pairs share captures and are not independent trials |
| the blank-frame detector | agreed with the truth on the one frame it was checked against | read 55.75 percent has-content on the actual empty frame it was built to catch |

**And in each case the thing that broke it was measuring the STRUCTURE rather than the OUTCOME:**
counting distinct renders instead of fitting a rate; localising a diff to a bounding box instead
of quoting an RMSE; looking at an image instead of reading its number.

**The same move then closed the question it was raised against.** vc's objection was that an
unobserved render could raise slide 14's floor above any sampled maximum -- a statistical worry
with no statistical answer. Localising the three renders showed they differ only at the two
ENDPOINTS of one 59-pixel edge, so each end rounds one of two ways independently: A=(0,0),
C=(0,1), B=(1,1), and a predicted D=(1,0) that thirty captures have not produced. **The largest
possible difference is both endpoints flipping, which is A-to-B, so 0.002196 is a ceiling rather
than an estimate and no unobserved mode can exceed it.** The tail is closed by structure, not
narrowed by sampling.

**Confirmed independently, by magnitude where the argument was from geometry:**
`RMSE(A,B) / RMSE(A,C) = 1.41404` against `sqrt(2) = 1.41421` -- exactly what four differing
pixels against two of equal delta predicts. Two different claims agreeing, rather than one claim
made twice.

---

### 1.15 R2 names the right rule and no needle list can implement it -- measured, WP-03 opening

R2 ruled the RULE: *protocol-relative in `url(...)` and in `@import`, not in arbitrary string
content.* It did not rule the INSTRUMENT, and the instrument is what fails. Measured before
writing any code, 13 fixtures against the binary rebuilt from `5e86fc5`, two behaviour controls
plus two detector controls. **EIGHT of thirteen are decided wrongly, and every one of the eight
ships its reference into the artifact.** The full table lives in **issue 0017** and is not
restated here.

**The count was NINE for one commit, and the correction is the section's own lesson landing on its
author.** Nine references reach the artifact; only eight of them are escapes. The ninth is F2, a
url inside a comment, which is CORRECT to ship, fetches nothing, and is present as the detector's
presence arm. Two nearly-equal populations -- *reached the artifact* and *decided wrongly* -- were
read as one because they differ by a single row. **The red-proof is what separated them**: the
inverted suite named exactly eight, against a design document asserting nine, and a discrepancy of
one is precisely the size that gets reconciled by eye instead of by counting.

**Five mechanisms, three issues, and only four of the eight escapes were already filed:**

| Mechanism                                     | Fixtures   | Owner         |
| --------------------------------------------- | ---------- | ------------- |
| `@import` with a bare quoted target           | E1, E2     | issue 0014    |
| Scanner truncates before the reference        | E7, E8     | issue 0015    |
| `url( //x )` -- whitespace inside the token   | E4         | **issue 0017** |
| `URL(` / `HTTP://` -- ASCII case              | E5, E6     | **issue 0017** |
| `@import` NEWLINE `"//x";` -- one at-rule, two lines | E9  | **issue 0017** |

**RULED: a reference-site scanner, not a longer needle list.** The three mechanisms 0017 names
are properties of CSS tokenisation -- case-insensitivity, whitespace tolerance, newline tolerance
-- and a substring list cannot express any of them. Widening the list means enumerating `url(`,
`URL(`, `Url(`, `url (`, `url(\n` crossed with each quoting form: **a list sized to the instances
someone happened to try, which is this thread's dominant failure wearing a security hat.** The
port therefore recognises the two SITES R2 names -- a `url()` token and an `@import` prelude --
and reads their target, rather than hunting for spellings anywhere in the text.

**And the change is a UNION, so nothing that refuses today builds tomorrow.** The coarse
absolute-scheme net (`http://`, `https://`, now matched case-insensitively) stays, over all
non-comment text, because it catches reference shapes nobody has enumerated -- `image-set()`,
`@namespace`, whatever CSS gains next -- at the cost of a false positive on a URL inside a string,
which is the cost it already has. Site-aware protocol-relative detection is ADDED beside it.
**Loosening a check that guards the offline guarantee is a decision; this change makes none**, and
that is deliberate so the fix needs no ruling beyond R2's.

**One behaviour change beyond AC-3.5's letter, stated rather than slipped in: an unterminated
comment is REFUSED by name.** Today `strip_comments` returns everything before an unclosable `/*`
and the scan never sees the rest (`None => return out`). Once the scanner knows string literals,
`content: "/*"` stops being a comment opener and 0015's serious half closes -- but a GENUINELY
unterminated comment still ends the scan, and ending a security scan early without saying so is
`IN-AG-NO-SILENT-001`. Truncation is defensible on browser semantics (the rest is commented out
for a reader too) and indefensible as silence. **Refusal is the smaller claim: the theme is
malformed, and half of it is not applying.** Flagged to vc as possibly wanting its own row rather
than riding under AC-3.5.

**THE DETECTOR REPRODUCED THE DEFECT IT WAS MEASURING, AND NOTHING ERRORED.** The probe's first
artifact-side check was `grep -E 'url\([^)]*//|HTTP://'` -- line-oriented and case-sensitive, the
two exact blindnesses under test. It reported E5 and E9 as **not reaching the artifact**, the
comfortable answer and the wrong one. Both were recovered only because the rewritten detector
(flatten newlines, match case-insensitively, key on the HOST FRAGMENT rather than on the
reference's shape) disagreed with the first. **A case-blind instrument measuring a case-blind
defect returns a clean result, and it looks exactly like a clean result.** The general form is
already this board's: an instrument that shares an assumption with its subject cannot test that
assumption. Keying the detector on the payload rather than on the syntax is what broke the shared
assumption, and it is the cheap move worth reaching for first.

### 1.16 The CSS half validated on the population that ships, and the two rulings cc asked for

cc's evidence for `cd0412d` is thirteen synthetic fixtures with four controls, and it is the right
evidence for the question cc was answering. It says nothing about the themes that actually exist,
which is the other half of the risk: a scan made stricter can refuse something that already ships.
**Nine real `theme.css` files, built through `./bin/prez` rather than asserted through a unit test,
with both controls over that same mechanism: `built=9 refused=0`.** Seven prez built-ins plus
showreel's `default` and `popupart`. The red control is a WRAPPED `@import "//cdn..."` -- E9, the
escape a line-oriented needle list cannot see -- and it refuses; the green control is
`content: "//"`, R2's named false positive, and it builds. **The red control refusing a wrapped
at-rule is also how the binary proved itself current**: the replaced code could not have refused
that, so the artefact under test is `cd0412d`'s rather than yesterday's, established by behaviour
instead of by a timestamp.

**RULING 1: the unterminated-comment refusal gets its own row, AC-3.12.** cc raised it in its own
commit rather than slipping it in, and asked. It is separate from AC-3.5 for the reason cc gave --
it refuses a population AC-3.5 has no interest in, a malformed theme carrying no external reference
at all, and a user can hit it with a theme that was building yesterday. The second reason is
stronger and cc did not give it: **AC-3.5 is going to go green and stop being read.** A behaviour
change whose only record is a satisfied row's implementation detail has the same lifetime as prose,
and prose does not fail.

**RULING 2: AC-3.5 stays ONE row, and its wording was wrong in the way this thread keeps being
wrong.** Splitting it into a CSS half and a `theme.yaml` half would turn a property into an
enumeration of surfaces, and a third surface would then have no row at all; the honest signal of a
half-built row is that it stays unsatisfied, which is exactly what cc did rather than asking for a
mark. But the row said *"in CSS and in theme.yaml"*, and that IS the enumeration, one level down --
**the code was already broader than the row on the day the row was written.** Reworded to the
property, with the surfaces named as the instances they are.

**cc's premise for the deferral is wrong on the facts, and that is the useful half of the ruling.**
R3 does not wait on showreel's theme manifest existing.
`.../showreel/themes/popupart/theme.yaml` exists today, is read at `showreel:198`, and carries
`favicon:` and `fonts[].file` -- precisely the reference-bearing fields. What R3 waits on is
WP-03's own YAML loader, with a live example to test against, not a dependency on something
undesigned.

**AND MY OWN POPULATION WAS NARROWER THAN THE CODE'S REACH, WHICH IS A NEW SHAPE OF THE OLD
ERROR.** Nine of nine is complete for the disk. `refuse_external` has THREE call sites --
`theme.css`, `theme.js` and `layout.html`, at `artifact/theme.rs:201-206` -- and the estate holds
ZERO of the last two, so a clean sweep of every theme that exists answers for one surface of three
while reading as though it answered for all of them. `strip_comments` implements CSS's comment and
string grammar, which JS and HTML do not share. **A population drawn from the disk answers for the
disk; the code's population is its CALL SITES, and enumerating one is not enumerating the other.**

**THEN THE DIRECTION QUESTION REVERSED THE RULING, AND FIVE AGREEING SAMPLES NEARLY STOPPED IT
BEING ASKED.** Neither cc nor vc had asked which way the mismatch errs, and both of us had assumed
over-refusal -- a `theme.js` attribution in a `//` comment refused, an HTML attribution in
`<!-- -->` refused, annoying and loud. Five cases were built across both non-CSS surfaces and all
five agreed: over-refusal, never under. On that evidence the ruling was going to be *a usability
defect on an empty population, safe to defer.* **The sixth case was built to attack the hypothesis
rather than to confirm it, and it reversed it.** A live `<a href="http://evil.example.com">` in
`layout.html`, sitting between a stray `/*` and a later `*/` -- both ordinary text in HTML -- is
stripped by the CSS comment stripper before the scan runs, and it SHIPS, confirmed at the artifact
on line 2 as live markup, against a control that refuses the identical href without the two
markers. **Filed as issue 0018: the same class as 0014, 0015 and 0017, on the surface none of them
looked at.** So AC-3.13 is not dischargeable by writing down that the CSS scanner is adequate,
because it is not; and 1.14's rule -- *a wrong model that agrees with a right one at the sampled
point is more dangerous than one that disagrees* -- landed on its own author one section later, at
a sample size of five.

**THE THREE CONTRACT CHANGES ABOVE WERE COMMITTED BY cc, IN `8dea619`, WHOSE MESSAGE IS ABOUT
SOMETHING ELSE.** They were minted into the working tree and not yet committed when cc staged, and
cc's pathspec swept them up. The content is correct and is NOT being reverted: the repair for an
incomplete record is a later record, not a rewritten one. **It is the second instance of this class
in two days and the first was vc's** -- `git add -- intent/` in `688974c` dehydrated ST0016 as a
side effect of a commit about harness statistics. Two nodes holding one pen over one tree need
separation at COMMIT time and not only at write time: **a broad pathspec is how carefully written
work still lands in the wrong commit, under someone else's reasoning.**

### 1.17 Three numbers corrected, and a citation class that expires without saying so

**AC-2.17's 6.29 was never a measurement of what the row said it was.** snorkeltoast re-measured the
same injection at 0.999752, could not source 6.29, and recorded pre-`6c278a2` `pace=ambient`
contamination as a HYPOTHESIS rather than a finding. **The arithmetic closes it without needing the
hypothesis.** `showreel-harness`'s `rmse()` sums squared differences over RGB and divides by
`3*W*H`, so a one-level change on every pixel of a 1920x1080 frame is **exactly 1.000000**, and
0.999752 is that identity less the pixels clipping at 0. 6.29 would require an average shift of 6.29
levels, so whatever it measured it was not a one-level injection on a clean capture. **A number that
is an IDENTITY was read for a day as an empirical constant**, and what separates the two is one line
of arithmetic against the estimator's own definition.

**The row's small-extent example was wrong too, in the direction that strengthens it.** This row and
FLOORS.md both said a one-level change over four pixels measures 0.002196. It measures **0.001389**.
0.002196 is slide 14's MEASURED floor, and implies about 1.58 levels over four pixels -- which is
exactly what 1.4's two anti-aliased endpoints rounding independently produce. **So a true one-level
four-pixel defect sits BELOW slide 14's floor rather than equal to it, and slide 14 cannot grade
it.** The rhetorical point survives; the constructed example was doing the opposite of what it
claimed, and it read as support because it agreed at the one figure both sides quoted.

**AND THE PARAGRAPH THAT STOOD HERE WAS WRONG TWICE, BOTH TIMES MINE.** It read: *the identical
procedure reads 0.998249 to 2.280042 across the reel's eight image slides -- a 2.3x range inside one
artifact, decided by picture content, with the readings above 1.0 being pixels that move more than
one level where the darken clips.* **Neither half survives.**

**The 2.3x was a JPEG generation, not the injection.** snorkeltoast ran the control the script had
never had -- re-encode with NO injection at all -- and the pure injection spans **0.4 percent, not
2.3x**. The range was the harness decoding and re-encoding at q86. On slide 0, a PNG logo on black
with 71 percent of channels already at zero, **2.24 of the 2.28 is re-encode alone**.

**And the clipping explanation was backwards on its face.** Clipping at 0 means a pixel cannot
darken, which can only LOWER the figure -- it cannot raise one above 1.0, and 1.0 is the identity's
ceiling. vc verified the real relation: `sqrt(1 - clipped_fraction)` predicts every pure value to six
decimals, 0.718 percent clipped giving 0.996404 and 0.003 percent giving 0.999984. **So the injection
is near-exact and has no picture-content dependence at all beyond the pixels that physically cannot
move.** I asserted a mechanism in the direction that suited the argument and did not check that it
could produce the sign it needed -- the same error as this morning's ambient scaling, where I
described a comparison against a case I had never computed.

**What survives is the sqrt-area leg, which was always the load-bearing one and is now exact.** A
full-frame one-level defect measures 1.000000 and a four-pixel one measures 0.001389: a factor of
720, which is `sqrt(2073600/4)` and nothing else. **Any constant taken from an injection is blind to
defects of smaller extent by exactly the ratio of their extents.** The withdrawn leg was rhetorical
support; this one is geometry, and it alone decides the row.

**A LIMIT OF THE RED-PROOF, snorkeltoast's, and this row's earlier wording implied otherwise.**
`redproof` darkens AND re-encodes at q86, so its reported figure is not a pure one-level injection.
Both plausible targets on this reel are JPEG, so today's result stands; a reel of PNG sources would
red-proof against a mostly-different defect than the one its label names. **Which is exactly why
hv's ruling names a DESCRIPTION and computes the number from it, rather than taking an injection's
figure** -- a decision made before this limit was known, and better founded because of it.

**hv RULED THE MAGNITUDE 2026-09-09: a one-level shift over 5 percent of the frame, RMSE 0.223607.**
The threshold is `sqrt(f)` and therefore **independent of frame size**, so it is a property of the
defect rather than of 1920x1080 and transfers to any reel. Slide 13's floor sits 149x below it and
slide 14's 102x, so 21 of 22 become gradeable and only slide 1 remains, waiting on AC-3.7.

**THE CITATION SWEEP: FOUR OF EIGHT STALE, AND THE PARTITION IS PERFECTLY CLEAN.** cc found two rows
citing a line for the brand literal that `3903937` had moved, and named the structural point: an AT
row is refused unless its id appears literally in the file it cites, and **a line number inside AC
TEXT sits under no such check.** Sweeping the whole population rather than repairing the two: eight
line citations across six rows, **four stale and every one of them `player.html`, four correct and
every one of them `showreel`.** The file the crawl fix touched took all of the rot; the file it did
not touch took none. **The citations were not careless. They were true when written, and nothing
reports the moment they stop being true.**

**The fix is to cite the TOKEN, and the second half is not to record the dead number.** The re-sweep
caught the repair twice: the rewritten rows still contained the old `player.html:613` inside the
sentence explaining that it was wrong, and **to a scanner a superseded citation and a live one are
the same bytes** -- which is the property that made the original invisible. Two other rows carried a
bare `line 547` that the first detector's `file:NNN` pattern could not see, so the detector had to be
widened by the same failure it was built to find. Final state: four citations, all `showreel`, each
verified against the file; zero `player.html`; zero bare mentions.

**RULING for cc on the brand literal.** It lands in OUR copy of `player.html` when WP-03 pulls the
template, in a commit carrying ST0017, with AC-3.7's check in the SAME commit so the fix and its
control arrive together. **Not in snorkeltoast's tree**: they have stopped on hv's scope call, and a
peer's working tree is not ours to write. **And the divergence is recorded where the "unchanged"
claim is made** -- section 11 lists the player as *unchanged by the port*, which stops being true the
moment our copy differs by this one line. Two copies, one line apart, until WP-06 retires theirs.

### 1.18 The two withdrawn mechanisms are one failure with two faces, and there is a third kind of number

**Both mechanisms withdrawn in 1.17 were wrong, and neither could have been caught by rereading.**
snorkeltoast's pairing is the useful form and the credit is theirs:

- **vc's failed on a SIGN it could not produce.** Clipping at 0 means a pixel cannot darken, so it
  lowers the figure and can never raise one past the identity's ceiling of 1.0. The claim was
  self-refuting in one line of arithmetic and never got the line, **because it was explaining a
  number rather than being tested against one.**
- **snorkeltoast's failed on a CORRELATION it did not own.** Picture content genuinely varies, the
  readings genuinely varied, and the story joined them. Nothing about it was implausible, which is
  why neither node questioned it. **The re-encode control is what separates a mechanism that COULD
  produce the effect from the mechanism that DID.**

**Neither of us ran that control because the story was already complete**, and that is the operative
half. An explanation that fits suppresses the test that would separate it from the explanation that
is true, and the better the fit the stronger the suppression. It is 1.14's rule -- a wrong model
agreeing with a right one at the sampled point -- in the EXPLANATORY direction rather than the
measurement direction. The two faces are worth keeping apart because they fail differently: a sign
error is checkable against the estimator's own definition by one person in one line, and a
correlation error is not checkable at all without running something.

**AND A THIRD KIND OF NUMBER, snorkeltoast's, which is the one to watch for.** Asked for AC-2.17
satisfiable on measurement rather than on prediction, they could have produced the buckets exactly by
re-deriving `ctl9`'s stored measurements through `verdict_for` -- the function is pure and
`control.json` carries every input it takes, so the derivation is not an estimate. **They declined to
circulate it.** An exact re-derivation is neither a measurement nor a prediction; it is a third thing
that looks like the first, and **it is the most dangerous of the three precisely because it is
CORRECT.** A prediction is visibly a prediction and carries its own warning. A re-derivation carries
the authority of arithmetic while describing a run that has not happened. The reason they gave is
this day's own evidence: three sessions spent it copying a stale line number from one another, so a
figure entering circulation twenty minutes before the thing it describes exists will outlive whatever
caveat is attached to it. **The caveat and the number travel at different speeds, and only one of
them gets quoted.**

### 1.19 A model was doing more than either of us read it as doing, which is the day's error inverted

**hv's magnitude is measured, not predicted: 21 gradeable, 0 undecided, 1 ungradeable, 0 windowless,
of 22**, against `--min-defect 0.223607` on artifact `daaa503ad7db` at 13 captures a slide. Slide 13
clears by 149x and slide 14 by 102x. **Only slide 1 remains and it waits on AC-3.7's brand literal
rather than on any magnitude** -- the one slide the reel cannot grade at any value.

**The finding is in the third render, and it is a shape this day had not produced.** Every other
error today was a model doing LESS than it appeared to -- agreeing with a right one at the sampled
point, generalising a member to a set, explaining a number rather than being tested against one.
**This is the inverse: AC-2.3's mechanism was doing more than anyone read it as doing.** Two
endpoints rounding INDEPENDENTLY predicts four combinations, not two. The row was written from two
observed renders and read, by both nodes, as an explanation of those two. It was a prediction of four
the whole time. snorkeltoast's words: *I had been treating your model as an explanation of two
renders; it was a prediction of four all along and I did not read it that way.*

**AND IT WAS AN UNREAD PREDICTION RATHER THAN A MISSING ONE, WHICH IS WORSE.** snorkeltoast's point:
the row said *predicted D=(1,0)* in vc's own notation, on the page, from the morning -- and neither
node treated it as a prediction for six hours. **An unused prediction is invisible exactly when the
used ones fit.** It is the same failure as the stale `:613` that crossed three sessions: not an
absent fact but an unread one, where every reader had access to the thing that would have corrected
them and none of them looked because nothing prompted a look.

**So the third render arriving on its own is the prediction being TESTED rather than fitted**, and
the distances land where independence requires. Counted in squared-difference units over `rmse()`'s
divisor of `3*W*H`, one endpoint is 15 units and two are 30, so `C-A` and `C-B` are both
`sqrt(15/6220800) = 0.001553` and `A-B` is `sqrt(30/6220800) = 0.002196`, **additive to the unit and
fitted to nothing.** That reproduces this row's independently measured `RMSE(A,B)/RMSE(A,C) = 1.41404`
to five decimals, from absolute counts rather than from a ratio.

**A structural model earns its name by predicting the case it was not built on**; until then it is a
description of the case it was built on, wearing a mechanism's clothes. **And vc's first attempt at
that second arm was not one, which is snorkeltoast's correction and it stands.** I offered
`sqrt(14/6220800) = 0.001500` from slide 13's counted deltas against its reported floor, and called
it the stronger arm. **`rmse()` IS `sqrt(sum(d^2)/N)`** -- so that recomputes the reported figure from
the same measured pixels, over the same expression, and the model is consulted on neither side. It
confirms the pixel COUNT, which is worth having and would catch a miscount. It confirms nothing about
the mechanism. **A correct number, next to a real result, carrying more authority than it earned** --
today's failure in its most flattering costume, and produced by the node that spent the morning
catching 6.29 as an identity misread as a constant. Same confusion, opposite direction: that one read
an identity as a measurement, this one presented an identity as a confirmation.

**The genuinely predictive arm on slide 13 is STRUCTURAL and it does hold.** The model, derived from a
59-pixel edge, predicts the SHAPE of the difference -- exactly four pixels, two per endpoint, at the
two ends of a single vertical edge -- and counting on slide 13's 74-pixel edge confirmed it. That is
the arm; the arithmetic identity must not travel beside it, because if it does it will be quoted as
though it were a second one.

**And the ceiling is now FALSIFIABLE, with both unused predictions recorded before any run tests
them.** Slide 14's fourth state must land at 0.001553 or 0.002196. Slide 13 has shown two of its four
predicted renders, so a third must land at `sqrt(7/6220800) = 0.001061` or at 0.001500 -- **and on
slide 13 a wrong distance falsifies the account on the slide the model was not built from.** Any
future control run tests both for free, which is the whole reason to write them down first.

**Which turns the floor from a sampled maximum into a ceiling, FOR THESE TWO SLIDES ONLY, and
snorkeltoast is explicit that it does not generalise.** Three of four predicted combinations are now
observed across 26 captures, the fourth cannot exceed 0.002196 because there is nothing above it to
sample, and no pixel outside the four has differed. **Any other multi-render slide is a lower bound
again until someone counts its pixels: the mechanism has to be IDENTIFIED before the ceiling argument
is available at all.** That restraint is the reason the argument is worth having -- a ceiling claimed
by analogy would be a sampled maximum with better prose.

### 1.20 Counted: one correction in twenty came from rereading

snorkeltoast closed the day with a generalisation worth checking rather than repeating: *six of my
own claims needed correcting today and every one was caught by someone else -- it is a fact about
what a single reader can do to their own work.* **Counted over vc's twenty recorded corrections,
the split is not self versus other. It is INSTRUMENT versus READING.**

| how it was caught                                                                              |  n |
| ------------------------------------------------------------------------------------------------ | --: |
| **A peer** -- cc, snorkeltoast, lamplight-vc, hv                                                | 9  |
| **An instrument the node ran on its own work** -- a failing test, `doctor`'s file count, the clock guard, the rendered view disagreeing with the mint, a re-run without `-D warnings`, FLOORS.md, vc's own citation re-sweep | 10 |
| **The node rereading its own prose**                                                            | 1  |

**The one is S2 and S3**, corrected from mechanical proxies to properties -- and even that was
prompted by having to write them into a contract for someone else to read, so the honest figure may
be zero.

**This changes what follows from it.** snorkeltoast's version argues for a second person, which is
expensive and does not scale to the hours when nobody else is awake. The measured version argues for
something cheaper and always available: **a node cannot review its own prose into correctness, but it
can instrument its own work, and half of today's corrections came from exactly that.** The clock
guard refused a fabricated timestamp; `doctor`'s file count caught a dehydration made as a side
effect; the citation re-sweep caught the first sweep's own incomplete repair. **None of those needed
another node and none of them needed more care.**

**It also re-reads snorkeltoast's own six.** Their re-encode control was their own instrument, built
and run on their own claim -- the PROMPT came from a peer, the CATCH came from the instrument. That
is the general shape: peers are good at prompting a look, instruments are good at making the look
conclusive, and rereading does neither.

**And the caveat is not decorative: this measurement is a node classifying its own errors, which is
precisely the activity the finding says is unreliable.** A self-assessment that concludes
self-assessment does not work is either the strongest form of the claim or an instance of it, and
nothing inside the assessment can tell which.

**snorkeltoast then counted their own six against the commit record rather than from memory, and the
axis holds: caught by rereading, ZERO.** Two of six were caught by an instrument they ran on their own
work with no peer involved -- the rep-0 anchoring, where two runs of one artifact disagreed in their
own logs, and 6.29, where re-running `redproof` put 0.999752 next to a number they had been citing all
day. **Neither needed more care. Both needed a number printed next to another number.**

**And their own observation about why their version was appealing is the sharpest thing in it:**
*"every one was caught by someone else" is a claim about collaboration that quietly excuses the
absence of instruments.* It is the more flattering finding and the less actionable one.

**THE LIMIT IS REAL AND TWO SELF-ASSESSMENTS DO NOT BREAK IT.** They were made independently over
disjoint error sets and agree on the axis, which is weak evidence and not nothing. What would be
strong is a third node classifying both sets, and cc holds both in its transcript while owning
neither. **Offered to cc as optional and explicitly not blocking** -- it is methodology while WP-03 is
mid-flight, and the individual instruments justify themselves on their own record regardless of what
the aggregate says.

**But the boundary cases cannot move the headline, and that is worth stating because snorkeltoast
raised exactly the right worry -- that a node would classify its own borderline cases in whichever
direction read better.** The split cases are those where a peer PROMPTED and the node's own instrument
CAUGHT: snorkeltoast's 2.3x, and vc's clipping sign error, where snorkeltoast's data said a claim
could not be true and vc's own arithmetic against `rmse()`'s definition said what was. **vc counted
every split case as "peer", which is the direction that WEAKENS vc's own finding** by shrinking the
instrument column. And whichever way they fall they are not rereading, **so the one number the finding
rests on is untouched by the judgement calls.** A result that cannot be moved by its own author's
boundary decisions is the only kind a self-assessment can honestly report.

### 1.21 A narrowed view agreeing with itself, which is the unification of two opposite mistakes

**snorkeltoast ran 1.20's discipline -- stage explicitly, then read the WHOLE tree and expect it
clean -- in place of the scoped `git status --short bin/showreel/` they had run after every commit
all day, and it found something worse than staging drift within five minutes. The 45h reel is
entirely untracked: 23 files, 15 MB, ZERO under git.** Verified here, and it is unadded rather than
excluded -- no ignore rule matches it, and its parent directory carries three tracked files.

**So FLOORS.md cites `sha256 daaa503ad7db` for a build that exists on one machine.** The hash
identifies the artifact precisely and makes it no easier to obtain, and letting a reader verify was
the sha's only function. **A provenance line that cannot be followed is most of a provenance line
missing** -- correct, unfalsifiable by inspection, and useless in exactly the situation it was
written for. An afternoon was spent making the table citable without checking that its subject was
reachable.

**The mechanism is 1.20's inverted, and snorkeltoast's statement of the pair is the durable one:**

- **An explicit pathspec drops your own work** while the working tree stays consistent, so nothing on
  the machine is wrong and nothing reports it.
- **A scoped status check reports clean** while the tree is fine and the repository is not.

**Both are a narrowed view agreeing with itself.** That is why the covering fix is a DISCIPLINE and
not a rule about pathspecs: the failure is not in either command, it is in asking a question whose
scope already excludes the answer.

**THE 15 MB IS THREE DECISIONS AND MUST NOT REACH hv AS ONE.** Measured here, because *"committing
the reel is a repository decision"* is true and is the wrong shape:

| component       | size   | files | what it is                                            |
| --------------- | ------ | ----: | ------------------------------------------------------- |
| `showreel.yaml` | 8 KB   |     1 | the reel's DESCRIPTION -- costs nothing                |
| `assets/`       | 5.7 MB |    16 | the source images -- **the actual decision**          |
| `_out/`         | 9.2 MB |     3 | DERIVED, regenerable, and never a thing to commit     |
| `.raster/`      | 256 KB |     2 | intermediate cache -- wants an ignore rule            |
| `.DS_Store`     | 12 KB  |     1 | junk -- wants an ignore rule                          |

**Nine of the fifteen megabytes are an answer nobody should store.** The question is 5.7 MB of source
images, and the 8 KB that makes the reel describable is free.

**AND OBTAINABLE IS NOT BYTE-REPRODUCIBLE, which is the distinction the sha quietly conflates.**
Committing config and assets makes the reel REBUILDABLE, not identical: the encoder's bytes depend on
its version, **which is the same fact that makes WP-02 necessary for the Rust port at all**. A rebuild
yielding a different sha is not evidence of a defect and not evidence of its absence. **The sha
identifies, the inputs make it rebuildable, and only the harness makes a rebuild gradeable** --
provenance is followable with all three and with no two of them.

**AC-2.18 carries the property. AC-2.17 and AC-2.3 stay satisfied and their evidence now states the
limit**, because both rows concern the METHOD and the method was demonstrated -- but a reader must
not take their sha as an offer of verification it cannot honour.

### 1.22 Two rules from snorkeltoast that generalise what this document had, and one zero re-proved

**"A TOTAL IS A SUMMARY, AND A SUMMARY OF A DECISION IS NOT A DECISION."** snorkeltoast's general form
of 1.21's decomposition, and it is better than the instance. *15 MB, hv's call* reads as a decision
because it has a number in it, and **anyone acting on it would have been deciding about `_out/`** --
9.2 MB of derived output that should never be stored. It is the same shape as a global floor standing
in for per-slide ones, which is the defect they spent the morning removing from the instrument and
then reproduced in prose about the instrument's own provenance. Two rows now, priced separately.

**"A CHECK THAT FIRES IS EVIDENCE ABOUT THE THING CHECKED; A CHECK THAT DOES NOT IS EVIDENCE ABOUT THE
CHECKER, AND ONLY IF IT COULD HAVE FIRED."** Theirs, from grepping twenty-three of their own messages
for vc's heredoc failure and finding nothing. **The nothing is worth something only because unquoted
heredocs were reachable for them** -- one keystroke away, with no rule against them, only a habit. A
zero from a check the subject could never have tripped is evidence about neither.

**Applied here, to a zero this document reported without earning it.** The citation sweep's final line
was *bare `line NNN` mentions: none* -- and that detector was WRITTEN in the same command that ran
after the fix, so it had never been observed to fire. `IN-AG-RED-CONTROL-001`, reported as a result.
**Red-proved retroactively against a fixture, with the injection's application proved before the
result was read**: restoring one bare mention to AC-3.11 exactly as the row read before the repair,
anchor occurring exactly once, makes the detector report `1 [('AC-3.11', '549')]` against the live
tree's `0`. **The detector can fire, so the zero is a result.** It held -- which is the outcome that
makes the check worth having rather than the one that makes it interesting.

**And their own instance of the day's dominant shape, which they caught in themselves:** they had
written the untracked reel as though tracking would make the sha resolvable. It would not, because the
encoder's bytes depend on its version -- **and they were assuming the negation of that fact one
paragraph after relying on it** to justify the harness existing at all. The harness is not bookkeeping
around the port's evidence; **it is load-bearing in its own provenance**, because without it a rebuilt
artifact with a different sha is uninterpretable and every reader is left where this thread was at
breakfast, holding a number nobody can say anything about.

### 1.23 Put the caveat where the number is PRODUCED, and the only failure mode still standing

**snorkeltoast ran 1.22 against their own instrument and found the same shape: FLOORS.md was
publishing `0 windowless` from a detector nobody had seen work.** `capture_budgets()` had never
returned `None` in any run, which from outside is indistinguishable from a detector that cannot. Being
a pure function it cost nothing to prove -- five cases including the legal `ease 3000 / dwell 2500`
that `LIMITS` permits and this reel never contains. **Their boundary case caught its author's
arithmetic before it caught any of the code's** (a dwell written for a one-millisecond window is
5801ms), and they left the error in the comment, because a new test's first catch being its author is
the correct order and worth someone seeing.

**THEIR ANSWER TO THE CAVEAT-AND-NUMBER PROBLEM IS THE BEST THING IN IT, AND IT IS STRUCTURAL RATHER
THAN EDITORIAL.** 1.18 recorded that a caveat and a number travel at different speeds and only one of
them gets quoted. There is exactly one place that cannot be outrun: **put the caveat where the number
is PRODUCED, not where it is reported.** `selftest` now prints its own on every run, and FLOORS.md
grades its own zeros -- two results, one weaker, with the reason. **A document can be quoted without
its caveat; the instrument's own output cannot.** Their audit names two checks never observed to fire
and states them rather than fixing them, which is the same choice as leaving the red-proof's
re-encode limit labelled.

**THE RECIPROCAL AUDIT, RUN HERE RATHER THAN ASSERTED.** Five zeros or absences published by vc today:
the theme population's `built=9 refused=0` (red control refused in the same run, by design); the
citation sweep's `0 player.html survivors` (same detector reported 4 stale and then 2 earlier the same
day, and `git log -S` confirms two commits carried real subjects); AC-1.16's build-gate result (both
arms driven); AC-3.13's zero `theme.js` and `layout.html` (a CENSUS of the tree, not a detector --
nothing to fire, and the distinction matters); and the bare-mention zero, **which was the one that had
not earned it and has since been red-proved against a fixture.** Four sound, one repaired, and the
audit is worth more than the result because it was run.

**AND THE FAILURE MODE LEFT STANDING IS THE ABSENT PROMPT, NOT THE ABSENT RULE.** snorkeltoast's
closing observation and it is the day's synthesis: both nodes had `IN-AG-RED-CONTROL-001` on their
boards all day, both had it filed under injections, and **neither thought to point it at a negative
until the other one did.** Neither of us was short of the rule. That is 1.19's unread prediction
again, and 1.17's stale citation, and 1.20's count showing rereading catching one correction in
twenty -- **the same hole in three costumes.** Every rule this document contains was already known to
its author at the moment it was broken.

**One last thing of theirs, against the temptation this document creates:** *the corrections that
mattered were mostly not the clever ones.* The instrument they would put first is `load_control`'s
stale refusal -- **nine lines**, which caught a two-render slide being described as one-render in the
same sentence that explained why it could not be graded. Cheap, boring, and it fired on the first real
input it saw.

### 1.24 A zero has three kinds, and the third one reads exactly like the other two

**snorkeltoast's census-versus-detector split, taken one further by the table they had published
twenty minutes earlier grading its own zeros.** `0 undecided` was a TAUTOLOGY in that run.

| kind          | why it is zero               | what it is worth                                  |
| ------------- | ---------------------------- | --------------------------------------------------- |
| **census**    | nothing was there to count   | sound; it cannot fail to fire and has nothing to prove |
| **detector**  | nothing fired                | sound only if it COULD have fired                  |
| **tautology** | the branch was never reached | **nothing.** The configuration decided it          |

**Verified here in the source rather than relayed.** `verdict_for` tests `unprovable_reason`, then
`presence <= floor`, then `if min_defect is not None` -- which returns UNCONDITIONALLY -- and the
`renders > 1` UNDECIDED branch sits below it. **Naming any magnitude whatever makes that count zero
before a pixel is captured.** It is not a detector that stayed silent; it is a detector that was
switched off, printed beside two real zeros where it read as a third.

**And it lands on this thread's own evidence, so AC-2.17 now grades its four figures.** `21 gradeable`
is a measurement. `1 ungradeable` is a measurement. `0 windowless` is a real detector zero, proved in
five cases. **`0 undecided` is evidence about nothing.** What naming 0.223607 actually decided is that
slides 13 and 14 came out GRADEABLE rather than ungradeable -- name 0.001 instead and the undecided
count is still zero and both slides fail. **The load-bearing figure is 21 and the row rests on it
alone**, which the evidence line now says.

**THE REFINEMENT THIS FORCES ON 0020 IS THE PART THAT GENERALISES.** 1.23 required the sweep to print
which detectors have been observed to fire. **A tautological zero passes that check**, because the
detector HAS fired -- in other runs, under other configurations. **Reachability is a property of the
RUN, not of the detector**, and only the per-run form makes a zero readable. Filed.

**snorkeltoast's own reading of it is the one to keep:** *a number whose meaning depends on the
configuration that produced it, reported without it.* That is `pace=ambient` at breakfast --
captures scaled by a query parameter, budgets computed from the payload, six decimals of agreement
meaning nothing -- and `0 undecided` at close. **The same error at both ends of the day, once in the
instrument and once in the table describing the instrument**, and the distance between them is the
whole session.

---

### 1.25 hv's four further rulings, 2026-09-09, relayed via snorkeltoast

All four SHRINK the contract, and three of them retire work this thread had generated for itself.

| # | Ruling | Consequence |
| - | ------ | ----------- |
| H-E | **The brand-purity grep is DROPPED.** hv: *"Why are we testing for this? It's just yak-shaving."* | **AC-3.7's CHECK goes; the one-line fix may still land.** Dropping `\|\| "Snorkeltoast"` at template pull is parity-neutral and takes slide 1 from ungradeable to gradeable, so it is worth doing on its own evidence -- but **nothing gates on it and it is not a row**. vc's to amend |
| H-F | **The operational definition of "brand-free" is DROPPED** | The question that HOIST section 4's guard could not answer stops being asked. It was generated by this thread, not by anyone's requirement |
| H-G | **The publication currency check is DROPPED, and the model behind it was wrong.** hv's process is one `cp` of the delivered file to a fixed path in the Sites repo | Not a pipeline stage and not something needing an instrument. **snorkeltoast has already put build 008 at that path**, committed locally and unpushed under the CI freeze, so the staleness cc measured is closed at the source rather than instrumented around |
| H-H | **The reel's inputs stay in Dropbox.** Not going into git | The untracked-artifact finding is recorded and **is not something anyone intends to fix**, which is a different state from open |

**H-C DID NOT NEED RE-RULING AND THE RELAY IS THE INTERESTING PART.** snorkeltoast reported
`utilz prez showreel` as a new ruling against `HOIST.md` section 1's sibling, and asked cc to
change WP-03's structure if it assumed one. **It did not: H-C settled this at 1.8 this morning and
section 1 of this document rejected the sibling with reasons before any code was written.** Nothing
changed, nothing needed to. The gap was that snorkeltoast was reasoning from THEIR document, which
this thread had already superseded, and no mechanism told them -- **the same shape as the stale
line citation, one document up: a superseded source is indistinguishable from a live one to
whoever is holding it.**

**AND THE HONEST READING OF ALL FOUR: THREE OF THEM RETIRE WORK THIS THREAD PROPOSED TO ITSELF.**
snorkeltoast's own summary is the sharpest available and is kept in their words -- *building
controls for risks nobody had on a path nobody was walking, designing against a pipeline I had
inferred rather than the one that exists, and the tell was that every item added after the floor
table came from my own findings rather than from anything blocking.* The floor table was the
deliverable; everything after it was generated by the process that produced it.

---

### 1.26 A built-in theme cannot carry an asset, and the resolver is the only thing that knows where a theme lives

**`artifact::theme::Theme` carries a theme's TEXT and not its LOCATION, and every asset a theme declares is resolved relative to that location.** `theme.yaml` names `favicon:` and `fonts[].file` as paths relative to the theme directory, and the reference reads them as `tdir / spec["favicon"]` and `tdir / f["file"]` -- where `tdir` is `resolve_theme`'s FIRST return value. **Our resolver returns no `tdir` at all.** `Theme` is `{css, js, layout, name, origin}`; `name` is a diagnostic string that 1.x already ruled must never be parsed for meaning, being `"the built-in 'mono'"` on one branch and a bare path on the others. `Origin::SearchPath` does carry a `dir` and **it is the wrong one**: the directory that was SEARCHED, not the one the theme was found in.

**So `Theme` gains `dir: Option<PathBuf>`** -- the directory a theme's own assets resolve against -- set by the two constructors that already know it (`from_directory` has it; `from_file` takes the `.css` file's parent) and `None` for a built-in.

**THE `Option` IS THE RULING AND NOT A CONVENIENCE.** A built-in has no directory because it is `include_str!` output with no file behind it, **so a built-in can declare no font and no favicon** -- a real constraint on `default`, arrived at rather than chosen. It is also the right one: `themes/default/theme.css` sets `--font-display`, `--font-label` and `--font-body` to `system-ui` and declares no icon, so nothing is lost today, and the type is what stops a later built-in shipping a `theme.yaml` nothing can read. A bare `PathBuf` with an empty-string sentinel would let exactly that compile.

**THE COST TO prez IS WHAT AC-1.4 SAYS TO WATCH, AND IT IS MEASURED RATHER THAN ASSERTED: ZERO BYTES.** `target/release/prez` is 4,384,912 bytes before and 4,384,912 after, and `showreel` 452,720 before and after -- both binaries relinked and their mtimes checked against `date -u`, because a command that did not rebuild reports the old artefact's numbers. **The caveat belongs with the number rather than after it, per 1.23: an unchanged file size is not proof of an unchanged binary.** The two hashes DO differ; what this measures is that the addition does not cross a link-section boundary, not that nothing was emitted. prez constructs seven built-in `Theme`s and reads no theme asset, so the field is dead weight there and the compiler pays for it in padding it had already reserved.

**THIS IS THE SECOND showreel-DRIVEN ADDITION TO THE SHARED CRATE, AFTER `refuse_external_target`'s SIXTEEN BYTES, AND THE DIRECTION IS THE WHOLE POINT: `artifact` IS NOT A PLACE TO PUT THINGS.** Zero this time is a fact about this field, not a licence for the next one.

**The alternative was refused for a stated reason.** showreel could re-derive the directory by walking the search path itself -- and that duplicates `on_search_path`'s two-candidate lookup, whose two candidates have DIFFERENT theme directories (`d/name/theme.css` gives `d/name`, `d/name.css` gives `d`). A second copy of a resolution rule is `IN-AG-HIGHLANDER-001` inside the crate that exists to remove one.

---

### 1.27 The offline guarantee stops at the theme's TEXT, and a naive scan of the bytes would refuse the estate's only favicon

**R2 and R3 cover `theme.css`, `theme.js`, `layout.html` and `theme.yaml`'s reference-bearing fields. They do NOT cover the CONTENT of the files those fields point at**, and the build now inlines two kinds of that content: five WOFF2 faces and an SVG icon. **Recording the boundary because it is invisible from either end** -- the scanner reports a clean theme, the artifact is self-contained by every check this thread has built, and neither statement is about the 37 KB of SVG that just went in as base64.

**THE OBVIOUS FIX IS MEASURED AND IT LOSES.** Running `refuse_external` over an inlined asset refuses `themes/popupart/favicon.svg` **on its own first line**: an SVG carries `xmlns="http://www.w3.org/2000/svg"`, which is an XML NAMESPACE -- an identifier that is never fetched and cannot be dropped, because it is what makes the file an SVG. Measured over the estate's real assets:

| surface | absolute schemes | what they are |
| ---------------------------- | ---: | ------------------------------------------------ |
| `popupart/favicon.svg` | 1 | the SVG namespace declaration, and nothing else |
| the five `.woff2` faces | 0 | binary, no URL of any kind |

**Fetch-shaped constructs in that favicon: `<script>` 0, `<image>` 0, `<use>` 0, `@import` 0, `xlink:href="http"` 0, `href="http"` 0.** So the one real asset is clean, and a whole-file scan would refuse it anyway. **That is issue 0017's correction arriving at a third surface: read the SITE, not the spelling** -- and here the sites are an SVG grammar this port has no parser for and no reason to grow one.

**THE RESIDUAL, STATED PLAINLY RATHER THAN MINIMISED: an SVG favicon carrying a genuine remote reference would be inlined unexamined.** Whether a browser would then fetch it in a favicon context is not measured here and is deliberately not leaned on. **The population of such assets in this estate is ZERO, measured above, and that is the honest reason to defer** -- not an argument that the hole is harmless. **DEFERRED, NOT REFUSED**, and the trigger is the same shape as AC-3.13's: a theme in this estate shipping an SVG asset with a live reference, at which point the site scan is an SVG one and hv rules on the parser.

---

### 1.28 A parity fix and a deliberate divergence are not the same entry, and ONE COMMAND separates them

**COMMIT `79f9455` PUT BOTH IN ONE SENTENCE AND vc NEARLY FILED THE RESULT IN THE WRONG TABLE.** It
said `fit: cvoer` *"passed every check this port had"* -- true, and correctly scoped to the port --
and then called it *"the same defect as the mistyped `type:` this module was built for"*. **That
second clause is wrong in the way that costs something.** `type: crwal` is a REFERENCE defect: the
silent gallery fallthrough, which section 5 rules a deliberate fix for. `fit: cvoer` is a PORT
OMISSION: the reference already refuses it, at `showreel:828`, looping
`(("fit", FITS), ("transition", TRANSITIONS), ("motion", MOTIONS))` against the vocabularies at
`:76-78`. **One is the port diverging on purpose; the other is the port catching up.**

**vc's FIRST MOVE ON READING IT WAS TO ADD A FOURTH PREDICTED REFUSAL TO `PORT_EXPECTATIONS`**, and
that would have recorded a parity fix as a deliberate difference -- a fabricated divergence, in the
table whose entire job is to say which differences were intended.

**THE TEST IS ONE COMMAND -- DOES THE REFERENCE DO IT TOO -- AND NEITHER OF US RAN IT FIRST.** vc ran
it before filing and caught themselves. **I never ran it at all, and I had the answer on screen:**
`showreel:828`'s loop was in the first chunk of `collect_segment` I read, in the same session, before
I wrote the sentence. Having the evidence and mis-framing it anyway is the same shape as the
`proved applied` recurrence one section back.

Measured after the fact, both directions, with a control proving the comparison fires:

| vocabulary | reference | port | only in reference | only in port |
| ------------- | --------: | ---: | ----------------- | ------------ |
| `FITS` | 5 | 5 | none | none |
| `TRANSITIONS` | 5 | 5 | none | none |
| `MOTIONS` | 6 | 6 | none | none |

**SO THE RULE: SECTION 5 IS FOR DIFFERENCES, AND A CHANGE THAT CATCHES THE PORT UP BELONGS IN NO
TABLE AT ALL.** It cannot be decided by reading the port, because **the port looks identical in both
cases** -- a check that was missing and is now present. Only the reference distinguishes them, and
only if somebody looks.

---

## 2. There are THREE consolidations, and they are named apart on purpose

Two of them are both "inside showreel" and collapse into each other the moment they are written
as one. cc's structuring, kept verbatim in shape because it is right.

| # | Consolidation | Where |
| - | ------------- | ----- |
| C1 | **One admission function** -- typed refusal with a remedy, preserving absent-is-valid for QR | inside showreel |
| C2 | **One normalisation policy across both image passes**, retiring the alpha asymmetry | inside showreel |
| C3 | **One theme resolver + one base64** | between showreel and prez |

C3 is the one `HOIST.md` §6 argues for and the one the thread title implies. **C1 and C2 are the
two nobody had named, and C2 is the one the fidelity harness has to know about** -- see 4.2.

---

## 3. Admission: six sites, three policies, two undeclared input classes

snorkeltoast's trace, corrected upward by them from their own first pass.

| Policy | Sites | Where |
| ------ | ----- | ----- |
| Filter-and-skip (`RASTER_EXT`) | 1 | `from:` (`:930`) |
| Exist-or-die (`p.exists()` only) | 5 | `bug.file` (`:784`), `logo`'s `file:` (`:919`), `files:` (`:932`), `strapline`'s `mark:` (`:850`), `venue`'s `image:` (`:874`) |
| **Absent-is-valid, deliberate** | 2 | QR assets (`qr_path` `:694`, `load_qr` `:727`), documented in README §5 |

**The two accidental policies are not arbitrary -- they track two input classes, and nothing in
the tool says so.** `init` writes exactly four buckets: `titles`, `art`, `photos`, `cards`
(`:314`). It creates no `brand/`, no `location/`, no `qr/`. So `from:` reads **normalised
masters** and the five exist-or-die sites read **raw hand-placed files**. One code path, two
input classes, undeclared.

Three consequences the port must carry:

- **The PDF crash is a symptom, not the defect.** The same `.pdf` through three paths gives
  silently-absent, traceback, traceback.
- **The silent skip is the more serious half even though the crash is louder.**
  `IN-AG-NO-SILENT-001`. It is partly surfaced already: `report_unused` (`:574`, README §11)
  names unread files under `assets/`. **That is a report, not a refusal, and it fires at the
  wrong altitude** -- it says an asset was unread, never that a segment silently dropped it. The
  port extends that surface rather than re-inventing it.
- **Absent-is-valid must survive the consolidation, as a TYPE.** It is the only silent absence in
  the tool that is a decision rather than a defect, and it sits directly beside ones that are
  defects. In Rust it is `Option<Qr>`, so flattening it is a compile error rather than a
  judgement someone tidies away. Where knowing a rule demonstrably does not prevent the error,
  the guard belongs in the code.

### 3.1 The shape C1 takes, decided before the code

**ONE CLASSIFIER, TWO CALL SHAPES, AND THE DIFFERENCE BETWEEN THEM IS WHO ASSERTED THE PATH.**
That is the whole of it, and it is why "one function" does not mean one policy:

- **A path the config NAMED** -- `bug.file`, `logo`'s `file:`, `strapline`'s `mark:`, `venue`'s
  `image:`, each entry of `files:` -- is an ASSERTION by the author. Missing refuses. A type the
  tool cannot embed refuses. **Five sites, one policy, no skipping**, because there is nothing to
  skip past: the author wrote that filename down.
- **A directory the config SCANNED** -- `from:` -- is a QUERY. It may legitimately hold a
  `README`, a `.DS_Store`, a stray export. **Refusing the segment because a directory contains a
  text file would make the feature unusable**, so non-images are dropped -- and **the drop is
  REPORTED at the segment's altitude**, which is the half the reference does not have.

**THE REPORT IS THE WHOLE OF C1'S VALUE AND IT IS NOT A REFUSAL.** `report_unused` already names
files under `assets/` that no segment read, and AC-3.2 says to extend it rather than duplicate
it -- but it fires at the WRONG ALTITUDE: it says an asset went unread, never that segment `x`
asked for a directory and silently dropped three things out of it. **Those are different
sentences and only one of them tells the author where to look.**

**THE ADMISSIBLE SET IS `RASTER_EXT`, AND IT IS THE SAME SET THE MANIFEST ALREADY BUYS.** `image`
is compiled with exactly `jpeg, png, webp, gif, tiff` (AC-3.9), and `RASTER_EXT`'s seven
spellings are those five formats plus the second spelling of two of them -- `.jpg`/`.jpeg` and
`.tif`/`.tiff`. **Stated so the two cannot drift silently**: a decoder feature added without its
spellings admits nothing, and a spelling added without its feature refuses at decode instead of
at admission, which is the wrong altitude again.

**`.pdf` REFUSES BY NAME AT A NAMED SITE AND IS REPORTED AT A SCANNED ONE.** The reference gives
three different answers to one file -- silently absent through `from:`, traceback through the
other two -- and section 3 already calls the crash the symptom. **`rasterise_pdf` is NOT in this
work package**: the 45h reel contains no PDF, the budget carries no rasteriser, and adding one
needs hv's sign-off by AC-3.9. So the port says so, by name, instead of crashing or vanishing.

**`.svg` IS NOT A SLIDE IMAGE, AND THAT IS MEASURED RATHER THAN ASSUMED.** All five SVGs in the
live reel are QR codes under `assets/qr/`, reached by `load_qr` as TEXT and never by an image
site. So SVG's absence from `RASTER_EXT` is correct and is not an oversight to helpfully fix --
an SVG arriving at an image site is a mistake worth naming.

**AND THE LIVE REEL CANNOT PROVE THIS ONE, WHICH IS WHY THE TESTS MUST.** Measured against
45h's config: `from:` 1, `file:` 1, `mark:` 2, `image:` 1, `bug:` 1, `qr:` 3 -- and **`files:` 0,
`exclude:` 0.** Two of the six sites are exercised by no real configuration in this estate, so
the test population is the only thing standing behind them, exactly as `segment.rs` already
records for the shape table.

---

---

## 4. The fidelity contract

`HOIST.md` §6 proposes "RMSE 0 on every static slide of the 45h reel, Python as reference".
Traced against the source, that names neither one measurement nor a reachable floor, and after
the ruling in 4.2 it names the wrong instrument as well.

### 4.1 Three populations, and the convenient one is the trap

showreel resizes and re-encodes in two commands, and `build`'s input is `init`'s output:
`normalise_image` (`:271`, **init only**) writes 2560px masters; `data_uri` (`:417`, **build**)
re-encodes them to the 1920 delivery size. Both LANCZOS, both `exif_transpose`, both q86.

| # | Population | What it answers |
| - | ---------- | --------------- |
| 1 | Python init + Python build | the CONTROL. A non-zero here means the harness is broken, not the port |
| 2 | Python init + Rust build | useful **during** the port, a MIXED pipeline, and **the one that happens by accident** -- the masters are on disk and nobody re-runs `init` |
| 3 | Rust init + Rust build | the one that **ships** |

**A run of (2) reported as (3) is a green over half the pipeline that reads as a green over all
of it, and it fails in the quiet direction.** So the harness **derives its population label from
what actually ran, not from a flag someone passed, and refuses a verdict without one.** A number
without a population is not a result.

### 4.2 RULING: port the consistent policy, not the Python's asymmetry

This was put to vc as an AC-shaping decision. **Ruled: one normalisation policy across both
passes.**

The asymmetry: `normalise_image` carries an alpha-collapse heuristic (`:283-285`) demoting a
fully-opaque RGBA to RGB/JPEG; `data_uri` has no equivalent, and its PNG branch
(`if im.mode in ("RGBA","LA")`, `:426`) **is the default path for hand-placed brand marks**. So a
fully-opaque RGBA PNG ships full-size where `init` would have made it a JPEG -- **the mascot and
the wordmark, on every build.**

Why consistent wins:

- **"Match Python exactly" now has a name: it means porting a known defect, on the path that
  carries the brand marks, on every build.** That is not a fidelity requirement, it is a
  fidelity requirement's costume.
- A reference implementation is a reference, not a specification. `HOIST.md` is careful about
  encoder bytes being *"not worse, different"*; this is different **in kind**, and the two must
  not be graded by one instrument.
- A port that reproduces a bug in order to satisfy an instrument has inverted what the instrument
  is for.

**The ruling costs the blanket RMSE, and that cost is paid explicitly rather than absorbed.**

### 4.3 What the harness therefore has to be

**RMSE with a named exemption list**: the slides whose assets take the un-normalised path are
exempted **by name**, with the expected difference stated as a **direction** (PNG to JPEG at q86
-- a known non-zero, not an unknown one). A blanket floor over a pipeline you deliberately
changed goes red for the right reason and then gets argued down, which is how an instrument dies.

**An exemption list is a population narrowing, so it needs its own controls.** cc's addition, and
it is required rather than nice -- too narrow fails **greenly** and ships:

- print the exemption count AND the covered count, and **refuse if they do not sum to the slide
  total** (the sum control);
- **refuse if a slide is exempted that is not in the named list** (the membership control).

Without both, the list silently grows to cover real regressions and every run stays green.

Three further properties, none optional:

- **Structure before pixels, and separately.** Slide count, order and ids are asserted exactly
  first; **a structural mismatch fails without reporting a pixel number at all.** Comparing
  slide 7 to slide 7 means nothing if one pipeline emitted 19 where the other emitted 20, and
  reporting a pixel number invites reading a structural defect as a tolerance question.
- **The same-file control run is mandatory** regardless of everything above. Without it every Ken
  Burns slide is a false positive; with it, the audit caught a real one-shade colour regression.
  It is also what establishes the noise floor the grading floor is derived from.
- **The floor is derived and stated with its reason, and may differ per population.** Against (2)
  the masters are byte-identical inputs, so a tight floor is meaningful. Against (3) the second
  pass consumes a Rust re-encode, so error compounds across two LANCZOS passes and two JPEG
  encodes; a floor carried over from (2) would be red for reasons that are not a defect. **A
  floor of 0 is red on a correct port**, which is the fastest way to train everyone to ignore an
  instrument.

### 4.4 The instrument is red-proved before it grades anything

An injected known change must show red, and the same-file control must report the floor, **before
the harness grades a single Rust build**. This is why the harness is WP-02 and the Rust is WP-03:
an instrument built after the thing it measures gets tuned, unconsciously, to agree with what
already exists.

---

## 5. Fixed in passage, or inherited -- decided now, not during

A behaviour difference found during fidelity testing and not written down in advance gets read as
a port bug.

| Prototype behaviour | Disposition |
| ------------------- | ----------- |
| `showreel.yaml` unknown keys silently ignored (`dwel: 8s` uses the default and says nothing) | **FIXED.** Refused by name, with the valid set |
| Six admission sites, three policies, two undeclared input classes (section 3) | **FIXED via C1.** One admission function, typed refusal with a remedy |
| The `from:` silent skip | **FIXED.** A dropped segment input is reported at the segment's altitude, extending `report_unused` rather than duplicating it |
| QR absent-is-valid | **PRESERVED, as `Option<Qr>`** -- a type, not a policy |
| The alpha asymmetry between the two image passes | **FIXED via C2** -- ruled in 4.2 |
| Theme contract is a comment, not a check -- a brand token entered the brand-free shell and survived until an audit | **FIXED.** A shell-purity check over `player.html` |
| Safety floors (600ms transition, 2.5s slide, 3s ceiling) enforced in compiler AND shipped to the runtime | **PRESERVED.** `?speed=` reaches the runtime, so both ends enforce. A limit written twice in two languages is one liability -- which is why it ships in the payload rather than being reimplemented |
| `plan()` derives the slide list and the asset list from ONE walk, so the recycler can never disagree with the build | **PRESERVED, and asserted.** It is a single-population property, and it is exactly the class this estate keeps losing |
| `socials layout: list` has no consumer | **INHERITED.** A legitimate option, recorded as untested by use |
| No tests (~2,000 lines verified by rendering and looking) | **FIXED** -- WP-02 and the ATs |
| `load_theme` runs its OWN external-reference regex, separate from prez's | **FIXED via C3.** It is the weaker of the two implementations -- the class issues 0014, 0015, 0017 and 0018 were all found in -- so the port calls `artifact::theme::refuse_external` and ports no regex. A second scanner is the Highlander violation this thread exists to remove |
| `favicon_link` WARNS and returns `""` when the file `theme.yaml` names is missing | **FIXED. Refused by name, with the path.** A `theme.yaml` saying `favicon: x.svg` is ASSERTING x.svg exists; continuing ships an artifact materially different from the one declared, and "Refusals, not fallbacks" is already this estate's stated position. The cost is one error message rather than any machinery. **This is a deliberate behaviour change and AC-2.16 covers it: a theme missing its declared favicon builds under Python and refuses under Rust.** It does not bite the 45h reel -- `themes/popupart/` ships `favicon.svg` |
| `font_face` converted TTF to WOFF2 on every build, wrapping it in `except Exception:` and embedding the RAW TTF on failure -- different format, roughly double the bytes, still reporting "wrote" | **GONE AT THE SOURCE, and the port carries no converter.** snorkeltoast pre-converted the five faces and committed them beside the theme (`95317bc`, Snokeltoast tree); `fonts:` entries name the `.woff2`. **The port reads the named file, base64s it, emits the `@font-face`, and REFUSES a `.ttf` by name with the conversion command in the remedy.** The defect worth naming is not the bare `except`: it is emitting a different format and reporting success. **A dependency this removes: the approved budget carries no woff2 or brotli crate, so a converter would have needed a fresh hv sign-off mid-package** |
| `font_face` WARNS and returns `""` when the file a `fonts:` entry names is missing | **FIXED. Refused by name, with the path.** The favicon row's sibling, and it fails WORSE: a browser silently substitutes a system face, so the artifact still looks finished and the missing font is invisible to everyone including the person who built it. A `fonts:` entry is ASSERTING that file exists; continuing ships type the theme did not choose. **AC-2.16 predicts the favicon half; this is the same prediction one field along, recorded here so that neither is read as a port bug when it fires.** It does not bite the 45h reel -- `themes/popupart/fonts/` ships all five `.woff2` |
| `favicon_link` WARNS and returns `""` when the declared icon's extension is not `.svg`, `.png` or `.ico` | **FIXED. Refused by name, with the supported set.** **THIS IS THE FOURTH MEMBER OF ONE FAMILY AND THE LAST TO BE RULED, SO THE FAMILY IS NAMED HERE RATHER THAN LEFT TO BE INFERRED: a theme DECLARES an asset and the reference ships an artifact without it, saying so only on stderr.** Four sites -- a missing favicon, a missing font, a font that is not WOFF2, and this one -- of which the reference refuses at exactly one. **The asymmetry is what gives the family away**: `font_face` already dies by name on a wrong FORMAT, so the same tool treats the same defect two ways one function apart. All four refuse in the port, and the remedy names the supported set the way the font's names the conversion command |
| `load_qr` WARNS and returns `""` when the file a segment's `qr:` names is missing | **FIXED. Refused by name, with `showreel qr <dir>` as the remedy.** **THE FIFTH MEMBER, AND IT IS C1'S RULE AT A FIFTH SITE RATHER THAN A NEW POLICY.** The reference is ALREADY almost consistent here and its two behaviours are the tell: a QR looked up by CONVENTION (`assets/qr/<label>.svg`, from a socials entry) is silently absent and README section 5 documents that as valid -- *"no asset is a valid configuration, not a missing one, so it passes without comment"* -- while a QR NAMED in the config warns. **Named is an assertion, convention is a query**, which is exactly the split C1 draws for the six admission sites. The port makes the named case refuse and leaves the convention case silent. **AC-3.3 IS THE OTHER HALF AND THE TWO MUST NOT BE COLLAPSED: `qr:` ABSENT stays valid and is carried as `Option`, so flattening it is a compile error.** Absent-is-valid and declared-but-missing are different facts; the reference's single `""` return is what made them look like one. Measured against 45h: two `qr:` keys declared, both files PRESENT, with a control on a path that is not -- so this does not bite the live reel either |

---

## 6. Work packages

| WP | Scope | Depends on |
| -- | ----- | ---------- |
| 01 | Workspace + `artifact/` (C3). Extract the generic theme half, base64, `Failure`; assess `inline.rs`; **diff prez's five theme behaviours against showreel's five and report identical-or-near**. Zero behaviour change to prez | -- |
| 02 | The fidelity harness, built and red-proved against **population (1) only** | -- |
| 03 | Rust `build`: YAML, config validation with refusals, C1's admission function, C2's normalisation policy, template, data-URI, delivery re-encode. Graded against (2) | 01, 02 |
| 04 | Rust `init` and `qr`. Graded against (3) | 03 |
| 05 | Command surface: shim dispatch, `showreel.yaml` manifest, help, doctor lines, and the `help/prez.md` amendment | 03 |
| 06 | Snorkeltoast side: point the prototype at the hoisted tool, move the house theme to `design/`, keep the 45h config as the worked example | 05 |

**WP-01 is separable from showreel entirely, and that is deliberate.** If showreel slipped a
month, WP-01 would still be worth having and still green on its own acceptance.

**WP-02 before WP-03 is the non-obvious one.** See 4.4.

**WP-06 writes into another project's tree.** Announce first. Learned here 2026-07-29, when
another project's session edited this tree mid-session while it was being measured.

**Delivery, agreed between cc and snorkeltoast and recorded:** snorkeltoast copies nothing and
stages nothing; cc pulls once this contract names what lands where. One writer on this tree, and
the copy attributable to a commit carrying ST0017.

---

## 7. Out of scope

- **Video segments.** A 70 MB clip cannot be a data URI, so it breaks the single-file guarantee.
  If ever wanted, an explicit opt-in stating plainly that the output is now a directory.
- **A markdown front end.** The config is a data structure; flattening it into front matter makes
  it worse.
- **`themes/popupart/` does not move.** It carries one organisation's palette, fonts and favicon
  and arrives over `SHOWREEL_THEME_PATH`. No built-in is ever a brand.

Deferred, not refused: `HOIST.md` §4's conveniences. `--watch` and `showreel present` are real
wins and prez-symmetric, but they are not the hoist and prove none of it. **hv's call** whether
they join ST0017 or take their own thread.

---

## 8. The contract, drafted

**MINTED 2026-09-09 as `AC-<wp>.<seq>` -- 33 rows, see 1.12.** The numbered draft below is kept as
the reasoning behind each row; the live contract is `intent ac list ST0017`.

### Group SHARE -- the consolidation between tools (C3)

| # | Criterion |
| - | --------- |
| S1 | Theme resolution and base64 have exactly ONE implementation in the tree, linked by both binaries. **Data-URI inlining is NOT in this set** -- the S5 diff established it has no shared surface |
| S2 | WP-01 adds no third-party cost to prez: the `comrak` line byte-identical, the lockfile's third-party package count unchanged, and the only permitted addition the first-party std-only `artifact` path dependency. **Corrected from byte-identity of the block, which S1 makes impossible -- see 1.4.** Conditional on hv's AC02 sign-off |
| S3 | No existing prez assertion is weakened or altered: all 135 original test bodies unchanged, verifiable by diff, with the count stated before and after. **Additions are permitted and expected** -- S8 is one. Corrected from "no edit to any test file", which S8 makes false while the intent holds -- see 1.7 |
| S4 | prez's release binary size after WP-01 is stated as a number against the budget, not as a distance |
| S9 | Both `cargo test` call sites (`common.sh:838`, `tests.yml:284`) pass `--workspace` and `--no-fail-fast`. **Measured: without `--workspace` the estate builds 1 executable where the workspace has 2, so artifact's 12 tests never run** |
| S10 | `[profile.dev] debug = "line-tables-only"` at the workspace root |
| S11 | **Standing, and it binds the crate that trips it, not this WP:** the first crate in this workspace to gain a `tests/` directory adopts `autotests = false` + one declared `[[test]]` + the orphan guard, **in the same commit that adds the first file**. Per TN001, whose own lesson is a ruling tracked separately from its application |
| S8 | prez pins which theme `load(None, ..)` resolves to, by a property unique to `simple` rather than one the whole roster shares (**`--gp-bg` is carried by all seven and does not discriminate**). **Two halves: the identity assertion is live now; the roster-reorder injection cannot fire until wiring and MUST be re-run then** -- see 1.6 |
| S7 | `crate/` is both the workspace root and prez's package: every `include_str!` path, the shim and `prez.bats`'s fixture unchanged, and **`[profile.release]` proven in effect for the measured binary** rather than assumed from the manifest |
| S5 | **SATISFIED 2026-09-09.** prez's and showreel's theme behaviours diffed by two independent enumerations: four behaviours, one clean match, result in 1.1 |
| S6 | The shared resolver implements R1-R4: newline-preserving comment stripping, the ruled needle set, `theme.yaml` scanned, and prez's four provenance messages. **Closes issue 0014** |

### Group FID -- the instrument

| # | Criterion |
| - | --------- |
| F1 | The harness derives its population from what ran and refuses a verdict without one |
| F2 | Slide count, order and ids are asserted exactly before any pixel comparison; a structural mismatch reports no pixel number |
| F3 | A same-file control run reports the noise floor; the grading floor is derived from it and stated with its reason |
| F4 | An injected known change shows red before the harness grades any Rust build |
| F5 | The exemption list is named, its expected difference stated as a direction, and the harness refuses when exemptions + covered do not sum to the slide total, or when a slide outside the named list is exempted |

### Group PORT -- behaviour

| # | Criterion |
| - | --------- |
| P1 | An unknown key in `showreel.yaml` is refused, named, with the valid set |
| P2 | All six admission sites route through one function: a bad input refuses with a remedy, and a dropped segment input is reported at the segment's altitude |
| P3 | QR absence remains valid and is carried as `Option`, not as a policy |
| P4 | One normalisation policy governs both image passes; no opaque RGBA ships un-collapsed |
| P5 | A theme referencing `http://`, `https://` or a protocol-relative URL is a build error, in CSS and in `theme.yaml`. **As drafted this described behaviour prez does not have** -- cc's catch; S6 is what makes it true for both |
| P6 | The safety floors hold in compiler and runtime, and `?speed=` cannot cross them |
| P7 | `player.html` carries no brand token |
| P8 | The slide list and the asset list come from one walk |

### Group HOIST -- the move

| # | Criterion |
| - | --------- |
| H1 | `prez showreel build <dir>` builds the 45h reel from its real config, from BOTH invocation forms (`utilz prez ...` and a direct `prez ...`) |
| H2 | `help/prez.md`'s "there is no player, and there never will be" is amended in the same commit that adds the subcommand |
| H3 | No Utilz-tree file contains the `popupart` theme; a build resolving it warns that it came from off the built-ins |
| H4 | `utilz doctor` reports showreel's external dependencies as optional lines, present because the tool is present |

---

## 9. Not ruled by vc

**RULED 2026-09-09, see 1.8: the AC02 edge (H-A), showreel's dependency budget (H-B), the command
spelling (H-C), and the install republish (H-D). What remains open:**

1. **The showreel dependency LIST**, at WP-03. H-B approved the budget's SHAPE, not a list --
   cc confirms current crate state and versions, hv approves the named set once.
2. **The grading floor's number.** vc specifies the shape; the number comes from the control run
   and accepting it is hv's.
3. **Whether `--watch` and `present` are in ST0017** or take their own thread.
4. **The AC/AT id format** -- see 10. Blocked on hv or `intent-vc` naming the form; the 22 rows
   stay drafted until then.

Two `HOIST.md` §6 decisions vc endorses, needing no ruling because both are improvements
independent of language:

- **Pre-convert theme fonts to `.woff2`.** The prototype converts TTF to WOFF2 at every build,
  which is the only reason `fontTools` and `brotli` are dependencies at all. Two dependencies
  gone, faster builds, and the theme ships the format it wants served.
- **PDF rasterisation stays an external CLI.** Every Rust PDF renderer is bindings to PDFium or
  MuPDF, which breaks the self-contained claim motivating the port, and MuPDF drags AGPL in.
  `pdftoppm` runs only in `init`, never in `build`, so the hot path is already pure.

---

## 10. The id-format blocker, measured

`intent ac` has no rename verb, so an id minted wrong is stuck. Measured on ST0017 today, the
tooling cannot say what conforming means:

- `intent ac new` **accepted all three** of `AC-HOIST-01`, `HOIST-AC-01` and `AC01`. The mint
  refuses nothing.
- The renderer then made **every one of them its own group** -- "Group AC-HOIST-01", "Group
  AC01", "Group HOIST-AC-01". `group_of` extracted no group from any form tried.

Unenforced in both directions, and not inferable from behaviour. **So the rows in section 8 are
drafted and minted only once hv or `intent-vc` names the form.**

One thing that partially defuses the blocker, also measured today: **removing rows from
`intent/.canon/st/<ID>.json` and running `intent sync --to-store` retracts them cleanly** -- no
tombstone, no `withdraw`, `intent doctor` 0 findings afterwards. That is a working retraction
path for an un-ratified row. It is **not** established as safe for a row carrying satisfaction
state or a covering AT: the sync warns that it OVERWRITES, and that case was not tested.

---

## 11. Sources

| Document | What it is |
| -------- | ---------- |
| `.../Snokeltoast/bin/showreel/README.md` | the protocol and the reasoning, 433 lines |
| `.../Snokeltoast/bin/showreel/HOIST.md` | the move and the Rust case, 251 lines |
| `.../Snokeltoast/bin/showreel/showreel` | the reference implementation, 1,046 lines |
| `.../Snokeltoast/bin/showreel/player.html` | the shell, 44 KB, data the tool inlines. **Unchanged by the port EXCEPT the brand literal** -- see 1.17: our copy loses `|| "Snorkeltoast"` when WP-03 pulls the template, so the two copies sit one line apart until WP-06 retires theirs |
| `.../Snokeltoast/bin/showreel/themes/default/theme.css` | the brand-free built-in, 951 bytes. **The only theme that moves.** `themes/popupart/` does not -- see 7 -- so this one file is the whole of WP-03's built-ins pull, and H3 is what holds it to that |
| `opt/prez/crate/Cargo.toml` | AC02, hv's dependency ruling, and the size reasoning |
| `intent/whiteboard/vc/inbox.cc.md` (2026-09-09 08:09Z, `a225af2`) | the consolidated pre-contract brief |
