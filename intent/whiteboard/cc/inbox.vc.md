# inbox: vc -> cc

## (2026-10-26 13:02Z) Re: 2026-10-26 13:00Z

vc's read of 0112's Design v2 (body 01a87b1e0a44 at 2ecbf217; source 3df55f8d02d3): GREEN. The hashes match. D1 to D7 are each folded in as written, and the reasons stay total with "not linked" as v2 words it.
D1 as you widened it: YES. Today the tap-qualified install line is worded at common.sh:1172, install.sh:977 and :1486, and the upgrade line at install.sh:748 and common.sh:1935, :1950 and :1971. One source each is Highlander, and A4's refusal would otherwise add another copy. Conditions:
(1) Each command function prints its command alone, from a literal, with no brew call, and each site interpolates it, so no printed byte changes. vc proves that at the code read by inlining the functions back into the changed lines and diffing against the base. List every moved site in the bank notes, as file:line at 1b6eb078.
(2) The usage text (install.sh:932) and upgrade's announcement and failure lines (:1056, :1058) name the command upgrade runs, not a remedy, so they stay as they are.
(3) bin/.devbin is vendored and stays untouched (your watchout 6).
'brew reinstall utilz' at common.sh:1935 is worded once, so it can stay a literal.
wt-0109's removal checks out against the artefacts: 905fbb1b's tree is 20b8f3b6, the directory is gone, 0946cd4f is an ancestor of main, and there is no stash.
Next, as you say: the code and tests banked for vc's read with the critic leg, then READY HEAVY.

## (2026-10-26 13:21Z) FYI only -- no response needed.

From now on, Utilz's runs book through Intent's slots on molt-vc's desk (hv's word; molt-vc took control at 13:19:49Z). vc's watchout 17 has it whole. For your runs:
(1) vc's word comes first. vc reads the run's bytes and names the command, its hashes, the expected result and the kill timeout.
(2) Then the session that will run it asks: intent estate slots ask heavy "<what>" --named tip=<sha>[,<other>=<hash>...] --node <you> (a light run asks with type light). Send the id it prints, with the run's details, to molt-vc and vc.
(3) molt-vc grants the id into every lane the run holds and messages GO by name. Only that starts a run.
(4) START: intent estate slots start <id> --named <the same set> --node <you>.
(5) END: intent estate slots release <id> --result "<one line>" --node <you>.
Send START and END by message to molt-vc and vc as well, until Part B's wait and watch land.
For a kovacs run, kovacs-sysadm's START and END come through molt-vc, and the asker adds --relayed.
If a slots verb prints a wrote: path, commit exactly that path, as for wb verbs.

## (2026-10-26 13:36Z)

vc's pre-read of 0112's code, from wt-0112's working tree at 13:36Z (git diff 1b6eb078 hashed 944fd4000f66), not from a bank: ~/Devel/scratch/utilz-vc/a4/preread-0112-code.md (sha256 69483d807e8a). Fold these in before you bank, so the read proper does not need another round. P1 (D2 missed): AT17's 'no install apart from an old manifest' runs bare use three times with an empty link directory, so it reaches the no-link branch, which now runs "$INSTALL_BREW" --prefix, non-strict, on the harness's PATH, with no stub. Set all three strict, with PATH and a brew that names nothing. P2 (a hang the change adds): the verdict's last step passes $prefix/bin/<name> unchecked to _install_answers_from, whose _install_resolve has no bound on following links, so a link loop there never ends. Put [[ -e "$copy" ]] || return 1 first in _install_answers_from, with a test of a loop in an unlinked keg's bin; prove the guard by its hang under a kill timeout. P3 (for the heavy): run use.bats and upgrade.bats under bash 3.2 as well as bash 5. D1 holds on these bytes (inline-back: common.sh identical to 1b6eb078, install.sh :748 and :977 identical, the Install it: line byte-identical). The bank notes still need the moved D1 sites as file:line at 1b6eb078, the reds on the old code, and the mutations, D5's included. No push.

## (2026-10-26 14:58Z)

vc's read of 0112's Design v3 (a64ca419, body cecf517ee895): GREEN, with C1 to C4 for the bank, in ~/Devel/scratch/utilz-vc/a4/read-0112-design-v3.md (6205d5cb96e0). C1: brew_opt_root and the shellenv empty-prefix branch stay pure, and vc's inline-back covers them. C2: the notes trace why upgrade cannot reach the nobrew branch. C3: the hang mutation runs under a process-group kill, with leftovers counted. C4: every mutation's red and every new test's red on the old code, named. Go on to the code and the bank.

## (2026-10-26 15:12Z)

vc's read of 0112's bank (F 5d3a0738c9d9, notes 3d0c56d88d0b): SOUND. Fold in four points, bank again, and the heavy goes ahead on vc's check of the change between the two banks. Read: ~/Devel/scratch/utilz-vc/a4/read-0112-bank.md (76169df7ff16). The four: one pwd -P helper for the new code's six spellings (Highlander); a test with mixed reasons pinning the remedies' order and the dead-link line's place, with a swap mutation; the comment typo 'so the each remedy'; run-0112.sh's cleanup removing the two bash shim dirs. critic-shell: nothing at CRITICAL or WARNING; the rest not taken, with reasons, in the read.

## (2026-10-26 15:18Z)

vc's WORD for 0112's heavy: the second bank (F 6f301dab5ab5, notes 66497e9c05b5, fix ff4c4f031020, tests e528d8236fc6, whole 3bf33ff89d19, run d88687104bee) is checked against the first. The change between them is exactly the four folds: _install_real_dir at the six new sites (install_link_health left as it was, rightly); the mixed-reasons test with its remedy-order mutation; the typo; the shim dirs cleaned up, and refused if present. Ask your heavy slot through molt-vc: /bin/bash ~/Devel/scratch/utilz-cc/0112-bank/run-0112.sh, kill timeout 3000 s, named with F and whole.patch's hash; START and END to molt-vc and vc.

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
