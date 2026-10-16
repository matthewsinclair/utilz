#!/usr/bin/env bats
# macos.bats - Tests for bin/devbin macos, menuz's app half (ST0027 WP-06)
#
# app-icons and doctor (AC-06.3), run through the real devbin dispatcher from
# a fixture project: bin/devbin and bin/.devbin copied into the test's own
# temp directory, with fixture SVGs, so nothing reads or writes the checkout's
# native/macos/Menuz. rsvg-convert is a fake that records its arguments and
# writes a PNG's first bytes; the one test that runs the real tool skips
# where it is not installed.
#
# devbin itself needs bash 5 (it refuses 3.2 by name), so these tests run
# under the first bash 5 on PATH, linked into the fakes. PATH is otherwise a
# copy of /usr/bin and /bin without rsvg-convert, so "not installed" is real
# on every machine.

load "../../utilz/test/test_helper.bash"

setup_file() {
  local b
  BASH5=""
  while IFS= read -r b; do
    if "$b" -c '(( BASH_VERSINFO[0] >= 5 ))' 2>/dev/null; then BASH5="$b"; break; fi
  done < <(type -ap bash)
  export BASH5
  export ORIGINAL_PATH_FOR_RSVG="$PATH"
  SYSBIN="$BATS_FILE_TMPDIR/sysbin"
  mkdir -p "$SYSBIN"
  local dir f
  for dir in /usr/bin /bin; do
    for f in "$dir"/*; do
      [ -e "$SYSBIN/${f##*/}" ] || ln -s "$f" "$SYSBIN/${f##*/}"
    done
  done
  rm -f "$SYSBIN/rsvg-convert"
  export SYSBIN
}

setup() {
  [ -n "$BASH5" ] || skip "devbin needs bash 5 and none is on PATH"
  PROJ="$BATS_TEST_TMPDIR/proj"
  mkdir -p "$PROJ/bin" "$PROJ/native/macos/Menuz/design" "$PROJ/native/macos/Menuz/Menuz"
  cp -R "$UTILZ_HOME/bin/devbin" "$UTILZ_HOME/bin/.devbin" "$PROJ/bin/"
  # As devbin sees the root: its own location with symlinks resolved, so
  # /var/folders reads /private/var/folders on macOS.
  PROJ="$(cd "$PROJ" && pwd -P)"
  DESIGN="$PROJ/native/macos/Menuz/design"
  ASSETS="$PROJ/native/macos/Menuz/Menuz/Assets.xcassets"
  printf '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024"><rect width="1024" height="1024" rx="230" fill="#222"/></svg>\n' >"$DESIGN/menuz.svg"
  printf '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 18 18"><rect x="2" y="2" width="14" height="14" fill="#000"/></svg>\n' >"$DESIGN/menuz-mark.svg"
  FAKES="$BATS_TEST_TMPDIR/fakes"
  mkdir -p "$FAKES"
  ln -s "$BASH5" "$FAKES/bash"
  export PATH="$FAKES:$SYSBIN"
}

