#!/usr/bin/env bash
# install.sh - the install/upgrade library for the utilz dispatcher
#
# Sourced ONLY from the install / upgrade / link branches of bin/utilz, never
# unconditionally. bin/utilz:58 sources common.sh for every one of the fifteen
# utilities on every invocation; folding this in would roughly double what
# cleanz parses in order to do something cleanz will never call. See
# intent/st/ST0014/design.md D1.
#
# Everything here is a function of a TREE PATH passed in. Nothing in this file
# may reach for state describing the tree it is running from, because every
# function operates on a tree that is not that one.
#
# Depends on common.sh for error() and get_util_metadata(). Nothing else.
# The manifest filename is UTILZ_MANIFEST_NAME and it lives in common.sh, which
# this file requires anyway. It is not install machinery: it is the
# discriminator between an install tree and a source tree, and the RUNTIME asks
# that question too -- show_version for AC12, run_tests for AC13, the prez shim
# for AC09. An alias here would be a second NAME for the one thing this thread
# cannot afford two answers about.

# THE RUNTIME SET -- what a publish copies and the manifest names -- is
# common.sh's utilz_runtime_set, with its roots, exclusions and build products
# (dev, opt, brew contract T1, issue 0105). It moved there because doctor and
# the version line read it too, on the dispatcher's own path, and one function
# is the whole of the rule that install and doctor agree on it.

# ============================================================================
# PURE: facts about a tree
# ============================================================================

# A file's sha256 is common.sh's sha256_of, shared with stampz (issue 0083).

# Echo the opt prefix, tilde-expanded, or return 1, by name, when it is unset.
#
# UTILZ_INSTALL_PREFIX, SET BY THE SLEEVE (dev, opt, brew contract T1, issue
# 0105): Molt's sleeve config writes it into every shell (Molt ST0008 WP05),
# as it does MOLT_INSTALL_PREFIX and DEVBIN_INSTALL_PREFIX. Utilz reads only
# the variable. Until 0105 it was
# install.prefix in the committed opt/utilz/utilz.yaml, which every Homebrew
# keg then shipped: one machine's path, read on every machine, a default in
# all but name. There is still NO built-in default (ST0014 AC05): unset is
# refused rather than guessed, because a publish to the wrong place looks
# exactly like a publish to the right one.
#
# A caller that forgets to check an empty return proceeds and writes to /bin;
# a caller that forgets to check rc 1 is killed by set -e at the assignment.
# Only one of those is silent.
install_prefix_configured() {
  local raw="${UTILZ_INSTALL_PREFIX:-}"

  if [[ -z "$raw" ]]; then
    error "UTILZ_INSTALL_PREFIX is not set, so there is no opt prefix"
    echo "  It names where 'utilz install' publishes this checkout, and Molt's" >&2
    echo "  sleeve config sets it in every shell. --prefix DIR names one for a" >&2
    echo "  single run. There is no default." >&2
    return 1
  fi

  # Shared with emacs_install --dest (D10): one expander, one home. A value
  # written in a config file is not always expanded by a shell, and an
  # unexpanded ~ creates a directory literally named ~ under the cwd, which
  # every later command then finds exactly where it looked.
  raw=$(expand_tilde "$raw")

  printf '%s\n' "$raw"
}

# Echo which kind of tree <dir> is: install, source, foreign, or other.
#
#   install   a manifest Utilz wrote, in either form (contract T3)
#   source    a tree that could be published from, with no manifest
#   foreign   a manifest.sha256 that Utilz did not write
#   other     anything else, eg an empty or absent directory
#
# The manifest is tested FIRST because an install tree also carries bin/utilz
# and opt/utilz/utilz.yaml -- the source test alone would call every install a
# source tree. A manifest of someone else's is its own answer, so a publish
# never takes a file of that name for its own and overwrites what it guards
# (contract T2: only a prefix whose manifest says this tool wrote it).
install_tree_kind() {
  local dir="$1"
  local manifest="$dir/$UTILZ_MANIFEST_NAME"

  # utilz_tree is the one function that names a tree (contract T4): an opt or
  # brew tree, in either manifest form, is an install, and a manifest it
  # cannot name is someone else's.
  if [[ -f "$manifest" ]]; then
    case "$(utilz_tree "$dir")" in
      opt* | brew*) printf 'install\n' ;;
      *) printf 'foreign\n' ;;
    esac
    return 0
  fi

  # AC03's predicate is a property of the TARGET alone, derived rather than
  # named: a tree that could be published FROM but carries no manifest is a
  # source checkout. Comparing source to destination was devbin's guard and it
  # did not hold, because the harm has nothing to do with the two being equal.
  if [[ -f "$dir/bin/utilz" && -f "$dir/opt/utilz/utilz.yaml" ]]; then
    printf 'source\n'
    return 0
  fi

  printf 'other\n'
}

# Echo the short commit a tree is at, or `none` when the tree is not a git
# repository of its own (issue 0044).
#
# THE SAME TEST utilz_runtime_state MAKES, SO THE TWO HALVES OF THE ANNOUNCE
# CANNOT DISAGREE. A bare `git -C <tree> rev-parse` walks up to the nearest
# enclosing repository and answers with its HEAD: from a Homebrew keg, which
# has no .git, that was Homebrew's own commit, printed beside `unknown`.
install_tree_commit() {
  local tree="$1"
  local commit

  if utilz_is_git_toplevel "$tree" &&
    commit=$(git -C "$tree" rev-parse --short HEAD 2>/dev/null); then
    printf '%s\n' "$commit"
  else
    printf 'none\n'
  fi
}

# ============================================================================
# PURE: the manifest (dev, opt, brew contract T3, issue 0105)
# ============================================================================
#
#   # tool: utilz
#   # version: <VERSION>
#   # source_commit: <the full sha>
#   # managed_by: utilz | brew
#   # source_tree: <the dev tree's absolute path>
#   # ci_state: <CI's verdict on the commit>
#   # ci_detail: <its run id, or the reason there is none>
#   <sha256>  <path>
#   ...
#
# The header keys are common.sh's UTILZ_MANIFEST_HEADER_KEYS. The body is one
# line per runtime path in `shasum -a 256 -c` form, LC_ALL=C sorted, so the
# manifest reads back with the system's own tool from the install root.
#
# THE DISPATCHER LINKS ARE IN THE BODY, HASHED THROUGH TO bin/utilz, as shasum
# reads a link. That proves each one is there and resolves to the dispatcher's
# bytes; what the body cannot see is a link retargeted from `utilz` to another
# file, which ST0014 AC06 caught with a link row of its own. The rule that
# replaces the row is structural, and install_manifest_check holds it: every
# link git names in the runtime set is `bin/<name> -> utilz`, so every link the
# body names under bin/ must still be one, with that target string.

