#!/usr/bin/env bash
# test_helper.bash - Common test utilities for Utilz framework tests
#
# This file provides helper functions for BATS tests, including:
# - Setup/teardown for test isolation
# - Assertion functions for test validation
# - Utility functions for running Utilz commands
# - Test data creation helpers
#
# Usage: Load this file at the top of each .bats test file:
#   load "test_helper.bash"

# ============================================================================
# ENVIRONMENT SETUP
# ============================================================================

# Determine UTILZ_HOME from this script's location
# This script is at: $UTILZ_HOME/opt/utilz/test/test_helper.bash
UTILZ_PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
export UTILZ_HOME="$UTILZ_PROJECT_ROOT"
export UTILZ_BIN_DIR="$UTILZ_HOME/bin"
export UTILZ_TEST_DIR="$UTILZ_HOME/opt/utilz/test"

# Set PATH to include Utilz binaries
export PATH="$UTILZ_BIN_DIR:$PATH"

# Disable colors in tests for consistent output
export NO_COLOR=1
export TERM=dumb

# ============================================================================
# SETUP AND TEARDOWN
# ============================================================================

# Per-file setup - runs once before all tests in a file
setup_file() {
    # Create a temporary directory for this test file
    export UTILZ_TEST_TMPDIR="${BATS_FILE_TMPDIR:-/tmp}/utilz-test-$$"
    mkdir -p "$UTILZ_TEST_TMPDIR"
}

# Per-file teardown - runs once after all tests in a file
teardown_file() {
    # Clean up temporary directory
    if [[ -n "$UTILZ_TEST_TMPDIR" && -d "$UTILZ_TEST_TMPDIR" ]]; then
        rm -rf "$UTILZ_TEST_TMPDIR"
    fi
}

# Per-test setup - runs before each test
setup() {
    # Create an isolated temporary directory for this specific test
    # Important: Create it OUTSIDE the Utilz project to avoid pollution
    export BATS_TEST_TMPDIR="${BATS_TMPDIR:-/tmp}/utilz-test-$(date +%s)-$$-$RANDOM"
    mkdir -p "$BATS_TEST_TMPDIR"

    # Save original working directory
    export ORIGINAL_PWD="$(pwd)"

    # Change to test temp directory
    cd "$BATS_TEST_TMPDIR"
}

# Per-test teardown - runs after each test
teardown() {
    # Return to original directory
    if [[ -n "$ORIGINAL_PWD" && -d "$ORIGINAL_PWD" ]]; then
        cd "$ORIGINAL_PWD"
    fi

    # Clean up test temporary directory
    if [[ -n "$BATS_TEST_TMPDIR" && -d "$BATS_TEST_TMPDIR" ]]; then
        rm -rf "$BATS_TEST_TMPDIR"
    fi
}

# ============================================================================
# EXECUTION HELPERS
# ============================================================================

# Run the utilz command with arguments
# Usage: run_utilz help
#        run_utilz doctor
run_utilz() {
    run "$UTILZ_BIN_DIR/utilz" "$@"
}

# Run a specific utility command (via symlink)
# Usage: run_utility mdagg --help
run_utility() {
    local utility_name="$1"
    shift
    run "$UTILZ_BIN_DIR/$utility_name" "$@"
}

# Run mdagg specifically
# Usage: run_mdagg "*.md" -o output.md
run_mdagg() {
    run "$UTILZ_BIN_DIR/mdagg" "$@"
}

# ============================================================================
# TEST DATA CREATION
# ============================================================================

# Create a minimal test utility for testing the dispatcher
# Usage: create_test_utility "myutil"
create_test_utility() {
    local util_name="$1"
    local util_dir="$UTILZ_HOME/opt/$util_name"
    local util_script="$util_dir/$util_name"

    # Create utility directory
    mkdir -p "$util_dir"

    # Create minimal utility script
    cat > "$util_script" <<'EOF'
#!/usr/bin/env bash
echo "Test utility invoked with args: $@"
exit 0
EOF

    chmod +x "$util_script"

    # Create help file
    cat > "$UTILZ_HOME/help/$util_name.md" <<EOF
# $util_name

**Version**: 1.0.0

Test utility for testing purposes.
EOF

    # Create symlink
    ln -sf utilz "$UTILZ_BIN_DIR/$util_name"

    echo "$util_name"
}

