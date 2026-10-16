#!/bin/bash
# ST0027 AC-03.3, the watcher's latency, run by hand on a Mac with the app
# built and hv's hands off: launches the Debug product under fixture XDG dirs
# (hv's own ~/.config/menuz is never touched), streams the watcher's OSLog
# reload lines, makes four changes three seconds apart (a save in place, an
# editor's atomic rename, a delete of MENUZ_HOME, its recreation) and times
# each reload against its change. Quits the app and removes the fixture.
# Usage: opt/menuz/test/watcher-handrun.sh <Menuz.app> [out-dir]
# The transcript's numbers go on AT-03.3's note in acceptance.md.
set -uo pipefail
APP="${1:?usage: watcher-handrun.sh <Menuz.app> [out-dir]}"; BIN="$APP/Contents/MacOS/Menuz"
[ -x "$BIN" ] || { echo "no binary at $BIN"; exit 2; }
S="${2:-${TMPDIR:-/tmp}/menuz-watcher-handrun}"; mkdir -p "$S"
FIX="$S/home"; rm -rf "$FIX"; mkdir -p "$FIX"
export XDG_CONFIG_HOME="$FIX/.config" XDG_STATE_HOME="$FIX/.local/state"
MH="$XDG_CONFIG_HOME/menuz"; mkdir -p "$MH"
EX="$(cd "$(dirname "$0")/../lib" && pwd)/example.yaml"
[ -f "$EX" ] || { echo "no example at $EX"; exit 2; }
cp "$EX" "$MH/menuz.yaml"
BID=com.matthewsinclair.utilz.menuz
now() { perl -MTime::HiRes=time -e 'printf "%.3f\n", time'; }
running() { osascript -l JavaScript -e "ObjC.import('AppKit'); \$.NSRunningApplication.runningApplicationsWithBundleIdentifier('$BID').count > 0" </dev/null 2>&1; }
[ "$(running)" = false ] || { echo "Menuz is already running; stopping, nothing touched"; exit 2; }
LOG="$S/oslog.txt"; : >"$LOG"
log stream --style compact --level info --predicate "subsystem == \"$BID\" AND category == \"watcher\"" >"$LOG" 2>&1 &
LOGPID=$!
sleep 2
echo "== launch $BIN (fixture MENUZ_HOME $MH) =="
"$BIN" </dev/null >"$S/app.txt" 2>&1 &
APPPID=$!
sleep 4
echo "running: $(running)"
echo "== 1: save in place (truncate and rewrite with one more item) =="
T1="$(now)"; { cat "$EX"; printf '  - label: Added one\n    run: true\n'; } >"$MH/menuz.yaml"
sleep 3
echo "== 2: an editor's atomic save (write beside, rename over) =="
T2="$(now)"; { cat "$EX"; printf '  - label: Added two\n    run: true\n'; } >"$MH/menuz.yaml.tmp"; mv -f "$MH/menuz.yaml.tmp" "$MH/menuz.yaml"
sleep 3
echo "== 3a: delete MENUZ_HOME =="
T3="$(now)"; rm -rf "$MH"
sleep 3
echo "== 3b: recreate MENUZ_HOME with the file =="
T4="$(now)"; mkdir -p "$MH"; cp "$EX" "$MH/menuz.yaml"
sleep 3
echo "== quit =="
osascript -e "tell application id \"$BID\" to quit" </dev/null >/dev/null 2>&1 || kill -TERM "$APPPID" 2>/dev/null
sleep 2; echo "running after quit: $(running)"
kill "$LOGPID" 2>/dev/null; wait "$LOGPID" 2>/dev/null
echo "== the app's stdout/stderr =="; sed 's/^/        /' "$S/app.txt" | head -20
echo "== watcher lines on OSLog =="; grep -E 'reload on|watcher' "$LOG" | sed 's/^/        /' | head -40
echo "== latency per change (first watcher line after each change) =="
python3 -I - "$LOG" "$T1" "$T2" "$T3" "$T4" <<'PY'
import re, sys, datetime
log, *stamps = sys.argv[1:]
names = ["save in place", "atomic rename", "delete MENUZ_HOME", "recreate MENUZ_HOME"]
rows = []
for line in open(log, encoding="utf-8", errors="replace"):
    m = re.match(r"(\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\.\d+)", line)
    if not m or "reload on" not in line:
        continue
    t = datetime.datetime.strptime(m.group(1)[:23], "%Y-%m-%d %H:%M:%S.%f").timestamp()
    rows.append((t, line.strip()))
for name, s in zip(names, stamps):
    s = float(s)
    after = [(t, l) for t, l in rows if t >= s - 0.05]
    if after:
        t, l = after[0]
        print(f"{name}: {t - s:.3f} s  ({l[:140]})")
    else:
        print(f"{name}: NO watcher line after the change")
PY
echo "== leave the machine as found =="; rm -rf "$FIX"; echo "fixture removed; app running: $(running)"
