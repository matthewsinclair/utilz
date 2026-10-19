#!/usr/bin/env bats
# menuz.bats - Tests for the menuz shim (ST0027)
#
# The shim, the config directory and the verbs that need no Xcode (WP-02).
# Each test names the AT it carries. NOTHING HERE REACHES THE REAL MACHINE:
# HOME and every XDG directory are fixtures under the test's own temp
# directory, the app is a fake bundle that records its arguments, and open,
# pgrep and tail are fakes on PATH where a verb would otherwise reach out.

# The fakes' bodies are written literally into each fake and expand when the
# fake runs, so their single quotes are deliberate.
# shellcheck disable=SC2016
load "../../utilz/test/test_helper.bash"

EXAMPLE="$UTILZ_HOME/opt/menuz/lib/example.yaml"

setup() {
  export HOME="$BATS_TEST_TMPDIR/home"
  export XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/config"
  export XDG_STATE_HOME="$BATS_TEST_TMPDIR/state"
  unset MENUZ_HOME VISUAL EDITOR
  mkdir -p "$HOME"
  CONFIG="$XDG_CONFIG_HOME/menuz"
  LOG="$XDG_STATE_HOME/menuz/menuz.log"
  INSTALLED="$HOME/Applications/Menuz.app"
  DEV="$XDG_STATE_HOME/menuz/build/macos/Build/Products/Debug/Menuz.app"
  FAKES="$BATS_TEST_TMPDIR/fakes"
  mkdir -p "$FAKES"
  # Every fake appends here, so a count of none is read from a file that
  # exists, never from a missing one.
  : >"$FAKES/calls"
  export PATH="$FAKES:$PATH"
  # pgrep finds no Menuz unless a test says otherwise.
  fake pgrep 'exit 1'
}

run_menuz() {
  run "$UTILZ_BIN_DIR/menuz" "$@"
}

# A command on PATH that records its arguments, one per line, in
# $FAKES/<name>.args, appends "<name> <args>" to $FAKES/calls so a sequence
# can be read in order, then runs BODY.
fake() {
  local name="$1" body="$2"
  cat >"$FAKES/$name" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$@" >"$FAKES/$name.args"
printf '%s %s\n' "$name" "\$*" >>"$FAKES/calls"
$body
EOF
  chmod +x "$FAKES/$name"
}

# A fake Menuz.app at BUNDLE: its binary records its arguments in
# $FAKES/app.args and as "app <args>" in $FAKES/calls, and answers from
# FAKE_APP_OUT and FAKE_APP_RC, for --login-item from FAKE_LOGIN, and for
# --unregister-login-item from FAKE_UNREGISTER_OUT and FAKE_UNREGISTER_RC;
# its Info.plist carries the bundle id and the stamps.
make_app() {
  local bundle="$1" version="${2:-0.1.0}" tree="${3:-abc123}" id="${4:-com.matthewsinclair.utilz.menuz}"
  mkdir -p "$bundle/Contents/MacOS"
  cat >"$bundle/Contents/MacOS/Menuz" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$@" >"$FAKES/app.args"
printf 'app %s\n' "\$*" >>"$FAKES/calls"
if [[ "\$1" == --login-item ]]; then
  printf '%s\n' "\${FAKE_LOGIN:-enabled}"
  exit 0
fi
if [[ "\$1" == --unregister-login-item ]]; then
  printf '%s\n' "\${FAKE_UNREGISTER_OUT:-unregistered (now not registered)}"
  exit "\${FAKE_UNREGISTER_RC:-0}"
fi
printf '%s\n' "\${FAKE_APP_OUT:-ok}"
exit "\${FAKE_APP_RC:-0}"
EOF
  chmod +x "$bundle/Contents/MacOS/Menuz"
  cat >"$bundle/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleIdentifier</key>
	<string>$id</string>
	<key>CFBundleShortVersionString</key>
	<string>$version</string>
	<key>CFBundleVersion</key>
	<string>42</string>
	<key>MenuzCommit</key>
	<string>deadbeef</string>
	<key>MenuzSourceTree</key>
	<string>$tree</string>
	<key>MenuzKind</key>
	<string>release</string>
</dict>
</plist>
EOF
}

app_args() { tr '\n' ' ' <"$FAKES/app.args"; }

# A fixture UTILZ_HOME that is a git repository: the real common.sh, shim and
# root VERSION, and native/macos/Menuz with one source and one test,
# committed. With
# --no-source it has no native/macos/Menuz. Status reads the source through
# git on UTILZ_HOME, so a test of it never reads the real tree, whose
# native/macos/Menuz exists from WP-03 on.
source_home() {
  SRC="$BATS_TEST_TMPDIR/src"
  mkdir -p "$SRC/opt/utilz/lib" "$SRC/opt/menuz/lib"
  cp "$UTILZ_HOME/opt/utilz/lib/common.sh" "$SRC/opt/utilz/lib/"
  cp "$UTILZ_HOME/opt/menuz/menuz" "$UTILZ_HOME/opt/menuz/VERSION" "$SRC/opt/menuz/"
  cp "$UTILZ_HOME/VERSION" "$SRC/"
  cp "$EXAMPLE" "$SRC/opt/menuz/lib/"
  if [[ "${1:-}" != --no-source ]]; then
    mkdir -p "$SRC/native/macos/Menuz/Menuz" "$SRC/native/macos/Menuz/MenuzTests"
    # The Xcode floor, as project.yml carries it: doctor reads it (issue 0073).
    printf 'name: Menuz\noptions:\n  xcodeVersion: "26.0"\n' >"$SRC/native/macos/Menuz/project.yml"
    echo 'print("menuz")' >"$SRC/native/macos/Menuz/Menuz/App.swift"
    echo 'test' >"$SRC/native/macos/Menuz/MenuzTests/AppTests.swift"
  fi
  git -C "$SRC" init -q
  git -C "$SRC" add -A
  git -C "$SRC" -c user.name=t -c user.email=t@t commit -qm fixture
}

run_src_menuz() {
  run env UTILZ_HOME="$SRC" "$SRC/opt/menuz/menuz" "$@"
}

# ============================================================================
# AT-02.1 -- dispatched, declared, listed (AC-02.1)
# ============================================================================

@test "AT-02.1: utilz menuz is dispatched and its help names every verb" {
  run_utilz menuz --help
  assert_success
  local verb
  for verb in init edit log validate render status --force --editor -n; do
    assert_output_contains "$verb"
  done
}

@test "AT-02.1: menuz with no verb prints usage and exits 2" {
  run_menuz
  assert_exit_code 2
  assert_output_contains "Usage: menuz"
}

@test "AT-02.1: an unknown verb is refused by name, exit 2" {
  run_menuz frobnicate
  assert_exit_code 2
  assert_output_contains "frobnicate"
}

@test "AT-02.1: VERSION is the one home of menuz's version" {
  run yq -r '.version_file' "$UTILZ_HOME/opt/menuz/menuz.yaml"
  assert_output "VERSION"
  run yq -r '.version // "none"' "$UTILZ_HOME/opt/menuz/menuz.yaml"
  assert_output "none"
  run_utilz menuz --version
  assert_success
  assert_output_contains "$(cat "$UTILZ_HOME/opt/menuz/VERSION")"
}

@test "AT-02.1: utilz list shows menuz" {
  run_utilz list
  assert_success
  assert_output_contains "menuz"
}

