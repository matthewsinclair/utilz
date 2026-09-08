#!/usr/bin/env bash
#
# prez acceptance tests -- the ATs behind ST0010's acceptance criteria.
#
# **EDITED BY ST0013 ON 2026-09-08, AND THE EDIT IS RECORDED RATHER THAN
# SILENT.** hv's re-scope split `--theme` into `--theme` (a NAME) and
# `--theme-file` (a PATH), so the five invocations here that passed a PATH to
# `--theme` -- in AT05 and AT08 -- now name the flag that takes one. This is a
# closed thread's frozen record being changed, which deserves saying out loud;
# the alternative was worse. These tests drive a CLI whose contract changed, and
# a test asserting the old contract would be asserting the opposite of correct.
# Nothing else here moved: every other `--theme` in this file passes a NAME and
# is unaffected.
#
# **EVERY CHECK HERE IS BLACK-BOX**: it drives the built binary and reads what
# came out. The unit tests inside src/ prove the modules; these prove the tool.
# A green here is meant to be reproducible by anyone with the repo, which is why
# it shells out rather than linking, and why each check prints what it saw.
#
# THE RULE THESE ARE WRITTEN TO (spec 10, learned four times in one day): a check
# must be able to go red, and only a real defect may turn it red. Two corollaries
# show up repeatedly below. A grep targets a string the artifact can only contain
# if the thing is really there -- a SENTINEL payload or a library-internal symbol
# -- never a token the demo deck legitimately discusses, because a deck
# documenting prez necessarily contains `notes:` and `mermaid: true` as author
# content and a naive grep fails a CORRECT build. And a check that cannot run
# reports itself as unrun rather than passing quietly.
#
# Usage:
#   test/acceptance.sh              run every AT
#   test/acceptance.sh AT03 AT05    run only those
#   test/acceptance.sh --strict     a skipped check fails the run
#
# Exit 0 if every AT that ran passed. Skips are reported and do not pass.
#
# **--strict IS FOR THE MACHINE, AND THE DEFAULT IS FOR A PERSON.** A skipped
# limb is printed, named and counted, which a human cannot miss -- but CI reads
# the exit code, and without --strict that code says "everything that ran passed"
# OR "the important things did not run", which is the same ambiguity one level
# down (vc, 29 Aug 2026). Exiting non-zero by default would break the
# interactive run on any machine without Chrome, so the automation path opts in.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRATE="$(dirname "$HERE")"
REPO="$(cd "$CRATE" && git rev-parse --show-toplevel)"
# The DEFAULT in-crate target/, not a redirect. Upstream redirected it out of
# the tree because that checkout lives in a cloud-synced folder that must not
# carry build output. Utilz is a plain local checkout, so
# the default is correct here and .gitignore's opt/*/crate/target/ is the whole
# fence. CARGO_TARGET_DIR still wins if a caller sets it, which is what lets CI
# or a cold-build run point somewhere else without editing this file.
TARGET="${CARGO_TARGET_DIR:-$CRATE/target}"
BIN="$TARGET/release/prez"
DEMO="$CRATE/examples/demo.md"
SENTINEL="PREZ-SENTINEL-7F3A"

# ONE size reader, GNU FIRST, and the order is the whole point.
#
# `stat -f %z` is BSD syntax. On Linux `-f` means "display filesystem status",
# so it does not fail -- it SUCCEEDS and prints something else entirely, which
# is why an `|| stat -c %s` fallback never fires there. A command that succeeds
# with the wrong answer defeats every `||` guard written against it.
#
# Found by CI on 2026-08-29, the first time this suite ever ran on Linux: three
# blocks failed (AT01, AT03, AT07) printing `binary is   File: "..."`, which is
# stat's filesystem output arriving where a byte count was expected. AT01 had
# the fallback and still failed; AT03 and AT07 had no fallback at all. Both
# facts point the same way -- the guard was on the wrong end.
#
# Trying GNU first inverts it: `stat -c` is not valid BSD, so it fails on macOS
# and the fallback runs. Neither platform has a form that succeeds wrongly.
file_size() {
  stat -c %s "$1" 2>/dev/null || stat -f %z "$1" 2>/dev/null || echo 0
}

# WAIT FOR THE PORT TO ANSWER, NEVER FOR A DURATION.
#
# Both CDP launches used `sleep 2` and then connected. That measures two
# seconds, not readiness -- so it passes on a warm developer laptop where
# Chrome opens its port in well under a second, and races on anything slower.
#
# Measured on CI 2026-08-29, the first run off this machine: AT04 died with
# `TypeError: fetch failed / ECONNREFUSED 127.0.0.1:9333` on BOTH matrix legs,
# with 128 unit tests green and every other block passing. Nothing was wrong
# with the runtime or the probe; the browser had simply not finished starting.
#
# The suite already had the right idiom -- the argv checks below poll for a
# file rather than sleeping at it. This applies the same shape to the port.
# /dev/tcp is a bash builtin, so it needs neither curl nor node, and the
# subshell closes the descriptor for us.
wait_for_cdp() {
  local port="$1" tries=200          # 200 x 0.05s = a 10s ceiling
  while [ "$tries" -gt 0 ]; do
    if (exec 3<>"/dev/tcp/127.0.0.1/$port") 2>/dev/null; then return 0; fi
    tries=$((tries - 1))
    sleep 0.05
  done
  return 1
}

WORK="$(mktemp -d "${TMPDIR:-/tmp}/prez-at.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

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