# Remove a test utility
# Usage: remove_test_utility "myutil"
remove_test_utility() {
    local util_name="$1"

    rm -f "$UTILZ_BIN_DIR/$util_name"
    rm -rf "$UTILZ_HOME/opt/$util_name"
    rm -f "$UTILZ_HOME/help/$util_name.md"
}

# Create markdown files for testing
# Usage: create_markdown_files 3
#   Creates: test1.md, test2.md, test3.md
create_markdown_files() {
    local count="$1"

    for i in $(seq 1 "$count"); do
        cat > "test$i.md" <<EOF
# Test File $i

This is test file number $i.

## Content

Some content here for testing purposes.
EOF
    done
}

# Create numbered markdown files for natural sort testing
# Usage: create_numbered_markdown_files
#   Creates: 01-chapter.md, 02-chapter.md, 10-chapter.md
create_numbered_markdown_files() {
    cat > "01-chapter.md" <<'EOF'
# Chapter 1
First chapter content.
EOF

    cat > "02-chapter.md" <<'EOF'
# Chapter 2
Second chapter content.
EOF

    cat > "10-chapter.md" <<'EOF'
# Chapter 10
Tenth chapter content.
EOF
}

# Create a markdown file with YAML frontmatter
# Usage: create_markdown_with_frontmatter "test.md"
create_markdown_with_frontmatter() {
    local filename="$1"

    cat > "$filename" <<'EOF'
---
title: "Test Document"
author: "Test Author"
date: 2025-01-12
---

# Test Document

This document has YAML frontmatter.
EOF
}

