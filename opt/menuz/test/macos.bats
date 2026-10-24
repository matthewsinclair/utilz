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
# The signing half (WP-05) runs against fakes for every tool it would reach:
# security (the keychain: NO TEST READS OR WRITES THE REAL ONE), codesign,
# xcrun, spctl, ditto, xattr, plutil and gh, each recording its calls, and a
# fake bin/utilz in the fixture project standing in for `utilz menuz build`.
# They are set in setup for every test, so a test that forgets one still
# reaches no real tool.
#
# The fixture project is a git repository whose one commit carries an
# annotated tag, 2.14.0, its VERSION, as the release core tags a cut. So the
# stamps the fake bin/utilz gives, for `menuz stamps` and on the bundles its
# build makes, are the tag's own build unless a test moves HEAD or sets a
# knob (issue 0103).
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
  export HOME="$BATS_TEST_TMPDIR/home" XDG_STATE_HOME="$BATS_TEST_TMPDIR/state" USER=tester
  mkdir -p "$HOME"
  # This setup() replaces test_helper's, so it isolates the tools that keep
  # state as that one does: unison, gpg, and git's signing (issue 0091).
  isolate_tool_homes
  KC="$FAKES/keychain"
  mkdir -p "$KC"
  printf '0.1.0\n' >"$PROJ/opt-menuz-VERSION"
  mkdir -p "$PROJ/opt/menuz"
  mv "$PROJ/opt-menuz-VERSION" "$PROJ/opt/menuz/VERSION"
  printf '2.14.0\n' >"$PROJ/VERSION"
  printf '<plist/>\n' >"$PROJ/native/macos/Menuz/Menuz/Menuz.entitlements"
  PRODUCT="$XDG_STATE_HOME/menuz/build/macos/Build/Products/Release/Menuz.app"
  DIST="$XDG_STATE_HOME/menuz/build/macos/dist/Menuz.app"
  fake_tools
  fake_shim
  fixture_repo
}

# The fixture project as a cut leaves it (issue 0103): one commit, tagged with
# an annotated 2.14.0, the root VERSION, as the release core tags, so every
# --points-at and ^{commit} has to peel it. git signs nothing here
# (isolate_tool_homes), and the commit and the tag carry a fixture identity.
fixture_repo() {
  git -C "$PROJ" -c init.defaultBranch=main init -q
  git -C "$PROJ" add -A
  fixture_git commit -qm fixture
  fixture_git tag -a 2.14.0 -m 2.14.0
}

# git in the fixture project, as the fixture's author.
fixture_git() {
  git -C "$PROJ" -c user.name=fixture -c user.email=fixture@example.com "$@"
}

IDENTITY_NAME="Developer ID Application: Fixture Co (TEAM123)"

# The signing half's fakes. Their bodies are written literally into each fake
# and expand when the fake runs, so the single quotes are deliberate.
# shellcheck disable=SC2016
# Each records its calls, one per line, in
# $FAKES/<name>.calls. State they share lives in files under $FAKES.
fake_tools() {
  # security: generic passwords are files under $KC named by service;
  # identities are $FAKES/identities, verbatim, when it exists.
  write_fake security '
case "$1" in
  find-generic-password)
    while [ $# -gt 0 ]; do [ "$1" = -s ] && svc="$2"; shift; done
    [ -f "'"$KC"'/$svc" ] && cat "'"$KC"'/$svc" && exit 0
    exit 44 ;;
  find-identity)
    [ -f "'"$FAKES"'/identities" ] && cat "'"$FAKES"'/identities"
    exit 0 ;;
  add-generic-password)
    while [ $# -gt 0 ]; do case "$1" in -s) svc="$2" ;; -w) val="$2" ;; esac; shift; done
    printf "%s" "$val" >"'"$KC"'/$svc" ;;
esac'
  # codesign: -d prints $FAKES/codesign.desc; --verify exits $FAKES/verify.rc.
  printf 'Identifier=com.matthewsinclair.utilz.menuz\nTeamIdentifier=TEAM123\nCodeDirectory v=20500 size=1 flags=0x10000(runtime) hashes=1\n' >"$FAKES/codesign.desc"
  write_fake codesign '
case " $* " in
  *" -d "*) cat "'"$FAKES"'/codesign.desc" >&2 ;;
  *" --verify "*) exit "$(cat "'"$FAKES"'/verify.rc" 2>/dev/null || echo 0)" ;;
