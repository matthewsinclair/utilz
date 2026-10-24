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

@test "AT07: utilz_runtime_set names exactly the utilities' bin symlinks" {
  run run_install_function "utilz_runtime_set '$UTILZ_HOME'"
  assert_success

  # The one roster here; the count is read from it, so a new utility is one
  # word, not a word and a number. menuz (ST0027) joined on 2026-10-16.
  local names=(arngz cleanz clipz cryptz expz gitz lnrel macoz mdagg menuz pdf2md prez retry stampz syncz todo xtrct)
  local listed
  listed=$(printf '%s\n' "$output" | grep -c '^bin/')
  # Each utility's symlink + bin/utilz itself. bin/devbin and bin/.devbin/
  # are vendored.
  [[ "$listed" -eq $((${#names[@]} + 1)) ]] || {
    echo "expected $((${#names[@]} + 1)) bin/ entries, got $listed" >&2
    printf '%s\n' "$output" | grep '^bin/' >&2
    return 1
  }

  local name
  for name in "${names[@]}"; do
    printf '%s\n' "$output" | grep -qx "bin/$name" || {
      echo "owned set is missing bin/$name" >&2
      return 1
    }
  done
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

@test "install_prefix_configured refuses an unset UTILZ_INSTALL_PREFIX by name, saying who sets it (issue 0105)" {
  run run_install_function "unset UTILZ_INSTALL_PREFIX; install_prefix_configured"
  # rc 127 is the library failing to load, and a bare assert_failure cannot
  # tell it from the refusal.
  assert_exit_code 1
  # AC05: unset is refused BY NAME, and the refusal says where it comes from.
  assert_output_contains "UTILZ_INSTALL_PREFIX is not set"
  assert_output_contains "Molt's"
  assert_output_contains "sleeve config sets it"
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

# A gh that waits <delay> seconds, answers <stdout>, says <stderr> and exits
# <rc>, and records the directory it was asked from and the arguments.
make_gh_stub() {
  local stub="$1" answer="$2" rc="${3:-0}" message="${4:-}" delay="${5:-0}" jobs="${6:-}"
  cat > "$stub" <<EOF
#!/bin/sh
# TWO QUESTIONS, TWO ANSWERS (issue 0062). install_ci_state asks \`run list\`
# for the runs on a commit; install_ci_jobs asks \`run view\` for one run's
# jobs, and only when the verdict is a conclusion that is not success. A stub
# that answered the run list to both would feed the jobs reader rows it was
# never given, so the arms are told apart here rather than by luck.
case "\$*" in
  *"run view"*)
    { pwd -P; printf '%s\n' "\$*"; } > "$stub.asked-jobs"
    # No jobs answer configured means "this read did not work", which is the
    # case that must add NOTHING to the detail. It keeps every expectation
    # written before 0062 exactly as it was.
    [ -n "$jobs" ] || exit 1
    printf '%s\n' "$jobs"
    exit 0
    ;;
esac
{ pwd -P; printf '%s\n' "\$*"; } > "$stub.asked"
sleep $delay
[ -n "$answer" ] && printf '%s\n' "$answer"
[ -n "$message" ] && printf '%s\n' "$message" >&2
exit $rc
EOF
  chmod +x "$stub"
}

# Echo <manifest>'s CI verdict as "<state> <detail>", or nothing.
ci_state_row() {
  local state detail
  state=$(awk '/^# ci_state: / { print substr($0, 13); exit }' "$1")
  detail=$(awk '/^# ci_detail: / { print substr($0, 14); exit }' "$1")
  [[ -n "$state" ]] && printf '%s %s\n' "$state" "$detail"
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
completed|null|104;unknown a completed run with no conclusion: 104
;none no run
ROWS
}

@test "AT08: install_ci_state reads every run on the commit and answers with the worst (issue 0052)" {
  # A release commit carries TWO runs since the macOS legs moved to release
  # tags (0046): the branch push, and the tag push that runs them. GitHub
  # documents no order between the two push events of one `git push`, so the
  # verdict is the worst of every run on the commit and never the newest one.
  local src="$BATS_TEST_TMPDIR/src-ci-many" gh="$BATS_TEST_TMPDIR/gh" sha
  make_fake_src "$src"
  sha=$(git -C "$src" rev-parse HEAD)

  local rows want
  while IFS=';' read -r rows want; do
    make_gh_stub "$gh" "$(printf '%b' "$rows")"
    run run_install_function "INSTALL_GH='$gh'; install_ci_state '$src' '$sha'"
    assert_success
    [ "$(printf '%s' "$output" | tr '\t' ' ')" = "$want" ] \
      || fail "runs '$rows' gave '$output', not '$want'"
  done <<'ROWS'
completed|success|201\ncompleted|failure|202;failure 202 of 2 runs on this commit
completed|failure|203\ncompleted|success|204;failure 203 of 2 runs on this commit
completed|success|205\nin_progress||206;pending 206 of 2 runs on this commit
completed|success|207\ncompleted|success|208;success 207 of 2 runs on this commit
completed|success|209;success 209
ROWS

  # AND THE REQUEST ITSELF, because no answer can prove it: the stub prints
  # what it is told whatever it was asked, so a `--limit 1` that reads one run
  # of two passes every case above. The number here is the guard.
  run cat "$gh.asked"
  assert_output_contains "--limit 20"
}

@test "AT08: a run that concluded without success is asked WHICH jobs failed (issue 0062)" {
  # RED-FIRST SHAPE: before 0062 every row below answered `failure 301` and
  # nothing else, so "the suite went red" and "no job ran at all" -- opposite
  # actions for whoever is reading mid-cut -- were the same string.
  #
  # The last two rows are the ones a run-level read can never give. A run that
  # concluded `failure` with no FAILING job in it was refused rather than
  # tested, and nothing about the code was measured.
  local src="$BATS_TEST_TMPDIR/src-ci-jobs" gh="$BATS_TEST_TMPDIR/gh" sha
  make_fake_src "$src"
  sha=$(git -C "$src" rev-parse HEAD)

  local jobs want
  while IFS=';' read -r jobs want; do
    make_gh_stub "$gh" "completed|failure|301" 0 "" 0 "$(printf '%b' "$jobs")"
    run run_install_function "INSTALL_GH='$gh'; install_ci_state '$src' '$sha'"
    assert_success
    [ "$(printf '%s' "$output" | tr '\t' ' ')" = "$want" ] \
      || fail "jobs '$jobs' gave '$output', not '$want'"
  done <<'ROWS'
failure|Rust (ubuntu-latest);failure 301 (failed: Rust (ubuntu-latest))
success|Test on Ubuntu\nfailure|Rust (ubuntu-latest);failure 301 (failed: Rust (ubuntu-latest))
failure|a\nfailure|b\nfailure|c\nfailure|d;failure 301 (failed: a, b, c and 1 more)
success|Test on Ubuntu\nskipped|Test on macOS;failure 301 (no job failed, so the run was refused rather than tested)
ROWS
}

@test "AT08: a run whose jobs cannot be read still answers, and adds nothing (issue 0062)" {
  # THE CONTROL FOR THE TEST ABOVE. install_ci_state's contract is that it
  # never fails and never guesses, so a second question it could not get an
  # answer to must leave the first answer exactly as it was -- the run id is
  # still there for a human to follow. Without this, a gh that answers the run
  # list and refuses the job list would turn a usable verdict into a worse one.
  local src="$BATS_TEST_TMPDIR/src-ci-nojobs" gh="$BATS_TEST_TMPDIR/gh" sha
  make_fake_src "$src"
  sha=$(git -C "$src" rev-parse HEAD)

  # No sixth argument: the stub refuses `run view`.
  make_gh_stub "$gh" "completed|failure|302"
  run run_install_function "INSTALL_GH='$gh'; install_ci_state '$src' '$sha'"
  assert_success
  [ "$(printf '%s' "$output" | tr '\t' ' ')" = "failure 302" ] \
    || fail "an unreadable job list gave '$output', not 'failure 302'"

  # AND IT ASKED: the enrichment is attempted rather than quietly skipped.
  [ -f "$gh.asked-jobs" ] || fail "install_ci_state never asked for the jobs"
  run cat "$gh.asked-jobs"
  assert_output_contains "run view 302"
}

@test "AT08: a SUCCESS verdict asks no second question (issue 0062)" {
  # The enrichment is on the not-success path alone, so the common case costs
  # exactly the one call it always did. Without this the green path would grow
  # a per-release gh call nobody asked for and nobody would notice.
  local src="$BATS_TEST_TMPDIR/src-ci-green" gh="$BATS_TEST_TMPDIR/gh" sha
  make_fake_src "$src"
  sha=$(git -C "$src" rev-parse HEAD)

  make_gh_stub "$gh" "completed|success|303" 0 "" 0 "failure|Should Not Be Read"
  run run_install_function "INSTALL_GH='$gh'; install_ci_state '$src' '$sha'"
  assert_success
  [ "$(printf '%s' "$output" | tr '\t' ' ')" = "success 303" ] \
    || fail "green gave '$output', not 'success 303'"
  [ ! -f "$gh.asked-jobs" ] || fail "a green verdict asked for jobs: $(cat "$gh.asked-jobs")"
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
  sed -i.bak -e 's/^# ci_state: .*/# ci_state: success/' -e 's/^# ci_detail: .*/# ci_detail: 101/' "$m" && rm -f "$m.bak"
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
  run run_install_function "utilz_runtime_set '$UTILZ_HOME'"
  assert_success
  if printf '%s\n' "$output" | grep -q '^tools/'; then
    fail "the publish would ship: $(printf '%s\n' "$output" | grep '^tools/')"
  fi
}

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

  run run_install_function "UTILZ_HOME='$inner'; INSTALL_GH='$BATS_TEST_TMPDIR/no-gh'; install_verb_install --prefix '$BATS_TEST_TMPDIR/dst'"
  assert_failure
  assert_output_contains "source: $inner (unknown, none)"
}
