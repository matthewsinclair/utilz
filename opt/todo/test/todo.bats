#!/usr/bin/env bats
# todo.bats - Tests for the todo utility (ST0008).
#
# Test names match the Acceptance Test (AT) ids in
# intent/st/ST0008/acceptance.md so the AC->AT coverage map stays honest.

load "../../utilz/test/test_helper.bash"

# ----------------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------------

# The todo binary (via the dispatcher symlink).
TODO() { "$UTILZ_BIN_DIR/todo" "$@"; }

# Literal (fixed-string) file-content assertion. The house assert_file_contains
# treats its needle as a regex, and item lines contain `[`/`]`, so use grep -F.
file_has() {
  grep -qF -- "$2" "$1" || { echo "missing in $1: $2"; cat "$1"; return 1; }
}
file_lacks() {
  if grep -qF -- "$2" "$1"; then echo "unexpected in $1: $2"; cat "$1"; return 1; fi
}

# ----------------------------------------------------------------------------
# Framework smoke
# ----------------------------------------------------------------------------

@test "todo --version shows version" {
  run "$UTILZ_BIN_DIR/todo" --version
  assert_success
  assert_output_contains "todo"
}

@test "todo help shows usage" {
  run "$UTILZ_BIN_DIR/todo" help
  assert_success
  assert_output_contains "Usage: todo"
}

# ----------------------------------------------------------------------------
# WP-01 -- Scaffold + core
# ----------------------------------------------------------------------------

@test "list creates a template file with frontmatter and buckets" {
  run "$UTILZ_BIN_DIR/todo" list
  assert_success
  assert_file_exists "todo.md"
  file_has todo.md 'title: "# TODO"'
  file_has todo.md "history: _history/YYYYMMDD-done.md"
  file_has todo.md "# TODO"
  file_has todo.md "## DOING"
  file_has todo.md "## TODO"
  run grep -qE '^## DONE:[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z' todo.md
  assert_success
  file_has todo.md "_(none)_"
}

@test "add appends to bottom; add --top prepends" {
  TODO add "first task"
  TODO add "second task"
  TODO add --top "urgent task"
  file_has todo.md "1:[ ] urgent task"
  file_has todo.md "2:[ ] first task"
  file_has todo.md "3:[ ] second task"
}

@test "numbers are global, positional, zero-padded to max width" {
  local i
  for i in $(seq 1 10); do TODO add "item $i"; done
  # 10 items -> width 2 -> first item is 01, tenth is 10
  file_has todo.md "01:[ ] item 1"
  file_has todo.md "10:[ ] item 10"
}

@test "file-location precedence file over global over default; file+g errors" {
  export XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/xdg"
  # --file writes to the explicit path
  TODO --file "$BATS_TEST_TMPDIR/custom.md" add "in custom"
  assert_file_exists "$BATS_TEST_TMPDIR/custom.md"
  file_has "$BATS_TEST_TMPDIR/custom.md" "in custom"
  # -g writes under XDG
  TODO -g add "in global"
  assert_file_exists "$XDG_CONFIG_HOME/utilz/todo/todo.md"
  # default writes ./todo.md and did not leak into the others
  TODO add "in default"
  file_has todo.md "in default"
  file_lacks todo.md "in custom"
  # mutually exclusive
  run "$UTILZ_BIN_DIR/todo" --file x.md -g list
  assert_failure
  assert_output_contains "mutually exclusive"
}

@test "normalization is idempotent" {
  TODO add "alpha"
  TODO add "beta"
  TODO done 1
  TODO sync
  cp todo.md first.md
  TODO sync
  run diff first.md todo.md
  assert_success
}

# ----------------------------------------------------------------------------
# WP-02 -- Mutation verbs
# ----------------------------------------------------------------------------

@test "start moves to DOING as in-progress" {
  TODO add "task a"
  TODO start 1
  file_has todo.md "1:[-] task a"
}

@test "done prepends to DONE newest-first" {
  TODO add "old done"
  TODO add "new done"
  TODO done 1   # completes "old done"
  TODO done 1   # completes "new done" (was renumbered to 1)
  # newest completion sits at the top of DONE
  run grep -nF -- "new done" todo.md
  local new_line="${output%%:*}"
  run grep -nF -- "old done" todo.md
  local old_line="${output%%:*}"
  [ "$new_line" -lt "$old_line" ]
}