# Create a markdown file with back links
# Usage: create_markdown_with_backlinks "test.md"
create_markdown_with_backlinks() {
    local filename="$1"

    cat > "$filename" <<'EOF'
[← Back to Index](index.md)

# Test Document

This document has navigation back links.

[↑ Top](#) | [← Previous](prev.md)
EOF
}

# Create a YAML config file for mdagg
# Usage: create_mdagg_yaml_config "config.yaml"
create_mdagg_yaml_config() {
    local filename="$1"

    cat > "$filename" <<'EOF'
settings:
  page_breaks: true
  section_dividers: true
  strip_back_links: false

files:
  - file: "test1.md"
    title: "First Test"
  - file: "test2.md"
    title: "Second Test"
EOF
}

# ============================================================================
# ASSERTION HELPERS
# ============================================================================

# Assert command succeeded (exit code 0)
assert_success() {
    if [[ "$status" -ne 0 ]]; then
        fail "Expected success (exit 0) but got exit code: $status\nOutput: $output"
    fi
}

# Assert command failed (exit code non-zero)
assert_failure() {
    if [[ "$status" -eq 0 ]]; then
        fail "Expected failure (non-zero exit) but got exit code 0\nOutput: $output"
    fi
}

# Assert command failed with specific exit code
# Usage: assert_exit_code 1
assert_exit_code() {
    local expected_code="$1"
    if [[ "$status" -ne "$expected_code" ]]; then
        fail "Expected exit code $expected_code but got: $status\nOutput: $output"
    fi
}

# Assert output contains a string
# Usage: assert_output_contains "expected text"
assert_output_contains() {
    local expected="$1"
    if [[ "$output" != *"$expected"* ]]; then
        fail "Expected output to contain: '$expected'\nActual output:\n$output"
    fi
}

# Assert output does NOT contain a string
# Usage: refute_output_contains "unexpected text"
refute_output_contains() {
    local unexpected="$1"
    if [[ "$output" == *"$unexpected"* ]]; then
        fail "Expected output NOT to contain: '$unexpected'\nActual output:\n$output"
    fi
}

# Assert exact output match
# Usage: assert_output "exact expected output"
assert_output() {
    local expected="$1"
    if [[ "$output" != "$expected" ]]; then
        fail "Expected output:\n$expected\n\nActual output:\n$output"
    fi
}

# Assert output matches regex
# Usage: assert_output_matches "^Error:.*"
assert_output_matches() {
    local pattern="$1"
    if [[ ! "$output" =~ $pattern ]]; then
        fail "Expected output to match pattern: '$pattern'\nActual output:\n$output"
    fi
}

# Assert file exists
# Usage: assert_file_exists "path/to/file"
assert_file_exists() {
    local filepath="$1"
    if [[ ! -f "$filepath" ]]; then
        fail "Expected file to exist: $filepath"
    fi
}

# Assert file does NOT exist
# Usage: assert_file_not_exists "path/to/file"
assert_file_not_exists() {
    local filepath="$1"
    if [[ -f "$filepath" ]]; then
        fail "Expected file NOT to exist: $filepath"
    fi
}

# Assert directory exists
# Usage: assert_directory_exists "path/to/dir"
assert_directory_exists() {
    local dirpath="$1"
    if [[ ! -d "$dirpath" ]]; then
        fail "Expected directory to exist: $dirpath"
    fi
}

# Assert directory does NOT exist
# Usage: assert_directory_not_exists "path/to/dir"
assert_directory_not_exists() {
    local dirpath="$1"
    if [[ -d "$dirpath" ]]; then
        fail "Expected directory NOT to exist: $dirpath"
    fi
}

# Assert file contains a string
# Usage: assert_file_contains "path/to/file" "expected text"
assert_file_contains() {
    local filepath="$1"
    local expected="$2"

    if [[ ! -f "$filepath" ]]; then
        fail "Cannot check file contents - file does not exist: $filepath"
    fi

    if ! grep -q "$expected" "$filepath"; then
        fail "Expected file '$filepath' to contain: '$expected'\nActual contents:\n$(cat "$filepath")"
    fi
}

# Assert file does NOT contain a string
# Usage: refute_file_contains "path/to/file" "unexpected text"
refute_file_contains() {
    local filepath="$1"
    local unexpected="$2"

    if [[ ! -f "$filepath" ]]; then
        fail "Cannot check file contents - file does not exist: $filepath"
    fi

    if grep -q "$unexpected" "$filepath"; then
        fail "Expected file '$filepath' NOT to contain: '$unexpected'\nActual contents:\n$(cat "$filepath")"
    fi
}

# Assert symlink exists and points to target
# Usage: assert_symlink_exists "path/to/link" "target"
assert_symlink_exists() {
    local link_path="$1"
    local expected_target="$2"

    if [[ ! -L "$link_path" ]]; then
        fail "Expected symlink to exist: $link_path"
    fi

    if [[ -n "$expected_target" ]]; then
        local actual_target=$(readlink "$link_path")
        if [[ "$actual_target" != "$expected_target" ]]; then
            fail "Expected symlink '$link_path' to point to '$expected_target' but points to '$actual_target'"
        fi
    fi
}

# Explicit test failure with message
# Usage: fail "Something went wrong"
fail() {
    local message="$1"
    echo "FAILURE: $message" >&2
    return 1
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Get utilz version
get_utilz_version() {
    local help_file="$UTILZ_HOME/help/utilz.md"
    if [[ -f "$help_file" ]]; then
        grep -m1 "^Version:" "$help_file" | awk '{print $2}'
    else
        echo "unknown"
    fi
}

# Check if a command exists
# Usage: if command_exists "yq"; then ...; fi
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Skip test if command is not installed
# Usage: require_command "yq" "yq is required for this test"
require_command() {
    local cmd="$1"
    local message="${2:-$cmd is required for this test}"

    if ! command_exists "$cmd"; then
        skip "$message"
    fi
}

# Print debug information (only when UTILZ_TEST_DEBUG=1)
debug() {
    if [[ "${UTILZ_TEST_DEBUG:-0}" == "1" ]]; then
        echo "DEBUG: $*" >&2
    fi
}
