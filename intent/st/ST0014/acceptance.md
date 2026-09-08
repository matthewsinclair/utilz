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

- AC01 `utilz install` publishes a runnable install to the configured prefix, and the installed tree RUNS with the source tree absent. Devbin's install tree is deliberately not runnable (D33); ours inverts that, so the test is that the install works when the source is moved aside, not merely that files arrived. -- satisfied: yes (computed)

### Group AC02

- AC02 Publishing from a dirty source tree is REFUSED, and no flag overrides it. An install cut from a dirty tree launders the bytes through one more hop and gives them the look of provenance; devbin measured five of thirteen estates running bytes that matched no commit. -- satisfied: yes (computed)

### Group AC03

- AC03 Publishing into a Utilz SOURCE tree is refused, whatever the source. The predicate is a property of the TARGET, never src-equals-dst: devbin's guard compared the two and a vendored copy landed in their dev tree past it on 2026-09-07. -- satisfied: yes (computed)

### Group AC04

- AC04 install and upgrade mirror each other: install refuses when an install exists and names upgrade; upgrade refuses when none exists and names install. Whichever verb is reached for, the wrong one names the right one. -- satisfied: yes (computed)

### Group AC05

- AC05 The install prefix is CONFIGURATION read from `install.prefix` in `opt/utilz/utilz.yaml`, with NO built-in default, and unset is refused BY NAME rather than guessed. RULED by hv 2026-09-07: utilz's own metadata file, read through get_util_metadata like every other utility's yaml, rather than borrowing bin/.devbin/config.yaml, which is devbin's config FOR utilz. A baked default relocates the decision from a key somebody wrote to the absence of one, and a publish to the wrong place is indistinguishable from a publish to the right one -- devbin shipped a hardcoded $HOME/Devel/opt/devbin into fourteen estates before this was learned. -- satisfied: yes (computed)

### Group AC06

- AC06 The fifteen bin/ symlinks arrive as SYMLINKS, not as dereferenced copies, and the manifest records each link's TARGET STRING against its PATH. MEASURED 8 Sep against the real install: all fifteen target strings are the identical four characters 'utilz' -- the links are distinguished by their PATH, never by their target, because dispatch keys on basename $0. So the row is 'link<TAB>utilz<TAB>bin/cleanz' and it is the third field that identifies it. THIS AC PREVIOUSLY JUSTIFIED THE TARGET-STRING RULE AS CATCHING 'A LINK RETARGETED AT THE WRONG UTILITY', AND THAT SCENARIO CANNOT OCCUR -- vc's wording, corrected against the artefact rather than defended. There is no wrong utility to point at: every link legitimately names the same target. What the rule actually catches, verified by doing it: a link pointing OUTSIDE the set reports 'retargeted bin/syncz', and restoring it returns rc 0. The real argument for not dereferencing is simpler and survives: a dereferenced copy stores the dispatcher's bytes fifteen times, loses the link-ness that AC06's own dispatch predicate depends on, and grows the install by fifteen copies of bin/utilz. THE SYMLINKS ARE THE DISPATCH PREDICATE, NOT DECORATION: bin/utilz:183 dispatches only when -L "$UTILZ_HOME/bin/$UTIL_NAME" holds, so a utility whose symlink did not arrive does not dispatch at all AND the error path offers it as a typo, sending the reader after a misspelling rather than a missing file. THE SOURCE bin/ HOLDS FIFTEEN SYMLINKS AND TWO REAL FILES (utilz, and the vendored devbin); THE INSTALL'S HOLDS FIFTEEN AND ONE, measured on the real install 8 Sep, because D2 excludes devbin as not ours to publish. Dispatch-predicate point found by cc. -- satisfied: yes (computed)

### Group AC07

- AC07 The install carries a manifest recording the utilz version, the source commit and a checksum for every owned file, and the recorded commit describes the bytes actually shipped. -- satisfied: yes (computed)

### Group AC08

- AC08 upgrade REPORTS files edited in place and leaves them alone without --force, and a file it declined to overwrite keeps its install-time checksum. Re-checksumming a file that was refused would record the edit as canonical and the next check would pronounce it intact. -- satisfied: yes (computed)

### Group AC09

- AC09 prez runs from the install because the install SHIPS THE BUILT BINARY, built at publish time; the install-tree shim REFUSES to build rather than falling back to one. RULED by hv 2026-09-07. Building on first use was rejected on a mechanism rather than a preference: prez_is_stale() uses `find -newer` against src/, themes/ and assets/, and cp stamps each destination as it writes, so whether a fresh install rebuilt itself would be decided by COPY ORDER -- deterministic per implementation, invisible in the output, and flipping on a reordering nobody would classify as behavioural. A build fallback in the shim reintroduces exactly that on the first stale check. prez is the only utility with a build step: 16 utility dirs, 15 impl files read, 1 hit. -- satisfied: yes (computed)