esac'
  # xcrun: notarytool submit prints $FAKES/notary.out; stapler staple marks
  # the bundle stapled, and validate reads the mark.
  printf 'Conducting pre-submission checks\n  id: 0b9c7f4e-1111-2222-3333-444455556666\n  status: Accepted\n' >"$FAKES/notary.out"
  write_fake xcrun '
case "$1 $2" in
  "notarytool submit") cat "'"$FAKES"'/notary.out" ;;
  "notarytool log") echo "the notary log" ;;
  "stapler staple") touch "'"$FAKES"'/stapled" ;;
  "stapler validate") [ -f "'"$FAKES"'/stapled" ] ;;
esac'
  write_fake spctl '
if [ -f "'"$FAKES"'/stapled" ]; then echo "source=Notarized Developer ID"; else echo "source=Unnotarized Developer ID"; exit 3; fi'
  # ditto: a copy, or a "zip" that is a tar of the parent-kept bundle.
  write_fake ditto '
case "$1" in
  -c) shift; while [ "${1#-}" != "$1" ]; do shift; done
      tar -C "$(dirname "$1")" -cf "$2" "$(basename "$1")" ;;
  -x) shift; while [ "${1#-}" != "$1" ]; do shift; done
      mkdir -p "$2" && tar -C "$2" -xf "$1" ;;
  *) mkdir -p "$(dirname "$2")" && cp -R "$1" "$2" ;;
esac'
  write_fake xattr ':'
  # plutil -extract KEY raw -o - PLIST, over a fixture Info.plist of KEY=value lines.
  write_fake plutil 'sed -n "s/^$2=//p" "$6" | grep . || exit 1'
  # gh: a release exists when $FAKES/release.<tag> does; it lists its assets.
  write_fake gh '
case "$1 $2" in
  "release view") [ -f "'"$FAKES"'/release.$3" ] && cat "'"$FAKES"'/release.$3" ;;
  "release upload") cp "$4" "'"$FAKES"'/uploaded.zip" ;;
esac'
}

write_fake() { # $1 name, $2 body
  printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >>"%s/%s.calls"\n%s\n' "$FAKES" "$1" "$2" >"$FAKES/$1"
  chmod +x "$FAKES/$1"
}

# The fixture project's bin/utilz. Its stamps come from the fixture repository
# as menuz's build_kind takes its own: HEAD's commit, and the kind release
# when a tag on HEAD is the one VERSION names, dev otherwise (a dirty tree is
# not modelled). `menuz stamps` prints them, and fails when $FAKES/stamps.fail
# is set. `menuz build --release` makes a Release bundle at opt/menuz/VERSION
# carrying them, or carrying $FAKES/build.commit and $FAKES/build.kind, which
# model a product another tree's build replaced after stamps was asked; it
# refuses as a shim without the verb does when $FAKES/no-build-verb is set.
fake_shim() {
  cat >"$PROJ/bin/utilz" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >>"$FAKES/utilz.calls"
commit="\$(git -C "$PROJ" rev-parse --short=8 HEAD)" || exit 1
tags="\$(git -C "$PROJ" tag --points-at HEAD)" || exit 1
kind=dev
if printf '%s\n' "\$tags" | grep -qxF "\$(cat "$PROJ/VERSION")"; then kind=release; fi
if [ "\$1 \$2" = "menuz stamps" ]; then
  if [ -f "$FAKES/stamps.fail" ]; then echo "menuz: git tag --points-at HEAD failed in $PROJ" >&2; exit 1; fi
  printf 'MENUZ_VERSION=%s\nMENUZ_BUILD=1\nMENUZ_COMMIT=%s\nMENUZ_SOURCE_TREE=fixture\nMENUZ_KIND=%s\n' "\$(cat "$PROJ/opt/menuz/VERSION")" "\$commit" "\$kind"
  exit 0
fi
if [ -f "$FAKES/no-build-verb" ]; then echo "menuz: unknown verb: 'build' (menuz --help names the verbs)" >&2; exit 2; fi
mkdir -p "$PRODUCT/Contents/MacOS"
printf 'CFBundleIdentifier=com.matthewsinclair.utilz.menuz\nCFBundleShortVersionString=%s\nCFBundleVersion=42\nCFBundleExecutable=Menuz\nLSUIElement=true\nMenuzCommit=%s\nMenuzKind=%s\n' "\$(cat "$PROJ/opt/menuz/VERSION")" "\$(cat "$FAKES/build.commit" 2>/dev/null || echo "\$commit")" "\$(cat "$FAKES/build.kind" 2>/dev/null || echo "\$kind")" >"$PRODUCT/Contents/Info.plist"
printf '#!/bin/sh\n' >"$PRODUCT/Contents/MacOS/Menuz"
chmod +x "$PRODUCT/Contents/MacOS/Menuz"
EOF
  chmod +x "$PROJ/bin/utilz"
}

