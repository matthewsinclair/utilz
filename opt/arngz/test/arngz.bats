#!/usr/bin/env bats
# arngz.bats - Tests for arngz (ST0026)
#
# WP-02: the CLI's surface, the desk catalogue and the validator. Each test
# names the AT it carries. Nothing here calls Hammerspoon or the hs tool: the
# catalogue verbs are file operations, and the verbs that need the engine print
# which work package builds them.
#
# THE CATALOGUE IS ALWAYS A FIXTURE. Every test points XDG_CONFIG_HOME at its
# own temp directory, which is the one override the design allows, so no test
# can read or write the real ~/.config/arngz.

load "../../utilz/test/test_helper.bash"

FIXTURES="$UTILZ_HOME/opt/arngz/test/fixtures"

run_arngz() {
  run "$UTILZ_BIN_DIR/arngz" "$@"
}

# A fresh catalogue for this test, holding the design's example desk.
catalogue() {
  export XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/config"
  CAT="$XDG_CONFIG_HOME/arngz/desks"
  mkdir -p "$CAT"
  cp "$FIXTURES/desks/zeop1.yaml" "$CAT/zeop1.yaml"
}

# A minimal valid desk, written to the catalogue under NAME. Each validator
# test changes exactly one thing in it, so the refusal can only be about that.
# The base is proven valid by its own test below.
minimal_desk() {
  cat >"$CAT/$1.yaml" <<'EOF'
desk: base
grid: 12x8
displays:
  - name: left
    match: { uuid: AAAA-1, name: VY229HF }
    spaces:
      - apps:
          - app: com.apple.mail
            layout: 0,0 6x8
          - app: com.apple.Safari
            layout: 6,0 6x8
EOF
}

# Replace one line of a desk, matched exactly, and fail loudly if it is absent,
# so a fixture edit that silently missed cannot pass as a refusal.
edit_desk() {
  local file="$CAT/$1.yaml" from="$2" to="$3"
  grep -qxF -- "$from" "$file" || {
    echo "edit_desk: no line '$from' in $file" >&2
    return 1
  }
  # Through the environment, because awk -v cannot carry a newline and a
  # replacement may add a line.
  FROM="$from" TO="$to" awk '$0 == ENVIRON["FROM"] { print ENVIRON["TO"]; next } { print }' "$file" >"$file.new"
  mv "$file.new" "$file"
}

# The three things every refusal must name: the desk, the file and the value.
assert_refusal() {
  local desk="$1" path="$2" value="$3"
  assert_exit_code 2
  assert_output_contains "desk '$desk'"
  assert_output_contains "$CAT/$desk.yaml"
  assert_output_contains "$path"
  assert_output_contains "$value"
}

# ============================================================================
# AT-02.1 -- dispatched, declared, listed (AC-02.1)
# ============================================================================

@test "AT-02.1: utilz arngz is dispatched and its help names every verb and flag" {
  run_utilz arngz --help
  assert_success
  local word
  for word in apply discover diff list show delete init doctor \
    --dry-run --no-launch --no-create --bind --map --save --force --yes; do
    assert_output_contains "$word"
  done
}

@test "AT-02.1: utilz list shows arngz" {
  run_utilz list
  assert_success
  assert_output_contains "arngz"
}

@test "AT-02.1: arngz.yaml declares yq as required and the hs tool and Hammerspoon as optional" {
  local y="$UTILZ_HOME/opt/arngz/arngz.yaml"
  run yq '.dependencies[] | select(.name == "yq") | .required' "$y"
  assert_output "true"
  run yq '.dependencies[] | select(.name == "hs") | .required' "$y"
  assert_output "false"
  run yq '.dependencies[] | select(.name == "Hammerspoon") | .app' "$y"
  assert_output "org.hammerspoon.Hammerspoon"
  run yq '.dependencies[] | select(.name == "Hammerspoon") | .required' "$y"
  assert_output "false"
}

