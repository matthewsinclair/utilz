#!/usr/bin/env bats
# install.bats - ST0014/WP-02: the `utilz install` verb
#
# Exercised as a FUNCTION against cheap `git init` fixtures. The enumeration is
# tested against the real tree in install_lib.bats, and the real dispatcher end
# to end in install_e2e.bats (WP-05, AT01). The split is deliberate: synthetic
# trees for the refusal paths, the real tree for anything that depends on the
# tree's actual shape.

load "test_helper.bash"

run_install_function() {
  bash -c "source '$UTILZ_HOME/opt/utilz/lib/common.sh'; source '$UTILZ_HOME/opt/utilz/lib/install.sh'; $*"
}

# Publish from $1 to $2, with any extra args appended.
run_publish() {
  local src="$1" prefix="$2"
  shift 2
  run run_install_function "UTILZ_HOME='$src'; install_verb_install --prefix '$prefix' $*"
}

set_prefix_key() {
  local src="$1" value="$2"
  printf 'name: utilz\ninstall:\n  prefix: %s\n' "$value" > "$src/opt/utilz/utilz.yaml"
  git -C "$src" add -A >/dev/null 2>&1
  git -C "$src" -c user.email=t@example.com -c user.name=t commit -qm prefix >/dev/null 2>&1
}

# ============================================================================
# THE HAPPY PATH
# ============================================================================

@test "install publishes the owned set, with symlinks arriving as symlinks" {
  local src="$BATS_TEST_TMPDIR/src" dst="$BATS_TEST_TMPDIR/dst"
  make_fake_src "$src"

  run_publish "$src" "$dst"
  assert_success

  assert_file_exists "$dst/manifest.sha256"
  assert_file_exists "$dst/bin/utilz"
  assert_file_exists "$dst/opt/alpha/alpha"

  # D3: cp dereferences, which produces a tree that still works and says
  # nothing. The link must arrive as a link carrying its target STRING.
  [[ -L "$dst/bin/alpha" ]] || {
    echo "bin/alpha arrived as a regular file, not a symlink" >&2
    return 1
  }
  [[ "$(readlink "$dst/bin/alpha")" == "utilz" ]]
  [[ "$(readlink "$dst/bin/beta")" == "other" ]]

  # AC13's exclusion: the suites are not shipped.
  assert_file_not_exists "$dst/opt/alpha/test/alpha.bats"
}

@test "install writes a manifest the checker then reads as clean" {
  local src="$BATS_TEST_TMPDIR/src-clean" dst="$BATS_TEST_TMPDIR/dst-clean"
  make_fake_src "$src"
  run_publish "$src" "$dst"
  assert_success

  run run_install_function "install_manifest_check '$dst'"
  assert_success
  assert_output ""
}

# ============================================================================
# AT11 (AC10) - the mode is announced BEFORE the first write
# ============================================================================

@test "install announces the mode before anything is written" {
  local src="$BATS_TEST_TMPDIR/src-mode" dst="$BATS_TEST_TMPDIR/dst-mode"
  make_fake_src "$src"

  run_publish "$src" "$dst"
  assert_success
  assert_output_contains "mode"
  assert_output_contains "install"
}

@test "install prints the mode even when the publish dies at its first write" {
  # Ordering, not presence. A line that only appears on the success path is not
  # announced before anything is written -- it is reported after everything was.
  local src="$BATS_TEST_TMPDIR/src-unwritable"
  make_fake_src "$src"

  local cage="$BATS_TEST_TMPDIR/cage"
  mkdir -p "$cage"
  chmod 500 "$cage"

  run_publish "$src" "$cage/prefix"
  assert_failure
  assert_output_contains "mode"

  chmod 700 "$cage"
}

# ============================================================================
# AT02 (AC02) - a dirty source tree is refused, and NO flag overrides it
# ============================================================================

@test "install refuses a dirty source tree, and --force does not override it" {
  local src="$BATS_TEST_TMPDIR/src-dirty" dst="$BATS_TEST_TMPDIR/dst-dirty"
  make_fake_src "$src"
  printf 'uncommitted\n' > "$src/SCRATCH.md"

  run_publish "$src" "$dst"
  assert_exit_code 1
  assert_output_contains "dirty"
  assert_directory_not_exists "$dst"

  # A gate with an escape hatch is not a gate.
  run_publish "$src" "$dst" "--force"
  assert_exit_code 1
  assert_output_contains "dirty"
  assert_directory_not_exists "$dst"
}

@test "install refuses a dirty tree for a change OUTSIDE the owned set" {
  # The gate reads the WHOLE tree. The manifest's claim is "these bytes are
  # commit X", and a dirty file anywhere means the recorded commit does not
  # describe the checkout the bytes came from.
  local src="$BATS_TEST_TMPDIR/src-outside" dst="$BATS_TEST_TMPDIR/dst-outside"
  make_fake_src "$src"
  mkdir -p "$src/docs"
  printf 'not owned, still dirty\n' > "$src/docs/notes.md"

  run_publish "$src" "$dst"
  assert_exit_code 1
  assert_output_contains "dirty"
}

# ============================================================================
# AT08 (AC07) - the recorded commit must describe the SHIPPED bytes
# ============================================================================

