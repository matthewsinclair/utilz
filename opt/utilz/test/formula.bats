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
  local repo="$BATS_TEST_TMPDIR/repo" tap="$BATS_TEST_TMPDIR/tap.git" check="$BATS_TEST_TMPDIR/check" commit
  make_formula_repo "$repo"
  make_tap "$tap"
  # 9.9.10 is newer than 9.9.8, which a string sort would put first.
  commit=$(git -C "$repo" rev-parse '9.9.10^{commit}')

  run env GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com "$repo/tools/formula" publish --tap "$tap"
  assert_success
  assert_output_contains "published utilz 9.9.10 at $commit to $tap"
  git clone -q "$tap" "$check"
  [[ "$(formula_pin "$check/Formula/utilz.rb")" == "9.9.10 $commit" ]] || fail "the tap's formula reads: $(formula_pin "$check/Formula/utilz.rb")"

  run env GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com "$repo/tools/formula" publish --tap "$tap"
  assert_success
  assert_output_contains "already carries utilz 9.9.10"
  [[ "$(git -C "$tap" rev-list --count HEAD)" == 2 ]] || fail "the tap has $(git -C "$tap" rev-list --count HEAD) commits after a second publish"
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
