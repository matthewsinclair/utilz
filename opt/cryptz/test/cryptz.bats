#!/usr/bin/env bats
# cryptz.bats - Tests for cryptz utility

# Load test helper from core utilz tests
load "../../utilz/test/test_helper.bash"

# ============================================================================
# BASIC TESTS
# ============================================================================

@test "cryptz --help shows usage" {
    run_cryptz --help
    assert_success
    assert_output_contains "Usage"
    assert_output_contains "cryptz"
}

@test "cryptz --version shows version" {
    run_cryptz --version
    assert_success
    assert_output_contains "cryptz"
    assert_output_contains "v"
}

@test "cryptz with unknown option shows error" {
    run_cryptz --invalid-option
    assert_failure
    assert_output_contains "Unknown option"
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

run_cryptz() {
    run "$UTILZ_BIN_DIR/cryptz" "$@"
}

# ============================================================================
# FUNCTIONALITY TESTS
# ============================================================================

# Add your tests here
@test "cryptz basic functionality" {
    skip "Not implemented yet"
}
