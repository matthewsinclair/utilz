#!/usr/bin/env bash
# Hoist adaptation: turn a freshly archived geopres crate into Utilz's prez.
#
# Run against a tree produced by:
#   git -C <upstream-estate> archive <PIN> native/rust/geopres \
#     | tar -x --strip-components=3 -C opt/prez/crate
#
# Idempotent and deterministic, so a moving pin costs a re-run rather than a
# re-remembering. Every change here is a Utilz-side adaptation; nothing is a
# fix to the tool, which is why none of it belongs upstream in _tools.
#
# Usage: hoist-adapt.sh <crate-dir>
set -euo pipefail

CRATE="${1:?usage: hoist-adapt.sh <crate-dir>}"
[ -f "$CRATE/Cargo.toml" ] || { echo "not a crate: $CRATE" >&2; exit 1; }

# ---------------------------------------------------------------- 1. rename
# ATOMIC, across every file at once. Three sets must move together or the
# suite goes red on the rename itself:
#   - theme.rs's SEARCH_PATH const + its refusal string + the AT asserting it
#   - acceptance.sh's SENTINEL + the same literal as notes payload in demo.md
#   - the binary name in acceptance.sh, at04 and at12 probes
# Doing the whole tree in one pass keeps them coordinated by construction.
# Both counts brace-guard the grep. grep exits 1 when it matches NOTHING, and
# under `set -euo pipefail` that propagates and kills the script -- so the
# SUCCESS condition (zero remaining occurrences) is what would abort the run,
# silently, after the rename had already been written to disk. Caught by
# diffing this script's output against the hand-edited tree it was meant to
# reproduce: steps 2 and 3 had never run and nothing said so.
before=$( { grep -rniI 'geopres' "$CRATE" || true; } | wc -l | tr -d ' ')
# Same guard on the file list, for the same reason one step further on: an
# ALREADY-ADAPTED tree matches nothing here, so the second run died where the
# first succeeded. Idempotency is not decoration for this script -- a moving
# pin means it runs again, possibly over a tree someone has partly fixed.
while IFS= read -r f; do
  [ -n "$f" ] || continue
  sed -i '' -e 's/GEOPRES/PREZ/g' -e 's/geopres/prez/g' "$f"
done < <(grep -rlI 'geopres\|GEOPRES' "$CRATE" || true)
after=$( { grep -rniI 'geopres' "$CRATE" || true; } | wc -l | tr -d ' ')
echo "rename: $before occurrence(s) -> $after"
[ "$after" -eq 0 ] || { echo "rename incomplete" >&2; exit 1; }

# ------------------------------------------------------- 2. target dir default
# _tools redirects CARGO_TARGET_DIR out of a Dropbox-synced checkout. Utilz is
# a plain local checkout, so the default in-crate target/ is correct here and
# .gitignore's opt/*/crate/target/ is the whole fence. The env var still wins,
# which is what lets CI or a cold run redirect without editing the file.
python3 - "$CRATE/test/acceptance.sh" <<'PY'
import sys, re
p = sys.argv[1]
s = open(p).read()
old = 'TARGET="${CARGO_TARGET_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/geodica/cargo-target}"'
new = ('# The DEFAULT in-crate target/, not a redirect. Upstream redirected it out of\n'
       '# the tree because that checkout lives in a cloud-synced folder that must not\n'
       '# carry build output. Utilz is a plain local checkout, so\n'
       '# the default is correct here and .gitignore\'s opt/*/crate/target/ is the whole\n'
       '# fence. CARGO_TARGET_DIR still wins if a caller sets it, which is what lets CI\n'
       '# or a cold-build run point somewhere else without editing this file.\n'
       'TARGET="${CARGO_TARGET_DIR:-$CRATE/target}"')
if old not in s:
    if 'TARGET="${CARGO_TARGET_DIR:-$CRATE/target}"' in s:
        sys.exit(0)          # already applied
    sys.exit("TARGET line not found and not already adapted")
open(p, 'w').write(s.replace(old, new))
PY
echo "target: default is now the in-crate target/"

