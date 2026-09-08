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

# Built at publish time and gitignored, so it is named rather than enumerated.
# It is part of the owned set whether or not it has been built: an owned path
# that is absent is a publish that must fail, not a set that quietly shrinks.
INSTALL_PREZ_BINARY="opt/prez/crate/target/release/prez"

# Subtrees that are tracked but not ours to publish. See design.md D2 for why
# the enumeration is by EXCLUSION rather than by an inclusion list: five of the
# fifteen utilities keep runtime payload outside the three obvious filenames,
# and an inclusion list drops all five silently.
INSTALL_EXCLUDE_RE='^(bin/devbin$|bin/\.devbin/|opt/[^/]+/test/|opt/prez/crate/)'

# ============================================================================
# PURE: facts about a tree
# ============================================================================

# Echo the sha256 of one file. macOS ships shasum, Linux ships sha256sum, and
# CI runs both.
_install_sha256() {
  local file="$1"

  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | awk '{print $1}'
  else
    error "no sha256 tool found: need shasum or sha256sum"
    return 1
  fi
}

# True when <tree> is the TOP LEVEL of a git worktree, not merely inside one.
# Publishing from a subdirectory would enumerate a set relative to the wrong
# root, and git answers happily either way.
_install_is_git_toplevel() {
  local tree="$1"
  local top here

  top=$(git -C "$tree" rev-parse --show-toplevel 2>/dev/null) || return 1
  here=$(cd "$tree" 2>/dev/null && pwd -P) || return 1
  [[ "$top" == "$here" ]]
}

# Echo every owned path of a SOURCE tree, one per line, relative to its root,
# LC_ALL=C sorted so the order is stable across filesystems.
#
# Git is the authority for the same reason the manifest is: the manifest's
# claim is "these bytes are commit X", and `git ls-files` is exactly "the files
# commit X names". Any other enumeration makes the file list and the provenance
# claim two authorities that agree until they do not.
install_owned_paths() {
  local tree="$1"
  local tracked kept

  if ! _install_is_git_toplevel "$tree"; then
    error "not a git repository (or not its top level): $tree"
    return 1
  fi

  tracked=$(git -C "$tree" ls-files -- bin opt help static VERSION) || {
    error "could not enumerate tracked files in $tree"
    return 1
  }

  if [[ -z "$tracked" ]]; then
    error "no tracked files under the owned roots in $tree"
    return 1
  fi

  # grep exits 1 when nothing survives, which here means every owned root was
  # excluded -- a real error, not an empty result, so it is named rather than
  # allowed to surface later as a short manifest.
  kept=$(printf '%s\n' "$tracked" | grep -Ev "$INSTALL_EXCLUDE_RE") || true

  if [[ -z "$kept" ]]; then
    error "every tracked path under the owned roots was excluded in $tree"
    return 1
  fi

  # The built binary is owned whenever the tree carries the crate to build it
  # from. That is the same predicate the publish uses to decide whether to run
  # cargo at all, so the binary cannot leave the owned set while there is still
  # something to build -- and a tree with no prez does not name prez output.
  if [[ -f "$tree/opt/prez/crate/Cargo.toml" ]]; then
    kept="$kept
$INSTALL_PREZ_BINARY"
  fi

  printf "%s\n" "$kept" | LC_ALL=C sort
}

# Echo the configured install prefix of a SOURCE tree, tilde-expanded.
# Returns 1, not an empty string, when it is unset.
#
# A caller that forgets to check an empty return proceeds and writes to /bin;
# a caller that forgets to check rc 1 is killed by set -e at the assignment.
# Only one of those is silent.
install_prefix_configured() {
  local tree="$1"
  local raw

  # get_util_metadata resolves $UTILZ_HOME/opt/<n>/<n>.yaml, so the tree under
  # examination is bound in the subshell rather than inherited from the tree
  # this code is running from. AC05 requires the read go through the one
  # metadata reader like every other utility's yaml.
  raw=$( export UTILZ_HOME="$tree"; get_util_metadata utilz '.install.prefix' ) || raw=""

  # yq prints the four-character string `null` for an absent key and
  # get_util_metadata ends `echo "$result"`, so it passes straight through.
  # `null` and empty are the same answer -- unset -- and a `[[ -n ]]` guard
  # PASSES on unset, then publishes to a directory called ./null and reports
  # success. Measured 7 Sep against opt/utilz/utilz.yaml.
  if [[ -z "$raw" || "$raw" == "null" ]]; then
    error "install.prefix is not set in $tree/opt/utilz/utilz.yaml"
    return 1
  fi

  # Shared with emacs_install --dest (D10): one expander, one home. A YAML
  # scalar is not a shell word, so an unexpanded ~ creates a directory
  # literally named ~ under the cwd, and every later command then finds the
  # install exactly where it looked -- silent and self-consistent.
  raw=$(expand_tilde "$raw")

  printf '%s\n' "$raw"
}