# doctor runs in-process with check_app STUBBED, so the test needs neither
# osascript nor Spotlight and runs the same on Linux and macOS. The stub is the
# function, never the binary (vc, 16 Oct 2026).
doctor_with_app() {
  local answer="$1"
  run /bin/bash -c "source '$UTILZ_HOME/opt/utilz/lib/common.sh'; check_app() { return $answer; }; run_doctor"
}

@test "AT-02.1: doctor names Hammerspoon as an optional app dependency of arngz when it is missing" {
  doctor_with_app 1
  assert_output_contains "Optional: 'Hammerspoon' is not installed"
  assert_output_contains "needed by arngz apply and discover"
  assert_output_contains "declared by arngz"
  assert_output_contains "brew install --cask hammerspoon"
  refute_output_contains "Missing dependencies: Hammerspoon"
}

@test "AT-02.1: doctor says nothing about Hammerspoon when the app is there" {
  doctor_with_app 0
  refute_output_contains "'Hammerspoon'"
}

@test "AT-02.1: doctor names the hs tool when it is not on PATH, as optional" {
  local bin="$BATS_TEST_TMPDIR/bin" tool
  mkdir -p "$bin"
  for tool in yq git bash; do
    ln -s "$(command -v "$tool")" "$bin/$tool"
  done
  run /bin/bash -c "export PATH='$bin:/usr/bin:/bin'; source '$UTILZ_HOME/opt/utilz/lib/common.sh'; check_app() { return 0; }; run_doctor"
  assert_output_contains "Optional: 'hs' is not installed"
  assert_output_contains "declared by arngz"
}

# ============================================================================
# AT-02.2 -- the catalogue verbs (AC-02.2)
# ============================================================================

@test "AT-02.2: init creates the catalogue under XDG_CONFIG_HOME, and a second run says it exists" {
  export XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/config"
  run_arngz init
  assert_success
  [ -d "$XDG_CONFIG_HOME/arngz/desks" ]
  assert_output_contains "$XDG_CONFIG_HOME/arngz/desks"
  assert_output_contains "created"

  run_arngz init
  assert_success
  assert_output_contains "exists"
}

@test "AT-02.2: without XDG_CONFIG_HOME the catalogue is under HOME/.config" {
  unset XDG_CONFIG_HOME
  export HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$HOME"
  run_arngz init
  assert_success
  [ -d "$HOME/.config/arngz/desks" ]
}

@test "AT-02.2: init says the Hammerspoon half is not built yet" {
  export XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/config"
  run_arngz init
  assert_success
  assert_output_contains "not yet: WP-06"
}

@test "AT-02.2: list prints each desk with its display and app counts" {
  catalogue
  minimal_desk base
  run_arngz list
  assert_success
  echo "$output" | grep -Eq '^base +1 display +2 apps$' || {
    echo "no line for base: $output" >&2
    return 1
  }
  echo "$output" | grep -Eq '^zeop1 +2 displays +4 apps$' || {
    echo "no line for zeop1: $output" >&2
    return 1
  }
}

@test "AT-02.2: list over an absent catalogue says so and names init" {
  export XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/config"
  run_arngz list
  assert_success
  assert_output_contains "$XDG_CONFIG_HOME/arngz/desks"
  assert_output_contains "arngz init"
}

@test "AT-02.2: list names an invalid desk on its own line and exits 1" {
  catalogue
  minimal_desk broken
  edit_desk broken "grid: 12x8" "grid: twelve"
  run_arngz list
  assert_exit_code 1
  assert_output_contains "zeop1"
  echo "$output" | grep -Eq '^broken +invalid' || {
    echo "broken was not named as invalid: $output" >&2
    return 1
  }
}

@test "AT-02.2: show prints the desk exactly as it is stored" {
  catalogue
  run_arngz show zeop1
  assert_success
  [ "$output" = "$(cat "$FIXTURES/desks/zeop1.yaml")" ]
}

@test "AT-02.2: delete removes one desk by name and names the file" {
  catalogue
  minimal_desk base
  run_arngz delete base
  assert_success
  assert_output_contains "$CAT/base.yaml"
  [ ! -e "$CAT/base.yaml" ]
  [ -f "$CAT/zeop1.yaml" ]
}

