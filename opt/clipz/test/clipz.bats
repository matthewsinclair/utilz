#!/usr/bin/env bats
# clipz.bats - Tests for clipz utility

# Load test helper from core utilz tests
load "../../utilz/test/test_helper.bash"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

run_clipz() {
    run "$UTILZ_BIN_DIR/clipz" "$@"
}

# ============================================================================
# BASIC TESTS
# ============================================================================

@test "clipz --help shows usage" {
    run_clipz --help
    assert_success
    assert_output_contains "clipz"
    assert_output_contains "copy"
    assert_output_contains "paste"
}

@test "clipz --version shows version" {
    run_clipz --version
    assert_success
    assert_output_contains "clipz"
    assert_output_contains "v"
}

@test "clipz with no arguments shows usage" {
    run_clipz
    assert_success
    assert_output_contains "Usage"
}

@test "clipz with unknown command shows error" {
    run_clipz unknown-command
    assert_failure
    assert_output_contains "Unknown command"
}

# ============================================================================
# COPY COMMAND TESTS
# ============================================================================

@test "clipz copy with missing file shows error" {
    run_clipz copy /nonexistent/file.txt
    assert_failure
    assert_output_contains "not found"
}

@test "clipz copy from stdin works" {
    run bash -c "echo 'test' | $UTILZ_BIN_DIR/clipz copy"
    assert_success
}

@test "clipz copy from file works" {
    echo "test content" > test_file.txt
    run_clipz copy test_file.txt
    assert_success
    rm -f test_file.txt
}

# ============================================================================
# PASTE COMMAND TESTS
# ============================================================================

@test "clipz paste executes without error" {
    # This test just ensures paste command runs
    # Actual clipboard content varies by system
    run_clipz paste
    assert_success
}

# ============================================================================
# INTEGRATION TESTS
# ============================================================================

@test "clipz copy then paste round-trip" {
    # Copy known content
    echo "round-trip test" | $UTILZ_BIN_DIR/clipz copy

    # Paste and verify
    run_clipz paste
    assert_success
    assert_output_contains "round-trip test"
}