pages_in() { python3 -c "
import re,sys
d=open(sys.argv[1],'rb').read()
print(len(re.findall(rb'/Type\s*/Page[^s]', d)))
" "$1"; }

paper_of() { python3 -c "
import re,sys
d=open(sys.argv[1],'rb').read()
for m in set(re.findall(rb'/MediaBox\s*\[([^\]]*)\]', d)):
  p=[float(v) for v in m.split()]
  print('%.0fx%.0f' % (round((p[2]-p[0])/72*25.4), round((p[3]-p[1])/72*25.4)))
  break
" "$1"; }

# The built-in roster, asked of the BINARY rather than listed here -- a theme
# added to theme.rs is covered the moment it is registered, not when someone
# remembers to update the suite. Two ATs need it, so it has one home.
builtins_list() {
  local err="$WORK/builtins.err"
  "$BIN" build "$DEMO" --theme=__nope__ -o /dev/null 2>"$err" >/dev/null
  sed -n 's/.*built in: //p' "$err" | tr -d ','
}

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

# EVERY headless launch goes through these. --use-mock-keychain because a fresh
# profile otherwise makes Chrome ask macOS for a Safe Storage keychain entry,
# which opens an INTERACTIVE MODAL -- at the human, mid-run, in a suite that is
# not interactive. It blocks rather than fails, so --strict cannot tell "hung on
# a dialog" from "still working", and it only fires on a machine with a keychain
# to prompt about: invisible on the Linux box, waiting on the user's Mac. hv
# screenshotted one on 29 Aug and asked whether it was us. It was.
#
# ONLY the flag. NOT --user-data-dir, and the reason is a mistake worth leaving
# written down.
#
# I added --user-data-dir to the two --dump-dom sites believing they ran against
# the user's DEFAULT profile, since they passed no profile flag. THAT WAS FALSE.
# Headless Chrome with no --user-data-dir creates its own scoped throwaway --
# ~/Library/Application Support/Google/Chrome-headless/scoped_dirXXXX -- fresh
# per launch and discarded after. Chrome-headless, not Chrome. There was nothing
# to contain.
#
# And the containment I added for that non-problem HUNG THE SUITE. An explicit
# --user-data-dir with --dump-dom dumps the DOM correctly and then never exits.
# The two sites using $(...) wait on stdout closing, so they hang forever; the
# two using & and a kill never noticed. Isolated by _tools-vc across five runs,
# and attribution settled by swapping --use-mock-keychain for
# --password-store=basic and watching it hang identically: the keychain flag is
# innocent, --user-data-dir is the cause.
#
# So: the flag goes on all four launches, because that is where the modal was.
# The profile flag goes only where it already was, at the two sites that
# background-and-kill. A fix aimed at a problem nobody verified cost four
# ten-minute hangs and two orphaned browsers on hv's machine.
#
# --no-first-run --no-default-browser-check are the SECOND interactive modal,
# found the same way: hv screenshotted Chrome's "Welcome to Google Chrome" panel
# -- make Chrome the default browser, send usage statistics to Google -- popping
# up on every run of this suite. It is the first-run experience, and every
# launch here triggers it because every launch gets a profile Chrome has never
# seen before. Same class of bug as the keychain prompt and the same fix: say no
# to it up front rather than let a non-interactive suite ask a human a question.
# `Courses/bin/render-cover` has carried both flags all along; this suite never
# picked them up.
# AN ARRAY, NOT A STRING. It held one flag until hv added --no-first-run and
# --no-default-browser-check on 7 Sep, and a multi-flag string only reaches the
# browser as separate arguments by way of an UNQUOTED expansion -- which is
# IN-SH-CODE-001 at critical severity, and the pre-commit critic refuses it.
# An array is the rule's own sanctioned form and needs no exemption comment.
# Never empty, so bash 3.2's "${arr[@]}"-under-set-u trap does not arise here.
CHROME_SAFE=(--use-mock-keychain --no-first-run --no-default-browser-check)

# ---------------------------------------------------------------- AT01 -- AC11

if want AT01; then
  start AT01 "build hygiene: the build lands in-crate and leaves no litter in git"
  # REWRITTEN ON THE HOIST, and the AC underneath it changed rather than the
  # test drifting. Upstream this proved their AC01 -- that `bin/devbin build`
  # redirected CARGO_TARGET_DIR out of a Dropbox-synced tree, and that the
  # redirect held COLD as well as warm. That AC stays behind: Utilz is a plain
  # local checkout, there is no redirect to hold, and a test asserting one
  # would be measuring a mechanism this repo deliberately does not have.
  #
  # The INTENT survives -- a build must not leave litter someone has to notice
  # -- so the same step now proves the Utilz mechanism: the default in-crate
  # target/ is where the binary goes, and .gitignore fences it. Kept as a test
  # rather than dropped, because "we do not need that check here" is how a
  # hoist quietly loses one.
  if cargo build --release --manifest-path "$CRATE/Cargo.toml" >"$WORK/at01.log" 2>&1; then
    ok "release build succeeded"
  else
    bad "release build failed"; sed 's/^/        /' "$WORK/at01.log" | tail -5
  fi

  [ -x "$CRATE/target/release/prez" ] \
    && ok "binary landed in the in-crate target dir" \
    || bad "binary is not at $CRATE/target/release/prez"

  # THE FENCE IS THE POINT. A few hundred MB of target/ showing up as
  # untracked is the failure this replaces the redirect with, so assert git
  # cannot see it rather than asserting the directory is absent -- it is
  # supposed to be present, just invisible.
  untracked="$(cd "$REPO" && git status --porcelain --untracked-files=all -- opt/prez/ | grep -c 'target/' || true)"
  check "build litter visible to git under opt/prez/" "$untracked" "0"

  size=$(file_size "$CRATE/target/release/prez")
  if [ "$size" -gt 0 ] && [ "$size" -le 8388608 ]; then ok "binary $((size / 1048576)) MB <= 8 MB ceiling"
  else bad "binary is $size bytes against an 8 MB ceiling"; fi
  finish
fi

cargo build --release --manifest-path "$CRATE/Cargo.toml" >/dev/null 2>&1

# ---------------------------------------------------------------- AT02 -- AC01

if want AT02; then
  start AT02 "dependency posture: comrak and std, nothing else"
  declared="$(awk '/^\[dependencies\]/{f=1;next} /^\[/{f=0} f && /^[a-zA-Z]/ {print $1}' "$CRATE/Cargo.toml" | sort | tr '\n' ' ')"
  check "declared dependencies" "$declared" "comrak "

  # The other half of AC01: the named jobs are HAND-ROLLED, which shows up as
  # every `use` resolving to std, this crate, or comrak. A new crate would have
  # to appear here even if someone forgot to look at Cargo.toml.
  foreign="$(grep -rhoE '^\s*use [a-zA-Z_][a-zA-Z0-9_]*' "$CRATE/src" \
    | awk '{print $2}' | sort -u | grep -vE '^(std|crate|super|self|comrak)$' || true)"
  [ -z "$foreign" ] && ok "every use resolves to std, crate or comrak" \
    || bad "foreign crate in a use statement: $foreign"

  for own in base64 args frontmatter split inline; do
    [ -f "$CRATE/src/$own.rs" ] && ok "$own is hand-rolled" || bad "$own.rs is missing"
  done
  finish
fi

# ------------------------------------------------------------ AT03 -- AC02/03

if want AT03; then
  start AT03 "self-contained artifact, and notes that reach no artifact"
  art="$WORK/demo.html"
  "$BIN" build "$DEMO" -o "$art" >/dev/null 2>"$WORK/at03.err"

  size=$(file_size "$art")
  if [ "$size" -le 102400 ]; then ok "artifact $size bytes <= 100 KB"; else bad "artifact is $size bytes"; fi

  # THE CAPTURE IS ASSERTED, NOT MERELY TAKEN. This redirect existed to keep the
  # terminal tidy and nothing read the file, so a build that SUCCEEDED NOISILY
  # was indistinguishable from a silent one. prez warned on every run of this
  # suite that demo.md applied a class no theme declares (issue 0012), the
  # harness wrote it into at03.err each time, and the suite reported green --
  # hv found by eye what this file had been recording all along.
  # An exit code is not a report: assert the stream, not just the status.
  check "the build says nothing on stderr" "$(wc -c < "$WORK/at03.err" | tr -d ' ')" "0"

  # AC03. The SENTINEL, never the `notes:` token: the demo shows a fenced notes
  # example on purpose, so a token grep would fail a correct build.
  absent "AC03 sentinel is nowhere in the HTML" "$SENTINEL" "$art"
  present "the fenced notes example survived as author content" "only the speaker sees this" "$art"

  ext=$(grep -coE '(src|href)="https?://' "$art" || true)
  check "prez-emitted external references" "${ext:-0}" "0"
  absent "mermaid library" "mermaidAPI" "$art"

  # Images: inlined when present, and never silently dropped when not.
  printf 'GIF89a\x01\x00' > "$WORK/dot.gif"
  printf -- '# Pictures\n\n![a](dot.gif)\n\n![b](missing.gif)\n' > "$WORK/img.md"
  "$BIN" build "$WORK/img.md" -o "$WORK/img.html" >/dev/null 2>"$WORK/img.err"
  present "local image inlined as a data: URI" 'src="data:image/gif;base64,' "$WORK/img.html"
  present "missing image left as a visible broken ref" 'src="missing.gif"' "$WORK/img.html"
  present "missing image warned on stderr with its path" "missing.gif" "$WORK/img.err"

  # Spec 10.3 -- the notes-leak cases, through the REAL pipeline, because the
  # defect was an interaction between the splitter and the note lifter and no
  # per-module test could see it.
  printf -- '# Slide One\n\n<!-- notes: PRIVATE-HEAD\n---\nPRIVATE-TAIL -->\n\nVisible text\n' > "$WORK/leak.md"
  "$BIN" build "$WORK/leak.md" -o "$WORK/leak.html" >/dev/null 2>&1
  absent "a note spanning a slide break leaks no head" "PRIVATE-HEAD" "$WORK/leak.html"
  absent "a note spanning a slide break leaks no tail" "PRIVATE-TAIL" "$WORK/leak.html"
  present "the surrounding content survives" "Visible text" "$WORK/leak.html"
  check "the note's --- did not split the deck" "$(grep -c 'id="gp-' "$WORK/leak.html")" "1"

  printf -- '# One\n\n<!-- notes: NEVER-CLOSED\n\n---\n\n# Two\n' > "$WORK/unterm.md"
  "$BIN" build "$WORK/unterm.md" -o "$WORK/unterm.html" >/dev/null 2>"$WORK/unterm.err"
  absent "an unterminated note leaks nothing" "NEVER-CLOSED" "$WORK/unterm.html"
  present "an unterminated note is warned about" "unterminated" "$WORK/unterm.err"
  present "the warning says the content was dropped" "dropped" "$WORK/unterm.err"
  finish
fi

# ---------------------------------------------------------------- AT04 -- AC04

if want AT04; then
  start AT04 "base runtime in a real browser: keys, counter, overview, hash, fullscreen"
  if ! BROWSER="$(chrome)"; then skip "no Chrome or Chromium installed"
  elif ! command -v node >/dev/null 2>&1; then skip "node is not installed (the CDP probe needs it)"
  else
    art="$WORK/runtime.html"
    "$BIN" build "$DEMO" -o "$art" >/dev/null 2>&1
    "$BROWSER" --headless=new "${CHROME_SAFE[@]}" --remote-debugging-port=9333 --window-size=1280,800 \
      --user-data-dir="$WORK/chrome" "file://$art" >"$WORK/chrome.log" 2>&1 &
    CHROME_PID=$!
    wait_for_cdp 9333 || bad "chrome never opened its debugging port on 9333"
    if node "$HERE/at04-runtime-probe.mjs" 9333; then ok "every runtime check passed"; else bad "the runtime probe reported failures"; fi
    kill "$CHROME_PID" 2>/dev/null; wait "$CHROME_PID" 2>/dev/null
    finish
  fi
fi

# ---------------------------------------------------------------- AT05 -- AC05

if want AT05; then
  start AT05 "pdf: one slide per page, and a refusal that names what it probed"
  if ! chrome >/dev/null; then skip "no Chrome or Chromium installed"
  else
    "$BIN" pdf "$DEMO" -o "$WORK/demo.pdf" >/dev/null 2>&1
    check "pages" "$(pages_in "$WORK/demo.pdf")" "6"
    check "page size (mm)" "$(paper_of "$WORK/demo.pdf")" "254x143"

    "$BIN" pdf "$DEMO" --paper 210x297 -o "$WORK/a4.pdf" >/dev/null 2>&1
    check "--paper override" "$(paper_of "$WORK/a4.pdf")" "210x297"
    # The equals form, which no AT exercised until vc found it refused outright.
    "$BIN" pdf "$DEMO" --paper=210x297 -o "$WORK/a4eq.pdf" >/dev/null 2>&1
    check "--paper=WxH equals form" "$(paper_of "$WORK/a4eq.pdf")" "210x297"

    # A theme may choose the page SIZE; it may not quietly drop the page BREAK.
    printf '@media print { @page { size: 400mm 200mm } }\n' > "$WORK/wide.css"
    "$BIN" pdf "$DEMO" --theme-file "$WORK/wide.css" -o "$WORK/wide.pdf" >/dev/null 2>&1
    check "a theme may set page size" "$(paper_of "$WORK/wide.pdf")" "400x200"
    check "and still gets one page per slide" "$(pages_in "$WORK/wide.pdf")" "6"

    # And when a theme defeats the break anyway with !important -- which order
    # cannot stop -- the page count control catches it. This is the check that
    # exists because the stronger claim was falsified.
    printf '@media print { section { break-after: auto !important; height: auto !important } }\n' > "$WORK/defeat.css"
    "$BIN" pdf "$DEMO" --theme-file "$WORK/defeat.css" -o "$WORK/defeat.pdf" 2>"$WORK/defeat.err" >/dev/null
    present "a collapsed PDF is reported, not shipped silently" "defeating one-slide-per-page" "$WORK/defeat.err"

    "$BIN" pdf "$DEMO" --browser /nonexistent -o "$WORK/never.pdf" >/dev/null 2>"$WORK/refuse.err"
    check "--browser /nonexistent exit code" "$?" "2"
    present "the refusal names the path given" "/nonexistent" "$WORK/refuse.err"
    [ -f "$WORK/never.pdf" ] && bad "a refused pdf left a partial file" || ok "a refused pdf left no file"
    finish
  fi
fi

# ---------------------------------------------------------------- AT06 -- AC06

if want AT06; then
  start AT06 "present: launches de-chromed, then prez gets out of the way"
  # A stub browser, so the check is about what prez DOES rather than about
  # whether a window appeared. It also has to be waited for: prez exits the
  # moment it spawns, so reading the record too early reports "invoked nothing"
  # (vc caught exactly this in its own instrument, 28 Aug).
  # The stub CHATTERS, on both streams, the way a real browser does. Chrome
  # greets an already-running instance with "Opening in existing browser
  # session." and libGL/gpu lines go to stderr -- and because prez has exited by
  # then, all of it lands under the user's next shell prompt looking like output
  # from whatever they type next. hv saw exactly that.
  cat > "$WORK/fake-browser" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$(dirname "$0")/argv.txt"
echo "Opening in existing browser session."
echo "[12345:ERROR:gpu_init.cc(42)] libGL noise" >&2
STUB
  chmod +x "$WORK/fake-browser"

  "$BIN" present "$DEMO" --browser "$WORK/fake-browser" >"$WORK/present.log" 2>&1
  check "prez exit code" "$?" "0"

  # WAIT FOR THE STUB TO HAVE RUN before reading anything it might have
  # written. The cleanliness checks below were originally above this loop and
  # could not go red: the browser had not chattered yet, so "the log does not
  # contain the chatter" was true because nothing had happened. Caught by the
  # red-first run, where the two message checks failed and these two did not.
  for _ in 1 2 3 4 5 6 7 8 9 10; do [ -f "$WORK/argv.txt" ] && break; sleep 0.2; done
  # argv.txt is written BEFORE the stub's echoes, so its existence is not proof
  # they have landed. One more beat, then assert.
  sleep 0.3

  # THE TERMINAL STAYS CLEAN. Both streams, because the launched process
  # inherits both and prez is not around to catch either -- and because prez
  # has exited by then, anything they write lands under the user's next shell
  # prompt looking like output from whatever they type next.
  absent "the browser's stdout does not reach the terminal" "Opening in existing" "$WORK/present.log"
  absent "nor its stderr" "libGL noise" "$WORK/present.log"

  # And what prez DOES say is about the deck, not about a scratch file. The
  # line used to name a temp path -- forty characters of machine detail about a
  # file the reader did not ask for and cannot find again.
  present "names the deck" "presenting demo.md" "$WORK/present.log"
  present "and how many slides came out" "slides)" "$WORK/present.log"
  absent "and not the scratch path" "/prez-" "$WORK/present.log"

  if [ -f "$WORK/argv.txt" ]; then
    present "launched with --app on a file:// URL" "--app=file://" "$WORK/argv.txt"
    present "launched in its own window" "--new-window" "$WORK/argv.txt"

    # AC19. THE WINDOW HAS A SHAPE NOW, and the default is the deck's own 16:9
    # rather than whatever the browser last remembered -- hv got a portrait
    # window for a 16:9 deck, which is not a bad default but the absence of one.
    present "launched at the deck's aspect" "--window-size=1280,720" "$WORK/argv.txt"

    # AND THE INERT FLAG IS GONE. Asserted as an ABSENCE, which is the half
    # that matters: a build keeping --start-fullscreen beside a working
    # --window-size would pass every check above, and the flag would live on
    # behind a green. It was passed on every launch for as long as this test
    # existed, never took effect on macOS, and said nothing -- this check
    # replaces the one that asserted its presence.
    absent "no flag that Chrome silently ignores" "--start-fullscreen" "$WORK/argv.txt"

    # --window is honoured, measured rather than assumed.
    rm -f "$WORK/argv.txt"
    "$BIN" present "$DEMO" --browser "$WORK/fake-browser" --window 1920x1080 >/dev/null 2>&1
    for _ in 1 2 3 4 5 6 7 8 9 10; do [ -f "$WORK/argv.txt" ] && break; sleep 0.2; done
    present "--window overrides the default" "--window-size=1920,1080" "$WORK/argv.txt"
  else
    bad "the browser was never invoked"
  fi
  # The anti-requirement, checked rather than asserted: nothing of prez is
  # left running once it has handed over.
  check "prez processes still alive" "$(pgrep -f 'release/prez' | wc -l | tr -d ' ')" "0"
  finish
fi

# ---------------------------------------------------------------- AT07 -- AC07

if want AT07; then
  start AT07 "mermaid is opt-in, and opting out costs zero bytes"
  # The diagram sits on slide TWO deliberately: a diagram on the current slide
  # would have a box either way, and the defect this test now exists to catch
  # only happens to a slide that is hidden when mermaid measures it.
  printf -- '---\ntitle: M\nmermaid: true\n---\n\n# Cover\n\n---\n\n# Diagram\n\n```mermaid\ngraph TD;\n  A-->B;\n```\n' > "$WORK/m.md"
  "$BIN" build "$WORK/m.md" -o "$WORK/m.html" >/dev/null 2>&1
  printf -- '---\ntitle: M\n---\n\n# Cover\n\n---\n\n# Diagram\n\n```mermaid\ngraph TD;\n  A-->B;\n```\n' > "$WORK/nom.md"
  "$BIN" build "$WORK/nom.md" -o "$WORK/nom.html" >/dev/null 2>&1

  # `mermaidAPI` is a library-internal symbol: a deck can discuss mermaid, but
  # it cannot contain that unless the library is really embedded.
  present "opted-in artifact carries the library" "mermaidAPI" "$WORK/m.html"
  absent "opted-out artifact carries no library" "mermaidAPI" "$WORK/nom.html"

  on=$(file_size "$WORK/m.html"); off=$(file_size "$WORK/nom.html")
  if [ "$on" -gt 3000000 ]; then ok "opted-in artifact is $((on / 1048576)) MB"; else bad "opted-in artifact is only $on bytes"; fi
  if [ "$off" -lt 102400 ]; then ok "opted-out artifact is $off bytes"; else bad "opted-out artifact is $off bytes"; fi

  # MEASURE THE DIAGRAM, DO NOT MERELY FIND IT (spec 10.7). This check used to
  # count <svg> in the DOM, which passed for a whole day while every diagram in
  # hv's deck was a 16px stub nobody could see -- the svg was THERE, it just had
  # no size. Both nodes shipped that same check. Two traps in the measurement
  # itself: navigate to the slide first, because a diagram on a hidden slide
  # legitimately measures 0x0 and would report a defect that is not there; and
  # measure the rendered BOX, because viewBox is what mermaid computed rather
  # than what a viewer sees.
  if BROWSER="$(chrome)"; then
    cp "$WORK/m.html" "$WORK/m-probe.html"
    cat >> "$WORK/m-probe.html" <<'PROBE'
<div id="probe">pending</div>
<script>
(async function () {
  var wait = function (ms) { return new Promise(function (r) { setTimeout(r, ms); }); };
  await wait(1200);
  var svg = document.querySelector('.gp-slide svg');
  if (!svg) { document.getElementById('probe').textContent = 'no-svg'; return; }
  var slide = svg.closest('.gp-slide');
  var slides = Array.prototype.slice.call(document.querySelectorAll('.gp-slide'));
  location.hash = '#' + (slides.indexOf(slide) + 1);
  await wait(400);
  var box = svg.getBoundingClientRect();
  document.getElementById('probe').textContent =
    Math.round(box.width) + 'x' + Math.round(box.height) + ' on-slide-' + (slides.indexOf(slide) + 1);
})();
</script>
PROBE
    measured=$("$BROWSER" --headless "${CHROME_SAFE[@]}" \
      --disable-gpu --window-size=1400,900 --virtual-time-budget=9000 \
      --dump-dom "file://$WORK/m-probe.html" 2>/dev/null \
      | grep -oE '<div id="probe">[^<]*' | sed 's/.*>//')
    # BOTH dimensions over 40, not spec 10.7's literal 100x40. The defect
    # signature is a 16x16 stub, and an orientation-agnostic floor separates
    # that from a real diagram without failing a correct one: `graph TD` is
    # legitimately tall and narrow and measured 85x174 here on the first run,
    # which would have failed a 100-wide threshold. A control going red for the
    # wrong reason is the thing this whole file is written against, so it would
    # have been an odd place to accept one. Raised with vc.
    w=${measured%%x*}; rest=${measured#*x}; h=${rest%% *}
    if [ "${w:-0}" -ge 40 ] && [ "${h:-0}" -ge 40 ]; then
      ok "the diagram renders offline at a visible size ($measured)"
    else
      bad "the diagram is present but not visible: measured $measured, wanted both sides over 40"
    fi
  else
    unchecked "offline diagram render: no Chrome or Chromium installed"
  fi
  finish
fi

# ---------------------------------------------------------------- AT08 -- AC08

if want AT08; then
  start AT08 "themes are orthogonal, offline, and the default carries no brand"
  BROWSER="$(chrome || true)"
  deck_before=$(shasum "$DEMO" | cut -d' ' -f1)
  printf 'body{background:#0a0a0a;color:#00ff00}\n' > "$WORK/good.css"
  "$BIN" build "$DEMO" --theme-file "$WORK/good.css" -o "$WORK/themed.html" >/dev/null 2>&1
  present "a single .css restyles the deck" "background:#0a0a0a" "$WORK/themed.html"

  # A NAME, not just a path -- and both flag forms, byte-identical. The whole
  # defect vc found was that nobody exercised the equals form, so this asserts
  # the two agree rather than that each runs.
  "$BIN" build "$DEMO" --theme simple -o "$WORK/named-space.html" >/dev/null 2>&1
  "$BIN" build "$DEMO" --theme=simple -o "$WORK/named-equals.html" >/dev/null 2>&1
  if cmp -s "$WORK/named-space.html" "$WORK/named-equals.html"; then
    ok "--theme NAME and --theme=NAME produce identical output"
  else
    bad "--theme NAME and --theme=NAME disagree"
  fi
  "$BIN" build "$DEMO" --theme=nosuchtheme -o "$WORK/never2.html" 2>"$WORK/name.err" >/dev/null
  check "an unknown theme NAME exits" "$?" "2"
  present "the refusal lists the built-ins" "built in:" "$WORK/name.err"
  present "the refusal says where it looked" "PREZ_THEME_PATH" "$WORK/name.err"
  [ -f "$WORK/never2.html" ] && bad "an unknown theme left a partial artifact" || ok "an unknown theme left no artifact"

  # A theme found by NAME on the search path is how a branded theme reaches
  # prez without prez carrying the brand.
  mkdir -p "$WORK/themes/housestyle"
  printf 'body{background:#123456}\n.title{}\n' > "$WORK/themes/housestyle/theme.css"
  PREZ_THEME_PATH="$WORK/themes" "$BIN" build "$DEMO" --theme=housestyle \
    -o "$WORK/searched.html" >/dev/null 2>&1
  present "a name resolves on PREZ_THEME_PATH" "background:#123456" "$WORK/searched.html"
  # Checksummed around every build above, not asked of git. Asking git conflated
  # "the build did not touch it" with "nobody is editing it", so the check went
  # red the moment there was an uncommitted edit in the tree -- a control failing
  # for a reason that has nothing to do with the tool it is watching.
  check "without touching the markdown" "$(shasum "$DEMO" | cut -d' ' -f1)" "$deck_before"

  printf 'body{color:red}\n@import url(https://fonts.example/x.css);\n' > "$WORK/bad.css"
  "$BIN" build "$DEMO" --theme-file "$WORK/bad.css" -o "$WORK/never.html" 2>"$WORK/theme.err" >/dev/null
  check "an external URL in a theme exits" "$?" "2"
  present "the refusal names the file" "bad.css" "$WORK/theme.err"
  present "the refusal names the line" "line 2" "$WORK/theme.err"
  present "the refusal names the offender" "fonts.example" "$WORK/theme.err"
  [ -f "$WORK/never.html" ] && bad "a refused build left a partial artifact" || ok "a refused build left no artifact"

  # An attribution URL in a comment is documentation, not a reference. Without
  # this the rule would teach theme authors to delete their attributions.
  printf '/* adapted from https://example.com/t, MIT */\nbody{color:red}\n' > "$WORK/attrib.css"
  "$BIN" build "$DEMO" --theme-file "$WORK/attrib.css" -o "$WORK/attrib.html" >/dev/null 2>&1
  check "a URL inside a comment does not fail a build" "$?" "0"

  # EVERY BUILT-IN, not just the default. A vocabulary one theme honours is not
  # a vocabulary, and brand-freeness that holds for the theme we happened to
  # check is not a property of the binary. The list comes from the refusal
  # itself, so a new built-in is covered the moment it is registered rather than
  # when someone remembers to add it here.
  builtins=$(builtins_list)
  [ -n "$builtins" ] && ok "built-ins enumerated: $builtins" || bad "could not enumerate the built-ins"
  for name in $builtins; do
    "$BIN" build "$DEMO" --theme="$name" -o "$WORK/b-$name.html" >/dev/null 2>&1 \
      && ok "$name builds the demo" || bad "$name failed to build the demo"

    # Brand-freeness, asserted structurally: a denylist of house names only
    # catches the names on the list.
    custom=$(grep -oE -- '--[a-z][a-z0-9-]*\s*:' "$WORK/b-$name.html" | grep -vc -- '--gp-' || true)
    check "$name: custom properties outside the gp- namespace" "${custom:-0}" "0"

    missing=""
    for class in title section quote full center small; do
      grep -q -- ".gp-slide.$class" "$WORK/b-$name.html" || missing="$missing $class"
    done
    [ -z "$missing" ] && ok "$name declares the standard classes" \
      || bad "$name does not declare:$missing"

    # An external reference in a built-in would take the offline guarantee with
    # it, and a built-in is the one theme a user cannot audit before choosing.
    ext=$(grep -coE '(src|href|url\()\s*["'"'"']?https?://' "$WORK/b-$name.html" || true)
    check "$name: external references" "${ext:-0}" "0"

    # CAN ANYONE READ IT. Every other check above is satisfied by a theme that
    # renders white on white -- and two of these seven shipped unreadable slides
    # past them: steampunk's heading on a dark background measured 1.1:1, and
    # 8bit's headings 2.4:1 in light mode. Both look plausible in a screenshot.
    if [ -z "${BROWSER:-}" ]; then
      unchecked "$name: legibility unmeasured, no Chrome or Chromium installed"
    else
      cat "$WORK/b-$name.html" "$HERE/theme-legibility-probe.html" > "$WORK/lp-$name.html"
      measured=$("$BROWSER" --headless "${CHROME_SAFE[@]}" \
        --disable-gpu --window-size=1400,900 \
        --virtual-time-budget=9000 --dump-dom "file://$WORK/lp-$name.html" 2>/dev/null \
        | grep -oE '<div id="probe">[^<]*' | sed 's/.*>//')
      worst=$(printf '%s' "$measured" | tr ' ' '\n' | cut -d: -f2 | cut -d/ -f1 | sort -n | head -1)
      # 4.5:1 is WCAG AA for body text. Deck type is larger than body text, so
      # this is a floor rather than a target.
      if [ -n "$worst" ] && awk "BEGIN{exit !($worst >= 4.5)}"; then
        ok "$name: worst text contrast ${worst}:1"
      else
        bad "$name: unreadable text at ${worst:-?}:1 -- $measured"
      fi
      overflowing=$(printf '%s' "$measured" | grep -c OVERFLOW || true)
      check "$name: slides overflowing their box" "${overflowing:-0}" "0"

      # A slide the probe cannot speak for must be COUNTED, not passed over.
      # It used to hit a bare `continue`: no entry, no marker, nothing counted,
      # so a full-bleed image slide or a raw-HTML composition was invisible and
      # the theme still reported a clean measurement. That is the same silent
      # skip `unchecked` and --strict exist to kill, one level down.
      #
      # Counts only slides with NO measurable text at all -- the bare
      # `N:UNMEASURED` form. `N:16.5/DIAGRAM-UNMEASURED` means the slide WAS
      # measured and also carries a diagram this probe deliberately does not
      # speak for; failing on that would fail every theme for owning a mermaid
      # slide, which measures the deck rather than the theme.
      unmeasured=$(printf '%s' "$measured" | tr ' ' '\n' | grep -c ':UNMEASURED' || true)
      check "$name: slides with no measurable text" "${unmeasured:-0}" "0"
    fi
  done
  finish
fi

# ---------------------------------------------------------------- AT12 -- AC10

if want AT12; then
  start AT12 "determinism: one artifact renders the same on every machine"
  if ! BROWSER="$(chrome)"; then skip "no Chrome or Chromium installed"
  elif ! command -v node >/dev/null 2>&1; then skip "node is not installed (the CDP probe needs it)"
  else
    # WHICH DECK, and it is the whole subtlety of this AT (vc, who found it by
    # running the probe rather than by reasoning about it).
    #
    # There are TWO independent sources of viewer-preference branching: a
    # theme's @media block, and mermaid choosing its palette from matchMedia.
    # The second is only IN the artifact when the deck opts into mermaid -- and
    # $DEMO does NOT, because its `mermaid: true` sits inside a fenced yaml
    # block as documentation. So AT12 on $DEMO alone reports every theme clean
    # while the mermaid defect is still there.
    #
    # A check that goes green on the very defect it was written for is the
    # sharpest form of the tell in spec section 10. So the sweep runs on
    # test_pres.md, which opts in, and $DEMO appears once as a CONTROL: the
    # non-mermaid path must be clean too, and if it ever differs from the
    # mermaid path the difference is the diagram.
    mermaid_deck="$CRATE/examples/test_pres.md"
    at12_fail=0

    at12_run() {
      local deck="$1" theme="$2" label="$3" art port
      art="$WORK/at12-$theme-$label.html"
      port=9350
      "$BIN" build "$deck" --theme="$theme" -o "$art" >/dev/null 2>&1 || {
        bad "$label/$theme: build failed"; at12_fail=1; return; }
      # ONE profile for the whole sweep, not one per theme. This loop runs eight
      # times (seven themes on the mermaid deck, plus the no-mermaid control),
      # and it used to mint a fresh --user-data-dir each time: eight profile
      # creations, which is eight keychain prompts and eight cold starts. The
      # profile is what is expensive and what triggers the modal, not the
      # launch, so reusing it removes the amplifier. Each instance is still
      # killed before the next starts, so the profile is never contended.
      "$BROWSER" --headless=new "${CHROME_SAFE[@]}" --remote-debugging-port=$port \
        --window-size=1280,800 --user-data-dir="$WORK/chrome-at12" "file://$art" \
        >"$WORK/chrome-at12.log" 2>&1 &
      local pid=$!
      wait_for_cdp "$port" || bad "chrome never opened its debugging port on $port"
      if node "$HERE/at12-determinism-probe.mjs" "$port" "$theme/$label" >"$WORK/at12-$theme-$label.out" 2>&1; then
        ok "$theme ($label): deterministic"
      else
        bad "$theme ($label): $(grep -c FAIL "$WORK/at12-$theme-$label.out" || true) branch(es) on the viewer's machine"
        sed -n 's/^  FAIL /         /p' "$WORK/at12-$theme-$label.out" | head -6
        at12_fail=1
      fi
      kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
    }

    for theme in $(builtins_list); do
      at12_run "$mermaid_deck" "$theme" "mermaid"
    done
    # The control. Same theme, a deck with no diagram in it.
    at12_run "$DEMO" "blueprint" "no-mermaid"

    finish
  fi
fi

# ---------------------------------------------------------------- AT09 -- AC09

if want AT09; then
  start AT09 "the source is standalone, and both code gates are run"
  # ANYWHERE IN src, COMMENTS INCLUDED (hv 2026-08-29: Utilz carries zero
  # knowledge of the estate this crate came from). The earlier form required
  # a leading quote, so it saw string literals only -- and a real client path
  # sat in a deck.rs comment, green, for as long as this check existed. A
  # comment creates no coupling, which is why AC09 once allowed it; it does
  # leak, which is why it is refused now.
  paths=$(grep -rlE '(/Users/|Dropbox|[Gg]eodica)' "$CRATE/src" 2>/dev/null | wc -l | tr -d ' ')
  check "estate paths or names anywhere in src" "$paths" "0"
  imports=$(grep -rhE '^\s*use .*(geodica|gtools)' "$CRATE/src" 2>/dev/null | wc -l | tr -d ' ')
  check "estate imports" "$imports" "0"

  tabs=$(grep -rl "$(printf '\t')" "$CRATE/src" 2>/dev/null | wc -l | tr -d ' ')
  check "files containing tabs" "$tabs" "0"
  # A line whose predecessor ends in a backslash is string CONTENT, not code:
  # Rust's line continuation strips its leading whitespace, so the alignment
  # under an opening quote is not indentation. Without this the check flagged
  # seven correct lines, which is a control going red for the wrong reason --
  # the thing every other check here is written to avoid.
  odd=$(awk 'prev ~ /\\$/ { prev = $0; next }
             match($0, /^ +/) && RLENGTH % 2 == 1 { n++ }
             { prev = $0 }
             END { print n+0 }' "$CRATE"/src/*.rs)
  check "lines at an odd indent" "$odd" "0"

  # BOTH gates, named separately, because the per-file critic arms 1 of its 7
  # rust rules and declines the three clippy-backed ones out loud. A clean
  # critic alone is a control that cannot go red on them.
  # PROBE THE TOOL, NEVER THE OUTPUT. Both gates below used to conflate "the
  # tool is not here" with an answer about the code, and they did it in
  # OPPOSITE directions -- which is why each needed its own fix rather than one
  # shared guard.
  #
  #   intent absent -> the last line does not start with 'ok:' -> "reported
  #     findings". A FALSE RED that names the Rust, on a green codebase. Found
  #     by _tools-vc on their CI (run 33263160164: AT01-AT12 all pass, AT09 the
  #     single failure), reproduced here by scrubbing PATH.
  #   cargo absent -> "command not found" does not match ^warning|^error -> the
  #     count is 0 -> the check PASSES having measured nothing. A FALSE GREEN,
  #     and the worse direction: this is the control AC09 names explicitly
  #     BECAUSE a clean critic alone cannot go red, carrying the same defect.
  #
  # This matters on a runner, not here. test-macos runs a bare `utilz test`,
  # so it runs this file; .github/workflows/tests.yml mentions `intent` zero
  # times. An `unchecked` still fails --strict, which is correct -- it just
  # fails saying the tool is missing instead of blaming the code.
  # THE CRITIC IS NOT RUN HERE, AND ITS ABSENCE IS THE FIX RATHER THAN A GAP.
  # `intent critic rust` already runs on every commit, through this project's
  # pre-commit gate. Asserting it here as well is a second home for one
  # enforcement -- and it is the home that cannot work, because `intent` is a
  # developer tool that no runner has. Measured on CI 2026-08-29: it was the
  # single remaining skip, and --strict counts a skip as a failure, correctly.
  #
  # The alternatives were worse. Installing intent means building another
  # project from source on every run and reddening Utilz whenever ITS main is
  # red. Inventing a "not applicable" outcome means a control that cannot go
  # red, which is the class this suite exists to refuse.
  #
  # NOTHING IS LOST, and AC09 says why in its own words: the critic arms 1 of
  # its 7 rust rules and declines the clippy-backed ones, which is exactly why
  # AC09 named clippy separately. Clippy is the load-bearing gate, it runs
  # unconditionally below, and CI runs it again with -D warnings in its own job.

  if ! command -v cargo >/dev/null 2>&1; then
    unchecked "clippy unmeasured, cargo is not installed"
  else
    clippy=$(cd "$REPO" && CARGO_TARGET_DIR="$TARGET" cargo clippy --manifest-path "$CRATE/Cargo.toml" \
      --all-targets 2>&1 | grep -cE '^(warning|error)(\[|:)' || true)
    check "clippy warnings and errors" "${clippy:-0}" "0"
  fi
  finish
fi

# ---------------------------------------------------------------- AT13 -- AC14

if want AT13; then
  start AT13 "announce-on-resolve: a theme off PREZ_THEME_PATH says which directory dressed the deck"
  # NET-NEW IN UTILZ, not carried. The announcement is this repo's one
  # behavioural addition to the crate (design 7.5), deferred out of _tools to
  # keep the pin narrow -- so unlike its neighbours this AT has never been green
  # anywhere else and proves the behaviour rather than re-proving a port.
  #
  # A MINIMAL DECK, NOT $DEMO. Half of this is a silence check, and demo.md
  # legitimately produces other warnings; measuring silence against a deck that
  # has things to say would be testing the deck.
  AT13DIR="$WORK/at13"
  mkdir -p "$AT13DIR/first/housestyle" "$AT13DIR/second/housestyle" "$AT13DIR/second/mono"
  printf 'body{background:#111}\n' > "$AT13DIR/first/housestyle/theme.css"
  printf 'body{background:#222}\n' > "$AT13DIR/second/housestyle/theme.css"
  printf 'body{background:#333}\n' > "$AT13DIR/second/mono/theme.css"
  printf '# One\n\ntext\n' > "$AT13DIR/deck.md"

  # 1. An external name announces itself. The deck records nothing about the
  #    environment that dressed it, so without this line the artifact's look is
  #    a property of a variable nobody mentioned.
  PREZ_THEME_PATH="$AT13DIR/second" "$BIN" build "$AT13DIR/deck.md" --theme=housestyle \
    -o "$AT13DIR/a.html" 2>"$AT13DIR/a.err" >/dev/null
  present "an external theme announces itself" "came from" "$AT13DIR/a.err"
  present "and names the variable it came off" "PREZ_THEME_PATH" "$AT13DIR/a.err"

  # 2. WHICH directory won, as an exact path rather than as presence. Both
  #    directories hold a 'housestyle', so only the real resolution order produces
  #    the first one -- a hardcoded or approximate message cannot pass here.
  #    This is AC14's own clause: two directories, and the user can still answer.
  PREZ_THEME_PATH="$AT13DIR/first:$AT13DIR/second" "$BIN" build "$AT13DIR/deck.md" \
    --theme=housestyle -o "$AT13DIR/b.html" 2>"$AT13DIR/b.err" >/dev/null
  won=$(sed -n 's/.*came from \(.*\) (on PREZ_THEME_PATH).*/\1/p' "$AT13DIR/b.err")
  check "the directory named as the winner" "$won" "$AT13DIR/first"

  # 3. Shadowing a built-in must READ differently, because it FAILS differently:
  #    an external name refuses elsewhere, loudly; a shadowing one silently
  #    builds a different deck. One wording for both would bury the second.
  PREZ_THEME_PATH="$AT13DIR/second" "$BIN" build "$AT13DIR/deck.md" --theme=mono \
    -o "$AT13DIR/c.html" 2>"$AT13DIR/c.err" >/dev/null
  present "shadowing a built-in is called shadowing" "SHADOWING" "$AT13DIR/c.err"
  absent "and the merely-external case is not" "SHADOWING" "$AT13DIR/a.err"

  # 4. THE CONTROL: a built-in resolving says nothing. A line on every default
  #    build would be noise, and noise is how a real notice stops being read.
  "$BIN" build "$AT13DIR/deck.md" --theme=mono -o "$AT13DIR/d.html" \
    2>"$AT13DIR/d.err" >/dev/null
  absent "a built-in announces nothing" "came from" "$AT13DIR/d.err"

  # 5. The announcement is not the whole guarantee. Where the directory is
  #    absent an external name must still REFUSE, never fall back. If this check
  #    ever goes quiet, the lines above are decorating a tool that has started
  #    guessing. Exit code read with no pipe in the way -- see the AT discipline
  #    note; a piped $? is head's, and it reads as 0.
  "$BIN" build "$AT13DIR/deck.md" --theme=housestyle -o "$AT13DIR/e.html" \
    >/dev/null 2>"$AT13DIR/e.err"
  check "an external name off the path is refused" "$?" "2"
  present "and the refusal names the search path" "PREZ_THEME_PATH" "$AT13DIR/e.err"
  finish
fi

# ---------------------------------------------------------------- AT17 -- AC04

if want AT17; then
  start AT17 "the runtime's key handling, driven with no browser at all"
  # ID IS PROVISIONAL. vc owns the AT map and AT17 is the next free number under
  # their rule (an id equals the acceptance.sh block id the suite prints);
  # renumber freely, the block does not care what it is called.
  #
  # WHY THIS SITS BESIDE AT04 RATHER THAN INSIDE IT. AT04 drives real Chrome and
  # is the only thing that can prove fullscreen, focus and real key events. It
  # also cannot run without a browser -- which means every runtime change stays
  # unverified until someone with Chrome runs it, and a keyboard runtime is
  # exactly what gets shipped on "it compiles". This stubs the DOM surfaces the
  # runtime touches, loads the script OUT OF A BUILT ARTIFACT so what ships is
  # what is tested, and dispatches keydown events at it.
  #
  # It claims dispatch and state, and nothing visual. That boundary is the
  # reason both exist.
  if ! command -v node >/dev/null 2>&1; then
    skip "node is not installed"
  else
    at17deck="$WORK/at17.md"
    printf '# 1\n\na\n\n---\n\n# 2\n\nb\n\n---\n\n# 3\n\nc\n\n---\n\n# 4\n\nd\n' > "$at17deck"
    "$BIN" build "$at17deck" -o "$WORK/at17.html" >/dev/null 2>&1
    # No pipe: $? must be the probe's, not a formatter's. The AT discipline note
    # this file opens with, applied to the newest block in it.
    # TWO DECKS, and the second is the one that matters. test_pres.md opts into
    # mermaid, so its runtime shares a <script> with 3.5 MB of vendored bundle
    # -- which is what caught the probe selecting the wrong span. A synthetic
    # deck alone would have gone on passing.
    "$BIN" build "$CRATE/examples/test_pres.md" -o "$WORK/at17-mermaid.html" >/dev/null 2>&1
    for at17case in "synthetic:$WORK/at17.html" "mermaid deck:$WORK/at17-mermaid.html"; do
      at17name="${at17case%%:*}"; at17file="${at17case#*:}"
      # No pipe: $? must be the probe's, not a formatter's. The AT discipline
      # note this file opens with, applied to the newest block in it.
      node "$HERE/runtime-logic-probe.mjs" "$at17file" > "$WORK/at17.out" 2>&1
      at17rc=$?
      check "runtime logic probe exit ($at17name)" "$at17rc" "0"
      # The count is asserted too: a probe that ran zero checks, or that bailed
      # on its own extraction guard, would otherwise be indistinguishable from
      # one that passed.
      at17n=$(grep -c '^  ok    ' "$WORK/at17.out" || true)
      if [ "${at17n:-0}" -ge 25 ]; then ok "$at17name: $at17n checks ran"
      else
        bad "$at17name: only ${at17n:-0} checks ran, expected at least 25"
        sed 's/^/        /' "$WORK/at17.out" | tail -6
      fi
    done
    finish
  fi
fi

# ---------------------------------------------------------------- AT15 -- AC18

if want AT15; then
  start AT15 "the harness must not lie, block, or be unreproducible"

  # ---- (a) ONE browser resolution, not two --------------------------------
  #
  # The clause says the harness "resolves through the tool's list or asks the
  # tool, NEVER a second copy". A check that the two lists AGREE would pass
  # right up to the moment it matters -- they agreed for weeks while drifting
  # was still possible, and the drift that did happen (drive.rs gained the PATH
  # names, this file did not) was invisible on macOS. So the assertion is the
  # structural one: chrome() holds NO browser literal at all.
  #
  # Scoped to chrome()'s body rather than the whole file, for two reasons. It
  # is where a second list would actually live; and a whole-file grep would
  # match THIS BLOCK's own needles, which is the self-matching defect already
  # recorded in this suite's history.
  at15fn="$WORK/at15-chrome.sh"
  sed -n '/^chrome() {/,/^}/p' "$HERE/acceptance.sh" > "$at15fn"
  at15lines=$(grep -c '' "$at15fn" || true)
  if [ "${at15lines:-0}" -gt 10 ]; then ok "extracted chrome() ($at15lines lines)"
  else bad "could not extract chrome() -- got ${at15lines:-0} lines, so the checks below prove nothing"; fi

  # The needles are assembled rather than written, so this block does not
  # contain the strings it forbids and cannot match itself.
  at15app='/App''lications/'
  at15mac='.app/Con''tents/MacOS/'
  at15path='chrom''ium-browser'
  for at15needle in "$at15app" "$at15mac" "$at15path"; do
    at15hits=$(grep -c -F -- "$at15needle" "$at15fn" || true)
    check "chrome() holds no '$at15needle'" "${at15hits:-0}" "0"
  done

  # SELF-DISCRIMINATION. A grep whose green is "no matches" passes just as
  # happily against a file it failed to read, so prove it can count before
  # trusting the zeros above.
  printf 'x %s y\n' "$at15app" > "$WORK/at15-control.txt"
  at15ctl=$(grep -c -F -- "$at15app" "$WORK/at15-control.txt" || true)
  check "the same grep counts a planted literal" "${at15ctl:-0}" "1"

  # And the positive half: it does not merely lack a list, it asks for one.
  present "chrome() asks the binary" 'BIN" browser' "$at15fn"

  # The tool's side of the same contract: a deck-less verb that answers.
  "$BIN" browser > "$WORK/at15-browser.out" 2>"$WORK/at15-browser.err"
  at15rc=$?
  if [ "$at15rc" -eq 0 ]; then
    at15got="$(cat "$WORK/at15-browser.out")"
    if [ -x "$at15got" ]; then ok "prez browser named an executable: $at15got"
    else bad "prez browser printed '$at15got', which is not executable"; fi
  else
    # Refusing is legitimate on a browserless box -- but the refusal must name
    # what it probed, which is the whole reason this door exists.
    present "the refusal names what it probed" "Probed:" "$WORK/at15-browser.err"
    unchecked "no browser on this machine, so the resolved path was not checked"
  fi

  # ---- (b) the browserless path is reproducible ---------------------------
  #
  # Before the override existed, the control proving --strict matters could not
  # be exercised anywhere Chrome was installed: a control that can never go red.
  # This forces it HERE, on a machine that has a browser.
  at15out="$WORK/at15-forced.err"
  if PREZ_TEST_BROWSER=/nonexistent chrome 2>"$at15out" >/dev/null; then
    bad "the override did not force the browserless path"
  else
    ok "the override forces the browserless path on a machine with a browser"
    # A SKIP CARRYING THE WRONG REASON IS THE DEFECT THIS AT IS ABOUT. The
    # refusal must blame the override, not invent an absent browser.
    present "the refusal blames the override" "PREZ_TEST_BROWSER" "$at15out"
    absent "the refusal does not claim no browser is installed" "no Chrome or Chromium installed" "$at15out"
  fi

  # A missing BINARY must not read as a missing BROWSER either -- same class,
  # and the build at the top of this file swallows its output, so this is the
  # only place that can tell them apart.
  #
  # PREZ_TEST_BROWSER is cleared for this ONE call, because the branch under
  # test sits BELOW the override and the override correctly returns before
  # reaching it. Without the clear this check passes on a normal run and FAILS
  # on the browserless leg -- a check whose answer depends on the ambient shell,
  # which is the defect this whole AT is named for. Caught by --strict on the
  # browserless control, 7 Sep, which is the control doing its job.
  at15nobin="$WORK/at15-nobin.err"
  if PREZ_TEST_BROWSER='' BIN="$WORK/definitely-not-here" chrome 2>"$at15nobin" >/dev/null; then
    bad "chrome() resolved a browser with no binary to ask"
  else
    present "a missing binary says so" "cannot be asked" "$at15nobin"
  fi

  # ---- (c) no interactive modal -------------------------------------------
  #
  # A fresh --user-data-dir makes macOS prompt for a Safe Storage keychain
  # entry: an interactive dialog in a non-interactive suite, which HANGS rather
  # than fails, and which --strict cannot tell from still working. It reached
  # hv's screen on 2026-08-29. --use-mock-keychain is the fix and $CHROME_SAFE
  # is its one home.
  #
  # The STRUCTURAL half is the guard that lasts: a launch site added without
  # $CHROME_SAFE is the regression, and it is greppable. Counted against the
  # launches actually present rather than a number written down here, because a
  # hardcoded count is a second roster -- the defect that reddened prez.bats.
  # EVERY launch of $BROWSER, not just the headless ones. This counted
  # `--headless` sites until 7 Sep, which excluded AT20's wrapper -- the single
  # launch in this suite that opens a VISIBLE window and therefore the only one
  # that can put a dialog in front of a human. hv got Chrome's first-run
  # "Welcome to Google Chrome" modal from it, mid-run, which is exactly the
  # class AC18(c) forbids, and the check written to catch that class was looking
  # the other way. A guard scoped to the safe launches is not a guard.
  at15launch=$(grep -c -E 'exec "\$BROWSER"|"\$BROWSER" --headless' "$HERE/acceptance.sh" || true)
  at15safe=$(grep -c -E '(exec "\$BROWSER"|"\$BROWSER" --headless)[^|]*CHROME_SAFE\[' "$HERE/acceptance.sh" || true)
  if [ "${at15launch:-0}" -gt 0 ]; then
    check "every launch of the browser carries \$CHROME_SAFE" "${at15safe:-0}" "${at15launch:-0}"
  else
    bad "found no browser launches to check, so this proves nothing"
  fi
  present "CHROME_SAFE is the mock-keychain flag" "use-mock-keychain" "$HERE/acceptance.sh"

  # The BEHAVIOURAL half. vc could confirm the flag is accepted and that Chrome
  # renders under it, but absence-of-a-dialog-on-someone-else's-screen is not
  # observable from a shell. What IS observable is the keychain: a fresh-profile
  # launch under --use-mock-keychain must not add a Safe Storage entry. Counted
  # before and after, because this machine may legitimately already hold one
  # from ordinary Chrome use, and asserting zero would fail for the wrong reason.
  if ! BROWSER="$(chrome 2>/dev/null)"; then
    unchecked "no browser, so the keychain half did not run"
  elif [ "$(uname -s)" != "Darwin" ]; then
    # PLATFORM, not `command -v security`. Safe Storage is a macOS keychain
    # concept, so there is nothing on Linux for this check to be about. The
    # macOS legs run it, so it is covered rather than waved away.
    not_applicable "Chrome Safe Storage is macOS-only; the macOS legs cover this"
  elif ! command -v security >/dev/null 2>&1; then
    # macOS WITHOUT security(1) is a broken machine, not an inapplicable one.
    unchecked "no security(1) on a Darwin host, so the keychain half did not run"
  else
    at15before=$(security find-generic-password -s "Chrome Safe Storage" 2>&1 | grep -c 'svce' || true)
    printf '<!doctype html><title>at15</title><p>at15\n' > "$WORK/at15.html"
    # BACKGROUND, PORT, KILL -- the shape AT04 and AT12 already use, and the
    # only one in this suite proven to survive a fresh --user-data-dir on this
    # machine. A foreground headless launch with a fresh profile does NOT exit
    # here: --dump-dom is documented six lines above CHROME_SAFE as hanging
    # exactly that way, and --screenshot was measured doing the same thing on
    # 7 Sep. A fresh profile is not optional for this check -- it is the thing
    # that provokes the keychain prompt -- so the launch shape has to give way
    # instead.
    at15port=9360
    "$BROWSER" --headless=new "${CHROME_SAFE[@]}" --remote-debugging-port=$at15port \
      --user-data-dir="$WORK/chrome-at15" "file://$WORK/at15.html" \
      >"$WORK/at15-chrome.log" 2>&1 &
    at15pid=$!
    if wait_for_cdp "$at15port"; then
      ok "a fresh-profile headless launch came up under \$CHROME_SAFE"
    else
      bad "chrome never opened its debugging port on $at15port with a fresh profile"
    fi
    kill "$at15pid" 2>/dev/null; wait "$at15pid" 2>/dev/null
    at15after=$(security find-generic-password -s "Chrome Safe Storage" 2>&1 | grep -c 'svce' || true)
    check "no Safe Storage entry was created" "${at15after:-0}" "${at15before:-0}"
  fi

  finish
fi

# ---------------------------------------------------------------- AT20 -- AC19

if want AT20; then
  start AT20 "the presenting window that actually appears, at the deck's shape"

  # AT18 has the argv layer and it is the only place a silently-DROPPED flag is
  # catchable. This is the other half: a flag that was sent and IGNORED. Chrome
  # took --start-fullscreen on every launch for as long as the function existed
  # and did nothing with it, and nothing in the process, the exit status or the
  # logs said so -- it took a screenshot of a portrait window to find.
  #
  # THIS IS THE ONLY BLOCK IN THE SUITE THAT PUTS A REAL WINDOW ON A SCREEN.
  # THIS AT NEEDS A DISPLAY, AND SAYS SO RATHER THAN FAILING OBSCURELY.
  # `present` opens a REAL window; with no display Chrome cannot open one, the
  # debugging port never appears, and the run reports "the presenting window
  # never opened its debugging port" -- which reads as a prez defect and is not
  # one. Measured on Ubuntu CI 2026-09-07, where it reddened a correct build.
  # On macOS a window server is always present. On Linux, DISPLAY or
  # WAYLAND_DISPLAY is the evidence; CI supplies one via Xvfb.
  at20has_display=1
  if [ "$(uname -s)" != "Darwin" ] && [ -z "${DISPLAY:-}" ] && [ -z "${WAYLAND_DISPLAY:-}" ]; then
    at20has_display=0
  fi

  if ! BROWSER="$(chrome)"; then skip "no browser, and this AT is meaningless headless"
  elif ! command -v node >/dev/null 2>&1; then skip "no node for the CDP probe"
  elif [ "$at20has_display" -eq 0 ]; then
    skip "no DISPLAY or WAYLAND_DISPLAY, so no window can open -- run under xvfb-run, or on a desktop"
  else
    # THE WRAPPER IS THE WHOLE TRICK. prez does not pass a debugging port, and
    # adding one by rebuilding its argv here would measure a reconstruction --
    # a second copy of presenting_argv, which is the defect AT15 just removed
    # from chrome(). Instead --browser (a flag prez already has) points at a
    # shim that APPENDS the port and execs the real browser, so prez builds and
    # sends its own argv untouched and what gets measured is prez's launch.
    # ${CHROME_SAFE[*]} AND NOT "${CHROME_SAFE[@]}" -- the one place in this file
    # where the quoted array form is wrong. This is a HEREDOC: the quotes would
    # be literal text in the generated script, so /bin/sh would receive the
    # three flags as a single argument. Here the array is being flattened INTO
    # source text, not expanded into an argv.
    at20wrap="$WORK/at20-browser"
    cat > "$at20wrap" <<WRAP
#!/bin/sh
exec "$BROWSER" ${CHROME_SAFE[*]} --remote-debugging-port=\$AT20_PORT --user-data-dir="\$AT20_PROFILE" "\$@"
WRAP
    chmod +x "$at20wrap"

    # The expected default is ASKED OF THE TOOL, never written down here: the
    # value lives in drive.rs::default_window and a copy in this file would be
    # a second roster that goes stale silently. If --help and the code ever
    # disagree, this check is where that surfaces.
    at20def=$("$BIN" --help | sed -n 's/.*Default: \([0-9][0-9]*x[0-9][0-9]*\).*/\1/p' | head -1)
    if [ -n "$at20def" ]; then ok "default window read from the tool: $at20def"
    else bad "could not read the default window size out of prez --help"; fi
    at20dw="${at20def%x*}"; at20dh="${at20def#*x}"

    # Killed by profile path: each launch gets a unique --user-data-dir, so this
    # cannot reach a browser window belonging to the human. Called explicitly at
    # each step rather than from a trap, because `trap ... RETURN` outside a
    # function never fires and would be cleanup that only looks like cleanup.
    at20kill() { pkill -f "at20-profile" 2>/dev/null; sleep 1; }

    # ---- (a) the default: the deck's own shape ----------------------------
    AT20_PORT=9370
    AT20_PROFILE="$WORK/at20-profile-cold"
    export AT20_PORT AT20_PROFILE
    "$BIN" present "$DEMO" --browser "$at20wrap" >"$WORK/at20-present.log" 2>&1
    check "prez present exited rather than staying resident" "$?" "0"
    if wait_for_cdp "$AT20_PORT"; then
      node "$HERE/at20-window-probe.mjs" "$AT20_PORT" "$at20dw" "$at20dh" "default" > "$WORK/at20-a.out" 2>&1
      at20rc=$?
      sed -n 's/^/    /p' "$WORK/at20-a.out"
      check "the default window matches the deck's shape" "$at20rc" "0"
    else
      bad "the presenting window never opened its debugging port"
    fi

    # ---- (b) --window overrides -------------------------------------------
    # A DIFFERENT ASPECT ON PURPOSE, not just a different size: 900x600 is 3:2
    # against the default's 16:9, so a window that ignored --window and kept the
    # default would fail the aspect check rather than sliding under a tolerance.
    at20kill
    AT20_PORT=9371
    AT20_PROFILE="$WORK/at20-profile-override"
    export AT20_PORT AT20_PROFILE
    "$BIN" present "$DEMO" --browser "$at20wrap" --window 900x600 >>"$WORK/at20-present.log" 2>&1
    if wait_for_cdp "$AT20_PORT"; then
      node "$HERE/at20-window-probe.mjs" "$AT20_PORT" 900 600 "override" > "$WORK/at20-b.out" 2>&1
      at20rc=$?
      sed -n 's/^/    /p' "$WORK/at20-b.out"
      check "--window overrides the default" "$at20rc" "0"
    else
      bad "the overridden presenting window never opened its debugging port"
    fi

    # ---- the open question, settled rather than dodged ---------------------
    #
    # utilz-cc's question, unanswered since 29 Aug: when Chrome is ALREADY
    # RUNNING, a launch can FORWARD to the existing instance instead of starting
    # a new one, and --window-size may not apply on that path -- so AC19's
    # geometry could be cold-start-only. A green taken with no Chrome running
    # does not answer it and must not be recorded as if it had.
    #
    # FORWARDING IS PROVOKED BY THE SHARED PROFILE, AND GETTING THIS BACKWARDS
    # IS HOW THIS LEG FIRST PASSED FOR THE WRONG REASON. The first version used
    # a DIFFERENT --user-data-dir for the second launch and called that a fair
    # test; a distinct profile is precisely what makes Chrome start a fresh
    # instance and never forward, so it measured two independent cold starts and
    # reported the question answered. Same profile, second launch: that is the
    # forwarding path.
    #
    # A SECOND ARTIFACT, so the two windows have different URLs and the probe can
    # tell which is which. With one artifact both targets look identical and the
    # measurement could read the FIRST window while believing it read the second.
    at20kill
    at20second="$WORK/at20-second.md"
    printf '# Second\n\ntext\n' > "$at20second"
    AT20_PORT=9372
    AT20_PROFILE="$WORK/at20-profile-shared"
    export AT20_PORT AT20_PROFILE
    "$BIN" present "$DEMO" --browser "$at20wrap" --window 1024x768 >>"$WORK/at20-present.log" 2>&1
    if ! wait_for_cdp "$AT20_PORT"; then
      unchecked "the first shared-profile launch opened no port, so the forwarding question is still open"
    else
      # Prove the first window is really there and really 1024x768 before using
      # it as the thing a second launch forwards INTO. Without this the leg below
      # could pass by measuring nothing.
      node "$HERE/at20-window-probe.mjs" "$AT20_PORT" 1024 768 "first" > "$WORK/at20-c1.out" 2>&1
      at20rc=$?
      sed -n 's/^/    /p' "$WORK/at20-c1.out"
      check "the first instance is up at its requested size" "$at20rc" "0"

      # Snapshot the windows that exist BEFORE the forwarding launch, so the
      # probe can pick the one that appears rather than guess at its URL.
      curl -s "http://127.0.0.1:$AT20_PORT/json/list" \
        | sed -n 's/.*"url": "\(file:[^"]*\)".*/\1/p' > "$WORK/at20-before.urls"
      check "one window open before the forwarding launch" "$(grep -c . "$WORK/at20-before.urls")" "1"

      # SAME PROFILE, still running. This is the launch that forwards.
      "$BIN" present "$at20second" --browser "$at20wrap" --window 640x480 >>"$WORK/at20-present.log" 2>&1
      # AC19(d), reworded 7 Sep: the forwarded window is EXPECTED to inherit.
      # This asserted 640x480 and went red for a real reason -- Chrome forwards
      # into the running instance and ignores --window-size. The criterion now
      # says so, so the check asserts the MEASURED behaviour rather than the
      # wish, and it can still go red: if a future Chrome starts honouring the
      # flag on this path, the inheritance assertion fails and sends someone
      # back to the criterion, which is the correct outcome rather than a
      # silent improvement nobody notices.
      node "$HERE/at20-window-probe.mjs" "$AT20_PORT" 1024 768 "forwarded" "$WORK/at20-before.urls" > "$WORK/at20-c2.out" 2>&1
      at20rc=$?
      sed -n 's/^/    /p' "$WORK/at20-c2.out"
      if [ "$at20rc" -eq 0 ]; then
        ok "the forwarded window inherits the running instance's geometry, as AC19(d) documents"
      else
        bad "the forwarded window did NOT inherit -- AC19(d) describes behaviour this build does not have, so the criterion is now wrong and needs re-measuring"
      fi

      # THE DOCUMENTATION CLAUSE IS PART OF THE CRITERION, SO IT IS CHECKED.
      # AC19(d) requires the limit to be stated where a user meets it. A clause
      # satisfied only by someone remembering to write the page is not
      # satisfied; the whole point is that a user who passes --window and gets
      # another size can find out why.
      present "help/prez.md states the forwarding limit" "Chrome forwards a new launch" "$REPO/help/prez.md"
      present "and says what to do about it" "quit Chrome first" "$REPO/help/prez.md"
    fi

    at20kill
    finish
  fi
fi

# ---------------------------------------------------------------------- report

printf '\n=======================================\n'
printf 'passed %d   failed %d   skipped %d   n/a %d\n' "$PASSED" "$FAILED" "$SKIPPED" "$NOT_APPLICABLE"
[ "$NOT_APPLICABLE" -gt 0 ] && printf 'n/a = cannot exist on this platform, and covered on one that can. Not a skip.\n'
[ "$SKIPPED" -gt 0 ] && printf 'A SKIP is not a pass. Re-run where the missing tool exists.\n'

[ "$FAILED" -gt 0 ] && exit 1
if [ "$STRICT" -eq 1 ] && [ "$SKIPPED" -gt 0 ]; then
  # `--` first: printf reads a leading --strict in the FORMAT as its own option
  # and errors, which left the message broken while the exit code was correct.
  printf -- '--strict: %d check(s) did not run, so this run does not pass.\n' "$SKIPPED"
  exit 1
fi
exit 0
