#!/usr/bin/env bats
# install_lib.bats - ST0014/WP-01: the owned set, the prefix reader, the manifest
#
# The owned-set tests run against the REAL tree rather than a fixture, on
# purpose. A synthetic tree has whatever shape the fixture author imagined,
# and the defect these tests exist to catch is precisely an enumeration that
# matches the imagined shape and not the real one (design.md D2).

load "test_helper.bash"

run_install_function() {
  bash -c "source '$UTILZ_HOME/opt/utilz/lib/common.sh'; source '$UTILZ_HOME/opt/utilz/lib/install.sh'; $*"
}

# ============================================================================
# THE OWNED SET (design.md D2)
# ============================================================================

@test "AT07: install_owned_paths names exactly the fifteen bin symlinks" {
  run run_install_function "install_owned_paths '$UTILZ_HOME'"
  assert_success

  local listed
  listed=$(printf '%s\n' "$output" | grep -c '^bin/')
  # 15 symlinks + bin/utilz itself. bin/devbin and bin/.devbin/ are vendored.
  [[ "$listed" -eq 16 ]] || {
    echo "expected 16 bin/ entries, got $listed" >&2
    printf '%s\n' "$output" | grep '^bin/' >&2
    return 1
  }

  local name
  for name in cleanz clipz cryptz expz gitz lnrel macoz mdagg pdf2md prez retry stampz syncz todo xtrct; do
    printf '%s\n' "$output" | grep -qx "bin/$name" || {
      echo "owned set is missing bin/$name" >&2
      return 1
    }
  done
}

