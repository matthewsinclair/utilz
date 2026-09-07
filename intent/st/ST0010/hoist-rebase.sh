#!/usr/bin/env bash
# Move opt/prez/crate to a new _tools pin WITHOUT discarding Utilz's own work.
#
# WHY THIS EXISTS, AND WHY hoist-adapt.sh IS NOT ENOUGH.
#
# The first hoist could re-archive over the top, because the crate was a pure
# mirror of the pin plus a set of mechanical adaptations that hoist-adapt.sh
# replays. That stopped being true at 8a53457: AC14 (announce-on-resolve) is
# net-new Utilz behaviour in src/theme.rs and src/deck.rs, AT13 proves it in
# test/acceptance.sh, and the AC18(b) override hook lives in the same file.
# `tar -x` over the top would silently drop all three -- the build would still
# be green, the tests would still pass, and nothing would say the behaviour had
# gone, because the tests that prove it would have gone with it.
#
# Nor do those changes belong in hoist-adapt.sh. That script's job is the
# MECHANICAL translation of a foreign tree into this one -- rename, target dir,
# the AT01 rewrite, the version, the formatter pass -- all of which are derived
# from the archive and must be replayed on every new one. AC14 is not derived
# from anything; it is Utilz's own source, and its home is git history. Putting
# it in a replay script would be two copies of the same change: the file, and
# the script that regenerates the file.
#
# So the pin moves as a REBASE rather than a replacement. Archive both pins,
# run hoist-adapt.sh over both so they are in Utilz's namespace, diff them to
# get exactly what _tools changed, and apply that delta to our tree. Upstream's
# work arrives, ours survives, and a conflict is reported rather than resolved
# by whoever wrote last.
#
# AC17 provenance still holds and is still one sentence:
#   tree at <OLD_PIN> + hoist-adapt.sh, plus Utilz commits <A>..<B>,
#   plus the upstream delta <OLD_PIN>..<NEW_PIN> applied at <C>
# Every term is nameable and every step is re-runnable.
#
# Usage: hoist-rebase.sh <old-pin> <new-pin> [--dry-run]
set -euo pipefail

TOOLS="${TOOLS_REPO:-$HOME/Dropbox/Geodica/_tools}"
SUBDIR="native/rust/geopres"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADAPT="${HOIST_ADAPT:-$HERE/hoist-adapt.sh}"

OLD="${1:?usage: hoist-rebase.sh <old-pin> <new-pin> [--dry-run]}"
NEW="${2:?usage: hoist-rebase.sh <old-pin> <new-pin> [--dry-run]}"
DRY=0
[ "${3:-}" = "--dry-run" ] && DRY=1

REPO="$(git rev-parse --show-toplevel)"
CRATE="$REPO/opt/prez/crate"

[ -d "$TOOLS/.git" ] || { echo "no _tools repo at $TOOLS" >&2; exit 1; }
[ -x "$ADAPT" ]      || { echo "hoist-adapt.sh not executable at $ADAPT" >&2; exit 1; }
[ -d "$CRATE" ]      || { echo "no crate at $CRATE" >&2; exit 1; }

# A dirty crate would make the delta ambiguous: git apply reports a conflict
# against uncommitted work as though it were an upstream disagreement.
if [ -n "$(git -C "$REPO" status --porcelain -- opt/prez/crate)" ]; then
  echo "opt/prez/crate has uncommitted changes -- commit or stash first" >&2
  exit 1
fi

WORK="$(mktemp -d "${TMPDIR:-/tmp}/prez-rebase.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

# ------------------------------------------------- 1. both pins, both adapted
# ADAPTED BEFORE DIFFING, not after. The rename alone touches 110 occurrences
# across 19 files; diffing raw archives would produce a delta that is almost
# entirely `geopres` -> `prez` noise and would not apply to our tree at all.
# Adapting both sides first means the delta contains exactly what _tools
# changed and nothing about the hoist.
for pin_dir in "old:$OLD" "new:$NEW"; do
  label="${pin_dir%%:*}"; pin="${pin_dir#*:}"
  mkdir -p "$WORK/$label"
  git -C "$TOOLS" archive "$pin" "$SUBDIR" | tar -x --strip-components=3 -C "$WORK/$label"
  "$ADAPT" "$WORK/$label" >/dev/null
  echo "$label: $pin adapted ($(find "$WORK/$label" -type f | wc -l | tr -d ' ') files)"
