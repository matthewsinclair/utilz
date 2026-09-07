#!/usr/bin/env bats
# relink.bats - ST0014/WP-12: the explicit PATH-symlink verb
#
# AC11 and AC16 are one policy from two sides: never implicitly, always
# available explicitly. install and upgrade write nothing outside the prefix
# (AT12, in install.bats); this is the verb the operator types when they do
# want the cutover.
#
# Every test uses a FIXTURE bin directory. Nothing here may touch the real
# ~/.local/bin, which on this machine holds sixteen links into the checkout.

load "test_helper.bash"

run_install_function() {
  bash -c "source '$UTILZ_HOME/opt/utilz/lib/common.sh'; source '$UTILZ_HOME/opt/utilz/lib/install.sh'; $*"
}

# A bin directory carrying both link shapes plus one link that is nobody's.
make_fake_bin() {
  local bindir="$1" tree="$2"
  mkdir -p "$bindir"

  # The ordinary shape: absolute, to its own name.
  ln -s "$tree/bin/alpha" "$bindir/alpha"
  # The odd shape ~/.local/bin/prez actually has: RELATIVE, and pointing at the
  # DISPATCHER rather than at bin/<name>. It works because dispatch keys on
  # basename "$0".
  ln -s "../$(basename "$tree")/bin/utilz" "$bindir/beta"
  ln -s "$tree/bin/utilz" "$bindir/utilz"

  # Nobody's. A link into a tree that is not Utilz at all.
  mkdir -p "$BATS_TEST_TMPDIR/elsewhere"
  printf '#!/usr/bin/env bash\n' > "$BATS_TEST_TMPDIR/elsewhere/stranger"
  chmod +x "$BATS_TEST_TMPDIR/elsewhere/stranger"
  ln -s "$BATS_TEST_TMPDIR/elsewhere/stranger" "$bindir/stranger"
}

# ============================================================================
# AT16 - repoint what is ours, leave alone what is not
# ============================================================================

@test "relink repoints every Utilz link into the named tree" {
  local old="$BATS_TEST_TMPDIR/old" new="$BATS_TEST_TMPDIR/new"
  local bindir="$BATS_TEST_TMPDIR/bin"
  make_fake_src "$old"
  run run_install_function "UTILZ_HOME='$old'; install_verb_install --prefix '$new'"
  assert_success
  make_fake_bin "$bindir" "$old"

  run run_install_function "install_verb_relink --prefix '$new' --bin-dir '$bindir'"
  assert_success

  local link
  for link in alpha beta utilz; do
    local resolved
    resolved=$(cd "$bindir" && cd "$(dirname "$(readlink "$link")")" && pwd)
    [[ "$resolved" == "$new/bin" ]] || {
      echo "$link resolves into $resolved, not $new/bin" >&2
      return 1
    }
  done
}

@test "relink leaves the odd-shaped link dispatching as itself" {
  # beta points at the DISPATCHER, not at bin/beta. Repointing it must keep
  # that: changing the target's basename would be normalising a convention
  # under cover of a command asked to do something else (design.md D9).
  local old="$BATS_TEST_TMPDIR/old-odd" new="$BATS_TEST_TMPDIR/new-odd"
  local bindir="$BATS_TEST_TMPDIR/bin-odd"
  make_fake_src "$old"
  run run_install_function "UTILZ_HOME='$old'; install_verb_install --prefix '$new'"
  assert_success
  make_fake_bin "$bindir" "$old"

  run run_install_function "install_verb_relink --prefix '$new' --bin-dir '$bindir'"
  assert_success

  [[ "$(basename "$(readlink "$bindir/beta")")" == "utilz" ]] || {
    echo "beta now points at $(readlink "$bindir/beta") -- its shape was normalised" >&2
    return 1
  }
  [[ "$(basename "$(readlink "$bindir/alpha")")" == "alpha" ]]
}

