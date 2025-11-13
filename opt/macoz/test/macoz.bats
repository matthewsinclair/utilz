#!/usr/bin/env bats
# macoz.bats - Tests for macoz utility

# Load test helper from core utilz tests
load "../../utilz/test/test_helper.bash"

# ============================================================================
# BASIC TESTS
# ============================================================================

@test "macoz --help shows usage" {
    run_macoz --help
    assert_success
    assert_output_contains "Usage"
    assert_output_contains "macoz"
}

@test "macoz --version shows version" {
    run_macoz --version
    assert_success
    assert_output_contains "macoz"
    assert_output_contains "v"
}

@test "macoz with unknown option shows error" {
    run_macoz --invalid-option
    assert_failure
    assert_output_contains "Unknown option"
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

run_macoz() {
    run "$UTILZ_BIN_DIR/macoz" "$@"
}

# ============================================================================
# FUNCTIONALITY TESTS
# ============================================================================

# Add your tests here
@test "macoz basic functionality" {
    skip "Not implemented yet"
}
