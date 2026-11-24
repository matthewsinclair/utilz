#!/usr/bin/env bats
# install_lib.bats - ST0014/WP-01: the owned set, the tree predicates and the
# manifest check. The prefix reader, the manifest writer and the CI verdict
# left with Utilz's own publish (devbin#0326, issue I59c806c): devbin's
# publish writes Utilz's trees, and devbin's arms prove it.
#
# The owned-set tests run against the REAL tree rather than a fixture, on
# purpose. A synthetic tree has whatever shape the fixture author imagined,
# and the defect these tests exist to catch is precisely an enumeration that
# matches the imagined shape and not the real one (design.md D2).

load "test_helper.bash"
load "population_helper.bash"

# ============================================================================
# THE OWNED SET (design.md D2)
# ============================================================================

@test "AT07: utilz_runtime_set names exactly the utilities' bin symlinks" {
  run run_install_function "utilz_runtime_set '$UTILZ_HOME'"
  assert_success

  # The bin/ entries are exactly each utility's symlink, from
  # population_helper.bash's population checked whole against bin's links, and
  # bin/utilz itself. bin/devbin and bin/.devbin/ are vendored. A missing or a
  # stray entry is named by the diff.
  assert_population_whole
  local listed want
  listed=$(printf '%s\n' "$output" | grep '^bin/' | LC_ALL=C sort)
  want=$({ _utilities | sed 's#^#bin/#'; echo bin/utilz; } | LC_ALL=C sort)
  [[ "$listed" == "$want" ]] || {
    echo "the owned set's bin/ entries are not each utility's symlink and bin/utilz (< wanted, > listed):" >&2
    diff <(printf '%s\n' "$want") <(printf '%s\n' "$listed") >&2
    return 1
  }
}

@test "utilz_runtime_set carries the runtime payload an inclusion list drops" {
  # The five measured on 7 Sep. Each is read at runtime by a utility whose
  # three obvious files (impl, yaml, README) would have shipped without it,
  # so the install breaks only on the one code path that needs the file.
  run run_install_function "utilz_runtime_set '$UTILZ_HOME'"
  assert_success

  local p
  for p in \
    opt/cleanz/data/trope-indicators.txt \
    opt/expz/lib/expense_schema.json \
    opt/pdf2md/lib/pdf2md.py \
    opt/xtrct/lib/xtrct.py \
    opt/macoz/images/backgrounds/winter-01.png
  do
    printf '%s\n' "$output" | grep -qx "$p" || {
      echo "owned set is missing runtime payload: $p" >&2
      return 1
    }
  done
}

@test "utilz_runtime_set excludes tests, crate source, vendored devbin and the project record" {
  run run_install_function "utilz_runtime_set '$UTILZ_HOME'"
  assert_success

  refute_output_contains "opt/utilz/test/"
  refute_output_contains "opt/prez/crate/src/"
  refute_output_contains "opt/prez/crate/themes/"
  refute_output_contains "intent/"
  refute_output_contains "docs/"

  printf '%s\n' "$output" | grep -qx "bin/devbin" && {
    echo "vendored devbin must not be in the owned set" >&2
    return 1
  }
  printf '%s\n' "$output" | grep -q '^bin/\.devbin/' && {
    echo "vendored .devbin/ must not be in the owned set" >&2
    return 1
  }
  return 0
}

@test "utilz_runtime_set names the built prez binary, and only where the crate is" {
  # Gitignored, so it is named rather than enumerated (D5). It must appear
  # regardless of whether it has been BUILT -- an owned path that is absent is
  # a publish that must fail, not a set that quietly shrinks -- but a tree that
  # carries no crate names no prez output at all.
  run run_install_function "utilz_runtime_set '$UTILZ_HOME'"
  assert_success
  printf '%s\n' "$output" | grep -qx "opt/prez/crate/target/release/prez"

  local nocrate="$BATS_TEST_TMPDIR/src-nocrate"
  make_fake_src "$nocrate"
  run run_install_function "utilz_runtime_set '$nocrate'"
  assert_success
  refute_output_contains "prez"
}

@test "utilz_runtime_set names the built showreel binary beside prez's (issue 0024)" {
  # The shim execs either binary -- `prez showreel <...>` hands over to the
  # second -- so an owned set naming only prez's shipped an install that handed
  # over to a file it never published. Named rather than enumerated for the
  # same reason as prez's: it is gitignored, and absent must fail the publish.
  run run_install_function "utilz_runtime_set '$UTILZ_HOME'"
  assert_success
  printf '%s\n' "$output" | grep -qx "opt/prez/crate/target/release/showreel" || {
    echo "owned set is missing showreel's binary" >&2
    return 1
  }
}