### Group AC10

- AC10 The mode is ANNOUNCED before anything is written. A discriminator that is merely correct is not enough: a misdetection has to land in the output rather than be discovered later in the filesystem. -- satisfied: yes (computed)

### Group AC11

- AC11 install and upgrade write nothing a person authored and nothing outside the prefix. In particular the ~/.local/bin PATH symlinks are NEVER relinked implicitly -- that is mutating hv's environment and needs a verb or flag they typed. -- satisfied: yes (computed)

### Group AC12

- AC12 (non-test) An installed utilz can be told apart from a source utilz AT THE PROMPT, reporting which tree it is and the commit it was cut from. Without this the two-tree arrangement is invisible in exactly the situation it exists for: a person debugging behaviour cannot tell which copy produced it. -- evidence: utilz version names the tree and the commit at the prompt. Verified by vc 8 Sep in a clean login shell: the install answers 'installed at /Users/matts/Devel/opt/utilz (1679024)' and the source answers 'source at /Users/matts/Devel/prj/Utilz'. Before ST0014 both printed 'utilz v2.5.0' and nothing else. -- satisfied: yes

### Group AC13

- AC13 `utilz test` run against an INSTALL tree REFUSES, and names the source tree as where to run it. RULED by hv 2026-09-07. The suite mutates $UTILZ_HOME/bin -- which is why it is not concurrency-safe -- so from a runnable install it rewrites the very files the manifest checksums and the install reports drift nobody caused. Refusing cannot corrupt anything; re-checksumming after a run was rejected because it makes the manifest re-bless whatever the run left behind, which is devbin's refuse-then-bless failure. Devbin never meets this because their install cannot run. Found by cc. -- satisfied: yes (computed)

### Group AC14

- AC14 (non-test) A file that NORMAL USE creates inside the prefix, and that the owned set does not name, is not drift. Two of fifteen utilities build a Python venv on first run -- pdf2md and xtrct each exec "$LIB_DIR/.venv/bin/python3" after ensure_venv (opt/utilz/lib/common.sh:223), at opt/<n>/lib/.venv, INSIDE the install and outside git ls-files because it is gitignored. So an install that has been USED carries files the manifest never recorded, and a check that reads any unowned file as drift reports drift nobody caused on two of fifteen utilities. THIS IS AC13'S SHAPE WITH AC13'S REMEDY UNAVAILABLE: utilz test is refused because refusing costs nothing, but pdf2md and xtrct RUNNING IS THE INSTALL WORKING (AC01), so the check must distinguish unowned-and-expected from owned-and-changed rather than refuse. Found by vc 7 Sep while verifying cc's D2 exclusion list; 22 paths across 5 utilities live outside opt/<n>/{<n>,<n>.yaml,README.md}, and these two are the pair that keep writing after install. -- evidence: AT14 green in opt/utilz/test/install_guards.bats. MIS-KINDED AT CREATION: this row is test-backed and should compute, but intent ac new defaults to --kind non-test and no verb changes an AC's kind, so it is satisfied by evidence instead. Verified by vc 8 Sep: install_manifest_check walks the manifest rows and never the tree, so a .venv built inside the install by pdf2md or xtrct is not read as drift; manifest_check returns rc 0 against the live install. -- satisfied: yes

### Group AC15

