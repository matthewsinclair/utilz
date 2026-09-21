#!/usr/bin/env bats
# install_lib.bats - ST0014/WP-01: the owned set, the prefix reader, the manifest
#
# The owned-set tests run against the REAL tree rather than a fixture, on
# purpose. A synthetic tree has whatever shape the fixture author imagined,
# and the defect these tests exist to catch is precisely an enumeration that
# matches the imagined shape and not the real one (design.md D2).

load "test_helper.bash"

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

@test "install_owned_paths names the built showreel binary beside prez's (issue 0024)" {
  # The shim execs either binary -- `prez showreel <...>` hands over to the
  # second -- so an owned set naming only prez's shipped an install that handed
  # over to a file it never published. Named rather than enumerated for the
  # same reason as prez's: it is gitignored, and absent must fail the publish.
  run run_install_function "install_owned_paths '$UTILZ_HOME'"
  assert_success
  printf '%s\n' "$output" | grep -qx "opt/prez/crate/target/release/showreel" || {
    echo "owned set is missing showreel's binary" >&2
    return 1
  }
}

@test "install_build_prez asks cargo for the whole workspace, so showreel is built too (issue 0024)" {
  # The crate root is prez's package and the workspace declares no
  # default-members, so a build there makes prez and what prez links, and never
  # showreel. The shim's own build carries --workspace for exactly this reason;
  # the publish's did not. A stub cargo records what it was asked, so nothing
  # here builds a crate.
  local src="$BATS_TEST_TMPDIR/src-build" stub="$BATS_TEST_TMPDIR/stubbin"
  mkdir -p "$src/opt/prez/crate" "$stub"
  : > "$src/opt/prez/crate/Cargo.toml"
  cat > "$stub/cargo" <<EOF
#!/bin/sh
printf '%s\n' "\$*" > "$BATS_TEST_TMPDIR/cargo.args"
EOF
  chmod +x "$stub/cargo"

  run env PATH="$stub:$PATH" bash -c "source '$UTILZ_HOME/opt/utilz/lib/common.sh'; source '$UTILZ_HOME/opt/utilz/lib/install.sh'; install_build_prez '$src'"
  assert_success
  [ -f "$BATS_TEST_TMPDIR/cargo.args" ] || fail "the stub cargo was never called"
  run cat "$BATS_TEST_TMPDIR/cargo.args"
  assert_output_contains "--workspace"
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
  fixture_commit "$src" twin

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
# ci-state (issue 0016): CI's verdict on the published commit, recorded
# ============================================================================

# A gh that waits <delay> seconds, answers <stdout>, says <stderr> and exits
# <rc>, and records the directory it was asked from and the arguments.
make_gh_stub() {
  local stub="$1" answer="$2" rc="${3:-0}" message="${4:-}" delay="${5:-0}"
  cat > "$stub" <<EOF
#!/bin/sh
{ pwd -P; printf '%s\n' "\$*"; } > "$stub.asked"
sleep $delay
[ -n "$answer" ] && printf '%s\n' "$answer"
[ -n "$message" ] && printf '%s\n' "$message" >&2
exit $rc
EOF
  chmod +x "$stub"
}

# Echo <manifest>'s ci-state row as "<state> <detail>", or nothing.
ci_state_row() {
  awk -F'\t' '$1 == "ci-state" { print $2 " " $3; exit }' "$1"
}

@test "AT08: a publish asks CI about the commit it publishes and records the answer (issue 0016)" {
  local src="$BATS_TEST_TMPDIR/src-ci-publish" dst="$BATS_TEST_TMPDIR/dst-ci-publish" gh="$BATS_TEST_TMPDIR/gh"
  make_fake_src "$src"
  make_gh_stub "$gh" "completed|success|105"

  run run_install_function "UTILZ_HOME='$src'; INSTALL_GH='$gh'; install_verb_install --prefix '$dst'"
  assert_success
  [ "$(ci_state_row "$dst/manifest.sha256")" = "success 105" ] \
    || fail "recorded: $(ci_state_row "$dst/manifest.sha256")"

  # It asked about the commit being published, of the workflow CI runs, from
  # inside the tree, so gh finds the repository from the tree's own remotes.
  run cat "$gh.asked"
  assert_output_contains "$(cd "$src" && pwd -P)"
  assert_output_contains "run list --commit $(git -C "$src" rev-parse HEAD) --workflow tests.yml"
}

@test "AT08: install_manifest_write records the CI state it is handed, and unknown when handed none (issue 0016)" {
  local src="$BATS_TEST_TMPDIR/src-ci-write" out="$BATS_TEST_TMPDIR/m" state
  make_fake_src "$src"
  state=$(printf 'failure\t106')

  run run_install_function "install_manifest_write '$src' '$out' '$state'"
  assert_success
  [ "$(ci_state_row "$out")" = "failure 106" ] || fail "recorded: $(ci_state_row "$out")"

  # Written outside a publish, with no answer to record: unknown, and why.
  run run_install_function "install_manifest_write '$src' '$out'"
  assert_success
  [ "$(ci_state_row "$out")" = "unknown not asked: this manifest was not written by a publish" ] \
    || fail "recorded: $(ci_state_row "$out")"
}

@test "AT08: install_ci_state reads each answer CI gives as itself (issue 0016)" {
  local src="$BATS_TEST_TMPDIR/src-ci-answers" gh="$BATS_TEST_TMPDIR/gh" sha
  make_fake_src "$src"
  sha=$(git -C "$src" rev-parse HEAD)

  local answer want
  while IFS=';' read -r answer want; do
    make_gh_stub "$gh" "$answer"
    run run_install_function "INSTALL_GH='$gh'; install_ci_state '$src' '$sha'"
    assert_success
    [ "$(printf '%s' "$output" | tr '\t' ' ')" = "$want" ] \
      || fail "gh answering '$answer' gave '$output', not '$want'"
  done <<'ROWS'
completed|success|101;success 101
completed|failure|102;failure 102
in_progress||103;pending 103
;none no run
ROWS
}

@test "AT08: install_ci_state answers unknown when gh is not installed, and says so (issue 0016)" {
  local src="$BATS_TEST_TMPDIR/src-ci-absent"
  make_fake_src "$src"

  run run_install_function "INSTALL_GH='$BATS_TEST_TMPDIR/no-such-gh'; install_ci_state '$src' deadbeef"
  assert_success
  [ "$(printf '%s' "$output" | tr '\t' ' ')" = "unknown $BATS_TEST_TMPDIR/no-such-gh is not installed" ] \
    || fail "answered: $output"
}

@test "AT08: install_ci_state answers unknown with gh's own first line when gh refuses, never success (issue 0016)" {
  # The refusal gh gives non-interactively when two remotes point at GitHub
  # and no default is set: the failure the design names.
  local src="$BATS_TEST_TMPDIR/src-ci-refused" gh="$BATS_TEST_TMPDIR/gh"
  local refusal="multiple remotes detected [origin upstream]. please specify which repo to use with -R"
  make_fake_src "$src"
  make_gh_stub "$gh" "" 1 "$refusal"

  run run_install_function "INSTALL_GH='$gh'; install_ci_state '$src' deadbeef"
  assert_success
  [ "$(printf '%s' "$output" | tr '\t' ' ')" = "unknown $refusal" ] || fail "answered: $output"
}

@test "AT08: install_ci_state kills a gh that outlives the deadline and answers unknown, without waiting on it (issue 0016)" {
  local src="$BATS_TEST_TMPDIR/src-ci-slow" gh="$BATS_TEST_TMPDIR/gh"
  make_fake_src "$src"
  make_gh_stub "$gh" "completed|success|104" 0 "" 5

  local t0=$SECONDS
  run run_install_function "INSTALL_GH='$gh'; INSTALL_CI_DEADLINE=1; install_ci_state '$src' deadbeef"
  assert_success
  [ $((SECONDS - t0)) -lt 4 ] || fail "the query waited $((SECONDS - t0))s on a gh given 1s"
  [ "$(printf '%s' "$output" | tr '\t' ' ')" = "unknown $gh did not answer within 1s" ] \
    || fail "answered: $output"
}

@test "AT08: the verifier reads the ci-state row as a header, and the publish's path count leaves it out (issue 0016)" {
  local src="$BATS_TEST_TMPDIR/src-ci-rows" dst="$BATS_TEST_TMPDIR/dst-ci-rows"
  make_fake_src "$src"
  local m="$dst/manifest.sha256" paths

  run_publish "$src" "$dst"
  assert_success
  paths=$(awk -F'\t' '$1 == "file" || $1 == "link"' "$m" | wc -l | tr -d ' ')
  assert_output_contains "at $dst -- $paths paths"

  # The row written here rather than by the writer, so this half does not
  # rest on the writer's. A kind the verifier does not know is refused as
  # unrecognised, so this fails until ci-state is a key the verifier reads.
  { printf 'ci-state\tsuccess\t101\n'; grep -v $'^ci-state\t' "$m"; } > "$m.tmp" && mv "$m.tmp" "$m"
  run run_install_function "install_manifest_check '$dst'"
  assert_success
  assert_output ""
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

# ============================================================================
# tools/ci-state: install_ci_state in the release core's words (ST0019 WP-01)
# ============================================================================
#
# The stub is found on PATH under the name `gh`, because the script is run as
# the release core runs it, as a command, and INSTALL_GH can only be moved by
# code that has sourced install.sh. Put first on PATH, it is the gh the real
# install_ci_state asks, so these drive the whole path the core will drive.

# Run tools/ci-state on <sha> with a gh stub on PATH that answers <answer>,
# exiting <rc> with <message> on stderr.
run_ci_state() {
  local sha="$1" answer="$2" rc="${3:-0}" message="${4:-}"
  local dir="$BATS_TEST_TMPDIR/gh-on-path"
  mkdir -p "$dir"
  make_gh_stub "$dir/gh" "$answer" "$rc" "$message"
  run env PATH="$dir:$PATH" "$UTILZ_HOME/tools/ci-state" "$sha"
}

@test "AT01 (ST0019 AC-01.3): tools/ci-state answers each of the core's five verdicts, one per CI answer" {
  local answer want
  while IFS=';' read -r answer want; do
    run_ci_state deadbeef "$answer"
    assert_success
    [ "$(printf '%s' "$output" | tr '\t' ' ')" = "$want" ] \
      || fail "gh answering '$answer' gave '$output', not '$want'"
  done <<'ROWS'
completed|success|101;green 101
completed|failure|102;failed failure: 102
completed|cancelled|103;failed cancelled: 103
in_progress||104;pending 104
;none no run
ROWS
}

@test "AT01 (ST0019 AC-01.3): tools/ci-state answers unknown with gh's own reason when gh refuses, never green" {
  local refusal="multiple remotes detected [origin upstream]. please specify which repo to use with -R"
  run_ci_state deadbeef "" 1 "$refusal"
  assert_success
  [ "$(printf '%s' "$output" | tr '\t' ' ')" = "unknown $refusal" ] || fail "answered: $output"
}

@test "AT01 (ST0019 AC-01.3): tools/ci-state asks through install_ci_state, about the sha it is given, from the tree" {
  local sha
  sha=$(git -C "$UTILZ_HOME" rev-parse HEAD)
  run_ci_state "$sha" "completed|success|105"
  assert_success

  # The query install_ci_state makes, word for word: no second gh query exists.
  run cat "$BATS_TEST_TMPDIR/gh-on-path/gh.asked"
  assert_output_contains "$(cd "$UTILZ_HOME" && pwd -P)"
  assert_output_contains "run list --commit $sha --workflow tests.yml"
}

@test "AT01 (ST0019 AC-01.3): tools/ci-state refuses anything but one sha, exiting non-zero so the core reads unknown" {
  run "$UTILZ_HOME/tools/ci-state"
  [ "$status" -eq 2 ] || fail "no argument exited $status"
  run "$UTILZ_HOME/tools/ci-state" a b
  [ "$status" -eq 2 ] || fail "two arguments exited $status"
}

@test "AT01 (ST0019 AC-01.3): tools/ci-state is in no install: the owned set names nothing under tools/" {
  [ -x "$UTILZ_HOME/tools/ci-state" ] || fail "tools/ci-state is missing, so this would pass vacuously"
  run run_install_function "install_owned_paths '$UTILZ_HOME'"
  assert_success
  if printf '%s\n' "$output" | grep -q '^tools/'; then
    fail "the publish would ship: $(printf '%s\n' "$output" | grep '^tools/')"
  fi
}
