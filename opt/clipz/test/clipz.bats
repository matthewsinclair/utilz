#!/usr/bin/env bats
# clipz.bats - Tests for clipz utility

# Load test helper from core utilz tests
load "../../utilz/test/test_helper.bash"

# ============================================================================
# BASIC TESTS
# ============================================================================

@test "clipz --help shows usage" {
    run_clipz --help
    assert_success
    assert_output_contains "Usage"
    assert_output_contains "clipz"
}

@test "clipz --version shows version" {
    run_clipz --version
    assert_success
    assert_output_contains "clipz"
    assert_output_contains "v"
}

@test "clipz with unknown option shows error" {
    run_clipz --invalid-option
    assert_failure
    assert_output_contains "Unknown option"
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

run_clipz() {
    run "$UTILZ_BIN_DIR/clipz" "$@"
}

# ============================================================================
# FUNCTIONALITY TESTS
# ============================================================================

# Add your tests here
@test "clipz basic functionality" {
    skip "Not implemented yet"
}
