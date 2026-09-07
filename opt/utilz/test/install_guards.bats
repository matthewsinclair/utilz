#!/usr/bin/env bats
# install_guards.bats - ST0014/WP-04: the guards that only exist in an install
#
# AT10 (AC09, the prez shim), AT13 (AC13, utilz test), AT14 (AC14, the venv),
# AT15 (AC15, an inherited UTILZ_HOME), and AC12's provenance at the prompt.
#
# THE INSTALL HERE IS BUILT BY COPYING, NOT BY PUBLISHING, AND THAT IS
# DELIBERATE. install_copy_owned + install_manifest_write produce the same tree
# `utilz install` produces, without going through the dirty gate -- so this
# suite runs against a working checkout instead of only against a committed
# one. The gates themselves are WP-02's and are covered in install.bats; what
# is under test here is how the resulting tree BEHAVES.

load "test_helper.bash"

run_install_function() {
  bash -c "source '$UTILZ_HOME/opt/utilz/lib/common.sh'; source '$UTILZ_HOME/opt/utilz/lib/install.sh'; $*"
}

setup_file() {
  export GUARD_SRC="$UTILZ_HOME"
  export GUARD_INSTALL="${BATS_FILE_TMPDIR:-/tmp}/guard-install"
  rm -rf "$GUARD_INSTALL"

  bash -c "
    source '$UTILZ_HOME/opt/utilz/lib/common.sh'
    source '$UTILZ_HOME/opt/utilz/lib/install.sh'
    install_copy_owned '$UTILZ_HOME' '$GUARD_INSTALL' >/dev/null
    install_manifest_write '$UTILZ_HOME' '$GUARD_INSTALL/manifest.sha256'
  " || return 1
}

teardown_file() {
  [[ -n "${GUARD_INSTALL:-}" ]] && rm -rf "$GUARD_INSTALL"
  return 0
}

# ============================================================================
# AT10 (AC09) - prez runs from the shipped binary and the shim refuses to build
# ============================================================================

@test "the install runs prez from the binary it shipped" {
  assert_file_exists "$GUARD_INSTALL/opt/prez/crate/target/release/prez"
  # The crate SOURCE is not shipped: include_str! compiles themes/ and assets/
  # into the binary, so the crate is build-time only.
  assert_directory_not_exists "$GUARD_INSTALL/opt/prez/crate/src"

  run env -u UTILZ_HOME "$GUARD_INSTALL/opt/prez/prez" --version
  assert_success
  assert_output_contains "prez"
}

@test "the install shim REFUSES to build rather than falling back to one" {
  # AC09's "refuses rather than falls back". Today this is satisfied BY
  # ACCIDENT: with no crate shipped, prez_is_stale's find errors on every
  # path, 2>/dev/null || true swallows it, and the empty result reads as
  # "not stale". A suppressed error standing in for a decision passes until
  # someone tidies the suppression away. Remove the binary and the accident
  # runs out: the shim must name the refusal, not reach for cargo.
  local sandbox="$BATS_TEST_TMPDIR/no-binary"
  cp -R "$GUARD_INSTALL" "$sandbox"
  rm -f "$sandbox/opt/prez/crate/target/release/prez"

  run env -u UTILZ_HOME "$sandbox/opt/prez/prez" --version
  assert_failure
  assert_output_contains "install"
  refute_output_contains "building"
  refute_output_contains "first use"
}

@test "the install shim IGNORES CARGO_TARGET_DIR" {
  # The shim honours the variable deliberately in a source tree. An install
  # resolves its binary at a path fixed at publish time, so a caller who
  # happens to have it exported would send the install looking somewhere it
  # never wrote. Same variable, opposite treatment; the manifest is the
  # discriminator.
  run env -u UTILZ_HOME CARGO_TARGET_DIR="$BATS_TEST_TMPDIR/junk" \
    "$GUARD_INSTALL/opt/prez/prez" --version
  assert_success
  assert_output_contains "prez"
}

@test "the SOURCE shim still honours CARGO_TARGET_DIR" {
  # BEHAVIOURAL, not a grep over the source file. A grep passes whether or not
  # the variable is honoured -- it only proves the string is present, which is
  # the check-that-measures-nothing shape.
  #
  # Point the variable at an empty directory and take cargo off PATH: the shim
  # must look in the junk directory, find no binary there, and reach for cargo.
  # A shim that IGNORED the variable would find the crate-local binary and exec
  # it, and this test would see prez's own version output instead of a refusal.
  mkdir -p "$BATS_TEST_TMPDIR/empty-target"

  run env PATH="/usr/bin:/bin" UTILZ_HOME="$GUARD_SRC" \
    CARGO_TARGET_DIR="$BATS_TEST_TMPDIR/empty-target" \
    "$GUARD_SRC/opt/prez/prez" --version
  assert_failure
  assert_output_contains "cargo"
  refute_output_contains "prez 1."
}

# ============================================================================
# AT13 (AC13) - utilz test refuses from an install
# ============================================================================

@test "utilz test refuses from an install tree and names the source tree" {
  run env UTILZ_HOME="$GUARD_INSTALL" "$GUARD_INSTALL/bin/utilz" test
  assert_failure
  assert_output_contains "cannot run from an install tree"
  # AT13: the message NAMES the source tree as where to run it. Asserting the
  # instruction rather than the bare word, so a message that merely mentions
  # the source in passing would not satisfy it.
  assert_output_contains "Run it from the Utilz SOURCE tree"
}

