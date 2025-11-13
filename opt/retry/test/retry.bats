#!/usr/bin/env bats
# retry.bats - Tests for retry utility

# Load test helper from core utilz tests
load "../../utilz/test/test_helper.bash"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

run_retry() {
    run "$UTILZ_BIN_DIR/retry" "$@"
}

# ============================================================================
# BASIC TESTS
# ============================================================================

@test "retry --help shows usage" {
    run_retry --help
    assert_success
    assert_output_contains "Usage"
    assert_output_contains "retry"
    assert_output_contains "wait"
    assert_output_contains "retries"
}

@test "retry --version shows version" {
    run_retry --version
    assert_success
    assert_output_contains "retry"
    assert_output_contains "v"
}

@test "retry with unknown option shows error" {
    run_retry --invalid-option
    assert_failure
    assert_output_contains "Unknown option"
}

@test "retry with no command shows error" {
    run_retry
    assert_failure
    assert_output_contains "No command provided"
}

# ============================================================================
# FUNCTIONALITY TESTS
# ============================================================================

@test "retry succeeds immediately for successful command" {
    run_retry "true"
    assert_success
    assert_output_contains "Command succeeded"
}

@test "retry fails for always-failing command with max retries" {
    run_retry --retries 2 --wait 1 "false"
    assert_failure
    assert_output_contains "Maximum retries reached"
}

@test "retry accepts wait time option" {
    run_retry --wait 1 "true"
    assert_success
    assert_output_contains "1s delay"
}

@test "retry accepts retries option" {
    run_retry --retries 5 "true"
    assert_success
    assert_output_contains "max 5 retries"
}

@test "retry short options work" {
    run_retry -w 1 -r 2 "true"
    assert_success
}

@test "retry with complex command" {
    run_retry --wait 1 --retries 1 "echo 'hello world'"
    assert_success
    assert_output_contains "hello world"
}

# ============================================================================
# RETRY BEHAVIOR TESTS
# ============================================================================

@test "retry attempts multiple times before succeeding" {
    # Create a file that will succeed after 2 attempts
    local test_file="$BATS_TEST_TMPDIR/retry_count"
    echo "0" > "$test_file"

    # Command that fails twice then succeeds
    local cmd="count=\$(cat $test_file); echo \$((count + 1)) > $test_file; [ \$count -ge 2 ]"

    run_retry --wait 1 --retries 5 "$cmd"
    assert_success
    assert_output_contains "Command succeeded"

    rm -f "$test_file"
}

@test "retry stops after max retries" {
    # Command that always fails
    run_retry --wait 1 --retries 2 "exit 1"
    assert_failure
    assert_output_contains "Maximum retries reached"
    assert_output_contains "2 attempts"
}
