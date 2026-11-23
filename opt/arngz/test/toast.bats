#!/usr/bin/env bats
# toast.bats - arngz's toasts under plain Lua (ST589246c, WP eae7633d)
#
# The driver is toast_test.lua, which carries AT-eae7633d.2 to AT-eae7633d.8
# (ST589246c acceptance.md). This arm runs it, as engine.bats runs
# engine_test.lua. run_tests() in opt/utilz/lib/common.sh finds suites with
# `find "$test_dir" -name "*.bats"`, so a file of its own here is run with no
# change to arngz.bats or engine.bats.
#
# NOTHING HERE REACHES THE REAL MACHINE. The driver injects a fake hs module
# inside Lua and never starts a process: no Hammerspoon, no display, no
# pointer, no catalogue. So it sets no UTILZ_TEST_PLATFORM, and runs alike on
# CI's macOS and Linux legs.

load "../../utilz/test/test_helper.bash"

bats_require_minimum_version 1.5.0

@test "AT-eae7633d.2 to .8: arngz's toasts pass under plain Lua" {
  local driver="$UTILZ_HOME/opt/arngz/test/toast_test.lua"
  local toast="$UTILZ_HOME/opt/arngz/lib/toast.lua"
  [ -f "$driver" ]
  [ -f "$toast" ]

  local lua
  lua="$(lua_bin)" || fail "no Lua interpreter (lua5.4, lua or luajit) on PATH; CI installs lua5.4"

  run "$lua" "$driver" "$toast"
  echo "$output"
  assert_success

  # The summary is parsed, not matched, by the shared helper in
  # test_helper.bash, which says why (issue 0136).
  assert_lua_suite_summary toast_test
}
