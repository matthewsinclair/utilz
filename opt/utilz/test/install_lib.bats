#!/usr/bin/env bats
# install_lib.bats - ST0014/WP-01: the owned set, the prefix reader, the manifest
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
# THE PREFIX READER (design.md D6, AC05; UTILZ_INSTALL_PREFIX since issue 0105)
# ============================================================================

@test "install_prefix_configured refuses an unset UTILZ_INSTALL_PREFIX by name, saying what it is and how to name one (issues 0105, 0121)" {
  run run_install_function "unset UTILZ_INSTALL_PREFIX; install_prefix_configured"
  # rc 127 is the library failing to load, and a bare assert_failure cannot
  # tell it from the refusal.
  assert_exit_code 1
  # AC05: unset is refused BY NAME, and the refusal says how to name one. It
  # claims no sleeve: a brew-only machine rightly leaves the prefix unset, and
  # use opt reaches this refusal as install does (issue 0121).
  assert_output_contains "UTILZ_INSTALL_PREFIX is not set"
  assert_output_contains "Set it to name one"
  assert_output_contains "--prefix DIR"
  refute_output_contains "sleeve"
}

@test "install_prefix_configured refuses an empty UTILZ_INSTALL_PREFIX as unset (issue 0105)" {
  run run_install_function "UTILZ_INSTALL_PREFIX=''; install_prefix_configured"
  assert_exit_code 1
  assert_output_contains "UTILZ_INSTALL_PREFIX is not set"
}

@test "install_prefix_configured expands a leading tilde" {
  run run_install_function "UTILZ_INSTALL_PREFIX='~/Devel/opt/utilz'; install_prefix_configured"
  assert_success
  assert_output "$HOME/Devel/opt/utilz"
  refute_output_contains "~"
}

@test "install_prefix_configured returns an absolute prefix unchanged" {
  run run_install_function "UTILZ_INSTALL_PREFIX=/opt/utilz; install_prefix_configured"
  assert_success
  assert_output "/opt/utilz"
}

@test "install_prefix_configured reads no key from utilz.yaml, so no install ships a prefix (issue 0105)" {
  # The key was install.prefix in the committed yaml until 0105, and every
  # keg shipped it. A yaml that still carries one is not read.
  local src="$BATS_TEST_TMPDIR/src-yamlkey"
  make_fake_src "$src"
  printf 'name: utilz\ninstall:\n  prefix: /opt/from-yaml\n' > "$src/opt/utilz/utilz.yaml"

  run run_install_function "unset UTILZ_INSTALL_PREFIX; UTILZ_HOME='$src'; install_prefix_configured"
  assert_exit_code 1
  refute_output_contains "/opt/from-yaml"
  [[ "$(yq '.install' "$UTILZ_HOME/opt/utilz/utilz.yaml")" == "null" ]] || fail "the committed utilz.yaml still carries an install key"
}

# ============================================================================
# THE MANIFEST (design.md D4, AC06, AC07)
# ============================================================================

@test "AT07: install_manifest_rows writes each line in shasum -a 256 -c form, links hashed through (issue 0105)" {
  local src="$BATS_TEST_TMPDIR/src-body"
  make_fake_src "$src"

  run run_install_function "install_manifest_rows '$src'"
  assert_success

  # Every line is "<64 hex>  <path>", and the dispatcher links carry the
  # dispatcher's own sha256, as shasum reads a link.
  local bad dispatcher alpha
  bad=$(printf '%s\n' "$output" | grep -v -E '^[0-9a-f]{64}  [^ ]' || true)
  [[ -z "$bad" ]] || fail "lines not in shasum form: $bad"
  dispatcher=$(printf '%s\n' "$output" | awk '$2 == "bin/utilz" { print $1 }')
  alpha=$(printf '%s\n' "$output" | awk '$2 == "bin/alpha" { print $1 }')
  [[ -n "$dispatcher" && "$alpha" == "$dispatcher" ]] || fail "bin/alpha hashed as '$alpha', the dispatcher as '$dispatcher'"

  # And the system's own tool reads the body back from the tree's root.
  printf '%s\n' "$output" > "$BATS_TEST_TMPDIR/body"
  run bash -c "cd '$src' && shasum -a 256 -c '$BATS_TEST_TMPDIR/body'"
  assert_success
}