@test "AT-02.2: a desk that does not exist is refused by name, exit 2, by show, delete and apply" {
  catalogue
  local verb
  for verb in show delete apply; do
    run_arngz "$verb" nosuch
    assert_exit_code 2
    assert_output_contains "nosuch"
    assert_output_contains "$CAT/nosuch.yaml"
  done
}

# ============================================================================
# AT-02.3 -- the validator (AC-02.3, and AC-05.7's verb-name refusal)
# ============================================================================

@test "AT-02.3: the design's example desk validates unchanged" {
  catalogue
  cmp -s "$FIXTURES/desks/zeop1.yaml" "$CAT/zeop1.yaml"
  run_arngz show zeop1
  assert_success
}

@test "AT-02.3: the minimal base desk validates, so each refusal below is about its one change" {
  catalogue
  minimal_desk base
  run_arngz show base
  assert_success
}

@test "AT-02.3: an unknown key is refused, at the top and nested" {
  catalogue
  minimal_desk top
  echo "colour: blue" >>"$CAT/top.yaml"
  run_arngz show top
  assert_refusal top "colour" "blue"
  assert_output_contains "unknown key"

  minimal_desk nested
  edit_desk nested "          - app: com.apple.mail" "          - app: com.apple.mail
            screen: 2"
  run_arngz show nested
  assert_refusal nested "displays[0].spaces[0].apps[0].screen" "2"
}

@test "AT-02.3: a grid that is not WxH is refused" {
  catalogue
  minimal_desk g
  edit_desk g "grid: 12x8" "grid: 12 by 8"
  run_arngz show g
  assert_refusal g "grid" "12 by 8"
}

@test "AT-02.3: a layout neither x,y wxh inside the grid nor fullscreen is refused" {
  catalogue
  minimal_desk shape
  edit_desk shape "            layout: 0,0 6x8" "            layout: left half"
  run_arngz show shape
  assert_refusal shape "displays[0].spaces[0].apps[0].layout" "left half"

  minimal_desk outside
  edit_desk outside "            layout: 6,0 6x8" "            layout: 7,0 6x8"
  run_arngz show outside
  assert_refusal outside "displays[0].spaces[0].apps[1].layout" "7,0 6x8"
  assert_output_contains "12x8"
}

@test "AT-02.3: two displays with one name are refused" {
  catalogue
  minimal_desk twins
  cat >>"$CAT/twins.yaml" <<'EOF'
  - name: left
    match: { uuid: AAAA-2 }
    spaces: []
EOF
  run_arngz show twins
  assert_refusal twins "displays[1].name" "left"
  assert_output_contains "displays[0]"
}

@test "AT-02.3: a display whose match has neither uuid nor name is refused" {
  catalogue
  minimal_desk m
  edit_desk m "    match: { uuid: AAAA-1, name: VY229HF }" "    match: { size: 1920x1080 }"
  run_arngz show m
  assert_refusal m "displays[0].match" "size"
}

@test "AT-02.3: the same app twice on one display needs a window pattern on every entry" {
  catalogue
  minimal_desk dup
  edit_desk dup "          - app: com.apple.Safari" "          - app: com.apple.mail"
  run_arngz show dup
  assert_refusal dup "displays[0].spaces[0].apps[1].app" "com.apple.mail"
  assert_output_contains "displays[0].spaces[0].apps[0]"

  # With a pattern on only one of them it is still refused.
  minimal_desk half
  edit_desk half "          - app: com.apple.Safari" "          - app: com.apple.mail
            window: Inbox"
  run_arngz show half
  assert_exit_code 2

  # With a pattern on every one it is accepted.
  minimal_desk both
  edit_desk both "          - app: com.apple.mail" "          - app: com.apple.mail
            window: Drafts"
  edit_desk both "          - app: com.apple.Safari" "          - app: com.apple.mail
            window: Inbox"
  run_arngz show both
  assert_success
}

