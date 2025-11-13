#!/usr/bin/env bats
# gitz.bats - Tests for gitz utility

# Load test helper from core utilz tests
load "../../utilz/test/test_helper.bash"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

run_gitz() {
    run "$UTILZ_BIN_DIR/gitz" "$@"
}

create_test_git_repo() {
    local repo_name="$1"
    local original_dir="$PWD"
    mkdir -p "$repo_name"
    cd "$repo_name"
    git init -q
    git config user.email "test@example.com"
    git config user.name "Test User"
    echo "test" > README.md
    git add README.md
    git commit -q -m "Initial commit"
    cd "$original_dir"
}

# ============================================================================
# BASIC TESTS
# ============================================================================

@test "gitz --help shows usage" {
    run_gitz --help
    assert_success
    assert_output_contains "gitz"
    assert_output_contains "status-all"
}

@test "gitz --version shows version" {
    run_gitz --version
    assert_success
    assert_output_contains "gitz"
    assert_output_contains "v"
}

@test "gitz with no arguments shows usage" {
    run_gitz
    assert_success
    assert_output_contains "Usage"
}

@test "gitz with unknown command shows error" {
    run_gitz unknown-command
    assert_failure
    assert_output_contains "Unknown command"
}

@test "gitz requires git" {
    if ! command_exists git; then
        run_gitz status-all
        assert_failure
        assert_output_contains "Git is required"
    else
        skip "git is installed"
    fi
}

# ============================================================================
# STATUS-ALL COMMAND TESTS
# ============================================================================

@test "gitz status-all in empty directory" {
    # Create empty test directory
    mkdir -p empty_dir
    cd empty_dir

    run_gitz status-all .
    assert_success
    assert_output_contains "No git repositories found"

    cd ..
    rm -rf empty_dir
}

@test "gitz status-all finds single repository" {
    if ! command_exists git; then
        skip "git not installed"
    fi

    # Create test repo
    create_test_git_repo "test_repo1"

    # Run status-all
    run_gitz status-all .
    assert_success
    assert_output_contains "test_repo1"
    assert_output_contains "Checked 1 repositories"

    # Cleanup
    rm -rf test_repo1
}

@test "gitz status-all finds multiple repositories" {
    if ! command_exists git; then
        skip "git not installed"
    fi

    # Create test repos
    create_test_git_repo "test_repo1"
    create_test_git_repo "test_repo2"

    # Run status-all
    run_gitz status-all .
    assert_success
    assert_output_contains "test_repo1"
    assert_output_contains "test_repo2"
    assert_output_contains "Checked 2 repositories"

    # Cleanup
    rm -rf test_repo1 test_repo2
}

@test "gitz status-all excludes paths with underscores" {
    if ! command_exists git; then
        skip "git not installed"
    fi

    # Create repos, one with underscore
    create_test_git_repo "test_repo"
    create_test_git_repo "_excluded_repo"

    # Run status-all
    run_gitz status-all .
    assert_success
    assert_output_contains "test_repo"
    refute_output_contains "_excluded_repo"
    assert_output_contains "Checked 1 repositories"

    # Cleanup
    rm -rf test_repo _excluded_repo
}

@test "gitz status-all excludes paths with .work" {
    if ! command_exists git; then
        skip "git not installed"
    fi

    # Create repos, one with .work
    create_test_git_repo "test_repo"
    mkdir -p "test.work"
    create_test_git_repo "test.work/excluded_repo"

    # Run status-all
    run_gitz status-all .
    assert_success
    assert_output_contains "test_repo"
    refute_output_contains "excluded_repo"
    assert_output_contains "Checked 1 repositories"

    # Cleanup
    rm -rf test_repo test.work
}

@test "gitz status-all shows git status" {
    if ! command_exists git; then
        skip "git not installed"
    fi

    # Create test repo
    create_test_git_repo "test_repo"

    # Run status-all
    run_gitz status-all .
    assert_success
    # Should contain git status output keywords
    assert_output_contains "branch"

    # Cleanup
    rm -rf test_repo
}

@test "gitz status alias works" {
    if ! command_exists git; then
        skip "git not installed"
    fi

    # Test that 'status' alias works
    run_gitz status .
    # Should run without error (may or may not find repos)
    assert_success
}

@test "gitz status-all defaults to current directory" {
    if ! command_exists git; then
        skip "git not installed"
    fi

    # Run without path argument
    run_gitz status-all
    assert_success
    # Should run without error
}
