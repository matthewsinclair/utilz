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

@test "apply and doctor say which work package builds them, exit 2" {
  catalogue
  run_arngz apply zeop1
  assert_exit_code 2
  assert_output_contains "not yet: WP-05"
  run_arngz zeop1
  assert_exit_code 2
  assert_output_contains "not yet: WP-05"
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
  export FAKE_HS_RESPONSE="${2:-$FIXTURES/responses/discover.json}"
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
  assert_output "discover"
  grep -qxF -- "-c" "$FAKE_HS_LOG/argv"
  grep -qF -- "return dofile(\"$UTILZ_HOME/opt/arngz/lib/arngz.lua\").run(\"" "$FAKE_HS_LOG/argv"
}

# WHAT THIS HOLDS, AND WHAT IT CANNOT. hs reads Lua from a stdin that is not a
# terminal, so it must get /dev/null. The CLI says so explicitly, and bash also
# gives a background job /dev/null when job control is off -- so removing the
# explicit redirect alone does NOT redden this (measured 16 Oct 2026). It goes
# red if hs is run in the foreground, or under job control, without the
# redirect: the outcome is what it holds.
@test "AT-03.1: hs runs with stdin from /dev/null, whatever the CLI's own stdin is" {
  fake_hs ok
  echo "return os.exit()" >"$BATS_TEST_TMPDIR/stdin.txt"
  "$UTILZ_BIN_DIR/arngz" discover <"$BATS_TEST_TMPDIR/stdin.txt" >/dev/null 2>&1
  run cat "$FAKE_HS_LOG/stdin"
  assert_output "devnull"
}

