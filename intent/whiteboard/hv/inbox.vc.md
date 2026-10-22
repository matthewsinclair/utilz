# inbox: vc -> hv

## (2026-09-21 18:51Z)

2.11.0 is ready for you to tag and push. Release commit 890064e: the gate passed 20/20, and versions read back utilz:2.11.0 and prez 2.3.0. Run: ! /Users/matts/Devel/prj/Utilz/tmp/release-2.11.0.sh -- it tags 2.11.0 bare at 890064e with --cleanup=whitespace, checks the annotation against tmp/tag-2.11.0.md (deleting the tag if it differs), and pushes main and the tag to local and upstream. After that, vc watches CI, runs tools/formula-bump 2.11.0, and hands you the tap step. Cut by hand because devbin's release core has a silent resolve bug with our older v-tags; fix due in devbin 0.1.5.

## (2026-10-16 19:08Z) FYI only -- no response needed.

vc, hv's word: all three Utilz nodes bank what we have, localfold and compact now. Each node: bank in-flight work (a branch commit by explicit path or tmp/), set its focus and a hold with the exact resume state, commit its own whiteboard views and own events by explicit path on main as wb(<node>): localfold, send vc the SHA, then hold for hv's compact. vc pushes main once all three folds are on it. No pushes, nothing heavy. The instruction in full is in each inbox by SendMessage.

## (2026-10-17 07:18Z)

vc, 17 Oct 07:2xZ: UTILZ 2.14.0 IS CUT-READY FOR YOUR TERMINAL. The release core is refused in my session (the auto-mode classifier), so the one command is yours: cd ~/Devel/prj/Utilz && bin/devbin release v2.14.0. What it does (the dry run at 5214f2e is green, 07:09Z to 07:17Z: check all passed, the estate passed, no step failed): stamps VERSION 2.14.0 and dates the CHANGELOG note 2026-10-17, commits "release: 2.14.0", asks you at step 6, then tags 2.14.0 (annotated, the notes body), pushes the commit and the tag to local (Dropbox) and upstream (GitHub), makes the release object 2.14.0 with gh, and waits up to 20 minutes on CI. After it: tell me (or I see the tag) and I run tools/formula-bump 2.14.0, commit the formula by path, copy it into the tap clone and brew audit it; the tap commit and push are yours after that; dc fills done.md; the kovacs runbook runs through intent-vc and kovacs-sysadm (its session needs your ! for the run, as devbin R1 did); dc installs 2.14.0 here after the tap push. The signed Menuz.app.zip waits on your bin/devbin macos store-creds. ST0027 is closed (WP-07 the identity row), CI green on main at the close in both the push run and the menuz-app dispatch. Intent 3.2.4 and Devbin 0.1.11 are cut-ready for your terminal too, their commands on their own boards.

## (2026-10-19 06:07Z) FYI only -- no response needed.

vc to all Utilz nodes: gtools-vc's queue has two new terms from 06:06Z, for every node on both estates (gtools-vc's board records them for hv to correct). (1) kovacs: a kovacs leg books with gtools-vc for the record, runs beside any Mac run when its START says it touches nothing on this Mac, and is ordered only against Utilz's own landings. (2) The light lane: a run whose START says it builds nothing, starts no GUI or daemon, binds no port and writes no state another run reads (its own temp dirs only) may share the window with one heavy run. That means at most one light beside one heavy, each with its own START, a GO given at a load under 60, and an END. A light run's red or green is read knowing a heavy run was beside it, so a failure that looks like timing is rerun alone before it counts. Heavy runs stay one at a time: any build (xcodebuild, swift build, cargo build), any whole suite (utilz test included), the estate gate, Chrome, a dry run or a cut, and any test that starts a daemon. Say light or heavy in each START.

## (2026-10-19 06:58Z) FYI only -- no response needed.

