# shellcheck shell=bash
# shellcheck disable=SC2034 # the counters and STRICT are read by the sourcing suite's report
#
# The black-box harness every suite under crate/test/ sources (issue 0040).
#
# **ONE COPY, BY vc's RULING ON 2026-09-19.** acceptance.sh and
# theme-addressing.sh each carried this harness until ST0021's video.sh would
# have made a third. The helpers moved here unchanged, as the union of both
# files', so a suite may call any of them. Each suite keeps its own report
# block, because the two print different summaries.
#
# **SOURCED, NEVER RUN, AND NOT NAMED crate/test/*.sh.** The test driver runs
# every crate/test/*.sh as a suite and refuses one that is not executable
# (opt/utilz/lib/common.sh), so this file lives in lib/, outside that glob.
#
# A suite sources this after setting HERE, and sets WORK before calling
# renders, refuses or exits, which leave stderr in $WORK. The arguments parsed
# here are the suite's own: `.` keeps the caller's "$@".

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  printf 'lib/harness.sh is sourced by the suites in crate/test/, never run: %s\n' "$0" >&2
  exit 2
fi

STRICT=0
ARGS=()
for arg in "$@"; do
  case "$arg" in
    --strict) STRICT=1 ;;
    *) ARGS+=("$arg") ;;
  esac
done
WANT=("${ARGS[@]+"${ARGS[@]}"}")
PASSED=0; FAILED=0; SKIPPED=0; NOT_APPLICABLE=0
AT=""; AT_FAILS=0; AT_SKIPS=0