store_creds_fixture() {
  printf 'dev@example.com' >"$KC/utilz.apple.APPLE_ID"
  printf 'hunter2-secret' >"$KC/utilz.apple.APPLE_APP_PASSWORD"
  printf 'TEAM123' >"$KC/utilz.apple.APPLE_TEAM_ID"
  printf '  1) ABCDEF "%s"\n     1 valid identities found\n' "$IDENTITY_NAME" >"$FAKES/identities"
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
  store_creds_fixture
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
  [[ "$output" == *"unknown macos subcommand: sign (try: app-icons doctor store-creds app-sign app-notarize app-verify publish)"* ]]
  run_macos app-icons now
  [ "$status" -eq 1 ]
  [[ "$output" == *"macos app-icons takes no arguments, got: now"* ]]
}

# --- the signing half (WP-05) -------------------------------------------------

@test "AC-05.3: with no credentials doctor says MISSING for each and for the identity, exit 1" {
  fake_rsvg
  run_macos doctor
  [ "$status" -eq 1 ]
  [[ "$output" == *"Developer ID          MISSING (no \"Developer ID Application\" identity in the login keychain)"* ]] || fail "$output"
  local k
  for k in APPLE_ID APPLE_APP_PASSWORD APPLE_TEAM_ID; do
    [[ "$output" == *"$k"*"MISSING (run: bin/devbin macos store-creds)"* ]] || fail "$k: $output"
  done
}

@test "AC-05.3: doctor says PRESENT and counts the identity, never printing a value or the identity whole" {
  fake_rsvg
  store_creds_fixture
  run_macos doctor
  [[ "$output" == *"Developer ID          1 found, team TEAM123"* ]] || fail "$output"
  [[ "$output" == *"test-sign             signs and verifies"* ]] || fail "$output"
  [ "$(printf '%s\n' "$output" | grep -c 'PRESENT$')" -eq 3 ]
  [[ "$output" != *"hunter2-secret"* && "$output" != *"dev@example.com"* ]]
  [[ "$output" != *"$IDENTITY_NAME"* ]]
  grep -q -- "--sign $IDENTITY_NAME " "$FAKES/codesign.calls"
}

@test "AC-05.3: doctor says FAILED when the listed identity cannot sign" {
  fake_rsvg
  store_creds_fixture
  printf '1' >"$FAKES/verify.rc"
  run_macos doctor
  [ "$status" -eq 1 ]
  [[ "$output" == *"test-sign             FAILED"* ]] || fail "$output"
}

@test "AC-05.3: app-notarize refuses without the notary credentials, before any submission" {
  printf '  1) ABCDEF "%s"\n' "$IDENTITY_NAME" >"$FAKES/identities"
  run_macos app-notarize
  [ "$status" -eq 1 ]
  [[ "$output" == *"notary credentials missing -- run: bin/devbin macos store-creds"* ]] || fail "$output"
  [ ! -e "$FAKES/xcrun.calls" ]
}

@test "AC-05.3: app-sign refuses without a Developer ID identity, before any build" {
  run_macos app-sign
  [ "$status" -eq 1 ]
  [[ "$output" == *"no Developer ID Application identity in the login keychain"* ]] || fail "$output"
  [ ! -e "$FAKES/utilz.calls" ]
}

@test "AC-05.3: app-sign refuses by name while utilz menuz has no build verb" {
  store_creds_fixture
  touch "$FAKES/no-build-verb"
  run_macos app-sign
  [ "$status" -eq 1 ]
  [[ "$output" == *"utilz menuz has no build verb yet (WP-05's shim), and app-sign builds only through it"* ]] || fail "$output"
  [ ! -e "$FAKES/codesign.calls" ]
}