@test "utilz_runtime_set is LC_ALL=C sorted and free of duplicates" {
  run run_install_function "utilz_runtime_set '$UTILZ_HOME'"
  assert_success

  local sorted uniq_count total
  sorted=$(printf '%s\n' "$output" | LC_ALL=C sort)
  [[ "$sorted" == "$output" ]] || {
    echo "owned set is not LC_ALL=C sorted" >&2
    return 1
  }
  total=$(printf '%s\n' "$output" | wc -l | tr -d ' ')
  uniq_count=$(printf '%s\n' "$output" | sort -u | wc -l | tr -d ' ')
  [[ "$total" -eq "$uniq_count" ]]
}

@test "utilz_runtime_set refuses a tree that is not a git repository" {
  local nogit="$BATS_TEST_TMPDIR/nogit"
  mkdir -p "$nogit/bin"
  run run_install_function "utilz_runtime_set '$nogit'"
  # rc 1 is the refusal. A bare assert_failure also passes at rc 127, which
  # is the library failing to load -- the check would then be green against a
  # library that does not exist.
  assert_exit_code 1
  assert_output_contains "not a git repository"
}

# ============================================================================
# THE PREDICATES (design.md D7, AC03, AC04)
# ============================================================================

@test "install_tree_kind tells a source tree from an install tree" {
  local src="$BATS_TEST_TMPDIR/src-kind"
  make_fake_src "$src"

  run run_install_function "install_tree_kind '$src'"
  assert_success
  assert_output "source"

  local inst="$BATS_TEST_TMPDIR/inst-kind"
  make_fake_install "$src" "$inst"

  run run_install_function "install_tree_kind '$inst'"
  assert_success
  assert_output "install"

  local other="$BATS_TEST_TMPDIR/other-kind"
  mkdir -p "$other"
  run run_install_function "install_tree_kind '$other'"
  assert_success
  assert_output "other"

  # Utilz's old manifest form is an install too, so --force may republish over
  # it; a manifest.sha256 Utilz did not write is not (contract T2, issue 0105).
  local old="$BATS_TEST_TMPDIR/old-kind" foreign="$BATS_TEST_TMPDIR/foreign-kind"
  mkdir -p "$old" "$foreign"
  printf 'utilz-version\t2.14.2\nmanaged-by\tutilz\n' > "$old/manifest.sha256"
  printf 'deadbeef  something\n' > "$foreign/manifest.sha256"
  run run_install_function "install_tree_kind '$old'; install_tree_kind '$foreign'"
  assert_success
  [[ "$output" == $'install\nforeign' ]] || fail "install_tree_kind answered: $output"
}

@test "utilz_runtime_state distinguishes clean, dirty and not-a-git-repo" {
  # "no changes" and "cannot tell" must never render as the same answer (D7).
  local src="$BATS_TEST_TMPDIR/src-state"
  make_fake_src "$src"

  run run_install_function "utilz_runtime_state '$src'"
  assert_success
  assert_output "clean"

  # THE RUNTIME SET ONLY (contract T2, issue 0105): a file outside it, a test
  # inside an excluded subtree, changes no byte the manifest names.
  printf 'scratch\n' > "$src/NOTES.md"
  printf 'edited\n' >> "$src/opt/alpha/test/alpha.bats"
  run run_install_function "utilz_runtime_state '$src'"
  assert_success
  assert_output "clean"

  # A file in the set, changed or new, is dirty.
  printf 'edited\n' >> "$src/help/alpha.md"
  run run_install_function "utilz_runtime_state '$src'"
  assert_success
  assert_output "dirty"
  git -C "$src" checkout -q -- help/alpha.md
  printf 'new\n' > "$src/help/beta.md"
  run run_install_function "utilz_runtime_state '$src'"
  assert_success
  assert_output "dirty"
  rm -f "$src/help/beta.md"

  # A file moved OUT of the set, staged, is dirty: the commit the manifest
  # would record still holds it at its old path (utilz-vc's W5).
  git -C "$src" mv help/alpha.md opt/alpha/test/alpha-help.md
  run run_install_function "utilz_runtime_state '$src'"
  assert_success
  assert_output "dirty"

  local nogit="$BATS_TEST_TMPDIR/nogit-state"
  mkdir -p "$nogit"
  run run_install_function "utilz_runtime_state '$nogit'"
  assert_success
  assert_output "unknown"
}

# ============================================================================
# THE MANIFEST CHECKER (design.md D3, D4; AC06, AC08)
# ============================================================================

# Build an install tree from a source fixture with devbin's publish, the one
# that writes Utilz's trees (devbin#0326, issue I59c806c): the runtime set,
# links as links, and T3's manifest.
make_fake_install() {
  local src="$1" dst="$2"
  run_devbin "$src" install --prefix "$dst" >/dev/null
}

@test "install_manifest_check is silent for an install that matches its manifest" {
  local src="$BATS_TEST_TMPDIR/src-chk" dst="$BATS_TEST_TMPDIR/inst-chk"
  make_fake_src "$src"
  make_fake_install "$src" "$dst"

  run run_install_function "install_manifest_check '$dst'"
  assert_success
  assert_output ""
}

