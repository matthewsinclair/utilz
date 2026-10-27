#!/usr/bin/env bats
# use.bats - `utilz use [dev|opt|brew]`, the one switch (dev, opt, brew contract
# T5, issue 0105), and what is left of ST0014/WP-12's relink inside it
#
# AC11 and AC20 are one policy from two sides: never implicitly, always
# available explicitly. install writes nothing outside the prefix (AT12, in
# install.bats); `use` is the verb the operator types when they do want the
# cutover. It points every link of the set at dev or opt, and `use brew`
# removes them, so Homebrew's links answer: no link means brew. relink, which
# did the pointing with a tree typed, is retired as a public verb.
#
# Every test uses a FIXTURE link directory, by --bin-dir or the test helper's
# UTILZ_LINK_DIR. Nothing here may touch the real ~/.local/bin.
#
# Every use-brew test sets PATH itself and names a stub brew: the harness's
# PATH can reach a real Homebrew utilz, which would answer for the fixture. So
# does every bare use that finds no link, since it asks brew too (issue 0112).

load "test_helper.bash"

# `run --separate-stderr` below needs bats >= 1.5.0; without this declaration
# bats warns BW02 on every run.
bats_require_minimum_version 1.5.0

# A link directory carrying both link shapes plus one link that is nobody's.
make_fake_bin() {
  local bindir="$1" tree="$2"
  mkdir -p "$bindir"

  # The ordinary shape: absolute, to its own name.
  ln -s "$tree/bin/alpha" "$bindir/alpha"
  # The odd shape ~/.local/bin/prez actually has: RELATIVE, and pointing at the
  # DISPATCHER rather than at bin/<name>. It works because dispatch keys on
  # basename "$0".
  ln -s "../$(basename "$tree")/bin/utilz" "$bindir/beta"
  ln -s "$tree/bin/utilz" "$bindir/utilz"

  make_stranger_link "$bindir"
}

# Nobody's link in <bindir>: one into a tree that is not Utilz at all, as
# another tool's link in ~/.local/bin is.
make_stranger_link() {
  local bindir="$1"
  mkdir -p "$bindir" "$BATS_TEST_TMPDIR/elsewhere"
  printf '#!/usr/bin/env bash\n' > "$BATS_TEST_TMPDIR/elsewhere/stranger"
  chmod +x "$BATS_TEST_TMPDIR/elsewhere/stranger"
  ln -s "$BATS_TEST_TMPDIR/elsewhere/stranger" "$bindir/stranger"
}

# A dev tree at <src> with its opt prefix set to <prefix> and published there,
# and a fixture link directory whose links serve the dev tree.
make_two_trees() {
  local src="$1" prefix="$2" bindir="$3"
  make_fake_src "$src"
  set_prefix_key "$src" "$prefix"
  run_install_function "UTILZ_HOME='$src'; install_verb_install --prefix '$prefix'" >/dev/null
  make_fake_bin "$bindir" "$src"
}

# Echo the directory each of <names> in <bindir> resolves into, one per line.
link_dirs() {
  local bindir="$1" link
  shift
  for link in "$@"; do
    (cd "$bindir" && cd "$(dirname "$(readlink "$link")")" && pwd)
  done
}