@test "AT07: install_manifest_rows refuses a bin/ entry that is not a link to the dispatcher (issue 0105)" {
  # THE STRUCTURAL RULE THAT REPLACES THE LINK ROW. Two links to two
  # byte-identical files hash alike, so the body alone cannot see a link
  # retargeted at the wrong file (ST0014 AC06). Every link git names in
  # Utilz's runtime set is bin/<name> -> utilz, so the write refuses any other.
  local src="$BATS_TEST_TMPDIR/src-twin"
  make_fake_src "$src"
  cp "$src/bin/utilz" "$src/bin/twin"
  ln -s twin "$src/bin/gamma"
  fixture_commit "$src" twin

  run run_install_function "install_manifest_rows '$src'"
  assert_failure
  assert_output_contains "is not a link to the dispatcher"
}

@test "AT08: install_manifest_rows emits exactly one row per owned path" {
  local src="$BATS_TEST_TMPDIR/src-rows"
  make_fake_src "$src"

  local paths rows
  paths=$(run_install_function "utilz_runtime_set '$src'" | wc -l | tr -d ' ')
  rows=$(run_install_function "install_manifest_rows '$src'" | wc -l | tr -d ' ')

  [[ "$paths" -eq "$rows" ]] || {
    echo "owned paths: $paths, manifest rows: $rows" >&2
    return 1
  }
  [[ "$rows" -gt 0 ]]
}