done

# ------------------------------- 2. a real three-way merge, file by file
# `git merge-file ours base theirs` -- the right primitive, and the reason this
# is not `git apply`. A `diff -ruN` patch carries no blob hashes, so git's
# --3way has nothing to do a three-way merge WITH and silently falls back to
# straight application: the first version of this script did exactly that, and
# a single conflicting hunk in chrome() made the whole patch a no-op, because
# git apply is atomic. Measured against a synthetic upstream change, not
# reasoned about.
#
# merge-file needs no repository, ships with every git, and writes ordinary
# conflict markers a person can resolve. The base is the OLD adapted pin, which
# is precisely the common ancestor both sides diverged from.
merged=0; copied=0; conflicted=0
CONFLICTS=()

while IFS= read -r rel; do
  ours="$CRATE/$rel"
  base="$WORK/old/$rel"
  theirs="$WORK/new/$rel"

  # Upstream deleted it. Never removed automatically: a file Utilz added under
  # the same name would be indistinguishable from one upstream dropped.
  if [ ! -f "$theirs" ]; then
    echo "  UPSTREAM DELETED (left in place, decide by hand): $rel"
    CONFLICTS+=("$rel (deleted upstream)")
    conflicted=$((conflicted + 1))
    continue
  fi

  # New upstream file, or one Utilz never had: take it whole.
  if [ ! -f "$ours" ]; then
    mkdir -p "$(dirname "$ours")"
    if [ "$DRY" -eq 0 ]; then cp "$theirs" "$ours"; fi
    echo "  new from upstream: $rel"
    copied=$((copied + 1))
    continue
  fi

  target="$ours"
  if [ "$DRY" -eq 1 ]; then
    target="$WORK/dry-$(echo "$rel" | tr / _)"
    cp "$ours" "$target"
  fi

  if git merge-file -L "utilz (ours)" -L "pin $OLD (base)" -L "pin $NEW (theirs)" \
       "$target" "$base" "$theirs" >/dev/null 2>&1; then
    echo "  merged clean: $rel"
    merged=$((merged + 1))
  else
    echo "  CONFLICT: $rel"
    CONFLICTS+=("$rel")
    conflicted=$((conflicted + 1))
  fi
done < <(cd "$WORK" && diff -rq old new 2>/dev/null \
           | sed -n -e 's/^Files old\/\(.*\) and new\/.* differ$/\1/p' \
                    -e 's/^Only in new\/*\(.*\): \(.*\)$/\1\/\2/p' \
                    -e 's/^Only in old\/*\(.*\): \(.*\)$/\1\/\2/p' \
           | sed 's|^/||' | sort -u)

echo ""
echo "merged $merged   new $copied   conflicted $conflicted"

if [ "$conflicted" -gt 0 ]; then
  echo ""
  echo "CONFLICTS ARE THE OUTCOME TO WANT over a silent overwrite: they are the"
  echo "two sides having changed the same lines, and only a person knows which"
  echo "is right. Each merged file now carries <<<<<<< markers naming ours,"
  echo "the base pin and theirs."
  for c in "${CONFLICTS[@]}"; do echo "  - $c"; done
  [ "$DRY" -eq 1 ] && echo "(dry run: nothing was written)"
  exit 1
fi


# ------------------------------------------ 3. THE POSTCONDITION (vc's ask)
# A CLEAN MERGE IS NOT EVIDENCE THAT ANYTHING SURVIVED, and that is the whole
# point of this step. "merged with no conflicts" would have been green for the
# `tar -x` too -- it deletes cleanly. A silent-deletion failure mode needs a
# check that goes red ON THE DELETION, so this asserts the Utilz-side behaviour
# is still in the file rather than inferring it from the absence of markers.
#
# Maintained by hand, deliberately. Deriving it (say, from `git diff` against
# the pin) would make it agree with whatever is there, which is what it exists
# to disagree with. A line is added here when Utilz adds crate-side behaviour;
# forgetting to is a gap, but a gap that leaves the older lines still checking.
#
# In DRY RUN this runs against the merged temp copies rather than the tree, so
# the dry run predicts the real outcome instead of re-reading the unmerged tree
# and passing for the wrong reason.
# Prefer the merged temp copy in a dry run, but FALL BACK TO THE REAL FILE when
# there is no temp copy: a file upstream did not touch has no merged version,
# and the real one IS the predicted outcome for it. Without the fallback a
# narrow delta -- which is the normal case -- made every untouched
# postcondition report UNCHECKABLE, so a correct dry run looked like seven
# failures. Caught by running it, on a no-op where nothing merges at all.
check_file() {
  local dry
  dry="$WORK/dry-$(echo "$1" | tr / _)"
  if [ "$DRY" -eq 1 ] && [ -f "$dry" ]; then
    printf '%s' "$dry"
  else
    printf '%s' "$CRATE/$1"
  fi
}

