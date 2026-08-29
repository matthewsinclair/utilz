---
node: vc
name: Validation Claude
role: validation
session_id: 3d40d776-e1d0-40da-b5c5-7926017d5ce1
heartbeat_at: 2026-08-29 13:34Z
status: active
focus: "ST0010 coordination pen. WP-01/02 Done, WP-03 hoisted at the OLD pin and awaiting re-archive. Pin patch written but UNCOMMITTED in _tools with both its nodes paused. Three new findings this pickup, one of which breaks the cutover."
claims: [ST0010]
---

# Validation Claude (vc)

Validation node. For ST0010, hv additionally gave vc the coordination pen ("utilz-vc has the plan"). Coordination is not ownership of code: cc builds, vc contracts and verifies, hv adjudicates. Session history in `.history/20260829/`.

Status stays `active` through the compact deliberately -- `/compact` does not end a session (whiteboard invariant 6), and hv has said work continues on the bounce. A `release` here would put a false `paused` on the board.

## THE BLOCKING FACT, restated after pickup

**The new `_tools` pin is written but NOT COMMITTED, and both `_tools` nodes are paused.** `_tools` HEAD is `42320af` (vc's localfold); `native/rust/geopres/test/acceptance.sh` sits modified in their working tree. Read the diff 2026-08-29 13:32Z: all four items are present and correct -- `--use-mock-keychain` at all four launch sites, disposable `--user-data-dir` at `:407`/`:519`, AT12 down to one profile for the whole eight-launch sweep, and `chrome()` extended to 4 app paths + 6 PATH names.

So the work is done and the freeze cannot advance, because committing it is a live `_tools` session's job and there is no live `_tools` session. **This is hv's to unstick, not mine** -- nothing in Utilz can commit into that repo, and the standing rule forbids editing it from here.

**On receipt of the sha: relay to utilz-cc immediately.** cc has already archived once from `3e16597` and has scripted the adaptations (`hoist-adapt.sh`, attached to ST0010, verified idempotent and byte-reproducing), so the re-archive is now cheap and deterministic rather than a redo.

## Findings from this pickup -- all three are new

**1. THE CUTOVER IS BROKEN AND NOBODY'S TESTS CAN SEE IT.** The rename sweep changed the search-path variable to `PREZ_THEME_PATH` (`opt/prez/crate/src/theme.rs:80`). The estate's shim still sets `GEOPRES_THEME_PATH` (`bin/geodica_present:125`), and `_tools-cc`'s recorded shim-rewrite parameters do not mention the rename. Land that rewrite as specified and `geodica present deck.md` sets a variable prez does not read, the search path is empty, and `--theme=geodica` **REFUSES** -- correctly, loudly, naming an empty path, and looking exactly like the port broke the brand theme. Eight more references trail it: `bin/geodica_design:114,178`, `bin/help/geodica_present.md:20,34`, `themes/geopres/geodica/theme.css:10`. This is a seam defect: `_tools`' suite never runs prez, our suite never runs the shim, so it is invisible on both sides until a human types the command. Must reach `_tools-cc` before their cutover commit.

**2. THE AT MAP DOES NOT MATCH THE INSTRUMENT IT NAMES.** ST0010's canon assigns AT01->AC01, AT02->AC02+AC03, AT03->AC04. The file says otherwise, verified by reading the blocks: `acceptance.sh` AT01 is the rewritten build-hygiene test (our AC11), AT02 is dependency posture (our AC01), AT03 is self-contained-artifact + the notes sentinel (our AC02+AC03). The head of the range is shifted by one because ST0010 dropped `_tools`' Dropbox AC01 and renumbered while the ATs kept their own sequence. The tail may or may not shift with it -- **the whole map needs re-deriving line by line from the file, not patching by inference.** Fourth, separate: the suite's own assertion strings still cite `_tools` AC ids (`absent "AC04 sentinel is nowhere in the HTML"` at `:218` is our AC03), so a green it prints names an AC that means something different in this repo. **This is a WP-04 PREREQUISITE, not part of it.** Greening through a wrong map manufactures exactly what `_tools` is stuck at 11/13 for right now: a green that does not name its instrument.

**3. `chrome()` WAS FIXED AS A MIRROR, AND `_tools-vc` HANDED US THE DURABLE FIX IN WRITING.** Their patch comment: "A MIRROR IS NOT THE RIGHT ANSWER AND THIS COMMENT IS NOT AN EXCUSE FOR IT... The durable fix is for the tool to expose its resolution (a `--print-browser`, or the refusal naming the list unconditionally) so this function can ask instead of copy. Raised for Utilz; the mirror is the stopgap." So AC18(a) is no longer "port their one-list fix" -- the pin carries two lists that agree today, and Utilz inherits the drift unless prez is made to answer. `builtins_list()` in the same file is the precedent: it asks the binary. Same shape as `_tools-cc`'s open ask about the determinism probe (below) -- **two consumers, two days apart, both blocked by prez keeping something private, both reaching for a copy.** One design answer, not two.

## DOING

- Holding the pen. WP-03 is cc's and continuing on its pin-independent half.
- Answering `_tools-cc`'s open ask: they want to know whether prez exposes its determinism probe to consumers or whether the estate needs its own, so the Geodica theme (which arrives over the search path and takes a DIFFERENT branch of `theme.rs` than any built-in) gets a determinism check. It is WP-07 here and currently deferred. Finding 3 is the argument for un-deferring: the same "expose it" answer serves both.

## TODO

- **Fix the AT map (finding 2) before anything is greened.** Re-derive AT->AC from `opt/prez/crate/test/acceptance.sh` block by block, correct the canon, and re-stamp the suite's own assertion strings onto this repo's AC ids. Contract work, mine, and it does not wait on the pin.
- **WP-04, on cc's hoist-green signal.** Re-produce every carried green with instruments run HERE: `cargo test` (111 at the pin), `acceptance.sh --strict` (10/0/0 there), AT12, the post-`ec3564a` legibility probe, the liftability refusal, the standalone greps. Walk ATs through red where the lifecycle requires. Satisfy AC16 (prepare the renders; hv supplies the eye) and AC17 (provenance) by named evidence. State what was NOT checked. `_tools-vc` has offered its eyes on whether my instruments measure what they name -- take that up.
- Announce prez-green to `_tools-cc`: their trigger to land the `geodica present` client rewrite + `geodica doctor` check in one commit. **Send finding 1 with it, or ahead of it.**
- WP-06 spec is written (design section 10); WP-05 last; WP-07 pending the finding-3 ruling.

## Open with hv

- **The pin is stalled on a paused repo.** Only hv can resume a `_tools` session to commit the patch. Everything else in ST0010 has unblocked work in front of it, so this is not idling the thread -- but WP-03 cannot close and WP-04 cannot start.
- **`geodica doctor` must report whether `utilz prez` is available** -- hv's estate requirement, still with no AC anywhere. `_tools-vc` put it to hv rather than minting it. It is an estate AC, not ours, but it is on nobody's contract today.
- **Did a Keychain dialog pop at ~14:18 local?** I ran one bounded `--use-mock-keychain` verification. Flag accepted, Chrome renders, no keychain error -- but absence of a dialog on hv's screen is not observable from a shell, and AT15's note records that limit rather than papering it.
- 18 unpushed commits. Pushing is hv's.
- **RETIRED: CI red on `main`.** Fixed at `95b650a` -- the blocking shellcheck gate no longer lints vendored devbin. No longer open.

## Watch-outs

- **The working tree has three writers and is dirty in two places that are not mine.** `bin/devbin` + `bin/.devbin/manifest.sha256` are hv's devbin running (`_tools-vc` records the identical class over there). `opt/prez/crate/examples/*.md` and `cc/.history/20260829/wip.md` are staged -- cc's documented prettier index residue from `git commit --only`. **Do not stage, do not commit, do not tidy.** Explicit pathspecs on every commit.
- **One known harness cause will still redden the FIRST Linux CI run, and one is now fixed at source.** Fixed in the pending pin: the browser-probe drift (finding 3's mirror). Still live: `AT01` sizing the binary with BSD-only `stat -f %z`, which returns nothing on Ubuntu, reads 0, and fails the 8 MB ceiling -- cc added a `stat -c %s` fallback in the hoisted copy, so confirm it survives the re-archive, because the fix lives HERE and the archive comes from THERE.
- **The rename sweep has three coordinated sets and must stay atomic**: theme const + refusal string + the AT asserting it; the `SENTINEL=` literal and its twin payload in `examples/demo.md`; the binary name throughout. cc measured 107 lines across 19 files.
- **The liftability refusal is the guarantee.** An unknown theme must REFUSE naming built-ins + search path. If `--theme=geodica` ever resolves on bare prez, the crate has stopped being liftable and nothing else reports it. Confirmed intact: the hoisted crate ships seven themes and no geodica.
- **`include_str!` pins the layout**: `src/`, `themes/`, `assets/` are compile-time siblings. The crate travels as one unit or it does not compile.
- **`examples/demo.md` does not opt into mermaid** (its `mermaid: true` is documentation inside a fence). Diagram and determinism checks must point at `examples/test_pres.md`; demo.md is the labelled negative control. Bit `_tools` three times.
- **`acceptance.sh` defaults to exit 0 with named SKIPs.** Always `--strict`, and in CI prove a browser was found.
- **Contrast figures go stale by selector** -- four corrections in two days. Current honest floor-nearest is mono 4.9:1 (flattened, every text element, `bfd0349`). Any quoted figure cites selector + palette + commit.
- **A green is a licence to look, not a substitute for looking** (AC16). `_tools-cc`'s diagram-font defect passed a green determinism probe.
- **Build provenance is a real seam** (AC17). At the pin a binary predated its own source commit by 3.5 minutes. If our numbers disagree with `_tools`' (10/0/0, 111), check provenance before suspecting the port.
- `utilz test` is not safe to run concurrently (the helper mutates `$UTILZ_HOME/bin`). Verify shell tooling under `/bin/bash` with an array, never zsh with an unquoted variable.
- Framework `VERSION` 2.4.0 and `intent` 3.0.0 are different numbers. ST0010 releases as **2.5.0**; tag and push are hv's.

## Decisions

- (2026-08-29) ST0010 claimed by vc as coordinator; cc executes the build WPs. Explicit exception to vc's no-claims default, at hv's direction.
- (2026-08-29) `_tools` AC01 NOT transcribed: Utilz is outside Dropbox and its `local` remote is bare, so it would gate a hazard that does not exist here. The hygiene lessons transfer as this thread's own criteria; the Dropbox justification does not. **This renumbering is the root of finding 2** -- dropping an AC while the ATs kept their own sequence is what broke the map, and nothing reported it because both numbers still existed.
- (2026-08-29) AC08's addressing clause is excised to AC15 rather than transcribed then edited -- validating a resolution order we are about to break yields a green that means nothing, and one AC is never edited twice.
- (2026-08-29) Two non-test ACs, satisfied by named evidence rather than a passing test: AC16 (a human looks at the render) and AC17 (the binary was built from a clean checkout of the pin). Both exist because the suite provably could not stand in for them.
- (2026-08-29) **The freeze protects utilz-cc from drift; it does not make the pin sacred.** Two findings, opposite rulings, and the difference is in the facts: the keychain modal is actively harming and testable where it lives, so it is patched in `_tools` and the pin moves; the Linux browser-probe drift is invisible and untestable there, so it is fixed in Utilz. `_tools` then went further than the ruling and put a mirror in the pin -- which fixes the false red at source and leaves the Highlander violation for us, exactly as their comment says.
- (2026-08-29) Two checks measuring the same PROPERTY by different mechanisms are duplication; two measuring DIFFERENT properties are not (`_tools-cc`'s refinement). So the estate's static grep on its generated CSS and prez's runtime determinism verb both stand, and neither is a second home.
- (2026-08-29) **A cross-repo rename has no owning suite.** Neither side's tests can see finding 1, because each repo's suite stops at its own boundary. Where two repos share a contract, the contract needs a check that runs one against the other -- or a named human step. Currently it has neither.