@test "AT08: install_manifest_write writes the contract's header, then the body (issue 0105)" {
  local src="$BATS_TEST_TMPDIR/src-header"
  make_fake_src "$src"
  local out="$BATS_TEST_TMPDIR/manifest.sha256"

  run run_install_function "install_manifest_write '$src' '$out' '' \"\$(install_manifest_rows '$src')\" brew"
  assert_success
  assert_file_exists "$out"

  local head_sha
  head_sha=$(git -C "$src" rev-parse HEAD)
  # The contract's four, first and in its order (T3), then Utilz's own.
  [[ "$(sed -n 1,4p "$out")" == "# tool: utilz
# version: 9.9.9
# source_commit: $head_sha
# managed_by: brew" ]] || fail "the header's first four lines are: $(sed -n 1,4p "$out")"
  grep -q "^# source_tree: $(cd "$src" && pwd)$" "$out" || fail "no source_tree line: $(head -8 "$out")"
  grep -q '^# ci_state: unknown$' "$out" || fail "no ci_state line: $(head -8 "$out")"
  grep -q '^# ci_detail: not asked: ' "$out" || fail "no ci_detail line: $(head -8 "$out")"

  # The body follows the header, and every body line names a path.
  [[ "$(run_install_function "install_manifest_path_count '$out'")" -eq "$(run_install_function "utilz_runtime_set '$src'" | wc -l | tr -d ' ')" ]] || fail "the body does not name every runtime path"

  run run_install_function "utilz_manifest_value '$out' source_commit; utilz_manifest_value '$out' managed_by"
  assert_success
  [[ "$output" == "$head_sha"$'\n'"brew" ]] || fail "utilz_manifest_value read: $output"
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

# A bin/devbin in <src> that waits <delay> seconds, answers <stdout>, says
# <stderr> and exits <rc>. It records the directory it was asked from and its
# arguments in $BATS_TEST_TMPDIR/devbin.asked, and the cut's ref it was handed,
# DEVBIN_RELEASE_TAG and DEVBIN_RELEASE_PASSED_OVER or `unset` for each, in
# devbin.env. A publish asks the release core's reader, `bin/devbin ci-state`,
# in the tree it publishes (ST0031/01). Left untracked, the stub is no part of
# the runtime set, which leaves bin/devbin out (UTILZ_RUNTIME_EXCLUDE_RE), so
# the tree stays clean.
make_devbin_stub() {
  local src="$1" answer="$2" rc="${3:-0}" message="${4:-}" delay="${5:-0}"
  cat > "$src/bin/devbin" <<EOF
#!/bin/sh
{ pwd -P; printf '%s\n' "\$*"; } > "$BATS_TEST_TMPDIR/devbin.asked"
printf '%s %s\n' "\${DEVBIN_RELEASE_TAG-unset}" "\${DEVBIN_RELEASE_PASSED_OVER-unset}" > "$BATS_TEST_TMPDIR/devbin.env"
sleep $delay
[ -n "$answer" ] && printf '%s\n' "$answer"
[ -n "$message" ] && printf '%s\n' "$message" >&2
exit $rc
EOF
  chmod +x "$src/bin/devbin"
}

# Echo <manifest>'s CI verdict as "<state> <detail>", or nothing.
ci_state_row() {
  local state detail
  state=$(awk '/^# ci_state: / { print substr($0, 13); exit }' "$1")
  detail=$(awk '/^# ci_detail: / { print substr($0, 14); exit }' "$1")
  [[ -n "$state" ]] && printf '%s %s\n' "$state" "$detail"
}

# The verdict words <function>'s case in <file> takes, as "a|b|c": the first
# line in the function whose first word is green.
verdict_list() {
  awk -v fn="$2() {" 'index($0, fn) == 1 { f = 1 } f && $1 == "green" { sub(/\).*/, ""); gsub(/[ \t]/, ""); print; exit }' "$1"
}

# Assert the reader was asked about <src>'s HEAD alone, from inside <src>.
assert_ci_asked() {
  local src="$1"
  run cat "$BATS_TEST_TMPDIR/devbin.asked"
  assert_success
  assert_output "$(cd "$src" && pwd -P)
ci-state $(git -C "$src" rev-parse HEAD)"
}

@test "AT08: a publish asks the release core's reader about the commit it publishes, from the tree, and records its word and detail (ST0031/01)" {
  local src="$BATS_TEST_TMPDIR/src-ci-publish" dst="$BATS_TEST_TMPDIR/dst-ci-publish"
  make_fake_src "$src"
  make_devbin_stub "$src" "$(printf 'green\trun 105')"

  run run_install_function "UTILZ_HOME='$src'; install_verb_install --prefix '$dst'"
  assert_success
  [ "$(ci_state_row "$dst/manifest.sha256")" = "green run 105" ] \
    || fail "recorded: $(ci_state_row "$dst/manifest.sha256")"
  assert_ci_asked "$src"
}

@test "AT08: a reader that exits non-zero records unknown with its own first line, never the verdict it printed (ST0031/01)" {
  local src="$BATS_TEST_TMPDIR/src-ci-refused" dst="$BATS_TEST_TMPDIR/dst-ci-refused"
  make_fake_src "$src"
  make_devbin_stub "$src" "$(printf 'green\trun 106')" 1 "release.repo cannot be read"

  run run_install_function "UTILZ_HOME='$src'; install_verb_install --prefix '$dst'"
  assert_success
  [ "$(ci_state_row "$dst/manifest.sha256")" = "unknown bin/devbin ci-state exited 1: release.repo cannot be read" ] \
    || fail "recorded: $(ci_state_row "$dst/manifest.sha256")"
  assert_ci_asked "$src"

  # With nothing on stderr, what it printed is what it said.
  make_devbin_stub "$src" "$(printf 'green\trun 109')" 1
  run run_install_function "UTILZ_HOME='$src'; install_verb_install --prefix '$dst-quiet'"
  assert_success
  [ "$(ci_state_row "$dst-quiet/manifest.sha256")" = "unknown bin/devbin ci-state exited 1: green run 109" ] \
    || fail "recorded: $(ci_state_row "$dst-quiet/manifest.sha256")"
}

@test "AT08: a reader that prints nothing records unknown, and says so (ST0031/01)" {
  local src="$BATS_TEST_TMPDIR/src-ci-silent" dst="$BATS_TEST_TMPDIR/dst-ci-silent"
  make_fake_src "$src"
  make_devbin_stub "$src" "" 0 "devbin: nothing to say"

  run run_install_function "UTILZ_HOME='$src'; install_verb_install --prefix '$dst'"
  assert_success
  [ "$(ci_state_row "$dst/manifest.sha256")" = "unknown bin/devbin ci-state printed nothing" ] \
    || fail "recorded: $(ci_state_row "$dst/manifest.sha256")"
  assert_ci_asked "$src"
}

@test "AT08: a reader that prints a word that is no verdict records unknown with the line it printed (ST0031/01)" {
  local src="$BATS_TEST_TMPDIR/src-ci-wordless" dst="$BATS_TEST_TMPDIR/dst-ci-wordless"
  make_fake_src "$src"
  # gh's own word for a green run, which is no verdict of the core's.
  make_devbin_stub "$src" "$(printf 'success\t107')"

  run run_install_function "UTILZ_HOME='$src'; install_verb_install --prefix '$dst'"
  assert_success
  [ "$(ci_state_row "$dst/manifest.sha256")" = 'unknown bin/devbin ci-state printed "success 107", which is no verdict' ] \
    || fail "recorded: $(ci_state_row "$dst/manifest.sha256")"
  assert_ci_asked "$src"
}

@test "AT08: each verdict word the core takes from a query is recorded as itself, with its detail (ST0031/01)" {
  local src="$BATS_TEST_TMPDIR/src-ci-words" words word row
  local -a list
  make_fake_src "$src"
  words=$(verdict_list "$UTILZ_HOME/bin/.devbin/lib/release.steps" release_ci_verdict)
  [ -n "$words" ] || fail "found no verdict list in the core's release_ci_verdict"
  IFS='|' read -r -a list <<<"$words"
  for word in "${list[@]}"; do
    make_devbin_stub "$src" "$(printf '%s\trun for %s' "$word" "$word")"
    run run_install_function "UTILZ_HOME='$src'; install_verb_install --prefix '$BATS_TEST_TMPDIR/dst-ci-$word'"
    assert_success
    row=$(ci_state_row "$BATS_TEST_TMPDIR/dst-ci-$word/manifest.sha256")
    [ "$row" = "$word run for $word" ] || fail "the reader said $word, and the publish recorded: $row"
  done
}

@test "AT08: the publish takes the very verdict words the core's release_ci_verdict takes (ST0031/01)" {
  local core mine
  core=$(verdict_list "$UTILZ_HOME/bin/.devbin/lib/release.steps" release_ci_verdict)
  mine=$(verdict_list "$UTILZ_HOME/opt/utilz/lib/install.sh" install_ci_verdict)
  [ -n "$core" ] || fail "found no verdict list in the core's release_ci_verdict"
  [ "$mine" = "$core" ] || fail "install_ci_verdict takes $mine, and the core's release_ci_verdict takes $core"
}

@test "AT08: a cut's ref left in the environment never reaches the reader, so it reads the commit's own runs (ST0031/01)" {
  local src="$BATS_TEST_TMPDIR/src-ci-env" dst="$BATS_TEST_TMPDIR/dst-ci-env"
  make_fake_src "$src"
  make_devbin_stub "$src" "$(printf 'green\trun 108')"

  run run_install_function "export DEVBIN_RELEASE_TAG=candidate/9.9.9 DEVBIN_RELEASE_PASSED_OVER=1; UTILZ_HOME='$src'; install_verb_install --prefix '$dst'"
  assert_success
  [ "$(ci_state_row "$dst/manifest.sha256")" = "green run 108" ] || fail "recorded: $(ci_state_row "$dst/manifest.sha256")"
  run cat "$BATS_TEST_TMPDIR/devbin.env"
  assert_success
  assert_output "unset unset"
}

@test "AT08: a reader that outlives INSTALL_CI_DEADLINE is stopped and records unknown, the publish not waiting on it (ST0031/01)" {
  local src="$BATS_TEST_TMPDIR/src-ci-slow" dst="$BATS_TEST_TMPDIR/dst-ci-slow" deadline=1 delay=10 t0
  make_fake_src "$src"
  make_devbin_stub "$src" "$(printf 'green\trun 104')" 0 "" "$delay"

  t0=$SECONDS
  run run_install_function "UTILZ_HOME='$src'; INSTALL_CI_DEADLINE=$deadline; install_verb_install --prefix '$dst'"
  assert_success
  [ $((SECONDS - t0)) -lt "$delay" ] || fail "the publish waited $((SECONDS - t0))s on a reader given ${deadline}s"
  [ "$(ci_state_row "$dst/manifest.sha256")" = "unknown bin/devbin ci-state did not answer within ${deadline}s" ] \
    || fail "recorded: $(ci_state_row "$dst/manifest.sha256")"
  assert_ci_asked "$src"
}

@test "AT08: a tree with no reader to run records unknown, naming the tree (ST0031/01)" {
  local src="$BATS_TEST_TMPDIR/src-ci-none" dst="$BATS_TEST_TMPDIR/dst-ci-none" row
  make_fake_src "$src"

  run run_install_function "UTILZ_HOME='$src'; install_verb_install --prefix '$dst'"
  assert_success
  row=$(ci_state_row "$dst/manifest.sha256")
  [[ "$row" == "unknown bin/devbin ci-state could not run in $src (exit 127)"* ]] || fail "recorded: $row"
}

@test "AT08: install_manifest_write records the CI state it is handed, and unknown when handed none (issue 0016)" {
  local src="$BATS_TEST_TMPDIR/src-ci-write" out="$BATS_TEST_TMPDIR/m" state
  make_fake_src "$src"
  state=$(printf 'failed\trun 106')

  run run_install_function "install_manifest_write '$src' '$out' '$state'"
  assert_success
  [ "$(ci_state_row "$out")" = "failed run 106" ] || fail "recorded: $(ci_state_row "$out")"

  # Written outside a publish, with no answer to record: unknown, and why.
  run run_install_function "install_manifest_write '$src' '$out'"
  assert_success
  [ "$(ci_state_row "$out")" = "unknown not asked: this manifest was not written by a publish" ] \
    || fail "recorded: $(ci_state_row "$out")"
}

@test "AT08: the verifier reads the CI lines as header, and the publish's path count leaves them out (issue 0016)" {
  local src="$BATS_TEST_TMPDIR/src-ci-rows" dst="$BATS_TEST_TMPDIR/dst-ci-rows"
  make_fake_src "$src"
  local m="$dst/manifest.sha256" paths

  run_publish "$src" "$dst"
  assert_success
  paths=$(grep -c -E '^[0-9a-f]{64}  ' "$m")
  assert_output_contains "at $dst -- $paths paths"

  # The lines written here rather than by the writer, so this half does not
  # rest on the writer's: a header line in another value is still a header.
  sed -i.bak -e 's/^# ci_state: .*/# ci_state: green/' -e 's/^# ci_detail: .*/# ci_detail: run 101/' "$m" && rm -f "$m.bak"
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
  done < <(run_install_function "utilz_runtime_set '$src'")

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

@test "0044: a source tree that is not a repository announces no commit, never an enclosing repository's" {
  local outer="$BATS_TEST_TMPDIR/outer" inner
  make_fake_src "$outer"
  inner="$outer/nested"
  make_fake_src "$inner"
  rm -rf "$inner/.git"
  # The enclosing repository has a HEAD git would happily report for $inner.
  [ -n "$(git -C "$inner" rev-parse --short HEAD 2>/dev/null)" ] \
    || fail "git reads no enclosing HEAD from the nested tree, so this would pass vacuously"

  run run_install_function "UTILZ_HOME='$inner'; install_verb_install --prefix '$BATS_TEST_TMPDIR/dst'"
  assert_failure
  assert_output_contains "source: $inner (unknown, none)"
}
