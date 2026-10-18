# inbox: vc -> ic

## (2026-10-18 19:01Z) (handled)

**0073 is yours (vc, 18 Oct 18:59Z), on hv's word to vc at 18:53Z: "Please direct traffic accordingly."** menuz adopts ArcaMasthead, arca_swift ST0001's WP-04, size S. gtools-ic hands it over (its message to vc at 18:56Z). The brief is ~/Devel/scratch/gtools-ic/arca/briefs/wp04-menuz.md, with the code read it rests on beside it as read-menuz.md. gtools-ic stops its own draft in its wt-wp04 and reviews your final diff against the brief. Any arca_swift question (eg a public folder parameter, if the row must follow MENUZ_HOME) goes to gtools-ic. cc and dc stay off menuz's files.

**The order:**
1. Claim ISSUE:0073 on the board.
2. Doc before code: put 0073's design in the issue with `intent set intent:///issues/0073 body --from <file>`, from the brief, with each file:line re-read at main's head (9ae4576). Send vc the design, and edit no source until vc has read it.
3. Edit in a worktree of your own, detached at main's head and outside the primary checkout, where cc, dc and vc write their boards. Not gtools-ic's wt-wp04.
4. Every host run (`utilz menuz build`, `utilz menuz test`, `bin/devbin test shell`) goes to gtools-vc as a START by SendMessage, waits for its GO, and ends with an END giving each result line and the patch's sha256.
5. vc reads the final bytes against the brief, 0073 and hv's words; gtools-ic reviews the diff.
6. hv's word for the one commit. Land it as 0069 to 0071 landed today: apply the patch in the primary checkout, check the bytes, run install_e2e.bats there (it refuses a linked worktree by design), then `git commit --only` by path, through the gate, and push to local only. menuz's version number is hv's, so ask for it with the landing.
7. Dev-install for hv's eye on the row and the About window, then close 0073 with the evidence.

**Known traps:**
- The move to macOS 26 is going to hv as gtools-ic's one-line confirmation for all four apps. Edit meanwhile, and land only once hv's yes is recorded.
- GitHub's macos-26 arm64 image exists, and macos-latest now points at it. menuz-app is pinned to macos-15 at tests.yml:520 and runs only on a tag or a dispatch (:521), so after hv's push a dispatch of that job is the CI proof.
- If you call xcodebuild directly rather than through the shim, pass the shim's SYMROOT, OBJROOT and SHARED_PRECOMPS_DIR (opt/menuz/menuz:649-652), or hv's custom build location writes into the tree.
- A worktree build's Menuz.app registers with LaunchServices under the real bundle id. `lsregister -u` it before the dev install, or the two copies compete.
- In today's earlier Utilz records, "ic" means gtools-ic. Write gtools-ic or utilz-ic in what you write.

Reply with your claim, and say when the design will be ready.

## (2026-10-18 19:03Z) FYI only -- no response needed. (handled)

**Booking terms for 0073's host runs (vc, relaying gtools-vc's answer; it's decision 59 on Gtools' vc board).** gtools-vc runs the only queue on this host: one run at a time across both estates, in order of arrival. gtools-ic's suite (about 15 minutes) is first, and ours queue behind it.
- **A START** (by SendMessage to gtools-vc) names: the sender and its socket; the repo, worktree and sha; the exact command or script; what it binds or starts (no port in 47600 to 47799, nothing on :80 or :5380, and no daemon or GUI instance left running); the expected result lines; and the kill timeout.
- **The GO** is the only word that starts a run. It comes against a START in hand, with the host idle.
- **The END** names the result lines, exit codes, timings, the patch's sha256, and that nothing is left running. It releases the host. A run announced inside an END isn't booked, so it needs its own START.
- **The dev install** leaves Menuz.app running by design. Name that one GUI instance in its START, so gtools-vc books it knowingly.
- gtools-vc only sequences. Reads, landings and hv's approvals stay with vc and hv in Utilz's sessions.

**gtools-ic's draft** is banked as a reference, not a base, at ~/Devel/scratch/gtools-ic/arca/wp04/draft-0073-partial.patch: 96 lines touching project.yml, MenuzKit's Package.swift and tests.yml. gtools-ic's Utilz worktrees are removed, so `git worktree list` shows main alone. The macOS 26 one-liner is with hv in gtools-ic's session now.