# A Homebrew prefix at <prefix> holding a keg published from <src>, laid out as
# the formula and brew lay one out, and a stub brew at <stub> whose --prefix
# answers it. The formula's bin.install_symlink gives the keg a bin/<name> for
# every entry of libexec/bin, pointing at ../libexec/bin/<name>; brew keeps the
# opt link; and a linked keg has <prefix>/bin/<name> pointing at
# ../Cellar/utilz/9.9.9/bin/<name> for each. With "unlinked" there are no
# <prefix>/bin links and the opt link stays, as `brew unlink utilz` leaves it.
make_fake_brew() {
  local src="$1" prefix="$2" stub="$3" linked="${4:-linked}"
  local cellar="$prefix/Cellar/utilz/9.9.9" entry name
  run_install_function "UTILZ_HOME='$src'; install_verb_install --prefix '$cellar/libexec' --managed-by brew" >/dev/null
  mkdir -p "$cellar/bin" "$prefix/opt" "$prefix/bin"
  for entry in "$cellar/libexec/bin"/*; do
    name=$(basename "$entry")
    ln -s "../libexec/bin/$name" "$cellar/bin/$name"
    if [[ "$linked" == "linked" ]]; then
      ln -s "../Cellar/utilz/9.9.9/bin/$name" "$prefix/bin/$name"
    fi
  done
  ln -s ../Cellar/utilz/9.9.9 "$prefix/opt/utilz"
  printf '#!/bin/sh\n[ "$1" = --prefix ] && echo %s\n' "$prefix" > "$stub"
  chmod +x "$stub"
}

# An executable at <dir>/<name> that is no Utilz tree's: another copy.
make_other_copy() {
  mkdir -p "$1"
  printf '#!/bin/sh\necho other\n' > "$1/$2"
  chmod +x "$1/$2"
}

# The refusal's contract (contract T5, amendment A4): exit 1, nothing on
# stdout, and the link directory exactly as <before>, its link_stamps, had it.
assert_refused_unchanged() {
  local bindir="$1" before="$2"
  assert_exit_code 1
  [[ -z "$output" ]] || fail "the refusal printed on stdout: $output"
  [[ "$(link_stamps "$bindir")" == "$before" ]] || fail "a refused use brew changed $bindir: $(link_stamps "$bindir")"
}

# Fail unless the last run's stderr is exactly the lines given, one argument
# each, in the order printed: a line missing, added or out of place fails it.
assert_stderr_is() {
  local want
  want=$(printf '%s\n' "$@")
  [[ "$stderr" == "$want" ]] || fail "stderr is not the lines expected (< expected, > printed):
$(diff <(printf '%s\n' "$want") <(printf '%s\n' "$stderr"))"
}

# ============================================================================
# use dev|opt points the whole set, and leaves alone what is not ours
# ============================================================================

@test "use opt repoints every Utilz link into the opt tree" {
  local src="$BATS_TEST_TMPDIR/src" prefix="$BATS_TEST_TMPDIR/opt" bindir="$BATS_TEST_TMPDIR/bin"
  make_two_trees "$src" "$prefix" "$bindir"

  run run_install_function "UTILZ_HOME='$src'; install_verb_use opt --bin-dir '$bindir'"
  assert_success
  [[ "$(link_dirs "$bindir" alpha beta utilz | sort -u)" == "$prefix/bin" ]] || fail "the links resolve into: $(link_dirs "$bindir" alpha beta utilz)"
  # And it ends with the tree's version line (contract T5).
  assert_output_contains "(opt, "
}

@test "use leaves the odd-shaped link dispatching as itself" {
  # beta points at the DISPATCHER, not at bin/beta. Repointing it must keep
  # that: changing the target's basename would be normalising a convention
  # under cover of a command asked to do something else (ST0014 design.md D9).
  local src="$BATS_TEST_TMPDIR/src-odd" prefix="$BATS_TEST_TMPDIR/opt-odd" bindir="$BATS_TEST_TMPDIR/bin-odd"
  make_two_trees "$src" "$prefix" "$bindir"

  run run_install_function "UTILZ_HOME='$src'; install_verb_use opt --bin-dir '$bindir'"
  assert_success
  [[ "$(basename "$(readlink "$bindir/beta")")" == "utilz" ]] || fail "beta now points at $(readlink "$bindir/beta") -- its shape was normalised"
  [[ "$(basename "$(readlink "$bindir/alpha")")" == "alpha" ]]
}

@test "use leaves a link that is nobody's alone, and reports it skipped" {
  local src="$BATS_TEST_TMPDIR/src-skip" prefix="$BATS_TEST_TMPDIR/opt-skip" bindir="$BATS_TEST_TMPDIR/bin-skip"
  make_two_trees "$src" "$prefix" "$bindir"
  local before
  before=$(readlink "$bindir/stranger")

  run run_install_function "UTILZ_HOME='$src'; install_verb_use opt --bin-dir '$bindir'"
  assert_success
  [[ "$(readlink "$bindir/stranger")" == "$before" ]] || fail "a link that is nobody's was rewritten"
}

@test "use REPORTS what it changed, and is idempotent" {
  local src="$BATS_TEST_TMPDIR/src-rep" prefix="$BATS_TEST_TMPDIR/opt-rep" bindir="$BATS_TEST_TMPDIR/bin-rep"
  make_two_trees "$src" "$prefix" "$bindir"

  run run_install_function "UTILZ_HOME='$src'; install_verb_use opt --bin-dir '$bindir'"
  assert_success
  assert_output_contains "relinked:  alpha"
  assert_output_contains "relinked:  beta"

  run run_install_function "UTILZ_HOME='$src'; install_verb_use opt --bin-dir '$bindir'"
  assert_success
  assert_output_contains "unchanged: alpha"
  refute_output_contains "relinked"
}

@test "use dev and use opt link the whole set into an empty link directory, creating it (contract T5)" {
  # A brew-only user has no links and may have no ~/.local/bin. `use dev`
  # points EVERY link of the set, so it makes them; until 0105 relink made
  # links only where a Utilz link already was.
  local src="$BATS_TEST_TMPDIR/src-empty" bindir="$BATS_TEST_TMPDIR/new-link-dir"
  make_fake_src "$src"

  run run_install_function "set -euo pipefail; UTILZ_HOME='$src'; install_verb_use dev --bin-dir '$bindir'"
  assert_success
  [[ "$(cd "$bindir" && echo *)" == "alpha beta utilz" ]] || fail "the link directory holds: $(cd "$bindir" && echo *)"
  [[ "$(link_dirs "$bindir" alpha beta utilz | sort -u)" == "$src/bin" ]] || fail "the links resolve into: $(link_dirs "$bindir" alpha beta utilz)"
}

@test "use leaves a file in a utility's place alone, and a link for a utility the tree lacks where it points (issue 0079)" {
  local src="$BATS_TEST_TMPDIR/src-safe" prefix="$BATS_TEST_TMPDIR/opt-safe" bindir="$BATS_TEST_TMPDIR/bin-safe"
  make_two_trees "$src" "$prefix" "$bindir"
  rm "$bindir/alpha"
  printf 'not utilz\n' > "$bindir/alpha"
  # gamma came to the dev tree after the install was published, with a link.
  ln -s utilz "$src/bin/gamma"
  ln -s "$src/bin/gamma" "$bindir/gamma"

  run run_install_function "set -euo pipefail; UTILZ_HOME='$src'; install_verb_use opt --bin-dir '$bindir'"
  assert_success
  assert_output_contains "skipped:   alpha (not a link)"
  [[ ! -L "$bindir/alpha" && "$(cat "$bindir/alpha")" == "not utilz" ]] || fail "the file in alpha's place was changed"
  assert_output_contains "skipped:   gamma (not in $prefix)"
  [[ "$(readlink "$bindir/gamma")" == "$src/bin/gamma" ]] || fail "gamma now points at $(readlink "$bindir/gamma")"
}

@test "use makes a relative UTILZ_INSTALL_PREFIX absolute, so every link it writes resolves (issue 0079)" {
  local src="$BATS_TEST_TMPDIR/src-rel" bindir="$BATS_TEST_TMPDIR/bin-rel"
  make_two_trees "$src" "$BATS_TEST_TMPDIR/opt-rel" "$bindir"
  rm "$bindir/alpha"

  # The suite's cwd is BATS_TEST_TMPDIR, so opt-rel names the install. A
  # relative target would be read from the link directory, where it names
  # nothing.
  run run_install_function "set -euo pipefail; UTILZ_INSTALL_PREFIX=opt-rel; UTILZ_HOME='$src'; install_verb_use opt --bin-dir '$bindir'"
  assert_success
  local link target
  for link in beta utilz alpha; do
    target=$(readlink "$bindir/$link") || target=""
    [[ "$target" == /* && -e "$bindir/$link" ]] || fail "$link -> '$target', which is relative or names nothing"
  done
}

@test "install and install --force leave the link directory untouched" {
  local src="$BATS_TEST_TMPDIR/src-ac11" new="$BATS_TEST_TMPDIR/new-ac11" bindir="$BATS_TEST_TMPDIR/bin-ac11"
  make_fake_src "$src"
  make_fake_bin "$bindir" "$src"

  local before after
  before=$(cd "$bindir" && for f in *; do printf '%s -> %s\n' "$f" "$(readlink "$f")"; done | LC_ALL=C sort)
  run run_install_function "UTILZ_HOME='$src'; install_verb_install --prefix '$new'"
  assert_success
  run run_install_function "UTILZ_HOME='$src'; install_verb_install --prefix '$new' --force"
  assert_success
  after=$(cd "$bindir" && for f in *; do printf '%s -> %s\n' "$f" "$(readlink "$f")"; done | LC_ALL=C sort)
  [[ "$before" == "$after" ]] || fail "install touched the link directory: $(diff <(printf '%s\n' "$before") <(printf '%s\n' "$after"))"
}

# ============================================================================
# dev and opt reach each other with no path typed
# ============================================================================

@test "AT17: the manifest header carries source_tree, the absolute path published from" {
  local src="$BATS_TEST_TMPDIR/moved-src" prefix="$BATS_TEST_TMPDIR/p-st"
  make_fake_src "$src"
  run run_install_function "UTILZ_HOME='$src'; install_verb_install --prefix '$prefix'"
  assert_success

  local recorded
  recorded=$(awk '/^# source_tree: / { print substr($0, 16); exit }' "$prefix/manifest.sha256")
  # It FOLLOWS the checkout rather than naming some canonical location.
  [[ "$recorded" == "$src" ]] || fail "source_tree is '$recorded', not $src"
}

@test "AT17: turnkey both ways, no path typed and no second key read" {
  local src="$BATS_TEST_TMPDIR/tk-src" prefix="$BATS_TEST_TMPDIR/tk-opt" bindir="$BATS_TEST_TMPDIR/tk-bin"
  make_two_trees "$src" "$prefix" "$bindir"

  run run_install_function "UTILZ_HOME='$src'; install_verb_use opt --bin-dir '$bindir'"
  assert_success
  [[ "$(link_dirs "$bindir" alpha beta utilz | sort -u)" == "$prefix/bin" ]] || fail "after 'use opt': $(link_dirs "$bindir" alpha beta utilz)"

  # From the opt install: back to dev, by the manifest's source_tree.
  run run_install_function "UTILZ_HOME='$prefix'; install_verb_use dev --bin-dir '$bindir'"
  assert_success
  [[ "$(link_dirs "$bindir" alpha beta utilz | sort -u)" == "$src/bin" ]] || fail "after 'use dev': $(link_dirs "$bindir" alpha beta utilz)"
}

@test "use opt refuses by name when there is no opt install, and when it has an old manifest" {
  local src="$BATS_TEST_TMPDIR/noinst-src" bindir="$BATS_TEST_TMPDIR/noinst-bin" prefix="$BATS_TEST_TMPDIR/nothing-published"
  make_fake_src "$src"
  set_prefix_key "$src" "$prefix"

  run run_install_function "UTILZ_HOME='$src'; install_verb_use opt --bin-dir '$bindir'"
  assert_exit_code 1
  assert_output_contains "no opt install at $prefix"
  assert_output_contains "utilz install"

  mkdir -p "$prefix"
  printf 'utilz-version\t2.10.0\nmanaged-by\tutilz\n' > "$prefix/manifest.sha256"
  run run_install_function "UTILZ_HOME='$src'; install_verb_use opt --bin-dir '$bindir'"
  assert_exit_code 1
  assert_output_contains "old manifest"
  assert_output_contains "install --force"
}

@test "use dev from opt refuses by name when the recorded dev checkout is gone" {
  local src="$BATS_TEST_TMPDIR/gone-src" prefix="$BATS_TEST_TMPDIR/gone-opt" bindir="$BATS_TEST_TMPDIR/gone-bin"
  make_two_trees "$src" "$prefix" "$bindir"
  rm -rf "$src"

  run run_install_function "UTILZ_HOME='$prefix'; install_verb_use dev --bin-dir '$bindir'"
  assert_exit_code 1
  assert_output_contains "no dev checkout at $src"
}

@test "use refuses a word that is not dev, opt or brew" {
  run run_install_function "install_verb_use sideways --bin-dir '$BATS_TEST_TMPDIR/bin'"
  assert_exit_code 2
  assert_output_contains "'dev', 'opt' or 'brew'"
}

# ============================================================================
# use brew: no link means brew
# ============================================================================

@test "use brew removes every Utilz link and nothing else, then names the Homebrew install (contract T5)" {
  local src="$BATS_TEST_TMPDIR/b-src" prefix="$BATS_TEST_TMPDIR/b-opt" bindir="$BATS_TEST_TMPDIR/b-bin"
  local brew="$BATS_TEST_TMPDIR/homebrew" stub="$BATS_TEST_TMPDIR/brew-stub"
  make_two_trees "$src" "$prefix" "$bindir"
  make_fake_brew "$src" "$brew" "$stub"
  local before
  before=$(readlink "$bindir/stranger")

  run run_install_function "set -euo pipefail; PATH='$bindir:$brew/bin:/usr/bin:/bin'; INSTALL_BREW='$stub'; UTILZ_HOME='$src'; install_verb_use brew --bin-dir '$bindir'"
  assert_success
  [[ "$(cd "$bindir" && echo *)" == "stranger" ]] || fail "the link directory still holds: $(cd "$bindir" && echo *)"
  [[ "$(readlink "$bindir/stranger")" == "$before" ]] || fail "use brew changed a link that is not Utilz's"
  # Another tool's link is neither touched nor counted (issue 0121).
  refute_output_contains "left alone"
  # The whole line, which names no path (issue 0109): the stub keg's version
  # and the commit its manifest records.
  local recorded
  recorded=$(manifest_source_commit "$brew/opt/utilz/libexec")
  [[ -n "$recorded" ]] || fail "the stub keg's manifest records no commit"
  printf '%s\n' "$output" | grep -qxF "utilz 9.9.9 (brew, ${recorded:0:12})" || fail "no version line 'utilz 9.9.9 (brew, ${recorded:0:12})': $output"
}

@test "use brew with no Utilz link says Homebrew's install already answers, with no removal header and no tally of other tools' links (issue 0121)" {
  local src="$BATS_TEST_TMPDIR/n-src" bindir="$BATS_TEST_TMPDIR/n-bin"
  local brew="$BATS_TEST_TMPDIR/homebrew" stub="$BATS_TEST_TMPDIR/brew-stub"
  make_fake_src "$src"
  make_fake_brew "$src" "$brew" "$stub"
  # Only another tool's link, as kovacs's ~/.local/bin held claude.
  make_stranger_link "$bindir"
  local before
  before=$(readlink "$bindir/stranger")

  run run_install_function "set -euo pipefail; PATH='$bindir:$brew/bin:/usr/bin:/bin'; INSTALL_BREW='$stub'; UTILZ_HOME='$src'; install_verb_use brew --bin-dir '$bindir'"
  assert_success
  assert_output_contains "no Utilz link in $bindir, so Homebrew's install already answers"
  refute_output_contains "removing"
  refute_output_contains "left alone"
  [[ "$(readlink "$bindir/stranger")" == "$before" ]] || fail "use brew changed a link that is not Utilz's"
  local recorded
  recorded=$(manifest_source_commit "$brew/opt/utilz/libexec")
  [[ -n "$recorded" ]] || fail "the stub keg's manifest records no commit"
  printf '%s\n' "$output" | grep -qxF "utilz 9.9.9 (brew, ${recorded:0:12})" || fail "no version line 'utilz 9.9.9 (brew, ${recorded:0:12})': $output"
}

@test "use brew refuses, removing nothing, when there is no Utilz formula under brew's prefix, naming each link and its tree (contract A4)" {
  local src="$BATS_TEST_TMPDIR/nf-src" prefix="$BATS_TEST_TMPDIR/nf-opt" bindir="$BATS_TEST_TMPDIR/nf-bin"
  local empty="$BATS_TEST_TMPDIR/empty-homebrew" stub="$BATS_TEST_TMPDIR/brew-stub"
  make_two_trees "$src" "$prefix" "$bindir"
  mkdir -p "$empty"
  printf '#!/bin/sh\necho %s\n' "$empty" > "$stub"
  chmod +x "$stub"
  local before
  before=$(link_stamps "$bindir")

  run --separate-stderr run_install_function "set -euo pipefail; PATH='$bindir:/usr/bin:/bin'; INSTALL_BREW='$stub'; UTILZ_HOME='$src'; install_verb_use brew --bin-dir '$bindir'"
  assert_refused_unchanged "$bindir" "$before"
  assert_stderr_is \
    "✗ use brew left the links in $bindir as they were: there is no Homebrew install of Utilz under $empty" \
    "  alpha -> dev at $src" \
    "  beta -> dev at $src" \
    "  utilz -> dev at $src" \
    "  Install the formula: brew install matthewsinclair/utilz/utilz" \
    "  Or stay on dev or opt: utilz use dev|opt"
}

@test "use brew refuses, removing nothing, when Homebrew is not installed or not on PATH, naming each link and its tree (contract A4)" {
  local src="$BATS_TEST_TMPDIR/nh-src" prefix="$BATS_TEST_TMPDIR/nh-opt" bindir="$BATS_TEST_TMPDIR/nh-bin"
  local nobrew="$BATS_TEST_TMPDIR/no-brew-here"
  make_two_trees "$src" "$prefix" "$bindir"
  local before
  before=$(link_stamps "$bindir")

  run --separate-stderr run_install_function "set -euo pipefail; PATH='$bindir:/usr/bin:/bin'; INSTALL_BREW='$nobrew'; UTILZ_HOME='$src'; install_verb_use brew --bin-dir '$bindir'"
  assert_refused_unchanged "$bindir" "$before"
  assert_stderr_is \
    "✗ use brew left the links in $bindir as they were: Homebrew is not installed, or is not on PATH ($nobrew --prefix answered nothing)" \
    "  alpha -> dev at $src" \
    "  beta -> dev at $src" \
    "  utilz -> dev at $src" \
    "  Install Homebrew, then the formula: brew install matthewsinclair/utilz/utilz" \
    "  Or, if Homebrew is installed, put its bin on PATH, in your shell config: eval \"\$(<brew's prefix>/bin/brew shellenv)\"" \
    "  Or stay on dev or opt: utilz use dev|opt"
}

@test "use brew refuses, removing nothing, when the Homebrew install has no copy of a linked utility (contract A4)" {
  local src="$BATS_TEST_TMPDIR/lk-src" prefix="$BATS_TEST_TMPDIR/lk-opt" bindir="$BATS_TEST_TMPDIR/lk-bin"
  local brew="$BATS_TEST_TMPDIR/homebrew" stub="$BATS_TEST_TMPDIR/brew-stub"
  make_two_trees "$src" "$prefix" "$bindir"
  make_fake_brew "$src" "$brew" "$stub"
  # A utility newer than the brew release: the dev tree has it, the keg not.
  ln -s utilz "$src/bin/gamma"
  ln -s "$src/bin/gamma" "$bindir/gamma"
  local before
  before=$(link_stamps "$bindir")

  run --separate-stderr run_install_function "set -euo pipefail; PATH='$bindir:$brew/bin:/usr/bin:/bin'; INSTALL_BREW='$stub'; UTILZ_HOME='$src'; install_verb_use brew --bin-dir '$bindir'"
  assert_refused_unchanged "$bindir" "$before"
  assert_stderr_is \
    "✗ use brew left the links in $bindir as they were: no Homebrew copy would answer once the links are gone" \
    "  alpha -> dev at $src" \
    "  beta -> dev at $src" \
    "  gamma -> dev at $src: the Homebrew install has no gamma" \
    "  utilz -> dev at $src" \
    "  Upgrade the formula once a release carries it: brew upgrade utilz" \
    "  Or stay on dev or opt: utilz use dev|opt"
}

@test "use brew refuses, removing nothing, at a dead link whose name the Homebrew install lacks, and names the link to remove, quoted (contract A4)" {
  # A dead link answers nothing now, so its remedy is to remove it, never to
  # wait for a release that need never carry the name. The link directory's
  # path holds a space, so the remedy is a command only when it is quoted.
  local src="$BATS_TEST_TMPDIR/dl-src" prefix="$BATS_TEST_TMPDIR/dl-opt" bindir="$BATS_TEST_TMPDIR/dl bin"
  local brew="$BATS_TEST_TMPDIR/homebrew" stub="$BATS_TEST_TMPDIR/brew-stub"
  [[ "$(printf '%q' "$BATS_TEST_TMPDIR")" == "$BATS_TEST_TMPDIR" ]] || fail "BATS_TEST_TMPDIR needs quoting itself: $BATS_TEST_TMPDIR"
  make_two_trees "$src" "$prefix" "$bindir"
  make_fake_brew "$src" "$brew" "$stub"
  # gamma is a utility of the current tree that the keg lacks, so a link to it
  # in a tree that has gone is Utilz's. A dead link to a name outside the set
  # is another tool's, and use brew leaves it be (utilz-vc's F1): rg's is not
  # named below.
  ln -s utilz "$src/bin/gamma"
  ln -s "$BATS_TEST_TMPDIR/gone/bin/gamma" "$bindir/gamma"
  ln -s "$BATS_TEST_TMPDIR/old-tool/bin/rg" "$bindir/rg"
  local before
  before=$(link_stamps "$bindir")

  run --separate-stderr run_install_function "set -euo pipefail; PATH='$bindir:$brew/bin:/usr/bin:/bin'; INSTALL_BREW='$stub'; UTILZ_HOME='$src'; install_verb_use brew --bin-dir '$bindir'"
  assert_refused_unchanged "$bindir" "$before"
  assert_stderr_is \
    "✗ use brew left the links in $bindir as they were: no Homebrew copy would answer once the links are gone" \
    "  alpha -> dev at $src" \
    "  beta -> dev at $src" \
    "  gamma -> $BATS_TEST_TMPDIR/gone/bin/gamma, which has gone: the Homebrew install has no gamma" \
    "  utilz -> dev at $src" \
    "  Remove the dead link: rm $BATS_TEST_TMPDIR/dl\\ bin/gamma" \
    "  Or stay on dev or opt: utilz use dev|opt"
}

@test "use brew refuses with mixed reasons, each link's line in the census's order and each remedy once in the reasons' order (utilz-vc's bank read)" {
  local src="$BATS_TEST_TMPDIR/mx-src" prefix="$BATS_TEST_TMPDIR/mx-opt" bindir="$BATS_TEST_TMPDIR/mx-bin"
  local brew="$BATS_TEST_TMPDIR/homebrew" stub="$BATS_TEST_TMPDIR/brew-stub" other="$BATS_TEST_TMPDIR/other-copies"
  make_two_trees "$src" "$prefix" "$bindir"
  make_fake_brew "$src" "$brew" "$stub"
  make_other_copy "$other" beta
  # Utilities newer than the brew release: gamma linked, and delta's link into
  # a tree that has gone, which is Utilz's since delta is in the set.
  ln -s utilz "$src/bin/gamma"
  ln -s utilz "$src/bin/delta"
  ln -s "$src/bin/gamma" "$bindir/gamma"
  ln -s "$BATS_TEST_TMPDIR/gone/bin/delta" "$bindir/delta"
  local before
  before=$(link_stamps "$bindir")

  run --separate-stderr run_install_function "set -euo pipefail; PATH='$bindir:$other:$brew/bin:/usr/bin:/bin'; INSTALL_BREW='$stub'; UTILZ_HOME='$src'; install_verb_use brew --bin-dir '$bindir'"
  assert_refused_unchanged "$bindir" "$before"
  assert_stderr_is \
    "✗ use brew left the links in $bindir as they were: no Homebrew copy would answer once the links are gone" \
    "  alpha -> dev at $src" \
    "  beta -> dev at $src: another copy comes first on PATH: $other/beta" \
    "  delta -> $BATS_TEST_TMPDIR/gone/bin/delta, which has gone: the Homebrew install has no delta" \
    "  gamma -> dev at $src: the Homebrew install has no gamma" \
    "  utilz -> dev at $src" \
    "  Upgrade the formula once a release carries it: brew upgrade utilz" \
    "  Remove the dead link: rm $bindir/delta" \
    "  Take each copy named above off PATH, or put $brew/bin before it (the sleeve's PATH order)" \
    "  Or stay on dev or opt: utilz use dev|opt"
}

@test "use brew refuses, removing nothing, when the Homebrew keg is not linked (contract A4)" {
  local src="$BATS_TEST_TMPDIR/ul-src" prefix="$BATS_TEST_TMPDIR/ul-opt" bindir="$BATS_TEST_TMPDIR/ul-bin"
  local brew="$BATS_TEST_TMPDIR/homebrew" stub="$BATS_TEST_TMPDIR/brew-stub"
  make_two_trees "$src" "$prefix" "$bindir"
  make_fake_brew "$src" "$brew" "$stub" unlinked
  local before
  before=$(link_stamps "$bindir")

  run --separate-stderr run_install_function "set -euo pipefail; PATH='$bindir:$brew/bin:/usr/bin:/bin'; INSTALL_BREW='$stub'; UTILZ_HOME='$src'; install_verb_use brew --bin-dir '$bindir'"
  assert_refused_unchanged "$bindir" "$before"
  assert_stderr_is \
    "✗ use brew left the links in $bindir as they were: no Homebrew copy would answer once the links are gone" \
    "  alpha -> dev at $src: the keg is not linked for alpha: $brew/bin/alpha does not resolve into it" \
    "  beta -> dev at $src: the keg is not linked for beta: $brew/bin/beta does not resolve into it" \
    "  utilz -> dev at $src: the keg is not linked for utilz: $brew/bin/utilz does not resolve into it" \
    "  Link the formula into brew's bin: brew link utilz" \
    "  Or stay on dev or opt: utilz use dev|opt"
}

@test "use brew refuses, removing nothing, when a link loop stands at a name in brew's bin, and does not hang (utilz-vc's P2)" {
  local src="$BATS_TEST_TMPDIR/lp-src" prefix="$BATS_TEST_TMPDIR/lp-opt" bindir="$BATS_TEST_TMPDIR/lp-bin"
  local brew="$BATS_TEST_TMPDIR/homebrew" stub="$BATS_TEST_TMPDIR/brew-stub"
  make_two_trees "$src" "$prefix" "$bindir"
  make_fake_brew "$src" "$brew" "$stub" unlinked
  ln -s alpha "$brew/bin/alpha"
  local before
  before=$(link_stamps "$bindir")

  run --separate-stderr run_install_function "set -euo pipefail; PATH='$bindir:$brew/bin:/usr/bin:/bin'; INSTALL_BREW='$stub'; UTILZ_HOME='$src'; install_verb_use brew --bin-dir '$bindir'"
  assert_refused_unchanged "$bindir" "$before"
  assert_stderr_is \
    "✗ use brew left the links in $bindir as they were: no Homebrew copy would answer once the links are gone" \
    "  alpha -> dev at $src: the keg is not linked for alpha: $brew/bin/alpha does not resolve into it" \
    "  beta -> dev at $src: the keg is not linked for beta: $brew/bin/beta does not resolve into it" \
    "  utilz -> dev at $src: the keg is not linked for utilz: $brew/bin/utilz does not resolve into it" \
    "  Link the formula into brew's bin: brew link utilz" \
    "  Or stay on dev or opt: utilz use dev|opt"
}

@test "use brew refuses, removing nothing, when Homebrew's bin is not on PATH (contract A4)" {
  local src="$BATS_TEST_TMPDIR/op-src" prefix="$BATS_TEST_TMPDIR/op-opt" bindir="$BATS_TEST_TMPDIR/op-bin"
  local brew="$BATS_TEST_TMPDIR/homebrew" stub="$BATS_TEST_TMPDIR/brew-stub"
  make_two_trees "$src" "$prefix" "$bindir"
  make_fake_brew "$src" "$brew" "$stub"
  local before
  before=$(link_stamps "$bindir")

  run --separate-stderr run_install_function "set -euo pipefail; PATH='$bindir:/usr/bin:/bin'; INSTALL_BREW='$stub'; UTILZ_HOME='$src'; install_verb_use brew --bin-dir '$bindir'"
  assert_refused_unchanged "$bindir" "$before"
  assert_stderr_is \
    "✗ use brew left the links in $bindir as they were: no Homebrew copy would answer once the links are gone" \
    "  alpha -> dev at $src: Homebrew's bin, $brew/bin, is not on PATH" \
    "  beta -> dev at $src: Homebrew's bin, $brew/bin, is not on PATH" \
    "  utilz -> dev at $src: Homebrew's bin, $brew/bin, is not on PATH" \
    "  Put brew's bin on PATH, in your shell config: eval \"\$($brew/bin/brew shellenv)\"" \
    "  Or stay on dev or opt: utilz use dev|opt"
}

@test "use brew refuses, removing nothing, when another copy of one utility comes first on PATH, naming that one alone (contract A4)" {
  local src="$BATS_TEST_TMPDIR/oc-src" prefix="$BATS_TEST_TMPDIR/oc-opt" bindir="$BATS_TEST_TMPDIR/oc-bin"
  local brew="$BATS_TEST_TMPDIR/homebrew" stub="$BATS_TEST_TMPDIR/brew-stub" other="$BATS_TEST_TMPDIR/other-copies"
  make_two_trees "$src" "$prefix" "$bindir"
  make_fake_brew "$src" "$brew" "$stub"
  make_other_copy "$other" beta
  local before
  before=$(link_stamps "$bindir")

  run --separate-stderr run_install_function "set -euo pipefail; PATH='$bindir:$other:$brew/bin:/usr/bin:/bin'; INSTALL_BREW='$stub'; UTILZ_HOME='$src'; install_verb_use brew --bin-dir '$bindir'"
  assert_refused_unchanged "$bindir" "$before"
  # alpha and utilz would be the Homebrew install's: each line names its tree
  # and no reason.
  assert_stderr_is \
    "✗ use brew left the links in $bindir as they were: no Homebrew copy would answer once the links are gone" \
    "  alpha -> dev at $src" \
    "  beta -> dev at $src: another copy comes first on PATH: $other/beta" \
    "  utilz -> dev at $src" \
    "  Take each copy named above off PATH, or put $brew/bin before it (the sleeve's PATH order)" \
    "  Or stay on dev or opt: utilz use dev|opt"
}

@test "use brew refuses, removing nothing, when a dev checkout's bin comes before Homebrew's on PATH, naming the checkout's tree (contract A4)" {
  local src="$BATS_TEST_TMPDIR/db-src" prefix="$BATS_TEST_TMPDIR/db-opt" bindir="$BATS_TEST_TMPDIR/db-bin"
  local brew="$BATS_TEST_TMPDIR/homebrew" stub="$BATS_TEST_TMPDIR/brew-stub"
  make_two_trees "$src" "$prefix" "$bindir"
  make_fake_brew "$src" "$brew" "$stub"
  local before
  before=$(link_stamps "$bindir")

  run --separate-stderr run_install_function "set -euo pipefail; PATH='$bindir:$src/bin:$brew/bin:/usr/bin:/bin'; INSTALL_BREW='$stub'; UTILZ_HOME='$src'; install_verb_use brew --bin-dir '$bindir'"
  assert_refused_unchanged "$bindir" "$before"
  assert_stderr_is \
    "✗ use brew left the links in $bindir as they were: no Homebrew copy would answer once the links are gone" \
    "  alpha -> dev at $src: another copy comes first on PATH: $src/bin/alpha (dev at $src)" \
    "  beta -> dev at $src: another copy comes first on PATH: $src/bin/beta (dev at $src)" \
    "  utilz -> dev at $src: another copy comes first on PATH: $src/bin/utilz (dev at $src)" \
    "  Take each copy named above off PATH, or put $brew/bin before it (the sleeve's PATH order)" \
    "  Or stay on dev or opt: utilz use dev|opt"
}

@test "use brew asks about utilz even with no Utilz link to it, looking it up on PATH as it stands (contract A4)" {
  local src="$BATS_TEST_TMPDIR/nu-src" prefix="$BATS_TEST_TMPDIR/nu-opt" bindir="$BATS_TEST_TMPDIR/nu-bin"
  local brew="$BATS_TEST_TMPDIR/homebrew" stub="$BATS_TEST_TMPDIR/brew-stub" other="$BATS_TEST_TMPDIR/other-copies"
  make_two_trees "$src" "$prefix" "$bindir"
  make_fake_brew "$src" "$brew" "$stub"
  rm "$bindir/utilz"
  make_other_copy "$other" utilz
  local before
  before=$(link_stamps "$bindir")

  run --separate-stderr run_install_function "set -euo pipefail; PATH='$bindir:$other:$brew/bin:/usr/bin:/bin'; INSTALL_BREW='$stub'; UTILZ_HOME='$src'; install_verb_use brew --bin-dir '$bindir'"
  assert_refused_unchanged "$bindir" "$before"
  assert_stderr_is \
    "✗ use brew left the links in $bindir as they were: no Homebrew copy would answer once the links are gone" \
    "  alpha -> dev at $src" \
    "  beta -> dev at $src" \
    "  utilz (no Utilz link): another copy comes first on PATH: $other/utilz" \
    "  Take each copy named above off PATH, or put $brew/bin before it (the sleeve's PATH order)" \
    "  Or stay on dev or opt: utilz use dev|opt"

  # A utilz in the link directory that is not a Utilz link stays, and goes on
  # answering, so the link directory is not dropped for it.
  make_other_copy "$bindir" utilz
  before=$(link_stamps "$bindir")
  run --separate-stderr run_install_function "set -euo pipefail; PATH='$bindir:$brew/bin:/usr/bin:/bin'; INSTALL_BREW='$stub'; UTILZ_HOME='$src'; install_verb_use brew --bin-dir '$bindir'"
  assert_refused_unchanged "$bindir" "$before"
  assert_stderr_is \
    "✗ use brew left the links in $bindir as they were: no Homebrew copy would answer once the links are gone" \
    "  alpha -> dev at $src" \
    "  beta -> dev at $src" \
    "  utilz (no Utilz link): another copy comes first on PATH: $bindir/utilz" \
    "  Take each copy named above off PATH, or put $brew/bin before it (the sleeve's PATH order)" \
    "  Or stay on dev or opt: utilz use dev|opt"
}

@test "use brew refuses, removing nothing, when a name's check cannot finish, naming the name and its status (issue 0112)" {
  local src="$BATS_TEST_TMPDIR/vf-src" prefix="$BATS_TEST_TMPDIR/vf-opt" bindir="$BATS_TEST_TMPDIR/vf-bin"
  local brew="$BATS_TEST_TMPDIR/homebrew" stub="$BATS_TEST_TMPDIR/brew-stub"
  make_two_trees "$src" "$prefix" "$bindir"
  make_fake_brew "$src" "$brew" "$stub"
  local before
  before=$(link_stamps "$bindir")

  # The verdict redefined to fail, as arngz.bats redefines check_app.
  run --separate-stderr run_install_function "set -euo pipefail; PATH='$bindir:$brew/bin:/usr/bin:/bin'; INSTALL_BREW='$stub'; UTILZ_HOME='$src'; _install_brew_verdict() { return 3; }; install_verb_use brew --bin-dir '$bindir'"
  assert_refused_unchanged "$bindir" "$before"
  assert_stderr_is "✗ use brew could not check alpha (its check exited 3), so it removed nothing"
}

@test "use brew's PATH filter reads an entry written with a leading ~ from HOME, and keeps it as written (issue 0112)" {
  local home="$BATS_TEST_TMPDIR/tl-home"
  mkdir -p "$home/.local/bin" "$home/other"

  run run_install_function "set -euo pipefail; HOME='$home'; PATH='~/.local/bin:~/other:/usr/bin:/bin'; _install_path_without '$home/.local/bin'"
  assert_success
  [[ "$output" == \~/other:/usr/bin:/bin ]] || fail "the filter answered: $output"
}

@test "use brew drops a PATH entry that links to the link directory, compared by resolved directory (utilz-vc's W3)" {
  local src="$BATS_TEST_TMPDIR/w3b-src" prefix="$BATS_TEST_TMPDIR/w3b-opt" bindir="$BATS_TEST_TMPDIR/w3b-bin"
  local brew="$BATS_TEST_TMPDIR/homebrew" stub="$BATS_TEST_TMPDIR/brew-stub"
  make_two_trees "$src" "$prefix" "$bindir"
  make_fake_brew "$src" "$brew" "$stub"
  # rhadamanth's shape: PATH names ~/bin, a link to ~/.local/bin.
  ln -s "$bindir" "$BATS_TEST_TMPDIR/home-bin"

  run run_install_function "set -euo pipefail; PATH='$BATS_TEST_TMPDIR/home-bin:$brew/bin:/usr/bin:/bin'; INSTALL_BREW='$stub'; UTILZ_HOME='$src'; install_verb_use brew --bin-dir '$bindir'"
  assert_success
  [[ "$(cd "$bindir" && echo *)" == "stranger" ]] || fail "the link directory still holds: $(cd "$bindir" && echo *)"
  printf '%s\n' "$output" | grep -qxE 'utilz 9\.9\.9 \(brew, [0-9a-f]{12}\)' || fail "no version line 'utilz 9.9.9 (brew, <sha12>)': $output"
}

@test "bare use reports brew when there is no link and the install brew names answers on PATH, and not for another keg" {
  local src="$BATS_TEST_TMPDIR/nl-src" brew="$BATS_TEST_TMPDIR/homebrew" stub="$BATS_TEST_TMPDIR/brew-stub"
  local brew2="$BATS_TEST_TMPDIR/homebrew2" stub2="$BATS_TEST_TMPDIR/brew-stub2"
  make_fake_src "$src"
  make_fake_brew "$src" "$brew" "$stub"

  run run_install_function "set -euo pipefail; PATH='$brew/bin:/usr/bin:/bin'; INSTALL_BREW='$stub'; UTILZ_HOME='$src'; install_verb_use --bin-dir '$BATS_TEST_TMPDIR/no-links'"
  assert_success
  assert_output_contains "brew: no links, and $brew/bin/utilz (the Homebrew install) answers"

  # A keg on PATH that is not the install brew --prefix names.
  make_fake_brew "$src" "$brew2" "$stub2"
  run run_install_function "set -euo pipefail; PATH='$brew2/bin:/usr/bin:/bin'; INSTALL_BREW='$stub'; UTILZ_HOME='$src'; install_verb_use --bin-dir '$BATS_TEST_TMPDIR/no-links'"
  assert_success
  assert_output_contains "no links; $brew2/bin/utilz answers, which is not the Homebrew install"
}

@test "bare use with no link and no Homebrew at all prints the not-brew line, and nothing from the missing brew (issue 0112)" {
  local src="$BATS_TEST_TMPDIR/nb2-src" brew="$BATS_TEST_TMPDIR/homebrew" stub="$BATS_TEST_TMPDIR/brew-stub"
  make_fake_src "$src"
  make_fake_brew "$src" "$brew" "$stub"

  run --separate-stderr run_install_function "set -euo pipefail; PATH='$brew/bin:/usr/bin:/bin'; INSTALL_BREW='$BATS_TEST_TMPDIR/no-brew-here'; UTILZ_HOME='$src'; install_verb_use --bin-dir '$BATS_TEST_TMPDIR/no-links'"
  assert_success
  assert_output_contains "no links; $brew/bin/utilz answers, which is not the Homebrew install"
  [[ -z "$stderr" ]] || fail "bare use printed on stderr: $stderr"
}

# ============================================================================
# the report, and the shadow and split checks
# ============================================================================

# Each link in <dir> with its own inode and mtime, one per line, sorted. A
# repoint replaces the link, so the inode moves even within the same second.
# GNU's form is tried first because GNU `stat -f` is not an error: it reports
# the FILESYSTEM, whose free-block count moves whenever anything else on the
# runner writes, and that read as a relink on CI (run 39036616338, 17 Oct).
link_stamps() {
  local f stamp listing=""
  for f in "$1"/*; do
    stamp=$(stat -c '%i %Y' "$f" 2>/dev/null || stat -f '%i %m' "$f") || return 1
    listing+="${f##*/} $stamp"$'\n'
  done
  printf '%s' "$listing" | LC_ALL=C sort
}

