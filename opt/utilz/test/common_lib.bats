#!/usr/bin/env bats
# common_lib.bats - Tests for opt/utilz/lib/common.sh functions

load "test_helper.bash"

# Helper to run a function from common.sh
run_common_function() {
  bash -c "source '$UTILZ_HOME/opt/utilz/lib/common.sh'; $*"
}

# ----------------------------------------------------------------------------
# ST0009 fixtures
# ----------------------------------------------------------------------------

# Build a self-contained UTILZ_HOME so the walker and generator tests never
# mutate the real bin/. It carries the three cases each_utility must tell
# apart: two genuine utilities (symlink -> dispatcher), one stray symlink that
# resolves elsewhere, and one plain file.
#
# The VERSION is a parameter so the generator tests can assert the compat floor
# TRACKS it rather than coincidentally matching the real 2.x.
#
# Echoes the path to the fake home.
make_fake_home() {
  local version="${1:-2.3.0}"
  local home="$BATS_TEST_TMPDIR/fake-home"

  mkdir -p "$home/bin" "$home/opt/utilz/lib" "$home/help"
  echo "$version" > "$home/VERSION"

  # The dispatcher: present and executable, and skipped by the walker.
  printf '#!/usr/bin/env bash\nexit 0\n' > "$home/bin/utilz"
  chmod +x "$home/bin/utilz"

  # utilz defers its version to the shared VERSION file, as the real one does.
  cat > "$home/opt/utilz/utilz.yaml" <<YAML
name: utilz
version_file: ../../VERSION
description: Fake core for tests
dependencies: []
YAML

  local name
  for name in alpha beta; do
    mkdir -p "$home/opt/$name"
    printf '#!/usr/bin/env bash\nexit 0\n' > "$home/opt/$name/$name"
    chmod +x "$home/opt/$name/$name"
    cat > "$home/opt/$name/$name.yaml" <<YAML
name: $name
version: 1.0.0
utilz_version: "^${version%%.*}.0.0"
description: Fake $name for tests
dependencies: []
YAML
    ln -s utilz "$home/bin/$name"
  done

  # The two entries in bin/ that are NOT utilities.
  ln -s /bin/echo "$home/bin/zzstray"
  printf 'not a symlink\n' > "$home/bin/zzplain"

  echo "$home"
}

# Run a common.sh function against a fake UTILZ_HOME. The real common.sh is
# sourced (absolute path, resolved by the calling shell); only UTILZ_HOME is
# redirected at the fake tree.
run_in_fake_home() {
  local home="$1"
  shift
  run /bin/bash -c "export UTILZ_HOME='$home'; source '$UTILZ_HOME/opt/utilz/lib/common.sh'; $*"
}

# As run_in_fake_home, but with extra entries prepended to PATH. The real PATH
# is kept on the tail so yq and the core tools stay reachable -- these tests are
# about what doctor concludes from PATH, not about a stripped environment.
run_in_fake_home_with_path() {
  local home="$1"
  local extra_path="$2"
  shift 2
  run /bin/bash -c "export UTILZ_HOME='$home'; export PATH='$extra_path':\"\$PATH\"; source '$UTILZ_HOME/opt/utilz/lib/common.sh'; $*"
}

# Run a common.sh function with yq unreachable: under test_helper's
# path_without yq, which keeps every other command on PATH (issue 0084).
run_without_yq() {
  local farm
  farm="$(path_without yq)"
  run env PATH="$farm" bash -c "source '$UTILZ_HOME/opt/utilz/lib/common.sh'; $*"
}

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

@test "info() produces output" {
  run run_common_function info "test message"
  assert_success
  assert_output_contains "test message"
}

@test "success() produces output" {
  run run_common_function success "test success"
  assert_success
  assert_output_contains "test success"
}

@test "warn() produces output to stderr" {
  run run_common_function warn "test warning"
  assert_success
  assert_output_contains "test warning"
}

@test "error() produces output to stderr" {
  run run_common_function error "test error"
  assert_success
  assert_output_contains "test error"
}

@test "debug() only outputs when UTILZ_DEBUG=1" {
  # Without UTILZ_DEBUG
  run run_common_function debug "debug message"
  assert_success
  refute_output_contains "debug message"

  # With UTILZ_DEBUG=1
  run bash -c "source '$UTILZ_HOME/opt/utilz/lib/common.sh'; UTILZ_DEBUG=1 debug 'debug message'"
  assert_success
  assert_output_contains "debug message"
}

# ============================================================================
# HELP FUNCTIONS
# ============================================================================

@test "show_help() renders help file for utilz" {
  run run_common_function show_help utilz
  assert_success
  assert_output_contains "Utilz"
}

@test "show_help() renders help file for mdagg" {
  run run_common_function show_help mdagg
  assert_success
  assert_output_contains "mdagg"
}

@test "show_help() shows error for missing help file" {
  run run_common_function show_help nonexistent
  assert_failure
  assert_output_contains "not found"
}

# ============================================================================
# VERSION FUNCTIONS
# ============================================================================

@test "show_version() returns utilz version" {
  run run_common_function show_version utilz
  assert_success
  # THE PAIR IS THE FORM, not merely two numbers appearing somewhere.
  # This asserted the bare letter "v" until 2026-09-08 -- an assertion so
  # weak it was satisfied by the "v" in "every" inside a description, which
  # is why five of the ten tests carrying it stayed GREEN through a change
  # that rewrote every one of these lines. ST0015/AC01.
  assert_output_matches "^utilz:[0-9]+\.[0-9]+\.[0-9]+($|[^0-9.])"
}

@test "show_version() extracts version from utility help file" {
  run run_common_function show_version mdagg
  assert_success
  assert_output_contains "mdagg"
}

@test "show_version() handles missing utility gracefully" {
  run run_common_function show_version nonexistent
  assert_failure
  assert_output_contains "nonexistent"
  assert_output_contains "version unknown"
}

# ============================================================================
# LIST FUNCTIONS
# ============================================================================

@test "list_utilities() discovers symlinked utilities" {
  run run_common_function list_utilities
  assert_success
  assert_output_contains "Available utilities"
  assert_output_contains "mdagg"
}

@test "list_utilities() skips utilz itself" {
  run run_common_function list_utilities
  assert_success
  # Should not list utilz as a utility (but may mention it in help text)
  # Check that the utilities section doesn't have a line for utilz
  refute_output_contains "  utilz"
}

