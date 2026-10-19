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

# THE path of a utility's yaml, in the running tree or the one passed (issue
# 0081): the reader and every refusal that names the file build it here.
util_yaml_path() {
  printf '%s\n' "${2:-$UTILZ_HOME}/opt/$1/$1.yaml"
}

# Get utility metadata from YAML file
# Usage: get_util_metadata "mdagg" ".description"
#
# yq is the single YAML parser in Utilz. This function previously carried a
# grep-based fallback covering four hardcoded queries; every other query
# returned an empty string, which a caller cannot distinguish from "key is
# absent". One parser, one answer. require_yq surfaces a missing yq once per
# process rather than silently degrading.
# The TREE is an optional third argument, defaulting to the running one. It
# exists because install and upgrade read another tree's yaml, and the previous
# form bound it ambiently -- `raw=$( export UTILZ_HOME="$tree"; ... )`. That was
# correct and it made shellcheck -x report SC2031 on EVERY later read of
# UTILZ_HOME in EVERY file that reaches this one: common.sh started sourcing
# install.sh for doctor's install-integrity check, so one deliberate subshell
# propagated 39 findings across 18 files and reddened a gate that had been green.
# Passing the root is also simply better than rebinding a global to fake it.
#
# ITS STATUS IS AN ANSWER (issue 0081). 0 prints the value, and yq's `null` for
# a key the yaml lacks. 1 means no yaml, no yq, or a version_file this tree does
# not carry or cannot open, which names itself on stderr. 2 means the yaml is
# there and cannot be read: yq could not read what was asked, or the yaml is not
# one map. It prints nothing, so each caller names the cause through
# yaml_read_error. Call it as `x=$(get_util_metadata ...) || status=$?`: a bare
# `|| x=""` reads status 2 as absence, which is how every caller once took a
# yaml's fault for a field it does not carry.
get_util_metadata() {
  local util_name="$1"
  local query="$2"
  local tree="${3:-$UTILZ_HOME}"
  local yaml_file
  yaml_file=$(util_yaml_path "$util_name" "$tree")

  [[ -f "$yaml_file" ]] || return 1
  require_yq || return 1

  local result top=""
  if ! result=$(yq eval "$query" "$yaml_file" 2>/dev/null); then
    return 2
  fi
  # NOT ONE MAP, NOT READ (issue 0081). yq answers a key of a yaml whose top
  # level is a string or a number with an empty line, and a key of one with two
  # documents with both answers, each with status 0, so either would pass for a
  # value. The yaml's type settles it, asked only of an answer that is empty or
  # runs past one line: a one-line answer costs no second read, and a good map's
  # empty value or block text passes.
  if [[ -z "$result" || "$result" == *$'\n'* ]]; then
    if ! top=$(yq eval 'type' "$yaml_file" 2>/dev/null) || [[ "$top" != '!!map' ]]; then
      return 2
    fi
  fi

  # A utility may defer its version to a shared file rather than inline it:
  # utilz itself points version_file at the repo-root VERSION.
  if [[ "$query" == ".version" && "$result" == "null" ]]; then
    local version_file_ref
    if ! version_file_ref=$(yq eval ".version_file" "$yaml_file" 2>/dev/null); then
      return 2
    fi
    if [[ -n "$version_file_ref" && "$version_file_ref" != "null" ]]; then
      local abs_version_file
      abs_version_file="$(dirname "$yaml_file")/$version_file_ref"
      if [[ ! -f "$abs_version_file" ]]; then
        # NO SILENT ERRORS. Falling through to "null" here reports the same
        # thing as a missing yaml, and the two send a reader to different
        # files. This fires in a PUBLISHED tree when version_file names
        # something the publish does not ship.
        echo "$util_name.yaml points version_file at $version_file_ref, which this tree does not carry: $abs_version_file" >&2
        return 1
      fi
      if [[ -f "$abs_version_file" ]]; then
        # `version_file` means "the file that CARRIES the version", not "a file
        # whose whole content is the version". A plain VERSION file is the
        # former by being the latter; a Cargo.toml carries it in [package].
        #
        # This exists because cargo REQUIRES a version in [package], so for a
        # Rust utility that file is a home which cannot be eliminated -- and a
        # second inline `version:` in the yaml would be a copy with no gate,
        # answering `--version` through a different channel from the compiled
        # CARGO_PKG_VERSION. One home, read two ways.
        #
        # Anchored on [package] so a DEPENDENCY's version can never be returned:
        # every dependency lives under its own [[package]] or [dependencies].
        #
        # A file it cannot open is status 1, in the tool's own words on stderr
        # (issue 0081), not 0 with nothing printed.
        case "$abs_version_file" in
          *.toml)
            awk -F'"' '/^\[package\]/ { p = 1; next }
                       /^\[/          { p = 0 }
                       p && /^version[[:space:]]*=/ { print $2; exit }' \
              "$abs_version_file" || return 1
            ;;
          *)
            cat "$abs_version_file" || return 1
            ;;
        esac
        return 0
      fi
    fi
  fi

  echo "$result"
}

# Why yq cannot read <yaml>, for a walker whose read of the file has just
# failed, to name the reason in its refusal (issue 0080). A yaml that does not
# parse gets yq's own first line of complaint, without the "Error: " it opens
# with. One that parses gets what about its shape stopped the read: more than
# one document, or a top level that is not a map, where every read asks for a
# key. It returns 0 whatever yq does: a helper that died here would be the
# silent exit it exists to name.
yaml_read_error() {
  local why="" top=""
  if ! why=$(yq eval 'true' "$1" 2>&1 >/dev/null); then
    why=${why%%$'\n'*}
    why=${why#Error: }
    printf '%s\n' "${why:-yq gave no reason}"
    return 0
  fi
  if ! top=$(yq eval 'type' "$1" 2>/dev/null); then
    top=""
  fi
  if [[ "$top" == *$'\n'* ]]; then
    echo "it holds more than one document"
  elif [[ -n "$top" && "$top" != '!!map' ]]; then
    echo "its top level is $(yaml_type_words "$top"), not a map"
  else
    echo "it parses, but yq could not read the part asked for"
  fi
}

# A yq type tag in words, for a refusal: !!str is "a string".
yaml_type_words() {
  case "$1" in
    '!!str') echo "a string" ;;
    '!!map') echo "a map" ;;
    '!!seq') echo "a list" ;;
    '!!int'|'!!float') echo "a number" ;;
    '!!bool') echo "a boolean" ;;
    '') echo "nothing" ;;
    *) echo "a ${1#!!}" ;;
  esac
}

