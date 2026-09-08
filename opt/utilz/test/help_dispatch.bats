#!/usr/bin/env bats
# help_dispatch.bats -- ST0016. --help has one home, and both forms agree.
#
# ST0015 one line up the same file: bin/utilz intercepted --help and -h on the
# SYMLINK path only, so 14 of 15 utilities answered `<util> --help` with the
# curated help/<name>.md and `utilz <util> --help` with their own terse inline
# usage. Every row runs BOTH forms -- a row exercising one cannot see a
# disagreement between them, and the disagreement WAS the defect.

load "test_helper.bash"

_utilities() {
  local d u
  for d in "$UTILZ_HOME"/opt/*/; do
    u=$(basename "$d")
    [ "$u" = "utilz" ] && continue
    [ -f "$d/$u.yaml" ] || continue
    echo "$u"
  done
}

_expected_count=15

@test "AT01 / AC01: --help is byte-identical across both invocation forms, for every utility" {
  local u a b n=0 bad=0
  for u in $(_utilities); do
    n=$((n + 1))
    a=$("$UTILZ_BIN_DIR/$u" --help 2>&1 </dev/null)
    b=$("$UTILZ_BIN_DIR/utilz" "$u" --help 2>&1 </dev/null)
    [ "$a" = "$b" ] || { echo "  $u: the two forms differ"; bad=$((bad + 1)); }
  done
  [ "$n" -eq "$_expected_count" ] || fail "checked $n, expected $_expected_count -- the glob is wrong, not the tree"
  [ "$bad" -eq 0 ] || fail "$bad utilities answer --help differently depending on how they were invoked"
}

@test "AT03 / AC03: -h is byte-identical across both forms too" {
  # -h and --help are separate arms in the intercept; covering one is not
  # covering the other, and a utility binding -h itself would show up here.
  local u a b n=0 bad=0
  for u in $(_utilities); do
    n=$((n + 1))
    a=$("$UTILZ_BIN_DIR/$u" -h 2>&1 </dev/null)
    b=$("$UTILZ_BIN_DIR/utilz" "$u" -h 2>&1 </dev/null)
    [ "$a" = "$b" ] || { echo "  $u: -h differs between forms"; bad=$((bad + 1)); }
  done
  [ "$n" -eq "$_expected_count" ] || fail "checked $n, expected $_expected_count"
  [ "$bad" -eq 0 ] || fail "$bad utilities answer -h differently by form"
}

@test "AT02 / AC02: the CURATED help/<name>.md is what both forms render" {
  # The terse inline usage is a second home for the same concern -- cleanz
  # carries ~80 lines of it against 232 in help/cleanz.md, overlapping and
  # free to drift. Asserting only "the two agree" would be satisfied by both
  # forms giving the TERSE text, which is agreement at the worse artifact.
  local u n=0 bad=0 out marker
  for u in $(_utilities); do
    n=$((n + 1))
    marker=$(sed -n '1p' "$UTILZ_HOME/help/$u.md" | tr -d '#' | sed 's/^ *//;s/ *$//')
    [ -n "$marker" ] || { echo "  $u: help file has no title line to key on"; bad=$((bad + 1)); continue; }
    out=$("$UTILZ_BIN_DIR/utilz" "$u" --help 2>&1 </dev/null)
    case "$out" in
      *"$marker"*) ;;
      *) echo "  $u: dispatcher form does not render help/$u.md (looked for '$marker')"; bad=$((bad + 1)) ;;
    esac
  done
  [ "$n" -eq "$_expected_count" ] || fail "checked $n, expected $_expected_count"
  [ "$bad" -eq 0 ] || fail "$bad utilities do not render their curated help from the dispatcher form"
}

