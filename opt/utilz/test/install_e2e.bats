#!/usr/bin/env bats
# install_e2e.bats - ST0014/WP-05: AC01, the row the whole thread turns on
#
# Devbin's install tree is deliberately not runnable (D33). Ours inverts that,
# so the test is that the install WORKS when the source is gone -- not that
# files arrived. An install that silently reaches back into the checkout passes
# every check that does not remove it, and passes them looking exactly like
# success.
#
# The source published from is a COPY at a temp path, removed after the
# publish. That is the honest form of "moved aside" here: the real checkout is
# hv's working tree with three concurrent writers and is never touched. The
# copy closes the reach-back-to-my-own-source case; the second test closes the
# case a copy cannot see, a path hardcoded to the real tree.

load "test_helper.bash"

setup_file() {
  export E2E_PREFIX="${BATS_FILE_TMPDIR:-/tmp}/e2e-prefix"
  local src="${BATS_FILE_TMPDIR:-/tmp}/e2e-src"

  export E2E_SRC_PATH="$src"
  rm -rf "$src" "$E2E_PREFIX"

  # cp -a preserves mtimes, so cargo's fingerprints still match and the
  # publish build is a no-op rather than a cold compile.
  cp -a "$UTILZ_HOME" "$src" || return 1

  # Commit inside the COPY so the publish's dirty gate is satisfied without
  # anything being done to the real checkout. A throwaway clone, so this is
  # free; doing it upstream would not be.
  git -C "$src" add -A >/dev/null 2>&1
  git -C "$src" -c user.email=e2e@example.com -c user.name=e2e \
    commit -qm "e2e fixture" >/dev/null 2>&1 || true

  env -u UTILZ_HOME "$src/bin/utilz" install --prefix "$E2E_PREFIX" >/dev/null 2>&1 || return 1

  # THE SOURCE GOES AWAY. Everything below runs against an install whose
  # source tree no longer exists.
  rm -rf "$src"
}

teardown_file() {
  [[ -n "${E2E_PREFIX:-}" ]] && rm -rf "$E2E_PREFIX"
  [[ -n "${E2E_SRC_PATH:-}" ]] && rm -rf "$E2E_SRC_PATH"
  return 0
}

@test "the source tree published from is really gone" {
  # Guard on the guard. If setup_file failed to remove it, every test below
  # would pass while proving nothing at all.
  assert_directory_not_exists "$E2E_SRC_PATH"
  assert_file_exists "$E2E_PREFIX/manifest.sha256"
}

@test "AC01: utilz version runs from the install with no source tree" {
  run env -u UTILZ_HOME "$E2E_PREFIX/bin/utilz" version
  assert_success
  assert_output_contains "utilz v"
  assert_output_contains "installed at $E2E_PREFIX"
}

@test "AC01: utilz list enumerates all fifteen utilities from the install" {
  # Exercises each_utility plus a yaml read per utility, so it fails if the
  # symlinks, the implementations or the metadata did not arrive.
  run env -u UTILZ_HOME "$E2E_PREFIX/bin/utilz" list
  assert_success

  local name
  for name in cleanz clipz cryptz expz gitz lnrel macoz mdagg pdf2md prez retry stampz syncz todo xtrct; do
    assert_output_contains "$name"
  done
}

@test "AC01: utilz doctor finds the install sound" {
  run env -u UTILZ_HOME "$E2E_PREFIX/bin/utilz" doctor

  # Doctor exits 1 here and is RIGHT to: a temp prefix is not on $PATH, and it
  # says so. That is AC16 / WP-12's territory -- the explicit relink verb --
  # not a defect in the install. Asserting rc 0 would mean either weakening
  # doctor or pretending an unconfigured PATH is fine, and both are worse than
  # asserting the checks that actually speak to AC01.
  assert_output_contains "All required directories present"
  assert_output_contains "bin/utilz exists and is executable"
  assert_output_contains "Found 15 utilities, all properly configured"
  assert_output_contains "All required dependencies installed"

  # And the only thing it found is the PATH.
  assert_output_contains "Found 1 issue(s)"
}