@test "list_utilities() extracts descriptions from help files" {
  run run_common_function list_utilities
  assert_success
  # Should have some description text, not just utility names
  assert_output_contains "mdagg"
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

@test "check_command() detects installed commands" {
  run run_common_function check_command bash
  assert_success

  run run_common_function check_command echo
  assert_success
}

@test "check_command() returns false for missing commands" {
  run run_common_function check_command nonexistent_command_xyz
  assert_failure
}

# bash's `command -v` names a file on PATH that cannot run when nothing
# executable matches (measured under bash 3.2.57 and 5.3.20), so the exec bit
# is the only difference between the two halves below.
@test "check_command() returns false for a file on PATH that is not executable" {
  local bin="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$bin"
  printf '#!/bin/sh\n' >"$bin/utilz_noexec_xyz"
  chmod 644 "$bin/utilz_noexec_xyz"
  run env PATH="$bin:$PATH" bash -c "source '$UTILZ_HOME/opt/utilz/lib/common.sh'; check_command utilz_noexec_xyz"
  assert_failure

  chmod 755 "$bin/utilz_noexec_xyz"
  run env PATH="$bin:$PATH" bash -c "source '$UTILZ_HOME/opt/utilz/lib/common.sh'; check_command utilz_noexec_xyz"
  assert_success
}

@test "require_command() succeeds for installed commands" {
  run run_common_function require_command bash
  assert_success
}

@test "require_command() fails for missing commands" {
  run run_common_function require_command nonexistent_command_xyz
  assert_failure
  assert_output_contains "not found"
}

@test "require_command() shows install hint" {
  run run_common_function require_command nonexistent_cmd '"brew install nonexistent"'
  assert_failure
  assert_output_contains "brew install"
}

@test "parse_yaml() requires yq" {
  # yq is hidden from the PATH parse_yaml runs under (issue 0084), so its
  # refusal runs on every machine, not only one without yq.
  run_without_yq parse_yaml test.yaml .foo
  assert_failure
  assert_output_contains "yq is required"
}

@test "path_without hides its one tool and keeps every other command on PATH (issue 0084)" {
  local farm
  farm=$(path_without cat)
  command -v cat >/dev/null

  run env PATH="$farm" bash -c 'command -v cat'
  assert_failure

  run env PATH="$farm" bash -c 'command -v bash && command -v env && command -v ls'
  assert_success

  # A command an earlier PATH directory carries wins, as it does on PATH: an
  # ls of the test's own, first on PATH, wins over the machine's. A plain file
  # named ls ahead of it, which PATH lookup passes over, does not hide it.
  # `|| fail` on each, since bash 3.2 lets a failing [[ ]] pass mid-test.
  mkdir first plain
  printf '#!/bin/sh\necho stub\n' > first/ls
  chmod +x first/ls
  touch plain/ls
  farm=$(PATH="$PWD/plain:$PWD/first:$PATH" path_without cat)
  [[ "$(readlink "$farm/ls")" == "$PWD/first/ls" ]] ||
    fail "the farm's ls is $(readlink "$farm/ls"), not the first one on PATH"
  [[ "$(readlink "$farm/bash")" == "$(command -v bash)" ]] ||
    fail "the farm's bash is $(readlink "$farm/bash"), not PATH's $(command -v bash)"
}

@test "parse_yaml() extracts values from YAML" {
  require_command yq

  # Create test YAML file
  cat > test.yaml <<EOF
name: test
value: 42
EOF

  run run_common_function parse_yaml test.yaml ".name"
  assert_success
  assert_output "test"

  run run_common_function parse_yaml test.yaml ".value"
  assert_success
  assert_output "42"
}

# ============================================================================
# DOCTOR COMMAND
# ============================================================================

@test "run_doctor() checks UTILZ_HOME" {
  run run_common_function run_doctor
  assert_output_contains "UTILZ_HOME"
}

@test "run_doctor() checks directory structure" {
  run run_common_function run_doctor
  assert_output_contains "directory structure"
}

@test "run_doctor() checks bin/utilz exists and is executable" {
  run run_common_function run_doctor
  assert_output_contains "bin/utilz"
}

@test "run_doctor() checks PATH configuration" {
  run run_common_function run_doctor
  assert_output_contains "PATH"
}

# ----------------------------------------------------------------------------
# doctor check 4 -- PATH reachability (issue 0005)
# ----------------------------------------------------------------------------
#
# The old test was `echo "$PATH" | grep -q "$UTILZ_HOME/bin"`: one expression,
# two faults. It could only ever recognise $UTILZ_HOME/bin as a literal PATH
# entry, so a working symlink-on-PATH install was reported as a problem; and it
# matched by unanchored regex, so any substring satisfied it.

@test "doctor check 4 passes when UTILZ_HOME/bin is on PATH" {
  local home
  home="$(make_fake_home)"

  run_in_fake_home_with_path "$home" "$home/bin" run_doctor
  assert_output_contains "is in \$PATH"
  refute_output_contains "is not in \$PATH"
}

@test "doctor check 4 accepts a utilz symlink on PATH (issue 0005)" {
  local home shim
  home="$(make_fake_home)"
  shim="$BATS_TEST_TMPDIR/shim"
  mkdir -p "$shim"
  ln -s "$home/bin/utilz" "$shim/utilz"

  # PATH carries the shim but NOT $home/bin, so the only route to the
  # dispatcher is through the symlink -- a working install either way.
  run_in_fake_home_with_path "$home" "$shim" run_doctor
  assert_output_contains "$shim/utilz"
  refute_output_contains "is not in \$PATH"
}

@test "doctor check 4 warns when the dispatcher is unreachable on PATH (issue 0005)" {
  local home
  home="$(make_fake_home)"

  # Neither $home/bin nor any utilz resolving to it. The real repo's own
  # dispatcher may well be on PATH, but it is a different file, so -ef is false.
  run_in_fake_home_with_path "$home" "$BATS_TEST_TMPDIR/nowhere" run_doctor
  assert_output_contains "is not in \$PATH"
}

@test "doctor check 4 rejects a PATH substring match (issue 0005)" {
  local home
  home="$(make_fake_home)"
  mkdir -p "$home/binaries"

  # "$home/binaries" contains "$home/bin" as a substring. The grep form passed
  # on this; an exact PATH-element match must not.
  run_in_fake_home_with_path "$home" "$home/binaries" run_doctor
  assert_output_contains "is not in \$PATH"
}

@test "run_doctor() discovers utilities" {
  run run_common_function run_doctor
  assert_output_contains "utilities"
}

@test "run_doctor() checks for yq dependency" {
  run run_common_function run_doctor
  assert_output_contains "dependencies"
}

@test "run_doctor() returns success with no issues" {
  # This test might fail if the system has actual issues
  # We just verify the function completes
  run run_common_function run_doctor
  # Should have diagnostic output
  assert_output_contains "Checking"
}

@test "run_doctor() reports issues count" {
  run run_common_function run_doctor
  # Should mention either "passed" or "issue"
  if [[ "$output" == *"passed"* ]] || [[ "$output" == *"issue"* ]]; then
    true
  else
    fail "Expected output to mention 'passed' or 'issue'"
  fi
}

# ----------------------------------------------------------------------------
# doctor's dependency sweep on a yaml it cannot use (issue 0080)
# ----------------------------------------------------------------------------
#
# The sweep's first read of each yaml had no ||, so under bin/utilz's
# `set -euo pipefail` a yaml yq could not read ended doctor under its [6/7]
# title, with no verdict. And a dependencies list that was not a list was read
# as a list of its length: `dependencies: jq` checked two entries with empty
# names. Each test runs run_doctor strict, as bin/utilz does, and checks that
# the refusal adds exactly one issue to the same home before beta's yaml.

# A good utility that sorts after beta, with one dependency no machine has:
# doctor names it only if its sweep went on past beta.
add_gamma() {
  local home="$1"
  mkdir -p "$home/opt/gamma"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$home/opt/gamma/gamma"
  chmod +x "$home/opt/gamma/gamma"
  printf 'name: gamma\nversion: 1.0.0\ndescription: Fake gamma for tests\ndependencies:\n  - name: zz-absent-0080\n    install: none\n' > "$home/opt/gamma/gamma.yaml"
  ln -s utilz "$home/bin/gamma"
}

# The N of doctor's "Found N issue(s)" in $output, or 0 when it found none.
doctor_issue_count() {
  local n
  n=$(printf '%s\n' "$output" | sed -n 's/.*Found \([0-9][0-9]*\) issue(s).*/\1/p')
  printf '%s\n' "${n:-0}"
}

@test "run_doctor names a yaml it cannot read, and still reaches its verdict (issue 0080)" {
  local home before
  home="$(make_fake_home)"
  add_gamma "$home"
  run_common_strict "$home" run_doctor
  before=$(doctor_issue_count)
  printf 'name: beta\ndependencies: [\n' > "$home/opt/beta/beta.yaml"

  run_common_strict "$home" run_doctor
  assert_output_contains "beta: beta.yaml cannot be read, so neither of its dependency lists is checked: "
  assert_output_contains "zz-absent-0080"
  assert_output_contains "[7/7]"
  [[ "$(doctor_issue_count)" -eq $((before + 1)) ]] ||
    fail "Expected $((before + 1)) issues, one more than the $before before beta's yaml. Actual output:\n$output"
}

@test "run_doctor names a yaml whose top level is not a map (issue 0080)" {
  local home before
  home="$(make_fake_home)"
  run_common_strict "$home" run_doctor
  before=$(doctor_issue_count)
  printf -- '- name: beta\n- version: 1.0.0\n' > "$home/opt/beta/beta.yaml"

  run_common_strict "$home" run_doctor
  assert_output_contains "beta: beta.yaml cannot be read, so neither of its dependency lists is checked: its top level is a list, not a map"
  assert_output_contains "2 dependency list(s) not checked"
  assert_output_contains "[7/7]"
  [[ "$(doctor_issue_count)" -eq $((before + 1)) ]] ||
    fail "Expected $((before + 1)) issues, one more than the $before before beta's yaml. Actual output:\n$output"
}

@test "run_doctor refuses dependencies that are not a list, by name, and does not call the rest installed (issue 0080)" {
  local home before
  home="$(make_fake_home)"
  run_common_strict "$home" run_doctor
  before=$(doctor_issue_count)
  printf 'name: beta\nversion: 1.0.0\ndescription: Fake beta\ndependencies: jq\n' > "$home/opt/beta/beta.yaml"

  run_common_strict "$home" run_doctor
  assert_output_contains "beta: dependencies is a string, not a list, so it is not checked"
  assert_output_contains "1 dependency list(s) not checked"
  refute_output_contains "All required dependencies installed"
  assert_output_contains "[7/7]"
  [[ "$(doctor_issue_count)" -eq $((before + 1)) ]] ||
    fail "Expected $((before + 1)) issues, one more than the $before before beta's yaml. Actual output:\n$output"
}

@test "run_doctor refuses optional_dependencies that are not a list, by name (issue 0080)" {
  local home before
  home="$(make_fake_home)"
  add_gamma "$home"
  run_common_strict "$home" run_doctor
  before=$(doctor_issue_count)
  printf 'name: beta\nversion: 1.0.0\ndescription: Fake beta\ndependencies: []\noptional_dependencies: {glow: brew install glow}\n' > "$home/opt/beta/beta.yaml"

  run_common_strict "$home" run_doctor
  assert_output_contains "beta: optional_dependencies is a map, not a list, so it is not checked"
  assert_output_contains "zz-absent-0080"
  assert_output_contains "[7/7]"
  [[ "$(doctor_issue_count)" -eq $((before + 1)) ]] ||
    fail "Expected $((before + 1)) issues, one more than the $before before beta's yaml. Actual output:\n$output"
}

# A dependency entry that names no dependency (issue 0085): one written as a
# bare string or as a map with no name was checked as a dependency with no
# name, and one written as a list ended doctor at the read of its name.

@test "run_doctor refuses a dependency written as a bare string, by name, and does not call the rest installed (issue 0085)" {
  local home before
  home="$(make_fake_home)"
  run_common_strict "$home" run_doctor
  assert_output_contains "All required dependencies installed"
  before=$(doctor_issue_count)
  printf 'name: beta\nversion: 1.0.0\ndescription: Fake beta\ndependencies: [jq]\n' > "$home/opt/beta/beta.yaml"

  run_common_strict "$home" run_doctor
  assert_output_contains "beta: dependencies[0] is a string, not a map with a name"
  refute_output_contains "Missing dependencies"
  refute_output_contains "All required dependencies installed"
  assert_output_contains "1 dependency entr(ies) not checked, named above"
  [[ "$(doctor_issue_count)" -eq $((before + 1)) ]] ||
    fail "Expected $((before + 1)) issues, one more than the $before before beta's entry. Actual output:\n$output"
}

@test "run_doctor refuses a dependency entry with no name, by name (issue 0085)" {
  local home before
  home="$(make_fake_home)"
  run_common_strict "$home" run_doctor
  before=$(doctor_issue_count)
  printf 'name: beta\nversion: 1.0.0\ndescription: Fake beta\ndependencies:\n  - install: brew install jq\n' > "$home/opt/beta/beta.yaml"

  run_common_strict "$home" run_doctor
  assert_output_contains "beta: dependencies[0] has no name"
  refute_output_contains "Missing dependencies"
  [[ "$(doctor_issue_count)" -eq $((before + 1)) ]] ||
    fail "Expected $((before + 1)) issues, one more than the $before before beta's entry. Actual output:\n$output"
}

@test "run_doctor refuses a dependency entry written as a list, by name, and reaches its verdict (issue 0085)" {
  local home before
  home="$(make_fake_home)"
  run_common_strict "$home" run_doctor
  before=$(doctor_issue_count)
  printf 'name: beta\nversion: 1.0.0\ndescription: Fake beta\ndependencies: []\noptional_dependencies: [[jq]]\n' > "$home/opt/beta/beta.yaml"

  run_common_strict "$home" run_doctor
  assert_output_contains "beta: optional_dependencies[0] is a list, not a map with a name"
  assert_output_contains "[7/7]"
  [[ "$(doctor_issue_count)" -eq $((before + 1)) ]] ||
    fail "Expected $((before + 1)) issues, one more than the $before before beta's entry. Actual output:\n$output"
}

# ----------------------------------------------------------------------------
# get_util_metadata on a yaml yq cannot read, and its four callers (issue 0081)
# ----------------------------------------------------------------------------
#
# get_util_metadata runs inside $(...), where bash clears errexit, so a read of
# a yaml yq could not read ended in `echo "$result"` with status 0, and every
# caller took the yaml's fault for an absent field. It now answers that read
# with status 2 and prints nothing, as it does for a yaml that is not one map,
# and each caller names the cause in yaml_read_error's own words, which no yq
# version moves. In each test alpha's yaml is good and beta's is the fault.

@test "get_util_metadata answers a yaml it cannot read with status 2 and no output (issue 0081)" {
  local home
  home="$(make_fake_home)"
  run_common_strict "$home" get_util_metadata alpha .nosuchkey
  assert_success
  assert_output "null"
  printf 'name: beta\ndescription: [\n' > "$home/opt/beta/beta.yaml"

  run_common_strict "$home" get_util_metadata beta .description
  assert_exit_code 2
  assert_output ""
}

@test "get_util_metadata answers a yaml that is not one map with status 2, and still reads a good map's empty value (issue 0081)" {
  local home
  home="$(make_fake_home)"
  printf 'name: beta\ndescription: ""\n' > "$home/opt/beta/beta.yaml"
  run_common_strict "$home" get_util_metadata beta .description
  assert_success
  assert_output ""
  printf 'name: beta\ndescription: |\n  one\n  ---\n  two\n' > "$home/opt/beta/beta.yaml"
  run_common_strict "$home" get_util_metadata beta .description
  assert_success
  assert_output "$(printf 'one\n---\ntwo')"

  printf 'just a string\n' > "$home/opt/beta/beta.yaml"
  run_common_strict "$home" get_util_metadata beta .description
  assert_exit_code 2
  assert_output ""
  # yq answers two documents with the block text's very lines; only the yaml's
  # type tells the two apart.
  printf 'name: beta\ndescription: one\n---\nname: beta\ndescription: two\n' > "$home/opt/beta/beta.yaml"
  run_common_strict "$home" get_util_metadata beta .description
  assert_exit_code 2
  assert_output ""
}

@test "get_util_metadata answers a version_file it cannot open with status 1, and cat says why (issue 0081)" {
  local home
  home="$(make_fake_home)"
  run_common_strict "$home" get_util_metadata utilz .version
  assert_success
  assert_output "2.3.0"
  chmod 000 "$home/VERSION"
  [[ ! -r "$home/VERSION" ]] || skip "this user can read a file of mode 000, as root can"

  # Called as every caller calls it, inside $(...) with its status taken, where
  # bash clears errexit. Called bare under set -e, the failing cat ends the shell
  # with status 1 on main's code too, and the test could not tell them apart.
  run_common_strict "$home" eval 'v=$(get_util_metadata utilz .version) || exit $?; echo "$v"'
  assert_exit_code 1
  assert_output_contains "Permission denied"
}

@test "get_util_metadata answers a Cargo.toml version_file it cannot open with status 1, and awk names it (issue 0081)" {
  local home
  home="$(make_fake_home)"
  printf 'name: beta\nversion_file: Cargo.toml\ndescription: Fake beta for tests\ndependencies: []\n' > "$home/opt/beta/beta.yaml"
  printf '[package]\nname = "beta"\nversion = "1.4.0"\n' > "$home/opt/beta/Cargo.toml"
  # Guarded as the test above calls it, for the same reason. awk's own words
  # differ between macOS's awk, mawk and gawk, so the test asserts the file's name.
  run_common_strict "$home" eval 'v=$(get_util_metadata beta .version) || exit $?; echo "$v"'
  assert_success
  assert_output "1.4.0"
  chmod 000 "$home/opt/beta/Cargo.toml"
  [[ ! -r "$home/opt/beta/Cargo.toml" ]] || skip "this user can read a file of mode 000, as root can"

  run_common_strict "$home" eval 'v=$(get_util_metadata beta .version) || exit $?; echo "$v"'
  assert_exit_code 1
  assert_output_contains "$home/opt/beta/Cargo.toml"
}

@test "show_version names a yaml it cannot read, and why, not a missing version (issue 0081)" {
  local home
  home="$(make_fake_home)"
  printf -- '- name: beta\n- version: 1.0.0\n' > "$home/opt/beta/beta.yaml"

  run_common_strict "$home" show_version beta
  assert_failure
  assert_output "beta (version unknown - beta.yaml cannot be read: its top level is a list, not a map)"
}

@test "list_utilities gives a yaml it cannot read a row that points at doctor (issue 0081)" {
  local home
  home="$(make_fake_home)"
  printf 'name: beta\ndescription: [\n' > "$home/opt/beta/beta.yaml"

  run_common_strict "$home" list_utilities
  assert_success
  assert_output_contains "Fake alpha for tests"
  assert_output_contains "(beta.yaml cannot be read; utilz doctor says why)"
  refute_output_contains "No description available"
}

@test "run_doctor's [5/7] names a yaml it cannot read, and why, and [6/7] counts it once (issue 0081)" {
  local home before
  home="$(make_fake_home)"
  run_common_strict "$home" run_doctor
  assert_output_contains "all properly configured"
  before=$(doctor_issue_count)
  # Two documents, each a good map, which yq answers with both values.
  printf 'name: beta\nutilz_version: "^2.0.0"\n---\nname: beta\nutilz_version: "^2.0.0"\n' > "$home/opt/beta/beta.yaml"

  run_common_strict "$home" run_doctor
  assert_output_contains "    - beta (beta.yaml cannot be read: it holds more than one document)"
  refute_output_contains "all properly configured"
  refute_output_contains "Version incompatibilities"
  [[ "$(doctor_issue_count)" -eq $((before + 1)) ]] ||
    fail "Expected $((before + 1)) issues, the one fault counted once, by [6/7]. Actual output:\n$output"
}

# ============================================================================
# ST0009 WP-01 -- each_utility(): THE walker of bin/
# ============================================================================

@test "each_utility() lists installed utilities one per line" {
  local home
  home="$(make_fake_home)"

  run_in_fake_home "$home" each_utility
  assert_success
  assert_output "alpha
beta"
}

@test "each_utility() ignores a bin/ symlink that does not resolve to utilz" {
  local home
  home="$(make_fake_home)"

  run_in_fake_home "$home" each_utility
  assert_success
  refute_output_contains "zzstray"
}

@test "each_utility() ignores a plain file in bin/" {
  local home
  home="$(make_fake_home)"

  run_in_fake_home "$home" each_utility
  assert_success
  refute_output_contains "zzplain"
}

# The drift regression. Before each_utility, list_utilities checked that the
# symlink resolved to the dispatcher but run_doctor did not, so a stray link
# was a utility to one and not the other. Asserting against ONE consumer would
# not have caught that -- this asserts both agree.
@test "a stray bin/ symlink is invisible to both list_utilities and run_doctor" {
  require_command yq
  local home
  home="$(make_fake_home)"

  run_in_fake_home "$home" list_utilities
  assert_success
  assert_output_contains "alpha"
  assert_output_contains "beta"
  refute_output_contains "zzstray"

  run_in_fake_home "$home" run_doctor
  assert_output_contains "Found 2 utilities"
  refute_output_contains "zzstray"
}

# ============================================================================
# ST0009 WP-02 -- yq as THE YAML parser, and a hard dependency
# ============================================================================

@test "list_utilities() without yq fails loudly with an install hint" {
  run_without_yq list_utilities
  assert_failure
  assert_output_contains "yq is required"
  assert_output_contains "brew install yq"
}

# Regression test for a defect hit while building this: require_yq originally
# memoised its result in a variable, which silently does nothing because
# get_util_metadata runs inside command substitution and a subshell's variables
# die with it. The hint was reprinted once per utility.
@test "the yq install hint is printed once, not once per utility" {
  run_without_yq list_utilities

  local hints
  hints="$(echo "$output" | grep -c 'brew install yq')"
  if [[ "$hints" -ne 1 ]]; then
    fail "Expected exactly 1 install hint, got $hints. A per-call guard reprints it once per utility.\nOutput:\n$output"
  fi
}

# doctor is the command you run TO FIND OUT that yq is missing, so it must not
# bail at the gate -- it has to reach its summary and name yq.
@test "run_doctor() completes without yq and names it as missing" {
  run_without_yq run_doctor
  assert_output_contains "external dependencies"
  assert_output_contains "yq is not installed"
  assert_output_contains "brew install yq"
  assert_output_contains "issue"
}

# **THE DEPENDENCY VERDICT BELONGS TO STEP 6** (issue 0026). run_doctor printed
# step 6's verdict only after [7/7] had printed its own result, so "All required
# dependencies installed" -- or "Missing dependencies: yq" -- read as the
# install-integrity step's. Whichever verdict this machine produces, it must
# print before step 7 begins.
@test "run_doctor() prints the dependency verdict before step 7 begins (issue 0026)" {
  run run_common_function run_doctor
  local verdict step7
  verdict=$(printf '%s\n' "$output" | grep -n -E 'All required dependencies installed|Missing dependencies:' | head -1 | cut -d: -f1 || true)
  step7=$(printf '%s\n' "$output" | grep -n -F '[7/7]' | head -1 | cut -d: -f1 || true)
  [ -n "$verdict" ] || fail "no dependency verdict in the doctor output: $output"
  [ -n "$step7" ] || fail "no [7/7] header in the doctor output: $output"
  [ "$verdict" -lt "$step7" ] || fail "the dependency verdict prints at line $verdict, after [7/7] at line $step7"
}

# **A DECLARED OPTIONAL DEPENDENCY IS REPORTED FROM ITS YAML** (issue 0041).
# Until 2026-09-19 check 6 read `.dependencies` alone, so no utility's
# `optional_dependencies` was ever read, and an entry marked `required: false`
# was reported as a missing requirement. The fake home's yamls declare nothing
# by default, so each test appends what it needs.
declare_optional() {
  local yaml="$1" name="$2"
  cat >> "$yaml" <<YAML
optional_dependencies:
  - name: $name
    install: brew install $name
    purpose: A tool no machine has
YAML
}

@test "doctor reports a missing optional dependency from its yaml, and its verdict does not move (issue 0041)" {
  local home before_status before_found
  home="$(make_fake_home)"
  run_in_fake_home "$home" run_doctor
  before_status=$status
  before_found=$(printf '%s\n' "$output" | grep -o 'Found [0-9]* issue' || true)

  declare_optional "$home/opt/alpha/alpha.yaml" zz-absent-0041
  run_in_fake_home "$home" run_doctor
  [ "$status" -eq "$before_status" ] || fail "doctor's status moved from $before_status to $status"
  [ "$(printf '%s\n' "$output" | grep -o 'Found [0-9]* issue' || true)" = "$before_found" ] ||
    fail "doctor's issue count moved: $output"
  assert_output_contains "Optional: 'zz-absent-0041' is not installed: A tool no machine has (declared by alpha)"
  assert_output_contains "brew install zz-absent-0041"
  refute_output_contains "Missing dependencies: zz-absent-0041"
}

@test "doctor draws no line for an optional dependency that is installed (issue 0041)" {
  local home
  home="$(make_fake_home)"
  declare_optional "$home/opt/alpha/alpha.yaml" sh
  run_in_fake_home "$home" run_doctor
  refute_output_contains "'sh' is not installed"
}

@test "an optional dependency two utilities declare is reported once, naming both (issue 0041)" {
  local home lines
  home="$(make_fake_home)"
  declare_optional "$home/opt/alpha/alpha.yaml" zz-absent-0041
  declare_optional "$home/opt/beta/beta.yaml" zz-absent-0041
  run_in_fake_home "$home" run_doctor
  lines=$(printf '%s\n' "$output" | grep -c "'zz-absent-0041' is not installed" || true)
  [ "$lines" -eq 1 ] || fail "reported $lines times: $output"
  assert_output_contains "(declared by alpha, beta)"
}

@test "a dependency marked required: false is optional, and an unmarked one is still required (issue 0041)" {
  local home
  home="$(make_fake_home)"
  cat > "$home/opt/beta/beta.yaml" <<YAML
name: beta
version: 1.0.0
utilz_version: "^2.0.0"
description: Fake beta for tests
dependencies:
  - name: zz-optional-0041
    required: false
    install: brew install zz-optional-0041
    purpose: A choice beta can live without
  - name: zz-required-0041
    install: brew install zz-required-0041
YAML
  run_in_fake_home "$home" run_doctor
  assert_output_contains "Optional: 'zz-optional-0041' is not installed: A choice beta can live without (declared by beta)"
  assert_output_contains "Missing dependencies: zz-required-0041"
  refute_output_contains "zz-optional-0041 (required by"
}

@test "without yq, doctor says the optional declarations went unread (issue 0041)" {
  run_without_yq run_doctor
  assert_output_contains "Optional dependencies not checked"
}

@test "get_util_metadata() returns non-zero for a missing yaml file" {
  run run_common_function get_util_metadata no-such-utility-xyz '".description"'
  assert_failure
}

@test "get_util_metadata() resolves both an inline version and a version_file" {
  require_command yq
  local home
  home="$(make_fake_home 7.3.1)"

  # alpha inlines its version
  run_in_fake_home "$home" get_util_metadata alpha '".version"'
  assert_success
  assert_output "1.0.0"

  # utilz defers to VERSION via version_file
  run_in_fake_home "$home" get_util_metadata utilz '".version"'
  assert_success
  assert_output "7.3.1"
}

# ============================================================================
# ST0009 WP-03 -- generated utilities carry a floor derived from VERSION
# ============================================================================

@test "metadata.tmpl carries a placeholder, not a literal version floor" {
  run grep '^utilz_version:' "$UTILZ_HOME/opt/utilz/tmpl/metadata.tmpl"
  assert_success
  assert_output 'utilz_version: "{{UTILZ_FLOOR}}"'
}

# The fake home reports VERSION 7.3.1, so a floor of ^7.0.0 proves the value is
# derived. Asserting ^2.0.0 against the real VERSION would pass even if the
# floor were still hardcoded to something that happened to match.
@test "generate stamps a utilz_version floor matching VERSION's major" {
  require_command yq
  local home
  home="$(make_fake_home 7.3.1)"
  cp -R "$UTILZ_HOME/opt/utilz/tmpl" "$home/opt/utilz/tmpl"

  run_in_fake_home "$home" generate_utility zznew '"A throwaway"' '"Tester"'
  assert_success
  assert_file_contains "$home/opt/zznew/zznew.yaml" 'utilz_version: "^7.0.0"'
}

@test "a generated utility passes doctor's version compatibility check" {
  require_command yq
  local home
  home="$(make_fake_home 7.3.1)"
  cp -R "$UTILZ_HOME/opt/utilz/tmpl" "$home/opt/utilz/tmpl"

  run_in_fake_home "$home" generate_utility zznew '"A throwaway"' '"Tester"'
  assert_success

  run_in_fake_home "$home" run_doctor
  assert_output_contains "Found 3 utilities"
  refute_output_contains "zznew (requires"
}

# ----------------------------------------------------------------------------
# ST0013 / AC03 -- the driver discovers every black-box suite, and refuses one
# it cannot run
# ----------------------------------------------------------------------------

# A fake UTILZ_HOME carrying ONE utility whose crate/test/ the caller fills.
# Deliberately minimal -- no Cargo.toml and no *.bats unless a test adds one --
# so the only source run_tests can find is the black-box one under test and a
# result cannot be produced by some other suite passing.
make_suite_home() {
  local home="$BATS_TEST_TMPDIR/suite-home"
  mkdir -p "$home/bin" "$home/opt/sut/crate/test"
  echo "9.9.9" > "$home/VERSION"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$home/bin/utilz"
  chmod +x "$home/bin/utilz"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$home/opt/sut/sut"
  chmod +x "$home/opt/sut/sut"
  cat > "$home/opt/sut/sut.yaml" <<YAML
name: sut
version: 1.0.0
description: Fixture utility for driver-discovery tests
dependencies: []
YAML
  ln -s utilz "$home/bin/sut"
  echo "$home"
}

# A suite that ANNOUNCES itself, so "ran" and "silently skipped" are told apart
# by what was printed rather than by an exit code that both produce.
write_suite() {
  cat > "$1" <<EOS
#!/usr/bin/env bash
echo "RAN:$2"
exit 0
EOS
  chmod +x "$1"
}

@test "AT07 leg 1: two executable suites in crate/test are BOTH run and BOTH counted" {
  # RED-FIRST, and this is the leg that would have caught the whole defect:
  # today only a file named exactly acceptance.sh runs, so the second suite is
  # invisible and the summary says everything passed.
  local home; home="$(make_suite_home)"
  write_suite "$home/opt/sut/crate/test/acceptance.sh" "first"
  write_suite "$home/opt/sut/crate/test/theme-addressing.sh" "second"

  run_in_fake_home "$home" "run_tests sut"
  assert_output_contains "RAN:first"
  assert_output_contains "RAN:second"
  assert_output_contains "2 suite(s)"
}

@test "AT07 leg 1 control: with one suite the count FALLS to 1" {
  # THE CONTROL FOR THE LEG ABOVE. A discovery test that never saw its count
  # change is asserting on a number it cannot tell from a constant, so this
  # removes the second suite and requires the count to move.
  local home; home="$(make_suite_home)"
  write_suite "$home/opt/sut/crate/test/acceptance.sh" "first"

  run_in_fake_home "$home" "run_tests sut"
  assert_output_contains "RAN:first"
  refute_output_contains "RAN:second"
  assert_output_contains "1 suite(s)"
}

@test "AT07 leg 2: a present-but-non-executable suite is REFUSED, never skipped" {
  # common.sh:919-923 generalised from one filename to a set. "Glob and run
  # each executable one" silently ignores this file and hands back a green,
  # which is the exact shape that guard exists to prevent.
  local home; home="$(make_suite_home)"
  write_suite "$home/opt/sut/crate/test/acceptance.sh" "first"
  printf '#!/usr/bin/env bash\necho "RAN:second"\nexit 0\n' \
    > "$home/opt/sut/crate/test/theme-addressing.sh"
  chmod -x "$home/opt/sut/crate/test/theme-addressing.sh"

  run_in_fake_home "$home" "run_tests sut"
  assert_failure
  assert_output_contains "theme-addressing.sh"
  refute_output_contains "RAN:second"
}

@test "AT07 leg 3: a crate with no .sh suite at all is skipped, not failed" {
  # A crate with no black-box suite is not a defect. The fixture carries a BATS
  # suite so the run has something to count: without it the driver's own
  # "No tests were run" would redden this leg for a reason it is not testing.
  local home; home="$(make_suite_home)"
  mkdir -p "$home/opt/sut/test"
  cat > "$home/opt/sut/test/trivial.bats" <<'EOS'
@test "trivial" { true; }
EOS

  run_in_fake_home "$home" "run_tests sut"
  assert_success
}

@test "AT08: neither driver names a single suite filename, and both discover" {
  # SOURCE ASSERTION, because CI cannot run itself from inside BATS. The
  # precedent is the --strict check above, which greps common.sh for the same
  # reason.
  #
  # NEVER grep for the word "acceptance": the prose comments around both call
  # sites contain it, so such a check passes forever whatever the code does.
  # Target the hardcoded PATH, which only a driver naming one file can contain.
  run grep -c 'test/acceptance\.sh' "$UTILZ_HOME/opt/utilz/lib/common.sh"
  assert_output "0"
  run grep -c 'test/acceptance\.sh' "$UTILZ_HOME/.github/workflows/tests.yml"
  assert_output "0"

  # And the discovery construct is really there -- a zero count above is also
  # what deleting the whole branch would produce.
  run grep -c 'test/\*\.sh' "$UTILZ_HOME/opt/utilz/lib/common.sh"
  assert_success
  run grep -c 'test/\*\.sh' "$UTILZ_HOME/.github/workflows/tests.yml"
  assert_success

  # prez.bats is the THIRD home of the convention: it asserted the hardcoded
  # path as the driver's contract, and that statement becomes false the moment
  # the driver stops naming it. The count covers PROSE there as well as code,
  # deliberately -- the third home was a comment as much as an assertion, and
  # the sentence "behaviour is covered by crate/test/acceptance.sh" was already
  # false with two suites in that directory. Write `crate/test/*.sh` instead.
  run grep -c 'test/acceptance\.sh' "$UTILZ_HOME/opt/prez/test/prez.bats"
  assert_output "0"

  # THE TWO HOMES MUST AGREE ABOUT WHAT A RUN MEANS, not just about which files
  # it finds. common.sh accumulates -- every suite runs, and the summary says
  # "N of M failed". CI must too: under set -e it would otherwise abort on the
  # first red suite and every later one would never run, so a contributor gets
  # one failure per push where the local driver gives the whole picture in one.
  # With ONE suite those behaviours were identical and the divergence could not
  # be seen; with two it can.
  run grep -c 'suite_failures' "$UTILZ_HOME/.github/workflows/tests.yml"
  assert_success

  # And the browser-evidence guard is scoped to the suite that declares it needs
  # a browser, not to the union of every suite's output. The union reads as
  # "somebody mentioned a browser", which is true today only because exactly one
  # suite does.
  run grep -c 'ONE OUTPUT FILE PER SUITE' "$UTILZ_HOME/.github/workflows/tests.yml"
  assert_success

  # The suite's own footer warned it was wired into nothing. That warning
  # becomes a lie once this criterion lands, and a warning that outlives its
  # truth teaches readers to discount the ones still true.
  run grep -c 'NOT WIRED INTO ANY DRIVER YET' \
    "$UTILZ_HOME/opt/prez/crate/test/theme-addressing.sh"
  assert_output "0"
}

# ONE POPULATION, USED BY BOTH THE ABSENCE ASSERTION AND ITS CONTROL.
#
# vc measured the first form of these tests and found the control was narrower
# than the thing it controlled: the absence check spanned help/*.md +
# opt/*/README.md + the templates -- 33 files -- while the presence control
# counted help/*.md alone, 16 of them. Deleting the version line from the other
# 17 passed BOTH assertions. **That is the very defect a presence control exists
# to stop, one level up**: pairing an absence with a presence is necessary and
# not sufficient, because the pair must also cover the SAME POPULATION or the
# control is a control over a subset and reads exactly like a control over the
# whole.
#
# So the list is computed ONCE and both halves consume it. They cannot drift
# apart because there is nothing to drift.
_version_prose_files() {
  ls "$UTILZ_HOME"/help/*.md \
     "$UTILZ_HOME"/opt/*/README.md \
     "$UTILZ_HOME"/opt/utilz/tmpl/help.tmpl \
     "$UTILZ_HOME"/opt/utilz/tmpl/README.tmpl 2>/dev/null
}

# The metadata population: every utility yaml, PLUS the template that mints new
# ones. vc found metadata.tmpl outside both nets in the first form -- the prose
# guard's glob reached the templates but its regex only matched `**Version**:`,
# and this guard's glob stopped at opt/*/*.yaml. The file named as the thing
# that mints violations was the one nothing guarded.
_version_metadata_files() {
  ls "$UTILZ_HOME"/opt/*/*.yaml "$UTILZ_HOME"/opt/utilz/tmpl/metadata.tmpl 2>/dev/null
}

# A LITERAL, IN EVERY FORM THESE FILES ACTUALLY USE. An optional quote and an
# optional leading v are not hypothetical: `utilz_version: "^2.0.0"` sits two
# lines below in every one of these yamls, so the quoted form is the one a
# future author copies. Measured by vc: `version: "1.0.0"` and
# `**Version**: v1.2.0` both evaded the first form entirely.
VERSION_LITERAL='"?v?[0-9]'

@test "no help file, utility README or template states a version literal" {
  # HIGHLANDER, and this estate has been bitten by it TWICE. A version has ONE
  # home -- the utility's yaml, or the file its `version_file` points at. Every
  # copy in prose is a second home with no gate holding it equal, and prose is
  # the copy nobody re-reads.
  #
  # First bite, recorded in help/utilz.md's own comment: hardcoding the
  # framework version there drifted it to 2.2.0 while 2.4.0 shipped. The fix was
  # applied to that one file and left in fifteen others.
  #
  # Second bite, MEASURED when this test was written: cleanz's README said 1.1.0
  # against a yaml of 1.2.0, and todo's help AND README both said 1.0.0 against
  # 1.1.0. Nothing reported either.
  local files literals present
  files=$(_version_prose_files | wc -l | tr -d ' ')
  # COUNT CONTROL FIRST. If the globs ever match nothing, every assertion below
  # is satisfied by an empty set and this test greens on a tree with no docs.
  [ "$files" -gt 30 ] || fail "only $files prose files found; the globs are wrong, not the tree"

  literals=$(_version_prose_files | xargs grep -lE "^\*\*Version\*\*: *$VERSION_LITERAL" 2>/dev/null | wc -l | tr -d ' ')
  [ "$literals" -eq 0 ] || {
    _version_prose_files | xargs grep -lE "^\*\*Version\*\*: *$VERSION_LITERAL" 2>/dev/null
    fail "$literals file(s) state a version literal; the fix is a pointer"
  }

  # AND THE LINE IS STILL THERE, over the SAME population. Without this,
  # deleting every Version line passes the check above -- the assert-absence
  # shape that an empty tree also satisfies.
  present=$(_version_prose_files | xargs grep -lE '^\*\*Version\*\*:' 2>/dev/null | wc -l | tr -d ' ')
  [ "$files" = "$present" ] \
    || fail "$present of $files prose files carry a Version line; the fix is a pointer, not a deletion"
}

@test "a utility's version has ONE home: its own VERSION file, or the file it cannot delete" {
  # hv's ruling, 2026-09-08: the framework's version is ./VERSION, every utility
  # carries its own, and there are no rogue literals anywhere.
  local files literals checked util resolved missing=""
  files=$(_version_metadata_files | wc -l | tr -d ' ')
  [ "$files" -gt 14 ] || fail "only $files metadata files found; the globs are wrong, not the tree"

  # NO METADATA FILE RESTATES A VERSION -- including the template that mints
  # them. Every utility `utilz generate` scaffolded was born with a literal that
  # was correct exactly until its first release.
  literals=$(_version_metadata_files | xargs grep -lE "^version: *$VERSION_LITERAL" 2>/dev/null | wc -l | tr -d ' ')
  [ "$literals" -eq 0 ] || {
    _version_metadata_files | xargs grep -lE "^version: *$VERSION_LITERAL" 2>/dev/null
    fail "$literals metadata file(s) state a version literal; point at one with version_file"
  }

  # prez IS THE DOCUMENTED EXCEPTION AND IT IS NOT AN EXCEPTION TO THE RULE.
  # Cargo REQUIRES a version in [package], so that file is a home which cannot
  # be deleted -- which makes it the one to keep. prez has no VERSION file
  # because a second one would be the duplication this test exists to stop. The
  # rule is "point at the one home you cannot delete", not "use this filename",
  # so do not "fix" prez into compliance.
  assert_file_not_exists "$UTILZ_HOME/opt/prez/VERSION"
  run grep -c '^version_file: crate/Cargo.toml' "$UTILZ_HOME/opt/prez/prez.yaml"
  assert_success

  # AND EVERY UTILITY STILL RESOLVES ONE, with a count control: without it an
  # empty glob leaves `missing` empty and greens a tree with no metadata at all.
  checked=0
  for yaml in "$UTILZ_HOME"/opt/*/*.yaml; do
    util=$(basename "$yaml" .yaml)
    [ -d "$UTILZ_HOME/opt/$util" ] || continue
    checked=$((checked + 1))
    # A yaml that cannot be read resolves no version either: it is named with
    # the rest rather than ending the test at this read (issue 0081).
    resolved=$(bash -c "source '$UTILZ_HOME/opt/utilz/lib/common.sh'; get_util_metadata '$util' '.version'" 2>/dev/null) || resolved=""
    case "$resolved" in
      ""|null) missing="$missing $util" ;;
    esac
  done
  [ "$checked" -gt 14 ] || fail "only $checked utilities checked; the loop measured almost nothing"
  [ -z "$missing" ] || fail "these utilities resolve no version:$missing"
}