@test "AT08 / AC07: --help stays usable non-interactively -- output, exit 0, no hang" {
  # A REAL PROPERTY, AND NOT THE ONE THIS ROW WAS FIRST WRITTEN TO HOLD.
  # It was meant to catch a future `glow -p`. IT CANNOT, and that was measured
  # rather than assumed: injecting `-p` into show_help left this exit 0 in 0s,
  # because glow's pager engages only when stdout is a TTY -- and a test, a
  # script and a CI step all redirect. So `-p` is INERT in exactly the context
  # the row was protecting. The pager invariant is held by AT07 against the
  # source instead; this row keeps the claim it can actually make.
  local u n=0 bad=0 out rc
  for u in $(_utilities); do
    n=$((n + 1))
    out=$(timeout 10 "$UTILZ_BIN_DIR/utilz" "$u" --help 2>&1 </dev/null); rc=$?
    [ "$rc" -eq 0 ] || { echo "  $u: exit $rc (124 = timed out, ie it paged or hung)"; bad=$((bad + 1)); continue; }
    [ -n "$out" ] || { echo "  $u: exited 0 with no output"; bad=$((bad + 1)); }
  done
  [ "$n" -eq "$_expected_count" ] || fail "checked $n, expected $_expected_count"
  [ "$bad" -eq 0 ] || fail "$bad utilities are not usable non-interactively"
}

@test "AT04 / AC04: --version is unregressed by sharing the intercept" {
  # The help half was added to the function that already answered --version.
  # A row proving the forms agree on --help says nothing about whether the
  # older claim survived the edit.
  local u a b n=0 bad=0
  for u in $(_utilities); do
    n=$((n + 1))
    a=$("$UTILZ_BIN_DIR/$u" --version 2>&1 | head -1)
    b=$("$UTILZ_BIN_DIR/utilz" "$u" --version 2>&1 | head -1)
    [ "$a" = "$b" ] || { echo "  $u: --version differs between forms"; bad=$((bad + 1)); }
    [[ "$a" =~ ^utilz:[0-9]+\.[0-9]+\.[0-9]+/${u}:[0-9]+\.[0-9]+\.[0-9]+$ ]] || bad=$((bad + 1))
  done
  [ "$n" -eq "$_expected_count" ] || fail "checked $n, expected $_expected_count"
  [ "$bad" -eq 0 ] || fail "$bad --version regressions"
}

@test "AT05 / AC05: ONE intercept, not two -- the dispatcher has no second --help arm" {
  # A --help-shaped intercept beside the --version one would rebuild exactly
  # the arrangement ST0015 removed: two homes agreeing by convention until
  # they do not. The absence is the claim.
  run grep -c 'predispatch_intercept' "$UTILZ_HOME/bin/utilz"
  assert_output "2"
  refute_file_contains "$UTILZ_HOME/bin/utilz" 'show_help "$UTIL_NAME"'
  refute_file_contains "$UTILZ_HOME/bin/utilz" 'show_version "$UTIL_NAME"'
}

@test "AT07 / AC07: show_help closes stdin on every renderer arm" {
  # THE HAZARD IS STDIN, NOT THE PAGER, and this row asserted the wrong thing
  # for its first half-hour. A bare `glow "$file"` with a terminal on stdin
  # hangs -- recorded twice here from real incidents. `-p` was the suspect and
  # was measured away: the pager is opt-in and injecting it changed nothing.
  # A row forbidding `-p` protects nothing; a row requiring the redirect
  # protects the thing that actually bites.
  #
  # INSPECTION, DELIBERATELY. The behavioural form needs a faithful pty, and a
  # `script`-allocated one does not reproduce it -- glow exits 1 emitting
  # terminal-query escapes rather than hanging. That harness is a thread of its
  # own, not a row in this one, and saying so is better than a green that has
  # never seen the failure.
  local line
  line=$(grep -nE '(glow|bat)[^|]*"\$help_file"' "$UTILZ_HOME/opt/utilz/lib/common.sh")
  [ -n "$line" ] || fail "no renderer invocation found in show_help -- the grep is wrong, not the tree"

  local n bad
  n=$(printf '%s\n' "$line" | grep -c .)
  bad=$(printf '%s\n' "$line" | grep -vc '</dev/null' || true)
  [ "$n" -ge 2 ] || fail "expected at least 2 renderer arms (glow, bat), found $n"
  [ "$bad" -eq 0 ] || {
    printf '%s\n' "$line" | grep -v '</dev/null'
    fail "$bad renderer arm(s) do not close stdin"
  }
}

