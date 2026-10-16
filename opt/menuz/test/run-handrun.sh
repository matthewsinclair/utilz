#!/bin/bash
# ST0027 AC-04.5, running items, run by hand on a Mac with the app built and
# hv's hands off: the Debug product under fixture XDG dirs, driven through
# the accessibility tree by run-handrun.lua under Hammerspoon. discover
# saves a desk through the form; the each-generated item applies it (the
# arrangement on screen, so no window moves); a text param through the form;
# a slow run with the app quit mid-way (D9: the end line lands after the
# quit line). arngz reaches the runs through MENUZ_HOME/bin, linked to this
# checkout's; the fixture catalogue starts empty and hv's is never touched.
# Usage: opt/menuz/test/run-handrun.sh <Menuz.app> [out-dir]
# The transcript's lines go on AT-04.5's note in acceptance.md.
set -uo pipefail
APP="${1:?usage: run-handrun.sh <Menuz.app> [out-dir]}"; BIN="$APP/Contents/MacOS/Menuz"
[ -x "$BIN" ] || { echo "no binary at $BIN"; exit 2; }
D="$(cd "$(dirname "$0")" && pwd)"; L="$D/run-handrun.lua"
ARNGZ="$(cd "$D/../../../bin" && pwd)/arngz"; [ -x "$ARNGZ" ] || { echo "no arngz at $ARNGZ"; exit 2; }
S="${2:-${TMPDIR:-/tmp}/menuz-run-handrun}"; rm -rf "$S"; mkdir -p "$S"
FIX="$S/home"; mkdir -p "$FIX/.config/menuz" "$FIX/.local/state"
export XDG_CONFIG_HOME="$FIX/.config" XDG_STATE_HOME="$FIX/.local/state"
LOG="$XDG_STATE_HOME/menuz/menuz.log"
BID=com.matthewsinclair.utilz.menuz
mkdir -p "$XDG_CONFIG_HOME/menuz/bin"; ln -s "$ARNGZ" "$XDG_CONFIG_HOME/menuz/bin/arngz"
cat >"$XDG_CONFIG_HOME/menuz/menuz.yaml" <<'YAML'
menu:
  - header: Desks
  - each: ls "${XDG_CONFIG_HOME:-$HOME/.config}/arngz/desks" 2>/dev/null | sed 's/\.yaml$//'
    label: "$MENUZ_ITEM"
    run: arngz apply "$MENUZ_ITEM"
  - label: Discover this arrangement
    params:
      - name: desk
        prompt: Save the arrangement on screen now as
        default: today
    run: arngz discover --save "$desk" --force
  - separator: true
  - label: Hello
    params:
      - name: name
        prompt: Your name
        default: world
    run: echo "hello $name"
  - label: Slow
    run: sleep 20; echo done
YAML
drive() { hs -t 30 -c "STEP='$1'; ARG='$2'; return dofile('$L')" </dev/null 2>&1 | cut -c1-200; }
running() { osascript -l JavaScript -e "ObjC.import('AppKit'); \$.NSRunningApplication.runningApplicationsWithBundleIdentifier('$BID').count > 0" </dev/null 2>&1; }
[ "$(running)" = false ] || { echo "Menuz is already running; stopping"; exit 2; }
echo "== launch at $(date -u +%H:%M:%SZ) =="; "$BIN" </dev/null >"$S/app.txt" 2>&1 & sleep 4; echo "running: $(running)"
echo "== 1: discover through the form (desk = vc-ac045) =="
echo "menu: $(drive menu 'Discover this arrangement')"; sleep 1
echo "windows: $(drive windows '')"
echo "form: $(drive form 'desk=vc-ac045')"
echo "press: $(drive press Run)"; sleep 6
echo "desk saved: $(ls "$XDG_CONFIG_HOME/arngz/desks/vc-ac045.yaml" 2>&1)"
echo "== 2: apply vc-ac045 from the each-generated items =="
echo "menu: $(drive menu 'vc-ac045')"; sleep 8
echo "== 3: a text param through the form (Hello) =="
echo "menu: $(drive menu 'Hello')"; sleep 1
echo "form: $(drive form 'name=hv')"
echo "press: $(drive press Run)"; sleep 3
echo "== 4: a slow run, the app quit during it =="
echo "menu: $(drive menu 'Slow')"; sleep 3
osascript -e "tell application id \"$BID\" to quit" </dev/null; sleep 2; echo "running after quit: $(running)"
echo "waiting 22 s for the detached run's end line"; sleep 22
echo "== the log =="; sed 's/^/        /' "$LOG" | cut -c1-200
echo "== checks =="
grep -c '^[0-9T:Z-]* run [0-9]* start' "$LOG" | sed 's/^/start lines: /'
grep -c ' exit 0 in ' "$LOG" | sed 's/^/exit 0 lines: /'
grep -n 'hello hv' "$LOG" | sed 's/^/hello: /'
grep -n 'quit' "$LOG" | sed 's/^/quit: /'
awk '/quit/{q=NR} /\] done/{d=NR} END{ if (q && d && d > q) print "done after the quit line: yes (" d " > " q ")"; else print "done after the quit line: NO (quit " q ", done " d ")" }' "$LOG"
echo "== leave as found =="; pgrep -fl 'sleep 20' | head -2; rm -rf "$S"; echo "fixture removed; app running: $(running)"
