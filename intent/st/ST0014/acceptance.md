---
st_id: ST0014
title: Make utilz insallable in to opt/ just like devbin
---

# ST0014: Make utilz insallable in to opt/ just like devbin -- Acceptance

> **THIS FILE IS A GENERATED VIEW, AND A ROW AUTHORED HERE IS DISCARDED BY THE NEXT SYNC.** The acceptance contract is canon in the thread model; this file renders it. Acceptance Criteria (AC) are the ratified completeness boundary; Acceptance Tests (AT) are the small red-to-green tests that prove them.
>
> Done = every AC is covered by a GREEN AT, or (for a non-test AC) its named evidence is satisfied, AND the AC set is the ratified full boundary. Done is read from this map, never from a hand-ticked box.
>
> Test-backed satisfaction is COMPUTED from covering green ATs and never stored -- storing it would be double truth. An AC has four states, not two: beyond satisfied and unsatisfied, a requirement can be **descoped** to a named thread or **withdrawn** with its reason on the record. Both are non-blocking and both are reported separately, so a thread that descoped half its contract looks like one.

## Acceptance Criteria

### Group AC01

- AC01 `utilz install` publishes a runnable install to the configured prefix, and the installed tree RUNS with the source tree absent. Devbin's install tree is deliberately not runnable (D33); ours inverts that, so the test is that the install works when the source is moved aside, not merely that files arrived. -- satisfied: no (computed)

### Group AC02

- AC02 Publishing from a dirty source tree is REFUSED, and no flag overrides it. An install cut from a dirty tree launders the bytes through one more hop and gives them the look of provenance; devbin measured five of thirteen estates running bytes that matched no commit. -- satisfied: no (computed)

### Group AC03

- AC03 Publishing into a Utilz SOURCE tree is refused, whatever the source. The predicate is a property of the TARGET, never src-equals-dst: devbin's guard compared the two and a vendored copy landed in their dev tree past it on 2026-09-07. -- satisfied: no (computed)

### Group AC04

- AC04 install and upgrade mirror each other: install refuses when an install exists and names upgrade; upgrade refuses when none exists and names install. Whichever verb is reached for, the wrong one names the right one. -- satisfied: no (computed)

### Group AC05

- AC05 The install prefix is CONFIGURATION read from `install.prefix` in `opt/utilz/utilz.yaml`, with NO built-in default, and unset is refused BY NAME rather than guessed. RULED by hv 2026-09-07: utilz's own metadata file, read through get_util_metadata like every other utility's yaml, rather than borrowing bin/.devbin/config.yaml, which is devbin's config FOR utilz. A baked default relocates the decision from a key somebody wrote to the absence of one, and a publish to the wrong place is indistinguishable from a publish to the right one -- devbin shipped a hardcoded $HOME/Devel/opt/devbin into fourteen estates before this was learned. -- satisfied: no (computed)

### Group AC06

- AC06 The fifteen bin/ symlinks arrive as SYMLINKS pointing at utilz, not as dereferenced copies, and the manifest checksums each link's TARGET STRING rather than the file it resolves to. Checksumming the resolved file gives all fifteen the same hash, so a link retargeted at the wrong utility reads as intact. Fifteen symlinks and two real files (utilz, and the vendored devbin) -- measured. THE SYMLINKS ARE THE DISPATCH PREDICATE, NOT DECORATION: bin/utilz:183 dispatches only when -L "$UTILZ_HOME/bin/$UTIL_NAME" holds, so a utility whose symlink did not arrive does not dispatch at all AND the error path offers it as a typo, which sends the reader after a misspelling rather than a missing file. The manifest's roll-call IS the owned set, so a count one high carries a phantom entry and one low leaves a file nothing checks. Dispatch-predicate point found by cc. -- satisfied: no (computed)

### Group AC07

- AC07 The install carries a manifest recording the utilz version, the source commit and a checksum for every owned file, and the recorded commit describes the bytes actually shipped. -- satisfied: no (computed)

### Group AC08

- AC08 upgrade REPORTS files edited in place and leaves them alone without --force, and a file it declined to overwrite keeps its install-time checksum. Re-checksumming a file that was refused would record the edit as canonical and the next check would pronounce it intact. -- satisfied: no (computed)

### Group AC09

- AC09 prez runs from the install because the install SHIPS THE BUILT BINARY, built at publish time; the install-tree shim REFUSES to build rather than falling back to one. RULED by hv 2026-09-07. Building on first use was rejected on a mechanism rather than a preference: prez_is_stale() uses `find -newer` against src/, themes/ and assets/, and cp stamps each destination as it writes, so whether a fresh install rebuilt itself would be decided by COPY ORDER -- deterministic per implementation, invisible in the output, and flipping on a reordering nobody would classify as behavioural. A build fallback in the shim reintroduces exactly that on the first stale check. prez is the only utility with a build step: 16 utility dirs, 15 impl files read, 1 hit. -- satisfied: no (computed)

### Group AC10

- AC10 The mode is ANNOUNCED before anything is written. A discriminator that is merely correct is not enough: a misdetection has to land in the output rather than be discovered later in the filesystem. -- satisfied: no (computed)

### Group AC11

- AC11 install and upgrade write nothing a person authored and nothing outside the prefix. In particular the ~/.local/bin PATH symlinks are NEVER relinked implicitly -- that is mutating hv's environment and needs a verb or flag they typed. -- satisfied: no (computed)

### Group AC12

- AC12 (non-test) An installed utilz can be told apart from a source utilz AT THE PROMPT, reporting which tree it is and the commit it was cut from. Without this the two-tree arrangement is invisible in exactly the situation it exists for: a person debugging behaviour cannot tell which copy produced it. -- satisfied: no

### Group AC13