@test "AT-02.3: a desk named like a verb is refused, by show and by apply" {
  catalogue
  local verb
  for verb in apply discover diff list show delete init doctor; do
    minimal_desk "$verb"
    run_arngz show "$verb"
    assert_refusal "$verb" "desk name" "$verb"
    run_arngz apply "$verb"
    assert_exit_code 2
    assert_output_contains "desk '$verb'"
  done
}

# ============================================================================
# The verbs the engine builds: present, and saying which work package
# ============================================================================

@test "apply, discover, diff and doctor say which work package builds them, exit 2" {
  catalogue
  run_arngz apply zeop1
  assert_exit_code 2
  assert_output_contains "not yet: WP-05"
  run_arngz zeop1
  assert_exit_code 2
  assert_output_contains "not yet: WP-05"
  run_arngz discover
  assert_exit_code 2
  assert_output_contains "not yet: WP-04"
  run_arngz diff zeop1
  assert_exit_code 2
  assert_output_contains "not yet: WP-04"
  run_arngz doctor
  assert_exit_code 2
  assert_output_contains "not yet: WP-06"
}

@test "apply validates the desk before saying it is not built" {
  catalogue
  minimal_desk g
  edit_desk g "grid: 12x8" "grid: 12 by 8"
  run_arngz apply g
  assert_refusal g "grid" "12 by 8"
}

@test "an unknown option is refused, exit 2" {
  run_arngz list --colour
  assert_exit_code 2
  assert_output_contains "--colour"
}

# ============================================================================
# AT-03.1 -- the engine contract, through a fake hs on PATH (AC-03.1)
# ============================================================================

# A bin dir holding the fake hs and the tools the CLI needs, so the real hs on
# this machine can never answer for it.
fake_hs() {
  export FAKE_HS_MODE="$1"
  export FAKE_HS_LOG="$BATS_TEST_TMPDIR/hslog"
  export FAKE_HS_RESPONSE="${2:-$FIXTURES/responses/observe.json}"
  mkdir -p "$FAKE_HS_LOG" "$BATS_TEST_TMPDIR/fakebin"
  cp "$FIXTURES/fake-hs" "$BATS_TEST_TMPDIR/fakebin/hs"
  export PATH="$BATS_TEST_TMPDIR/fakebin:$PATH"
  export XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/config"
  export TMPDIR="$BATS_TEST_TMPDIR/tmp"
  mkdir -p "$TMPDIR"
}

@test "AT-03.1: the request holds exactly verb, desk and options, and hs runs the module's run on it" {
  fake_hs ok
  run_arngz discover
  run yq -o json -I0 'keys' "$FAKE_HS_LOG/request.json"
  assert_output '["verb","desk","options"]'
  run yq -r '.verb' "$FAKE_HS_LOG/request.json"
  assert_output "observe"
  grep -qxF -- "-c" "$FAKE_HS_LOG/argv"
  grep -qF -- "return dofile(\"$UTILZ_HOME/opt/arngz/lib/arngz.lua\").run(\"" "$FAKE_HS_LOG/argv"
}

@test "AT-03.1: the CLI renders exactly the response's report, then says what is not built" {
  fake_hs ok
  run_arngz discover
  assert_exit_code 2
  assert_output_contains "FIXTURE-LINE-1 main Test Display (SCREEN-A): 2 spaces, 2 desktop; 3 windows, 3 named"
  assert_output_contains "FIXTURE-LINE-2 separate spaces true"
  assert_output_contains "not yet: WP-04"
  # The temp dir of a call that succeeded is removed.
  [ -z "$(ls -A "$TMPDIR")" ]
}

@test "AT-03.1: an absent hs is refused by name, exit 2" {
  export XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/config"
  # The system dirs plus links to yq and bash alone: hs lives beside yq in a
  # package manager's bin, so that dir is left off rather than linked whole.
  local bin="$BATS_TEST_TMPDIR/nohs" tool
  mkdir -p "$bin"
  for tool in yq bash; do
    ln -s "$(command -v "$tool")" "$bin/$tool"
  done
  run env PATH="$bin:/usr/bin:/bin" "$UTILZ_BIN_DIR/arngz" discover
  assert_exit_code 2
  assert_output_contains "the hs tool is not on PATH"
}

