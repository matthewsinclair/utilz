#!/usr/bin/env bats
# isolation.bats - the test helper keeps the user's own state out of every
# test (issue 0082). The checks for unison and gpg live with the suites that
# run them (syncz.bats, cryptz.bats); the helper-wide ones live here.

load "test_helper.bash"

# NO TEST SIGNS WITH THE USER'S KEY (issue 0082). Where the user's git config
# sets commit.gpgsign or tag.gpgsign, every commit and tag a test made was
# signed with the user's own key, and under the helper's fail-closed GNUPGHOME
# it would be refused. The helper turns signing off for every git a test runs.
# Here a global config turns signing on and points gpg.program at a stub that
# records any call and fails, so no real gpg is ever asked: the fixture commit
# and the annotated tag must both succeed without calling it.
@test "a fixture commit and a tag sign nothing where git config says to sign (issue 0082)" {
  local repo="$BATS_TEST_TMPDIR/repo" stub="$BATS_TEST_TMPDIR/gpg-stub" calls="$BATS_TEST_TMPDIR/gpg.calls"
  printf '#!/bin/bash\necho "$*" >> "%s"\nexit 1\n' "$calls" > "$stub"
  chmod +x "$stub"
  printf '[commit]\n\tgpgsign = true\n[tag]\n\tgpgsign = true\n[gpg]\n\tprogram = %s\n' "$stub" > "$BATS_TEST_TMPDIR/gitconfig"
  export GIT_CONFIG_GLOBAL="$BATS_TEST_TMPDIR/gitconfig"

  git init --quiet "$repo"
  echo one > "$repo/file.txt"
  fixture_commit "$repo" "one"
  git -C "$repo" -c user.email=t@example.com -c user.name=t tag -a v1 -m v1

  [[ ! -e "$calls" ]] || fail "git asked gpg to sign: $(cat "$calls")"
  [[ "$(git -C "$repo" log -1 --format=%G?)" == "N" ]] || fail "the commit carries a signature"
}
