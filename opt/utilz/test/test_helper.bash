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

# NO TEST REACHES THE NETWORK (issue 0016). A publish asks CI about the commit
# it publishes, with gh, so every suite that publishes -- install, upgrade,
# relink, the guard install and the e2e -- would otherwise ask GitHub about a
# fixture commit it has never seen, from a machine that may or may not be
# logged in. This gh refuses every call the same way, so a publish records
# `unknown`, identically, on every machine and on CI. A test that wants another
# answer points INSTALL_GH at its own stub.
export PATH="$UTILZ_TEST_DIR/stub-bin:$PATH"

# NO TEST WRITES OUTSIDE ITS OWN TEMP DIRS (issue 0082). Tools that keep state
# in the user's home or session -- unison's archives and its default.prf, gpg's
# keyring and daemons, the desktop picture, the clipboard -- get the test's own
# instead. setup() points UNISON into the per-test dir, and GNUPGHOME at a path
# that cannot be made, so a test that runs gpg without make_gpg_home fails by
# name rather than reaching the user's keyring; and it turns git's signing off,
# so no commit or tag a test makes is signed with the user's key, whatever their
# git config says. HOME is never changed: rustup's
# and cargo's homes, which the prez and install suites need, stay where they
# are. A suite with its own setup() that runs unison or gpg calls
# isolate_tool_homes; a test that drives osascript or a clipboard tool puts a
# stub first on PATH in its own dir.

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

  isolate_tool_homes

  # THE OPT PREFIX IS THE SLEEVE'S (issue 0105), so a maintainer's own
  # UTILZ_INSTALL_PREFIX must never reach a test: a publish with no --prefix
  # would write into the real opt tree. A test that wants one sets it, with
  # set_prefix_key.
  unset UTILZ_INSTALL_PREFIX
  # AND THE LINK DIRECTORY IS THE TEST'S (issue 0105): doctor and `use` read
  # ~/.local/bin, which on a maintainer's machine holds the live link set.
  # UTILZ_LINK_DIR names it for tests only, here a directory no test has made.
  export UTILZ_LINK_DIR="$BATS_TEST_TMPDIR/link-dir"

  # A suite about one platform's paths names it at its top (issue 0083).
  if [[ -n "${UTILZ_TEST_PLATFORM:-}" ]]; then
    stub_platform "$UTILZ_TEST_PLATFORM"
  fi
}

# Per-test teardown - runs after each test. A suite that needs a teardown of
# its own defines teardown() and calls utilz_teardown in it, since its own
# replaces this one (issue 0088); isolation.bats checks every suite does.
teardown() {
  utilz_teardown
}

# THE per-test cleanup: the cd back, any gpg home the test made, and the
# per-test dir.
utilz_teardown() {
  # Return to original directory
  if [[ -n "$ORIGINAL_PWD" && -d "$ORIGINAL_PWD" ]]; then
    cd "$ORIGINAL_PWD"
  fi

  # A gpg home the test made goes first, daemons and all (issue 0082).
  end_gpg_home

  # Clean up test temporary directory
  if [[ -n "$BATS_TEST_TMPDIR" && -d "$BATS_TEST_TMPDIR" ]]; then
    rm -rf "$BATS_TEST_TMPDIR"
  fi
}

# THE per-test homes of the tools that keep state (issue 0082). setup() calls
# it once the per-test dir exists, as does any suite's own setup() that runs
# unison or gpg.
isolate_tool_homes() {
  # unison makes this dir itself and keeps its archives, its log and its own
  # default.prf there, so no preference of the user's reaches a test.
  export UNISON="$BATS_TEST_TMPDIR/unison"
  # Fail closed: no such path can be made, and gpg's own error names the fix.
  # A home only make_gpg_home made is ended by teardown, never one inherited.
  unset UTILZ_GPG_HOME
  export GNUPGHOME="/nonexistent/utilz-test-gnupg-call-make_gpg_home"
  no_git_signing
}

