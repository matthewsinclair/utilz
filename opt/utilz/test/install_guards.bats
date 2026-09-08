#!/usr/bin/env bats
# install_guards.bats - ST0014/WP-04: the guards that only exist in an install
#
# AT10 (AC09, the prez shim), AT13 (AC13, utilz test), AT14 (AC18, the venv),
# AT15 (AC19, an inherited UTILZ_HOME), and AC12's provenance at the prompt.
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

# THE SHARED INSTALL IS READ-ONLY. A test that needs to mutate one copies it
# first. This is not fastidiousness: the AT15 legs used to write a marker
# VERSION straight into it, and every test after them then inherited an install
# whose VERSION no longer matched its manifest -- which made doctor's integrity
# check fail in a full run and pass in isolation. Measured 8 Sep.
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
  # AT13: the message NAMES the source tree as where to run it -- and NAMES
  # means the literal path, not a description of which tree to go and find.
  # This asserted the sentence "Run it from the Utilz SOURCE tree", which a
  # message can satisfy while leaving the reader to work out where that is.
  # The manifest records source-tree, so the refusal prints a command that can
  # be pasted, and the assertion is now the PATH plus the instruction built
  # from it. A message mentioning the source in passing still fails.
  assert_output_contains "$GUARD_SRC"
  assert_output_contains "cd $GUARD_SRC && utilz test"
}

@test "AT13: the refusal falls back to prose when the manifest predates source-tree" {
  # An install published before source-tree existed carries no such row. The
  # refusal must still say where to go rather than printing an empty path --
  # the failure mode a naive awk-and-interpolate would produce, silently.
  grep -v $'^source-tree\t' "$GUARD_INSTALL/manifest.sha256" > "$GUARD_INSTALL/manifest.tmp"
  mv "$GUARD_INSTALL/manifest.tmp" "$GUARD_INSTALL/manifest.sha256"

  run env UTILZ_HOME="$GUARD_INSTALL" "$GUARD_INSTALL/bin/utilz" test
  assert_failure
  assert_output_contains "cannot run from an install tree"
  assert_output_contains "Run it from the Utilz SOURCE tree"
  # And specifically NOT a dangling instruction with nothing after cd.
  refute_output_contains "cd  && utilz test"
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
# AT14 (AC18) - a venv built inside the install is not drift
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
# AT15 (AC19) - an inherited UTILZ_HOME has NO EFFECT on the dispatcher
# ============================================================================
#
# These legs assert the OPPOSITE of what this row used to. hv reversed the
# honour-and-announce ruling on 2026-09-08: if it can find the dispatcher on
# PATH it can work everything else out from there, so no environment variable
# is needed at all.
#
# The two tests that stood here -- an inherited value being announced, and the
# announcement landing on stderr -- are DELETED rather than adapted. They were
# the only divergent dispatcher invocations in the whole tree, which made them
# a behaviour whose only consumer was its own test. A passing test for deleted
# behaviour is the worst artefact of a change like this.

@test "AT15: an inherited UTILZ_HOME has no effect -- the marker comes back" {
  local inst="$BATS_TEST_TMPDIR/at15-a"
  cp -R "$GUARD_INSTALL" "$inst"
  echo "PREFIX-MARKER-9.9.9" > "$inst/VERSION"

  run env UTILZ_HOME="$GUARD_SRC" "$inst/bin/utilz" version
  assert_success
  assert_output_contains "PREFIX-MARKER-9.9.9"
  # The source's version must NOT come back: honouring the inherited value is
  # exactly what was removed.
  refute_output_contains "utilz v2."
}

@test "AT15: stderr is SILENT -- there is no announcement to make" {
  # Asserted as empty rather than inferred from stdout being right. A run that
  # got the correct answer AND printed four lines of explanation would pass an
  # stdout-only check while being the behaviour this row deleted.
  #
  # MEASURED: this leg does NOT bite against a dispatcher that silently
  # honours the inherited value -- legs 1 and 3 catch that one. It bites only
  # against re-adding the ANNOUNCEMENT. The three legs divide the space and
  # none of them is redundant.
  local inst="$BATS_TEST_TMPDIR/at15-b"
  cp -R "$GUARD_INSTALL" "$inst"
  echo "PREFIX-MARKER-9.9.9" > "$inst/VERSION"

  run --separate-stderr env UTILZ_HOME="$GUARD_SRC" "$inst/bin/utilz" version
  assert_success
  [[ -z "$stderr" ]] || {
    echo "stderr was not silent under a divergent UTILZ_HOME:" >&2
    printf '%s\n' "$stderr" >&2
    return 1
  }
}

@test "AT15: a DISPATCHED utility answers from the prefix too" {
  # This is the leg that proves the dispatcher EXPORTED the derived value
  # rather than merely using it locally. A dispatcher that fixed its own
  # resolution but left the stale value in the environment would pass the two
  # legs above and hand every child the wrong tree.
  local inst="$BATS_TEST_TMPDIR/at15-c"
  cp -R "$GUARD_INSTALL" "$inst"
  echo "PREFIX-MARKER-9.9.9" > "$inst/VERSION"
  printf 'It is important to note that this delves into the tapestry.\n' \
    > "$BATS_TEST_TMPDIR/deck.txt"

  run env UTILZ_HOME="$GUARD_SRC" "$inst/bin/cleanz" --detrope "$BATS_TEST_TMPDIR/deck.txt"
  assert_success
  assert_output_contains "Trope Analysis"

  # And the child sees the prefix, not the inherited source.
  run env UTILZ_HOME="$GUARD_SRC" "$inst/bin/utilz" doctor
  assert_output_contains "UTILZ_HOME=$inst"
  refute_output_contains "UTILZ_HOME=$GUARD_SRC"
}

# ============================================================================
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

# ============================================================================
# doctor's install-integrity check (vc's finding, 2026-09-08)
# ============================================================================

@test "doctor reports a clean install as matching its manifest" {
  # The manifest checker had no user-facing surface: it could only be reached
  # by sourcing the library, so an operator had no way to ask whether their
  # install still matched what was published.
  local sandbox="$BATS_TEST_TMPDIR/d7-clean"
  cp -R "$GUARD_INSTALL" "$sandbox"

  run env -u UTILZ_HOME "$sandbox/bin/utilz" doctor
  assert_output_contains "Checking install integrity"
  assert_output_contains "Install matches its manifest"
}

@test "doctor names every drifted path and the remedy" {
  local sandbox="$BATS_TEST_TMPDIR/d7-drift"
  cp -R "$GUARD_INSTALL" "$sandbox"
  printf '\n# hand edit\n' >> "$sandbox/opt/gitz/gitz"
  rm "$sandbox/bin/cleanz"
  cp "$sandbox/bin/utilz" "$sandbox/bin/cleanz"

  run env -u UTILZ_HOME "$sandbox/bin/utilz" doctor
  assert_failure
  assert_output_contains "2 owned path(s) differ"
  assert_output_contains "modified"
  assert_output_contains "opt/gitz/gitz"
  assert_output_contains "not-a-link"
  assert_output_contains "bin/cleanz"
  assert_output_contains "utilz upgrade"
}

@test "doctor says NOT APPLICABLE in a source tree rather than skipping" {
  # "nothing to check" and "checked, clean" must not render as the same line.
  # A skipped check that prints nothing looks exactly like a passing one.
  run env -u UTILZ_HOME "$GUARD_SRC/bin/utilz" doctor
  assert_output_contains "Checking install integrity"
  assert_output_contains "Not an install tree"
  refute_output_contains "Install matches its manifest"
}
