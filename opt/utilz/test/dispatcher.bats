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

@test "utilz help <verb> - prints that verb's section of help/utilz.md, and leaves no temp dir (issue 0120)" {
  # A verb's help is its section of help/utilz.md, rendered alone: use's runs
  # from its heading to the line before upgrade's, which is absent. glow and
  # bat are hidden, so the section comes back as the Markdown it is. It is
  # written to a temp dir for the renderer and removed straight after; macOS
  # mktemp writes to the system temp dir whatever TMPDIR says unless given a
  # template, so that dir is read for what the call left, as well as TMPDIR.
  local page="$UTILZ_HOME/help/utilz.md" start end farm tmp sys before after
  start=$(grep -n '^### `utilz use ' "$page" | cut -d: -f1 || true)
  end=$(grep -n '^### `utilz upgrade' "$page" | cut -d: -f1 || true)
  [[ -n "$start" && -n "$end" && "$end" -gt "$start" ]] || fail "use's section is not followed by upgrade's in $page -- the test's reading is wrong, not the tree"
  farm=$(path_without glow bat)
  tmp="$BATS_TEST_TMPDIR/tmpdir"
  mkdir "$tmp"
  sys=$(getconf DARWIN_USER_TEMP_DIR 2>/dev/null || true)
  if [[ -n "$sys" ]]; then
    before=$(find "$sys" -maxdepth 1 -name 'utilz-help.*' | LC_ALL=C sort)
  fi
  run env PATH="$farm" TMPDIR="$tmp" "$UTILZ_BIN_DIR/utilz" help use
  assert_success
  assert_output "$(sed -n "${start},$((end - 1))p" "$page")"
  [[ -z "$(ls -A "$tmp")" ]] || fail "left in TMPDIR: $(ls -A "$tmp")"
  if [[ -n "$sys" ]]; then
    after=$(find "$sys" -maxdepth 1 -name 'utilz-help.*' | LC_ALL=C sort)
    [[ "$after" == "$before" ]] || fail "left in $sys: $after"
  fi
}

@test "utilz help <verb> - a # comment inside a code fence does not end the section (issue 0120)" {
  # help's own section shows shell comments in a fence. Read as headings, the
  # first of them would end the section; read as code, the section runs to the
  # line before doctor's heading. use's section has none, so the row above
  # cannot show this.
  local page="$UTILZ_HOME/help/utilz.md" start end farm
  start=$(grep -n '^### `utilz help ' "$page" | cut -d: -f1 || true)
  end=$(grep -n '^### `utilz doctor' "$page" | cut -d: -f1 || true)
  [[ -n "$start" && -n "$end" && "$end" -gt "$start" ]] || fail "help's section is not followed by doctor's in $page -- the test's reading is wrong, not the tree"
  sed -n "${start},${end}p" "$page" | grep -q '^# ' || fail "help's section holds no # line in a fence -- the row cannot fail"
  farm=$(path_without glow bat)
  run env PATH="$farm" "$UTILZ_BIN_DIR/utilz" help help
  assert_success
  assert_output "$(sed -n "${start},$((end - 1))p" "$page")"
}

