#!/usr/bin/env bats
# relink.bats - ST0014/WP-12: the explicit PATH-symlink verb
#
# AC11 and AC20 are one policy from two sides: never implicitly, always
# available explicitly. install and upgrade write nothing outside the prefix
# (AT12, in install.bats); this is the verb the operator types when they do
# want the cutover.
#
# Every test uses a FIXTURE bin directory. Nothing here may touch the real
# ~/.local/bin, which on this machine holds sixteen links into the checkout.

load "test_helper.bash"

# A bin directory carrying both link shapes plus one link that is nobody's.
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

# ============================================================================
# AT16 - repoint what is ours, leave alone what is not
# ============================================================================

@test "relink repoints every Utilz link into the named tree" {
  local old="$BATS_TEST_TMPDIR/old" new="$BATS_TEST_TMPDIR/new"
  local bindir="$BATS_TEST_TMPDIR/bin"
  make_fake_src "$old"
  run run_install_function "UTILZ_HOME='$old'; install_verb_install --prefix '$new'"
  assert_success
  make_fake_bin "$bindir" "$old"

  run run_install_function "install_verb_relink --prefix '$new' --bin-dir '$bindir'"
  assert_success

  local link
  for link in alpha beta utilz; do
    local resolved
    resolved=$(cd "$bindir" && cd "$(dirname "$(readlink "$link")")" && pwd)
    [[ "$resolved" == "$new/bin" ]] || {
      echo "$link resolves into $resolved, not $new/bin" >&2
      return 1
    }
  done
}

@test "relink leaves the odd-shaped link dispatching as itself" {
  # beta points at the DISPATCHER, not at bin/beta. Repointing it must keep
  # that: changing the target's basename would be normalising a convention
  # under cover of a command asked to do something else (design.md D9).
  local old="$BATS_TEST_TMPDIR/old-odd" new="$BATS_TEST_TMPDIR/new-odd"
  local bindir="$BATS_TEST_TMPDIR/bin-odd"
  make_fake_src "$old"
  run run_install_function "UTILZ_HOME='$old'; install_verb_install --prefix '$new'"
  assert_success
  make_fake_bin "$bindir" "$old"

  run run_install_function "install_verb_relink --prefix '$new' --bin-dir '$bindir'"
  assert_success

  [[ "$(basename "$(readlink "$bindir/beta")")" == "utilz" ]] || {
    echo "beta now points at $(readlink "$bindir/beta") -- its shape was normalised" >&2
    return 1
  }
  [[ "$(basename "$(readlink "$bindir/alpha")")" == "alpha" ]]
}

@test "relink leaves a link pointing at neither tree alone, and reports it skipped" {
  local old="$BATS_TEST_TMPDIR/old-skip" new="$BATS_TEST_TMPDIR/new-skip"
  local bindir="$BATS_TEST_TMPDIR/bin-skip"
  make_fake_src "$old"
  run run_install_function "UTILZ_HOME='$old'; install_verb_install --prefix '$new'"
  assert_success
  make_fake_bin "$bindir" "$old"

  local before
  before=$(readlink "$bindir/stranger")

  run run_install_function "install_verb_relink --prefix '$new' --bin-dir '$bindir'"
  assert_success
  assert_output_contains "skipped"
  assert_output_contains "stranger"

  [[ "$(readlink "$bindir/stranger")" == "$before" ]] || {
    echo "a link that is nobody's was rewritten" >&2
    return 1
  }
}

@test "relink REPORTS what it changed" {
  local old="$BATS_TEST_TMPDIR/old-rep" new="$BATS_TEST_TMPDIR/new-rep"
  local bindir="$BATS_TEST_TMPDIR/bin-rep"
  make_fake_src "$old"
  run run_install_function "UTILZ_HOME='$old'; install_verb_install --prefix '$new'"
  assert_success
  make_fake_bin "$bindir" "$old"

  run run_install_function "install_verb_relink --prefix '$new' --bin-dir '$bindir'"
  assert_success
  assert_output_contains "relinked"
  assert_output_contains "alpha"
  assert_output_contains "beta"
}