@test "AT-02.1: doctor reports xcodegen and Xcode only on macOS, when native/macos/Menuz is present" {
  source_home
  # A machine without them: xcodebuild is the stub every macOS carries, which
  # runs and fails without Xcode; xcodegen is installed here, so check_command
  # answers no for it alone.
  fake xcodebuild 'echo "xcode-select: error: tool requires Xcode" >&2; exit 1'
  # The single quotes are the point: $1 is check_command's argument in the
  # inner bash, and must reach it unexpanded.
  # shellcheck disable=SC2016
  local missing='check_command() { [[ "$1" == xcodegen ]] && return 1; command -v "$1" >/dev/null 2>&1; }'
  run /bin/bash -c "export UTILZ_HOME='$SRC'; source '$SRC/opt/utilz/lib/common.sh'; $missing; run_doctor"
  if [[ "$(uname -s)" == Darwin ]]; then
    assert_output_contains "brew install xcodegen"
    assert_output_contains "xcodebuild -version does not run"
  else
    refute_output_contains "xcodegen"
    refute_output_contains "Xcode"
  fi
  rm -rf "$SRC/native/macos/Menuz"
  run /bin/bash -c "export UTILZ_HOME='$SRC'; source '$SRC/opt/utilz/lib/common.sh'; $missing; run_doctor"
  refute_output_contains "xcodegen"
  refute_output_contains "xcodebuild -version"
}

@test "AT-02.1: doctor says nothing of Xcode when xcodebuild runs" {
  source_home
  fake xcodebuild 'echo "Xcode 26.0"; exit 0'
  run /bin/bash -c "export UTILZ_HOME='$SRC'; source '$SRC/opt/utilz/lib/common.sh'; run_doctor"
  refute_output_contains "xcodebuild -version does not run"
}

# ============================================================================
# AT-02.2 -- init, edit and log (AC-02.2)
# ============================================================================

@test "AT-02.2: init creates the config directory with the example menu and an empty bin/" {
  run_menuz init
  assert_success
  assert_output_contains "$CONFIG"
  cmp "$EXAMPLE" "$CONFIG/menuz.yaml"
  [[ -d "$CONFIG/bin" ]] || false
  [[ -z "$(ls -A "$CONFIG/bin")" ]] || false
}

@test "AT-02.2: the example menu declares no param type outside D4's five" {
  run yq -r '[.. | select(tag == "!!map" and has("params")) | .params[] | select(has("type")) | .type | select(test("^(text|secret|choice|file|folder)$") | not)] | length' "$EXAMPLE"
  assert_success
  assert_output "0"
}

@test "AT-02.2: init honours MENUZ_HOME over the XDG default" {
  export MENUZ_HOME="$BATS_TEST_TMPDIR/elsewhere"
  run_menuz init
  assert_success
  cmp "$EXAMPLE" "$MENUZ_HOME/menuz.yaml"
  [[ ! -e "$CONFIG" ]] || false
}

@test "AT-02.2: a second init changes nothing" {
  run_menuz init
  touch -t 202001010000 "$CONFIG/menuz.yaml" "$CONFIG/bin"
  touch "$BATS_TEST_TMPDIR/mark"
  run_menuz init
  assert_success
  assert_output_contains "nothing changed"
  [[ ! "$CONFIG/menuz.yaml" -nt "$BATS_TEST_TMPDIR/mark" ]] || false
  [[ ! "$CONFIG/bin" -nt "$BATS_TEST_TMPDIR/mark" ]] || false
}

@test "AT-02.2: init refuses to overwrite a menu of the user's own without --force, exit 2, naming the file" {
  mkdir -p "$CONFIG"
  echo "menu: [ { label: mine } ]" >"$CONFIG/menuz.yaml"
  run_menuz init
  assert_exit_code 2
  assert_output_contains "$CONFIG/menuz.yaml"
  assert_output_contains "--force"
  grep -q mine "$CONFIG/menuz.yaml"
}

@test "AT-02.2: init --force overwrites the menu and keeps bin/" {
  mkdir -p "$CONFIG/bin"
  echo "menu: [ { label: mine } ]" >"$CONFIG/menuz.yaml"
  echo "#!/bin/sh" >"$CONFIG/bin/mine"
  run_menuz init --force
  assert_success
  cmp "$EXAMPLE" "$CONFIG/menuz.yaml"
  [[ -f "$CONFIG/bin/mine" ]] || false
}

@test "AT-02.2: edit opens the menu with open -t" {
  run_menuz init
  fake open 'exit 0'
  run_menuz edit
  assert_success
  [[ "$(tr '\n' ' ' <"$FAKES/open.args")" == "-t $CONFIG/menuz.yaml " ]] || false
}

@test "AT-02.2: edit --editor runs \$VISUAL, else \$EDITOR" {
  run_menuz init
  fake vis 'exit 0'
  fake ed 'exit 0'
  VISUAL='vis' EDITOR='ed' run_menuz edit --editor
  assert_success
  [[ "$(cat "$FAKES/vis.args")" == "$CONFIG/menuz.yaml" ]] || false
  [[ ! -e "$FAKES/ed.args" ]] || false
  EDITOR='ed' run_menuz edit --editor
  assert_success
  [[ "$(cat "$FAKES/ed.args")" == "$CONFIG/menuz.yaml" ]] || false
}

@test "AT-02.2: edit --editor with neither \$VISUAL nor \$EDITOR is refused, exit 2" {
  run_menuz init
  run_menuz edit --editor
  assert_exit_code 2
  assert_output_contains "VISUAL"
}

@test "AT-02.2: edit with no menu is refused by name, exit 2" {
  fake open 'exit 0'
  run_menuz edit
  assert_exit_code 2
  assert_output_contains "$CONFIG/menuz.yaml"
  [[ ! -e "$FAKES/open.args" ]] || false
}

@test "AT-02.2: log with no log yet is refused by name, exit 2" {
  run_menuz log
  assert_exit_code 2
  assert_output_contains "$LOG"
}

@test "AT-02.2: log prints the log's path, then follows it with tail -f" {
  mkdir -p "$(dirname "$LOG")"
  echo "one" >"$LOG"
  fake tail 'exit 0'
  run_menuz log
  assert_success
  assert_output_contains "$LOG"
  [[ "$(tr '\n' ' ' <"$FAKES/tail.args")" == "-f $LOG " ]] || false
}

@test "AT-02.2: log -n N prints the last N lines and does not follow" {
  mkdir -p "$(dirname "$LOG")"
  printf 'one\ntwo\nthree\nfour\n' >"$LOG"
  run_menuz log -n 2
  assert_success
  assert_output_contains "$LOG"
  assert_output_contains "three"
  assert_output_contains "four"
  refute_output_contains "two"
}

@test "AT-02.2: log -n that is not a count is refused, exit 2" {
  mkdir -p "$(dirname "$LOG")"
  echo "one" >"$LOG"
  run_menuz log -n many
  assert_exit_code 2
  assert_output_contains "many"
}

# ============================================================================
# AT-02.3 -- validate, render and status (AC-02.3)
# ============================================================================

@test "AT-02.3: validate runs the installed app's --validate on the menu and passes its output and exit through" {
  run_menuz init
  make_app "$INSTALLED"
  FAKE_APP_OUT="menu[2].label: refused" FAKE_APP_RC=2 run_menuz validate
  assert_exit_code 2
  assert_output_contains "menu[2].label: refused"
  [[ "$(app_args)" == "--validate $CONFIG/menuz.yaml " ]] || false
}

@test "AT-02.3: validate on a given file passes that file" {
  make_app "$INSTALLED"
  echo "menu: []" >"$BATS_TEST_TMPDIR/other.yaml"
  run_menuz validate "$BATS_TEST_TMPDIR/other.yaml"
  assert_success
  assert_output_contains "ok"
  [[ "$(app_args)" == "--validate $BATS_TEST_TMPDIR/other.yaml " ]] || false
}

@test "AT-02.3: validate on a file that does not exist is refused by name, exit 2" {
  make_app "$INSTALLED"
  run_menuz validate "$BATS_TEST_TMPDIR/nope.yaml"
  assert_exit_code 2
  assert_output_contains "$BATS_TEST_TMPDIR/nope.yaml"
  [[ ! -e "$FAKES/app.args" ]] || false
}

