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
#
#   observe   AT-03.3: the engine's observe, through the real hs, reports every
#             screen with UUID, name, frame and position, every space with its
#             ordinal and type, every named window with bundle id, title and
#             frame, the two settings and every Dock binding. Given the spike's
#             module, it runs the spike's observe straight after and says where
#             the two agree.
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
check("auto-rearrange (mru-spaces) is reported (%s)" % w.get("mru_spaces"), "mru_spaces" in w)
check("stage manager is reported (%s)" % w.get("stage_manager"), isinstance(w.get("stage_manager"), bool))
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

case "${1:-}" in
  observe)
    shift
    observe "$@"
    ;;
  *) die "usage: $0 observe [<spike.lua>]" ;;
esac

if [[ $FAILED -gt 0 ]]; then
  echo "acceptance: $FAILED check(s) failed"
  exit 1
fi
echo "acceptance: every check passed"
