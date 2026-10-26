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

load "test_helper.bash"

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

  # Nobody's. A link into a tree that is not Utilz at all.
  mkdir -p "$BATS_TEST_TMPDIR/elsewhere"
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

# A Homebrew prefix at <prefix> holding a keg published from <src>, with the
# opt link brew keeps, and a stub brew at <stub> whose --prefix answers it.
make_fake_brew() {
  local src="$1" prefix="$2" stub="$3"
  local keg="$prefix/Cellar/utilz/9.9.9/libexec"
  run_install_function "UTILZ_HOME='$src'; install_verb_install --prefix '$keg' --managed-by brew" >/dev/null
  mkdir -p "$prefix/opt" "$prefix/bin"
  ln -s ../Cellar/utilz/9.9.9 "$prefix/opt/utilz"
  ln -s ../Cellar/utilz/9.9.9/libexec/bin/utilz "$prefix/bin/utilz"
  printf '#!/bin/sh\n[ "$1" = --prefix ] && echo %s\n' "$prefix" > "$stub"
  chmod +x "$stub"
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

  run run_install_function "set -euo pipefail; INSTALL_BREW='$stub'; UTILZ_HOME='$src'; install_verb_use brew --bin-dir '$bindir'"
  assert_success
  [[ "$(cd "$bindir" && echo *)" == "stranger" ]] || fail "the link directory still holds: $(cd "$bindir" && echo *)"
  [[ "$(readlink "$bindir/stranger")" == "$before" ]] || fail "use brew changed a link that is not Utilz's"
  # The whole line, which names no path (issue 0109): the stub keg's version
  # and the commit its manifest records.
  local recorded
  recorded=$(manifest_source_commit "$brew/opt/utilz/libexec")
  [[ -n "$recorded" ]] || fail "the stub keg's manifest records no commit"
  printf '%s\n' "$output" | grep -qxF "utilz 9.9.9 (brew, ${recorded:0:12})" || fail "no version line 'utilz 9.9.9 (brew, ${recorded:0:12})': $output"
}

@test "use brew refuses by name, and removes nothing, when there is no Homebrew install of Utilz" {
  local src="$BATS_TEST_TMPDIR/nb-src" prefix="$BATS_TEST_TMPDIR/nb-opt" bindir="$BATS_TEST_TMPDIR/nb-bin"
  local stub="$BATS_TEST_TMPDIR/brew-stub"
  make_two_trees "$src" "$prefix" "$bindir"
  printf '#!/bin/sh\necho %s\n' "$BATS_TEST_TMPDIR/empty-homebrew" > "$stub"
  chmod +x "$stub"

  run run_install_function "INSTALL_BREW='$stub'; UTILZ_HOME='$src'; install_verb_use brew --bin-dir '$bindir'"
  assert_exit_code 1
  assert_output_contains "brew install matthewsinclair/utilz/utilz"
  [[ -L "$bindir/alpha" ]] || fail "a refused use brew removed a link"

  run run_install_function "INSTALL_BREW='$BATS_TEST_TMPDIR/no-brew-here'; UTILZ_HOME='$src'; install_verb_use brew --bin-dir '$bindir'"
  assert_exit_code 1
  assert_output_contains "Homebrew is not installed"
}

@test "bare use reports brew when there is no link and the Homebrew install answers on PATH" {
  local src="$BATS_TEST_TMPDIR/nl-src" brew="$BATS_TEST_TMPDIR/homebrew" stub="$BATS_TEST_TMPDIR/brew-stub"
  make_fake_src "$src"
  make_fake_brew "$src" "$brew" "$stub"

  run run_install_function "set -euo pipefail; PATH='$brew/bin:/usr/bin:/bin'; UTILZ_HOME='$src'; install_verb_use --bin-dir '$BATS_TEST_TMPDIR/no-links'"
  assert_success
  assert_output_contains "brew: no links, and $brew/bin/utilz (the Homebrew install) answers"
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

  run run_install_function "UTILZ_HOME='$src'; install_verb_use --bin-dir '$bindir'"
  assert_success
  assert_output_contains "no install at $prefix"

  mkdir -p "$prefix"
  printf 'utilz-version\t2.10.0\nsource-tree\t%s\nmanaged-by\tutilz\n' "$src" > "$prefix/manifest.sha256"
  run run_install_function "UTILZ_HOME='$src'; install_verb_use --bin-dir '$bindir'"
  assert_success
  assert_output_contains "old manifest at $prefix"
  refute_output_contains "no install at"

  run_install_function "UTILZ_HOME='$src'; install_verb_install --prefix '$prefix' --force" >/dev/null
  run run_install_function "UTILZ_HOME='$src'; install_verb_use --bin-dir '$bindir'"
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

  run run_install_function "set -euo pipefail; INSTALL_BREW='$stub'; UTILZ_HOME='$src'; install_verb_use brew --bin-dir '$bindir'"
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
