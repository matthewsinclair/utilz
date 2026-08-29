---
st_id: ST0010
title: Add prez to utilz to support markdown presentation pipeline
---

# ST0010: Add prez to utilz to support markdown presentation pipeline -- Acceptance

> **THIS FILE IS A GENERATED VIEW, AND A ROW AUTHORED HERE IS DISCARDED BY THE NEXT SYNC.** The acceptance contract is canon in the thread model; this file renders it. Acceptance Criteria (AC) are the ratified completeness boundary; Acceptance Tests (AT) are the small red-to-green tests that prove them.
>
> Done = every AC is covered by a GREEN AT, or (for a non-test AC) its named evidence is satisfied, AND the AC set is the ratified full boundary. Done is read from this map, never from a hand-ticked box.
>
> Test-backed satisfaction is COMPUTED from covering green ATs and never stored -- storing it would be double truth. An AC has four states, not two: beyond satisfied and unsatisfied, a requirement can be **descoped** to a named thread or **withdrawn** with its reason on the record. Both are non-blocking and both are reported separately, so a thread that descoped half its contract looks like one.

## Acceptance Criteria

### Group AC01

- AC01 Dependency posture: the crate's Cargo.toml declares comrak as its ONLY dependency, with default-features = false (the syntect default locks 104 packages against 25 and funds nothing here -- the theme owns code presentation). Args, front matter, slide split, inlining, base64 and shell-outs stay hand-rolled against std. Any further crate needs hv sign-off named in the adding commit. (Carried from _tools AC02.) -- satisfied: no (computed)

### Group AC02

- AC02 Self-contained artifact: `utilz prez build examples/demo.md` emits one .html that opens fully offline from file:// -- no prez-emitted http(s) references -- with local images inlined as data: URIs, and the text-only demo artifact <= 100 KB. (Carried from _tools AC03.) -- satisfied: no (computed)

### Group AC03

- AC03 Notes stripped: the demo deck's notes comment carries a distinctive sentinel string and that sentinel appears nowhere in the built artifact (grep on the demo build proves it). Stripping is a REMOVAL wherever a notes comment appears on a depth-zero line, mid-line included, not a whole-line rule; a notes comment INSIDE a code fence is author content and is shown, so the grep targets the sentinel payload, never the literal notes: token. (Carried from _tools AC04.) -- satisfied: no (computed)

### Group AC04

- AC04 Base runtime, on the demo artifact: arrows/space/PgUp/PgDn navigate, Home/End jump to first/last, a slide counter shows n/N, and #n hash addressing deep-links and survives reload. FOUR STRUCTURAL PROPERTIES, which are what this criterion actually pins, because the key roster itself lives in ONE place -- the BINDINGS table in src/html.rs -- and re-listing it here would make this a second home for it: (a) every key dispatches THROUGH that table, never a switch, so the table is the roster; (b) i opens the index and ESC MUST NOT -- esc closes, like q, and the absence is asserted separately from the presence, because a runtime binding esc to BOTH would satisfy a check that only looked for i and hv's actual complaint (one key meaning open-this and close-this by invisible state) would survive its own fix; (c) the conditional commit binding (enter/space, while indexing) must PRECEDE the unconditional next binding in the table -- both are individually correct and only their ORDER makes them work, so the position is asserted, not just the presence; (d) the key bar re-renders per mode, since a static list advertises keys that do nothing in the current one. (e) NO SHIPPED ARTIFACT RESTATES THE ROSTER. The key bar renders from BINDINGS and re-renders per mode, so it is the one presentation of the key set; the example decks point at `?` and carry no key list of their own. This clause exists because hv caught test_pres.md advertising "Esc overview grid" -- the exact behaviour removed an hour earlier -- by looking at a screenshot, which is the only instrument that had it. Fixing the decks was not enough: a copy that was wrong once will be wrong again, and the fix is deleting the copy rather than checking it. VERIFIED TWO WAYS WITH THE BOUNDARY STATED: AT04 drives real Chrome and is the only thing that can prove fullscreen, focus and real key events; AT17 stubs the DOM and drives keydown at the script extracted from a BUILT artifact, claiming dispatch and state and explicitly nothing visual. Neither replaces the other -- they measure different properties, so this is not the duplication rule's case. (Carried from _tools AC05; rewritten 2026-08-29 for hv's runtime changes at 4ed491e and the commit binding after it.) -- satisfied: no (computed)