vc to all Utilz nodes, 19 Oct. (1) utilz-vc holds the host queue while gtools-vc is compacted (its handover just now), on decisions 59 and 62's terms unchanged. Every run is a START to utilz-vc by SendMessage, the GO comes only from utilz-vc, and the END goes to utilz-vc. One heavy run at a time, one light run beside it, and kovacs legs beside both, counted in the load. Before each GO I check that nothing listens on ports 47600 to 47799, that the load is under 60, and that no suite is running. New slots number from 69. Slot 65 (utilz-cc's utilz suite) is running, and its END comes to me. (2) hv's word to vc, "Ok, do it" (vc's decision 30): vc gives the word for each Utilz landing once the bytes are read and the booked runs are green. hv keeps the cut and every push, so a landing is a local commit by path and nothing more. Landings go one at a time into a primary that holds no one else's hunks, each patch re-applied on the head it lands on. The order is 0078 (utilz-ic), then 0077, then 0079 (utilz-cc). The sweep for 0053's class is in 2.14.1, utilz-cc's. 0072 stays open, since it needs sc.

## (2026-10-19 07:06Z) FYI only -- no response needed.

vc to all Utilz nodes: gtools-vc is back from its compact and holds the host queue again as of 07:06Z. Every START goes to gtools-vc by SendMessage, and the GO comes from gtools-vc alone; utilz-vc gives no more GOs. utilz-dc: send slot 72's END to gtools-vc as well as to me. utilz-cc: 0079's install_e2e.bats START goes to gtools-vc. utilz-ic: 0073's and 0074's runs go to gtools-vc.

## (2026-10-19 08:04Z) FYI only -- no response needed.

vc to all Utilz nodes: until utilz-dc fixes the test-home leak (an issue in 2.14.1), syncz.bats writes unison archives into the real archive dir, about 18 a run (on this Mac, ~/Library/Application Support/Unison, beside hv's own syncs), and cryptz.bats runs gpg on the real home. Keep both out of Mac runs that do not need them, and a whole-suite run that must include them says so in its START. dc's kovacs legs already keep both homes inside the run dir.

## (2026-10-19 08:30Z) FYI only -- no response needed.

vc to all Utilz nodes, from gtools-vc: the Mac is closed to Utilz runs from now until the Gtools 0.6.0 cut's step 5 ends (its local suite and app tests). kovacs legs still go, on a START as before. Send STARTs to gtools-vc as usual; it GOes them once step 5 has ended. Meanwhile, design and reading work goes on.

## (2026-10-19 08:37Z) FYI only -- no response needed.

vc to all Utilz nodes: gtools-vc is compacting, so every START comes to utilz-vc again, by SendMessage, slots from 97, on decisions 59 and 62's terms. The Mac stays closed to heavy runs until the Gtools 0.6.0 cut's step 5 ends. Light runs and kovacs legs can go until Gtools' dispatch run goes green; from then until step 5 ends nothing starts, kovacs legs included, since kovacs loads this Mac. Say light or heavy in every START.

## (2026-10-19 09:58Z) FYI only -- no response needed.

vc to all Utilz nodes: gtools-vc is back from its compact and holds the host queue again; it has closed the Mac for the Gtools 0.6.0 cut. After your compact, send every START to gtools-vc by SendMessage; it GOes them once the cut's step 5 has ended. utilz-vc gives no more GOs. Queued for then: utilz-ic's icon dev install and 0086's red and green; utilz-dc's 0082 landing (install_e2e in the primary) and 0081's kovacs leg for cc; utilz-cc's 0081 landing after that leg.

## (2026-10-19 13:25Z) FYI only -- no response needed.

vc to all Utilz nodes: slot 131 is GOne. utilz-dc lands 0082 in the primary, and its nine files sit uncommitted there until its commit: CHANGELOG.md, docs/developer-guide.md, opt/clipz/test/clipz.bats, opt/cryptz/test/cryptz.bats, opt/macoz/test/macoz.bats, opt/syncz/test/syncz.bats, opt/utilz/test/install_e2e.bats, opt/utilz/test/isolation.bats and opt/utilz/test/test_helper.bash. Until utilz-dc's END, nobody commits a change to any of the nine, nobody runs git add -A or commit -a, and every commit goes by path. Board commits are fine. 0086's landing (utilz-ic) comes after 131's commit, since it touches CHANGELOG.md.

## (2026-10-19 13:55Z) FYI only -- no response needed.

vc to all Utilz nodes: slot 133 is GOne. utilz-cc lands 0081 in the primary on 4aa86d6, and its seven files sit uncommitted there until its commit: CHANGELOG.md, docs/architecture.md, docs/developer-guide.md, opt/utilz/lib/common.sh, opt/utilz/lib/install.sh, opt/utilz/test/common_lib.bats and opt/utilz/test/install_lib.bats. Its commit step refuses on any move of HEAD, so until utilz-cc's END nobody commits anything to the primary, board records included. Bank them after. No git add -A or commit -a. Work in your own worktrees goes on as normal.

## (2026-10-19 14:01Z) FYI only -- no response needed.

vc to all Utilz nodes: slot 133 has ENDed. 0081 is landed as bffd04a, and I have checked it by change. The primary's commit window is closed, so commit your localfold now, by path, with a retry on index.lock, and send me its SHA. Nothing new STARTs or GOes until after hv's compacts.

## (2026-10-19 14:57Z) FYI only -- no response needed.

Slot 135 (heavy, utilz-cc) is running: 0085's landing in the primary. Until its END, nobody commits or edits common.sh, common_lib.bats, docs/developer-guide.md or CHANGELOG.md in the primary. Whiteboard commits by path are fine. Light runs book beside it as usual.

## (2026-10-19 15:08Z) FYI only -- no response needed.

vc's decision 38 (read it on vc's board): hv is AFK and vc has the pen. hv's goal is every Utilz issue fixed and 2.14.1 ready to cut, with no CI failure from a slip. That means: (1) utilz-dc finishes 0083's part (137, then the kovacs leg), then ic's and cc's parts of 0083 land in that order. cc lands 0084, then 0087. ic runs START A, the diagnostic install, after 137's END, taking hv's word as the yes, then START B and 0073's fix. (2) Before anything counts as ready, the final head passes a local twin of every CI job. The tests.yml Ubuntu loop, shellcheck 0.9.0, cargo fmt and clippy -D warnings, and cargo test and acceptance all run on kovacs. The macOS suites, cargo on the Mac and the menuz app build and test run here. dc's release dry run comes last. utilz-dc owns that gate. (3) Each node runs critic-<lang> and the formatters on its own diff before asking vc to read it, so no slip reaches CI. (4) Push, dispatch, cut and tap stay hv's.

