#!/usr/bin/env bats
# formula.bats - tools/formula renders the Homebrew formula from a release tag
# and publishes it to the tap (dev, opt, brew contract T8, issue 0105)
#
# The script is run as hv runs it, from a repository's own tools/, so each case
# copies the real script and the real template into a fixture repository and
# runs that copy: the bytes under test are the bytes that ship to hv, and the
# git it asks is the fixture's, never this checkout's. The tap is a local bare
# repository; nothing here reaches GitHub.

load "test_helper.bash"

# A fixture repository at <repo> carrying tools/formula and the template,
# committed, with annotated tags 9.9.8 and 9.9.10 and a lightweight tag light.
make_formula_repo() {
  local repo="$1"
  mkdir -p "$repo/tools" "$repo/packaging/homebrew"
  cp "$UTILZ_HOME/tools/formula" "$repo/tools/formula"
  cp "$UTILZ_HOME/packaging/homebrew/utilz.rb" "$repo/packaging/homebrew/utilz.rb"
  git -C "$repo" init -q
  fixture_commit "$repo" init
  git -C "$repo" -c user.email=t@example.com -c user.name=t tag -a 9.9.8 -m "9.9.8"
  printf 'later\n' > "$repo/NOTES"
  fixture_commit "$repo" later
  git -C "$repo" -c user.email=t@example.com -c user.name=t tag -a 9.9.10 -m "9.9.10"
  git -C "$repo" tag light
}

# A bare tap at <tap>, with one commit, as a fresh tap has.
make_tap() {
  local tap="$1" w="$BATS_TEST_TMPDIR/tap-seed"
  mkdir -p "$w"
  git -C "$w" init -q
  printf '# tap\n' > "$w/README.md"
  fixture_commit "$w" seed
  git clone -q --bare "$w" "$tap"
}

# The formula's tag: and revision: values, as "<tag> <revision>".
formula_pin() {
  awk -F'"' '/^ *tag: / { t = $2 } /^ *revision: / { r = $2 } END { print t " " r }' "$1"
}

@test "the committed template holds exactly one tag and one revision placeholder (issue 0105)" {
  local t="$UTILZ_HOME/packaging/homebrew/utilz.rb"
  [[ "$(grep -o '@@TAG@@' "$t" | wc -l | tr -d ' ')" == 1 ]] || fail "the template's tag placeholders: $(grep -c '@@TAG@@' "$t")"
  [[ "$(grep -o '@@REVISION@@' "$t" | wc -l | tr -d ' ')" == 1 ]] || fail "the template's revision placeholders"
}

# Assert <file> is a formula brew can read for <tag> at <commit>: the exact
# tag: and revision: lines, and Ruby's own parse where Ruby is here.
assert_formula_reads() {
  local file="$1" tag="$2" commit="$3"
  grep -qxF "      tag:      \"$tag\"," "$file" || fail "no exact tag line for $tag: $(grep 'tag:' "$file")"
  grep -qxF "      revision: \"$commit\"" "$file" || fail "no exact revision line: $(grep 'revision:' "$file")"
  if command -v ruby >/dev/null 2>&1; then
    run ruby -c "$file"
    assert_success
  fi
}

@test "render writes a formula brew can parse under every bash, the 3.2 that macOS ships included (utilz-vc's C1)" {
  # bash 3.2 kept the double quotes written inside a ${var//pat/"$repl"}
  # replacement, so render under /bin/bash wrote tag: ""9.9.8"". Each bash on
  # this machine renders, and each result must read.
  local repo="$BATS_TEST_TMPDIR/repo" commit sh n=0
  make_formula_repo "$repo"
  commit=$(git -C "$repo" rev-parse '9.9.8^{commit}')
  for sh in /bin/bash "$(command -v bash)"; do
    [[ -x "$sh" ]] || continue
    n=$((n + 1))
    run "$sh" "$repo/tools/formula" render 9.9.8 "$BATS_TEST_TMPDIR/out-$n.rb"
    assert_success
    assert_formula_reads "$BATS_TEST_TMPDIR/out-$n.rb" 9.9.8 "$commit"
  done
  [[ $n -gt 0 ]] || fail "no bash to render with"
}