@test "AT-03.1: an hs that never answers is refused by name, exit 2, within the timeout" {
  fake_hs hang
  export ARNGZ_HS_TIMEOUT=1
  local start=$SECONDS
  run_arngz discover
  assert_exit_code 2
  assert_output_contains "did not answer within 1s"
  [ $((SECONDS - start)) -lt 10 ]
}

@test "AT-03.1: an hs that writes its response and then hangs is not waited for" {
  fake_hs hang-after-reply
  export ARNGZ_HS_TIMEOUT=30
  local start=$SECONDS
  run_arngz discover
  assert_output_contains "FIXTURE-LINE-1"
  [ $((SECONDS - start)) -lt 10 ]
}

@test "AT-03.1: an hs that exits without a response is refused by name, exit 2" {
  fake_hs none
  run_arngz discover
  assert_exit_code 2
  assert_output_contains "hs exited 0 and wrote no response"
}

@test "AT-03.1: hs's own failures are named: Hammerspoon unreachable, and a Lua error" {
  fake_hs exit-69
  run_arngz discover
  assert_exit_code 2
  assert_output_contains "could not reach Hammerspoon (exit 69)"

  fake_hs lua-error
  run_arngz discover
  assert_exit_code 2
  assert_output_contains "Lua error (hs exit 65)"
  assert_output_contains "attempt to index a nil value"
}

@test "AT-03.1: an engine that answers with an error is refused with its error, exit 2" {
  fake_hs ok "$FIXTURES/responses/engine-error.json"
  run_arngz discover
  assert_exit_code 2
  assert_output_contains "FIXTURE-ENGINE-ERROR"
}

# ============================================================================
# AT-03.2 -- the pure planner, under plain Lua (AC-03.2)
# ============================================================================

# lua5.4 on the CI legs, luajit on hv's machine. NO INTERPRETER IS A FAILURE,
# never a skip: every leg that runs this suite installs one.
lua_bin() {
  local b
  for b in lua5.4 lua luajit; do
    if command -v "$b" >/dev/null 2>&1; then
      command -v "$b"
      return 0
    fi
  done
  return 1
}

@test "AT-03.2: plan is pure: plan.lua makes no Hammerspoon, io, os or require call" {
  local plan="$UTILZ_HOME/opt/arngz/lib/plan.lua" impure='(^|[^A-Za-z0-9_])(hs|io|os)\.|require[ (]'
  [ -f "$plan" ]
  # The control: the same pattern finds the impure module's calls, so a
  # pattern that matches nothing cannot pass for a pure planner.
  grep -Eq "$impure" "$UTILZ_HOME/opt/arngz/lib/arngz.lua"
  run grep -En "$impure" "$plan"
  assert_exit_code 1
}

@test "AT-03.2: the planner's fixtures pass under plain Lua" {
  local lua
  lua="$(lua_bin)" || fail "no Lua interpreter (lua5.4, lua or luajit) on PATH; CI installs lua5.4"
  run "$lua" "$UTILZ_HOME/opt/arngz/test/plan_test.lua" "$UTILZ_HOME/opt/arngz/lib/plan.lua"
  echo "$output"
  assert_success
  assert_output_contains "0 failed"
}

# ============================================================================
# AT-03.4 -- Lua is a declared language, and CI can run the planner (AC-03.4)
# ============================================================================

@test "AT-03.4: lua is a declared language of the project" {
  run jq -r '.languages[]' "$UTILZ_HOME/intent/.config/config.json"
  assert_output_contains "lua"
}

@test "AT-03.4: CI installs lua5.4 on Linux and lua on macOS" {
  local wf="$UTILZ_HOME/.github/workflows/tests.yml"
  grep -q 'apt-get install.*lua5\.4' "$wf"
  grep -q 'brew install.* lua' "$wf"
}
