#!/usr/bin/env bats
# cleanz.bats - Tests for cleanz utility

# Load test helper from core utilz tests
load "../../utilz/test/test_helper.bash"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

run_cleanz() {
    run "$UTILZ_BIN_DIR/cleanz" "$@"
}

# Run cleanz with stdin input (bats run doesn't work well with pipes)
run_cleanz_stdin() {
    local input="$1"
    shift
    run bash -c "printf '%s' '$input' | '$UTILZ_BIN_DIR/cleanz' $*"
}

# Create test file with hidden characters
create_test_file_with_hidden_chars() {
    local filename="$1"
    # Text with zero-width space between Hello and World
    printf 'Hello\xe2\x80\x8bWorld\n' > "$filename"
}

# Create test file with multiple hidden char types
create_test_file_with_multiple_hidden() {
    local filename="$1"
    # ZWSP + NBSP + BOM
    printf '\xef\xbb\xbfHello\xe2\x80\x8b\xc2\xa0World\n' > "$filename"
}

# Create test file with HTML data attributes
create_test_file_with_html() {
    local filename="$1"
    cat > "$filename" <<'EOF'
<p data-start="123" data-end="456">Hello World</p>
<span data-sourcepos="1:1-1:5">Text</span>
EOF
}

# Create test file with smart quotes
create_test_file_with_smart_quotes() {
    local filename="$1"
    printf 'He said \xe2\x80\x9cHello\xe2\x80\x9d and \xe2\x80\x98goodbye\xe2\x80\x99\n' > "$filename"
}

# Create test file with extra whitespace
create_test_file_with_whitespace() {
    local filename="$1"
    printf 'Hello   World  \nLine with trailing space   \n\n\n\nToo many blank lines\n' > "$filename"
}

# Skip test if exiftool is not installed
skip_if_no_exiftool() {
    if ! command -v exiftool &>/dev/null; then
        skip "exiftool not installed"
    fi
}

# ============================================================================
# BASIC TESTS
# ============================================================================

@test "cleanz --help shows usage" {
    run_cleanz --help
    assert_success
    assert_output_contains "Usage"
    assert_output_contains "cleanz"
}

@test "cleanz --version shows version" {
    run_cleanz --version
    assert_success
    assert_output_contains "cleanz"
}

@test "cleanz with unknown option shows error" {
    run_cleanz --invalid-option
    assert_failure
    assert_output_contains "Unknown option"
}

@test "cleanz with plain text passes through unchanged" {
    local testfile="$BATS_TEST_TMPDIR/plain.txt"
    echo "Hello World" > "$testfile"

    run_cleanz "$testfile"
    assert_success
    assert_output "Hello World"
}

# ============================================================================
# UNICODE CLEANING TESTS
# ============================================================================

@test "cleanz removes zero-width space (U+200B)" {
    local testfile="$BATS_TEST_TMPDIR/zwsp.txt"
    printf 'Hello\xe2\x80\x8bWorld' > "$testfile"

    run_cleanz "$testfile"
    assert_success
    assert_output "HelloWorld"
}

@test "cleanz removes zero-width non-joiner (U+200C)" {
    local testfile="$BATS_TEST_TMPDIR/zwnj.txt"
    printf 'Hello\xe2\x80\x8cWorld' > "$testfile"

    run_cleanz "$testfile"
    assert_success
    assert_output "HelloWorld"
}

@test "cleanz removes zero-width joiner (U+200D)" {
    local testfile="$BATS_TEST_TMPDIR/zwj.txt"
    printf 'Hello\xe2\x80\x8dWorld' > "$testfile"

    run_cleanz "$testfile"
    assert_success
    assert_output "HelloWorld"
}

@test "cleanz removes word joiner (U+2060)" {
    local testfile="$BATS_TEST_TMPDIR/wj.txt"
    printf 'Hello\xe2\x81\xa0World' > "$testfile"

    run_cleanz "$testfile"
    assert_success
    assert_output "HelloWorld"
}