@test "install refuses when an owned file was mutated after the commit" {
  # Reachable only because AC02's dirty gate exists: without it the publish
  # records a commit the bytes do not match, and the manifest then vouches for
  # provenance it does not have.
  local src="$BATS_TEST_TMPDIR/src-mutate" dst="$BATS_TEST_TMPDIR/dst-mutate"
  make_fake_src "$src"
  printf '\n# mutated after the commit\n' >> "$src/opt/alpha/alpha"

  run_publish "$src" "$dst"
  assert_exit_code 1
  assert_directory_not_exists "$dst"
}

# ============================================================================
# AT03 (AC03) - publishing INTO a source tree is refused, from the TARGET
# ============================================================================

@test "install refuses a target that is a Utilz source tree" {
  local src="$BATS_TEST_TMPDIR/src-a" other="$BATS_TEST_TMPDIR/src-b"
  make_fake_src "$src"
  make_fake_src "$other"

  # src is NOT the target. A src-equals-dst comparison passes this, and that
  # is the guard devbin's vendored copy walked past on 2026-09-07.
  run_publish "$src" "$other"
  assert_exit_code 1
  assert_output_contains "source tree"
}

@test "install refuses a target that is its own source tree" {
  local src="$BATS_TEST_TMPDIR/src-self"
  make_fake_src "$src"

  run_publish "$src" "$src"
  assert_exit_code 1
  assert_output_contains "source tree"
}

# ============================================================================
# AT04 (AC04) - install onto an existing install names upgrade
# ============================================================================

@test "install refuses when an install already exists, and NAMES upgrade" {
  local src="$BATS_TEST_TMPDIR/src-twice" dst="$BATS_TEST_TMPDIR/dst-twice"
  make_fake_src "$src"

  run_publish "$src" "$dst"
  assert_success

  run_publish "$src" "$dst"
  assert_exit_code 1
  # Assert the word, not just the non-zero rc: whichever verb is reached for,
  # the wrong one has to name the right one.
  assert_output_contains "upgrade"
}

# ============================================================================
# AT06 (AC05) - the prefix is configuration, and unset is refused BY NAME
# ============================================================================

@test "install publishes to the configured prefix when the key is set" {
  local src="$BATS_TEST_TMPDIR/src-key" dst="$BATS_TEST_TMPDIR/dst-key"
  make_fake_src "$src"
  set_prefix_key "$src" "$dst"

  run run_install_function "UTILZ_HOME='$src'; install_verb_install"
  assert_success
  assert_file_exists "$dst/manifest.sha256"
}

@test "install refuses an absent prefix key BY NAME, and creates no ./null" {
  # The key IS absent today, so this is the live path rather than a contrived
  # one. get_util_metadata returns the four-character string 'null' for an
  # absent key, so a bare [[ -n ]] guard passes and publishes to ./null.
  local src="$BATS_TEST_TMPDIR/src-nokey"
  make_fake_src "$src"

  run run_install_function "cd '$BATS_TEST_TMPDIR'; UTILZ_HOME='$src'; install_verb_install"
  assert_exit_code 1
  assert_output_contains "install.prefix"
  assert_output_contains "utilz.yaml"
  assert_directory_not_exists "$BATS_TEST_TMPDIR/null"
}

@test "install refuses an EMPTY prefix value as well as an absent one" {
  # yq yields a zero-length result where it yields 'null' for an absent key.
  # A guard written for either case alone lets the other through.
  local src="$BATS_TEST_TMPDIR/src-empty"
  make_fake_src "$src"
  set_prefix_key "$src" '""'

  run run_install_function "UTILZ_HOME='$src'; install_verb_install"
  assert_exit_code 1
  assert_output_contains "install.prefix"
}

# ============================================================================
# AT12 (AC11) - nothing outside the prefix is written
# ============================================================================

@test "install writes nothing outside the prefix" {
  local src="$BATS_TEST_TMPDIR/src-scope" dst="$BATS_TEST_TMPDIR/scoped/dst"
  make_fake_src "$src"

  # A stand-in for ~/.local/bin: a link into the source tree, of the shape the
  # real one has. Relinking it implicitly is mutating the operator's
  # environment mid-command, which needs a verb they typed (AC16 / WP-12).
  local localbin="$BATS_TEST_TMPDIR/fakehome/.local/bin"
  mkdir -p "$localbin"
  ln -s "$src/bin/utilz" "$localbin/utilz"
  ln -s ../../src/bin/utilz "$localbin/alpha"

  local before after
  before=$(cd "$BATS_TEST_TMPDIR" && find . -path ./scoped -prune -o -print | LC_ALL=C sort)

  run run_install_function "HOME='$BATS_TEST_TMPDIR/fakehome'; UTILZ_HOME='$src'; install_verb_install --prefix '$dst'"
  assert_success

  after=$(cd "$BATS_TEST_TMPDIR" && find . -path ./scoped -prune -o -print | LC_ALL=C sort)
  [[ "$before" == "$after" ]] || {
    echo "the filesystem outside the prefix changed:" >&2
    diff <(printf '%s\n' "$before") <(printf '%s\n' "$after") >&2
    return 1
  }

  # And the odd one stays odd: leave a link you did not write alone.
  [[ -L "$localbin/utilz" ]]
  [[ "$(readlink "$localbin/alpha")" == "../../src/bin/utilz" ]]
}
