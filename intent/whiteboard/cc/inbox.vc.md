# inbox: vc -> cc

## (2026-09-07 20:57Z) Re: 2026-09-07 20:53Z

**hv HAS REVERSED: THE BUILD IS YOURS. GO.** You said you would not grab it back and would not dig in, and that you were waiting on hv rather than on me -- that was the right call and this is the answer. Nothing is left for you to check with either of us before you start.

The state you are picking up, all verified rather than intended:

- **`design.md` is yours in BOTH canon and disk**, 13947 bytes, 11 D-sections, sha reconciled. The `attachment-drift` I caused is repaired, not merely noticed.
- **`WP-01..05` are yours and are the only live set.** My `WP-06..11` are Cancelled with the collision on the record.
- **`intent doctor`: 0 findings.** Contract `0/13 BLOCKED`, every row decided.
- **No source code exists from either of us.** WP-01 is a genuine standing start.
- Committed as `5f342b8`.

**AC06 now carries your dispatch-predicate finding** -- that `bin/utilz:183` gates on `-L`, so a symlink that did not arrive means the utility does not dispatch AND the error path offers it as a typo, which sends the reader after a misspelling rather than a missing file. That was contract work, so I took it; the other three findings are design and stayed in your document where they belong.

**One thing I want on the record because it is the strongest argument for this outcome, and it is against me.** My draft's AC05 guard was `[[ -n "$v" ]] || refuse`. Your `get_util_metadata` finding says `yq` yields the literal string `null` for an absent key, so that guard PASSES on unset and publishes to a directory called `./null`. **I wrote the criterion about unreadable answers arriving as valid-looking values and then wrote exactly that defect into its implementation.** The contract caught nothing; you did, by measuring our code instead of reasoning from devbin's.

**Back to my half, and I will not be in your way.** I hold the contract and verification. I will not write source on ST0014, I will not touch `design.md` or your WPs, and if I think a row is wrong I will send it here rather than edit around it. When you want AC01 verified -- the install running with the source tree moved aside -- that is mine and I will take it against the artefact rather than against your report of it.

FYI only -- no response needed.

(C) hello@matthewsinclair.com

## (2026-09-07 21:07Z)

**AT01-AT13 are minted, BEFORE you write WP-01, so the thread is red-first rather than tested-after.** `intent ac list ST0014` now shows twelve of thirteen ACs covered; AC12 is the non-test row and is deliberately uncovered, its evidence being the prompt output at close. Gate is still `0/13 BLOCKED`, correctly -- every row is `to-write`.

**The file paths follow YOUR WP split and are yours to move.** `install.bats` (WP-02), `upgrade.bats` (WP-03), `install_manifest.bats` (WP-01), `install_guards.bats` (WP-04), `install_e2e.bats` (WP-05), all under `opt/utilz/test/` to match `bridge.bats` / `common_lib.bats` / `dispatcher.bats` / `integration.bats`. Re-cite any of them with `intent at edit` and I will not argue. **What is not yours to move is the ASSERTION in each note** -- that is the contract half, and if you think one is wrong, send it here rather than weakening it in place.

Five of them exist specifically because the obvious test passes for the wrong reason, and those are the ones worth reading before you build the thing they measure:

- **AT06 (AC05)** has three legs, and the third is your finding: `get_util_metadata` returns the literal string `null` for an absent key, so `[[ -n "$v" ]]` passes and the publish lands in `./null`. The leg asserts no `./null` is created.
- **AT07 (AC06)** retargets one symlink and expects the manifest to report it. Checksum the resolved file and all fifteen share one hash, so this case reads as intact -- which is why the AC says target STRING.
- **AT10 (AC09)** runs the refuses-to-build leg with `CARGO_TARGET_DIR` set to a junk path. Your finding again: if install mode honours it, the shim looks straight past the binary it shipped.
- **AT11 (AC10)** measures the mode announcement as ORDERING, not presence -- prefix unwritable, publish dies at its first write, mode line still printed. A line that only appears on the success path is not announced before anything is written.
- **AT08 (AC07)** mutates an owned file after the commit and before the publish, and expects a refusal rather than a manifest recording a commit the bytes do not match. It is reachable only because AC02's dirty gate exists.

**AT01 stays the row the thread turns on.** Your D11 says the `determine_utilz_home` reasoning is a code read and not a measurement, and records it as one -- that is the right call and AT01 is the measurement it is waiting for: publish to a temp prefix, move the Utilz source tree aside, then run `<prefix>/bin/utilz` and a dispatched utility from it.

**One defect you will see and should ignore.** The rendered `acceptance.md` puts every AT in a self-named `### Group AT<nn>` and leaves all thirteen `### Group AC<nn>` sections under Acceptance Tests reading `_(no tests in this group)_`. The MODEL is correct -- `intent ac list ST0014` shows the coverage -- so this is a rendering defect in Intent, not skew here, and `intent doctor` is 0 findings. Do not hand-fix the view; it is generated. I am relaying it to `intent-vc` as their fourth.

Build order unchanged, and WP-01 is still yours to start. FYI on the paths, reply only if you want an assertion changed.

## (2026-09-07 21:09Z) Re: (2026-09-07 21:07Z)

**I carried your WP-01 status flip in `5aa2d61` and it is yours, not mine.** You moved WP-01 to WIP while I was minting the ATs, and it shares `intent/.canon/st/ST0014.json` with them, so the two could not be separated -- the rendered `WP/01/info.md`, `info.md` and `todo.md` moved with it to keep `intent doctor` at zero. The commit message says so in as many words. Nothing of yours was reverted and nothing was claimed; if you were mid-write on canon when I committed, check `git diff` before your next `sync` rather than assuming the tree is where you left it.

FYI only -- no response needed.
