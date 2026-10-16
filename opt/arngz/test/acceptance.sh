#!/usr/bin/env bash
#
# arngz hand-run acceptance (ST0026): what only a real Hammerspoon can show.
#
# NOT RUN BY `utilz test`. Accessibility cannot be granted on a CI runner
# (design.md D12), so these checks run on hv's machine, by hand, and the
# transcript is recorded in the thread's acceptance notes as a hand run.
#
# Usage:
#   opt/arngz/test/acceptance.sh observe [<spike.lua>]
#   opt/arngz/test/acceptance.sh apply <desk>
#   opt/arngz/test/acceptance.sh launch <desk> <bundle id>
#
#   observe   AT-03.3: the engine's observe, through the real hs, reports every
#             screen with UUID, name, frame and position, every space with its
#             ordinal and type, every named window with bundle id, title and
#             frame, the two settings and every Dock binding. Given the spike's
#             module, it runs the spike's observe straight after and says where
#             the two agree.
#
#   apply     AC-05.4, after the desk's windows were scrambled by hand: diff
#             first finds something to do (the scramble is real), apply exits
#             0 with every entry placed, diff then finds nothing to do (a fresh
#             observe and plan), and a second apply moves and launches nothing
#             and reports every entry plainly placed. It TAKES THE POINTER:
#             hands off the mouse and the keyboard while it runs.
#   launch    AC-05.5, with <bundle id> named in <desk> and NOT running: apply
#             --no-launch reports it skipped and exits 1, leaving it unlaunched;
#             then apply launches and places it within the timeout, exit 0.
#             It takes the pointer too.
#
# Exit 0 if every check passed, 1 if any failed, 2 if it could not run.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE="$(cd "$HERE/../lib" && pwd)/arngz.lua"
FAILED=0

ok() { printf '  ok    %s\n' "$1"; }
bad() {
  printf '  FAIL  %s\n' "$1"
  FAILED=$((FAILED + 1))
}
die() {
  printf 'acceptance: %s\n' "$1" >&2
  exit 2
}

# One hs call under a wall clock, done when OUT appears. Stdin from /dev/null,
# because hs reads Lua from a stdin that is not a terminal and waits on one
# that stays open; and the file, not the exit, is the signal all the same.
hs_call() {
  local code="$1" out="$2" pid deadline
  hs -a -t 60 -c "$code" </dev/null >/dev/null 2>&1 &
  pid=$!
  deadline=$((SECONDS + 60))
  while [[ ! -s "$out" ]] && kill -0 "$pid" 2>/dev/null && [[ $SECONDS -lt $deadline ]]; do
    sleep 0.1
  done
  kill "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
  [[ -s "$out" ]] || die "hs wrote no $out within 60 s"
}

