#!/usr/bin/env bats
# macos.bats - Tests for what bin/devbin macos keeps of Utilz's own (issue 0118)
#
# devbin's built-in macos signs, notarises and publishes Menuz.app, and
# devbin's own suite tests it. What stays Utilz's is tested here: the macos:
# declaration in bin/.devbin/config.yaml, the bundle id's second copy there,
# and app-icons with its check (AC-06.3), declared options that route to
# tools/app-icons before any other word reaches the built-in.
#
# app-icons runs through the real devbin dispatcher from a fixture project:
# bin/devbin, bin/.devbin and tools/app-icons copied into the test's own temp
# directory, with fixture SVGs, so nothing reads or writes the checkout's
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
  mkdir -p "$PROJ/bin" "$PROJ/tools" "$PROJ/native/macos/Menuz/design" "$PROJ/native/macos/Menuz/Menuz"
  cp -R "$UTILZ_HOME/bin/devbin" "$UTILZ_HOME/bin/.devbin" "$PROJ/bin/"
  cp "$UTILZ_HOME/tools/app-icons" "$PROJ/tools/"
  printf '2.14.0\n' >"$PROJ/VERSION"
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
  export HOME="$BATS_TEST_TMPDIR/home" XDG_STATE_HOME="$BATS_TEST_TMPDIR/state" USER=tester
  mkdir -p "$HOME"
  # This setup() replaces test_helper's, so it isolates the tools that keep
  # state as that one does: unison, gpg, and git's signing (issue 0091).
  isolate_tool_homes
}

