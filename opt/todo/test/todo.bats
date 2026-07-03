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