@test "AT-02.3: render runs the dev build when nothing is installed" {
  run_menuz init
  make_app "$DEV"
  FAKE_APP_OUT="  Desks" run_menuz render
  assert_success
  assert_output_contains "  Desks"
  [[ "$(app_args)" == "--render $CONFIG/menuz.yaml " ]] || false
}

@test "AT-02.3: use's record selects the dev build over an installed one" {
  run_menuz init
  make_app "$INSTALLED"
  make_app "$DEV"
  rm "$INSTALLED/Contents/MacOS/Menuz"
  echo dev >"$XDG_STATE_HOME/menuz/use"
  run_menuz validate
  assert_success
  [[ "$(app_args)" == "--validate $CONFIG/menuz.yaml " ]] || false
}

@test "AT-02.3: a use record that names neither build is refused, exit 2, and no app runs" {
  run_menuz init
  make_app "$INSTALLED"
  mkdir -p "$XDG_STATE_HOME/menuz"
  echo bogus >"$XDG_STATE_HOME/menuz/use"
  local verb
  for verb in validate render status; do
    run_menuz "$verb"
    assert_exit_code 2
    assert_output_contains "bogus"
  done
  [[ ! -e "$FAKES/app.args" ]] || false
}

@test "AT-02.3: with no app built or installed, validate and render are refused, exit 2, naming both builds" {
  run_menuz init
  local verb
  for verb in validate render; do
    run_menuz "$verb"
    assert_exit_code 2
    assert_output_contains "$INSTALLED"
    assert_output_contains "$DEV"
  done
}

@test "AT-02.3: status reports not installed, exit 1, naming where it looked" {
  run_menuz status
  assert_exit_code 1
  assert_output_contains "not installed"
  assert_output_contains "$INSTALLED"
}

@test "AT-02.3: with no use record, use selects the installed build, even with only a dev build" {
  make_app "$DEV"
  run_menuz status
  assert_output_contains "use         installed (default)"
}

@test "AT-02.3: status reports installed, use, running, login item and source, with no Xcode" {
  source_home
  make_app "$INSTALLED" 0.3.1
  fake pgrep 'echo 4242'
  fake xcodebuild 'echo "xcodebuild must not run" >&2; exit 99'
  FAKE_LOGIN="requires approval" run_src_menuz status
  assert_success
  assert_output_contains "$INSTALLED"
  assert_output_contains "0.3.1"
  assert_output_contains "build 42"
  assert_output_contains "deadbee"
  assert_output_contains "installed (default)"
  assert_output_contains "4242"
  assert_output_contains "requires approval"
  printf '%s\n' "$output" | grep -Eq '^source      stale: installed [^,]+, tree [0-9a-f]{7,}$'
  [[ ! -e "$FAKES/xcodebuild.args" ]] || false
}

@test "AT-02.3: status says not running, and names use's record when there is one" {
  make_app "$INSTALLED"
  mkdir -p "$XDG_STATE_HOME/menuz"
  echo installed >"$XDG_STATE_HOME/menuz/use"
  run_menuz status
  assert_success
  assert_output_contains "running     no"
  assert_output_contains "installed (by $XDG_STATE_HOME/menuz/use)"
}

@test "AT-02.3: status compares the installed source stamp with the tree's: current, stale, dirty" {
  source_home
  make_app "$INSTALLED"
  # The fake app's stamp is a placeholder, so the tree's is read from status's
  # own account and written into the bundle: current.
  run_src_menuz status
  assert_output_contains "stale"
  local tree
  tree="$(printf '%s\n' "$output" | sed -n 's/.*tree \([0-9a-f-]*\).*/\1/p')"
  [[ -n "$tree" ]] || false
  make_app "$INSTALLED" 0.1.0 "$tree"
  run_src_menuz status
  assert_output_contains "current"
  # A test-only change leaves it current; a source change makes it dirty.
  echo 'more' >>"$SRC/native/macos/Menuz/MenuzTests/AppTests.swift"
  run_src_menuz status
  assert_output_contains "current"
  echo 'print("changed")' >>"$SRC/native/macos/Menuz/Menuz/App.swift"
  run_src_menuz status
  assert_output_contains "stale"
  assert_output_contains "-dirty"
}

@test "AT-02.3: status says the source is unknown where there is no native/macos/Menuz" {
  source_home --no-source
  make_app "$INSTALLED"
  run_src_menuz status
  assert_success
  assert_output_contains "source      unknown: no $SRC/native/macos/Menuz under git here"
}

@test "AT-02.3: status reads the login item through the selected app, and says when it cannot" {
  make_app "$INSTALLED"
  rm "$INSTALLED/Contents/MacOS/Menuz"
  run_menuz status
  assert_output_contains "login item  unknown: no app"
}

@test "AT-02.3: status says so when the app's --login-item fails" {
  make_app "$INSTALLED"
  printf '#!/usr/bin/env bash\necho "SMAppService unavailable" >&2\nexit 3\n' >"$INSTALLED/Contents/MacOS/Menuz"
  run_menuz status
  assert_success
  assert_output_contains "login item  unknown"
  assert_output_contains "SMAppService unavailable"
}

@test "AT-02.3: status says running is unknown when pgrep fails" {
  make_app "$INSTALLED"
  fake pgrep 'echo "pgrep: cannot read the process table" >&2; exit 3'
  run_menuz status
  assert_output_contains "running     unknown"
  assert_output_contains "cannot read the process table"
}

@test "AT-02.3: status says so when the installed Info.plist cannot be read" {
  make_app "$INSTALLED"
  rm "$INSTALLED/Contents/Info.plist"
  run_menuz status
  assert_success
  assert_output_contains "could not be read"
}

# ============================================================================
# AT-05.1 -- build, test, stamps, install, use, uninstall, start, stop,
# restart and doctor (AC-05.1, WP-05). Xcode, xcodegen, Launch Services,
# open, osascript, curl, ditto, codesign and spctl are fakes on PATH: nothing
# here builds, signs, registers or launches anything.
# ============================================================================

BUILD_ROOT_REL="menuz/build/macos"

# Xcode and xcodegen present. xcodebuild -version answers; any other call
# makes the product under SYMROOT/<configuration> from a template bundle of
# version 0.1.0, prints FAKE_XCODEBUILD_ERRORS compiler error lines (default
# none) and a fatal one when there are any, then 100 numbered lines, and exits
# FAKE_XCODEBUILD_RC (default 0). xcodegen makes Menuz.xcodeproj where it runs.
xcode_fakes() {
  make_app "$FAKES/template.app" 0.1.0
  fake xcodegen 'mkdir -p Menuz.xcodeproj'
  fake xcodebuild '
if [[ "$1" == -version ]]; then
  printf "Xcode 26.0\nBuild version 17A100\n"
  exit 0
fi
sym="" cfg="" prev=""
for a in "$@"; do
  case "$a" in SYMROOT=*) sym="${a#SYMROOT=}" ;; esac
  if [[ "$prev" == -configuration ]]; then cfg="$a"; fi
  prev="$a"
done
for ((i = 1; i <= ${FAKE_XCODEBUILD_ERRORS:-0}; i++)); do
  echo "/src/MenuLoader.swift:$i:5: error: cannot call value of non-function type (e$i)"
done
if [[ "${FAKE_XCODEBUILD_ERRORS:-0}" -gt 0 ]]; then
  echo "<unknown>:0: fatal error: the compiler gave up"
fi
mkdir -p "${sym:?}/${cfg:?}"
rm -rf "${sym:?}/${cfg:?}/Menuz.app"
cp -R "'"$FAKES"'/template.app" "$sym/$cfg/Menuz.app"
seq 1 100 | sed "s/^/line /"
exit "${FAKE_XCODEBUILD_RC:-0}"'
  fake xcode-select 'echo /Applications/Xcode.app/Contents/Developer'
}

# Only the system's own directories after the fakes, so a real xcodegen
# (Homebrew's) cannot answer for a missing one.
system_path_only() {
  export PATH="$FAKES:/usr/bin:/bin:/usr/sbin:/sbin"
}

