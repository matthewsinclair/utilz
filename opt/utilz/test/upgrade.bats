#!/usr/bin/env bats
# upgrade.bats - ST0014/WP-03: the `utilz upgrade` verb
#
# The mirror of install (AC04), plus the one behaviour install does not have:
# a file edited in place is REPORTED and LEFT ALONE, and keeps its install-time
# checksum (AC08). Re-checksumming a file the upgrade declined to overwrite
# would record the edit as canonical and the next check would pronounce it
# intact -- the refuse-then-bless failure, where the refusal still prints and
# the evidence that made it necessary is destroyed by the same pass.

load "test_helper.bash"

run_install_function() {
  bash -c "source '$UTILZ_HOME/opt/utilz/lib/common.sh'; source '$UTILZ_HOME/opt/utilz/lib/install.sh'; $*"
}

run_publish() {
  local src="$1" prefix="$2"
  shift 2
  run run_install_function "UTILZ_HOME='$src'; install_verb_install --prefix '$prefix' $*"
}

run_upgrade() {
  local src="$1" prefix="$2"
  shift 2
  run run_install_function "UTILZ_HOME='$src'; install_verb_upgrade --prefix '$prefix' $*"
}

commit_src() {
  git -C "$1" add -A >/dev/null 2>&1
  git -C "$1" -c user.email=t@example.com -c user.name=t commit -qm "$2" >/dev/null 2>&1
}

manifest_row_for() {
  awk -F'\t' -v p="$2" '$3 == p { print $2; exit }' "$1/manifest.sha256"
}

# ============================================================================
# AT05 (AC04) - the mirror refusal
# ============================================================================

@test "upgrade refuses when no install exists, and NAMES install" {
  local src="$BATS_TEST_TMPDIR/src" dst="$BATS_TEST_TMPDIR/empty"
  make_fake_src "$src"
  mkdir -p "$dst"

  run_upgrade "$src" "$dst"
  assert_exit_code 1
  # Both halves or the mirror is untested: install names upgrade (AT04), and
  # upgrade names install here. Whichever verb is reached for, the wrong one
  # names the right one.
  assert_output_contains "install"
}

@test "upgrade announces its mode" {
  local src="$BATS_TEST_TMPDIR/src-mode" dst="$BATS_TEST_TMPDIR/dst-mode"
  make_fake_src "$src"
  run_publish "$src" "$dst"
  assert_success

  run_upgrade "$src" "$dst"
  assert_success
  assert_output_contains "mode"
  assert_output_contains "upgrade"
}

@test "upgrade refuses a dirty source tree" {
  local src="$BATS_TEST_TMPDIR/src-dirty" dst="$BATS_TEST_TMPDIR/dst-dirty"
  make_fake_src "$src"
  run_publish "$src" "$dst"
  assert_success

  printf 'uncommitted\n' > "$src/SCRATCH.md"
  run_upgrade "$src" "$dst"
  assert_exit_code 1
  assert_output_contains "dirty"
}

# ============================================================================
# The happy path
# ============================================================================

@test "upgrade replaces an install and the manifest verifies afterwards" {
  local src="$BATS_TEST_TMPDIR/src-ok" dst="$BATS_TEST_TMPDIR/dst-ok"
  make_fake_src "$src"
  run_publish "$src" "$dst"
  assert_success

  printf '#!/usr/bin/env bash\necho v2\n' > "$src/opt/alpha/alpha"
  commit_src "$src" v2

  run_upgrade "$src" "$dst"
  assert_success
  assert_file_contains "$dst/opt/alpha/alpha" "echo v2"

  run run_install_function "install_manifest_check '$dst'"
  assert_success
  assert_output ""
}

@test "upgrade brings across a file the source has gained" {
  local src="$BATS_TEST_TMPDIR/src-new" dst="$BATS_TEST_TMPDIR/dst-new"
  make_fake_src "$src"
  run_publish "$src" "$dst"
  assert_success

  printf '# new\n' > "$src/help/beta.md"
  commit_src "$src" newfile

  run_upgrade "$src" "$dst"
  assert_success
  assert_file_exists "$dst/help/beta.md"
}

@test "upgrade restores an owned file that was DELETED from the install" {
  # A missing file is not an edit to preserve. Nothing was authored there.
  local src="$BATS_TEST_TMPDIR/src-del" dst="$BATS_TEST_TMPDIR/dst-del"
  make_fake_src "$src"
  run_publish "$src" "$dst"
  assert_success
  rm "$dst/help/alpha.md"

  run_upgrade "$src" "$dst"
  assert_success
  assert_file_exists "$dst/help/alpha.md"
}

