#!/usr/bin/env bats
# keg.bats - ST0019/WP-02: a Homebrew keg is an install tree whose upgrade is brew's
#
# AT03 (AC-02.1). The formula publishes with `utilz install --managed-by brew`,
# which records managed_by in the manifest's header, and install_tree_manager
# reads it. Every verb that writes or links a tree refuses a keg at either end
# and names `brew upgrade utilz`; utilz test's refusal names a clone, because a
# keg's source_tree is brew's deleted build directory (design D4).
#
# Every keg here is published by the real install verb from make_fake_src, so
# the row under test is the one a publish writes, not one a fixture typed.
# INSTALL_GH names no gh, so each publish records unknown at once instead of
# asking CI over the network.

load "test_helper.bash"

# Publish <src> to <prefix> with any extra install args, gh absent.
publish_to() {
  local src="$1" prefix="$2"
  shift 2
  run run_install_function "UTILZ_HOME='$src'; INSTALL_GH='$BATS_TEST_TMPDIR/no-gh'; install_verb_install --prefix '$prefix' $*"
}

# A fake source at <src> and a keg published from it at <keg>.
make_keg() {
  local src="$1" keg="$2"
  make_fake_src "$src"
  publish_to "$src" "$keg" --managed-by brew
  assert_success
}

# Echo <manifest>'s managed_by value, or nothing (the contract's header, T3).
managed_by_row() {
  awk '/^# managed_by: / { print substr($0, 15); exit }' "$1"
}

@test "AT03 (ST0019 AC-02.1): --managed-by brew records brew, and every other publish records utilz" {
  local src="$BATS_TEST_TMPDIR/src"
  make_keg "$src" "$BATS_TEST_TMPDIR/keg"
  publish_to "$src" "$BATS_TEST_TMPDIR/plain"
  assert_success

  [ "$(managed_by_row "$BATS_TEST_TMPDIR/keg/manifest.sha256")" = "brew" ] || fail "the keg records '$(managed_by_row "$BATS_TEST_TMPDIR/keg/manifest.sha256")'"
  [ "$(managed_by_row "$BATS_TEST_TMPDIR/plain/manifest.sha256")" = "utilz" ] || fail "the plain install records '$(managed_by_row "$BATS_TEST_TMPDIR/plain/manifest.sha256")'"

  run run_install_function "install_tree_manager '$BATS_TEST_TMPDIR/keg'; install_tree_manager '$BATS_TEST_TMPDIR/plain'; install_tree_manager '$src'"
  assert_success
  [ "$output" = $'brew\nutilz\nutilz' ] || fail "install_tree_manager answered: $output"
}

@test "AT03 (ST0019 AC-02.1): an old-form manifest is read for its manager alone, brew's still brew's (issue 0105)" {
  # The 2.14.2 kegs carry the old form. It is not read as a second format
  # (contract T3), but who wrote it still decides what may write into it.
  local oldkeg="$BATS_TEST_TMPDIR/oldkeg" oldopt="$BATS_TEST_TMPDIR/oldopt" older="$BATS_TEST_TMPDIR/older"
  mkdir -p "$oldkeg" "$oldopt" "$older"
  printf 'utilz-version\t2.14.2\nmanaged-by\tbrew\n' > "$oldkeg/manifest.sha256"
  printf 'utilz-version\t2.10.0\nmanaged-by\tutilz\n' > "$oldopt/manifest.sha256"
  printf 'utilz-version\t2.9.0\n' > "$older/manifest.sha256"

  run run_install_function "install_tree_manager '$oldkeg'; install_tree_manager '$oldopt'; install_tree_manager '$older'"
  assert_success
  [ "$output" = $'brew\nutilz\nutilz' ] || fail "install_tree_manager answered: $output"

  local src="$BATS_TEST_TMPDIR/src"
  make_fake_src "$src"
  publish_to "$src" "$oldkeg" --force
  assert_failure
  assert_output_contains "is a Homebrew keg"
}