# Menuz running as pid 4242 until the fake osascript is asked to quit it.
running_app() {
  echo 4242 >"$FAKES/running"
  fake pgrep "if [[ -f '$FAKES/running' ]]; then cat '$FAKES/running'; else exit 1; fi"
  fake osascript "rm -f '$FAKES/running'"
}

# Launch Services, open and ditto, recording; ditto copies as ditto does.
launch_fakes() {
  fake lsregister 'exit 0'
  fake open 'env >"'"$FAKES"'/open.env"'
  fake ditto 'cp -R "$1" "$2"'
}

# A fixture install tree: what a keg or a publish holds, with
# manifest.sha256 at its root, the release VERSION, and no native/macos.
keg_home() {
  source_home --no-source
  touch "$SRC/manifest.sha256"
  echo 2.14.0 >"$SRC/VERSION"
}

# The release asset's fakes: curl writes a zip (or exits FAKE_CURL_RC), ditto
# -x unpacks ASSET (a Menuz.app made here at the menuz VERSION unless the test
# makes its own), codesign exits FAKE_CODESIGN_RC, spctl names
# FAKE_SPCTL_SOURCE.
asset_fakes() {
  ASSET="$BATS_TEST_TMPDIR/asset"
  make_app "$ASSET/Menuz.app" "$(cat "$SRC/opt/menuz/VERSION")"
  fake curl '
out="" prev=""
for a in "$@"; do
  if [[ "$prev" == -o ]]; then out="$a"; fi
  prev="$a"
done
if [[ -n "${FAKE_CURL_RC:-}" ]]; then
  echo "curl: (22) The requested URL returned error: 404" >&2
  exit "$FAKE_CURL_RC"
fi
echo zip >"$out"'
  fake ditto '
if [[ "$1" == -x ]]; then
  cp -R "'"$ASSET"'/Menuz.app" "$4/"
else
  cp -R "$1" "$2"
fi'
  fake codesign 'exit "${FAKE_CODESIGN_RC:-0}"'
  fake spctl 'echo "${*: -1}: accepted"; echo "source=${FAKE_SPCTL_SOURCE:-Notarized Developer ID}"'
  fake lsregister 'exit 0'
  fake open 'exit 0'
}

# A Menuz.app of another VERSION or bundle id in place of the asset.
replace_asset() {
  rm -rf "${ASSET:?}/Menuz.app"
  make_app "$ASSET/Menuz.app" "$@"
}

# The calls whose first word is one of the given names, in order, each line
# cut to its first two words: "<name> <first arg>".
calls_of() {
  local pattern
  pattern="^($(printf '%s|' "$@" | sed 's/|$//')) "
  grep -E "$pattern" "$FAKES/calls" | awk '{ print $1, $2 }'
}

# How many calls start with NAME; grep's exit 1 is a count of none, and any
# other failure prints a word no -eq can compare, so the test fails.
count_calls() {
  local n rc=0
  n="$(grep -c "^$1 " "$FAKES/calls")" || rc=$?
  if [[ $rc -gt 1 ]]; then
    echo "count_calls: grep exited $rc"
    return 1
  fi
  printf '%s\n' "$n"
}

xcodebuild_call() {
  grep -E '^xcodebuild -project' "$FAKES/calls" | tail -1
}

app_count() {
  find "$HOME/Applications" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' '
}

@test "AT-05.1: the shim's usage names every verb and flag WP-05 adds" {
  # menuz with no verb prints the shim's own usage; --help is the
  # dispatcher's, which shows help/menuz.md.
  run_menuz
  assert_exit_code 2
  local word
  for word in build test stamps install use uninstall start stop restart doctor --release --unsigned dev installed; do
    assert_output_contains "$word"
  done
}

# --- build -------------------------------------------------------------------

@test "AT-05.1: build runs xcodegen, then xcodebuild Debug with every location setting under XDG state" {
  source_home
  xcode_fakes
  run_src_menuz build
  assert_success
  local root="$XDG_STATE_HOME/$BUILD_ROOT_REL" call
  call="$(xcodebuild_call)"
  [[ "$call" == *"-project $SRC/native/macos/Menuz/Menuz.xcodeproj -scheme Menuz -configuration Debug "* ]] || false
  [[ "$call" == *" -derivedDataPath $root "* ]] || false
  [[ "$call" == *" SYMROOT=$root/Build/Products "* ]] || false
  [[ "$call" == *" OBJROOT=$root/Build/Intermediates.noindex "* ]] || false
  [[ "$call" == *" SHARED_PRECOMPS_DIR=$root/Build/Intermediates.noindex/PrecompiledHeaders "* ]] || false
  [[ "$call" == *" build" ]] || false
  [[ "$call" != *CODE_SIGNING_ALLOWED* ]] || false
  [[ "$(count_calls xcodegen)" -eq 1 ]] || false
  [[ -x "$DEV/Contents/MacOS/Menuz" ]] || false
  assert_output_contains "$DEV"
}

@test "AT-05.1: build passes the five stamps as build settings" {
  source_home
  xcode_fakes
  run_src_menuz build
  assert_success
  local call commit
  call="$(xcodebuild_call)"
  commit="$(git -C "$SRC" rev-parse --short=8 HEAD)"
  [[ "$call" == *" MENUZ_VERSION=$(cat "$SRC/opt/menuz/VERSION") "* ]] || false
  [[ "$call" == *" MENUZ_BUILD=1 "* ]] || false
  [[ "$call" == *" MENUZ_COMMIT=$commit "* ]] || false
  printf '%s\n' "$call" | grep -Eq ' MENUZ_SOURCE_TREE=[0-9a-f]{40}(-dirty)? '
  [[ "$call" == *" MENUZ_KIND=dev "* ]] || false
}

@test "AT-05.1: build --release builds Release, where app-sign reads it" {
  source_home
  xcode_fakes
  run_src_menuz build --release
  assert_success
  [[ "$(xcodebuild_call)" == *" -configuration Release "* ]] || false
  [[ -x "$XDG_STATE_HOME/$BUILD_ROOT_REL/Build/Products/Release/Menuz.app/Contents/MacOS/Menuz" ]] || false
}

@test "AT-05.1: build --unsigned adds CODE_SIGNING_ALLOWED=NO" {
  source_home
  xcode_fakes
  run_src_menuz build --unsigned
  assert_success
  [[ "$(xcodebuild_call)" == *" CODE_SIGNING_ALLOWED=NO "* ]] || false
}

@test "AT-05.1: build refuses an unknown argument, exit 2, running nothing" {
  source_home
  xcode_fakes
  run_src_menuz build --fast
  assert_exit_code 2
  assert_output_contains "--fast"
  [[ "$(count_calls xcodegen)" -eq 0 ]] || false
}

@test "AT-05.1: a second build runs no xcodegen; a changed project.yml, an added source or a missing project does" {
  source_home
  xcode_fakes
  run_src_menuz build
  assert_success
  [[ -f "$XDG_STATE_HOME/menuz/build/xcodegen.hash" ]] || false
  run_src_menuz build
  assert_success
  [[ "$(count_calls xcodegen)" -eq 1 ]] || false
  # A changed source is Xcode's business, not xcodegen's.
  echo 'print("more")' >>"$SRC/native/macos/Menuz/Menuz/App.swift"
  run_src_menuz build
  [[ "$(count_calls xcodegen)" -eq 1 ]] || false
  echo 'targets: {}' >>"$SRC/native/macos/Menuz/project.yml"
  run_src_menuz build
  [[ "$(count_calls xcodegen)" -eq 2 ]] || false
  echo 'struct New {}' >"$SRC/native/macos/Menuz/Menuz/New.swift"
  run_src_menuz build
  [[ "$(count_calls xcodegen)" -eq 3 ]] || false
  run_src_menuz build
  [[ "$(count_calls xcodegen)" -eq 3 ]] || false
  rm -rf "${SRC:?}/native/macos/Menuz/Menuz.xcodeproj"
  run_src_menuz build
  assert_success
  [[ "$(count_calls xcodegen)" -eq 4 ]] || false
}

