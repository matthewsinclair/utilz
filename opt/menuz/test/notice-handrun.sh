#!/bin/bash
# ST0027 AC-06.4 (AT-06.4), the notice and the first launch, run by hand on a
# Mac with the app built and hv's hands off: the dev build under
# ~/.local/state (a bundle under /private/tmp is refused by the notification
# centre outright, D13) with fixture MENUZ_HOME and XDG_STATE_HOME, driven
# through the accessibility tree by run-handrun.lua under Hammerspoon. The
# launch logs the authorisation answer and, with no position recorded, the
# placement line; a run that fails while the app runs lands "notice posted"
# under its id; notify: always posts with the last line; a run that exits 0
# under failure posts nothing; a run that ends after the app quit posts too
# (D9). The app's defaults are hv's: the position key is read, removed for
# the launch and written back as found before the app is relaunched for hv.
# Usage: opt/menuz/test/notice-handrun.sh <Menuz.app> [out-dir]
# The transcript's lines go on AT-06.4's note in acceptance.md.
set -uo pipefail
APP="${1:?usage: notice-handrun.sh <Menuz.app> [out-dir]}"; BIN="$APP/Contents/MacOS/Menuz"
[ -x "$BIN" ] || { echo "no binary at $BIN"; exit 2; }
case "$(cd "$APP" && pwd -P)" in /private/tmp/*|/tmp/*) echo "refused: $APP is under /private/tmp, which the notification centre refuses (D13); use the dev build under ~/.local/state"; exit 2 ;; esac
D="$(cd "$(dirname "$0")" && pwd)"; L="$D/run-handrun.lua"
S="${2:-${TMPDIR:-/tmp}/menuz-notice-handrun}"; rm -rf "$S"; mkdir -p "$S"
FIX="$S/home"; mkdir -p "$FIX/.config/menuz" "$FIX/.local/state"
export XDG_CONFIG_HOME="$FIX/.config" XDG_STATE_HOME="$FIX/.local/state"
LOG="$XDG_STATE_HOME/menuz/menuz.log"
BID=com.matthewsinclair.utilz.menuz; KEY="NSStatusItem Preferred Position Item-0"
cat >"$XDG_CONFIG_HOME/menuz/menuz.yaml" <<'YAML'
notify: failure
menu:
  - label: Fail now
    run: echo "oops" >&2; exit 3
  - label: Always
    notify: always
    run: echo "the last line"
  - label: Quietly
    run: "true"
  - label: Fail later
    run: sleep 12; exit 4
YAML
drive() { hs -t 30 -c "STEP='$1'; ARG='$2'; return dofile('$L')" </dev/null 2>&1 | cut -c1-200; }
running() { osascript -l JavaScript -e "ObjC.import('AppKit'); \$.NSRunningApplication.runningApplicationsWithBundleIdentifier('$BID').count > 0" </dev/null 2>&1; }
[ "$(running)" = false ] || { echo "Menuz is already running; stopping"; exit 2; }
echo "== machine =="; sysctl -n hw.model; sw_vers -productVersion | sed 's/^/macOS /'; sw_vers -buildVersion | sed 's/^/build /'; xcodebuild -version 2>/dev/null | tr '\n' ' '; echo
echo "== the position key, as found =="
if defaults read "$BID" "$KEY" >/dev/null 2>&1; then POS="$(defaults read "$BID" "$KEY")"; echo "present: $POS; removed for this launch"; defaults delete "$BID" "$KEY"; else POS=""; echo "absent"; fi
echo "== launch at $(date -u +%H:%M:%SZ) =="; "$BIN" </dev/null >"$S/app.txt" 2>&1 & sleep 4; echo "running: $(running)"
# macOS asks with an alert at the bundle id's first request and holds the
# answer for the user (D13): the launch line is waited for, up to 90 s, and
# an unanswered alert is named, since the notices below then read "not yet
# allowed" until it is answered or the id is allowed under System Settings.
for _ in $(seq 1 90); do grep -q '^[^ ]* notifications:' "$LOG" 2>/dev/null && break; sleep 1; done
case "$(grep -h 'notifications:' "$LOG" 2>/dev/null | tail -1)" in
  *"notifications: granted"*) echo "authorised: granted" ;;
  *"is asking"*) echo "authorised: NOT YET: macOS's alert is up; answer it with Allow (hv), or the notices below read not yet allowed" ;;
  "") echo "authorised: no notifications: line in 90 s" ;;
  *) echo "authorised: $(grep -h 'notifications:' "$LOG" | tail -1 | cut -c22-)" ;;
esac
echo "== 1: Fail now (notify: failure, exit 3) =="; echo "menu: $(drive menu 'Fail now')"; sleep 4
echo "== 2: Always (notify: always, exit 0, the last line) =="; echo "menu: $(drive menu 'Always')"; sleep 4
echo "== 3: Quietly (notify: failure, exit 0: no notice) =="; echo "menu: $(drive menu 'Quietly')"; sleep 3
echo "== 4: Fail later, the app quit during it (exit 4 after the quit line) =="; echo "menu: $(drive menu 'Fail later')"; sleep 3
osascript -e "tell application id \"$BID\" to quit" </dev/null; sleep 2; echo "running after quit: $(running)"
echo "waiting 14 s for the detached run's end and notice"; sleep 14
echo "== the log =="; sed 's/^/        /' "$LOG" | cut -c1-200
echo "== checks =="
grep -n 'notifications:' "$LOG" | sed 's/^/authorisation: /'
grep -n -i 'hold Command' "$LOG" | sed 's/^/placement line: /'
grep -c 'not yet allowed' "$LOG" | sed 's/^/not yet allowed lines (0 wanted): /'
grep -c 'notice posted' "$LOG" | sed 's/^/notice posted lines (3 wanted): /'
grep -n 'notice not posted' "$LOG" | sed 's/^/not posted: /'
grep -n ' exit 0 in ' "$LOG" | sed 's/^/exit 0 lines: /'
awk '/quit/{q=NR} /\[4\] notice posted/{d=NR} END{ if (q && d && d > q) print "run 4 notice after the quit line: yes (" d " > " q ")"; else print "run 4 notice after the quit line: NO (quit " q ", notice " d ")" }' "$LOG"
echo "== leave as found =="
if [ -n "$POS" ]; then defaults write "$BID" "$KEY" -float "$POS"; echo "position key written back: $(defaults read "$BID" "$KEY")"; else echo "position key left absent"; fi
pgrep -fl 'sleep 12' | head -2; rm -rf "$S"; echo "fixture removed; app running: $(running)"