@test "AT03 (ST0019 AC-02.1): --managed-by takes brew or utilz and refuses any other word" {
  local src="$BATS_TEST_TMPDIR/src"
  make_fake_src "$src"
  publish_to "$src" "$BATS_TEST_TMPDIR/dst" --managed-by apt
  assert_exit_code 2
  assert_output_contains "--managed-by takes brew or utilz"
  [ ! -e "$BATS_TEST_TMPDIR/dst/manifest.sha256" ] || fail "a refused publish wrote a manifest"
}

@test "AT03 (ST0019 AC-02.1): install --force refuses onto a keg, names brew upgrade, and writes nothing" {
  local src="$BATS_TEST_TMPDIR/src" keg="$BATS_TEST_TMPDIR/keg" before
  make_keg "$src" "$keg"
  before=$(shasum "$keg/manifest.sha256")

  publish_to "$src" "$keg" --force
  assert_failure
  assert_output_contains "is a Homebrew keg"
  assert_output_contains "brew upgrade utilz"

  [ "$(shasum "$keg/manifest.sha256")" = "$before" ] || fail "a refusal rewrote the keg's manifest"
}

@test "AT03 (ST0019 AC-02.1): install run from a keg refuses by naming brew, not by the missing git" {
  local keg="$BATS_TEST_TMPDIR/keg"
  make_keg "$BATS_TEST_TMPDIR/src" "$keg"

  run run_install_function "UTILZ_HOME='$keg'; install_verb_install --prefix '$BATS_TEST_TMPDIR/anywhere'"
  assert_failure
  assert_output_contains "brew upgrade utilz"
  refute_output_contains "not a git repository"
}

@test "AT03 (ST0019 AC-02.1): use opt refuses when the opt prefix is a keg, and moves no link" {
  local src="$BATS_TEST_TMPDIR/src" keg="$BATS_TEST_TMPDIR/keg" bindir="$BATS_TEST_TMPDIR/bin"
  make_keg "$src" "$keg"
  set_prefix_key "$src" "$keg"
  mkdir -p "$bindir"
  ln -s "$src/bin/alpha" "$bindir/alpha"

  run run_install_function "UTILZ_HOME='$src'; install_verb_use opt --bin-dir '$bindir'"
  assert_failure
  assert_output_contains "brew upgrade utilz"
  [ "$(readlink "$bindir/alpha")" = "$src/bin/alpha" ] || fail "a refusal moved the link"
}

@test "AT03 (ST0019 AC-02.1): use dev from a keg refuses, naming the checkout, and moves no link" {
  # A keg's source_tree names brew's deleted build directory, never a tree a
  # link could point at (design D4), so from brew the checkout is not known.
  local src="$BATS_TEST_TMPDIR/src" keg="$BATS_TEST_TMPDIR/keg" bindir="$BATS_TEST_TMPDIR/bin"
  make_keg "$src" "$keg"
  mkdir -p "$bindir"
  ln -s "$src/bin/alpha" "$bindir/alpha"

  run run_install_function "UTILZ_HOME='$keg'; install_verb_use dev --bin-dir '$bindir'"
  assert_failure
  assert_output_contains "<checkout>/bin/utilz use dev"
  [ "$(readlink "$bindir/alpha")" = "$src/bin/alpha" ] || fail "a refusal moved the link"
}

@test "AT03 (ST0019 AC-02.1): utilz test in a keg names a clone, never the keg's source_tree" {
  local keg="$BATS_TEST_TMPDIR/keg-real"
  run run_install_function "install_copy_owned '$UTILZ_HOME' '$keg' >/dev/null && install_manifest_write '$UTILZ_HOME' '$keg/manifest.sha256' '' \"\$(install_manifest_rows '$UTILZ_HOME')\" brew"
  assert_success
  [ "$(managed_by_row "$keg/manifest.sha256")" = "brew" ] || fail "the fixture is not a keg"

  run env UTILZ_HOME="$keg" "$keg/bin/utilz" test
  assert_failure
  assert_output_contains "cannot run from an install tree"
  assert_output_contains "git clone https://github.com/matthewsinclair/utilz.git"
  refute_output_contains "cd $UTILZ_HOME && utilz test"
}