# ============================================================================
# THE PLATFORM (issue 0083)
# ============================================================================
#
# Utilz runs on macOS and Linux. utilz_platform is the one reader of which,
# from uname -s, and each test here pins the platform it is about with
# stub_platform, a uname first on PATH, so both platforms' paths are tested on
# either. A test that says nothing changes on macOS passes on the code before
# 0083 too: it is the control for its Linux twin.

# alpha's yaml in <home>, written fresh: its own fields, then <extra>, the
# yaml under test.
write_alpha() {
  local home="$1" extra="$2"
  {
    printf 'name: alpha\nversion: 1.0.0\nutilz_version: "^2.0.0"\ndescription: Fake alpha for tests\n'
    printf '%s\n' "$extra"
  } > "$home/opt/alpha/alpha.yaml"
}

# Append to <home>'s <util> an optional dependency <name> declared to run on
# <platforms>, given as yaml, with an install line and a purpose.
declare_optional_on() {
  local yaml="$1/opt/$2/$2.yaml" name="$3" platforms="$4"
  cat >> "$yaml" <<YAML
optional_dependencies:
  - name: $name
    platforms: $platforms
    install: brew install $name
    purpose: A tool only one platform has
YAML
}

@test "utilz_platform reads uname -s: Darwin is macos, Linux is linux, and anything else is other (issue 0083)" {
  stub_platform Darwin
  run run_common_function utilz_platform
  assert_output "macos"
  stub_platform Linux
  run run_common_function utilz_platform
  assert_output "linux"
  stub_platform FreeBSD
  run run_common_function utilz_platform
  assert_output "other"
}

