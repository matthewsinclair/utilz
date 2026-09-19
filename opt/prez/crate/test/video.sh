#!/usr/bin/env bash
# ST0021's black-box proof that a video is faithful to its reel.
#
# `showreel video` builds a reel exactly as `build` does, plays the built HTML's
# own player in headless Chrome on a clock it controls, and encodes the frames
# with ffmpeg (design.md). This suite drives the verb end to end, on a fixture
# it generates, so nothing binary is committed:
#
#   a crawl; a 6000x4000 photo arriving by cut, so its first frame has nothing
#   to blend with; a solid-colour picture fading in, over the stage's own
#   ground, because the photo before it leaves by cut; then three gridded
#   pictures by wipe, dissolve and push. Six slides at the 2500 ms dwell floor
#   with a 1200 ms ease, recorded at --fps 10: 150 frames.
#
# EVERY EXPECTED VALUE COMES FROM THE PLAYER'S CSS AND THE DWELL SCHEDULE, NEVER
# FROM A RECORDING (vc's note 3), and the tolerances are design.md's, fixed
# before the first green: 0.5 ms of phase, and 6/255 per channel of colour.
#
# THE TOOLS ARE NAMED, AND A MISSING ONE IS UNCHECKED, NEVER N/A. n/a is gated on
# the platform, never on a missing tool (restart.md): a leg without Chrome or
# ffmpeg has proved nothing, and --strict says so.
#
# usage: video.sh [--strict] [AT...]

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRATE="$(dirname "$HERE")"
REPO="$(cd "$CRATE" && git rev-parse --show-toplevel)"
TARGET="${CARGO_TARGET_DIR:-$CRATE/target}"
BIN="$TARGET/release/prez" # chrome() asks it which browser the one finder resolves
SHOWREEL="$TARGET/release/showreel"
SHIM="$REPO/opt/prez/prez"
PLAYER="$CRATE/crates/showreel/player.html"
THEME_CSS="$CRATE/crates/showreel/themes/default/theme.css"

FPS=10            # 100 ms a frame
SLIDES=6          # the fixture's, below
DWELL=2500        # every slide's dwell: the floor
EASE=1200         # every slide's ease
PHASE=0.5         # ms a frame may sit off its grid time: the clock's rounding
TOL=6             # per channel, of 255
FADE_RGB="192 32 32"  # the fade slide's picture, 0xC02020
PHOTO_WH="1920x1280"  # the 6000x4000 photo, as build fits it to the 1920 target

WORK="$(mktemp -d "${TMPDIR:-/tmp}/showreel-video-at.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

# THIS RUN'S OWN NAME, AND THE ONLY SAFE KEY FOR A PROCESS MATCHER (issue 0030):
# every recording's TMPDIR, and so Chrome's profile, lives under it.
RUN_NAME="${WORK##*/}"

# THE HARNESS IS SHARED (issue 0040): see acceptance.sh for why a harness that
# is missing, or that does not load, stops the suite.
if [ ! -f "$HERE/lib/harness.sh" ]; then
  printf '%s: the shared harness is missing: %s\n' "${0##*/}" "$HERE/lib/harness.sh" >&2
  exit 1
fi
# shellcheck source=SCRIPTDIR/lib/harness.sh
. "$HERE/lib/harness.sh" || {
  printf '%s: the shared harness did not load: %s\n' "${0##*/}" "$HERE/lib/harness.sh" >&2
  exit 1
}

# ---------------------------------------------------------------- helpers

# The mean colour of an image, or of a crop=w:h:x:y region of it, as "R G B".
# ffmpeg averages 10x10 blocks by area and awk averages those, so the rounding
# happens once, at the end.
mean_of() {
  local vf="scale=iw/10:ih/10:flags=area"
  [ -n "${2:-}" ] && vf="crop=$2,$vf"
  "$FFMPEG" -loglevel error -i "$1" -vf "$vf" -f rawvideo -pix_fmt rgb24 - 2>/dev/null |
    od -An -v -tu1 |
    awk '{ for (i = 1; i <= NF; i++) { s[n % 3] += $i; n++ } }
         END { if (n == 0) { print "none"; exit }
               p = n / 3; printf "%d %d %d\n", s[0] / p + .5, s[1] / p + .5, s[2] / p + .5 }'
}