## (2026-10-19 16:01Z) FYI only -- no response needed.

Slot 151 (heavy, utilz-dc) is running: 0083's landing in the primary, 28 files. Until its END, nobody edits or commits any of them in the primary: tests.yml, CHANGELOG.md, README.md, bin/utilz, the developer guide, help/arngz, macoz and utilz, opt/arngz, clipz, macoz and stampz, opt/utilz/lib/common.sh and install.sh, common_lib.bats, help_dispatch.bats, test_helper.bash, and the formula. Whiteboard commits by path are fine.

## (2026-10-19 16:18Z) FYI only -- no response needed.

Slot 157 (utilz-dc) is running: 0088's landing in the primary. Until its END, nobody edits or commits CHANGELOG.md, opt/utilz/test/test_helper.bash, isolation.bats or version_dispatch.bats in the primary.

## (2026-10-19 17:35Z) FYI only -- no response needed.

FOLD for hv's compact (vc's decision 39), and a freeze: nothing STARTs or GOes until after the compacts. Each node: (1) Bank in-flight work in ~/Devel/scratch/utilz-<node>/ (not /private/tmp, which a reboot empties), so the primary holds no uncommitted code. cc: 0089's re-apply on 80fb661 and 0092's design. dc: the final-head gate script. ic: the 0073 diagnostic's look and START B. (2) Archive what is finished. Set your focus, and a hold whose condition is hv's compact, with your exact resume state. (3) Commit wb(<node>): localfold by path: your events (subject node:<you>), your views, and any intent/.intentfiles line you wrote, which is modified in the primary now. (4) Send vc the SHA by board and SendMessage, then hold. vc checks each fold by change and folds last.

## (2026-10-19 17:40Z) FYI only -- no response needed.

vc, after hv's third compact of 19 Oct: decision 39's freeze lifts for each node once it has compacted and run its pickup. The queue resumes with vc's hold 16. (1) utilz-cc: send 0089's START (re-applied on 80fb661, prez 2.5.3). It names the Mac runs, the crate tests red then green and bin/devbin check all, plus dc's kovacs leg of the crate's tests on the same bytes. The landing waits for both to be green. Then 0092's design, for vc's read. (2) utilz-dc: hold until 0089 and 0092 have landed, apart from the kovacs leg of 0089 that cc's START books with you. Then the final-head gate at the sha vc names. (3) utilz-ic: hold for hv's return, the screen awake and vc's GO. Then the look (run-0073-look.sh) and START B. The host log is at slot 171. Nothing is running.

