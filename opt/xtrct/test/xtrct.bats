#!/usr/bin/env bats
# xtrct.bats - Tests for xtrct utility

# Load test helper from core utilz tests
load "../../utilz/test/test_helper.bash"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

run_xtrct() {
    run "$UTILZ_BIN_DIR/xtrct" "$@"
}

FIXTURES_DIR="$UTILZ_HOME/opt/xtrct/test/fixtures"

# ============================================================================
# TIER 1: ALWAYS RUN (no API key required)
# ============================================================================

@test "xtrct --help shows usage" {
    run_xtrct --help
    assert_success
    assert_output_contains "Usage"
    assert_output_contains "xtrct"
}

@test "xtrct --version shows version" {
    run_xtrct --version
    assert_success
    assert_output_contains "xtrct"
}

@test "xtrct with unknown option shows error" {
    # Need to set API key to get past that check
    ANTHROPIC_API_KEY=test run_xtrct --unknown-option --schema "$FIXTURES_DIR/sample_schema.json"
    assert_failure
}

@test "xtrct without --schema shows error" {
    ANTHROPIC_API_KEY=test run_xtrct "$FIXTURES_DIR/sample.md"
    assert_failure
}

@test "xtrct without ANTHROPIC_API_KEY shows error" {
    unset ANTHROPIC_API_KEY
    run_xtrct "$FIXTURES_DIR/sample.md" --schema "$FIXTURES_DIR/sample_schema.json"
    assert_failure
    assert_output_contains "ANTHROPIC_API_KEY"
}

@test "xtrct with nonexistent input file shows error" {
    ANTHROPIC_API_KEY=test run_xtrct /tmp/nonexistent_file_12345.md --schema "$FIXTURES_DIR/sample_schema.json"
    assert_failure
    assert_output_contains "not found"
}

@test "xtrct with nonexistent schema file shows error" {
    ANTHROPIC_API_KEY=test run_xtrct "$FIXTURES_DIR/sample.md" --schema /tmp/nonexistent_schema_12345.json
    assert_failure
    assert_output_contains "not found"
}

@test "xtrct with .pdf input without pdf2md shows error" {
    # Temporarily hide pdf2md from PATH but set API key to pass that check
    local tmpdir="$BATS_TEST_TMPDIR"
    echo "dummy" > "$tmpdir/test.pdf"
    ANTHROPIC_API_KEY=test PATH="/usr/bin:/bin" run "$UTILZ_BIN_DIR/xtrct" "$tmpdir/test.pdf" --schema "$FIXTURES_DIR/sample_schema.json"
    assert_failure
    assert_output_contains "pdf2md"
}

# ============================================================================
# TIER 2: REQUIRE ANTHROPIC_API_KEY (skipped in CI)
# ============================================================================

@test "xtrct extracts data from sample.md" {
    [[ -z "${ANTHROPIC_API_KEY:-}" ]] && skip "ANTHROPIC_API_KEY not set"
    require_command python3 "python3 required"
    run_xtrct "$FIXTURES_DIR/sample.md" --schema "$FIXTURES_DIR/sample_schema.json"
    assert_success
    # Output should be valid JSON with expected fields
    assert_output_contains "supplier_name"
    assert_output_contains "invoice_number"
}

@test "xtrct --format csv produces CSV output" {
    [[ -z "${ANTHROPIC_API_KEY:-}" ]] && skip "ANTHROPIC_API_KEY not set"
    require_command python3 "python3 required"
    run_xtrct "$FIXTURES_DIR/sample.md" --schema "$FIXTURES_DIR/sample_schema.json" --format csv
    assert_success
    assert_output_contains "supplier_name"
}

@test "xtrct --format table produces table output" {
    [[ -z "${ANTHROPIC_API_KEY:-}" ]] && skip "ANTHROPIC_API_KEY not set"
    require_command python3 "python3 required"
    run_xtrct "$FIXTURES_DIR/sample.md" --schema "$FIXTURES_DIR/sample_schema.json" --format table
    assert_success
    assert_output_contains "supplier_name"
}

@test "xtrct reads from stdin" {
    [[ -z "${ANTHROPIC_API_KEY:-}" ]] && skip "ANTHROPIC_API_KEY not set"
    require_command python3 "python3 required"
    run bash -c "cat '$FIXTURES_DIR/sample.md' | '$UTILZ_BIN_DIR/xtrct' --schema '$FIXTURES_DIR/sample_schema.json'"
    assert_success
    assert_output_contains "supplier_name"
}
