#!/usr/bin/env bats
# engine.bats - arngz's ENGINE under plain Lua (ST0033)
#
# AT-01.2 (ST0033 acceptance.md) cites this file: the suite arm that runs the
# engine's create_space driver. The driver itself is engine_test.lua and
# carries AT-01.1.
#
# WHY THIS IS A FILE OF ITS OWN AND NOT A NEW ARM IN arngz.bats. arngz.bats is
# the suite the arms ran green on at 5d7bfe37, and a cut's audit trail leans on
# that file not moving: a new arm inside it moves its total off 158 and makes
# the next reader re-establish what the green was of. run_tests() in
# opt/utilz/lib/common.sh finds suites with `find "$test_dir" -name "*.bats"`,
# so a new file here is discovered with no change to the old one. It also keeps
# a proof surface for the engine out of the suite for the CLI.
#
# NOTHING HERE REACHES THE REAL MACHINE, and it reaches it less than arngz.bats
# does: there is no fake hs TOOL on PATH and no fixture machine, because the
# driver injects a fake hs MODULE inside Lua and never starts a process. No
# Hammerspoon, no Spaces, no pointer, no catalogue, no XDG directory.
#
# NO PLATFORM PIN ON PURPOSE. This suite sets no UTILZ_TEST_PLATFORM because
# nothing in it is platform-gated, which is a property of the design and not an
# oversight: with hs injected, the engine's own logic runs identically on CI's
# Linux leg, where Hammerspoon cannot exist at all.

load "../../utilz/test/test_helper.bash"

bats_require_minimum_version 1.5.0

# ============================================================================
# AT-01.2 -- the engine's create_space driver, under plain Lua (AC-01.4)
# ============================================================================

@test "AT-01.2: the engine's create_space driver passes under plain Lua" {
  local driver="$UTILZ_HOME/opt/arngz/test/engine_test.lua"
  local engine="$UTILZ_HOME/opt/arngz/lib/arngz.lua"
  [ -f "$driver" ]
  [ -f "$engine" ]

  local lua
  lua="$(lua_bin)" || fail "no Lua interpreter (lua5.4, lua or luajit) on PATH; CI installs lua5.4"

  run "$lua" "$driver" "$engine"
  echo "$output"
  assert_success

  # The summary is parsed rather than matched, by the shared helper in
  # test_helper.bash, which carries the reason (issue 0136).
  assert_lua_suite_summary engine_test
}