@test "render fills the tag and its commit from git, and changes nothing else (issue 0105)" {
  local repo="$BATS_TEST_TMPDIR/repo" out="$BATS_TEST_TMPDIR/utilz.rb" commit
  make_formula_repo "$repo"
  commit=$(git -C "$repo" rev-parse '9.9.8^{commit}')

  run "$repo/tools/formula" render 9.9.8 "$out"
  assert_success
  assert_output_contains "wrote $out, utilz 9.9.8 at $commit"
  [[ "$(formula_pin "$out")" == "9.9.8 $commit" ]] || fail "the formula reads: $(formula_pin "$out")"
  # The template with its placeholders filled, and nothing else changed.
  diff <(git -C "$repo" show 9.9.8:packaging/homebrew/utilz.rb | sed -e "s/@@TAG@@/9.9.8/" -e "s/@@REVISION@@/$commit/") "$out" || fail "render changed more than the placeholders"
  # The template itself is untouched.
  [[ -z "$(git -C "$repo" status --porcelain)" ]] || fail "render wrote into the repository: $(git -C "$repo" status --porcelain)"
}

@test "render refuses a tag that does not exist, and a lightweight one, writing nothing (issue 0105)" {
  local repo="$BATS_TEST_TMPDIR/repo" out="$BATS_TEST_TMPDIR/utilz.rb"
  make_formula_repo "$repo"

  run "$repo/tools/formula" render 0.0.0 "$out"
  assert_failure
  assert_output_contains "no tag '0.0.0'"
  assert_file_not_exists "$out"

  run "$repo/tools/formula" render light "$out"
  assert_failure
  assert_output_contains "lightweight"
  assert_file_not_exists "$out"
}

@test "render refuses a template without exactly one of each placeholder (issue 0105)" {
  local repo="$BATS_TEST_TMPDIR/repo" out="$BATS_TEST_TMPDIR/utilz.rb"
  make_formula_repo "$repo"
  printf '# @@TAG@@\n' >> "$repo/packaging/homebrew/utilz.rb"
  fixture_commit "$repo" two-tags
  git -C "$repo" -c user.email=t@example.com -c user.name=t tag -a 9.9.12 -m "9.9.12"

  run "$repo/tools/formula" render 9.9.12 "$out"
  assert_failure
  assert_output_contains "2 tag placeholder(s) and 1 revision placeholder(s)"
  assert_file_not_exists "$out"
}

@test "publish renders the NEWEST release into the tap, commits and pushes it, and a second run publishes nothing (issue 0105)" {
  local repo="$BATS_TEST_TMPDIR/repo" tap="$BATS_TEST_TMPDIR/tap.git" check="$BATS_TEST_TMPDIR/check" commit published
  make_formula_repo "$repo"
  make_tap "$tap"
  # 9.9.10 is newer than 9.9.8, which a string sort would put first.
  commit=$(git -C "$repo" rev-parse '9.9.10^{commit}')

  run env GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com "$repo/tools/formula" publish --tap "$tap"
  assert_success
  assert_output_contains "published utilz 9.9.10 at $commit to $tap"
  git clone -q "$tap" "$check"
  [[ "$(formula_pin "$check/Formula/utilz.rb")" == "9.9.10 $commit" ]] || fail "the tap's formula reads: $(formula_pin "$check/Formula/utilz.rb")"
  published=$(git -C "$tap" rev-parse HEAD)

  run env GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com "$repo/tools/formula" publish --tap "$tap"
  assert_success
  assert_output_contains "already carries utilz 9.9.10"
  [[ "$(git -C "$tap" rev-parse HEAD)" == "$published" ]] || fail "a second publish moved the tap from $published to $(git -C "$tap" rev-parse HEAD)"
}

# ============================================================================
# publish --pull: this machine's clone of the tap brought forward (ST0031/01)
# ============================================================================

# A bare tap at <tap>, and this machine's clone of it at <mine>. Each test
# names the tap <BATS_TEST_TMPDIR>/acme/homebrew-utilz.git, as Homebrew names a
# tap's repository, and its clone where a brew whose repository is
# <BATS_TEST_TMPDIR>/brew keeps it, Library/Taps/acme/homebrew-utilz.
make_tap_and_clone() {
  local tap="$1" mine="$2"
  mkdir -p "${tap%/*}"
  make_tap "$tap"
  git clone -q "$tap" "$mine"
}