# ------------------------------------------------------------------- 3. AT01
# AT01 proved _tools' AC01 -- devbin's CARGO_TARGET_DIR redirect, holding cold.
# That AC stays behind: Utilz has no redirect, so as written the step measures
# a mechanism this repo deliberately does not have. The INTENT survives -- a
# build must not leave litter anyone has to notice -- so the subject changes
# and the step stays. Rewritten rather than dropped, because "we do not need
# that check here" is how a hoist quietly loses one.
#
# Also fixes a portability bug that is independent of the rewrite: the size
# check used `stat -f %z`, which is BSD-only, so on Linux it returns nothing,
# the size reads 0 and the 8MB ceiling FAILS ON A CORRECT BUILD. A check that
# reads plausibly and measures "stat succeeded" rather than "the binary is
# small enough" -- and one that can only fail on the platform nobody develops on.
python3 - "$CRATE/test/acceptance.sh" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
start = s.find('if want AT01; then')
if start == -1:
    sys.exit("AT01 block not found")
end = s.find('# ---', start)
if end == -1:
    sys.exit("AT01 block terminator not found")
if 'in-crate target dir' in s[start:end]:
    sys.exit(0)              # already applied
new = '''if want AT01; then
  start AT01 "build hygiene: the build lands in-crate and leaves no litter in git"
  # REWRITTEN ON THE HOIST, and the AC underneath it changed rather than the
  # test drifting. In _tools this proved AC01 -- that `bin/devbin build`
  # redirected CARGO_TARGET_DIR out of a Dropbox-synced tree, and that the
  # redirect held COLD as well as warm. That AC stays behind: Utilz is a plain
  # local checkout, there is no redirect to hold, and a test asserting one
  # would be measuring a mechanism this repo deliberately does not have.
  #
  # The INTENT survives -- a build must not leave litter someone has to notice
  # -- so the same step now proves the Utilz mechanism: the default in-crate
  # target/ is where the binary goes, and .gitignore fences it. Kept as a test
  # rather than dropped, because "we do not need that check here" is how a
  # hoist quietly loses one.
  if cargo build --release --manifest-path "$CRATE/Cargo.toml" >"$WORK/at01.log" 2>&1; then
    ok "release build succeeded"
  else
    bad "release build failed"; sed 's/^/        /' "$WORK/at01.log" | tail -5
  fi

  [ -x "$CRATE/target/release/prez" ] \\
    && ok "binary landed in the in-crate target dir" \\
    || bad "binary is not at $CRATE/target/release/prez"

  # THE FENCE IS THE POINT. A few hundred MB of target/ showing up as
  # untracked is the failure this replaces the redirect with, so assert git
  # cannot see it rather than asserting the directory is absent -- it is
  # supposed to be present, just invisible.
  untracked="$(cd "$REPO" && git status --porcelain --untracked-files=all -- opt/prez/ | grep -c 'target/' || true)"
  check "build litter visible to git under opt/prez/" "$untracked" "0"

  size=$(stat -f %z "$CRATE/target/release/prez" 2>/dev/null || stat -c %s "$CRATE/target/release/prez" 2>/dev/null || echo 0)
  if [ "$size" -gt 0 ] && [ "$size" -le 8388608 ]; then ok "binary $((size / 1048576)) MB <= 8 MB ceiling"
  else bad "binary is $size bytes against an 8 MB ceiling"; fi
  finish
fi

cargo build --release --manifest-path "$CRATE/Cargo.toml" >/dev/null 2>&1

'''
open(p, 'w').write(s[:start] + new + s[end:])
PY
echo "AT01: rewritten for the Utilz build mechanism"

# --------------------------------------------------------------- 4. version
# 1.0.0 on arrival, matching every other utility's arrival convention here.
# _tools carried 0.1.0 because the crate was pre-release inside that estate;
# landing in Utilz is the release. Cargo.toml is the single source --
# CARGO_PKG_VERSION drives `prez --version` from inside the binary -- and
# prez.yaml mirrors it for the dispatcher's own metadata path.
python3 - "$CRATE/Cargo.toml" <<'PY'
import sys, re
p = sys.argv[1]
s = open(p).read()
s2 = re.sub(r'(?m)^version = "0\.1\.0"$', 'version = "1.0.0"', s, count=1)
if s2 != s:
    open(p, 'w').write(s2)
PY
# Cargo.lock records the package version too; let cargo reconcile it rather
# than hand-editing a generated file.
if command -v cargo >/dev/null 2>&1; then
  cargo update --workspace --manifest-path "$CRATE/Cargo.toml" --offline >/dev/null 2>&1 || true
fi
echo "version: $(grep -m1 '^version' "$CRATE/Cargo.toml")"