@test "install_manifest_check names a modified file" {
  local src="$BATS_TEST_TMPDIR/src-mod" dst="$BATS_TEST_TMPDIR/inst-mod"
  make_fake_src "$src"
  make_fake_install "$src" "$dst"
  printf 'edited by hand\n' >> "$dst/bin/utilz"

  run run_install_function "install_manifest_check '$dst'"
  assert_failure
  assert_output_contains "modified"
  assert_output_contains "bin/utilz"
}

# AT07 (AC06): a link that names another target is named as retargeted, and a
# copy where a link belongs as not-a-link (the arm below this one).
@test "install_manifest_check names a retargeted link" {
  # The AC06 case. All the dispatcher links resolve to one file, so the body's
  # hash gives every one of them the same value and this retarget reads as
  # intact unless every bin/ link is held to its target string, utilz.
  local src="$BATS_TEST_TMPDIR/src-retarget" dst="$BATS_TEST_TMPDIR/inst-retarget"
  make_fake_src "$src"
  make_fake_install "$src" "$dst"
  cp "$dst/bin/utilz" "$dst/bin/twin"
  rm "$dst/bin/alpha"
  ln -s twin "$dst/bin/alpha"

  # bin/twin is the dispatcher's bytes, so the body alone reads alpha as
  # intact; the structural rule (issue 0105) is what names it.
  run run_install_function "install_manifest_check '$dst'"
  assert_failure
  assert_output_contains "retargeted"
  assert_output_contains "bin/alpha"
}

@test "install_manifest_check names a link that arrived as a dereferenced copy" {
  # D3's defect, and it is the one that leaves a tree which still WORKS: cp
  # dereferences, so the install gets N copies of the dispatcher, nothing
  # fails, and nothing says anything. It must be its own reason rather than
  # be folded into 'modified'.
  local src="$BATS_TEST_TMPDIR/src-deref" dst="$BATS_TEST_TMPDIR/inst-deref"
  make_fake_src "$src"
  make_fake_install "$src" "$dst"
  rm "$dst/bin/alpha"
  cp "$dst/bin/utilz" "$dst/bin/alpha"

  run run_install_function "install_manifest_check '$dst'"
  assert_failure
  assert_output_contains "not-a-link"
  assert_output_contains "bin/alpha"
}

@test "install_manifest_check names a missing owned path" {
  local src="$BATS_TEST_TMPDIR/src-miss" dst="$BATS_TEST_TMPDIR/inst-miss"
  make_fake_src "$src"
  make_fake_install "$src" "$dst"
  rm "$dst/help/alpha.md"

  run run_install_function "install_manifest_check '$dst'"
  assert_failure
  assert_output_contains "missing"
  assert_output_contains "help/alpha.md"
}

@test "install_manifest_check answers rc 3 for Utilz's old manifest form, and rc 2 for one it did not write (issue 0105)" {
  local old="$BATS_TEST_TMPDIR/old-chk" foreign="$BATS_TEST_TMPDIR/foreign-chk"
  mkdir -p "$old" "$foreign"
  printf 'utilz-version\t2.14.2\nsource-commit\t%040d\nfile\t%064d\tVERSION\n' 0 0 > "$old/manifest.sha256"
  printf 'deadbeef  something\n' > "$foreign/manifest.sha256"

  # The old form is not read as a second format (contract T3): it is named.
  run run_install_function "install_manifest_check '$old'"
  assert_exit_code 3
  assert_output ""

  run run_install_function "install_manifest_check '$foreign'"
  assert_exit_code 2
  assert_output_contains "is not a manifest Utilz wrote"
}

@test "install_manifest_check refuses a body line it cannot read" {
  local src="$BATS_TEST_TMPDIR/src-badline" dst="$BATS_TEST_TMPDIR/inst-badline"
  make_fake_src "$src"
  make_fake_install "$src" "$dst"
  printf 'not a body line\n' >> "$dst/manifest.sha256"

  run run_install_function "install_manifest_check '$dst'"
  assert_exit_code 2
  assert_output_contains "unreadable manifest line"
}

@test "install_manifest_check refuses a tree with no manifest" {
  local bare="$BATS_TEST_TMPDIR/bare"
  mkdir -p "$bare"
  run run_install_function "install_manifest_check '$bare'"
  # rc 2 is "cannot read the manifest", distinct from rc 1 "drift found" and
  # from rc 127 "the library did not load". Three answers, three codes: a bare
  # assert_failure cannot tell any of them apart.
  assert_exit_code 2
  assert_output_contains "no manifest"
}

# ============================================================================
# ST0019's AT01 (AC-01.3), retired with Utilz's own CI reader (ST0031/01)
# ============================================================================

# AT01 held the reader Utilz kept as the release core's ci.query: five arms
# for its verdicts, its refusal, its one query, its usage and its place in no
# install. ST0031/01 retired that reader with its arms, since CI's verdict is
# now the core's own `bin/devbin ci-state`, for the cut and the publish alike;
# the publish's side of it is AT08's arms above.

# ============================================================================
# issue 0044: the announced commit is the tree's own, or none
# ============================================================================

