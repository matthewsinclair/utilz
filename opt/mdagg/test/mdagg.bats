#!/usr/bin/env bats
# mdagg.bats - Tests for mdagg utility

# Load test helper from core utilz tests
load "../../utilz/test/test_helper.bash"

# ============================================================================
# BASIC INVOCATION
# ============================================================================

@test "mdagg --help shows usage" {
    run_mdagg --help
    assert_success
    assert_output_contains "mdagg"
    assert_output_contains "Markdown"
}

@test "mdagg --version shows version" {
    run_mdagg --version
    assert_success
    assert_output_contains "mdagg"
}

@test "mdagg with no args shows error" {
    run_mdagg
    assert_failure
}

# ============================================================================
# GLOB MODE
# ============================================================================

@test "glob mode: processes matching files" {
    create_markdown_files 3

    run_mdagg "test*.md"
    assert_success
    assert_output_contains "Test File 1"
    assert_output_contains "Test File 2"
    assert_output_contains "Test File 3"
}

@test "glob mode: sorted naturally (1, 2, 10 not 1, 10, 2)" {
    create_numbered_markdown_files

    run_mdagg "*.md"
    assert_success

    # Check order by looking at positions in output
    local output_lines="$output"
    local pos_1=$(echo "$output_lines" | grep -n "Chapter 1" | head -1 | cut -d: -f1)
    local pos_2=$(echo "$output_lines" | grep -n "Chapter 2" | head -1 | cut -d: -f1)
    local pos_10=$(echo "$output_lines" | grep -n "Chapter 10" | head -1 | cut -d: -f1)

    # pos_2 should be after pos_1
    [[ $pos_2 -gt $pos_1 ]]

    # pos_10 should be after pos_2 (not between 1 and 2)
    [[ $pos_10 -gt $pos_2 ]]
}

@test "glob mode: no matches shows error" {
    run_mdagg "nonexistent*.md"
    assert_failure
}

@test "glob mode: respects working directory" {
    mkdir -p subdir
    cd subdir
    create_markdown_files 2

    run_mdagg "*.md"
    assert_success
    assert_output_contains "Test File"
}

# ============================================================================
# YAML CONFIG MODE
# ============================================================================

@test "yaml mode: processes YAML config file" {
    require_command yq

    create_markdown_files 2
    create_mdagg_yaml_config "config.yaml"

    run_mdagg config.yaml
    assert_success
    assert_output_contains "Test File 1"
    assert_output_contains "Test File 2"
}

@test "yaml mode: reads settings from YAML" {
    require_command yq

    create_markdown_files 2

    cat > config.yaml <<EOF
settings:
  page_breaks: true

files:
  - file: "test1.md"
  - file: "test2.md"
EOF

    run_mdagg config.yaml
    assert_success
    assert_output_contains "page-break"
}

@test "yaml mode: processes files in order specified" {
    require_command yq

    create_markdown_files 3

    cat > config.yaml <<EOF
files:
  - file: "test3.md"
  - file: "test1.md"
  - file: "test2.md"
EOF

    run_mdagg config.yaml
    assert_success

    # Check order
    local output_lines="$output"
    local pos_3=$(echo "$output_lines" | grep -n "Test File 3" | head -1 | cut -d: -f1)
    local pos_1=$(echo "$output_lines" | grep -n "Test File 1" | head -1 | cut -d: -f1)
    local pos_2=$(echo "$output_lines" | grep -n "Test File 2" | head -1 | cut -d: -f1)

    # File 3 should come first
    [[ $pos_3 -lt $pos_1 ]]
    [[ $pos_1 -lt $pos_2 ]]
}

@test "yaml mode: handles relative paths" {
    require_command yq

    mkdir -p docs
    cd docs
    create_markdown_files 1

    cd ..
    cat > config.yaml <<EOF
files:
  - file: "docs/test1.md"
EOF

    run_mdagg config.yaml
    assert_success
    assert_output_contains "Test File 1"
}

@test "yaml mode: shows error for missing config file" {
    run_mdagg nonexistent.yaml
    assert_failure
}

@test "yaml mode: requires yq" {
    if command_exists yq; then
        skip "yq is installed - cannot test error path"
    fi

    create_mdagg_yaml_config "config.yaml"

    run_mdagg config.yaml
    assert_failure
    assert_output_contains "yq"
}