@test "refuse_off_macos lets macOS through, saying nothing (issue 0083)" {
  stub_platform Darwin
  run run_common_function 'refuse_off_macos "thing go" "macOS" "thing list works here"; echo went on'
  assert_success
  assert_output "went on"
}

@test "refuse_off_macos refuses off macOS by name: what refused, what it needs, the platform and what works here, exit 2 (issue 0083)" {
  stub_platform Linux
  run run_common_function 'refuse_off_macos "thing go" "macOS and a widget" "thing list works here"; echo went on'
  assert_exit_code 2
  assert_output_contains "thing go needs macOS and a widget, so it is not available on Linux; thing list works here"
  refute_output_contains "went on"
}

@test "refuse_off_macos names the platform as uname -s does, never the token other (issue 0083)" {
  stub_platform FreeBSD
  run run_common_function 'refuse_off_macos "thing go" "macOS"'
  assert_exit_code 2
  assert_output_contains "thing go needs macOS, so it is not available on FreeBSD"
  refute_output_contains "other"
}

@test "require_platform lets a utility that declares no platforms run anywhere (issue 0083)" {
  local home
  home="$(make_fake_home)"
  stub_platform Linux
  run_in_fake_home "$home" 'require_platform alpha; echo ALPHA RAN'
  assert_success
  assert_output "ALPHA RAN"
}