@test "cleanz removes byte order mark (U+FEFF)" {
    local testfile="$BATS_TEST_TMPDIR/bom.txt"
    printf '\xef\xbb\xbfHello World' > "$testfile"

    run_cleanz "$testfile"
    assert_success
    assert_output "Hello World"
}

@test "cleanz removes soft hyphen (U+00AD)" {
    local testfile="$BATS_TEST_TMPDIR/shy.txt"
    printf 'Hello\xc2\xadWorld' > "$testfile"

    run_cleanz "$testfile"
    assert_success
    assert_output "HelloWorld"
}

@test "cleanz converts non-breaking space to regular space" {
    local testfile="$BATS_TEST_TMPDIR/nbsp.txt"
    printf 'Hello\xc2\xa0World' > "$testfile"

    run_cleanz "$testfile"
    assert_success
    assert_output "Hello World"
}

@test "cleanz converts hair space to regular space" {
    local testfile="$BATS_TEST_TMPDIR/hair.txt"
    printf 'Hello\xe2\x80\x8aWorld' > "$testfile"

    run_cleanz "$testfile"
    assert_success
    assert_output "Hello World"
}

@test "cleanz removes multiple hidden character types" {
    local testfile="$BATS_TEST_TMPDIR/multi.txt"
    # BOM + ZWSP + NBSP
    printf '\xef\xbb\xbfHello\xe2\x80\x8b\xc2\xa0World' > "$testfile"

    run_cleanz "$testfile"
    assert_success
    assert_output "Hello World"
}

# ============================================================================
# HTML CLEANING TESTS
# ============================================================================

@test "cleanz removes data-start attribute" {
    local testfile="$BATS_TEST_TMPDIR/html1.txt"
    echo '<p data-start="123">Hello</p>' > "$testfile"

    run_cleanz "$testfile"
    assert_success
    assert_output "<p>Hello</p>"
}

@test "cleanz removes data-end attribute" {
    local testfile="$BATS_TEST_TMPDIR/html2.txt"
    echo '<p data-end="456">Hello</p>' > "$testfile"

    run_cleanz "$testfile"
    assert_success
    assert_output "<p>Hello</p>"
}

@test "cleanz removes data-sourcepos attribute" {
    local testfile="$BATS_TEST_TMPDIR/html3.txt"
    echo '<p data-sourcepos="1:1-1:10">Hello</p>' > "$testfile"

    run_cleanz "$testfile"
    assert_success
    assert_output "<p>Hello</p>"
}

@test "cleanz removes generic data-* attributes" {
    local testfile="$BATS_TEST_TMPDIR/html4.txt"
    echo '<p data-custom="value">Hello</p>' > "$testfile"

    run_cleanz "$testfile"
    assert_success
    assert_output "<p>Hello</p>"
}

@test "cleanz --no-html preserves data attributes" {
    local testfile="$BATS_TEST_TMPDIR/html5.txt"
    echo '<p data-start="123">Hello</p>' > "$testfile"

    run_cleanz --no-html "$testfile"
    assert_success
    assert_output_contains "data-start"
}

# ============================================================================
# WHITESPACE CLEANING TESTS
# ============================================================================

@test "cleanz collapses multiple spaces" {
    local testfile="$BATS_TEST_TMPDIR/spaces.txt"
    echo "Hello    World" > "$testfile"

    run_cleanz "$testfile"
    assert_success
    assert_output "Hello World"
}

@test "cleanz removes trailing whitespace" {
    local testfile="$BATS_TEST_TMPDIR/trailing.txt"
    printf "Hello World   " > "$testfile"

    run_cleanz "$testfile"
    assert_success
    # Output should not have trailing spaces
    refute_output_contains "   "
}

@test "cleanz --no-whitespace preserves multiple spaces" {
    local testfile="$BATS_TEST_TMPDIR/preserve.txt"
    echo "Hello    World" > "$testfile"

    run_cleanz --no-whitespace "$testfile"
    assert_success
    assert_output_contains "    "
}

# ============================================================================
# QUOTE NORMALIZATION TESTS
# ============================================================================