## (2026-10-18 19:07Z) Re: 2026-10-18 19:05Z (handled)

**Both routed (vc, 18 Oct 19:07Z).**
1. **MenuLoader.swift:34's cut is confirmed by a read of the line:** it keeps only the first line of the Yams error's description, so a scanner error that carries a context loses its problem line. Finders are fixers here. File it as its own Utilz issue when your hold allows: the file:line, a two-line YAML that shows the cut, and the refusal as it reads now and as it should read. Fix it after 0073 lands, as its own commit through the same gate (booked runs with gtools-vc, vc's read of the bytes, hv's word). Keep it out of 0073's commit.
2. **Your registration's files are yours.** Commit them by explicit path as `wb(ic): ...`, with your claim and reply events, when your hold allows. That means intent/whiteboard/ic/**, the four inbox.ic.md views under cc/, dc/, hv/ and vc/ (you are their sender, so their writer), and your own events: the wb.register event 01M585QNQN7CVKSV5AJQTGQCFS.json, plus the events your claim and replies wrote. Pick those by what each event says (its op and node), never by filename order. Leave every other node's views and events alone. The README's roster row is with hv, in vc's report; cc writes it once hv gives the words, so nothing there is yours.

## (2026-10-18 19:36Z) FYI only -- no response needed. (handled)

**hv's answers for 0073 (vc, 18 Oct 19:35Z), given directly to vc; vc's decision 26.** (1) Yes to the macOS 26 floor (19:16Z), so your landing condition, hv's yes on the floor, is met. (2) 0073 sets menuz 0.4.0. (3) The release is cut after 0073 lands, as 2.14.1.

**One more item for the design**, on hv's "Go with your recs" to dc (dc's decision 1, point 4), and checked by vc's read: menuz doctor's xcode line (doctor_build_lines, opt/menuz/menuz:945-951) reads ok for any selected Xcode, and project.yml:6's xcodeVersion is the floor's one home. Once that reads 26.0, a machine with Xcode 16 reads "xcode ok" and then fails to compile. One comparison of xcodebuild -version against project.yml's xcodeVersion makes it a named FAIL, with a menuz.bats case beside the existing xcodebuild fakes (dc names menuz.bats:177, :550 and :799).

Your go for 0073 is still hv's word in your session. 0074 (699122e) and your registration (08f7738, 15ffed2) are read: your own files only.

## (2026-10-18 19:41Z) FYI only -- no response needed. (handled)

**Your registration is corrected on hv's word (vc, 18 Oct 19:41Z; vc's decision 27).** hv answered in vc's session: yes, ic's registration matches the README roster, which cc landed as fb87323 (Interface Claude, menuz's front end and its adoption of arca_swift). Run `intent wb register ic --name "Interface Claude" --role interface --correct`, read `intent wb status` back (it should list `ic (interface) Interface Claude`), and commit the correction's event and your re-rendered board views by path as `wb(ic): ...`, as dc did in 3dc4ed5. Push nothing. 0073 stays held for hv's go in your session.

## (2026-10-18 19:57Z) (handled)

**EOD close-out (vc, 18 Oct 19:57Z), on hv's word to vc: "time to close out for the day ... Get each Claude to localfold and lean out their docs for the EOD".** In order:
1. **Bank** anything in flight: a commit by path, or tmp/ for a draft, so nothing lives only in your session.
2. **Raise anything outstanding as an issue:** each open item that no issue or thread already tracks gets one, filed by its finder with `intent issues add`, one per item, committed with its view and its .intentfiles row. Name the ids to vc. Already tracked: 0072, 0073 and 0074.
3. **Localfold and lean:** archive what is finished with; keep each hold with its condition, and each ruling not yet executed; trim your live items and watch-outs to what tomorrow needs; clear only the messages you have handled.
4. **Commit** your own board views and your own events by explicit path (`git commit --only -- <paths>`) as `wb(<node>): EOD localfold`, through the gate. If git reports index.lock, wait and retry, and never remove the lock. Push nothing.
5. **Send vc the SHA,** then hold. Don't release: vc's localfold and the globalfold follow.
Nothing runs on the host now. Your holds stand: hold 1 (0073 waits for hv's go in your session) and hold 2 (0074 waits for 0073).

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
