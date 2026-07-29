#!/usr/bin/env bats
# dispatcher.bats - Tests for bin/utilz dispatcher functionality

load "test_helper.bash"

# ============================================================================
# INFRASTRUCTURE TESTS
# ============================================================================

@test "UTILZ_HOME is detected from script location" {
  run_utilz version
  assert_success
  assert_output_contains "utilz"
}

@test "bin/utilz exists and is executable" {
  assert_file_exists "$UTILZ_BIN_DIR/utilz"
  [[ -x "$UTILZ_BIN_DIR/utilz" ]]
}

@test "common.sh is sourced successfully" {
  run_utilz version
  assert_success
}

# ============================================================================
# BUILT-IN COMMANDS
# ============================================================================

@test "utilz help - shows main help" {
  run_utilz help
  assert_success
  assert_output_contains "Utilz"
}

@test "utilz help mdagg - shows utility-specific help" {
  run_utilz help mdagg
  assert_success
  assert_output_contains "mdagg"
}

@test "utilz help <unknown> - shows error for unknown utility" {
  run_utilz help nonexistent
  assert_failure
  assert_output_contains "not found"
}

@test "utilz doctor - runs diagnostics" {
  run_utilz doctor
  # May pass or fail depending on system setup, but should run
  assert_output_contains "Utilz Doctor"
  assert_output_contains "UTILZ_HOME"
}

@test "utilz list - lists available utilities" {
  run_utilz list
  assert_success
  assert_output_contains "Available utilities"
  assert_output_contains "mdagg"
}

@test "utilz version - shows version" {
  run_utilz version
  assert_success
  assert_output_contains "utilz"
  assert_output_contains "v"
}

@test "utilz test - runs without bats shows error" {
  # Skip if bats is installed (it should be, but test the error path)
  if command_exists bats; then
    skip "bats is installed"
  fi

  run_utilz test
  assert_failure
  assert_output_contains "bats is required"
}

@test "utilz <unknown> - shows error for unknown command" {
  run_utilz unknowncommand
  assert_failure
  assert_output_contains "Unknown command"
  assert_output_contains "Available commands"
}

# ============================================================================
# TOP-LEVEL FLAG ALIASES (issue 0003)
# ============================================================================
#
# Every utility accepts --version/--help/-h, and the dispatcher's own nested
# `integration` and `emacs` verbs accept --help/-h. The top level accepted only
# the bare words, so `utilz --version` -- the form a first-time user and a
# probing script both reach for -- exited 1 with "Unknown command".

@test "utilz --version - flag form of 'version' (issue 0003)" {
  run_utilz --version
  assert_success
  assert_output_contains "utilz v"
}

@test "utilz --help - flag form of 'help' (issue 0003)" {
  run_utilz --help
  assert_success
  assert_output_contains "Utilz"
}

@test "utilz -h - short flag form of 'help' (issue 0003)" {
  run_utilz -h
  assert_success
  assert_output_contains "Utilz"
}

@test "utilz --help <utility> - flag form still takes a utility argument (issue 0003)" {
  run_utilz --help mdagg
  assert_success
  assert_output_contains "mdagg"
}

@test "utilz -v is NOT bound (issue 0003)" {
  # Deliberately unbound: -v reads as verbose, and no utility binds it. Pinned
  # so a later "while we're here" change has to argue with a test.
  run_utilz -v
  assert_failure
  assert_output_contains "Unknown command"
}

# ============================================================================
# UNKNOWN-COMMAND SUGGESTION LIST (issue 0004)
# ============================================================================

@test "unknown-command list omits a stray non-utilz symlink (issue 0004)" {
  # each_utility() requires the link to resolve to utilz; this list is a sixth
  # open-coded walk that only tested -L, so a stray link read as a utility.
  ln -sf /bin/echo "$UTILZ_BIN_DIR/zzstray"
  run_utilz boguscommand
  rm -f "$UTILZ_BIN_DIR/zzstray"

  assert_failure
  assert_output_contains "Unknown command"
  assert_output_contains "Installed utilities"
  if [[ "$output" == *"zzstray"* ]]; then
    echo "stray symlink leaked into the installed-utilities list" >&2
    return 1
  fi
}

@test "unknown-command list names a real utility (issue 0004)" {
  run_utilz boguscommand
  assert_failure
  assert_output_contains "utilz mdagg"
}

@test "unknown-command list aligns its description column (issue 0004)" {
  run_utilz boguscommand
  assert_failure

  # Every "- Run <x> utility" must begin at the same column. The old form used
  # a hardcoded run of spaces, so the column tracked the name length.
  local distinct
  distinct=$(printf '%s\n' "$output" \
    | awk '/^  utilz .* \[args\].*- Run /  { print index($0, "- Run ") }' \
    | sort -u | wc -l | tr -d ' ')
  [[ "$distinct" == "1" ]]
}

# ============================================================================
# SYMLINK DISPATCH
# ============================================================================

@test "mdagg symlink exists and points to utilz" {
  assert_symlink_exists "$UTILZ_BIN_DIR/mdagg" "utilz"
}

@test "invoking via symlink dispatches to utility" {
  run_mdagg --version
  assert_success
  assert_output_contains "mdagg"
}

@test "mdagg --help shows help (handled by dispatcher)" {
  run_mdagg --help
  assert_success
  assert_output_contains "mdagg"
  assert_output_contains "Markdown"
}

@test "mdagg --version shows version (handled by dispatcher)" {
  run_mdagg --version
  assert_success
  assert_output_contains "mdagg"
}

# ============================================================================
# ERROR HANDLING
# ============================================================================

@test "missing utility implementation shows helpful error" {
  # Create a symlink without implementation
  ln -sf utilz "$UTILZ_BIN_DIR/testutil"

  run_utility testutil
  assert_failure
  assert_output_contains "implementation not found"
  assert_output_contains "opt/testutil/testutil"

  # Cleanup
  rm -f "$UTILZ_BIN_DIR/testutil"
}

@test "non-executable implementation shows helpful error" {
  # Create a utility with non-executable implementation
  mkdir -p "$UTILZ_HOME/opt/testutil"
  echo "#!/bin/bash" > "$UTILZ_HOME/opt/testutil/testutil"
  # Don't make it executable
  ln -sf utilz "$UTILZ_BIN_DIR/testutil"

  run_utility testutil
  assert_failure
  assert_output_contains "not executable"
  assert_output_contains "chmod +x"

  # Cleanup
  rm -f "$UTILZ_BIN_DIR/testutil"
  rm -rf "$UTILZ_HOME/opt/testutil"
}

# ============================================================================
# ENVIRONMENT
# ============================================================================

@test "dispatcher works from different working directories" {
  # Create temp directory and cd into it
  local temp_dir="$BATS_TEST_TMPDIR/subdir"
  mkdir -p "$temp_dir"
  cd "$temp_dir"

  run_utilz version
  assert_success
  assert_output_contains "utilz"
}

@test "dispatcher passes arguments to utility" {
  # mdagg with no args should show error about missing input
  run_mdagg
  assert_failure
}
