# Utilz Test Suite

Comprehensive test suite for the Utilz framework and all its utilities.

## Overview

The Utilz test system uses **BATS (Bash Automated Testing System)** to provide thorough test coverage of:
- Core framework functionality (dispatcher, common library)
- Individual utilities (mdagg, etc.)
- Integration workflows

### Test Organization

Tests are organized by utility:
```
opt/
├── utilz/
│   └── test/
│       ├── test_helper.bash      # Common test functions
│       ├── dispatcher.bats        # Dispatcher tests
│       ├── common_lib.bats        # Common library tests
│       ├── integration.bats       # End-to-end workflows
│       └── README.md              # This file
└── mdagg/
    └── test/
        ├── mdagg.bats             # mdagg utility tests
        └── fixtures/              # Test data
            ├── simple.md
            ├── with_frontmatter.md
            ├── with_backlinks.md
            └── sample_config.yaml
```

## Prerequisites

### Install BATS

```bash
# macOS with Homebrew
brew install bats-core

# Or from source
git clone https://github.com/bats-core/bats-core.git
cd bats-core
./install.sh /usr/local
```

### Verify Installation

```bash
bats --version
# Should show: Bats 1.x.x
```

## Running Tests

### Run All Tests

```bash
utilz test
```

This runs tests for:
- Core framework (utilz)
- All installed utilities (mdagg, etc.)

### Run Tests for Specific Utility

```bash
utilz test utilz    # Core framework tests only
utilz test mdagg    # mdagg tests only
```

### Run Tests Directly with BATS

```bash
# Run all core framework tests
bats opt/utilz/test/*.bats

# Run specific test file
bats opt/utilz/test/dispatcher.bats

# Run mdagg tests
bats opt/mdagg/test/mdagg.bats

# Run with verbose output
bats -t opt/utilz/test/dispatcher.bats
```

## Test Structure

### Core Framework Tests (opt/utilz/test/)

#### dispatcher.bats (21 tests)
Tests the main dispatcher (`bin/utilz`):
- UTILZ_HOME detection from script location
- Built-in commands (help, doctor, list, test, version)
- Symlink dispatch mechanism
- Error handling for missing/broken utilities
- Argument passing to utilities

#### common_lib.bats (25 tests)
Tests shared library functions (`opt/utilz/lib/common.sh`):
- Logging functions (info, success, warn, error, debug)
- Help rendering (show_help)
- Version extraction (show_version)
- Utility discovery (list_utilities)
- Command checking (check_command, require_command)
- YAML parsing (parse_yaml)
- Doctor diagnostics (run_doctor)

#### integration.bats (6 tests)
End-to-end workflow tests:
- Complete user workflows
- Creating and using test utilities
- Error recovery scenarios
- Multi-step operations

### Utility Tests (opt/*/test/)

#### mdagg.bats (31 tests)
Tests mdagg utility functionality:
- Basic invocation (--help, --version)
- Glob mode (pattern matching, natural sorting)
- YAML config mode (settings, file ordering)
- Stdin mode (piped input)
- Options (output, page breaks, section dividers, stripping)
- Content processing (concatenation, formatting)
- Error handling (missing files, invalid options)

## Test Helper Functions

The `test_helper.bash` file provides common functions for all tests:

### Setup/Teardown
- `setup_file()` - Runs once per test file
- `teardown_file()` - Cleanup after all tests in file
- `setup()` - Runs before each test (creates temp dir)
- `teardown()` - Cleanup after each test

### Execution Helpers
- `run_utilz <args>` - Run utilz command
- `run_utility <name> <args>` - Run specific utility
- `run_mdagg <args>` - Run mdagg utility

### Test Data Creation
- `create_test_utility(name)` - Create minimal test utility
- `create_markdown_files(count)` - Generate test markdown files
- `create_numbered_markdown_files()` - Generate 01, 02, 10 for sort testing
- `create_markdown_with_frontmatter(file)` - Create file with YAML frontmatter
- `create_markdown_with_backlinks(file)` - Create file with nav links
- `create_mdagg_yaml_config(file)` - Create sample YAML config

### Assertions
- `assert_success()` - Check command succeeded (exit 0)
- `assert_failure()` - Check command failed (non-zero exit)
- `assert_exit_code(N)` - Check specific exit code
- `assert_output_contains(text)` - Check output contains string
- `refute_output_contains(text)` - Check output doesn't contain string
- `assert_output(exact)` - Check exact output match
- `assert_output_matches(regex)` - Check output matches pattern
- `assert_file_exists(path)` - Check file exists
- `assert_file_not_exists(path)` - Check file doesn't exist
- `assert_directory_exists(path)` - Check directory exists
- `assert_file_contains(file, text)` - Check file contains text
- `refute_file_contains(file, text)` - Check file doesn't contain text
- `assert_symlink_exists(link, target)` - Check symlink exists and target
- `fail(message)` - Explicit test failure

### Utilities
- `get_utilz_version()` - Extract version from help file
- `command_exists(cmd)` - Check if command is installed
- `require_command(cmd, msg)` - Skip test if command missing
- `debug(message)` - Print debug info (when UTILZ_TEST_DEBUG=1)

## Writing Tests

### Basic Test Pattern

```bash
#!/usr/bin/env bats

load "test_helper.bash"

@test "description of what is being tested" {
    # Setup
    create_markdown_files 2

    # Execute
    run_mdagg "*.md"

    # Assert
    assert_success
    assert_output_contains "expected text"
}
```

### Test with Required Command

```bash
@test "feature requiring yq" {
    require_command yq  # Skip if yq not installed

    # Test code here
}
```

