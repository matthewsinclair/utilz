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
  echo -e "${BLUE}ℹ${RESET} $*" >&2
}

success() {
  echo -e "${GREEN}✓${RESET} $*" >&2
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
#
# yq is the single YAML parser in Utilz. This function previously carried a
# grep-based fallback covering four hardcoded queries; every other query
# returned an empty string, which a caller cannot distinguish from "key is
# absent". One parser, one answer. require_yq surfaces a missing yq once per
# process rather than silently degrading.
get_util_metadata() {
  local util_name="$1"
  local query="$2"
  local yaml_file="$UTILZ_HOME/opt/$util_name/$util_name.yaml"

  [[ -f "$yaml_file" ]] || return 1
  require_yq || return 1

  local result
  result=$(yq eval "$query" "$yaml_file" 2>/dev/null)

  # A utility may defer its version to a shared file rather than inline it:
  # utilz itself points version_file at the repo-root VERSION.
  if [[ "$query" == ".version" && "$result" == "null" ]]; then
    local version_file_ref
    version_file_ref=$(yq eval ".version_file" "$yaml_file" 2>/dev/null)
    if [[ -n "$version_file_ref" && "$version_file_ref" != "null" ]]; then
      local abs_version_file="$(dirname "$yaml_file")/$version_file_ref"
      if [[ -f "$abs_version_file" ]]; then
        cat "$abs_version_file"
        return 0
      fi
    fi
  fi

  echo "$result"
}

# Show help for a utility
show_help() {
  local util="${1:-utilz}"
  local help_file="$UTILZ_HOME/help/$util.md"

  if [[ -f "$help_file" ]]; then
    if command -v glow >/dev/null 2>&1; then
      glow "$help_file"
    elif command -v bat >/dev/null 2>&1; then
      bat --style=plain --language=markdown "$help_file"
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
  # Once, before the loop: every description below is a get_util_metadata
  # call, and each of those runs in its own subshell.
  require_yq || return 1

  echo "Available utilities:"
  echo ""

  local name desc
  while IFS= read -r name; do
    desc=$(get_util_metadata "$name" ".description") || desc=""
    printf "  ${BOLD}%-15s${RESET} %s\n" "$name" "${desc:-No description available}"
  done < <(each_utility)

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

# THE gate for the yq hard dependency. yq is the only YAML parser in Utilz
# (see get_util_metadata), so it is declared as a required dependency in
# opt/utilz/utilz.yaml.
#
# A caller that loops over utilities must call this ONCE before its loop.
# get_util_metadata runs inside a command substitution, so it cannot memoise
# anything -- a subshell's variables die with it -- and relying on its
# per-call guard alone reprints the install hint once per utility.
require_yq() {
  if check_command yq; then
    return 0
  fi

  error "yq is required for YAML parsing"
  echo "" >&2
  echo "Install with:" >&2
  echo "  brew install yq" >&2
  return 1
}

# THE walker of bin/. Emits the name of every installed utility -- a symlink
# in bin/ pointing at the dispatcher -- one per line, excluding the
# dispatcher itself.
#
# Every consumer iterates this and nothing else: list_utilities, run_doctor,
# run_tests, emit_integration_tsv, emacs_doctor. Those five previously
# open-coded the same glob-and-filter loop, and had already drifted -- two
# checked that the symlink resolved to utilz, three accepted any symlink in
# bin/ at all, so a stray link was a utility to doctor and not to list.
#
# Consume with process substitution, not a pipe, so accumulator variables
# survive the loop:
#   while IFS= read -r name; do ...; done < <(each_utility)
each_utility() {
  local symlink name target

  for symlink in "$UTILZ_HOME"/bin/*; do
    if [[ ! -L "$symlink" ]]; then
      continue
    fi

    name=$(basename "$symlink")
    if [[ "$name" == "utilz" ]]; then
      continue
    fi

    target=$(readlink "$symlink")
    if [[ "$target" != "utilz" && "$target" != "./utilz" ]]; then
      continue
    fi

    echo "$name"
  done

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

  # Resolved once, up front. doctor is the command you run to find out that
  # yq is missing, so it must not require yq to complete -- checks 5 and 6
  # both branch on this rather than calling require_yq and bailing.
  local have_yq=0
  if check_command yq; then
    have_yq=1
  fi

  # Check 1: UTILZ_HOME is set and valid
  echo -e "${BOLD}[1/6]${RESET} Checking UTILZ_HOME..."
  if [[ -z "${UTILZ_HOME:-}" ]]; then
    error "UTILZ_HOME is not set"
    issues=$((issues + 1))
  elif [[ ! -d "$UTILZ_HOME" ]]; then
    error "UTILZ_HOME points to non-existent directory: $UTILZ_HOME"
    issues=$((issues + 1))
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
    issues=$((issues + 1))
  else
    success "All required directories present"
  fi
  echo ""

  # Check 3: bin/utilz exists and is executable
  echo -e "${BOLD}[3/6]${RESET} Checking bin/utilz..."
  if [[ ! -f "$UTILZ_HOME/bin/utilz" ]]; then
    error "bin/utilz not found"
    issues=$((issues + 1))
  elif [[ ! -x "$UTILZ_HOME/bin/utilz" ]]; then
    warn "bin/utilz is not executable"
    echo "  Fix with: chmod +x $UTILZ_HOME/bin/utilz"
    issues=$((issues + 1))
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
    issues=$((issues + 1))
  fi
  echo ""

  # Check 5: Installed utilities
  echo -e "${BOLD}[5/6]${RESET} Checking installed utilities..."
  local util_count=0
  local broken_utils=()
  local incompatible_utils=()
  local framework_version=$(get_utilz_version)
  local framework_major=$(echo "$framework_version" | cut -d. -f1)
  local name impl required_utilz_version required_major

  while IFS= read -r name; do
    util_count=$((util_count + 1))

    impl="$UTILZ_HOME/opt/$name/$name"
    if [[ ! -f "$impl" ]]; then
      broken_utils+=("$name (no implementation)")
      continue
    fi
    if [[ ! -x "$impl" ]]; then
      broken_utils+=("$name (not executable)")
      continue
    fi

    # Version compatibility needs the YAML; check 6 reports the missing yq.
    if [[ $have_yq -eq 0 ]]; then
      continue
    fi

    required_utilz_version=$(get_util_metadata "$name" ".utilz_version") || required_utilz_version=""
    if [[ -z "$required_utilz_version" || "$required_utilz_version" == "null" ]]; then
      continue
    fi

    # Major version only.
    required_major=$(echo "$required_utilz_version" | sed 's/^\^//' | sed 's/[^0-9].*//')
    if [[ "$required_major" != "$framework_major" ]]; then
      incompatible_utils+=("$name (requires Utilz $required_utilz_version, have $framework_version)")
    fi
  done < <(each_utility)

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
    issues=$((issues + 1))
  else
    success "Found $util_count utilities, all properly configured"
  fi
  echo ""

  # Check 6: External dependencies
  echo -e "${BOLD}[6/6]${RESET} Checking external dependencies..."
  local missing_deps=()
  local missing_dep_info=()
  local yaml_file dep_count dep_name dep_install i

  # yq is reported by hand, and first: it is the framework's own hard
  # dependency and the only YAML parser, so nothing below can read a single
  # dependency declaration until it is present. Parsing YAML to discover that
  # the YAML parser is missing does not work.
  if [[ $have_yq -eq 1 ]]; then
    # utilz is in this walk, unlike the checks above -- opt/utilz/utilz.yaml
    # declares its own dependencies, and one that no check ever reads is a
    # declaration in name only.
    while IFS= read -r name; do
      yaml_file="$UTILZ_HOME/opt/$name/$name.yaml"
      if [[ ! -f "$yaml_file" ]]; then
        continue
      fi

      dep_count=$(yq eval '.dependencies | length' "$yaml_file" 2>/dev/null)
      if [[ "$dep_count" == "null" || "$dep_count" == "0" ]]; then
        continue
      fi

      for ((i = 0; i < dep_count; i++)); do
        dep_name=$(yq eval ".dependencies[$i].name" "$yaml_file" 2>/dev/null)
        dep_install=$(yq eval ".dependencies[$i].install" "$yaml_file" 2>/dev/null)

        if ! check_command "$dep_name"; then
          missing_deps+=("$dep_name")
          missing_dep_info+=("$dep_name|$dep_install|$name")
        fi
      done
    done < <(printf '%s\n' "utilz"; each_utility)
  else
    error "yq is not installed; it is required to parse utility metadata"
    missing_deps+=("yq")
    missing_dep_info+=("yq|brew install yq|utilz")
  fi

  # Check for glow (nice-to-have for help)
  if ! check_command "glow"; then
    info "Optional: Install 'glow' for beautiful markdown rendering"
    echo -e "    brew install glow"
  fi

  # Check for exiftool (optional for cleanz --image mode)
  if ! check_command "exiftool"; then
    info "Optional: Install 'exiftool' for cleanz image metadata stripping"
    echo -e "    brew install exiftool"
  fi

  # Check for rsync (required for syncz)
  if ! check_command "rsync"; then
    info "Required: Install 'rsync' for syncz directory syncing"
    echo -e "    Pre-installed on most systems; brew install rsync (macOS)"
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
    issues=$((issues + 1))
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

  require_yq || return 1

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

    local name
    while IFS= read -r name; do
      utils_to_test+=("$name")
    done < <(each_utility)
  fi

  # Run tests for each utility
  local total_failed=0
  local total_tested=0

  for util in "${utils_to_test[@]}"; do
    local test_dir="$UTILZ_HOME/opt/$util/test"

    if [[ ! -d "$test_dir" ]]; then
      continue
    fi

    # Find .bats files in test directory
    local bats_files=()
    while IFS= read -r -d '' file; do
      bats_files+=("$file")
    done < <(find "$test_dir" -name "*.bats" -type f -print0 2>/dev/null)

    if [[ ${#bats_files[@]} -eq 0 ]]; then
      continue
    fi

    echo -e "${BOLD}Testing: $util${RESET}"
    echo -e "Location: $test_dir"
    echo -e ""

    # Run bats on all test files
    total_tested=$((total_tested + 1))

    # Run bats (allow failures, we handle exit code)
    local bats_exit=0
    (
      cd "$test_dir" || exit 1
      bats *.bats
    ) || bats_exit=$?

    if [[ $bats_exit -eq 0 ]]; then
      echo -e ""
      success "$util tests passed"
      echo -e ""
    else
      echo -e ""
      error "$util tests failed"
      echo -e ""
      total_failed=$((total_failed + 1))
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

# ============================================================================
# INTEGRATION METADATA & EDITOR BRIDGES
# ============================================================================

# Emit a TSV manifest of utilities that declare an `integration:` block.
# Columns (tab-separated): name  description  input  output  flags
# `flags` is a comma-separated list (empty for default `flags: []`).
# Skips: utilz core, utilities without an integration block, non-symlinks.
# Warns (to stderr) and skips utilities whose integration values are missing.
#
# This is the single walker of the YAML corpus (Highlander). Every editor
# integration (Emacs, future VSCode / Zed / Vim) consumes this TSV directly.
emit_integration_tsv() {
  require_yq || return 1

  local name yaml_file has_integration desc input output flags

  while IFS= read -r name; do
    yaml_file="$UTILZ_HOME/opt/$name/$name.yaml"
    if [[ ! -f "$yaml_file" ]]; then continue; fi

    has_integration=$(yq eval '.integration' "$yaml_file" 2>/dev/null)
    if [[ "$has_integration" == "null" ]]; then continue; fi

    desc=$(yq eval '.description' "$yaml_file" 2>/dev/null)
    input=$(yq eval '.integration.input' "$yaml_file" 2>/dev/null)
    output=$(yq eval '.integration.output' "$yaml_file" 2>/dev/null)
    flags=$(yq eval '.integration.flags | join(",")' "$yaml_file" 2>/dev/null)

    if [[ "$flags" == "null" ]]; then flags=""; fi
    if [[ "$desc" == "null" ]]; then desc=""; fi

    if [[ -z "$input" || "$input" == "null" ]]; then
      warn "$name: integration.input missing or null; skipping"
      continue
    fi
    if [[ -z "$output" || "$output" == "null" ]]; then
      warn "$name: integration.output missing or null; skipping"
      continue
    fi

    printf '%s\t%s\t%s\t%s\t%s\n' "$name" "$desc" "$input" "$output" "$flags"
  done < <(each_utility)
}

# Health-check the Emacs bridge: PATH reachability, integration metadata
# validity on every installed utility, canonical elisp file presence.
# Returns 0 when all hard checks pass; canonical-elisp absence is info only
# (expected before ST0007/WP03 lands the bridge file).
emacs_doctor() {
  echo -e "${BOLD}Utilz Emacs Bridge Doctor${RESET}"
  echo "========================="
  echo ""

  local issues=0

  # Check 1: utilz on PATH (so Emacs child processes can find it)
  echo -e "${BOLD}[1/3]${RESET} Checking utilz command on PATH..."
  if command -v utilz >/dev/null 2>&1; then
    success "utilz is on PATH: $(command -v utilz)"
  else
    warn "utilz is not on PATH"
    echo "  Emacs child processes need to find 'utilz'. Ensure"
    echo "  \$UTILZ_HOME/bin is in PATH before Emacs starts."
    issues=$((issues + 1))
  fi
  echo ""

  # Check 2: integration metadata on every installed utility
  echo -e "${BOLD}[2/3]${RESET} Checking integration metadata..."
  local missing=()
  local invalid=()
  local exposed=0

  require_yq || return 1

  local name yaml_file has_integration input output
  while IFS= read -r name; do
    yaml_file="$UTILZ_HOME/opt/$name/$name.yaml"
    if [[ ! -f "$yaml_file" ]]; then continue; fi

    has_integration=$(yq eval '.integration' "$yaml_file" 2>/dev/null)
    if [[ "$has_integration" == "null" ]]; then
      missing+=("$name")
      continue
    fi

    input=$(yq eval '.integration.input' "$yaml_file" 2>/dev/null)
    output=$(yq eval '.integration.output' "$yaml_file" 2>/dev/null)

    case "$input" in
      stdin|file|path|none) ;;
      *) invalid+=("$name (input='$input')") ; continue ;;
    esac
    case "$output" in
      replace|buffer|message|discard) ;;
      *) invalid+=("$name (output='$output')") ; continue ;;
    esac

    exposed=$((exposed + 1))
  done < <(each_utility)

  if [[ ${#missing[@]} -gt 0 ]]; then
    warn "${#missing[@]} utility/utilities without an integration: block:"
    for name in "${missing[@]}"; do
      echo "    - $name (opt/$name/$name.yaml)"
    done
    issues=$((issues + 1))
  fi
  if [[ ${#invalid[@]} -gt 0 ]]; then
    error "${#invalid[@]} utility/utilities with invalid integration values:"
    for name in "${invalid[@]}"; do
      echo "    - $name"
    done
    issues=$((issues + 1))
  fi
  if [[ ${#missing[@]} -eq 0 && ${#invalid[@]} -eq 0 ]]; then
    success "$exposed utility/utilities exposed via integration metadata"
  fi
  echo ""

  # Check 3: canonical elisp file (info only — absence expected pre-WP03)
  echo -e "${BOLD}[3/3]${RESET} Checking canonical elisp file..."
  local canonical="$UTILZ_HOME/static/emacs/utilz.el"
  if [[ -f "$canonical" ]]; then
    success "Canonical elisp present: $canonical"
  else
    info "Canonical elisp not yet present: $canonical"
    echo "  (expected before ST0007/WP03 lands the bridge file)"
  fi
  echo ""

  echo "========================="
  if [[ $issues -eq 0 ]]; then
    echo -e "${GREEN}${BOLD}✓ All checks passed!${RESET}"
    return 0
  else
    echo -e "${YELLOW}${BOLD}⚠ Found $issues issue(s)${RESET}"
    return 1
  fi
}

# Install the canonical elisp file to a user-specified destination.
# Usage: emacs_install --dest PATH [--symlink] [--force]
#
# Idempotent: re-running on an unchanged destination is a no-op. Requires
# --force to overwrite a destination whose content/target differs from the
# canonical source.
emacs_install() {
  local dest=""
  local use_symlink=0
  local force=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dest)
        if [[ -z "${2:-}" ]]; then
          error "--dest requires a PATH argument"
          return 1
        fi
        dest="$2"
        shift 2
        ;;
      --symlink)
        use_symlink=1
        shift
        ;;
      --force)
        force=1
        shift
        ;;
      --help|-h)
        _emacs_install_usage
        return 0
        ;;
      *)
        error "Unknown option: $1"
        _emacs_install_usage >&2
        return 1
        ;;
    esac
  done

  if [[ -z "$dest" ]]; then
    error "--dest PATH is required"
    _emacs_install_usage >&2
    return 1
  fi

  local src="$UTILZ_HOME/static/emacs/utilz.el"
  if [[ ! -f "$src" ]]; then
    error "Canonical elisp file not found: $src"
    echo "The Emacs bridge file has not been created yet." >&2
    echo "This is expected before ST0007/WP03 completes." >&2
    return 1
  fi

  # Expand leading ~ in dest
  dest="${dest/#\~/$HOME}"

  local dest_dir
  dest_dir=$(dirname "$dest")
  if [[ ! -d "$dest_dir" ]]; then
    error "Destination directory does not exist: $dest_dir"
    echo "Create it first, then re-run install." >&2
    return 1
  fi

  # Idempotency: skip if the destination already matches the source
  if [[ -L "$dest" ]]; then
    local target
    target=$(readlink "$dest")
    if [[ "$target" == "$src" ]]; then
      success "Already installed as symlink: $dest -> $src"
      _emacs_install_hint "$dest"
      return 0
    fi
    if [[ $force -eq 0 ]]; then
      error "Destination is a symlink to a different target:"
      echo "  $dest -> $target" >&2
      echo "Use --force to replace." >&2
      return 1
    fi
  elif [[ -f "$dest" ]]; then
    if cmp -s "$src" "$dest" 2>/dev/null; then
      success "Already installed (content matches): $dest"
      _emacs_install_hint "$dest"
      return 0
    fi
    if [[ $force -eq 0 ]]; then
      error "Destination exists and differs from source: $dest"
      echo "Use --force to overwrite." >&2
      return 1
    fi
  fi

  if [[ $use_symlink -eq 1 ]]; then
    ln -sfn "$src" "$dest"
    success "Installed symlink: $dest -> $src"
  else
    cp "$src" "$dest"
    success "Installed copy: $dest"
  fi

  _emacs_install_hint "$dest"
}

_emacs_install_usage() {
  cat <<'EOF'
Usage: utilz emacs install --dest PATH [--symlink] [--force]

Install the canonical Utilz elisp bridge to PATH so Emacs can load it.

Options:
  --dest PATH   Destination path (required). For a Doom setup:
                ~/.config/doom/custom/160-utilz.el
  --symlink     Create a symlink instead of a copy. Recommended for
                development: 'git pull' in Utilz rolls the bridge forward.
  --force       Overwrite existing destination even if content differs.

After install, add the printed load statement to your Emacs config. For
Doom that lives in ~/.config/doom/config.el alongside the existing custom/
load statements.
EOF
}

_emacs_install_hint() {
  local dest="$1"
  local base
  base=$(basename "$dest")
  echo ""
  echo "Next: add to your Emacs config:"
  echo "  (load \"$base\")"
  echo ""
  echo "For Doom, that lives in ~/.config/doom/config.el alongside the"
  echo "existing custom/ load statements."
}

# ============================================================================
# GENERATE UTILITY
# ============================================================================

generate_utility() {
  local util_name="${1:-}"
  local util_desc="${2:-A new utility}"
  local author="${3:-$(git config user.name 2>/dev/null || echo "Your Name")}"
  local year=$(date +%Y)

  if [[ -z "$util_name" ]]; then
    error "Usage: utilz generate <name> [description] [author]"
    echo ""
    echo "Example:"
    echo "  utilz generate mytool \"Does something useful\" \"Your Name\""
    return 1
  fi

  # Validate name
  if [[ ! "$util_name" =~ ^[a-z][a-z0-9-]*$ ]]; then
    error "Invalid utility name: $util_name"
    echo "Name must start with a letter and contain only lowercase letters, numbers, and hyphens"
    return 1
  fi

  local util_dir="$UTILZ_HOME/opt/$util_name"
  local bin_link="$UTILZ_HOME/bin/$util_name"

  # Check if utility already exists
  if [[ -d "$util_dir" ]]; then
    error "Utility already exists: $util_dir"
    return 1
  fi

  if [[ -L "$bin_link" ]] || [[ -f "$bin_link" ]]; then
    error "Binary already exists: $bin_link"
    return 1
  fi

  info "Generating utility: $util_name"
  echo ""

  # Create directory structure
  info "Creating directory structure..."
  mkdir -p "$util_dir/test"

  # Generate files from templates
  local tmpl_dir="$UTILZ_HOME/opt/utilz/tmpl"
  local impl_path="$util_dir/$util_name"
  local help_path="$UTILZ_HOME/help/$util_name.md"

  info "Generating implementation..."
  sed -e "s/{{NAME}}/$util_name/g" \
    -e "s/{{DESCRIPTION}}/$util_desc/g" \
    -e "s/{{AUTHOR}}/$author/g" \
    -e "s/{{YEAR}}/$year/g" \
    "$tmpl_dir/script.tmpl" > "$impl_path"
  chmod +x "$impl_path"

  # The compatibility floor is derived from the framework's own VERSION, never
  # written into the template. metadata.tmpl used to hardcode "^1.0.0"; once
  # the framework reached 2.x, every generated utility was born incompatible
  # and run_doctor flagged it until someone hand-edited the yaml by hand.
  local utilz_floor="^$(get_utilz_version | cut -d. -f1).0.0"

  info "Generating metadata..."
  sed -e "s/{{NAME}}/$util_name/g" \
    -e "s/{{DESCRIPTION}}/$util_desc/g" \
    -e "s/{{AUTHOR}}/$author/g" \
    -e "s/{{UTILZ_FLOOR}}/$utilz_floor/g" \
    "$tmpl_dir/metadata.tmpl" > "$util_dir/$util_name.yaml"

  info "Generating README..."
  sed -e "s/{{NAME}}/$util_name/g" \
    -e "s/{{DESCRIPTION}}/$util_desc/g" \
    -e "s/{{AUTHOR}}/$author/g" \
    -e "s/{{YEAR}}/$year/g" \
    -e "s|{{IMPL_PATH}}|$impl_path|g" \
    -e "s|{{HELP_PATH}}|$help_path|g" \
    "$tmpl_dir/README.tmpl" > "$util_dir/README.md"

  info "Generating help file..."
  sed -e "s/{{NAME}}/$util_name/g" \
    -e "s/{{DESCRIPTION}}/$util_desc/g" \
    -e "s/{{AUTHOR}}/$author/g" \
    -e "s/{{YEAR}}/$year/g" \
    "$tmpl_dir/help.tmpl" > "$help_path"

  info "Generating test file..."
  sed -e "s/{{NAME}}/$util_name/g" \
    "$tmpl_dir/test.tmpl" > "$util_dir/test/$util_name.bats"
  chmod +x "$util_dir/test/$util_name.bats"

  info "Creating symlink..."
  cd "$UTILZ_HOME/bin"
  ln -s utilz "$util_name"
  cd - >/dev/null

  echo ""
  success "Utility '$util_name' generated successfully!"
  echo ""
  echo "Next steps:"
  echo "  1. Edit implementation: $impl_path"
  echo "  2. Add tests: $util_dir/test/$util_name.bats"
  echo "  3. Update help: $help_path"
  echo "  4. Test it: $util_name --help"
  echo "  5. Run tests: utilz test $util_name"
  echo ""
  echo "Generated files:"
  echo "  - $impl_path"
  echo "  - $util_dir/$util_name.yaml"
  echo "  - $util_dir/README.md"
  echo "  - $util_dir/test/$util_name.bats"
  echo "  - $help_path"
  echo "  - $bin_link -> utilz"
}