# ============================================================================
# AT09 (AC08) - an edited file is reported, left alone, and keeps its row
# ============================================================================

@test "upgrade REPORTS a file edited in place and LEAVES IT ALONE" {
  local src="$BATS_TEST_TMPDIR/src-edit" dst="$BATS_TEST_TMPDIR/dst-edit"
  make_fake_src "$src"
  run_publish "$src" "$dst"
  assert_success

  printf '\n# hand edit\n' >> "$dst/opt/alpha/alpha"

  # The source moves on too, so "left alone" is distinguishable from "the
  # source happened to match".
  printf '#!/usr/bin/env bash\necho upstream-v2\n' > "$src/opt/alpha/alpha"
  commit_src "$src" upstream

  run_upgrade "$src" "$dst"
  assert_success
  assert_output_contains "opt/alpha/alpha"

  assert_file_contains "$dst/opt/alpha/alpha" "hand edit"
  refute_file_contains "$dst/opt/alpha/alpha" "upstream-v2"
}

@test "a file the upgrade declined to overwrite keeps its INSTALL-TIME checksum" {
  # The row must be neither a re-checksum of the edit (which blesses it, and
  # the next check then calls the file intact) nor the new source's checksum
  # (which claims a file was updated that was not). It is the row the install
  # wrote, so the drift stays visible.
  local src="$BATS_TEST_TMPDIR/src-row" dst="$BATS_TEST_TMPDIR/dst-row"
  make_fake_src "$src"
  run_publish "$src" "$dst"
  assert_success

  local install_time_row edited_sum upstream_sum after_row
  install_time_row=$(manifest_row_for "$dst" "opt/alpha/alpha")

  printf '\n# hand edit\n' >> "$dst/opt/alpha/alpha"
  edited_sum=$(shasum -a 256 "$dst/opt/alpha/alpha" | awk '{print $1}')

  printf '#!/usr/bin/env bash\necho upstream-v2\n' > "$src/opt/alpha/alpha"
  commit_src "$src" upstream
  upstream_sum=$(shasum -a 256 "$src/opt/alpha/alpha" | awk '{print $1}')

  run_upgrade "$src" "$dst"
  assert_success

  after_row=$(manifest_row_for "$dst" "opt/alpha/alpha")
  [[ "$after_row" == "$install_time_row" ]] || {
    echo "row is not the install-time one" >&2
    echo "  install-time: $install_time_row" >&2
    echo "  after:        $after_row" >&2
    echo "  (edited:      $edited_sum)" >&2
    echo "  (upstream:    $upstream_sum)" >&2
    return 1
  }
  [[ "$after_row" != "$edited_sum" ]]
  [[ "$after_row" != "$upstream_sum" ]]

  # And therefore the very next check still reports the edit.
  run run_install_function "install_manifest_check '$dst'"
  assert_failure
  assert_output_contains "modified"
  assert_output_contains "opt/alpha/alpha"
}

@test "upgrade reports a RETARGETED link and leaves it alone" {
  local src="$BATS_TEST_TMPDIR/src-link" dst="$BATS_TEST_TMPDIR/dst-link"
  make_fake_src "$src"
  run_publish "$src" "$dst"
  assert_success

  rm "$dst/bin/alpha"
  ln -s other "$dst/bin/alpha"

  run_upgrade "$src" "$dst"
  assert_success
  assert_output_contains "bin/alpha"
  [[ "$(readlink "$dst/bin/alpha")" == "other" ]]
}

@test "upgrade --force overwrites the edit and records the new checksum" {
  local src="$BATS_TEST_TMPDIR/src-force" dst="$BATS_TEST_TMPDIR/dst-force"
  make_fake_src "$src"
  run_publish "$src" "$dst"
  assert_success

  printf '\n# hand edit\n' >> "$dst/opt/alpha/alpha"
  printf '#!/usr/bin/env bash\necho upstream-v2\n' > "$src/opt/alpha/alpha"
  commit_src "$src" upstream

  run_upgrade "$src" "$dst" "--force"
  assert_success
  assert_file_contains "$dst/opt/alpha/alpha" "upstream-v2"
  refute_file_contains "$dst/opt/alpha/alpha" "hand edit"

  run run_install_function "install_manifest_check '$dst'"
  assert_success
  assert_output ""
}