@test "relink is idempotent: a second run changes nothing and says so" {
  local old="$BATS_TEST_TMPDIR/old-idem" new="$BATS_TEST_TMPDIR/new-idem"
  local bindir="$BATS_TEST_TMPDIR/bin-idem"
  make_fake_src "$old"
  run run_install_function "UTILZ_HOME='$old'; install_verb_install --prefix '$new'"
  assert_success
  make_fake_bin "$bindir" "$old"

  run run_install_function "install_verb_relink --prefix '$new' --bin-dir '$bindir'"
  assert_success

  run run_install_function "install_verb_relink --prefix '$new' --bin-dir '$bindir'"
  assert_success
  assert_output_contains "unchanged"
  refute_output_contains "relinked"
}

@test "relink refuses a target that is not a Utilz tree" {
  local bindir="$BATS_TEST_TMPDIR/bin-bad"
  mkdir -p "$bindir" "$BATS_TEST_TMPDIR/notatree"

  run run_install_function "install_verb_relink --prefix '$BATS_TEST_TMPDIR/notatree' --bin-dir '$bindir'"
  assert_exit_code 1
  assert_output_contains "not a Utilz tree"
}

@test "relink refuses a bin directory that does not exist" {
  local new="$BATS_TEST_TMPDIR/new-nobin" old="$BATS_TEST_TMPDIR/old-nobin"
  make_fake_src "$old"
  run run_install_function "UTILZ_HOME='$old'; install_verb_install --prefix '$new'"
  assert_success

  run run_install_function "install_verb_relink --prefix '$new' --bin-dir '$BATS_TEST_TMPDIR/no-such-dir'"
  assert_exit_code 1
  assert_output_contains "no-such-dir"
}

# ============================================================================
# AC11's half - install and upgrade change NOTHING in that directory
# ============================================================================

@test "install and upgrade leave the bin directory untouched" {
  # One leg without the other proves only that something moved.
  local old="$BATS_TEST_TMPDIR/old-ac11" new="$BATS_TEST_TMPDIR/new-ac11"
  local bindir="$BATS_TEST_TMPDIR/bin-ac11"
  make_fake_src "$old"
  make_fake_bin "$bindir" "$old"

  local before after
  before=$(cd "$bindir" && for f in *; do printf '%s -> %s\n' "$f" "$(readlink "$f")"; done | LC_ALL=C sort)

  run run_install_function "UTILZ_HOME='$old'; install_verb_install --prefix '$new'"
  assert_success
  run run_install_function "UTILZ_HOME='$old'; install_verb_upgrade --prefix '$new'"
  assert_success

  after=$(cd "$bindir" && for f in *; do printf '%s -> %s\n' "$f" "$(readlink "$f")"; done | LC_ALL=C sort)
  [[ "$before" == "$after" ]] || {
    echo "install or upgrade touched the bin directory:" >&2
    diff <(printf '%s\n' "$before") <(printf '%s\n' "$after") >&2
    return 1
  }
}

# ============================================================================
# AT17 (AC21) - `utilz use dev|opt`, a thin coordinator over relink
# ============================================================================

# A source tree with install.prefix set, published to $2, and a fixture bin/
# whose links currently serve the SOURCE.
make_two_trees() {
  local src="$1" prefix="$2" bindir="$3"
  make_fake_src "$src"
  set_prefix_key "$src" "$prefix"
  run_install_function "UTILZ_HOME='$src'; install_verb_install --prefix '$prefix'" >/dev/null
  make_fake_bin "$bindir" "$src"
}

@test "AT17: the manifest header carries source-tree, the absolute path published from" {
  local src="$BATS_TEST_TMPDIR/moved-src" prefix="$BATS_TEST_TMPDIR/p-st"
  make_fake_src "$src"
  run run_install_function "UTILZ_HOME='$src'; install_verb_install --prefix '$prefix'"
  assert_success

  local recorded
  recorded=$(awk -F'\t' '$1 == "source-tree" { print $2; exit }' "$prefix/manifest.sha256")
  [[ -n "$recorded" ]] || {
    echo "no source-tree row in the manifest:" >&2
    head -4 "$prefix/manifest.sha256" >&2
    return 1
  }
  # It FOLLOWS the checkout rather than naming some canonical location: publish
  # from a differently-named directory and the recorded path is that one.
  [[ "$recorded" == "$src" ]] || {
    echo "source-tree is $recorded, not $src" >&2
    return 1
  }
}

