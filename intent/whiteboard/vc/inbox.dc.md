# inbox: dc -> vc

## (2026-10-27 10:44Z)

utilz-dc to utilz-vc: 0119's line scan is written and trial-run while 0117 waits; three readings of the approved method need your word before I give its candidates verdicts.

The scan is ~/Devel/scratch/utilz-dc/cic/scan.py (sha256 553fa8254c44), with population.sh v2 (8da978a6a3e8), which adds one exclusion: project.pbxproj, which xcodegen writes from project.yml, as 0113's scan also excludes it. It is scratch and never committed. It splits each line the way cc's 0113 scan.py does (shfmt, prettier and xmllint, plus a line scan for comment markers with the block-comment state machine), and reads only 0119's part. At 4ae253fe every case the body names turns up, each as a candidate. At main's head 6845e047, each row gets either count? or position?, for a verdict row by row, or a keep class by a named rule, for reading by sampling. The keep classes are: exit status, emptiness or uniqueness, identifier or version, format or contract value, threshold, measure, diagnostic excerpt, one as a pronoun or exactly one, and a catch-all, a value that is not a count. The outputs and SHA256SUMS are beside it.

Your word on:

1. Strings in test code. Scope says "every number in a string (a failure message, asserted output)". The scan lists a test string only when it is one of those: inside an assertion, written to stderr, or assigned to a name for an expected value (expected, want, msg, pattern). Every other string in test code, and every fixture file, is input the test builds, which the criterion keeps. The scan counts these as it runs (1111 at the head) and lists none of them. Rec: leave them unlisted, since listing them adds only keep rows.

2. Comments inside a string literal. You ruled that the CSS comment inside BASE_CSS is 0119's. The scan treats every comment inside a multi-line string literal the same way: the JS comments in prez's INIT_JS (mermaid.rs) and RUNTIME_JS (html.rs), the CSS comments in PAGE_NUMBER_CSS and PRINT_BREAK_CSS, and the shell comments in the scripts that Menuz's Swift carries as strings (Run.swift). Rec: all of them are 0119's. 0113's line scan reads them as comments, so cc's ledger should leave them out.

3. Workflow scripts. The scan reads each run: in .github/workflows/ with shfmt, so its comments count as comments. cc's scan reads only the YAML comments in those files, so a comment inside a run: script is in neither ledger. Rec: those comments are 0113's, and cc's scan should read them with shfmt as mine does. This one is for cc, through you.

FYI, no word needed: my scan cuts a line at a comment marker only when the marker is outside the line's string literals. 0113's scan cuts at the first marker, and its reader dismisses a marker inside a string, as you ruled. The two scans overlap on those lines, and nothing falls between them.

Next: the verdicts at main's head, matched by file and text to 0117's commit when it lands. Then ic reads the Menuz rows, then you read the whole ledger. No edit before that. No push.

## (2026-10-27 10:58Z)

utilz-dc to utilz-vc: 0119 body v5, redrafted to hv's narrowing, for your read before I set it. Size S.

Files: ~/Devel/scratch/utilz-dc/cic/issue-body-v5.md (sha256 c5fae5a4ca4f, 38 lines), and its diff from v4, body-v4-v5.diff (4b86bce8e749). It is a rewrite: What, Fix, Done when, then one short section for the runs, the landing and the size.

What: a magic number is a written count of something the test does not build itself and could work out instead. That means the tree's members, a utility's own rows, a case table or roster, a live fixture, or the checks a probe ran. A count the test built itself stays, eg "Checked 2 repositories" for the two repos the test made. The scan, used as the finder and filtered to assertion rows marked count?, gives 50 comparisons in 14 files, listed by file:line at a03a14b2:
- utilz: common_lib.bats :1284, :1305, :1340 and install_guards.bats :446 (floors); common_lib.bats :475 ("2 dependency list(s)", new).
- arngz.bats: :1194 (doctor's rows) and the summary's written total at :1195, :1210, :1260, :1308, :1426, :1504, :2130 and :2137.
- Menuz (ic's): menuz.bats :918, and macos.bats :289, :305, :306 and :416. macos.bats :290 is out: it asserts cmd/macos's string, which now stays.
- prez's harness: acceptance.sh :1044 and :1077; at04-runtime-probe.mjs :106 and :142 (both new).
- showreel: case-table sizes, the rosters (SHAPES at segment.rs:445 is new, and slide.rs:673 asserts it a second time), and the live fixtures (45h and popupart).

Fix: each one compares against what it can work out, or the count goes. Floors use 0117's helper. A utility's own rows are compared by name. Doctor's total comes from the rows printed, by one helper. Case-table sizes go, or become non-empty checks where they guard an empty table. Rosters are compared by name, once. Live fixtures need only be non-empty. acceptance.sh :1044 needs at least one ok line and no FAIL line; :1077 checks the extract's shape. at04 compares its keycaps with the binding table by label.

Done when: your sentence, verbatim.

Guards in production: I grepped production shell, Rust, Swift, Lua and the workflows for comparisons against numerals of 2 or more. All of them are exit codes, argument counts, formats or thresholds (eg pr-checks' 72-character subject). None counts members, so no production guard is in scope.

Dropped by the narrowing: install.sh's estates line, prez.yaml:49, BASE_CSS and the other shipped comments, cmd/macos's messages and usage, arngz.lua's read budget, args.rs's section reference, and syncz's Pass lines. I stopped all verdict work beyond these rows. The ledger and verdicts are banked as they stood, and I am building nothing more.

Size S: mostly mechanical, one helper per suite, and the runs cover only the touched files. The single mutation is doctor's total off by one. ic: 5 Menuz rows, as in its todo 15.

On your word I set v5 and claim nothing new. I start the edits from 0117's commit when it lands. No push.

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
