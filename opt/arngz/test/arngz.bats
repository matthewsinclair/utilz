#!/usr/bin/env bats
# arngz.bats - Tests for arngz (ST0026)
#
# The CLI's surface, the desk catalogue and the validator (WP-02), the engine
# contract (WP-03), discover and diff (WP-04), doctor and init (WP-06). Each
# test names the AT it carries. NOTHING HERE REACHES THE REAL MACHINE: the hs
# tool is a fake that answers from fixture files, and doctor and init run on a
# fixture machine whose defaults, pgrep and osascript are stand-ins too.
#
# THE CATALOGUE IS ALWAYS A FIXTURE. Every test points XDG_CONFIG_HOME at its
# own temp directory, which is the one override the design allows, so no test
# can read or write the real ~/.config/arngz. SO IS THE STATE: every helper
# that points XDG_CONFIG_HOME there points XDG_STATE_HOME there too, so the
# current desk an apply or a discover --save records (issue 0070) never
# reaches the real ~/.local/state/arngz.
# AT-01.4 (ST0028 acceptance.md) cites this file: the suite the estate and the Ubuntu loop run on the closing SHA.

load "../../utilz/test/test_helper.bash"

# `run --separate-stderr` (issue 0070's tests) needs bats >= 1.5.0; without
# this declaration bats warns BW02 on every run.
bats_require_minimum_version 1.5.0

FIXTURES="$UTILZ_HOME/opt/arngz/test/fixtures"

# EVERY TEST RUNS AS MACOS, ON ANY MACHINE, unless it pins another platform
# (issue 0083). Off macOS the engine verbs refuse before anything else, and
# CI's Linux leg runs this suite, so its macOS paths are tested there under a
# Darwin uname (test_helper's setup). A test that builds its own PATH, the
# fixture machine among them, puts UTILZ_TEST_PLATFORM_BIN first in it.
# shellcheck disable=SC2034 # read by test_helper's setup()
UTILZ_TEST_PLATFORM=Darwin

# THE ONE CAP ON A SCHEDULED APPLY'S WAIT, for every arm (ST589246c, folded
# into WP 53ef07aa). An arm whose fake engine never answers waits out
# ARNGZ_APPLY_TIMEOUT, 600 s by default, so a red cost ten minutes an arm. An
# arm that sets its own keeps it.
export ARNGZ_APPLY_TIMEOUT=20

# NO ARM PLAYS A REAL SOUND (hv decision 53). apply and discover play the
# marks' sounds through afplay, and an arm whose PATH has /usr/bin finds the
# real one. So the sounds are off for every arm; the marks' arms set them on,
# with the fake afplay first on PATH.
export ARNGZ_SOUNDS=off

run_arngz() {
  run "$UTILZ_BIN_DIR/arngz" "$@"
}