# Echo which kind of tree <dir> is: install, source, or other.
#
# The manifest is tested FIRST because an install tree also carries bin/utilz
# and opt/utilz/utilz.yaml -- the source test alone would call every install a
# source tree.
install_tree_kind() {
  local dir="$1"

  if [[ -f "$dir/$UTILZ_MANIFEST_NAME" ]]; then
    printf 'install\n'
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

# Echo the git state of a source tree: clean, dirty, or unknown.
#
# Three values, not two. "no changes" and "cannot tell" must never render as
# the same answer: a tree that is not a git repository cannot establish the
# provenance the manifest claims, and that is a different fact from a tree
# whose provenance is intact.
install_tree_state() {
  local tree="$1"
  local porcelain

  if ! _install_is_git_toplevel "$tree"; then
    printf 'unknown\n'
    return 0
  fi

  porcelain=$(git -C "$tree" status --porcelain) || {
    error "could not read git status for $tree"
    return 1
  }

  # The WHOLE tree, not the owned subset. The manifest's claim is "these bytes
  # are commit X", and that holds only when nothing is uncommitted: a dirty .md
  # beside a clean opt/ still means the recorded commit does not describe the
  # checkout the bytes came from.
  if [[ -n "$porcelain" ]]; then
    printf 'dirty\n'
  else
    printf 'clean\n'
  fi
}

# ============================================================================
# PURE: the manifest
# ============================================================================

# Echo one manifest row per owned path, TAB-separated, in owned-set order.
#
#   file<TAB><sha256><TAB><path>
#   link<TAB><target><TAB><path>
#
# The type discriminator is what lets a checker pick the right comparison
# without inferring it from the path.
install_manifest_rows() {
  local tree="$1"
  local paths path target sum

  paths=$(install_owned_paths "$tree") || return 1

  while IFS= read -r path; do
    [[ -n "$path" ]] || continue

    if [[ -L "$tree/$path" ]]; then
      # The TARGET STRING, never a content hash. All fifteen dispatcher links
      # resolve to one file, so a resolved-content hash gives every one of them
      # the same value and a link retargeted at the wrong utility reads as
      # intact (AC06).
      target=$(readlink "$tree/$path") || {
        error "could not read link target: $path"
        return 1
      }
      printf 'link\t%s\t%s\n' "$target" "$path"
    elif [[ -f "$tree/$path" ]]; then
      sum=$(_install_sha256 "$tree/$path") || {
        error "could not checksum: $path"
        return 1
      }
      printf 'file\t%s\t%s\n' "$sum" "$path"
    else
      error "owned path is missing from $tree: $path"
      return 1
    fi
  done <<< "$paths"
}

# Write the manifest for a SOURCE tree to <out>.
install_manifest_write() {
  local tree="$1"
  local out="$2"
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

  # Rows may be supplied by the caller: upgrade composes them so a file it
  # declined to overwrite keeps its install-time row (install_manifest_rows_
  # preserving). One writer either way -- the header is composed in exactly
  # one place.
  if [[ $# -ge 3 ]]; then
    rows="$3"
  else
    rows=$(install_manifest_rows "$tree") || return 1
  fi

  # NO generated-at timestamp. A timestamp makes two manifests of identical
  # bytes compare unequal, which turns the one instrument that reports drift
  # into a thing that always reports drift.
  # source-tree is what makes `utilz use dev` turnkey (D13): each tree then
  # holds the address of the other, so neither direction needs a path typed or
  # a second config key invented. Resolved physically, because a relative or
  # symlinked spelling would name a tree that only resolves from where the
  # publish happened to be run.
  local source_tree
  source_tree=$(cd "$tree" 2>/dev/null && pwd) || source_tree="$tree"

  {
    printf 'utilz-version\t%s\n' "$version"
    printf 'source-commit\t%s\n' "$commit"
    printf 'source-tree\t%s\n' "$source_tree"
    printf '%s\n' "$rows"
  } > "$out"
}

# Echo one row per owned path whose on-disk state differs from its manifest
# row, TAB-separated as "<reason><TAB><path>". Silence means the install
# matches the manifest it was written with.
#
#   missing      the path is not there at all
#   modified     a file whose sha256 differs from its row
#   retargeted   a link whose target string differs from its row
#   not-a-link   the manifest says link and the disk holds a regular file
#   not-a-file   the manifest says file and the disk holds a link
#
# rc 0 no drift, rc 1 drift reported, rc 2 the manifest could not be read.
# Three answers, three codes, for the same reason install_tree_state has three
# values: "matches" and "cannot tell" must never render as the same answer.
#
# THE ROLL-CALL IS REQUIRED, NOT MERELY CONVENIENT. THIS FUNCTION MUST NEVER
# WALK THE TREE (AC14). It reads the manifest and looks at nothing else, so a
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
  local kind value path actual
  local drift=0

  if [[ ! -f "$manifest" ]]; then
    error "no manifest at $root/$UTILZ_MANIFEST_NAME"
    return 2
  fi

  while IFS=$'\t' read -r kind value path; do
    case "$kind" in
      utilz-version | source-commit | source-tree) continue ;;
      file | link) ;;
      "") continue ;;
      *)
        # An unrecognised row is a manifest this code cannot vouch for, and
        # skipping it would report "no drift" over a file nothing checked.
        error "unrecognised manifest row kind '$kind' in $manifest"
        return 2
        ;;
    esac

    [[ -n "$path" ]] || continue

    if [[ ! -e "$root/$path" && ! -L "$root/$path" ]]; then
      printf 'missing\t%s\n' "$path"
      drift=1
      continue
    fi

    if [[ "$kind" == "link" ]]; then
      if [[ ! -L "$root/$path" ]]; then
        # cp dereferences a symlink, so an install that took this path still
        # WORKS: N copies of the dispatcher, nothing failing, and nothing
        # saying anything. It is its own reason rather than 'modified'.
        printf 'not-a-link\t%s\n' "$path"
        drift=1
        continue
      fi

      actual=$(readlink "$root/$path") || {
        error "could not read link target: $path"
        return 2
      }

      if [[ "$actual" != "$value" ]]; then
        printf 'retargeted\t%s\n' "$path"
        drift=1
      fi
    else
      if [[ -L "$root/$path" ]]; then
        printf 'not-a-file\t%s\n' "$path"
        drift=1
        continue
      fi

      actual=$(_install_sha256 "$root/$path") || return 2

      if [[ "$actual" != "$value" ]]; then
        printf 'modified\t%s\n' "$path"
        drift=1
      fi
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

  paths=$(install_owned_paths "$src") || return 1

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