@test "AC-05.3: app-sign builds through utilz menuz build --release, stages a copy, signs it with the runtime, reads it back" {
  store_creds_fixture
  run_macos app-sign
  [ "$status" -eq 0 ] || fail "exit $status: $output"
  [ "$(cat "$FAKES/utilz.calls")" = "$(printf 'menuz stamps\nmenuz build --release')" ]
  grep -qx -- "$PRODUCT $DIST" "$FAKES/ditto.calls"
  [ -x "$DIST/Contents/MacOS/Menuz" ]
  grep -qx -- "--force --options runtime --timestamp --entitlements $PROJ/native/macos/Menuz/Menuz/Menuz.entitlements --sign $IDENTITY_NAME $DIST" "$FAKES/codesign.calls" ||
    fail "$(cat "$FAKES/codesign.calls")"
  # Signed, then verified, then described: in that order.
  local order
  order="$(grep -n -- "--sign $IDENTITY_NAME $DIST\|--verify --strict --deep $DIST\|-d --verbose=2 $DIST" "$FAKES/codesign.calls" | cut -d: -f1 | tr '\n' ' ')"
  [ "$order" = "1 2 3 " ] || fail "codesign order: $order: $(cat "$FAKES/codesign.calls")"
  [[ "$output" == *"identifier            com.matthewsinclair.utilz.menuz"* ]]
  [[ "$output" == *"nested code signed    0"* ]]
  [[ "$output" != *"$IDENTITY_NAME"* ]]
  # issue 0103: what the build would be, said before it, and the stamps read
  # back off the signed bundle.
  local head
  head="$(git -C "$PROJ" rev-parse --short=8 HEAD)"
  [[ "$output" == *"next build            release at $head"* ]] || fail "$output"
  [[ "$output" == *"version               0.1.0 (build 42)"* ]] || fail "$output"
  [[ "$output" == *"commit                $head"* ]] || fail "$output"
  [[ "$output" == *"kind                  release"* ]] || fail "$output"
}

@test "AC-05.3: app-sign refuses a bundle that still carries the build's signature" {
  store_creds_fixture
  printf 'Identifier=Menuz\nTeamIdentifier=not set\nCodeDirectory flags=0x2(adhoc)\n' >"$FAKES/codesign.desc"
  run_macos app-sign
  [ "$status" -eq 1 ]
  [[ "$output" == *"the bundle is signed as 'Menuz', not com.matthewsinclair.utilz.menuz"* ]] || fail "$output"
}

@test "AC-05.3: app-notarize staples only an Accepted submission and checks a quarantined copy" {
  store_creds_fixture
  run_macos app-sign
  run_macos app-notarize
  [ "$status" -eq 0 ] || fail "exit $status: $output"
  grep -q "^notarytool submit .*Menuz.zip --apple-id dev@example.com --password hunter2-secret --team-id TEAM123 --wait$" "$FAKES/xcrun.calls"
  grep -qx "stapler staple $DIST" "$FAKES/xcrun.calls"
  [[ "$output" == *"Gatekeeper            quarantined copy accepted, source=Notarized Developer ID"* ]] || fail "$output"
  [[ "$output" != *"hunter2-secret"* ]]
}

@test "AC-05.3: app-notarize prints Apple's log and staples nothing when the submission is not Accepted" {
  store_creds_fixture
  run_macos app-sign
  printf '  id: 0b9c7f4e-1111-2222-3333-444455556666\n  status: Invalid\n' >"$FAKES/notary.out"
  run_macos app-notarize
  [ "$status" -eq 1 ]
  [[ "$output" == *"the notary log"* ]]
  [[ "$output" == *"notarisation was not Accepted (status: Invalid) -- nothing stapled"* ]] || fail "$output"
  if grep -q "stapler staple" "$FAKES/xcrun.calls"; then fail "stapled after an Invalid submission"; fi
}

# A signed, notarised dist bundle, the tag's own build.
notarised_dist() {
  store_creds_fixture
  (cd "$PROJ" && bin/devbin macos app-sign >/dev/null 2>&1) || fail "app-sign failed in the fixture"
  (cd "$PROJ" && bin/devbin macos app-notarize >/dev/null 2>&1) || fail "app-notarize failed in the fixture"
}

