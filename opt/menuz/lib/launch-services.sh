# shellcheck shell=bash
#
# launch-services.sh - Menuz's Launch Services records, for menuz and for
# bin/devbin macos (issue 0106)
#
# Sourced, never run: by opt/menuz/menuz and by bin/.devbin/cmd/macos, so
# lsregister's path, how it is found, how its record list is read and how a
# drop is checked have one home. Only ~/Applications/Menuz.app stays
# registered; every Menuz.app a build, app-sign, app-notarize, app-verify or
# publish leaves under XDG state, or unpacks to prove a zip, has its record
# dropped, so the bundle id never resolves to a build product.
#
# These functions print and return; they say nothing on stderr and exit
# nothing, so each caller says a failure in its own voice. bash 3.2 safe,
# and safe under errexit: every command answers its own failure.

# Menuz.app's bundle id: menuz's BUNDLE_ID and devbin macos's APP_BUNDLE_ID.
# shellcheck disable=SC2034 # read by the two scripts that source this
MENUZ_BUNDLE_ID="com.matthewsinclair.utilz.menuz"

# Launch Services' registrar, not on PATH on macOS.
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

# lsregister: an executable one on PATH first (a test's fake), then the
# system's.
ls_cmd() {
  local found
  if found="$(command -v lsregister)" && [ -x "$found" ]; then
    printf '%s\n' "$found"
  else
    printf '%s\n' "$LSREGISTER"
  fi
}

# ls_records_parse <under|id> <value>: from lsregister -dump's text on stdin,
# the paths of the records at or under the dir <value>, or whose identifier
# is <value>, one per line. A record is the lines between two rules of
# dashes; its path: line comes before its identifier: line, each path
# without its ` (0x...)` id. Exit 3 when the text holds no path: line at all:
# the real list always holds the system's own apps, so none means it was not
# read. Any other non-zero is awk's own failure.
ls_records_parse() {
  MODE="$1" VALUE="$2" awk '
    /^-----/ { p = "" }
    /^path:/ {
      seen = 1
      p = $0
      sub(/^path:[ \t]+/, "", p); sub(/ \(0x[0-9a-fA-F]+\)$/, "", p)
      if (ENVIRON["MODE"] == "under" && (p == ENVIRON["VALUE"] || index(p, ENVIRON["VALUE"] "/") == 1)) print p
    }
    /^identifier:/ {
      if (ENVIRON["MODE"] == "id" && p != "") {
        i = $0
        sub(/^identifier:[ \t]+/, "", i)
        if (i == ENVIRON["VALUE"]) print p
        p = ""
      }
    }
    END { if (!seen) exit 3 }'
}

# ls_records <under|id> <value>: ls_records_parse over lsregister -dump, read
# whole. Returns 2, printing why on one line, when the list cannot be read: a
# failed -dump, one that lists no path: line, or a search that failed.
ls_records() {
  local dump rc=0 found lrc=0
  dump="$("$(ls_cmd)" -dump 2>&1)" || rc=$?
  if [ "$rc" -ne 0 ]; then
    printf 'lsregister -dump failed (exit %s)\n' "$rc"
    return 2
  fi
  found="$(printf '%s\n' "$dump" | ls_records_parse "$1" "$2")" || lrc=$?
  case "$lrc" in
    0) ;;
    3)
      printf 'lsregister -dump listed no record at all, so the list was not read\n'
      return 2
      ;;
    *)
      printf 'the record list could not be searched (exit %s)\n' "$lrc"
      return 2
      ;;
  esac
  if [ -n "$found" ]; then printf '%s\n' "$found"; fi
}

# ls_unregister <bundle>: lsregister -u, its words in LS_ANSWER and its exit
# in LS_URC for ls_report. Globals, so a caller can put other work between
# the two. The real lsregister exits non-zero on a path it holds no record
# for, so LS_URC alone decides nothing: the record list does.
LS_ANSWER=""
LS_URC=0
ls_unregister() {
  LS_URC=0
  LS_ANSWER="$("$(ls_cmd)" -u "$1" 2>&1)" || LS_URC=$?
}

# ls_report <bundle> <dir>: after ls_unregister <bundle>, the record list
# must hold no record at or under <dir>. Prints nothing when it holds none;
# otherwise one line per record left, or one saying the list was not read,
# each naming the path and the command that drops it, and returns 1.
ls_report() {
  local bundle="$1" dir="$2" ls left rc=0 why path
  ls="$(ls_cmd)"
  left="$(ls_records under "$dir")" || rc=$?
  if [ "$rc" -ne 0 ]; then
    printf 'could not drop the Launch Services record for %s: %s, so whether it is gone is unknown; drop it with: %s -u %s\n' "$bundle" "$left" "$ls" "$bundle"
    return 1
  fi
  [ -n "$left" ] || return 0
  if [ "$LS_URC" -ne 0 ]; then
    why="lsregister -u said: ${LS_ANSWER:-nothing} (exit $LS_URC)"
  else
    why="lsregister -u exited 0 and the record is still listed"
  fi
  while IFS= read -r path; do
    printf 'could not drop the Launch Services record for %s: %s; drop it with: %s -u %s\n' "$path" "$why" "$ls" "$path"
  done <<<"$left"
  return 1
}

# ls_drop <bundle>: its record dropped and the drop checked, the bundle
# resolved first as Launch Services lists it (pwd -P). ls_report's lines and
# status.
ls_drop() {
  local bundle
  bundle="$(cd "$1" 2>/dev/null && pwd -P)" || bundle="$1"
  ls_unregister "$bundle"
  ls_report "$bundle" "$bundle"
}

# ls_drop_under <dir>: every record at or under <dir>, resolved as Launch
# Services lists it (pwd -P), dropped and checked, each with ls_drop: doctor's
# remedy, run by menuz install and publish on the build products (issue 0115).
# Prints ls_drop's lines, or one saying the list could not be read, and
# returns 1 when a record is left or the list was not read.
ls_drop_under() {
  local dir found path said rc=0
  dir="$(cd "$1" 2>/dev/null && pwd -P)" || dir="$1"
  if ! found="$(ls_records under "$dir")"; then
    printf 'could not drop the Launch Services records under %s: %s; utilz menuz doctor names any left\n' "$dir" "$found"
    return 1
  fi
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    if ! said="$(ls_drop "$path")"; then
      printf '%s\n' "$said"
      rc=1
    fi
  done <<<"$found"
  return "$rc"
}
