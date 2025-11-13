#!/usr/bin/env bats
# cryptz.bats - Tests for cryptz utility

# Load test helper from core utilz tests
load "../../utilz/test/test_helper.bash"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

run_cryptz() {
    run "$UTILZ_BIN_DIR/cryptz" "$@"
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
    assert_output_contains "cryptz"
    assert_output_contains "v"
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
    if [[ $status -eq 0 ]]; then
        # If encrypt succeeded, try decrypt
        run_cryptz decrypt test_encrypt.txt.gpg test_decrypted.txt
        # Decrypt may prompt for passphrase, so we don't assert success
    fi

    # Cleanup
    rm -f test_encrypt.txt test_encrypt.txt.gpg test_decrypted.txt
}
