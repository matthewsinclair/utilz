#!/usr/bin/env bats
# xtrct.bats - Tests for xtrct utility

# Load test helper from core utilz tests
load "../../utilz/test/test_helper.bash"

# ============================================================================
# BASIC TESTS
# ============================================================================

@test "xtrct --help shows usage" {
    run_xtrct --help
    assert_success
    assert_output_contains "Usage"
    assert_output_contains "xtrct"
}

@test "xtrct --version shows version" {
    run_xtrct --version
    assert_success
    assert_output_contains "xtrct"
    assert_output_contains "v"
}

@test "xtrct with unknown option shows error" {
    run_xtrct --invalid-option
    assert_failure
    assert_output_contains "Unknown option"
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

run_xtrct() {
    run "$UTILZ_BIN_DIR/xtrct" "$@"
}

# ============================================================================
# FUNCTIONALITY TESTS
# ============================================================================

# Add your tests here
@test "xtrct basic functionality" {
    skip "Not implemented yet"
}