@test "AC01: utilz help reads a help file from the install" {
  run env -u UTILZ_HOME "$E2E_PREFIX/bin/utilz" help mdagg
  assert_success
  assert_output_contains "mdagg"
}

@test "AC01: a dispatched utility runs and reads its own data file" {
  # cleanz --detrope reads opt/cleanz/data/trope-indicators.txt, which is
  # exactly the file D2's original inclusion list would have dropped. If the
  # owned set were still <n>, <n>.yaml and README.md, cleanz would arrive and
  # this path would find nothing -- a broken install that looks installed.
  printf 'It is important to note that this delves into the tapestry.\n' \
    > "$BATS_TEST_TMPDIR/deck.txt"

  run env -u UTILZ_HOME "$E2E_PREFIX/bin/cleanz" --detrope "$BATS_TEST_TMPDIR/deck.txt"
  assert_success
  assert_output_contains "Trope Analysis"
  assert_output_contains "delve"
}

@test "AC01: prez runs from the install with no crate present" {
  assert_directory_not_exists "$E2E_PREFIX/opt/prez/crate/src"

  run env -u UTILZ_HOME "$E2E_PREFIX/opt/prez/prez" --version
  assert_success
  assert_output_contains "prez"
}

@test "AC01: the install verifies against its own manifest" {
  run bash -c "source '$UTILZ_HOME/opt/utilz/lib/common.sh'
    source '$UTILZ_HOME/opt/utilz/lib/install.sh'
    install_manifest_check '$E2E_PREFIX'"
  assert_success
  assert_output ""
}

@test "the fifteen symlinks arrived as symlinks, not as dereferenced copies" {
  local name
  for name in cleanz clipz cryptz expz gitz lnrel macoz mdagg pdf2md prez retry stampz syncz todo xtrct; do
    [[ -L "$E2E_PREFIX/bin/$name" ]] || {
      echo "bin/$name is not a symlink in the install" >&2
      return 1
    }
    [[ "$(readlink "$E2E_PREFIX/bin/$name")" == "utilz" ]] || {
      echo "bin/$name points at $(readlink "$E2E_PREFIX/bin/$name"), not utilz" >&2
      return 1
    }
  done
}

@test "no file in the install names the tree it was published from" {
  # The case a copy-and-delete cannot see: a path hardcoded to the source would
  # survive the source going away if that source were the REAL checkout, which
  # is still there. Grepping the artefact is the only thing that catches it.
  run bash -c "grep -rIl -e '$E2E_SRC_PATH' '$E2E_PREFIX' 2>/dev/null || true"
  assert_success
  [[ -z "$output" ]] || {
    echo "these installed files name the tree they were published from:" >&2
    printf '%s\n' "$output" >&2
    return 1
  }
}

@test "no executable or library in the install names an absolute home path" {
  # The stricter half, restricted to files that RUN. Eight opt/*/README.md
  # carry a literal /Users/matts/Devel/prj/Utilz in a Development section --
  # historical drift from an older generator, measured 7 Sep; the current
  # tmpl/README.tmpl ships the literal string $UTILZ_HOME and is clean. That is
  # a documentation wart with its own home, and NOT something to smuggle into
  # this assertion as an exception list that would rot the first time someone
  # fixed one of them.
  run bash -c "
    cd '$E2E_PREFIX' || exit 1
    find . -type f ! -name '*.md' ! -path './opt/prez/crate/*' -print0 \
      | xargs -0 grep -Il '/Users/' 2>/dev/null || true
  "
  assert_success
  [[ -z "$output" ]] || {
    echo "these installed executables name an absolute home path:" >&2
    printf '%s\n' "$output" >&2
    return 1
  }
}