- AC15 (non-test) UTILZ_HOME IS NOT A USER INTERFACE. THE DISPATCHER FINDS ITSELF AND WORKS EVERYTHING OUT FROM THERE. RE-RULED by hv 8 Sep, reversing vc's ruling of the previous evening; hv is right and the general form is hv's: if it can find the dispatcher on PATH it can derive the rest, so no environment variable is needed at all. determine_utilz_home (bin/utilz:17-53) already does exactly that -- walk the symlink chain from $0, take the parent of bin/ -- and bin/utilz:42 then threw the answer away whenever the variable happened to be set, which is how an exported value silently redirected an install at the checkout. NOBODY SETS IT NOW AND SETTING IT HAS NO EFFECT. The variable survives ONLY as an internal channel from the dispatcher to its children: derived once from $0 and exported, because fifteen utilities each re-deriving it would be fifteen copies of one answer (IN-AG-HIGHLANDER-001). The library keeps READING it and the dispatcher is its only producer in production. VC'S EARLIER RULING KEPT THE HONOURING AND ADDED AN STDERR ANNOUNCEMENT, ON A MEASUREMENT ABOUT THE LIBRARY APPLIED TO THE DISPATCHER -- that conflation is what hv caught. Re-measured 8 Sep by what each consumer actually invokes: test_helper.bash:20 is convergent, so derive gives the identical answer; common_lib.bats:71 and install.sh:124 source the LIBRARY and never run the dispatcher; opt/prez/prez:24 has its own fallback and receives the exported value anyway; cleanz.bats:575 and install_guards.bats:107,120,191,207 are convergent. THE ONLY DIVERGENT DISPATCHER INVOCATIONS IN THE TREE ARE install_guards.bats:166 AND :217, THE TESTS OF THE ANNOUNCEMENT ITSELF. A behaviour whose only consumer is its own test is circular; deleting it removes the test rather than breaking anything, and the whole class goes with it -- no divergence to announce, nothing for AC17 to refuse, and a user with a stale variable simply gets the tree they invoked. -- evidence: AT15 green in opt/utilz/test/install_guards.bats. Mis-kinded as AC14. Verified by vc 8 Sep against the live estate: env -u UTILZ_HOME and UTILZ_HOME=/nonexistent and UTILZ_HOME=<the real other tree> all return the tree the binary lives in, with EMPTY stderr, and a dispatched utility answers from the same tree, which proves the derived value was exported to children. -- satisfied: yes

### Group AC16

- AC16 (non-test) AN EXPLICIT VERB REPOINTS THE PATH SYMLINKS AT A TREE THE CALLER NAMES, AND NOTHING ELSE EVER TOUCHES THEM. RULED by vc 7 Sep with the pen, closing the gap between the contract and hv's opening question -- why ~/.local/bin/utilz points at the checkout rather than the install. Measured: SIXTEEN links in ~/.local/bin resolve into the Utilz source tree, all fifteen utilities plus utilz. Without this row a green ST0014 leaves hv typing utilz and getting the checkout, and no criterion reports it. THE VERB IS SEPARATE FROM install AND upgrade, NOT A FLAG ON THEM: a --relink flag becomes habitual and then the relinking is implicit by habit, which is the thing AC11 forbids. AC11 and this row are the same policy from two sides -- never implicitly, always available explicitly. SHELL-INIT IN DEVBIN'S SHAPE WAS REJECTED: devbin has one entry point and is reached by absolute path from .zshrc:27-28, which does not transfer to sixteen PATH entries, and resolving by PATH order would make which-tree-answers depend on shell state, which is the defect AC15 exists to remove. DOING NOTHING WAS REJECTED because it leaves a manual sixteen-link step with no record, rediscovered as a bug rather than a decision. The verb reports what it changed and what it left, is reversible by naming the source tree, and LEAVES A LINK IT DID NOT WRITE ALONE -- ~/.local/bin/prez is relative and points at bin/utilz rather than bin/prez, which works because dispatch keys on basename $0, and normalising it is a change to hv's environment nobody asked for. -- evidence: AT16 green in opt/utilz/test/relink.bats. Mis-kinded as AC14. Verified by vc 8 Sep on hv's real ~/.local/bin: 16 changed / 15 left alone, idempotent on a second run (0 changed / 16 already correct), and my own ls -lT read shows exactly 16 links dated 8 Sep against 21 others dating back to March. -- satisfied: yes

### Group AC17

- AC17 (non-test) `utilz use dev|opt` SWITCHES TREES IN ONE COMMAND, FROM EITHER TREE, WITH NO ARGUMENT BEYOND THE WORD, NO NEW CONFIGURATION AND NO ENVIRONMENT VARIABLE. RULED by vc 8 Sep on hv's ask, then SIMPLIFIED TWICE against hv's corrections. The install records source-tree in its manifest header alongside utilz-version and source-commit -- the absolute path it was published FROM. That one line makes the verb turnkey: from the install, 'use dev' reads source-tree from the manifest; from the source, 'use opt' reads install.prefix from utilz.yaml. Each tree holds the address of the other, so NEITHER DIRECTION NEEDS A PATH TYPED OR A KEY INVENTED. THIS ROW'S FIRST DRAFT REQUIRED A SECOND CONFIG KEY AND BUILT ITSELF AROUND REFUSING WHILE UTILZ_HOME IS EXPORTED. Both are gone: the key duplicated an address the manifest carries for free, and AC15 now has the dispatcher ignore an inherited UTILZ_HOME entirely, so there is no override to refuse under. MECHANISM IS relink AND THERE IS EXACTLY ONE OF IT (IN-AG-HIGHLANDER-001): use parses a word to a tree, calls relink, renders (IN-AG-THIN-COORD-001). If it grows a link-walk, a skip policy or a report of its own it has gone wrong. Bare `utilz use` reports which tree the links currently serve and changes nothing, because a switch you cannot interrogate is one you run to find out where you are. -- evidence: AT17 green in opt/utilz/test/relink.bats. Mis-kinded as AC14. Verified by vc 8 Sep in a clean login shell: 'utilz use dev' then 'utilz use opt' round-trips with one word each way, no path typed; use dev FROM the install reads source-tree out of its own manifest; bare 'utilz use' reports opt/dev/other counts and changes nothing. -- satisfied: yes

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

