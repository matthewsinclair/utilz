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

# NO TEST SETS THE USER'S DESKTOP PICTURE (issue 0082). macoz runs osascript by
# name, so this stub, first on PATH in the test's own dir, takes every call: it
# records the script it was asked to run and exits 0. A test asserts the
# record, which the real osascript never writes.
stub_osascript() {
  local stub="$BATS_TEST_TMPDIR/stub"
  mkdir -p "$stub" || return 1
  cat > "$stub/osascript" <<EOF
#!/bin/bash
printf '%s\n' "\$*" >> "$BATS_TEST_TMPDIR/osascript.calls"
EOF
  chmod +x "$stub/osascript" || return 1
  export PATH="$stub:$PATH"
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
  # THE PAIR IS THE FORM, not merely two numbers appearing somewhere.
  # This asserted the bare letter "v" until 2026-09-08 -- an assertion so
  # weak it was satisfied by the "v" in "every" inside a description, which
  # is why five of the ten tests carrying it stayed GREEN through a change
  # that rewrote every one of these lines. ST0015/AC01.
  assert_output_matches "^utilz:[0-9]+\.[0-9]+\.[0-9]+/macoz:[0-9]+\.[0-9]+\.[0-9]+($|[^0-9.])"
}

@test "macoz with no arguments shows usage" {
  run_macoz
  assert_success
  assert_output_contains "Usage"
}

@test "macoz with unknown command shows error" {
  # macOS's answer, on any machine: off macOS every command refuses first
  # (issue 0083).
  stub_platform Darwin
  run_macoz unknown-command
  assert_failure
  assert_output_contains "Unknown command"
}

# ============================================================================
# THE PLATFORM (issue 0083)
# ============================================================================

# It ran only off macOS, and macoz was off CI's Linux roster, so it ran nowhere
# (issue 0083, item 19). Under a Linux uname it runs on every machine.
@test "macoz refuses every command off macOS by name, exit 2 (issue 0083)" {
  stub_platform Linux
  local args
  for args in "background test.jpg" "bg" "setpicfor icon.png" "unknown-command"; do
    # shellcheck disable=SC2086 # each case is a command and its words
    run_macoz $args
    assert_exit_code 2
    assert_output_contains "macoz needs macOS, so it is not available on Linux"
  done
}

@test "macoz answers --help, --version and no arguments off macOS (issue 0083)" {
  stub_platform Linux
  run_macoz --help
  assert_success
  assert_output_contains "background"

  run_macoz --version
  assert_success
  assert_output_matches "^utilz:[0-9]+\.[0-9]+\.[0-9]+/macoz:[0-9]+\.[0-9]+\.[0-9]+($|[^0-9.])"

  run_macoz
  assert_success
  assert_output_contains "Usage"

  # The script itself, as the dispatcher runs it, answers its help arm first.
  run "$UTILZ_HOME/opt/macoz/macoz" --help
  assert_success
  assert_output_contains "Usage"
}

@test "macoz.yaml declares macOS as its only platform, and fileicon as an optional dependency (issue 0083)" {
  local y="$UTILZ_HOME/opt/macoz/macoz.yaml"
  run yq -o=json -I=0 '.platforms' "$y"
  assert_output '["macos"]'
  run yq '.dependencies[] | select(.name == "fileicon") | .required' "$y"
  assert_output "false"
  run yq '.dependencies[] | select(.name == "fileicon") | .purpose' "$y"
  assert_output_contains "setpicfor"
}

# ============================================================================
# BACKGROUND COMMAND TESTS
# ============================================================================

@test "macoz background with no argument auto-selects seasonal" {
  if ! is_macos; then
    skip "Not on macOS"
  fi

  stub_osascript
  run_macoz background
  assert_success
  assert_output_contains "Auto-selected"
  assert_file_contains "$BATS_TEST_TMPDIR/osascript.calls" "set picture to \"$UTILZ_HOME/opt/macoz/images/backgrounds/"
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

  stub_osascript
  run_macoz background "$test_image"
  assert_success
  assert_file_contains "$BATS_TEST_TMPDIR/osascript.calls" "set picture to \"$test_image\""
}

@test "macoz background alias bg works" {
  if ! is_macos; then
    skip "Not on macOS"
  fi

  # Test that 'bg' alias works (auto-selects seasonal)
  stub_osascript
  run_macoz bg
  assert_success
  assert_output_contains "Auto-selected"
  assert_file_contains "$BATS_TEST_TMPDIR/osascript.calls" "set picture to \"$UTILZ_HOME/opt/macoz/images/backgrounds/"
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