# The largest per-channel difference between two "R G B" colours.
worst_channel() {
  awk -v a="$1" -v b="$2" 'BEGIN { if (split(a, x, " ") != 3 || split(b, y, " ") != 3) { print 999; exit }
    w = 0; for (k = 1; k <= 3; k++) { d = x[k] - y[k]; if (d < 0) d = -d; if (d > w) w = d }
    printf "%.1f\n", w }'
}

# Passes when two colours are within TOL on every channel.
near() {
  local w
  w=$(worst_channel "$2" "$3")
  if awk -v w="$w" -v t="$TOL" 'BEGIN { exit !(w <= t) }'; then ok "$1: $2 against $3 (worst channel $w)"
  else bad "$1: $2 against $3 (worst channel $w, over $TOL)"; fi
}

# The player's fade, t ms into a fade lasting span ms: the picture's colour
# times CSS ease-in's progress, over the stage's ground for the rest. ease-in is
# cubic-bezier(.42, 0, 1, 1), solved for its x by bisection.
fade_at() {
  awk -v t="$1" -v span="$2" -v fg="$3" -v bg="$4" '
    function bez(s, a, b) { return 3 * (1 - s) * (1 - s) * s * a + 3 * (1 - s) * s * s * b + s * s * s }
    function easein(p,   lo, hi, mid, k) {
      if (p <= 0) return 0
      if (p >= 1) return 1
      lo = 0; hi = 1
      for (k = 0; k < 60; k++) { mid = (lo + hi) / 2; if (bez(mid, 0.42, 1) < p) lo = mid; else hi = mid }
      return bez((lo + hi) / 2, 0, 1)
    }
    BEGIN { y = easein(t / span); split(fg, c, " "); split(bg, g, " ")
      printf "%.1f %.1f %.1f\n", c[1] * y + g[1] * (1 - y), c[2] * y + g[2] * (1 - y), c[3] * y + g[3] * (1 - y) }'
}

# How many processes carry TEXT in their command line. ps is read from a file,
# so the grep reading it is not among them, and TEXT is always a path under
# $WORK, which mktemp made this run's alone (issue 0030).
procs_carrying() {
  ps -eo args= >"$WORK/ps.txt" 2>/dev/null
  grep -c -F -- "$1" "$WORK/ps.txt" || true
}

# How many entries a directory holds.
entries() { find "$1" -mindepth 1 -maxdepth 1 2>/dev/null | grep -c ''; }

# Waits up to $2 seconds for no process to carry $1 and for directory $3 to be
# empty, and says how long it took, or "never".
settles() {
  local waited=0
  while [ "$waited" -le "$2" ]; do
    if [ "$(procs_carrying "$1")" = 0 ] && [ "$(entries "$3")" = 0 ]; then
      echo "$waited"
      return 0
    fi
    sleep 1
    waited=$((waited + 1))
  done
  echo never
  return 1
}

# Waits up to $2 seconds for background pid $1 to exit, and returns its exit
# status. Past the bound it is killed and the status is 124, as timeout(1)
# reports, so a hang fails its AT rather than the whole suite.
exits_within() {
  local waited=0
  while kill -0 "$1" 2>/dev/null && [ "$waited" -lt $(($2 * 10)) ]; do
    sleep 0.1
    waited=$((waited + 1))
  done
  if kill -0 "$1" 2>/dev/null; then
    kill -KILL "$1" 2>/dev/null
    { wait "$1"; } 2>/dev/null
    return 124
  fi
  { wait "$1"; } 2>/dev/null
}

# Starts a recording in the background with job control, so it gets SIGINT's
# default action (a script's background job ignores SIGINT otherwise), and
# waits up to two minutes for its frame 5. Sets PID. Fails when frame 5 never
# comes, having killed the recording.
started() {
  local name="$1" waited=0
  shift
  run_argv "$name" "$@" --frames "$WORK/f-$name"
  set -m
  "${RUN[@]}" >"$WORK/$name.out" 2>"$WORK/$name.err" &
  PID=$!
  set +m
  while [ ! -f "$WORK/f-$name/f00005.png" ] && kill -0 "$PID" 2>/dev/null && [ "$waited" -lt 1200 ]; do
    sleep 0.1
    waited=$((waited + 1))
  done
  [ -f "$WORK/f-$name/f00005.png" ] && return 0
  kill -KILL "$PID" 2>/dev/null
  { wait "$PID"; } 2>/dev/null
  return 1
}