@test "install_owned_paths carries the runtime payload an inclusion list drops" {
  # The five measured on 7 Sep. Each is read at runtime by a utility whose
  # three obvious files (impl, yaml, README) would have shipped without it,
  # so the install breaks only on the one code path that needs the file.
  run run_install_function "install_owned_paths '$UTILZ_HOME'"
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

@test "install_owned_paths excludes tests, crate source, vendored devbin and the project record" {
  run run_install_function "install_owned_paths '$UTILZ_HOME'"
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

@test "install_owned_paths names the built prez binary, and only where the crate is" {
  # Gitignored, so it is named rather than enumerated (D5). It must appear
  # regardless of whether it has been BUILT -- an owned path that is absent is
  # a publish that must fail, not a set that quietly shrinks -- but a tree that
  # carries no crate names no prez output at all.
  run run_install_function "install_owned_paths '$UTILZ_HOME'"
  assert_success
  printf '%s\n' "$output" | grep -qx "opt/prez/crate/target/release/prez"

  local nocrate="$BATS_TEST_TMPDIR/src-nocrate"
  make_fake_src "$nocrate"
  run run_install_function "install_owned_paths '$nocrate'"
  assert_success
  refute_output_contains "prez"
}

@test "install_owned_paths is LC_ALL=C sorted and free of duplicates" {
  run run_install_function "install_owned_paths '$UTILZ_HOME'"
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

@test "install_owned_paths refuses a tree that is not a git repository" {
  local nogit="$BATS_TEST_TMPDIR/nogit"
  mkdir -p "$nogit/bin"
  run run_install_function "install_owned_paths '$nogit'"
  # rc 1 is the refusal. A bare assert_failure also passes at rc 127, which
  # is the library failing to load -- the check would then be green against a
  # library that does not exist.
  assert_exit_code 1
  assert_output_contains "not a git repository"
}

# ============================================================================
# THE PREFIX READER (design.md D6, AC05)
# ============================================================================

@test "install_prefix_configured refuses an absent key rather than returning the string null" {
  # get_util_metadata ends `echo \"\$result\"` and yq prints the four-character
  # string `null` for an absent key -- measured. A `[[ -n ]]` guard therefore
  # PASSES on unset and the publish writes a directory called ./null.
  local src="$BATS_TEST_TMPDIR/src-noprefix"
  make_fake_src "$src"

  run run_install_function "install_prefix_configured '$src'"
  # Same trap as the git-repo check: rc 127 is the library failing to load,
  # and a bare assert_failure cannot tell it from the refusal.
  assert_exit_code 1
  # AC05: unset is refused BY NAME.
  assert_output_contains "install.prefix"
  refute_output_contains "null"
}

@test "install_prefix_configured expands a leading tilde" {
  local src="$BATS_TEST_TMPDIR/src-tilde"
  make_fake_src "$src"
  printf 'name: utilz\ninstall:\n  prefix: ~/Devel/opt/utilz\n' > "$src/opt/utilz/utilz.yaml"

  run run_install_function "install_prefix_configured '$src'"
  assert_success
  assert_output "$HOME/Devel/opt/utilz"
  refute_output_contains "~"
}

@test "install_prefix_configured returns an absolute prefix unchanged" {
  local src="$BATS_TEST_TMPDIR/src-abs"
  make_fake_src "$src"
  printf 'name: utilz\ninstall:\n  prefix: /opt/utilz\n' > "$src/opt/utilz/utilz.yaml"

  run run_install_function "install_prefix_configured '$src'"
  assert_success
  assert_output "/opt/utilz"
}

# ============================================================================
# THE MANIFEST (design.md D4, AC06, AC07)
# ============================================================================

@test "AT07: install_manifest_rows records a symlink's TARGET STRING, never a content hash" {
  local src="$BATS_TEST_TMPDIR/src-links"
  make_fake_src "$src"

  run run_install_function "install_manifest_rows '$src'"
  assert_success

  local alpha beta
  alpha=$(printf '%s\n' "$output" | grep 'bin/alpha$')
  beta=$(printf '%s\n' "$output" | grep 'bin/beta$')

  printf '%s\n' "$alpha" | grep -q '^link' || {
    echo "bin/alpha row is not a link row: $alpha" >&2
    return 1
  }
  printf '%s\n' "$alpha" | grep -q 'utilz' || {
    echo "bin/alpha row does not carry its target string: $alpha" >&2
    return 1
  }
  # The anti-degeneracy check. cp would dereference both links into copies of
  # two DIFFERENT files, so a content hash distinguishes these two by accident.
  # The case that matters is two links to the same file, covered below.
  [[ "$alpha" != "$beta" ]]
}

@test "AT07: install_manifest_rows distinguishes two links whose resolved content is identical" {
  # This is the case a resolved-content hash cannot see: fifteen links all
  # pointing at bin/utilz hash identically, so a link retargeted at the wrong
  # utility reads as intact (AC06).
  local src="$BATS_TEST_TMPDIR/src-samecontent"
  make_fake_src "$src"
  cp "$src/bin/utilz" "$src/bin/twin"
  ln -s twin "$src/bin/gamma"
  git -C "$src" add -A >/dev/null 2>&1
  git -C "$src" -c user.email=t@example.com -c user.name=t commit -qm twin >/dev/null 2>&1

  run run_install_function "install_manifest_rows '$src'"
  assert_success

  local alpha gamma
  alpha=$(printf '%s\n' "$output" | grep 'bin/alpha$')
  gamma=$(printf '%s\n' "$output" | grep 'bin/gamma$')

  # bin/utilz and bin/twin are byte-identical, so their sha256 is identical.
  # The rows must still differ, because the recorded value is the target.
  [[ "$(printf '%s\n' "$alpha" | cut -f2)" != "$(printf '%s\n' "$gamma" | cut -f2)" ]]
}

@test "AT08: install_manifest_rows emits exactly one row per owned path" {
  local src="$BATS_TEST_TMPDIR/src-rows"
  make_fake_src "$src"

  local paths rows
  paths=$(run_install_function "install_owned_paths '$src'" | wc -l | tr -d ' ')
  rows=$(run_install_function "install_manifest_rows '$src'" | wc -l | tr -d ' ')

  [[ "$paths" -eq "$rows" ]] || {
    echo "owned paths: $paths, manifest rows: $rows" >&2
    return 1
  }
  [[ "$rows" -gt 0 ]]
}

@test "AT08: install_manifest_write records the utilz version and the source commit" {
  local src="$BATS_TEST_TMPDIR/src-header"
  make_fake_src "$src"
  local out="$BATS_TEST_TMPDIR/manifest.sha256"

  run run_install_function "install_manifest_write '$src' '$out'"
  assert_success
  assert_file_exists "$out"

  local head_sha
  head_sha=$(git -C "$src" rev-parse HEAD)
  grep -q "^utilz-version	9.9.9$" "$out" || {
    echo "version header missing or wrong:" >&2; head -3 "$out" >&2; return 1
  }
  grep -q "^source-commit	$head_sha$" "$out" || {
    echo "source-commit header missing or wrong:" >&2; head -3 "$out" >&2; return 1
  }
}

@test "AT08: install_manifest_write is deterministic - no generated-at timestamp" {
  # A timestamp makes two manifests of identical bytes compare unequal, which
  # turns the one instrument that reports drift into one that always does (D4).
  local src="$BATS_TEST_TMPDIR/src-determ"
  make_fake_src "$src"
  local a="$BATS_TEST_TMPDIR/m-a" b="$BATS_TEST_TMPDIR/m-b"

  run_install_function "install_manifest_write '$src' '$a'"
  run_install_function "install_manifest_write '$src' '$b'"

  diff "$a" "$b" || {
    echo "two writes of one tree produced different manifests" >&2
    return 1
  }
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
  mkdir -p "$inst/bin"
  run_install_function "install_manifest_write '$src' '$inst/manifest.sha256'"

  run run_install_function "install_tree_kind '$inst'"
  assert_success
  assert_output "install"

  local other="$BATS_TEST_TMPDIR/other-kind"
  mkdir -p "$other"
  run run_install_function "install_tree_kind '$other'"
  assert_success
  assert_output "other"
}

@test "install_tree_state distinguishes clean, dirty and not-a-git-repo" {
  # "no changes" and "cannot tell" must never render as the same answer (D7).
  local src="$BATS_TEST_TMPDIR/src-state"
  make_fake_src "$src"

  run run_install_function "install_tree_state '$src'"
  assert_success
  assert_output "clean"

  # The gate reads the WHOLE tree, not the owned subset: a dirty file outside
  # the owned set still means the recorded commit does not describe the
  # checkout the bytes came from.
  printf 'scratch\n' > "$src/NOTES.md"
  run run_install_function "install_tree_state '$src'"
  assert_success
  assert_output "dirty"

  local nogit="$BATS_TEST_TMPDIR/nogit-state"
  mkdir -p "$nogit"
  run run_install_function "install_tree_state '$nogit'"
  assert_success
  assert_output "unknown"
}

# ============================================================================
# THE MANIFEST CHECKER (design.md D3, D4; AC06, AC08)
# ============================================================================

# Build an install tree from a source fixture: owned paths copied across, links
# recreated as links, plus the manifest. The copy here is the fixture's, not
# the installer's -- WP-02 owns the real one and WP-05 exercises it end to end.
make_fake_install() {
  local src="$1" dst="$2"
  local path

  while IFS= read -r path; do
    [[ -n "$path" ]] || continue
    mkdir -p "$dst/$(dirname "$path")"
    if [[ -L "$src/$path" ]]; then
      ln -s "$(readlink "$src/$path")" "$dst/$path"
    else
      cp "$src/$path" "$dst/$path"
    fi
  done < <(run_install_function "install_owned_paths '$src'")

  run_install_function "install_manifest_write '$src' '$dst/manifest.sha256'"
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

@test "install_manifest_check names a retargeted link" {
  # The AC06 case. All the dispatcher links resolve to one file, so a
  # resolved-content hash gives every one of them the same value and this
  # retarget reads as intact.
  local src="$BATS_TEST_TMPDIR/src-retarget" dst="$BATS_TEST_TMPDIR/inst-retarget"
  make_fake_src "$src"
  make_fake_install "$src" "$dst"
  rm "$dst/bin/alpha"
  ln -s other "$dst/bin/alpha"

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