@test "the utilz test refusal ran nothing: the manifest still verifies" {
  # The suite mutates $UTILZ_HOME/bin, which is why it is not concurrency-safe.
  # A refusal that ran anything first has already rewritten the very files the
  # manifest checksums, and the install would then report drift nobody caused.
  env UTILZ_HOME="$GUARD_INSTALL" "$GUARD_INSTALL/bin/utilz" test >/dev/null 2>&1 || true

  run run_install_function "install_manifest_check '$GUARD_INSTALL'"
  assert_success
  assert_output ""
}

# ============================================================================
# AT14 (AC14) - a venv built inside the install is not drift
# ============================================================================

@test "a venv created inside the install is not reported as drift" {
  local sandbox="$BATS_TEST_TMPDIR/venv-install"
  cp -R "$GUARD_INSTALL" "$sandbox"

  # The real article at the real path: pdf2md sets VENV_DIR="$LIB_DIR/.venv"
  # off SCRIPT_DIR, so in an install it lands in the install. Gitignored, so
  # git ls-files never named it and the manifest never recorded it.
  python3 -m venv --without-pip "$sandbox/opt/pdf2md/lib/.venv"
  assert_file_exists "$sandbox/opt/pdf2md/lib/.venv/pyvenv.cfg"

  run run_install_function "install_manifest_check '$sandbox'"
  assert_success
  assert_output ""
}

@test "and an edited OWNED file IS still reported" {
  # One leg without the other proves only that the check is silent.
  local sandbox="$BATS_TEST_TMPDIR/venv-drift"
  cp -R "$GUARD_INSTALL" "$sandbox"
  python3 -m venv --without-pip "$sandbox/opt/pdf2md/lib/.venv"
  printf '\n# hand edit\n' >> "$sandbox/opt/pdf2md/pdf2md"

  run run_install_function "install_manifest_check '$sandbox'"
  assert_failure
  assert_output_contains "modified"
  assert_output_contains "opt/pdf2md/pdf2md"
}

# ============================================================================
# AT15 (AC15) - an inherited UTILZ_HOME is ANNOUNCED, then HONOURED
# ============================================================================

@test "an inherited UTILZ_HOME naming a different tree is announced and honoured" {
  echo "PREFIX-MARKER-9.9.9" > "$GUARD_INSTALL/VERSION"

  run env UTILZ_HOME="$GUARD_SRC" "$GUARD_INSTALL/bin/utilz" version
  assert_success
  # Honoured: the SOURCE version comes back, not the marker.
  assert_output_contains "2."
  refute_output_contains "PREFIX-MARKER"
  # Announced: the divergence is stated rather than left silent.
  assert_output_contains "UTILZ_HOME"
}

@test "with UTILZ_HOME unset the install answers and nothing is announced" {
  echo "PREFIX-MARKER-9.9.9" > "$GUARD_INSTALL/VERSION"

  run --separate-stderr env -u UTILZ_HOME "$GUARD_INSTALL/bin/utilz" version
  assert_success
  assert_output_contains "PREFIX-MARKER-9.9.9"
  [[ -z "$stderr" ]] || {
    echo "stderr was not silent for an agreeing run:" >&2
    printf '%s\n' "$stderr" >&2
    return 1
  }
}

@test "UTILZ_HOME pointing at the tree itself produces no announcement" {
  # The bats harness's own shape: test_helper.bash:20 exports UTILZ_HOME to
  # the tree $0 already lives in, so the suite must see no new output.
  run --separate-stderr env UTILZ_HOME="$GUARD_INSTALL" "$GUARD_INSTALL/bin/utilz" version
  assert_success
  [[ -z "$stderr" ]] || {
    echo "stderr was not silent when the trees agree:" >&2
    printf '%s\n' "$stderr" >&2
    return 1
  }
}

@test "the announcement is on STDERR: stdout is byte-identical to the unset run" {
  # A caller parsing utilz output must not gain a line it did not have.
  echo "PREFIX-MARKER-9.9.9" > "$GUARD_INSTALL/VERSION"

  run --separate-stderr env -u UTILZ_HOME "$GUARD_INSTALL/bin/utilz" version
  local unset_stdout="$output"

  run --separate-stderr env UTILZ_HOME="$GUARD_INSTALL" "$GUARD_INSTALL/bin/utilz" version
  local agreeing_stdout="$output"

  [[ "$unset_stdout" == "$agreeing_stdout" ]] || {
    echo "stdout differed between the unset run and the agreeing run" >&2
    diff <(printf '%s\n' "$unset_stdout") <(printf '%s\n' "$agreeing_stdout") >&2
    return 1
  }

  # And the diverging run announces on stderr while stdout stays clean of it.
  run --separate-stderr env UTILZ_HOME="$GUARD_SRC" "$GUARD_INSTALL/bin/utilz" version
  printf '%s\n' "$stderr" | grep -q "UTILZ_HOME" || {
    echo "the divergence was not announced on stderr" >&2
    return 1
  }
  printf '%s\n' "$output" | grep -q "UTILZ_HOME" && {
    echo "the announcement leaked onto stdout" >&2
    return 1
  }
  return 0
}

# ============================================================================
# AC12 - the two trees are told apart at the prompt
# ============================================================================

@test "utilz version tells an install from a source tree, and names the commit" {
  run env -u UTILZ_HOME "$GUARD_INSTALL/bin/utilz" version
  assert_success
  assert_output_contains "installed"
  assert_output_contains "$GUARD_INSTALL"

  local commit
  commit=$(git -C "$GUARD_SRC" rev-parse HEAD)
  assert_output_contains "${commit:0:7}"

  run env -u UTILZ_HOME "$GUARD_SRC/bin/utilz" version
  assert_success
  assert_output_contains "source"
  refute_output_contains "installed at"
}