@test "notdone moves back to TODO" {
  TODO add "task b"
  TODO done 1
  file_has todo.md "1:[x] task b"
  TODO notdone 1
  file_has todo.md "1:[ ] task b"
}

@test "toggle flips from current glyph" {
  TODO add "task c"
  TODO toggle 1
  file_has todo.md "1:[x] task c"
  TODO toggle 1
  file_has todo.md "1:[ ] task c"
}

@test "unknown id errors non-zero" {
  TODO add "only one"
  run "$UTILZ_BIN_DIR/todo" done 999
  assert_failure
  assert_output_contains "no item numbered"
}

# ----------------------------------------------------------------------------
# WP-03 -- Queries
# ----------------------------------------------------------------------------

@test "next prints next n open items DOING-first" {
  TODO add "todo one"
  TODO add "todo two"
  TODO add "todo three"
  TODO start 2   # "todo two" -> DOING (becomes item 1)
  # next 2 should show the DOING item first, then the top TODO item
  run "$UTILZ_BIN_DIR/todo" next 2
  assert_success
  assert_output_contains "todo two"
  assert_output_contains "todo one"
  refute_output_contains "todo three"
}

@test "doing todo done print their buckets" {
  TODO add "a todo"
  TODO add "a doing"
  TODO start 2
  TODO add "a done"
  TODO done 3
  run "$UTILZ_BIN_DIR/todo" doing
  assert_output_contains "a doing"
  refute_output_contains "a todo"
  run "$UTILZ_BIN_DIR/todo" todo
  assert_output_contains "a todo"
  refute_output_contains "a doing"
  run "$UTILZ_BIN_DIR/todo" done
  assert_output_contains "a done"
}

@test "count prints per-bucket counts" {
  TODO add "t1"
  TODO add "t2"
  TODO add "d1"
  TODO start 3
  run "$UTILZ_BIN_DIR/todo" count
  assert_output_contains "DOING 1"
  assert_output_contains "TODO  2"
  assert_output_contains "DONE  0"
}

# ----------------------------------------------------------------------------
# WP-04 -- Lifecycle: prune / flush
# ----------------------------------------------------------------------------

@test "prune archives DONE to history newest-first and clears bucket" {
  TODO add "first done"
  TODO add "second done"
  TODO done 1   # first done
  TODO done 1   # second done (now at top of DONE)
  TODO done --prune
  local hist="_history/$(date -u +%Y%m%d)-done.md"
  assert_file_exists "$hist"
  file_has "$hist" "[x] second done"
  file_has "$hist" "[x] first done"
  # newest-first: second done above first done
  run grep -nF -- "second done" "$hist"
  local top="${output%%:*}"
  run grep -nF -- "first done" "$hist"
  local bot="${output%%:*}"
  [ "$top" -lt "$bot" ]
  # DONE bucket cleared in the live file
  file_lacks todo.md "second done"
}

@test "flush clears DONE with --force and does not archive" {
  TODO add "throwaway"
  TODO done 1
  TODO done --flush --force
  file_lacks todo.md "throwaway"
  assert_directory_not_exists "_history"
}

@test "custom history pattern is honoured" {
  # seed a file carrying a custom history: pattern
  cat > todo.md <<'EOF'
---
title: "# TODO"
history: archive/done-YYYYMMDD.md
---

# TODO

## DOING

_(none)_

## TODO

_(none)_

## DONE:2026-01-01T00:00:00Z

1:[x] archived item
EOF
  TODO done --prune
  local hist="archive/done-$(date -u +%Y%m%d).md"
  assert_file_exists "$hist"
  file_has "$hist" "[x] archived item"
}

# ----------------------------------------------------------------------------
# WP-05 -- sync + edit
# ----------------------------------------------------------------------------

@test "sync relocates by glyph (glyph wins)" {
  cat > todo.md <<'EOF'
---
title: "# TODO"
history: _history/YYYYMMDD-done.md
---

# TODO

## DOING

_(none)_

## TODO

1:[ ] still todo
2:[x] secretly finished

## DONE:2026-01-01T00:00:00Z

_(none)_
EOF
  TODO sync
  # the [x] item under TODO moves to DONE
  run grep -nF -- "secretly finished" todo.md
  local done_line="${output%%:*}"
  run grep -n "## DONE:" todo.md
  local heading_line="${output%%:*}"
  [ "$done_line" -gt "$heading_line" ]
  # and "still todo" stays a todo
  file_has todo.md ":[ ] still todo"
}

