#!/usr/bin/env bats
# expz.bats - Tests for expz utility

# Load test helper from core utilz tests
load "../../utilz/test/test_helper.bash"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

run_expz() {
  run "$UTILZ_BIN_DIR/expz" "$@"
}

# ============================================================================
# BASIC TESTS
# ============================================================================

@test "expz --help shows usage" {
  run_expz --help
  assert_success
  assert_output_contains "expz"
}

@test "expz --version shows version" {
  run_expz --version
  assert_success
  assert_output_contains "expz"
  assert_output_contains "v"
}

@test "expz with unknown option shows error" {
  run_expz --invalid-option
  assert_failure
  assert_output_contains "Unknown option"
}

# ============================================================================
# ARGUMENT VALIDATION TESTS
# ============================================================================

@test "expz with no arguments shows error" {
  run_expz
  assert_failure
  assert_output_contains "Missing required argument"
}

@test "expz with non-existent directory shows error" {
  run_expz /tmp/nonexistent_expz_dir_$$
  assert_failure
  assert_output_contains "Directory not found"
}

@test "expz with empty directory shows error" {
  local tmpdir
  tmpdir=$(mktemp -d)
  run_expz "$tmpdir"
  assert_failure
  assert_output_contains "No PDF files found"
  rmdir "$tmpdir"
}

# ============================================================================
# SCHEMA TESTS
# ============================================================================

@test "expz default schema file exists" {
  local schema="$UTILZ_HOME/opt/expz/lib/expense_schema.json"
  assert_file_exists "$schema"
}

@test "expz default schema is valid JSON" {
  local schema="$UTILZ_HOME/opt/expz/lib/expense_schema.json"
  run jq empty "$schema"
  assert_success
}

@test "expz with non-existent schema shows error" {
  local tmpdir
  tmpdir=$(mktemp -d)
  mkdir "$tmpdir/Category"
  touch "$tmpdir/Category/test.pdf"
  run_expz "$tmpdir" --schema /tmp/nonexistent_schema_$$.json
  assert_failure
  assert_output_contains "Schema not found"
  rm -rf "$tmpdir"
}