# No git a test runs signs with the user's key, whatever their git config says
# (issue 0082). Two keys, added after any the environment already carries; the
# user's name, email and everything else in their config still apply. Its own
# function for a suite's setup_file that commits before any test's dir exists,
# as install_e2e.bats does.
no_git_signing() {
  local n="${GIT_CONFIG_COUNT:-0}"
  export "GIT_CONFIG_KEY_$n=commit.gpgsign" "GIT_CONFIG_VALUE_$n=false"
  n=$((n + 1))
  export "GIT_CONFIG_KEY_$n=tag.gpgsign" "GIT_CONFIG_VALUE_$n=false"
  export GIT_CONFIG_COUNT=$((n + 1))
}

# A gpg home of the test's own, for a test that runs gpg (issue 0082). It is in
# /tmp, not the per-test dir: on macOS gpg-agent cannot start at the per-test
# dir's depth, where its socket's path is past the limit (0082's probe, at 88
# characters). Nothing in it can prompt or reach the network: its pinentry
# fails, and key lookups stay local. teardown() ends it.
make_gpg_home() {
  local home
  home="$(mktemp -d /tmp/utilz-gpg.XXXXXX)" || return 1
  # Recorded at once, so teardown removes it even if a step below fails.
  export UTILZ_GPG_HOME="$home"
  chmod 700 "$home" || return 1
  printf 'pinentry-program /usr/bin/false\n' > "$home/gpg-agent.conf" || return 1
  printf 'auto-key-locate local\nno-auto-key-retrieve\n' > "$home/gpg.conf" || return 1
  export GNUPGHOME="$home"
}

# Ends make_gpg_home's home: its daemons, then the dir. Never silenced: a kill
# that cannot run or fails, and a home that cannot be removed, are said on
# bats's fd 3, which shows even when the test passes (its stderr would not).
end_gpg_home() {
  local home="${UTILZ_GPG_HOME:-}" out note=""
  if [[ -z "$home" ]]; then
    return 0
  fi
  if ! command -v gpgconf > /dev/null 2>&1; then
    note="gpgconf not found, so gpg's daemons for $home may outlive the test"
  elif ! out="$(gpgconf --homedir "$home" --kill all 2>&1)"; then
    note="gpgconf --kill all failed for $home: ${out:-no output}"
  fi
  if ! out="$(rm -rf "$home" 2>&1)"; then
    note="${note:+$note; }could not remove $home: ${out:-no output}"
  fi
  unset UTILZ_GPG_HOME
  if [[ -n "$note" ]]; then
    if { true >&3; } 2> /dev/null; then
      printf '# teardown: %s\n' "$note" >&3
    else
      printf 'teardown: %s\n' "$note" >&2
    fi
  fi
}