@test "AT06 / AC06: a DIRECTLY executed utility keeps its own usage -- the arms are not deleted" {
  # THE BOUNDARY, NOT THE FEATURE, and it exists because prose does not fail.
  # ST0015 deleted thirteen --version arms because show_version was the only
  # producer either way. These arms are NOT that: they produce genuinely
  # different text, and they are the only usage a DIRECTLY executed script can
  # print -- `opt/<name>/<name> --help` is not a dispatched invocation and
  # nothing intercepts it. Without this row the next reader sees two adjacent
  # threads, reads them as one pattern, and deletes fifteen arms that nothing
  # replaces.
  #
  # expz is the documented exception and is NOT a defect: its arms call
  # show_help directly, so it has no inline usage to keep. The row therefore
  # asserts the ARM SURVIVES and direct execution still answers -- never that
  # the text differs, which expz would fail for the right reason.
  # prez is the second documented exception: its opt/prez/prez is a SHIM that
  # delegates to a compiled binary, and clap answers --help there. It carries
  # no arm and needs none. So the enforceable claim is that DIRECT EXECUTION
  # STILL ANSWERS for all 15, and that the 14 shell utilities which own a usage
  # still own it -- never a count bent to fit whatever the tree happens to hold.
  local u n=0 arms=0 noarm="" broke=""
  for u in $(_utilities); do
    [ -f "$UTILZ_HOME/opt/$u/$u" ] || fail "$u has no implementation file"
    n=$((n + 1))
    # SPACES AROUND THE PIPE ARE LEGAL AND todo USES THEM: `-h | --help)`.
    # The first form of this pattern demanded `-h|--help)` exactly and reported
    # todo as having no arm -- a population narrowed by an assumption about
    # spelling, which is the same error as matching one flag and missing the
    # other. Tolerate the whitespace rather than tidy the source to suit a test.
    if grep -qE '^[[:space:]]*(-h[[:space:]]*\|[[:space:]]*--help|--help[[:space:]]*\|[[:space:]]*-h)\)' "$UTILZ_HOME/opt/$u/$u"; then
      arms=$((arms + 1))
    else
      noarm="$noarm $u"
    fi
    # A UTILITY MAY REFUSE FOR A STATED PLATFORM REASON, AND THAT IS AN ANSWER.
    # macoz calls check_macos() at its line 431, BEFORE the arg loop at 451, so
    # `macoz --help` exits 1 on Linux saying "macoz utilities require macOS".
    # That predates ST0016 and is not a regression -- this row is new, and its
    # first form asserted platform-independent behaviour of a platform-specific
    # utility. CI caught it on Ubuntu; macOS cannot.
    #
    # The exemption is BEHAVIOURAL, not a name: refusing is accepted only when
    # the refusal SAYS it is about the platform. A utility that is simply broken
    # produces no such message and still fails this leg. Accepting any non-zero
    # exit here would have turned the row into one that cannot fail.
    # `|| rc=$?` IS LOAD-BEARING, NOT STYLE. An assignment from a command
    # substitution takes that command's exit status, and under bats' `set -e`
    # a non-zero one aborts the test AT THIS LINE -- before any `rc=$?` on the
    # next line can run. The first form of this did exactly that and CI caught
    # it on Ubuntu, where macoz exits 1; macOS cannot reach the branch at all
    # because all 15 exit 0 there. Same family as this project's note that a
    # check whose green is "no matches" aborts on success under `set -e`.
    local out rc=0
    out=$(UTILZ_HOME="$UTILZ_HOME" timeout 10 "$UTILZ_HOME/opt/$u/$u" --help 2>&1 </dev/null) || rc=$?
    if [ "$rc" -ne 0 ]; then
      printf '%s' "$out" | grep -qiE 'require(s)? (macos|linux|darwin)|only on (macos|linux)' \
        || broke="$broke $u"
    fi
  done
  [ "$n" -eq "$_expected_count" ] || fail "checked $n, expected $_expected_count"
  [ "$arms" -eq 14 ] || fail "$arms utilities carry their own --help arm, expected 14"
  [ "$noarm" = " prez" ] || fail "expected prez alone to delegate; got:$noarm"
  [ -z "$broke" ] || fail "these cannot answer --help when executed directly:$broke"
}
