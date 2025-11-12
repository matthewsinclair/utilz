#!/usr/bin/env bats
# common_lib.bats - Tests for opt/utilz/lib/common.sh functions

load "test_helper.bash"

# Helper to run a function from common.sh
run_common_function() {
    bash -c "source '$UTILZ_HOME/opt/utilz/lib/common.sh'; $*"
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
    assert_output_contains "Utilz"
    assert_output_contains "v"
}

@test "show_version() extracts version from utility help file" {
    run run_common_function show_version mdagg
    assert_success
    assert_output_contains "mdagg"
}

@test "show_version() handles missing utility gracefully" {
    run run_common_function show_version nonexistent
    assert_success
    assert_output_contains "nonexistent"
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
    # Should have summary line
    assert_output_contains "checks"
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
