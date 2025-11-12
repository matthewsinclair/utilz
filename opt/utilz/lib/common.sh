#!/usr/bin/env bash
#
# Utilz - Common functions library
#
# This library provides shared functions for all Utilz utilities.
# Sourced by bin/utilz dispatcher.
#

# ============================================================================
# COLORS & FORMATTING
# ============================================================================

if [[ -t 1 ]]; then
    # Terminal supports colors
    BOLD='\033[1m'
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    RESET='\033[0m'
else
    # No colors (piped output or non-tty)
    BOLD=''
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    RESET=''
fi

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

info() {
    echo -e "${BLUE}ℹ${RESET} $*"
}

success() {
    echo -e "${GREEN}✓${RESET} $*"
}

warn() {
    echo -e "${YELLOW}⚠${RESET} $*" >&2
}

error() {
    echo -e "${RED}✗${RESET} $*" >&2
}

debug() {
    if [[ "${UTILZ_DEBUG:-}" == "1" ]]; then
        echo -e "${BOLD}[DEBUG]${RESET} $*" >&2
    fi
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Get Utilz framework version from VERSION file
get_utilz_version() {
    local version_file="$UTILZ_HOME/VERSION"
    if [[ -f "$version_file" ]]; then
        cat "$version_file"
    else
        echo "unknown"
    fi
}

# Get utility metadata from YAML file
# Usage: get_util_metadata "mdagg" ".description"
get_util_metadata() {
    local util_name="$1"
    local query="$2"
    local yaml_file="$UTILZ_HOME/opt/$util_name/$util_name.yaml"

    if [[ -f "$yaml_file" ]]; then
        if check_command "yq"; then
            local result=$(yq eval "$query" "$yaml_file" 2>/dev/null)

            # Special handling for version_file reference
            if [[ "$query" == ".version" && "$result" == "null" ]]; then
                local version_file_ref=$(yq eval ".version_file" "$yaml_file" 2>/dev/null)
                if [[ -n "$version_file_ref" && "$version_file_ref" != "null" ]]; then
                    # Resolve relative path from yaml_file location
                    local yaml_dir=$(dirname "$yaml_file")
                    local abs_version_file="$yaml_dir/$version_file_ref"
                    if [[ -f "$abs_version_file" ]]; then
                        cat "$abs_version_file"
                        return
                    fi
                fi
            fi

            echo "$result"
        else
            # Fallback: simple grep-based parsing for common queries
            case "$query" in
                .description)
                    grep "^description:" "$yaml_file" | sed 's/^description: *//' | sed 's/^"//' | sed 's/"$//'
                    ;;
                .version)
                    # Check for version_file reference first
                    local version_file_ref=$(grep "^version_file:" "$yaml_file" | sed 's/^version_file: *//')
                    if [[ -n "$version_file_ref" ]]; then
                        local yaml_dir=$(dirname "$yaml_file")
                        local abs_version_file="$yaml_dir/$version_file_ref"
                        if [[ -f "$abs_version_file" ]]; then
                            cat "$abs_version_file"
                            return
                        fi
                    fi
                    # Otherwise get direct version
                    grep "^version:" "$yaml_file" | sed 's/^version: *//'
                    ;;
                .name)
                    grep "^name:" "$yaml_file" | sed 's/^name: *//'
                    ;;
                .utilz_version)
                    grep "^utilz_version:" "$yaml_file" | sed 's/^utilz_version: *//' | sed 's/^"//' | sed 's/"$//'
                    ;;
            esac
        fi
    fi
}

# Show help for a utility
show_help() {
    local util="${1:-utilz}"
    local help_file="$UTILZ_HOME/help/$util.md"

    if [[ -f "$help_file" ]]; then
        if command -v bat >/dev/null 2>&1; then
            bat --style=plain --language=markdown "$help_file"
        elif command -v mdcat >/dev/null 2>&1; then
            mdcat "$help_file"
        else
            cat "$help_file"
        fi
    else
        error "Help file not found: $help_file"
        return 1
    fi
}

# Show version
show_version() {
    local util="${1:-utilz}"

    # Get version from YAML metadata (single source of truth)
    local version=$(get_util_metadata "$util" ".version")
    local description=$(get_util_metadata "$util" ".description")

    if [[ -n "$version" && "$version" != "null" ]]; then
        echo "$util v$version"
        if [[ -n "$description" && "$description" != "null" ]]; then
            echo "$description"
        fi
    else
        echo "$util (version unknown - missing $util.yaml)"
        return 1
    fi
}