want() {
  [ ${#WANT[@]} -eq 0 ] && return 0
  local id
  for id in "${WANT[@]}"; do [ "$id" = "$1" ] && return 0; done
  return 1
}

start() { AT="$1"; AT_FAILS=0; AT_SKIPS=0; printf '\n%s -- %s\n' "$1" "$2"; }

ok()   { printf '  ok    %s\n' "$1"; }
bad()  { printf '  FAIL  %s\n' "$1"; AT_FAILS=$((AT_FAILS + 1)); }

# check <description> <actual> <expected>
check() { if [ "$2" = "$3" ]; then ok "$1 = $2"; else bad "$1 = $2, wanted $3"; fi; }

# absent <description> <needle> <file>
absent() {
  local n; n=$(grep -c -- "$2" "$3" 2>/dev/null || true)
  if [ "${n:-0}" -eq 0 ]; then ok "$1 (absent)"; else bad "$1: found $n occurrence(s) of '$2'"; fi
}

# present <description> <needle> <file>
present() {
  local n; n=$(grep -c -- "$2" "$3" 2>/dev/null || true)
  if [ "${n:-0}" -gt 0 ]; then ok "$1 (present)"; else bad "$1: '$2' not found"; fi
}

finish() {
  if [ "$AT_FAILS" -gt 0 ]; then
    printf '%s: FAIL (%d)\n' "$AT" "$AT_FAILS"; FAILED=$((FAILED + 1)); return
  fi
  PASSED=$((PASSED + 1))
  # A PARTLY-RUN AT MUST NOT READ AS A CLEAN PASS. Without this, "AT08 passed"
  # meant "the themes are readable" OR "no browser was present" and nothing in
  # the output separated them (vc, 29 Aug 2026) -- the exact adjacency this file
  # is written against, inside the newest check in it.
  if [ "$AT_SKIPS" -gt 0 ]; then printf '%s: PASS, but %d check(s) DID NOT RUN\n' "$AT" "$AT_SKIPS"
  else printf '%s: PASS\n' "$AT"; fi
}

# A whole AT that could not run.
skip() { printf '%s: SKIP -- %s\n' "$AT" "$1"; SKIPPED=$((SKIPPED + 1)); }

# One limb of an AT that could not run. Counted, so the summary cannot call the
# suite clean, and printed, so the reason is in front of whoever reads it.
unchecked() { printf '  SKIP  %s\n' "$1"; AT_SKIPS=$((AT_SKIPS + 1)); SKIPPED=$((SKIPPED + 1)); }

# THE THIRD OUTCOME, AND THE CONDITION IS THE PLATFORM RATHER THAN THE CHECK'S
# DIFFICULTY. Ruled by hv 2026-09-08, the first exception to "a SKIP is not a
# pass", and it is narrow on purpose.
#
# `unchecked` means DID NOT RUN and reddens --strict, which is right for a tool
# that is missing but installable: the check exists and this machine failed to
# perform it. `not_applicable` means the check CANNOT EXIST HERE -- it asks
# something about a platform this run is not on -- so counting it as did-not-run
# demands a run that can never happen.
#
# The discriminator must be the platform predicate, never `command -v <tool>`.
# Gating on a missing tool makes any machine lacking it silently exempt,
# including one that should have it; gating on `uname` cannot. And it is only
# honest while the check runs SOMEWHERE: the keychain half runs on every macOS
# leg, so the coverage exists and this leg is the one that cannot host it. A
# not_applicable check with no leg that DOES run it is dead, and should be
# deleted rather than excused.
not_applicable() { printf '  N/A   %s\n' "$1"; NOT_APPLICABLE=$((NOT_APPLICABLE + 1)); }

# shaped <description> <extended-regex> <file> -- for an assertion where the
# STRUCTURE is the requirement and a bare substring would not see a malformed
# string that happens to contain the token. AT05's "names theme-file:" wording
# licensed exactly that check, and it could not see `'theme-file:'=./x.css`.
shaped() {
  if grep -Eq -- "$2" "$3"; then ok "$1 (shape)"; else bad "$1: no match for /$2/"; fi
}

# same <description> <fileA> <fileB> -- byte identity, the point of AT01/AT05
same() {
  if cmp -s "$2" "$3"; then ok "$1 (identical)"
  else bad "$1: artifacts differ ($(wc -c <"$2" | tr -d ' ') vs $(wc -c <"$3" | tr -d ' ') bytes)"; fi
}

# renders <description> <cmd...> -- the invocation must SUCCEED
renders() {
  local d="$1"; shift
  if "$@" >/dev/null 2>"$WORK/renders.err"; then ok "$d (rendered)"
  else bad "$d: refused -- $(head -1 "$WORK/renders.err")"; fi
}

# refuses <description> <cmd...> -- the invocation must FAIL, and its stderr is
# left in $WORK/refuses.err for the caller to assert against. NEVER pipe this:
# `$?` would be the last stage's, which is how a refusal check stops checking.
refuses() {
  local d="$1"; shift
  if "$@" >/dev/null 2>"$WORK/refuses.err"; then
    bad "$d: rendered when it should have refused"
  else
    ok "$d (refused)"
  fi
}

# exits <description> <code> <cmd...> -- the invocation must exit with EXACTLY
# <code>, and like refuses it leaves stderr in $WORK/refuses.err. A check that
# accepts any non-zero exit cannot tell a refusal from a crash, and every theme
# refusal promises 2.
exits() {
  local d="$1" want="$2" rc; shift 2
  "$@" >/dev/null 2>"$WORK/refuses.err"
  rc=$?
  if [ "$rc" -eq "$want" ]; then ok "$d (exit $rc)"; else bad "$d: exited $rc, not $want"; fi
}

# ordered <description> <first> <second> <file> -- both fixed strings are
# present and <first> is on an earlier line. For a list whose ORDER is part of
# the message: two present checks pass a list printed backwards.
ordered() {
  local a b
  a=$(grep -n -F -- "$2" "$4" 2>/dev/null | head -1 | cut -d: -f1)
  b=$(grep -n -F -- "$3" "$4" 2>/dev/null | head -1 | cut -d: -f1)
  if [ -n "$a" ] && [ -n "$b" ] && [ "$a" -lt "$b" ]; then ok "$1 (in order)"
  else bad "$1: '$2' (line ${a:-absent}) is not before '$3' (line ${b:-absent})"; fi
}

# unwritten <description> <file> -- a refusal wrote nothing. An artifact left
# behind by a refused build is one a caller can mistake for the answer.
unwritten() {
  if [ -e "$2" ]; then bad "$1: $2 was written"; else ok "$1 (nothing written)"; fi
}

# chrome() CAME HERE FROM acceptance.sh WITH ST0021, UNCHANGED, because video.sh
# needs the same answer to the same question: which browser does the one finder
# resolve? It asks $BIN, so every suite that calls it sets BIN to the prez
# binary. It stays the harness's last definition, so a clean load of this file
# returns 0 to the stanza that sources it.
# ASKS THE TOOL. Does not mirror it. (AC18a, WP-07's browser half, 7 Sep.)
#
# This function used to hand-copy src/drive.rs's APP_PATHS and PATH_NAMES, and
# the copy was wrong: drive.rs gained the six PATH names and this did not, so
# on Linux the TOOL found a browser and the HARNESS did not -- five ATs
# degraded to skips and --strict turned a correct build RED while the message
# said "no Chrome or Chromium installed" about a browser the tool under test
# was happily driving. Invisible on macOS, where both were only ever run.
#
# `prez browser` is the door that lets this ask. It takes no deck, prints the
# path pdf and present would drive, and refuses through drive::find's own
# refusal -- the one that names every path probed. There is now ONE list, in
# Rust, and the check that this stayed true is AT15(a): the harness must hold
# no browser literal at all, which is greppable, unlike "the two lists agree".
#
# The other candidate -- have the refusal name its list unconditionally -- was
# rejected in design section 12: a refusal only fires when nothing is found,
# which cannot be provoked on a machine that HAS a browser, and that is every
# machine this runs on bar CI's browserless leg.
chrome() {
  local found=""

  # THE OVERRIDE (AC18b), checked BEFORE asking so it wins outright:
  #   PREZ_TEST_BROWSER=/nonexistent      -> no browser; every browser AT skips
  #   PREZ_TEST_BROWSER=/path/to/chromium -> drive exactly that one
  #
  # Without it the browserless path CANNOT BE EXERCISED on a machine that has
  # Chrome, so the control proving --strict matters is a control that can never
  # go red -- the exact class this file is written against, sitting in the file
  # itself. It stays ahead of the tool because its job is to force an answer
  # the tool would not give.
  #
  # A set-but-not-executable value returns 1 rather than falling through.
  # Falling through would make "force the refusal path" mean "force it unless
  # this machine happens to have Chrome", which is the thing being fixed.
  if [ -n "${PREZ_TEST_BROWSER:-}" ]; then
    if [ -x "$PREZ_TEST_BROWSER" ]; then
      found="$PREZ_TEST_BROWSER"
    else
      # SAY WHY. The call sites all skip with "no Chrome or Chromium
      # installed", which is FALSE when the override caused it -- and a skip
      # carrying the wrong reason is the class AC18 is about, so producing one
      # here to test for it would be its own joke.
      printf 'note: PREZ_TEST_BROWSER=%s is not executable, so no browser is offered.\n' \
        "$PREZ_TEST_BROWSER" >&2
      return 1
    fi
  elif [ ! -x "$BIN" ]; then
    # A MISSING BINARY IS NOT A MISSING BROWSER. Without this the call sites
    # skip saying "no Chrome or Chromium installed" when the truth is that the
    # build failed -- a skip with a false reason, which is precisely what AC18
    # exists to forbid. The build at the top of this file swallows its output,
    # so this is the first place that can tell.
    printf 'note: %s is not executable, so the tool cannot be asked which browser it resolves.\n' \
      "$BIN" >&2
    return 1
  else
    # Relay the tool's OWN refusal rather than inventing one: it names every
    # path it probed, which is a report the caller can act on.
    if ! found="$("$BIN" browser 2>&1)"; then
      printf '%s\n' "$found" >&2
      return 1
    fi
  fi

  [ -n "$found" ] || return 1

  # ANNOUNCE ON RESOLVE (AC17), at ONE site.
  #
  # This function announced loudly when it REFUSED and said nothing when it
  # resolved and handed a browser to four ATs to launch -- the louder half was
  # the harmless half, so the same command gave 12/0/0 in one shell and
  # 9-passed-11-skipped in another with nothing in the output naming the
  # difference, and an acceptance figure carried no evidence of which mode
  # produced it. One site rather than three, so the note cannot drift from the
  # value actually returned.
  printf 'note: browser resolved to %s\n' "$found" >&2
  printf '%s' "$found"
}

#
# The suite already had the right idiom -- the argv checks below poll for a
# file rather than sleeping at it. This applies the same shape to the port.
# /dev/tcp is a bash builtin, so it needs neither curl nor node, and the
# subshell closes the descriptor for us.
# HOW LONG IT WAITED IS PART OF THE ANSWER (issue 0063). The ceiling used to
# be silent: a caller could only say "chrome never opened its debugging port",
# which reads as "chrome is broken" when it usually means "this runner was
# slower than the ceiling". CDP_WAITED carries the measured wait so a refusal
# can say it, and CDP_CEILING makes the ceiling a number rather than a magic
# 200 in a loop. Raised from 10s to 30s: the 10s ceiling was set on a warm
# laptop and a cold GitHub runner starting Chrome for the first time has been
# measured past it.
CDP_CEILING="${CDP_CEILING:-30}"
CDP_WAITED=""
wait_for_cdp() {
  local port="$1" waited=0 step=0.05
  local tries=$(( ${CDP_CEILING%%.*} * 20 ))
  CDP_WAITED="0s"
  while [ "$tries" -gt 0 ]; do
    if (exec 3<>"/dev/tcp/127.0.0.1/$port") 2>/dev/null; then
      CDP_WAITED="$(awk -v w="$waited" 'BEGIN { printf "%.2fs", w * 0.05 }')"
      return 0
    fi
    tries=$((tries - 1))
    waited=$((waited + 1))
    sleep "$step"
  done
  CDP_WAITED="${CDP_CEILING}s (the ceiling)"
  return 1
}

# A debugging port nothing is holding, asked for at the moment it is needed
# (issue 0063).
#
# WHY THIS EXISTS. Every CDP launch in these suites used a HARD-CODED port --
# 9333, 9350, 9360..9363, 9370..9372 -- so anything already holding one made
# Chrome fail to bind, and the only symptom was `wait_for_cdp` timing out and
# the caller blaming Chrome's startup. That is a false diagnosis pointing at
# the wrong subsystem, and a leftover Chrome from an earlier block in the same
# run is enough to cause it. Measured on the 2.12.0 tag run: AT04 failed this
# way on the Linux leg while the same commit passed on its other run, and
# AT05, AT06 and AT07 each launched Chrome successfully seconds later.
#
# A connect that FAILS is the answer we want: nothing is listening there.
# Refusing rather than falling back to a constant is the point -- a fallback
# to a fixed port is the very bug this replaces.
cdp_port() {
  local p tries=50
  while [ "$tries" -gt 0 ]; do
    p=$(( 9000 + RANDOM % 40000 ))
    if ! (exec 3<>"/dev/tcp/127.0.0.1/$p") 2>/dev/null; then
      printf '%s\n' "$p"
      return 0
    fi
    tries=$((tries - 1))
  done
  return 1
}

# The flags every headless launch here carries. --use-mock-keychain is the one
# that matters: without it a launch raises a keychain modal on hv's screen
# (2026-08-29). An ARRAY rather than a string, because a string reaches the
# browser as separate arguments by way of an UNQUOTED expansion -- which is
# IN-SH-CODE-001 at critical severity, and the pre-commit critic refuses it.
# An array is the rule's own sanctioned form and needs no exemption comment.
# Never empty, so bash 3.2's "${arr[@]}"-under-set-u trap does not arise here.
CHROME_SAFE=(--use-mock-keychain --no-first-run --no-default-browser-check)
