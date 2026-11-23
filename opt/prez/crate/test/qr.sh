#!/usr/bin/env bash
# qr.sh -- `showreel qr`, black-box, through the built binary (STb8e4fb6).
#
# The logic -- targets, refusals, keep and force, the stamp the build reads
# back -- is held by the unit tests in crates/showreel/src/qr.rs. This suite
# holds what only the binary shows: the verb is dispatched, its help and its
# refusals say what they should, and a run leaves the files a reel needs.
#
# Usage: test/qr.sh [--strict] [QR1 QR2 ...]

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRATE="$(dirname "$HERE")"
TARGET="${CARGO_TARGET_DIR:-$CRATE/target}"
SHOWREEL="$TARGET/release/showreel"

WORK="$(mktemp -d /tmp/sqr.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

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

# ---------------------------------------------------------------- the binary

# Built here, as video.sh builds it: this suite is run on its own as often as
# by the driver, and a stale showreel would test yesterday's verb.
if ! cargo build --release -p showreel --manifest-path "$CRATE/Cargo.toml" >"$WORK/build.log" 2>&1; then
  printf '%s: the release build failed:\n' "${0##*/}" >&2
  tail -20 "$WORK/build.log" >&2
  exit 1
fi

# ---------------------------------------------------------------- the reel

# Two socials with an address, one of them naming its own qr: path, a third
# with none, and a venue. Written again by each AT that needs it fresh.
reel() {
  rm -rf "$WORK/reel"
  mkdir -p "$WORK/reel"
  cat >"$WORK/reel/showreel.yaml" <<EOF
artist: {handle: x}
session: {venue_url: 'https://v.example/shop'}
socials:
  - {label: Web, handle: a, url: '${1:-https://a.example}'}
  - {label: Shop, handle: b, url: 'https://b.example', qr: assets/qr/front.svg}
  - {label: Mail, handle: c}
EOF
}

# The first line of a QR the verb wrote: its stamp.
stamp() { head -n 1 "$WORK/reel/assets/qr/$1"; }

# ---------------------------------------------------------------- QR1 -- AC-702cceb9.6

if want QR1; then
  start QR1 "the verb is dispatched, and its help and its refusals name it"
  reel
  "$SHOWREEL" --help >"$WORK/help.out" 2>&1
  present "the help lists the verb" "showreel qr <dir>" "$WORK/help.out"
  present "the help lists --force" "--force" "$WORK/help.out"
  "$SHOWREEL" qr >/dev/null 2>"$WORK/nodir.err"
  check "the exit status of qr with no directory" "$?" "2"
  present "the remedy names the verb's form" "remedy: showreel qr <dir>" "$WORK/nodir.err"
  "$SHOWREEL" qr "$WORK/reel" --bogus >/dev/null 2>"$WORK/bogus.err"
  check "the exit status of an unknown qr option" "$?" "2"
  present "an unknown qr option is refused as unknown" "unknown qr option '--bogus'" "$WORK/bogus.err"
  "$SHOWREEL" nosuch >/dev/null 2>"$WORK/verb.err"
  present "an unknown command's remedy names qr" "check, build, video, qr" "$WORK/verb.err"
  finish
fi

# ---------------------------------------------------------------- QR2 -- AC-702cceb9.1

if want QR2; then
  start QR2 "each address gets a QR where the build looks, stamped with that address"
  reel
  "$SHOWREEL" qr "$WORK/reel" >"$WORK/run.out" 2>"$WORK/run.err"
  check "the exit status" "$?" "0"
  present "the social's QR is reported" "showreel: wrote assets/qr/web.svg for https://a.example" "$WORK/run.out"
  present "the explicit qr: is reported" "showreel: wrote assets/qr/front.svg for https://b.example" "$WORK/run.out"
  present "the venue's QR is reported" "showreel: wrote assets/qr/venue.svg for https://v.example/shop" "$WORK/run.out"
  check "the social's stamp" "$(stamp web.svg)" "<!--showreel-qr:https://a.example-->"
  check "the explicit qr:'s stamp" "$(stamp front.svg)" "<!--showreel-qr:https://b.example-->"
  check "the venue's stamp" "$(stamp venue.svg)" "<!--showreel-qr:https://v.example/shop-->"
  if [ -e "$WORK/reel/assets/qr/mail.svg" ]; then bad "a social with no url got a QR"
  else ok "a social with no url gets none"; fi
  absent "the XML declaration is left out" "<?xml" "$WORK/reel/assets/qr/web.svg"
  finish
fi

# ---------------------------------------------------------------- QR3 -- AC-702cceb9.2

if want QR3; then
  start QR3 "a file there is kept and its state said; --force writes it anew"
  reel
  "$SHOWREEL" qr "$WORK/reel" >/dev/null 2>&1
  cp "$WORK/reel/assets/qr/web.svg" "$WORK/web.before"
  "$SHOWREEL" qr "$WORK/reel" >"$WORK/again.out" 2>&1
  present "a matching file is kept and said to match" "kept assets/qr/web.svg: its stamp matches https://a.example" "$WORK/again.out"
  if cmp -s "$WORK/web.before" "$WORK/reel/assets/qr/web.svg"; then ok "the kept file is byte for byte as it was"
  else bad "the kept file changed"; fi
  # The config moves on and the QR made for the old address stays: reel()
  # starts the reel afresh, so the old QR is put back, as a reel that changed
  # its config and kept its assets would have it (dc's read r1).
  reel "https://new.example"
  mkdir -p "$WORK/reel/assets/qr" && cp "$WORK/web.before" "$WORK/reel/assets/qr/web.svg"
  "$SHOWREEL" qr "$WORK/reel" >"$WORK/stale.out" 2>&1
  present "a stale file is kept and named as stale" "it was generated for https://a.example, but the config now says https://new.example; --force regenerates it" "$WORK/stale.out"
  if cmp -s "$WORK/web.before" "$WORK/reel/assets/qr/web.svg"; then ok "the stale file is kept byte for byte"
  else bad "the stale file changed without --force"; fi
  "$SHOWREEL" qr "$WORK/reel" --force >"$WORK/force.out" 2>&1
  check "the exit status with --force" "$?" "0"
  present "--force writes it anew" "showreel: wrote assets/qr/web.svg for https://new.example" "$WORK/force.out"
  check "its new stamp" "$(stamp web.svg)" "<!--showreel-qr:https://new.example-->"
  finish
fi

# ---------------------------------------------------------------- QR4 -- AC-702cceb9.3

if want QR4; then
  start QR4 "a QR outside the reel is refused before anything is written"
  rm -rf "$WORK/reel"
  mkdir -p "$WORK/reel"
  cat >"$WORK/reel/showreel.yaml" <<'EOF'
artist: {handle: x}
session: {venue_url: 'https://v.example/shop'}
socials:
  - {label: Web, handle: a, url: 'https://a.example', qr: ../outside.svg}
EOF
  "$SHOWREEL" qr "$WORK/reel" >/dev/null 2>"$WORK/outside.err"
  check "the exit status" "$?" "2"
  present "the refusal says why" "outside the reel" "$WORK/outside.err"
  if [ -e "$WORK/outside.svg" ]; then bad "the QR was written outside the reel"
  else ok "nothing was written outside the reel"; fi
  if [ -e "$WORK/reel/assets" ]; then bad "the venue's QR was written before the refusal"
  else ok "nothing was written inside it either"; fi
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