# rsvg-convert that records each call on one line and writes the PNG
# signature to the file after -o; BODY runs first and may exit.
fake_rsvg() {
  local body="${1:-}"
  cat >"$FAKES/rsvg-convert" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >>"$FAKES/rsvg-convert.calls"
$body
out=""
while [ \$# -gt 0 ]; do
  if [ "\$1" = -o ]; then out="\$2"; shift; fi
  shift
done
printf '\x89PNG\r\n' >"\$out"
EOF
  chmod +x "$FAKES/rsvg-convert"
}

# From inside the fixture project: devbin refuses to act on a project other
# than the one it is run from.
run_macos() {
  cd "$PROJ" || return 1
  run bin/devbin macos "$@"
}

@test "AC-06.3: app-icons writes AppIcon at the seven sizes from menuz.svg and MenuBarIcon at three from menuz-mark.svg" {
  fake_rsvg
  run_macos app-icons
  [ "$status" -eq 0 ] || fail "exit $status: $output"
  local px
  for px in 16 32 64 128 256 512 1024; do
    grep -qx -- "-w $px -h $px $DESIGN/menuz.svg -o $ASSETS/AppIcon.appiconset/icon_$px.png" "$FAKES/rsvg-convert.calls" ||
      fail "no call for icon_$px: $(cat "$FAKES/rsvg-convert.calls")"
    [ -s "$ASSETS/AppIcon.appiconset/icon_$px.png" ]
  done
  for px in 18 36 54; do
    grep -qx -- "-w $px -h $px $DESIGN/menuz-mark.svg -o $ASSETS/MenuBarIcon.imageset/menubar_$px.png" "$FAKES/rsvg-convert.calls" ||
      fail "no call for menubar_$px: $(cat "$FAKES/rsvg-convert.calls")"
    [ -s "$ASSETS/MenuBarIcon.imageset/menubar_$px.png" ]
  done
  [ "$(wc -l <"$FAKES/rsvg-convert.calls")" -eq 10 ]
  [[ "$output" == *"wrote AppIcon (7 sizes) + MenuBarIcon (template, 3 scales) to native/macos/Menuz/Menuz/Assets.xcassets"* ]]
}

@test "AC-06.3: every file the Contents.json files name was written, and the menu bar image is a template" {
  fake_rsvg
  run_macos app-icons
  [ "$status" -eq 0 ] || fail "exit $status: $output"
  [ -f "$ASSETS/Contents.json" ]
  local set name named=0
  for set in AppIcon.appiconset MenuBarIcon.imageset; do
    while IFS= read -r name; do
      [ -s "$ASSETS/$set/$name" ] || fail "$set/Contents.json names $name, which was not written"
      named=$((named + 1))
    done < <(grep -o '"filename" : "[^"]*"' "$ASSETS/$set/Contents.json" | sed 's/.*: "//; s/"$//')
  done
  [ "$named" -eq 13 ]
  [ "$(grep -c '"idiom" : "mac"' "$ASSETS/AppIcon.appiconset/Contents.json")" -eq 10 ]
  grep -qF '"template-rendering-intent" : "template"' "$ASSETS/MenuBarIcon.imageset/Contents.json"
}

@test "AC-06.3: app-icons refuses by name without rsvg-convert, and writes nothing" {
  run_macos app-icons
  [ "$status" -eq 1 ]
  [[ "$output" == *"rsvg-convert not found (brew install librsvg)"* ]]
  [ ! -e "$ASSETS" ]
}

@test "AC-06.3: app-icons refuses by name without either SVG, calls no rsvg-convert and writes nothing" {
  fake_rsvg
  local svg
  for svg in menuz.svg menuz-mark.svg; do
    mv "$DESIGN/$svg" "$DESIGN/$svg.away"
    run_macos app-icons
    [ "$status" -eq 1 ]
    [[ "$output" == *"no SVG at native/macos/Menuz/design/$svg"* ]] || fail "$output"
    [ ! -e "$FAKES/rsvg-convert.calls" ]
    [ ! -e "$ASSETS" ]
    mv "$DESIGN/$svg.away" "$DESIGN/$svg"
  done
}

@test "AC-06.3: an rsvg-convert that fails stops app-icons, naming the size and the source" {
  fake_rsvg 'case "$*" in *"-w 128 "*) exit 3 ;; esac'
  run_macos app-icons
  [ "$status" -eq 1 ]
  [[ "$output" == *"rsvg-convert failed at 128px for native/macos/Menuz/design/menuz.svg"* ]] || fail "$output"
}

@test "AC-06.3: an rsvg-convert that exits 0 and writes nothing stops app-icons" {
  fake_rsvg 'case "$*" in *menuz-mark.svg*) exit 0 ;; esac'
  run_macos app-icons
  [ "$status" -eq 1 ]
  [[ "$output" == *"rsvg-convert wrote nothing at 18px for native/macos/Menuz/design/menuz-mark.svg"* ]] || fail "$output"
}

@test "AC-06.3: the real rsvg-convert makes PNGs of the sizes asked for" {
  local real=""
  real="$(PATH="$ORIGINAL_PATH_FOR_RSVG" command -v rsvg-convert 2>/dev/null || true)"
  [ -n "$real" ] || skip "rsvg-convert is not installed here"
  ln -s "$real" "$FAKES/rsvg-convert"
  run_macos app-icons
  [ "$status" -eq 0 ] || fail "exit $status: $output"
  run file -b "$ASSETS/AppIcon.appiconset/icon_64.png"
  [[ "$output" == "PNG image data, 64 x 64"* ]] || fail "$output"
  run file -b "$ASSETS/MenuBarIcon.imageset/menubar_54.png"
  [[ "$output" == "PNG image data, 54 x 54"* ]] || fail "$output"
}

@test "AC-06.3: doctor reports rsvg-convert, both SVGs and the catalogue, exit 0 when nothing is missing" {
  fake_rsvg
  run_macos doctor
  [ "$status" -eq 0 ] || fail "exit $status: $output"
  [[ "$output" == *"rsvg-convert   $FAKES/rsvg-convert"* ]]
  [[ "$output" == *"menuz.svg      present"* ]]
  [[ "$output" == *"menuz-mark.svg present"* ]]
  [[ "$output" == *"AppIcon.appiconset    absent (run: "*" macos app-icons)"* ]] || fail "$output"
  run_macos app-icons
  run_macos doctor
  [[ "$output" == *"AppIcon.appiconset    present"* ]]
  [[ "$output" == *"MenuBarIcon.imageset  present"* ]]
}

@test "AC-06.3: doctor says MISSING and exits 1 without rsvg-convert or an SVG" {
  run_macos doctor
  [ "$status" -eq 1 ]
  [[ "$output" == *"rsvg-convert   MISSING (brew install librsvg)"* ]]
  fake_rsvg
  rm "$DESIGN/menuz-mark.svg"
  run_macos doctor
  [ "$status" -eq 1 ]
  [[ "$output" == *"menuz-mark.svg MISSING (native/macos/Menuz/design/menuz-mark.svg)"* ]]
  [[ "$output" == *"incomplete -- see MISSING above"* ]]
}

@test "macos with no subcommand prints the list; an unknown one or an extra argument is refused" {
  run_macos
  [ "$status" -eq 0 ]
  [[ "$output" == *"app-icons"* && "$output" == *"doctor"* ]]
  run_macos sign
  [ "$status" -eq 1 ]
  [[ "$output" == *"unknown macos subcommand: sign (try: app-icons doctor)"* ]]
  run_macos app-icons now
  [ "$status" -eq 1 ]
  [[ "$output" == *"macos app-icons takes no arguments, got: now"* ]]
}
