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

# NO TEST TOUCHES THE USER'S CLIPBOARD (issue 0082). clipz runs its tools by
# name, so these stubs, first on PATH in the test's own dir, take every call:
# pbcopy and pbpaste, xclip, xsel, wl-copy and wl-paste all read and write one
# file there, and each records how it was called, so a test can say which tool
# answered. XDG_SESSION_TYPE is pinned to x11 so the runner's own session
# cannot choose; a test that wants Wayland sets it after.
stub_clipboard() {
  local stub="$BATS_TEST_TMPDIR/stub" board="$BATS_TEST_TMPDIR/clipboard" name
  mkdir -p "$stub" || return 1
  : > "$board" || return 1
  for name in pbcopy pbpaste xclip xsel wl-copy wl-paste; do
    cat > "$stub/$name" <<EOF
#!/bin/bash
printf '%s\n' "$name \$*" >> "$board.calls"
case "$name \$*" in
  pbpaste* | wl-paste* | *" -o"* | *--output*) cat "$board" ;;
  *) cat > "$board" ;;
esac
EOF
    chmod +x "$stub/$name" || return 1
  done
  export PATH="$stub:$PATH"
  export XDG_SESSION_TYPE=x11
}

# The tool that took the first copy, as the stubs recorded it.
clipboard_copier() {
  head -1 "$BATS_TEST_TMPDIR/clipboard.calls" | cut -d' ' -f1
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
  # THE PAIR IS THE FORM, not merely two numbers appearing somewhere.
  # This asserted the bare letter "v" until 2026-09-08 -- an assertion so
  # weak it was satisfied by the "v" in "every" inside a description, which
  # is why five of the ten tests carrying it stayed GREEN through a change
  # that rewrote every one of these lines. ST0015/AC01.
  assert_output_matches "^utilz:[0-9]+\.[0-9]+\.[0-9]+/clipz:[0-9]+\.[0-9]+\.[0-9]+($|[^0-9.])"
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
  stub_clipboard
  run_clipz copy /nonexistent/file.txt
  assert_failure
  assert_output_contains "not found"
}

@test "clipz copy from stdin works" {
  stub_clipboard
  run bash -c 'echo test | "$1" copy' _ "$UTILZ_BIN_DIR/clipz"
  assert_success
  assert_file_contains "$BATS_TEST_TMPDIR/clipboard" "^test$"
}

@test "clipz copy from file works" {
  stub_clipboard
  echo "test content" > test_file.txt
  run_clipz copy test_file.txt
  assert_success
  assert_file_contains "$BATS_TEST_TMPDIR/clipboard" "^test content$"
  rm -f test_file.txt
}

# ============================================================================
# PASTE COMMAND TESTS
# ============================================================================

@test "clipz paste executes without error" {
  stub_clipboard
  echo "already there" > "$BATS_TEST_TMPDIR/clipboard"
  run_clipz paste
  assert_success
  assert_output_contains "already there"
}

# ============================================================================
# INTEGRATION TESTS
# ============================================================================

@test "clipz copy then paste round-trip" {
  stub_clipboard
  echo "round-trip test" | "$UTILZ_BIN_DIR/clipz" copy

  run_clipz paste
  assert_success
  assert_output_contains "round-trip test"
  # Under x11, as stub_clipboard pins it: xclip on Linux, pbcopy on macOS.
  local want=xclip
  if [[ "$(uname)" == "Darwin" ]]; then want=pbcopy; fi
  [[ "$(clipboard_copier)" == "$want" ]] || fail "expected $want to take the copy; the stubs recorded: $(cat "$BATS_TEST_TMPDIR/clipboard.calls")"
}

@test "clipz copy then paste round-trip under Wayland (issue 0082)" {
  stub_clipboard
  export XDG_SESSION_TYPE=wayland
  echo "wayland trip" | "$UTILZ_BIN_DIR/clipz" copy

  run_clipz paste
  assert_success
  assert_output_contains "wayland trip"
  # wl-copy on Linux; macOS has one clipboard, whatever the session says.
  local want=wl-copy
  if [[ "$(uname)" == "Darwin" ]]; then want=pbcopy; fi
  [[ "$(clipboard_copier)" == "$want" ]] || fail "expected $want to take the copy; the stubs recorded: $(cat "$BATS_TEST_TMPDIR/clipboard.calls")"
}