# Show help for a utility
show_help() {
  local util="${1:-utilz}"
  local help_file="$UTILZ_HOME/help/$util.md"

  if [[ -f "$help_file" ]]; then
    # STDIN IS REDIRECTED, AND THAT IS THE WHOLE OF A DOCUMENTED HANG.
    # A bare `glow "$file"` with a terminal on stdin hangs -- this project has
    # it recorded twice from real incidents, once as "utilz help <anything>
    # HANGS", once as a 120-second accident while measuring it. The renderer is
    # given a FILE; it has no business reading stdin, so closing it costs
    # nothing and removes the hazard.
    #
    # It is NOT about the pager. `-p` was suspected and measured away: glow's
    # pager is opt-in and injecting it changed nothing. Two of us reached the
    # same wrong conclusion about `-p` from two different wrong mechanisms and
    # nearly shipped agreeing -- the defect was underneath the thing we were
    # both discussing. ST0016/D5.
    if command -v glow >/dev/null 2>&1; then
      glow "$help_file" </dev/null
    elif command -v bat >/dev/null 2>&1; then
      bat --style=plain --language=markdown "$help_file" </dev/null
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

  # Get version from YAML metadata (single source of truth). Absence is a
  # handled case here (reported below as "version unknown"), so tolerate the
  # non-zero explicitly rather than masking it inside a `local` assignment.
  local version description meta_status=0
  version=$(get_util_metadata "$util" ".version") || meta_status=$?
  if [[ $meta_status -eq 2 ]]; then
    echo "$util (version unknown - $util.yaml cannot be read: $(yaml_read_error "$(util_yaml_path "$util")"))"
    return 1
  fi
  if [[ $meta_status -ne 0 ]]; then
    version=""
  fi
  # The version read of this same file has answered 0 or 1 by here, so this
  # read cannot answer 2: an empty description is simply none.
  description=$(get_util_metadata "$util" ".description") || description=""

  if [[ -n "$version" && "$version" != "null" ]]; then
    # BOTH VERSIONS ON ONE GREPPABLE LINE (hv, 2026-09-08, ST0015/D2). Two
    # versions are in play whenever a utility misbehaves -- its own and the
    # framework's -- and a bug report carrying one of them is missing the half
    # that explains it. The pair is the FORM, not merely two numbers present:
    # `utilz:<framework>/<util>:<version>`. Both are read, never restated.
    #
    # utilz itself is the degenerate case of the same form: the framework is
    # not "part of" anything, so the pair has no second term and it prints
    # `utilz:<version>` alone. It keeps its third line, which answers WHICH
    # TREE replied -- load-bearing in a two-tree estate and held by an AC.
    #
    # NO `v` PREFIX ANYWHERE (hv, 2026-09-08, resolving D3 toward symmetry):
    # it is noise, and it was the only thing separating the framework's shape
    # from every utility's. This line was the estate's ONLY minter of one.
    if [[ "$util" == "utilz" ]]; then
      echo "$util:$version"
    else
      echo "utilz:$(get_utilz_version)/$util:$version"
    fi
    if [[ -n "$description" && "$description" != "null" ]]; then
      echo "$description"
    fi
    # AC12: which tree answered, and what it was cut from.
    if [[ "$util" == "utilz" ]]; then
      utilz_tree_provenance
    fi
  else
    # NAME WHAT IS ACTUALLY MISSING. This said "missing $util.yaml"
    # unconditionally, and printed it for a tree whose yaml was present and
    # readable -- sending the reader to the wrong file, which is the same
    # defect as a warning naming the wrong mechanism. get_util_metadata has
    # already said WHICH file on stderr in the version_file case.
    if [[ ! -f "$(util_yaml_path "$util")" ]]; then
      echo "$util (version unknown - missing $util.yaml)"
    else
      echo "$util (version unknown - $util.yaml carries no version this tree can read)"
    fi
    return 1
  fi
}

# THE one place a dispatched utility invocation is answered before its
# implementation runs: `--version`, `--help` and `-h`.
#
# It began as the `--version` half (ST0015) and grew the help half one thread
# later (ST0016), because BOTH flags had the same defect from the same cause.
# `bin/utilz` intercepted them on the SYMLINK dispatch site only, so:
#
#   --version  thirteen utilities hand-copied an arm to cover `utilz <util>`,
#              and the two that could not -- todo, which never did, and prez,
#              whose clap answers first -- were the two that broke.
#   --help     nothing covered the other form at all, so 14 of 15 utilities
#              answered `<util> --help` with the curated help/<name>.md and
#              `utilz <util> --help` with their own terse inline usage.
#
# ONE function rather than two: a second, --help-shaped intercept beside the
# --version one would rebuild the exact arrangement ST0015 removed -- two
# homes agreeing by convention until they do not.
#
# Exit status is the renderer's own. The previous inline --version form exited
# 0 whatever show_version returned, which turned an unreadable version into a
# silent success (IN-AG-NO-SILENT-001); show_help likewise fails when a help
# file is missing, and that must reach the caller.
predispatch_intercept() {
  local util="$1"
  shift
  case "${1:-}" in
    --version)
      show_version "$util"
      exit $?
      ;;
    --help | -h)
      show_help "$util"
      exit $?
      ;;
  esac
}

# List all available utilities
list_utilities() {
  # Once, before the loop: every description below is a get_util_metadata
  # call, and each of those runs in its own subshell.
  require_yq || return 1

  echo "Available utilities:"
  echo ""

  local name desc meta_status
  while IFS= read -r name; do
    # A yaml that cannot be read gets a row of its own words, and doctor says
    # why (issue 0081): yq's reason is too long for a listing.
    meta_status=0
    desc=$(get_util_metadata "$name" ".description") || meta_status=$?
    if [[ $meta_status -eq 2 ]]; then
      desc="($name.yaml cannot be read; utilz doctor says why)"
    elif [[ $meta_status -ne 0 ]]; then
      desc=""
    fi
    printf "  ${BOLD}%-15s${RESET} %s\n" "$name" "${desc:-No description available}"
  done < <(each_utility)

  echo ""
  echo "Run 'utilz help <utility>' for detailed information."
}

