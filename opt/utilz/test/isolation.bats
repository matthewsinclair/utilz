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

# The suites under opt/ that define <function>() without calling <call> in
# it, one per line, relative to UTILZ_HOME; 2 when no suite defines
# <function>(), so a guard over an empty list never passes. Both guards
# below ask it (issues 0088 and 0091).
_suites_missing_call() {
  local fn="$1" call="$2" f n=0
  while IFS= read -r f; do
    n=$((n + 1))
    if ! awk -v fn="$fn" -v call="$call" '$0 ~ "^" fn "\\(\\) \\{" { inside = 1; next } inside && /^\}/ { exit } inside && $0 ~ "(^|[^_[:alnum:]])" call "([^_[:alnum:]]|$)" { found = 1 } END { exit !found }' "$f"; then
      echo "${f#"$UTILZ_HOME"/}"
    fi
  done < <(grep -l -E "^$fn\\(\\) \\{" "$UTILZ_HOME"/opt/*/test/*.bats)
  [[ $n -gt 0 ]] || return 2
}

# EVERY SUITE'S TEARDOWN ENDS THE HELPER'S (issue 0088). A suite's own
# teardown() replaces the helper's, and version_dispatch.bats' did: its
# per-test dir, any gpg home and the cd back were skipped for each of its
# tests, and the utilz suite left 11 dirs in TMPDIR a run. So every suite under
# opt/ that defines teardown() calls utilz_teardown in it.
@test "every suite that defines its own teardown() calls utilz_teardown in it (issue 0088)" {
  local missing status=0
  missing=$(_suites_missing_call teardown utilz_teardown) || status=$?
  [[ $status -ne 2 ]] || fail "no suite defines its own teardown(), so the guard checked nothing"
  [[ -z "$missing" ]] || fail "these define teardown() without calling utilz_teardown: ${missing//$'\n'/ }"
}

# EVERY SUITE'S OWN SETUP ISOLATES AS THE HELPER'S DOES (issue 0091). A
# suite's own setup() replaces the helper's, and with it isolate_tool_homes,
# and menuz.bats' and macos.bats' did: their tests ran with the user's unison,
# gpg home and git signing, and menuz.bats' fixture commit asked an inherited
# signing config's gpg to sign. So every suite under opt/ that defines setup()
# calls isolate_tool_homes in it.
@test "every suite that defines its own setup() calls isolate_tool_homes in it (issue 0091)" {
  local missing status=0
  missing=$(_suites_missing_call setup isolate_tool_homes) || status=$?
  [[ $status -ne 2 ]] || fail "no suite defines its own setup(), so the guard checked nothing"
  [[ -z "$missing" ]] || fail "these define setup() without calling isolate_tool_homes: ${missing//$'\n'/ }"
}
