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
  # gpg is hidden from the PATH cryptz runs under (issue 0084), so the refusal
  # runs on every machine. The input exists, so gpg is the one thing missing.
  local farm
  farm=$(path_without gpg)
  echo "secret" > test.txt
  run env PATH="$farm" "$UTILZ_BIN_DIR/cryptz" encrypt test.txt < /dev/null
  assert_failure
  assert_output_contains "GPG is required for encryption"
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
  # As for encrypt (issue 0084): gpg hidden, the input present.
  local farm
  farm=$(path_without gpg)
  echo "not really ciphertext" > test.gpg
  run env PATH="$farm" "$UTILZ_BIN_DIR/cryptz" decrypt test.gpg < /dev/null
  assert_failure
  assert_output_contains "GPG is required for decryption"
}

# ============================================================================
# INTEGRATION TESTS
# ============================================================================

@test "cryptz encrypt/decrypt round-trip" {
  if ! command_exists gpg; then
    skip "gpg not installed"
  fi

  # THE ROUND TRIP RUNS FOR REAL, ON EVERY MACHINE (issue 0082). It used to run
  # on the user's own keyring, asserted nothing about the encrypt, and made the
  # decrypt opt-in because pinentry-mac could stop the suite on a password box.
  # A home of the test's own, with a throwaway key that needs no passphrase,
  # means no prompt, no key lookup over the network and no user key.
  make_gpg_home
  run gpg --batch --pinentry-mode loopback --passphrase '' \
    --quick-gen-key 'utilz test <utilz-test@example.invalid>' future-default default never < /dev/null
  assert_success
  export CRYPTZ_EMAIL=utilz-test@example.invalid

  echo "secret message" > test_encrypt.txt
  run_cryptz encrypt test_encrypt.txt test_encrypt.txt.gpg
  assert_success
  assert_file_exists test_encrypt.txt.gpg

  run_cryptz decrypt test_encrypt.txt.gpg test_decrypted.txt
  assert_success
  assert_file_contains test_decrypted.txt "secret message"

  # Its daemons go with the home. First the control: the decrypt has just used
  # the home's gpg-agent, so pgrep must find a process naming the home, or the
  # absence below would prove nothing. Then, once the helper's teardown step
  # for gpg has run, none may be left; gpgconf asks the daemons to stop, so
  # they get a few seconds to finish exiting. pgrep's 1 is "none".
  local home="$UTILZ_GPG_HOME" tries=0
  run pgrep -f -- "$home"
  [[ $status -eq 0 ]] || fail "the control failed: no process names $home after the decrypt (pgrep status $status), so pgrep cannot see gpg's daemons here"
  end_gpg_home
  run pgrep -f -- "$home"
  while [[ $status -eq 0 && $tries -lt 50 ]]; do
    sleep 0.1
    tries=$((tries + 1))
    run pgrep -f -- "$home"
  done
  [[ $status -eq 1 ]] || fail "a process still names $home, or pgrep could not run (status $status): $output"
}

# A GPG RUN WITHOUT A HOME OF ITS OWN WRITES NOTHING UNDER HOME (issue 0082).
# The helper points GNUPGHOME at a path that cannot be made, so such a run
# fails by name rather than reaching the user's keyring; a test that wants gpg
# calls make_gpg_home. Run as the round trip ran gpg before 0082, with HOME
# pointed at a scratch home inside the test's dir.
@test "cryptz: gpg without make_gpg_home writes nothing under HOME (issue 0082)" {
  if ! command_exists gpg; then
    skip "gpg not installed"
  fi

  local home="$BATS_TEST_TMPDIR/home"
  mkdir -p "$home"
  echo "secret message" > test_encrypt.txt

  run env HOME="$home" gpg --list-keys < /dev/null
  assert_directory_not_exists "$home/.gnupg"
  assert_failure
  assert_output_contains "call-make_gpg_home"

  run env HOME="$home" "$UTILZ_BIN_DIR/cryptz" encrypt test_encrypt.txt test_encrypt.txt.gpg < /dev/null
  assert_directory_not_exists "$home/.gnupg"
  assert_failure
}