## (2026-10-19 18:13Z) FYI only -- no response needed.

vc: hv closed 0073 and 0080 to 0092 before the push (decision 44, commit a2a2536). Owners: do not close them again. A red on CI or the dispatch reopens the issue it touches. utilz-cc: your +ISSUE:0093 line in intent/.intentfiles is left unstaged for your own commit.

## (2026-10-19 18:17Z) FYI only -- no response needed.

vc: 0075 is closed on hv's word that the logout and login was already tested and works (commit 1c84a9a). There's no logout step before the cut. Open: 0093, which lands in 2.14.1, and 0072, which goes to the next release.

## (2026-10-19 18:32Z) FYI only -- no response needed.

vc: final head d5beb38 (0093 landed as b262242 and closed). Code freeze on every node until the cut. utilz-dc STARTs the gate's phases (1) to (4) whole at d5beb38. utilz-ic re-sends the menuz-app twin's START at d5beb38. Then AT27 alone, dc's report, hv's push and dispatch, and the dry run. Only 0072 is open, for the next release.

## (2026-10-22 18:53Z) FYI only -- no response needed.

vc to every Utilz node: Intent's devbin build all comes in about 20 minutes (intent-vc sends its START and END). It swaps the intent binary for every estate on this Mac and carries Intent issue 0612, which changes how the whiteboard stores a message. What each node does:
(1) Before intent-vc's START, commit your pending board renders under today's rule.
(2) After the swap, the first intent wb verb in this estate, a pickup included, re-renders every board.json and inbox view into board@4.0. vc commits that re-render whole, in one commit. No node commits a board file until vc says it is in.
(3) From then on a node commits exactly the paths its verb prints on wrote: lines. A re-rendered: line is another node's.
(4) A running intent mcp server keeps the old code and refuses a migrated store: write through the CLI, or reconnect with /mcp.
(5) No heavy run GOes between intent-vc's START and END.

## (2026-10-22 20:01Z) FYI only -- no response needed.

vc to every Utilz node, on hv's word to vc: "Ok, context is high. Let's corale a localfold across the nodes, then get this done on the bounce." Localfold now, for hv's compact:
(1) Nothing new STARTs, and what is held stays held: cc's R99 and dc's K1 for 0099 (slots 236 and 237), and ic's install of a build of main, each wait for intent-vc's gap after Intent's macos prepare.
(2) Archive what is finished and clear what is handled. Keep every unexecuted ruling, and every hold with its condition.
(3) Add a hold for hv's compact, released once the compact has run, then /in-session, your pickup and vc's word. Set your focus, and put your resume state in ~/Devel/scratch/utilz-<node>/RESUME.md.
(4) Commit exactly your verbs' wrote: paths (board@4.0). Do not release: a compact does not end a session.
(5) Send vc "folded" by socket with your commit's sha. vc folds last.

## (2026-10-22 20:15Z) FYI only -- no response needed.

vc's word after hv's compact (22 Oct): the compact holds are released, so cc's hold 42, dc's hold 23 and ic's hold 13 go, each archived by its owner. The box is Intent's until intent-vc names a gap (hv's decision 53, Intent first), so every Utilz heavy run stays held until vc's GO, and vc has asked intent-vc for the gap. cc: go on your plan. Amend 0100's body (critic-rust's two WARNINGs and critic-shell's, one home for "counted" and for the name check, the .mov orphan, and which of critic-shell's findings you take, each named) and 0101's body and title (a fixed "..", "." or "" name, and the counter in the name's last extension with its own test), both for vc's read before any v2 code; no build until a GO. R99 (slot 236) stays held. dc: doing 15 (0099's K1, slot 237) stays held with R99; todos 25 and 26 on cc's STARTs; todo 18 after Intent's cut. ic: hold 12 (the install of a build of main) stands for the gap. vc read dispatch 39844116949's menuz app job: Xcode 27.1 (27A9275), and arca_swift resolves to 0.2.0 at f7742b1 (the committed pin, and the only 0.2.x tag), so 0072 and 0097 stand.

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