@test "cleanz --normalize-quotes converts left double quote" {
    local testfile="$BATS_TEST_TMPDIR/quotes1.txt"
    printf '\xe2\x80\x9cHello\xe2\x80\x9d' > "$testfile"

    run_cleanz --normalize-quotes "$testfile"
    assert_success
    assert_output '"Hello"'
}

@test "cleanz --normalize-quotes converts single quotes" {
    local testfile="$BATS_TEST_TMPDIR/quotes2.txt"
    printf '\xe2\x80\x98Hello\xe2\x80\x99' > "$testfile"

    run_cleanz --normalize-quotes "$testfile"
    assert_success
    assert_output "'Hello'"
}

@test "cleanz without --normalize-quotes preserves smart quotes" {
    local testfile="$BATS_TEST_TMPDIR/quotes3.txt"
    printf '\xe2\x80\x9cHello\xe2\x80\x9d' > "$testfile"

    run_cleanz "$testfile"
    assert_success
    # Smart quotes should still be in output (as UTF-8 bytes)
    [[ "$output" == *$'\xe2\x80\x9c'* ]]
}

# ============================================================================
# DETECT MODE TESTS
# ============================================================================

@test "cleanz --detect shows zero-width space count" {
    local testfile="$BATS_TEST_TMPDIR/detect1.txt"
    printf 'Hello\xe2\x80\x8bWorld' > "$testfile"

    run_cleanz --detect "$testfile"
    assert_success
    assert_output_contains "Zero-width space (U+200B): 1"
    assert_output_contains "Total hidden elements found: 1"
}

@test "cleanz --detect shows multiple character types" {
    local testfile="$BATS_TEST_TMPDIR/detect2.txt"
    printf '\xef\xbb\xbfHello\xe2\x80\x8b\xc2\xa0World' > "$testfile"

    run_cleanz --detect "$testfile"
    assert_success
    assert_output_contains "Zero-width space"
    assert_output_contains "Non-breaking space"
    assert_output_contains "Byte order mark"
}

@test "cleanz --detect with clean text shows no hidden elements" {
    local testfile="$BATS_TEST_TMPDIR/detect3.txt"
    echo "Hello World" > "$testfile"

    run_cleanz --detect "$testfile"
    assert_success
    assert_output_contains "No hidden elements detected"
}

@test "cleanz --detect does not modify the text" {
    local testfile="$BATS_TEST_TMPDIR/detect_test.txt"
    create_test_file_with_hidden_chars "$testfile"
    local original=$(cat "$testfile")

    run_cleanz --detect "$testfile"
    assert_success

    # File should be unchanged
    local after=$(cat "$testfile")
    [[ "$original" == "$after" ]]
}

# ============================================================================
# VERBOSE MODE TESTS
# ============================================================================

@test "cleanz -v shows character removal count" {
    local testfile="$BATS_TEST_TMPDIR/verbose1.txt"
    printf 'Hello\xe2\x80\x8bWorld' > "$testfile"

    run bash -c "'$UTILZ_BIN_DIR/cleanz' -v '$testfile' 2>&1"
    assert_success
    assert_output_contains "Removed"
}

@test "cleanz -v with clean text shows no hidden chars" {
    local testfile="$BATS_TEST_TMPDIR/verbose2.txt"
    echo "Hello World" > "$testfile"

    run bash -c "'$UTILZ_BIN_DIR/cleanz' -v '$testfile' 2>&1"
    assert_success
    assert_output_contains "No hidden characters found"
}

# ============================================================================
# FILE I/O TESTS
# ============================================================================

@test "cleanz reads from file" {
    local testfile="$BATS_TEST_TMPDIR/input.txt"
    create_test_file_with_hidden_chars "$testfile"

    run_cleanz "$testfile"
    assert_success
    assert_output "HelloWorld"
}

