#!/usr/bin/env bats
# pdf2md.bats - Tests for pdf2md utility

# Load test helper from core utilz tests
load "../../utilz/test/test_helper.bash"

# ============================================================================
# BASIC TESTS
# ============================================================================

@test "pdf2md --help shows usage" {
    run_pdf2md --help
    assert_success
    assert_output_contains "Usage"
    assert_output_contains "pdf2md"
}

@test "pdf2md --version shows version" {
    run_pdf2md --version
    assert_success
    assert_output_contains "pdf2md"
    assert_output_contains "v"
}

@test "pdf2md with unknown option shows error" {
    run_pdf2md --invalid-option
    assert_failure
    assert_output_contains "Unknown option"
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

run_pdf2md() {
    run "$UTILZ_BIN_DIR/pdf2md" "$@"
}

# ============================================================================
# FUNCTIONALITY TESTS
# ============================================================================

# Add your tests here
@test "pdf2md basic functionality" {
    skip "Not implemented yet"
}