post_fail=0
post() {                       # post <file> <needle> <min-count> <what>
  local f n
  f="$(check_file "$1")"
  if [ ! -f "$f" ]; then
    echo "  POSTCONDITION UNCHECKABLE: $1 is not there at all ($4)" >&2
    post_fail=$((post_fail + 1))
    return
  fi
  n=$(grep -c -- "$2" "$f" 2>/dev/null || true)
  if [ "${n:-0}" -ge "$3" ]; then
    echo "  ok   $4 ($n)"
  else
    echo "  LOST $4 -- found $n of $2, wanted at least $3" >&2
    post_fail=$((post_fail + 1))
  fi
}

echo ""
echo "postcondition: Utilz's own crate-side work is still here"
post "test/acceptance.sh" "PREZ_TEST_BROWSER" 5  "AC18(b) browser override"
post "test/acceptance.sh" "if want AT13"       1  "AT13 block"
post "test/acceptance.sh" "AT13: PASS"         0  "AT13 (presence only)"
post "src/theme.rs"       "pub fn provenance"  1  "AC14 provenance()"
post "src/theme.rs"       "Origin::SearchPath" 2  "AC14 Origin enum"
post "src/deck.rs"        "theme::provenance"  1  "AC14 wired to the warning door"
post "test/acceptance.sh" "if want AT17"       1  "AT17 block"
post "test/runtime-logic-probe.mjs" "SPACE commits" 1 "the browserless runtime probe"
post "src/html.rs"        "open this slide"    1  "hv's index commit binding"
post "src/html.rs"        "gp-bar"             5  "hv's key bar"
post "src/html.rs"        "fn fill("           1  "single-pass placeholder fill"
post "src/html.rs"        "closeShortcut"      3  "AC20 view-time close shortcut"
post "src/drive.rs"       "presenting_argv"    2  "AC19 window geometry"
post "src/drive.rs"       "window_size"        2  "AC19 --window parser"
post "src/args.rs"        "cmd.window"         2  "AC19 --window flag"
post "test/runtime-logic-probe.mjs" "AT19"     1  "AT19 platform branches"
post "src/drive.rs"       "Stdio::null"        3  "the browser's chatter stays off the terminal"
post "src/deck.rs"        "presenting {name}"  2  "presenting names the deck, not a scratch path"

# AT13's checks counted individually: the block surviving as a stub would pass
# a presence test while proving nothing.
at13=$(sed -n '/^if want AT13/,/^fi$/p' "$(check_file test/acceptance.sh)" \
        | grep -c -E '^\s+(present|absent|check) ' || true)
if [ "${at13:-0}" -ge 8 ]; then
  echo "  ok   AT13 still carries its checks ($at13)"
else
  echo "  LOST AT13's checks -- found ${at13:-0}, wanted 8" >&2
  post_fail=$((post_fail + 1))
fi

if [ "$post_fail" -gt 0 ]; then
  echo "" >&2
  echo "$post_fail POSTCONDITION(S) FAILED. The merge reported success and lost work anyway," >&2
  echo "which is the exact failure this step exists to catch. Do not commit; re-run" >&2
  echo "with --dry-run and read what merge-file did." >&2
  exit 1
fi

if [ "$DRY" -eq 1 ]; then
  echo "DRY RUN: everything merges clean and every postcondition holds. Nothing was written."
  exit 0
fi

echo ""
echo "Now: cargo test, PREZ_TEST_BROWSER=/nonexistent test/acceptance.sh --strict,"
echo "and record the new pin plus this rebase in impl.md (AC17)."