@test "cleanz -o writes to output file" {
    local testfile="$BATS_TEST_TMPDIR/input.txt"
    local outfile="$BATS_TEST_TMPDIR/output.txt"
    create_test_file_with_hidden_chars "$testfile"

    run_cleanz "$testfile" -o "$outfile"
    assert_success
    assert_file_exists "$outfile"
    assert_file_contains "$outfile" "HelloWorld"
}

@test "cleanz -i edits file in place" {
    local testfile="$BATS_TEST_TMPDIR/inplace.txt"
    create_test_file_with_hidden_chars "$testfile"

    run_cleanz -i "$testfile"
    assert_success

    # Check file was modified
    local content=$(cat "$testfile")
    [[ "$content" == "HelloWorld" ]]
}

@test "cleanz -i requires file argument" {
    run_cleanz -i
    assert_failure
    assert_output_contains "requires a file"
}

@test "cleanz -i and -o are mutually exclusive" {
    local testfile="$BATS_TEST_TMPDIR/test.txt"
    echo "test" > "$testfile"

    run_cleanz -i "$testfile" -o out.txt
    assert_failure
    assert_output_contains "mutually exclusive"
}

@test "cleanz with nonexistent file shows error" {
    run_cleanz /nonexistent/file.txt
    assert_failure
    assert_output_contains "File not found"
}

# ============================================================================
# STDIN TESTS
# ============================================================================

@test "cleanz reads from stdin" {
    local testfile="$BATS_TEST_TMPDIR/stdin_source.txt"
    printf 'Hello\xe2\x80\x8bWorld' > "$testfile"

    run bash -c "cat '$testfile' | '$UTILZ_BIN_DIR/cleanz'"
    assert_success
    assert_output "HelloWorld"
}

@test "cleanz stdin with plain text" {
    run bash -c "echo 'Hello World' | '$UTILZ_BIN_DIR/cleanz'"
    assert_success
    assert_output "Hello World"
}

# ============================================================================
# CLIPBOARD TESTS (skip if no clipboard available)
# ============================================================================

@test "cleanz --clipboard and file are mutually exclusive" {
    run_cleanz --clipboard somefile.txt
    assert_failure
    assert_output_contains "mutually exclusive"
}

# ============================================================================
# EDGE CASES
# ============================================================================

@test "cleanz handles only hidden characters" {
    local testfile="$BATS_TEST_TMPDIR/only_hidden.txt"
    printf '\xe2\x80\x8b\xe2\x80\x8c\xe2\x80\x8d' > "$testfile"

    run_cleanz "$testfile"
    assert_success
    [[ -z "$output" || "$output" == "" ]]
}

@test "cleanz preserves newlines" {
    local testfile="$BATS_TEST_TMPDIR/newlines.txt"
    printf 'Line1\nLine2\nLine3' > "$testfile"

    run_cleanz "$testfile"
    assert_success
    assert_output_contains "Line1"
    assert_output_contains "Line2"
    assert_output_contains "Line3"
}

@test "cleanz preserves tabs" {
    local testfile="$BATS_TEST_TMPDIR/tabs.txt"
    printf 'Column1\tColumn2' > "$testfile"

    run_cleanz "$testfile"
    assert_success
    assert_output_contains $'\t'
}

@test "cleanz handles mixed content" {
    local testfile="$BATS_TEST_TMPDIR/mixed.txt"
    printf '\xef\xbb\xbfTitle\n\nParagraph with \xe2\x80\x8bhidden\xc2\xa0chars.\n' > "$testfile"

    run_cleanz "$testfile"
    assert_success
    assert_output_contains "Title"
    assert_output_contains "Paragraph with hidden chars."
}

# ============================================================================
# COMBINED OPTIONS TESTS
# ============================================================================

@test "cleanz -v with file input" {
    local testfile="$BATS_TEST_TMPDIR/verbose_test.txt"
    create_test_file_with_hidden_chars "$testfile"

    run bash -c "'$UTILZ_BIN_DIR/cleanz' -v '$testfile' 2>&1"
    assert_success
    assert_output_contains "Removed"
    assert_output_contains "HelloWorld"
}

