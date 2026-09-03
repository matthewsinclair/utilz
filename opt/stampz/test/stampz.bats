#!/usr/bin/env bats
# stampz.bats - Tests for stampz utility
#
# ST0011 acceptance tests AT01-AT10. Each test names the AT it carries.
#
# VISIBILITY IS MEASURED IN THE CENTRE BAND, NEVER WHOLE-PAGE. A whole-page
# pixel count reported the --underlay build -- the one that must be invisible
# -- as visible at 0.30%, because compositing leaves a one-pixel rasteriser
# seam down the page edge: 468 differing pixels, one per row, every delta
# exactly 83. The band crop excludes the seam by construction. Raising a
# threshold above it instead would work today and drift with the renderer.

load "../../utilz/test/test_helper.bash"

# ============================================================================
# HELPERS
# ============================================================================

run_stampz() {
  run "$UTILZ_BIN_DIR/stampz" "$@"
}

# Load the implementation's functions WITHOUT running it, so fixtures come
# out of the one PDF assembler rather than a second copy living in here.
# The script detects that it is being sourced; there is no flag to pass, and
# deliberately so -- an inheritable env guard made the shipped tool a silent
# no-op for any process that had it set.
load_stampz_lib() {
  # shellcheck source=/dev/null
  source "$UTILZ_HOME/opt/stampz/stampz"
}

have_tools() {
  command -v qpdf >/dev/null 2>&1 &&
    command -v pdfinfo >/dev/null 2>&1 &&
    command -v pdftoppm >/dev/null 2>&1
}

# require_tools -- skip with a TRUE reason, naming what is missing.
require_tools() {
  if ! have_tools; then
    skip "needs qpdf and poppler (pdfinfo, pdftoppm); CI installs both"
  fi
}

# band_args <pdf> <dpi> -- crop flags for the centre band the mark crosses.
band_args() {
  local size
  size=$(pdfinfo "$1" 2>/dev/null | awk '/^Page size:/ { print $3, $5 }')
  awk -v w="${size%% *}" -v h="${size##* }" -v r="$2" 'BEGIN {
    px = w * r / 72; py = h * r / 72
    printf "-x %d -y %d -W %d -H %d", 0.20 * px, 0.35 * py, 0.60 * px, 0.30 * py
  }'
}

# crop_diff <pdf-a> <pdf-b> <crop-flags...> -- differing bytes in one crop.
#
# Comparing two renders of the SAME crop means the PGM headers are identical
# by construction, so every differing byte is a differing pixel and nothing
# has to parse the header. An earlier version skipped a guessed number of
# header fields with `NR > 12`, which is a magic number that silently
# miscounts the moment the dimensions change width in digits.
crop_diff() {
  local a="$1" b="$2"
  shift 2
  local d fa fb n
  d=$(mktemp -d)
  pdftoppm -gray -r 40 "$@" "$a" "$d/a"
  pdftoppm -gray -r 40 "$@" "$b" "$d/b"
  fa=$(find "$d" -name 'a-*.pgm' | head -1)
  fb=$(find "$d" -name 'b-*.pgm' | head -1)
  # cmp exits 1 WHEN THE FILES DIFFER, which is the answer we want, not an
  # error -- so it must not be allowed to kill the test under errexit.
  n=$({ cmp -l "$fa" "$fb" || true; } | wc -l | tr -d ' ')
  rm -rf "$d"
  printf '%s' "$n"
}

# band_diff <pdf-a> <pdf-b> -- differing bytes within the centre band.
band_diff() {
  # word-splitting the crop flags is intended
  # shellcheck disable=SC2046
  crop_diff "$1" "$2" $(band_args "$1" 40)
}