# One value of bin/.devbin/config.yaml's top-level macos: block, as written.
cfg_macos() {
  awk -v k="$1" '
    /^macos:/ { m = 1; next }
    /^[^ #]/ { m = 0 }
    m && $1 == k ":" { sub(/^[^:]*: */, ""); print; exit }
  ' "$UTILZ_HOME/bin/.devbin/config.yaml"
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
  local px call calls=""
  for px in 16 32 64 128 256 512 1024; do
    call="-w $px -h $px $DESIGN/menuz.svg -o $ASSETS/AppIcon.appiconset/icon_$px.png"
    grep -qx -- "$call" "$FAKES/rsvg-convert.calls" ||
      fail "no call for icon_$px: $(cat "$FAKES/rsvg-convert.calls")"
    calls="$calls$call"$'\n'
    [ -s "$ASSETS/AppIcon.appiconset/icon_$px.png" ]
  done
  for px in 18 36 54; do
    call="-w $px -h $px $DESIGN/menuz-mark.svg -o $ASSETS/MenuBarIcon.imageset/menubar_$px.png"
    grep -qx -- "$call" "$FAKES/rsvg-convert.calls" ||
      fail "no call for menubar_$px: $(cat "$FAKES/rsvg-convert.calls")"
    calls="$calls$call"$'\n'
    [ -s "$ASSETS/MenuBarIcon.imageset/menubar_$px.png" ]
  done
  [ "$(sort "$FAKES/rsvg-convert.calls")" = "$(printf '%s' "$calls" | sort)" ] ||
    fail "calls beyond the listed sizes: $(cat "$FAKES/rsvg-convert.calls")"
  [[ "$output" == *"wrote AppIcon (7 sizes) + MenuBarIcon (template, 3 scales) to native/macos/Menuz/Menuz/Assets.xcassets"* ]]
}

@test "AC-06.3: every file the Contents.json files name was written, and the menu bar image is a template" {
  fake_rsvg
  run_macos app-icons
  [ "$status" -eq 0 ] || fail "exit $status: $output"
  [ -f "$ASSETS/Contents.json" ]
  local set name named
  for set in AppIcon.appiconset MenuBarIcon.imageset; do
    named=""
    while IFS= read -r name; do
      [ -s "$ASSETS/$set/$name" ] || fail "$set/Contents.json names $name, which was not written"
      named="$named$name"$'\n'
    done < <(grep -o '"filename" : "[^"]*"' "$ASSETS/$set/Contents.json" | sed 's/.*: "//; s/"$//')
    [ -n "$named" ] || fail "$set/Contents.json names no file"
    [ "$(printf '%s' "$named" | sort -u)" = "$(cd "$ASSETS/$set" && printf '%s\n' *.png | sort)" ] ||
      fail "$set holds a PNG its Contents.json does not name: $(cd "$ASSETS/$set" && printf '%s ' *.png)"
  done
  local size slots="" have
  for size in 16x16 32x32 128x128 256x256 512x512; do
    slots="$slots$size 1x"$'\n'"$size 2x"$'\n'
  done
  have="$(grep '"idiom" : "mac"' "$ASSETS/AppIcon.appiconset/Contents.json" | sed 's/.*"scale" : "\([^"]*\)", "size" : "\([^"]*\)".*/\2 \1/' | sort)"
  [ "$have" = "$(printf '%s' "$slots" | sort)" ] || fail "AppIcon's mac slots: $have"
  have="$(grep '"idiom" : "universal"' "$ASSETS/MenuBarIcon.imageset/Contents.json" | sed 's/.*"scale" : "\([^"]*\)".*/\1/' | sort)"
  [ "$have" = "$(printf '%s\n' 1x 2x 3x | sort)" ] || fail "MenuBarIcon's scales: $have"
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

@test "AC-06.3: app-icons-check reports rsvg-convert, both SVGs and the catalogue, exit 0 when nothing is missing" {
  fake_rsvg
  run_macos app-icons-check
  [ "$status" -eq 0 ] || fail "exit $status: $output"
  [[ "$output" == *"rsvg-convert   $FAKES/rsvg-convert"* ]]
  [[ "$output" == *"menuz.svg      present"* ]]
  [[ "$output" == *"menuz-mark.svg present"* ]]
  [[ "$output" == *"AppIcon.appiconset    absent (run: "*" macos app-icons)"* ]] || fail "$output"
  run_macos app-icons
  run_macos app-icons-check
  [[ "$output" == *"AppIcon.appiconset    present"* ]]
  [[ "$output" == *"MenuBarIcon.imageset  present"* ]]
}

@test "AC-06.3: app-icons-check says MISSING and exits 1 without rsvg-convert or an SVG" {
  run_macos app-icons-check
  [ "$status" -eq 1 ]
  [[ "$output" == *"rsvg-convert   MISSING (brew install librsvg)"* ]]
  fake_rsvg
  rm "$DESIGN/menuz-mark.svg"
  run_macos app-icons-check
  [ "$status" -eq 1 ]
  [[ "$output" == *"menuz-mark.svg MISSING (native/macos/Menuz/design/menuz-mark.svg)"* ]]
  [[ "$output" == *"incomplete -- see MISSING above"* ]]
}

@test "issue 0118: app-icons routes to tools/app-icons, which takes no arguments, and every other word reaches the built-in" {
  run_macos app-icons now
  [ "$status" -eq 1 ]
  [[ "$output" == *"app-icons takes no arguments, got: now"* ]] || fail "$output"
  run_macos app-verify now
  [ "$status" -eq 1 ]
  [[ "$output" == *"macos app-verify takes no arguments, got: now"* ]] || fail "$output"
  [ ! -e "$PROJ/bin/.devbin/cmd/macos" ] || fail "a project handler would shadow the built-in"
}

# --- the declaration (issue 0118) ---------------------------------------------

@test "issue 0118: macos: declares Menuz's own version, and stamp keys its Info.plist writes from the build's settings" {
  local plist="$UTILZ_HOME/native/macos/Menuz/Menuz/Info.plist" key
  [ "$(cfg_macos version_from)" = opt/menuz/VERSION ] || fail "version_from: $(cfg_macos version_from)"
  for key in "$(cfg_macos commit_stamp)" "$(cfg_macos kind_stamp)"; do
    [ -n "$key" ] || fail "a stamp key is not declared"
    # shellcheck disable=SC2016 # the plist holds the literal $(MENUZ_...
    grep -A1 "<key>$key</key>" "$plist" | grep -q '<string>$(MENUZ_' || fail "$key is not a stamp $plist writes"
  done
  [ "$(cfg_macos kind_value)" = release ] || fail "kind_value: $(cfg_macos kind_value)"
}

@test "issue 0118: macos.app and macos.build_root are menuz's own build places under XDG state" {
  local menuz="$UTILZ_HOME/opt/menuz/menuz"
  [ "$(cfg_macos build)" = "bin/utilz menuz build --release" ] || fail "build: $(cfg_macos build)"
  grep -q "printf '%s/build/macos\\\\n' \"\$(state_dir)\"" "$menuz" || fail "menuz's build_root moved; re-read macos.build_root"
  # shellcheck disable=SC2016 # the config holds the variable unexpanded
  [ "$(cfg_macos build_root)" = '${XDG_STATE_HOME}/menuz/build/macos' ] || fail "build_root: $(cfg_macos build_root)"
  [ "$(cfg_macos app)" = "$(cfg_macos build_root)/Build/Products/Release/Menuz.app" ] || fail "app: $(cfg_macos app)"
  [ -f "$UTILZ_HOME/$(cfg_macos entitlements)" ] || fail "no entitlements at $(cfg_macos entitlements)"
}

@test "issue 0106: lsregister's path and the bundle id have one home, the lib menuz sources, and macos.bundle_id equals it" {
  local lib="$UTILZ_HOME/opt/menuz/lib/launch-services.sh" f="$UTILZ_HOME/opt/menuz/menuz" id
  [ "$(grep -c 'LaunchServices.framework/Support/lsregister' "$lib")" -eq 1 ] || fail "the lib does not hold lsregister's path once"
  [ "$(grep -c '"com\.matthewsinclair\.utilz\.menuz"' "$lib")" -eq 1 ] || fail "the lib does not hold the bundle id once"
  ! grep -n 'LaunchServices.framework/Support/lsregister\|"com\.matthewsinclair\.utilz\.menuz"' "$f" ||
    fail "$f holds a literal the lib owns"
  grep -q 'opt/menuz/lib/launch-services\.sh' "$f" || fail "$f does not source the lib"
  id="$(sed -n 's/^MENUZ_BUNDLE_ID="\(.*\)"$/\1/p' "$lib")"
  [ -n "$id" ] || fail "no MENUZ_BUNDLE_ID in $lib"
  [ "$(cfg_macos bundle_id)" = "$id" ] || fail "macos.bundle_id is $(cfg_macos bundle_id), and the lib's MENUZ_BUNDLE_ID is $id"
}
