#!/bin/bash
# ST0027 AC-05.2 (AT-05.2), the install and the login item, run by hand on a
# Mac with Xcode and hv's hands off: `utilz menuz install` builds Release,
# quits every running copy, replaces ~/Applications/Menuz.app, registers the
# bundle and launches it with an empty environment; the installed copy
# registers itself as a login item at its first launch (the service answers
# not registered, or not found for a bundle just put in place), and status
# and doctor read it enabled. The logout and login that bring the menu back
# are the user's own keypresses, confirmed by them. The install is one
# xcodebuild: book the box first. Without --install the read half runs
# alone, on whatever is installed.
# Since WP-07 (AT-07.5) it also prints the identity row, the first line of
# the installed binary's --render and of utilz menuz render, and checks its
# shape: menuz <version> (<eight-character commit>), dirty- before a dirty
# tree's commit, dev after the parentheses unless the build is a release.
# Usage: opt/menuz/test/install-handrun.sh [--install]
# The transcript's lines go on AT-05.2's and AT-07.5's notes in acceptance.md.
set -uo pipefail
cd "$(dirname "$0")/../../.." || exit 2
LOG="${XDG_STATE_HOME:-$HOME/.local/state}/menuz/menuz.log"
APP="$HOME/Applications/Menuz.app"; BIN="$APP/Contents/MacOS/Menuz"
echo "== machine =="; sysctl -n hw.model; sw_vers -productVersion | sed 's/^/macOS /'; sw_vers -buildVersion | sed 's/^/build /'; xcodebuild -version 2>/dev/null | tr '\n' ' '; echo
echo "== tree =="; git rev-parse --short HEAD | sed 's/^/HEAD /'; git status --porcelain -- native/macos/Menuz opt/menuz | sed 's/^/dirty: /'
if [ "${1:-}" = "--install" ]; then
  echo "== install at $(date -u +%H:%M:%SZ) =="
  bin/utilz menuz install </dev/null 2>&1 | sed 's/^/        /'
  echo "install exit=${PIPESTATUS[0]}"; sleep 3
fi
[ -x "$BIN" ] || { echo "nothing installed at $APP"; exit 2; }
echo "== the installed copy =="; "$BIN" --version </dev/null | sed 's/^/version: /'
echo "== the identity row (AT-07.5) =="; "$BIN" --render </dev/null 2>/dev/null | head -1 | sed 's/^/app --render first line:   /'
bin/utilz menuz render </dev/null 2>/dev/null | head -1 | sed 's/^/utilz menuz render first: /'
for k in CFBundleShortVersionString MenuzCommit MenuzSourceTree MenuzKind; do printf 'stamp %s=' "$k"; plutil -extract "$k" raw "$APP/Contents/Info.plist" 2>&1; done
codesign -dv "$APP" 2>&1 | grep -E '^(Identifier|TeamIdentifier)=' | sed 's/^/signing: /'
echo "== status =="; bin/utilz menuz status </dev/null 2>&1 | sed 's/^/        /'; echo "status exit=${PIPESTATUS[0]}"
echo "== doctor =="; bin/utilz menuz doctor </dev/null 2>&1 | sed 's/^/        /'; echo "doctor exit=${PIPESTATUS[0]}"
echo "== the login item, from the installed copy =="; "$BIN" --login-item </dev/null 2>&1 | sed 's/^/login item: /'
echo "== the log's launch lines =="; grep -h -E 'login item|registered as a login item|notifications:' "$LOG" 2>/dev/null | tail -4 | sed 's/^/        /'
echo "== checks =="
grep -c 'registered as a login item' "$LOG" 2>/dev/null | sed 's/^/registered lines: /'
bin/utilz menuz status </dev/null 2>&1 | grep -E '^login item +enabled' >/dev/null && echo "login item enabled: yes" || echo "login item enabled: NO"
pgrep -f "$BIN" >/dev/null && echo "running from $APP: yes" || echo "running from $APP: NO"
"$BIN" --render </dev/null 2>/dev/null | head -1 | grep -E '^menuz [^ ]+ \((dirty-)?[0-9a-f]{8}\)( dev)?$' >/dev/null && echo "identity row shape: yes" || echo "identity row shape: NO"
echo "the menu after a logout and login: the user's keypress, recorded on AT-05.2's note when confirmed"
