#!/usr/bin/env bats
# retry.bats - Tests for retry utility

# Load test helper from core utilz tests
load "../../utilz/test/test_helper.bash"

# ============================================================================
# BASIC TESTS
# ============================================================================

@test "retry --help shows usage" {
    run_retry --help
    assert_success
    assert_output_contains "Usage"
    assert_output_contains "retry"
}

@test "retry --version shows version" {
    run_retry --version
    assert_success
    assert_output_contains "retry"
    assert_output_contains "v"
}

@test "retry with unknown option shows error" {
    run_retry --invalid-option
    assert_failure
    assert_output_contains "Unknown option"
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

run_retry() {
    run "$UTILZ_BIN_DIR/retry" "$@"
}

# ============================================================================
# FUNCTIONALITY TESTS
# ============================================================================

# Add your tests here
@test "retry basic functionality" {
    skip "Not implemented yet"
}