### Test File Structure

```bash
#!/usr/bin/env bats
# filename.bats - Description

load "test_helper.bash"

# Per-file setup (optional)
setup_file() {
    # Runs once before all tests
}

# Per-test setup (optional, usually not needed due to test_helper)
setup() {
    # Runs before each test
}

@test "test description" {
    # Test code
}
```

## Best Practices

### 1. Test Isolation
- Each test runs in a fresh temporary directory
- Don't rely on state from previous tests
- Clean up any modifications to the Utilz project

### 2. Clear Test Names
Use descriptive test names that explain what's being tested:
```bash
@test "mdagg glob mode: processes files in natural sort order"
```

### 3. Arrange-Act-Assert Pattern
```bash
@test "example" {
    # Arrange - set up test conditions
    create_markdown_files 3

    # Act - perform the action
    run_mdagg "*.md"

    # Assert - verify results
    assert_success
    assert_output_contains "expected"
}
```

### 4. Test Both Success and Failure
```bash
@test "success case: valid input processes correctly" { ... }
@test "failure case: invalid input shows error" { ... }
```

### 5. Use Helper Functions
Leverage test_helper.bash functions to keep tests readable:
```bash
# Good
create_markdown_files 3
run_mdagg "*.md"
assert_output_contains "Test File 1"

# Avoid
cat > test1.md <<EOF
...
EOF
run "$UTILZ_BIN_DIR/mdagg" "*.md"
if [[ "$output" != *"Test File 1"* ]]; then fail; fi
```

### 6. Handle Optional Dependencies
```bash
@test "feature requiring yq" {
    require_command yq  # Automatically skips if not installed
    # Test code
}
```

## Debugging Tests

### Run Single Test

```bash
# Run specific test file
bats opt/utilz/test/dispatcher.bats

# Run with tap output
bats -t opt/utilz/test/dispatcher.bats
```

### Enable Debug Output

```bash
# Set debug flag
export UTILZ_TEST_DEBUG=1
bats opt/utilz/test/dispatcher.bats
```

### Add Debug Statements

```bash
@test "example" {
    debug "Current directory: $(pwd)"
    debug "Files: $(ls)"

    run_mdagg "*.md"

    debug "Output: $output"
    debug "Status: $status"

    assert_success
}
```

### Inspect Test Directory

Temporarily disable cleanup to inspect test directory:
```bash
@test "example" {
    create_markdown_files 3
    run_mdagg "*.md"

    # Add this to inspect directory
    echo "Test dir: $BATS_TEST_TMPDIR"
    echo "Files: $(ls -la)"
    false  # Force failure to see output
}
```

## Adding Tests for New Utilities

When adding a new utility to Utilz, follow these steps:

### 1. Create Test Directory

```bash
mkdir -p opt/myutil/test/fixtures
```

### 2. Create Test File

Create `opt/myutil/test/myutil.bats`:

```bash
#!/usr/bin/env bats
# myutil.bats - Tests for myutil utility

# Load test helper from core utilz tests
load "../../utilz/test/test_helper.bash"

@test "myutil --help shows usage" {
    run_utility myutil --help
    assert_success
    assert_output_contains "myutil"
}

@test "myutil basic functionality" {
    # Test your utility's main functionality
}
```

### 3. Add Fixtures (if needed)

Add test data files to `opt/myutil/test/fixtures/`

### 4. Run Tests

```bash
utilz test myutil
```

## Test Coverage

Current test coverage:

| Component | Test File | Test Count | Status |
|-----------|-----------|------------|--------|
| Dispatcher | dispatcher.bats | 21 | ✓ |
| Common Library | common_lib.bats | 25 | ✓ |
| Integration | integration.bats | 6 | ✓ |
| mdagg Utility | mdagg.bats | 31 | ✓ |
| **Total** | | **83** | **✓** |

## Continuous Integration

### Local Pre-commit

Run tests before committing:
```bash
utilz test && git commit -m "message"
```

### CI/CD Pipeline

Example GitHub Actions workflow:

```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install BATS
        run: brew install bats-core yq
      - name: Run Tests
        run: |
          export UTILZ_HOME="$PWD"
          export PATH="$UTILZ_HOME/bin:$PATH"
          utilz test
```

## Troubleshooting

### "bats: command not found"

Install BATS:
```bash
brew install bats-core
```

### Tests fail with "Permission denied"

Ensure scripts are executable:
```bash
chmod +x bin/utilz
chmod +x opt/*/[utility-name]
```

### "yq: command not found" in YAML tests

Install yq:
```bash
brew install yq
```

Or tests requiring yq will be automatically skipped.

### Tests interfere with each other

- Tests should be isolated (use test_helper setup/teardown)
- Check that tests aren't modifying shared state
- Verify temp directories are being cleaned up

### Strange PATH issues

Tests set PATH to include UTILZ_HOME/bin:
```bash
export PATH="$UTILZ_BIN_DIR:$PATH"
```

If issues persist, check your shell config for conflicting PATH modifications.

## Resources

- **BATS Documentation**: https://bats-core.readthedocs.io/
- **BATS GitHub**: https://github.com/bats-core/bats-core
- **Utilz Framework**: See main README.md
- **Test Helper Source**: opt/utilz/test/test_helper.bash

## Contributing

When adding tests:
1. Follow existing patterns and conventions
2. Use descriptive test names
3. Keep tests focused (one assertion per test when possible)
4. Add helper functions for reusable test code
5. Document any special setup requirements
6. Ensure tests are isolated and don't affect each other

---

**Last Updated**: 2025-01-12
**Utilz Version**: 1.0.0