@test "AT17: bare use REPORTS and changes nothing, asserted by mtime" {
  # A switch you cannot interrogate is one you run in order to find out where
  # you are. Asserted by link mtime rather than by the output looking right:
  # a report that repointed first would print exactly the same thing.
  local src="$BATS_TEST_TMPDIR/rep-src" prefix="$BATS_TEST_TMPDIR/rep-opt" bindir="$BATS_TEST_TMPDIR/rep-bin"
  make_two_trees "$src" "$prefix" "$bindir"

  local before after
  before=$(link_stamps "$bindir")
  run run_install_function "set -euo pipefail; PATH='$bindir:/usr/bin:/bin'; UTILZ_HOME='$src'; install_verb_use --bin-dir '$bindir'"
  assert_success
  assert_output_contains "dev at $src"
  assert_output_contains "opt:   $prefix"
  after=$(link_stamps "$bindir")
  [[ "$before" == "$after" ]] || fail "bare 'use' changed link mtimes: $(diff <(printf '%s\n' "$before") <(printf '%s\n' "$after"))"
}

@test "AT17: bare use tells 'no install' apart from 'an old manifest'" {
  # Found LIVE, not by a test, which is why it is a test now: the first draft
  # reported an install published before the source-tree row as no install at
  # all. Since issue 0105 the middle answer is the old manifest form, which is
  # not read for its source tree (contract T3).
  local src="$BATS_TEST_TMPDIR/3w-src" prefix="$BATS_TEST_TMPDIR/3w-opt" bindir="$BATS_TEST_TMPDIR/3w-bin"
  make_fake_src "$src"
  set_prefix_key "$src" "$prefix"
  mkdir -p "$bindir"

  run run_install_function "set -euo pipefail; PATH='/usr/bin:/bin'; INSTALL_BREW='$BATS_TEST_TMPDIR/no-brew-here'; UTILZ_HOME='$src'; install_verb_use --bin-dir '$bindir'"
  assert_success
  assert_output_contains "no install at $prefix"

  mkdir -p "$prefix"
  printf 'utilz-version\t2.10.0\nsource-tree\t%s\nmanaged-by\tutilz\n' "$src" > "$prefix/manifest.sha256"
  run run_install_function "set -euo pipefail; PATH='/usr/bin:/bin'; INSTALL_BREW='$BATS_TEST_TMPDIR/no-brew-here'; UTILZ_HOME='$src'; install_verb_use --bin-dir '$bindir'"
  assert_success
  assert_output_contains "old manifest at $prefix"
  refute_output_contains "no install at"

  run_install_function "UTILZ_HOME='$src'; install_verb_install --prefix '$prefix' --force" >/dev/null
  run run_install_function "set -euo pipefail; PATH='/usr/bin:/bin'; INSTALL_BREW='$BATS_TEST_TMPDIR/no-brew-here'; UTILZ_HOME='$src'; install_verb_use --bin-dir '$bindir'"
  assert_success
  assert_output_contains "opt:   $prefix"
  refute_output_contains "old manifest"
}