# margin_diff <pdf> <blank> -- ink in the left and right margin strips.
#
# Proves a mark FITS, which the band check cannot: a string that overran the
# page would still differ in the centre, so "visible" and "inside the page"
# are two claims needing two instruments.
margin_diff() {
  local pdf="$1" blank="$2" size px strip total
  size=$(pdfinfo "$pdf" 2>/dev/null | awk '/^Page size:/ { print $3, $5 }')
  px=$(awk -v w="${size%% *}" 'BEGIN { printf "%d", w * 40 / 72 }')
  strip=$((px / 20))
  total=$(crop_diff "$pdf" "$blank" -x 0 -y 0 -W "$strip" -H 99999)
  total=$((total + $(crop_diff "$pdf" "$blank" -x "$((px - strip))" -y 0 -W "$strip" -H 99999)))
  printf '%s' "$total"
}

# vmargin_diff <pdf> <blank> -- ink in the top and bottom margin strips.
#
# The vertical twin of margin_diff, and the one that matters: a width-only
# size solve overflows a WIDE page vertically while staying inside it
# horizontally, so a left/right check alone cannot see the defect.
vmargin_diff() {
  local pdf="$1" blank="$2" size py strip total
  size=$(pdfinfo "$pdf" 2>/dev/null | awk '/^Page size:/ { print $3, $5 }')
  py=$(awk -v h="${size##* }" 'BEGIN { printf "%d", h * 40 / 72 }')
  strip=$((py / 20))
  total=$(crop_diff "$pdf" "$blank" -x 0 -y 0 -W 99999 -H "$strip")
  total=$((total + $(crop_diff "$pdf" "$blank" -x 0 -y "$((py - strip))" -W 99999 -H "$strip")))
  printf '%s' "$total"
}

make_pack() {
  load_stampz_lib
  mkdir -p "$1"
  _emit_fixture light "$1/light.pdf"
  _emit_fixture dark "$1/dark.pdf"
}

# ============================================================================
# BASIC TESTS
# ============================================================================

@test "stampz --help shows usage" {
  run_stampz --help
  assert_success
  assert_output_contains "Usage"
  assert_output_contains "stampz"
}

@test "stampz --version shows version" {
  run_stampz --version
  assert_success
  assert_output_contains "stampz"
  assert_output_contains "v"
}

@test "stampz with unknown option shows error" {
  run_stampz --invalid-option
  assert_failure
  assert_output_contains "Unknown option"
}

@test "stampz with no arguments refuses" {
  run_stampz
  assert_failure
  assert_output_contains "No pack directory"
}

@test "stampz with no recipient refuses" {
  run_stampz "$BATS_TEST_TMPDIR"
  assert_failure
  assert_output_contains "No recipient"
}

# ============================================================================
# AT01 -- AC02: the mark is visible on a light AND a near-black page
# ============================================================================

@test "AT01: the mark is visible on a light page (centre band)" {
  require_tools
  local p="$BATS_TEST_TMPDIR/pack"
  make_pack "$p"
  run_stampz "$p" "Matthew Sinclair" --out "$BATS_TEST_TMPDIR/out"
  assert_success

  local n
  n=$(band_diff "$p/light.pdf" "$BATS_TEST_TMPDIR/out/light.pdf")
  [ "$n" -gt 200 ] || {
    echo "centre-band difference was $n pixels; the mark did not land" >&2
    return 1
  }
}

@test "AT01: the mark is visible on a near-black page (centre band)" {
  require_tools
  local p="$BATS_TEST_TMPDIR/pack"
  make_pack "$p"
  run_stampz "$p" "Matthew Sinclair" --out "$BATS_TEST_TMPDIR/out"
  assert_success

  local n
  n=$(band_diff "$p/dark.pdf" "$BATS_TEST_TMPDIR/out/dark.pdf")
  [ "$n" -gt 200 ] || {
    echo "centre-band difference was $n pixels; the mark did not land" >&2
    return 1
  }
}

# ============================================================================
# AT02 -- AC09: the underlay control. THIS IS THE ONE THAT CAN GO RED.
# ============================================================================

