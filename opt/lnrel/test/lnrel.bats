#!/usr/bin/env bats
# lnrel.bats - Tests for lnrel utility

# Load test helper from core utilz tests
load "../../utilz/test/test_helper.bash"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

run_lnrel() {
    run "$UTILZ_BIN_DIR/lnrel" "$@"
}

# Skip tests that need GNU realpath if it's not available
require_gnu_realpath() {
    if command -v grealpath >/dev/null 2>&1; then
        if grealpath -m --relative-to=/ / >/dev/null 2>&1; then
            return 0
        fi
    fi
    if command -v realpath >/dev/null 2>&1; then
        if realpath -m --relative-to=/ / >/dev/null 2>&1; then
            return 0
        fi
    fi
    skip "GNU realpath not available"
}

# ============================================================================
# BASIC TESTS
# ============================================================================

@test "lnrel --help shows usage" {
    run_lnrel --help
    assert_success
    assert_output_contains "Synopsis"
    assert_output_contains "lnrel"
    assert_output_contains "target"
}

@test "lnrel --version shows version" {
    run_lnrel --version
    assert_success
    assert_output_contains "lnrel"
    assert_output_contains "v"
}

@test "lnrel with unknown option shows error" {
    run_lnrel --invalid-option
    assert_failure
    assert_output_contains "Unknown option"
}

@test "lnrel with no arguments shows error" {
    run_lnrel
    assert_failure
    assert_output_contains "No target"
}

@test "lnrel with too many arguments shows error" {
    require_gnu_realpath
    run_lnrel one two three
    assert_failure
    assert_output_contains "Too many arguments"
}

# ============================================================================
# FUNCTIONALITY TESTS
# ============================================================================

@test "lnrel two-arg form creates relative symlink" {
    require_gnu_realpath

    # Create a target file
    mkdir -p "$BATS_TEST_TMPDIR/src"
    echo "hello" > "$BATS_TEST_TMPDIR/src/file.txt"

    # Create symlink
    run_lnrel "$BATS_TEST_TMPDIR/src/file.txt" "$BATS_TEST_TMPDIR/link.txt"
    assert_success

    # Verify symlink exists
    [[ -L "$BATS_TEST_TMPDIR/link.txt" ]]

    # Verify the link target is relative (not starting with /)
    local link_target
    link_target="$(readlink "$BATS_TEST_TMPDIR/link.txt")"
    [[ "$link_target" != /* ]]

    # Verify the symlink resolves to the correct file
    [[ "$(cat "$BATS_TEST_TMPDIR/link.txt")" == "hello" ]]
}

@test "lnrel one-arg form defaults to basename in cwd" {
    require_gnu_realpath

    # Create a target file
    mkdir -p "$BATS_TEST_TMPDIR/src"
    echo "world" > "$BATS_TEST_TMPDIR/src/data.txt"

    # Run from the test temp dir (setup already cd'd there)
    run_lnrel "$BATS_TEST_TMPDIR/src/data.txt"
    assert_success

    # Verify symlink exists in cwd with basename
    [[ -L "$BATS_TEST_TMPDIR/data.txt" ]]
}

@test "lnrel works with non-existent target (dangling symlink)" {
    require_gnu_realpath

    # Create symlink to non-existent target
    run_lnrel "$BATS_TEST_TMPDIR/does-not-exist.txt" "$BATS_TEST_TMPDIR/dangling.txt"
    assert_success

    # Verify symlink exists (even though target doesn't)
    [[ -L "$BATS_TEST_TMPDIR/dangling.txt" ]]

    # Verify the link target is relative
    local link_target
    link_target="$(readlink "$BATS_TEST_TMPDIR/dangling.txt")"
    [[ "$link_target" != /* ]]
}

@test "lnrel errors when link directory does not exist" {
    require_gnu_realpath

    echo "target" > "$BATS_TEST_TMPDIR/target.txt"

    run_lnrel "$BATS_TEST_TMPDIR/target.txt" "$BATS_TEST_TMPDIR/nodir/link.txt"
    assert_failure
    assert_output_contains "does not exist"
}

@test "lnrel cross-directory relative path resolves correctly" {
    require_gnu_realpath

    # Create directory structure
    mkdir -p "$BATS_TEST_TMPDIR/a/b"
    mkdir -p "$BATS_TEST_TMPDIR/c/d"
    echo "cross" > "$BATS_TEST_TMPDIR/a/b/target.txt"

    # Create symlink in a different directory tree
    run_lnrel "$BATS_TEST_TMPDIR/a/b/target.txt" "$BATS_TEST_TMPDIR/c/d/link.txt"
    assert_success

    # Verify the symlink resolves to the correct file
    [[ "$(cat "$BATS_TEST_TMPDIR/c/d/link.txt")" == "cross" ]]

    # Verify link is relative
    local link_target
    link_target="$(readlink "$BATS_TEST_TMPDIR/c/d/link.txt")"
    [[ "$link_target" != /* ]]
    # Should contain ../ to navigate up
    [[ "$link_target" == *../* ]]
}

@test "lnrel strips backslash escapes from paths" {
    require_gnu_realpath

    # Create target with spaces in name (simulates tab-completion in quotes)
    mkdir -p "$BATS_TEST_TMPDIR/src dir"
    echo "escaped" > "$BATS_TEST_TMPDIR/src dir/my file.txt"

    # Pass path with backslash-escaped spaces (as if tab-completed inside quotes)
    run_lnrel "$BATS_TEST_TMPDIR/src\ dir/my\ file.txt" "$BATS_TEST_TMPDIR/link.txt"
    assert_success

    # Verify the symlink resolves to the actual file
    [[ -L "$BATS_TEST_TMPDIR/link.txt" ]]
    [[ "$(cat "$BATS_TEST_TMPDIR/link.txt")" == "escaped" ]]

    # Verify the link target has no backslashes
    local link_target
    link_target="$(readlink "$BATS_TEST_TMPDIR/link.txt")"
    [[ "$link_target" != *\\* ]]
}

@test "lnrel fails when link path already exists" {
    require_gnu_realpath

    echo "target" > "$BATS_TEST_TMPDIR/target.txt"
    echo "existing" > "$BATS_TEST_TMPDIR/existing.txt"

    run_lnrel "$BATS_TEST_TMPDIR/target.txt" "$BATS_TEST_TMPDIR/existing.txt"
    assert_failure
}
