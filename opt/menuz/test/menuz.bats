#!/usr/bin/env bats
# menuz.bats - Tests for the menuz shim (ST0027)
#
# The shim, the config directory and the verbs that need no Xcode (WP-02).
# Each test names the AT it carries. NOTHING HERE REACHES THE REAL MACHINE:
# HOME and every XDG directory are fixtures under the test's own temp
# directory, the app is a fake bundle that records its arguments, and open,
# pgrep and tail are fakes on PATH where a verb would otherwise reach out.

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
  export PATH="$FAKES:$PATH"
  # pgrep finds no Menuz unless a test says otherwise.
  fake pgrep 'exit 1'
}

run_menuz() {
  run "$UTILZ_BIN_DIR/menuz" "$@"
}

# A command on PATH that records its arguments, one per line, in
# $FAKES/<name>.args, then runs BODY.
fake() {
  local name="$1" body="$2"
  cat >"$FAKES/$name" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$@" >"$FAKES/$name.args"
$body
EOF
  chmod +x "$FAKES/$name"
}

# A fake Menuz.app at BUNDLE: its binary records its arguments in
# $FAKES/app.args and answers from FAKE_APP_OUT and FAKE_APP_RC, or for
# --login-item from FAKE_LOGIN; its Info.plist carries the stamps.
make_app() {
  local bundle="$1" version="${2:-0.1.0}" tree="${3:-abc123}"
  mkdir -p "$bundle/Contents/MacOS"
  cat >"$bundle/Contents/MacOS/Menuz" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$@" >"$FAKES/app.args"
if [[ "\$1" == --login-item ]]; then
  printf '%s\n' "\${FAKE_LOGIN:-enabled}"
  exit 0
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
	<key>CFBundleShortVersionString</key>
	<string>$version</string>
	<key>CFBundleVersion</key>
	<string>42</string>
	<key>MenuzCommit</key>
	<string>deadbee</string>
	<key>MenuzSourceTree</key>
	<string>$tree</string>
</dict>
</plist>
EOF
}

app_args() { tr '\n' ' ' <"$FAKES/app.args"; }

# A fixture UTILZ_HOME that is a git repository: the real common.sh and shim,
# and native/macos/Menuz with one source and one test, committed. With
# --no-source it has no native/macos/Menuz. Status reads the source through
# git on UTILZ_HOME, so a test of it never reads the real tree, whose
# native/macos/Menuz exists from WP-03 on.
source_home() {
  SRC="$BATS_TEST_TMPDIR/src"
  mkdir -p "$SRC/opt/utilz/lib" "$SRC/opt/menuz/lib"
  cp "$UTILZ_HOME/opt/utilz/lib/common.sh" "$SRC/opt/utilz/lib/"
  cp "$UTILZ_HOME/opt/menuz/menuz" "$UTILZ_HOME/opt/menuz/VERSION" "$SRC/opt/menuz/"
  cp "$EXAMPLE" "$SRC/opt/menuz/lib/"
  if [[ "${1:-}" != --no-source ]]; then
    mkdir -p "$SRC/native/macos/Menuz/Menuz" "$SRC/native/macos/Menuz/MenuzTests"
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
  [[ -d "$CONFIG/bin" ]]
  [[ -z "$(ls -A "$CONFIG/bin")" ]]
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
  [[ ! -e "$CONFIG" ]]
}

@test "AT-02.2: a second init changes nothing" {
  run_menuz init
  touch -t 202001010000 "$CONFIG/menuz.yaml" "$CONFIG/bin"
  touch "$BATS_TEST_TMPDIR/mark"
  run_menuz init
  assert_success
  assert_output_contains "nothing changed"
  [[ ! "$CONFIG/menuz.yaml" -nt "$BATS_TEST_TMPDIR/mark" ]]
  [[ ! "$CONFIG/bin" -nt "$BATS_TEST_TMPDIR/mark" ]]
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
  [[ -f "$CONFIG/bin/mine" ]]
}

@test "AT-02.2: edit opens the menu with open -t" {
  run_menuz init
  fake open 'exit 0'
  run_menuz edit
  assert_success
  [[ "$(tr '\n' ' ' <"$FAKES/open.args")" == "-t $CONFIG/menuz.yaml " ]]
}

@test "AT-02.2: edit --editor runs \$VISUAL, else \$EDITOR" {
  run_menuz init
  fake vis 'exit 0'
  fake ed 'exit 0'
  VISUAL='vis' EDITOR='ed' run_menuz edit --editor
  assert_success
  [[ "$(cat "$FAKES/vis.args")" == "$CONFIG/menuz.yaml" ]]
  [[ ! -e "$FAKES/ed.args" ]]
  EDITOR='ed' run_menuz edit --editor
  assert_success
  [[ "$(cat "$FAKES/ed.args")" == "$CONFIG/menuz.yaml" ]]
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
  [[ ! -e "$FAKES/open.args" ]]
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
  [[ "$(tr '\n' ' ' <"$FAKES/tail.args")" == "-f $LOG " ]]
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
  [[ "$(app_args)" == "--validate $CONFIG/menuz.yaml " ]]
}

@test "AT-02.3: validate on a given file passes that file" {
  make_app "$INSTALLED"
  echo "menu: []" >"$BATS_TEST_TMPDIR/other.yaml"
  run_menuz validate "$BATS_TEST_TMPDIR/other.yaml"
  assert_success
  assert_output_contains "ok"
  [[ "$(app_args)" == "--validate $BATS_TEST_TMPDIR/other.yaml " ]]
}

@test "AT-02.3: validate on a file that does not exist is refused by name, exit 2" {
  make_app "$INSTALLED"
  run_menuz validate "$BATS_TEST_TMPDIR/nope.yaml"
  assert_exit_code 2
  assert_output_contains "$BATS_TEST_TMPDIR/nope.yaml"
  [[ ! -e "$FAKES/app.args" ]]
}

@test "AT-02.3: render runs the dev build when nothing is installed" {
  run_menuz init
  make_app "$DEV"
  FAKE_APP_OUT="  Desks" run_menuz render
  assert_success
  assert_output_contains "  Desks"
  [[ "$(app_args)" == "--render $CONFIG/menuz.yaml " ]]
}

@test "AT-02.3: use's record selects the dev build over an installed one" {
  run_menuz init
  make_app "$INSTALLED"
  make_app "$DEV"
  rm "$INSTALLED/Contents/MacOS/Menuz"
  echo dev >"$XDG_STATE_HOME/menuz/use"
  run_menuz validate
  assert_success
  [[ "$(app_args)" == "--validate $CONFIG/menuz.yaml " ]]
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
  [[ ! -e "$FAKES/app.args" ]]
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
  [[ ! -e "$FAKES/xcodebuild.args" ]]
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
  [[ -n "$tree" ]]
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