@test "utilz help <verb> - every verb heading in help/utilz.md answers with its section (issue 0120)" {
  # The verbs are read from the page's headings, so a verb gets its help by
  # getting a section, with no list of verbs to keep.
  local page="$UTILZ_HOME/help/utilz.md" farm heading verb headings=()
  while IFS= read -r heading; do
    headings+=("$heading")
  done < <(grep '^### `utilz ' "$page" || true)
  [[ ${#headings[@]} -gt 0 ]] || fail "no verb heading in $page -- the grep is wrong, not the tree"
  farm=$(path_without glow bat)
  for heading in "${headings[@]}"; do
    read -r _ _ verb _ <<<"${heading//\`/ }"
    run env PATH="$farm" "$UTILZ_BIN_DIR/utilz" help "$verb"
    [[ "$status" -eq 0 ]] || fail "utilz help $verb exited $status: $output"
    [[ "${lines[0]}" == "$heading" ]] || fail "utilz help $verb opened with '${lines[0]}', not '$heading'"
  done
}

@test "utilz help <unknown> - says where to look, with no path in it (issue 0120)" {
  # A name that is neither a utility nor a verb was answered with the path of
  # a page nobody wrote. No "/" at all, so no path of any kind is in it.
  run_utilz help nonexistent
  assert_exit_code 1
  assert_output_contains "utilz help has nothing on nonexistent"
  assert_output_contains "'utilz list' names the utilities"
  assert_output_contains "'utilz help' describes the verbs"
  refute_output_contains "/"
}

@test "utilz help <utility> - a utility whose page is missing names that page (issue 0120)" {
  # Its opt/<name>/<name>.yaml makes it a utility, so a missing page is a
  # broken tree and the page's path is the answer. The tree is a fake, since
  # the real one has every page; show_help runs strict, as bin/utilz runs it.
  local home="$BATS_TEST_TMPDIR/home"
  mkdir -p "$home/opt/nopagez"
  printf 'name: nopagez\n' >"$home/opt/nopagez/nopagez.yaml"
  run env UTILZ_HOME="$home" bash -c "set -euo pipefail; source '$UTILZ_HOME/opt/utilz/lib/common.sh'; show_help nopagez"
  assert_exit_code 1
  assert_output_contains "Help file not found: $home/help/nopagez.md"
}

@test "utilz doctor - runs diagnostics" {
  run_utilz doctor
  # May pass or fail depending on system setup, but should run
  assert_output_contains "Utilz Doctor"
  assert_output_contains "UTILZ_HOME"
}

@test "utilz doctor - the whole report is on stdout, and nothing on stderr" {
  # ONE STREAM (issue 0037). BATS `run` merges stdout and stderr, so the test
  # above passes whichever stream a line took. Doctor printed its titles on
  # stdout and every verdict on stderr, so a saved or paged report kept the
  # titles and lost the answers. Both directions are asserted, so an empty
  # report cannot pass for a whole one. "✓ UTILZ_HOME is set, to a directory
  # that exists" is the UTILZ_HOME check's verdict; its title, "Checking
  # UTILZ_HOME...", names UTILZ_HOME and carries none of the verdict's words,
  # "is set, to a directory that exists".
  run bash -c '"$1" doctor 2>/dev/null' _ "$UTILZ_BIN_DIR/utilz"
  assert_output_contains "✓ UTILZ_HOME is set, to a directory that exists"
  run bash -c '"$1" doctor 2>&1 >/dev/null' _ "$UTILZ_BIN_DIR/utilz"
  assert_output ""
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
  # THE PAIR IS THE FORM, not merely two numbers appearing somewhere.
  # This asserted the bare letter "v" until 2026-09-08 -- an assertion so
  # weak it was satisfied by the "v" in "every" inside a description, which
  # is why five of the ten tests carrying it stayed GREEN through a change
  # that rewrote every one of these lines. ST0015/AC01. Since issue 0105 the
  # form is the dev, opt, brew contract's one version line (T4).
  assert_output_matches "^utilz [0-9]+\.[0-9]+\.[0-9]+ \((dev|opt|brew), [0-9a-f]{12}(\+dirty)?\)$"
}

@test "utilz test - runs without bats shows error" {
  # bats is hidden from the PATH utilz runs under (issue 0084), so the refusal
  # runs on every machine. It asks for utilz's suite alone, so a refusal that
  # stopped firing would not go on to build every crate first.
  local farm
  farm=$(path_without bats)
  run env PATH="$farm" "$UTILZ_BIN_DIR/utilz" test utilz
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
  # `utilz v2.6.1` until ST0015, then `utilz:2.6.1`, and since issue 0105 the
  # contract's one version line (T4). No `v` in any of them.
  assert_output_matches "^utilz [0-9]+\.[0-9]+\.[0-9]+ \((dev|opt|brew), [0-9a-f]{12}(\+dirty)?\)$"
  refute_output_contains "utilz v"
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
