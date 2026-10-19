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

# EVERY SUITE'S TEARDOWN ENDS THE HELPER'S (issue 0088). A suite's own
# teardown() replaces the helper's, and version_dispatch.bats' did: its
# per-test dir, any gpg home and the cd back were skipped for each of its
# tests, and the utilz suite left 11 dirs in TMPDIR a run. So every suite under
# opt/ that defines teardown() calls utilz_teardown in it.
@test "every suite that defines its own teardown() calls utilz_teardown in it (issue 0088)" {
  local f n=0 missing=""
  while IFS= read -r f; do
    n=$((n + 1))
    if ! awk '/^teardown\(\) \{/ { inside = 1; next } inside && /^\}/ { exit } inside && /(^|[^_[:alnum:]])utilz_teardown([^_[:alnum:]]|$)/ { found = 1 } END { exit !found }' "$f"; then
      missing="$missing ${f#"$UTILZ_HOME"/}"
    fi
  done < <(grep -l -E '^teardown\(\) \{' "$UTILZ_HOME"/opt/*/test/*.bats)
  [[ $n -gt 0 ]] || fail "no suite defines its own teardown(), so the guard checked nothing"
  [[ -z "$missing" ]] || fail "these define teardown() without calling utilz_teardown:$missing"
}