# Check if a command exists and can run. bash's `command -v` also names a
# file on PATH that is not executable when nothing executable matches
# (measured under bash 3.2.57 and 5.3.20), so a path it gives must be
# executable; a builtin or a function, named without a path, counts.
check_command() {
  local p
  p="$(command -v "$1" 2>/dev/null)" && [[ "$p" != /* || -x "$p" ]]
}

# Where a macOS app is installed, by bundle id, WITHOUT LAUNCHING IT. Prints
# its path (eg /Applications/Hammerspoon.app) and returns 0; returns 1 when
# there is no such app; prints why and returns 2 when the lookup itself
# failed, which is never taken for an absent app. Only LaunchServices' own
# answer, "no app with bundle id <id>" (measured 16 Oct 2026), means absent.
#
# A dependency that is an app has no command on PATH (Hammerspoon is
# /Applications/Hammerspoon.app), so check_command would call it missing on
# every machine. This asks LaunchServices through NSWorkspace, which only looks
# the app up. MEASURED, because the obvious form is wrong: osascript's
# `path to application id "<id>"` LAUNCHES the app it is asked about (Chess,
# not running, was running four seconds later), so a doctor using it would
# start every app it checks. This form, run three times against Chess, left it
# not running (pgrep 0 before and after), found Hammerspoon, and failed on a
# made-up id. mdfind also leaves apps alone but answers from Spotlight's index,
# which can be off, so it is not used.
#
# The guard is osascript itself: off macOS there is none, so there is no app
# to find, and a test can put a stand-in first on PATH on any OS.
app_path() {
  # The words that mean absent, thrown below and matched after: one string,
  # so rewording the throw cannot quietly turn every absent app into a
  # failed lookup.
  local bundle="$1" absent="no app with bundle id $1" out rc=0
  if ! command -v osascript >/dev/null 2>&1; then
    return 1
  fi
  out="$(osascript -l JavaScript -e "ObjC.import('AppKit');
    var u = \$.NSWorkspace.sharedWorkspace.URLForApplicationWithBundleIdentifier('$bundle');
    if (u.isNil()) { throw new Error('$absent'); }
    u.path.js" 2>&1)" || rc=$?
  # A path is one line starting with /; anything else on success is a warning
  # mixed in, and is said rather than taken for a path.
  if [[ $rc -eq 0 && "$out" == /* && "$out" != *$'\n'* ]]; then
    printf '%s\n' "$out"
    return 0
  fi
  if [[ $rc -ne 0 && "$out" == *"$absent"* ]]; then
    return 1
  fi
  printf 'looking %s up through LaunchServices failed (osascript exited %s): %s\n' "$bundle" "$rc" "$(printf '%s' "$out" | tr '\n' ' ')"
  return 2
}

# Check if a macOS app is installed, by bundle id, without launching it (see
# app_path). Off macOS the answer is always missing. A lookup that failed is
# said, as a warning naming why, and returns 2: utilz doctor has no third
# answer, so it then lists the app with the missing ones, but never silently.
check_app() {
  local out rc=0
  if [[ "$(uname -s)" != "Darwin" ]]; then
    return 1
  fi
  out="$(app_path "$1")" || rc=$?
  if [[ $rc -eq 2 ]]; then
    warn "$out"
  fi
  return "$rc"
}

# How many entries a yaml's dependency <list> holds, for doctor's sweep: 0
# when it is absent or null (issue 0080). A <list> that is not a list prints
# why and returns 1, where `dependencies: jq` was once read as two entries with
# empty names. A yaml yq cannot read, or whose answer is not one type, returns
# 2, for the caller to name with yaml_read_error. Call it as
# `x=$(dependency_count ...) || status=$?`: each status is an answer, and a
# plain statement under set -e would end its caller at the first that is not 0.
dependency_count() {
  local yaml_file="$1" list="$2" kind
  if ! kind=$(yq eval ".${list} | type" "$yaml_file" 2>/dev/null) ||
    [[ -z "$kind" || "$kind" == *$'\n'* ]]; then
    return 2
  fi
  case "$kind" in
    '!!seq') yq eval ".${list} | length" "$yaml_file" 2>/dev/null || return 2 ;;
    '!!null') echo 0 ;;
    *)
      printf '%s is %s, not a list\n' "$list" "$(yaml_type_words "$kind")"
      return 1
      ;;
  esac
}

# Whether one declared dependency is present: an entry carrying `app: <bundle
# id>` is an app and is looked up as one; every other entry is a command. The
# one place that choice is made, for both of doctor's dependency lists.
dependency_present() {
  local yaml_file="$1" list="$2" index="$3" name="$4" app
  app=$(yq eval ".${list}[${index}].app" "$yaml_file" 2>/dev/null)
  if [[ -n "$app" && "$app" != "null" ]]; then
    check_app "$app"
  else
    check_command "$name"
  fi
}

# The purpose doctor prints for a missing dependency, plus why an app
# dependency can never be present off macOS, so that line is not read as
# something to install.
dependency_purpose() {
  local yaml_file="$1" list="$2" index="$3" purpose app
  purpose=$(yq eval ".${list}[${index}].purpose" "$yaml_file" 2>/dev/null)
  app=$(yq eval ".${list}[${index}].app" "$yaml_file" 2>/dev/null)
  if [[ -n "$app" && "$app" != "null" && "$(uname -s)" != "Darwin" ]]; then
    purpose="$purpose; a macOS app, so never present on $(uname -s)"
  fi
  printf '%s\n' "$purpose"
}

# Why entry <index> of <list> names no dependency, for doctor to refuse it by
# name (issue 0085): a map with no `name`, or an entry that is not a map at
# all, such as `- jq`. It returns 0 whatever yq does, as yaml_read_error does.
dependency_entry_fault() {
  local yaml_file="$1" list="$2" index="$3" kind=""
  if ! kind=$(yq eval ".${list}[${index}] | type" "$yaml_file" 2>/dev/null); then
    kind=""
  fi
  if [[ "$kind" == '!!map' ]]; then
    printf '%s[%s] has no name\n' "$list" "$index"
  else
    printf '%s[%s] is %s, not a map with a name\n' "$list" "$index" "$(yaml_type_words "$kind")"
  fi
}

# THE leading-tilde expander. A YAML scalar or a --dest argument is not a shell
# word, so an unexpanded ~ creates a directory literally named ~ under the cwd,
# and every later command then finds it exactly where it looked -- silent and
# self-consistent.
#
# Two callers: emacs_install's --dest, and install_prefix_configured's
# install.prefix (ST0014 design.md D10). The MECHANISM is shared; the refusal
# policy around it deliberately is not.
#
# `~user` is not handled -- it becomes "$HOMEuser". That is the pre-existing
# behaviour of the one implementation this was extracted from, recorded here
# rather than quietly changed: neither caller supports ~user, and adding it
# under cover of an extraction would be inventing a requirement.
expand_tilde() {
  local path="$1"
  printf '%s\n' "${path/#\~/$HOME}"
}

# The manifest's filename at an install root. It is NOT install machinery: it
# is the discriminator between an install tree and a source tree, and both the
# installer that writes it and the runtime that reports provenance need this
# one name. install.sh reads it from here rather than carrying a second copy.
UTILZ_MANIFEST_NAME="manifest.sha256"

# Echo who manages the tree at <dir>: `brew` for a Homebrew keg, else what its
# manifest's managed-by row says, `utilz` for every other publish (ST0019 D4).
#
# A FACT THE KEG CARRIES, NEVER A PATH PATTERN. A Cellar path is where brew
# happens to put a keg today, and a test on it would call a keg moved by
# HOMEBREW_CELLAR someone else's. The formula's publish writes the row, so the
# answer is the one the tree was published with.
#
# A tree with no manifest, or a manifest from before the row existed, is
# `utilz`: brew's publish is the only writer of `brew`, and it has always
# written the row. rc 1, by name, when the manifest is there and unreadable.
#
# Here, not in install.sh, because run_tests asks it where install.sh is not
# loaded, and the install verbs read it from here as they read the name.
install_tree_manager() {
  local manifest="$1/$UTILZ_MANIFEST_NAME"
  local manager

  if [[ ! -f "$manifest" ]]; then
    printf 'utilz\n'
    return 0
  fi

  manager=$(awk -F'\t' '$1 == "managed-by" { print $2; exit }' "$manifest") || {
    error "could not read $manifest"
    return 1
  }

  printf '%s\n' "${manager:-utilz}"
}

# Echo one line describing the tree utilz is running from, and what it was cut
# from if it is an install.
#
# Without this the two-tree arrangement is invisible in precisely the situation
# it exists for (AC12): the version string is identical either way, so someone
# debugging behaviour cannot tell which copy produced it.
utilz_tree_provenance() {
  local manifest="$UTILZ_HOME/$UTILZ_MANIFEST_NAME"
  local commit ci

  if [[ -f "$manifest" ]]; then
    commit=$(awk -F'\t' '$1 == "source-commit" { print substr($2, 1, 7); exit }' "$manifest")
    # CI's verdict on that commit, as the publish recorded it (issue 0016). A
    # manifest cut before the row existed says so: absent is neither unknown
    # nor success.
    ci=$(awk -F'\t' '$1 == "ci-state" { found = 1; print ($2 != "" ? $2 : "unreadable"); exit } END { if (!found) print "not recorded" }' "$manifest")
    printf 'installed at %s (%s, CI %s)\n' "$UTILZ_HOME" "${commit:-unknown}" "$ci"
  else
    printf 'source at %s\n' "$UTILZ_HOME"
  fi
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

# THE Python virtualenv bootstrapper for utilities with Python backends.
# Creates the venv and installs requirements on first use; a no-op thereafter.
#
# Usage: ensure_venv "$VENV_DIR" "$REQUIREMENTS"
#
# pdf2md and xtrct each carried a byte-identical private copy of this. They had
# not drifted yet -- but neither had the five bin/ walkers this library used to
# have, right up until two of them started answering differently. Identical
# copies are the state a Highlander violation is in before it becomes a bug.
#
# Failures are surfaced rather than left for the caller to trip over later: a
# half-built venv produces a confusing "module not found" from the Python side
# instead of the real cause.
ensure_venv() {
  local venv_dir="$1"
  local requirements="$2"

  if [[ -d "$venv_dir" ]]; then
    return 0
  fi

  info "Creating Python virtual environment..."
  if ! python3 -m venv "$venv_dir"; then
    error "Failed to create virtual environment at $venv_dir"
    return 1
  fi

  info "Installing dependencies..."
  if ! "$venv_dir/bin/pip" install --quiet -r "$requirements"; then
    error "Failed to install dependencies from $requirements"
    # Leave no half-built venv behind: its presence would make every later
    # run skip this function and fail further downstream instead.
    rm -rf "$venv_dir"
    return 1
  fi

  success "Virtual environment ready"
}

# THE walker of bin/. Emits the name of every installed utility of a tree --
# a symlink in its bin/ pointing at the dispatcher -- one per line, excluding
# the dispatcher itself. The tree is the running one unless one is given:
# relink names the tree it links into, which may not have the running tree's
# utilities (issue 0079).
#
# Every consumer iterates this and nothing else. Here: list_utilities,
# run_doctor twice (its version check and its dependency sweep), run_tests,
# emit_integration_tsv and emacs_doctor. Elsewhere: the dispatcher's help
# listing in bin/utilz, and relink's install_link_gaps. The first five
# previously open-coded the same glob-and-filter loop, and had already
# drifted -- two checked that the symlink resolved to utilz, three accepted
# any symlink in bin/ at all, so a stray link was a utility to doctor and not
# to list.
#
# Consume with process substitution, not a pipe, so accumulator variables
# survive the loop:
#   while IFS= read -r name; do ...; done < <(each_utility)
each_utility() {
  local tree="${1:-$UTILZ_HOME}"
  local symlink name target

  for symlink in "$tree"/bin/*; do
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

# One missing optional dependency, as check 6 reports it: info, never a
# failure, with the install line and purpose its declarers' yaml gives.
_doctor_optional() {
  local name="$1" install="$2" purpose="$3" declarers="$4"
  local why=""
  if [[ -n "$purpose" && "$purpose" != "null" ]]; then
    why=": $purpose"
  fi
  info "Optional: '$name' is not installed$why (declared by $declarers)"
  if [[ -n "$install" && "$install" != "null" ]]; then
    echo -e "    $install"
  fi
}

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
  echo -e "${BOLD}[1/7]${RESET} Checking UTILZ_HOME..."
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
  echo -e "${BOLD}[2/7]${RESET} Checking directory structure..."
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
  echo -e "${BOLD}[3/7]${RESET} Checking bin/utilz..."
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
  #
  # Two ways to have a working install, and this check used to recognise only
  # the first -- so a symlink install was reported as a problem and doctor said
  # "Found 1 issue(s)" about a setup that worked. Issue 0005.
  #
  # The old test was `echo "$PATH" | grep -q "$UTILZ_HOME/bin"`, which also
  # matched by unanchored regex: $UTILZ_HOME went in unescaped (a `.` or `+` in
  # the path is a metacharacter) and any substring satisfied it, so a stray
  # /opt/Utilz/binaries passed a test for /opt/Utilz/bin. `case` on a delimited
  # PATH is an exact element match with no regex in play.
  echo -e "${BOLD}[4/7]${RESET} Checking PATH configuration..."
  local bin_dir="$UTILZ_HOME/bin"
  local dispatcher="$bin_dir/utilz"
  local path_entry reached_via=""

  case ":$PATH:" in
    *":$bin_dir:"*) reached_via="$bin_dir" ;;
  esac

  if [[ -z "$reached_via" ]]; then
    # A `utilz` symlink on PATH pointing back here (eg ~/.local/bin/utilz) is
    # an equally working install. `-ef` compares device and inode THROUGH
    # symlinks, so this needs no path resolver of its own -- the only one in
    # the codebase, determine_utilz_home in bin/utilz, cannot be reused because
    # it runs before common.sh is sourced (it is what finds common.sh).
    while IFS= read -r path_entry; do
      # An empty PATH element means cwd; never treat that as an install.
      if [[ -z "$path_entry" ]]; then
        continue
      fi
      if [[ -x "$path_entry/utilz" && "$path_entry/utilz" -ef "$dispatcher" ]]; then
        reached_via="$path_entry/utilz"
        break
      fi
    done < <(printf '%s\n' "$PATH" | tr ':' '\n')
  fi

  if [[ "$reached_via" == "$bin_dir" ]]; then
    success "\$UTILZ_HOME/bin is in \$PATH"
  elif [[ -n "$reached_via" ]]; then
    # Named, not just accepted: which route resolved it is the diagnostic.
    success "utilz is on \$PATH via $reached_via"
  else
    warn "\$UTILZ_HOME/bin is not in \$PATH"
    echo ""
    echo "  Add to your shell config (~/.zshrc or ~/.bashrc):"
    echo "    export UTILZ_HOME=\"$UTILZ_HOME\""
    echo "    export PATH=\"\$UTILZ_HOME/bin:\$PATH\""
    echo ""
    echo "  Or symlink the dispatcher onto a directory already on \$PATH:"
    echo "    ln -s \"$dispatcher\" ~/.local/bin/utilz"
    issues=$((issues + 1))
  fi
  echo ""

  # Check 5: Installed utilities
  echo -e "${BOLD}[5/7]${RESET} Checking installed utilities..."
  local util_count=0
  local broken_utils=()
  local incompatible_utils=()
  local name impl required_utilz_version required_major meta_status
  local unreadable_utils=()
  local framework_version framework_major
  framework_version=$(get_utilz_version)
  framework_major=$(echo "$framework_version" | cut -d. -f1)

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

    # ONE FAULT, ONE COUNT (issue 0081). A yaml that cannot be read is named
    # here, so this section no longer calls every utility properly configured,
    # but [6/7] counts it: [6/7] reads every yaml, utilz's own too.
    meta_status=0
    required_utilz_version=$(get_util_metadata "$name" ".utilz_version") || meta_status=$?
    if [[ $meta_status -eq 2 ]]; then
      unreadable_utils+=("$name")
      continue
    fi
    if [[ $meta_status -ne 0 ]]; then
      required_utilz_version=""
    fi
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
      warn "Found $util_count utilities, ${#broken_utils[@]} of them with issues:"
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
  elif [[ ${#unreadable_utils[@]} -eq 0 ]]; then
    success "Found $util_count utilities, all properly configured"
  fi
  if [[ ${#unreadable_utils[@]} -gt 0 ]]; then
    warn "utilz_version is not checked where a yaml cannot be read: ${#unreadable_utils[@]} of $util_count utilities, each counted by [6/7]:"
    # The reason is asked here, in an argument, so its status is no statement's,
    # as it would be the array append's above.
    for util in "${unreadable_utils[@]}"; do
      echo "    - $util ($util.yaml cannot be read: $(yaml_read_error "$(util_yaml_path "$util")"))"
    done
  fi
  echo ""

  # Check 6: External dependencies
  echo -e "${BOLD}[6/7]${RESET} Checking external dependencies..."
  local missing_deps=()
  local missing_dep_info=()
  local optional_missing=()
  local yaml_file dep_count dep_name dep_install dep_purpose dep_required dep_status dep_list i
  local refused_lists=0 refused_entries=0

  # yq is reported by hand, and first: it is the framework's own hard
  # dependency and the only YAML parser, so nothing below can read a single
  # dependency declaration until it is present. Parsing YAML to discover that
  # the YAML parser is missing does not work.
  if [[ $have_yq -eq 1 ]]; then
    # utilz is in this walk, unlike the checks above -- opt/utilz/utilz.yaml
    # declares its own dependencies, and one that no check ever reads is a
    # declaration in name only.
    #
    # AND THE OPTIONAL HALF IS READ AS WELL (issue 0041). Until 2026-09-19 this
    # walk read `.dependencies` alone: no `optional_dependencies` declaration
    # was ever read, and an entry marked `required: false` was reported as a
    # missing requirement. A missing optional dependency is info, with the
    # yaml's own install line and purpose, and it never moves the verdict.
    while IFS= read -r name; do
      yaml_file=$(util_yaml_path "$name")
      if [[ ! -f "$yaml_file" ]]; then
        continue
      fi

      # EACH LIST IS READ, OR REFUSED BY NAME (issue 0080). This was the first
      # read of each yaml, with no ||, so a yaml yq could not read ended doctor
      # here under bin/utilz's set -e, before a word; and a list that was not a
      # list was read as one of its length. A refusal counts as an issue, and a
      # yaml that cannot be read is left for the next utility. One loop takes
      # both lists: an entry of optional_dependencies is optional by its list,
      # and one of dependencies when it says required: false.
      for dep_list in dependencies optional_dependencies; do
        dep_status=0
        dep_count=$(dependency_count "$yaml_file" "$dep_list") || dep_status=$?
        case $dep_status in
          0) ;;
          2)
            # continue 2 stops both lists, so the words and the count say both,
            # unless the yaml failed only at the second, after the first read.
            if [[ "$dep_list" == dependencies ]]; then
              error "$name: $name.yaml cannot be read, so neither of its dependency lists is checked: $(yaml_read_error "$yaml_file")"
              refused_lists=$((refused_lists + 2))
            else
              error "$name: $name.yaml cannot be read, so its optional dependencies are not checked: $(yaml_read_error "$yaml_file")"
              refused_lists=$((refused_lists + 1))
            fi
            issues=$((issues + 1))
            continue 2
            ;;
          *)
            error "$name: $dep_count, so it is not checked"
            issues=$((issues + 1))
            refused_lists=$((refused_lists + 1))
            continue
            ;;
        esac
        for ((i = 0; i < dep_count; i++)); do
          # AN ENTRY IS CHECKED ONLY IF IT NAMES A DEPENDENCY (issue 0085). One
          # written as a bare string, `- jq`, reads its name as empty, and one
          # with no name reads `null`, so each was checked as a dependency with
          # no name. One written as a list cannot be asked for a name at all,
          # and this read, bare, ended doctor. Each is refused by name, counted
          # as an issue, and the sweep goes on.
          if ! dep_name=$(yq eval ".${dep_list}[$i].name" "$yaml_file" 2>/dev/null); then
            dep_name=""
          fi
          if [[ -z "$dep_name" || "$dep_name" == "null" ]]; then
            error "$name: $(dependency_entry_fault "$yaml_file" "$dep_list" "$i")"
            issues=$((issues + 1))
            refused_entries=$((refused_entries + 1))
            continue
          fi
          if dependency_present "$yaml_file" "$dep_list" "$i" "$dep_name"; then
            continue
          fi
          dep_install=$(yq eval ".${dep_list}[$i].install" "$yaml_file" 2>/dev/null)
          dep_required=false
          if [[ "$dep_list" == dependencies ]]; then
            dep_required=$(yq eval ".dependencies[$i].required" "$yaml_file" 2>/dev/null)
          fi
          if [[ "$dep_required" == "false" ]]; then
            dep_purpose=$(dependency_purpose "$yaml_file" "$dep_list" "$i")
            optional_missing+=("$dep_name|$dep_install|$dep_purpose|$name")
          else
            missing_deps+=("$dep_name")
            missing_dep_info+=("$dep_name|$dep_install|$name")
          fi
        done
      done
    done < <(printf '%s\n' "utilz"; each_utility)

    # ONE LINE PER NAME, naming every utility that declares it: glow is
    # declared by utilz and by mdagg, and saying so twice would read as two
    # problems. The sort is stable, so the first declarer's install line and
    # purpose are the ones shown.
    if [[ ${#optional_missing[@]} -gt 0 ]]; then
      local last="" shown_install="" shown_purpose="" declarers="" used_by
      while IFS='|' read -r dep_name dep_install dep_purpose used_by; do
        if [[ "$dep_name" == "$last" ]]; then
          declarers="$declarers, $used_by"
          continue
        fi
        if [[ -n "$last" ]]; then
          _doctor_optional "$last" "$shown_install" "$shown_purpose" "$declarers"
        fi
        last="$dep_name"
        shown_install="$dep_install"
        shown_purpose="$dep_purpose"
        declarers="$used_by"
      done < <(printf '%s\n' "${optional_missing[@]}" | sort -s -t'|' -k1,1)
      _doctor_optional "$last" "$shown_install" "$shown_purpose" "$declarers"
    fi
  else
    error "yq is not installed; it is required to parse utility metadata"
    missing_deps+=("yq")
    missing_dep_info+=("yq|brew install yq|utilz")
    # Said, not skipped: without yq no declaration can be read, and a silence
    # here would read as "nothing optional is missing".
    info "Optional dependencies not checked: their declarations cannot be read without yq"
  fi

  # Check for exiftool (optional for cleanz --image mode). Hand-written, unlike
  # glow and rsync, because no utility's yaml declares it (issue 0041).
  if ! check_command "exiftool"; then
    info "Optional: Install 'exiftool' for cleanz image metadata stripping"
    echo -e "    brew install exiftool"
  fi

  # Check for cargo, but ONLY when this checkout actually carries a Rust crate.
  #
  # Unlike exiftool above, this one is conditional: cargo is a
  # BUILD-time need of whichever utilities ship a crate, and reporting it on a
  # checkout with no Rust in it would be advice about nothing. The condition is
  # the same convention the test runner and CI use -- opt/<name>/crate/Cargo.toml
  # -- so a second crate is covered without touching this line.
  #
  # It stays advisory rather than a missing_deps entry: a utility with a crate
  # builds on first use through its own shim, and that shim refuses by name
  # when cargo is absent. Doctor points at the toolchain; it does not duplicate
  # the refusal the shim already makes well.
  local crate_count
  crate_count=$(find "$UTILZ_HOME/opt" -mindepth 3 -maxdepth 3 \
    -path "$UTILZ_HOME/opt/*/crate/Cargo.toml" 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$crate_count" -gt 0 ]] && ! check_command "cargo"; then
    info "Required: Install Rust for the $crate_count utility/utilities that build from source"
    echo -e "    brew install rust  (they build on first use)"
  fi

  # Check for xcodegen and Xcode, but ONLY on macOS and only when this checkout
  # carries menuz's app source (ST0027): a BUILD-time need, advisory as cargo
  # is above, because menuz's shim refuses by name without them. Xcode is
  # judged by running `xcodebuild -version`, not by finding it: every macOS has
  # an executable /usr/bin/xcodebuild, and without Xcode it only says it
  # requires Xcode. The Command Line Tools' xcodebuild refuses the same way, so
  # the one fix named is Xcode itself.
  if [[ "$(uname -s)" == Darwin && -d "$UTILZ_HOME/native/macos/Menuz" ]]; then
    if ! check_command "xcodegen"; then
      info "Required: Install 'xcodegen' to build menuz's app (native/macos/Menuz)"
      echo -e "    brew install xcodegen"
    fi
    if ! xcodebuild -version >/dev/null 2>&1; then
      info "Required: Install Xcode to build menuz's app (native/macos/Menuz): xcodebuild -version does not run"
      echo -e "    Xcode from the App Store, then: sudo xcode-select --switch /Applications/Xcode.app"
    fi
  fi

  # STEP 6'S VERDICT PRINTS HERE, UNDER STEP 6 (issue 0026). It sat after step
  # 7 until 2026-09-14, so "All required dependencies installed" -- or "Missing
  # dependencies: yq" -- read as the install-integrity step's result.
  if [[ ${#missing_deps[@]} -gt 0 ]]; then
    # Remove duplicates. Read into the array a line at a time rather than
    # splitting a command substitution: a dependency name is not guaranteed
    # whitespace-free, and `mapfile` is bash 4 (macOS ships 3.2).
    local unique_deps=()
    local dep
    while IFS= read -r dep; do
      unique_deps+=("$dep")
    done < <(printf '%s\n' "${missing_deps[@]}" | sort -u)

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
  elif [[ $refused_lists -gt 0 || $refused_entries -gt 0 ]]; then
    # Not "all installed": a list or an entry refused above was never checked
    # (issues 0080 and 0085). Each was counted as an issue where it was refused.
    local read_installed="; every dependency that was read is installed"
    if [[ $refused_lists -gt 0 ]]; then
      warn "$refused_lists dependency list(s) not checked, named above$read_installed"
      read_installed=""
    fi
    if [[ $refused_entries -gt 0 ]]; then
      warn "$refused_entries dependency entr(ies) not checked, named above$read_installed"
    fi
  else
    success "All required dependencies installed"
  fi

  # ------------------------------------------------------------------------
  echo -e ""
  echo -e "${BOLD}[7/7]${RESET} Checking install integrity..."

  # THIS CHECK EXISTS BECAUSE THE MANIFEST CHECKER HAD NO USER-FACING SURFACE.
  # It could only be reached by sourcing the library, so an operator had no way
  # to ask whether their install still matched what was published. Found by vc,
  # 2026-09-08.
  #
  # It is folded into doctor rather than given its own verb: doctor already
  # answers "is this tree sound", and a second command answering the same
  # question is the duplication the Highlander rule is about. A source tree
  # carries no manifest, so this reports NOT APPLICABLE there rather than
  # silently skipping -- "nothing to check" and "checked, clean" must not
  # render as the same line.
  if [[ -f "$UTILZ_HOME/$UTILZ_MANIFEST_NAME" ]]; then
    if [[ -f "$UTILZ_HOME/opt/utilz/lib/install.sh" ]]; then
      local drift check_rc=0
      # Sourced here and nowhere else in this function: install.sh is not
      # loaded for the fifteen utilities' hot path (ST0014 design.md D1).
      # shellcheck source=opt/utilz/lib/install.sh
      source "$UTILZ_HOME/opt/utilz/lib/install.sh"
      drift=$(install_manifest_check "$UTILZ_HOME") || check_rc=$?

      if [[ $check_rc -eq 0 ]]; then
        success "Install matches its manifest"
      elif [[ $check_rc -eq 2 ]]; then
        error "The manifest at $UTILZ_HOME could not be read"
        issues=$((issues + 1))
      else
        warn "$(printf '%s\n' "$drift" | wc -l | tr -d ' ') owned path(s) differ from the manifest"
        printf '%s\n' "$drift" | sed 's/^/    /'
        echo ""
        echo "  'utilz upgrade' from the source tree reports these and leaves"
        echo "  them alone; --force overwrites them."
        issues=$((issues + 1))
      fi
    else
      error "This is an install tree but its install library is missing"
      issues=$((issues + 1))
    fi
  else
    info "Not an install tree, so there is no manifest to check"
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

# A utility can carry up to THREE kinds of suite, discovered by CONVENTION so
# that the next utility of a given shape inherits the driver for free and
# nothing below names a specific utility:
#
#   opt/<name>/crate/Cargo.toml        Rust unit tests      (cargo test)
#   opt/<name>/test/*.bats             shell-level tests    (bats)
#   opt/<name>/crate/test/*.sh         black-box suites     (--strict, always)
#
# run_tests() is the coordinator: it decides WHICH sources a utility has and
# folds the results together. The three helpers below decide nothing -- each
# knows only how to invoke one kind of suite and returns its exit status.
#
# Every helper returns rather than exits, so a caller under `set -e` must
# invoke it in a condition context (`_run_x ... || rc=$?`). Calling one bare
# would abort the whole run on the first failing suite and report nothing.

# Rust unit tests for a utility with a crate.
_run_crate_tests() {
  local util="$1"
  local manifest="$2"

  # A crate with no toolchain is a named finding, never a bare
  # "cargo: command not found" from three frames down.
  require_command "cargo" "brew install rust" || return 1

  echo -e "${BOLD}Testing: $util${RESET} (cargo)"
  echo -e "Manifest: $manifest"
  echo -e ""

  # --workspace AND --no-fail-fast, together, and neither is tidiness.
  #
  # Without --workspace, cargo operates on the ROOT PACKAGE alone -- prez -- and
  # every other crate in the workspace is silently skipped. Measured when the
  # workspace was introduced: 1 executable without it, 2 with. A skipped crate's
  # tests do not fail, they never run, and the suite reports green.
  #
  # Without --no-fail-fast, cargo stops after the first failing TARGET -- so
  # whether a later crate's results appear at all depends on the order cargo
  # happens to run targets in, which is not ours to control.
  #
  # DRIVEN ON THIS TREE, two arms, one injected failure in prez, counting
  # REPORTED FAILURES rather than $? (both arms exit non-zero, so the exit code
  # cannot tell them apart): both arms reported artifact's 12, because artifact
  # ran first that time; the arm without the flag stopped before the third
  # target. So the flag is not "it would hide the other crate" -- it is "every
  # target ran, regardless of an ordering nobody promised us".
  cargo test --workspace --no-fail-fast --manifest-path "$manifest"
}

# Build a crate's release artifacts ONCE, before any source runs (issue 0056).
#
# WHY THIS IS A STAGE OF ITS OWN AND WHY IT IS FIRST. Two of the three sources
# below read `crate/target/release/<bin>`: the BATS source asserts the compiled
# binary's `--version` against the version declared in Cargo.toml, and the
# black-box suites exec the binary directly. Only the third built it. So the
# order was: read the binary, then build it. After a hand version bump -- which
# ST0019 D2 requires, because the release core stamps VERSION and this project
# declares no version sidecars -- the BATS arm read the binary from BEFORE the
# bump and failed:
#
#   not ok 32 prez's version has ONE home, and both channels read that one
#   Expected: prez 2.4.0   Actual: prez 2.3.0
#
# The test was RIGHT about the tree and wrong about the moment. Building here
# fixes the moment rather than weakening the test, which is the whole point:
# the assertion that the two channels agree is worth keeping.
#
# --workspace, for the reason _run_crate_tests gives at length: prez is the
# ROOT package, so a bare `cargo build --release` leaves target/release/showreel
# stale and every suite that execs it tests the previous build.
#
# This adds no work to a full run. The black-box suites already build release;
# this moves that build in front of the readers instead of behind them, and
# cargo serves the later calls from its cache.
_build_crate() {
  local util="$1"
  local manifest="$2"

  require_command "cargo" "brew install rust" || return 1

  echo -e "${BOLD}Building: $util${RESET} (cargo build --release --workspace)"
  echo -e "Manifest: $manifest"
  echo -e ""

  cargo build --release --workspace --manifest-path "$manifest"
}

# The existing BATS path, unchanged in behaviour and moved here so the
# coordinator reads as three symmetrical calls rather than one inline block
# and two additions.
_run_bats_suite() {
  local util="$1"
  local test_dir="$2"

  echo -e "${BOLD}Testing: $util${RESET}"
  echo -e "Location: $test_dir"
  echo -e ""

  (
    cd "$test_dir" || exit 1
    bats ./*.bats
  )
}

# The black-box acceptance suite, ALWAYS with --strict.
#
# --strict is what makes a missing browser or missing node a FAILURE rather
# than a skip. Without it the suite degrades to skips and exits 0, so the run
# goes green having driven nothing -- a check that reads plausibly and
# measures something adjacent to what it names. The flag existing is not the
# same as the flag being passed, which is why it is hard-coded here rather
# than left to a caller.
_run_acceptance_suite() {
  local util="$1"
  local script="$2"

  echo -e "${BOLD}Testing: $util${RESET} (acceptance, --strict)"
  echo -e "Script: $script"
  echo -e ""

  "$script" --strict
}

# Print one suite's verdict. Shared so the three sources report identically;
# bash 3.2 has no namerefs, so the counters stay with the coordinator and this
# passes the status back through its own return.
_report_suite() {
  local util="$1"
  local kind="$2"
  local rc="$3"

  echo -e ""
  if [[ $rc -eq 0 ]]; then
    success "$util $kind passed"
  else
    error "$util $kind failed"
  fi
  echo -e ""

  return "$rc"
}

run_tests() {
  # AC13: the suite mutates $UTILZ_HOME/bin -- which is why it is not safe to
  # run concurrently -- so from a runnable install it would rewrite the very
  # files the manifest checksums, and the install would then report drift
  # nobody caused. Refusing cannot corrupt anything.
  #
  # Re-checksumming after a run was rejected as the remedy: it makes the
  # manifest re-bless whatever the run left behind, which is the refuse-then-
  # bless failure. Devbin never meets this because their install cannot run.
  #
  # This is the FIRST thing run_tests does. A gate placed after any step that
  # touches bin/ has already done the damage it exists to prevent.
  if [[ -f "$UTILZ_HOME/$UTILZ_MANIFEST_NAME" ]]; then
    error "utilz test cannot run from an install tree"
    echo "" >&2
    echo "  This tree is an install: $UTILZ_HOME" >&2
    echo "" >&2
    echo "  The suite mutates \$UTILZ_HOME/bin, so running it here would rewrite" >&2
    echo "  the files the manifest checksums and the install would then report" >&2
    echo "  drift that nobody caused." >&2
    echo "" >&2
    # NAME THE PATH, DO NOT DESCRIBE IT. This said "the checkout this install
    # was published from", which is a description the reader has to resolve
    # themselves, and it made a correct refusal read as a failure with no next
    # step. The manifest records source-tree exactly so this can be answered.
    # An install published before that key existed carries no such row, so the
    # description survives as the fallback rather than printing an empty path.
    #
    # A KEG'S source-tree NAMES NOTHING (ST0019 D4): it is brew's build
    # directory, deleted once the formula's install returned. So a keg names a
    # clone of the repository, the one source a brew user can have.
    local src_tree manager
    src_tree=$(awk -F'\t' '$1 == "source-tree" { print $2; exit }' \
      "$UTILZ_HOME/$UTILZ_MANIFEST_NAME" 2>/dev/null || true)
    manager=$(install_tree_manager "$UTILZ_HOME") || manager="unknown"

    if [[ "$manager" == "brew" ]]; then
      echo "  This install is Homebrew's. Run the suites from a clone instead:" >&2
      echo "" >&2
      echo "      git clone https://github.com/matthewsinclair/utilz.git" >&2
      echo "      cd utilz && bin/utilz test" >&2
    elif [[ -n "$src_tree" ]]; then
      echo "  Run it from the SOURCE tree instead:" >&2
      echo "" >&2
      echo "      cd $src_tree && utilz test" >&2
    else
      echo "  Run it from the Utilz SOURCE tree instead -- the checkout this" >&2
      echo "  install was published from." >&2
    fi
    echo "" >&2
    echo "  An install ships no test suites." >&2
    return 1
  fi

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
    local crate_dir="$UTILZ_HOME/opt/$util/crate"
    local manifest="$crate_dir/Cargo.toml"
    local suite_exit=0

    # Source 0 -- the release build, before anything READS the binary it makes
    # (issue 0056). A crate that cannot build makes every source below
    # meaningless, so this refuses the utility rather than running suites
    # against a stale or absent binary and reporting on the wrong moment.
    if [[ -f "$manifest" ]]; then
      total_tested=$((total_tested + 1))
      suite_exit=0
      _build_crate "$util" "$manifest" || suite_exit=$?
      if ! _report_suite "$util" "release build" "$suite_exit"; then
        total_failed=$((total_failed + 1))
        # Nothing below can say anything true without a binary.
        continue
      fi
    fi

    # Source 1 -- Rust unit tests, first because they are the fastest signal
    # and a broken crate makes the suites below meaningless.
    if [[ -f "$manifest" ]]; then
      total_tested=$((total_tested + 1))
      suite_exit=0
      _run_crate_tests "$util" "$manifest" || suite_exit=$?
      _report_suite "$util" "cargo tests" "$suite_exit" \
        || total_failed=$((total_failed + 1))
    fi

    # Source 2 -- BATS.
    if [[ -d "$test_dir" ]]; then
      local bats_files=()
      while IFS= read -r -d '' file; do
        bats_files+=("$file")
      done < <(find "$test_dir" -name "*.bats" -type f -print0 2>/dev/null)

      if [[ ${#bats_files[@]} -gt 0 ]]; then
        total_tested=$((total_tested + 1))
        suite_exit=0
        _run_bats_suite "$util" "$test_dir" || suite_exit=$?
        _report_suite "$util" "tests" "$suite_exit" \
          || total_failed=$((total_failed + 1))
      fi
    fi

    # Source 3 -- black-box suites, DISCOVERED rather than named (AC03).
    #
    # Naming one file meant a second suite in the same directory was run by
    # nothing: CI green, this driver green, and its ATs marked green in canon
    # on a manual run nothing repeats. The BATS source above already globs;
    # the asymmetry was the defect.
    #
    # A SHELL GLOB rather than `find`. The shell sorts the expansion, so suite
    # order is deterministic without depending on `sort -z` (GNU syntax BSD has
    # historically lacked), and there is no stderr to suppress when crate/test/
    # does not exist -- a suppressed `find` error and a genuinely empty
    # directory are the same observation, which is how a discovery step stops
    # discovering.
    #
    # `*.sh` rather than "any executable file", and this is measured rather
    # than assumed: opt/prez/crate/test/runtime-logic-probe.mjs is -rwxr-xr-x,
    # so a glob on the executable bit would silently start driving a Node probe
    # as a black-box suite.
    local script
    for script in "$crate_dir"/test/*.sh; do
      # An unmatched glob stays literal. That is the "this crate has no
      # black-box suite" case, and it is not a defect.
      [[ -e "$script" ]] || continue

      if [[ ! -x "$script" ]]; then
        # Refuse rather than skip. A non-executable suite is the silent-pass
        # shape this whole driver exists to avoid: the file is right there, the
        # suite it represents never runs, and the summary says everything
        # passed. Discovering a SET rather than one filename does not retire
        # that hazard, it multiplies it -- so the guard is inside the loop.
        error "$util acceptance suite is not executable: $script"
        total_tested=$((total_tested + 1))
        total_failed=$((total_failed + 1))
        continue
      fi

      total_tested=$((total_tested + 1))
      suite_exit=0
      _run_acceptance_suite "$util" "$script" || suite_exit=$?
      # NAMED per suite, not "acceptance suite" for all of them: with more than
      # one, an unattributed failure line cannot say which suite failed.
      _report_suite "$util" "$(basename "$script")" "$suite_exit" \
        || total_failed=$((total_failed + 1))
    done
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

# THE INTEGRATION BLOCK'S RULES, IN ONE PLACE (issue 0080). Both walkers of
# the integration blocks ask this, emit_integration_tsv and emacs_doctor, so
# the manifest and the doctor cannot disagree about a block. The rules: the
# yaml reads; the block is a map; input and output are present and inside the
# bridge's sets; and flags is a list, or absent for none.
#
# For a block it accepts, prints its description, input, output and flags,
# tab-separated, and returns 0. For one it refuses, prints the reason and
# returns 1. A yaml with no integration block prints nothing and returns 2.
# Call it as `x=$(integration_fields ...) || status=$?`: each status is an
# answer, and a plain statement under set -e would end its caller at the
# first that is not 0.
integration_fields() {
  local name="$1" yaml_file="$2"
  local kind desc input output flags

  if ! kind=$(yq eval '.integration | type' "$yaml_file" 2>/dev/null) ||
    [[ -z "$kind" || "$kind" == *$'\n'* ]]; then
    printf '%s.yaml cannot be read: %s\n' "$name" "$(yaml_read_error "$yaml_file")"
    return 1
  fi
  case "$kind" in
    '!!null') return 2 ;;
    '!!map') ;;
    *) echo "integration is $(yaml_type_words "$kind"), not a map" ; return 1 ;;
  esac
  if ! desc=$(yq eval '.description' "$yaml_file" 2>/dev/null) ||
    ! input=$(yq eval '.integration.input' "$yaml_file" 2>/dev/null) ||
    ! output=$(yq eval '.integration.output' "$yaml_file" 2>/dev/null) ||
    ! kind=$(yq eval '.integration.flags | type' "$yaml_file" 2>/dev/null); then
    printf '%s.yaml cannot be read: %s\n' "$name" "$(yaml_read_error "$yaml_file")"
    return 1
  fi
  if [[ "$desc" == "null" ]]; then desc=""; fi

  if [[ -z "$input" || "$input" == "null" ]]; then
    echo "integration.input missing or null"
    return 1
  fi
  case "$input" in
    stdin|file|path|none) ;;
    *) echo "integration.input is $input, not one of stdin, file, path, none" ; return 1 ;;
  esac
  if [[ -z "$output" || "$output" == "null" ]]; then
    echo "integration.output missing or null"
    return 1
  fi
  case "$output" in
    replace|buffer|message|discard) ;;
    *) echo "integration.output is $output, not one of replace, buffer, message, discard" ; return 1 ;;
  esac
  case "$kind" in
    '!!seq')
      if ! flags=$(yq eval '.integration.flags | join(",")' "$yaml_file" 2>/dev/null); then
        echo "integration.flags is a list yq cannot join"
        return 1
      fi
      ;;
    '!!null') flags="" ;;
    *) echo "integration.flags is $(yaml_type_words "$kind"), not a list" ; return 1 ;;
  esac

  printf '%s\t%s\t%s\t%s\n' "$desc" "$input" "$output" "$flags"
}

# Emit a TSV manifest of utilities that declare an `integration:` block.
# Columns (tab-separated): name  description  input  output  flags
# `flags` is a comma-separated list, empty when the block declares none.
# Skips: utilz core, utilities without an integration block, non-symlinks.
# Warns (to stderr) and skips a utility whose block integration_fields
# refuses, naming the reason: a yaml yq cannot read, a block that is not a
# map, an input or output missing or outside the bridge's sets, or flags that
# are not a list.
#
# What is single is the block's RULES: integration_fields holds them, and this
# and emacs_doctor both ask it (Highlander). This TSV is the only contract
# that crosses to an editor: every integration (Emacs, future VSCode / Zed /
# Vim) consumes it directly, and none reads the yamls itself.
emit_integration_tsv() {
  require_yq || return 1

  local name yaml_file fields status

  while IFS= read -r name; do
    yaml_file=$(util_yaml_path "$name")
    if [[ ! -f "$yaml_file" ]]; then continue; fi

    status=0
    fields=$(integration_fields "$name" "$yaml_file") || status=$?
    case $status in
      0) printf '%s\t%s\n' "$name" "$fields" ;;
      2) ;;
      *) warn "$name: $fields; skipping" ;;
    esac
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

  # The block's rules are integration_fields', the manifest's own (issue
  # 0080), so a block this lists as invalid is one the manifest leaves out.
  local name yaml_file fields status
  while IFS= read -r name; do
    yaml_file=$(util_yaml_path "$name")
    if [[ ! -f "$yaml_file" ]]; then continue; fi

    status=0
    fields=$(integration_fields "$name" "$yaml_file") || status=$?
    case $status in
      0) exposed=$((exposed + 1)) ;;
      2) missing+=("$name") ;;
      *) invalid+=("$name ($fields)") ;;
    esac
  done < <(each_utility)

  # NOT BOUND IS NOT BROKEN (issue 0006, hv 2026-08-29). The bridge is opt-in,
  # so a utility that declares no integration: block has not failed at anything
  # -- it has declined something optional. Counting it as an issue made every
  # utility added after ST0007 born red, which is a default nobody chose rather
  # than a rule anyone set, and it matches run_doctor two functions away, where
  # an absent optional dependency is an `info` and never a failure.
  #
  # The list stays, because it is the useful half. Only the exit code goes.
  if [[ ${#missing[@]} -gt 0 ]]; then
    info "${#missing[@]} utility/utilities not bound to the bridge (no integration: block):"
    for name in "${missing[@]}"; do
      echo "    - $name (opt/$name/$name.yaml)"
    done
  fi
  if [[ ${#invalid[@]} -gt 0 ]]; then
    error "${#invalid[@]} utility/utilities with invalid integration values:"
    for name in "${invalid[@]}"; do
      echo "    - $name"
    done
    issues=$((issues + 1))
  fi
  # Gated on `invalid` ALONE, deliberately. This line is the only place the
  # phrase "integration metadata" reaches the output, and bridge.bats asserts
  # on it -- so leaving `missing` in the condition would have kept the test red
  # for a second reason after the first was fixed, which is how a two-part
  # defect gets half-repaired and declared done.
  if [[ ${#invalid[@]} -eq 0 ]]; then
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

  # Expand leading ~ in dest. Shared with install_prefix_configured.
  dest=$(expand_tilde "$dest")

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
  local year
  year=$(date +%Y)

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
  # TWO SPELLINGS OF EACH PATH, BECAUSE THEY HAVE TWO JOBS AND ONLY ONE OF THEM
  # SHIPS. The absolute pair is what the generator WRITES THROUGH and what it
  # prints to the operator; the _rel pair is what goes into README.md, which is
  # in the install's owned set -- so an absolute path there puts the generating
  # machine's home directory inside every published tree. That is exactly what
  # eight older READMEs carried (issue 0010), and the generator was still
  # minting the ninth, so fixing the eight alone would have fixed nothing.
  #
  # These were ONE variable serving both jobs, which is why the leak existed:
  # nothing could be changed for the reader without breaking the writer. The
  # relative form is also the better documentation -- someone reading
  # opt/foo/README.md is already standing in the tree it names.
  local impl_path="$util_dir/$util_name"
  local help_path="$UTILZ_HOME/help/$util_name.md"
  local impl_path_rel="opt/$util_name/$util_name"
  local help_path_rel="help/$util_name.md"

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
  local utilz_floor
  utilz_floor="^$(get_utilz_version | cut -d. -f1).0.0"

  # THE UTILITY'S VERSION GETS ITS OWN FILE, which is its one home. The yaml
  # points at it with version_file rather than restating it: metadata.tmpl used
  # to carry a literal 1.0.0, so every generated utility was born with a second
  # copy that was correct exactly until its first release.
  info "Generating VERSION..."
  echo "1.0.0" > "$util_dir/VERSION"

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
    -e "s|{{IMPL_PATH}}|$impl_path_rel|g" \
    -e "s|{{HELP_PATH}}|$help_path_rel|g" \
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
  # Subshell so the cd is scoped and a failure cannot leave the caller in
  # bin/ -- the old form used a bare `cd` plus `cd -`, which silently
  # continued into `ln` from the wrong directory if bin/ was missing.
  ( cd "$UTILZ_HOME/bin" && ln -s utilz "$util_name" ) || {
    error "Failed to create symlink for $util_name in $UTILZ_HOME/bin"
    return 1
  }

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