@test "AT17: turnkey both ways, no path typed and no second key read" {
  local src="$BATS_TEST_TMPDIR/tk-src" prefix="$BATS_TEST_TMPDIR/tk-opt"
  local bindir="$BATS_TEST_TMPDIR/tk-bin"
  make_two_trees "$src" "$prefix" "$bindir"

  # From the SOURCE: switch to opt. One word, no path.
  run run_install_function "UTILZ_HOME='$src'; install_verb_use opt --bin-dir '$bindir'"
  assert_success

  local link resolved
  for link in alpha beta utilz; do
    resolved=$(cd "$bindir" && cd "$(dirname "$(readlink "$link")")" && pwd)
    [[ "$resolved" == "$prefix/bin" ]] || {
      echo "after 'use opt', $link resolves into $resolved, not $prefix/bin" >&2
      return 1
    }
  done

  # From the INSTALL: switch back to dev. The source's address came out of the
  # manifest, not out of a key or an argument.
  run run_install_function "UTILZ_HOME='$prefix'; install_verb_use dev --bin-dir '$bindir'"
  assert_success

  for link in alpha beta utilz; do
    resolved=$(cd "$bindir" && cd "$(dirname "$(readlink "$link")")" && pwd)
    [[ "$resolved" == "$src/bin" ]] || {
      echo "after 'use dev', $link resolves into $resolved, not $src/bin" >&2
      return 1
    }
  done
}

@test "AT17: use calls relink rather than reimplementing it" {
  # relink's documented policy is that a link pointing at neither tree is
  # skipped and reported. A second implementation inside `use` would have to
  # reproduce that to pass, which is the Highlander check written as a test
  # rather than as a comment.
  local src="$BATS_TEST_TMPDIR/hl-src" prefix="$BATS_TEST_TMPDIR/hl-opt"
  local bindir="$BATS_TEST_TMPDIR/hl-bin"
  make_two_trees "$src" "$prefix" "$bindir"

  local before
  before=$(readlink "$bindir/stranger")

  run run_install_function "UTILZ_HOME='$src'; install_verb_use opt --bin-dir '$bindir'"
  assert_success
  assert_output_contains "skipped"
  assert_output_contains "stranger"
  [[ "$(readlink "$bindir/stranger")" == "$before" ]]
}

# Each link in <dir> with its own inode and mtime, one per line, sorted. A
# relink replaces the link, so the inode moves even within the same second.
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
  # a report that relinked first would print exactly the same thing.
  local src="$BATS_TEST_TMPDIR/rep-src" prefix="$BATS_TEST_TMPDIR/rep-opt"
  local bindir="$BATS_TEST_TMPDIR/rep-bin"
  make_two_trees "$src" "$prefix" "$bindir"

  local before after
  before=$(link_stamps "$bindir")

  run run_install_function "UTILZ_HOME='$src'; install_verb_use --bin-dir '$bindir'"
  assert_success
  assert_output_contains "$src"
  assert_output_contains "$prefix"

  after=$(link_stamps "$bindir")
  [[ "$before" == "$after" ]] || {
    echo "bare 'use' changed link mtimes:" >&2
    diff <(printf '%s\n' "$before") <(printf '%s\n' "$after") >&2
    return 1
  }
}

@test "AT17: use refuses a word that is neither dev nor opt" {
  local src="$BATS_TEST_TMPDIR/bad-src" prefix="$BATS_TEST_TMPDIR/bad-opt"
  local bindir="$BATS_TEST_TMPDIR/bad-bin"
  make_two_trees "$src" "$prefix" "$bindir"

  run run_install_function "UTILZ_HOME='$src'; install_verb_use sideways --bin-dir '$bindir'"
  assert_exit_code 2
  assert_output_contains "dev"
  assert_output_contains "opt"
}