# The command line every recording shares, into the array RUN: the fixture,
# this suite's browser and FPS, and a TMPDIR of the run's own under $WORK, so
# AT27 can see what a run leaves behind. `env` execs the verb, so a pid taken
# from RUN is showreel's own, and it is named by its path because two ATs run
# RUN under a PATH of their own making.
run_argv() {
  local name="$1"
  shift
  mkdir -p "$WORK/tmp-$name"
  RUN=(/usr/bin/env "TMPDIR=$WORK/tmp-$name/" "$SHOWREEL" video "$REEL" --browser "$CHROME" --fps "$FPS" "$@")
}

# Runs a command while stopping and continuing it every 20 ms, so it records at
# a different real-time pace from an unhindered run. It is this suite's own
# child, signalled by pid, and the number of pauses is kept as the evidence.
paced() {
  local out="$1" err="$2" pauses=0 pid
  shift 2
  "$@" >"$out" 2>"$err" &
  pid=$!
  while kill -0 "$pid" 2>/dev/null; do
    kill -STOP "$pid" 2>/dev/null && pauses=$((pauses + 1))
    sleep 0.02
    kill -CONT "$pid" 2>/dev/null
    sleep 0.02
  done
  echo "$pauses" >"$WORK/pauses"
  wait "$pid"
}

# Each recording is made once, by the first AT that asks for it, so any AT runs
# on its own (video.sh AT24) and a full run records each only once. Returns the
# recording's exit status.
ensure() {
  local name="$1"
  if [ ! -f "$WORK/$name.rc" ]; then
    case "$name" in
      one)
        run_argv one --frames "$WORK/f-one"
        "${RUN[@]}" >"$WORK/one.out" 2>"$WORK/one.err"
        ;;
      two)
        run_argv two -o "$WORK/two.mp4" --frames "$WORK/f-two"
        paced "$WORK/two.out" "$WORK/two.err" "${RUN[@]}"
        ;;
      three)
        # A stale partial from an interrupted run, which this run must remove.
        printf 'an interrupted encode\n' >"$WORK/three.mov.partial"
        run_argv three -o "$WORK/three.mov"
        "${RUN[@]}" >"$WORK/three.out" 2>"$WORK/three.err"
        ;;
      fail)
        # An ffmpeg that writes the start of its output, reads a little of the
        # frames, and fails, as a full disk or a bad build does.
        mkdir -p "$WORK/fakebin"
        cat >"$WORK/fakebin/ffmpeg" <<'FAKE'
#!/bin/sh
for last in "$@"; do :; done
printf 'not a video' >"$last"
head -c 1000 >/dev/null
exit 1
FAKE
        chmod +x "$WORK/fakebin/ffmpeg"
        run_argv fail -o "$WORK/fail.mp4" --frames "$WORK/f-fail"
        PATH="$WORK/fakebin:$PATH" "${RUN[@]}" >"$WORK/fail.out" 2>"$WORK/fail.err"
        ;;
    esac
    echo $? >"$WORK/$name.rc"
  fi
  return "$(cat "$WORK/$name.rc")"
}

# Passes when a failed recording kept at least one frame under $1: the failure
# came with Chrome up and frames flowing, which a refusal before the recording
# would satisfy every other check of AT27(b) and AT31 without.
mid_recording() {
  local kept
  kept=$(find "$1" -name '*.png' 2>/dev/null | grep -c '')
  if [ "$kept" -ge 1 ]; then ok "the failure came mid-recording: $kept frame(s) were captured first"
  else bad "no frame was captured, so the failure came before the recording, not under it"; fi
}

# The first line a recording said on stderr, its refusal, for a failure message.
said() { head -1 "$WORK/$1.err" 2>/dev/null; }

# Inside an AT: true when every tool is here. When one is missing the AT is
# UNCHECKED, which --strict counts: never n/a, because a missing tool is not a
# platform that cannot run this.
tools_here() {
  [ -z "$MISSING" ] && return 0
  unchecked "$MISSING not found, so nothing was recorded"
  return 1
}

# ---------------------------------------------------------------- the binaries

# Built here, because this suite is run on its own as often as by the driver,
# and a stale showreel would test yesterday's verb. --workspace, because the
# root package is prez alone, and chrome() asks prez which browser to use.
if ! cargo build --release --workspace --manifest-path "$CRATE/Cargo.toml" >"$WORK/build.log" 2>&1; then
  printf '%s: the release build failed:\n' "${0##*/}" >&2
  tail -20 "$WORK/build.log" >&2
  exit 1
fi

# ---------------------------------------------------------------- the tools