# A brew in <stubdir> that names <repo> as its repository, by default
# <BATS_TEST_TMPDIR>/brew, or fails to name one when <repo> is empty, and
# records every call it is given in <stubdir>/brew.asked.
make_brew_stub() {
  local stubdir="$1" repo="${2-$BATS_TEST_TMPDIR/brew}"
  mkdir -p "$stubdir"
  cat > "$stubdir/brew" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >> "$stubdir/brew.asked"
[ "\$1" = "--repository" ] || exit 1
[ -n "$repo" ] || { echo "brew stub: no repository to name" >&2; exit 1; }
printf '%s\n' "$repo"
EOF
  chmod +x "$stubdir/brew"
}

# Run <repo>'s publish --tap <tap> --pull, the stub brew first on PATH.
publish_pull() {
  local repo="$1" tap="$2" stubdir="$3"
  run env PATH="$stubdir:$PATH" GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com "$repo/tools/formula" publish --tap "$tap" --pull
}

@test "publish --pull brings this machine's clone of the tap, where Homebrew keeps it, forward to the release published (ST0031/01)" {
  local repo="$BATS_TEST_TMPDIR/repo" tap="$BATS_TEST_TMPDIR/acme/homebrew-utilz.git" stub="$BATS_TEST_TMPDIR/stub"
  local mine="$BATS_TEST_TMPDIR/brew/Library/Taps/acme/homebrew-utilz" commit
  make_formula_repo "$repo"
  make_tap_and_clone "$tap" "$mine"
  make_brew_stub "$stub"
  commit=$(git -C "$repo" rev-parse '9.9.10^{commit}')

  publish_pull "$repo" "$tap" "$stub"
  assert_success
  assert_output_contains "published utilz 9.9.10 at $commit to $tap"
  assert_output_contains "this machine's clone of the tap at $mine pulled, its last commit utilz 9.9.10"
  [[ "$(git -C "$mine" rev-parse HEAD)" == "$(git -C "$tap" rev-parse HEAD)" ]] \
    || fail "the clone is at $(git -C "$mine" rev-parse HEAD), the tap at $(git -C "$tap" rev-parse HEAD)"
  assert_formula_reads "$mine/Formula/utilz.rb" 9.9.10 "$commit"
  # The stub records what it is asked, so its silence elsewhere means something.
  grep -qx -- --repository "$stub/brew.asked" || fail "brew was not asked for its repository"
}

@test "publish --pull finds the clone Homebrew keeps for an https tap url, in the lower case Homebrew keeps it in (ST0031/01)" {
  local repo="$BATS_TEST_TMPDIR/repo" tap="$BATS_TEST_TMPDIR/acme/homebrew-utilz.git" stub="$BATS_TEST_TMPDIR/stub"
  local mine="$BATS_TEST_TMPDIR/brew/Library/Taps/acme/homebrew-utilz" url="https://github.com/Acme/Homebrew-Utilz.git"
  local n="${GIT_CONFIG_COUNT:-0}" commit
  make_formula_repo "$repo"
  make_tap_and_clone "$tap" "$mine"
  make_brew_stub "$stub"
  commit=$(git -C "$repo" rev-parse '9.9.10^{commit}')

  # git reads the https url as the local tap, so nothing reaches the network.
  run env PATH="$stub:$PATH" "GIT_CONFIG_KEY_$n=url.$tap.insteadOf" "GIT_CONFIG_VALUE_$n=$url" "GIT_CONFIG_COUNT=$((n + 1))" \
    GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com \
    "$repo/tools/formula" publish --tap "$url" --pull
  assert_success
  assert_output_contains "published utilz 9.9.10 at $commit to $url"
  assert_output_contains "this machine's clone of the tap at $mine pulled"
  [[ "$(git -C "$mine" rev-parse HEAD)" == "$(git -C "$tap" rev-parse HEAD)" ]] \
    || fail "the clone is at $(git -C "$mine" rev-parse HEAD), the tap at $(git -C "$tap" rev-parse HEAD)"
}