# Build the prez binary in <src>'s crate, if it has one. A no-op otherwise.
install_build_prez() {
  local src="$1"
  local crate="$src/opt/prez/crate"

  [[ -f "$crate/Cargo.toml" ]] || return 0

  if ! command -v cargo >/dev/null 2>&1; then
    error "cargo is required to publish: the install SHIPS prez's built binary"
    echo "  AC09 -- the install-tree shim refuses to build, so the binary has to" >&2
    echo "  exist before anyone runs it. Install Rust from https://rustup.rs." >&2
    return 1
  fi

  echo "build:  cargo build --release (opt/prez/crate)"

  # CARGO_TARGET_DIR is unset for this build so the binary lands where the
  # owned set names it. The shim honours the variable deliberately, but a
  # publish run by someone with it exported would send the output somewhere
  # the copy never looks, and then ship the previous binary or none at all.
  (
    unset CARGO_TARGET_DIR
    cd "$crate" && cargo build --release --quiet
  ) || {
    error "cargo build failed in $crate"
    return 1
  }
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
Usage: utilz install [--prefix DIR] [--force]

Publish a runnable install of this Utilz checkout.

  --prefix DIR  Publish here instead of install.prefix from opt/utilz/utilz.yaml
  --force       Publish over an existing install

The source tree must be CLEAN. The manifest records the commit the bytes came
from, and that claim holds only when nothing is uncommitted. No flag overrides
it, --force included.
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
    prefix=$(install_prefix_configured "$src") || return 1
  fi

  local state kind commit
  state=$(install_tree_state "$src")
  kind=$(install_tree_kind "$prefix")
  commit=$(git -C "$src" rev-parse --short HEAD 2>/dev/null) || commit="none"

  install_announce "install" "$src" "$state" "$commit" "$prefix" "$kind"

  case "$state" in
    dirty)
      error "source tree is dirty: $src"
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
    install)
      if [[ $force -eq 0 ]]; then
        error "an install already exists at $prefix"
        echo "  Use 'utilz upgrade' to replace it, which reports files edited" >&2
        echo "  in place instead of overwriting them. Or --force to publish" >&2
        echo "  straight over it." >&2
        return 1
      fi
      ;;
  esac

  install_build_prez "$src" || return 1
  install_copy_owned "$src" "$prefix" || return 1
  install_manifest_write "$src" "$prefix/$UTILZ_MANIFEST_NAME" || return 1

  local count
  count=$(grep -c -v '^utilz-version	\|^source-commit	\|^source-tree	' "$prefix/$UTILZ_MANIFEST_NAME")
  success "installed $(cat "$src/VERSION") ($commit) at $prefix -- $count paths"
}