MISSING=""
CHROME="$(chrome)" || {
  CHROME=""
  MISSING="Chrome"
}
FFMPEG="$(command -v ffmpeg || true)"
FFPROBE="$(command -v ffprobe || true)"
[ -n "$FFMPEG" ] || MISSING="${MISSING:+$MISSING, }ffmpeg"
[ -n "$FFPROBE" ] || MISSING="${MISSING:+$MISSING, }ffprobe"
if [ -n "$FFMPEG" ]; then
  printf 'note: ffmpeg resolved to %s (%s)\n' "$FFMPEG" "$("$FFMPEG" -version 2>/dev/null | head -1)" >&2
fi

# ---------------------------------------------------------------- the fixture

REEL="$WORK/reel"

# The pictures: a 6000x4000 photo of one colour, a solid picture for the fade,
# and three gridded ones, so that every moving slide moves visibly.
make_pictures() {
  local pair
  mkdir -p "$REEL/art/photo" "$REEL/art/fade" "$REEL/art/wipe" "$REEL/art/dissolve" "$REEL/art/push"
  "$FFMPEG" -loglevel error -f lavfi -i "color=c=0x806040:s=6000x4000" -frames:v 1 -q:v 2 "$REEL/art/photo/1.jpg" || return 1
  "$FFMPEG" -loglevel error -f lavfi -i "color=c=0xC02020:s=1920x1080" -frames:v 1 "$REEL/art/fade/1.png" || return 1
  for pair in wipe:0x20A040 dissolve:0x2040C0 push:0xC0A020; do
    "$FFMPEG" -loglevel error -f lavfi \
      -i "color=c=${pair#*:}:s=1920x1080,drawgrid=width=120:height=120:thickness=6:color=white" \
      -frames:v 1 "$REEL/art/${pair%%:*}/1.png" || return 1
  done
}

if [ -n "$FFMPEG" ]; then
  if ! make_pictures >"$WORK/fixture.log" 2>&1; then
    printf '%s: ffmpeg could not generate the fixture:\n' "${0##*/}" >&2
    cat "$WORK/fixture.log" >&2
    exit 1
  fi
  cat >"$REEL/showreel.yaml" <<'YAML'
showreel: {version: 1}
artist: {handle: videotest, name: Video Test}
session: {venue: The Hall, city: Derby, date: 19th September, iso: 2026-09-19, action: Come and say hello}
theme: default
target: 1920
loop: false
segments:
  - {id: opening, type: crawl, source: session, dwell: 2500ms, ease: 1200ms, transition: fade}
  - {id: photo, from: art/photo, fit: cover, motion: none, dwell: 2500ms, ease: 1200ms, transition: cut}
  - {id: fade, from: art/fade, fit: cover, motion: kenburns, dwell: 2500ms, ease: 1200ms, transition: fade}
  - {id: wipe, from: art/wipe, fit: cover, motion: kenburns-out, dwell: 2500ms, ease: 1200ms, transition: wipe}
  - {id: dissolve, from: art/dissolve, fit: cover, motion: drift-l, dwell: 2500ms, ease: 1200ms, transition: dissolve}
  - {id: push, from: art/push, fit: cover, motion: drift-r, dwell: 2500ms, ease: 1200ms, transition: push}
YAML
fi

FRAMES=$((SLIDES * DWELL * FPS / 1000))

# ---------------------------------------------------------------- AT23 -- AC-02.1

if want AT23; then
  start AT23 "determinism: two recordings at two real-time paces write the same PNG bytes"
  if tools_here; then
    if ensure one && ensure two; then
      check "frames in the first recording" "$(find "$WORK/f-one" -name '*.png' | grep -c '')" "$FRAMES"
      check "frames in the paced recording" "$(find "$WORK/f-two" -name '*.png' | grep -c '')" "$FRAMES"
      pauses=$(cat "$WORK/pauses" 2>/dev/null || echo 0)
      if [ "$pauses" -gt 10 ]; then ok "the second recording was paused $pauses times, so its real-time pace differed"
      else bad "the second recording was paused only $pauses times, so the paces may not have differed"; fi
      differ=0
      for f in "$WORK/f-one"/*.png; do
        cmp -s "$f" "$WORK/f-two/${f##*/}" || differ=$((differ + 1))
      done
      check "frames whose bytes differ between the two paces" "$differ" "0"
    else
      bad "a recording failed: $(said one) / $(said two)"
    fi
  fi
  finish
fi

# ---------------------------------------------------------------- AT24 -- AC-02.2

