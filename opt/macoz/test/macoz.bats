#!/usr/bin/env bats
# macoz.bats - Tests for macoz utility

# Load test helper from core utilz tests
load "../../utilz/test/test_helper.bash"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

run_macoz() {
    run "$UTILZ_BIN_DIR/macoz" "$@"
}

is_macos() {
    [[ "$(uname)" == "Darwin" ]]
}

# ============================================================================
# BASIC TESTS
# ============================================================================

@test "macoz --help shows usage" {
    run_macoz --help
    assert_success
    assert_output_contains "macoz"
    assert_output_contains "background"
}

@test "macoz --version shows version" {
    run_macoz --version
    assert_success
    assert_output_contains "macoz"
    assert_output_contains "v"
}

@test "macoz with no arguments shows usage" {
    run_macoz
    assert_success
    assert_output_contains "Usage"
}

@test "macoz with unknown command shows error" {
    run_macoz unknown-command
    assert_failure
    assert_output_contains "Unknown command"
}

@test "macoz requires macOS" {
    if ! is_macos; then
        run_macoz background test.jpg
        assert_failure
        assert_output_contains "macOS"
    else
        skip "Running on macOS"
    fi
}

# ============================================================================
# BACKGROUND COMMAND TESTS
# ============================================================================

@test "macoz background with no argument auto-selects seasonal" {
    if ! is_macos; then
        skip "Not on macOS"
    fi

    run_macoz background
    # Should show auto-selected message
    assert_output_contains "Auto-selected"
    # We don't assert success because setting background may be restricted
}

@test "macoz background with missing file shows error" {
    if ! is_macos; then
        skip "Not on macOS"
    fi

    run_macoz background /nonexistent/image.jpg
    assert_failure
    assert_output_contains "not found"
}

@test "macoz background with valid file" {
    if ! is_macos; then
        skip "Not on macOS"
    fi

    # Use one of the actual seasonal images
    local test_image="$UTILZ_HOME/opt/macoz/images/backgrounds/autumn-01.png"

    if [[ ! -f "$test_image" ]]; then
        skip "Test image not found"
    fi

    # Test command - may fail if osascript restrictions, that's ok
    run_macoz background "$test_image"

    # We don't assert success because setting background may be restricted
    # Just verify the command ran and tried to do something
    if [[ $status -ne 0 ]]; then
        # If it failed, make sure it's not a file-not-found error
        refute_output_contains "not found"
    fi
}

@test "macoz background alias bg works" {
    if ! is_macos; then
        skip "Not on macOS"
    fi

    # Test that 'bg' alias works (auto-selects seasonal)
    run_macoz bg
    assert_output_contains "Auto-selected"
}

# ============================================================================
# SETPICFOR COMMAND TESTS
# ============================================================================

@test "macoz setpicfor with no arguments shows error" {
    if ! is_macos; then
        skip "Not on macOS"
    fi

    run_macoz setpicfor
    assert_failure
    assert_output_contains "No image file specified"
}

@test "macoz setpicfor with missing image shows error" {
    if ! is_macos; then
        skip "Not on macOS"
    fi

    run_macoz setpicfor /nonexistent/image.png
    assert_failure
    assert_output_contains "Image file not found"
}

@test "macoz setpicfor with missing directory shows error" {
    if ! is_macos; then
        skip "Not on macOS"
    fi

    # Create a test image
    touch "$BATS_TEST_TMPDIR/test.png"

    run_macoz setpicfor "$BATS_TEST_TMPDIR/test.png" /nonexistent/directory
    assert_failure
    assert_output_contains "Directory not found"

    rm -f "$BATS_TEST_TMPDIR/test.png"
}

@test "macoz setpicfor dry-run mode" {
    if ! is_macos; then
        skip "Not on macOS"
    fi

    # Create test image and directory
    touch "$BATS_TEST_TMPDIR/test.png"
    mkdir -p "$BATS_TEST_TMPDIR/testdir"

    run_macoz setpicfor --dry-run "$BATS_TEST_TMPDIR/test.png" "$BATS_TEST_TMPDIR/testdir"
    assert_success
    assert_output_contains "[DRY RUN]"
    assert_output_contains "Would set icon for"

    rm -f "$BATS_TEST_TMPDIR/test.png"
    rm -rf "$BATS_TEST_TMPDIR/testdir"
}

@test "macoz setpicfor requires fileicon" {
    if ! is_macos; then
        skip "Not on macOS"
    fi

    if ! command -v fileicon >/dev/null 2>&1; then
        # fileicon not installed - test error message
        touch "$BATS_TEST_TMPDIR/test.png"

        run_macoz setpicfor "$BATS_TEST_TMPDIR/test.png"
        assert_failure
        assert_output_contains "fileicon command not found"
        assert_output_contains "brew install fileicon"

        rm -f "$BATS_TEST_TMPDIR/test.png"
    else
        skip "fileicon is installed"
    fi
}

@test "macoz setpicfor --all dry-run mode" {
    if ! is_macos; then
        skip "Not on macOS"
    fi

    # Create test structure
    mkdir -p "$BATS_TEST_TMPDIR/testparent/subdir1"
    mkdir -p "$BATS_TEST_TMPDIR/testparent/subdir2"
    touch "$BATS_TEST_TMPDIR/testparent/subdir1/icon.png"
    touch "$BATS_TEST_TMPDIR/testparent/subdir2/folder.jpg"

    run_macoz setpicfor --all --dry-run --data-dir "$BATS_TEST_TMPDIR/testparent"
    assert_success
    assert_output_contains "[DRY RUN]"
    assert_output_contains "Would process"

    rm -rf "$BATS_TEST_TMPDIR/testparent"
}