# One stamp of the dist bundle set to another value, after it was signed and
# notarised: a bundle publish meets that app-sign did not make (app-sign
# refuses to sign one; issue 0103).
dist_stamp() { # $1 key, $2 value
  local plist="$DIST/Contents/Info.plist"
  grep -q "^$1=" "$plist" || fail "no $1 in $plist"
  sed "s|^$1=.*|$1=$2|" "$plist" >"$plist.new" && mv "$plist.new" "$plist"
}

@test "AC-05.3: publish refuses a bundle whose version is not opt/menuz/VERSION, uploading nothing" {
  notarised_dist
  dist_stamp CFBundleShortVersionString 0.0.9
  touch "$FAKES/release.2.14.0"
  run_macos publish
  [ "$status" -eq 1 ]
  [[ "$output" == *"the bundle is version 0.0.9 and opt/menuz/VERSION is 0.1.0"* ]] || fail "$output"
  [ ! -e "$FAKES/uploaded.zip" ]
}

@test "AC-05.3: publish refuses when the release object for VERSION's tag does not exist" {
  notarised_dist
  run_macos publish
  [ "$status" -eq 1 ]
  [[ "$output" == *"there is no release object for 2.14.0"* ]] || fail "$output"
  [ ! -e "$FAKES/uploaded.zip" ]
}

@test "AC-05.3: publish refuses a release that already holds Menuz.app.zip" {
  notarised_dist
  printf 'utilz-2.14.0.tar.gz\nMenuz.app.zip\n' >"$FAKES/release.2.14.0"
  run_macos publish
  [ "$status" -eq 1 ]
  [[ "$output" == *"release 2.14.0 already holds Menuz.app.zip -- nothing uploaded"* ]] || fail "$output"
  [ ! -e "$FAKES/uploaded.zip" ]
}

@test "AC-05.3: publish proves the zip and uploads Menuz.app.zip to VERSION's release" {
  notarised_dist
  printf 'utilz-2.14.0.tar.gz\n' >"$FAKES/release.2.14.0"
  run_macos publish
  [ "$status" -eq 0 ] || fail "exit $status: $output"
  grep -q "^release upload 2.14.0 .*/Menuz.app.zip$" "$FAKES/gh.calls"
  tar -tf "$FAKES/uploaded.zip" | grep -qx "Menuz.app/Contents/Info.plist"
  [[ "$output" == *"published: Menuz.app.zip on release 2.14.0"* ]]
}

@test "AC-05.3: store-creds refuses a stdin that is not a terminal, storing nothing" {
  run bash -c "cd '$PROJ' && printf 'a\nb\nc\n' | bin/devbin macos store-creds"
  [ "$status" -eq 1 ]
  [[ "$output" == *"store-creds is interactive and reads the terminal; stdin is not one"* ]] || fail "$output"
  [ -z "$(ls "$KC")" ]
}

@test "AC-05.3: app-verify refuses an unknown config and a missing bundle by name" {
  run_macos app-verify bogus
  [ "$status" -eq 1 ]
  [[ "$output" == *"app-verify: unknown config 'bogus' (debug|release|dist)"* ]]
  run_macos app-verify release
  [ "$status" -eq 1 ]
  [[ "$output" == *"no Release bundle at $PRODUCT -- run: utilz menuz build --release"* ]] || fail "$output"
  run_macos app-verify
  [ "$status" -eq 1 ]
  [[ "$output" == *"no signed bundle at $DIST"* ]] || fail "$output"
}

@test "AC-05.3: app-verify passes a signed, notarised bundle" {
  notarised_dist
  run_macos app-verify
  [ "$status" -eq 0 ] || fail "exit $status: $output"
  [[ "$output" == *"LSUIElement           true"* ]]
  [[ "$output" == *"version               0.1.0 (build 42)"* ]] || fail "$output"
  [[ "$output" == *"kind                  release"* ]] || fail "$output"
  [[ "$output" == *"stapled ticket        present, validates"* ]]
}

# --- issue 0103: app-sign and publish take the release tag's build alone ----