@test "bare use fails, naming what shadows a link, when a link is not the first hit on PATH (contract T5)" {
  local src="$BATS_TEST_TMPDIR/sh-src" brew="$BATS_TEST_TMPDIR/homebrew" stub="$BATS_TEST_TMPDIR/brew-stub"
  local bindir="$BATS_TEST_TMPDIR/sh-bin"
  make_fake_src "$src"
  make_fake_brew "$src" "$brew" "$stub"
  run_install_function "UTILZ_HOME='$src'; install_verb_use dev --bin-dir '$bindir'" >/dev/null

  # Homebrew's bin first, as rhadamanth's PATH had it on 24 Oct.
  run run_install_function "PATH='$brew/bin:$bindir:/usr/bin:/bin'; UTILZ_HOME='$src'; install_verb_use --bin-dir '$bindir'"
  assert_exit_code 1
  assert_output_contains "utilz in $bindir is shadowed: the first utilz on PATH is $brew/bin/utilz"

  # The link directory first: healthy.
  run run_install_function "PATH='$bindir:$brew/bin:/usr/bin:/bin'; UTILZ_HOME='$src'; install_verb_use --bin-dir '$bindir'"
  assert_success
  refute_output_contains "shadowed"

  # Compared by resolved directory: a PATH naming a link to the link directory
  # (rhadamanth's ~/bin) reaches the same links.
  ln -s "$bindir" "$BATS_TEST_TMPDIR/home-bin"
  run run_install_function "PATH='$BATS_TEST_TMPDIR/home-bin:$brew/bin:/usr/bin:/bin'; UTILZ_HOME='$src'; install_verb_use --bin-dir '$bindir'"
  assert_success
  refute_output_contains "shadowed"
}