@test "publish --pull on a tap that already carries the release still brings the clone forward, as a re-run after a failed pull does (ST0031/01)" {
  local repo="$BATS_TEST_TMPDIR/repo" tap="$BATS_TEST_TMPDIR/acme/homebrew-utilz.git" stub="$BATS_TEST_TMPDIR/stub"
  local mine="$BATS_TEST_TMPDIR/brew/Library/Taps/acme/homebrew-utilz"
  make_formula_repo "$repo"
  make_tap_and_clone "$tap" "$mine"
  make_brew_stub "$stub"
  # The first publish leaves the clone behind, as a pull that failed would.
  run env GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com "$repo/tools/formula" publish --tap "$tap"
  assert_success
  [[ "$(git -C "$mine" rev-parse HEAD)" != "$(git -C "$tap" rev-parse HEAD)" ]] || fail "the clone moved without --pull"

  publish_pull "$repo" "$tap" "$stub"
  assert_success
  assert_output_contains "already carries utilz 9.9.10"
  assert_output_contains "this machine's clone of the tap at $mine pulled, its last commit utilz 9.9.10"
  [[ "$(git -C "$mine" rev-parse HEAD)" == "$(git -C "$tap" rev-parse HEAD)" ]] \
    || fail "the clone is at $(git -C "$mine" rev-parse HEAD), the tap at $(git -C "$tap" rev-parse HEAD)"
}

@test "publish --pull says so, and succeeds, where Homebrew keeps no clone of the tap (ST0031/01)" {
  local repo="$BATS_TEST_TMPDIR/repo" tap="$BATS_TEST_TMPDIR/acme/homebrew-utilz.git" stub="$BATS_TEST_TMPDIR/stub"
  make_formula_repo "$repo"
  mkdir -p "${tap%/*}"
  make_tap "$tap"
  make_brew_stub "$stub"

  publish_pull "$repo" "$tap" "$stub"
  assert_success
  assert_output_contains "published utilz 9.9.10"
  assert_output_contains "no clone of the tap at $BATS_TEST_TMPDIR/brew/Library/Taps/acme/homebrew-utilz, so nothing here to pull"
}

@test "publish --pull says so, and succeeds, with no brew on PATH (ST0031/01)" {
  local repo="$BATS_TEST_TMPDIR/repo" tap="$BATS_TEST_TMPDIR/acme/homebrew-utilz.git"
  local mine="$BATS_TEST_TMPDIR/brew/Library/Taps/acme/homebrew-utilz" before
  make_formula_repo "$repo"
  make_tap_and_clone "$tap" "$mine"
  before=$(git -C "$mine" rev-parse HEAD)

  # The system's own directories alone: git and a bash, and no brew.
  run env PATH=/usr/bin:/bin GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com \
    "$repo/tools/formula" publish --tap "$tap" --pull
  assert_success
  assert_output_contains "published utilz 9.9.10"
  assert_output_contains "no brew on PATH, so no clone of the tap here to pull"
  [[ "$(git -C "$mine" rev-parse HEAD)" == "$before" ]] || fail "a clone moved with no brew to name it"
}

@test "publish --pull names a brew that cannot name its repository, the formula published (ST0031/01)" {
  local repo="$BATS_TEST_TMPDIR/repo" tap="$BATS_TEST_TMPDIR/acme/homebrew-utilz.git" stub="$BATS_TEST_TMPDIR/stub"
  local mine="$BATS_TEST_TMPDIR/brew/Library/Taps/acme/homebrew-utilz" check="$BATS_TEST_TMPDIR/check" commit
  make_formula_repo "$repo"
  make_tap_and_clone "$tap" "$mine"
  make_brew_stub "$stub" ""
  commit=$(git -C "$repo" rev-parse '9.9.10^{commit}')

  publish_pull "$repo" "$tap" "$stub"
  assert_failure
  assert_output_contains "published utilz 9.9.10 at $commit to $tap"
  assert_output_contains "brew cannot name its repository"
  assert_output_contains "the formula is published"
  git clone -q "$tap" "$check"
  assert_formula_reads "$check/Formula/utilz.rb" 9.9.10 "$commit"
}