@test "AT-05.1: a failed xcodebuild is exit 1 with its last 40 lines" {
  source_home
  xcode_fakes
  FAKE_XCODEBUILD_RC=65 run_src_menuz build
  assert_exit_code 1
  printf '%s\n' "$output" | grep -qx 'line 100'
  printf '%s\n' "$output" | grep -qx 'line 61'
  run grep -cx 'line 60' <<<"$output"
  assert_output "0"
}

@test "AT-05.1: a failed xcodebuild prints the log's error lines above its last 40, the first 20 and a count of the rest" {
  source_home
  xcode_fakes
  FAKE_XCODEBUILD_ERRORS=23 FAKE_XCODEBUILD_RC=65 run_src_menuz build
  assert_exit_code 1
  assert_output_contains "menuz: the log's error lines:"
  printf '%s\n' "$output" | grep -qx '/src/MenuLoader.swift:1:5: error: cannot call value of non-function type (e1)'
  printf '%s\n' "$output" | grep -qx '/src/MenuLoader.swift:20:5: error: cannot call value of non-function type (e20)'
  [[ "$(grep -c 'non-function type (e21)' <<<"$output")" -eq 0 ]] || false
  # 23 errors and the fatal one: 20 shown, 4 counted.
  assert_output_contains "and 4 more error lines in $XDG_STATE_HOME/menuz/build/xcodebuild-build.log"
  # The error lines come before the tail, which is still the last 40.
  local first_error tail_start
  first_error="$(printf '%s\n' "$output" | grep -n '(e1)$' | head -1 | cut -d: -f1)"
  tail_start="$(printf '%s\n' "$output" | grep -nx 'line 61' | cut -d: -f1)"
  [[ "$first_error" -lt "$tail_start" ]] || false
  printf '%s\n' "$output" | grep -qx 'line 100'
}

@test "AT-05.1: a failed xcodebuild with no error lines prints only its last 40" {
  source_home
  xcode_fakes
  FAKE_XCODEBUILD_RC=65 run_src_menuz build
  assert_exit_code 1
  refute_output_contains "error lines:"
  refute_output_contains "more error lines"
}

@test "AT-05.1: a failed xcodegen is exit 1 naming it, and no xcodebuild runs" {
  source_home
  xcode_fakes
  fake xcodegen 'echo "spec is invalid" >&2; exit 1'
  run_src_menuz build
  assert_exit_code 1
  assert_output_contains "xcodegen"
  assert_output_contains "spec is invalid"
  [[ -z "$(xcodebuild_call)" ]] || false
  [[ ! -f "$XDG_STATE_HOME/menuz/build/xcodegen.hash" ]] || false
}

@test "AT-05.1: build, test and install refuse without Xcode, exit 2, naming it" {
  source_home
  xcode_fakes
  fake xcodebuild 'echo "xcode-select: error: tool xcodebuild requires Xcode" >&2; exit 1'
  local verb
  for verb in build test install; do
    run_src_menuz "$verb"
    assert_exit_code 2
    assert_output_contains "Xcode"
  done
  [[ "$(count_calls xcodegen)" -eq 0 ]] || false
  [[ "$(count_calls osascript)" -eq 0 ]] || false
}

@test "AT-05.1: build, test and install refuse without xcodegen, exit 2, naming it" {
  source_home
  xcode_fakes
  rm "$FAKES/xcodegen"
  system_path_only
  local verb
  for verb in build test install; do
    run_src_menuz "$verb"
    assert_exit_code 2
    assert_output_contains "xcodegen"
  done
  [[ -z "$(xcodebuild_call)" ]] || false
}

@test "AT-05.1: build, test and install refuse without the source tree, exit 2, naming it" {
  source_home --no-source
  xcode_fakes
  local verb
  for verb in build test install; do
    run_src_menuz "$verb"
    assert_exit_code 2
    assert_output_contains "$SRC/native/macos/Menuz"
  done
}

@test "AT-05.1: in an install, build and test refuse by name, exit 2, naming the source clone" {
  keg_home
  xcode_fakes
  local verb
  for verb in build test; do
    run_src_menuz "$verb"
    assert_exit_code 2
    assert_output_contains "git clone https://github.com/matthewsinclair/utilz"
  done
  [[ -z "$(xcodebuild_call)" ]] || false
}

# --- test --------------------------------------------------------------------

@test "AT-05.1: test runs xcodebuild test of the scheme with the same locations" {
  source_home
  xcode_fakes
  run_src_menuz test --unsigned
  assert_success
  local call root="$XDG_STATE_HOME/$BUILD_ROOT_REL"
  call="$(xcodebuild_call)"
  [[ "$call" == *"-scheme Menuz "* ]] || false
  [[ "$call" == *" SYMROOT=$root/Build/Products "* ]] || false
  [[ "$call" == *" CODE_SIGNING_ALLOWED=NO "* ]] || false
  [[ "$call" == *" test" ]] || false
}

@test "AT-05.1: a red test is exit 1" {
  source_home
  xcode_fakes
  FAKE_XCODEBUILD_RC=65 run_src_menuz test
  assert_exit_code 1
  printf '%s\n' "$output" | grep -qx 'line 100'
}

# --- stamps ------------------------------------------------------------------

@test "AT-05.1: stamps prints what the next build stamps, one NAME=value a line" {
  source_home
  run_src_menuz stamps
  assert_success
  local tree
  tree="$(printf '%s\n' "$output" | sed -n 's/^MENUZ_SOURCE_TREE=//p')"
  [[ "$tree" =~ ^[0-9a-f]{40}$ ]] || false
  assert_output_contains "MENUZ_VERSION=$(cat "$SRC/opt/menuz/VERSION")"
  assert_output_contains "MENUZ_BUILD=1"
  assert_output_contains "MENUZ_COMMIT=$(git -C "$SRC" rev-parse --short=8 HEAD)"
  assert_output_contains "MENUZ_KIND=dev"
  [[ "$(printf '%s\n' "$output" | grep -c '^MENUZ_[A-Z_]*=')" -eq 5 ]] || false
  # The tree's stamp is the one status compares (WP-02's source_stamp).
  make_app "$INSTALLED" 0.1.0 "$tree"
  run_src_menuz status
  assert_output_contains "source      current (tree $tree)"
  echo 'print("changed")' >>"$SRC/native/macos/Menuz/Menuz/App.swift"
  run_src_menuz stamps
  printf '%s\n' "$output" | grep -Eq '^MENUZ_SOURCE_TREE=[0-9a-f]{40}-dirty$'
}

@test "AT-05.1: in an install, stamps prints what the installed bundle carries, and says so" {
  keg_home
  make_app "$INSTALLED" 2.0.1 feed42
  run_src_menuz stamps
  assert_success
  assert_output_contains "MENUZ_VERSION=2.0.1"
  assert_output_contains "MENUZ_BUILD=42"
  assert_output_contains "MENUZ_COMMIT=deadbeef"
  assert_output_contains "MENUZ_SOURCE_TREE=feed42"
  assert_output_contains "MENUZ_KIND=release"
  assert_output_contains "$INSTALLED"
}

@test "AT-05.1: in an install with nothing installed, stamps is refused by name, exit 2" {
  keg_home
  run_src_menuz stamps
  assert_exit_code 2
  assert_output_contains "$INSTALLED"
}

# --- install, from a source clone ---------------------------------------------

