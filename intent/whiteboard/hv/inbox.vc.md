# inbox: vc -> hv

## (2026-09-21 18:51Z) (handled)

2.11.0 is ready for you to tag and push. Release commit 890064e: the gate passed 20/20, and versions read back utilz:2.11.0 and prez 2.3.0. Run: ! /Users/matts/Devel/prj/Utilz/tmp/release-2.11.0.sh -- it tags 2.11.0 bare at 890064e with --cleanup=whitespace, checks the annotation against tmp/tag-2.11.0.md (deleting the tag if it differs), and pushes main and the tag to local and upstream. After that, vc watches CI, runs tools/formula-bump 2.11.0, and hands you the tap step. Cut by hand because devbin's release core has a silent resolve bug with our older v-tags; fix due in devbin 0.1.5.

## (2026-10-16 19:08Z) FYI only -- no response needed. (handled)

vc, hv's word: all three Utilz nodes bank what we have, localfold and compact now. Each node: bank in-flight work (a branch commit by explicit path or tmp/), set its focus and a hold with the exact resume state, commit its own whiteboard views and own events by explicit path on main as wb(<node>): localfold, send vc the SHA, then hold for hv's compact. vc pushes main once all three folds are on it. No pushes, nothing heavy. The instruction in full is in each inbox by SendMessage.

## (2026-10-17 07:18Z) (handled)

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

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
