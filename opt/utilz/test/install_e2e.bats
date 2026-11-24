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
load "population_helper.bash"

setup_file() {
  # No commit this file makes signs with the user's key (issue 0082). The
  # helper's setup() pins that for each test, and the fixture commit below
  # comes before any test.
  no_git_signing
  export E2E_PREFIX="${BATS_FILE_TMPDIR:-/tmp}/e2e-prefix"
  local src="${BATS_FILE_TMPDIR:-/tmp}/e2e-src"

  export E2E_SRC_PATH="$src"

  # A copy of this checkout, committed and published with devbin's publish
  # (publish_checkout_copy, test_helper.bash), its output kept in the log.
  publish_checkout_copy "$src" "$E2E_PREFIX" "${BATS_FILE_TMPDIR:-/tmp}/e2e-publish.log" "e2e setup" || return 1

  # THE SOURCE GOES AWAY. Everything below runs against an install whose
  # source tree no longer exists.
  rm -rf "$src"
}

teardown_file() {
  [[ -n "${E2E_PREFIX:-}" ]] && rm -rf "$E2E_PREFIX"
  [[ -n "${E2E_SRC_PATH:-}" ]] && rm -rf "$E2E_SRC_PATH"
  return 0
}

# ============================================================================
# AT01 (AC01) - the install runs with the source tree moved aside
#
# Every @test below is a leg of AT01. They are named "AC01:" because that is
# the criterion they demonstrate, but the ROW that cites this file is AT01,
# and `intent at lint` traces a green by the literal AT id. Without this
# banner the file proves AC01 and the contract cannot say so -- which is the
# same defect in the other direction as a green that names no test at all.
# ============================================================================

@test "the source tree published from is really gone" {
  # Guard on the guard. If setup_file failed to remove it, every test below
  # would pass while proving nothing at all.
  assert_directory_not_exists "$E2E_SRC_PATH"
  assert_file_exists "$E2E_PREFIX/manifest.sha256"
}

# AT01 (AC01): the install runs with its source tree gone.
@test "AC01: utilz version runs from the install with no source tree" {
  run env -u UTILZ_HOME "$E2E_PREFIX/bin/utilz" version
  assert_success
  assert_output_matches "^utilz [0-9]+\.[0-9]+\.[0-9]+ \(opt, [0-9a-f]{12}\)$"
  # Which tree answered is NOT cosmetic: ST0014/AC12 holds that an installed
  # utilz can be told from a source utilz at the prompt, and it earned that
  # within the hour -- it was the one command that said WHICH TREE answered
  # when a checkout and a stale install disagreed about --version. Since issue
  # 0105 the contract's one version line carries it (T4), by the tree and the
  # commit its manifest records, and no path (contract A3, issue 0109).
  local recorded
  recorded=$(manifest_source_commit "$E2E_PREFIX")
  [ -n "$recorded" ]
  assert_output_contains "(opt, ${recorded:0:12})"
}

# What an install carries is population_helper.bash's population, checked
# whole against bin's links, so a new utility needs no word here.

@test "AC01: utilz list enumerates every utility from the install" {
  # Exercises each_utility plus a yaml read per utility, so it fails if the
  # symlinks, the implementations or the metadata did not arrive.
  run env -u UTILZ_HOME "$E2E_PREFIX/bin/utilz" list
  assert_success

  local name
  assert_population_whole
  for name in $(_utilities); do
    assert_output_contains "$name"
  done
}

@test "AC01: utilz doctor finds the install sound" {
  run env -u UTILZ_HOME "$E2E_PREFIX/bin/utilz" doctor

  # Doctor exits 1 here and is RIGHT to: a temp prefix is not on $PATH, and it
  # says so. That is AC20 / WP-12's territory -- the explicit relink verb --
  # not a defect in the install. Asserting rc 0 would mean either weakening
  # doctor or pretending an unconfigured PATH is fine, and both are worse than
  # asserting the checks that actually speak to AC01.
  assert_output_contains "All required directories present"
  assert_output_contains "bin/utilz exists and is executable"
  assert_population_whole
  assert_output_contains "Found $(_utility_links | grep -c .) utilities, all properly configured"
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
    source '$UTILZ_HOME/opt/utilz/lib/trees.sh'
    install_manifest_check '$E2E_PREFIX'"
  assert_success
  assert_output ""
}