@test "AT-05.1: install builds Release, quits, replaces, unclaims, registers and launches, in that order" {
  source_home
  xcode_fakes
  launch_fakes
  running_app
  make_app "$INSTALLED" 0.0.9
  run_src_menuz install
  assert_success
  local release="$XDG_STATE_HOME/$BUILD_ROOT_REL/Build/Products/Release/Menuz.app"
  [[ "$(xcodebuild_call)" == *" -configuration Release "* ]] || false
  [[ "$(calls_of osascript ditto lsregister open | tr '\n' '|')" == "osascript -l|ditto $release|lsregister -u|lsregister -f|open -a|" ]] || false
  grep -qx "lsregister -u $release" "$FAKES/calls"
  grep -qx "lsregister -f $INSTALLED" "$FAKES/calls"
  grep -qx "open -a $INSTALLED" "$FAKES/calls"
  grep -q "com.matthewsinclair.utilz.menuz" "$FAKES/osascript.args"
  # Replaced: the new bundle, and no sibling left behind.
  grep -q '<string>0.1.0</string>' "$INSTALLED/Contents/Info.plist"
  [[ "$(app_count)" -eq 1 ]] || false
}

@test "AT-05.1: install launches with an empty environment, so the app captures its own login shell" {
  source_home
  xcode_fakes
  launch_fakes
  run_src_menuz install
  assert_success
  grep -q "^HOME=$HOME$" "$FAKES/open.env"
  run grep -c '^XDG_STATE_HOME=\|^UTILZ_HOME=' "$FAKES/open.env"
  assert_output "0"
}

@test "AT-05.1: install quits nothing when nothing runs" {
  source_home
  xcode_fakes
  launch_fakes
  fake osascript 'exit 0'
  run_src_menuz install
  assert_success
  [[ "$(count_calls osascript)" -eq 0 ]] || false
}

@test "AT-05.1: a copy that will not quit is exit 1 naming the quit, and nothing is replaced" {
  source_home
  xcode_fakes
  launch_fakes
  running_app
  fake osascript 'exit 0'
  make_app "$INSTALLED" 0.0.9
  run_src_menuz install
  assert_exit_code 1
  assert_output_contains "quit"
  assert_output_contains "4242"
  grep -q '<string>0.0.9</string>' "$INSTALLED/Contents/Info.plist"
  [[ "$(count_calls open)" -eq 0 ]] || false
}

@test "AT-05.1: a failed copy is exit 1 naming the replace, and the old copy stays whole" {
  source_home
  xcode_fakes
  launch_fakes
  fake ditto 'echo "ditto: No space left on device" >&2; exit 1'
  make_app "$INSTALLED" 0.0.9
  run_src_menuz install
  assert_exit_code 1
  assert_output_contains "replace"
  assert_output_contains "No space left on device"
  grep -q '<string>0.0.9</string>' "$INSTALLED/Contents/Info.plist"
  [[ -x "$INSTALLED/Contents/MacOS/Menuz" ]] || false
  [[ "$(app_count)" -eq 1 ]] || false
  [[ "$(count_calls open)" -eq 0 ]] || false
}

@test "AT-05.1: a failed launch is exit 1 naming the launch" {
  source_home
  xcode_fakes
  launch_fakes
  fake open 'echo "LSOpenURLsWithRole() failed" >&2; exit 1'
  run_src_menuz install
  assert_exit_code 1
  assert_output_contains "launch"
  assert_output_contains "LSOpenURLsWithRole"
  [[ -x "$INSTALLED/Contents/MacOS/Menuz" ]] || false
}

@test "AT-05.1: a failed build is exit 1 and nothing is quit or replaced" {
  source_home
  xcode_fakes
  launch_fakes
  running_app
  make_app "$INSTALLED" 0.0.9
  FAKE_XCODEBUILD_RC=65 run_src_menuz install
  assert_exit_code 1
  [[ "$(count_calls osascript)" -eq 0 ]] || false
  grep -q '<string>0.0.9</string>' "$INSTALLED/Contents/Info.plist"
}

# --- install, in a keg: the release asset --------------------------------------

@test "AT-05.1: in an install, install fetches the release asset, verifies it, then quits, replaces, registers and launches" {
  keg_home
  asset_fakes
  running_app
  run_src_menuz install
  assert_success
  grep -qx 'https://github.com/matthewsinclair/utilz/releases/download/2.14.0/Menuz.app.zip' "$FAKES/curl.args"
  grep -qx -- '-fsSL' "$FAKES/curl.args"
  [[ "$(calls_of curl ditto codesign spctl osascript lsregister open | awk '{ print $1 }' | tr '\n' ' ')" == "curl ditto codesign spctl osascript ditto lsregister open " ]] || false
  grep -q '^codesign --verify --deep --strict ' "$FAKES/calls"
  grep -q '^spctl -a -t exec -vv ' "$FAKES/calls"
  grep -qx "lsregister -f $INSTALLED" "$FAKES/calls"
  [[ "$(count_calls 'lsregister -u')" -eq 0 ]] || false
  [[ -x "$INSTALLED/Contents/MacOS/Menuz" ]] || false
  [[ -z "$(xcodebuild_call)" ]] || false
}

@test "AT-05.1: a keg install whose release carries no asset is exit 1 naming the URL, nothing replaced" {
  keg_home
  asset_fakes
  make_app "$INSTALLED" 0.0.9
  FAKE_CURL_RC=22 run_src_menuz install
  assert_exit_code 1
  assert_output_contains "https://github.com/matthewsinclair/utilz/releases/download/2.14.0/Menuz.app.zip"
  assert_output_contains "no Menuz.app"
  grep -q '<string>0.0.9</string>' "$INSTALLED/Contents/Info.plist"
  [[ "$(count_calls open)" -eq 0 ]] || false
}

@test "AT-05.1: a keg install refuses a failed signature, exit 1 naming codesign, nothing replaced" {
  keg_home
  asset_fakes
  make_app "$INSTALLED" 0.0.9
  FAKE_CODESIGN_RC=1 run_src_menuz install
  assert_exit_code 1
  assert_output_contains "codesign"
  grep -q '<string>0.0.9</string>' "$INSTALLED/Contents/Info.plist"
  [[ "$(count_calls osascript)" -eq 0 ]] || false
  [[ "$(count_calls open)" -eq 0 ]] || false
}

@test "AT-05.1: a keg install refuses a bundle that is not notarised, exit 1 naming spctl" {
  keg_home
  asset_fakes
  FAKE_SPCTL_SOURCE="Apple Development" run_src_menuz install
  assert_exit_code 1
  assert_output_contains "spctl"
  assert_output_contains "Notarized Developer ID"
  [[ ! -e "$INSTALLED" ]] || false
}

@test "AT-05.1: a keg install refuses the wrong version, exit 1 naming both, nothing replaced" {
  keg_home
  asset_fakes
  replace_asset 9.9.9
  run_src_menuz install
  assert_exit_code 1
  assert_output_contains "9.9.9"
  assert_output_contains "$(cat "$SRC/opt/menuz/VERSION")"
  [[ ! -e "$INSTALLED" ]] || false
}

@test "AT-05.1: a keg install refuses another bundle id, exit 1 naming it" {
  keg_home
  asset_fakes
  replace_asset "$(cat "$SRC/opt/menuz/VERSION")" abc123 com.example.other
  run_src_menuz install
  assert_exit_code 1
  assert_output_contains "com.example.other"
  [[ ! -e "$INSTALLED" ]] || false
}

# --- use, start, stop, restart -------------------------------------------------

@test "AT-05.1: use with no record prints installed (default)" {
  run_menuz use
  assert_success
  assert_output "installed (default)"
}

@test "AT-05.1: use dev records the choice; use prints it and why; status and start follow it" {
  run_menuz use dev
  assert_success
  [[ "$(cat "$XDG_STATE_HOME/menuz/use")" == dev ]] || false
  run_menuz use
  assert_success
  assert_output "dev (by $XDG_STATE_HOME/menuz/use)"
  make_app "$DEV"
  run_menuz status
  assert_output_contains "use         dev (by $XDG_STATE_HOME/menuz/use)"
  fake open 'exit 0'
  run_menuz start
  assert_success
  grep -qx "open -a $DEV" "$FAKES/calls"
  run_menuz use installed
  assert_success
  [[ "$(cat "$XDG_STATE_HOME/menuz/use")" == installed ]] || false
}