# Echo the manifest rows for <src>, except that any path listed in <preserved>
# (newline-separated) keeps its row from <old_manifest> verbatim.
#
# A file the upgrade declined to overwrite keeps its INSTALL-TIME row, and the
# two wrong answers are both worse in the same direction. Re-checksumming what
# is on disk records the edit as canonical and the next check pronounces the
# file intact -- the refusal still prints, and the evidence that made it
# necessary is destroyed by the same pass. Writing the NEW source's checksum
# claims a file was updated that was not. The install-time row leaves the
# drift visible, which is the only one of the three that stays true.
install_manifest_rows_preserving() {
  local src="$1"
  local old_manifest="$2"
  local preserved="$3"
  local rows row path old

  rows=$(install_manifest_rows "$src") || return 1

  if [[ -z "$preserved" ]]; then
    printf '%s\n' "$rows"
    return 0
  fi

  while IFS= read -r row; do
    [[ -n "$row" ]] || continue

    # The path is the third TAB-separated field; no owned path contains a tab.
    path=${row##*$'\t'}

    if printf '%s\n' "$preserved" | grep -qxF "$path"; then
      old=$(awk -F'\t' -v p="$path" '$3 == p { print; exit }' "$old_manifest")
      if [[ -n "$old" ]]; then
        printf '%s\n' "$old"
        continue
      fi
      # No old row for a path we chose to preserve means the manifest and the
      # drift report disagree, which is a state neither can be trusted in.
      error "preserved path has no row in $old_manifest: $path"
      return 1
    fi

    printf '%s\n' "$row"
  done <<< "$rows"
}

install_usage_upgrade() {
  cat <<'USAGE'
Usage: utilz upgrade [--prefix DIR] [--force]

Replace an existing install with this Utilz checkout.

  --prefix DIR  Upgrade the install here instead of install.prefix
  --force       Overwrite files that were edited in place

Files edited in place are REPORTED and left alone, and keep their install-time
checksum so the next check still reports them. The source tree must be clean;
no flag overrides that.
USAGE
}

# `utilz upgrade` -- replace an install, preserving what someone edited.
#
# The mirror of install (AC04) plus the one behaviour install does not have.
install_verb_upgrade() {
  local prefix=""
  local force=0
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
      -h | --help)
        install_usage_upgrade
        return 0
        ;;
      *)
        error "Unknown option: $1"
        install_usage_upgrade >&2
        return 2
        ;;
    esac
  done

  if [[ -z "$prefix" ]]; then
    prefix=$(install_prefix_configured "$src") || return 1
  fi

  local state kind commit
  state=$(install_tree_state "$src")
  kind=$(install_tree_kind "$prefix")
  commit=$(git -C "$src" rev-parse --short HEAD 2>/dev/null) || commit="none"

  install_announce "upgrade" "$src" "$state" "$commit" "$prefix" "$kind"

  case "$state" in
    dirty)
      error "source tree is dirty: $src"
      echo "  The manifest records the commit the bytes came from, and that is" >&2
      echo "  only true when nothing is uncommitted. There is no flag for this" >&2
      echo "  one. Commit or stash first." >&2
      return 1
      ;;
    unknown)
      error "cannot establish provenance: $src is not a git repository"
      return 1
      ;;
  esac

  if [[ "$kind" != "install" ]]; then
    error "no install at $prefix"
    echo "  Use 'utilz install' to publish one. upgrade replaces an install" >&2
    echo "  that is already there; it will not create the first one, because" >&2
    echo "  there would be nothing to preserve and nothing to report." >&2
    return 1
  fi

  # The drift is computed BEFORE anything is written. A report taken after the
  # copy would describe the tree the copy just made, not the one someone edited.
  local drift check_rc=0
  drift=$(install_manifest_check "$prefix") || check_rc=$?

  if [[ $check_rc -eq 2 ]]; then
    error "the install at $prefix has a manifest this cannot read"
    return 1
  fi

  local preserved="" reason path kept=0
  if [[ $force -eq 0 && -n "$drift" ]]; then
    while IFS=$'\t' read -r reason path; do
      [[ -n "$path" ]] || continue
      case "$reason" in
        modified | retargeted | not-a-link | not-a-file)
          warn "left alone ($reason): $path"
          preserved="${preserved}${path}"$'\n'
          kept=$((kept + 1))
          ;;
        missing)
          # Nothing was authored there, so there is nothing to preserve. The
          # copy restores it.
          ;;
      esac
    done <<< "$drift"
  fi

  install_build_prez "$src" || return 1
  install_copy_owned "$src" "$prefix" "$preserved" || return 1

  local rows
  rows=$(install_manifest_rows_preserving "$src" "$prefix/$UTILZ_MANIFEST_NAME" "$preserved") || return 1
  install_manifest_write "$src" "$prefix/$UTILZ_MANIFEST_NAME" "$rows" || return 1

  local count
  count=$(grep -c -v '^utilz-version	\|^source-commit	\|^source-tree	' "$prefix/$UTILZ_MANIFEST_NAME")

  if [[ $kept -gt 0 ]]; then
    success "upgraded to $(cat "$src/VERSION") ($commit) at $prefix -- $count paths, $kept left alone"
    echo "  The $kept file(s) above keep their install-time checksum, so the" >&2
    echo "  next check still reports them. Re-run with --force to overwrite." >&2
  else
    success "upgraded to $(cat "$src/VERSION") ($commit) at $prefix -- $count paths"
  fi
}