@test "bare use and doctor fail, naming both trees, when the set is split across trees (contract T5)" {
  local src="$BATS_TEST_TMPDIR/sp-src" prefix="$BATS_TEST_TMPDIR/sp-opt" bindir="$BATS_TEST_TMPDIR/sp-bin"
  make_two_trees "$src" "$prefix" "$bindir"
  rm "$bindir/alpha"
  ln -s "$prefix/bin/alpha" "$bindir/alpha"

  run run_install_function "PATH='$bindir:/usr/bin:/bin'; UTILZ_HOME='$src'; install_verb_use --bin-dir '$bindir'"
  assert_exit_code 1
  assert_output_contains "split across trees; one points into $src"
  assert_output_contains "split across trees; one points into $prefix"

  # doctor reads the link set from the tree it runs in, the real one here.
  run run_install_function "PATH='$bindir:/usr/bin:/bin'; UTILZ_LINK_DIR='$bindir'; run_doctor"
  assert_failure
  assert_output_contains "the links in $bindir are split across trees"
}

@test "utilz relink is retired, naming use, and changes nothing (contract T5)" {
  local bindir="$BATS_TEST_TMPDIR/rt-bin"
  mkdir -p "$bindir"
  run "$UTILZ_BIN_DIR/utilz" relink --bin-dir "$bindir"
  assert_exit_code 2
  assert_output_contains "utilz relink is retired"
  assert_output_contains "utilz use dev|opt|brew"
  [[ -z "$(ls -A "$bindir")" ]] || fail "a retired relink wrote: $(ls -A "$bindir")"
}

