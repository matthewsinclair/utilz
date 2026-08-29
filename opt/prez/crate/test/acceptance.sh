#!/usr/bin/env bash
#
# prez acceptance tests -- the ATs behind ST0002's acceptance criteria.
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
# The DEFAULT in-crate target/, not a redirect. _tools pointed this at
# ~/.cache/geodica/cargo-target because its checkout lives in a Dropbox-synced
# tree that must not carry build output. Utilz is a plain local checkout, so
# the default is correct here and .gitignore's opt/*/crate/target/ is the whole
# fence. CARGO_TARGET_DIR still wins if a caller sets it, which is what lets CI
# or a cold-build run point somewhere else without editing this file.
TARGET="${CARGO_TARGET_DIR:-$CRATE/target}"
BIN="$TARGET/release/prez"
DEMO="$CRATE/examples/demo.md"
SENTINEL="PREZ-SENTINEL-7F3A"

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
PASSED=0; FAILED=0; SKIPPED=0
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

# Mirrors src/drive.rs's probe: APP_PATHS then PATH_NAMES. It used to carry
# only the first two macOS app paths, so on Linux the TOOL found Chrome and
# worked while the HARNESS did not -- five call sites skipped, and --strict
# turned that into a failing run on a correct build. The message said "no
# Chrome or Chromium installed" and measured "no Chrome at a macOS app path".
# Invisible here forever; it would have surfaced on Utilz's first Ubuntu job
# looking exactly like the port broke something. (_tools-vc, 29 Aug.)
#
# A MIRROR IS NOT THE RIGHT ANSWER AND THIS COMMENT IS NOT AN EXCUSE FOR IT.
# Two lists of the same fact drift, which is precisely what happened: drive.rs
# gained the PATH names and this did not, and nothing reported it because both
# only ever ran on macOS. builtins_list() above avoids this by ASKING the
# binary, and the same trick does not work here -- the tool only enumerates its
# browser probe when its own auto-probe fails, which cannot be provoked on a
# machine that has a browser. The durable fix is for the tool to expose its
# resolution (a --print-browser, or the refusal naming the list unconditionally)
# so this function can ask instead of copy. Raised for Utilz; the mirror is the
# stopgap that at least makes the two lists agree today.
chrome() {
  local p
  # THE OVERRIDE (AC18b), checked BEFORE the probe so it wins outright:
  #   PREZ_TEST_BROWSER=/nonexistent      -> no browser; every browser AT skips
  #   PREZ_TEST_BROWSER=/path/to/chromium -> drive exactly that one
  #
  # Without it the browserless path CANNOT BE EXERCISED on a machine that has
  # Chrome, so the control proving --strict matters is a control that can never
  # go red -- the exact class this file is written against, sitting in the file
  # itself. Every browser AT resolves through this one function, so the hook has
  # one home and reaches all five.
  #
  # A set-but-not-executable value returns 1 rather than falling through to the
  # probe. Falling through would make "force the refusal path" mean "force it
  # unless this machine happens to have Chrome", which is the thing being fixed.
  if [ -n "${PREZ_TEST_BROWSER:-}" ]; then
    if [ -x "$PREZ_TEST_BROWSER" ]; then
      printf '%s' "$PREZ_TEST_BROWSER"
      return 0
    fi
    # SAY WHY. The five call sites all skip with "no Chrome or Chromium
    # installed", which is FALSE when the override caused it -- and a skip
    # carrying the wrong reason is the class AC18 is about, so producing one
    # here to test for it would be its own joke. Reported from the one place
    # that knows, rather than by editing five messages _tools is patching now.
    printf 'note: PREZ_TEST_BROWSER=%s is not executable, so no browser is offered.\n' \
      "$PREZ_TEST_BROWSER" >&2
    return 1
  fi
  for p in "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
           "/Applications/Chromium.app/Contents/MacOS/Chromium" \
           "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge" \
           "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"; do
    [ -x "$p" ] && { printf '%s' "$p"; return 0; }
  done
  for p in google-chrome google-chrome-stable chromium chromium-browser \
           microsoft-edge brave-browser; do
    command -v "$p" >/dev/null 2>&1 && { command -v "$p"; return 0; }
  done
  return 1
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
CHROME_SAFE="--use-mock-keychain"

# ---------------------------------------------------------------- AT01 -- AC01

if want AT01; then
  start AT01 "build hygiene: the build lands in-crate and leaves no litter in git"
  # REWRITTEN ON THE HOIST, and the AC underneath it changed rather than the
  # test drifting. In _tools this proved AC01 -- that `bin/devbin build`
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

  size=$(stat -f %z "$CRATE/target/release/prez" 2>/dev/null || stat -c %s "$CRATE/target/release/prez" 2>/dev/null || echo 0)
  if [ "$size" -gt 0 ] && [ "$size" -le 8388608 ]; then ok "binary $((size / 1048576)) MB <= 8 MB ceiling"
  else bad "binary is $size bytes against an 8 MB ceiling"; fi
  finish
fi

cargo build --release --manifest-path "$CRATE/Cargo.toml" >/dev/null 2>&1

# ---------------------------------------------------------------- AT02 -- AC02

if want AT02; then
  start AT02 "dependency posture: comrak and std, nothing else"
  declared="$(awk '/^\[dependencies\]/{f=1;next} /^\[/{f=0} f && /^[a-zA-Z]/ {print $1}' "$CRATE/Cargo.toml" | sort | tr '\n' ' ')"
  check "declared dependencies" "$declared" "comrak "

  # The other half of AC02: the named jobs are HAND-ROLLED, which shows up as
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

# ------------------------------------------------------------ AT03 -- AC03/04

if want AT03; then
  start AT03 "self-contained artifact, and notes that reach no artifact"
  art="$WORK/demo.html"
  "$BIN" build "$DEMO" -o "$art" >/dev/null 2>"$WORK/at03.err"

  size=$(stat -f %z "$art")
  if [ "$size" -le 102400 ]; then ok "artifact $size bytes <= 100 KB"; else bad "artifact is $size bytes"; fi

  # AC04. The SENTINEL, never the `notes:` token: the demo shows a fenced notes
  # example on purpose, so a token grep would fail a correct build.
  absent "AC04 sentinel is nowhere in the HTML" "$SENTINEL" "$art"
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

# ---------------------------------------------------------------- AT04 -- AC05

if want AT04; then
  start AT04 "base runtime in a real browser: keys, counter, overview, hash, fullscreen"
  if ! BROWSER="$(chrome)"; then skip "no Chrome or Chromium installed"
  elif ! command -v node >/dev/null 2>&1; then skip "node is not installed (the CDP probe needs it)"
  else
    art="$WORK/runtime.html"
    "$BIN" build "$DEMO" -o "$art" >/dev/null 2>&1
    "$BROWSER" --headless=new $CHROME_SAFE --remote-debugging-port=9333 --window-size=1280,800 \
      --user-data-dir="$WORK/chrome" "file://$art" >"$WORK/chrome.log" 2>&1 &
    CHROME_PID=$!
    sleep 2
    if node "$HERE/at04-runtime-probe.mjs" 9333; then ok "every runtime check passed"; else bad "the runtime probe reported failures"; fi
    kill "$CHROME_PID" 2>/dev/null; wait "$CHROME_PID" 2>/dev/null
    finish
  fi
fi

# ---------------------------------------------------------------- AT05 -- AC06

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
    "$BIN" pdf "$DEMO" --theme "$WORK/wide.css" -o "$WORK/wide.pdf" >/dev/null 2>&1
    check "a theme may set page size" "$(paper_of "$WORK/wide.pdf")" "400x200"
    check "and still gets one page per slide" "$(pages_in "$WORK/wide.pdf")" "6"

    # And when a theme defeats the break anyway with !important -- which order
    # cannot stop -- the page count control catches it. This is the check that
    # exists because the stronger claim was falsified.
    printf '@media print { section { break-after: auto !important; height: auto !important } }\n' > "$WORK/defeat.css"
    "$BIN" pdf "$DEMO" --theme "$WORK/defeat.css" -o "$WORK/defeat.pdf" 2>"$WORK/defeat.err" >/dev/null
    present "a collapsed PDF is reported, not shipped silently" "defeating one-slide-per-page" "$WORK/defeat.err"

    "$BIN" pdf "$DEMO" --browser /nonexistent -o "$WORK/never.pdf" >/dev/null 2>"$WORK/refuse.err"
    check "--browser /nonexistent exit code" "$?" "2"
    present "the refusal names the path given" "/nonexistent" "$WORK/refuse.err"
    [ -f "$WORK/never.pdf" ] && bad "a refused pdf left a partial file" || ok "a refused pdf left no file"
    finish
  fi
fi

# ---------------------------------------------------------------- AT06 -- AC07

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

# ---------------------------------------------------------------- AT07 -- AC08

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

  on=$(stat -f %z "$WORK/m.html"); off=$(stat -f %z "$WORK/nom.html")
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
    measured=$("$BROWSER" --headless $CHROME_SAFE \
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

# ---------------------------------------------------------------- AT08 -- AC09

if want AT08; then
  start AT08 "themes are orthogonal, offline, and the default carries no brand"
  BROWSER="$(chrome || true)"
  deck_before=$(shasum "$DEMO" | cut -d' ' -f1)
  printf 'body{background:#0a0a0a;color:#00ff00}\n' > "$WORK/good.css"
  "$BIN" build "$DEMO" --theme "$WORK/good.css" -o "$WORK/themed.html" >/dev/null 2>&1
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
  "$BIN" build "$DEMO" --theme "$WORK/bad.css" -o "$WORK/never.html" 2>"$WORK/theme.err" >/dev/null
  check "an external URL in a theme exits" "$?" "2"
  present "the refusal names the file" "bad.css" "$WORK/theme.err"
  present "the refusal names the line" "line 2" "$WORK/theme.err"
  present "the refusal names the offender" "fonts.example" "$WORK/theme.err"
  [ -f "$WORK/never.html" ] && bad "a refused build left a partial artifact" || ok "a refused build left no artifact"

  # An attribution URL in a comment is documentation, not a reference. Without
  # this the rule would teach theme authors to delete their attributions.
  printf '/* adapted from https://example.com/t, MIT */\nbody{color:red}\n' > "$WORK/attrib.css"
  "$BIN" build "$DEMO" --theme "$WORK/attrib.css" -o "$WORK/attrib.html" >/dev/null 2>&1
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
      measured=$("$BROWSER" --headless $CHROME_SAFE \
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

# ---------------------------------------------------------------- AT12 -- AC13

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
      "$BROWSER" --headless=new $CHROME_SAFE --remote-debugging-port=$port \
        --window-size=1280,800 --user-data-dir="$WORK/chrome-at12" "file://$art" \
        >"$WORK/chrome-at12.log" 2>&1 &
      local pid=$!
      sleep 2
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

# ---------------------------------------------------------------- AT09 -- AC10

if want AT09; then
  start AT09 "the source is standalone, and both code gates are run"
  paths=$(grep -rlE '"(/Users/|.*Dropbox)' "$CRATE/src" 2>/dev/null | wc -l | tr -d ' ')
  check "estate paths in string literals" "$paths" "0"
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
  if (cd "$REPO" && intent critic rust --files "$CRATE"/src/*.rs 2>&1 | tail -1 | grep -q '^ok:'); then
    ok "intent critic rust is clean"
  else bad "intent critic rust reported findings"; fi

  clippy=$(cd "$REPO" && CARGO_TARGET_DIR="$TARGET" cargo clippy --manifest-path "$CRATE/Cargo.toml" \
    --all-targets 2>&1 | grep -cE '^(warning|error)(\[|:)' || true)
  check "clippy warnings and errors" "${clippy:-0}" "0"
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
  mkdir -p "$AT13DIR/first/geodica" "$AT13DIR/second/geodica" "$AT13DIR/second/mono"
  printf 'body{background:#111}\n' > "$AT13DIR/first/geodica/theme.css"
  printf 'body{background:#222}\n' > "$AT13DIR/second/geodica/theme.css"
  printf 'body{background:#333}\n' > "$AT13DIR/second/mono/theme.css"
  printf '# One\n\ntext\n' > "$AT13DIR/deck.md"

  # 1. An external name announces itself. The deck records nothing about the
  #    environment that dressed it, so without this line the artifact's look is
  #    a property of a variable nobody mentioned.
  PREZ_THEME_PATH="$AT13DIR/second" "$BIN" build "$AT13DIR/deck.md" --theme=geodica \
    -o "$AT13DIR/a.html" 2>"$AT13DIR/a.err" >/dev/null
  present "an external theme announces itself" "came from" "$AT13DIR/a.err"
  present "and names the variable it came off" "PREZ_THEME_PATH" "$AT13DIR/a.err"

  # 2. WHICH directory won, as an exact path rather than as presence. Both
  #    directories hold a 'geodica', so only the real resolution order produces
  #    the first one -- a hardcoded or approximate message cannot pass here.
  #    This is AC14's own clause: two directories, and the user can still answer.
  PREZ_THEME_PATH="$AT13DIR/first:$AT13DIR/second" "$BIN" build "$AT13DIR/deck.md" \
    --theme=geodica -o "$AT13DIR/b.html" 2>"$AT13DIR/b.err" >/dev/null
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
  "$BIN" build "$AT13DIR/deck.md" --theme=geodica -o "$AT13DIR/e.html" \
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

# ---------------------------------------------------------------------- report

printf '\n=======================================\n'
printf 'passed %d   failed %d   skipped %d\n' "$PASSED" "$FAILED" "$SKIPPED"
[ "$SKIPPED" -gt 0 ] && printf 'A SKIP is not a pass. Re-run where the missing tool exists.\n'

[ "$FAILED" -gt 0 ] && exit 1
if [ "$STRICT" -eq 1 ] && [ "$SKIPPED" -gt 0 ]; then
  # `--` first: printf reads a leading --strict in the FORMAT as its own option
  # and errors, which left the message broken while the exit code was correct.
  printf -- '--strict: %d check(s) did not run, so this run does not pass.\n' "$SKIPPED"
  exit 1
fi
exit 0