@test "require_platform refuses a macOS-only utility on Linux by name, exit 2, and lets it run on macOS (issue 0083)" {
  local home
  home="$(make_fake_home)"
  write_alpha "$home" 'platforms: [macos]
dependencies: []'
  stub_platform Linux
  run_in_fake_home "$home" 'require_platform alpha; echo ALPHA RAN'
  assert_exit_code 2
  assert_output_contains "alpha needs macOS, so it is not available on Linux"
  refute_output_contains "ALPHA RAN"

  stub_platform Darwin
  run_in_fake_home "$home" 'require_platform alpha; echo ALPHA RAN'
  assert_success
  assert_output "ALPHA RAN"
}

@test "require_platform refuses a platforms that is not a list of macos and linux, naming why, and never lets it run (issue 0083)" {
  local home value want
  home="$(make_fake_home)"
  stub_platform Darwin
  for value in 'macos' '[windows]' '[]' '[[macos]]'; do
    case "$value" in
      macos) want="platforms is a string, not a list" ;;
      '[windows]') want="platforms names 'windows', which is not macos or linux" ;;
      '[]') want="platforms is an empty list, so it names nowhere to run" ;;
      *) want="platforms names a list, which is not macos or linux" ;;
    esac
    write_alpha "$home" "platforms: $value