# List all available utilities
list_utilities() {
    echo "Available utilities:"
    echo ""

    for symlink in "$UTILZ_HOME"/bin/*; do
        local name=$(basename "$symlink")

        # Skip utilz itself
        if [[ "$name" == "utilz" ]]; then
            continue
        fi

        # Check if it's a symlink to utilz
        if [[ -L "$symlink" ]]; then
            local target=$(readlink "$symlink")
            if [[ "$target" == "utilz" ]] || [[ "$target" == "./utilz" ]]; then
                # Get description from YAML metadata
                local desc=$(get_util_metadata "$name" ".description")

                printf "  ${BOLD}%-15s${RESET} %s\n" "$name" "${desc:-No description available}"
            fi
        fi
    done
    echo ""
    echo "Run 'utilz help <utility>' for detailed information."
}

# Check if a command exists
check_command() {
    command -v "$1" >/dev/null 2>&1
}

# Check if a required command is installed
require_command() {
    local cmd="$1"
    local install_hint="${2:-}"

    if ! check_command "$cmd"; then
        error "Required command not found: $cmd"
        if [[ -n "$install_hint" ]]; then
            echo ""
            echo "Install with:"
            echo "  $install_hint"
        fi
        return 1
    fi
    return 0
}

# ============================================================================
# DOCTOR COMMAND
# ============================================================================

run_doctor() {
    echo -e "${BOLD}Utilz Doctor - System Diagnostics${RESET}"
    echo -e "=================================="
    echo -e ""

    local issues=0

    # Check 1: UTILZ_HOME is set and valid
    echo -e "${BOLD}[1/6]${RESET} Checking UTILZ_HOME..."
    if [[ -z "${UTILZ_HOME:-}" ]]; then
        error "UTILZ_HOME is not set"
        ((issues++))
    elif [[ ! -d "$UTILZ_HOME" ]]; then
        error "UTILZ_HOME points to non-existent directory: $UTILZ_HOME"
        ((issues++))
    else
        success "UTILZ_HOME=$UTILZ_HOME"
    fi
    echo ""

    # Check 2: Directory structure
    echo -e "${BOLD}[2/6]${RESET} Checking directory structure..."
    local required_dirs=("bin" "opt" "opt/utilz" "opt/utilz/lib" "help")
    local missing_dirs=()

    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$UTILZ_HOME/$dir" ]]; then
            missing_dirs+=("$dir")
        fi
    done

    if [[ ${#missing_dirs[@]} -gt 0 ]]; then
        error "Missing directories: ${missing_dirs[*]}"
        ((issues++))
    else
        success "All required directories present"
    fi
    echo ""

    # Check 3: bin/utilz exists and is executable
    echo -e "${BOLD}[3/6]${RESET} Checking bin/utilz..."
    if [[ ! -f "$UTILZ_HOME/bin/utilz" ]]; then
        error "bin/utilz not found"
        ((issues++))
    elif [[ ! -x "$UTILZ_HOME/bin/utilz" ]]; then
        warn "bin/utilz is not executable"
        echo "  Fix with: chmod +x $UTILZ_HOME/bin/utilz"
        ((issues++))
    else
        success "bin/utilz exists and is executable"
    fi
    echo ""

    # Check 4: PATH configuration
    echo -e "${BOLD}[4/6]${RESET} Checking PATH configuration..."
    if echo "$PATH" | grep -q "$UTILZ_HOME/bin"; then
        success "\$UTILZ_HOME/bin is in \$PATH"
    else
        warn "\$UTILZ_HOME/bin is not in \$PATH"
        echo ""
        echo "  Add to your shell config (~/.zshrc or ~/.bashrc):"
        echo "    export UTILZ_HOME=\"$UTILZ_HOME\""
        echo "    export PATH=\"\$UTILZ_HOME/bin:\$PATH\""
        ((issues++))
    fi
    echo ""

    # Check 5: Installed utilities
    echo -e "${BOLD}[5/6]${RESET} Checking installed utilities..."
    local util_count=0
    local broken_utils=()
    local incompatible_utils=()
    local framework_version=$(get_utilz_version)

    for symlink in "$UTILZ_HOME"/bin/*; do
        local name=$(basename "$symlink")

        # Skip utilz itself
        if [[ "$name" == "utilz" ]]; then
            continue
        fi

        if [[ -L "$symlink" ]]; then
            ((util_count++))

            # Check if implementation exists
            local impl="$UTILZ_HOME/opt/$name/$name"
            if [[ ! -f "$impl" ]]; then
                broken_utils+=("$name (no implementation)")
            elif [[ ! -x "$impl" ]]; then
                broken_utils+=("$name (not executable)")
            else
                # Check version compatibility
                local required_utilz_version=$(get_util_metadata "$name" ".utilz_version")
                if [[ -n "$required_utilz_version" && "$required_utilz_version" != "null" ]]; then
                    # Simple compatibility check - just check major version for now
                    local required_major=$(echo "$required_utilz_version" | sed 's/[^0-9].*//' | sed 's/^\^//')
                    local framework_major=$(echo "$framework_version" | cut -d. -f1)

                    if [[ "$required_major" != "$framework_major" ]]; then
                        incompatible_utils+=("$name (requires Utilz $required_utilz_version, have $framework_version)")
                    fi
                fi
            fi
        fi
    done

    if [[ $util_count -eq 0 ]]; then
        info "No utilities installed yet"
    elif [[ ${#broken_utils[@]} -gt 0 ]] || [[ ${#incompatible_utils[@]} -gt 0 ]]; then
        if [[ ${#broken_utils[@]} -gt 0 ]]; then
            warn "Found $util_count utilities, but ${#broken_utils[@]} have issues:"
            for util in "${broken_utils[@]}"; do
                echo "    - $util"
            done
        fi
        if [[ ${#incompatible_utils[@]} -gt 0 ]]; then
            warn "Version incompatibilities detected:"
            for util in "${incompatible_utils[@]}"; do
                echo "    - $util"
            done
        fi
        ((issues++))
    else
        success "Found $util_count utilities, all properly configured"
    fi
    echo ""

    # Check 6: External dependencies
    echo -e "${BOLD}[6/6]${RESET} Checking external dependencies..."
    local missing_deps=()
    local missing_dep_info=()

    # Check dependencies for each installed utility
    for symlink in "$UTILZ_HOME"/bin/*; do
        local name=$(basename "$symlink")

        # Skip utilz itself and non-symlinks
        if [[ "$name" == "utilz" ]] || [[ ! -L "$symlink" ]]; then
            continue
        fi

        local yaml_file="$UTILZ_HOME/opt/$name/$name.yaml"
        if [[ -f "$yaml_file" ]]; then
            # Check if yq is available for proper parsing
            if check_command "yq"; then
                local dep_count=$(yq eval '.dependencies | length' "$yaml_file" 2>/dev/null)
                if [[ "$dep_count" != "null" && "$dep_count" != "0" ]]; then
                    for ((i=0; i<dep_count; i++)); do
                        local dep_name=$(yq eval ".dependencies[$i].name" "$yaml_file" 2>/dev/null)
                        local dep_install=$(yq eval ".dependencies[$i].install" "$yaml_file" 2>/dev/null)

                        if ! check_command "$dep_name"; then
                            missing_deps+=("$dep_name")
                            missing_dep_info+=("$dep_name|$dep_install|$name")
                        fi
                    done
                fi
            else
                # Basic grep fallback for dependencies
                if grep -q "^  - name:" "$yaml_file"; then
                    while IFS= read -r line; do
                        local dep_name=$(echo "$line" | sed 's/.*name: *//')
                        if ! check_command "$dep_name"; then
                            missing_deps+=("$dep_name")
                            missing_dep_info+=("$dep_name||$name")
                        fi
                    done < <(grep "^  - name:" "$yaml_file")
                fi
            fi
        fi
    done

    # Check for bat or mdcat (nice-to-have for help)
    if ! check_command "bat" && ! check_command "mdcat"; then
        info "Optional: Install 'bat' or 'mdcat' for better help display"
        echo -e "    brew install bat"
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        # Remove duplicates
        local unique_deps=($(printf '%s\n' "${missing_deps[@]}" | sort -u))

        warn "Missing dependencies: ${unique_deps[*]}"
        echo -e ""

        for dep_info in "${missing_dep_info[@]}"; do
            IFS='|' read -r dep_name dep_install used_by <<< "$dep_info"
            echo -e "  ${BOLD}$dep_name${RESET} (required by $used_by)"
            if [[ -n "$dep_install" && "$dep_install" != "null" ]]; then
                echo -e "    Install: $dep_install"
            fi
        done
        ((issues++))
    else
        success "All required dependencies installed"
    fi
    echo -e ""

    # Summary
    echo -e "=================================="
    if [[ $issues -eq 0 ]]; then
        echo -e "${GREEN}${BOLD}✓ All checks passed!${RESET}"
        return 0
    else
        echo -e "${YELLOW}${BOLD}⚠ Found $issues issue(s)${RESET}"
        echo -e ""
        echo -e "Fix the issues above and run 'utilz doctor' again."
        return 1
    fi
}

# ============================================================================
# YAML PARSING (using yq)
# ============================================================================

parse_yaml() {
    local yaml_file="$1"
    local query="$2"

    if ! check_command "yq"; then
        error "yq is required for YAML parsing"
        echo ""
        echo "Install with:"
        echo "  brew install yq"
        return 1
    fi

    yq eval "$query" "$yaml_file"
}

# ============================================================================
# TEST RUNNER
# ============================================================================

run_tests() {
    local target_util="${1:-}"

    echo -e "${BOLD}Utilz Test Runner${RESET}"
    echo -e "=================="
    echo -e ""

    # Check if bats is installed
    if ! check_command "bats"; then
        error "bats is required to run tests"
        echo ""
        echo "Install with:"
        echo "  brew install bats-core"
        echo ""
        echo "Or visit: https://github.com/bats-core/bats-core"
        return 1
    fi

    # Determine which utilities to test
    local utils_to_test=()

    if [[ -n "$target_util" ]]; then
        # Test specific utility
        if [[ "$target_util" == "utilz" ]]; then
            # Core framework tests
            utils_to_test=("utilz")
        else
            # Check if utility exists
            if [[ ! -L "$UTILZ_HOME/bin/$target_util" ]]; then
                error "Utility not found: $target_util"
                echo ""
                echo "Run 'utilz list' to see available utilities."
                return 1
            fi
            utils_to_test=("$target_util")
        fi
    else
        # Test all utilities (core + all installed)
        utils_to_test=("utilz")  # Always include core tests

        # Add all installed utilities
        for symlink in "$UTILZ_HOME"/bin/*; do
            local name=$(basename "$symlink")

            # Skip utilz itself
            if [[ "$name" == "utilz" ]]; then
                continue
            fi

            # Check if it's a symlink to utilz
            if [[ -L "$symlink" ]]; then
                local target=$(readlink "$symlink")
                if [[ "$target" == "utilz" ]] || [[ "$target" == "./utilz" ]]; then
                    utils_to_test+=("$name")
                fi
            fi
        done
    fi

    # Run tests for each utility
    local total_failed=0
    local total_tested=0

    for util in "${utils_to_test[@]}"; do
        local test_dir="$UTILZ_HOME/opt/$util/test"

        if [[ ! -d "$test_dir" ]]; then
            info "No tests found for $util (expected: $test_dir)"
            continue
        fi

        # Find .bats files in test directory
        local bats_files=()
        while IFS= read -r -d '' file; do
            bats_files+=("$file")
        done < <(find "$test_dir" -name "*.bats" -type f -print0 2>/dev/null)

        if [[ ${#bats_files[@]} -eq 0 ]]; then
            info "No .bats files found in $test_dir"
            continue
        fi

        echo -e "${BOLD}Testing: $util${RESET}"
        echo -e "Location: $test_dir"
        echo -e ""

        # Run bats on all test files
        ((total_tested++))
        if bats "${bats_files[@]}"; then
            echo -e ""
            success "$util tests passed"
            echo -e ""
        else
            echo -e ""
            error "$util tests failed"
            echo -e ""
            ((total_failed++))
        fi
    done

    # Summary
    echo -e "=================="
    if [[ $total_tested -eq 0 ]]; then
        warn "No tests were run"
        return 1
    elif [[ $total_failed -eq 0 ]]; then
        echo -e "${GREEN}${BOLD}✓ All tests passed! ($total_tested suite(s))${RESET}"
        return 0
    else
        echo -e "${RED}${BOLD}✗ $total_failed of $total_tested test suite(s) failed${RESET}"
        return 1
    fi
}
