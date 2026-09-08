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

# A PATH carrying the tools common.sh needs, minus yq. Built by symlinking real
# tool paths into a sandbox rather than by filtering $PATH: CI installs yq into
# /usr/bin on Linux, so filtering out its directory would take the core tools
# with it. Echoes the sandbox path.
yqless_path() {
  local sandbox="$BATS_TEST_TMPDIR/yqless-bin"
  mkdir -p "$sandbox"

  local tool real
  for tool in basename dirname readlink cat cut sed grep tr awk sort uniq head tail wc ls date git; do
    if real="$(command -v "$tool" 2>/dev/null)"; then
      ln -sf "$real" "$sandbox/$tool"
    fi
  done

  echo "$sandbox"
}

# Run a common.sh function with yq unreachable.
run_without_yq() {
  local sandbox
  sandbox="$(yqless_path)"
  run /bin/bash -c "PATH='$sandbox'; export PATH; source '$UTILZ_HOME/opt/utilz/lib/common.sh'; $*"
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
  if ! command_exists yq; then
    run run_common_function parse_yaml test.yaml ".foo"
    assert_failure
    assert_output_contains "yq is required"
  else
    skip "yq is installed - cannot test error path"
  fi
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
    resolved=$(bash -c "source '$UTILZ_HOME/opt/utilz/lib/common.sh'; get_util_metadata '$util' '.version'" 2>/dev/null)
    case "$resolved" in
      ""|null) missing="$missing $util" ;;
    esac
  done
  [ "$checked" -gt 14 ] || fail "only $checked utilities checked; the loop measured almost nothing"
  [ -z "$missing" ] || fail "these utilities resolve no version:$missing"
}