@test "AT17: use dev refuses by name when there is no install to read from" {
  # The source's address lives in the install's manifest, so with no install
  # there is nowhere to read it. That is refused by name rather than guessed
  # at -- the same rule AC05 applies to the prefix, for the same reason.
  local src="$BATS_TEST_TMPDIR/noinst-src" bindir="$BATS_TEST_TMPDIR/noinst-bin"
  make_fake_src "$src"
  set_prefix_key "$src" "$BATS_TEST_TMPDIR/nothing-published"
  mkdir -p "$bindir"

  run run_install_function "UTILZ_HOME='$src'; install_verb_use dev --bin-dir '$bindir'"
  assert_exit_code 1
  assert_output_contains "install"
}

@test "AT17: bare use tells 'no install' apart from 'install predates source-tree'" {
  # Found LIVE, not by a test, which is why it is a test now. The real install
  # was published before the source-tree row existed and the first draft
  # reported it as no install at all -- sending the reader to publish
  # something already published. Three answers, not two.
  local src="$BATS_TEST_TMPDIR/3w-src" prefix="$BATS_TEST_TMPDIR/3w-opt"
  local bindir="$BATS_TEST_TMPDIR/3w-bin"
  make_fake_src "$src"
  set_prefix_key "$src" "$prefix"
  mkdir -p "$bindir"

  # (a) nothing published at all
  run run_install_function "UTILZ_HOME='$src'; install_verb_use --bin-dir '$bindir'"
  assert_success
  assert_output_contains "no install at $prefix"

  # (b) published, but the manifest predates the row
  run_install_function "UTILZ_HOME='$src'; install_verb_install --prefix '$prefix'" >/dev/null
  grep -v '^source-tree	' "$prefix/manifest.sha256" > "$prefix/m.tmp"
  mv "$prefix/m.tmp" "$prefix/manifest.sha256"

  run run_install_function "UTILZ_HOME='$src'; install_verb_use --bin-dir '$bindir'"
  assert_success
  assert_output_contains "predates source-tree"
  refute_output_contains "no install at"

  # (c) published with the row
  run_install_function "UTILZ_HOME='$src'; install_verb_upgrade --prefix '$prefix'" >/dev/null
  run run_install_function "UTILZ_HOME='$src'; install_verb_use --bin-dir '$bindir'"
  assert_success
  assert_output_contains "$src"
  refute_output_contains "predates source-tree"
  refute_output_contains "no install at"
}

# ============================================================================
# 0079 - the bin dir follows the tree's utilities, both ways
# ============================================================================
#
# relink runs here under set -euo pipefail, as bin/utilz runs it: the
# run_install_function shell is not strict, so without it a fault that strict
# mode turns into an exit would pass.

@test "0079: relink links a utility of the tree that has no link here, names it, and links nothing else" {
  local old="$BATS_TEST_TMPDIR/old-add" new="$BATS_TEST_TMPDIR/new-add"
  local bindir="$BATS_TEST_TMPDIR/bin-add"
  make_fake_src "$old"
  run run_install_function "UTILZ_HOME='$old'; install_verb_install --prefix '$new'"
  assert_success
  make_fake_bin "$bindir" "$old"
  # Links made before alpha was a utility.
  rm "$bindir/alpha"

  run run_install_function "set -euo pipefail; install_verb_relink --prefix '$new' --bin-dir '$bindir'"
  assert_success
  assert_output_contains "linked:    alpha -> $new/bin/alpha"
  [[ "$(readlink "$bindir/alpha")" == "$new/bin/alpha" ]] || {
    echo "alpha is $(readlink "$bindir/alpha" || echo 'not a link')" >&2
    return 1
  }
  # The tree's own utilities and no others: this suite runs with UTILZ_HOME at
  # the real checkout, whose utilities the fixture install does not have.
  [[ "$(cd "$bindir" && echo *)" == "alpha beta stranger utilz" ]] || {
    echo "the bin dir holds: $(cd "$bindir" && echo *)" >&2
    return 1
  }

  run run_install_function "set -euo pipefail; install_verb_relink --prefix '$new' --bin-dir '$bindir'"
  assert_success
  assert_output_contains "unchanged: alpha"
  refute_output_contains "  linked:"
}