# ============================================================================
# utilz-vc's warnings on d3dbb766: what the census calls ours
# ============================================================================

@test "a Utilz link into a tree that has gone is broken: use dev repoints it, and bare use and doctor fail naming it (utilz-vc's W1)" {
  local src="$BATS_TEST_TMPDIR/w1-src" gone="$BATS_TEST_TMPDIR/w1-gone" bindir="$BATS_TEST_TMPDIR/w1-bin"
  make_fake_src "$src"
  make_fake_src "$gone"
  make_fake_bin "$bindir" "$gone"
  # The tree the links name is removed, as a worktree is.
  rm -rf "$gone"

  run run_install_function "set -euo pipefail; PATH='$bindir:/usr/bin:/bin'; UTILZ_HOME='$src'; install_verb_use --bin-dir '$bindir'"
  assert_exit_code 1
  assert_output_contains "alpha in $bindir is a Utilz link into a tree that has gone: $gone/bin/alpha"

  run run_install_function "PATH='$bindir:/usr/bin:/bin'; UTILZ_LINK_DIR='$bindir'; run_doctor"
  assert_failure
  assert_output_contains "is a Utilz link into a tree that has gone"

  run run_install_function "set -euo pipefail; UTILZ_HOME='$src'; install_verb_use dev --bin-dir '$bindir'"
  assert_success
  assert_output_contains "relinked:  alpha -> $src/bin/alpha (it named $gone/bin/alpha, which has gone)"
  [[ "$(link_dirs "$bindir" alpha beta utilz | sort -u)" == "$src/bin" ]] || fail "the links resolve into: $(link_dirs "$bindir" alpha beta utilz)"
}