# ------------------------------------------------- 6. AC-id re-stamp (vc's)
# THE SUITE'S OWN CITATIONS USE UPSTREAM'S AC NUMBERING, and this repo
# renumbered. Ten block headers and two body lines named a criterion that means
# something else here. Nothing failed; the label was just wrong, which is the
# kind of wrong nobody re-reads. Delivered 2026-08-29 after checking every
# citation against `intent at list ST0010` rather than inferring the offset.
#
# THIS IS NOT AN ID->ID MAP, and that is a correction to the earlier design
# rather than a preference. Two reasons a global map cannot be right for this
# file:
#
#   1. THE FILE MIXES BOTH NUMBERING SYSTEMS. AT13 -- AC14 and AT17 -- AC04 are
#      already correct in OUR numbering, as are the comment citations of AC09,
#      AC14, AC18 and AC19, because those blocks and clauses were written here.
#      A global AC04->AC03 would silently corrupt AT17's header while fixing
#      line 301. The two AC04s in this file mean different criteria.
#   2. THE MAP CHAINS. AC02->AC01, AC03->AC02, AC04->AC03, AC05->AC04 and so on
#      make almost every id both a source and a target, so the earlier guard --
#      correctly -- refuses the whole map.
#
# Context-anchored pairs solve both. The AT prefix disambiguates which AC04 is
# meant, so no pair's replacement matches any other pair's target, and a second
# run finds none of the old strings and is inert.
python3 - "$CRATE/test/acceptance.sh" <<'ACMAP'
import sys

PAIRS = [
    ("AT01 -- AC01", "AT01 -- AC11"),
    ("AT02 -- AC02", "AT02 -- AC01"),
    ("AT03 -- AC03/04", "AT03 -- AC02/03"),
    ("AT04 -- AC05", "AT04 -- AC04"),
    ("AT05 -- AC06", "AT05 -- AC05"),
    ("AT06 -- AC07", "AT06 -- AC06"),
    ("AT07 -- AC08", "AT07 -- AC07"),
    ("AT08 -- AC09", "AT08 -- AC08"),
    ("AT12 -- AC13", "AT12 -- AC10"),
    ("AT09 -- AC10", "AT09 -- AC09"),
    ("# The other half of AC02: the named jobs", "# The other half of AC01: the named jobs"),
    ("# AC04. The SENTINEL", "# AC03. The SENTINEL"),
    ('absent "AC04 sentinel is nowhere in the HTML"', 'absent "AC03 sentinel is nowhere in the HTML"'),
]

# A target that is also somebody's source would make order matter. Asserted
# rather than assumed, because the whole reason this is not an id map is that
# the naive form chained.
srcs = {o for o, _ in PAIRS}
clash = srcs & {n for _, n in PAIRS}
if clash:
    raise SystemExit("a replacement is also a pattern (%s); order would matter" % sorted(clash))

path = sys.argv[1]
s = open(path).read()
done = skipped = 0
for old, repl in PAIRS:
    n = s.count(old)
    if n == 1:
        s = s.replace(old, repl); done += 1
    elif n == 0:
        skipped += 1          # already stamped, or upstream reworded the line
    else:
        raise SystemExit("pattern is ambiguous (%d hits): %s" % (n, old))
open(path, "w").write(s)
print("AC-id re-stamp: %d rewritten, %d already correct or absent" % (done, skipped))
if skipped and not done:
    print("  (all pairs inert -- either already stamped, or upstream has reworded them:")
    print("   re-derive against `intent at list ST0010` before trusting this step again)")
ACMAP

# ---------------------------------------------------------------- 5. format
# The rename shortens table cells by three characters wherever `geopres`
# appeared, leaving the example decks' markdown tables ragged -- and this
# project requires column-aligned tables. Utilz's pre-commit hook runs
# prettier over staged .md and adds the result back, so those two files get
# reformatted whether or not this script does it.
#
# Doing it HERE is what keeps the AC17 provenance claim honest. The claim is
# "tree at <sha>, plus adaptations at <commit>", and it only holds if running
# this script over a fresh archive reproduces the committed tree exactly. Left
# to the hook, prettier is a third writer nobody named, and the reproduction
# diverges on two files for reasons no artifact records. Measured, not
# guessed: the first commit of this crate came back with both decks reflowed.
if command -v prettier >/dev/null 2>&1; then
  prettier --write "$CRATE"/examples/*.md >/dev/null 2>&1 || true
  echo "format: example decks aligned (matching the pre-commit hook's own pass)"
else
  echo "format: prettier absent, skipped -- the pre-commit hook will do it instead"
fi

echo "adaptation complete: $CRATE"