@test "AT-05.1: use refuses any other word, exit 2, recording nothing" {
  run_menuz use staging
  assert_exit_code 2
  assert_output_contains "staging"
  [[ ! -e "$XDG_STATE_HOME/menuz/use" ]] || false
  run_menuz use dev installed
  assert_exit_code 2
}

@test "AT-05.1: start opens the chosen build with an empty environment" {
  make_app "$INSTALLED"
  fake open 'env >"'"$FAKES"'/open.env"'
  run_menuz start
  assert_success
  grep -qx "open -a $INSTALLED" "$FAKES/calls"
  run grep -c '^XDG_STATE_HOME=' "$FAKES/open.env"
  assert_output "0"
}

@test "AT-05.1: start refuses when the chosen build is not there, exit 2, naming it" {
  fake open 'exit 0'
  run_menuz start
  assert_exit_code 2
  assert_output_contains "$INSTALLED"
  mkdir -p "$XDG_STATE_HOME/menuz"
  echo dev >"$XDG_STATE_HOME/menuz/use"
  run_menuz start
  assert_exit_code 2
  assert_output_contains "$DEV"
  [[ "$(count_calls open)" -eq 0 ]] || false
}

@test "AT-05.1: stop quits every copy by bundle id, and says when none runs" {
  running_app
  run_menuz stop
  assert_success
  grep -q "com.matthewsinclair.utilz.menuz" "$FAKES/osascript.args"
  [[ ! -e "$FAKES/running" ]] || false
  run_menuz stop
  assert_success
  assert_output_contains "not running"
  [[ "$(count_calls osascript)" -eq 1 ]] || false
}

@test "AT-05.1: restart is stop, then start" {
  running_app
  make_app "$INSTALLED"
  fake open 'exit 0'
  run_menuz restart
  assert_success
  [[ "$(calls_of osascript open | awk '{ print $1 }' | tr '\n' ' ')" == "osascript open " ]] || false
}

@test "AT-05.1: the verbs that take no arguments refuse one by name, exit 2" {
  local verb
  for verb in start stop restart uninstall doctor stamps; do
    run_menuz "$verb" --now
    assert_exit_code 2
    assert_output_contains "--now"
  done
}

# --- uninstall -----------------------------------------------------------------

@test "AT-05.1: uninstall with nothing installed is exit 0 and says so" {
  fake lsregister 'exit 0'
  run_menuz uninstall
  assert_success
  assert_output_contains "nothing installed"
  [[ "$(count_calls lsregister)" -eq 0 ]] || false
}

@test "AT-05.1: uninstall quits, unregisters the login item, unregisters the bundle and removes it" {
  running_app
  fake lsregister 'exit 0'
  make_app "$INSTALLED"
  run_menuz uninstall
  assert_success
  [[ "$(calls_of osascript app lsregister | tr '\n' '|')" == "osascript -l|app --unregister-login-item|lsregister -u|" ]] || false
  grep -qx "lsregister -u $INSTALLED" "$FAKES/calls"
  assert_output_contains "unregistered (now not registered)"
  [[ ! -e "$INSTALLED" ]] || false
}

@test "AT-05.1: a login item that will not unregister is reported, the removal goes on, exit 1" {
  fake lsregister 'exit 0'
  make_app "$INSTALLED"
  FAKE_UNREGISTER_RC=1 FAKE_UNREGISTER_OUT="still enabled" run_menuz uninstall
  assert_exit_code 1
  assert_output_contains "still enabled"
  assert_output_contains "login item"
  [[ ! -e "$INSTALLED" ]] || false
}

# --- doctor --------------------------------------------------------------------

doctor_fixture() {
  source_home
  xcode_fakes
  fake security 'printf "  1) 0123ABCD \"Apple Development: M S (TEAM1)\"\n  2) 4567EF01 \"Developer ID Application: M S (TEAM1)\"\n     2 valid identities found\n"'
  run_src_menuz init
  make_app "$INSTALLED"
  running_app
}

@test "AT-05.1: doctor prints one line per precondition, exit 0 when all hold" {
  doctor_fixture
  run_src_menuz doctor
  assert_success
  local label
  for label in xcode xcodegen identity config menu installed running "login item"; do
    printf '%s\n' "$output" | grep -Eq "^$label +ok "
  done
  assert_output_contains "/Applications/Xcode.app/Contents/Developer"
  assert_output_contains "Xcode 26.0"
  assert_output_contains "2 codesigning"
  refute_output_contains "0123ABCD"
  refute_output_contains "4567EF01"
  grep -q '^app --validate' "$FAKES/calls"
}

@test "AT-05.1: doctor is exit 1 naming each precondition that fails" {
  doctor_fixture
  rm -rf "${INSTALLED:?}"
  rm "$FAKES/running"
  fake security 'printf "     0 valid identities found\n"'
  rm "$CONFIG/menuz.yaml"
  run_src_menuz doctor
  assert_exit_code 1
  local label
  for label in identity config installed running; do
    printf '%s\n' "$output" | grep -Eq "^$label +FAIL "
  done
  printf '%s\n' "$output" | grep -Eq "^xcode +ok "
}

@test "AT-05.1: doctor fails an Xcode below project.yml's xcodeVersion, and a floor it cannot read or compare (issue 0073)" {
  doctor_fixture
  local yml="$SRC/native/macos/Menuz/project.yml"
  fake xcodebuild 'printf "Xcode 16.4\nBuild version 16F6\n"'
  run_src_menuz doctor
  assert_exit_code 1
  printf '%s\n' "$output" | grep -Eq "^xcode +FAIL .*Xcode 16\.4 is below menuz's floor, Xcode 26\.0 "
  fake xcodebuild 'printf "Xcode 26.0.1\nBuild version 17A101\n"'
  run_src_menuz doctor
  assert_success
  printf '%s\n' "$output" | grep -Eq "^xcode +ok .*Xcode 26\.0\.1$"
  printf 'name: Menuz\noptions:\n  xcodeVersion: "26.x"\n' >"$yml"
  run_src_menuz doctor
  assert_exit_code 1
  printf '%s\n' "$output" | grep -Eq "^xcode +FAIL .*Xcode 26\.0\.1: cannot compare it with menuz's floor, Xcode 26\.x$"
  echo 'name: Menuz' >"$yml"
  run_src_menuz doctor
  assert_exit_code 1
  printf '%s\n' "$output" | grep -Eq "^xcode +FAIL .*no xcodeVersion, double-quoted and indented two spaces, in $yml$"
  rm "$yml"
  run_src_menuz doctor
  assert_exit_code 1
  printf '%s\n' "$output" | grep -Eq "^xcode +FAIL .*menuz's floor is unreadable: .*project\.yml"
}

@test "AT-05.1: doctor reads Xcode's version from its own line, past anything xcodebuild prints first (issue 0073)" {
  doctor_fixture
  fake xcodebuild 'echo "xcodebuild[1:1] Requested but did not find extension point" >&2; printf "Xcode 26.0\nBuild version 17A100\n"'
  run_src_menuz doctor
  assert_success
  printf '%s\n' "$output" | grep -Eq "^xcode +ok .*Xcode 26\.0$"
  fake xcodebuild 'echo "no version here"'
  run_src_menuz doctor
  assert_exit_code 1
  printf '%s\n' "$output" | grep -Eq "^xcode +FAIL .*printed no Xcode line: no version here$"
}

@test "AT-05.1: doctor fails a menu the chosen app refuses, and a login item that is not enabled" {
  doctor_fixture
  FAKE_APP_RC=2 FAKE_APP_OUT="line 3: unknown key" FAKE_LOGIN="requires approval" run_src_menuz doctor
  assert_exit_code 1
  printf '%s\n' "$output" | grep -Eq "^menu +FAIL .*unknown key"
  printf '%s\n' "$output" | grep -Eq "^login item +FAIL .*requires approval"
}