@test "use brew removes a broken Utilz link too, and nothing that is not Utilz's (utilz-vc's W1, W2)" {
  local src="$BATS_TEST_TMPDIR/w2-src" gone="$BATS_TEST_TMPDIR/w2-gone" bindir="$BATS_TEST_TMPDIR/w2-bin"
  local brew="$BATS_TEST_TMPDIR/homebrew" stub="$BATS_TEST_TMPDIR/brew-stub"
  make_fake_src "$src"
  make_fake_brew "$src" "$brew" "$stub"
  mkdir -p "$bindir"
  ln -s "$gone/bin/alpha" "$bindir/alpha"
  # A Utilz checkout's bin/ holds things that are not the dispatcher: a
  # vendored tool and a personal script, and a link to one of them.
  printf '#!/bin/sh\n' > "$src/bin/devbin"
  printf '#!/bin/sh\n' > "$src/bin/mine"
  ln -s mine "$src/bin/also-mine"
  ln -s "$src/bin/devbin" "$bindir/devbin"
  ln -s "$src/bin/mine" "$bindir/mine"
  ln -s "$src/bin/also-mine" "$bindir/also-mine"
  ln -s "$src/bin/utilz" "$bindir/utilz"
  # Another tool's link into a tree that has gone (utilz-vc's F1).
  ln -s "$BATS_TEST_TMPDIR/old-tool/bin/rg" "$bindir/rg"

  run run_install_function "set -euo pipefail; PATH='$bindir:$brew/bin:/usr/bin:/bin'; INSTALL_BREW='$stub'; UTILZ_HOME='$src'; install_verb_use brew --bin-dir '$bindir'"
  assert_success
  [[ "$(cd "$bindir" && echo *)" == "also-mine devbin mine rg" ]] || fail "the link directory holds: $(cd "$bindir" && echo *)"
  [[ ! -L "$bindir/alpha" ]] || fail "the broken Utilz link is still there"
}