# ============================================================================
# STDIN MODE
# ============================================================================

@test "stdin mode: reads file list from stdin" {
    create_markdown_files 2

    run bash -c "echo -e 'test1.md\ntest2.md' | $UTILZ_BIN_DIR/mdagg --stdin"
    assert_success
    assert_output_contains "Test File 1"
    assert_output_contains "Test File 2"
}

@test "stdin mode: processes files in order received" {
    create_markdown_files 3

    run bash -c "echo -e 'test3.md\ntest1.md\ntest2.md' | $UTILZ_BIN_DIR/mdagg --stdin"
    assert_success

    # Check order
    local output_lines="$output"
    local pos_3=$(echo "$output_lines" | grep -n "Test File 3" | head -1 | cut -d: -f1)
    local pos_1=$(echo "$output_lines" | grep -n "Test File 1" | head -1 | cut -d: -f1)

    [[ $pos_3 -lt $pos_1 ]]
}

@test "stdin mode: handles empty stdin gracefully" {
    run bash -c "echo '' | $UTILZ_BIN_DIR/mdagg --stdin"
    assert_failure
}

# ============================================================================
# OPTIONS
# ============================================================================

@test "option: -o/--output writes to file" {
    create_markdown_files 2

    run_mdagg "test*.md" -o output.md
    assert_success
    assert_file_exists "output.md"
    assert_file_contains "output.md" "Test File 1"
    assert_file_contains "output.md" "Test File 2"
}

@test "option: -p/--page-breaks inserts page breaks" {
    create_markdown_files 2

    run_mdagg "test*.md" -p
    assert_success
    assert_output_contains "page-break"
}

@test "option: -d/--section-dividers adds section titles" {
    create_markdown_files 2

    run_mdagg "test*.md" -d
    assert_success
    # Section dividers typically add horizontal rules or headers
    assert_output_contains "---"
}

@test "option: -s/--strip-front-matter removes YAML frontmatter" {
    create_markdown_with_frontmatter "test.md"

    run_mdagg "test.md" -s
    assert_success
    refute_output_contains "---"
    refute_output_contains "title:"
    assert_output_contains "Test Document"
}

@test "option: -b/--strip-back-links removes navigation links" {
    create_markdown_with_backlinks "test.md"

    run_mdagg "test.md" -b
    assert_success
    refute_output_contains "← Back"
    refute_output_contains "↑ Top"
    assert_output_contains "Test Document"
}

@test "option: -v/--verbose shows progress" {
    create_markdown_files 2

    run_mdagg "test*.md" -v
    assert_success
    # Verbose mode should show some progress info
    assert_output_contains "test"
}

# ============================================================================
# CONTENT PROCESSING
# ============================================================================

@test "content: concatenates multiple files correctly" {
    cat > file1.md <<EOF
# File One
Content of file one.
EOF

    cat > file2.md <<EOF
# File Two
Content of file two.
EOF

    run_mdagg "file*.md"
    assert_success
    assert_output_contains "File One"
    assert_output_contains "Content of file one"
    assert_output_contains "File Two"
    assert_output_contains "Content of file two"
}

@test "content: preserves markdown formatting" {
    cat > test.md <<EOF
# Heading 1
## Heading 2

- List item 1
- List item 2

**Bold text** and *italic text*.

\`\`\`bash
code block
\`\`\`
EOF

    run_mdagg "test.md"
    assert_success
    assert_output_contains "# Heading 1"
    assert_output_contains "## Heading 2"
    assert_output_contains "- List item 1"
    assert_output_contains "**Bold text**"
    assert_output_contains "\`\`\`bash"
}

@test "content: handles empty files" {
    touch empty.md
    create_markdown_files 1

    run_mdagg "*.md"
    assert_success
}

# ============================================================================
# ERROR HANDLING
# ============================================================================

@test "error: missing file shows warning but continues" {
    create_markdown_files 1

    # If using YAML mode
    if command_exists yq; then
        cat > config.yaml <<EOF
files:
  - file: "test1.md"
  - file: "nonexistent.md"
EOF

        run_mdagg config.yaml
        # Should show warning but still process test1.md
        assert_output_contains "Test File 1"
    else
        skip "yq not installed"
    fi
}

@test "error: unknown option shows error and usage" {
    run_mdagg --unknown-option
    assert_failure
}