@test "publish --pull pulls nothing, and asks brew nothing, when the publish fails (ST0031/01)" {
  local repo="$BATS_TEST_TMPDIR/repo" tap="$BATS_TEST_TMPDIR/acme/homebrew-utilz.git" stub="$BATS_TEST_TMPDIR/stub"
  local mine="$BATS_TEST_TMPDIR/brew/Library/Taps/acme/homebrew-utilz"
  make_formula_repo "$repo"
  make_tap_and_clone "$tap" "$mine"
  # The tap refuses every push, as a tap the publisher may not write to does.
  printf '#!/bin/sh\nexit 1\n' > "$tap/hooks/pre-receive"
  chmod +x "$tap/hooks/pre-receive"
  make_brew_stub "$stub"

  publish_pull "$repo" "$tap" "$stub"
  assert_failure
  assert_output_contains "cannot push the tap to $tap"
  # A refused push leaves the tap where the clone is, so the clone cannot show
  # a pull; that brew was never asked can, as the first --pull arm shows it is.
  [[ ! -e "$stub/brew.asked" ]] || fail "brew was asked: $(cat "$stub/brew.asked")"
}

@test "publish --pull names a clone it cannot bring forward without a merge, the formula published (ST0031/01)" {
  local repo="$BATS_TEST_TMPDIR/repo" tap="$BATS_TEST_TMPDIR/acme/homebrew-utilz.git" stub="$BATS_TEST_TMPDIR/stub"
  local mine="$BATS_TEST_TMPDIR/brew/Library/Taps/acme/homebrew-utilz" check="$BATS_TEST_TMPDIR/check" commit
  make_formula_repo "$repo"
  make_tap_and_clone "$tap" "$mine"
  # A commit the tap never had, so the clone and the tap part ways.
  printf 'local\n' > "$mine/LOCAL"
  fixture_commit "$mine" local
  make_brew_stub "$stub"
  commit=$(git -C "$repo" rev-parse '9.9.10^{commit}')

  publish_pull "$repo" "$tap" "$stub"
  assert_failure
  assert_output_contains "published utilz 9.9.10 at $commit to $tap"
  assert_output_contains "cannot bring $mine forward without a merge"
  assert_output_contains "the formula is published, so pull it by hand before brew upgrade"
  git clone -q "$tap" "$check"
  assert_formula_reads "$check/Formula/utilz.rb" 9.9.10 "$commit"
}

@test "publish renders the template the tag carries, never the working tree's (utilz-vc's W7)" {
  local repo="$BATS_TEST_TMPDIR/repo" tap="$BATS_TEST_TMPDIR/tap.git" check="$BATS_TEST_TMPDIR/check"
  make_formula_repo "$repo"
  make_tap "$tap"
  # An edit no commit holds, and one committed after the newest tag: neither
  # is what 9.9.10 carries, so neither reaches the tap.
  printf '# committed after the tag\n' >> "$repo/packaging/homebrew/utilz.rb"
  fixture_commit "$repo" after-tag
  printf '# not committed\n' >> "$repo/packaging/homebrew/utilz.rb"

  run env GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com "$repo/tools/formula" publish --tap "$tap"
  assert_success
  git clone -q "$tap" "$check"
  if grep -q -e 'committed after the tag' -e 'not committed' "$check/Formula/utilz.rb"; then
    fail "publish rendered the working tree's template: $(tail -3 "$check/Formula/utilz.rb")"
  fi
  assert_formula_reads "$check/Formula/utilz.rb" 9.9.10 "$(git -C "$repo" rev-parse '9.9.10^{commit}')"
}

@test "render refuses a tag whose commit carries no template (utilz-vc's W7)" {
  local repo="$BATS_TEST_TMPDIR/repo"
  make_formula_repo "$repo"
  git -C "$repo" rm -q packaging/homebrew/utilz.rb
  fixture_commit "$repo" no-template
  git -C "$repo" -c user.email=t@example.com -c user.name=t tag -a 9.9.11 -m "9.9.11"

  run "$repo/tools/formula" render 9.9.11 "$BATS_TEST_TMPDIR/out.rb"
  assert_failure
  assert_output_contains "carries no formula template"
  assert_file_not_exists "$BATS_TEST_TMPDIR/out.rb"
}

@test "tools/formula is in no install: the runtime set names nothing under tools/ or packaging/" {
  run run_install_function "utilz_runtime_set '$UTILZ_HOME'"
  assert_success
  refute_output_contains "tools/"
  refute_output_contains "packaging/"
}
