#!/usr/bin/env bats
# version_dispatch.bats -- ST0015. One home for --version, and both versions reported.
#
# The defect this suite exists for: `--version` was intercepted at the SYMLINK
# dispatch site only, so thirteen utilities hand-copied an arm to cover the
# `utilz <util>` form. The two that never copied it were the two that broke.
# Every row here therefore runs BOTH invocation forms -- a test exercising one
# form cannot see a disagreement between them, and the disagreement WAS the bug.

load "test_helper.bash"

SEMVER='[0-9]+\.[0-9]+\.[0-9]+'

# The population, computed ONCE and shared by every row that sweeps it. A
# per-row glob is a per-row chance to narrow silently; the count control below
# is what makes a green mean "all of them" rather than "all of the ones I saw".
_utilities() {
  local d u
  for d in "$UTILZ_HOME"/opt/*/; do
    u=$(basename "$d")
    [ "$u" = "utilz" ] && continue
    [ -f "$d/$u.yaml" ] || continue
    echo "$u"
  done
}

_expected_count=15

@test "AT01 / AC03: the population is the whole set, and a narrowed sweep fails loudly" {
  local n
  n=$(_utilities | wc -l | tr -d ' ')
  [ "$n" -eq "$_expected_count" ] || fail "swept $n utilities, expected $_expected_count -- the glob is wrong, not the tree"
}

@test "AT02 / AC01: every utility reports the pair FORM, anchored, not a substring" {
  local u line bad=0 n=0
  for u in $(_utilities); do
    n=$((n + 1))
    line=$("$UTILZ_BIN_DIR/utilz" "$u" --version 2>&1 | head -1)
    # THE FORM is the requirement. A `contains` check cannot see a malformed
    # pair that happens to hold the right characters -- the ST0013 lesson.
    [[ "$line" =~ ^utilz:${SEMVER}/${u}:${SEMVER}$ ]] || {
      echo "  $u -> $line"
      bad=$((bad + 1))
    }
  done
  [ "$n" -eq "$_expected_count" ] || fail "checked $n, expected $_expected_count"
  [ "$bad" -eq 0 ] || fail "$bad utilities do not report the pair form"
}

@test "AT03 / AC01: the framework half is the BYTES of ./VERSION, not merely version-shaped" {
  local fw u line n=0
  fw=$(cat "$UTILZ_HOME/VERSION")
  [ -n "$fw" ] || fail "./VERSION is empty"
  for u in $(_utilities); do
    n=$((n + 1))
    line=$("$UTILZ_BIN_DIR/utilz" "$u" --version 2>&1 | head -1)
    [[ "$line" == "utilz:$fw/"* ]] || fail "$u reports '$line', which does not open with the framework's own $fw"
  done
  [ "$n" -eq "$_expected_count" ] || fail "checked $n, expected $_expected_count"
}

@test "AT04 / AC02: both invocation forms are byte-identical, for every utility" {
  local u a b bad=0 n=0
  for u in $(_utilities); do
    n=$((n + 1))
    a=$("$UTILZ_BIN_DIR/$u" --version 2>&1)
    b=$("$UTILZ_BIN_DIR/utilz" "$u" --version 2>&1)
    [ "$a" = "$b" ] || {
      echo "  $u: symlink form and dispatcher form differ"
      bad=$((bad + 1))
    }
  done
  [ "$n" -eq "$_expected_count" ] || fail "checked $n, expected $_expected_count"
  [ "$bad" -eq 0 ] || fail "$bad utilities answer --version differently depending on how they were invoked"
}

@test "AT05 / AC04: todo and prez by name -- the two that could not inherit the convention" {
  # todo never carried the arm and errored outright; prez could not carry one
  # because clap answers before any shell runs. A population-wide row that
  # tolerated them would pass while exactly these two stayed broken.
  local u out
  for u in todo prez; do
    out=$("$UTILZ_BIN_DIR/utilz" "$u" --version 2>&1 | head -1)
    [[ "$out" =~ ^utilz:${SEMVER}/${u}:${SEMVER}$ ]] || fail "$u (dispatcher form) reports '$out'"
    out=$("$UTILZ_BIN_DIR/$u" --version 2>&1 | head -1)
    [[ "$out" =~ ^utilz:${SEMVER}/${u}:${SEMVER}$ ]] || fail "$u (symlink form) reports '$out'"
  done
}

@test "AT06 / AC05: no utility carries its own --version arm" {
  # Proved by DELETION rather than by inspection: fourteen arms across thirteen
  # files were removed and both forms still answer. "The dispatcher ALSO
  # handles it" passes every test that "the dispatcher handles it" passes, so
  # the absence is the claim.
  local u found=""
  for u in $(_utilities); do
    [ -f "$UTILZ_HOME/opt/$u/$u" ] || continue
    grep -qE '^[[:space:]]*--version\)' "$UTILZ_HOME/opt/$u/$u" && found="$found $u"
  done
  [ -z "$found" ] || fail "these utilities have re-grown a --version arm:$found"
}

@test "AT07 / AC06: prez's version keeps its one home, and no second one appears" {
  assert_file_not_exists "$UTILZ_HOME/opt/prez/VERSION"
  run grep -c '^version_file: crate/Cargo.toml' "$UTILZ_HOME/opt/prez/prez.yaml"
  assert_success
  run grep -c '^version:' "$UTILZ_HOME/opt/prez/prez.yaml"
  assert_output "0"
}

# AC07 generates a real utility into the shared tree, so its cleanup MUST NOT
# sit after an assertion. It did, once: an injected regression made the arm
# check fail, the `rm -rf` never ran, and the scratch utility leaked into
# opt/ -- where it poisoned every later population sweep (16, not 15) and the
# arm check itself. A fixture a test mutates is a flake generator; teardown
# runs whether the test passed, failed or exploded.
_AC07_NAME=""
teardown() {
  if [ -n "${_AC07_NAME:-}" ]; then
    rm -rf "$UTILZ_HOME/opt/$_AC07_NAME" "$UTILZ_HOME/help/$_AC07_NAME.md" "$UTILZ_BIN_DIR/$_AC07_NAME"
  fi
}

@test "AT08 / AC07: a NEWLY GENERATED utility answers on both forms, with no arm of its own" {
  # THE MINT. script.tmpl carried the arm, so `utilz generate` would have
  # re-seeded the duplication one utility at a time and this fix would have
  # decayed from the next utility onward. The row pins REGENERATION, not the
  # template's current text: a template can be correct today and wrong at its
  # next edit, and an inspection-based row goes green straight through that.
  local name="zzgen$$"
  _AC07_NAME="$name"   # hand it to teardown BEFORE anything can fail
  run "$UTILZ_BIN_DIR/utilz" generate "$name" "Scratch utility for AC07" "test"
  assert_success

  local a b
  a=$("$UTILZ_BIN_DIR/$name" --version 2>&1 | head -1)
  b=$("$UTILZ_BIN_DIR/utilz" "$name" --version 2>&1 | head -1)

  # `--` keeps a `-`-leading pattern a PATTERN. Without it grep parses
  # `--version)` as an option, errors, returns non-zero, and the refutation
  # PASSES -- which is exactly how this row was green while the template
  # carried the arm it exists to catch.
  refute_file_contains "$UTILZ_HOME/opt/$name/$name" '--version)'

  [[ "$a" =~ ^utilz:${SEMVER}/${name}:${SEMVER}$ ]] || fail "generated utility, symlink form: '$a'"
  [ "$a" = "$b" ] || fail "generated utility answers differently by form: '$a' vs '$b'"
}

@test "AT09 / AC08: an unreadable version exits NON-ZERO rather than reporting success" {
  # The old arms exited 0 whatever show_version returned, so a utility whose
  # version_file was missing from an install printed an error and told the
  # caller it had succeeded -- a shipped regression, not a hypothetical.
  local sandbox="$BATS_TEST_TMPDIR/nover"
  mkdir -p "$sandbox/opt/broken"
  cp "$UTILZ_HOME/bin/utilz" "$sandbox/utilz-copy" 2>/dev/null || true
  printf 'name: broken\ndescription: no version anywhere\nversion_file: MISSING\n' \
    > "$sandbox/opt/broken/broken.yaml"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$sandbox/opt/broken/broken"
  chmod +x "$sandbox/opt/broken/broken"

  run bash -c "source '$UTILZ_HOME/opt/utilz/lib/common.sh'; UTILZ_HOME='$sandbox' show_version broken"
  assert_failure
}

@test "AT10 / AC09: utilz itself is the degenerate pair, and keeps its detail lines" {
  # hv's ruling: `utilz:<version>`, no `v`, so the framework half renders
  # identically in the solo and the pair form. Lines two and three are NOT
  # part of that ruling and are asserted here because ST0014/AC12 -- on a
  # CLOSED thread -- holds that an installed utilz can be told from a source
  # utilz at the prompt. Rewriting line one and tidying line three away would
  # break a satisfied criterion elsewhere, and nothing in AC01-AC08 sees it.
  run "$UTILZ_BIN_DIR/utilz" --version
  assert_success
  assert_output_matches "^utilz:${SEMVER}($|[^0-9.])"
  refute_output_contains "utilz v"

  local l2 l3
  l2=$(printf '%s' "$output" | sed -n 2p)
  l3=$(printf '%s' "$output" | sed -n 3p)
  [ -n "$l2" ] || fail "the description line is gone"
  [[ "$l3" =~ ^(source|installed)\ at\  ]] || fail "the tree-provenance line is gone or reshaped: '$l3'"
}

@test "AT11 / AC09: the framework half is spelled the same way alone as it is in a pair" {
  local solo pair
  solo=$("$UTILZ_BIN_DIR/utilz" --version 2>&1 | head -1)
  pair=$("$UTILZ_BIN_DIR/utilz" syncz --version 2>&1 | head -1)
  # `utilz:2.6.1` must be a literal prefix of `utilz:2.6.1/syncz:2.0.0`.
  [[ "$pair" == "$solo/"* ]] || fail "solo '$solo' is not the prefix of pair '$pair'"
}