# Echo one body line per runtime path: "<sha256>  <path>", in runtime-set order.
install_manifest_rows() {
  local tree="$1"
  local paths path sum

  paths=$(utilz_runtime_set "$tree") || return 1

  while IFS= read -r path; do
    [[ -n "$path" ]] || continue

    if [[ ! -e "$tree/$path" ]]; then
      error "runtime path is missing from $tree: $path"
      return 1
    fi

    # The structural rule the checker holds (above), held at the write too, so
    # no publish records a tree its own doctor would call drifted.
    if [[ "$path" == bin/* && "$path" != "bin/utilz" && "$path" != */*/* ]] &&
      [[ ! -L "$tree/$path" || "$(readlink "$tree/$path")" != "utilz" ]]; then
      error "$path is not a link to the dispatcher (bin/<name> -> utilz): $tree"
      return 1
    fi

    sum=$(sha256_of "$tree/$path") || {
      error "could not checksum: $path"
      return 1
    }
    printf '%s  %s\n' "$sum" "$path"
  done <<< "$paths"
}

# Echo how many lines of <manifest>'s body name a path.
install_manifest_path_count() {
  local manifest="$1"

  if [[ ! -r "$manifest" ]]; then
    error "cannot read the manifest at $manifest"
    return 1
  fi

  grep -c -v -E '^(#|$)' "$manifest" || true
}

# Write the manifest for a SOURCE tree to <out>:
#   install_manifest_write <tree> <out> [<ci_state> [<rows> [<manager>]]]
# <ci_state> is CI's verdict on the commit as "<state><TAB><detail>", the
# form install_ci_state gives. <manager> is who owns the published tree,
# `utilz` unless the formula's publish says `brew` (ST0019 D4).
install_manifest_write() {
  local tree="$1"
  local out="$2"
  local ci_state="${3-}"
  local manager="${5:-utilz}"
  local version commit rows

  if [[ ! -f "$tree/VERSION" ]]; then
    error "no VERSION file in $tree"
    return 1
  fi

  version=$(cat "$tree/VERSION") || return 1

  commit=$(git -C "$tree" rev-parse HEAD 2>/dev/null) || {
    error "could not resolve HEAD in $tree"
    return 1
  }

  if [[ $# -ge 4 ]]; then
    rows="$4"
  else
    rows=$(install_manifest_rows "$tree") || return 1
  fi

  # NO generated-at timestamp. A timestamp makes two manifests of identical
  # bytes compare unequal, which turns the one instrument that reports drift
  # into a thing that always reports drift.
  # source_tree is what makes `utilz use dev` turnkey (D13): an opt tree then
  # holds the address of the dev tree, so that direction needs no path typed or
  # a second config key invented. Made absolute, because a relative spelling
  # names the tree only from where the publish ran. Resolved LOGICALLY, never
  # with -P (issue 0039): the row is an address, compared as a string with link
  # roots that _install_link_state resolves logically, as the dispatcher
  # resolves its own home. utilz_is_git_toplevel's -P is the one exception,
  # because git reports its toplevel physically.
  local source_tree
  source_tree=$(cd "$tree" 2>/dev/null && pwd) || {
    error "could not resolve $tree to an absolute path"
    return 1
  }

  # CI's verdict is asked by the coordination and handed in (issue 0016): a
  # network call is not a fact about a tree, and a writer that made one would
  # stop being a function of its inputs. A manifest written without an answer
  # -- by a fixture, never by a publish -- records unknown, and says why.
  if [[ -z "$ci_state" ]]; then
    ci_state=$'unknown\tnot asked: this manifest was not written by a publish'
  fi

  # One value per header key, IN THE KEYS' ORDER. The count is checked, so a
  # key added to UTILZ_MANIFEST_HEADER_KEYS without a value here fails the
  # write rather than recording a key with nothing in it.
  local header_values=("utilz" "$version" "$commit" "$manager" "$source_tree"
    "${ci_state%%$'\t'*}" "${ci_state#*$'\t'}")
  if [[ ${#header_values[@]} -ne ${#UTILZ_MANIFEST_HEADER_KEYS[@]} ]]; then
    error "the manifest has ${#UTILZ_MANIFEST_HEADER_KEYS[@]} header keys but ${#header_values[@]} values for them"
    return 1
  fi

  local i
  {
    for i in "${!UTILZ_MANIFEST_HEADER_KEYS[@]}"; do
      printf '# %s: %s\n' "${UTILZ_MANIFEST_HEADER_KEYS[$i]}" "${header_values[$i]}"
    done
    printf '%s\n' "$rows"
  } > "$out"
}

# Echo one row per runtime path whose on-disk state differs from its manifest
# line, TAB-separated as "<reason><TAB><path>". Silence means the install
# matches the manifest it was written with.
#
#   missing      the path is not there at all
#   modified     a file whose sha256 differs from its line
#   not-a-link   a dispatcher link under bin/ that arrived as a regular file
#   retargeted   a dispatcher link whose target is not `utilz`
#
# rc 0 no drift, rc 1 drift reported, rc 2 the manifest could not be read,
# rc 3 the manifest is Utilz's in the old form (contract T3), read for nothing
# more. Four answers, four codes, for the same reason utilz_runtime_state has
# three values: "matches" and "cannot tell" must never render as the same
# answer, and "cannot tell" has two remedies.
#
# THE ROLL-CALL IS REQUIRED, NOT MERELY CONVENIENT. THIS FUNCTION MUST NEVER
# WALK THE TREE (AC18). It reads the manifest and looks at nothing else, so a
# file the manifest does not name is not drift and is not reported.
#
# The convenient reason is that an install has no git and therefore nothing to
# enumerate from. Read alone that sounds like a LIMITATION, and a limitation
# invites a fix: the next reader sees a checker that cannot detect files it
# does not know about, calls it a completeness gap, adds a find over the
# prefix, and every existing check still passes.
#
# The reason that makes it load-bearing: pdf2md and xtrct each exec
# "$LIB_DIR/.venv/bin/python3" after ensure_venv (common.sh:241), building a
# venv INSIDE the install on first use, gitignored so git ls-files never named
# it. Measured 7 Sep: 1776 files under opt/pdf2md/lib/.venv and 2407 under
# opt/xtrct/lib/.venv. A tree-walking check reports 4183 drift rows that
# nobody caused, the first time anyone runs either utility.
#
# This is AC13's shape with AC13's remedy unavailable. utilz test is refused
# from an install because refusing costs nothing; pdf2md and xtrct running IS
# the install working (AC01), so they cannot be refused. The check has to tell
# unowned-and-expected from owned-and-changed, and reading the roll-call is how.
#
# The manifest is the one enumeration at one remove, not a second one.
install_manifest_check() {
  local root="$1"
  local manifest="$root/$UTILZ_MANIFEST_NAME"
  local line sum path actual
  local drift=0

  if [[ ! -f "$manifest" ]]; then
    error "no manifest at $root/$UTILZ_MANIFEST_NAME"
    return 2
  fi

  if ! utilz_manifest_is_current "$manifest"; then
    if utilz_manifest_is_old "$manifest"; then
      return 3
    fi
    error "$manifest is not a manifest Utilz wrote"
    return 2
  fi

  while IFS= read -r line; do
    # The header is not a path, and its keys have one home (issue 0016).
    case "$line" in
      "" | "#"*) continue ;;
    esac

    # "<sha256>  <path>": a line in any other shape is a manifest this code
    # cannot vouch for, and skipping it would report "no drift" over a file
    # nothing checked.
    sum="${line%%  *}"
    path="${line#*  }"
    if [[ ! "$sum" =~ ^[0-9a-f]{64}$ || -z "$path" || "$path" == "$line" ]]; then
      error "unreadable manifest line in $manifest: $line"
      return 2
    fi

    # The dispatcher links, structurally (above): a link git names in the
    # runtime set is bin/<name> -> utilz, and nothing else is a link.
    if [[ "$path" == bin/* && "$path" != "bin/utilz" && "$path" != */*/* ]]; then
      if [[ -e "$root/$path" && ! -L "$root/$path" ]]; then
        # cp dereferences a symlink, so an install that took this path still
        # WORKS: N copies of the dispatcher, nothing failing, and nothing
        # saying anything. It is its own reason rather than 'modified'.
        printf 'not-a-link\t%s\n' "$path"
        drift=1
        continue
      fi
      if [[ -L "$root/$path" && "$(readlink "$root/$path")" != "utilz" ]]; then
        printf 'retargeted\t%s\n' "$path"
        drift=1
        continue
      fi
    fi

    if [[ ! -e "$root/$path" ]]; then
      printf 'missing\t%s\n' "$path"
      drift=1
      continue
    fi

    actual=$(sha256_of "$root/$path") || return 2

    if [[ "$actual" != "$sum" ]]; then
      printf 'modified\t%s\n' "$path"
      drift=1
    fi
  done < "$manifest"

  return "$drift"
}

# ============================================================================
# IMPURE: the coordination
# ============================================================================

# Copy the owned set of <src> into <dst>, creating parents as it goes.
# <skip> is an optional newline-separated list of owned paths to leave alone.
# upgrade uses it for files edited in place (AC08); install never passes one.
install_copy_owned() {
  local src="$1"
  local dst="$2"
  local skip="${3:-}"
  local paths path target

  paths=$(utilz_runtime_set "$src") || return 1

  mkdir -p "$dst" || {
    error "could not create $dst"
    return 1
  }

  while IFS= read -r path; do
    [[ -n "$path" ]] || continue

    if [[ -n "$skip" ]] && printf '%s\n' "$skip" | grep -qxF "$path"; then
      continue
    fi

    mkdir -p "$dst/$(dirname "$path")" || {
      error "could not create the directory for $path under $dst"
      return 1
    }

    if [[ -L "$src/$path" ]]; then
      # readlink + ln -s, never cp. cp DEREFERENCES a symlink, which produces
      # fifteen 8.5KB copies of the dispatcher in a tree that still looks
      # right, so nothing fails and nothing says anything (D3). Making the
      # target string the thing this code handles is what makes AC06
      # checkable rather than incidental.
      target=$(readlink "$src/$path") || {
        error "could not read link target: $path"
        return 1
      }
      rm -f "$dst/$path"
      ln -s "$target" "$dst/$path" || {
        error "could not create link: $path"
        return 1
      }
    elif [[ -f "$src/$path" ]]; then
      cp -p "$src/$path" "$dst/$path" || {
        error "could not copy: $path"
        return 1
      }
    else
      error "owned path is missing from $src: $path"
      return 1
    fi
  done <<< "$paths"
}

# Build prez's binaries in <src>'s crate, if it has one. A no-op otherwise.
install_build_prez() {
  local src="$1"
  local crate="$src/opt/prez/crate"

  [[ -f "$crate/Cargo.toml" ]] || return 0

  if ! command -v cargo >/dev/null 2>&1; then
    error "cargo is required to publish: the install SHIPS prez's built binaries"
    echo "  AC09 -- the install-tree shim refuses to build, so the binaries have to" >&2
    echo "  exist before anyone runs them. Install Rust from https://rustup.rs." >&2
    return 1
  fi

  echo "build:  cargo build --release --workspace (opt/prez/crate)"

  # CARGO_TARGET_DIR is unset for this build so the binaries land where the
  # owned set names them. The shim honours the variable deliberately, but a
  # publish run by someone with it exported would send the output somewhere
  # the copy never looks, and then ship the previous binaries or none at all.
  #
  # --workspace, because the crate root is prez's own package and the workspace
  # declares no default-members: without it this builds prez and what prez
  # links, and never showreel (issue 0024). The shim's build has carried it
  # since ST0017's WP-05 for the same reason; this was the copy that did not.
  (
    unset CARGO_TARGET_DIR
    cd "$crate" && cargo build --release --workspace --quiet
  ) || {
    error "cargo build failed in $crate"
    return 1
  }
}

# THE CI QUERY (issue 0016): the command it runs, the workflow it asks about,
# and how long a publish waits for the answer. Assigned here rather than read
# from the environment, so only code that has sourced this file -- a test --
# can point them anywhere else.
INSTALL_GH="gh"
INSTALL_CI_WORKFLOW="tests.yml"
INSTALL_CI_DEADLINE=10

# Run <cmd...> with stdout to <out> and stderr to <err>, and kill it if it is
# still running after <seconds>. Returns the command's own status, or 124 --
# timeout(1)'s code -- when the deadline killed it. macOS ships no timeout(1),
# which is why this exists, and it has to run on bash 3.2.
install_run_bounded() {
  local seconds="$1" out="$2" err="$3"
  shift 3
  local fired="$err.deadline" pid watchdog rc=0

  rm -f "$fired"
  "$@" > "$out" 2> "$err" &
  pid=$!
  # THE WATCHDOG'S OUTPUT GOES NOWHERE: it writes none, and it must hold none
  # of its caller's. install_ci_state is read through $(...), which waits for
  # every holder of its pipe, and a TERM landing between `sleep &` and
  # `sleeper=$!` would otherwise leave that sleep holding it until the
  # deadline (issue 0032).
  (
    # Killed early when the command finishes first, and the trap takes the
    # sleep with it, so no stray sleep outlives the publish.
    sleeper=""
    trap 'kill "$sleeper" 2>/dev/null; exit 0' TERM
    sleep "$seconds" &
    sleeper=$!
    wait "$sleeper"
    if kill -0 "$pid" 2>/dev/null; then
      : > "$fired"
      # Its children before it -- a wrapper's sleep, gh's git -- because once
      # the command is gone they belong to init and nothing here can name
      # them. One level: a grandchild is its own parent's to reap. Tolerated
      # when it finds none, which is the usual case.
      pkill -TERM -P "$pid" 2>/dev/null || true
      kill -TERM "$pid" 2>/dev/null
    fi
  ) > /dev/null 2>&1 &
  watchdog=$!

  # stderr is the shell's own "Terminated" notice for a command the deadline
  # killed, which would reach the publisher naming a line of this file. The
  # marker file below is the record of that, and the status still arrives.
  wait "$pid" 2>/dev/null || rc=$?
  # Tolerated: when the deadline fired, the watchdog has already exited, and
  # the marker file -- not this kill or this wait -- is what records that.
  kill -TERM "$watchdog" 2>/dev/null || true
  wait "$watchdog" 2>/dev/null || true

  if [[ -f "$fired" ]]; then
    rm -f "$fired"
    return 124
  fi
  return "$rc"
}

# Echo CI's verdict on <commit> as "<state><TAB><detail>" (issue 0016), asked
# of the workflow's own record with gh, run in <tree> so gh finds the repo
# from the tree's remotes. It never fails and never guesses: an answer it
# cannot get, or cannot read, is `unknown` with the reason, because a failed
# read recorded as success is a pass nobody measured.
#
#   <conclusion>  CI's verdict on a completed run, eg success     the run id
#   pending       a run that has not concluded                    the run id
#   none          no run for this commit, eg it was never pushed  no run
#   unknown       gh absent, refusing, silent or unreadable       the reason
#
# EVERY RUN ON THE COMMIT IS READ, AND THE WORST OF THEM IS THE ANSWER (issue
# 0052). A release commit carries two runs since the macOS legs moved to
# release tags (0046) -- the branch push, and the tag push that runs them --
# and GitHub documents no order between the two push events of one `git push`,
# so asking for one run is asking for a coin toss. Worst first: a row that
# cannot be read, a conclusion that is not success, a run still going, a
# completed run with no conclusion, success. That is the same rule tools/ci-state
# states downstream, applied to the population instead of to one row.
# Name what failed INSIDE a run, as "<note>" or nothing (issue 0062).
#
# WHY A SECOND CALL EXISTS AT ALL. install_ci_state reads the RUN's conclusion,
# and a run concludes `failure` for two reasons a release cares about very
# differently: a job ran and went red, or no job ran at all -- a billing
# refusal, an unavailable runner, an expired or cancelled queue. At the run
# level those are the same word. Measured at devbin: four runs concluded
# `failure` with every test job green and only the summary refused. The reader
# was correct and unactionable, and it is read by a human mid-cut deciding
# between "fix the code" and "re-run CI", which are opposite moves.
#
# ONLY ON THE NOT-SUCCESS PATH, so a green release costs exactly one gh call
# as before. And this ENRICHES rather than decides: a note it cannot get is no
# note, never a changed verdict, because install_ci_state's contract is that it
# never guesses and the run id is already in the detail for a human to follow.
install_ci_jobs() {
  local tree="$1" run_id="$2"
  local scratch rc=0 rows line conclusion name total=0 failed="" count=0

  command -v "$INSTALL_GH" > /dev/null 2>&1 || return 0
  [[ -n "$run_id" ]] || return 0
  scratch=$(mktemp -d "${TMPDIR:-/tmp}/utilz-cijobs.XXXXXX") || return 0
  : > "$scratch/out"
  : > "$scratch/err"

  (
    cd "$tree" || exit 125
    install_run_bounded "$INSTALL_CI_DEADLINE" "$scratch/out" "$scratch/err" \
      "$INSTALL_GH" run view "$run_id" --json jobs \
      --jq '.jobs[] | "\(.conclusion)|\(.name)"'
  ) || rc=$?

  rows=$(cat "$scratch/out")
  rm -rf "$scratch"

  # A read that did not work adds nothing. The verdict and the run id stand.
  [[ "$rc" -eq 0 ]] || return 0

  # A here-string, never a pipe, for the reason install_ci_state gives: a
  # piped loop's counters die in its subshell.
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    total=$((total + 1))
    IFS='|' read -r conclusion name <<< "$line"
    [[ "$conclusion" != "null" ]] || conclusion=""
    case "$conclusion" in
      success | skipped | neutral) continue ;;
    esac
    count=$((count + 1))
    # Three names is enough to act on; more is a wall of text in a manifest.
    if [[ "$count" -le 3 ]]; then
      [[ -z "$failed" ]] && failed="$name" || failed="$failed, $name"
    fi
  done <<< "$rows"

  if [[ "$total" -eq 0 ]]; then
    # THE SIGNATURE OF AN INFRASTRUCTURE REFUSAL: the run concluded, and
    # nothing in it ran. Nothing was tested, so nothing about the code is known.
    printf 'no job ran, so nothing was tested'
    return 0
  fi
  if [[ "$count" -eq 0 ]]; then
    printf 'no job failed, so the run was refused rather than tested'
    return 0
  fi
  [[ "$count" -le 3 ]] || failed="$failed and $((count - 3)) more"
  printf 'failed: %s' "$failed"
}

install_ci_state() {
  local tree="$1" commit="$2"
  local scratch rc=0 answers reason line status conclusion run_id
  local rank=0 verdict=success detail="" total=0 newest=""

  if ! command -v "$INSTALL_GH" > /dev/null 2>&1; then
    printf 'unknown\t%s is not installed\n' "$INSTALL_GH"
    return 0
  fi
  if ! scratch=$(mktemp -d "${TMPDIR:-/tmp}/utilz-ci.XXXXXX"); then
    printf 'unknown\tcould not make a scratch directory for the query\n'
    return 0
  fi
  : > "$scratch/out"
  : > "$scratch/err"

  (
    cd "$tree" || exit 125
    install_run_bounded "$INSTALL_CI_DEADLINE" "$scratch/out" "$scratch/err" \
      "$INSTALL_GH" run list --commit "$commit" --workflow "$INSTALL_CI_WORKFLOW" \
      --json status,conclusion,databaseId --limit 20 \
      --jq '.[] | "\(.status)|\(.conclusion)|\(.databaseId)"'
  ) || rc=$?

  answers=$(cat "$scratch/out")
  reason=$(head -n 1 "$scratch/err")
  rm -rf "$scratch"

  case "$rc" in
    0) ;;
    124)
      printf 'unknown\t%s did not answer within %ss\n' "$INSTALL_GH" "$INSTALL_CI_DEADLINE"
      return 0
      ;;
    125)
      printf 'unknown\tcould not enter %s to ask\n' "$tree"
      return 0
      ;;
    *)
      printf 'unknown\t%s\n' "${reason:-$INSTALL_GH exited $rc and said nothing}"
      return 0
      ;;
  esac

  if [[ -z "$answers" ]]; then
    printf 'none\tno run\n'
    return 0
  fi

  # A here-string, never a pipe: a piped loop runs in a subshell and its
  # verdict dies with it, which would leave every commit reading success.
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    total=$((total + 1))
    IFS='|' read -r status conclusion run_id <<< "$line"
    # gh renders a JSON null through jq as the STRING "null", not as an empty
    # field (measured: `"\(.conclusion)"` on a null gives `completed|null|9`),
    # so a completed run with no conclusion arrives SPELLED. Without this the
    # rank below reads "null" as a conclusion that is not success and answers
    # with it as a verdict word, and the branch written for that case cannot be
    # reached at all (cc's read of issue 0052). It fails safe either way; it
    # just says something untrue on the way.
    [[ "$conclusion" != "null" ]] || conclusion=""
    # gh lists newest first, so the first id read is the newest, which is what
    # an all-green answer names.
    [[ -n "$newest" ]] || newest="$run_id"

    local row_rank=0 row_verdict="success" row_detail="$run_id"
    if [[ -z "$status" || -z "$run_id" ]]; then
      row_rank=4
      row_verdict="unknown"
      row_detail="could not read the answer from $INSTALL_GH: $line"
    elif [[ "$conclusion" != "success" && "$status" == "completed" && -n "$conclusion" ]]; then
      row_rank=3
      row_verdict="$conclusion"
    elif [[ "$status" != "completed" ]]; then
      row_rank=2
      row_verdict="pending"
    elif [[ -z "$conclusion" ]]; then
      row_rank=1
      row_verdict="unknown"
      row_detail="a completed run with no conclusion: $run_id"
    fi

    if [[ "$row_rank" -gt "$rank" ]]; then
      rank="$row_rank"
      verdict="$row_verdict"
      detail="$row_detail"
    fi
  done <<< "$answers"

  if [[ "$total" -eq 0 ]]; then
    printf 'none\tno run\n'
    return 0
  fi
  [[ -n "$detail" ]] || detail="$newest"
  # A CONCLUSION THAT IS NOT SUCCESS IS THE ONE ANSWER A HUMAN MUST ACT ON,
  # so it is the one that gets a second question asked of it (issue 0062).
  # rank 3 is that case, and at rank 3 the detail is the run id alone.
  if [[ "$rank" -eq 3 ]]; then
    local jobs_note
    jobs_note=$(install_ci_jobs "$tree" "$detail")
    [[ -z "$jobs_note" ]] || detail="$detail ($jobs_note)"
  fi
  # The count is part of the answer only when there was more than one run to
  # read, so a single-run commit reads exactly as it always has.
  [[ "$total" -eq 1 ]] || detail="$detail of $total runs on this commit"
  printf '%s\t%s\n' "$verdict" "$detail"
}

# Refuse, by name, when <dir> is a Homebrew keg (ST0019 D4). Returns 0 for any
# other tree, 1 after saying why for a keg or a manifest it cannot read.
#
# ONE REFUSAL FOR EVERY VERB THAT WRITES OR LINKS A TREE. brew checksums what
# it installed and removes a versioned keg at the next `brew upgrade`, so a
# rewrite breaks brew's record and a PATH link into the keg breaks later. The
# verb is not named: install and `use opt` both reach it, and one message that
# is true for both is better than two that each name one. `use brew` points no
# link into the keg: it removes the links, so brew's own answer (T5).
install_refuse_keg() {
  local dir="$1"
  local manager

  manager=$(install_tree_manager "$dir") || return 1
  [[ "$manager" == "brew" ]] || return 0

  error "$dir is a Homebrew keg: brew owns it"
  echo "  Utilz will not write to a keg or point PATH into one. Upgrade it" >&2
  echo "  with 'brew upgrade utilz'; brew links its own commands onto PATH." >&2
  return 1
}

# Announce what is about to happen, on stdout, BEFORE anything is written.
#
# A discriminator that is merely correct is not enough (AC10): a misdetection
# has to arrive in the output rather than be discovered later in the
# filesystem. This is called before the refusals as well as before the writes,
# so a run that is about to be refused still says what it thought it was doing.
install_announce() {
  local mode="$1"
  local src="$2"
  local state="$3"
  local commit="$4"
  local dst="$5"
  local kind="$6"

  printf 'mode:   %s\n' "$mode"
  printf 'source: %s (%s, %s)\n' "$src" "$state" "$commit"
  printf 'target: %s (%s)\n' "$dst" "$kind"
}

install_usage_install() {
  cat <<'USAGE'
Usage: utilz install [--prefix DIR] [--force] [--managed-by brew]

Publish a runnable install of this Utilz checkout.

  --prefix DIR        Publish here instead of $UTILZ_INSTALL_PREFIX
  --force             Republish over an existing install (the one republish)
  --managed-by brew   Record that Homebrew owns the tree (the formula's publish)

It runs only in a dev checkout. The checkout's runtime set must be CLEAN: the
manifest records the commit the bytes came from, and that claim holds only
when none of them is uncommitted. No flag overrides it, --force included.
USAGE
}

# `utilz install` -- publish a runnable install to the prefix.
#
# Facts first, announcement second, refusals third, writes last. Everything
# this reads is a pure function of a tree path (above); everything it decides
# is here (IN-AG-PFIC-001).
install_verb_install() {
  local prefix=""
  local force=0
  local manager="utilz"
  local src="$UTILZ_HOME"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --prefix)
        if [[ $# -lt 2 ]]; then
          error "--prefix requires a DIR argument"
          return 2
        fi
        prefix=$(expand_tilde "$2")
        shift 2
        ;;
      --force)
        force=1
        shift
        ;;
      --managed-by)
        # brew is the one manager besides utilz itself, and only the formula
        # passes it (ST0019 D4). Any other word is refused rather than
        # recorded, or the manifest would carry an owner nothing checks for.
        if [[ $# -lt 2 || ("$2" != "brew" && "$2" != "utilz") ]]; then
          error "--managed-by takes brew or utilz"
          return 2
        fi
        manager="$2"
        shift 2
        ;;
      -h | --help)
        install_usage_install
        return 0
        ;;
      *)
        error "Unknown option: $1"
        install_usage_install >&2
        return 2
        ;;
    esac
  done

  if [[ -z "$prefix" ]]; then
    prefix=$(install_prefix_configured) || return 1
  fi

  local state kind commit
  state=$(utilz_runtime_state "$src")
  kind=$(install_tree_kind "$prefix")
  commit=$(install_tree_commit "$src")

  install_announce "install" "$src" "$state" "$commit" "$prefix" "$kind"

  # A keg at either end, before the rest: from a keg every later refusal would
  # give advice brew's tree cannot take, and onto one --force would overwrite
  # what brew checksums (ST0019 D4).
  install_refuse_keg "$src" || return 1
  install_refuse_keg "$prefix" || return 1

  # ONLY FROM A DEV TREE, BY NAME (contract T2, issue 0105). An opt install is
  # no git repository, so the provenance refusal below caught it too, but by a
  # reason that does not name the rule.
  if [[ "$(install_tree_kind "$src")" == "install" ]]; then
    error "utilz install runs only in a dev checkout, and this is an install: $src"
    echo "  Publish from the dev checkout it came from, with 'utilz install" >&2
    echo "  --force' there." >&2
    return 1
  fi

  case "$state" in
    dirty)
      error "the runtime set is dirty: $src"
      echo "  An install cut from a dirty tree launders the bytes through one" >&2
      echo "  more hop and gives them the look of provenance. Devbin measured" >&2
      echo "  five of thirteen estates running bytes that matched no commit." >&2
      echo "  Commit or stash first. There is no flag for this one." >&2
      return 1
      ;;
    unknown)
      error "cannot establish provenance: $src is not a git repository"
      echo "  The manifest records the commit the bytes came from and there is" >&2
      echo "  none to record. \"No changes\" and \"cannot tell\" are different" >&2
      echo "  answers and this is the second one." >&2
      return 1
      ;;
  esac

  case "$kind" in
    source)
      error "target is a Utilz source tree: $prefix"
      echo "  Publishing over a checkout would destroy work the manifest does" >&2
      echo "  not know about. This is a property of the TARGET, not of whether" >&2
      echo "  it happens to equal the source." >&2
      return 1
      ;;
    foreign)
      error "$prefix holds a $UTILZ_MANIFEST_NAME that Utilz did not write"
      echo "  A republish replaces only a prefix whose manifest says Utilz wrote" >&2
      echo "  it (contract T2). Choose another prefix, or clear this one first." >&2
      return 1
      ;;
    install)
      if [[ $force -eq 0 ]]; then
        error "an install already exists at $prefix"
        echo "  Republish over it with 'utilz install --force'. An install in the" >&2
        echo "  old manifest form is Utilz's too, and --force republishes it." >&2
        return 1
      fi
      ;;
  esac

  install_build_prez "$src" || return 1
  # The body is read before anything is copied, so a runtime set its own doctor
  # would refuse (a bin/ entry that is not a link to the dispatcher) stops the
  # publish with the prefix untouched.
  local rows
  rows=$(install_manifest_rows "$src") || return 1
  install_copy_owned "$src" "$prefix" || return 1
  # CI's verdict on the commit being published (issue 0016), asked here, at the
  # coordination, and handed to the writer. Recorded, never enforced: no
  # answer refuses the publish.
  local ci_state
  ci_state=$(install_ci_state "$src" "$(git -C "$src" rev-parse HEAD)")
  install_manifest_write "$src" "$prefix/$UTILZ_MANIFEST_NAME" "$ci_state" "$rows" "$manager" || return 1

  local count
  count=$(install_manifest_path_count "$prefix/$UTILZ_MANIFEST_NAME") || return 1
  success "installed $(cat "$src/VERSION") ($commit) at $prefix -- $count paths"
}

install_usage_upgrade() {
  cat <<'USAGE'
Usage: utilz upgrade

Upgrade the tree this utilz runs from, as that tree is upgraded:

  dev    git pull --ff-only, then build prez and showreel
  opt    nothing: opt is republished from its dev checkout with
         'utilz install --force', and this says when dev is ahead
  brew   brew update, then HOMEBREW_NO_AUTO_UPDATE=1 brew upgrade utilz,
         when brew says it is outdated
USAGE
}

# `utilz upgrade` -- UPGRADE BY TREE (dev, opt, brew contract T6, issue 0105).
#
# It never publishes: `install --force` is the one republish (T2). What it does
# is the tree's own upgrade, asked of utilz_tree, so the one verb is right in
# every tree and nobody has to remember which tree they are in.
install_verb_upgrade() {
  case "${1:-}" in
    "") ;;
    -h | --help)
      install_usage_upgrade
      return 0
      ;;
    *)
      error "utilz upgrade takes no arguments, and was given '$*'"
      install_usage_upgrade >&2
      return 2
      ;;
  esac

  local tree
  tree=$(utilz_tree)

  case "$tree" in
    dev)
      _install_upgrade_dev
      ;;
    opt)
      _install_upgrade_opt
      ;;
    brew*)
      # An old keg's remedy is this very upgrade (T3 amendment).
      _install_upgrade_brew
      ;;
    "opt old")
      error "this opt install has an old manifest: $UTILZ_HOME"
      echo "  Republish it from the dev checkout with 'utilz install --force'." >&2
      return 2
      ;;
    *)
      error "$UTILZ_HOME is no tree Utilz can name, so there is no upgrade for it"
      echo "  Install Utilz with Homebrew: brew install matthewsinclair/utilz/utilz" >&2
      return 1
      ;;
  esac
}

# dev: the pull, refused over a dirty runtime set, then the publish's own build.
_install_upgrade_dev() {
  local state before after
  state=$(utilz_runtime_state "$UTILZ_HOME") || return 1

  case "$state" in
    dirty)
      error "the runtime set is dirty, so upgrade will not pull over it: $UTILZ_HOME"
      echo "  Commit or stash first." >&2
      return 1
      ;;
    unknown)
      error "git cannot read $UTILZ_HOME, so there is nothing to pull"
      return 1
      ;;
  esac

  before=$(git -C "$UTILZ_HOME" rev-parse --short=12 HEAD) || return 1
  echo "upgrade: git pull --ff-only in $UTILZ_HOME"
  git -C "$UTILZ_HOME" pull --ff-only || {
    error "git pull --ff-only failed in $UTILZ_HOME"
    return 1
  }
  after=$(git -C "$UTILZ_HOME" rev-parse --short=12 HEAD) || return 1
  if [[ "$before" == "$after" ]]; then
    success "already at $after"
  else
    success "pulled $before to $after"
  fi

  # The build the publish makes, so one build path serves both (T6: then the
  # tool's build where it has one).
  install_build_prez "$UTILZ_HOME" || return 1
  utilz_version_line
}

# opt: nothing written. It says how opt is upgraded, and when its dev checkout
# is ahead of what was published. rc 2: refused, nothing changed, as Utilz's
# refusals are.
_install_upgrade_opt() {
  local manifest="$UTILZ_HOME/$UTILZ_MANIFEST_NAME" src commit head

  src=$(utilz_manifest_value "$manifest" source_tree 2>/dev/null) || src=""
  commit=$(utilz_manifest_value "$manifest" source_commit 2>/dev/null) || commit=""

  error "an opt install is upgraded from its dev checkout, never on its own"
  echo "  Republish it there: cd ${src:-<the dev checkout>} && bin/utilz install --force" >&2

  if [[ -n "$src" && "$(utilz_tree "$src")" == dev* ]] &&
    head=$(git -C "$src" rev-parse HEAD 2>/dev/null) && [[ "$head" != "$commit" ]]; then
    echo "  The dev checkout is at ${head:0:12}; this install is ${commit:0:12}." >&2
  fi
  return 2
}

# brew: an explicit `brew update` first, as a step of its own (T6 allows one),
# because with Homebrew's auto-update off `brew outdated` reads a stale tap and
# never names a new release (utilz-vc, 24 Oct). Then brew's own upgrade, with
# HOMEBREW_NO_AUTO_UPDATE=1, and only when brew names utilz as outdated.
_install_upgrade_brew() {
  local out rc=0 root

  echo "upgrade: brew update, so brew outdated reads the current tap"
  "$INSTALL_BREW" update || {
    error "brew update failed, so upgrade did not ask whether utilz is outdated"
    return 1
  }

  out=$(HOMEBREW_NO_AUTO_UPDATE=1 "$INSTALL_BREW" outdated --quiet utilz 2>&1) || rc=$?
  # brew naming utilz is the outdated answer, whatever its status. Any other
  # non-zero is a brew outdated that did not answer, which is never "current"
  # (utilz-vc's W6).
  if printf '%s\n' "$out" | grep -qE '(^|/)utilz$'; then
    echo "upgrade: HOMEBREW_NO_AUTO_UPDATE=1 brew upgrade utilz"
    HOMEBREW_NO_AUTO_UPDATE=1 "$INSTALL_BREW" upgrade utilz || {
      error "brew upgrade utilz failed"
      return 1
    }
  elif [[ $rc -ne 0 ]]; then
    error "brew outdated failed (exit $rc): ${out:-it said nothing}"
    return 1
  else
    success "brew's utilz is current"
  fi

  root=$(_install_brew_root) || return 1
  (UTILZ_HOME="$root" utilz_version_line)
}

# Echo the state of <link> and, for a link into a Utilz tree, that tree's root,
# TAB-separated: "ours<TAB><root>", "broken<TAB><target>" or "other". Resolution
# follows the kernel's rule: a relative target is resolved from the LINK's own
# directory, not from the caller's cwd.
#
#   ours     its target is the DISPATCHER in a Utilz tree's bin/: bin/utilz,
#            or a bin/<name> that is itself a link to utilz, each_utility's
#            own test (utilz-vc's W2). Anything else a checkout's bin/ holds,
#            eg bin/devbin or a personal script, is not ours, and `use brew`
#            never removes it.
#   broken   it names <dir>/bin/<name> or <dir>/bin/utilz, and nothing is there:
#            a Utilz link into a tree that has gone, eg a removed worktree
#            (utilz-vc's W1). use dev|opt repoints it, use brew removes it, and
#            the report and doctor fail on it.
#   other    anything else.
#
# The root is LOGICAL, as the dispatcher resolves its own home, so a report
# names the path a person typed. Two roots are compared by what they resolve
# to (-ef, or pwd -P), never as strings (utilz-vc's W3).
_install_link_state() {
  local link="$1"
  local target tdir base root hop

  target=$(readlink "$link") || {
    printf 'other\n'
    return 0
  }
  base=$(basename "$target")

  if [[ "$target" == /* ]]; then
    tdir=$(cd "$(dirname "$target")" 2>/dev/null && pwd) || tdir=""
  else
    tdir=$(cd "$(dirname "$link")" 2>/dev/null && cd "$(dirname "$target")" 2>/dev/null && pwd) || tdir=""
  fi

  # A dispatcher-shaped target that names nothing is a link into a tree that
  # has gone: one to a utilz, or one named for a utility of the current tree's
  # own set. Any other dangling */bin/<name> is another tool's, left alone
  # (utilz-vc's F1).
  if [[ ! -e "$link" && "$(basename "$(dirname "$target")")" == "bin" ]]; then
    if [[ "$base" == "utilz" ]] ||
      { [[ "$base" == "$(basename "$link")" ]] && _install_is_link_set_name "$base"; }; then
      printf 'broken\t%s\n' "$target"
      return 0
    fi
  fi

  if [[ -z "$tdir" || "$(basename "$tdir")" != "bin" ]]; then
    printf 'other\n'
    return 0
  fi
  root=$(cd "$tdir/.." 2>/dev/null && pwd) || {
    printf 'other\n'
    return 0
  }
  case "$(install_tree_kind "$root")" in
    install | source) ;;
    *)
      printf 'other\n'
      return 0
      ;;
  esac

  # The dispatcher, and nothing else in that bin/.
  hop="$tdir/$base"
  if [[ "$base" == "utilz" && ! -L "$hop" ]] ||
    [[ -L "$hop" && "$(readlink "$hop")" == "utilz" ]]; then
    printf 'ours\t%s\n' "$root"
  else
    printf 'other\n'
  fi
}