@test "AT02: --underlay is invisible on an opaque page (the control)" {
  require_tools
  load_stampz_lib
  local d="$BATS_TEST_TMPDIR"
  _emit_fixture light "$d/light.pdf"
  _render_stamp 595 842 "CONFIDENTIAL 20260903 Matthew Sinclair" 0.5 0.30 "$d/stamp.pdf"

  qpdf "$d/light.pdf" --underlay "$d/stamp.pdf" --repeat=1 -- "$d/under.pdf"
  qpdf "$d/light.pdf" --overlay "$d/stamp.pdf" --repeat=1 -- "$d/over.pdf"

  local u o
  u=$(band_diff "$d/light.pdf" "$d/under.pdf")
  o=$(band_diff "$d/light.pdf" "$d/over.pdf")

  # The point of the control: underlay renders and is then covered, so the
  # file changes on disk and NOTHING changes on the page.
  [ "$u" -eq 0 ] || {
    echo "underlay changed $u band pixels; expected 0" >&2
    return 1
  }
  [ "$o" -gt 200 ] || {
    echo "overlay changed only $o band pixels; the control proves nothing" >&2
    return 1
  }
  # And it really did write a different file, which is what makes the trap
  # invisible to every check that is not a render.
  run cmp -s "$d/light.pdf" "$d/under.pdf"
  assert_failure
}

# ============================================================================
# AT05 -- AC06: mixed page geometry is refused
# ============================================================================

@test "AT05: a mixed-geometry PDF is refused, naming the size count" {
  require_tools
  load_stampz_lib
  local p="$BATS_TEST_TMPDIR/pack"
  mkdir -p "$p"
  # Two genuinely different MEDIA BOXES in one file. An earlier version made
  # this file by rotating one page, which does not change what pdfinfo
  # reports per page -- so the fixture was uniform and the guard was never
  # exercised. The test passed nothing and looked like it tested something.
  _emit_fixture light "$BATS_TEST_TMPDIR/a.pdf" 595 842
  _emit_fixture light "$BATS_TEST_TMPDIR/b.pdf" 1440 810
  qpdf --empty --pages "$BATS_TEST_TMPDIR/a.pdf" "$BATS_TEST_TMPDIR/b.pdf" -- "$p/mixed.pdf"

  # The fixture must really carry two sizes, or this test proves nothing.
  local sizes
  sizes=$(pdfinfo -f 1 -l 2 "$p/mixed.pdf" | awk '/^Page +[0-9]+ size:/ { print $4 "x" $6 }' | sort -u | wc -l | tr -d ' ')
  [ "$sizes" -eq 2 ] || {
    echo "fixture carries $sizes geometries, not 2; the guard is untested" >&2
    return 1
  }

  run_stampz "$p" "Matthew Sinclair" --out "$BATS_TEST_TMPDIR/out"
  assert_failure
  assert_output_contains "mixed page geometry"
}

# ============================================================================
# AT04 -- AC05: page count survives
# ============================================================================

@test "AT04: page count is unchanged by the overlay" {
  require_tools
  local p="$BATS_TEST_TMPDIR/pack"
  make_pack "$p"
  run_stampz "$p" "Matthew Sinclair" --out "$BATS_TEST_TMPDIR/out"
  assert_success

  local before after
  before=$(pdfinfo "$p/light.pdf" | awk '/^Pages:/ { print $2 }')
  after=$(pdfinfo "$BATS_TEST_TMPDIR/out/light.pdf" | awk '/^Pages:/ { print $2 }')
  [ "$before" = "$after" ]
}

# ============================================================================
# AT06 -- AC07: the manifest
# ============================================================================

@test "AT06: the manifest records recipient, date, source and both hashes" {
  require_tools
  local p="$BATS_TEST_TMPDIR/pack" out="$BATS_TEST_TMPDIR/out"
  make_pack "$p"
  run_stampz "$p" "Matthew Sinclair" --out "$out" --date 20260903
  assert_success

  local m="$out/STAMP-MANIFEST.txt"
  [ -f "$m" ]
  grep -q "Recipient : Matthew Sinclair" "$m"
  grep -q "Dated     : 20260903" "$m"
  grep -q "Source    : $p" "$m"

  # Every stamped file has a row, and its before and after hashes DIFFER --
  # a row carrying the same hash twice would mean nothing was written.
  local before after
  before=$(awk '/^light.pdf/ { print $3 }' "$m")
  after=$(awk '/^light.pdf/ { print $4 }' "$m")
  [ -n "$before" ] && [ -n "$after" ] && [ "$before" != "$after" ]
}