@test "issue 0103: app-sign refuses off VERSION's tag before any build, naming the stamps, the tag and the route" {
  store_creds_fixture
  printf 'a record made after the cut\n' >"$PROJ/record.md"
  git -C "$PROJ" add record.md
  fixture_git commit -qm "a record after the tag"
  local head tagged
  head="$(git -C "$PROJ" rev-parse --short=8 HEAD)"
  tagged="$(git -C "$PROJ" rev-parse --short=8 '2.14.0^{commit}')"
  run_macos app-sign
  [ "$status" -eq 1 ]
  [[ "$output" == *"the build here would be MENUZ_KIND=dev at MENUZ_COMMIT=$head"* ]] || fail "$output"
  [[ "$output" == *"HEAD at the tag 2.14.0, which names $tagged, from a clean tree -- nothing built or signed"* ]] || fail "$output"
  [[ "$output" == *"git worktree add --detach <dir> 2.14.0"* ]] || fail "$output"
  [[ "$output" == *"cd <dir>, then bin/devbin macos app-sign, app-notarize and publish"* ]] || fail "$output"
  [[ "$output" == *"git worktree remove <dir>, once publish has run"* ]] || fail "$output"
  [ "$(cat "$FAKES/utilz.calls")" = "menuz stamps" ]
  [ ! -e "$FAKES/codesign.calls" ]
  [ ! -e "$DIST" ]
}

@test "issue 0103: app-sign stops before any build when utilz menuz stamps fails, naming it" {
  store_creds_fixture
  touch "$FAKES/stamps.fail"
  run_macos app-sign
  [ "$status" -eq 1 ]
  [[ "$output" == *"utilz menuz stamps failed, so app-sign cannot tell whether the build would be the release's -- nothing built or signed"* ]] || fail "$output"
  [ "$(cat "$FAKES/utilz.calls")" = "menuz stamps" ]
  [ ! -e "$FAKES/codesign.calls" ]
}

@test "issue 0103: app-sign refuses a staged copy that is not the release's build, signing nothing" {
  store_creds_fixture
  # menuz stamps says release; the product staged says dev, as one another
  # tree's build put in the shared products would.
  printf 'dev' >"$FAKES/build.kind"
  run_macos app-sign
  [ "$status" -eq 1 ]
  [[ "$output" == *"the staged Menuz.app cannot ship with release 2.14.0 -- nothing signed:"* ]] || fail "$output"
  [[ "$output" == *"the bundle's MenuzKind is dev, not release"* ]] || fail "$output"
  [ "$(cat "$FAKES/utilz.calls")" = "$(printf 'menuz stamps\nmenuz build --release')" ]
  [ ! -e "$FAKES/codesign.calls" ]
  [ ! -e "$DIST" ]
}

@test "issue 0103: the release core tags the root VERSION bare, as app-sign, publish and menuz's build_kind read it" {
  local cfg="$UTILZ_HOME/bin/.devbin/config.yaml" yq
  yq="$(PATH="$ORIGINAL_PATH_FOR_RSVG" command -v yq)" || fail "yq is not on PATH; this guard reads $cfg with it, as CI installs it"
  run "$yq" '.release.tag' "$cfg"
  [ "$status" -eq 0 ] || fail "yq could not read $cfg: $output"
  [ "$output" = "{version}" ] || fail "release.tag is '$output', not \"{version}\": app_release_tag and build_kind read the tag as the bare VERSION"
  run "$yq" '.project.version_from // "VERSION"' "$cfg"
  [ "$status" -eq 0 ] || fail "yq could not read $cfg: $output"
  [ "$output" = VERSION ] || fail "project.version_from is '$output', not VERSION: app_release_tag and build_kind read the root VERSION"
}

@test "issue 0103: publish refuses a bundle whose MenuzKind is not release, uploading nothing" {
  notarised_dist
  dist_stamp MenuzKind dev
  printf 'utilz-2.14.0.tar.gz\n' >"$FAKES/release.2.14.0"
  run_macos publish
  [ "$status" -eq 1 ]
  [[ "$output" == *"the bundle's MenuzKind is dev, not release -- it was built off the tag 2.14.0 or from a dirty tree; run app-sign and app-notarize in a tree at the tag"* ]] || fail "$output"
  [ ! -e "$FAKES/uploaded.zip" ]
}

