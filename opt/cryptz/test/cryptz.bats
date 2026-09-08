#!/usr/bin/env bats
# cryptz.bats - Tests for cryptz utility

# Load test helper from core utilz tests
load "../../utilz/test/test_helper.bash"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# STDIN IS CLOSED FOR EVERY CRYPTZ CALL. cryptz shells out to gpg, and a gpg
# that wants a passphrase will read the terminal if it is given one -- so a
# suite run from an interactive shell blocks on a prompt while the same suite
# in CI passes, which is the worst shape a test can have. `< /dev/null` here
# rather than at each call site: one door, so a test added later inherits it.
run_cryptz() {
  run "$UTILZ_BIN_DIR/cryptz" "$@" < /dev/null
}

# ============================================================================
# BASIC TESTS
# ============================================================================

@test "cryptz --help shows usage" {
  run_cryptz --help
  assert_success
  assert_output_contains "Usage"
  assert_output_contains "cryptz"
  assert_output_contains "encrypt"
  assert_output_contains "decrypt"
}

@test "cryptz --version shows version" {
  run_cryptz --version
  assert_success
  # THE PAIR IS THE FORM, not merely two numbers appearing somewhere.
  # This asserted the bare letter "v" until 2026-09-08 -- an assertion so
  # weak it was satisfied by the "v" in "every" inside a description, which
  # is why five of the ten tests carrying it stayed GREEN through a change
  # that rewrote every one of these lines. ST0015/AC01.
  assert_output_matches "^utilz:[0-9]+\.[0-9]+\.[0-9]+/cryptz:[0-9]+\.[0-9]+\.[0-9]+($|[^0-9.])"
}

@test "cryptz with no arguments shows usage" {
  run_cryptz
  assert_success
  assert_output_contains "Usage"
}

@test "cryptz with unknown command shows error" {
  run_cryptz unknown-command
  assert_failure
  assert_output_contains "Unknown command"
}

# ============================================================================
# ENCRYPT COMMAND TESTS
# ============================================================================

@test "cryptz encrypt with no input shows error" {
  run_cryptz encrypt
  assert_failure
  assert_output_contains "No input file"
}

@test "cryptz encrypt with missing file shows error" {
  run_cryptz encrypt /nonexistent/file.txt
  assert_failure
  assert_output_contains "not found"
}

@test "cryptz encrypt requires gpg" {
  if ! command_exists gpg; then
    run_cryptz encrypt test.txt
    assert_failure
    assert_output_contains "GPG"
  else
    skip "gpg is installed"
  fi
}

# ============================================================================
# DECRYPT COMMAND TESTS
# ============================================================================

@test "cryptz decrypt with no input shows error" {
  run_cryptz decrypt
  assert_failure
  assert_output_contains "No input file"
}

@test "cryptz decrypt with missing file shows error" {
  run_cryptz decrypt /nonexistent/file.gpg
  assert_failure
  assert_output_contains "not found"
}

@test "cryptz decrypt requires gpg" {
  if ! command_exists gpg; then
    run_cryptz decrypt test.gpg
    assert_failure
    assert_output_contains "GPG"
  else
    skip "gpg is installed"
  fi
}

# ============================================================================
# INTEGRATION TESTS
# ============================================================================

@test "cryptz encrypt/decrypt round-trip" {
  # Skip if gpg not configured with keys
  if ! command_exists gpg; then
    skip "gpg not installed"
  fi

  # Check if user has gpg keys configured
  if ! gpg --list-keys >/dev/null 2>&1; then
    skip "gpg keys not configured"
  fi

  # Create test file
  echo "secret message" > test_encrypt.txt

  # Try encrypt (may fail if recipient key not available, that's ok)
  run_cryptz encrypt test_encrypt.txt test_encrypt.txt.gpg

  # THE DECRYPT HALF IS OPT-IN, AND THE REASON IS THAT IT ASSERTED NOTHING.
  # It used to run unconditionally under the comment "decrypt may prompt for
  # passphrase, so we don't assert success" -- which handled the ASSERTION and
  # not the PROMPT. Closing stdin above stops a tty pinentry, but on macOS
  # pinentry-mac opens a GUI dialog that no redirection suppresses, so the
  # suite stopped dead on a password box with nothing to type into it.
  #
  # A call that asserts nothing and can block the suite is pure cost. It runs
  # only when someone has deliberately set up a key that needs no interaction
  # and says so by exporting CRYPTZ_TEST_DECRYPT=1.
  if [[ $status -eq 0 && -n "${CRYPTZ_TEST_DECRYPT:-}" ]]; then
    run_cryptz decrypt test_encrypt.txt.gpg test_decrypted.txt
    assert_success
  fi

  # Cleanup
  rm -f test_encrypt.txt test_encrypt.txt.gpg test_decrypted.txt
}