@test "sync tolerates hand-entered lines" {
  cat > todo.md <<'EOF'
---
title: "# TODO"
history: _history/YYYYMMDD-done.md
---

# TODO

## DOING

_(none)_

## TODO

[ ] no number here
- [ ] pasted intent dash
7:[x]nospace

## DONE:2026-01-01T00:00:00Z

_(none)_
EOF
  TODO sync
  file_has todo.md "1:[ ] no number here"
  file_has todo.md "2:[ ] pasted intent dash"
  file_has todo.md "3:[x] nospace"
}

@test "sync warns and preserves an unrecognizable line" {
  cat > todo.md <<'EOF'
---
title: "# TODO"
history: _history/YYYYMMDD-done.md
---

# TODO

## DOING

_(none)_

## TODO

1:[ ] real item
this is not a checkbox line

## DONE:2026-01-01T00:00:00Z

_(none)_
EOF
  run "$UTILZ_BIN_DIR/todo" sync
  assert_success
  assert_output_contains "unrecognized line"
  file_has todo.md "this is not a checkbox line"
}

@test "update aliases sync" {
  TODO add "beta"
  TODO add "alpha"
  TODO update
  assert_file_exists "todo.md"
  file_has todo.md "1:[ ] beta"
}

@test "edit uses EDITOR then syncs" {
  # stub editor flips the first `[ ]` to `[x]`; edit must then sync it into DONE
  local stub="$BATS_TEST_TMPDIR/stub-editor.sh"
  cat > "$stub" <<'EOF'
#!/usr/bin/env bash
sed -i.bak 's/\[ \]/[x]/' "$1" && rm -f "$1.bak"
EOF
  chmod +x "$stub"
  TODO add "edit target"
  run env VISUAL= EDITOR="$stub" "$UTILZ_BIN_DIR/todo" edit
  assert_success
  file_has todo.md "1:[x] edit target"
}

# ----------------------------------------------------------------------------
# WP-06 -- --json
# ----------------------------------------------------------------------------

@test "--json emits keyed buckets" {
  require_command jq
  TODO add "a todo"
  TODO add "a doing"
  TODO start 2
  TODO add "a done"
  TODO done 3
  run bash -c "'$UTILZ_BIN_DIR/todo' --json 2>/dev/null"
  assert_success
  echo "$output" | jq -e 'has("doing") and has("todo") and has("done") and has("done_watermark")'
  echo "$output" | jq -e '.doing[0].text == "a doing"'
  echo "$output" | jq -e '.todo[0].text == "a todo"'
  echo "$output" | jq -e '.done[0].text == "a done"'
}

# ----------------------------------------------------------------------------
# WP-08 -- mutual guard with intent todo
# ----------------------------------------------------------------------------

# A foreign (intent-owned) todo.md body written to $1.
_seed_intent_todo() {
  cat > "$1" <<'EOF'
---
generator: intent todo
---

## DOING

_(none)_

## TODO

- [ ] ST0001: intent-owned item

## DONE:2026-01-01T00:00:00Z

_(none)_
EOF
}

# Put an executable `intent` stub on PATH so `command -v intent` succeeds
# regardless of host. Echoes the dir to prepend.
_stub_intent() {
  mkdir -p "$PWD/fakebin"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$PWD/fakebin/intent"
  chmod +x "$PWD/fakebin/intent"
  printf '%s' "$PWD/fakebin"
}

@test "write stamps generator: utilz todo" {
  TODO add "anything"
  file_has todo.md "generator: utilz todo"
}

@test "foreign file in an Intent project with intent present is refused unchanged" {
  mkdir -p proj/intent/.config
  echo '{"project_name":"x"}' > proj/intent/.config/config.json
  _seed_intent_todo proj/todo.md
  cp proj/todo.md expected.md
  local bin
  bin="$(_stub_intent)"
  run env PATH="$bin:$PATH" "$UTILZ_BIN_DIR/todo" --file proj/todo.md sync
  assert_failure
  assert_output_contains "refusing to overwrite"
  # left byte-unchanged
  run diff expected.md proj/todo.md
  assert_success
}