@test "cleanz --no-html --no-whitespace only cleans unicode" {
    local testfile="$BATS_TEST_TMPDIR/combined.txt"
    printf 'Hello  \xe2\x80\x8b  <p data-x="y">World</p>' > "$testfile"

    run_cleanz --no-html --no-whitespace "$testfile"
    assert_success
    # Unicode removed, but spaces and HTML preserved
    assert_output_contains "  "
    assert_output_contains "data-x"
}

@test "cleanz all options combined" {
    local testfile="$BATS_TEST_TMPDIR/all_opts.txt"
    printf '\xe2\x80\x9cHello\xe2\x80\x8b  World\xe2\x80\x9d' > "$testfile"

    run bash -c "'$UTILZ_BIN_DIR/cleanz' --normalize-quotes -v '$testfile' 2>&1"
    assert_success
    assert_output_contains '"Hello World"'
}

# ============================================================================
# IMAGE MODE TESTS
# ============================================================================

@test "cleanz --image requires file argument" {
    run_cleanz --image
    assert_failure
    assert_output_contains "requires an image file"
}

@test "cleanz --image with nonexistent file shows error" {
    run_cleanz --image --detect nonexistent.png
    assert_failure
    assert_output_contains "Image file not found"
}

@test "cleanz --image requires exiftool" {
    skip_if_no_exiftool
    # If we get here, exiftool is available - just verify the command structure works
    local test_image="$UTILZ_HOME/opt/macoz/images/backgrounds/autumn-01.png"
    run_cleanz --image --detect "$test_image"
    assert_success
    assert_output_contains "C2PA/AI metadata analysis"
}

@test "cleanz --image --detect shows metadata analysis" {
    skip_if_no_exiftool
    local test_image="$UTILZ_HOME/opt/macoz/images/backgrounds/autumn-01.png"

    run_cleanz --image --detect "$test_image"
    assert_success
    assert_output_contains "C2PA/AI metadata analysis"
}

@test "cleanz --image --detect -v shows full metadata" {
    skip_if_no_exiftool
    local test_image="$UTILZ_HOME/opt/macoz/images/backgrounds/autumn-01.png"

    run_cleanz --image --detect -v "$test_image"
    assert_success
    assert_output_contains "Full metadata"
}

@test "cleanz --image strips metadata to output file" {
    skip_if_no_exiftool
    local test_image="$UTILZ_HOME/opt/macoz/images/backgrounds/autumn-01.png"
    local output_file="$BATS_TEST_TMPDIR/cleaned_output.png"

    run bash -c "UTILZ_HOME='$UTILZ_HOME' '$UTILZ_BIN_DIR/cleanz' --image '$test_image' -o '$output_file' 2>&1"
    assert_success
    assert_output_contains "Cleaned image written to"
    # Verify file was created
    [[ -f "$output_file" ]]
}

@test "cleanz --image -i strips metadata in place" {
    skip_if_no_exiftool
    local test_image="$UTILZ_HOME/opt/macoz/images/backgrounds/autumn-01.png"
    local work_copy="$BATS_TEST_TMPDIR/work_copy.png"

    # Make a copy to avoid modifying the original
    cp "$test_image" "$work_copy"

    run bash -c "'$UTILZ_BIN_DIR/cleanz' --image -i '$work_copy' 2>&1"
    assert_success
    assert_output_contains "Metadata stripped"
}

@test "cleanz --image without -o or -i shows error" {
    skip_if_no_exiftool
    local test_image="$UTILZ_HOME/opt/macoz/images/backgrounds/autumn-01.png"

    run bash -c "'$UTILZ_BIN_DIR/cleanz' --image '$test_image' 2>&1"
    assert_failure
    assert_output_contains "requires -o"
}

@test "cleanz --image does not support clipboard" {
    local test_image="$UTILZ_HOME/opt/macoz/images/backgrounds/autumn-01.png"
    run bash -c "'$UTILZ_BIN_DIR/cleanz' --image --clipboard '$test_image' 2>&1"
    assert_failure
    # The clipboard+file check happens before image-specific clipboard check
    assert_output_contains "clipboard"
}
