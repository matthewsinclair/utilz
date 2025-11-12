# GitHub Actions Workflows

This directory contains automated workflows that run on GitHub to ensure code quality and test coverage for the Utilz framework.

## Workflows

### 1. Utilz Tests (`tests.yml`)

**Triggers**: On push to `main` branch and on all pull requests

**What it does**:

- Runs all utility tests on Ubuntu and macOS
- Performs ShellCheck analysis on all scripts
- Validates framework with `utilz doctor`
- Provides a summary of test results

**Jobs**:

- `test-linux`: Runs full test suite on Ubuntu with bats-core
- `test-macos`: Runs full test suite on macOS with bats-core
- `shellcheck`: Static analysis of shell scripts (non-blocking)
- `test-summary`: Aggregates results from all test jobs

**Key Features**:

- Tests on both Ubuntu and macOS to ensure cross-platform compatibility
- Installs yq for YAML parsing
- Uses `utilz test` to run all utility tests
- ShellCheck provides code quality feedback without blocking

### 2. PR Checks (`pr-checks.yml`)

**Triggers**: On all pull request events (opened, synchronized, reopened)

**What it does**:

- Checks for documentation updates when code changes
- Verifies test coverage for new code
- Validates commit message format
- Checks PR size and suggests splitting if too large
- Validates utility metadata for new utilities

**Jobs**:

- `check-documentation`: Ensures docs are updated when scripts change
- `test-coverage`: Verifies tests are added/updated with code changes
- `commit-message-check`: Validates commit message length and format
- `pr-size-check`: Warns about large PRs (>1000 lines)
- `utility-metadata-check`: Ensures new utilities have proper metadata, README, and tests

## Status Badge

Add the test status badge to the main README:

```markdown
[![Utilz Tests](https://github.com/matthewsinclair/utilz/actions/workflows/tests.yml/badge.svg)](https://github.com/matthewsinclair/utilz/actions/workflows/tests.yml)
```

## Local Testing

Before pushing, you can run tests locally:

```bash
# Set up environment
export UTILZ_HOME="$HOME/Devel/prj/Utilz"
export PATH="$UTILZ_HOME/bin:$PATH"

# Run all tests
utilz test

# Run specific utility tests
utilz test mdagg

# Run tests directly
cd opt/mdagg/test
bats mdagg.bats

# Run diagnostics
utilz doctor

# Run ShellCheck locally
shellcheck bin/utilz
shellcheck opt/*/[!test]*
```

## Workflow Maintenance

### Dependencies

- **GitHub Actions**: Uses `actions/checkout@v4`
- **yq**: YAML parsing for metadata files
- **Bats**: Installed via system package manager (v1.12.0)
- Both environments test the full suite to ensure cross-platform compatibility

### Test Environments

- **Ubuntu**: Latest version with apt package manager
- **macOS**: Latest version with Homebrew
- Both environments run identical test suites

### Best Practices

- ShellCheck runs are non-blocking to allow gradual improvements
- Tests run with `utilz test` command
- All scripts are made executable before running
- Environment setup mimics local development

## Adding New Utilities

When adding a new utility:

1. **Create the implementation** in `opt/myutil/myutil`
2. **Add metadata file** `opt/myutil/myutil.yaml` with version and description
3. **Write tests** in `opt/myutil/test/*.bats`
4. **Add documentation** in `opt/myutil/README.md` and `help/myutil.md`
5. **Create symlink** `ln -s utilz bin/myutil`
6. **Run tests locally** with `utilz test myutil`
7. **Update main README** if the utility is significant

The PR checks will validate that all these files are present.

## Troubleshooting

### Common Issues

1. **Tests pass locally but fail in CI**
   - Check for environment-specific paths
   - Ensure UTILZ_HOME is set correctly
   - Verify file permissions are set correctly
   - Check that yq is available

2. **yq not found**
   - The workflow installs yq automatically
   - On Linux, it downloads the binary directly
   - On macOS, it uses Homebrew

3. **ShellCheck warnings**
   - These are non-blocking but should be addressed
   - Run `shellcheck` locally to see specific issues
   - Common issues: unquoted variables, unused variables

4. **Doctor reports issues**
   - This is non-blocking to allow flexible test environments
   - PATH warnings are expected in CI (UTILZ_HOME/bin not in base PATH)
   - Missing optional dependencies (bat, mdcat) are acceptable

### Debugging Workflows

- Check the Actions tab in GitHub for detailed logs
- Each step shows its output when expanded
- Failed steps are highlighted in red
- Use `echo` statements for debugging in workflows

## Version Compatibility

The workflows expect:

- Bash 4.0+ or Zsh
- yq for YAML parsing
- bats-core for testing
- Standard Unix utilities (grep, sed, awk, find)

Both Ubuntu and macOS runners provide these by default or install them during setup.
