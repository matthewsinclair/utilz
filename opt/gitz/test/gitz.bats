#!/usr/bin/env bats
# gitz.bats - Tests for gitz utility

# Load test helper from core utilz tests
load "../../utilz/test/test_helper.bash"

# ============================================================================
# BASIC TESTS
# ============================================================================

@test "gitz --help shows usage" {
    run_gitz --help
    assert_success
    assert_output_contains "Usage"
    assert_output_contains "gitz"
}

@test "gitz --version shows version" {
    run_gitz --version
    assert_success
    assert_output_contains "gitz"
    assert_output_contains "v"
}

@test "gitz with unknown option shows error" {
    run_gitz --invalid-option
    assert_failure
    assert_output_contains "Unknown option"
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

run_gitz() {
    run "$UTILZ_BIN_DIR/gitz" "$@"
}

# ============================================================================
# FUNCTIONALITY TESTS
# ============================================================================

# Add your tests here
@test "gitz basic functionality" {
    skip "Not implemented yet"
}