@test "another tool's dangling link is not Utilz's: bare use and doctor leave it be (utilz-vc's F1)" {
  local src="$BATS_TEST_TMPDIR/f1-src" bindir="$BATS_TEST_TMPDIR/f1-bin"
  make_fake_src "$src"
  make_fake_bin "$bindir" "$src"
  ln -s "$BATS_TEST_TMPDIR/old-tool/bin/rg" "$bindir/rg"

  run run_install_function "set -euo pipefail; PATH='$bindir:/usr/bin:/bin'; UTILZ_HOME='$src'; install_verb_use --bin-dir '$bindir'"
  assert_success
  refute_output_contains "rg in $bindir"

  run run_install_function "PATH='$bindir:/usr/bin:/bin'; UTILZ_HOME='$src'; UTILZ_LINK_DIR='$bindir'; run_doctor"
  refute_output_contains "a Utilz link into a tree that has gone"
}

@test "two paths to one tree are one tree, never split (utilz-vc's W3)" {
  local src="$BATS_TEST_TMPDIR/w3-src" alias="$BATS_TEST_TMPDIR/w3-alias" bindir="$BATS_TEST_TMPDIR/w3-bin"
  make_fake_src "$src"
  ln -s "$src" "$alias"
  mkdir -p "$bindir"
  ln -s "$src/bin/utilz" "$bindir/utilz"
  ln -s "$alias/bin/alpha" "$bindir/alpha"
  ln -s "$src/bin/beta" "$bindir/beta"

  run run_install_function "set -euo pipefail; PATH='$bindir:/usr/bin:/bin'; UTILZ_HOME='$src'; install_verb_use --bin-dir '$bindir'"
  assert_success
  refute_output_contains "split"

  # And use dev reads both spellings as already pointing at the tree.
  run run_install_function "set -euo pipefail; UTILZ_HOME='$src'; install_verb_use dev --bin-dir '$bindir'"
  assert_success
  assert_output_contains "unchanged: alpha"
}