@test "every utility's symlink arrived as a symlink, not as a dereferenced copy" {
  local name
  assert_population_whole
  for name in $(_utilities); do
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

@test "only the MANIFEST may name the tree the install was published from, and only as its source_tree" {
  # The case a copy-and-delete cannot see: a path hardcoded to the source would
  # survive the source going away if that source were the REAL checkout, which
  # is still there. Grepping the artefact is the only thing that catches it.
  #
  # THE MANIFEST'S source_tree LINE IS EXEMPT, AND ONLY IT. It is a RECORD of
  # where the bytes came from; a path in code would be a DEPENDENCY on that
  # tree still existing. devbin's publish writes it in an opt manifest from
  # devbin 0.1.31 (devbin I79fb280), for information only, and the tests above
  # prove the install runs with that tree gone. No other line names the tree.
  run bash -c "grep -rIl -e '$E2E_SRC_PATH' '$E2E_PREFIX' 2>/dev/null || true"
  assert_success

  local offenders
  offenders=$(printf '%s\n' "$output" | grep -v "^$E2E_PREFIX/manifest.sha256$" | grep -v '^$' || true)
  [[ -z "$offenders" ]] || {
    echo "these installed files name the tree they were published from:" >&2
    printf '%s\n' "$offenders" >&2
    return 1
  }

  offenders=$(grep -n -e "$E2E_SRC_PATH" "$E2E_PREFIX/manifest.sha256" | grep -v '^[0-9]*:# source_tree: ' || true)
  [[ -z "$offenders" ]] || {
    echo "the manifest names the tree it was published from on a line that is not its source_tree:" >&2
    printf '%s\n' "$offenders" >&2
    return 1
  }
}

# AT08 (AC07): the manifest is in devbin's T3 form, and the install prints the
# line it records.
@test "AT08 (AC07): the install's manifest is in devbin's T3 form, and utilz --version prints its line" {
  local m="$E2E_PREFIX/manifest.sha256" key line
  for key in tool version source_commit managed_by line; do
    grep -qE "^# $key: .+" "$m" || fail "the manifest records no $key: $(sed -n '1,8p' "$m")"
  done
  [[ "$(sed -n '1p' "$m")" == "# tool: utilz" ]] || fail "the manifest's first line is not its tool: $(sed -n '1p' "$m")"
  line=$(sed -n 's/^# line: //p' "$m")
  [[ "$line" == "utilz $(cat "$E2E_PREFIX/VERSION") (opt, "* ]] || fail "the recorded line is not an opt line for this version: $line"
  run env -u UTILZ_HOME "$E2E_PREFIX/bin/utilz" --version
  assert_success
  assert_output "$line"
}

@test "nothing in the install names an absolute home path" {
  # THE .md EXEMPTION IS GONE, AND ITS REMOVAL IS THE POINT. This was
  # restricted to files that RUN because eight opt/*/README.md carried a
  # literal /Users/matts/Devel/prj/Utilz in a Development section. Both halves
  # of that are now fixed -- the eight files AND the generator that was still
  # minting the ninth (issue 0010) -- so the property covers the whole owned
  # set, which is where the leak actually was. Documentation ships too.
  #
  # It also catches what the exact-path test above structurally CANNOT: that
  # one greps for E2E_SRC_PATH, a throwaway fixture tree, so a path naming the
  # real checkout goes straight past it. That is how the eight survived.
  #
  # ONE THING IS EXEMPT AND IT IS NOT A PER-FILE EXCEPTION LIST: the manifest
  # is a RECORD of where the bytes came from, exempt here for the same reason
  # and by the same argument as the test above. No installed file needs a home
  # path any more, the /Users/you/ placeholder included, so any /Users/ in an
  # install fails (issue 0105 dropped the last placeholder from help/utilz.md).
  run bash -c "
    cd '$E2E_PREFIX' || exit 1
    find . -type f ! -path './opt/prez/crate/*' ! -name 'manifest.sha256' -print0 \
      | xargs -0 grep -In '/Users/' 2>/dev/null || true
  "
  assert_success
  [[ -z "$output" ]] || {
    echo "these installed files name an absolute home path:" >&2
    printf '%s\n' "$output" >&2
    return 1
  }
}