# ============================================================================
# AT07 -- AC08: the deterrence boundary is stated and true
# ============================================================================

@test "AT07: page text survives, the recipient is not contiguous, header is honest" {
  require_tools
  command -v pdftotext >/dev/null 2>&1 || skip "needs pdftotext (poppler)"
  local p="$BATS_TEST_TMPDIR/pack" out="$BATS_TEST_TMPDIR/out"
  make_pack "$p"
  run_stampz "$p" "Matthew Sinclair" --out "$out"
  assert_success

  local txt
  txt=$(pdftotext "$out/light.pdf" - 2>/dev/null)
  # Nothing was rasterised: the page's own text is still extractable.
  echo "$txt" | grep -q "A light page"
  # The mark is NOT a contiguous search hit, which is the claim the header
  # makes and the reason this deters rather than protects.
  ! echo "$txt" | grep -q "Matthew Sinclair"

  # The claim itself is in the shipped header, asserted rather than trusted.
  grep -q "THIS DETERS, IT DOES NOT PROTECT" "$UTILZ_HOME/opt/stampz/stampz"
}

# ============================================================================
# AT08 -- AC03: out-dir is the default; --in-place is explicit
# ============================================================================

@test "AT08: the default run leaves the source pack untouched" {
  require_tools
  local p="$BATS_TEST_TMPDIR/pack"
  make_pack "$p"
  local before
  before=$(shasum -a 256 "$p/light.pdf" | cut -d' ' -f1)

  run_stampz "$p" "Matthew Sinclair"
  assert_success

  local after
  after=$(shasum -a 256 "$p/light.pdf" | cut -d' ' -f1)
  [ "$before" = "$after" ]
  [ -f "${p}.stamped/light.pdf" ]
}

@test "AT08: --in-place overwrites the pack" {
  require_tools
  local p="$BATS_TEST_TMPDIR/pack"
  make_pack "$p"
  local before
  before=$(shasum -a 256 "$p/light.pdf" | cut -d' ' -f1)

  run_stampz "$p" "Matthew Sinclair" --in-place
  assert_success

  local after
  after=$(shasum -a 256 "$p/light.pdf" | cut -d' ' -f1)
  [ "$before" != "$after" ]
}

@test "AT08: --in-place and --out together are refused" {
  run_stampz "$BATS_TEST_TMPDIR" "Someone" --in-place --out /tmp/x
  assert_failure
  assert_output_contains "mutually exclusive"
}

# ============================================================================
# AT09 -- AC01: no browser, no network
# ============================================================================

@test "AT09: the implementation drives no browser and fetches nothing" {
  local impl="$UTILZ_HOME/opt/stampz/stampz"
  # Assert on the ARTIFACT, not on a claim in a comment. The header
  # discusses Chrome and CDNs by name, so the check targets INVOCATIONS:
  # a resolved browser path or an actual fetch.
  ! grep -qE '(Google Chrome\.app|--headless|--print-to-pdf)' "$impl"
  ! grep -qE '\b(curl|wget)\b' "$impl"
  ! grep -qE 'https?://[a-z]' "$impl"
}

@test "AT09: the stamp itself carries no URI" {
  require_tools
  load_stampz_lib
  local d="$BATS_TEST_TMPDIR"
  _render_stamp 595 842 "CONFIDENTIAL 20260903 Someone" 0.5 0.30 "$d/stamp.pdf"
  ! grep -qa 'http' "$d/stamp.pdf"
  ! grep -qa '/URI' "$d/stamp.pdf"
}