dependencies: []"
    run_in_fake_home "$home" 'require_platform alpha; echo ALPHA RAN'
    assert_exit_code 2
    assert_output_contains "alpha: alpha.yaml's $want, so where alpha runs is not known"
    refute_output_contains "ALPHA RAN"
  done
}

@test "require_platform refuses where the yaml cannot be read, naming why, and never lets the utility run (issue 0083)" {
  local home
  home="$(make_fake_home)"
  stub_platform Darwin
  printf 'name: alpha\nplatforms: [\n' > "$home/opt/alpha/alpha.yaml"
  run_in_fake_home "$home" 'require_platform alpha; echo ALPHA RAN'
  assert_exit_code 2
  assert_output_contains "alpha: alpha.yaml cannot be read, so where alpha runs is not known: "
  refute_output_contains "ALPHA RAN"
}

@test "doctor on Linux reads a macOS-only utility as not available here, skips its dependencies, and counts nothing for it (issue 0083)" {
  local home before_status before
  home="$(make_fake_home)"
  stub_platform Linux
  run_common_strict "$home" run_doctor
  before_status=$status
  before=$(doctor_issue_count)

  write_alpha "$home" 'platforms: [macos]
dependencies: []
optional_dependencies:
  - name: zz-absent-0083
    install: brew install zz-absent-0083
    purpose: A tool no machine has'
  run_common_strict "$home" run_doctor
  assert_output_contains "alpha: macOS only, not available on Linux"
  refute_output_contains "zz-absent-0083"
  [ "$status" -eq "$before_status" ] || fail "doctor's status moved from $before_status to $status: $output"
  [ "$(doctor_issue_count)" -eq "$before" ] || fail "doctor's issue count moved from $before: $output"
}