@test "relink leaves a link pointing at neither tree alone, and reports it skipped" {
  local old="$BATS_TEST_TMPDIR/old-skip" new="$BATS_TEST_TMPDIR/new-skip"
  local bindir="$BATS_TEST_TMPDIR/bin-skip"
  make_fake_src "$old"
  run run_install_function "UTILZ_HOME='$old'; install_verb_install --prefix '$new'"
  assert_success
  make_fake_bin "$bindir" "$old"

  local before
  before=$(readlink "$bindir/stranger")

  run run_install_function "install_verb_relink --prefix '$new' --bin-dir '$bindir'"
  assert_success
  assert_output_contains "skipped"
  assert_output_contains "stranger"

  [[ "$(readlink "$bindir/stranger")" == "$before" ]] || {
    echo "a link that is nobody's was rewritten" >&2
    return 1
  }
}

@test "relink REPORTS what it changed" {
  local old="$BATS_TEST_TMPDIR/old-rep" new="$BATS_TEST_TMPDIR/new-rep"
  local bindir="$BATS_TEST_TMPDIR/bin-rep"
  make_fake_src "$old"
  run run_install_function "UTILZ_HOME='$old'; install_verb_install --prefix '$new'"
  assert_success
  make_fake_bin "$bindir" "$old"

  run run_install_function "install_verb_relink --prefix '$new' --bin-dir '$bindir'"
  assert_success
  assert_output_contains "relinked"
  assert_output_contains "alpha"
  assert_output_contains "beta"
}

@test "relink is idempotent: a second run changes nothing and says so" {
  local old="$BATS_TEST_TMPDIR/old-idem" new="$BATS_TEST_TMPDIR/new-idem"
  local bindir="$BATS_TEST_TMPDIR/bin-idem"
  make_fake_src "$old"
  run run_install_function "UTILZ_HOME='$old'; install_verb_install --prefix '$new'"
  assert_success
  make_fake_bin "$bindir" "$old"

  run run_install_function "install_verb_relink --prefix '$new' --bin-dir '$bindir'"
  assert_success

  run run_install_function "install_verb_relink --prefix '$new' --bin-dir '$bindir'"
  assert_success
  assert_output_contains "unchanged"
  refute_output_contains "relinked"
}

@test "relink refuses a target that is not a Utilz tree" {
  local bindir="$BATS_TEST_TMPDIR/bin-bad"
  mkdir -p "$bindir" "$BATS_TEST_TMPDIR/notatree"

  run run_install_function "install_verb_relink --prefix '$BATS_TEST_TMPDIR/notatree' --bin-dir '$bindir'"
  assert_exit_code 1
  assert_output_contains "not a Utilz tree"
}

@test "relink refuses a bin directory that does not exist" {
  local new="$BATS_TEST_TMPDIR/new-nobin" old="$BATS_TEST_TMPDIR/old-nobin"
  make_fake_src "$old"
  run run_install_function "UTILZ_HOME='$old'; install_verb_install --prefix '$new'"
  assert_success

  run run_install_function "install_verb_relink --prefix '$new' --bin-dir '$BATS_TEST_TMPDIR/no-such-dir'"
  assert_exit_code 1
  assert_output_contains "no-such-dir"
}

# ============================================================================
# AC11's half - install and upgrade change NOTHING in that directory
# ============================================================================

@test "install and upgrade leave the bin directory untouched" {
  # One leg without the other proves only that something moved.
  local old="$BATS_TEST_TMPDIR/old-ac11" new="$BATS_TEST_TMPDIR/new-ac11"
  local bindir="$BATS_TEST_TMPDIR/bin-ac11"
  make_fake_src "$old"
  make_fake_bin "$bindir" "$old"

  local before after
  before=$(cd "$bindir" && for f in *; do printf '%s -> %s\n' "$f" "$(readlink "$f")"; done | LC_ALL=C sort)

  run run_install_function "UTILZ_HOME='$old'; install_verb_install --prefix '$new'"
  assert_success
  run run_install_function "UTILZ_HOME='$old'; install_verb_upgrade --prefix '$new'"
  assert_success

  after=$(cd "$bindir" && for f in *; do printf '%s -> %s\n' "$f" "$(readlink "$f")"; done | LC_ALL=C sort)
  [[ "$before" == "$after" ]] || {
    echo "install or upgrade touched the bin directory:" >&2
    diff <(printf '%s\n' "$before") <(printf '%s\n' "$after") >&2
    return 1
  }
}