@test "0079: relink leaves a link for a utility the tree lacks where it points, and says so" {
  local old="$BATS_TEST_TMPDIR/old-lack" new="$BATS_TEST_TMPDIR/new-lack"
  local bindir="$BATS_TEST_TMPDIR/bin-lack"
  make_fake_src "$old"
  run run_install_function "UTILZ_HOME='$old'; install_verb_install --prefix '$new'"
  assert_success
  # gamma came to the source after the install was published, and has a link.
  ln -s utilz "$old/bin/gamma"
  make_fake_bin "$bindir" "$old"
  ln -s "$old/bin/gamma" "$bindir/gamma"

  run run_install_function "set -euo pipefail; install_verb_relink --prefix '$new' --bin-dir '$bindir'"
  assert_success
  assert_output_contains "skipped:   gamma (not in $new)"
  [[ "$(readlink "$bindir/gamma")" == "$old/bin/gamma" ]] || {
    echo "gamma now points at $(readlink "$bindir/gamma"), which $new does not have" >&2
    return 1
  }
}

@test "0079: relink makes no link where no Utilz link is, and leaves a file in a utility's place alone" {
  local old="$BATS_TEST_TMPDIR/old-safe" new="$BATS_TEST_TMPDIR/new-safe"
  make_fake_src "$old"
  run run_install_function "UTILZ_HOME='$old'; install_verb_install --prefix '$new'"
  assert_success

  # A directory that is not Utilz's: its one link is nobody's.
  local plain="$BATS_TEST_TMPDIR/bin-plain"
  mkdir -p "$plain" "$BATS_TEST_TMPDIR/elsewhere"
  printf '#!/usr/bin/env bash\n' > "$BATS_TEST_TMPDIR/elsewhere/stranger"
  ln -s "$BATS_TEST_TMPDIR/elsewhere/stranger" "$plain/stranger"
  run run_install_function "set -euo pipefail; install_verb_relink --prefix '$new' --bin-dir '$plain'"
  assert_success
  [[ ! -e "$plain/alpha" && ! -L "$plain/alpha" ]] || {
    echo "relink linked alpha into a directory holding no Utilz link" >&2
    return 1
  }

  # A Utilz directory where alpha's name is held by somebody else's file.
  local bindir="$BATS_TEST_TMPDIR/bin-taken"
  make_fake_bin "$bindir" "$old"
  rm "$bindir/alpha"
  printf 'not utilz\n' > "$bindir/alpha"
  run run_install_function "set -euo pipefail; install_verb_relink --prefix '$new' --bin-dir '$bindir'"
  assert_success
  assert_output_contains "skipped:   alpha (not a link)"
  [[ ! -L "$bindir/alpha" && "$(cat "$bindir/alpha")" == "not utilz" ]] || {
    echo "the file in alpha's place was changed" >&2
    return 1
  }
}

@test "0079: relink makes a relative --prefix absolute, so every link it writes resolves" {
  local old="$BATS_TEST_TMPDIR/old-rel" new="$BATS_TEST_TMPDIR/new-rel"
  local bindir="$BATS_TEST_TMPDIR/bin-rel"
  make_fake_src "$old"
  run run_install_function "UTILZ_HOME='$old'; install_verb_install --prefix '$new'"
  assert_success
  make_fake_bin "$bindir" "$old"
  rm "$bindir/alpha"

  # The suite's cwd is BATS_TEST_TMPDIR, so new-rel names the install. A
  # relative target would be read from the bin dir, where it names nothing.
  # beta and utilz first: the repoints the defect wrote, ahead of the new link.
  run run_install_function "set -euo pipefail; install_verb_relink --prefix new-rel --bin-dir '$bindir'"
  assert_success
  local link target
  for link in beta utilz alpha; do
    target=$(readlink "$bindir/$link") || target=""
    [[ "$target" == /* && -e "$bindir/$link" ]] || {
      echo "$link -> '$target', which is relative or names nothing" >&2
      return 1
    }
  done
}
