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

---

_Generated by Intent v3.0.0 from `thread.json`. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