observe() {
  local spike="${1:-}" work
  command -v hs >/dev/null 2>&1 || die "the hs tool is not on PATH"
  command -v python3 >/dev/null 2>&1 || die "python3 is needed to read the JSON"
  work="$(mktemp -d "${TMPDIR:-/tmp}/arngz-acceptance.XXXXXX")"
  printf '{"verb":"observe","desk":null,"options":{}}\n' >"$work/request.json"

  echo "AT-03.3 -- observe on this machine, through hs"
  echo "  machine: $(scutil --get ComputerName 2>/dev/null || hostname), macOS $(sw_vers -productVersion) ($(sw_vers -buildVersion))"
  hs_call "return dofile(\"$MODULE\").run(\"$work/request.json\")" "$work/response.json"
  if [[ -n "$spike" ]]; then
    hs_call "return dofile(\"$spike\").observe(\"$work/spike.json\")" "$work/spike.json"
  fi

  local verdicts
  verdicts="$(python3 - "$work" "$spike" <<'PY'
import json, sys
work, spike = sys.argv[1], sys.argv[2]
r = json.load(open(work + "/response.json"))
w = r.get("world", {})
out = []
def check(name, cond): out.append(("ok" if cond else "FAIL") + "\t" + name)
check("the engine answered ok", r.get("status") == "ok")
print("info\tHammerspoon %s, %s" % (w.get("hammerspoon"), w.get("macos")))
screens = w.get("screens", [])
check("at least one screen", len(screens) > 0)
for s in screens:
    f = s.get("frame") or {}
    check("screen %s carries uuid, name, frame and position (%s, %s)" % (s.get("uuid"), s.get("name"), s.get("position")),
          all(s.get(k) for k in ("uuid", "name", "position")) and all(k in f for k in "xywh"))
    for sp in s.get("spaces", []):
        check("  space %s on %s carries its ordinal and type (%s, %s)" % (sp.get("id"), s.get("name"), sp.get("ordinal"), sp.get("type")),
              isinstance(sp.get("ordinal"), int) and sp.get("type") in ("user", "fullscreen", "tiled", "system"))
    named = [x for sp in s.get("spaces", []) for x in sp.get("windows", []) if x.get("named")]
    check("  every named window on %s carries bundle id, title and frame (%d named)" % (s.get("name"), len(named)),
          all("bundle" in x and "title" in x and all(k in (x.get("frame") or {}) for k in "xywh") for x in named))
check("separate spaces is reported (%s)" % w.get("separate_spaces"), isinstance(w.get("separate_spaces"), bool))
# D26: the raw values, absent when unset, and no verdict: pref_verdict in the
# CLI says what an unset key means.
import subprocess
for key, domain, pref in (("spans_displays", "com.apple.spaces", "spans-displays"),
                          ("mru_spaces", "com.apple.dock", "mru-spaces"),
                          ("globally_enabled", "com.apple.WindowManager", "GloballyEnabled")):
    v = w.get(key)
    d = subprocess.run(["defaults", "read", domain, pref], capture_output=True, text=True, stdin=subprocess.DEVNULL)
    # The same three wordings read_pref takes as unset, each naming this key
    # and this domain; any other failure is not "unset".
    unset = d.returncode != 0 and (
        ("Could not find key '%s' in domain '%s'" % (pref, domain)) in d.stderr
        or ("(%s, %s) does not exist" % (domain, pref)) in d.stderr
        or ("Domain '%s' not found" % domain) in d.stderr)
    if d.returncode == 0:
        raw = d.stdout.strip()
        try:
            same = v is not None and str(int(v)) == raw
        except (TypeError, ValueError):
            same = False
            print("info\t%s: the engine recorded %r and defaults reads %r, which do not compare as numbers" % (key, v, raw))
    else:
        same = unset and v is None
    check("%s is recorded raw, as defaults reads %s %s (%s)" % (key, domain, pref, "unset" if v is None else v), same)
check("no verdict is recorded beside them (no stage_manager)", "stage_manager" not in w)
for s in screens:
    check("screen %s's space order was read from com.apple.spaces (D22)%s" % (s.get("name"),
          ": " + s["order_error"] if s.get("order_error") else ""), not s.get("order_error"))
check("accessibility is reported (%s)" % w.get("accessibility"), isinstance(w.get("accessibility"), bool))
check("every Dock binding carries bundle and target (%d)" % len(w.get("app_bindings", [])),
      all(b.get("bundle") and b.get("target") for b in w.get("app_bindings", [])))
if spike:
    sp = json.load(open(work + "/spike.json"))
    a = {s["uuid"]: s for s in screens}
    b = {s["uuid"]: s for s in sp.get("screens", [])}
    check("agrees with the spike: the same screens", set(a) == set(b))
    for u in a:
        if u not in b: continue
        x, y = a[u], b[u]
        check("agrees with the spike on %s: name, frame and full frame" % x["name"],
              x["name"] == y["name"] and x["frame"] == y["frame"] and x["full_frame"] == y["full_frame"])
        ka = [(q["id"], q["ordinal"], q["type"], q.get("uuid"), q["active"]) for q in x["spaces"]]
        kb = [(q["id"], q["ordinal"], q["type"], q.get("uuid"), q["active"]) for q in y["spaces"]]
        check("agrees with the spike on %s: every space's id, ordinal, type, uuid and active" % x["name"], ka == kb)
        wa = {q["id"]: q.get("bundle") for t in x["spaces"] for q in t["windows"] if q.get("named")}
        wb = {q["id"]: q.get("bundle") for t in y["spaces"] for q in t["windows"] if q.get("named")}
        same = sum(1 for k in wa if wb.get(k) == wa[k])
        print("info\t  %s: %d of %d named windows the same in both (windows come and go between two reads)" % (x["name"], same, len(wa)))
    check("agrees with the spike: separate spaces and mru-spaces",
          w.get("separate_spaces") == sp.get("separate_spaces") and w.get("mru_spaces") == (sp.get("prefs") or {}).get("mru_spaces"))
    check("agrees with the spike: the same Dock bindings",
          {x["bundle"]: x["target"] for x in w.get("app_bindings", [])} == {x["bundle"]: x["target"] for x in sp.get("app_bindings", [])})
print("\n".join(out))
PY
)"
  local verdict line
  while IFS=$'\t' read -r verdict line; do
    case "$verdict" in
      ok) ok "$line" ;;
      FAIL) bad "$line" ;;
      info) printf '  info  %s\n' "$line" ;;
    esac
  done <<<"$verdicts"
  rm -rf "$work"
}

# One arngz run through the repository's own dispatcher, its output shown
# and kept, its exit code in RC.
ARNGZ="$(cd "$HERE/../../.." && pwd)/bin/utilz"
RC=0
OUT=""
arngz() {
  RC=0
  OUT="$("$ARNGZ" arngz "$@" 2>&1)" || RC=$?
  printf '%s\n' "$OUT" | sed 's/^/        /'
  printf '        (exit %d)\n' "$RC"
}