# Echo the Utilz tree root that <link> points into, or return 1 if it points
# somewhere else. Resolution follows the kernel's rule: a relative target is
# resolved from the LINK's own directory, not from the caller's cwd.
_install_link_root() {
  local link="$1"
  local target tdir root

  target=$(readlink "$link") || return 1

  if [[ "$target" == /* ]]; then
    tdir=$(cd "$(dirname "$target")" 2>/dev/null && pwd) || return 1
  else
    tdir=$(cd "$(dirname "$link")" 2>/dev/null && cd "$(dirname "$target")" 2>/dev/null && pwd) || return 1
  fi

  # Every Utilz link, whatever its shape, lands in <root>/bin.
  [[ "$(basename "$tdir")" == "bin" ]] || return 1
  root=$(cd "$tdir/.." 2>/dev/null && pwd) || return 1

  case "$(install_tree_kind "$root")" in
    install | source) printf '%s\n' "$root" ;;
    *) return 1 ;;
  esac
}

# Echo one row per SYMLINK in <bindir>: "<name><TAB><root>", where <root> is
# the Utilz tree the link resolves into, or "-" when it resolves elsewhere.
#
# THE ONE LINK-WALK. relink acts on this census and `use` reports from it; a
# second walk anywhere would be a second answer to "which of these links are
# ours" (IN-AG-HIGHLANDER-001), and the one that drifted would be whichever
# nobody was reading.
install_link_census() {
  local bindir="$1"
  local entry name root

  for entry in "$bindir"/*; do
    [[ -L "$entry" ]] || continue
    name=$(basename "$entry")

    if root=$(_install_link_root "$entry"); then
      printf '%s\t%s\n' "$name" "$root"
    else
      printf '%s\t-\n' "$name"
    fi
  done
}

install_usage_relink() {
  cat <<'USAGE'
Usage: utilz relink [--prefix DIR] [--bin-dir DIR]

Repoint the PATH symlinks at a Utilz tree.

  --prefix DIR   The tree to point at. Default: install.prefix
  --bin-dir DIR  Where the links live. Default: ~/.local/bin

Links that resolve into a Utilz tree are repointed; anything else is left
alone and reported as skipped. install and upgrade NEVER do this implicitly.
USAGE
}

# `utilz relink` -- the explicit PATH cutover (AC16).
#
# AC11 and AC16 are one policy from two sides: never implicitly, always
# available explicitly. A --relink flag on install was rejected because a flag
# becomes habitual, and habitual relinking is implicit relinking with a longer
# spelling.
install_verb_relink() {
  local prefix=""
  local bindir=""
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
      --bin-dir)
        if [[ $# -lt 2 ]]; then
          error "--bin-dir requires a DIR argument"
          return 2
        fi
        bindir=$(expand_tilde "$2")
        shift 2
        ;;
      -h | --help)
        install_usage_relink
        return 0
        ;;
      *)
        error "Unknown option: $1"
        install_usage_relink >&2
        return 2
        ;;
    esac
  done

  if [[ -z "$prefix" ]]; then
    prefix=$(install_prefix_configured "$src") || return 1
  fi
  if [[ -z "$bindir" ]]; then
    bindir="$HOME/.local/bin"
  fi

  case "$(install_tree_kind "$prefix")" in
    install | source) ;;
    *)
      error "not a Utilz tree: $prefix"
      echo "  relink points PATH symlinks at a tree that already exists. Publish" >&2
      echo "  one with 'utilz install' first." >&2
      return 1
      ;;
  esac

  if [[ ! -d "$bindir" ]]; then
    error "no such directory: $bindir"
    return 1
  fi

  echo "relink: $bindir into $prefix"

  local name target root newtarget
  local changed=0 already=0 left=0

  # Process substitution, never a pipe: the counters below accumulate in this
  # shell and a pipe would subshell the loop body away.
  while IFS=$'\t' read -r name root; do
    [[ -n "$name" ]] || continue

    if [[ "$root" == "-" ]]; then
      # Not ours. Leaving it is the whole point of the row: a verb that
      # quietly tidies what it was not pointed at is the same shape as a
      # manifest check that re-blesses a file it refused.
      echo "  skipped:   $name (not a Utilz link)"
      left=$((left + 1))
      continue
    fi

    target=$(readlink "$bindir/$name")

    if [[ "$root" == "$prefix" ]]; then
      echo "  unchanged: $name"
      already=$((already + 1))
      continue
    fi

    # WHICH FILE the link names is preserved. bin/utilz and bin/<name> both
    # dispatch, because the dispatcher reads basename "$0", so choosing
    # between them would be normalising a convention rather than relinking
    # (design.md D9). ~/.local/bin/prez names the dispatcher and stays that
    # way.
    #
    # What is NOT preserved is relative-ness, and it cannot be: a relative
    # target names the OLD tree by construction, so a repoint has to rewrite
    # it, and recomputing a relative path across a tree move is arithmetic
    # that produces a silently broken link when it is wrong.
    newtarget="$prefix/bin/$(basename "$target")"

    ln -sfn "$newtarget" "$bindir/$name" || {
      error "could not relink $name"
      return 1
    }
    echo "  relinked:  $name -> $newtarget"
    changed=$((changed + 1))
  done < <(install_link_census "$bindir")

  success "$changed changed, $already already correct, $left left alone"
}

# Echo the tree that <word> names -- `opt` or `dev` -- for the source tree
# <src>. Returns 1, by name, when the address cannot be read.
#
# EACH TREE HOLDS THE ADDRESS OF THE OTHER, which is the whole reason this
# verb is turnkey (D13). `opt` is install.prefix from utilz.yaml, which both
# trees carry. `dev` is source-tree from the install's manifest, recorded at
# the one moment the source path is known for certain. Neither direction needs
# a path typed or a second config key invented, and a second key would be an
# address that can disagree with the manifest.
_install_use_tree() {
  local word="$1"
  local src="$2"
  local prefix manifest source_tree

  prefix=$(install_prefix_configured "$src") || return 1

  if [[ "$word" == "opt" ]]; then
    printf '%s\n' "$prefix"
    return 0
  fi

  manifest="$prefix/$UTILZ_MANIFEST_NAME"

  if [[ ! -f "$manifest" ]]; then
    error "no install at $prefix, so the source tree's address cannot be read"
    echo "  'use dev' reads source-tree from the install's manifest, which is" >&2
    echo "  where the publish recorded it. Run 'utilz install' first." >&2
    return 1
  fi

  source_tree=$(awk -F'\t' '$1 == "source-tree" { print $2; exit }' "$manifest")

  if [[ -z "$source_tree" ]]; then
    error "the install at $prefix records no source-tree"
    echo "  It was published before that row existed. Run 'utilz upgrade' from" >&2
    echo "  the source tree; the manifest is rewritten and gains the row." >&2
    return 1
  fi

  printf '%s\n' "$source_tree"
}

# Report which tree the PATH links currently serve. Changes nothing.
install_use_report() {
  local src="$1"
  local bindir="$2"
  local prefix manifest source_tree dev_label name root
  local opt_n=0 dev_n=0 other_n=0

  prefix=$(install_prefix_configured "$src") || return 1

  # THREE ANSWERS, NOT TWO. "there is no install" and "there is an install
  # that predates the source-tree row" are different facts with different
  # remedies, and printing them as one sends the reader to publish something
  # that is already published. Measured 8 Sep: the live install was cut before
  # the row existed, and the first draft of this reported it as absent.
  source_tree=""
  dev_label="(no install at $prefix)"
  manifest="$prefix/$UTILZ_MANIFEST_NAME"

  if [[ -f "$manifest" ]]; then
    source_tree=$(awk -F'\t' '$1 == "source-tree" { print $2; exit }' "$manifest")
    if [[ -n "$source_tree" ]]; then
      dev_label="$source_tree"
    else
      dev_label="(install predates source-tree; 'utilz upgrade' records it)"
    fi
  fi

  if [[ ! -d "$bindir" ]]; then
    error "no such directory: $bindir"
    return 1
  fi

  while IFS=$'\t' read -r name root; do
    [[ -n "$name" ]] || continue

    if [[ "$root" == "$prefix" ]]; then
      opt_n=$((opt_n + 1))
    elif [[ -n "$source_tree" && "$root" == "$source_tree" ]]; then
      dev_n=$((dev_n + 1))
    else
      other_n=$((other_n + 1))
    fi
  done < <(install_link_census "$bindir")

  printf 'bin:   %s\n' "$bindir"
  printf 'opt:   %s -- %s link(s)\n' "$prefix" "$opt_n"
  printf 'dev:   %s -- %s link(s)\n' "$dev_label" "$dev_n"
  printf 'other: %s link(s), which relink leaves alone\n' "$other_n"
}

install_usage_use() {
  cat <<'USAGE'
Usage: utilz use [dev|opt] [--bin-dir DIR]

Switch which tree the PATH symlinks serve.

  utilz use opt   Point them at install.prefix from opt/utilz/utilz.yaml
  utilz use dev   Point them at the source tree the install was published from
  utilz use       Report which tree they serve now, and change nothing

  --bin-dir DIR   Where the links live. Default: ~/.local/bin

No path is typed either way: each tree carries the address of the other.
USAGE
}

# `utilz use dev|opt` -- the two-word switch (AC17).
#
# A THIN COORDINATOR OVER relink, and there is exactly one relinker. This
# parses a word to a tree, calls relink, and renders. If it ever grows a
# link-walk, a skip policy or a report of its own, it has gone wrong.
install_verb_use() {
  local word=""
  local bindir=""
  local src="$UTILZ_HOME"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      dev | opt)
        word="$1"
        shift
        ;;
      --bin-dir)
        if [[ $# -lt 2 ]]; then
          error "--bin-dir requires a DIR argument"
          return 2
        fi
        bindir=$(expand_tilde "$2")
        shift 2
        ;;
      -h | --help)
        install_usage_use
        return 0
        ;;
      *)
        error "Unknown argument: $1"
        echo "  utilz use takes the word 'dev' or 'opt', or no word at all." >&2
        return 2
        ;;
    esac
  done

  if [[ -z "$bindir" ]]; then
    bindir="$HOME/.local/bin"
  fi

  if [[ -z "$word" ]]; then
    install_use_report "$src" "$bindir"
    return $?
  fi

  local tree
  tree=$(_install_use_tree "$word" "$src") || return 1

  install_verb_relink --prefix "$tree" --bin-dir "$bindir"
}