- AC13 `utilz test` run against an INSTALL tree REFUSES, and names the source tree as where to run it. RULED by hv 2026-09-07. The suite mutates $UTILZ_HOME/bin -- which is why it is not concurrency-safe -- so from a runnable install it rewrites the very files the manifest checksums and the install reports drift nobody caused. Refusing cannot corrupt anything; re-checksumming after a run was rejected because it makes the manifest re-bless whatever the run left behind, which is devbin's refuse-then-bless failure. Devbin never meets this because their install cannot run. Found by cc. -- satisfied: no (computed)

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

### Group AT07

_(no criteria in this group)_

### Group AT08

_(no criteria in this group)_

### Group AT09

_(no criteria in this group)_

### Group AT10

_(no criteria in this group)_

### Group AT11

_(no criteria in this group)_

### Group AT12

_(no criteria in this group)_

### Group AT13

_(no criteria in this group)_

## Acceptance Tests

### Group AC01

_(no tests in this group)_

### Group AC02

_(no tests in this group)_

### Group AC03

_(no tests in this group)_

### Group AC04

_(no tests in this group)_

### Group AC05

_(no tests in this group)_

### Group AC06

_(no tests in this group)_

### Group AC07

_(no tests in this group)_

### Group AC08

_(no tests in this group)_

### Group AC09

_(no tests in this group)_

### Group AC10

_(no tests in this group)_

### Group AC11

_(no tests in this group)_

### Group AC12

_(no tests in this group)_

### Group AC13

_(no tests in this group)_

### Group AT01

- AT01 `opt/utilz/test/install_e2e.bats` -- covers AC01 -- status: to-write -- Publish to a temp prefix, move the Utilz source tree aside, then run <prefix>/bin/utilz and a dispatched utility from it. Moving the source is the measurement; asserting files arrived is not.

### Group AT02

- AT02 `opt/utilz/test/install.bats` -- covers AC02 -- status: to-write -- Publish from a tree with one uncommitted change: refused. Then repeat with every flag the verb accepts, including --force, and assert each is still refused. A gate with an escape hatch is not a gate.

### Group AT03

- AT03 `opt/utilz/test/install.bats` -- covers AC03 -- status: to-write -- Publish INTO a Utilz source tree is refused, and the refusal is driven from the TARGET: run it with a source that is not the target too. A src-equals-dst comparison passes this and is the exact guard devbin's vendored copy walked past on 2026-09-07.

### Group AT04

- AT04 `opt/utilz/test/install.bats` -- covers AC04 -- status: to-write -- install against a prefix that already holds an install: refused, and the message NAMES upgrade. Assert the word, not just the non-zero rc.

### Group AT05

- AT05 `opt/utilz/test/upgrade.bats` -- covers AC04 -- status: to-write -- upgrade against a prefix holding no install: refused, and the message NAMES install. The mirror half of AT04; both halves or the mirror is untested.

### Group AT06

- AT06 `opt/utilz/test/install.bats` -- covers AC05 -- status: to-write -- Prefix comes from install.prefix in opt/utilz/utilz.yaml. Three cases: key set (publishes there), key ABSENT (refused BY NAME, naming the key and the file), and the get_util_metadata literal-null case -- an absent key returns the string null, so a bare -n test passes and publishes to ./null. Assert no ./null is created.

### Group AT07

- AT07 `opt/utilz/test/install_manifest.bats` -- covers AC06 -- status: to-write -- Count the arrivals: 15 symlinks and 2 real files. Each of the 15 is -L and its readlink target string matches the source link. Then retarget one link at a different utility WITHOUT changing what it resolves to being a valid file, and assert the manifest check reports it. Checksumming the resolved file gives all 15 one hash and this case reads as intact.

### Group AT08

- AT08 `opt/utilz/test/install_manifest.bats` -- covers AC07 -- status: to-write -- Manifest records the utilz version, the source commit and a checksum per owned file. The commit must describe the SHIPPED bytes: mutate one owned file in the source after the commit and before the publish, and assert the publish refuses rather than recording a commit the bytes do not match. AC02's dirty gate is what makes this reachable.

### Group AT09

- AT09 `opt/utilz/test/upgrade.bats` -- covers AC08 -- status: to-write -- Edit an installed file in place, upgrade without --force: the edit is REPORTED, the file is left alone, and its recorded checksum is still the install-time one. Re-checksumming a file the upgrade declined to overwrite would bless the edit and every later check would call it intact.

### Group AT10

- AT10 `opt/utilz/test/install_guards.bats` -- covers AC09 -- status: to-write -- The published install carries a built prez binary and runs it. Then make the install look stale to prez_is_stale and assert the shim REFUSES rather than building. Run that leg with CARGO_TARGET_DIR set to a junk path: install mode must ignore it, or the shim looks past the shipped binary.

### Group AT11

- AT11 `opt/utilz/test/install.bats` -- covers AC10 -- status: to-write -- The mode is on stdout before the first write. Measure it as ordering, not presence: run with the prefix unwritable so the publish fails at its first write, and assert the mode line was still printed.

### Group AT12

- AT12 `opt/utilz/test/install.bats` -- covers AC11 -- status: to-write -- Snapshot the filesystem outside the prefix before and after install and upgrade: unchanged. Specifically ~/.local/bin is untouched -- point a fixture link there and assert it is neither relinked nor removed. Implicit relinking mutates hv's environment.

### Group AT13

- AT13 `opt/utilz/test/install_guards.bats` -- covers AC13 -- status: to-write -- utilz test run with UTILZ_HOME at an install tree: refused, and the message names the SOURCE tree as where to run it. Then assert the install's manifest still verifies -- a refusal that ran anything first has already rewritten bin/.

---

_Generated by Intent v3.0.0 from `thread.json`. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