# How many lines of OUT match the extended pattern: grep -c exits 1 on a count
# of 0, which is a count; 2 or more is grep failing, which stops the run.
count_lines() {
  local n rc=0
  n="$(grep -Ec "$1" <<<"$OUT")" || rc=$?
  if [[ $rc -gt 1 ]]; then die "grep failed (exit $rc) counting report lines"; fi
  printf '%s\n' "$n"
}

apply_check() {
  local desk="${1:-}"
  [[ -n "$desk" ]] || die "usage: $0 apply <desk>"
  echo "AC-05.4 -- apply $desk after a scramble by hand (hands off: this takes the pointer)"
  arngz diff "$desk"
  if [[ $RC -eq 1 ]]; then ok "before apply, diff finds something to do (the scramble is real)"; else bad "before apply, diff finds something to do (exit $RC)"; fi
  local entries placed
  entries="$("$ARNGZ" arngz show "$desk" | yq '[.displays[].spaces[].apps[]] | length')" ||
    die "could not count $desk's entries: arngz show or yq failed"
  [[ "$entries" =~ ^[1-9][0-9]*$ ]] || die "could not count $desk's entries (read '$entries'); nothing to check against"
  arngz apply "$desk"
  if [[ $RC -eq 0 ]]; then ok "apply exits 0"; else bad "apply exits 0 (it exited $RC)"; fi
  # Counted, not only searched for: an empty report must not pass.
  placed="$(count_lines '\(displays\[[0-9]+\]\.spaces\[[0-9]+\]\.apps\[[0-9]+\]\): (moved and |launched and )?placed$')"
  if [[ "$placed" -eq "$entries" ]]; then
    ok "every entry placed ($placed of $entries)"
  else
    bad "every entry placed ($placed of $entries)"
  fi
  arngz diff "$desk"
  if [[ $RC -eq 0 ]]; then ok "diff after apply finds nothing to do (a fresh observe)"; else bad "diff after apply finds nothing to do (exit $RC)"; fi
  arngz apply "$desk"
  placed="$(count_lines '\(displays\[[0-9]+\]\.spaces\[[0-9]+\]\.apps\[[0-9]+\]\): placed$')"
  if [[ $RC -eq 0 && "$placed" -eq "$entries" ]]; then
    ok "a second apply reports every entry plainly placed, nothing moved or launched, exit 0 ($placed of $entries)"
  else
    bad "a second apply reports every entry plainly placed, nothing moved or launched, exit 0 (exit $RC, $placed of $entries)"
  fi
}

# Whether an app with this bundle id runs, through NSRunningApplication,
# which never launches it. The id travels in the environment, never into the
# script's source. Prints true or false; dies, exit 2, when it cannot tell.
app_running() {
  local said rc=0
  said="$(B="$1" osascript -l JavaScript -e "ObjC.import('AppKit');
    var b = \$.NSProcessInfo.processInfo.environment.objectForKey('B').js;
    \$.NSRunningApplication.runningApplicationsWithBundleIdentifier(b).count > 0" </dev/null 2>&1)" || rc=$?
  if [[ $rc -ne 0 || ( "$said" != true && "$said" != false ) ]]; then
    die "could not tell whether $1 is running (osascript exited $rc): $said"
  fi
  printf '%s\n' "$said"
}

launch_check() {
  local desk="${1:-}" bundle="${2:-}" running
  [[ -n "$desk" && -n "$bundle" ]] || die "usage: $0 launch <desk> <bundle id>"
  running="$(app_running "$bundle")"
  if [[ "$running" == true ]]; then
    die "$bundle is running; quit it first, then run this again"
  fi
  echo "AC-05.5 -- $bundle in $desk, not running (hands off: this takes the pointer)"
  arngz apply --no-launch "$desk"
  if [[ $RC -eq 1 ]] && grep -iF "$bundle" <<<"$OUT" | grep -q ': skipped'; then
    ok "--no-launch reports $bundle skipped, exit 1"
  else
    bad "--no-launch reports $bundle skipped, exit 1 (exit $RC)"
  fi
  running="$(app_running "$bundle")"
  if [[ "$running" == false ]]; then ok "--no-launch left $bundle unlaunched"; else bad "--no-launch left $bundle unlaunched"; fi
  arngz apply "$desk"
  if [[ $RC -eq 0 ]] && grep -iF "$bundle" <<<"$OUT" | grep -q 'launched and placed'; then
    ok "apply launches and places $bundle, exit 0"
  else
    bad "apply launches and places $bundle, exit 0 (exit $RC)"
  fi
}

case "${1:-}" in
  observe)
    shift
    observe "$@"
    ;;
  apply)
    shift
    apply_check "$@"
    ;;
  launch)
    shift
    launch_check "$@"
    ;;
  *) die "usage: $0 observe [<spike.lua>] | apply <desk> | launch <desk> <bundle id>" ;;
esac

if [[ $FAILED -gt 0 ]]; then
  echo "acceptance: $FAILED check(s) failed"
  exit 1
fi
echo "acceptance: every check passed"