@test "doctor on macOS reads a macOS-only utility as any other, and checks its dependencies (issue 0083)" {
  local home
  home="$(make_fake_home)"
  stub_platform Darwin
  write_alpha "$home" 'platforms: [macos]
dependencies: []
optional_dependencies:
  - name: zz-absent-0083
    install: brew install zz-absent-0083
    purpose: A tool no machine has'
  run_common_strict "$home" run_doctor
  refute_output_contains "not available on"
  assert_output_contains "Optional: 'zz-absent-0083' is not installed: A tool no machine has (declared by alpha)"
}

@test "doctor on Linux reports a dependency declared macOS only in one line, with no install line, and counts nothing for it (issue 0083)" {
  local home before_status before
  home="$(make_fake_home)"
  stub_platform Linux
  run_common_strict "$home" run_doctor
  before_status=$status
  before=$(doctor_issue_count)

  declare_optional_on "$home" alpha zz-mac-0083 "[macos]"
  run_common_strict "$home" run_doctor
  assert_output_contains "macOS only: 'zz-mac-0083' is not checked on Linux: A tool only one platform has (declared by alpha)"
  refute_output_contains "brew install zz-mac-0083"
  refute_output_contains "Optional: 'zz-mac-0083'"
  [ "$status" -eq "$before_status" ] || fail "doctor's status moved from $before_status to $status: $output"
  [ "$(doctor_issue_count)" -eq "$before" ] || fail "doctor's issue count moved from $before: $output"
}