if want AT24; then
  start AT24 "phase: frame i is at t0 + i x 1000/fps, on the slide the dwell schedule puts there"
  if tools_here; then
    if ensure one; then
      tsv="$WORK/f-one/frames.tsv"
      t0=$(sed -n 's/^#.*t0_ms=\([-0-9.]*\).*/\1/p' "$tsv" 2>/dev/null | head -1)
      if [ -z "$t0" ]; then
        bad "frames.tsv names no t0_ms, so there is no grid to hold the frames to"
      else
        ok "the player's t0 is $t0 ms, as frames.tsv records it"
        held=$(awk -F'\t' -v t0="$t0" -v fps="$FPS" -v dwell="$DWELL" -v tol="$PHASE" '
          /^#/ || $1 == "frame" { next }
          { rows++; i = $1 + 0; at = t0 + i * 1000 / fps
            if (i >= 1) { d = $2 - at; if (d < 0) d = -d; if (d > tol) off++; if (d > worst) worst = d }
            if ($3 + 0 != int((at - t0) / dwell)) wrong++ }
          END { printf "%d %d %d %.2f\n", rows, off, wrong, worst }' "$tsv")
        read -r rows off wrong worst <<<"$held"
        check "frames in frames.tsv" "$rows" "$FRAMES"
        check "frames from 1 on more than $PHASE ms off t0 + i x 100 (worst ${worst} ms)" "$off" "0"
        check "frames on a slide other than the dwell schedule's" "$wrong" "0"
      fi
      shaped "the report says how late frame 0 was taken" 'frame 0.* [0-9.]+ ms' "$WORK/one.out"
    else
      bad "the recording failed: $(said one)"
    fi
  fi
  finish
fi

# ---------------------------------------------------------------- AT25 -- AC-02.3

if want AT25; then
  start AT25 "curve: mid-fade frames sit on the player's own ease-in, over the stage's ground"
  if tools_here; then
    # The expectation is derived from these two lines of CSS, so if either
    # changes, the AT says so rather than measuring against a stale curve.
    fade_rule='.t-fade{transition:opacity calc(var(--ease)*.5) ease-in}'
    bg_hex=$(sed -n 's/.*--bg:#\([0-9a-fA-F]\{6\}\).*/\1/p' "$THEME_CSS" | head -1)
    if ! grep -qF -- "$fade_rule" "$PLAYER"; then
      bad "player.html no longer carries '$fade_rule', so the curve must be re-derived"
    elif [ -z "$bg_hex" ]; then
      bad "the default theme no longer sets --bg as #rrggbb, so the ground must be re-derived"
    elif ! ensure one; then
      bad "the recording failed: $(said one)"
    else
      bg_rgb=$(printf '%d %d %d' "0x${bg_hex:0:2}" "0x${bg_hex:2:2}" "0x${bg_hex:4:2}")
      span=$((EASE / 2))
      ok "the fade is half the ease, ${span} ms of ease-in, over the ground #$bg_hex ($bg_rgb)"
      # The fade slide is the third: it starts at 2 x DWELL after t0.
      first=$((2 * DWELL * FPS / 1000))
      i=$((first + 1))
      while [ $((i - first)) -lt $((span * FPS / 1000)) ]; do
        t=$(((i - first) * 1000 / FPS))
        frame=$(printf '%s/f-one/f%05d.png' "$WORK" "$i")
        near "frame $i, $t ms into the fade" "$(mean_of "$frame" 960:540:480:270)" "$(fade_at "$t" "$span" "$FADE_RGB" "$bg_rgb")"
        i=$((i + 1))
      done
    fi
  fi
  finish
fi

# ---------------------------------------------------------------- AT26 -- AC-02.4

if want AT26; then
  start AT26 "the photo: the first frame of a slide arriving by cut is the whole picture, decoded"
  if tools_here; then
    if ensure one; then
      html=$(find "$REEL/_out" -name '*.html' | head -1)
      photo=""
      n=0
      while IFS= read -r uri; do
        n=$((n + 1))
        printf '%s' "${uri#*;base64,}" | base64 -d >"$WORK/embedded-$n.jpg" 2>/dev/null
        wh=$("$FFPROBE" -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0:s=x "$WORK/embedded-$n.jpg" 2>/dev/null)
        [ "$wh" = "$PHOTO_WH" ] && photo="$WORK/embedded-$n.jpg"
      done < <(grep -o 'data:image/jpeg;base64,[A-Za-z0-9+/=]*' "$html" 2>/dev/null)
      if [ -z "$photo" ]; then
        bad "no $PHOTO_WH JPEG among the $n the build embedded, so the photo's colour is unknown"
      else
        ok "the photo as built is $PHOTO_WH, one of $n embedded pictures"
        # The photo is the second slide: its first frame is at DWELL after t0.
        first=$(printf '%s/f-one/f%05d.png' "$WORK" $((DWELL * FPS / 1000)))
        near "the photo's first frame, against the photo" "$(mean_of "$first")" "$(mean_of "$photo")"
      fi
    else
      bad "the recording failed: $(said one)"
    fi
  fi
  finish
fi

# ---------------------------------------------------------------- AT27 -- AC-02.5

if want AT27; then
  start AT27 "shutdown: nothing left behind on any exit path, nothing matched by name"
  if tools_here; then
    # (a) A recording that worked: nothing left, and nothing of Chrome's said.
    if ensure one; then
      check "processes still carrying the first run's TMPDIR" "$(procs_carrying "$WORK/tmp-one")" "0"
      check "files the first run left in its TMPDIR" "$(entries "$WORK/tmp-one")" "0"
      check "lines of Chrome's own output on a recording that worked" \
        "$(grep -cE '^\[[0-9]+:[0-9]+:|Chrome said' "$WORK/one.err" || true)" "0"
    else
      bad "the recording failed: $(said one)"
    fi

    # (b) A recording that failed: the same, on the refusal path. The frames it
    # kept show the failure came mid-recording, with Chrome up, and not from a
    # refusal before anything started (vc's review of the red suite).
    ensure fail
    mid_recording "$WORK/f-fail"
    if [ "$(cat "$WORK/fail.rc")" -ne 0 ]; then
      waited=$(settles "$WORK/tmp-fail" 20 "$WORK/tmp-fail")
      if [ "$waited" = never ]; then bad "a failed recording left processes or files after 20 s"
      else ok "a failed recording left no process and no file (settled in ${waited} s)"; fi
    else
      bad "a recording through a failing ffmpeg exited 0"
    fi

    # (c) An interrupt, which runs no Rust at all: the wrapper must end Chrome
    # itself (design.md, Shutdown).
    if started int -o "$WORK/int.mp4"; then
      kill -INT "$PID" 2>/dev/null
      exits_within "$PID" 60
      check "the interrupted verb's exit (128 + SIGINT)" "$?" "130"
      waited=$(settles "$WORK/tmp-int" 20 "$WORK/tmp-int")
      if [ "$waited" = never ]; then bad "an interrupt left Chrome running or its TMPDIR full after 20 s"
      else ok "an interrupt left no process and an empty TMPDIR (settled in ${waited} s)"; fi
      unwritten "an interrupt leaves only a .partial, never the finished name" "$WORK/int.mp4"
    else
      bad "the recording to interrupt never captured frame 5: $(said int)"
    fi

    # (d) A stall, end to end, which AT28's pipe cannot show (AC-02.6 as well
    # as AC-02.5). Chrome's group is stopped mid-recording, so no reply comes:
    # the refusal must name its step and leave nothing behind. The group is
    # found by this run's own TMPDIR, never by a name (issue 0030).
    if started stall -o "$WORK/stall.mp4"; then
      ps -eo pgid=,args= >"$WORK/ps.txt" 2>/dev/null
      group=$(grep -F -- "$WORK/tmp-stall" "$WORK/ps.txt" | awk '{ print $1 }' | sort -u)
      if [ "$(printf '%s\n' "$group" | grep -c '[0-9]')" -ne 1 ]; then
        bad "wanted one process group carrying the stalled run's TMPDIR, found: $(printf '%s ' "$group")"
        kill -KILL "$PID" 2>/dev/null
        { wait "$PID"; } 2>/dev/null
      else
        kill -STOP -- -"$group" 2>/dev/null
        exits_within "$PID" 120
        rc=$?
        if [ "$rc" -ne 0 ] && [ "$rc" -ne 124 ] &&
          grep -q 'no reply from Chrome in [0-9.]* s, during frame [0-9]*: ' "$WORK/stall.err"; then
          ok "a stalled Chrome is refused naming its step: $(head -1 "$WORK/stall.err" | sed 's/^showreel: //')"
        else
          bad "a stalled Chrome: exit $rc, $(head -1 "$WORK/stall.err")"
        fi
        waited=$(settles "$WORK/tmp-stall" 20 "$WORK/tmp-stall")
        if [ "$waited" = never ]; then
          bad "a stall left Chrome's group or its TMPDIR behind after 20 s"
          kill -KILL -- -"$group" 2>/dev/null
        else
          ok "a stall left no process and an empty TMPDIR (settled in ${waited} s)"
        fi
      fi
    else
      bad "the recording to stall never captured frame 5: $(said stall)"
    fi

    # And the whole run: nothing of it is still running.
    check "processes carrying this run's name ($RUN_NAME)" "$(procs_carrying "$RUN_NAME")" "0"
  fi
  finish
fi

# ---------------------------------------------------------------- AT29 -- AC-03.1

if want AT29; then
  start AT29 "the slot: the video lands beside its HTML in the next _out/ slot, and -o writes only the video"
  if tools_here; then
    if ensure one; then
      html=$(find "$REEL/_out" -name '*.html' | head -1)
      check "HTML files in _out/" "$(find "$REEL/_out" -name '*.html' | grep -c '')" "1"
      if [ -n "$html" ] && [ -f "${html%.html}.mp4" ]; then ok "the video is ${html##*/} with .html swapped for .mp4"
      else bad "no ${html##*/} with .html swapped for .mp4 in _out/: $(find "$REEL/_out" -mindepth 1 -maxdepth 1 -exec basename {} \; | tr '\n' ' ')"; fi
      check "entries in _out/ after one recording" "$(entries "$REEL/_out")" "2"
    else
      bad "the recording failed: $(said one)"
    fi
    if ensure two; then
      if [ -s "$WORK/two.mp4" ]; then ok "-o wrote the video where it was named"; else bad "-o wrote nothing at $WORK/two.mp4"; fi
      check "entries in _out/ after a recording with -o" "$(entries "$REEL/_out")" "2"
    else
      bad "the recording with -o failed: $(said two)"
    fi
  fi
  finish
fi

# ---------------------------------------------------------------- AT30 -- AC-03.2

if want AT30; then
  start AT30 "the file: floor(D x fps) frames of H.264 at the target's 16:9, silent, and .mov in QuickTime"
  if tools_here; then
    if ensure one; then
      video=$(find "$REEL/_out" -name '*.mp4' | head -1)
      probe() { "$FFPROBE" -v error -select_streams v:0 -show_entries "stream=$1" -of default=nw=1:nk=1 "$2" 2>/dev/null; }
      check "codec" "$(probe codec_name "$video")" "h264"
      check "size" "$(probe width "$video")x$(probe height "$video")" "1920x1080"
      check "frames by ffprobe, floor(D x fps) for D = $SLIDES x $DWELL ms" \
        "$("$FFPROBE" -v error -count_frames -select_streams v:0 -show_entries stream=nb_read_frames -of default=nw=1:nk=1 "$video" 2>/dev/null)" "$FRAMES"
      check "audio streams" "$("$FFPROBE" -v error -select_streams a -show_entries stream=index -of csv=p=0 "$video" 2>/dev/null | grep -c '')" "0"
      check "the .mp4's brand" "$("$FFPROBE" -v error -show_entries format_tags=major_brand -of default=nw=1:nk=1 "$video" 2>/dev/null)" "isom"
    else
      bad "the recording failed: $(said one)"
    fi
    if ensure three; then
      check "the .mov's codec" "$("$FFPROBE" -v error -select_streams v:0 -show_entries stream=codec_name -of default=nw=1:nk=1 "$WORK/three.mov" 2>/dev/null)" "h264"
      check "the .mov's brand, QuickTime" "$("$FFPROBE" -v error -show_entries format_tags=major_brand -of default=nw=1:nk=1 "$WORK/three.mov" 2>/dev/null | tr -d ' ')" "qt"
    else
      bad "the .mov recording failed: $(said three)"
    fi
    for fps in 0 61 x; do
      if "$SHOWREEL" video "$REEL" --fps "$fps" >/dev/null 2>"$WORK/fps.err"; then
        bad "--fps $fps was accepted"
      elif grep -q -- '--fps' "$WORK/fps.err"; then ok "--fps $fps is refused by name"
      else bad "--fps $fps was refused without naming --fps: $(head -1 "$WORK/fps.err")"; fi
    done
  fi
  finish
fi

# ---------------------------------------------------------------- AT31 -- AC-03.3

if want AT31; then
  start AT31 "no partial file ever looks finished"
  if tools_here; then
    ensure fail
    mid_recording "$WORK/f-fail"
    if [ "$(cat "$WORK/fail.rc")" -ne 0 ]; then ok "a failing ffmpeg fails the verb (exit $(cat "$WORK/fail.rc"))"
    else bad "a failing ffmpeg left the verb exiting 0"; fi
    present "and the refusal names ffmpeg" "ffmpeg" "$WORK/fail.err"
    unwritten "a failing ffmpeg leaves no video" "$WORK/fail.mp4"
    unwritten "and no partial" "$WORK/fail.mp4.partial"
    if ensure three; then
      if [ -s "$WORK/three.mov" ]; then ok "the next run to the same name finished its video"; else bad "the next run wrote no video"; fi
      unwritten "and removed the stale partial" "$WORK/three.mov.partial"
    else
      bad "the run after a stale partial failed: $(said three)"
    fi
  fi
  finish
fi

# ---------------------------------------------------------------- AT32 -- AC-03.4

if want AT32; then
  start AT32 "a missing ffmpeg or Chrome is refused by name, before any frame, by the one finder"
  if tools_here; then
    mkdir -p "$WORK/nobin"
    run_argv noff -o "$WORK/noff.mp4" --frames "$WORK/f-noff"
    PATH="$WORK/nobin" "${RUN[@]}" >/dev/null 2>"$WORK/noff.err"
    rc=$?
    if [ "$rc" -ne 0 ] && grep -q 'ffmpeg' "$WORK/noff.err" && grep -qi 'install' "$WORK/noff.err"; then
      ok "no ffmpeg on PATH is refused naming ffmpeg, with its install line (exit $rc)"
    else
      bad "no ffmpeg on PATH: exit $rc, $(head -1 "$WORK/noff.err")"
    fi
    check "frames captured before that refusal" "$(find "$WORK/f-noff" -name '*.png' 2>/dev/null | grep -c '')" "0"

    "$SHOWREEL" video "$REEL" --browser /nonexistent/chrome --fps "$FPS" -o "$WORK/nochrome.mp4" --frames "$WORK/f-nochrome" \
      >/dev/null 2>"$WORK/nochrome.err"
    rc=$?
    check "a --browser that does not exist exits" "$rc" "2"
    present "with artifact::browser::find's own refusal" "--browser '/nonexistent/chrome' is not an executable file" "$WORK/nochrome.err"
    present "and its remedy" "give the full path to a Chrome, Chromium, Edge or Brave binary" "$WORK/nochrome.err"
    check "frames captured before that refusal" "$(find "$WORK/f-nochrome" -name '*.png' 2>/dev/null | grep -c '')" "0"
  fi
  # The one finder: showreel carries no list and no finder of its own. Read,
  # not run, so it needs no tool.
  src="$CRATE/crates/showreel/src"
  check "APP_PATHS, PATH_NAMES or fn find( in showreel's source" \
    "$(grep -rE 'APP_PATHS|PATH_NAMES|fn find\(' "$src" | grep -c '')" "0"
  if grep -rq 'browser::find' "$src"; then ok "showreel calls artifact::browser::find"
  else bad "showreel never calls artifact::browser::find"; fi
  finish
fi

# ---------------------------------------------------------------- AT34 -- AC-03.6

if want AT34; then
  start AT34 "prez showreel video reaches showreel through the shim, as check and build do"
  "$SHIM" showreel video >/dev/null 2>"$WORK/shim.err"
  rc=$?
  check "prez showreel video with no directory exits" "$rc" "2"
  present "with showreel's own refusal" "video needs a directory" "$WORK/shim.err"
  "$SHIM" showreel video "$WORK" --fps 0 >/dev/null 2>"$WORK/shim-fps.err"
  present "and showreel's own flags reach it" "--fps" "$WORK/shim-fps.err"
  finish
fi

# ---------------------------------------------------------------------- report

printf '\n=======================================\n'
printf 'passed %d   failed %d   skipped %d\n' "$PASSED" "$FAILED" "$SKIPPED"
[ "$SKIPPED" -gt 0 ] && printf 'A SKIP is not a pass. Re-run where the missing tool exists.\n'

[ "$FAILED" -gt 0 ] && exit 1
if [ "$STRICT" -eq 1 ] && [ "$SKIPPED" -gt 0 ]; then
  printf -- '--strict: %d check(s) did not run, so this run does not pass.\n' "$SKIPPED"
  exit 1
fi
exit 0