@test "AT-03.1: the CLI renders exactly the response's report" {
  fake_hs ok
  run_arngz discover
  assert_success
  assert_output_contains "FIXTURE-LINE-1 main space 1 (user): 3 windows, 3 named, 1 recorded"
  assert_output_contains "FIXTURE-LINE-2 0 Dock bindings"
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

# ============================================================================
# AT-04 -- discover and diff (AC-04.1 to AC-04.4)
# ============================================================================

# discover's stdout alone: bats' run merges stderr into $output, so the report
# is dropped inside the command, never by a redirect on run.
discover_stdout() {
  "$UTILZ_BIN_DIR/arngz" discover "$@" 2>/dev/null
}

# A response computed by the REAL pure functions from a fixture world, for the
# fake hs to hand back: what the engine would answer on hv's machine.
engine_response() {
  local lua out="$BATS_TEST_TMPDIR/response-$1-$2.json"
  lua="$(lua_bin)" || fail "no Lua interpreter (lua5.4, lua or luajit) on PATH; CI installs lua5.4"
  "$lua" "$UTILZ_HOME/opt/arngz/test/discover_response.lua" "$UTILZ_HOME/opt/arngz/lib/plan.lua" \
    "$UTILZ_HOME/opt/arngz/test/fixtures/worlds.lua" "$@" >"$out" || fail "discover_response.lua failed: $*"
  printf '%s\n' "$out"
}

@test "AT-04.1: discover prints a desk the validator accepts, and the report goes to stderr" {
  local response
  response="$(engine_response discover discover_world "" "")"
  fake_hs ok "$response"
  run discover_stdout
  assert_success
  assert_output_contains "desk: discovered"
  assert_output_contains "grid: 8x4"
  refute_output_contains "2 Dock bindings"
  printf '%s\n' "$output" >"$BATS_TEST_TMPDIR/printed.yaml"
  mkdir -p "$XDG_CONFIG_HOME/arngz/desks"
  sed 's/^desk: discovered$/desk: printed/' "$BATS_TEST_TMPDIR/printed.yaml" >"$XDG_CONFIG_HOME/arngz/desks/printed.yaml"
  run_arngz show printed
  assert_success
}

@test "AT-04.1: the request asks the engine to discover, with the grid and name" {
  local response
  response="$(engine_response discover discover_world "" "")"
  fake_hs ok "$response"
  run_arngz discover --grid 12x6
  run yq -r '.verb + " " + .options.grid + " " + .options.name' "$FAKE_HS_LOG/request.json"
  assert_output "discover 12x6 discovered"
}

@test "AT-04.1: every display carries uuid, name without its (n), size and position; full screen is fullscreen" {
  local response
  response="$(engine_response discover discover_world "" "")"
  fake_hs ok "$response"
  run discover_stdout
  assert_output_contains "match: {uuid: SCREEN-B, name: VY229HF, size: 1920x1080, position: above-left}"
  assert_output_contains "match: {uuid: SCREEN-A, name: VY229HF, size: 1920x1080, position: above-right}"
  refute_output_contains "VY229HF ("
  assert_output_contains "layout: fullscreen"
  refute_output_contains "org.hammerspoon.Hammerspoon"
  refute_output_contains "com.apple.Notes"
}

@test "AT-04.1: discover says what it did not record, and reads the Dock bindings" {
  local response
  response="$(engine_response discover discover_world "" "")"
  fake_hs ok "$response"
  run_arngz discover
  assert_output_contains "1 minimized"
  assert_output_contains "1 Accessibility could not name"
  assert_output_contains "on every space"
  assert_output_contains "2 Dock bindings: 1 to all spaces, 1 to one space"
}

@test "AT-04.1: discover refuses a world observe could not read, naming why, and prints no desk" {
  local response
  response="$(engine_response discover unread_world "" "")"
  fake_hs ok "$response"
  run_arngz discover
  assert_exit_code 2
  assert_output_contains "windowsForSpace failed"
  refute_output_contains "desk: discovered"
}

@test "AT-04.1: the same world prints byte-identically, whatever order the engine's JSON keys arrive in" {
  local response reversed
  response="$(engine_response discover discover_world "" "")"
  reversed="$BATS_TEST_TMPDIR/reversed.json"
  jq 'walk(if type == "object" then (to_entries | reverse | from_entries) else . end)' "$response" >"$reversed"
  ! cmp -s "$response" "$reversed"

  fake_hs ok "$response"
  "$UTILZ_BIN_DIR/arngz" discover >"$BATS_TEST_TMPDIR/one.yaml" 2>/dev/null
  "$UTILZ_BIN_DIR/arngz" discover >"$BATS_TEST_TMPDIR/two.yaml" 2>/dev/null
  fake_hs ok "$reversed"
  "$UTILZ_BIN_DIR/arngz" discover >"$BATS_TEST_TMPDIR/three.yaml" 2>/dev/null
  cmp "$BATS_TEST_TMPDIR/one.yaml" "$BATS_TEST_TMPDIR/two.yaml"
  cmp "$BATS_TEST_TMPDIR/one.yaml" "$BATS_TEST_TMPDIR/three.yaml"
}

@test "AT-04.2: a window 3 px off a cell edge is recorded at that cell with its misfit beside the layout" {
  local response
  response="$(engine_response discover discover_world "" "")"
  fake_hs ok "$response"
  run discover_stdout
  printf '%s\n' "$output" | grep -F -A3 'window: ^Docs %(draft%) 100%%$' | grep -qx '            layout: 4,0 4x4'
  printf '%s\n' "$output" | grep -F -A3 'window: ^Docs %(draft%) 100%%$' | grep -qx '            misfit: 3px'
}

@test "AT-04.2: a window spanning part of a cell is snapped and reported, never silently rounded" {
  local response
  response="$(engine_response discover discover_world "" "")"
  fake_hs ok "$response"
  run_arngz discover
  assert_output_contains 'com.microsoft.VSCode "arngz.lua - Utilz" spans part of a cell; snapped to 1,0 4x4, 75px off'
}

@test "AT-04.2: the validator accepts misfit as whole points and refuses anything else" {
  catalogue
  minimal_desk m
  edit_desk m "            layout: 0,0 6x8" "            layout: 0,0 6x8
            misfit: 3px"
  run_arngz show m
  assert_success
  minimal_desk bad
  edit_desk bad "            layout: 0,0 6x8" "            layout: 0,0 6x8
            misfit: 3 points"
  run_arngz show bad
  assert_refusal bad "displays[0].spaces[0].apps[0].misfit" "3 points"
}

@test "AT-04.3: discover --save writes the desk into the catalogue, validated" {
  local response
  response="$(engine_response discover discover_world "" "zeop2")"
  fake_hs ok "$response"
  run_arngz discover --save zeop2
  assert_success
  assert_output_contains "saved $XDG_CONFIG_HOME/arngz/desks/zeop2.yaml"
  run_arngz show zeop2
  assert_success
  assert_output_contains "desk: zeop2"
}

@test "AT-04.3: discover --save refuses an existing desk without --force, naming the file, before asking the engine" {
  local response
  response="$(engine_response discover discover_world "" "zeop2")"
  fake_hs ok "$response"
  mkdir -p "$XDG_CONFIG_HOME/arngz/desks"
  echo "desk: keep me" >"$XDG_CONFIG_HOME/arngz/desks/zeop2.yaml"
  run_arngz discover --save zeop2
  assert_exit_code 2
  assert_output_contains "$XDG_CONFIG_HOME/arngz/desks/zeop2.yaml"
  assert_output_contains "--force"
  [ ! -e "$FAKE_HS_LOG/request.json" ]
  grep -qx "desk: keep me" "$XDG_CONFIG_HOME/arngz/desks/zeop2.yaml"

  run_arngz discover --save zeop2 --force
  assert_success
  run_arngz show zeop2
  assert_success
}

@test "AT-04.3: discover --save refuses a name the validator refuses, and a grid that is not WxH" {
  fake_hs ok "$FIXTURES/responses/discover.json"
  run_arngz discover --save list
  assert_exit_code 2
  assert_output_contains "a desk may not be named like a verb"
  run_arngz discover --save ../out
  assert_exit_code 2
  run_arngz discover --grid 8 by 4
  assert_exit_code 2
  run_arngz discover --force
  assert_exit_code 2
  assert_output_contains "--force only means something with --save"
}

@test "AT-04.4: diff prints each op apply would run with its reason, exits 1, and asks only for a plan" {
  local response
  response="$(engine_response plan off_cell_world base_desk)"
  fake_hs ok "$response"
  catalogue
  run_arngz diff zeop1
  assert_exit_code 1
  assert_output_contains "place window 102 at 600,25 600x800 (displays[0].spaces[0].apps[1]):"
  run yq -r '.verb' "$FAKE_HS_LOG/request.json"
  assert_output "plan"
  run yq -r '.desk.desk' "$FAKE_HS_LOG/request.json"
  assert_output "zeop1"
}

@test "AT-04.4: diff exits 0 and says so when apply would change nothing" {
  local response
  response="$(engine_response plan base_world base_desk)"
  fake_hs ok "$response"
  catalogue
  run_arngz diff zeop1
  assert_success
  assert_output_contains "no change: this machine already matches the desk"
}

@test "AT-04.4: diff refuses a desk the validator refuses before asking the engine" {
  fake_hs ok "$FIXTURES/responses/discover.json"
  catalogue
  minimal_desk g
  edit_desk g "grid: 12x8" "grid: 12 by 8"
  run_arngz diff g
  assert_refusal g "grid" "12 by 8"
  [ ! -e "$FAKE_HS_LOG/request.json" ]
}
