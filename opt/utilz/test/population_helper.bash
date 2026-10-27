#!/usr/bin/env bash
# population_helper.bash - the tree's utilities, for the suites that sweep them
#
# ONE HOME FOR THE SET THE SUITES SWEEP (issue 0117). help_dispatch.bats and
# version_dispatch.bats each defined their own _utilities and checked every
# sweep against a written count of the tree's utilities, so a new utility
# turned their rows red until the number was edited. A sweep is checked
# against the same set read another way instead: the links in the bin dir
# that point at the dispatcher. A narrowed glob still fails loudly, and a new
# utility needs no edit here. Every suite that sweeps the tree's utilities
# loads it.
#
# Usage, after test_helper.bash, whose UTILZ_HOME, UTILZ_BIN_DIR and fail it
# reads:
#   load "test_helper.bash"
#   load "population_helper.bash"

# Every utility the tree carries: each opt/<name>/ holding its <name>.yaml,
# utilz itself aside.
_utilities() {
  local d u
  for d in "$UTILZ_HOME"/opt/*/; do
    u=$(basename "$d")
    [ "$u" = "utilz" ] && continue
    [ -f "$d/$u.yaml" ] || continue
    echo "$u"
  done
}

# The same set read from the bin dir: each link there that points at utilz.
_utility_links() {
  local l
  for l in "$UTILZ_BIN_DIR"/*; do
    [ -L "$l" ] || continue
    [ "$(readlink "$l")" = "utilz" ] || continue
    basename "$l"
  done
}

# Assert _utilities names exactly the bin dir's links to utilz, and that there
# is at least one; on a difference, name each name on either side.
assert_population_whole() {
  local swept linked only_swept only_linked
  swept=$(_utilities | LC_ALL=C sort)
  linked=$(_utility_links | LC_ALL=C sort)
  if [[ -z "$linked" ]]; then
    fail "no link in $UTILZ_BIN_DIR points at utilz -- the reader is wrong, not the tree"
  fi
  if [[ "$swept" != "$linked" ]]; then
    only_swept=$(LC_ALL=C comm -23 <(printf '%s\n' "$swept") <(printf '%s\n' "$linked") | tr '\n' ' ')
    only_linked=$(LC_ALL=C comm -13 <(printf '%s\n' "$swept") <(printf '%s\n' "$linked") | tr '\n' ' ')
    fail "swept but not linked: ${only_swept:-none}; linked but not swept: ${only_linked:-none} -- the glob is wrong, not the tree"
  fi
}

# Assert a row that swept _utilities reached every utility the bin dir links.
# Usage: assert_swept_all "$n"
assert_swept_all() {
  local want
  want=$(_utility_links | grep -c . || true)
  if [[ "$1" -ne "$want" ]]; then
    fail "checked $1, expected $want, the links to utilz in $UTILZ_BIN_DIR -- the glob is wrong, not the tree"
  fi
}