### Group AT14

_(no criteria in this group)_

### Group AT15

_(no criteria in this group)_

### Group AT16

_(no criteria in this group)_

### Group AT17

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

### Group AC14

_(no tests in this group)_

### Group AC15

_(no tests in this group)_

### Group AC16

_(no tests in this group)_

### Group AC17

_(no tests in this group)_

### Group AT01

- AT01 `opt/utilz/test/install_e2e.bats` -- covers AC01 -- status: green -- Publish to a temp prefix, move the Utilz source tree aside, then run <prefix>/bin/utilz and a dispatched utility from it. Moving the source is the measurement; asserting files arrived is not.

### Group AT02

- AT02 `opt/utilz/test/install.bats` -- covers AC02 -- status: green -- Publish from a tree with one uncommitted change: refused. Then repeat with every flag the verb accepts, including --force, and assert each is still refused. A gate with an escape hatch is not a gate.

### Group AT03

- AT03 `opt/utilz/test/install.bats` -- covers AC03 -- status: green -- Publish INTO a Utilz source tree is refused, and the refusal is driven from the TARGET: run it with a source that is not the target too. A src-equals-dst comparison passes this and is the exact guard devbin's vendored copy walked past on 2026-09-07.

### Group AT04

- AT04 `opt/utilz/test/install.bats` -- covers AC04 -- status: green -- install against a prefix that already holds an install: refused, and the message NAMES upgrade. Assert the word, not just the non-zero rc.

### Group AT05

- AT05 `opt/utilz/test/upgrade.bats` -- covers AC04 -- status: green -- upgrade against a prefix holding no install: refused, and the message NAMES install. The mirror half of AT04; both halves or the mirror is untested.

### Group AT06

- AT06 `opt/utilz/test/install.bats` -- covers AC05 -- status: green -- Prefix comes from install.prefix in opt/utilz/utilz.yaml. Four legs. (1) key set: publishes there. (2) key ABSENT: refused BY NAME, naming the key and the file -- and the key IS absent today, so this is the live path, not a contrived one. (3) the literal-null leg, cc's finding, MEASURED 7 Sep: get_util_metadata utilz .install.prefix returns the four-character string 'null', so [[ -n $v ]] PASSES and a bare guard publishes to ./null. Assert no ./null is created. (4) a MALFORMED query returns EMPTY rather than null -- yq eval needs the leading dot, and 'install.prefix' without it yields a zero-length result. Both the null and the empty case must be refused, and a guard written for either one alone lets the other through.

### Group AT07

- AT07 `opt/utilz/test/install_lib.bats` -- covers AC06 -- status: green -- Three legs, all three run against the REAL install 8 Sep. (1) arrivals: 15 symlinks and ONE real file, utilz -- not two, because D2 excludes bin/devbin. VERIFIED. (2) every link's target string is byte-identical to its source counterpart, and each is the literal 'utilz'. VERIFIED. (3) corruption is detected BY PATH, not by target: point bin/syncz at something outside the tree and assert the check reports 'retargeted bin/syncz', then restore and assert rc 0. VERIFIED. DO NOT WRITE THE LEG THIS ROW USED TO CARRY -- 'retarget one link at a different utility' -- it is untestable, because all fifteen legitimately share one target string and there is no wrong utility to point at. That leg was vc's and it would have passed vacuously.

### Group AT08

- AT08 `opt/utilz/test/install_lib.bats` -- covers AC07 -- status: green -- Verified by vc 8 Sep against the real install: manifest header carries utilz-version 2.5.0 and source-commit d3142a7, which is an ancestor of main; 111 file/link rows; install_manifest_check returns rc 0, so every recorded checksum matches the shipped bytes. The commit-describes-the-shipped-bytes leg holds by construction here because AC02's dirty gate refused anything else -- the install announced 'clean, d3142a7' before writing. The refusal leg itself is exercised in cc's install.bats, which passes.