# A fresh catalogue for this test, holding the design's example desk.
catalogue() {
  export XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/config"
  export XDG_STATE_HOME="$BATS_TEST_TMPDIR/state"
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

# A space-separated list the script declares, read from the script itself, so
# no test here carries its own copy of a list the code owns. ST0032/04 added
# two verbs and four of the five copies of "which verbs are there" went stale.
arngz_list() {
  sed -n "s/^$1=\"\\(.*\\)\"\$/\\1/p" "$UTILZ_HOME/opt/arngz/arngz"
}

@test "AT-02.1: utilz arngz is dispatched and its help names every verb and flag" {
  run_utilz arngz --help
  assert_success
  local word
  local -a verbs
  read -r -a verbs <<<"$(arngz_list ARNGZ_VERBS)"
  [ "${#verbs[@]}" -gt 0 ] || fail "ARNGZ_VERBS could not be read from the script"
  for word in "${verbs[@]}" \
    --dry-run --no-create --map --save --force --yes --default; do
    assert_output_contains "$word"
  done
  # No --bind in v1 (D10, AC-05.6), and no --no-launch, since apply never
  # launches an app (ST6d8eed9 AC-35219619.3): help does not offer what apply
  # refuses.
  refute_output_contains "--bind"
  refute_output_contains "--no-launch"
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

# check_app runs for real here, over a stubbed app_path and uname, so a lookup
# that failed is seen through the framework's own reading of it.
@test "AT-02.1: a LaunchServices lookup that fails is said by utilz doctor, never quietly read as missing" {
  run /bin/bash -c "source '$UTILZ_HOME/opt/utilz/lib/common.sh'; uname() { if [[ \"\$1\" == -s ]]; then echo Darwin; else command uname \"\$@\"; fi; }; app_path() { echo 'looking org.hammerspoon.Hammerspoon up through LaunchServices failed (osascript exited 1): not authorized'; return 2; }; run_doctor"
  assert_output_contains "looking org.hammerspoon.Hammerspoon up through LaunchServices failed (osascript exited 1): not authorized"
}

@test "AT-02.1: doctor names the hs tool when it is not on PATH, as optional" {
  local bin="$BATS_TEST_TMPDIR/bin" tool
  mkdir -p "$bin"
  for tool in yq git bash; do
    ln -s "$(command -v "$tool")" "$bin/$tool"
  done
  run /bin/bash -c "export PATH='$UTILZ_TEST_PLATFORM_BIN:$bin:/usr/bin:/bin'; source '$UTILZ_HOME/opt/utilz/lib/common.sh'; check_app() { return 0; }; run_doctor"
  assert_output_contains "Optional: 'hs' is not installed"
  assert_output_contains "declared by arngz"
}

# ============================================================================
# AT-02.2 -- the catalogue verbs (AC-02.2)
# ============================================================================

# init reads the machine as well as making the catalogue (WP-06), so these run
# on the fixture machine (machine, in the AT-06 section) and never the real one.
@test "AT-02.2: init creates the catalogue under XDG_CONFIG_HOME, and a second run says it exists" {
  machine
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
  machine
  unset XDG_CONFIG_HOME
  run_arngz init
  assert_success
  [ -d "$HOME/.config/arngz/desks" ]
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
  local -a verbs
  read -r -a verbs <<<"$(arngz_list ARNGZ_VERBS)"
  [ "${#verbs[@]}" -gt 0 ] || fail "ARNGZ_VERBS could not be read from the script"
  for verb in "${verbs[@]}"; do
    minimal_desk "$verb"
    run_arngz show "$verb"
    assert_refusal "$verb" "desk name" "$verb"
    run_arngz apply "$verb"
    assert_exit_code 2
    assert_output_contains "desk '$verb'"
  done
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
  cp "$FIXTURES/fake-macos/afplay" "$BATS_TEST_TMPDIR/fakebin/afplay"
  export PATH="$BATS_TEST_TMPDIR/fakebin:$PATH"
  export XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/config"
  export XDG_STATE_HOME="$BATS_TEST_TMPDIR/state"
  export TMPDIR="$BATS_TEST_TMPDIR/tmp"
  mkdir -p "$TMPDIR"
}

@test "AT-03.1: the request holds exactly verb, desk, options, run, log and end_sound, and hs runs the module's run on it" {
  fake_hs ok
  run_arngz discover
  run yq -o json -I0 'keys' "$FAKE_HS_LOG/request.json"
  # end_sound is the end mark's sound, for an engine the CLI stopped waiting
  # for (hv decision 53); empty here, since the suite's sounds are off.
  assert_output '["verb","desk","options","run","log","end_sound"]'
  # run and log are the run's id and its log (ST589246c), for the engine's records.
  run yq -r '.log' "$FAKE_HS_LOG/request.json"
  assert_output "$XDG_STATE_HOME/arngz/arngz.log"
  run yq -r '.run' "$FAKE_HS_LOG/request.json"
  # A run id, so an empty one on both sides cannot pass as equal.
  [[ "$output" =~ ^[0-9]{8}T[0-9]{6}Z-[0-9]+$ ]] || fail "the request's run is not a run id: '$output'"
  assert_output "$(awk '$4 == "start" { id = $2 } END { print id }' "$XDG_STATE_HOME/arngz/arngz.log")"
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
  # The temp dir of a call that succeeded is removed: the request was made
  # under TMPDIR, which is still there, and holds nothing now.
  grep -qF "$TMPDIR/arngz." "$FAKE_HS_LOG/argv"
  [ -d "$TMPDIR" ]
  [ -z "$(ls -A "$TMPDIR")" ]
}

@test "AT-03.1: an absent hs is refused by name, exit 2" {
  export XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/config"
  # The hs tool is told as doctor tells it (hs_tool_state), which looks under
  # the prefix too, so the prefix is the test's own, never /opt/homebrew.
  export ARNGZ_HS_PREFIX="$BATS_TEST_TMPDIR/prefix"
  # The system dirs plus links to yq and bash alone: hs lives beside yq in a
  # package manager's bin, so that dir is left off rather than linked whole.
  local bin="$BATS_TEST_TMPDIR/nohs" tool
  mkdir -p "$bin"
  for tool in yq bash; do
    ln -s "$(command -v "$tool")" "$bin/$tool"
  done
  run env PATH="$UTILZ_TEST_PLATFORM_BIN:$bin:/usr/bin:/bin" "$UTILZ_BIN_DIR/arngz" discover
  assert_exit_code 2
  assert_output_contains "the hs tool, which arngz reaches Hammerspoon through, is missing: not on PATH; fix: arngz init --yes links it under $ARNGZ_HS_PREFIX"
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

# Issue I7085193: an hs that hangs after its response is waited for only until
# its own timeout and the margin have passed, never stopped while it may still
# take Hammerspoon's reply; its report is rendered all the same.
@test "AT-03.1: an hs that writes its response and then hangs is waited for only to its own timeout" {
  fake_hs hang-after-reply
  export ARNGZ_HS_TIMEOUT=2
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

@test "AT-03.1: hs's own failures are named: Hammerspoon unreachable, a reply too late, and a Lua error" {
  fake_hs exit-69
  run_arngz discover
  assert_exit_code 2
  assert_output_contains "could not reach Hammerspoon (exit 69)"

  # Delivered and not answered in time: Hammerspoon is running, so this is
  # never "could not reach" it, and never init's fix.
  fake_hs receive-timeout
  export ARNGZ_HS_TIMEOUT=7
  run_arngz discover
  assert_exit_code 2
  assert_output_contains "hs gave up on discover after ${ARNGZ_HS_TIMEOUT}s with receive timeout: the request reached Hammerspoon, which is running, and no answer came in time"
  assert_output_contains "; fix: Hammerspoon is busy or hung: let an arngz apply that is running finish"
  refute_output_contains "could not reach Hammerspoon"
  refute_output_contains "init --yes"

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

@test "AT-03.1: a refusal after hs was asked names the request it kept, and what fixes it, and that request is there" {
  fake_hs exit-69
  run_arngz discover
  assert_exit_code 2
  local kept
  kept="$(printf '%s\n' "$output" | sed -n 's/.*(request kept at \([^)]*\)).*/\1/p')"
  [[ "$kept" == "$TMPDIR"/arngz.*/request.json ]]
  [ -f "$kept" ]
  assert_output_contains "; fix: arngz init --yes makes Hammerspoon's config load hs.ipc; then reload that config"
}

@test "AT-03.1: a request that was never written is not named as kept, and its temp dir is gone" {
  fake_hs ok
  # A quote in TMPDIR: the dir is made, and then the call is refused, because
  # its path would end the Lua string the request goes into.
  export TMPDIR="$BATS_TEST_TMPDIR/a\"b"
  mkdir -p "$TMPDIR"
  run_arngz discover
  assert_exit_code 2
  assert_output_contains "a path holds a quote or backslash"
  refute_output_contains "request kept at"
  [ -d "$TMPDIR" ]
  [ -z "$(ls -A "$TMPDIR")" ]
  [ ! -e "$FAKE_HS_LOG/argv" ]
}

# ============================================================================
# AT-03.2 -- the pure planner, under plain Lua (AC-03.2)
# ============================================================================

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
  assert_lua_suite_summary plan_test
}

@test "the Mission Control finder's pure part passes under plain Lua" {
  local lua
  lua="$(lua_bin)" || fail "no Lua interpreter (lua5.4, lua or luajit) on PATH; CI installs lua5.4"
  run "$lua" "$UTILZ_HOME/opt/arngz/test/mc_test.lua" "$UTILZ_HOME/opt/arngz/lib/mc.lua" "$UTILZ_HOME/opt/arngz/lib/plan.lua"
  echo "$output"
  assert_success
  assert_lua_suite_summary mc_test
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
  printf '%s\n' "$output" | grep -F -A3 'window: Docs %(draft%) 100%%' | grep -qx '            layout: 4,0 4x4'
  printf '%s\n' "$output" | grep -F -A3 'window: Docs %(draft%) 100%%' | grep -qx '            misfit: 3px'
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

# Issue I19d4fa6: a desk that would leave out windows arngz could not name.
@test "I19d4fa6: a plain discover with gaps prints the desk, names each gap, and exits 1" {
  fake_hs ok "$FIXTURES/responses/discover-gaps.json"
  run_arngz discover
  assert_exit_code 1
  assert_output_contains "desk: discovered"
  assert_output_contains "not recorded: Console on desktop 3 on main:"
}

@test "I19d4fa6: a refused save names each gap, exits 2, and leaves the desk file byte for byte, though --force" {
  fake_hs ok "$FIXTURES/responses/discover-refused.json"
  mkdir -p "$XDG_CONFIG_HOME/arngz/desks"
  echo "desk: keep me" >"$XDG_CONFIG_HOME/arngz/desks/zeop2.yaml"
  cp "$XDG_CONFIG_HOME/arngz/desks/zeop2.yaml" "$BATS_TEST_TMPDIR/before.yaml"
  run_arngz discover --save zeop2 --force
  assert_exit_code 2
  assert_output_contains "not recorded: Console on desktop 3 on main:"
  assert_output_contains "arngz: the engine refused discover: refused, nothing saved: 1 window could not be named"
  assert_output_contains "--with-gaps"
  cmp -s "$BATS_TEST_TMPDIR/before.yaml" "$XDG_CONFIG_HOME/arngz/desks/zeop2.yaml" ||
    fail "the refused save changed the desk file"
  run yq -r '.options.force' "$FAKE_HS_LOG/request.json"
  assert_output "true"
}

@test "I19d4fa6: --save --with-gaps saves the desk, names each gap, and exits 1; --with-gaps alone is refused" {
  local response
  response="$(engine_response discover discover_world "" "zeop3")"
  yq -o json '.gaps = ["not recorded: Console on desktop 3 on main: arngz showed that desktop, and Accessibility still could not name its window"] | .verdict = "save with gaps"' \
    "$response" >"$BATS_TEST_TMPDIR/with-gaps.json"
  fake_hs ok "$BATS_TEST_TMPDIR/with-gaps.json"
  run_arngz discover --save zeop3 --with-gaps
  assert_exit_code 1
  assert_output_contains "not recorded: Console on desktop 3 on main:"
  [ -s "$XDG_CONFIG_HOME/arngz/desks/zeop3.yaml" ] || fail "nothing saved"
  run yq -r '.options.with_gaps' "$FAKE_HS_LOG/request.json"
  assert_output "true"
  run_arngz discover --with-gaps
  assert_exit_code 2
  assert_output_contains "--with-gaps only means something with --save <desk>"
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

@test "0132: diff prints an app running with no window to name, and exits 0 when nothing else would change" {
  local response
  response="$(engine_response plan unseen_world base_desk)"
  fake_hs ok "$response"
  catalogue
  run_arngz diff zeop1
  assert_success
  assert_output_contains "unseen com.apple.Safari (displays[0].spaces[0].apps[1]): com.apple.Safari is running and no standard window of it"
}

@test "0132: diff counts an unseen entry planned while a window read failed, exit 1" {
  local response
  response="$(engine_response plan unseen_unread_world base_desk)"
  fake_hs ok "$response"
  catalogue
  run_arngz diff zeop1
  assert_exit_code 1
  assert_output_contains "unseen com.apple.Safari (displays[0].spaces[0].apps[1]):"
  assert_output_contains "Hammerspoon's window filter failed (no filter), so windows on desktops not shown could not be named"
}

@test "0132: diff refuses a plan whose exit is not 0 or 1, exit 2, its response kept" {
  local response="$BATS_TEST_TMPDIR/no-exit.json"
  printf '%s\n' '{"status":"ok","verb":"plan","ops":[],"report":["no change: this machine already matches the desk"]}' >"$response"
  fake_hs ok "$response"
  catalogue
  run_arngz diff zeop1
  assert_exit_code 2
  assert_output_contains "the engine's plan carries exit 'null', not 0 or 1 (kept at "
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

# ============================================================================
# AT-05 -- apply (AC-05.1, AC-05.3, AC-05.6, AC-05.7)
# ============================================================================

# apply on the fixture machine (below): its preferences as hv's, the fake hs
# on PATH answering in MODE with RESPONSE, and the design's example desk in
# the catalogue. RESPONSE is made before the machine narrows PATH, because
# making it needs Lua.
apply_machine() {
  machine
  hs_on_path "$1" "$2"
  catalogue
}

# The response the engine sends for an apply whose results are RESULTS, a
# function in worlds.lua, with the report and exit code apply_report gives.
apply_response() {
  engine_response apply "$1" base_desk
}

@test "AT-05.1: apply --dry-run asks only for a plan, prints every op with its reason, and exits 0" {
  local response
  response="$(engine_response plan off_cell_world base_desk)"
  apply_machine ok "$response"
  run_arngz apply --dry-run zeop1
  assert_success
  assert_output_contains "place window 102 at 600,25 600x800 (displays[0].spaces[0].apps[1]):"
  run yq -r '.verb' "$FAKE_HS_LOG/request.json"
  assert_output "plan"
}

@test "AT-05.1: apply --dry-run judges no preference, because it changes nothing" {
  local response
  response="$(engine_response plan base_world base_desk)"
  apply_machine ok "$response"
  pref com.apple.dock mru-spaces 1
  run_arngz apply --dry-run zeop1
  assert_success
  assert_output_contains "no change"
}

@test "AT-05.3: every entry placed exits 0, the engine's report printed as it wrote it" {
  local response
  response="$(apply_response placed_results)"
  apply_machine scheduled "$response"
  run_arngz apply zeop1
  assert_success
  assert_output_contains "com.apple.mail (displays[0].spaces[0].apps[0]): placed"
  run yq -r '.verb + " " + .desk.desk' "$FAKE_HS_LOG/request.json"
  assert_output "apply zeop1"
}

# AT-35219619.2 (ST6d8eed9 acceptance.md) cites this arm.
@test "ST6d8eed9: an app that is not running is reported not running, and apply exits 0 (AC-35219619.2)" {
  local response
  response="$(apply_response not_running_results)"
  apply_machine scheduled "$response"
  run_arngz apply zeop1
  assert_success
  assert_output_contains "com.apple.Safari (displays[0].spaces[0].apps[1]): not running: com.apple.Safari is not running, and apply does not launch apps"
  assert_output_contains "com.apple.mail (displays[0].spaces[0].apps[0]): placed"
}

# AT-35219619.3 (ST6d8eed9 acceptance.md) cites this arm.
@test "ST6d8eed9: arngz holds no code that launches an app (AC-35219619.3)" {
  # The engine is where apply launched apps: no launch call is left in it.
  # windows.js (WP 88504807) is read too: doShellScript and .launch( are the
  # ways JXA launches an app.
  run grep -n -E 'open -b|launchOrFocus|launchApplication|exec_launch|LAUNCH_TIMEOUT|doShellScript|\.launch\(' \
    "$UTILZ_HOME"/opt/arngz/lib/*.lua "$UTILZ_HOME"/opt/arngz/lib/*.js
  # grep's 1 is "no line matched"; its 2 would be a file it could not read.
  [ "$status" -eq 1 ] || fail "grep exited $status: $output"
  # The CLI runs no open command. Its fix lines that tell a person to run
  # `open -b` for Hammerspoon itself are words it prints, never a command.
  run grep -n -E '^[[:space:]]*(command[[:space:]]+)?open[[:space:]]' "$UTILZ_HOME/opt/arngz/arngz"
  [ "$status" -eq 1 ] || fail "grep exited $status: $output"
}

# dc's arm for windows.js, the window list's reader (WP 88504807, hv decision
# 49). osacompile only compiles, so the script never runs. The absolute path,
# not uname, says macOS: test_helper stubs uname as Darwin.
@test "ST6d8eed9: lib/windows.js compiles as JavaScript for Automation" {
  [[ -x /usr/bin/osacompile ]] || skip "osacompile is macOS's, and arngz refuses off macOS"
  run /usr/bin/osacompile -l JavaScript -o "$BATS_TEST_TMPDIR/windows.scpt" "$UTILZ_HOME/opt/arngz/lib/windows.js"
  assert_success
  [ -s "$BATS_TEST_TMPDIR/windows.scpt" ] || fail "osacompile wrote no script: $output"
}

# Issue I40cbb9b (hv decision 49): hs.window.get reads every running app's
# windows through Accessibility at each call, so the engine looks a window up
# in observe's index and calls it nowhere.
@test "I40cbb9b: arngz's engine makes no hs.window.get call" {
  run grep -n -E 'hs\.window\.get[[:space:]]*\(|window\.windowForID[[:space:]]*\(' "$UTILZ_HOME"/opt/arngz/lib/*.lua
  # grep's 1 is "no line matched"; its 2 would be a file it could not read.
  [ "$status" -eq 1 ] || fail "grep exited $status: $output"
}

# ============================================================================
# ST6d8eed9 WP a45b3aeb -- a reload and one retry after the window filter fails
# ============================================================================

# The words the engine gives a failed window filter (P.filter_words), with a
# fixture's reason in the brackets.
FILTER_WORDS="Hammerspoon's window filter failed (hs/uielement.lua:134: FIXTURE)"

# The reload verb's answer, and the state verb's from the old Lua state and
# from a fresh one.
RELOADING='{"status":"ok","verb":"reload","reloading":true}'
OLD_STATE='{"status":"ok","verb":"state","reloading":true}'
FRESH_STATE='{"status":"ok","verb":"state","reloading":false}'

# The engine's answers for a command that reloads, one per ask in the order
# the CLI asks them, for fake-hs's sequence mode. After apply_machine or
# fake_hs, given the mode sequence.
reload_sequence() {
  export FAKE_HS_SEQUENCE="$BATS_TEST_TMPDIR/sequence"
  mkdir -p "$FAKE_HS_SEQUENCE"
}

# answer N JSON: ask N's response. answer_mode N MODE: ask N answered as
# fake-hs's MODE. N is rest for every ask with no answer of its own.
answer() {
  printf '%s\n' "$2" >"$FAKE_HS_SEQUENCE/$1.json"
}

answer_mode() {
  printf '%s\n' "$2" >"$FAKE_HS_SEQUENCE/$1.mode"
}

# The engine's refusal of VERB when the window filter failed at its read and
# the request let it ask for a reload.
reload_refusal() {
  V="$1" W="$FILTER_WORDS" F="arngz reloads Hammerspoon's config and runs it again" yq -n -o json -I0 \
    '{"status": "error", "kind": "reload", "verb": strenv(V), "error": strenv(W), "fix": strenv(F)}'
}

# A refusal of VERB with WORDS and FIX, as the engine gives one.
engine_refusal() {
  V="$1" W="$2" F="$3" yq -n -o json -I0 \
    '{"status": "error", "kind": "refused", "verb": strenv(V), "error": strenv(W), "fix": strenv(F)}'
}

# The answers the test numbered, which is how many asks a command that took
# each of them made; and the asks the fake took.
answers_numbered() {
  find "$FAKE_HS_SEQUENCE" -type f -name '[0-9]*' | wc -l | tr -d ' '
}

asks_made() {
  cat "$FAKE_HS_LOG/asks"
}

# The verb of ask N, and an option it carried.
ask_verb() {
  yq -r '.verb' "$FAKE_HS_LOG/request.$1.json"
}

ask_option() {
  K="$2" yq -r '.options[strenv(K)]' "$FAKE_HS_LOG/request.$1.json"
}

# AT-a45b3aeb.3 (ST6d8eed9 acceptance.md) cites this arm and the next.
@test "ST6d8eed9: a filter that failed at apply's read reloads Hammerspoon once, waits for its fresh config, and asks apply again (AC-a45b3aeb.3)" {
  local response last n
  response="$(apply_response placed_results)"
  apply_machine sequence
  reload_sequence
  answer 1 "$(reload_refusal apply)"
  answer 2 "$RELOADING"
  answer 3 "$OLD_STATE"
  answer_mode 4 exit-69
  answer 5 "$FRESH_STATE"
  cp "$response" "$FAKE_HS_SEQUENCE/6.json"
  run_arngz apply zeop1
  assert_success
  # The second answer is the command's, and one line before it says why.
  assert_output_contains "$FILTER_WORDS, so arngz reloaded Hammerspoon's config and ran apply again"
  assert_output_contains "com.apple.mail (displays[0].spaces[0].apps[0]): placed"
  # Every answer was asked for, and no more: one reload, then state until a
  # fresh config answered, then one retry.
  last="$(asks_made)"
  [ "$last" -eq "$(answers_numbered)" ] || fail "the fake was asked $last times, for $(answers_numbered) answers"
  [ "$(ask_verb 1)" = apply ] || fail "ask 1 is $(ask_verb 1)"
  [ "$(ask_verb 2)" = reload ] || fail "ask 2 is $(ask_verb 2)"
  for ((n = 3; n < last; n++)); do
    [ "$(ask_verb "$n")" = state ] || fail "ask $n is $(ask_verb "$n"), not state"
  done
  [ "$(ask_verb "$last")" = apply ] || fail "the last ask is $(ask_verb "$last")"
  [ "$(ask_option 1 may_reload)" = true ] || fail "the first apply did not let the engine ask for a reload"
  [ "$(ask_option "$last" may_reload)" = false ] || fail "the retry let the engine ask for a second reload"
  [ "$(ask_option "$last" after_reload_of)" = "$(yq -r '.run' "$FAKE_HS_LOG/request.1.json")" ] ||
    fail "the retry does not name the run it follows: $(ask_option "$last" after_reload_of)"
  # The run log has each step of the reload.
  grep -qF " cli reload apply: $FILTER_WORDS; asking Hammerspoon to reload its config" "$(run_log)" ||
    fail "no record of the reload asked for: $(cat "$(run_log)")"
  grep -q ' cli reload Hammerspoon answered from a fresh config after [0-9]* s; asking apply again$' "$(run_log)" ||
    fail "no record of Hammerspoon back: $(cat "$(run_log)")"
}

@test "ST6d8eed9: an apply that ran while the filter failed asks for the reload in its answer, and the retry's answer is the command's (AC-a45b3aeb.3)" {
  local first="$BATS_TEST_TMPDIR/ran.json" second last
  W="$FILTER_WORDS" yq -o json '.reload = strenv(W)' "$(apply_response unseen_results)" >"$first"
  second="$(apply_response placed_results)"
  apply_machine sequence
  reload_sequence
  cp "$first" "$FAKE_HS_SEQUENCE/1.json"
  answer 2 "$RELOADING"
  answer 3 "$FRESH_STATE"
  cp "$second" "$FAKE_HS_SEQUENCE/4.json"
  run_arngz apply zeop1
  assert_success
  assert_output_contains "$FILTER_WORDS, so arngz reloaded Hammerspoon's config and ran apply again"
  assert_output_contains "com.apple.Safari (displays[0].spaces[0].apps[1]): placed"
  refute_output_contains "): unseen"
  last="$(asks_made)"
  [ "$last" -eq "$(answers_numbered)" ] || fail "the fake was asked $last times, for $(answers_numbered) answers"
  [ "$(ask_verb "$last")" = apply ] || fail "the last ask is $(ask_verb "$last")"
  # The first apply ran, so its desk is the current one.
  run --separate-stderr "$UTILZ_BIN_DIR/arngz" current
  assert_success
  assert_output "zeop1"
}

# AT-a45b3aeb.4 (ST6d8eed9 acceptance.md) cites this arm, with log_test.lua's
# arm "the reload and state verbs".
@test "ST6d8eed9: a reload the engine refuses while a run is live leaves the first answer, with the refusal's fix, and asks nothing more (AC-a45b3aeb.4)" {
  apply_machine sequence
  reload_sequence
  answer 1 "$(reload_refusal apply)"
  answer 2 "$(engine_refusal reload "an apply is running (asked for at 2026-11-25T10:00:00Z)" \
    "another arngz run is live; run it again when it has finished")"
  run_arngz apply zeop1
  assert_exit_code 2
  assert_output_contains "the engine refused apply: $FILTER_WORDS"
  assert_output_contains "Hammerspoon's config was not reloaded: the engine refused reload: an apply is running"
  assert_output_contains "fix: another arngz run is live; run it again when it has finished"
  [ "$(asks_made)" -eq "$(answers_numbered)" ] || fail "the fake was asked $(asks_made) times, for $(answers_numbered) answers"
}

# AT-a45b3aeb.5 (ST6d8eed9 acceptance.md) cites this arm.
@test "ST6d8eed9: a Hammerspoon not back within ARNGZ_RELOAD_TIMEOUT is exit 1 with the words, and apply is not asked again (AC-a45b3aeb.5)" {
  local last n numbered
  apply_machine sequence
  reload_sequence
  export ARNGZ_RELOAD_TIMEOUT=2
  answer 1 "$(reload_refusal apply)"
  answer 2 "$RELOADING"
  answer_mode rest exit-69
  run_arngz apply zeop1
  assert_exit_code 1
  assert_output_contains "after the reload of its config, Hammerspoon did not answer within $ARNGZ_RELOAD_TIMEOUT s"
  assert_output_contains "fix: open Hammerspoon and read its console"
  last="$(asks_made)"
  numbered="$(answers_numbered)"
  [ "$last" -gt "$numbered" ] || fail "the CLI never asked whether Hammerspoon was back"
  for ((n = numbered + 1; n <= last; n++)); do
    [ "$(ask_verb "$n")" = state ] || fail "ask $n is $(ask_verb "$n"), not state"
  done
}

@test "ST6d8eed9: a bad ARNGZ_RELOAD_TIMEOUT is refused before anything is sent, exit 2" {
  apply_machine scheduled "$(apply_response placed_results)"
  export ARNGZ_RELOAD_TIMEOUT=soon
  run_arngz apply zeop1
  assert_exit_code 2
  assert_output_contains "ARNGZ_RELOAD_TIMEOUT = 'soon'"
  [ ! -e "$FAKE_HS_LOG/request.json" ]
}

# AT-a45b3aeb.6 (ST6d8eed9 acceptance.md) cites this arm, with log_test.lua's
# discover checks in arm "the reload and state verbs".
@test "ST6d8eed9: discover --save reloads once, and saves nothing when the filter failed again (AC-a45b3aeb.6)" {
  local last
  fake_hs sequence
  catalogue
  reload_sequence
  answer 1 "$(reload_refusal discover)"
  answer 2 "$RELOADING"
  answer 3 "$FRESH_STATE"
  answer 4 "$(engine_refusal discover \
    "$FILTER_WORDS, so windows on desktops not shown could not be named, and a desk read now would leave them out" \
    "arngz reloaded Hammerspoon's config and its window filter failed again: quit Hammerspoon, open it again, then run arngz again")"
  run_arngz discover --save fresh
  assert_exit_code 2
  assert_output_contains "$FILTER_WORDS, so arngz reloaded Hammerspoon's config and ran discover again"
  assert_output_contains "quit Hammerspoon, open it again, then run arngz again"
  [ ! -e "$CAT/fresh.yaml" ] || fail "discover saved a desk from a read whose filter failed"
  last="$(asks_made)"
  [ "$last" -eq "$(answers_numbered)" ] || fail "the fake was asked $last times, for $(answers_numbered) answers"
  [ "$(ask_option "$last" may_reload)" = false ] || fail "the retry let the engine ask for a second reload"
}

# AT-a45b3aeb.7 (ST6d8eed9 acceptance.md) cites this arm.
@test "ST6d8eed9: diff and apply --dry-run never let the engine ask for a reload, and never reload (AC-a45b3aeb.7)" {
  local response="$BATS_TEST_TMPDIR/plan-reload.json"
  # A plan that carries reload, which the engine never sends: a CLI that acted
  # on it would ask a second time.
  W="$FILTER_WORDS" yq -o json '.reload = strenv(W)' "$(engine_response plan base_world base_desk)" >"$response"
  apply_machine ok "$response"
  # A red then waits for a fresh config that never comes: a second, not 30.
  export ARNGZ_RELOAD_TIMEOUT=1
  run_arngz diff zeop1
  assert_success
  [ "$(ask_option 1 may_reload)" = null ] || fail "diff let the engine ask for a reload"
  [ ! -e "$FAKE_HS_LOG/request.2.json" ] || fail "diff asked the engine again: $(ask_verb 2)"
  rm -f "$FAKE_HS_LOG"/request.* "$FAKE_HS_LOG/asks"
  run_arngz apply --dry-run zeop1
  assert_success
  [ "$(ask_option 1 may_reload)" = null ] || fail "apply --dry-run let the engine ask for a reload"
  [ ! -e "$FAKE_HS_LOG/request.2.json" ] || fail "apply --dry-run asked the engine again: $(ask_verb 2)"
}

@test "0132: an app running with no window to name is reported unseen, and apply exits 0" {
  local response
  response="$(apply_response unseen_results)"
  apply_machine scheduled "$response"
  run_arngz apply zeop1
  assert_success
  assert_output_contains "com.apple.Safari (displays[0].spaces[0].apps[1]): unseen: com.apple.Safari is running and no standard window of it"
  assert_output_contains "com.apple.mail (displays[0].spaces[0].apps[0]): placed"
}

# The answer comes FAKE_HS_DELAY after the hs call, later than the hs call's
# own deadline, so only apply's deadline can be what waits for it. The hs
# deadline must still leave the fake room to start its writer: the CLI counts
# it in bash's whole SECONDS, so 1 s is anywhere from 0 to 1 s, and a fake
# killed before it starts the writer leaves nothing to answer. With a 1 s hs
# deadline this arm waited out apply's 600 s default under load (R-full at
# 0342aee6). So 4 s for hs, the answer 2 s after that, and apply's own
# deadline at 20 s, so a red costs 20 s, not 600.
@test "AT-05.3: apply waits for a scheduled answer past the hs call, on its own deadline" {
  local response
  response="$(apply_response placed_results)"
  apply_machine scheduled "$response"
  export FAKE_HS_DELAY=6 ARNGZ_HS_TIMEOUT=4 ARNGZ_APPLY_TIMEOUT=20
  run_arngz apply zeop1
  assert_success
  assert_output_contains ": placed"
}

@test "AT-05.3: a scheduled apply that never answers is said, exit 1, never as nothing changed" {
  local response
  response="$(apply_response placed_results)"
  apply_machine scheduled-never "$response"
  export ARNGZ_APPLY_TIMEOUT=1
  run_arngz apply zeop1
  assert_exit_code 1
  assert_output_contains "has not answered within 1s; it may still be running"
  assert_output_contains "ARNGZ_APPLY_TIMEOUT"
  assert_output_contains "request kept at"
}

@test "AT-05.3: a bad ARNGZ_APPLY_TIMEOUT is refused before anything is sent, exit 2" {
  apply_machine scheduled "$FIXTURES/responses/observe.json"
  export ARNGZ_APPLY_TIMEOUT=soon
  run_arngz apply zeop1
  assert_exit_code 2
  assert_output_contains "ARNGZ_APPLY_TIMEOUT = 'soon'"
  [ ! -e "$FAKE_HS_LOG/request.json" ]
}

@test "AT-05.3: a diff is not a scheduled verb, so a bad ARNGZ_APPLY_TIMEOUT does not touch it" {
  local response
  response="$(engine_response plan base_world base_desk)"
  apply_machine ok "$response"
  export ARNGZ_APPLY_TIMEOUT=soon
  run_arngz diff zeop1
  assert_success
}

@test "AT-05.3: an apply whose answer carries no 0 or 1 exit is exit 1, its response kept, never nothing changed" {
  local response="$BATS_TEST_TMPDIR/noexit.json"
  printf '%s\n' '{"status":"ok","verb":"apply","report":["a line"]}' >"$response"
  apply_machine scheduled "$response"
  run_arngz apply zeop1
  assert_exit_code 1
  assert_output_contains "apply ran, and its exit code reads 'null'"
  assert_output_contains "response is kept at"
}

@test "AT-05.3: a refusal before anything changed exits 2 with the engine's reason, not as the engine failing" {
  local response="$BATS_TEST_TMPDIR/refused.json"
  printf '%s\n' '{"status":"error","kind":"refused","verb":"apply","error":"FIXTURE-REFUSAL displays[0] (left) matches no screen"}' >"$response"
  apply_machine scheduled "$response"
  run_arngz apply zeop1
  assert_exit_code 2
  assert_output_contains "the engine refused apply: FIXTURE-REFUSAL displays[0] (left) matches no screen"
  refute_output_contains "engine failing"
}

@test "AT-05.3: an apply while one runs is refused, exit 2, with the engine's fix naming hs.reload" {
  local response="$BATS_TEST_TMPDIR/running.json"
  printf '%s\n' '{"status":"error","kind":"refused","verb":"apply","error":"an apply is already running (asked for at 2026-10-16T13:00:00Z)","fix":"wait for it to finish; if none is running, reload Hammerspoon'"'"'s config (hs.reload() in its console)"}' >"$response"
  apply_machine scheduled "$response"
  run_arngz apply zeop1
  assert_exit_code 2
  assert_output_contains "the engine refused apply: an apply is already running (asked for at 2026-10-16T13:00:00Z)"
  assert_output_contains "hs.reload() in its console"
}

@test "AT-05.3: the engine's own error during apply exits 1, its response kept, never as nothing changed" {
  local response="$BATS_TEST_TMPDIR/failed.json"
  printf '%s\n' '{"status":"error","kind":"lua_error","verb":"apply","error":"FIXTURE attempt to index a nil value"}' >"$response"
  apply_machine scheduled "$response"
  run_arngz apply zeop1
  assert_exit_code 1
  assert_output_contains "the engine failed on apply: FIXTURE attempt to index a nil value"
  assert_output_contains "its response is kept at"
  assert_output_contains "engine failing"
}

@test "AT-05.3: the same error under --dry-run, which changes nothing, is a refusal, exit 2" {
  local response="$BATS_TEST_TMPDIR/failed.json"
  printf '%s\n' '{"status":"error","kind":"lua_error","verb":"plan","error":"FIXTURE attempt to index a nil value"}' >"$response"
  apply_machine ok "$response"
  run_arngz apply --dry-run zeop1
  assert_exit_code 2
  assert_output_contains "the engine failed on plan"
}

@test "AT-05.3: an hs that hangs after apply was sent is waited out, then said as maybe running, exit 1" {
  apply_machine hang "$FIXTURES/responses/observe.json"
  export ARNGZ_HS_TIMEOUT=1 ARNGZ_APPLY_TIMEOUT=1
  run_arngz apply zeop1
  assert_exit_code 1
  assert_output_contains "has not answered within 1s; it may still be running"
}

@test "AT-05.3: an hs that ran and scheduled nothing is not waited on: the engine failing, exit 2, at once" {
  apply_machine none "$FIXTURES/responses/observe.json"
  export ARNGZ_APPLY_TIMEOUT=30
  local t0=$SECONDS
  run_arngz apply zeop1
  assert_exit_code 2
  assert_output_contains "wrote no response"
  [ $((SECONDS - t0)) -lt 10 ]
}

@test "AT-05.3: an hs that gave up with receive timeout may have delivered apply: waited out, exit 1" {
  apply_machine receive-timeout "$FIXTURES/responses/observe.json"
  export ARNGZ_APPLY_TIMEOUT=1
  run_arngz apply zeop1
  assert_exit_code 1
  assert_output_contains "may still be running"
}

@test "AT-05.3: an apply Hammerspoon never received is a refusal, exit 2" {
  apply_machine exit-69 "$FIXTURES/responses/observe.json"
  run_arngz apply zeop1
  assert_exit_code 2
  assert_output_contains "exit 69"
}

@test "AT-05.3: the CLI and the engine schedule the same verbs" {
  local cli lua
  cli="$(sed -n 's/^SCHEDULED_VERBS="\(.*\)"$/\1/p' "$UTILZ_HOME/opt/arngz/arngz")"
  lua="$(sed -n 's/^local SCHEDULED = { \(.*\) }$/\1/p' "$UTILZ_HOME/opt/arngz/lib/arngz.lua" | sed 's/ = true//g; s/,//g')"
  [ -n "$cli" ]
  [ "$cli" = "$lua" ]
}

@test "AT-05.3: a preference that does not hold refuses before the engine is asked, exit 2" {
  apply_machine ok "$FIXTURES/responses/observe.json"
  pref com.apple.dock mru-spaces 1
  run_arngz apply zeop1
  assert_exit_code 2
  assert_output_contains "auto-rearrange is on"
  assert_output_contains "fix:"
  [ ! -e "$FAKE_HS_LOG/request.json" ]
}

@test "AT-05.3: --no-create and --map reach the engine as options" {
  local response
  response="$(apply_response placed_results)"
  apply_machine scheduled "$response"
  run_arngz apply --no-create --map left=AAAA-1 --map=right=BBBB-2 zeop1
  assert_success
  # apply's first try lets the engine ask for a reload (ST6d8eed9 WP a45b3aeb).
  run yq -o json -I0 '.options' "$FAKE_HS_LOG/request.json"
  assert_output '{"no_create":true,"map":{"left":"AAAA-1","right":"BBBB-2"},"may_reload":true}'
}

@test "AT-05.3: apply with no options sends no_create off and an empty map" {
  local response
  response="$(apply_response placed_results)"
  apply_machine scheduled "$response"
  run_arngz apply zeop1
  # apply's first try lets the engine ask for a reload (ST6d8eed9 WP a45b3aeb).
  run yq -o json -I0 '.options' "$FAKE_HS_LOG/request.json"
  assert_output '{"no_create":false,"map":{},"may_reload":true}'
}

# AT-35219619.3 (ST6d8eed9 acceptance.md) cites this arm too.
@test "ST6d8eed9: --no-launch is refused as an unknown option, before anything is asked (AC-35219619.3)" {
  apply_machine ok "$FIXTURES/responses/observe.json"
  run_arngz apply --no-launch zeop1
  assert_exit_code 2
  assert_output_contains "unknown option for apply: '--no-launch'"
  [ ! -e "$FAKE_HS_LOG/request.json" ]
}

@test "AT-05.3: a --map not of the form name=uuid, or given twice for one name, is refused before asking" {
  apply_machine ok "$FIXTURES/responses/observe.json"
  run_arngz apply --map left zeop1
  assert_exit_code 2
  assert_output_contains "it takes <name>=<uuid>"
  run_arngz apply --map left=A --map left=B zeop1
  assert_exit_code 2
  assert_output_contains "--map left is given twice"
  [ ! -e "$FAKE_HS_LOG/request.json" ]
}

@test "AT-05.6: --bind is refused as the unknown option it is, exit 2, and nothing is asked" {
  apply_machine ok "$FIXTURES/responses/observe.json"
  run_arngz apply --bind zeop1
  assert_exit_code 2
  assert_output_contains "unknown option for apply: '--bind'"
  [ ! -e "$FAKE_HS_LOG/request.json" ]
}

@test "AT-05.7: arngz <desk> is apply <desk>" {
  local response
  response="$(apply_response placed_results)"
  apply_machine scheduled "$response"
  run_arngz zeop1
  assert_success
  run yq -r '.verb + " " + .desk.desk' "$FAKE_HS_LOG/request.json"
  assert_output "apply zeop1"
}

@test "AT-05.7: a desk named like a verb can be neither saved nor applied" {
  local response
  response="$(engine_response discover discover_world "" "")"
  fake_hs ok "$response"
  catalogue
  minimal_desk diff
  run_arngz apply diff
  assert_exit_code 2
  assert_output_contains "desk 'diff'"
  run_arngz discover --save apply
  assert_exit_code 2
  assert_output_contains "desk 'apply'"
  [ ! -e "$CAT/apply.yaml" ]
}

# ============================================================================
# AT-06 -- doctor and init (AC-06.1, AC-06.2)
# ============================================================================

# A FIXTURE MACHINE, so no test reads or writes the real one. HOME, the
# catalogue and the hs prefix live under the test's temp dir, and stand-ins for
# every macOS tool doctor and init ask (fixtures/fake-macos: defaults, pgrep,
# osascript) come first on PATH, answering from files the test writes. The
# rest of PATH is the system dirs and links to yq and bash alone, so the real
# hs, which lives beside yq in a package manager's bin, can never answer. The
# settings start as hv's machine had them on 16 Oct 2026: separate spaces
# unset (macOS's default, on), auto-rearrange off, Stage Manager off.
# Hammerspoon is neither installed nor running until a test says so.
machine() {
  export HOME="$BATS_TEST_TMPDIR/home"
  export XDG_CONFIG_HOME="$HOME/.config"
  export XDG_STATE_HOME="$HOME/.local/state"
  export ARNGZ_HS_PREFIX="$BATS_TEST_TMPDIR/prefix"
  export TMPDIR="$BATS_TEST_TMPDIR/tmp"
  export FAKE_PREFS="$BATS_TEST_TMPDIR/prefs"
  export FAKE_APPS="$BATS_TEST_TMPDIR/apps"
  export FAKE_RUNNING=""
  export FAKE_HS_LOG="$BATS_TEST_TMPDIR/hslog"
  APP="$BATS_TEST_TMPDIR/Applications/Hammerspoon.app"
  STUBS="$BATS_TEST_TMPDIR/stubs"
  local tools="$BATS_TEST_TMPDIR/tools" tool
  mkdir -p "$HOME" "$TMPDIR" "$FAKE_APPS" "$FAKE_HS_LOG" "$ARNGZ_HS_PREFIX" "$STUBS" "$tools"
  cp "$FIXTURES"/fake-macos/* "$STUBS/"
  for tool in yq bash; do
    ln -s "$(command -v "$tool")" "$tools/$tool"
  done
  # The suite's platform (UTILZ_TEST_PLATFORM, at the top) first: the
  # machine is a Mac whatever the host, unless a test pins another after.
  export PATH="$UTILZ_TEST_PLATFORM_BIN:$STUBS:$ARNGZ_HS_PREFIX/bin:$tools:/usr/bin:/bin"
  pref com.apple.dock mru-spaces 0
  pref com.apple.WindowManager GloballyEnabled 0
}

# pref DOMAIN KEY VALUE: one preference, as defaults reads it.
pref() {
  mkdir -p "$FAKE_PREFS/$1"
  printf '%s\n' "$3" >"$FAKE_PREFS/$1/$2"
}

# unpref DOMAIN KEY: the preference unset.
unpref() {
  rm -f "$FAKE_PREFS/$1/$2"
}

# Hammerspoon installed: an app carrying the hs tool, which is the fake hs, and
# its man page, found by its bundle id.
hammerspoon_installed() {
  mkdir -p "$APP/Contents/Frameworks/hs" "$APP/Contents/Resources/man"
  cp "$FIXTURES/fake-hs" "$APP/Contents/Frameworks/hs/hs"
  echo "the hs man page" >"$APP/Contents/Resources/man/hs.man"
  printf '%s\n' "$APP" >"$FAKE_APPS/org.hammerspoon.Hammerspoon"
}

hammerspoon_running() {
  export FAKE_RUNNING="Hammerspoon"
}

# The hs tool on PATH: the fake hs, answering as MODE says, with RESPONSE.
hs_on_path() {
  export FAKE_HS_MODE="$1"
  export FAKE_HS_RESPONSE="${2:-$FIXTURES/responses/observe.json}"
  cp "$FIXTURES/fake-hs" "$STUBS/hs"
}

# Every file, link and dir under DIR, a file by its checksum and a link by its
# target, so two snapshots differ exactly when something under DIR changed.
snapshot() {
  local dir="$1" f
  if [[ ! -d "$dir" ]]; then
    printf '(no %s)\n' "$dir"
    return 0
  fi
  (cd "$dir" && find . | LC_ALL=C sort | while IFS= read -r f; do
    if [[ -L "$f" ]]; then
      printf '%s -> %s\n' "$f" "$(readlink "$f")"
    elif [[ -f "$f" ]]; then
      printf '%s %s\n' "$f" "$(cksum <"$f")"
    else
      printf '%s/\n' "$f"
    fi
  done)
}

# The fixture machine outside the catalogue: HOME less the catalogue and the
# config dir that holds it, and less the run log and the dirs that hold it,
# since every run that logs appends to it (ST589246c); the hs prefix; and the
# app. The log alone is left out: any other state init writes there, eg
# current or own-sizes, still shows. snapshot() prints a dir with a trailing
# slash and a file followed by a space and its checksum.
machine_snapshot() {
  snapshot "$HOME" |
    grep -Ev '^\./\.config/$|^\./\.config/arngz|^\./\.local/$|^\./\.local/state/$|^\./\.local/state/arngz/$|^\./\.local/state/arngz/arngz\.log '
  snapshot "$ARNGZ_HS_PREFIX"
  snapshot "$BATS_TEST_TMPDIR/Applications"
}

# The doctor line for WHAT says STATUS, and the rest of it matches PATTERN, an
# extended regex. Each line it finds is kept in DOCTOR_NAMED, for
# assert_doctor_rows_named.
doctor_says() {
  local status="$1" what="$2" pattern="$3" line
  line=$(printf '%s\n' "$output" | grep -E "^$status +$what +$pattern") || {
    echo "no line '$status $what $pattern' in:" >&2
    echo "$output" >&2
    return 1
  }
  DOCTOR_NAMED="${DOCTOR_NAMED:-}$line"$'\n'
}

# Doctor's precondition rows, as the run printed them: each line that opens
# with ok, FAIL or skip.
doctor_rows() {
  printf '%s\n' "$output" | grep -E '^(ok|FAIL|skip) ' || true
}

# Doctor printed no row this test has not named with doctor_says: a new
# precondition names itself here, as a missing one does in doctor_says.
assert_doctor_rows_named() {
  local unnamed
  unnamed=$(doctor_rows | grep -vxF -f <(printf '%s' "${DOCTOR_NAMED:-}") || true)
  [ -z "$unnamed" ] || fail "doctor printed rows this test does not name:
$unnamed"
}

# Doctor's summary line, its total read off the rows the run printed. With a
# count, the preconditions the test made fail; with none, all of them hold.
# Usage: assert_doctor_summary [FAILED]
assert_doctor_summary() {
  local rows
  rows=$(doctor_rows | grep -c . || true)
  [ "$rows" -gt 0 ] || fail "doctor printed no precondition row -- the reader is wrong, not doctor"
  if [ $# -eq 0 ]; then
    assert_output_contains "arngz doctor: all $rows preconditions hold"
  else
    assert_output_contains "arngz doctor: $1 of $rows preconditions do not hold"
  fi
}

# stub_failing TOOL PATTERN: on the fixture machine's PATH, TOOL fails, saying
# so, whenever its arguments match the glob PATTERN, and is the real TOOL
# otherwise. For a step that fails after every check before it has passed.
stub_failing() {
  local tool="$1" pattern="$2" real
  real="$(command -v "$tool")"
  cat >"$STUBS/$tool" <<EOF
#!/bin/bash
case "\$*" in
  $pattern) echo "$tool: failed on purpose (arngz.bats)" >&2; exit 1 ;;
esac
exec "$real" "\$@"
EOF
  chmod 755 "$STUBS/$tool"
}

# The path a doctor line names as kept, from the run's output.
kept_dir() {
  printf '%s\n' "$output" | sed -n 's/.*(its request and answer are kept at \([^)]*\)).*/\1/p'
}

# The line init appends, exactly.
IPC_LINE='require("hs.ipc") -- arngz (Utilz ST0026): IPC for the hs command-line tool'

@test "AT-06.1: doctor names all seven preconditions, each with its state, and exits 0 when every one holds" {
  machine
  hammerspoon_installed
  hammerspoon_running
  hs_on_path ok
  run_arngz doctor
  assert_success
  doctor_says ok Hammerspoon "running "
  assert_output_contains "running ($APP)"
  doctor_says ok "hs tool" ""
  assert_output_contains "$STUBS/hs"
  doctor_says ok IPC "Hammerspoon answered through "
  doctor_says ok Accessibility "granted to Hammerspoon$"
  doctor_says ok "separate spaces" "on \(unset: macOS's default\)$"
  doctor_says ok auto-rearrange "off$"
  doctor_says ok "Stage Manager" "off$"
  assert_doctor_rows_named
  assert_doctor_summary
}

@test "AT-06.1: doctor completes with no Hammerspoon at all, naming it as missing, and asks nothing" {
  machine
  local start=$SECONDS
  run_arngz doctor
  assert_exit_code 1
  doctor_says FAIL Hammerspoon "missing: not installed; fix: brew install --cask hammerspoon$"
  doctor_says FAIL "hs tool" "missing: not on PATH; fix: arngz init --yes links it under "
  doctor_says skip IPC "not checked: there is no hs tool to ask it with$"
  doctor_says skip Accessibility "not checked: only Hammerspoon can say"
  doctor_says ok "separate spaces" "on"
  doctor_says ok auto-rearrange "off$"
  doctor_says ok "Stage Manager" "off$"
  assert_doctor_summary 4
  [ $((SECONDS - start)) -lt 10 ]
}

@test "AT-06.1: Hammerspoon installed but not running is named with its fix, and hs is never asked" {
  machine
  hammerspoon_installed
  hs_on_path hang
  export ARNGZ_HS_TIMEOUT=30
  local start=$SECONDS
  run_arngz doctor
  assert_exit_code 1
  doctor_says FAIL Hammerspoon "installed at .*, not running; fix: open -b org.hammerspoon.Hammerspoon$"
  doctor_says ok "hs tool" ""
  doctor_says skip IPC "not checked: Hammerspoon is not running$"
  doctor_says skip Accessibility "not checked"
  [ ! -e "$FAKE_HS_LOG/argv" ]
  [ $((SECONDS - start)) -lt 10 ]
}

@test "AT-06.1: an IPC that does not answer is named with its fix, and Accessibility is not checked" {
  machine
  hammerspoon_installed
  hammerspoon_running
  hs_on_path exit-69
  run_arngz doctor
  assert_exit_code 1
  doctor_says FAIL IPC "hs could not reach Hammerspoon \(exit 69\)"
  assert_output_contains "fix: arngz init --yes makes Hammerspoon's config load hs.ipc"
  doctor_says skip Accessibility "not checked: only Hammerspoon can say, and Hammerspoon did not answer$"

  hs_on_path hang
  export ARNGZ_HS_TIMEOUT=1
  local start=$SECONDS
  run_arngz doctor
  assert_exit_code 1
  doctor_says FAIL IPC "hs did not answer within 1s"
  [ $((SECONDS - start)) -lt 10 ]
}

@test "AT-06.1: Accessibility not granted to Hammerspoon is named, with where to grant it" {
  machine
  hammerspoon_installed
  hammerspoon_running
  yq -o json '.world.accessibility = false' "$FIXTURES/responses/observe.json" >"$BATS_TEST_TMPDIR/denied.json"
  hs_on_path ok "$BATS_TEST_TMPDIR/denied.json"
  run_arngz doctor
  assert_exit_code 1
  doctor_says ok IPC "Hammerspoon answered"
  doctor_says FAIL Accessibility "not granted to Hammerspoon; fix: System Settings > Privacy & Security > Accessibility: turn on Hammerspoon$"
  assert_doctor_summary 1
}

@test "AT-06.1: doctor asks the engine to observe, with hs's stdin from /dev/null, and leaves no temp dir" {
  machine
  hammerspoon_installed
  hammerspoon_running
  hs_on_path ok
  echo "return os.exit()" >"$BATS_TEST_TMPDIR/stdin.txt"
  "$UTILZ_BIN_DIR/arngz" doctor <"$BATS_TEST_TMPDIR/stdin.txt" >/dev/null 2>&1
  run cat "$FAKE_HS_LOG/stdin"
  assert_output "devnull"
  run yq -r '.verb' "$FAKE_HS_LOG/request.json"
  assert_output "observe"
  # The request was made under TMPDIR, and TMPDIR is still there, so the empty
  # listing below is the request's dir removed, not a dir that never was.
  grep -qF "$TMPDIR/arngz." "$FAKE_HS_LOG/argv"
  [ -d "$TMPDIR" ]
  [ -z "$(ls -A "$TMPDIR")" ]
}

@test "AT-06.1: each setting that does not hold is named with its fix, and an unset one takes macOS's default" {
  machine
  hammerspoon_installed
  hammerspoon_running
  hs_on_path ok

  pref com.apple.spaces spans-displays 1
  run_arngz doctor
  assert_exit_code 1
  doctor_says FAIL "separate spaces" "off; fix: System Settings > Desktop & Dock > Mission Control: turn on Displays have separate Spaces"
  unpref com.apple.spaces spans-displays

  pref com.apple.dock mru-spaces 1
  run_arngz doctor
  assert_exit_code 1
  doctor_says FAIL auto-rearrange "on; fix: System Settings > Desktop & Dock > Mission Control: turn off Automatically rearrange Spaces"

  unpref com.apple.dock mru-spaces
  run_arngz doctor
  assert_exit_code 1
  doctor_says FAIL auto-rearrange "on \(unset: macOS's default\); fix: "
  pref com.apple.dock mru-spaces 0

  pref com.apple.WindowManager GloballyEnabled 1
  run_arngz doctor
  assert_exit_code 1
  doctor_says FAIL "Stage Manager" "on; fix: System Settings > Desktop & Dock: turn off Stage Manager$"
  assert_doctor_summary 1

  # A domain with no preferences at all is unset too ("Domain ... not found").
  rm -rf "$FAKE_PREFS/com.apple.WindowManager"
  run_arngz doctor
  assert_success
  doctor_says ok "Stage Manager" "off \(unset: macOS's default\)$"
}

@test "AT-06.1: a preference defaults cannot read is unknown, never unset, and the wording before macOS 27 reads as unset" {
  machine
  hammerspoon_installed
  hammerspoon_running
  hs_on_path ok
  echo "defaults[4242] Could not connect to cfprefsd" >"$FAKE_PREFS/com.apple.dock/mru-spaces.error"
  run_arngz doctor
  assert_exit_code 1
  doctor_says FAIL auto-rearrange "unknown: defaults read com.apple.dock mru-spaces failed \(exit 1\): defaults\[4242\] Could not connect to cfprefsd"
  rm "$FAKE_PREFS/com.apple.dock/mru-spaces.error"

  export FAKE_PREFS_WORDING=old
  run_arngz doctor
  assert_success
  doctor_says ok "separate spaces" "on \(unset: macOS's default\)$"
}

@test "AT-06.1: doctor takes no arguments" {
  machine
  run_arngz doctor --verbose
  assert_exit_code 2
  assert_output_contains "doctor takes no arguments: '--verbose'"
}

@test "AT-06.1: a Lua error in the engine is an IPC that answered, and the error is named, not sent to init" {
  machine
  hammerspoon_installed
  hammerspoon_running
  hs_on_path lua-error
  run_arngz doctor
  assert_exit_code 1
  doctor_says ok IPC "Hammerspoon answered"
  doctor_says FAIL Accessibility "unknown: the engine could not say: the engine raised a Lua error \(hs exit 65\): attempt to index a nil value"
  assert_output_contains "that is arngz's engine failing"
  refute_output_contains "init --yes"
}

@test "AT-06.1: pgrep failing is said, never read as not running, and Hammerspoon is still asked" {
  machine
  hammerspoon_installed
  hs_on_path ok
  export FAKE_PGREP_EXIT=3
  run_arngz doctor
  assert_exit_code 1
  doctor_says FAIL Hammerspoon "unknown: pgrep exited 3: pgrep: cannot read the process table"
  doctor_says ok IPC "Hammerspoon answered"
  doctor_says ok Accessibility "granted to Hammerspoon$"
}

@test "AT-06.1: a LaunchServices lookup that fails is said, never taken for no Hammerspoon" {
  machine
  hs_on_path ok
  echo "execution error: Error: Not authorized to send Apple events (-1743)" >"$FAKE_APPS/org.hammerspoon.Hammerspoon.error"
  run_arngz doctor
  assert_exit_code 1
  doctor_says FAIL Hammerspoon "not running, and where it is installed is unknown: looking org.hammerspoon.Hammerspoon up through LaunchServices failed \(osascript exited 1\): execution error: Error: Not authorized"
  refute_output_contains "missing: not installed"
}

@test "AT-06.1: an engine that ran and wrote no response is an IPC that answered, and the engine is named, not init" {
  machine
  hammerspoon_installed
  hammerspoon_running
  hs_on_path none
  run_arngz doctor
  assert_exit_code 1
  doctor_says ok IPC "Hammerspoon answered"
  doctor_says FAIL Accessibility "unknown: the engine could not say: hs exited 0 and wrote no response, so the engine ran and could not write its answer"
  assert_output_contains "that is arngz's engine failing"
  refute_output_contains "init --yes"
}

@test "AT-06.1: an engine error keeps its request and answer, at the path its line names" {
  machine
  hammerspoon_installed
  hammerspoon_running
  printf 'this is not json\n' >"$BATS_TEST_TMPDIR/notjson.json"
  hs_on_path ok "$BATS_TEST_TMPDIR/notjson.json"
  run_arngz doctor
  assert_exit_code 1
  doctor_says ok IPC "Hammerspoon answered"
  doctor_says FAIL Accessibility "unknown: the engine could not say: the engine's response is not JSON: "
  [[ "$(kept_dir)" == "$TMPDIR"/arngz.* ]]
  [ -f "$(kept_dir)/request.json" ]
  [ -f "$(kept_dir)/response.json" ]

  hs_on_path lua-error
  run_arngz doctor
  [[ "$(kept_dir)" == "$TMPDIR"/arngz.* ]]
  [ -f "$(kept_dir)/request.json" ]
}

@test "AT-06.1: a request that could not be made is IPC not asked, with what fixes it, and doctor finishes" {
  machine
  hammerspoon_installed
  hammerspoon_running
  hs_on_path ok
  # TMPDIR a plain file: no temp dir, so no request, and nothing to remove.
  export TMPDIR="$BATS_TEST_TMPDIR/tmp-is-a-file"
  echo "not a directory" >"$TMPDIR"
  mkdir -p "$BATS_TEST_TMPDIR/cwd"
  : >"$BATS_TEST_TMPDIR/cwd/sentinel"
  cd "$BATS_TEST_TMPDIR/cwd"
  run_arngz doctor
  assert_exit_code 1
  doctor_says FAIL IPC "not asked: could not make a temp dir under $TMPDIR for the request: .*; fix: make $TMPDIR a writable directory, or set TMPDIR to one$"
  doctor_says skip Accessibility "not checked: only Hammerspoon can say, and Hammerspoon was not asked$"
  # Every preference read needs a temp file too, so each says it could not.
  doctor_says FAIL auto-rearrange "unknown: could not make a temp file under $TMPDIR to read com.apple.dock mru-spaces with: "
  assert_doctor_summary 5
  [ -f "$BATS_TEST_TMPDIR/cwd/sentinel" ]
}

@test "AT-06.1: a request whose options could not be written is IPC not asked, and its temp dir is removed" {
  machine
  hammerspoon_installed
  hammerspoon_running
  hs_on_path ok
  # mktemp makes the request's dir read-only, as a full disk would leave the
  # write: every check before it has passed.
  local real
  real="$(command -v mktemp)"
  cat >"$STUBS/mktemp" <<EOF
#!/bin/bash
if [[ "\$1" == -d && "\$2" == */arngz.XXXXXX ]]; then
  dir="\$("$real" -d "\$2")" || exit 1
  chmod 500 "\$dir"
  printf '%s\n' "\$dir"
  exit 0
fi
exec "$real" "\$@"
EOF
  chmod 755 "$STUBS/mktemp"
  run_arngz doctor
  assert_exit_code 1
  doctor_says FAIL IPC "not asked: could not write the request's options to $TMPDIR/arngz\.[^/]+/options\.json: .*; fix: make $TMPDIR a writable directory"
  doctor_says skip Accessibility "not checked: only Hammerspoon can say, and Hammerspoon was not asked$"
  [ ! -e "$FAKE_HS_LOG/argv" ]
  [ -z "$(ls -A "$TMPDIR")" ]
}

@test "AT-06.1: an hs on PATH that cannot run is said, never called ok, and nothing is asked through it" {
  machine
  hammerspoon_installed
  hammerspoon_running
  hs_on_path ok
  chmod 644 "$STUBS/hs"
  run_arngz doctor
  assert_exit_code 1
  doctor_says FAIL "hs tool" "missing: $STUBS/hs is on PATH and is not executable; fix: remove it, or make it executable$"
  doctor_says skip IPC "not checked: there is no hs tool to ask it with$"
  [ ! -e "$FAKE_HS_LOG/argv" ]

  # Executable, and still it will not run: its interpreter is gone. bash says
  # so as exit 126 on macOS and 127 on Linux ("required file not found").
  printf '#!%s/no-such-interpreter\n' "$BATS_TEST_TMPDIR" >"$STUBS/hs"
  chmod 755 "$STUBS/hs"
  run_arngz doctor
  assert_exit_code 1
  doctor_says ok "hs tool" ""
  doctor_says FAIL IPC "not asked: the hs tool at $STUBS/hs could not be run \(exit 12[67]\): "
  doctor_says skip Accessibility "not checked: only Hammerspoon can say, and Hammerspoon was not asked$"
  refute_output_contains "init --yes makes"
}

@test "AT-06.1: another user's Hammerspoon is not this user's: not running, and never asked" {
  machine
  hammerspoon_installed
  hs_on_path ok
  export FAKE_RUNNING="Hammerspoon@other"
  run_arngz doctor
  assert_exit_code 1
  doctor_says FAIL Hammerspoon "installed at .*, not running; fix: open -b org.hammerspoon.Hammerspoon$"
  doctor_says skip IPC "not checked: Hammerspoon is not running$"
  [ ! -e "$FAKE_HS_LOG/argv" ]
}

@test "AT-06.1: an observe whose answer cannot be read is said, and doctor still finishes its report" {
  machine
  hammerspoon_installed
  hammerspoon_running
  yq -o json '.world = [1, 2]' "$FIXTURES/responses/observe.json" >"$BATS_TEST_TMPDIR/array.json"
  hs_on_path ok "$BATS_TEST_TMPDIR/array.json"
  run_arngz doctor
  assert_exit_code 1
  doctor_says ok IPC "Hammerspoon answered"
  doctor_says FAIL Accessibility "unknown: the engine's observe gave accessibility = '\(unreadable: .*cannot index array"
  assert_doctor_summary 1
  [ -z "$(ls -A "$TMPDIR")" ]
}

@test "AT-06.1: each way IPC fails gets its own fix, and init only when the config is what is missing" {
  machine
  hammerspoon_installed
  hammerspoon_running
  hs_on_path exit-75
  run_arngz doctor
  assert_exit_code 1
  doctor_says FAIL IPC "Hammerspoon is not running \(hs exit 75\); fix: open -b org.hammerspoon.Hammerspoon$"
  refute_output_contains "init --yes"

  hs_on_path receive-timeout
  run_arngz doctor
  assert_exit_code 1
  doctor_says FAIL IPC "hs gave up on observe after 60s with receive timeout: the request reached Hammerspoon, which is running, and no answer came in time; fix: Hammerspoon is busy or hung"
  refute_output_contains "could not reach Hammerspoon"
  refute_output_contains "init --yes"

  hs_on_path hang
  export ARNGZ_HS_TIMEOUT=1
  run_arngz doctor
  assert_exit_code 1
  doctor_says FAIL IPC "hs did not answer within 1s and wrote no response; fix: Hammerspoon is busy or hung"
  refute_output_contains "init --yes"
}

@test "AT-06.1: only an unset wording that names this key and this domain is unset; any other is unknown" {
  machine
  hammerspoon_installed
  hammerspoon_running
  hs_on_path ok
  local wording
  for wording in "Error: Domain 'com.apple.other' not found." \
    "Error: Could not find key 'other-key' in domain 'com.apple.dock'." \
    "The domain/default pair of (com.apple.other, mru-spaces) does not exist"; do
    printf '%s\n' "$wording" >"$FAKE_PREFS/com.apple.dock/mru-spaces.error"
    run_arngz doctor
    assert_exit_code 1
    doctor_says FAIL auto-rearrange "unknown: defaults read com.apple.dock mru-spaces failed \(exit 1\): "
  done
}

@test "AT-06.1: the engine call tells the hs tool as doctor does, with the same fix" {
  machine
  hammerspoon_installed
  run_arngz init --yes
  assert_success
  # Linked under the prefix, which is then taken off PATH.
  export PATH="${PATH/$ARNGZ_HS_PREFIX\/bin:/}"
  run_arngz discover
  assert_exit_code 2
  assert_output_contains "the hs tool, which arngz reaches Hammerspoon through, is missing: $ARNGZ_HS_PREFIX/bin/hs is there, but $ARNGZ_HS_PREFIX/bin is not on PATH, where arngz looks for it; fix: add $ARNGZ_HS_PREFIX/bin to PATH"
  refute_output_contains "installs it"
}

@test "AT-06.1 and AT-06.2: an hs left under the prefix that does not run is one state, told the same by doctor and init" {
  machine
  hammerspoon_installed
  mkdir -p "$ARNGZ_HS_PREFIX/bin"
  ln -s "$BATS_TEST_TMPDIR/Applications/Moved.app/Contents/Frameworks/hs/hs" "$ARNGZ_HS_PREFIX/bin/hs"
  run_arngz doctor
  assert_exit_code 1
  doctor_says FAIL "hs tool" "missing: .*/bin/hs is there and does not run \(a link to a Hammerspoon that moved\?\); fix: remove it, and arngz init --yes links it again$"
  run_arngz init --yes
  assert_exit_code 2
  assert_output_contains "init --yes changed nothing"
  assert_output_contains "bin/hs is there and does not run (a link to a Hammerspoon that moved?): remove it, and arngz init --yes links it again"
}

@test "AT-06.2: init without --yes says what it would do and changes nothing outside the catalogue" {
  machine
  hammerspoon_installed
  mkdir -p "$HOME/.hammerspoon"
  printf 'hs.grid.setGrid("8x4")\n' >"$HOME/.hammerspoon/init.lua"
  local before
  before="$(machine_snapshot)"
  run_arngz init
  assert_success
  assert_output_contains "catalogue: $XDG_CONFIG_HOME/arngz/desks (created)"
  assert_output_contains "Hammerspoon: installed at $APP"
  assert_output_contains "hs tool: would link $ARNGZ_HS_PREFIX/bin/hs to $APP/Contents/Frameworks/hs/hs, and its man page"
  assert_output_contains "init.lua: would append to $HOME/.hammerspoon/init.lua: $IPC_LINE"
  assert_output_contains "nothing else changed: arngz init --yes does what is marked would"
  [ "$before" = "$(machine_snapshot)" ]
  [ -d "$XDG_CONFIG_HOME/arngz/desks" ]
}

@test "AT-06.2: init --yes links the hs tool as hs.ipc.cliInstall does, and appends exactly one marked line" {
  machine
  hammerspoon_installed
  mkdir -p "$HOME/.hammerspoon"
  printf 'hs.grid.setGrid("8x4")\n' >"$HOME/.hammerspoon/init.lua"
  cp "$HOME/.hammerspoon/init.lua" "$BATS_TEST_TMPDIR/init.before"
  local before
  before="$(machine_snapshot)"
  run_arngz init --yes
  assert_success
  # The snapshot the "changes nothing" tests trust does see a change.
  [ "$before" != "$(machine_snapshot)" ]
  assert_output_contains "hs tool: linked $ARNGZ_HS_PREFIX/bin/hs to $APP/Contents/Frameworks/hs/hs, and its man page"
  assert_output_contains "init.lua: appended to $HOME/.hammerspoon/init.lua: $IPC_LINE"
  assert_output_contains "reload Hammerspoon's config"
  [ -L "$ARNGZ_HS_PREFIX/bin/hs" ]
  [ "$ARNGZ_HS_PREFIX/bin/hs" -ef "$APP/Contents/Frameworks/hs/hs" ]
  [ -L "$ARNGZ_HS_PREFIX/share/man/man1/hs.1" ]
  [ "$ARNGZ_HS_PREFIX/share/man/man1/hs.1" -ef "$APP/Contents/Resources/man/hs.man" ]
  # The config is what it was, and then the one marked line.
  {
    cat "$BATS_TEST_TMPDIR/init.before"
    printf '%s\n' "$IPC_LINE"
  } >"$BATS_TEST_TMPDIR/init.expected"
  cmp "$BATS_TEST_TMPDIR/init.expected" "$HOME/.hammerspoon/init.lua"
}

@test "AT-06.2: a second init --yes changes nothing, and says there is nothing to do" {
  machine
  hammerspoon_installed
  run_arngz init --yes
  assert_success
  # With no config at all, the first run made one holding the one line.
  printf '%s\n' "$IPC_LINE" >"$BATS_TEST_TMPDIR/init.expected"
  cmp "$BATS_TEST_TMPDIR/init.expected" "$HOME/.hammerspoon/init.lua"
  local before
  before="$(machine_snapshot)"
  run_arngz init --yes
  assert_success
  assert_output_contains "catalogue: $XDG_CONFIG_HOME/arngz/desks (exists)"
  assert_output_contains "hs tool: $ARNGZ_HS_PREFIX/bin/hs"
  assert_output_contains "init.lua: $HOME/.hammerspoon/init.lua loads hs.ipc (line 1)"
  assert_output_contains "Hammerspoon setup: nothing to do"
  [ "$before" = "$(machine_snapshot)" ]
}

@test "AT-06.2: init --yes adds nothing to a config that loads hs.ipc already, marked or not, as hv's does" {
  machine
  hammerspoon_installed
  hs_on_path ok
  mkdir -p "$HOME/.hammerspoon"
  local config="$HOME/.hammerspoon/init.lua" form
  # The three lines vc appended to hv's own config on 16 Oct 2026, verbatim.
  cat >"$config" <<'EOF'
hs.grid.setGrid("8x4")
-- arngz (Utilz ST0026): IPC for the `hs` command-line tool. Appended by vc on hv's word, 16 Oct 2026.
require("hs.ipc")
if not hs.ipc.cliStatus("/opt/homebrew", true) then hs.ipc.cliInstall("/opt/homebrew", true) end
EOF
  cp "$config" "$BATS_TEST_TMPDIR/init.before"
  run_arngz init --yes
  assert_success
  assert_output_contains "hs tool: $STUBS/hs"
  assert_output_contains "init.lua: $config loads hs.ipc (line 3)"
  assert_output_contains "Hammerspoon setup: nothing to do"
  cmp "$BATS_TEST_TMPDIR/init.before" "$config"
  [ ! -e "$ARNGZ_HS_PREFIX/bin/hs" ]

  for form in 'require "hs.ipc"' "require('hs.ipc')" 'local ipc = require ( "hs.ipc" )'; do
    printf '%s\n' "$form" >"$config"
    run_arngz init --yes
    assert_success
    assert_output_contains "loads hs.ipc (line 1)"
    [ "$(cat "$config")" = "$form" ]
  done
}

@test "AT-06.2: a require behind a -- comment does not count, so the line is appended" {
  machine
  hammerspoon_installed
  hs_on_path ok
  mkdir -p "$HOME/.hammerspoon"
  printf -- '-- require("hs.ipc")\n' >"$HOME/.hammerspoon/init.lua"
  run_arngz init --yes
  assert_success
  [ "$(grep -cxF "$IPC_LINE" "$HOME/.hammerspoon/init.lua")" -eq 1 ]
}

@test "AT-06.2: init --yes ends a last line that has no newline before it appends" {
  machine
  hammerspoon_installed
  hs_on_path ok
  mkdir -p "$HOME/.hammerspoon"
  printf 'hs.grid.setGrid("8x4")' >"$HOME/.hammerspoon/init.lua"
  run_arngz init --yes
  assert_success
  printf 'hs.grid.setGrid("8x4")\n%s\n' "$IPC_LINE" >"$BATS_TEST_TMPDIR/init.expected"
  cmp "$BATS_TEST_TMPDIR/init.expected" "$HOME/.hammerspoon/init.lua"
}

@test "AT-06.2: init --yes refuses, changing nothing, when the hs tool needs Hammerspoon and it is not installed" {
  machine
  local before
  before="$(machine_snapshot)"
  run_arngz init --yes
  assert_exit_code 2
  assert_output_contains "init --yes changed nothing"
  assert_output_contains "brew install --cask hammerspoon"
  [ ! -e "$XDG_CONFIG_HOME/arngz/desks" ]
  [ "$before" = "$(machine_snapshot)" ]

  # Without --yes it says the same, and still makes the catalogue, its own job.
  run_arngz init
  assert_success
  assert_output_contains "hs tool: cannot be linked: the hs tool comes with Hammerspoon, which is not installed"
  assert_output_contains "init --yes cannot finish until this is fixed"
  [ -d "$XDG_CONFIG_HOME/arngz/desks" ]
}

@test "AT-06.2: init follows Hammerspoon's MJConfigFile preference to the config it really reads" {
  machine
  hammerspoon_installed
  hs_on_path ok
  pref org.hammerspoon.Hammerspoon MJConfigFile '~/.config/hammerspoon/init.lua'
  run_arngz init --yes
  assert_success
  assert_output_contains "appended to $HOME/.config/hammerspoon/init.lua"
  grep -qxF "$IPC_LINE" "$HOME/.config/hammerspoon/init.lua"
  [ ! -e "$HOME/.hammerspoon/init.lua" ]
}

@test "AT-06.2: init refuses an option it does not take" {
  machine
  run_arngz init --force
  assert_exit_code 2
  assert_output_contains "unknown option for init: '--force'"
}

@test "AT-06.2: an hs under the prefix but not on PATH is said as still to do, never as nothing to do" {
  machine
  hammerspoon_installed
  run_arngz init --yes
  assert_success
  export PATH="${PATH/$ARNGZ_HS_PREFIX\/bin:/}"
  run_arngz init --yes
  assert_success
  assert_output_contains "still for you to do: add $ARNGZ_HS_PREFIX/bin to PATH"
  refute_output_contains "nothing to do"
  run_arngz doctor
  doctor_says FAIL "hs tool" "missing: .*/bin/hs is there, but .*/bin is not on PATH, where arngz looks for it; fix: add .*/bin to PATH$"
}

@test "AT-06.2: init --yes refuses before changing anything when the config cannot be made, so no link is left behind" {
  machine
  hammerspoon_installed
  # A dotfiles link whose repository moved.
  ln -s "$BATS_TEST_TMPDIR/dotfiles-that-moved/hammerspoon" "$HOME/.hammerspoon"
  local before
  before="$(machine_snapshot)"
  run_arngz init --yes
  assert_exit_code 2
  assert_output_contains "init --yes changed nothing"
  assert_output_contains "$HOME/.hammerspoon is a link that leads nowhere"
  [ ! -e "$ARNGZ_HS_PREFIX/bin/hs" ]
  [ "$before" = "$(machine_snapshot)" ]
}

@test "AT-06.2: an MJConfigFile preference that cannot be read is said and refused, never guessed to be unset" {
  machine
  hammerspoon_installed
  mkdir -p "$FAKE_PREFS/org.hammerspoon.Hammerspoon"
  echo "defaults[4242] Could not connect to cfprefsd" >"$FAKE_PREFS/org.hammerspoon.Hammerspoon/MJConfigFile.error"
  run_arngz init --yes
  assert_exit_code 2
  assert_output_contains "MJConfigFile preference, which says where its config is, could not be read"
  [ ! -e "$HOME/.hammerspoon/init.lua" ]
  [ ! -e "$ARNGZ_HS_PREFIX/bin/hs" ]
}

@test "AT-06.2: a warning defaults prints beside MJConfigFile's value is not taken for part of the path" {
  machine
  hammerspoon_installed
  hs_on_path ok
  pref org.hammerspoon.Hammerspoon MJConfigFile '~/.config/hammerspoon/init.lua'
  echo "2026-10-16 defaults[4242:1] a warning, not the value" >"$FAKE_PREFS/org.hammerspoon.Hammerspoon/MJConfigFile.warning"
  mkdir -p "$BATS_TEST_TMPDIR/cwd"
  cd "$BATS_TEST_TMPDIR/cwd"
  run_arngz init --yes
  assert_success
  assert_output_contains "appended to $HOME/.config/hammerspoon/init.lua"
  grep -qxF "$IPC_LINE" "$HOME/.config/hammerspoon/init.lua"
  [ -z "$(ls -A "$BATS_TEST_TMPDIR/cwd")" ]
}

@test "AT-06.2: an MJConfigFile that is not a full path or one under ~/ is refused, never guessed at" {
  machine
  hammerspoon_installed
  hs_on_path ok
  pref org.hammerspoon.Hammerspoon MJConfigFile 'hammerspoon/init.lua'
  run_arngz init --yes
  assert_exit_code 2
  assert_output_contains "Hammerspoon's MJConfigFile preference is 'hammerspoon/init.lua', not a full path or one under ~/"
}

@test "AT-06.2: an MJConfigFile that is set and empty is refused by name, because Hammerspoon then loads no config" {
  machine
  hammerspoon_installed
  hs_on_path ok
  pref org.hammerspoon.Hammerspoon MJConfigFile ''
  local before
  before="$(machine_snapshot)"
  run_arngz init --yes
  assert_exit_code 2
  assert_output_contains "init --yes changed nothing: Hammerspoon's MJConfigFile preference is set and empty, which Hammerspoon 1.1.1 takes as its config path rather than falling back to ~/.hammerspoon/init.lua, so it loads no config"
  assert_output_contains "; set it to a full path, or remove it: defaults delete org.hammerspoon.Hammerspoon MJConfigFile"
  [ "$before" = "$(machine_snapshot)" ]

  run_arngz init
  assert_success
  assert_output_contains "init.lua: cannot be changed: Hammerspoon's MJConfigFile preference is set and empty"
}

@test "AT-06.2: a LaunchServices lookup that fails is said by init, which links nothing on a guess" {
  machine
  echo "execution error: Error: Not authorized to send Apple events (-1743)" >"$FAKE_APPS/org.hammerspoon.Hammerspoon.error"
  run_arngz init
  assert_success
  assert_output_contains "Hammerspoon: unknown: looking org.hammerspoon.Hammerspoon up through LaunchServices failed (osascript exited 1): execution error: Error: Not authorized"
  assert_output_contains "hs tool: cannot be linked: the hs tool comes with Hammerspoon, and where it is installed is unknown: looking org.hammerspoon.Hammerspoon up"
  refute_output_contains "not installed"
  local before
  before="$(machine_snapshot)"
  run_arngz init --yes
  assert_exit_code 2
  assert_output_contains "init --yes changed nothing: the hs tool comes with Hammerspoon, and where it is installed is unknown"
  [ "$before" = "$(machine_snapshot)" ]
}

@test "AT-06.2: a config that cannot be searched for its require is refused, never given a second one" {
  machine
  hammerspoon_installed
  hs_on_path ok
  mkdir -p "$HOME/.hammerspoon"
  printf 'require("hs.ipc")\n' >"$HOME/.hammerspoon/init.lua"
  cp "$HOME/.hammerspoon/init.lua" "$BATS_TEST_TMPDIR/init.before"
  stub_failing awk '*re=require*'
  run_arngz init --yes
  assert_exit_code 2
  assert_output_contains "init --yes changed nothing: $HOME/.hammerspoon/init.lua could not be searched for a require of hs.ipc: awk: failed on purpose"
  cmp "$BATS_TEST_TMPDIR/init.before" "$HOME/.hammerspoon/init.lua"
}

@test "AT-06.2: a step that fails after init --yes changed something stops it, exit 1, naming what it made" {
  machine
  hammerspoon_installed
  stub_failing ln '*hs.1*'
  run_arngz init --yes
  assert_exit_code 1
  assert_output_contains "init --yes stopped at 'link $ARNGZ_HS_PREFIX/share/man/man1/hs.1 to $APP/Contents/Resources/man/hs.man': ln: failed on purpose (arngz.bats). Made before it: make the catalogue $XDG_CONFIG_HOME/arngz/desks; make $ARNGZ_HS_PREFIX/bin; link $ARNGZ_HS_PREFIX/bin/hs to $APP/Contents/Frameworks/hs/hs; make $ARNGZ_HS_PREFIX/share/man/man1"
  refute_output_contains "changed nothing"
  [ -L "$ARNGZ_HS_PREFIX/bin/hs" ]
}

@test "AT-06.2: a catalogue that cannot be made is refused, exit 2, because nothing has changed" {
  machine
  mkdir -p "$BATS_TEST_TMPDIR/locked"
  chmod 555 "$BATS_TEST_TMPDIR/locked"
  export XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/locked/config"
  run_arngz init
  chmod 755 "$BATS_TEST_TMPDIR/locked"
  assert_exit_code 2
  assert_output_contains "init changed nothing: could not make the catalogue $XDG_CONFIG_HOME/arngz/desks: "
}

# ============================================================================
# Issue 0070 -- the current desk: recorded by an apply that ran and by a
# discover --save, cleared by a delete of it, printed by current
# ============================================================================

# Where the record is, under this test's own XDG_STATE_HOME.
current_record() {
  printf '%s/arngz/current\n' "$XDG_STATE_HOME"
}

@test "0070: with nothing recorded, current prints nothing and exits 1, saying why on stderr" {
  catalogue
  run --separate-stderr "$UTILZ_BIN_DIR/arngz" current
  assert_exit_code 1
  [ -z "$output" ]
  [[ "$stderr" == *"no current desk: no apply or discover --save has recorded one in $(current_record)"* ]]
}

@test "0070: an apply that placed every entry records its desk, and current prints it" {
  local response
  response="$(apply_response placed_results)"
  apply_machine scheduled "$response"
  run_arngz apply zeop1
  assert_success
  # The record is written beside itself and moved over, leaving nothing else
  # but the run log, which the apply also wrote (ST589246c).
  [ "$(ls -A "$XDG_STATE_HOME/arngz")" = "$(printf 'arngz.log\ncurrent')" ]
  run --separate-stderr "$UTILZ_BIN_DIR/arngz" current
  assert_success
  assert_output "zeop1"
}

@test "0070: an apply the engine took and never answered, exit 1, records its desk" {
  local response
  response="$(apply_response placed_results)"
  apply_machine scheduled-never "$response"
  export ARNGZ_APPLY_TIMEOUT=1
  run_arngz apply zeop1
  assert_exit_code 1
  [ "$(cat "$(current_record)")" = "zeop1" ]
}

@test "0070: an apply that ran with an entry not placed, exit 1, records its desk all the same" {
  local response
  response="$(apply_response gone_results)"
  apply_machine scheduled "$response"
  run_arngz apply zeop1
  assert_exit_code 1
  [ "$(cat "$(current_record)")" = "zeop1" ]
}

@test "0070: an apply whose engine failed after taking it, exit 1, records its desk too" {
  local response="$BATS_TEST_TMPDIR/failed.json"
  printf '%s\n' '{"status":"error","kind":"lua_error","verb":"apply","error":"FIXTURE attempt to index a nil value"}' >"$response"
  apply_machine scheduled "$response"
  run_arngz apply zeop1
  assert_exit_code 1
  [ "$(cat "$(current_record)")" = "zeop1" ]
}

@test "0070: a dry run, and an apply refused before anything changed, leave the record as it was" {
  local response
  response="$(engine_response plan off_cell_world base_desk)"
  apply_machine ok "$response"
  run_arngz apply --dry-run zeop1
  assert_success
  [ ! -e "$(current_record)" ]
  mkdir -p "$XDG_STATE_HOME/arngz"
  printf 'earlier\n' >"$(current_record)"
  hs_on_path exit-69 "$FIXTURES/responses/observe.json"
  run_arngz apply zeop1
  assert_exit_code 2
  run_arngz apply nosuchdesk
  assert_exit_code 2
  # The engine's own refusal comes with a response, and still records nothing.
  local refused="$BATS_TEST_TMPDIR/running.json"
  printf '%s\n' '{"status":"error","kind":"refused","verb":"apply","error":"an apply is already running (asked for at 2026-10-16T13:00:00Z)","fix":"wait for it to finish"}' >"$refused"
  hs_on_path scheduled "$refused"
  run_arngz apply zeop1
  assert_exit_code 2
  assert_output_contains "the engine refused apply"
  [ "$(cat "$(current_record)")" = "earlier" ]
}

@test "0070: discover --save records the desk it saved; a discover that only prints records nothing" {
  local response
  response="$(engine_response discover discover_world "" "zeop2")"
  fake_hs ok "$response"
  run_arngz discover
  assert_success
  [ ! -e "$(current_record)" ]
  run_arngz discover --save zeop2
  assert_success
  run --separate-stderr "$UTILZ_BIN_DIR/arngz" current
  assert_success
  assert_output "zeop2"
}

@test "0070: a delete of the current desk clears the record, and a delete of another desk keeps it" {
  catalogue
  minimal_desk other
  mkdir -p "$XDG_STATE_HOME/arngz"
  printf 'zeop1\n' >"$(current_record)"
  run_arngz delete other
  assert_success
  [ "$(cat "$(current_record)")" = "zeop1" ]
  run_arngz delete zeop1
  assert_success
  [ ! -e "$(current_record)" ]
}

@test "0070: a recorded desk that has left the catalogue is no current desk, exit 1, and current says so" {
  catalogue
  mkdir -p "$XDG_STATE_HOME/arngz"
  printf 'gone\n' >"$(current_record)"
  run --separate-stderr "$UTILZ_BIN_DIR/arngz" current
  assert_exit_code 1
  [ -z "$output" ]
  [[ "$stderr" == *"names 'gone', which is not in the catalogue"* ]]
}

@test "0070: current takes no arguments, and asks Hammerspoon nothing" {
  fake_hs ok
  catalogue
  mkdir -p "$XDG_STATE_HOME/arngz"
  printf 'zeop1\n' >"$(current_record)"
  run_arngz current zeop1
  assert_exit_code 2
  assert_output_contains "current takes no arguments: 'zeop1'"
  run_arngz current
  assert_success
  assert_output "zeop1"
  [ ! -e "$FAKE_HS_LOG/request.json" ]
}

@test "0070: a record that cannot be written is said, with why, and the apply keeps its own exit" {
  local response
  response="$(apply_response placed_results)"
  apply_machine scheduled "$response"
  export XDG_STATE_HOME="$BATS_TEST_TMPDIR/state-is-a-file"
  : >"$XDG_STATE_HOME"
  run_arngz apply zeop1
  assert_success
  assert_output_contains "could not record 'zeop1' as the current desk in $XDG_STATE_HOME/arngz/current: "
  refute_output_contains "no reason given"
}

@test "0070: a directory where the record goes is said, and nothing is left inside it" {
  local response
  response="$(apply_response placed_results)"
  apply_machine scheduled "$response"
  mkdir -p "$(current_record)"
  run_arngz apply zeop1
  assert_success
  assert_output_contains "could not record 'zeop1' as the current desk: $(current_record) is a directory"
  [ -z "$(ls -A "$(current_record)")" ]
}

@test "0070: a record that cannot be read is said by name, never taken for no record at all" {
  catalogue
  mkdir -p "$XDG_STATE_HOME/arngz"
  printf 'zeop1\n' >"$(current_record)"
  chmod 000 "$(current_record)"
  run --separate-stderr "$UTILZ_BIN_DIR/arngz" current
  chmod 644 "$(current_record)"
  assert_exit_code 1
  [ -z "$output" ]
  [[ "$stderr" == *"the current desk's record $(current_record) cannot be read"* ]]
}

@test "0070: a record that is not a desk name is no current desk, though its path reaches a desk's file" {
  catalogue
  mkdir -p "$XDG_STATE_HOME/arngz"
  printf '../desks/zeop1\n' >"$(current_record)"
  run --separate-stderr "$UTILZ_BIN_DIR/arngz" current
  assert_exit_code 1
  [ -z "$output" ]
}

@test "0070: current reads no Hammerspoon entry, so a broken one does not stop it" {
  machine
  catalogue
  stub_failing yq '*Hammerspoon*'
  mkdir -p "$XDG_STATE_HOME/arngz"
  printf 'zeop1\n' >"$(current_record)"
  run_arngz current
  assert_success
  assert_output "zeop1"
}

# ============================================================================
# THE PLATFORM (issue 0083)
# ============================================================================
#
# Every other test here runs as macOS (UTILZ_TEST_PLATFORM, at the top). These
# pin Linux: the engine verbs refuse by name before they read or ask anything,
# init makes the catalogue alone, doctor checks the catalogue alone, and the
# catalogue verbs work as they do anywhere.

ENGINE_OFF_LINUX="arngz's engine (apply, diff, discover, which, auto and init --yes) needs macOS and Hammerspoon, so it is not available on Linux; arngz list, show, delete, current and log work here"

# Recorders for every tool an engine verb reaches first, first on PATH: each
# call is written to $BATS_TEST_TMPDIR/calls, which a refusal leaves unwritten.
record_engine_tools() {
  local rec="$BATS_TEST_TMPDIR/recorders" tool
  mkdir -p "$rec"
  for tool in defaults hs osascript pgrep; do
    printf '#!/bin/sh\necho "%s $*" >> "%s/calls"\n' "$tool" "$BATS_TEST_TMPDIR" >"$rec/$tool"
    chmod +x "$rec/$tool"
  done
  export PATH="$rec:$PATH"
}

@test "AT-02.1: arngz.yaml declares the hs tool macOS only (issue 0083)" {
  run yq -o=json -I=0 '.dependencies[] | select(.name == "hs") | .platforms' "$UTILZ_HOME/opt/arngz/arngz.yaml"
  assert_output '["macos"]'
}

# AT-04.9 (ST0032)
@test "on Linux, apply, a bare desk, diff, discover and init --yes refuse by name before any defaults or hs call (issue 0083)" {
  machine
  hammerspoon_installed
  catalogue
  record_engine_tools
  stub_platform Linux
  local args verb checked=""
  # The table stays, because each verb needs different words after it, but it
  # is checked against ARNGZ_ENGINE_VERBS below: a verb added to the gate's
  # list and not to this table fails here rather than going unexercised, which
  # is how ST0032/04's two verbs would have shipped refusing as "arngz apply".
  for args in "apply zeop1" "zeop1" "diff zeop1" "discover" "which" "auto" "init --yes"; do
    verb="arngz $args"
    verb="${verb% zeop1}"
    if [[ "$args" == zeop1 ]]; then
      verb="arngz apply"
    fi
    # shellcheck disable=SC2086 # each case is a verb and its words
    run_arngz $args
    assert_exit_code 2
    assert_output_contains "$verb needs macOS and Hammerspoon, so it is not available on Linux; arngz list, show, delete, current and log work here"
    checked="$checked ${args%% *}"
  done
  local engine_verb
  local -a engine_verbs
  read -r -a engine_verbs <<<"$(arngz_list ARNGZ_ENGINE_VERBS)"
  [ "${#engine_verbs[@]}" -gt 0 ] || fail "ARNGZ_ENGINE_VERBS could not be read from the script"
  for engine_verb in "${engine_verbs[@]}"; do
    case " $checked " in
      *" $engine_verb "*) ;;
      *) fail "ARNGZ_ENGINE_VERBS names $engine_verb and this test does not exercise it" ;;
    esac
  done
  [ ! -e "$BATS_TEST_TMPDIR/calls" ] || fail "an engine tool was called: $(cat "$BATS_TEST_TMPDIR/calls")"
  [ -z "$(ls -A "$FAKE_HS_LOG")" ] || fail "the fake hs was called: $(ls "$FAKE_HS_LOG")"
}

@test "on Linux, init makes the catalogue and gives no Hammerspoon advice (issue 0083)" {
  machine
  stub_platform Linux
  run_arngz init
  assert_success
  [ -d "$XDG_CONFIG_HOME/arngz/desks" ] || fail "no catalogue at $XDG_CONFIG_HOME/arngz/desks: $output"
  assert_output_contains "catalogue: $XDG_CONFIG_HOME/arngz/desks (created)"
  assert_output_contains "$ENGINE_OFF_LINUX"
  refute_output_contains "Hammerspoon:"
  refute_output_contains "hs tool:"
  refute_output_contains "init.lua:"
}

@test "on Linux, doctor says the engine is not available here and checks the catalogue alone (issue 0083)" {
  machine
  stub_platform Linux
  run_arngz doctor
  assert_exit_code 1
  assert_output_contains "$ENGINE_OFF_LINUX"
  assert_output_contains "FAIL  catalogue"
  assert_output_contains "fix: arngz init"
  refute_output_contains "hs tool"
  refute_output_contains "Accessibility"
  assert_doctor_summary 1

  run_arngz init
  assert_success
  run_arngz doctor
  assert_success
  assert_output_contains "ok    catalogue"
  assert_doctor_summary
}

@test "on Linux, list, show, delete and current work as they do anywhere (issue 0083)" {
  catalogue
  stub_platform Linux
  run_arngz list
  assert_success
  assert_output_contains "zeop1"
  run_arngz show zeop1
  assert_success
  assert_output_contains "desk: zeop1"
  run_arngz current
  assert_exit_code 1
  refute_output_contains "not available on"
  run_arngz delete zeop1
  assert_success
  assert_output_contains "deleted"
}

# ============================================================================
# ST0032/04 -- which and auto: the desk the screens present are
# ============================================================================

# The catalogue first, then the fake hs: both set XDG_CONFIG_HOME to the same
# path, so the desk catalogue() wrote is the one which_options reads.
which_fixture() {
  catalogue
  fake_hs ok "$FIXTURES/responses/$1"
}

# For the tests that reach cmd_apply through auto: the whole fixture machine,
# so apply_prefs reads the stub defaults rather than the host's. With
# which_fixture alone, fake_hs installs an hs and narrows nothing else, so
# apply_prefs refuses exit 2 on any Mac with Automatically rearrange Spaces on
# (macOS's default) and fails outright on Linux where defaults is absent --
# both for a reason that has nothing to do with the subject, and both against
# this file's promise that nothing here reaches the real machine.
which_apply_fixture() {
  apply_machine ok "$FIXTURES/responses/$1"
}

@test "ST0032/04: which names the desk the screens present are, on stdout, and exits 0" {
  which_fixture which-one.json
  run_arngz which
  assert_success
  assert_output_contains "zeop1"
}

@test "ST0032/04: which asks the engine for which, carrying every desk in the catalogue and no desk argument" {
  which_fixture which-one.json
  run_arngz which
  run yq -r '.verb' "$FAKE_HS_LOG/request.json"
  assert_output "which"
  # The desks travel in the options, because the catalogue's layout is the
  # CLI's to know and the engine is handed data.
  run yq -r '.options.desks[0].name' "$FAKE_HS_LOG/request.json"
  assert_output "zeop1"
  run yq -r '.options.desks[0].desk.desk' "$FAKE_HS_LOG/request.json"
  assert_output "zeop1"
}

# AT-04.6 (ST0032)
@test "ST0032/04: which exits 1 when no desk fits, and says what to do about it" {
  which_fixture which-none.json
  run_arngz which
  assert_exit_code 1
  assert_output_contains "no desk fits the screens present"
  assert_output_contains "discover --save"
}

@test "ST0032/04: which exits 2 when several desks fit and none is the current one" {
  which_fixture which-several.json
  run_arngz which
  assert_exit_code 2
  assert_output_contains "more than one desk fits"
}

@test "ST0032/04: which takes no arguments" {
  which_fixture which-one.json
  run_arngz which zeop1
  assert_exit_code 2
  assert_output_contains "which takes no arguments"
}

# AT-04.8 (ST0032)
@test "ST0032/04: which is read as a verb, not as the name of a desk to apply" {
  which_fixture which-one.json
  run_arngz which
  # Positively, not by refuting "apply". Without the which) arm, cmd_apply
  # which is refused by desk_name_refusal before any request is written, so
  # the file would be missing, yq would error, and a refutation would hold in
  # both shapes -- green whether the defect is there or not.
  [ -f "$FAKE_HS_LOG/request.json" ] || fail "no request was written: $output"
  run yq -r '.verb' "$FAKE_HS_LOG/request.json"
  assert_output "which"
}

@test "ST0032/04: auto hands the desk it found to apply, rather than applying it itself" {
  which_apply_fixture which-one.json
  run_arngz auto
  # auto makes two engine calls, and the fake serves one canned response, so
  # the apply leg's own answer is not what is checked here: the request the
  # fake last recorded is, which proves auto delegated to apply by name.
  run yq -r '.verb' "$FAKE_HS_LOG/request.json"
  assert_output "apply"
  run yq -r '.desk.desk' "$FAKE_HS_LOG/request.json"
  assert_output "zeop1"
}

@test "ST0032/04: auto falls back to --default when no desk fits, and says that it did" {
  which_apply_fixture which-none.json
  run_arngz auto --default zeop1
  assert_output_contains "no desk fits the screens present: falling back to 'zeop1'"
  run yq -r '.verb' "$FAKE_HS_LOG/request.json"
  assert_output "apply"
}

@test "ST0032/04: auto with no desk fitting and no --default moves nothing, exit 1" {
  which_fixture which-none.json
  run_arngz auto
  assert_exit_code 1
  assert_output_contains "no --default was given: nothing moved"
}

@test "ST0032/04: auto moves nothing when several desks fit, exit 2" {
  which_fixture which-several.json
  run_arngz auto
  assert_exit_code 2
  assert_output_contains "nothing moved"
}

# AT-04.7 (ST0032)
@test "ST0032/04: auto refuses a --default that is not a desk before it reads the screens" {
  which_fixture which-one.json
  run_arngz auto --default nosuchdesk
  assert_exit_code 2
  assert_output_contains "no such desk"
  # Refused before the engine was asked anything, so a typo costs no observe.
  [ ! -f "$FAKE_HS_LOG/request.json" ]
}

@test "ST0032/04: auto refuses a --default named like a verb, and --default with no value" {
  which_fixture which-one.json
  run_arngz auto --default apply
  assert_exit_code 2
  assert_output_contains "may not be named like a verb"
  run_arngz auto --default
  assert_exit_code 2
  assert_output_contains "--default takes a desk name"
}

@test "ST0032/04: a desk may not be named which or auto" {
  # fake_hs as well as the catalogue, for the RED path: the name refusal fires
  # before any engine call, so the green path reaches nothing, but if that
  # refusal ever stopped firing this test would run discover for real against
  # the host's screens. AT-04.3 sets fake_hs for the same shape.
  which_fixture which-one.json
  run_arngz discover --save which
  assert_exit_code 2
  assert_output_contains "may not be named like a verb"
  run_arngz discover --save auto
  assert_exit_code 2
  assert_output_contains "may not be named like a verb"
}

# ============================================================================
# ST0034 -- the sizes apps hold their windows at (issue 0138)
# ============================================================================

# The records file, under this test's own XDG_STATE_HOME.
own_sizes_at() {
  printf '%s/arngz/own-sizes\n' "$XDG_STATE_HOME"
}

# AT-01.5 (ST0034)
@test "0138: diff passes the recorded own sizes to the engine and reads a window at one as no change, exit 0" {
  local response file
  response="$(engine_response plan own_size_world base_desk own_size_records)"
  fake_hs ok "$response"
  catalogue
  file="$(own_sizes_at)"
  mkdir -p "${file%/*}"
  printf '[{"bundle":"com.apple.safari","want":{"w":600,"h":800},"size":{"w":375,"h":667}}]\n' >"$file"
  run_arngz diff zeop1
  assert_success
  assert_output_contains "no change: this machine already matches the desk"
  assert_output_contains "window 102 in place at the app's own size, 375x667"
  # A valid file is read as one: no word of it being unreadable or not a list,
  # which a stderr warning captured with yq's shape once caused (ST0034).
  refute_output_contains "sizes apps hold their windows at"
  run yq -r '.options.own_sizes[0].bundle + " " + (.options.own_sizes[0].size.w | tostring)' "$FAKE_HS_LOG/request.json"
  assert_output "com.apple.safari 375"
}

# AT-01.5 (ST0034)
@test "0138: with no own-sizes record, diff passes none and says nothing of it" {
  local response
  response="$(engine_response plan base_world base_desk)"
  fake_hs ok "$response"
  catalogue
  run_arngz diff zeop1
  assert_success
  refute_output_contains "sizes apps hold"
  run yq -r '.options | has("own_sizes")' "$FAKE_HS_LOG/request.json"
  assert_output "false"
}

# AT-01.5 (ST0034)
@test "0138: an own-sizes record that is not a list is said once and used as none" {
  local response file said
  response="$(engine_response plan base_world base_desk)"
  fake_hs ok "$response"
  catalogue
  file="$(own_sizes_at)"
  mkdir -p "${file%/*}"
  printf '{"bundle":"com.apple.safari"}\n' >"$file"
  run_arngz diff zeop1
  assert_success
  said="$(printf '%s\n' "$output" | grep -c "is not a list" || true)"
  [ "$said" = 1 ] || fail "the unreadable record was said $said times, not once: $output"
  run yq -r '.options | has("own_sizes")' "$FAKE_HS_LOG/request.json"
  assert_output "false"
}

# AT-01.5 (ST0034)
@test "0138: apply writes the records the engine returns when they changed, and passes the old ones in" {
  local response file
  response="$(engine_response apply own_size_results base_desk "")"
  apply_machine scheduled "$response"
  file="$(own_sizes_at)"
  run_arngz apply zeop1
  assert_success
  assert_output_contains "com.apple.Safari (displays[0].spaces[0].apps[1]): placed (in place at the app's own size, 375x667)"
  [ -f "$file" ] || fail "apply wrote no record at $file"
  run yq -r '.[0].bundle + " " + (.[0].want.w | tostring) + " " + (.[0].size.w | tostring)' "$file"
  assert_output "com.apple.safari 600 375"
  run ls -A "${file%/*}"
  refute_output_contains "own-sizes."
}

# AT-01.5 (ST0034)
@test "0138: apply clears a record the engine says the app let go of" {
  local response file
  response="$(engine_response apply own_size_let_go_results base_desk own_size_records)"
  apply_machine scheduled "$response"
  file="$(own_sizes_at)"
  mkdir -p "${file%/*}"
  printf '[{"bundle":"com.apple.safari","want":{"w":600,"h":800},"size":{"w":375,"h":667}}]\n' >"$file"
  run_arngz apply zeop1
  assert_success
  run yq -r 'length' "$file"
  assert_output "0"
}

# AT-01.5 (ST0034)
@test "0138: apply leaves the record untouched when the engine says nothing changed" {
  local response file before
  response="$(engine_response apply placed_results base_desk "")"
  apply_machine scheduled "$response"
  file="$(own_sizes_at)"
  mkdir -p "${file%/*}"
  # Spaced as no writer here spaces it, so a rewrite of the same list shows.
  printf '[ ]\n' >"$file"
  before="$(shasum -a 256 "$file")"
  run_arngz apply zeop1
  assert_success
  [ "$(shasum -a 256 "$file")" = "$before" ] || fail "apply rewrote a record that had not changed"
}

# ============================================================================
# AT-53ef07aa.1 -- the run log, the CLI's side (ST589246c, WP 53ef07aa)
# ============================================================================

# The run log as a run writes it, and the space-separated events of its
# records in order. The fake hs is not the engine, so every record here is the
# CLI's; the engine's are log_test.lua's (AT-53ef07aa.2).
run_log() {
  printf '%s/arngz/arngz.log\n' "$XDG_STATE_HOME"
}

log_events() {
  awk '{ printf "%s ", $4 }' "$1"
}

# AT-53ef07aa.1
@test "AT-53ef07aa.1: an engine run appends its records, start to end, every one under the run's one id" {
  fake_hs ok
  unset MENUZ_LOG
  run_arngz discover
  assert_success
  local log
  log="$(run_log)"
  [ -f "$log" ] || fail "no run log at $log"
  # A kill record comes between hs and answer when hs is still running as the
  # response lands, which the fake may or may not be. discover marks its start
  # and its end (hv decision 53), each a mark record inside the run's start
  # and end.
  [[ "$(log_events "$log")" =~ ^start\ mark\ request\ hs\ (kill\ )?answer\ mark\ end\ $ ]] ||
    fail "the records are not start, mark, request, hs, answer, mark, end: $(log_events "$log")"
  [ "$(awk '{ print $2 }' "$log" | sort -u | wc -l | tr -d ' ')" = 1 ] || fail "more than one run id: $(cat "$log")"
  [[ "$(awk '{ print $2; exit }' "$log")" =~ ^[0-9]{8}T[0-9]{6}Z-[0-9]+$ ]] || fail "the run id is not <UTC stamp>-<pid>"
  [ "$(awk '{ print $3 }' "$log" | sort -u)" = cli ] || fail "a record not the CLI's: $(cat "$log")"
  grep -q ' cli start arngz .*, tree '"$UTILZ_HOME"', discover, from shell$' "$log" || fail "the start record does not name the tree: $(head -1 "$log")"
  grep -q ' cli end exit 0 in [0-9]* s$' "$log" || fail "no end record with exit 0: $(cat "$log")"
  # How hs ended: it exited 0, or the CLI stopped it once the response landed.
  grep -q -E ' cli answer discover: returned 0 after [0-9]+ s; hs exited (0|killed); response ok$' "$log" ||
    fail "the answer record does not say how hs ended: $(grep ' answer ' "$log")"
}

# AT-53ef07aa.1
@test "AT-53ef07aa.1: a refusal before the engine is asked logs start, refused and end, exit 2" {
  catalogue
  run_arngz apply no-such-desk
  assert_exit_code 2
  local log
  log="$(run_log)"
  [ "$(log_events "$log")" = "start refused end " ] || fail "records: $(log_events "$log")"
  grep -q ' cli refused .*no-such-desk' "$log" || fail "the refused record does not say what: $(cat "$log")"
  grep -q ' cli end exit 2 in ' "$log" || fail "the end record is not exit 2: $(cat "$log")"
}

# AT-53ef07aa.1
@test "AT-53ef07aa.1: a read-only verb logs nothing, since Menuz runs current at every menu open" {
  catalogue
  # Each ran, and to its own end: current has no desk to name, list one desk.
  run_arngz current
  assert_exit_code 1
  run_arngz list
  assert_success
  assert_output_contains "zeop1"
  [ ! -e "$(run_log)" ] || fail "a read-only verb wrote the run log: $(cat "$(run_log)")"
}

# AT-53ef07aa.1
@test "AT-53ef07aa.1: the log puts nothing on screen: a logged run's stderr is exactly its report, and its stdout the desk" {
  fake_hs ok
  run --separate-stderr "$UTILZ_BIN_DIR/arngz" discover
  assert_success
  # discover prints the desk on stdout and its report on stderr; the log adds
  # a line to neither.
  [ "$stderr" = "$(yq -r '.report[]' "$FIXTURES/responses/discover.json")" ] || fail "stderr is not exactly the report: $stderr"
  [ -n "$output" ] || fail "no desk on stdout"
  refute_output_contains "run log"
  [ -f "$(run_log)" ] || fail "the run was not logged"
}

# AT-53ef07aa.1
@test "AT-53ef07aa.1: at ARNGZ_LOG_MAX the log moves to arngz.log.1 before the run writes, and two files at most" {
  fake_hs ok
  export ARNGZ_LOG_MAX=1
  local log second third
  log="$(run_log)"
  run_arngz discover
  run_arngz discover
  second="$(awk '$4 == "start" { print $2 }' "$log")"
  run_arngz discover
  third="$(awk '$4 == "start" { print $2 }' "$log")"
  [ "$(awk '$4 == "start" { print $2 }' "$log.1")" = "$second" ] || fail "arngz.log.1 is not the run before the last"
  [ "$third" != "$second" ] || fail "the last run's log is the run before it"
  run ls -A "${log%/*}"
  assert_output "$(printf 'arngz.log\narngz.log.1')"
}

# AT-53ef07aa.1
@test "AT-53ef07aa.1: a bad ARNGZ_LOG_MAX is refused before anything is sent or logged, exit 2" {
  fake_hs ok
  export ARNGZ_LOG_MAX=big
  run_arngz discover
  assert_exit_code 2
  assert_output_contains "ARNGZ_LOG_MAX = 'big': a whole number of bytes"
  [ ! -e "$FAKE_HS_LOG/argv" ] || fail "hs was asked"
  # Judged before the run has a log, as a platform refusal is: no start
  # without its end.
  [ ! -e "$(run_log)" ] || fail "a refused run wrote the run log: $(cat "$(run_log)")"
}

# AT-53ef07aa.1
@test "AT-53ef07aa.1: arngz log prints the last run, the watcher's records in it, and no other run's" {
  fake_hs ok
  local log first last
  log="$(run_log)"
  run_arngz discover
  first="$(awk '$4 == "start" { print $2 }' "$log")"
  run_arngz discover
  last="$(awk '$4 == "start" { id = $2 } END { print id }' "$log")"
  printf '%s - displays change 1 display(s) attached\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >>"$log"
  printf '%s other-run engine point start verb=which\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >>"$log"
  run_arngz log
  assert_success
  [ "$(printf '%s\n' "$output" | awk '{ print $4; exit }')" = start ] || fail "it does not begin at the run's start: $output"
  [ "$(printf '%s\n' "$output" | awk '{ print $2; exit }')" = "$last" ] || fail "it does not begin at the last run: $output"
  assert_output_contains " - displays change 1 display(s) attached"
  refute_output_contains "$first"
  refute_output_contains "other-run"
}

# AT-53ef07aa.1
@test "AT-53ef07aa.1: arngz log with no run logged says where it looked, exit 1" {
  catalogue
  run_arngz log
  assert_exit_code 1
  assert_output_contains "no run is logged yet: there is no $(run_log)"
}

# AT-53ef07aa.1
@test "AT-53ef07aa.1: a log that cannot be written is said once on stderr, and the run keeps its exit" {
  fake_hs ok
  export XDG_STATE_HOME="$BATS_TEST_TMPDIR/state-is-a-file"
  : >"$XDG_STATE_HOME"
  run --separate-stderr "$UTILZ_BIN_DIR/arngz" discover
  assert_success
  [ "$(printf '%s\n' "$stderr" | grep -c 'the run log could not be written')" = 1 ] || fail "not said exactly once: $stderr"
  # The run's own report is still there, on stderr where discover puts it.
  printf '%s\n' "$stderr" | grep -q '^FIXTURE-LINE-1 ' || fail "the report is gone: $stderr"
}

# ============================================================================
# ST589246c/93ea7f8a -- the displays settle before a verb acts on what it reads
# ============================================================================

# AT-93ea7f8a.5
@test "AT-93ea7f8a.5: auto's which and discover --save ask for the displays to settle first; which and plain discover do not" {
  local response
  which_fixture which-none.json
  run_arngz which
  run yq -o json -I0 '.options.quiet' "$FAKE_HS_LOG/request.json"
  assert_output "null"
  run_arngz auto
  assert_exit_code 1
  run yq -o json -I0 '.options.quiet' "$FAKE_HS_LOG/request.json"
  assert_output "{}"
  response="$(engine_response discover discover_world "" "zeop2")"
  fake_hs ok "$response"
  run_arngz discover
  assert_success
  run yq -o json -I0 '.options.quiet' "$FAKE_HS_LOG/request.json"
  assert_output "null"
  run_arngz discover --save zeop2
  assert_success
  run yq -o json -I0 '.options.quiet' "$FAKE_HS_LOG/request.json"
  assert_output "{}"
}

# AT-93ea7f8a.5
@test "AT-93ea7f8a.5: told the displays have not settled, the CLI sleeps what the engine names, then asks again with the wait's start" {
  local response first
  response="$(engine_response discover discover_world "" "zeop2")"
  fake_hs unsettled-once "$response"
  export FAKE_HS_WAIT=0.1 FAKE_HS_BEGAN=1795000000.125
  run_arngz discover --save zeop2
  assert_success
  assert_output_contains "waiting $FAKE_HS_WAIT s for them to settle"
  assert_output_contains "saved $XDG_CONFIG_HOME/arngz/desks/zeop2.yaml"
  run yq -o json -I0 '.options.quiet' "$FAKE_HS_LOG/request.1.json"
  assert_output "{}"
  run yq -r '.options.quiet.began' "$FAKE_HS_LOG/request.json"
  assert_output "$FAKE_HS_BEGAN"
  # Both asks are one run.
  first="$(yq -r '.run' "$FAKE_HS_LOG/request.1.json")"
  [[ -n "$first" && "$first" != null ]] || fail "the first ask carries no run: '$first'"
  run yq -r '.run' "$FAKE_HS_LOG/request.json"
  assert_output "$first"
}

# AT-93ea7f8a.5
@test "AT-93ea7f8a.5: displays that do not settle refuse discover --save and auto, exit 2, writing and applying nothing" {
  local refused="$BATS_TEST_TMPDIR/refused.json"
  local why="the displays did not settle in 20 s: they had been unchanged for 1.5 s, and 5 s is needed"
  local fix="run it again once the displays have stopped changing"
  W="$why" F="$fix" yq -n -o json '{"status": "error", "kind": "refused", "error": strenv(W), "fix": strenv(F)}' >"$refused"
  catalogue
  fake_hs ok "$refused"
  run_arngz discover --save zeop2
  assert_exit_code 2
  assert_output_contains "$why"
  assert_output_contains "$fix"
  # The refusal came to the ask that waits for the displays to settle.
  run yq -o json -I0 '.options.quiet' "$FAKE_HS_LOG/request.json"
  assert_output "{}"
  [ ! -e "$XDG_CONFIG_HOME/arngz/desks/zeop2.yaml" ] || fail "a desk was written: $XDG_CONFIG_HOME/arngz/desks/zeop2.yaml"
  run_arngz auto --default zeop1
  assert_exit_code 2
  assert_output_contains "$why"
  run yq -r '.verb' "$FAKE_HS_LOG/request.json"
  assert_output "which"
}

# AT-93ea7f8a.5
@test "AT-93ea7f8a.5: an engine's wait that is not a time is refused, exit 2, after one ask and writing nothing" {
  local response
  response="$(engine_response discover discover_world "" "zeop2")"
  fake_hs unsettled-once "$response"
  export FAKE_HS_WAIT=soon FAKE_HS_BEGAN=1795000000.125
  run_arngz discover --save zeop2
  assert_exit_code 2
  assert_output_contains "the engine asked discover to wait '$FAKE_HS_WAIT' s from '$FAKE_HS_BEGAN', which are not times"
  [ ! -e "$XDG_CONFIG_HOME/arngz/desks/zeop2.yaml" ] || fail "a desk was written: $XDG_CONFIG_HOME/arngz/desks/zeop2.yaml"
  [ ! -e "$FAKE_HS_LOG/request.2.json" ] || fail "the engine was asked again after a wait that is not a time"
}

# AT-93ea7f8a.5
@test "AT-93ea7f8a.5: an engine's wait whose start is not a time is refused, exit 2, after one ask and writing nothing" {
  local response
  response="$(engine_response discover discover_world "" "zeop2")"
  fake_hs unsettled-once "$response"
  export FAKE_HS_WAIT=0.1 FAKE_HS_BEGAN=later
  run_arngz discover --save zeop2
  assert_exit_code 2
  assert_output_contains "the engine asked discover to wait '$FAKE_HS_WAIT' s from '$FAKE_HS_BEGAN', which are not times"
  [ ! -e "$XDG_CONFIG_HOME/arngz/desks/zeop2.yaml" ] || fail "a desk was written: $XDG_CONFIG_HOME/arngz/desks/zeop2.yaml"
  [ ! -e "$FAKE_HS_LOG/request.2.json" ] || fail "the engine was asked again after a start that is not a time"
}

# AT-93ea7f8a.5
@test "AT-93ea7f8a.5: an engine's wait whose start moves is refused, exit 2, after two asks and writing nothing" {
  local response
  response="$(engine_response discover discover_world "" "zeop2")"
  fake_hs unsettled-moved "$response"
  export FAKE_HS_WAIT=0.1 FAKE_HS_BEGAN=1795000000.125 FAKE_HS_BEGAN_AGAIN=1795000003.250
  run_arngz discover --save zeop2
  assert_exit_code 2
  assert_output_contains "it began at $FAKE_HS_BEGAN, and now at $FAKE_HS_BEGAN_AGAIN"
  [ ! -e "$XDG_CONFIG_HOME/arngz/desks/zeop2.yaml" ] || fail "a desk was written: $XDG_CONFIG_HOME/arngz/desks/zeop2.yaml"
  [ -e "$FAKE_HS_LOG/request.2.json" ] || fail "the engine was not asked again after the first wait"
  [ ! -e "$FAKE_HS_LOG/request.3.json" ] || fail "the engine was asked a third time after its wait moved"
}

# AT-93ea7f8a.5
@test "AT-93ea7f8a.5: diff does not wait for the displays to settle: its request asks for no quiet" {
  local response
  response="$(engine_response plan off_cell_world base_desk)"
  fake_hs ok "$response"
  catalogue
  run_arngz diff zeop1
  assert_exit_code 1
  run yq -o json -I0 '.options.quiet' "$FAKE_HS_LOG/request.json"
  assert_output "null"
}

# AT-93ea7f8a.6
@test "AT-93ea7f8a.6: an hs that exits on its own just after its response is let exit, and one that hangs is stopped only past its own timeout (F3, I7085193)" {
  local took
  fake_hs reply-then-exit
  export FAKE_HS_EXIT_AFTER=0.5
  run_arngz discover
  assert_success
  run grep -c ' cli kill ' "$(run_log)"
  assert_output "0"
  grep -qE ' cli answer discover: returned 0 after [0-9]+ s; hs exited 0; ' "$(run_log)" ||
    fail "hs's own exit is not the answer's: $(grep ' cli answer ' "$(run_log)")"
  # One that hangs after replying (the fake ignores -t, as the 16 Oct hang
  # did) is stopped only once its own timeout has run out, never while it may
  # still be taking Hammerspoon's reply (issue I7085193).
  fake_hs hang-after-reply
  export ARNGZ_HS_TIMEOUT=2
  run_arngz discover
  assert_success
  grep -q " cli kill stopped hs (pid [0-9]*): it outlived its own $ARNGZ_HS_TIMEOUT s timeout by [0-9]* s after its response came" \
    "$(run_log)" || fail "the hung hs was not stopped past its timeout: $(grep ' cli kill ' "$(run_log)")"
  took="$(sed -n 's/.* cli answer discover: returned 0 after \([0-9]*\) s; hs exited killed;.*/\1/p' "$(run_log)")"
  # The margin as the CLI sets it; less one, since the log counts whole
  # seconds (ic's N1 on a43e31cd).
  local margin
  margin="$(sed -n 's/^HS_EXIT_MARGIN=\([0-9]*\)$/\1/p' "$UTILZ_HOME/opt/arngz/arngz")"
  [ -n "$margin" ] || fail "the CLI sets no HS_EXIT_MARGIN"
  [ -n "$took" ] && [ "$took" -ge $((ARNGZ_HS_TIMEOUT + margin - 1)) ] ||
    fail "the hung hs was stopped before its own timeout and the margin ran out: '$took' s"
}

# Issue I7085193: on 26 Nov 2026 the CLI stopped an hs 3 s after its
# response, and Hammerspoon crashed replying to it. An hs that ends on its own
# later than that, within its timeout, is let end.
@test "I7085193: an hs that exits on its own seconds after its response is let exit, not stopped" {
  fake_hs reply-then-exit
  export FAKE_HS_EXIT_AFTER=4.5
  export ARNGZ_HS_TIMEOUT=30
  run_arngz discover
  assert_success
  run grep -c ' cli kill ' "$(run_log)"
  assert_output "0"
  grep -qE ' cli answer discover: returned 0 after [0-9]+ s; hs exited 0; ' "$(run_log)" ||
    fail "hs's own exit is not the answer's: $(grep ' cli answer ' "$(run_log)")"
}

# AT-93ea7f8a.6
@test "AT-93ea7f8a.6: discover may take longer than other calls, and ARNGZ_HS_TIMEOUT still sets every call's deadline (F4)" {
  local discover_t which_t
  which_fixture which-none.json
  unset ARNGZ_HS_TIMEOUT
  run_arngz which
  which_t="$(sed -n '/^-t$/{n;p;}' "$FAKE_HS_LOG/argv")"
  fake_hs ok
  run_arngz discover
  assert_success
  discover_t="$(sed -n '/^-t$/{n;p;}' "$FAKE_HS_LOG/argv")"
  [ "$discover_t" -gt "$which_t" ] || fail "discover's deadline, $discover_t s, is not longer than which's, $which_t s"
  export ARNGZ_HS_TIMEOUT=7
  run_arngz discover
  assert_success
  run sed -n '/^-t$/{n;p;}' "$FAKE_HS_LOG/argv"
  assert_output "$ARNGZ_HS_TIMEOUT"
}

# ============================================================================
# hv decision 53 -- the start and end marks (ic's marks-note, 26 Nov 2026)
# ============================================================================

# The marks' sounds on, each a file of this test's own, so the arms hear a
# sound on any machine; the fake afplay, first on PATH in fake_hs and in the
# fixture machine, logs each file it is given.
sounds_on() {
  export ARNGZ_SOUNDS=on
  export ARNGZ_SOUND_START="$BATS_TEST_TMPDIR/begin_record.caf"
  export ARNGZ_SOUND_END="$BATS_TEST_TMPDIR/end_record.caf"
  : >"$ARNGZ_SOUND_START"
  : >"$ARNGZ_SOUND_END"
}

# The CLI does not wait for the end mark's call or for a sound, so an arm reads
# them once the end mark (end or still) is logged, or 5 s have passed.
marks_settled() {
  local deadline=$((SECONDS + 5))
  until grep -qE '^mark (end|still) ' "$FAKE_HS_LOG/calls" 2>/dev/null || [[ $SECONDS -ge $deadline ]]; do
    sleep 0.1
  done
}

sounds_settled() {
  local deadline=$((SECONDS + 5))
  until grep -qxF "$ARNGZ_SOUND_END" "$FAKE_HS_LOG/sounds" 2>/dev/null || [[ $SECONDS -ge $deadline ]]; do
    sleep 0.1
  done
}

# The calls a marked run made: the start mark first, for LIFE seconds; only
# asks between, at least one; and LAST, the end mark, last.
assert_marks() {
  local life="$1" last="$2" calls
  marks_settled
  calls="$(cat "$FAKE_HS_LOG/calls")" || fail "no hs call was logged"
  [ "$(head -n 1 <<<"$calls")" = "mark start $life arngz: starting" ] || fail "the first call is not the start mark: $calls"
  [ "$(tail -n 1 <<<"$calls")" = "$last" ] || fail "the last call is not '$last': $calls"
  if sed '1d;$d' <<<"$calls" | grep -q '^mark '; then fail "a mark between the start and the end: $calls"; fi
  sed '1d;$d' <<<"$calls" | grep -q '^run ' || fail "no ask between the marks: $calls"
}

# The sounds a run played, as one sorted list, against WANT's files.
assert_sounds() {
  local want="$1" got
  sounds_settled
  got="$(sort "$FAKE_HS_LOG/sounds" 2>/dev/null)" || got=""
  [ "$got" = "$(sort <<<"$want")" ] || fail "the sounds were: '$got', not: '$want'"
}

@test "hv decision 53: discover marks its start and 'done', with the rising and the falling sound" {
  fake_hs ok
  sounds_on
  export ARNGZ_HS_TIMEOUT=30
  run_arngz discover
  assert_success
  assert_marks "$((2 * ARNGZ_HS_TIMEOUT))" "mark end 0 arngz: done"
  assert_sounds "$(printf '%s\n%s' "$ARNGZ_SOUND_START" "$ARNGZ_SOUND_END")"
  grep -q ' cli mark start: arngz: starting$' "$(run_log)" || fail "no start mark record: $(cat "$(run_log)")"
  grep -q ' cli mark end: arngz: done$' "$(run_log)" || fail "no end mark record: $(cat "$(run_log)")"
}

@test "hv decision 53: done with problems, exit 1, is 'done' too" {
  fake_hs ok "$FIXTURES/responses/discover-gaps.json"
  sounds_on
  export ARNGZ_HS_TIMEOUT=30
  run_arngz discover
  assert_exit_code 1
  assert_marks "$((2 * ARNGZ_HS_TIMEOUT))" "mark end 0 arngz: done"
  assert_sounds "$(printf '%s\n%s' "$ARNGZ_SOUND_START" "$ARNGZ_SOUND_END")"
}

@test "hv decision 53: an apply marks its start and 'done', and its start mark stays for twice its longest wait" {
  apply_machine scheduled "$(apply_response placed_results)"
  sounds_on
  export ARNGZ_HS_TIMEOUT=30
  run_arngz apply zeop1
  assert_success
  assert_marks "$((2 * (ARNGZ_HS_TIMEOUT + ARNGZ_APPLY_TIMEOUT)))" "mark end 0 arngz: done"
  assert_sounds "$(printf '%s\n%s' "$ARNGZ_SOUND_START" "$ARNGZ_SOUND_END")"
}

@test "hv decision 53: a refusal by the engine, exit 2, ends 'stopped: refused' with the falling sound" {
  fake_hs ok "$FIXTURES/responses/discover-refused.json"
  sounds_on
  export ARNGZ_HS_TIMEOUT=30
  run_arngz discover
  assert_exit_code 2
  assert_marks "$((2 * ARNGZ_HS_TIMEOUT))" "mark end 0 arngz: stopped: refused"
  assert_sounds "$(printf '%s\n%s' "$ARNGZ_SOUND_START" "$ARNGZ_SOUND_END")"
}

@test "hv decision 53: a Hammerspoon that does not answer still gets both sounds, and the mark's failure is logged" {
  fake_hs exit-69
  sounds_on
  export ARNGZ_HS_TIMEOUT=30 FAKE_HS_MARK_EXIT=69
  run_arngz discover
  assert_exit_code 2
  assert_marks "$((2 * ARNGZ_HS_TIMEOUT))" "mark end 0 arngz: stopped: refused"
  assert_sounds "$(printf '%s\n%s' "$ARNGZ_SOUND_START" "$ARNGZ_SOUND_END")"
  grep -q " cli mark the start mark's hs call exited 69$" "$(run_log)" || fail "the failed mark is not logged: $(cat "$(run_log)")"
}

@test "hv decision 53: an apply the CLI stopped waiting for says it is still running, plays no falling sound, and leaves the engine its file" {
  apply_machine scheduled-never "$(apply_response placed_results)"
  sounds_on
  export ARNGZ_HS_TIMEOUT=30 ARNGZ_APPLY_TIMEOUT=1
  run_arngz apply zeop1
  assert_exit_code 1
  marks_settled
  local last kept
  last="$(tail -n 1 "$FAKE_HS_LOG/calls")"
  [[ "$last" =~ ^mark\ still\ $((2 * (ARNGZ_HS_TIMEOUT + ARNGZ_APPLY_TIMEOUT)))\ arngz:\ still\ running\ in\ Hammerspoon\ \(arngz\ stopped\ waiting\ after\ [0-9]+\ s\)$ ]] ||
    fail "the last call is not the still mark: $(cat "$FAKE_HS_LOG/calls")"
  assert_sounds "$ARNGZ_SOUND_START"
  kept="$(printf '%s\n' "$output" | sed -n 's/.*(request kept at \([^)]*\)).*/\1/p')"
  [ -f "${kept%/request.json}/stopped-waiting" ] || fail "no stopped-waiting file beside $kept"
  run yq -r '.end_sound' "$kept"
  assert_output "$ARNGZ_SOUND_END"
}

# One apply sent SIGNAL once the engine has its ask; STATUS is its exit. Each
# trial starts with no calls and no sounds logged. bash starts a background
# job with SIGINT ignored, and a shell cannot trap a signal ignored when it
# starts, so the CLI would never see the INT (set -m did not change this in
# cc's run of f90fda57: INT exited 1, after the whole wait). perl puts SIGINT
# back to its default and then execs the CLI, so the CLI's trap is set as it
# is under a terminal's Ctrl-C.
interrupted_apply() {
  local signal="$1" pid deadline
  rm -f "$FAKE_HS_LOG/calls" "$FAKE_HS_LOG/sounds"
  perl -e '$SIG{INT} = "DEFAULT"; exec @ARGV or die "exec $ARGV[0]: $!\n"' \
    "$UTILZ_BIN_DIR/arngz" apply zeop1 >/dev/null 2>&1 3>&- &
  pid=$!
  deadline=$((SECONDS + 10))
  until grep -qx 'run apply' "$FAKE_HS_LOG/calls" 2>/dev/null || [[ $SECONDS -ge $deadline ]]; do
    sleep 0.1
  done
  kill -s "$signal" "$pid"
  status=0
  wait "$pid" || status=$?
  ! kill -0 "$pid" 2>/dev/null || fail "the CLI still runs after $signal"
}

@test "hv decision 53: SIGINT and SIGTERM end 'stopped: interrupted' with the falling sound, on every trial" {
  apply_machine scheduled-never "$(apply_response placed_results)"
  sounds_on
  export ARNGZ_HS_TIMEOUT=30
  local signal want trial
  for signal in INT TERM; do
    want=130
    [ "$signal" = INT ] || want=143
    for trial in 1 2 3 4 5; do
      interrupted_apply "$signal"
      [ "$status" -eq "$want" ] || fail "trial $trial: $signal exited $status, not $want"
      assert_marks "$((2 * (ARNGZ_HS_TIMEOUT + ARNGZ_APPLY_TIMEOUT)))" "mark end 0 arngz: stopped: interrupted"
      assert_sounds "$(printf '%s\n%s' "$ARNGZ_SOUND_START" "$ARNGZ_SOUND_END")"
    done
  done
}

@test "hv decision 53: ARNGZ_SOUNDS=off draws the marks and plays nothing; a bad value is refused before any mark" {
  fake_hs ok
  sounds_on
  export ARNGZ_SOUNDS=off ARNGZ_HS_TIMEOUT=30
  run_arngz discover
  assert_success
  assert_marks "$((2 * ARNGZ_HS_TIMEOUT))" "mark end 0 arngz: done"
  [ ! -e "$FAKE_HS_LOG/sounds" ] || fail "a sound played: $(cat "$FAKE_HS_LOG/sounds")"

  rm -f "$FAKE_HS_LOG/calls"
  export ARNGZ_SOUNDS=loud
  run_arngz discover
  assert_exit_code 2
  assert_output_contains "ARNGZ_SOUNDS = 'loud': it takes on or off"
  [ ! -e "$FAKE_HS_LOG/calls" ] || fail "hs was called: $(cat "$FAKE_HS_LOG/calls")"
  [ ! -e "$FAKE_HS_LOG/sounds" ] || fail "a sound played: $(cat "$FAKE_HS_LOG/sounds")"
}

@test "hv decision 53: diff and apply --dry-run change nothing, so they make no mark and no sound" {
  apply_machine ok "$(engine_response plan base_world base_desk)"
  sounds_on
  local verb
  for verb in diff "apply --dry-run"; do
    rm -f "$FAKE_HS_LOG/calls"
    # shellcheck disable=SC2086 # the verb and its flag, split on purpose
    run_arngz $verb zeop1
    [ "$(cat "$FAKE_HS_LOG/calls")" = "run plan" ] || fail "$verb called: $(cat "$FAKE_HS_LOG/calls")"
  done
  [ ! -e "$FAKE_HS_LOG/sounds" ] || fail "a sound played: $(cat "$FAKE_HS_LOG/sounds")"
}

# late_answer_claim alone, from the CLI's own source: the answer that comes
# as the CLI stops waiting. Each case is laid out on disk first, so no arm
# rests on timing: the remove of stopped-waiting is the claim, and exactly
# one side ends the mark.
@test "hv decision 53: an answer that comes as the CLI stops waiting has its mark ended by one side alone" {
  eval "$(sed -n '/^late_answer_claim() {$/,/^}$/p' "$UTILZ_HOME/opt/arngz/arngz")"
  declare -F late_answer_claim >/dev/null || fail "the CLI has no late_answer_claim"
  local dir="$BATS_TEST_TMPDIR/late" flag rc
  mkdir -p "$dir"
  flag="$dir/stopped-waiting"

  : >"$flag"
  rc=0
  late_answer_claim "$dir/response.json" "$flag" 1 || rc=$?
  [ "$rc" -ne 0 ] || fail "no answer yet, and the run was not left pending"
  [ -e "$flag" ] || fail "a pending run lost the engine's file"

  : >"$dir/response.json"
  late_answer_claim "$dir/response.json" "$flag" 1 || fail "an answer that came was left pending"
  [ "$ENGINE_MARK_BY_ENGINE" -eq 0 ] || fail "the CLI removed the file, and still left the mark to the engine"
  [ ! -e "$flag" ] || fail "the CLI's claim left the file for the engine to take as well"

  late_answer_claim "$dir/response.json" "$flag" 1 || fail "an answer the engine had claimed was left pending"
  [ "$ENGINE_MARK_BY_ENGINE" -eq 1 ] || fail "the engine took the file first, and the CLI ends the mark too"

  late_answer_claim "$dir/response.json" "$flag" 0 || fail "an answer with no file written was left pending"
  [ "$ENGINE_MARK_BY_ENGINE" -eq 0 ] || fail "no file was written, so the engine cannot end the mark, and the CLI left it"

  : >"$flag"
  chmod 555 "$dir"
  late_answer_claim "$dir/response.json" "$flag" 1 || fail "an answer with a file the CLI cannot remove was left pending"
  chmod 755 "$dir"
  [ "$ENGINE_MARK_BY_ENGINE" -eq 0 ] || fail "a file neither side can remove left the mark to nobody"
}
