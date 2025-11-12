#!/usr/bin/env bats
# integration.bats - End-to-end integration tests for Utilz framework

load "test_helper.bash"

# ============================================================================
# COMPLETE WORKFLOWS
# ============================================================================

@test "complete workflow: run doctor, list utilities, get help" {
    # Run doctor
    run_utilz doctor
    assert_output_contains "Utilz Doctor"

    # List utilities
    run_utilz list
    assert_success
    assert_output_contains "mdagg"

    # Get help for a utility
    run_utilz help mdagg
    assert_success
    assert_output_contains "mdagg"
}

@test "complete workflow: create markdown files, aggregate with mdagg" {
    # Create test markdown files
    create_markdown_files 3

    # Aggregate with glob mode
    run_mdagg "test*.md"
    assert_success
    assert_output_contains "Test File 1"
    assert_output_contains "Test File 2"
    assert_output_contains "Test File 3"
}

@test "complete workflow: create YAML config, run mdagg with config" {
    # Create test markdown files
    create_markdown_files 2

    # Create YAML config
    create_mdagg_yaml_config "config.yaml"

    # Run mdagg with config (requires yq)
    if ! command_exists yq; then
        skip "yq not installed"
    fi

    run_mdagg config.yaml
    assert_success
    assert_output_contains "Test File 1"
    assert_output_contains "Test File 2"
}

@test "complete workflow: help system works for all utilities" {
    # Get list of utilities
    run_utilz list
    assert_success

    # Test help for utilz itself
    run_utilz help
    assert_success
    assert_output_contains "Utilz"

    # Test help for mdagg
    run_utilz help mdagg
    assert_success
    assert_output_contains "mdagg"
}

@test "complete workflow: create test utility, invoke it, clean up" {
    # Create a test utility
    local util_name="testutil"
    create_test_utility "$util_name" > /dev/null

    # Verify it appears in list
    run_utilz list
    assert_success
    assert_output_contains "$util_name"

    # Invoke it
    run_utility "$util_name" arg1 arg2
    assert_success
    assert_output_contains "Test utility invoked"
    assert_output_contains "arg1 arg2"

    # Get help
    run_utilz help "$util_name"
    assert_success

    # Clean up
    remove_test_utility "$util_name"

    # Verify it's gone
    run_utilz list
    assert_success
    refute_output_contains "$util_name"
}

@test "error recovery: broken utility detected by doctor" {
    # Create a utility with missing implementation
    ln -sf utilz "$UTILZ_BIN_DIR/brokenutil"

    # Doctor should detect the issue
    run_utilz doctor
    # Doctor may pass or warn, but should mention the broken utility
    assert_output_contains "brokenutil"

    # Cleanup
    rm -f "$UTILZ_BIN_DIR/brokenutil"
}