### Group AT09

- AT09 `opt/utilz/test/upgrade.bats` -- covers AC08 -- status: green -- Edit an installed file in place, upgrade without --force: the edit is REPORTED, the file is left alone, and its recorded checksum is still the install-time one. Re-checksumming a file the upgrade declined to overwrite would bless the edit and every later check would call it intact.

### Group AT10

- AT10 `opt/utilz/test/install_guards.bats` -- covers AC09 -- status: green -- The published install carries a built prez binary and runs it. Then make the install look stale to prez_is_stale and assert the shim REFUSES rather than building. Run that leg with CARGO_TARGET_DIR set to a junk path: install mode must ignore it, or the shim looks past the shipped binary.

### Group AT11

- AT11 `opt/utilz/test/install.bats` -- covers AC10 -- status: green -- The mode is on stdout before the first write. Measure it as ordering, not presence: run with the prefix unwritable so the publish fails at its first write, and assert the mode line was still printed.

### Group AT12

- AT12 `opt/utilz/test/relink.bats` -- covers AC11 -- status: green -- Snapshot the filesystem outside the prefix before and after install and upgrade: unchanged. Specifically ~/.local/bin is untouched -- point a fixture link there and assert it is neither relinked nor removed. Implicit relinking mutates hv's environment.

### Group AT13

- AT13 `opt/utilz/test/install_guards.bats` -- covers AC13 -- status: green -- utilz test run with UTILZ_HOME at an install tree: refused, and the message names the SOURCE tree as where to run it. Then assert the install's manifest still verifies -- a refusal that ran anything first has already rewritten bin/.

### Group AT14

- AT14 `opt/utilz/test/install_guards.bats` -- covers AC14 -- status: green -- Publish, then run pdf2md --version or whatever the cheapest venv-creating path is, then run the manifest check: it must report the install intact. Assert the .venv actually got created first, or the test passes by never exercising the case. Then edit an OWNED file and assert the same check DOES report that -- one leg without the other proves only that the check is silent.

### Group AT15

- AT15 `opt/utilz/test/install_guards.bats` -- covers AC15 -- status: green -- Three legs, and they assert the OPPOSITE of what this row used to. (1) publish to a prefix with a marker VERSION, leave the source in place, run <prefix>/bin/utilz version with UTILZ_HOME EXPORTED at the source: THE MARKER COMES BACK. The inherited value has no effect. (2) stderr is SILENT -- there is no announcement, because there is no divergence to announce; assert stderr is empty, not merely that stdout is right. (3) a child process resolves correctly: run a DISPATCHED utility the same way and assert it too answers from the prefix, which proves the dispatcher exported the derived value rather than merely using it locally. DELETE install_guards.bats:166 and :217 -- they test the honour-and-announce behaviour this row no longer has, and a passing test for deleted behaviour is the worst artefact of the change.

### Group AT16

- AT16 `opt/utilz/test/relink.bats` -- covers AC16 -- status: green -- Run the verb against a fixture bin/ holding both link shapes -- absolute-to-own-name, and the relative-to-dispatcher shape ~/.local/bin/prez actually has. Assert: every link now resolves into the named tree; the odd-shaped one still dispatches; the verb REPORTS what it changed; a link pointing at neither tree is left untouched and reported as skipped. Then assert install and upgrade with no verb change NOTHING in that directory -- the AC11 half. One leg without the other proves only that something moved.

### Group AT17

- AT17 `opt/utilz/test/relink.bats` -- covers AC17 -- status: green -- Three legs. (1) TURNKEY BOTH WAYS: from the install, 'utilz use dev' with no further argument repoints every link at the source; from the source, 'utilz use opt' repoints them back. Assert no path was typed, no key beyond install.prefix and the manifest's source-tree was read, and NO environment variable was set. (2) the manifest header carries source-tree and it is the absolute path published from -- publish from a moved checkout and assert the recorded path follows it. (3) use calls relink rather than reimplementing it: assert a link pointing at neither tree is skipped and reported, which is relink's documented policy, so a second implementation would have to reproduce it to pass. Bare 'utilz use' reports and changes nothing -- assert link mtimes are untouched, not merely that the output looks right. THE UTILZ_HOME REFUSAL LEG IS DELETED with AC15's re-ruling; there is no override to refuse under.

---

_Generated by Intent v3.0.0 from `thread.json`. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