@test "safe files own no-frontmatter and no-generator are written" {
  # (a) our own marked file, even inside an Intent project with intent present,
  # writes -- the marker check short-circuits before the refuse gate.
  mkdir -p proj/intent/.config
  echo '{}' > proj/intent/.config/config.json
  local bin
  bin="$(_stub_intent)"
  cat > proj/todo.md <<'EOF'
---
generator: utilz todo
title: "# TODO"
history: _history/YYYYMMDD-done.md
---

# TODO

## DOING

_(none)_

## TODO

1:[ ] mine

## DONE:2026-01-01T00:00:00Z

_(none)_
EOF
  run env PATH="$bin:$PATH" "$UTILZ_BIN_DIR/todo" --file proj/todo.md add "another"
  assert_success
  file_has proj/todo.md "another"

  # (b) no frontmatter at all (legacy intent / fresh) -> writable, gains marker
  printf '## DOING\n\n_(none)_\n\n## TODO\n\n1:[ ] legacy\n\n## DONE:2026-01-01T00:00:00Z\n\n_(none)_\n' > legacy.md
  run "$UTILZ_BIN_DIR/todo" --file legacy.md add "new one"
  assert_success
  file_has legacy.md "generator: utilz todo"

  # (c) frontmatter but no generator (utilz pre-marker) -> writable, gains marker
  cat > premarker.md <<'EOF'
---
title: "# TODO"
history: _history/YYYYMMDD-done.md
---

# TODO

## DOING

_(none)_

## TODO

1:[ ] premarker

## DONE:2026-01-01T00:00:00Z

_(none)_
EOF
  run "$UTILZ_BIN_DIR/todo" --file premarker.md add "x"
  assert_success
  file_has premarker.md "generator: utilz todo"
}

@test "foreign file outside an Intent project is taken over and re-stamped" {
  # foreign marker, but cwd is a bare temp dir (no Intent project above it)
  _seed_intent_todo todo.md
  local bin
  bin="$(_stub_intent)"   # even with intent present, no project here -> proceed
  run env PATH="$bin:$PATH" "$UTILZ_BIN_DIR/todo" --file todo.md sync
  assert_success
  refute_output_contains "refusing"
  file_has todo.md "generator: utilz todo"
  file_lacks todo.md "generator: intent todo"
}

@test "foreign file with intent absent proceeds without error" {
  # foreign marker, inside an Intent project, but Intent not installed
  mkdir -p proj/intent/.config
  echo '{}' > proj/intent/.config/config.json
  _seed_intent_todo proj/todo.md
  run env UTILZ_TODO_INTENT_PRESENT=0 "$UTILZ_BIN_DIR/todo" --file proj/todo.md sync
  assert_success
  refute_output_contains "refusing"
  file_has proj/todo.md "generator: utilz todo"
}

@test "refuses to create a fresh default todo.md inside an Intent project" {
  mkdir -p proj/intent/.config
  echo '{}' > proj/intent/.config/config.json
  local bin
  bin="$(_stub_intent)"
  # bare `utilz todo` with cwd inside the project, default ./todo.md, none yet
  run env PATH="$bin:$PATH" bash -c "cd proj && \"$UTILZ_BIN_DIR/todo\""
  assert_failure
  assert_output_contains "Intent project"
  assert_file_not_exists proj/todo.md
}

@test "an existing utilz todo.md inside an Intent project still works" {
  mkdir -p proj/intent/.config
  echo '{}' > proj/intent/.config/config.json
  local bin
  bin="$(_stub_intent)"
  cat > proj/todo.md <<'EOF'
---
generator: utilz todo
title: "# TODO"
history: _history/YYYYMMDD-done.md
---

# TODO

## DOING

_(none)_

## TODO

1:[ ] existing

## DONE:2026-01-01T00:00:00Z

_(none)_
EOF
  run env PATH="$bin:$PATH" bash -c "cd proj && \"$UTILZ_BIN_DIR/todo\" add more"
  assert_success
  file_has proj/todo.md "more"
}