# PINS THE PLATFORM A TEST RUNS AS (issue 0083). A uname first on PATH, in the
# test's own dir, answers `uname` and `uname -s` with <name> -- Darwin, Linux,
# or another, such as FreeBSD -- and hands every other question to the real
# one, so either platform's paths are tested on either. utilz_platform reads
# uname -s, so this is the one switch a test needs. Its dir is exported as
# UTILZ_TEST_PLATFORM_BIN for a test that builds a PATH of its own. A suite
# whose tests are about one platform's paths sets UTILZ_TEST_PLATFORM at its
# top, and setup() pins it for every test; a test pins another by calling this.
stub_platform() {
  local name="$1" dir real=""
  if [[ ! "$name" =~ ^[A-Za-z][A-Za-z0-9]*$ ]]; then
    echo "stub_platform: '$name' is not a platform name" >&2
    return 1
  fi
  for real in /usr/bin/uname /bin/uname; do
    if [[ -x "$real" ]]; then
      break
    fi
    real=""
  done
  if [[ -z "$real" ]]; then
    echo "stub_platform: no uname in /usr/bin or /bin to hand other questions to" >&2
    return 1
  fi
  dir="$BATS_TEST_TMPDIR/platform-$name"
  mkdir -p "$dir" || return 1
  cat > "$dir/uname" <<EOF || return 1
#!/bin/sh
if [ \$# -eq 0 ] || [ "\$1" = -s ]; then
  echo $name
  exit 0
fi
exec $real "\$@"
EOF
  chmod +x "$dir/uname" || return 1
  export UTILZ_TEST_PLATFORM_BIN="$dir"
  export PATH="$dir:$PATH"
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

# Run a common.sh function over the tree <home> as bin/utilz runs a verb:
# `set -euo pipefail` first (bin/utilz:9), then the lib sourced from the tree
# under test, then the function as a plain statement, under the first bash on
# PATH (issue 0080). run_common_function and run_in_fake_home run non-strict,
# so they cannot see a verb that strict mode ends at a failing assignment. The
# paths and the words travel as arguments, never spliced into the script.
# Usage: run_common_strict "$home" emit_integration_tsv
run_common_strict() {
  local home="$1"
  shift
  run bash -c 'set -euo pipefail; export UTILZ_HOME="$1"; source "$2/opt/utilz/lib/common.sh"; shift 2; "$@"' \
    _ "$home" "$UTILZ_HOME" "$@"
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

  # See refute_file_contains: `--` keeps a `-`-leading pattern a PATTERN.
  if ! grep -q -- "$expected" "$filepath"; then
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

  # `--` IS LOAD-BEARING: without it a pattern starting with `-` is parsed as
  # a grep OPTION, grep errors, returns non-zero, and the refutation PASSES.
  # A refutation that can never fail. Found 2026-09-08 by injecting the very
  # regression a `refute_file_contains "--version)"` was written to catch.
  if grep -q -- "$unexpected" "$filepath"; then
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

# A PATH THAT LACKS ONE TOOL (issue 0084). A test of a missing tool's refusal
# used to skip wherever the tool was installed, which was every machine that
# ran it, so no refusal it was written for ever ran. PATH order cannot hide a
# tool that shares a directory with everything else, as yq, gpg and git do in
# Ubuntu's /usr/bin, so this builds a farm: a dir of links to every command on
# the current PATH except <tool>, new on each call under BATS_TEST_TMPDIR, so
# it always answers the PATH of the moment; it prints the farm's path. Only
# executable files are linked, as PATH lookup finds only those, so a dangling
# link or a plain file in an earlier directory cannot hide a command a later
# one carries. The directories are linked last to first, so a command an
# earlier one carries wins, as it does on PATH. That is one ln per directory,
# whose arguments are that directory's names alone (about 1,000 at most on
# this project's machines), well inside ARG_MAX. Relative and empty PATH
# entries are skipped. Run the verb under the farm, never bats, so bats and
# the test's assertions keep the test's own PATH:
#   farm=$(path_without gpg)
#   run env PATH="$farm" "$UTILZ_BIN_DIR/cryptz" encrypt test.txt
# A verb that takes either of two tools needs both hidden, so it takes several:
#   farm=$(path_without shasum sha256sum)
# Usage: path_without <tool>...
path_without() {
  local tool farm dirs=() names=() i dir name

  if [[ $# -eq 0 ]]; then
    echo "path_without: name a tool to hide" >&2
    return 1
  fi
  for tool in "$@"; do
    if [[ -z "$tool" || "$tool" == */* ]]; then
      echo "path_without: name a tool, not a path: '$tool'" >&2
      return 1
    fi
  done
  if [[ ! -d "${BATS_TEST_TMPDIR:-}" ]]; then
    echo "path_without: BATS_TEST_TMPDIR is not a directory: '${BATS_TEST_TMPDIR:-}'" >&2
    return 1
  fi

  farm=$(mktemp -d "$BATS_TEST_TMPDIR/path-without-$1.XXXXXX") || return 1
  IFS=: read -r -a dirs <<<"$PATH"
  for ((i = ${#dirs[@]} - 1; i >= 0; i--)); do
    dir="${dirs[$i]}"
    [[ "$dir" == /* && -d "$dir" ]] || continue
    names=()
    for name in "$dir"/*; do
      [[ -f "$name" && -x "$name" ]] && names+=("$name")
    done
    # bash 3.2 calls an empty array unbound under set -u, so ask its length.
    [[ ${#names[@]} -gt 0 ]] || continue
    if ! ln -sfn "${names[@]}" "$farm/"; then
      rm -rf "$farm"
      echo "path_without: could not link $dir into $farm" >&2
      return 1
    fi
  done
  for tool in "$@"; do
    rm -f "$farm/$tool"
    if [[ -e "$farm/$tool" || -L "$farm/$tool" ]]; then
      echo "path_without: $tool is still in $farm" >&2
      return 1
    fi
  done
  echo "$farm"
}

# Print debug information (only when UTILZ_TEST_DEBUG=1)
debug() {
  if [[ "${UTILZ_TEST_DEBUG:-0}" == "1" ]]; then
    echo "DEBUG: $*" >&2
  fi
}

# ============================================================================
# ST0014 INSTALL FIXTURES
# ============================================================================
#
# ONE HOME FOR THE FIXTURES THE INSTALL SUITES SHARE (issue 0028). Until
# 2026-09-14 the suites defined their own copies -- run_install_function five
# times -- and six files carried their own stage-and-commit pair, install_e2e's
# with a `|| true` that turned a refused commit into the publish's "source
# tree is dirty", a step later.

# install.sh's functions, in a fresh bash with common.sh and install.sh sourced
# from the tree under test.
run_install_function() {
  bash -c "source '$UTILZ_HOME/opt/utilz/lib/common.sh'; source '$UTILZ_HOME/opt/utilz/lib/install.sh'; $*"
}

# Publish from $1 to $2, with any extra args appended.
run_publish() {
  local src="$1" prefix="$2"
  shift 2
  run run_install_function "UTILZ_HOME='$src'; install_verb_install --prefix '$prefix' $*"
}

# Stage everything in a fixture tree and commit it, so HEAD matches the tree
# afterwards. A tree that already matches is not an error: a copy of a clean
# checkout has nothing to commit. Everything else that stops the commit fails
# HERE, naming the tree, the commit and git's own words, instead of surfacing
# a step later as some other command's refusal.
fixture_commit() {
  local tree="$1" message="$2" out rc=0
  if ! out=$(git -C "$tree" add -A 2>&1); then
    printf 'fixture_commit: git add -A in %s failed:\n%s\n' "$tree" "$out" >&2
    return 1
  fi
  git -C "$tree" diff --cached --quiet || rc=$?
  case "$rc" in
    0) return 0 ;;
    1) ;;
    *)
      printf 'fixture_commit: could not compare the index with HEAD in %s (git exit %s)\n' "$tree" "$rc" >&2
      return 1
      ;;
  esac
  if ! out=$(git -C "$tree" -c user.email=t@example.com -c user.name=t commit -qm "$message" 2>&1); then
    printf 'fixture_commit: the commit "%s" in %s was refused:\n%s\n' "$message" "$tree" "$out" >&2
    return 1
  fi
  if ! out=$(git -C "$tree" status --porcelain 2>&1); then
    printf 'fixture_commit: could not read %s after the commit "%s":\n%s\n' "$tree" "$message" "$out" >&2
    return 1
  fi
  if [[ -n "$out" ]]; then
    printf 'fixture_commit: %s is still dirty after the commit "%s":\n%s\n' "$tree" "$message" "$out" >&2
    return 1
  fi
}

# A minimal source tree: a git repo whose bin/ is the dispatcher and two links
# to it, the shape git names in Utilz's own bin/ (every link is
# bin/<name> -> utilz, which the manifest's structural check holds, issue 0105).
make_fake_src() {
  local home="$1"
  mkdir -p "$home/bin" "$home/opt/utilz/lib" "$home/opt/alpha/test" "$home/help"
  echo "9.9.9" > "$home/VERSION"
  printf '#!/usr/bin/env bash\necho dispatcher\n' > "$home/bin/utilz"
  chmod +x "$home/bin/utilz"
  ln -s utilz "$home/bin/alpha"
  ln -s utilz "$home/bin/beta"
  printf 'name: alpha\n' > "$home/opt/alpha/alpha.yaml"
  printf '#!/usr/bin/env bash\n' > "$home/opt/alpha/alpha"
  printf 'this must not ship\n' > "$home/opt/alpha/test/alpha.bats"
  printf 'name: utilz\n' > "$home/opt/utilz/utilz.yaml"
  printf '# help\n' > "$home/help/alpha.md"
  git -C "$home" init -q >/dev/null 2>&1
  fixture_commit "$home" init
}

# The opt prefix for this test, as a sleeve sets it: UTILZ_INSTALL_PREFIX,
# exported so every command the test runs reads it (issue 0105). <tree> is
# the fixture it is for, kept so each call still reads as which tree it
# configures; the variable names no tree.
set_prefix_key() {
  local tree="$1" value="$2"
  : "$tree"
  export UTILZ_INSTALL_PREFIX="$value"
}
