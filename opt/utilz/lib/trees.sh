#!/usr/bin/env bash
# trees.sh - what the utilz dispatcher still needs about its trees, once devbin
# publishes and switches them (devbin#0326, issue I59c806c): the link set's
# census and health that doctor reports, the manifest check doctor reads, and
# `utilz upgrade`, which upgrades the tree it runs from.
#
# THE PUBLISH AND THE SWITCH ARE DEVBIN'S. `bin/devbin install` publishes the
# opt tree and the formula's keg, and `bin/devbin use dev|opt|brew` points the
# link set in ~/.local/bin, each run in a Utilz checkout (docs/dev-opt-brew.md
# in devbin, T2 and T5). `utilz install` and `utilz use` are retired refusals
# that name them.
#
# Sourced ONLY where it is needed, never unconditionally: doctor's link and
# manifest rows, and the upgrade verb. bin/utilz sources common.sh for every
# utility on every invocation, and folding this in would make every utility
# parse it for something only doctor and upgrade call (ST0014 design.md D1).
#
# Depends on common.sh, which defines utilz_tree, the manifest's name and its
# readers, and the output functions.

# The brew command `use brew` asks for brew's prefix, assigned here so only
# code that has sourced this file -- a test -- can point it anywhere else.
INSTALL_BREW="brew"

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

install_usage_upgrade() {
  cat <<'USAGE'
Usage: utilz upgrade

Upgrade the tree this utilz runs from, as that tree is upgraded:

  dev    git pull --ff-only, then bin/devbin build, which builds prez and
         showreel
  opt    nothing: opt is republished from its dev checkout with
         'bin/devbin install --force', and this says when dev is ahead
  brew   brew update, then HOMEBREW_NO_AUTO_UPDATE=1 brew upgrade utilz,
         when brew says it is outdated
USAGE
}

# `utilz upgrade` -- UPGRADE BY TREE (dev, opt, brew contract T6, issue 0105).
#
# It never publishes: devbin's `bin/devbin install --force`, run in the dev
# checkout, is the one republish (T2). What it does
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
      echo "  Republish it from the dev checkout with 'bin/devbin install --force'." >&2
      return 2
      ;;
    *)
      error "$UTILZ_HOME is no tree Utilz can name, so there is no upgrade for it"
      echo "  Install Utilz with Homebrew: $(brew_install_command)" >&2
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

  # The tool's build, the one devbin's publish runs too (T6: then the tool's
  # build where it has one): commands.build in bin/.devbin/config.yaml.
  (cd "$UTILZ_HOME" && bin/devbin build) || {
    error "bin/devbin build failed in $UTILZ_HOME"
    return 1
  }
  utilz_version_line
}

# opt: nothing written. It says how opt is upgraded, and when its dev checkout
# is ahead of what was published. rc 2: refused, nothing changed, as Utilz's
# refusals are. source_tree, the checkout an opt tree was published from, is
# in the manifest from devbin 0.1.31 (I79fb280) and only informs: with none,
# or one that is gone, the remedy names the dev checkout in words.
_install_upgrade_opt() {
  local manifest="$UTILZ_HOME/$UTILZ_MANIFEST_NAME" src commit head

  src=$(utilz_manifest_value "$manifest" source_tree 2>/dev/null) || src=""
  commit=$(utilz_manifest_value "$manifest" source_commit 2>/dev/null) || commit=""

  error "an opt install is upgraded from its dev checkout, never on its own"
  echo "  Republish it there: cd ${src:-<the dev checkout>} && bin/devbin install --force" >&2

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
  echo "  and make the set one tree with 'bin/devbin use dev|opt|brew', run in a Utilz checkout." >&2
}

# Find the Homebrew install of Utilz by its opt link, printing nothing of its
# own. Echo "<prefix><TAB><root>" and return 0, or echo why there is none,
# "<reason><TAB><words>", and return 1: nobrew when brew answers no prefix,
# noformula when there is no Utilz install under it.
#
# THE ONE FINDER (issue 0112): use brew's check, bare use's report and
# _install_brew_root all read it, so none of them can name another install.
_install_brew_find() {
  local prefix root
  if ! prefix=$("$INSTALL_BREW" --prefix 2>/dev/null) || [[ -z "$prefix" ]]; then
    printf 'nobrew\tHomebrew is not installed, or is not on PATH (%s --prefix answered nothing)\n' "$INSTALL_BREW"
    return 1
  fi
  root=$(brew_opt_root "$prefix")
  if [[ ! -x "$root/bin/utilz" ]]; then
    printf 'noformula\tthere is no Homebrew install of Utilz under %s\n' "$prefix"
    return 1
  fi
  printf '%s\t%s\n' "$prefix" "$root"
}

# Echo the Homebrew install's root, by its opt link, or return 1 by name.
_install_brew_root() {
  local found reason words
  if ! found=$(_install_brew_find); then
    IFS=$'\t' read -r reason words <<<"$found"
    error "$words"
    if [[ "$reason" == "noformula" ]]; then
      echo "  Install it: $(brew_install_command)" >&2
    fi
    return 1
  fi
  printf '%s\n' "${found#*$'\t'}"
}