### Group AC05

- AC05 PDF: `utilz prez pdf examples/demo.md` produces one slide per 254x142.9mm page via a probed installed browser; with --browser /nonexistent it refuses non-zero, listing every path probed and the remedy. (Carried from _tools AC06.) -- satisfied: no (computed)

### Group AC06

- AC06 Present: `utilz prez present` builds, launches the browser de-chromed/fullscreen on the artifact, then exits -- no prez process left behind, no server, ever (hv's standing anti-requirement: the browser presents; prez writes a file and stops). (Carried from _tools AC07.) -- satisfied: no (computed)

### Group AC07

- AC07 Mermaid opt-in: with `mermaid: true` in front matter a fenced mermaid block renders as a diagram offline; without the opt-in the artifact carries zero mermaid bytes, proven by a grep for a library-internal symbol, never a token a deck might legitimately discuss. (Carried from _tools AC08.) -- satisfied: no (computed)

### Group AC08

- AC08 Theme system: a single .css restyles the deck without touching the md; --theme NAME and --theme=NAME produce byte-identical output; an unresolvable theme is REFUSED non-zero -- naming the built-ins and the search path, and, with PREZ_THEME_PATH unset, saying no theme directories were searched -- never falling back to the default, and leaving no partial artifact. A theme carrying an external URL is refused at build naming file, line and offender; a URL inside a CSS comment is documentation and builds. EVERY built-in: builds the demo, declares all six standard classes, emits no custom property outside the --gp- namespace, carries zero external references, overflows no slide, and measures >= 4.5:1 worst-case text contrast -- any quoted figure citing selector + palette + commit (worked example: 8bit th at 4.18:1, hidden by headless Chrome defaulting light AND a probe that never reached a table cell; removing either blind spot alone would not have shown it). There is no theme named `default` in either tree: prez's no-flag default is `simple`, and a caller's default is the caller's argument (hv 2026-08-29). Addressing-mode semantics live in AC15. (Carried from _tools AC09; the addressing clause is deliberately excised to its successor.) -- satisfied: no (computed)

### Group AC09

- AC09 Standalone source: NO REFERENCE TO THE ESTATE THIS CRATE CAME FROM -- paths, organisation or project names, or imports -- anywhere in opt/prez/crate/src, COMMENTS INCLUDED, grep-validated. The comment exemption is withdrawn (hv 2026-08-29: Utilz carries zero knowledge of that estate). It was defensible on its own terms, since a comment creates no coupling and nothing executes it -- but it is not only coupling that travels: the check that enforced this required a leading quote, so it saw string literals only, and a real client path sat in a deck.rs comment, green, for as long as the check existed. A rule the check cannot see is a rule nobody enforces. The tripwire keeps naming the estate deliberately, because a grep that cannot say what it is looking for cannot look for it; it lives in test/, never in src/, so it cannot match itself. 2-space indent. `intent critic rust` clean AND `cargo clippy --all-targets` clean -- clippy named explicitly because the critic arms 1 of 7 rules and declines the clippy-backed ones, so a clean critic alone is a control that cannot go red. (Carried from upstream AC10; the comment clause tightened here.) -- satisfied: no (computed)

### Group AC10

- AC10 Deterministic artifact: nothing in a built .html branches on a VIEWER PREFERENCE -- no prefers-color-scheme, prefers-reduced-motion, prefers-contrast, forced-colors or navigator.language in any emitted script or stylesheet, theme CSS included, and no runtime palette choice; mermaid's themeVariables are built from the five universal tokens only (--gp-bg, --gp-fg, --gp-muted, --gp-rule, --gp-code-bg -- --gp-accent is declared by 4 of 7 themes, and an undeclared token's empty string re-enters the defect). Scoped to BRANCHING, not pixel-identity: system font stacks legitimately resolve per machine, and a green determinism probe says the artifact renders the SAME everywhere, not that it renders CORRECTLY anywhere (recorded limit: diagram labels took documentElement's serif while the deck ran its own sans -- deterministically wrong, caught by screenshot after the green). Verified by grepping emitted output AND by CDP light/dark emulation agreeing on the computed palette, swept on examples/test_pres.md with demo.md present only as the labelled negative control (its mermaid: true is documentation inside a fence; a sweep pointed at demo.md alone goes green on the exact defect this criterion exists for). (Carried from _tools AC13.) -- satisfied: no (computed)

### Group AC11

- AC11 Repo build hygiene: opt/prez/crate/target/ is gitignored in a commit that lands BEFORE any in-tree build exists; no build-generated file is ever tracked (the pres_*.html litter class stays behind by hoisting from git at the pin, tracked content only, never cp -R). The Dropbox rationale of _tools AC01 is recorded as NOT transferring: Utilz sits outside Dropbox and its local remote is bare. -- satisfied: no (computed)

### Group AC12

- AC12 The shim: opt/prez/prez is bash, shellcheck-clean inside the blocking gate, and does resolve-ensure-exec only -- rebuilds when the binary is missing or older than any crate source (Cargo.*, src/, themes/, assets/), refuses without cargo BEFORE any build attempt naming the install remedy, and execs the binary with no presentation logic of its own. The dispatcher is untouched: zero changes to bin/utilz. -- satisfied: no (computed)

### Group AC13

- AC13 Framework integration: prez appears in utilz list with its yaml metadata; utilz help prez renders help/prez.md; utilz doctor keeps its declare-and-check posture (cargo appears as a manual optional line, not a hard dependency); utilz test prez drives cargo test + shim BATS + crate/test/acceptance.sh --strict by CONVENTION (crate/Cargo.toml, test/*.bats, crate/test/acceptance.sh -- the next Rust utility inherits the driver unedited), with counters aggregated across all three sources; CI gains a rust job (both OSes; the log PROVES a browser was found, because a skip surviving into green is the measured failure mode) and a clippy job (-D warnings, blocking from day one), both wired into test-summary. -- satisfied: no (computed)

### Group AC14

- AC14 Announce-on-resolve: when a theme NAME resolves from PREZ_THEME_PATH rather than the built-ins, the build says so on stderr, naming the directory it came from -- local-wins shadowing stays visible, and under --theme-path a user with two directories can always answer which one won. -- satisfied: no (computed)

### Group AC15

- AC15 Theme addressing, split by mode (hv 2026-08-29): --theme=NAME resolves names ONLY -- search path then built-ins, never the working directory (killing the measured cwd-shadowing: --theme=simple beside a ./simple/ directory resolved the local one, elsewhere the built-in, silently); --theme-file=FILE resolves a path ONLY, mutually exclusive with --theme, its refusal saying no-such-file rather than offering a theme roster; --theme-path=PATHSTR PREPENDS colon-separated directories to PREZ_THEME_PATH for the invocation (prepend, not replace: flag and env compose); front matter splits identically into theme: (name) and theme-file: (deck-relative path), or the ambiguity moves into the deck where it travels; --theme=./x.css is thereby refused as a name carrying a separator -- a breaking change taken deliberately at the rename, the cheapest moment it will ever have. (f) THE REFUSAL OF A PATH GIVEN TO --theme MUST NAME --theme-file, because this split breaks an invocation that is already in use. Measured 2026-08-29: hv presented a real 14-slide client deck with `prez present <deck> --theme <path>`, which is in hv's shell history and in that deck's build instructions. On the day WP-06 lands, that exact command starts failing, and a refusal that only says a name cannot contain a separator reads as the port having broken the deck. Naming the replacement flag turns a breakage into a migration. This is the general rule of AC20(b) pointing the other way: a refusal must name the remedy for the case that actually fired. -- satisfied: no (computed)

### Group AC16

- AC16 (non-test) A human has LOOKED at the output. Every built-in theme is rendered and viewed -- not merely measured -- and the render is compared against what the criteria claim, with the observation recorded as evidence. This is a gate rather than a note because the automated suite demonstrably cannot stand in for it: on _tools, hv's screenshots found four defects a full day of tests had missed, and the diagram-font defect (labels resolving to a serif off documentElement while the deck ran its own sans) passed a GREEN determinism probe -- deterministically wrong is still wrong, and nothing in the suite connected the two. The operational rule, in _tools-cc's words: a green determinism probe is a licence to look at the output, not a substitute for looking at it. -- satisfied: no

### Group AC17

- AC17 (non-test) Every green recorded in this repo names the instrument that produced it, and that instrument is provably this repo's: the binary under test is built from a clean checkout of the recorded pin (3e16597), and WP-04 records the build's provenance alongside its numbers. The seam is real rather than theoretical -- at the pin, _tools-vc found the binary on disk predated its own source commit by three and a half minutes (cc had compiled a working tree and committed afterwards), so the first green there was true but unattributable until forced to rebuild from HEAD. The first Utilz build at the pin is the first moment the sha and the binary are provably the same artifact; if this repo's numbers disagree with _tools', that seam is checked BEFORE the port is suspected. -- satisfied: no

### Group AC18

- AC18 The harness must not lie, block, or be unreproducible -- three inherited defects, all invisible on the machine that wrote them, all fixed HERE because here is where they can be tested. (a) ONE browser resolution, not two: test/acceptance.sh's chrome() carries two macOS app paths and no PATH names, while src/drive.rs carries four app paths AND six PATH names (google-chrome, google-chrome-stable, chromium, chromium-browser, microsoft-edge, brave-browser). On Linux the tool finds a browser and the harness does not, so five ATs (AT04, AT05, AT07's diagram measurement, AT08's per-theme legibility, AT12) degrade to skips and --strict turns a correct build RED -- while the message says 'no Chrome or Chromium installed' about a browser the tool under test is happily driving. A Highlander violation that has already drifted once, unreported because both were only ever run on macOS; the harness resolves through the tool's list or asks the tool, never a second copy. (b) An override hook (eg GP_TEST_BROWSER=/nonexistent) so the browserless path is reproducible on a machine that HAS a browser -- today the control proving --strict matters cannot be exercised anywhere Chrome is installed, which makes it a control that cannot go red, the exact class this thread inherited its vocabulary for. The tool already has the shape (--browser /nonexistent); the harness lacks it. (c) NO INTERACTIVE MODAL: every headless launch passes --use-mock-keychain (or --password-store=basic), because a fresh --user-data-dir makes macOS prompt for a Safe Storage keychain entry -- an interactive dialog in a non-interactive suite, which HANGS rather than fails, and which --strict cannot distinguish from still working. It reached hv's screen on 2026-08-29; AT04 has done it since it was written and AT12's per-theme profiles made it eight times per run. -- satisfied: no (computed)

### Group AC19

- AC19 The presenting window opens at the deck's own shape, and the shape is overridable. prez pdf already renders 16:9 by default (--paper 254x142.9mm); prez present passed --app, --start-fullscreen and --new-window and set no geometry at all, so an app window inherited whatever Chrome last remembered and hv got a PORTRAIT window for a 16:9 deck. Three clauses: (a) present sizes the window to the deck's aspect by default, matching pdf's default rather than a second opinion about it; (b) a --window WxH flag overrides, mirroring --paper's grammar so the two verbs read the same way; (c) NO FLAG IS PASSED THAT HAS NO OBSERVABLE EFFECT ON A PLATFORM WE SHIP TO -- --start-fullscreen is passed today and demonstrably did not take on macOS, which is AC18's class (a check or a flag that reads plausibly and does something adjacent to what it names) applied to the tool rather than the harness. Either it works and that is shown, or it goes. VERIFIED IN TWO LAYERS, the same split as AC04: a unit test asserts the ARGV open_presenting builds, which needs no browser and is where a silently-dropped flag is caught; the browser AT asserts the window that actually appears, which is the only thing that can prove a flag took effect. (Minted 2026-08-29 from hv's screenshot -- the second defect this thread found by hv looking at output rather than by any green.) -- satisfied: no (computed)

### Group AC20

- AC20 A binding does what its label says, or the bar and the runtime say what will actually happen. hv pressed q and got 'this browser will not let a page close itself -- q closes the window that prez present opens' IN THE WINDOW prez present had just opened. The fallback names as its remedy the exact case in which it fired. Underneath it is a false premise, stated in the code comment at src/html.rs:418: 'window.close() only acts on a window script opened -- which is what prez present produces, since it launches a dedicated app window.' A command-line --app window is NOT script-opened; Chrome refuses window.close() there, so q has never closed that window and the bar advertises 'close' for a key that cannot. Two clauses: (a) every entry in BINDINGS either performs its label or the bar shows what it will really do -- a key that cannot do the thing is not advertised as doing it; (b) NO FALLBACK MESSAGE NAMES AS ITS REMEDY THE CASE IN WHICH IT FIRED. That second clause is the general form and the checkable one: a message written for the failure it does not cover reads as help and sends the reader back to the thing that just failed. RULED BY hv 2026-08-29, who tried it: the bar advertises the OS shortcut, not q. (c) The close row of the key bar shows the platform's own window-close shortcut -- Cmd-W on macOS, Ctrl-W elsewhere -- because that is the thing that actually closes the window, and the bar's job is to name keys that work. (d) THE SHORTCUT IS RESOLVED WHEN THE DECK IS VIEWED, NEVER WHEN IT IS BUILT. A prez artifact is self-contained and portable by design -- it opens offline, from a USB stick, on another machine, in five years -- so a deck built on a Mac and opened on Linux must say Ctrl-W. Baking the build host's platform into the artifact would be correct on the author's machine and wrong everywhere else, which is the failure mode this whole thread collects. (e) q and Esc stay CAUGHT, and say the shortcut rather than claiming to close. A key that silently does nothing reads as broken, which is the state clause (b) was written against; pointing at the working shortcut is honest and actionable, and it does not name itself as the remedy. (Minted 2026-08-29 from hv's second screenshot. Both of today's runtime defects were found by hv looking at output; no green had either.) -- satisfied: no (computed)

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

### Group AT18

_(no criteria in this group)_

### Group AT19

_(no criteria in this group)_

### Group AT20

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

### Group AC18

_(no tests in this group)_

### Group AC19

_(no tests in this group)_

### Group AC20

_(no tests in this group)_

### Group AT01

- AT01 `opt/prez/crate/test/acceptance.sh` -- covers AC11 -- status: to-write -- Block AT01, rewritten by hoist-adapt.sh step 3 to prove the UTILZ build mechanism (build lands in-crate, git sees no litter, 8 MB ceiling with a stat -c %s fallback). At b600306 the upstream block still proves _tools' devbin redirect, so this row's meaning DEPENDS on that adaptation surviving every re-archive. AT id == the acceptance.sh block id the suite PRINTS. The carried suite has no AT10/AT11 (those were _tools' estate-side tests and stayed behind), so those ids are free for Utilz-native rows.

### Group AT02

- AT02 `opt/prez/crate/test/acceptance.sh` -- covers AC01 -- status: to-write -- Block AT02, 'dependency posture: comrak and std, nothing else'. Carried from _tools ST0002, re-derived against pin b600306 on 2026-08-29. Green THERE under --strict (10 passed / 0 failed / 0 skipped, exit 0, 69s, _tools-vc's own run, not relayed). UNVERIFIED HERE until WP-04 reproduces it with instruments run in this repo.

### Group AT03

- AT03 `opt/prez/crate/test/acceptance.sh` -- covers AC02, AC03 -- status: to-write -- Block AT03, 'self-contained artifact, and notes that reach no artifact' -- one block, two criteria. Carried from _tools ST0002, re-derived against pin b600306 on 2026-08-29. Green THERE under --strict (10 passed / 0 failed / 0 skipped, exit 0, 69s, _tools-vc's own run, not relayed). UNVERIFIED HERE until WP-04 reproduces it with instruments run in this repo.

### Group AT04

- AT04 `opt/prez/crate/test/acceptance.sh` -- covers AC04 -- status: to-write -- Block AT04, 'base runtime in a real browser: keys, counter, overview, hash, fullscreen'. Launches Chrome backgrounded with a disposable profile and --use-mock-keychain. Carried from _tools ST0002, re-derived against pin b600306 on 2026-08-29. Green THERE under --strict (10 passed / 0 failed / 0 skipped, exit 0, 69s, _tools-vc's own run, not relayed). UNVERIFIED HERE until WP-04 reproduces it with instruments run in this repo.

### Group AT05

- AT05 `opt/prez/crate/test/acceptance.sh` -- covers AC05 -- status: to-write -- Block AT05, 'pdf: one slide per page, and a refusal that names what it probed'. Carried from _tools ST0002, re-derived against pin b600306 on 2026-08-29. Green THERE under --strict (10 passed / 0 failed / 0 skipped, exit 0, 69s, _tools-vc's own run, not relayed). UNVERIFIED HERE until WP-04 reproduces it with instruments run in this repo.

### Group AT06

- AT06 `opt/prez/crate/test/acceptance.sh` -- covers AC06 -- status: to-write -- Block AT06, 'present: launches de-chromed, then the tool gets out of the way'. Carried from _tools ST0002, re-derived against pin b600306 on 2026-08-29. Green THERE under --strict (10 passed / 0 failed / 0 skipped, exit 0, 69s, _tools-vc's own run, not relayed). UNVERIFIED HERE until WP-04 reproduces it with instruments run in this repo.

### Group AT07

- AT07 `opt/prez/crate/test/acceptance.sh` -- covers AC07 -- status: to-write -- Block AT07, 'mermaid is opt-in, and opting out costs zero bytes'. Waits on a command substitution, so it carries NO --user-data-dir: adding one made --dump-dom hang forever, measured five ways on Chrome 151. Point it at test_pres.md, never demo.md. Carried from _tools ST0002, re-derived against pin b600306 on 2026-08-29. Green THERE under --strict (10 passed / 0 failed / 0 skipped, exit 0, 69s, _tools-vc's own run, not relayed). UNVERIFIED HERE until WP-04 reproduces it with instruments run in this repo.

### Group AT08

- AT08 `opt/prez/crate/test/acceptance.sh` -- covers AC08 -- status: to-write -- Block AT08, 'themes are orthogonal, offline, and the default carries no brand'. Same command-substitution form and same no-profile-dir rule as AT07. Carried from _tools ST0002, re-derived against pin b600306 on 2026-08-29. Green THERE under --strict (10 passed / 0 failed / 0 skipped, exit 0, 69s, _tools-vc's own run, not relayed). UNVERIFIED HERE until WP-04 reproduces it with instruments run in this repo.

### Group AT09

- AT09 `opt/prez/crate/test/acceptance.sh` -- covers AC09 -- status: to-write -- Block AT09, 'the source is standalone, and both code gates are run' -- estate paths, estate imports, tabs, odd indent, intent critic rust AND cargo clippy named separately because the critic arms 1 of 7 rules. Carried from _tools ST0002, re-derived against pin b600306 on 2026-08-29. Green THERE under --strict (10 passed / 0 failed / 0 skipped, exit 0, 69s, _tools-vc's own run, not relayed). UNVERIFIED HERE until WP-04 reproduces it with instruments run in this repo.

### Group AT10

- AT10 `opt/prez/test/prez.bats` -- covers AC11 -- status: to-write -- Utilz-native. Co-covers AC11 with acceptance.sh's AT01, and this is NOT duplication: AC11 has two clauses and each row anchors a different one. AT10 proves the ignore rule is PRESENT AND COMMITTED (clause 1, a repo-history property a build cannot show); AT01 proves a build PRODUCES nothing tracked (clause 2). Neither is redundant, so do not tidy one away. ID RULE: an ST0010 AT id equals the acceptance.sh block id wherever that suite prints one (AT01-AT09, AT12). The carried suite has NO AT10/AT11 -- those were _tools' estate-side tests and stayed behind -- so those ids are free and hold Utilz-native rows. AT13-AT15 are new acceptance.sh blocks this thread adds; AT16 is Utilz-native.

### Group AT11

- AT11 `opt/prez/test/prez.bats` -- covers AC12 -- status: to-write -- Shim black-box: version/help through the dispatcher, the no-cargo refusal names the remedy and fires BEFORE any build attempt, freshness rebuilds on Cargo.*, src/, themes/ AND assets/ (the last two are include_str! embeds -- a check watching only src/ calls a stale binary current). Note --version and --help are intercepted by the dispatcher and answered from prez.yaml, so any case meaning to exercise the binary must use a real verb. ID RULE: an ST0010 AT id equals the acceptance.sh block id wherever that suite prints one (AT01-AT09, AT12). The carried suite has NO AT10/AT11 -- those were _tools' estate-side tests and stayed behind -- so those ids are free and hold Utilz-native rows. AT13-AT15 are new acceptance.sh blocks this thread adds; AT16 is Utilz-native.

### Group AT12

- AT12 `opt/prez/crate/test/acceptance.sh` -- covers AC10 -- status: to-write -- Block AT12, 'determinism: one artifact renders the same on every machine'. Backgrounded launch, ONE reused profile for the whole sweep (eight fresh profiles was the keychain-modal amplifier). Carried from _tools ST0002, re-derived against pin b600306 on 2026-08-29. Green THERE under --strict (10 passed / 0 failed / 0 skipped, exit 0, 69s, _tools-vc's own run, not relayed). UNVERIFIED HERE until WP-04 reproduces it with instruments run in this repo.

### Group AT13

- AT13 `opt/prez/crate/test/acceptance.sh` -- covers AC14 -- status: to-write -- New case post-hoist: a search-path theme resolving announces its source directory on stderr; a built-in resolving stays silent.

### Group AT14

- AT14 `opt/prez/crate/test/acceptance.sh` -- covers AC15 -- status: to-write -- GENUINELY red-first: --theme=NAME must resolve identically from two working directories, one containing a ./NAME/ directory -- RED against the pinned binary today (path.exists() wins). Goes green only when the split lands (WP-06).

### Group AT15

- AT15 `opt/prez/crate/test/acceptance.sh` -- covers AC18 -- status: to-write -- Three clauses, each red-first and separately checkable: (a) chrome() resolves a browser on a PATH-only box -- exercised for real by the Linux CI job, which is where this first becomes visible; (b) the override forces the refusal path on a machine that has Chrome, so the --strict control is finally reproducible; (c) a fresh-profile headless launch completes with no keychain prompt. Note the LIMIT of (c) as verified so far: vc confirmed --use-mock-keychain is accepted and Chrome renders normally under it, but absence-of-a-dialog-on-someone-else's-screen is not observable from a shell -- hv confirms, or the AT asserts no Safe Storage entry is created.

### Group AT16

- AT16 `opt/prez/test/prez.bats` -- covers AC13 -- status: to-write -- Framework integration: list/help/doctor/test surfaces observed through the dispatcher; the CI half is evidenced by the first green run on both OSes, and the log must PROVE a browser was found because a skip surviving into green is the measured failure mode. Was AT12 until 2026-08-29; moved because acceptance.sh PRINTS its own AT12 (determinism) and two instruments cannot share an id. ID RULE: an ST0010 AT id equals the acceptance.sh block id wherever that suite prints one (AT01-AT09, AT12). The carried suite has NO AT10/AT11 -- those were _tools' estate-side tests and stayed behind -- so those ids are free and hold Utilz-native rows. AT13-AT15 are new acceptance.sh blocks this thread adds; AT16 is Utilz-native.

### Group AT17

- AT17 `opt/prez/crate/test/acceptance.sh` -- covers AC04 -- status: to-write -- Block AT17, 'the runtime's key handling, driven with no browser at all' -- runs test/runtime-logic-probe.mjs, 29 checks, over a synthetic deck AND test_pres.md. Co-covers AC04 with AT04 and is NOT duplication: AT04 proves a real browser does the thing, AT17 proves the dispatch table routes correctly, and the boundary is written into the probe. It exists because a keyboard runtime is exactly what gets shipped on 'it compiles' -- two of hv's runtime changes had only a build behind them. Extracts the runtime by its own IIFE terminator, never the first script tag: html.rs appends mermaid AFTER the runtime, so on a mermaid deck the first (and only) script is 3.5 MB of vendored bundle. The extraction CHECKS ITSELF and exits 2 if it finds no binding table or any sign of esbuild -- a boundary read out of a text file starts selecting the wrong span silently, and the symptom is a probe that passes having tested something else. Red-first proven: unreachable commit binding -> 6 failures, exit 1. Minted by utilz-cc at c3307c5 and verified here as the id the suite prints.

### Group AT18

- AT18 `opt/prez/crate/src/drive.rs` -- covers AC19 -- status: to-write -- To write, utilz-cc's. Two layers: a cargo unit test over open_presenting's constructed argv (browserless, catches a flag that is passed and ignored), plus a browser check that the window that appears has the deck's aspect. The argv half must assert the ABSENCE of any flag proven inert as well as the presence of the geometry, or a build that keeps --start-fullscreen alongside a working --window-size passes a check that only looks for the new flag -- the same both-directions rule as AC04(b).

### Group AT19

- AT19 `opt/prez/crate/test/runtime-logic-probe.mjs` -- covers AC20 -- status: to-write -- To write, utilz-cc's. AT17's probe already stubs the DOM and holds BINDINGS, so it is the cheap home. Four assertions: the bar's close row shows the platform shortcut; q and Esc are still caught and say it; the message TEXT is asserted, not merely its existence, because the defect was a truthful-looking sentence with a false remedy in it; and the platform branch is driven BOTH ways from a stubbed navigator, since a check run only on the build host proves nothing about the portable artifact -- that is clause (d), and a single-platform test would pass on a Mac while the Linux path stayed unexercised.

### Group AT20

- AT20 `opt/prez/crate/test/acceptance.sh` -- covers AC19 -- status: to-write -- AC19's BROWSER layer, split out of AT18 on 2026-08-29 because nothing covered it and AT18 green alone would have satisfied AC19 with half its clauses unproven. AT18 keeps the argv layer, which is real: the unit tests under drive.rs's "AT18's argv half" header, plus three assertions inside AT06's block (launched at the deck's aspect, no flag that Chrome silently ignores, --window overrides the default). This row is the other half and it needs a REAL window, not a headless one, so it is the only check in the suite that puts something on the human's screen. Two things it must settle, both open: whether the window that actually appears carries the deck's aspect, and utilz-cc's unclosed question -- when Chrome is ALREADY RUNNING the launch forwards to the existing instance, and --window-size may not apply on that path, so AC19's geometry could be cold-start-only. A green taken on a machine with no Chrome running would not answer that and must not be recorded as if it had.

---

_Generated by Intent v3.0.0 from `thread.json`. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
