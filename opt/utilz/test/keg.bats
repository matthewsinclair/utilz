#!/usr/bin/env bats
# keg.bats - ST0019/WP-02: a Homebrew keg is an install tree whose upgrade is brew's
#
# AT03 (AC-02.1). The formula publishes with devbin's publish, `bin/devbin
# install --managed-by brew` (devbin#0326, issue I59c806c), which records
# managed_by in the manifest's header, and install_tree_manager reads it. A
# publish into a keg, or a switch onto one, is devbin's to refuse, and devbin's
# own arms prove it. What stays Utilz's: it reads a keg as brew, an old-form
# manifest's manager included, and utilz test's refusal names a clone, because
# a keg's source tree is brew's deleted build directory (design D4).
#
# Every keg here is written by devbin's publish, so the row under test is the
# one a publish writes, not one a fixture typed.

load "test_helper.bash"

# A fake source at <src> and a keg published from it at <keg>.
make_keg() {
  local src="$1" keg="$2"
  make_fake_src "$src"
  run_publish "$src" "$keg" --managed-by brew
  assert_success
}

# Echo <manifest>'s managed_by value, or nothing (the contract's header, T3).
managed_by_row() {
  awk '/^# managed_by: / { print substr($0, 15); exit }' "$1"
}

@test "AT03 (ST0019 AC-02.1): --managed-by brew records brew, and every other publish records utilz" {
  local src="$BATS_TEST_TMPDIR/src"
  make_keg "$src" "$BATS_TEST_TMPDIR/keg"
  run_publish "$src" "$BATS_TEST_TMPDIR/plain"
  assert_success

  [ "$(managed_by_row "$BATS_TEST_TMPDIR/keg/manifest.sha256")" = "brew" ] || fail "the keg records '$(managed_by_row "$BATS_TEST_TMPDIR/keg/manifest.sha256")'"
  [ "$(managed_by_row "$BATS_TEST_TMPDIR/plain/manifest.sha256")" = "utilz" ] || fail "the plain install records '$(managed_by_row "$BATS_TEST_TMPDIR/plain/manifest.sha256")'"

  run run_install_function "install_tree_manager '$BATS_TEST_TMPDIR/keg'; install_tree_manager '$BATS_TEST_TMPDIR/plain'; install_tree_manager '$src'"
  assert_success
  [ "$output" = $'brew\nutilz\nutilz' ] || fail "install_tree_manager answered: $output"
}

@test "AT03 (ST0019 AC-02.1): an old-form manifest is read for its manager alone, brew's still brew's, in both old forms (issues 0105, I59c806c)" {
  # Two old forms, neither read as a second format (contract T3), though who
  # wrote each still decides its tree: the rows before the contract, and
  # Utilz's own header with no `line`, which `utilz install` wrote before
  # devbin's publish and which Homebrew's keg carries until the next release.
  local oldkeg="$BATS_TEST_TMPDIR/oldkeg" oldopt="$BATS_TEST_TMPDIR/oldopt" older="$BATS_TEST_TMPDIR/older"
  local hdrkeg="$BATS_TEST_TMPDIR/hdrkeg" hdropt="$BATS_TEST_TMPDIR/hdropt" sha
  mkdir -p "$oldkeg" "$oldopt" "$older" "$hdrkeg" "$hdropt"
  sha=$(git -C "$UTILZ_HOME" rev-parse HEAD)
  printf 'utilz-version\t2.14.2\nmanaged-by\tbrew\n' > "$oldkeg/manifest.sha256"
  printf 'utilz-version\t2.10.0\nmanaged-by\tutilz\n' > "$oldopt/manifest.sha256"
  printf 'utilz-version\t2.9.0\n' > "$older/manifest.sha256"
  printf '# tool: utilz\n# version: 2.15.0\n# source_commit: %s\n# managed_by: brew\n' "$sha" > "$hdrkeg/manifest.sha256"
  printf '# tool: utilz\n# version: 2.15.0\n# source_commit: %s\n# managed_by: utilz\n' "$sha" > "$hdropt/manifest.sha256"

  run run_install_function "install_tree_manager '$oldkeg'; install_tree_manager '$oldopt'; install_tree_manager '$older'; install_tree_manager '$hdrkeg'; install_tree_manager '$hdropt'"
  assert_success
  [ "$output" = $'brew\nutilz\nutilz\nbrew\nutilz' ] || fail "install_tree_manager answered: $output"

  run run_install_function "utilz_tree '$hdrkeg'; utilz_tree '$hdropt'"
  assert_success
  [ "$output" = $'brew old\nopt old' ] || fail "utilz_tree answered: $output"
}

@test "AT03 (ST0019 AC-02.1): utilz test in a keg names a clone, never the keg's source tree" {
  local keg="$BATS_TEST_TMPDIR/keg-real"
  publish_checkout_copy "$BATS_TEST_TMPDIR/keg-src" "$keg" "$BATS_TEST_TMPDIR/keg-publish.log" "keg setup" --managed-by brew ||
    fail "the keg could not be published"
  [ "$(managed_by_row "$keg/manifest.sha256")" = "brew" ] || fail "the fixture is not a keg"

  run env UTILZ_HOME="$keg" "$keg/bin/utilz" test
  assert_failure
  assert_output_contains "cannot run from an install tree"
  assert_output_contains "git clone https://github.com/matthewsinclair/utilz.git"
  refute_output_contains "cd $UTILZ_HOME && utilz test"
}
