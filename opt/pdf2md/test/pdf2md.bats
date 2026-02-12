#!/usr/bin/env bats
# pdf2md.bats - Tests for pdf2md utility

# Load test helper from core utilz tests
load "../../utilz/test/test_helper.bash"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

run_pdf2md() {
    run "$UTILZ_BIN_DIR/pdf2md" "$@"
}

FIXTURES_DIR="$UTILZ_HOME/opt/pdf2md/test/fixtures"

# ============================================================================
# TIER 1: ALWAYS RUN (no python3 required)
# ============================================================================

@test "pdf2md --help shows usage" {
    run_pdf2md --help
    assert_success
    assert_output_contains "Usage"
    assert_output_contains "pdf2md"
}

@test "pdf2md --version shows version" {
    run_pdf2md --version
    assert_success
    assert_output_contains "pdf2md"
}

@test "pdf2md with unknown option shows error" {
    run_pdf2md --unknown-option
    assert_failure
}

@test "pdf2md with no args shows error" {
    run_pdf2md
    assert_failure
}

@test "pdf2md with nonexistent file shows error" {
    run_pdf2md /tmp/nonexistent_file_12345.pdf
    assert_failure
    assert_output_contains "not found"
}

@test "pdf2md with non-PDF file shows error" {
    echo "not a pdf" > "$BATS_TEST_TMPDIR/test.txt"
    run_pdf2md "$BATS_TEST_TMPDIR/test.txt"
    assert_failure
    assert_output_contains "Not a PDF"
}

# ============================================================================
# TIER 2: REQUIRE PYTHON3
# ============================================================================

@test "pdf2md converts sample PDF to markdown" {
    require_command python3 "python3 required"
    run_pdf2md "$FIXTURES_DIR/sample.pdf"
    assert_success
    # Should have some content
    [[ -n "$output" ]]
}

@test "pdf2md output contains heading markers" {
    require_command python3 "python3 required"
    run_pdf2md "$FIXTURES_DIR/sample.pdf"
    assert_success
    assert_output_contains "#"
}

@test "pdf2md detects main title as heading" {
    require_command python3 "python3 required"
    run_pdf2md "$FIXTURES_DIR/sample.pdf"
    assert_success
    assert_output_contains "Sample Document Title"
}

@test "pdf2md detects list items" {
    require_command python3 "python3 required"
    run_pdf2md "$FIXTURES_DIR/sample.pdf"
    assert_success
    # Should detect numbered or bullet list items
    assert_output_contains "heading detection"
}

@test "pdf2md -o writes output to file" {
    require_command python3 "python3 required"
    local outfile="$BATS_TEST_TMPDIR/output.md"
    run_pdf2md "$FIXTURES_DIR/sample.pdf" -o "$outfile"
    assert_success
    assert_file_exists "$outfile"
    # File should have content
    [[ -s "$outfile" ]]
}

@test "pdf2md --pages limits output to specified pages" {
    require_command python3 "python3 required"
    # Get full output
    run_pdf2md "$FIXTURES_DIR/sample.pdf"
    local full_output="$output"

    # Get page 1 only
    run_pdf2md "$FIXTURES_DIR/sample.pdf" --pages 1
    assert_success
    local page1_output="$output"

    # Page 1 should have Introduction but not Second Page Content
    assert_output_contains "Introduction"
    refute_output_contains "Second Page Content"
}

@test "pdf2md --pages 2 shows second page only" {
    require_command python3 "python3 required"
    run_pdf2md "$FIXTURES_DIR/sample.pdf" --pages 2
    assert_success
    assert_output_contains "Second Page Content"
    refute_output_contains "Introduction"
}

@test "pdf2md --verbose shows progress on stderr" {
    require_command python3 "python3 required"
    # Run and capture stderr separately
    run bash -c "'$UTILZ_BIN_DIR/pdf2md' '$FIXTURES_DIR/sample.pdf' --verbose 2>&1 >/dev/null"
    assert_success
    assert_output_contains "Processing page"
}

@test "pdf2md detects bullet list items" {
    require_command python3 "python3 required"
    run_pdf2md "$FIXTURES_DIR/sample.pdf" --pages 2
    assert_success
    assert_output_contains "- "
}
