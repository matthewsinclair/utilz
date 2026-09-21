#!/usr/bin/env bats
# keg.bats - ST0019/WP-02: a Homebrew keg is an install tree whose upgrade is brew's
#
# AT03 (AC-02.1). The formula publishes with `utilz install --managed-by brew`,
# which records a managed-by row, and install_tree_manager reads it. Every verb
# that writes or links a tree refuses a keg at either end and names
# `brew upgrade utilz`; utilz test's refusal names a clone, because a keg's
# source-tree is brew's deleted build directory (design D4).
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

# Echo <manifest>'s managed-by value, or nothing.
managed_by_row() {
  awk -F'\t' '$1 == "managed-by" { print $2; exit }' "$1"
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

@test "AT03 (ST0019 AC-02.1): a manifest from before the row reads as utilz" {
  local src="$BATS_TEST_TMPDIR/src" old="$BATS_TEST_TMPDIR/old"
  make_fake_src "$src"
  publish_to "$src" "$old"
  assert_success
  grep -v $'^managed-by\t' "$old/manifest.sha256" > "$old/m.tmp"
  mv "$old/m.tmp" "$old/manifest.sha256"
  [ -z "$(managed_by_row "$old/manifest.sha256")" ] || fail "the row is still there"

  run run_install_function "install_tree_manager '$old'"
  assert_success
  assert_output "utilz"

  # And upgrade still takes it, rewriting the manifest with the row.
  run run_install_function "UTILZ_HOME='$src'; INSTALL_GH='$BATS_TEST_TMPDIR/no-gh'; install_verb_upgrade --prefix '$old'"
  assert_success
  [ "$(managed_by_row "$old/manifest.sha256")" = "utilz" ] || fail "upgrade did not write the row"
}

@test "AT03 (ST0019 AC-02.1): --managed-by takes brew or utilz and refuses any other word" {
  local src="$BATS_TEST_TMPDIR/src"
  make_fake_src "$src"
  publish_to "$src" "$BATS_TEST_TMPDIR/dst" --managed-by apt
  assert_exit_code 2
  assert_output_contains "--managed-by takes brew or utilz"
  [ ! -e "$BATS_TEST_TMPDIR/dst/manifest.sha256" ] || fail "a refused publish wrote a manifest"
}

@test "AT03 (ST0019 AC-02.1): upgrade and install --force refuse onto a keg, name brew upgrade, and write nothing" {
  local src="$BATS_TEST_TMPDIR/src" keg="$BATS_TEST_TMPDIR/keg" before
  make_keg "$src" "$keg"
  before=$(shasum "$keg/manifest.sha256")

  run run_install_function "UTILZ_HOME='$src'; INSTALL_GH='$BATS_TEST_TMPDIR/no-gh'; install_verb_upgrade --prefix '$keg'"
  assert_failure
  assert_output_contains "is a Homebrew keg"
  assert_output_contains "brew upgrade utilz"

  publish_to "$src" "$keg" --force
  assert_failure
  assert_output_contains "is a Homebrew keg"
  assert_output_contains "brew upgrade utilz"

  [ "$(shasum "$keg/manifest.sha256")" = "$before" ] || fail "a refusal rewrote the keg's manifest"
}

@test "AT03 (ST0019 AC-02.1): upgrade run from a keg refuses by naming brew, not by the missing git" {
  local keg="$BATS_TEST_TMPDIR/keg"
  make_keg "$BATS_TEST_TMPDIR/src" "$keg"

  run run_install_function "UTILZ_HOME='$keg'; install_verb_upgrade --prefix '$BATS_TEST_TMPDIR/anywhere'"
  assert_failure
  assert_output_contains "brew upgrade utilz"
  refute_output_contains "not a git repository"
}

@test "AT03 (ST0019 AC-02.1): relink refuses into a keg and from one, and moves no link" {
  local src="$BATS_TEST_TMPDIR/src" keg="$BATS_TEST_TMPDIR/keg" bindir="$BATS_TEST_TMPDIR/bin"
  make_keg "$src" "$keg"
  mkdir -p "$bindir"
  ln -s "$src/bin/alpha" "$bindir/alpha"

  run run_install_function "UTILZ_HOME='$src'; install_verb_relink --prefix '$keg' --bin-dir '$bindir'"
  assert_failure
  assert_output_contains "brew upgrade utilz"

  run run_install_function "UTILZ_HOME='$keg'; install_verb_relink --prefix '$src' --bin-dir '$bindir'"
  assert_failure
  assert_output_contains "brew upgrade utilz"

  [ "$(readlink "$bindir/alpha")" = "$src/bin/alpha" ] || fail "a refusal moved the link to $(readlink "$bindir/alpha")"
}

@test "AT03 (ST0019 AC-02.1): use opt and use dev refuse when install.prefix is a keg" {
  local src="$BATS_TEST_TMPDIR/src" keg="$BATS_TEST_TMPDIR/keg" bindir="$BATS_TEST_TMPDIR/bin"
  make_keg "$src" "$keg"
  set_prefix_key "$src" "$keg"
  mkdir -p "$bindir"
  ln -s "$src/bin/alpha" "$bindir/alpha"

  run run_install_function "UTILZ_HOME='$src'; install_verb_use opt --bin-dir '$bindir'"
  assert_failure
  assert_output_contains "brew upgrade utilz"

  # dev refuses before it reads the keg's source-tree, which names brew's
  # deleted build directory, never a tree relink could point at.
  run run_install_function "UTILZ_HOME='$src'; install_verb_use dev --bin-dir '$bindir'"
  assert_failure
  assert_output_contains "brew upgrade utilz"

  [ "$(readlink "$bindir/alpha")" = "$src/bin/alpha" ] || fail "a refusal moved the link"
}

@test "AT03 (ST0019 AC-02.1): utilz test in a keg names a clone, never the keg's source-tree" {
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
