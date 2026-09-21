#!/usr/bin/env bats
# formula_bump.bats - ST0019/WP-05: tools/formula-bump writes the tag and its commit
#
# AT04 (AC-05.3). The script is run as hv runs it, from a repository's own
# tools/, so each case copies the real script and the real formula into a
# fixture repository and runs that copy: the bytes under test are the bytes
# that ship to hv, and the git it asks is the fixture's, never this checkout's.

load "test_helper.bash"

# A fixture repository at <repo> carrying tools/formula-bump and the formula,
# committed, with an annotated tag 9.9.9 and a lightweight tag light.
make_bump_repo() {
  local repo="$1"
  mkdir -p "$repo/tools" "$repo/packaging/homebrew"
  cp "$UTILZ_HOME/tools/formula-bump" "$repo/tools/formula-bump"
  cp "$UTILZ_HOME/packaging/homebrew/utilz.rb" "$repo/packaging/homebrew/utilz.rb"
  git -C "$repo" init -q
  fixture_commit "$repo" init
  git -C "$repo" -c user.email=t@example.com -c user.name=t tag -a 9.9.9 -m "9.9.9"
  git -C "$repo" tag light
}

# The formula's tag: and revision: values, as "<tag> <revision>".
formula_pin() {
  awk -F'"' '/^ *tag: / { t = $2 } /^ *revision: / { r = $2 } END { print t " " r }' "$1"
}

@test "AT04 (ST0019 AC-05.3): an annotated tag rewrites exactly tag: and revision:, from git, and prints the diff" {
  local repo="$BATS_TEST_TMPDIR/repo" formula commit before
  make_bump_repo "$repo"
  formula="$repo/packaging/homebrew/utilz.rb"
  commit=$(git -C "$repo" rev-parse '9.9.9^{commit}')
  before="$BATS_TEST_TMPDIR/before.rb"
  cp "$formula" "$before"

  local mode_before
  mode_before=$(ls -l "$formula" | cut -c1-10)

  run "$repo/tools/formula-bump" 9.9.9
  assert_success
  [ "$(ls -l "$formula" | cut -c1-10)" = "$mode_before" ] || fail "the rewrite changed the formula's mode to $(ls -l "$formula" | cut -c1-10)"
  [ "$(formula_pin "$formula")" = "9.9.9 $commit" ] || fail "the formula reads: $(formula_pin "$formula")"

  # Exactly two lines changed, and they are the two it owns.
  local changed
  changed=$(diff "$before" "$formula" | grep -c '^>' || true)
  [ "$changed" -eq 2 ] || fail "$changed lines changed: $(diff "$before" "$formula")"
  diff "$before" "$formula" | grep '^>' | grep -qv -e 'tag:' -e 'revision:' \
    && fail "a line other than tag: or revision: changed"

  # The diff it printed is the change it made.
  assert_output_contains "+      tag:      \"9.9.9\","
  assert_output_contains "+      revision: \"$commit\""
}

@test "AT04 (ST0019 AC-05.3): a tag that does not exist is refused and nothing changes" {
  local repo="$BATS_TEST_TMPDIR/repo" formula before
  make_bump_repo "$repo"
  formula="$repo/packaging/homebrew/utilz.rb"
  before=$(shasum "$formula")

  run "$repo/tools/formula-bump" 1.2.3
  assert_failure
  assert_output_contains "no tag '1.2.3'"
  [ "$(shasum "$formula")" = "$before" ] || fail "a refusal changed the formula"
}

@test "AT04 (ST0019 AC-05.3): a lightweight tag is refused, because every release tag is annotated" {
  local repo="$BATS_TEST_TMPDIR/repo" formula before
  make_bump_repo "$repo"
  formula="$repo/packaging/homebrew/utilz.rb"
  before=$(shasum "$formula")

  run "$repo/tools/formula-bump" light
  assert_failure
  assert_output_contains "lightweight"
  [ "$(shasum "$formula")" = "$before" ] || fail "a refusal changed the formula"
}

@test "AT04 (ST0019 AC-05.3): anything but one argument is refused with exit 2" {
  local repo="$BATS_TEST_TMPDIR/repo"
  make_bump_repo "$repo"
  run "$repo/tools/formula-bump"
  assert_exit_code 2
  run "$repo/tools/formula-bump" 9.9.9 extra
  assert_exit_code 2
}

@test "AT04 (ST0019 AC-05.3): a formula without exactly one tag: and one revision: line is refused and left alone" {
  local repo="$BATS_TEST_TMPDIR/repo" formula before
  make_bump_repo "$repo"
  formula="$repo/packaging/homebrew/utilz.rb"

  # A second revision: line: which one is the pin is no longer knowable.
  printf '      revision: "%s"\n' "1111111111111111111111111111111111111111" >> "$formula"
  before=$(shasum "$formula")
  run "$repo/tools/formula-bump" 9.9.9
  assert_failure
  assert_output_contains "revision:"
  [ "$(shasum "$formula")" = "$before" ] || fail "a refusal changed the formula"

  # No tag: line at all.
  git -C "$repo" checkout -q -- packaging/homebrew/utilz.rb
  grep -v '^ *tag: ' "$formula" > "$formula.tmp" && mv "$formula.tmp" "$formula"
  before=$(shasum "$formula")
  run "$repo/tools/formula-bump" 9.9.9
  assert_failure
  assert_output_contains "tag:"
  [ "$(shasum "$formula")" = "$before" ] || fail "a refusal changed the formula"
}