@test "AT-05.1: in an install, doctor skips the build lines and says why" {
  keg_home
  run_src_menuz init
  make_app "$INSTALLED"
  running_app
  fake security 'exit 0'
  run_src_menuz doctor
  assert_success
  printf '%s\n' "$output" | grep -Eq "^build +skip .*install"
  run grep -Ec '^(xcode|xcodegen|identity) ' <<<"$output"
  assert_output "0"
}

@test "AT-05.1: in an install, doctor still checks the installed app" {
  keg_home
  run_src_menuz init
  make_app "$INSTALLED"
  running_app
  run_src_menuz doctor
  printf '%s\n' "$output" | grep -Eq "^installed +ok "
}

# --- the failure paths the critic found untested ---------------------------------

# mv that fails on the calls FAKE_MV_FAIL names (by their order, from 1),
# and is the system's mv on every other.
mv_fake() {
  fake mv '
n=$(($(cat "'"$FAKES"'/mv.n" 2>/dev/null || echo 0) + 1))
echo "$n" >"'"$FAKES"'/mv.n"
case " ${FAKE_MV_FAIL:-} " in
  *" $n "*)
    echo "mv: rename failed (call $n)" >&2
    exit 1
    ;;
esac
exec /bin/mv "$@"'
}

@test "AT-05.1: an old copy that cannot be moved aside is exit 1 naming the replace, and it stays whole" {
  source_home
  xcode_fakes
  launch_fakes
  mv_fake
  make_app "$INSTALLED" 0.0.9
  FAKE_MV_FAIL=1 run_src_menuz install
  assert_exit_code 1
  assert_output_contains "replace"
  assert_output_contains "moved aside"
  grep -q '<string>0.0.9</string>' "$INSTALLED/Contents/Info.plist"
  [[ "$(app_count)" -eq 1 ]] || false
  [[ "$(count_calls open)" -eq 0 ]] || false
}

@test "AT-05.1: a new copy that cannot be moved in puts the old one back, exit 1" {
  source_home
  xcode_fakes
  launch_fakes
  mv_fake
  make_app "$INSTALLED" 0.0.9
  FAKE_MV_FAIL=2 run_src_menuz install
  assert_exit_code 1
  assert_output_contains "the old copy is back"
  grep -q '<string>0.0.9</string>' "$INSTALLED/Contents/Info.plist"
  [[ "$(app_count)" -eq 1 ]] || false
}

@test "AT-05.1: when the old copy cannot be put back either, the failure says where it is" {
  source_home
  xcode_fakes
  launch_fakes
  mv_fake
  make_app "$INSTALLED" 0.0.9
  FAKE_MV_FAIL="2 3" run_src_menuz install
  assert_exit_code 1
  assert_output_contains "could not be put back"
  assert_output_contains "$HOME/Applications/.Menuz.app.old."
  [[ "$(count_calls open)" -eq 0 ]] || false
}

@test "AT-05.1: restart with the chosen build missing is refused, exit 2, and nothing is quit" {
  running_app
  run_menuz restart
  assert_exit_code 2
  assert_output_contains "$INSTALLED"
  [[ "$(count_calls osascript)" -eq 0 ]] || false
  [[ -f "$FAKES/running" ]] || false
}

@test "AT-05.1: with no use record and only a dev build, start opens it, as validate uses it" {
  make_app "$DEV"
  fake open 'exit 0'
  run_menuz start
  assert_success
  grep -qx "open -a $DEV" "$FAKES/calls"
}

@test "AT-05.1: an uninstall whose lsregister -u fails removes the app and is exit 1 naming it" {
  fake lsregister 'echo "lsregister: no such bundle" >&2; exit 1'
  make_app "$INSTALLED"
  run_menuz uninstall
  assert_exit_code 1
  assert_output_contains "lsregister -u"
  assert_output_contains "no such bundle"
  [[ ! -e "$INSTALLED" ]] || false
}

@test "AT-05.1: a keg install with no release VERSION is refused, exit 2, fetching nothing" {
  keg_home
  asset_fakes
  : >"$SRC/VERSION"
  run_src_menuz install
  assert_exit_code 2
  assert_output_contains "$SRC/VERSION"
  [[ "$(count_calls curl)" -eq 0 ]] || false
}

# ============================================================================
# AT-07.3 -- the fifth stamp and the eight-character commit (AC-07.3, WP-07).
# The fixture repository's root VERSION is the real one; a test tags its
# HEAD, or does not, and reads the kind from stamps and from build.
# ============================================================================

kind_stamp() {
  printf '%s\n' "$output" | sed -n 's/^MENUZ_KIND=//p'
}

@test "AT-07.3: the kind is release for a clean source whose HEAD carries the root VERSION's tag" {
  source_home
  git -C "$SRC" tag "$(cat "$SRC/VERSION")"
  run_src_menuz stamps
  assert_success
  [[ "$(kind_stamp)" == release ]] || false
  xcode_fakes
  run_src_menuz build
  assert_success
  [[ "$(xcodebuild_call)" == *" MENUZ_KIND=release "* ]] || false
}

@test "AT-07.3: the kind is dev when HEAD carries no tag" {
  source_home
  run_src_menuz stamps
  assert_success
  [[ "$(kind_stamp)" == dev ]] || false
}

@test "AT-07.3: the kind is dev when the source is dirty, though HEAD carries the tag" {
  source_home
  git -C "$SRC" tag "$(cat "$SRC/VERSION")"
  echo 'print("changed")' >>"$SRC/native/macos/Menuz/Menuz/App.swift"
  run_src_menuz stamps
  assert_success
  printf '%s\n' "$output" | grep -Eq '^MENUZ_SOURCE_TREE=[0-9a-f]{40}-dirty$'
  [[ "$(kind_stamp)" == dev ]] || false
}

@test "AT-07.3: the kind is dev when HEAD's tag is not the bare VERSION, or the tag is on an earlier commit" {
  source_home
  git -C "$SRC" tag "v$(cat "$SRC/VERSION")"
  git -C "$SRC" tag 0.0.1
  run_src_menuz stamps
  assert_success
  [[ "$(kind_stamp)" == dev ]] || false
  git -C "$SRC" tag "$(cat "$SRC/VERSION")"
  echo more >"$SRC/notes.txt"
  git -C "$SRC" add notes.txt
  git -C "$SRC" -c user.name=t -c user.email=t@t commit -qm later
  run_src_menuz stamps
  assert_success
  [[ "$(kind_stamp)" == dev ]] || false
}

@test "AT-07.3: the commit stamp is HEAD's first eight characters" {
  source_home
  run_src_menuz stamps
  assert_success
  local commit
  commit="$(printf '%s\n' "$output" | sed -n 's/^MENUZ_COMMIT=//p')"
  [[ "$commit" =~ ^[0-9a-f]{8}$ ]] || false
  [[ "$(git -C "$SRC" rev-parse HEAD)" == "$commit"* ]] || false
}

@test "AT-07.3: without the root VERSION, stamps is exit 1 naming it" {
  source_home
  rm "$SRC/VERSION"
  run_src_menuz stamps
  assert_exit_code 1
  assert_output_contains "$SRC/VERSION"
}

@test "AT-07.3: in an install, a bundle with no MenuzKind prints the stamp empty" {
  keg_home
  make_app "$INSTALLED" 2.0.1 feed42
  local plist="$INSTALLED/Contents/Info.plist"
  grep -v -e '<key>MenuzKind</key>' -e '<string>release</string>' "$plist" >"$plist.new"
  mv "$plist.new" "$plist"
  run_src_menuz stamps
  assert_success
  printf '%s\n' "$output" | grep -qx 'MENUZ_KIND='
}