@test "issue 0103: publish refuses a bundle whose MenuzCommit is not the commit VERSION's tag names, uploading nothing" {
  local tagged other
  tagged="$(git -C "$PROJ" rev-parse '2.14.0^{commit}')"
  # Each hex digit moved on by one, so it differs from the tag's at every place.
  other="$(printf '%s' "${tagged:0:8}" | tr '0-9a-f' '1-9a-f0')"
  notarised_dist
  dist_stamp MenuzCommit "$other"
  printf 'utilz-2.14.0.tar.gz\n' >"$FAKES/release.2.14.0"
  run_macos publish
  [ "$status" -eq 1 ]
  [[ "$output" == *"the bundle's MenuzCommit is $other and the tag 2.14.0 names ${tagged:0:8} -- it was built off the tag; run app-sign and app-notarize in a tree at the tag"* ]] || fail "$output"
  [ ! -e "$FAKES/uploaded.zip" ]
}

@test "issue 0103: publish refuses a MenuzCommit that is not 8 to 40 lowercase hex characters, though it begins the tag's commit" {
  local tagged stamp
  tagged="$(git -C "$PROJ" rev-parse '2.14.0^{commit}')"
  printf 'utilz-2.14.0.tar.gz\n' >"$FAKES/release.2.14.0"
  # Seven characters: one short of the floor, so a lowered floor turns it red.
  for stamp in "${tagged:0:7}" ""; do
    notarised_dist
    dist_stamp MenuzCommit "$stamp"
    run_macos publish
    [ "$status" -eq 1 ] || fail "the stamp '$stamp' was not refused: $output"
    [[ "$output" == *"the bundle's MenuzCommit is ${stamp:-<unreadable>}, not a commit of 8 to 40 lowercase hex characters, so it cannot be checked against the tag 2.14.0"* ]] || fail "$output"
    [[ "$output" != *"and the tag 2.14.0 names"* ]] || fail "the stamp '$stamp' was compared: $output"
    [ ! -e "$FAKES/uploaded.zip" ]
  done
}

@test "issue 0103: publish refuses when the tag VERSION names is not in the tree, uploading nothing" {
  notarised_dist
  git -C "$PROJ" tag -d 2.14.0 >/dev/null
  printf 'utilz-2.14.0.tar.gz\n' >"$FAKES/release.2.14.0"
  run_macos publish
  [ "$status" -eq 1 ]
  [[ "$output" == *"the tag 2.14.0 that VERSION names is not in this tree, so the bundle's commit cannot be checked against it"* ]] || fail "$output"
  [ ! -e "$FAKES/uploaded.zip" ]
}

@test "issue 0103: publish refuses, naming it, when the root VERSION is empty, uploading nothing" {
  notarised_dist
  : >"$PROJ/VERSION"
  printf 'utilz-2.14.0.tar.gz\n' >"$FAKES/release.2.14.0"
  run_macos publish
  [ "$status" -eq 1 ]
  [[ "$output" == *"$PROJ/VERSION could not be read or is empty, so the release tag is unknown"* ]] || fail "$output"
  [[ "$output" == *"no release tag to publish to -- nothing uploaded"* ]] || fail "$output"
  [ ! -e "$FAKES/gh.calls" ]
  [ ! -e "$FAKES/uploaded.zip" ]
}

@test "issue 0103: publish refuses a bundle when opt/menuz/VERSION is empty, rather than matching an empty version" {
  notarised_dist
  dist_stamp CFBundleShortVersionString ""
  : >"$PROJ/opt/menuz/VERSION"
  printf 'utilz-2.14.0.tar.gz\n' >"$FAKES/release.2.14.0"
  run_macos publish
  [ "$status" -eq 1 ]
  [[ "$output" == *"opt/menuz/VERSION could not be read or is empty, so the bundle's version <unreadable> cannot be checked against it"* ]] || fail "$output"
  [ ! -e "$FAKES/uploaded.zip" ]
}

@test "issue 0103: app-verify prints a build product's stamps: version, build, commit and kind" {
  (cd "$PROJ" && bin/utilz menuz build --release) || fail "the fixture build failed"
  run_macos app-verify release
  [ "$status" -eq 0 ] || fail "exit $status: $output"
  local head
  head="$(git -C "$PROJ" rev-parse --short=8 HEAD)"
  [[ "$output" == *"version               0.1.0 (build 42)"* ]] || fail "$output"
  [[ "$output" == *"commit                $head"* ]] || fail "$output"
  [[ "$output" == *"kind                  release"* ]] || fail "$output"
}