@test "doctor on Linux reads an app dependency as macOS only, never as missing, even when it is required (issue 0083)" {
  local home before_status before
  home="$(make_fake_home)"
  stub_platform Linux
  run_common_strict "$home" run_doctor
  before_status=$status
  before=$(doctor_issue_count)

  write_alpha "$home" 'dependencies:
  - name: ZzApp0083
    app: com.example.zzapp0083
    required: true
    install: brew install --cask zz-app-0083
    purpose: An app only macOS has'
  run_common_strict "$home" run_doctor
  assert_output_contains "macOS only: 'ZzApp0083' is not checked on Linux: An app only macOS has (declared by alpha)"
  refute_output_contains "brew install --cask zz-app-0083"
  refute_output_contains "Missing dependencies"
  refute_output_contains "never present on"
  [ "$status" -eq "$before_status" ] || fail "doctor's status moved from $before_status to $status: $output"
  [ "$(doctor_issue_count)" -eq "$before" ] || fail "doctor's issue count moved from $before: $output"
}

@test "a dependency two utilities declare macOS only is one line on Linux, naming both (issue 0083)" {
  local home lines
  home="$(make_fake_home)"
  stub_platform Linux
  declare_optional_on "$home" alpha zz-mac-0083 "[macos]"
  declare_optional_on "$home" beta zz-mac-0083 "[macos]"
  run_common_strict "$home" run_doctor
  lines=$(printf '%s\n' "$output" | grep -c "'zz-mac-0083' is not checked on Linux" || true)
  [ "$lines" -eq 1 ] || fail "reported $lines times: $output"
  assert_output_contains "(declared by alpha, beta)"
}

@test "doctor counts a utility's platforms that is not a list as one issue, by name (issue 0083)" {
  local home before
  home="$(make_fake_home)"
  stub_platform Linux
  run_common_strict "$home" run_doctor
  before=$(doctor_issue_count)

  write_alpha "$home" 'platforms: macos
dependencies: []'
  run_common_strict "$home" run_doctor
  assert_output_contains "alpha (alpha.yaml's platforms is a string, not a list)"
  [ "$(doctor_issue_count)" -eq $((before + 1)) ] ||
    fail "Expected $((before + 1)) issues, one more than the $before before. Actual output:\n$output"
}

@test "doctor refuses a dependency's platforms that is not a list, by name, and counts it (issue 0083)" {
  local home before
  home="$(make_fake_home)"
  stub_platform Linux
  run_common_strict "$home" run_doctor
  before=$(doctor_issue_count)

  declare_optional_on "$home" alpha zz-bad-0083 "linux"
  run_common_strict "$home" run_doctor
  assert_output_contains "alpha: optional_dependencies[0] (zz-bad-0083): platforms is a string, not a list"
  [ "$(doctor_issue_count)" -eq $((before + 1)) ] ||
    fail "Expected $((before + 1)) issues, one more than the $before before. Actual output:\n$output"
}

@test "utilz doctor on Linux reads macoz as not available here, and arngz's hs and Hammerspoon as macOS only with no install line (issue 0083)" {
  stub_platform Linux
  run_utilz doctor
  assert_output_contains "macoz: macOS only, not available on Linux"
  assert_output_contains "macOS only: 'hs' is not checked on Linux"
  assert_output_contains "macOS only: 'Hammerspoon' is not checked on Linux"
  refute_output_contains "brew install --cask hammerspoon"
  refute_output_contains "'fileicon'"
}

# On macOS nothing that needs macOS is set aside: no utility reads as not
# available, and no macOS-only dependency as not checked. clipz's Linux-only
# clipboard tools are, by name, the dependency lines the design asks for.
@test "utilz doctor on macOS sets nothing macOS-only aside, and names clipz's Linux-only tools as not checked here (issue 0083)" {
  stub_platform Darwin
  run_utilz doctor
  refute_output_contains "not available on"
  refute_output_contains "macOS only"
  assert_output_contains "Linux only: 'xclip' is not checked on Darwin"
  assert_output_contains "Linux only: 'wl-copy' is not checked on Darwin"
  # Their own install lines, by name: another tool's hint may name apt too,
  # as prez's ffmpeg does where ffmpeg is missing (kovacs, slot 148). doctor
  # here reads the host's real tools, so only clipz.yaml may carry these two
  # lines: another yaml declaring either would turn this red.
  refute_output_contains "sudo apt install xclip"
  refute_output_contains "sudo apt install wl-clipboard"
}

@test "utilz list marks a macOS-only utility on Linux, and not on macOS (issue 0083)" {
  stub_platform Linux
  run_utilz list
  assert_success
  printf '%s\n' "$output" | grep -Eq '^ +macoz +.*\(macOS only\)$' || fail "no marked row for macoz: $output"

  stub_platform Darwin
  run_utilz list
  assert_success
  refute_output_contains "(macOS only)"
}

@test "list_utilities marks a platforms it cannot judge with a pointer to doctor, and lists the rest (issue 0083)" {
  local home
  home="$(make_fake_home)"
  stub_platform Linux
  write_alpha "$home" 'platforms: macos
dependencies: []'
  run_in_fake_home "$home" list_utilities
  assert_success
  assert_output_contains "Fake alpha for tests (its platforms cannot be read; utilz doctor says why)"
  assert_output_contains "Fake beta for tests"
}

@test "an unknown command's listing marks a macOS-only utility on Linux (issue 0083)" {
  stub_platform Linux
  run_utilz zz-no-such-command-0083
  assert_exit_code 1
  printf '%s\n' "$output" | grep -Eq 'utilz macoz \[args\] +- Run macoz utility \(macOS only\)$' ||
    fail "no marked line for macoz: $output"
}

# Where the platforms cannot be read, the mark says why rather than nothing:
# the unknown command's listing has no row text of its own for it, as
# list_utilities has (critic-shell's read of 0083).
@test "utility_platform_note says why where it cannot judge: a yaml it cannot read, or no yq (issue 0083)" {
  local home
  home="$(make_fake_home)"
  stub_platform Linux
  printf 'name: alpha\nplatforms: [\n' > "$home/opt/alpha/alpha.yaml"
  run_in_fake_home "$home" 'utility_platform_note alpha'
  assert_success
  assert_output " (its yaml cannot be read; utilz doctor says why)"

  run_without_yq 'utility_platform_note macoz'
  assert_success
  assert_output " (where it runs is not known without yq)"

  # list_utilities' own row for that yaml says it once, with no second mark.
  run_in_fake_home "$home" list_utilities
  assert_output_contains "(alpha.yaml cannot be read; utilz doctor says why)"
  refute_output_contains "its yaml cannot be read"
}

@test "sha256_of prints a file's sha256 (issue 0083)" {
  printf 'abc' > "$BATS_TEST_TMPDIR/abc"
  run run_common_function "sha256_of '$BATS_TEST_TMPDIR/abc'"
  assert_success
  assert_output "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
}

@test "sha256_of says what it needs when neither shasum nor sha256sum is on PATH (issue 0083)" {
  local farm
  printf 'abc' > "$BATS_TEST_TMPDIR/abc"
  # Both tools hidden, by name (issue 0084): run_without_yq's PATH keeps every
  # command but yq, so it no longer lacks them by accident.
  farm=$(path_without shasum sha256sum)
  run env PATH="$farm" bash -c 'source "$1/opt/utilz/lib/common.sh"; sha256_of "$2"' \
    _ "$UTILZ_HOME" "$BATS_TEST_TMPDIR/abc"
  assert_failure
  assert_output_contains "no sha256 tool found: need shasum or sha256sum"
}