# Echo one row per SYMLINK in <bindir>: "<name><TAB><state>[<TAB><detail>]",
# as _install_link_state answers for it.
#
# THE ONE LINK-WALK. `use` acts on this census and reports from it, and doctor
# reads it; a second walk anywhere would be a second answer to "which of these
# links are ours" (IN-AG-HIGHLANDER-001), and the one that drifted would be
# whichever nobody was reading.
install_link_census() {
  local bindir="$1"
  local entry

  for entry in "$bindir"/*; do
    [[ -L "$entry" ]] || continue
    printf '%s\t%s\n' "$(basename "$entry")" "$(_install_link_state "$entry")"
  done
}

# ============================================================================
# THE SWITCH: `utilz use [dev|opt|brew]` (dev, opt, brew contract T5, issue 0105)
# ============================================================================
#
# The link set is `utilz` and every utility of a tree, in the link directory,
# ~/.local/bin. The links are the only record of which tree serves the shell,
# and nothing else stores it. `use dev|opt` points every link of the set at that
# tree; `use brew` removes them, so Homebrew's own bin links answer: NO LINK
# MEANS BREW. `use` is the one verb that points links; `relink`, which did it
# with a tree typed, is retired as a public verb and its logic is this.

# The brew command `use brew` asks for brew's prefix, assigned here so only
# code that has sourced this file -- a test -- can point it anywhere else.
INSTALL_BREW="brew"

# Echo the link directory: UTILZ_LINK_DIR, FOR TESTS ONLY (contract T5 allows a
# tool to name the directory for its tests), else ~/.local/bin. `use --bin-dir`
# sets it for one run. One resolver, so use, its report and doctor read the
# same directory.
install_link_dir() {
  printf '%s\n' "${UTILZ_LINK_DIR:-$HOME/.local/bin}"
}

# Echo the link set of <tree>, one name per line: the dispatcher, then each
# utility the tree carries (each_utility, the one walker of bin/).
install_link_set() {
  printf 'utilz\n'
  each_utility "$1"
}

# True when <name> is in the current tree's link set. The set is read whole
# first: grep -q under pipefail would kill its producer.
_install_is_link_set_name() {
  local name="$1" set
  set=$(install_link_set "$UTILZ_HOME") || return 1
  grep -qxF -- "$name" <<<"$set"
}

# Echo the path <path> resolves to, following every link, as the kernel does: a
# relative target is read from its link's own directory. Logical, so it
# compares with the census's roots.
_install_resolve() {
  local path="$1" target dir
  while [[ -L "$path" ]]; do
    target=$(readlink "$path") || return 1
    if [[ "$target" == /* ]]; then
      path="$target"
    else
      path="$(dirname "$path")/$target"
    fi
  done
  dir=$(cd "$(dirname "$path")" 2>/dev/null && pwd) || return 1
  printf '%s/%s\n' "$dir" "$(basename "$path")"
}

# Echo one row per problem with the link set in <bindir>, TAB-separated, and
# return 1 if there is any (contract T5's shadow and split checks):
#
#   broken<TAB><name><TAB><target>   a Utilz link into a tree that has gone
#   split<TAB><root>                 the set serves more than one tree; one row
#                                    per tree
#   shadowed<TAB><name><TAB><hit>    a link in the set is not the first hit on
#                                    PATH
#
# A directory with no Utilz link has no set to check, and answers nothing.
# EVERY COMPARISON IS OF RESOLVED DIRECTORIES, never path strings (T5; utilz-
# vc's W3): a PATH entry or a tree can be reached through a link (~/bin to
# ~/.local/bin on rhadamanth, /tmp to /private/tmp on macOS).
install_link_health() {
  local bindir="$1"
  local name state detail hit here there key keys="" roots="" n_roots=0 problems=0

  [[ -d "$bindir" ]] || return 0
  here=$(cd "$bindir" && pwd -P) || return 0

  while IFS=$'\t' read -r name state detail; do
    case "$state" in
      broken)
        printf 'broken\t%s\t%s\n' "$name" "$detail"
        problems=1
        continue
        ;;
      ours) ;;
      *) continue ;;
    esac
    key=$(cd "$detail" 2>/dev/null && pwd -P) || key="$detail"
    if [[ "$keys" != *$'\n'"$key"$'\n'* ]]; then
      keys="${keys}"$'\n'"$key"$'\n'
      roots="${roots}${detail}"$'\n'
      n_roots=$((n_roots + 1))
    fi
    hit=$(type -P "$name" 2>/dev/null || true)
    there=""
    [[ -n "$hit" ]] && there=$(cd "$(dirname "$hit")" 2>/dev/null && pwd -P)
    if [[ "$there" != "$here" ]]; then
      printf 'shadowed\t%s\t%s\n' "$name" "${hit:-nothing on PATH}"
      problems=1
    fi
  done < <(install_link_census "$bindir")

  if [[ $n_roots -gt 1 ]]; then
    while IFS= read -r detail; do
      [[ -n "$detail" ]] && printf 'split\t%s\n' "$detail"
    done <<< "$roots"
    problems=1
  fi

  return "$problems"
}

# Say each problem install_link_health found in <bindir>, with the remedy, on
# stderr. THE ONE RENDERER, for `use`'s report and doctor alike (utilz-vc's
# recommendation 2), so the two cannot word one fault two ways.
install_link_health_render() {
  local bindir="$1" health="$2"
  local kind a b

  while IFS=$'\t' read -r kind a b; do
    case "$kind" in
      broken) error "$a in $bindir is a Utilz link into a tree that has gone: $b" ;;
      split) error "the links in $bindir are split across trees; one points into $a" ;;
      shadowed) error "$a in $bindir is shadowed: the first $a on PATH is $b" ;;
    esac
  done <<< "$health"
  echo "  Put $bindir before Homebrew's bin on PATH (the sleeve's PATH order)," >&2
  echo "  and make the set one tree with 'utilz use dev|opt|brew'." >&2
}

# Point every link of <tree>'s set in <bindir> at <tree>, creating the ones
# that are missing and repointing a broken one. A link that is not Utilz's, and
# a file that is not a link, are left alone and reported; so is a Utilz link
# for a utility <tree> does not carry, which pointed into <tree> would name
# nothing (issue 0079).
_install_point_links() {
  local tree="$1" bindir="$2"
  local name link state detail target newtarget
  local changed=0 already=0 left=0 linked=0

  # Absolute, once. A relative tree went into each link as typed, and the
  # kernel reads a relative target from the link's own directory, so every
  # link broke while the report said changed (issue 0079). Logical pwd, so a
  # link names the path a person typed; trees are compared with -ef.
  tree=$(CDPATH='' cd -- "$tree" && pwd) || {
    error "could not resolve the tree's path: $tree"
    return 1
  }

  mkdir -p "$bindir" || {
    error "could not create the link directory $bindir"
    return 1
  }

  echo "use: $bindir into $tree"

  while IFS= read -r name; do
    link="$bindir/$name"
    if [[ -L "$link" ]]; then
      IFS=$'\t' read -r state detail <<< "$(_install_link_state "$link")"
      case "$state" in
        other)
          # Not ours. Leaving it is the whole point of the row: a verb that
          # quietly tidies what it was not pointed at is the same shape as a
          # manifest check that re-blesses a file it refused.
          echo "  skipped:   $name (not a Utilz link)"
          left=$((left + 1))
          continue
          ;;
        ours)
          if [[ "$detail" -ef "$tree" ]]; then
            echo "  unchanged: $name"
            already=$((already + 1))
            continue
          fi
          ;;
      esac
      target=$(readlink "$link")
      # WHICH FILE the link names is preserved. bin/utilz and bin/<name> both
      # dispatch, because the dispatcher reads basename "$0", so choosing
      # between them would be normalising a convention (ST0014 design.md D9).
      # Relative-ness is not preserved, and cannot be: a relative target names
      # the OLD tree by construction.
      newtarget="$tree/bin/$(basename "$target")"
      ln -sfn "$newtarget" "$link" || {
        error "could not repoint $name"
        return 1
      }
      if [[ "$state" == "broken" ]]; then
        echo "  relinked:  $name -> $newtarget (it named $target, which has gone)"
      else
        echo "  relinked:  $name -> $newtarget"
      fi
      changed=$((changed + 1))
    elif [[ -e "$link" ]]; then
      echo "  skipped:   $name (not a link)"
      left=$((left + 1))
    else
      ln -s "$tree/bin/$name" "$link" || {
        error "could not link $name"
        return 1
      }
      echo "  linked:    $name -> $tree/bin/$name"
      linked=$((linked + 1))
    fi
  done < <(install_link_set "$tree")

  # A Utilz link this tree has no utility for keeps where it points.
  while IFS=$'\t' read -r name state detail; do
    [[ "$state" == "ours" || "$state" == "broken" ]] || continue
    if [[ ! -e "$tree/bin/$name" ]]; then
      echo "  skipped:   $name (not in $tree)"
      left=$((left + 1))
    fi
  done < <(install_link_census "$bindir")

  success "$changed changed, $linked linked, $already already correct, $left left alone"
}

# Remove every Utilz link in <bindir>, a broken one included, and nothing
# else (`use brew`: no link means brew).
_install_remove_links() {
  local bindir="$1"
  local name state detail removed=0 left=0

  [[ -d "$bindir" ]] || {
    success "no link directory at $bindir, so nothing points away from brew"
    return 0
  }

  echo "use: removing the Utilz links in $bindir"
  while IFS=$'\t' read -r name state detail; do
    [[ -n "$name" ]] || continue
    case "$state" in
      ours | broken) ;;
      *)
        left=$((left + 1))
        continue
        ;;
    esac
    # Both names are guarded, so an empty one stops the shell rather than
    # widening what is removed.
    rm -f -- "${bindir:?}/${name:?}" || {
      error "could not remove $bindir/$name"
      return 1
    }
    echo "  removed:   $name (was $detail)"
    removed=$((removed + 1))
  done < <(install_link_census "$bindir")

  success "$removed removed, $left left alone (not Utilz links)"
}

# Echo the tree <word> names -- dev or opt -- from the running tree, or return
# 1 by name when it cannot be reached. Each tree can reach the other without a
# path typed: opt is UTILZ_INSTALL_PREFIX, from the sleeve; dev is the running
# tree when that is dev, and the opt install's source_tree when it is opt.
_install_use_tree() {
  local word="$1"
  local here prefix dev

  here=$(utilz_tree)

  if [[ "$word" == "opt" ]]; then
    prefix=$(install_prefix_configured) || return 1
    case "$(utilz_tree "$prefix")" in
      opt)
        printf '%s\n' "$prefix"
        ;;
      "opt old")
        error "the opt install at $prefix has an old manifest"
        echo "  Republish it from the dev checkout with 'utilz install --force'." >&2
        return 1
        ;;
      brew*)
        install_refuse_keg "$prefix"
        return 1
        ;;
      *)
        error "no opt install at $prefix"
        echo "  Publish one from the dev checkout with 'utilz install'." >&2
        return 1
        ;;
    esac
    return 0
  fi

  case "$here" in
    dev*)
      dev="$UTILZ_HOME"
      ;;
    opt)
      dev=$(utilz_manifest_value "$UTILZ_HOME/$UTILZ_MANIFEST_NAME" source_tree) || return 1
      ;;
    brew*)
      # A keg's source_tree is brew's build directory, deleted once the
      # formula's install returned (ST0019 D4), so it names no tree.
      error "the Homebrew install does not know where a dev checkout is"
      echo "  Run 'use dev' from the checkout: <checkout>/bin/utilz use dev." >&2
      return 1
      ;;
    *)
      error "this tree ($here) records no dev checkout to point at"
      echo "  Run 'use dev' from the checkout: <checkout>/bin/utilz use dev." >&2
      return 1
      ;;
  esac

  if [[ -z "$dev" || "$(utilz_tree "$dev")" != dev* ]]; then
    error "no dev checkout at ${dev:-(none recorded)}"
    echo "  The opt install records the checkout it was published from, and it" >&2
    echo "  is not there. Run 'use dev' from the checkout itself." >&2
    return 1
  fi
  printf '%s\n' "$dev"
}

# Echo the Homebrew install's root, by its opt link, or return 1 by name.
_install_brew_root() {
  local prefix
  if ! prefix=$("$INSTALL_BREW" --prefix 2>/dev/null) || [[ -z "$prefix" ]]; then
    error "Homebrew is not installed ($INSTALL_BREW --prefix answered nothing)"
    return 1
  fi
  if [[ ! -x "$prefix/opt/utilz/libexec/bin/utilz" ]]; then
    error "there is no Homebrew install of Utilz under $prefix"
    echo "  Install it: brew install matthewsinclair/utilz/utilz" >&2
    return 1
  fi
  printf '%s\n' "$prefix/opt/utilz/libexec"
}

# Report which tree each link serves, and change nothing. rc 1 when the set is
# split, shadowed or broken (contract T5), naming what splits, shadows or
# breaks it.
install_use_report() {
  local bindir="$1"
  local name state detail rows="" n=0 hit root health rc=0 prefix dev count

  printf 'links: %s\n' "$bindir"

  if [[ -d "$bindir" ]]; then
    while IFS=$'\t' read -r name state detail; do
      [[ "$state" == "ours" || "$state" == "broken" ]] || continue
      [[ "$state" == "ours" ]] && rows="${rows}${detail}"$'\n'
      n=$((n + 1))
    done < <(install_link_census "$bindir")
  fi

  if [[ $n -gt 0 ]]; then
    printf '%s' "$rows" | LC_ALL=C sort | uniq -c | while read -r count root; do
      [[ -n "$root" ]] && printf '  %s at %s -- %s link(s)\n' "$(utilz_tree "$root")" "$root" "$count"
    done
  else
    # NO LINK MEANS BREW (contract T5): it is the state a brew-only user is in
    # without ever running `use`, when the first utilz on PATH is the keg's.
    hit=$(type -P utilz 2>/dev/null || true)
    if [[ -n "$hit" ]] && root=$(_install_resolve "$hit") &&
      [[ "$(utilz_tree "$(dirname "$(dirname "$root")")")" == brew* ]]; then
      printf '  brew: no links, and %s (the Homebrew install) answers\n' "$hit"
    elif [[ -n "$hit" ]]; then
      printf '  no links; %s answers, which is not the Homebrew install\n' "$hit"
    else
      printf '  no links, and no utilz on PATH\n'
    fi
  fi

  if ! health=$(install_link_health "$bindir"); then
    rc=1
    install_link_health_render "$bindir" "$health"
  fi

  # The two addresses the switch can reach from here.
  if prefix=$(install_prefix_configured 2>/dev/null); then
    case "$(utilz_tree "$prefix")" in
      opt) printf 'opt:   %s\n' "$prefix" ;;
      "opt old") printf "opt:   old manifest at %s; 'utilz install --force' republishes it\n" "$prefix" ;;
      *) printf 'opt:   no install at %s\n' "$prefix" ;;
    esac
  else
    printf 'opt:   UTILZ_INSTALL_PREFIX is not set\n'
  fi
  case "$(utilz_tree)" in
    dev*) printf 'dev:   %s\n' "$UTILZ_HOME" ;;
    opt)
      dev=$(utilz_manifest_value "$UTILZ_HOME/$UTILZ_MANIFEST_NAME" source_tree 2>/dev/null) || dev=""
      printf 'dev:   %s\n' "${dev:-(none recorded)}"
      ;;
    *) printf 'dev:   not known from this tree\n' ;;
  esac

  return "$rc"
}

install_usage_use() {
  cat <<'USAGE'
Usage: utilz use [dev|opt|brew] [--bin-dir DIR]

Switch which tree the links in ~/.local/bin serve.

  utilz use dev    Point them at the dev checkout
  utilz use opt    Point them at the opt install, $UTILZ_INSTALL_PREFIX
  utilz use brew   Remove them, so Homebrew's own links answer
  utilz use        Report which tree they serve, and change nothing

  --bin-dir DIR    Where the links live, for tests. Default: ~/.local/bin

No link means brew. ~/.local/bin must come before Homebrew's bin on PATH for a
dev or opt link to answer; `utilz use` and doctor say when it does not.
USAGE
}

# `utilz use dev|opt|brew` -- the one switch (contract T5).
install_verb_use() {
  local word=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      dev | opt | brew)
        word="$1"
        shift
        ;;
      --bin-dir)
        if [[ $# -lt 2 ]]; then
          error "--bin-dir requires a DIR argument"
          return 2
        fi
        local UTILZ_LINK_DIR
        UTILZ_LINK_DIR=$(expand_tilde "$2")
        shift 2
        ;;
      -h | --help)
        install_usage_use
        return 0
        ;;
      *)
        error "Unknown argument: $1"
        echo "  utilz use takes the word 'dev', 'opt' or 'brew', or no word at all." >&2
        return 2
        ;;
    esac
  done

  local bindir
  bindir=$(install_link_dir)

  if [[ -z "$word" ]]; then
    install_use_report "$bindir"
    return $?
  fi

  local tree
  if [[ "$word" == "brew" ]]; then
    tree=$(_install_brew_root) || return 1
    _install_remove_links "$bindir" || return 1
  else
    tree=$(_install_use_tree "$word") || return 1
    _install_point_links "$tree" "$bindir" || return 1
  fi

  # The version line of the tree the shell now reaches (contract T5), read as
  # that tree would read it.
  (UTILZ_HOME="$tree" utilz_version_line)

  # Said, not refused: the PATH order is the sleeve's, not this verb's.
  local health
  if [[ "$word" != "brew" ]] && ! health=$(install_link_health "$bindir"); then
    warn "the links are set, but PATH does not reach them first; 'utilz use' says what shadows them"
  fi
}