@test "AT09: every declared dependency is a real command name" {
  # doctor resolves a dependency by running `command -v <name>`, so a
  # PACKAGE name here is a permanent false finding: `poppler` installs
  # pdfinfo and pdftoppm and provides no binary called poppler, and doctor
  # reported it missing on a machine that had it.
  local yaml="$UTILZ_HOME/opt/stampz/stampz.yaml" dep
  grep -q 'name: qpdf' "$yaml"
  grep -q 'name: pdfinfo' "$yaml"
  while read -r dep; do
    command -v "$dep" >/dev/null 2>&1 || skip "declared dep $dep is not installed here"
  done < <(awk '/^  - name: / { print $3 }' "$yaml")
}

# ============================================================================
# AT10 -- AC10: framework integration
# ============================================================================

@test "AT10: bin/stampz is a dispatcher symlink" {
  [ -L "$UTILZ_BIN_DIR/stampz" ]
  [ "$(readlink "$UTILZ_BIN_DIR/stampz")" = "utilz" ]
}

@test "AT10: utilz list shows stampz" {
  run "$UTILZ_BIN_DIR/utilz" list
  assert_success
  assert_output_contains "stampz"
}

# ============================================================================
# AT03 -- AC04: font size is derived, not configured
# ============================================================================

@test "AT03: a long recipient shrinks the mark instead of overrunning" {
  require_tools
  load_stampz_lib
  local d="$BATS_TEST_TMPDIR" short long
  short="A B"
  long="Wilhelmina Fitzgerald-Montgomery of the Northern Reaches and Beyond"

  _render_stamp 595 842 "$short" 0.5 0.30 "$d/short.pdf"
  _render_stamp 595 842 "$long" 0.5 0.30 "$d/long.pdf"

  # The derived size must shrink as the string grows. Read the font size
  # straight out of the content stream -- the artifact, not the formula.
  local fs_short fs_long
  fs_short=$(qpdf --qdf --object-streams=disable "$d/short.pdf" - 2>/dev/null | grep -ao '/F1 [0-9.]* Tf' | head -1 | awk '{ print $2 }')
  fs_long=$(qpdf --qdf --object-streams=disable "$d/long.pdf" - 2>/dev/null | grep -ao '/F1 [0-9.]* Tf' | head -1 | awk '{ print $2 }')
  [ -n "$fs_short" ] && [ -n "$fs_long" ]
  awk -v a="$fs_short" -v b="$fs_long" 'BEGIN { exit !(a > b) }'

  # BOTH still fit on A4: no ink in either side margin.
  _emit_fixture blank "$d/blank.pdf"
  local m ink
  for m in short long; do
    ink=$(margin_diff "$d/$m.pdf" "$d/blank.pdf")
    [ "$ink" -eq 0 ] || {
      echo "$m recipient put $ink ink pixels in the side margins" >&2
      return 1
    }
  done
}

@test "AT03: a short name on a wide page does not overflow vertically" {
  require_tools
  load_stampz_lib
  local d="$BATS_TEST_TMPDIR"

  # THE CASE THAT CATCHES A WIDTH-ONLY SOLVE. On A4 the defect is invisible
  # -- the bounding box exceeds the page arithmetically but the glyph ink is
  # inset far enough that no pixel lands in a margin, so an A4-only fit check
  # passes a formula that is wrong. On a 1440x810 deck page the same name
  # overflows top and bottom for real.
  _render_stamp 1440 810 "A B" 0.5 0.30 "$d/deck.pdf"
  _emit_fixture blank "$d/blankdeck.pdf" 1440 810

  local ink strip_px
  ink=$(vmargin_diff "$d/deck.pdf" "$d/blankdeck.pdf")

  # Bound stated as a fraction of the strip, not a value tuned to today's
  # render: each strip is 800 x 22 px, so the two together are 35200 px.
  # Measured: width-only 2761 (7.8%), two-axis 141 (0.4%). The bound sits an
  # order of magnitude clear of the passing case on one side and a factor of
  # three clear of the failing one on the other.
  strip_px=35200
  awk -v n="$ink" -v t="$strip_px" 'BEGIN { exit !(n < 0.02 * t) }' || {
    echo "short name put $ink ink pixels into the wide page margins" >&2
    echo "(over 2% of the strip: the size solve is ignoring page height)" >&2
    return 1
  }
}
